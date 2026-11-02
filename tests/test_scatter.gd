extends RefCounted
## Scatter Strike: ten small strikes thrown at random into a wide circle, every fifth of a second after the first,
## each killing within its own reach, knocking those a little farther, and breaking what it lands on.


static func run(t) -> void:
	var b := PowerBook.get_power("scatter")
	t.check(int(b.dp) == 2 and PowerBook.authority_of("scatter") == "ruin" and not PowerBook.is_quiet("scatter")
		and is_equal_approx(PowerBook.impact("scatter"), ScatterStrikeFx.T_FIRST) and PowerBook.family("scatter") == "strike"
		and PowerBook.icon("scatter") != null and PowerBook.hud_icon("scatter") != null and PowerBook.clip("scatter") != null
		and Targeting.AREAS.has("scatter") and Rules.POWER_KINDS["scatter"].has(&"orbital") and Rules.POWER_KINDS["scatter"].has(&"scatter"),
		"Scatter Strike is Ruin's 2 DP, loud, its impact the first strike, with icons, clip, area and kinds")

	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = Rect2(-30, -30, 60, 60)
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 5
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var at := Vector2(2.0, 3.0)
	var fx: ScatterStrikeFx = FxTimeline.cast(load("res://src/fx/ruin/scatter_strike.gd"), ctx, at)
	t.check(fx.points.size() == ScatterStrikeFx.BLASTS and fx.blasts == 0, "Scatter Strike: ten points are drawn at the cast, nothing has fallen")
	var inside := true
	var spread := 0.0
	var pairs := 0
	for i in fx.points.size():
		inside = inside and fx.points[i].distance_to(at) <= ScatterStrikeFx.RADIUS + 0.001
		for j in range(i + 1, fx.points.size()):
			spread += fx.points[i].distance_to(fx.points[j])
			pairs += 1
	spread /= float(pairs)
	t.check(inside and spread > ScatterStrikeFx.RADIUS * 0.6, "every point lies within the circle, and they are scattered over it (mean pair distance %.1f)" % spread)
	var far := env.add_structure(Rect2(at + Vector2(ScatterStrikeFx.RADIUS + 3.0, 0.0), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var under := env.add_structure(Rect2(fx.points[0] - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var hp := under.hp
	var e := DummyEnemy.new()
	e.ground_pos = fx.points[0] + Vector2(0.2, 0.0)
	field.add(e)
	var pushed := DummyEnemy.new()
	pushed.ground_pos = fx.points[0] + Vector2(ScatterStrikeFx.KILL_R + 0.3, 0.0)
	field.add(pushed)
	var where := pushed.ground_pos
	fx._process(ScatterStrikeFx.T_FIRST - 0.05)
	t.check(fx.blasts == 0 and e.is_alive() and is_equal_approx(fx.busy, ScatterStrikeFx.T_FIRST + ScatterStrikeFx.BLAST_GAP * ScatterStrikeFx.BLASTS),
		"nothing falls before the first strike; the slots are locked until the last")
	fx._process(0.1)
	t.check(fx.blasts == 1 and not e.is_alive() and fx.struck == 1, "the first strike falls and takes who stood under it")
	pushed.tick(0.5)
	t.check(pushed.is_alive() and pushed.ground_pos.distance_to(where) > 0.1, "one a little farther is thrown, alive (%.2f)" % pushed.ground_pos.distance_to(where))
	t.check(under.hp < hp and is_equal_approx(far.hp, far.max_hp), "what it lands on is hit; what stands outside the circle is not (%.0f of %.0f)" % [under.hp, hp])
	fx._process(ScatterStrikeFx.BLAST_GAP * float(ScatterStrikeFx.BLASTS) + 0.1)
	t.check(fx.blasts == ScatterStrikeFx.BLASTS, "all ten fall, a fifth of a second apart (%d)" % fx.blasts)
	fx._process(3.0)
	fx.free()
	field.clear()
	ctx.overhead.free()
	ctx.ground.free()
