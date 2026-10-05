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
	_done(s)
