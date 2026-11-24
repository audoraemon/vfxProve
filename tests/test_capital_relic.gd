extends RefCounted
## Plan "The Capital at every tier", Task 18: the Relic Run in the Capital (spec 6.3.5). The cart's route, the words of its two halts, the drop-off and Pip's spot
## are town vars (`cart_route`, `check_words`, `drop_spot`, `pip_spot`: the director's `route` stays the route on walkable ground that setup builds from `cart_route`),
## seeded from the consts (a fresh director in Aldermere reads Aldermere's own). The town's overrides (src/game/town/cities/capital_missions/relic_run.gd) are valid and
## hold after setup; the route ends at the Citadel's gate; the halts, the drop-off and Pip's spot land on walkable ground; the wardens stand WARDEN_GAP apart; the
## cart's route and Pip's walk to the first halt are in Aldermere's band (real grid walks); the camera keeps the key points clear of the padded HUD stack; the words
## are true in the Capital; the policies read the director and Places. The Vigil Flame's `route_spots` and `mira_shrine`, which this run inherits, are not read here
## (its `_begin` builds its own `shrine` from the drop house), so the Capital's overrides set neither.

const ID := "relic_run"
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
	t.check(City.current() is AldermereCity, "the Capital Relic test leaves Aldermere active")


## A fresh director holds each town var at its const (copies, never shared); Aldermere's numbers and camera are untouched; the Vigil Flame's two inherited town vars
## stay at theirs.
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := RelicRunDirector.new()
	t.check(d.cart_route == RelicRunDirector.ROUTE and d.check_words == RelicRunDirector.CHECK_WORDS and d.drop_spot == RelicRunDirector.DROP_SPOT
		and d.pip_spot == RelicRunDirector.PIP_SPOT, "a fresh director's cart_route, check_words, drop_spot and pip_spot are their consts")
	d.cart_route.append(Vector2.ZERO)
	d.check_words.append("x")
	t.check(RelicRunDirector.ROUTE.size() == 6 and RelicRunDirector.CHECK_WORDS.size() == 2, "the town vars are copies: the consts are untouched")
	var names := Overrides.town_vars(RelicRunDirector.new())
	for n in ["cart_route", "check_words", "drop_spot", "pip_spot", "route_spots", "mira_shrine"]:
		t.check(names.has(n), "the Relic Run's town vars hold %s (%s)" % [n, names])
	t.check(RelicRunDirector.ROUTE == [Vector2(9.5, -5.1), Vector2(9.5, 9.0), Vector2(-6.0, 9.0), Vector2(-6.0, -5.1), Vector2(-10.5, -5.1), Vector2(-10.5, -7.6)]
		and RelicRunDirector.CHECK_WORDS == ["the east watch-house", "the west watch-house"] and RelicRunDirector.DROP_SPOT == Vector2(12.5, -12.0)
		and RelicRunDirector.PIP_SPOT == Vector2(6.0, 2.5) and RelicRunDirector.HALT_LEGS == [0, 2] and RelicRunDirector.WARDEN_GAP == 2.6, "the consts are untouched")
	var r := RelicRunDirector.new()
	t.check(r.route_spots == BrokenLanternsDirector.SHRINE_SPOTS and r.mira_shrine == VigilFlameDirector.MIRA_SHRINE, "the inherited Vigil Flame town vars are at their consts")
	t.check(MissionBook.relic_run().camera_at == RelicRunDirector.CART_CAMERA and RelicRunDirector.CART_CAMERA == Vector2(4.0, -3.0)
		and MissionBook.relic_run().intro_from == Vector2(4.0, 3.0), "Aldermere's camera is still CART_CAMERA")
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	t.check(not ov.director.has("mira_shrine") and not ov.director.has("route_spots"), "the Capital's overrides leave the inherited, unread Vigil Flame vars alone")


## An Aldermere director after setup is as it was: its route, drop house, Pip and its words.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.relic_run())
	var d: RelicRunDirector = s.d
	var ok := d.route.size() == RelicRunDirector.ROUTE.size()
	for i in mini(d.route.size(), RelicRunDirector.ROUTE.size()):
		ok = ok and d.route[i] == d._walkable(RelicRunDirector.ROUTE[i])
	t.check(ok, "Aldermere's route is its ROUTE on walkable ground, point for point")
	t.check(d.checkpoints[0] == d.route[0] and d.checkpoints[1] == d.route[2], "Aldermere's halts are route points 0 and 2")
	t.check(d.drop_house != null and d.drop_house == d._house_near(RelicRunDirector.DROP_SPOT), "Aldermere's drop house is the dwelling nearest DROP_SPOT")
	t.check(d.wren.ground_pos.distance_to(d._walkable(RelicRunDirector.PIP_SPOT)) < 1.5, "Aldermere's Pip stands by PIP_SPOT")
	t.check(String(d.check_words[0]) == "the east watch-house" and String(d.check_words[1]) == "the west watch-house", "Aldermere's halts are the east and west watch-houses")
	Kit.done(s)


## The Capital's director after setup reads back every override: its route, words, drop-off and Pip, the wardens and the walks.
static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var dov: Dictionary = City.by_id(&"capital").mission_overrides(ID).director
	var d := Cap.starts(t, ID) as RelicRunDirector
	t.check(d != null and d.cart_route == dov.cart_route and d.check_words == dov.check_words and d.drop_spot == dov.drop_spot and d.pip_spot == dov.pip_spot,
		"the director reads back the Capital's cart route, words, drop-off and Pip's spot after setup")
	if d == null:
		return
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == Vector2(5.0, -3.5) and def.intro_from == Vector2(5.0, 2.5), "camera_at and intro_from are overridden together (C9)")
	t.check(d.cart_route == [Vector2(14.0, 1.5), Vector2(14.0, -9.0), Vector2(-2.0, -9.0), Vector2(-2.0, -13.0), Vector2(4.0, -13.0), Vector2(0.0, -22.6)]
		and d.drop_spot == Vector2(16.0, -14.0) and d.pip_spot == Vector2(8.0, -6.0), "the Capital's route, drop-off and Pip's spot are as pinned (%s)" % [d.cart_route])
	t.check(d.route.size() == 6 and d.checkpoints.size() == 2, "six route points and two halts (%d, %d)" % [d.route.size(), d.checkpoints.size()])
	var gate := Places.point(&"citadel_gate")
	t.check(gate != Vector2.INF and d.route[d.route.size() - 1].distance_to(gate) <= 0.6, "the route's last point is the Capital's Citadel gate %s (%s)" % [gate, d.route[d.route.size() - 1]])
	t.check(RelicRunDirector.HALT_LEGS == [0, 2] and d.checkpoints[0] == d.route[0] and d.checkpoints[1] == d.route[2], "the halts are route points 0 and 2")
	var spots := {"drop_spot": d.drop_spot, "pip_spot": d.pip_spot, "temple door": d.temple_door}
	for i in d.cart_route.size():
		spots["route %d" % i] = d.cart_route[i]
	Cap.spots_land(t, cap, spots)
	for i in d.route.size():
		t.check(cap.grid.walkable(d.route[i]), "route point %d %s is walkable ground" % [i, d.route[i]])
	t.check(d.drop_house != null and d.drop_house.center().distance_to(d.drop_spot) < 5.0, "the believers' house is a dwelling by the drop-off (%s)" % [d.drop_house.center() if d.drop_house != null else "none"])
	t.check(d.shrine != Vector2.INF and cap.grid.walkable(d.shrine) and d.shrine.distance_to(d.drop_house.center()) < 4.0, "its door %s is walkable ground" % [d.shrine])
	t.check(_alive_near(d.wren, d.pip_spot, 1.5), "Pip is a lay citizen standing by Pip's spot (%s)" % [d.wren.ground_pos if d.wren != null else "none"])
	var posts := {}
	for w: RelicRunDirector.Warden in d.wardens:
		posts["warden %d.%d" % [w.checkpoint, w.slot]] = w.post
	t.check(posts.size() == 4, "two wardens at each halt (%d)" % posts.size())
	Cap.spots_land(t, cap, posts)
	Cap.spread(t, posts.values())
	for k in 2:
		var gap := (d.wardens[2 * k] as RelicRunDirector.Warden).post.distance_to((d.wardens[2 * k + 1] as RelicRunDirector.Warden).post)
		t.check(absf(gap - RelicRunDirector.WARDEN_GAP) <= 0.5, "halt %d's wardens stand WARDEN_GAP (%.1f) apart (%.2f)" % [k, RelicRunDirector.WARDEN_GAP, gap])
	print("CAPITAL relic route %s halts %s door %s pip %s house %s shrine %s" % [d.route, d.checkpoints, d.temple_door, d.wren.ground_pos, d.drop_house.center(), d.shrine])
	_opening(d, "CAPITAL")
	_walk_parity(t, d, cap, ald)
	City.use(&"capital")
	_words_true(t, d)


static func _alive_near(p: Person, at: Vector2, within: float) -> bool:
	return p != null and p.is_alive() and p.ground_pos.distance_to(at) <= within and not p.profile.role in Wish.NOT_LAY


## The cart's route (route point 0 to 5: five legs; the walk from the Temple's door to the first halt apart) and Pip's walk to the first halt, Capital against Aldermere on
## the real grids (band 0.75-1.35); each leg printed.
static func _walk_parity(t, d: RelicRunDirector, cap: Dictionary, ald: Dictionary) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.relic_run())
	var ad: RelicRunDirector = a.d
	_opening(ad, "ALDERMERE")
	var rc := _legs(cap.grid, d)
	var ra := _legs(ald.grid, ad)
	for i in rc.size():
		print("CAPITAL relic leg %d: capital %.1f, aldermere %.1f (%.2fx)" % [i, rc[i], ra[i], rc[i] / maxf(ra[i], 0.01)])
	Cap.parity(t, "the cart's route (five legs)", _sum(rc), _sum(ra))
	Cap.parity(t, "Pip's spot to the first halt", Cap.walk(cap.grid, d.wren.ground_pos, d.checkpoints[0]), Cap.walk(ald.grid, ad.wren.ground_pos, ad.checkpoints[0]))
	var door_c := Cap.walk(cap.grid, d.temple_door, d.checkpoints[0])
	var door_a := Cap.walk(ald.grid, ad.temple_door, ad.checkpoints[0])
	Cap.parity(t, "the cart's walk between the halts", rc[0] + rc[1], ra[0] + ra[1])
	print("CAPITAL relic Temple's door to the first halt: capital %.1f, aldermere %.1f (%.2fx)" % [door_c, door_a, door_c / door_a])
	# Measured (the gates, Task 18 report): the spec's first halt (14.0, 1.5) is 27.6 of walking from the Temple's door (Aldermere's 9.3), so the cart reaches it about 35 s
	# later and the policy idles 63-67 s before it (Aldermere 35-49). The brief's only knob is leg 2's end, which does not move this; it is pinned as measured, out of the band.
	t.check(door_c / door_a >= 2.5 and door_c / door_a <= 3.5, "the cart's walk from the Temple's door to the first halt is 2.5-3.5x Aldermere's, longer as measured (%.1f vs %.1f)" % [door_c, door_a])
	print("CAPITAL relic Pip's carry (the second halt to the drop-off's door): capital %.1f, aldermere %.1f" % [
		Cap.walk(cap.grid, d.checkpoints[1], d.shrine), Cap.walk(ald.grid, ad.checkpoints[1], ad.shrine)])
	Kit.done(a)
	City.use(&"capital")


static func _legs(grid: WalkGrid, d: RelicRunDirector) -> Array[float]:
	var out: Array[float] = []
	for i in range(1, d.route.size()):
		out.append(Cap.walk(grid, d.route[i - 1], d.route[i]))
	return out


static func _sum(legs: Array[float]) -> float:
	var s := 0.0
	for x in legs:
		s += x
	return s


## The policies read the director and the Places: no Relic Run data const (the ones the brief keeps are the halts' legs, the cart's reach and the wardens' gap) or
## TownLayout coordinate, no hard-coded offset from a director point in the A policy.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "func _relic_act(", "\nfunc ")
	var carry := _slice(bc, "func _relic_carry(", "\nfunc ")
	var quiet := _slice(bc, "func _relic_quiet(", "\nfunc ")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier4_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "static func act_relic(", "\nstatic func ")
	t.check(act.length() > 3000 and carry.length() > 100 and quiet.length() > 500 and rb.length() > 3000,
		"the relic policy functions are found and sliced (%d, %d, %d, %d chars)" % [act.length(), carry.length(), quiet.length(), rb.length()])
	var re := RegEx.create_from_string("\\bRelicRunDirector\\.(ROUTE|CHECK_WORDS|DROP_SPOT|PIP_SPOT|CART_CAMERA)\\b|\\bTownLayout\\b")
	var plus := RegEx.create_from_string("\\b(d\\.(drop_spot|pip_spot|shrine|temple_door)|d\\.(route|checkpoints)\\[[^\\]]*\\])\\s*[+-]")
	t.check(re.search("x RelicRunDirector.DROP_SPOT") != null and re.search("TownLayout.BELL_TOWER") != null and re.search("RelicRunDirector.CART_REACH") == null
		and re.search("RelicRunDirector.HALT_LEGS.size()") == null and re.search("d.drop_spot") == null and plus.search("d.checkpoints[k] + Vector2(1.0, 0.0)") != null
		and plus.search("d.shrine - Vector2.ONE") != null and plus.search("p.ground_pos - d.temple_door") == null and plus.search("d.checkpoints[k],") == null,
		"the policy regexes bite on a sample and pass the director's vars")
	for body: String in [act, carry, quiet, rb]:
		var m := re.search(body)
		t.check(m == null, "a relic policy reads no Relic Run data const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
	for body: String in [act, carry, quiet]:
		var m := plus.search(body)
		t.check(m == null, "the A policy has no hard-coded offset from a director point (%s)" % [m.get_string() if m != null else ""])
	t.check("Places.at(&\"bell_tower\")" in act, "the A policy finds the bell tower by place")
	t.check("d.checkpoints" in act and "d.checkpoints" in rb and "d.cart_at()" in act, "the policies read the director's checkpoints and cart")
	t.check("RelicRunDirector.HALT_LEGS" in act and "RelicRunDirector.CART_REACH" in act and "RelicRunDirector.WARDEN_GAP" in act, "the A policy keeps the three consts the brief keeps")
	# The Vigil Flame's two town vars are not read by this run: its _begin (not the base's) builds the shrine from the drop house.
	var src := FileAccess.get_file_as_string("res://src/game/mission/relic_run_director.gd").replace("\r\n", "\n")
	var begin := _slice(src, "func _begin()", "\nfunc ")
	t.check(begin.length() > 500 and "drop_spot" in begin and "cart_route" in begin and not "mira_shrine" in begin and not "route_spots" in begin and not "super(" in begin,
		"_begin reads cart_route and drop_spot, never mira_shrine or route_spots, and does not call the base's")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## No line the player reads names a place only Aldermere has, and the Capital's halts are where their words say: the tour, the brief, the goal, the hints, the steps, the tags.
static func _words_true(t, d: RelicRunDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "moving", "watched", "aboard", "carry", "last_halt", "citadel", "report", "seen", "bell"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	said.append_array(PackedStringArray(d.check_words))
	said.append(d._cart_label())
	said.append(d._pip_label())
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	var re := RegEx.create_from_string("\\b(east watch-house|west watch-house|market square|poor quarter|south-west|east well|west well|main gate)\\b")
	t.check(re.search("the east watch-house") != null and re.search("the south-east gate watch-house") == null, "the words regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL relic line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names a place of Aldermere (%s)" % [said])
	t.check(d.tour().size() == 3 and said.size() >= 25, "the lines were gathered (%d)" % said.size())
	t.check(d.check_words == ["the south-east gate watch-house", "the plaza watch-house"], "the halts' words are the south-east gate's and the plaza's (%s)" % [d.check_words])
	# The words are true where the halts stand: the first by a real gate in the old town's south-east corner, the second by the pilgrim plaza.
	var gate_near := INF
	for s: Dictionary in City.current().structures():
		if s.role == &"gate" and (s.rect as Rect2).get_center().x > 10.0 and (s.rect as Rect2).get_center().y > 0.0:
			gate_near = minf(gate_near, (s.rect as Rect2).get_center().distance_to(d.checkpoints[0]))
	t.check(gate_near <= 3.0, "the first halt is %.1f from a gate in the south-east of the old town" % gate_near)
	t.check(Places.rect(&"pilgrim_plaza").grow(2.0).has_point(d.checkpoints[1]), "the second halt is within 2 of the pilgrim plaza (%s)" % [d.checkpoints[1]])


## The cart's start, both halts, Pip, the drop-off's door and the Citadel's gate (or their edge arrows) are clear of the padded HUD stack at the camera's resting place and at
## the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as RelicRunDirector
	var at: Array = [d.temple_door, d.checkpoints[0], d.checkpoints[1], d.wren.ground_pos, d.shrine, d.route[d.route.size() - 1]]
	Cap.camera_clear(t, def, at)
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")


## Who stands near the cart's start, each halt, Pip's spot and the drop-off when the night opens (the director's own people left out): soldiers and citizens within 8 (printed).
static func _opening(d: RelicRunDirector, label: String) -> void:
	var ours := {}
	for p: Variant in d._busy():
		ours[p] = true
	var spots := {"cart start": d.temple_door, "halt 1": d.checkpoints[0], "halt 2": d.checkpoints[1], "Pip": d.wren.ground_pos, "drop-off": d.shrine}
	for name: String in spots:
		var soldiers := 0
		var lay := 0
		for p: Person in d.crowd.soldiers:
			if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(spots[name]) <= 8.0:
				soldiers += 1
		for p: Person in d.crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and not ours.has(p) and p.ground_pos.distance_to(spots[name]) <= 8.0:
				lay += 1
		print("%s relic %s: soldiers within 8: %d, other citizens %d" % [label, name, soldiers, lay])
