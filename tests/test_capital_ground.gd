extends RefCounted
## The capital's ground (Task 8): every place people use can be reached on the walk grid from every exit, every
## district holds reachable ground; and the floor and decor read the active city's own geography (trails, outcrops,
## boats, scarecrows, signposts, carts, rosettes, forest gaps, outside roads, the harbour basin's shores), Aldermere
## keeping its exact data.


static func run(t) -> void:
	_aldermere_data(t)
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_capital_data(t, c)
	_basin(t)
	_poor_quarter(t, c)
	_decor(t)
	_reach(t)
	City.use(&"aldermere")


## Aldermere hands back the countryside data the floor and decor used to hardcode, unchanged and in order.
static func _aldermere_data(t) -> void:
	City.use(&"aldermere")
	var a := City.current()
	t.check(a.trails() == TownLayout.TRAILS, "Aldermere's meadow trails")
	var roads_ok := a.road_trails().size() == TownLayout.ROAD_TRAILS.size()
	for i in mini(a.road_trails().size(), TownLayout.ROAD_TRAILS.size()):
		var r: Dictionary = a.road_trails()[i]
		roads_ok = roads_ok and r.points == TownLayout.ROAD_TRAILS[i] and is_equal_approx(r.width, 0.5)
	t.check(roads_ok, "Aldermere's road trails, 0.5 wide")
	t.check(a.outcrops() == TownLayout.OUTCROPS, "Aldermere's rocky outcrops")
	t.check(a.boats() == _points(TownLayout.BOATS), "Aldermere's rowing boats")
	t.check(a.scarecrows() == _points(TownLayout.SCARECROWS), "Aldermere's scarecrows")
	t.check(a.signposts() == _points(TownLayout.SIGNPOSTS), "Aldermere's signposts")
	t.check(a.carts() == _points(TownLayout.CARTS), "Aldermere's carts")
	var ros := a.rosettes()
	t.check(ros.size() == 2 and ros[0].at == Vector2(2.7, 12.55) and is_equal_approx(ros[0].radius, 1.49)
		and ros[0].along_y and ros[1].at == Vector2(12.2, 9.9) and is_equal_approx(ros[1].radius, 1.3)
		and not ros[1].along_y and is_equal_approx(ros[1].across, 9.0)
		and is_equal_approx(ros[0].across, TownLayout.GATE_PLAZAS[0].get_center().x), "Aldermere's two rosettes and ruts")
	t.check(a.floor_areas().get(&"crossings") == ([TownLayout.BRIDGE] as Array[Rect2]), "Aldermere's bank gap: its bridge")
	# The forest's road gaps, derived from the roads, are the two Aldermere had hardcoded (east road y 9, south road
	# x 2.7, each 1.5 either side, beyond the walls), on a fine grid between the floor's cell centres (off the gaps' own
	# edges, where the old strict test and Rect2.has_point() part by a float's rounding).
	var gaps := a.forest_gaps()
	var t_r := a.town()
	var same := true
	var g := Vector2(-33.8125, -33.8125)
	while g.y < 34.0:
		g.x = -33.8125
		while g.x < 34.0:
			var old := (g.x > t_r.end.x and absf(g.y - 9.0) < 1.5) or (g.y > t_r.end.y and absf(g.x - 2.7) < 1.5)
			var out := maxf(maxf(t_r.position.x - g.x, g.x - t_r.end.x), maxf(t_r.position.y - g.y, g.y - t_r.end.y))
			# Only where the ring could be forest: past the walls, short of its far rim, north of the river.
			if out > 1.5 and out < TownFloor.FOREST_OUT + 1.5 and g.y <= TownLayout.RIVER.position.y:
				same = same and old == _in_any(gaps, g)
			g.x += 0.125
		g.y += 0.125
	t.check(same, "Aldermere's forest gaps follow its two outside roads exactly")


static func _capital_data(t, c: CapitalCity) -> void:
	City.use(&"capital")
	t.check(c.trails() != TownLayout.TRAILS and c.outcrops() != TownLayout.OUTCROPS, "the capital has its own trails and outcrops")
	var wet := not c.boats().is_empty()
	for b: Vector2 in c.boats():
		var on_bridge := false
		for d: Dictionary in c.structures():
			on_bridge = on_bridge or (d.kind == Structure.Kind.BRIDGE and (d.rect as Rect2).grow(0.6).has_point(b))
		wet = wet and _in_any(c.rivers(), b) and not on_bridge
	t.check(wet, "the capital's boats float on its river and basin, clear of the bridges and piers")
	t.check(c.rosettes().is_empty() or c.rosettes().size() <= c.floor_areas()[&"gate_plazas"].size(), "rosettes fit")
	# Every outside road is painted: the street rects beyond both rings lie under a road trail (a bridge paves its own).
	var unpainted: Array = []
	var decks: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if d.kind == Structure.Kind.BRIDGE:
			decks.append(d.rect)
	for r: Rect2 in c.roads():
		var along_y := r.size.y > r.size.x
		var steps := int((r.size.y if along_y else r.size.x) / 0.5)
		for k in steps + 1:
			var p := Vector2(r.get_center().x, r.position.y + k * 0.5) if along_y else Vector2(r.position.x + k * 0.5, r.get_center().y)
			if not c.map().grow(-0.3).has_point(p) or c.landmark(&"old_town_wall").grow(0.8).has_point(p) \
					or c.landmark(&"new_town_wall").grow(0.8).has_point(p) or _in_any(c.rivers(), p) or _in_any(decks, p):
				continue
			var painted := false
			for tr: Dictionary in c.road_trails():
				painted = painted or TownFloor._near_polyline(p, tr.points, tr.width * 0.85)
			if not painted:
				unpainted.append(p)
	t.check(unpainted.is_empty(), "every road outside the walls is painted (%d bare: %s)" % [unpainted.size(), unpainted.slice(0, 4)])
	t.check(c.road_trails().size() >= 7, "dirt roads to the barbican, the west gate, the harbour, the farms and the monastery")
	# Nothing of the countryside on a building, the water or a street.
	var solid: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if not d.kind in Structure.WALKABLE:
			solid.append(d.rect)
	var bad: Array = []
	for o: Array in c.outcrops():
		for s: Rect2 in solid:
			if s.grow(o[1]).has_point(o[0]):
				bad.append(o[0])
	for tr: Array in c.trails():
		for p: Vector2 in tr:
			if _in_any(c.rivers(), p) or _in_any(solid, p) or c.town().grow(0.8).has_point(p):
				bad.append(p)
	for p: Vector2 in c.scarecrows() + c.signposts() + c.carts():
		if _in_any(c.rivers(), p) or _in_any(solid, p) or _in_any(c.roads(), p):
			bad.append(p)
	t.check(bad.is_empty(), "the capital's outcrops, trails, scarecrows, signposts and carts stand clear (%s)" % [bad])
	# The forest keeps off the outside roads and the harbour.
	var floor := TownFloor.new()
	var wooded: Array = []
	for r: Rect2 in c.roads():
		if c.town().encloses(r):
			continue
		for k in 21:
			var q := r.position + r.size * Vector2(float(k) / 20.0, 0.5) if r.size.x > r.size.y \
				else r.position + r.size * Vector2(0.5, float(k) / 20.0)
			if c.town().has_point(q):
				continue
			if floor._forest(q) or TownDecor._forest(q):
				wooded.append(q)
	var harbour := c.landmark(&"harbour_district")
	for k in 200:
		var q := harbour.position + harbour.size * Vector2(ArtKit.hash01(k, 1), ArtKit.hash01(k, 2))
		if floor._forest(q) or TownDecor._forest(q):
			wooded.append(q)
	t.check(wooded.is_empty(), "no forest on the capital's outside roads or in the harbour (%d: %s)" % [wooded.size(), wooded.slice(0, 4)])
	floor.free()
	t.check(c.floor_areas().get(&"crossings", []).size() == 3, "the capital's banks part at its three bridges")


## The harbour basin is shaded as the river is: by distance from its shore (light at the shore, deep in the middle),
## joining the river's bands where they meet, with no proportional steps.
static func _basin(t) -> void:
	City.use(&"capital")
	var river := City.current().landmark(&"river")
	t.check(TownFloor._water_band(Vector2(21.9, 6.3)) == TownFloor._water_band(Vector2(22.1, 6.3)),
		"the basin's shore band meets the river's")
	t.check(TownFloor._water_band(Vector2(22.3, 0.0)) == 0, "light water along the basin's west quay")
	t.check(TownFloor._water_band(Vector2(30.0, -1.7)) == 0, "light water along the basin's north quay")
	t.check(TownFloor._water_band(Vector2(31.0, 8.0)) == 2, "deep water in the basin's middle")
	t.check(TownFloor._water_band(Vector2(0.0, river.position.y + 0.3)) == 0
		and TownFloor._water_band(Vector2(0.0, river.get_center().y)) == 2, "the river keeps its own bands")
	# The basin reaches the map's east edge, so it runs on to the drawn area's edge as the river does.
	t.check(TownFloor._water_band(Vector2(41.0, 3.0)) >= 0, "the basin runs on past the map's edge")
	t.check(TownFloor._water_band(Vector2(10.0, 0.0)) == -1, "dry land is no water")


## The poor quarter's cottages are not a rigid lattice: their rows and gaps vary.
static func _poor_quarter(t, c: CapitalCity) -> void:
	var area := c.landmark(&"poor_quarter")
	var ys := {}
	var gaps := {}
	var hs: Array[Rect2] = []
	for h: Rect2 in c.houses():
		if area.encloses(h) and h.size == Vector2(0.95, 0.75):
			hs.append(h)
			ys[snappedf(h.position.y, 0.01)] = true
	for a: Rect2 in hs:
		for b: Rect2 in hs:
			if b.position.x > a.end.x and b.position.x - a.end.x < 1.0 and absf(b.position.y - a.position.y) < 0.4:
				gaps[snappedf(b.position.x - a.end.x, 0.01)] = true
	t.check(hs.size() > 20 and ys.size() > hs.size() / 4, "the poor quarter's cottages do not line up in rows (%d rows for %d)" % [ys.size(), hs.size()])
	t.check(gaps.size() >= 5, "the gaps between them vary (%d sizes)" % gaps.size())


## The capital's decor: none inside a building, none on an outside road, a dirt road or the water (bar the boats); the
## street props and gardens are walked round and keep out of the gates' queues.
static func _decor(t) -> void:
	City.use(&"capital")
	var c := City.current()
	var spots := TownDecor.spots()
	var solid: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if not d.kind in Structure.WALKABLE:
			solid.append((d.rect as Rect2).grow(-0.05).abs())
	var inside: Array = []
	var outside: Array = []
	var rings: Array[Rect2] = [c.landmark(&"old_town_wall"), c.landmark(&"new_town_wall")]
	for d: Dictionary in spots:
		var at: Vector2 = d.at
		if _in_any(solid, at):
			inside.append([Decor.Kind.keys()[d.kind], at])
		if _in_any(rings, at):
			continue
		var bad := false
		if Decor.ON_WATER.has(d.kind):
			bad = not _in_any(c.rivers(), at)
		else:
			# (decor hugging a building outside the walls, the harbour's, may stand close by a road, never on it)
			bad = _in_any(c.rivers(), at) or _in_any(c.roads(), at)
			for tr: Dictionary in c.road_trails():
				bad = bad or TownFloor._near_polyline(at, tr.points, tr.width)
		if bad:
			outside.append([Decor.Kind.keys()[d.kind], at])
	t.check(spots.size() > 400, "the capital gets plenty of decor (%d)" % spots.size())
	t.check(inside.is_empty(), "no capital decor stands inside a building (%d: %s)" % [inside.size(), inside.slice(0, 4)])
	t.check(outside.is_empty(), "capital decor outside keeps off the roads and the water (%d: %s)" % [outside.size(), outside.slice(0, 4)])
	var props := c.street_props()
	var gardens := c.gardens()
	t.check(not props.is_empty() and not gardens.is_empty(), "the capital's streets have props and its cottages gardens (%d, %d)" % [props.size(), gardens.size()])
	var blockers := c.blockers()
	var all_in := true
	for p: Dictionary in props:
		all_in = all_in and blockers.has(p.rect)
	for g: Rect2 in gardens:
		all_in = all_in and blockers.has(g)
	t.check(all_in, "people walk round the street props and gardens (blockers)")
	t.check(c.queue_fans().size() == c.floor_areas()[&"gate_plazas"].size(), "a queue fan for every gate")
	var fan_hit := 0
	for p: Dictionary in props:
		fan_hit += 1 if _in_fan(c, p.rect) else 0
	for g: Rect2 in gardens:
		fan_hit += 1 if _in_fan(c, g) else 0
	t.check(fan_hit == 0, "no prop or garden in a gate's queue fan (%d)" % fan_hit)


## Built through the real town, walk grid and crowd: flooding the grid from each exit reaches every exit, every anchor,
## every citizen's and soldier's spawn point, every citizen's home, work and leisure spots, and ground in every
## district of the plan.
static func _reach(t) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var targets: Array = []  # [what, point]
	for e: Vector2 in City.current().exits():
		targets.append(["exit", e])
	var anchors := City.current().anchors()
	for k: String in anchors:
		for g: Vector2 in anchors[k]:
			targets.append(["anchor " + k, g])
	var n_anchor := targets.size() - City.current().exits().size()
	for p: Person in crowd.citizens:
		targets.append(["citizen spawn", p.ground_pos])
		targets.append(["home", p.profile.home])
		if p.profile.works():
			targets.append(["work", p.profile.work])
		for g: Vector2 in p.profile.leisure:
			targets.append(["leisure", g])
	for p: Person in crowd.soldiers:
		targets.append(["soldier spawn", p.ground_pos])
	for st: Vector2 in crowd.routine._stalls:
		targets.append(["errand", st])
	var exits := City.current().exits()
	var all_ok := true
	for e: Vector2 in exits:
		var seen := _flood(grid, grid.nearest_walkable(e))
		var cut: Array = []
		for tg: Array in targets:
			var w := grid.nearest_walkable(tg[1])
			if w == Vector2.INF or not seen.has(grid.world_to_id(w)):
				cut.append("%s %s" % [tg[0], tg[1]])
		var empty: Array = []
		for d: Dictionary in (City.current() as CapitalCity).district_table():
			var r: Rect2 = d.rect
			var any := false
			for id: Vector2i in seen:
				if r.has_point(grid.id_to_world(id)):
					any = true
					break
			if not any:
				empty.append(d.name)
		all_ok = all_ok and cut.is_empty() and empty.is_empty()
		t.check(cut.is_empty(), "from the exit %s every place is reachable (%d targets, %d cut off: %s)"
			% [e, targets.size(), cut.size(), cut.slice(0, 6)])
		t.check(empty.is_empty(), "from the exit %s every district holds reachable ground (%s)" % [e, empty])
	print("capital reachability: %d exits, %d anchors, %d citizens, %d soldiers, %d targets in all; all reachable: %s"
		% [exits.size(), n_anchor, crowd.citizens.size(), crowd.soldiers.size(), targets.size(), all_ok])
	world.free()
	town.free()
	City.use(&"aldermere")


static func _flood(grid: WalkGrid, start: Vector2) -> Dictionary:
	var seen := {}
	if start == Vector2.INF:
		return seen
	var todo: Array[Vector2i] = [grid.world_to_id(start)]
	seen[todo[0]] = true
	while not todo.is_empty():
		var id: Vector2i = todo.pop_back()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := id + step
			if not seen.has(n) and grid.grid.is_in_boundsv(n) and not grid.grid.is_point_solid(n):
				seen[n] = true
				todo.append(n)
	return seen


static func _in_fan(c: CityDef, r: Rect2) -> bool:
	var poly := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	for fan in c.queue_fans():
		if not Geometry2D.intersect_polygons(poly, fan).is_empty():
			return true
	return false


static func _in_any(rects: Array, g: Vector2) -> bool:
	for r: Rect2 in rects:
		if r.has_point(g):
			return true
	return false


static func _points(src: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.assign(src)
	return out
