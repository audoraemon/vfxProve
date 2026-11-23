extends RefCounted
## Plan "The Capital at every tier", Task 14: the Procession in the Capital (spec 6.3.1). The Procession is a board act (TierBook._from_act(), like the Festival),
## so the kit's get_mission() checks are made here on Mission.def_for(). The Prince walks the Capital's own five points (route_spots: the court's south, the
## cathedral door, inside the harbour gate, the quay's waiting ground, the boarding point) instead of Aldermere's landmark points, which would lead him
## through the Great Market. With no overrides (Aldermere) the route is the landmarks' and every number is what it was; the overrides
## (src/game/town/cities/capital_missions/procession.gd) are valid and hold after setup; the real grid walk of the route and of each leg is in Aldermere's band; the
## route crosses no bridge, and the party at the harbour gate's mouth is not the gate's queue (that reads fleeing evacuees only); the Capital draws the ship at its dock;
## the words the player reads are true in both towns; the policies read the director.

const ID := "procession"
const TIER := 4
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	City.use(&"aldermere")
	_overrides_valid(t)
	_hostable(t)
	_seeded(t)
	_policy_reads_vars(t)
	_aldermere_pin(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var spots := {}
	for i in dov.route_spots.size():
		spots["route spot %d" % i] = dov.route_spots[i]
	Cap.spots_land(t, cap, spots, 1.0)
	_ship(t, cap)
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Procession test leaves Aldermere active")


## The overrides: a def and a director section; they apply cleanly to a fresh board Procession and its director, each value with the type of the var it sets.
static func _overrides_valid(t) -> void:
	var ov := City.by_id(&"capital").mission_overrides(ID)
	t.check(ov.has("def") and ov.has("director"), "the Capital has a def and a director section for the Procession (%s)" % [ov.keys()])
	var def := Mission.def_for(ID, true, null)
	t.check(def != null and def.id == ID and def.director == ProcessionDirector, "the board's Procession is the act's def (%s)" % [def.id if def != null else null])
	var d := def.make_director()
	var bad_def := Overrides.apply(def, (ov.get("def", {}) as Dictionary).duplicate(true))
	var bad_dir := Overrides.apply(d, (ov.get("director", {}) as Dictionary).duplicate(true), Overrides.town_vars(d))
	t.check(bad_def.is_empty() and bad_dir.is_empty(), "the overrides apply cleanly to a fresh board Procession and director (refused %s %s)" % [bad_def, bad_dir])
	var okay := true
	var fresh := Mission.def_for(ID, true, null)
	for key: Variant in ov.get("def", {}):
		okay = okay and typeof(fresh.get(String(key))) == typeof(ov.def[key])
	var made := fresh.make_director()
	for key: Variant in ov.get("director", {}):
		okay = okay and typeof(made.get(String(key))) == typeof(ov.director[key])
	t.check(okay, "every overridden value has the type of the var it sets")


## The Capital hosts the Procession: its list has procession@capital, which is the board's Procession in the Capital.
static func _hostable(t) -> void:
	var capital := City.by_id(&"capital")
	t.check(MissionBook.hostable(ID, capital), "the Capital hosts the Procession")
	t.check(MissionBook.town_missions(&"capital").has("%s@capital" % ID), "the Capital's list has procession@capital")
	var m := Mission.def_for("%s@capital" % ID, true, null)
	t.check(m != null and m.id == ID and m.city == &"capital", "procession@capital is the board's Procession, in the Capital")
	t.check(Mission.hosting_error(m, &"capital") == "", "the Capital's hosting check passes for the Procession")
	t.check(Mission.def_for(ID, true, null).city != &"capital", "the board's Procession is Aldermere's until put in the Capital")


## A fresh director has no route spots (the landmarks are read) and its numbers are untouched; Aldermere's def is unchanged.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := ProcessionDirector.new()
	t.check(d.route_spots.is_empty(), "a fresh director has no route spots (the landmark points are read)")
	t.check(Overrides.town_vars(d) == ["route_spots"], "the Procession's town vars (%s)" % [Overrides.town_vars(d)])
	d.route_spots.append(Vector2.ONE)
	t.check(ProcessionDirector.new().route_spots.is_empty(), "route_spots is a var of its own, not a shared const")
	t.check(ProcessionDirector.STEPS_LEG == 1 and ProcessionDirector.DOCK_LEG == 3 and ProcessionDirector.SHIP_AT == 120.0 and ProcessionDirector.TIDE_AT == 150.0
		and ProcessionDirector.BLESSING_AT == 60.0 and ProcessionDirector.EMERGE_AT == 36.0, "the legs and windows are untouched")
	var def := Mission.def_for(ID, true, null)
	var home := City.current()
	t.check(def.camera_at == home.citadel_origin().lerp(home.landmark(&"dock").get_center(), 0.3) and def.intro_from == home.citadel_origin(),
		"Aldermere's camera and intro are the Citadel's and a third of the way to the dock")


## An Aldermere director after setup walks the landmark route exactly as before.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(Mission.def_for(ID, true, null))
	var d: ProcessionDirector = s.d
	var want := PackedVector2Array()
	for at: Vector2 in [Vector2(Places.rect(&"citadel_court").get_center().x, Places.rect(&"citadel_court").end.y + 0.6),
			Vector2(Places.rect(&"temple").get_center().x, Places.rect(&"temple").end.y + 0.5),
			Vector2(Places.rect(&"market_square").get_center().x, Places.rect(&"market_square").end.y - 0.5),
			Places.at(&"dock_wait"), Vector2(Places.rect(&"dock").get_center().x, Places.rect(&"dock").position.y - 0.4)]:
		want.append(d._ground(at))
	t.check(d.route_spots.is_empty() and d.route.size() == 5 and d.route == want, "Aldermere's route is its landmark points, each on walkable ground (%s)" % [d.route])
	print("ALDERMERE procession route %s" % [d.route])
	t.check(TownLayout.SHIP_AT == City.current().ship_at() and TownLayout.SHIP_AT == Vector2(-5.6, 21.35), "Aldermere's ship lies where it did")
	Kit.done(s)


## The Capital's ship lies at its harbour dock, drawn as Aldermere's: a decor piece of the existing ship sprite, beyond the pier's end, on the water.
static func _ship(t, cap: Dictionary) -> void:
	var capital := City.by_id(&"capital")
	var at := capital.ship_at()
	var dock := capital.landmark(&"dock")
	t.check(at.is_finite() and at == Vector2(dock.get_center().x, dock.end.y + 0.75) and at.is_equal_approx(Vector2(31.0, -0.65)), "the Capital's ship_at() is the pier's end plus 0.75, as Aldermere's (%s)" % [at])
	t.check(CapitalCity.HARBOUR.has_point(at), "the ship lies in the harbour water %s" % [at])
	var found := false
	for d in (cap.env as EnvironmentField).decor():
		if d.kind == Decor.Kind.SHIP and d.at == at:
			found = true
	t.check(found, "the town's decor holds the ship at its dock")
	var ald_dock := City.by_id(&"aldermere").landmark(&"dock")
	t.check(City.by_id(&"aldermere").ship_at() == Vector2(ald_dock.get_center().x, ald_dock.end.y + 0.75), "the formula is Aldermere's own")


## The Capital's director after setup reads back every override; the route is in Aldermere's band; no bridge; no queue.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var d := Cap.starts(t, ID, TIER) as ProcessionDirector
	t.check(d != null and d.route_spots == dov.route_spots and d.route_spots.size() == 5, "the director reads back the Capital's five route spots")
	if d == null:
		return
	var def := Mission.def_for("%s@capital" % ID, true, null)
	t.check(def.camera_at == Vector2(-1.0, -12.0) and def.intro_from == Vector2(0.0, -25.5), "camera_at and intro_from are overridden together (C9)")
	t.check(d.emerge_after > 0.0 and d.emerge_after == ProcessionDirector.EMERGE_AT / maxf(d.stretch, 0.001), "the board's carriage wait survives the town's overrides (%.1f)" % d.emerge_after)
	t.check(d.route.size() == 5, "the route has five points")
	for i in mini(d.route.size(), dov.route_spots.size()):
		t.check(d.route[i].distance_to(dov.route_spots[i]) <= 1.0, "route point %d %s is its spot %s on walkable ground" % [i, d.route[i], dov.route_spots[i]])
	# The boarding point stands 1.3 from the waiting ground (Aldermere's 1.1): the spread rule is the pair's own, no tighter than Aldermere's.
	var ald_def := Mission.def_for(ID, true, null)
	City.use(&"aldermere")
	var a := Kit.world(ald_def)
	var ad: ProcessionDirector = a.d
	var ar := ad.route
	City.use(&"capital")
	t.check(_tightest(d.route) >= _tightest(ar) - 0.01, "no two route points stand closer than Aldermere's closest (%.2f vs %.2f)" % [_tightest(d.route), _tightest(ar)])
	_walk_parity(t, d, ar, cap, ald)
	_no_bridge(t, d, cap)
	Kit.done(a)
	City.use(&"capital")
	_no_queue(t, d)
	_words_true(t, d)


## The Prince's whole route (band 0.75-1.35) and each leg (printed; 0.6-1.8): the real grids.
static func _walk_parity(t, d: ProcessionDirector, ald_route: PackedVector2Array, cap: Dictionary, ald: Dictionary) -> void:
	var cw := 0.0
	var aw := 0.0
	for i in range(1, d.route.size()):
		var c := Cap.walk(cap.grid, d.route[i - 1], d.route[i])
		var al := Cap.walk(ald.grid, ald_route[i - 1], ald_route[i])
		cw += c
		aw += al
		print("CAPITAL procession leg %d: capital %.1f, aldermere %.1f (%.2fx)" % [i, c, al, c / maxf(al, 0.01)])
		t.check(c / maxf(al, 0.01) >= 0.6 and c / maxf(al, 0.01) <= 1.8, "leg %d walks %.1f vs Aldermere's %.1f (%.2fx, in 0.6-1.8)" % [i, c, al, c / maxf(al, 0.01)])
	Cap.parity(t, "the Prince's whole route", cw, aw)


## No stretch of the route's real path crosses a bridge's footprint (the Prince walks the old town's streets to the harbour gate and its quay).
static func _no_bridge(t, d: ProcessionDirector, cap: Dictionary) -> void:
	var rects: Array[Rect2] = []
	for r: Rect2 in CapitalCity.BRIDGES:
		rects.append(r)
	var crossed := 0
	for i in range(1, d.route.size()):
		var at: Vector2 = Cap.snap(cap.grid, d.route[i - 1])
		for step: Vector2 in (cap.grid as WalkGrid).path(at, Cap.snap(cap.grid, d.route[i])):
			var n := maxi(1, ceili(at.distance_to(step) / 0.25))
			for k in range(n + 1):
				var p := at.lerp(step, float(k) / float(n))
				for r in rects:
					if r.has_point(p):
						crossed += 1
			at = step
	t.check(crossed == 0 and rects.size() == 3, "the route's path crosses no bridge (%d samples inside %d bridge rects)" % [crossed, rects.size()])


## The party at the harbour gate's mouth (route point 2) is not the gate's queue: the crowd's queue (Crowd._gates()) takes fleeing evacuees only, and the
## Prince, his attendants and his escort are calm or posted. Set down at the mouth and the crowd stepped, none of them holds a queue spot.
static func _no_queue(t, d: ProcessionDirector) -> void:
	var crowd: Crowd = Cap._worlds.back().crowd
	var mouth := d.route[2]
	var near := INF
	for g in crowd._town.gates:
		if is_instance_valid(g):
			near = minf(near, (g as Structure).center().distance_to(mouth))
	t.check(near <= 4.0, "route point 2 %s is at the harbour gate's mouth (nearest gate %.1f)" % [mouth, near])
	var party: Array[Person] = [d.prince]
	party.append_array(d.attendants)
	d._place(d.prince, mouth)
	for i in d.attendants.size():
		d._place(d.attendants[i], d._ring(mouth, ProcessionDirector.ATTEND_R, i, d.attendants.size(), 0.0))
	for i in d.escorts.size():
		d.escorts[i].ground_pos = d._escort_spot(i)
		party.append(d.escorts[i])
	var calm := true
	for p in party:
		calm = calm and p.mind != Person.Mind.FLEE
	for i in 30:
		crowd._gates()
		crowd.advance(0.1)
		for p in party:
			d._place(p, p.ground_pos)  # held where set down
	var queued := 0
	for p in party:
		if p.queue_spot != Vector2.INF or p.passing_gate != null:
			queued += 1
	t.check(calm and queued == 0 and party.size() >= 5, "the Prince's party of %d at the gate's mouth is no queued evacuee (calm %s, queued %d)" % [party.size(), calm, queued])


## The policies read the director: no TownLayout coordinate, no landmark lookup, no map const.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var a := _slice(bc, "\nfunc _play_procession(", "\nfunc ")
	var b4 := FileAccess.get_file_as_string("res://tools/dev/routes/tier4_b.gd").replace("\r\n", "\n")
	var rb := _slice(b4, "\nstatic func act_procession(", "\nstatic func state_procession(") + _slice(b4, "\nstatic func state_procession(", "\nstatic func ")
	var b5 := FileAccess.get_file_as_string("res://tools/dev/routes/tier5_b.gd").replace("\r\n", "\n")
	var nb := _slice(b5, "\nstatic func _night_procession(", "\nstatic func ")
	t.check(a.length() > 2000 and rb.length() > 800 and nb.length() > 600, "the procession policy functions are found and sliced (%d, %d, %d chars)" % [a.length(), rb.length(), nb.length()])
	var re := RegEx.create_from_string("TownLayout\\.|Places\\.|\\b(CAMERA_AT|SHIP_AT|DOCK|DOCK_WAIT|TEMPLE|MARKET|CITADEL)\\b|ProcessionDirector\\.(?!DOCK_LEG\\b)")
	t.check(re.search("x TownLayout.DOCK y") != null and re.search("Places.at(&\"dock\")") != null and re.search("ProcessionDirector.SHIP_AT") != null
		and re.search("d.leg >= ProcessionDirector.DOCK_LEG") == null and re.search("d.route[2]") == null and re.search("ctx.d as ProcessionDirector") == null,
		"the scan regex bites on samples and passes the allowed reads")
	for body: String in [a, rb, nb]:
		var m := re.search(body)
		t.check(m == null, "a procession policy reads no Aldermere const, landmark or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
	t.check("d.leg" in a and "d.prince" in rb and "d.prince" in nb, "the policies read the director's prince and leg")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a place that is one town's only: the tour, the brief, the goal and lose lines, the hints, the tags.
static func _words_true(t, d: ProcessionDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var tour_lines := said.size()
	var def := Mission.def_for("%s@capital" % ID, true, null)
	said.append_array(def.brief)
	said.append_array([def.goal, def.goal_label, def.lose])
	for phase in ["", "blessing", "dock"]:
		said.append(MissionHints.line(ID, phase))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	t.check(tour_lines == 3 and said.size() >= tour_lines + 2 + 3 + 3 and not String(said[said.size() - 1]).is_empty(), "the Procession's lines are found (%d)" % said.size())
	var re := RegEx.create_from_string("\\b(temple|north-east|workshops|east tavern|west quarter|bell tower|great market|market)\\b")
	t.check(re.search("the temple steps") != null and re.search("the cathedral steps") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL procession line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names a place of Aldermere or one the Capital lacks (%s)" % [said])
	var all := " ".join(said).to_lower()
	t.check("cathedral" in all and "dock" in all and Places.has(City.by_id(&"capital"), &"dock") and Places.has(City.by_id(&"capital"), &"temple"),
		"the lines name the cathedral and the dock, which the Capital has")
	t.check(d.tour()[1][0] == d.route[ProcessionDirector.STEPS_LEG] and d.tour()[2][0] == d.route[4], "the tour's stops are the steps and the dock, where the route has them")


## The Prince's five points (or their edge arrows) and the ship are clear of the padded HUD stack at the camera's resting place and at the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := Mission.def_for("%s@capital" % ID, true, null)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID, TIER) as ProcessionDirector
	var at: Array = Array(d.route)
	at.append(City.by_id(&"capital").ship_at())
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")


## The smallest distance between two of the route's points.
static func _tightest(route: PackedVector2Array) -> float:
	var tight := INF
	for i in route.size():
		for j in range(i + 1, route.size()):
			tight = minf(tight, route[i].distance_to(route[j]))
	return tight
