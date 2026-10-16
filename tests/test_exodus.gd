extends RefCounted
## v0.11 M6 Exodus (mission spec §2, ExodusDirector on the Escort type's Charge record): twelve believers in three households, each
## waiting inside its quiet, stone-tonight house until its time on the chain (0:15, then each at its time or CHAIN after the one before
## is done); a household follows its lamp in file, the lamp passing on; watchmen -- two patrols, two at each gate, two searchers per
## household sent 30 s after it comes out -- seize a believer on sight and march him to the Temple's door, where he is taken inside; a
## watcher marching one sees no other; the gates shut one by one and a shut gate lets no one out; ten out wins; too few left, or the
## last gate shut with fewer than ten out, loses at once. The town's evacuation passes everyone by and a believer the crowd carries out
## counts out; freed bodies are borne; seen deaths fill its own Gaze; the tags, hints, tour, titles, camera and numbers. v0.11 M6
## (Task 1's carried minors): the others keep stepping once the first charge is resolved, each with his own hold; a file whose lamp got
## out by a gate since shut re-routes to the next open one.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_inside(t)
	_come_out(t)
	_chain(t)
	_file(t)
	_lamp_passes(t)
	_rerouted(t)
	_others_step(t)
	_seized(t)
	_marching(t)
	_gates(t)
	_shut(t)
	_few(t)
	_won(t)
	_carried(t)
	_searchers(t)
	_relief(t)
	_stone(t)
	_gaze(t)
	_evacuated(t)
	_tagged(t)
	_phases(t)
	_heading(t)
	_freed(t)
	_lone_searchers(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.exodus())


## The live keepout (v0.11 M6, the controller's ruling): the kit's stack grown by the HUD's pad.
static func _keepout() -> Rect2:
	return Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))


## Every watcher moved well away and held there (v0.11 M6 tests): no one sees the believers.
static func _clear_watch(d: ExodusDirector) -> void:
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(40.0, 40.0))
	for h: ExodusDirector.Household in d.households:
		for v: Variant in h.searchers:
			if MissionDirector._alive(v) and not (v as Person).inside:
				Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(40.0, 40.0))


static func _setup(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var ok := d.charges.size() == ExodusDirector.BELIEVERS and d.households.size() == 3 and d.gates.size() == 3
	var people := {}
	var near := INF
	for i in 3:
		var h: ExodusDirector.Household = d.households[i]
		ok = ok and RuinWish.fits(h.house, "house") and h.members.size() == ExodusDirector.PER_HOUSE and h.house.damage_filter.is_valid() \
			and h.gate == i and not h.out
		for c: EscortDirector.Charge in h.members:
			var p := c.man as Person
			ok = ok and p.inside and p.mind == Person.Mind.DUTY and not p.soldier
			people[p] = true
		for v: Variant in h.searchers:
			ok = ok and (v as Person).inside and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN
			people[v] = true
		for b: PackedVector2Array in d.beats:
			for k in range(b.size() - 1):
				near = minf(near, Geometry2D.get_closest_point_to_segment(h.door, b[k], b[k + 1]).distance_to(h.door))
		for post: Vector2 in d.watch_posts:
			near = minf(near, post.distance_to(h.door))
	for v: Variant in d.watch:
		ok = ok and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN and (v as Person).mind == Person.Mind.DUTY
		people[v] = true
	for squad: Array in d.patrols:
		for v: Variant in squad:
			people[v] = true
	t.check(ok and d.watch.size() == 6 and people.size() == ExodusDirector.BELIEVERS + 6 + 4 + 6 and not d.watch_changes,
		"twelve believers, four inside each stone house; two at each gate; two patrols of two; two searchers per household inside the Temple; no guard change")
	t.check(near > ExodusDirector.QUIET - 0.01, "each household's door is quiet: no beat and no gate post within %.1f (nearest %.2f)" % [ExodusDirector.QUIET, near])
	for i in 3:
		var a: Vector2 = d.watch_posts[2 * i]
		var b: Vector2 = d.watch_posts[2 * i + 1]
		ok = ok and absf(a.distance_to(b) - ExodusDirector.POST_GAP) < 0.5
	t.check(ok, "each gate's two posts about %.1f apart" % ExodusDirector.POST_GAP)
	var ids := []
	for e in d.timeline.upcoming(6):
		ids.append(e.id)
	t.check(ids == ["out_0", "out_1", "shut_0", "out_2", "shut_1", "shut_2"], "the strip: the households and the shuttings from 0:00 (%s)" % [ids])
	var cam := ExodusDirector.CAMERA_AT
	var zone := _keepout()
	var clear := Kit.clear_of_stack(d.temple_door, cam, zone)
	for h: ExodusDirector.Household in d.households:
		clear = clear and Kit.clear_of_stack(h.door, cam, zone)
	for g: ExodusDirector.Gate in d.gates:
		clear = clear and Kit.clear_of_stack(g.mouth, cam, zone)
	t.check(clear, "the camera keeps the three doors, the three gates and the Temple's door (or their arrows) clear of the padded stack")
	var m := MissionBook.exodus()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	var main := m.objectives()[0] as EscortObjective
	t.check(m.tier == 5 and is_equal_approx(m.clock, 420.0) and reasons == ["exodus", "gaze", "dawn"] and main.need == ExodusDirector.NEED
		and Array(m.default_loadout) == ["whisper", "doom", "discord", "wisp"] and d.gaze != null and not (d.gaze is Descent.TierGaze)
		and MissionBook.tier_missions().any(func(x: MissionDef) -> bool: return x.id == MissionBook.EXODUS),
		"the mission: Tier 5's numbers; ten out, the Gaze, dawn; its own Gaze; on the board's list (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := true
	for c in d.charges:
		held = held and (c.man as Person).inside
	for v: Variant in d.watch:
		held = held and (v as Person).mind == Person.Mind.DUTY
	t.check(held, "the town's regroup and evacuation pass the gates' watch by; the households stay inside (review focus 2)")
	Kit.done(s)


static func _inside(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var h: ExodusDirector.Household = d.households[0]
	var p := (h.members[0] as EscortDirector.Charge).man as Person
	var reach := (s.field as EnemyField).in_radius(h.house.center(), 3.0)
	h.house.damage(500.0, h.house.center(), &"smite")
	t.check(MissionDirector._alive(p) and p.inside and not reach.has(p) and not h.house.destroyed,
		"a household inside is out of every power's reach (out of the field), its house stone tonight")
	Kit.done(s)


static func _come_out(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	Kit.run_for(s, float(ExodusDirector.OUT_AT[0]) + DT)
	var h: ExodusDirector.Household = d.households[0]
	var out := true
	for c: EscortDirector.Charge in h.members:
		out = out and not (c.man as Person).inside and (c.man as Person).mind == Person.Mind.DUTY
	t.check(h.out and out and (s.banners as Array).has("THE WEST HOUSEHOLD COMES OUT") and d.lamp(0) == h.members[0]
		and not (d.households[1] as ExodusDirector.Household).out, "at %s the west household comes out and holds at its door; its first carries the lamp" % UiTheme.clock(float(ExodusDirector.OUT_AT[0])))
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	d._come_out(0)
	Kit.run_for(s, 1.0)
	for c: EscortDirector.Charge in (d.households[0] as ExodusDirector.Household).members:
		c.escaped = true
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var left := d.timeline.seconds_to("out_1")
	t.check((d.households[0] as ExodusDirector.Household).done and absf(left - ExodusDirector.CHAIN) < 1.0,
		"a household done (each out, taken or dead): the strip shows the next at the chain (%.1f s)" % left)
	Kit.run_for(s, ExodusDirector.CHAIN + DT)
	t.check((d.households[1] as ExodusDirector.Household).out, "and it comes out %d s later, long before its own time" % roundi(ExodusDirector.CHAIN))
	Kit.done(s)


static func _file(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var lead := d.lamp(0)
	var lp := lead.man as Person
	for k in 6:
		Kit.arrive(lp, h.door + Vector2(0.0, 0.6 * float(k + 1)))
		Kit.run_for(s, ExodusDirector.TICK + DT)
	var follower: EscortDirector.Charge = h.members[1]
	var fp := follower.man as Person
	var spot := d._file_spot(follower)
	t.check(spot != Vector2.INF and fp.mind == Person.Mind.DUTY and fp.anchor.distance_to(spot) < 0.8
		and spot.distance_to(lp.ground_pos) <= 2.0 * ExodusDirector.FOLLOW_GAP + 0.3, "a follower in file walks on duty to his place behind the lamp")
	fp.whisper(fp.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(d._file_spot(follower) == Vector2.INF, "whispered on his own, he leaves the file")
	fp._wake()
	Kit.arrive(fp, lp.ground_pos + Vector2(6.0, 0.0))
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(d._file_spot(follower) == Vector2.INF and fp.mind == Person.Mind.DUTY, "back on his feet away from his lamp, he holds where he was left")
	Kit.arrive(fp, lp.ground_pos + Vector2(1.0, 0.0))
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(d._file_spot(follower) != Vector2.INF, "within %d of his lamp he rejoins the file" % roundi(ExodusDirector.REJOIN))
	Kit.done(s)


static func _lamp_passes(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var first: EscortDirector.Charge = h.members[0]
	Kit.free_body(s, first.man)
	t.check(d.lamp(0) == h.members[1], "the lamp passes to the next when its bearer dies")
	var second: EscortDirector.Charge = h.members[1]
	Kit.arrive(second.man as Person, (d.gates[0] as ExodusDirector.Gate).way_out)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(second.escaped and d.lamp(0) == h.members[2] and h.out_to.distance_to((d.gates[0] as ExodusDirector.Gate).way_out) < 1.0
		and d._file_spot(h.members[2]) == h.out_to, "when the bearer gets out, the lamp passes on and the file walks on to his way out")
	Kit.done(s)


## The controller's ruling (v0.11 M6): a file walking on to a way out whose gate has since shut re-routes to the next open gate's.
static func _rerouted(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var lead: EscortDirector.Charge = h.members[0]
	var postern: ExodusDirector.Gate = d.gates[0]
	Kit.arrive(lead.man as Person, postern.way_out)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var was := h.out_to
	d._shut(0)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var next := d._open_exit_near(postern.way_out)
	var follower: EscortDirector.Charge = h.members[1]
	t.check(lead.escaped and was.distance_to(postern.way_out) < 1.0 and next != Vector2.INF and h.out_to == next
		and d._file_spot(follower) == next and (follower.man as Person).anchor.distance_to(next) < 0.8,
		"the postern shut behind its lamp: the file walks on to the next open gate's way out, not to a shut gate")
	Kit.done(s)


## Task 1's carried minor (v0.11 M6): the first charge resolved first, the others keep stepping, each with his own hold.
static func _others_step(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	d._come_out(1)
	var first: EscortDirector.Charge = d.charges[0]
	var first_hold := first.hold_at
	first.escaped = true
	var east: EscortDirector.Charge = (d.households[1] as ExodusDirector.Household).members[0]
	var ep := east.man as Person
	var to := ep.ground_pos + Vector2(1.5, 0.0)
	Kit.arrive(ep, to)
	ep._recover(1.0)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var south: EscortDirector.Charge = (d.households[2] as ExodusDirector.Household).members[0]
	t.check(first.hold_at == first_hold and east.hold_at == to and ep.mind == Person.Mind.DUTY and ep.anchor == to
		and south.hold_at == (d.households[2] as ExodusDirector.Household).door,
		"the first charge out, the east lamp back on his feet still holds where he stands; every charge keeps his own hold")
	Kit.done(s)


static func _seized(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var c: EscortDirector.Charge = (d.households[0] as ExodusDirector.Household).members[0]
	var w := d.watch[0]
	Kit.arrive(w, (c.man as Person).ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(c.held and c.seizer == w and (s.banners as Array).has("A BELIEVER IS TAKEN") and d.hint_phase() == "caught"
		and Kit.labels(d).has("TAKEN TO THE TEMPLE") and Kit.edged(d, "TAKEN TO THE TEMPLE") and Kit.edged(d, "TAKING HIM IN"),
		"a watchman within sight seizes a believer: TAKEN TO THE TEMPLE and TAKING HIM IN, pointed at")
	Kit.arrive(w, d.return_to)
	Kit.arrive(c.man as Person, d.return_to + Vector2(0.3, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(c.taken and (c.man as Person).inside and (s.banners as Array).has("THE INQUISITION TAKES A BELIEVER") and d.left_count() == 11,
		"marched to the Temple's door he is taken inside, lost to the count")
	var march := INF
	for h: ExodusDirector.Household in d.households:
		march = minf(march, h.door.distance_to(d.temple_door))
	t.check(march >= 12.0, "every household's door is 12 units or more from the Temple's door: a march to answer (%.1f)" % march)
	Kit.done(s)


static func _marching(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var a: EscortDirector.Charge = h.members[0]
	var b: EscortDirector.Charge = h.members[1]
	var w := d.watch[0]
	Kit.arrive(b.man as Person, (a.man as Person).ground_pos + Vector2(-8.0, 0.0))
	Kit.arrive(w, (a.man as Person).ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	Kit.arrive(b.man as Person, w.ground_pos + Vector2(0.0, 1.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(a.held and not b.held and d.seizures == 1, "a watcher marching one believer seizes no other")
	Kit.done(s)


static func _gates(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var c: EscortDirector.Charge = h.members[1]
	Kit.arrive(c.man as Person, (d.gates[1] as ExodusDirector.Gate).way_out)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(c.escaped and d.out_count() == 1, "any open gate's way out counts, not only the household's own")
	Kit.done(s)


static func _shut(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	_clear_watch(d)
	d._come_out(0)
	d._shut(0)
	var g: ExodusDirector.Gate = d.gates[0]
	var c: EscortDirector.Charge = (d.households[0] as ExodusDirector.Household).members[1]
	Kit.arrive(c.man as Person, g.way_out)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(g.shut and not c.escaped and d.lost_reason() == "" and Kit.labels(d).has("POSTERN - SHUT"),
		"the postern shut: a believer at its way out does not get out; its tag reads SHUT")
	for gate: ExodusDirector.Gate in d.gates:
		d._shut(d.gates.find(gate))
	t.check(d.lost_reason() == "gates_shut" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "gates_shut",
		"the last gate shut with fewer than ten out: lost through the director's reason (THE GATES ARE SHUT)")
	Kit.done(s)


static func _few(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	d._come_out(0)
	d._come_out(1)
	Kit.free_body(s, d.charges[0].man)
	Kit.free_body(s, d.charges[5].man)
	t.check(d.lost_reason() == "" and d.left_count() == 10 and main.check(s.rules) == Objective.Status.PENDING
		and main.hud_text(s.rules) == "Lead them out 0 / 10, 0 to spare", "two lost: none to spare, still open (%s)" % main.hud_text(s.rules))
	d.charges[9].taken = true
	t.check(d.lost_reason() == "exodus_few" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "exodus_few",
		"the third: out plus left below ten, lost at once (TOO FEW ARE LEFT)")
	Kit.done(s)


static func _won(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	for k in ExodusDirector.NEED:
		d.charges[k].escaped = true
	t.check(main.check(s.rules) == Objective.Status.DONE and main.reason == "exodus" and d.hint_phase() == "" and d.tags().is_empty(),
		"the tenth out: the faithful are out")
	Kit.done(s)


static func _carried(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	d._come_out(0)
	var c: EscortDirector.Charge = (d.households[0] as ExodusDirector.Household).members[2]
	(s.crowd as Crowd).escaped.emit(c.man)
	t.check(c.escaped and d.out_count() == 1, "the crowd carrying a believer out counts him out at once (review focus 4)")
	Kit.done(s)


static func _searchers(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	Kit.run_for(s, ExodusDirector.HUNT_AFTER + DT)
	var out := h.sent
	var lead := (d.lamp(0).man as Person).ground_pos
	for v: Variant in h.searchers:
		var p := v as Person
		out = out and not p.inside and p.mind == Person.Mind.DUTY and p.anchor.distance_to(lead) < 1.5
	t.check(ids.has("hunt_0") and out and (s.banners as Array).has("THE TEMPLE SENDS SEARCHERS") and Kit.edged(d, "SEARCHER"),
		"%d s after the household comes out its two searchers leave the Temple for its lamp, pointed at" % roundi(ExodusDirector.HUNT_AFTER))
	for c: EscortDirector.Charge in h.members:
		c.escaped = true
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var home := true
	for v: Variant in h.searchers:
		home = home and (v as Person).mind != Person.Mind.DUTY
	t.check(h.done and home and not d._watchers().has(h.searchers[0]), "the household done sends its searchers home: they watch no more")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var dead: Variant = d.watch[1]
	var post := d._walkable(d.watch_posts[1])
	Kit.free_body(s, dead)
	Kit.run_for(s, ExodusDirector.RELIEF_AFTER + 2.0 * ExodusDirector.TICK + DT)
	var p: Variant = d.watch[1]
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and (p as Person).anchor == post
		and d.reliefs == 1 and (s.banners as Array).has("A NEW WATCHMAN COMES FROM THE TEMPLE"),
		"a fallen gate watchman is replaced %d s later from the Temple's door" % roundi(ExodusDirector.RELIEF_AFTER))
	var w := d.watch[0]
	w.whisper(w.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	w._wake()
	Kit.run_for(s, 2.0)
	var waited := w.mind != Person.Mind.DUTY
	Kit.run_for(s, ExodusDirector.RETURN_AFTER)
	t.check(waited and w.mind == Person.Mind.DUTY and w.anchor == d._walkable(d.watch_posts[0]),
		"a whispered watchman walks back %d s after he is calm, not before" % roundi(ExodusDirector.RETURN_AFTER))
	Kit.done(s)


static func _stone(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var house: Structure = (d.households[0] as ExodusDirector.Household).house
	(s.crowd as Crowd).fires.ignite(house, 1.0)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(not (s.crowd as Crowd).fires.is_burning(house) and is_equal_approx(house.hp, house.max_hp), "a household's house only shakes and its fire goes out")
	var own := d._own_filters.duplicate()
	d.teardown()
	t.check(house.damage_filter == own[0], "teardown gives each house its own filter back")
	Kit.done(s)


## The controller's ruling (v0.11 M6): a seen death fills Exodus's own Gaze by 10, and a full Gaze loses the night.
static func _gaze(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var crowd: Crowd = s.crowd
	var victim: Person = null
	var witness: Person = null
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and not d._in_use(d.charge).has(p):
			if victim == null:
				victim = p
			elif witness == null:
				witness = p
				break
	Kit.arrive(witness, victim.ground_pos + Vector2(1.0, 0.0))
	Kit.free_body(s, victim)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var once := d.gaze.value
	var gaze_o: Objective = (s.rules as Rules).objectives[1]
	d.gaze.value = GazeMeter.FULL - GazeMeter.SEEN_DEATH
	var next: Person = null
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and p != witness and not d._in_use(d.charge).has(p):
			next = p
			break
	Kit.arrive(next, witness.ground_pos + Vector2(-1.0, 0.0))
	Kit.free_body(s, next)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(is_equal_approx(once, GazeMeter.SEEN_DEATH) and d.gaze.is_full() and gaze_o.check(s.rules) == Objective.Status.FAILED
		and gaze_o.reason == "gaze", "a seen death adds %d to its own Gaze (%.0f); the Gaze full loses the night (THE LANTERN LOOKS)" % [roundi(GazeMeter.SEEN_DEATH), once])
	Kit.done(s)


static func _evacuated(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	d._come_out(1)
	Kit.run_for(s, 1.0)
	var lead := d.lamp(1).man as Person
	lead.whisper(lead.ground_pos + Vector2(2.0, 0.0), MindWhisperFx.LINGER)
	var w := d.watch[2]
	w._recover(1.0)
	Kit.evacuate(s)
	Kit.run_for(s, 2.0 * ExodusDirector.TICK + DT)
	var none_fled := true
	for c: EscortDirector.Charge in (d.households[1] as ExodusDirector.Household).members:
		none_fled = none_fled and (c.man as Person).mind != Person.Mind.FLEE
	var south_in := true
	for c: EscortDirector.Charge in (d.households[2] as ExodusDirector.Household).members:
		south_in = south_in and (c.man as Person).inside
	t.check(none_fled and lead.mind == Person.Mind.WHISPERED and not lead._whisper_fled and w.mind == Person.Mind.DUTY
		and w.anchor == d._walkable(d.watch_posts[2]) and south_in,
		"the evacuation: the east household walks on, none flees; the recovering watchman walks back at once; the south household stays inside")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var labels := Kit.labels(d)
	var waiting := "HOUSEHOLD - OUT BY %s" % UiTheme.clock(float(ExodusDirector.OUT_AT[0]))
	t.check(labels.has(waiting) and Kit.edged(d, waiting) and labels.has("POSTERN - WATCHED") and Kit.edged(d, "POSTERN - WATCHED")
		and labels.has("PATROL") and d.hint_phase() == "", "at the start: each household's time over its door, the gates watched, pointed at (%s)" % [labels])
	d._come_out(0)
	labels = Kit.labels(d)
	t.check(labels[0] == "LAMP - DO NOT KILL" and Kit.edged(d, "LAMP - DO NOT KILL"), "the lamp, steel blue, DO NOT KILL, pointed at")
	for v: Variant in d.watch.slice(0, 2):
		Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(40.0, 40.0))
	t.check(Kit.labels(d).has("POSTERN - CLEAR"), "its watch gone, the postern reads clear")
	var tour := d.tour()
	var fits := true
	for stop: Array in tour:
		fits = fits and UiTheme.width(String(stop[1]), UiTheme.SIZE_BODY) + 16.0 <= Kit.VIEW.x
	t.check(tour.size() == 3 and String(tour[0][1]) == "The west household hides here. At %s, whisper its lamp to the postern; the rest follow." % UiTheme.clock(float(ExodusDirector.OUT_AT[0]))
		and String(tour[1][1]) == "Gates shut: postern %s, Side Gate %s, Main Gate %s (lost unless ten are out)." % [
			UiTheme.clock(float(ExodusDirector.SHUT_AT[0])), UiTheme.clock(float(ExodusDirector.SHUT_AT[1])), UiTheme.clock(float(ExodusDirector.SHUT_AT[2]))]
		and String(tour[2][1]) == "The Temple. Inquisitors take any believer they catch here. Ten must get out." and fits,
		"the tour, each line within the caption's plate; the last gate's shutting loses unless ten are out (fix round 1)")
	t.check(ResultsScreen.ACT_TITLES.get("exodus") == "THE FAITHFUL ARE OUT" and ResultsScreen.ACT_TITLES.get("exodus_few") == "TOO FEW ARE LEFT"
		and ResultsScreen.ACT_TITLES.get("gates_shut") == "THE GATES ARE SHUT" and MissionHints.line("exodus", "waiting").contains(MissionHints.SECONDS),
		"its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	d._come_out(0)
	d._send(0)
	Kit.run_for(s, 0.2)
	for c: EscortDirector.Charge in (d.households[0] as ExodusDirector.Household).members.slice(0, 2):
		Kit.free_body(s, c.man)
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.free_body(s, v)
	d.tags()
	d.hint_phase()
	d.hud_line()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.left_count() == 10 and d.lost_reason() == "", "two believers and every watcher freed: borne, the count right (review focus 4)")
	Kit.done(s)


## Task 1's carried minor (v0.11 M6): the Escort type's single-charge searchers do nothing once their charge is gone (The Lost Lamb).
static func _lone_searchers(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb())
	var d: EscortDirector = s.d
	var h: Person = d._free_soldiers(d.return_to, 1, d._in_use(d.charge))[0]
	d.hunters.assign([h])
	var was := h.anchor
	Kit.free_body(s, d.charge)
	d._step_hunters()
	t.check(d.charge == null and h.anchor == was, "the Escort type's searchers stand once its one charge is gone")
	Kit.done(s)


## Fix round 1 (v0.11 M6): each hint phase -- hounds, shut, gate, waiting -- with its seconds, and their order (caught, hounds, shut,
## gate; waiting only between households).
static func _phases(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var postern: ExodusDirector.Gate = d.gates[0]
	var lp := d.lamp(0).man as Person
	Kit.arrive(lp, postern.mouth + Vector2(0.0, -4.0))
	t.check(d.gate_watched(0) and d.hint_phase() == "gate" and d.hint_seconds() == 0.0,
		"the lamp within %d of the gate it heads for, watched: gate (no seconds)" % roundi(EscortDirector.NEAR_GATE))
	d._shut(0)
	t.check(d.hint_phase() == "shut" and d.hint_seconds() == 0.0, "that gate shut: shut, before gate (no seconds)")
	d._send(0)
	var hound := h.searchers[0] as Person
	Kit.arrive(hound, lp.ground_pos + Vector2(ExodusDirector.HOUNDS_NEAR - 1.0, 0.0))
	t.check(d.searchers_out(0).has(hound) and d.hint_phase() == "hounds" and d.hint_seconds() == 0.0,
		"a searcher within %d of a believer: hounds, before shut (no seconds)" % roundi(ExodusDirector.HOUNDS_NEAR))
	var w := d.watch[2]
	Kit.arrive(w, lp.ground_pos + Vector2(0.0, 1.0))
	d._seize(d.lamp(0), w)
	t.check(d.hint_phase() == "caught" and d.hint_seconds() == 0.0, "a believer seized: caught, before hounds")
	Kit.done(s)
	s = _world()
	d = s.d
	d._come_out(0)
	for c: EscortDirector.Charge in (d.households[0] as ExodusDirector.Household).members:
		c.escaped = true
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(d.current() == -1 and d.upcoming() == 1 and d.hint_phase() == "waiting" and absf(d.hint_seconds() - d.due_in(1)) < 0.01
		and absf(d.hint_seconds() - ExodusDirector.CHAIN) < 1.0 and MissionHints.filled(MissionHints.line("exodus", "waiting"), d.hint_seconds()).contains("in 25 s"),
		"a household done and the next inside: waiting, counting down to it (%.1f s)" % d.hint_seconds())
	Kit.done(s)


## Fix round 1 (v0.11 M6): the shut phase keys to the gate the household heads for, not the one it was bound for.
static func _heading(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var lp := d.lamp(0).man as Person
	var main_gate: ExodusDirector.Gate = d.gates[2]
	lp.whisper(main_gate.mouth, MindWhisperFx.LINGER)
	d._shut(0)
	t.check(d.heading(0) == 2 and d.hint_phase() == "", "the west lamp whispered toward the Main Gate: its own postern shut gives no false shut")
	d._shut(2)
	t.check(d.lost_reason() == "" and d.hint_phase() == "shut", "the Main Gate it heads for shut: shut")
	Kit.done(s)
