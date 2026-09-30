extends RefCounted
## v0.04 local awareness: the threat registry, and how people react by how near a danger is -- run clear of it,
## stop and look, or carry on -- how a fright spreads to neighbours, and how a frightened citizen goes back to its
## day avoiding the ground the danger left.


static func run(t) -> void:
	# The registry: a threat lasts its time, then leaves a recent impact that is still unsafe for a while.
	var tm := ThreatManager.new()
	var id := tm.register(Vector2(0, 0), 2.0, 0.5, 3.0, 6.0, 9.0, &"heaven")
	t.check(tm.is_active(id) and tm.nearby(Vector2(3.0, 0), 1.5).size() == 1 and tm.nearby(Vector2(5.0, 0), 1.5).is_empty(),
		"a threat is found near its radius and not beyond")
	tm.step(3.5)
	t.check(not tm.is_active(id) and tm.unsafe(Vector2(1.0, 0)), "once over it leaves a recent impact")
	tm.step(ThreatManager.RECENT + 0.1)
	t.check(not tm.unsafe(Vector2(1.0, 0)), "which fades")

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

	# A Heaven Splitter strike in the market: by distance, run / look / carry on.
	var at := Vector2(0.8, 2.0)
	var reach: Array = PowerBook.REACH["heaven"]
	var radius := Crowd._cast_radius("heaven")
	var near: Person = crowd.citizens[0]
	var mid: Person = crowd.citizens[1]
	var far: Person = crowd.citizens[2]
	var beside: Person = crowd.citizens[3]
	for p in [near, mid, far, beside]:
		p.mind = Person.Mind.CALM
		p._goal = Vector2.INF
	near.ground_pos = at + Vector2(radius * 0.5, 0.0)
	mid.ground_pos = at + Vector2(0.0, radius + Person.THREAT_MARGIN + 2.0)
	far.ground_pos = at + Vector2(0.0, -(float(reach[1]) + radius + 4.0))
	crowd.on_cast(at, Vector2.ZERO, 0.0, "heaven")
	t.check(near.mind == Person.Mind.PANIC and near.intent() == Person.Intent.LOCAL_FLEE, "inside the danger: run clear of it")
	t.check(mid.mind == Person.Mind.OBSERVE and mid.awareness == Person.Awareness.CONCERNED, "within earshot: stop and look")
	t.check(far.mind == Person.Mind.CALM and far.awareness == Person.Awareness.UNAWARE, "beyond: carry on")
	t.check(near._goal != Vector2.INF and near._goal.distance_to(at) >= radius + Person.LOCAL_FLEE - 0.6,
		"the run is to beyond the danger's edge, not to a gate (%.1f from it)" % near._goal.distance_to(at))

	# The fright spreads: a calm neighbour of the frightened one looks up a moment later, not at once.
	beside.ground_pos = near.ground_pos + Vector2(1.0, 0.0)
	beside.mind = Person.Mind.CALM
	crowd._spreads = [[crowd._clock + 0.5, near]]
	crowd._spread_fright()
	t.check(beside.mind == Person.Mind.CALM, "a neighbour does not react at once")
	crowd._clock += 1.0
	crowd._spread_fright()
	t.check(beside.mind == Person.Mind.OBSERVE, "but looks up a moment later")

	# Walking into a lasting danger frightens too.
	crowd.threats.register(Vector2(-10, 5), 2.0, 0.6, 10.0, 8.0, 11.0, &"tornado")
	var walker: Person = crowd.citizens[4]
	walker.mind = Person.Mind.CALM
	walker.ground_pos = Vector2(-10, 6)
	crowd._watch_threats()
	t.check(walker.mind == Person.Mind.PANIC or walker.mind == Person.Mind.SHELTER,
		"someone walking into a lasting danger runs from it or takes cover")

	# Recovering, a citizen's routine steers clear of the ground a danger left.
	var back: Person = crowd.citizens[5]
	var pr: CitizenProfile = back.profile
	back.mind = Person.Mind.RECOVER
	back._goal = Vector2.INF
	back.stay_left = 0.0
	crowd.threats.register(pr.home, 3.0, 0.5, 0.1, 5.0, 8.0, &"test")
	crowd.threats.step(0.2)
	var idx := crowd.citizens.find(back)
	for k in 10:
		back._goal = Vector2.INF
		back.stay_left = 0.0
		crowd.routine.visit(idx, 1.0)
		if back.has_goal():
			break
	t.check(not back.has_goal() or not crowd.threats.unsafe(back._goal, 1.0),
		"going back to its day, it does not walk onto ground a danger just left")
	crowd.clear()
	world.free()
