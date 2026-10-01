extends RefCounted
## v0.06 Will-o'-Wisp: calm citizens within reach walk to the light and stand staring; the fleeing, people on duty and
## soldiers do not come; at most LURE_MAX; afterwards they go back to their day. Nothing is registered as a danger.


static func run(t) -> void:
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
	var at := Vector2(0.8, 2.0)
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var near: Array[Person] = []
	for k in 30:
		var p: Person = crowd.citizens[k]
		p.mind = Person.Mind.CALM
		p.ground_pos = at + Vector2(0.15 * float(k % 10) - 0.7, 0.3 * float(k / 10) + 1.0)
		near.append(p)
	near[0].mind = Person.Mind.FLEE
	near[1].mind = Person.Mind.DUTY
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = at + Vector2(0.5, 0.5)
	var drawn := WillOWisp.drawn(field, at)
	t.check(drawn.size() == WillOWisp.LURE_MAX and near[0] not in drawn and near[1] not in drawn and soldier not in drawn,
		"it draws calm citizens only, %d at most (%d)" % [WillOWisp.LURE_MAX, drawn.size()])
	var p: Person = drawn[0]
	t.check(p.lure(at, 10.0) and p.mind == Person.Mind.OBSERVE and p.goal() != Vector2.INF,
		"a lured citizen walks to the light, watching it")
	p._idle = 0.0
	p._think(0.1)
	t.check(p._idle == 0.0, "and is not held in place on the way, as a plain watcher is")
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._think(9.0)
	t.check(p.mind == Person.Mind.OBSERVE, "it stands there staring")
	p._think(1.5)
	t.check(p.mind == Person.Mind.RECOVER, "then goes back to its day")
	t.check(not near[0].lure(at, 10.0) and not soldier.lure(at, 10.0), "the fleeing and soldiers will not come")
	crowd.on_cast(at, Vector2.ZERO, 0.0, "wisp")
	t.check(crowd.threats.active_count() == 0, "a wisp is no danger the town can see")
	crowd.clear()
	world.free()
