extends RefCounted
## God P5 Task 7 (plan Task 7, MS §5, Rulings C4, C9): Hunt 4, Break the hunt (BreakHuntDirector, a HuntDirector with no head and no Structure):
## four standards, each a bearer between two escorts, march on three of the god's believers' houses; a bearer killed or frightened with no escort
## by him breaks the standard, with one by him that escort takes it up; two taken houses lose. Tested in the Hunt's world (people do not walk in
## it: a test places a walker with Kit.arrive()): the frame, the setup, the chain, the raise (never a break on a null Structure), the march and
## the escorts' places at every stop, the break, the take-up, the walls, a house taken, two taken, the win before the loss, the warning window,
## the Lantern, a freed body, the tags, the camera, the town's flight and a clean teardown. Every test builds and frees its own world.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05
const LOOK := HuntDirector.TICK + DT


static func run(t) -> void:
	_frame(t)
	_setup(t)
	_chain(t)
	_raise_not_broken(t)
	_pace_and_window(t)
	_reaim_pace(t)
	_resume_march(t)
	_reaim_walk(t)
	_whisper_walk(t)
	_planted_bodies(t)
	_escorts_follow(t)
	_walk_model(t)
	_street_clear(t)
	_fallen_not_replaced(t)
	_break_unguarded(t)
	_guard_rules(t)
	_take_up(t)
	_out_of_walls(t)
	_taken(t)
	_lose_two(t)
	_win_beats_loss(t)
	_near_warning(t)
	_lantern(t)
	_lost_body(t)
	_tags(t)
	_camera(t)
	_hold(t)
	_evacuation(t)
	_teardown_clean(t)
	_wishes(t)
	_policies_written(t)
	_policies_play(t)
	_aim_teeth(t)


## The Hunt's world: its town, Rules and director, with the watch Lantern the game gives the night.
static func _world() -> Dictionary:
	var s := Kit.world(MissionBook.break_hunt())
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_WATCH)
	(s.rules as Rules).lantern = lw
	return s


static func _bh(s: Dictionary) -> BreakHuntDirector:
	return s.d as BreakHuntDirector


## Step `i`'s two escorts, as people (a freed or dead one stays in the list).
static func _escorts(d: BreakHuntDirector, i: int) -> Array:
	var out := []
	for g: HuntDirector.Guard in d.steps[i].party:
		out.append(g.man)
	return out


## Everyone at the hunt's work told there is nothing to fear (Person.fearless_left): a death beside them frightens no one, as a quiet kill
## does. A loud one scatters the company -- every one of them shelters or runs, which is a fright -- and a standard left so breaks within two
## looks (MS §5: "A fright counts whoever set it going"; the first look judges the bearer as he stood, R8). The tests that need a calm company
## through several looks say so here.
static func _steady(d: BreakHuntDirector) -> void:
	for v: Variant in d.crew:
		if MissionDirector._alive(v):
			(v as Person).fearless_left = 600.0


## `p` killed where he stands.
static func _kill(s: Dictionary, p: Person) -> void:
	(s.crowd as Crowd)._field.kill(p, &"doom")


## Standard `i` raised now and a look past it.
static func _raise(s: Dictionary, i: int) -> void:
	_bh(s)._raise(i)
	Kit.run_for(s, LOOK)


## Standard `i` is raised, its bearer put down at `at`, and a look taken.
static func _march_to(s: Dictionary, i: int, at: Vector2) -> void:
	var d := _bh(s)
	Kit.arrive(d.bearer(i), at)
	Kit.run_for(s, LOOK)


## The waypoints of the street from standard `i`'s muster to its house's door (the walk a bearer makes).
static func _road(d: BreakHuntDirector, i: int) -> PackedVector2Array:
	return d.crowd._grid.path(d.steps[i].spot, d.house_doors[d._dest[i]])


static func _frame(t) -> void:
	var m := MissionBook.break_hunt()
	t.check(m.director == BreakHuntDirector and m.lantern == LanternWatch.KIND_WATCH and m.tier == 4 and m.make_director() is BreakHuntDirector,
		"the frame builds the Hunt's director, a Tier 4 night with the watch Lantern")
	var objectives: Array = m.make_objectives.call()
	t.check(objectives.size() == 2 and objectives[0] is HuntObjective and objectives[0].label == "Break the hunt" and objectives[0].reason == "standards"
		and objectives[1] is ClockObjective, "the Hunt objective runs ahead of the dawn: the winning strike never also loses")
	t.check(m.goal == "Break the four standards before they take two of your believers' houses" and m.goal_label == "The hunt is broken"
		and m.lose == "Two believers' houses are taken, or dawn comes", "the goal, label and lose are the spec's")
	t.check(MissionHints.line("break_hunt") == "Standards (gold) march on your believers' houses (blue). Strike a bearer when no escort (red) stands by him."
		and MissionHints.line("break_hunt", "carried") == "An escort took up the standard: strike him too."
		and MissionHints.line("break_hunt", "taken") == "A house is taken: one more and the hunt has won.", "the three hints")
	t.check(m.camera_at == BreakHuntDirector.BH_CAMERA_AT and m.intro_from == m.camera_at + Vector2(0.0, 6.0), "the camera is the director's")
	# C2: no parent const name is redeclared (a parse error otherwise); the Hunt's numbers carry its prefix.
	var own := (BreakHuntDirector as GDScript).get_script_constant_map()
	var prefixed := true
	for k: String in own.keys():
		prefixed = prefixed and k.begins_with("BH_")
	t.check(prefixed, "every const of the Hunt carries the BH_ prefix (C2)")


static func _setup(t) -> void:
	var s := _world()
	var d := _bh(s)
	var rules: Rules = s.rules
	t.check(d.steps.size() == 4 and not d.has_head and d.head_down() and d.chain == BreakHuntDirector.BH_CHAIN and d.guard_reach == BreakHuntDirector.BH_GUARD_REACH
		and d.lost_word == "houses", "four steps, no head, the chain and the reach, the loss word 'houses'")
	t.check((s.banners as Array).has("BREAK THE HUNT"), "the opening banner (%s)" % [s.banners])
	t.check(d.houses.size() == 3 and d.house_doors.size() == 3 and d.taken() == 0, "three believers' houses, none taken")
	var stone := true
	var distinct := true
	for h in d.houses.size():
		stone = stone and d.houses[h].damage_filter == d._stone and not d.reserved_places.has(d.houses[h])
		for k in range(h + 1, d.houses.size()):
			distinct = distinct and d.houses[h] != d.houses[k] and d.house_doors[h].distance_to(d.house_doors[k]) > 2.0
	t.check(stone and distinct, "the houses are stone tonight, different, their doors apart")
	var everyone: Array = []
	var posts_ok := true
	var reach_ok := true
	for i in 4:
		var b := d.bearer(i)
		t.check(b != null and not b.inside and b.mind == Person.Mind.DUTY and b.ground_pos.distance_to(d.steps[i].spot) < 0.5, "bearer %d stands at his muster" % i)
		var es := _escorts(d, i)
		posts_ok = posts_ok and es.size() == 2
		everyone.append(b)
		for e: Person in es:
			posts_ok = posts_ok and e != null and e.profile.role == CitizenProfile.Role.WATCHMAN and not e.inside
			reach_ok = reach_ok and e.ground_pos.distance_to(b.ground_pos) <= BreakHuntDirector.BH_GUARD_REACH
			everyone.append(e)
		t.check(d.steps[i].party_size == 2 and d.guarded(i) == false, "standard %d is not raised yet (guarded() reads only a raised one)" % i)
		t.check(d._guarded(i), "(but its two escorts guard its bearer from the start)")
		t.check(not d.reserved.has(b), "the bearer is not a wish's person")
	t.check(posts_ok, "each bearer has two escorts, lay citizens dressed as guards")
	t.check(reach_ok, "each escort stands within the guard reach of his bearer")
	var unique := true
	for i in everyone.size():
		for j in range(i + 1, everyone.size()):
			unique = unique and everyone[i] != everyone[j]
	t.check(unique and everyone.size() == 12, "twelve different people (%d)" % everyone.size())
	# Opposition stands more than two Silent Doom radii apart (MS §0): every escort from every other escort.
	var escorts: Array = []
	for i in 4:
		escorts.append_array(_escorts(d, i))
	var far := true
	var min_gap := INF
	for i in escorts.size():
		for j in range(i + 1, escorts.size()):
			var gap: float = (escorts[i] as Person).ground_pos.distance_to((escorts[j] as Person).ground_pos)
			min_gap = minf(min_gap, gap)
			far = far and gap > 2.0 * SilentDoom.RADIUS
	t.check(far, "no two escorts stand within two Silent Doom radii of each other (closest %.2f)" % min_gap)
	# The musters are on ground the street reaches from the Temple's door and lie inside the walls.
	var hub := d._walkable(d.lantern_door())
	var reached := true
	for st in d.steps:
		reached = reached and not d.crowd._grid.path(st.spot, hub).is_empty() and not Walls.outside(st.spot)
	t.check(reached, "every muster is on ground the street reaches, inside the walls")
	var labels := Kit.labels(d)
	t.check(labels.has("RAISED IN 0:20") and labels.has("RAISED IN 1:10") and labels.has("RAISED IN 2:00") and labels.has("RAISED IN 2:50"),
		"the grey countdowns of the four musters show at the start (%s)" % [labels])
	t.check(d.hint_phase() == "" and d.strip_rows().is_empty() and d.broken_count() == 0 and not d.found, "the hint is the mission's; no row; nothing broken")
	t.check(rules.objectives[0].hud_text(rules) == "Break the hunt: standards 0 / 4", "the HUD counts the four (%s)" % rules.objectives[0].hud_text(rules))
	t.check(d.tour().size() == 3 and d.report().has("taken") and d.report().has("took_up"), "a tour of three stops; the report counts the houses taken")
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d := _bh(s)
	Kit.run_for(s, 19.5)
	t.check(not d.steps[0].raised and d.bearer(0).badge_left <= 0.0, "0:19: nothing raised, no pennant yet")
	Kit.run_for(s, 1.5)
	t.check(d.steps[0].raised and not d.steps[1].raised and (s.banners as Array).has("A STANDARD MARCHES FROM THE NORTH"),
		"0:20: the north standard is raised and marches (%s)" % [s.banners])
	# Break it: the next is due at its own time or the chain after, whichever is sooner.
	for e: Person in _escorts(d, 0):
		_kill(s, e)
	_kill(s, d.bearer(0))
	Kit.run_for(s, LOOK)
	var at := d.steps[0].broken_at
	t.check(d.steps[0].broken and (s.banners as Array).has("THE STANDARD IS BROKEN  1/4"), "the first standard breaks: THE STANDARD IS BROKEN  1/4 (%s)" % [s.banners])
	t.check(d.step_due(1) <= minf(70.0, at + BreakHuntDirector.BH_CHAIN) + 0.01 and d.step_due(1) - at <= BreakHuntDirector.BH_CHAIN + 0.01,
		"the next is due within 45 s of the break, or at 1:10 (%.1f, broken %.1f)" % [d.step_due(1), at])
	t.check(d.step_due(2) == 120.0 and d.step_due(3) == 170.0, "the later ones keep their times while the one before stands")
	Kit.run_for(s, BreakHuntDirector.BH_CHAIN + 1.0)
	t.check(d.steps[1].raised and (s.banners as Array).has("A STANDARD MARCHES FROM THE WEST"), "and is raised then, before its own time")
	# No wait over 60 s: with nothing broken the four come at 0:20, 1:10, 2:00 and 2:50.
	var n := _world()
	var dn := _bh(n)
	Kit.run_for(n, 155.0)
	t.check(dn.steps[0].raised and dn.steps[1].raised and dn.steps[2].raised and not dn.steps[3].raised and dn.next_step() == 3,
		"at 2:35 with nothing broken the first three are raised and the last waits for 2:50")
	Kit.run_for(n, 20.0)
	t.check(dn.steps[3].raised, "and at 2:55 the fourth is raised")
	Kit.done(n)
	Kit.done(s)


## C4: a step is raised and not broken, with no Structure made, no damage filter set and the standards list empty.
static func _raise_not_broken(t) -> void:
	var s := _world()
	var d := _bh(s)
	var built := (s.town as Town)._built.size()
	d._raise(0)
	var b := d.bearer(0)
	t.check(d.steps[0].raised and not d.steps[0].broken and d.broken_count() == 0, "at its time a step is raised and not broken (C4)")
	t.check(d.standards.is_empty() and d.steps[0].standard == null and d.standard(0) == null and d._filters.is_empty(), "no Structure, no damage filter, nothing connected")
	t.check(d._raise_standard(0) == null, "_raise_standard() makes nothing")
	t.check((s.town as Town)._built.size() == built, "and no building was added to the town")
	t.check(b.badge_left > 0.0 and b.badge_glyph == BreakHuntDirector.BH_FLAG and b.mind == Person.Mind.DUTY and b.goal().distance_to(d.house_doors[d._dest[0]]) < 0.6,
		"the bearer is marked with a pennant and marches for his house's door")
	t.check(d.guarded(0) and d.hint_phase() == "", "a raised standard with escorts by him is guarded")
	# Raising twice does nothing more.
	var first_at := d.steps[0].raised_at
	Kit.run_for(s, 3.0)
	d._raise(0)
	t.check(d.steps[0].raised_at == first_at and d.broken_count() == 0 and d.took_up_count == 0, "raising it again changes nothing (raised at %.1f)" % first_at)
	# A bearer fallen at the muster before his time: an escort carries it; with none left, the step breaks at its time.
	var u := _world()
	var du := _bh(u)
	var muster_escorts := _escorts(du, 1)
	_kill(u, du.bearer(1))
	du._raise(1)
	t.check(du.steps[1].raised and not du.steps[1].broken and muster_escorts.has(du.bearer(1)) and _escorts(du, 1).size() == 1,
		"a bearer fallen before his time: an escort carries the standard when it is raised")
	Kit.done(u)
	var w := _world()
	var dw := _bh(w)
	_kill(w, dw.bearer(2))
	for e: Person in _escorts(dw, 2):
		_kill(w, e)
	dw._raise(2)
	t.check(dw.steps[2].raised and dw.steps[2].broken and dw.broken_count() == 1, "with no one left to carry it, the step counts broken, so the night never locks")
	Kit.done(w)
	Kit.done(s)


## The march's pace and its window (MS §0): at its raise every countdown shows at least 45 s out, and the whole company walks at the same pace.
static func _pace_and_window(t) -> void:
	var s := _world()
	var d := _bh(s)
	var ok := true
	var shown := []
	for i in 4:
		d._raise(i)
		shown.append(snappedf(d.eta(i), 0.1))
		ok = ok and d.eta(i) >= 45.0
	t.check(ok, "each standard's countdown first shows 45 s or more (%s)" % [shown])
	var same := true
	for i in 4:
		var b := d.bearer(i)
		same = same and b.pace <= BreakHuntDirector.BH_BEARER_PACE / Person.PANIC_SPEED + 0.0001
		for e: Person in _escorts(d, i):
			same = same and is_equal_approx(e.pace, b.pace * BreakHuntDirector.BH_ESCORT_PACE)
	t.check(same, "a bearer walks no faster than the Hunt's pace (%.2f units a second) and his escorts at %.1f times it" % [
		BreakHuntDirector.BH_BEARER_PACE, BreakHuntDirector.BH_ESCORT_PACE])
	var doors: Array = []
	for i in 4:
		doors.append(d._dest[i])
	t.check(doors.size() == 4 and (doors[0] != doors[1] and doors[0] != doors[2] and doors[1] != doors[2]),
		"the first three standards are bound for three different houses (%s)" % [doors])
	Kit.done(s)


## Task 12, review-t7 M5: a bearer re-aimed at another house (his own was taken by another standard) walks the pace of the NEW street, not the one
## he was raised with: never faster than the 50 s a countdown needs (BH_MARCH_MIN), and no slower than the street allows. Tried for every standard (its house taken by another); at least one case must differ from the pace he was raised with, or the test proves nothing.
static func _reaim_pace(t) -> void:
	var differs := 0
	var tried := 0
	var bad := []
	for i in 4:
		var s := _world()
		var d := _bh(s)
		_steady(d)
		_raise(s, i)
		if d.bearer(i) == null:
			Kit.done(s)
			continue
		var raised_pace := d.bearer(i).pace
		d._taken[d._dest[i]] = true  # another standard planted there
		Kit.run_for(s, LOOK)
		var b := d.bearer(i)
		if b == null or d._dest[i] < 0:
			Kit.done(s)
			continue
		tried += 1
		var want := minf(BreakHuntDirector.BH_BEARER_PACE, d._way(b.ground_pos, d.house_doors[d._dest[i]]) / BreakHuntDirector.BH_MARCH_MIN) / Person.PANIC_SPEED
		differs += 1 if absf(want - raised_pace) > 0.001 else 0
		var escorts_ok := true
		for e: Person in _escorts(d, i):
			escorts_ok = escorts_ok and is_equal_approx(e.pace, want * BreakHuntDirector.BH_ESCORT_PACE)
		if absf(b.pace - want) > 0.001 or not escorts_ok or d.eta(i) < BreakHuntDirector.BH_MARCH_MIN - 2.0:
			bad.append("%d->%d pace %.4f want %.4f eta %.1f" % [i, d._dest[i], b.pace, want, d.eta(i)])
		Kit.done(s)
	t.check(tried == 4 and differs >= 2 and bad.is_empty(), "a re-aimed bearer and his escorts walk the new street's pace, and its countdown shows 50 s (tried %d, %d differ from the raise's pace; bad %s)" % [tried, differs, bad])


## Task 12, Ruling P5-T12-R1: a bearer sent for his house who has no way to walk (a thornwall shut the street the look he was sent, and has withered since) is
## sent again, so he takes the march up (MS §5), not stands at his muster until dawn. His goal is cleared by hand here (the test world's streets are open).
static func _resume_march(t) -> void:
	var s := _world()
	var d := _bh(s)
	_steady(d)
	_raise(s, 3)
	var b := d.bearer(3)
	var door: Vector2 = d.house_doors[d._dest[3]]
	t.check(b.has_goal() and b.anchor.distance_to(door) < 0.5, "(set-up) the bearer is sent for his house (%s)" % [b.anchor])
	b._goal = Vector2.INF  # the street was shut when he was sent: no way, and he stands on duty
	Kit.run_for(s, LOOK)
	t.check(b.has_goal() and b.mind == Person.Mind.DUTY, "a bearer on duty with no way to walk is sent again at the next look")
	b._goal = Vector2.INF
	Kit.arrive(b, door + Vector2(0.0, 0.5))
	Kit.run_for(s, LOOK)
	t.check(d.taken() == 1 and d._planted[3], "and one at the door plants (the resend never stands in the plant's way)")
	Kit.done(s)


## Task 12 (the wave-1 lesson on the walk): a standard re-aimed at another house while it marches (its house taken by another company) keeps its escorts in file,
## more than 1.6 apart, on the new street: bodies stepped frame by frame for 8 s on the first street, then along the new one, every step counted from the
## re-aim on, none excluded.
static func _reaim_walk(t) -> void:
	var s := _world()
	var d := _bh(s)
	_steady(d)
	_raise(s, 1)
	var w := _walker(d, 1)
	for f in 160:
		_walk_frame(s, d, 1, w, DT)
	d._taken[d._dest[1]] = true  # another standard planted there
	var was: int = d._dest[1]
	_walk_frame(s, d, 1, w, DT)
	var b := d.bearer(1)
	w.road = d.crowd._grid.path(b.ground_pos, d.house_doors[d._dest[1]])
	w.k = 0
	w.at = b.ground_pos
	var steps := 0
	var low := 0
	var closest := INF
	for f in 600:
		_walk_frame(s, d, 1, w, DT)
		var men := _escorts(d, 1).filter(func(e: Variant) -> bool: return MissionDirector._alive(e))
		if men.size() < 2 or d.steps[1].broken or d._planted[1]:
			break
		var gap: float = (men[0] as Person).ground_pos.distance_to((men[1] as Person).ground_pos)
		steps += 1
		closest = minf(closest, gap)
		low += 1 if gap <= 2.0 * SilentDoom.RADIUS else 0
	t.check(d._dest[1] != was and steps > 200 and float(low) <= 0.05 * float(steps) and not d.steps[1].broken,
		"after a re-aim the escorts keep apart on the new street: %d of %d steps at 1.6 or less (the least asked is 5%%), closest %.2f" % [low, steps, closest])
	Kit.done(s)


## The escorts' places move with the bearer, every look, and stay apart (MS §0, wave 1's finding): at every stop of every walk the two posts are
## on opposite sides of him more than 1.6 apart, and no escort post is within 1.6 of another standard's.
static func _escorts_follow(t) -> void:
	var s := _world()
	var d := _bh(s)
	for i in 4:
		d._raise(i)
	Kit.run_for(s, LOOK)
	var stops := 0
	var pair_ok := true
	var near_ok := true
	var cross_ok := true
	var worst := INF
	var worst_where := ""
	for i in 4:
		var road := _road(d, i)
		var k := 0
		while k < road.size() and d._way(road[k], d.house_doors[d._dest[i]]) > 2.5:
			_march_to(s, i, road[k])
			stops += 1
			var g0: HuntDirector.Guard = d.steps[i].party[0]
			var g1: HuntDirector.Guard = d.steps[i].party[1]
			var gap := g0.post.distance_to(g1.post)
			if gap < worst:
				worst = gap
				worst_where = "standard %d stop %d" % [i, k]
			pair_ok = pair_ok and gap > 2.0 * SilentDoom.RADIUS
			var at := d.bearer(i).ground_pos
			near_ok = near_ok and g0.post.distance_to(at) <= BreakHuntDirector.BH_GUARD_REACH and g1.post.distance_to(at) <= BreakHuntDirector.BH_GUARD_REACH
			for j in 4:
				if j == i:
					continue
				for g: HuntDirector.Guard in d.steps[j].party:
					cross_ok = cross_ok and g.post.distance_to(g0.post) > 2.0 * SilentDoom.RADIUS and g.post.distance_to(g1.post) > 2.0 * SilentDoom.RADIUS
			k += 3
		# Back to the muster for the next walk's check.
		_march_to(s, i, d.steps[i].spot)
	t.check(stops > 12 and pair_ok, "at every stop of every walk (%d) the two escorts' posts stand more than 1.6 apart (closest %.2f at %s)" % [stops, worst, worst_where])
	t.check(near_ok, "and within the guard reach of the bearer")
	t.check(cross_ok, "and more than 1.6 from every other standard's escorts")
	# The escorts are sent to the posts beside him, not left at the muster.
	var d2 := d
	_march_to(s, 0, _road(d2, 0)[_road(d2, 0).size() / 2])
	var e0: Person = _escorts(d2, 0)[0]
	var g0: HuntDirector.Guard = d2.steps[0].party[0]
	t.check(e0.mind == Person.Mind.DUTY and e0.goal().distance_to(g0.post) < 0.6 and g0.post.distance_to(d2.steps[0].spot) > 1.5,
		"each look sends an escort to the post beside the bearer where he now is (%s -> %s)" % [e0.goal(), g0.post])
	Kit.done(s)


## The company on a real walk (wave 1's finding, the first review's I1): bodies stepped frame by frame along each of the four routes at their own paces
## (the test world does not walk them): the bearer along the street at the Hunt's pace, each escort straight toward the place the director last gave
## him at his own pace (1.3 times the bearer's). At every frame the two escorts stand more than 1.6 apart and each within the guard reach of the
## bearer; the closest and the farthest are printed.
static func _walk_model(t) -> void:
	var worst_gap := INF
	var worst_reach := 0.0
	var bad := 0
	var frames := 0
	var where := ""
	var dt := 0.05
	for i in 4:
		var s := _world()
		var d := _bh(s)
		d._raise(i)
		var road := d.crowd._grid.path(d.steps[i].spot, d.house_doors[d._dest[i]])
		var b := d.bearer(i)
		var at := b.ground_pos
		var k := 0
		var end := d.house_doors[d._dest[i]]
		var guard: Array = d.steps[i].party
		var route_bad := 0
		while k < road.size() and at.distance_to(end) > 2.5:
			var left := Person.PANIC_SPEED * b.pace * dt
			while left > 0.0 and k < road.size():
				var to: Vector2 = road[k]
				var gap := at.distance_to(to)
				if gap <= left:
					at = to
					left -= gap
					k += 1
				else:
					at = at.move_toward(to, left)
					left = 0.0
			Kit.arrive(b, at)
			for g: HuntDirector.Guard in guard:
				var e: Person = g.man
				Kit.arrive(e, e.ground_pos.move_toward(g.post, Person.PANIC_SPEED * e.pace * dt))
			Kit.run_for(s, dt)
			var p0: Person = (guard[0] as HuntDirector.Guard).man
			var p1: Person = (guard[1] as HuntDirector.Guard).man
			var pair := p0.ground_pos.distance_to(p1.ground_pos)
			var reach := maxf(p0.ground_pos.distance_to(b.ground_pos), p1.ground_pos.distance_to(b.ground_pos))
			frames += 1
			if pair < worst_gap:
				worst_gap = pair
				where = "route %d frame %d" % [i, frames]
			worst_reach = maxf(worst_reach, reach)
			if pair <= 2.0 * SilentDoom.RADIUS or reach > BreakHuntDirector.BH_GUARD_REACH:
				bad += 1
				route_bad += 1
		t.check(not d.steps[i].broken and d.taken() == 0 and route_bad == 0, "route %d: the company walked to the last stretch with its standard standing and no bad frame (%d)" % [i, route_bad])
		t.check(d.pair_looks > 10 and d.pair_min < INF and d.pair_low == 0, "route %d: the director sampled the pair at %d looks, closest %.2f, %d at 1.6 or less" % [i, d.pair_looks, d.pair_min, d.pair_low])
		Kit.done(s)
	t.check(frames > 2000 and bad == 0, "on all four walks (%d frames) the escorts stand more than 1.6 apart and within %.1f of the bearer at every frame (%d bad; closest %.2f at %s, farthest %.2f)" % [
		frames, BreakHuntDirector.BH_GUARD_REACH, bad, worst_gap, where, worst_reach])


## Ruling P5-T7-R9: no muster's street to a house passes within 2.7 of another house's door (a planted company stands there), sampled here
## from the streets themselves.
static func _street_clear(t) -> void:
	var s := _world()
	var d := _bh(s)
	var least := INF
	var streets := 0
	for m in d.steps.size():
		for h in d.houses.size():
			var route := d.crowd._grid.path(d.steps[m].spot, d.house_doors[h])
			for g in d.houses.size():
				if g == h:
					continue
				var from := d.steps[m].spot
				for pt in route:
					least = minf(least, d.house_doors[g].distance_to(Geometry2D.get_closest_point_to_segment(d.house_doors[g], from, pt)))
					from = pt
			streets += 1
	t.check(streets == 12 and least >= BreakHuntDirector.BH_DOOR_CLEAR, "the 12 streets pass every other house's door by %.2f or more (the least asked is %.1f)" % [least, BreakHuntDirector.BH_DOOR_CLEAR])
	t.check(d.street_clearance() >= BreakHuntDirector.BH_DOOR_CLEAR, "and the director reports the same (%.2f)" % d.street_clearance())
	# A company planted at a house (its bearer at the door, its escorts at the posts _flanks() gives them) stands more than a Doom's reach
	# (BH_FLANK_GAP) from the walk of every company on its way to another house: the planted escorts' real places, not the door alone (task 12, M2).
	var near := 0
	var closest := INF
	var planted_posts := 0
	for h in d.houses.size():
		for i in d.steps.size():
			d._dest[i] = h
			d._planted[i] = true
			d._flank_ang[i] = NAN
			Kit.arrive(d.bearer(i), d.house_doors[h])  # the bearer planted at the door
			d._lane[i] = d._plant_posts(i, h)  # as _plant() chooses them
			var posts := d._flanks(i)
			d._planted[i] = false
			var stand: Array[Vector2] = [d.bearer(i).ground_pos, posts[0], posts[1]]
			planted_posts += 1 if posts[0].distance_to(d.house_doors[h]) < 2.7 and posts[1].distance_to(d.house_doors[h]) < 2.7 and posts[0].distance_to(posts[1]) >= BreakHuntDirector.BH_LANE_GAP - 0.06 else 0
			for m in d.steps.size():
				if m == i:
					continue
				for g in d.houses.size():
					if g == h:
						continue
					var from := d.steps[m].spot
					for pt in d.crowd._grid.path(d.steps[m].spot, d.house_doors[g]):
						for q in stand:
							var gap := q.distance_to(Geometry2D.get_closest_point_to_segment(q, from, pt))
							closest = minf(closest, gap)
							near += 1 if gap < BreakHuntDirector.BH_FLANK_GAP + Person.GOAL_REACH else 0
						from = pt
	t.check(near == 0 and planted_posts == 12, "so a planted company (bearer and both escorts, at their real places beside the door: %d of 12) is never within a Doom's reach of a company on its way (%d points; closest %.2f)" % [planted_posts, near, closest])
	Kit.done(s)


## A fallen escort is not replaced (MS §5): each standard grows easier.
static func _fallen_not_replaced(t) -> void:
	var s := _world()
	var d := _bh(s)
	_steady(d)
	_raise(s, 0)
	var es := _escorts(d, 0)
	var before := d.crew.size()
	_kill(s, es[0])
	Kit.run_for(s, 62.0)
	var alive := 0
	for e: Variant in _escorts(d, 0):
		alive += 1 if MissionDirector._alive(e) else 0
	t.check(alive == 1 and d.steps[0].party.size() == 2 and not (s.banners as Array).has("A NEW GUARD TAKES THE POST") and d.crew.size() == before,
		"a fallen escort is not replaced after 60 s: one stands, no relief banner, nobody new appointed (%d)" % alive)
	t.check(d.guarded(0) and d.relief_walking(0) == null, "the one left still guards")
	Kit.done(s)


static func _break_unguarded(t) -> void:
	# Both escorts dead, then the bearer: broken.
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	d.bearer(0).fearless_left = 600.0  # (the loud kills of his escorts do not frighten him here)
	for e: Person in _escorts(d, 0):
		_kill(s, e)
	Kit.run_for(s, LOOK)
	t.check(not d.guarded(0) and not d.steps[0].broken, "(set-up) no escort stands by him and the standard still stands")
	var b := d.bearer(0)
	_kill(s, b)
	Kit.run_for(s, LOOK)
	t.check(d.steps[0].broken and d.broken_count() == 1 and (s.banners as Array).has("THE STANDARD IS BROKEN  1/4") and d.bearer(0) == null,
		"the bearer killed unguarded: THE STANDARD IS BROKEN  1/4")
	t.check(not (s.banners as Array).has("THE STANDARD IS TAKEN UP"), "and nobody takes it up")
	Kit.done(s)

	# A frightened bearer with no escort by him: the standard is broken, and he is stood down.
	var f := _world()
	var df := _bh(f)
	_raise(f, 1)
	for e: Person in _escorts(df, 1):
		_kill(f, e)
	df.bearer(1).mind = Person.Mind.PANIC
	Kit.run_for(f, LOOK)
	t.check(df.steps[1].broken and df.bearer(1) != null and df.bearer(1).badge_left <= 0.0,
		"a bearer frightened (the town's panic counts too) with no escort by him breaks his standard and drops his pennant")
	Kit.done(f)

	# Death Mark: both escorts frail (unguarded at once), the bearer killed: broken, though both stand next to him.
	var m := _world()
	var dm := _bh(m)
	_raise(m, 2)
	for e: Person in _escorts(dm, 2):
		e.statuses[&"frail"] = 1.0
	Kit.run_for(m, LOOK)
	t.check(not dm._guarded(2) and not dm.steps[2].broken, "frail escorts do not guard")
	_kill(m, dm.bearer(2))
	Kit.run_for(m, LOOK)
	t.check(dm.steps[2].broken and not (m.banners as Array).has("THE STANDARD IS TAKEN UP"), "the bearer killed with both escorts frail: broken, not taken up")
	Kit.done(m)

	# The chain after a break: a released escort goes home, the party is stood down.
	var r := _world()
	var dr := _bh(r)
	_raise(r, 3)
	for e: Person in _escorts(dr, 3):
		_kill(r, e)
	_kill(r, dr.bearer(3))
	Kit.run_for(r, LOOK)
	t.check(dr.steps[3].broken and dr.broken_count() == 1 and not dr.broken_all(), "the fourth breaks; the win needs all four")
	Kit.done(r)


## What stops an escort guarding (MS §5): held by the god, fighting, afraid, frail, indoors, too far.
static func _guard_rules(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	var g: HuntDirector.Guard = d.steps[0].party[0]
	var e: Person = g.man
	t.check(d._guarding(0, g), "(set-up) an escort by his bearer guards")
	var cases := {
		"whispered": func() -> void: e.mind = Person.Mind.WHISPERED,
		"confused": func() -> void: e.mind = Person.Mind.CONFUSED,
		"compelled": func() -> void: e.mind = Person.Mind.COMPELLED,
		"fighting": func() -> void: e.mind = Person.Mind.FIGHT,
		"panicking": func() -> void: e.mind = Person.Mind.PANIC,
		"fleeing": func() -> void: e.mind = Person.Mind.FLEE,
		"sheltering": func() -> void: e.mind = Person.Mind.SHELTER,
		"frail": func() -> void: e.statuses[&"frail"] = 1.0,
		"indoors": func() -> void: e.inside = true,
		"too far": func() -> void: Kit.arrive(e, e.ground_pos + Vector2(BreakHuntDirector.BH_GUARD_REACH + 0.5, 0.0)),
	}
	for k: String in cases:
		var mind := e.mind
		var inside := e.inside
		var at := e.ground_pos
		var had := e.statuses.duplicate()
		(cases[k] as Callable).call()
		t.check(not d._guarding(0, g), "an escort who is %s does not guard" % k)
		e.mind = mind
		e.inside = inside
		e.ground_pos = at
		e.statuses = had
	t.check(d._guarding(0, g), "(and he guards again once he is himself)")
	Kit.done(s)


## A walker for standard `i`: the street from its muster to its house, and where the bearer stands on it.
static func _walker(d: BreakHuntDirector, i: int) -> Dictionary:
	return {"road": d.crowd._grid.path(d.steps[i].spot, d.house_doors[d._dest[i]]), "k": 0, "at": d.bearer(i).ground_pos, "b": d.bearer(i)}


## The bearer stands: on duty with no goal further than a pace off (the base's resume, or a take-up waiting for his fellow).
static func _is_held(b: Person) -> bool:
	return b.mind == Person.Mind.DUTY and (not b.has_goal() or b.goal().distance_to(b.ground_pos) < 0.3)


## One frame of standard `i`'s company with bodies stepped (the test world does not walk them): the bearer along the street at his pace unless he stands,
## each escort straight toward the place the director last gave him at his own pace; then the world runs the frame.
static func _walk_frame(s: Dictionary, d: BreakHuntDirector, i: int, w: Dictionary, dt: float) -> void:
	var b := d.bearer(i)
	if b != null:
		if b != w.b:
			w.b = b
			w.at = b.ground_pos
		if _is_held(b):
			w.at = b.ground_pos
		else:
			var road: PackedVector2Array = w.road
			var left := Person.PANIC_SPEED * b.pace * dt
			var at: Vector2 = w.at
			var k: int = w.k
			while left > 0.0 and k < road.size():
				var gap := at.distance_to(road[k])
				if gap <= left:
					at = road[k]
					left -= gap
					k += 1
				else:
					at = at.move_toward(road[k], left)
					left = 0.0
			w.at = at
			w.k = k
			b.ground_pos = at
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			var e: Person = g.man
			e.ground_pos = e.ground_pos.move_toward(g.post, Person.PANIC_SPEED * e.pace * dt)
	Kit.run_for(s, dt)


## A world where standard 0 has marched 8 s and its bearer is killed (a witnessed, loud kill): run until an escort has taken it up.
static func _taken_up_world() -> Dictionary:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	var w := _walker(d, 0)
	for f in 160:
		_walk_frame(s, d, 0, w, DT)
	var es := _escorts(d, 0)
	_kill(s, d.bearer(0))
	var n := 0
	while d.took_up_count == 0 and n < 40:
		_walk_frame(s, d, 0, w, DT)
		n += 1
	return {"s": s, "d": d, "w": w, "es": es}


## The take-up (Ruling P5-T7-R8): a guarded bearer struck dead is judged as he stood at the look before, so the fright his death gives his escorts does
## not stop one taking the standard up; he and his fellow are steadied for BH_STEADY seconds; after that the normal rules apply.
static func _take_up(t) -> void:
	var tw := _taken_up_world()
	var s: Dictionary = tw.s
	var d: BreakHuntDirector = tw.d
	var walk: Dictionary = tw.w
	var es: Array = tw.es
	var goal: Vector2 = d.house_doors[d._dest[0]]
	t.check(not d.steps[0].broken and d.bearer(0) != null and es.has(d.bearer(0)) and (s.banners as Array).has("THE STANDARD IS TAKEN UP"),
		"a guarded bearer killed in a witnessed blow after a march: an escort takes the standard up, not a break (%s)" % [s.banners])
	var up := d.bearer(0)
	var left: HuntDirector.Guard = d.steps[0].party[0]
	t.check(left.post.distance_to(up.ground_pos) <= BreakHuntDirector.BH_GUARD_REACH, "(the one left is sent to a place beside the new bearer at once)")
	t.check(up.fearless_left > 0.0 and (left.man as Person).fearless_left > 0.0 and up.fearless_left <= BreakHuntDirector.BH_STEADY + 0.01,
		"he and his fellow are steadied for %d s (%.1f, %.1f)" % [roundi(BreakHuntDirector.BH_STEADY), up.fearless_left, (left.man as Person).fearless_left])
	var tagged := false
	for l: String in Kit.labels(d):
		tagged = tagged or l.begins_with("STANDARD - TAKEN UP - HOUSE IN ")
	t.check(tagged, "the new bearer's tag reads STANDARD - TAKEN UP - HOUSE IN m:ss while he is steadied (%s)" % [Kit.labels(d)])
	t.check(d.steps[0].party.size() == 1 and (d.steps[0].party[0] as HuntDirector.Guard).man != up and d.took_up_count == 1 and d.hint_phase() == "carried",
		"he is no longer among the escorts; the hint reads 'carried' (%s)" % d.hint_phase())
	t.check(up.badge_glyph == BreakHuntDirector.BH_FLAG and _is_held(up), "he carries the pennant and stands while his fellow closes up (Ruling P5-T7-R11)")
	# The fellow closes up with bodies stepped frame by frame: at every frame he is within the guard reach of the new bearer, or the bearer stands.
	var fellow := left.man as Person
	var held_at := up.ground_pos
	var bad := 0
	var reach_at := -1.0
	var moved_held := false
	for f in 120:
		var held := _is_held(up)
		var before := up.ground_pos
		_walk_frame(s, d, 0, walk, DT)
		if held and up.ground_pos != before and _is_held(up):
			moved_held = true
		var near := fellow.ground_pos.distance_to(up.ground_pos) <= BreakHuntDirector.BH_GUARD_REACH
		if near and reach_at < 0.0:
			reach_at = float(f) * DT
		if not near and not held:
			bad += 1
	t.check(bad == 0 and reach_at >= 0.0 and reach_at <= 3.0 and not moved_held,
		"after a take-up his fellow is within the guard reach at every frame or the bearer stands: %d bad frames, in reach at %.2f s, the bearer %s while held" % [
		bad, reach_at, "moved" if moved_held else "stood"])
	t.check(not _is_held(up) and up.goal().distance_to(goal) < 0.6 and d.guarded(0) and not d.steps[0].broken,
		"then he marches on for the same house, his last escort guarding him")
	Kit.run_for(s, LOOK)
	# Taken up again: the steadied fellow carries it though the second death frightens him as well.
	_kill(s, up)
	Kit.run_for(s, LOOK)
	var last := d.bearer(0)
	t.check(not d.steps[0].broken and last != null and last != up and d.steps[0].party.is_empty() and d.took_up_count == 2,
		"the new bearer killed too, his fellow steadied and in reach: another take-up (%d taken up)" % d.took_up_count)
	t.check(not d.guarded(0) and last.fearless_left > 0.0, "and now no one guards him, but he is steadied")
	# With no escort left in reach, it breaks.
	_kill(s, last)
	Kit.run_for(s, LOOK)
	t.check(d.steps[0].broken and d.bearer(0) == null and d.broken_count() == 1, "he is killed with no escort left: the standard is broken at last")
	Kit.done(s)

	# A blow on the new bearer while his fellow is still out of reach follows the rule as written: no escort in reach, so it breaks.
	var win := _taken_up_world()
	var dwin: BreakHuntDirector = win.d
	for f in 10:
		_walk_frame(win.s, dwin, 0, win.w, DT)
	var far_fellow := (dwin.steps[0].party[0] as HuntDirector.Guard).man as Person
	var far_ok := far_fellow.ground_pos.distance_to(dwin.bearer(0).ground_pos) > BreakHuntDirector.BH_GUARD_REACH
	_kill(win.s, dwin.bearer(0))
	Kit.run_for(win.s, LOOK)
	t.check(far_ok and dwin.steps[0].broken and dwin.took_up_count == 1, "a blow on the new bearer while his fellow is still out of reach breaks the standard (no escort in reach)")
	Kit.done(win.s)

	# After the steadiness the normal rules apply: a fright with nobody guarding breaks the standard.
	var a := _world()
	var da := _bh(a)
	_raise(a, 1)
	_kill(a, da.bearer(1))
	Kit.run_for(a, LOOK)
	var carrier := da.bearer(1)
	for g: HuntDirector.Guard in da.steps[1].party:
		_kill(a, g.man)
	Kit.run_for(a, BreakHuntDirector.BH_STEADY + 1.0)
	carrier.fearless_left = 0.0
	carrier.mind = Person.Mind.PANIC
	Kit.run_for(a, 2.0 * LOOK)
	t.check(da.steps[1].broken, "once the steadiness is over, a frightened bearer with no escort by him breaks his standard")
	Kit.done(a)

	# An unguarded bearer killed breaks: his escorts are alive but out of reach, he is steady, so the kill itself is what breaks it.
	var u := _world()
	var du := _bh(u)
	_raise(u, 2)
	du.bearer(2).fearless_left = 600.0
	for e: Person in _escorts(du, 2):
		e.ground_pos += Vector2(12.0, 0.0)
	Kit.run_for(u, LOOK)
	t.check(not du.steps[2].broken and not du._guarded(2), "(set-up) his escorts are alive but out of reach, and the standard still stands: nothing but a blow breaks it")
	_kill(u, du.bearer(2))
	Kit.run_for(u, LOOK)
	t.check(du.steps[2].broken and du.took_up_count == 0 and not (u.banners as Array).has("THE STANDARD IS TAKEN UP"),
		"a bearer killed with no escort in reach breaks his standard, the kill itself being what breaks it")
	Kit.done(u)

	# Bearer and one escort killed together: the other takes it up.
	var b := _world()
	var db := _bh(b)
	_raise(b, 1)
	var e1: Person = _escorts(db, 1)[0]
	var e2: Person = _escorts(db, 1)[1]
	_kill(b, db.bearer(1))
	_kill(b, e1)
	Kit.run_for(b, LOOK)
	t.check(db.bearer(1) == e2 and not db.steps[1].broken, "bearer and one escort killed in one blow: the other takes it up")
	Kit.done(b)

	# An escort who was held by the god at the blow (whispered) does not take it up.
	var w := _world()
	var dw := _bh(w)
	_raise(w, 3)
	for e: Person in _escorts(dw, 3):
		e.mind = Person.Mind.WHISPERED
		e._whisper_left = 30.0  # (a whisper that lasts the look, and a mind no fright can take it from)
		e.fearless_left = 100.0
	_kill(w, dw.bearer(3))
	Kit.run_for(w, LOOK)
	t.check(dw.steps[3].broken, "escorts held by the god when the bearer falls: none takes the standard up")
	Kit.done(w)

	# A bearer held (a whisper) and back on his feet takes the march up again.
	var h := _world()
	var dh := _bh(h)
	_raise(h, 0)
	var hb := dh.bearer(0)
	hb.mind = Person.Mind.CALM
	Kit.run_for(h, LOOK)
	t.check(hb.mind == Person.Mind.DUTY and hb.goal().distance_to(dh.house_doors[dh._dest[0]]) < 0.6, "a bearer let go takes the march up again")
	Kit.done(h)


static func _out_of_walls(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 1)
	var b := d.bearer(1)
	Kit.arrive(b, Vector2(-19.0, 0.0))
	Kit.run_for(s, LOOK)
	t.check(d.steps[1].broken and d.walled_count == 1 and d.is_leaving(b) and (s.banners as Array).has("THE STANDARD IS BROKEN  1/4"),
		"a bearer out of the walls: the standard is broken and he is walked off the map (shared rule 1)")
	Kit.done(s)
	# A bearer who took it up, then out of the walls: the same.
	var u := _world()
	var du := _bh(u)
	_steady(du)
	_raise(u, 2)
	_kill(u, du.bearer(2))
	Kit.run_for(u, LOOK)
	var up := du.bearer(2)
	Kit.arrive(up, Vector2(19.0, 0.0))
	Kit.run_for(u, LOOK)
	t.check(du.steps[2].broken and du.is_leaving(up), "the escort who took it up, out of the walls: broken too")
	Kit.done(u)


static func _taken(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	var h: int = d._dest[0]
	var door: Vector2 = d.house_doors[h]
	var road := _road(d, 0)
	_march_to(s, 0, road[road.size() / 2])
	t.check(d.taken() == 0, "(set-up) half way, nothing is taken")
	_march_to(s, 0, door + Vector2(0.0, 0.9))
	t.check(d.taken() == 1 and d._taken[h] and d._planted[0] and (s.banners as Array).has("A HOUSE IS TAKEN - ONE MORE AND THE HUNT IS LOST"),
		"a bearer within 1.0 of a house's door plants the standard: the house is taken, with its banner (%s)" % [s.banners])
	t.check(not d.found and d.lost_reason() == "" and not d.steps[0].broken, "one house is no loss; the standard stands, planted, still counted")
	t.check(d.hint_phase() == "taken" and d.eta(0) == INF and Kit.labels(d).has("STANDARD - PLANTED") and Kit.labels(d).has("BELIEVERS - TAKEN"),
		"the hint reads 'taken'; the tags read PLANTED and TAKEN (%s)" % [Kit.labels(d)])
	# Still breakable: the unguarded planted bearer killed breaks the standard, and the house stays taken.
	for e: Person in _escorts(d, 0):
		_kill(s, e)
	_kill(s, d.bearer(0))
	Kit.run_for(s, LOOK)
	t.check(d.steps[0].broken and d.taken() == 1, "a planted standard is still breakable; its house stays taken")
	# A later bearer marches on a house left.
	_raise(s, 1)
	t.check(d._dest[1] >= 0 and not d._taken[d._dest[1]], "a later bearer is bound for a house still standing free (%d)" % d._dest[1])
	# A bearer at a taken house's door does not take it twice.
	_march_to(s, 1, d.house_doors[h])
	t.check(d.taken() == 1 and d._dest[1] != h and not d._planted[1], "and a taken house is not taken again; he marches on another")
	Kit.done(s)

	# A bearer not on duty (frightened) near a door plants nothing.
	var u := _world()
	var du := _bh(u)
	_raise(u, 0)
	du.bearer(0).mind = Person.Mind.PANIC
	Kit.arrive(du.bearer(0), du.house_doors[du._dest[0]])
	Kit.run_for(u, LOOK)
	t.check(du.taken() == 0, "a frightened bearer at the door plants nothing (and, guarded, his standard stands)")
	Kit.done(u)


static func _lose_two(t) -> void:
	var s := _world()
	var d := _bh(s)
	var rules: Rules = s.rules
	_raise(s, 0)
	_raise(s, 1)
	_march_to(s, 0, d.house_doors[d._dest[0]])
	t.check(d.taken() == 1 and rules.objectives[0].check(rules) == Objective.Status.PENDING, "one taken: the objective is pending")
	_march_to(s, 1, d.house_doors[d._dest[1]])
	Kit.run_for(s, LOOK)
	t.check(d.taken() == 2 and d.found and d.lost_reason() == "houses" and (s.banners as Array).has("THE HUNT TAKES THEIR HOUSES"),
		"two houses taken: the hunt has found its quarry, lost_reason 'houses', with its banner (%s)" % [s.banners])
	t.check(rules.objectives[0].check(rules) == Objective.Status.FAILED and rules.objectives[0].reason == "houses", "the Hunt objective fails with 'houses'")
	t.check(d.tags().is_empty() and d.strip_rows().is_empty() and d.hint_phase() == "", "and the tags, the strip row and the hint go quiet")
	Kit.done(s)


## MS §0: the winning strike never also loses. Two houses are taken (before the director's next look finds its quarry) and the last standards
## are broken in the same look: the Hunt objective is read first and wins, and the director finds no quarry.
static func _win_beats_loss(t) -> void:
	var s := _world()
	var d := _bh(s)
	var rules: Rules = s.rules
	for i in 4:
		d._raise(i)
	d._plant(0, d._dest[0])
	d._plant(1, d._dest[1])
	t.check(d.taken() == 2, "(set-up) two houses are taken")
	for i in 4:
		d._break(i)
	t.check(d.broken_all() and not d._found(), "all four broken: the director finds no quarry though two houses are taken")
	Kit.run_for(s, LOOK)
	t.check(rules.objectives[0].check(rules) == Objective.Status.DONE and rules.objectives[0].reason == "standards" and d.lost_reason() == "",
		"all four broken wins first, whatever else is true (%s)" % [d.lost_reason()])
	t.check(not (s.banners as Array).has("THE HUNT TAKES THEIR HOUSES"), "and no loss banner comes with the win")
	Kit.done(s)


## The warning window (MS §0, wave 1's finding): the countdown shows from the raise, the 'near' banner only at 15 s, once, in a later look.
static func _near_warning(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	t.check(not (s.banners as Array).has("A STANDARD NEARS A HOUSE") and d.eta(0) >= 45.0, "at the raise: the countdown (%.0f s), no 'near' banner" % d.eta(0))
	var labels := Kit.labels(d)
	var counting := false
	for l: String in labels:
		counting = counting or l.begins_with("BELIEVERS - STANDARD IN ") or l.begins_with("STANDARD - HOUSE IN ")
	t.check(counting, "the house and the bearer both count down (%s)" % [labels])
	t.check(d.strip_rows().size() == 1 and d.strip_rows()[0].label == "A standard reaches a house" and float(d.strip_rows()[0]["in"]) >= 45.0,
		"the strip has a row 'A standard reaches a house' counting down (%s)" % [d.strip_rows()])
	# Half way: not yet.
	var road := _road(d, 0)
	_march_to(s, 0, road[road.size() / 2])
	t.check(not (s.banners as Array).has("A STANDARD NEARS A HOUSE"), "half way (%.0f s out) there is no banner yet" % d.eta(0))
	# Within 15 s of the door: the banner, once.
	var door: Vector2 = d.house_doors[d._dest[0]]
	var k := road.size() - 1
	while k > 0 and d._way(road[k], door) < 6.0:
		k -= 1
	_march_to(s, 0, road[k])
	var after := (s.banners as Array).count("A STANDARD NEARS A HOUSE")
	_march_to(s, 0, road[k])
	t.check(d.eta(0) <= BreakHuntDirector.BH_NEAR_WARN + 0.5 and after == 1 and (s.banners as Array).count("A STANDARD NEARS A HOUSE") == 1,
		"within 15 s (%.1f) the banner A STANDARD NEARS A HOUSE comes once" % d.eta(0))
	Kit.done(s)


## The bell never loses: a toll turns the Lantern and nothing else (the watch kind, MS §0).
static func _lantern(t) -> void:
	var s := _world()
	var d := _bh(s)
	var rules: Rules = s.rules
	_raise(s, 0)
	t.check(rules.lantern != null and rules.lantern.kind == LanternWatch.KIND_WATCH, "a watch Lantern")
	rules.lantern.on_toll()
	d.on_toll()
	Kit.run_for(s, 1.0)
	t.check(rules.lantern.tolled and d.lost_reason() == "" and rules.objectives[0].check(rules) != Objective.Status.FAILED and d.bearer(0) != null,
		"a toll turns the Lantern and never loses: the standard marches on")
	# On a Lantern night the director's clock runs in mission seconds, like the strip.
	var before := d._clock
	var tl := d.timeline.seconds_to("step_1")
	rules.clock_rate = 2.0
	d.step(1.0)
	t.check(is_equal_approx(d._clock - before, 2.0), "the director's clock runs in mission seconds (a Lantern at x2: %.1f for 1 s)" % (d._clock - before))
	t.check(tl > 0.0, "(the next standard is on the strip)")
	Kit.done(s)


## Freed bodies (MS §0): a freed bearer, a freed escort, nothing breaks.
static func _lost_body(t) -> void:
	var s := _world()
	var d := _bh(s)
	_steady(d)
	_raise(s, 0)
	_raise(s, 1)
	var e: Person = _escorts(d, 0)[0]
	Kit.free_body(s, e)
	Kit.run_for(s, LOOK)
	t.check(d.guarded(0) and d.tags().size() > 0, "a freed escort: the other still guards; the tags still read")
	var b := d.bearer(1)
	Kit.free_body(s, b)
	Kit.run_for(s, LOOK)
	t.check(d.bearer(1) != null and not d.steps[1].broken and d.took_up_count == 1, "a freed bearer: his escort takes the standard up")
	for x: Variant in _escorts(d, 1):
		if is_instance_valid(x):
			Kit.free_body(s, x as Person)
	Kit.free_body(s, d.bearer(1))
	Kit.run_for(s, LOOK)
	t.check(d.steps[1].broken and d.bearer(1) == null, "and when every one of them is freed the standard is broken, with no error")
	d.tags()
	d.strip_rows()
	d.report()
	Kit.done(s)


static func _tags(t) -> void:
	var s := _world()
	var d := _bh(s)
	var pre := Kit.labels(d)
	t.check(pre.count("BELIEVERS") == 3 and pre.count("ESCORT") == 0 and pre.has("RAISED IN 0:20"), "before the march: three houses, grey countdowns, no escort tag (%s)" % [pre])
	t.check(Kit.edged(d, "RAISED IN 0:20") and not Kit.edged(d, "RAISED IN 1:10"), "the next muster is pointed at, the later ones are not")
	_raise(s, 0)
	var labels := Kit.labels(d)
	var bearer_label := ""
	for l: String in labels:
		if l.begins_with("STANDARD - HOUSE IN "):
			bearer_label = l
	t.check(bearer_label != "" and Kit.edged(d, bearer_label), "the bearer is tagged STANDARD - HOUSE IN m:ss, pointed at (%s)" % [labels])
	t.check(labels.count("ESCORT") == 2 and Kit.edged(d, "ESCORT"), "his two escorts are tagged ESCORT, pointed at")
	var gold := false
	var red := true
	var blue := false
	for m in d.tags():
		gold = gold or (m.label == bearer_label and m.color == HuntDirector.MARK_TARGET)
		red = red and (m.label != "ESCORT" or m.color == HuntDirector.MARK_WATCHED)
		blue = blue or (m.label.begins_with("BELIEVERS - STANDARD IN ") and m.color == BreakHuntDirector.BH_MARK_HOUSE)
	t.check(gold and red and blue, "the bearer gold, the escorts red, the house blue")
	t.check(labels.has("RAISED IN 1:10") and not labels.has("RAISED IN 0:20"), "the raised muster's grey tag is gone; the others count on")
	var bad := false
	for l: String in labels:
		bad = bad or l.contains("DO NOT KILL") or l.contains("STRUCTURE")
	t.check(not bad, "no DO NOT KILL (no death loses)")
	# Counting down like the strip: the bearer half way, the countdown about half; between looks it runs down with the clock.
	var first := d.eta(0)
	var road := _road(d, 0)
	_march_to(s, 0, road[road.size() / 2])
	var half := d.eta(0)
	t.check(half < first * 0.75 and half > first * 0.25, "the countdown follows the bearer along the road (%.1f then %.1f)" % [first, half])
	d._clock += 0.4
	t.check(is_equal_approx(half - d.eta(0), 0.4), "and between looks it runs down with the clock (%.2f then %.2f)" % [half, d.eta(0)])
	Kit.done(s)


static func _camera(t) -> void:
	var s := _world()
	var d := _bh(s)
	var cam := BreakHuntDirector.BH_CAMERA_AT
	var keep := Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))
	var clear := true
	var failed := ""
	for m in d.tags():
		if m.label == "RAISED IN 0:20" or m.at.distance_to(d.house_doors[d._dest[0]]) < 0.1:
			if keep.has_point(Kit.shown_at(m.at, cam)):
				clear = false
				failed = m.label
	t.check(clear, "the first muster's countdown and its house's tag are clear of the padded HUD stack from the camera (%s)" % failed)
	d._raise(0)
	var bearer_ok := not keep.has_point(Kit.shown_at(d.bearer(0).ground_pos, cam))
	t.check(bearer_ok, "and so is the first bearer at his muster (%s)" % [Kit.shown_at(d.bearer(0).ground_pos, cam)])
	var muster := Kit.shown_at(d.steps[0].spot, cam)
	t.check(Rect2(Vector2.ZERO, Kit.VIEW).has_point(muster), "the first muster is on screen (%s)" % [muster])
	Kit.done(s)


## The director's people are held out of the flight every look (_hold_all).
static func _hold(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	var b := d.bearer(0)
	var e: Person = _escorts(d, 0)[0]
	b._reassured_fled = true
	e._reassured_fled = true
	Kit.run_for(s, LOOK)
	t.check(not b._reassured_fled and not e._reassured_fled, "each look lets go of the flight a false calm owes the bearer and his escort")
	Kit.done(s)


static func _evacuation(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	_raise(s, 1)
	var b := d.bearer(0)
	b._recover(1.0)
	var e: Person = _escorts(d, 0)[0]
	e._recover(1.0)
	Kit.evacuate(s)
	t.check(b.mind == Person.Mind.FLEE, "(set-up) the evacuation sends the recovering bearer running (%s)" % Person.Mind.keys()[b.mind])
	Kit.run_for(s, 2.0 * HuntDirector.TICK + DT)
	t.check(b.mind == Person.Mind.DUTY and b.goal().distance_to(d.house_doors[d._dest[0]]) < 0.6, "at the next looks the bearer is back on duty, bound for his house (%s)" % Person.Mind.keys()[b.mind])
	t.check(e.mind != Person.Mind.FLEE and (s.crowd as Crowd).citizens.has(e), "his escort is held out of the flight too")
	t.check(not d.steps[0].broken and not d.steps[1].broken and d.broken_count() == 0, "and the town's flight was no fright: nothing broke")
	Kit.run_for(s, 5.0)
	t.check(d.taken() == 0 and not d.found and not (s.rules as Rules).finished, "the town's flight loses nothing and breaks nothing")
	Kit.done(s)


## Teardown with no Structure raises no error, puts the stone houses and the pennants back, and is safe twice.
static func _teardown_clean(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	var h: Structure = d.houses[0]
	var b := d.bearer(0)
	t.check(h.damage_filter == d._stone and b.badge_glyph == BreakHuntDirector.BH_FLAG, "(set-up) a stone house and a pennant")
	d.teardown()
	t.check(not h.damage_filter.is_valid() and b.badge_left <= 0.0 and d.standards.is_empty(), "teardown puts the house's own filter back and takes the pennant off")
	d.teardown()
	t.check(not h.damage_filter.is_valid() and d.standards.is_empty() and d.timeline == null, "a second teardown raises no error and changes nothing")
	Kit.done(s)


## Open issue 4's promise for this Hunt (Task 1's _hunt_wishes cannot read the escorts held in the steps' records): on nights 0-3 the Descent hears
## the tier's wishes and none lands on a bearer, an escort or one of the three houses.
static func _wishes(t) -> void:
	var id := MissionBook.BREAK_HUNT
	var heard := 0
	var hit := 0
	for night in 4:
		var def := HuntBook.def(id)
		var descent := Descent.new().setup(def, Descent.seed_for(night, id))
		var n := Kit.world(HuntBook.def(id), null, func(dir: MissionDirector, rules: Rules) -> void: descent.reserve(rules, dir))
		var d := _bh(n)
		var mine: Array = []
		mine.append_array(d.crew)
		mine.append_array(d.bearers)
		var places: Array = []
		places.append_array(d.houses)
		for w in descent.wishes:
			heard += 1
			for p in w.people():
				hit += 1 if mine.has(p) else 0
			for st in w.places():
				hit += 1 if places.has(st) else 0
		t.check(d.crew.size() == 12 and d.houses.size() == 3, "night %d: twelve people and three houses (%d, %d)" % [night, d.crew.size(), d.houses.size()])
		descent.release()
		Kit.done(n)
	t.check(heard > 0 and hit == 0, "wishes heard (%d), none on the director's own people or buildings (%d)" % [heard, hit])


# --- Task 12: the six types' scripted policies (tools/dev/routes/god_hunts/break_hunt.gd) -------------------------------------------------------------

const GodHunts := preload("res://tools/dev/routes/god_hunts.gd")
const Policies := preload("res://tools/dev/routes/god_hunts/break_hunt.gd")  # (its _out_spot() places the whisper in _whisper_walk)


## What behaviour_check gives a Hunt policy (the slot test, the cooldown, the walk's length), as the policies call them.
class Bc:
	extends RefCounted

	func _slot_ready(rules: Rules, slots: Dictionary, key: String) -> bool:
		return slots.has(key) and rules.refusal(int(slots[key])) == ""

	func _slot_wait(rules: Rules, slots: Dictionary, key: String) -> float:
		return rules.cooldown_left(int(slots[key])) if slots.has(key) else INF

	func _walk_len(crowd: Crowd, from: Vector2, to: Vector2) -> float:
		var path := crowd._grid.path(from, to)
		if path.is_empty():
			return INF
		var n := 0.0
		var at := from
		for q in path:
			n += at.distance_to(q)
			at = q
		return n


## All six types are written and none is a filler (T1R D38: a cast made only so the scripted player is not idle). The file never names the filler mark; the
## behavioural proof is _policies_play.
static func _policies_written(t) -> void:
	var file := FileAccess.get_file_as_string("res://tools/dev/routes/god_hunts/break_hunt.gd")
	t.check(Array(GodHunts.filled("break_hunt")) == ["ruin", "death", "veil", "passage", "decree", "dominion"], "all six types are filled (%s)" % [GodHunts.filled("break_hunt")])
	t.check(not file.contains("GOD.FILL") and not file.contains("GodT1.FILL") and not file.contains("\"fill:"), "no policy of the file names the filler mark (D38)")


## How near a cast's aim must lie to someone the night still has to answer -- a bearer or an escort of an unbroken standard, out of doors -- by power (the effect's
## own radius, read from the power: Silent Doom 0.8, Smite 0.6, Death Mark's pick 1.0, Pestilence 1.2, Discord 1.2, Mind Whisper's pick 0.6; Leaving Is Prohibited 3.0,
## Heaven Splitter's core 1.6, the wall and the mirror a few units ahead of the file). The test world's bodies stand, so an aim at one needs no slack.
const AIM_REACH := {"doom": SilentDoom.RADIUS, "smite": SmiteFx.KILL_R, "deathmark": DeathMarkFx.PICK_R, "pestilence": PestilenceFx.INFECT_R, "discord": DiscordFx.DISCORD_R,
	"whisper": MindWhisperFx.PICK_R, "noleave": 3.0, "heaven": 1.6, "thorns": 8.0, "mirror": 8.0}


## The Hunt's people who still have to be answered: the bearer and the escorts of every unbroken standard, alive and out of doors.
static func _needy(d: BreakHuntDirector) -> Array[Person]:
	var out: Array[Person] = []
	for i in d.steps.size():
		if d.steps[i].broken:
			continue
		if d.bearer(i) != null and not d.bearer(i).inside:
			out.append(d.bearer(i))
		for e: Variant in _escorts(d, i):
			if MissionDirector._alive(e) and not (e as Person).inside:
				out.append(e as Person)
	return out


## What is wrong with a cast of `key` at `at` as the night stands: "" when its aim is within the power's reach of someone the night still has to answer and --
## for the powers that mark one man -- he is not already answered by it (a Death Mark on the frail, Pestilence on the sick, Discord on the confused, a whisper
## on the whispered). Blight must be on the Bell Tower. An empty cast is a filler.
static func _aim_problem(d: BreakHuntDirector, key: String, at: Vector2) -> String:
	if key == "blight":
		return "" if at.distance_to(City.current().landmark(&"bell_tower").get_center()) <= 1.0 else "not on the Bell Tower"
	var reach: float = float(AIM_REACH.get(key, 1.0))
	var near := INF
	var fresh := false
	for p in _needy(d):
		var gap := p.ground_pos.distance_to(at)
		near = minf(near, gap)
		if gap > reach:
			continue
		match key:
			"deathmark": fresh = fresh or not p.statuses.has(&"frail")
			"pestilence": fresh = fresh or p.sick_left <= 0.0
			"discord": fresh = fresh or p.mind != Person.Mind.CONFUSED
			"whisper": fresh = fresh or p.mind != Person.Mind.WHISPERED
			_: fresh = true
	if near > reach:
		return "no bearer or escort within %.1f (the nearest %.1f)" % [reach, near]
	if not fresh:
		return "everyone in reach is already answered by it"
	return ""


## The Hunt's world with the type's loadout (the def's default_loadout) and its slots by key.
static func _policy_world(type: String) -> Dictionary:
	var def := MissionBook.break_hunt()
	def.default_loadout = GodHunts.loadout("break_hunt", type, 4)
	var s := Kit.world(def)
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_WATCH)
	(s.rules as Rules).lantern = lw
	var slots := {}
	for slot in (s.rules as Rules).loadout.size():
		if (s.rules as Rules).key(slot) != "":
			slots[(s.rules as Rules).key(slot)] = slot
	s["slots"] = slots
	s["def"] = def
	return s


## Each type's policy, played for a minute and a half of the night with the bodies where they stand (the casts do nothing in this world: only the choice is
## checked). Every cast is a key of the type's loadout, none is a filler word, and every cast lands within its power's reach of someone the night still has
## to answer and not on one it has already answered (Ruling P5-T10-R2, P5-T11-R7): the proof that no policy casts only to end a stretch of idle.
static func _policies_play(t) -> void:
	GodTree.dev_fill = true
	for type: String in GodHunts.TYPES:
		var s := _policy_world(type)
		var d := _bh(s)
		var rules: Rules = s.rules
		var casts: Array[String] = []
		var misses: Array[String] = []
		rules.cast_made.connect(func(_slot: int, key: String, at: Vector2) -> void:
			casts.append(key)
			var why := _aim_problem(d, key, at)
			if why != "":
				misses.append("%s at %s: %s" % [key, at, why]))
		var said: Array[String] = []
		var memo := {}
		var bc := Bc.new()
		for i in roundi(90.0 / DT):
			Kit.run_for(s, DT)
			if i % 10 == 0:
				var ctx := {"rules": rules, "slots": s.slots, "d": rules.director, "crowd": s.crowd, "memo": memo, "mission": null}
				var did := GodHunts.act("break_hunt", type, bc, ctx)
				if did != "":
					said.append(did)
		var ok := true
		for key in casts:
			ok = ok and (s.def as MissionDef).default_loadout.has(key)
		var fills := said.filter(func(w: String) -> bool: return GodHunts.GOD_T1.is_fill(w))
		t.check(ok and fills.is_empty() and not casts.is_empty(), "%s: the policy casts (%s), only keys of its loadout, no filler (%s)" % [type, casts, said])
		t.check(misses.is_empty(), "%s: every cast lands on a bearer or an escort the night still has to answer, within its reach, and not on one it has already answered (%s)" % [type, misses])
		Kit.done(s)
	GodTree.dev_fill = false


## The aim check itself can fail (the mutation of the no-filler proof): a cast at nobody, a Death Mark on the frail, Pestilence on the sick, Discord on the
## confused, a whisper on the whispered, a Blight away from the Bell Tower are all told.
static func _aim_teeth(t) -> void:
	var s := _world()
	var d := _bh(s)
	_raise(s, 0)
	var b := d.bearer(0)
	t.check(_aim_problem(d, "doom", b.ground_pos) == "" and _aim_problem(d, "doom", b.ground_pos + Vector2(40.0, 0.0)) != "",
		"a Doom on the bearer is aimed; the same far from everyone is an empty cast")
	# Everyone else out of the way, the bearer alone and answered every way a power can answer him.
	for i in 4:
		for v: Variant in _escorts(d, i):
			if MissionDirector._alive(v):
				(v as Person).ground_pos = Vector2(-60.0, -60.0 + float(i))
		if i > 0 and d.bearer(i) != null:
			d.bearer(i).ground_pos = Vector2(60.0, 60.0 + float(i))
	b.statuses[&"frail"] = true
	b.sick_left = 4.0
	b.mind = Person.Mind.WHISPERED
	t.check(_aim_problem(d, "deathmark", b.ground_pos) != "" and _aim_problem(d, "pestilence", b.ground_pos) != "" and _aim_problem(d, "whisper", b.ground_pos) != "",
		"a Death Mark on the frail, Pestilence on the sick and a whisper on the whispered are repeats")
	b.mind = Person.Mind.CONFUSED
	t.check(_aim_problem(d, "discord", b.ground_pos) != "", "a Discord on the confused is a repeat")
	t.check(_aim_problem(d, "blight", Vector2.ZERO) != "" and _aim_problem(d, "blight", City.current().landmark(&"bell_tower").get_center()) == "", "Blight is aimed at the Bell Tower")
	Kit.done(s)


## One frame of standard `i`'s company with bodies stepped when the bearer is walked by hand: the bearer along `route` at `speed` (a unit a second) unless `walk`
## is false, each escort straight toward the post the director last gave him at his own pace, stopping within Person.GOAL_REACH of it as a body does; then the world
## runs the frame. Returns the new index into `route`.
static func _step_company(s: Dictionary, d: BreakHuntDirector, i: int, route: PackedVector2Array, k: int, speed: float, dt: float, walk := true) -> int:
	var b := d.bearer(i)
	if walk and b != null:
		var left := speed * dt
		var at := b.ground_pos
		while left > 0.0 and k < route.size():
			var gap := at.distance_to(route[k])
			if gap <= left:
				at = route[k]
				left -= gap
				k += 1
			else:
				at = at.move_toward(route[k], left)
				left = 0.0
		b.ground_pos = at  # (Kit.arrive() would drop the goal a whisper gave him)
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			var e: Person = g.man
			if e.ground_pos.distance_to(g.post) > Person.GOAL_REACH:
				e.ground_pos = e.ground_pos.move_toward(g.post, Person.PANIC_SPEED * e.pace * dt)
	d.step(dt)  # the director alone: the world's own tick would drop the goal of a body that is moved by hand
	return k


## The gap between the two living escorts of standard `i`, INF with fewer than two.
static func _pair_gap(d: BreakHuntDirector, i: int) -> float:
	var men: Array = _escorts(d, i).filter(func(e: Variant) -> bool: return MissionDirector._alive(e))
	return INF if men.size() < 2 else (men[0] as Person).ground_pos.distance_to((men[1] as Person).ground_pos)


## Ruling P5-T12-R2 (review-t12 I1; the wave-1 standard): a bearer the god whispers to ground out of the walls walks another road than the street to his house, and
## his escorts stand ahead of him along the road he is on, not along the street to the house (which runs back over his own trail: ahead and behind coincided, the two
## escorts stood on one spot for the 110 s of the walk). Bodies stepped frame by frame along the whispered walk (the bearer at his whispered pace), every step counted
## from the whisper on with nothing excluded: at most 5 % of the steps under 1.6, and over 1.6 at every stop.
static func _whisper_walk(t) -> void:
	var bc := Bc.new()
	for i in [0, 1]:
		var s := _world()
		var d := _bh(s)
		_steady(d)
		_raise(s, i)
		var b := d.bearer(i)
		for f in 20:  # 2 s of the march first, so there is a trail behind him
			var road := d.crowd._grid.path(b.ground_pos, d.house_doors[d._dest[i]])
			_step_company(s, d, i, road, 0, Person.PANIC_SPEED * b.pace, 0.1)
		var spot: Vector2 = Policies._out_spot(bc, d.crowd, b)
		b.whisper(spot, 8.0)
		var route := d.crowd._grid.path(b.ground_pos, spot)
		var speed := b.walk_speed
		var k := 0
		var steps := 0
		var low := 0
		var closest := INF
		# He walks the road out as far as the walls (stepped 0.25 s at a time, every step counted from the whisper on), then stands.
		var inside := route.size()
		for q in route.size():
			if Walls.outside(route[q]):
				inside = maxi(q - 1, 0)
				break
		while k < inside and steps < 1500 and not d.steps[i].broken:
			k = _step_company(s, d, i, route, k, speed, 0.25)
			var gap := _pair_gap(d, i)
			if gap == INF:
				break
			steps += 1
			closest = minf(closest, gap)
			low += 1 if gap <= 2.0 * SilentDoom.RADIUS else 0
		# He stands (arrived, lingering): every step of the stop is over 1.6.
		b._goal = Vector2.INF
		var stop_low := 0
		for f in 40:
			_step_company(s, d, i, route, k, speed, 0.25, false)
			stop_low += 1 if _pair_gap(d, i) <= 2.0 * SilentDoom.RADIUS else 0
		t.check(steps > 300 and float(low) <= 0.05 * float(steps) and stop_low == 0 and not d.steps[i].broken,
			"standard %d whispered out: %d of %d walking steps with the escorts at 1.6 or less (5%% allowed), closest %.2f; %d of 40 at the stop" % [i, low, steps, closest, stop_low])
		Kit.done(s)


## Ruling P5-T12-R3 (review-t12 I2): a standard planted at a door stands its escorts more than 1.6 apart as BODIES, not only as posts: the bodies stop up to
## Person.GOAL_REACH short of their posts, so the posts are BH_LANE_GAP (2.6) apart. At each of the three doors the standard is planted (the bearer at the door,
## the escorts walking in from where the march left them), bodies stepped 10 s: every step of the last 5 s is over 1.6 and the least is printed.
static func _planted_bodies(t) -> void:
	var worst := INF
	var bad := 0
	var cases := 0
	for h in 3:
		var s := _world()
		var d := _bh(s)
		_steady(d)
		var i := h
		d._raise(i)
		Kit.run_for(s, LOOK)
		var door: Vector2 = d.house_doors[h]
		d._dest[i] = h
		Kit.arrive(d.bearer(i), door + Vector2(0.0, 0.3))
		var first := true
		for g: HuntDirector.Guard in d.steps[i].party:
			Kit.arrive(g.man, door + Vector2(1.3 if first else -1.3, 0.2))
			first = false
		Kit.run_for(s, LOOK)
		t.check(d._planted[i], "(set-up) the standard is planted at door %d" % h)
		for f in 100:
			_step_company(s, d, i, PackedVector2Array(), 0, 0.0, 0.1, false)
			if f >= 50:
				var gap := _pair_gap(d, i)
				worst = minf(worst, gap)
				bad += 1 if gap <= 2.0 * SilentDoom.RADIUS else 0
		cases += 1
		Kit.done(s)
	t.check(cases == 3 and bad == 0, "planted at each door the escorts' bodies stand more than 1.6 apart for the last 5 s (%d bad steps; the least %.2f)" % [bad, worst])
