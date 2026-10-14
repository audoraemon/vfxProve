extends RefCounted
## v0.11 M4 The Prisoner (mission spec §2, PrisonerDirector, EscortDirector reused): she starts bound in the stocks down the Citadel's
## lane -- a whisper, a lure and a fright do nothing, no one seizes her -- her two gaolers either side, held past fear while she is
## bound (decision 119); the stocks' fall frees her (a Smite on their far side passes her by); free, the lay watchers -- gaolers,
## patrols, the postern's watch and, HUE_AFTER after the freeing, two searchers out of the Citadel -- seize her on sight, unless held
## by the god; a seizer felled or held lets her go; marched to the Citadel's gate she is taken back. Still bound at FREE_BY: taken
## inside. Out at the dock bank, or carried out by the crowd: won. The town's regroup and evacuation pass everyone by (review focus
## 4), at 0:00 and mid-night (the controller's ruling); freed bodies are borne (review focus 5); the tags, hints, tour, titles, camera
## and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_evacuated(t)
	_bound(t)
	_seized_at_once(t)
	_smite(t)
	_seen(t)
	_hounds(t)
	_inside(t)
	_dead(t)
	_out(t)
	_carried(t)
	_gate(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.prisoner())


## Kills and frees each of `who` still standing out of doors (v0.11 M4 tests).
static func _strike(s: Dictionary, who: Array) -> void:
	for v: Variant in who:
		if MissionDirector._alive(v) and not (v as Person).inside:
			Kit.free_body(s, v)


## The stocks brought down by a blow, then two looks: the first finds them down and frees her, the second looks at her free (v0.11
## M4 tests). The night runs a moment first, as it always has by the time a power lands: the director's first looks put her and her
## gaolers past fear before the fall frightens everyone near it.
static func _break(s: Dictionary, d: PrisonerDirector) -> void:
	Kit.run_for(s, 0.3)
	d.stocks.destroy(d.stocks.center(), &"smite")
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)


static func _setup(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var her := d.charge
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	t.check(d.stocks != null and d.stocks.kind == Structure.Kind.MARKET_STALL and d.stocks.role == PrisonerDirector.STOCKS_ROLE
		and is_equal_approx(d.stocks.max_hp, 25.0) and (s.town as Town)._built.has(d.stocks) and d.bound_by == d.stocks
		and not grid.path(d.citadel_door, d._walkable(PrisonerDirector.LANE_FOOT)).is_empty(),
		"the stocks: a drawn stall down the Citadel's lane, the director's own, the lane still walkable")
	var c := d.stocks.center()
	var march := grid.path(d.citadel_door, her.ground_pos)
	t.check(c.distance_to(d.citadel_door) >= PrisonerDirector.LANE_DOWN and her.ground_pos.distance_to(d.citadel_door) >= PrisonerDirector.LANE_DOWN
		and not march.is_empty(), "the stocks stand %.1f down the lane from the Citadel's gate (a seizure is a march, not a loss in a second)"
		% c.distance_to(d.citadel_door))
	var ok := her != null and d.bound and her.mind == Person.Mind.DUTY and absf(her.ground_pos.distance_to(c) - PrisonerDirector.HER_OFF) < 0.3 \
		and d.stocks_far.distance_to(her.ground_pos) > SmiteFx.KILL_R + 0.5 and d.stocks.distance_to(d.stocks_far) <= SmiteFx.HIT_R
	ok = ok and d.gaolers.size() == PrisonerDirector.GAOLERS and d.searchers.size() == PrisonerDirector.HOUNDS
	for v: Variant in d.gaolers:
		var g := v as Person
		var gap := g.ground_pos.distance_to(her.ground_pos)
		ok = ok and gap > SilentDoom.RADIUS and gap <= EscortDirector.SIGHT and g.mind == Person.Mind.DUTY
	ok = ok and (d.gaolers[0] as Person).ground_pos.distance_to((d.gaolers[1] as Person).ground_pos) > 2.0 * SilentDoom.RADIUS
	t.check(ok, "she stands bound 1.0 from the stocks; the far-side aim passes her by; two gaolers within sight, beyond one Doom of her")
	var people := [her]
	for v: Variant in d._watchers() + d.searchers:
		people.append(v)
	var lay := true
	var seen := {}
	for v: Variant in people:
		var p := v as Person
		lay = lay and not p.soldier and not seen.has(p) and (p == her or p.profile.role == CitizenProfile.Role.WATCHMAN)
		seen[p] = true
	var inside := true
	for v: Variant in d.searchers:
		inside = inside and (v as Person).inside
	t.check(lay and inside and seen.size() == 11 and d.watch.size() == 2 and d.patrols.size() == 2,
		"eleven lay citizens: she, two gaolers, two patrols of two, the postern's watch of two, two searchers indoors; no soldier")
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["inside"], "the strip: the gaolers' deadline (%s)" % [ids])
	var cam := PrisonerDirector.CAMERA_AT
	t.check(Kit.clear_of_stack(c, cam) and Kit.clear_of_stack(d.exit_at, cam) and Kit.clear_of_stack(d.citadel_door, cam),
		"the camera keeps the stocks, the postern and the Citadel's gate (or their arrows) clear of the left HUD stack")
	var m := MissionBook.prisoner()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 3 and is_equal_approx(m.clock, 360.0) and reasons == ["prisoner_out", "dawn"]
		and Array(m.default_loadout) == ["whisper", "doom", "ember", "discord"] and MissionBook.get_mission("prisoner").id == "prisoner",
		"the mission: Tier 3's numbers; her way out, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var crowd: Crowd = s.crowd
	var at := d.charge.ground_pos
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := d.charge.mind == Person.Mind.DUTY and d.charge.ground_pos.distance_to(at) < 0.3
	for v: Variant in d._watchers():
		held = held and (v as Person).mind == Person.Mind.DUTY
	for v: Variant in d.searchers:
		held = held and (v as Person).inside
	t.check(held, "the town's regroup and evacuation pass her and every watcher by; the searchers stay indoors (review focus 4)")
	Kit.done(s)


## The evacuation mid-night (the controller's ruling: every M4 mission): with her free, a gaoler recovering away from his post and a
## patrol watchman whispered when the town evacuates are not lost to the gates -- the first is back on duty at his post at the next
## looks, the second's owed flight is ended, and woken he takes his beat again, not the road out. His mate, recovering under a false
## calm, owes a flight for when it wears off (Person._reassured_fled): that is let go too.
static func _evacuated(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var her := d.charge
	_strike(s, [d.gaolers[1]])
	_strike(s, d.patrols[1])
	var a := d.gaolers[0] as Person
	var b := (d.patrols[0] as Array)[0] as Person
	var mate := (d.patrols[0] as Array)[1] as Person
	Kit.arrive(a, her.ground_pos + Vector2(8.0, 0.0))
	Kit.arrive(b, her.ground_pos + Vector2(-7.0, 0.0))
	Kit.arrive(mate, her.ground_pos + Vector2(-7.5, 0.0))
	_break(s, d)
	a.fearless_left = 0.0  # headless people never think: the hold past fear while she was bound wears off by hand
	a._recover(1.0)
	b.whisper(b.ground_pos + Vector2(-1.0, 0.0), MindWhisperFx.LINGER)
	mate.fearless_left = 5.0
	mate._recover(1.0)
	Kit.evacuate(s)
	t.check(not d.bound and not d.held and a.mind == Person.Mind.FLEE and b._whisper_fled and mate._reassured_fled,
		"(set-up) she is free; the evacuation sends the recovering gaoler running, owes the whispered watchman a flight, his mate one later")
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(a.mind == Person.Mind.DUTY and a.anchor == d.gaoler_posts[0] and b.mind == Person.Mind.WHISPERED and not b._whisper_fled
		and not mate._reassured_fled and mate.mind == Person.Mind.DUTY,
		"at the next looks the gaoler is back on duty at his post, the watchman's flight is ended, his mate's let go and he walks his beat")
	b._wake()  # headless people never think: the whisper wears off by hand
	Kit.run_for(s, EscortDirector.TICK + DT)
	var on_beat := false
	for at: Vector2 in d.beats[0]:
		on_beat = on_beat or b.anchor.distance_to(at) <= 1.0
	t.check(b.mind == Person.Mind.DUTY and on_beat and not d.held, "woken, he walks his beat again, not the road to the gates")
	Kit.done(s)


static func _bound(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var her := d.charge
	var g := d.gaolers[0] as Person
	Kit.arrive(g, her.ground_pos + Vector2(0.6, 0.0))
	Kit.run_for(s, 0.5)
	t.check(not d.held and not her.whisper(her.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
		and not her.lure(her.ground_pos + Vector2(2.0, 0.0), 5.0) and d.hint_phase() == "bound",
		"bound: a gaoler beside her seizes no one; a whisper and a lure on her do nothing")
	her.panic(her.ground_pos + Vector2(0.4, 0.0), 1.0)
	g.panic(g.ground_pos + Vector2(0.4, 0.0), 1.0)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(her.mind == Person.Mind.DUTY and g.mind == Person.Mind.DUTY and main.hud_text(s.rules).begins_with("Free the prisoner: taken inside ") and main.hud_text(s.rules) != "Free the prisoner: taken inside 0:00",
		"bound, she and her gaolers are past fear; the HUD's row counts down to 2:00 (%s)" % main.hud_text(s.rules))
	Kit.done(s)


static func _seized_at_once(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	_break(s, d)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(not d.bound and d.held and d._watchers().has(d.seizer) and (s.banners as Array).has("SHE IS FREE")
		and (s.banners as Array).has("THE PRISONER IS CAUGHT") and d.hint_phase() == "caught" and main.hud_text(s.rules) == "Lead her out: caught",
		"the stocks down with her gaolers at their posts, past fear: a watcher seizes her the moment she is free")
	t.check(not d.taken and Kit.labels(d).has("TAKING HER BACK") and Kit.edged(d, "TAKING HER BACK"),
		"seized down the lane she is not yet taken: her seizer is pointed at while he marches her up it")
	var seizer := d.seizer as Person
	Kit.arrive(seizer, d.return_to)  # headless people never walk: the march is set down, as The Lost Lamb's _taken does
	Kit.arrive(d.charge, d.return_to + Vector2(0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(d.taken and main.check(s.rules) == Objective.Status.FAILED and main.reason == "prisoner_taken",
		"marched to the Citadel's gate, she is taken back: lost")
	Kit.done(s)


static func _smite(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var her := d.charge
	_strike(s, d.gaolers)
	for squad: Array in d.patrols:
		_strike(s, squad)
	Kit.run_for(s, 0.3)
	var struck := (s.field as EnemyField).in_radius(d.stocks_far, SmiteFx.KILL_R)
	(s.env as EnvironmentField).damage_radius(d.stocks_far, SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")
	Kit.run_for(s, 0.3)
	t.check(not struck.has(her) and d.stocks.destroyed and not d.bound and not d.held and MissionDirector._alive(her)
		and is_equal_approx(her.health, Person.HEALTH_CITIZEN) and d.hint_phase() == "",
		"her gaolers gone, a Smite on the stocks' far side brings them down and passes her by: free, unhurt")
	t.check(her.whisper(her.ground_pos + Vector2(0.0, 3.0), MindWhisperFx.LINGER), "free, a whisper takes her at once")
	Kit.done(s)


static func _seen(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var her := d.charge
	var g := d.gaolers[0] as Person
	var p := (d.patrols[0] as Array)[0] as Person
	var q := (d.patrols[0] as Array)[1] as Person
	_strike(s, [d.gaolers[1]])
	Kit.arrive(p, her.ground_pos + Vector2(8.0, 0.0))
	Kit.arrive(q, her.ground_pos + Vector2(-8.0, 0.0))
	g.whisper(g.ground_pos + Vector2(-4.0, 0.0), MindWhisperFx.LINGER)
	_break(s, d)
	t.check(not d.bound and not d.held, "a whispered gaoler sees nothing: no seizure")
	p.confuse(10.0)
	Kit.arrive(p, her.ground_pos + Vector2(1.0, 0.0))
	Kit.run_for(s, 0.3)
	t.check(not d.held, "a watcher held by Discord sees nothing")
	Kit.arrive(q, her.ground_pos + Vector2(-1.0, 0.0))
	Kit.run_for(s, 0.3)
	t.check(d.held and d.seizer == q, "a watcher on his beat within sight seizes her")
	q.whisper(q.ground_pos + Vector2(-4.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, 0.3)
	t.check(not d.held and not d.taken, "a whisper on her seizer frees her where she stands")
	Kit.done(s)


static func _hounds(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	_strike(s, d.gaolers)
	for squad: Array in d.patrols:
		_strike(s, squad)
	_break(s, d)
	var shown := d.timeline.seconds_to("hunt")
	t.check(shown > PrisonerDirector.HUE_AFTER - 1.0 and shown <= PrisonerDirector.HUE_AFTER, "the hounds on the strip, HUE_AFTER on (%.1f)" % shown)
	d.timeline.step(PrisonerDirector.HUE_AFTER)
	var out := d.hunters.size() == PrisonerDirector.HOUNDS
	for v: Variant in d.hunters:
		out = out and not (v as Person).inside and (v as Person).mind == Person.Mind.DUTY and d.searchers.has(v) \
			and (v as Person).ground_pos.distance_to(d.citadel_door) < 0.5
	t.check(out and (s.banners as Array).has("THE CITADEL SENDS ITS HOUNDS") and d.hint_phase() == "hounds" and Kit.edged(d, "SEARCHER"),
		"HUE_AFTER after the freeing two searchers come out of the Citadel's gate after her, pointed at")
	Kit.done(s)


static func _inside(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	d.timeline.step(PrisonerDirector.FREE_BY + DT)
	t.check(d.bound_lost and main.check(s.rules) == Objective.Status.FAILED and main.reason == "prisoner_inside"
		and (s.banners as Array).has("THE GAOLERS TAKE HER INSIDE"), "still bound at 2:00: the gaolers take her inside, lost")
	Kit.done(s)


static func _dead(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	Kit.free_body(s, d.charge)
	t.check(main.check(s.rules) == Objective.Status.FAILED and main.reason == "prisoner" and d.tags().is_empty() and d.hint_phase() == "",
		"she dies: lost, under its own key; the tags and hint bear her freed body")
	Kit.done(s)


static func _out(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	_strike(s, d.gaolers)
	for squad: Array in d.patrols:
		_strike(s, squad)
	_break(s, d)
	Kit.arrive(d.charge, d.exit_at)
	Kit.run_for(s, 0.3)
	t.check(d.escaped and main.check(s.rules) == Objective.Status.DONE and main.reason == "prisoner_out" and (s.banners as Array).has("SHE IS OUT"),
		"at the dock bank past the postern she is out: won")
	Kit.done(s)


static func _carried(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	_strike(s, d.gaolers)
	_break(s, d)
	(s.crowd as Crowd).escape(d.charge)
	t.check(d.escaped and main.check(s.rules) == Objective.Status.DONE and main.reason == "prisoner_out",
		"carried out of the town by the crowd or a boat, she has got away: won at once (review focus 5)")
	Kit.done(s)


static func _gate(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	_strike(s, d.gaolers)
	for squad: Array in d.patrols:
		_strike(s, squad)
	_break(s, d)
	var spot := d._walkable(d.gate_at + Vector2(1.5, -3.0))
	Kit.arrive(d.charge, spot)
	d._hold_at = spot  # as if a whisper had left her there: she holds where she is left
	d.charge.go_duty(spot)
	Kit.run_for(s, 0.5)
	t.check(d.change_in > 0.0 and d.hint_phase() == "gate" and Kit.labels(d).has("POSTERN - WATCHED"), "near the postern: watched, the change's clock started")
	Kit.run_for(s, EscortDirector.WATCH_CHANGE + 0.5)
	var off := true
	for v: Variant in d.watch:
		off = off and (v as Person).anchor.distance_to(d.guardhouse) < 1.5
	t.check(d.watch_away and off and d.hint_phase() == "clear" and Kit.labels(d).has("POSTERN - CLEAR") and (s.banners as Array).has("THE GUARD CHANGES"),
		"WATCH_CHANGE after she nears it the postern's lay watch walks to the guardhouse: clear")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels[0] == "PRISONER - DO NOT KILL" and Kit.edged(d, "PRISONER - DO NOT KILL") and labels.has("STOCKS - TAKEN IN AT 2:00")
		and labels.has("POSTERN - WATCHED") and Kit.edged(d, "POSTERN - WATCHED") and labels.count("GAOLER - SEIZES HER") == 2
		and labels.has("PATROL"),
		"bound: PRISONER - DO NOT KILL, pointed at; the stocks' deadline; the postern; GAOLER - SEIZES HER on each gaoler (the ruling's plain warning); PATROL (%s)" % [labels])
	t.check(MissionHints.line("prisoner", "bound").contains("seizes her") and MissionHints.line("prisoner", "bound").contains("Citadel"),
		"the bound hint warns plainly that a gaoler left standing seizes her and takes her back to the Citadel")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The prisoner in the stocks by the Citadel. Break her free by 2:00: do not kill her."
		and String(tour[2][1]) == "The Citadel. Once she is free it sends its hounds after her.", "the tour")
	t.check(ResultsScreen.ACT_TITLES.get("prisoner_out") == "THE PRISONER IS FREE" and ResultsScreen.ACT_TITLES.get("prisoner_taken") == "THE PRISONER IS TAKEN BACK"
		and ResultsScreen.ACT_TITLES.get("prisoner_inside") == "THE PRISONER IS TAKEN INSIDE" and ResultsScreen.ACT_TITLES.get("prisoner") == "THE PRISONER IS DEAD",
		"its results under its own keys, never the Escort defaults")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: PrisonerDirector = s.d
	_strike(s, d._watchers())
	d.tags()
	d.hint_phase()
	d.report()
	_break(s, d)
	Kit.run_for(s, 1.0)
	t.check(not d.bound and not d.held and Kit.labels(d)[0] == "PRISONER", "every watcher freed: the tags, hint and report bear it (review focus 5)")
	Kit.done(s)
