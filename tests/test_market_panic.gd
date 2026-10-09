extends RefCounted
## v0.11 M3 Market Panic (mission spec §2, MarketPanicDirector): a night fair at the north-east fountain -- no Mayor, one bonfire,
## the first crowd of WAVE walking in at once to spots within FAIR_R; WARDENS wardens (lay watchmen) at posts evenly round it, each
## pair more than one Silent Doom apart; on guard a warden is fearless and steadies the goers within WARD_R (a fright or a loud
## cast breaks none of them; a death counts); return and relief as Spoiled Harvest's; the next crowds at their times, or CHAIN after the one
## before is scattered; goers at the fair hold to it against the town's regroup and evacuation (review focus 6); FAIR_NEED broken
## wins, the close loses. Freed bodies are borne (review focus 4); the tags, hints, tour, titles, camera and the mission's numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_wardens(t)
	_relief(t)
	_crowds(t)
	_hold(t)
	_ends(t)
	_freed(t)
	_texts(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.market_panic())


static func _setup(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var first: Array = d.waves[0]
	var ok := d.mayor == null and d.need == MarketPanicDirector.FAIR_NEED and first.size() == MarketPanicDirector.WAVE \
		and d.goers.size() == MarketPanicDirector.WAVE and d.wards.size() == MarketPanicDirector.WARDENS
	for v: Variant in first:
		var p := v as Person
		var spot: Vector2 = d._spots[p.get_instance_id()]
		ok = ok and p.profile.faith == CitizenProfile.Faith.NONE and not p.soldier
		ok = ok and spot.distance_to(MarketPanicDirector.HEART) <= MarketPanicDirector.FAIR_R + 0.01
	t.check(ok, "no Mayor; the first crowd of WAVE lay citizens walks in at once, each to a spot within FAIR_R of the fountain")
	var apart := true
	var lay := true
	for i in d.wards.size():
		var a := d.wards[i].man as Person
		lay = lay and a.profile.role == CitizenProfile.Role.WATCHMAN and not d.goers.has(a) 			and a.ground_pos.distance_to(MarketPanicDirector.HEART) < 2.5
		for j in range(i + 1, d.wards.size()):
			apart = apart and a.ground_pos.distance_to((d.wards[j].man as Person).ground_pos) > SilentDoom.RADIUS * 2.0
	t.check(lay and apart, "the wardens, lay watchmen at posts round the fountain, each pair more than one Silent Doom apart")
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["crowd_1", "crowd_2", "close"], "the strip: the two crowds to come and the close (%s)" % [ids])
	var clear := true
	for spot in [MarketPanicDirector.HEART, MarketPanicDirector.SOURCES[1], MarketPanicDirector.SOURCES[2]]:
		clear = clear and Kit.clear_of_stack(spot, MarketPanicDirector.CAMERA_AT)
	t.check(clear, "the camera keeps the fair and both sources clear of the left HUD stack")
	var m := MissionBook.market_panic()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 2 and is_equal_approx(m.clock, 330.0) and m.dp_capacity == 8 and reasons == ["fair", "market_closed", "dawn"]
		and m.objectives()[1].deadline and Array(m.default_loadout) == ["heaven", "doom", "smite"]
		and MissionBook.get_mission("market_panic").id == "market_panic",
		"the mission: Tier 2's numbers; the fair, the close (a deadline), dawn (%s)" % [reasons])
	Kit.done(s)


static func _wardens(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var rules: Rules = s.rules
	var a := d.wards[0].man as Person
	var g := (d.waves[0] as Array)[0] as Person
	Kit.arrive(g, a.ground_pos + Vector2(0.0, 1.0))
	Kit.run_for(s, MarketPanicDirector.TICK + DT)
	g.panic(g.ground_pos + Vector2(1.0, 0.0), 1.0)
	rules.cast_made.emit(0, "smite", g.ground_pos)
	Kit.run_for(s, FestivalDirector.SAMPLE + DT)
	t.check(a.fearless_left > 0.0 and d.steadied(g) and g.mind != Person.Mind.PANIC and d.count() == 0,
		"a warden on guard is fearless and steadies a goer by him: a fright and a loud cast break no one")
	(s.crowd as Crowd)._field.kill(g, &"doom")
	t.check(d.count() == 1, "a death still counts")
	for w in d.wards:
		Kit.free_body(s, w.man as Person)
	var h := (d.waves[0] as Array)[1] as Person
	Kit.run_for(s, HarvestDirector.HOLD_POST + DT * 2.0)
	h.panic(h.ground_pos + Vector2(1.0, 0.0), 1.0)
	Kit.run_for(s, FestivalDirector.SAMPLE + DT)
	t.check(d.on_guard().is_empty() and d.broke_list().has(h) and d.hint_phase() == "open",
		"with no warden standing a fright breaks a goer; the hint says the fair is open")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var w := d.wards[0]
	var a := w.man as Person
	Kit.arrive(a, w.post + Vector2(6.0, 0.0))
	a.mind = Person.Mind.RECOVER
	Kit.run_for(s, HarvestDirector.RETURN_AFTER + MarketPanicDirector.TICK + DT)
	t.check(a.mind == Person.Mind.DUTY and a.anchor.distance_to(w.post) < 0.5, "a warden off his post, calm again, goes back after RETURN_AFTER")
	var old := a.get_instance_id()
	Kit.free_body(s, a)
	Kit.run_for(s, HarvestDirector.RELIEF_AFTER + MarketPanicDirector.TICK + DT)
	var fresh: Variant = w.man
	t.check(MissionDirector._alive(fresh) and (fresh as Person).get_instance_id() != old
		and (fresh as Person).profile.role == CitizenProfile.Role.WATCHMAN and (fresh as Person).anchor.distance_to(w.post) < 0.5
		and (s.banners as Array).has("A NEW WARDEN TAKES THE POST") and not d.goers.has(fresh),
		"a fallen warden is replaced RELIEF_AFTER after, by a lay citizen not at the fair")
	Kit.done(s)


static func _crowds(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var first: Array = d.waves[0]
	for i in MarketPanicDirector.WAVE_NEED:
		(s.crowd as Crowd)._field.kill(first[i] as Person, &"doom")
	Kit.run_for(s, DT * 2.0)
	var shown := d.timeline.seconds_to("crowd_1")
	t.check(d.scattered_at[0] >= 0.0 and shown <= MarketPanicDirector.CHAIN + 0.1 and d.wave_out[1] < 0.0,
		"WAVE_NEED of the first crowd broken scatters it: the strip shows the next crowd within CHAIN (%.1f s)" % shown)
	Kit.run_for(s, MarketPanicDirector.CHAIN + DT * 2.0)
	var second: Array = d.waves[1]
	var walking := d.walkers()
	var all_walk := true
	for v: Variant in second:
		all_walk = all_walk and walking.has(v)
	t.check(d.wave_out[1] >= 0.0 and second.size() == MarketPanicDirector.WAVE and (s.banners as Array).has("MORE COME TO THE FAIR")
		and d.hint_phase() == "coming" and d.wave_out[2] < 0.0 and all_walk,
		"CHAIN after, the second crowd sets out, not at its own time; the hint on its walkers")
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var crowd: Crowd = s.crowd
	var g := (d.waves[0] as Array)[2] as Person
	var spot: Vector2 = d._spots[g.get_instance_id()]
	Kit.arrive(g, spot)
	Kit.run_for(s, MarketPanicDirector.TICK + DT)
	t.check(g.mind == Person.Mind.DUTY and g.anchor.distance_to(spot) < 0.5, "a goer who reaches his spot holds to the fair, on duty there")
	crowd._regroup()
	crowd._evacuate()
	t.check(g.mind == Person.Mind.DUTY, "the town's regroup and evacuation pass him by (Decision 19)")
	Kit.arrive(g, spot + Vector2(3.0, 0.0))
	g.mind = Person.Mind.RECOVER
	Kit.run_for(s, MarketPanicDirector.TICK + DT)
	t.check(g.mind == Person.Mind.DUTY and g.anchor.distance_to(spot) < 0.5, "moved off it and back on his feet, unbroken, he walks back")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var rules: Rules = s.rules
	var o := FestivalObjective.new("Scatter the fair", "fair")
	t.check(o.hud_text(rules) == "Scatter the fair 0/%d" % MarketPanicDirector.FAIR_NEED, "the HUD: Scatter the fair 0/FAIR_NEED")
	d._send_wave(1)
	d._send_wave(2)
	for v: Variant in d.goers:
		(s.crowd as Crowd)._field.kill(v as Person, &"doom")
	t.check(d.count() >= MarketPanicDirector.FAIR_NEED and o.check(rules) == Objective.Status.DONE and o.reason == "fair",
		"FAIR_NEED broken: the fair is scattered")
	Kit.done(s)
	var late := _world()
	var close := EventObjective.new("close", "Market closes", "market_closed")
	t.check(close.hud_text(late.rules) == "Market closes %s" % UiTheme.clock(MarketPanicDirector.MARKET_CLOSE), "the deadline row")
	(late.d as MarketPanicDirector).timeline.step(MarketPanicDirector.MARKET_CLOSE)
	t.check(close.check(late.rules) == Objective.Status.FAILED and close.deadline, "the guard closes the market at its time: lost")
	t.check(ResultsScreen.title_for(true, "fair") == "THE FAIR IS SCATTERED"
		and ResultsScreen.title_for(false, "market_closed") == "THE MARKET IS CLOSED", "its results' titles, under its own reasons")
	Kit.done(late)


static func _freed(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	Kit.free_body(s, (d.waves[0] as Array)[0] as Person)
	Kit.free_body(s, d.wards[0].man as Person)
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	t.check(d.count() == 1 and d.wave_count(0) == 1 and not Kit.labels(d).is_empty() and d.hint_phase() == "steadied"
		and int(d.report().festival_count) == 1, "a goer's body and a warden's freed: the goer counted; the tags and the hint untouched")
	Kit.done(s)


static func _texts(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var labels := Kit.labels(d)
	var fair := "THE FAIR - 0 / %d" % MarketPanicDirector.FAIR_NEED
	t.check(labels[0] == fair and Kit.edged(d, fair) and labels.count("WARDEN") == MarketPanicDirector.WARDENS
		and labels.has("NEXT CROWD") and Kit.edged(d, "NEXT CROWD") and d.hint_phase() == "",
		"THE FAIR with its count, pointed at; a WARDEN each; NEXT CROWD (%s)" % [labels])
	var pips := 0
	for m in d.tags():
		pips += 1 if m.color == FestivalDirector.MARK_GOER else 0
	t.check(pips == MarketPanicDirector.WAVE, "a gold diamond on each goer still to break, walkers too")
	var lines := []
	for stop: Array in d.tour():
		lines.append(String(stop[1]))
	t.check(lines == ["The night fair at the north-east fountain. Its wardens (red) keep the crowd calm.",
		"More come from the cathedral's street by %s." % UiTheme.clock(float(MarketPanicDirector.WAVE_AT[1])),
		"More come from the workshops by %s. The guard closes the market at %s." % [UiTheme.clock(float(MarketPanicDirector.WAVE_AT[2])),
		UiTheme.clock(MarketPanicDirector.MARKET_CLOSE)]], "the tour (%s)" % [lines])
	var missing := []
	for phase: String in ["", "steadied", "open", "coming"]:
		var line := MissionHints.line("market_panic", phase)
		if line == "" or (phase != "" and line == MissionHints.line("market_panic")):
			missing.append(phase)
	t.check(missing.is_empty(), "a hint line for every phase (missing: %s)" % [missing])
	Kit.done(s)
