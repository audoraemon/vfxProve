extends RefCounted
## Where people may walk: buildings block, rubble does not, the river blocks except at the bridge, and a
## fallen bridge closes the south route.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)

	t.check(not grid.walkable(Vector2(0, 0)) and grid.walkable(Vector2(0, 1.0)) and grid.walkable(Vector2(1.0, 0)),
		"the fountain fills the market crossroads and the streets run on past it")
	t.check(not grid.walkable(TownLayout.TEMPLE.get_center()), "the temple blocks")
	t.check(not grid.walkable(Vector2(-6.0, 12.2)), "the river blocks")
	t.check(grid.walkable(Vector2(0, 12.2)), "the bridge crosses it")
	t.check(not grid.walkable(Vector2(0, -8.7)), "the town wall blocks")
	t.check(grid.walkable(TownLayout.MAIN_GATE.get_center()), "the main gate is a way through")

	# A route out of town uses the gate and the bridge.
	var south := grid.path(Vector2(0, 0), TownLayout.EXITS[0])
	var over_water := false
	var through_gate := false
	for p: Vector2 in south:
		over_water = over_water or (p.y > 11.4 and p.y < 13.0)
		through_gate = through_gate or TownLayout.MAIN_GATE.grow(0.3).has_point(p)
	t.check(south.size() > 0 and over_water and through_gate, "the south route runs through the gate and over the bridge (%d points)" % south.size())
	t.check(grid.path(Vector2(0, 0), TownLayout.EXITS[1]).size() > 0, "the east route is open too")
	t.near(grid.nearest_exit(Vector2(0, 6.0)).y, TownLayout.EXITS[0].y, 0.001, "from the south of town the south exit is nearest")

	# A goal inside a building still gives a route to its doorstep.
	var to_temple := grid.path(Vector2(0, 0), TownLayout.TEMPLE.get_center())
	t.check(to_temple.size() > 0 and not grid.walkable(TownLayout.TEMPLE.get_center()), "a goal inside a building routes beside it")

	# Rubble is walkable: destroying the temple opens its ground.
	for s in env.structures():
		if s.role == &"temple":
			s.destroy(Vector2(0, 0), &"stone")
	t.check(grid.walkable(TownLayout.TEMPLE.get_center()), "the temple's rubble can be walked over")
	t.check(not grid.walkable(Vector2(0, -8.7)), "the wall beside it still blocks")

	# The bridge is the only way south: when it falls the river closes.
	town.bridge.destroy(Vector2(0, 12.0), &"water")
	t.check(not grid.walkable(Vector2(0, 12.2)), "the fallen bridge does not carry anyone")
	t.check(grid.path(Vector2(0, 0), TownLayout.EXITS[0]).is_empty(), "the south route is closed")
	t.near(grid.nearest_exit(Vector2(0, 6.0)).x, TownLayout.EXITS[1].x, 0.001, "so the east exit becomes the nearest open one")
	t.check(grid.nearest_walkable(Vector2(-6.0, 12.2)) != Vector2.INF, "a point in the river snaps to the nearest bank")

	# Gates are passable across their whole span, not just down the middle: the wall segments beside the Side
	# Gate reach into its edge cells.
	var side: Rect2 = TownLayout.SIDE_GATE
	var blocked_cells := 0
	var probes := 0
	for gy in 6:
		for gx in 2:
			var p := side.position + Vector2(0.25 + 0.5 * float(gx), 0.25 + 0.5 * float(gy))
			if not side.has_point(p):
				continue
			probes += 1
			if not grid.walkable(p):
				blocked_cells += 1
	t.check(probes >= 8 and blocked_cells == 0, "the whole Side Gate is walkable (%d of %d cells blocked)" % [blocked_cells, probes])
	t.check(grid.walkable(TownLayout.FIELDS[0].get_center()), "a farm field can be walked over")
	t.check(not grid.clear_line(Vector2(-9.6, 0.0), Vector2(-8.0, 0.0)), "a straight walk through the west wall is not clear")
	t.check(grid.clear_line(Vector2(0.0, 1.0), Vector2(0.0, 3.0)), "and straight down the open street it is")
	env.clear()
	env.free()
	town.free()
