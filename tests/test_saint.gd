extends RefCounted
## Saint or Sinner: one is chosen; the wheel says whether everyone round them guards them at all cost or kills them.


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
	var b := PowerBook.get_power("saint")
	var modes: Array = b.get("modes", [])
	t.check(int(b.dp) == 3 and PowerBook.authority_of("saint") == "dominion" and PowerBook.is_quiet("saint") and String(b.aim) == "wheel"
		and modes.size() == 2 and String(modes[0].key) == "saint" and String(modes[1].key) == "sinner"
		and PowerBook.icon("saint") != null and PowerBook.hud_icon("saint") != null and PowerBook.clip("saint") != null
		and Targeting.AREAS.has("saint") and Rules.POWER_KINDS["saint"].has(&"frenzy") and PowerBook.family("saint") != "",
		"Saint or Sinner is Dominion's 3 DP, quiet, aimed by a wheel of two, with icons, clip, area, kinds and a family")

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
	var chosen: Person = crowd.citizens[0]
	var near: Array[Person] = []
	chosen.ground_pos = at
	chosen.mind = Person.Mind.CALM
	for k in 4:
		var p: Person = crowd.citizens[1 + k]
		p.ground_pos = grid.nearest_walkable(at + Vector2(2.0 + 0.5 * float(k), 1.0))
		p.mind = Person.Mind.CALM
		near.append(p)
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = grid.nearest_walkable(at + Vector2(-2.0, 1.0))
	var far: Person = crowd.citizens[6]
	far.ground_pos = at + Vector2(SaintFx.RADIUS + 3.0, 0.0)
	far.mind = Person.Mind.CALM
	t.check(SaintFx.target_at(field, at) == chosen and SaintFx.target_at(field, at + Vector2(20.0, 20.0)) == null, "the nearest to the click is chosen; nobody, nothing")

	# --- SAINT
	var saint: SaintFx = FxTimeline.cast(load("res://src/fx/dominion/saint_or_sinner.gd"), ctx, at, {"mode": "saint"})
	t.check(saint.chosen == chosen and saint.people.is_empty() and chosen.badge_left == 0.0, "Saint: the chosen is picked; nothing holds until it takes")
	saint._process(SaintFx.T_CAST + 0.05)
	var ringed := 0
	for p in near:
		if p.mind == Person.Mind.COMPELLED and p.goal().distance_to(chosen.ground_pos) <= SaintFx.GUARD_RING.y + 0.6:
			ringed += 1
	t.check(saint.people.size() == 5 and ringed == 4 and guard.mind == Person.Mind.COMPELLED and not saint.people.has(far) and chosen.badge_left > 0.0,
		"then everyone within reach, a soldier too, closes round the chosen in a ring; one outside is left (%d ringed)" % ringed)
	# The chosen walks; the ring follows.
	chosen.ground_pos = at + Vector2(0.0, 4.0)
	saint._process(SaintFx.RETHINK + 0.05)
	var followed := 0
	for p in near:
		if p.goal().distance_to(chosen.ground_pos) <= SaintFx.GUARD_RING.y + 0.6:
			followed += 1
	t.check(followed == 4, "the ring follows the chosen as they move (%d)" % followed)
	# Someone goes for the chosen: the nearest guards set on them.
	var foe: Person = crowd.citizens[7]
	foe.ground_pos = chosen.ground_pos + Vector2(1.0, 0.0)
	foe.fight(chosen, 20.0, SaintFx.CIVIL_BLOW, Person.FightRule.TARGET_ONLY)
	saint._process(SaintFx.RETHINK + 0.05)
	var defending := 0
	for p in saint.people:
		if p.mind == Person.Mind.FIGHT and p.fight_target == foe:
			defending += 1
	t.check(saint.repelled == 1 and defending == SaintFx.GUARDS_PER_THREAT, "whoever goes for the chosen is set on by the nearest guards (%d)" % defending)
	saint._process(SaintFx.SPAN + 1.0)
	saint.free()
	for p in near + [guard, foe]:
		p.stop_fighting()
		p.release_compulsion()

	# --- SINNER
	for p in near:
		p.ground_pos = grid.nearest_walkable(at + Vector2(2.0, 0.0))
		p.mind = Person.Mind.CALM
	chosen.ground_pos = at
	chosen.mind = Person.Mind.CALM
	chosen.health = Person.HEALTH_CITIZEN
	var sinner: SaintFx = FxTimeline.cast(load("res://src/fx/dominion/saint_or_sinner.gd"), ctx, at, {"mode": "sinner"})
	sinner._process(SaintFx.T_CAST + 0.05)
	var hunting := 0
	for p in sinner.people:
		if p.mind == Person.Mind.FIGHT and p.fight_target == chosen:
			hunting += 1
	t.check(sinner.mode == "sinner" and hunting == sinner.people.size() and hunting >= 4 and chosen.badge_left > 0.0,
		"Sinner: everyone within reach goes for the chosen (%d)" % hunting)
	for k in 400:
		for p in sinner.people:
			p.tick(0.1)
		if not chosen.is_alive():
			break
	t.check(not chosen.is_alive() and chosen._kind == &"frenzy", "and the chosen is beaten to death")
	sinner._process(SaintFx.SPAN + 1.0)
	sinner.free()
	_done(made)
