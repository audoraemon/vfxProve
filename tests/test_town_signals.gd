extends RefCounted
## v0.06: a structure added after the town is built closes the walk grid under it, and removing it opens it again;
## the crowd forgets the gate queue spots it had worked out, so they are found again round the change.


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
	var at := Vector2(2.75, 11.25)  # the Main Gate's plaza, on a cell centre
	t.check(grid.walkable(at), "open ground first")
	crowd.queue_spots(town.gates[0])
	var v := grid.version
	var s := env.add_structure(Rect2(at - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), 14.0, Structure.Kind.TREE, &"thorns",
		&"thorns")
	t.check(not grid.walkable(at) and grid.version > v and crowd._spots.is_empty(),
		"an added structure closes its ground, and the gate spots are worked out again")
	env.remove(s)
	t.check(grid.walkable(at), "removed, the ground opens again")
	crowd.clear()
	world.free()
