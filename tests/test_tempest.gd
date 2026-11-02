extends RefCounted
## Tempest: a storm over the whole town. It gathers, then bolts fall where the god's rng sends them -- tall things first
## -- each a Smite; every fourth lights a fire; the rain sends the calm indoors; then it breaks.


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
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func run(t) -> void:
	var b := PowerBook.get_power("tempest")
	t.check(int(b.dp) == 5 and PowerBook.authority_of("tempest") == "ruin" and not PowerBook.is_quiet("tempest")
		and is_equal_approx(PowerBook.impact("tempest"), TempestFx.T_GATHER) and PowerBook.family("tempest") == "strike"
		and PowerBook.icon("tempest") != null and PowerBook.hud_icon("tempest") != null and PowerBook.clip("tempest") != null
		and Targeting.AREAS.has("tempest") and Rules.POWER_KINDS["tempest"].has(&"lightning") and Rules.POWER_KINDS["tempest"].has(&"tempest"),
		"Tempest is Ruin's 5 DP, loud, its impact the gathering, with icons, clip, area and kinds")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var at := TownLayout.MARKET_SQUARE.get_center()
	var alive0 := 0
	for p in crowd.citizens + crowd.soldiers:
		if p.is_alive():
			alive0 += 1
	var outside0 := 0
	for p in crowd.citizens:
		if p.is_alive() and not p.inside:
			outside0 += 1
	var storm: TempestFx = FxTimeline.cast(load("res://src/fx/ruin/tempest.gd"), ctx, at)
	t.check(not storm.storming() and storm.bolts == 0 and is_equal_approx(storm.busy, TempestFx.T_GATHER),
		"Tempest: nothing falls while it gathers, and the slots are locked for the gathering")
	storm._process(TempestFx.T_GATHER - 0.1)
	t.check(storm.bolts == 0, "still nothing at the end of the gathering")
	storm._process(0.35)
	t.check(storm.volleys == 1 and storm.bolts == 0, "the first volley is told (%d) before any bolt falls (%d)" % [storm.volleys, storm.bolts])
	storm._process(TempestFx.LEAD)
	t.check(storm.bolts >= 1, "and its bolts fall LEAD later (%d)" % storm.bolts)
	# The storm, stepped as the game would, a tenth of a second at a time.
	var steps := int((TempestFx.STORM_TIME - 0.35 - TempestFx.LEAD) / 0.1)
	for k in steps:
		storm._process(0.1)
		crowd.shelters.step(0.1)
	var volleys := int(TempestFx.STORM_TIME / TempestFx.VOLLEY_EVERY)
	t.check(storm.volleys >= volleys and storm.volleys <= volleys + 1 and storm.bolts >= storm.volleys * TempestFx.VOLLEY.x
		and storm.bolts <= storm.volleys * TempestFx.VOLLEY.y, "then a volley every %.1f s of %d-%d bolts: %d volleys, %d bolts in %.0f s" % [TempestFx.VOLLEY_EVERY, TempestFx.VOLLEY.x, TempestFx.VOLLEY.y, storm.volleys, storm.bolts, TempestFx.STORM_TIME])
	var alive := 0
	for p in crowd.citizens + crowd.soldiers:
		if p.is_alive():
			alive += 1
	var damaged := 0
	for s in env.structures():
		if is_instance_valid(s) and (s.destroyed or s.hp < s.max_hp):
			damaged += 1
	t.check(damaged > 0 and storm.struck == alive0 - alive, "the bolts strike buildings (%d hit) and people (%d struck, as counted)" % [damaged, storm.struck])
	t.check(storm.fires == storm.bolts / TempestFx.FIRE_EVERY or storm.fires == storm.bolts / TempestFx.FIRE_EVERY - 1 or crowd.fires.fires.size() > 0,
		"every fourth bolt lights what it struck when it burns (%d fires of %d bolts)" % [storm.fires, storm.bolts])
	var inside := 0
	for p in crowd.citizens:
		if p.is_alive() and (p.inside or p.mind == Person.Mind.SHELTER):
			inside += 1
	t.check(storm.sent_in > 0 and inside > 0, "the rain sends the calm indoors (%d sent, %d in or on their way, of %d out before)" % [storm.sent_in, inside, outside0])
	t.check(crowd.threats.active_count() > 0, "the town knows a danger where the last bolts fell")
	var last := storm.last_at
	storm._process(TempestFx.T_BREAK + 0.5)
	t.check(not storm.storming() and storm.last_at == last and storm.t >= storm.duration, "then it breaks: no more bolts")
	storm.free()

	# Where the bolts fall is weighted by height: the tallest things draw them most.
	var ctx2: FxContext = made[5]
	ctx2.rng.seed = 11
	var tall := 0
	var probe: TempestFx = FxTimeline.cast(load("res://src/fx/ruin/tempest.gd"), ctx2, at)
	# The tall (the Bell Tower's height and up) are few; the bolts find them far more often than their number.
	var tall_n := 0
	var all_n := 0
	for s in env.structures():
		if is_instance_valid(s) and not s.destroyed and s.role != &"thorns":
			all_n += 1
			if s.height >= TownLayout.BELL_TOWER_H * 0.9:
				tall_n += 1
	for k in 300:
		probe.last_at = Vector2.INF
		var where := probe._pick()
		for s in env.structures():
			if is_instance_valid(s) and not s.destroyed and s.center().distance_to(where) < 0.01 and s.height >= TownLayout.BELL_TOWER_H * 0.9:
				tall += 1
				break
	t.check(tall_n > 0 and float(tall) / 300.0 > 2.0 * float(tall_n) / float(all_n),
		"the tall draw the bolts: %d of 300 picks on the %d tall things of %d" % [tall, tall_n, all_n])
	probe.free()
	_done(made)
