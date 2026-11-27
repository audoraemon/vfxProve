extends RefCounted
## Plan "The Capital at every tier", Task 24: The Long Night in the Capital (spec 6.4.2). The night is three acts that are other missions' directors, so the Capital's
## overrides for it (src/game/town/cities/capital_missions/long_night.gd) carry an `acts` section (MissionBook.in_city() applies each act's def and director values as it does the
## root's). The Festival's and the Procession's values are those missions' own files (one source); the Omen is a WarningDirector whose post and its banner's name are
## town vars (`post`, `post_name`: the post is the input, `gate_spot` is the snapped place setup derives, so it cannot be overridden). Aldermere's night is unchanged field
## for field; an unknown act id is reported and changes nothing; the Omen's watchman walks to the bell's foot in Aldermere's band; the cameras keep their tags clear; the
## policies read the active city; the words name no place of Aldermere.

const ID := "long_night"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DIR := "res://src/game/town/cities/capital_missions/"
const WEST_GATE := Vector2(-22.4, -13.0)


## A town that has only the overrides it is given (a fixture for the unknown-act check).
class _Fixture extends CityDef:
	var ov := {}

	func id() -> StringName: return &"fixture_night"

	func mission_overrides(_id: String) -> Dictionary: return ov


static func run(t) -> void:
	City.use(&"aldermere")
	_overrides_valid(t)
	Cap.hostable(t, ID)
	_acts_applied(t)
	_unknown_act(t)
	_seeded(t)
	_policy_reads_vars(t)
	_aldermere_pin(t)
	_starts(t)
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Long Night test leaves Aldermere active")


static func _load(name: String) -> Dictionary:
	return (load(DIR + name + ".gd") as GDScript).call("overrides")


## The overrides: a def and an acts section; every act exists, its def and director values apply cleanly to a fresh act and its director, each with the type of the var it sets.
static func _overrides_valid(t) -> void:
	var ov := City.by_id(&"capital").mission_overrides(ID)
	t.check("acts" in Overrides.KEYS and ov.has("def") and ov.has("acts"), "the Capital has a def and an acts section for the Long Night, and `acts` is a known key (%s)" % [ov.keys()])
	var acts: Dictionary = ov.get("acts", {})
	t.check(acts.keys() == ["omen", "festival", "procession", "judgement"], "every act of the night has overrides (%s)" % [acts.keys()])
	var bad := PackedStringArray()
	var typed := true
	for id: Variant in acts:
		var act := MissionBook.long_night().act(String(id))
		if act == null:
			bad.append(String(id))
			continue
		var d := act.make_director()
		var sec: Dictionary = acts[id]
		bad.append_array(Overrides.apply(act, (sec.get("def", {}) as Dictionary).duplicate(true)))
		bad.append_array(Overrides.apply(d, (sec.get("director", {}) as Dictionary).duplicate(true), Overrides.town_vars(d)))
		var fresh := MissionBook.long_night().act(String(id))
		for key: Variant in sec.get("def", {}):
			typed = typed and typeof(fresh.get(String(key))) == typeof(sec.def[key])
		var made := fresh.make_director()
		for key: Variant in sec.get("director", {}):
			typed = typed and typeof(made.get(String(key))) == typeof(sec.director[key])
	t.check(bad.is_empty() and typed, "the acts' overrides apply cleanly and every value has the type of the var it sets (refused %s)" % [bad])
	var root := MissionBook.long_night()
	t.check(Overrides.apply(root, (ov.get("def", {}) as Dictionary).duplicate(true)).is_empty(), "the root def's overrides apply cleanly")


## in_city() gives the Capital's night each act's values; the Festival's and the Procession's are those missions' own (one source); Aldermere's night is unchanged field for field.
static func _acts_applied(t) -> void:
	var m := MissionBook.in_city(MissionBook.long_night(), &"capital")
	t.check(m.city == &"capital" and m.camera_at == Vector2(-21.0, -13.7) and m.intro_from == Vector2(-21.0, -7.7), "the night's own camera and intro are the west gate's")
	var omen := m.act("omen")
	t.check(omen.camera_at == Vector2(-21.0, -13.7) and omen.intro_from == Vector2(-21.0, -7.7)
		and omen.brief == PackedStringArray(["A star falls over the west gate.", "A watchman runs to wake the bell."]), "the Omen's camera, intro and brief")
	var fest := _load("festival").def as Dictionary
	t.check(m.act("festival").camera_at == Vector2(-7.5, -2.5) and m.act("festival").intro_from == Vector2(-7.5, 5.5)
		and m.act("festival").camera_at == fest.camera_at and m.act("festival").intro_from == fest.intro_from, "the Festival act's camera and intro are the Festival's own (-7.5, -2.5) and (-7.5, 5.5)")
	var pr := _load("procession")
	var proc := m.act("procession")
	t.check(proc.camera_at == pr.def.camera_at and proc.intro_from == pr.def.intro_from and proc.camera_at == Vector2(-1.0, -12.0) and proc.intro_from == Vector2(0.0, -25.5),
		"the Procession act's camera and intro are the Procession's own (%s, %s)" % [proc.camera_at, proc.intro_from])
	var pd := proc.make_director() as ProcessionDirector
	t.check(pd.route_spots == pr.director.route_spots and pd.route_spots.size() == 5 and pd.route_spots[0] == Vector2(0.0, -20.5),
		"the Procession act's director walks the Procession's own five route spots")
	var jud := m.act("judgement")
	t.check(jud.intro_from == Vector2(16.4, -9.0) and jud.camera_at == Vector2(0.0, -25.5) and jud.camera_at == CapitalCity.CITADEL_ORIGIN
		and jud.intro_from == _load("last_judgement").def.intro_from, "the Judgement act starts at the harbour gate and rests on the Citadel")
	var od := omen.make_director()
	t.check(od.get("post") == WEST_GATE and od.get("post_name") == "THE WEST GATE", "the Omen's director posts its watchman at the west gate")
	for a: ActDef in m.acts:
		t.check(a.city == &"capital", "act %s is in the Capital" % a.id)
	# The values are copies: changing a made director leaves the overrides as they were.
	var again := m.act("procession").make_director() as ProcessionDirector
	again.route_spots[0] = Vector2(99.0, 99.0)
	t.check(_load("procession").director.route_spots[0] == Vector2(0.0, -20.5) and _load("long_night").acts.procession.director.route_spots[0] == Vector2(0.0, -20.5),
		"mutating a made director leaves the override data as it was")
	# Aldermere: put in Aldermere (no overrides) or plain, the night is the same field for field.
	var plain := MissionBook.long_night()
	var home := MissionBook.in_city(MissionBook.long_night(), &"aldermere")
	t.check(_fields(plain) == _fields(home), "the night put in Aldermere is the plain night, field for field")
	t.check(plain.act("omen").camera_at == TownLayout.MAIN_GATE.get_center().lerp(TownLayout.BELL_TOWER.get_center(), 0.35)
		and plain.act("omen").brief[0] == "A star falls over the Main Gate." and not plain.act("omen").tune.is_valid()
		and (plain.act("omen").make_director() as WarningDirector).post == WarningDirector.GATE_SPOT, "Aldermere's Omen is the Main Gate's, with no tuning")


## The def fields of the night and each act that a town's overrides could touch.
static func _fields(m: MissionDef) -> Array:
	var out := []
	var defs: Array = [m]
	defs.append_array(m.acts)
	for d: MissionDef in defs:
		out.append([d.id, d.camera_at, d.intro_from, d.brief, d.goal, d.lose, d.clock, d.slots, d.dp_capacity, d.tune.is_valid()])
	return out


## An overrides dictionary with an unknown act id reports one error (the id) and changes nothing.
static func _unknown_act(t) -> void:
	var town := _Fixture.new()
	town.ov = {"acts": {"nope": {"def": {"camera_at": Vector2(1.0, 2.0)}}}}
	var before := _fields(MissionBook.long_night())
	var m := MissionBook.in_city(MissionBook.long_night(), &"fixture_night", town)
	var after := _fields(m)
	t.check(after == before and m.city == &"fixture_night", "an unknown act id changes no field of the night")
	var bad := MissionBook.apply_acts(MissionBook.long_night(), {"nope": {}, "omen": {"def": {"no_such": 1.0}}})
	t.check(bad == PackedStringArray(["nope", "no_such"]), "an unknown act id and an unknown key are each reported once (%s)" % [bad])
	t.check(MissionBook.apply_acts(MissionBook.warning(), {"omen": {}}) == PackedStringArray(["omen"]), "a mission with no acts reports every act id")


## The Warning's post and its banner's name are town vars seeded from the consts; the consts stay; every read of GATE_SPOT is the var's default.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := WarningDirector.new()
	t.check(d.post == WarningDirector.GATE_SPOT and d.post_name == "THE MAIN GATE" and d.gate_spot == Vector2.INF, "a fresh Warning keeps its Main Gate post and name; gate_spot is derived at setup")
	t.check(Overrides.town_vars(d) == ["post", "post_name"], "the Warning's town vars (%s)" % [Overrides.town_vars(d)])
	t.check(WarningDirector.GATE_SPOT == Vector2(2.7, 14.5), "GATE_SPOT is Aldermere's, untouched")
	var src := FileAccess.get_file_as_string("res://src/game/mission/warning_director.gd").replace("\r\n", "\n")
	var reads := RegEx.create_from_string("\\bGATE_SPOT\\b").search_all(src)
	t.check(src.count("var post: Vector2 = GATE_SPOT") == 1 and src.count("var post_name: String = \"THE MAIN GATE\"") == 1, "the town vars are declared once, typed")
	t.check(reads.size() == 2, "GATE_SPOT is read only by the const and the var `post`'s default (%d reads)" % reads.size())
	t.check(Overrides.town_vars(StarfallDirector.new()) == ["star_falls", "stop_wait"], "the Starfall's town vars are its own, unchanged")
	var r := RingerDirector.new()
	t.check(r.post == WarningDirector.GATE_SPOT and r.post_name == "THE MAIN GATE", "a Ringer's fresh post is the Warning's")


## An Aldermere Omen after setup stands at the Main Gate as before.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.long_night().act("omen"))
	var d: WarningDirector = s.d
	var free: Vector2 = s.crowd._grid.nearest_walkable(WarningDirector.GATE_SPOT)
	t.check(d.gate_spot == free and d.post_name == "THE MAIN GATE" and d.watchman != null and d.watchman.ground_pos == free, "Aldermere's watchman stands at the Main Gate's walkable ground (%s)" % [d.gate_spot])
	Kit.done(s)


## The Capital's director after setup reads back every override; the watchman's walk to the bell's foot is in Aldermere's band; the opening is not crowded.
static func _starts(t) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.long_night().act("omen"))
	var ad: WarningDirector = a.d
	var aw := Cap.walk(a.crowd._grid, ad.gate_spot, a.crowd.bell.foot)
	var a_near := _near(a.crowd, ad.gate_spot)
	Kit.done(a)
	City.use(&"capital")
	var m := MissionBook.in_city(MissionBook.long_night(), &"capital")
	var c := Kit.world(m.act("omen"))
	var d: WarningDirector = c.d
	t.check(d.post == WEST_GATE and d.post_name == "THE WEST GATE" and d.gate_spot.distance_to(WEST_GATE) <= 0.6, "the Capital's Omen reads back its post after setup (%s snapped to %s)" % [d.post, d.gate_spot])
	t.check(d.watchman != null and d.watchman.ground_pos == d.gate_spot, "the watchman stands at the west gate")
	var cw := Cap.walk(c.crowd._grid, d.gate_spot, c.crowd.bell.foot)
	Cap.parity(t, "the Omen's watchman to the bell's foot", cw, aw)
	var c_near := _near(c.crowd, d.gate_spot)
	print("CAPITAL night opening within 8 of the post: capital soldiers %d citizens %d; aldermere soldiers %d citizens %d" % [c_near.x, c_near.y, a_near.x, a_near.y])
	t.check(c_near.x <= 14 and c_near.y >= 3, "the opening: at most 14 soldiers and at least 3 citizens within 8 of the west gate post (%s)" % [c_near])
	t.check(a_near.x <= 14 and a_near.y >= 3, "the opening at Aldermere's post, for comparison (%s)" % [a_near])
	Cap.spots_land(t, {"grid": c.crowd._grid}, {"the west gate post": WEST_GATE}, 0.6)
	_words_true(t, m, d)
	Kit.done(c)
	# The Procession's director of the night, set up in the Capital, has the five spots on its route.
	var p := Kit.world(m.act("procession"))
	var pd: ProcessionDirector = p.d
	t.check(pd.route.size() == 5 and pd.route_spots.size() == 5 and pd.route[0].distance_to(pd.route_spots[0]) <= 1.0, "the night's Procession walks the Capital's five points after setup")
	Kit.done(p)
	City.use(&"aldermere")


## Soldiers (x) and citizens (y) within 8 of `at`, out of doors and alive.
static func _near(crowd: Crowd, at: Vector2) -> Vector2i:
	var n := Vector2i.ZERO
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= 8.0:
			n.x += 1
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= 8.0:
			n.y += 1
	return n


## The policies read the active city: no Aldermere const or TownLayout coordinate in the night's policy functions.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var b5 := FileAccess.get_file_as_string("res://tools/dev/routes/tier5_b.gd").replace("\r\n", "\n")
	var night := _slice(bc, "\nfunc _night(", "\nfunc ")
	var play := _slice(bc, "\nfunc _play_act(", "\nfunc ") + _slice(bc, "\nfunc _play_act_b(", "\nfunc ")
	var jud := _slice(bc, "\nfunc _play_judgement(", "\nfunc ")
	var nb := _slice(b5, "\nstatic func act_night(", "\nstatic func ") + _slice(b5, "\nstatic func _omen_runner(", "\nstatic func ")
	t.check(night.length() > 3000 and play.length() > 800 and jud.length() > 1500 and nb.length() > 600, "the night's policy functions are found and sliced (%d, %d, %d, %d chars)" % [night.length(), play.length(), jud.length(), nb.length()])
	var re := RegEx.create_from_string("TownLayout\\.|\\bGATE_SPOT\\b|\\bCITADEL_ORIGIN\\b|Places\\.")
	t.check(re.search("rules.caster.call(heaven, TownLayout.CITADEL_ORIGIN, {})") != null and re.search("w.gate_spot") == null and re.search("City.current().citadel_origin()") == null
		and re.search("WarningDirector.GATE_SPOT") != null and re.search("_judgement_target(next)") == null, "the scan regex bites on samples and passes the city lookups")
	for body: String in [night, play, jud, nb]:
		var m := re.search(body)
		t.check(m == null, "a night policy reads no Aldermere const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
	t.check("City.current().citadel_origin()" in night and "_judgement_target(next)" in jud and "w.gate_spot" in nb, "the night's policies read the active city, the target table and the director")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the Omen shows names a place that is Aldermere's only: the brief, the goal and lose lines, the hints, the tags, the banner's gate, the tour.
static func _words_true(t, m: MissionDef, d: WarningDirector) -> void:
	var omen := m.act("omen")
	var said := PackedStringArray()
	said.append_array(omen.brief)
	said.append_array([omen.goal, omen.goal_label, omen.lose, m.goal, m.goal_label, m.lose, "A STAR FALLS OVER %s" % d.post_name, "THE WATCHMAN UNBARS %s" % d.post_name])
	for phase in ["", "relay", "bell", "herald"]:
		said.append(MissionHints.line("warning", phase))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var re := RegEx.create_from_string("\\b(main gate|postern|side gate|north-east|workshops|east tavern|great market)\\b")
	t.check(re.search("a star over the main gate") != null and re.search("a star over the west gate") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var found := re.search(line.to_lower())
		if found != null:
			wrong = true
			print("CAPITAL night line names '%s': %s" % [found.get_string(), line])
	t.check(not wrong and said.size() >= 14, "no line of the Omen names a gate or place of Aldermere (%d lines)" % said.size())
	t.check("west gate" in " ".join(said).to_lower() and "A STAR FALLS OVER THE WEST GATE" in said, "the Omen's lines name the west gate")


## Every night camera keeps its tags clear of the padded HUD stack at its resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var m := MissionBook.in_city(MissionBook.long_night(), &"capital")
	var cap := Cap.town(&"capital")
	var bell := City.by_id(&"capital").landmark(&"bell_tower").get_center()
	var proc: Array = (m.act("procession").make_director() as ProcessionDirector).route_spots.duplicate()
	proc.append(City.by_id(&"capital").ship_at())
	Cap.camera_clear(t, m.act("omen"), [WEST_GATE, bell])
	Cap.camera_clear(t, m.act("festival"), [Places.rect(&"market_square").get_center(), Places.at(&"fountain")])
	Cap.camera_clear(t, m.act("procession"), proc)
	Cap.camera_clear(t, m.act("judgement"), [CapitalCity.CITADEL_ORIGIN])
	Cap.drop(cap)
	City.use(&"aldermere")
