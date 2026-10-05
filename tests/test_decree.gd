extends RefCounted
## The Decree Authority. Leaving Is Prohibited: nobody in the circle can leave it, and nobody is held still. The Bell
## Lies: rung, the bell tolls all is well. Magnify: what is already there is doubled, and nothing new is made.
## Abolition: one law of the night -- the clock, the escape limit, the Citadel's ward -- is void for a while.


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
	var problems := []
	var prices := {"noleave": 1, "belllies": 2, "magnify": 3, "abolition": 5}
	for key: String in prices:
		var b := PowerBook.get_power(key)
		if int(b.dp) != int(prices[key]) or PowerBook.icon(key) == null or PowerBook.hud_icon(key) == null or PowerBook.clip(key) == null \
				or not ResourceLoader.exists(String(b.path)) or not Targeting.AREAS.has(key) or not Rules.POWER_KINDS.has(key) \
				or PowerBook.authority_of(key) != "decree" or not PowerBook.is_quiet(key):
			problems.append(key)
	t.check(problems.is_empty() and Array(PowerBook.of_authority("decree")) == ["noleave", "belllies", "magnify", "abolition"]
		and PowerBook.authority_title("decree") == "DECREE",
		"Decree holds four quiet powers at 1, 2, 3 and 5 DP, each with its effect, icons, clip and area (%s)" % [problems])
	var modes: Array = PowerBook.get_power("abolition").modes
	t.check(modes.size() == 3 and String(modes[0].key) == "clock" and String(modes[1].key) == "escape" and String(modes[2].key) == "ward",
		"Abolition's modes are the three laws")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var town: Town = made[6]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var guard: Person = crowd.soldiers[0]

	# --- Leaving Is Prohibited
	a.ground_pos = at + Vector2(1.0, 0.0)
	guard.ground_pos = at - Vector2(1.0, 0.0)
	b.ground_pos = at + Vector2(NoLeaveFx.RADIUS + 2.0, 0.0)
	var wall: NoLeaveFx = FxTimeline.cast(load("res://src/fx/decree/leaving_is_prohibited.gd"), ctx, at)
	t.check(not wall.sealed and wall.bound.is_empty(), "Leaving Is Prohibited: nothing holds until the law lands")
	wall._process(NoLeaveFx.T_SEAL + 0.05)
	t.check(wall.sealed and wall.bound.has(a) and wall.bound.has(guard) and not wall.bound.has(b) and a.badge_left > 0.0,
		"then whoever stands inside is bound, a soldier too, and wears the bars; one outside is not")
	var mind := a.mind
	a.ground_pos = at + Vector2(NoLeaveFx.RADIUS + 1.0, 0.0)
	wall._process(0.016)
	t.check(is_equal_approx(a.ground_pos.distance_to(at), NoLeaveFx.RADIUS) and wall.turned_back == 1 and a.mind == mind,
		"one who walks past the edge is set back onto it, its mind its own (%.2f)" % a.ground_pos.distance_to(at))
	a.ground_pos = at + Vector2(0.5, 0.5)
	wall._process(0.016)
	t.check(a.ground_pos.is_equal_approx(at + Vector2(0.5, 0.5)), "inside the circle it walks where it likes")
	b.ground_pos = at + Vector2(0.0, 1.0)
	wall._process(NoLeaveFx.JOIN_EVERY + 0.05)
	t.check(wall.bound.has(b), "whoever walks in afterwards is bound as well")
	guard.ground_pos = at + Vector2(NoLeaveFx.RADIUS + NoLeaveFx.CARRIED + 4.0, 0.0)
	wall._process(0.016)
	t.check(not wall.bound.has(guard) and guard.ground_pos.distance_to(at) > NoLeaveFx.RADIUS + NoLeaveFx.CARRIED and guard.badge_left == 0.0,
		"one carried far beyond the edge by something greater is free of it")
	wall._process(NoLeaveFx.HOLD_TIME)
	b.ground_pos = at + Vector2(NoLeaveFx.RADIUS + 2.0, 0.0)
	wall._process(0.016)
	t.check(not wall.sealed and wall.bound.is_empty() and b.ground_pos.distance_to(at) > NoLeaveFx.RADIUS and b.badge_left == 0.0,
		"when the time is up the law lifts and they go where they will")
	wall.free()

	# --- The Bell Lies
	var lie: BellLiesFx = FxTimeline.cast(load("res://src/fx/decree/the_bell_lies.gd"), ctx, at)
	t.check(not crowd.is_bell_lying(), "The Bell Lies: the bell is true until the law lands")
	lie._process(BellLiesFx.T_CAST + 0.05)
	crowd.add_alarm(30.0)
	var alarm := crowd.alarm
	var scared: Person = crowd.citizens[6]
	scared.ground_pos = at + Vector2(0.0, 5.0)
	scared.mind = Person.Mind.PANIC
	crowd.bell._ring()
	t.check(crowd.is_bell_lying() and crowd.bell.lied == 1 and lie.lies == 1 and crowd.bell.state == BellNetwork.State.WAITING
		and not crowd.alarms.bell_rung, "rung, it tolls all is well: the town is not warned, and the keeper must try again")
	t.check(is_equal_approx(crowd.alarm, alarm - Crowd.LIE_CALM) and scared.fearless_left > 0.0 and scared.mind != Person.Mind.PANIC,
		"the alarm falls and those who hear take heart (%.0f from %.0f)" % [crowd.alarm, alarm])
	crowd._clock += BellLiesFx.LIE_TIME
	lie._process(BellLiesFx.LIE_TIME + 2.0)
	lie.free()
	crowd.bell._ring()
	t.check(not crowd.is_bell_lying() and crowd.bell.state == BellNetwork.State.RUNG and crowd.alarms.bell_rung and crowd.bell.lied == 1,
		"after its time the bell rings true again")

	# --- Magnify
	for person in crowd.citizens:
		person.fearless_left = 0.0  # the lying bell's comfort is not this test's
	var spot := at + Vector2(0.0, 9.0)
	var dazed: Person = crowd.citizens[2]
	var mad: Person = crowd.citizens[3]
	var plain: Person = crowd.citizens[4]
	dazed.ground_pos = spot + Vector2(1.0, 0.0)
	mad.ground_pos = spot - Vector2(1.0, 0.0)
	plain.ground_pos = spot + Vector2(0.0, 1.0)
	plain.mind = Person.Mind.CALM
	dazed.confuse(10.0)
	dazed.sick_left = 20.0
	mad.statuses[MadnessManager.STATUS] = 0.3
	var shed := env.add_structure(Rect2(spot + Vector2(1.5, 1.5), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	shed.damage(20.0, shed.center(), &"gravity")
	var taken := shed.max_hp - shed.hp
	var whole := env.add_structure(Rect2(spot + Vector2(-2.5, 1.5), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	crowd.fires.ignite(whole, 0.3)
	var swell: MagnifyFx = FxTimeline.cast(load("res://src/fx/decree/magnify.gd"), ctx, spot)
	t.check(is_equal_approx(dazed._confused_left, 10.0) and swell.people == 0, "Magnify: nothing changes until it lands")
	swell._process(MagnifyFx.T_SWELL + 0.05)
	t.check(is_equal_approx(dazed._confused_left, 20.0) and is_equal_approx(dazed.sick_left, 10.0)
		and is_equal_approx(float(mad.statuses[MadnessManager.STATUS]), 0.6) and swell.people == 2,
		"what holds a person holds twice as long, a sickness runs twice as fast, a madness is twice as deep (%d)" % swell.people)
	t.check(plain.mind == Person.Mind.CALM and plain.statuses.is_empty() and not plain.magnify(2.0), "one nothing has touched is left as it was")
	t.check(is_equal_approx(shed.max_hp - shed.hp, taken * 2.0) and swell.cracked == 1 and not crowd.fires.is_burning(shed),
		"a damaged building takes its damage once more, and no fire of it (%.0f of %.0f)" % [shed.max_hp - shed.hp, shed.max_hp])
	t.check(is_equal_approx(crowd.fires.intensity(whole), 0.6) and swell.fires == 1 and is_equal_approx(whole.hp, whole.max_hp),
		"a fire burns twice as hard; a whole building is not hurt")
	swell._process(4.0)
	swell.free()
	crowd.fires.clear()
	var idle: MagnifyFx = FxTimeline.cast(load("res://src/fx/decree/magnify.gd"), ctx, Vector2(-26.0, -26.0))
	idle._process(MagnifyFx.T_SWELL + 0.05)
	t.check(idle.people + idle.fires + idle.cracked == 0, "on untouched ground it does nothing at all")
	idle._process(4.0)
	idle.free()

	# --- Abolition
	var rules := Rules.new().setup(PackedStringArray(["abolition"]), ctx, env, made[3], crowd, town)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	ctx.rules = rules
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	rules.advance(1.0)
	var clock := rules.time_left
	var edict: AbolitionFx = FxTimeline.cast(load("res://src/fx/decree/abolition.gd"), ctx, at, {"mode": "clock"})
	rules.advance(1.0)
	t.check(edict.law == "clock" and not edict.abolished and is_equal_approx(rules.time_left, clock - 1.0),
		"Abolition: the law stands while the decree is spoken (finished %s, %.1f of %.1f)" % [rules.finished, rules.time_left, clock])
	edict._process(AbolitionFx.T_DECREE + 0.05)
	rules.advance(5.0)
	t.check(edict.abolished and rules.is_abolished(Rules.LAW_CLOCK) and is_equal_approx(rules.time_left, clock - 1.0)
		and banners.has("THE CLOCK IS ABOLISHED"), "the clock abolished: it does not run, and the night is told")
	rules.advance(AbolitionFx.ABOLISH_TIME)
	rules.advance(2.0)
	t.check(not rules.is_abolished(Rules.LAW_CLOCK) and rules.time_left < clock - 2.5, "the law comes back by itself and the clock runs on")
	edict._process(AbolitionFx.ABOLISH_TIME + 3.0)
	edict.free()

	var gone := rules.escaped_this_act()
	rules.abolish(Rules.LAW_ESCAPE, 5.0)
	crowd.escaped_count += 2
	crowd.escaped.emit(a)
	crowd.escaped.emit(b)
	t.check(rules.escaped_this_act() == gone, "the escape limit abolished: who escapes meanwhile is not counted")
	rules.advance(6.0)
	crowd.escaped_count += 1
	crowd.escaped.emit(a)
	t.check(rules.escaped_this_act() == gone + 1, "and is counted again afterwards")

	var ward := town.citadel.budget_per_second
	edict = FxTimeline.cast(load("res://src/fx/decree/abolition.gd"), ctx, at, {"mode": "ward"})
	edict._process(AbolitionFx.T_DECREE + 0.05)
	t.check(rules.is_abolished(Rules.LAW_WARD) and is_equal_approx(town.citadel.budget_per_second, Rules.WARD_GONE),
		"the Citadel's ward abolished: nothing caps what it loses in a second")
	rules.abolish(Rules.LAW_WARD, 3.0)
	rules.advance(AbolitionFx.ABOLISH_TIME + 0.5)
	t.check(not rules.is_abolished(Rules.LAW_WARD) and is_equal_approx(town.citadel.budget_per_second, ward),
		"and the ward is as it was when the time is up, however often it was struck")
	rules.abolish(&"gravity", 5.0)
	t.check(not rules.is_abolished(&"gravity"), "only a law of the night can be abolished")
	edict._process(AbolitionFx.ABOLISH_TIME + 3.0)
	edict.free()
	ctx.rules = null
	rules.free()
	_done(made)
