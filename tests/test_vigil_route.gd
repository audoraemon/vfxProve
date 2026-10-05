extends RefCounted
## v0.10 the Vigil's walk (VigilRoute): the flame-bearer walks his route point by point with two acolytes keeping beside
## him; a fright stops him, and he takes the route up where he left it; at the last point the walk is over and all three
## go back to their day. A dead bearer ends it.

const DT := 0.05


static func _crowd() -> Dictionary:
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


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## One look at the walk (VigilRoute.TICK), stepped at DT.
static func _tick(v: VigilRoute) -> void:
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)


static func run(t) -> void:
	var s := _crowd()
	var crowd: Crowd = s.crowd
	var grid: WalkGrid = s.grid
	var bearer: Person = crowd.citizens[2]
	var acolytes: Array[Person] = [crowd.citizens[4], crowd.citizens[6]]
	var start := bearer.ground_pos
	var points := PackedVector2Array([grid.nearest_walkable(start + Vector2(2.0, 0.0)),
		grid.nearest_walkable(start + Vector2(4.0, 0.0))])
	var v := VigilRoute.new().setup(points, bearer, acolytes)
	t.check(not v.active and not v.finished and v.walkers().size() == 3, "a Vigil waits until it starts, three walking")
	v.start()
	t.check(v.active and v.leg == 0 and bearer.mind == Person.Mind.DUTY and bearer.anchor.distance_to(points[0]) < 0.01,
		"the bearer sets out for the first point")
	bearer.ground_pos = points[0]
	bearer._goal = Vector2.INF
	bearer._path = PackedVector2Array()
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.leg == 1 and bearer.anchor.distance_to(points[1]) < 0.01, "at a point he goes on to the next")
	t.check(acolytes[0].mind == Person.Mind.DUTY and acolytes[0].anchor.distance_to(bearer.ground_pos) < 2.0,
		"the acolytes keep beside him")
	bearer.panic(bearer.ground_pos + Vector2(0.5, 0.0), 1.0)
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.leg == 1 and bearer.mind != Person.Mind.DUTY, "a fright stops him where he is")
	bearer.mind = Person.Mind.CALM
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.leg == 1 and bearer.mind == Person.Mind.DUTY and bearer.anchor.distance_to(points[1]) < 0.01,
		"back on his feet he takes the route up again")
	bearer.ground_pos = points[1]
	bearer._goal = Vector2.INF
	bearer._path = PackedVector2Array()
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
	t.check(v.finished and not v.active and bearer.mind != Person.Mind.DUTY and acolytes[1].mind != Person.Mind.DUTY,
		"at the last point the walk is over and all three go back to their day")

	# A walker busy elsewhere (a report to carry) is not pulled back beside the bearer.
	var b3: Person = crowd.citizens[10]
	var a3: Array[Person] = [crowd.citizens[12]]
	var v3 := VigilRoute.new().setup(points, b3, a3)
	v3.busy = func(p: Person) -> bool: return p == a3[0]
	v3.start()
	a3[0].go_duty(points[0] + Vector2(30.0, 0.0))
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v3.step(DT)
	t.check(a3[0].anchor.distance_to(points[0] + Vector2(30.0, 0.0)) < 0.01, "a busy acolyte keeps their own errand")
	v3.busy = func(p: Person) -> bool: return p == b3
	b3.go_duty(points[0] + Vector2(30.0, 0.0))
	b3._goal = Vector2.INF
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v3.step(DT)
	t.check(b3.anchor.distance_to(points[0] + Vector2(30.0, 0.0)) < 0.01, "and so does a busy bearer")

	var b2: Person = crowd.citizens[8]
	var v2 := VigilRoute.new().setup(points, b2, [] as Array[Person])
	v2.start()
	crowd._field.kill(b2, &"doom")
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v2.step(DT)
	t.check(v2.finished and v2.walkers().is_empty(), "a dead bearer ends the Vigil")
	# v0.10 M3, for Broken Lanterns: round again, turned aside, the flame passed on.
	var b4: Person = crowd.citizens[14]
	var first: Person = crowd.citizens[16]
	var second: Person = crowd.citizens[18]
	var a4: Array[Person] = [first, second]
	var v4 := VigilRoute.new().setup(points, b4, a4)
	v4.loop = true
	v4.pass_flame = true
	var passed: Array[Person] = []
	v4.flame_passed.connect(func(p: Person) -> void: passed.append(p))
	v4.start()
	for pt in points:
		_arrive(b4, pt)
		_tick(v4)
	t.check(v4.active and not v4.finished and v4.leg == 0 and b4.anchor.distance_to(points[0]) < 0.01,
		"a looping Vigil goes round again from the first point")
	var aside := grid.nearest_walkable(points[0] + Vector2(0.0, 3.0))
	v4.divert(aside)
	t.check(v4.detour == aside and v4.goal() == aside and b4.anchor.distance_to(aside) < 0.01,
		"turned aside, the bearer makes for the place at once")
	_arrive(b4, aside)
	_tick(v4)
	t.check(v4.detour == Vector2.INF and v4.leg == 0 and b4.anchor.distance_to(points[0]) < 0.01,
		"there, he takes the route up where he left it")
	v4.divert(aside)
	v4.divert(Vector2.INF)
	t.check(v4.detour == Vector2.INF and b4.anchor.distance_to(points[0]) < 0.01, "a detour called off sends him back to the route")
	crowd._field.kill(b4, &"doom")
	_tick(v4)
	t.check(v4.active and v4.bearer == first and passed.size() == 1 and passed[0] == first
		and first.mind == Person.Mind.DUTY and first.anchor.distance_to(v4.goal()) < 0.01,
		"a dead bearer's flame passes to the first living acolyte, who walks on")
	crowd._field.kill(first, &"doom")
	_tick(v4)
	t.check(v4.active and v4.bearer == second and passed.size() == 2, "and on again when that one falls")
	crowd._field.kill(second, &"doom")
	_tick(v4)
	t.check(v4.finished and v4.walkers().is_empty(), "with all three dead the Vigil is over")
	_done(s)
