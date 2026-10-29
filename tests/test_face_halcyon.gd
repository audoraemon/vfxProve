extends RefCounted
## God P5 Task 8 (plan Task 8, MS §6): Hunt 5, Face Halcyon (FaceHalcyonDirector on ExodusDirector): four processions of a bound believer in the
## midst of three soldier escorts, led from four district houses to the pyre before the Temple's steps; a believer is freed the moment fewer than
## two of his escort are able (or when he stands out of the walls), burns FH_BURN seconds after he reaches the pyre; three freed win, two burned,
## the Gaze full or dawn lose. The world is test_lost_lamb's kind: a town with its crowd and a Rules, run in 0.05 s steps (people do not walk in it, so
## the tests read goals and anchors and move people with Kit.arrive()).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const Book := preload("res://tests/test_hunt_book.gd")
## One look is a TICK, and a little more so a director whose own timer is mid-way still gets one.
const LOOK := EscortDirector.TICK * 2.0 + DT


static func run(t) -> void:
	_tuned(t)
	_names_free(t)
	_setup(t)
	_frame(t)
	_chain(t)
	_form_and_walk(t)
	_file_places(t)
	_body_walk(t)
	_tag_matches_rule(t)
	_report(t)
	_one_seizer_not_free(t)
	_free_break(t)
	_call_on_procession(t)
	_out_of_walls(t)
	_burn(t)
	_god_kill(t)
	_lose_two(t)
	_gaze(t)
	_win_beats_gaze(t)
	_strip_rows(t)
	_warning_window(t)
	_one_stake(t)
	_straggler(t)
	_busy(t)
	_evacuation(t)
	_wishes(t)


static func _world() -> Dictionary:
	return Kit.world(HuntBook.def(MissionBook.FACE_HALCYON))


## The live keepout: the kit's stack grown by the HUD's pad.
static func _keepout() -> Rect2:
	return Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))


static func _believer(d: FaceHalcyonDirector, i: int) -> Person:
	return d.procs[i].charge.man as Person


## Procession `i`'s believer and his escorts set down in file round `at`, as if they had walked there (the trail behind him a straight lane west).
static func _stand(d: FaceHalcyonDirector, i: int, at: Vector2) -> void:
	var pr: FaceHalcyonDirector.Procession = d.procs[i]
	Kit.arrive(pr.charge.man as Person, at)
	pr.trail = []
	for k in range(12, -1, -1):
		pr.trail.append(at + Vector2(-0.5 * float(k), 0.0))
	pr.places = d._file_places(pr, at)
	for k in pr.escorts.size():
		if MissionDirector._alive(pr.escorts[k]):
			Kit.arrive(pr.escorts[k] as Person, pr.places[k])


## Every procession forms up now.
static func _form_all(d: FaceHalcyonDirector) -> void:
	for i in d.households.size():
		d._come_out(i)


## One look of the night.
static func _look(s: Dictionary, n := 1) -> void:
	Kit.run_for(s, LOOK * float(n))


## The tags' labels.
static func _labels(d: FaceHalcyonDirector) -> Array:
	return Kit.labels(d)


# --- The numbers ---

static func _tuned(t) -> void:
	var d := FaceHalcyonDirector.new()
	d._tune()
	t.check(d.tune_need == FaceHalcyonDirector.FH_NEED and d.tune_per_house == 1 and d.tune_hounds == 0 and d.tune_shut_at.is_empty()
		and is_equal_approx(d.tune_believer_pace, FaceHalcyonDirector.FH_PROC_PACE) and is_equal_approx(d.tune_chain, FaceHalcyonDirector.FH_CHAIN)
		and d.tune_out_at == FaceHalcyonDirector.FH_PROC_AT and d.tune_beats.is_empty() and d.tune_gate_watch == 0,
		"setup puts the Hunt's numbers into the base's tune_ vars: one believer a house, three needed, no gate shuts, no hounds (%s %s)" % [d.tune_need, d.tune_out_at])
	t.check(ExodusDirector.NEED == 10 and ExodusDirector.PER_HOUSE == 4 and ExodusDirector.SHUT_AT.size() == 3 and ExodusDirector.HOUNDS == 2,
		"the base's own consts stand (Exodus: 10 of 12 in 4s, three gates, two hounds)")
	t.check(FaceHalcyonDirector.FH_ESCORT == 3 and FaceHalcyonDirector.FH_ESCORT_HOLD == 2 and is_equal_approx(FaceHalcyonDirector.FH_ESCORT_REACH, 1.6)
		and is_equal_approx(FaceHalcyonDirector.FH_CHAIN, 45.0) and FaceHalcyonDirector.FH_PROC_AT == [30.0, 95.0, 160.0, 225.0]
		and is_equal_approx(FaceHalcyonDirector.FH_FORM, 8.0) and is_equal_approx(FaceHalcyonDirector.FH_BURN, 12.0)
		and is_equal_approx(FaceHalcyonDirector.FH_PYRE_REACH, 1.2) and FaceHalcyonDirector.FH_LOSE_BURNED == 2 and FaceHalcyonDirector.FH_PROC_PACE == 0.5,
		"MS §6's numbers: 3 escorts, 2 hold, reach 1.6, chain 45, forming 8, burn 12, pyre reach 1.2, two burned lose, pace 0.5")


## A subclass never redeclares a parent's const name (Ruling C2: a parse error); a source scan holds it to its own FH_ prefix.
static func _names_free(t) -> void:
	var own: Dictionary = (load("res://src/game/mission/face_halcyon_director.gd") as GDScript).get_script_constant_map()
	var clash := []
	var bad_prefix := []
	var base: GDScript = load("res://src/game/mission/exodus_director.gd")
	var theirs := {}
	while base != null:
		for k: Variant in base.get_script_constant_map():
			theirs[k] = true
		base = base.get_base_script()
	for k: Variant in own:
		if theirs.has(k):
			clash.append(k)
		if not String(k).begins_with("FH_") and String(k) != "Procession":  # (the one inner class, the Hunt's record)
			bad_prefix.append(k)
	t.check(clash.is_empty() and bad_prefix.is_empty() and own.size() > 15, "every const is the Hunt's own and prefixed FH_ (clashes %s, unprefixed %s, %d consts)" % [clash, bad_prefix, own.size()])


# --- The night's start ---

static func _setup(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var ok := d.charges.size() == FaceHalcyonDirector.FH_BELIEVERS and d.households.size() == 4 and d.procs.size() == 4 and d.gates.is_empty()
	var houses := {}
	var inside := true
	var all_escorts: Array = []
	for i in 4:
		var h: ExodusDirector.Household = d.households[i]
		var pr: FaceHalcyonDirector.Procession = d.procs[i]
		ok = ok and RuinWish.fits(h.house, "house") and h.members.size() == 1 and h.house.damage_filter.is_valid() and not h.out and h.searchers.is_empty() \
			and pr.phase == FaceHalcyonDirector.Procession.Phase.WAITING and pr.charge == h.members[0] and pr.escorts.size() == FaceHalcyonDirector.FH_ESCORT
		houses[h.house] = true
		var p := _believer(d, i)
		ok = ok and not p.soldier and p.profile.faith == CitizenProfile.Faith.NONE and absf(p.pace - FaceHalcyonDirector.FH_PROC_PACE) < 0.001
		inside = inside and p.inside and p.mind == Person.Mind.DUTY
		for v: Variant in pr.escorts:
			var e := v as Person
			inside = inside and e.inside and e.soldier and e.corps == Person.Corps.NONE and e.mind == Person.Mind.DUTY
			all_escorts.append(e)
	t.check(ok and houses.size() == 4, "four believers, one in each of four stone dwellings, three soldier escorts with each; no gates, no searchers (%d charges)" % d.charges.size())
	t.check(inside and all_escorts.size() == 12 and all_escorts.size() == _distinct(all_escorts),
		"believers and their twelve distinct escorts wait inside their houses on duty, so nobody is a target before the procession forms up")
	var door := d.lantern_door()
	t.check(d.pyre_at.distance_to(door) > 1.5 and d.pyre_at.distance_to(door) < 4.0 and (s.crowd as Crowd)._grid.nearest_walkable(d.pyre_at).distance_to(d.pyre_at) < 0.05,
		"the pyre stands on walkable ground before the Temple's steps (%.1f from the door)" % d.pyre_at.distance_to(door))
	var walks := PackedStringArray()
	var near := INF
	var far := 0.0
	for i in 4:
		var h: ExodusDirector.Household = d.households[i]
		var secs := d._walk_secs(h.door)
		near = minf(near, secs)
		far = maxf(far, secs)
		walks.append("%.0f" % secs)
	t.check(near > 25.0 and far < 45.0, "each house is a street away from the pyre: the walk at the believers' pace takes %s s" % [", ".join(walks)])
	var banners: Array = s.banners
	t.check(banners == ["FACE HALCYON"], "the opening banner (%s)" % [banners])
	var ids := []
	var labels := []
	for e in d.timeline.upcoming(5):
		ids.append(e.id)
		labels.append(e.label)
	t.check(ids == ["out_0", "out_1", "out_2", "out_3"] and labels[0] == "The west procession forms up", "the strip lists the four processions forming up, no searchers' row (%s)" % [labels])
	var tags := _labels(d)
	var waiting := tags.filter(func(l: Variant) -> bool: return String(l).begins_with("PROCESSION IN "))
	t.check(waiting.size() == 4 and tags.has("PROCESSION IN %s" % UiTheme.clock(30.0)) and tags.has("PYRE") and d.tags().size() == 5,
		"a grey PROCESSION IN tag over each waiting house and the PYRE (%s)" % [tags])
	var edges := 0
	for m in d.tags():
		edges += 1 if m.edge else 0
	t.check(edges >= 2, "the pyre and the next house are pointed at from the screen's edge")
	var pyre: MapTag = null
	for m in d.tags():
		if m.label == "PYRE":
			pyre = m
	t.check(pyre != null and pyre.outline.has_area() and pyre.color == ExodusDirector.MARK_PLACE and pyre.outline.has_point(d.pyre_at),
		"the pyre is orange with its pile outlined (no art)")
	Kit.done(s)


static func _distinct(list: Array) -> int:
	var seen := {}
	for v in list:
		seen[v] = true
	return seen.size()


static func _frame(t) -> void:
	var m := HuntBook.def(MissionBook.FACE_HALCYON)
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	var main := m.objectives()[0] as EscortObjective
	t.check(m.tier == 5 and m.director == FaceHalcyonDirector and reasons == ["freed", "gaze", "dawn"] and main.need == 3 and m.lantern == LanternWatch.KIND_GAZE
		and Array(m.default_loadout) == ["whisper", "discord", "doom"] and not m.mission_tags.has(TierBook.UNAWARE_TAG),
		"the frame: Tier 5, three freed then the Gaze then dawn, the Gaze for the bell (%s)" % [reasons])
	var gazes := 0
	for o in m.objectives():
		gazes += 1 if o is GazeObjective else 0
	t.check(gazes == 1, "the real Hunt 5 lists its own Gaze objective (%d)" % gazes)
	t.check(m.goal == "Free three of the four believers led to the pyre, unseen by Halcyon" and m.goal_label == "The pyre stays cold"
		and m.lose == "Two believers burn, Halcyon's Gaze fills, or dawn comes", "the plate's copy is the spec's")
	for key in ["face_halcyon", "face_halcyon.pyre", "face_halcyon.gaze"]:
		t.check(MissionHints.line("face_halcyon", key.trim_prefix("face_halcyon").trim_prefix(".")) != "", "the hint %s has its line" % key)
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var cam := FaceHalcyonDirector.FH_CAMERA_AT
	var zone := _keepout()
	var worst := INF
	var clear := m.camera_at == cam and Kit.clear_of_stack(d.pyre_at, cam, zone) and Kit.clear_of_stack(d.temple_door, cam, zone)
	var points: Array[Vector2] = [d.pyre_at, d.temple_door]
	for h: ExodusDirector.Household in d.households:
		points.append(h.door)
	for at in points:
		clear = clear and Kit.clear_of_stack(at, cam, zone)
		var shown := Kit.shown_at(at, cam)
		worst = minf(worst, maxf(shown.x - zone.end.x, shown.y - zone.end.y))
	t.check(clear and worst >= 0.0, "the camera keeps the pyre, the Temple's door and the four doors (or their arrows) clear of the padded stack (%.0f px to spare)" % worst)
	var shown_pyre := Kit.shown_at(d.pyre_at, cam)
	t.check(Rect2(Vector2(40.0, 40.0), Kit.VIEW - Vector2(80.0, 80.0)).has_point(shown_pyre) and worst >= 20.0,
		"the pyre is on screen at the start (%s) and every arrow keeps 20 px off the padded stack" % [shown_pyre])
	var tour := d.tour()
	var fits := true
	for stop: Array in tour:
		fits = fits and UiTheme.width(String(stop[1]), UiTheme.SIZE_BODY) + 16.0 <= Kit.VIEW.x
	t.check(tour.size() == 2 and fits and tour[1][0] == d.pyre_at, "the tour: the first house, the pyre; each line within the caption's plate (%d stops)" % tour.size())
	Kit.done(s)


# --- The chain, the forming and the walk ---

static func _chain(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	t.check(absf(d.due_in(0) - 30.0) < 0.01 and absf(d.due_in(1) - 95.0) < 0.01 and absf(d.due_in(3) - 225.0) < 0.01,
		"the processions form up at 0:30, 1:35, 2:40 and 3:45 at the latest")
	# Procession 0 forms up at its time: the banner, then it is freed or burned: the next is due 45 s after.
	Kit.run_for(s, 30.5)
	t.check((d.households[0] as ExodusDirector.Household).out and (s.banners as Array).has("THE WEST PROCESSION FORMS UP") and not (d.households[1] as ExodusDirector.Household).out,
		"at 0:30 the west procession forms up and the banner says so (%s)" % [s.banners])
	d.charges[0].escaped = true
	_look(s)
	var left := d.timeline.seconds_to("out_1")
	t.check((d.households[0] as ExodusDirector.Household).done and absf(left - FaceHalcyonDirector.FH_CHAIN) < 2.0 and absf(d.due_in(1) - left) < 1.0,
		"a procession freed: the strip and the tag show the next at the chain (%.1f s, tag %.1f)" % [left, d.due_in(1)])
	Kit.run_for(s, FaceHalcyonDirector.FH_CHAIN + 0.5)
	t.check((d.households[1] as ExodusDirector.Household).out and d._clock < 95.0 - 5.0 and (s.banners as Array).has("THE NORTH PROCESSION FORMS UP"),
		"it forms up %d s later, before its own time (%.0f s)" % [roundi(FaceHalcyonDirector.FH_CHAIN), d._clock])
	# A burned procession chains the next in the same way.
	var e: FaceHalcyonDirector = null
	var n := _world()
	e = n.d
	e._come_out(2)
	e.charges[2].taken = true
	_look(n)
	t.check(absf(e.timeline.seconds_to("out_3") - FaceHalcyonDirector.FH_CHAIN) < 1.0, "a procession burned chains the next in the same way (%.1f s)" % e.timeline.seconds_to("out_3"))
	Kit.done(n)
	Kit.done(s)


static func _form_and_walk(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var h: ExodusDirector.Household = d.households[0]
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	d._come_out(0)
	var p := _believer(d, 0)
	var outside := not p.inside and p.visible
	var near := true
	var gap := INF
	for k in 3:
		var e := pr.escorts[k] as Person
		outside = outside and not e.inside and e.visible and e.mind == Person.Mind.DUTY
		near = near and e.ground_pos.distance_to(p.ground_pos) <= FaceHalcyonDirector.FH_SPAN and e.ground_pos.distance_to(p.ground_pos) >= 0.7
		for j in range(k + 1, 3):
			gap = minf(gap, e.ground_pos.distance_to((pr.escorts[j] as Person).ground_pos))
	t.check(outside and near and gap > 2.0 * SilentDoom.RADIUS and d.able_escort(0) == 3,
		"forming up: the believer and three escorts out at the door, each beside him and more than 1.6 apart, all three able (%.2f)" % gap)
	t.check(pr.phase == FaceHalcyonDirector.Procession.Phase.FORMING and absf(pr.form_end - d._clock - FaceHalcyonDirector.FH_FORM) < 0.01,
		"the procession forms for FH_FORM seconds")
	_look(s)
	t.check(p.anchor.distance_to(h.door) < 0.5 and p.fearless_left > 0.0 and p.shaken(), "while forming he stands at his door, past fear and deaf to a whisper (the bound believer)")
	var anchors_ok := true
	for k in 3:
		anchors_ok = anchors_ok and (pr.escorts[k] as Person).mind == Person.Mind.DUTY
	var banners_before := (s.banners as Array).size()
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM)
	t.check(pr.phase == FaceHalcyonDirector.Procession.Phase.MARCHING and p.anchor.distance_to(d.pyre_at) < 0.6 and anchors_ok,
		"after the forming he walks to the pyre (anchor %s, pyre %s)" % [p.anchor, d.pyre_at])
	var placed := pr.places.size() == 3
	for k in 3:
		placed = placed and (pr.escorts[k] as Person).anchor.distance_to(pr.places[k]) < 0.5
	t.check(placed and (s.banners as Array).size() == banners_before, "his escorts are sent to their places on the ring round him, each look; no banner for the march")
	t.check(not (s.banners as Array).has("A BELIEVER IS FREED  1/3") and d.out_count() == 0, "nobody is freed by the forming or the march alone")
	# A whisper cannot turn him; fright does not move him.
	t.check(not p.whisper(p.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER) and p.mind == Person.Mind.DUTY, "a Mind Whisper does not take on the bound believer")
	Kit.done(s)


## Along the whole road of every house, the three escorts' places (the lead ahead, two behind along the trail, _file_places()) keep more than two Silent
## Doom radii apart and within the span of the believer, and an escort standing on his place is able, so a walk round a corner frees nobody by luck; a
## house is only chosen if a lane behind its door holds the file (review of Task 8, I1).
static func _file_places(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var worst := INF
	var far := 0.0
	var points := 0
	for i in 4:
		var h: ExodusDirector.Household = d.households[i]
		var pr: FaceHalcyonDirector.Procession = d.procs[i]
		d._come_out(i)
		var road := d._road(h.door)
		var at: Vector2 = road[0]
		for k in range(1, road.size()):
			var to: Vector2 = road[k]
			var steps := maxi(1, ceili(at.distance_to(to) / 0.2))
			for q in range(1, steps + 1):
				var here := at.lerp(to, float(q) / float(steps))
				Kit.arrive(pr.charge.man as Person, here)
				d._note_trail(pr, pr.charge.man as Person)
				var spots := d._file_places(pr, here)
				for a in 3:
					for b in range(a + 1, 3):
						worst = minf(worst, spots[a].distance_to(spots[b]))
					far = maxf(far, spots[a].distance_to(here))
				points += 1
			at = to
	t.check(points > 500 and worst > 1.5, "along all four roads (%d points) the escorts' places are more than 1.5 apart (nearest %.2f; round a right-angled lane corner the 2.6 along the road are 1.6 apart as the crow flies; the bodies are pinned in _body_walk)" % [points, worst])
	t.check(far <= FaceHalcyonDirector.FH_SPAN, "every place is within %.1f of the believer (farthest %.2f)" % [FaceHalcyonDirector.FH_SPAN, far])
	# Standing on their places they are able: at the door, on the road and at the stake.
	var n := _world()
	var e: FaceHalcyonDirector = n.d
	_form_all(e)
	var every := true
	for i in 4:
		var h: ExodusDirector.Household = e.households[i]
		for at: Vector2 in [h.door, e.pyre_at, h.door.lerp(e.pyre_at, 0.4), h.door.lerp(e.pyre_at, 0.7)]:
			_stand(e, i, _nearest_walkable(n, at))
			every = every and e.able_escort(i) == 3
	t.check(every, "standing on their places at the door, on the road and at the stake, all three escorts are able")
	# The lane behind each door was found: the trail is seeded with it, the second and third escorts stand in it.
	var seeded := true
	for i in 4:
		seeded = seeded and (e.procs[i] as FaceHalcyonDirector.Procession).places.size() == 3
	t.check(seeded, "every procession has its three places")
	Kit.done(n)
	Kit.done(s)


## A believer and his escorts moved bodily (the test world does not walk them): each step a person on duty goes toward his anchor along the walk grid at
## his own pace, and stops within Person.GOAL_REACH of it, as a walker does.
static func _walk_body(crowd: Crowd, p: Person, dt: float) -> void:
	if p.mind != Person.Mind.DUTY or p.anchor == Vector2.INF or p.ground_pos.distance_to(p.anchor) <= Person.GOAL_REACH:
		return
	var left := p.walk_speed * dt
	var path := crowd._grid.path(p.ground_pos, p.anchor)
	var at := p.ground_pos
	for k in path.size():
		var q: Vector2 = path[k]
		if k + 1 < path.size() and (at - q).dot(path[k + 1] - q) > 0.0:
			continue
		if q.distance_to(at) < 0.01:
			continue
		var run := at.distance_to(q)
		if run >= left:
			at = at.move_toward(q, left)
			left = 0.0
			break
		at = q
		left -= run
	p.ground_pos = at


## The walk with real bodies (review of Task 8, I1; review-t7 I1(d)): all four processions form up and are walked to the pyre by their pace, the director
## looking every 0.25 s, and the nearest two fit escorts of a procession are measured at every look. Pinned: at most 3% of looks under two Silent Doom radii
## (one cast takes two), nothing under 1.0; nobody is freed or disabled by the walk alone (all three able at every look); and the first fire comes at least
## 45 s after the countdown first shows (the instant loss is warned with room to act).
static func _body_walk(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var crowd: Crowd = s.crowd
	_form_all(d)
	var clock := 0.0
	var looks := 0
	var under := 0
	var low := INF
	var min_able := 3
	var burn_at := -1.0
	while clock < 100.0 and d.lost_reason() == "":
		Kit.run_for(s, EscortDirector.TICK)
		clock += EscortDirector.TICK
		if burn_at < 0.0 and (s.banners as Array).any(func(b: Variant) -> bool: return String(b).begins_with("A BELIEVER BURNS")):
			burn_at = clock
		for i in 4:
			var pr: FaceHalcyonDirector.Procession = d.procs[i]
			if not pr.phase in [FaceHalcyonDirector.Procession.Phase.FORMING, FaceHalcyonDirector.Procession.Phase.MARCHING, FaceHalcyonDirector.Procession.Phase.BURNING]:
				continue
			_walk_body(crowd, pr.charge.man as Person, EscortDirector.TICK)
			var near := INF
			var fit: Array[Person] = []
			for k in pr.escorts.size():
				if MissionDirector._alive(pr.escorts[k]):
					_walk_body(crowd, pr.escorts[k] as Person, EscortDirector.TICK)
				if d._fit(pr, k):
					fit.append(pr.escorts[k] as Person)
			for a in fit.size():
				for b in range(a + 1, fit.size()):
					near = minf(near, fit[a].ground_pos.distance_to(fit[b].ground_pos))
			min_able = mini(min_able, d.able_escort(i))
			if near < INF:
				looks += 1
				low = minf(low, near)
				under += 1 if near < 2.0 * SilentDoom.RADIUS else 0
	t.check(looks > 500 and under * 100 <= looks * 3 and low >= 1.0,
		"walked by their pace along all four roads, the nearest two escorts of a procession are under 1.6 apart at %d of %d looks (%.1f%%) and never under 1.0 (nearest %.2f)" % [under, looks, 100.0 * float(under) / float(maxi(looks, 1)), low])
	t.check(min_able == 3 and d.out_count() == 0, "and the walk alone disables nobody and frees nobody (fewest able %d, freed %d)" % [min_able, d.out_count()])
	t.check(burn_at >= 45.0 and d.burned() >= 1, "the first fire comes %.1f s after the countdowns first showed (at least 45 s)" % burn_at)
	t.check(d.pair_looks > 0 and d.walk_looks > 0 and d.walk_min >= 1.0 and d.pair_min >= 1.0 and d.walk_under * 100 <= d.walk_looks * 3,
		"the director's own figures agree: walking %.2f/%d/%d, stopped %.2f/%d/%d (min / under 1.6 / looks)" % [d.walk_min, d.walk_under, d.walk_looks, d.pair_min, d.pair_under, d.pair_looks])
	Kit.done(s)


static func _nearest_walkable(s: Dictionary, at: Vector2) -> Vector2:
	var w: Vector2 = (s.crowd as Crowd)._grid.nearest_walkable(at)
	return w if w != Vector2.INF else at


## One escort off DUTY or dead does not free him: the Escort type's single-seizer release is not this Hunt's.
static func _one_seizer_not_free(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + LOOK)
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	var p := _believer(d, 0)
	(pr.escorts[0] as Person).mind = Person.Mind.POST  # off DUTY, as the Escort type's seizer sent off his errand
	Kit.free_body(s, pr.escorts[1] as Person)
	_look(s, 2)
	t.check(pr.phase == FaceHalcyonDirector.Procession.Phase.MARCHING and not d.charges[0].escaped and d.out_count() == 0 and not (s.banners as Array).any(func(b: Variant) -> bool: return String(b).contains("FREE"))
		and d.able_escort(0) == 2 and p.anchor.distance_to(d.pyre_at) < 0.6,
		"one escort off duty and another dead: he is still marched (2 able of 3), not freed, no release banner (%s)" % [s.banners])
	Kit.done(s)


## The ways to break an escort (MS §6): afraid, compelled by CALL THE GUARD, confused, whispered, frail, dead, indoors, far from him, bound by a law,
## out of the walls. Two disabled free him at once; one never does.
static func _free_break(t) -> void:
	var kinds := ["afraid", "compelled", "confused", "whispered", "frail", "dead", "inside", "far", "bars", "outside"]
	var made := 0
	var failed := PackedStringArray()
	for start in range(0, kinds.size(), 3):  # (three freed win the night: a fourth would never be looked at)
		var s := _world()
		var d: FaceHalcyonDirector = s.d
		_form_all(d)
		var group := kinds.slice(start, mini(start + 3, kinds.size()))
		for i in group.size():
			var pr: FaceHalcyonDirector.Procession = d.procs[i]
			_disable(String(group[i]), pr.escorts[0] as Person, s)
		Kit.run_for(s, FaceHalcyonDirector.FH_GRACE + 1.0)  # (an escort left apart is able for FH_GRACE seconds)
		for i in group.size():
			var pr: FaceHalcyonDirector.Procession = d.procs[i]
			var one_ok := pr.phase == FaceHalcyonDirector.Procession.Phase.FORMING and d.able_escort(i) == 2 and not d.charges[i].escaped
			if not one_ok:
				failed.append("%s alone (%s, %d able)" % [group[i], pr.phase, d.able_escort(i)])
		for i in group.size():
			_disable(String(group[i]), (d.procs[i] as FaceHalcyonDirector.Procession).escorts[1] as Person, s)
		var banners_before := (s.banners as Array).size()
		Kit.run_for(s, FaceHalcyonDirector.FH_GRACE + 1.0)
		for i in group.size():
			var pr: FaceHalcyonDirector.Procession = d.procs[i]
			var p := d.charges[i].man as Person
			var ok := pr.phase == FaceHalcyonDirector.Procession.Phase.FREED and d.charges[i].escaped and pr.freed_by == "broken" and not d.charges[i].held \
				and d.leaving.has(p) and p.pace >= 1.0 and d.able_escort(i) < 2
			made += 1 if ok else 0
			if not ok:
				failed.append("%s pair (%s, escaped %s, leaving %s)" % [group[i], pr.phase, d.charges[i].escaped, d.leaving.has(p)])
		var freed_banners := (s.banners as Array).slice(banners_before).filter(func(b: Variant) -> bool: return String(b).begins_with("A BELIEVER IS FREED  "))
		t.check(freed_banners.size() == group.size(), "each is bannered, once (%s)" % [freed_banners])
		Kit.done(s)
	t.check(made == kinds.size() and failed.is_empty(), "every way to break an escort frees the believer at once with two disabled, never with one (%d of %d; %s)" % [made, kinds.size(), failed])
	# The first banner reads A BELIEVER IS FREED  1/3 exactly.
	var n := _world()
	var e: FaceHalcyonDirector = n.d
	e._come_out(0)
	_disable("dead", e.procs[0].escorts[0] as Person, n)
	_disable("afraid", e.procs[0].escorts[1] as Person, n)
	_look(n)
	t.check((n.banners as Array).has("A BELIEVER IS FREED  1/3") and e.out_count() == 1 and e.freed() == 1 and e.freed_broken == 1,
		"A BELIEVER IS FREED  1/3 (%s)" % [n.banners])
	# Freed in the next look is not freed twice, and his escort goes back to its post.
	_look(n, 2)
	var back := 0
	for v: Variant in e.procs[0].escorts:
		if MissionDirector._alive(v):
			back += 1 if (v as Person).mind != Person.Mind.DUTY else 0
	t.check(e.out_count() == 1 and back >= 1, "freed once; his able escort goes back to his post (%d)" % back)
	Kit.done(n)


## Disables escort `e` the way `kind` says.
static func _disable(kind: String, e: Person, s: Dictionary) -> void:
	match kind:
		"afraid":
			e.mind = Person.Mind.PANIC
		"compelled":
			e.compel(e.ground_pos, 20.0, Person.WILL_FIRM, Color.WHITE, false)
		"confused":
			e.confuse(10.0)
		"whispered":
			e.whisper(e.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
		"frail":
			e.statuses[&"frail"] = 1.0
		"dead":
			Kit.free_body(s, e)
		"inside":
			e.inside = true
		"far":
			Kit.arrive(e, e.ground_pos + Vector2(4.0, 4.0))
		"bars":
			e.badge_glyph = DecreeParts.BARS
			e.badge_left = 5.0
		"outside":
			Kit.arrive(e, Vector2(30.0, 0.0))


## The real CALL THE GUARD (Decree's Bell Lies) clicked on the procession itself: the call takes the soldiers nearest the click, so his escorts are held;
## clicked well away, it draws other soldiers first and the procession is left whole.
static func _call_on_procession(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	_form_all(d)
	_look(s)
	# Called far from procession 1 (at the first procession's door): the nearest soldiers there are procession 0's.
	var elsewhere: Vector2 = (d.households[0] as ExodusDirector.Household).door
	var wrong: BellLiesFx = FxTimeline.cast(load("res://src/fx/decree/the_bell_lies.gd"), ctx, elsewhere, {"mode": "guard"})
	wrong._process(BellLiesFx.T_CAST + 0.05)
	_look(s)
	t.check(d.procs[1].phase == FaceHalcyonDirector.Procession.Phase.FORMING and d.able_escort(1) == 3 and d.procs[2].phase == FaceHalcyonDirector.Procession.Phase.FORMING
		and d.procs[0].phase == FaceHalcyonDirector.Procession.Phase.FREED,
		"a call at the first door held the first procession's escorts (freed), not the others' (%s %s)" % [d.procs[1].phase, d.able_escort(1)])
	wrong._process(BellLiesFx.GUARD_TIME + 3.0)
	wrong.free()
	for sdr in (s.crowd as Crowd).soldiers:
		sdr.release_compulsion()
	# Called on the second procession: his escorts are compelled (held by the god, not able) and he is free at once.
	var at := _believer(d, 1).ground_pos
	var call: BellLiesFx = FxTimeline.cast(load("res://src/fx/decree/the_bell_lies.gd"), ctx, at, {"mode": "guard"})
	call._process(BellLiesFx.T_CAST + 0.05)
	var held := 0
	for v: Variant in d.procs[1].escorts:
		held += 1 if (v as Person).held_by_god() and (v as Person).mind == Person.Mind.COMPELLED else 0
	t.check(held == 3 and d.able_escort(1) == 0, "CALL THE GUARD clicked on the procession compels its three escorts (%d held, %d able)" % [held, d.able_escort(1)])
	_look(s)
	t.check(d.procs[1].phase == FaceHalcyonDirector.Procession.Phase.FREED and d.charges[1].escaped and (s.banners as Array).has("A BELIEVER IS FREED  2/3"),
		"and the believer is free at once (%s)" % [s.banners])
	call._process(BellLiesFx.GUARD_TIME + 3.0)
	call.free()
	ctx.overhead.free()
	ctx.ground.free()
	Kit.done(s)


static func _out_of_walls(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	_form_all(d)
	_look(s)
	# An escort set down out of the walls is sent off the map; one escort lost leaves him held.
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	var gone := pr.escorts[0] as Person
	Kit.arrive(gone, Vector2(30.0, 0.0))
	_look(s)
	t.check(d.leaving.has(gone) and d.able_escort(0) == 2 and pr.phase == FaceHalcyonDirector.Procession.Phase.FORMING and d.out_count() == 0,
		"an escort out of the walls is sent off; the believer is held by the other two")
	# A believer set down out of the walls (a Mirrorfold's forest) is freed: counted, sent off, his escort released.
	var p := _believer(d, 1)
	Kit.arrive(p, Vector2(0.0, 22.0))
	_look(s)
	var q: FaceHalcyonDirector.Procession = d.procs[1]
	t.check(q.phase == FaceHalcyonDirector.Procession.Phase.FREED and q.freed_by == "walls" and d.charges[1].escaped and d.leaving.has(p) and d.freed_walls == 1
		and (s.banners as Array).has("A BELIEVER IS FREED  1/3"),
		"a believer set down out of the walls is freed too: counted, sent off the map, the banner says 1/3 (%s)" % [s.banners])
	var released := true
	for v: Variant in q.escorts:
		released = released and (v as Person).mind != Person.Mind.DUTY
	t.check(released, "and his escort is released from the errand")
	# The whole procession folded out past the wall: freed, the escort sent off.
	var r := d.procs[2]
	for v: Variant in r.escorts:
		Kit.arrive(v as Person, Vector2(-30.0, 3.0))
	Kit.arrive(_believer(d, 2), Vector2(-29.0, 3.0))
	_look(s, 2)
	var all_off := true
	for v: Variant in r.escorts:
		all_off = all_off and d.leaving.has(v)
	t.check(r.phase == FaceHalcyonDirector.Procession.Phase.FREED and all_off and d.out_count() == 2, "a procession folded out past the wall: he is free, his escort sent off")
	Kit.done(s)


# --- The burning ---

static func _burn(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + LOOK)
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	var p := _believer(d, 0)
	_stand(d, 0, d.pyre_at + Vector2(0.0, 1.0))
	_look(s)
	t.check(pr.phase == FaceHalcyonDirector.Procession.Phase.BURNING and absf(d.burn_left(0) - FaceHalcyonDirector.FH_BURN) < 0.7 and d.hint_phase() == "pyre",
		"within the pyre's reach he is bound to the stake: %.1f s to burn, the hint turns to the pyre" % d.burn_left(0))
	var tags := d.tags()
	var burning: MapTag = null
	for m in tags:
		if m.label.begins_with("BURNING "):
			burning = m
	t.check(burning != null and burning.edge and burning.ring >= 0.0 and burning.label == "BURNING 0:12" and _labels(d).has("BELIEVER - DO NOT KILL"),
		"the pyre's tag reads BURNING 0:12 with a ring, the believer's reads BELIEVER - DO NOT KILL (%s)" % [_labels(d)])
	Kit.run_for(s, 6.0)
	_stand(d, 0, d.pyre_at + Vector2(0.0, 1.0))
	var ring_then := 0.0
	for m in d.tags():
		if m.label.begins_with("BURNING "):
			ring_then = m.ring
	t.check(ring_then > 0.3 and ring_then < 0.7 and d.burn_left(0) < 7.0 and d.burn_left(0) > 5.0, "the ring fills as the fire takes hold (%.2f, %.1f s left)" % [ring_then, d.burn_left(0)])
	var rows := d.strip_rows()
	t.check(rows.size() == 1 and rows[0].label == "The fire takes a believer" and absf(float(rows[0]["in"]) - d.burn_left(0)) < 0.01, "the strip counts the fire down (%s)" % [rows])
	# Left alone, he burns: taken, hidden, banner, escort released, one more and the Hunt is lost.
	Kit.run_for(s, 6.2)
	_stand(d, 0, d.pyre_at + Vector2(0.0, 1.0))
	_look(s)
	t.check(pr.phase == FaceHalcyonDirector.Procession.Phase.BURNED and d.charges[0].taken and d.burned() == 1 and p.inside and d.lost_reason() == "" and d.out_count() == 0
		and (s.banners as Array).has("A BELIEVER BURNS - ONE MORE AND THE HUNT IS LOST"),
		"left alone, the fire takes him: burned 1, the banner warns, the night goes on (%s)" % [s.banners])
	var released := true
	for v: Variant in pr.escorts:
		released = released and (v as Person).mind != Person.Mind.DUTY
	t.check(released, "and his escort goes back to its posts")
	Kit.done(s)
	# Freed while he burns: the break works until the fire ends.
	var n := _world()
	var e: FaceHalcyonDirector = n.d
	e._come_out(0)
	Kit.run_for(n, FaceHalcyonDirector.FH_FORM + LOOK)
	_stand(e, 0, e.pyre_at + Vector2(0.0, 1.0))
	_look(n)
	Kit.run_for(n, 10.0)
	_stand(e, 0, e.pyre_at + Vector2(0.0, 1.0))
	_look(n)
	t.check(e.procs[0].phase == FaceHalcyonDirector.Procession.Phase.BURNING and e.burn_left(0) < 2.0, "two seconds from the end he is still on the stake (%.1f)" % e.burn_left(0))
	_disable("frail", e.procs[0].escorts[0] as Person, n)
	_disable("afraid", e.procs[0].escorts[1] as Person, n)
	_look(n)
	t.check(e.procs[0].phase == FaceHalcyonDirector.Procession.Phase.FREED and e.burned() == 0 and e.out_count() == 1,
		"two escorts broken with two seconds to go: freed from the stake, not burned (freed %d burned %d)" % [e.out_count(), e.burned()])
	Kit.done(n)


static func _god_kill(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	_form_all(d)
	_look(s)
	var p0 := _believer(d, 0)
	Kit.free_body(s, p0)
	_look(s)
	t.check(d.procs[0].phase == FaceHalcyonDirector.Procession.Phase.DEAD and d.burned() == 1 and d.lost_reason() == ""
		and (s.banners as Array).has("A BELIEVER IS KILLED - ONE MORE AND THE HUNT IS LOST"),
		"a believer the god kills counts as burned: one, the banner warns (%s)" % [s.banners])
	var released := true
	for v: Variant in d.procs[0].escorts:
		released = released and (v as Person).mind != Person.Mind.DUTY
	t.check(released, "and his escort is released")
	Kit.free_body(s, _believer(d, 1))
	_look(s)
	t.check(d.burned() == 2 and d.lost_reason() == "burned", "a second killed is two burned: lost (burned %d)" % d.burned())
	Kit.done(s)


static func _lose_two(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var rules: Rules = s.rules
	d.charges[0].taken = true
	var main := rules.objectives[0] as EscortObjective
	t.check(d.burned() == 1 and d.lost_reason() == "" and main.check(rules) == Objective.Status.PENDING and not d.tags().is_empty(), "one burned: not lost yet")
	d.charges[1].taken = true
	t.check(d.burned() == 2 and d.lost_reason() == "burned", "two burned: burned (%d)" % d.burned())
	t.check(main.check(rules) == Objective.Status.FAILED and main.reason == "burned" and d.tags().is_empty() and d.hint_phase() == "" and d.strip_rows().is_empty(),
		"the objective fails with that reason; nothing is tagged")
	t.check(d.hud_line() == "Free the believers 0 / 3, 2 burned", "the HUD line (%s)" % d.hud_line())
	Kit.done(s)
	# Three freed win whatever else happens to the fourth.
	var n := _world()
	var e: FaceHalcyonDirector = n.d
	for k in 3:
		e.charges[k].escaped = true
	e.charges[3].taken = true
	var win := n.rules.objectives[0] as EscortObjective
	t.check(e.out_count() == 3 and win.check(n.rules) == Objective.Status.DONE and win.reason == "freed" and e.lost_reason() == "", "three freed win (%d)" % e.out_count())
	Kit.done(n)


# --- The Gaze ---

static func _gaze(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var rules: Rules = s.rules
	var gate := rules.objectives[1] as GazeObjective
	t.check(d.gaze != null and d.gaze.value == 0.0 and gate is GazeObjective and gate.check(rules) == Objective.Status.PENDING and gate.hud_text(rules) == "Halcyon's Gaze 0%",
		"the director keeps the Gaze at nought and the objective is pending (%s)" % gate.hud_text(rules))
	_form_all(d)
	_look(s)
	# An escort killed with the believer and his mates beside him is a seen death: +10 (the base's Gaze).
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	Kit.free_body(s, pr.escorts[0] as Person)
	_look(s, 2)
	t.check(is_equal_approx(d.gaze.value, GazeMeter.SEEN_DEATH), "a seen death adds %d to the Gaze (%.0f)" % [roundi(GazeMeter.SEEN_DEATH), d.gaze.value])
	# The toll adds 40 (LanternWatch): the Gaze is a bar on the HUD, and the hint turns to it at FH_GAZE_HINT.
	d.gaze.add(LanternWatch.GAZE_TOLL)
	t.check(is_equal_approx(d.gaze.value, 50.0) and d.hint_phase() == "gaze" and gate.check(rules) == Objective.Status.PENDING and gate.hud_text(rules) == "Halcyon's Gaze 50%",
		"the toll's 40 on top: 50%%, the hint turns to the Gaze (%s)" % d.hint_phase())
	d.gaze.add(50.0)
	t.check(d.gaze.is_full() and gate.check(rules) == Objective.Status.FAILED and gate.reason == "gaze", "the Gaze full fails the night with reason gaze")
	Kit.done(s)


static func _win_beats_gaze(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var rules: Rules = s.rules
	for k in 3:
		d.charges[k].escaped = true
	d.gaze.fill()
	var main := rules.objectives[0] as EscortObjective
	var gate := rules.objectives[1] as GazeObjective
	t.check(main.check(rules) == Objective.Status.DONE and gate.check(rules) == Objective.Status.FAILED and rules.objectives[0] == main,
		"the third freed wins while the Gaze is full: the Escort objective is listed and checked first (win first)")
	t.check(d.tags().is_empty() and d.hint_phase() == "", "a won night tags nothing")
	Kit.done(s)


# --- The strip ---

static func _strip_rows(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	t.check(d.strip_rows().is_empty(), "no row before a procession forms up")
	d._come_out(0)
	var rows := d.strip_rows()
	var names := []
	for r: Dictionary in rows:
		names.append(r.label)
	t.check(names == ["A believer reaches the pyre"] and not names.has("The Temple sends searchers") and float(rows[0]["in"]) > FaceHalcyonDirector.FH_FORM,
		"the strip: A believer reaches the pyre, the forming and the walk counted (%s)" % [rows])
	Kit.run_for(s, 0.5)
	var rows2 := d.strip_rows()
	t.check(float(rows2[0]["in"]) < float(rows[0]["in"]) - 0.3, "and it counts down between looks (%.2f then %.2f)" % [float(rows[0]["in"]), float(rows2[0]["in"])])
	var up := []
	for e in d.timeline.upcoming(5):
		up.append(e.id)
	t.check(not up.has("hunt_0") and not up.has("hunt_1"), "the timeline lists no searchers (%s)" % [up])
	var tags := _labels(d)
	var leader := tags.filter(func(l: Variant) -> bool: return String(l).begins_with("PYRE IN "))
	var escorts := tags.filter(func(l: Variant) -> bool: return String(l) == "ESCORT")
	t.check(leader.size() == 2 and escorts.size() == 3 and Kit.edged(d, String(leader[0])) and Kit.edged(d, "ESCORT"),
		"the leader's believer and the pyre read PYRE IN <seconds>; each escort is tagged ESCORT, pointed at (%s)" % [tags])
	var believers := tags.filter(func(l: Variant) -> bool: return String(l).ends_with("DO NOT KILL"))
	t.check(believers.size() == 1 and String(believers[0]).begins_with("PYRE IN "), "his tag carries DO NOT KILL from the start (%s)" % [believers])
	Kit.done(s)


## The instant loss is warned with room to act (review of wave 1, point b): from the moment a procession forms up the pyre's tag counts down to the fire,
## and the burn that would be the second is at least 45 s away from the first look at it; and the fire itself shows 12 s.
static func _warning_window(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var worst := INF
	var firsts := PackedStringArray()
	for i in 4:
		var h: ExodusDirector.Household = d.households[i]
		d._come_out(i)
		var shown := -1.0
		for m in d.tags():
			if m.label.begins_with("PYRE IN "):
				var parts := m.label.trim_prefix("PYRE IN ").split(":")
				shown = float(parts[0]) * 60.0 + float(parts[1])
		var window := shown + FaceHalcyonDirector.FH_BURN
		worst = minf(worst, window)
		firsts.append("%.0f" % window)
		d.procs[i].phase = FaceHalcyonDirector.Procession.Phase.FREED  # (set aside, so the next procession is the leader in turn)
	t.check(worst >= 45.0, "each procession's pyre countdown first shows at least 45 s before its fire could take him (windows %s s)" % [", ".join(firsts)])
	Kit.done(s)


## Two processions never stand at one stake: a second arriving while a believer burns waits short of the pyre.
static func _one_stake(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	d._come_out(1)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + LOOK)
	_stand(d, 0, d.pyre_at + Vector2(0.0, 1.0))
	_look(s)
	t.check(d.procs[0].phase == FaceHalcyonDirector.Procession.Phase.BURNING, "the first is bound to the stake")
	var spot := d.pyre_at + Vector2(0.0, FaceHalcyonDirector.FH_QUEUE - 1.0)
	_stand(d, 1, spot)
	_look(s)
	var q := _believer(d, 1)
	t.check(d.procs[1].phase == FaceHalcyonDirector.Procession.Phase.MARCHING and q.anchor.distance_to(spot) < 0.6,
		"a second arriving within %.0f of the pyre while one burns stands where it is" % FaceHalcyonDirector.FH_QUEUE)
	# Freed, the stake is free and he goes on.
	_disable("frail", d.procs[0].escorts[0] as Person, s)
	_disable("afraid", d.procs[0].escorts[1] as Person, s)
	_look(s, 2)
	_stand(d, 1, spot)
	_look(s)
	t.check(d.procs[0].phase == FaceHalcyonDirector.Procession.Phase.FREED and q.anchor.distance_to(d.pyre_at) < 0.6, "the stake free again, he walks on to it (%s)" % q.anchor)
	Kit.done(s)


## An escort straggling more than FH_LAG from his place holds the march for a moment (no luck at a street corner), at most FH_STRAGGLE seconds in all.
static func _straggler(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + LOOK)
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	var p := _believer(d, 0)
	var door := (d.households[0] as ExodusDirector.Household).door
	_stand(d, 0, door)
	var behind := pr.escorts[0] as Person
	Kit.arrive(behind, pr.places[0] + Vector2(FaceHalcyonDirector.FH_LAG + 0.3, 0.0))  # straggling, though not disabled
	_look(s)
	t.check(p.anchor.distance_to(door) < 0.6 and pr.stall > 0.0 and pr.phase == FaceHalcyonDirector.Procession.Phase.MARCHING,
		"an escort straggling holds the march a moment (stalled %.2f s)" % pr.stall)
	Kit.run_for(s, FaceHalcyonDirector.FH_STRAGGLE + 1.0)
	t.check(p.anchor.distance_to(d.pyre_at) < 0.6 or pr.phase == FaceHalcyonDirector.Procession.Phase.FREED,
		"and no more than %.0f s: a stuck escort cannot hold the march for good (%s)" % [FaceHalcyonDirector.FH_STRAGGLE, pr.phase])
	Kit.done(s)


static func _busy(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	var all_busy := true
	for i in 4:
		all_busy = all_busy and d.busy(_believer(d, i))
		for v: Variant in d.procs[i].escorts:
			all_busy = all_busy and d.busy(v as Person)
	var stranger: Person = null
	for p in (s.crowd as Crowd).soldiers:
		if is_instance_valid(p) and not d._in_use(null).has(p):
			stranger = p
			break
	t.check(all_busy and stranger != null and not d.busy(stranger), "the Lantern's Bearer may not take a believer or an escort; a town soldier is free")
	# No luck: a town soldier or watchman beside a believer neither seizes nor frees him.
	d._come_out(0)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + LOOK)
	var p0 := _believer(d, 0)
	Kit.arrive(stranger, p0.ground_pos + Vector2(0.9, 0.0))
	stranger.send_to_post(stranger.ground_pos)
	_look(s, 3)
	t.check(d.procs[0].phase == FaceHalcyonDirector.Procession.Phase.MARCHING and d.seizures == 0 and d.out_count() == 0 and d.able_escort(0) == 3 and d.charges[0].held,
		"a town soldier beside a believer seizes no one and changes nothing (%d seizures, %d able)" % [d.seizures, d.able_escort(0)])
	Kit.done(s)


static func _evacuation(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	Kit.run_for(s, 1.0)
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	var recovering := pr.escorts[0] as Person
	recovering._recover(1.0)
	Kit.evacuate(s)
	_look(s)
	var none_fled := true
	for c in d.charges:
		none_fled = none_fled and (c.man as Person).mind != Person.Mind.FLEE
	for list: Array in d.escort_lists:
		for v: Variant in list:
			none_fled = none_fled and (v as Person).mind != Person.Mind.FLEE
	t.check(none_fled and recovering.mind == Person.Mind.DUTY and _believer(d, 0).mind == Person.Mind.DUTY,
		"the evacuation: no believer or escort flees, the recovering escort goes back to work at once (%s)" % [recovering.mind])
	var inside := true
	for i in range(1, 4):
		inside = inside and _believer(d, i).inside
		for v: Variant in d.procs[i].escorts:
			inside = inside and (v as Person).inside
	t.check(inside, "the processions still in their houses stay inside")
	Kit.done(s)


## The ESCORT tag counts what the rule counts (review of Task 8, R1): an escort apart from the procession past the grace loses his tag as he stops being able,
## and with another disabled the believer is freed.
static func _tag_matches_rule(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + LOOK)
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	var tags := _labels(d).filter(func(l: Variant) -> bool: return String(l) == "ESCORT")
	t.check(tags.size() == 3, "three escorts, three ESCORT tags (%d)" % tags.size())
	Kit.arrive(pr.escorts[0] as Person, Vector2(-7.0, -7.0))  # far from him and from his place, not disabled by the god
	Kit.run_for(s, 1.0)
	var inside_grace := _labels(d).filter(func(l: Variant) -> bool: return String(l) == "ESCORT").size()
	Kit.run_for(s, FaceHalcyonDirector.FH_GRACE + 0.5)
	var after := _labels(d).filter(func(l: Variant) -> bool: return String(l) == "ESCORT").size()
	t.check(inside_grace == 3 and after == 2 and d.able_escort(0) == 2 and pr.phase == FaceHalcyonDirector.Procession.Phase.MARCHING,
		"cut off beyond both measures: still tagged inside the grace (%d), untagged and unable after it (%d), the believer not yet freed" % [inside_grace, after])
	_disable("frail", pr.escorts[1] as Person, s)
	_look(s)
	t.check(pr.phase == FaceHalcyonDirector.Procession.Phase.FREED and d.out_count() == 1, "and with another disabled he is freed")
	Kit.done(s)


## report() keeps the base's keys and adds the Hunt's; the HUD line counts freed and burned on a night that is not lost.
static func _report(t) -> void:
	var s := _world()
	var d: FaceHalcyonDirector = s.d
	d.charges[0].escaped = true
	d.charges[1].taken = true
	var r := d.report()
	t.check(r.has("out") and r.has("taken") and r.has("seizures") and r.has("reliefs") and r.has("gaze") and int(r.freed) == 1 and int(r.burned) == 1
		and int(r.freed_broken) == 0 and int(r.freed_walls) == 0, "report(): the base's keys and freed / burned / freed_broken / freed_walls (%s)" % [r])
	t.check(d.hud_line() == "Free the believers 1 / 3, 1 burned" and d.lost_reason() == "", "the HUD line on a night still on (%s)" % d.hud_line())
	Kit.done(s)


## Task 1's wish check for this Hunt, with its director: no wish lands on the director's own people or buildings, on nights 0-3.
static func _wishes(t) -> void:
	var id := MissionBook.FACE_HALCYON
	var heard := 0
	var hit := 0
	var mine_people := 0
	for night in 4:
		var def := HuntBook.def(id)
		var descent := Descent.new().setup(def, Descent.seed_for(night, id))
		var n := Kit.world(HuntBook.def(id), null, func(d: MissionDirector, rules: Rules) -> void: descent.reserve(rules, d))
		var mine: Dictionary = Book._own(n.d)
		mine_people += (mine.people as Array).size()
		for w in descent.wishes:
			heard += 1
			for p in w.people():
				hit += 1 if (mine.people as Array).has(p) else 0
			for st in w.places():
				hit += 1 if (mine.places as Array).has(st) else 0
		var d := n.d as FaceHalcyonDirector
		for h: ExodusDirector.Household in d.households:
			for c: EscortDirector.Charge in h.members:
				hit += 1 if (descent.wishes.any(func(w: Wish) -> bool: return w.people().has(c.man))) else 0
			hit += 1 if (descent.wishes.any(func(w: Wish) -> bool: return w.places().has(h.house))) else 0
		for list: Array in d.escort_lists:
			for v: Variant in list:
				hit += 1 if (descent.wishes.any(func(w: Wish) -> bool: return w.people().has(v))) else 0
		descent.release()
		Kit.done(n)
	t.check(heard > 0 and hit == 0 and mine_people >= 16, "face_halcyon: wishes heard (%d), none on the director's own people or buildings (%d); %d of its people found" % [heard, hit, mine_people])
