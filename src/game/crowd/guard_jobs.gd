class_name GuardJobs
extends RefCounted
## The guard job board (soldier jobs): which ordinary guards -- corps NONE, standing at the post the town gave them -- are away
## on a job (fighting a fire; digging a pile later), and who may be taken. Mission-placed soldiers never take a job. Jobs stop
## at the rally (close()); the leaderless town's forgo_rally() is not a rally.

## How much of the guards near a job (those already on it plus the free ones) it may have, and how many of a post group
## (yard, walls, citadel, patrol) must stay at their posts.
const SHARE := 0.5
const GROUP_KEEP := 1

var open := true
var _crowd: Crowd
## Person -> the job he is on (a burning Structure; a pile from Task 6). Insertion order, so deterministic.
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
	if not s.at_own_post() or s.has_goal() or _crowd._looking(s):
		return false
	if _crowd.escorts != null and _crowd.escorts.guarding(s):
		return false
	return not _crowd.held_by_mission(s)


func eligible(p: Variant) -> bool:
	return at_post(p) and not on_job(p)


## The eligible guards within `reach` of `at`, nearest first (ties by stagger).
func free_near(at: Vector2, reach: float) -> Array[Person]:
	var out: Array[Person] = []
	for p in _crowd.soldiers:
		if eligible(p) and p.ground_pos.distance_to(at) <= reach:
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
		if at_post(p):
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
	_jobs[p] = job
	if spot != Vector2.INF:
		_spots[p] = spot
	else:
		_spots.erase(p)
	p.on_guard_job = true


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


## Drop records of people gone, dead or no longer on their job (a god-held guard keeps his: he comes back to it).
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
		if not p.is_alive() or not _still_on(p, _jobs[k]):
			_drop(p, true)


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
			_drop(p, false)
	_jobs.clear()
	_spots.clear()


## A new crowd or act: forget everything and open again.
func clear() -> void:
	for k in _jobs.keys():
		if is_instance_valid(k):
			(k as Person).on_guard_job = false
	_jobs.clear()
	_spots.clear()
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
