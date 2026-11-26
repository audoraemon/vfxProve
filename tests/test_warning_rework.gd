extends RefCounted
## The Warning rework, T1 (spec 3, 3.1, 7): the WarningDirector's new rules, each a flag that defaults off -- the watchman holds his post until set_off()
## (`holds_post`), a Discord on him there is a stop (`dreams_stop`), a whisper that leads the postern's watchman beyond the wall is let out through
## its key (`lead_key`, K2), and why_not() reads the new reach (the lead, the seal, the dream). One WarningDirector, set by hand.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const ClarityKit := preload("res://tests/clarity_kit.gd")

const POSTERN := Vector2(-5.75, 14.9)
const BEYOND := Vector2(-6.0, 17.4)


static func run(t) -> void:
	_off_by_default(t)
	_post_hold(t)
	_dreamt(t)
	_dreamt_after_set_off(t)
	_dreamt_off(t)
	_key_lead(t)
	_key_lead_off(t)
	_key_lead_evacuation(t)
	_reach(t)
	_reach_off(t)
	_reach_key(t)
	_reach_walls_only(t)
	_omen_body(t)
	_key_fold_fails(t)
	_broken_gain(t)
	_broken_blight(t)
	_broken_keeper(t)
	_broken_off(t)
	_broken_why(t)


## A world for one WarningDirector, `flags` set before it is set up. `at_postern`: its post is the postern's (a barred gate in the unaware town).
static func _world(flags: Dictionary, at_postern := false) -> Dictionary:
	var w := WarningDirector.new()
	for k: String in flags:
		w.set(k, flags[k])
	if at_postern:
		w.post = POSTERN
		w.post_name = "THE POSTERN"
		w.gate_keeps = true
		w.walls_stop = bool(flags.get("walls_stop", true))
	return ClarityKit.world(MissionBook.warning(), w)


## The night's seconds, the people walking too unless `walk` is false (the shared kit leaves them standing: a runner from the Main Gate's post
## walks the road out of the town at once, which the reach cases here do not want).
static func _run(s: Dictionary, seconds: float, walk := true) -> void:
	for i in roundi(seconds / Kit.DT):
		(s.crowd as Crowd).advance(Kit.DT)
		if walk:
			(s.crowd as Crowd).step_people(Kit.DT)
		(s.rules as Rules).advance(Kit.DT)


## Without holds_post the watchman runs at OMEN_AT + STARE, as ever.
static func _off_by_default(t) -> void:
	var s := _world({})
	var w: WarningDirector = s.d
	_run(s, WarningDirector.OMEN_AT + WarningDirector.STARE + 0.4, false)
	t.check(w.phase == WarningDirector.Phase.RUN and w.watchman.mind == Person.Mind.DUTY and w.watchman.stay_left < NightRules.HOLD_STAY,
		"off by default: he runs at the stare's end (%s)" % WarningDirector.Phase.keys()[w.phase])
	t.check(not w.at_post(), "off by default: at_post() is false")
	ClarityKit.done(s)


## With holds_post he never runs before set_off(), however long (the 70 s case, past the 60 s his day would have taken him off); after it he runs.
static func _post_hold(t) -> void:
	var s := _world({"holds_post": true, "quiet_omen": true})
	var w: WarningDirector = s.d
	var man := w.watchman
	_run(s, 70.0)
	t.check(w.omen_fallen and w.phase == WarningDirector.Phase.STARE and w.at_post() and not w.warning_dead,
		"held: 70 s on he still stares at his post (%s)" % WarningDirector.Phase.keys()[w.phase])
	t.check(man.ground_pos.distance_to(w.gate_spot) < 1.5 and man.mind != Person.Mind.DUTY and man.stay_left >= NightRules.HOLD_STAY,
		"held: he stands at his post, off every errand, his stay kept")
	t.check(not (s.banners as Array).has("A STAR FALLS OVER THE MAIN GATE") and not (s.banners as Array).has("STOP THE WARNING"),
		"quiet_omen: the star's banners are not sent")
	w.set_off()
	_run(s, 0.3)
	t.check(w.phase == WarningDirector.Phase.RUN and man.mind == Person.Mind.DUTY and not w.at_post(), "set_off(): he runs")
	var before := w.phase
	w.set_off()
	t.check(w.phase == before, "a second set_off() does nothing")
	ClarityKit.done(s)
	# Nothing to set off unless the warning holds its post.
	s = _world({})
	w = s.d
	w.set_off()
	t.check(w.phase == WarningDirector.Phase.OMEN, "set_off() on a warning that holds no post does nothing")
	ClarityKit.done(s)


## A Discord (the Rules' own cast) on the watchman at his post: he dreamt it.
static func _dreamt(t) -> void:
	var s := _world({"holds_post": true, "dreams_stop": true})
	var w: WarningDirector = s.d
	_run(s, 3.0)
	t.check(w.at_post() and w.phase == WarningDirector.Phase.STARE, "dreamt: the watchman stares at his post")
	var man := w.watchman
	ClarityKit.apply(s, "confuse", man)
	_run(s, 0.1)
	t.check(w.warning_dead and w.stopped_how == "dreamt" and w.phase == WarningDirector.Phase.OVER, "dreamt: the warning stops, 'dreamt' (%s)" % w.stopped_how)
	t.check((s.banners as Array).has(WarningDirector.DREAMT_BANNER), "dreamt: the banner")
	t.check(man.is_alive() and man.mind != Person.Mind.DUTY and man.stay_left < NightRules.HOLD_STAY and w.report().stopped_how == "dreamt",
		"dreamt: he is off duty, his stay no longer held, and the report says so")
	ClarityKit.done(s)


## After set_off() a Discord only pauses the runner.
static func _dreamt_after_set_off(t) -> void:
	var s := _world({"holds_post": true, "dreams_stop": true})
	var w: WarningDirector = s.d
	_run(s, 3.0)
	w.set_off()
	_run(s, 0.3)
	ClarityKit.apply(s, "confuse", w.watchman)
	_run(s, 0.2)
	t.check(not w.warning_dead and w.phase == WarningDirector.Phase.RUN and w.watchman.mind == Person.Mind.CONFUSED,
		"a Discord after set_off() only pauses him (%s)" % w.stopped_how)
	ClarityKit.done(s)


## Without dreams_stop a Discord at the post stops nothing.
static func _dreamt_off(t) -> void:
	var s := _world({"holds_post": true})
	var w: WarningDirector = s.d
	_run(s, 3.0)
	ClarityKit.apply(s, "confuse", w.watchman)
	_run(s, 0.2)
	t.check(not w.warning_dead and w.at_post(), "without dreams_stop a Discord at the post stops nothing")
	ClarityKit.done(s)


## K2: a real Mind Whisper of the postern's watchman to ground beyond the postern takes him out through it, so W1 stops the warning.
static func _key_lead(t) -> void:
	var s := _world({"holds_post": true, "lead_key": true}, true)
	var w: WarningDirector = s.d
	t.check(w.key_door() != Vector2.INF, "K2: the postern is barred and its watchman holds the key")
	_run(s, 0.1)  # (the first step appoints and settles him)
	var man := w.watchman
	s["to"] = BEYOND
	ClarityKit.apply(s, "lead", man)
	t.check(s.took and man.mind == Person.Mind.WHISPERED, "K2: the whisper took him")
	_run(s, 0.2)
	t.check(w.warning_dead and w.stopped_how == "out" and Walls.outside(man.ground_pos), "K2: out through the postern, the warning stopped 'out' (%s)" % w.stopped_how)
	t.check((s.banners as Array).has("THE WATCHMAN UNBARS THE POSTERN"), "K2: the unbarring banner")
	ClarityKit.done(s)
	# From a few steps away: he walks to the inner face first, then goes through.
	s = _world({"holds_post": true, "lead_key": true}, true)
	w = s.d
	_run(s, 0.1)
	man = w.watchman
	var face := w.gate_spot
	Kit.arrive(man, face + Vector2(0.0, -2.5))
	t.check(man.ground_pos.distance_to(w.key_door()) > WarningDirector.KEY_REACH and man.ground_pos.distance_to(w.key_door()) <= WarningDirector.KEY_WALK,
		"K2: he stands past KEY_REACH and within KEY_WALK of the postern")
	s["to"] = BEYOND
	ClarityKit.apply(s, "lead", man)
	_run(s, 0.1)
	t.check(not w.warning_dead and man.mind == Person.Mind.WHISPERED and man.has_goal(), "K2: first he is walked to the inner face")
	_run(s, 4.0)
	t.check(w.warning_dead and w.stopped_how == "out", "K2: then through it, stopped 'out' (%s)" % w.stopped_how)
	ClarityKit.done(s)


## With lead_key off the same whisper takes him round, as ever.
static func _key_lead_off(t) -> void:
	var s := _world({"holds_post": true}, true)
	var w: WarningDirector = s.d
	_run(s, 0.1)
	var man := w.watchman
	s["to"] = BEYOND
	ClarityKit.apply(s, "lead", man)
	_run(s, 0.5)
	t.check(not w.warning_dead and not Walls.outside(man.ground_pos), "lead_key off: he goes round as ever")
	ClarityKit.done(s)


## D30: the town's evacuation never turns the key.
static func _key_lead_evacuation(t) -> void:
	var s := _world({"holds_post": true, "lead_key": true}, true)
	var w: WarningDirector = s.d
	_run(s, 0.1)
	Kit.evacuate(s)
	_run(s, 0.4)
	t.check(not w.warning_dead and not Walls.outside(w.watchman.ground_pos), "D30: an evacuation flee never turns the key")
	ClarityKit.done(s)


## why_not(): the dream, the seal, the lead.
static func _reach(t) -> void:
	var s := _world({"holds_post": true, "dreams_stop": true, "walls_stop": true, "rework_reach": true, "lead_key": false})
	var w: WarningDirector = s.d
	_run(s, 3.0)
	var man := w.watchman
	ClarityKit.assert_read_only(t, s, "warning rework")
	t.check(w.why_not("discord", man.ground_pos) == "", "why_not: Discord at the post says nothing (he dreams it)")
	t.check(w.why_not("noleave", man.ground_pos) == "", "why_not: a seal on a man at his post says nothing (no runner)")
	t.check(w.why_not("discord", Vector2(0.0, 0.0)) == "", "why_not: far away says nothing")
	# Whispered outside the walls: the walls stop him.
	var out := ClarityKit.outside_point(man.ground_pos)
	s["to"] = out
	ClarityKit.apply(s, "lead", man)
	t.check(w.why_not("whisper", s.at) == "", "why_not: a whisper out of the walls says nothing")
	ClarityKit.assert_read_only(t, s, "warning rework, whispered out")
	ClarityKit.done(s)
	s = _world({"holds_post": true, "dreams_stop": true, "walls_stop": true, "rework_reach": true})
	w = s.d
	_run(s, 3.0)
	man = w.watchman
	s["to"] = man.ground_pos + Vector2(1.5, 0.0)
	ClarityKit.apply(s, "lead", man)
	t.check(w.why_not("whisper", s.at) == WarningDirector.STOPS_BANNER, "why_not: a whisper inside the walls says he keeps the warning")
	ClarityKit.done(s)
	# A runner: Discord and the seal only pause him.
	s = _world({"holds_post": true, "dreams_stop": true, "walls_stop": true, "rework_reach": true})
	w = s.d
	_run(s, 3.0, false)
	w.set_off()
	_run(s, 0.3, false)
	man = w.messenger
	t.check(w.why_not("discord", man.ground_pos) == WarningDirector.STOPS_BANNER, "why_not: Discord on a runner says STOPS_BANNER")
	t.check(w.why_not("noleave", man.ground_pos) == WarningDirector.STOPS_BANNER, "why_not: a seal on a runner says STOPS_BANNER")
	ClarityKit.assert_read_only(t, s, "warning rework, a runner")
	ClarityKit.done(s)


## With the flags off why_not reads as it always did: Discord on the watchman and a whisper out both say STOPS_BANNER; a seal says nothing.
static func _reach_off(t) -> void:
	var s := _world({})
	var w: WarningDirector = s.d
	_run(s, 3.0)
	var man := w.watchman
	t.check(w.why_not("discord", man.ground_pos) == WarningDirector.STOPS_BANNER, "flags off: Discord on him says STOPS_BANNER as ever")
	t.check(w.why_not("noleave", man.ground_pos) == "", "flags off: a seal says nothing as ever")
	ClarityKit.done(s)


## K2's why_not: a whisper to ground beyond the postern from within KEY_WALK says nothing; from beyond KEY_WALK it keeps the warning.
static func _reach_key(t) -> void:
	var s := _world({"holds_post": true, "lead_key": true, "rework_reach": true, "walls_stop": false}, true)  # (no walls rule: K2 alone makes it "")
	var w: WarningDirector = s.d
	_run(s, 0.1, false)
	var man := w.watchman
	t.check(man.ground_pos.distance_to(w.key_door()) <= WarningDirector.KEY_WALK, "K2 reach: he stands within KEY_WALK of the postern (%.1f)" % man.ground_pos.distance_to(w.key_door()))
	s["to"] = BEYOND
	ClarityKit.apply(s, "lead", man)
	t.check(w.why_not("whisper", s.at) == "", "why_not: a whisper beyond the postern, within KEY_WALK, says nothing (K2)")
	ClarityKit.done(s)
	s = _world({"holds_post": true, "lead_key": true, "rework_reach": true, "walls_stop": false}, true)  # (no walls rule: K2 alone is judged)
	w = s.d
	_run(s, 0.1, false)
	man = w.watchman
	Kit.arrive(man, w.gate_spot + Vector2(0.0, -5.5))
	t.check(man.ground_pos.distance_to(w.key_door()) > WarningDirector.KEY_WALK, "K2 reach: he stands beyond KEY_WALK")
	s["to"] = BEYOND
	ClarityKit.apply(s, "lead", man)
	t.check(w.why_not("whisper", s.at) == WarningDirector.STOPS_BANNER, "why_not: the same whisper from beyond KEY_WALK keeps the warning")
	ClarityKit.done(s)
	# dreams_stop off: a Discord at the post is only a pause.
	s = _world({"holds_post": true, "walls_stop": true, "rework_reach": true})
	w = s.d
	_run(s, 3.0, false)
	t.check(w.why_not("discord", w.watchman.ground_pos) == WarningDirector.STOPS_BANNER, "why_not: Discord at the post without dreams_stop says STOPS_BANNER")
	ClarityKit.done(s)


## W-R1: a director with walls_stop and no rework flag (Silence the Witness) reads as ever: a seal on a carrier says nothing.
static func _reach_walls_only(t) -> void:
	var s := _world({"walls_stop": true})
	var w: WarningDirector = s.d
	_run(s, 6.5, false)
	var man := w.messenger
	t.check(w.why_not("noleave", man.ground_pos) == "", "walls_stop alone: a seal on a carrier says nothing, as ever")
	s["to"] = man.ground_pos + Vector2(1.5, 0.0)
	ClarityKit.apply(s, "lead", man)
	t.check(w.why_not("whisper", s.at) == WarningDirector.STOPS_BANNER, "walls_stop alone: a whisper keeps the old banner")
	ClarityKit.done(s)


## W3 under holds_post before the star falls: a body outside the gate at once draws him out, and the omen's look-up does not call him back.
static func _omen_body(t) -> void:
	var s := _world({"holds_post": true, "gate_keeps": true, "walls_stop": true, "quiet_omen": true})
	var w: WarningDirector = s.d
	_run(s, 1.0, false)
	t.check(w.phase == WarningDirector.Phase.OMEN and not w.omen_fallen, "W3 early: the star has not fallen yet")
	var g: Person = null
	for p in (s.crowd as Crowd).soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside:
			g = p
			break
	Kit.arrive(g, Vector2(2.7, 17.2))
	g.anchor = g.ground_pos
	(s.field as EnemyField).kill(g, &"lightning", g.ground_pos)
	var m := w.watchman
	t.check(w._drawn_to != Vector2.INF and m.mind == Person.Mind.DUTY, "W3 early: he goes out to the body (%s)" % Person.Mind.keys()[m.mind])
	_run(s, 1.5, false)
	t.check(w.omen_fallen and m.mind == Person.Mind.DUTY and w._drawn_to != Vector2.INF and not m.look_up and w.phase == WarningDirector.Phase.STARE,
		"W3 early: the omen's look-up leaves his walk alone (%s, look_up %s, %s)" % [Person.Mind.keys()[m.mind], m.look_up, WarningDirector.Phase.keys()[w.phase]])
	ClarityKit.done(s)


## W-R15: a fold that finds no ground beyond the postern is tried again KEY_RETRIES times, then the whispered watchman is let go to his whisper's goal, not held at
## the wall. (No real ground fails a fold at the postern -- the landing's nearest open ground may lie inside -- so the failed folds are counted in by hand.)
static func _key_fold_fails(t) -> void:
	var s := _world({"holds_post": true, "lead_key": true}, true)
	var w: WarningDirector = s.d
	_run(s, 0.1, false)
	var man := w.watchman
	s["to"] = BEYOND
	ClarityKit.apply(s, "lead", man)
	w._led_fails = WarningDirector.KEY_RETRIES + 1  # (the fold has found no ground the allowed number of times)
	var at := man.ground_pos
	_run(s, 0.3, false)
	t.check(not w.warning_dead and man.mind == Person.Mind.WHISPERED and man.ground_pos.is_equal_approx(at) and w._led_to == Vector2.INF
		and man.goal().distance_to(BEYOND) < 1.5, "K2 fold fails: after the retries he is let go to his whisper's goal, not held or folded (%s)" % str(man.goal()))
	t.check(w.key_door() != Vector2.INF and w._led_fails == WarningDirector.KEY_RETRIES + 1, "K2 fold fails: and the count stands")
	man.mind = Person.Mind.CALM  # (the whisper wears off: the count starts over for the next one)
	_run(s, 0.1, false)
	t.check(w._led_fails == 0, "K2 fold fails: the count starts over once he is no longer whispered")
	ClarityKit.done(s)
	# One failed fold (the count at the retry limit, not past it) is tried again: the latch is made and the walk to the face is given.
	s = _world({"holds_post": true, "lead_key": true}, true)
	w = s.d
	_run(s, 0.1, false)
	man = w.watchman
	s["to"] = BEYOND
	ClarityKit.apply(s, "lead", man)
	w._led_fails = WarningDirector.KEY_RETRIES
	_run(s, 0.2, false)
	t.check(w.warning_dead and w.stopped_how == "out", "K2 fold fails: at the retry limit he is still taken through (%s)" % w.stopped_how)
	ClarityKit.done(s)


## ---- T2: the broken bell buys time (spec 5, W-R3) --------------------------------------------------------------------------------------------

## A Warning world with the bell broken by `bell_breaks` and a Herald Lantern on its Rules (the Kit worlds carry none).
static func _bell_world(flags: Dictionary) -> Dictionary:
	var s := _world(flags)
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_HERALD)
	(s.rules as Rules).lantern = lw
	s["lw"] = lw
	return s


## A real Blight cast on the bell tower, its effect run to the end by hand (the kit's world has no tree to run it).
static func _blight_bell(s: Dictionary) -> void:
	var tower: Structure = (s.crowd as Crowd).bell.tower
	var fx := ClarityKit.cast_real(s, "blight", tower.center())
	for i in 20:
		fx._process(0.1)
	_run(s, 0.1, false)


## The gain test: from every post of the schedule the broken bell's walk takes at least BROKEN_GAIN longer than the intact chain.
static func _broken_gain(t) -> void:
	var s := _bell_world({"bell_breaks": true})
	var w: WarningDirector = s.d
	for st: Array in StarfallDirector.STARS:
		var post: Vector2 = (s.crowd as Crowd)._grid.nearest_walkable(st[1])
		var intact := w._eta_intact(post)
		var broken := w._eta_broken(post)
		print("  broken-bell gain at %s: intact %.1f s, broken %.1f s (+%.1f)" % [st[2], intact, broken, broken - intact])
		t.check(broken >= intact + WarningDirector.BROKEN_GAIN, "gain: %s: broken %.1f >= intact %.1f + %.0f" % [st[2], broken, intact, WarningDirector.BROKEN_GAIN])
	ClarityKit.done(s)


## Blight on an idle bell breaks it at once: the banner once, a later set-off walks at BROKEN_PACE to the Temple, the Herald is open, and the ETA reads that pace.
static func _broken_blight(t) -> void:
	var s := _bell_world({"bell_breaks": true, "holds_post": true, "quiet_omen": true})
	var w: WarningDirector = s.d
	var tower: Structure = (s.crowd as Crowd).bell.tower
	_run(s, 1.0, false)
	t.check(not w.bell_broken() and not w.heralding() and is_equal_approx(w.carrier_pace(), LanternWatch.HERALD_SLOW), "broken: intact bell, no Herald, the Herald's pace")
	_blight_bell(s)
	_run(s, 0.3, false)
	t.check(tower.blighted and w.bell_broken() and w.heralding(), "broken: a blighted idle bell is broken at once")
	t.check(is_equal_approx(w.carrier_pace(), WarningDirector.BROKEN_PACE), "broken: carrier_pace() is BROKEN_PACE")
	t.check((s.banners as Array).count(WarningDirector.BROKEN_BANNER) == 1, "broken: THE BELL IS BROKEN once")
	_run(s, 1.0, false)
	t.check((s.banners as Array).count(WarningDirector.BROKEN_BANNER) == 1, "broken: ... and not again")
	t.check(not w.herald_open(), "broken: the Herald is not open before the set-off")
	w.set_off()
	_run(s, 0.6, false)
	var m := w.messenger
	t.check(w.herald_open() and m.mind == Person.Mind.DUTY, "broken: after the set-off the Herald is open")
	t.check(is_equal_approx(float(m.statuses.get(&"slow", 1.0)), WarningDirector.BROKEN_PACE), "broken: he walks at BROKEN_PACE (%s)" % str(m.statuses.get(&"slow", 1.0)))
	t.check(m.goal().distance_to(w.lantern_door()) < 1.5, "broken: his goal is the Temple's door")
	var want := TempleReport.walk_seconds(m, w.lantern_door(), WarningDirector.BROKEN_PACE) * (s.rules as Rules).clock_rate
	t.check(absf(w.herald_eta() - want) < 0.01, "broken: herald_eta() uses BROKEN_PACE (%.1f vs %.1f)" % [w.herald_eta(), want])
	t.check(w.herald_label().begins_with("TO THE TEMPLE "), "broken: his tag reads TO THE TEMPLE (%s)" % w.herald_label())
	ClarityKit.done(s)


## The keeper already carrying it walks at BROKEN_PACE with no climb and no descent.
static func _broken_keeper(t) -> void:
	var s := _bell_world({"bell_breaks": true, "holds_post": true, "quiet_omen": true})
	var w: WarningDirector = s.d
	var bell: BellNetwork = (s.crowd as Crowd).bell
	w.messenger = bell.keeper
	w.phase = WarningDirector.Phase.DELIVERED
	_blight_bell(s)
	_run(s, 0.8, false)
	var k := bell.keeper
	t.check(w.herald_open() and w._descend == 0.0, "keeper: carrying it, the Herald is open with no descent")
	t.check(is_equal_approx(float(k.statuses.get(&"slow", 1.0)), WarningDirector.BROKEN_PACE) and k.goal().distance_to(w.lantern_door()) < 1.5,
		"keeper: he walks to the Temple at BROKEN_PACE")
	ClarityKit.done(s)


## bell_breaks off: a blighted tower changes nothing (no Herald before the toll, the old pace).
static func _broken_off(t) -> void:
	var s := _bell_world({})
	var w: WarningDirector = s.d
	(s.env as EnvironmentField).blight((s.crowd as Crowd).bell.tower)
	_run(s, 0.5, false)
	t.check(not w.bell_broken() and not w.heralding() and is_equal_approx(w.carrier_pace(), LanternWatch.HERALD_SLOW), "off: a blighted tower breaks nothing")
	t.check(w.bell_why("blight", (s.crowd as Crowd).bell.tower.center()) == "" and not (s.banners as Array).has(WarningDirector.BROKEN_BANNER), "off: no banner, no bell_why")
	ClarityKit.done(s)


## bell_why: TIME at his post, SOONER for a carrier near the door, TOLLED once the bell has tolled; "" for any other key or structure; read-only.
static func _broken_why(t) -> void:
	var s := _bell_world({"bell_breaks": true})
	var w: WarningDirector = s.d
	var bell: BellNetwork = (s.crowd as Crowd).bell
	var at := bell.tower.center()
	_run(s, 0.5, false)
	t.check(w.bell_why("blight", at) == WarningDirector.BELL_TIME, "bell_why: a watchman at his post: IT ONLY BUYS TIME (%s)" % w.bell_why("blight", at))
	t.check(w.why_not("blight", at) == WarningDirector.BELL_TIME, "why_not carries it")
	t.check(w.bell_why("smite", at) == "" and w.bell_why("blight", at + Vector2(0.0, 12.0)) == "", "bell_why: another key or another place says nothing")
	Kit.arrive(w.messenger, w.lantern_door() + Vector2(0.0, 1.0))
	t.check(w.bell_why("blight", at) == WarningDirector.BELL_SOONER, "bell_why: a carrier at the Temple's door: HE RUNS SOONER (%s)" % w.bell_why("blight", at))
	ClarityKit.assert_read_only(t, s, "warning rework, bell_why")
	(s.lw as LanternWatch).tolled = true
	t.check(w.bell_why("blight", at) == WarningDirector.BELL_TOLLED, "bell_why: THE BELL HAS TOLLED ALREADY")
	ClarityKit.done(s)
