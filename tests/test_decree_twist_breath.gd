extends RefCounted
## breath level 5 twist (Death and Decree ability levels, Task 13): Nobody May Leave. With the air gone a NO LEAVING law of
## 2 s is laid on the same circle, so for 2 s nobody can run out; then it lifts. One in the middle has 1 s left and dies
## at 3.0; one 0.3 inside the edge is out before 3.0 and lives. The law is lifted at the cast's end, its early end and when
## it is freed, and never lifts another cast's (or another power's) NO LEAVING law.

const Kit := preload("res://tests/test_decree.gd")
const PATH := "res://src/fx/decree/breathing_is_prohibited.gd"
const DT := 0.1


static func _cast(ctx: FxContext, at: Vector2, level: int) -> BreathFx:
	return FxTimeline.cast(load(PATH), ctx, at, {"level": level})


## `seconds` of frames: the effects', then each walker's own.
static func _run(fxs: Array, walkers: Array, seconds: float) -> void:
	for i in int(roundf(seconds / DT)):
		for fx: FxTimeline in fxs:
			if is_instance_valid(fx):
				fx._process(DT)
		for p: Person in walkers:
			if p.is_alive():
				p.frame(DT)


## How many NO LEAVING laws the crowd holds now.
static func _stays(crowd: Crowd) -> int:
	var n := 0
	for z in crowd.laws:
		if z.holds(LawZone.NO_LEAVING):
			n += 1
	return n


static func _place(crowd: Crowd, grid: WalkGrid, at: Vector2, r: float) -> Array:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var mid: Person = crowd.citizens[0]
	var edge: Person = crowd.citizens[1]
	mid.ground_pos = at
	edge.ground_pos = at + Vector2(r - 0.3, 0.0)
	return [mid, edge]


static func run(t) -> void:
	_level4(t)
	_level5(t)
	_dies_early(t)
	_end_now(t)
	await _freed(t)
	_full_run(t)
	_overlap(t)


## A fresh town for a scenario (the people's earlier runs must not carry over): [made, crowd, ctx, at].
static func _world() -> Array:
	var made: Array = Kit._setup()
	var grid: WalkGrid = made[2]
	return [made, made[0], made[5], grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center()), grid]


static func _level4(t) -> void:
	var wd := _world()
	var made: Array = wd[0]
	var crowd: Crowd = wd[1]
	var ctx: FxContext = wd[2]
	var at: Vector2 = wd[3]
	var grid: WalkGrid = wd[4]

	# Level 4: no NO LEAVING law; the one at the edge runs out at once and lives, and nobody is held.
	var r4 := float(PowerBook.stat({"level": 4}, "breath", "RADIUS", BreathFx.RADIUS))
	var w4 := _place(crowd, grid, at, r4)
	var f4 := _cast(ctx, at, 4)
	_run([f4], w4, BreathFx.T_LAND + 0.1)
	t.check(f4.law != null and _stays(crowd) == 0 and not crowd.in_law(w4[1], LawZone.NO_LEAVING),
		"breath level 4: no NO LEAVING law is laid")
	_run([f4], w4, 2.5)
	t.check(w4[1].is_alive() and w4[1].ground_pos.distance_to(at) > r4 + 0.01, "breath level 4: one at the edge runs out and lives")
	f4.end_now()
	f4.free()


	Kit._done(made)


static func _level5(t) -> void:
	var wd := _world()
	var made: Array = wd[0]
	var crowd: Crowd = wd[1]
	var ctx: FxContext = wd[2]
	var at: Vector2 = wd[3]
	var grid: WalkGrid = wd[4]
	var r5 := float(PowerBook.stat({"level": 5}, "breath", "RADIUS", BreathFx.RADIUS))

	# Level 5: held for 2 s, then free; the centre one dies at 3.0, the edge one lives.
	var w5 := _place(crowd, grid, at, r5)
	var mid: Person = w5[0]
	var edge: Person = w5[1]
	var f5 := _cast(ctx, at, 5)
	_run([f5], w5, BreathFx.T_LAND + 0.1)
	t.check(f5.lv_radius == r5 and _stays(crowd) == 1 and crowd.in_law(edge, LawZone.NO_LEAVING) and crowd.in_law(mid, LawZone.NO_LEAVING)
		and f5.choking.has(mid) and f5.choking.has(edge),
		"breath level 5: a NO LEAVING law lands with the air, both inside are held and choking (%d)" % _stays(crowd))
	_run([f5], w5, 1.7)
	t.check(_stays(crowd) == 1 and crowd.in_law(edge, LawZone.NO_LEAVING) and edge.ground_pos.distance_to(at) <= r5 + 0.01,
		"breath level 5: held still at 1.8 s, the edge one has not left")
	_run([f5], w5, 0.4)
	t.check(_stays(crowd) == 0 and crowd.laws.has(f5.law) and crowd.laws.size() == 1 and not crowd.in_law(edge, LawZone.NO_LEAVING),
		"breath level 5: the NO LEAVING law is lifted at 2.0, only the NO BREATH law is left")
	_run([f5], w5, 0.7)
	t.check(edge.is_alive() and edge.ground_pos.distance_to(at) > r5 and not f5.choking.has(edge) and mid.is_alive() and f5.choking.has(mid),
		"breath level 5: before 3.0 the edge one is out and lives; the middle one still chokes")
	_run([f5], w5, 0.2)
	t.check(not mid.is_alive() and edge.is_alive(), "breath level 5: the middle one dies at 3.0, the edge one lives")
	f5.end_now()
	f5.free()


	Kit._done(made)


static func _dies_early(t) -> void:
	var wd := _world()
	var made: Array = wd[0]
	var crowd: Crowd = wd[1]
	var ctx: FxContext = wd[2]
	var at: Vector2 = wd[3]
	var grid: WalkGrid = wd[4]
	var r5 := float(PowerBook.stat({"level": 5}, "breath", "RADIUS", BreathFx.RADIUS))

	# One who dies at 1.0 frees nothing: the law still holds the other, and he leaves no hold behind.
	var w6 := _place(crowd, grid, at, r5)
	var f6 := _cast(ctx, at, 5)
	_run([f6], w6, BreathFx.T_LAND + 0.1)
	var held_before: bool = crowd.in_law(w6[1], LawZone.NO_LEAVING) and f6._stay.members.has(w6[0])
	_run([f6], w6, 0.9)
	ctx.field.kill(w6[0], &"choke", w6[0].ground_pos)
	_run([f6], w6, 0.5)
	t.check(held_before and not w6[0].is_alive() and _stays(crowd) == 1 and crowd.in_law(w6[1], LawZone.NO_LEAVING)
		and not f6._stay.members.has(w6[0]) and not f6.choking.has(w6[0]),
		"breath level 5: one dead at 1.0 frees nobody and the law holds on")
	f6.end_now()
	f6.free()


	Kit._done(made)


static func _end_now(t) -> void:
	var wd := _world()
	var made: Array = wd[0]
	var crowd: Crowd = wd[1]
	var ctx: FxContext = wd[2]
	var at: Vector2 = wd[3]
	var grid: WalkGrid = wd[4]
	var r5 := float(PowerBook.stat({"level": 5}, "breath", "RADIUS", BreathFx.RADIUS))

	# Teardown by end_now: held before the early end, no NO LEAVING law and no hold after.
	var w7 := _place(crowd, grid, at, r5)
	var f7 := _cast(ctx, at, 5)
	_run([f7], w7, BreathFx.T_LAND + 1.0)
	var held7: bool = crowd.in_law(w7[1], LawZone.NO_LEAVING) and _stays(crowd) == 1
	f7.end_now()
	t.check(held7 and _stays(crowd) == 0 and crowd.laws.is_empty() and not crowd.in_law(w7[1], LawZone.NO_LEAVING),
		"breath level 5: end_now at 1 s lifts both laws (held before it)")
	f7.free()


	Kit._done(made)


static func _freed(t) -> void:
	var wd := _world()
	var made: Array = wd[0]
	var crowd: Crowd = wd[1]
	var ctx: FxContext = wd[2]
	var at: Vector2 = wd[3]
	var grid: WalkGrid = wd[4]
	var r5 := float(PowerBook.stat({"level": 5}, "breath", "RADIUS", BreathFx.RADIUS))

	# Teardown by a free (in the tree, so its exit fires).
	(t.root as Node).add_child(ctx.overhead)
	await t.process_frame
	var w8 := _place(crowd, grid, at, r5)
	var f8 := _cast(ctx, at, 5)
	_run([f8], w8, BreathFx.T_LAND + 1.0)
	var held8: bool = crowd.in_law(w8[1], LawZone.NO_LEAVING) and _stays(crowd) == 1
	f8.free()
	t.check(held8 and _stays(crowd) == 0 and crowd.laws.is_empty() and not crowd.in_law(w8[1], LawZone.NO_LEAVING),
		"breath level 5: freed at 1 s lifts both laws (held before it)")
	(t.root as Node).remove_child(ctx.overhead)


	Kit._done(made)


static func _full_run(t) -> void:
	var wd := _world()
	var made: Array = wd[0]
	var crowd: Crowd = wd[1]
	var ctx: FxContext = wd[2]
	var at: Vector2 = wd[3]
	var grid: WalkGrid = wd[4]
	var r5 := float(PowerBook.stat({"level": 5}, "breath", "RADIUS", BreathFx.RADIUS))

	# Teardown by the cast's own end: a full run leaves no law behind, the edge one was held first.
	var w9 := _place(crowd, grid, at, r5)
	var f9 := _cast(ctx, at, 5)
	_run([f9], w9, BreathFx.T_LAND + 0.5)
	var held9: bool = crowd.in_law(w9[1], LawZone.NO_LEAVING)
	_run([f9], w9, f9.lv_hold_time + 1.0)
	t.check(held9 and f9.finished and _stays(crowd) == 0 and crowd.laws.is_empty(), "breath level 5: run to its end leaves no law (held before)")
	f9.free()


	Kit._done(made)


static func _overlap(t) -> void:
	var wd := _world()
	var made: Array = wd[0]
	var crowd: Crowd = wd[1]
	var ctx: FxContext = wd[2]
	var at: Vector2 = wd[3]
	var grid: WalkGrid = wd[4]
	var r5 := float(PowerBook.stat({"level": 5}, "breath", "RADIUS", BreathFx.RADIUS))

	# Two overlapping casts never lift each other's laws; nor another power's NO LEAVING.
	var w10 := _place(crowd, grid, at, r5)
	var other := LawZone.circle(at, 9.0, [LawZone.NO_LEAVING], 30.0)
	crowd.add_law(other)
	var fa := _cast(ctx, at, 5)
	var fb := _cast(ctx, at, 5)
	_run([fa, fb], w10, BreathFx.T_LAND + 0.5)
	var three: bool = _stays(crowd) == 3
	fa.end_now()
	var after_a: bool = _stays(crowd) == 2 and crowd.laws.has(fb._stay) and crowd.laws.has(other) and fb._stay.alive() and crowd.in_law(w10[1], LawZone.NO_LEAVING)
	fa.free()
	_run([fb], w10, 0.1)
	fb.end_now()
	t.check(three and after_a and _stays(crowd) == 1 and crowd.laws.has(other) and other.alive(),
		"breath level 5: two overlapping casts and another power's law do not lift each other")
	fb.free()
	crowd.remove_law(other)

	Kit._done(made)
