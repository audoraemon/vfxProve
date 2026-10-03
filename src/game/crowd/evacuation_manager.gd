class_name EvacuationManager
extends RefCounted
## Which way out (v0.04): each evacuee picks the exit with the lowest score -- the length of the route there (a
## distance field per exit over the walk grid), the crowd already waiting at its gate, and the danger it knows of on
## the way and at the gate -- and re-checks now and then, switching only when another way is clearly better. The
## danger is also costed into the walk grid itself (grid weights), so every path, a soldier's too, bends round it.
## A town with river boats (v0.05) has a third way out: the dock (add_boat_exit()), open while the ferry runs, its
## crowd costed like a gate's.

## Score weights: ground units per person waiting at the gate, per unsafe route step (0.5 units), and for a gate
## whose mouth lies in danger.
const CONGESTION := 0.5
## Per person waiting at the dock: the boat carries RiverFerry.LOAD every LOAD_TIME + TRIP seconds, slower than a gate.
const BOAT_CONGESTION := 0.7
const HAZARD := 4.0
const HAZARD_GATE := 20.0
## Route steps (walk cells) sampled for danger from where a person stands.
const ROUTE_STEPS := 24
## Before the bell, a person only knows the dangers within this of it.
const KNOWN_REACH := 12.0
## How often each evacuee re-checks, how much better another way must be, and how soon after a switch it may switch
## again.
const HZ := 1.5
const SWITCH_GAIN := 0.25
const SWITCH_WAIT := 4.0
## Collapse: order is breaking down; scores get up to this much noise.
const COLLAPSE_NOISE := 0.3
## Walk-grid weight of a cell in danger, and how many field cells are filled per frame.
const DANGER_WEIGHT := 6.0
const FIELD_CELLS_PER_FRAME := 3000

var exits: Array[Vector2] = []
## The gate each exit's route runs through (null for none).
var gates: Array = []
## The dock's index in exits (-1: no boats), and the ferry that serves it.
var boat_exit := -1
var ferry: RiverFerry
var _crowd: Crowd
var _grid: WalkGrid
var _town: Town
var _rng := RandomNumberGenerator.new()
## Per exit: the finished distance field (cells from the exit, -1 unreachable), and the one being built.
var _fields: Array[PackedInt32Array] = []
var _building: Array = []
var _built_version := -1
var _w := 0
var _h := 0
var _origin := Vector2i.ZERO
var _weighted: Array[Vector2i] = []
var _threat_epoch := -1
var _due := 0.0
var _at := 0
var _clock := 0.0


func setup(crowd: Crowd, grid: WalkGrid, town: Town, seed_value: int) -> EvacuationManager:
	_crowd = crowd
	_grid = grid
	_rng.seed = seed_value
	var r := grid.grid.region
	_origin = r.position
	_w = r.size.x
	_h = r.size.y
	_town = town
	for e: Vector2 in TownLayout.EXITS:
		_add_exit(e)
	_rebuild_all()
	return self


func _add_exit(e: Vector2) -> void:
	exits.append(e)
	var best: Structure = null
	for g: Structure in _town.gates:
		if best == null or g.center().distance_to(e) < best.center().distance_to(e):
			best = g
	gates.append(best)
	_fields.append(PackedInt32Array())


## River boats (v0.05): the dock's boarding point `at` becomes a way out, through the gate nearest it, while `f` runs.
func add_boat_exit(at: Vector2, f: RiverFerry) -> void:
	ferry = f
	boat_exit = exits.size()
	_add_exit(at)
	_rebuild_all()


## Is `g` the dock's boarding point? Reaching it is not escaping: the boat has to sail first.
func is_boat_exit(g: Vector2) -> bool:
	return boat_exit >= 0 and g == exits[boat_exit]


## One frame: keep the danger costed into the grid, the distance fields current, and let a slice of the evacuees
## re-check their way out.
func step(delta: float) -> void:
	_clock += delta
	if _crowd.threats.epoch != _threat_epoch:
		_threat_epoch = _crowd.threats.epoch
		_weigh_danger()
	if _grid.version != _built_version and _building.is_empty():
		_start_fields()
	_grow_fields()
	var n := _crowd.citizens.size()
	if n == 0:
		return
	_due = minf(_due + n * HZ * delta, n)
	var k := int(_due)
	_due -= k
	for j in k:
		if _at >= n:
			_at = 0
		var p = _crowd.citizens[_at]
		_at += 1
		if is_instance_valid(p):
			_recheck(p)


## The exit for `p` now, or Vector2.INF when none can be reached.
func choose(p: Person) -> Vector2:
	var best := -1
	var best_s := INF
	for i in exits.size():
		var s := score(p, i)
		if s < best_s:
			best_s = s
			best = i
	return exits[best] if best >= 0 else Vector2.INF


func exit_index(g: Vector2) -> int:
	return exits.find(g)


## Exit `i`'s score for `p` (lower is better; INF when it cannot be reached).
func score(p: Person, i: int) -> float:
	if i == boat_exit and (ferry == null or not ferry.open()):
		return INF
	var d := _dist(i, p.ground_pos)
	if d < 0:
		return INF
	var s := float(d) * WalkGrid.CELL
	if i == boat_exit:
		# A bigger boat (v0.08.2, ResponseProfile.boat_load) clears its crowd sooner.
		var boat := BOAT_CONGESTION if ferry.capacity == RiverFerry.LOAD \
			else BOAT_CONGESTION * float(RiverFerry.LOAD) / float(ferry.capacity)
		s += boat * ferry.waiting()
	var gate: Structure = gates[i]
	# A gate's crowd and danger only count for those still inside the walls: outside, the gate is behind them.
	if is_instance_valid(gate) and not gate.destroyed and TownLayout.TOWN.has_point(p.ground_pos):
		# A slower door (the postern) makes each person ahead a longer wait.
		var slow := _crowd.profile.postern_interval / Crowd.GATE_INTERVAL if gate.art_tag == &"postern" else 1.0
		s += CONGESTION * slow * _crowd.waiting_at(gate)
		if _known_unsafe(p, gate.center() - Crowd.outward_of(gate) * Crowd.QUEUE_DEPTH0):
			s += HAZARD_GATE
	s += HAZARD * _route_danger(p, i)
	if _crowd.alarms.stage == AlarmManager.Stage.COLLAPSE:
		s *= 1.0 + _rng.randf() * COLLAPSE_NOISE
	return s


func _recheck(p: Person) -> void:
	if not p.is_alive() or p.mind != Person.Mind.FLEE or p.queue_spot != Vector2.INF or p.passing_gate != null:
		return
	var now := exit_index(p.goal())
	if now < 0 or _clock - p.route_since < SWITCH_WAIT:
		return
	var here := score(p, now)
	for i in exits.size():
		if i != now and score(p, i) < here * (1.0 - SWITCH_GAIN):
			p.reroute(exits[i], _clock)
			return


## Unsafe steps on the way from `p` towards exit `i`, walking down its distance field.
func _route_danger(p: Person, i: int) -> int:
	var id := _grid.world_to_id(p.ground_pos)
	var f := _fields[i]
	var n := 0
	for k in ROUTE_STEPS:
		var d := _at_field(f, id)
		if d <= 0:
			break
		var next := id
		for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var dn := _at_field(f, id + o)
			if dn >= 0 and dn < d:
				next = id + o
				d = dn
		if next == id:
			break
		id = next
		if _known_unsafe(p, _grid.id_to_world(id)):
			n += 1
	return n


func _known_unsafe(p: Person, g: Vector2) -> bool:
	if not _crowd.alarms.bell_rung and g.distance_to(p.ground_pos) > KNOWN_REACH:
		return false
	return _crowd.threats.unsafe(g, 0.5)


func _dist(i: int, g: Vector2) -> int:
	return _at_field(_fields[i], _grid.world_to_id(g))


func _at_field(f: PackedInt32Array, id: Vector2i) -> int:
	var x := id.x - _origin.x
	var y := id.y - _origin.y
	if f.is_empty() or x < 0 or y < 0 or x >= _w or y >= _h:
		return -1
	return f[y * _w + x]


## Danger costed into the walk grid: cells in an active threat or a recent impact weigh DANGER_WEIGHT.
func _weigh_danger() -> void:
	for id in _weighted:
		if _grid.grid.is_in_boundsv(id):
			_grid.grid.set_point_weight_scale(id, 1.0)
	_weighted.clear()
	for t: Dictionary in _crowd.threats.all_zones():
		var c: Vector2 = t.at
		var r: float = t.radius
		var c0 := _grid.world_to_id(c - Vector2(r, r))
		var c1 := _grid.world_to_id(c + Vector2(r, r))
		for y in range(c0.y, c1.y + 1):
			for x in range(c0.x, c1.x + 1):
				var id := Vector2i(x, y)
				if _grid.grid.is_in_boundsv(id) and _grid.id_to_world(id).distance_to(c) <= r:
					_grid.grid.set_point_weight_scale(id, DANGER_WEIGHT)
					_weighted.append(id)


func _rebuild_all() -> void:
	_start_fields()
	while not _building.is_empty():
		_grow_fields()


## A fresh set of distance fields, grown a slice a frame (_grow_fields()); the old ones serve meanwhile.
func _start_fields() -> void:
	_built_version = _grid.version
	_building = []
	for e in exits:
		var f := PackedInt32Array()
		f.resize(_w * _h)
		f.fill(-1)
		var start := _grid.world_to_id(_grid.nearest_walkable(e))
		var q := PackedInt32Array()
		var x := start.x - _origin.x
		var y := start.y - _origin.y
		if x >= 0 and y >= 0 and x < _w and y < _h:
			f[y * _w + x] = 0
			q.append(y * _w + x)
		_building.append([f, q, 0])


func _grow_fields() -> void:
	if _building.is_empty():
		return
	var budget := FIELD_CELLS_PER_FRAME
	var done := true
	for b in _building:
		var f: PackedInt32Array = b[0]
		var q: PackedInt32Array = b[1]
		var head: int = b[2]
		while head < q.size() and budget > 0:
			var cell := q[head]
			head += 1
			budget -= 1
			var cx := cell % _w
			var cy := cell / _w
			var d := f[cell] + 1
			for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := cx + o.x
				var ny := cy + o.y
				if nx < 0 or ny < 0 or nx >= _w or ny >= _h:
					continue
				var ni := ny * _w + nx
				if f[ni] >= 0 or _grid.grid.is_point_solid(Vector2i(nx, ny) + _origin):
					continue
				f[ni] = d
				q.append(ni)
		b[0] = f
		b[1] = q
		b[2] = head
		if head < q.size():
			done = false
	if done:
		for i in _building.size():
			_fields[i] = _building[i][0]
		_building = []
