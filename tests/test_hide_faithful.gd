extends RefCounted
## God P5 Task 4 (plan Task 4, MS §2): Hunt 1, Hide the faithful (HideFaithfulDirector on ExodusDirector): two households of three believers in
## quiet stone houses who walk themselves out of the walls when their time comes; a soldiers' watch (four at the gates, two patrols of two
## walking 2.0 apart); two inquisitors who search six listed houses in order and trail a household that is out when they reach its house; a
## household never found inside (SLIP); five of six out wins, two taken or killed loses. The world is test_lost_lamb's kind: a town with its
## crowd and a Rules, run in 0.05 s steps (people do not walk in it, so the tests read goals and anchors and move people with Kit.arrive()).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const Book := preload("res://tests/test_hunt_book.gd")
const Hunts := preload("res://tools/dev/routes/god_hunts.gd")
const TYPES := ["ruin", "death", "veil", "passage", "decree", "dominion"]


## The pieces of behaviour_check the six policies read, as a stand-in (the policy files take `bc` as an untyped script).
class FakeBc:
	extends RefCounted

	func _slot_ready(rules: Rules, slots: Dictionary, key: String) -> bool:
		return slots.has(key) and rules.refusal(int(slots[key])) == ""

	func _exodus_flock(d: ExodusDirector) -> Array:
		var out := []
		for c in d.charges:
			if not d._resolved(c) and not (c.man as Person).inside:
				out.append(c.man)
		return out

	func _prisoner_away(crowd: Crowd, p: Person, from: Vector2) -> Vector2:
		var off := p.ground_pos - from
		return MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * 8.0)


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
	_pair_trail_behind(t)
	_pair_in_reach(t)
	_pair_door_gaps(t)
	_pair_afresh(t)
	_patrol_apart(t)
	_pair_walk(t)
	_policies_written(t)
	_policies_answer(t)
	_no_filler_casts(t)
	_pair_orders(t)
	_walk_fixes(t)
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
	var first := minf(p.anchor.distance_to((lead.man as Person).ground_pos), (d.inquisitors[1] as Person).anchor.distance_to((lead.man as Person).ground_pos))
	t.check(p.mind == Person.Mind.DUTY and first < 1.5 and is_equal_approx(p.pace, float(d._inq_base[p.get_instance_id()])),
		"the inquisitors walk after the lamp at their full pace (the first one's anchor %.1f from it)" % first)
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


## The nearest `p` lies to the polyline `pts`.
static func _off_line(p: Vector2, pts: Array) -> float:
	var best := INF
	for k in range(pts.size() - 1):
		best = minf(best, Geometry2D.get_closest_point_to_segment(p, pts[k], pts[k + 1]).distance_to(p))
	return best


## Task 9 (review of Task 4, re-review item 1): on a trail the first inquisitor stands at the lamp's place and the second behind him -- on the
## lamp's trail where that reaches far enough back, and where the lamp is still near its house door (the trail shorter than the gap), on the
## road's own points behind it -- at every point of both roads; the door ring is never the answer on a road.
static func _pair_trail_behind(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var want := HideFaithfulDirector.HF_SEARCH_GAP + HideFaithfulDirector.HF_PAIR_SLACK - 0.1
	var points := 0
	var on_trail := 0
	var on_road := 0
	var ring := 0
	var lead_off := 0
	var worst := INF
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		var line: Array = d.road(i)
		h.trail.clear()
		var at: Vector2 = line[0]
		for k in range(1, line.size()):
			var to: Vector2 = line[k]
			var steps := maxi(1, ceili(at.distance_to(to) / (ExodusDirector.FOLLOW_GAP * 0.5)))
			for q in range(1, steps + 1):
				var here := at.lerp(to, float(q) / float(steps))
				h.trail.append(here)
				var spots := d.pair_spots(here, 2, Vector2.INF, h)
				points += 1
				worst = minf(worst, spots[0].distance_to(spots[1]))
				if spots[0].distance_to(d._walkable(here)) > 0.01:
					lead_off += 1
				# The second: on the lamp's trail (the trail reaches the gap back), else on the road's own points behind the lamp.
				var line_pts: Array = [here]
				for m in range(h.trail.size() - 1, -1, -1):
					line_pts.append(h.trail[m])
				var found := ""
				for step in 10:
					var back := HideFaithfulDirector.HF_SEARCH_GAP + HideFaithfulDirector.HF_PAIR_SLACK + 0.4 * float(step)
					if found == "" and spots[1].distance_to(d._trail_point(h, here, back)) < 0.01 and _off_line(spots[1], line_pts) < 0.3 							and spots[0].distance_to(spots[1]) >= want and h.trail.size() > 8:
						found = "trail"
					if found == "" and spots[1].distance_to(d._road_behind(i, here, back)) < 0.01:
						found = "road"
				on_trail += 1 if found == "trail" else 0
				on_road += 1 if found == "road" else 0
				ring += 1 if found == "" else 0
			at = to
		h.trail.clear()
	t.check(points > 100 and lead_off == 0 and ring == 0 and worst > want - 0.01,
		"on a trail the first stands at the lamp and the second behind him on its trail (%d points) or on the road's own points behind him (%d), never on the ring (%d on it, %d leads off the lamp; nearest %.2f)" % [
			on_trail, on_road, ring, lead_off, worst])
	t.check(on_trail > 20 and on_road > 0, "both cases are met along the roads: a trail long enough (%d) and a lamp still near its door (%d)" % [on_trail, on_road])
	Kit.done(s)


## Task 9 (re-review item 4): every pair place at a listed door is within HF_ARRIVE of it (the stop starts when one inquisitor is), at all
## six doors and the Temple's.
static func _pair_in_reach(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var far := 0.0
	var beyond := 0
	var from := d.temple_door
	for e: Dictionary in d._search:
		var near := INF
		for spot in d.pair_spots(e.door, 2, from):
			far = maxf(far, spot.distance_to(e.door))
			near = minf(near, spot.distance_to(e.door))
			beyond += 1 if spot.distance_to(e.door) > HideFaithfulDirector.HF_ARRIVE else 0
		from = e.door
		t.check(near <= HideFaithfulDirector.HF_ARRIVE, "a place of the pair at the door %s is within HF_ARRIVE (the stop starts) (%.2f)" % [e.door, near])
	# Every place but one is within HF_ARRIVE of its door; the one is the second place of a door in an alley whose far side is shut (it stands up to 4.6 off).
	t.check(beyond <= 1 and far <= 4.6, "every pair place at the six listed doors is within HF_ARRIVE %.1f of its door, bar one alley door's second place (%d beyond, farthest %.2f)" % [
		HideFaithfulDirector.HF_ARRIVE, beyond, far])
	Kit.done(s)


## Task 9 (re-review item 2): the nearest the two stood to each other is kept at every listed door, not only the first's; a stop at each door
## notes its own.
static func _pair_door_gaps(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	var limit := 2.0 * SilentDoom.RADIUS + 0.1
	var seen := 0
	var worst := INF
	for h: ExodusDirector.Household in d.households:
		h.out = true  # (both households done: no trail is taken up, the search stops at every door)
		h.done = true
	for k in d._search.size():
		d._search_at = k
		d._search_stop = -1.0
		d._pairs.clear()
		var door: Vector2 = d._search[k].door
		var spots: Array[Vector2] = d._door_spots(door, 2)
		for j in 2:
			Kit.arrive(d.inquisitors[j] as Person, spots[j])
			(d.inquisitors[j] as Person).go_duty(spots[j])
		Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
		var gap: float = d.stopped_door_gap[k] if k < d.stopped_door_gap.size() else INF
		if gap < INF:
			seen += 1
			worst = minf(worst, gap)
	t.check(seen == d._search.size() and worst > limit, "a stop at each of the six listed doors notes its own gap, all over %.1f (%d noted, nearest %.2f)" % [limit, seen, worst])
	Kit.done(s)


## Task 9 (re-review item 5): the pair's places are worked out afresh at each arrival, not kept from the walk there -- a house fallen or rebuilt
## on the ground since is seen.
static func _pair_afresh(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch(d)
	d._search_at = 2
	var door: Vector2 = d._search[2].door
	var stale: Array[Vector2] = [door + Vector2(40.0, 40.0), door + Vector2(41.0, 40.0)]
	d._pairs.clear()
	d._pairs["%s/%d" % [door, 2]] = stale
	Kit.arrive(d.inquisitors[0] as Person, door)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var spots: Array[Vector2] = d._door_spots(door, 2)
	t.check(d._search_stop >= 0.0 and spots != stale and spots[0].distance_to(door) <= HideFaithfulDirector.HF_ARRIVE + 0.01,
		"at the arrival the stale places are dropped and the pair's places are worked out afresh (%s)" % [spots])
	Kit.done(s)


## Task 9 (first review, Minor 4): a patrol's two soldiers are HF_PATROL_GAP (2.0) apart at the start and, walking the beat on their own feet,
## more than two Silent Doom radii apart all the way along it, both ways, turns included.
static func _patrol_apart(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	t.check(is_equal_approx(HideFaithfulDirector.HF_PATROL_GAP, 2.0), "HF_PATROL_GAP is 2.0")
	var limit := 2.0 * SilentDoom.RADIUS
	var nearest := INF
	var looks := 0
	var moved := 0.0
	var start: Array[Vector2] = []
	for squad: Array in d.patrols:
		for v: Variant in squad:
			start.append((v as Person).ground_pos)
	var seconds := 90.0
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)
		for squad: Array in d.patrols:
			for v: Variant in squad:
				if MissionDirector._alive(v):
					(v as Person).tick(DT)
		if i % 4 == 0:
			var n := 0
			for squad: Array in d.patrols:
				for v: Variant in squad:
					moved = maxf(moved, (v as Person).ground_pos.distance_to(start[n]))
					n += 1
			for squad: Array in d.patrols:
				if squad.size() == 2 and MissionDirector._alive(squad[0]) and MissionDirector._alive(squad[1]):
					nearest = minf(nearest, (squad[0] as Person).ground_pos.distance_to((squad[1] as Person).ground_pos))
					looks += 1
	t.check(looks > 100 and moved > 3.0 and nearest > limit + 0.2,
		"walking its beat for %d s a patrol's two stay more than %.2f apart (%d looks, nearest %.2f, farthest walked %.1f)" % [roundi(seconds), limit + 0.2, looks, nearest, moved])
	Kit.done(s)


# --- The six policies (god P5 Task 9; tools/dev/routes/god_hunts/hide_faithful.gd) ---

## Every type's policy is written and drafts a loadout the tree can play; the file keeps no filler cast (a cast made only so the scripted
## player is not idle, T1R D38 -- the policy's words never start with GodT1.FILL) and the report line prints every door's gap.
static func _policies_written(t) -> void:
	GodTree.dev_fill = true
	var filled := Hunts.filled("hide_faithful")
	var all := true
	var problems := PackedStringArray()
	for type: String in TYPES:
		all = all and type in filled and Hunts.has_policy("hide_faithful", type)
		for p in Hunts.problems("hide_faithful", type, 1):
			problems.append("%s: %s" % [type, p])
	t.check(all and problems.is_empty(), "all six types have a written policy with a loadout the tree plays (filled %s, problems %s)" % [Array(filled), Array(problems)])
	var src := FileAccess.get_file_as_string("res://tools/dev/routes/god_hunts/hide_faithful.gd")
	t.check(not src.contains('"' + Hunts.GOD_T1.FILL) and not src.contains("FILL +") and not src.contains("GOD_T1.FILL"),
		"the Hunt's policy file keeps no filler cast")
	GodTree.dev_fill = false


## Each type answers a watcher about to see a believer, with its own two powers and no filler: a soldier set on the road a few steps ahead of
## the lamp of a household that has come out. Ruin, Death, Veil and Dominion strike or turn him at once; Decree calls the guard off; Passage has
## its mirror out before the household comes (the way out past the wall).
static func _policies_answer(t) -> void:
	GodTree.dev_fill = true
	for type: String in TYPES:
		var def := HuntBook.def(MissionBook.HIDE_FAITHFUL)
		def.default_loadout = Hunts.loadout("hide_faithful", type)
		var s := Kit.world(def)
		var d: HideFaithfulDirector = s.d
		var rules: Rules = s.rules
		var calls: Array = []
		rules.caster = func(_s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
			calls.append({"at": g, "extra": e})
			return null
		var slots := {}
		for i in def.default_loadout.size():
			slots[def.default_loadout[i]] = i
		var ctx := {"rules": rules, "slots": slots, "d": d, "crowd": s.crowd, "memo": {}, "mission": null}
		var bc := FakeBc.new()
		_clear_watch(d)
		if type != "passage":
			d._come_out(0)
			Kit.run_for(s, EscortDirector.TICK + DT)
			var lead := d.lamp(0)
			var line: Array = d.road(0)
			var from_k := 0
			var best := INF
			for k in line.size():
				var g := (lead.man as Person).ground_pos.distance_to(line[k])
				if g < best:
					best = g
					from_k = k
			var at: Vector2 = line[from_k]
			var run := 0.0
			for k in range(from_k + 1, line.size()):
				run += (line[k - 1] as Vector2).distance_to(line[k])
				at = line[k]
				if run >= 6.0:
					break  # six units of road ahead of the lamp: about eight seconds of its walk
			Kit.arrive((d.patrols[0][0] as Person), at)
		var words := ""
		var said := ""
		for look in 60:
			said = Hunts.act("hide_faithful", type, bc, ctx)
			if said != "":
				words = said
				break
			Kit.run_for(s, 0.1)
		t.check(words != "" and not Hunts.GOD_T1.is_fill(words) and not calls.is_empty(), "%s answers a watcher on the road with a cast of its own (%s)" % [type, words])
		if type == "passage" and not calls.is_empty():
			t.check(Walls.outside(calls[0].extra.to) and words.begins_with("mirror"), "Passage folds the file out past the wall: its way out is outside (%s)" % [calls[0].extra])
		if type == "decree" and not calls.is_empty():
			t.check(calls[0].extra.get("mode", "") == "guard" or words.begins_with("leaving"), "Decree calls the guard off or holds a circle (%s)" % words)
		Kit.done(s)
	var w := _world()
	var report := Hunts.state("hide_faithful", null, {"d": w.d, "memo": {}})
	t.check(report.contains("doors=") and report.contains("pair="), "the report line prints the pair's gap at every door (%s)" % report)
	Kit.done(w)
	GodTree.dev_fill = false


## The inquisitor pair walks the whole six-house list on its own feet (the people are ticked; both households done and gone, so no believer is seized and
## marched), the gap between the two read every step of 0.05 s (Ruling P5-T9-R8, the standard of P5-T11-R9). `relief` kills one at 3 s, 50 s and 110 s so a
## relief walks in. Returns {steps, under, walk_steps,
## walk_under, nearest, stop_nearest, doors, stops, reliefs}: every step while both stand is counted, the first after a change of state (a stop begins or
## ends, the trail) included; `walk_*` counts only the steps when the two are not both standing at their places.
static func _walk_metrics(relief: bool) -> Dictionary:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	_clear_watch_but_search(d)
	for h: ExodusDirector.Household in d.households:
		h.out = true
		h.done = true
	var m := {"steps": 0, "under": 0, "walk_steps": 0, "walk_under": 0, "nearest": INF, "stop_nearest": INF, "stops": 0}
	var kills := [3.0, 50.0, 110.0]
	for i in roundi(330.0 / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)
		for v: Variant in d.inquisitors:
			if MissionDirector._alive(v):
				(v as Person).tick(DT)
		if relief and not kills.is_empty() and d._clock > float(kills[0]) and MissionDirector._alive(d.inquisitors[1]):
			kills.pop_front()
			Kit.free_body(s, d.inquisitors[1] as Person)
		if d.inquisitors.size() != 2 or not MissionDirector._alive(d.inquisitors[0]) or not MissionDirector._alive(d.inquisitors[1]):
			continue
		var a := d.inquisitors[0] as Person
		var b := d.inquisitors[1] as Person
		var gap := a.ground_pos.distance_to(b.ground_pos)
		var settled := a.ground_pos.distance_to(a.anchor) < HideFaithfulDirector.HF_PLACE_NEAR and b.ground_pos.distance_to(b.anchor) < HideFaithfulDirector.HF_PLACE_NEAR \
			and a.anchor.distance_to(b.anchor) < 6.0
		m.steps += 1  # (every sample while both stand: the first after a change of state too, nothing left out)
		m.under += 1 if gap < 1.6 else 0
		m.nearest = minf(m.nearest, gap)
		if settled and d._search_stop >= 0.0:
			m.stops += 1
			m.stop_nearest = minf(m.stop_nearest, gap)
		if not settled:
			m.walk_steps += 1
			m.walk_under += 1 if gap < 1.6 else 0
	m["doors"] = d.stopped_door_gap.duplicate()
	m["reliefs"] = d.inq_reliefs
	Kit.done(s)
	return m


## Ruling P5-T9-R8 (review of Task 9, I1): the inquisitor pair walks apart on its whole walk, not only at its stops -- the place of each by who is nearer
## along the path, the rear man holding on leaving a stop until the gap along the path opens to HF_PAIR_FILE. The standard (P5-T11-R9): at a stop the pair
## stands over 1.6 apart always -- at each of the six doors -- and on the walk at most 5 % of the steps are under 1.6 (corners, the first steps out of a door).
## Measured shares are in the check message. (Mutation: the file order off -- places by index, no hold -- reads 6.0 % of all steps and 19.8 % of the walking
## steps under 1.6, nearest 0.00; the review measured 8.0 % of the walk on the old director.)
static func _pair_walk(t) -> void:
	for relief in [false, true]:
		var m := _walk_metrics(relief)
		var doors: Array = m.doors
		var noted := 0
		var worst_door := INF
		for g: Variant in doors:
			noted += 1 if float(g) < INF else 0
			worst_door = minf(worst_door, float(g))
		var share := float(m.under) / float(maxi(m.steps, 1))
		var walk_share := float(m.walk_under) / float(maxi(m.walk_steps, 1))
		# (Door 3 is never stood at by both on the walk -- the rear man comes in as the stop ends -- and the alley door is stood at 4.2 apart: five doors are
		# sampled; the pair's places at all six are held by _pair_apart and _pair_orders, the forced stops at all six by _pair_door_gaps.)
		t.check(m.stops > (10 if relief else 20) and float(m.stop_nearest) > 1.6 and noted >= (1 if relief else 5) and worst_door > 1.6,
			"%s: at each door the pair stands at it is over 1.6 apart (%d samples at %d doors, nearest %.2f, per door %s)" % ["with a relief" if relief else "plain", m.stops, noted, m.stop_nearest, doors])
		t.check(m.steps > (600 if relief else 3000) and share <= 0.05 and float(m.nearest) > 0.5,
			"%s: on the whole walk %.1f %% of the %d steps are under 1.6 apart (%.1f %% of the %d walking steps; nearest %.2f) -- at most 5 %%" % [
				"with a relief" if relief else "plain", 100.0 * share, m.steps, 100.0 * walk_share, m.walk_steps, m.nearest])


## Only the inquisitors left to search: the watch and the patrols are moved well away.
static func _clear_watch_but_search(d: HideFaithfulDirector) -> void:
	for v: Variant in d.watch:
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))
	for squad: Array in d.patrols:
		for v: Variant in squad:
			if MissionDirector._alive(v):
				Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))


## A Rules that records the casts and lands none.
class SpyRules:
	extends Rules
	var casts: Array[Dictionary] = []

	func cast(slot: int, ground: Vector2, extra := {}) -> FxTimeline:
		casts.append({"slot": slot, "at": ground, "extra": extra})
		return null


## FakeBc with every power ready (the spy world has no cooldowns).
class SpyBc:
	extends FakeBc

	func _slot_ready(_rules, slots: Dictionary, key: String) -> bool:
		return slots.has(key)


## What watcher `p` is: "watch", "patrol" or "inquisitor".
static func _kind_of(d: HideFaithfulDirector, p: Person) -> String:
	if d.watch.has(p):
		return "watch"
	if d.inquisitors.has(p):
		return "inquisitor"
	return "patrol"


## Everybody the night still needs answered: each watcher, patrolman, inquisitor and watchman alive out of doors.
static func _needed(d: HideFaithfulDirector) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for v: Variant in d._watchers():
		if MissionDirector._alive(v) and not (v as Person).inside:
			out.append((v as Person).ground_pos)
	return out


## Behavioural no-filler check (review of Task 9, M1; Ruling P5-T10-R2): every cast the six policies make, driven over three nights, lands on somebody the
## night still needs answered (a kill, mark, plague, whisper, discord or cage within 3.5 of a living watcher; the call of the guard within 16 of the soldiers
## it takes; the mirror's way in on a road of a household not yet out of the walls), never a cast made only to end an idle stretch. Nights: the 0:00 start, a
## household out with a soldier on its road, and the idle night -- the first household done, the second 20 s from coming out (clock 120 s), the last cast 31 s
## back, the side gate's watch 60 s from its sight. There Dominion casts nothing: its whisper holds a man twenty seconds and is not cast sixty ahead.
## (Mutation: Dominion's idle lead restored in act_dominion -- it whispers the watchman at the gate at once and the idle-night check fails.)
static func _no_filler_casts(t) -> void:
	GodTree.dev_fill = true
	for type: String in TYPES:
		var total := 0
		var strays := PackedStringArray()
		var idle_casts := 0
		var idle_watch := 0
		for night in 3:
			var def := HuntBook.def(MissionBook.HIDE_FAITHFUL)
			def.default_loadout = Hunts.loadout("hide_faithful", type)
			var s := Kit.world(def)
			var d: HideFaithfulDirector = s.d
			var slots := {}
			for i in def.default_loadout.size():
				slots[def.default_loadout[i]] = i
			var spy := SpyRules.new()
			var ctx := {"rules": spy, "slots": slots, "d": d, "crowd": s.crowd, "memo": {}, "mission": null}
			var bc := SpyBc.new()
			if night == 1:
				_clear_watch(d)
				d._come_out(0)
				Kit.run_for(s, EscortDirector.TICK + DT)
				var lead := d.lamp(0)
				var line: Array = d.road(0)
				var from_k := 0
				var best := INF
				for k in line.size():
					var g := (lead.man as Person).ground_pos.distance_to(line[k])
					if g < best:
						best = g
						from_k = k
				var at: Vector2 = line[from_k]
				var run := 0.0
				for k in range(from_k + 1, line.size()):
					run += (line[k - 1] as Vector2).distance_to(line[k])
					at = line[k]
					if run >= 6.0:
						break
				Kit.arrive((d.patrols[0][0] as Person), at)
			elif night == 2:
				var h0: ExodusDirector.Household = d.households[0]
				h0.out = true
				h0.done = true
				h0.done_at = 1000.0
				d.inq_reliefs = HideFaithfulDirector.HF_SEARCH_RELIEFS
				for v: Variant in d.inquisitors.duplicate():
					Kit.free_body(s, v as Person)
				Kit.run_for(s, 120.0)
				ctx.memo["last_cast"] = d._clock - 31.0
			var act := Callable(Hunts.FILES["hide_faithful"], "act_" + type)
			for look in 6:
				Kit.run_for(s, 0.5)
				var before := spy.casts.size()
				var did := String(act.call(bc, ctx))
				if spy.casts.size() > before:
					spy.casts[spy.casts.size() - 1]["did"] = did  # (what the cast names: "smite a patrol", "doom a watch", ...)
				t.check((did == "") == (spy.casts.size() == before), "%s night %d: what the policy returns says whether it cast (%s)" % [type, night, did])
				t.check(not Hunts.GOD_T1.is_fill(did), "%s night %d: the cast is not worded a filler (%s)" % [type, night, did])
			var roads: Array = []
			for i in d.households.size():
				if not (d.households[i] as ExodusDirector.Household).done:
					roads.append_array(d.road(i))
			for c in spy.casts:
				total += 1
				idle_casts += 1 if night == 2 else 0
				var key := String(slots.find_key(c.slot))
				var near := false
				if key == "mirror":
					for q: Vector2 in roads:
						near = near or (c.at as Vector2).distance_to(q) <= 1.0
				elif key == "blight":
					var tower: Structure = (s.crowd as Crowd).bell.tower  # (the Bell Tower, so a seen death rings nothing: it ends no stretch, the tower is ruined for good)
					near = tower != null and (c.at as Vector2).distance_to(tower.center()) <= 1.0
				else:
					# The cast names its target ("smite a patrol", "doom a watch", "leaving is prohibited: a patrol group ..."): it lands on one of THAT kind, a
					# strike within 1.5 of him, a cage within 3.5, the call of the guard within 16 of the soldiers it takes.
					var said := String(c.get("did", ""))
					var kind := "inquisitor" if said.contains("inquisitor") else ("patrol" if said.contains("patrol") else ("watch" if said.contains("watch") else ""))
					var reach := 16.0 if key == "belllies" else (3.5 if key == "noleave" else 1.5)
					var named: Array[Vector2] = []
					for v: Variant in d._watchers():
						if MissionDirector._alive(v) and _kind_of(d, v as Person) == kind or (key == "belllies" and MissionDirector._alive(v) and _kind_of(d, v as Person) != "inquisitor"):
							named.append((v as Person).ground_pos)
					for at: Vector2 in named:
						near = near or (c.at as Vector2).distance_to(at) <= reach
					if night == 2 and kind == "watch":
						idle_watch += 1
				if not near:
					strays.append("%s night %d at %s (%s)" % [key, night, c.at, c.get("did", "")])
			spy.free()
			Kit.done(s)
		t.check(total > 0, "%s: the policy casts over the three nights (%d casts)" % [type, total])
		t.check(strays.is_empty(), "%s: every cast lands on somebody the night still needs answered (strays: %s)" % [type, ", ".join(strays)])
		if type == "dominion":
			t.check(idle_casts == 0, "dominion: on the idle night, with the watch 60 s from its sight, it casts nothing (%d casts)" % idle_casts)
		if type in ["ruin", "death"]:
			# The idle lead: a real, permanent kill, made earlier than its lead -- on the gate watchman it names, the watch 60 s from its sight.
			t.check(idle_watch >= 1, "%s: on the idle night it kills a gate watchman 60 s ahead of his sight, and the cast lands on him (%d such casts)" % [type, idle_watch])
	GodTree.dev_fill = false


## Review of Task 9, M2: tests that fail without HF_PAIR_SLACK 0.6, the inquisitors' one pace and the pair being re-ordered together. (Mutations: slack
## 0.5 -- the constant pin and the walk test fail, the 2.3 floor alone does not (nearest 2.33); `p.pace = HF_SEARCH_BASE_PACE` removed, `resend` per man -- each fails here.)
static func _pair_orders(t) -> void:
	var s := _world()
	var d: HideFaithfulDirector = s.d
	# One pace: the people the director picks walk at different paces of their own, and the pair share the base one.
	var paces := {}
	for v: Variant in d.inquisitors:
		paces[float(d._inq_base[(v as Person).get_instance_id()])] = true
	t.check(paces.size() == 1 and is_equal_approx(float(paces.keys()[0]), HideFaithfulDirector.HF_SEARCH_BASE_PACE),
		"the two inquisitors share one base pace, %.1f (%s)" % [HideFaithfulDirector.HF_SEARCH_BASE_PACE, paces.keys()])
	# The places are over HF_SEARCH_GAP + 0.6 - 0.1 = 2.3 apart at the six doors (the design is 2.4; absolute: the slack is 0.6).
	var worst := INF
	var from := d.temple_door
	for e: Dictionary in d._search:
		var sp := d.pair_spots(e.door, 2, from)
		worst = minf(worst, sp[0].distance_to(sp[1]))
		from = e.door
	t.check(worst >= 2.3 and is_equal_approx(HideFaithfulDirector.HF_PAIR_SLACK, 0.6), "the pair's places at the six doors are at least 2.3 apart (nearest %.2f)" % worst)
	# Both are re-ordered together: one far from his place, the other a hair off his own (under MOVE): both anchors come to their places.
	_clear_watch_but_search(d)
	for h: ExodusDirector.Household in d.households:
		h.out = true
		h.done = true
	d._search_at = 3
	var door: Vector2 = d._search[3].door
	var spots: Array[Vector2] = d._door_spots(door, 2)
	var a := d.inquisitors[0] as Person
	var b := d.inquisitors[1] as Person
	Kit.arrive(a, spots[0] + Vector2(6.0, 0.0))
	Kit.arrive(b, spots[1] + Vector2(0.0, 0.2))
	a.go_duty(spots[0] + Vector2(6.0, 0.0))
	b.go_duty(spots[1] + Vector2(0.0, 0.2))
	d._set_pace(a, HideFaithfulDirector.HF_SEARCH_PACE)  # (their walking pace already set: only the anchors can say who was sent)
	d._set_pace(b, HideFaithfulDirector.HF_SEARCH_PACE)
	d._order_search()
	var anchors := [a.anchor, b.anchor]
	var placed := (anchors[0] as Vector2).distance_to(spots[0]) < 0.05 and (anchors[1] as Vector2).distance_to(spots[1]) < 0.05 \
		or (anchors[0] as Vector2).distance_to(spots[1]) < 0.05 and (anchors[1] as Vector2).distance_to(spots[0]) < 0.05
	t.check(placed, "when one of the pair needs a new order both are sent: the anchors stand at the two places (%s, places %s)" % [anchors, spots])
	Kit.done(s)


## A Lantern whose Bearer's errand is `busy`'s alone.
class ErrandLantern:
	extends LanternWatch
	var busy: Variant = null

	func has_errand(p: Variant) -> bool:
		return p == busy


## A director whose walk is shut between chosen places: `_reaches(a, b)` is false for each blocked [from, to] pair (each end within 0.05).
class ShutDirector:
	extends HideFaithfulDirector
	var blocked: Array = []

	func _reaches(a: Vector2, b: Vector2) -> bool:
		for pair: Array in blocked:
			if a.distance_to(pair[0]) < 0.05 and b.distance_to(pair[1]) < 0.05:
				return false
		return super(a, b)


## Review of Task 9 (re-review): the director fixes the walk test found. (Mutations, each failing here: the Lantern filter left out of
## `_relief_from_temple`; the inquisitors not put in `reserved`; a man sent to a place he cannot reach instead of the door; `pair_spots` not asking that a
## place can be walked from to the door; or from the door the search comes from.)
static func _walk_fixes(t) -> void:
	# The relief is not the Lantern Bearer's escort: the man the base would pick (nearest the Temple) walks the Lantern's errand, and another comes.
	var s := _world()
	var d: HideFaithfulDirector = s.d
	var rules: Rules = s.rules
	var plain: Person = null
	for p in d._lay_near(d.temple_door, MissionDirector.REACH_PICKS, d._in_use(d.charge)):
		if (s.crowd as Crowd)._grid == null or not (s.crowd as Crowd)._grid.path(p.ground_pos, d.temple_door).is_empty():
			plain = p
			break
	var kept := rules.lantern
	var lantern := ErrandLantern.new()
	rules.lantern = lantern
	var first := d._relief_from_temple(d.temple_door)
	lantern.busy = plain
	var second := d._relief_from_temple(d.temple_door)
	t.check(plain != null and first == plain and second != null and second != plain,
		"the relief is the nearest lay citizen, but not one walking the Lantern's errand (%s, then %s instead)" % [first, second])
	rules.lantern = kept
	# The inquisitors are set aside from the Bearer: reserved, and so left out of his pool even when one has a free mind.
	var all_reserved := true
	for v: Variant in d.inquisitors:
		all_reserved = all_reserved and d.reserved.has(v)
	var spare := d.inquisitors[0] as Person
	spare.mind = Person.Mind.CALM
	var bearer := LanternBearer.new()
	bearer.crowd = s.crowd
	bearer.door = d.temple_door
	bearer._reserved = d.reserved
	var pooled := false
	var rows := bearer._pool()
	for row: Array in rows:
		pooled = pooled or row[2] == spare
	t.check(all_reserved and not rows.is_empty() and not pooled,
		"both inquisitors are in `reserved` and the Bearer's pool (%d free citizens) leaves out one with a free mind" % rows.size())
	Kit.done(s)
	# A place he cannot walk to from where he stands is not sent to: the man goes to the door.
	var w := Kit.world(HuntBook.def(MissionBook.HIDE_FAITHFUL), ShutDirector.new())
	var e: ShutDirector = w.d
	_clear_watch_but_search(e)
	for h: ExodusDirector.Household in e.households:
		h.out = true
		h.done = true
	e._search_at = 3
	var door: Vector2 = e._search[3].door
	var spots: Array[Vector2] = e._door_spots(door, 2)
	var men: Array[Person] = [e.inquisitors[0] as Person, e.inquisitors[1] as Person]
	for m in men:
		Kit.arrive(m, door + Vector2(-6.0, 0.0))
		m.go_duty(door + Vector2(-6.0, 0.0))
		e._set_pace(m, HideFaithfulDirector.HF_SEARCH_PACE)
	for from_man in 2:
		e.blocked.append([men[from_man].ground_pos, spots[0]])  # (the street to the first place is shut from each of them)
	e._order_search()
	var at_shut := false
	var at_door := false
	for m in men:
		at_shut = at_shut or m.anchor.distance_to(spots[0]) < 0.05
		at_door = at_door or m.anchor.distance_to(e._walkable(door)) < 0.05
	t.check(not at_shut and at_door, "a man who cannot walk to his place is sent to the door, not anchored to the place (anchors %s %s, place %s, door %s)" % [men[0].anchor, men[1].anchor, spots[0], door])
	# pair_spots: a place that cannot be walked from to the door, or from the door the search comes from, is not a place of the pair.
	e.blocked.clear()
	var from_door: Vector2 = e._search[2].door
	var base := e.pair_spots(door, 2, from_door)
	e.blocked.append([base[0], door])
	var back := e.pair_spots(door, 2, from_door)
	var kept_back := false
	for q in back:
		kept_back = kept_back or q.distance_to(base[0]) < 0.05
	e.blocked.clear()
	e.blocked.append([from_door, base[0]])
	var shut_in := e.pair_spots(door, 2, from_door)
	var kept_in := false
	for q in shut_in:
		kept_in = kept_in or q.distance_to(base[0]) < 0.05
	t.check(not kept_back and not kept_in, "a place shut from the door, or from the door the search comes from, is left out of the pair (kept: back %s, in %s; %s -> %s -> %s)" % [kept_back, kept_in, base, back, shut_in])
	Kit.done(w)


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
