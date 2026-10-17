extends RefCounted
## v0.11 M5 The Armoury (mission spec §2 with the controller's staged ruling; ArmouryDirector, RazeDirector reused): the north barracks,
## the gate barracks (stone) and the armoury, each mustering at its horn on the chain; a night watch of armed men from the start, a
## squad indoors until the horn, both held deaf and fearless on their posts; guarded, a target is sealed; unguarded, every blow lands
## from the start, but before its horn its fire goes out and its fall counts at the horn; seconds burned stay counted; return, relief
## and reinforcements from the reserve inside the Citadel's gate, faster each minute; the armoury felled early leaves the reserve and
## its clock be; the reserve spent sends none. All three razed wins; the march at 5:00 loses. Freed bodies are borne (review focus 4);
## the rally and the evacuation pass them by (review focus 2); the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_guarded(t)
	_ahead(t)
	_muster(t)
	_burn(t)
	_reinforce(t)
	_reserve(t)
	_relief(t)
	_chain(t)
	_felled_early(t)
	_ends(t)
	_evacuate(t)
	_tower_reserved(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.armoury())


## Every armed man of target `i` out of doors killed and freed (v0.11 M5 tests).
static func _clear(s: Dictionary, d: ArmouryDirector, i: int) -> void:
	for a: ArmouryDirector.Armed in d.armed[i]:
		if MissionDirector._alive(a.man) and not (a.man as Person).inside:
			Kit.free_body(s, a.man)


## Every post of each target (night watch and squad) within GUARD_REACH of it and more than two Silent Doom radii from every other,
## so one strike takes one man (v0.11 M5, the squad-spread ruling: _spread() must never fall back to a bunched post).
static func _spread_ok(d: ArmouryDirector) -> bool:
	var ok := true
	for i in d.targets.size():
		var list: Array = d.armed[i]
		ok = ok and list.size() == ArmouryDirector.NIGHT_WATCH + ArmouryDirector.SQUAD
		for a: ArmouryDirector.Armed in list:
			ok = ok and d.targets[i].distance_to(a.post) <= ArmouryDirector.GUARD_REACH
			for b: ArmouryDirector.Armed in list:
				ok = ok and (a == b or a.post.distance_to(b.post) > 2.0 * SilentDoom.RADIUS)
	return ok


## How many of the targets' plates the HUD draws with the camera at its rest (v0.11 M5, Task 8's photograph; Hud.tag_layout keeps the
## earlier of two overlapping plates and drops the other).
static func _plates(d: ArmouryDirector) -> int:
	var xf := Transform2D(0.0, Vector2.ONE * Mission.PLAY_ZOOM, 0.0, Vector2.ZERO)
	xf.origin = Kit.VIEW * 0.5 - Iso.ground_to_screen(ArmouryDirector.CAMERA_AT) * Mission.PLAY_ZOOM
	var shown := 0
	for e in Hud.tag_layout(d.tags(), xf, Kit.VIEW):
		var label := String(e.tag.label)
		if bool(e.show) and (label.begins_with("BARRACKS") or label.begins_with("ARMOURY")):
			shown += 1
	return shown


static func _setup(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	t.check(d.targets.size() == 3 and d.targets[0].art_tag == &"tavern"
		and d.targets[0].footprint.position.is_equal_approx(TownLayout.TAVERNS[0].position) and d.targets[1].role == &"tower"
		and d.targets[1].footprint.position.is_equal_approx(TownLayout.GATE_TOWERS[1].position) and d.targets[2].kind == Structure.Kind.BARRACKS,
		"the north barracks (the north tavern), the gate barracks (the Main Gate's east tower), the armoury (the barracks shed)")
	var seen := {}
	var ok := true
	for i in 3:
		var watch: Array = []
		for a: ArmouryDirector.Armed in d.armed[i]:
			var p := a.man as Person
			ok = ok and p != null and not seen.has(p) and p.profile.role == CitizenProfile.Role.WATCHMAN and not p.soldier \
				and p.mind == Person.Mind.DUTY
			seen[p] = true
			if a.squad:
				ok = ok and p.inside and d.targets[i].distance_to(a.post) <= ArmouryDirector.GUARD_REACH
			else:
				ok = ok and not p.inside and p.ground_pos.distance_to(a.post) < 0.1 \
					and d.targets[i].distance_to(p.ground_pos) <= ArmouryDirector.GUARD_REACH
				watch.append(p)
		ok = ok and watch.size() == ArmouryDirector.NIGHT_WATCH \
			and (watch[0] as Person).ground_pos.distance_to((watch[1] as Person).ground_pos) > 2.0 * SilentDoom.RADIUS
	for v: Variant in d.reserve:
		ok = ok and (v as Person).inside and not seen.has(v) and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN \
			and (v as Person).mind == Person.Mind.DUTY and (v as Person).ground_pos.distance_to(d.citadel_door) < 0.1
	t.check(ok and seen.size() == 3 * (ArmouryDirector.NIGHT_WATCH + ArmouryDirector.SQUAD) and d.reserve.size() == ArmouryDirector.RESERVE,
		"a night watch on its posts one Doom apart and a squad indoors at each target, a reserve inside the Citadel's gate: %d lay watchmen"
			% (seen.size() + d.reserve.size()))
	var eng := (s.crowd as Crowd).engineers
	t.check(_spread_ok(d), "every pair of a target's five posts more than two Doom radii apart, each within reach (the squad-spread ruling)")
	var gate_ok := true
	for i in d.targets.size():
		gate_ok = gate_ok and d._reaches(d._post(i, ArmouryDirector.NIGHT_WATCH + ArmouryDirector.SQUAD))
	t.check(gate_ok, "each target's next reinforcement post is reached from the Citadel's gate (the final review: none stalls on one slot)")
	t.check(eng.hands_off.size() == 3 and eng.hands_off.has(d.targets[1]) and not d.mustering[0], "the town's teams keep off the three; none musters yet")
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["horn_0", "horn_1", "horn_2", "march"], "the strip: three horns, then the march (%s)" % [ids])
	var clear := true
	for st in d.targets:
		clear = clear and Kit.clear_of_stack(st.center(), ArmouryDirector.CAMERA_AT, Kit.STACK)
	t.check(clear, "the camera keeps the three targets (or their arrows) clear of the real HUD stack")
	# Task 8's photograph: the gate barracks' and the armoury's arrows stand side by side on the bottom edge; with "MUSTERS BY" in
	# both plates the HUD dropped the armoury's (Hud.tag_layout keeps the earlier plate).
	var shown := _plates(d)
	t.check(shown == 3, "at the camera's rest all three targets' plates are drawn, the two arrows' too (%d)" % shown)
	var m := MissionBook.armoury()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and m.dp_capacity == 13 and reasons == ["garrison", "marches", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "ember", "heaven"] and MissionBook.get_mission("armoury").id == "armoury",
		"the mission: Tier 4's numbers; the garrison, the march, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := true
	for i in 3:
		for a: ArmouryDirector.Armed in d.armed[i]:
			var p := a.man as Person
			held = held and (p.inside if a.squad else p.mind == Person.Mind.DUTY)
	for v: Variant in d.reserve:
		held = held and (v as Person).inside
	t.check(held, "the rally, the regroup and the evacuation pass the night watches by; the squads and the reserve stay indoors (review focus 2)")
	Kit.done(s)


static func _guarded(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var north := d.targets[0]
	Kit.run_for(s, 0.6)
	var hp := north.hp
	north.damage(30.0, north.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, 0.1)
	t.check(d.is_sealed(north) and is_equal_approx(north.hp, hp) and not d.burning(north),
		"an armed man on guard: a blow only shakes it, its fire goes out")
	var a: ArmouryDirector.Armed = d.armed[0][0]
	var man := a.man as Person
	t.check(man.fearless_left > 0.0 and not man.shaken(), "an armed man on guard is past fear")
	man.confuse(5.0)
	Kit.run_for(s, 0.6)
	t.check(man.mind == Person.Mind.DUTY and man.anchor == a.post, "Discord holds him a look at most: he is set back on his post")
	t.check(man.whisper(man.ground_pos + Vector2(4.0, 0.0), MindWhisperFx.LINGER),
		"v0.11.1: soldiers hear the god -- an armed man hears a whisper")
	Kit.run_for(s, 0.6)
	t.check(man.mind == Person.Mind.WHISPERED and not d.guards(0).has(man), "and a whispered one is off his post, not set back on it at the next look")
	Kit.done(s)


static func _ahead(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var north := d.targets[0]
	_clear(s, d, 0)
	Kit.run_for(s, 0.1)
	var hp := north.hp
	north.damage(20.0, north.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, 0.1)
	t.check(not d.is_sealed(north) and north.hp < hp and not d.burning(north),
		"with none on guard a blow lands before its horn, but its fire goes out (the staged ruling)")
	north.destroy(north.center(), &"smite")
	Kit.run_for(s, 0.5)
	t.check(not d.razed(north) and d.hint_phase() == "not_yet" and Kit.labels(d)[0] == "BARRACKS - DOWN %s" % UiTheme.clock(d.due_in(0))
		and d.due_in(0) < float(ArmouryDirector.STAGE_AT[0]),
		"a fall before its horn is not razed yet: DOWN and the seconds to its horn, counting down (%s)" % Kit.labels(d)[0])
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]))
	t.check(d.razed(north) and (s.banners as Array).has("THE NORTH BARRACKS IS RAZED"), "still down when its horn sounds: razed at once")
	Kit.done(s)


static func _muster(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]) + DT)
	var out := true
	for a: ArmouryDirector.Armed in d.armed[0]:
		out = out and not (a.man as Person).inside and (a.man as Person).anchor == a.post
	t.check(d.mustering[0] and out and (s.banners as Array).has("THE MUSTER HORN: THE NORTH BARRACKS TURNS OUT") and not d.mustering[1],
		"at its horn the north barracks musters: its squad comes out to its posts")
	Kit.done(s)


static func _burn(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var north := d.targets[0]
	d._muster(0)
	var keep: ArmouryDirector.Armed = d.armed[0][0]
	for a: ArmouryDirector.Armed in d.armed[0]:
		if a != keep and MissionDirector._alive(a.man) and not (a.man as Person).inside:
			Kit.free_body(s, a.man)
	Kit.arrive(keep.man as Person, north.center() + Vector2(6.0, 6.0))
	Kit.run_for(s, 0.1)
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, 5.0)
	var five := d.burned(north)
	t.check(d.burning(north) and five > 4.5 and not d.is_sealed(north), "mustering with none on guard, it burns and its seconds count")
	Kit.arrive(keep.man as Person, keep.post)
	Kit.run_for(s, 0.2)
	t.check(not d.burning(north) and d.is_sealed(north) and absf(d.burned(north) - five) < 0.3,
		"an armed man back on guard seals it and puts its fire out; its seconds stay counted")
	Kit.free_body(s, keep.man)
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, ArmouryDirector.SPOIL_SECONDS - five + 0.5)
	t.check(d.razed(north), "burned SPOIL_SECONDS in all after its horn: razed")
	Kit.done(s)


static func _reinforce(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(0)
	_clear(s, d, 0)
	d.targets[0].destroy(d.targets[0].center(), &"smite")
	Kit.run_for(s, 0.1)
	t.check(d.razed(d.targets[0]) and d._next_arms < 0.0, "(set-up) the north barracks razed: nothing musters, the clock stops")
	d._muster(1)
	Kit.run_for(s, float(ArmouryDirector.REINFORCE[0]) + 0.6)
	var last: ArmouryDirector.Armed = d.armed[1].back()
	var man := last.man as Person
	var apart := true
	for a: ArmouryDirector.Armed in d.armed[1]:
		apart = apart and (a == last or a.post.distance_to(last.post) > 2.0 * SilentDoom.RADIUS)
	t.check(d.reinforced == 1 and last.reinforcement and last.relief and man.anchor == last.post and not man.inside
		and man.ground_pos.distance_to(d.citadel_door) < 0.1 and d.reserve.size() == ArmouryDirector.RESERVE - 1
		and d.targets[1].distance_to(last.post) <= ArmouryDirector.GUARD_REACH and apart,
		"REINFORCE after its horn an armed man runs out of the Citadel's gate to a post within reach of it, one Doom from the rest")
	for a: ArmouryDirector.Armed in d.armed[1]:
		if a != last and MissionDirector._alive(a.man) and not (a.man as Person).inside:
			Kit.free_body(s, a.man)
	d.targets[1].destroy(d.targets[1].center(), &"smite")
	Kit.run_for(s, 0.1)
	t.check(d.razed(d.targets[1]) and man.mind == Person.Mind.DUTY and man.anchor == d.citadel_door and d._next_arms < 0.0,
		"his target razed while he runs in, he turns back for the Citadel's gate; nothing musters, the clock stops")
	Kit.arrive(man, d.citadel_door)
	Kit.run_for(s, ArmouryDirector.TICK + DT)
	t.check(man.inside and d.reserve.has(man) and d.reserve.size() == ArmouryDirector.RESERVE, "at the gate he goes in again, back in the reserve")
	var rates := []
	for at: float in [30.0, 125.0, 185.0, 250.0]:
		d._clock = at
		rates.append(d.arms_every())
	t.check(rates == [40.0, 30.0, 20.0, 12.0], "REINFORCE follows the clock's minute: 40, 30 in the third, 20 in the fourth, 12 from 4:00 (%s)" % [rates])
	Kit.done(s)


static func _reserve(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d.reserve.clear()
	d._muster(0)
	d._next_arms = 0.0
	Kit.free_body(s, (d.armed[0][0] as ArmouryDirector.Armed).man)
	Kit.run_for(s, ArmouryDirector.RELIEF_AFTER + 1.0)
	t.check(d.reinforced == 0 and d.reliefs == 0 and not MissionDirector._alive((d.armed[0][0] as ArmouryDirector.Armed).man),
		"the reserve spent: no reinforcement, no relief")
	Kit.done(s)
	var w := _world()
	var wd: ArmouryDirector = w.d
	wd.citadel_door = Vector2(-40.0, -40.0)  # off the map: no way from here to any post
	wd._muster(0)
	wd._next_arms = 0.0
	Kit.run_for(w, 0.6)
	t.check(wd.reinforced == 0 and wd.reserve.size() == ArmouryDirector.RESERVE and wd._next_arms > wd._clock,
		"no way from the gate to the post: no reinforcement leaves the reserve, and the clock backs off to its next time")
	Kit.done(w)
	var f := _world()
	var fd: ArmouryDirector = f.d
	var store := fd.targets[2]
	_clear(f, fd, 2)
	Kit.run_for(f, 0.1)
	store.destroy(store.center(), &"smite")
	Kit.run_for(f, 0.6)
	var inside := true
	for v: Variant in fd.reserve:
		inside = inside and (v as Person).inside
	t.check(not fd.razed(store) and fd.reserve.size() == ArmouryDirector.RESERVE and inside,
		"the armoury felled early: not razed before its horn, and the reserve waits on inside the Citadel's gate")
	fd._muster(0)
	Kit.run_for(f, float(ArmouryDirector.REINFORCE[0]) + 0.6)
	t.check(fd.reinforced == 1 and fd.reliefs == 0 and fd.reserve.size() == ArmouryDirector.RESERVE - 1,
		"its fall never cancels the reinforcement clock, and its fallen night watch gets no relief (the controller's ruling)")
	Kit.done(f)


static func _relief(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var a: ArmouryDirector.Armed = d.armed[1][0]
	var dead: Variant = a.man
	Kit.free_body(s, dead)
	Kit.run_for(s, ArmouryDirector.RELIEF_AFTER + 1.0)
	var p: Variant = a.man
	t.check(p != dead and MissionDirector._alive(p) and not (p as Person).inside and (p as Person).anchor == a.post and a.relief
		and d.reserve.size() == ArmouryDirector.RESERVE - 1 and d.reliefs == 1 and (s.banners as Array).has("AN ARMED MAN RUNS FROM THE CITADEL"),
		"RELIEF_AFTER after an armed man falls, one from the reserve runs out of the Citadel's gate to his post")
	var b: ArmouryDirector.Armed = d.armed[1][1]
	Kit.arrive(b.man as Person, d.targets[1].center() + Vector2(0.0, -7.0))
	(b.man as Person).mind = Person.Mind.CALM
	Kit.run_for(s, ArmouryDirector.RETURN_AFTER + 1.0)
	t.check((b.man as Person).mind == Person.Mind.DUTY and (b.man as Person).anchor == b.post,
		"one off his post and calm walks back RETURN_AFTER after he left")
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(0)
	_clear(s, d, 0)
	d.targets[0].destroy(d.targets[0].center(), &"smite")
	Kit.run_for(s, 0.1)
	var shown := d.timeline.seconds_to("horn_1")
	t.check(d.razed(d.targets[0]) and (s.banners as Array).has("THE NORTH BARRACKS IS RAZED") and shown <= ArmouryDirector.CHAIN + 0.1
		and String(Kit.labels(d)[0]).begins_with("BARRACKS - HORN"), "razed after its horn; the next horn chained, CHAIN on (%.1f)" % shown)
	Kit.run_for(s, ArmouryDirector.CHAIN + DT)
	t.check(d.mustering[1] and (s.banners as Array).has("THE MUSTER HORN: THE GATE BARRACKS TURNS OUT"), "the gate barracks musters CHAIN after")
	Kit.done(s)


## The final review: a target already down when the one before is razed sounds its horn at once, so a player who felled all three at
## 0:01 sees them razed in quick succession at the first horn, not at 0:40, 1:20 and 2:00. Down before their horns, the gate barracks'
## and the armoury's plates (DOWN and the horn's time) both draw beside the north barracks' at the camera's rest.
static func _felled_early(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	Kit.run_for(s, 0.5)
	for i in 3:
		_clear(s, d, i)
	Kit.run_for(s, 0.5)
	for i in [1, 2]:
		d.targets[i].destroy(d.targets[i].center(), &"smite")
	Kit.run_for(s, 0.1)
	var labels := Kit.labels(d)
	var want := ["BARRACKS - HORN %s" % UiTheme.clock(d.due_in(0)), "BARRACKS - DOWN %s" % UiTheme.clock(d.due_in(1)),
		"ARMOURY - DOWN %s" % UiTheme.clock(d.due_in(2))]
	t.check(labels.slice(0, 3) == want and want[2] == "ARMOURY - DOWN 2:59" and _plates(d) == 3,
		"two down before their horns: DOWN and the seconds to the horn, all three plates drawn (%s, %d)" % [labels.slice(0, 3), _plates(d)])
	d.targets[0].destroy(d.targets[0].center(), &"smite")
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]))
	Kit.run_for(s, 1.0)
	var horn := float(ArmouryDirector.STAGE_AT[0])
	t.check(d.razed_at[0] >= horn - 0.01 and d.razed_at[0] < horn + 0.2, "the north barracks razed at its own horn (%.2f)" % d.razed_at[0])
	t.check(d.all_razed() and d.razed_at[2] - d.razed_at[0] < 1.0 and (s.banners as Array).has("THE ARMOURY IS RAZED")
		and (s.banners as Array).has("THE MUSTER HORN: THE GARRISON ARMS"),
		"all three felled at 0:01: razed in quick succession at the first horn, each horn sounding at once (%.2f / %.2f / %.2f)"
			% [d.razed_at[0], d.razed_at[1], d.razed_at[2]])
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(main.hud_text(s.rules) == "Raze the garrison 0 / 3", "the main row before any horn")
	d._muster(0)
	t.check(main.hud_text(s.rules) == "Raze the garrison 0 / 3, armed men every 40 s", "while a target musters, the rate rides in the main row")
	for i in 3:
		d._muster(i)
		_clear(s, d, i)
		d.targets[i].destroy(d.targets[i].center(), &"smite")
	Kit.run_for(s, 0.1)
	t.check(d.all_razed() and main.check(s.rules) == Objective.Status.DONE and main.reason == "garrison"
		and main.hud_text(s.rules) == "Raze the garrison 3 / 3", "all three razed: the garrison is broken")
	Kit.done(s)
	var n := _world()
	var march: Objective = (n.rules as Rules).objectives[1]
	t.check(march.hud_text(n.rules) == "Garrison marches 5:00", "the deadline row (%s)" % march.hud_text(n.rules))
	(n.d as ArmouryDirector).timeline.step(ArmouryDirector.MARCH_AT + DT)
	t.check(march.check(n.rules) == Objective.Status.FAILED and march.reason == "marches" and (n.banners as Array).has("THE GARRISON MARCHES"),
		"left alone, the garrison marches at 5:00")
	Kit.done(n)


## The evacuate-mid-mission test (the controller's rulings): the evacuation begins while the gate barracks musters.
static func _evacuate(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(1)
	d._next_arms = 0.0
	Kit.run_for(s, 0.6)
	var runner: ArmouryDirector.Armed = d.armed[1].back()
	var rp := runner.man as Person
	var watch: ArmouryDirector.Armed = d.armed[1][0]
	var wp := watch.man as Person
	t.check(runner.reinforcement and rp.whisper(rp.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER),
		"(set-up) a reinforcement running in hears a whisper")
	wp.fearless_left = 0.0
	wp.mind = Person.Mind.RECOVER
	Kit.evacuate(s)
	t.check(wp.mind == Person.Mind.FLEE and rp._whisper_fled, "(set-up) the evacuation sends the recovering man running, and owes the whispered one a flight")
	Kit.run_for(s, 0.6)
	t.check(wp.mind == Person.Mind.DUTY and wp.anchor == watch.post and not rp._whisper_fled,
		"at the first look after it the night watch man is back on his post, the runner's flight ended")
	rp._wake()
	Kit.run_for(s, 0.6)
	var inside := true
	for v: Variant in d.reserve:
		inside = inside and (v as Person).inside
	var squad := true
	for a: ArmouryDirector.Armed in d.armed[1]:
		if a.squad:
			squad = squad and (a.man as Person).mind == Person.Mind.DUTY and (a.man as Person).anchor == a.post
	t.check(rp.mind == Person.Mind.DUTY and rp.anchor == runner.post and squad and inside and d.reserve.size() == ArmouryDirector.RESERVE - 1,
		"back on his feet the runner runs on to his post; the squad holds its posts; the reserve stays inside the Citadel's gate")
	Kit.done(s)


static func _tower_reserved(t) -> void:
	var probe := _world()
	var ix := (probe.town as Town)._built.find((probe.d as ArmouryDirector).targets[1])
	Kit.done(probe)
	var s := Kit.world(MissionBook.armoury(), null, func(d: MissionDirector, rules: Rules) -> void:
		d.reserved_places.append(rules.town()._built[ix]))
	var d: ArmouryDirector = s.d
	t.check(ix >= 0 and d.targets[1].role == &"tower" and (s.town as Town)._built.find(d.targets[1]) != ix
		and d.targets[1].footprint.position.is_equal_approx(TownLayout.GATE_TOWERS[0].position),
		"a wish's east gate tower set aside: the gate barracks is the west one (review focus 5)")
	t.check(_spread_ok(d), "the west tower's five posts too: each pair more than two Doom radii apart, each within reach")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 3) == ["BARRACKS - HORN 0:40", "BARRACKS - HORN 1:50", "ARMOURY - HORN 3:00"]
		and Kit.edged(d, "ARMOURY - HORN 3:00") and labels.has("ARMED") and d.hint_phase() == "",
		"before its horn each target is grey with the seconds to it, pointed at; ARMED on each man on guard (%s)" % [labels.slice(0, 3)])
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]) - ArmouryDirector.WORK_AHEAD + 1.0)
	t.check(d.hint_phase() == "not_yet", "within 25 s of its horn: not yet")
	t.check(Kit.labels(d)[0] == "BARRACKS - HORN 0:24",
		"its tag counts down to the horn as the strip does (v0.11 M6's final review) (%s)" % Kit.labels(d)[0])
	d._muster(0)
	t.check(Kit.labels(d)[0] == "BARRACKS - GUARDED" and Kit.edged(d, "BARRACKS - GUARDED") and d.hint_phase() == "guarded",
		"mustering, guarded, pointed at")
	_clear(s, d, 0)
	Kit.run_for(s, 0.1)
	t.check(Kit.labels(d)[0] == "BARRACKS" and Kit.edged(d, "BARRACKS") and d.hint_phase() == "open", "none on guard: open, pointed at")
	(s.crowd as Crowd).fires.ignite(d.targets[0], 0.5)
	Kit.run_for(s, 1.2)
	t.check(Kit.labels(d)[0] == "BARRACKS - BURNING 11" and Kit.edged(d, "BARRACKS - BURNING 11"),
		"burning, its seconds counted down, pointed at (%s)" % Kit.labels(d)[0])
	d.targets[0].destroy(d.targets[0].center(), &"smite")
	d._muster(1)
	_clear(s, d, 1)
	Kit.run_for(s, 0.1)
	t.check(d.hint_phase() == "stone", "the gate barracks open: blows, not fire")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The north barracks. The muster horn calls it at 0:40."
		and String(tour[2][1]).begins_with("The armoury, last."), "the tour: the north barracks, the gate barracks, the armoury")
	t.check(ResultsScreen.ACT_TITLES.get("garrison") == "THE GARRISON IS BROKEN" and ResultsScreen.ACT_TITLES.get("marches") == "THE GARRISON MARCHES",
		"its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(0)
	for i in 3:
		_clear(s, d, i)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.guards(0).is_empty() and d.hint_phase() == "open" and int(d.report().razed) == 0,
		"every armed man out of doors freed: the tags, hint and report bear it (review focus 4)")
	Kit.done(s)
