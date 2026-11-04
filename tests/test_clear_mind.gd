extends RefCounted
## Clear Mind: everyone in the circle is hypnotized -- they sense nothing special and go on with their day while people
## die beside them and houses burn -- and whoever walks in joins them; nothing of their day is taken, and the fright
## does not come back when the trance ends.


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
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func run(t) -> void:
	var b := PowerBook.get_power("clearmind")
	t.check(int(b.dp) == 3 and PowerBook.authority_of("clearmind") == "dominion" and PowerBook.is_quiet("clearmind")
		and PowerBook.icon("clearmind") != null and PowerBook.hud_icon("clearmind") != null and PowerBook.clip("clearmind") != null
		and Targeting.AREAS.has("clearmind") and Rules.POWER_KINDS.has("clearmind") and PowerBook.family("clearmind") != "",
		"Clear Mind is Dominion's 3 DP, quiet, with icons, clip, area, kinds and a family")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b2: Person = crowd.citizens[1]
	var guard: Person = crowd.soldiers[0]
	var outside: Person = crowd.citizens[2]
	var victim: Person = crowd.citizens[3]
	var scared: Person = crowd.citizens[4]
	for p in [a, b2, outside, scared]:
		p.mind = Person.Mind.CALM
	a.ground_pos = at + Vector2(1.0, 0.0)
	b2.ground_pos = at - Vector2(1.0, 0.0)
	guard.ground_pos = at + Vector2(0.0, 1.0)
	victim.ground_pos = at + Vector2(0.5, 0.5)
	outside.ground_pos = at + Vector2(ClearMindFx.RADIUS + 2.0, 0.0)
	scared.ground_pos = at + Vector2(0.0, -1.0)
	scared.mind = Person.Mind.PANIC
	scared._panic_left = 5.0
	var fx: ClearMindFx = FxTimeline.cast(load("res://src/fx/dominion/clear_mind.gd"), ctx, at)
	t.check(fx.taken == 0 and a.fearless_left == 0.0, "Clear Mind: nobody is taken until it lands")
	fx._process(ClearMindFx.T_CAST + 0.05)
	t.check(fx.entranced.has(a) and fx.entranced.has(guard) and fx.entranced.has(scared) and not fx.entranced.has(outside)
		and a.fearless_left > 0.0 and guard.fearless_left > 0.0 and a.badge_left > 0.0,
		"then everyone in the circle is entranced, a soldier too, under the spiral; one outside is not (%d)" % fx.taken)
	t.check(scared.mind != Person.Mind.PANIC and not scared._reassured_fled, "one frightened is calmed back into its day")
	var mind := a.mind
	crowd.fright(at, 1.5, 0.6, 5.0, 4.0, 8.0, &"frenzy")
	t.check(a.mind == mind and b2.mind != Person.Mind.PANIC and guard.mind != Person.Mind.PANIC, "a fright beside them frightens nobody entranced")
	field.kill(victim, &"lightning", victim.ground_pos)
	crowd._settle_doom()
	t.check(not victim.is_alive() and a.mind == mind and b2.mind == mind, "one dies beside them and they go on (%s)" % Person.Mind.keys()[a.mind])
	crowd.threats.clear()
	# Whoever walks in joins.
	outside.ground_pos = at + Vector2(0.0, 2.0)
	fx._process(ClearMindFx.JOIN_EVERY + 0.05)
	t.check(fx.entranced.has(outside) and outside.fearless_left > 0.0, "whoever walks in while it holds is taken as well")
	# The keeper does not go to the rope; the brigade lets the house burn; the guard sends nobody to look.
	var keeper: Person = crowd.bell.keeper
	if keeper != null:
		keeper.fearless_left = 10.0
		crowd.bell.state = BellNetwork.State.IDLE
		crowd.bell.call_keeper()
		t.check(crowd.bell.state == BellNetwork.State.WAITING, "an entranced bellkeeper does not go to the rope (%s)" % BellNetwork.State.keys()[crowd.bell.state])
		keeper.fearless_left = 0.0
		crowd.bell.state = BellNetwork.State.IDLE
	# The trance ends (the people's own clocks run it down): they see again, and nobody runs from a danger that is gone.
	fx._process(ClearMindFx.TRANCE_TIME + 1.0)
	for p in [a, b2, guard, scared, outside]:
		p._think(ClearMindFx.TRANCE_TIME + 2.0)
		p.mind = Person.Mind.CALM if not p.soldier else p.mind
	mind = a.mind
	t.check(not fx.holding() and a.mind == mind and scared.mind != Person.Mind.PANIC and a.fearless_left == 0.0,
		"when it ends they are as they were, and the old fright does not come back")
	crowd.fright(at, 1.5, 0.6, 5.0, 4.0, 8.0, &"frenzy")
	t.check(a.mind == Person.Mind.PANIC, "and a new danger frightens them again")
	fx.free()
	_done(made)
