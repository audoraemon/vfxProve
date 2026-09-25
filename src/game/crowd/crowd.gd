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
## One person through a gate this often. 0.6 s was the spec's starting value, calibrated against people who
## stalled at every path waypoint; once they really ran (milestone 5) 42 escaped in the first 34 s against a
## loss limit of 38. At 2 s the gates are the bottleneck the spec describes: crowds pile up in front of them.
const GATE_INTERVAL := 2.0
## How far beyond a gate's footprint its queue reaches, so people are held just before the arch as well.
const GATE_DOOR := 0.45
## A gate's waiting crowd: how far in front of the doorway it may reach, and how far apart two waiting people
## stand. People never collide, so without spots of their own a crowd of thirty stood on three pixels.
const QUEUE_REACH := 3.2
const QUEUE_SPACING := 0.34
## The waiting crowd forms this far inside the town from the doorway, where the wall does not hide it -- the
## camera looks from the south-east, and a 34-px wall covers about 2.1 units of ground behind it.
const QUEUE_DEPTH0 := 2.2
## Where the soldiers ring the Citadel.
const RING_RADIUS := 3.4
## Voices: at most this many a second across the whole town, refilling steadily, so 160 people can never drown
## the powers. A cast is heard from at most VOICES_PER_CAST of the people it frightened, the nearest first.
const VOICE_BUDGET := 4.0
const VOICES_PER_CAST := 3

## The sound of a town running: a looping bed whose level follows how many citizens are running -- silent with
## none, full at BED_FULL -- easing at BED_EASE a second so it swells and fades instead of jumping.
const BED_FULL := 40.0
const BED_EASE := 1.5
const BED_DB := -8.0

var citizens: Array[Person] = []
var soldiers: Array[Person] = []
## How many were spawned, so milestone 3's stability can measure losses against the starting town.
var spawned_citizens := 0
var spawned_soldiers := 0
var alarm := 0.0
var escaped_count := 0
var killed_citizens := 0
var killed_soldiers := 0
## The battlefield's Sfx; null in tests, which still count what would have played.
var sfx: Node
var voices_played := 0
var _voice_tokens := VOICE_BUDGET
var _bed: AudioStreamPlayer
var _bed_level := 0.0
## Set by stop_bed(): once the mission is quitting, _update_bed() must not revive the bed even though the
## crowd (unlike the frozen pause) keeps processing for the few frames Battlefield.quit() waits out.
var _bed_stopped := false

var _field: EnemyField
var _env: EnvironmentField
var _town: Town
var _grid: WalkGrid
var _parent: Node2D
var _rng := RandomNumberGenerator.new()
## Gate -> the crowd clock time it may pass someone again.
var _gate_next := {}
## Gate -> its queue spots, nearest the doorway first. Built when the town is first asked about, per gate.
var _spots := {}
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
	p.env = _env
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


## How loud the panic bed should be, 0 to 1, for this many running citizens.
static func bed_level_for(running: int) -> float:
	return clampf(float(running) / BED_FULL, 0.0, 1.0)


## The mission paused (or the results are up over it): hold the bed where it is.
func pause_bed(paused: bool) -> void:
	if _bed != null:
		_bed.stream_paused = paused


## Silence the bed outright (the mission is quitting): unlike pause_bed(), nothing resumes it -- the crowd keeps
## processing for the few frames Battlefield.quit() waits out, and without this latch a still-running citizen
## would have _update_bed() call play() right back. Battlefield.quit() stops its own Sfx pool and waits out the
## audio thread before it exits -- the bed is not in that pool, so it needs to be stopped before that wait, or
## a bed still playing at process exit leaks its audio playback.
func stop_bed() -> void:
	_bed_stopped = true
	if _bed != null:
		_bed.stop()


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
	_voice_tokens = minf(VOICE_BUDGET, _voice_tokens + VOICE_BUDGET * delta)
	_purge_in -= delta
	if _purge_in <= 0.0:
		_purge_in = 1.0
		_field.purge()
	_update_bed(delta)


## Rows fanned out in front of a gate's doorway on the town side, starting QUEUE_DEPTH0 in (beyond the wall's
## own shadow) and nearest that point first, walkable only. The crowd widens as it backs into the town, the way
## a real one does.
func queue_spots(gate: Structure) -> Array[Vector2]:
	if _spots.has(gate):
		return _spots[gate]
	var out_dir := gate.center().normalized()
	var side := Vector2(-out_dir.y, out_dir.x)
	var face := gate.center() - out_dir * (absf(gate.footprint.size.dot(out_dir)) * 0.5 + GATE_DOOR)
	# Built as one continuous path, nearest row first and snaking left-right-left row to row (not always left
	# to right) -- not re-sorted by plain distance to face, which would let a row's far edge sort ahead of the
	# next row's near centre and zig-zag between the two sides of a single row. _gates() advances the whole
	# waiting crowd by one array index at a time as people are let through, so a neighbour in the fan has to be
	# a neighbour in this array too (in both directions, row to row as well as within one), or the person
	# handed that index has to cross the row -- or jump from one edge of the fan clear over to the other -- to
	# reach it.
	var spots: Array[Vector2] = []
	var row := 0
	var depth := QUEUE_DEPTH0
	while depth <= QUEUE_DEPTH0 + QUEUE_REACH:
		var half := 1.2 + depth * 0.6
		var count := int(half * 2.0 / QUEUE_SPACING) + 1
		var stagger := QUEUE_SPACING * 0.5 if row % 2 == 1 else 0.0
		var order := range(count) if row % 2 == 0 else range(count - 1, -1, -1)
		for i in order:
			var spot := face - out_dir * depth + side * (-half + stagger + QUEUE_SPACING * float(i))
			if _grid == null or _grid.walkable(spot):
				spots.append(spot)
		row += 1
		depth += QUEUE_SPACING * 0.87
	_spots[gate] = spots
	return spots


## How many people are waiting at a gate right now.
func waiting_at(gate: Structure) -> int:
	var n := 0
	var spots := queue_spots(gate)
	for p in citizens:
		if is_instance_valid(p) and p.queue_spot != Vector2.INF and spots.has(p.queue_spot):
			n += 1
	return n


func _gates() -> void:
	for gate in _town.gates:
		if not is_instance_valid(gate) or gate.destroyed:
			_release_all(gate)
			continue  # rubble is no bottleneck
		var centre := gate.center()
		var outward := centre.normalized()
		var spots := queue_spots(gate)
		var face := centre - outward * (absf(gate.footprint.size.dot(outward)) * 0.5 + GATE_DOOR)
		# Each person this gate has released keeps its own pass until it is through (more than a third of the
		# way past the doorway's centre line), dead, no longer fleeing, or has wandered off -- unlike the old
		# single shared pass, several can be on their way out at once, so a slow one never looks like a jam.
		for p in citizens:
			if not is_instance_valid(p) or p.passing_gate != gate:
				continue
			var rel := p.ground_pos - centre
			if rel.dot(outward) > 0.3 or not p.is_alive() or p.mind != Person.Mind.FLEE \
					or p.ground_pos.distance_to(face) > QUEUE_DEPTH0 + QUEUE_REACH + 2.0:
				p.passing_gate = null
		# The waiting crowd: fleeing, in front of the doorway, not yet released.
		var crowd_here: Array[Person] = []
		for p in citizens:
			if not is_instance_valid(p) or not p.is_alive() or p.mind != Person.Mind.FLEE or p.passing_gate == gate:
				continue
			var rel := p.ground_pos - centre
			var in_front := rel.dot(outward) <= 0.0 \
				and p.ground_pos.distance_to(face) <= QUEUE_DEPTH0 + QUEUE_REACH + 0.5
			if in_front:
				crowd_here.append(p)
			elif spots.has(p.queue_spot):
				p.release_from_queue()  # it left this gate's crowd (thrown clear, or through)
		if crowd_here.is_empty():
			continue
		# Order by who joined the queue first, not by distance: a distance sort every tick re-ranked people as
		# they walked (two people converging from the same direction kept overtaking each other in "distance
		# to face", so the gate kept swapping which spot each of them was walking to, and neither ever
		# arrived). Arrival order does not have that problem, and unlike ordering by the spot each person
		# already holds, it also is not upset by queue_spots()'s own distance sort, which zig-zags between the
		# two sides of a row rather than running left to right -- two neighbours could hold spots on opposite
		# sides of the same row and, ordered by spot index, swap them outright the next time the queue shuffled
		# forward. A newcomer with no turn yet falls in after everyone already waiting, nearest the face first.
		crowd_here.sort_custom(func(a: Person, b: Person) -> bool:
			if a.queue_since < 0.0 and b.queue_since < 0.0:
				return a.ground_pos.distance_squared_to(face) < b.ground_pos.distance_squared_to(face)
			if a.queue_since < 0.0 or b.queue_since < 0.0:
				return b.queue_since < 0.0
			if not is_equal_approx(a.queue_since, b.queue_since):
				return a.queue_since < b.queue_since
			# Joined in the same tick (a burst of newcomers gets one queue_since between them): break the tie
			# by instance id, which never changes, rather than leaving it to sort_custom's own stability --
			# that let two same-tick joiners flip order the next time the queue's composition changed.
			return a.get_instance_id() < b.get_instance_id())
		# The gate opens on the clock alone: each passer now keeps its own pass, so there is no "previous
		# passer must be gone" condition to also satisfy, only the interval -- and that alone still limits the
		# gate to one release per GATE_INTERVAL.
		var first := 0
		if _clock >= float(_gate_next.get(gate, -1.0)):
			_gate_next[gate] = _clock + GATE_INTERVAL
			crowd_here[0].release_from_queue()
			crowd_here[0].passing_gate = gate
			first = 1
		for i in range(first, crowd_here.size()):
			var slot := i - first
			var p: Person = crowd_here[i]
			if p.queue_since < 0.0:
				p.queue_since = _clock
			p.queue_spot = spots[mini(slot, spots.size() - 1)]


## A gate that fell lets its whole crowd go, waiting or already walking through it.
func _release_all(gate: Structure) -> void:
	var spots: Array[Vector2] = _spots.get(gate, [])
	for p in citizens:
		if not is_instance_valid(p):
			continue
		if spots.has(p.queue_spot):
			p.release_from_queue()
		if p.passing_gate == gate:
			p.passing_gate = null


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


func _update_bed(delta: float) -> void:
	if _bed_stopped:
		return  # the mission quit; nothing revives the bed after that, even a citizen still running
	var running := 0
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and (p.mind == Person.Mind.PANIC or p.mind == Person.Mind.FLEE):
			running += 1
	_bed_level = move_toward(_bed_level, bed_level_for(running), BED_EASE * delta)
	if sfx == null or DisplayServer.get_name() == "headless" or not is_inside_tree():
		return
	if _bed == null:
		_bed = AudioStreamPlayer.new()
		_bed.bus = Sfx.BUS
		_bed.stream = Sfx.load_stream(&"crowd_panic")
		add_child(_bed)
	if _bed_level <= 0.001:
		if _bed.playing:
			_bed.stop()
		return
	if not _bed.playing:
		_bed.play()
	_bed.volume_db = BED_DB + linear_to_db(_bed_level)


## One voice from `p`, if the budget allows it.
func _voice(p: Person, cue: StringName) -> void:
	if _voice_tokens < 1.0:
		return
	_voice_tokens -= 1.0
	voices_played += 1
	if sfx != null:
		sfx.play(cue, p.ground_pos)


## A few of the people just frightened near `at` cry out, nearest first.
func _yelp(frightened: Array[Person], at: Vector2) -> void:
	frightened.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	for i in mini(frightened.size(), VOICES_PER_CAST):
		_voice(frightened[i], &"cit_yelp")


## A cast landed: everyone close enough panics. A lane power (`dir` set, `length` above zero) frightens people
## along its whole lane -- a tsunami's far end runs through streets the player never pressed on.
func on_cast(ground: Vector2, dir := Vector2.ZERO, length := 0.0) -> void:
	var points: Array[Vector2] = [ground]
	if dir != Vector2.ZERO and length > 0.0:
		var step := PANIC_CAST
		var along := step
		var unit := dir.normalized()
		while along < length:
			points.append(ground + unit * along)
			along += step
		points.append(ground + unit * length)
	var frightened: Array[Person] = []
	for p in citizens:
		if not is_instance_valid(p) or not p.is_alive():
			continue
		for point in points:
			if p.ground_pos.distance_to(point) <= PANIC_CAST:
				var was := p.mind
				p.panic(point)
				if p.mind == Person.Mind.PANIC and was != Person.Mind.PANIC:
					frightened.append(p)
				break
	_yelp(frightened, ground)


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
		var shouted := 0
		for p in citizens:
			if shouted >= 2:
				break
			if is_instance_valid(p) and p.is_alive():
				_voice(p, &"cit_shout")
				shouted += 1


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
	if sfx != null:
		sfx.play(&"sol_rally", TownLayout.CITADEL_ORIGIN)
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
	_spots.clear()
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
	_voice_tokens = VOICE_BUDGET
	voices_played = 0


func _on_structure_destroyed(s: Structure, _kind: StringName) -> void:
	if s.role != &"citadel":
		add_alarm(ALARM_BUILDING)
	var at := s.center()
	var frightened: Array[Person] = []
	for p in citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(at) <= PANIC_DESTROY:
			var was := p.mind
			p.panic(at)
			if p.mind == Person.Mind.PANIC and was != Person.Mind.PANIC:
				frightened.append(p)
	_yelp(frightened, at)
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
