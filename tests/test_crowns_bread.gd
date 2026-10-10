extends RefCounted
## v0.11 M4 The Crown's Bread (mission spec §1, CrownsBreadDirector, RazeDirector reused): the east-road barn, the watermill and the
## stone bridge, each in use at its stage (the next at its time or CHAIN after the one before is razed); a night crew of two at each
## from the start, a shift of two indoors until its stage; the engineers on guard mend, beat out a fire in use, and rebuild a fall not
## in use (Structure.restore(), decision 92, on the barn and the mill); a target down when its time comes is razed; return and relief;
## the town's own teams keep off (hands_off). All three razed wins; the carts at 5:00 lose. Freed bodies are borne (review focus 5);
## the town's regroup and evacuation pass the crews by (review focus 4); the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_stage(t)
	_ahead(t)
	_down(t)
	_rebuild(t)
	_mend(t)
	_smother(t)
	_relief(t)
	_evacuated(t)
	_keeps_off(t)
	_chain(t)
	_ends(t)
	_tower_reserved(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.crowns_bread())


## Moves every crewman of target `i` well away from it (v0.11 M4 tests): off guard, still alive.
static func _clear(d: CrownsBreadDirector, i: int) -> void:
	for c: CrownsBreadDirector.Crew in d.crews[i]:
		if MissionDirector._alive(c.man) and not (c.man as Person).inside:
			Kit.arrive(c.man as Person, d.targets[i].center() + Vector2(6.0, 6.0))


## Puts every crewman of target `i` out of doors back on duty at his post, past fear for a few seconds (v0.11 M4 tests): a fall or a
## blow frightens the crew like anyone near it (the town's own fright), which these tests step past to measure the work itself.
static func _steady(d: CrownsBreadDirector, i: int) -> void:
	for c: CrownsBreadDirector.Crew in d.crews[i]:
		if MissionDirector._alive(c.man) and not (c.man as Person).inside:
			var p := c.man as Person
			Kit.arrive(p, c.post)
			p.go_duty(c.post)
			p.fearless_left = 5.0


## Every crewman of target `i` out of doors killed and freed (v0.11 M4 tests).
static func _strike_all(s: Dictionary, d: CrownsBreadDirector, i: int) -> void:
	for c: CrownsBreadDirector.Crew in d.crews[i]:
		if MissionDirector._alive(c.man) and not (c.man as Person).inside:
			Kit.free_body(s, c.man)


static func _setup(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var town: Town = s.town
	var barn := d.targets[0]
	var ok := d.targets.size() == 3 and barn.role == &"farm" and barn.kind == Structure.Kind.HOUSE and barn.art_tag == &"" \
		and barn.footprint.position.is_equal_approx(TownLayout.BARNS[3].position) and d.targets[1].art_tag == &"watermill" \
		and d.targets[2] == town.bridge
	var seen := {}
	for i in 3:
		var night: Array = []
		for c: CrownsBreadDirector.Crew in d.crews[i]:
			var p := c.man as Person
			ok = ok and p != null and not seen.has(p) and p.profile.role == CitizenProfile.Role.ENGINEER and not p.soldier
			seen[p] = true
			if c.shift:
				ok = ok and p.inside
			else:
				ok = ok and not p.inside and p.mind == Person.Mind.DUTY and p.ground_pos.distance_to(c.post) < 0.1 \
					and d.targets[i].distance_to(p.ground_pos) <= CrownsBreadDirector.GUARD_REACH
				night.append(p)
		ok = ok and night.size() == CrownsBreadDirector.NIGHT_CREW \
			and (night[0] as Person).ground_pos.distance_to((night[1] as Person).ground_pos) > 2.0 * SilentDoom.RADIUS
	t.check(ok and seen.size() == 3 * (CrownsBreadDirector.NIGHT_CREW + CrownsBreadDirector.SHIFT),
		"the granary (the east-road barn), the mill and the bridge; at each a night crew on duty at its posts, one Doom apart, and its shift indoors: %d lay engineers" % seen.size())
	var eng := (s.crowd as Crowd).engineers
	t.check(eng.hands_off.size() == 3 and eng.hands_off.has(barn) and eng.not_hired.size() == seen.size() and not d.in_use[0],
		"the town's teams keep off the three, and the workshop never hires a crewman; nothing in use yet")
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["stage_0", "stage_1", "stage_2", "carts"], "the strip: three stages, then the carts (%s)" % [ids])
	var clear := true
	for st in d.targets:
		clear = clear and Kit.clear_of_stack(st.center(), CrownsBreadDirector.CAMERA_AT)
	clear = clear and Kit.clear_of_stack(d.waiting_in[2].center(), CrownsBreadDirector.CAMERA_AT)
	t.check(clear, "the camera keeps the three targets and the bridge shift's tower (or their arrows) clear of the left HUD stack")
	var m := MissionBook.crowns_bread()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 3 and is_equal_approx(m.clock, 360.0) and m.dp_capacity == 10 and reasons == ["bread", "fed", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "ember", "whisper"] and MissionBook.get_mission("crowns_bread").id == "crowns_bread",
		"the mission: Tier 3's numbers; the bread, the carts, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	var held := true
	for i in 3:
		for c: CrownsBreadDirector.Crew in d.crews[i]:
			var p := c.man as Person
			held = held and (p.inside if c.shift else p.mind == Person.Mind.DUTY)
	t.check(held, "the town's regroup and evacuation pass the night crews by; the shifts stay indoors (review focus 4)")
	Kit.done(s)


static func _stage(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	Kit.run_for(s, float(CrownsBreadDirector.STAGE_AT[0]) + DT)
	var out := true
	for c: CrownsBreadDirector.Crew in d.crews[0]:
		out = out and not (c.man as Person).inside and (c.man as Person).mind == Person.Mind.DUTY and (c.man as Person).anchor == c.post
	t.check(d.in_use[0] and out and (s.banners as Array).has("THE GRAIN CARTS FILL THE GRANARY") and not d.in_use[1],
		"at its time the granary is in use and its shift comes out to its posts")
	Kit.done(s)


static func _ahead(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var mill := d.targets[1]
	(s.crowd as Crowd).fires.ignite(mill, 0.5)
	Kit.run_for(s, 0.1)
	t.check(not d.burning(mill), "fire on a target not in use is put out at once (the Raze base's rule)")
	mill.destroy(mill.center(), &"smite")
	Kit.run_for(s, 0.5)
	t.check(not d.razed(mill) and d.hint_phase() in ["not_yet", ""], "a fall before its time is not razed")
	_steady(d, 1)
	Kit.run_for(s, CrownsBreadDirector.REBUILD + 0.5)
	t.check(not mill.destroyed and is_equal_approx(mill.hp, mill.max_hp) and d.rebuilt == 1
		and (s.banners as Array).has("THE ENGINEERS REBUILD THE MILL"), "two on guard rebuild it in REBUILD")
	Kit.done(s)


static func _down(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var barn := d.targets[0]
	for c: CrownsBreadDirector.Crew in d.crews[0]:
		if not c.shift:
			Kit.free_body(s, c.man)
	barn.destroy(barn.center(), &"smite")
	Kit.run_for(s, float(CrownsBreadDirector.STAGE_AT[0]) + DT)
	t.check(d.razed(barn) and d.razed_count() == 1, "a target still down when its time comes is razed at once: holding it down was not wasted")
	var home := true
	for c: CrownsBreadDirector.Crew in d.crews[0]:
		if MissionDirector._alive(c.man):
			home = home and not (c.man as Person).inside and (c.man as Person).mind != Person.Mind.DUTY
	t.check(home, "razed, its shift comes out and goes home")
	Kit.done(s)


static func _rebuild(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	var ok := true
	for i in 2:
		var st := d.targets[i]
		var inner := st.center()
		st.destroy(st.center(), &"smite")
		var opened := grid.walkable(inner)
		var night: Array = []
		for c: CrownsBreadDirector.Crew in d.crews[i]:
			if not c.shift:
				night.append(c.man)
		Kit.free_body(s, night[1])
		_steady(d, i)
		Kit.run_for(s, CrownsBreadDirector.REBUILD + 1.0)
		var half := st.destroyed and d.rebuild_left(i) > 0.0
		Kit.run_for(s, CrownsBreadDirector.REBUILD_ONE - CrownsBreadDirector.REBUILD)
		ok = ok and opened and half and not st.destroyed and is_equal_approx(st.hp, st.max_hp) and is_equal_approx(st.height, st.max_height) \
			and not grid.walkable(inner)
	t.check(ok, "the barn and the watermill fall and are rebuilt by one engineer in REBUILD_ONE: standing, whole, their ground closed again (decision 92)")
	Kit.done(s)


static func _mend(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var barn := d.targets[0]
	barn.damage(20.0, barn.center(), &"smite")
	_steady(d, 0)
	var low := barn.hp
	Kit.run_for(s, 4.0)
	t.near(barn.hp - low, 2.0 * CrownsBreadDirector.MEND * barn.max_hp * 4.0, 0.6, "two on guard mend 2 x MEND of its health a second")
	Kit.done(s)


static func _smother(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var barn := d.targets[0]
	d._open(0)
	(s.crowd as Crowd).fires.ignite(barn, 0.5)
	_steady(d, 0)
	Kit.run_for(s, 1.0)
	t.check(d.burning(barn), "in use, a fire burns on")
	Kit.run_for(s, CrownsBreadDirector.SMOTHER_AFTER)
	t.check(not d.burning(barn) and is_zero_approx(d.burned(barn)), "with one on guard it is beaten out after SMOTHER_AFTER, its burning forgotten")
	_strike_all(s, d, 0)
	(s.crowd as Crowd).fires.ignite(barn, 0.5)
	Kit.run_for(s, CrownsBreadDirector.SMOTHER_AFTER + 1.0)
	t.check(d.burning(barn) or barn.destroyed, "with none on guard it burns on")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var c: CrownsBreadDirector.Crew = d.crews[1][0]
	var dead: Variant = c.man
	Kit.free_body(s, dead)
	Kit.run_for(s, CrownsBreadDirector.RELIEF_AFTER + 1.0)
	var p: Variant = c.man
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.ENGINEER
		and (p as Person).anchor == c.post and (s.crowd as Crowd).engineers.not_hired.has(p)
		and Kit.labels(d).has("ENGINEER"), "RELIEF_AFTER after a crewman falls, a relief made an engineer walks to his post")
	var away := d.crews[1][1] as CrownsBreadDirector.Crew
	var man := away.man as Person
	Kit.arrive(man, away.post + Vector2(6.0, 6.0))
	man.confuse(5.0)
	Kit.run_for(s, 1.0)
	man._come_to()  # headless people never think, so his confusion is lifted by hand (the controller's ruling)
	t.check(man.mind == Person.Mind.RECOVER and d.crews[1][1].away > 0.5, "(set-up) off his post and back on his feet, he is away")
	Kit.run_for(s, CrownsBreadDirector.RETURN_AFTER + 2.0)
	t.check(man.mind == Person.Mind.DUTY and man.anchor == away.post,
		"one confused off his post is sent back on duty to it RETURN_AFTER after he left, once back on his feet")
	Kit.done(s)


## The controller's ruling (every M4 mission): the town evacuates mid-mission, with one crewman of the target in use recovering and
## one whispered; at the next looks the first is stopped and back on duty at his post, the second's flight is ended, and woken he
## walks back, never to the gates. The shift of a target not yet in use stays indoors on duty.
static func _evacuated(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	d._open(0)
	Kit.run_for(s, 1.0)
	var first := d.crews[0][0] as CrownsBreadDirector.Crew
	var second := d.crews[0][1] as CrownsBreadDirector.Crew
	var a := first.man as Person
	var b := second.man as Person
	a._recover(1.0)
	b.whisper(second.post + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(s)
	t.check(a.mind == Person.Mind.FLEE and b._whisper_fled,
		"(set-up) the evacuation sends the recovering crewman running and owes the whispered one a flight")
	Kit.run_for(s, 2.0 * CrownsBreadDirector.TICK + DT)
	t.check(a.mind == Person.Mind.DUTY and a.anchor == first.post and b.mind == Person.Mind.WHISPERED and not b._whisper_fled,
		"at the next looks the first is back on duty at his post, the second's flight is ended")
	b._wake()  # headless people never think: the whisper wears off by hand
	Kit.arrive(b, second.post + Vector2(6.0, 6.0))
	Kit.run_for(s, CrownsBreadDirector.RETURN_AFTER + 1.0)
	var waiting := d.crews[1][2] as CrownsBreadDirector.Crew
	t.check(b.mind == Person.Mind.DUTY and b.anchor == second.post and (waiting.man as Person).inside
		and (waiting.man as Person).mind == Person.Mind.DUTY,
		"woken, he walks back to his post, not to the gates; the mill's shift waits indoors on duty")
	Kit.done(s)


static func _keeps_off(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var eng := (s.crowd as Crowd).engineers
	var bridge := d.targets[2]
	bridge.damage(bridge.max_hp * 0.5, bridge.center(), &"smite")
	var jobs := []
	for j: Dictionary in eng.jobs():
		jobs.append(j.target)
	t.check(not jobs.has(bridge), "the town's own teams make no job of the bridge")
	var targets := d.targets.duplicate()
	d.teardown()
	t.check(eng.hands_off.is_empty() and eng.not_hired.is_empty() and targets.size() == 3, "teardown empties hands_off and not_hired")
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var barn := d.targets[0]
	d._open(0)
	_clear(d, 0)
	barn.destroy(barn.center(), &"smite")
	Kit.run_for(s, 0.1)
	var shown := d.timeline.seconds_to("stage_1")
	t.check(d.razed(barn) and (s.banners as Array).has("THE GRANARY IS RAZED") and shown <= CrownsBreadDirector.CHAIN + 0.1
		and Kit.labels(d)[0].begins_with("MILL - IN USE BY"), "razed in use; the mill's time chained, CHAIN on (%.1f)" % shown)
	Kit.run_for(s, CrownsBreadDirector.CHAIN + DT)
	t.check(d.in_use[1] and (s.banners as Array).has("THE MILL GRINDS THE CROWN'S FLOUR"), "the mill comes into use CHAIN after")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	for i in 3:
		d._open(i)
		_clear(d, i)
		d.targets[i].destroy(d.targets[i].center(), &"smite")
	Kit.run_for(s, 0.1)
	t.check(d.all_razed() and main.check(s.rules) == Objective.Status.DONE and main.reason == "bread"
		and main.hud_text(s.rules) == "Raze the Crown's bread 3 / 3", "all three razed: the Crown's bread is ruined")
	Kit.done(s)
	var n := _world()
	var carts: Objective = (n.rules as Rules).objectives[1]
	t.check(carts.hud_text(n.rules) == "Carts roll 5:00", "the deadline row (%s)" % carts.hud_text(n.rules))
	(n.d as CrownsBreadDirector).timeline.step(CrownsBreadDirector.CARTS_AT + DT)  # the strip's own clock to 5:00, without 300 s of crowd
	t.check(carts.check(n.rules) == Objective.Status.FAILED and carts.reason == "fed" and (n.banners as Array).has("THE CROWN'S CARTS ROLL"),
		"left alone, the carts roll at 5:00: the Crown is fed")
	Kit.done(n)


static func _tower_reserved(t) -> void:
	var west: Variant = null
	var probe := _world()
	west = (probe.d as CrownsBreadDirector).waiting_in[2]
	var ix := (probe.town as Town)._built.find(west)
	Kit.done(probe)
	var s := Kit.world(MissionBook.crowns_bread(), null, func(d: MissionDirector, rules: Rules) -> void:
		d.reserved_places.append(rules.town()._built[ix]))
	var d: CrownsBreadDirector = s.d
	var east := d.waiting_in[2]
	t.check(ix >= 0 and east != null and (s.town as Town)._built.find(east) != ix and east.role == &"tower"
		and east.footprint.position.is_equal_approx(TownLayout.GATE_TOWERS[1].position),
		"a wish's west gate tower set aside: the bridge's shift waits in the east one (review focus 6)")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 3) == ["GRANARY - IN USE BY 0:55", "MILL - IN USE BY 1:55", "BRIDGE - IN USE BY 3:05"]
		and Kit.edged(d, "MILL - IN USE BY 1:55") and labels.has("ENGINEER") and d.hint_phase() == "",
		"before its time each target is grey with its time, pointed at; ENGINEER on each crewman on guard (%s)" % [labels.slice(0, 3)])
	var mill := d.targets[1]
	mill.destroy(mill.center(), &"smite")
	_steady(d, 1)
	Kit.run_for(s, 1.0)
	t.check(Kit.labels(d)[1].begins_with("MILL - DOWN, REBUILT IN") and d.hint_phase() == "",
		"down, its rebuild counts down (the hint follows the granary, the current target, more than 25 s from its time)")
	Kit.run_for(s, float(CrownsBreadDirector.STAGE_AT[0]))
	t.check(Kit.labels(d)[0] == "GRANARY" and d.hint_phase() == "engineers", "in use: gold, ENGINEERS while one is on guard")
	_clear(d, 0)
	t.check(d.hint_phase() == "open", "none on guard: open")
	(s.crowd as Crowd).fires.ignite(d.targets[0], 0.5)
	t.check(Kit.labels(d)[0] == "GRANARY - BURNING", "burning: orange")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("The granary by the east road. In use at 0:55.")
		and String(tour[2][1]).ends_with("It takes blows, not fire."), "the tour: the granary, the mill, the bridge")
	t.check(ResultsScreen.ACT_TITLES.get("bread") == "THE CROWN'S BREAD IS RUINED" and ResultsScreen.ACT_TITLES.get("fed") == "THE CROWN IS FED",
		"its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: CrownsBreadDirector = s.d
	d._open(0)
	for i in 3:
		for c: CrownsBreadDirector.Crew in d.crews[i]:
			if MissionDirector._alive(c.man) and not (c.man as Person).inside:
				Kit.free_body(s, c.man)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.guards(0).is_empty() and d.hint_phase() == "open" and int(d.report().razed) == 0,
		"every crewman out of doors freed: the tags, hint and report bear it (review focus 5)")
	Kit.done(s)
