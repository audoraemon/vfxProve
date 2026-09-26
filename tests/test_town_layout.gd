extends RefCounted
## Aldermere's layout data: counts per role, everything on the map, nothing overlapping, and roads, river,
## barracks yard and Citadel ground kept clear; exits on roads.


static func run(t) -> void:
	var items := TownLayout.structures()
	var counts := {}
	for d in items:
		counts[d.role] = int(counts.get(d.role, 0)) + 1
	var want := {&"house": 71, &"wall": 85, &"tower": 17, &"gate": 2, &"temple": 1, &"barracks": 1, &"bridge": 1,
		&"market": 20, &"farm": 16, &"decor": 153}
	for role in want:
		t.check(counts.get(role, 0) == want[role], "%d x %s (got %d)" % [want[role], role, counts.get(role, 0)])
	t.check(counts.size() == want.size(), "no unexpected roles (%s)" % [counts.keys()])

	# The wall pieces have to tile their run exactly: a gap would be a hole in the wall and an overlap a double
	# thickness, and each has to stay short enough to sort correctly against what stands behind it.
	var tiling: Array[String] = []
	for r: Rect2 in TownLayout.walls():
		var pieces := TownLayout.wall_pieces(r)
		var area := 0.0
		var covered := pieces[0]
		for piece in pieces:
			area += piece.get_area()
			covered = covered.merge(piece)
		if absf(area - r.get_area()) > 0.0001 or not covered.is_equal_approx(r):
			tiling.append("%s -> %d pieces covering %s, area %.4f of %.4f" % [r, pieces.size(), covered, area, r.get_area()])
	t.check(tiling.is_empty(), "every wall run is tiled exactly by its pieces (%s)" % [tiling])
	var longest := 0.0
	for d in items:
		if d.role == &"wall":
			var wr: Rect2 = d.rect
			longest = maxf(longest, maxf(wr.size.x, wr.size.y))
	t.check(longest <= TownLayout.WALL_PIECE + 0.0001, "no wall piece runs longer than WALL_PIECE (%.2f)" % longest)

	var problems: Array[String] = []
	for d in items:
		var r: Rect2 = d.rect
		if not TownLayout.MAP.encloses(r):
			problems.append("off the map: %s %s" % [d.role, r])
		if r.intersects(TownLayout.CITADEL_AREA):
			problems.append("on the Citadel ground: %s %s" % [d.role, r])
		if Structure.WALKABLE.has(d.kind):
			continue
		for road: Rect2 in TownLayout.ROADS:
			if r.intersects(road):
				problems.append("on a road: %s %s" % [d.role, r])
		if r.intersects(TownLayout.RIVER):
			problems.append("in the river: %s %s" % [d.role, r])
		if r.intersects(TownLayout.BARRACKS_YARD):
			problems.append("in the barracks yard: %s %s" % [d.role, r])
	for i in items.size():
		var a: Rect2 = items[i].rect
		for j in range(i + 1, items.size()):
			var b: Rect2 = items[j].rect
			if a.grow(-0.01).intersects(b.grow(-0.01)):
				problems.append("overlap: %s %s / %s %s" % [items[i].role, a, items[j].role, b])
	t.check(problems.is_empty(), "layout problems: %s" % [problems])

	for e: Vector2 in TownLayout.EXITS:
		var on_road := false
		for road: Rect2 in TownLayout.ROADS:
			on_road = on_road or road.has_point(e)
		t.check(on_road and TownLayout.MAP.has_point(e), "exit %s is on a road inside the map" % e)
	var plaza_clear := true
	for d in items:
		for plaza: Rect2 in TownLayout.GATE_PLAZAS:
			if not Structure.WALKABLE.has(d.kind) and (d.rect as Rect2).intersects(plaza):
				plaza_clear = false
	t.check(plaza_clear, "nothing stands on the ground in front of a gate, where the crowd queues")
	var bridge: Rect2 = TownLayout.BRIDGE
	t.check(bridge.position.y < TownLayout.RIVER.position.y and bridge.end.y > TownLayout.RIVER.end.y, "the bridge spans the river")
	t.check(TownLayout.CITADEL_AREA.has_point(TownLayout.CITADEL_ORIGIN), "the Citadel origin is inside its ground")
