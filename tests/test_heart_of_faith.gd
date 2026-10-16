extends RefCounted
## v0.11 M6 The Heart of Faith (mission spec §3, HeartOfFaithDirector on the Raze type): stage one, the oil-house (the dwelling nearest its
## point) then the Great Temple, staged on the chain (0:45, 1:50 or CHAIN after the oil-house is razed -- at once for a Temple already
## down, M5's horn rule), each under Lantern Knights -- two standing from the start, two coming out of its door at its time -- who seal
## it while one stands guard; a target not in use puts its fire out and a fall counts at its time; burned 12 s (the oil-house) or 20 s
## (the Temple) in use, or fallen, it is razed; a fallen Knight is replaced from the Citadel's gate, backing off while no road leads
## there. The Temple razed puts the Great Flame out: four bearers come out at the Citadel's gate and High Priest Odran follows
## ODRAN_CHAIN later, hidden in his litter while two bearers live (MissionDirector's shared ride), on foot below two; at the Temple's
## steps he rekindles for RITE, started again by any interruption. His death wins; the flame blessed at 5:00 or rekindled loses; once
## the flame is out a seen death adds 20, bannered. The town's evacuation passes everyone by; freed bodies are borne; the tags, hints,
## tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_sealed(t)
	_not_yet(t)
	_burn(t)
	_horn(t)
	_flame_out(t)
	_litter(t)
	_on_foot(t)
	_set_down(t)
	_rite(t)
	_fury(t)
	_won(t)
	_leaves(t)
	_blessed(t)
	_relief(t)
	_no_road(t)
	_evacuated(t)
	_tagged(t)
	_freed(t)


## A Heart of Faith night with no road from the Citadel's gate to any post (v0.11 M6 tests, the carried ruling: a relief no one can
## reach backs off): it counts its searches for a relief.
class NoRoad:
	extends HeartOfFaithDirector
	var asked := 0

	func _reaches(_at: Vector2) -> bool:
		asked += 1
		return false


## A Gaze that never fills (v0.11 M6 tests): for a test whose many kills are not what it checks.
class Blind:
	extends HeartOfFaithDirector.HeartGaze

	func add(_amount: float) -> void:
		pass


static func _world() -> Dictionary:
	return Kit.world(MissionBook.heart_of_faith())


## The live keepout the camera checks use (v0.11 M6, the controller's ruling): Kit.STACK grown by Hud.STACK_PAD.
static func _padded() -> Rect2:
	return Rect2(Vector2.ZERO, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))


## Every Knight of target `i` out of doors killed and freed (v0.11 M6 tests).
static func _kill_knights(s: Dictionary, d: HeartOfFaithDirector, i: int) -> void:
	for p: HeartOfFaithDirector.Post in d.posts:
		if p.target == i and MissionDirector._alive(p.man) and not (p.man as Person).inside:
			Kit.free_body(s, p.man)


## Both targets razed in turn by hand (v0.11 M6 tests): the flame goes out.
static func _put_out(d: HeartOfFaithDirector) -> void:
	d._open(0)
	d._raze(d.targets[0])
	d._open(1)
	d._raze(d.targets[1])


static func _setup(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var eng := (s.crowd as Crowd).engineers
	t.check(d.targets.size() == 2 and d.targets[0] == d.oil_house and d.targets[1] == d.temple and RuinWish.fits(d.oil_house, "house")
		and d.temple.role == &"temple" and eng.hands_off.has(d.oil_house) and eng.hands_off.has(d.temple) and not d.in_use[0],
		"the oil-house (a dwelling) then the Great Temple, kept from the town's engineers, neither in use yet")
	var ok := d.posts.size() == 8
	for p: HeartOfFaithDirector.Post in d.posts:
		var k := p.man as Person
		ok = ok and k.soldier and k.corps == Person.Corps.KNIGHT and is_equal_approx(k.health, Person.HEALTH_KNIGHT) \
			and d.targets[p.target].distance_to(p.spot) <= HeartOfFaithDirector.GUARD_REACH + 0.01 and k.inside == p.arriving 			and d.targets[p.target].distance_to(p.spot) <= d.targets[1 - p.target].distance_to(p.spot)
		for q: HeartOfFaithDirector.Post in d.posts:
			if q != p and q.target == p.target:
				ok = ok and p.spot.distance_to(q.spot) > Crowd.DOOM_WITNESS
	t.check(ok and d.guards_at(0).size() == 2 and d.guards_at(1).size() == 2,
		"two Knights stand at each, two wait inside it, every post within reach of its own target and a witness apart")
	var o := d.odran as Person
	t.check(o.profile.role == CitizenProfile.Role.CLERGY and o.inside and o.mind == Person.Mind.DUTY and d.gaze is HeartOfFaithDirector.HeartGaze,
		"Odran, a cleric, waits inside the Citadel on duty; the Heart keeps its own Gaze")
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["stage_0", "stage_1", "blessed"], "the strip: the oil-house, the Temple, the blessing (%s)" % [ids])
	var cam := HeartOfFaithDirector.CAMERA_AT
	var zone := _padded()
	t.check(Kit.clear_of_stack(d.oil_house.center(), cam, zone) and Kit.clear_of_stack(d.temple.center(), cam, zone)
		and Kit.clear_of_stack(d.steps_at, cam, zone) and Kit.clear_of_stack(d.citadel_door, cam, zone),
		"the camera keeps the oil-house, the Temple, its steps and the Citadel's gate (or their arrows) clear of the padded stack")
	var m := MissionBook.heart_of_faith()
	var reasons := []
	for obj in m.objectives():
		reasons.append(obj.reason)
	t.check(m.tier == 5 and is_equal_approx(m.clock, 420.0) and reasons == ["heart", "gaze", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "ember", "whisper", "heaven"] and Array(m.mission_tags) == ["burns_temple"],
		"the mission: Tier 5's numbers; the Heart, the Gaze, dawn; it burns the Temple (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := (d.odran as Person).inside
	for p: HeartOfFaithDirector.Post in d.posts:
		var k := p.man as Person
		held = held and k.corps == Person.Corps.KNIGHT and (k.inside or k.mind == Person.Mind.POST)
	t.check(held, "the town's regroup and evacuation take no Knight; Odran stays in the Citadel (review focus 2)")
	Kit.done(s)


static func _sealed(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	Kit.run_for(s, DT)
	d.oil_house.damage(40.0, d.oil_house.center(), &"smite")
	t.check(d.is_sealed(d.oil_house) and is_equal_approx(d.oil_house.hp, d.oil_house.max_hp) and d.hint_phase() == "guarded",
		"a Knight on guard seals the target in use: a blow only shakes it")
	Kit.done(s)


static func _not_yet(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_kill_knights(s, d, 0)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	(s.crowd as Crowd).fires.ignite(d.oil_house, 1.0)
	Kit.run_for(s, DT)
	t.check(not d.is_sealed(d.oil_house) and not d.burning(d.oil_house) and is_equal_approx(d.burned(d.oil_house), 0.0),
		"not in use and unguarded: its fire goes out at once and nothing it burns counts")
	d.oil_house.destroy(d.oil_house.center(), &"smite")
	Kit.run_for(s, DT)
	t.check(not d.razed(d.oil_house) and Kit.labels(d).has("OIL-HOUSE - DOWN %s" % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[0])))
		and d.hint_phase() == "not_yet", "felled ahead of its time: not razed yet, and its tag says when it counts")
	d._open(0)
	Kit.run_for(s, DT)
	t.check(d.razed(d.oil_house) and absf(d.timeline.seconds_to("stage_1") - HeartOfFaithDirector.CHAIN) < 1.0,
		"at its time a fallen oil-house is razed at once, and the Temple comes on the chain")
	Kit.done(s)


static func _burn(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	_kill_knights(s, d, 0)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	(s.crowd as Crowd).fires.ignite(d.oil_house, 1.0)
	Kit.run_for(s, float(HeartOfFaithDirector.SPOIL[0]) + 0.5)
	t.check(d.razed(d.oil_house) and not d.flame_out and (s.banners as Array).has("THE OIL-HOUSE IS RAZED")
		and absf(d.timeline.seconds_to("stage_1") - (d.razed_at[0] + HeartOfFaithDirector.CHAIN - d._clock)) < 0.1,
		"in use and unguarded, burned %d s in all (or burned down) the oil-house is razed; the Temple comes on the chain" % roundi(float(HeartOfFaithDirector.SPOIL[0])))
	Kit.done(s)


static func _horn(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_kill_knights(s, d, 1)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	d.temple.destroy(d.temple.center(), &"smite")
	Kit.run_for(s, DT)
	t.check(not d.razed(d.temple) and not d.flame_out, "the Temple felled ahead of its time waits for it")
	d._open(0)
	d._raze(d.targets[0])
	Kit.run_for(s, 2.0 * DT)
	t.check(d.in_use[1] and d.razed(d.temple) and d.flame_out,
		"the oil-house razed with the Temple already down: it comes into use at once and is razed -- the flame goes out (M5's horn rule)")
	Kit.done(s)


static func _flame_out(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	var ok := d.flame_out and d.bearers.size() == HeartOfFaithDirector.BEARERS and (d.gaze as HeartOfFaithDirector.HeartGaze).fury
	for a: HeartOfFaithDirector.Post in d.bearers:
		ok = ok and MissionDirector._alive(a.man) and (a.man as Person).corps == Person.Corps.KNIGHT
		for b: HeartOfFaithDirector.Post in d.bearers:
			if a != b:
				ok = ok and a.spot.distance_to(b.spot) > Crowd.DOOM_WITNESS
	var banners: Array = s.banners
	t.check(ok and banners.has("THE GREAT FLAME GOES OUT") and banners.has("HALCYON LOOKS HARDER") and banners.has("THE HIGH PRIEST'S LITTER WAITS")
		and (d.odran as Person).inside and d.hint_phase() == "coming" and absf(d.hint_seconds() - HeartOfFaithDirector.ODRAN_CHAIN) < 0.5
		and d.hud_line() == "Kill Odran" and d.stages_done() == false,
		"the Temple razed: the flame out, four bearers a witness apart at the Citadel's gate, Odran %d s off" % roundi(HeartOfFaithDirector.ODRAN_CHAIN))
	Kit.done(s)


static func _litter(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	d._odran_comes()
	Kit.run_for(s, 1.0)
	var o := d.odran as Person
	var carried := true
	for b in d.bearers_standing():
		carried = carried and b.mind == Person.Mind.DUTY
	t.check(d.riding and o.inside and o.ground_pos.distance_to(d.litter_at) < 0.01 and carried and d.hint_phase() == "litter"
		and d.hud_line() == "Kill Odran: in his litter" and Kit.labels(d).has("ODRAN - IN HIS LITTER") and Kit.edged(d, "ODRAN - IN HIS LITTER")
		and Kit.edged(d, "BEARER"), "he rides hidden in his litter, carried on duty; untouchable; each bearer pointed at")
	for k in 3:
		Kit.free_body(s, (d.bearers[k] as HeartOfFaithDirector.Post).man)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	t.check(not d.riding and not o.inside and o.mind == Person.Mind.DUTY and (s.banners as Array).has("THE LITTER FALLS")
		and d.hint_phase() == "on_foot" and d.last_guards().size() == 1, "below two bearers the litter falls: he walks on, killable, the last bearer behind him")
	Kit.done(s)


static func _on_foot(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for k in 3:
		Kit.free_body(s, (d.bearers[k] as HeartOfFaithDirector.Post).man)
	d._odran_comes()
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	var o := d.odran as Person
	var guard: Array[Person] = d.last_guards()
	t.check(not d.riding and not o.inside and o.mind == Person.Mind.DUTY and guard.size() == 2 and d.hint_phase() == "on_foot",
		"with fewer than two bearers he sets out on foot, one more Knight as his last guard and the bearer left behind him")
	Kit.done(s)


static func _set_down(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	d._odran_comes()
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.arrive(p.man as Person, d.steps_at + d._corner(d.bearers.find(p)))
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	var o := d.odran as Person
	t.check(not d.riding and not o.inside and o.mind == Person.Mind.DUTY and d.last_guards().size() == HeartOfFaithDirector.BEARERS
		and Kit.labels(d).count("KNIGHT") == HeartOfFaithDirector.BEARERS,
		"the litter at the Temple's steps sets him down on foot; its bearers stand by him as his guard, tagged (plan decision 291)")
	Kit.done(s)


static func _rite(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	d._odran_comes()
	var o := d.odran as Person
	Kit.arrive(o, d.steps_at)
	d._road_at = d._road.size() - 1
	o.go_duty(d.steps_at)
	Kit.run_for(s, 1.0)
	t.check(d.rite_on and d.rite_left < HeartOfFaithDirector.RITE and (s.banners as Array).has("ODRAN REKINDLES THE FLAME") and d.hint_phase() == "rite"
		and Kit.labels(d).has("ODRAN - REKINDLING %d" % ceili(d.rite_left)), "at the Temple's steps, on foot, he rekindles the flame")
	o.whisper(o.ground_pos + Vector2(4.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, DT)
	t.check(not d.rite_on and is_equal_approx(d.rite_left, HeartOfFaithDirector.RITE) and (s.banners as Array).has("THE REKINDLING IS BROKEN"),
		"a whisper on him starts it again from %d" % roundi(HeartOfFaithDirector.RITE))
	o._wake()
	Kit.arrive(o, d.steps_at)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	Kit.run_for(s, HeartOfFaithDirector.RITE + 0.5)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.kindled and d.lost_reason() == "kindled" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "kindled",
		"left to finish, the flame is kindled anew: lost")
	Kit.done(s)


static func _fury(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var crowd: Crowd = s.crowd
	var people: Array[Person] = []
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and p != d.odran and people.size() < 4:
			people.append(p)
	Kit.arrive(people[1], people[0].ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(people[0], &"doom")
	Kit.run_for(s, DT)
	var before := d.gaze.value
	var banners: Array = s.banners
	var first := banners.has("HALCYON SEES A DEATH")
	_put_out(d)
	Kit.arrive(people[3], people[2].ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(people[2], &"doom")
	Kit.run_for(s, DT)
	t.check(is_equal_approx(before, HeartOfFaithDirector.SEEN) and is_equal_approx(d.gaze.value - before, HeartOfFaithDirector.FURY)
		and first and banners.has("HALCYON SEES A DEATH: +%d" % roundi(HeartOfFaithDirector.FURY)),
		"a seen death adds %d, and %d once the flame is out, each bannered" % [roundi(HeartOfFaithDirector.SEEN), roundi(HeartOfFaithDirector.FURY)])
	Kit.done(s)


static func _won(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	d._odran_comes()
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	(s.crowd as Crowd)._field.kill(d.odran, &"doom")
	Kit.run_for(s, DT)
	var main: Objective = (s.rules as Rules).objectives[0]
	var home := true
	for p: HeartOfFaithDirector.Post in d.posts + d.guards:
		home = home and p.done
	t.check(d.odran_dead and d.stages_done() and main.check(s.rules) == Objective.Status.DONE and main.reason == "heart" and home,
		"Odran dead once the flame is out: the Heart of Faith is broken; his Knights go home")
	Kit.done(s)


static func _leaves(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	d._odran_comes()
	(s.crowd as Crowd).escaped.emit(d.odran)
	t.check(d.odran_down() and d.stages_done(), "Odran leaving the town ends him as his death would: at once (review focus 4)")
	Kit.done(s)


static func _blessed(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d.timeline.step(HeartOfFaithDirector.BLESSED_AT + 1.0)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.blessed and d.lost_reason() == "blessed" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "blessed",
		"the flame still burning at %s: blessed, lost" % UiTheme.clock(HeartOfFaithDirector.BLESSED_AT))
	Kit.done(s)
	var o := _world()
	var od: HeartOfFaithDirector = o.d
	_put_out(od)
	od.timeline.step(HeartOfFaithDirector.BLESSED_AT + 1.0)
	t.check(not od.blessed and od.lost_reason() == "", "with the flame out, the blessing is dropped")
	Kit.done(o)


static func _relief(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var post: HeartOfFaithDirector.Post = d.posts[0]
	var dead: Variant = post.man
	Kit.free_body(s, dead)
	Kit.run_for(s, HeartOfFaithDirector.RELIEF_AFTER + HeartOfFaithDirector.TICK + DT)
	var k: Variant = post.man
	t.check(k != dead and MissionDirector._alive(k) and (k as Person).corps == Person.Corps.KNIGHT and (k as Person).anchor == post.spot
		and post.relief and d.reliefs == 1 and d.relief_walking() == k and (s.banners as Array).has("A NEW KNIGHT COMES FROM THE CITADEL"),
		"a fallen Knight is replaced %d s later by one walking from the Citadel's gate" % roundi(HeartOfFaithDirector.RELIEF_AFTER))
	Kit.done(s)


static func _no_road(t) -> void:
	var s := Kit.world(MissionBook.heart_of_faith(), NoRoad.new())
	var d: NoRoad = s.d
	var post: HeartOfFaithDirector.Post = d.posts[0]
	Kit.free_body(s, post.man)
	Kit.run_for(s, HeartOfFaithDirector.RELIEF_AFTER + HeartOfFaithDirector.TICK + DT)
	var once := d.asked
	Kit.run_for(s, 2.0)
	t.check(once == 1 and d.asked == 1 and d.reliefs == 0 and not MissionDirector._alive(post.man),
		"no road from the Citadel's gate to the post: no relief, and the search backs off %d s (asked %d)" % [roundi(HeartOfFaithDirector.RELIEF_AFTER), d.asked])
	Kit.done(s)


static func _evacuated(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	d._raze(d.targets[0])
	d._open(1)
	var post: HeartOfFaithDirector.Post = null
	for p: HeartOfFaithDirector.Post in d.posts:
		if p.target == 1 and not p.arriving:
			post = p
			break
	Kit.free_body(s, post.man)
	Kit.run_for(s, HeartOfFaithDirector.RELIEF_AFTER + HeartOfFaithDirector.TICK + DT)
	var relief := post.man as Person
	Kit.evacuate(s)
	Kit.run_for(s, 2.0 * HeartOfFaithDirector.TICK + DT)
	var held := true
	for p: HeartOfFaithDirector.Post in d.posts:
		if p.target == 1 and MissionDirector._alive(p.man):
			held = held and (p.man as Person).mind == Person.Mind.POST and (p.man as Person).anchor == p.spot
	t.check(post.relief and relief.mind == Person.Mind.POST and relief.anchor == post.spot and held,
		"the evacuation while the Temple is in use and a relief walks in: he walks on to his post, the Knights hold")
	Kit.done(s)
	var s2 := _world()
	var d2: HeartOfFaithDirector = s2.d
	_put_out(d2)
	Kit.run_for(s2, DT)
	d2._odran_comes()
	Kit.run_for(s2, 1.0)
	Kit.evacuate(s2)
	Kit.run_for(s2, 2.0 * HeartOfFaithDirector.TICK + DT)
	var square := true
	for b in d2.bearers_standing():
		square = square and b.mind == Person.Mind.DUTY
	t.check(d2.riding and (d2.odran as Person).inside and square, "again while the litter walks: the bearers keep their square, Odran hidden in it")
	for k in 3:
		Kit.free_body(s2, (d2.bearers[k] as HeartOfFaithDirector.Post).man)
	Kit.run_for(s2, HeartOfFaithDirector.TICK + DT)
	var o := d2.odran as Person
	o._recover(1.0)
	d2._saw_evacuation = false
	(s2.crowd as Crowd)._fled_all = false  # the town runs again, now with him recovering on foot
	Kit.evacuate(s2)
	Kit.run_for(s2, 2.0 * HeartOfFaithDirector.TICK + DT)
	t.check(o.mind == Person.Mind.DUTY and (s2.crowd as Crowd).citizens.has(o) and not o.inside,
		"on foot, recovering when the town runs, he keeps his road; he never leaves the town")
	Kit.done(s2)
	var s3 := _world()
	var d3: HeartOfFaithDirector = s3.d
	_put_out(d3)
	Kit.run_for(s3, DT)
	for p: HeartOfFaithDirector.Post in d3.bearers:
		Kit.free_body(s3, p.man)
	d3._odran_comes()
	Kit.run_for(s3, HeartOfFaithDirector.TICK + DT)
	var w := d3.odran as Person
	w.whisper(w.ground_pos + Vector2(2.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(s3)
	Kit.run_for(s3, 2.0 * HeartOfFaithDirector.TICK + DT)
	var under := w.mind == Person.Mind.WHISPERED and not w._whisper_fled
	w._wake()
	Kit.run_for(s3, HeartOfFaithDirector.TICK + DT)
	t.check(under and w.mind == Person.Mind.DUTY and (s3.crowd as Crowd).citizens.has(w),
		"whispered when the town runs, he owes it no flight: woken, he takes up his road")
	Kit.done(s3)


static func _tagged(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var labels := Kit.labels(d)
	var next := "OIL-HOUSE - IN USE BY %s" % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[0]))
	t.check(labels[0] == next and Kit.edged(d, next) and labels.has("ODRAN - IN THE CITADEL") and labels.has("KNIGHT")
		and d.hud_line() == "Put out the flame 0 / 2: blessed in %s" % UiTheme.clock(HeartOfFaithDirector.BLESSED_AT),
		"at the start: the oil-house's time, grey, pointed at; Odran in the Citadel; KNIGHT on each; the blessing's countdown (%s)" % [labels])
	d._open(0)
	t.check(Kit.labels(d)[0] == "OIL-HOUSE - GUARDED" and Kit.edged(d, "OIL-HOUSE - GUARDED"), "in use and guarded, gold, pointed at")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The oil-house. Its Knights guard it. It feeds the flame from %s: burn it." % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[0]))
		and String(tour[1][1]) == "The Great Temple. The flame blazes here by %s. Burn it down to put the flame out." % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[1]))
		and String(tour[2][1]) == "The Citadel. High Priest Odran waits here. Once the flame is out he comes to rekindle it: kill him.", "the tour")
	t.check(ResultsScreen.ACT_TITLES.get("heart") == "THE HEART OF FAITH IS BROKEN" and ResultsScreen.ACT_TITLES.get("blessed") == "THE GREAT FLAME IS BLESSED"
		and ResultsScreen.ACT_TITLES.get("kindled") == "THE FLAME IS KINDLED ANEW" and MissionHints.line("heart_of_faith", "coming").contains(MissionHints.SECONDS)
		and MissionHints.line("heart_of_faith", "coming").contains("adds %d to the Gaze" % roundi(HeartOfFaithDirector.FURY)),
		"its results under its own keys; the hint counts Odran down and states the Gaze once the flame is out")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d.gaze = Blind.new()  # the freed Knights die in sight of each other; the Gaze is not what this checks
	d._open(0)
	Kit.run_for(s, 0.2)
	for p: HeartOfFaithDirector.Post in d.posts:
		if MissionDirector._alive(p.man) and not (p.man as Person).inside:
			Kit.free_body(s, p.man)
	d.tags()
	d.hint_phase()
	d.hud_line()
	d.report()
	_put_out(d)
	Kit.run_for(s, DT)
	d._odran_comes()
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	for p: HeartOfFaithDirector.Post in d.guards:
		if MissionDirector._alive(p.man):
			Kit.free_body(s, p.man)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(not d.odran_down() and d.hint_phase() == "on_foot", "every Knight and bearer freed: borne; Odran walks on (review focus 4)")
	Kit.done(s)
