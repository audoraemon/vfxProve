extends RefCounted
## Soldier jobs, Task 1: the guard job board. Ordinary guards at the post the town gave them are the only ones a job may take;
## post groups keep a share at home; mission hooks claim soldiers and are dropped with the mission; the rally ends the jobs.

const Corps := preload("res://tests/test_corps.gd")
const CapPeople := preload("res://tests/test_capital_people.gd")


static func _made() -> Array:
	return Corps._crowd()


static func _house(env: EnvironmentField) -> Structure:
	for s in env.structures():
		if s.kind == Structure.Kind.HOUSE and s.role == &"house":
			return s
	return null


## An ordinary guard (corps NONE) of `group`, standing at his post.
static func _guard(crowd: Crowd, group: int) -> Person:
	for p in crowd.soldiers:
		if p.post_group == group and p.corps == Person.Corps.NONE and crowd.guard_jobs.at_post(p):
			return p
	return null


static func _posts_and_groups(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var sizes := [0, 0, 0, 0]
	var ok := true
	for i in crowd.soldiers.size():
		var p := crowd.soldiers[i]
		ok = ok and p.town_post == p.post and p.town_post != Vector2.INF
		if p.post_group >= 0:
			sizes[p.post_group] += 1
	t.check(ok, "every spawned soldier has town_post == post")
	t.check(sizes == [30, 30, 20, 20], "Aldermere groups are 30/30/20/20 (%s)" % [sizes])
	var extra := crowd.add_soldier(Vector2(0.0, 0.0))
	t.check(extra.post_group == -1, "add_soldier() gives post_group -1")
	t.check(crowd.citizens[0].post_group == -1 and crowd.citizens[0].town_post == Vector2.INF, "a citizen has no post group")
	Corps._done(made)


static func _on_watch(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var g := _guard(crowd, 0)
	t.check(g.at_own_post() and g.on_watch(), "a soldier at his spawn post is at it and on watch")
	g.send_to_post(g.post + Vector2(5.0, 0.0))
	g.ground_pos = g.goal()
	g._goal = Vector2.INF
	g._path = PackedVector2Array()
	t.check(not g.at_own_post() and g.on_watch(), "a stationed soldier (anchor moved) is on watch, not at his own post")
	g.go_duty(g.ground_pos + Vector2(2.0, 0.0))
	t.check(g.on_watch(), "a soldier on duty is on watch")
	g.send_to_post(g.post)
	g.ground_pos = g.post
	g._goal = Vector2.INF
	var house := _house(env)
	g.assist(house, true)
	t.check(not g.at_own_post() and not g.on_watch(), "a soldier sent to a fire is neither")
	g.stand_down()
	g.ground_pos = g.post
	g._goal = Vector2.INF
	g.confuse(3.0)
	t.check(not g.at_own_post() and not g.on_watch(), "a confused soldier is neither")
	var h := _guard(crowd, 1)
	crowd.guard_jobs.take(h, house)
	t.check(h.on_guard_job and not h.on_watch(), "a guard on a job is not on watch")
	Corps._done(made)


static func _eligible(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var g := _guard(crowd, 0)
	t.check(gj.eligible(g), "an ordinary guard at his post is eligible")
	for c in [Person.Corps.RESCUE, Person.Corps.MARSHAL, Person.Corps.ESCORT]:
		g.corps = c
		t.check(not gj.eligible(g), "corps %d is not eligible" % c)
	g.corps = Person.Corps.NONE
	var h := _guard(crowd, 1)
	h.post = h.post + Vector2(3.0, 0.0)
	h.anchor = h.post
	t.check(not gj.eligible(h), "a guard re-posted by someone is not eligible")
	var m := _guard(crowd, 2)
	crowd.mission_holds.append(func(p: Person) -> bool: return p == m)
	t.check(not gj.eligible(m), "a guard covered by a mission hold is not eligible")
	var pa := _guard(crowd, 3)
	crowd.sweep.request(pa.ground_pos)
	gj._fill()
	var seen := 0
	for p in crowd.soldiers:
		if gj.kind_of(p) == GuardJobs.Kind.SWEEP:
			seen += 1
			t.check(not gj.eligible(p), "a sweep man is not eligible")
	t.check(seen > 0, "someone went to sweep")
	Corps._done(made)


static func _pick_share(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var c: Vector2 = City.current().landmark(&"barracks_yard").get_center()
	var n := gj.free_near(c, 10.0).size()
	t.check(n > 2, "guards stand near the yard (%d)" % n)
	t.check(gj.pick(c, 10.0, 0, 1000).size() == ceili(n * 0.5), "a job takes half the guards near it (n=%d)" % n)
	t.check(gj.pick(c, 10.0, 0, 2).size() <= 2, "and no more than its cap")
	var near := gj.free_near(c, 10.0)
	var sorted := true
	for i in range(1, near.size()):
		sorted = sorted and near[i - 1].ground_pos.distance_to(c) <= near[i].ground_pos.distance_to(c)
	t.check(sorted, "free_near is nearest first")
	Corps._done(made)


static func _group_keep(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var at: Vector2 = City.current().citadel_origin()
	var kept := 0
	for p in crowd.soldiers:
		if p.post_group == 2:
			if kept < 2:
				kept += 1
			else:
				p.send_to_post(p.post + Vector2(0.0, 6.0))
	var taken := 0
	for p in gj.pick(at, 10.0, 0, 1000):
		if p.post_group == 2:
			taken += 1
	t.check(taken == 1, "only one of two citadel guards at their posts may go (%d)" % taken)
	Corps._done(made)


static func _hooks_cleared(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var g := _guard(crowd, 0)
	crowd.mission_holds.append(func(p: Person) -> bool: return p == g)
	t.check(crowd.held_by_mission(g), "a registered hook holds his man")
	crowd.clear_mission_hooks()
	t.check(not crowd.held_by_mission(g) and crowd.mission_holds.is_empty(), "cleared hooks hold nobody")
	var probe := Node.new()
	crowd.mission_holds.append(Callable(probe, "is_inside_tree"))
	probe.free()
	t.check(not crowd.held_by_mission(g), "a hook whose object was freed is skipped")
	var d := MissionDirector.new().setup(null, crowd, made[5], null)
	t.check(crowd.mission_holds.size() == 2, "a director registers its hold")
	d.reserved.append(g)
	t.check(crowd.held_by_mission(g), "a reserved soldier is held by his director")
	crowd.clear_mission_hooks()
	Corps._done(made)


static func _close(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var house := _house(made[1])
	var g := _guard(crowd, 0)
	g.assist(house, true)
	gj.take(g, house)
	t.check(gj.on_job(g) and gj.job_of(g) == house and not gj.eligible(g), "a guard on a job is on it")
	crowd.rally()
	t.check(gj.is_open() and gj.on_job(g) and g.mind == Person.Mind.ASSIST, "the call-up leaves the fire fighter on his fire and the board open")
	crowd._on_citadel_fallen()
	t.check(not gj.is_open() and not gj.on_job(g) and not g.on_guard_job, "the Citadel's fall closes the board")
	t.check(g.assist_fire == null and g.mind == Person.Mind.HOLD, "and the fire fighter holds the ground")
	Corps._done(made)


static func _prune(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var house := _house(made[1])
	var g := _guard(crowd, 0)
	g.assist(house, true)
	gj.take(g, house)
	gj.prune()
	t.check(gj.on_job(g), "prune keeps a man still on his fire")
	g.stand_down()
	gj.prune()
	t.check(not gj.on_job(g) and not g.on_guard_job, "prune drops a man who left his fire")
	var h := _guard(crowd, 1)
	h.assist(house, true)
	gj.take(h, house)
	h.confuse(3.0)
	gj.prune()
	t.check(gj.on_job(h), "prune keeps a god-held guard's record")
	h.die(&"test")
	gj.prune()
	t.check(not gj.on_job(h), "prune drops the dead")
	# Final review I4: a fire fighter a director re-posts is left at that station when his record drops.
	var r := _guard(crowd, 2)
	r.assist(house, true)
	gj.take(r, house)
	var station := r.post + Vector2(2.5, 0.0)
	r.send_to_post(station)
	gj.prune()
	t.check(not gj.on_job(r) and r.anchor.is_equal_approx(station), "prune leaves a re-posted fire fighter at the director's station")
	Corps._done(made)


## The house nearest the barracks yard, set burning (hot enough to be fought, below ABANDON).
static func _yard_fire(crowd: Crowd, env: EnvironmentField) -> Structure:
	var c: Vector2 = City.current().landmark(&"barracks_yard").get_center()
	var best: Structure = null
	for s in env.structures():
		if s.kind == Structure.Kind.HOUSE and s.role == &"house" and not s.destroyed:
			if best == null or s.center().distance_to(c) < best.center().distance_to(c):
				best = s
	crowd.fires.ignite(best, 0.4)
	return best


static func _on_fire(crowd: Crowd, s: Structure) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.soldiers:
		if p.mind == Person.Mind.ASSIST and p.assist_fire == s:
			out.append(p)
	return out


static func _fires(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	# Soldiers a job must leave alone: a guard sent to a spot, a re-posted one, a mission-held one, and corps soldiers.
	var a := _guard(crowd, 0)
	a.send_to_post(a.post + Vector2(2.0, 0.0))
	var b := _guard(crowd, 0)
	b.post = b.post + Vector2(1.0, 0.0)
	b.anchor = b.post
	var m := _guard(crowd, 0)
	crowd.mission_holds.append(func(p: Person) -> bool: return p == m)
	var corps_men: Array[Person] = []
	for c in [Person.Corps.RESCUE, Person.Corps.MARSHAL, Person.Corps.ESCORT, Person.Corps.KNIGHT]:
		var k := _guard(crowd, 0)
		k.corps = c
		corps_men.append(k)
	crowd.alarms.stage = crowd.profile.fire_from
	var house := _yard_fire(crowd, made[1])
	var n := gj.free_near(house.center(), FireManager.RECRUIT_REACH).size()
	t.check(n > 0, "guards stand near the burning house (%d)" % n)
	crowd.fires._recruit()
	var guards := 0
	var taken: Array[Person] = []
	for p in _on_fire(crowd, house):
		if p.corps == Person.Corps.NONE and gj.job_of(p) == house:
			guards += 1
			taken.append(p)
	t.check(guards == ceili(n * 0.5), "ordinary guards on the fire are half those near it (%d of %d)" % [guards, n])
	t.check(crowd.fires.guards_on(house) == guards, "guards_on counts them")
	var citizens := 0
	for p in crowd.citizens:
		if p.mind == Person.Mind.ASSIST and p.assist_fire == house:
			citizens += 1
	t.check(citizens <= crowd.profile.fire_crew, "and the citizens' brigade keeps its own cap (%d)" % citizens)
	var kept := {}
	for p in crowd.soldiers:
		if gj.at_post(p):
			kept[p.post_group] = int(kept.get(p.post_group, 0)) + 1
	var groups_ok := true
	for g in 4:
		groups_ok = groups_ok and int(kept.get(g, 0)) >= GuardJobs.GROUP_KEEP
	t.check(groups_ok, "every post group keeps a guard at his post (%s)" % [kept])
	var stray := false
	for p in [a, b, m] + corps_men:
		stray = stray or (p.mind == Person.Mind.ASSIST and p.assist_fire == house) or gj.on_job(p)
	t.check(not stray, "no sent, re-posted, mission-held or corps soldier is on the fire")
	var safety := 0
	while crowd.fires.is_burning(house) and safety < 100:
		crowd.fires.douse(house)
		safety += 1
	gj.prune()
	var home := true
	for p in taken:
		home = home and p.mind == Person.Mind.POST and p.anchor.is_equal_approx(p.post) and not gj.on_job(p)
	t.check(not taken.is_empty() and home, "a fire put out sends its guards back to their posts")
	crowd.clear_mission_hooks()
	Corps._done(made)


static func _forgo(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.forgo_rally()
	t.check(crowd.guard_jobs.is_open(), "a leaderless town's forgo_rally leaves the job board open")
	Corps._done(made)
	made = _made()
	crowd = made[0]
	crowd.rally()
	t.check(crowd.guard_jobs.is_open(), "while rally() leaves it open")
	Corps._done(made)


static func _rally_clears(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = crowd.profile.fire_from
	var house := _yard_fire(crowd, made[1])
	crowd.fires._recruit()
	t.check(crowd.fires.guards_on(house) > 0, "guards are on the fire before the rally")
	crowd.rally()
	var left := 0
	for p in crowd.soldiers:
		if p.corps == Person.Corps.NONE and (p.mind == Person.Mind.ASSIST or p.assist_fire != null):
			left += 1
	t.check(left > 0 and crowd.fires.guards_on(house) > 0, "the call-up leaves the guards at the fire (%d there)" % left)
	crowd.fires._recruit()
	t.check(crowd.fires.guards_on(house) > 0, "and the board stays open to a new recruit")
	Corps._done(made)


static func _unprepared(t) -> void:
	var made := Corps._crowd(ResponseProfile.Tier.UNPREPARED)
	var crowd: Crowd = made[0]
	crowd._on_stage(AlarmManager.Stage.CITY_EMERGENCY, "")
	crowd.alarms.stage = crowd.profile.fire_from
	var house := _yard_fire(crowd, made[1])
	crowd.fires._recruit()
	t.check(crowd.fires.guards_on(house) > 0, "an unprepared town's rally came first, yet its free guards turn out at the fire")
	Corps._done(made)


static func _capital_fire(t) -> void:
	var b: Dictionary = CapPeople._build()
	var crowd: Crowd = b.crowd
	var env: EnvironmentField = b.env
	var c: Vector2 = City.current().landmark(&"barracks_yard").get_center()
	var best: Structure = null
	for s in env.structures():
		if not s.destroyed and FireManager.burns(s) and s.kind == Structure.Kind.HOUSE:
			if best == null or s.center().distance_to(c) < best.center().distance_to(c):
				best = s
	t.check(best != null, "the capital has a plot that burns")
	if best != null:
		crowd.alarms.stage = crowd.profile.fire_from
		crowd.fires.ignite(best, 0.4)
		crowd.fires._recruit()
		var guards := 0
		for p in _on_fire(crowd, best):
			if p.corps == Person.Corps.NONE:
				guards += 1
		t.check(guards >= 1, "capital guards turn out to its fire (%d)" % guards)
		var kept := {}
		for p in crowd.soldiers:
			if crowd.guard_jobs.at_post(p):
				kept[p.post_group] = int(kept.get(p.post_group, 0)) + 1
		var ok := true
		for g in kept.keys():
			ok = ok and int(kept[g]) >= 1
		t.check(ok and kept.size() >= 3, "every capital post group keeps a guard at his post (%s)" % [kept])
	crowd.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


static func _kinds_order(t) -> void:
	t.check(GuardJobs.Kind.keys() == ["CITADEL", "FIRE", "PILE", "SHELTER", "SWEEP", "CORPSE", "CORDON", "GATE"], "kinds in priority order")
	t.check(GuardJobs.Kind.CITADEL == 0 and GuardJobs.Kind.GATE == 7, "CITADEL is 0 and GATE is 7")


static func _mission_man_kinds(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var house := _house(made[1])
	var a := _guard(crowd, 0)
	t.check(not gj.mission_man(a), "an ordinary guard at spawn is not a mission man")
	var b := _guard(crowd, 0)
	b.post = b.post + Vector2(3.0, 0.0)
	b.anchor = b.post
	t.check(gj.mission_man(b), "a guard whose post was overwritten is a mission man")
	var c := _guard(crowd, 1)
	crowd.mission_holds.append(func(p: Person) -> bool: return p == c)
	t.check(gj.mission_man(c), "a guard a mission hook names is a mission man")
	var d := _guard(crowd, 1)
	d.go_duty(d.ground_pos + Vector2(2.0, 0.0))
	t.check(gj.mission_man(d), "a guard sent on duty is a mission man")
	var e := _guard(crowd, 2)
	e.send_to_post(e.post + Vector2(4.0, 0.0))
	e.ground_pos = e.goal()
	e._goal = Vector2.INF
	e._path = PackedVector2Array()
	t.check(gj.mission_man(e), "a guard a director stationed away from his post is a mission man")
	var f := crowd.add_soldier(Vector2(0.0, 0.0))
	t.check(gj.mission_man(f), "an add_soldier() guard is a mission man")
	var g := _guard(crowd, 3)
	g.assist(house, true)
	gj.take(g, house)
	t.check(not gj.mission_man(g), "a guard on a fire job is not a mission man")
	var pa := _guard(crowd, 3)
	crowd.sweep.request(pa.ground_pos)
	gj._fill()
	var seen := 0
	for p in crowd.soldiers:
		if gj.kind_of(p) == GuardJobs.Kind.SWEEP:
			seen += 1
			t.check(not gj.mission_man(p), "a sweep man is not a mission man")
	t.check(seen > 0, "someone went to sweep")
	t.check(not gj.mission_man(null), "nobody is not a mission man")
	crowd.clear_mission_hooks()
	Corps._done(made)


## Steps the crowd `frames` frames with the board pruning alone (the old way) or stepping.
class PruneOnly extends GuardJobs:
	## The old frame: prune only.
	func step(_delta: float) -> void:
		prune()


static func _step_no_change(t) -> void:
	var made_a := _made()
	var made_b := _made()
	var crowd_a: Crowd = made_a[0]
	var crowd_b: Crowd = made_b[0]
	crowd_b.guard_jobs = PruneOnly.new().setup(crowd_b)
	for m in [made_a, made_b]:
		var crowd: Crowd = m[0]
		crowd.alarms.stage = crowd.profile.fire_from
		_yard_fire(crowd, m[1])
	for i in 600:
		crowd_a.advance(1.0 / 60.0)
		crowd_b.advance(1.0 / 60.0)
	var same := crowd_a.soldiers.size() == crowd_b.soldiers.size()
	var jobs := 0
	for i in mini(crowd_a.soldiers.size(), crowd_b.soldiers.size()):
		var x := crowd_a.soldiers[i]
		var y := crowd_b.soldiers[i]
		same = same and x.mind == y.mind and x.anchor.is_equal_approx(y.anchor) and x.on_guard_job == y.on_guard_job
		if x.on_guard_job:
			jobs += 1
	t.check(jobs > 0, "guards went to the yard fire (%d)" % jobs)
	t.check(same, "step() leaves every soldier's mind, anchor and job as prune() did")
	Corps._done(made_a)
	Corps._done(made_b)


static func _cap_scales(t) -> void:
	var made := _made()
	var gj: GuardJobs = made[0].guard_jobs
	t.check(gj.cap(2) == 2, "Aldermere (100): cap 2 stays 2")
	Corps._done(made)
	var b: Dictionary = CapPeople._build()
	var crowd: Crowd = b.crowd
	var want := ceili(2.0 * crowd.spawned_soldiers / 100.0)
	t.check(crowd.guard_jobs.cap(2) == want and want == 4, "the Capital: cap 2 is %d (spawned %d)" % [want, crowd.spawned_soldiers])
	crowd.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


static func _tags_empty(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	t.check(crowd.guard_jobs.tags().is_empty(), "no job: no tags")
	var hud := Hud.new()
	var before := hud.all_tags().size()
	hud._crowd = crowd
	hud._rules = Rules.new()
	t.check(hud.all_tags().size() == before, "an empty board adds nothing to the HUD's tags")
	hud._rules.free()
	hud.free()
	Corps._done(made)


static func _duty_event_banner(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var got := []
	crowd.duty_event.connect(func(k: int, text: String, at: Vector2) -> void: got.append([k, text, at]))
	crowd.duty_event.emit(GuardJobs.Kind.SWEEP, "X", Vector2(1.0, 2.0))
	t.check(got == [[GuardJobs.Kind.SWEEP, "X", Vector2(1.0, 2.0)]], "duty_event carries kind, text and place")
	Corps._done(made)


## A duty of kind CORDON that posts one job of one man and notes when it was cleared.
class StubDuty extends Duty:
	## Whether clear() ran.
	var cleared := false
	## The job it posted.
	var job: GuardJobs.Job

	func kind() -> int:
		return GuardJobs.Kind.CORDON

	func post_jobs() -> void:
		if job == null:
			job = board.post(GuardJobs.Kind.CORDON, crowd.soldiers[0].ground_pos, 1)

	func clear() -> void:
		cleared = true


static func _clear_resets_jobs(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var stub := StubDuty.new().setup(gj, crowd)
	gj.add_duty(stub)
	gj.step(1.0)
	t.check(gj.jobs.size() == 1 and stub.job.crew.size() == 1, "the board filled the stub's job with one man")
	var man: Person = stub.job.crew[0]
	t.check(gj.on_job(man) and gj.kind_of(man) == GuardJobs.Kind.CORDON and stub.job.started, "he is on a CORDON job")
	gj.clear()
	t.check(gj.jobs.is_empty() and not gj.on_job(man) and stub.cleared, "clear() drops every job and clears each duty")
	t.check(not man.on_guard_job and gj.clock == 0.0, "and the man is free of the flag and the clock is back to 0")
	crowd.clear()
	Corps._done(made)


static func _called_up(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	t.check(not crowd.called_up(), "a new crowd is not called up")
	crowd.forgo_rally()
	t.check(not crowd.called_up(), "forgo_rally() alone is no call-up")
	Corps._done(made)
	made = _made()
	crowd = made[0]
	crowd.rally()
	t.check(crowd.called_up(), "rally() calls up")
	crowd.clear()
	t.check(not crowd.called_up(), "clear() resets it")
	(made[2] as Node).free()


## A duty of `k` that posts one job of `need` men at `at`.
class OrderDuty extends Duty:
	## The kind it runs.
	var k := 0
	## Where its job is.
	var at := Vector2.ZERO
	## The crew it wants.
	var need := 1
	## Its job once posted.
	var job: GuardJobs.Job

	func kind() -> int:
		return k

	func post_jobs() -> void:
		if job == null:
			job = board.post(k, at, need)


static func _only_free(crowd: Crowd, men: Array) -> void:
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier and not men.has(p))


static func _fill_order(t) -> void:
	var made := _made()
	var crowd: Crowd = made[0]
	var gj := crowd.guard_jobs
	var men: Array = []
	for p in crowd.soldiers:
		if p.post_group == 0 and p.corps == Person.Corps.NONE and men.size() < 3:
			men.append(p)
	_only_free(crowd, men)
	var near: Person = men[0]
	var sweep := OrderDuty.new().setup(gj, crowd) as OrderDuty
	sweep.k = GuardJobs.Kind.SWEEP
	sweep.at = near.ground_pos
	sweep.need = 1
	var cordon := OrderDuty.new().setup(gj, crowd) as OrderDuty
	cordon.k = GuardJobs.Kind.CORDON
	cordon.at = near.ground_pos
	cordon.need = 2
	gj.add_duty(cordon)
	gj.add_duty(sweep)
	gj.step(1.0)
	t.check(sweep.job.crew == [near] and sweep.job.started, "the higher kind fills first, from the nearest man")
	t.check(cordon.job.crew.is_empty() and not cordon.job.started, "keep-one leaves one man free: the 2-man job assigns nobody")
	Corps._done(made)
	# Ties break by stagger.
	made = _made()
	crowd = made[0]
	gj = crowd.guard_jobs
	men = []
	for p in crowd.soldiers:
		if p.post_group == 0 and p.corps == Person.Corps.NONE and men.size() < 3:
			men.append(p)
	var spot: Vector2 = (men[1] as Person).post
	for i in [1, 2]:
		var m: Person = men[i]
		m.post = spot
		m.town_post = spot
		m.anchor = spot
		m.ground_pos = spot
	_only_free(crowd, men)
	var duty := OrderDuty.new().setup(gj, crowd) as OrderDuty
	duty.k = GuardJobs.Kind.CORDON
	duty.at = spot
	duty.need = 1
	gj.add_duty(duty)
	gj.step(1.0)
	var want: Person = men[1] if (men[1] as Person).stagger < (men[2] as Person).stagger else men[2]
	t.check(duty.job.crew == [want], "two men the same distance away: the lower stagger goes")
	Corps._done(made)


static func run(t) -> void:
	_called_up(t)
	_fill_order(t)
	_kinds_order(t)
	_mission_man_kinds(t)
	_step_no_change(t)
	_cap_scales(t)
	_tags_empty(t)
	_duty_event_banner(t)
	_clear_resets_jobs(t)
	_posts_and_groups(t)
	_on_watch(t)
	_eligible(t)
	_pick_share(t)
	_group_keep(t)
	_hooks_cleared(t)
	_close(t)
	_prune(t)
	_fires(t)
	_forgo(t)
	_rally_clears(t)
	_unprepared(t)
	_capital_fire(t)
