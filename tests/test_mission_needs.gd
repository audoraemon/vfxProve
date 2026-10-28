extends RefCounted
## v0.12 Task 3: missions list what a town must have for them (MissionNeeds), the places a director reads are all listed, and the
## intro camera asks the town (MissionDef.camera()) while MissionBook's builders keep Aldermere's own framing.

## Every mission id that exists: the board's three, the campaign's, the tier missions, the dev ones, the Awaken rites (god P3) and the board's list.
static func _all_ids() -> Array[String]:
	var out: Array[String] = []
	for list: Array in [MissionBook.all(), MissionBook.campaign_missions(), MissionBook.tier_missions(), MissionBook.dev_missions(),
			MissionBook.rite_missions()]:
		for m: MissionDef in list:
			if not out.has(m.id):
				out.append(m.id)
	for id: String in TierBook.all():
		if not out.has(id):
			out.append(id)
	return out


static func run(t) -> void:
	City.use(&"aldermere")
	_every_mission(t)
	_tier1(t)
	_reads_are_needs(t)
	_unknown_and_counts(t)
	_camera(t)
	_builders_keep_aldermere(t)
	_gate_aliases(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the mission-needs test leaves Aldermere the active city")


## Every mission lists its needs, Aldermere hosts all of them, and no row is left for a mission that is gone.
static func _every_mission(t) -> void:
	var al := City.by_id(&"aldermere")
	var ids := _all_ids()
	t.check(ids.size() == 29, "all 29 missions are listed (%d)" % ids.size())
	for id: String in ids:
		t.check(MissionNeeds.TABLE.has(id), "%s lists its needs" % id)
		if MissionNeeds.TABLE.has(id):
			t.check(Places.can_host(id, al), "Aldermere hosts %s" % id)
	for id: String in MissionNeeds.TABLE:
		t.check(ids.has(id), "the needs row '%s' is a mission that exists" % id)
	var m := MissionBook.tax_collector()
	t.check(m.needs() == MissionNeeds.of("tax_collector") and not m.needs().is_empty(), "MissionDef.needs() reads the table")
	t.check(MissionBook.capital_sandbox().needs().is_empty(), "the sandbox's def needs nothing")


## Spec 1.4's five Tier 1 rows (Spoiled Harvest's lists the Temple too: every director reads it through MissionDirector).
static func _tier1(t) -> void:
	t.check(MissionNeeds.of("warning") == PackedStringArray(["temple", "bell_tower"]), "Starfall: temple, bell_tower")
	t.check(MissionNeeds.of("tax_collector") == PackedStringArray(["temple", "bell_tower", "citadel", "citadel_gate", "workshop"]),
		"the Tax Collector's row")
	t.check(MissionNeeds.of("spoiled_harvest") == PackedStringArray(["citadel", "citadel_gate", "temple"]), "Spoiled Harvest's row")
	t.check(MissionNeeds.of("lost_lamb") == PackedStringArray(["temple"]), "the Lost Lamb's row")
	t.check(MissionNeeds.of("first_prayers") == PackedStringArray(["temple", "bell_tower", "market_square"]), "First Prayers' row")


## Every place a director reads is one its mission needs. The scan covers the mission's director (and each act's), every base script
## up to MissionDirector, and reads `Places.rect/at/point(&"name")`, `landmark(&"name")`, `place(&"name")`, `citadel_origin()`
## and the city's lists (`taverns()[0]` needs two taverns).
static func _reads_are_needs(t) -> void:
	var name_re := RegEx.create_from_string("(?:Places\\.(?:rect|at|point)|\\.landmark|\\.place)\\(&\"(\\w+)\"\\)")
	var list_re := RegEx.create_from_string("\\.(gate_towers|barns|taverns|wells|fountains|districts)\\(\\)(?:\\[(\\d+)\\])?")
	var checked := 0
	var scripts_seen := 0
	for id: String in _all_ids():
		var defs: Array[MissionDef] = []
		var home := MissionBook.get_mission(id)
		if home.id == id:
			defs.append(home)
		if TierBook.has(id):
			var board := TierBook.board(id)
			if board != null:
				defs.append(board)
		var reads := {}  # need name -> the count read
		for def: MissionDef in defs:
			for s: GDScript in _director_scripts(def):
				scripts_seen += 1
				var base: GDScript = s
				while base != null:
					_collect(base.resource_path, name_re, list_re, reads)
					base = base.get_base_script()
		var needs := {}  # need name -> the count listed
		for need: String in MissionNeeds.of(id):
			var base_name := need.get_slice(":", 0)
			needs[base_name] = maxi(int(needs.get(base_name, 0)), int(need.get_slice(":", 1)) if ":" in need else 1)
		var missing := PackedStringArray()
		for name: String in reads:
			if int(needs.get(name, 0)) < int(reads[name]):
				missing.append("%s:%d" % [name, int(reads[name])])
		t.check(missing.is_empty(), "%s lists every place its directors read (missing %s)" % [id, ", ".join(missing)])
		checked += 1
	t.check(checked == 29 and scripts_seen > 25, "the scan walks every mission's directors (%d missions, %d scripts)" % [checked, scripts_seen])
	# The scan sees a read: a made-up script that reads a place no row lists is caught.
	var probe := {}
	_collect_text("var a = Places.rect(&\"temple\")\nvar b = City.current().taverns()[1]\n# Places.rect(&\"ghost\")\n",
		name_re, list_re, probe)
	t.check(probe.has("temple") and int(probe.get("taverns", 0)) == 2 and not probe.has("ghost"), "the scan reads names and lists, not comments")


## The directors of a def and of each of its acts.
static func _director_scripts(def: MissionDef) -> Array[GDScript]:
	var out: Array[GDScript] = []
	if def.director != null:
		out.append(def.director)
	for a: ActDef in def.acts:
		if a.director != null and not out.has(a.director):
			out.append(a.director)
	return out


static func _collect(path: String, name_re: RegEx, list_re: RegEx, reads: Dictionary) -> void:
	_collect_text(FileAccess.get_file_as_string(path), name_re, list_re, reads)


static func _collect_text(text: String, name_re: RegEx, list_re: RegEx, reads: Dictionary) -> void:
	for line: String in text.split("\n"):
		var code := line.get_slice("#", 0)
		for m: RegExMatch in name_re.search_all(code):
			reads[m.get_string(1)] = maxi(int(reads.get(m.get_string(1), 0)), 1)
		for m: RegExMatch in list_re.search_all(code):
			var n := int(m.get_string(2)) + 1 if m.get_string(2) != "" else 1
			reads[m.get_string(1)] = maxi(int(reads.get(m.get_string(1), 0)), n)
		if code.contains(".citadel_origin()"):
			reads["citadel"] = maxi(int(reads.get("citadel", 0)), 1)


## An id with no row cannot be hosted (an error is printed); a count on a non-list need is an error but the name is still asked.
static func _unknown_and_counts(t) -> void:
	var al := City.by_id(&"aldermere")
	t.check(not Places.can_host("no_such_mission", al), "a mission with no needs row is not hostable")
	t.check(MissionNeeds.of("no_such_mission").is_empty(), "an unknown id has no needs")
	t.check(Places.has(al, &"temple:2"), "a count on a landmark need is an error, and the landmark is still asked (it printed one)")
	t.check(Places.has(al, &"barns:4") and not Places.has(al, &"barns:5") and Places.has(al, &"districts:8"),
		"list counts are asked as at-least")
	for id: String in ["armoury", "crowns_bread", "heretic_hunt", "sermon"]:
		t.check(Places.can_host(id, al), "Aldermere hosts %s (counts and all)" % id)
	for id: String in ["armoury", "crowns_bread"]:
		t.check(not Places.can_host(id, City.by_id(&"capital")), "the Capital models no gate towers, so it cannot host %s" % id)


## MissionDef.camera(): the city's Citadel unless the mission sets one (an ActDef too).
static func _camera(t) -> void:
	t.check(MissionDef.new().camera_at == Vector2.INF, "a def's camera_at defaults to INF")
	City.use(&"aldermere")
	t.check(MissionDef.new().camera() == TownLayout.CITADEL_ORIGIN, "unset: Aldermere's Citadel exactly")
	t.check(ActDef.new().camera() == TownLayout.CITADEL_ORIGIN, "an act inherits it")
	var d := MissionDef.new()
	d.camera_at = Vector2(1.0, 2.0)
	t.check(d.camera() == Vector2(1.0, 2.0), "a set camera_at is returned")
	City.use(&"capital")
	t.check(MissionDef.new().camera() == CapitalCity.CITADEL_ORIGIN and d.camera() == Vector2(1.0, 2.0),
		"unset: the active city's Citadel; set: its own")
	City.use(&"aldermere")


## MissionBook's builders frame Aldermere whichever city is active (a def is built before City.use()).
static func _builders_keep_aldermere(t) -> void:
	for active: StringName in [&"aldermere", &"capital"]:
		City.use(active)
		var tax := MissionBook.tax_collector()
		t.check(tax.camera_at == TownLayout.WORKSHOP.get_center() + Vector2(-2.0, 3.0)
			and tax.intro_from == tax.camera_at + Vector2(0.0, 6.0), "Tax Collector frames Aldermere's workshop (%s active)" % active)
		var gate_to_bell := TownLayout.MAIN_GATE.get_center().lerp(TownLayout.BELL_TOWER.get_center(), 0.35)
		for m: MissionDef in [MissionBook.warning(), MissionBook.long_night()]:
			t.check(m.camera_at == gate_to_bell and m.intro_from == TownLayout.MAIN_GATE.get_center() + Vector2(0.0, 6.0),
				"%s frames the Main Gate and the bell (%s active)" % [m.id, active])
		var ln := MissionBook.long_night()
		var fest := ln.act("festival")
		t.check(fest.camera_at == TownLayout.MARKET_SQUARE.get_center()
			and fest.intro_from == TownLayout.MARKET_SQUARE.get_center() + Vector2(0.0, 8.0), "the Festival frames the market (%s)" % active)
		var proc := ln.act("procession")
		t.check(proc.camera_at == TownLayout.CITADEL_ORIGIN.lerp(TownLayout.DOCK.get_center(), 0.3)
			and proc.intro_from == TownLayout.CITADEL_ORIGIN, "the Procession frames the Citadel and the dock (%s)" % active)
		var jud := ln.act("judgement")
		t.check(jud.camera_at == TownLayout.CITADEL_ORIGIN and jud.intro_from == TownLayout.MAIN_GATE.get_center(),
			"the Judgement frames the Citadel (%s)" % active)
	City.use(&"aldermere")


## The Tier 2-5 aliases and the rescue wish's literal are Aldermere's `citadel_gate` place, one point.
static func _gate_aliases(t) -> void:
	var gate := City.by_id(&"aldermere").place(&"citadel_gate")
	t.check(HarvestDirector.CITADEL_GATE == gate and TaxCollectorDirector.CITADEL_GATE == gate and RescueWish.GATE == gate,
		"the Tier 1 and wish gate consts are Aldermere's citadel_gate")
	t.check(ArmouryDirector.CITADEL_GATE == gate and BishopDirector.CITADEL_GATE == gate and HeartOfFaithDirector.CITADEL_GATE == gate
		and PrisonerDirector.CITADEL_GATE == gate, "the Tier 2-5 CITADEL_GATE consts are Aldermere's citadel_gate")
