extends RefCounted
## v0.07 Marshals: at the evacuation the soldiers from the walls take the ways out, profile.marshals_per_exit each;
## each one standing near a way out makes it SPEED faster; a confused evacuee near one comes to within STEADY_TIME;
## killed, a way out slows again -- until a soldier from the rally ring takes the dead one's place (v0.09.1).

const CorpsTest := preload("res://tests/test_corps.gd")


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
	var gap := 0.0
	for mouth: Vector2 in m.posts:
		var mine: Array = m.posts[mouth]
		placed = placed and mine.size() == per
		for p: Person in mine:
			placed = placed and p.corps == Person.Corps.MARSHAL and p.goal().distance_to(mouth) <= MarshalManager.REACH
			gap = maxf(gap, absf(p._mind_speed() - Person.PANIC_SPEED * p.pace))
	t.near(gap, 0.0, 0.001, "the marshals run to the ways out")
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
	_reserve(t)


## The reserve (v0.09.1): once the soldiers have rallied, a marshal killed is replaced by the nearest soldier on the ring.
## At its way out it takes the dead one's place there; on the walls before the evacuation, the evacuation posts it.
static func _reserve(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var m := crowd.marshals
	crowd.rally()
	CorpsTest.ring(crowd)
	# On the walls, before the evacuation.
	var dead: Person = CorpsTest.first_of(crowd, Person.Corps.MARSHAL)
	var ring := CorpsTest.on_ring(crowd)
	field.kill(dead, &"test")
	var wall: Person = null
	for p in ring:
		if p.corps == Person.Corps.MARSHAL:
			wall = p
	t.check(wall != null and wall.post == dead.post and wall.mind == Person.Mind.POST and wall.hurrying
		and wall.goal().distance_to(dead.post) < 0.3, "a marshal killed on the walls: a soldier from the ring runs to its post")
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.EVACUATION, "test")
	var posted := false
	for mine: Array in m.posts.values():
		posted = posted or mine.has(wall)
	t.check(posted, "and the evacuation posts it at a way out")

	# At a way out.
	var mouth: Vector2 = m.exits()[0][0]
	var mine: Array = m.posts[mouth]
	var per := crowd.profile.marshals_per_exit
	t.check(mine.size() == per, "%d marshals at the Main Gate" % mine.size())
	for p: Person in mine:
		p.ground_pos = p.goal()
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
	var full := m.speed_at(mouth)
	var fallen: Person = mine[1]
	var spot := fallen.ground_pos
	ring = CorpsTest.on_ring(crowd)
	field.kill(fallen, &"test")
	var reserve: Person = null
	for p in ring:
		if p.corps == Person.Corps.MARSHAL:
			reserve = p
	mine = m.posts[mouth]
	t.check(reserve != null and reserve.post == fallen.post and mine.size() == per and mine[1] == reserve
		and not mine.has(fallen), "a marshal killed at the gate: the reserve takes its place in the gate's marshals")
	t.check(reserve != null and reserve.hurrying and reserve.goal().distance_to(spot) < 0.5,
		"and runs to where it stood")
	reserve.ground_pos = reserve.goal()
	reserve._goal = Vector2.INF
	t.near(m.speed_at(mouth), full, 0.001, "there, the gate runs at its full pace again (x%.2f)" % m.speed_at(mouth))
	crowd.clear()
	(made[2] as Node).free()
