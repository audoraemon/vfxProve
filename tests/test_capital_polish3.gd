extends RefCounted
## Capital polish 3: layout.
##   - The map's edge: a border band of distant country drawn past map() on every side (CityDef.border(), Aldermere's
##     too), the river and its banks carried out through it; the camera never pans the view off the drawn ground; the
##     river's glints stay on the water. Drawing only: no walk grid, structure or decor node.


static func run(t) -> void:
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_border(t)
	_camera(t)
	_glints(t)
	_border_trees(t)
	City.use(&"aldermere")


## Both cities draw a border band about 12 cells deep; a city that says nothing draws none.
static func _border(t) -> void:
	t.check(CityDef.new().border() == 0.0, "a city draws no border band unless it says so")
	for id: StringName in [&"aldermere", &"capital"]:
		City.use(id)
		var city := City.current()
		t.check(city.border() >= 10.0 and city.border() <= 14.0, "%s draws a border band about 12 cells deep (%s)"
			% [id, city.border()])
		t.check(TownFloor.drawn_area() == city.map().grow(city.border()),
			"%s's drawn ground is its map grown by its border" % id)
		# Water touching the map's edge runs on through the band: the floor's detail finds water there, not meadow.
		var river := city.landmark(&"river")
		var mid_y := river.get_center().y
		for x: float in [city.map().position.x - 2.0, city.map().position.x - 8.0, city.map().end.x + 2.0,
				city.map().end.x + 8.0]:
			t.check(TownFloor.wet(Vector2(x, mid_y)), "%s: the river runs on past the map's edge at x %s" % [id, x])
		t.check(not TownFloor.wet(Vector2(0.0, city.map().position.y - 6.0)), "%s: the band north of the map is dry" % id)
		t.check(TownFloor.FILL_MARGIN < city.border(), "%s's border reaches past the old fill" % id)


## The camera never pans the view past the drawn ground at any zoom a player has (the mission's and the town debug's),
## while it can still reach the map's middle and its corners' neighbourhood.
static func _camera(t) -> void:
	var view := Vector2(640, 360)
	for id: StringName in [&"aldermere", &"capital"]:
		City.use(id)
		var outer := TownFloor.drawn_area()
		var limits := Mission.pan_limits()
		var bad := 0
		var probes := 0
		for z: float in [0.3, Mission.ZOOM_MIN, Mission.PLAY_ZOOM, 1.0, Mission.ZOOM_MAX]:
			for i in 21:
				for j in 21:
					var probe := limits.position - Vector2(800, 800) + (limits.size + Vector2(1600, 1600)) \
						* Vector2(i / 20.0, j / 20.0)
					var p := Mission.clamp_view(probe, z, view)
					probes += 1
					var half := view * 0.5 / z
					for corner: Vector2 in [p - half, p + half, p + Vector2(half.x, -half.y), p + Vector2(-half.x, half.y)]:
						if not outer.grow(0.01).has_point(Iso.screen_to_ground(corner)):
							bad += 1
							break
		t.check(probes > 0 and bad == 0, "%s: the view never leaves the drawn ground (%d of %d probes out)" % [id, bad, probes])
		t.check(Mission.clamp_view(Vector2.ZERO, Mission.ZOOM_MIN, view) == Vector2.ZERO,
			"%s: the map's middle stays reachable at the furthest zoom" % id)
		# At play zoom the camera still frames each corner of the map's ground (the map's corner within view).
		var map := City.current().map()
		for c: Vector2 in [map.position, map.end, Vector2(map.position.x, map.end.y), Vector2(map.end.x, map.position.y)]:
			var p := Mission.clamp_view(Iso.ground_to_screen(c), Mission.PLAY_ZOOM, view)
			var half := view * 0.5 / Mission.PLAY_ZOOM
			t.check(Rect2(p - half, half * 2.0).has_point(Iso.ground_to_screen(c)),
				"%s: the map's corner %s can be brought into view" % [id, c])


## The river's glints drift on the drawn water only.
static func _glints(t) -> void:
	for id: StringName in [&"aldermere", &"capital"]:
		City.use(id)
		var off := 0
		var n := 0
		for time: float in [0.0, 3.7, 41.0, 260.5]:
			for r: Rect2 in TownFloor.RiverGlints.glints(time):
				n += 1
				# (a branch glint at its foot runs on onto the main river: still water)
				var wet := TownFloor.wet(r.position) and TownFloor.wet(r.end) \
					and TownFloor.wet(Vector2(r.end.x, r.position.y)) and TownFloor.wet(Vector2(r.position.x, r.end.y))
				if not wet:
					off += 1
		t.check(n > 0 and off == 0, "%s: every glint lies on the drawn water (%d of %d off)" % [id, off, n])


## The band's trees: past the old fill, inside the drawn ground, off the water and the roads; none at all inside.
static func _border_trees(t) -> void:
	for id: StringName in [&"aldermere", &"capital"]:
		City.use(id)
		var city := City.current()
		var fill := city.map().grow(TownFloor.FILL_MARGIN)
		var outer := TownFloor.drawn_area()
		var trees := TownDecor.border_trees()
		var bad := 0
		for d: Dictionary in trees:
			var g: Vector2 = d.at
			if fill.has_point(g) or not outer.has_point(g) or TownFloor.wet(g) or TownFloor.wet(g + Vector2(0.4, 0.4)) \
					or TownFloor.wet(g - Vector2(0.4, 0.4)) or not d.kind in [Decor.Kind.OAK, Decor.Kind.PINE]:
				bad += 1
		t.check(trees.size() > 100 and bad == 0, "%s: %d border trees, %d misplaced" % [id, trees.size(), bad])
		var again := TownDecor.border_trees()
		t.check(again.size() == trees.size() and (again.is_empty() or again[0].at == trees[0].at),
			"%s: the border trees are the same every time" % id)
		var roads := 0
		for d: Dictionary in trees:
			for line: Array in TownFloor.border_roads():
				if TownFloor._near_polyline(d.at, line[0], float(line[1]) + 0.6):
					roads += 1
		t.check(roads == 0, "%s: no border tree on a road carried out through the band (%d)" % [id, roads])
		t.check(not TownFloor.border_roads().is_empty(), "%s: its roads off the map run on through the band" % id)
