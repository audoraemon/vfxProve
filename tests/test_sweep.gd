extends RefCounted
## Soldier duties, slice d: the sweep. A seen power (danger_landed with a witness, a seen Silent Doom kill) or a district's Local
## Emergency posts a SWEEP job of four free soldiers: they go door to door through the district for 30 s with the eye badge over
## them, see a power from 4.0 instead of 2.0, add extra alarm when a power is seen under their eyes, and are never a posted watch.

const Corps := preload("res://tests/test_corps.gd")
const C := preload("res://tests/test_cordon.gd")
const CapPeople := preload("res://tests/test_capital_people.gd")
const Warning := preload("res://tests/test_warning.gd")
const SWEEP := GuardJobs.Kind.SWEEP
const STEP := 1.0 / 60.0


static func run(t) -> void:
	_seen_trigger(t)
	_unseen_none(t)
	_witness_rules(t)
	_doom_seen(t)
	_local_emergency(t)
	_hushed_veiled_none(t)
	_one_per_district(t)
	_cap_two(t)
	_crew_four(t)
	_mission_man_never(t)
	_clock_starts_inside(t)
	_doors_six(t)
	_watch_sight(t)
	_watch_sight_report(t)
	_extra_alarm(t)
	_not_on_watch(t)
	_ends_thirty(t)
	_held_squad_breaks(t)
	_evacuation_ends(t)
	_open_job_ends(t)
	_freed_man(t)
	_clear_resets(t)
	_capital_sweep(t)
	_one_power_one_charge(t)
	_never_arrives_ends(t)
	_lane_swept_where_seen(t)
	_director_copy_reach(t)
	_sweep_men_keep_nerve(t)
	_stands_off_danger(t)


static func _jobs(crowd: Crowd) -> Array[GuardJobs.Job]:
	return crowd.guard_jobs.live(SWEEP)


## The district (index) with the most standing houses.
static func _busy(made: Array) -> int:
	var districts: Array = City.current().districts()
	var best := 0
	var best_n := -1
	for i in districts.size():
		var n := 0
		for s in (made[1] as EnvironmentField).structures():
			if s.kind == Structure.Kind.HOUSE and not s.destroyed and (districts[i] as Rect2).has_point(s.center()):
				n += 1
		if n > best_n:
			best_n = n
			best = i
	return best


## Open ground at the centre of district `i`.
static func _spot(made: Array, i: int) -> Vector2:
	var r: Rect2 = City.current().districts()[i]
	return (made[4] as WalkGrid).nearest_walkable(r.get_center())


## A loud power lands at `at`.
static func _land(crowd: Crowd, at: Vector2, radius := 1.0) -> void:
	var pts: Array[Vector2] = [at]
	crowd.danger_landed.emit("test", pts, radius)


## `p` stands calm out of doors at `at`, no goal.
static func _put(p: Person, at: Vector2) -> void:
	p.inside = false
	p.mind = Person.Mind.CALM
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at


## `n` ordinary yard guards (post group 0, no corps, at their posts) set at 1, 2, ... units east of `at`.
static func _guards(crowd: Crowd, at: Vector2, n: int, step := 1.0) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.soldiers:
		if out.size() >= n:
			break
		if p.post_group == 0 and p.corps == Person.Corps.NONE and crowd.guard_jobs.at_post(p):
			C._place(p, at + Vector2(step * (out.size() + 1), 0.0))
			out.append(p)
	return out


## A sweep of `district` posted at `at` with five guards at hand (only they are free): the job once filled; null when it took no crew.
static func _up(made: Array, at: Vector2, only := true) -> GuardJobs.Job:
	var crowd: Crowd = made[0]
	var five := _guards(crowd, at, 5, 0.5)
	if only:
		C._only_free(crowd, five)
	crowd.sweep.request(at)
	crowd.guard_jobs._fill()
	var live := _jobs(crowd)
	return live[0] if not live.is_empty() and live[0].crew.size() == SweepDuty.CREW else null


## Every crew man stands on the spot he was sent to.
static func _arrive(job: GuardJobs.Job) -> void:
	for p: Person in job.crew:
		var at: Vector2 = job.data.at_spot[p]
		p.ground_pos = at
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = at


static func _texts(crowd: Crowd) -> Array[String]:
	var out: Array[String] = []
	crowd.duty_event.connect(func(_k: int, text: String, _at: Vector2) -> void: out.append(text))
	return out


## A seen power (a citizen 1.5 off) posts one sweep in that district.
static func _seen_trigger(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	_put(crowd.citizens[0], at + Vector2(1.5, 0.0))
	_land(crowd, at)
	var jobs := _jobs(crowd)
	t.check(jobs.size() == 1, "a seen power: one sweep job (%d)" % jobs.size())
	if jobs.size() == 1:
		t.check(jobs[0].data.district == AlarmManager.district_of(at) and jobs[0].need == SweepDuty.CREW and jobs[0].reach == INF,
			"in that district, a crew of 4, no reach limit")
		t.check(jobs[0].data.seen_at == at, "remembering where it was seen")
	C._done(made)


## The same landing with nobody about posts none.
static func _unseen_none(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	C._hide_others(crowd, [])
	_land(crowd, at)
	t.check(_jobs(crowd).is_empty(), "a landing nobody sees: no sweep")
	C._done(made)


## Who counts as a witness of a power: awake, not god-held, not guised, not unseen; within 2.0 or the radius, or a watch_far man's 4.0.
static func _witness_rules(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	C._hide_others(crowd, [])
	var pts: Array[Vector2] = [at]
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var g: Person = crowd.citizens[2]
	for p in [a, b, g]:
		_put(p, at + Vector2(1.0, 0.0))
	a.mind = Person.Mind.ASLEEP
	b.mind = Person.Mind.CONFUSED
	g.statuses[&"guise"] = 5.0
	t.check(crowd.power_witness(pts, 1.0) == null, "only an asleep, a god-held and a guised person near: no witness")
	var inside: Person = crowd.citizens[3]
	_put(inside, at + Vector2(1.0, 0.0))
	inside.inside = true
	t.check(crowd.power_witness(pts, 1.0) == null, "nor one inside a house")
	var far: Person = crowd.citizens[4]
	_put(far, at + Vector2(3.0, 0.0))
	t.check(crowd.power_witness(pts, 1.0) == null, "3.0 away with radius 1.0: out of reach (2.0)")
	t.check(crowd.power_witness(pts, 3.5) == far, "inside the radius at 3.0: a witness")
	var near: Person = crowd.citizens[5]
	_put(near, at + Vector2(1.9, 0.0))
	t.check(crowd.power_witness(pts, 1.0) == near, "1.9 away: within DOOM_WITNESS")
	_put(near, at + Vector2(1.9, 0.0))
	near.inside = true
	far.watch_far = true
	t.check(crowd.power_witness(pts, 1.0) == far, "a watch_far man sees from 3.0 (4.0)")
	_put(far, at + Vector2(4.5, 0.0))
	t.check(crowd.power_witness(pts, 1.0) == null, "but not from 4.5")
	_put(far, at + Vector2(1.0, 0.0))
	var law: Person = crowd.citizens[6]
	_put(law, at + Vector2(0.5, 0.0))
	far.mind = Person.Mind.PANIC
	t.check(crowd.power_witness(pts, 1.0) == law or crowd.power_witness(pts, 1.0) == far, "the nearest of those who qualify")
	t.check(crowd.power_witness(pts, 1.0) == law, "the nearest of two is chosen (0.5 < 1.0)")
	C._done(made)


## A Silent Doom kill with a witness posts a sweep; an unwitnessed one posts none.
static func _doom_seen(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var v: Person = crowd.citizens[0]
	_put(v, at)
	_put(crowd.citizens[1], at + Vector2(1.0, 0.0))
	(made[3] as EnemyField).kill(v, &"doom")
	crowd._settle_doom()
	t.check(_jobs(crowd).size() == 1, "a seen Silent Doom kill: a sweep (%d)" % _jobs(crowd).size())
	C._done(made)
	var made2 := C._world()
	var crowd2: Crowd = made2[0]
	var v2: Person = crowd2.citizens[0]
	_put(v2, at)
	C._hide_others(crowd2, [v2])
	(made2[3] as EnemyField).kill(v2, &"doom")
	crowd2._settle_doom()
	t.check(_jobs(crowd2).is_empty(), "an unwitnessed one: none")
	C._done(made2)


## The 4th incident in a district (Local Emergency) posts a sweep there, whoever saw it.
static func _local_emergency(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	C._hide_others(crowd, [])
	for k in AlarmManager.LOCAL_EVENTS - 1:
		crowd.alarms.incident(at)
	t.check(_jobs(crowd).is_empty(), "(three incidents: no sweep)")
	var v: Person = crowd.citizens[0]
	_put(v, at)
	(made[3] as EnemyField).kill(v, &"mob")
	t.check(_jobs(crowd).size() == 1 and _jobs(crowd)[0].data.district == AlarmManager.district_of(at), "the 4th incident: a sweep in that district")
	C._done(made)


## A hushed town, a hushed place and a veiled place post none.
static func _hushed_veiled_none(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	_put(crowd.citizens[0], at + Vector2(1.0, 0.0))
	crowd.hush(30.0)
	_land(crowd, at)
	t.check(_jobs(crowd).is_empty(), "a hushed town: no sweep")
	C._done(made)
	var made2 := C._world()
	var crowd2: Crowd = made2[0]
	_put(crowd2.citizens[0], at + Vector2(1.0, 0.0))
	crowd2.hush_at(at, 6.0, 30.0)
	_land(crowd2, at)
	t.check(_jobs(crowd2).is_empty(), "a hushed place: no sweep")
	C._done(made2)
	var made3 := C._world()
	var crowd3: Crowd = made3[0]
	_put(crowd3.citizens[0], at + Vector2(1.0, 0.0))
	crowd3.veil(at, 6.0, 30.0)
	_land(crowd3, at)
	t.check(_jobs(crowd3).is_empty(), "a veiled place: no sweep")
	C._done(made3)


## A second seen power in a district with a sweep (open or begun) makes no second job.
static func _one_per_district(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	_put(crowd.citizens[0], at + Vector2(1.0, 0.0))
	_land(crowd, at)
	_land(crowd, at + Vector2(0.5, 0.0))
	crowd.sweep.request(at)
	t.check(_jobs(crowd).size() == 1, "an open sweep: still one (%d)" % _jobs(crowd).size())
	t.check(crowd.sweep.swept(AlarmManager.district_of(at)), "swept() says so")
	crowd.guard_jobs._fill()
	_land(crowd, at)
	t.check(_jobs(crowd).size() == 1, "a begun sweep: still one")
	C._done(made)


## Two sweeps at once in Aldermere, four in the Capital.
static func _cap_two(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var districts: Array = City.current().districts()
	for i in 3:
		crowd.sweep.request((districts[i] as Rect2).get_center())
	t.check(_jobs(crowd).size() == 2, "Aldermere: three districts, two sweeps (%d)" % _jobs(crowd).size())
	C._done(made)
	var b: Dictionary = CapPeople._build()
	var cap: Crowd = b.crowd
	var cds: Array = City.current().districts()
	for i in 5:
		cap.sweep.request((cds[i] as Rect2).get_center())
	t.check(cap.guard_jobs.cap(SweepDuty.SWEEPS) == 4 and _jobs(cap).size() == 4, "the Capital: four (%d)" % _jobs(cap).size())
	cap.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


## The four nearest free men of any group; three free men make no sweep; keep-one holds.
static func _crew_four(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var five := _guards(crowd, at, 5)
	C._only_free(crowd, five)
	crowd.sweep.request(at)
	crowd.guard_jobs._fill()
	var job: GuardJobs.Job = _jobs(crowd)[0]
	t.check(job.crew.size() == 4 and job.started and not job.crew.has(five[4]), "five free in one group: the four nearest go, the farthest stays")
	for i in 4:
		t.check(job.crew.has(five[i]), "(man %d is in the crew)" % i)
	C._done(made)
	var made2 := C._world()
	var crowd2: Crowd = made2[0]
	var four := _guards(crowd2, at, 4)
	C._only_free(crowd2, four)
	crowd2.sweep.request(at)
	crowd2.guard_jobs._fill()
	var job2: GuardJobs.Job = _jobs(crowd2)[0]
	t.check(job2.crew.is_empty() and not job2.started, "four free of one group: keep-one leaves three, no crew")
	crowd2.mission_holds.clear()
	var three := _guards(crowd2, at, 3)
	C._only_free(crowd2, three)
	crowd2.guard_jobs._fill()
	t.check(job2.crew.is_empty(), "three free: no sweep")
	C._done(made2)


## A director's soldier is never a crew man.
static func _mission_man_never(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var five := _guards(crowd, at, 5, 1.0)
	var m := crowd.add_soldier(at)
	var men: Array = five.duplicate()
	men.append(m)
	C._only_free(crowd, men)
	crowd.sweep.request(at)
	crowd.guard_jobs._fill()
	var job: GuardJobs.Job = _jobs(crowd)[0]
	t.check(job.crew.size() == 4 and not job.crew.has(m), "the director's man (nearest) is not taken")
	C._done(made)


## The 30 s count starts when the first crew man is inside the district rect.
static func _clock_starts_inside(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var d := _busy(made)
	var rect: Rect2 = City.current().districts()[d]
	var at := _spot(made, d)
	var far := rect.end + Vector2(25.0, 25.0)
	var five := _guards(crowd, far, 5, 0.5)
	C._only_free(crowd, five)
	crowd.sweep.request(at)
	crowd.guard_jobs._fill()
	var job: GuardJobs.Job = _jobs(crowd)[0]
	t.check(job.crew.size() == 4, "(a crew of four, all far from the district)")
	C._run_for(crowd, 1.0, [], 0.1)
	t.near(float(job.data.left), SweepDuty.SWEEP_SECONDS, 0.001, "nobody inside yet: the clock stands at 30")
	var lead: Person = job.crew[0]
	lead.ground_pos = at
	lead._goal = Vector2.INF
	lead._path = PackedVector2Array()
	C._run_for(crowd, 2.0, [], 0.1)
	t.near(float(job.data.left), SweepDuty.SWEEP_SECONDS - 2.0, 0.35, "one man inside: it counts down (%.2f)" % float(job.data.left))
	C._done(made)


## At most six doors, each walkable, the first nearest the seen point; the crew stands 3.0 s at each.
static func _doors_six(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var d := _busy(made)
	var at := _spot(made, d)
	var doors := crowd.sweep.doors(d, at)
	t.check(not doors.is_empty() and doors.size() <= SweepDuty.SWEEP_DOORS, "doors: 1 to 6 (%d)" % doors.size())
	var walk := true
	for p in doors:
		walk = walk and (made[4] as WalkGrid).walkable(p)
	t.check(walk, "each a walkable point")
	var rect: Rect2 = City.current().districts()[d]
	var nearest: Structure = null
	for s in (made[1] as EnvironmentField).structures():
		if s.kind == Structure.Kind.HOUSE and not s.destroyed and rect.has_point(s.center()):
			if nearest == null or s.center().distance_to(at) < nearest.center().distance_to(at):
				nearest = s
	t.check(nearest != null and doors[0].distance_to(nearest.center()) <= nearest.footprint.size.length() * 0.5 + 1.5, "the first door is the nearest house's")
	var again := crowd.sweep.doors(d, at)
	t.check(again == doors, "the same order every time")
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	t.check(job.data.doors.size() == doors.size() and job.data.doors[0] == doors[0], "the job walks those doors")
	_arrive(job)
	C._run_for(crowd, 1.0, [], 0.1)
	t.check(int(job.data.door) == 0 and job.crew[0].talk_left > 0.0, "standing at door 0, talking")
	C._run_for(crowd, SweepDuty.SWEEP_STAND, [], 0.1)
	t.check(int(job.data.door) == 1 or doors.size() == 1, "after 3.0 s on to the next door (%d)" % int(job.data.door))
	C._done(made)


## A death 3.5 from a sweep man is seen by him; 4.5 is not.
static func _watch_sight(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	for i in range(1, job.crew.size()):
		(job.crew[i] as Person).ground_pos = at + Vector2(60.0, 60.0)
	C._hide_others(crowd, job.crew)
	var lead: Person = job.crew[0]
	t.check(lead.watch_far, "(the crew is watch_far)")
	t.check(crowd.nearest_witness(lead.ground_pos + Vector2(3.5, 0.0)) == lead, "3.5 off: the sweep man is the witness")
	t.check(crowd.nearest_witness(lead.ground_pos + Vector2(4.5, 0.0)) == null, "4.5 off: nobody")
	crowd.sight_scale = 0.5
	t.check(crowd.nearest_witness(lead.ground_pos + Vector2(3.5, 0.0)) == null and crowd.nearest_witness(lead.ground_pos + Vector2(1.9, 0.0)) == lead, "at night his sight is 2.0")
	crowd.sight_scale = 1.0
	C._done(made)


## TempleReport's own witness search gives a sweep man 4.0 too.
static func _watch_sight_report(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	for i in range(1, job.crew.size()):
		(job.crew[i] as Person).ground_pos = at + Vector2(60.0, 60.0)
	C._hide_others(crowd, job.crew)
	var lead: Person = job.crew[0]
	var report := TempleReport.new(crowd.citizens[0], Vector2.ZERO)
	report.skip = func(_p: Person) -> bool: return false
	t.check(report._witness(crowd, lead.ground_pos + Vector2(3.5, 0.0)) == lead, "the report finds the sweep man at 3.5")
	t.check(report._witness(crowd, lead.ground_pos + Vector2(4.5, 0.0)) == null, "not at 4.5")
	C._done(made)


## Once the bell has rung, each seen power in the district under a sweep man's eyes adds 2.0 alarm, at most 6.0 a sweep.
static func _extra_alarm(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	crowd.alarms.bell_rung = true
	C._run_for(crowd, 0.5, [], 0.1)
	var texts := _texts(crowd)
	_put(crowd.citizens[0], at + Vector2(1.0, 0.0))
	var before := crowd.alarm
	_land(crowd, at)
	t.near(crowd.alarm - before, SweepDuty.SWEEP_ALARM, 0.001, "a seen power under the sweep: +2.0")
	_land(crowd, at)
	t.near(crowd.alarm - before, SweepDuty.SWEEP_ALARM, 0.001, "a second power in the same frame is the same charge")
	crowd.advance(STEP)
	_land(crowd, at)
	crowd.advance(STEP)
	_land(crowd, at)
	t.near(crowd.alarm - before, SweepDuty.SWEEP_ALARM_CAP, 0.001, "three of them: +6.0")
	crowd.advance(STEP)
	_land(crowd, at)
	t.near(crowd.alarm - before, SweepDuty.SWEEP_ALARM_CAP, 0.001, "a fourth: capped")
	t.check(texts.count(SweepDuty.BANNER_HEARS) == 3, "THE SWEEP HEARS IT three times (%d)" % texts.count(SweepDuty.BANNER_HEARS))
	var made2 := C._world()
	var crowd2: Crowd = made2[0]
	var job2 := _up(made2, at)
	if job2 != null:
		crowd2.alarms.bell_rung = true
		_put(crowd2.citizens[0], at + Vector2(1.0, 0.0))
		crowd2.hush(30.0)
		var b2 := crowd2.alarm
		crowd2.sweep.on_seen(at)
		t.near(crowd2.alarm, b2, 0.001, "a hushed town hears nothing: no extra alarm")
		crowd2._hush_until = -INF
		crowd2.veil(at, 5.0, 30.0)
		crowd2.sweep.on_seen(at)
		t.near(crowd2.alarm, b2, 0.001, "nor a veiled place")
	else:
		t.check(false, "(a second sweep with its crew)")
	C._done(made2)
	C._done(made)


## A sweep man is no posted watch.
static func _not_on_watch(t) -> void:
	var made := C._world()
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	for p: Person in job.crew:
		_put_still(p)
		t.check(not p.on_watch(), "a sweep man: on_watch() is false")
	C._done(made)


static func _put_still(p: Person) -> void:
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = p.ground_pos
	p.anchor = p.ground_pos


## 30 s after the first man is inside the sweep is over: crew back at their posts, no flag, no badge.
static func _ends_thirty(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var texts := _texts(crowd)
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	var crew: Array = job.crew.duplicate()
	_arrive(job)
	C._run_for(crowd, 2.0, [], 0.1)
	t.check(not _jobs(crowd).is_empty(), "(the sweep stands)")
	var badged := true
	for p: Person in crew:
		badged = badged and p.watch_far and p.badge_left > 0.0 and p.badge_glyph == GuardJobs.GLYPH_EYE
	t.check(badged, "the crew wears the eye badge and sees far")
	var tags := crowd.guard_jobs.tags()
	t.check(tags.size() == 1 and tags[0].label.begins_with("SWEEP "), "a tag over the lead: SWEEP n")
	C._run_for(crowd, SweepDuty.SWEEP_SECONDS, [], 0.1)
	t.check(_jobs(crowd).is_empty(), "after 30 s the sweep is over")
	var clean := true
	for p: Person in crew:
		clean = clean and not p.watch_far and p.badge_left <= 0.0 and p.talk_left <= 0.0 and p.anchor.is_equal_approx(p.post) and not crowd.guard_jobs.on_job(p)
	t.check(clean, "every man back at his post, flags and badge gone")
	t.check(texts.has(SweepDuty.BANNER), "SOLDIERS SWEEP THE DISTRICT was shown")
	C._done(made)


## Every crew man held by the god and out of the district: the sweep is broken.
static func _held_squad_breaks(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var d := _busy(made)
	var at := _spot(made, d)
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	var crew: Array = job.crew.duplicate()
	var texts := _texts(crowd)
	_arrive(job)
	C._run_for(crowd, 1.2, [], 0.1)
	t.check(not _jobs(crowd).is_empty(), "(the sweep stands, the clock runs)")
	for p: Person in crew:
		p.confuse(40.0)
		p.ground_pos = at + Vector2(80.0, 80.0)
	t.check(crew[0].held_by_god(), "(the god holds them)")
	C._run_for(crowd, 1.2, [], 0.1)
	t.check(_jobs(crowd).is_empty(), "held and out of the district: the sweep is over")
	t.check(texts.has(SweepDuty.BANNER_BROKEN), "THE SWEEP IS BROKEN was shown")
	C._done(made)
	var made2 := C._world()
	var crowd2: Crowd = made2[0]
	var job2 := _up(made2, at)
	if job2 == null:
		t.check(false, "(a second sweep with its crew)")
		C._done(made2)
		return
	_arrive(job2)
	C._run_for(crowd2, 1.2, [], 0.1)
	var held: Person = job2.crew[0]
	held.confuse(40.0)
	t.check(not crowd2.sweep.counts_inside(job2, held), "a held man inside the rect does not count as inside")
	C._run_for(crowd2, 1.2, [], 0.1)
	t.check(not _jobs(crowd2).is_empty(), "(the other men keep the sweep)")
	C._done(made2)


## The stage reaching EVACUATION ends a sweep.
static func _evacuation_ends(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	var crew: Array = job.crew.duplicate()
	_arrive(job)
	C._run_for(crowd, 1.2, [], 0.1)
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	C._run_for(crowd, 1.2, [], 0.1)
	t.check(_jobs(crowd).is_empty(), "EVACUATION: the sweep is over")
	var home := true
	for p: Person in crew:
		home = home and not p.watch_far and not crowd.guard_jobs.on_job(p)
	t.check(home, "and the men are let go")
	crowd.sweep.request(at)
	t.check(_jobs(crowd).is_empty(), "none is posted at EVACUATION")
	C._done(made)


## An open (unstaffed) sweep ends by itself and blocks nothing after.
static func _open_job_ends(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var d := _busy(made)
	var at := _spot(made, d)
	C._only_free(crowd, [])
	crowd.sweep.request(at)
	t.check(_jobs(crowd).size() == 1 and not _jobs(crowd)[0].started, "(an open sweep, no free man)")
	C._run_for(crowd, SweepDuty.OPEN_SECONDS + 2.0, [], 0.5)
	t.check(_jobs(crowd).is_empty() and not crowd.sweep.swept(d), "it ends after its wait and the district is free to ask again")
	crowd.sweep.request(at)
	t.check(_jobs(crowd).size() == 1, "a new request posts again")
	C._done(made)


## A crew man freed mid-sweep does not crash the tick; the sweep goes on short-handed.
static func _freed_man(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	_arrive(job)
	C._run_for(crowd, 1.2, [], 0.1)
	var gone: Person = job.crew[1]
	crowd.soldiers.erase(gone)
	gone.free()
	C._run_for(crowd, 1.2, [], 0.1)
	t.check(not _jobs(crowd).is_empty() and job.crew.size() == 3, "a freed man: the sweep runs on with three")
	C._done(made)


## clear() drops every job, flag and badge.
static func _clear_resets(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	var crew: Array = job.crew.duplicate()
	_arrive(job)
	C._run_for(crowd, 1.2, [], 0.1)
	crowd.guard_jobs.clear()
	var clean := _jobs(crowd).is_empty()
	for p: Person in crew:
		clean = clean and not p.watch_far and p.badge_left <= 0.0 and p.talk_left <= 0.0
	t.check(clean, "clear(): no sweep, no watch_far, no badge, no talk")
	C._done(made)


## A Capital district: doors found, a crew assigned.
static func _capital_sweep(t) -> void:
	var b: Dictionary = CapPeople._build()
	var cap: Crowd = b.crowd
	var d := 0
	var cds: Array = City.current().districts()
	var best_n := -1
	for i in cds.size():
		var n := 0
		for s in (b.env as EnvironmentField).structures():
			if s.kind == Structure.Kind.HOUSE and not s.destroyed and (cds[i] as Rect2).has_point(s.center()):
				n += 1
		if n > best_n:
			best_n = n
			d = i
	var at: Vector2 = (b.grid as WalkGrid).nearest_walkable((cds[d] as Rect2).get_center())
	var five := _guards(cap, at, 5, 0.5)
	C._only_free(cap, five)
	cap.sweep.request(at)
	cap.guard_jobs._fill()
	var jobs := cap.guard_jobs.live(SWEEP)
	t.check(jobs.size() == 1 and jobs[0].crew.size() == SweepDuty.CREW, "the Capital: a sweep with its crew of four")
	t.check(not cap.sweep.doors(d, at).is_empty(), "and doors in that district")
	cap.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


## A Silent Doom that fells three seen men in a swept district is one power: +2.0 once and one banner (and their own 0.5 each).
static func _one_power_one_charge(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	_arrive(job)
	crowd.alarms.bell_rung = true
	var texts := _texts(crowd)
	C._run_for(crowd, 0.5, [], 0.1)
	var witness: Person = crowd.citizens[0]
	_put(witness, at + Vector2(0.0, 1.0))
	var field: EnemyField = made[3]
	for i in 3:
		var v: Person = crowd.citizens[1 + i]
		_put(v, at + Vector2(0.3 * i, 0.0))
		field.kill(v, &"doom")
	var before := crowd.alarm
	crowd._settle_doom()
	t.near(crowd.alarm - before, SweepDuty.SWEEP_ALARM + 3.0 * Crowd.ALARM_KILL, 0.001, "three seen victims: 2.0 once, and 0.5 each (%.2f)" % (crowd.alarm - before))
	t.check(texts.count(SweepDuty.BANNER_HEARS) == 1, "one banner")
	C._done(made)


## A begun sweep whose men are held outside the district never starts its clock: it ends at 45 s, flags cleared, no BROKEN banner.
static func _never_arrives_ends(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var d := _busy(made)
	var rect: Rect2 = City.current().districts()[d]
	var at := _spot(made, d)
	var five := _guards(crowd, rect.end + Vector2(25.0, 25.0), 5, 0.5)
	C._only_free(crowd, five)
	var texts := _texts(crowd)
	crowd.sweep.request(at)
	crowd.guard_jobs._fill()
	var live := _jobs(crowd)
	if live.is_empty() or live[0].crew.size() != SweepDuty.CREW:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	var crew: Array = live[0].crew.duplicate()
	for p: Person in crew:
		p.confuse(200.0)
	C._run_for(crowd, SweepDuty.LEG_LIMIT + SweepDuty.SWEEP_SECONDS - 3.0, [], 0.5)
	t.check(not _jobs(crowd).is_empty(), "(still waiting at 42 s)")
	C._run_for(crowd, 6.0, [], 0.5)
	t.check(_jobs(crowd).is_empty(), "never inside: over after 45 s")
	var clean := true
	for p: Person in crew:
		clean = clean and not p.watch_far and p.badge_left <= 0.0 and p.talk_left <= 0.0 and not crowd.guard_jobs.on_job(p)
	t.check(clean, "flags and badges cleared")
	t.check(not texts.has(SweepDuty.BANNER_BROKEN), "and no BROKEN banner")
	C._done(made)


## A lane power (points in two districts) witnessed only at its far end is swept in the far district.
static func _lane_swept_where_seen(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var districts: Array = City.current().districts()
	var a := _spot(made, 0)
	var b := _spot(made, districts.size() - 1)
	t.check(AlarmManager.district_of(a) != AlarmManager.district_of(b), "(two districts)")
	C._hide_others(crowd, [])
	_put(crowd.citizens[0], b + Vector2(1.0, 0.0))
	var pts: Array[Vector2] = [a, b]
	crowd.danger_landed.emit("lane", pts, 1.0)
	var jobs := _jobs(crowd)
	t.check(jobs.size() == 1 and jobs[0].data.district == AlarmManager.district_of(b) and jobs[0].data.seen_at == b,
		"swept in the district it was witnessed in, at that point")
	var out: Array[Vector2] = []
	t.check(crowd.power_witness(pts, 1.0, out) == crowd.citizens[0] and out == [b], "power_witness gives the point")
	C._done(made)


## A director's own witness search gives a sweep man 3.5; anyone else keeps the day's 2.0.
static func _director_copy_reach(t) -> void:
	var s: Dictionary = Warning._setup()
	var crowd: Crowd = s.crowd
	var d: WarningDirector = s.d
	for p in crowd.citizens + crowd.soldiers:
		p.inside = true
	var man: Person = crowd.soldiers[0]
	man.inside = false
	var at := Vector2(0.0, 0.0)
	man.ground_pos = at + Vector2(3.5, 0.0)
	t.check(d._relay_witness(at) == null, "an ordinary man 3.5 off carries nothing")
	man.watch_far = true
	t.check(d._relay_witness(at) == man, "a sweep man 3.5 off is the witness")
	man.ground_pos = at + Vector2(4.5, 0.0)
	t.check(d._relay_witness(at) == null, "not at 4.5")
	crowd.sight_scale = 0.5
	man.watch_far = false
	man.ground_pos = at + Vector2(1.5, 0.0)
	t.check(d._relay_witness(at) == man, "an ordinary man keeps the day's 2.0 even at night")
	crowd.sight_scale = 1.0
	Warning._done(s)


## A sweep man is not frightened by a danger landing beside him, from assignment to the end; after it he is again.
static func _sweep_men_keep_nerve(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	var crew: Array = job.crew.duplicate()
	_arrive(job)
	C._run_for(crowd, 3.0, [], 0.1)
	for p: Person in crew:
		p.panic(p.ground_pos + Vector2(0.5, 0.0), 1.0)
	var calm := true
	for p: Person in crew:
		calm = calm and p.mind != Person.Mind.PANIC and p.mind != Person.Mind.FLEE
	t.check(calm and crew[0].fearless_left > 0.0, "a danger beside them: nobody panics")
	crowd.guard_jobs.end_job(job)
	t.check(crew[0].fearless_left <= 0.0, "after the sweep his nerve is his own again")
	C._done(made)


## A sweep whose door lies in a live danger (an airless cell, a fire) does not walk into it: its men stand off outside until the danger
## is over, then go to the door (R19: the men stand off until it is safe).
static func _stands_off_danger(t) -> void:
	var made := C._world()
	var crowd: Crowd = made[0]
	var at := _spot(made, _busy(made))
	var job := _up(made, at)
	if job == null:
		t.check(false, "(a sweep with its crew)")
		C._done(made)
		return
	var door: Vector2 = job.data.doors[0]
	crowd.threats.register(door, 2.0, 0.6, 6.0, 6.0, 6.0, &"breath")
	C._run_for(crowd, 1.0, [], 0.1)
	t.check(bool(job.data.held) and not job.crew.is_empty(), "the door in a live danger: the sweep holds")
	for p: Person in job.crew:
		t.check(crowd.threats.first_near(job.data.at_spot[p], 0.0).is_empty(), "no spot a man is sent to lies in it")
	C._run_for(crowd, 6.0, [], 0.1)
	var back := true
	for p: Person in job.crew:
		back = back and (job.data.at_spot[p] as Vector2).distance_to(door) <= 2.0 * SweepDuty.SPOT_APART + 0.5
	t.check(back and not bool(job.data.held), "the danger over, the men are sent to the door")
	C._done(made)
