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
	_keep_gate(t, c)
	_dummies(t, c)
	_house_mix(t, c)
	City.use(&"aldermere")


## The house blocks' GPT housing sets by district (item 5): patrician houses in the noble quarter and by the Keep,
## shop-houses on the avenues and in the market, shacks and tenements in the poor quarter, plain cottages in the new
## town; each on its own footprint, none overlapping; the count held at HOUSE_FLOOR or more.
static func _house_mix(t, c: CapitalCity) -> void:
	var houses := c.houses()
	t.check(houses.size() >= HOUSE_FLOOR and HOUSE_FLOOR >= 140, "at least %d houses (%d)" % [HOUSE_FLOOR, houses.size()])
	var tag_of := {}
	for d: Dictionary in c.structures():
		if d.role in [&"house", CapitalPlots.ROLE]:
			tag_of[d.rect] = d.tag
	var by := {}
	var fit := true
	var avenues: Array[Rect2] = []
	for line: Array in CapitalCity.AVENUES:
		for k in line.size() - 1:
			var a: Vector2 = line[k]
			var b: Vector2 = line[k + 1]
			avenues.append(Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs()).grow(CapitalCity.AVENUE_W * 0.5))
	var off_avenue := 0
	for h: Rect2 in houses:
		var tag: StringName = tag_of.get(h, &"?")
		var district := _district(c, h)
		var key := "%s/%s" % [district, tag]
		by[key] = int(by.get(key, 0)) + 1
		if String(tag).begins_with("gpt_"):
			fit = fit and (CapitalPlots.SETS[tag][0] as Vector2).is_equal_approx(h.size) and tag in CapitalPlots.HOMES
			if tag == &"gpt_shophouse" and district != &"great_market":
				var near := false
				for r: Rect2 in avenues:
					near = near or r.grow(1.6).intersects(h)
				off_avenue += 0 if near else 1
	t.check(fit, "every GPT house stands on its own footprint and is lived in")
	t.check(int(by.get("noble_quarter/gpt_patrician", 0)) >= 4, "patrician houses in the noble quarter's blocks (%s)" % [by])
	var shops := 0
	var tenements := 0
	for d: Dictionary in c.structures():
		var dn := _district(c, d.rect)
		if d.tag == &"gpt_shophouse" and dn in [&"great_market", &"guild_quarter", &"old_town_houses"]:
			shops += 1
		if d.tag == &"gpt_tenement" and dn == &"poor_quarter":
			tenements += 1
	t.check(shops >= 6 and off_avenue == 0, "shop-houses in the market and on the avenues (%d, %d off an avenue)"
		% [shops, off_avenue])
	t.check(int(by.get("poor_quarter/gpt_shacks", 0)) >= 4 and tenements >= 4,
		"rows of shacks in the poor quarter's blocks among its tenements (%d tenements)" % tenements)
	var plain := true
	for key: String in by:
		if key.begins_with("new_town/"):
			plain = plain and key == "new_town/"
	t.check(plain and int(by.get("new_town/", 0)) > 0, "the new town's blocks hold plain cottages only (%s)" % [by])
	var overlap := 0
	for i in houses.size():
		for j in range(i + 1, houses.size()):
			if houses[i].grow(0.1).intersects(houses[j]):
				overlap += 1
	var others := 0
	for d: Dictionary in c.structures():
		if d.role in [&"house"] or houses.has(d.rect):
			continue
		for h: Rect2 in houses:
			if (d.rect as Rect2).intersects(h):
				others += 1
	t.check(overlap == 0 and others == 0, "no house overlaps another or a building (%d, %d)" % [overlap, others])


## The house count's floor: about 5% under the count, never under 140.
const HOUSE_FLOOR := 143


## The walled district of the plan holding `r`'s middle.
static func _district(c: CapitalCity, r: Rect2) -> StringName:
	for row: Array in CapitalCity.DISTRICT_TABLE:
		if row[2] != &"outside" and (row[1] as Rect2).has_point(r.get_center()):
			return row[0]
	return &""


## The practice dummies stand about a soldier's height (a decor scale: the scarecrow art drawn smaller), in two tidy
## rows in the drill yard, a drilling soldier facing each.
static func _dummies(t, c: CapitalCity) -> void:
	var dummies: Array[Dictionary] = []
	for d: Dictionary in c.court_decor():
		if d.kind == Decor.Kind.SCARECROW:
			dummies.append(d)
	t.check(dummies.size() == 8, "eight practice dummies (%d)" % dummies.size())
	var art: Dictionary = DecorSprites.decor_set("scarecrow")
	var tall: float = (art.size as Vector2).y if not art.is_empty() else 37.0
	var person: float = PeopleArt.cell().y
	var ok := true
	var xs := {}
	for d: Dictionary in dummies:
		var drawn: float = tall * ArtTuning.scale("scarecrow") * float(d.get("scale", 1.0))
		ok = ok and drawn >= person * 0.9 and drawn <= person * 1.35 and CapitalCity.DRILL_YARD.has_point(d.at)
		xs[snappedf((d.at as Vector2).x, 0.01)] = int(xs.get(snappedf((d.at as Vector2).x, 0.01), 0)) + 1
	t.check(ok, "each dummy is drawn about a soldier's height (%.1f px art, a %.0f px cell), in the drill yard"
		% [tall * ArtTuning.scale("scarecrow") * float(dummies[0].get("scale", 1.0)) if not dummies.is_empty() else 0.0, person])
	t.check(xs.size() == 2 and xs.values() == [4, 4], "in two rows of four (%s)" % [xs])
	var spots := c.drill_spots()
	var faced := {}
	var good := true
	var solid := c.court_blockers()
	for s: Dictionary in spots:
		var at: Vector2 = s.at
		var face: Vector2 = s.face
		var gap := face.x - at.x
		good = good and gap >= 1.0 and gap <= 2.0 and is_equal_approx(at.y, face.y) \
			and CapitalCity.DRILL_YARD.has_point(at)
		for b: Rect2 in solid:
			good = good and not b.grow(WalkGrid.BODY).has_point(at)
		faced[face] = true
	t.check(spots.size() == 8 and faced.size() == 8 and good,
		"a drilling soldier stands west of each dummy facing it, in the yard and on open ground (%d spots, %d faced)"
		% [spots.size(), faced.size()])
	# The scale reaches the dummies' decor nodes.
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var scaled := 0
	for dec: Decor in town._decor:
		if dec.kind == Decor.Kind.SCARECROW and CapitalCity.DRILL_YARD.has_point(dec.at) \
				and is_equal_approx(dec.scale_mul, CapitalCity.DUMMY_SCALE):
			scaled += 1
	t.check(scaled == 8, "each dummy's decor node draws at the dummies' scale (%d)" % scaled)
	town.free()


static func _plots(c: CapitalCity, tag: StringName) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d: Dictionary in c.structures():
		if d.tag == tag:
			out.append(d.rect)
	return out


## The Keep's gate and steps are gone (unused sets); the watchtower stands on the Keep's wall line, its guards at its
## foot; a few trees stand on the paving between the Keep and the garden lawn, the drill yard and the royal garden as
## they were.
static func _keep_gate(t, c: CapitalCity) -> void:
	for k: StringName in [&"gpt_barbican", &"gpt_alleysteps"]:
		t.check(_plots(c, k).is_empty() and k in CapitalPlots.UNUSED, "%s is no longer placed, and listed unused" % k)
	t.check(BuildingTypes.PASSAGE.has(&"gpt_barbican") and BuildingTypes.PASSAGE.has(&"gpt_alleysteps"),
		"the passage plumbing stays")
	var tower := _plots(c, &"gpt_watchtower")
	t.check(tower.size() == 1, "one watchtower (%d)" % tower.size())
	if tower.size() != 1:
		return
	var w := tower[0]
	var o := c.citadel_origin()
	var se := Rect2(Citadel.TOWERS[3].position + o, Citadel.TOWERS[3].size)
	var south := Rect2(Citadel.WALLS[1].position + o, Citadel.WALLS[1].size)
	t.check(w.position.y < south.end.y and w.end.y > south.position.y and w.position.x >= se.end.x
		and w.position.x - se.end.x <= 1.0, "the watchtower stands on the Keep's south wall line beside its tower (%s)" % w)
	t.check(c.landmark(&"royal_keep").encloses(w), "in the Royal Keep")
	# No soldier is posted inside it (the Citadel's rally ring passes close by).
	var inside := 0
	var posts := c.soldier_posts()
	for k: String in posts:
		for p: Vector2 in posts[k]:
			if w.grow(WalkGrid.BODY + 0.1).has_point(p):
				inside += 1
	t.check(inside == 0, "no soldier is posted on the watchtower (%d)" % inside)
	var guards := 0
	for p: Vector2 in posts.walls:
		if p.y > w.end.y and p.y < w.end.y + 0.8 and absf(p.x - w.get_center().x) < 1.2:
			guards += 1
	t.check(guards == 2 and c.soldiers() == 180, "the Keep's two guards stand at the watchtower's foot (%d, %d soldiers)"
		% [guards, c.soldiers()])
	# Item 8: trees on the paving south of the Keep, round the watchtower.
	var trees := 0
	var grounds := CapitalCity.KEEP_GROUNDS
	for d: Dictionary in c.court_decor():
		if d.kind in [Decor.Kind.OAK, Decor.Kind.PINE] and grounds.has_point(d.at):
			trees += 1
	t.check(trees >= 3, "a few trees stand on the Keep's paving (%d)" % trees)
	t.check(grounds.encloses(w) and c.landmark(&"royal_keep").grow(0.01).encloses(grounds),
		"the Keep's grounds hold the watchtower, inside the Royal Keep")
	t.check(not grounds.intersects(CapitalCity.DRILL_YARD) and not grounds.intersects(CapitalCity.ROYAL_GARDEN),
		"the drill yard and the royal garden are left as they were")


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
