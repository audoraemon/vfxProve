class_name Visitors
extends RefCounted
## Visitors: hostile walkers from the other side, the god's to send (Hound Gate first; Hellmouth, Hell's Parade and The
## Hellgate after). Each is an Animal (the hound sheet, a breed of the town's own dogs) that the town's AnimalPack
## never steps: it is summoned at a gate, hunts whoever is nearest -- citizen or soldier, alive and out in the open,
## within its seek reach, the nearest looked for again every RETARGET -- and bites whoever it reaches (hurt_from: a
## citizen falls to one bite, a soldier to two; the dead are the god's, damage kind frenzy). It fears nothing: no
## threat, strike or fright ever sets it running, and it never flees. The guard cuts it down: a soldier within
## GUARD_REACH of one lands a blow every GUARD_SWING (the first after a swing's wait; he strikes one visitor at a
## time), and at `blows` blows it dies; a struck visitor flinches and must begin its bite again, so one guard holds one
## visitor off, two visitors on one guard bring him down. Soldiers within the seek reach standing at their post are
## drawn to the nearest visitor every LURE_EVERY so they come to fight. A target it cannot reach (a wall between) is
## left alone SKIP_FOR. recall() sends every visitor back to its gate, where it is freed. The owner steps it (step())
## every frame and clears it (clear()) at the end; it keeps count of its kills and of the visitors slain.

## How often a visitor looks for the nearest person again, and how long it leaves one it could not reach.
const RETARGET := 0.5
const SKIP_FOR := 1.0
## The guard: a soldier this near a visitor strikes it every GUARD_SWING.
const GUARD_REACH := 0.6
const GUARD_SWING := 0.8
## Soldiers at their post within a visitor's seek reach are drawn to it this often, for this long.
const LURE_EVERY := 1.0
const LURE_FOR := 1.5

## A visitor bit `victim` (its first bite too: the owner spreads the outcry).
signal bitten(visitor: Animal, victim: Person, first: bool)
## A visitor was cut down at `at` (its node is freed right after).
signal cut_down(visitor: Animal, at: Vector2)

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
	var recalling := false
	var recall_left := 0.0


func setup(field: EnemyField, crowd: Crowd, grid: WalkGrid, parent: Node2D) -> Visitors:
	_field = field
	_crowd = crowd
	_grid = grid
	_parent = parent
	return self


## A visitor comes through at `at`: a `breed` that takes `blows` blows, runs at `speed_mul` times its breed's run,
## hunts within `seek_r`, bites within `bite_r` every `bite_every`. Its node is added to the parent; the Animal is
## returned for the owner's looks (a tint, eyes).
func summon(at: Vector2, breed: Animal.Breed, blows: int, speed_mul: float, seek_r: float, bite_r: float,
		bite_every: float) -> Animal:
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
	_rules[a] = r
	return a


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


## Every visitor is freed at once (the owner's end).
func clear() -> void:
	for a in _rules.keys():
		_free(a)
	_rules.clear()
	_swings.clear()


func step(delta: float) -> void:
	for a in _rules.keys():
		if not is_instance_valid(a):
			_rules.erase(a)
			continue
		var r: Rule = _rules[a]
		a.tick_visual(delta)
		if r.recalling:
			_go_home(a, r, delta)
		else:
			_hunt(a, r, delta)
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
	var who := a.target
	if who != null and not (is_instance_valid(who) and who.is_alive() and not who.inside
			and who.ground_pos.distance_to(a.ground_pos) <= r.seek_r):
		who = null
		a.target = null
		r.retarget_in = 0.0
	if r.retarget_in <= 0.0:
		r.retarget_in = RETARGET
		who = _nearest(a.ground_pos, r.seek_r, r.skip)
		a.target = who
	if who == null:
		return  # nobody near: it stands, and looks again
	if a.ground_pos.distance_to(who.ground_pos) > r.bite_r:
		if a.walk_to(who.ground_pos, delta, _grid) and a.blocked:
			r.skip = who
			r.skip_left = SKIP_FOR
			a.target = null
			r.retarget_in = 0.0
		return
	if r.bite_in > 0.0:
		return
	r.bite_in = r.bite_every
	a.facing = 1 if who.ground_pos.x - who.ground_pos.y > a.ground_pos.x - a.ground_pos.y else -1
	a.bit()
	var was := who.is_alive()
	who.hurt_from(1.0, a.ground_pos)
	if was and not who.is_alive():
		kills += 1
	var first := not r.has_bitten
	r.has_bitten = true
	bitten.emit(a, who, first)


## Recalled: back to the gate, freed there or when the time is up.
func _go_home(a: Animal, r: Rule, delta: float) -> void:
	r.recall_left -= delta
	if r.recall_left <= 0.0 or a.walk_to(r.gate, delta, _grid):
		_rules.erase(a)
		_free(a)


## The nearest living person out in the open within `reach` of `at`, but for `skip`.
func _nearest(at: Vector2, reach: float, skip: Person) -> Person:
	var best: Person = null
	var best_d := INF
	for e in _field.in_radius(at, reach):
		var p := e as Person
		if p == null or p.inside or p == skip:
			continue
		var d := p.ground_pos.distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = p
	return best


## The guard: every soldier standing by a visitor strikes the nearest one every GUARD_SWING (the first blow after one
## swing's wait); a struck visitor flinches, its bite begun again; at its last blow it is cut down and freed.
func _guard(delta: float) -> void:
	var near := {}  # soldier -> the nearest visitor within reach
	for a in _rules.keys():
		if not is_instance_valid(a) or not a.is_alive():
			continue
		for e in _field.in_radius(a.ground_pos, GUARD_REACH):
			var p := e as Person
			if p == null or not p.soldier or p.inside or p.is_down():
				continue
			if not near.has(p) or a.ground_pos.distance_squared_to(p.ground_pos) \
					< (near[p] as Animal).ground_pos.distance_squared_to(p.ground_pos):
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


func _free(a: Animal) -> void:
	if not is_instance_valid(a):
		return
	if a.is_inside_tree():
		a.queue_free()
	else:
		a.free()
