extends RefCounted
## Earthshatter: the ground torn open from one click to another, crawling, taking whoever stands in its way and what
## is built there, and left open for good.


static func run(t) -> void:
	var b := PowerBook.get_power("shatter")
	t.check(int(b.dp) == 5 and PowerBook.authority_of("shatter") == "ruin" and not PowerBook.is_quiet("shatter") and String(b.aim) == "two clicks"
		and is_equal_approx(PowerBook.impact("shatter"), EarthshatterFx.T_CRACK) and PowerBook.family("shatter") == "strike"
		and PowerBook.icon("shatter") != null and PowerBook.hud_icon("shatter") != null and PowerBook.clip("shatter") != null
		and String(Targeting.AREAS["shatter"].shape) == "path" and Rules.POWER_KINDS["shatter"].has(&"pit") and Rules.POWER_KINDS["shatter"].has(&"shatter"),
		"Earthshatter is Ruin's 5 DP, loud, two clicks, its impact the crack, with icons, clip, a path area and kinds")

	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = Rect2(-30, -30, 60, 60)
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 7
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var from := Vector2(0.0, 0.0)
	var to := Vector2(10.0, 0.0)
	var near := DummyEnemy.new()
	near.ground_pos = Vector2(2.0, 0.3)
	field.add(near)
	var far := DummyEnemy.new()
	far.ground_pos = Vector2(8.0, -0.2)
	field.add(far)
	var beside := DummyEnemy.new()
	beside.ground_pos = Vector2(5.0, EarthshatterFx.HALF + 0.4)
	field.add(beside)
	var stood := beside.ground_pos
	var clear := DummyEnemy.new()
	clear.ground_pos = Vector2(5.0, EarthshatterFx.HALF + EarthshatterFx.SHOVE + 2.0)
	field.add(clear)
	var house := env.add_structure(Rect2(Vector2(4.0, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var spared := env.add_structure(Rect2(Vector2(4.0, 4.0), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var fx: EarthshatterFx = FxTimeline.cast(load("res://src/fx/ruin/earthshatter.gd"), ctx, from, {"to": to})
	t.check(is_equal_approx(fx.length, 10.0) and fx.to.is_equal_approx(to) and is_equal_approx(fx.busy, EarthshatterFx.T_CRACK + 10.0 / EarthshatterFx.SPEED),
		"Earthshatter: runs from the first click to the second, and locks the slots until it is there")
	fx._process(EarthshatterFx.T_CRACK - 0.05)
	t.check(fx.fissure == null and near.is_alive() and fx.reach == 0.0, "the ground only groans before the crack")
	fx._process(0.1)
	t.check(fx.fissure != null and fx.fissure.is_in_group(&"fx_lasting") and fx.reach > 0.0, "then it opens at the start and begins to crawl")
	# 1.5 s of crawl: 3 units, past the first one and the house at 4? Not yet the house.
	for k in 15:
		fx._process(0.1)
	t.check(not near.is_alive() and near._kind == &"pit" and far.is_alive() and fx.fell == 1,
		"whoever stands in its way falls in as the front reaches them; one farther on still stands (reach %.1f)" % fx.reach)
	for k in 15:
		fx._process(0.1)
	t.check(house.destroyed and is_equal_approx(spared.hp, spared.max_hp) and fx.broke == 1, "what is built on the line is broken; what stands aside is not")
	beside.tick(0.5)
	t.check(beside.is_alive() and beside.ground_pos.distance_to(stood) > 0.1 and clear.ground_pos == Vector2(5.0, EarthshatterFx.HALF + EarthshatterFx.SHOVE + 2.0),
		"one beside the crack is thrown off their feet, alive; one well clear is untouched (%.2f)" % beside.ground_pos.distance_to(stood))
	for k in 30:
		fx._process(0.1)
	t.check(not far.is_alive() and is_equal_approx(fx.reach, fx.length) and fx.fissure.armed, "the crawl reaches the end: the last in its way is gone and the crack lies open")
	# It stays: someone wandering onto it later is gone too.
	var later := DummyEnemy.new()
	later.ground_pos = Vector2(6.0, 0.1)
	field.add(later)
	fx.fissure.advance(EarthshatterFx.Fissure.CHECK_EVERY + 0.01)
	t.check(not later.is_alive() and fx.fissure.fallen == 1, "and whoever steps onto it later falls (%d)" % fx.fissure.fallen)
	fx._process(EarthshatterFx.T_SETTLE + 0.5)
	var fissure := fx.fissure
	fx.free()
	t.check(is_instance_valid(fissure) and fissure.get_parent() == ctx.ground, "the crack outlives the cast, in the ground layer")
	var length := EarthshatterFx.new()
	length.ctx = ctx
	length.origin = Vector2.ZERO
	length.extra = {"to": Vector2(40.0, 0.0)}
	ctx.overhead.add_child(length)
	length._build()
	t.check(is_equal_approx(length.length, EarthshatterFx.MAX_LENGTH), "a run is clamped to MAX_LENGTH (%.1f)" % length.length)
	length.free()
	field.clear()
	ctx.overhead.free()
	ctx.ground.free()
