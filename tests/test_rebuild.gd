extends RefCounted
## Tearing the town down and building it again leaves exactly one town behind: no leftover buildings, no second
## floor, a Citadel back at full health and a crowd of the right size.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var ground := Node2D.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()

	var town := Town.new()
	town.build(env, ground)
	var first := env.structures().size()
	# Something the town did not build: teardown must leave it exactly where it is.
	var outsider := env.add_structure(Rect2(20.0, 20.0, 1.0, 1.0), 20.0, Structure.Kind.HOUSE, &"outsider")
	var first_citadel: Citadel = town.citadel
	var grid := WalkGrid.new().setup(env, town)
	var crowd := Crowd.new().setup(field, env, town, grid, world, 3)
	crowd.spawn(20, 10)
	t.check(first == TownLayout.structures().size() + 10, "the first town is complete (%d)" % first)
	t.check(ground.get_child_count() == 1, "one floor under the ground plane")

	# Knock a few things down and hurt the Citadel, so the rebuild has state to clear.
	env.damage_radius(Vector2(0.0, 2.0), 3.0, 99999.0, &"stone")
	town.citadel.keep.damage(300.0, TownLayout.CITADEL_ORIGIN, &"stone")
	t.check(town.citadel.fraction() < 1.0, "the Citadel took damage")

	crowd.clear()
	crowd.free()
	town.teardown()
	t.check(env.structures().size() == 1 and env.structures()[0] == outsider,
		"teardown takes only what the town built (%d left)" % env.structures().size())
	t.check(not env.blocked(TownLayout.TEMPLE.get_center()), "and nothing blocks where the temple stood")

	town.build(env, ground)
	t.check(env.structures().size() == first + 1, "the rebuilt town has the same buildings (%d)" % env.structures().size())
	t.check(town.get_child_count() == 1, "one Citadel node after a rebuild (%d children)" % town.get_child_count())
	t.check(town.citadel == first_citadel, "the same Citadel instance is rebuilt, so listeners stay wired")
	t.check(ground.get_child_count() == 1, "and still one floor")
	t.near(town.citadel.fraction(), 1.0, 0.001, "the Citadel is whole again")
	t.check(town.citadel.standing_parts() == 9 and town.citadel.parts.size() == 9, "with all nine parts")
	var grid2 := WalkGrid.new().setup(env, town)
	t.check(not grid2.walkable(TownLayout.TEMPLE.get_center()), "the temple blocks again")
	crowd = Crowd.new().setup(field, env, town, grid2, world, 4)
	crowd.spawn(20, 10)
	t.check(crowd.citizens.size() == 20 and crowd.soldiers.size() == 10, "and the crowd comes back")
	crowd.clear()
	town.teardown()
	env.clear()
	env.free()
	field.clear()
	field.free()
	town.free()
	crowd.free()
	world.free()
	ground.free()
