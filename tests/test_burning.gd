extends RefCounted
## Burning (Ember on a person, 2026-11-19): a reusable status on the crowd, modelled on the Withering. Laid on a person
## (Crowd.burn()) he panics with no shelter roll and runs; every SPREAD_EVERY a burnable building within SPREAD_R of him
## catches and the citizens within SEE_R who can see him are frightened; at BURN_FOR he dies as fire (no body to raise).
## Indoors, dead of something else, freed or cleared, it lapses with no fire death. A trail hook lays something behind
## him each TRAIL step (Ember's level 5 Fire Trail). Flames on him are drawn only.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func run(t) -> void:
	var made := RD._setup()
	_consts(t)
	_panics(t, made)
	_dies(t, made)
	_spreads(t, made)
	_fright(t, made)
	_indoors(t, made)
	_lapses(t, made)
	_trail(t, made)
	_cleared(t, made)
	_perf(t, made)
	RD._done(made)


static func _advance(crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / DT):
		crowd.advance(DT)


## The nth citizen still alive, calm and out in the open, at `at`.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var alive := (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var p: Person = alive[n]
	p.ground_pos = at
	p.inside = false
	p.mind = Person.Mind.CALM
	return p


static func _consts(t) -> void:
	t.check(Burning.BURN_FOR == 4.0 and Burning.SPREAD_EVERY == 0.5 and Burning.SPREAD_R == 0.8 and Burning.SEE_R == 4.0
		and Burning.KIND == &"fire" and not Remains.BODY_KINDS.has(Burning.KIND) and FireManager.FIRE_KINDS.has(Burning.KIND),
		"the brief's numbers; it kills as the town's own fire kind, which leaves no body")


## Laid: he burns, panics at once (no startle freeze) and never rolls for a shelter; a second lay, one inside or a dead
## one is refused.
static func _panics(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var sheltered := []
	var burned := 0
	for i in 16:
		var w := _put(made, 30 + i, grid.nearest_walkable(at + Vector2(float(i % 4) * 2.5 - 4.0, float(i / 4) * 2.5 - 4.0)))
		if crowd.burn(w, Burning.BURN_FOR, w.ground_pos + Vector2(0.5, 0.0)):
			burned += 1
		if w.mind == Person.Mind.SHELTER or w.shelter != null:
			sheltered.append(i)
	t.check(burned == 16 and sheltered.is_empty() and crowd.burning.count() == 16,
		"laid on 16: every one burns and none is sent for a shelter (%d burned, %s sent)" % [burned, sheltered])
	var first: Person = crowd.citizens.filter(func(q: Person) -> bool: return q.burning())[0]
	t.check(first.burning() and first.mind == Person.Mind.PANIC and not first.startled(),
		"he panics and runs at once (mind %d, startled %s)" % [first.mind, first.startled()])
	t.check(not crowd.burn(first, Burning.BURN_FOR, first.ground_pos), "a second burning on the burning runs nothing new")
	crowd.burning.clear()
	t.check(crowd.burning.count() == 0 and not first.burning(), "clear(): nobody burns")
	var indoor := _put(made, 50, at + Vector2(1.0, 0.0))
	indoor.inside = true
	t.check(not crowd.burn(indoor, Burning.BURN_FOR, at) and not indoor.burning(), "one indoors cannot be set alight")
	indoor.inside = false
	t.check(not crowd.burn(_put(made, 51, at + Vector2(-1.0, 0.0)), 0.0, at), "zero seconds lays nothing")


## At BURN_FOR he dies as fire, where he stands, and leaves no body.
static func _dies(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var p := _put(made, 21, at)
	var got := []
	var grab := func(e: DummyEnemy, kind: StringName) -> void: got.append([e, kind])
	field.enemy_killed.connect(grab)
	crowd.burn(p, Burning.BURN_FOR, at + Vector2(0.3, 0.0))
	_advance(crowd, Burning.BURN_FOR - 0.1)
	var alive_at := p.is_alive() and p.burning()
	_advance(crowd, 0.2)
	var pos := p.ground_pos
	field.enemy_killed.disconnect(grab)
	t.check(alive_at and not p.is_alive() and got.size() == 1 and got[0][0] == p and got[0][1] == Burning.KIND,
		"alive and burning at 3.9 s, dead at 4.1 s as fire (%s)" % [got])
	t.check(crowd.remains.pick(pos) == null and not p.burning() and crowd.burning.count() == 0,
		"a fire death leaves no raisable body, and the burning is done with him")


## A burnable house within SPREAD_R of him catches within one SPREAD_EVERY; at 2.0 it does not.
static func _spreads(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var house := RD._house(made[1], made[2])
	t.check(house != null and not crowd.fires.is_burning(house), "(set-up) a house that burns, not burning")
	var p := _put(made, 22, Vector2(house.footprint.end.x + 2.0, house.center().y))
	crowd.burn(p, Burning.BURN_FOR, p.ground_pos + Vector2(0.5, 0.0))
	_advance(crowd, Burning.SPREAD_EVERY * 2.0 + DT)
	var dark_far := not crowd.fires.is_burning(house)
	p.ground_pos = Vector2(house.footprint.end.x + 0.5, house.center().y)
	_advance(crowd, Burning.SPREAD_EVERY + DT)
	t.check(dark_far and crowd.fires.is_burning(house),
		"2.0 from the house it stays dark; brushing it (0.5) it catches within one SPREAD_EVERY")
	t.check(is_equal_approx(crowd.fires.intensity(house), Burning.LIGHT_AT) or crowd.fires.intensity(house) > Burning.LIGHT_AT,
		"it catches at Ember's start level (%.2f)" % crowd.fires.intensity(house))
	crowd.burning.clear()
	crowd.fires.clear()


## The citizens within SEE_R who can see him are frightened at the next SPREAD_EVERY; one at 5.0 is not.
static func _fright(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var at := RD._empty(made)
	var near_at := at + Vector2(3.0, 0.0)
	var far_at := grid.nearest_walkable(at + Vector2(0.0, 5.0))
	t.check(grid.clear_line(at, near_at) and absf(far_at.distance_to(at) - 5.0) < 0.3,
		"(set-up) a clear line to 3.0, a walkable spot at 5.0 (%.2f)" % far_at.distance_to(at))
	var p := _put(made, 23, at)
	var seer := _put(made, 24, near_at)
	var far := _put(made, 25, far_at)
	crowd.burn(p, Burning.BURN_FOR, at)
	var calm_at_once := seer.mind == Person.Mind.CALM
	_advance(crowd, Burning.SPREAD_EVERY + DT)
	t.check(calm_at_once and seer.mind == Person.Mind.PANIC and far.mind != Person.Mind.PANIC,
		"the one at 3.0 who sees him is frightened (mind %d), the one at 5.0 is not (mind %d)" % [seer.mind, far.mind])
	crowd.burning.clear()


## Indoors mid-burn it lapses at once: no fire death, ever.
static func _indoors(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var p := _put(made, 26, at)
	var got := []
	var grab := func(e: DummyEnemy, kind: StringName) -> void: got.append([e, kind])
	field.enemy_killed.connect(grab)
	crowd.burn(p, Burning.BURN_FOR, at)
	_advance(crowd, 1.0)
	p.inside = true
	_advance(crowd, DT)
	var lapsed := not p.burning() and crowd.burning.count() == 0
	_advance(crowd, Burning.BURN_FOR)
	field.enemy_killed.disconnect(grab)
	t.check(lapsed and p.is_alive() and got.is_empty(), "indoors mid-burn it lapses at once, and he lives (%s)" % [got])
	p.inside = false


## Killed by something else or freed mid-burn: no error, no fire death (Review Focus 2).
static func _lapses(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var slain := _put(made, 27, at)
	var carried := _put(made, 28, at + Vector2(2.0, 0.0))
	var got := []
	var grab := func(e: DummyEnemy, kind: StringName) -> void: got.append([e, kind])
	field.enemy_killed.connect(grab)
	crowd.burn(slain, Burning.BURN_FOR, at)
	crowd.burn(carried, Burning.BURN_FOR, at)
	_advance(crowd, 1.0)
	field.kill(slain, &"frenzy", slain.ground_pos)
	field.remove(carried)
	crowd.citizens.erase(carried)
	carried.free()
	_advance(crowd, Burning.BURN_FOR)
	field.enemy_killed.disconnect(grab)
	t.check(got.size() == 1 and got[0][0] == slain and got[0][1] == &"frenzy" and not slain.burning()
		and crowd.burning.count() == 0,
		"killed by something else or freed mid-burn: no error, no fire death (%s)" % [got])


## The trail hook: called with the spot he caught fire once he is `every` from it, then each time he has gone `every`
## further, `most` at most; never on a spot inside a building.
static func _trail(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var at := RD._empty(made)
	var p := _put(made, 29, at)
	var spots: Array[Vector2] = []
	crowd.burn(p, Burning.BURN_FOR, at)
	crowd.burning.trail(p, func(g: Vector2) -> void: spots.append(g), 1.0, 3)
	crowd.advance(DT)
	var none_yet := spots.is_empty()
	# He walks 6 units in steps of 0.25 (a straight line; his path's ground is not checked here).
	for i in 24:
		p.ground_pos += Vector2(0.25, 0.0)
		crowd.advance(DT)
	var spaced := spots.size() == 3 and spots[0].distance_to(at) < 0.001
	for k in range(1, spots.size()):
		spaced = spaced and spots[k].distance_to(spots[k - 1]) >= 1.0 - 0.001
	var clear := true
	for g in spots:
		clear = clear and not env.blocked(g, 0.0)
	t.check(none_yet and spaced and clear,
		"the trail: nothing while he stands, then the spot he caught fire, one each 1.0 he goes, 3 at most (%s)" % [spots])
	crowd.burning.clear()


## The town's end: nobody burns, and nobody dies of it.
static func _cleared(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p := _put(made, 31, at)
	crowd.burn(p, Burning.BURN_FOR, at)
	crowd.burning.clear()
	_advance(crowd, Burning.BURN_FOR + 0.5)
	t.check(p.is_alive() and not p.burning() and crowd.burning.count() == 0, "cleared: the burning lapses, he lives")


## 12 burning people in the town, each with a trail, running as they do: the burning's step costs under 1 ms a frame on
## average over 200 frames (Review Focus 5).
static func _perf(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var burners: Array[Person] = []
	for i in 12:
		var g := grid.nearest_walkable(Vector2(-18.0 + float(i % 4) * 12.0, -14.0 + float(i / 4) * 12.0))
		var p := _put(made, 60 + i, g)
		crowd.burn(p, 20.0, g + Vector2(0.4, 0.0))
		crowd.burning.trail(p, crowd.fires.lay, 1.0, 8)
		burners.append(p)
	# Neighbours to frighten: the town spread about them.
	for i in 60:
		_put(made, 80 + i, grid.nearest_walkable(burners[i % 12].ground_pos + Vector2(float(i % 5) - 2.0, float(i % 3) + 1.0)))
	var spent := 0
	for f in 200:
		for p in burners:
			if is_instance_valid(p) and p.is_alive():
				p.frame(DT)
		var t0 := Time.get_ticks_usec()
		crowd.burning.step(DT)
		spent += Time.get_ticks_usec() - t0
	var ms := float(spent) / 200.0 / 1000.0
	print("burning perf: 12 burning, %d people, %.4f ms a step on average over 200 frames, %d patches laid"
		% [crowd.citizens.size() + crowd.soldiers.size(), ms, crowd.fires.patches_laid])
	t.check(ms < 1.0, "12 burning people: %.4f ms a step averaged over 200 frames (under 1 ms)" % ms)
	crowd.burning.clear()
	crowd.fires.clear()
