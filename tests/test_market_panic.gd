extends RefCounted
## v0.11 M3 Market Panic (mission spec §2, MarketPanicDirector): a night fair at the north-east fountain -- no Mayor, one bonfire,
## the first crowd of WAVE walking in at once to spots within FAIR_R; WARDENS wardens (lay watchmen) at posts evenly round it, each
## pair more than one Silent Doom apart; on guard a warden is fearless and steadies the goers within WARD_R (a fright or a loud
## cast breaks none of them; a death counts); return and relief as Spoiled Harvest's; the three crowds to come appointed as the
## night begins and waiting on duty at their sources (an evacuation does not empty them), counted as goers from the start (one
## struck down while he waits counts; a crowd wholly gone before its time is scattered), setting out at their times, or CHAIN after
## the one before is scattered; goers at the fair hold to it against the town's regroup and evacuation (review focus 6);
## FAIR_NEED broken wins, the close loses. Freed bodies are borne (review focus 4); the tags, hints, tour, titles, camera and the
## mission's numbers; and Impact's hit-stop switch (the scripted run's exact replays).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_wardens(t)
	_relief(t)
	_appointed(t)
	_crowds(t)
	_scattered(t)
	_evacuated(t)
	_walking(t)
	_unsent(t)
	_stray(t)
	_hold(t)
	_ends(t)
	_freed(t)
	_texts(t)
	_impact(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.market_panic())


static func _setup(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var first: Array = d.waves[0]
	var ok := d.mayor == null and d.need == MarketPanicDirector.FAIR_NEED and first.size() == MarketPanicDirector.WAVE \
		and d.goers.size() == MarketPanicDirector.WAVE * MarketPanicDirector.SOURCES.size() and d.unbroken().size() == MarketPanicDirector.WAVE \
		and d.wards.size() == MarketPanicDirector.WARDENS
	for v: Variant in first:
		var p := v as Person
		var spot: Vector2 = d._spots[p.get_instance_id()]
		ok = ok and p.profile.faith == CitizenProfile.Faith.NONE and not p.soldier
		ok = ok and spot.distance_to(MarketPanicDirector.HEART) <= MarketPanicDirector.FAIR_R + 0.01 and d._reaches(p, spot)
		ok = ok and p.mind == Person.Mind.DUTY and p.anchor.distance_to(spot) < 0.01
	t.check(ok, "no Mayor; the first crowd of WAVE lay citizens walks in at once, on duty, each to a spot within FAIR_R of the fountain"
		+ " with a way to it")
	var apart := true
	var lay := true
	for i in d.wards.size():
		var a := d.wards[i].man as Person
		lay = lay and a.profile.role == CitizenProfile.Role.WATCHMAN and not d.goers.has(a) \
			and a.ground_pos.distance_to(MarketPanicDirector.HEART) < 2.5
		for j in range(i + 1, d.wards.size()):
			apart = apart and a.ground_pos.distance_to((d.wards[j].man as Person).ground_pos) > SilentDoom.RADIUS * 2.0
	t.check(lay and apart, "the wardens, lay watchmen at posts round the fountain, each pair more than one Silent Doom apart")
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["crowd_1", "crowd_2", "crowd_3", "close"], "the strip: the three crowds to come and the close (%s)" % [ids])
	var clear := true
	for spot in [MarketPanicDirector.HEART] + MarketPanicDirector.SOURCES.slice(1):
		clear = clear and Kit.clear_of_stack(spot, MarketPanicDirector.CAMERA_AT)
	t.check(clear, "the camera keeps the fair and the three sources clear of the left HUD stack")
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
	t.check(a.mind == Person.Mind.DUTY and a.anchor.distance_to(w.post) < 0.5,
		"a warden off his post, calm again, goes back after RETURN_AFTER")
	var old := a.get_instance_id()
	Kit.free_body(s, a)
	Kit.run_for(s, HarvestDirector.RELIEF_AFTER + MarketPanicDirector.TICK + DT)
	var fresh: Variant = w.man
	t.check(MissionDirector._alive(fresh) and (fresh as Person).get_instance_id() != old
		and (fresh as Person).profile.role == CitizenProfile.Role.WATCHMAN and (fresh as Person).anchor.distance_to(w.post) < 0.5
		and (s.banners as Array).has("A NEW WARDEN TAKES THE POST") and not d.goers.has(fresh),
		"a fallen warden is replaced RELIEF_AFTER after, by a lay citizen not at the fair")
	Kit.done(s)
	# The final review: end to end, the lay citizen nearest a fallen warden's post, shut in behind the houses, is passed over.
	var u := _world()
	var e: MarketPanicDirector = u.d
	var v := e.wards[2]
	var shut := Vector2(6.78, -10.23)  # behind the houses west of the fair: no cell of the walk grid (_scattered())
	var penned: Person = e._lay_near(v.post, 1, e._busy())[0]
	Kit.arrive(penned, shut)
	var away := e._walkable(Vector2(0.0, 0.0))
	for k in 60:
		var nearer: Person = e._lay_near(v.post, 1, e._busy() + [penned])[0]
		if nearer.ground_pos.distance_to(v.post) >= shut.distance_to(v.post):
			break
		Kit.arrive(nearer, away)
	var first_pick := e._lay_near(v.post, 1, e._busy())[0] == penned
	Kit.free_body(u, v.man as Person)
	Kit.run_for(u, HarvestDirector.RELIEF_AFTER + MarketPanicDirector.TICK + DT)
	t.check(first_pick and MissionDirector._alive(v.man) and v.man != penned and penned.profile.role != CitizenProfile.Role.WATCHMAN
		and e._reaches(v.man as Person, v.post),
		"the nearest lay citizen to a fallen warden's post, shut in a yard, is passed over: the relief is one with a way to it")
	Kit.done(u)


## The crowds to come are appointed as the night begins and wait on duty at their sources (Task 3's fix round).
static func _appointed(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var seen := {}
	var ok := true
	for w in d.wards:
		seen[w.man] = true
	for v: Variant in d.waves[0]:
		seen[v] = true
	for i in range(1, MarketPanicDirector.SOURCES.size()):
		var crew: Array = d.waves[i]
		ok = ok and crew.size() == MarketPanicDirector.WAVE and d.wave_out[i] < 0.0
		for v: Variant in crew:
			var p := v as Person
			ok = ok and not seen.has(v) and d.is_waiting(p) and d.goers.has(p) and p.mind == Person.Mind.DUTY \
				and p.profile.faith == CitizenProfile.Faith.NONE \
				and p.anchor.distance_to(MarketPanicDirector.SOURCES[i]) <= MarketPanicDirector.WAIT_STEP * 6.0
			seen[v] = true
	t.check(ok and d.waiting_goers().size() == MarketPanicDirector.WAVE * (MarketPanicDirector.SOURCES.size() - 1),
		"each crowd to come: WAVE lay citizens appointed as goers, on duty at a stand round its source, none twice, none a warden")
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


## A crowd is scattered when every one of it is gone (Task 3's fix round): broken, dead, or out of the town; one still standing keeps
## the next crowd to its own time.
static func _scattered(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var first: Array = d.waves[0]
	(first[first.size() - 1] as Person).fearless_left = 99.0  # the last is not frightened by the others' deaths
	for i in first.size() - 1:
		(s.crowd as Crowd)._field.kill(first[i] as Person, &"doom")
	Kit.run_for(s, DT * 2.0)
	var open := d.scattered_at[0] < 0.0 and d.wave_out[1] < 0.0
	d._left[first[first.size() - 1]] = true  # the last one got away out of the town unbroken
	Kit.run_for(s, DT * 2.0)
	t.check(open and d.scattered_at[0] >= 0.0 and d.count() == first.size() - 1,
		"all but one gone does not scatter a crowd; the last out of the town does, and counts for nothing")
	var p := first[0] as Person
	var shut := Vector2(6.78, -10.23)  # behind the houses west of the fair: no cell of the walk grid
	Kit.arrive(p, shut)
	t.check(not (s.crowd as Crowd)._grid.walkable(shut) and not d._reaches(p, d.wards[0].post)
		and d._reaches(d.wards[0].man as Person, d.wards[0].post),
		"a citizen shut in behind the houses has no way to a post; one at the post has")
	Kit.done(s)


## The town evacuates after the first crowd, and the second still walks in with its WAVE (Task 3's fix round: a loud cast or a
## seen kill must not empty a crowd to come); one of them killed where he waited is simply not sent.
static func _evacuated(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var crowd: Crowd = s.crowd
	var first: Array = d.waves[0]
	for i in MarketPanicDirector.WAVE_NEED:
		crowd._field.kill(first[i] as Person, &"doom")
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	var kept := true
	for i in range(1, MarketPanicDirector.SOURCES.size()):
		for v: Variant in d.waves[i]:
			kept = kept and (v as Person).mind == Person.Mind.DUTY
	t.check(kept, "the town's regroup and evacuation pass the crowds to come by: all still on duty at their stands")
	var held := (d.waves[1] as Array)[0] as Person
	held.panic(held.ground_pos + Vector2(1.0, 0.0), 1.0)
	t.check(held.mind == Person.Mind.DUTY and held.fearless_left > 0.0, "a fright takes none of them: held fearless while he waits")
	Kit.run_for(s, MarketPanicDirector.CHAIN + DT * 2.0)
	var second: Array = d.waves[1]
	var walking := d.walkers()
	var all_walk := true
	for v: Variant in second:
		all_walk = all_walk and walking.has(v) and (v as Person).mind == Person.Mind.DUTY and (v as Person).fearless_left == 0.0
	t.check(d.wave_out[1] >= 0.0 and second.size() == MarketPanicDirector.WAVE and all_walk and d.waiting_goers().size() > 0,
		"the town evacuated after the first crowd: the second still walks in with its %d, no longer held" % MarketPanicDirector.WAVE)
	Kit.done(s)


## The town evacuates while a crowd walks in (v0.11 M3 final review): the walkers are on duty, so the evacuation passes them by and
## every one of them reaches the fair. A goer at the fair whispered at that moment, and one waiting at his stand, wake back on their
## feet and hold to their places; one at the fair recovering at that moment, sent running, is called back to his spot.
static func _walking(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var crowd: Crowd = s.crowd
	var first: Array = d.waves[0]
	for w in d.wards:
		Kit.arrive(w.man as Person, w.post + Vector2(0.0, 12.0))  # off their posts: no warden steadies anyone
	d._send_wave(1)
	Kit.run_for(s, 1.0)
	var heard := first[0] as Person
	var shaken := first[1] as Person
	var waiter := (d.waves[2] as Array)[0] as Person
	for g: Person in [heard, shaken]:
		Kit.arrive(g, d._spots[g.get_instance_id()])
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	var held := heard.mind == Person.Mind.DUTY and shaken.mind == Person.Mind.DUTY
	heard.whisper(heard.ground_pos + Vector2(1.5, 0.0), 3.0)
	waiter.whisper(waiter.ground_pos + Vector2(1.5, 0.0), 3.0)
	shaken._recover(2.0)
	crowd._evacuate()
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	var second: Array = d.waves[1]
	var on_way := true
	for v: Variant in second:
		var p := v as Person
		on_way = on_way and p.mind == Person.Mind.DUTY and p.anchor.distance_to(d._spots[p.get_instance_id()]) < 0.01
	t.check(held and on_way and shaken.mind == Person.Mind.DUTY
		and shaken.anchor.distance_to(d._spots[shaken.get_instance_id()]) < 0.01,
		"the town evacuates as the second crowd walks in: every walker still on duty for his spot; one recovering at the fair called back")
	for v: Variant in second:
		Kit.arrive(v as Person, d._spots[(v as Person).get_instance_id()])
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	var there := true
	for v: Variant in second:
		var p := v as Person
		there = there and d._arrived.has(p.get_instance_id()) and p.mind == Person.Mind.DUTY
	t.check(there and d.unbroken().size() == MarketPanicDirector.WAVE * 2 and d.count() == 0,
		"all %d of the second crowd reach the fair and hold to it" % MarketPanicDirector.WAVE)
	heard._wake()
	waiter._wake()
	var woke := heard.mind != Person.Mind.FLEE and waiter.mind != Person.Mind.FLEE
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	t.check(woke and heard.mind == Person.Mind.DUTY and heard.anchor.distance_to(d._spots[heard.get_instance_id()]) < 0.01
		and waiter.mind == Person.Mind.DUTY and d.is_waiting(waiter),
		"a goer at the fair and one at his stand, whispered as the town evacuated, wake on their feet and go back, not out of the town")
	Kit.done(s)


## A goer his crowd could not send as it set out -- whispered or confused then -- is sent once back on his feet (v0.11 M3 final
## review), on duty to a spot of his own, so the hint never waits on "coming" for him.
static func _unsent(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var late := (d.waves[1] as Array)[0] as Person
	late.whisper(late.ground_pos + Vector2(1.5, 0.0), 3.0)
	d._send_wave(1)
	var skipped := not d._spots.has(late.get_instance_id())
	late._wake()
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	var spot: Vector2 = d._spots.get(late.get_instance_id(), Vector2.INF)
	t.check(skipped and late.mind == Person.Mind.DUTY and spot.distance_to(MarketPanicDirector.HEART) <= MarketPanicDirector.FAIR_R + 0.01
		and late.anchor.distance_to(spot) < 0.01, "a goer whispered as his crowd set out is sent to his own spot once on his feet")
	for v: Variant in d.goers:
		var p := v as Person
		if not d.is_waiting(p):
			Kit.arrive(p, d._spots[p.get_instance_id()])
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	t.check(d.walkers().is_empty() and d.hint_phase() != "coming", "and once he is there the hint no longer says more are coming")
	Kit.done(s)


## A goer of any crowd struck down before he walks in counts toward the need, as the Festival counts any of its crowd (Task 3's
## fix round 2): nine stray kills at a source do not make the night unwinnable. One not sent is not walked; a crowd wholly gone
## before its time is out and scattered, and the next one's chain moves on.
static func _stray(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var crowd: Crowd = s.crowd
	var third: Array = d.waves[2]
	var n := 9
	for i in n:
		crowd._field.kill(third[i] as Person, &"fire")
	Kit.run_for(s, DT * 2.0)
	t.check(d.count() == n and d.wave_out[2] < 0.0 and d.scattered_at[2] < 0.0
		and d.waiting_goers().size() == MarketPanicDirector.WAVE * 3 - n,
		"%d of the third crowd struck down where they waited: the fair's broken count rises by %d" % [n, n])
	for i in range(1, MarketPanicDirector.SOURCES.size()):
		d._send_wave(i)
	t.check((d.waves[2] as Array).size() == MarketPanicDirector.WAVE and d.unbroken().size() == MarketPanicDirector.WAVE * 4 - n,
		"the rest of them still set out, and the dead are not walked")
	for v: Variant in d.goers:
		if MissionDirector._alive(v):
			crowd._field.kill(v as Person, &"doom")
	var o := FestivalObjective.new("Scatter the fair", "fair")
	t.check(d.count() == d.goers.size() and d.count() >= MarketPanicDirector.FAIR_NEED and o.check(s.rules) == Objective.Status.DONE,
		"and with every one of them struck down the night is won: the stray kills lost it nothing")
	Kit.done(s)
	var u := _world()
	var e: MarketPanicDirector = u.d
	for v: Variant in e.waves[2]:
		(u.crowd as Crowd)._field.kill(v as Person, &"fire")
	Kit.run_for(u, DT * 2.0)
	t.check(e.scattered_at[2] >= 0.0 and e.wave_out[2] >= 0.0 and not (u.banners as Array).has("MORE COME TO THE FAIR")
		and e.next_wave() == 1 and e.count() == MarketPanicDirector.WAVE,
		"a whole waiting crowd struck down is scattered before its time: out, nothing comes, and the count has all of it")
	var shown := e.timeline.seconds_to("crowd_3")
	Kit.run_for(u, MarketPanicDirector.CHAIN + DT * 4.0)
	t.check(shown <= MarketPanicDirector.CHAIN + 0.1 and e.wave_out[3] >= 0.0 and e.wave_out[1] < 0.0,
		"and the crowd after it is due 45 s after at the latest: the strip says so (%.1f s) and it sets out" % shown)
	Kit.done(u)
	var w := _world()
	var f: MarketPanicDirector = w.d
	var stand := (f.waves[1] as Array)[0] as Person
	var before := f.count()
	(w.crowd as Crowd)._field.kill(stand, &"doom")
	f._send_wave(1)
	t.check(f.count() == before + 1 and (f.waves[1] as Array).size() == MarketPanicDirector.WAVE and not f.walkers().has(stand),
		"one killed where he waited is counted and not walked")
	Kit.done(w)


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
	for i in range(1, MarketPanicDirector.SOURCES.size()):
		d._send_wave(i)
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
	Kit.free_body(s, (d.waves[1] as Array)[0] as Person)
	Kit.run_for(s, MarketPanicDirector.TICK * 2.0)
	t.check(d.count() == 2 and d.wave_count(0) == 1 and d.wave_count(1) == 1 and not Kit.labels(d).is_empty()
		and d.hint_phase() == "steadied" and int(d.report().festival_count) == 2,
		"a goer's body, a warden's and a waiting person's freed: both goers counted; the tags and the hint untouched")
	Kit.done(s)


static func _texts(t) -> void:
	var s := _world()
	var d: MarketPanicDirector = s.d
	var labels := Kit.labels(d)
	var fair := "THE FAIR - 0 / %d" % MarketPanicDirector.FAIR_NEED
	var next := "NEXT CROWD %s" % UiTheme.clock(float(MarketPanicDirector.WAVE_AT[1]))
	t.check(labels[0] == fair and Kit.edged(d, fair) and labels.count("WARDEN") == MarketPanicDirector.WARDENS
		and labels.has(next) and Kit.edged(d, next) and d.hint_phase() == "",
		"THE FAIR with its count, pointed at; a WARDEN each; NEXT CROWD and the time to it, pointed at (%s)" % [labels])
	var pips := 0
	for m in d.tags():
		pips += 1 if m.color == FestivalDirector.MARK_GOER else 0
	t.check(pips == MarketPanicDirector.WAVE * MarketPanicDirector.SOURCES.size(),
		"a gold diamond on each goer still to break, walkers and the ones waiting at their stands too")
	var s2 := _world()
	var d2: MarketPanicDirector = s2.d
	Kit.run_for(s2, 30.0)
	var counted := false
	for sec in ["0:44", "0:45", "0:46"]:
		counted = counted or Kit.labels(d2).has("NEXT CROWD " + sec)
	t.check(counted, "the NEXT CROWD tag counts down the seconds to its time (%s)" % [Kit.labels(d2)])
	Kit.done(s2)
	var lines := []
	for stop: Array in d.tour():
		lines.append(String(stop[1]))
	t.check(lines == ["The night fair at the north-east fountain. Its wardens (red) keep the crowd calm.",
		"More come from the cathedral's street by %s." % UiTheme.clock(float(MarketPanicDirector.WAVE_AT[1])),
		"More come from the workshops by %s." % UiTheme.clock(float(MarketPanicDirector.WAVE_AT[2])),
		"More come from the east tavern by %s. The guard closes the market at %s." % [UiTheme.clock(float(MarketPanicDirector.WAVE_AT[3])),
		UiTheme.clock(MarketPanicDirector.MARKET_CLOSE)]], "the tour (%s)" % [lines])
	var missing := []
	for phase: String in ["", "steadied", "open", "coming"]:
		var line := MissionHints.line("market_panic", phase)
		if line == "" or (phase != "" and line == MissionHints.line("market_panic")):
			missing.append(phase)
	t.check(missing.is_empty(), "a hint line for every phase (missing: %s)" % [missing])
	t.check(MissionHints.line("market_panic").contains("Thirty-six") and MarketPanicDirector.FAIR_NEED == 36,
		"the hint's \"Thirty-six\" is FAIR_NEED in words: retune one, reword the other")
	Kit.done(s)


## Impact's hit-stop switch (Task 3's fix round): on, a hit dips the engine's time scale; off, it does nothing, so a scripted run
## replays exactly. The engine's time scale is put back at once.
static func _impact(t) -> void:
	var on := Impact.new()
	on.hitstop(0.05)
	var dipped := Engine.time_scale < 1.0
	Engine.time_scale = 1.0
	var off := Impact.new()
	off.hitstop_enabled = false
	off.hitstop(0.05)
	var held := is_equal_approx(Engine.time_scale, 1.0)
	Engine.time_scale = 1.0
	t.check(on.hitstop_enabled and dipped and not off.hitstop_enabled and held,
		"Impact: hit-stop on by default; off, it leaves the time scale alone")
	on.free()
	off.free()
