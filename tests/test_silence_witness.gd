extends RefCounted
## God P5 Task 5 (plan Task 5, MS §3; Ruling P5-12, C2, C3, C9): Hunt 2, Silence the witness -- SilenceWitnessDirector (BellRingersDirector's timeline and
## chain over four quiet district houses), WitnessDirector (a RingerDirector with the bell taken out) and WitnessObjective. Four witnesses, each with two
## mates inside a house until sent; the Hunt's rule: only his own mates carry the word on (`THE MATE RUNS ON`), the town never does; a witness stopped is
## dead with no mate to carry it or out of the walls; one within TempleReport.REACH of the Temple's door loses `word`; the bell never decides it (C3: the
## witness tells no keeper and never takes the rope); the toll only turns the Lantern. People do not walk in these worlds (no scene tree): a test places
## them, as test_bell_ringers does.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


## A director that reports a full count and a word reaching the Temple at once (WitnessObjective's order: the win first).
class Both:
	extends MissionDirector

	func stars_stopped() -> int:
		return 4

	func stars_total() -> int:
		return 4

	func lost_reason() -> String:
		return "word"


static func run(t) -> void:
	_setup(t)
	_frame(t)
	_chain(t)
	_mates_apart(t)
	_relay_mate(t)
	_no_luck(t)
	_held_mate(t)
	_out_of_walls(t)
	_keeper_inert(t)
	_word_in(t)
	_win(t)
	_lantern(t)
	_no_keeper_tags(t)
	_tags(t)
	_evacuation(t)
	_freed(t)
	_texts(t)
	_hunt_wishes(t)


## The Hunt's world: its town, Rules and director, with the watch Lantern the game gives the night (Mission builds it; test_lantern does the same).
static func _world() -> Dictionary:
	var s := Kit.world(MissionBook.silence_witness())
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, LanternWatch.KIND_WATCH)
	(s.rules as Rules).lantern = lw
	return s


## The padded HUD stack (the kit's grown by Hud.STACK_PAD).
static func _keepout() -> Rect2:
	return Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))


## House `i` sends its witness and the night runs until he walks (his stare is over): returns his warning.
static func _out(s: Dictionary, i: int) -> WitnessDirector:
	var d: SilenceWitnessDirector = s.d
	d._send(i)
	Kit.run_for(s, SilenceWitnessDirector.SW_OUT_PAUSE + WarningDirector.RETARGET + DT * 2.0)
	return d.ringers[i] as WitnessDirector


## Everyone out of doors within sight of `c` but those in `spare` moved six units off him.
static func _clear_round(s: Dictionary, c: Person, spare: Array) -> void:
	for group: Array[Person] in [(s.crowd as Crowd).citizens, (s.crowd as Crowd).soldiers]:
		for p in group:
			if is_instance_valid(p) and p != c and not spare.has(p) and p.is_alive() and not p.inside \
					and p.ground_pos.distance_to(c.ground_pos) <= Crowd.DOOM_WITNESS + 0.5:
				var off := p.ground_pos - c.ground_pos
				Kit.arrive(p, c.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * 6.0)


## Kills `r`'s carrier with nobody (but `spare`) in sight, and lets a step judge it.
static func _stop(s: Dictionary, r: WitnessDirector, spare := []) -> void:
	var c := r.messenger
	_clear_round(s, c, spare)
	(s.crowd as Crowd)._field.kill(c, &"doom")
	Kit.run_for(s, DT * 2.0)


## The length of the walk grid's way from `from` to `to`.
static func _route(s: Dictionary, from: Vector2, to: Vector2) -> float:
	var n := 0.0
	var at := from
	for p in (s.crowd as Crowd)._grid.path(from, to):
		n += at.distance_to(p)
		at = p
	return n


static func _labels(d: MissionDirector) -> Array:
	return Kit.labels(d)


static func _setup(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var door := d.lantern_door()
	var seen := {}
	var ok := d.posts.size() == 4 and d.ringers.size() == 4 and d.doors.size() == 4
	var quiet := true
	var runs: Array[float] = []
	for i in d.ringers.size():
		var r := d.ringers[i]
		ok = ok and r is WitnessDirector and RuinWish.fits(d.posts[i], "house") and d.doors[i] != Vector2.INF and r.waiting \
			and r.mates.size() == SilenceWitnessDirector.SW_MATES and r.walls_stop and r.tower == d.posts[i]
		quiet = quiet and d._quiet(d.doors[i])
		runs.append(_route(s, door, d.doors[i]))
		var crew: Array = [r.watchman]
		crew.append_array(r.mates)
		for v: Variant in crew:
			var p := v as Person
			ok = ok and p.inside and not p.soldier and p.profile.role == CitizenProfile.Role.WATCHMAN and not seen.has(p)
			seen[p] = true
	t.check(ok and seen.size() == 4 * 3, "four houses, each with a witness and two mates inside (lay watchmen, no soldiers, %d people)" % seen.size())
	t.check(quiet, "each house's door is quiet: no beat within %.1f" % SilenceWitnessDirector.SW_QUIET)
	var in_range := 0
	for k in runs.size():
		in_range += 1 if runs[k] >= SilenceWitnessDirector.SW_STREET.x and runs[k] <= SilenceWitnessDirector.SW_STREET.y else 0
	t.check(in_range >= 3 and runs.min() > 19.0 and runs.max() <= SilenceWitnessDirector.SW_STREET.y + 0.01,
		"three houses lie 22-32 units of street from the Temple's door, the north-east (no dwelling there is that far) the closest to it (%s)" % [runs])
	var names := []
	for n in d.post_names:
		names.append(n)
	t.check(names == ["west", "south-west", "south-east", "north-east"], "one house per district, in order (%s)" % [names])
	var apart := true
	for i in d.doors.size():
		for k in range(i + 1, d.doors.size()):
			apart = apart and d.doors[i].distance_to(d.doors[k]) > 2.0 * SilentDoom.RADIUS
	t.check(apart, "the four houses' doors are more than two Silent Doom radii apart")
	var house: Structure = d.posts[0]
	var hp := house.hp
	house.damage(500.0, house.center(), &"smite")
	t.check(is_equal_approx(house.hp, hp) and not house.destroyed, "stone tonight: a blow only shakes a house")
	var bell := (s.crowd as Crowd).bell
	var tower_hp := bell.tower.hp
	bell.tower.damage(5.0, bell.tower.center(), &"smite")
	t.check(bell.tower.hp < tower_hp, "the bell tower is not made stone (the bell is not this Hunt's)")
	t.check((s.banners as Array).has("SILENCE THE WITNESS"), "the night opens with its banner")
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["out_0", "out_1", "out_2", "out_3"], "the strip: the four witnesses from 0:20 (%s)" % [ids])
	d.teardown()
	t.check(not house.damage_filter.is_valid(), "teardown gives the stone back")
	Kit.done(s)


static func _frame(t) -> void:
	var m := MissionBook.silence_witness()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 2 and is_equal_approx(m.clock, 330.0) and m.slots == 3 and m.dp_capacity == 8 and m.lantern == LanternWatch.KIND_WATCH
		and m.director == SilenceWitnessDirector and reasons == ["witnesses", "dawn"] and m.objectives()[0] is WitnessObjective
		and m.camera_at == SilenceWitnessDirector.SW_CAMERA_AT and m.intro_from == m.camera_at + Vector2(0.0, 6.0)
		and m.default_loadout == PackedStringArray(["doom", "whisper", "discord"]) and HuntBook.def("silence_witness").director == SilenceWitnessDirector,
		"the frame: Tier 2's numbers, a watch Lantern, the witnesses' objective then the dawn, the Hunt's director and camera (%s)" % [reasons])
	var o := m.objectives()[0] as WitnessObjective
	t.check(o.label == "Silence the witnesses" and o.count_text == "Witnesses silenced" and o.reason == "witnesses",
		"WitnessObjective's words: %s / %s" % [o.label, o.count_text])
	# C2: the numbers are the Hunt's own consts, copied into the bases' vars; the one the base has equals the base's.
	var d := SilenceWitnessDirector.new()
	t.check(d.tune_set_out_at == SilenceWitnessDirector.SW_OUT_AT and is_equal_approx(d.tune_chain_wait, 45.0)
		and SilenceWitnessDirector.SW_POST_SIGHT == BellRingersDirector.POST_SIGHT and SilenceWitnessDirector.SW_OUT_AT == [20.0, 75.0, 130.0, 185.0]
		and BellRingersDirector.SET_OUT_AT == [40.0, 110.0, 180.0] and RingerDirector.MATE_SIDE == 0.7,
		"the Hunt's times and chain in the base's vars, the base's own consts untouched (%s, %s)" % [d.tune_set_out_at, d.tune_chain_wait])
	t.check(is_equal_approx(SilenceWitnessDirector.SW_MATE_GAP, 1.2) and is_equal_approx(SilenceWitnessDirector.SW_MATE_SIDE, 0.85)
		and is_equal_approx(SilenceWitnessDirector.SW_WITNESS_PACE, 0.65) and SilenceWitnessDirector.SW_MATES == 2
		and is_equal_approx(SilenceWitnessDirector.SW_OUT_PAUSE, 3.0) and is_equal_approx(SilenceWitnessDirector.SW_NEAR_WARN, 15.0),
		"the spec's numbers: mates 2, gap 1.2, side 0.85, pace 0.65, pause 3, warning at 15")
	var s := _world()
	var w := (s.d as SilenceWitnessDirector).ringers[0]
	t.check(w.tune_mates == 2 and is_equal_approx(w.tune_mate_gap, 1.2) and is_equal_approx(w.tune_mate_side, 0.85)
		and is_equal_approx(w.tune_out_pause, 3.0) and is_equal_approx(w.witness_pace, 0.65) and is_equal_approx(w.near_warn, 15.0),
		"each witness carries the Hunt's numbers")
	Kit.done(s)
	var zone := _keepout()
	var cam := SilenceWitnessDirector.SW_CAMERA_AT
	var s2 := _world()
	var d2: SilenceWitnessDirector = s2.d
	var clear := Kit.clear_of_stack(d2.lantern_door(), cam, zone)
	for g in d2.doors:
		clear = clear and Kit.clear_of_stack(g, cam, zone)
	t.check(clear, "the camera keeps the four houses, the Temple's door (or their arrows) clear of the padded HUD stack at %s" % [cam])
	var west := Kit.shown_at(d2.doors[0], cam)
	var temple := Kit.shown_at(d2.lantern_door(), cam)
	t.check(Rect2(Vector2.ZERO, Kit.VIEW).has_point(west) and Rect2(Vector2.ZERO, Kit.VIEW).has_point(temple) and temple.y < 316.0 - 20.0
		and not Rect2(190.0, 30.0, 260.0, 66.0).has_point(temple),
		"the first house and the Temple's door are on screen, clear of the strip and the slots (%s, %s)" % [west, temple])
	Kit.done(s2)


static func _chain(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var rules: Rules = s.rules
	Kit.run_for(s, SilenceWitnessDirector.SW_OUT_AT[0] - 0.5)
	var still := d.ringers[0].waiting and d.ringers[0].watchman.inside and Kit.labels(d).has("WITNESS OUT IN 0:01")
	Kit.run_for(s, 0.5 + DT * 2.0)
	var r := d.ringers[0]
	t.check(still and not r.waiting and not r.watchman.inside and r.watchman.ground_pos.distance_to(d.doors[0]) < 1.0
		and (s.banners as Array).has("THE WEST WITNESS SETS OUT"), "the west house sends its witness at 0:20, out at the door")
	Kit.run_for(s, SilenceWitnessDirector.SW_OUT_PAUSE + WarningDirector.RETARGET + DT * 2.0)
	t.check(r.phase == WarningDirector.Phase.RUN and r.messenger.mind == Person.Mind.DUTY and r.messenger.goal().distance_to(d.lantern_door()) < 0.6,
		"after the pause the witness walks for the Temple's door, not the bell's foot")
	_stop(s, r)
	var shown := d.timeline.seconds_to("out_1")
	t.check(r.warning_dead and d.stopped() == 1 and (s.banners as Array).has("THE WITNESS IS SILENT  1/4") and shown <= SilenceWitnessDirector.SW_CHAIN + 0.1
		and String(d.timeline.upcoming(1)[0].id) == "out_1",
		"killed unseen by his mates, he is stopped: THE WITNESS IS SILENT  1/4; the strip shows the next within the chain (%.1f s)" % shown)
	Kit.run_for(s, SilenceWitnessDirector.SW_CHAIN + DT * 2.0)
	t.check(not d.ringers[1].waiting and d.ringers[2].waiting, "the south-west house sends its witness the chain (45 s) after, not at its own 1:15")
	rules.cast_made.emit(0, "doom", d.doors[2])
	t.check(d.ringers[2].waiting, "a quiet power by a house sends no one")
	rules.cast_made.emit(0, "smite", d.doors[2] + Vector2(SilenceWitnessDirector.SW_POST_SIGHT - 0.5, 0.0))
	t.check(not d.ringers[2].waiting and (s.banners as Array).has("THE SOUTH-EAST HOUSE SEES YOU"), "a loud one within 6 sends its witness at once")
	t.check(d.out_at(3) == 185.0 * d.timeline.stretch_factor(), "the last house keeps its own time while the one before still runs (%.1f)" % d.out_at(3))
	Kit.done(s)


static func _mates_apart(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := d.ringers[0] as WitnessDirector
	d._send(0)
	var pair := (r.mates[0] as Person).ground_pos.distance_to((r.mates[1] as Person).ground_pos)
	var near := true
	for v: Variant in r.mates:
		var gap := (v as Person).ground_pos.distance_to(r.watchman.ground_pos)
		near = near and not (v as Person).inside and gap > SilentDoom.RADIUS and gap <= Crowd.DOOM_WITNESS
	t.check(near and pair > 2.0 * SilentDoom.RADIUS, "at the door: the mates beyond one Silent Doom of him, within sight, %.2f apart (> 1.6)" % pair)
	Kit.done(s)
	for i in 4:
		var s2 := _world()
		var d2: SilenceWitnessDirector = s2.d
		var r2 := _out(s2, i)
		Kit.run_for(s2, RingerDirector.MATE_TICK + DT * 2.0)
		var at := r2.messenger.ground_pos
		var dir := (r2._goal() - at).normalized()
		var g0 := r2._heel(at, dir, 0)
		var g1 := r2._heel(at, dir, 1)
		t.check(r2.mates.size() == 2 and g0.distance_to(g1) > 2.0 * SilentDoom.RADIUS and g0.distance_to(at) <= Crowd.DOOM_WITNESS
			and g1.distance_to(at) <= Crowd.DOOM_WITNESS,
			"at his heels from the %s house (_heel()): the mates' places more than 1.6 apart, each within 2.0 of him (%.2f, %.2f / %.2f)" % [
				d2.post_names[i], g0.distance_to(at), g1.distance_to(at), g0.distance_to(g1)])
		if i == 0:
			t.check(is_equal_approx(g0.distance_to(g1), 1.7), "in the open street the pair is the spec's 1.7 apart (%.2f)" % g0.distance_to(g1))
			var slow := r2.messenger.pace
			t.check(slow < 0.65 * Person.PACE_RANGE.y + 0.001 and slow >= 0.65 * Person.PACE_RANGE.x - 0.001,
				"the witness walks at 0.65 of his pace (%.2f of a 0.85-1.2 pace)" % slow)
		Kit.done(s2)


static func _relay_mate(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := _out(s, 0)
	var w := r.messenger
	var old_mates: Array = r.mates.duplicate()
	var before := {}
	for v: Variant in old_mates:
		before[v] = (v as Person).pace
	(s.crowd as Crowd)._field.kill(w, &"doom")
	Kit.run_for(s, DT * 2.0)
	var mate := r.messenger
	t.check(mate != w and old_mates.has(mate) and r.relays == 1 and not r.warning_dead and r.phase == WarningDirector.Phase.RUN
		and (s.banners as Array).has("THE MATE RUNS ON") and d.stopped() == 0 and not (s.banners as Array).has("THE WARNING PASSES ON"),
		"a witness killed in sight of his mates is replaced by one of them: THE MATE RUNS ON, nobody stopped yet")
	t.check(mate.mind == Person.Mind.DUTY and mate.goal().distance_to(d.lantern_door()) < 0.6 and is_equal_approx(mate.pace, float(before[mate]) * 0.65),
		"the mate walks on for the Temple's door at the witness's pace (%.2f from %.2f)" % [mate.pace, float(before[mate])])
	t.check(Kit.labels(d).has("WITNESS - TEMPLE IN %s" % UiTheme.clock(r.eta())) and d.hint_phase() == "relay",
		"his tag says WITNESS and the hint is the relay's (%s)" % [d.hint_phase()])
	var last := old_mates.filter(func(v: Variant) -> bool: return v != mate)[0] as Person
	_stop(s, r, [])
	t.check(r.warning_dead and d.stopped() == 1 and last.is_alive(), "killed with his other mate out of sight, the word dies: one witness stopped")
	Kit.done(s)
	# Two mates: the nearer carries it; with both dead in turn nothing is left.
	var s2 := _world()
	var r2 := _out(s2, 1)
	var w2 := r2.messenger
	var m0 := r2.mates[0] as Person
	var m1 := r2.mates[1] as Person
	Kit.arrive(m0, w2.ground_pos + Vector2(1.8, 0.0))
	Kit.arrive(m1, w2.ground_pos + Vector2(-0.9, 0.0))
	(s2.crowd as Crowd)._field.kill(w2, &"doom")
	Kit.run_for(s2, DT * 2.0)
	t.check(r2.messenger == m1, "the nearest able mate within sight carries it on (the one 0.9 away, not the one 1.8 away)")
	Kit.done(s2)


static func _no_luck(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := _out(s, 0)
	var w := r.messenger
	var crowd: Crowd = s.crowd
	var townsman: Person = null
	var soldier: Person = null
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p != w and not r.mates.has(p) and townsman == null:
			townsman = p
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside and soldier == null:
			soldier = p
	for v: Variant in r.mates:
		Kit.arrive(v as Person, w.ground_pos + Vector2(6.0, 6.0))
	Kit.arrive(townsman, w.ground_pos + Vector2(0.6, 0.0))
	Kit.arrive(soldier, w.ground_pos + Vector2(-0.6, 0.5))
	crowd._field.kill(w, &"doom")
	Kit.run_for(s, DT * 2.0)
	t.check(r.warning_dead and r.relays == 0 and d.stopped() == 1 and r.stopped_how == "kill" and not (s.banners as Array).has("THE MATE RUNS ON")
		and townsman.mind != Person.Mind.DUTY and soldier.mind != Person.Mind.DUTY and r._relay_witness(w.ground_pos) == null,
		"seen only by townsfolk and a soldier (both within a unit of him) the word dies with him: the town never carries it")
	Kit.done(s)


## What the god (or the town) has done to a mate `p` by the time his witness falls.
static func _hold(case: String, p: Person) -> void:
	match case:
		"whispered":
			p.mind = Person.Mind.WHISPERED
		"confused":
			p.mind = Person.Mind.CONFUSED
		"far":
			Kit.arrive(p, p.ground_pos + Vector2(2.6, 0.0))
		"fleeing":
			p.mind = Person.Mind.FLEE
		"inside":
			p.inside = true


static func _held_mate(t) -> void:
	for key in ["whispered", "confused", "far", "fleeing", "inside"]:
		var s := _world()
		var d: SilenceWitnessDirector = s.d
		var r := _out(s, 0)
		var w := r.messenger
		for v: Variant in r.mates:
			Kit.arrive(v as Person, w.ground_pos + Vector2(1.0, 0.5))
			_hold(key, v as Person)
		(s.crowd as Crowd)._field.kill(w, &"doom")
		Kit.run_for(s, DT * 2.0)
		t.check(r.warning_dead and r.relays == 0 and d.stopped() == 1, "a mate %s cannot carry the word on: the witness is stopped" % key)
		Kit.done(s)
	# A frightened mate still does: a relay overrides a fright (WarningDirector's rule).
	var s2 := _world()
	var r2 := _out(s2, 0)
	var w2 := r2.messenger
	for v: Variant in r2.mates:
		Kit.arrive(v as Person, w2.ground_pos + Vector2(1.0, 0.5))
		(v as Person).mind = Person.Mind.PANIC
	(s2.crowd as Crowd)._field.kill(w2, &"doom")
	Kit.run_for(s2, DT * 2.0)
	t.check(r2.relays == 1 and not r2.warning_dead and r2.messenger.mind == Person.Mind.DUTY, "a frightened mate who saw it runs on all the same")
	Kit.done(s2)
	# A mate's own death changes nothing for the walk.
	var s3 := _world()
	var d3: SilenceWitnessDirector = s3.d
	var r3 := _out(s3, 0)
	var w3 := r3.messenger
	(s3.crowd as Crowd)._field.kill(r3.mates[0] as Person, &"doom")
	Kit.run_for(s3, DT * 2.0)
	t.check(r3.messenger == w3 and not r3.warning_dead and d3.stopped() == 0 and r3.relays == 0, "a mate's death changes nothing: the witness walks on")
	Kit.done(s3)


static func _out_of_walls(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := _out(s, 0)
	var w := r.messenger
	var way := Vector2(2.7, 16.8)
	Kit.arrive(w, way)
	Kit.run_for(s, DT * 3.0)
	t.check(Walls.outside(way) and r.warning_dead and r.stopped_how == "out" and d.stopped() == 1 and r.is_leaving(w)
		and (s.banners as Array).has("THE WITNESS LEAVES TOWN") and (s.banners as Array).has("THE WITNESS IS SILENT  1/4"),
		"a witness out of the walls is stopped and walked off the map (shared rule 1)")
	Kit.done(s)
	var s2 := _world()
	var d2: SilenceWitnessDirector = s2.d
	var r2 := _out(s2, 1)
	var w2 := r2.messenger
	Kit.arrive(w2, Vector2(2.7, 16.8))
	var mate := r2.mates[0] as Person
	Kit.arrive(mate, Vector2(3.2, 16.8))
	(s2.crowd as Crowd)._field.kill(w2, &"doom")
	Kit.run_for(s2, DT * 2.0)
	t.check(r2.warning_dead and d2.stopped() == 1 and not (s2.banners as Array).has("THE MATE RUNS ON"),
		"a mate who would carry it on from outside the walls is stopped too (the walls stop the warning wherever it is carried)")
	Kit.done(s2)


static func _keeper_inert(t) -> void:
	# C3: a living bellkeeper can neither lose the night nor ring for the witness.
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := _out(s, 0)
	var bell := (s.crowd as Crowd).bell
	var keeper := bell.keeper
	var before := bell.state
	Kit.arrive(r.messenger, keeper.ground_pos + Vector2(0.3, 0.0))
	r.messenger.mind = Person.Mind.DUTY
	r._run()
	Kit.run_for(s, 0.6)
	t.check(r._rings_himself() and r.phase == WarningDirector.Phase.RUN and bell.state == before and bell.keeper == keeper and d.lost_reason() == ""
		and not r.in_temple and r.messenger != keeper, "a witness walked past the living bellkeeper within 0.8 neither loses nor calls the bell")
	Kit.done(s)
	var s2 := _world()
	var d2: SilenceWitnessDirector = s2.d
	var r2 := _out(s2, 0)
	var bell2 := (s2.crowd as Crowd).bell
	var keeper2 := bell2.keeper
	(s2.crowd as Crowd)._field.kill(keeper2, &"doom")
	Kit.run_for(s2, DT * 2.0)
	var state2 := bell2.state
	var holder: Variant = bell2.keeper
	Kit.arrive(r2.messenger, bell2.foot)
	r2.messenger.mind = Person.Mind.DUTY
	r2.phase = WarningDirector.Phase.RUN
	r2._run()
	Kit.run_for(s2, 0.6)
	t.check(bell2.keeper != r2.messenger and bell2.state == state2 and bell2.keeper == holder and r2.phase == WarningDirector.Phase.RUN
		and d2.lost_reason() == "" and r2.messenger.has_goal() and r2.messenger.goal().distance_to(d2.lantern_door()) < 0.6,
		"with the keeper dead, a witness at the bell's foot never takes the rope (the bell is unchanged) and is sent on for the Temple")
	var held := bell2.keeper
	r2._give_back()
	t.check(bell2.keeper == held and bell2.state == state2, "_give_back() is a no-op: he never held the rope")
	Kit.done(s2)
	var s3 := _world()
	var bell3 := (s3.crowd as Crowd).bell
	t.check(bell3.hold_on_death, "the base's hold on the town's bell (it waits for a relay) is kept: the bell is never a loss")
	(s3.d as SilenceWitnessDirector).teardown()
	t.check(not bell3.hold_on_death, "and let go at teardown")
	Kit.done(s3)


static func _word_in(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := _out(s, 0)
	var rules: Rules = s.rules
	var door := d.lantern_door()
	Kit.arrive(r.messenger, door + Vector2(1.3, 0.0))
	Kit.run_for(s, DT * 3.0)
	t.check(not d.word_in() and d.lost_reason() == "", "1.3 from the Temple's door is not yet in (TempleReport.REACH is %.1f)" % TempleReport.REACH)
	var o := d.rules.objectives[0]
	t.check(o.check(rules) != Objective.Status.FAILED, "the objective does not fail")
	Kit.arrive(r.messenger, door + Vector2(0.5, 0.0))
	Kit.run_for(s, DT * 3.0)
	t.check(d.word_in() and d.lost_reason() == "word" and r.in_temple and o.check(rules) == Objective.Status.FAILED and o.reason == "word",
		"a witness within 1.0 of the Temple's door: word reaches the Temple, the objective fails `word`")
	Kit.done(s)
	# A dead witness at the door is no word; and the winning strike never also loses.
	var s2 := _world()
	var d2: SilenceWitnessDirector = s2.d
	var r2 := _out(s2, 0)
	Kit.arrive(r2.messenger, d2.lantern_door() + Vector2(0.4, 0.0))
	_clear_round(s2, r2.messenger, [])
	(s2.crowd as Crowd)._field.kill(r2.messenger, &"doom")
	Kit.run_for(s2, DT * 3.0)
	t.check(not d2.word_in() and d2.lost_reason() == "" and r2.warning_dead, "killed at the very door, unseen, he is stopped, not in")
	Kit.done(s2)
	# The near warning: at 15 s out the banner, once; the strip's row and the tag count down; the hint says so.
	var s3 := _world()
	var d3: SilenceWitnessDirector = s3.d
	var r3 := _out(s3, 0)
	Kit.run_for(s3, WarningDirector.RETARGET * 3.0)
	var eta := r3.eta()
	t.check(eta > SilenceWitnessDirector.SW_NEAR_WARN and not (s3.banners as Array).has("A WITNESS NEARS THE TEMPLE") and d3.hint_phase() == "",
		"far off (%.1f s) there is no warning" % eta)
	var near := d3._walkable(d3.lantern_door() + Vector2(-4.0, 2.0))
	Kit.arrive(r3.messenger, near)
	Kit.run_for(s3, WarningDirector.RETARGET * 3.0)
	eta = r3.eta()
	var count := (s3.banners as Array).count("A WITNESS NEARS THE TEMPLE")
	Kit.run_for(s3, WarningDirector.RETARGET * 4.0)
	var rows := d3.strip_rows()
	t.check(eta <= SilenceWitnessDirector.SW_NEAR_WARN and count == 1 and (s3.banners as Array).count("A WITNESS NEARS THE TEMPLE") == 1
		and d3.hint_phase() == "near" and rows.size() == 1 and rows[0].label == "Word reaches the Temple" and absf(float(rows[0]["in"]) - r3.eta()) < 0.5
		and Kit.labels(d3).has("WITNESS - TEMPLE IN %s" % UiTheme.clock(r3.eta())),
		"within 15 s: the banner once, the hint `near`, the strip row and the tag count the walk (%.1f s)" % eta)
	Kit.done(s3)


static func _win(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var rules: Rules = s.rules
	var o := rules.objectives[0]
	for i in 4:
		var r := _out(s, i)
		_stop(s, r)
		t.check(r.warning_dead and d.stopped() == i + 1, "witness %d stopped (%d/4)" % [i + 1, d.stopped()])
	t.check(o.check(rules) == Objective.Status.DONE and o.reason == "witnesses" and d.stars_stopped() == 4 and d.stars_total() == 4
		and d.lost_reason() == "" and (s.banners as Array).has("THE WITNESS IS SILENT  4/4"),
		"all four stopped wins `witnesses`")
	var hud := o.hud_text(rules)
	t.check(hud == "Witnesses silenced 4 / 4", "the HUD counts them (%s)" % hud)
	Kit.done(s)
	# The win is checked first: a count of four with the word at the door in one frame is a win.
	var s2 := _world()
	var rules2: Rules = s2.rules
	var real := rules2.director
	rules2.director = Both.new()
	var o2 := rules2.objectives[0]
	t.check(o2.check(rules2) == Objective.Status.DONE and o2.reason == "witnesses",
		"the winning strike never also loses: the count first, then the word")
	rules2.director = real
	Kit.done(s2)


static func _lantern(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var rules: Rules = s.rules
	var r := _out(s, 0)
	t.check(rules.lantern != null and rules.lantern.kind == LanternWatch.KIND_WATCH and not r.heralding() and not d.herald_open(),
		"a watch Lantern: no Herald, the witness's errand is the Temple's door whatever the bell does")
	rules.lantern.on_toll()
	d.on_toll()
	Kit.run_for(s, 1.0)
	t.check(rules.lantern.tolled and rules.lantern.stage == LanternWatch.Stage.STIRRING and d.lost_reason() == "" and not r.heralding()
		and not d.herald_open() and rules.objectives[0].check(rules) != Objective.Status.FAILED and r.phase == WarningDirector.Phase.RUN
		and r.messenger.goal().distance_to(d.lantern_door()) < 0.6,
		"a toll turns the Lantern (the clock x1.5) and never loses: the witness walks on")
	Kit.done(s)


static func _no_keeper_tags(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var bell := (s.crowd as Crowd).bell
	bell.call_keeper()
	Kit.run_for(s, 1.0)
	var labels := _labels(d)
	var bad := false
	for l: String in labels:
		bad = bad or l.contains("BELLKEEPER") or l.contains("BELL TOWER") or l.contains("RINGER") or l.contains("POST")
	t.check(not bad and d.hint_phase() == "" and not labels.is_empty(), "no bellkeeper or bell-tower tag, whatever the keeper does (%s)" % [labels])
	var r := _out(s, 0)
	labels = _labels(d)
	for l: String in labels:
		bad = bad or l.contains("BELLKEEPER") or l.contains("BELL TOWER") or l.contains("RINGER")
	t.check(not bad, "nor with a witness out of doors (%s)" % [labels])
	r.teardown()
	Kit.done(s)


static func _tags(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var tags := d.tags()
	var waiting := tags.filter(func(m: MapTag) -> bool: return m.label.begins_with("WITNESS OUT IN"))
	var temple := tags.filter(func(m: MapTag) -> bool: return m.label == "TEMPLE")
	var ok := waiting.size() == 4 and temple.size() == 1
	for m: MapTag in waiting:
		ok = ok and m.edge and m.color == BellRingersDirector.MARK_POST
	t.check(ok and temple[0].edge and temple[0].color == BellRingersDirector.MARK_POST and Kit.labels(d).has("WITNESS OUT IN 0:20"),
		"four waiting houses `WITNESS OUT IN 0:20` (orange, edge) and the Temple's door `TEMPLE` (orange)")
	Kit.run_for(s, 5.5)
	t.check(Kit.labels(d).has("WITNESS OUT IN 0:15") and Kit.labels(d).has("WITNESS OUT IN 1:10"), "the tags count down like the strip (%s)" % [Kit.labels(d)])
	var r := _out(s, 0)
	var out := d.tags()
	var wit := out.filter(func(m: MapTag) -> bool: return m.label.begins_with("WITNESS - TEMPLE IN"))
	var mates := out.filter(func(m: MapTag) -> bool: return m.label == "MATE")
	t.check(wit.size() == 1 and wit[0].edge and wit[0].color == WarningDirector.MARK_MESSENGER and mates.size() == 2 and mates[0].edge
		and mates[0].color == WarningDirector.MARK_WATCHED and out[0].label.begins_with("WITNESS - TEMPLE IN"),
		"the witness `WITNESS - TEMPLE IN m:ss` (gold, edge, first) and each mate `MATE` (red, edge)")
	Kit.done(s)


static func _evacuation(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := _out(s, 0)
	Kit.evacuate(s)
	Kit.run_for(s, WarningDirector.RETARGET * 3.0 + RingerDirector.MATE_TICK * 2.0 + DT)
	var ok := r.messenger.mind != Person.Mind.FLEE
	for v: Variant in r.mates:
		ok = ok and (v as Person).mind != Person.Mind.FLEE
	for i in range(1, 4):
		for v: Variant in d.ringers[i].crew():
			ok = ok and (v as Person).mind != Person.Mind.FLEE
	t.check(ok and r.messenger.mind == Person.Mind.DUTY and r.messenger.has_goal(),
		"through an evacuation the witness and his mates are held out of the flight and back on their errand; the waiting crews too")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var r := _out(s, 0)
	var w := r.messenger
	for v: Variant in r.mates.duplicate():
		Kit.free_body(s, v as Person)
	Kit.run_for(s, 1.0)
	var labels := Kit.labels(d)
	t.check(r.witnesses().is_empty() and r._relay_witness(w.ground_pos) == null and labels.has("WITNESS - TEMPLE IN %s" % UiTheme.clock(r.eta())),
		"the mates' bodies freed: nothing touches them, the witness walks on alone")
	Kit.free_body(s, w)
	Kit.run_for(s, 1.0)
	t.check(r.warning_dead and r.phase == WarningDirector.Phase.OVER and d.stopped() == 1, "the witness's body freed with no fall to judge: nothing is left to stop")
	d.tags()
	d.strip_rows()
	d.hint_phase()
	d.tour()
	d.report()
	Kit.done(s)


static func _texts(t) -> void:
	var m := MissionBook.silence_witness()
	t.check(m.brief == PackedStringArray(["Four witnesses saw you work.", "Stop them before they reach the Temple."])
		and m.goal == "Stop all four witnesses before word of you reaches the Temple" and m.goal_label == "The witnesses are silent"
		and m.lose == "A witness reaches the Temple, or dawn comes", "the brief, goal, label and lose are the spec's")
	t.check(MissionHints.line("silence_witness") == "A witness (gold) walks to the Temple with two mates (red). Kill him where his mates cannot see."
		and MissionHints.line("silence_witness", "relay") == "His mate saw it and runs on: stop him too."
		and MissionHints.line("silence_witness", "near") == "The witness nears the Temple: stop him now.",
		"the three hint lines are MS §3's")
	var s := _world()
	var d: SilenceWitnessDirector = s.d
	var tour := d.tour()
	t.check(tour.size() == 5 and tour[4][0] == d.lantern_door() and String(tour[0][1]).contains("0:20") and String(tour[1][1]).contains("1:15")
		and String(tour[4][1]).begins_with("The Temple."), "the tour: four houses with their times, then the Temple's door")
	var report := d.report()
	t.check(report.has("stopped") and report.has("relays") and report.has("word") and report.witnesses == 4 and not report.word,
		"the report keeps the base's keys and adds the Hunt's (%s)" % [report])
	Kit.done(s)


## The hunt's wishes never land on the witnesses, their mates or their houses (MS §1, open issue 4; Task 1's `_hunt_wishes` for this Hunt).
static func _hunt_wishes(t) -> void:
	var id := MissionBook.SILENCE_WITNESS
	var heard := 0
	var hit := 0
	for night in 4:
		var def := HuntBook.def(id)
		var descent := Descent.new().setup(def, Descent.seed_for(night, id))
		var n := Kit.world(HuntBook.def(id), null, func(d: MissionDirector, rules: Rules) -> void: descent.reserve(rules, d))
		var d: SilenceWitnessDirector = n.d
		var mine: Array = []
		for r in d.ringers:
			mine.append_array(r.crew())
		for w in descent.wishes:
			heard += 1
			for p in w.people():
				hit += 1 if mine.has(p) else 0
			for st in w.places():
				hit += 1 if d.posts.has(st) else 0
		descent.release()
		Kit.done(n)
	t.check(heard > 0 and hit == 0, "Silence the witness: wishes heard (%d), none on a witness, a mate or a house (%d)" % [heard, hit])
