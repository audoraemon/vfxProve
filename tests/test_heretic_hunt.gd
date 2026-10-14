extends RefCounted
## v0.11 M4 The Heretic Hunt (mission spec §3, HereticHuntDirector, the Hunt type's first night): three parties of three watchmen on
## their rings from the start; a standard raised at each sweep's spot on the chain (0:45, then each at its time or CHAIN after the one
## before is broken); a guarded standard only shakes, an open one breaks to one Smite and its party goes home; return and relief; the
## captain, a resident made a noble, waits in the Temple with two escorts and comes out at 4:00 (or HEAD_CHAIN after the third
## breaks), never before the third is raised, searching the five houses nearest the cellar farthest first and then its door; a fright
## drops his search and he takes it up where he was. All three broken and the captain dead wins; the cellar found loses. The cellar
## (a quiet dwelling in the south-west quarter) only shakes, and takes blows again after teardown. The town's regroup and evacuation
## pass everyone by (review focus 4), at the start and mid-mission (the controller's ruling); freed bodies are borne (review focus 5);
## the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_guarded(t)
	_open(t)
	_captain_last(t)
	_found(t)
	_search_dropped(t)
	_won(t)
	_stone(t)
	_relief(t)
	_evacuated(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.heretic_hunt())


## Moves step `i`'s guards well off their ring (v0.11 M4 tests): off guard, still alive.
static func _clear(d: HereticHuntDirector, i: int) -> void:
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			Kit.arrive(g.man as Person, g.post + Vector2(5.0, 5.0))


## Step `i` raised, cleared and broken by a Smite on its standard (v0.11 M4 tests).
static func _break(s: Dictionary, d: HereticHuntDirector, i: int) -> void:
	d._raise(i)
	_clear(d, i)
	(s.env as EnvironmentField).damage_radius(d.standard(i).center(), SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")


static func _setup(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	var ok := d.steps.size() == 3 and d.standards.is_empty()
	var people := {}
	for i in 3:
		var st := d.steps[i]
		ok = ok and st.district == TownLayout.DISTRICTS[HereticHuntDirector.SWEEP_DISTRICTS[i]] and st.party.size() == HereticHuntDirector.PARTY
		for k in st.party.size():
			var g: HuntDirector.Guard = st.party[k]
			var p := g.man as Person
			ok = ok and p.mind == Person.Mind.DUTY and p.profile.role == CitizenProfile.Role.WATCHMAN and not p.soldier \
				and absf(g.post.distance_to(st.spot) - HereticHuntDirector.PARTY_R) < 0.4
			people[p] = true
			var nxt: HuntDirector.Guard = st.party[(k + 1) % st.party.size()]
			ok = ok and g.post.distance_to(nxt.post) > 2.0 * SilentDoom.RADIUS
	t.check(ok, "three parties of three watchmen on duty on their rings round each sweep's spot, one Doom apart; no standard yet")
	var head := d.head as Person
	var escorts_in := d.escorts.size() == HereticHuntDirector.ESCORTS
	for v: Variant in d.escorts:
		escorts_in = escorts_in and (v as Person).inside and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN
		people[v] = true
	people[head] = true
	t.check(head.inside and head.profile.role == CitizenProfile.Role.NOBLE and escorts_in and people.size() == 12 and not d.head_out,
		"the captain, made a noble, waits in the Temple with his two escorts: twelve lay citizens in all")
	var area: Rect2 = TownLayout.DISTRICTS[HereticHuntDirector.CELLAR_DISTRICT]
	var quiet := true
	for p in (s.crowd as Crowd).soldiers:
		if MissionDirector._alive(p) and p.post != Vector2.INF and p.post.distance_to(d.cellar_door) <= HereticHuntDirector.QUIET_R:
			quiet = false
	t.check(d.cellar != null and RuinWish.fits(d.cellar, "house") and area.has_point(d.cellar.center()) and quiet
		and d.cellar.damage_filter.is_valid(), "the cellar: a dwelling in the south-west quarter, its door quiet, stone tonight")
	var route := d.head_route
	var far_first: bool = route.size() == HereticHuntDirector.CAPTAIN_HOUSES + 1 and route.back() == d.cellar_door
	for k in range(1, route.size() - 1):
		far_first = far_first and route[k - 1].distance_to(d.cellar.center()) >= route[k].distance_to(d.cellar.center()) - 0.5
	t.check(far_first, "his route: the five houses nearest the cellar, farthest first, then its door (%d points)" % route.size())
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["step_0", "step_1", "step_2", "head"], "the strip: three sweeps, then the captain (%s)" % [ids])
	var cam := HereticHuntDirector.CAMERA_AT
	var clear := Kit.clear_of_stack(d.cellar_door, cam) and Kit.clear_of_stack(d._walkable(HereticHuntDirector.TEMPLE_DOOR), cam)
	for st in d.steps:
		clear = clear and Kit.clear_of_stack(st.spot, cam)
	t.check(clear, "the camera keeps the three spots, the cellar and the Temple's door (or their arrows) clear of the left HUD stack")
	var m := MissionBook.heretic_hunt()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 3 and is_equal_approx(m.clock, 360.0) and reasons == ["hunt", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "whisper", "discord"] and MissionBook.get_mission("heretic_hunt").id == "heretic_hunt",
		"the mission: Tier 3's numbers; the hunt, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := (d.head as Person).inside
	for st in d.steps:
		for g: HuntDirector.Guard in st.party:
			held = held and (g.man as Person).mind == Person.Mind.DUTY
	for v: Variant in d.escorts:
		held = held and (v as Person).inside
	t.check(held, "the town's regroup and evacuation pass the parties by; the captain and his escorts stay in the Temple (review focus 4)")
	Kit.done(s)


static func _guarded(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	Kit.run_for(s, float(HereticHuntDirector.STEP_AT[0]) + DT)
	var std := d.standard(0)
	t.check(std != null and std.distance_to(d.steps[0].spot) < 0.3 and (s.banners as Array).has("THE HUNT SWEEPS THE NORTH QUARTER")
		and d.guarded(0) and d.hint_phase() == "guarded" and Kit.labels(d)[0] == "STANDARD - GUARDED" and Kit.edged(d, "STANDARD - GUARDED"),
		"at %s the first standard is planted at its spot, guarded by its party, gold and pointed at" % UiTheme.clock(float(HereticHuntDirector.STEP_AT[0])))
	(s.env as EnvironmentField).damage_radius(std.center(), SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")
	var outlined := false
	for m in d.tags():
		outlined = outlined or m.outline == TownLayout.DISTRICTS[HereticHuntDirector.SWEEP_DISTRICTS[0]]
	t.check(not std.destroyed and is_equal_approx(std.hp, std.max_hp) and outlined, "guarded, a Smite only shakes it; its district is outlined")
	Kit.done(s)


static func _open(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	d._raise(0)
	_clear(d, 0)
	t.check(not d.guarded(0) and d.hint_phase() == "open" and Kit.labels(d)[0] == "STANDARD", "its party off it: open")
	var home := (d.steps[0].party[0] as HuntDirector.Guard).man as Person
	(s.env as EnvironmentField).damage_radius(d.standard(0).center(), SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")
	t.check(d.broken(0) and (s.banners as Array).has("A STANDARD FALLS") and home.mind != Person.Mind.DUTY
		and d.timeline.seconds_to("step_1") <= HereticHuntDirector.CHAIN + 0.1 and d.hint_phase() == "waiting",
		"one Smite breaks an open standard: its party goes home, the next sweep chained CHAIN on, the hint waiting")
	Kit.done(s)


static func _captain_last(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	d._call_head()
	d._raise(0)
	d._raise(1)
	Kit.run_for(s, 0.2)
	t.check(not d.head_out and (d.head as Person).inside, "the captain never comes before the third standard is raised")
	d._raise(2)
	Kit.run_for(s, 0.2)
	var head := d.head as Person
	t.check(d.head_out and not head.inside and head.mind == Person.Mind.DUTY and (s.banners as Array).has("THE CAPTAIN LEADS THE LAST SWEEP")
		and Kit.labels(d).has("CAPTAIN") and Kit.edged(d, "CAPTAIN") and Kit.labels(d).count("ESCORT") == 2 and d.hint_phase() == "captain",
		"the third raised, he comes out with his two escorts, pointed at")
	var gap := true
	Kit.run_for(s, 2.0)
	for v: Variant in d.escorts:
		gap = gap and (v as Person).ground_pos.distance_to(head.ground_pos) > SilentDoom.RADIUS
	t.check(gap, "his escorts walk beyond one Doom of him")
	Kit.done(s)


static func _found(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	for i in 3:
		d._raise(i)
	d._call_head()
	var head := d.head as Person
	for k in d.head_route.size() - 1:
		Kit.arrive(head, d.head_route[k])
		Kit.run_for(s, HereticHuntDirector.CAPTAIN_STOP + 0.3)
	t.check(d.searching and d._route_at == d.head_route.size() - 1 and d.hint_phase() == "searching"
		and Kit.labels(d).has("CAPTAIN - SEARCHING"), "he searches each house CAPTAIN_STOP, then makes for the cellar")
	Kit.arrive(head, d.cellar_door)
	Kit.run_for(s, 0.1)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.found and main.check(s.rules) == Objective.Status.FAILED and main.reason == "cellar" and (s.banners as Array).has("THE CELLAR IS FOUND"),
		"at the cellar's door he finds it: lost")
	Kit.done(s)


static func _search_dropped(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	for i in 3:
		d._raise(i)
	d._call_head()
	var head := d.head as Person
	Kit.arrive(head, d.head_route[0])
	Kit.run_for(s, HereticHuntDirector.CAPTAIN_STOP + 0.3)
	var at := d._route_at
	head.confuse(3.0)
	Kit.run_for(s, 1.0)
	t.check(head.mind != Person.Mind.DUTY and d._route_at == at, "Discord drops his search")
	head._come_to()  # headless people never think, so his confusion is lifted by hand (the controller's ruling)
	Kit.run_for(s, HuntDirector.TICK + DT)
	t.check(head.mind == Person.Mind.DUTY and d._route_at == at and head.anchor == d.head_route[at],
		"back on his feet he takes it up at the house he had reached")
	Kit.done(s)


static func _won(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	for i in 3:
		_break(s, d, i)
	t.check(d.broken_all() and main.check(s.rules) == Objective.Status.PENDING and main.hud_text(s.rules) == "Break the hunt: standards 3 / 3"
		and d.timeline.seconds_to("head") <= HereticHuntDirector.HEAD_CHAIN + 0.1 and HereticHuntDirector.HEAD_CHAIN < HereticHuntDirector.CHAIN,
		"three standards broken, the captain alive: not yet; he is due HEAD_CHAIN on, sooner than the sweeps' chain (the controller's ruling)")
	d._call_head()
	Kit.run_for(s, 0.2)
	t.check(main.hud_text(s.rules) == "Break the hunt: standards 3 / 3, kill the captain", "the HUD names the captain")
	(s.crowd as Crowd)._field.kill(d.head as Person, &"doom")
	var home := true
	for v: Variant in d.escorts:
		home = home and (v as Person).mind != Person.Mind.DUTY
	t.check(main.check(s.rules) == Objective.Status.DONE and main.reason == "hunt" and home,
		"the captain dead and every standard broken: the hunt is broken; his escorts go home")
	Kit.done(s)
	var w := _world()
	var wd: HereticHuntDirector = w.d
	for i in 3:
		_break(w, wd, i)
	Kit.run_for(w, HereticHuntDirector.HEAD_CHAIN + 0.2)
	t.check(wd.head_out and not (wd.head as Person).inside, "left alone, the captain comes out HEAD_CHAIN after the third standard breaks")
	Kit.done(w)


static func _stone(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	var cellar := d.cellar
	cellar.damage(999.0, cellar.center(), &"blast")
	t.check(not cellar.destroyed and is_equal_approx(cellar.hp, cellar.max_hp), "the cellar only shakes tonight")
	d.teardown()
	cellar.damage(10.0, cellar.center(), &"blast")
	t.check(not cellar.damage_filter.is_valid() and cellar.hp < cellar.max_hp, "after teardown it takes blows again")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	var g: HuntDirector.Guard = d.steps[1].party[0]
	var dead: Variant = g.man
	Kit.free_body(s, dead)
	Kit.run_for(s, HereticHuntDirector.RELIEF_AFTER + 1.0)
	t.check(g.man != dead and MissionDirector._alive(g.man) and (g.man as Person).profile.role == CitizenProfile.Role.WATCHMAN
		and (g.man as Person).anchor == g.post, "RELIEF_AFTER after a guard falls, a relief made a watchman walks to his post")
	Kit.done(s)


## The controller's ruling (every M4 mission): the town evacuates mid-mission, the captain out and searching and whispered, a guard of
## a raised standard recovering; at the next looks the guard is back on duty at his post and the captain's flight is ended; woken, he
## takes up his search where he was, never leaving the town to win the hunt by his absence.
static func _evacuated(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	for i in 3:
		d._raise(i)
	d._call_head()
	var head := d.head as Person
	Kit.arrive(head, d.head_route[0])
	Kit.run_for(s, 1.0)
	var g: HuntDirector.Guard = d.steps[2].party[0]
	var guard := g.man as Person
	guard._recover(1.0)
	head.whisper(head.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(s)
	t.check(d.searching and guard.mind == Person.Mind.FLEE and head._whisper_fled,
		"(set-up) the captain searching; the evacuation sends the recovering guard running and owes the whispered captain a flight")
	Kit.run_for(s, 2.0 * HuntDirector.TICK + DT)
	t.check(guard.mind == Person.Mind.DUTY and guard.anchor == g.post and head.mind == Person.Mind.WHISPERED and not head._whisper_fled,
		"at the next looks the guard is back on duty at his post, the captain's flight is ended")
	var at := d._route_at
	head._wake()  # headless people never think: the whisper wears off by hand
	Kit.run_for(s, 1.0)
	t.check(head.mind == Person.Mind.DUTY and head.anchor == d.head_route[at] and not d.head_down() and not d.found
		and (s.crowd as Crowd).citizens.has(head), "woken, he takes up his search at the house he had reached; he never leaves the town")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	var labels := Kit.labels(d)
	var first := "NEXT SWEEP %s" % UiTheme.clock(float(HereticHuntDirector.STEP_AT[0]))
	t.check(labels.has(first) and Kit.edged(d, first) and labels.has("CAPTAIN - IN THE TEMPLE")
		and labels.has("CELLAR") and Kit.edged(d, "CELLAR") and labels.has("GUARD") and d.hint_phase() == "",
		"at the start: the next sweep's time, pointed at; the captain in the Temple; the cellar, pointed at; GUARD on each guard (%s)" % [labels])
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "Your believers' cellar. If the hunt finds it, the night is lost."
		and String(tour[1][1]) == "The north quarter. The hunt raises its first standard here at %s." % UiTheme.clock(float(HereticHuntDirector.STEP_AT[0]))
		and String(tour[2][1]) == "The Temple. Its captain leads the last sweep by %s." % UiTheme.clock(float(HereticHuntDirector.STEP_AT[3])),
		"the tour")
	t.check(ResultsScreen.ACT_TITLES.get("hunt") == "THE HUNT IS BROKEN" and ResultsScreen.ACT_TITLES.get("cellar") == "THE CELLAR IS FOUND",
		"its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: HereticHuntDirector = s.d
	for i in 3:
		d._raise(i)
	d._call_head()
	Kit.run_for(s, 0.2)
	for v: Variant in [d.head] + d.escorts:
		if MissionDirector._alive(v):
			Kit.free_body(s, v)
	for st in d.steps:
		for g: HuntDirector.Guard in st.party:
			if MissionDirector._alive(g.man):
				Kit.free_body(s, g.man)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.head_down() and d.hint_phase() == "open" and not d.found, "the captain, his escorts and every guard freed: borne (review focus 5)")
	Kit.done(s)
