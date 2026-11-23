extends RefCounted
## Plan "The Capital at every tier", Task 12: the Heretic Hunt in the Capital (spec 6.2.5). The sweeps are the cathedral quarter, the noble
## quarter and the west market; the cellar stands in the old town's south-west corner; the captain comes out of the cathedral's door. The director's places
## are town vars; with no overrides (Aldermere) every one is what it was; the town's overrides (src/game/town/cities/capital_missions/
## heretic_hunt.gd) are valid and hold after setup; the captain's walk to the cellar is in Aldermere's band (real grid walks) and each sweep
## spot's is printed; the cellar's door is out of every soldier post's reach; the words the player reads name no quarter of Aldermere; the
## policies read the director.

const ID := "heretic_hunt"
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
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var spots := {"cellar_at": dov.cellar_at, "Temple door": dov.temple_door_at}
	for i in dov.sweep_spots.size():
		spots["sweep %d" % i] = dov.sweep_spots[i]
	Cap.spots_land(t, cap, spots, 1.0)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Hunt test leaves Aldermere active")


## A fresh director holds each town var at its const (Aldermere's); the arrays are copies.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := HereticHuntDirector.new()
	t.check(d.sweep_spots == HereticHuntDirector.SWEEP_SPOTS and d.sweep_words == HereticHuntDirector.SWEEP_WORDS
		and d.step_at == HereticHuntDirector.STEP_AT and d.cellar_at == HereticHuntDirector.CELLAR_AT
		and d.temple_door_at == HereticHuntDirector.TEMPLE_DOOR, "a fresh director's sweep_spots, sweep_words, step_at, cellar_at and temple_door_at are their consts")
	t.check(d.sweep_areas.is_empty() and not d.cellar_area.has_area(), "a fresh director has no sweep areas and no cellar area (the districts are read)")
	d.sweep_spots.append(Vector2.ZERO)
	d.sweep_words.append("x")
	d.step_at[0] = 1.0
	t.check(HereticHuntDirector.SWEEP_SPOTS.size() == 3 and HereticHuntDirector.SWEEP_WORDS.size() == 3 and HereticHuntDirector.STEP_AT[0] == 60.0,
		"the arrays are copies: the consts are untouched")
	t.check(Overrides.town_vars(d) == ["sweep_spots", "sweep_words", "sweep_areas", "cellar_at", "cellar_area", "temple_door_at", "step_at"],
		"the Hunt's town vars (%s)" % [Overrides.town_vars(d)])
	t.check(MissionBook.heretic_hunt().camera_at == HereticHuntDirector.CAMERA_AT and HereticHuntDirector.STEP_AT == [60.0, 115.0, 185.0, 240.0]
		and HereticHuntDirector.TEMPLE_DOOR == LostLambDirector.TEMPLE_DOOR, "Aldermere's camera and times are untouched")


## An Aldermere director after setup is what it was: Aldermere's words, districts, times and tour.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.heretic_hunt())
	var d: HereticHuntDirector = s.d
	var ok := d.steps.size() == 3
	for i in d.steps.size():
		ok = ok and d.steps[i].words == HereticHuntDirector.SWEEP_WORDS[i] and d.steps[i].district == TownLayout.DISTRICTS[HereticHuntDirector.SWEEP_DISTRICTS[i]] \
			and d.steps[i].at == float(HereticHuntDirector.STEP_AT[i])
	t.check(ok, "Aldermere's three sweeps keep their words, districts and times")
	t.check(d.head_at == 240.0 and d.head_door == HereticHuntDirector.TEMPLE_DOOR, "Aldermere's captain comes at 240 s by the Temple's door const")
	t.check(String(d.tour()[1][1]) == "The north quarter. The hunt raises its first standard here at %s." % UiTheme.clock(60.0), "Aldermere's tour line is as before")
	print("ALDERMERE hunt cellar_door %s" % [d.cellar_door])
	Kit.done(s)


## The Capital's director after setup reads back every override; the captain's walk is in Aldermere's band.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var d := Cap.starts(t, ID) as HereticHuntDirector
	t.check(d != null and d.sweep_spots == dov.sweep_spots and d.sweep_words == dov.sweep_words and d.sweep_areas == dov.sweep_areas
		and d.cellar_at == dov.cellar_at and d.cellar_area == dov.cellar_area and d.temple_door_at == dov.temple_door_at,
		"the director reads back the Capital's sweep spots, words, areas, cellar and Temple door")
	if d == null:
		return
	var ok := d.steps.size() == 3
	for i in d.steps.size():
		ok = ok and d.steps[i].words == dov.sweep_words[i] and d.steps[i].district == dov.sweep_areas[i] and d.steps[i].spot.distance_to(dov.sweep_spots[i]) < 1.0 \
			and d.steps[i].at == float(HereticHuntDirector.STEP_AT[i])
	t.check(ok, "the three sweeps are the Capital's: words, areas, spots, and Aldermere's times")
	t.check(d.head_door == dov.temple_door_at and d.head_at == 240.0, "the captain comes out of the Capital's Temple door at 240 s")
	t.check(d.cellar != null and dov.cellar_area.has_point(d.cellar.center()), "the cellar is a dwelling in the south-west corner (%s)" % [d.cellar.center() if d.cellar != null else null])
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(-18.0, -8.0) and def.intro_from == Vector2(-18.0, -2.0), "camera_at and intro_from are overridden together (C9)")
	_cellar_quiet(t, d)
	var points: Array = []
	for st in d.steps:
		points.append(st.spot)
	Cap.spread(t, points, 1.6)
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


## The cellar's door is farther than QUIET_R from every soldier post of the Capital.
static func _cellar_quiet(t, d: HereticHuntDirector) -> void:
	var crowd: Crowd = Cap._worlds.back().crowd
	var near := INF
	var n := 0
	for p in crowd.soldiers:
		if MissionDirector._alive(p) and p.post != Vector2.INF:
			n += 1
			near = minf(near, p.post.distance_to(d.cellar_door))
	t.check(n > 0 and near > HereticHuntDirector.QUIET_R, "the cellar's door is farther than QUIET_R from all %d soldier posts (%.1f)" % [n, near])


## The captain's walk, the Temple door to the cellar's door (band 0.75-1.35), and each sweep spot to the cellar (printed): the real grids.
static func _walk_parity(t, d: HereticHuntDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.heretic_hunt())
	var ad: HereticHuntDirector = a.d
	var cw := Cap.walk(cap.grid, d.head_door, d.cellar_door)
	var aw := Cap.walk(ald.grid, ad.head_door, ad.cellar_door)
	Cap.parity(t, "the captain's walk, Temple door to cellar", cw, aw)
	for i in d.steps.size():
		var c := Cap.walk(cap.grid, d.steps[i].spot, d.cellar_door)
		var al := Cap.walk(ald.grid, ad.steps[i].spot, ad.cellar_door)
		print("CAPITAL hunt sweep %d -> cellar %.1f (Aldermere %.1f, %.2fx)" % [i, c, al, c / maxf(al, 0.01)])
	Kit.done(a)
	City.use(&"capital")


## The policies read the director's steps, head and cellar: no Hunt const or TownLayout coordinate.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "\nfunc _hunt_act(", "\nfunc ")
	var run := _slice(bc, "\nfunc _hunt(", "\nfunc ")
	var far := _slice(bc, "\nfunc _hunt_far_side(", "\nfunc ")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier3_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "\nstatic func act_hunt(", "\nstatic func state_hunt(")
	t.check(act.length() > 1800 and run.length() > 300 and far.length() > 300 and rb.length() > 1200,
		"the hunt policy functions are found and sliced (%d, %d, %d, %d chars)" % [act.length(), run.length(), far.length(), rb.length()])
	var re := RegEx.create_from_string("\\b(SWEEP_SPOTS|SWEEP_WORDS|SWEEP_DISTRICTS|CELLAR_AT|CELLAR_DISTRICT|TEMPLE_DOOR|STEP_AT|CAMERA_AT)\\b|TownLayout\\.|HereticHuntDirector\\.")
	t.check(re.search("x HereticHuntDirector.STEP_AT y") != null and re.search("TownLayout.DISTRICTS") != null and re.search("d.cellar_door") == null
		and re.search("d: HereticHuntDirector, crowd") == null, "the scan regex bites on a sample and passes a typed parameter")
	for body: String in [act, run, far, rb]:
		var m := re.search(body)
		t.check(m == null, "a hunt policy reads no Hunt const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
	t.check("d.steps" in act and "d.steps" in rb and "d.standard(" in act, "the hunt policies read the director's steps and standards")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a quarter of Aldermere: the tour, the brief, the goal, the hints, the steps, the strip, the banners, the tags.
static func _words_true(t, d: HereticHuntDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "guarded", "open", "waiting", "coming", "captain", "searching"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	for i in d.steps.size():
		said.append(d._step_label(i))
	said.append(d._head_label())
	said.append(d._opening_banner())
	said.append(d._found_banner())
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	var re := RegEx.create_from_string("\\b(north quarter|west quarter|south quarter|south-west)\\b")
	t.check(re.search("the north quarter") != null and re.search("the west market") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL hunt line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names a quarter of Aldermere (%s)" % [said])
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[1][1]).begins_with("The cathedral quarter."), "the tour names the cathedral quarter (%s)" % [tour])
	t.check(MissionHints.line(ID, "searching") != "" and said.size() >= 20, "the lines were gathered (%d)" % said.size())


## The cellar, the sweeps' spots and the Temple's door (or their edge arrows) are clear of the padded HUD stack at the camera's resting place and the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as HereticHuntDirector
	var at: Array = [d.cellar_door, d._walkable(d.temple_door_at)]
	for st in d.steps:
		at.append(st.spot)
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
