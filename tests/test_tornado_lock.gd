extends RefCounted
## Tornado Tempest locks onto buildings: the nearest standing one inside its ring, not decor, walls or ground people
## walk on; it keeps its target unless another is clearly nearer, and has none when the ring is empty.


static func run(t) -> void:
	var tornado: GDScript = load("res://src/fx/set2/tornado_tempest.gd")
	var env := EnvironmentField.new()
	var origin := Vector2.ZERO
	var near_house := env.add_structure(Rect2(1.5, 0.0, 1.0, 1.0), 20.0, Structure.Kind.HOUSE, &"house")
	var far_house := env.add_structure(Rect2(4.0, 0.0, 1.0, 1.0), 20.0, Structure.Kind.HOUSE, &"house")
	var tree := env.add_structure(Rect2(0.6, 0.0, 0.45, 0.45), 22.0, Structure.Kind.TREE, &"decor")
	var wall := env.add_structure(Rect2(-1.2, 0.0, 0.5, 1.2), 34.0, Structure.Kind.CASTLE_WALL, &"wall")
	var field := env.add_structure(Rect2(-2.0, -2.0, 1.5, 1.5), 3.0, Structure.Kind.FARM_FIELD, &"farm")
	var outside := env.add_structure(Rect2(8.0, 0.0, 1.0, 1.0), 20.0, Structure.Kind.HOUSE, &"house")
	var all := env.structures()

	t.check(tornado.pick_target(origin, origin, null, all) == near_house,
		"it locks onto the nearest building, past a tree, a wall and a field that are nearer")
	# Moving towards the far house, it keeps its target until the other is a clear unit nearer.
	var between := Vector2(3.3, 0.5)
	t.check(tornado.pick_target(between, origin, near_house, all) == near_house,
		"it keeps its target while another is not clearly nearer")
	t.check(tornado.pick_target(Vector2(4.2, 0.5), origin, near_house, all) == far_house,
		"and switches once another is a clear unit nearer")
	# The ring: a building beyond WANDER_RADIUS of the cast point is never a target.
	t.check(tornado.pick_target(Vector2(8.5, 0.5), origin, null, all) != outside,
		"a building outside the ring is never locked onto")
	near_house.destroy(near_house.center(), &"wind")
	t.check(tornado.pick_target(origin, origin, near_house, all) == far_house, "a fallen target gives way to the next")
	far_house.destroy(far_house.center(), &"wind")
	t.check(tornado.pick_target(origin, origin, far_house, all) == null,
		"with nothing left in the ring it has no target (%s)" % tornado.pick_target(origin, origin, far_house, all))
	t.check(tree.role == &"decor" and wall.role == &"wall" and field.walkable, "the ones it ignores are decor, wall and walkable")
	env.clear()
	env.free()
