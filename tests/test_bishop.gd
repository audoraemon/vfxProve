extends RefCounted
## v0.11 M5 The Bishop (mission spec §1, BishopDirector, AssassinateDirector reused): the bishop waits in the Citadel, goes to ground
## in his house at ARRIVE_AT, and moves refuge to refuge indoors, unseen, only when driven out by fire; a refuge ahead is stone; Knights
## (added soldiers, corps KNIGHT) stand at each door and beat out a fire while one is on guard; his escort comes with him; reliefs from
## the Citadel; driven from the Temple he walks the square for the Citadel's gate, ringed by its Knights. His death wins; the gate,
## leaving the town or the Knights at 5:00 lose. The rally and the evacuation pass the Knights and the bishop by (review focus 2);
## freed bodies are borne (review focus 4); the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_no_flush(t)
	_hold(t)
	_ground(t)
	_stone(t)
	_held_door(t)
	_discorded_door(t)
	_smother(t)
	_flight(t)
	_relief(t)
	_square(t)
	_ends(t)
	_evacuate(t)
	_tagged(t)
	_freed(t)


## A Bishop night with no road from the Citadel's gate to any post (v0.11 M5 tests, the controller's ruling: a relief no one can
## reach backs off): it counts its searches for a relief.
class NoRoad:
	extends BishopDirector
	var asked := 0

	func _reaches(_at: Vector2) -> bool:
		asked += 1
		return false


static func _world() -> Dictionary:
	return Kit.world(MissionBook.bishop())


## Every Knight of refuge `i` out of doors killed and freed (v0.11 M5 tests).
static func _clear(s: Dictionary, d: BishopDirector, i: int) -> void:
	for p: BishopDirector.Post in d.posts:
		if not p.done and p.refuge == i and MissionDirector._alive(p.man) and not (p.man as Person).inside:
			Kit.free_body(s, p.man)


## The bishop in refuge `i` now (v0.11 M5 tests): his time brought on, and each refuge before it cleared and left.
static func _to_refuge(s: Dictionary, d: BishopDirector, i: int) -> void:
	d._set_out(d.quarries[0])
	for k in i:
		_clear(s, d, k)
		d._drive_out(k)
		d._reach_refuge(k + 1)


static func _setup(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	t.check(d.refuges.size() == 3 and RuinWish.fits(d.refuges[0], "house") and RuinWish.fits(d.refuges[1], "house")
		and d.refuges[2].role == &"temple" and d.refuges[0].center().distance_to(BishopDirector.REFUGE_SPOTS[0]) < 4.0
		and d.refuges[1].center().distance_to(BishopDirector.REFUGE_SPOTS[1]) < 4.0, "the refuges: his house, the chapter house, the Temple")
	t.check(MissionDirector._alive(q.target) and q.target.profile.role == CitizenProfile.Role.CLERGY and q.target.inside
		and q.target.mind == Person.Mind.DUTY and q.state == AssassinateDirector.State.WAITING and d.at_refuge == -1,
		"the bishop, a cleric, waits inside the Citadel, on duty")
	var ok := true
	var knights := 0
	for i in 3:
		var at := d.standing_at(i)
		knights += at.size()
		ok = ok and at.size() == BishopDirector.STANDING and at[0].ground_pos.distance_to(at[1].ground_pos) > 2.0 * SilentDoom.RADIUS
		for k in at:
			ok = ok and k.soldier and k.corps == Person.Corps.KNIGHT and is_equal_approx(k.health, Person.HEALTH_KNIGHT) \
				and d.refuges[i].distance_to(k.ground_pos) <= BishopDirector.GUARD_REACH
	var escort := 0
	for p: BishopDirector.Post in d.posts:
		escort += 1 if p.escort and MissionDirector._alive(p.man) and (p.man as Person).inside else 0
	t.check(ok and knights == 6 and escort == BishopDirector.ESCORT and d.guards_at(0).size() == 2,
		"two Knights at each refuge's door, one Doom apart, on guard; his escort waits inside with him")
	var eng := (s.crowd as Crowd).engineers
	t.check(eng.hands_off.size() == 3 and eng.hands_off.has(d.refuges[2]), "the town's engineers never mend a refuge")
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["out_0", "taken"], "the strip: he goes to ground, then the Knights take him (%s)" % [ids])
	var clear := true
	for st in d.refuges:
		clear = clear and Kit.clear_of_stack(st.center(), BishopDirector.CAMERA_AT, Kit.STACK)
	for k in [0.0, 0.25, 0.5]:
		clear = clear and Kit.clear_of_stack(d.doors[2].lerp(d.safe_at, k), BishopDirector.CAMERA_AT, Kit.STACK)
	t.check(clear, "the camera keeps the three refuges, the Temple's door and his walk across the square clear of the HUD stack")
	var m := MissionBook.bishop()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and m.dp_capacity == 13 and reasons == ["bishop", "bishop_taken", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "ember"] and MissionBook.get_mission("bishop").id == "bishop",
		"the mission: Tier 4's numbers; the bishop, the Knights, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := true
	for i in 3:
		for k in d.standing_at(i):
			held = held and k.mind == Person.Mind.POST and k.corps == Person.Corps.KNIGHT
	t.check(held and d.quarries[0].target.inside and d.quarries[0].target.mind == Person.Mind.DUTY,
		"the rally, the regroup and the evacuation take no Knight, and the bishop stays inside (review focus 2)")
	Kit.done(s)


static func _ground(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	Kit.run_for(s, BishopDirector.ARRIVE_AT + DT)
	var out := 0
	for p: BishopDirector.Post in d.posts:
		if p.escort and MissionDirector._alive(p.man) and not (p.man as Person).inside and (p.man as Person).anchor == p.spot \
				and (p.man as Person).ground_pos.is_equal_approx(p.spot):
			out += 1
	t.check(d.at_refuge == 0 and q.target.inside and q.target.ground_pos.is_equal_approx(d.refuges[0].center()) and out == BishopDirector.ESCORT
		and (s.banners as Array).has("THE BISHOP GOES TO GROUND") and q.state == AssassinateDirector.State.WAITING,
		"at ARRIVE_AT he goes to ground in his house, unseen; his escort comes out each at his own post, not bunched at the door")
	Kit.done(s)
	var apart := true
	var seen := []
	for i in 3:
		var r := _world()
		var rd: BishopDirector = r.d
		_to_refuge(r, rd, i)
		var spots: Array[Vector2] = []
		for p: BishopDirector.Post in rd.posts:
			if not p.done and p.refuge == i:
				spots.append(p.spot)
		apart = apart and spots.size() == BishopDirector.STANDING + BishopDirector.ESCORT
		for a in spots.size():
			apart = apart and rd.refuges[i].distance_to(spots[a]) <= BishopDirector.GUARD_REACH
			for b in range(a + 1, spots.size()):
				apart = apart and spots[a].distance_to(spots[b]) > 2.0 * SilentDoom.RADIUS
		seen.append(spots.size())
		Kit.done(r)
	t.check(apart, "at each refuge his five Knights hold their own posts within reach of it, two Doom radii from every other: one strike never takes two (%s)" % [seen])


static func _stone(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var chapter := d.refuges[1]
	var hp := chapter.hp
	chapter.damage(40.0, chapter.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(chapter, 0.5)
	Kit.run_for(s, 0.2)
	t.check(is_equal_approx(chapter.hp, hp) and not d._burning(chapter), "a refuge he is not yet in only shakes, and its fire is smothered")
	d.teardown()
	t.check(not chapter.damage_filter.is_valid(), "teardown lets the stone go: it takes blows again")
	Kit.done(s)


static func _smother(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	var house := d.refuges[0]
	(s.crowd as Crowd).fires.ignite(house, 0.5)
	Kit.run_for(s, 1.0)
	t.check(d._burning(house), "in his refuge a fire takes")
	Kit.run_for(s, BishopDirector.SMOTHER_AFTER)
	t.check(not d._burning(house) and d.driven == 0, "a Knight on guard beats it out after SMOTHER_AFTER")
	_clear(s, d, 0)
	(s.crowd as Crowd).fires.ignite(house, 0.5)
	Kit.run_for(s, BishopDirector.DRIVE_OUT + 0.5)
	t.check(d.driven == 1 and d.in_flight and d.at_refuge == 1 and d.quarries[0].target.inside
		and (s.banners as Array).has("THE BISHOP FLEES HIS HOUSE"), "with none on guard, DRIVE_OUT seconds alight drive him out, unseen")
	t.check(absf(d.timeline.seconds_to("arrive_1") - BishopDirector.CHAIN) < 1.0 and d.hint_phase() == "waiting"
		and absf(d.hint_seconds() - BishopDirector.CHAIN) < 1.0, "the strip and the hint count down to his next refuge, CHAIN on")
	Kit.done(s)


static func _flight(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	var standing: Array = []
	for p: BishopDirector.Post in d.posts:
		if not p.escort and p.refuge == 0:
			standing.append(p.man)
	d.refuges[0].destroy(d.refuges[0].center(), &"smite")
	Kit.run_for(s, 0.1)
	var home := true
	for v: Variant in standing:
		home = home and (v as Person).anchor.is_equal_approx(d.hide_door)
	t.check(d.in_flight and d.driven == 1 and home, "his house down drives him out too; its Knights go home to the Citadel")
	Kit.run_for(s, BishopDirector.CHAIN - 1.0)
	t.check(d.in_flight and d.at_refuge == 1, "a second short of CHAIN he is still on his way")
	Kit.run_for(s, 1.0 + DT)
	var out := 0
	for p: BishopDirector.Post in d.posts:
		if p.escort and not p.done and p.refuge == 1 and MissionDirector._alive(p.man) and not (p.man as Person).inside:
			out += 1
	t.check(not d.in_flight and d.at_refuge == 1 and out == BishopDirector.ESCORT and (s.banners as Array).has("THE BISHOP REACHES THE CHAPTER HOUSE"),
		"CHAIN after he was driven out he reaches the chapter house, his escort beside him")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var post: BishopDirector.Post = null
	for p: BishopDirector.Post in d.posts:
		if not p.escort and p.refuge == 1:
			post = p
			break
	var dead: Variant = post.man
	Kit.free_body(s, dead)
	Kit.run_for(s, BishopDirector.RELIEF_AFTER + 1.0)
	var k: Variant = post.man
	t.check(k != dead and MissionDirector._alive(k) and (k as Person).corps == Person.Corps.KNIGHT and (k as Person).anchor == post.spot
		and (k as Person).ground_pos.distance_to(d.hide_door) < 1.5 and post.relief and d.reliefs == 1
		and d.relief_walking() == k, "RELIEF_AFTER after a standing Knight falls, a new one walks from the Citadel's gate to his post")
	d.reliefs = BishopDirector.RELIEFS
	var other: Variant = null
	for p: BishopDirector.Post in d.posts:
		if not p.escort and p.refuge == 2:
			other = p.man
			break
	Kit.free_body(s, other)
	Kit.run_for(s, BishopDirector.RELIEF_AFTER + 1.0)
	t.check(d.reliefs == BishopDirector.RELIEFS and d.standing_at(2).size() == 1, "RELIEFS at most in a night")
	Kit.done(s)
	var n := Kit.world(MissionBook.bishop(), NoRoad.new())
	var nd: NoRoad = n.d
	var lost: BishopDirector.Post = null
	for p: BishopDirector.Post in nd.posts:
		if not p.escort and p.refuge == 1:
			lost = p
			break
	Kit.free_body(n, lost.man)
	Kit.run_for(n, 2.0 * BishopDirector.RELIEF_AFTER + 1.0)
	t.check(nd.reliefs == 0 and nd.asked == 2 and lost.fallen < BishopDirector.RELIEF_AFTER,
		"with no road from the Citadel to the post, the relief backs off and is tried again RELIEF_AFTER later (%d)" % nd.asked)
	Kit.done(n)


static func _square(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	_to_refuge(s, d, 2)
	_clear(s, d, 2)
	(s.crowd as Crowd).fires.ignite(d.refuges[2], 0.5)
	Kit.run_for(s, BishopDirector.DRIVE_OUT_TEMPLE + 0.6)
	var ringed := q.guards.size() == 2
	for v: Variant in q.guards:
		var gap := (v as Person).anchor.distance_to(q.target.ground_pos)
		ringed = ringed and gap > SilentDoom.RADIUS and gap < Crowd.DOOM_WITNESS
	t.check(d.in_square and not q.target.inside and q.state == AssassinateDirector.State.WALKING and q.target.mind == Person.Mind.DUTY
		and q.target.anchor.is_equal_approx(d.safe_at) and ringed and d.hint_phase() == "square"
		and (s.banners as Array).has("THE BISHOP IS DRAWN INTO THE SQUARE"),
		"driven from the Temple he walks for the Citadel's gate, two Knights ringing him beyond one Doom")
	t.check(Kit.labels(d).slice(0, 2) == ["BISHOP", "CITADEL"] and Kit.edged(d, "BISHOP") and Kit.edged(d, "CITADEL")
		and ((s.rules as Rules).objectives[0] as Objective).hud_text(s.rules) == "Kill the bishop, he makes for the Citadel",
		"in the square: BISHOP and CITADEL, pointed at; the HUD says so")
	var walk := q.target.pace
	(s.crowd as Crowd).on_cast(q.target.ground_pos, Vector2.ZERO, 0.0, "smite")
	Kit.run_for(s, PowerBook.IMPACT.smite + 0.1)  # v0.11.2: at the impact
	t.check(q.state == AssassinateDirector.State.FLEEING and q.target.pace > walk and d.hint_phase() == "running"
		and Kit.labels(d)[0] == "BISHOP - RUNNING", "a loud power by him sends him running for it, at his own pace")
	Kit.arrive(q.target, d.safe_at)
	Kit.run_for(s, 0.6)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.any_safe() and main.check(s.rules) == Objective.Status.FAILED and main.reason == "bishop_safe"
		and (s.banners as Array).has("THE BISHOP REACHES THE CITADEL"), "the gate reached: the night is lost")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	_to_refuge(s, d, 2)
	d._drive_out(2)
	(s.crowd as Crowd)._field.kill(q.target, &"doom")
	Kit.run_for(s, 0.1)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.all_fallen() and main.check(s.rules) == Objective.Status.DONE and main.reason == "bishop"
		and (s.banners as Array).has("THE KNIGHTS CRY MURDER"), "his death wins, seen by his Knights: they cry murder")
	Kit.done(s)
	var n := _world()
	var taken: Objective = (n.rules as Rules).objectives[1]
	t.check(taken.hud_text(n.rules) == "Knights come 5:00", "the deadline row (%s)" % taken.hud_text(n.rules))
	(n.d as BishopDirector).timeline.step(BishopDirector.TAKEN_AT + DT)
	t.check(taken.check(n.rules) == Objective.Status.FAILED and taken.reason == "bishop_taken" and (n.banners as Array).has("THE KNIGHTS TAKE HIM AWAY"),
		"left alone, the Knights take him away at 5:00")
	Kit.done(n)
	var g := _world()
	var gq := (g.d as BishopDirector).quarries[0]
	(g.crowd as Crowd)._field.remove(gq.target)
	(g.crowd as Crowd).citizens.erase(gq.target)
	gq.target.free()
	Kit.run_for(g, 0.1)
	t.check((g.d as BishopDirector).any_safe(), "his body gone without his death (out of the town): he got away, at once")
	Kit.done(g)


static func _evacuate(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	_to_refuge(s, d, 0)
	d._drive_out(0)
	var due := d.arrive_at
	Kit.evacuate(s)
	Kit.run_for(s, 0.6)
	var posted := true
	for k in d.standing_at(1):
		posted = posted and k.mind == Person.Mind.POST
	t.check(posted and q.target.inside and d.in_flight, "the evacuation in his flight: the next refuge's Knights hold, he stays inside")
	Kit.run_for(s, due - d._clock + DT)
	t.check(d.at_refuge == 1 and not d.in_flight, "and he arrives on time")
	Kit.done(s)
	var w := _world()
	var wd: BishopDirector = w.d
	var wq := wd.quarries[0]
	_to_refuge(w, wd, 2)
	wd._drive_out(2)
	var bishop := wq.target
	bishop.whisper(bishop.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	var knight := wq.guards[0] as Person
	Kit.evacuate(w)
	t.check(bishop._whisper_fled, "(set-up) the evacuation owes the whispered bishop a flight")
	Kit.run_for(w, 0.6)
	t.check(not bishop._whisper_fled and bishop.mind == Person.Mind.WHISPERED and knight.mind == Person.Mind.POST,
		"at the first look after it his flight is ended; his ring holds")
	bishop._wake()
	bishop.mind = Person.Mind.RECOVER
	Kit.run_for(w, 0.6)
	t.check(bishop.mind == Person.Mind.DUTY and bishop.anchor.is_equal_approx(wd.safe_at),
		"back on his feet he walks for the Citadel again, not for the gates")
	Kit.done(w)
	var r := _world()
	var rd: BishopDirector = r.d
	var rq := rd.quarries[0]
	_to_refuge(r, rd, 2)
	rd._drive_out(2)
	var shaken := rq.target
	shaken._recover(1.0)
	Kit.evacuate(r)
	t.check(shaken.mind == Person.Mind.FLEE, "(set-up) the evacuation sends the recovering bishop running")
	Kit.run_for(r, 0.6)
	t.check(shaken.mind == Person.Mind.DUTY and shaken.anchor.is_equal_approx(rd.safe_at) and rq.state == AssassinateDirector.State.WALKING
		and (r.crowd as Crowd).citizens.has(shaken), "at the first look he is stopped and walks for the Citadel again, unalarmed, still in town")
	Kit.done(r)


static func _tagged(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var labels := Kit.labels(d)
	var comes := "NEXT REFUGE - HE COMES IN %s" % UiTheme.clock(BishopDirector.ARRIVE_AT)
	t.check(labels.slice(0, 2) == ["BISHOP - IN THE CITADEL", comes] and labels.has("KNIGHT")
		and Kit.edged(d, comes) and Kit.edged(d, "BISHOP - IN THE CITADEL") and d.hint_phase() == "waiting"
		and is_equal_approx(d.hint_seconds(), BishopDirector.ARRIVE_AT),
		"before ARRIVE_AT: in the Citadel (grey, an edge tag, so the HUD's keepout keeps it); his house next, pointed at (%s)" % [labels.slice(0, 2)])
	_to_refuge(s, d, 0)
	t.check(Kit.labels(d).slice(0, 2) == ["REFUGE - GUARDED", "NEXT REFUGE"] and d.hint_phase() == "guarded"
		and Kit.edged(d, "REFUGE - GUARDED") and Kit.edged(d, "NEXT REFUGE"),
		"in his house: guarded, the chapter house next")
	_clear(s, d, 0)
	t.check(Kit.labels(d)[0] == "REFUGE - SET IT ALIGHT" and d.hint_phase() == "open" and Kit.edged(d, "REFUGE - SET IT ALIGHT"),
		"none on guard: set it alight, pointed at")
	(s.crowd as Crowd).fires.ignite(d.refuges[0], 0.5)
	Kit.run_for(s, 1.2)
	t.check(Kit.labels(d)[0] == "REFUGE - BURNING %d" % ceili(BishopDirector.DRIVE_OUT - 1.2) and d.hint_phase() == "burning"
		and Kit.edged(d, Kit.labels(d)[0])
		and ((s.rules as Rules).objectives[0] as Objective).hud_text(s.rules) == "Kill the bishop: refuges 0 / 3",
		"burning, its seconds counted down, pointed at; the HUD's count (%s)" % Kit.labels(d)[0])
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("His house. The bishop goes to ground here at %s" % UiTheme.clock(BishopDirector.ARRIVE_AT))
		and String(tour[2][1]).ends_with("draw him into the square."), "the tour: his house, the chapter house, the Temple")
	t.check(ResultsScreen.ACT_TITLES.get("bishop") == "THE BISHOP IS DEAD" and ResultsScreen.ACT_TITLES.get("bishop_safe") == "THE BISHOP REACHES THE CITADEL"
		and ResultsScreen.ACT_TITLES.get("bishop_taken") == "THE KNIGHTS TAKE HIM AWAY", "its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	for i in 3:
		_clear(s, d, i)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.guards_at(0).is_empty() and d.hint_phase() == "open" and int(d.report().refuges) == 0,
		"every Knight freed: the tags, hint and report bear it (review focus 4)")
	Kit.free_body(s, d.quarries[0].target)
	Kit.run_for(s, 0.1)
	d.tags()
	t.check(d.all_fallen() and d.hint_phase() == "" and d.tags().is_empty() and String(d.report().target) != "",
		"his body freed too: nothing touches it")
	Kit.done(s)


## v0.11.1: the Bishop has no hideout to empty and keeps the base's rule (flush_waiting false).
static func _no_flush(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	t.check(not d.flush_waiting and d.hideout == null and d.quarries[0].state == AssassinateDirector.State.WAITING,
		"the Bishop keeps the base's rule: nothing to flush, the waiting bishop stays put")
	Kit.done(s)


## v0.11.1 (R6; mission spec §7.2 row 17): the refuge he is in is held by the Knights at its door -- a blow only shakes it while one
## stands guard, and it takes blows as any building does once none does; fire is not a blow.
static func _held_door(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	Kit.run_for(s, 0.6)
	var house := d.refuges[0]
	var hp := house.hp
	t.check(not d.guards_at(0).is_empty(), "(set-up) Knights stand at his door")
	house.damage(30.0, house.center(), &"lightning")
	t.check(is_equal_approx(house.hp, hp), "a blow only shakes it while a Knight stands guard")
	house.damage(10.0, house.center(), &"fire")
	t.check(house.hp < hp, "a fire is not turned aside: the Knights beat it out themselves")
	hp = house.hp
	_clear(s, d, 0)
	Kit.run_for(s, 0.6)
	house.damage(30.0, house.center(), &"lightning")
	t.check(d.guards_at(0).is_empty() and house.hp < hp, "with none on guard it takes the blow")
	Kit.done(s)


## v0.11.1 (R8, final review I1): a Knight the god holds -- Discorded, whispered, bound -- is off guard, as in the Armoury: the refuge takes
## the blow, and he stands guard again once the hold ends. The refuge's own damage filter is put back when the seal comes off (M9).
static func _discorded_door(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	Kit.run_for(s, 0.6)
	var house := d.refuges[0]
	var knights := d.guards_at(0)
	var n := knights.size()
	t.check(n >= 2 and house.damage_filter == Callable(d, "_guard_hit"), "(set-up) Knights stand guard and the refuge is sealed")
	knights[0].confuse(8.0)
	t.check(d.guards_at(0).size() == n - 1, "one Knight Discorded: he no longer stands guard")
	for k in knights:
		k.confuse(8.0)
	Kit.run_for(s, 0.6)
	t.check(d.guards_at(0).is_empty() and house.damage_filter == Callable(), "all Discorded: none on guard, the seal is off, the original filter back")
	var hp := house.hp
	house.damage(30.0, house.center(), &"lightning")
	t.check(house.hp < hp, "and the refuge takes the blow")
	Kit.done(s)
