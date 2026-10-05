extends RefCounted
## v0.08 The Warning (WarningDirector): a star falls over the Main Gate at 0:02, the watchman stares at it for 4 s,
## then runs to the bellkeeper -- wherever the keeper is -- to tell them, and the bell is called; with the keeper dead
## he climbs the tower himself. Killing the messenger unseen wins, a seen death passes the warning to the witness, the
## bell ringing loses, and the omen fading at 0:00 wins. Fright, Discord and Mind Whisper interrupt the errand until
## the messenger is back on its feet.

const DT := 0.05


## An Unaware town playing The Warning, with no effects (ctx null: the star is skipped, the banners still come).
static func _setup() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var def := MissionBook.warning()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as WarningDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## `seconds` of the mission, in the game's order: the crowd, then the rules (which step the director).
static func _run(s: Dictionary, seconds: float) -> void:
	var n := roundi(seconds / DT)
	for i in n:
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


static func _arrive(p: Person, at := Vector2.INF) -> void:
	p.ground_pos = p.goal() if at == Vector2.INF else at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## Everyone but `keep` standing within `reach` of `at` is moved well away, so nobody but `keep` can witness there.
static func _clear_round(s: Dictionary, at: Vector2, reach: float, keep: Array) -> void:
	var crowd: Crowd = s.crowd
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + (p.ground_pos - at).normalized() * (reach + 6.0) if p.ground_pos != at \
					else at + Vector2(reach + 6.0, 0.0)


static func run(t) -> void:
	_route(t)
	_keeper_dead(t)
	_unseen_kill(t)
	_relay(t)
	_endings(t)
	_interruptions(t)
	_bonus(t)
	_teardown_releases_the_bell(t)


## The watchman, the omen, the run, the re-aim and the delivery.
static func _route(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var d: WarningDirector = s.d
	var banners: Array[String] = s.banners
	var w := d.watchman
	var keeper := crowd.bell.keeper
	t.check(w != null and w.profile.role == CitizenProfile.Role.WATCHMAN and d.messenger == w,
		"a watchman is appointed, and carries the warning")
	t.check(w != null and w.ground_pos.distance_to(WarningDirector.GATE_SPOT) <= 1.5,
		"he stands at the Main Gate (%.2f from it)" % w.ground_pos.distance_to(WarningDirector.GATE_SPOT))
	t.check(w != keeper and keeper != null and crowd.bell.hold_on_death, "he is not the bellkeeper, and the bell holds")
	t.check(d.marker() == w.ground_pos, "the marker is on him")

	_run(s, 1.9)
	t.check(banners.is_empty() and d.phase == WarningDirector.Phase.OMEN, "nothing before 0:02 (%s)" % [banners])
	_run(s, 0.2)
	t.check(banners.has("A STAR FALLS OVER THE MAIN GATE") and banners.has("STOP THE WARNING"),
		"at 0:02 the star falls (%s)" % [banners])
	t.check(w.mind == Person.Mind.OBSERVE, "and the watchman stares at it")
	_run(s, 3.6)
	t.check(w.mind == Person.Mind.OBSERVE and d.phase == WarningDirector.Phase.STARE, "still staring at 5.7 s")
	_run(s, 0.4)
	t.check(w.mind == Person.Mind.DUTY and d.phase == WarningDirector.Phase.RUN, "at 6 s he runs (%s)" %
		Person.Mind.keys()[w.mind])
	t.check(w.goal().distance_to(keeper.ground_pos) <= 0.5 and w.walk_speed >= Person.PANIC_SPEED * w.pace - 0.001,
		"to the keeper, at the run")

	# The keeper moves: the errand follows.
	keeper.ground_pos = crowd._grid.nearest_walkable(keeper.ground_pos + Vector2(3.0, 0.0))
	_run(s, 0.6)
	t.check(w.goal().distance_to(keeper.ground_pos) <= 0.01, "re-aimed at the keeper where they are now")

	# Within reach: the keeper is told.
	_arrive(w, keeper.ground_pos + Vector2(0.5, 0.0))
	_run(s, 0.6)
	t.check(crowd.bell.state == BellNetwork.State.CALLED and keeper.mind == Person.Mind.DUTY,
		"told, the keeper is called to the tower (%s)" % BellNetwork.State.keys()[crowd.bell.state])
	t.check(d.messenger == keeper and d.phase == WarningDirector.Phase.DELIVERED and d.marker() == keeper.ground_pos,
		"and carries the warning now")
	t.check(w.mind == Person.Mind.RECOVER or w.mind == Person.Mind.REGROUP, "the watchman is off duty (%s)" %
		Person.Mind.keys()[w.mind])
	t.check(not (s.rules as Rules).finished, "the mission goes on")
	_done(s)


## The keeper dead before the warning reaches them: the watchman climbs, slower.
static func _keeper_dead(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var d: WarningDirector = s.d
	var bell := crowd.bell
	var keeper := bell.keeper
	var climb := bell.climb
	_clear_round(s, keeper.ground_pos, Crowd.DOOM_WITNESS + 1.0, [keeper])
	(s.field as EnemyField).kill(keeper, &"doom", keeper.ground_pos)
	_run(s, 6.2)
	var w := d.watchman
	t.check(d.phase == WarningDirector.Phase.RUN and not d.warning_dead, "the keeper's death is not the warning's")
	t.check(w.mind == Person.Mind.DUTY and w.goal().distance_to(bell.foot) <= 0.01, "the watchman runs to the tower's foot")
	_arrive(w)
	_run(s, 0.6)
	t.check(bell.keeper == w and (bell.state == BellNetwork.State.CALLED or bell.state == BellNetwork.State.CLIMBING),
		"and takes the rope himself (%s)" % BellNetwork.State.keys()[bell.state])
	t.check(is_equal_approx(bell.climb, climb * BellNetwork.ESCORT_CLIMB) and not bell.keeper_is_soldier,
		"climbing x%.1f (%.1f s)" % [BellNetwork.ESCORT_CLIMB, bell.climb])
	t.check(d.messenger == w and d.phase == WarningDirector.Phase.DELIVERED, "still carrying the warning")
	_done(s)


## The messenger killed with nobody near: the warning dies and the mission is won.
static func _unseen_kill(t) -> void:
	var s := _setup()
	var d: WarningDirector = s.d
	var rules: Rules = s.rules
	_run(s, 6.2)
	var w := d.watchman
	t.check(d.phase == WarningDirector.Phase.RUN, "running")
	_clear_round(s, w.ground_pos, 3.0, [w])
	(s.field as EnemyField).kill(w, &"doom", w.ground_pos)
	_run(s, DT * 2.0)
	t.check(d.warning_dead and d.relays == 0 and d.phase == WarningDirector.Phase.OVER, "unseen, the warning dies")
	t.check(rules.finished and rules.won and rules.over_reason == "warning", "and the mission is won (%s)" % rules.over_reason)
	t.check(d.killed_by == "" and (d.report().solved_by as PackedStringArray).is_empty(),
		"no cast in a test: nothing is credited (%s)" % [d.report()])
	t.check(d.marker() == Vector2.INF, "and the marker is gone")
	_done(s)


## A seen death: the warning passes to the witness, who runs on. Before the omen, too -- the star still falls.
static func _relay(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var d: WarningDirector = s.d
	var banners: Array[String] = s.banners
	var w := d.watchman
	var witness: Person = null
	for p in crowd.citizens:
		if p != w and p != crowd.bell.keeper and p.profile != null and p.profile.role == CitizenProfile.Role.RESIDENT:
			witness = p
			break
	_clear_round(s, w.ground_pos, 3.0, [w])
	witness.ground_pos = w.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(w, &"doom", w.ground_pos)
	_run(s, DT * 2.0)
	t.check(d.messenger == witness and d.relays == 1 and not d.warning_dead, "the witness carries the warning on")
	t.check(banners.has("THE WARNING PASSES ON"), "THE WARNING PASSES ON (%s)" % [banners])
	t.check(witness.mind == Person.Mind.DUTY and witness.goal().distance_to(crowd.bell.keeper.ground_pos) <= 0.5,
		"running to the keeper (%s)" % Person.Mind.keys()[witness.mind])
	t.check(not (s.rules as Rules).finished, "the mission is not over")
	_run(s, 2.0)
	t.check(banners.has("A STAR FALLS OVER THE MAIN GATE") and witness.mind == Person.Mind.DUTY,
		"the star still falls at 0:02, and the witness runs on")
	_done(s)


## The bell rings: lost. The omen fades with the bell silent: won, credited to the Authorities that delayed it.
static func _endings(t) -> void:
	var s := _setup()
	var rules: Rules = s.rules
	(s.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	_run(s, DT)
	t.check(rules.finished and not rules.won and rules.over_reason == "bell", "the bell rings: lost (%s)" % rules.over_reason)
	_done(s)

	s = _setup()
	rules = s.rules
	var d: WarningDirector = s.d
	rules.cast_made.emit(0, "discord", d.messenger.ground_pos)
	rules.cast_made.emit(1, "wisp", d.messenger.ground_pos + Vector2(10.0, 0.0))
	t.check(d.delayed_by.has("disorder") and not d.delayed_by.has("dominion"),
		"a cast at the messenger delays the warning; one 10 away does not (%s)" % [d.delayed_by])
	rules.time_left = 0.01
	_run(s, 0.1)
	t.check(rules.finished and rules.won and rules.over_reason == "omen", "the omen fades: won (%s)" % rules.over_reason)
	t.check(d.report().solved_by == PackedStringArray(["DISORDER"]), "solved by DISORDER (%s)" % [d.report()])
	t.check(rules.result().get("solved_by") == PackedStringArray(["DISORDER"]), "and the results carry it")
	_done(s)


## Fright, Discord and Mind Whisper hold the errand until the messenger is back on its feet.
static func _interruptions(t) -> void:
	var s := _setup()
	var d: WarningDirector = s.d
	var grid: WalkGrid = s.grid
	_run(s, 6.2)
	var w := d.messenger
	t.check(w.mind == Person.Mind.DUTY, "on the errand")

	w.confuse(DiscordFx.DISCORD_TIME)
	_run(s, 1.0)
	t.check(w.mind == Person.Mind.CONFUSED, "Discord: no re-send while confused")
	w._come_to()
	w.mind = Person.Mind.RECOVER
	_run(s, 0.6)
	t.check(w.mind == Person.Mind.DUTY, "come to, he runs on (%s)" % Person.Mind.keys()[w.mind])

	w.whisper(grid.nearest_walkable(w.ground_pos + Vector2(-3.0, 0.0)), MindWhisperFx.LINGER)
	_run(s, 1.0)
	t.check(w.mind == Person.Mind.WHISPERED, "Mind Whisper: no re-send while whispered")
	w._wake()
	_run(s, 0.6)
	t.check(w.mind == Person.Mind.DUTY, "the whisper worn off, he runs on (%s)" % Person.Mind.keys()[w.mind])

	w.shelters = null  # a plain fright, not a run for cover
	w.panic(w.ground_pos + Vector2(0.5, 0.0))
	_run(s, 1.0)
	t.check(w.mind == Person.Mind.PANIC, "a fright: no re-send while frightened (%s)" % Person.Mind.keys()[w.mind])
	w._recover(5.0)
	_run(s, 0.6)
	t.check(w.mind == Person.Mind.DUTY and d.messenger == w, "recovering, he picks the errand up again")
	_done(s)


## The Unseen bonus: lost once the town reaches Local Emergency.
static func _bonus(t) -> void:
	var s := _setup()
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	var unseen := rules.bonuses[0]
	t.check(unseen is UnseenObjective and unseen.label == "Unseen", "the bonus is Unseen")
	t.check(unseen.check(rules) == Objective.Status.PENDING, "pending at the start")
	var at := TownLayout.MARKET_SQUARE.get_center()
	for i in AlarmManager.LOCAL_EVENTS:
		crowd.alarms.incident(at)
	crowd.alarms.update(crowd.alarm, 0, 0.0)
	t.check(crowd.alarms.stage >= AlarmManager.Stage.LOCAL_EMERGENCY and unseen.check(rules) == Objective.Status.FAILED,
		"failed at Local Emergency (%s)" % crowd.alarms.stage_name())
	_done(s)


## v0.09: the bell waits for a relay only while the warning lives; tearing the director down lets it fall silent
## with its keeper again.
static func _teardown_releases_the_bell(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	t.check(crowd.bell.hold_on_death, "the warning holds the bell while it lives")
	(s.d as WarningDirector).teardown()
	t.check(not crowd.bell.hold_on_death, "and lets it go when it is torn down")
	_done(s)
