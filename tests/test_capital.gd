extends RefCounted
## The capital's geography (Task 6): its map, the river and the harbour basin, the three bridges, the two closed wall
## rings with their gatehouses, the roads, the districts of the spec's §1 table, and that it builds and walks.


static func run(t) -> void:
	var c := City.by_id(&"capital")
	t.check(c is CapitalCity and c.id() == &"capital", "City.by_id builds the CapitalCity")
	var cap := c as CapitalCity
	if cap == null:
		return
	t.check(cap.map() == Rect2(-40, -40, 80, 80), "the capital's map is 80x80")
	_water(t, cap)
	_bridges(t, cap)
	_walls(t, cap)
	_roads(t, cap)
	_districts(t, cap)
	_floor(t, cap)
	_builds(t)
	_sandbox(t)
	var title := FileAccess.get_file_as_string("res://src/game/ui/title_screen.gd")
	t.check(title.contains("City.use(&\"aldermere\")") and title.find("City.use(&\"aldermere\")") < title.find("Town.new()"),
		"the title screen's backdrop is always Aldermere")
	City.use(&"aldermere")


## The bench's capital mission (Task 13 stub; Task 15 finishes it): reached by id, played in the capital, every power,
## and kept off the board and the campaign.
static func _sandbox(t) -> void:
	var m := MissionBook.get_mission(MissionBook.CAPITAL_SANDBOX)
	t.check(m.id == MissionBook.CAPITAL_SANDBOX and m.city == &"capital" and m.pool.is_empty(),
		"capital_sandbox is a mission in the capital with every power")
	var listed := false
	for d: MissionDef in MissionBook.all() + MissionBook.campaign_missions():
		listed = listed or d.id == MissionBook.CAPITAL_SANDBOX
	t.check(not listed and not TierBook.has(MissionBook.CAPITAL_SANDBOX),
		"capital_sandbox is dev-only: not on the board or in the campaign")


static func _water(t, c: CapitalCity) -> void:
	var rivers := c.rivers()
	t.check(rivers == ([Rect2(-40, 6, 80, 6), Rect2(22, -2, 18, 20)] as Array[Rect2]), "the river band and the harbour basin")
	for r: Rect2 in rivers:
		t.check(c.map().encloses(r), "%s lies inside the map" % r)
	t.check(c.landmark(&"river") == Rect2(-40, 6, 80, 6) and c.landmark(&"harbour") == Rect2(22, -2, 18, 20),
		"river and harbour landmarks")


## Three bridges, as BRIDGE structures at x≈-14 and x≈4 (stone) and x≈14 (the footbridge set, laid in spans), each
## crossing the whole river band: on the bridge or in the gatehouse it lands at, all the way over.
static func _bridges(t, c: CapitalCity) -> void:
	var river := c.landmark(&"river")
	var by_x := {}
	var gates: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if d.kind == Structure.Kind.BRIDGE and d.role == &"bridge":
			var x := roundi((d.rect as Rect2).get_center().x)
			if not by_x.has(x):
				by_x[x] = []
			by_x[x].append(d)
		elif d.kind == Structure.Kind.GATE:
			gates.append(d.rect)
	t.check(by_x.keys() == [-14, 4, 14], "three bridges, at x -14, 4 and 14 (got %s)" % [by_x.keys()])
	var want := {-14: &"stone", 4: &"stone", 14: &"gpt_footbridge"}
	for x: int in by_x:
		var tags_ok := true
		for d: Dictionary in by_x[x]:
			tags_ok = tags_ok and d.tag == want.get(x, &"")
		t.check(tags_ok, "the bridge at x %d is %s" % [x, want.get(x, &"")])
		var crosses := true
		var y := river.position.y - 0.5
		while y <= river.end.y + 0.5:
			var p := Vector2(float(x), y)
			var on := false
			for d: Dictionary in by_x[x]:
				on = on or (d.rect as Rect2).has_point(p)
			for g: Rect2 in gates:
				on = on or g.has_point(p)
			crosses = crosses and on
			y += 0.1
		t.check(crosses, "the bridge at x %d crosses the river band from gate to gate" % x)
	var dock := c.landmark(&"dock")
	t.check(dock.intersects(c.landmark(&"harbour")) and c.exits().has(CapitalCity.FERRY_LANDING),
		"the ferry pier reaches into the basin and its landing is an exit")


## Each ring is closed: its wall band's centre line is covered all the way round by its walls, towers and gatehouses;
## and its gates stand where the plan has them. Built with TownLayout's own ring code.
static func _walls(t, c: CapitalCity) -> void:
	var structs := c.structures()
	var rings := [[CapitalCity.INNER, CapitalCity.INNER_GATES], [CapitalCity.OUTER, CapitalCity.OUTER_GATES]]
	t.check(CapitalCity.INNER == Rect2(-24, -30, 42, 34) and CapitalCity.OUTER == Rect2(-30, 12, 52, 22), "the two rings' rects")
	for ring: Array in rings:
		var rect: Rect2 = ring[0]
		var pieces: Array[Rect2] = []
		var gates: Array[Rect2] = []
		for d: Dictionary in structs:
			if d.kind in [Structure.Kind.CASTLE_WALL, Structure.Kind.KEEP, Structure.Kind.GATE] \
					and rect.grow(1.5).intersects(d.rect) and not rect.grow(-1.5).encloses(d.rect):
				pieces.append(d.rect)
				if d.kind == Structure.Kind.GATE:
					gates.append(d.rect)
		var m := TownLayout.WALL_T * 0.5
		var inner := rect.grow(-m)
		var corners := [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
		var gaps := 0
		for k in 4:
			var a: Vector2 = corners[k]
			var b: Vector2 = corners[(k + 1) % 4]
			var n := int(a.distance_to(b) / 0.2)
			for i in n + 1:
				var p := a.lerp(b, float(i) / n)
				var covered := false
				for r: Rect2 in pieces:
					covered = covered or r.grow(0.01).has_point(p)
				if not covered:
					gaps += 1
		t.check(gaps == 0, "the ring %s is closed (%d gaps)" % [rect, gaps])
		var points: Array = ring[1]
		t.check(gates.size() == points.size(), "the ring %s has its %d gatehouses (got %d)" % [rect, points.size(), gates.size()])
		for at: Vector2 in points:
			var found := false
			for g: Rect2 in gates:
				found = found or g.get_center().distance_to(at) < 0.6
			t.check(found, "a gatehouse at %s" % at)
	t.check(c.landmark(&"barbican").get_center().distance_to(Vector2(7, 34)) < 0.6, "the south barbican at (7, 34)")
	t.check(c.landmark(&"west_gate").get_center().distance_to(Vector2(-24, -13)) < 0.6, "the west gate at (-24, -13)")
	# The ring code is shared: Aldermere's walls are ring_walls() round its TOWN with its own gates.
	t.check(TownLayout.walls() == TownLayout.ring_walls(TownLayout.TOWN, TownLayout.ROADS,
		TownLayout._rect_array(TownLayout.GATE_TOWERS), TownLayout._rect_array([TownLayout.MAIN_GATE, TownLayout.SIDE_GATE]),
		TownLayout.TOWER_AT), "Aldermere's walls come from the shared ring code")
	# No wall piece or tower stands on a road except where a gatehouse lets it through.
	var on_road := 0
	for d: Dictionary in structs:
		if d.kind in [Structure.Kind.CASTLE_WALL, Structure.Kind.KEEP]:
			for road: Rect2 in c.roads():
				if road.intersects(d.rect):
					on_road += 1
	t.check(on_road == 0, "no wall or tower stands on a road (%d)" % on_road)
	var overlaps := 0
	for i in structs.size():
		for j in range(i + 1, structs.size()):
			# Butting wall pieces meet within float error (as Aldermere's do): only a real overlap counts.
			var o := (structs[i].rect as Rect2).intersection(structs[j].rect)
			if o.size.x > 0.001 and o.size.y > 0.001:
				overlaps += 1
	t.check(overlaps == 0, "no two capital structures overlap (%d)" % overlaps)


static func _roads(t, c: CapitalCity) -> void:
	var roads := c.roads()
	var lines := c.road_lines()
	t.check(lines.size() == CapitalCity.AVENUES.size() + CapitalCity.LANES.size() and lines.size() >= 8,
		"avenues and lanes as polylines (%d)" % lines.size())
	var avenues := 0
	var lanes := 0
	for l: Dictionary in lines:
		avenues += 1 if l.width == 2.0 else 0
		lanes += 1 if l.width == 1.0 else 0
	t.check(avenues >= 4 and lanes >= 4, "2-cell avenues and 1-cell lanes (%d, %d)" % [avenues, lanes])
	var all_in := true
	for r: Rect2 in roads:
		all_in = all_in and c.map().encloses(r) and r.has_area()
	t.check(all_in, "every street rect lies in the map")
	var exits := c.exits()
	t.check(exits.size() == 3, "three exits: the south road, the west road, the ferry")
	for e: Vector2 in exits:
		var on := false
		for r: Rect2 in roads:
			on = on or r.grow(0.6).has_point(e)
		t.check(on and c.map().has_point(e), "exit %s is on a road, in the map" % e)


static func _districts(t, c: CapitalCity) -> void:
	# Spec §1, as (x0, y0, x1, y1).
	var spec := {
		&"royal_keep": [-8, -30, 8, -21], &"noble_quarter": [-24, -21, -9, -9], &"cathedral_square": [-9, -21, 8, -9],
		&"guild_quarter": [8, -21, 18, -9], &"great_market": [-24, -9, -2, 4], &"old_town_houses": [-2, -9, 18, 4],
		&"harbour_district": [18, -22, 40, -2], &"crafts_quarter": [-30, 12, -8, 22], &"new_town": [-8, 12, 10, 22],
		&"tanners_dyers": [10, 12, 22, 22], &"poor_quarter": [-30, 22, -4, 34], &"road_quarter": [-4, 22, 22, 34],
		&"monastery_hill": [-40, -40, -24, -12], &"northern_woods": [14, -40, 40, -22], &"west_farms": [-40, 12, -30, 40],
		&"south_east_fields": [22, 18, 40, 40], &"suburbs": [-30, 34, 6, 40], &"tournament_field": [6, 34, 22, 40],
	}
	var table := c.district_table()
	t.check(table.size() == spec.size(), "every area of the plan (%d)" % table.size())
	for row: Dictionary in table:
		var s: Array = spec.get(row.name, [])
		var want := Rect2(s[0], s[1], s[2] - s[0], s[3] - s[1]) if s.size() == 4 else Rect2()
		t.check(row.rect == want, "district %s matches the spec (%s)" % [row.name, row.rect])
		t.check(c.landmark(row.name) == row.rect, "district %s is a landmark" % row.name)
	var walled := 0
	for row: Dictionary in table:
		if row.kind == &"old_town":
			t.check(CapitalCity.INNER.encloses(row.rect), "%s lies in the old town's ring" % row.name)
			walled += 1
		elif row.kind == &"new_town":
			t.check(CapitalCity.OUTER.encloses(row.rect), "%s lies in the new town's ring" % row.name)
			walled += 1
	t.check(walled == 11, "eleven walled districts (%d)" % walled)
	# districts() is the floor's house blocks: the walled districts less their streets.
	var blocks := c.districts()
	var ok := blocks.size() >= walled
	for b: Rect2 in blocks:
		var inside := false
		for row: Dictionary in table:
			inside = inside or (row.kind != &"outside" and (row.rect as Rect2).encloses(b))
		ok = ok and inside
		for road: Rect2 in c.roads():
			ok = ok and not road.intersects(b)
	t.check(ok, "the house blocks lie in the walled districts, clear of every street (%d blocks)" % blocks.size())


static func _floor(t, c: CapitalCity) -> void:
	var a := c.floor_areas()
	for k: StringName in [&"plazas", &"yards", &"gate_plazas", &"building_yards", &"farm"]:
		t.check(a.has(k), "floor area %s" % k)
	var paved: Array = a.get(&"paved", [])
	t.check(paved.size() == 1 and CapitalCity.OUTER.encloses(paved[0]) and (paved[0] as Rect2).get_area() > 900.0,
		"the new town's ring is cobbled like the old town's")
	t.check(not AldermereCity.new().floor_areas().has(&"paved"), "Aldermere has no extra paved ground")
	var plazas: Array = a.get(&"gate_plazas", [])
	t.check(plazas.size() == CapitalCity.INNER_GATES.size() + CapitalCity.OUTER_GATES.size(), "a gate plaza at every gate")
	var clear := true
	for p: Rect2 in plazas:
		for d: Dictionary in c.structures():
			clear = clear and not (d.rect as Rect2).intersects(p)
	t.check(clear, "the gate plazas are open ground")
	var torches := c.torches()
	t.check(torches.size() == 4 + 2 * plazas.size(), "four market torches, two inside every gate (%d)" % torches.size())
	t.check(c.anchors().has("stall") and c.anchors().has("home"), "anchors carry every key")


## The capital builds through the real town, walk grid and crowd, and the river is crossed only at the bridges.
static func _builds(t) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	t.check(env.structures().size() == City.current().structures().size() + town.citadel.parts.size()
		+ City.current().fountains().size() + City.current().wells().size(),
		"every capital structure is built, and the Citadel, the fountains and the wells")
	var keep := City.current().landmark(&"royal_keep")
	var on_hill := true
	for s: Structure in town.citadel.parts:
		on_hill = on_hill and keep.encloses(s.footprint)
	t.check(on_hill, "the Citadel stands on the Royal Keep's hill")
	var foot: Structure = null
	for st: Structure in env.structures():
		if st.kind == Structure.Kind.BRIDGE and st.art_tag == &"gpt_footbridge":
			foot = st
	t.check(foot != null and SpriteArt.name_for(foot) == "gpt_footbridge", "the footbridge draws the gpt_footbridge set")
	var grid := WalkGrid.new().setup(env, town)
	t.check(not grid.walkable(Vector2(-6.0, 9.0)), "the river blocks between the bridges")
	t.check(grid.walkable(Vector2(-14.0, 9.0)) and grid.walkable(Vector2(4.0, 9.0)) and grid.walkable(Vector2(14.0, 9.0)),
		"the three bridges cross it")
	t.check(not grid.walkable(Vector2(-10.0, -29.65)), "the old town's wall blocks")
	# From the market to each map-edge exit, and from the new town back into the old town.
	var market := City.current().landmark(&"market_square").get_center()
	for e: Vector2 in [Vector2(7, 39.6), Vector2(-39.6, -13)]:
		t.check(grid.path(market, e).size() > 0, "a route from the market to the exit %s" % e)
	t.check(grid.path(Vector2(0, 17), Vector2(0, -15)).size() > 0, "a route from the new town to the cathedral square")
	t.check(grid.path(market, CapitalCity.FERRY_LANDING).size() > 0, "a route from the market to the ferry")
	town.free()
	City.use(&"aldermere")
