extends RefCounted
## Town Suspicion in the crowd: a witnessed cast is one sign; the town learns it knows by the bell, the Citadel's wound and City
## Emergency; clear() forgets it all; the new code draws nothing from the crowd's random stream.

const DT := 0.1
const AT := Vector2(0.8, 2.0)


static func run(t) -> void:
	_signs(t)
	_sight(t)
	_once_per_cast(t)
	_ways_to_know(t)
	_deterministic(t)
	_keeper(t)
	_excuse_rules(t)
	_thought(t)


static func _world() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	for p in crowd.citizens + crowd.soldiers:
		p.inside = true  # nobody sees anything until a test stands someone in the open
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / DT):
		crowd.advance(DT)


## A person standing in the open at `at`, calm.
static func _stand(p: Person, at: Vector2) -> Person:
	p.inside = false
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	return p


## Casts `key` at AT and lets it land; returns the sign_seen records [witness, look, before, after].
static func _cast(crowd: Crowd, key: String) -> Array:
	var seen := []
	var fn := func(w: Person, look: StringName, before: StringName, after: StringName) -> void: seen.append([w, look, before, after])
	crowd.sign_seen.connect(fn)
	crowd.on_cast(AT, Vector2.ZERO, 0.0, key)
	_run(crowd, PowerBook.impact(key) + 0.2)
	crowd.sign_seen.disconnect(fn)
	return seen


## A fresh world with one citizen standing `d` units from AT; the cast of `key` is made. Returns the crowd's suspicion value.
static func _value_after(key: String, d: float, scale := 1.0) -> float:
	var s := _world()
	var crowd: Crowd = s.crowd
	crowd.sight_scale = scale
	_stand(crowd.citizens[0], AT + Vector2(d, 0.0))
	_cast(crowd, key)
	var v := crowd.suspicion.value
	_done(s)
	return v


static func _signs(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var c := _stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	var seen := _cast(crowd, "smite")
	t.near(crowd.suspicion.value, 20.0, 0.01, "a Smite seen 3 units away adds 20")
	t.check(seen.size() == 1 and seen[0][0] == c and seen[0][1] == &"lightning" and seen[0][2] == &"calm" and seen[0][3] == &"calm",
		"sign_seen once, with the witness, calm before and after (%d)" % seen.size())
	_done(s)

	t.near(_value_after("smite", 6.0), 0.0, 0.01, "nobody within 5 units: no sign")
	t.near(_value_after("smite", 0.0), 0.0, 0.01, "a lone man on the point is the victim, no witness")

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT)
	_stand(crowd.citizens[1], AT + Vector2(3.0, 0.0))
	_cast(crowd, "smite")
	t.near(crowd.suspicion.value, 20.0, 0.01, "a second man 3 units away saw the strike on the first")
	_done(s)

	s = _world()
	crowd = s.crowd
	var in_house := _stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	in_house.inside = true
	_cast(crowd, "smite")
	t.near(crowd.suspicion.value, 0.0, 0.01, "the only person in reach is inside a building: no sign")
	_done(s)

	s = _world()
	crowd = s.crowd
	var sleeper := _stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	sleeper.sleep(60.0)
	_cast(crowd, "smite")
	t.near(crowd.suspicion.value, 0.0, 0.01, "the only person in reach is asleep: no sign")
	_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.soldiers[0], AT + Vector2(3.0, 0.0))
	_cast(crowd, "smite")
	t.near(crowd.suspicion.value, 20.0, 0.01, "a soldier at 3 units is a witness")
	_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	crowd.hush(30.0)
	_cast(crowd, "smite")
	t.near(crowd.suspicion.value, 0.0, 0.01, "a hushed town sees nothing")
	_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	crowd.veil(AT, 10.0, 30.0)
	_cast(crowd, "smite")
	t.near(crowd.suspicion.value, 0.0, 0.01, "a cast under the Unseen Hour is no sign")
	_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(5.0, 0.0))
	_cast(crowd, "dragon")
	t.check(crowd.suspicion.known and crowd.suspicion.reason == "an unnatural power", "Dragonfire witnessed: the town knows")
	_done(s)

	s = _world()
	crowd = s.crowd
	_cast(crowd, "dragon")
	t.check(not crowd.suspicion.known, "Dragonfire unwitnessed: it does not")
	_done(s)

	t.near(_value_after("ember", 4.0), 20.0, 0.01, "Ember seen at 4 units adds 20")
	t.near(_value_after("ember", 6.0), 0.0, 0.01, "Ember seen from 6 units is not seen")
	t.near(_value_after("whisper", 2.0), 0.0, 0.01, "a quiet power with no look proves nothing")


static func _sight(t) -> void:
	t.near(_value_after("smite", 4.0, 0.6), 0.0, 0.01, "at night (sight 0.6) 4 units is too far")
	t.near(_value_after("smite", 2.5, 0.6), 20.0, 0.01, "at night (sight 0.6) 2.5 units is seen")


static func _once_per_cast(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(5.0, 0.0))
	_stand(crowd.citizens[1], AT + Vector2(-5.0, 0.0))
	_stand(crowd.citizens[2], AT + Vector2(0.0, 5.0))
	var seen := []
	crowd.sign_seen.connect(func(w: Person, look: StringName, _b: StringName, _a: StringName) -> void: seen.append([w, look]))
	crowd.on_cast(AT, Vector2(1.0, 0.0), float(Targeting.AREAS.tsunami.length), "tsunami")
	_run(crowd, PowerBook.impact("tsunami") + 0.2)
	t.check(seen.size() == 1, "a Tsunami along a lane past three witnesses is one sign (%d)" % seen.size())
	t.near(crowd.suspicion.value, 30.0, 0.01, "worth the flood's 30")
	_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	crowd.fright(AT, 2.0, 0.6, 3.0, 8.0, 12.0, &"lightning")
	crowd.fright(AT, 2.0, 0.6, 3.0, 8.0, 12.0, &"lightning")
	t.near(crowd.suspicion.value, 0.0, 0.01, "Crowd.fright() of kind lightning (Wrath of the Sky's bolts) is no sign")
	_done(s)

	t.near(_value_after("smite", 3.0), 20.0, 0.01, "a cast is one sign; a follow-up click (Rules.recast) never reaches on_cast()")


static func _ways_to_know(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	crowd.ring_bell(Vector2.ZERO)
	t.check(crowd.suspicion.known and crowd.suspicion.reason == "the bell rings", "the bell rings: the town knows")
	crowd.clear()
	t.check(not crowd.suspicion.known and crowd.suspicion.value == 0.0 and crowd.suspicion.reason == "", "clear(): a calm town again")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd._on_citadel_health(0.9)
	t.check(crowd.suspicion.known and crowd.suspicion.reason == "the Citadel is struck", "a hit on the Citadel: the town knows")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	t.check(crowd.alarms.stage >= AlarmManager.Stage.CITY_EMERGENCY and crowd.suspicion.known, "City Emergency: the town knows")
	_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	crowd.suspicion.know("test")
	var seen := _cast(crowd, "smite")
	t.check(seen.size() == 1 and seen[0][2] == &"known" and seen[0][3] == &"known", "a witnessed cast still reports once the town knows")
	t.near(crowd.suspicion.value, 100.0, 0.01, "and adds nothing")
	_done(s)


static func _deterministic(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	var pts: Array[Vector2] = [AT]
	var before := crowd._rng.state
	crowd._sign(pts, 5.0, &"lightning")
	t.check(crowd.suspicion.value > 0.0 and crowd._rng.state == before, "a witnessed sign draws nothing from the crowd's random stream")
	_done(s)

	var states := []
	for i in 2:
		s = _world()
		crowd = s.crowd
		_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
		_cast(crowd, "smite")
		states.append([crowd._rng.state, crowd.suspicion.value])
		_done(s)
	t.check(states[0] == states[1], "the same cast twice gives the same stream and value")


## Where a district's incidents happen: the centre of district `i`.
static func _district_at(i: int) -> Vector2:
	return (City.current().districts()[i] as Rect2).get_center()


## `n` deaths of `kind` in the district at `at`, each a different citizen from index `from` on.
static func _deaths(s: Dictionary, kind: StringName, n: int, at: Vector2, from := 0) -> void:
	var crowd: Crowd = s.crowd
	for i in n:
		var p := crowd.citizens[from + i]
		p.ground_pos = at
		(s.field as EnemyField).kill(p, kind)


static func _keeper(t) -> void:
	var at := _district_at(0)
	var s := _world()
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	crowd.suspicion.excuse(&"lightning")
	_deaths(s, &"lightning", 4, at)
	t.check(crowd.alarms.stage == AlarmManager.Stage.LOCAL_EMERGENCY and crowd.sweep.swept(AlarmManager.district_of(at)),
		"four lightning deaths in a district: Local Emergency, the district's sweep asked for (soldier duties: the investigators' heir)")
	t.check(bell.state == BellNetwork.State.IDLE and not crowd.keeper_due(), "but the bellkeeper is not called")
	crowd.suspicion.know("x")
	t.check(bell.state != BellNetwork.State.IDLE and crowd.keeper_due(), "once the town knows, he is")
	bell.state = BellNetwork.State.IDLE
	_deaths(s, &"plague", 4, _district_at(1), 4)
	crowd.suspicion.know("y")
	t.check(bell.state == BellNetwork.State.IDLE, "called once: a second district's emergency and a second know() do not call again")
	_done(s)

	s = _world()
	crowd = s.crowd
	_deaths(s, &"plague", 3, at)
	t.check(crowd.bell.state == BellNetwork.State.IDLE, "three plague deaths: not yet")
	_deaths(s, &"plague", 1, at, 3)
	t.check(crowd.bell.state != BellNetwork.State.IDLE and not crowd.suspicion.known, "four plague deaths, no sign ever: the keeper is called, as today")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.suspicion.excuse(&"lightning")
	_deaths(s, &"lightning", 3, at)
	_deaths(s, &"plague", 1, at, 3)
	t.check(crowd.bell.state == BellNetwork.State.IDLE and not crowd.keeper_due(), "three lightning and one plague: not called")
	_deaths(s, &"plague", 3, at, 4)
	t.check(crowd.bell.state != BellNetwork.State.IDLE, "three more plague deaths (four unexplained): called")
	_done(s)

	for mode in ["excused", "known", "no natural cast"]:
		var knows: bool = mode != "excused"
		s = _world()
		crowd = s.crowd
		if mode == "known":
			crowd.suspicion.know("test")
		elif mode == "excused":
			crowd.on_cast(AT, Vector2.ZERO, 0.0, "tornado")
			_run(crowd, 5.0)
		var in_district: Array[Structure] = []
		var by_district := {}
		for st: Structure in (s.env as EnvironmentField).structures():
			if st.role == &"citadel" or st.role == &"thorns" or st.role == &"windfall" or st.role == LawRubble.ROLE:
				continue
			var d := AlarmManager.district_of(st.center())
			by_district[d] = by_district.get(d, []) + [st]
		for d in by_district:
			if by_district[d].size() >= AlarmManager.LOCAL_EVENTS:
				in_district.assign(by_district[d].slice(0, AlarmManager.LOCAL_EVENTS))
				break
		for st in in_district:
			crowd._on_structure_destroyed(st, &"test")
		crowd.advance(0.6)  # the stage follows the incidents on the alarm's half-second tick
		t.check(in_district.size() == AlarmManager.LOCAL_EVENTS and (crowd.bell.state != BellNetwork.State.IDLE) == knows,
			"four collapses in a district: called unless a Tornado cast 5 s ago excuses them (%s)" % [mode])
		_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[8], at + Vector2(2.0, 0.0))
	_deaths(s, &"doom", 4, at)
	crowd._settle_doom()
	t.check(crowd.alarms.stage >= AlarmManager.Stage.LOCAL_EMERGENCY and crowd.bell.state != BellNetwork.State.IDLE,
		"four witnessed dooms in a district: called, as today")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	t.check(crowd.alarms.stage == AlarmManager.Stage.CITY_EMERGENCY and crowd.suspicion.known and crowd.bell.state != BellNetwork.State.IDLE,
		"City Emergency with no district emergency: the town knows, the keeper is called")
	_done(s)

	# The Bell Lies: the town still knows and the bell's own retry still sends him.
	s = _world()
	crowd = s.crowd
	bell = crowd.bell
	crowd.suspicion.know("test")
	crowd.alarms.stage = AlarmManager.Stage.LOCAL_EMERGENCY
	crowd._send_keeper()
	_arrive(bell.keeper)
	bell.state = BellNetwork.State.RUNG
	crowd.alarms.bell_rung = true
	crowd.unring_bell()
	t.check(bell.state == BellNetwork.State.WAITING and crowd.suspicion.known, "the Bell Lies: the bell waits to ring again, the town still knows")
	bell.keeper.mind = Person.Mind.CALM
	bell.step(BellNetwork.RETRY + 0.1)
	t.check(bell.state == BellNetwork.State.CALLED, "and the keeper is sent again by the bell's own retry")
	_done(s)

	# No bell, a dead keeper, a held keeper: no error, no second call.
	s = _world()
	crowd = s.crowd
	crowd.bell = null
	_deaths(s, &"plague", 4, at)
	crowd.suspicion.know("test")
	t.check(not crowd.keeper_due() and crowd.alarms.stage >= AlarmManager.Stage.LOCAL_EMERGENCY, "an Unprepared town (no bell): keeper_due() is false, nothing breaks")
	crowd.bell = BellNetwork.new()
	_done(s)

	s = _world()
	crowd = s.crowd
	bell = crowd.bell
	(s.field as EnemyField).kill(bell.keeper, &"test")
	_deaths(s, &"plague", 4, at, 1)
	t.check(bell.state == BellNetwork.State.SILENCED, "a dead keeper silences the bell, as today")
	_done(s)

	s = _world()
	crowd = s.crowd
	bell = crowd.bell
	bell.hold_on_death = true
	bell.keeper_held = func() -> bool: return true
	(s.field as EnemyField).kill(bell.keeper, &"test")
	_deaths(s, &"plague", 4, at, 1)
	t.check(bell.state == BellNetwork.State.CALLED and bell.keeper_held.is_valid(), "a held, dead keeper: called and waiting, as today")
	_done(s)

	# The crowd outlives an act (Mission.next_act() drops the act's hooks and held dangers, and raises the profile); an R restart clears.
	s = _world()
	crowd = s.crowd
	crowd.alarms.stage = AlarmManager.Stage.LOCAL_EMERGENCY
	crowd.suspicion.excuse(&"fire")
	crowd.suspicion.know("act one")
	crowd.clear_mission_hooks()
	crowd.drop_held()
	crowd.raise_profile(ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT))
	t.check(crowd.suspicion.known and crowd._keeper_sent, "a new act keeps what the town knows and the keeper's call")
	crowd.clear()
	t.check(not crowd.suspicion.known and not crowd._keeper_sent, "an R restart forgets both")
	_done(s)


## The excuse rule: only a natural-looking cast excuses a kind of death, for Suspicion.EXCUSE_SECONDS from the cast; and the town's
## one call is spent once the bell has left idle.
static func _excuse_rules(t) -> void:
	var at := _district_at(0)
	var s := _world()
	var crowd: Crowd = s.crowd
	_deaths(s, &"lightning", 3, at)
	t.check(crowd.bell.state == BellNetwork.State.IDLE, "three lightning deaths, no cast: not yet")
	_deaths(s, &"lightning", 1, at, 3)
	t.check(crowd.bell.state != BellNetwork.State.IDLE and not crowd.suspicion.known,
		"four lightning deaths and no Smite ever cast (Heaven Splitter): the keeper is sent at the fourth, as on the base")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.on_cast(AT, Vector2.ZERO, 0.0, "smite")
	_run(crowd, 10.0)
	_deaths(s, &"lightning", 4, at)
	t.check(crowd.alarms.stage == AlarmManager.Stage.LOCAL_EMERGENCY and crowd.bell.state == BellNetwork.State.IDLE,
		"the same after a Smite cast 10 s earlier (seen or not): explained, no keeper")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.on_cast(AT, Vector2.ZERO, 0.0, "smite")
	_run(crowd, 100.0)
	_deaths(s, &"lightning", 4, at)
	t.check(crowd.bell.state != BellNetwork.State.IDLE, "after a Smite cast 100 s earlier the excuse has run out: the keeper is sent")
	_done(s)

	s = _world()
	crowd = s.crowd
	_deaths(s, &"fire", 4, at)
	t.check(crowd.bell.state != BellNetwork.State.IDLE, "four fire deaths and no Ember cast: unexplained, the keeper is sent")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.on_cast(AT, Vector2.ZERO, 0.0, "ember")
	_run(crowd, 1.0)
	_deaths(s, &"fire", 4, at)
	t.check(crowd.bell.state == BellNetwork.State.IDLE, "four fire deaths 1 s after an Ember (cast in a quiet town): explained")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.on_cast(AT, Vector2.ZERO, 0.0, "tempest")
	t.check(crowd.suspicion.explains(&"lightning") and crowd.suspicion.explains(&"wind") and not crowd.suspicion.explains(&"fire"),
		"Wrath of the Sky excuses lightning and wind, not fire")
	_done(s)

	s = _world()
	crowd = s.crowd
	crowd.veil(AT, 10.0, 30.0)
	crowd.on_cast(AT, Vector2.ZERO, 0.0, "smite")
	t.check(not crowd.suspicion.explains(&"lightning"), "a cast under the Unseen Hour excuses nothing")
	_done(s)

	# The town's one call is spent once the bell has left idle by any route: a script's call, a restore, then the town comes to know.
	s = _world()
	crowd = s.crowd
	crowd.suspicion.excuse(&"lightning")
	_deaths(s, &"lightning", 4, at)
	t.check(crowd.alarms.stage == AlarmManager.Stage.LOCAL_EMERGENCY and crowd.bell.state == BellNetwork.State.IDLE, "excused deaths: Local Emergency, no keeper")
	crowd.bell.call_keeper()
	crowd.advance(0.1)
	crowd.bell.restore(crowd.bell.keeper)
	crowd.suspicion.know("x")
	t.check(crowd.bell.state == BellNetwork.State.IDLE, "a script called him and restored the bell: the town's one call is spent, no second")
	_done(s)


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## A fresh world with one citizen standing `d` units from AT, cast `key`; returns [crowd, world dict, witness].
static func _thought_world(key: String, d: float) -> Array:
	var s := _world()
	var crowd: Crowd = s.crowd
	var c := _stand(crowd.citizens[0], AT + Vector2(d, 0.0))
	_cast(crowd, key)
	return [crowd, s, c]


## The witness's thought tag: what the sign said, in the gauge's colours, for 2.5 s; one at a time; none for an unseen cast.
static func _thought(t) -> void:
	var words := {"smite": ["JUST A STORM", 3.0], "tornado": ["JUST A STORM", 5.0], "tempest": ["JUST A STORM", 5.0], "ember": ["FIRE!", 3.0],
		"shatter": ["EARTHQUAKE!", 5.0], "tsunami": ["THE RIVER!", 5.0], "breath": ["BAD AIR", 5.0]}
	for key: String in words:
		var r := _thought_world(key, float(words[key][1]))
		var crowd: Crowd = r[0]
		var tags := crowd.thought_tags()
		t.check(tags.size() == 1 and tags[0].label == String(words[key][0]) and tags[0].who == r[2],
			"%s, seen calm: the witness says %s (%s)" % [key, words[key][0], str(tags.map(func(x: MapTag) -> String: return x.label))])
		if tags.size() == 1:
			t.check(tags[0].color == UiTheme.COL_DIM, "%s: a calm town's thought is the dim colour" % key)
		_done(r[1])

	var r := _thought_world("smite", 3.0)
	var crowd: Crowd = r[0]
	t.check(crowd.thought_tags().size() == 1, "the tag is up at once")
	_run(crowd, 2.0)
	t.check(crowd.thought_tags().size() == 1, "and still up about 2.2 s after the sign (the cast ran 0.2 s past it)")
	_run(crowd, 0.4)
	t.check(crowd.thought_tags().is_empty(), "gone after 2.5 s")
	_done(r[1])

	var s := _world()
	crowd = s.crowd
	var first := _stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	_cast(crowd, "smite")
	t.check(crowd.thought_tags()[0].who == first and crowd.thought_tags()[0].label == "JUST A STORM", "the first sign: JUST A STORM, calm at 20")
	_cast(crowd, "smite")
	var tags := crowd.thought_tags()
	t.check(tags.size() == 1 and tags[0].label == "AGAIN?" and tags[0].color == UiTheme.COL_GOLD,
		"a second sign replaces the first: AGAIN? in gold (value %.0f)" % crowd.suspicion.value)
	_done(s)

	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	_cast(crowd, "disorder")
	t.check(crowd.thought_tags().is_empty(), "a cast with no look has no thought")
	_cast(crowd, "heaven")
	tags = crowd.thought_tags()
	t.check(tags.size() == 1 and tags[0].label == "THIS IS NO ACCIDENT" and tags[0].color == UiTheme.COL_BAD,
		"an unnatural sign: THIS IS NO ACCIDENT in red (%s)" % str(tags.map(func(x: MapTag) -> String: return x.label)))
	_done(s)

	s = _world()
	crowd = s.crowd
	_cast(crowd, "smite")
	t.check(crowd.thought_tags().is_empty(), "an unwitnessed cast: no tag")
	_done(s)

	# The witness dies: the tag goes with him.
	s = _world()
	crowd = s.crowd
	var seer := _stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	_cast(crowd, "smite")
	(s.field as EnemyField).kill(seer, &"test")
	t.check(not seer.is_alive() and crowd.thought_tags().is_empty(), "the witness dies: his tag is gone")
	_done(s)

	# Uneasy for the first time: the witness cries out through the voice budget; the tag alone changes nothing else.
	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	_cast(crowd, "smite")
	var voices := crowd.voices_played
	_cast(crowd, "smite")
	t.check(crowd.suspicion.state() == &"uneasy" and crowd.voices_played > voices, "calm to uneasy: the witness shouts (voices %d -> %d)" % [voices, crowd.voices_played])
	voices = crowd.voices_played
	_cast(crowd, "smite")
	t.check(crowd.voices_played == voices, "uneasy to uneasy: no shout")
	_done(s)

	# The thought draws nothing from the random stream and moves no simulation state but the voice budget.
	s = _world()
	crowd = s.crowd
	var w := _stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	var rng_before := crowd._rng.state
	crowd.sign_seen.emit(w, &"lightning", &"calm", &"uneasy")
	t.check(crowd._rng.state == rng_before, "the thought spends no random draw")
	_done(s)

	# A town that already knows has nothing to say: no tag for a sign (the signal is still emitted).
	s = _world()
	crowd = s.crowd
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	crowd.suspicion.know("test")
	var seen := _cast(crowd, "smite")
	t.check(seen.size() == 1 and crowd.thought_tags().is_empty(), "the town knows: the sign is seen, no thought tag (%d)" % crowd.thought_tags().size())
	_done(s)
