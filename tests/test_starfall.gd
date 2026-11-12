extends RefCounted
## v0.11 M1 the board's Warning (spec §7.2): three stars over three gates at 0:10, 1:30 and 3:00, each a WarningDirector set
## up 2 s before its star, so its watchman is appointed at its gate then; all three stopped wins, a bell rung loses; the
## stars' tags, phases and tour. The campaign's Warning keeps one star over the Main Gate.

const DT := 0.05


static func run(t) -> void:
	_stars(t)
	_chain(t)
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
	_next_countdown(t)
	_gate_guards(t)
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
	t.check(d.stars.size() == 3 and d.stars[0].rules == null and d.stopped() == 0 and d.hint_phase() == "stars",
		"three stars, none set up before its time; the board's own line (god T1R)")
	var next := _labelled(d, "NEXT STAR - FALLS IN 0:10")
	t.check(next.size() == 1 and next[0].at == StarfallDirector.STARS[0][1] and next[0].edge, "the first star's gate is pointed at")
	var stops := d.tour()
	t.check(stops.size() == 4 and String(stops[0][1]) == "The Postern. A star falls here at 0:10."
		and String(stops[1][1]) == "The Main Gate. A star falls here by 1:30."
		and String(stops[2][1]) == "The Side Gate. A star falls here by 3:00.",
		"the tour: the three gates -- the later stars 'by' their time, as they may fall sooner (v0.11 M2) -- then the bellkeeper")
	t.check(String(stops[3][1]) == "The bellkeeper. Warned, he rings the bell: the Lantern turns, and he runs for the Temple.",
		"v0.11.2: the bellkeeper's stop says what the toll does now (%s)" % [stops[3][1]])
	t.check(rules.objectives[0].hud_text(rules) == "Warnings stopped 0 / 3", "the HUD counts them")
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	t.check(first.rules != null and d.stars[1].rules == null and is_instance_valid(first.watchman)
		and first.watchman.ground_pos.distance_to(StarfallDirector.STARS[0][1]) < 1.5,
		"at 0:08 the postern's watchman is appointed at his gate")
	_run(s, 2.2)
	t.check((s.banners as Array).has("A STAR FALLS OVER THE POSTERN") and first.omen_fallen, "at 0:10 its star falls")
	first.warning_dead = true
	first.phase = WarningDirector.Phase.OVER
	_run(s, DT)
	t.check(d.stopped() == 1 and not rules.finished and d.hint_phase() == "waiting" and d.running() == null,
		"one stopped: the night goes on, waiting for the next star")
	d._clock = 87.95
	_run(s, 2.3)
	t.check(d.stars[1].rules != null and (s.banners as Array).has("A STAR FALLS OVER THE MAIN GATE") and d.running() == d.stars[1],
		"at 1:30 the Main Gate's")
	d.stars[1].warning_dead = true
	d._clock = 177.95
	_run(s, 2.3)
	t.check((s.banners as Array).has("A STAR FALLS OVER THE SIDE GATE") and d.next_star() == -1, "at 3:00 the Side Gate's, the last")
	d.stars[2].warning_dead = true
	_run(s, DT)
	t.check(rules.finished and rules.won and rules.over_reason == "warning" and d.report().stopped == 3,
		"all three stopped: won (%s)" % rules.over_reason)
	_done(s)


## Final review, item 3 (the user's rule: no wait over 60 s): a later star falls at its scheduled time or STOP_WAIT after the
## previous warning was stopped, whichever is sooner -- its omen still first. A star not yet stopped never brings the next forward.
static func _chain(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	d._clock = 19.9
	first.warning_dead = true
	first.phase = WarningDirector.Phase.OVER
	_run(s, 0.2)  # (stopped at 0:20)
	d._clock = 46.0
	_run(s, 0.1)
	t.check(d.stars[1].rules == null, "star 0 stopped at 0:20: star 1 is not set up at 0:46, its omen's lead (%s) not yet come" % [d.stars[1].rules])
	_run(s, 2.5)
	t.check(d.stars[1].rules != null and not d.stars[1].omen_fallen, "its watchman is appointed at 0:48 (the omen first)")
	_run(s, 2.0)
	t.check(d.stars[1].omen_fallen and (s.banners as Array).has("A STAR FALLS OVER THE MAIN GATE"),
		"and its star falls by 0:50, not 1:30")
	var at: float = d._clock
	d.stars[1].warning_dead = true
	d.stars[1].phase = WarningDirector.Phase.OVER
	_run(s, DT)  # (stopped just after 0:50)
	d._clock = at + 26.0
	_run(s, 0.2)
	t.check(d.stars[2].rules == null, "star 1 stopped at once: star 2 is not set up before its lead")
	_run(s, 2.5)
	t.check(d.stars[2].rules != null and not d.stars[2].omen_fallen, "star 2's watchman is appointed 28 s after")
	_run(s, 2.0)
	t.check(d.stars[2].omen_fallen and d._clock < at + 31.0 and (s.banners as Array).has("A STAR FALLS OVER THE SIDE GATE"),
		"and its star falls within 30 s of the stop, not at 3:00 (%.1f s after)" % (d._clock - at))
	_done(s)

	# A star running, not yet stopped, never brings the next forward.
	var run := _world()
	var e: StarfallDirector = run.d
	e._clock = 7.95
	_run(run, 0.1)
	e._clock = 60.0
	_run(run, 0.1)
	t.check(e.stars[1].rules == null and not e.stars[0].warning_dead, "star 0 still running at 1:00: star 1 waits for its time")
	e._clock = 87.9
	_run(run, 0.2)
	t.check(e.stars[1].rules != null, "and comes at 1:30 as scheduled")
	_done(run)

	# A stop late in the night does not push the next star past its schedule.
	var late := _world()
	var l: StarfallDirector = late.d
	l._clock = 7.95
	_run(late, 0.1)
	l._clock = 79.9
	l.stars[0].warning_dead = true
	l.stars[0].phase = WarningDirector.Phase.OVER
	_run(late, 0.2)
	l._clock = 87.9
	_run(late, 0.2)
	t.check(l.stars[1].rules != null, "stopped at 1:20, star 1 falls at its scheduled 1:30, not 30 s after")
	_done(late)


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
	# A star already stopped is never set up.
	d.stars[1].warning_dead = true
	d.stars[2].warning_dead = true
	d._clock = 200.0
	_run(s, DT)
	t.check(d.stars[1].rules == null and d.stars[2].rules == null, "a star already stopped is never set up")
	# A star set up has its watchman on errand and the bell held for him; teardown lets the bell go.
	var s2 := _world()
	var d2: StarfallDirector = s2.d
	d2._clock = 7.95
	_run(s2, 0.1)
	t.check(d2.stars[0].rules != null and is_instance_valid(d2.stars[0].watchman)
		and (s2.crowd as Crowd).bell.hold_on_death == true, "a star set up holds the bell for its watchman")
	d2.teardown()
	t.check((s2.crowd as Crowd).bell.hold_on_death == false, "teardown lets the bell go")
	_done(s2)
	_done(s)


## Earlier stars' runners are reserved (preflight ruling): star 0 still running at 88 s, with its watchman standing at star 1's
## gate, does not lend him to star 1; and one kill stops only one warning.
static func _runners(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	var lent := first.watchman
	t.check(first.rules != null and is_instance_valid(lent) and not first.warning_dead, "star 0 is set up and running")
	d._clock = 87.9
	lent.ground_pos = StarfallDirector.STARS[1][1]
	_run(s, 0.2)
	var second := d.stars[1]
	t.check(second.rules != null and is_instance_valid(second.watchman) and second.watchman != first.watchman
		and second.watchman != first.messenger, "star 1's watchman is not star 0's watchman or messenger")
	t.check(first.watchman == lent and first.messenger == lent, "and star 0 still has its own")
	var at := second.messenger.ground_pos
	for group: Array[Person] in [(s.crowd as Crowd).citizens, (s.crowd as Crowd).soldiers]:
		for p in group:
			if is_instance_valid(p) and p != second.messenger and p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + 1.0:
				p.ground_pos = at + Vector2(Crowd.DOOM_WITNESS + 6.0, 0.0)
	(s.field as EnemyField).kill(second.messenger, &"doom")
	_run(s, DT)
	t.check(second.warning_dead and not first.warning_dead and d.stopped() == 1, "one kill stops only one warning")
	_done(s)


## A runner killed on an earlier star and freed after its fade is simply skipped when the next star is set up (and the log
## stays clean: no freed body is put in a typed array).
static func _runners_freed(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	d._clock = 7.95
	_run(s, 0.1)
	var first := d.stars[0]
	var gone := first.watchman
	t.check(first.rules != null and is_instance_valid(gone), "star 0 is set up with a watchman")
	(s.crowd as Crowd).citizens.erase(gone)
	gone.free()
	t.check(not is_instance_valid(first.watchman), "its watchman is freed (a fade ended)")
	d._clock = 87.9
	_run(s, 0.2)
	var second := d.stars[1]
	t.check(second.rules != null and is_instance_valid(second.watchman), "star 1 is set up all the same, with a watchman of its own")
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

## Star `i` set up and its stare over (its watchman runs): the board's clock put just before its omen, then run past the stare.
static func _star_running(s: Dictionary, i: int) -> WarningDirector:
	var d: StarfallDirector = s.d
	d._clock = float(d.star_falls[i][0]) - WarningDirector.OMEN_AT - 0.05
	_run(s, 0.1)
	_run(s, WarningDirector.OMEN_AT + WarningDirector.STARE + 0.2)
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
	t.check(d.stopped() == 1 and d._stopped_at[0] >= 0.0 and is_equal_approx(d.fall_at(1), d._stopped_at[0] + d.stop_wait),
		"star 1 falls stop_wait after the stop, as after a kill (%.1f)" % d.fall_at(1))
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
	d._clock = 7.95
	_run(s, 0.1)
	_run(s, 3.0)
	var w := d.stars[0]
	t.check(w.omen_fallen and w.phase == WarningDirector.Phase.STARE, "star 0 has fallen and its watchman stares")
	var p := w.watchman
	t.check(p.fold(Vector2(-5.75, 18.0)) and Walls.outside(p.ground_pos), "the postern's watchman is set down outside")
	_run(s, DT * 2.0)
	t.check(w.warning_dead and w.stopped_how == "out" and w.omen_fallen and (s.banners as Array).has("A STAR FALLS OVER THE POSTERN"),
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
	_run(s, 1.0)
	var tags := _labelled(w, "BELLKEEPER - ALL IS WELL 0:44")
	t.check(tags.size() == 1 and tags[0].at == crowd.bell.keeper.ground_pos, "while it lies: BELLKEEPER - ALL IS WELL 0:44 (%s)" % [w.tags().map(func(m: MapTag) -> String: return m.label)])
	_run(s, 10.0)
	t.check(_labelled(w, "BELLKEEPER - ALL IS WELL 0:34").size() == 1, "and it counts down (0:34)")
	_run(s, 40.0)
	t.check(_labelled(w, "BELLKEEPER").size() == 1, "and is plain again once it has run out")
	_done(s)


## The board sets both flags on every warning; a lone WarningDirector (the campaign's) keeps them off; the report has the counts.
static func _flags_and_report(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var on := true
	for w in d.stars:
		on = on and w.walls_stop and w.lie_stops and w.stopped_how == ""
	t.check(on, "each star's warning has both rules on before it is set up")
	t.check(d.report().out == 0 and d.report().lies == 0 and d.report().has("stopped") and d.report().has("relays"), "the report has out and lies, beside stopped and relays")
	var lone := WarningDirector.new()
	t.check(not lone.walls_stop and not lone.lie_stops and lone.stopped_how == "", "a lone WarningDirector has both rules off")
	_done(s)


## Star `i` set up, its star fallen, and its watchman a second into his stare (W3's window).
static func _star_staring(s: Dictionary, i: int) -> WarningDirector:
	var d: StarfallDirector = s.d
	d._clock = float(d.star_falls[i][0]) - WarningDirector.OMEN_AT - 0.05
	_run(s, 0.1)
	_run(s, WarningDirector.OMEN_AT + 1.0)
	return d.stars[i]


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
	t.check(w.phase == WarningDirector.Phase.RUN and m.mind == Person.Mind.DUTY and m.goal() == w._drawn_to and not w.warning_dead,
		"his stare runs out on the way: he goes on out, not to the keeper")
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
	_run(s, WarningDirector.STARE)
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
	d._clock = 7.95
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


## D29 (1): the NEXT STAR tag counts down to the fall in mission seconds -- from the schedule, and stop_wait after a stop.
static func _next_countdown(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	t.check(_labelled(d, "NEXT STAR - FALLS IN 0:10").size() == 1 and is_equal_approx(d.next_fall_in(), 10.0), "at dusk: NEXT STAR - FALLS IN 0:10")
	_run(s, 3.5)
	t.check(_labelled(d, "NEXT STAR - FALLS IN 0:07").size() == 1, "it counts down (0:07 at 0:03.5)")
	var w := _star_running(s, 0)
	t.check(d.next_star() == 1 and d.next_fall_in() < 90.0, "star 1 by its schedule while star 0 runs")
	t.check(w.messenger.fold(Vector2(-5.75, 18.0)), "star 0's runner set down outside")
	_run(s, DT * 2.0)
	t.check(w.warning_dead and _labelled(d, "NEXT STAR - FALLS IN 0:30").size() == 1, "stopped: the next star's tag reads stop_wait, 0:30 (%s)"
		% [d.tags().map(func(m: MapTag) -> String: return m.label)])
	_done(s)


## The policy file whose Ruin and Death routes stand on the gate guards (D29 (3)).
const WARNING_POLICY := preload("res://tools/dev/routes/god_t1/warning.gd")


## The board Warning's gates with no guard posted outside the walls for W3: none the gate mark can pick (a post past the ring by POST_SPREAD, within
## GATE_SIGHT less a little of the watchman's post), or none clear of the watchman for Ruin's Smite. The names of the gates that lack one.
static func _missing_gate_guards(s: Dictionary) -> PackedStringArray:
	var d: StarfallDirector = s.d
	var crowd: Crowd = s.crowd
	var out := PackedStringArray()
	for star: Array in d.star_falls:
		var post: Vector2 = d._walkable(star[1])
		var marked: Person = WARNING_POLICY.outside_guard(crowd, post)
		var struck: Person = WARNING_POLICY.outside_guard(crowd, post, post, SmiteFx.KILL_R + Person.THREAT_MARGIN + WARNING_POLICY.SMITE_CLEAR)
		if marked == null or struck == null or marked.ground_pos.distance_to(post) > WarningDirector.GATE_SIGHT:
			out.append(String(star[2]))
	return out


## D29 (3), as D25 pins the Lamb's pocket: in Aldermere every star's gate has a guard posted outside the walls within W3's reach of its post. Ruin's and
## Death's Warning policies win by striking or marking him; an art or layout round that moves the gate guards shows up here, not as a gate mystery.
## The pin bites: with the Main Gate's outer guards moved inside, it names that gate.
static func _gate_guards(t) -> void:
	var s := _world()
	var missing := _missing_gate_guards(s)
	t.check(missing.is_empty(), ("W3 (D28/D29): no guard posted outside the walls within GATE_SIGHT of %s -- tools/dev/routes/god_t1/warning.gd's Ruin (Smite the man outside the "
		+ "gate) and Death (the gate mark) Warning policies stand on one at each of the three gates") % ", ".join(missing))
	var crowd: Crowd = s.crowd
	var post: Vector2 = (s.d as StarfallDirector)._walkable(StarfallDirector.STARS[1][1])
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.anchor.distance_to(post) <= WarningDirector.GATE_SIGHT + 1.0 and not City.current().town().has_point(p.anchor):
			p.anchor = post + Vector2(0.0, -1.0)
			p.ground_pos = p.anchor
	t.check(Array(_missing_gate_guards(s)) == ["THE MAIN GATE"], "with the Main Gate's outer guards moved inside, the pin names that gate (%s)" % ", ".join(_missing_gate_guards(s)))
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


## Review M4, D30: while a warning has nothing of its own to say, the board's hint is its own line -- "stars" (W3's stare clause) while he stares,
## "running" (no stare clause: W3 draws only in the stare) once he runs with no relay.
static func _hint_running(t) -> void:
	var s := _world()
	var d: StarfallDirector = s.d
	var w := _star_staring(s, 0)
	t.check(d.running() == w and w.hint_phase() == "" and d.hint_phase() == "stars", "staring: the board's line (%s)" % d.hint_phase())
	_run(s, WarningDirector.STARE)
	t.check(w.phase == WarningDirector.Phase.RUN and w.relays == 0 and d.hint_phase() == "running", "running, no relay: the running line (%s)" % d.hint_phase())
	t.check(not MissionHints.line("warning", "running").contains("stares") and MissionHints.line("warning", "stars").contains("stares"),
		"the running line offers no stare clause; the stare's does")
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
