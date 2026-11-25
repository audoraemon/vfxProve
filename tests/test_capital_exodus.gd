extends RefCounted
## Plan "The Capital at every tier", Task 22: Exodus in the Capital (spec 6.4.4). Three households of believers hide in three real dwellings of the old town and are led out
## by the west gate, the harbour gate and the bridge gate before the Inquisition shuts them. The director's places are town vars (EscortDirector's gate_at and exit_at seeded in
## _init(), no longer assigned by _plan()); with no overrides (Aldermere) every one is what it was and every line the player reads is word for word what it was; the
## town's overrides (src/game/town/cities/capital_missions/exodus.gd) are valid and hold after setup; each household's door to its gate is in Aldermere's band (real grid
## walks); every way out is outside the walls and every mouth inside; the gatehouse queue does not hold a believer at the bridge gate; the gates' posts stand POST_GAP
## apart; the households' doors are quiet; the policies read the director; the words the player reads name no postern, Side Gate, Main Gate or Aldermere.

## Gates accepted by the coordinator (judged against Aldermere's own medians, band 0.75-1.35x), final placement, direct runs, seeds 1-3:
##   Aldermere A play 3/3 (221.9 203.5 212.8, median 213, idle 24), none lost exodus_few; Aldermere B play 3/3 (245.4 240.8 242.7, median 243).
##   Capital A play 2/3 (225.1, 295.2; seed 2 lost gates_shut at 300 s), median of the wins 260 = 1.22x Aldermere's, idle 18; none lost 3/3 exodus_few (104-109 s);
##   Capital B play 2/3 (240.0, 208.8; seed 3 lost exodus_few at 263.8 s), median 224, idle 45.
## Cause of the slower Capital night: the east household is seized at the harbour gate's watch (about 115 s) and by the Temple's searchers (about 140 s) in nearly every
## run, so the south household comes out near 190 s (Aldermere's near 150 s) and has less time before the 300 s shutting. Walk parity is fine (pinned below).
## The tuned placement is pinned in _starts (house doors, gates, posts, beats), _walk_parity and _camera_clear; the final values are in capital_missions/exodus.gd.
const ID := "exodus"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_other_escorts(t)
	_policy_reads_vars(t)
	_aldermere_pin(t)
	_starts(t)
	_no_queue(t)
	_camera_clear(t)
	Cap.release()
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Exodus test leaves Aldermere active")


## A fresh director holds each town var at its const (Aldermere's), the lists as copies; EscortDirector's gate_at and exit_at are seeded in _init().
static func _seeded(t) -> void:
	City.use(&"aldermere")
	var d := ExodusDirector.new()
	t.check(d.house_points == ExodusDirector.HOUSE_POINTS and d.gate_mouths == ExodusDirector.GATE_MOUTHS and d.gate_exits == ExodusDirector.GATE_EXITS
		and d.gate_labels == ExodusDirector.GATE_LABELS and d.gate_words == ExodusDirector.GATE_WORDS and d.gate_along == ExodusDirector.GATE_ALONG
		and d.beat_spots == ExodusDirector.BEATS and d.temple_door_at == ExodusDirector.TEMPLE_DOOR,
		"a fresh director's house_points, gate_mouths, gate_exits, gate_labels, gate_words, gate_along, beat_spots and temple_door_at are their consts")
	t.check(d.gate_at == ExodusDirector.GATE_MOUTHS[2] and d.exit_at == ExodusDirector.GATE_EXITS[2],
		"EscortDirector's gate_at and exit_at are seeded in _init() from GATE_MOUTHS[2] and GATE_EXITS[2]")
	d.house_points.append(Vector2.ZERO)
	d.gate_mouths[0] = Vector2.ZERO
	(d.beat_spots[0] as Array).append(Vector2.ZERO)
	d.gate_labels.append("X")
	t.check(ExodusDirector.HOUSE_POINTS.size() == 3 and ExodusDirector.GATE_MOUTHS[0] == Vector2(-5.75, 14.6) and ExodusDirector.BEATS[0].size() == 2
		and ExodusDirector.GATE_LABELS.size() == 3, "the lists are copies: the consts are untouched")
	var want := ["house_points", "gate_mouths", "gate_exits", "gate_labels", "gate_words", "gate_along", "beat_spots", "temple_door_at", "gate_at", "exit_at"]
	t.check(Overrides.town_vars(ExodusDirector.new()) == want, "the Exodus town vars (%s)" % [Overrides.town_vars(ExodusDirector.new())])
	t.check(ExodusDirector.OUT_AT == [15.0, 105.0, 195.0] and ExodusDirector.SHUT_AT == [150.0, 225.0, 300.0] and ExodusDirector.SHUT_WARN == 60.0
		and ExodusDirector.POST_GAP == 2.4 and ExodusDirector.CAMERA_AT == Vector2(-7.0, 9.0) and MissionBook.exodus().camera_at == ExodusDirector.CAMERA_AT,
		"SHUT_AT, OUT_AT, SHUT_WARN, POST_GAP and Aldermere's camera are untouched")
	var tuned := ExodusDirector.new()
	t.check(tuned.tune_beats == ExodusDirector.BEATS, "a fresh director's tune_beats are still BEATS")


## The other EscortDirector missions start with the places they had: the Lost Lamb's and the Prisoner's; FaceHalcyon and HideFaithful inherit the Exodus seeds of
## gate_at and exit_at (their own _plan() assigns both) and nothing else.
static func _other_escorts(t) -> void:
	var l := LostLambDirector.new()
	t.check(l.gate_at == LostLambDirector.GATE_MOUTH and l.exit_at == LostLambDirector.EXIT and l.return_to == LostLambDirector.TEMPLE_DOOR, "the Lost Lamb starts with its own places")
	for d: EscortDirector in [FaceHalcyonDirector.new(), HideFaithfulDirector.new()]:
		t.check(d.gate_at == ExodusDirector.GATE_MOUTHS[2] and d.exit_at == ExodusDirector.GATE_EXITS[2] and d.guardhouse == Vector2.INF and d.return_to == Vector2.INF
			and d.charge_start == Vector2.INF and d.watch_posts.is_empty(), "%s inherits the Exodus gate_at and exit_at and no other place" % [d.get_script().resource_path.get_file()])
	t.check(not "stocks_at" in Overrides.town_vars(ExodusDirector.new()) and not "house_points" in Overrides.town_vars(LostLambDirector.new()), "the Exodus town vars are not the others'")


## The policies read the director's households, gates and Temple and no Exodus place const, no TownLayout coordinate, no offset from a director point.
static func _policy_reads_vars(t) -> void:
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd").replace("\r\n", "\n")
	var act := _slice(bc, "func _exodus_flock(", "\n## With the flame")
	var route_b := FileAccess.get_file_as_string("res://tools/dev/routes/tier5_b.gd").replace("\r\n", "\n")
	var rb := _slice(route_b, "static func _exodus_watchers(", "static func _eye_aim(")
	t.check(act.length() > 5000 and rb.length() > 5000, "the exodus policy functions are found and sliced (%d, %d chars)" % [act.length(), rb.length()])
	var re := RegEx.create_from_string("\\b(HOUSE_POINTS|HOUSE_WORDS|HOUSE_NAMES|GATE_MOUTHS|GATE_EXITS|GATE_LABELS|GATE_WORDS|GATE_ALONG|BEATS|TEMPLE_DOOR|CAMERA_AT)\\b|TownLayout\\.")
	var off := RegEx.create_from_string("(\\.mouth|\\.way_out|\\.door|\\bgate_at|\\bexit_at|\\btemple_door|\\bgate_mouths|\\bhouse_points)\\s*[-+]\\s*(Vector2|\\()")
	t.check(re.search("x ExodusDirector.GATE_MOUTHS[2] y") != null and re.search("TownLayout.MAP") != null and re.search("ExodusDirector.GATE_WATCH") == null
		and re.search("d.gate_mouths") == null and off.search("gate.mouth + Vector2(0.0, 1.0)") != null and off.search("d.gate_at - d.exit_at") == null
		and off.search("h.door,") == null, "the scan regexes bite on a sample and pass what they should")
	for body: String in [act, rb]:
		var m := re.search(body)
		t.check(m == null, "an exodus policy reads no Exodus place const or TownLayout coordinate (%s)" % [m.get_string() if m != null else ""])
		var o := off.search(body)
		t.check(o == null, "an exodus policy takes no offset from a director point (%s)" % [o.get_string() if o != null else ""])
	t.check("d.gates" in act and "d.households" in act and "d.gates" in rb and "d.households" in rb, "each exodus policy reads d.gates and d.households")


## The text from `from` to the next `to` after it ("" when either is missing: a missing marker fails the length checks).
static func _slice(src: String, from: String, to: String) -> String:
	var at := src.find(from)
	if at < 0:
		return ""
	var body := src.substr(at + from.length())
	var end := body.find(to)
	return body.substr(0, end) if end > 0 else ""


## Aldermere after setup is what it was: the gate and exit are the Main Gate's, the Temple's door and the beats and posts as before, the tour's lines word for word.
static func _aldermere_pin(t) -> void:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.exodus())
	var d: ExodusDirector = s.d
	t.check(d.gate_at == d._walkable(Vector2(2.7, 14.4)) and d.exit_at == d._walkable(Vector2(2.7, 17.6)), "Aldermere's gate_at and exit_at are the Main Gate's, as before")
	t.check(d.temple_door == d._walkable(LostLambDirector.TEMPLE_DOOR) and d.return_to == LostLambDirector.TEMPLE_DOOR and d.guardhouse == LostLambDirector.TEMPLE_DOOR
		and LostLambDirector.TEMPLE_DOOR == Vector2(0.8, -5.0), "Aldermere's Temple door, return spot and guardhouse are as before")
	t.check(d.gates.size() == 3 and (d.gates[0] as ExodusDirector.Gate).label == "POSTERN" and (d.gates[1] as ExodusDirector.Gate).label == "SIDE GATE"
		and (d.gates[2] as ExodusDirector.Gate).label == "MAIN GATE" and (d.gates[2] as ExodusDirector.Gate).words == "the Main Gate", "Aldermere's gates are named as before")
	t.check(d.watch_posts.size() == 6 and d.watch_posts[4] == d._walkable(Vector2(2.7, 14.4) + Vector2.RIGHT * ExodusDirector.POST_GAP * -0.5)
		and d.watch_posts[5] == d._walkable(Vector2(2.7, 14.4) + Vector2.RIGHT * ExodusDirector.POST_GAP * 0.5), "the Main Gate's posts are as before")
	t.check(d.beats.size() == 2 and d.beats[0][0] == d._walkable(Vector2(-6.25, 0.0)) and d.beats[1][1] == d._walkable(Vector2(12.0, 9.0)) and d.tune_beats == ExodusDirector.BEATS,
		"the beats are as before")
	var tour := d.tour()
	t.check(tour.size() == 3 and tour[0][1] == "The west household hides here. At %s, whisper its lamp to the postern; the rest follow." % UiTheme.clock(15.0)
		and tour[1][1] == "Gates shut: postern %s, Side Gate %s, Main Gate %s (lost unless ten are out)." % [UiTheme.clock(150.0), UiTheme.clock(225.0), UiTheme.clock(300.0)]
		and tour[2][1] == "The Temple. Inquisitors take any believer they catch here. Ten must get out.", "Aldermere's tour lines are word for word as before (%s)" % [tour])
	t.check(MissionBook.exodus().goal == "Lead ten of your twelve believers out of Aldermere before the Inquisition shuts the last gate at %s" % UiTheme.clock(300.0),
		"Aldermere's goal is as before")
	var doors := []
	for h: ExodusDirector.Household in d.households:
		doors.append(h.door)
	print("ALDERMERE exodus doors %s gates %s %s %s" % [doors, (d.gates[0] as ExodusDirector.Gate).mouth, (d.gates[1] as ExodusDirector.Gate).mouth, (d.gates[2] as ExodusDirector.Gate).mouth])
	Kit.done(s)


## The Capital's director after setup reads back every override; the households' houses are real dwellings with quiet doors; the gates are the Capital's.
static func _starts(t) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var dov: Dictionary = ov.director
	var d := Cap.starts(t, ID) as ExodusDirector
	t.check(d != null and d.house_points == dov.house_points and d.gate_mouths == dov.gate_mouths and d.gate_exits == dov.gate_exits and d.gate_labels == dov.gate_labels
		and d.gate_words == dov.gate_words and d.gate_along == dov.gate_along and d.beat_spots == dov.beat_spots and d.temple_door_at == dov.temple_door_at,
		"the director reads back the Capital's house_points, gate_mouths, gate_exits, gate_labels, gate_words, gate_along, beat_spots and temple_door_at")
	if d == null:
		return
	var grid: WalkGrid = d.crowd._grid
	t.check(dov.gate_at == dov.gate_mouths[2] and dov.exit_at == dov.gate_exits[2], "the overrides' gate_at and exit_at are gate_mouths[2] and gate_exits[2] (the bridge gate)")
	t.check(d.gate_at.distance_to(dov.gate_mouths[2]) < 1.0 and d.exit_at.distance_to(dov.gate_exits[2]) < 1.0,
		"gate_at and exit_at hold after setup: the bridge gate's mouth and way out (%s %s)" % [d.gate_at, d.exit_at])
	t.check(d.temple_door.distance_to(dov.temple_door_at) < 1.0 and d.return_to == dov.temple_door_at and d.guardhouse == dov.temple_door_at,
		"the Temple's door, the return spot and the guardhouse are temple_door_at (%s)" % d.temple_door)
	t.check(d.gates.size() == 3 and d.households.size() == 3 and d.watch_posts.size() == 6 and d.beats.size() == 2, "three gates, three households, six posts, two beats")
	var spots := {"temple_door_at": dov.temple_door_at}
	var posts_ok := true
	for g in d.gates.size():
		var gate: ExodusDirector.Gate = d.gates[g]
		t.check(gate.mouth.distance_to(dov.gate_mouths[g]) < 1.0 and gate.way_out.distance_to(dov.gate_exits[g]) < 1.0 and gate.label == dov.gate_labels[g] and gate.words == dov.gate_words[g],
			"gate %d is %s: its mouth %s and way out %s hold after setup" % [g, gate.label, gate.mouth, gate.way_out])
		spots["mouth %d" % g] = dov.gate_mouths[g]
		spots["exit %d" % g] = dov.gate_exits[g]
		posts_ok = posts_ok and absf((d.watch_posts[2 * g] as Vector2).distance_to(d.watch_posts[2 * g + 1]) - ExodusDirector.POST_GAP) < 0.5
	t.check(posts_ok, "each gate's two posts stand about POST_GAP (%.1f) apart" % ExodusDirector.POST_GAP)
	Cap.spread(t, d.watch_posts)
	for b: Array in dov.beat_spots:
		for p: Vector2 in b:
			spots["beat %s" % p] = p
	for i in dov.house_points.size():
		spots["house %d" % i] = dov.house_points[i]
	Cap.spots_land(t, {"grid": grid}, spots, 1.0)
	t.check(d.households.size() == 3, "every household has its house")
	t.check((d.households[0] as ExodusDirector.Household).door.distance_to(Vector2(-16.19398, -5.4)) < 0.05 and (d.households[1] as ExodusDirector.Household).door.distance_to(Vector2(12.29509, -14.17)) < 0.05
		and (d.households[2] as ExodusDirector.Household).door.distance_to(Vector2(8.076139, -2.575)) < 0.05, "the tuned households stand at the doors (-16.19, -5.4), (12.30, -14.17) and (8.08, -2.58)")
	t.check(dov.gate_mouths == [Vector2(-22.4, -13.0), Vector2(16.4, -9.0), Vector2(4.0, 2.4)] and dov.gate_exits == [Vector2(-25.6, -13.0), Vector2(19.6, -9.0), Vector2(4.0, 5.6)]
		and dov.gate_along == [Vector2(0.0, 1.0), Vector2(1.0, 0.0), Vector2(1.0, 0.0)] and dov.beat_spots[1] == [Vector2(2.0, -7.0), Vector2(12.0, -7.0)],
		"the tuned gates, the harbour posts' way along the approach and the second beat's y -7 are pinned")
	_walls(t, d, dov)
	_houses(t, d, dov)
	_walk_parity(t, d)
	City.use(&"capital")
	_words_true(t, d)


## Every way out is outside the old town's walls and every mouth is inside them.
static func _walls(t, d: ExodusDirector, dov: Dictionary) -> void:
	City.use(&"capital")
	var out := true
	var inside := true
	for g in d.gates.size():
		out = out and Walls.outside(d.gates[g].way_out) and Walls.outside(dov.gate_exits[g])
		inside = inside and not Walls.outside(d.gates[g].mouth)
	t.check(out, "every gate's way out is outside the Capital's walls (%s)" % [d.gates.map(func(g: ExodusDirector.Gate) -> Vector2: return g.way_out)])
	t.check(inside, "every gate's mouth is inside the walls")


## Each household's house is a dwelling (a wish may ruin it), its door is within a unit of its point and quiet (no beat and no gate post within QUIET), its road ends at its own
## gate's way out, and the words west, east and south are true of the three houses.
static func _houses(t, d: ExodusDirector, dov: Dictionary) -> void:
	var near := INF
	var far := 0.0
	var ok := true
	var own := true
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		ok = ok and RuinWish.fits(h.house, "house") and h.house.damage_filter.is_valid() and h.gate == i
		far = maxf(far, h.door.distance_to(dov.house_points[i]))
		for b: PackedVector2Array in d.beats:
			for k in range(b.size() - 1):
				near = minf(near, Geometry2D.get_closest_point_to_segment(h.door, b[k], b[k + 1]).distance_to(h.door))
		for post: Vector2 in d.watch_posts:
			near = minf(near, post.distance_to(h.door))
		var road := d.road(i)
		own = own and (road.back() as Vector2) == (d.gates[i] as ExodusDirector.Gate).way_out
	t.check(ok, "each household's house is a dwelling a wish may ruin")
	t.check(far <= 1.0, "each household's door is within a unit of its house point (%.2f)" % far)
	t.check(near > ExodusDirector.QUIET - 0.01, "each household's door is quiet: no beat and no gate post within %.1f (nearest %.2f)" % [ExodusDirector.QUIET, near])
	t.check(own, "each household's road ends at its own gate's way out (the nearest open one)")
	var h0: ExodusDirector.Household = d.households[0]
	var h1: ExodusDirector.Household = d.households[1]
	var h2: ExodusDirector.Household = d.households[2]
	t.check(h0.door.x < h1.door.x and h0.door.x < h2.door.x and h1.door.x > h2.door.x and h2.door.y > h1.door.y and h2.door.y > h0.door.y,
		"the west household is the westmost, the east the eastmost and the south the southmost of the three (%s %s %s)" % [h0.door, h1.door, h2.door])
	var wr := d.road(2)
	print("CAPITAL exodus doors %s %s %s, houses %s %s %s" % [h0.door, h1.door, h2.door, h0.house.center(), h1.house.center(), h2.house.center()])
	t.check(wr.size() >= 2, "the south household has a road")


## Soldiers and citizens within 8 of each household's door, each gate's mouth and the Temple's door (printed for both towns); returns the most soldiers within 8 of any.
static func _opening(d: ExodusDirector, label: String) -> int:
	var worst := 0
	var line := PackedStringArray()
	var keys: Array[Vector2] = []
	for h: ExodusDirector.Household in d.households:
		keys.append(h.door)
	for g: ExodusDirector.Gate in d.gates:
		keys.append(g.mouth)
	keys.append(d.temple_door)
	for at in keys:
		var soldiers := 0
		var folk := 0
		for p: Person in d.crowd.soldiers:
			if is_instance_valid(p) and p.ground_pos.distance_to(at) <= 8.0:
				soldiers += 1
		for p: Person in d.crowd.citizens:
			if is_instance_valid(p) and not p.soldier and p.ground_pos.distance_to(at) <= 8.0:
				folk += 1
		worst = maxi(worst, soldiers)
		line.append("%s %d/%d" % [at, soldiers, folk])
	print("%s exodus opening (soldiers/citizens within 8): %s" % [label, ", ".join(line)])
	return worst


## Each household's door to its gate's mouth: Capital against Aldermere on the real grids (band 0.75-1.35); printed.
static func _walk_parity(t, d: ExodusDirector) -> void:
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.exodus())
	var ad: ExodusDirector = a.d
	for i in 3:
		var cw := Cap.walk(d.crowd._grid, (d.households[i] as ExodusDirector.Household).door, (d.gates[i] as ExodusDirector.Gate).mouth)
		var aw := Cap.walk(ad.crowd._grid, (ad.households[i] as ExodusDirector.Household).door, (ad.gates[i] as ExodusDirector.Gate).mouth)
		Cap.parity(t, "household %d's door to its gate" % i, cw, aw)
	var cap_soldiers := _opening(d, "CAPITAL")
	var ald_soldiers := _opening(ad, "ALDERMERE")
	t.check(cap_soldiers <= ald_soldiers + 4, "the Capital opens with at most 4 more soldiers than Aldermere within 8 of any door, gate or the Temple (%d against %d)" % [cap_soldiers, ald_soldiers])
	Kit.done(a)
	City.use(&"capital")


## A believer set at the bridge gate's mouth with a whisper to its way out gets there within the walk plus 2 s on a built Capital in a calm town: the gatehouse's queue
## (one person a second through a gate) does not hold him.
static func _no_queue(t) -> void:
	City.use(&"capital")
	var d := Cap.starts(t, ID) as ExodusDirector
	if d == null:
		return
	var gate: ExodusDirector.Gate = d.gates[2]
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))
	d._come_out(2)
	for k in 20:
		d.crowd.step_people(DT)
		d.crowd.advance(DT)
		d.rules.advance(DT)
	var c: EscortDirector.Charge = (d.households[2] as ExodusDirector.Household).members[0]
	var p := c.man as Person
	t.check(not p.inside, "the believer is out of doors")
	Kit.arrive(p, gate.mouth)
	t.check(p.whisper(gate.way_out, MindWhisperFx.LINGER), "the believer hears the whisper")
	var walk := Cap.walk(d.crowd._grid, gate.mouth, gate.way_out)
	var due := walk / maxf(p.walk_speed, 0.01) + 2.0
	var took := -1.0
	var clock := 0.0
	while clock < due + 10.0 and took < 0.0:
		d.crowd.step_people(DT)
		d.crowd.advance(DT)
		d.rules.advance(DT)
		clock += DT
		if p.ground_pos.distance_to(gate.way_out) <= EscortDirector.ESCAPE_REACH:
			took = clock
	print("CAPITAL exodus bridge gate: walk %.1f at %.2f/s, arrived %.1f s (due %.1f)" % [walk, p.walk_speed, took, due])
	t.check(took >= 0.0 and took <= due, "a believer at the bridge gate's mouth reaches its way out in %.1f s, within the walk plus 2 s (%.1f)" % [took, due])


## No line the player reads names the postern, the Side Gate, the Main Gate or Aldermere: the tour, the brief, the goal, the hints, the steps, the tags, the gates' labels.
static func _words_true(t, d: ExodusDirector) -> void:
	var said := PackedStringArray()
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var def := MissionBook.get_mission("%s@capital" % ID)
	said.append_array(def.brief)
	said.append(def.goal)
	said.append(def.goal_label)
	said.append(def.lose)
	for phase in ["", "caught", "hounds", "gate", "shut", "waiting"]:
		said.append(MissionHints.line(ID, phase))
	for step: Dictionary in MissionSteps.steps(ID):
		said.append(String(step.t))
	for tag: MapTag in d.tags():
		if tag.label != "":
			said.append(tag.label)
	for g: ExodusDirector.Gate in d.gates:
		said.append(g.label)
		said.append(g.words)
	var re := RegEx.create_from_string("\\b(postern|side gate|main gate|aldermere|dock)\\b")
	t.check(re.search("the postern") != null and re.search("lead them out of aldermere") != null and re.search("the harbour gate") == null, "the word regex bites on a sample")
	var wrong := false
	for line in said:
		var m := re.search(line.to_lower())
		if m != null:
			wrong = true
			print("CAPITAL exodus line names '%s': %s" % [m.get_string(), line])
	t.check(not wrong, "no line names the postern, the Side Gate, the Main Gate or Aldermere (%s)" % [said])
	var tour := d.tour()
	t.check(tour.size() == 3 and "west gate" in String(tour[0][1]).to_lower() and "west gate" in String(tour[1][1]).to_lower() and "harbour gate" in String(tour[1][1]).to_lower()
		and "bridge gate" in String(tour[1][1]).to_lower(), "the tour names the west, harbour and bridge gates (%s)" % [tour])
	t.check(def.goal.ends_with(UiTheme.clock(300.0)) and "the Capital" in def.goal, "the goal names the Capital and the last shutting (%s)" % def.goal)
	t.check(d.gates[0].label == "WEST GATE" and d.gates[1].label == "HARBOUR GATE" and d.gates[2].label == "BRIDGE GATE", "the gates' labels are the Capital's")
	t.check(MissionHints.line(ID, "gate") != "" and said.size() >= 20, "the lines were gathered (%d)" % said.size())


## The doors, the gates' mouths and the Temple's door (or their edge arrows) are clear of the padded HUD stack at the camera's resting place and the intro's start.
static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var d := Cap.starts(t, ID) as ExodusDirector
	var at: Array = [d.temple_door]
	for h: ExodusDirector.Household in d.households:
		at.append(h.door)
	for g: ExodusDirector.Gate in d.gates:
		at.append(g.mouth)
	t.check(def.camera_at == Vector2(-9.0, 0.0) and def.intro_from == Vector2(-9.0, 6.0), "camera_at and intro_from are overridden together (C9)")
	Cap.camera_clear(t, def, at)
	Cap.release()
	City.use(&"aldermere")
