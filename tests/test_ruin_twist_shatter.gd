extends RefCounted
## Earthshatter level 5 twist, Fault Lines (Ruin ability levels): the crack forks at a third and two thirds of its run, first to the left, then
## to the right; each branch is a Fissure of its own, crawls at the crack's speed, takes what is in its way and stays open. Level 4 forks nothing.


## A headless context as test_shatter's: no stage, a field and an environment.
static func _ctx() -> FxContext:
	var ctx := FxContext.new()
	ctx.env = EnvironmentField.new()
	ctx.field = EnemyField.new()
	ctx.field.env = ctx.env
	ctx.field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 7
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return ctx


static func _free(ctx: FxContext) -> void:
	ctx.field.clear()
	ctx.overhead.free()
	ctx.ground.free()


static func _dummy(ctx: FxContext, at: Vector2) -> DummyEnemy:
	var d := DummyEnemy.new()
	d.ground_pos = at
	ctx.field.add(d)
	return d


## How many Fissures lie in the ground layer.
static func _fissures(ctx: FxContext) -> int:
	var n := 0
	for c in ctx.ground.get_children():
		if c is EarthshatterFx.Fissure:
			n += 1
	return n


static func _step(fx: EarthshatterFx, seconds: float) -> void:
	var left := seconds
	while left > 0.0001:
		var dt := minf(0.1, left)
		fx._process(dt)
		left -= dt


static func run(t) -> void:
	_level_five(t)
	_level_four(t)
	_busy(t)


## A 12-unit run along +x: the forks are at 4 and 8. The first branch leaves 0.6 rad to the left (y falls), the second to the right. A dummy 4.0
## along each branch stands 2.26 off the main line: beyond the crack's own fall width at every level (HALF 1.1-1.4), so only a branch can take it.
## (The brief put them 2.0 along; at level 5's HALF 1.4 that is 1.13 off the line, inside the main crack, which would prove nothing.)
static func _spots() -> Array[Vector2]:
	var d := Vector2.RIGHT
	return [Vector2(4.0, 0.0) + d.rotated(-EarthshatterFx.FORK_ANGLE) * 4.0, Vector2(8.0, 0.0) + d.rotated(EarthshatterFx.FORK_ANGLE) * 4.0]


static func _level_five(t) -> void:
	var ctx := _ctx()
	var spots := _spots()
	var first := _dummy(ctx, spots[0])
	var second := _dummy(ctx, spots[1])
	var apart := _dummy(ctx, Vector2(8.0, -7.0))
	var kinds := {}
	ctx.field.enemy_killed.connect(func(e, kind): kinds[e] = kind)
	var fx: EarthshatterFx = FxTimeline.cast(load("res://src/fx/ruin/earthshatter.gd"), ctx, Vector2.ZERO, {"to": Vector2(12.0, 0.0), "level": 5})
	t.check(is_equal_approx(fx.length, 12.0) and fx.branches.is_empty(), "level 5: a 12-unit run, no branch before the crack opens")
	_step(fx, EarthshatterFx.T_CRACK + 1.0)
	t.check(fx.branches.is_empty() and _fissures(ctx) == 1, "the crack has not reached the first fork (4.0) a second after opening")
	_step(fx, 1.0)
	t.check(fx.branches.size() == 1 and _fissures(ctx) == 2, "the first fork is passed: a branch starts")
	_step(fx, 5.0)
	t.check(fx.branches.size() == 2 and _fissures(ctx) == 3, "after the crawl there are two branch fissures beside the main one")
	var armed := true
	var lasting := true
	var long := true
	for run in fx.branches:
		var b: EarthshatterFx.Fissure = run.fissure
		armed = armed and b.armed and is_equal_approx(b.reach, EarthshatterFx.FORK_LEN)
		lasting = lasting and b.is_in_group(&"fx_lasting")
		long = long and is_equal_approx(b.a.distance_to(b.b), EarthshatterFx.FORK_LEN) and is_equal_approx(b.half, fx.lv_half)
	t.check(armed and lasting and long, "both branches are armed, in group fx_lasting, 5.0 long and as wide as the crack")
	var f0: EarthshatterFx.Fissure = fx.branches[0].fissure
	var f1: EarthshatterFx.Fissure = fx.branches[1].fissure
	t.check(f0.a.is_equal_approx(Vector2(4.0, 0.0)) and f1.a.is_equal_approx(Vector2(8.0, 0.0)), "they leave the line at a third and two thirds of the run")
	t.check(f0.b.y < 0.0 and f1.b.y > 0.0, "on opposite sides of the line, the first to the left (y %.2f), the second to the right (y %.2f)" % [f0.b.y, f1.b.y])
	t.check(not first.is_alive() and kinds.get(first, &"") == &"pit", "a dummy 4.0 along the first branch fell in (pit)")
	t.check(not second.is_alive() and kinds.get(second, &"") == &"pit", "and one mirrored on the other side, along the second branch")
	t.check(apart.is_alive(), "one clear of every crack still stands")
	_step(fx, EarthshatterFx.T_SETTLE + 1.0)
	t.check(fx.finished and is_instance_valid(f0) and f0.get_parent() == ctx.ground, "the cast ends, the branches stay in the ground layer")
	_free(ctx)


static func _level_four(t) -> void:
	var ctx := _ctx()
	var spots := _spots()
	var first := _dummy(ctx, spots[0])
	var second := _dummy(ctx, spots[1])
	var fx: EarthshatterFx = FxTimeline.cast(load("res://src/fx/ruin/earthshatter.gd"), ctx, Vector2.ZERO, {"to": Vector2(12.0, 0.0), "level": 4})
	_step(fx, fx.duration + 0.2)
	t.check(fx.branches.is_empty() and _fissures(ctx) == 1, "level 4: one fissure only")
	t.check(first.is_alive() and second.is_alive(), "and the dummies where the branches would run live")
	t.check(is_equal_approx(fx.duration, EarthshatterFx.T_CRACK + 12.0 / fx.lv_speed + EarthshatterFx.T_SETTLE), "level 4 lasts as before the twist")
	_free(ctx)


## busy and duration cover the last branch: on a short run it ends well after the main crack.
static func _busy(t) -> void:
	var ctx := _ctx()
	var fx: EarthshatterFx = FxTimeline.cast(load("res://src/fx/ruin/earthshatter.gd"), ctx, Vector2.ZERO, {"to": Vector2(4.0, 0.0), "level": 5})
	var second_fork := 2.0 * fx.length / 3.0
	var want := EarthshatterFx.T_CRACK + (second_fork + EarthshatterFx.FORK_LEN) / fx.lv_speed
	t.check(is_equal_approx(fx.length, 4.0) and is_equal_approx(fx.busy, want) and fx.busy > EarthshatterFx.T_CRACK + 4.0 / fx.lv_speed + 0.5
		and is_equal_approx(fx.duration, want + EarthshatterFx.T_SETTLE),
		"a 4-unit run's busy (%.2f) covers its second branch's end and the cast lasts T_SETTLE longer" % fx.busy)
	# The main crack is done long before; the branches go on crawling to the end all the same.
	_step(fx, fx.busy - 0.3)
	t.check(fx.reach >= fx.length and fx.branches.size() == 2 and float(fx.branches[1].reach) < EarthshatterFx.FORK_LEN - 0.0001,
		"the main crack has ended and the second branch is still crawling a moment before busy")
	_step(fx, 0.5)
	t.check(is_equal_approx(float(fx.branches[1].reach), EarthshatterFx.FORK_LEN) and fx.branches[1].fissure.armed, "and has reached its end by it, armed")
	_free(ctx)
