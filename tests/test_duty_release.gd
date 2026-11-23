extends RefCounted
## Soldier duties, final review wave (R14): a director takes only the men it keeps and a taken man leaves his duty. A hunt that
## asks for every soldier but keeps two (EscortDirector._appoint_hunters) wipes no other board record; the men it keeps leave
## their sweep, cordon or gate job with their flags off; GuardJobs.release() on a Job man does the same for any director.

const Corps := preload("res://tests/test_corps.gd")
const C := preload("res://tests/test_cordon.gd")
const TS := preload("res://tests/test_sweep.gd")
const TG := preload("res://tests/test_gate_check.gd")
const GATE := GuardJobs.Kind.GATE
const SWEEP := GuardJobs.Kind.SWEEP
const CORDON := GuardJobs.Kind.CORDON


static func run(t) -> void:
	_hunt_takes_only_kept(t)
	_release_leaves_duty(t)
	_tick_drops_stray(t)


## A world with a stepped-out gate checker, a cordon crew of two and a sweep crew of four, all on the board (`ok` false when one
## is missing).
static func _scene() -> Dictionary:
	var made := C._world()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = AlarmManager.Stage.LOCAL_EMERGENCY  # the gate check is live only from Local Emergency (R20)
	var gate := TG._none_gate(crowd)
	var checker := TG._ready_gate(crowd, gate) if gate != null else null
	var house := C._site(made)
	var cord := C._up(made, house) if house != null else null
	var at := TS._spot(made, TS._busy(made))
	var sweep := TS._up(made, at, false)
	var ok := checker != null and cord != null and sweep != null
	if ok:
		TS._arrive(sweep)
		C._arrive(cord)
	return {"ok": ok, "made": made, "crowd": crowd, "gate": gate, "checker": checker, "cord": cord, "sweep": sweep}


static func _end(s: Dictionary) -> void:
	C._done(s.made)


static func _hunt_takes_only_kept(t) -> void:
	var s := _scene()
	t.check(s.ok, "(a checker out on his spot, a cordon of two, a sweep of four)")
	if not s.ok:
		_end(s)
		return
	var crowd: Crowd = s.crowd
	var board := crowd.guard_jobs
	var checker: Person = s.checker
	var cord: GuardJobs.Job = s.cord
	var sweep: GuardJobs.Job = s.sweep
	var sweep_man: Person = sweep.crew[0]
	var cord_man: Person = cord.crew[0]
	var sweep_rest: Array[Person] = []
	sweep_rest.assign(sweep.crew.slice(1))
	var cord_rest: Person = cord.crew[1]
	t.check(sweep_man.watch_far and sweep_man.badge_left > 0.0, "(the sweep is begun: his far sight and eye badge are on)")
	var d := EscortDirector.new()
	d.crowd = crowd
	d.return_to = TownLayout.MAP.position + Vector2(1.0, 1.0)
	sweep_man.ground_pos = d.return_to
	cord_man.ground_pos = d.return_to + Vector2(0.1, 0.0)
	var held: Array[Person] = []
	for p in crowd.soldiers:
		if board.on_job(p) and p != sweep_man and p != cord_man:
			held.append(p)
	var got := d._appoint_hunters(null, 2)
	t.check(got.size() == 2 and got.has(sweep_man) and got.has(cord_man), "the hunt appoints the two nearest (%d)" % got.size())
	var wiped := 0
	for p in held:
		if not board.on_job(p):
			wiped += 1
	t.check(wiped == 0, "no other man loses his board record (%d of %d wiped)" % [wiped, held.size()])
	t.check(not board.on_job(sweep_man) and not board.on_job(cord_man), "the appointed men are off the board")
	t.check(board.kind_of(checker) == GATE and crowd.gate_check.checked(s.gate), "the checker still checks")
	t.check(not sweep.crew.has(sweep_man) and not cord.crew.has(cord_man), "an appointed man left his sweep or cordon crew")
	var kept := true
	for m in sweep_rest:
		kept = kept and sweep.crew.has(m) and board.job_of(m) == sweep
	t.check(kept and cord.crew.has(cord_rest) and board.job_of(cord_rest) == cord, "the men not appointed keep their sweep and cordon jobs")
	t.check(not sweep_man.watch_far and sweep_man.badge_left <= 0.0 and sweep_man.talk_left == 0.0,
			"the taken sweep man has no far sight, badge or talk")
	var there := d.return_to + Vector2(3.0, 0.0)
	d._post_to(sweep_man, there, false)
	for i in 3:
		TG._tick(crowd)
	C._run_for(crowd, 1.0)
	t.check(sweep_man.anchor.is_equal_approx(there) and not sweep_man.watch_far and not board.on_job(sweep_man),
			"he obeys the director: nobody sends him home or flags him again")
	for job in board.jobs.duplicate():
		board.end_job(job)
	for job in board.live(GATE):
		board.end_job(job)
	var off := 0
	var men: Array[Person] = [checker, cord_rest]
	men.append_array(sweep_rest)
	for p in men:
		if not p.anchor.is_equal_approx(p.post):
			off += 1
	t.check(off == 0, "when the duties end nobody he left stands off his post (%d)" % off)
	_end(s)


## release() of a Job man: out of the crew, his duty's flags off, no walk home ordered.
static func _release_leaves_duty(t) -> void:
	var s := _scene()
	t.check(s.ok, "(the scene)")
	if not s.ok:
		_end(s)
		return
	var crowd: Crowd = s.crowd
	var board := crowd.guard_jobs
	var sweep: GuardJobs.Job = s.sweep
	var cord: GuardJobs.Job = s.cord
	var m: Person = sweep.crew[0]
	var n: Person = cord.crew[0]
	n.talk_left = 1.0
	board.release(m)
	board.release(n)
	t.check(not sweep.crew.has(m) and not m.watch_far and m.badge_left <= 0.0, "released sweep man: off the crew, no far sight, no badge")
	t.check(not cord.crew.has(n) and n.talk_left == 0.0, "released cordon man: off the crew, no talk")
	t.check(not board.on_job(m) and not board.on_job(n), "and neither holds a record")
	_end(s)


## A crew man whose record is not the job's any more is dropped by every duty's tick.
static func _tick_drops_stray(t) -> void:
	var s := _scene()
	t.check(s.ok, "(the scene)")
	if not s.ok:
		_end(s)
		return
	var crowd: Crowd = s.crowd
	var board := crowd.guard_jobs
	var sweep: GuardJobs.Job = s.sweep
	var cord: GuardJobs.Job = s.cord
	var m: Person = sweep.crew[0]
	var n: Person = cord.crew[0]
	board._jobs.erase(m)
	board._jobs.erase(n)
	board.step(0.0)
	t.check(not sweep.crew.has(m) and not m.watch_far and m.badge_left <= 0.0, "a sweep tick drops a man whose record is gone")
	t.check(not cord.crew.has(n), "a cordon tick drops a man whose record is gone")
	_end(s)
