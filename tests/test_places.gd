extends RefCounted
## v0.12 Task 2: the mission-facing place API. CityDef names the places a mission reads (landmark(), place(), gate_towers(),
## barns()); Places reads them for the active city and fails loudly on a misspelt name; MissionNeeds lists what each mission
## reads and Places.can_host() asks a town for it. Aldermere answers from TownLayout exactly.

static func run(t) -> void:
	City.use(&"aldermere")
	_aldermere_exact(t)
	_capital(t)
	_has(t)
	_helper(t)
	_needs(t)
	_rescue_gate(t)
	_reads_the_place(t)
	_citadel_gate_walkable(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the places test leaves Aldermere the active city")


static func _rects(src: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.assign(src)
	return out


static func _aldermere_exact(t) -> void:
	var al := City.by_id(&"aldermere")
	t.check(al.landmark(&"fountain") == TownLayout.FOUNTAIN and al.landmark(&"side_gate") == TownLayout.SIDE_GATE,
		"Aldermere's new landmarks are TownLayout's")
	t.check(al.place(&"citadel_gate") == Vector2(-10.5, -7.6) and al.place(&"postern") == TownLayout.POSTERN_AT
		and al.place(&"citadel") == TownLayout.CITADEL_ORIGIN, "Aldermere's places are the literals")
	t.check(al.gate_towers() == _rects(TownLayout.GATE_TOWERS) and al.barns() == _rects(TownLayout.BARNS),
		"Aldermere's gate towers and barns are TownLayout's, in order")
	t.check(al.place(&"nowhere") == Vector2.INF, "an unknown place is INF")
	t.check(al.mission_overrides("tax_collector").is_empty(), "no overrides by default")
	var a := al.gate_towers()
	a.clear()
	t.check(al.gate_towers().size() == TownLayout.GATE_TOWERS.size(), "the lists are fresh copies")
	t.check(City.IDS == [&"aldermere", &"capital"], "City.IDS lists the cities")


static func _capital(t) -> void:
	var c := City.by_id(&"capital")
	t.check(c.place(&"citadel_gate") == CapitalCity.CITADEL_ORIGIN + Vector2(0.0, 2.9) and c.gate_towers().is_empty(),
		"the Capital's Citadel gate, and no gate towers")
	t.check(c.place(&"citadel") == CapitalCity.CITADEL_ORIGIN, "the Capital's citadel")
	t.check(c.landmark(&"fountain") == CapitalCity.FOUNTAINS[0], "the Great Market's fountain")
	t.check(c.landmark(&"side_gate").has_area() and c.landmark(&"side_gate") == c.landmark(&"harbour_gate"), "the harbour gate")
	t.check(c.barns() == _rects(CapitalCity.BARNS), "the Capital's barns")
	t.check(c.place(&"nowhere") == Vector2.INF and c.place(&"postern") == Vector2.INF, "an unknown place is INF")


static func _has(t) -> void:
	var al := City.by_id(&"aldermere")
	var c := City.by_id(&"capital")
	t.check(Places.has(c, &"citadel") and not Places.has(c, &"gate_towers") and Places.has(c, &"taverns:2"), "needs in the Capital")
	t.check(not Places.has(c, &"taverns:9") and not Places.has(c, &"no_such_place"), "too few of a list, an unknown name")
	for n: StringName in [&"temple", &"bell_tower", &"citadel", &"citadel_gate", &"market_square", &"gate_towers", &"barns:4",
			&"fountain", &"taverns:2", &"districts", &"wells", &"fountains"]:
		t.check(Places.has(al, n), "Aldermere has %s" % n)
	for n: StringName in [&"temple", &"bell_tower", &"citadel", &"citadel_gate", &"market_square", &"workshop", &"barns:4"]:
		t.check(Places.has(c, n), "the Capital has %s" % n)


static func _helper(t) -> void:
	City.use(&"aldermere")
	t.check(Places.rect(&"temple") == TownLayout.TEMPLE, "Places.rect reads the active city")
	t.check(Places.at(&"citadel_gate") == Vector2(-10.5, -7.6), "Places.at: a place's point")
	t.check(Places.at(&"temple") == TownLayout.TEMPLE.get_center(), "Places.at: a landmark's centre")
	t.check(Places.point(&"citadel") == TownLayout.CITADEL_ORIGIN, "Places.point")
	t.check(Places.rect(&"nope") == Rect2() and Places.point(&"nope") == Vector2.INF and Places.at(&"nope") == Vector2.INF,
		"a misspelt name answers empty (and prints an error)")
	City.use(&"capital")
	t.check(Places.rect(&"temple") == CapitalCity.CATHEDRAL and Places.point(&"citadel_gate") == Vector2(0.0, -22.6),
		"Places follows the active city")
	City.use(&"aldermere")


static func _needs(t) -> void:
	var al := City.by_id(&"aldermere")
	var c := City.by_id(&"capital")
	t.check(MissionNeeds.of("warning") == PackedStringArray(["temple", "bell_tower"]), "Starfall's needs")
	t.check(MissionNeeds.of("tax_collector") == PackedStringArray(["temple", "bell_tower", "citadel", "citadel_gate", "workshop"]),
		"the Tax Collector's needs")
	t.check(MissionNeeds.of("spoiled_harvest") == PackedStringArray(["citadel", "citadel_gate", "temple"]), "Spoiled Harvest's needs")
	t.check(MissionNeeds.of("lost_lamb") == PackedStringArray(["temple"]), "the Lost Lamb's needs")
	t.check(MissionNeeds.of("first_prayers") == PackedStringArray(["temple", "bell_tower", "market_square"]), "First Prayers' needs")
	t.check(MissionNeeds.TABLE.has("capital_sandbox") and MissionNeeds.of("capital_sandbox").is_empty(), "the sandbox needs nothing")
	for id: String in ["warning", "tax_collector", "spoiled_harvest", "lost_lamb", "first_prayers", "capital_sandbox"]:
		t.check(Places.can_host(id, al), "Aldermere hosts %s" % id)
		t.check(Places.can_host(id, c), "the Capital has the places %s needs" % id)


## RescueWish's gate is the place, snapped as before: the snapped ground of the literal in Aldermere, the raw point with no grid.
static func _rescue_gate(t) -> void:
	City.use(&"aldermere")
	t.check(RescueWish.gate_point(null) == Vector2(-10.5, -7.6), "the rescue gate with no grid is the place")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var snap := grid.nearest_walkable(Vector2(-10.5, -7.6))
	t.check(snap != Vector2.INF and RescueWish.gate_point(grid) == snap, "the rescue gate is the snapped place (%s)" % snap)
	town.free()


## The code reads the place, not Aldermere's literal (the consts stay as Aldermere's data for Tiers 2-5 and the tests).
static func _reads_the_place(t) -> void:
	for p: String in ["res://src/game/mission/harvest_director.gd", "res://src/game/mission/tax_collector_director.gd",
			"res://src/game/descend/rescue_wish.gd"]:
		var code := PackedStringArray()
		for line: String in FileAccess.get_file_as_string(p).split("\n"):
			code.append(line.get_slice("#", 0))
		var src := "\n".join(code)
		t.check(src.contains("Places.point(&\"citadel_gate\")"), "%s reads the Citadel's gate place" % p.get_file())
		t.check(not src.contains("_walkable(CITADEL_GATE)") and not src.contains("= CITADEL_GATE")
			and not src.contains("nearest_walkable(GATE)"), "%s no longer reads Aldermere's literal in code" % p.get_file())


## The Capital's Citadel gate is walkable ground the Great Market can reach.
static func _citadel_gate_walkable(t) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var gate := Places.point(&"citadel_gate")
	var snap := grid.nearest_walkable(gate)
	t.check(snap != Vector2.INF and snap.distance_to(gate) <= 0.6, "the Capital's Citadel gate is walkable (snaps %s from %s)" % [snap, gate])
	var from := Places.at(&"market_square")
	t.check(not grid.path(from, gate).is_empty(), "the Great Market reaches the Citadel's gate")
	town.free()
	City.use(&"aldermere")
