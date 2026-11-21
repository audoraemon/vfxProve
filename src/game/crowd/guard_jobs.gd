class_name GuardJobs
extends RefCounted
## The guard job board (soldier jobs): which ordinary guards -- corps NONE, standing at the post the town gave them -- are away
## on a job (fighting a fire; digging a pile later), and who may be taken. Mission-placed soldiers never take a job. Jobs stop
## at the rally (close()); the leaderless town's forgo_rally() is not a rally.

## How much of the guards near a job (those already on it plus the free ones) it may have, and how many of a post group
## (yard, walls, citadel, patrol) must stay at their posts.
const SHARE := 0.5
const GROUP_KEEP := 1
## The job kinds, in priority order (highest first). FIRE and PILE keep their own Structure and Pile records.
enum Kind { CITADEL, FIRE, PILE, SHELTER, SWEEP, CORPSE, CORDON, GATE }
## Seconds between the board's ticks (duties post jobs, open jobs are filled).
const EVERY := 1.0
## The sweep's badge: an eye (five rows of five bits, as Person's glyphs).
const GLYPH_EYE: Array[int] = [0b00000, 0b01110, 0b11011, 0b01110, 0b00000]
## The gate guard's badge when he sees through someone: an exclamation mark.
const GLYPH_ALERT: Array[int] = [0b00100, 0b00100, 0b00100, 0b00000, 0b00100]


## One open job of a new kind.
class Job:
	## Its Kind.
	var kind: int
	## Where the crew is wanted (nearest free man first from here).
	var at := Vector2.INF
	## The board clock when it was posted (oldest first).
	var born := 0.0
	## Posting order (the last tie-break).
	var seq := 0
	## The full crew.
	var need := 0
	## Free men only within this of `at`.
	var reach := INF
	## The men on it.
	var crew: Array[Person] = []
	## Whether a full crew was once assigned (the fixed-crew rule).
	var started := false
	## Whether it is over.
	var ended := false
	## The kind's own state.
	var data := {}


var open := true
## Open jobs of the new kinds, in posting order.
var jobs: Array[Job] = []
## Kind -> the Duty that posts and runs that kind.
var duties := {}
## The board's clock (seconds since the crowd was made).
var clock := 0.0
var _crowd: Crowd
var _tick_left := EVERY
var _seq := 0
## Person -> the job he is on (a burning Structure, a Pile or a Job). Insertion order, so deterministic.
var _jobs := {}
## Person -> the spot his job gave him to stand at (a pile's dig spot; none for a fire, which he fights as ASSIST).
var _spots := {}


func setup(crowd: Crowd) -> GuardJobs:
	_crowd = crowd
	return self


func is_open() -> bool:
	return open


## Whether `p` is an ordinary guard standing at his own post, free of any role, look, escort or mission hold.
func at_post(p: Variant) -> bool:
	if not is_instance_valid(p):
		return false
	var s := p as Person
	if s == null or not s.is_alive() or not s.soldier or s.corps != Person.Corps.NONE or s.inside:
		return false
	if s.town_post == Vector2.INF or not s.post.is_equal_approx(s.town_post) or s.post_group < 0:
		return false
	if not s.at_own_post() or s.has_goal():
		return false
	if _crowd.escorts != null and _crowd.escorts.guarding(s):
		return false
	return not _crowd.held_by_mission(s) and not mission_man(s)


## Whether `p` is a director's soldier (never taken by a town duty): an `add_soldier()` guard with no town post, one re-posted
## away from the town's post, held by a mission hook, on a duty errand, or stationed away from his post by a director's
## send_to_post() (a man on a board job is not stationed; his job sent him).
func mission_man(p: Variant) -> bool:
	if not is_instance_valid(p):
		return false
	var s := p as Person
	if s == null or not s.is_alive() or not s.soldier or s.corps != Person.Corps.NONE:
		return false
	if s.post_group < 0 or not s.post.is_equal_approx(s.town_post) or _crowd.held_by_mission(s) or s.mind == Person.Mind.DUTY:
		return true
	return not s.anchor.is_equal_approx(s.post) and not on_job(s) \
			and (s.mind == Person.Mind.POST or s.mind == Person.Mind.HOLD)


## Whether `p` is a street beat man who may be given a job now though he is mid-leg: alive, a soldier, no corps, out of doors,
## on his beat, his mind POST, not in the god's hand, not named by a mission, not guarding for an escort, not on a job.
func beat_walker(p: Variant) -> bool:
	if not is_instance_valid(p):
		return false
	var s := p as Person
	if s == null or not s.is_alive() or not s.soldier or s.corps != Person.Corps.NONE or s.inside or not s.on_beat():
		return false
	if s.mind != Person.Mind.POST or s.held_by_god() or _crowd.held_by_mission(s) or mission_man(s):
		return false
	return not (_crowd.escorts != null and _crowd.escorts.guarding(s)) and not on_job(s)


## Whether `p` is a gate checker who may be given a higher job: his only record is a GATE job, he is out of doors on a post mind, in
## no hand but the town's, no corps, not named by a mission and not guarding for an escort. He may be mid-step to his spot.
func gate_checker(p: Variant) -> bool:
	if not is_instance_valid(p) or kind_of(p) != Kind.GATE:
		return false
	var s := p as Person
	if not s.is_alive() or not s.soldier or s.corps != Person.Corps.NONE or s.inside or s.mind != Person.Mind.POST:
		return false
	if s.held_by_god() or _crowd.held_by_mission(s) or (_crowd.escorts != null and _crowd.escorts.guarding(s)):
		return false
	return s.post_group >= 0 and s.post.is_equal_approx(s.town_post)


## Whether `p` may be given a job now: at his post, a beat man on his way, or a gate checker (the lowest job: any other kind may
## take him and that is not a pull).
func is_free(p: Variant) -> bool:
	return eligible(p) or beat_walker(p) or gate_checker(p)


## A cap `base` scaled to the town's guard (Aldermere's 100 soldiers keep it as it is).
func cap(base: int) -> int:
	if _crowd.spawned_soldiers <= 0:
		return base
	return ceili(float(base) * float(_crowd.spawned_soldiers) / 100.0)


func eligible(p: Variant) -> bool:
	return at_post(p) and not on_job(p)


## The free guards (is_free(): at their posts or walking a beat) within `reach` of `at`, nearest first (ties by stagger).
func free_near(at: Vector2, reach: float) -> Array[Person]:
	var out: Array[Person] = []
	for p in _crowd.soldiers:
		if is_free(p) and p.ground_pos.distance_to(at) <= reach:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_to(at)
		var db := b.ground_pos.distance_to(at)
		if da != db:
			return da < db
		return a.stagger < b.stagger)
	return out


## Whom a job at `at` may take: `want` = its share (SHARE) of the guards near it (`on_here` already on it plus the free),
## less those already there, at most `cap`; nobody whose leaving would leave his post group under GROUP_KEEP at their posts.
## Returns the taken without calling take().
func pick(at: Vector2, reach: float, on_here: int, cap: int) -> Array[Person]:
	var free := free_near(at, reach)
	var want := mini(ceili(float(on_here + free.size()) * SHARE) - on_here, cap)
	var out: Array[Person] = []
	if want <= 0:
		return out
	var left := {}
	for p in _crowd.soldiers:
		if is_free(p):
			left[p.post_group] = int(left.get(p.post_group, 0)) + 1
	for p in free:
		if out.size() >= want:
			break
		if int(left.get(p.post_group, 0)) - 1 < GROUP_KEEP:
			continue
		left[p.post_group] = int(left[p.post_group]) - 1
		out.append(p)
	return out


## `spot`: where the job stands him (a dig spot); a guard dropped while still anchored there walks home.
func take(p: Person, job: Variant, spot := Vector2.INF) -> void:
	var old: Variant = _jobs.get(p)
	_jobs[p] = job
	if old is Job and old != job and (old as Job).kind == Kind.GATE:
		# A gate checker taken by a higher job: his GATE record yields (his job is no longer his record, so he is not sent to his post).
		(old as Job).crew.erase(p)
		duties[Kind.GATE].on_dropped(old, p)
	if spot != Vector2.INF:
		_spots[p] = spot
	else:
		_spots.erase(p)
	p.on_guard_job = not (job is Job and (job as Job).kind == Kind.GATE)  # a gate guard still counts as a watcher


func job_of(p: Variant) -> Variant:
	if not is_instance_valid(p):
		return null
	return _jobs.get(p, null)


func on_job(p: Variant) -> bool:
	return is_instance_valid(p) and _jobs.has(p)


func release(p: Variant) -> void:
	if not is_instance_valid(p):
		return
	_drop(p as Person, true)


## Drop records of people gone, dead or no longer on their job (a god-held guard keeps his: he comes back to it). A man of a
## Job is also dropped when he fights, a director took him or his duty says he is off it.
func prune() -> void:
	if _jobs.is_empty():
		return
	for k in _jobs.keys():
		if not is_instance_valid(k):
			_jobs.erase(k)
			_spots.erase(k)
			continue
		var p: Person = k
		if p.is_alive() and p.held_by_god():
			continue
		var rec: Variant = _jobs[k]
		if rec is Job:
			var job: Job = rec
			if not p.is_alive() or p.mind == Person.Mind.FIGHT or (job.kind != Kind.CITADEL and mission_man(p)) \
					or not duties[job.kind].still_on(job, p):
				drop(job, p)
		elif not p.is_alive() or not _still_on(p, rec):
			_drop(p, true)


## The board's frame: prune; count the jobs' clocks; once a second each duty posts its jobs, open jobs are filled and ended
## ones go. A closed board (the Citadel fell) fills nothing and posts nothing.
func step(delta: float) -> void:
	prune()
	clock += delta
	if not open:
		return
	for job in jobs:
		duties[job.kind].tick(job, delta)
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += EVERY
	for kind in Kind.values():
		if duties.has(kind):
			(duties[kind] as Duty).post_jobs()
	_fill()
	for job in jobs.duplicate():
		if duties[job.kind].done(job) or (job.started and job.crew.is_empty() and job.kind != Kind.CITADEL):
			end_job(job)


## Registers the duty that runs its kind.
func add_duty(d: Duty) -> void:
	duties[d.kind()] = d


## Posts an open job of `kind`; null (nothing posted) for a kind with no registered duty.
func post(kind: int, at: Vector2, need: int, reach := INF, data := {}) -> Job:
	if not duties.has(kind):
		return null
	var job := Job.new()
	job.kind = kind
	job.at = at
	job.born = clock
	job.seq = _seq
	_seq += 1
	job.need = need
	job.reach = reach
	job.data = data
	jobs.append(job)
	return job


## Puts `p` on `job`.
func assign(job: Job, p: Person) -> void:
	take(p, job)
	job.crew.append(p)
	duties[job.kind].on_taken(job, p)


## Takes `p` off `job` and gives him back to his post.
func drop(job: Job, p: Person) -> void:
	job.crew.erase(p)
	duties[job.kind].on_dropped(job, p)
	_drop(p, true)


## Ends `job`: every man is dropped and it goes off the board.
func end_job(job: Job) -> void:
	for p in job.crew.duplicate():
		drop(job, p)
	job.ended = true
	jobs.erase(job)


## Whether `p` may be pulled off his job for a higher one: on a job that is not CITADEL, not SHELTER and not a corpse carry.
func pullable(p: Variant) -> bool:
	if not is_instance_valid(p) or not _jobs.has(p) or not (p as Person).is_alive():
		return false
	var rec: Variant = _jobs[p]
	if rec is Job:
		var job: Job = rec
		return job.kind != Kind.CITADEL and job.kind != Kind.SHELTER \
				and not (job.kind == Kind.CORPSE and bool(job.data.get("carrying", false)))
	return true


## Takes `p` off whatever job he is on, ready to be sent elsewhere: a fire man stands down, a pile man is released, a Job man
## is dropped.
func pull(p: Person) -> void:
	var rec: Variant = job_of(p)
	if rec is Structure:
		if p.mind == Person.Mind.ASSIST and p.assist_fire == rec:
			p.stand_down()
	elif rec is PileManager.Pile:
		_crowd.piles.release(p)
	elif rec is Job:
		drop(rec, p)
	release(p)


## The kind of the job `p` is on (a Structure is FIRE, a Pile is PILE); -1 for none.
func kind_of(p: Variant) -> int:
	var rec: Variant = job_of(p)
	if rec is Structure:
		return Kind.FIRE
	if rec is PileManager.Pile:
		return Kind.PILE
	if rec is Job:
		return (rec as Job).kind
	return -1


## The open jobs of `kind`, in posting order.
func live(kind: int) -> Array[Job]:
	var out: Array[Job] = []
	for job in jobs:
		if job.kind == kind and not job.ended:
			out.append(job)
	return out


## The map tags of every live job, in priority order.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for kind in Kind.values():
		if duties.has(kind):
			for job in live(kind):
				out.append_array((duties[kind] as Duty).tags(job))
			out.append_array((duties[kind] as Duty).standing_tags())
	return out


## Fills open jobs in kind priority order, oldest first, from the free men nearest the job, keeping GROUP_KEEP of each post
## group at their posts. A job not yet started is assigned only a full crew; a started one is refilled up to its duty's say.
func _fill() -> void:
	if jobs.is_empty():
		return
	var left := {}
	for p in _crowd.soldiers:
		if is_free(p):
			left[p.post_group] = int(left.get(p.post_group, 0)) + 1
	var order := jobs.duplicate()
	order.sort_custom(func(a: Job, b: Job) -> bool:
		if a.kind != b.kind:
			return a.kind < b.kind
		if a.born != b.born:
			return a.born < b.born
		return a.seq < b.seq)
	for job: Job in order:
		var duty: Duty = duties[job.kind]
		var want := duty.refills(job) if job.started else job.need - job.crew.size()
		if want <= 0:
			continue
		var at := duty.target(job)
		var cands: Array[Person] = []
		for p in _crowd.soldiers:
			if is_free(p) and duty.may_take(job, p) and p.ground_pos.distance_to(at) <= job.reach:
				cands.append(p)
		cands.sort_custom(func(a: Person, b: Person) -> bool:
			var da := a.ground_pos.distance_to(at)
			var db := b.ground_pos.distance_to(at)
			if da != db:
				return da < db
			return a.stagger < b.stagger)
		var sim := left.duplicate()
		var chosen: Array[Person] = []
		for p in cands:
			if chosen.size() >= want:
				break
			if int(sim.get(p.post_group, 0)) - 1 < GROUP_KEEP:
				continue
			sim[p.post_group] = int(sim[p.post_group]) - 1
			chosen.append(p)
		if not job.started and chosen.size() < want:
			continue
		for p in chosen:
			assign(job, p)
		if job.started and chosen.size() < want and duty.may_pull(job):
			var pulls: Array[Person] = []
			for p in _crowd.soldiers:
				if pullable(p) and duty.may_take(job, p) and p.ground_pos.distance_to(at) <= job.reach:
					pulls.append(p)
			pulls.sort_custom(func(a: Person, b: Person) -> bool:
				var da := a.ground_pos.distance_to(at)
				var db := b.ground_pos.distance_to(at)
				if da != db:
					return da < db
				return a.stagger < b.stagger)
			var short := want - chosen.size()
			for p in pulls:
				if short <= 0 or not duty.may_pull(job):
					break
				pull(p)
				assign(job, p)
				short -= 1
		left = sim
		if not job.started and job.crew.size() >= job.need:
			job.started = true


## The rally: the jobs end. Fire fighters stand down; the records go.
func close() -> void:
	open = false
	for k in _jobs.keys():
		if is_instance_valid(k):
			var p: Person = k
			var job: Variant = _jobs[k]
			if job is Structure and p.mind == Person.Mind.ASSIST and p.assist_fire == job:
				p.stand_down()
			elif job is PileManager.Pile:
				_crowd.piles.release(p)
			elif job is Job:
				(job as Job).crew.erase(p)
				duties[(job as Job).kind].on_dropped(job, p)
			_drop(p, false)
	_jobs.clear()
	_spots.clear()
	for job in jobs:
		job.ended = true
	jobs.clear()
	for kind in duties:
		(duties[kind] as Duty).on_close()


## A new crowd or act: forget everything and open again.
func clear() -> void:
	for k in _jobs.keys():
		if is_instance_valid(k):
			(k as Person).on_guard_job = false
	_jobs.clear()
	_spots.clear()
	for job in jobs:
		job.ended = true
	jobs.clear()
	for kind in duties:
		(duties[kind] as Duty).clear()
	clock = 0.0
	_tick_left = EVERY
	_seq = 0
	open = true


func _still_on(p: Person, job: Variant) -> bool:
	if job is Structure:
		return p.mind == Person.Mind.ASSIST and p.assist_fire == job
	# A pile job: the pile still stands and he is at the spot it gave him.
	var pile: PileManager.Pile = job
	var spot: Variant = pile.spots.get(p)
	return _crowd.piles.piles.has(pile) and spot is Vector2 and p.mind == Person.Mind.POST and p.anchor.is_equal_approx(spot)


## Drop one record; `home`: a guard still anchored at the spot his job gave him (a stranded digger) walks back. One anchored
## anywhere else was sent there by someone (a director's send_to_post()) and is left to that order.
func _drop(p: Person, home: bool) -> void:
	var spot: Variant = _spots.get(p)
	_jobs.erase(p)
	_spots.erase(p)
	p.on_guard_job = false
	if home and spot is Vector2 and p.is_alive() and not p.held_by_god() and p.mind == Person.Mind.POST \
			and p.anchor.is_equal_approx(spot) and not p.anchor.is_equal_approx(p.post):
		p.back_to_post()
