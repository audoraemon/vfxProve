extends RefCounted
## Plan "The Capital at every tier", Task 9: the Festival in the Capital (spec 6.2.2). The Festival is a board act (TierBook._from_act()), not a MissionBook
## mission, so the kit's get_mission() checks are made here on Mission.def_for(). Its director reads Places only: the Capital's overrides
## (src/game/town/cities/capital_missions/festival.gd) are the def's camera and intro, and nothing else. The square (Places.rect(&"market_square")) holds the
## fountain and room for the whole crowd; the intro camera keeps the fountain, the square's heart and the bonfires clear of the padded HUD stack; the
## words are true in the Capital; the policies read Places and the director, no Aldermere coordinate; the capture aid's look-at follows the town.

const ID := "festival"
const Cap := preload("res://tests/capital_kit.gd")
const TIER := 3


static func run(t) -> void:
	City.use(&"aldermere")
	_overrides_valid(t)
	_hostable(t)
	_seeded(t)
	_policy_reads_places(t)
	var cap := Cap.town(&"capital")
	var sq := Places.rect(&"market_square")
	var fountain := Places.at(&"fountain")
	print("CAPITAL festival: square %s centre %s, fountain %s" % [sq, Places.at(&"market_square"), fountain])
	t.check(sq.has_point(fountain), "the fountain %s lies inside the market square %s" % [fountain, sq])
	Cap.spots_land(t, cap, {"square centre": Places.at(&"market_square")})
	var by: Vector2 = (cap.grid as WalkGrid).nearest_walkable(fountain)
	t.check(by != Vector2.INF and by.distance_to(fountain) <= 1.2, "the fountain has ground within 1.2 of it to stand by (%.2f)" % [by.distance_to(fountain) if by != Vector2.INF else -1.0])
	_starts(t, cap)
	Cap.drop(cap)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Festival test leaves Aldermere active")


## The overrides: a def section with the camera and its intro, no director section; they apply cleanly to a fresh board Festival, each with the type of the
## var it sets.
static func _overrides_valid(t) -> void:
	var ov := City.by_id(&"capital").mission_overrides(ID)
	t.check(ov.has("def") and not ov.has("director"), "the Capital has a def section for the Festival and no director section (%s)" % [ov.keys()])
	var def := Mission.def_for(ID, true, null)
	t.check(def != null and def.id == ID and def.director == FestivalDirector, "the board's Festival is the act's def (%s)" % [def.id if def != null else null])
	var bad := Overrides.apply(def, (ov.get("def", {}) as Dictionary).duplicate(true))
	t.check(bad.is_empty(), "the overrides apply cleanly to a fresh board Festival (refused %s)" % [bad])
	var okay := true
	var fresh := Mission.def_for(ID, true, null)
	for key: Variant in ov.get("def", {}):
		okay = okay and typeof(fresh.get(String(key))) == typeof(ov.def[key])
	t.check(okay, "every overridden value has the type of the def var it sets")


## The Capital hosts the Festival: its list has festival@capital, which is the board's Festival in the Capital.
static func _hostable(t) -> void:
	var capital := City.by_id(&"capital")
	t.check(MissionBook.hostable(ID, capital), "the Capital hosts the Festival")
	t.check(MissionBook.town_missions(&"capital").has("%s@capital" % ID), "the Capital's list has festival@capital")
	var m := Mission.def_for("%s@capital" % ID, true, null)
	t.check(m != null and m.id == ID and m.city == &"capital", "festival@capital is the board's Festival, in the Capital")
	t.check(Mission.hosting_error(m, &"capital") == "", "the Capital's hosting check passes for the Festival")
	t.check(Mission.def_for(ID, true, null).city != &"capital", "the board's Festival is Aldermere's until put in the Capital")


## A fresh director has no town var, its numbers are untouched, and Aldermere's own def is unchanged.
static func _seeded(t) -> void:
	var d := FestivalDirector.new()
	t.check(Overrides.town_vars(d).is_empty(), "the Festival has no town vars (%s)" % [Overrides.town_vars(d)])
	t.check(FestivalDirector.FESTIVAL_CROWD == 80 and FestivalDirector.FESTIVAL_NEED == 50 and FestivalDirector.PACK_R == 3.0,
		"FESTIVAL_CROWD, FESTIVAL_NEED and PACK_R are untouched")
	var def := Mission.def_for(ID, true, null)
	t.check(def.camera_at == Places.at(&"market_square") and def.intro_from == Places.at(&"market_square") + Vector2(0.0, 8.0),
		"Aldermere's camera and intro are its square's centre and 8 south of it")


## The director, the policies and the capture aid take their places from Places / the director, not an Aldermere coordinate.
static func _policy_reads_places(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var policy := _slice(bc, "func _play_festival()", "\nfunc ")
	t.check(policy.length() > 1500, "the festival policy (route a) is found and sliced (%d chars)" % policy.length())
	var rb := FileAccess.get_file_as_string("res://tools/dev/routes/tier3_b.gd").replace("\r\n", "\n")
	var b := _slice(rb, "static func act_festival(", "\nstatic func state_festival(") + _slice(rb, "static func _by_square(", "\nstatic func ")
	t.check(b.length() > 1500, "route b's festival functions are found and sliced (%d chars)" % b.length())
	for body: String in [policy, b]:
		t.check(not "TownLayout." in body and not "CAMERA_AT" in body and not "FESTIVAL_LOOK_AT" in body,
			"a festival policy reads no TownLayout coordinate, CAMERA_AT or FESTIVAL_LOOK_AT")
	var dir := FileAccess.get_file_as_string("res://src/game/mission/festival_director.gd").replace("\r\n", "\n")
	t.check(dir.length() > 3000 and not "TownLayout." in dir, "the Festival director names no TownLayout coordinate (%d chars)" % dir.length())
	# The capture aid: --shots looks at Aldermere's literal there and at the square's centre elsewhere.
	var shots := _slice(bc, "func _festival_shots()", "\nfunc ")
	t.check(shots.length() > 400 and "_festival_look_at()" in shots and not "FESTIVAL_LOOK_AT" in shots, "the shots read _festival_look_at(), not the const")
	var look := _slice(bc, "func _festival_look_at()", "\nfunc ")
	t.check(look.length() > 20 and "FESTIVAL_LOOK_AT" in look and "Places.at(&\"market_square\")" in look,
		"_festival_look_at() keeps the const for Aldermere and reads the square elsewhere")
	t.check(bc.find("const FESTIVAL_LOOK_AT := Vector2(1.0, 4.0)") >= 0, "Aldermere's look-at literal is kept")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


static func _starts(t, cap: Dictionary) -> void:
	var d := Cap.starts(t, ID, TIER) as FestivalDirector
	t.check(d != null, "the Festival is set up in the Capital by the god's own def")
	if d == null:
		return
	var def := Mission.def_for("%s@capital" % ID, true, null)
	t.check(def.camera_at == Vector2(-7.5, -2.5) and def.intro_from == Vector2(-7.5, 5.5), "camera_at and intro_from are overridden together (C9)")
	t.check(def.camera_at == Places.at(&"market_square"), "the camera rests on the square's centre %s" % [Places.at(&"market_square")])
	t.check(d.goers.size() == d.crowd_size and d.crowd_size >= FestivalDirector.FESTIVAL_CROWD, "%d goers are gathered (%d)" % [d.crowd_size, d.goers.size()])
	t.check(d.mayor != null, "a Mayor is appointed")
	for at in d.fire_spots:
		var ground: Vector2 = cap.grid.nearest_walkable(at)
		t.check(ground != Vector2.INF and ground.distance_to(at) <= 3.0, "a bonfire spot %s has ground within 3 of it" % [at])
	_crowd_fits(t, d, cap)
	City.use(&"capital")
	_words_true(t, d)


## The square holds its crowd: the crowd's own spot finder (the one _gather() calls, over the square's 0.4 reach) finds 80 walkable goer spots within that
## reach of the centre, and the goers themselves stand there.
static func _crowd_fits(t, d: FestivalDirector, cap: Dictionary) -> void:
	var c := Places.at(&"market_square")
	var reach := Places.rect(&"market_square").size.x * 0.4
	var grid: WalkGrid = cap.grid
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var found := 0
	var seen := {}
	for i in 400:
		var s := d.crowd._spot_near(c, reach, rng)
		if grid.walkable(s) and absf(s.x - c.x) <= reach + 0.01 and absf(s.y - c.y) <= reach + 0.01:
			found += 1
			seen[s.snapped(Vector2(0.25, 0.25))] = true
	t.check(found >= 360, "_spot_near finds walkable goer spots within %.1f of the centre: %d of 400 (need 360)" % [reach, found])
	t.check(seen.size() >= 80, "%d distinct 0.25 spots (need 80)" % seen.size())
	var stand := 0
	for g in d.goers:
		if g.has_goal() and absf(g.goal().x - c.x) <= reach + 0.5 and absf(g.goal().y - c.y) <= reach + 0.5:
			stand += 1
	t.check(stand >= d.goers.size() * 0.9, "the goers' own goals are in the square: %d of %d" % [stand, d.goers.size()])
	print("CAPITAL festival crowd: %d of 400 spots in reach, %d distinct, %d of %d goals in the square" % [found, seen.size(), stand, d.goers.size()])


## No line the player reads names a place of Aldermere or one the Capital lacks: the tour, the brief, the goal and lose lines, the hints.
static func _words_true(t, d: FestivalDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var tour_lines := said.size()
	var def := Mission.def_for("%s@capital" % ID, true, null)
	said.append_array(def.brief)
	said.append_array([def.goal, def.goal_label, def.lose])
	for phase in ["", "packed", "address"]:
		said.append(MissionHints.line(ID, phase))
	t.check(tour_lines >= 1 and said.size() == tour_lines + 2 + 3 + 3 and not String(said[said.size() - 1]).is_empty(), "the Festival's lines are found (%d)" % said.size())
	var wrong := false
	for line in said:
		for place in ["north-east", "cathedral", "workshops", "east tavern", "citadel", "old town", "west quarter", "bell tower"]:
			if place in line.to_lower():
				wrong = true
				print("CAPITAL festival line names '%s': %s" % [place, line])
	t.check(not wrong, "no line names a place of Aldermere or one the Capital lacks (%s)" % [said])
	# What the lines do name, the Capital has: a square and a fountain.
	var all := " ".join(said).to_lower()
	var capital := City.by_id(&"capital")
	t.check("fountain" in all and "square" in all and Places.has(capital, &"fountain") and Places.has(capital, &"market_square"),
		"the lines name the fountain and the square, which the Capital has")
	t.check(d.tour()[0][0] == Places.at(&"fountain"), "the tour's first stop is the fountain, where it stands")


## The fountain, the square's centre, both bonfires and the Mayor are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := Mission.def_for("%s@capital" % ID, true, null)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID, TIER) as FestivalDirector
	var at: Array = [Places.at(&"fountain"), Places.at(&"market_square")]
	at.append_array(d.fire_spots)
	if d.mayor != null:
		at.append(d.mayor.ground_pos)
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
