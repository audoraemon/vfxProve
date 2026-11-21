extends RefCounted
## Trail fire (TrailFire, 2026-11-20: Ember's level 5 Fire Trail, the user's playtest): a reusable ground hazard on the town,
## apart from the town's GroundFire. A patch lives LIFE, fading over its last FADE, and burns out by itself. It frightens
## nobody, calls no beater and never catches a building. Whoever stands on it builds heat: a crossing (at a walk or a run)
## hurts and scorches but adds at most CROSS_MAX; lingering past LINGER or crossing again soon after takes him to KILL_AFTER,
## which kills as the fire kind (no raisable body); heat leaves him slowly off it. The one who laid it
## (the burning man) is spared; people inside are never touched. Cleared with the town. Drawn by its own layer.

const RD := preload("res://tests/test_raise_dead.gd")
const BP := preload("res://src/core/bench_prof.gd")
const DT := 0.05


static func run(t) -> void:
	_consts(t)
	var made := RD._setup()
	_lazy(t, made)
	_life(t, made)
	_no_fright(t, made)
	_crossing(t, made)
	_walking(t, made)
	_overlap(t, made)
	_kills(t, made)
	_cools(t, made)
	_no_building(t, made)
	_spared(t, made)
	_inside(t, made)
	_bad_ground(t, made)
	_perf(t, made)
	await _draw_cost(t, made)
	await _draws(t, made)
	_night_flames(t, made)
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
	t.check(TrailFire.CROSS_MAX < TrailFire.KILL_AFTER and 2.0 * TrailFire.CROSS_MAX > TrailFire.KILL_AFTER
		and TrailFire.LINGER > 2.0 * TrailFire.RADIUS / (Person.WALK_SPEED * Person.PACE_RANGE.x),
		"a crossing adds less than a kill, two do kill, and the slowest walker's crossing is shorter than LINGER")
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


## Walks `p` straight along x across the patch at `at`, from `from` to `to` (offsets), at `speed`, stepping the town. Returns
## [the most heat he held, the seconds he was on the patch].
static func _cross(crowd: Crowd, p: Person, at: Vector2, from: float, to: float, speed: float) -> Array:
	var tf := crowd.trail_fire
	var most := 0.0
	var on := 0.0
	var x := from
	var dir := signf(to - from)
	while (to - x) * dir > 0.0 and p.is_alive():
		x += dir * speed * DT
		p.ground_pos = at + Vector2(x, 0.0)
		crowd.advance(DT)
		most = maxf(most, tf.heat_of(p))
		if absf(x) <= TrailFire.RADIUS:
			on += DT
	return [most, on]


## The user's rule (2026-11-21): a calm walker at the crowd's walking pace (WALK_SPEED times the slowest and the fastest
## pace) crossing a patch's middle is on it longer than KILL_AFTER, yet takes at most CROSS_MAX and lives, scorched; a
## second crossing straight after (he turns back half a second past it: about 2.2-2.7 s off the fire) kills him, as the
## fire kind.
static func _walking(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	tf.lay(at)
	var got := []
	var grab := func(e: DummyEnemy, kind: StringName) -> void: got.append([e, kind])
	field.enemy_killed.connect(grab)
	for n in 2:
		var pace: float = Person.PACE_RANGE.x if n == 0 else Person.PACE_RANGE.y
		var speed := Person.WALK_SPEED * pace
		var p := _put(made, 14 + n, at + Vector2(-1.0, 0.0))
		var r := _cross(crowd, p, at, -1.0, 1.0, speed)
		t.check(p.is_alive() and float(r[1]) > TrailFire.KILL_AFTER and float(r[0]) <= TrailFire.CROSS_MAX + 0.001
			and float(r[0]) > TrailFire.CROSS_MAX - 0.06 and p.scorched_left > 0.0,
			"a walker at pace %.2f (%.2f u/s): %.2f s on the patch, %.2f s of heat at most, alive and scorched"
			% [pace, speed, r[1], r[0]])
		_advance(crowd, 0.5)
		var before := tf.heat_of(p)
		_cross(crowd, p, at, 1.0, -1.0, speed)
		t.check(not p.is_alive() and got.size() == 1 and got[0][0] == p and got[0][1] == TrailFire.KIND,
			"turning back after 0.5 s (%.2f s of heat left), his second crossing kills him as fire (%s)" % [before, got])
		got.clear()
	field.enemy_killed.disconnect(grab)


## Standing across two overlapping patches heats him at one patch's rate, not two: the heat is for being on trail fire.
static func _overlap(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var tf := crowd.trail_fires()
	var set_up := tf.lay(at) and tf.lay(at + Vector2(0.1, 0.0)) and tf.lay(at + Vector2(3.0, 0.0))
	var two := _put(made, 16, at + Vector2(0.05, 0.0))
	var one := _put(made, 17, at + Vector2(3.0, 0.0))
	_advance(crowd, 0.5)
	var h2 := tf.heat_of(two)
	var h1 := tf.heat_of(one)
	t.check(set_up and h1 > 0.4 and h1 < 0.6 and absf(h2 - h1) < 0.001,
		"on two overlapping patches %.2f s of heat in 0.5 s, on one %.2f: the single rate" % [h2, h1])


## Standing on it: the crossing's cap holds him at CROSS_MAX until LINGER, then he burns on and dies about
## KILL_AFTER - CROSS_MAX later, where he stands, as the fire kind: no raisable body.
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
	_advance(crowd, TrailFire.LINGER - 0.1)
	var held := tf.heat_of(p)
	var alive_at := p.is_alive() and soldier.is_alive() and absf(held - TrailFire.CROSS_MAX) < 0.001
	_advance(crowd, TrailFire.KILL_AFTER - TrailFire.CROSS_MAX + 0.35)
	field.enemy_killed.disconnect(grab)
	var kinds_ok := got.size() == 2
	for g in got:
		kinds_ok = kinds_ok and g[1] == TrailFire.KIND
	t.check(alive_at and not p.is_alive() and not soldier.is_alive() and kinds_ok,
		("citizen and soldier alike: alive at LINGER - 0.1, held at CROSS_MAX (%.2f); dead by LINGER + KILL_AFTER"
		+ " - CROSS_MAX + 0.25, as fire (%s)") % [held, got])
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
	_advance(crowd, 1.0)
	t.check(not p.is_alive(), "back on it: what he took before counts, and he dies short of KILL_AFTER this time")
	var q := _put(made, 8, at + Vector2(3.0, 0.0))
	tf._heat[q] = Vector4(0.2, -1.0, 0.2, 0.2)
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
	_advance(crowd, TrailFire.LINGER + TrailFire.KILL_AFTER)
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
	_advance(crowd, TrailFire.LINGER + TrailFire.KILL_AFTER)
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


## 12 burning men's trails at TRAIL_MOST (168 patches), all on screen (the view zoomed out over them), in the tree for 2 s at
## 60 fps: the layer redraws at most REDRAW_HZ a second (not every frame), and what its _draw costs (BenchProf's
## trail_draw, as --bench --bench-prof times it) is printed, a draw and a frame, and stays under 1 ms a frame.
static func _draw_cost(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var world: Node2D = made[4]
	var tf := crowd.trail_fires()
	for i in 12:
		var g := grid.nearest_walkable(Vector2(-18.0 + float(i % 4) * 12.0, -14.0 + float(i / 4) * 12.0))
		for k in EmberFx.TRAIL_MOST:
			tf.lay(grid.nearest_walkable(g + Vector2(EmberFx.TRAIL_STEP * float(k), 0.0).rotated(float(i))))
	var lo := Vector2(INF, INF)
	var hi := -lo
	for i in tf.count():
		var c := Iso.ground_to_screen(tf.spot(i))
		lo = Vector2(minf(lo.x, c.x), minf(lo.y, c.y))
		hi = Vector2(maxf(hi.x, c.x), maxf(hi.y, c.y))
	var vp: Vector2 = t.root.get_visible_rect().size
	var zoom := minf((vp.x - 120.0) / maxf(hi.x - lo.x, 1.0), (vp.y - 120.0) / maxf(hi.y - lo.y, 1.0))
	world.scale = Vector2(zoom, zoom)
	world.position = vp * 0.5 - (lo + hi) * 0.5 * zoom
	TrailFire.TrailLayer.atlas()  # (baked once, before the timing)
	TrailFire.TrailLayer.disc()
	t.root.add_child(world)
	await t.process_frame
	await t.process_frame
	var draws0: int = tf.layer.draws
	var drawn0: int = tf.layer.patches_drawn
	BP.reset()
	BP.on = true
	var frames := 120
	for f in frames:
		crowd.advance(1.0 / 60.0)
		await t.process_frame
	BP.on = false
	t.root.remove_child(world)
	world.position = Vector2.ZERO
	world.scale = Vector2.ONE
	var draws: int = tf.layer.draws - draws0
	var per_draw := float(tf.layer.patches_drawn - drawn0) / maxf(draws, 1)
	var usec := float(BP._usec.get(&"trail_draw", 0))
	BP.reset()
	var ms_frame := usec / 1000.0 / float(frames)
	var ms_draw := usec / 1000.0 / maxf(draws, 1)
	print("trail fire draw: %d patches, %.0f drawn a draw, %d draws in %d frames (2 s), %.3f ms a draw, %.3f ms a frame"
		% [tf.count(), per_draw, draws, frames, ms_draw, ms_frame])
	t.check(per_draw >= 150.0, "(set-up) all %d patches on screen (%.0f drawn a draw)" % [tf.count(), per_draw])
	var img := TrailFire.TrailLayer.atlas().get_image()
	var lit := 0
	for v in TrailFire.TrailLayer.VARIANTS:
		for f in TrailFire.TrailLayer.FRAMES:
			var cell := 0
			for x in TrailFire.TrailLayer.CELL_W:
				for y in TrailFire.TrailLayer.CELL_H:
					if img.get_pixel(f * TrailFire.TrailLayer.CELL_W + x, v * TrailFire.TrailLayer.CELL_H + y).a > 0.5:
						cell += 1
			if cell >= 20:
				lit += 1
	t.check(img.get_width() == TrailFire.TrailLayer.CELL_W * TrailFire.TrailLayer.FRAMES
		and lit == TrailFire.TrailLayer.VARIANTS * TrailFire.TrailLayer.FRAMES,
		"the flames' atlas: every one of its %d frames has flames in it" % lit)
	t.check(draws >= 20 and draws <= int(TrailFire.REDRAW_HZ * 2.0) + 2,
		"the layer redraws at REDRAW_HZ, not every frame: %d draws in %d frames" % [draws, frames])
	t.check(ms_frame < 1.0, "its draw: %.3f ms a draw, %.3f ms a frame (under 1 ms)" % [ms_draw, ms_frame])
	_reset(made)


## At night the burning man's fire is not dimmed or cooled by the light on him (his modulate): drawn in fire_colour(), it
## shows as its own colour under the night's modulate; by day (white) it is unchanged; a very dark spot cannot blow it up.
static func _night_flames(t, made: Array) -> void:
	var night := Color(0.69, 0.76, 0.86)  # 0.86 ambient x the night's tint (0.80, 0.88, 1.0)
	var ok := true
	for c: Color in [Person.COL_FLAME_EDGE, Person.COL_FLAME_MID, Person.COL_FLAME_CORE, Person.COL_FIRE_GLOW, Person.COL_HOT]:
		var shown := Person.unlit(c, night) * night
		ok = ok and absf(shown.r - c.r) < 0.001 and absf(shown.g - c.g) < 0.001 and absf(shown.b - c.b) < 0.001
		ok = ok and Person.unlit(c, Color.WHITE).is_equal_approx(c) and Person.unlit(c, night).a == c.a
		var dark := Person.unlit(c, Color(0.01, 0.01, 0.01))
		ok = ok and dark.r <= c.r / Person.UNLIT_FLOOR + 0.001 and dark.b <= c.b / Person.UNLIT_FLOOR + 0.001
	var p := _put(made, 18, RD._empty(made))
	var was := p.modulate
	p.modulate = night
	ok = ok and p.fire_colour(Person.COL_FLAME_MID) == Person.unlit(Person.COL_FLAME_MID, night)
	p.modulate = was
	t.check(ok, "at night his flames show their own colour (fire colour x the night's light = the flame), by day unchanged")


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
