extends RefCounted
## Soldier duties, slice b: bodies in every mission and corpse duty. The ledger of bodies is always on; a beat pair that sees a
## whole body within CORPSE_NOTICE inspects it 4 s, reports it (the district's incident, the missing alarm), lifts it and
## carries it off the street. A held, dead, pulled or fighting man ends the job; a body being carried is put back where it was
## dropped.

const Corps := preload("res://tests/test_corps.gd")
const CapPeople := preload("res://tests/test_capital_people.gd")
const PaleT := preload("res://tests/test_pale.gd")
const RD := preload("res://tests/test_raise_dead.gd")
const DM := preload("res://tests/test_death_twist_deathmark.gd")
const STEP := 1.0 / 60.0
const CORPSE := GuardJobs.Kind.CORPSE


static func run(t) -> void:
	_bodies_every_loadout(t)
	_pale_keeps_ledger(t)
	_notice(t)
	_veiled_unnoticed(t)
	_no_sight(t)
	_crew_pair_only(t)
	_keep_one(t)
	_mission_man_never(t)
	_inspect_four(t)
	_found_tag(t)
	_incident_and_alarm(t)
	_counted_no_alarm(t)
	_lift_takes(t)
	_held_inspector_drops(t)
	_held_carrier_drops_body(t)
	_pulled_by_guard(t)
	_lapse_ends(t)
	_capital_corpse(t)
	_reported_once(t)
	_silent_find(t)
	_open_job_lets_go(t)
	_taken_before_lift(t)
	_countdown_walk(t)
	_corps_pair_none(t)
	_near_tie(t)


## A town with the ledger on as Rules would leave it.
static func _world() -> Array:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	crowd.remains.always = true
	return made


static func _done(made: Array) -> void:
	Corps._done(made)
	City.use(&"aldermere")


## Every soldier thinks and moves one step, then the crowd's own tick.
static func _step(crowd: Crowd) -> void:
	for p in crowd.soldiers:
		if is_instance_valid(p) and not p.inside:
			p.tick(STEP)
	crowd.advance(STEP)


static func _run_for(crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		_step(crowd)


## The two men of the `n`th street beat whose men are both ordinary guards (no corps), each set down standing at his own post
## with no goal.
static func _pair(crowd: Crowd, n := 0) -> Array[Person]:
	var by := {}
	for e in crowd._beats:
		if is_instance_valid(e[0]):
			var men: Array = by.get(e[3], [])
			men.append(e[0])
			by[e[3]] = men
	var out: Array[Person] = []
	var seen := 0
	for k in by:
		var men: Array = by[k]
		if men.size() == 2 and men.all(func(p: Person) -> bool: return p.corps == Person.Corps.NONE):
			if seen == n:
				out.assign(men)
				break
			seen += 1
	for p in out:
		p.ground_pos = p.post
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos
	return out


## The point `d` off the pair's first man, away from the second (so he is the nearer, and the second is farther still).
static func _far(pair: Array[Person], d: float) -> Vector2:
	var dir := pair[0].ground_pos - pair[1].ground_pos
	dir = dir.normalized() if dir.length() > 0.01 else Vector2.LEFT
	return pair[0].ground_pos + dir * d


## The next living citizen, set down at `at` and killed as `kind`; his remain (null when none was written).
static func _kill(made: Array, at: Vector2, kind: StringName = &"mob") -> Remains.Remain:
	var crowd: Crowd = made[0]
	for c in crowd.citizens:
		if is_instance_valid(c) and c.is_alive():
			c.ground_pos = at
			c.inside = false
			(made[3] as EnemyField).kill(c, kind)
			return crowd.remains.of_body(c)
	return null


static func _live(crowd: Crowd) -> Array[GuardJobs.Job]:
	return crowd.guard_jobs.live(CORPSE)


## Steps until a corpse job has both men (at most `most` seconds); it, or null.
static func _until_job(crowd: Crowd, most := 3.0) -> GuardJobs.Job:
	for i in roundi(most / STEP):
		_step(crowd)
		for j in _live(crowd):
			if j.crew.size() == 2:
				return j
	return null


## Both men of `job` set down at the spots he is walking to, no goal left.
static func _arrive(job: GuardJobs.Job, spots: Array = []) -> void:
	for i in job.crew.size():
		var p: Person = job.crew[i]
		p.ground_pos = spots[i] if i < spots.size() else p.anchor
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos


## The inspector at his spot, the watcher at his.
static func _arrive_now(job: GuardJobs.Job) -> void:
	for p in job.crew:
		p.ground_pos = job.data.spot if p == job.data.inspector else p.anchor
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos


static func _labels(crowd: Crowd) -> Array[String]:
	var out: Array[String] = []
	for tag in crowd.guard_jobs.tags():
		out.append(tag.label)
	return out


static func _banners(crowd: Crowd) -> Array[String]:
	var out: Array[String] = []
	crowd.duty_event.connect(func(_k: int, text: String, _at: Vector2) -> void: out.append(text))
	return out


## A pair with a mob kill `d` off, one tick on: the corpse jobs there are.
static func _noticed(d: float) -> int:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	_kill(made, _far(pair, d))
	_run_for(crowd, 1.2)
	var n := _live(crowd).size()
	_done(made)
	return n


static func _bodies_every_loadout(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	t.check(not crowd.remains.enabled and not crowd.remains.always, "(the ledger is off before Rules)")
	var rules := Rules.new().setup(PackedStringArray(["smite"]), null, made[1], made[3], crowd, made[5])
	t.check(crowd.remains.enabled and crowd.remains.always, "a Ruin-style loadout: the ledger is on and always on")
	t.check(not Remains.wants(["smite"]), "Remains.wants() still names only the powers that need bodies")
	rules.free()
	_done(made)


## An always-on ledger is never put back off, by Pale Reign's end or by a Death Mark Wake's.
static func _pale_keeps_ledger(t) -> void:
	var made := RD._setup()
	PaleT._reset(made)
	var crowd: Crowd = made[0]
	crowd.remains.enabled = false
	var fx := PaleT._cast(made, RD._empty(made))
	t.check(crowd.remains.enabled, "(the reign lit the ledger)")
	crowd.remains.always = true
	fx.end_now()
	t.check(crowd.remains.enabled, "Pale Reign's put-back leaves an always-on ledger on")
	RD._done(made)
	var dm := DM._setup()
	DM._clear_town(dm[0])
	var c := DM._cast(dm, 5, 2, DM._spot(dm))
	t.check(dm[0].remains.enabled, "(the Wake lit the ledger)")
	dm[0].remains.always = true
	(c[0] as DeathMarkFx).end_now()
	t.check(dm[0].remains.enabled, "a Death Mark Wake's put-back leaves it on too")
	(c[0] as Node).free()
	DM._done(dm)


## A body 3.5 off a standing beat pair is noticed after one tick; one 4.5 off is not.
static func _notice(t) -> void:
	t.check(_noticed(3.5) == 1, "a mob kill 3.5 from a beat pair: one corpse job")
	t.check(_noticed(4.5) == 0, "one 4.5 away: none")


## Under Unseen Hour's veil nothing is noticed.
static func _veiled_unnoticed(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var at := _far(pair, 3.0)
	crowd.veil(at, 3.0, 30.0)
	_kill(made, at)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty(), "a body under a veil: no job")
	_done(made)


## Decree's NO SIGHT cuts the notice to 2.0.
static func _no_sight(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var at := _far(pair, 3.0)
	crowd.add_law(LawZone.circle(pair[0].ground_pos, 8.0, [LawZone.NO_SIGHT], 60.0))
	_kill(made, at)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty(), "under NO SIGHT a body 3.0 off goes unnoticed (reach 2.0)")
	_done(made)
	var made2 := _world()
	var crowd2: Crowd = made2[0]
	var pair2 := _pair(crowd2)
	crowd2.add_law(LawZone.circle(pair2[0].ground_pos, 8.0, [LawZone.NO_SIGHT], 60.0))
	_kill(made2, _far(pair2, 1.5))
	_run_for(crowd2, 1.2)
	t.check(_live(crowd2).size() == 1, "and one 1.5 off is still seen")
	_done(made2)


## Only that pair is on the body; a second body near the same pair gets no second job; a second pair next to the same body
## makes no second job for it.
static func _crew_pair_only(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var other := _pair(crowd, 1)
	for i in other.size():
		other[i].ground_pos = pair[0].ground_pos + Vector2(0.4 + 0.2 * float(i), 0.3)
	_kill(made, _far(pair, 3.5))
	_run_for(crowd, 1.2)
	var jobs := _live(crowd)
	t.check(jobs.size() == 1 and jobs[0].crew.size() == 2, "one body, two pairs in sight: one job with two men")
	if jobs.size() == 1:
		var who: Array = jobs[0].data.pair
		var on := 0
		for p in crowd.soldiers:
			on += 1 if crowd.guard_jobs.on_job(p) else 0
		t.check(on == 2 and who.size() == 2 and jobs[0].crew.all(func(p: Person) -> bool: return who.has(p)),
			"only the pair named by the job is on it (%d men on jobs)" % on)
	_kill(made, _far(pair, 2.5))
	_run_for(crowd, 1.2)
	var named := 0
	for j in _live(crowd):
		named += 1 if j.data.pair.has(pair[0]) or j.data.pair.has(pair[1]) else 0
	t.check(named == 1, "a second body near the same pair: that pair has no second job (%d)" % named)
	_done(made)


## A job never leaves a post group under GROUP_KEEP free men: with the pair the group's only free men there is no crew; with a
## third free man there is.
static func _keep_one(t) -> void:
	for extra in [false, true]:
		var made := _world()
		var crowd: Crowd = made[0]
		var pair := _pair(crowd)
		var third: Person = null
		if extra:
			third = _pair(crowd, 1)[0]
		crowd.mission_holds.append(func(p: Person) -> bool:
			return p.soldier and p != pair[0] and p != pair[1] and p != third)
		_kill(made, _far(pair, 3.5))
		_run_for(crowd, 1.2)
		var jobs := _live(crowd)
		var crew := jobs[0].crew.size() if not jobs.is_empty() else -1
		if extra:
			t.check(crew == 2, "three free men in the group: the pair goes, one stays (%d)" % crew)
		else:
			t.check(crew == 0, "the pair the group's only free men: the job waits open, nobody goes (%d)" % crew)
		_done(made)


## A man a mission names is never part of a pair.
static func _mission_man_never(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	crowd.mission_holds.append(func(p: Person) -> bool: return p == pair[1])
	_kill(made, _far(pair, 3.5))
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty() and not crowd.guard_jobs.on_job(pair[0]), "one of the pair held by a hook: no job")
	_done(made)


## Arrived at the body, found after exactly 4.0 s (240 frames at 60 fps, not 239); the banner says so.
static func _inspect_four(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var rem := _kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	t.check(job != null and job.data.phase == CorpseDuty.WALK, "the pair is sent: phase WALK")
	if job == null:
		_done(made)
		return
	var insp: Person = job.data.inspector
	var watch: Person = job.data.watcher
	t.check(insp.ground_pos.distance_to(rem.pos) <= watch.ground_pos.distance_to(rem.pos) + 0.01
		and job.data.spot.distance_to(rem.pos) <= 1.0, "the nearer man inspects, at the body")
	var out: Vector2 = (rem.pos - insp.ground_pos).normalized()
	t.check(watch.anchor.distance_to(rem.pos) <= CorpseDuty.WATCH_OFF + 0.6 and watch.stand_face != Vector2.INF
		and (out == Vector2.ZERO or watch.stand_face.dot(out) > 0.0), "the other stands off the body, facing out")
	_arrive_now(job)
	t.check(banners.is_empty(), "(nothing found yet)")
	var frames := 0
	while banners.is_empty() and frames < 400:
		_step(crowd)
		frames += 1
		if frames == 10:
			t.check(insp.crouching, "the inspector crouches while he looks")
	t.check(frames == 240, "found exactly after 4.0 s: 240 frames (%d)" % frames)
	t.check(banners == [CorpseDuty.BANNER] and CorpseDuty.BANNER == "A BODY IS FOUND", "the banner is A BODY IS FOUND")
	t.check(not insp.crouching, "and he stands up")
	_done(made)


## The tag counts down: FOUND IN n never rises, and it is 0 once found.
static func _found_tag(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	_kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job to read the tag of")
		_done(made)
		return
	var first := _labels(crowd)
	t.check(first.size() == 1 and first[0].begins_with("FOUND IN "), "the tag from assignment: FOUND IN n (%s)" % str(first))
	_arrive_now(job)
	var seen: Array[int] = []
	var frames := 0
	while banners.is_empty() and frames < 400:
		if frames % 60 == 0:
			var ls := _labels(crowd)
			seen.append(int(ls[0].trim_prefix("FOUND IN ")) if not ls.is_empty() else -1)
		_step(crowd)
		frames += 1
	var steady := seen.size() >= 3
	for i in range(1, seen.size()):
		steady = steady and seen[i] >= 0 and seen[i] <= seen[i - 1]
	t.check(steady and seen[0] > seen[seen.size() - 1], "FOUND IN n never rises and counts down: %s" % str(seen))
	t.check(crowd.corpses.found_in(job) == 0, "and is 0 at found")
	_done(made)


## A kill the town did not hear (hushed): the find counts as one more incident and gives half the unwarned alarm.
static func _incident_and_alarm(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	crowd.hush(0.3)
	var rem := _kill(made, _far(pair, 3.5))
	t.check(rem != null and not rem.counted, "(a hushed kill is not counted)")
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	var d := AlarmManager.district_of(rem.pos)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	_arrive_now(job)
	var events := int(crowd.alarms._events.get(d, 0))
	var alarm := crowd.alarm
	var frames := 0
	while banners.is_empty() and frames < 400:
		alarm = crowd.alarm
		events = int(crowd.alarms._events.get(d, 0))
		_step(crowd)
		frames += 1
	t.check(not banners.is_empty(), "(found)")
	t.check(int(crowd.alarms._events.get(d, 0)) == events + 1, "the find is one more incident in its district")
	t.near(crowd.alarm - alarm, Crowd.ALARM_KILL * Crowd.UNWARNED_ALARM, 0.0001, "and adds the kill's alarm it never gave")
	_done(made)


## A kill the town saw (counted): the find is one more incident and adds no alarm.
static func _counted_no_alarm(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var rem := _kill(made, _far(pair, 3.5))
	t.check(rem != null and rem.counted, "(a seen mob kill is counted)")
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	var d := AlarmManager.district_of(rem.pos)
	_arrive_now(job)
	var events := 0
	var alarm := 0.0
	var frames := 0
	while banners.is_empty() and frames < 400:
		alarm = crowd.alarm
		events = int(crowd.alarms._events.get(d, 0))
		_step(crowd)
		frames += 1
	t.check(int(crowd.alarms._events.get(d, 0)) == events + 1, "the find is one more incident")
	t.near(crowd.alarm, alarm, 0.0001, "and the alarm is unchanged by it")
	_done(made)


## After the find the body is off the ledger, TAKEN shows 2.0 s, and it is laid off every road within 4.0, then they go home.
static func _lift_takes(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var rem := _kill(made, _far(pair, 3.5))
	var at := rem.pos
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	_arrive_now(job)
	while banners.is_empty():
		_step(crowd)
	t.check(crowd.remains.pick(at) == null, "lifted: the body is no longer on the ledger")
	t.check(_labels(crowd) == ["TAKEN"], "the tag says TAKEN (%s)" % str(_labels(crowd)))
	var to: Vector2 = job.data.to
	var off_road := true
	for road: Rect2 in City.current().roads():
		off_road = off_road and not road.has_point(to)
	t.check(job.data.phase == CorpseDuty.CARRY and job.data.carrying, "phase CARRY, carrying")
	t.check(off_road and to.distance_to(at) <= CorpseDuty.CARRY_REACH and to != at, "laid off every road within 4.0 of where it lay")
	_run_for(crowd, 1.7)
	t.check(_labels(crowd).has("TAKEN"), "TAKEN still shows at 1.7 s")
	_run_for(crowd, 0.5)
	t.check(not _labels(crowd).has("TAKEN"), "TAKEN goes after 2.0 s")
	_arrive(job, job.data.carry_spots)
	_run_for(crowd, 0.2)
	t.check(job.data.phase == CorpseDuty.LAY, "at the spot the body is laid down")
	t.check(not job.data.carrying, "from the start of the lay-down the men are free to be pulled")
	_run_for(crowd, DummyEnemy.DEATH_FADE + 0.1)
	t.check(not crowd.guard_jobs.on_job(pair[0]) and not crowd.guard_jobs.on_job(pair[1]) and _live(crowd).is_empty(),
		"then both go back to their posts and the job is over")
	t.check(crowd.remains.pick(at) == null and crowd.remains.pick(to) == null, "and the body is not on the ledger again")
	_done(made)


## The inspector held by the god's hand at 2 s: the job ends, nothing is found, the body stays on the ledger, no tag.
static func _held_inspector_drops(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var rem := _kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	var insp: Person = job.data.inspector
	var events := int(crowd.alarms._events.get(AlarmManager.district_of(rem.pos), 0))
	_arrive_now(job)
	_run_for(crowd, 2.0)
	insp.confuse(5.0)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty() and banners.is_empty(), "held at 2 s: the job is over and nothing was found")
	t.check(crowd.remains.pick(rem.pos) == rem and _labels(crowd).is_empty(), "the body is still on the ledger and no tag shows")
	t.check(int(crowd.alarms._events.get(AlarmManager.district_of(rem.pos), 0)) == events, "no incident was added")
	t.check(not insp.crouching and not crowd.guard_jobs.on_job(job.data.watcher), "nobody crouches and the partner is free")
	_done(made)


## A carrier confused mid-carry: the body goes back on the ledger at the midpoint with a fresh clock, and the job ends.
static func _held_carrier_drops_body(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var rem := _kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	_arrive_now(job)
	while banners.is_empty():
		_step(crowd)
	var carrier: Person = job.crew[0]
	var other: Person = job.crew[1]
	var mid := (carrier.ground_pos + other.ground_pos) * 0.5
	carrier.confuse(5.0)
	_step(crowd)
	t.check(crowd.remains.pick(rem.pos, false, false, 1.5) == rem and crowd.remains.age(rem) < 0.05, "the body is back on the ledger, age 0")
	t.check(rem.pos.distance_to(mid) < 1.0 and not rem.hidden, "where the carriers were")
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty() and not crowd.guard_jobs.on_job(other), "and the job is over")
	_done(made)


## The guard pulls an inspecting man (the job ends for both) but never a carrier.
static func _pulled_by_guard(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	_kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	var a: Person = job.crew[0]
	var b: Person = job.crew[1]
	_arrive_now(job)
	_run_for(crowd, 1.0)
	t.check(crowd.guard_jobs.pullable(a) and crowd.guard_jobs.pullable(b), "an inspecting man can be pulled")
	crowd.guard_jobs.pull(a)
	_run_for(crowd, 1.2)
	t.check(not crowd.guard_jobs.on_job(a) and not crowd.guard_jobs.on_job(b) and _live(crowd).is_empty() and banners.is_empty(),
		"pulled: the job ends for both, nothing found")
	_done(made)
	var made2 := _world()
	var crowd2: Crowd = made2[0]
	var pair2 := _pair(crowd2)
	_kill(made2, _far(pair2, 3.5))
	var banners2 := _banners(crowd2)
	var job2 := _until_job(crowd2)
	if job2 == null:
		t.check(false, "a second job")
		_done(made2)
		return
	_arrive_now(job2)
	while banners2.is_empty():
		_step(crowd2)
	t.check(not crowd2.guard_jobs.pullable(job2.crew[0]) and not crowd2.guard_jobs.pullable(job2.crew[1]), "a carrier is never pullable")
	_done(made2)


## The body lapses (45 s) before it is found: the job ends and nothing is found.
static func _lapse_ends(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	_kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	_arrive_now(job)
	_run_for(crowd, 1.0)
	crowd.remains.step(Remains.LIFE + 1.0)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty() and banners.is_empty() and not crowd.guard_jobs.on_job(job.crew[0] if not job.crew.is_empty() else pair[0]),
		"the body lapsed before it was found: the job is over")
	_done(made)


## The Capital's beat pairs notice, report and carry a body too.
static func _capital_corpse(t) -> void:
	var b: Dictionary = CapPeople._build()
	var crowd: Crowd = b.crowd
	crowd.remains.enabled = true
	crowd.remains.always = true
	var pair := _pair(crowd)
	var banners := _banners(crowd)
	var made := [crowd, b.env, b.world, b.field]
	var rem := _kill(made, _far(pair, 3.5))
	var job := _until_job(crowd)
	t.check(rem != null and job != null, "Capital: a body 3.5 from a beat pair is noticed")
	if job != null:
		_arrive_now(job)
		var frames := 0
		while banners.is_empty() and frames < 400:
			_step(crowd)
			frames += 1
		t.check(banners == [CorpseDuty.BANNER] and crowd.remains.pick(rem.pos) == null, "found and lifted in the Capital")
	crowd.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")


## Steps until `rem` is off the ledger (lifted), at most `frames`; whether it was.
static func _until_lifted(crowd: Crowd, rem: Remains.Remain, frames := 600) -> bool:
	for i in frames:
		if not crowd.remains.holds(rem):
			return true
		_step(crowd)
	return not crowd.remains.holds(rem)


## A body dropped back and found again adds no second incident and no second alarm, and is still lifted.
static func _reported_once(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var rem := _kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	var d := AlarmManager.district_of(rem.pos)
	_arrive_now(job)
	while banners.is_empty():
		_step(crowd)
	t.check(rem.reported and rem.counted, "the first find marks the body reported and counted")
	var events := int(crowd.alarms._events.get(d, 0))
	var alarm := crowd.alarm
	job.crew[0].confuse(1.0)
	_step(crowd)
	t.check(crowd.remains.holds(rem), "(dropped back on the ledger)")
	_run_for(crowd, 3.0)
	var again := _until_job(crowd, 8.0)
	t.check(again != null, "the pair comes back to the body")
	if again != null:
		_arrive_now(again)
		t.check(_until_lifted(crowd, rem), "it is lifted again")
	t.check(int(crowd.alarms._events.get(d, 0)) == events and is_equal_approx(crowd.alarm, alarm) and banners.size() == 1,
		"found again: no second incident, no second alarm, no second banner")
	_done(made)


## A find while the town is hushed, or on veiled ground, reports nothing; the body is still lifted.
static func _silent_find(t) -> void:
	for mode in ["hush", "veil"]:
		var made := _world()
		var crowd: Crowd = made[0]
		var pair := _pair(crowd)
		var rem := _kill(made, _far(pair, 3.5))
		var banners := _banners(crowd)
		var job := _until_job(crowd)
		if job == null:
			t.check(false, "a job (%s)" % mode)
			_done(made)
			continue
		var d := AlarmManager.district_of(rem.pos)
		var events := int(crowd.alarms._events.get(d, 0))
		var alarm := crowd.alarm
		_arrive_now(job)
		if mode == "hush":
			crowd.hush(60.0)
		else:
			crowd.veil(rem.pos, 3.0, 60.0)
		t.check(_until_lifted(crowd, rem), "(%s) the body is still lifted" % mode)
		t.check(banners.is_empty() and int(crowd.alarms._events.get(d, 0)) == events and is_equal_approx(crowd.alarm, alarm)
			and not rem.reported, "(%s) nothing is reported: no banner, incident or alarm" % mode)
		_done(made)


## An open job whose man is taken elsewhere ends, and the body is free for the next pair.
static func _open_job_lets_go(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	crowd.mission_holds.append(func(p: Person) -> bool: return p.soldier and p != pair[0] and p != pair[1])
	_kill(made, _far(pair, 3.5))
	_run_for(crowd, 1.2)
	t.check(_live(crowd).size() == 1 and _live(crowd)[0].crew.is_empty(), "(the job waits open: the pair is the group's only free men)")
	var gone := pair[1]
	crowd.mission_holds.append(func(p: Person) -> bool: return p == gone)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty(), "a man of the pair taken elsewhere: the open job ends")
	_done(made)


## A Death power taking the body between assignment and the lift: the job ends, the tag goes.
static func _taken_before_lift(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	var rem := _kill(made, _far(pair, 3.5))
	var banners := _banners(crowd)
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	crowd.remains.take(rem)
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty() and _labels(crowd).is_empty() and banners.is_empty(), "the body used elsewhere: no job, no tag, no find")
	_done(made)


## FOUND IN n never rises while the pair really walks to the body.
static func _countdown_walk(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	_kill(made, _far(pair, 3.5))
	var job := _until_job(crowd)
	if job == null:
		t.check(false, "a job")
		_done(made)
		return
	var seen: Array[int] = []
	for i in 600:
		if i % 15 == 0:
			for l in _labels(crowd):
				if l.begins_with("FOUND IN "):
					seen.append(int(l.trim_prefix("FOUND IN ")))
		_step(crowd)
	var steady := seen.size() >= 4
	for i in range(1, seen.size()):
		steady = steady and seen[i] <= seen[i - 1]
	t.check(steady, "walking there, FOUND IN n never rises: %s" % str(seen))
	_done(made)


## A beat with a corps man in it posts no job.
static func _corps_pair_none(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var pair := _pair(crowd)
	pair[1].corps = Person.Corps.ESCORT
	_kill(made, _far(pair, 3.5))
	_run_for(crowd, 1.2)
	t.check(_live(crowd).is_empty(), "a beat with a corps man in it: no corpse job")
	_done(made)


## Two bodies as near: the older is first.
static func _near_tie(t) -> void:
	var made := _world()
	var crowd: Crowd = made[0]
	var at := Vector2(-20.0, -20.0)
	var older := _kill(made, at + Vector2(1.0, 0.0))
	crowd.remains.step(1.0)
	var newer := _kill(made, at + Vector2(-1.0, 0.0))
	var got := crowd.remains.near(at, 3.0)
	t.check(got.size() == 2 and got[0] == older and got[1] == newer, "Remains.near(): a tie in distance goes to the older body")
	_done(made)
