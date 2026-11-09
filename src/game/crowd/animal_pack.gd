class_name AnimalPack
extends Node
## The town's dogs and cats (Animal): spawned by Crowd.spawn() round the citizens' homes and haunts, about one for
## every PER_CITIZENS citizens (MIN..MAX), dogs and cats in five breeds each (Animal.DOGS, Animal.CATS), and stepped
## here every frame. Wherever they go (an errand, a flight, a gathering, after someone) they go the streets' way round
## the buildings (Animal.route_to()). They draw from their own rng (the crowd's seed + SEED_OFFSET), never the crowd's, a power's or a
## person's, and touch nobody unless a power turns them (cast()), so every reference stays as it was. `enabled` off
## (the reference tools and the test runner) spawns none.

static var enabled := true

const PER_CITIZENS := 12
const MIN := 6
const MAX := 32
const SEED_OFFSET := 71
## Dogs of all animals.
const DOG_SHARE := 0.55
## How far from home a wander goes, how long a sit lasts, and the chance a dog follows a passer-by.
const ROAM := 2.4
const SIT := Vector2(2.0, 7.0)
const FOLLOW_CHANCE := 0.3
const FOLLOW_REACH := 2.0
const FOLLOW_TIME := Vector2(6.0, 14.0)
const FOLLOW_GAP := 0.55
## A danger this near (beyond its radius) sends it running, FLEE_DIST away; inside KILL_SHARE of a new strike's radius
## it dies.
const FLEE_REACH := 1.5
const FLEE_DIST := 3.5
const KILL_SHARE := 0.5
const HARMLESS := [&"frenzy", &"smoke", &"doom", &"fire", &"bite"]
## A soldier this near a maddened animal cuts it down in SOLDIER_KILL seconds.
const SOLDIER_REACH := 0.6
const SOLDIER_KILL := 1.2
## The fright a maddened animal's first bite spreads: radius, severity, seconds, sight, sound.
const BITE_THREAT := [0.7, 0.4, 5.0, 3.5, 5.0]
const BITE_ALARM := 0.6
## The wait poses and their chances (Animal.IDLES).
const IDLE_WEIGHTS := [[&"sit", 0.3], [&"idle", 0.25], [&"sniff", 0.2], [&"scratch", 0.1], [&"bark", 0.1],
	[&"lie", 0.05]]
## At night (the NIGHT lighting look, TownLook.active): dogs sleep most of it and keep near home, cats prowl -- they
## roam farther and rest less. The wait poses' chances by kind, the waits' length and the roam's reach, against the day.
const NIGHT_DOG_IDLES := [[&"lie", 0.55], [&"sit", 0.2], [&"idle", 0.15], [&"sniff", 0.05], [&"bark", 0.05]]
const NIGHT_CAT_IDLES := [[&"sit", 0.35], [&"idle", 0.25], [&"sniff", 0.25], [&"lie", 0.15]]
const NIGHT_DOG_WAIT := 2.5
const NIGHT_CAT_WAIT := 0.6
const NIGHT_DOG_ROAM := 0.5
const NIGHT_CAT_ROAM := 1.6
const NIGHT_FOLLOW := 0.25
## A target it could not reach is left alone this long.
const SKIP_FOR := 3.0

var animals: Array[Animal] = []
var rng := RandomNumberGenerator.new()
var _crowd: Crowd
var _grid: WalkGrid
var _parent: Node2D
var _seen_threats := {}
var _check_in := 0.0
## Animal -> seconds a soldier has been on it.
var _cut := {}
## Animals whose bites have spread a fright this spell.
var _cried := {}
## Animal -> [person it could not reach, seconds left].
var _skip := {}


func setup(crowd: Crowd, grid: WalkGrid, parent: Node2D, seed_value: int) -> AnimalPack:
	_crowd = crowd
	_grid = grid
	_parent = parent
	rng.seed = seed_value + SEED_OFFSET
	name = "AnimalPack"
	return self


## Spawns `count` animals (by default by the citizens) at the citizens' starting spots, read only.
func spawn(count := -1) -> void:
	var people := _crowd.citizens
	if people.is_empty():
		return
	if count < 0:
		count = clampi(people.size() / PER_CITIZENS, MIN, MAX)
	for i in count:
		var who: Person = people[rng.randi_range(0, people.size() - 1)]
		var at := who.anchor + Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
		if _grid != null:
			at = _near(at, 3, who.anchor)
		var a := Animal.new()
		var dog := rng.randf() < DOG_SHARE
		var kinds: Array[Animal.Breed] = Animal.DOGS if dog else Animal.CATS
		a.breed = kinds[rng.randi_range(0, kinds.size() - 1)]
		a.ground_pos = at
		a.home = at
		a.goal = at
		a.facing = 1 if rng.randf() < 0.5 else -1
		a.wait = rng.randf_range(0.0, SIT.y)
		a.name = "Animal%d" % i
		a.sync_position()
		_parent.add_child(a)
		animals.append(a)


## Frees every animal (Crowd.clear()).
func clear() -> void:
	for a in animals:
		if is_instance_valid(a):
			if a.is_inside_tree():
				a.queue_free()
			else:
				a.free()
	animals.clear()
	_cut.clear()
	_cried.clear()
	_skip.clear()


## Takes one animal out of the town for good (a power carries it off: The Far Gate): the pack forgets it and its node is
## freed. Nothing is left lying.
func take(a: Animal) -> void:
	animals.erase(a)
	_cut.erase(a)
	_cried.erase(a)
	_skip.erase(a)
	if is_instance_valid(a):
		if a.is_inside_tree():
			a.queue_free()
		else:
			a.free()


## The nearest walkable point to `to` within `cells`, else `fallback` (WalkGrid gives INF when there is none, and an
## animal sent there would walk off for ever).
func _near(to: Vector2, cells: int, fallback: Vector2) -> Vector2:
	var at := _grid.nearest_walkable(to, cells)
	return at if at.is_finite() else fallback


## The town is lit for night (Town.Look.NIGHT).
static func is_night() -> bool:
	return TownLook.active == Town.Look.NIGHT


func living() -> Array[Animal]:
	var out: Array[Animal] = []
	for a in animals:
		if is_instance_valid(a) and a.is_alive():
			out.append(a)
	return out


## The living within `r` of `at`, nearest first.
func in_radius(at: Vector2, r: float) -> Array[Animal]:
	var out: Array[Animal] = []
	for a in living():
		if a.ground_pos.distance_to(at) <= r:
			out.append(a)
	out.sort_custom(func(x: Animal, y: Animal) -> bool:
		return x.ground_pos.distance_squared_to(at) < y.ground_pos.distance_squared_to(at))
	return out


## A power at `at` of radius `r` takes the animals there (see Animal.cast()); returns how many. Draws no number from
## any rng, so a cast where no animal stands changes nothing.
static func cast(ctx: FxContext, at: Vector2, r: float, spell: Animal.Spell, seconds: float, who: Person = null,
		to := Vector2.INF) -> int:
	if ctx == null or ctx.crowd == null or ctx.crowd.animals == null:
		return 0
	var n := 0
	for a in ctx.crowd.animals.in_radius(at, r):
		if a.cast(spell, seconds, who, to if to != Vector2.INF else at):
			n += 1
	return n


func _process(delta: float) -> void:
	if _crowd == null or _crowd.is_frozen():
		return
	step(delta)


func step(delta: float) -> void:
	_check_in -= delta
	if _check_in <= 0.0:
		_check_in = 0.25
		_check_threats()
	for a in _skip.keys():
		_skip[a][1] -= delta
		if _skip[a][1] <= 0.0:
			_skip.erase(a)
	for a in animals:
		if not is_instance_valid(a):
			continue
		a.tick_visual(delta)
		if not a.is_alive():
			continue
		if a.spell_left > 0.0:
			a.spell_left -= delta
			if a.spell_left <= 0.0:
				_cried.erase(a)
				_cut.erase(a)
				a.release()
				continue
		match a.state:
			Animal.State.WANDER:
				_wander(a, delta)
			Animal.State.SIT:
				_wander(a, delta)
			Animal.State.FOLLOW:
				_follow(a, delta)
			Animal.State.FLEE:
				if a.route_to(a.goal, delta, _grid):
					a.state = Animal.State.WANDER
					a.home = a.ground_pos
					a.wait = rng.randf_range(SIT.x, SIT.y)
			Animal.State.ATTACK:
				_attack(a, delta)
			Animal.State.GATHER:
				if a.wait <= 0.0 and a.route_to(a.goal, delta, _grid):
					a.wait = 999.0
					a.queue_redraw()
			Animal.State.TRANCE:
				pass


func _wander(a: Animal, delta: float) -> void:
	if a.wait > 0.0:
		a.wait -= delta
		if a.wait <= 0.0:
			_next_errand(a)
			a.queue_redraw()
		return
	if a.route_to(a.goal, delta, _grid):
		a.idle = _pick_idle(a)
		a.wait = rng.randf_range(SIT.x, SIT.y) * (1.6 if not a.is_dog() else 1.0) * (2.0 if a.idle == &"lie" else 1.0)
		if is_night():
			a.wait *= NIGHT_DOG_WAIT if a.is_dog() else NIGHT_CAT_WAIT
		a.queue_redraw()


## What it does while it waits, by weight.
func _pick_idle(a: Animal) -> StringName:
	var table: Array = IDLE_WEIGHTS
	if is_night():
		table = NIGHT_DOG_IDLES if a.is_dog() else NIGHT_CAT_IDLES
	var r := rng.randf()
	for pair in table:
		r -= float(pair[1])
		if r < 0.0:
			return pair[0]
	return &"sit"


func _next_errand(a: Animal) -> void:
	if a.is_dog() and rng.randf() < FOLLOW_CHANCE * (NIGHT_FOLLOW if is_night() else 1.0):
		var who := _nearest_person(a.ground_pos, FOLLOW_REACH, true)
		if who != null:
			a.state = Animal.State.FOLLOW
			a.target = who
			a.wait = -rng.randf_range(FOLLOW_TIME.x, FOLLOW_TIME.y)  # negative: how long it tags along
			return
	a.state = Animal.State.WANDER
	var roam := ROAM
	if is_night():
		roam *= NIGHT_DOG_ROAM if a.is_dog() else NIGHT_CAT_ROAM
	var to := a.home + Vector2(rng.randf_range(-roam, roam), rng.randf_range(-roam, roam))
	if _grid != null:
		to = _near(to, 3, a.ground_pos)
		if not _grid.clear_line(a.ground_pos, to):
			to = a.ground_pos + (to - a.ground_pos) * 0.3
	a.goal = to


func _follow(a: Animal, delta: float) -> void:
	a.wait += delta
	var who := a.target
	if a.wait >= 0.0 or who == null or not is_instance_valid(who) or not who.is_alive() or who.inside \
			or a.ground_pos.distance_to(who.ground_pos) > FOLLOW_REACH * 2.5:
		a.state = Animal.State.WANDER
		a.target = null
		a.home = a.ground_pos
		a.wait = rng.randf_range(SIT.x, SIT.y)
		a.queue_redraw()
		return
	if a.ground_pos.distance_to(who.ground_pos) > FOLLOW_GAP:
		if a.route_to(who.ground_pos, delta, _grid) and a.blocked:
			a.wait = 0.0  # cannot reach them: stop following next step


func _attack(a: Animal, delta: float) -> void:
	var who := a.target
	if who == null or not is_instance_valid(who) or not who.is_alive() or who.inside or _skipped(a, who):
		who = _nearest_person(a.ground_pos, Animal.HUNT_SIGHT, false, a)
		a.target = who
	if who == null:
		a.wait = 0.5
		return
	a._bite_in -= delta
	if a.ground_pos.distance_to(who.ground_pos) > Animal.REACH:
		if a.route_to(who.ground_pos, delta, _grid) and a.blocked:
			# A wall between them: go for someone else a while.
			_skip[a] = [who, SKIP_FOR]
			a.target = null
	elif a._bite_in <= 0.0:
		a._bite_in = Animal.BITE_EVERY
		who.hurt_from(a.bite(), a.ground_pos)
		a.bit()
		if not _cried.has(a):
			_cried[a] = true
			_outcry(a)
	# A soldier beside it cuts it down.
	for s in _crowd.soldiers:
		if is_instance_valid(s) and s.is_alive() and s.ground_pos.distance_to(a.ground_pos) < SOLDIER_REACH:
			_cut[a] = float(_cut.get(a, 0.0)) + delta
			if float(_cut[a]) >= SOLDIER_KILL:
				_cut.erase(a)
				a.die()
			return


## Its first bite: the town sees a danger there and the alarm rises, as a maddened citizen's frenzy does.
func _outcry(a: Animal) -> void:
	var t: Array = BITE_THREAT
	_crowd.fright(a.ground_pos, float(t[0]), float(t[1]), float(t[2]), float(t[3]), float(t[4]), &"bite", false)
	_crowd.add_alarm(BITE_ALARM)


## The nearest living person out in the open within `reach`; `calm` for a citizen going about its day only.
func _skipped(a: Animal, who: Person) -> bool:
	return _skip.has(a) and _skip[a][0] == who


func _nearest_person(at: Vector2, reach: float, calm: bool, hunter: Animal = null) -> Person:
	var best: Person = null
	var best_d := reach
	for p in _crowd.citizens:
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		if hunter != null and _skipped(hunter, p):
			continue
		if calm and p.mind != Person.Mind.CALM:
			continue
		var d := p.ground_pos.distance_to(at)
		if d < best_d:
			best_d = d
			best = p
	if not calm:
		for p in _crowd.soldiers:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) < best_d \
					and not (hunter != null and _skipped(hunter, p)):
				best_d = p.ground_pos.distance_to(at)
				best = p
	return best


## New strikes kill the animals under them; any active danger near a free animal sends it running.
func _check_threats() -> void:
	var zones := _crowd.threats.all_zones()
	for t: Dictionary in zones:
		if not t.has("id"):
			continue
		var id := int(t.id)
		if _seen_threats.has(id):
			continue
		_seen_threats[id] = true
		if t.kind in HARMLESS:
			continue
		for a in in_radius(t.at, float(t.radius) * KILL_SHARE):
			a.die()
	for a in living():
		if a.hypnotized() or a.state == Animal.State.FLEE:
			continue
		for t: Dictionary in zones:
			if not t.has("id") or t.kind == &"bite":
				continue
			var at: Vector2 = t.at
			if a.ground_pos.distance_to(at) <= float(t.radius) + FLEE_REACH:
				var away := a.ground_pos - at
				if away.length() < 0.01:
					away = Vector2.RIGHT
				var to := a.ground_pos + away.normalized() * FLEE_DIST
				if _grid != null:
					to = _near(to, 4, a.ground_pos)
				a.state = Animal.State.FLEE
				a.target = null
				a.goal = to
				a.wait = 0.0
				break
