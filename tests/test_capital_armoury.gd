extends RefCounted
## Plan "The Capital at every tier", Task 16: the Armoury in the Capital (spec 6.3.3). Its three targets are the west market tavern, the west river gate's
## east tower and the Keep's barracks; the words, the horn labels and the horns' times are the director's town vars, seeded from the consts (a fresh
## director in Aldermere reads Aldermere's own); the Citadel's gate is the place `citadel_gate` (bit-equal in Aldermere). The town's overrides
## (src/game/town/cities/capital_missions/armoury.gd) are valid and hold after setup; the legs between the targets are in Aldermere's band (real grid
## walks); each target's night watch stands more than 1.6 apart; the words the player reads name no Aldermere place; the camera keeps the targets clear
## of the padded HUD stack; the policies read `d.words`, not ArmouryDirector.WORDS.

const ID := "armoury"
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
	t.check(City.current() is AldermereCity, "the Capital Armoury test leaves Aldermere active")


## A fresh director holds each town var at its const (copies, never shared); Aldermere's numbers and gate are untouched.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := ArmouryDirector.new()
	t.check(d.words == ArmouryDirector.WORDS and d.horn_labels == ArmouryDirector.HORN_LABELS and d.stage_at == ArmouryDirector.STAGE_AT,
		"a fresh director's words, horn_labels and stage_at are their consts")
	d.words.append("x")
	d.stage_at.append(1.0)
	d.horn_labels.append("x")
	t.check(ArmouryDirector.WORDS.size() == 3 and ArmouryDirector.STAGE_AT.size() == 3 and ArmouryDirector.HORN_LABELS.size() == 3, "the town vars are copies: the consts are untouched")
	t.check(Overrides.town_vars(ArmouryDirector.new()) == ["words", "horn_labels", "stage_at"], "the Armoury's town vars (%s)" % [Overrides.town_vars(ArmouryDirector.new())])
	t.check(ArmouryDirector.WORDS == ["north barracks", "gate barracks", "armoury"] and ArmouryDirector.STAGE_AT == [40.0, 110.0, 180.0]
		and ArmouryDirector.CHAIN == 40.0 and ArmouryDirector.HORN_LABELS[2] == "The muster horn: the garrison arms"
		and ArmouryDirector.CAMERA_AT == Vector2(-5.5, -4.5) and ArmouryDirector.CITADEL_GATE == Vector2(-10.5, -7.6),
		"the words, the horns, the camera and the gate const are untouched")
	t.check(MissionBook.armoury().camera_at == ArmouryDirector.CAMERA_AT and MissionBook.armoury().intro_from == ArmouryDirector.CAMERA_AT + Vector2(0.0, 6.0),
		"Aldermere's camera is still CAMERA_AT")
	t.check(Array(MissionNeeds.of(ID)) == ["temple", "barracks", "taverns:2", "gate_towers:2", "citadel_gate"], "the Armoury needs the Citadel's gate too (%s)" % [MissionNeeds.of(ID)])
	t.check(Places.point(&"citadel_gate") == ArmouryDirector.CITADEL_GATE, "Aldermere's citadel_gate place is the old const, bit for bit")


## An Aldermere director after setup is as it was: its gate, its three targets, its tour.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.armoury())
	var d: ArmouryDirector = s.d
	t.check(d.citadel_door == d._walkable(Vector2(-10.5, -7.6)), "Aldermere's reserve waits at the same gate (%s)" % [d.citadel_door])
	t.check(d.targets.size() == 3 and d.targets[0].footprint.position.is_equal_approx(City.current().taverns()[0].position)
		and d.targets[1].footprint.position.is_equal_approx(City.current().gate_towers()[1].position) and d.targets[2].footprint.position.is_equal_approx(Places.rect(&"barracks").position),
		"Aldermere's targets are the north tavern, the Main Gate's east tower and the barracks")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The north barracks. The muster horn calls it at 0:40."
		and String(tour[1][1]) == "The gate barracks, by 1:50. It is stone: blows, not fire."
		and String(tour[2][1]) == "The armoury, last. It arms the garrison, faster each minute.", "the tour is as it was (%s)" % [tour])
	Kit.done(s)


## The Capital's director after setup reads back every override; its three targets; the walks; the night watches; the words.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var d := Cap.starts(t, ID) as ArmouryDirector
	t.check(d != null and d.words == dov.words and d.horn_labels == dov.horn_labels and d.stage_at == dov.stage_at, "the director reads back the Capital's words and horn labels after setup")
	t.check(d != null and d.stage_at == [40.0, 110.0, 150.0]
		and d.stage_at[2] <= d.stage_at[1] + ArmouryDirector.CHAIN, "the Capital's horns are 40, 110 and 150, the third within the second plus CHAIN, as the second is not within the first plus CHAIN in either town (%s)" % [d.stage_at])
	if d == null:
		return
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-16.0, -4.0) and def.intro_from == Vector2(-16.0, 2.0), "camera_at and intro_from are overridden together (C9)")
	var citadel: Vector2 = City.current().place(&"citadel_gate")
	t.check(d.citadel_door.distance_to(citadel) < 1.0, "the reserve waits at the Keep's gate (%s)" % [d.citadel_door])
	t.check(d.targets.size() == 3, "the Capital's night has three targets (%d)" % d.targets.size())
	if d.targets.size() != 3:
		return
	t.check(d.targets[0].footprint.position.is_equal_approx(City.current().taverns()[0].position) and d.targets[0].center().distance_to(Vector2(-21.8, -7.7)) < 2.0,
		"the first target is the west market tavern (%s)" % [d.targets[0].center()])
	var tower: Rect2 = City.current().gate_towers()[1]
	var west_tower: Rect2 = City.current().gate_towers()[0]
	t.check(d.targets[1].footprint.position.is_equal_approx(tower.position) and d.targets[1].role == &"tower"
		and d.targets[1].center().distance_to(tower.get_center()) < 2.0 and d.targets[1].center().distance_to(west_tower.get_center()) > 2.0
		and d.targets[1].center().distance_to(CapitalCity.INNER_GATES[1]) < 4.0,
		"the second target is the west river gate's east tower, by place: beside that gate, not its west tower or another gate's (%s)" % [d.targets[1].center()])
	t.check(d.targets[2].footprint.position.is_equal_approx(Places.rect(&"barracks").position) and d.targets[2].center().distance_to(Vector2(-7.8, -28.2)) < 2.5,
		"the third target is the Keep's barracks (%s)" % [d.targets[2].center()])
	print("CAPITAL armoury targets %s %s %s; distances %.1f %.1f; faces %s" % [d.targets[0].center(), d.targets[1].center(), d.targets[2].center(),
		d.targets[0].center().distance_to(d.targets[1].center()), d.targets[1].center().distance_to(d.targets[2].center()), d.faces])
	var night := []
	var all := 0
	for i in 3:
		var mine := []
		for a: ArmouryDirector.Armed in d.armed[i]:
			mine.append(a.post)
			all += 1
		for k in ArmouryDirector.NIGHT_WATCH:
			night.append((d.armed[i][k] as ArmouryDirector.Armed).post)
		Cap.spread(t, mine)
	t.check(all == 3 * (ArmouryDirector.NIGHT_WATCH + ArmouryDirector.SQUAD) and night.size() == 6, "each target has its night watch and squad posts (%d)" % all)
	Cap.spread(t, night)
	_opening(d, "CAPITAL")
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## Target to target (the faces the player looks at), Capital against Aldermere on the real grids (band 0.75-1.35). The spec's targets are fixed and its legs
## swap (tavern to tower 13 against 28, tower to barracks 33 against 13: spec 6.3.3 "A about 21 and 13, C about 13.5 and 32"), so each leg is printed and the
## band judges the whole walk, tavern to tower to barracks. The Keep's gate to the armoury (where the reinforcements march) is printed too: the Keep's gate
## stands beside its barracks.
static func _walk_parity(t, d: ArmouryDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.armoury())
	var ad: ArmouryDirector = a.d
	_opening(ad, "ALDERMERE")
	var c := [Cap.walk(cap.grid, d.faces[0], d.faces[1]), Cap.walk(cap.grid, d.faces[1], d.faces[2])]
	var al := [Cap.walk(ald.grid, ad.faces[0], ad.faces[1]), Cap.walk(ald.grid, ad.faces[1], ad.faces[2])]
	for k in 2:
		print("CAPITAL parity leg %d (%s to %s): capital %.1f, aldermere %.1f (%.2fx)" % [k + 1, d.words[k], d.words[k + 1], c[k], al[k], c[k] / al[k]])
	print("CAPITAL parity the Citadel's gate to the armoury: capital %.1f, aldermere %.1f" % [Cap.walk(cap.grid, d.citadel_door, d.faces[2]), Cap.walk(ald.grid, ad.citadel_door, ad.faces[2])])
	Cap.parity(t, "the three targets in order", c[0] + c[1], al[0] + al[1])
	# Measured consequence (Task 16 fix round 1): the Keep's gate stands beside its barracks, so the reinforcements and reliefs of the third stage
	# reach the armoury in 8 of walking where Aldermere's take 36 (4.4x faster); the per-stage table (task-16-report.md): route A stage 3 plays at 1.05x Aldermere's
	# time, route B at 0.50x (its reinforcements 0.3 against 1.3). A layout change that moves either walk out of its range changes that stage and fails here.
	var cw: float = Cap.walk(cap.grid, d.citadel_door, d.faces[2])
	var aw: float = Cap.walk(ald.grid, ad.citadel_door, ad.faces[2])
	t.check(cw >= 4.0 and cw <= 16.0, "the Capital's reinforcement walk, the Keep's gate to the armoury, is 4-16 (%.1f)" % cw)
	t.check(aw >= 28.0 and aw <= 44.0, "Aldermere's reinforcement walk, the Citadel's gate to the armoury, is 28-44 (%.1f)" % aw)
	Kit.done(a)
	City.use(&"capital")


## The policies read the director's words, no Armoury const or TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "func _armoury_act(", "\nfunc ")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier4_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "static func act_armoury(", "\nstatic func ")
	t.check(act.length() > 1500 and rb.length() > 3000, "the armoury policy functions are found and sliced (%d, %d chars)" % [act.length(), rb.length()])
	var re := RegEx.create_from_string("\\bArmouryDirector\\.(WORDS|NAMES|HORN_LABELS|STAGE_AT|CAMERA_AT|CITADEL_GATE)\\b|TownLayout\\b")
	var plus := RegEx.create_from_string("\\b(citadel_door|faces\\[\\w+\\]|targets\\[\\w+\\]\\.center\\(\\))\\s*[+-]")
	t.check(re.search("x ArmouryDirector.WORDS[0]") != null and re.search("TownLayout.TAVERNS") != null and re.search("ArmouryDirector.GUARD_REACH") == null and re.search("d.words[0]") == null
		and plus.search("d.citadel_door + Vector2(1.0, 0.0)") != null and plus.search("d.citadel_door,") == null, "the policy regexes bite on a sample and pass the director's vars")
	for body: String in [act, rb]:
		var m := re.search(body)
		t.check(m == null, "an armoury policy reads no Armoury const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
		t.check(plus.search(body) == null, "an armoury policy has no hard-coded offset from a director point")
		t.check("d.words" in body, "each armoury policy reads d.words")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a place only Aldermere has: the tour, the brief, the goal, the hints, the steps, the strip's labels, the tags.
static func _words_true(t, d: ArmouryDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "not_yet", "guarded", "open", "stone"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	for l in d.horn_labels:
		said.append(String(l))
	for w in d.words:
		said.append("the %s is razed" % w)
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	var re := RegEx.create_from_string("\\b(north barracks|north tavern|main gate|north quarter|citadel's lane)\\b")
	t.check(re.search("the north barracks turns out") != null and re.search("the west barracks turns out") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL armoury line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names the north barracks or a place of Aldermere (%s)" % [said])
	t.check(d.tour().size() == 3 and "west barracks" in String(d.tour()[0][1]).to_lower() and MissionHints.line(ID, "not_yet") != "" and said.size() >= 16,
		"the tour names the west barracks and the lines were gathered (%d)" % said.size())


## The three targets (or their edge arrows) are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as ArmouryDirector
	var at: Array = []
	for s in d.targets:
		at.append(s.center())
	t.check(at.size() == 3, "three target points for the camera check (%d)" % at.size())
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")


## Who stands near each target when the night opens (the director's own armed men left out): other watchmen and other citizens within 8 (printed).
static func _opening(d: ArmouryDirector, label: String) -> void:
	var ours := {}
	for list: Array in d.armed:
		for a: ArmouryDirector.Armed in list:
			ours[a.man] = true
	for i in d.targets.size():
		var armed := 0
		var lay := 0
		for p: Person in d.crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and not ours.has(p) and p.ground_pos.distance_to(d.targets[i].center()) <= 8.0:
				if p.profile.role == CitizenProfile.Role.WATCHMAN:
					armed += 1
				else:
					lay += 1
		print("%s armoury target %d: other watchmen within 8: %d, other citizens %d" % [label, i, armed, lay])
