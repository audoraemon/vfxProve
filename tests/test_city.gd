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
	t.check(TownFloor.shrub_spots().is_empty(), "the (empty) capital has no shrubs of Aldermere's")
	City.use(&"aldermere")
	t.check(City.current().structures() == fresh, "Aldermere rebuilds identically after another city")
	t.check(not shrubs.is_empty() and TownFloor.shrub_spots() == shrubs, "Aldermere's shrubs come back after the capital")


## Shared code reads the active city, never Aldermere's constants (Aldermere-only directors excepted).
static func _no_hardcoded(t) -> void:
	const SHARED := ["res://src/game/town/town.gd", "res://src/game/town/town_floor.gd",
		"res://src/game/town/town_decor.gd", "res://src/game/town/walk_grid.gd",
		"res://src/game/crowd/crowd.gd", "res://src/game/crowd/evacuation_manager.gd",
		"res://src/game/crowd/alarm_manager.gd", "res://src/game/crowd/citizen_profile.gd"]
	for p: String in SHARED:
		var src := FileAccess.get_file_as_string(p)
		var n := src.count("TownLayout.") - src.count("TownLayout.Prop")
		t.check(n == 0, "%s reads no TownLayout constants (found %d)" % [p, n])


## The capital stub answers every CityDef method with empty data, so building it crashes nothing.
static func _capital_stub(t) -> void:
	var c := City.by_id(&"capital")
	t.check(c is CityDef and c.id() == &"capital", "the capital stub's id")
	t.check(c.structures().is_empty() and c.houses().is_empty() and c.taverns().is_empty()
		and c.pastures().is_empty() and c.market_piles().is_empty() and c.torches().is_empty(), "the capital stub is empty")
	t.check(c.ship_at() == Vector2.INF and c.citadel_origin() == Vector2.INF, "the capital stub has no ship, no Citadel")
	var a := c.floor_areas()
	for k: StringName in [&"plazas", &"yards", &"gate_plazas", &"building_yards", &"farm"]:
		t.check(a.has(k) and (a[k] as Array).is_empty(), "the capital stub's floor area %s is empty" % k)
	t.check(City.by_id(&"aldermere") is AldermereCity, "by_id aldermere")


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
