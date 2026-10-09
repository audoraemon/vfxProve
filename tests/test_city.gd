extends RefCounted
## The shared city format: Aldermere through CityDef is exactly TownLayout.

static func run(t) -> void:
	var c := AldermereCity.new()
	t.check(c.id() == &"aldermere", "Aldermere's city id")
	t.check(c.map() == TownLayout.MAP, "map")
	t.check(c.structures() == TownLayout.structures(), "same structures, same order")
	t.check(c.houses() == TownLayout.houses(), "same houses")
	t.check(c.anchors() == TownLayout.anchors(), "same anchors")
	t.check(c.blockers() == TownLayout.blockers(), "same blockers")
	t.check(c.landmark(&"market_square") == TownLayout.MARKET_SQUARE, "market landmark")
	t.check(c.landmark(&"nowhere") == Rect2(), "unknown landmark is empty")
	City.active = null
	t.check(City.current() is AldermereCity, "Aldermere is the default city")
	_landmarks(t, c)
	_lists(t, c)
	_floor_areas(t, c)
	_fresh_copies(t)
	_leak(t)
	_no_hardcoded(t)
	_capital_stub(t)
	_missions_choose(t)
	City.use(&"aldermere")


## Every landmark name Aldermere answers to is the TownLayout constant of that name.
static func _landmarks(t, c: AldermereCity) -> void:
	var want := {
		&"market_square": TownLayout.MARKET_SQUARE, &"temple": TownLayout.TEMPLE,
		&"citadel_court": TownLayout.CITADEL_COURT, &"bell_tower": TownLayout.BELL_TOWER, &"dock": TownLayout.DOCK,
		&"dock_wait": TownLayout.DOCK_WAIT, &"main_gate": TownLayout.MAIN_GATE, &"barracks": TownLayout.BARRACKS,
		&"barracks_yard": TownLayout.BARRACKS_YARD, &"workshop": TownLayout.WORKSHOP, &"smithy": TownLayout.SMITHY,
		&"carpenter": TownLayout.CARPENTER, &"windmill": TownLayout.WINDMILL, &"watermill": TownLayout.WATERMILL,
		&"bridge": TownLayout.BRIDGE, &"fountain_plaza": TownLayout.FOUNTAIN_PLAZA,
		&"carpenter_yard": TownLayout.CARPENTER_YARD, &"tavern_patio": TownLayout.TAVERN_PATIO,
		&"smithy_yard": TownLayout.SMITHY_YARD, &"river": TownLayout.RIVER, &"river_west": TownLayout.RIVER_WEST,
	}
	t.check(AldermereCity.LANDMARKS.size() == want.size(), "every Aldermere landmark is checked")
	for k in AldermereCity.LANDMARKS:
		t.check(want.has(k) and c.landmark(k) == want[k], "landmark %s is TownLayout's" % k)


## The list methods hand back TownLayout's constants, in order.
static func _lists(t, c: AldermereCity) -> void:
	t.check(c.town() == TownLayout.TOWN, "town")
	t.check(c.citadel_origin() == TownLayout.CITADEL_ORIGIN, "citadel origin")
	t.check(c.rivers() == _rects(TownLayout.RIVERS), "rivers")
	t.check(c.roads() == TownLayout.ROADS, "roads")
	t.check(c.exits() == _points(TownLayout.EXITS), "exits")
	t.check(c.districts() == TownLayout.DISTRICTS, "districts")
	t.check(c.fields() == _rects(TownLayout.FIELDS), "fields")
	t.check(c.stalls() == _rects(TownLayout.STALLS), "stalls")
	t.check(c.fountains() == _rects(TownLayout.FOUNTAINS), "fountains")
	t.check(c.wells() == _rects(TownLayout.WELLS), "wells")
	t.check(c.taverns() == _rects(TownLayout.TAVERNS), "taverns")
	t.check(c.pastures() == _rects(TownLayout.PASTURES), "pastures")
	t.check(c.market_piles() == _rects(TownLayout.MARKET_PILES), "market piles")
	t.check(c.torches() == _points(TownLayout.TORCHES), "torches")
	t.check(c.ship_at() == TownLayout.SHIP_AT, "ship")
	t.check(c.gardens() == TownLayout.gardens(), "gardens")
	t.check(c.street_props() == TownLayout.street_props(), "street props")


## floor_areas() is exactly what TownFloor painted from TownLayout before the city format, in the same order.
static func _floor_areas(t, c: AldermereCity) -> void:
	var a := c.floor_areas()
	t.check(a.get(&"plazas") == _rects([TownLayout.MARKET_SQUARE, TownLayout.CITADEL_COURT,
		TownLayout.FOUNTAIN_PLAZA]), "floor plazas: market, citadel court, fountain plaza (flagstones)")
	t.check(a.get(&"yards") == _rects([TownLayout.BARRACKS_YARD]), "floor yards: the barracks yard (sand)")
	t.check(a.get(&"gate_plazas") == _rects(TownLayout.GATE_PLAZAS), "floor gate plazas")
	t.check(a.get(&"farm") == _rects(TownLayout.BARNS + [TownLayout.WINDMILL, TownLayout.WATERMILL]),
		"floor farm: barns, windmill, watermill")
	var yards := _rects([TownLayout.TEMPLE.grow(0.35), TownLayout.SMITHY.grow(0.3), TownLayout.WORKSHOP.grow(0.3),
		TownLayout.CARPENTER.grow(0.3), TownLayout.CARPENTER_YARD.grow(0.2)])
	for tv: Rect2 in TownLayout.TAVERNS:
		yards.append(tv.grow(0.3))
	t.check(a.get(&"building_yards") == yards, "floor building yards, grown as the floor paints them")


## Mutating what City.current() hands back changes neither TownLayout nor the next answer.
static func _fresh_copies(t) -> void:
	City.active = null
	var city := City.current()
	var r := city.rivers()
	r.clear()
	var d := city.districts()
	d[0] = Rect2()
	var s := city.structures()
	s[0].rect = Rect2()
	s.clear()
	var a := city.anchors()
	(a["home"] as Array).clear()
	var p := city.street_props()
	p[0].rect = Rect2()
	var f := city.floor_areas()
	(f[&"plazas"] as Array).clear()
	var e := city.exits()
	e.clear()
	t.check(TownLayout.RIVERS.size() == 2 and city.rivers() == _rects(TownLayout.RIVERS), "rivers stay")
	t.check(TownLayout.DISTRICTS[0] != Rect2() and city.districts() == TownLayout.DISTRICTS, "districts stay")
	t.check(city.structures() == TownLayout.structures() and city.structures()[0].rect != Rect2(), "structures stay")
	t.check(not (city.anchors()["home"] as Array).is_empty() and city.anchors() == TownLayout.anchors(), "anchors stay")
	t.check(TownLayout.street_props()[0].rect != Rect2() and city.street_props() == TownLayout.street_props(),
		"street props stay (TownLayout caches them)")
	t.check((city.floor_areas()[&"plazas"] as Array).size() == 3, "floor areas stay")
	t.check(city.exits().size() == TownLayout.EXITS.size(), "exits stay")
	t.check(City.current() == city, "the same city object")


static func _rects(src: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.assign(src)
	return out


static func _points(src: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.assign(src)
	return out


## A capital build then an Aldermere build gives exactly Aldermere (no state carried over), the floor's cached shrubs too.
static func _leak(t) -> void:
	City.use(&"aldermere")
	var fresh := City.current().structures()
	var shrubs := TownFloor.shrub_spots().duplicate(true)
	City.use(&"capital")
	t.check(City.current().id() == &"capital", "City.use(&\"capital\") makes the capital the active city")
	# The capital's shrubs are its own: none stands where one of Aldermere's does, and each lies in one of its blocks.
	var capital_shrubs := TownFloor.shrub_spots()
	var shared := 0
	var at := {}
	for s: Dictionary in shrubs:
		at[s.at] = true
	var in_blocks := true
	for s: Dictionary in capital_shrubs:
		shared += 1 if at.has(s.at) else 0
		var any := false
		for d: Rect2 in City.current().districts():
			any = any or d.grow(0.5).has_point(s.at)
		in_blocks = in_blocks and any
	t.check(not capital_shrubs.is_empty() and shared == 0, "the capital has none of Aldermere's shrubs (%d shared)" % shared)
	t.check(in_blocks, "every capital shrub lies in one of the capital's house blocks")
	City.use(&"aldermere")
	t.check(City.current().structures() == fresh, "Aldermere rebuilds identically after another city")
	t.check(not shrubs.is_empty() and TownFloor.shrub_spots() == shrubs, "Aldermere's shrubs come back after the capital")


## Shared code reads the active city (City.current()), never Aldermere's TownLayout places. Scans every script under
## the shared folders; a TownLayout read counts unless it is in a comment or names one of GENERIC's city-agnostic
## sizes and helpers (both cities build their walls, gardens and street props with them).
static func _no_hardcoded(t) -> void:
	const DIRS := ["res://src/fx", "res://src/game/crowd", "res://src/game/descend", "res://src/game/town",
		"res://src/environment"]
	const FILES := ["res://src/game/targeting.gd", "res://src/game/mission.gd"]
	# Files allowed to read Aldermere's places, each with its reason.
	const EXCEPT := {
		# The layout itself: Aldermere's constants live here.
		"res://src/game/town/town_layout.gd": "Aldermere's layout",
		# Aldermere's CityDef: answers City.current() from TownLayout.
		"res://src/game/town/cities/aldermere_city.gd": "Aldermere's CityDef",
		# The GPT proof district: built only by the town debug scene, and only in Aldermere (town_debug.gd).
		"res://src/game/town/gpt_showcase.gd": "Aldermere-only dev showcase",
	}
	# City-agnostic sizes and helpers on TownLayout (no Aldermere place): wall thickness and pieces, garden and street
	# prop spacing, the shared ring and gatehouse builders and the prop kinds.
	const GENERIC := ["Prop", "WALL_T", "WALL_TOWER", "GARDEN_CHANCE", "GARDEN_LONG", "GARDEN_GAP",
		"GARDEN_SHORT", "GARDEN_STREET_CLEAR", "STREET_PROP_STEP", "STREET_PROP_GAP", "PROP_SIZE", "_prop_kind",
		"STREET_TREE_JUNCTION", "ring_gatehouse", "ring_structures"]
	var files: Array[String] = []
	for d: String in DIRS:
		_scripts_under(d, files)
	files.append_array(FILES)
	t.check(files.size() > 40, "the guard scans the shared scripts (%d)" % files.size())
	var re := RegEx.create_from_string("TownLayout\\.([A-Za-z_][A-Za-z0-9_]*)")
	for p: String in files:
		if EXCEPT.has(p):
			continue
		var found := PackedStringArray()
		for line: String in FileAccess.get_file_as_string(p).split("\n"):
			var code := line.get_slice("#", 0)
			for m: RegExMatch in re.search_all(code):
				if not m.get_string(1) in GENERIC:
					found.append(m.get_string(1))
		t.check(found.is_empty(), "%s reads no Aldermere places (found %s)" % [p, ", ".join(found)])
	for p: String in EXCEPT:
		t.check(FileAccess.file_exists(p), "the excepted %s exists" % p)


## Every .gd file under `dir`, recursively, into `out`.
static func _scripts_under(dir: String, out: Array[String]) -> void:
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in DirAccess.get_directories_at(dir):
		_scripts_under(dir.path_join(sub), out)


## The capital (CapitalCity, tests/test_capital.gd and tests/test_capital_plots.gd) is made by City.by_id.
static func _capital_stub(t) -> void:
	var c := City.by_id(&"capital")
	t.check(c is CapitalCity and c.id() == &"capital", "the capital's id")
	t.check(not c.houses().is_empty() and not c.taverns().is_empty(), "the capital has its houses and taverns")
	t.check(c.pastures().is_empty() and c.market_piles().is_empty(), "the capital has no pastures or market piles yet")
	t.check(c.ship_at() == Vector2.INF, "the capital has no ship")
	t.check(c.landmark(&"royal_keep").has_point(c.citadel_origin()), "the capital's Citadel stands in the Royal Keep")
	var a := c.floor_areas()
	for k: StringName in [&"plazas", &"yards", &"gate_plazas", &"building_yards", &"farm"]:
		t.check(a.has(k), "the capital's floor area %s" % k)
	t.check(City.by_id(&"aldermere") is AldermereCity, "by_id aldermere")
	# What the powers and wishes read of the active city (the final review): the bell tower (The Bell Lies), the
	# cathedral's steps (Rewrite Priority's worship) and the gates out (Mercy's ways out).
	var al := City.by_id(&"aldermere")
	t.check(al.gate_exits() == [TownLayout.MAIN_GATE.get_center(), TownLayout.SIDE_GATE.get_center(),
		TownLayout.POSTERN_AT], "Aldermere's ways out are its Main Gate, Side Gate and postern")
	t.check(c.landmark(&"bell_tower").has_area() and not (c.anchors().get("cathedral", []) as Array).is_empty(),
		"the capital has a bell tower and cathedral steps")
	var gates := c.structures().filter(func(s: Dictionary) -> bool: return s.kind == Structure.Kind.GATE)
	var out_of_walls := 0
	for e: Vector2 in c.gate_exits():
		for s: Dictionary in gates:
			var g: Rect2 = s.rect
			if g.grow(0.05).has_point(e):
				var past: Vector2 = e + c.gate_outward(g) * 2.0
				if not c.landmark(&"old_town_wall").has_point(past) and not c.landmark(&"new_town_wall").has_point(past):
					out_of_walls += 1
				break
	t.check(c.gate_exits().size() == 3 and out_of_walls == 3,
		"the capital's three ways out are gates opening out of its walls (%d)" % out_of_walls)


## Every mission names its city, Aldermere by default, and the mission and town debug scenes use it before building.
static func _missions_choose(t) -> void:
	t.check(MissionDef.new().city == &"aldermere", "a mission is played in Aldermere by default")
	for m: MissionDef in MissionBook.all() + MissionBook.campaign_missions():
		t.check(m.city == &"aldermere", "%s is played in Aldermere" % m.id)
	var mission := FileAccess.get_file_as_string("res://src/game/mission.gd")
	t.check(mission.contains("City.use(_def.city)") and mission.find("City.use(_def.city)") < mission.find("_town = Town.new()"),
		"Mission uses its def's city before building the town")
	var debug := FileAccess.get_file_as_string("res://src/game/town_debug.gd")
	t.check(debug.contains("--city") and debug.contains("City.use(") and debug.find("City.use(") < debug.find("_town = Town.new()"),
		"town debug takes --city and uses it before building")
