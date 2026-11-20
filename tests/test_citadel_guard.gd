extends RefCounted
## Soldier duties, slice a1: the Citadel guard. At the call-up a guard of 20 forms in still ranks (mission men first, then the
## Citadel group, then the nearest free guards), the rest of the Citadel group stands down to the yard and the other
## soldiers keep the city; the board stays open until the Citadel falls.

const Corps := preload("res://tests/test_corps.gd")
const GuardJobsTest := preload("res://tests/test_guard_jobs.gd")
const CapPeople := preload("res://tests/test_capital_people.gd")


## A duty that only registers the SHELTER kind.
class StubShelter extends Duty:
	func kind() -> int:
		return GuardJobs.Kind.SHELTER


static func _made() -> Array:
	return Corps._crowd()


## Every living ordinary soldier not on a job is held by a "director" (so no free man is left).
static func _hold_rest(crowd: Crowd) -> void:
	var gj := crowd.guard_jobs
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier and p.corps == Person.Corps.NONE and not gj.on_job(p))


static func _group(crowd: Crowd, group: int) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.soldiers:
		if p.post_group == group and p.corps == Person.Corps.NONE:
			out.append(p)
	return out


static func _slots(t) -> void:
	var o := Vector2(10.0, 10.0)
	t.check(CitadelGuard.slot_at(o, 0).face == Vector2(0, 1) and CitadelGuard.slot_at(o, 1).face == Vector2(1, 0), "south first, then round")
	t.check(CitadelGuard.slot_at(o, 2).face == Vector2(0, -1) and CitadelGuard.slot_at(o, 3).face == Vector2(-1, 0), "north, then west")
	t.near(CitadelGuard.slot_at(o, 0).at.distance_to(o), Crowd.RING_RADIUS, 0.001, "front rank at RING_RADIUS")
	t.near(CitadelGuard.slot_at(o, 4).at.distance_to(CitadelGuard.slot_at(o, 0).at), 0.6, 0.001, "ranks 0.6 apart along a side")
	t.near(CitadelGuard.slot_at(o, 8).at.distance_to(CitadelGuard.slot_at(o, 0).at), 0.6, 0.001, "the next man is 0.6 the other way")
	t.near(CitadelGuard.slot_at(o, 12).at.distance_to(CitadelGuard.slot_at(o, 0).at), 1.2, 0.001, "then 1.2")
	t.near(CitadelGuard.slot_at(o, 16).at.distance_to(CitadelGuard.slot_at(o, 0).at), 1.2, 0.001, "and 1.2 the other way")
	var sides := {}
	for k in 15:
		sides[CitadelGuard.slot_at(o, k).face] = true
	t.check(sides.size() == 4, "slots 0..14 cover all four sides")
	t.near(CitadelGuard.slot_at(o, 20).at.distance_to(o), Crowd.RING_RADIUS + 0.6, 0.001, "slot 20 is the rear rank, 0.6 further out")
	t.check(CitadelGuard.slot_at(o, 20).face == Vector2(0, 1), "facing the same side as slot 0")


static func _guard_of_twenty(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	t.check(crowd.guard.count() == 20, "the call-up forms a guard of 20 (%d)" % crowd.guard.count())
	var rallying := 0
	var bad := 0
	for p in crowd.soldiers:
		if p.mind == Person.Mind.RALLY:
			rallying += 1
			if crowd.guard_jobs.job_of(p) != crowd.guard.job:
				bad += 1
		elif p.corps == Person.Corps.NONE and p.mind != Person.Mind.POST:
			bad += 1
	t.check(rallying == 20 and bad == 0, "20 men march and every other corps-NONE soldier stays at his post (%d, %d)" % [rallying, bad])
	t.check(crowd.called_up() and crowd.guard_jobs.is_open(), "called up, board open")
	Corps._done(made)


static func _mission_men_first(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var a := crowd.add_soldier(Vector2(0.0, 0.0))
	var b := GuardJobsTest._guard(crowd, 0)
	b.post = b.post + Vector2(3.0, 0.0)
	b.anchor = b.post
	var c := GuardJobsTest._guard(crowd, 1)
	c.go_duty(c.ground_pos + Vector2(2.0, 0.0))
	t.check(crowd.guard_jobs.mission_man(a) and crowd.guard_jobs.mission_man(b) and crowd.guard_jobs.mission_man(c), "three mission men")
	crowd.rally()
	var o := City.current().citadel_origin()
	var ok := true
	var slots := []
	for p in [a, b, c]:
		var k := int(crowd.guard._slot.get(p, -1))
		slots.append(k)
		ok = ok and p.mind == Person.Mind.RALLY and crowd.guard.job.crew.has(p) and crowd.guard.is_mission(p)
		ok = ok and k >= 0 and crowd.guard.slot_of(p).is_equal_approx(crowd.guard._snap(CitadelGuard.slot_at(o, k).at))
	slots.sort()
	t.check(ok and slots == [0, 1, 2], "all three are in the guard, in slots 0-2, marching (%s)" % [slots])
	t.check(crowd.guard.count() == 20, "and the guard is still 20")
	Corps._done(made)


static func _more_than_twenty(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var men: Array[Person] = []
	for i in 22:
		men.append(crowd.add_soldier(Vector2(float(i) * 0.5, 0.0)))
	crowd.rally()
	var town := 0
	for p in crowd.guard.job.crew:
		if not crowd.guard.is_mission(p):
			town += 1
	t.check(crowd.guard.count() == 22 and town == 0, "22 mission men: a guard of 22 and no town man (%d, %d)" % [crowd.guard.count(), town])
	var rear := 0
	for p in men:
		if int(crowd.guard._slot.get(p, 0)) >= 20:
			rear += 1
	t.check(rear == 2, "two stand in the rear rank (%d)" % rear)
	Corps._done(made)


static func _stand_down_yard(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var group := _group(crowd, 2)
	crowd.add_soldier(Vector2(0.0, 0.0))
	crowd.add_soldier(Vector2(1.0, 0.0))
	crowd.rally()
	var down: Array[Person] = []
	for p in group:
		if not crowd.guard.job.crew.has(p):
			down.append(p)
	var yard := City.current().landmark(&"barracks_yard").get_center()
	var ok := down.size() == 2
	for p in down:
		ok = ok and p.post_group == 0 and p.post == p.town_post and p.mind == Person.Mind.POST \
				and p.anchor.is_equal_approx(p.post) and p.post.distance_to(yard) <= 3.5
	t.check(ok, "with 2 mission men, 2 Citadel-group men stand down to the yard (%d)" % down.size())
	t.check(down.size() == 2 and not down[0].post.is_equal_approx(down[1].post), "each to a spot of his own")
	Corps._done(made)


static func _stand_down_never_mission(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var group := _group(crowd, 2)
	var m := group[0]
	m.post = m.post + Vector2(3.0, 0.0)
	m.anchor = m.post
	var post := m.post
	for i in 3:
		crowd.add_soldier(Vector2(float(i), 0.0))
	crowd.rally()
	t.check(crowd.guard.job.crew.has(m) and m.post_group == 2 and m.post == post, "a mission man of the Citadel group is never stood down")
	Corps._done(made)


static func _march_walk(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	var p: Person = crowd.guard.job.crew[0]
	t.near(p._base_speed(), Person.WALK_SPEED * Person.ASSIST_PACE * p.pace, 0.0001, "a guard man marches at 0.9 x pace")
	Corps._done(made)


static func _stand_still(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	var p: Person = crowd.guard.job.crew[0]
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	var at := p.ground_pos
	for i in 300:
		crowd.advance(1.0 / 60.0)
	t.check(p.ground_pos.distance_to(at) < 0.01, "arrived, he stands still (%.3f)" % p.ground_pos.distance_to(at))
	var face: Vector2 = CitadelGuard.slot_at(City.current().citadel_origin(), int(crowd.guard._slot[p])).face
	t.check(p.stand_face == face and p._facing == (1 if face.x - face.y > 0.0 else -1), "and faces the way his slot gives")
	Corps._done(made)


static func _count_only_on_slot(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var citadel: Citadel = made[5].citadel
	crowd.rally()
	var crew := crowd.guard.job.crew.duplicate()
	for p in crew:
		p.ground_pos = crowd.guard.slot_of(p) + Vector2(5.0, 0.0)
	t.check(crowd.ring_count() == 0 and crowd.guard.count() == 20, "20 walking men count for nothing")
	for i in 15:
		crew[i].ground_pos = crowd.guard.slot_of(crew[i]) + Vector2(0.5, 0.0)
	t.check(crowd.ring_count() == 15, "15 within 1.0 of their own slot count (%d)" % crowd.ring_count())
	t.near(citadel.garrison_cut(), 0.30, 0.0001, "15 men on slot cut a hit by 0.30")
	var other: Person = null
	for p in crew:
		if other == null and crowd.guard.slot_of(p).distance_to(crowd.guard.slot_of(crew[0])) > 2.0:
			other = p
	crew[0].ground_pos = crowd.guard.slot_of(other)
	t.check(not crowd.on_ring(crew[0]), "a man on another's slot does not count")
	Corps._done(made)


static func _refill_under_twenty(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	var crew := crowd.guard.job.crew.duplicate()
	var dead: Person = crew[3]
	dead.die(&"test")
	crowd.guard_jobs.step(1.0)
	t.check(crowd.guard.count() == 20, "a guard man dies: the next tick refills to 20 (%d)" % crowd.guard.count())
	var new: Person = null
	for p in crowd.guard.job.crew:
		if not crew.has(p):
			new = p
	t.check(new != null and new.mind == Person.Mind.RALLY and new.has_goal(), "the new man is marching to a slot")
	Corps._done(made)


static func _pull_under_min(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var house := GuardJobsTest._house(made[1])
	crowd.rally()
	var a := GuardJobsTest._guard(crowd, 0)
	a.assist(house, true)
	gj.take(a, house)
	var b := GuardJobsTest._guard(crowd, 1)
	gj.add_duty(StubShelter.new().setup(gj, crowd))
	var job := gj.post(GuardJobs.Kind.SHELTER, b.ground_pos, 1)
	gj.assign(job, b)
	_hold_rest(crowd)
	var crew := crowd.guard.job.crew.duplicate()
	for i in 6:
		(crew[i] as Person).die(&"test")
	gj.step(1.0)
	t.check(crowd.guard.count() == 15, "under 15 the fire man is pulled (%d)" % crowd.guard.count())
	t.check(crowd.guard.job.crew.has(a) and a.assist_fire == null and gj.kind_of(a) == GuardJobs.Kind.CITADEL, "he leaves the fire for the guard")
	t.check(gj.kind_of(b) == GuardJobs.Kind.SHELTER and not crowd.guard.job.crew.has(b), "a shelter man is never pulled")
	Corps._done(made)


static func _refill_from_guard(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	_hold_rest(crowd)
	var marshal: Person = null
	for p in crowd.soldiers:
		if p.corps == Person.Corps.MARSHAL:
			marshal = p
			break
	t.check(marshal != null, "the town has a marshal")
	var crew := crowd.guard.job.crew.duplicate()
	marshal.die(&"test")
	crowd._refill(marshal)
	var taken: Person = null
	for p in crew:
		if p.corps == Person.Corps.MARSHAL:
			taken = p
	t.check(taken != null and not crowd.guard.job.crew.has(taken), "with no free man, a guard man takes the marshal's place")
	t.check(crowd.guard.count() == 19 and crowd.guard.free_slot() >= 0, "his slot reopens (%d)" % crowd.guard.count())
	Corps._done(made)


static func _board_open(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	t.check(crowd.guard_jobs.is_open(), "after the call-up the board is open")
	crowd.alarms.stage = crowd.profile.fire_from
	var house := GuardJobsTest._yard_fire(crowd, made[1])
	crowd.fires._recruit()
	var guards := 0
	for p in GuardJobsTest._on_fire(crowd, house):
		if p.corps == Person.Corps.NONE:
			guards += 1
	t.check(guards > 0, "a fresh yard fire takes a guard (%d)" % guards)
	Corps._done(made)


static func _fallen_closes(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	crowd._on_citadel_fallen()
	var holding := true
	for p in crowd.soldiers:
		if p.is_alive() and p.corps == Person.Corps.NONE:
			holding = holding and p.mind == Person.Mind.HOLD
	t.check(not crowd.guard_jobs.is_open() and crowd.guard_jobs.jobs.is_empty(), "the fall closes the board and ends every job")
	t.check(holding, "and every ordinary soldier holds the ground")
	crowd.guard_jobs.step(2.0)
	t.check(crowd.guard_jobs.jobs.is_empty(), "a closed board fills nothing")
	Corps._done(made)


static func _forgo_no_guard(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.forgo_rally()
	t.check(crowd.guard.count() == 0 and crowd.guard_jobs.is_open() and not crowd.called_up(), "no rally, no guard, board open")
	Corps._done(made)


static func _late_appointment(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	var d := MissionDirector.new().setup(null, crowd, made[5], null)
	var at: Vector2 = City.current().citadel_origin()
	t.check(d._free_soldiers(at, 5).is_empty(), "after the call-up a director finds no free soldier")
	var p: Person = crowd.guard.job.crew[0]
	crowd.guard_jobs.drop(crowd.guard.job, p)
	p.send_to_post(p.post)
	var got := d._free_soldiers(at, 5)
	t.check(got.size() == 1 and got[0] == p, "a guard man sent back to his post is the one returned")
	Corps._done(made)


static func _before_call_up(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var house := GuardJobsTest._house(made[1])
	var g := GuardJobsTest._guard(crowd, 0)
	g.assist(house, true)
	crowd.guard_jobs.take(g, house)
	var d := MissionDirector.new().setup(null, crowd, made[5], null)
	var got := d._free_soldiers(g.ground_pos, 1)
	t.check(got.size() == 1 and not crowd.guard_jobs.on_job(got[0]), "before the call-up a director wins: the man taken is off any job")
	Corps._done(made)


static func _capital_guard(t) -> void:
	var b: Dictionary = CapPeople._build()
	var crowd: Crowd = b.crowd
	var group := _group(crowd, 2)
	crowd.rally()
	var down := 0
	for p in group:
		if not crowd.guard.job.crew.has(p) and p.post_group == 0 and p.mind == Person.Mind.POST:
			down += 1
	t.check(crowd.guard.count() == 20, "the Capital's guard is 20 too (%d)" % crowd.guard.count())
	t.check(group.size() == 30 and down == 10, "and 10 of its 30 Citadel men stand down (%d of %d)" % [down, group.size()])
	crowd.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


static func _walk_cadence(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.rally()
	var p: Person = crowd.guard.job.crew[0]
	t.check(not p.is_running() and p._walk_rate() == 5.0, "a marching guard man walks: not running, the soldier's walk rate 5.0")
	Corps._done(made)


static func _guard_wiped_out_refills(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	crowd.rally()
	_hold_rest(crowd)
	for p in crowd.guard.job.crew.duplicate():
		(p as Person).die(&"test")
	gj.step(1.0)
	t.check(crowd.guard.count() == 0, "with nobody free the dead guard is not refilled (%d)" % crowd.guard.count())
	t.check(gj.jobs.has(crowd.guard.job) and not crowd.guard.job.ended, "the CITADEL job survives an empty crew")
	crowd.mission_holds.clear()
	gj.step(1.0)
	t.check(crowd.guard.count() == 20, "once men are free the next tick sends them (%d)" % crowd.guard.count())
	Corps._done(made)


static func _stand_down_skips_busy(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var b := _group(crowd, 2)[0]
	gj.add_duty(StubShelter.new().setup(gj, crowd))
	var job := gj.post(GuardJobs.Kind.SHELTER, b.ground_pos, 1)
	gj.assign(job, b)
	var post := b.post
	crowd.add_soldier(Vector2(0.0, 0.0))
	crowd.add_soldier(Vector2(1.0, 0.0))
	crowd.rally()
	t.check(gj.kind_of(b) == GuardJobs.Kind.SHELTER and b.post_group == 2 and b.post == post and not crowd.guard.job.crew.has(b),
		"a man on a job that cannot be pulled is not stood down: he keeps his job and his group")
	Corps._done(made)


static func _rally_after_fall(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd._on_citadel_fallen()
	crowd.rally()
	t.check(crowd.guard.count() == 0 and crowd.guard_jobs.jobs.is_empty(), "a rally after the fall forms no guard")
	Corps._done(made)


static func _mission_man_inside_or_busy(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var a := crowd.add_soldier(Vector2(0.0, 0.0))
	a.inside = true
	var b := GuardJobsTest._guard(crowd, 0)
	b.post = b.post + Vector2(3.0, 0.0)
	b.anchor = b.post
	var house := GuardJobsTest._house(made[1])
	b.assist(house, true)
	gj.take(b, house)
	crowd.rally()
	t.check(crowd.guard.job.crew.has(a) and a.mind == Person.Mind.RALLY, "a mission man inside a building joins the guard")
	t.check(crowd.guard.job.crew.has(b) and gj.kind_of(b) == GuardJobs.Kind.CITADEL, "a mission man on a fire record is pulled and joins")
	Corps._done(made)


static func _yard_spots_distinct(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var spots := crowd.yard_spots(80)
	var seen := {}
	for s in spots:
		seen[s] = true
	t.check(spots.size() == 80 and seen.size() == 80, "80 yard spots, no two the same (%d)" % spots.size())
	Corps._done(made)


static func run(t) -> void:
	_slots(t)
	_guard_of_twenty(t)
	_mission_men_first(t)
	_more_than_twenty(t)
	_stand_down_yard(t)
	_stand_down_never_mission(t)
	_march_walk(t)
	_stand_still(t)
	_count_only_on_slot(t)
	_refill_under_twenty(t)
	_pull_under_min(t)
	_refill_from_guard(t)
	_board_open(t)
	_fallen_closes(t)
	_forgo_no_guard(t)
	_late_appointment(t)
	_before_call_up(t)
	_capital_guard(t)
	_walk_cadence(t)
	_guard_wiped_out_refills(t)
	_stand_down_skips_busy(t)
	_rally_after_fall(t)
	_mission_man_inside_or_busy(t)
	_yard_spots_distinct(t)
