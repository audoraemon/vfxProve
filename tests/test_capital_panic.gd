extends RefCounted
## Plan "The Capital at every tier", Task 5: Market Panic in the Capital (spec 6.1.4). The night fair is held at the old town centre in the old town's
## north; the town's overrides (src/game/town/cities/capital_missions/market_panic.gd) are valid and hold after setup; the mission is hostable;
## each later crowd's source to the fair's heart is in Aldermere's band (real grid walks); every spot lands on ground; the fair has room for four crowds;
## the wardens stand more than 1.6 apart; the three paired lists are the same length; the intro camera keeps the heart and every source's arrow clear
## of the padded HUD stack; the tour tells the truth about the Capital; the director and the policies read the vars, not the consts.

const ID := "market_panic"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_policy_reads_vars(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var spots := {"heart": ov.director.heart}
	for i in (ov.director.sources as Array).size():
		spots["source %d" % (i + 1)] = ov.director.sources[i]
	Cap.spots_land(t, cap, spots)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Panic test leaves Aldermere active")


## A fresh director holds every town var at its const.
static func _seeded(t) -> void:
	var d := MarketPanicDirector.new()
	t.check(d.heart == MarketPanicDirector.HEART, "a fresh director's heart is HEART (Aldermere's)")
	t.check(d.sources == MarketPanicDirector.SOURCES, "a fresh director's sources is SOURCES")
	t.check(d.source_names == MarketPanicDirector.SOURCE_NAMES, "a fresh director's source_names is SOURCE_NAMES")
	t.check(d.wave_at == MarketPanicDirector.WAVE_AT, "a fresh director's wave_at is WAVE_AT")
	t.check(Overrides.town_vars(d) == ["heart", "sources", "source_names", "wave_at"], "Market Panic's town vars (%s)" % [Overrides.town_vars(d)])
	t.check(MarketPanicDirector.WAVE == 11 and MarketPanicDirector.CHAIN == 45.0 and MarketPanicDirector.FAIR_R == 5.5 and MarketPanicDirector.WARDENS == 3,
		"WAVE, CHAIN, FAIR_R and WARDENS are untouched")
	t.check(MissionBook.market_panic().camera_at == MarketPanicDirector.CAMERA_AT, "Aldermere's camera is still CAMERA_AT")


## The director and its policies read the vars: no HEART, SOURCES, SOURCE_NAMES or WAVE_AT outside a const line, a comment and the tour's
## Aldermere-only wording; no policy function reads the consts or a TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/mission/market_panic_director.gd")
	var at := src.find("var _tick_in")
	var body := src.substr(at) if at >= 0 else ""
	t.check(at >= 0 and body.length() > 5000, "the director's code is found and sliced (%d chars)" % body.length())
	var re := RegEx.create_from_string("\\b(HEART|SOURCES|SOURCE_NAMES|WAVE_AT)\\b")
	var bad := PackedStringArray()
	for line in body.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("##") or l.begins_with("const ") or "heart == HEART" in l:
			continue
		if re.search(l) != null:
			bad.append(l)
	t.check(bad.is_empty(), "the director reads the town vars, not the consts (%s)" % [bad])
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd")
	var policy := _slice(bc, ["func _panic_act(", "func _panic_near(", "func _panic_lane(", "func _panic_knot("], "\nfunc ")
	var rb := FileAccess.get_file_as_string("res://tools/dev/routes/tier2_b.gd")
	policy += _slice(rb, ["static func act_panic(", "static func _panic_look(", "static func _panic_ahead(", "static func _panic_mark(",
		"static func _panic_far_citizen(", "static func _panic_house(", "static func _panic_by(", "static func state_panic("], "\nstatic func ")
	t.check(policy.length() > 3000, "the panic policy functions are all found and sliced (%d chars)" % policy.length())
	t.check(not "MarketPanicDirector.HEART" in policy and not "MarketPanicDirector.SOURCES" in policy and not "TownLayout." in policy
		and not "CAMERA_AT" in policy, "the panic policy reads d.heart and d.sources, no const, CAMERA_AT or TownLayout coordinate")


## The concatenated bodies of the functions starting at each of `fns` up to `end`; "" when any find fails, so the caller's length check fails.
static func _slice(src: String, fns: Array, end: String) -> String:
	var out := ""
	for fn: String in fns:
		var f := src.find(fn)
		if f < 0:
			print("PANIC TEST: %s not found" % fn)
			return ""
		var rest := src.substr(f + fn.length())
		var e := rest.find(end)
		if e <= 0:
			print("PANIC TEST: end of %s not found" % fn)
			return ""
		out += rest.substr(0, e)
	return out


static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var d := Cap.starts(t, ID) as MarketPanicDirector
	t.check(d != null and d.heart == ov.director.heart and d.sources == ov.director.sources and d.source_names == ov.director.source_names
		and d.wave_at == MarketPanicDirector.WAVE_AT, "the director reads back the Capital's heart, sources and names after setup")
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-5.0, -3.5) and def.intro_from == Vector2(-5.0, 2.5), "camera_at and intro_from are overridden together (C9)")
	t.check(d.sources.size() == 4 and d.source_names.size() == d.sources.size() and d.wave_at.size() == d.sources.size(),
		"sources, source_names and wave_at are paired, four each (%d, %d, %d)" % [d.sources.size(), d.source_names.size(), d.wave_at.size()])
	t.check(d.sources[0] == d.heart, "the first crowd comes from the heart")
	t.check(d.waves.size() == 4 and d.goers.size() > 0 and d.unbroken().size() == MarketPanicDirector.WAVE,
		"four crowds are appointed and the first (%d) walks in" % d.unbroken().size())
	_wardens(t, d)
	_fair_ground(t, d, cap)
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## Three wardens stand at their posts round the heart, all more than 1.6 apart.
static func _wardens(t, d: MarketPanicDirector) -> void:
	var posts: Array = []
	for w in d.wards:
		posts.append(w.post)
		t.check(w.man != null, "a warden stands at post %s" % [w.post])
	t.check(posts.size() == MarketPanicDirector.WARDENS, "three wardens (%d)" % posts.size())
	Cap.spread(t, posts)
	var men: Array = []
	for w in d.wards:
		if w.man != null:
			men.append((w.man as Person).ground_pos)
	t.check(men.size() == 3, "all three wardens were set down (%d)" % men.size())
	Cap.spread(t, men)


## The fair has room for four crowds: at least WAVE * 4 walkable spots (a 0.5 lattice) within FAIR_R of the heart on the built Capital.
static func _fair_ground(t, d: MarketPanicDirector, cap: Dictionary) -> void:
	var grid: WalkGrid = cap.grid
	var n := 0
	var r := MarketPanicDirector.FAIR_R
	var x := -r
	while x <= r:
		var y := -r
		while y <= r:
			var spot: Vector2 = d.heart + Vector2(x, y)
			if spot.distance_to(d.heart) <= r and grid.walkable(spot):
				n += 1
			y += 0.5
		x += 0.5
	t.check(n >= MarketPanicDirector.WAVE * 4, "the fair has room: %d walkable spots within FAIR_R of the heart (need %d)" % [n, MarketPanicDirector.WAVE * 4])
	print("CAPITAL panic fair ground: %d walkable spots" % n)


## Each later crowd's source to the heart, Capital against Aldermere on the real grids (band 0.75-1.35).
static func _walk_parity(t, d: MarketPanicDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.market_panic())
	var ad: MarketPanicDirector = a.d
	var csum := 0.0
	var asum := 0.0
	for i in range(1, 4):
		var c := Cap.walk(cap.grid, d.sources[i], d.heart)
		var l := Cap.walk(ald.grid, ad.sources[i], ad.heart)
		csum += c
		asum += l
		print("CAPITAL panic crowd %d (%s) to the heart: capital %.1f, aldermere %.1f" % [i + 1, d.source_names[i], c, l])
		Cap.parity(t, "crowd %d (%s) to the heart" % [i + 1, d.source_names[i]], c, l)
	Cap.parity(t, "the three sources to the heart (total)", csum, asum)
	Kit.done(a)
	City.use(&"capital")


## No line of the Capital's tour names a place of Aldermere; each stop names its place in the Capital's words.
static func _words_true(t, d: MarketPanicDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var wrong := false
	for line in said:
		for place in ["north-east", "cathedral's street", "workshops", "east tavern"]:
			wrong = wrong or place in line.to_lower()
	t.check(not wrong, "no tour line names a place of Aldermere (%s)" % [said])
	# Every line the player reads in the Capital: the def's board lines, goal, goal label and lose line, and the hints, name no place of Aldermere.
	var def := MissionBook.get_mission("%s@capital" % ID)
	var read := PackedStringArray(def.brief)
	read.append_array([def.goal, def.goal_label, def.lose, String(MissionHints.LINES.get(ID, ""))])
	t.check(def.brief.size() == 2 and read.size() == 6 and not String(read[0]).is_empty(), "the Capital's mission lines are found (%d)" % read.size())
	var text_wrong := false
	for line in read:
		for place in ["north-east", "cathedral's street", "workshops", "east tavern", "fountain", "square"]:
			text_wrong = text_wrong or place in line.to_lower()
	t.check(not text_wrong, "no mission line the player reads in the Capital names a place of Aldermere (%s)" % [read])
	# Aldermere's own words are unchanged.
	var ald := MissionBook.get_mission(ID)
	t.check(ald.brief.size() == 2 and ald.brief[0] == "A night fair fills the north-east square." and ald.brief[1] == "Scatter it before the market closes."
		and ald.goal == def.goal, "Aldermere's board lines are unchanged")
	t.check(MarketPanicDirector.new().heart == MarketPanicDirector.HEART and MarketPanicDirector.SOURCE_NAMES[0] == "the north-east quarter",
		"Aldermere's place names are unchanged")
	t.check(said.size() == 4, "the tour has its four stops (%d)" % said.size())
	var named := said.size() == 4 and "old town" in said[0]
	for i in range(1, mini(4, said.size())):
		named = named and String(d.source_names[i]) in said[i]
	t.check(named, "each stop names its place in the Capital's words")


## The heart and every source's arrow are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as MarketPanicDirector
	var at: Array = [d.heart]
	for i in range(1, d.sources.size()):
		at.append(d.sources[i])
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
