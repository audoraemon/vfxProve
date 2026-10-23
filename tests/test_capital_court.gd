extends RefCounted
## The Keep's courtyard (capital polish 1): the paved yard inside the old town's north-west walls is filled. The ice
## house and the orchard have left it (the orchard to the west farms, the ice house to the manor's garden by its
## fishpond); its west half is the royal garden (lawn, gravel paths, hedges, flower beds, benches, trees, a fountain,
## the monument and the pavilion), its east half the garrison's drill yard (paved, its practice dummies, barrels, crates
## and a table), where some of the Keep's yard soldiers stand at drill spots facing a dummy. Everything there is walked
## round, its paths and drill spots stay open and reachable.


static func run(t) -> void:
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_moved_out(t, c)
	_garden(t, c)
	_drill(t, c)
	_decor(t, c)
	_aldermere(t)
	_reach_and_face(t)
	City.use(&"aldermere")


static func _plots(c: CapitalCity, tag: StringName) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if d.tag == tag:
			out.append(d.rect)
	return out


## The ice house (a mound house) and the orchard are out of the courtyard: the orchard with the west farms' orchards,
## the ice house in the manor's garden beside the fishpond.
static func _moved_out(t, c: CapitalCity) -> void:
	var court := CapitalCity.KEEP_COURT
	t.check(court.has_area() and c.landmark(&"old_town_wall").encloses(court), "the Keep's courtyard lies inside the old town")
	t.check(c.landmark(&"keep_court") == court and c.landmark(&"royal_garden") == CapitalCity.ROYAL_GARDEN
		and c.landmark(&"drill_yard") == CapitalCity.DRILL_YARD, "the courtyard, garden and drill yard are landmarks")
	t.check(court.encloses(CapitalCity.ROYAL_GARDEN) and court.encloses(CapitalCity.DRILL_YARD)
		and CapitalCity.ROYAL_GARDEN.end.x <= CapitalCity.DRILL_YARD.position.x,
		"the garden is the courtyard's west half, the drill yard its east half")
	t.check(CapitalCity.DRILL_YARD.end.x <= CapitalCity.BARRACKS.position.x
		and CapitalCity.BARRACKS.position.x - CapitalCity.DRILL_YARD.end.x < 1.0, "the drill yard lies next to the barracks")
	var ice := _plots(c, &"gpt_icehouse")
	t.check(ice.size() == 1 and not ice[0].intersects(court) and c.landmark(&"noble_quarter").encloses(ice[0]),
		"the ice house has left the courtyard for the noble quarter (%s)" % [ice])
	var pond := _plots(c, &"gpt_fishpond")
	t.check(not ice.is_empty() and not pond.is_empty() and ice[0].grow(1.0).intersects(pond[0]),
		"the ice house stands by the fishpond")
	var orchards := _plots(c, &"gpt_orchard")
	var in_court := 0
	var west := 0
	for r: Rect2 in orchards:
		in_court += 1 if r.intersects(court) else 0
		west += 1 if c.landmark(&"west_farms").encloses(r) else 0
	t.check(in_court == 0 and west == 3, "no orchard in the courtyard; three in the west farms (%d, %d)" % [in_court, west])


## The garden: its lawn and gravel paths on the floor, a fountain at their crossing, the monument at the head of its
## north path and the pavilion in a corner, all inside it.
static func _garden(t, c: CapitalCity) -> void:
	var g := CapitalCity.ROYAL_GARDEN
	var areas := c.floor_areas()
	var lawns: Array = areas.get(&"lawns", [])
	t.check(lawns.size() == 1 and (lawns[0] as Rect2).encloses(g.grow(-0.01)), "the garden is laid to lawn")
	var paths: Array = areas.get(&"paths", [])
	var inside := not paths.is_empty()
	for p: Dictionary in paths:
		for q: Vector2 in p.points:
			inside = inside and CapitalCity.KEEP_COURT.has_point(q)
		inside = inside and float(p.width) > 0.0 and float(p.width) <= 0.5
	t.check(inside and paths.size() >= 2, "gravel paths cross it (%d)" % paths.size())
	var fountain := 0
	for f: Rect2 in c.fountains():
		fountain += 1 if g.encloses(f) else 0
	t.check(fountain == 1, "a fountain stands in the garden")
	var water: Array = c.anchors().get("water", [])
	var drawn := false
	for w: Vector2 in water:
		drawn = drawn or g.has_point(w)
	t.check(not drawn, "the townsfolk do not fetch water from the royal garden's fountain")
	for tag: StringName in [&"gpt_monument", &"gpt_pavilion"]:
		var r := _plots(c, tag)
		t.check(r.size() == 1 and g.encloses(r[0]), "the %s stands in the garden (%s)" % [tag, r])


## The drill yard: paved (no lawn, no path), the drill spots in it, each facing a practice dummy (a scarecrow: there is
## no dummy set), and the drill spots are the last of the Keep's yard posts.
static func _drill(t, c: CapitalCity) -> void:
	var y := CapitalCity.DRILL_YARD
	for l: Rect2 in c.floor_areas().get(&"lawns", []):
		t.check(not l.intersects(y), "the drill yard stays paved")
	var dummies: Array[Vector2] = []
	for d: Dictionary in c.court_decor():
		if d.kind == Decor.Kind.SCARECROW:
			dummies.append(d.at)
	t.check(dummies.size() >= 3, "practice dummies stand in the drill yard (%d)" % dummies.size())
	var spots := c.drill_spots()
	t.check(spots.size() >= 6, "drill spots (%d)" % spots.size())
	var ok := true
	for s: Dictionary in spots:
		ok = ok and y.has_point(s.at) and s.face in dummies and (s.at as Vector2).distance_to(s.face) > 1.0
	for g: Vector2 in dummies:
		ok = ok and y.has_point(g)
	t.check(ok, "every drill spot lies in the drill yard and faces a dummy")
	var yard: Array = c.soldier_posts().yard
	var tail := yard.slice(yard.size() - spots.size())
	var same := yard.size() >= spots.size()
	for k in spots.size():
		same = same and tail[k] == spots[k].at
	t.check(same, "the drill spots are the last of the Keep's yard posts")
	t.check(yard.size() == CapitalCity.POSTS_YARD, "the yard still posts %d" % CapitalCity.POSTS_YARD)


## The courtyard's decor: what batch 4 has (hedges as bushes, flower beds, benches, garden trees; barrels, crates, a
## table, dummies as scarecrows), each walked round (a blocker), none on a path, a drill spot or a building; and the town
## decor carries it.
static func _decor(t, c: CapitalCity) -> void:
	var court := c.court_decor()
	var kinds := {}
	for d: Dictionary in court:
		kinds[d.kind] = int(kinds.get(d.kind, 0)) + 1
	var g := CapitalCity.ROYAL_GARDEN
	var yd := CapitalCity.DRILL_YARD
	var in_garden := {}
	var in_yard := {}
	for d: Dictionary in court:
		if g.has_point(d.at):
			in_garden[d.kind] = true
		elif yd.has_point(d.at):
			in_yard[d.kind] = true
	for k: Decor.Kind in [Decor.Kind.BUSH, Decor.Kind.FLOWERS, Decor.Kind.BENCH, Decor.Kind.OAK]:
		t.check(in_garden.has(k), "the garden has %s" % Decor.Kind.keys()[k])
	for k: Decor.Kind in [Decor.Kind.SCARECROW, Decor.Kind.BARREL, Decor.Kind.CRATES]:
		t.check(in_yard.has(k), "the drill yard has %s" % Decor.Kind.keys()[k])
	t.check(kinds.get(Decor.Kind.BUSH, 0) >= 10, "hedges line the garden (%d bushes)" % kinds.get(Decor.Kind.BUSH, 0))
	var blockers := c.blockers()
	var walked_round := true
	for d: Dictionary in court:
		var hit := false
		for b: Rect2 in blockers:
			hit = hit or b.has_point(d.at)
		walked_round = walked_round and hit
	t.check(walked_round, "people walk round every courtyard piece (each in a blocker)")
	var on_path := []
	for b: Rect2 in c.court_blockers():
		for p: Dictionary in c.floor_areas().get(&"paths", []):
			var pts: Array = p.points
			for k in pts.size() - 1:
				if _seg_hits(pts[k], pts[k + 1], b.grow(0.2)):
					on_path.append(b)
		for s: Dictionary in c.drill_spots():
			if b.grow(0.3).has_point(s.at):
				on_path.append(b)
		for st: Dictionary in c.structures():
			if (st.rect as Rect2).intersects(b):
				on_path.append(b)
		for f: Rect2 in c.fountains():
			if f.intersects(b):
				on_path.append(b)
	t.check(on_path.is_empty(), "no courtyard piece stands on a path, a drill spot or a building (%s)" % [on_path.slice(0, 4)])
	City.use(&"capital")
	# (goods standing close together merge into one pile node: its parts)
	var flat: Array[Dictionary] = []
	for s: Dictionary in TownDecor.spots():
		flat.append(s)
		for part: Dictionary in s.get("parts", []):
			flat.append(part)
	var carried := 0
	for d: Dictionary in court:
		for s: Dictionary in flat:
			if s.kind == d.kind and (s.at as Vector2).is_equal_approx(d.at):
				carried += 1
				break
	t.check(carried == court.size(), "the town's decor carries every courtyard piece (%d of %d)" % [carried, court.size()])
	City.use(&"aldermere")


static func _seg_hits(a: Vector2, b: Vector2, r: Rect2) -> bool:
	var n := maxi(int(a.distance_to(b) / 0.05), 1)
	for i in n + 1:
		if r.has_point(a.lerp(b, float(i) / n)):
			return true
	return false


## Aldermere has none of it.
static func _aldermere(t) -> void:
	var a := City.by_id(&"aldermere")
	t.check(a.court_decor().is_empty() and a.drill_spots().is_empty() and a.court_blockers().is_empty(),
		"Aldermere has no courtyard decor or drill spots")
	t.check(not a.floor_areas().has(&"lawns") and not a.floor_areas().has(&"paths"), "nor lawns or garden paths")


## Through the real town, walk grid and crowd: the garden's paths and every drill spot can be reached from the south
## road; after a calm spell the drill soldiers stand at their spots, facing their dummies.
static func _reach_and_face(t) -> void:
	City.use(&"capital")
	var c := City.current() as CapitalCity
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var seen: Dictionary = preload("res://tests/test_capital_ground.gd")._flood(grid, grid.nearest_walkable(c.exits()[0]))
	var cut: Array = []
	for p: Dictionary in c.floor_areas().get(&"paths", []):
		var pts: Array = p.points
		for k in pts.size() - 1:
			for f: float in [0.1, 0.5, 0.9]:
				var q: Vector2 = (pts[k] as Vector2).lerp(pts[k + 1], f)
				if not grid.walkable(q) or not seen.has(grid.world_to_id(q)):
					cut.append(q)
	for s: Dictionary in c.drill_spots():
		if not grid.walkable(s.at) or not seen.has(grid.world_to_id(s.at)):
			cut.append(s.at)
	t.check(cut.is_empty(), "the garden's paths and the drill spots are open and reachable (cut %s)" % [cut])
	var field := EnemyField.new()
	field.env = env
	field.bounds = c.map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 7)
	crowd.spawn()
	var drillers: Array[Person] = []
	for p: Person in crowd.soldiers:
		if p.drill_face != Vector2.INF:
			drillers.append(p)
	t.check(drillers.size() == c.drill_spots().size(), "a soldier for every drill spot (%d)" % drillers.size())
	for s in roundi(12.0 * 30.0):
		for p in crowd.citizens + crowd.soldiers:
			if is_instance_valid(p) and not p.inside:
				p.tick(1.0 / 30.0)
		crowd.advance(1.0 / 30.0)
	var facing := 0
	var still := 0
	for p in drillers:
		var d := p.drill_face - p.ground_pos
		if p._facing == (1 if d.x - d.y > 0.0 else -1) and p._back == (d.x + d.y < 0.0):
			facing += 1
		if p.ground_pos.distance_to(p.post) < 0.3:
			still += 1
	t.check(not drillers.is_empty() and facing == drillers.size() and still == drillers.size(),
		"the drill soldiers stand at their spots (%d) facing their dummies (%d of %d)" % [still, facing, drillers.size()])
	var aldermere_like := true
	for p: Person in crowd.soldiers:
		if not p in drillers:
			aldermere_like = aldermere_like and p.drill_face == Vector2.INF
	t.check(aldermere_like, "no other soldier drills")
	crowd.clear()
	world.free()
	town.free()
	City.use(&"aldermere")
