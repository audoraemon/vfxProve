extends RefCounted
## v0.05 Bell Tower: at the first Local Emergency the bellkeeper goes to the tower, climbs it and rings the bell --
## the alarm jumps and the whole town learns of it; a frightened bellkeeper retries later, a dead one silences it.


static func _crowd() -> Array:
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
	return [crowd, env, world, field]


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var bell := crowd.bell
	t.check(bell.tower != null and bell.tower.art_tag == &"bell_tower" and bell.keeper != null
		and bell.keeper.profile.role == CitizenProfile.Role.BELLKEEPER and bell.state == BellNetwork.State.IDLE,
		"the Bell Tower stands, with its bellkeeper")
	t.check(not crowd._grid.path(TownLayout.MARKET_SQUARE.get_center(), bell.foot).is_empty(),
		"its foot can be reached from the market")

	# The first Local Emergency sends the bellkeeper; at the foot it climbs, and at the top it rings.
	crowd.alarms.stage = AlarmManager.Stage.CONCERN
	crowd._on_stage(AlarmManager.Stage.LOCAL_EMERGENCY, "test")
	t.check(bell.state == BellNetwork.State.CALLED and bell.keeper.mind == Person.Mind.DUTY, "Local Emergency calls the bellkeeper")
	_arrive(bell.keeper)
	bell.step(0.1)
	t.check(bell.state == BellNetwork.State.CLIMBING, "at the tower's foot it climbs")
	bell.step(bell.climb * 0.5)
	t.check(bell.state == BellNetwork.State.CLIMBING and not crowd.alarms.bell_rung, "which takes a while")
	var alarm_before := crowd.alarm
	bell.step(bell.climb)
	var aware := true
	for p in crowd.citizens:
		aware = aware and p.awareness >= Person.Awareness.EMERGENCY
	t.check(bell.state == BellNetwork.State.RUNG and crowd.alarms.bell_rung and aware
		and is_equal_approx(crowd.alarm - alarm_before, BellNetwork.RING_ALARM),
		"at the top it rings: +%d alarm, and everyone knows" % roundi(BellNetwork.RING_ALARM))
	t.check(crowd.alarms.stage >= AlarmManager.Stage.CITY_EMERGENCY or crowd.alarm < AlarmManager.CITY_ALARM_BELL,
		"after the bell, City Emergency comes at %d" % roundi(AlarmManager.CITY_ALARM_BELL))
	crowd.clear()
	(made[2] as Node).free()

	# Frightened mid-climb: it drops the climb and tries again later.
	made = _crowd()
	crowd = made[0]
	bell = crowd.bell
	bell.call_keeper()
	_arrive(bell.keeper)
	bell.step(0.1)
	bell.step(1.0)
	bell.keeper.panic(bell.keeper.ground_pos + Vector2(1, 0), 1.0, &"heaven")
	if bell.keeper.mind == Person.Mind.SHELTER:
		bell.keeper.leave_shelter(false)
		bell.keeper.mind = Person.Mind.PANIC
	bell.step(0.1)
	t.check(bell.state == BellNetwork.State.WAITING and bell.progress == 0.0, "a frightened bellkeeper drops the climb")
	bell.keeper.mind = Person.Mind.CALM
	bell.step(BellNetwork.RETRY + 0.1)
	t.check(bell.state == BellNetwork.State.CALLED, "and tries again later")

	# Killed: silenced for good.
	var silenced := []
	bell.silenced.connect(func(why: String) -> void: silenced.append(why))
	(made[3] as EnemyField).kill(bell.keeper, &"test")
	bell.step(0.1)
	t.check(bell.state == BellNetwork.State.SILENCED and silenced.size() == 1 and not crowd.alarms.bell_rung,
		"a dead bellkeeper silences the bell (%s)" % [silenced])
	crowd.clear()
	(made[2] as Node).free()

	# Held for a relay (v0.08, The Warning): a dead keeper neither silences the bell nor calls an escort; the bell waits
	# for whoever the mission sends, who climbs ESCORT_CLIMB slower.
	made = _crowd()
	crowd = made[0]
	bell = crowd.bell
	bell.hold_on_death = true
	silenced.clear()
	var replaced := []
	bell.silenced.connect(func(why: String) -> void: silenced.append(why))
	bell.keeper_replaced.connect(func() -> void: replaced.append(true))
	bell.call_keeper()
	var dead_keeper := bell.keeper
	(made[3] as EnemyField).kill(dead_keeper, &"test")
	for k in 50:
		bell.step(0.1)
	t.check(bell.state == BellNetwork.State.CALLED and silenced.is_empty() and replaced.is_empty()
		and bell.keeper == dead_keeper, "held, a dead keeper leaves the bell waiting: no silence, no escort")
	var climb := bell.climb
	var relay: Person = null
	for p in crowd.citizens:
		if p.is_alive() and p.profile != null and p.profile.role != CitizenProfile.Role.BELLKEEPER:
			relay = p
			break
	var hand_before := Mission.bell_hand(bell)
	relay.profile.role = CitizenProfile.Role.WATCHMAN
	bell.replace_keeper(relay)
	t.check(bell.keeper == relay and is_equal_approx(bell.climb, climb * BellNetwork.ESCORT_CLIMB)
		and not bell.keeper_is_soldier and replaced.size() == 1 and relay.mind == Person.Mind.DUTY,
		"a citizen sent in its place takes the rope, climbing x%.1f (%.1f s)" % [BellNetwork.ESCORT_CLIMB, bell.climb])
	var hand_watch := Mission.bell_hand(bell)
	bell.replace_keeper(crowd.soldiers[0])
	t.check(is_equal_approx(bell.climb, climb * BellNetwork.ESCORT_CLIMB) and bell.keeper_is_soldier and replaced.size() == 2,
		"a second stand-in is no slower still; a soldier is known as one")
	t.check([hand_before, hand_watch, Mission.bell_hand(bell)] == ["THE BELLKEEPER", "THE WATCHMAN", "A SOLDIER"],
		"the bell's banners name who holds the rope (%s, %s, %s)" % [hand_before, hand_watch, Mission.bell_hand(bell)])
	crowd.clear()
	(made[2] as Node).free()

	# A dead keeper before the call, held: the call waits rather than silencing the bell.
	made = _crowd()
	crowd = made[0]
	bell = crowd.bell
	bell.hold_on_death = true
	silenced.clear()
	bell.silenced.connect(func(why: String) -> void: silenced.append(why))
	(made[3] as EnemyField).kill(bell.keeper, &"test")
	bell.call_keeper()
	bell.step(0.1)
	t.check(bell.state == BellNetwork.State.CALLED and silenced.is_empty(), "held, a call to a dead keeper waits too")
	crowd.clear()
	(made[2] as Node).free()
