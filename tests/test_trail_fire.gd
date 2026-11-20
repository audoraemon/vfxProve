extends RefCounted
## Trail fire (TrailFire, 2026-11-20: Ember's level 5 Fire Trail, the user's playtest): a reusable ground hazard on the town,
## apart from the town's GroundFire. A patch lives LIFE, fading over its last FADE, and burns out by itself. It frightens
## nobody, calls no beater and never catches a building. Whoever stands on it builds heat: a quick crossing hurts and
## scorches, KILL_AFTER in all kills as the fire kind (no raisable body); heat leaves him slowly off it. The one who laid it
## (the burning man) is spared; people inside are never touched. Cleared with the town. Drawn by its own layer.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func run(t) -> void:
	_consts(t)
	var made := RD._setup()
	_lazy(t, made)
	_life(t, made)
	_no_fright(t, made)
	_crossing(t, made)
	_kills(t, made)
	_cools(t, made)
	_no_building(t, made)
	_spared(t, made)
	_inside(t, made)
	_bad_ground(t, made)
	_perf(t, made)
	await _draws(t, made)
	_cleared(t, made)
	RD._done(made)
	t.check(made[0].trail_fire == null or made[0].trail_fire.count() == 0, "the town's end clears the trail fire")


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
	p.scorched_left = 0.0
	return p


static func _reset(made: Array) -> void:
	var crowd: Crowd = made[0]
	crowd.burning.clear()
	crowd.fires.clear()
	if crowd.trail_fire != null:
		crowd.trail_fire.clear()
	RD._clear_all(made)


static func _consts(t) -> void:
	t.check(TrailFire.LIFE == 12.0 and TrailFire.FADE == 2.0 and TrailFire.RADIUS == 0.45 and TrailFire.KILL_AFTER == 1.2
		and TrailFire.COOL > 0.0 and TrailFire.COOL < GroundFire.COOL and TrailFire.HARM_TICK == GroundFire.HARM_TICK,
		"the spec's numbers: LIFE 12, FADE 2, RADIUS 0.45, KILL_AFTER 1.2, slower cooling than the town's fire")
	t.check(TrailFire.KIND == Burning.KIND and FireManager.FIRE_KINDS.has(TrailFire.KIND)
		and not Remains.BODY_KINDS.has(TrailFire.KIND), "it kills as the town's own fire kind: no body to raise")


## Nothing is made until a trail fire is laid (no number moves in a town that never lays one): the town's keeper is null,
## then made on the first ask, and the same one after.
static func _lazy(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	t.check(crowd.trail_fire == null, "a town that never lays trail fire has no keeper for it")
	var tf := crowd.trail_fires()
	t.check(tf != null and crowd.trail_fire == tf and crowd.trail_fires() == tf and tf.count() == 0,
		"made on the first ask, the same one after")


## A patch lives LIFE at full strength until its last FADE, fading to nothing, and is gone after.
static func _life(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	t.check(tf.lay(at) and tf.count() == 1, "laid: one patch")
	_advance(crowd, TrailFire.LIFE - TrailFire.FADE - 0.2)
	var full := is_equal_approx(tf.strength(0), 1.0)
	_advance(crowd, 1.0)
	var fading := tf.strength(0) > 0.3 and tf.strength(0) < 0.7
	_advance(crowd, 0.9)
	var alive_at := tf.count() == 1
	_advance(crowd, 0.3)
	t.check(full and fading and alive_at and tf.count() == 0,
		"full strength until its last 2 s, about half at LIFE - 1, alive at LIFE - 0.1, gone after LIFE")


## It frightens nobody (no danger on the town's ThreatManager, the one standing by it stays calm), calls no beater and is not
## the town's ground fire.
static func _no_fright(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var by := _put(made, 3, at + Vector2(0.7, 0.0))
	var near := _put(made, 4, at + Vector2(1.5, 0.0))
	var threats0 := crowd.threats.active_count()
	var tf := crowd.trail_fires()
	tf.lay(at)
	tf.lay(at + Vector2(0.6, 0.0))
	_advance(crowd, 3.0)
	var beaters := 0
	for q in crowd.citizens:
		if is_instance_valid(q) and q.mind == Person.Mind.ASSIST:
			beaters += 1
	t.check(crowd.threats.active_count() == threats0 and crowd.threats.nearby(at, 2.0).is_empty(),
		"no danger is registered for it (%d threats, were %d)" % [crowd.threats.active_count(), threats0])
	t.check(by.mind == Person.Mind.CALM and near.mind == Person.Mind.CALM and beaters == 0 and crowd.fires.patches.is_empty(),
		"nobody panics from it (minds %d, %d), nobody turns out to beat it (%d), it is not the town's ground fire"
		% [by.mind, near.mind, beaters])


## A quick crossing (at a run, PANIC_SPEED, straight over a patch's middle) hurts -- heat, a flash, soot -- but does not kill.
static func _crossing(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	tf.lay(at)
	var p := _put(made, 5, at + Vector2(-1.0, 0.0))
	var step := Person.PANIC_SPEED * DT
	var x := -1.0
	while x < 1.0:
		x += step
		p.ground_pos = at + Vector2(x, 0.0)
		crowd.advance(DT)
	var heat := tf.heat_of(p)
	t.check(p.is_alive() and heat > 0.3 and heat < TrailFire.KILL_AFTER and p.scorched_left > 0.0,
		"a quick crossing: alive, %.2f s of heat taken, scorched (soot %.1f)" % [heat, p.scorched_left])


## Standing on it KILL_AFTER in all kills him where he stands, as the fire kind: no raisable body.
static func _kills(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	tf.lay(at)
	var p := _put(made, 6, at + Vector2(0.1, 0.0))
	var soldier: Person = crowd.soldiers.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())[0]
	soldier.stop_fighting()
	soldier.ground_pos = at + Vector2(-0.1, 0.1)
	soldier.inside = false
	var got := []
	var grab := func(e: DummyEnemy, kind: StringName) -> void: got.append([e, kind])
	field.enemy_killed.connect(grab)
	_advance(crowd, TrailFire.KILL_AFTER - 0.2)
	var alive_at := p.is_alive() and soldier.is_alive()
	_advance(crowd, 0.35)
	field.enemy_killed.disconnect(grab)
	var kinds_ok := got.size() == 2
	for g in got:
		kinds_ok = kinds_ok and g[1] == TrailFire.KIND
	t.check(alive_at and not p.is_alive() and not soldier.is_alive() and kinds_ok,
		"citizen and soldier alike: alive at KILL_AFTER - 0.2, dead by KILL_AFTER + 0.15 as fire (%s)" % [got])
	t.check(crowd.remains.pick(at) == null, "a trail fire death leaves no raisable body")


## Heat leaves him slowly once he is off it (COOL a second), and a second crossing on top of the first kills.
static func _cools(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	tf.lay(at)
	var p := _put(made, 7, at)
	_advance(crowd, 0.7)
	p.ground_pos = at + Vector2(2.0, 0.0)
	crowd.advance(DT)
	var h0 := tf.heat_of(p)
	_advance(crowd, 2.0)
	var h1 := tf.heat_of(p)
	t.check(p.is_alive() and h0 > 0.6 and h1 < h0 and absf((h0 - h1) - TrailFire.COOL * 2.0) < 0.05,
		"off the fire his heat falls by COOL a second (%.2f -> %.2f over 2 s)" % [h0, h1])
	p.ground_pos = at
	_advance(crowd, 0.8)
	t.check(not p.is_alive(), "back on it: what he took before counts, and he dies short of KILL_AFTER this time")
	var q := _put(made, 8, at + Vector2(3.0, 0.0))
	tf._heat[q] = Vector2(0.2, -1.0)
	_advance(crowd, 0.2 / TrailFire.COOL + 0.3)
	t.check(not tf._heat.has(q), "cooled right down, he is forgotten")


## A patch right against a house for its whole life never sets it alight.
static func _no_building(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var house := RD._house(made[1], made[2])
	var tf := crowd.trail_fires()
	var g := Vector2(house.footprint.end.x + 0.15, house.center().y)
	tf.lay(g)
	_advance(crowd, TrailFire.LIFE + 0.5)
	t.check(not crowd.fires.is_burning(house) and crowd.fires.fires.is_empty(), "a patch 0.15 off a house never lights it")


## The one who laid it (the burning man) is spared his own trail; another on the same patch is not.
static func _spared(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	var man := _put(made, 9, at)
	var other := _put(made, 10, at + Vector2(0.1, 0.0))
	tf.lay(at, man.get_instance_id())
	_advance(crowd, TrailFire.KILL_AFTER + 0.5)
	t.check(man.is_alive() and tf.heat_of(man) == 0.0 and man.scorched_left == 0.0 and not other.is_alive(),
		"the one who laid it stands on it unharmed; the other dies")


## One inside a building is never touched, even standing on its point.
static func _inside(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	tf.lay(at)
	var p := _put(made, 11, at)
	p.inside = true
	_advance(crowd, TrailFire.KILL_AFTER + 0.5)
	t.check(p.is_alive() and tf.heat_of(p) == 0.0, "one inside is never touched")
	p.inside = false


## Never inside a building, never on water.
static func _bad_ground(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var tf := crowd.trail_fires()
	var house := RD._house(made[1], made[2])
	var river: Rect2 = City.current().rivers()[0]
	t.check(not tf.lay(house.center()) and not tf.lay(river.get_center()) and tf.count() == 0,
		"refused inside a building and on the water")


## 12 burning men's trails at TRAIL_MOST (168 patches) spread over the 220 town, people walking among them: the trail fire's
## step costs under 1 ms a frame on average over 200 frames, and its cell index is rebuilt only when a patch comes or goes,
## never every frame.
static func _perf(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var tf := crowd.trail_fires()
	var n := 0
	for i in 12:
		var g := grid.nearest_walkable(Vector2(-18.0 + float(i % 4) * 12.0, -14.0 + float(i / 4) * 12.0))
		for k in EmberFx.TRAIL_MOST:
			var s := grid.nearest_walkable(g + Vector2(EmberFx.TRAIL_STEP * float(k), 0.0).rotated(float(i)))
			if tf.lay(s):
				n += 1
	for i in 60:
		_put(made, 80 + i, grid.nearest_walkable(Vector2(-18.0 + float(i % 4) * 12.0, -14.0 + float(i / 4 % 3) * 12.0)
			+ Vector2(float(i % 5) * 0.8, 2.0)))
	var rebuilds0 := tf.rebuilds
	var spent := 0
	for f in 200:
		var t0 := Time.get_ticks_usec()
		tf.step(DT)  # (200 frames are 10 s, short of LIFE: none burns out, so this is the steady cost)
		spent += Time.get_ticks_usec() - t0
	var ms := float(spent) / 200.0 / 1000.0
	print("trail fire perf: %d patches, %d people, %.4f ms a step on average over 200 frames, %d rebuilds"
		% [tf.count(), crowd.citizens.size() + crowd.soldiers.size(), ms, tf.rebuilds - rebuilds0])
	t.check(n >= 150 and tf.count() == n, "(set-up) %d patches laid" % n)
	t.check(ms < 1.0, "%d trail patches: %.4f ms a step averaged over 200 frames (under 1 ms)" % [n, ms])
	t.check(tf.rebuilds - rebuilds0 <= 1, "no patch came or went: the cell index was rebuilt %d times" % (tf.rebuilds - rebuilds0))
	_reset(made)


## In the tree, the trail fire's layer draws its patches, and a burning man draws his flames.
static func _draws(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var world: Node2D = made[4]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	tf.lay(at)
	tf.lay(at + Vector2(0.6, 0.0))
	var man := _put(made, 12, at + Vector2(2.0, 0.0))
	crowd.burn(man, Burning.BURN_FOR, man.ground_pos)
	t.check(tf.layer != null and tf.layer.get_parent() == world, "(set-up) the layer sits in the town's world")
	world.position = Vector2(400.0, 300.0) - Iso.ground_to_screen(at)  # the patches on screen (the layer draws only those)
	t.root.add_child(world)
	var drawn0 := tf.layer.patches_drawn
	var flames0 := man.flame_draws
	for i in 4:
		crowd.advance(DT)
		man.frame(DT)
		man.statuses[Burning.STATUS] = float(man.statuses[Burning.STATUS]) - 0.1  # a new flame frame each step
		await t.process_frame
	t.root.remove_child(world)
	world.position = Vector2.ZERO
	t.check(tf.layer.patches_drawn - drawn0 >= 2, "the layer draws its patches (%d drawn)" % (tf.layer.patches_drawn - drawn0))
	t.check(man.flame_draws > flames0, "the burning man's flames are drawn (%d draws)" % (man.flame_draws - flames0))
	_reset(made)


## Its own clear(): every patch and every heat gone; a patch laid after burns again.
static func _cleared(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	tf.lay(at)
	var p := _put(made, 13, at)
	_advance(crowd, 0.5)
	tf.clear()
	_advance(crowd, 2.0)
	t.check(tf.count() == 0 and tf.heat_of(p) == 0.0 and p.is_alive(), "cleared: no patch, no heat, he lives")
	tf.lay(at)
	_advance(crowd, DT * 2.0)
	t.check(tf.count() == 1, "laid after a clear, it burns again")
