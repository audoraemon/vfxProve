extends RefCounted
## The board's Warning (v0.11 M1, reworked: spec 2, 6): three watchmen at three posts from 0:00 (each a WarningDirector set up on the first step),
## one star over the town at OMEN_AT, each watchman sets off at 0:20, 0:40 and 1:00 (mission seconds); all three stopped wins, a Herald in loses; the
## watchmen's tags, phases and tour. The campaign's Warning keeps one star over the Main Gate.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_stars(t)
	_omen_once(t)
	_set_offs(t)
	_rate(t)
	_phases(t)
	_main_gate_runs(t)
	_broken_mid_climb(t)
	_broken_banner_once(t)
	_bell_why_all(t)
	_bell(t)
	_forced(t)
	_runners(t)
	_runners_freed(t)
	_single(t)
	_out_stops(t)
	_out_staring(t)
	_out_herald(t)
	_out_relay(t)
	_lie_stops(t)
	_lie_rope(t)
	_lie_over(t)
	_lie_tag(t)
	_flags_and_report(t)
	_gate_body(t)
	_gate_body_not(t)
	_gate_body_postern(t)
	_key_fright(t)
	_key_only_his(t)
	_lie_calls_off(t)
	_lie_tolled_stays(t)
	_dreamt_report(t)
	_key_other_goal(t)
	_lie_calls_off_waiting(t)
	_gate_body_far(t)
	_hint_running(t)
	_key_evacuation(t)


static func _world() -> Dictionary:
	var def := TierBook.board("warning")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := def.make_director().setup(rules, crowd, town, null) as StarfallDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


## The tags labelled `label`.
static func _labelled(d: MissionDirector, label: String) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for m in d.tags():
		if m.label == label:
			out.append(m)
	return out


static func _stars(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var rules: Rules = s.rules
	t.check(d.stars.size() == 3 and d.stars[0].rules == null and d.stopped() == 0 and d.hint_phase() == "posts",
		"three warnings, none set up before the first step; the board never says nothing")
	var stops := d.tour()
	t.check(stops.size() == 5 and String(stops[0][1]) == "The Postern's watchman. He sets off for the bellkeeper at 0:20."
		and String(stops[1][1]) == "The Main Gate's watchman. He sets off for the bellkeeper at 0:40."
		and String(stops[2][1]) == "The Side Gate's watchman. He sets off for the bellkeeper at 1:00.",
		"the tour: the three posts with their set-off times (%s)" % [stops.map(func(x: Array) -> String: return x[1])])
	t.check(String(stops[3][1]) == "The bellkeeper. Warned, he rings the bell: the Lantern turns, and he runs for the Temple."
		and String(stops[4][1]) == "The Temple. A warning that reaches it loses the night.", "then the bellkeeper and the Temple's door")
	t.check(rules.objectives[0].hud_text(rules) == "Warnings stopped 0 / 3", "the HUD counts them")
	_run(s, DT)
	var men: Array[Person] = []
	var at_posts := true
	for i in 3:
		var w := d.stars[i]
		at_posts = at_posts and w.rules != null and is_instance_valid(w.watchman) and w.at_post() \
			and w.watchman.ground_pos.distance_to(StarfallDirector.STARS[i][1]) < 1.5 and not men.has(w.watchman)
		men.append(w.watchman)
	t.check(at_posts, "from the first step all three watchmen are appointed, each at his own post, three different men")
	t.check(_labelled(d, "WATCHMAN - SETS OFF IN 0:20").size() == 1 and _labelled(d, "WATCHMAN - SETS OFF IN 0:40").size() == 1
		and _labelled(d, "WATCHMAN - SETS OFF IN 1:00").size() == 1, "the three countdown tags: 0:20, 0:40 and 1:00 (%s)" % [d.tags().map(func(m: MapTag) -> String: return m.label)])
	var tag := _labelled(d, "WATCHMAN - SETS OFF IN 0:20")[0]
	t.check(tag.edge and tag.who == d.stars[0].watchman and tag.color == WarningDirector.MARK_MESSENGER, "a gold edge arrow on the watchman himself")
	_run(s, 3.5)
	t.check(_labelled(d, "WATCHMAN - SETS OFF IN 0:17").size() == 1 and _labelled(d, "WATCHMAN - SETS OFF IN 0:57").size() == 1, "and they count down (0:17, 0:57)")
	t.check(_labelled(d, "BELLKEEPER").size() == 1 and _labelled(d, "BELL TOWER").size() == 1 and _labelled(d, "TEMPLE").size() == 1,
		"the bellkeeper, the bell tower and the Temple's door once each, not once per warning (%s)" % [d.tags().map(func(m: MapTag) -> String: return m.label)])
	t.check(d.step_seconds() > 16.0 and d.step_seconds() <= 16.5, "step_seconds is the soonest set-off still to come (%.2f)" % d.step_seconds())
	for i in 3:
		d.stars[i].warning_dead = true
		d.stars[i].phase = WarningDirector.Phase.OVER
		_run(s, DT)
	t.check(rules.finished and rules.won and rules.over_reason == "warning" and d.report().stopped == 3 and d.step_seconds() == 0.0,
		"all three stopped: won at that instant, long before any clock (%s)" % rules.over_reason)
	_done(s)
	_win_waits_for_the_word(t)

## Two warnings stopped and the third seen to die: a witness carries the word, so nothing is won until he is stopped too, and then at that instant.
static func _win_waits_for_the_word(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	_run(s, 2.0)
	for i in 2:
		d.stars[i].warning_dead = true
		d.stars[i].phase = WarningDirector.Phase.OVER
	var last := d.stars[2]
	var m := last.messenger
	var witness: Person = null
	for p in crowd.citizens:
		if p != m and p != crowd.bell.keeper and p.profile != null and p.profile.role == CitizenProfile.Role.RESIDENT:
			witness = p
			break
	_clear_round(s, m.ground_pos, [m, witness])
	witness.ground_pos = m.ground_pos + Vector2(1.0, 0.0)
	(s.field as EnemyField).kill(m, &"doom", m.ground_pos)  # (seen: the witness carries the warning on)
	_run(s, 0.3)
	t.check(not last.warning_dead and last.relays == 1 and last.messenger == witness and d.stopped() == 2 and not rules.finished,
		"two stopped, the third passed on to a witness: the word lives, nothing is won (%d stopped, finished %s)" % [d.stopped(), rules.finished])
	_run(s, 2.0)
	t.check(not rules.finished, "and none is won while he still carries it")
	_clear_round(s, witness.ground_pos, [witness])
	(s.field as EnemyField).kill(witness, &"doom", witness.ground_pos)  # (unseen)
	_run(s, 0.3)
	t.check(last.warning_dead and rules.finished and rules.won and rules.over_reason == "warning", "the witness killed unseen: won at that instant (%s)" % rules.over_reason)
	_done(s)


## The one star (W-R13: mission seconds): at OMEN_AT, one pair of banners and no star over each gate, each watchman looks up and keeps his post.
static func _omen_once(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	_run(s, 0.9)
	t.check((s.banners as Array).is_empty() and not d.stars[0].omen_fallen, "before OMEN_AT no star has fallen")
	_run(s, 0.3)
	var said := s.banners as Array
	t.check(said.count("A STAR FALLS OVER THE TOWN") == 1 and said.count("STOP THE WARNINGS") == 1 and said.size() == 2,
		"at OMEN_AT one star: A STAR FALLS OVER THE TOWN, STOP THE WARNINGS (%s)" % [said])
	var all := true
	for w in d.stars:
		all = all and w.omen_fallen and w.phase == WarningDirector.Phase.STARE and w.at_post() and w.watchman.look_up
	t.check(all, "each watchman looks up at it and keeps his post")
	_run(s, 5.0)
	t.check((s.banners as Array).count("A STAR FALLS OVER THE TOWN") == 1 and d.stars[0].at_post() and d.stars[0].watchman.ground_pos.distance_to(d.stars[0].gate_spot) < 1.5,
		"it falls once, and the stare ending sends nobody")
	_done(s)


## Each watchman sets off at his own time in mission seconds, with the others still holding; a stopped one never sets off.
static func _set_offs(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	_run(s, DT)
	t.check(is_equal_approx(d.sets_off_in(0), 19.95) and is_equal_approx(d.sets_off_in(2), 59.95), "sets_off_in reads the schedule (%.2f)" % d.sets_off_in(0))
	d._clock = 19.9
	_run(s, 0.2)
	var w0 := d.stars[0]
	t.check(w0.phase == WarningDirector.Phase.RUN and d.stars[1].at_post() and d.stars[2].at_post() and d.sets_off_in(0) == INF,
		"at 0:20 the Postern's watchman sets off, the others hold (%s)" % WarningDirector.Phase.keys()[w0.phase])
	t.check(d.hint_phase() == "running" and d.step_seconds() > 19.5 and d.step_seconds() <= 20.0, "the soonest set-off is the Main Gate's (%.2f)" % d.step_seconds())
	t.check(_labelled(d, "MESSENGER").size() == 1 and _labelled(d, "WATCHMAN - SETS OFF IN 0:20").size() == 1
		and _labelled(d, "WATCHMAN - SETS OFF IN 0:20")[0].who == d.stars[1].watchman, "his tag is MESSENGER now; the next countdown reads 0:20")
	d.stars[1].warning_dead = true
	d.stars[1].phase = WarningDirector.Phase.OVER
	d._clock = 39.9
	_run(s, 0.2)
	t.check(d.stars[1].phase == WarningDirector.Phase.OVER and d.sets_off_in(1) == INF, "a watchman stopped before his time never sets off")
	d._clock = 59.9
	_run(s, 0.2)
	t.check(d.stars[2].phase == WarningDirector.Phase.RUN and d.step_seconds() == 0.0, "at 1:00 the Side Gate's sets off: no set-off left, step_seconds 0")
	_done(s)


## The schedule is in mission seconds: at x2 the first watchman sets off at 10 s of play, the star falls at 0.5.
static func _rate(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	(s.rules as Rules).clock_rate = 2.0
	_run(s, 0.6)
	t.check(d.stars[0].omen_fallen, "x2: the star falls at 0.5 s of play")
	_run(s, 9.0)
	t.check(d.stars[0].at_post() and d._clock < 20.0, "x2: at 9.6 s he still holds his post (mission clock %.1f)" % d._clock)
	_run(s, 0.6)
	t.check(d.stars[0].phase == WarningDirector.Phase.RUN, "x2: and has set off by 10.2 s")
	_done(s)


## hint_phase(): posts while all hold; running once one has set off; relay and bell as the chain goes; broken with the bell broken and only posts left; never "".
static func _phases(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_HERALD)
	(s.rules as Rules).lantern = lw
	_run(s, 2.0)
	t.check(d.hint_phase() == "posts" and d.running() == null, "every live warning at its post: posts")
	t.check(d.hint_phases() == PackedStringArray(["herald", "bell", "relay", "running", "broken", "posts"]), "the six phases of spec 6.2")
	(s.env as EnvironmentField).blight((s.crowd as Crowd).bell.tower)
	_run(s, 0.3)
	t.check(d.hint_phase() == "broken", "the bell broken and only watchmen at their posts: broken (%s)" % d.hint_phase())
	d.stars[0].set_off()
	_run(s, 0.5)
	t.check(d.hint_phase() == "herald", "a walker to the Temple is a Herald: herald (%s)" % d.hint_phase())
	_done(s)
	s = _world()
	d = s.d
	var w := _star_running(s, 0)
	t.check(d.hint_phase() == "running" and d.running() == w, "one has set off: running")
	w.messenger.ground_pos = (s.crowd as Crowd).bell.keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	t.check(w.phase == WarningDirector.Phase.DELIVERED and d.hint_phase() == "bell", "the keeper carries it: bell (%s)" % d.hint_phase())
	_done(s)
	s = _world()
	d = s.d
	w = _star_running(s, 0)
	w.relays = 1
	t.check(d.hint_phase() == "relay", "a witness carries it on: relay (%s)" % d.hint_phase())
	_done(s)


## W-R14: the watchmen set off in a world where people walk: no run to the keeper may take a runner out of the walls (W1 would stop the warning the moment
## he did). T1 saw the Main Gate's run path leave the walls in the kit's world; in the board's own world, stepped, none does (the post stands inside the gate).
static func _main_gate_runs(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	_run(s, 2.0)
	var men: Array[Person] = []
	for w in d.stars:
		men.append(w.messenger)
		w.set_off()
	var left := [false, false, false]
	var y_top := [-INF, -INF, -INF]
	var starts: Array[Vector2] = []
	var far := [0.0, 0.0, 0.0]
	for m in men:
		starts.append(m.ground_pos)
	for step in roundi(25.0 / DT):
		Person.frame_no = step  # the frames advance as in play (the LOD staggers by them), not by this process's instance ids
		crowd.advance(DT)
		crowd.step_people(DT)
		(s.rules as Rules).advance(DT)
		for i in 3:
			var w := d.stars[i]
			if (w.phase == WarningDirector.Phase.RUN or w.phase == WarningDirector.Phase.DELIVERED) and is_instance_valid(men[i]):
				left[i] = left[i] or Walls.outside(men[i].ground_pos)
				y_top[i] = maxf(y_top[i], men[i].ground_pos.y)
				far[i] = maxf(far[i], men[i].ground_pos.distance_to(starts[i]))
	Person.frame_no = -1
	for i in 3:
		var w := d.stars[i]
		t.check(far[i] > 2.0 and not left[i] and w.stopped_how != "out", "W-R14: %s's runner really runs (%.1f from his post) and never leaves the walls (his y reached %.1f, the post at %.1f; %s)"
			% [StarfallDirector.STARS[i][2], far[i], y_top[i], w.gate_spot.y, w.stopped_how])
	_done(s)


## W-R16: the bell breaks while the keeper is mid-climb: the carrier turns to the Temple at BROKEN_PACE and nothing tolls.
static func _broken_mid_climb(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	var lw := LanternWatch.new().setup(s.rules, crowd, s.town, null, LanternWatch.KIND_HERALD)
	(s.rules as Rules).lantern = lw
	var w := _star_running(s, 0)
	w.messenger.ground_pos = bell.keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	var keeper := bell.keeper
	t.check(w.phase == WarningDirector.Phase.DELIVERED and w.messenger == keeper and not w.bell_broken(), "the keeper carries it, the bell is called and intact")
	bell.state = BellNetwork.State.CLIMBING
	bell.progress = 3.0
	(s.env as EnvironmentField).blight(bell.tower)
	_run(s, 1.0)
	t.check(w.bell_broken() and not lw.tolled and bell.state != BellNetwork.State.RUNG, "the tower is blighted mid-climb: the bell is broken, nothing tolls (%s)" % BellNetwork.State.keys()[bell.state])
	t.check(w.herald_open() and w._descend == 0.0 and is_equal_approx(float(keeper.statuses.get(&"slow", 1.0)), WarningDirector.BROKEN_PACE)
		and keeper.goal().distance_to(w.lantern_door()) < 1.5, "the keeper turns to the Temple's door at BROKEN_PACE, with no descent")
	t.check(d.hint_phase() == "herald" and d.herald_open(), "the board names the Herald phase")
	_done(s)


## W-R16: THE BELL IS BROKEN is said once on the board, by the first warning, or by the director when that one is already stopped; never off a Herald night.
static func _broken_banner_once(t) -> void:
	var s := _world()
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_HERALD)
	(s.rules as Rules).lantern = lw
	_run(s, 1.0)
	(s.env as EnvironmentField).blight((s.crowd as Crowd).bell.tower)
	_run(s, 1.0)
	t.check((s.banners as Array).count(WarningDirector.BROKEN_BANNER) == 1, "THE BELL IS BROKEN shows once for three warnings (%d)" % (s.banners as Array).count(WarningDirector.BROKEN_BANNER))
	_done(s)
	s = _world()
	var d: StarfallDirector = s.d
	lw = LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_HERALD)
	(s.rules as Rules).lantern = lw
	_run(s, 1.0)
	d.stars[0].warning_dead = true
	d.stars[0].phase = WarningDirector.Phase.OVER
	(s.env as EnvironmentField).blight((s.crowd as Crowd).bell.tower)
	_run(s, 1.0)
	t.check((s.banners as Array).count(WarningDirector.BROKEN_BANNER) == 1, "the first warning stopped: the director says it, once")
	_done(s)
	s = _world()  # (no Lantern on this Rules: no Herald night, no banner)
	_run(s, 1.0)
	(s.env as EnvironmentField).blight((s.crowd as Crowd).bell.tower)
	_run(s, 1.0)
	t.check(not (s.banners as Array).has(WarningDirector.BROKEN_BANNER), "off a Herald night the broken bell says nothing")
	_done(s)


## Blight on the tower over three warnings (I6): TIME while all hold their posts, SOONER if any live carrier is nearer the door, TOLLED first of all.
static func _bell_why_all(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_HERALD)
	(s.rules as Rules).lantern = lw
	_run(s, 1.0)
	var at := (s.crowd as Crowd).bell.tower.center()
	t.check(d.why_not("blight", at) == WarningDirector.BELL_TIME, "three watchmen at their posts: IT ONLY BUYS TIME (%s)" % d.why_not("blight", at))
	var man: Vector2 = d.stars[1].messenger.ground_pos
	t.check(d.why_not("ember", man) == WarningDirector.BURN_BANNER, "Ember on a watchman at his post: HE RUNS BURNING (%s)" % d.why_not("ember", man))
	t.check(d.why_not("ember", Vector2(0.0, 0.0)) == "", "an Ember far from every post says nothing")
	d.stars[0].warning_dead = true
	d.stars[0].phase = WarningDirector.Phase.OVER
	Kit.arrive(d.stars[2].messenger, d.stars[2].lantern_door() + Vector2(0.0, 1.0))
	t.check(d.why_not("blight", at) == WarningDirector.BELL_SOONER, "the first one stopped, another carrier near the door: HE RUNS SOONER (%s)" % d.why_not("blight", at))
	# SOONER wins over TIME whichever star says which: the near-door carrier moves to the middle star, the last now says TIME after him.
	Kit.arrive(d.stars[2].messenger, d.stars[2].gate_spot)
	Kit.arrive(d.stars[1].messenger, d.stars[1].lantern_door() + Vector2(0.0, 1.0))
	t.check(d.stars[1].bell_why("blight", at) == WarningDirector.BELL_SOONER and d.stars[2].bell_why("blight", at) == WarningDirector.BELL_TIME
		and d.why_not("blight", at) == WarningDirector.BELL_SOONER, "SOONER from an earlier star beats a later star's TIME (%s)" % d.why_not("blight", at))
	lw.tolled = true
	t.check(d.why_not("blight", at) == WarningDirector.BELL_TOLLED, "tolled: THE BELL HAS TOLLED ALREADY first")
	_done(s)


## The report counts a watchman who dreamt it.
static func _dreamt_report(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	_run(s, 2.0)
	var w := d.stars[0]
	w.watchman.confuse(5.0)
	_run(s, 0.2)
	t.check(w.warning_dead and w.stopped_how == "dreamt" and d.report().dreamt == 1 and d.report().stopped == 1 and d.stars[1].at_post(),
		"a Discord on the Postern's watchman at his post: dreamt, counted, the others hold (%s)" % w.stopped_how)
	_done(s)


## v0.11.2: the toll no longer loses the night (it turned the Lantern); a Herald who reaches the Temple does (tests/test_herald_nights.gd).
static func _bell(t) -> void:
	var s := _world()
	var rules: Rules = s.rules
	var bell: BellNetwork = (s.crowd as Crowd).bell
	var lw := LanternWatch.new().setup(rules, s.crowd, s.town, null, TierBook.board("warning").lantern)
	rules.lantern = lw
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()
	_run(s, DT)
	t.check(lw.tolled and not rules.finished and lw.stage == LanternWatch.Stage.STIRRING,
		"a warning reaching the bell no longer loses the night: the Lantern turns")
	_done(s)


static func _forced(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	# A warning already stopped is never set up.
	d.stars[1].warning_dead = true
	d.stars[2].warning_dead = true
	_run(s, DT)
	t.check(d.stars[1].rules == null and d.stars[2].rules == null and d.stars[0].rules != null, "a star already stopped is never set up")
	# A warning set up has its watchman at his post and the bell held for him; teardown lets the bell go.
	var s2 := _world()
	var d2: StarfallDirector = s2.d
	_run(s2, 0.1)
	t.check(d2.stars[0].rules != null and is_instance_valid(d2.stars[0].watchman)
		and (s2.crowd as Crowd).bell.hold_on_death == true, "a star set up holds the bell for its watchman")
	d2.teardown()
	t.check((s2.crowd as Crowd).bell.hold_on_death == false, "teardown lets the bell go")
	_done(s2)
	_done(s)


static func _runners(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	_run(s, 0.1)
	var first := d.stars[0]
	var second := d.stars[1]
	var third := d.stars[2]
	t.check(first.watchman != second.watchman and second.watchman != third.watchman and first.watchman != third.watchman, "three watchmen, three different men")
	var at := second.messenger.ground_pos
	for group: Array[Person] in [(s.crowd as Crowd).citizens, (s.crowd as Crowd).soldiers]:
		for p in group:
			if is_instance_valid(p) and p != second.messenger and p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + 1.0:
				p.ground_pos = at + Vector2(Crowd.DOOM_WITNESS + 6.0, 0.0)
	(s.field as EnemyField).kill(second.messenger, &"doom")
	_run(s, DT)
	t.check(second.warning_dead and not first.warning_dead and not third.warning_dead and d.stopped() == 1, "one kill stops only one warning")
	_done(s)


static func _runners_freed(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	_run(s, 0.1)
	var first := d.stars[0]
	var gone := first.watchman
	t.check(first.rules != null and is_instance_valid(gone), "star 0 is set up with a watchman")
	(s.crowd as Crowd).citizens.erase(gone)
	gone.free()
	t.check(not is_instance_valid(first.watchman), "his watchman is freed (a fade ended)")
	_run(s, 0.5)
	t.check(d.stars[1].at_post() and d.stars[2].at_post() and not first.at_post() and d.tags().size() >= 3 and d.hint_phase() != "", "the others carry on, the tags and phase still read")
	d._clock = 19.9
	_run(s, 0.2)
	t.check(not first.warning_dead and d.sets_off_in(0) == INF, "a freed watchman is never sent off (no errors)")
	_done(s)


static func _single(t) -> void:
	var w := WarningDirector.new()
	t.check(w.post == WarningDirector.GATE_SPOT and w.post_name == "THE MAIN GATE", "a lone Warning's star falls over the Main Gate")
	t.check(MissionBook.warning().director == WarningDirector, "and the campaign's Warning is the lone one")
	var b := TierBook.board("warning")
	var reasons := []
	for o in b.objectives():
		reasons.append(o.reason)
	t.check(b.director == StarfallDirector and b.stretch == 1.0 and reasons == ["warning", "lantern", "dawn"]
		and b.goal_label == "The warnings die", "the board's: three stars, stop them all (%s)" % [reasons])



# --- god T1R, Task 2: out of the walls (W1) and the keeper who heard ALL IS WELL (W2), spec 4.1 ---

static func _star_running(s: Dictionary, i: int) -> WarningDirector:
	var d: StarfallDirector = s.d
	_run(s, StarfallDirector.OMEN_AT + WarningDirector.STARE)
	d.stars[i].set_off()
	_run(s, 0.3)
	return d.stars[i]


## Everyone out of doors but `keep` is moved clear of `at` by more than the witness distance, so a death there is unseen by all but them.
static func _clear_round(s: Dictionary, at: Vector2, keep: Array) -> void:
	var crowd: Crowd = s.crowd
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		var n := 0
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + 4.0:
				n += 1
				p.ground_pos = at + Vector2(Crowd.DOOM_WITNESS + 8.0, 0.0).rotated(float(n))


## A watchman set down outside the walls (a Mirrorfold's way out, a whisper) stops the warning for the night.
static func _out_stops(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	var w := _star_running(s, 0)
	var p := w.messenger
	t.check(w.walls_stop and w.lie_stops and w.phase == WarningDirector.Phase.RUN and not w.warning_dead, "star 0's watchman runs, both rules on")
	t.check(p.fold(Vector2(-5.75, 18.0)) and Walls.outside(p.ground_pos), "he is set down outside the walls")
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "out" and w.phase == WarningDirector.Phase.OVER, "the next step: the warning is dead, stopped 'out' (%s)" % w.stopped_how)
	t.check((s.banners as Array).has("THE WARNING LEAVES TOWN") and w.is_leaving(p) and p.mind == Person.Mind.DUTY and w.tags().is_empty(),
		"the banner, and he is leaving the map, on duty for his way off, with no tag")
	t.check(d.stopped() == 1 and d.sets_off_in(0) == INF and d.sets_off_in(1) < INF, "one stopped: the next watchman still sets off at his own time")
	t.check(p in d._reserved_for(d.stars[1]), "and the next star's watchman is never him: a leaver is reserved")
	# He is walked off after the warning is over (the warning steps its leaver before its OVER return), and counts no escape.
	var escaped := crowd.escaped_count
	p.ground_pos = Walls.way_off(p.ground_pos) + Vector2(0.4, 0.0)
	_run(s, DT * 2.0)
	t.check(not p in crowd.citizens and not w.is_leaving(p) and crowd.escaped_count == escaped, "taken off the map at his way off, not counted as escaped")
	_done(s)


## Whispered out during the stare: stopped before he runs; the star still fell.
static func _out_staring(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	_run(s, 3.0)
	var w := d.stars[0]
	t.check(w.omen_fallen and w.phase == WarningDirector.Phase.STARE, "star 0 has fallen and its watchman stares")
	var p := w.watchman
	t.check(p.fold(Vector2(-5.75, 18.0)) and Walls.outside(p.ground_pos), "the postern's watchman is set down outside")
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "out" and w.omen_fallen and (s.banners as Array).has("A STAR FALLS OVER THE TOWN"),
		"stopped in his stare, the star having fallen")
	t.check(w.phase == WarningDirector.Phase.OVER and w.is_leaving(p), "and he never runs for the keeper: he walks off the map")
	_done(s)


## The Herald (the bell tolled) set down outside: not a Herald any more, the warning is stopped.
static func _out_herald(t) -> void:
	var s := _world()
	var rules: Rules = s.rules
	var bell: BellNetwork = (s.crowd as Crowd).bell
	var lw := LanternWatch.new().setup(rules, s.crowd, s.town, null, TierBook.board("warning").lantern)
	rules.lantern = lw
	var w := _star_running(s, 0)
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()
	_run(s, DT)
	t.check(lw.tolled and w.heralding(), "the bell tolled: a Herald night")
	_run(s, 1.0)
	t.check(w.herald_open() and not w.warning_dead, "the warning's carrier is a Herald, running for the Temple")
	var h := w.messenger
	t.check(h.fold(Vector2(-5.75, 18.0)), "the Herald is set down outside the walls")
	_run(s, DT * 2.0)
	t.check(not w.herald_open() and w.warning_dead and w.stopped_how == "out", "no Herald any more: the warning is stopped 'out'")
	t.check(not h.statuses.has(&"slow"), "and he is given back his pace")
	_done(s)


## A seen kill whose nearest witness stands outside the walls stops the warning at once (relays 1).
static func _out_relay(t) -> void:
	var s := _world()
	var w := _star_running(s, 0)
	var m := w.messenger
	var at := Vector2(2.7, 15.4)
	var crowd: Crowd = s.crowd
	var witness: Person = null
	for p in crowd.citizens:
		if p != m and p != crowd.bell.keeper and p.profile != null and p.profile.role == CitizenProfile.Role.RESIDENT:
			witness = p
			break
	m.ground_pos = at
	_clear_round(s, at, [m, witness])
	witness.ground_pos = Vector2(2.7, 17.0)
	t.check(Walls.outside(witness.ground_pos) and not Walls.outside(m.ground_pos), "the messenger is inside, his only witness outside")
	(s.field as EnemyField).kill(m, &"doom", at)
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "out" and w.relays == 1 and w.is_leaving(witness), "stopped at once, relays 1, the witness sent off (%s)" % w.stopped_how)
	_done(s)


## The bell lies and the messenger reaches the keeper: not believed.
static func _lie_stops(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var w := _star_running(s, 0)
	var m := w.messenger
	var keeper := crowd.bell.keeper
	crowd.bell_lies(45.0)
	m.ground_pos = keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	t.check(w.warning_dead and w.stopped_how == "lie" and w.phase == WarningDirector.Phase.OVER, "told while the bell lies: stopped 'lie' (%s)" % w.stopped_how)
	t.check(crowd.bell.state == BellNetwork.State.IDLE and (s.banners as Array).has("ALL IS WELL - THE KEEPER SENDS HIM HOME"),
		"the bell is not called; the banner")
	t.check(m.mind != Person.Mind.DUTY and not w.is_leaving(m), "the messenger is off duty, home")
	t.check((s.d as StarfallDirector).report().lies == 1 and (s.d as StarfallDirector).report().out == 0, "the report counts the lie")
	_done(s)


## Keeper dead, messenger at the tower's foot while the bell lies: stopped, the bell not rung.
static func _lie_rope(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	var keeper := bell.keeper
	_clear_round(s, keeper.ground_pos, [keeper])
	(s.field as EnemyField).kill(keeper, &"doom", keeper.ground_pos)
	var w := _star_running(s, 0)
	var m := w.messenger
	crowd.bell_lies(45.0)
	m.ground_pos = bell.foot
	m._goal = Vector2.INF
	m._path = PackedVector2Array()
	_run(s, 0.7)
	t.check(w.warning_dead and w.stopped_how == "lie" and bell.state == BellNetwork.State.IDLE and bell.keeper != m,
		"at the foot while the bell lies: stopped, nobody climbs (%s)" % w.stopped_how)
	_done(s)


## A lie that ended 2 s ago: the delivery is believed, as today.
static func _lie_over(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var w := _star_running(s, 0)
	var m := w.messenger
	var keeper := crowd.bell.keeper
	crowd.bell_lies(1.0)
	_run(s, 2.0)
	t.check(not crowd.is_bell_lying(), "the lie is over")
	m.ground_pos = keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	t.check(not w.warning_dead and w.phase == WarningDirector.Phase.DELIVERED and crowd.bell.state != BellNetwork.State.IDLE,
		"delivered as today, the bell called (%s)" % BellNetwork.State.keys()[crowd.bell.state])
	_done(s)


## While the bell lies, the BELLKEEPER tag counts the lie down in mission seconds.
static func _lie_tag(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var w := _star_running(s, 0)
	t.check(_labelled(w, "BELLKEEPER").size() == 1, "before the lie: BELLKEEPER")
	crowd.bell_lies(45.0)
	_run(s, 1.1)
	var tags := _labelled(w, "BELLKEEPER - ALL IS WELL 0:44")
	t.check(tags.size() == 1 and tags[0].at == crowd.bell.keeper.ground_pos, "while it lies: BELLKEEPER - ALL IS WELL 0:44 (%s)" % [w.tags().map(func(m: MapTag) -> String: return m.label)])
	_run(s, 10.0)
	t.check(_labelled(w, "BELLKEEPER - ALL IS WELL 0:34").size() == 1, "and it counts down (0:34)")
	_run(s, 40.0)
	t.check(_labelled(w, "BELLKEEPER").size() == 1, "and is plain again once it has run out")
	_done(s)


static func _flags_and_report(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var on := true
	for w in d.stars:
		on = on and w.walls_stop and w.lie_stops and w.gate_keeps and w.holds_post and w.quiet_omen and w.dreams_stop and w.lead_key and w.bell_breaks 			and w.rework_reach and w.stopped_how == ""
	t.check(on, "each warning has every rework flag on before it is set up")
	t.check(not d.stars[0].broken_said and d.stars[1].broken_said and d.stars[2].broken_said, "THE BELL IS BROKEN is said by one of three")
	t.check(d.report().out == 0 and d.report().lies == 0 and d.report().dreamt == 0 and d.report().has("stopped") and d.report().has("relays"),
		"the report has out, lies and dreamt, beside stopped and relays")
	var lone := WarningDirector.new()
	t.check(not lone.walls_stop and not lone.lie_stops and not lone.holds_post and not lone.quiet_omen and not lone.dreams_stop and not lone.lead_key and not lone.bell_breaks
		and not lone.rework_reach and lone.stopped_how == "", "a lone WarningDirector has every rule off")
	_done(s)


static func _star_staring(s: Dictionary, i: int) -> WarningDirector:
	_run(s, StarfallDirector.OMEN_AT + 1.0)
	return (s.d as StarfallDirector).stars[i]


## One of the town's soldiers, out of doors, moved to stand (and keep his post) at `at`, for a test to strike down.
static func _guard_at(s: Dictionary, at: Vector2) -> Person:
	var crowd: Crowd = s.crowd
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside:
			p.ground_pos = at
			p.anchor = at
			return p
	return null


## W3 (D26): while the Main Gate's watchman stares at his star, a man struck down just outside the gate draws him out to the body; past the
## walls he is out, and the warning is stopped as by W1.
static func _gate_body(t) -> void:
	var s := _world()
	var w := _star_staring(s, 1)
	var m := w.messenger
	t.check(w.gate_keeps and w.phase == WarningDirector.Phase.STARE and m == w.watchman, "star 1's watchman stares, W3 on")
	var g := _guard_at(s, Vector2(2.7, 17.2))
	t.check(g != null and not City.current().town().has_point(g.ground_pos) and g.ground_pos.distance_to(w.gate_spot) <= WarningDirector.GATE_SIGHT,
		"a guard stands outside the gate, within sight of the post")
	(s.field as EnemyField).kill(g, &"lightning", g.ground_pos)
	t.check(m.mind == Person.Mind.DUTY and w._drawn_to != Vector2.INF and (s.banners as Array).has("THE WATCHMAN GOES OUT TO THE BODY"),
		"he goes out to the body, on duty (%s)" % Person.Mind.keys()[m.mind])
	t.check(Walls.outside(m.goal()), "his walk ends past the walls' margin (%s)" % m.goal())
	_run(s, WarningDirector.STARE)
	t.check(w.phase == WarningDirector.Phase.STARE and m.mind == Person.Mind.DUTY and m.goal() == w._drawn_to and not w.warning_dead,
		"the stare's time runs out on the way: he goes on out, not to the keeper, and holds no post")
	m.ground_pos = m.goal()  # (the test's people do not walk: he is set down where his walk ends)
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "out" and w.is_leaving(m) and (s.banners as Array).has("THE WARNING LEAVES TOWN"),
		"past the walls he is out: stopped 'out', leaving the map (%s)" % w.stopped_how)
	_done(s)


## W3's edges: a death inside the walls, or one outside once he has run, draws nobody.
static func _gate_body_not(t) -> void:
	var s := _world()
	var w := _star_staring(s, 1)
	var m := w.messenger
	var g := _guard_at(s, Vector2(2.7, 12.5))
	(s.field as EnemyField).kill(g, &"lightning", g.ground_pos)
	t.check(w._drawn_to == Vector2.INF and m.mind != Person.Mind.DUTY and w.phase == WarningDirector.Phase.STARE,
		"a man killed inside the walls: he stares on (%s)" % Person.Mind.keys()[m.mind])
	w.set_off()
	_run(s, 0.3)
	t.check(w.phase == WarningDirector.Phase.RUN and m.mind == Person.Mind.DUTY, "he runs for the keeper")
	var g2 := _guard_at(s, Vector2(2.7, 17.2))
	(s.field as EnemyField).kill(g2, &"lightning", g2.ground_pos)
	t.check(w._drawn_to == Vector2.INF, "a man killed outside once he runs: he runs on")
	_run(s, 1.0)
	t.check(not w.warning_dead, "and the warning lives")
	_done(s)


## W3 at the barred postern: a man struck down on the bank beyond it draws its watchman out through it (he holds its key); it stays barred.
static func _gate_body_postern(t) -> void:
	var s := _world()
	var town: Town = s.town
	var w := _star_staring(s, 0)
	t.check(is_instance_valid(town.postern) and not town.postern.walkable and w.key_door() != Vector2.INF, "the postern is barred; its watchman holds the key")
	var g := _guard_at(s, Vector2(-7.5, 16.6))
	(s.field as EnemyField).kill(g, &"deathmark", g.ground_pos)
	_run(s, DT * 3.0)
	t.check(w.warning_dead and w.stopped_how == "out" and (s.banners as Array).has("THE WATCHMAN UNBARS THE POSTERN"),
		"he goes out through his postern at once, not round by the Main Gate: stopped 'out' (%s)" % w.stopped_how)
	t.check(not town.postern.walkable, "and the postern is barred behind him")
	_done(s)


## The key turns for a fright too: the postern's watchman whose way lies beyond his barred postern (a fright's flight) goes out through it.
static func _key_fright(t) -> void:
	var s := _world()
	var w := _star_staring(s, 0)
	var m := w.messenger
	m.panic(m.ground_pos + Vector2(0.0, -1.4), 0.6, &"smite")
	m.set_goal(Vector2(-6.0, 17.4))  # his flight beyond the wall (where a panic's own flight ends is its own; the key reads only where he is going)
	t.check(not City.current().town().has_point(m.goal()), "frightened at his post, his flight lies beyond the barred postern")
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "out" and Walls.outside(m.ground_pos), "he unbars it and is out: stopped 'out' (%s)" % w.stopped_how)
	_done(s)


## Only the postern's own watchman, while he carries the warning, and only once his star has fallen: the watchman before his star, the Main
## Gate's watchman, or a relay standing at the postern, goes round as ever.
static func _key_only_his(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	_run(s, 0.1)
	var w := d.stars[0]
	t.check(w.phase == WarningDirector.Phase.OMEN and w.key_door() != Vector2.INF, "set up, the star not yet fallen")
	var m := w.messenger
	m.set_goal(Vector2(-6.0, 17.4))
	_run(s, DT * 2.0)
	t.check(not w.warning_dead and City.current().town().has_point(m.ground_pos), "before the star falls the key does not turn")
	_done(s)
	s = _world()
	var w1 := _star_staring(s, 1)
	t.check(w1.key_door() == Vector2.INF, "the Main Gate's watchman holds no postern's key")
	_done(s)
	s = _world()
	var w0 := _star_running(s, 0)
	var crowd: Crowd = s.crowd
	var relay: Person = null
	for p in crowd.citizens:
		if p != w0.messenger and p != crowd.bell.keeper and p.profile != null and p.profile.role == CitizenProfile.Role.RESIDENT:
			relay = p
			break
	w0.messenger = relay
	relay.ground_pos = Vector2(-5.75, 14.9)
	relay.set_goal(Vector2(-6.0, 17.4))
	t.check(w0.key_door() == Vector2.INF, "a relay is not the postern's watchman: no key")
	_run(s, DT * 2.0)
	t.check(not w0.warning_dead and City.current().town().has_point(relay.ground_pos), "and he does not go through it")
	_done(s)


## D27: the keeper has the warning and the bell is called when the bell starts to lie -- he heard ALL IS WELL, so he calls the ringer back before
## the toll. The warning is stopped 'lie', the bell is idle again with its keeper, who is off the rope.
static func _lie_calls_off(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	var w := _star_running(s, 0)
	var keeper := bell.keeper
	w.messenger.ground_pos = keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	t.check(w.phase == WarningDirector.Phase.DELIVERED and w.messenger == keeper and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING],
		"delivered: the keeper carries it, the bell is called (%s)" % BellNetwork.State.keys()[bell.state])
	crowd.bell_lies(45.0)
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "lie" and bell.state == BellNetwork.State.IDLE and bell.keeper == keeper,
		"he hears ALL IS WELL: stopped 'lie', the bell idle again with its keeper (%s, %s)" % [w.stopped_how, BellNetwork.State.keys()[bell.state]])
	t.check(keeper.mind != Person.Mind.DUTY and (s.banners as Array).has("ALL IS WELL - THE KEEPER CALLS OFF THE BELL"), "off the rope; the banner")
	t.check((s.d as StarfallDirector).report().lies == 1, "the report counts the lie")
	_run(s, 20.0)
	t.check(bell.state == BellNetwork.State.IDLE, "and the bell is not rung after all")
	_done(s)


## D27's edge: a bell that has tolled stays tolled; the lie stops nothing then.
static func _lie_tolled_stays(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	var w := _star_running(s, 0)
	w.messenger.ground_pos = bell.keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()
	t.check(bell.state == BellNetwork.State.RUNG and w.phase == WarningDirector.Phase.DELIVERED, "the bell has tolled, the keeper has the warning")
	crowd.bell_lies(45.0)
	_run(s, DT * 2.0)
	t.check(bell.state == BellNetwork.State.RUNG and not w.warning_dead and w.stopped_how == "", "the lie after the toll: the bell stays rung, the warning lives")
	_done(s)


## Review M2 (D29): the key turns only for a way W3 or a fright gave him; any other walk beyond the wall goes round as ever.
static func _key_other_goal(t) -> void:
	var s := _world()
	var w := _star_staring(s, 0)
	var m := w.messenger
	t.check(m.mind == Person.Mind.OBSERVE and w.key_door() != Vector2.INF, "the postern's watchman stares, the key his")
	m.set_goal(Vector2(-6.0, 17.4))
	_run(s, DT * 3.0)
	t.check(not w.warning_dead and City.current().town().has_point(m.ground_pos), "a walk beyond the wall from nothing W3 or a fright gave: no key, he stays in")
	_done(s)


## Review M4: D27 recalls a bell left WAITING too (a frightened keeper, or a lie at the top of the climb).
static func _lie_calls_off_waiting(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	var w := _star_running(s, 0)
	w.messenger.ground_pos = bell.keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	bell._wait()
	t.check(w.phase == WarningDirector.Phase.DELIVERED and bell.state == BellNetwork.State.WAITING, "delivered, the bell waiting to be tried again")
	crowd.bell_lies(45.0)
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "lie" and bell.state == BellNetwork.State.IDLE, "the lie calls it off: stopped 'lie', the bell idle (%s)" % BellNetwork.State.keys()[bell.state])
	_done(s)


## Review M4: W3's reach -- a man killed outside the gate but beyond GATE_SIGHT of the post draws nobody.
static func _gate_body_far(t) -> void:
	var s := _world()
	var w := _star_staring(s, 1)
	var g := _guard_at(s, w.gate_spot + Vector2(0.0, WarningDirector.GATE_SIGHT + 0.4))
	t.check(not City.current().town().has_point(g.ground_pos), "a guard outside the walls, %.1f from the post" % g.ground_pos.distance_to(w.gate_spot))
	(s.field as EnemyField).kill(g, &"lightning", g.ground_pos)
	t.check(w._drawn_to == Vector2.INF and w.messenger.mind != Person.Mind.DUTY, "beyond W3's reach: he stares on")
	_done(s)


static func _hint_running(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var w := _star_staring(s, 0)
	t.check(d.running() == null and w.hint_phase() == "" and d.hint_phase() == "posts", "staring at the post: the posts' line (%s)" % d.hint_phase())
	w.set_off()
	_run(s, 0.3)
	t.check(w.phase == WarningDirector.Phase.RUN and w.relays == 0 and d.hint_phase() == "running", "set off, no relay: the running line (%s)" % d.hint_phase())
	_done(s)


## D30 (review M2): the town's evacuation sends the postern's watchman to flee for a gate (FLEE, Crowd._evacuate()); a flight like that, though
## it lies beyond the wall, does not turn the key -- only a fright from a strike near him (PANIC), or W3's body.
static func _key_evacuation(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	var w := _star_staring(s, 0)
	var m := w.messenger
	crowd._evacuate()
	t.check(m.mind == Person.Mind.FLEE and w.key_door() != Vector2.INF, "the town evacuates: the staring watchman flees for a gate (%s)" % Person.Mind.keys()[m.mind])
	m.set_goal(Vector2(-6.0, 17.4))  # his way to the gate it chose, beyond the barred postern
	_run(s, DT * 3.0)
	t.check(not w.warning_dead and City.current().town().has_point(m.ground_pos), "an evacuation's flight does not turn the key: he stays in")
	_done(s)
