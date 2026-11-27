extends RefCounted
## Plan "The Capital at every tier", Task 15: the Bishop in the Capital (spec 6.3.2). His house and the chapter house are the director's town vars
## (refuge_spots, `safe_at` seeded in _init(), Informer's pattern); with no overrides (Aldermere) every one is what it was, the other Assassinate missions
## keep their own `safe_at`; the town's overrides (src/game/town/cities/capital_missions/bishop.gd) are valid and hold after setup; the refuges are
## standing dwellings (his house, the chapter house) and the Temple; his house to the chapter house to the Temple door and the Keep's gate to his house
## walk in Aldermere's band (real grid walks); the Knights stand more than 1.6 apart; the words the player reads name no Aldermere place; the policies
## read the director.

const ID := "bishop"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_other_assassinates(t)
	_policy_reads_vars(t)
	_aldermere_pin(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var spots := {"safe_at": dov.safe_at, "citadel_gate": City.by_id(&"capital").place(&"citadel_gate")}
	for p: Vector2 in dov.refuge_spots:
		spots["refuge %s" % p] = p
	Cap.spots_land(t, cap, spots, 1.0)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Bishop test leaves Aldermere active")


## A fresh director holds each town var at its const (Aldermere's); the list is a copy; the town vars are the two.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := BishopDirector.new()
	t.check(d.refuge_spots == BishopDirector.REFUGE_SPOTS, "a fresh director's refuge_spots equal REFUGE_SPOTS")
	d.refuge_spots.append(Vector2.ZERO)
	t.check(BishopDirector.REFUGE_SPOTS.size() == 2, "refuge_spots is a copy: the const is untouched")
	t.check(BishopDirector.new().safe_at == BishopDirector.CITADEL_GATE, "a fresh director's safe_at is the Citadel gate place, bit for bit (%s)" % [d.safe_at])
	t.check(Overrides.town_vars(d) == ["refuge_spots", "safe_at"], "the Bishop's town vars (%s)" % [Overrides.town_vars(d)])
	t.check(MissionBook.bishop().camera_at == BishopDirector.CAMERA_AT and MissionBook.bishop().intro_from == BishopDirector.CAMERA_AT + Vector2(0.0, 6.0),
		"Aldermere's camera is still CAMERA_AT")
	t.check(BishopDirector.REFUGE_SPOTS == [Vector2(12.0, -6.8), Vector2(7.9, -12.3)] and BishopDirector.CITADEL_GATE == Vector2(-10.5, -7.6)
		and BishopDirector.ARRIVE_AT == 45.0 and BishopDirector.CHAIN == 45.0 and BishopDirector.POST_GAP == 1.8 and BishopDirector.STANDING == 2
		and BishopDirector.ESCORT == 3 and BishopDirector.REFUGE_WORDS == ["his house", "the chapter house", "the Temple"],
		"the places, the numbers and the words are untouched")
	t.check(Array(MissionNeeds.of(ID)) == ["temple", "citadel_gate"], "the Bishop needs the Temple and the Citadel's gate (%s)" % [MissionNeeds.of(ID)])


## The other Assassinate missions start with the safe place they had: unset (the Informer seeds its own, the Temple's door).
static func _other_assassinates(t) -> void:
	City.use(&"aldermere")
	t.check(AssassinateDirector.new().safe_at == Vector2.INF and TaxCollectorDirector.new().safe_at == Vector2.INF
		and ExpelInquisitorDirector.new().safe_at == Vector2.INF and InformerDirector.new().safe_at == InformerDirector.TEMPLE_DOOR,
		"AssassinateDirector, Tax Collector, Expel Inquisitor and Informer start with the safe_at they had")
	t.check(not "refuge_spots" in Overrides.town_vars(InformerDirector.new()) and not "refuge_spots" in Overrides.town_vars(TaxCollectorDirector.new()),
		"the Bishop's town vars are not the others'")


## An Aldermere director's places after setup are what they were: the refuges, his gate; the tour words are as before.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.bishop())
	var d: BishopDirector = s.d
	t.check(d.safe_at == d._walkable(Vector2(-10.5, -7.6)) and d.refuges.size() == 3 and d.refuges[2].role == &"temple"
		and d.refuges[0].center().distance_to(Vector2(12.0, -6.8)) < 4.0 and d.refuges[1].center().distance_to(Vector2(7.9, -12.3)) < 4.0,
		"Aldermere's gate and refuges are as before (%s)" % [d.safe_at])
	t.check(d.tour().size() == 3 and String(d.tour()[1][1]) == "The chapter house, his next refuge. Burn each one to drive him on.", "the tour is as before")
	print("ALDERMERE bishop refuges %s %s %s gate %s" % [d.refuges[0].center(), d.refuges[1].center(), d.refuges[2].center(), d.safe_at])
	Kit.done(s)


## The Capital's director after setup reads back every override; his walks are in Aldermere's band.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var d := Cap.starts(t, ID) as BishopDirector
	t.check(d != null and d.refuge_spots == dov.refuge_spots, "the director reads back the Capital's refuge_spots")
	if d == null:
		return
	var citadel: Vector2 = City.current().place(&"citadel_gate")
	t.check(d.safe_at.distance_to(citadel) < 1.0 and d.safe_at.distance_to(dov.safe_at) < 1.0, "the safe place is the Keep's gate and holds after setup (%s)" % [d.safe_at])
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(2.0, -9.0) and def.intro_from == Vector2(2.0, -3.0), "camera_at and intro_from are overridden together (C9)")
	t.check(d.refuges.size() == 3 and d.refuges[2].role == &"temple" and d.doors.size() == 3, "his house, the chapter house and the Temple are refuges (%d)" % d.refuges.size())
	if d.refuges.size() != 3 or d.doors.size() != 3:
		return
	var distinct := {}
	for i in 2:
		var h := d.refuges[i]
		distinct[h] = true
		t.check(RuinWish.fits(h, "house") and not h.destroyed, "%s %s is a standing dwelling" % [BishopDirector.REFUGE_WORDS[i], h.center()])
		t.check(h.center().distance_to(dov.refuge_spots[i]) <= 3.5, "%s %s is near its spot %s (%.1f)" % [BishopDirector.REFUGE_WORDS[i], h.center(), dov.refuge_spots[i], h.center().distance_to(dov.refuge_spots[i])])
	t.check(distinct.size() == 2 and d.refuges[0] != d.refuges[2] and d.refuges[1] != d.refuges[2], "his house, the chapter house and the Temple are three distinct buildings")
	print("CAPITAL bishop refuges %s %s %s doors %s gate %s" % [d.refuges[0].center(), d.refuges[1].center(), d.refuges[2].center(), d.doors, d.safe_at])
	# the Knights: standing posts more than 1.6 apart
	var posts := []
	for p: BishopDirector.Post in d.posts:
		if p.spot != Vector2.INF:
			posts.append(p.spot)
	t.check(posts.size() >= 6, "the Knights' posts were placed (%d)" % posts.size())
	Cap.spread(t, posts)
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## His house to the chapter house, the chapter house to the Temple's door and the Keep's gate to his house: Capital against Aldermere on the real grids.
static func _walk_parity(t, d: BishopDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.bishop())
	var ad: BishopDirector = a.d
	Cap.parity(t, "his house to the chapter house", Cap.walk(cap.grid, d.doors[0], d.doors[1]), Cap.walk(ald.grid, ad.doors[0], ad.doors[1]))
	Cap.parity(t, "the chapter house to the Temple's door", Cap.walk(cap.grid, d.doors[1], d.doors[2]), Cap.walk(ald.grid, ad.doors[1], ad.doors[2]))
	Cap.parity(t, "the Keep's gate to his house", Cap.walk(cap.grid, d.safe_at, d.doors[0]), Cap.walk(ald.grid, ad.safe_at, ad.doors[0]))
	Kit.done(a)
	City.use(&"capital")


## The policies read the director's refuges and gate, no Aldermere const or coordinate.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "func _bishop_act(", "\nfunc ")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier4_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "static func act_bishop(", "\nstatic func state_bishop(")
	t.check(act.length() > 1500 and rb.length() > 3000, "the bishop policy functions are found and sliced (%d, %d chars)" % [act.length(), rb.length()])
	var re := RegEx.create_from_string("\\b(REFUGE_SPOTS|CITADEL_GATE|CAMERA_AT|ARRIVE_AT|TAKEN_AT|REFUGE_WORDS)\\b|TownLayout\\b")
	var plus := RegEx.create_from_string("\\b(safe_at|refuge_spots|doors\\[\\d\\])\\s*[+-]")
	t.check(re.search("x BishopDirector.REFUGE_SPOTS[0]") != null and re.search("TownLayout.CITADEL_ORIGIN") != null and re.search("d.refuges[0]") == null
		and plus.search("d.safe_at + Vector2(1.0, 0.0)") != null and plus.search("d.safe_at - Vector2(1.0, 0.0)") != null and plus.search("d.safe_at,") == null, "the policy regexes bite on a sample and pass the director's vars")
	for body: String in [act, rb]:
		var m := re.search(body)
		t.check(m == null, "a bishop policy reads no Bishop const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
		t.check(plus.search(body) == null, "a bishop policy has no hard-coded offset from a director point")
		t.check("d.refuges" in body or "d.current_refuge()" in body, "each bishop policy reads the director's refuges")
	t.check("d.in_square" in act and "d.in_square" in rb, "each bishop policy reads the director's square flag")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a place only Aldermere has: the tour, the brief, the goal, the hints, the steps, the tags.
static func _words_true(t, d: BishopDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "waiting", "guarded", "open", "burning", "square", "running"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	said.append_array(BishopDirector.REFUGE_WORDS)
	said.append(d.safe_label)
	var re := RegEx.create_from_string("\\b(postern|dock|cellars|long west street|north quarter|south street|main gate)\\b")
	t.check(re.search("by the cellars") != null and re.search("the keep's gate") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL bishop line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names the postern, the dock, the cellars or a street of Aldermere (%s)" % [said])
	t.check(d.tour().size() == 3 and MissionHints.line(ID, "square") != "" and said.size() >= 18, "the lines were gathered (%d)" % said.size())


## His house, the chapter house, the Temple's door and the Keep's gate (or their edge arrows) are clear of the padded HUD stack at the camera's resting
## place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as BishopDirector
	var at: Array = []
	for s in d.refuges:
		at.append(s.center())
	at.append(d.doors[2])
	at.append(d.safe_at)
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
