extends RefCounted
## v0.11 M4 the groundwork for Tier 3's new missions, each shared change shown to keep today's path when left alone (review focus 1):
## Tier 3's frame; MissionDirector._recall_to() and _lay_reaching(); EngineerManager.hands_off and not_hired; EscortDirector's hooks,
## each handed the charge it acts for (review focus 3), the bound charge, hunt_after_free, lost_reason() and hud_line(), which
## EscortObjective reads; and the Hunt type (HuntDirector, HuntObjective) on two drills, one shaped like M6's The Lantern's Eye
## (review focus 2).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


## The Lost Lamb with a spy on its hooks (v0.11 M4): each records the charge it was handed.
class Spy:
	extends LostLambDirector
	var handed: Array = []

	func _in_use(c: Person) -> Array:
		handed.append(["in_use", c])
		return super(c)

	func _appoint_watch(c: Person, n: int) -> Array[Person]:
		handed.append(["watch", c])
		return super(c, n)

	func _appoint_patrol(c: Person, beat: PackedVector2Array, n: int) -> Array[Person]:
		handed.append(["patrol", c])
		return super(c, beat, n)

	func _appoint_hunters(c: Person, n: int) -> Array[Person]:
		handed.append(["hunters", c])
		return super(c, n)


## The Lost Lamb bound to a stall beside him (v0.11 M4): freed by its fall, lost if still bound at 20 s, the searchers 5 s after
## the freeing; its own loss and HUD line.
class Bound:
	extends LostLambDirector
	var stall: Structure

	func _plan() -> void:
		super()
		var at := _walkable(START + Vector2(0.0, -1.2))
		stall = crowd._env.add_structure(Rect2(at - Vector2(0.3, 0.2), Vector2(0.6, 0.4)), 10.0, Structure.Kind.MARKET_STALL,
			&"stocks")
		town._built.append(stall)
		bound_by = stall
		free_by = 20.0
		hunt_at = -1.0
		hunt_after_free = 5.0

	func lost_reason() -> String:
		return "inside" if bound_lost else ""

	func hud_line() -> String:
		return "Free him" if bound else ""


## A small hunt (v0.11 M4): two steps at 10 s and 40 s with a 15 s chain, parties of two, a head out at 60 s walking one door and
## then to a fixed quarry, with one escort.
class Drill:
	extends HuntDirector

	func _plan() -> void:
		chain = 15.0
		head_at = 60.0
		head_stop = 1.0
		head_door = Vector2(0.8, -5.0)
		steps.append(_step("the market", Vector2(1.5, 2.0), Rect2(), 10.0, 2))
		steps.append(_step("the south street", Vector2(-4.0, 9.0), TownLayout.DISTRICTS[7], 40.0, 2))

	func _appoint_head() -> Person:
		var near := _lay_near(_walkable(head_door), 1, _in_use())
		if near.is_empty():
			return null
		_take_inside(near[0], null)
		return near[0]

	func _appoint_escorts() -> Array:
		var out: Array = []
		for p in _lay_near(_walkable(head_door), 1, _in_use()):
			_dress_guard(p)
			p.go_duty(p.ground_pos)
			_take_inside(p, null)
			out.append(p)
		return out

	func _head_route() -> Array[Vector2]:
		var out: Array[Vector2] = [_walkable(Vector2(0.8, 0.0)), _quarry_point()]
		return out

	func _quarry_point() -> Vector2:
		return _walkable(Vector2(0.8, 3.0))


## The Lantern's Eye's shape (v0.11 M4, review focus 2): no head; each standard an existing wall tower, and a third step with none.
class Towered:
	extends HuntDirector
	var towers: Array[Structure] = []

	func _plan() -> void:
		has_head = false
		for s: Structure in town._built:
			if is_instance_valid(s) and s.role == &"tower" and s.art_tag != &"bell_tower" and towers.size() < 2:
				towers.append(s)
		for k in towers.size():
			steps.append(_step("tower %d" % k, _front_of(towers[k]), Rect2(), 5.0 + 5.0 * float(k), 1))
		steps.append(_step("nowhere", Vector2(0.0, 2.0), Rect2(), 15.0, 1))

	func _raise_standard(i: int) -> Structure:
		return towers[i] if i < towers.size() else null

	func _quarry_point() -> Vector2:
		return Vector2(0.0, 2.0)


static func run(t) -> void:
	_frame(t)
	_recall(t)
	_recall_flight(t)
	_hold_all(t)
	_hands_off(t)
	_lamb_as_before(t)
	_hooks_take_the_charge(t)
	_bound(t)
	_hunt_drill(t)
	_hunt_head(t)
	_hunt_towered(t)
	_hunt_evacuation(t)
	_hunt_no_captain_time(t)
	_hunt_pre_destroyed(t)
	_hunt_relief_in_flight(t)
	_hunt_relief_backs_off(t)
	_bound_both(t)


static func _probe() -> MissionDef:
	var m := MissionBook._tier3("probe", "The Probe", PackedStringArray(["One.", "Two."]))
	m.default_loadout = PackedStringArray(["doom"])
	return m


static func _frame(t) -> void:
	var m := MissionBook._tier3("probe", "The Probe", PackedStringArray(["One.", "Two."]))
	t.check(m.tier == 3 and is_equal_approx(m.clock, 360.0) and m.slots == 4 and m.dp_capacity == 10 and m.tier_floor == 3
		and m.profile == "" and m.intro_banner == "THE PROBE" and m.bonuses().is_empty()
		and m.response_profile(ResponseProfile.DEFAULT).tier_name() == "Prepared",
		"Tier 3's frame: 6:00, 4 / 10, a Prepared town by tier_floor and no profile, no bonuses, the name in capitals")
	t.check(MissionBook.CROWNS_BREAD == "crowns_bread" and MissionBook.PRISONER == "prisoner" and MissionBook.HERETIC_HUNT == "heretic_hunt",
		"the three ids")


static func _recall(t) -> void:
	var s := Kit.world(_probe(), MissionDirector.new())
	var d: MissionDirector = s.d
	var post := d._walkable(Vector2(0.0, 6.0))
	var a := d._lay_near(Vector2(0.0, 8.0), 3)
	d._recall_to(a[0], post)
	a[1].panic(a[1].ground_pos + Vector2(0.4, 0.0), 1.0)
	d._recall_to(a[1], post)
	d._take_inside(a[2], null)
	d._recall_to(a[2], post)
	t.check(a[0].mind == Person.Mind.DUTY and a[0].anchor == post and a[1].mind != Person.Mind.DUTY and a[2].mind != Person.Mind.DUTY,
		"_recall_to(): one back on his feet goes on duty to his place; one frightened or indoors is left be")
	var gone: Variant = a[0]
	Kit.free_body(s, gone)
	d._recall_to(gone, post)
	var r := d._lay_reaching(post, [a[1]])
	t.check(r != null and r != a[1] and not (s.crowd as Crowd)._grid.path(r.ground_pos, post).is_empty(),
		"a freed body is passed by; _lay_reaching(): the nearest lay citizen with a way there, none excluded")
	Kit.done(s)


static func _recall_flight(t) -> void:
	var s := Kit.world(_probe(), MissionDirector.new())
	var d: MissionDirector = s.d
	var post := d._walkable(Vector2(0.0, 6.0))
	var a := d._lay_near(Vector2(0.0, 8.0), 2)
	a[0].flee()
	d._recall_to(a[0], post)
	t.check(a[0].mind == Person.Mind.FLEE, "_recall_to() with no evacuation leaves a man already running be (a god's own flight)")
	d._recall_to(a[0], post, true)
	t.check(a[0].mind == Person.Mind.DUTY and a[0].anchor == post,
		"at the first look after the town evacuates, one it sent running is called back on duty (the shared rule, _keep_from_flight())")
	a[1].whisper(a[1].ground_pos + Vector2(2.0, 0.0), MindWhisperFx.LINGER)
	a[1]._whisper_fled = true
	d._recall_to(a[1], post, true)
	t.check(a[1].mind == Person.Mind.WHISPERED and not a[1]._whisper_fled,
		"a whisper the evacuation found him under ends with him on his feet, not running for the gates")
	Kit.done(s)


## The one held-people rule (v0.11 M4, the final review's ruling, MissionDirector._hold_all()), shared by The Crown's Bread, The Prisoner
## and the Hunt type: at the evacuation's first look one it sent running stops, indoors or out; a whisper's owed flight ends; a false
## calm's owed flight is let go; a freed body is passed by; with no evacuation a man already running is let be.
static func _hold_all(t) -> void:
	var s := Kit.world(_probe(), MissionDirector.new())
	var d: MissionDirector = s.d
	var a := d._lay_near(Vector2(0.0, 8.0), 5)
	a[0].flee()
	a[1].whisper(a[1].ground_pos + Vector2(2.0, 0.0), MindWhisperFx.LINGER)
	a[1]._whisper_fled = true
	a[2].fearless_left = 5.0
	a[2].flee()
	d._take_inside(a[3], null)
	a[3].flee()
	var gone: Variant = a[4]
	Kit.free_body(s, gone)
	t.check(a[0].mind == Person.Mind.FLEE and a[2]._reassured_fled and a[2].mind != Person.Mind.FLEE and a[3].mind == Person.Mind.FLEE,
		"(set-up) one running, one whispered owing a flight, one calmed owing a flight, one indoors running")
	MissionDirector._hold_all([a[0], a[1], a[2], a[3], gone], false)
	t.check(a[0].mind == Person.Mind.FLEE and not a[1]._whisper_fled and not a[2]._reassured_fled,
		"no evacuation: a man already running is let be (a god's own flight); the whisper's and the false calm's owed flights end")
	a[2]._reassured_fled = true
	MissionDirector._hold_all([a[0], a[1], a[2], a[3], gone], true)
	t.check(a[0].mind == Person.Mind.CALM and a[3].mind == Person.Mind.CALM and not a[2]._reassured_fled and a[1].mind == Person.Mind.WHISPERED,
		"at the evacuation's first look the running are stopped, indoors or out, back on their feet; a freed body is passed by")
	Kit.done(s)


static func _job_targets(eng: EngineerManager) -> Array:
	var out := []
	for j: Dictionary in eng.jobs():
		out.append(j.target)
	return out


static func _hands_off(t) -> void:
	var s := Kit.world(_probe(), MissionDirector.new())
	var eng: EngineerManager = (s.crowd as Crowd).engineers
	var bridge: Structure = (s.town as Town).bridge
	bridge.damage(bridge.max_hp * 0.5, bridge.center(), &"blast")
	t.check(eng.hands_off.is_empty() and eng.not_hired.is_empty() and _job_targets(eng).has(bridge),
		"by default the town's teams mend a damaged bridge (hands_off and not_hired empty)")
	eng.hands_off.append(bridge)
	t.check(not _job_targets(eng).has(bridge), "a structure in hands_off gets no job")
	bridge.destroy(bridge.center(), &"blast")
	t.check(not _job_targets(eng).has(bridge), "nor is it rebuilt once fallen")
	var hire: Person = (s.d as MissionDirector)._lay_near(Vector2.ZERO, 1)[0]
	hire.profile.role = CitizenProfile.Role.ENGINEER
	var hired := eng._recruit(2)
	t.check(hired.size() == 2 and hired.has(hire), "by default the workshop hires an engineer off a team first (two hired)")
	hire.profile.role = CitizenProfile.Role.ENGINEER
	eng.not_hired.append(hire)
	var passed := eng._recruit(2)
	t.check(passed.size() == 2 and not passed.has(hire), "one in not_hired is never hired (two others are)")
	Kit.done(s)


static func _lamb_as_before(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb())
	var d: LostLambDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	var soldiers := not d._watchers().is_empty()
	for v: Variant in d._watchers():
		soldiers = soldiers and (v as Person).soldier and (v as Person).mind == Person.Mind.POST
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(soldiers and d.watch.size() == 2 and d.patrols.size() == 2 and not d.bound and d.bound_by == null and d.free_by < 0.0
		and d.hunt_after_free < 0.0 and d.lost_reason() == "" and d.hud_line() == "" and ids == ["bolt", "hunt"]
		and main.hud_text(s.rules) == "Lead the acolyte out" and main.check(s.rules) == Objective.Status.PENDING,
		"The Lost Lamb's as before: soldiers at their posts, never bound, his bolt (god T1R) and the searchers on the clock, its own HUD line (%s)" % [ids])
	var watching := d._watchers()
	d._hunt()
	var fresh := d.hunters.size() == LostLambDirector.HUNTERS
	for h: Variant in d.hunters:
		fresh = fresh and (h as Person).soldier and not watching.has(h) and (h as Person).mind == Person.Mind.DUTY
	t.check(fresh, "the searchers: free soldiers from their posts, none already watching, sent after him")
	Kit.done(s)


static func _hooks_take_the_charge(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb(), Spy.new())
	var d: Spy = s.d
	d._hunt()
	var kinds := {}
	var all := true
	for h: Array in d.handed:
		kinds[h[0]] = true
		all = all and h[1] == d.charge
	t.check(kinds.has("in_use") and kinds.has("watch") and kinds.has("patrol") and kinds.has("hunters") and all,
		"every new hook is handed the charge it acts for (review focus 3: Exodus) (%s)" % [kinds.keys()])
	Kit.done(s)


static func _bound(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb(), Bound.new())
	var d: Bound = s.d
	var him := d.charge
	var o := EscortObjective.new("Lead him out", "out", "taken", "dead")
	var sol := (d.patrols[0] as Array)[0] as Person
	Kit.arrive(sol, him.ground_pos + Vector2(1.0, 0.0))
	Kit.run_for(s, 0.5)
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(d.bound and not d.held and not him.whisper(him.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
		and not him.lure(him.ground_pos + Vector2(2.0, 0.0), 5.0) and o.hud_text(s.rules) == "Free him" and ids == ["inside"],
		"bound: no soldier seizes him, a whisper and a lure do nothing, the director's HUD line, the deadline on the strip (%s)" % [ids])
	him.panic(him.ground_pos + Vector2(0.4, 0.0), 1.0)
	t.check(him.mind == Person.Mind.DUTY, "bound, he is past fear: a fright does not run him off")
	Kit.arrive(sol, him.ground_pos + Vector2(8.0, 0.0))
	d.stall.destroy(d.stall.center(), &"blast")
	Kit.run_for(s, 0.5)
	var hunt_in := d.timeline.seconds_to("hunt")
	t.check(not d.bound and d.freed_at > 0.0 and (s.banners as Array).has("HE BREAKS FREE") and hunt_in > 4.0 and hunt_in <= 5.0
		and o.hud_text(s.rules) == "Lead him out" and him.whisper(him.ground_pos + Vector2(2.0, 0.0), MindWhisperFx.LINGER),
		"the stall down frees him: the banner, the searchers on the strip 5 s on (%.1f), the label back, a whisper takes" % hunt_in)
	Kit.run_for(s, 5.0)
	t.check(not d.hunters.is_empty(), "the searchers set out 5 s after the freeing")
	Kit.done(s)
	var b := Kit.world(MissionBook.lost_lamb(), Bound.new())
	var bd: Bound = b.d
	var o2 := EscortObjective.new("Lead him out", "out", "taken", "dead")
	Kit.run_for(b, 20.0 + 0.3)
	t.check(bd.bound_lost and o2.check(b.rules) == Objective.Status.FAILED and o2.reason == "inside"
		and (b.banners as Array).has("TAKEN INSIDE"), "still bound at free_by: lost, under the director's own reason")
	Kit.done(b)


static func _hunt_drill(t) -> void:
	var s := Kit.world(_probe(), Drill.new())
	var d: Drill = s.d
	var ok := d.steps.size() == 2 and d.standards.is_empty() and d.standard(0) == null
	for st: HuntDirector.HuntStep in d.steps:
		ok = ok and st.party.size() == 2
		for g: HuntDirector.Guard in st.party:
			var p := g.man as Person
			ok = ok and p.mind == Person.Mind.DUTY and p.ground_pos.distance_to(g.post) < 0.1 and p.profile.role == CitizenProfile.Role.WATCHMAN
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ok and (d.head as Person).inside and not d.head_out and ids == ["step_0", "step_1", "head"],
		"the parties on duty at their posts from the start, watchmen; no standard yet; the head indoors; the strip (%s)" % [ids])
	Kit.run_for(s, 10.0 + DT)
	var std := d.standard(0)
	t.check(std != null and std.role == HuntDirector.STANDARD_ROLE and d.guarded(0) and d.hint_phase() == "guarded"
		and Kit.labels(d).has("STANDARD - GUARDED") and Kit.labels(d).has("GUARD"), "raised at its time, guarded by its party")
	std.damage(45.0, std.center(), &"smite")
	t.check(not std.destroyed and is_equal_approx(std.hp, std.max_hp), "guarded, a blow only shakes it")
	for g: HuntDirector.Guard in d.steps[0].party:
		Kit.arrive(g.man as Person, g.post + Vector2(4.0, 0.0))
	t.check(not d.guarded(0) and d.hint_phase() == "open", "its party off it: open")
	std.damage(45.0, std.center(), &"smite")
	var home := (d.steps[0].party[0] as HuntDirector.Guard).man as Person
	t.check(d.broken(0) and d.broken_count() == 1 and (s.banners as Array).has("A STANDARD FALLS") and home.mind != Person.Mind.DUTY
		and d.timeline.seconds_to("step_1") <= 15.1, "unguarded, one blow breaks it for good; its party goes home; the next step chained")
	var body: Variant = (d.steps[1].party[0] as HuntDirector.Guard).man
	Kit.free_body(s, body)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 15.0 + DT)
	t.check(d.steps[1].raised and d.standard(1) != null and d.hint_phase() in ["guarded", "open"],
		"the chain raises the next 15 s after; a freed guard is borne (review focus 5)")
	Kit.run_for(s, HuntDirector.TICK + 30.0)
	var relief: Variant = (d.steps[1].party[0] as HuntDirector.Guard).man
	t.check(relief != body and MissionDirector._alive(relief) and (relief as Person).profile.role == CitizenProfile.Role.WATCHMAN,
		"a fallen guard is replaced relief_after on")
	Kit.done(s)


static func _hunt_head(t) -> void:
	var s := Kit.world(_probe(), Drill.new())
	var d: Drill = s.d
	d._call_head()
	t.check(not d.head_out and (d.head as Person).inside, "the head never comes before every standard is raised")
	d._raise(0)
	d._raise(1)
	Kit.run_for(s, 0.1)
	var head := d.head as Person
	t.check(d.head_out and not head.inside and head.mind == Person.Mind.DUTY and Kit.labels(d).has("CAPTAIN")
		and d.hint_phase() == "guarded", "once both are raised, the head called earlier comes out, on duty, tagged; a standing standard leads the hint")
	Kit.arrive(head, d.head_route[0])
	Kit.run_for(s, d.head_stop + 0.3)
	t.check(d.searching and d._route_at == 1 and d.hint_phase() == "guarded", "he searches a door head_stop, then walks on")
	Kit.arrive(head, d.head_route[1])
	Kit.run_for(s, 0.1)
	var o := HuntObjective.new("Break the drill", "drill")
	t.check(d.found and o.check(s.rules) == Objective.Status.FAILED and o.reason == "found", "at the quarry he finds it: lost")
	Kit.done(s)
	var w := Kit.world(_probe(), Drill.new())
	var wd: Drill = w.d
	wd._raise(0)
	wd._raise(1)
	for i in 2:
		for g: HuntDirector.Guard in wd.steps[i].party:
			Kit.arrive(g.man as Person, g.post + Vector2(4.0, 0.0))
		wd.standard(i).damage(100.0, wd.standard(i).center(), &"smite")
	var o2 := HuntObjective.new("Break the drill", "drill")
	t.check(wd.broken_all() and not wd.head_down() and o2.check(w.rules) == Objective.Status.PENDING
		and o2.hud_text(w.rules) == "Break the drill: standards 2 / 2", "every standard broken, the head alive: not yet")
	wd._call_head()
	Kit.run_for(w, 0.1)
	t.check(o2.hud_text(w.rules) == "Break the drill: standards 2 / 2, kill the captain", "the HUD names the head once he is out")
	(w.crowd as Crowd)._field.kill(wd.head as Person, &"doom")
	t.check(wd.head_fell and wd.head_down() and o2.check(w.rules) == Objective.Status.DONE and o2.reason == "drill",
		"his death, any death: the hunt is broken")
	Kit.done(w)


static func _hunt_towered(t) -> void:
	var s := Kit.world(_probe(), Towered.new())
	var d: Towered = s.d
	var built := (s.town as Town)._built.size()
	var own := func(_s: Structure, _a: float, _src: Vector2, _k: StringName) -> void: pass
	d.towers[1].damage_filter = own
	Kit.run_for(s, 15.0 + DT)
	var tw := d.towers[0]
	t.check(d.towers.size() == 2 and d.head_down() and d.standard(0) == tw and tw.damage_filter.is_valid()
		and (s.town as Town)._built.size() == built and d.broken(2),
		"no head is down; an existing tower returned as a standard is shielded, not built again; a step with none counts broken")
	for g: HuntDirector.Guard in d.steps[0].party:
		Kit.arrive(g.man as Person, g.post + Vector2(5.0, 0.0))
	tw.damage(tw.max_hp + 1.0, tw.center(), &"smite")
	var o := HuntObjective.new("Break the eye", "eye")
	t.check(d.broken(0) and not d.broken_all() and o.check(s.rules) == Objective.Status.PENDING, "one tower down, one standing")
	var other := d.towers[1]
	d.teardown()
	t.check(other.damage_filter == own and not tw.damage_filter.is_valid() and not other.broken.is_connected(d._on_broken),
		"teardown puts back a borrowed tower's own filter (none: it takes blows again) and lets go of the signal")
	Kit.done(s)


## The hunt through the evacuation (v0.11 M4, the controller's ruling): a guard recovering, a captain whispered and his escort
## recovering when the town evacuates are not lost to the flight; a captain who waited indoors through it still walks his route.
static func _hunt_evacuation(t) -> void:
	var s := Kit.world(_probe(), Drill.new())
	var d: Drill = s.d
	d._raise(0)
	d._raise(1)
	d._call_head()
	Kit.run_for(s, 0.6)
	var head := d.head as Person
	var escort := d.escorts[0] as Person
	var guard := (d.steps[0].party[0] as HuntDirector.Guard).man as Person
	var away_g: HuntDirector.Guard = d.steps[1].party[0]
	var away := away_g.man as Person
	Kit.arrive(away, away_g.post + Vector2(4.0, 0.0))
	away.mind = Person.Mind.CALM
	Kit.run_for(s, 0.6)
	t.check(away.mind == Person.Mind.CALM and away_g.away > 0.0 and away_g.away < d.return_after,
		"(set-up) a guard away from his post, calm, not yet due back")
	guard.mind = Person.Mind.RECOVER
	escort.mind = Person.Mind.RECOVER
	head.whisper(head.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(s)
	t.check(guard.mind == Person.Mind.FLEE and escort.mind == Person.Mind.FLEE and away.mind == Person.Mind.FLEE and head._whisper_fled,
		"(set-up) the evacuation sends the recovering ones and the one away running and owes the whispered captain a flight")
	Kit.run_for(s, 0.6)
	t.check(guard.mind == Person.Mind.DUTY and escort.mind == Person.Mind.DUTY and not head._whisper_fled and head.mind == Person.Mind.WHISPERED,
		"at the first look after it: the guard and the escort called back, the captain's flight ended")
	t.check(away.mind == Person.Mind.DUTY and away.anchor == away_g.post and away_g.away < d.return_after,
		"one away from his post when the evacuation begins is recalled at once, not return_after later (the final review's one policy)")
	head._wake()  # headless people never think: the whisper wears off by hand
	Kit.run_for(s, 1.0)
	t.check(head.mind == Person.Mind.DUTY and MissionDirector._alive(head) and not d.head_down() and not d.found,
		"the captain does not leave town and win the hunt by his absence")
	Kit.done(s)
	var w := Kit.world(_probe(), Drill.new())
	var wd: Drill = w.d
	Kit.evacuate(w)
	var inside := wd.head as Person
	t.check(inside.inside and inside.mind == Person.Mind.FLEE, "(set-up) the evacuation sends the captain waiting indoors running too")
	wd._raise(0)
	wd._raise(1)
	wd._call_head()
	t.check(wd.head_out and not inside.inside and inside.mind == Person.Mind.DUTY and inside.anchor == wd.head_route[0],
		"coming out, he is stopped and put on his route, not left running for the gates")
	Kit.done(w)


## A hunt whose head has no time of his own (v0.11 M4, M6's reuse): only the chain brings him, `chain` after the last break.
class Chained:
	extends Drill

	func _plan() -> void:
		super()
		head_at = -1.0


static func _hunt_no_captain_time(t) -> void:
	var s := Kit.world(_probe(), Chained.new())
	var d: Chained = s.d
	d._raise(0)
	d._raise(1)
	Kit.run_for(s, 1.0)
	t.check(d.head_due() == INF and not d.head_out, "no captain time: while a standard stands he is due never, and does not come out")
	for i in 2:
		for g: HuntDirector.Guard in d.steps[i].party:
			Kit.arrive(g.man as Person, g.post + Vector2(4.0, 0.0))
		d.standard(i).damage(100.0, d.standard(i).center(), &"smite")
	var broke := d._clock
	t.check(d.broken_all() and is_equal_approx(d.head_due(), broke + d.chain) and not d.head_out, "the last break sets him due `chain` on")
	Kit.run_for(s, d.chain - 1.0)
	t.check(not d.head_out, "he is not out a second before")
	Kit.run_for(s, 2.0)
	t.check(d.head_out, "and is out `chain` seconds after the last break")
	Kit.done(s)


static func _hunt_pre_destroyed(t) -> void:
	var s := Kit.world(_probe(), Towered.new())
	var d: Towered = s.d
	var tw := d.towers[0]
	tw.destroy(tw.center(), &"blast")
	Kit.run_for(s, 5.0 + DT)
	t.check(d.steps[0].raised and d.broken(0) and d.standard(0) == null and (s.banners as Array).has("A STANDARD FALLS"),
		"a tower already down when its step comes counts the step broken, not a standard that can never fall")
	Kit.run_for(s, 10.0 + DT)
	t.check(d.broken(2) and d.standard(1) != null and not d.broken(1), "the night does not lock: the next step is raised on its time")
	Kit.done(s)


## A relief chosen once the town is running is not one of the flight (v0.11 M4).
static func _hunt_relief_in_flight(t) -> void:
	var s := Kit.world(_probe(), Drill.new())
	var d: Drill = s.d
	var gone: Variant = (d.steps[0].party[0] as HuntDirector.Guard).man
	Kit.free_body(s, gone)
	Kit.evacuate(s)
	Kit.run_for(s, d.relief_after + 1.0)
	var relief: Variant = (d.steps[0].party[0] as HuntDirector.Guard).man
	t.check(relief != gone and MissionDirector._alive(relief) and (relief as Person).mind == Person.Mind.DUTY,
		"a relief picked after the evacuation began is put on duty at the post, not left running for the gates")
	Kit.done(s)


## A hunt whose fallen guards no one can reach (v0.11 M4, the final review): it counts its searches for a relief.
class NoRelief:
	extends Drill
	var searched := 0

	func _lay_reaching(_at: Vector2, _exclude: Array = []) -> Person:
		searched += 1
		return null


## With no relief who can reach the post, the search backs off and is tried again relief_after later, not at every look (v0.11 M4).
static func _hunt_relief_backs_off(t) -> void:
	var s := Kit.world(_probe(), NoRelief.new())
	var d: NoRelief = s.d
	var g: HuntDirector.Guard = d.steps[0].party[0]
	Kit.free_body(s, g.man)
	Kit.run_for(s, 2.0 * d.relief_after + 2.0)
	t.check(d.searched == 2 and g.fallen < d.relief_after, "two searches in two relief_after spans, not one every look (%d)" % d.searched)
	Kit.done(s)


## hunt_at and hunt_after_free both set (v0.11 M4): hunt_at wins; the freeing adds no second event.
class BothBound:
	extends Bound

	func _plan() -> void:
		super()
		hunt_at = 90.0


static func _bound_both(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb(), BothBound.new())
	var d: BothBound = s.d
	Kit.run_for(s, 0.5)
	d.stall.destroy(d.stall.center(), &"blast")
	Kit.run_for(s, 0.5)
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(not d.bound and ids.count("hunt") == 1 and d.timeline.seconds_to("hunt") > 60.0,
		"with hunt_at set, the freeing adds no searchers' event of its own (%s, in %.1f)" % [ids, d.timeline.seconds_to("hunt")])
	Kit.done(s)
