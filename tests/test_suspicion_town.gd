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
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
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
	_stand(crowd.citizens[0], AT + Vector2(3.0, 0.0))
	_stand(crowd.citizens[1], AT + Vector2(-3.0, 0.0))
	_stand(crowd.citizens[2], AT + Vector2(0.0, 3.0))
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
