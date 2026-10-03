extends RefCounted
## Voice of God: one command and everyone obeys, soldiers too, as the wave reaches them; no danger breaks it; when its
## time is up each takes up its own judgement again. Kneel and Halt hold people where they stand, Flee runs them from
## the click, Gather walks them to its place, Return sends them home, Silence stops every call for help, Judge turns
## those near on one person until it falls.

const PATH := "res://src/fx/dominion/voice_of_god.gd"


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


## Cast `command` at `at` and let the wave cross the town.
static func _cast(ctx: FxContext, at: Vector2, command: String) -> VoiceOfGodFx:
	var fx: VoiceOfGodFx = FxTimeline.cast(load(PATH), ctx, at, {"mode": command})
	fx._process(2.5)
	return fx


## Lift every command and put the two back to calm.
static func _reset(fx: VoiceOfGodFx, crowd: Crowd) -> void:
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p) and p.is_alive():
			p.release_compulsion()
			p.stop_fighting()
			p.clear_badge()
			if not p.soldier:
				p.mind = Person.Mind.CALM
	fx.free()


static func run(t) -> void:
	var book := PowerBook.get_power("voice")
	t.check(PowerBook.authority_of("voice") == "dominion" and int(book.dp) == 5 and PowerBook.is_quiet("voice")
		and float(book.alarm) >= 5.0 and (book.modes as Array).size() == 7 and PowerBook.icon("voice") != null
		and PowerBook.hud_icon("voice") != null and PowerBook.clip("voice") != null,
		"%s: Dominion, 5 DP, seven commands, a major alarm, its icons and clip" % book.name)
	var keys := []
	for m: Dictionary in book.modes:
		keys.append(m.key)
		if not VoiceOfGodFx.COMMANDS.has(m.key) or not VoiceOfGodFx.GLYPHS.has(m.key):
			keys.append("?")
	t.check(keys == ["kneel", "halt", "flee", "gather", "return", "silence", "judge"], "each command has its seconds and its glyph (%s)" % [keys])

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var c: Person = crowd.citizens[0]
	c.ground_pos = at + Vector2(1.0, 0.0)
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = at + Vector2(0.0, 1.0)
	var alive := crowd.alive_citizens() + crowd.alive_soldiers()

	# Kneel: the wave reaches the near first and the whole town within its sweep; soldiers obey; no danger breaks it.
	var fx: VoiceOfGodFx = FxTimeline.cast(load(PATH), ctx, at, {"mode": "kneel"})
	t.check(fx.busy == 1.5 and is_equal_approx(fx.duration, 13.0) and fx.obeyed == 0, "the cast locks the slots for 1.5 s; nobody is reached yet")
	fx._process(0.1)
	t.check(c.mind == Person.Mind.COMPELLED and fx.obeyed < alive, "the wave reaches those near first (%d of %d)" % [fx.obeyed, alive])
	fx._process(2.4)
	var inside := 0
	for p in crowd.citizens + crowd.soldiers:
		if p.inside:
			inside += 1
	t.check(fx.obeyed == alive - inside, "then the whole town (%d of %d)" % [fx.obeyed, alive])
	t.check(c.compel_pose == &"kneel" and c.goal().distance_to(c.ground_pos) < 0.5 or not c.has_goal(), "a citizen kneels where it stands")
	t.check(guard.mind == Person.Mind.COMPELLED and guard.compel_pose == &"kneel", "a soldier obeys like anyone: rank is no resistance")
	c.panic(c.ground_pos, 0.5)
	c.flee()
	t.check(c.mind == Person.Mind.COMPELLED and c.held_by_will(Person.WILL_ABSOLUTE), "no danger and no evacuation breaks it")
	c._think(VoiceOfGodFx.COMMANDS["kneel"])
	guard._think(VoiceOfGodFx.COMMANDS["kneel"])
	t.check(c.mind == Person.Mind.RECOVER and c.compel_pose == &"" and guard.mind == Person.Mind.POST,
		"when its time is up each takes up its own judgement: a citizen its day, a soldier its post")
	_reset(fx, crowd)

	# Halt, Flee, Gather, Return.
	fx = _cast(ctx, at, "halt")
	t.check(c.mind == Person.Mind.COMPELLED and c.compel_pose == &"" and c.anchor.distance_to(c.ground_pos) < 0.01, "Halt: everyone stands where they are")
	_reset(fx, crowd)
	fx = _cast(ctx, at, "flee")
	t.check(c.is_running() and c.goal().distance_to(at) > c.ground_pos.distance_to(at) + 3.0,
		"Flee: everyone runs from the click (%.1f away)" % c.goal().distance_to(at))
	_reset(fx, crowd)
	fx = _cast(ctx, at, "gather")
	t.check(not c.is_running() and c.goal().distance_to(at) < 6.0 and guard.goal().distance_to(at) < 6.0 and c.goal() != guard.goal(),
		"Gather: everyone walks to the place, each to a spot of its own")
	_reset(fx, crowd)
	fx = _cast(ctx, at, "return")
	t.check(c.goal().distance_to(c.profile.home) < 1.0 and (guard.post == Vector2.INF or guard.goal().distance_to(guard.post) < 1.0),
		"Return: a citizen to its home, a soldier to its post")
	_reset(fx, crowd)

	# Silence: nobody moves for it, but no death is cried.
	var alarm := crowd.alarm
	fx = _cast(ctx, at, "silence")
	t.check(c.mind == Person.Mind.CALM and c.badge_left > 0.0 and crowd.is_hushed(), "Silence: nobody is moved; the town is hushed")
	var victim: Person = crowd.citizens[30]
	field.kill(victim, &"stone", at)
	t.check(crowd.alarm == alarm and crowd.voices_played == 0, "a death in a silenced town raises no alarm and no cry")
	crowd.advance(VoiceOfGodFx.COMMANDS["silence"] + 0.1)
	field.kill(crowd.citizens[31], &"stone", at)
	t.check(not crowd.is_hushed() and crowd.alarm > alarm, "when the silence lifts, the next one does")
	_reset(fx, crowd)

	# Judge: the nearest to the click is condemned, those near turn on them, and stop when they fall.
	var condemned: Person = crowd.citizens[1]
	condemned.ground_pos = at
	c.ground_pos = at + Vector2(0.3, 0.0)
	guard.ground_pos = at + Vector2(0.0, 0.3)
	t.check(VoiceOfGodFx.judged_at(field, at) == condemned, "Judge condemns the one nearest the click")
	fx = _cast(ctx, at, "judge")
	t.check(fx.judged == condemned and c.mind == Person.Mind.FIGHT and c.fight_target == condemned and guard.fight_target == condemned,
		"those near turn on the condemned, soldiers too (%d judges)" % fx.judges)
	t.check(condemned.mind != Person.Mind.FIGHT and condemned.badge_color == VoiceOfGodFx.CRIMSON, "the condemned wears the crimson mark")
	for k in 40:
		condemned.ground_pos = at
		c.ground_pos = at + Vector2(0.3, 0.0)
		guard.ground_pos = at + Vector2(0.0, 0.3)
		c.tick(0.1)
		guard.tick(0.1)
		condemned.state = DummyEnemy.State.WANDER if condemned.is_alive() else condemned.state
	t.check(not condemned.is_alive(), "and strike until they fall")
	c.tick(0.1)
	c.tick(0.1)
	guard.tick(0.1)
	guard.tick(0.1)
	t.check(c.mind != Person.Mind.FIGHT and guard.mind != Person.Mind.FIGHT, "then the judgement is over")
	_reset(fx, crowd)
	_done(made)
