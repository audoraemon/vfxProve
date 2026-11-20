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
	_deaths(s, &"lightning", 4, at)
	t.check(crowd.alarms.stage == AlarmManager.Stage.LOCAL_EMERGENCY and crowd._investigating.size() == Crowd.INVESTIGATORS,
		"four lightning deaths in a district: Local Emergency, the two investigators sent")
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
	_deaths(s, &"lightning", 3, at)
	_deaths(s, &"plague", 1, at, 3)
	t.check(crowd.bell.state == BellNetwork.State.IDLE and not crowd.keeper_due(), "three lightning and one plague: not called")
	_deaths(s, &"plague", 3, at, 4)
	t.check(crowd.bell.state != BellNetwork.State.IDLE, "three more plague deaths (four unexplained): called")
	_done(s)

	for knows in [false, true]:
		s = _world()
		crowd = s.crowd
		if knows:
			crowd.suspicion.know("test")
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
			"four collapses in a district: the keeper is called only if the town knows (%s)" % [knows])
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
	crowd.suspicion.know("act one")
	crowd.clear_mission_hooks()
	crowd.drop_held()
	crowd.raise_profile(ResponseProfile.for_tier(ResponseProfile.Tier.GOD_RESISTANT))
	t.check(crowd.suspicion.known and crowd._keeper_sent, "a new act keeps what the town knows and the keeper's call")
	crowd.clear()
	t.check(not crowd.suspicion.known and not crowd._keeper_sent, "an R restart forgets both")
	_done(s)


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
