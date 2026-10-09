extends RefCounted
## Capital polish 2: the Keep's gate and steps, and its service yard.
##   - The barbican is the Keep's gatehouse at the head of the avenue from the cathedral square, the watchtower beside
##     it on the same line. Its arch is a walkable passage (BuildingTypes.PASSAGE) between solid towers: no crowd gate.
##   - Both alley steps stand at the gate's foot as one flight of two pieces up to it: their stairs are walked over,
##     their cheeks are solid.
##   - The Keep's service yard, the paving east of the Keep inside the old town's wall: royal stables and horse pens, a
##     granary, a well, the wagon (both facings) and hand carts parked, wood piles, barrels and crates; stable hands
##     work there.


static func run(t) -> void:
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_passages(t)
	_keep_gate(t, c)
	_keep_yard(t, c)
	_walk(t, c)
	_stable_hands(t, c)
	City.use(&"aldermere")


static func _plots(c: CapitalCity, tag: StringName) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if d.tag == tag:
			out.append(d.rect)
	return out


## The type table's passages: a gate-style walkable strip through a set (its arch or its stair) between solid sides.
static func _passages(t) -> void:
	for k: StringName in [&"gpt_barbican", &"gpt_alleysteps"]:
		var i := BuildingTypes.info(k)
		t.check(i.walkable and BuildingTypes.PASSAGE.has(k), "%s is walked through its passage" % k)
		var r := Rect2(Vector2(1.0, 2.0), CapitalPlots.SETS[k][0])
		var p := BuildingTypes.passage(k, r)
		var sides := BuildingTypes.cheeks(k, r)
		t.check(r.encloses(p) and is_equal_approx(p.size.y, r.size.y) and p.size.x < r.size.x,
			"%s's passage runs its whole depth, inside it (%s)" % [k, p])
		var area := p.get_area()
		var ok := sides.size() == 2
		for s: Rect2 in sides:
			area += s.get_area()
			ok = ok and r.encloses(s) and not s.intersects(p)
		t.check(ok and is_equal_approx(area, r.get_area()), "%s's cheeks are the rest of it, either side (%s)" % [k, sides])
	t.check(BuildingTypes.info(&"gpt_alleysteps").flat and not BuildingTypes.info(&"gpt_barbican").flat,
		"the steps lie flat (people climb over them), the gate stands up over its passage")
	t.check(BuildingTypes.cheeks(&"gpt_districtgate", Rect2(0, 0, 1.6, 2.1)).is_empty()
		and BuildingTypes.passage(&"gpt_inn", Rect2(0, 0, 1, 1)) == Rect2(), "a set without a passage has no cheeks")


## The barbican is the Keep's gate at the avenue's head; the watchtower beside it; the steps at its foot.
static func _keep_gate(t, c: CapitalCity) -> void:
	var gate := _plots(c, &"gpt_barbican")
	t.check(gate.size() == 1, "one Keep gate (%d)" % gate.size())
	if gate.size() != 1:
		return
	var g := gate[0]
	var avenue_x := 4.0
	t.check(c.landmark(&"royal_keep").encloses(g), "the gate stands in the Royal Keep")
	t.check(is_equal_approx(g.end.y, -22.0), "it stands at the head of the avenue from the cathedral square (%s)" % g)
	var arch := BuildingTypes.passage(&"gpt_barbican", g)
	t.check(arch.position.x < avenue_x - 0.2 and arch.end.x > avenue_x + 0.2, "its arch is on the avenue (%s)" % arch)
	var key := Rect2(Citadel.KEEP.position + c.citadel_origin(), Citadel.KEEP.size)
	t.check(g.position.y > key.end.y, "it is on the Keep's south side")
	var tower := _plots(c, &"gpt_watchtower")
	t.check(tower.size() == 1 and is_equal_approx(tower[0].position.y, g.position.y)
		and tower[0].position.x >= g.end.x and tower[0].position.x - g.end.x <= 0.5,
		"the watchtower stands beside the gate on its line (%s)" % [tower])
	var steps := _plots(c, &"gpt_alleysteps")
	t.check(steps.size() == 2, "both alley steps are at the Keep (%d)" % steps.size())
	if steps.size() == 2:
		steps.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.y > b.position.y)
		t.check(is_equal_approx(steps[1].end.y, g.end.y + steps[1].size.y) and is_equal_approx(steps[1].position.y, g.end.y)
			and is_equal_approx(steps[0].position.y, steps[1].end.y) and is_equal_approx(steps[0].position.x, steps[1].position.x),
			"the two pieces make one flight up to the gate's front (%s)" % [steps])
		var stair := BuildingTypes.passage(&"gpt_alleysteps", steps[1])
		t.check(stair.end.x > arch.position.x + 0.2 and stair.position.x < arch.end.x - 0.2,
			"the stair leads into the arch (%s, %s)" % [stair, arch])
	var kinds := true
	for d: Dictionary in c.structures():
		if d.tag in [&"gpt_barbican", &"gpt_alleysteps"]:
			kinds = kinds and d.kind != Structure.Kind.GATE
	t.check(kinds, "the Keep's gate is a passage, not a crowd gate (the Keep is no way out)")


## The Keep's service yard: inside the old town, east of the Keep's gate; its buildings, carts, well and decor in it.
static func _keep_yard(t, c: CapitalCity) -> void:
	var y := CapitalCity.KEEP_YARD
	t.check(c.landmark(&"keep_yard") == y and c.landmark(&"old_town_wall").grow(-0.7).encloses(y),
		"the service yard is a landmark inside the old town's wall")
	var gate := _plots(c, &"gpt_barbican")
	t.check(not gate.is_empty() and y.position.x >= gate[0].end.x, "it lies east of the Keep and its gate")
	var count := {}
	var turned := 0
	var straight := 0
	for d: Dictionary in c.structures():
		if y.encloses(d.rect):
			count[d.tag] = int(count.get(d.tag, 0)) + 1
			if d.tag == &"gpt_wagon":
				var s := Structure.new().setup(d.rect, d.height, d.kind, 1, d.role, d.tag)
				if SpriteArt.set_for(s).get("mirror", false):
					turned += 1
				else:
					straight += 1
				s.free()
		elif d.tag in [&"gpt_wagon", &"gpt_handcart"]:
			count[&"elsewhere"] = int(count.get(&"elsewhere", 0)) + 1
	t.check(int(count.get(&"gpt_stables", 0)) >= 2 and int(count.get(&"gpt_pens", 0)) >= 1,
		"royal stables and horse pens stand in the yard (%s)" % [count])
	t.check(int(count.get(&"gpt_granary", 0)) == 1, "a granary stands in the yard")
	t.check(turned >= 1 and straight >= 1, "wagons are parked there both ways round (%d, %d)" % [straight, turned])
	t.check(int(count.get(&"gpt_handcart", 0)) >= 1, "hand carts are parked there")
	t.check(not count.has(&"elsewhere"), "the wagons and hand carts stand in the yard only")
	var well := false
	for w: Rect2 in c.wells():
		well = well or y.encloses(w)
	t.check(well, "the yard has its well")
	var kinds := {}
	for d: Dictionary in c.court_decor():
		if y.has_point(d.at):
			kinds[d.kind] = true
	t.check(kinds.has(Decor.Kind.LOGS) and kinds.has(Decor.Kind.BARREL) and kinds.has(Decor.Kind.CRATES),
		"wood piles, barrels and crates stand about the yard (%s)" % [kinds.keys()])
	var work := 0
	for g: Vector2 in c.anchors().work:
		work += 1 if y.has_point(g) else 0
	t.check(work >= CitizenProfile.WORK_NEAREST, "the yard has its own work places (%d)" % work)
	t.check(c.spawn_roles().get(&"keep_yard", {}).get(&"stable_hand", 0) >= 2, "stable hands are dealt to the yard")


## Through the real town and walk grid: the passages are walked, the cheeks are not; a walk up the avenue climbs the
## steps and passes the arch; the decor keeps off the cheeks only.
static func _walk(t, c: CapitalCity) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var gate := _plots(c, &"gpt_barbican")
	var steps := _plots(c, &"gpt_alleysteps")
	if gate.size() != 1 or steps.size() != 2:
		t.check(false, "the Keep's gate and steps stand")
		town.free()
		return
	var open := 0
	var shut := 0
	var cells := 0
	for d: Dictionary in [{"tag": &"gpt_barbican", "rect": gate[0]}, {"tag": &"gpt_alleysteps", "rect": steps[0]},
			{"tag": &"gpt_alleysteps", "rect": steps[1]}]:
		var p := BuildingTypes.passage(d.tag, d.rect)
		for y in range(floori(p.position.y / 0.5), floori(p.end.y / 0.5) + 1):
			for x in range(floori(p.position.x / 0.5), floori(p.end.x / 0.5) + 1):
				var ctr := Vector2(x + 0.5, y + 0.5) * 0.5
				if p.has_point(ctr):
					cells += 1
					open += 1 if grid.walkable(ctr) else 0
		for s: Rect2 in BuildingTypes.cheeks(d.tag, d.rect):
			for y in range(floori(s.position.y / 0.5), floori(s.end.y / 0.5) + 1):
				for x in range(floori(s.position.x / 0.5), floori(s.end.x / 0.5) + 1):
					var ctr := Vector2(x + 0.5, y + 0.5) * 0.5
					if s.has_point(ctr) and grid.walkable(ctr):
						shut += 1
	t.check(cells > 0 and open == cells, "every cell of the arch and the stairs is walkable (%d of %d)" % [open, cells])
	t.check(shut == 0, "no cell of the gate's towers or the steps' cheeks is (%d)" % shut)
	# Up the avenue from the cathedral square into the Keep: over the steps and through the arch.
	var arch := BuildingTypes.passage(&"gpt_barbican", gate[0])
	var from := Vector2(arch.get_center().x, steps[0].end.y + 1.5)
	var to := Vector2(arch.get_center().x, gate[0].position.y - 1.5)
	var path := grid.path(from, to)
	var on_steps := false
	var in_arch := false
	for q: Vector2 in path:
		on_steps = on_steps or steps[0].has_point(q) or steps[1].has_point(q)
		in_arch = in_arch or gate[0].has_point(q)
	t.check(not path.is_empty() and on_steps and in_arch, "a walk up the avenue climbs the steps and passes the arch (%s)"
		% [path])
	t.check(not town.gates.has(_structure(env, gate[0])), "the Keep's gate is not one of the town's crowd gates")
	# The decor keeps off the cheeks, never the passages.
	var solid := TownDecor._solid_rects(c.structures())
	var sides := BuildingTypes.cheeks(&"gpt_barbican", gate[0])
	t.check(sides.size() == 2 and solid.has(sides[0]) and solid.has(sides[1]) and not solid.has(gate[0])
		and not solid.has(arch), "the decor treats the gate's towers as solid, its arch as open")
	town.free()
	City.use(&"aldermere")


## In a real crowd the yard's stable hands live and work in it, and every yard work place can be reached.
static func _stable_hands(t, c: CapitalCity) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var seen: Dictionary = preload("res://tests/test_capital_ground.gd")._flood(grid, grid.nearest_walkable(c.exits()[0]))
	var cut: Array = []
	for g: Vector2 in c.anchors().work:
		if CapitalCity.KEEP_YARD.has_point(g):
			var w := grid.nearest_walkable(g, 2)
			if w == Vector2.INF or not seen.has(grid.world_to_id(w)):
				cut.append(g)
	t.check(cut.is_empty(), "every work place in the yard can be reached (cut %s)" % [cut])
	var field := EnemyField.new()
	field.env = env
	field.bounds = c.map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 7)
	crowd.spawn()
	var hands := 0
	var there := 0
	for p: Person in crowd.citizens:
		if p.profile != null and p.profile.district == &"keep_yard":
			hands += 1
			there += 1 if p.profile.job == &"stable_hand" and CapitalCity.KEEP_YARD.grow(0.5).has_point(p.profile.work) else 0
	t.check(hands >= 2 and there == hands, "the yard's stable hands work in it (%d of %d)" % [there, hands])
	crowd.clear()
	world.free()
	town.free()
	City.use(&"aldermere")


static func _structure(env: EnvironmentField, r: Rect2) -> Structure:
	for s: Structure in env.structures():
		if s.footprint == r:
			return s
	return null
