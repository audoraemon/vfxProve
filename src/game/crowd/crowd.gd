class_name Crowd
extends Node
## The people of Aldermere: 110 citizens who wander their street, panic, flee to the exits and queue at the
## gates, and 50 soldiers who hold their posts until the alarm or the first blow on the Citadel sends them to
## ring it. Everyone is an ordinary unit in EnemyField, so every effect kills, knocks, pulls, freezes and lifts
## them as it does the sandbox's troopers. Numbers are the spec's starting values (§3).

signal escaped(person: Person)
signal alarm_changed(value: float)
signal rallied

const CITIZENS := 110
const SOLDIERS := 50
## Soldier posts: drilling in the yard, on the walls and gates, guarding the Citadel, patrolling in pairs.
const POST_YARD := 20
const POST_WALLS := 12
const POST_CITADEL := 10
const POST_PATROL := 8
const ALARM_BUILDING := 2.0
const ALARM_KILL := 0.5
const ALARM_CITADEL_HIT := 10.0
const ALARM_RALLY := 25.0
const ALARM_FLEE_ALL := 50.0
## A cast this close frightens a citizen; a collapse this close does too.
const PANIC_CAST := 7.0
const PANIC_DESTROY := 4.0
## One person through a gate this often.
const GATE_INTERVAL := 0.6
## Only people this close to a gate's middle are held; the rest walk up and bunch on their own.
const GATE_DOOR := 0.45
## A released person keeps its pass until it is this far past the middle (or the interval runs out).
const GATE_CLEAR := 0.8
## Where the soldiers ring the Citadel.
const RING_RADIUS := 3.4

var citizens: Array[Person] = []
var soldiers: Array[Person] = []
## How many were spawned, so milestone 3's stability can measure losses against the starting town.
var spawned_citizens := 0
var spawned_soldiers := 0
var alarm := 0.0
var escaped_count := 0
var killed_citizens := 0
var killed_soldiers := 0

var _field: EnemyField
var _env: EnvironmentField
var _town: Town
var _grid: WalkGrid
var _parent: Node2D
var _rng := RandomNumberGenerator.new()
## Gate -> the crowd clock time it may pass someone again.
var _gate_next := {}
## Gate -> the Person it last let through, exempt from the hold until it clears GATE_CLEAR range.
var _gate_passing := {}
var _clock := 0.0
var _rallied := false
var _fled_all := false
var _citadel_hit := false
## Seconds until EnemyField.purge() runs again (about once a second; mirrors the gate clock's pacing).
var _purge_in := 1.0


func setup(field: EnemyField, env: EnvironmentField, town: Town, grid: WalkGrid, parent: Node2D,
		seed_value: int) -> Crowd:
	_field = field
	_env = env
	_town = town
	_grid = grid
	_parent = parent
	_rng.seed = seed_value
	env.structure_destroyed.connect(_on_structure_destroyed)
	field.enemy_killed.connect(_on_killed)
	if town.citadel != null:
		town.citadel.health_changed.connect(_on_citadel_health)
		town.citadel.fallen.connect(_on_citadel_fallen)
	return self


func spawn(citizen_count := CITIZENS, soldier_count := SOLDIERS) -> void:
	var homes: Array[Structure] = []
	for s in _env.structures():
		if s.role == &"house":
			homes.append(s)
	for i in citizen_count:
		var home: Structure = homes[i % maxi(homes.size(), 1)] if not homes.is_empty() else null
		var at := _spot_near(home.center() if home != null else Vector2.ZERO, 1.6)
		var p := _add_person(false, at)
		p.anchor = at
		citizens.append(p)
	for spot in _soldier_posts(soldier_count):
		soldiers.append(_add_person(true, spot))
	spawned_citizens = citizens.size()
	spawned_soldiers = soldiers.size()


## Walkable ground within `spread` of `about`, or the nearest walkable point to it.
func _spot_near(about: Vector2, spread: float) -> Vector2:
	for attempt in 8:
		var candidate := about + Vector2(_rng.randf_range(-spread, spread), _rng.randf_range(-spread, spread))
		if _grid.walkable(candidate):
			return candidate
	var free := _grid.nearest_walkable(about)
	return free if free != Vector2.INF else about


func _add_person(is_soldier: bool, at: Vector2) -> Person:
	var p := Person.new()
	p.rng.seed = _rng.randi()
	_field.add(p)
	p.setup_person(is_soldier, at, _grid)
	_parent.add_child(p)
	return p


## The spec's posting: the yard, the wall towers and gates, the Citadel, and street patrols in pairs.
func _soldier_posts(count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in POST_YARD:
		out.append(_spot_near(TownLayout.BARRACKS_YARD.get_center(), 1.4))
	var guard_spots: Array[Vector2] = []
	for s in _env.structures():
		if s.role == &"tower" or s.role == &"gate":
			guard_spots.append(s.center())
	for i in POST_WALLS:
		var about: Vector2 = guard_spots[i % maxi(guard_spots.size(), 1)] if not guard_spots.is_empty() else Vector2.ZERO
		out.append(_spot_near(about, 1.2))
	for i in POST_CITADEL:
		var a := TAU * float(i) / float(POST_CITADEL)
		out.append(_spot_near(TownLayout.CITADEL_ORIGIN + Vector2(cos(a), sin(a)) * RING_RADIUS, 0.8))
	for i in POST_PATROL:
		# Pairs walk the two streets; their post is a point on the road.
		var along := -6.0 + 4.0 * float(i / 2)
		var road_point := Vector2(0.0, along) if i % 4 < 2 else Vector2(along, 0.0)
		out.append(_spot_near(road_point, 0.8))
	while out.size() > count:
		out.pop_back()
	while out.size() < count:
		out.append(_spot_near(TownLayout.BARRACKS_YARD.get_center(), 1.4))
	return out


func alive_citizens() -> int:
	return _alive(citizens)


func alive_soldiers() -> int:
	return _alive(soldiers)


func _alive(list: Array[Person]) -> int:
	var n := 0
	for p in list:
		if is_instance_valid(p) and p.is_alive():
			n += 1
	return n


func _process(delta: float) -> void:
	advance(delta)


## Gate queues, escapes and the crowd clock. Runs from _process; tests call it directly.
func advance(delta: float) -> void:
	_clock += delta
	_gates()
	_escapes()
	_prune_soldiers()
	_purge_in -= delta
	if _purge_in <= 0.0:
		_purge_in = 1.0
		_field.purge()


func _gates() -> void:
	for gate in _town.gates:
		if not is_instance_valid(gate) or gate.destroyed:
			_gate_passing.erase(gate)
			continue  # rubble is no bottleneck
		var centre := gate.center()
		# The way out of town is straight away from its crossroads at the origin, so anyone already further out
		# than the gate is through it and is not held again. Without this the doorway catches its own passer a
		# second time the moment its pass expires -- it is still inside the 0.45 span, and being nearest the
		# centre it wins the next turn as well, so every person spent two of the gate's turns.
		var outward := centre.normalized()
		# Whoever this gate let through stays exempt from the hold until it actually clears the doorway —
		# otherwise the very next frame's re-evaluation catches it again mid-step and nobody ever gets far
		# enough to leave GATE_CLEAR range, let alone reach the exit. The exemption also ends once the
		# interval runs out, so a slow passer cannot hold the gate open past its own turn.
		var passing: Person = _gate_passing.get(gate)
		if is_instance_valid(passing) and passing.is_alive() and passing.mind == Person.Mind.FLEE \
				and passing.ground_pos.distance_to(centre) <= GATE_CLEAR \
				and _clock < float(_gate_next.get(gate, -1.0)):
			passing.wait = 0.0
		else:
			passing = null
			_gate_passing.erase(gate)
		var queue: Array[Person] = []
		for p in citizens:
			if p != passing and is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.FLEE \
					and p.ground_pos.distance_to(centre) <= GATE_DOOR \
					and (p.ground_pos - centre).dot(outward) <= 0.0:
				queue.append(p)
		if queue.is_empty():
			continue
		queue.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_squared_to(centre) < b.ground_pos.distance_squared_to(centre))
		var open: bool = passing == null and _clock >= float(_gate_next.get(gate, -1.0))
		for i in queue.size():
			if i == 0 and open:
				_gate_next[gate] = _clock + GATE_INTERVAL
				queue[0].wait = 0.0
				_gate_passing[gate] = queue[0]
			else:
				queue[i].wait = maxf(queue[i].wait, 0.25)


func _escapes() -> void:
	# Rebuilt rather than erased in place: a citizen DummyEnemy frees itself when its death fade ends, and
	# Array.erase() on an already-freed object raises a TypedArray validation error instead of removing it.
	var remaining: Array[Person] = []
	for p in citizens:
		if not is_instance_valid(p):
			continue
		if p.is_alive() and p.has_escaped():
			escaped_count += 1
			escaped.emit(p)
			_field.remove(p)
			p.queue_free()
			continue
		remaining.append(p)
	citizens = remaining


## Drop freed soldiers from the roster, the same way _escapes() prunes citizens -- never Array.erase() a freed
## object, that raises a typed-array error. A dead-but-not-yet-freed corpse stays here; rally() filters those.
func _prune_soldiers() -> void:
	var remaining: Array[Person] = []
	for p in soldiers:
		if is_instance_valid(p):
			remaining.append(p)
	soldiers = remaining


## The player cast a power here: everyone close enough panics.
func on_cast(ground: Vector2) -> void:
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(ground) <= PANIC_CAST:
			p.panic(ground)


func add_alarm(points: float) -> void:
	var before := alarm
	alarm = clampf(alarm + points, 0.0, 100.0)
	if alarm != before:
		alarm_changed.emit(alarm)
	if alarm >= ALARM_RALLY:
		rally()
	if alarm >= ALARM_FLEE_ALL and not _fled_all:
		_fled_all = true
		for p in citizens:
			if is_instance_valid(p) and p.is_alive():
				p.flee()


## Every soldier leaves its post for a slot on the Citadel's ring.
func rally() -> void:
	if _rallied:
		return
	_rallied = true
	var living: Array[Person] = []
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive():
			living.append(p)
	for i in living.size():
		var p := living[i]
		var a := TAU * float(i) / float(maxi(living.size(), 1))
		p.send_to_post(_spot_near(TownLayout.CITADEL_ORIGIN + Vector2(cos(a), sin(a)) * RING_RADIUS, 0.6), true)
	rallied.emit()


func clear() -> void:
	for p in citizens + soldiers:
		if is_instance_valid(p):
			if p.is_inside_tree():
				p.queue_free()
			else:
				p.free()
	citizens.clear()
	soldiers.clear()
	_gate_next.clear()
	_gate_passing.clear()
	alarm = 0.0
	escaped_count = 0
	killed_citizens = 0
	killed_soldiers = 0
	spawned_citizens = 0
	spawned_soldiers = 0
	_rallied = false
	_fled_all = false
	_citadel_hit = false
	_clock = 0.0
	_purge_in = 1.0


func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if s.role != &"citadel":
		add_alarm(ALARM_BUILDING)
	var at := s.center()
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(at) <= PANIC_DESTROY:
			p.panic(at)
	if is_instance_valid(_town) and s == _town.bridge:
		# The south route just closed: everyone already walking it needs a new plan.
		for p in citizens:
			if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.FLEE:
				p.replan()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	var p := e as Person
	if p == null:
		return
	if p.soldier:
		killed_soldiers += 1
	else:
		killed_citizens += 1
	add_alarm(ALARM_KILL)


## The Citadel reports every hit that takes health; the first one is the alarm bell.
func _on_citadel_health(_fraction: float) -> void:
	if _citadel_hit:
		return
	_citadel_hit = true
	add_alarm(ALARM_CITADEL_HIT)
	rally()


func _on_citadel_fallen() -> void:
	for p in soldiers:
		if is_instance_valid(p) and p.is_alive():
			p.hold_ground()
