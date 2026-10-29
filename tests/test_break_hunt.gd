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
	_escorts_follow(t)
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
## (Death Mark, an unseen Doom) does not. A loud one scatters the company -- every one of them shelters or runs, which is a fright -- and a
## standard struck so breaks at once (MS §5: "A fright counts whoever set it going"); the tests that need a calm company say so here.
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
			reach_ok = reach_ok and e.ground_pos.distance_to(b.ground_pos) <= BreakHuntDirector.BH_ESCORT_OFF + 0.35
			everyone.append(e)
		t.check(d.steps[i].party_size == 2 and d.guarded(i) == false, "standard %d is not raised yet (guarded() reads only a raised one)" % i)
		t.check(d._guarded(i), "(but its two escorts guard its bearer from the start)")
		t.check(not d.reserved.has(b), "the bearer is not a wish's person")
	t.check(posts_ok, "each bearer has two escorts, lay citizens dressed as guards")
	t.check(reach_ok, "each escort stands within a pace of his bearer")
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
	d._raise(0)
	t.check(d.steps[0].raised_at == d.steps[0].raised_at and d.broken_count() == 0, "raising it again changes nothing")
	# A bearer fallen at the muster before his time: an escort carries it; with none left, the step breaks at its time.
	var u := _world()
	var du := _bh(u)
	_kill(u, du.bearer(1))
	du._raise(1)
	t.check(du.steps[1].raised and not du.steps[1].broken and du.bearer(1) != null and du.bearer(1) != null and _escorts(du, 1).size() == 1,
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
			same = same and is_equal_approx(e.pace, b.pace)
	t.check(same, "a bearer and his escorts walk at one pace, no faster than the Hunt's (%.2f units a second)" % BreakHuntDirector.BH_BEARER_PACE)
	var apart := true
	var doors: Array = []
	for i in 4:
		doors.append(d._dest[i])
	t.check(doors.size() == 4 and (doors[0] != doors[1] and doors[0] != doors[2] and doors[1] != doors[2]),
		"the first three standards are bound for three different houses (%s)" % [doors])
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
			near_ok = near_ok and g0.post.distance_to(at) <= BreakHuntDirector.BH_FLANK_NEAR + 0.01 and g1.post.distance_to(at) <= BreakHuntDirector.BH_FLANK_NEAR + 0.01
			for j in 4:
				if j == i:
					continue
				for g: HuntDirector.Guard in d.steps[j].party:
					cross_ok = cross_ok and g.post.distance_to(g0.post) > 2.0 * SilentDoom.RADIUS and g.post.distance_to(g1.post) > 2.0 * SilentDoom.RADIUS
			k += 3
		# Back to the muster for the next walk's check.
		_march_to(s, i, d.steps[i].spot)
	t.check(stops > 12 and pair_ok, "at every stop of every walk (%d) the two escorts' posts stand more than 1.6 apart (closest %.2f at %s)" % [stops, worst, worst_where])
	t.check(near_ok, "and within a pace of the bearer")
	t.check(cross_ok, "and more than 1.6 from every other standard's escorts")
	# The escorts are sent to the posts beside him, not left at the muster.
	var d2 := d
	_march_to(s, 0, _road(d2, 0)[_road(d2, 0).size() / 2])
	var e0: Person = _escorts(d2, 0)[0]
	var g0: HuntDirector.Guard = d2.steps[0].party[0]
	t.check(e0.mind == Person.Mind.DUTY and e0.goal().distance_to(g0.post) < 0.6 and g0.post.distance_to(d2.steps[0].spot) > 1.5,
		"each look sends an escort to the post beside the bearer where he now is (%s -> %s)" % [e0.goal(), g0.post])
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
	t.check(not dm._guarded(2), "frail escorts do not guard")
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
	t.check(dr.steps[3].broken and dr.timeline.seconds_to("step_3") >= -1.0, "the fourth breaks; the win needs all four")
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


static func _take_up(t) -> void:
	var s := _world()
	var d := _bh(s)
	_steady(d)
	_raise(s, 0)
	var es := _escorts(d, 0)
	var first: Person = es[0]
	var second: Person = es[1]
	var goal: Vector2 = d.house_doors[d._dest[0]]
	_kill(s, d.bearer(0))
	Kit.run_for(s, LOOK)
	t.check(not d.steps[0].broken and d.bearer(0) != null and (d.bearer(0) == first or d.bearer(0) == second) and (s.banners as Array).has("THE STANDARD IS TAKEN UP"),
		"the bearer killed with escorts by him: an escort takes the standard up (%s)" % [s.banners])
	var up := d.bearer(0)
	var left: HuntDirector.Guard = d.steps[0].party[0]
	t.check(left.post.distance_to(up.ground_pos) <= BreakHuntDirector.BH_FLANK_NEAR, "(the one left is sent to a place beside the new bearer at once)")
	Kit.arrive(left.man, left.post)  # (people do not walk in this world)
	t.check(d.steps[0].party.size() == 1 and (d.steps[0].party[0] as HuntDirector.Guard).man != up and d.took_up_count == 1 and d.hint_phase() == "carried",
		"he is no longer among the escorts; the hint reads 'carried' (%s)" % d.hint_phase())
	t.check(up.badge_glyph == BreakHuntDirector.BH_FLAG and up.goal().distance_to(goal) < 0.6 and d.guarded(0),
		"he carries the pennant and marches on for the same house; his last escort guards him")
	# Taken up again: the last escort carries it.
	_kill(s, up)
	Kit.run_for(s, LOOK)
	var last := d.bearer(0)
	t.check(not d.steps[0].broken and last != null and last != up and d.steps[0].party.is_empty() and d.took_up_count == 2,
		"the new bearer killed too: his last escort takes it up (%d taken up)" % d.took_up_count)
	t.check(not d.guarded(0), "and now no one guards him")
	_kill(s, last)
	Kit.run_for(s, LOOK)
	t.check(d.steps[0].broken and d.bearer(0) == null and d.broken_count() == 1, "he is killed unguarded: the standard is broken at last")
	Kit.done(s)

	# Bearer and one escort killed together: the other takes it up.
	var u := _world()
	var du := _bh(u)
	_steady(du)
	_raise(u, 1)
	var e1: Person = _escorts(du, 1)[0]
	var e2: Person = _escorts(du, 1)[1]
	_kill(u, du.bearer(1))
	_kill(u, e1)
	Kit.run_for(u, LOOK)
	t.check(du.bearer(1) == e2 and not du.steps[1].broken, "bearer and one escort killed in one blow: the other takes it up")
	Kit.done(u)

	# A loud kill: the death frightens the company, so no escort guards and the standard breaks instead of being taken up.
	var l := _world()
	var dl := _bh(l)
	_raise(l, 3)
	_kill(l, dl.bearer(3))
	Kit.run_for(l, LOOK)
	t.check(dl.steps[3].broken and not (l.banners as Array).has("THE STANDARD IS TAKEN UP"),
		"a loud kill frightens his escorts too: none guards, so the standard breaks (the Hunt's rule: a fright counts whoever set it going)")
	Kit.done(l)

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
	t.check(d.taken() == 1 or d._dest[1] != h, "and a taken house is not taken again")
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
	t.check(true, "a second teardown raises no error")
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
