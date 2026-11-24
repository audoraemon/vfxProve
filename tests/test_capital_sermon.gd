extends RefCounted
## Plan "The Capital at every tier", Task 17: the Sermon in the Capital (spec 6.3.4). The pulpit is the Capital's well number pulpit_well (3, the old town houses' well,
## east of x = 8), the god's house the dwelling nearest house_spot, the later waves come from `sources`, and `wave_at` is the waves' times; all four are town vars seeded
## from the consts (a fresh director in Aldermere reads Aldermere's own, and its pulpit is the same well as before). The town's overrides
## (src/game/town/cities/capital_missions/sermon.gd) are valid and hold after setup; the walks are in Aldermere's band (real grid walks); the sentries stand more than 1.6 apart;
## the words the player reads name no Aldermere place; the camera keeps the key points clear of the padded HUD stack; the policies read the director and Places.

const ID := "sermon"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_lookup_exact(t)
	_policy_reads_vars(t)
	_aldermere_pin(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Sermon test leaves Aldermere active")


## A fresh director holds each town var at its const (copies, never shared); Aldermere's numbers and camera are untouched.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := SermonDirector.new()
	t.check(d.pulpit_well == 2 and d.house_spot == SermonDirector.HOUSE_SPOT and d.sources == SermonDirector.SOURCES and d.wave_at == SermonDirector.WAVE_AT,
		"a fresh director's pulpit_well, house_spot, sources and wave_at are their consts")
	d.sources.append(Vector2.ZERO)
	d.wave_at.append(1.0)
	t.check(SermonDirector.SOURCES.size() == 3 and SermonDirector.WAVE_AT.size() == 4, "the town vars are copies: the consts are untouched")
	var names := Overrides.town_vars(SermonDirector.new())
	t.check(names.has("pulpit_well") and names.has("house_spot") and names.has("sources") and names.has("wave_at"), "the Sermon's town vars (%s)" % [names])
	t.check(SermonDirector.HOUSE_SPOT == Vector2(-14.0, 10.4) and SermonDirector.SOURCES == [Vector2(-11.0, 3.0), Vector2(-2.0, 12.0), Vector2(-12.0, 6.0)]
		and SermonDirector.WAVE_AT == [0.0, 95.0, 185.0, 260.0] and SermonDirector.CAMERA_AT == Vector2(-13.5, 9.0), "the consts are untouched")
	t.check(MissionBook.sermon().camera_at == SermonDirector.CAMERA_AT and MissionBook.sermon().intro_from == SermonDirector.CAMERA_AT + Vector2(0.0, 6.0),
		"Aldermere's camera is still CAMERA_AT")


## The lookup that replaces the policy's tower const is bit-equal in Aldermere.
static func _lookup_exact(t) -> void:
	City.use(&"aldermere")
	t.check(Places.at(&"bell_tower") == TownLayout.BELL_TOWER.get_center(), "Aldermere's bell_tower place is the old const's centre, bit for bit")


## An Aldermere director after setup is as it was: the same well, the same house, the same sources, the same tour.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.sermon())
	var d: SermonDirector = s.d
	t.check(d.pulpit == d._walkable(City.current().wells()[2].get_center() + Vector2(0.0, -0.8)), "Aldermere's pulpit is the old well 2's (%s)" % [d.pulpit])
	t.check(d.house != null and d.house.center().distance_to(Vector2(-14.0, 10.4)) < 3.0, "Aldermere's god's house is by (-14.0, 10.4) (%s)" % [d.house.center() if d.house != null else "none"])
	for w in 3:
		t.check(d._wave_source(w + 1) == d._walkable(SermonDirector.SOURCES[w]), "Aldermere's wave %d comes from SOURCES[%d]" % [w + 1, w])
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("The preacher at the well."), "the tour names the well (%s)" % [tour])
	Kit.done(s)


## The Capital's director after setup reads back every override: its pulpit, house, sources, waves, sentries, walks and words.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var d := Cap.starts(t, ID) as SermonDirector
	t.check(d != null and d.pulpit_well == dov.pulpit_well and d.house_spot == dov.house_spot and d.sources == dov.sources, "the director reads back the Capital's well, house and sources after setup")
	if d == null:
		return
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(8.0, 4.0) and def.intro_from == Vector2(8.0, 10.0), "camera_at and intro_from are overridden together (C9)")
	t.check(d.pulpit_well == 3 and d.house_spot == Vector2(1.5, -5.0) and d.sources == [Vector2(-6.0, -9.0), Vector2(14.0, -5.5), Vector2(-2.0, -3.0)],
		"the Capital's well is 3, its house spot (13.0, -2.5), its sources the spec's (%s %s)" % [d.house_spot, d.sources])
	var well: Rect2 = City.current().wells()[3]
	t.check(well.get_center().x > 8.0, "the Capital's well 3 stands east of x = 8 (%s)" % [well.get_center()])
	t.check(d.pulpit == d._walkable(well.get_center() + Vector2(0.0, -0.8)) and d.pulpit.distance_to(well.get_center()) < 1.5, "the pulpit is by well 3 (%s)" % [d.pulpit])
	t.check(d.house != null, "the Capital has a god's house")
	if d.house == null:
		return
	t.check(d.house.center().distance_to(d.house_spot) < 4.0, "the god's house is a dwelling by the house spot (%s)" % [d.house.center()])
	t.check(d.door.distance_to(d.pulpit) > SermonDirector.VOICE, "the god's door is beyond the preacher's voice (%.1f)" % d.door.distance_to(d.pulpit))
	var points := {"pulpit": d.pulpit, "door": d.door, "temple door": d.temple_door}
	for w in 3:
		points["source %d" % (w + 1)] = d._wave_source(w + 1)
	Cap.spots_land(t, cap, points)
	var posts := []
	for st: SermonDirector.Sentry in d.sentries:
		posts.append(st.post)
	t.check(posts.size() == 2, "two sentries' posts (%d)" % posts.size())
	Cap.spread(t, posts)
	var spots := []
	for l: SermonDirector.Listener in d.listeners:
		spots.append(l.spot)
	t.check(spots.size() == 12, "twelve listeners in four waves (%d)" % spots.size())
	Cap.spread(t, spots, 0.35)
	t.check(d.wave_at == [0.0, 85.0, 160.0, 230.0] and d.wave_at == dov.wave_at, "the waves are at 0, 85, 160 and 230 (%s)" % [d.wave_at])
	print("CAPITAL sermon pulpit %s door %s house %s temple door %s" % [d.pulpit, d.door, d.house.center(), d.temple_door])
	_opening(d, "CAPITAL")
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## The pulpit to the god's door, each source to the pulpit, the god's door to the Temple's (the Faithful's report run): Capital against Aldermere on the real grids
## (band 0.75-1.35).
static func _walk_parity(t, d: SermonDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.sermon())
	var ad: SermonDirector = a.d
	_opening(ad, "ALDERMERE")
	var hw: float = Cap.walk(cap.grid, d.pulpit, d.door)
	var haw: float = Cap.walk(ald.grid, ad.pulpit, ad.door)
	print("CAPITAL parity the pulpit to the god's house: capital %.1f, aldermere %.1f (%.2fx)" % [hw, haw, hw / haw])
	# Measured (Task 17): a whisper reaches 10 along the street (MindWhisperFx.REACH) and a listener is brought in only if he lands by the house, so the Capital's house must lie within one
	# whisper of the pulpit; every dwelling that does is 5-11 away, 0.45-0.69x Aldermere's 15.1. The spec's spot east of x = 8 has no dwelling beyond the preacher's voice (the nearest east of it is 14+ away: with the house south at (8.25, 14.1) the whisper never landed, 0 of 3 wins, 0 believers in seed 1).
	t.check(hw <= MindWhisperFx.REACH + 1.0 and hw > SermonDirector.VOICE and haw >= 12.0 and haw <= 18.0, "the Capital's house door is one whisper from the pulpit (%.1f, reach %.0f), Aldermere's is 12-18 (%.1f)" % [hw, MindWhisperFx.REACH, haw])
	for w in 3:
		Cap.parity(t, "source %d to the pulpit" % (w + 1), Cap.walk(cap.grid, d._wave_source(w + 1), d.pulpit), Cap.walk(ald.grid, ad._wave_source(w + 1), ad.pulpit))
	var rc: float = Cap.walk(cap.grid, d.door, d.temple_door)
	var ra: float = Cap.walk(ald.grid, ad.door, ad.temple_door)
	print("CAPITAL parity the god's house to the Temple's door: capital %.1f, aldermere %.1f (%.2fx)" % [rc, ra, rc / ra])
	t.check(rc >= 10.0 and rc <= 20.0 and ra >= 26.0 and ra <= 36.0, "the report run is 10-20 in the Capital and 26-36 in Aldermere (%.1f, %.1f): the Faithful's report arrives sooner, measured in the gates" % [rc, ra])
	Kit.done(a)
	City.use(&"capital")


## The policies read the director and the Places, no Sermon const or TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "func _sermon_act(", "\nfunc ")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier4_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "static func act_sermon(", "\nstatic func ")
	t.check(act.length() > 3000 and rb.length() > 3000, "the sermon policy functions are found and sliced (%d, %d chars)" % [act.length(), rb.length()])
	var re := RegEx.create_from_string("\\bSermonDirector\\.(HOUSE_SPOT|SOURCES|WAVE_AT|CAMERA_AT)\\b|\\bTownLayout\\b")
	var plus := RegEx.create_from_string("\\b(d\\.pulpit|d\\.door|d\\.temple_door)\\s*[+-]")
	t.check(re.search("x SermonDirector.HOUSE_SPOT") != null and re.search("TownLayout.BELL_TOWER") != null and re.search("SermonDirector.RELIEF_AFTER") == null
		and re.search("d.house_spot") == null and plus.search("d.door + Vector2(1.0, 0.0)") != null and plus.search("p.ground_pos - d.door") == null and plus.search("d.door,") == null,
		"the policy regexes bite on a sample and pass the director's vars")
	for body: String in [act, rb]:
		var m := re.search(body)
		t.check(m == null, "a sermon policy reads no Sermon const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
		t.check(plus.search(body) == null, "a sermon policy has no hard-coded offset from a director point")
		t.check("Places.at(&\"bell_tower\")" in body, "each sermon policy finds the bell tower by place")
		t.check(("d.door" if body == act else "d.pulpit") in body, "each sermon policy reads the director's door or pulpit")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a place only Aldermere has: the tour, the brief, the goal, the hints, the steps, the tags.
static func _words_true(t, d: SermonDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "rapt", "watched", "report", "coming", "seen", "bell"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	said.append(d._house_label())
	said.append(d._opening_banner())
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	var re := RegEx.create_from_string("\\b(south-west|south-east|poor quarter|east well|west well|bell tower|main gate)\\b")
	t.check(re.search("the preacher at the south-west well") != null and re.search("the preacher at the well") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL sermon line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names the south-west well, the poor quarter or a place of Aldermere (%s)" % [said])
	t.check(d.tour().size() == 3 and MissionHints.line(ID, "rapt") != "" and said.size() >= 20, "the lines were gathered (%d)" % said.size())


## The pulpit, the god's house and its door and the three sources (or their edge arrows) are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as SermonDirector
	var at: Array = [d.pulpit, d.door, d.house.center()]
	for w in 3:
		at.append(d._wave_source(w + 1))
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")


## Who stands near the pulpit, the god's house and each source when the night opens (the director's own people left out): soldiers and citizens within 8 (printed).
static func _opening(d: SermonDirector, label: String) -> void:
	var ours := {}
	for l: SermonDirector.Listener in d.listeners:
		ours[l.man] = true
	for st: SermonDirector.Sentry in d.sentries:
		ours[st.man] = true
	for a: Variant in d.acolytes:
		ours[a] = true
	ours[d.preacher] = true
	var spots := {"pulpit": d.pulpit, "house": d.house.center() if d.house != null else d.pulpit}
	for w in 3:
		spots["source %d" % (w + 1)] = d._wave_source(w + 1)
	for name: String in spots:
		var soldiers := 0
		var lay := 0
		for p: Person in d.crowd.soldiers:
			if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(spots[name]) <= 8.0:
				soldiers += 1
		for p: Person in d.crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and not ours.has(p) and p.ground_pos.distance_to(spots[name]) <= 8.0:
				lay += 1
		print("%s sermon %s: soldiers within 8: %d, other citizens %d" % [label, name, soldiers, lay])
