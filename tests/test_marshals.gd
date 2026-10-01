extends RefCounted
## v0.07 Marshals: at the evacuation the soldiers from the walls take the ways out, profile.marshals_per_exit each;
## each one standing near a way out makes it SPEED faster; a confused evacuee near one comes to within STEADY_TIME;
## killed, a way out slows again.


static func _crowd(tier := ResponseProfile.Tier.PREPARED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var m := crowd.marshals
	t.check(m != null and not m.active, "the marshals wait on the walls until the evacuation")
	var fired := []
	m.posted.connect(func() -> void: fired.append(true))
	var calm := true
	for e in m.exits():
		calm = calm and is_equal_approx(m.speed_at(e[0]), 1.0)
	t.check(calm, "before the evacuation the ways out run at their own pace")
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.EVACUATION, "test")
	var per := crowd.profile.marshals_per_exit
	var placed := true
	for mouth: Vector2 in m.posts:
		var mine: Array = m.posts[mouth]
		placed = placed and mine.size() == per
		for p: Person in mine:
			placed = placed and p.corps == Person.Corps.MARSHAL and p.goal().distance_to(mouth) <= MarshalManager.REACH
	t.check(m.active and fired.size() == 1 and m.posts.size() == m.exits().size() and m.posts.size() == 4 and placed,
		"at the evacuation %d marshals take each of the %d ways out" % [per, m.posts.size()])

	# Arrived, they make the way out faster; killed, it slows again.
	var gate: Structure = (made[5] as Town).gates[0]
	var mouth: Vector2 = m.exits()[0][0]
	# All of them arrive, not only this way out's: one whose wall post is near this gate would still count here.
	for mine: Array in m.posts.values():
		for p: Person in mine:
			p.ground_pos = p.goal()
			p._goal = Vector2.INF
			p._path = PackedVector2Array()
	t.near(m.speed_at(mouth), 1.0 + MarshalManager.SPEED * per, 0.001, "each marshal speeds the way out (x%.2f)" % m.speed_at(mouth))
	var spots := crowd.queue_spots(gate)
	for k in 4:
		var c: Person = crowd.citizens[k]
		c.mind = Person.Mind.FLEE
		c.ground_pos = spots[k]
	crowd._gate_next.erase(gate)
	crowd._gates()
	t.near(float(crowd._gate_next[gate]) - crowd._clock, Crowd.GATE_INTERVAL / m.speed_at(mouth), 0.001,
		"so the gate lets the next one through sooner (%.2f s)" % (float(crowd._gate_next[gate]) - crowd._clock))

	# A confused evacuee near a marshal comes to sooner.
	var ev: Person = crowd.citizens[10]
	ev.mind = Person.Mind.FLEE
	ev.ground_pos = mouth + Vector2(0.0, -1.0)
	ev.confuse(15.0)
	m.step(1.0)
	t.check(ev._confused_left <= MarshalManager.STEADY_TIME, "a confused evacuee near a marshal comes to sooner")
	var far: Person = crowd.citizens[11]
	far.mind = Person.Mind.FLEE
	far.ground_pos = mouth + Vector2(0.0, -(MarshalManager.STEADY_R + 3.0))
	far.confuse(15.0)
	m.step(1.0)
	t.check(far.mind == Person.Mind.CONFUSED and far._confused_left > MarshalManager.STEADY_TIME,
		"a confused evacuee away from every marshal stays confused")

	for p: Person in m.posts[mouth]:
		field.kill(p, &"test")
	t.near(m.speed_at(mouth), 1.0, 0.001, "killed, the way out slows again")
	crowd.clear()
	(made[2] as Node).free()
