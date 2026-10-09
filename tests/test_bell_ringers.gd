extends RefCounted
## v0.11 M3 The Bell-Ringers (mission spec §1; BellRingersDirector, RingerDirector): three wall towers, each with a ringer and his
## MATES inside (lay watchmen, no soldiers); the posts and the bell tower only shake; each post sends its ringer at its time,
## CHAIN_WAIT after the warning before is stopped, or at once when a loud power is cast near it (never a quiet one); they stand
## OUT_PAUSE, his mates beyond one Doom of him, then the ringer runs for the bell's foot, his mates at his heels; a seen death
## passes the warning on; at the foot a carrier takes the rope himself (one rope: a second waits, and takes it if the climber is
## pulled off) and climbs 12 s; stopped on the rope, the bell goes back to its keeper, idle (review focus 2). All three stopped
## wins; a rung bell loses. Freed bodies are borne (review focus 4); the tags, hints, tour, titles, camera and the mission's
## numbers. The controller's rulings: the waiting posts pointed at from the edge; the keeper called again by the hand-back at
## Local Emergency; a relay never picks another warning's people.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_set_out(t)
	_chain(t)
	_relay(t)
	_rope(t)
	_recall(t)
	_two(t)
	_ends(t)
	_freed(t)
	_texts(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.bell_ringers())


## Kills `r`'s carrier unseen: everyone within sight of him is moved well away first, then a step judges it.
static func _stop(s: Dictionary, r: RingerDirector) -> void:
	var c := r.messenger
	_clear_round(s, c, [])
	(s.crowd as Crowd)._field.kill(c, &"doom")
	Kit.run_for(s, DT * 2.0)


## Moves everyone within sight of `c` (but `c` and those in `spare`) six units off him (v0.11 M3).
static func _clear_round(s: Dictionary, c: Person, spare: Array) -> void:
	for group: Array[Person] in [(s.crowd as Crowd).citizens, (s.crowd as Crowd).soldiers]:
		for p in group:
			if is_instance_valid(p) and p != c and not spare.has(p) and p.is_alive() \
					and p.ground_pos.distance_to(c.ground_pos) <= Crowd.DOOM_WITNESS + 0.5:
				var off := p.ground_pos - c.ground_pos
				Kit.arrive(p, c.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * 6.0)


## The length of the walk grid's way from `from` to `to` (v0.11 M3).
static func _route(s: Dictionary, from: Vector2, to: Vector2) -> float:
	var n := 0.0
	var at := from
	for p in (s.crowd as Crowd)._grid.path(from, to):
		n += at.distance_to(p)
		at = p
	return n


## Puts `r`'s carrier at the bell's foot on his errand, with nowhere left to walk.
static func _at_foot(r: RingerDirector, bell: BellNetwork) -> void:
	Kit.arrive(r.messenger, bell.foot)
	r.messenger.mind = Person.Mind.DUTY
	r.phase = WarningDirector.Phase.RUN


## `r`'s carrier, at the bell's foot, takes the rope, stands on the rope's own spot (headless tests think no one: his last few
## tenths of a unit are dropped), and a bell step starts the climb.
static func _climb(r: RingerDirector, bell: BellNetwork) -> void:
	_at_foot(r, bell)
	r._run()
	Kit.arrive(r.messenger, bell.foot)
	bell.step(DT)


static func _setup(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var bell := (s.crowd as Crowd).bell
	var seen := {}
	var ok := d.posts.size() == 3 and d.ringers.size() == 3
	for i in d.ringers.size():
		var r := d.ringers[i]
		ok = ok and RuinWish.fits(d.posts[i], "tower") and d.doors[i] != Vector2.INF and r.waiting and r.mates.size() == RingerDirector.MATES
		var crew: Array = [r.watchman]
		crew.append_array(r.mates)
		for v: Variant in crew:
			var p := v as Person
			ok = ok and p.inside and not p.soldier and p.profile.role == CitizenProfile.Role.WATCHMAN and not seen.has(p)
			seen[p] = true
	t.check(ok and seen.size() == 3 * (1 + RingerDirector.MATES),
		"three wall towers, each with a ringer and his mates inside: %d lay watchmen, no soldiers" % seen.size())
	var post := d.posts[0]
	var hp := post.hp
	post.damage(500.0, post.center(), &"smite")
	bell.tower.damage(500.0, bell.tower.center(), &"smite")
	t.check(is_equal_approx(post.hp, hp) and not post.destroyed and not bell.tower.destroyed, "stone tonight: a post and the bell tower only shake")
	var inside := true
	var runs: Array[float] = []
	for i in d.doors.size():
		inside = inside and d.doors[i].distance_to(TownLayout.MAP.get_center()) < d.posts[i].center().distance_to(TownLayout.MAP.get_center())
		runs.append(_route(s, bell.foot, d.doors[i]))
	t.check(inside and runs[2] < runs[0] and runs[2] < runs[1],
		"each post's door is its town-side one, inside the wall; the east post's run is the shortest (%s)" % [runs])
	var clear := Kit.clear_of_stack(bell.foot, BellRingersDirector.CAMERA_AT)
	for door in d.doors:
		clear = clear and Kit.clear_of_stack(door, BellRingersDirector.CAMERA_AT)
	t.check(clear, "the camera keeps every post (or its arrow) and the bell tower clear of the left HUD stack")
	var sw := Kit.shown_at(d.doors[1], BellRingersDirector.CAMERA_AT)
	t.check(is_equal_approx(sw.x, 0.0) and sw.y > Kit.DEAD.end.y, "the south-west post off screen, its arrow on the left edge below the stack (%s)" % sw)
	d.teardown()
	t.check(not post.damage_filter.is_valid() and not bell.tower.damage_filter.is_valid(), "teardown gives the stone back")
	var m := MissionBook.bell_ringers()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 2 and is_equal_approx(m.clock, 330.0) and m.slots == 3 and m.dp_capacity == 8 and not m.allows("blight")
		and not m.allows("belllies") and m.allows("doom") and reasons == ["ringers", "bell", "dawn"] and m.bonuses().is_empty()
		and MissionBook.get_mission("bell_ringers").id == "bell_ringers" and m.camera_at == BellRingersDirector.CAMERA_AT,
		"the mission: Tier 2's numbers, no Blight nor The Bell Lies; the ringers, the bell, dawn (%s)" % [reasons])
	Kit.done(s)


static func _set_out(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var r := d.ringers[0]
	var bell := (s.crowd as Crowd).bell
	Kit.run_for(s, float(BellRingersDirector.SET_OUT_AT[0]) - 0.5)
	var still := r.waiting and r.watchman.inside and Kit.edged(d, "NEXT POST")
	Kit.run_for(s, 0.5 + DT * 2.0)
	t.check(still and not r.waiting and not r.watchman.inside and r.watchman.ground_pos.distance_to(d.doors[0]) < 1.0
		and (s.banners as Array).has("THE NORTH-EAST POST SENDS ITS RINGER"), "the north-east post sends its ringer at its time, out at the door")
	var apart := true
	for v: Variant in r.mates:
		var gap := (v as Person).ground_pos.distance_to(r.watchman.ground_pos)
		apart = apart and not (v as Person).inside and gap > SilentDoom.RADIUS and gap <= Crowd.DOOM_WITNESS
	t.check(apart, "his mates out with him, beyond one Silent Doom of him, within sight: one strike at the door never ends it")
	Kit.run_for(s, RingerDirector.OUT_PAUSE + WarningDirector.RETARGET + DT * 2.0)
	t.check(r.phase == WarningDirector.Phase.RUN and r.messenger.mind == Person.Mind.DUTY
		and r.messenger.goal().distance_to(bell.foot) < 0.6, "after OUT_PAUSE the ringer runs for the bell's foot, not the bellkeeper")
	Kit.run_for(s, RingerDirector.MATE_TICK + DT)
	var heels := r.mates.size() == RingerDirector.MATES
	for v: Variant in r.mates:
		var gap := (v as Person).goal().distance_to(r.messenger.ground_pos)
		heels = heels and (v as Person).mind == Person.Mind.DUTY and gap > SilentDoom.RADIUS and gap <= Crowd.DOOM_WITNESS + 0.3
	t.check(heels, "his mates at his heels: beyond one Silent Doom of him, within sight")
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var rules: Rules = s.rules
	d._send(0)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	_stop(s, d.ringers[0])
	var shown := d.timeline.seconds_to("out_1")
	t.check(d.ringers[0].warning_dead and d.stopped() == 1 and shown <= BellRingersDirector.CHAIN_WAIT + 0.1
		and String(d.timeline.upcoming(1)[0].id) == "out_1" and d.hint_phase() == "waiting",
		"killed unseen, the warning dies; the strip shows the next post within CHAIN_WAIT (%.1f s); the hint waits" % shown)
	Kit.run_for(s, BellRingersDirector.CHAIN_WAIT + DT * 2.0)
	t.check(not d.ringers[1].waiting and d.ringers[2].waiting, "the south-west post sends its ringer CHAIN_WAIT after, not at its own time")
	rules.cast_made.emit(0, "doom", d.doors[2])
	t.check(d.ringers[2].waiting, "a quiet power by a post sends no one")
	rules.cast_made.emit(0, "smite", d.doors[2] + Vector2(BellRingersDirector.POST_SIGHT - 0.5, 0.0))
	t.check(not d.ringers[2].waiting and (s.banners as Array).has("THE EAST POST SEES YOU"), "a loud one within POST_SIGHT sends its ringer at once")
	Kit.done(s)


static func _relay(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var r := d.ringers[0]
	d._send(0)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	var first := r.messenger
	var crew := r.mates.duplicate()
	(s.crowd as Crowd)._field.kill(first, &"doom")
	Kit.run_for(s, RingerDirector.MATE_TICK + DT * 2.0)
	t.check(not r.warning_dead and r.messenger != first and r.relays == 1 and crew.has(r.messenger) and not r.mates.has(r.messenger)
		and (s.banners as Array).has("THE WARNING PASSES ON") and d.hint_phase() == "relay",
		"one strike never ends it: a mate beside him saw, and carries the warning on")
	Kit.done(s)


static func _rope(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var bell := (s.crowd as Crowd).bell
	var own := bell.keeper
	var a := d.ringers[0]
	var b := d.ringers[1]
	d._send(0)
	d._send(1)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	_climb(a, bell)
	t.check(bell.keeper == a.messenger and bell.state == BellNetwork.State.CLIMBING and MissionDirector._alive(own)
		and is_equal_approx(bell.climb, 8.0 * BellNetwork.ESCORT_CLIMB) and d.hint_phase() == "climbing"
		and Kit.labels(d).has("RINGER - CLIMBING"), "a carrier at the foot takes the rope himself, the keeper alive, and climbs 12 s")
	_at_foot(b, bell)
	b._run()
	t.check(bell.keeper == a.messenger and b.phase == WarningDirector.Phase.RUN, "one rope: the second carrier waits at the foot")
	a.messenger.confuse(5.0)
	bell.step(DT)
	b._run()
	t.check(bell.keeper == b.messenger and bell.state == BellNetwork.State.CALLED and b.phase == WarningDirector.Phase.DELIVERED,
		"the climber pulled off by Discord: the carrier waiting takes the rope")
	a.messenger.mind = Person.Mind.CALM
	a.step(DT)
	t.check(a.phase == WarningDirector.Phase.RUN, "back on his feet, the first goes back to the foot to wait his turn")
	_stop(s, b)
	t.check(b.warning_dead and bell.keeper == own and bell.state == BellNetwork.State.IDLE and is_equal_approx(bell.climb, 8.0),
		"stopped on the rope: the bell goes back to its own keeper, idle (Decision 7)")
	_at_foot(a, bell)
	a._run()
	t.check(bell.keeper == a.messenger, "and the next carrier takes the rope")
	Kit.done(s)


## Controller ruling (review focus 2): the town calls its bellkeeper while a ringer holds the rope -- a call the bell cannot take
## then; the ringer stopped on the rope, the hand-back calls the keeper again, as the town is at Local Emergency.
static func _recall(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	var own := bell.keeper
	var a := d.ringers[0]
	d._send(0)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	_climb(a, bell)
	crowd.alarms.stage = AlarmManager.Stage.LOCAL_EMERGENCY
	bell.call_keeper()
	var held := bell.keeper == a.messenger and bell.state == BellNetwork.State.CLIMBING and not d.called()
	_stop(s, a)
	t.check(held and a.warning_dead and bell.keeper == own and bell.state == BellNetwork.State.CALLED and own.mind == Person.Mind.DUTY
		and d.called() and d.hint_phase() == "bell" and Kit.labels(d).has("BELLKEEPER"),
		"the town called its keeper while a ringer held the rope: stopped on it, the rope goes back and the keeper is called again")
	Kit.done(s)


## Controller ruling: a relay never picks another warning's people. The climber killed in sight of only the carrier waiting at the
## foot and his mate: neither takes the climber's warning on -- one kill never stops two warnings, and no man takes orders from
## two -- so the climber's warning dies, and the carrier waiting takes the rope.
static func _two(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var bell := (s.crowd as Crowd).bell
	var a := d.ringers[0]
	var b := d.ringers[1]
	d._send(0)
	d._send(1)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	_climb(a, bell)
	_at_foot(b, bell)
	b._run()
	var climber := a.messenger
	var waiter := b.messenger
	var mate := b.mates[0] as Person
	Kit.arrive(mate, bell.foot + Vector2(0.5, 0.0))
	_clear_round(s, climber, [waiter, mate])
	var unmarked := not a.witnesses().has(waiter) and not a.witnesses().has(mate) and b.witnesses().has(mate)
	(s.crowd as Crowd)._field.kill(climber, &"doom")
	Kit.run_for(s, DT * 2.0)
	t.check(unmarked and a.warning_dead and a.relays == 0 and not b.warning_dead and b.messenger == waiter and a.messenger != waiter
		and b.mates.has(mate) and d.stopped() == 1, "the climber killed in sight of another warning's carrier and mate only: neither carries it on, so it dies")
	var back := bell.keeper != climber and bell.state == BellNetwork.State.IDLE
	_at_foot(b, bell)
	b._run()
	t.check(back and bell.keeper == waiter and not b.warning_dead and b.messenger == waiter,
		"the rope given back, the carrier waiting at the foot takes it, back on his errand")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var rules: Rules = s.rules
	var o := StarsObjective.new("Stop the ringers", "ringers", "Ringers stopped")
	t.check(o.check(rules) == Objective.Status.PENDING and o.hud_text(rules) == "Ringers stopped 0 / 3", "the HUD: Ringers stopped 0 / 3")
	for r in d.ringers:
		r.warning_dead = true
	t.check(o.check(rules) == Objective.Status.DONE and o.reason == "ringers" and o.hud_text(rules) == "Ringers stopped 3 / 3",
		"all three stopped: the main objective is done")
	t.check(StarsObjective.new().label == "Stop the warnings" and StarsObjective.new().reason == "warning"
		and StarsObjective.tally(MissionDirector.new()) == Vector2i.ZERO and StarsObjective.tally(null) == Vector2i.ZERO,
		"StarsObjective keeps the board Warning's words; another director counts nothing")
	(s.crowd as Crowd).bell.state = BellNetwork.State.RUNG
	t.check(BellSilentObjective.new().check(rules) == Objective.Status.FAILED, "the bell tolling loses, whoever rang it")
	t.check(ResultsScreen.title_for(true, "ringers") == "THE RINGERS ARE STOPPED" and ResultsScreen.title_for(false, "bell") == "THE BELL TOLLS"
		and ResultsScreen.title_for(false, "dawn") == "DAWN COMES", "its results' titles, under its own reason")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var r := d.ringers[0]
	d._send(0)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	Kit.free_body(s, r.mates[0] as Person)
	Kit.run_for(s, RingerDirector.MATE_TICK + DT * 2.0)
	t.check(r.mates.size() == RingerDirector.MATES - 1 and not d.tags().is_empty() and d.hint_phase() in ["mates", "relay", ""],
		"a mate's body freed: the warning runs on, the freed one untouched")
	_stop(s, r)
	Kit.free_body(s, r.messenger)
	Kit.run_for(s, DT * 2.0)
	t.check(r.warning_dead and r.tags().is_empty() and r.mates_with().is_empty() and d.hint_phase() == "waiting"
		and int(d.report().stopped) == 1, "the stopped carrier's body freed: untagged, the hint on the next post, counted")
	Kit.done(s)


static func _texts(t) -> void:
	var s := _world()
	var d: BellRingersDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels.count("NEXT POST") == 1 and labels.count("WATCH POST") == 2 and labels.has("BELL TOWER") and Kit.edged(d, "NEXT POST")
		and Kit.edged(d, "WATCH POST") and d.hint_phase() == "",
		"at first: NEXT POST and the WATCH POSTs (each pointed at) and the BELL TOWER (%s)" % [labels])
	var at := []
	for i in 3:
		at.append(UiTheme.clock(float(BellRingersDirector.SET_OUT_AT[i])))
	var lines := []
	for stop: Array in d.tour():
		lines.append(String(stop[1]))
	t.check(lines == ["The north-east post. Its ringer runs for the bell at %s." % at[0],
		"The south-west post. Its ringer comes by %s." % at[1], "The east post. Its ringer comes by %s, by the shortest way." % at[2],
		"The bell tower. A ringer who reaches it climbs and rings it himself."], "the tour (%s)" % [lines])
	d._send(0)
	Kit.run_for(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	labels = Kit.labels(d)
	t.check(labels.has("RINGER") and Kit.edged(d, "RINGER") and labels.count("MATE") == RingerDirector.MATES and d.hint_phase() == "mates",
		"out: the RINGER pointed at, his MATEs, the hint on them (%s)" % [labels])
	(s.crowd as Crowd).bell.call_keeper()
	t.check(d.called() and Kit.labels(d).has("BELLKEEPER") and Kit.edged(d, "BELLKEEPER") and d.hint_phase() == "bell",
		"the town calls its bellkeeper: pointed at, and the hint on him")
	var missing := []
	for phase: String in ["", "mates", "relay", "climbing", "bell", "waiting"]:
		var line := MissionHints.line("bell_ringers", phase)
		if line == "" or (phase != "" and line == MissionHints.line("bell_ringers")):
			missing.append(phase)
	t.check(missing.is_empty(), "a hint line for every phase (missing: %s)" % [missing])
	Kit.done(s)
