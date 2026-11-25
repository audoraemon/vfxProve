extends RefCounted
## Plan "The Capital at every tier", Task 23: The Heart of Faith in the Capital (spec 6.4.5). The oil-house's point, the Temple's steps, the foot of Odran's lane, the
## Knights' quiet faces and the stages' times are the director's town vars (`steps_at_spot` seeds the existing `steps_at`, which setup snaps to walkable ground), seeded from
## the consts; the Citadel's gate is the place `citadel_gate` (bit-equal in Aldermere). The town's overrides (src/game/town/cities/capital_missions/heart_of_faith.gd) are valid
## and hold after setup; the oil-house is a real dwelling of the old town, the steps are the cathedral's; Odran's road and the oil-house to the steps are in Aldermere's band
## (real grid walks); the Knights' posts stand apart; the camera keeps the tags clear of the HUD stack; the policies read the director; the words name no place of Aldermere.

const ID := "heart_of_faith"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
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
	t.check(City.current() is AldermereCity, "the Capital Heart test leaves Aldermere active")


## A fresh director holds each town var at its const (copies, never shared); Aldermere's consts, camera and needs are untouched; the Citadel's gate place is the old const.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := HeartOfFaithDirector.new()
	t.check(d.oil_at == HeartOfFaithDirector.OIL_AT and d.steps_at_spot == HeartOfFaithDirector.STEPS_AT and d.lane_foot == HeartOfFaithDirector.LANE_FOOT
		and d.quiet_at == HeartOfFaithDirector.QUIET_AT and d.stage_at == HeartOfFaithDirector.STAGE_AT,
		"a fresh director's oil_at, steps_at_spot, lane_foot, quiet_at and stage_at are their consts")
	d.quiet_at.append(Vector2.ONE)
	d.stage_at.append(1.0)
	t.check(HeartOfFaithDirector.QUIET_AT.size() == 2 and HeartOfFaithDirector.STAGE_AT.size() == 2, "the town vars are copies: the consts are untouched")
	var vars := Overrides.town_vars(HeartOfFaithDirector.new())
	t.check(vars == ["oil_at", "steps_at_spot", "lane_foot", "quiet_at", "stage_at"], "the Heart's town vars (%s)" % [vars])
	t.check(HeartOfFaithDirector.OIL_AT == Vector2(-2.5, -12.5) and HeartOfFaithDirector.STEPS_AT == Vector2(0.8, -5.0) and HeartOfFaithDirector.LANE_FOOT == Vector2(-10.5, -5.1)
		and HeartOfFaithDirector.QUIET_AT == [Vector2(-3.5, -14.0), Vector2(2.0, -14.0)] and HeartOfFaithDirector.STAGE_AT == [45.0, 110.0]
		and HeartOfFaithDirector.CAMERA_AT == Vector2(-6.0, -4.0), "the oil-house, steps, lane, quiet faces, stage times and camera consts are untouched")
	t.check(MissionBook.heart_of_faith().camera_at == HeartOfFaithDirector.CAMERA_AT and MissionBook.heart_of_faith().intro_from == HeartOfFaithDirector.CAMERA_AT + Vector2(0.0, 6.0),
		"Aldermere's camera is still CAMERA_AT")
	t.check(Array(MissionNeeds.of(ID)) == ["temple", "citadel_gate"], "the Heart needs the Temple and the Citadel's gate (%s)" % [MissionNeeds.of(ID)])
	t.check(Places.point(&"citadel_gate") == HeartOfFaithDirector.CITADEL_GATE, "Aldermere's citadel_gate place is the old const, bit for bit")


## An Aldermere director after setup is as it was: the steps, the road, the citadel door and the oil-house are what the consts gave; the tour reads as it did.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.heart_of_faith())
	var d: HeartOfFaithDirector = s.d
	t.check(d.steps_at == d._walkable(HeartOfFaithDirector.STEPS_AT) and d.citadel_door == d._walkable(HeartOfFaithDirector.CITADEL_GATE),
		"Aldermere's steps and Citadel door are the consts' walkable ground, bit for bit (%s, %s)" % [d.steps_at, d.citadel_door])
	t.check(d._road.size() == 3 and d._road[0] == d.citadel_door and d._road[1] == d._walkable(HeartOfFaithDirector.LANE_FOOT) and d._road[2] == d.steps_at,
		"Aldermere's Odran road is the Citadel gate, the lane's foot and the steps (%s)" % [d._road])
	t.check(d.oil_house != null and d.temple != null and d.targets.size() == 2 and d.oil_house.center().distance_to(HeartOfFaithDirector.OIL_AT) < 6.0,
		"Aldermere's oil-house is the dwelling near OIL_AT")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The oil-house. Its Knights guard it. It feeds the flame from 0:45: burn it."
		and String(tour[1][1]) == "The Great Temple. The flame blazes here by 1:50. Burn it down to put the flame out."
		and String(tour[2][1]).begins_with("The Citadel. High Priest Odran waits here."), "Aldermere's tour reads as it did (%s)" % [tour])
	Kit.done(s)


## The Capital's director after setup reads back every override; the oil-house, the steps, Odran's road, the posts; the walks; the words.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var d := Cap.starts(t, ID) as HeartOfFaithDirector
	t.check(d != null and d.oil_at == dov.oil_at and d.steps_at_spot == dov.steps_at_spot and d.lane_foot == dov.lane_foot and d.quiet_at == dov.quiet_at
		and d.stage_at == HeartOfFaithDirector.STAGE_AT, "the director reads back the Capital's oil_at, steps_at_spot, lane_foot and quiet_at after setup")
	if d == null:
		return
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-13.0, -17.0) and def.intro_from == Vector2(-13.0, -11.0), "camera_at and intro_from are overridden together (C9)")
	# the tuned placement (final values in capital_missions/heart_of_faith.gd), pinned:
	t.check(d.oil_at == Vector2(-16.19398, -6.375) and d.steps_at_spot == Vector2(-3.9, -14.0) and d.lane_foot == Vector2(2.0, -13.0)
		and d.quiet_at == [Vector2(-18.0, -6.4), Vector2(-0.8, -17.7)], "the tuned oil-house point, steps, lane foot and quiet faces")
	t.check(d.oil_house != null and d.oil_house.center().distance_to(Vector2(-16.19398, -6.375)) < 0.01 and d.doors[0].distance_to(Vector2(-17.34398, -6.375)) < 0.01
		and d.doors[1].distance_to(Vector2(-1.3, -17.7)) < 0.01, "the oil-house is the west house, its Knights on its west face; the Temple's on its east face")
	t.check(d.citadel_door.distance_to(d._walkable(City.current().place(&"citadel_gate"))) < 0.01, "the Capital's Citadel door is its citadel_gate place (%s)" % [d.citadel_door])
	t.check(d.steps_at.distance_to(d.steps_at_spot) <= 0.6, "the steps land on walkable ground within 0.6 of the spot (%s vs %s)" % [d.steps_at, d.steps_at_spot])
	t.check(d.temple != null and d.temple.center().distance_to(Places.at(&"temple")) < 0.01, "the Temple is the cathedral (%s)" % [d.temple.center() if d.temple != null else null])
	t.check(d.steps_at.distance_to(d.temple.center()) < 9.0 and d.steps_at.y > d.temple.center().y, "the steps are at the cathedral's front, within 9 of it (%s)" % [d.steps_at.distance_to(d.temple.center())])
	t.check(d.oil_house != null and d.oil_house.role != &"temple" and d.oil_house.center().distance_to(d.oil_at) < 6.0 and d.oil_house != d.temple,
		"the oil-house is a real dwelling within 6 of its point (%s, role %s)" % [d.oil_house.center().distance_to(d.oil_at) if d.oil_house != null else -1.0,
		d.oil_house.role if d.oil_house != null else &""])
	Cap.spots_land(t, cap, {"lane_foot": d.lane_foot, "steps_at_spot": d.steps_at_spot, "citadel_door": d.citadel_door})
	var near_close := true
	for i in d.doors.size():
		near_close = near_close and d.doors[i].distance_to(d.quiet_at[mini(i, d.quiet_at.size() - 1)]) < 6.0
		print("CAPITAL heart door %d %s (quiet %s, target %s)" % [i, d.doors[i], d.quiet_at[mini(i, d.quiet_at.size() - 1)], d.targets[i].center()])
	t.check(d.doors.size() == 2 and near_close, "each target's face is within 6 of its quiet point")
	var spots: Array = []
	var per := {}
	for p: HeartOfFaithDirector.Post in d.posts:
		spots.append(p.spot)
		if not per.has(p.target):
			per[p.target] = []
		per[p.target].append(p.spot)
	t.check(spots.size() == 2 * (HeartOfFaithDirector.STANDING + HeartOfFaithDirector.ARRIVING), "every Knight has a post (%d)" % spots.size())
	Cap.spread(t, spots)
	for i: int in per:
		var least := INF
		for a in per[i].size():
			for b in range(a + 1, per[i].size()):
				least = minf(least, (per[i][a] as Vector2).distance_to(per[i][b]))
		print("CAPITAL heart posts at target %d: least apart %.2f (POST_APART %.1f)" % [i, least, HeartOfFaithDirector.POST_APART])
		t.check(least > HeartOfFaithDirector.POST_APART, "target %d's Knight posts are more than POST_APART apart (%.2f)" % [i, least])
	var crowded := _opening(d, "CAPITAL")
	t.check(crowded <= 14, "no key point sits under a garrison: at most 14 soldiers within 8 of one (%d)" % crowded)
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## Both walks on the real grids: the oil-house to the steps, and Odran's road from the Citadel's gate by the lane's foot to the steps.
static func _walk_parity(t, d: HeartOfFaithDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.heart_of_faith())
	var ad: HeartOfFaithDirector = a.d
	_opening(ad, "ALDERMERE")
	t.check(d.oil_house != null and ad.oil_house != null and d._road.size() == 3 and ad._road.size() == 3, "both towns' oil-houses and roads are built")
	if d.oil_house != null and ad.oil_house != null and d._road.size() == 3 and ad._road.size() == 3:
		Cap.parity(t, "the oil-house to the steps", Cap.walk(cap.grid, d._open_door(d.oil_house, d.citadel_door), d.steps_at), Cap.walk(ald.grid, ad._open_door(ad.oil_house, ad.citadel_door), ad.steps_at))
		var cw: float = Cap.walk(cap.grid, d._road[0], d._road[1]) + Cap.walk(cap.grid, d._road[1], d._road[2])
		var aw: float = Cap.walk(ald.grid, ad._road[0], ad._road[1]) + Cap.walk(ald.grid, ad._road[1], ad._road[2])
		Cap.parity(t, "Odran's road, Citadel gate to lane foot to steps", cw, aw)
	Kit.done(a)
	City.use(&"capital")


## The policies read the director's vars: no Heart const that is a var, no TownLayout coordinate, no offset from a director point.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var a := _slice(bc, "func _heart(which", "\nfunc _ringers(")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier5_b.gd").replace("\r\n", "\n")
	var r1 := _slice(route_b, "static func _heart_fells(", "\nstatic func state_heart(")
	# state_heart is the last function of the file, so it is sliced to the end
	var r2 := route_b.substr(route_b.find("static func state_heart(")) if "static func state_heart(" in route_b else ""
	t.check(a.length() > 5000 and r1.length() > 8000 and r2.length() > 150, "the heart policy functions are found and sliced (%d, %d, %d chars)" % [a.length(), r1.length(), r2.length()])
	var re := RegEx.create_from_string("\\bHeartOfFaithDirector\\.(OIL_AT|CITADEL_GATE|LANE_FOOT|STEPS_AT|QUIET_AT|STAGE_AT|CAMERA_AT)\\b|TownLayout\\b")
	var plus := RegEx.create_from_string("\\bd\\.(oil_at|steps_at_spot|steps_at|lane_foot|quiet_at|citadel_door|oil_house)(\\[\\w+\\])?\\s*[+-]|[+-]\\s*d\\.(oil_at|steps_at_spot|steps_at|lane_foot|quiet_at|citadel_door)\\b")
	t.check(re.search("x HeartOfFaithDirector.STEPS_AT") != null and re.search("TownLayout.TEMPLE") != null and re.search("HeartOfFaithDirector.WORDS[i]") == null
		and re.search("HeartOfFaithDirector.GUARD_REACH") == null and re.search("d.steps_at") == null
		and plus.search("d.steps_at + Vector2(1.0, 0.0)") != null and plus.search("o - d.citadel_door") != null and plus.search("d.steps_at,") == null
		and plus.search("d.temple.center() - x") == null, "the policy regexes bite on a sample and pass the director's vars")
	# existing offsets from director structures (not town vars): _heart_act's `o.ground_pos + (o.ground_pos - d.temple.center()).normalized() * HEART_OFF` (the Temple's centre, a structure).
	for body: String in [a, r1, r2]:
		var m := re.search(body)
		t.check(m == null, "a heart policy reads no Heart const that is a var and no TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
		var o := plus.search(body)
		t.check(o == null, "a heart policy has no hard-coded offset from a director point (%s)" % [o.get_string() if o != null else ""])


## The text from `from` to the next `to` after it ("" when `from` is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a place only Aldermere has: the tour, the brief, the goal, the hints, the steps, the tags, the targets' names.
static func _words_true(t, d: HeartOfFaithDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "not_yet", "guarded", "open", "burning", "coming", "litter", "on_foot", "rite"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	said.append_array(HeartOfFaithDirector.NAMES)
	said.append_array(HeartOfFaithDirector.WORDS)
	said.append_array(HeartOfFaithDirector.STAGE_LABELS)
	var re := RegEx.create_from_string("\\b(aldermere|main gate|side gate|postern|north quarter|old chapel)\\b")
	t.check(re.search("through the main gate") != null and re.search("the Great Temple and the Citadel") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL heart line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names a place of Aldermere (%s)" % [said])
	# the words are true by place: the oil-house is a dwelling and the Temple the cathedral; the Citadel's gate is the Capital's place
	t.check(HeartOfFaithDirector.WORDS == ["oil-house", "Temple"] and d.targets[0].role != &"temple" and d.targets[1].role == &"temple" and said.size() >= 20,
		"the words are true by place: an oil-house in the old town's houses, the Temple the cathedral (%d lines)" % said.size())


## The oil-house, the Temple, the Citadel and the altar are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as HeartOfFaithDirector
	var at: Array = [d.oil_house.center(), d.temple.center(), d.citadel_door, d.steps_at]
	t.check(at.size() == 4, "four tag points for the camera check (%d)" % at.size())
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")


## Who stands near each key point when the night opens (the director's own Knights left out): soldiers and citizens within 8 (printed); the most soldiers by one point other than the Citadel's gate and the Temple.
static func _opening(d: HeartOfFaithDirector, label: String) -> int:
	var most := 0
	var ours := {}
	for p: HeartOfFaithDirector.Post in d.posts:
		ours[p.man] = true
	var points := {"oil-house": d.oil_house.center(), "temple": d.temple.center(), "citadel": d.citadel_door, "steps": d.steps_at}
	for name: String in points:
		var sold := 0
		var lay := 0
		for p: Person in d.crowd.soldiers:
			if is_instance_valid(p) and p.is_alive() and not ours.has(p) and p.ground_pos.distance_to(points[name]) <= 8.0:
				sold += 1
		for p: Person in d.crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and not ours.has(p) and p.ground_pos.distance_to(points[name]) <= 8.0:
				lay += 1
		if name != "citadel" and name != "temple":  # the Citadel's gate (Aldermere 29, the Capital 52 within 8) and the cathedral (8 against 23) are fixed places of the town: printed, never moved
			most = maxi(most, sold)
		print("%s heart %s: soldiers within 8: %d, citizens %d" % [label, name, sold, lay])
	return most
