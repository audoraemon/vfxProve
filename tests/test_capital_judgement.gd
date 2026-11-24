extends RefCounted
## Plan "The Capital at every tier", Task 20: Last Judgement in the Capital (spec 6.4.1). The director has no town var: it tags the active city's Citadel, exits, rite and
## boats. The Capital's overrides (src/game/town/cities/capital_missions/last_judgement.gd) change the brief and the intro's start only, and the camera stays unset (the Citadel).
## The scripted play's ring is a per-city table in tools/dev/behaviour_check.gd: Aldermere's list is v0.08's, element for element; the Capital's eight targets each lie within reach of a standing building and the Citadel is clear of the padded HUD stack at the camera; the policy reads the active city, no TownLayout
## coordinate. The words are true in the Capital.

const ID := "last_judgement"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const BC := "res://tools/dev/behaviour_check.gd"
## Aldermere's ring as v0.08 wrote it (the literal the table's &"aldermere" entry must equal; the fifth is its Citadel's origin).
const ALDERMERE_RING := [Vector2(-9.0, -11.0), Vector2(0.8, 2.2), Vector2(-12.0, 1.0), Vector2(-4.0, -6.0), Vector2(-10.5, -10.5), Vector2(-6.0, -12.0), Vector2(4.0, -4.0), Vector2(-10.5, -8.0)]
const CAPITAL_RING := [Vector2(0.0, -25.5), Vector2(-8.0, -12.0), Vector2(-7.5, -2.5), Vector2(6.0, -4.0), Vector2(-18.0, -15.0), Vector2(10.0, -14.0), Vector2(-3.9, -17.7), Vector2(-20.0, -4.0)]


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_policy_city_table(t)
	_policy_reads_vars(t)
	var cap := Cap.town(&"capital")
	_starts(t)
	_spots_land(t, cap)
	Cap.drop(cap)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Judgement test leaves Aldermere active")


## The director holds no town var and Aldermere's mission is as it was.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	t.check(Overrides.town_vars(LastJudgementDirector.new()).is_empty(), "Last Judgement's director has no town vars (%s)" % [Overrides.town_vars(LastJudgementDirector.new())])
	var m := MissionBook.last_judgement()
	t.check(m.brief == PackedStringArray(["Aldermere and its Royal Citadel.", "Bring the whole kingdom down."]) and m.camera_at == MissionDef.new().camera_at,
		"Aldermere's brief is as it was and its camera is unset")


## Aldermere's ring is today's list element for element; the Capital's is the pinned eight; both have eight.
static func _policy_city_table(t) -> void:
	var consts: Dictionary = load(BC).get_script_constant_map()
	var table: Dictionary = consts.get("JUDGEMENT_TARGETS", {})
	t.check(table.has(&"aldermere") and table.has(&"capital") and table.size() == 2, "the ring is a table of two cities (%s)" % [table.keys()])
	var ald: Array = table.get(&"aldermere", [])
	var cap: Array = table.get(&"capital", [])
	t.check(ald.size() == 8 and cap.size() == 8, "each ring has eight targets (%d, %d)" % [ald.size(), cap.size()])
	var same := ald.size() == ALDERMERE_RING.size()
	for i in mini(ald.size(), ALDERMERE_RING.size()):
		same = same and (ald[i] as Vector2).is_equal_approx(ALDERMERE_RING[i])
	t.check(same, "Aldermere's ring is today's list, element for element")
	t.check(ald.size() > 4 and (ald[4] as Vector2) == TownLayout.CITADEL_ORIGIN, "Aldermere's fifth target is its Citadel's origin, bit for bit")
	var cs := cap.size() == CAPITAL_RING.size()
	for i in mini(cap.size(), CAPITAL_RING.size()):
		cs = cs and (cap[i] as Vector2).is_equal_approx(CAPITAL_RING[i])
	t.check(cs, "the Capital's ring is the table this test pins (%s)" % [cap])


## The Capital's overrides hold, the camera is the Citadel's, and the director's tags point at the Keep and the Capital's own exits.
static func _starts(t) -> void:
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.brief == PackedStringArray(["The Capital and its Royal Keep.", "Bring the whole kingdom down."]) and def.intro_from == Vector2(16.4, -9.0),
		"the Capital's brief and intro start are overridden (%s, %s)" % [def.brief, def.intro_from])
	t.check(def.camera() == City.by_id(&"capital").citadel_origin(), "no camera_at: the camera is the Capital's Citadel (%s)" % [def.camera()])
	var d := Cap.starts(t, ID) as LastJudgementDirector
	t.check(d != null, "the Capital hosts Last Judgement and its director starts")
	if d == null:
		return
	var tags := d.tags()
	var keep: MapTag = null
	var gates := 0
	for tag: MapTag in tags:
		if tag.label == "CITADEL":
			keep = tag
		elif tag.label == "GATE":
			gates += 1
	t.check(keep != null and keep.at.distance_to(Vector2(0.0, -25.5)) < 5.0, "the Citadel's tag points at the Keep (%s)" % [keep.at if keep != null else "none"])
	var exits: Array[Vector2] = City.by_id(&"capital").exits()
	var landed := 0
	for e in exits:
		for tag: MapTag in tags:
			if tag.label == "GATE" and tag.at.distance_to(e) < 8.0:
				landed += 1
				break
	print("CAPITAL judgement exits %s gate tags %d (near an exit: %d)" % [exits, gates, landed])
	t.check(exits.size() == 3 and exits[0] == Vector2(7, 39.6) and exits[1] == Vector2(-39.6, -13), "the Capital's exits (%s)" % [exits])
	t.check(gates >= 1 and landed >= 1, "the gate tags stand at the Capital's own exits")
	_words_true(t, d)


## The eight targets: a point inside the map and a standing building's footprint within 2.5 (the nearest printed).
static func _spots_land(t, cap: Dictionary) -> void:
	var table: Dictionary = load(BC).get_script_constant_map().get("JUDGEMENT_TARGETS", {})
	var ring: Array = table.get(&"capital", [])
	var env: EnvironmentField = cap.env
	for i in ring.size():
		var g: Vector2 = ring[i]
		var best := INF
		var role: StringName = &""
		for s in env.structures():
			if s.destroyed:
				continue
			var d := _rect_dist(s.footprint, g)
			if d < best:
				best = d
				role = s.role
		print("CAPITAL judgement target %d %s: nearest building %.1f away (%s)" % [i, g, best, role])
		t.check(best <= 2.5, "target %d %s has a standing building within 2.5 (%.1f, %s)" % [i, g, best, role])


static func _rect_dist(r: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return sqrt(dx * dx + dy * dy)


## The policy functions read the active city, no TownLayout coordinate and no direct index into the ring.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string(BC).replace("\r\n", "\n")
	var bodies := {"_judgement": _slice(bc, "func _judgement(", "\nfunc "), "_judgement_target": _slice(bc, "func _judgement_target(", "\nfunc "),
		"_play_judgement": _slice(bc, "func _play_judgement(", "\nfunc "), "_richest": _slice(bc, "func _richest(", "\nfunc ")}
	var re := RegEx.create_from_string("\\bTownLayout\\b|JUDGEMENT_TARGETS\\[\\w*\\s*%")
	t.check(re.search("x TownLayout.CITADEL_ORIGIN") != null and re.search("JUDGEMENT_TARGETS[next % 3]") != null
		and re.search("City.current().citadel_origin()") == null and re.search("JUDGEMENT_TARGETS.get(City.current().id()") == null, "the policy regex bites on samples and passes the city lookups")
	for k: String in bodies:
		var body: String = bodies[k]
		t.check(body.length() > 150, "%s is found and sliced (%d chars)" % [k, body.length()])
		var m := re.search(body)
		t.check(m == null, "%s reads no TownLayout coordinate or direct ring index (%s)" % [k, m.get_string() if m != null else ""])
	t.check("City.current().id()" in bodies["_judgement_target"] and "City.current().citadel_origin()" in bodies["_richest"], "the ring is read by city and _richest starts from the active Citadel")


static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a place only Aldermere has.
static func _words_true(t, d: LastJudgementDirector) -> void:
	var said := PackedStringArray()
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "rite", "fallen"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	var re := RegEx.create_from_string("\\b(aldermere|royal citadel|main gate|side gate|postern)\\b")
	t.check(re.search("aldermere and its royal citadel.") != null and re.search("the capital and its royal keep.") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL judgement line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names Aldermere or its gates (%s)" % [said])
	t.check(said.size() >= 8, "the lines were gathered (%d)" % said.size())


## The Citadel (the camera's own subject) is clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	Cap.camera_clear(t, def, [City.by_id(&"capital").citadel_origin()])
	City.use(&"aldermere")
