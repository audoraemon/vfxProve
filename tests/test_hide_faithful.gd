extends RefCounted
## God P5 Task 4 (plan Task 4, MS §2): Hunt 1, Hide the faithful (HideFaithfulDirector on ExodusDirector): two households of three believers in
## quiet stone houses who walk themselves out of the walls when their time comes; a soldiers' watch (four at the gates, two patrols of two
## walking 1.8 apart); two inquisitors who search six listed houses in order and trail a household that is out when they reach its house; a
## household never found inside (SLIP); five of six out wins, two taken or killed loses. The world is test_lost_lamb's kind: a town with its
## crowd and a Rules, run in 0.05 s steps (people do not walk in it, so the tests read goals and anchors and move people with Kit.arrive()).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const Book := preload("res://tests/test_hunt_book.gd")


static func run(t) -> void:
	_tuned(t)
	_names_free(t)
	_setup(t)
	_frame(t)
	_walk_out(t)
	_out_of_walls(t)
	_sight_first(t)
	_slip(t)
	_chain(t)
	_trail(t)
	_relief(t)
	_pair_apart(t)
	_strip_rows(t)
	_seize_free(t)
	_lose_two(t)
	_win_beats_loss(t)
	_no_luck(t)
	_evacuation(t)
	_wishes(t)


static func _world() -> Dictionary:
	return Kit.world(HuntBook.def(MissionBook.HIDE_FAITHFUL))


## The live keepout: the kit's stack grown by the HUD's pad.
static func _keepout() -> Rect2:
	return Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))


## Everyone who watches moved well away (the gates' watch, the patrols, the inquisitors): no one sees the believers.
static func _clear_watch(d: HideFaithfulDirector) -> void:
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))


## The believers' tags, labelled.
static func _labels(d: HideFaithfulDirector) -> Array:
	return Kit.labels(d)


# --- The numbers ---

static func _tuned(t) -> void:
	var d := HideFaithfulDirector.new()
	d._tune()
	t.check(d.tune_need == HideFaithfulDirector.HF_NEED and d.tune_per_house == 3 and d.tune_hounds == 0 and d.tune_shut_at.is_empty()
		and is_equal_approx(d.tune_believer_pace, HideFaithfulDirector.HF_BELIEVER_PACE) and is_equal_approx(d.tune_chain, HideFaithfulDirector.HF_CHAIN)
		and d.tune_out_at == HideFaithfulDirector.HF_OUT_AT and d.tune_beats == HideFaithfulDirector.HF_BEATS and d.patrol_size == 2
		and is_equal_approx(d.tune_quiet, HideFaithfulDirector.HF_QUIET) and d.tune_gate_watch == 2,
		"setup puts the Hunt's numbers into the base's tune_ vars: 3 a household, 5 needed, no gate shuts, no hounds (%s %s)" % [d.tune_need, d.tune_out_at])
	t.check(ExodusDirector.NEED == 10 and ExodusDirector.PER_HOUSE == 4 and ExodusDirector.SHUT_AT.size() == 3 and EscortDirector.SIGHT == HideFaithfulDirector.HF_SIGHT,
		"the base's own consts stand (Exodus: 10 of 12 in 4s, three gates), and the sight is the Escort type's 2.5")


## A subclass never redeclares a parent's const name (Ruling C2: a parse error); a source scan holds it to its own HF_ prefix.
static func _names_free(t) -> void:
	var own: Dictionary = (load("res://src/game/mission/hide_faithful_director.gd") as GDScript).get_script_constant_map()
	var clash := []
	var bad_prefix := []
	var base: GDScript = load("res://src/game/mission/exodus_director.gd")
	var theirs := {}
	while base != null:
		for k: Variant in base.get_script_constant_map():
			theirs[k] = true
		base = base.get_base_script()
	for k: Variant in own:
		if theirs.has(k):
			clash.append(k)
		if not String(k).begins_with("HF_"):
			bad_prefix.append(k)
	t.check(clash.is_empty() and bad_prefix.is_empty() and own.size() > 20, "every const is the Hunt's own and prefixed HF_ (clashes %s, unprefixed %s, %d consts)" % [clash, bad_prefix, own.size()])


# --- The night's start ---

static func _setup(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var ok := d.charges.size() == HideFaithfulDirector.HF_BELIEVERS and d.households.size() == 2 and d.gates.size() == 2
	var near := INF
	var people := {}
	for i in 2:
		var h: ExodusDirector.Household = d.households[i]
		ok = ok and RuinWish.fits(h.house, "house") and h.members.size() == 3 and h.house.damage_filter.is_valid() and h.gate == i and not h.out \
			and h.searchers.is_empty()
		for c: EscortDirector.Charge in h.members:
			var p := c.man as Person
			ok = ok and p.inside and p.mind == Person.Mind.DUTY and not p.soldier
			people[p] = true
		for b: PackedVector2Array in d.beats:
			for k in range(b.size() - 1):
				near = minf(near, Geometry2D.get_closest_point_to_segment(h.door, b[k], b[k + 1]).distance_to(h.door))
		for post: Vector2 in d.watch_posts:
			near = minf(near, post.distance_to(h.door))
	t.check(ok and (d.households[0] as ExodusDirector.Household).house != (d.households[1] as ExodusDirector.Household).house,
		"six believers, three inside each of two stone houses, no hound inside the Temple (%s)" % [d.charges.size()])
	t.check(near > HideFaithfulDirector.HF_QUIET - 0.01, "each household's door is quiet: no beat and no post within %.1f (nearest %.2f)" % [HideFaithfulDirector.HF_QUIET, near])
	var opposition: Array[Person] = []
	for v: Variant in d._watchers():
		opposition.append(v as Person)
		people[v] = true
	var soldiers := true
	for v: Variant in d.watch:
		soldiers = soldiers and (v as Person).soldier and (v as Person).mind == Person.Mind.POST
	for squad: Array in d.patrols:
		for v: Variant in squad:
			soldiers = soldiers and (v as Person).soldier
	for v: Variant in d.inquisitors:
		soldiers = soldiers and not (v as Person).soldier and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN
	var apart := INF
	for a in opposition.size():
		for b in range(a + 1, opposition.size()):
			apart = minf(apart, opposition[a].ground_pos.distance_to(opposition[b].ground_pos))
	t.check(d.watch.size() == 4 and d.patrols.size() == 2 and d.inquisitors.size() == 2 and opposition.size() == 10 and soldiers and not d.watch_changes,
		"four soldiers at the gates, two patrols of two soldiers, two lay inquisitors; no guard change (%d watchers)" % opposition.size())
	t.check(apart > 2.0 * SilentDoom.RADIUS, "the opposition stands more than %.1f apart at the start (nearest %.2f)" % [2.0 * SilentDoom.RADIUS, apart])
	var posts_ok := true
	for i in 4:
		posts_ok = posts_ok and (d.watch[i] as Person).ground_pos.distance_to(d.watch_posts[i]) < 0.5
	var gaps := []
	for squad: Array in d.patrols:
		gaps.append(snappedf((squad[0] as Person).ground_pos.distance_to((squad[1] as Person).ground_pos), 0.1))
	t.check(posts_ok and absf(float(gaps[0]) - HideFaithfulDirector.HF_PATROL_GAP) < 0.3 and absf(float(gaps[1]) - HideFaithfulDirector.HF_PATROL_GAP) < 0.3
		and absf((d.watch_posts[0] as Vector2).distance_to(d.watch_posts[1]) - 2.2) < 0.4,
		"each watchman at his post; each patrol's two %.1f apart, not the Escort type's 1.0 (%s)" % [HideFaithfulDirector.HF_PATROL_GAP, gaps])
	var list := d.search_list()
	var doors := []
	for e: Dictionary in d._search:
		doors.append(e.door)
	t.check(list.size() == HideFaithfulDirector.HF_SEARCH_LIST and list[1] == (d.households[0] as ExodusDirector.Household).house
		and list[5] == (d.households[1] as ExodusDirector.Household).house and not list.slice(0, 1).has(list[1]) and list.size() == list.duplicate().size(),
		"the search lists six houses: four empty dwellings and the households', the first household's second, the second's last (%d)" % list.size())
	var empties_ok := true
	for k in [0, 2, 3, 4]:
		empties_ok = empties_ok and RuinWish.fits(list[k], "house") and list[k] != (d.households[0] as ExodusDirector.Household).house \
			and list[k] != (d.households[1] as ExodusDirector.Household).house
	t.check(empties_ok, "the other four are dwellings, none a household's")
	var eta0 := d.search_eta(1)
	t.check(eta0 > float(HideFaithfulDirector.HF_OUT_AT[0]) + HideFaithfulDirector.HF_SLIP - 0.5 and d.search_eta(5) > d.search_eta(1) and d.search_eta(0) < d.search_eta(1),
		"at 0:00 the search reaches the first household's house (%.0f s) after the household is out and slipped clear, and the second's last (%.0f s)" % [eta0, d.search_eta(5)])
	var labels := _labels(d)
	var searches := labels.filter(func(l: Variant) -> bool: return String(l).begins_with("SEARCH IN "))
	var waiting := labels.filter(func(l: Variant) -> bool: return String(l).begins_with("OUT IN "))
	t.check(searches.size() == 6 and waiting.size() == 2 and labels.has("OUT IN %s" % UiTheme.clock(float(HideFaithfulDirector.HF_OUT_AT[0]))),
		"a SEARCH IN tag over each of the six listed houses and an OUT IN over each waiting household (%s)" % [labels])
	var banners: Array = s.banners
	t.check(banners == ["HIDE THE FAITHFUL"], "the opening banner (%s)" % [banners])
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["out_0", "out_1"], "the strip lists the two households and no searchers' row (%s)" % [ids])
	Kit.done(s)


static func _frame(t) -> void:
	var m := HuntBook.def(MissionBook.HIDE_FAITHFUL)
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	var main := m.objectives()[0] as EscortObjective
	t.check(m.tier == 1 and m.director == HideFaithfulDirector and reasons == ["faithful_out", "dawn"] and main.need == 5 and m.lantern == LanternWatch.KIND_WATCH
		and Array(m.default_loadout) == ["whisper", "doom", "discord"] and m.mission_tags.has(TierBook.UNAWARE_TAG),
		"the frame: Tier 1, five out then dawn, a watch for the bell, the Unaware town (%s)" % [reasons])
	t.check(m.goal == "Lead five of your six believers out of the walls before the Inquisition takes them" and m.goal_label == "The faithful are hidden"
		and m.lose == "Two believers are taken or killed, or dawn comes", "the plate's copy is the spec's")
	for key in ["hide_faithful", "hide_faithful.trail", "hide_faithful.seized"]:
		t.check(MissionHints.line("hide_faithful", key.trim_prefix("hide_faithful").trim_prefix(".")) != "", "the hint %s has its line" % key)
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var cam := HideFaithfulDirector.HF_CAMERA_AT
	var zone := _keepout()
	var clear := m.camera_at == cam and Kit.clear_of_stack(d.temple_door, cam, zone)
	for h: ExodusDirector.Household in d.households:
		clear = clear and Kit.clear_of_stack(h.door, cam, zone)
	for g: ExodusDirector.Gate in d.gates:
		clear = clear and Kit.clear_of_stack(g.mouth, cam, zone)
	t.check(clear, "the camera keeps the two doors, the two gates and the Temple's door (or their arrows) clear of the padded stack")
	var tour := d.tour()
	var fits := true
	for stop: Array in tour:
		fits = fits and UiTheme.width(String(stop[1]), UiTheme.SIZE_BODY) + 16.0 <= Kit.VIEW.x
	t.check(tour.size() == 3 and fits, "the tour: the household, the gates, the Temple; each line within the caption's plate (%d stops)" % tour.size())
	Kit.done(s)


# --- The self-walk and out of the walls ---

static func _walk_out(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	d._come_out(1)
	Kit.run_for(s, 2.0 * EscortDirector.TICK)
	var gate0 := (d.gates[0] as ExodusDirector.Gate).way_out
	var gate1 := (d.gates[1] as ExodusDirector.Gate).way_out
	var lead0 := d.lamp(0)
	var lead1 := d.lamp(1)
	var lp := lead0.man as Person
	t.check(lp.mind == Person.Mind.DUTY and lp.anchor.distance_to(gate0) < 0.5 and (lead1.man as Person).anchor.distance_to(gate1) < 0.5,
		"out, each lamp walks itself to its gate's way out: the north-west to the Main Gate, the north to the Side Gate")
	var past_fear := true
	var followers_hold := true
	for c: EscortDirector.Charge in (d.households[0] as ExodusDirector.Household).members:
		var p := c.man as Person
		past_fear = past_fear and p.fearless_left > 0.0 and p.pace < 0.6
		if c != lead0:
			followers_hold = followers_hold and p.mind == Person.Mind.DUTY and p.anchor.distance_to(lp.ground_pos) < ExodusDirector.FOLLOW_REACH
	t.check(past_fear and followers_hold, "past fear, at the believers' slow pace, the followers on duty at their places behind the lamp")
	# A Mind Whisper sends the lamp where the god chooses; after its linger he walks on to the nearest way out from there.
	var away := lp.ground_pos + Vector2(2.0, 1.0)
	lp.whisper(away, MindWhisperFx.LINGER)
	Kit.run_for(s, 2.0 * EscortDirector.TICK)
	var held_off := lp.mind == Person.Mind.WHISPERED
	var anchor_then := lp.anchor
	lp._wake()
	Kit.arrive(lp, away)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(held_off and lp.mind == Person.Mind.DUTY and lp.anchor.distance_to(gate0) < 0.5 and anchor_then.distance_to(gate0) > 0.5,
		"a whispered lamp is let be while the whisper holds, and walks on to the way out the moment it lets go")
	Kit.done(s)


static func _out_of_walls(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, 2.0 * EscortDirector.TICK)
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var spot := (d.gates[0] as ExodusDirector.Gate).way_out
	Kit.arrive(lp, spot)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(lead.escaped and d.out_count() == 1 and d.leaving.has(lp) and (s.banners as Array).has("A BELIEVER IS OUT  1/5") and not lead.taken,
		"a believer set down past the wall (a Mirrorfold's forest) is out: counted, sent off the map, the banner says 1/5 (%s)" % [s.banners])
	t.check(d.lamp(0) != lead and d.lamp(0) != null and (d.households[0] as ExodusDirector.Household).out_to != Vector2.INF,
		"the lamp passes on, and the household's file walks on to the way out")
	var h: ExodusDirector.Household = d.households[0]
	for c: EscortDirector.Charge in h.members:
		c.escaped = true
	Kit.run_for(s, 2.0 * EscortDirector.TICK)
	t.check(h.done and d.out_count() == 3, "all three out: the household is done")
	Kit.done(s)


static func _sight_first(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	var outer := d.watch[1] as Person
	Kit.arrive(outer, d.watch_posts[1])
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var out_spot: Vector2 = d.watch_posts[1] + Vector2(0.0, 1.5)
	t.check(Walls.outside(out_spot) and out_spot.distance_to(outer.ground_pos) <= EscortDirector.SIGHT, "the spot is out of the walls and 1.5 from the outer post")
	Kit.arrive(lp, out_spot)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(lead.held and not lead.escaped and d.out_count() == 0 and lead.seizer == outer,
		"a believer set down 1.5 from the outer Main Gate post is seized before he is out (the watch's sight is judged first)")
	Kit.done(s)


# --- The search: SLIP, the chain, the trail, the reliefs ---

static func _slip(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	var h: ExodusDirector.Household = d.households[1]
	# The search is on its way to the second household's house (the last listed): the household is out HF_SLIP seconds before it arrives.
	d._search_at = 5
	var door: Vector2 = d._search[5].door
	var far: Vector2 = (d.gates[0] as ExodusDirector.Gate).mouth  # the Main Gate: a long street from the second house
	for v: Variant in d.inquisitors:
		Kit.arrive(v as Person, far)
	d._refresh_eta()
	var eta := d.search_eta(5)
	var due := d.out_due(1) - d._clock
	t.check(eta > HideFaithfulDirector.HF_SLIP + 5.0 and due > 0.0, "the search is %.0f s from the second household's house: it is not yet due out (%.0f s)" % [eta, due])
	# The inquisitors walk (people do not walk in this world: each look moves them a step along the line to where they are sent).
	var when := -1.0
	var left_then := 0.0
	var unreached := false
	for k in roundi(120.0 / EscortDirector.TICK):
		for v: Variant in d.inquisitors:
			var p := v as Person
			Kit.arrive(p, p.ground_pos.move_toward(p.anchor, Person.PANIC_SPEED * HideFaithfulDirector.HF_SEARCH_PACE * EscortDirector.TICK))
		Kit.run_for(s, EscortDirector.TICK)
		if h.out and when < 0.0:
			when = d._clock
			left_then = d.search_eta(5)
			unreached = d.trail_of() == -1 and not d._reached(5)
	t.check(when >= 0.0 and absf(left_then - HideFaithfulDirector.HF_SLIP) < 3.0 and (s.banners as Array).has("THE NORTH HOUSEHOLD SLIPS OUT"),
		"it comes out at %.0f s with the search %.1f s from its house: HF_SLIP (%.0f) before, and the banner says it slips out (%s)" % [when, left_then, HideFaithfulDirector.HF_SLIP, s.banners])
	t.check(unreached, "and the search had not reached it: never found inside")
	Kit.done(s)
	# The net under it: an inquisitor within HF_SLIP_NEAR of a door brings its household out at the next look, whatever the numbers say.
	var n := _world()
	var e: HideFaithfulDirector = n.d
	_clear_watch(e)
	Kit.arrive(e.inquisitors[0] as Person, (e.households[1] as ExodusDirector.Household).door + Vector2(HideFaithfulDirector.HF_SLIP_NEAR - 1.0, 0.0))
	Kit.run_for(n, EscortDirector.TICK + DT)
	t.check((e.households[1] as ExodusDirector.Household).out and (n.banners as Array).has("THE NORTH HOUSEHOLD SLIPS OUT"),
		"an inquisitor within %.0f of the door brings the household out at once, whatever the search's numbers" % HideFaithfulDirector.HF_SLIP_NEAR)
	Kit.done(n)


static func _chain(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, 1.0)
	for c: EscortDirector.Charge in (d.households[0] as ExodusDirector.Household).members:
		c.escaped = true
	Kit.run_for(s, EscortDirector.TICK + DT)
	var left := d.timeline.seconds_to("out_1")
	t.check((d.households[0] as ExodusDirector.Household).done and absf(left - HideFaithfulDirector.HF_CHAIN) < 1.0 and absf(d.due_in(1) - left) < 1.0,
		"a household done: the strip and the tag show the next at the chain (%.1f s, tag %.1f)" % [left, d.due_in(1)])
	Kit.run_for(s, HideFaithfulDirector.HF_CHAIN + DT)
	t.check((d.households[1] as ExodusDirector.Household).out and d._clock < float(HideFaithfulDirector.HF_OUT_AT[1]) - 5.0,
		"it comes out %d s later, long before its own time" % roundi(HideFaithfulDirector.HF_CHAIN))
	Kit.done(s)


static func _trail(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var h: ExodusDirector.Household = d.households[0]
	# The search reaches the first household's house (listed second) after the household is out.
	d._search_at = 1
	var door: Vector2 = d._search[1].door
	Kit.arrive(d.inquisitors[0] as Person, door)
	Kit.arrive(d.inquisitors[1] as Person, door + Vector2(1.0, 0.0))
	var lead := d.lamp(0)
	for c: EscortDirector.Charge in h.members:
		Kit.arrive(c.man as Person, door + Vector2(0.0, 12.0 + 0.5 * float(h.members.find(c))))  # well away: the household is 12 units on
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(d.trail_of() == 0 and (s.banners as Array).has("THE INQUISITION FINDS THE TRAIL") and d.hint_phase() == "trail",
		"reaching an emptied household's house the search takes up its trail: the banner, the hint's phase (%s)" % [s.banners])
	var p := d.inquisitors[0] as Person
	t.check(p.mind == Person.Mind.DUTY and p.anchor.distance_to((lead.man as Person).ground_pos) < 1.5 and is_equal_approx(p.pace, float(d._inq_base[p.get_instance_id()])),
		"the inquisitors walk after the lamp at their full pace (anchor %.1f from it)" % p.anchor.distance_to((lead.man as Person).ground_pos))
	var named := _labels(d).filter(func(l: Variant) -> bool: return String(l) == "INQUISITOR")
	t.check(named.size() == 2 and Kit.edged(d, "INQUISITOR"), "each inquisitor is tagged, pointed at")
	for c: EscortDirector.Charge in h.members:
		c.escaped = true
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(d.trail_of() == -1 and d._search_at == 2 and d.hint_phase() == "", "the household done, they go on down the list: the third house is next")
	# A house whose household is still inside is only stood at, and a household already done is searched as an empty one.
	var n := _world()
	var e: HideFaithfulDirector = n.d
	_clear_watch(e)
	e._search_at = 2
	var empty_door: Vector2 = e._search[2].door
	Kit.arrive(e.inquisitors[0] as Person, empty_door)
	Kit.run_for(n, EscortDirector.TICK + DT)
	var stop_at := e._search_stop
	t.check(e.trail_of() == -1 and stop_at > e._clock and absf((stop_at - e._clock) - HideFaithfulDirector.HF_SEARCH_STOP) < 0.6,
		"at an empty dwelling they stand HF_SEARCH_STOP seconds (%.1f)" % (stop_at - e._clock))
	Kit.run_for(n, HideFaithfulDirector.HF_SEARCH_STOP + 2.0 * EscortDirector.TICK)
	t.check(e._search_at == 3, "and go on to the next")
	Kit.done(n)
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var dead: Variant = d.inquisitors[0]
	Kit.free_body(s, dead as Person)
	Kit.run_for(s, HideFaithfulDirector.HF_SEARCH_RELIEF_AFTER - 3.0)
	t.check(d.inq_reliefs == 0 and not MissionDirector._alive(d.inquisitors[0]), "an inquisitor killed is not replaced before %d s" % roundi(HideFaithfulDirector.HF_SEARCH_RELIEF_AFTER))
	Kit.run_for(s, 3.0 + 2.0 * EscortDirector.TICK + DT)
	var p: Variant = d.inquisitors[0]
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and d.inq_reliefs == 1
		and (s.banners as Array).has("A NEW INQUISITOR COMES FROM THE TEMPLE"), "%d s later a lay citizen from the Temple's door takes his place" % roundi(HideFaithfulDirector.HF_SEARCH_RELIEF_AFTER))
	for k in 3:
		Kit.free_body(s, d.inquisitors[1 if k % 2 == 0 else 0] as Person)
		Kit.run_for(s, HideFaithfulDirector.HF_SEARCH_RELIEF_AFTER + 3.0 * EscortDirector.TICK)
	t.check(d.inq_reliefs == HideFaithfulDirector.HF_SEARCH_RELIEFS, "at most %d reliefs a night (%d)" % [HideFaithfulDirector.HF_SEARCH_RELIEFS, d.inq_reliefs])
	var watch_dead: Variant = d.watch[0]
	Kit.free_body(s, watch_dead as Person)
	Kit.run_for(s, ExodusDirector.RELIEF_AFTER + 4.0 * EscortDirector.TICK)
	t.check(d.watch[0] == watch_dead and d.reliefs == 0 and not (s.banners as Array).has("A NEW WATCHMAN COMES FROM THE TEMPLE"),
		"a gate watchman killed is never replaced")
	Kit.done(s)


## Review of Task 4, Important 1: the two inquisitors stay more than two Silent Doom radii apart wherever the search sends them -- at every
## listed door they stand at, and at every point of both households' roads, where one stands at the lamp and the other behind him on its trail.
static func _pair_apart(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var limit := 2.0 * SilentDoom.RADIUS + 0.1  # places, not people: the pair's places, 0.1 over a Doom's reach
	var worst_door := INF
	var from := d.temple_door
	for e: Dictionary in d._search:
		var spots := d.pair_spots(e.door, 2, from)
		worst_door = minf(worst_door, spots[0].distance_to(spots[1]))
		from = e.door
	var start := d.pair_spots(d.temple_door, 2)
	t.check(worst_door > limit and start[0].distance_to(start[1]) > limit,
		"at each of the six listed doors and at the Temple's the pair's two places are more than %.1f apart (nearest %.2f)" % [limit, worst_door])
	var worst_road := INF
	var points := 0
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		var line: Array = d.road(i)
		h.trail.clear()
		var at: Vector2 = line[0]
		for k in range(1, line.size()):
			var to: Vector2 = line[k]
			var run := at.distance_to(to)
			var steps := maxi(1, ceili(run / (ExodusDirector.FOLLOW_GAP * 0.5)))
			for q in range(1, steps + 1):
				var here := at.lerp(to, float(q) / float(steps))
				h.trail.append(here)
				var spots := d.pair_spots(here, 2, Vector2.INF, h)
				worst_road = minf(worst_road, spots[0].distance_to(spots[1]))
				points += 1
			at = to
		h.trail.clear()
	t.check(points > 100 and worst_road > limit, "along both households' roads (%d points) the pair on the trail is more than %.1f apart (nearest %.2f)" % [points, limit, worst_road])
	# Sent to a door, the pair is ordered to those places and no others.
	d._search_at = 3
	for v: Variant in d.inquisitors:
		Kit.arrive(v as Person, d._search[3].door)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var a := d.inquisitors[0] as Person
	var b := d.inquisitors[1] as Person
	t.check(a.anchor.distance_to(b.anchor) > limit, "the orders to the third listed door keep them %.2f apart" % a.anchor.distance_to(b.anchor))
	Kit.done(s)


static func _strip_rows(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var rows := d.strip_rows()
	var names := []
	for r: Dictionary in rows:
		names.append(r.label)
	t.check(names == ["The search reaches the north-west household", "The search reaches the north household"]
		and float(rows[0]["in"]) < float(rows[1]["in"]) and not names.has("The Temple sends searchers"),
		"the strip: the search reaches each household, counting down, soonest first; no \"Temple sends searchers\" row (%s)" % [names])
	Kit.run_for(s, 0.1)
	var rows2 := d.strip_rows()
	t.check(float(rows2[0]["in"]) < float(rows[0]["in"]) - 0.03, "the rows count down between looks (%.2f then %.2f)" % [float(rows[0]["in"]), float(rows2[0]["in"])])
	for v: Variant in d.inquisitors:
		Kit.arrive(v as Person, d._search[0].door)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var rows3 := d.strip_rows()
	t.check(float(rows3[0]["in"]) < float(rows[0]["in"]) - 5.0, "and the search standing nearer its first house: the first household's row is sooner (%.1f then %.1f)" % [float(rows[0]["in"]), float(rows3[0]["in"])])
	d._search_at = 1
	d._search_stop = d._clock + 3.0
	d._refresh_eta()
	t.check(d.strip_rows().size() == 1 and d.strip_rows()[0].label == "The search reaches the north household", "a house reached leaves the strip")
	var up := []
	for e in d.timeline.upcoming(4):
		up.append(e.id)
	t.check(not up.has("hunt_0") and not up.has("hunt_1"), "the timeline lists no searchers (%s)" % [up])
	Kit.done(s)


# --- Seized, lost, won ---

static func _seize_free(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var soldier := d.patrols[0][0] as Person
	Kit.arrive(soldier, lp.ground_pos + Vector2(1.0, 0.0))
	soldier.send_to_post(soldier.ground_pos)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	var banner := "A BELIEVER IS SEIZED - FREE HIM BEFORE THE TEMPLE"
	t.check(lead.held and lead.seizer == soldier and (s.banners as Array).has(banner) and d.hint_phase() == "seized" and d.seizures == 1,
		"a patrol soldier within sight seizes a believer: the banner, the hint's phase (%s)" % [s.banners])
	var labels := _labels(d)
	var seized := labels.filter(func(l: Variant) -> bool: return String(l).begins_with("SEIZED - TEMPLE IN "))
	t.check(seized.size() == 1 and labels.has("TAKING HIM IN") and labels.has("TEMPLE") and Kit.edged(d, String(seized[0])),
		"the seized believer is tagged with the seconds to the Temple, his seizer and the Temple pointed at (%s)" % [labels])
	Kit.free_body(s, soldier)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(not lead.held and (s.banners as Array).has("THE BELIEVER IS FREE") and d.lost() == 0, "the seizer felled lets him go where he stands; he walks on")
	# Delivered, he is taken: lost, not an instant loss.
	var n := _world()
	var e: HideFaithfulDirector = n.d
	_clear_watch(e)
	e._come_out(0)
	Kit.run_for(n, EscortDirector.TICK + DT)
	var c2 := e.lamp(0)
	var by := e.inquisitors[0] as Person
	Kit.arrive(by, (c2.man as Person).ground_pos + Vector2(1.0, 0.0))
	by.send_to_post(by.ground_pos)
	by.mind = Person.Mind.POST
	Kit.run_for(n, 2.0 * EscortDirector.TICK + DT)
	Kit.arrive(by, e.return_to)
	Kit.arrive(c2.man as Person, e.return_to + Vector2(0.5, 0.0))
	Kit.run_for(n, 2.0 * EscortDirector.TICK + DT)
	t.check(c2.taken and e.lost() == 1 and e.lost_reason() == "" and (n.banners as Array).has("THE INQUISITION TAKES A BELIEVER")
		and (n.banners as Array).has("ONE BELIEVER LOST - ONE MORE AND THE HUNT FAILS"),
		"delivered, a believer is taken: one lost, the night goes on, the banner warns (%s)" % [n.banners])
	var warned := _labels(e).filter(func(l: Variant) -> bool: return String(l).ends_with("DO NOT KILL"))
	var believers := 0
	for c in e.charges:
		believers += 1 if not e._resolved(c) and not (c.man as Person).inside else 0
	t.check(warned.size() == believers and believers == 2, "after the first loss every believer's tag ends DO NOT KILL (%d of %d)" % [warned.size(), believers])
	Kit.done(n)
	Kit.done(s)


static func _lose_two(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var rules: Rules = s.rules
	d.charges[0].taken = true
	t.check(d.lost() == 1 and d.lost_reason() == "" and rules.objectives[0].check(rules) == Objective.Status.PENDING, "one taken: not lost yet")
	Kit.free_body(s, d.charges[1].man as Person)
	t.check(d.lost() == 2 and d.lost_reason() == "faithful_lost", "one taken and one killed: two lost, faithful_lost (%d)" % d.lost())
	var main := rules.objectives[0] as EscortObjective
	t.check(main.check(rules) == Objective.Status.FAILED and main.reason == "faithful_lost" and d.tags().is_empty() and d.hint_phase() == "",
		"the objective fails with that reason; nothing is tagged")
	Kit.done(s)
	# An out believer is not a lost one, whatever happens to his body after.
	var n := _world()
	var e: HideFaithfulDirector = n.d
	e.charges[0].escaped = true
	Kit.free_body(n, e.charges[0].man as Person)
	t.check(e.lost() == 0, "a believer out whose body is freed is not lost")
	Kit.done(n)


static func _win_beats_loss(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var rules: Rules = s.rules
	for k in 5:
		d.charges[k].escaped = true
	d.charges[5].taken = true
	var main := rules.objectives[0] as EscortObjective
	t.check(d.out_count() == 5 and d.lost() == 1 and main.check(rules) == Objective.Status.DONE and main.reason == "faithful_out",
		"five out win, whatever else (the objective is checked win first)")
	Kit.done(s)


static func _no_luck(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var lp := d.lamp(0).man as Person
	var stranger: Person = null
	for p in (s.crowd as Crowd).soldiers:
		if is_instance_valid(p) and not d._watchers().has(p):
			stranger = p
			break
	var citizen: Person = null
	for p in (s.crowd as Crowd).citizens:
		if is_instance_valid(p) and not p.inside and not d._watchers().has(p) and p.profile != null and p.profile.role == CitizenProfile.Role.WATCHMAN:
			citizen = p
			break
	t.check(stranger != null, "the town has a soldier who is not in the watch")
	if stranger != null:
		Kit.arrive(stranger, lp.ground_pos + Vector2(0.8, 0.0))
		stranger.send_to_post(stranger.ground_pos)
	if citizen != null:
		Kit.arrive(citizen, lp.ground_pos + Vector2(-0.8, 0.0))
	Kit.run_for(s, 4.0 * EscortDirector.TICK)
	t.check(not d.charges[0].held and d.seizures == 0 and d.lost() == 0, "a town soldier or watchman who is not the director's seizes no one (%d seizures)" % d.seizures)
	Kit.done(s)


static func _evacuation(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, 1.0)
	var lead := d.lamp(0).man as Person
	var inq := d.inquisitors[0] as Person
	inq._recover(1.0)
	var w := d.watch[2] as Person
	w._recover(1.0)
	Kit.evacuate(s)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	var none_fled := true
	for c in d.charges:
		none_fled = none_fled and (c.man as Person).mind != Person.Mind.FLEE
	t.check(none_fled and lead.mind == Person.Mind.DUTY and inq.mind == Person.Mind.DUTY and w.mind == Person.Mind.POST,
		"the evacuation: no believer flees, the lamp walks on, the recovering inquisitor and watchman go back to work at once (%s %s %s)" % [lead.mind, inq.mind, w.mind])
	var inside := (d.households[1] as ExodusDirector.Household).members.all(func(c: EscortDirector.Charge) -> bool: return (c.man as Person).inside)
	t.check(inside, "the household still inside stays inside")
	Kit.done(s)


## Task 1's wish check for this Hunt, with its director: no wish lands on the director's own people or buildings, on nights 0-3.
static func _wishes(t) -> void:
	var id := MissionBook.HIDE_FAITHFUL
	var heard := 0
	var hit := 0
	var mine_people := 0
	for night in 4:
		var def := HuntBook.def(id)
		var descent := Descent.new().setup(def, Descent.seed_for(night, id))
		var n := Kit.world(HuntBook.def(id), null, func(d: MissionDirector, rules: Rules) -> void: descent.reserve(rules, d))
		var mine: Dictionary = Book._own(n.d)
		mine_people += (mine.people as Array).size()
		for w in descent.wishes:
			heard += 1
			for p in w.people():
				hit += 1 if (mine.people as Array).has(p) else 0
			for st in w.places():
				hit += 1 if (mine.places as Array).has(st) else 0
		var d := n.d as HideFaithfulDirector
		for h: ExodusDirector.Household in d.households:
			for c: EscortDirector.Charge in h.members:
				hit += 1 if (descent.wishes.any(func(w: Wish) -> bool: return w.people().has(c.man))) else 0
			hit += 1 if (descent.wishes.any(func(w: Wish) -> bool: return w.places().has(h.house))) else 0
		descent.release()
		Kit.done(n)
	t.check(heard > 0 and hit == 0 and mine_people >= 12, "hide_faithful: wishes heard (%d), none on the director's own people or buildings (%d); %d of its people found" % [heard, hit, mine_people])
