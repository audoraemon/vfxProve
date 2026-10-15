extends RefCounted
## v0.11 M5 The Relic Run (mission spec §4, RelicRunDirector, VigilFlameDirector reused): the relic cart -- its carter and two escorts,
## a VigilRoute -- sets out at 0:45 from the Temple for the Citadel, halting at two watch-houses for the watch's count; its reliquary
## opens only while it halts. Pip, from the start, slips aboard at a halt once no one watches, picks the lock on the way, and swaps the
## relic at the second halt only, unseen by rule (no report); then carries it to your believers' house under the Searchlight. A dead
## driver's reins pass on; all three dead stall the cart until new hands come, its reliquary locked. The relic at the Citadel, Pip dead
## or gone, or the Gaze lose. Wardens return and are relieved (flight-proofed, backed off); a seen death sends a report, and the bell's
## warning shows before the bell is called. The evacuation passes them by (review focus 2); freed bodies are borne (review focus 4).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_halt(t)
	_moving(t)
	_board(t)
	_rolls_on(t)
	_swap(t)
	_no_first_swap(t)
	_one_halt(t)
	_stall(t)
	_ends(t)
	_seen(t)
	_wardens(t)
	_relief(t)
	_evacuate(t)
	_tagged(t)
	_bell(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.relic_run())


## The cart at its `k`th checkpoint now (v0.11 M5 tests): set out if need be, its route's leg there, and its carter and escorts set
## down at it (headless people never walk).
static func _at_halt(s: Dictionary, d: RelicRunDirector, k: int) -> void:
	if not d.set_out:
		d._set_out_cart()
	d.vigil.leg = int(RelicRunDirector.HALT_LEGS[k]) - d._leg_base
	var at := d.checkpoints[k]
	Kit.arrive(d.vigil.bearer, at)
	for i in d.vigil.acolytes.size():
		Kit.arrive(d.vigil.acolytes[i], at + (VigilRoute.ACOLYTE_OFFSETS[i % 2] as Vector2))
	Kit.run_for(s, 0.1)


## The cart set out and its carter and escorts set down at the route's second point, away from the Temple's door (a Faithful there
## who sees a death would deliver his report at once) (v0.11 M5 tests); the cart's place.
static func _out_on_road(s: Dictionary, d: RelicRunDirector) -> Vector2:
	d._set_out_cart()
	var at := d.route[1]
	Kit.arrive(d.vigil.bearer, at)
	for i in d.vigil.acolytes.size():
		Kit.arrive(d.vigil.acolytes[i], at + (VigilRoute.ACOLYTE_OFFSETS[i % 2] as Vector2))
	Kit.run_for(s, 0.1)
	return d.cart_at()


## Everyone who watches the cart now held by Discord (it never lifts headless) (v0.11 M5 tests).
static func _blind(d: RelicRunDirector) -> void:
	for p in d.watchers_now():
		p.confuse(60.0)


static func _setup(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	t.check(d.route.size() == 6 and d.checkpoints.size() == 2 and d.checkpoints[0].distance_to(Vector2(9.5, -5.1)) < 1.0
		and d.checkpoints[1].distance_to(Vector2(-6.0, 9.0)) < 1.0 and d.route[5].distance_to(Vector2(-10.5, -7.6)) < 1.0,
		"the route: the east and west watch-houses its checkpoints, the Citadel's gate its end")
	t.check(d.drop_house != null and RuinWish.fits(d.drop_house, "house") and d.drop_house.center().distance_to(RelicRunDirector.DROP_SPOT) < 5.0
		and d.shrine != Vector2.INF, "your believers' house: the dwelling by the north-east point, its door the drop-off")
	var pip := d.wren
	t.check(MissionDirector._alive(pip) and d.appeared and not d.faithful.has(pip) and pip.mind == Person.Mind.DUTY
		and pip.ground_pos.distance_to(RelicRunDirector.PIP_SPOT) < 1.5, "Pip, a lay citizen east of the market, on duty from the start, never Faithful")
	var c := d.carter as Person
	var ok := c != null and not d.faithful.has(c) and c.ground_pos.distance_to(d.temple_door) < 0.5 and d.escorts.size() == RelicRunDirector.ESCORTS
	for v: Variant in d.escorts:
		ok = ok and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(v)
	t.check(ok and d._lantern.distance_to(d.temple_door) < 0.5 and not d.set_out, "the cart waits at the Temple's door: its carter (no Faithful) and two Faithful escorts")
	var posted := d.wardens.size() == 2 * RelicRunDirector.WARDENS
	for k in 2:
		var at := d.wardens_at(k)
		posted = posted and at.size() == 2 and at[0].ground_pos.distance_to(at[1].ground_pos) > 2.0 * SilentDoom.RADIUS
		for p in at:
			posted = posted and p.profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p) and p.mind == Person.Mind.DUTY
	t.check(posted, "two wardens at each watch-house, one Doom apart, Faithful watchmen on duty")
	var ids := []
	for e in d.timeline.upcoming(2):
		ids.append(e.id)
	t.check(ids == ["set_out"], "the strip: the relic sets out (the light's search shows once the light wakes) (%s)" % [ids])
	var cam := RelicRunDirector.CART_CAMERA
	t.check(Kit.clear_of_stack(d.temple_door, cam, Kit.STACK) and Kit.clear_of_stack(pip.ground_pos, cam, Kit.STACK)
		and Kit.clear_of_stack(d.checkpoints[0], cam, Kit.STACK) and Kit.clear_of_stack(d.checkpoints[1], cam, Kit.STACK)
		and Kit.clear_of_stack(d.shrine, cam, Kit.STACK),
		"the camera keeps the cart, Pip, both checkpoints and the drop-off (or their arrows) clear of the real HUD stack")
	var m := MissionBook.relic_run()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and reasons == ["gaze", "relic", "dawn"]
		and Array(m.default_loadout) == ["whisper", "discord", "doom", "wisp"] and MissionBook.get_mission("relic_run").id == "relic_run",
		"the mission: Tier 4's numbers; the Gaze, the relic, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := d.wren.mind == Person.Mind.DUTY and (d.carter as Person).mind == Person.Mind.DUTY
	for w: RelicRunDirector.Warden in d.wardens:
		held = held and (w.man as Person).mind == Person.Mind.DUTY
	t.check(held, "the regroup and the evacuation pass Pip, the cart and the wardens by (review focus 2)")
	Kit.done(s)


static func _halt(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	Kit.run_for(s, RelicRunDirector.SET_OUT_AT + DT)
	t.check(d.set_out and d.vigil != null and d.vigil.active and (s.banners as Array).has("THE RELIC SETS OUT") and d.hint_phase() == "moving",
		"at 0:45 the relic sets out")
	_at_halt(s, d, 0)
	var stepped := true
	for p in d.wardens_at(0):
		stepped = stepped and p.anchor.distance_to(d.cart_at()) < 1.5
	t.check(d.halt == 0 and d.vigil.leg == 0 and stepped and (s.banners as Array).has("THE CART HALTS AT THE EAST WATCH-HOUSE"),
		"at the east watch-house the cart halts; its wardens step up for the count")
	var stood := d.cart_at()
	Kit.arrive(d.vigil.bearer, stood + Vector2(1.5, 0.0))
	Kit.run_for(s, 0.1)
	t.check(d.cart_at().is_equal_approx(stood), "halted, the cart stands where it stopped though its carter wanders (held by the god)")
	Kit.arrive(d.vigil.bearer, stood)
	Kit.run_for(s, RelicRunDirector.COUNT + 0.6)
	t.check(d.halt == -1 and d.halts_done[0] and (s.banners as Array).has("THE CART ROLLS ON") and d.vigil.leg == 1,
		"the count done with the watch at the cart, the reliquary closes and the cart rolls on")
	Kit.done(s)


static func _moving(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	Kit.arrive(d.wren, d.cart_at())
	d.wren.whisper(d.cart_at(), MindWhisperFx.LINGER)
	Kit.run_for(s, RelicRunDirector.BOARD + 1.0)
	t.check(not d.aboard and d.halt < 0, "no hand reaches the relic while the cart moves")
	Kit.done(s)


static func _board(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	_at_halt(s, d, 0)
	Kit.arrive(d.wren, d.cart_at() + Vector2(0.0, 0.6))
	Kit.run_for(s, RelicRunDirector.BOARD + 0.5)
	t.check(d.watched() and not d.aboard and Kit.labels(d).has("PIP - WAITING, DO NOT KILL") and d.hint_phase() == "watched",
		"by a watched cart Pip waits (his tag still says DO NOT KILL): he never boards while watched")
	_blind(d)
	Kit.run_for(s, RelicRunDirector.BOARD + 0.2)
	t.check(not d.watched() and d.aboard and d.wren.inside and (s.banners as Array).has("PIP SLIPS ABOARD")
		and d.hud_line() == "The relic: Pip at the lock", "the watch held, BOARD seconds unwatched and he slips aboard, hidden")
	Kit.done(s)


static func _rolls_on(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	_at_halt(s, d, 0)
	Kit.arrive(d.wren, d.cart_at())
	d._board()
	Kit.run_for(s, RelicRunDirector.COUNT + 0.6)
	t.check(d.halts_done[0] and d.halt == -1 and d.aboard and d.wren.inside, "a cart with Pip aboard leaves the first halt once its count is done")
	Kit.run_for(s, RelicRunDirector.LOCK + 0.5)
	t.check(d.lock_left <= 0.0 and Kit.labels(d)[0] == "RELIC CART - PIP ABOARD" and d.hud_line() == "The relic: Pip aboard"
		and d.wren.ground_pos.is_equal_approx(d.cart_at()) and d.hint_phase() == "aboard", "he picks the lock on the way, carried with the cart")
	Kit.done(s)


static func _swap(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	d.halts_done[0] = true
	d._board()
	d.lock_left = 0.0
	_at_halt(s, d, 1)
	Kit.run_for(s, RelicRunDirector.SWAP + 0.5)
	t.check(d.halt == 1 and not d.swapped and d.watched(), "at the second halt, watched: no swap")
	_blind(d)
	Kit.run_for(s, RelicRunDirector.SWAP + 0.3)
	t.check(d.swapped and not d.aboard and not d.wren.inside and d.wren.anchor == d.shrine and d.searchlight.on and d.reports_started == 0
		and (s.banners as Array).has("THE RELIC IS TAKEN") and d.hint_phase() == "carry"
		and d.hud_line().begins_with("The relic to your believers: "), "SWAP seconds unwatched: he swaps it, slips out and makes for your believers' house; no report, the light wakes")
	t.check(Kit.labels(d).has("PIP - THE RELIC, DO NOT KILL") and Kit.edged(d, "PIP - THE RELIC, DO NOT KILL") and not Kit.labels(d).has("RELIC CART"),
		"with the relic his tag still says DO NOT KILL; the cart's tag is gone (a false relic)")
	Kit.arrive(d.wren, d.shrine)
	Kit.run_for(s, 0.1)
	var main: Objective = (s.rules as Rules).objectives[1]
	t.check(d.home and main.check(s.rules) == Objective.Status.DONE and main.reason == "relic" and (s.banners as Array).has("YOUR BELIEVERS HAVE THE RELIC"),
		"at your believers' door: the relic is ours")
	Kit.done(s)


static func _no_first_swap(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	_at_halt(s, d, 0)
	Kit.arrive(d.wren, d.cart_at())
	d._board()
	d.lock_left = 0.0
	_blind(d)
	Kit.run_for(s, RelicRunDirector.SWAP + 1.0)
	t.check(d.aboard and not d.swapped, "the swap waits for the second halt (plan decision 192): the drop-off is not reached from the first")
	Kit.done(s)


## The one-halt path (the final review; Decision 153's fallback in play): Pip who let the first halt pass boards at the second, picks
## the lock and swaps the relic within that one halt, while its watch is held.
static func _one_halt(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	d.halts_done[0] = true
	_at_halt(s, d, 1)
	Kit.arrive(d.wren, d.cart_at() + Vector2(0.0, 0.6))
	_blind(d)
	Kit.run_for(s, RelicRunDirector.BOARD + 0.2)
	t.check(d.halt == 1 and d.aboard and d.wren.inside and d.lock_left > 0.0 and not d.swapped,
		"at the second halt, the first let pass: he slips aboard, the lock still shut")
	Kit.run_for(s, RelicRunDirector.LOCK + 0.2)
	t.check(d.halt == 1 and d.aboard and d.lock_left <= 0.0 and d.wren.ground_pos.is_equal_approx(d.cart_at()) and not d.swapped,
		"he picks the lock while the cart stands, carried with it (%.1f left)" % d.lock_left)
	Kit.run_for(s, RelicRunDirector.SWAP + 0.3)
	t.check(d.halt == 1 and d.swapped and not d.aboard and not d.wren.inside and d.wren.anchor == d.shrine
		and (s.banners as Array).has("THE RELIC IS TAKEN"), "and swaps it within the same halt: out, making for your believers' house")
	Kit.done(s)


static func _stall(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var at := _out_on_road(s, d)
	for v: Variant in d.vigil.walkers():
		Kit.free_body(s, v)
	Kit.run_for(s, 0.1)
	t.check(d.stalled and d.cart_at().is_equal_approx(at) and (s.banners as Array).has("THE CART STANDS"), "the three dead: the cart stands where the last fell")
	Kit.arrive(d.wren, at)
	Kit.run_for(s, RelicRunDirector.BOARD + 0.5)
	t.check(not d.aboard and d.halt < 0, "killing its people never opens the reliquary")
	Kit.run_for(s, RelicRunDirector.RELIEF_AFTER)
	t.check(d.hands.size() == 1 + RelicRunDirector.ESCORTS and (d.hands[0] as Person).anchor.is_equal_approx(at)
		and (s.banners as Array).has("NEW HANDS COME FROM THE TEMPLE"), "RELIEF_AFTER later new hands walk from the Temple to the cart")
	Kit.arrive(d.hands[0] as Person, at)
	Kit.run_for(s, 0.1)
	t.check(not d.stalled and d.vigil != null and d.vigil.active and d.vigil.route[0].is_equal_approx(d.route[d._leg_base]),
		"at the cart they take it on, along the rest of its route")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	d.halts_done[0] = true
	d.halts_done[1] = true
	d.vigil.leg = d.route.size() - 1
	Kit.arrive(d.vigil.bearer, d.route[d.route.size() - 1])
	Kit.run_for(s, 0.6)
	var main: Objective = (s.rules as Rules).objectives[1]
	t.check(d.kept and main.check(s.rules) == Objective.Status.FAILED and main.reason == "relic_kept", "the cart at the Citadel's gate with the relic: lost")
	Kit.done(s)
	var p := _world()
	Kit.free_body(p, (p.d as RelicRunDirector).wren)
	var pm: Objective = (p.rules as Rules).objectives[1]
	t.check(pm.check(p.rules) == Objective.Status.FAILED and pm.reason == "pip", "Pip dead or gone: lost at once")
	Kit.done(p)


static func _seen(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var a := d.escorts[0] as Person
	var b := d.escorts[1] as Person
	Kit.arrive(a, d.route[1])  # away from the Temple's door, where a report would be delivered at once
	Kit.arrive(b, a.ground_pos + Vector2(1.4, 0.0))
	Kit.free_body(s, a)
	Kit.run_for(s, 0.1)
	t.check(d.reports_started == 1 and d.reports[0].skip.is_valid(), "a death a Faithful sees sends him to the Temple, his relay passing over the fleeing")
	Kit.done(s)


static func _wardens(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var w: RelicRunDirector.Warden = d.wardens[2]
	var dead: Variant = w.man
	Kit.free_body(s, dead)
	Kit.run_for(s, RelicRunDirector.RELIEF_AFTER + 1.0)
	var p: Variant = w.man
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p)
		and (p as Person).anchor == w.post and w.relief and d.reliefs == 1, "RELIEF_AFTER after a warden falls, a Faithful watchman walks to his post")
	var o: RelicRunDirector.Warden = d.wardens[3]
	var op := o.man as Person
	Kit.arrive(op, o.post + Vector2(6.0, 0.0))
	op.mind = Person.Mind.CALM
	Kit.run_for(s, RelicRunDirector.RETURN_AFTER + 1.0)
	t.check(op.mind == Person.Mind.DUTY and op.anchor == o.post, "one off his post and calm walks back RETURN_AFTER after he left")
	Kit.done(s)


## The reliefs and new hands copy The Crown's Bread's _relieve (the controller's ruling): one chosen once the town is running is stopped
## from the flight first, and with no one to send the search backs off, tried again RELIEF_AFTER later.
static func _relief(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	Kit.evacuate(s)
	var w: RelicRunDirector.Warden = d.wardens[0]
	Kit.free_body(s, w.man)
	Kit.run_for(s, RelicRunDirector.RELIEF_AFTER + 1.0)
	var p: Variant = w.man
	t.check(w.relief and MissionDirector._alive(p) and (p as Person).mind == Person.Mind.DUTY and (p as Person).anchor == w.post,
		"a warden's relief chosen while the town runs is stopped from the flight and walks to the post")
	Kit.done(s)
	s = _world()
	d = s.d
	var at := _out_on_road(s, d)
	for v: Variant in d.vigil.walkers():
		Kit.free_body(s, v)
	Kit.evacuate(s)
	Kit.run_for(s, RelicRunDirector.RELIEF_AFTER + 0.5)
	var on := d.hands.size() == 1 + RelicRunDirector.ESCORTS
	for v: Variant in d.hands:
		on = on and MissionDirector._alive(v) and (v as Person).mind == Person.Mind.DUTY and (v as Person).anchor.distance_to(at) < 1.5
	t.check(on, "new hands chosen while the town runs are stopped from the flight and walk to the cart")
	Kit.done(s)
	s = _world()
	d = s.d
	for c in (s.crowd as Crowd).citizens:
		if c.profile != null and c.profile.faith == CitizenProfile.Faith.NONE:
			c.profile.faith = CitizenProfile.Faith.GRIEVING  # (set-up) no lay citizen left to send
	w = d.wardens[0]
	Kit.free_body(s, w.man)
	Kit.run_for(s, RelicRunDirector.RELIEF_AFTER + 1.0)
	t.check(d.reliefs == 0 and not MissionDirector._alive(w.man) and w.fallen < 2.0,
		"with no warden to send the search backs off, tried again RELIEF_AFTER later (%.1f)" % w.fallen)
	Kit.done(s)


static func _evacuate(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	d.halts_done[0] = true
	d.vigil.leg = 1
	d._board()
	var w: RelicRunDirector.Warden = d.wardens[2]
	var wp := w.man as Person
	wp.mind = Person.Mind.RECOVER
	var o: RelicRunDirector.Warden = d.wardens[3]
	var op := o.man as Person
	Kit.arrive(op, o.post + Vector2(6.0, 0.0))
	op.mind = Person.Mind.CALM
	var e := d.escorts[0] as Person
	e.whisper(e.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(s)
	t.check(wp.mind == Person.Mind.FLEE and op.mind == Person.Mind.FLEE and e._whisper_fled,
		"(set-up) the evacuation sends the recovering warden and the one off his post running, and owes the whispered escort a flight")
	Kit.run_for(s, 0.6)
	t.check(wp.mind == Person.Mind.DUTY and wp.anchor == w.post and not e._whisper_fled and d.aboard and d.wren.inside
		and (d.carter as Person).mind == Person.Mind.DUTY and d.vigil.active,
		"in the cart's second leg: the second checkpoint's warden holds his post, the escort's flight is ended, Pip stays hidden, the cart walks on")
	t.check(op.mind == Person.Mind.DUTY and op.anchor == o.post, "the warden off his post is sent back at the first look, not RETURN_AFTER later")
	Kit.done(s)
	var c := _world()
	var cd: RelicRunDirector = c.d
	cd._set_out_cart()
	cd.halts_done[0] = true
	cd._board()
	cd.lock_left = 0.0
	cd._take_relic()
	var pip := cd.wren
	pip.whisper(pip.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(c)
	t.check(cd.swapped and pip.mind == Person.Mind.WHISPERED and pip._whisper_fled,
		"(set-up) Pip carries the relic, whispered, and the evacuation owes him a flight")
	Kit.run_for(c, 0.6)
	pip._wake()
	Kit.run_for(c, 0.6)
	t.check(pip.mind == Person.Mind.DUTY and pip.anchor == cd.shrine and not pip._whisper_fled,
		"whispered with the relic when it begins, he takes up his walk to your believers' house, not the gates")
	Kit.done(c)


static func _tagged(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 4) == ["RELIC CART", "PIP - DO NOT KILL", "CHECKPOINT", "BELIEVERS' HOUSE"] and Kit.edged(d, "RELIC CART")
		and Kit.edged(d, "PIP - DO NOT KILL") and Kit.edged(d, "CHECKPOINT") and Kit.edged(d, "BELIEVERS' HOUSE") and labels.has("ESCORT")
		and labels.has("WARDEN") and not labels.has("CITADEL") and d.hint_phase() == "" and d.hud_line() == "The relic: in its cart",
		"the cart, Pip (DO NOT KILL), the first checkpoint, your believers' house, all pointed at; the escorts and wardens (%s)" % [labels])
	_at_halt(s, d, 0)
	t.check(Kit.labels(d)[0] == "RELIC CART - HALTED 50", "halted: its window's seconds (%s)" % Kit.labels(d)[0])
	d.halts_done[0] = true
	d.halt = -1
	d.vigil.leg = 1
	Kit.run_for(s, 0.1)
	t.check(d.hint_phase() == "last_halt" and not Kit.labels(d).has("CITADEL"),
		"the first halt passed and Pip not aboard: the next halt is the last (bring him there)")
	_at_halt(s, d, 1)
	t.check(Kit.labels(d).has("CITADEL") and Kit.edged(d, "CITADEL"), "from the second halt on, the Citadel")
	d.halts_done[1] = true
	d.halt = -1
	Kit.run_for(s, 0.1)
	t.check(d.hint_phase() == "citadel" and Kit.labels(d).has("CITADEL"),
		"the last halt passed: the citadel phase, with the CITADEL tag it names (the final review)")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("The relic cart at the Temple.") and String(tour[1][1]).begins_with("Pip.")
		and String(tour[2][1]).contains("bell"), "the tour: the cart, Pip, your believers' house (with the bell's warning)")
	t.check(ResultsScreen.ACT_TITLES.get("relic") == "THE RELIC IS OURS" and ResultsScreen.ACT_TITLES.get("relic_kept") == "THE RELIC REACHES THE CITADEL"
		and ResultsScreen.ACT_TITLES.get("pip") == "THE BOY IS DEAD", "its results under its own keys")
	Kit.done(s)


## The bell's warning (the controller's ruling): a seen death raising the Gaze shows it before the bell is called, a report running has
## its own line, and a called bellkeeper is tagged red and pointed at, with the bell's line.
static func _bell(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var a := d.escorts[0] as Person
	var b := d.escorts[1] as Person
	Kit.arrive(a, d.route[1])  # away from the Temple's door, where a report would be delivered at once
	Kit.arrive(b, a.ground_pos + Vector2(1.4, 0.0))
	Kit.free_body(s, a)
	Kit.run_for(s, 0.1)
	t.check(d.gaze.value > 0.0 and d.hint_phase() == "report" and Kit.labels(d).has("TO THE TEMPLE"), "a seen death: the report's runner, and its line")
	for r in d.reports:
		r.dead = true  # (set-up) the report ended
	Kit.run_for(s, 0.1)
	t.check(d.hint_phase() == "seen", "the Gaze risen by a seen death: the bell's warning, before the bell is called")
	Kit.run_for(s, RelicRunDirector.SEEN_SHOW)
	t.check(d.hint_phase() == "", "SEEN_SHOW later the warning gives way")
	var bell := (s.crowd as Crowd).bell
	bell.state = BellNetwork.State.CALLED
	t.check(d.hint_phase() == "bell" and (MissionDirector._alive(bell.keeper) == Kit.labels(d).has("BELLKEEPER"))
		and (not MissionDirector._alive(bell.keeper) or Kit.edged(d, "BELLKEEPER")), "the bell called: its line, the bellkeeper red and pointed at")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	var out: Array = d.vigil.walkers()
	for w: RelicRunDirector.Warden in d.wardens:
		out.append(w.man)
	for v: Variant in out:
		Kit.free_body(s, v)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.stalled and d.wardens_at(0).is_empty() and d.wardens_at(1).is_empty() and int(d.report().halts) == 0,
		"the cart's people and the wardens freed: the tags, hint and report bear it (review focus 4)")
	Kit.done(s)
