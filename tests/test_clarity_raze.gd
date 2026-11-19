extends RefCounted
## Mission clarity, the raze group (spec 5.4, 6.4): Spoiled Harvest, The Crown's Bread, The Armoury, The Heart of Faith, Last Judgement and
## Judgement. Every verb a step or hint of a phase names is landed on that phase's target through ClarityKit.apply() (the game's own entry
## points) and the director's own progress is asserted (a guard drops, a target is razed, the rite restarts); every why-not cause is asserted
## with its text and with the same cast far away giving "". A step or hint that names a power is a bug (pre-flight B1, B2, I6, I8).
## A line of the mission's own phase ("") names the whole loop (the guards, then the fall): its verbs are proved where they count.

const ClarityKit := preload("res://tests/clarity_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")

const IDS := ["spoiled_harvest", "crowns_bread", "armoury", "heart_of_faith", "last_judgement", "judgement"]
const FAR := Vector2(300.0, 300.0)


static func run(t) -> void:
	var cases := []
	_harvest(t, cases)
	_bread(t, cases)
	_armoury(t, cases)
	_heart(t, cases)
	_judgement(t, cases)
	_why_harvest(t)
	_why_bread(t)
	_why_armoury(t)
	_why_heart(t)
	ClarityKit.check_coverage(t, PackedStringArray(IDS), cases)
	_fits(t)
	Hud.reset_session()


## `ok` is checked, and a case {id, phase, verb} is recorded for each phase when it holds.
static func _prove(t, cases: Array, id: String, phases: Array, verb: String, ok: bool, msg: String) -> void:
	t.check(ok, "%s [%s] %s: %s" % [id, ", ".join(PackedStringArray(phases)), verb, msg])
	if ok:
		for ph: String in phases:
			cases.append({"id": id, "phase": ph, "verb": verb})


## Every colour word the step and the hint of `phase` name is a tag drawn now.
static func _colours(t, id: String, phase: String, d: MissionDirector) -> void:
	for text in ClarityKit.texts(id, phase):
		ClarityKit.colours_ok(t, d, text, "%s/%s" % [id, phase])


## `verb` landed on `man`: the guards `guards` returns drop by at least him.
static func _drop(t, cases: Array, s: Dictionary, id: String, phases: Array, verb: String, man: Person, guards: Callable) -> void:
	var before: Array = guards.call()
	ClarityKit.apply(s, verb, man)
	var left: Array = guards.call()
	_prove(t, cases, id, phases, verb, before.has(man) and left.size() < before.size() and not left.has(man),
		"a guard leaves his post (%d -> %d, mind %s)" % [before.size(), left.size(), man.mind])


## Runs until `done` holds or `limit` seconds pass, half a second at a time.
static func _until(s: Dictionary, limit: float, done: Callable) -> bool:
	for i in roundi(limit / 0.5):
		if done.call():
			return true
		Kit.run_for(s, 0.5)
	return done.call()


## Strikes `st` until it falls (at most `casts` blows).
static func _fell(s: Dictionary, st: Structure, casts := 60) -> bool:
	for i in casts:
		if st.destroyed:
			return true
		ClarityKit.apply(s, "strike", st)
	return st.destroyed


## A point of `st`'s footprint as far as it can be from every one of `men` (alive or fallen): a bolt there lands on the building and kills no one.
static func _aim(st: Structure, men: Array) -> Vector2:
	var r := st.footprint
	var best := r.get_center()
	var best_d := -1.0
	for i in 5:
		for j in 5:
			var at := r.position + Vector2(r.size.x * float(i) / 4.0, r.size.y * float(j) / 4.0)
			var near := INF
			for m: Variant in men:
				if is_instance_valid(m):
					near = minf(near, at.distance_to((m as Person).ground_pos))
			if near > best_d:
				best_d = near
				best = at
	return best


static func _armed_men(d: ArmouryDirector, i: int) -> Array:
	var out: Array = []
	for a: ArmouryDirector.Armed in d.armed[i]:
		out.append(a.man)
	return out


# --- Spoiled Harvest -------------------------------------------------------------------------------------------------

## Four verbs on the watchmen of granaries `g0` (kill, lead) and `g1` (confuse, scare).
static func _harvest_men(t, cases: Array, s: Dictionary, phases: Array, scare := true) -> void:
	var d: HarvestDirector = s.d
	var g0 := d.targets[0]
	var g1 := d.targets[1]
	var a: Array[Person] = d.guards(g0)
	var b: Array[Person] = d.guards(g1)
	t.check(a.size() == 2 and b.size() == 2, "two watchmen stand at each granary (%d, %d)" % [a.size(), b.size()])
	if a.size() < 2 or b.size() < 2:
		return
	_drop(t, cases, s, "spoiled_harvest", phases, "kill", a[0], func() -> Array: return d.guards(g0))
	_drop(t, cases, s, "spoiled_harvest", phases, "lead", a[1], func() -> Array: return d.guards(g0))
	_drop(t, cases, s, "spoiled_harvest", phases, "confuse", b[1], func() -> Array: return d.guards(g1))
	if scare:
		_drop(t, cases, s, "spoiled_harvest", phases, "scare", b[0], func() -> Array: return d.guards(g1))
	else:
		# A watchman at his post while his granary burns is past fear (HOLD_POST): a fright does not move him, so the copy never says "scare" here.
		ClarityKit.apply(s, "scare", b[0])
		t.check(d.guards(g1).has(b[0]) and not scare, "spoiled_harvest [watchman]: a watchman at a burning granary is not frightened off (mind %s)" % b[0].mind)


static func _harvest(t, cases: Array) -> void:
	var id := "spoiled_harvest"
	# "empty": no grain yet.
	var s := ClarityKit.world(MissionBook.spoiled_harvest())
	var d: HarvestDirector = s.d
	t.check(d.hint_phase() == "empty", "at its start: no grain yet (%s)" % d.hint_phase())
	t.check(d.hint_seconds() > 0.0 and is_equal_approx(d.hint_seconds(), d.step_seconds()), "empty: the hint counts down the step's seconds (%.1f)" % d.hint_seconds())
	_colours(t, id, "empty", d)
	_harvest_men(t, cases, s, ["empty"])
	ClarityKit.assert_read_only(t, s, "harvest (empty)")
	ClarityKit.done(s)

	# "": the grain is in, no fire. Then every route: rot, burn, banish.
	s = ClarityKit.world(MissionBook.spoiled_harvest())
	d = s.d
	for g in d.targets:
		d._deliver(g)
	t.check(d.hint_phase() == "" and d.hint_seconds() == 0.0, "grain in everywhere: the mission's own phase (%s)" % d.hint_phase())
	_colours(t, id, "", d)
	_harvest_men(t, cases, s, [""])
	var g0 := d.targets[0]
	var g1 := d.targets[1]
	var g2 := d.targets[2]
	ClarityKit.apply(s, "rot", g0)
	_prove(t, cases, id, [""], "rot", bool(s.took) and d.razed(g0) and d.spoiled_by.get(g0) == "blight", "an unguarded granary with grain in rots")
	for p in d.guards(g2):
		ClarityKit.apply(s, "kill", p)
	ClarityKit.apply(s, "burn", g2)
	var carter: Person = d.carters[g1][0]
	ClarityKit.apply(s, "banish", carter)
	_until(s, HarvestDirector.SPOIL_SECONDS + 2.0, func() -> bool: return d.razed(g2) and d.razed(g1))
	_prove(t, cases, id, [""], "burn", d.razed(g2), "unguarded, with grain in, it burns down or is spoiled in %d s" % roundi(HarvestDirector.SPOIL_SECONDS))
	_prove(t, cases, id, [""], "banish", d.razed(g1) and d.spoiled_by.get(g1) == "out", "the carter set down outside the walls spoils his granary (%s)" % d.spoiled_by.get(g1))
	ClarityKit.done(s)

	# "watchman": a granary burns under a watchman's eye.
	s = ClarityKit.world(MissionBook.spoiled_harvest())
	d = s.d
	for k in 2:
		d._deliver(d.targets[k])
		ClarityKit.apply(s, "burn", d.targets[k])
	Kit.run_for(s, 0.2)
	t.check(d.hint_phase() == "watchman", "alight under a watchman's eye (%s)" % d.hint_phase())
	_colours(t, id, "watchman", d)
	_harvest_men(t, cases, s, ["watchman"], false)
	ClarityKit.done(s)

	# "burning": the keep-it-burning phase names no verb.
	s = ClarityKit.world(MissionBook.spoiled_harvest())
	d = s.d
	d._deliver(d.targets[0])
	for p in d.guards(d.targets[0]):
		ClarityKit.apply(s, "kill", p)
	ClarityKit.apply(s, "burn", d.targets[0])
	Kit.run_for(s, 0.2)
	t.check(d.hint_phase() == "burning", "alight with no one to put it out (%s)" % d.hint_phase())
	_colours(t, id, "burning", d)
	ClarityKit.done(s)


static func _why_harvest(t) -> void:
	var s := ClarityKit.world(MissionBook.spoiled_harvest())
	var d: HarvestDirector = s.d
	var g0 := d.targets[0]
	var g1 := d.targets[1]
	var g2 := d.targets[2]
	var k := ClarityKit.apply(s, "burn", g0)
	t.check(d.why_not(k, s.at) == "NO GRAIN YET - THE FIRE GOES OUT" and d.why_not(k, FAR) == "", "burn on an empty granary: no grain yet (%s)" % d.why_not(k, s.at))
	d._deliver(g0)
	k = ClarityKit.apply(s, "burn", g0)
	t.check(d.why_not(k, s.at) == "A WATCHMAN (RED) PUTS IT OUT" and d.why_not(k, FAR) == "", "burn with a watchman on guard (%s)" % d.why_not(k, s.at))
	for p in d.guards(g0):
		ClarityKit.apply(s, "kill", p)
	k = ClarityKit.apply(s, "burn", g0)
	t.check(d.why_not(k, s.at) == "", "burn on an unguarded granary with grain counts: no banner")
	t.check(d.why_not("blight", g1.center()) == "", "rot says nothing: Blight's own words are the banner")
	# A lure that took keeps a watchman guarding; one a man on duty refuses says nothing (pre-flight minor 7).
	d._deliver(g1)
	var w: Person = d.guards(g1)[0]
	w.mind = Person.Mind.CALM
	ClarityKit.apply(s, "lure", w)
	t.check(bool(s.took) and w.lured() and d.guards(g1).has(w) and d.why_not("wisp", s.at) == "LURED, HE STILL WATCHES IT" and d.why_not("wisp", FAR) == "",
		"lured, he still watches it (%s)" % d.why_not("wisp", s.at))
	d._deliver(g2)
	var duty: Person = d.guards(g2)[0]
	duty.go_duty(duty.ground_pos)
	ClarityKit.apply(s, "lure", duty)
	t.check(not bool(s.took) and not duty.lured() and d.why_not("wisp", s.at) == "", "a lure a man on duty refused: no banner (took %s)" % s.took)
	# Killing the carter spoils nothing; killing a watchman counts.
	var carter: Person = d.carters[g0][0]
	Kit.arrive(carter, d.doors[g0] + Vector2(6.0, 6.0))
	k = ClarityKit.apply(s, "kill", carter)
	t.check(d.why_not(k, s.at) == "KILLING THE CARTER SPOILS NOTHING" and d.why_not(k, FAR) == "" and not d.razed(g0),
		"killing the carter spoils nothing (%s)" % d.why_not(k, s.at))
	var man: Person = d.guards(g2)[0]
	k = ClarityKit.apply(s, "kill", man)
	t.check(d.why_not(k, s.at) == "", "killing a watchman counts: no banner")
	ClarityKit.assert_read_only(t, s, "harvest (why-not)")
	ClarityKit.done(s)


# --- The Crown's Bread -----------------------------------------------------------------------------------------------

static func _bread_men(t, cases: Array, s: Dictionary, phases: Array, i: int, j: int) -> void:
	var d: CrownsBreadDirector = s.d
	var a: Array[Person] = d.guards(i)
	var b: Array[Person] = d.guards(j)
	t.check(a.size() >= 2 and b.size() >= 2, "engineers stand at the targets (%d, %d)" % [a.size(), b.size()])
	if a.size() < 2 or b.size() < 2:
		return
	var id := "crowns_bread"
	_drop(t, cases, s, id, phases, "kill", a[0], func() -> Array: return d.guards(i))
	_drop(t, cases, s, id, phases, "lead", a[1], func() -> Array: return d.guards(i))
	_drop(t, cases, s, id, phases, "confuse", b[1], func() -> Array: return d.guards(j))
	_drop(t, cases, s, id, phases, "scare", b[0], func() -> Array: return d.guards(j))


static func _bread(t, cases: Array) -> void:
	var id := "crowns_bread"
	# "": far from its time.
	var s := ClarityKit.world(MissionBook.crowns_bread())
	var d: CrownsBreadDirector = s.d
	t.check(d.hint_phase() == "" and d.step_seconds() > 0.0, "at its start: not in use, the wait counts (%s)" % d.hint_phase())
	_colours(t, id, "", d)
	_bread_men(t, cases, s, [""], 0, 1)
	ClarityKit.assert_read_only(t, s, "bread (start)")
	ClarityKit.done(s)

	# "not_yet": within WORK_AHEAD of its time.
	s = ClarityKit.world(MissionBook.crowns_bread())
	d = s.d
	Kit.run_for(s, float(CrownsBreadDirector.STAGE_AT[0]) - CrownsBreadDirector.WORK_AHEAD + 1.0)
	t.check(d.hint_phase() == "not_yet", "within %d s of its time (%s)" % [roundi(CrownsBreadDirector.WORK_AHEAD), d.hint_phase()])
	_colours(t, id, "not_yet", d)
	_bread_men(t, cases, s, ["not_yet"], 0, 1)
	ClarityKit.done(s)

	# "engineers": in use, the crew on guard.
	s = ClarityKit.world(MissionBook.crowns_bread())
	d = s.d
	Kit.run_for(s, float(CrownsBreadDirector.STAGE_AT[0]) + 1.0)
	t.check(d.in_use[0] and d.hint_phase() == "engineers", "in use with its crew on guard (%s)" % d.hint_phase())
	_colours(t, id, "engineers", d)
	var crew: Array[Person] = d.guards(0)
	if crew.size() >= 4:
		_drop(t, cases, s, id, ["engineers"], "kill", crew[0], func() -> Array: return d.guards(0))
		_drop(t, cases, s, id, ["engineers"], "lead", crew[1], func() -> Array: return d.guards(0))
		_drop(t, cases, s, id, ["engineers"], "confuse", crew[2], func() -> Array: return d.guards(0))
		_drop(t, cases, s, id, ["engineers"], "scare", crew[3], func() -> Array: return d.guards(0))
	else:
		t.check(false, "four engineers stand guard at the granary in use (%d)" % crew.size())
	ClarityKit.done(s)

	# "open": no engineer stands. Burn the granary, then strike the mill when it comes into use.
	s = ClarityKit.world(MissionBook.crowns_bread())
	d = s.d
	Kit.run_for(s, float(CrownsBreadDirector.STAGE_AT[0]) + 1.0)
	for p in d.guards(0):
		ClarityKit.apply(s, "kill", p)
	t.check(d.hint_phase() == "open", "no engineer stands (%s)" % d.hint_phase())
	_colours(t, id, "open", d)
	ClarityKit.apply(s, "burn", d.targets[0])
	_until(s, 20.0, func() -> bool: return d.razed(d.targets[0]))
	_prove(t, cases, id, ["", "open"], "burn", d.razed(d.targets[0]), "burned with no engineer on guard, the granary is razed")
	_until(s, CrownsBreadDirector.CHAIN + 2.0, func() -> bool: return d.in_use[1])
	for p in d.guards(1):
		ClarityKit.apply(s, "kill", p)
	var mill := d.targets[1]
	t.check(d.in_use[1] and d.hint_phase() == "open", "the next target in use, unguarded (%s)" % d.hint_phase())
	var fell := _fell(s, mill)
	Kit.run_for(s, 1.0)
	_prove(t, cases, id, ["", "open"], "strike", fell and d.razed(mill), "struck down with no engineer on guard, the mill is razed")
	ClarityKit.done(s)


static func _why_bread(t) -> void:
	var s := ClarityKit.world(MissionBook.crowns_bread())
	var d: CrownsBreadDirector = s.d
	var granary := d.targets[0]
	var bridge := d.targets[2]
	t.check(d.guards(0).size() >= 2 and bridge == (s.town as Town).bridge, "its night crew stands at the granary")
	var k := ClarityKit.apply(s, "burn", bridge)
	t.check(d.why_not(k, s.at) == "STONE - STRIKE IT, FIRE DOES NOTHING" and d.why_not(k, FAR) == "", "burn on the bridge (%s)" % d.why_not(k, s.at))
	k = ClarityKit.apply(s, "burn", granary)
	t.check(d.why_not(k, s.at) == "AN ENGINEER (RED) MENDS IT" and d.why_not(k, FAR) == "", "burn with an engineer on guard (%s)" % d.why_not(k, s.at))
	var crew: Array = []
	for c: CrownsBreadDirector.Crew in d.crews[0]:
		crew.append(c.man)
	k = ClarityKit.apply(s, "strike", _aim(granary, crew), "smite")
	t.check(d.why_not(k, s.at) == "AN ENGINEER (RED) MENDS IT" and d.why_not(k, FAR) == "", "strike with an engineer on guard (%s)" % d.why_not(k, s.at))
	var man: Person = d.guards(0)[0] if not d.guards(0).is_empty() else null
	if man != null:
		ClarityKit.apply(s, "lure", man)
		t.check(not bool(s.took) or d.why_not("wisp", s.at) == "LURED, HE STILL MENDS IT", "a lure that took him: he still mends it (took %s)" % s.took)
	for p in d.guards(0):
		ClarityKit.apply(s, "kill", p)
	k = ClarityKit.apply(s, "burn", granary)
	t.check(d.why_not(k, s.at) == "", "burn with no engineer on guard: no banner")
	ClarityKit.assert_read_only(t, s, "bread (why-not)")
	ClarityKit.done(s)


# --- The Armoury -----------------------------------------------------------------------------------------------------

static func _armoury_men(t, cases: Array, s: Dictionary, phases: Array, verbs: Array, i: int) -> void:
	var d: ArmouryDirector = s.d
	var men: Array[Person] = d.guards(i)
	t.check(men.size() >= verbs.size(), "armed men stand guard (%d for %d verbs)" % [men.size(), verbs.size()])
	if men.size() < verbs.size():
		return
	for k in verbs.size():
		_drop(t, cases, s, "armoury", phases, String(verbs[k]), men[k], func() -> Array: return d.guards(i))


static func _armoury(t, cases: Array) -> void:
	var id := "armoury"
	# "": before the horn, far from it.
	var s := ClarityKit.world(MissionBook.armoury())
	var d: ArmouryDirector = s.d
	t.check(d.hint_phase() == "" and d.step_seconds() > 0.0, "at its start: not mustering, the wait counts (%s)" % d.hint_phase())
	t.check(d.hint_seconds() == 0.0, "no countdown in the hint outside not_yet")
	_colours(t, id, "", d)
	_armoury_men(t, cases, s, [""], ["kill"], 0)
	ClarityKit.assert_read_only(t, s, "armoury (start)")
	ClarityKit.done(s)

	# "not_yet": within WORK_AHEAD of the horn.
	s = ClarityKit.world(MissionBook.armoury())
	d = s.d
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]) - ArmouryDirector.WORK_AHEAD + 1.0)
	t.check(d.hint_phase() == "not_yet" and d.hint_seconds() > 0.0 and is_equal_approx(d.hint_seconds(), d.step_seconds()),
		"within %d s of its horn: the hint counts the wait (%s, %.1f)" % [roundi(ArmouryDirector.WORK_AHEAD), d.hint_phase(), d.hint_seconds()])
	_colours(t, id, "not_yet", d)
	_armoury_men(t, cases, s, ["not_yet"], ["kill", "hold"], 0)
	ClarityKit.done(s)

	# "guarded", then the whole chain: open (burn), stone (strike), open (strike).
	s = ClarityKit.world(MissionBook.armoury())
	d = s.d
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]) + 1.0)
	t.check(d.mustering[0] and d.hint_phase() == "guarded", "after the horn, armed men on guard (%s)" % d.hint_phase())
	_colours(t, id, "guarded", d)
	_armoury_men(t, cases, s, ["guarded"], ["kill", "hold"], 0)
	for p in d.guards(0):
		ClarityKit.apply(s, "kill", p)
	Kit.run_for(s, ArmouryDirector.TICK * 2.0)
	t.check(d.hint_phase() == "open", "no one on guard (%s)" % d.hint_phase())
	_colours(t, id, "open", d)
	ClarityKit.apply(s, "burn", d.targets[0])
	_until(s, ArmouryDirector.SPOIL_SECONDS + 3.0, func() -> bool: return d.razed(d.targets[0]))
	_prove(t, cases, id, ["open"], "burn", d.razed(d.targets[0]), "burned with no armed man on guard, the north barracks is razed")
	_until(s, ArmouryDirector.CHAIN + 3.0, func() -> bool: return d.mustering[1])
	for p in d.guards(1):
		ClarityKit.apply(s, "kill", p)
	Kit.run_for(s, ArmouryDirector.TICK * 2.0)
	t.check(d.mustering[1] and d.hint_phase() == "stone", "the gate barracks musters, unguarded: stone (%s)" % d.hint_phase())
	_colours(t, id, "stone", d)
	var gate := d.targets[1]
	var fell := _fell(s, gate)
	Kit.run_for(s, 1.0)
	_prove(t, cases, id, ["stone"], "strike", fell and d.razed(gate), "the stone barracks falls to blows")
	_until(s, ArmouryDirector.CHAIN + 3.0, func() -> bool: return d.mustering[2])
	for p in d.guards(2):
		ClarityKit.apply(s, "kill", p)
	Kit.run_for(s, ArmouryDirector.TICK * 2.0)
	t.check(d.mustering[2] and d.hint_phase() == "open", "the armoury musters, unguarded (%s)" % d.hint_phase())
	var arms := d.targets[2]
	fell = _fell(s, arms)
	Kit.run_for(s, 1.0)
	_prove(t, cases, id, ["open"], "strike", fell and d.razed(arms), "struck down with no armed man on guard, the armoury is razed")
	ClarityKit.done(s)


static func _why_armoury(t) -> void:
	var s := ClarityKit.world(MissionBook.armoury())
	var d: ArmouryDirector = s.d
	var north := d.targets[0]
	var gate := d.targets[1]
	var k := ClarityKit.apply(s, "burn", north)
	t.check(d.why_not(k, s.at) == "NOT MUSTERING - IT TAKES NO HARM" and d.why_not(k, FAR) == "", "burn before the horn (%s)" % d.why_not(k, s.at))
	k = ClarityKit.apply(s, "strike", _aim(gate, _armed_men(d, 1)), "smite")
	t.check(d.why_not(k, s.at) == "NOT MUSTERING - IT TAKES NO HARM", "strike before the horn (%s)" % d.why_not(k, s.at))
	ClarityKit.apply(s, "strike", gate)
	t.check(d.why_not("smite", s.at) == "" or d.why_not("smite", s.at) == "NOT MUSTERING - IT TAKES NO HARM", "a bolt on his own men may have killed one: silent or the reason")
	d._muster(0)
	d._muster(1)
	Kit.run_for(s, 3.0)
	k = ClarityKit.apply(s, "burn", north)
	t.check(not d.guards(0).is_empty() and d.why_not(k, s.at) == "ARMED MEN (RED) GUARD IT", "burn with armed men on guard (%s)" % d.why_not(k, s.at))
	for p in d.guards(1):
		ClarityKit.apply(s, "kill", p)
	k = ClarityKit.apply(s, "burn", gate)
	t.check(d.why_not(k, s.at) == "STONE - STRIKE IT, FIRE DOES NOTHING" and d.why_not(k, FAR) == "", "burn on the stone barracks (%s)" % d.why_not(k, s.at))
	for p in d.guards(0):
		ClarityKit.apply(s, "kill", p)
	k = ClarityKit.apply(s, "burn", north)
	t.check(d.why_not(k, s.at) == "", "burn on an unguarded mustering barracks counts: no banner (%s)" % d.why_not(k, s.at))
	ClarityKit.assert_read_only(t, s, "armoury (why-not)")
	ClarityKit.done(s)


# --- The Heart of Faith ----------------------------------------------------------------------------------------------

static func _knights(t, cases: Array, s: Dictionary, phases: Array, verbs: Array, i: int) -> void:
	var d: HeartOfFaithDirector = s.d
	var men: Array[Person] = d.guards_at(i)
	t.check(men.size() >= verbs.size(), "Knights stand guard (%d for %d verbs)" % [men.size(), verbs.size()])
	if men.size() < verbs.size():
		return
	for k in verbs.size():
		_drop(t, cases, s, "heart_of_faith", phases, String(verbs[k]), men[k], func() -> Array: return d.guards_at(i))


static func _heart_world() -> Dictionary:
	return ClarityKit.world(MissionBook.heart_of_faith())


static func _heart(t, cases: Array) -> void:
	var id := "heart_of_faith"
	# "": far from the oil-house's time.
	var s := _heart_world()
	var d: HeartOfFaithDirector = s.d
	t.check(d.hint_phase() == "", "at its start (%s)" % d.hint_phase())
	_colours(t, id, "", d)
	_knights(t, cases, s, [""], ["kill"], 0)
	ClarityKit.assert_read_only(t, s, "heart (start)")
	ClarityKit.done(s)

	# "not_yet".
	s = _heart_world()
	d = s.d
	Kit.run_for(s, float(HeartOfFaithDirector.STAGE_AT[0]) - HeartOfFaithDirector.WORK_AHEAD + 1.0)
	t.check(d.hint_phase() == "not_yet" and d.step_seconds() > 0.0, "within %d s of its time (%s)" % [roundi(HeartOfFaithDirector.WORK_AHEAD), d.hint_phase()])
	_colours(t, id, "not_yet", d)
	_knights(t, cases, s, ["not_yet"], ["kill", "hold"], 0)
	ClarityKit.done(s)

	# "guarded", "open", "burning".
	s = _heart_world()
	d = s.d
	Kit.run_for(s, float(HeartOfFaithDirector.STAGE_AT[0]) + 1.0)
	t.check(d.in_use[0] and d.hint_phase() == "guarded", "in use, a Knight on guard (%s)" % d.hint_phase())
	_colours(t, id, "guarded", d)
	_knights(t, cases, s, ["guarded"], ["kill", "hold"], 0)
	for p in d.guards_at(0):
		ClarityKit.apply(s, "kill", p)
	t.check(d.hint_phase() == "open", "no Knight on guard (%s)" % d.hint_phase())
	_colours(t, id, "open", d)
	ClarityKit.apply(s, "burn", d.oil_house)
	Kit.run_for(s, 1.0)
	t.check(d.hint_phase() == "burning", "alight (%s)" % d.hint_phase())
	_colours(t, id, "burning", d)
	_until(s, float(HeartOfFaithDirector.SPOIL[0]) + 3.0, func() -> bool: return d.razed(d.oil_house))
	_prove(t, cases, id, ["", "open"], "burn", d.razed(d.oil_house), "burned with no Knight on guard, the oil-house is razed")
	ClarityKit.done(s)

	# Stage two: "coming" (bearers at the gate), "litter", "on_foot", "rite".
	s = _heart_world()
	d = s.d
	d._open(0)
	d._raze(d.targets[0])
	d._open(1)
	d._raze(d.targets[1])
	Kit.run_for(s, 0.2)
	t.check(d.hint_phase() == "coming" and d.hint_seconds() > 0.0, "the flame is out: Odran is coming (%s)" % d.hint_phase())
	_colours(t, id, "coming", d)
	var bearers: Array[Person] = d.bearers_standing()
	var before := bearers.size()
	ClarityKit.apply(s, "kill", bearers[0])
	_prove(t, cases, id, ["coming"], "kill", d.bearers_standing().size() < before, "a bearer falls (%d -> %d)" % [before, d.bearers_standing().size()])
	d._odran_comes()
	Kit.run_for(s, 1.0)
	t.check(d.riding and d.hint_phase() == "litter", "he rides in his litter (%s)" % d.hint_phase())
	_colours(t, id, "litter", d)
	for p in d.bearers_standing():
		if d.riding:
			ClarityKit.apply(s, "kill", p)
	Kit.run_for(s, HeartOfFaithDirector.TICK + 0.1)
	_prove(t, cases, id, ["litter"], "kill", not d.riding and d.hint_phase() == "on_foot", "with fewer than two bearers the litter falls (%s)" % d.hint_phase())
	_colours(t, id, "on_foot", d)
	var odran := d.odran as Person
	ClarityKit.apply(s, "kill", odran)
	Kit.run_for(s, 0.1)
	_prove(t, cases, id, ["on_foot"], "kill", d.odran_down(), "Odran on foot dies")
	ClarityKit.done(s)

	_rite(t, cases)


## "rite": his rekindling restarts on a fright, a whisper or a Discord; his death ends it.
static func _rite(t, cases: Array) -> void:
	var id := "heart_of_faith"
	for verb: String in ["lead", "confuse", "scare", "kill"]:
		var s := _heart_world()
		var d: HeartOfFaithDirector = s.d
		d._open(0)
		d._raze(d.targets[0])
		d._open(1)
		d._raze(d.targets[1])
		Kit.run_for(s, 0.2)
		for p: HeartOfFaithDirector.Post in d.bearers:
			Kit.free_body(s, p.man)
		d._odran_comes()
		var o := d.odran as Person
		Kit.arrive(o, d.steps_at)
		d._road_at = d._road.size() - 1
		o.go_duty(d.steps_at)
		Kit.run_for(s, 4.0)
		t.check(d.rite_on and d.hint_phase() == "rite", "he rekindles the flame (%s)" % d.hint_phase())
		if verb == "lead":
			t.check(d.hint_seconds() > 0.0 and is_equal_approx(d.hint_seconds(), d.step_seconds()), "rite: the hint counts the rite's seconds (%.1f)" % d.hint_seconds())
			_colours(t, id, "rite", d)
		var left := d.rite_left
		ClarityKit.apply(s, verb, o)
		if verb == "kill":
			Kit.run_for(s, 0.1)
			_prove(t, cases, id, ["rite"], verb, d.odran_down(), "Odran dies at the altar")
		else:
			# Restarted: the flame's seconds are back to RITE, however long he stands there again.
			Kit.run_for(s, 0.3)
			var restarted := d.rite_left > left or not d.rite_on
			_prove(t, cases, id, ["rite"], verb, restarted, "the rekindling starts again (%.1f -> %.1f, on %s, mind %s)" % [left, d.rite_left, d.rite_on, o.mind])
		ClarityKit.done(s)


static func _why_heart(t) -> void:
	var s := _heart_world()
	var d: HeartOfFaithDirector = s.d
	var k := ClarityKit.apply(s, "burn", d.oil_house)
	t.check(d.why_not(k, s.at) == "NOT IN USE - THE FIRE GOES OUT" and d.why_not(k, FAR) == "", "burn before its time (%s)" % d.why_not(k, s.at))
	d._open(0)
	Kit.run_for(s, 2.0)
	k = ClarityKit.apply(s, "burn", d.oil_house)
	t.check(not d.guards_at(0).is_empty() and d.why_not(k, s.at) == "A KNIGHT (RED) PUTS IT OUT", "burn with a Knight on guard (%s)" % d.why_not(k, s.at))
	var knights: Array = []
	for p: HeartOfFaithDirector.Post in d.posts:
		knights.append(p.man)
	k = ClarityKit.apply(s, "strike", _aim(d.oil_house, knights), "smite")
	t.check(d.why_not(k, s.at) == "A KNIGHT (RED) PUTS IT OUT", "strike with a Knight on guard (%s)" % d.why_not(k, s.at))
	ClarityKit.assert_read_only(t, s, "heart (why-not)")
	ClarityKit.done(s)

	s = _heart_world()
	d = s.d
	d._open(0)
	d._raze(d.targets[0])
	d._open(1)
	d._raze(d.targets[1])
	Kit.run_for(s, 0.2)
	d._odran_comes()
	Kit.run_for(s, 1.0)
	t.check(d.riding, "he rides in his litter")
	var litter := d.litter_at
	for key: String in ["doom", "ember", "whisper"]:
		t.check(d.why_not(key, litter) == "IN HIS LITTER - KILL HIS BEARERS" and d.why_not(key, FAR) == "", "a %s on the litter (%s)" % [key, d.why_not(key, litter)])
	var b: Person = d.bearers_standing()[0]
	t.check(d.why_not("doom", b.ground_pos) == "", "a kill on a bearer counts: no banner")
	ClarityKit.assert_read_only(t, s, "heart (litter)")
	ClarityKit.done(s)


# --- Last Judgement and Judgement ------------------------------------------------------------------------------------

static func _judgement(t, cases: Array) -> void:
	var s := ClarityKit.world(MissionBook.last_judgement())
	var d: MissionDirector = s.d
	var town: Town = s.town
	var citadel := town.citadel
	var ids := ["last_judgement", "judgement"]
	t.check(d.hint_phase() == "", "at its start (%s)" % d.hint_phase())
	for id in ids:
		_colours(t, id, "", d)
	var health := citadel.health
	ClarityKit.apply(s, "strike", citadel.keep)
	for id in ids:
		_prove(t, cases, id, [""], "strike", citadel.health < health, "a blow on the Citadel wears its health down (%.0f -> %.0f)" % [health, citadel.health])
	ClarityKit.assert_read_only(t, s, "last judgement (start)")
	ClarityKit.done(s)

	# "rite": the clergy chant on the steps.
	s = ClarityKit.world(MissionBook.last_judgement())
	d = s.d
	var crowd: Crowd = s.crowd
	crowd.raise_profile(ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED))
	var rite := crowd.rite
	t.check(rite.state != BanishingRite.State.ENDED, "this town holds the rite (%s)" % rite.state)
	if rite.state != BanishingRite.State.ENDED:
		var clergy := _chant(s, rite)
		t.check(d.hint_phase() == "rite", "the clergy chant (%s)" % d.hint_phase())
		for id in ids:
			_colours(t, id, "rite", d)
		var before := rite.in_ring()
		ClarityKit.apply(s, "kill", clergy[0])
		for id in ids:
			_prove(t, cases, id, ["rite"], "kill", rite.in_ring() < before, "a cleric killed leaves the ring (%d -> %d)" % [before, rite.in_ring()])
		before = rite.in_ring()
		ClarityKit.apply(s, "scare", clergy[1])
		for id in ids:
			_prove(t, cases, id, ["rite"], "scare", rite.in_ring() < before, "a cleric frightened leaves the ring (%d -> %d)" % [before, rite.in_ring()])
		rite.step(0.1)
		var cathedral := rite.cathedral
		var hp := cathedral.hp
		_chant(s, rite)
		for i in 40:
			if cathedral.hp < cathedral.max_hp * BanishingRite.MIN_HP:
				break
			ClarityKit.apply(s, "strike", cathedral)
		for id in ids:
			_prove(t, cases, id, ["rite"], "strike", cathedral.hp < hp and (cathedral.hp < cathedral.max_hp * BanishingRite.MIN_HP or cathedral.destroyed),
				"strikes on the cathedral take it under %d%% (%.0f -> %.0f of %.0f)" % [roundi(BanishingRite.MIN_HP * 100.0), hp, cathedral.hp, cathedral.max_hp])
	ClarityKit.done(s)

	# "fallen": kills and ruin break the city's stability.
	s = ClarityKit.world(MissionBook.last_judgement())
	d = s.d
	town = s.town
	town.citadel._fall(town.citadel.keep.center(), &"smite")
	Kit.run_for(s, 0.2)
	t.check(d.hint_phase() == "fallen", "the Citadel is down (%s)" % d.hint_phase())
	for id in ids:
		_colours(t, id, "fallen", d)
	var rules: Rules = s.rules
	var stable := rules.stability
	stable.measure(s.env, s.crowd, town.citadel)
	var pop := stable.population
	var victim: Person = (s.crowd as Crowd).citizens[0]
	ClarityKit.apply(s, "kill", victim)
	stable.measure(s.env, s.crowd, town.citadel)
	for id in ids:
		_prove(t, cases, id, ["fallen"], "kill", stable.population < pop, "a death lowers the city's population part (%.3f -> %.3f)" % [pop, stable.population])
	var infra := stable.infrastructure
	var house: Structure = null
	for st: Structure in (s.env as EnvironmentField).structures():
		if st.role == &"house" and not st.destroyed:
			house = st
			break
	ClarityKit.apply(s, "burn", house)
	_until(s, 25.0, func() -> bool: return house.destroyed)
	stable.measure(s.env, s.crowd, town.citadel)
	for id in ids:
		_prove(t, cases, id, ["fallen"], "burn", house.destroyed and stable.infrastructure < infra, "a house burned down lowers the infrastructure part (%.3f -> %.3f)" % [infra, stable.infrastructure])
	ClarityKit.done(s)
	t.check(JudgementDirector.new().hint_phases() == LastJudgementDirector.new().hint_phases(), "Judgement has Last Judgement's phases")


## The clergy gathered in their places and chanting; returns them.
static func _chant(s: Dictionary, rite: BanishingRite) -> Array[Person]:
	if rite.state == BanishingRite.State.IDLE:
		rite.begin()
	for e in rite.circle:
		Kit.arrive(e[0] as Person, e[1])
	Kit.run_for(s, 0.3)
	var out: Array[Person] = []
	for e in rite.circle:
		out.append(e[0] as Person)
	return out


# --- Fit ----------------------------------------------------------------------------------------------------------------

## Each of this group's lines, its countdown filled with the widest number, still fits the plate.
static func _fits(t) -> void:
	var long := PackedStringArray()
	for key: String in MissionHints.LINES:
		var id := key.get_slice(".", 0)
		if not id in IDS:
			continue
		if UiTheme.wrap(MissionHints.filled(String(MissionHints.LINES[key]), 999.0), Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
			long.append(key)
	t.check(long.is_empty(), "every raze line fits %d lines with its countdown filled with 999 (%s)" % [Hud.HINT_LINES, ", ".join(long)])
