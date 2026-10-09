extends RefCounted
## Capital polish 2: the Keep's gate and steps, its service yard, the cathedral close, the aqueduct and the south
## district gate.
##   - The passages (BuildingTypes.PASSAGE): a walkable strip through a set between solid sides. (Polish 3 took the
##     Keep's gate and its steps out of the capital: test_capital_polish3.gd covers the Keep's ground now.)
##   - The district gate stands across a real lane, its paving carrying the lane through.
##   - The Keep's service yard, the paving east of the Keep inside the old town's wall: royal stables and horse pens, a
##     granary, a well, the wagon (both facings) and hand carts parked, wood piles, barrels and crates; stable hands
##     work there.
##   - The cathedral close: a churchyard beside the cathedral (graves, the wayside cross, yews) and a paved pilgrim
##     plaza before its steps (a well, benches, the notice board, a crier's stage, pilgrim stalls); priests and monks
##     pray there, townsfolk gather there.
##   - The aqueduct runs from a spring in the northern woods to the old town's north-east corner tower, the cistern
##     just inside the wall there; the woods stand back from its arches.


static func run(t) -> void:
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_passages(t)
	_district_gate(t, c)
	_keep_yard(t, c)
	_close(t, c)
	_aqueduct(t, c)
	_walk(t, c)
	_stable_hands(t, c)
	City.use(&"aldermere")


static func _plots(c: CapitalCity, tag: StringName) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if d.tag == tag:
			out.append(d.rect)
	return out


## The road rects of the lanes (LANE_W wide).
static func _lanes(c: CapitalCity) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var lines: Array = []
	for line: Array in CapitalCity.LANES:
		lines.append(line)
	for line: Array in lines:
		for k in line.size() - 1:
			var a: Vector2 = line[k]
			var b: Vector2 = line[k + 1]
			out.append(Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs()).grow(CapitalCity.LANE_W * 0.5))
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


## The district gate stands across a lane: the lane runs through it, under its arch.
static func _district_gate(t, c: CapitalCity) -> void:
	var dg := _plots(c, &"gpt_districtgate")
	t.check(dg.size() == 1, "one district gate (%d)" % dg.size())
	if dg.size() != 1:
		return
	var g := dg[0]
	var across := false
	for lane: Rect2 in _lanes(c):
		if lane.size.y > lane.size.x and g.position.x <= lane.position.x and g.end.x >= lane.end.x \
				and lane.position.y < g.position.y - 0.5 and lane.end.y > g.end.y + 0.5:
			across = true
	t.check(across, "the district gate stands across a lane, which runs on beyond both its ends (%s)" % g)
	t.check(c.landmark(&"new_town_wall").encloses(g), "in the new town")


## The Keep's service yard: inside the old town, east of the Keep's gate; its buildings, carts, well and decor in it.
static func _keep_yard(t, c: CapitalCity) -> void:
	var y := CapitalCity.KEEP_YARD
	t.check(c.landmark(&"keep_yard") == y and c.landmark(&"old_town_wall").grow(-0.7).encloses(y),
		"the service yard is a landmark inside the old town's wall")
	var keep := Rect2(Citadel.KEEP.position + c.citadel_origin(), Citadel.KEEP.size)
	t.check(y.position.x >= keep.end.x + 3.0, "it lies east of the Keep")
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


## The cathedral close: the churchyard on the lawn beside the cathedral, the pilgrim plaza paved before its steps;
## nothing there taller than the cathedral; prayer and market points for the clergy, the monks and the townsfolk.
static func _close(t, c: CapitalCity) -> void:
	var cath := c.landmark(&"temple")
	var yard := CapitalCity.CHURCHYARD
	var plaza := CapitalCity.PILGRIM_PLAZA
	t.check(c.landmark(&"churchyard") == yard and c.landmark(&"pilgrim_plaza") == plaza, "the close's two parts are landmarks")
	t.check(yard.position.x >= cath.end.x and yard.position.x - cath.end.x < 0.6 and yard.position.y < cath.end.y
		and yard.end.y > cath.position.y, "the churchyard lies on the lawn beside the cathedral (%s)" % yard)
	t.check(plaza.position.y > cath.end.y and plaza.position.y - cath.end.y < 3.0 and plaza.position.x < cath.position.x
		and plaza.end.x > cath.end.x, "the pilgrim plaza lies before the cathedral's steps, across its front (%s)" % plaza)
	var tags := {}
	var tall: Array = []
	for d: Dictionary in c.structures():
		var r: Rect2 = d.rect
		if yard.encloses(r) or plaza.encloses(r):
			tags[d.tag] = int(tags.get(d.tag, 0)) + (1 if yard.encloses(r) else 100)
			if d.height >= 56.0:
				tall.append(d.tag)
	t.check(int(tags.get(&"gpt_graveyard", 0)) == 1 and int(tags.get(&"gpt_waysidecross", 0)) == 1,
		"the churchyard has its graves and the wayside cross (%s)" % [tags])
	t.check(int(tags.get(&"gpt_noticeboard", 0)) == 100 and int(tags.get(&"gpt_crierstage", 0)) == 100,
		"the notice board and a crier's stage stand on the plaza (%s)" % [tags])
	t.check(tall.is_empty(), "nothing in the close stands as tall as the cathedral (%s)" % [tall])
	var near := 0
	for d: Dictionary in c.structures():
		if d.tag == &"gpt_noticeboard" and cath.grow(4.0).intersects(d.rect):
			near += 1
	t.check(near == 1, "one notice board by the cathedral: the jail's, moved to the plaza (%d)" % near)
	var stalls := 0
	for st: Rect2 in c.stalls():
		stalls += 1 if plaza.encloses(st) else 0
	t.check(stalls >= 3 and stalls <= 4, "3-4 pilgrim stalls on the plaza (%d)" % stalls)
	var well := false
	for w: Rect2 in c.wells():
		well = well or plaza.encloses(w)
	t.check(well, "the plaza has its well")
	var paved := false
	for r: Rect2 in c.floor_areas()[&"plazas"]:
		paved = paved or r == plaza
	t.check(paved, "the plaza is paved with the floor's plaza paving")
	var benches := 0
	var yews := 0
	for d: Dictionary in c.court_decor():
		benches += 1 if d.kind == Decor.Kind.BENCH and plaza.has_point(d.at) else 0
		yews += 1 if d.kind == Decor.Kind.PINE and yard.has_point(d.at) else 0
	t.check(benches >= 2 and yews >= 2, "benches on the plaza (%d), yews in the churchyard (%d)" % [benches, yews])
	var an := c.anchors()
	var pray_yard := 0
	var pray_plaza := 0
	var market_plaza := 0
	for g: Vector2 in an.pray:
		pray_yard += 1 if yard.has_point(g) else 0
		pray_plaza += 1 if plaza.has_point(g) else 0
	for g: Vector2 in an.market:
		market_plaza += 1 if plaza.has_point(g) else 0
	t.check(pray_yard >= 2 and pray_plaza >= 2 and market_plaza >= 2,
		"prayer points in the churchyard (%d) and on the plaza (%d), market points on the plaza (%d)"
		% [pray_yard, pray_plaza, market_plaza])
	t.check(int(c.spawn_roles()[&"cathedral_square"].get(&"monk", 0)) >= 2, "monks are dealt to the cathedral close")


## The aqueduct: one straight run from a spring in the northern woods west to the old town's north-east corner tower,
## its last arch against the tower's face; the cistern just inside the wall there; no tree under or beside the arches.
static func _aqueduct(t, c: CapitalCity) -> void:
	City.use(&"capital")
	var pieces := _plots(c, &"gpt_aqueduct")
	pieces.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	t.check(pieces.size() >= 8, "the aqueduct has its arches (%d)" % pieces.size())
	if pieces.is_empty():
		return
	var joined := true
	for k in range(1, pieces.size()):
		joined = joined and is_equal_approx(pieces[k].position.x, pieces[k - 1].end.x) \
			and is_equal_approx(pieces[k].position.y, pieces[0].position.y)
	t.check(joined, "its arches join end to end in one straight run")
	var corner := Rect2()
	for d: Dictionary in c.structures():
		var r: Rect2 = d.rect
		if d.role == &"tower" and r.has_point(Vector2(CapitalCity.INNER.end.x, CapitalCity.INNER.position.y)):
			corner = r
	t.check(corner.has_area() and is_equal_approx(pieces[0].position.x, corner.end.x)
		and pieces[0].position.y > corner.position.y and pieces[0].end.y < corner.end.y,
		"its last arch ends against the old town's north-east corner tower (%s, %s)" % [pieces[0], corner])
	var run := Rect2(pieces[0].position, Vector2(pieces[-1].end.x - pieces[0].position.x, pieces[0].size.y))
	t.check(c.landmark(&"northern_woods").has_point(pieces[-1].get_center()), "it starts in the northern woods")
	t.check(pieces[-1].end.distance_to(CapitalCity.AQUEDUCT_SPRING) < 2.0, "at the spring")
	var cis := _plots(c, &"gpt_cistern")
	t.check(cis.size() == 1 and CapitalCity.INNER.grow(-TownLayout.WALL_T).encloses(cis[0])
		and cis[0].grow(0.6).intersects(corner), "the cistern stands just inside the wall at that tower (%s)" % [cis])
	var trees: Array = []
	var clear := run.grow_individual(0.4, 0.9, 0.0, 1.6)
	for d: Dictionary in TownDecor.spots():
		if d.kind in [Decor.Kind.OAK, Decor.Kind.PINE] and clear.has_point(d.at):
			trees.append(d.at)
	t.check(trees.is_empty(), "no tree stands under or beside the arches (%s)" % [trees])
	var floor := true
	for f: float in [0.1, 0.5, 0.9]:
		for dy: float in [-0.8, 0.2, 1.4]:
			floor = floor and TownFloor.in_forest_gap(Vector2(lerpf(run.position.x, run.end.x, f), run.get_center().y + dy))
	t.check(floor, "the forest floor stands back from them too")


## Through the real town and walk grid: the passages are walked, the cheeks are not; a walk up the avenue climbs the
## steps and passes the arch; the lane runs through the district gate; the decor keeps off the cheeks only.
static func _walk(t, c: CapitalCity) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	# The lane runs on through the district gate.
	var dg := _plots(c, &"gpt_districtgate")
	if dg.size() == 1:
		var g := dg[0]
		var x := g.get_center().x
		var cut: Array = []
		var y := g.position.y - 0.75
		while y <= g.end.y + 0.75:
			if not grid.walkable(Vector2(x, y)):
				cut.append(y)
			y += 0.25
		t.check(cut.is_empty(), "the lane runs on through the district gate (cut at %s)" % [cut])
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
