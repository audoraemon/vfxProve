class_name Visitors
extends RefCounted
## Visitors: hostile walkers from the other side, the god's to send (Hound Gate first; Hellmouth, Hell's Parade and The
## Hellgate after). Each is an Animal (of the breed its summoner picks: Hound Gate's is the hellhound, with its own painted sheet) that the town's AnimalPack
## never steps: it is summoned at a gate, hunts whoever is nearest -- citizen or soldier, alive and out in the open,
## within its seek reach, the nearest looked for again every RETARGET -- and bites whoever it reaches (hurt_from: a
## citizen falls to one bite, a soldier to two; the dead are the god's, damage kind frenzy). It fears nothing: no
## threat, strike or fright ever sets it running, and it never flees -- but for a law that takes the air (NO BREATH):
## it runs out of that (_flee_law()). The guard cuts it down: a soldier within
## GUARD_REACH of one lands a blow every GUARD_SWING (the first after a swing's wait; he strikes one visitor at a
## time), and at `blows` blows it dies. A visitor summoned to flinch must begin its bite again each time it is struck,
## so one guard holds one off; one that does not flinch bites through the blows, and a lone guard falls to it.
## Soldiers within the seek reach standing at their post are drawn to the nearest visitor every LURE_EVERY so they
## come to fight. It runs round buildings by the streets (Animal.route_to()); a target there is no way to is left alone
## SKIP_FOR. recall() sends every visitor back
## to its gate, where it is freed. The owner steps it (step()) every frame and clears it (clear()) at the end; it keeps
## count of its kills and of the visitors slain. From setup() to clear() the pack is listed in Crowd.visitors, so a power
## that moves whoever walks a place moves its visitors too (The Folded Ward).
## Traits (give()) change how one goes about it: `phase` walks straight through walls and houses to its prey (a ghost),
## `wreck` claws at buildings (a demon): every `wreck_every` it strikes the building within `wreck_reach` of it for
## `wreck` (damage kind frenzy) -- running past one at its prey as much as standing at one -- and with nobody in
## reach it goes for the nearest building within its seek reach instead, unless `wreck_idle` is false (Grave Tide's giant:
## it smashes only what stands in its way as it goes, never leaves the street for a house, nor claws one it stands idle by).
## Death's undead go by more traits: `knock_first` (the first bite on a citizen only knocks them down, a second within
## KNOCK_WINDOW kills; after that the next knocks again), `infect` (a bite also gives the plague), `spare_guise` (never
## picks a person under the Corpse Guise status), `prey` "soldiers" (hunts soldiers only), `fright_r` (frightens the
## crowd within it every FRIGHT_EVERY, as the Doors of the Dead's ghosts do), `slow` (whoever it passes through, within
## `slow_r`, keeps `slow` of their pace for `slow_for` seconds: hold_pace()) and `no_bite` (it comes to its prey and
## does not bite: a spirit passes through).
## `march` (a ground point; Grave Tide's horde) sends it there first, by the streets (straight, with `phase`), for
## `march_for` seconds at most: on the way it turns only on whoever comes within MARCH_SEEK of it, and once within
## MARCH_NEAR of the point (or blocked, or out of time) it hunts as above. `bite` is what one bite takes off a person's
## health (1 by default: a citizen falls to one, a soldier to two; Grave Tide's giant fells a soldier with one).
## A marked prey (mark(): Hound Gate's Quarry) is hunted by every visitor of the pack, at any distance, by the streets,
## in place of the nearest within reach, until it falls or goes inside (the mark is dropped then) or another is marked;
## one there is no way to is left alone SKIP_FOR like any other. A visitor with `bounds` leaves a mark outside them alone.
## With nothing marked the hunt is as above.

## How often a visitor looks for the nearest person again, and how long it leaves one it could not reach.
const RETARGET := 0.5
const SKIP_FOR := 1.0
## It runs the streets' way round to its prey (Animal.route_to()), planned again this often: the prey moves.
const CHASE_REPATH := 0.5
## Where the air has gone (a NO BREATH law) a visitor runs this far past the nearest edge.
const AIR_CLEAR := 1.0
## The guard: a soldier this near a visitor strikes it every GUARD_SWING.
const GUARD_REACH := 0.6
const GUARD_SWING := 0.8
## A wrecker looks for the building beside it this often (a look asks the town's buildings near it).
const WRECK_LOOK := 0.2
## Soldiers at their post within a visitor's seek reach are drawn to it this often, for this long.
const LURE_EVERY := 1.0
const LURE_FOR := 1.5
## knock_first: a second bite within this long of the first kills.
const KNOCK_WINDOW := 3.0
## fright_r: how often the crowd round it is frightened.
const FRIGHT_EVERY := 1.0
## march: it is there within MARCH_NEAR of the point; on the way it turns only on whoever comes within MARCH_SEEK.
const MARCH_NEAR := 1.5
const MARCH_SEEK := 1.5
## march: how long it may take when give() names no `march_for`.
const MARCH_FOR := 20.0

## A visitor bit `victim` (its first bite too: the owner spreads the outcry).
signal bitten(visitor: Animal, victim: Person, first: bool)
## A visitor was cut down at `at` (its node is freed right after).
signal cut_down(visitor: Animal, at: Vector2)
## A visitor with `wreck` struck building `s`.
signal wrecked(visitor: Animal, s: Structure)

## People bitten dead, and visitors cut down.
var kills := 0
var slain := 0

var _field: EnemyField
var _crowd: Crowd
var _grid: WalkGrid
var _parent: Node2D
## Animal -> its Rule.
var _rules := {}
## Person (a soldier) -> seconds to his next blow, while he stands by a visitor.
var _swings := {}
var _lure_in := 0.0
## The field's living, taken once a step when someone first needs them (_people()).
var _living: Array = []
var _living_taken := false
## The prey every visitor goes for (mark()), or null.
var _mark: Person
## Animal instance id -> {Person -> seconds its pace hold has left} (give()'s `slow`); lifted when the time is up or the visitor goes.
var _slows := {}


## What one visitor is and does.
class Rule extends RefCounted:
	var gate := Vector2.ZERO
	var seek_r := 8.0
	var bite_r := 0.5
	var bite_every := 1.0
	var retarget_in := 0.0
	var bite_in := 0.0
	## Whom it leaves alone a while (it could not reach them), and for how long.
	var skip: Person
	var skip_left := 0.0
	var has_bitten := false
	## Struck, it begins its bite again (summon()'s `flinch`).
	var flinch := true
	var recalling := false
	var recall_left := 0.0
	## give(): through walls; and the blow it deals buildings (0: none), how often, how near.
	var phase := false
	var wreck := 0.0
	var wreck_every := 1.5
	var wreck_reach := 0.5
	var wreck_in := 0.0
	## With nobody to hunt, it goes at the nearest building (false: it only strikes what it passes).
	var wreck_idle := true
	## The building it is going for, with nobody to hunt; the one beside it, looked for every WRECK_LOOK.
	var house: Structure
	var beside: Structure
	var look_in := 0.0
	## give(): Death's undead (see the class comment).
	var knock_first := false
	var infect := false
	var spare_guise := false
	var soldiers_only := false
	var no_bite := false
	## touch_kill: its touch kills outright as this kind (&"": it bites as above); spent_on_kill: freed after one.
	var touch_kill: StringName = &""
	var spent_on_kill := false
	## bounds (cx, cy, r): it only hunts people within r of (cx, cy). r <= 0: anywhere.
	var bounds := Vector3.ZERO
	var fright_r := 0.0
	var fright_in := 0.0
	var slow := 1.0
	var slow_for := 4.0
	var slow_r := 0.5
	## give(): what a bite takes off; the point it walks to before it hunts (INF: none) and how long it may take.
	var bite := 1.0
	var march := Vector2.INF
	var march_left := 0.0
	## knock_first: whom it has knocked down -> seconds left in which a second bite kills.
	var knocked := {}


func setup(field: EnemyField, crowd: Crowd, grid: WalkGrid, parent: Node2D) -> Visitors:
	_field = field
	_crowd = crowd
	_grid = grid
	_parent = parent
	if crowd != null and not crowd.visitors.has(self):
		crowd.visitors.append(self)
	return self


## A visitor comes through at `at`: a `breed` that takes `blows` blows, runs at `speed_mul` times its breed's run,
## hunts within `seek_r`, bites within `bite_r` every `bite_every`, and -- when `flinch` -- begins its bite again
## each time it is struck. Its node is added to the parent; the Animal is returned for the owner's looks.
func summon(at: Vector2, breed: Animal.Breed, blows: int, speed_mul: float, seek_r: float, bite_r: float,
		bite_every: float, flinch := true) -> Animal:
	var a := Animal.new()
	a.breed = breed
	a.ground_pos = at
	a.home = at
	a.goal = at
	a.health = float(blows)
	a.speed_mul = speed_mul
	a.state = Animal.State.ATTACK  # its run; spell_left stays 0, so it wears no power's mark
	a.wait = 0.0
	a.name = "Visitor%d" % _rules.size()
	a.sync_position()
	_parent.add_child(a)
	var r := Rule.new()
	r.gate = at
	r.seek_r = seek_r
	r.bite_r = bite_r
	r.bite_every = bite_every
	r.flinch = flinch
	_rules[a] = r
	return a


## Traits for visitor `a` (summon()'s): {"phase": bool, "wreck": damage, "wreck_every": s, "wreck_reach": units}.
func give(a: Animal, traits: Dictionary) -> void:
	var r: Rule = _rules.get(a)
	if r == null:
		return
	r.phase = bool(traits.get("phase", r.phase))
	r.wreck = float(traits.get("wreck", r.wreck))
	r.wreck_every = float(traits.get("wreck_every", r.wreck_every))
	r.wreck_reach = float(traits.get("wreck_reach", r.wreck_reach))
	if traits.has("wreck") or traits.has("wreck_every"):
		r.wreck_in = r.wreck_every * 0.5  # its first blow half a swing in (only as the claws are given: a renewed march keeps the count)
	r.wreck_idle = bool(traits.get("wreck_idle", r.wreck_idle))
	r.knock_first = bool(traits.get("knock_first", r.knock_first))
	r.infect = bool(traits.get("infect", r.infect))
	r.spare_guise = bool(traits.get("spare_guise", r.spare_guise))
	r.no_bite = bool(traits.get("no_bite", r.no_bite))
	r.touch_kill = StringName(traits.get("touch_kill", r.touch_kill))
	r.spent_on_kill = bool(traits.get("spent_on_kill", r.spent_on_kill))
	r.bounds = traits.get("bounds", r.bounds)
	if traits.has("prey"):
		r.soldiers_only = String(traits.prey) == "soldiers"
	r.fright_r = float(traits.get("fright_r", r.fright_r))
	r.slow = float(traits.get("slow", r.slow))
	r.slow_for = float(traits.get("slow_for", r.slow_for))
	r.slow_r = float(traits.get("slow_r", r.slow_r))
	r.bite = float(traits.get("bite", r.bite))
	if traits.has("march"):
		r.march = traits.march
		r.march_left = float(traits.get("march_for", MARCH_FOR))


## Whether visitor `a` is still on its march (give()'s `march`).
func marching(a: Animal) -> bool:
	var r: Rule = _rules.get(a)
	return r != null and r.march != Vector2.INF


## The visitors still on their feet.
func living() -> Array[Animal]:
	var out: Array[Animal] = []
	for a in _rules.keys():
		if is_instance_valid(a) and a.is_alive():
			out.append(a)
	return out


## Every visitor runs back to its gate and is freed there, or after `seconds` wherever it is.
func recall(seconds: float) -> void:
	for a in _rules.keys():
		var r: Rule = _rules[a]
		r.recalling = true
		r.recall_left = seconds
		if is_instance_valid(a):
			a.target = null


## Takes one visitor out of the town for good (a power carries it off: Heaven's Door): the pack forgets it and its node
## is freed. It is not counted as slain.
func take(a: Animal) -> void:
	_rules.erase(a)
	_free(a)


## Every visitor of the pack goes for `p` (any distance, by the streets) until they fall or go inside; replaces any
## earlier mark. null clears it.
func mark(p: Person) -> void:
	_mark = p


func clear_mark() -> void:
	_mark = null


## The marked prey while it can still be hunted (alive, out in the open), or null -- a fallen or sheltered one's mark
## is dropped here.
func marked() -> Person:
	if _mark != null and not (is_instance_valid(_mark) and _mark.is_alive() and not _mark.inside):
		_mark = null
	return _mark


## Every visitor is freed at once (the owner's end). `deferred`: queued for freeing instead, for an owner's _exit_tree, whose
## parents may be mid-teardown.
func clear(deferred := false) -> void:
	_mark = null
	for a in _rules.keys():
		_free(a, deferred)
	_rules.clear()
	_swings.clear()
	if _crowd != null and is_instance_valid(_crowd):
		_crowd.visitors.erase(self)


func step(delta: float) -> void:
	_living = []
	_living_taken = false
	for a in _rules.keys():
		if not is_instance_valid(a):
			_rules.erase(a)
			continue
		var r: Rule = _rules[a]
		a.tick_visual(delta)
		if r.recalling:
			_go_home(a, r, delta)
			if not _rules.has(a):
				continue  # home, and freed: it slows nobody any more (a wraith's pass would hold a freed node's id)
		elif not _flee_law(a, r, delta):
			_hunt(a, r, delta)
			if not _rules.has(a):
				continue  # spent on its kill
		if r.fright_r > 0.0 and not r.recalling:
			_frighten(a, r, delta)
		if r.slow < 1.0:
			_pass_slow(a, r)
	_lift_slows(delta)
	_guard(delta)
	_lure_in -= delta
	if _lure_in <= 0.0:
		_lure_in = LURE_EVERY
		_lure()


## The hunt: the nearest person within reach, looked for again every RETARGET or when the one it has is gone; run to
## them; bite when within reach and the bite is up. Blocked, it leaves that one alone a while.
func _hunt(a: Animal, r: Rule, delta: float) -> void:
	r.retarget_in -= delta
	r.bite_in -= delta
	if r.skip_left > 0.0:
		r.skip_left -= delta
		if r.skip_left <= 0.0:
			r.skip = null
	if r.skip != null and not is_instance_valid(r.skip):
		r.skip = null  # the one it left alone is gone from the town (freed)
	for k in r.knocked.keys():
		if not is_instance_valid(k) or float(r.knocked[k]) - delta <= 0.0:
			r.knocked.erase(k)
		else:
			r.knocked[k] = float(r.knocked[k]) - delta
	var marching := _marching(a, r, delta)
	var reach := MARCH_SEEK if marching else r.seek_r
	var who := a.target
	var quarry := marked()
	# A bounded one (a pale ghost) leaves a mark outside its bounds alone and hunts the nearest within them.
	if quarry != null and quarry != r.skip and _within(r, quarry):
		who = quarry  # the marked prey, wherever it is
		a.target = quarry
	else:
		if who != null and not (is_instance_valid(who) and who.is_alive() and not who.inside and _fair(r, who)
				and who.ground_pos.distance_to(a.ground_pos) <= reach and _within(r, who)):
			who = null
			a.target = null
			r.retarget_in = 0.0
		if r.retarget_in <= 0.0:
			r.retarget_in = RETARGET
			who = _nearest(a.ground_pos, reach, r.skip, r)
			a.target = who
	if r.wreck > 0.0:
		_wreck(a, r, delta, who == null and not marching)
	if who == null:
		if marching:
			_march_on(a, r, delta)
		return  # nobody near: it stands (or goes at a building), and looks again
	if a.ground_pos.distance_to(who.ground_pos) > r.bite_r:
		if r.phase:
			a.walk_to(who.ground_pos, delta, null)  # straight through whatever stands between
			return
		# Round the buildings by the streets; only one there is no way to at all is left alone a while.
		if a.route_to(who.ground_pos, delta, _grid, CHASE_REPATH) and a.blocked:
			r.skip = who
			r.skip_left = SKIP_FOR
			a.target = null
			r.retarget_in = 0.0
		return
	if r.bite_in > 0.0 or r.no_bite:
		return
	r.bite_in = r.bite_every
	a.facing = 1 if who.ground_pos.x - who.ground_pos.y > a.ground_pos.x - a.ground_pos.y else -1
	if r.touch_kill != &"":
		# Its touch kills outright: no knock, no hurt. Spent only when it did kill (the target may have fallen already).
		a.bit()
		var killed := _field.kill(who, r.touch_kill, a.ground_pos)
		if killed:
			kills += 1
		var touched := not r.has_bitten
		r.has_bitten = true
		bitten.emit(a, who, touched)
		if killed and r.spent_on_kill:
			_rules.erase(a)
			_free(a, true)
		return
	a.bit()
	var was := who.is_alive()
	if r.knock_first and not who.soldier and not r.knocked.has(who):
		who.knock_down()  # the first bite only knocks them flat; a second within KNOCK_WINDOW kills
		r.knocked[who] = KNOCK_WINDOW
	else:
		who.hurt_from(r.bite, a.ground_pos)
	if r.infect and who.is_alive():
		who.infect(PlagueManager.PLAGUE_LIFE)
	if was and not who.is_alive():
		kills += 1
	var first := not r.has_bitten
	r.has_bitten = true
	bitten.emit(a, who, first)


## Whether it is still on its march: not yet within MARCH_NEAR of the point, and with time left. Ending it, it looks for
## prey at once.
func _marching(a: Animal, r: Rule, delta: float) -> bool:
	if r.march == Vector2.INF:
		return false
	r.march_left -= delta
	if r.march_left <= 0.0 or a.ground_pos.distance_to(r.march) <= MARCH_NEAR:
		_end_march(a, r)
		return false
	return true


func _end_march(a: Animal, r: Rule) -> void:
	r.march = Vector2.INF
	r.retarget_in = 0.0
	a.target = null


## One step of the march: by the streets (straight through, with phase); one that cannot get there hunts from here.
func _march_on(a: Animal, r: Rule, delta: float) -> void:
	if r.phase:
		if a.walk_to(r.march, delta, null):
			_end_march(a, r)
		return
	if a.route_to(r.march, delta, _grid) and a.blocked:
		_end_march(a, r)


## A wrecker's claws: the building beside it is struck every wreck_every; with nobody to hunt (`idle`) it goes to the
## nearest building within its seek reach (to the open ground at the face nearest it) and strikes that.
func _wreck(a: Animal, r: Rule, delta: float, idle: bool) -> void:
	r.wreck_in -= delta
	r.look_in -= delta
	var env := _field.env if _field != null else null
	if env == null:
		return
	var best := INF
	if r.look_in <= 0.0 or (r.beside != null and not _wreckable(r.beside)):
		r.look_in = WRECK_LOOK
		r.beside = null
		for s in env.near(a.ground_pos, r.wreck_reach):
			if _wreckable(s):
				var d := s.distance_to(a.ground_pos)
				if d < best:
					best = d
					r.beside = s
	var beside := r.beside
	# One that does not go at buildings (wreck_idle false) strikes only what stands in its way: never standing idle.
	if beside != null and r.wreck_in <= 0.0 and (r.wreck_idle or not idle):
		r.wreck_in = r.wreck_every
		a.facing = 1 if beside.center().x - beside.center().y > a.ground_pos.x - a.ground_pos.y else -1
		a.bit()
		beside.damage(r.wreck, a.ground_pos, &"frenzy")
		wrecked.emit(a, beside)
	if not idle or beside != null or not r.wreck_idle:
		return
	if r.house == null or not _wreckable(r.house) or r.house.distance_to(a.ground_pos) > r.seek_r:
		r.house = null
		best = INF
		for s in env.near(a.ground_pos, r.seek_r):
			if _wreckable(s):
				var d := s.distance_to(a.ground_pos)
				if d < best:
					best = d
					r.house = s
	if r.house == null:
		return
	var face := a.ground_pos.clamp(r.house.footprint.position, r.house.footprint.end)
	var out := (a.ground_pos - face)
	var to := face + (out.normalized() if out.length() > 0.01 else Vector2.DOWN) * (r.wreck_reach * 0.5)
	if r.phase:
		a.walk_to(to, delta, null)
	elif a.route_to(to, delta, _grid, 1.0) and a.blocked:
		r.house = null


## A building a wrecker can strike: standing, solid (not a field, rubble or the bridge), not a power's own pile.
static func _wreckable(s: Structure) -> bool:
	return is_instance_valid(s) and not s.destroyed and not s.walkable and not (s.role in [&"thorns", &"windfall", &"decree"])


## A visitor standing where the air has gone (a NO BREATH law: Breathing Is Prohibited) runs for the nearest edge,
## AIR_CLEAR past it, instead of hunting: the other side breathes too. It never dies of it. True while it flees.
func _flee_law(a: Animal, r: Rule, delta: float) -> bool:
	if _crowd == null or _crowd.laws.is_empty():
		return false
	var z := _crowd.law_of(a, LawZone.NO_BREATH)
	if z == null:
		return false
	var out := z.nearest_outside(a.ground_pos, AIR_CLEAR)
	if r.phase:
		a.walk_to(out, delta, null)
	else:
		a.route_to(out, delta, _grid, CHASE_REPATH)
	return true


## Recalled: back to the gate, freed there or when the time is up.
func _go_home(a: Animal, r: Rule, delta: float) -> void:
	r.recall_left -= delta
	if r.phase:
		if r.recall_left <= 0.0 or a.walk_to(r.gate, delta, null):
			_rules.erase(a)
			_free(a)
		return
	if r.recall_left <= 0.0 or a.route_to(r.gate, delta, _grid):
		_rules.erase(a)
		_free(a)


## Whether visitor rule `r` may hunt `p` at all: not a guised person under spare_guise, and a soldier under prey "soldiers".
static func _fair(r: Rule, p: Person) -> bool:
	if r.spare_guise and p.guised():
		return false
	return not r.soldiers_only or p.soldier


## Whether `p` stands inside rule `r`'s bounds (always, with none).
static func _within(r: Rule, p: Person) -> bool:
	if r.bounds.z <= 0.0:
		return true
	return p.ground_pos.distance_to(Vector2(r.bounds.x, r.bounds.y)) <= r.bounds.z


## The nearest living person out in the open within `reach` of `at`, but for `skip` (and, with a rule, those it never hunts).
func _nearest(at: Vector2, reach: float, skip: Person, r: Rule = null) -> Person:
	var best: Person = null
	var best_d := INF
	var r2 := reach * reach
	for e in _people():
		var p := e as Person
		# Alive asked again: one bitten earlier this step is still on the step's list.
		if p == null or p.inside or p == skip or not p.is_alive() or (r != null and not (_fair(r, p) and _within(r, p))):
			continue
		var d := p.ground_pos.distance_squared_to(at)
		if d > r2:
			continue
		if d < best_d:
			best_d = d
			best = p
	return best


## The field's living this step, in its order (EnemyField.in_radius() builds this list on every call: a horde asking it
## round every visitor made that the dearest thing in the frame).
func _people() -> Array:
	if not _living_taken:
		_living_taken = true
		_living = _field.alive()
	return _living


## The guard: every soldier standing by a visitor strikes the nearest one every GUARD_SWING (the first blow after one
## swing's wait); a struck visitor that flinches begins its bite again; at its last blow it is cut down and freed.
func _guard(delta: float) -> void:
	var near := {}  # soldier -> the nearest visitor within reach
	# The soldiers who can strike, once a step in the field's order (_people()).
	var guards: Array[Person] = []
	if not _rules.is_empty():
		for e in _people():
			var p := e as Person
			if p != null and p.soldier and p.is_alive() and not p.inside and not p.is_down():
				guards.append(p)
	var reach2 := GUARD_REACH * GUARD_REACH
	for a in _rules.keys():
		if not is_instance_valid(a) or not a.is_alive():
			continue
		for p in guards:
			var d: float = a.ground_pos.distance_squared_to(p.ground_pos)
			if d > reach2:
				continue
			if not near.has(p) or d < (near[p] as Animal).ground_pos.distance_squared_to(p.ground_pos):
				near[p] = a
	for p in _swings.keys():
		if not near.has(p):
			_swings.erase(p)  # stepped away: the next approach begins with a fresh swing
	for p in near.keys():
		var left := float(_swings.get(p, GUARD_SWING)) - delta
		if left > 0.0:
			_swings[p] = left
			continue
		_swings[p] = GUARD_SWING
		var a: Animal = near[p]
		if not is_instance_valid(a) or not a.is_alive():
			continue
		a.hurt(1.0)
		var r: Rule = _rules[a]
		if r.flinch:
			r.bite_in = maxf(r.bite_in, r.bite_every)
		if not a.is_alive():
			slain += 1
			var at := a.ground_pos
			_rules.erase(a)
			cut_down.emit(a, at)
			_free(a)


## Soldiers at their post within a visitor's seek reach are drawn to the nearest visitor (lure(): only a soldier at his
## post or holding ground answers; one already on his way, fighting or ordered elsewhere does not).
func _lure() -> void:
	var seen := {}
	for a in _rules.keys():
		if not is_instance_valid(a) or not a.is_alive():
			continue
		var r: Rule = _rules[a]
		if r.recalling:
			continue
		for e in _field.in_radius(a.ground_pos, r.seek_r):
			var p := e as Person
			if p == null or not p.soldier or p.inside or seen.has(p):
				continue
			seen[p] = true
			var nearest := _nearest_visitor(p.ground_pos)
			if nearest != null and p.ground_pos.distance_to(nearest.ground_pos) > GUARD_REACH:
				p.lure(nearest.ground_pos, LURE_FOR)


## fright_r: the crowd within it is frightened every FRIGHT_EVERY (Crowd.fright(), as the Doors of the Dead's ghosts do).
func _frighten(a: Animal, r: Rule, delta: float) -> void:
	r.fright_in -= delta
	if r.fright_in > 0.0:
		return
	r.fright_in = FRIGHT_EVERY
	if _crowd != null and is_instance_valid(_crowd):
		_crowd.fright(a.ground_pos, r.fright_r, 0.5, 2.0, 3.0, 3.0, &"beast")


## slow: whoever it is passing through keeps `slow` of their pace for `slow_for` (each visitor holds under its own id).
func _pass_slow(a: Animal, r: Rule) -> void:
	var id := a.get_instance_id()
	var held: Dictionary = _slows.get(id, {})
	var r2 := r.slow_r * r.slow_r
	for e in _people():
		var p := e as Person
		if p == null or not p.is_alive() or p.ground_pos.distance_squared_to(a.ground_pos) > r2:
			continue
		p.hold_pace(id, r.slow)
		held[p] = r.slow_for
	if not held.is_empty():
		_slows[id] = held


## Counts the pace holds down and lifts the ones that are up.
func _lift_slows(delta: float) -> void:
	for id in _slows.keys():
		var held: Dictionary = _slows[id]
		for p in held.keys():
			var left := float(held[p]) - delta
			if left > 0.0 and is_instance_valid(p):
				held[p] = left
				continue
			held.erase(p)
			if is_instance_valid(p):
				p.free_pace(id)
		if held.is_empty():
			_slows.erase(id)


func _nearest_visitor(at: Vector2) -> Animal:
	var best: Animal = null
	var best_d := INF
	for a in living():
		var r: Rule = _rules[a]
		if r.recalling:
			continue
		var d := a.ground_pos.distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = a
	return best


## Untyped: a visitor whose node another power freed is still a key here, and a freed node errors in a typed parameter.
func _free(a, deferred := false) -> void:
	if not is_instance_valid(a):
		return
	var id: int = a.get_instance_id()
	if _slows.has(id):
		for p in (_slows[id] as Dictionary).keys():
			if is_instance_valid(p):
				p.free_pace(id)
		_slows.erase(id)
	if deferred or a.is_inside_tree():
		a.queue_free()
	else:
		a.free()
