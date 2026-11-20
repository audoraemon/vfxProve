extends RefCounted
## Soldier duties, slice c: the cordon. A doused fire or a fall (a house that leaves a ruin) posts a CORDON job on the nearest
## street: two free guards within REACH stand at its two ends for 40 s, turn calm citizens back (they keep their goals and take
## them up again at the end), lures through the rope fail, and a death inside it is seen by no cordon man.

const Corps := preload("res://tests/test_corps.gd")
const CapPeople := preload("res://tests/test_capital_people.gd")
const STEP := 1.0 / 60.0
const CORDON := GuardJobs.Kind.CORDON


static func run(t) -> void:
	_fire_out_trigger(t)
	_fall_trigger(t)
	_veiled_none(t)
	_restart_inside(t)
	_cap_two(t)
	_crew_within_reach(t)
	_full_crew_only(t)
	_keep_one(t)
	_mission_man_never(t)
	_shape(t)
	_turns_back(t)
	_never_turns_back(t)
	_lure_fails(t)
	_lure_o1(t)
	_inside_unwatched(t)
	_ends_forty(t)
	_ends_releases(t)
	_held_ends_cordon(t)
	_evacuation_ends(t)
	_open_job_ends(t)
	_freed_man(t)
	_clear_resets(t)
	_talk_left(t)


static func _world() -> Array:
	City.use(&"aldermere")
	return Corps._crowd()


static func _done(made: Array) -> void:
	Corps._done(made)
	City.use(&"aldermere")


## Every soldier and each of `extra` thinks and moves one step (`delta`), then the crowd's own tick.
static func _step(crowd: Crowd, extra: Array = [], delta := STEP) -> void:
	for p in crowd.soldiers:
		if is_instance_valid(p) and not p.inside:
			p.tick(delta)
	for p in extra:
		if is_instance_valid(p):
			p.tick(delta)
	crowd.advance(delta)


static func _run_for(crowd: Crowd, seconds: float, extra: Array = [], delta := STEP) -> void:
	for i in roundi(seconds / delta):
		_step(crowd, extra, delta)


## The house nearest the barracks yard (so free guards stand about it) that burns, leaves a ruin and has a street cell beside it,
## not any of `skip`.
static func _site(made: Array, skip: Array = []) -> Structure:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var c: Vector2 = City.current().landmark(&"barracks_yard").get_center()
	var best: Structure = null
	for s in env.structures():
		if s.role != &"house" or s.destroyed or not s.leaves_ruin() or skip.has(s) or not FireManager.burns(s):
			continue
		if crowd.piles.cells_for(s).is_empty():
			continue
		if best == null or s.center().distance_to(c) < best.center().distance_to(c):
			best = s
	return best


static func _live(crowd: Crowd) -> Array[GuardJobs.Job]:
	return crowd.guard_jobs.live(CORDON)


## A cordon posted on `house` and filled from the free guards at once; null when it took no crew.
static func _up(made: Array, house: Structure) -> GuardJobs.Job:
	var crowd: Crowd = made[0]
	crowd.cordon.request(house, house.center())
	crowd.guard_jobs._fill()
	var live := _live(crowd)
	return live[0] if not live.is_empty() and live[0].crew.size() == 2 else null


## Both men of `job` set down on the ends they were sent to.
static func _arrive(job: GuardJobs.Job) -> void:
	for p: Person in job.crew:
		p.ground_pos = job.data.at_end[p]
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos


## The first `n` living citizens, calm, set out of doors at `at`, no goal.
static func _citizens(crowd: Crowd, n: int, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for c in crowd.citizens:
		if out.size() >= n:
			break
		if is_instance_valid(c) and c.is_alive() and not out.has(c):
			c.inside = false
			c.mind = Person.Mind.CALM
			c.ground_pos = at
			c._goal = Vector2.INF
			c._path = PackedVector2Array()
			c._target = at
			out.append(c)
	return out


## The unit vector along the cordon's street, end 0 to end 1.
static func _axis(job: GuardJobs.Job) -> Vector2:
	return ((job.data.ends[1] as Vector2) - (job.data.ends[0] as Vector2)).normalized()


## Every living person who is not in `keep` is put out of doors-of-sight (inside), so no stray watcher or walker is about.
static func _hide_others(crowd: Crowd, keep: Array) -> void:
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p) and not keep.has(p):
			p.inside = true


## Everyone but `men` is held by a "director", so only they are free.
static func _only_free(crowd: Crowd, men: Array) -> void:
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier and not men.has(p))


## `p` stands at `at` as his post, anchor and place.
static func _place(p: Person, at: Vector2) -> void:
	p.post = at
	p.town_post = at
	p.anchor = at
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


## Three ordinary yard guards (post group 0), the first two set `d` east of `at` and the third far off.
static func _trio(crowd: Crowd, at: Vector2, d: float) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.soldiers:
		if p.post_group == 0 and p.corps == Person.Corps.NONE and crowd.guard_jobs.at_post(p) and out.size() < 3:
			out.append(p)
	_place(out[0], at + Vector2(d, 0.0))
	_place(out[1], at + Vector2(d, 0.4))
	_place(out[2], at + Vector2(40.0, 0.0))
	return out


## A doused fire posts one cordon; a house that burnt down posts none from the fire's end.
static func _fire_out_trigger(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var a := _site(made)
	var b := _site(made, [a])
	crowd.fires.ignite(b, 0.5)
	crowd.fires._put_out(b, false)
	t.check(_live(crowd).is_empty(), "a house that burnt down: _put_out(false) posts no cordon")
	crowd.fires.ignite(a, 0.5)
	t.check(_live(crowd).is_empty(), "a burning house: none yet")
	crowd.fires.fires[a].intensity = 0.05
	crowd.fires.douse(a)
	var live := _live(crowd)
	t.check(live.size() == 1, "a doused fire: one cordon job (%d)" % live.size())
	if live.size() == 1:
		t.check(live[0].data.site == a and live[0].need == CordonDuty.CREW and live[0].reach == CordonDuty.REACH, "on that house: crew 2, reach 10")
	_done(made)


## A house that falls (leaves a ruin) posts one cordon on its street.
static func _fall_trigger(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	house.destroy(Vector2.ZERO, &"stone")
	var live := _live(crowd)
	t.check(live.size() == 1, "a fallen house: one cordon job (%d)" % live.size())
	if live.size() == 1:
		var d: Dictionary = live[0].data
		t.check(d.site == house and (d.rect as Rect2).encloses(house.footprint.grow(CordonDuty.FOOT_GROW)), "its rect takes in the ruin")
		var pile: PileManager.Pile = crowd.piles.piles[0]
		t.check(live[0].at.distance_to(crowd.piles.centre(pile)) < 12.0, "and sits on the pile's street")
	_done(made)


## A veiled site, and any site once the town is at EVACUATION, posts none.
static func _veiled_none(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	crowd.veil(house.center(), 4.0, 60.0)
	crowd.cordon.request(house, house.center())
	t.check(_live(crowd).is_empty(), "a veiled site: no cordon")
	_done(made)
	var made2 := _world()
	var crowd2: Crowd = made2[0]
	crowd2.alarms.stage = AlarmManager.Stage.EVACUATION
	crowd2.cordon.request(_site(made2), _site(made2).center())
	t.check(_live(crowd2).is_empty(), "stage EVACUATION: no cordon")
	_done(made2)


## A second site whose centre lies in a live rect restarts that cordon's clock; it makes no second job.
static func _restart_inside(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	t.check(job != null, "(a cordon with its crew)")
	if job == null:
		_done(made)
		return
	_arrive(job)
	_run_for(crowd, 12.0, [], 0.1)
	t.check(float(job.data.left) < CordonDuty.CORDON_SECONDS - 5.0, "(its clock runs: %.1f)" % float(job.data.left))
	crowd.cordon.request(house, house.center())
	t.check(_live(crowd).size() == 1, "a second site inside the rect: still one job")
	t.near(float(job.data.left), CordonDuty.CORDON_SECONDS, 0.001, "and the clock is back at 40")
	_done(made)


## Two cordons at most in Aldermere (cap 2 scaled), four in the Capital.
static func _cap_two(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var sites: Array[Structure] = []
	for s in made[1].structures():
		if s.role != &"house" or s.destroyed or not FireManager.burns(s):
			continue
		var far := true
		for o in sites:
			far = far and o.center().distance_to(s.center()) >= 14.0
		if far:
			sites.append(s)
	t.check(sites.size() >= 3, "(three houses far apart: %d)" % sites.size())
	for s in sites:
		crowd.cordon.request(s, s.center())
	t.check(_live(crowd).size() == 2, "Aldermere: three far sites, two cordons (%d)" % _live(crowd).size())
	_done(made)
	var b: Dictionary = CapPeople._build()
	var cap: Crowd = b.crowd
	var far_sites: Array[Structure] = []
	for s in b.env.structures():
		if s.destroyed or s.kind != Structure.Kind.HOUSE or not FireManager.burns(s):
			continue
		var apart := true
		for o in far_sites:
			apart = apart and o.center().distance_to(s.center()) >= 14.0
		if apart:
			far_sites.append(s)
	t.check(cap.guard_jobs.cap(CordonDuty.CORDONS) == 4, "(the Capital's cap is 4: %d)" % cap.guard_jobs.cap(CordonDuty.CORDONS))
	t.check(far_sites.size() >= 5, "(five far sites: %d)" % far_sites.size())
	for s in far_sites:
		cap.cordon.request(s, s.center())
	t.check(cap.guard_jobs.live(CORDON).size() == 4, "the Capital: four cordons (%d)" % cap.guard_jobs.live(CORDON).size())
	cap.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


## Both crew men were free and within 10.0 of the job; none is taken from 10.5.
static func _crew_within_reach(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	crowd.cordon.request(house, house.center())
	var job: GuardJobs.Job = _live(crowd)[0]
	var trio := _trio(crowd, job.at, 10.5)
	_only_free(crowd, trio)
	crowd.guard_jobs._fill()
	t.check(job.crew.is_empty() and not job.started, "free men 10.5 off: no crew")
	_place(trio[0], job.at + Vector2(9.5, 0.0))
	_place(trio[1], job.at + Vector2(9.5, 0.4))
	crowd.guard_jobs._fill()
	t.check(job.crew.size() == 2 and job.started, "9.5 off: the full crew")
	var within := true
	for p in job.crew:
		within = within and p.ground_pos.distance_to(job.at) <= CordonDuty.REACH + 0.5 and trio.has(p)
	t.check(within, "both were within reach")
	_done(made)


## One free man in reach is no crew: nothing starts and nobody is taken.
static func _full_crew_only(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	crowd.cordon.request(house, house.center())
	var job: GuardJobs.Job = _live(crowd)[0]
	var trio := _trio(crowd, job.at, 4.0)
	_only_free(crowd, [trio[0], trio[2]])
	crowd.guard_jobs._fill()
	t.check(job.crew.is_empty() and not job.started and not crowd.guard_jobs.on_job(trio[0]), "one free man in reach: no job starts")
	_done(made)


## A post group is never left under GROUP_KEEP: two free men of one group make no crew; three do, one stays.
static func _keep_one(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	crowd.cordon.request(house, house.center())
	var job: GuardJobs.Job = _live(crowd)[0]
	var trio := _trio(crowd, job.at, 4.0)
	_place(trio[2], job.at + Vector2(-9.0, 0.0))
	_only_free(crowd, [trio[0], trio[1]])
	crowd.guard_jobs._fill()
	t.check(job.crew.is_empty(), "two free men of one group: the last one stays, no crew")
	crowd.mission_holds.clear()
	_only_free(crowd, trio)
	crowd.guard_jobs._fill()
	t.check(job.crew.size() == 2 and not job.crew.has(trio[2]), "three: two go, the third (farthest) stays at his post")
	_done(made)


## A director's soldier is never a crew man.
static func _mission_man_never(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	crowd.cordon.request(house, house.center())
	var job: GuardJobs.Job = _live(crowd)[0]
	var m := crowd.add_soldier(job.at + Vector2(1.0, 0.0))
	var m2 := crowd.add_soldier(job.at + Vector2(1.0, 0.5))
	var trio := _trio(crowd, job.at, 9.0)
	_only_free(crowd, trio + [m, m2])
	crowd.guard_jobs._fill()
	t.check(not job.crew.has(m) and not job.crew.has(m2), "an add_soldier() man is not taken")
	t.check(crowd.guard_jobs.mission_man(m) and not crowd.guard_jobs.on_job(m), "and stays a mission man off the board")
	_done(made)


## stretch(): ends 6.0 apart on the road's centre line, clamped to the road; ties go to the first road; the rect holds the ruin.
static func _shape(t) -> void:
	var roads: Array = [Rect2(-15.3, 8.3, 30.6, 1.4), Rect2(2.0, -4.6, 1.4, 19.9)]
	var s := CordonDuty.stretch(roads, Vector2(0.0, 9.5), CordonDuty.CORDON_HALF)
	t.near((s[0] as Vector2).distance_to(s[1]), 6.0, 0.001, "ends 6.0 apart")
	t.near((s[0] as Vector2).y, 9.0, 0.001, "on the road's centre line")
	t.check((s[2] as Rect2).is_equal_approx(Rect2(-3.0, 8.3, 6.0, 1.4)), "the rect is the road's width between the ends (%s)" % s[2])
	var edge := CordonDuty.stretch(roads, Vector2(40.0, 9.0), CordonDuty.CORDON_HALF)
	t.check((edge[1] as Vector2).x <= 15.3 + 0.001 and (edge[0] as Vector2).distance_to(edge[1]) <= 6.0 + 0.001, "clamped to the road's end")
	var tie := CordonDuty.stretch(roads, Vector2(2.5, 9.0), CordonDuty.CORDON_HALF)
	t.check((tie[2] as Rect2).size.x > (tie[2] as Rect2).size.y, "a point on two roads: the first in the list (the east-west one)")
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	crowd.cordon.request(house, house.center())
	var job: GuardJobs.Job = _live(crowd)[0]
	t.check((job.data.rect as Rect2).encloses(house.footprint.grow(CordonDuty.FOOT_GROW)), "the rect contains the ruin grown by 0.5")
	t.check(job.at.is_equal_approx(((job.data.ends[0] as Vector2) + (job.data.ends[1] as Vector2)) * 0.5), "the job sits at the ends' middle")
	_done(made)


## A calm citizen whose goal lies in the rect, or whose path crosses it, is held off at the next tick.
static func _turns_back(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	t.check(job != null, "(a cordon with its crew)")
	if job == null:
		_done(made)
		return
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var axis := _axis(job)
	var along := crowd._grid.nearest_walkable((job.data.ends[0] as Vector2) - axis * 5.0)
	var beyond := crowd._grid.nearest_walkable((job.data.ends[1] as Vector2) + axis * 5.0)
	var two := _citizens(crowd, 2, along)
	var into: Person = two[0]
	var through: Person = two[1]
	var mid := crowd._grid.nearest_walkable(rect.get_center())
	into.set_goal(mid)
	through.set_goal(beyond)
	t.check(through.path_crosses(rect, CordonDuty.PATH_AHEAD), "(the second citizen's path runs through the rect)")
	var goal_in: Vector2 = into.goal()
	_run_for(crowd, 1.2, two)
	t.check(into.held_off(), "a goal inside the rect: turned back within a tick")
	t.check(through.held_off(), "a path through the rect: turned back too")
	t.check(into.bound_for().is_equal_approx(goal_in), "and he keeps the goal he meant")
	t.check(into.mind == Person.Mind.CALM, "his mind is untouched")
	_done(made)


## Fleeing, panicking, on duty, regrouping citizens and a soldier are never turned back.
static func _never_turns_back(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var mid := crowd._grid.nearest_walkable(rect.get_center())
	var minds := [Person.Mind.FLEE, Person.Mind.PANIC, Person.Mind.DUTY, Person.Mind.REGROUP, Person.Mind.ASSIST, Person.Mind.SHELTER]
	var folk := _citizens(crowd, minds.size(), mid + Vector2(0.0, 0.0))
	for i in folk.size():
		folk[i].set_goal(mid)
		folk[i].mind = minds[i]
	var soldier: Person = null
	for p in crowd.soldiers:
		if p.corps == Person.Corps.NONE and not job.crew.has(p) and not crowd.guard_jobs.mission_man(p):
			soldier = p
			break
	soldier.send_to_post(mid)
	_run_for(crowd, 1.2, folk)
	var held := 0
	for p in folk:
		held += 1 if p.held_off() else 0
	t.check(held == 0, "flee, panic, duty, regroup, assist, shelter: none turned back (%d)" % held)
	t.check(not soldier.held_off() and soldier.anchor.is_equal_approx(mid), "a soldier walks through")
	_done(made)


## A citizen outside the rope cannot be lured to a point beyond it; the Wisp's draw skips him; a clear way still works.
static func _lure_fails(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var axis := _axis(job)
	var side := crowd._grid.nearest_walkable((job.data.ends[0] as Vector2) - axis * 2.0)
	var far_side := (job.data.ends[1] as Vector2) + axis * 2.0
	var two := _citizens(crowd, 2, side)
	t.check(crowd.cordon_blocks(side, far_side), "(the segment crosses the rope)")
	t.check(not two[0].lure(far_side, 5.0), "lure() across the rope fails")
	t.check(not (WillOWisp.drawn(made[3], far_side) as Array).has(two[0]), "the Wisp's draw leaves him out")
	var clear_at := side + (axis.orthogonal() * 4.0 if not crowd.cordon_blocks(side, side + axis.orthogonal() * 4.0) else -axis.orthogonal() * 4.0)
	t.check(not crowd.cordon_blocks(side, clear_at), "(a segment clear of the rope)")
	t.check(two[1].lure(clear_at, 5.0), "a lure that does not cross it still works")
	t.check(rect.has_point(rect.get_center()), "(rect sane)")
	_done(made)


## With no cordon live the lure test is a constant: false at once.
static func _lure_o1(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	t.check(_live(crowd).is_empty() and not crowd.cordon_blocks(Vector2.ZERO, Vector2(30.0, 30.0)), "no cordon live: cordon_blocks() is false")
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	var r := crowd.cordon.rect_of(job)
	t.check(crowd.cordon_blocks(r.get_center() - Vector2(20.0, 0.0), r.get_center() + Vector2(20.0, 0.0)), "a live cordon blocks a segment through its rect")
	t.check(not crowd.cordon_blocks(r.position - Vector2(5.0, 5.0), r.position - Vector2(1.0, 5.0)), "and not one clear of it")
	_done(made)


## A death inside the rope is seen by no cordon man within 2.0; one outside it still is.
static func _inside_unwatched(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var crew: Array = job.crew.duplicate()
	_hide_others(crowd, crew)
	var axis := _axis(job)
	var in_at: Vector2 = (job.data.ends[0] as Vector2) + axis * 1.0
	t.check(rect.has_point(in_at), "(the point is inside the rect)")
	t.check(crowd.nearest_witness(in_at) == null, "a death inside the rope: the crew men within 2.0 witness nothing")
	var out_at: Vector2 = (job.data.ends[0] as Vector2) - axis * 1.0
	t.check(not rect.has_point(out_at) and crowd.nearest_witness(out_at) == job.crew[0], "one just outside the rope is seen by his man")
	_done(made)


## 40 s after the start the job ends: the men go back to their posts, the held citizens take up their goals.
static func _ends_forty(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	var crew: Array = job.crew.duplicate()
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var mid := crowd._grid.nearest_walkable(rect.get_center())
	var folk := _citizens(crowd, 1, crowd._grid.nearest_walkable((job.data.ends[0] as Vector2) - _axis(job) * 5.0))
	folk[0].set_goal(mid)
	_run_for(crowd, 30.0, folk, 0.1)
	t.check(_live(crowd).size() == 1 and folk[0].held_off(), "at 30 s: still up, the citizen still kept off")
	_run_for(crowd, 12.0, folk, 0.1)
	t.check(_live(crowd).is_empty(), "past 40 s: the job is over")
	var home := true
	for p: Person in crew:
		home = home and p.anchor.is_equal_approx(p.post) and not crowd.guard_jobs.on_job(p) and p.stand_face == Vector2.INF and p.talk_left == 0.0
	t.check(home, "both men are back at their posts, not on the board, no stand_face or talk left")
	t.check(not folk[0].held_off() and folk[0].has_goal(), "the citizen is let in and takes up his goal")
	t.check(not crowd.cordon_blocks(rect.position - Vector2(3.0, 0.0), rect.end + Vector2(3.0, 0.0)), "and the rope blocks nothing")
	_done(made)


## Ending lets the held-off citizen's goal back (the stage reaching EVACUATION ends it at once).
static func _ends_releases(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var mid := crowd._grid.nearest_walkable(rect.get_center())
	var folk := _citizens(crowd, 1, crowd._grid.nearest_walkable((job.data.ends[0] as Vector2) - _axis(job) * 5.0))
	folk[0].set_goal(mid)
	_run_for(crowd, 1.2, folk)
	t.check(folk[0].held_off() and not folk[0].has_goal(), "(held off, goal kept back)")
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	_run_for(crowd, 1.2, folk)
	t.check(not folk[0].held_off() and folk[0].has_goal() and folk[0].goal().is_equal_approx(mid), "released: his goal is his own again")
	_done(made)


## Kill one man, lure the other: nobody stands his end, the job ends at the next tick.
static func _held_ends_cordon(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).size() == 1, "(the cordon stands)")
	var a: Person = job.crew[0]
	var b: Person = job.crew[1]
	(made[3] as EnemyField).kill(a, &"mob")
	t.check(b.lure(b.ground_pos + Vector2(1.0, 0.0), 5.0) and b.held_by_god(), "(the other is held by a lure)")
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty(), "one dead, one held: the cordon ends")
	t.check(not crowd.guard_jobs.on_job(b), "and the held man is off the board")
	_done(made)


## The stage reaching EVACUATION ends a live cordon.
static func _evacuation_ends(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	var crew: Array = job.crew.duplicate()
	_arrive(job)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).size() == 1, "(the cordon stands)")
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty(), "EVACUATION: the job is over")
	var home := true
	for p: Person in crew:
		home = home and p.anchor.is_equal_approx(p.post) and not crowd.guard_jobs.on_job(p)
	t.check(home, "its men are back at their posts")
	_done(made)


## An open job that can no longer start never blocks: it ends when the stage passes the window, when the site is gone, and after
## 40 s with no crew.
static func _open_job_ends(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	Corps.hold_free(crowd)
	var house := _site(made)
	crowd.cordon.request(house, house.center())
	_run_for(crowd, 2.2, [], 0.1)
	t.check(_live(crowd).size() == 1, "(an open job, nobody free)")
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	_run_for(crowd, 1.2, [], 0.1)
	t.check(_live(crowd).is_empty(), "EVACUATION ends an open job")
	_done(made)
	var made2 := _world()
	var crowd2: Crowd = made2[0]
	Corps.hold_free(crowd2)
	crowd2.cordon.request(_site(made2), _site(made2).center())
	_run_for(crowd2, CordonDuty.CORDON_SECONDS - 5.0, [], 0.1)
	t.check(_live(crowd2).size() == 1, "an open job waits")
	_run_for(crowd2, 8.0, [], 0.1)
	t.check(_live(crowd2).is_empty(), "and goes after 40 s without a crew")
	_done(made2)


## A crew man freed under the job: the tick survives, the job runs short-handed with the other.
static func _freed_man(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	_run_for(crowd, 1.2)
	var gone: Person = job.crew[0]
	var stays: Person = job.crew[1]
	crowd.soldiers.erase(gone)
	gone.free()
	_run_for(crowd, 2.2)
	t.check(_live(crowd).size() == 1 and job.crew.size() == 1 and job.crew[0] == stays, "a freed man: the job goes on with the other")
	crowd.soldiers.erase(stays)
	stays.free()
	_run_for(crowd, 2.2)
	t.check(_live(crowd).is_empty(), "both freed: the job ends")
	_done(made)


## A new act (guard_jobs.clear()) drops every cordon: no rect blocks, held citizens are let in, stand_face and talk_left clear.
static func _clear_resets(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var crew: Array = job.crew.duplicate()
	var folk := _citizens(crowd, 1, crowd._grid.nearest_walkable((job.data.ends[0] as Vector2) - _axis(job) * 5.0))
	folk[0].set_goal(crowd._grid.nearest_walkable(rect.get_center()))
	_run_for(crowd, 1.2, folk)
	t.check(folk[0].held_off() and (crew[0].stand_face != Vector2.INF), "(held off; the men face out)")
	crowd.guard_jobs.clear()
	t.check(not folk[0].held_off(), "clear(): the held citizen is let in")
	t.check(not crowd.cordon_blocks(rect.position - Vector2(3.0, 0.0), rect.end + Vector2(3.0, 0.0)) and not crowd.cordon.inside(rect.get_center()), "no rect blocks or counts any more")
	t.check(crew[0].stand_face == Vector2.INF and crew[1].stand_face == Vector2.INF and crew[0].talk_left == 0.0 and crew[1].talk_left == 0.0, "no stand_face or talk_left stays")
	_done(made)


## The nearer end man talks (talk_left 1.0) when a citizen is turned back; it counts down; the talk anim shows while it runs.
static func _talk_left(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var house := _site(made)
	var job := _up(made, house)
	if job == null:
		t.check(false, "(a cordon with its crew)")
		_done(made)
		return
	_arrive(job)
	var rect := crowd.cordon.rect_of(job)
	var near_end: Vector2 = job.data.ends[0]
	var folk := _citizens(crowd, 1, crowd._grid.nearest_walkable(near_end - _axis(job) * 4.0))
	folk[0].set_goal(crowd._grid.nearest_walkable(rect.get_center()))
	var nearer: Person = job.crew[0] if (job.crew[0] as Person).ground_pos.distance_to(folk[0].ground_pos) <= (job.crew[1] as Person).ground_pos.distance_to(folk[0].ground_pos) else job.crew[1]
	_run_for(crowd, 1.05, folk)
	t.check(folk[0].held_off() and nearer.talk_left > 0.0, "the nearer end man talks to the citizen (%.2f)" % nearer.talk_left)
	if nearer._own_art(13):
		t.check(nearer._interact_anim() == 13, "and shows the talk anim, standing")
	var before := nearer.talk_left
	nearer.tick(0.2)
	t.check(nearer.talk_left < before, "talk_left counts down")
	_done(made)
