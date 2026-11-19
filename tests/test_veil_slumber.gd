extends RefCounted
## Slumber (Veil, Tier 2): everyone in the open within 1.5 (light) / 3.5 (dark) sleeps 20 s; light sleep wakes to a loud blow, dark sleep
## only to a hurt; quiet; the dusk it leaves; two casts; teardown; no crowd.


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	crowd.dusk.enabled = true
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		i += 1
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _cast(ctx: FxContext, at: Vector2, dark: bool) -> SlumberFx:
	return FxTimeline.cast(load("res://src/fx/veil/slumber.gd"), ctx, at, {"dark": dark}) as SlumberFx


static func run(t) -> void:
	var b := PowerBook.get_power("slumber")
	t.check(not b.is_empty() and PowerBook.authority_of("slumber") == "veil" and ResourceLoader.exists(String(b.path))
		and SlumberFx.SLEEP_TIME == 20.0 and SlumberFx.T_FALL == 0.6, "Slumber is a Veil power with its effect and its constants")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- light
	var near: Person = crowd.citizens[0]
	var far: Person = crowd.citizens[1]
	var guard: Person = crowd.soldiers[0]
	var inn: Person = crowd.citizens[2]
	var wide: Person = crowd.citizens[3]
	near.ground_pos = at + Vector2(1.4, 0.0)
	far.ground_pos = at + Vector2(1.6, 0.0)
	guard.ground_pos = at + Vector2(0.0, 1.0)
	inn.ground_pos = at + Vector2(0.5, 0.0)
	inn.inside = true
	wide.ground_pos = at + Vector2(3.0, 0.0)
	var order := SlumberFx.sleepers_at(field, at, 1.5)
	t.check(order.size() == 2 and order[0] == guard and order[1] == near and not order.has(inn),
		"sleepers_at: the open within r, nearest first, nobody inside (%d)" % order.size())
	var alarm := crowd.alarm
	var fx := _cast(ctx, at, false)
	t.check(fx.asleep == 0 and not near.is_asleep() and crowd.dusk.count() == 1, "nobody sleeps until the hush has settled; the dusk is laid at the cast")
	fx._process(SlumberFx.T_FALL + 0.05)
	t.check(fx.asleep == 2 and near.is_asleep() and guard.is_asleep() and not far.is_asleep() and not wide.is_asleep()
		and not near.is_deep_asleep() and not inn.is_asleep(),
		"light: 1.4 away sleeps, a soldier too; 1.6 and 3.0 do not; the one inside does not (%d)" % fx.asleep)
	t.check(is_equal_approx(near.sleep_left(), SlumberFx.SLEEP_TIME), "the sleep is 20 s (%.2f)" % near.sleep_left())
	t.check(is_equal_approx(crowd.alarm, alarm) and crowd.threats.active_count() == 0 and crowd.held_count() == 0,
		"quiet: no alarm, no danger registered")
	t.check(crowd.dusk.count() == 1 and is_equal_approx(crowd.dusk.r_at(at), 3.0) and crowd.dusk.covers(at + Vector2(2.9, 0.0))
		and not crowd.dusk.covers(at + Vector2(3.1, 0.0)), "light: dusk laid with r 3.0 (%.2f)" % crowd.dusk.r_at(at))
	var stood := near.ground_pos
	near.set_goal(grid.nearest_walkable(at + Vector2(6.0, 0.0)))
	for k in 10:
		near.tick(0.1)
	t.check(near.ground_pos.is_equal_approx(stood) and near.is_asleep(), "a sleeper goes nowhere")
	# A loud blow wakes the light sleeper (heard to 6.5 from 5 away).
	crowd.fright(near.ground_pos + Vector2(5.0, 0.0), 1.0, 0.5, 5.0, 3.0, 6.5, &"collapse")
	t.check(not near.is_asleep() and not guard.is_asleep(), "light: a loud blow nearby wakes them")
	crowd.threats.clear()
	crowd.dusk.clear()
	# All wake at 20 s: a fresh cast, then their own time.
	near.mind = Person.Mind.CALM
	var fx2 := _cast(ctx, at, false)
	fx2._process(SlumberFx.T_FALL + 0.05)
	near._think(SlumberFx.SLEEP_TIME - 1.0)
	t.check(near.is_asleep(), "asleep at 19 s")
	near._think(1.2)
	t.check(not near.is_asleep() and near.is_alive(), "and awake at 20 s")
	fx.free()
	fx2.free()
	crowd.dusk.clear()

	# --- dark
	for p in [near, guard, far, wide]:
		p.mind = Person.Mind.CALM
	wide.ground_pos = at + Vector2(3.4, 0.0)
	far.ground_pos = at + Vector2(3.6, 0.0)
	var dfx := _cast(ctx, at, true)
	dfx._process(SlumberFx.T_FALL + 0.05)
	t.check(dfx.asleep == 3 and near.is_deep_asleep() and guard.is_deep_asleep() and wide.is_deep_asleep() and not far.is_asleep(),
		"dark: r 3.5, a deep sleep (%d)" % dfx.asleep)
	t.check(crowd.dusk.count() == 1 and crowd.dusk.covers(at + Vector2(3.4, 0.0)) and not crowd.dusk.covers(at + Vector2(3.6, 0.0))
		and is_equal_approx(crowd.dusk.r_at(at), 3.5), "dark: dusk laid with r 3.5 (%.2f)" % crowd.dusk.r_at(at))
	crowd.fright(near.ground_pos + Vector2(2.0, 0.0), 1.0, 0.5, 5.0, 3.0, 6.5, &"collapse")
	crowd.threats.clear()
	t.check(near.is_deep_asleep() and guard.is_deep_asleep(), "dark: the same blow does not wake them")
	near.panic(near.ground_pos + Vector2(1.0, 0.0), 3.0, &"fire")
	t.check(near.is_deep_asleep(), "dark: a danger does not either")
	near.hurt(0.05, null)
	t.check(not near.is_asleep() and guard.is_deep_asleep(), "dark: a hurt does wake one")
	dfx.free()
	crowd.dusk.clear()

	# --- two casts on one person
	var twice: Person = crowd.citizens[4]
	twice.ground_pos = at + Vector2(0.0, 0.5)
	twice.mind = Person.Mind.CALM
	var first := _cast(ctx, at, false)
	first._process(SlumberFx.T_FALL + 0.05)
	twice._think(12.0)
	var second := _cast(ctx, at, false)
	second._process(SlumberFx.T_FALL + 0.05)
	t.check(twice.is_asleep() and is_equal_approx(twice.sleep_left(), SlumberFx.SLEEP_TIME),
		"a second cast runs the sleep to the later end (%.1f)" % twice.sleep_left())
	first._process(5.0)
	t.check(first.finished and twice.is_asleep(), "the first effect's finish does not wake him")
	twice._think(SlumberFx.SLEEP_TIME - 3.0)
	t.check(twice.is_asleep(), "he sleeps on to the later end")
	twice._think(3.5)
	t.check(not twice.is_asleep(), "and wakes there")
	second.free()
	first.free()
	crowd.dusk.clear()

	# --- teardown
	var a: Person = crowd.citizens[5]
	var c: Person = crowd.citizens[6]
	a.ground_pos = at + Vector2(0.5, 0.0)
	c.ground_pos = at + Vector2(0.0, 0.5)
	a.mind = Person.Mind.CALM
	c.mind = Person.Mind.CALM
	var cut := _cast(ctx, at, true)
	cut.end_now()
	t.check(cut.finished and not a.is_asleep(), "ended before it lands: nobody sleeps")
	cut.free()
	var live := _cast(ctx, at, true)
	live._process(SlumberFx.T_FALL + 0.05)
	t.check(a.is_deep_asleep(), "cast and landed: deep asleep")
	live.end_now()
	live.free()
	a._think(SlumberFx.SLEEP_TIME + 1.0)
	t.check(a.is_alive() and not a.is_deep_asleep() and not a.is_asleep(),
		"teardown: ended and freed, nobody is left deep-asleep past the time")
	var control := _cast(ctx, at, true)
	control._process(SlumberFx.T_FALL + 0.05)
	c._think(SlumberFx.SLEEP_TIME - 2.0)
	t.check(c.is_deep_asleep(), "control: left to run, they sleep")
	control.free()
	crowd.dusk.clear()
	_done(made)

	# --- no crowd: builds and finishes
	var env := EnvironmentField.new()
	var bare := FxContext.new()
	bare.env = env
	bare.field = EnemyField.new()
	bare.field.env = env
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var sb := _cast(bare, Vector2.ZERO, false)
	sb._process(SlumberFx.T_FALL + 0.05)
	sb._process(5.0)
	t.check(sb.finished and sb.asleep == 0, "no crowd: builds and finishes")
	sb.free()
	bare.overhead.free()
	bare.ground.free()
