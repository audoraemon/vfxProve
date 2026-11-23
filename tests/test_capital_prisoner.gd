extends RefCounted
## Plan "The Capital at every tier", Task 11: the Prisoner in the Capital (spec 6.2.4). She stands in the stocks at the south road's head below the
## Keep's gate and is led along the south road and the cross avenue to the harbour gate and out to the quays. The director's places are town vars
## (EscortDirector's seeded in _init(), Lost Lamb's pattern); with no overrides (Aldermere) every one is what it was; the town's overrides
## (src/game/town/cities/capital_missions/prisoner.gd) are valid and hold after setup; her road and the walk from the Keep's gate to her are in
## Aldermere's band (real grid walks); the posts stand more than 1.6 apart; every beat point is 6 or more from the Keep's gate; the way out is
## outside the walls; the words the player reads name no postern or dock; the policies read `d.road`; the other EscortDirector subclasses
## start with the values they had.

const ID := "prisoner"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_other_escorts(t)
	_policy_reads_vars(t)
	_aldermere_pin(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var spots := {"stocks_at": dov.stocks_at, "lane_foot": dov.lane_foot, "gate_at": dov.gate_at, "exit_at": dov.exit_at, "guardhouse": dov.guardhouse,
		"citadel_gate": City.by_id(&"capital").place(&"citadel_gate")}
	for p: Vector2 in dov.watch_posts:
		spots["post %s" % p] = p
	for b: Array in dov.beat_spots:
		for p: Vector2 in b:
			spots["beat %s" % p] = p
	Cap.spots_land(t, cap, spots, 1.0)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Prisoner test leaves Aldermere active")


## A fresh director holds each town var at its const (Aldermere's), the road and beats as copies.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := PrisonerDirector.new()
	t.check(d.stocks_at == PrisonerDirector.STOCKS_AT and d.lane_foot == PrisonerDirector.LANE_FOOT and d.gate_words == PrisonerDirector.GATE_WORDS
		and d.exit_name == PrisonerDirector.EXIT_NAME, "a fresh director's stocks_at, lane_foot, gate_words and exit_name are their consts")
	t.check(d.road == PrisonerDirector.ROAD and d.beat_spots == PrisonerDirector.BEATS, "a fresh director's road and beat_spots equal their consts")
	d.road.append(Vector2.ZERO)
	(d.beat_spots[0] as Array).append(Vector2.ZERO)
	t.check(PrisonerDirector.ROAD.size() == 4 and PrisonerDirector.BEATS[0].size() == 2, "road and beat_spots are copies: the consts are untouched")
	t.check(d.gate_at == PrisonerDirector.GATE_MOUTH and d.exit_at == PrisonerDirector.EXIT and d.guardhouse == PrisonerDirector.GUARDHOUSE
		and d.watch_posts.size() == 2 and d.watch_posts[0] == PrisonerDirector.POSTS[0] and d.watch_posts[1] == PrisonerDirector.POSTS[1]
		and d.return_to == PrisonerDirector.CITADEL_GATE and d.charge_start == PrisonerDirector.STOCKS_AT + Vector2(0.0, PrisonerDirector.HER_OFF),
		"EscortDirector's places are seeded in _init() at Aldermere's (the return spot is the Citadel gate place, bit for bit)")
	t.check(Overrides.town_vars(d) == ["stocks_at", "lane_foot", "road", "beat_spots", "gate_words", "exit_name", "charge_start", "gate_at", "exit_at",
		"return_to", "guardhouse", "watch_posts"], "the Prisoner's town vars (%s)" % [Overrides.town_vars(d)])
	t.check(MissionBook.prisoner().camera_at == PrisonerDirector.CAMERA_AT, "Aldermere's camera is still CAMERA_AT")
	t.check(PrisonerDirector.FREE_BY == 120.0 and PrisonerDirector.LANE_DOWN == 4.0 and PrisonerDirector.PACE == 0.33, "FREE_BY, LANE_DOWN and PACE are untouched")


## The other EscortDirector missions start with the values they had: the Lost Lamb's _init() consts and the unseeded INF of the Exodus family.
static func _other_escorts(t) -> void:
	var l := LostLambDirector.new()
	t.check(l.gate_at == LostLambDirector.GATE_MOUTH and l.exit_at == LostLambDirector.EXIT and l.charge_start == LostLambDirector.START
		and l.return_to == LostLambDirector.TEMPLE_DOOR and l.guardhouse == LostLambDirector.GUARDHOUSE and l.watch_posts.size() == 2
		and l.watch_posts[0] == LostLambDirector.POSTS[0] and l.watch_posts[1] == LostLambDirector.POSTS[1], "the Lost Lamb starts with its own places")
	for d: EscortDirector in [ExodusDirector.new(), FaceHalcyonDirector.new(), HideFaithfulDirector.new()]:
		t.check(d.gate_at == Vector2.INF and d.exit_at == Vector2.INF and d.guardhouse == Vector2.INF and d.return_to == Vector2.INF
			and d.charge_start == Vector2.INF and d.watch_posts.is_empty(), "%s starts with no place seeded (its setup assigns them)" % [d.get_script().resource_path.get_file()])
	t.check(not "road" in Overrides.town_vars(LostLambDirector.new()) and not "stocks_at" in Overrides.town_vars(ExodusDirector.new()),
		"the Prisoner's town vars are not the others'")


## An Aldermere director's places after setup are what they were: each is the walkable ground of the const it came from; the beats and posts
## the same; the stocks stand where they stood.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.prisoner())
	var d: PrisonerDirector = s.d
	t.check(d.gate_at == d._walkable(Vector2(-5.75, 14.6)) and d.exit_at == d._walkable(Vector2(-5.75, 17.4)) and d.guardhouse == d._walkable(Vector2(-11.75, 14.4))
		and d.return_to == d._walkable(Vector2(-10.5, -7.6)) and d.citadel_door == d.return_to, "Aldermere's gate, exit, guardhouse and return spot are as before")
	t.check(d.watch_posts.size() == 2 and d.watch_posts[0] == Vector2(-6.45, 14.6) and d.watch_posts[1] == Vector2(-5.05, 14.6), "the postern's posts are as before")
	t.check(d.road == [Vector2(-6.25, -6.4), Vector2(-6.25, 13.5), Vector2(-5.75, 14.6), Vector2(-5.75, 17.4)], "her road is as before")
	t.check(d.beats.size() == 2 and d.beats[0].size() == 2 and d.beats[1].size() == 2
		and d.beats[0][0] == d._walkable(Vector2(-14.0, -5.1)) and d.beats[0][1] == d._walkable(Vector2(-7.0, -5.1))
		and d.beats[1][0] == d._walkable(Vector2(-14.0, 9.0)) and d.beats[1][1] == d._walkable(Vector2(-2.0, 9.0)), "the patrols' beats are as before")
	t.check(d.stocks != null and d.stocks.center().distance_to(Vector2(-6.25, -7.4)) < 0.4 and d.charge_start == d.stocks.center() + Vector2(0.0, 1.0)
		and d.stocks_far == d.stocks.center() - Vector2(0.0, 0.25), "the stocks stand near (-6.25, -7.4); she stands a unit south of them (%s)" % [d.stocks.center() if d.stocks != null else null])
	t.check(d.exit_label == "POSTERN" and d.tour()[1][1] == "The postern, down to the dock. Its guard changes soon after she draws near.",
		"the postern's label and tour line are as before")
	print("ALDERMERE prisoner stocks %s gate %s exit %s return %s" % [d.stocks.center(), d.gate_at, d.exit_at, d.return_to])
	Kit.done(s)


## The Capital's director after setup reads back every override; her road and the stocks' approach are in Aldermere's band.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var dov: Dictionary = ov.director
	var d := Cap.starts(t, ID) as PrisonerDirector
	t.check(d != null and d.stocks_at == dov.stocks_at and d.lane_foot == dov.lane_foot and d.gate_words == dov.gate_words and d.exit_name == dov.exit_name
		and d.road == dov.road and d.beat_spots == dov.beat_spots, "the director reads back the Capital's stocks_at, lane_foot, gate_words, exit_name, road and beat_spots")
	if d == null:
		return
	var citadel: Vector2 = City.current().place(&"citadel_gate")
	t.check(d.return_to.distance_to(citadel) < 0.6 and d.citadel_door.distance_to(citadel) < 0.6, "the return spot and the door are the Keep's gate place (%s, %s)" % [d.return_to, d.citadel_door])
	t.check(d.gate_at.distance_to(dov.gate_at) < 1.0 and d.exit_at.distance_to(dov.exit_at) < 1.0 and d.guardhouse.distance_to(dov.guardhouse) < 1.0,
		"the gate, exit and guardhouse hold after setup (%s %s %s)" % [d.gate_at, d.exit_at, d.guardhouse])
	t.check(d.watch_posts.size() == 2 and d.watch_posts[0] == dov.watch_posts[0] and d.watch_posts[1] == dov.watch_posts[1], "the watch's posts are the Capital's, not appended to Aldermere's")
	t.check(d.stocks != null and d.stocks.center().distance_to(dov.stocks_at) < 0.8, "the stocks stand by stocks_at (%s)" % [d.stocks.center() if d.stocks != null else null])
	t.check(d.exit_label == "HARBOUR GATE" and d.beats.size() == 2, "the exit's label is the Capital's and both patrols have a beat")
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(8.0, -15.0) and def.intro_from == Vector2(8.0, -9.0), "camera_at and intro_from are overridden together (C9)")
	t.check(Walls.outside(d.exit_at), "the Capital's exit %s is outside the walls" % d.exit_at)
	Cap.spread(t, d.watch_posts)
	var near := INF
	for b: Array in dov.beat_spots:
		for p: Vector2 in b:
			near = minf(near, p.distance_to(citadel))
	t.check(near >= 6.0, "every beat point is 6 or more from the Keep's gate (%.1f)" % near)
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## Her road, and the Keep's gate to the stocks: Capital against Aldermere on the real grids (band 0.75-1.35); printed.
static func _walk_parity(t, d: PrisonerDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.prisoner())
	var ad: PrisonerDirector = a.d
	var cw := 0.0
	var aw := 0.0
	for k in range(d.road.size() - 1):
		cw += Cap.walk(cap.grid, d.road[k], d.road[k + 1])
	for k in range(ad.road.size() - 1):
		aw += Cap.walk(ald.grid, ad.road[k], ad.road[k + 1])
	Cap.parity(t, "her road", cw, aw)
	Cap.parity(t, "the Keep's gate to the stocks", Cap.walk(cap.grid, d.citadel_door, d.charge_start), Cap.walk(ald.grid, ad.citadel_door, ad.charge_start))
	Kit.done(a)
	City.use(&"capital")


## The policies read the director's road and no Aldermere const or coordinate.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "func _prisoner_act(", "\nfunc ")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier3_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "static func act_prisoner(", "static func state_prisoner(")
	t.check(act.length() > 1800 and rb.length() > 1000, "the prisoner policy functions are found and sliced (%d, %d chars)" % [act.length(), rb.length()])
	var re := RegEx.create_from_string("\\b(ROAD|STOCKS_AT|LANE_FOOT|GATE_MOUTH|EXIT|POSTS|GUARDHOUSE|BEATS|CITADEL_GATE)\\b|TownLayout\\.")
	for body: String in [act, rb]:
		var m := re.search(body)
		t.check(m == null, "a prisoner policy reads no Prisoner const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
	t.check("d.road" in act and "d.road" in rb, "each prisoner policy reads d.road")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names the postern, the dock or a street of Aldermere: the tour, the brief, the goal, the hints, the steps, the tags.
static func _words_true(t, d: PrisonerDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "bound", "caught", "hounds", "gate", "clear"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	said.append(d.exit_label)
	var re := RegEx.create_from_string("\\b(postern|dock|long west street|north quarter|south street)\\b")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL prisoner line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names the postern, the dock or a street of Aldermere (%s)" % [said])
	t.check(d.tour().size() == 3 and "harbour gate" in String(d.tour()[1][1]).to_lower(), "the tour names the harbour gate (%s)" % [d.tour()])
	t.check(MissionHints.line(ID, "gate") != "" and said.size() >= 20, "the lines were gathered (%d)" % said.size())


## The stocks, the way out and the Keep's gate (or their edge arrows) are clear of the padded HUD stack at the camera's resting place and the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as PrisonerDirector
	var at: Array = [d.stocks.center(), d.exit_at, d.citadel_door]
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
