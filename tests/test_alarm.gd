extends RefCounted
## v0.04's staged alarm: the stages rise in order and only rise; a district's emergency sends soldiers to look;
## City Emergency closes the market, sends some home and calls the bell-ringer; the bell lets the evacuation come
## sooner, and without the cathedral it comes only at the higher alarm.


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
	return [crowd, env, world]


static func run(t) -> void:
	# The stages alone.
	var a := AlarmManager.new()
	var seen: Array = []
	a.stage_changed.connect(func(s: AlarmManager.Stage, _r: String) -> void: seen.append(s))
	a.update(0.0, 0, 0.0)
	t.check(a.stage == AlarmManager.Stage.NORMAL, "a quiet town is Normal")
	a.update(0.0, 1, 1.0)
	t.check(a.stage == AlarmManager.Stage.CONCERN, "any danger: Concern")
	var g := Vector2(-10, -10)
	for k in AlarmManager.LOCAL_EVENTS - 1:
		a.incident(g)
	var first_emergency := a.incident(g)
	a.update(4.0, 0, 2.0)
	t.check(first_emergency and a.stage == AlarmManager.Stage.LOCAL_EMERGENCY, "incidents pile up in a district: Local Emergency")
	a.update(80.0, 0, 3.0)
	t.check(a.stage == AlarmManager.Stage.CITY_EMERGENCY, "alarm 80 without the bell stops at City Emergency")
	a.bell_rung = true
	a.update(80.0, 0, 4.0)
	t.check(a.stage == AlarmManager.Stage.CITY_EMERGENCY, "even with the bell, not before families have had time to regroup")
	a.update(80.0, 0, 3.0 + AlarmManager.REGROUP_SECONDS)
	t.check(a.stage == AlarmManager.Stage.EVACUATION, "then the bell lets 75 call the evacuation")
	a.update(0.0, 0, 30.0)
	t.check(a.stage == AlarmManager.Stage.EVACUATION, "stages never fall")
	t.check(seen == [1, 2, 3, 4], "each stage is announced in turn (%s)" % [seen])

	# A district's emergency sends two patrolling soldiers to look.
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var at := Vector2(-10.0, 3.0)
	crowd._investigate(at)
	t.check(crowd._investigating.size() == Crowd.INVESTIGATORS, "two soldiers go to look (%d)" % crowd._investigating.size())
	crowd._clock += Crowd.INVESTIGATE_SECONDS + 1.0
	crowd._return_investigators()
	t.check(crowd._investigating.is_empty(), "and go back to their posts after a while")

	# City Emergency: the soldiers rally, merchants go home, a clergy member heads for the bell.
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	t.check(crowd.alarms.stage == AlarmManager.Stage.CITY_EMERGENCY and crowd._rallied, "alarm 35: City Emergency, the soldiers rally")
	var merchants_home := true
	var regrouping := 0
	for p in crowd.citizens:
		if p.profile.role == CitizenProfile.Role.MERCHANT and p.mind != Person.Mind.PANIC:
			merchants_home = merchants_home and p.mind == Person.Mind.REGROUP
		if p.mind == Person.Mind.REGROUP:
			regrouping += 1
	t.check(merchants_home and regrouping >= Crowd.CITIZENS * 0.3, "the market closes and people go home (%d)" % regrouping)
	t.check(is_instance_valid(crowd._ringer) and crowd._ringer.mind == Person.Mind.DUTY
		and crowd._ringer.profile.role == CitizenProfile.Role.CLERGY, "a clergy member sets off to ring the bell")
	crowd._ringer.ground_pos = crowd._steps
	crowd._tend_bell(0.1)
	t.check(crowd.alarms.bell_rung, "reaching the steps, it rings")
	var aware := true
	for p in crowd.citizens:
		aware = aware and p.awareness >= Person.Awareness.EMERGENCY
	t.check(aware, "and everyone knows")
	crowd._clock += AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(AlarmManager.EVAC_BELL - crowd.alarm)
	t.check(crowd.alarms.stage == AlarmManager.Stage.EVACUATION and crowd._fled_all, "after the bell and the regroup, 75 evacuates the town")
	crowd.clear()
	(made[2] as Node).free()

	# No cathedral, no bell: the evacuation waits for 70.
	made = _crowd()
	crowd = made[0]
	env = made[1]
	for s in env.structures():
		if s.role == &"temple":
			s.destroy(s.center(), &"nova")
	crowd.add_alarm(80.0 - crowd.alarm)
	crowd._clock += AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(0.001)
	t.check(not crowd.alarms.bell_rung and crowd._ringer == null and crowd.alarms.stage == AlarmManager.Stage.CITY_EMERGENCY,
		"with the cathedral down nobody rings, and 80 is not yet an evacuation")
	crowd.add_alarm(AlarmManager.EVAC_NO_BELL - crowd.alarm)
	t.check(crowd.alarms.stage == AlarmManager.Stage.EVACUATION, "90 is")
	crowd.order_collapses()
	t.check(crowd.alarms.stage == AlarmManager.Stage.COLLAPSE, "and order can collapse")
	crowd.clear()
	(made[2] as Node).free()

	# Households: people sharing a home are a family, and a family regrouped at home leaves together as soon as
	# everyone is home.
	made = _crowd()
	crowd = made[0]
	var fam: int = crowd.citizens[0].profile.family
	var members: Array[Person] = []
	for p in crowd.citizens:
		if p.profile.family == fam:
			members.append(p)
	var same_home := true
	for p in members:
		same_home = same_home and p.profile.home == members[0].profile.home
		p.ground_pos = p.profile.home + Vector2(3.0, 0.0)
		p.regroup(p.profile.home)
	crowd._households[fam] = crowd._clock
	crowd._tend_households()
	t.check(members.size() >= 2 and same_home and members[0].mind == Person.Mind.REGROUP,
		"a household (%d people, one home) waits while members are still on their way" % members.size())
	for p in members:
		p.ground_pos = p.profile.home
		p._goal = Vector2.INF
	crowd._tend_households()
	var gone := true
	for p in members:
		gone = gone and p.mind == Person.Mind.FLEE
	t.check(gone, "and leaves together once everyone is home")
	crowd.clear()
	(made[2] as Node).free()
