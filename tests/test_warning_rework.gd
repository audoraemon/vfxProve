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


## A world for one WarningDirector, `flags` set before it is set up. `at_postern`: its post is the postern's (a barred gate in the unaware town).
static func _world(flags: Dictionary, at_postern := false) -> Dictionary:
	var w := WarningDirector.new()
	for k: String in flags:
		w.set(k, flags[k])
	if at_postern:
		w.post = POSTERN
		w.post_name = "THE POSTERN"
		w.gate_keeps = true
		w.walls_stop = true
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
	var s := _world({"holds_post": true, "dreams_stop": true, "walls_stop": true, "lead_key": false})
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
	s = _world({"holds_post": true, "dreams_stop": true, "walls_stop": true})
	w = s.d
	_run(s, 3.0)
	man = w.watchman
	s["to"] = man.ground_pos + Vector2(1.5, 0.0)
	ClarityKit.apply(s, "lead", man)
	t.check(w.why_not("whisper", s.at) == WarningDirector.STOPS_BANNER, "why_not: a whisper inside the walls says he keeps the warning")
	ClarityKit.done(s)
	# A runner: Discord and the seal only pause him.
	s = _world({"holds_post": true, "dreams_stop": true, "walls_stop": true})
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
