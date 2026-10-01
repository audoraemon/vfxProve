extends RefCounted
## v0.05 River boats: the dock on the north bank is a structure, and in a town with boats a third way out from the
## Evacuation stage, down through the postern in the south wall -- evacuees bound for it wait in a crowd behind the
## pier, step aboard one by one, and escape when the ship sails with up to LOAD of them; it is back TRIP seconds
## later. A destroyed dock stops the boats until it is rebuilt; a blighted one ends them. Without boats the postern
## is barred.


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


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


## Everyone waiting walks straight to their place.
static func _arrive(f: RiverFerry) -> void:
	for p in f._waiting:
		if is_instance_valid(p) and p.queue_spot != Vector2.INF:
			p.ground_pos = p.queue_spot


static func run(t) -> void:
	var made := _crowd(ResponseProfile.Tier.ORGANIZED)
	var crowd: Crowd = made[0]
	var town: Town = made[5]
	t.check(town.dock != null and town.dock.walkable and crowd.ferry.state == RiverFerry.State.ENDED
		and crowd.evac.exits.size() == 2, "an Organized town has a dock but no boats, and two ways out")
	t.check(not town.postern.walkable and not (made[4] as WalkGrid).walkable(TownLayout.POSTERN_AT),
		"and its postern is barred")
	_done(made)

	made = _crowd()
	crowd = made[0]
	var grid: WalkGrid = made[4]
	town = made[5]
	var f := crowd.ferry
	var ev := crowd.evac
	var inside_gate := Vector2(2.7, 13.5)
	var street := Vector2(-5.75, 12.0)
	t.check(f.state == RiverFerry.State.MOORED and grid.walkable(f.board_at) and ev.boat_exit == 2
		and ev.is_boat_exit(f.board_at) and ev.gates[ev.boat_exit] == town.postern and town.postern.walkable
		and not grid.path(street, f.board_at).is_empty(),
		"a Prepared town's dock is a third way out, down through the postern")
	var p: Person = crowd.citizens[0]
	p.ground_pos = street
	t.check(ev.score(p, ev.boat_exit) == INF, "closed until the evacuation")

	var events: Array = []
	f.opened.connect(func() -> void: events.append("opened"))
	f.sailed.connect(func(n: int) -> void: events.append("sailed %d" % n))
	f.closed.connect(func(why: String) -> void: events.append(why))
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.EVACUATION, "test")
	t.check(f.state == RiverFerry.State.LOADING and events == ["opened"] and ev.score(p, ev.boat_exit) < INF
		and ev.choose(p) == f.board_at, "the evacuation opens it, and from the west street it is the way out")

	# Eight bound for the dock: they wait behind the pier and step aboard one by one.
	var bound: Array[Person] = []
	for i in 8:
		var q: Person = crowd.citizens[10 + i]
		q.mind = Person.Mind.FLEE
		q.ground_pos = f.board_at + Vector2(-1.0 + 0.25 * i, -2.0)
		q.set_goal(f.board_at)
		bound.append(q)
	f.step(0.01)
	t.check(f.waiting() == 8 and bound[0].queue_spot != Vector2.INF, "they wait in a crowd behind the pier")
	_arrive(f)
	t.check(not f._waiting[0].has_escaped(), "reaching the pier is not yet escaping")
	var before := crowd.escaped_count
	var steps := 0
	while f.state == RiverFerry.State.LOADING and steps < 200:
		f.step(0.1)
		_arrive(f)
		steps += 1
	t.check(f.state == RiverFerry.State.AWAY and crowd.escaped_count - before == RiverFerry.LOAD and events.back() == "sailed 6"
		and f.waiting() == 2, "%d step aboard, and the ship sails with them (%d escaped, %s, %s, %d waiting)" % [RiverFerry.LOAD,
		crowd.escaped_count - before, RiverFerry.State.keys()[f.state], events.back(), f.waiting()])
	t.check(steps * 0.1 <= RiverFerry.LOAD_TIME + 0.5, "loading within %d s (%.1f)" % [roundi(RiverFerry.LOAD_TIME), steps * 0.1])
	f.step(RiverFerry.TRIP + 0.1)
	t.check(f.state == RiverFerry.State.LOADING, "and is back %d s later" % roundi(RiverFerry.TRIP))
	# Not full: with nobody left waiting it sails LOAD_TIME after the first stepped aboard.
	steps = 0
	while f.state == RiverFerry.State.LOADING and steps < 200:
		f.step(0.1)
		_arrive(f)
		steps += 1
	t.check(f.state == RiverFerry.State.AWAY and events.back() == "sailed 2", "with fewer waiting it sails anyway (%s)" % events.back())

	# A destroyed dock stops the boats until it is rebuilt.
	var late: Person = crowd.citizens[30]
	late.mind = Person.Mind.FLEE
	late.ground_pos = f.board_at + Vector2(0.0, -2.0)
	late.set_goal(f.board_at)
	f.step(RiverFerry.TRIP + 0.1)
	var waiting_before := f.waiting()
	town.dock.destroy(town.dock.center(), &"nova")
	f.step(0.1)
	t.check(waiting_before == 1 and f.state == RiverFerry.State.CLOSED and events.back() == "the dock is destroyed"
		and late.queue_spot == Vector2.INF and ev.score(p, ev.boat_exit) == INF,
		"a destroyed dock stops the boats, and those waiting go for the gates")
	town.dock.restore()
	f.step(0.1)
	t.check(f.state == RiverFerry.State.LOADING and events.back() == "opened", "rebuilt, they run again")
	town.dock.blighted = true
	f.step(0.1)
	t.check(f.state == RiverFerry.State.ENDED and events.back() == "the dock is sunk", "a blighted dock ends them for good")
	_done(made)

	# With the bridge down, the dock is the south's only way out.
	made = _crowd()
	crowd = made[0]
	town = made[5]
	f = crowd.ferry
	ev = crowd.evac
	crowd.alarms.stage = AlarmManager.Stage.CITY_EMERGENCY
	crowd._on_stage(AlarmManager.Stage.EVACUATION, "test")
	town.bridge.destroy(town.bridge.center(), &"nova")
	ev._rebuild_all()
	p = crowd.citizens[0]
	p.ground_pos = inside_gate
	t.check(ev.score(p, 0) == INF and ev.choose(p) == f.board_at, "with the bridge down, the south's way out is the boat")
	_done(made)
