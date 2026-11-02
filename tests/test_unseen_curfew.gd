extends RefCounted
## Unseen Hour: for a while nothing in the circle is seen -- no cast there is feared, no death or collapse there brings
## anyone, no danger there is marked -- while the people inside go on as they were. Curfew: everyone in the circle
## sleeps where they stand, and only a loud blow nearby, a hurt, or the end of the sleep wakes them.


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
	var problems := []
	for key: String in ["unseen", "curfew"]:
		var b := PowerBook.get_power(key)
		if PowerBook.icon(key) == null or PowerBook.hud_icon(key) == null or PowerBook.clip(key) == null \
				or not ResourceLoader.exists(String(b.path)) or not Targeting.AREAS.has(key) or not Rules.POWER_KINDS.has(key) \
				or not PowerBook.is_quiet(key):
			problems.append(key)
	t.check(problems.is_empty() and PowerBook.authority_of("unseen") == "veil" and int(PowerBook.get_power("unseen").dp) == 3
		and PowerBook.authority_of("curfew") == "decree" and int(PowerBook.get_power("curfew").dp) == 4,
		"Unseen Hour is Veil's 3 DP and Curfew Decree's 4, quiet, each with its effect, icons, clip and area (%s)" % [problems])

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var far := at + Vector2(UnseenHourFx.RADIUS + 12.0, 0.0)

	# --- Unseen Hour
	var inside: Person = crowd.citizens[0]
	var witness: Person = crowd.citizens[1]
	var victim: Person = crowd.citizens[2]
	inside.ground_pos = at + Vector2(1.0, 0.0)
	inside.mind = Person.Mind.CALM
	witness.ground_pos = at + Vector2(0.0, 1.0)
	witness.mind = Person.Mind.CALM
	victim.ground_pos = at - Vector2(1.0, 0.0)
	var hour: UnseenHourFx = FxTimeline.cast(load("res://src/fx/quiet/unseen_hour.gd"), ctx, at)
	t.check(not crowd.is_veiled(at) and not hour.veiled, "Unseen Hour: everything is seen until the veil falls")
	hour._process(UnseenHourFx.T_FALL + 0.05)
	t.check(hour.veiled and crowd.is_veiled(at) and crowd.is_veiled(at + Vector2(UnseenHourFx.RADIUS - 0.1, 0.0))
		and not crowd.is_veiled(at + Vector2(UnseenHourFx.RADIUS + 0.5, 0.0)), "then nothing within its circle is seen, and everything outside is")
	var alarm := crowd.alarm
	crowd.on_cast(at, Vector2.ZERO, 0.0, "nova")
	t.check(crowd.held_count() == 0 and is_equal_approx(crowd.alarm, alarm) and inside.mind == Person.Mind.CALM,
		"a loud power cast inside is not looked at, feared or counted (%d held)" % crowd.held_count())
	crowd.on_cast(far, Vector2.ZERO, 0.0, "nova")
	t.check(crowd.held_count() == 1, "the same cast outside is a danger as ever")
	crowd.drop_held()
	for p in [inside, witness]:
		p.mind = Person.Mind.CALM  # the far cast's build-up was looked at; that is not this test's
	t.check(crowd.threats.register(at, 1.0, 0.5, 5.0, 3.0, 4.0, &"fire") == -1 and crowd.threats.register(far, 1.0, 0.5, 5.0, 3.0, 4.0, &"fire") > 0
		and crowd.threats.active_count() == 1, "no danger is marked inside the veil; outside it is")
	crowd.threats.clear()
	crowd.fright(at, 1.5, 0.5, 5.0, 3.0, 5.0, &"frenzy")
	t.check(inside.mind == Person.Mind.CALM and witness.mind == Person.Mind.CALM and crowd.threats.active_count() == 0,
		"a fright inside frightens nobody (%s %s, %d)" % [Person.Mind.keys()[inside.mind], Person.Mind.keys()[witness.mind], crowd.threats.active_count()])
	var dead := crowd.killed_citizens
	field.kill(victim, &"lightning", victim.ground_pos)
	t.check(not victim.is_alive() and crowd.killed_citizens == dead + 1 and is_equal_approx(crowd.alarm, alarm)
		and witness.mind == Person.Mind.CALM, "a death inside is a death, and nobody comes or cries out (alarm %.1f from %.1f, %s)" % [crowd.alarm, alarm, Person.Mind.keys()[witness.mind]])
	var shed := env.add_structure(Rect2(at + Vector2(1.5, 1.5), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	shed.damage(shed.max_hp + 10.0, shed.center(), &"stone")
	t.check(shed.destroyed and is_equal_approx(crowd.alarm, alarm) and crowd.threats.active_count() == 0
		and inside.mind == Person.Mind.CALM and witness.mind == Person.Mind.CALM, "a building falling inside is not seen to fall (alarm %.1f from %.1f, %d threats, %s %s)" % [crowd.alarm, alarm, crowd.threats.active_count(), Person.Mind.keys()[inside.mind], Person.Mind.keys()[witness.mind]])
	crowd.fright(at + Vector2(UnseenHourFx.RADIUS + 1.0, 0.0), 1.0, 0.5, 5.0, 3.0, 8.0, &"frenzy")
	t.check(inside.mind != Person.Mind.CALM, "a danger outside still reaches the eyes of those inside (%s)" % Person.Mind.keys()[inside.mind])
	crowd.threats.clear()
	crowd._clock += UnseenHourFx.VEIL_TIME + 1.0
	hour._process(UnseenHourFx.VEIL_TIME + 1.5)
	hour.free()
	t.check(not crowd.is_veiled(at), "the hour over, the place is seen again")
	crowd.on_cast(at, Vector2.ZERO, 0.0, "nova")
	t.check(crowd.held_count() == 1, "and a loud cast there is a danger again")
	crowd.drop_held()

	# --- Curfew
	var spot := at + Vector2(0.0, 9.0)
	var a: Person = crowd.citizens[3]
	var b: Person = crowd.citizens[4]
	var guard: Person = crowd.soldiers[0]
	var awake: Person = crowd.citizens[5]
	a.ground_pos = spot + Vector2(1.0, 0.0)
	b.ground_pos = spot - Vector2(1.0, 0.0)
	guard.ground_pos = spot + Vector2(0.0, 1.0)
	awake.ground_pos = spot + Vector2(CurfewFx.RADIUS + 1.0, 0.0)
	for p in [a, b, awake]:
		p.mind = Person.Mind.CALM
	var night: CurfewFx = FxTimeline.cast(load("res://src/fx/decree/curfew.gd"), ctx, spot)
	t.check(night.asleep == 0 and a.mind == Person.Mind.CALM, "Curfew: nobody sleeps until the decree lands")
	night._process(CurfewFx.T_CAST + 0.05)
	t.check(night.asleep == 3 and a.is_asleep() and b.is_asleep() and guard.is_asleep() and not awake.is_asleep() and a.is_stumbling(),
		"then everyone in the circle sleeps where they stand, a soldier too, down on the ground; one outside does not (%d)" % night.asleep)
	a.set_goal(grid.nearest_walkable(spot + Vector2(6.0, 0.0)))
	var stood := a.ground_pos
	for k in 20:
		a.tick(0.1)
	t.check(a.ground_pos.is_equal_approx(stood) and a.is_asleep(), "a sleeper goes nowhere (moved %.2f, %s)" % [a.ground_pos.distance_to(stood), Person.Mind.keys()[a.mind]])
	crowd.threats.register(b.ground_pos + Vector2(0.5, 0.0), 1.0, 0.5, 5.0, 3.0, 4.0, &"collapse")
	crowd._watch_threats()
	t.check(b.is_asleep(), "a danger that only stands nearby does not wake it")
	crowd.threats.clear()
	# A loud blow 5 away: heard to 6.5, so a and the guard (6.1 away) wake; b, 7 away, sleeps on.
	crowd.fright(a.ground_pos + Vector2(5.0, 0.0), 1.0, 0.5, 5.0, 3.0, 6.5, &"collapse")
	t.check(not a.is_asleep() and not guard.is_asleep() and b.is_asleep(),
		"a loud blow wakes those near enough to hear it (%s, %s), not one out of earshot" % [Person.Mind.keys()[a.mind], Person.Mind.keys()[guard.mind]])
	crowd.threats.clear()
	b.hurt(0.05, null)
	t.check(not b.is_asleep() and b.is_alive(), "a hurt wakes a sleeper")
	var dozer: Person = crowd.citizens[6]
	dozer.ground_pos = spot
	dozer.mind = Person.Mind.CALM
	t.check(dozer.sleep(2.0) and dozer.is_asleep(), "one can be put to sleep for a while")
	dozer._think(2.1)
	t.check(not dozer.is_asleep() and dozer.is_alive(), "and wakes when the time is up")
	t.check(not victim.sleep(5.0), "the dead do not sleep")
	night._process(CurfewFx.SLEEP_TIME + 2.0)
	night.free()
	_done(made)
