class_name ShelterEscort
extends Duty
## The shelter escort (soldier duties, slice f): at City Emergency, when a household's first member is home and waits there
## (Mind.REGROUP), two free soldiers run to the house and lead the whole family to a shelter with room within SHELTER_REACH: the
## members walk to its door in REGROUP, the squad keeping beside them, and each goes in. While a living, free squad man stands
## within STEADY_R of a member a near miss (a danger that does not reach him) does not scatter him; a direct hit does. If the last
## squad man dies the members still outside panic and a banner says so. The job ends when everyone is in; at the Evacuation (the
## members are left to flee as without an escort); when the shelter fills or is lost and no other has room, when no crew comes in
## OPEN_WAIT s, or after LEAD_LIMIT s: the members outside are then handed back to the normal flow (home to wait; at the Evacuation
## the one at the door goes in and the rest flee). Only a started job holds a family
## from fleeing. Nothing here draws a number from any rng.

## Squads at once (scaled by the board's cap()), the men of one, how far from the house a shelter may be.
const ESCORT_SQUADS := 3
const CREW := 2
const SHELTER_REACH := 12.0
## How near a member a squad man must stand to steady him, and how far the squad's anchor may lag the group before it moves.
const STEADY_R := EscortManager.STEADY_R
const KEEP := EscortManager.REACH
## The tag and the banner.
const TAG := "ESCORT"
const BANNER := "A HOUSEHOLD SCATTERS"
## The colour of the tag and of the shield badge, and how long each badge is set for.
const COLOUR := Color(0.55, 0.8, 0.95)
const BADGE_SECONDS := 1.5
## Seconds an unstaffed (open) job waits for its full crew, and the longest a started one lasts.
const OPEN_WAIT := 10.0
const LEAD_LIMIT := 60.0
## Seconds a family whose open job timed out is not posted again.
const COOLDOWN := 10.0

## The jobs that are not over (the near-miss test loops these; empty means nothing is steadied).
var _live: Array[GuardJobs.Job] = []
## Person -> the started job whose household he belongs to.
var _in := {}
## Family -> the crowd clock until which it is not posted again (its open job timed out).
var _cool := {}


func kind() -> int:
	return GuardJobs.Kind.SHELTER


## Whether a started escort holds the family `family` now (an open job holds nobody; at the Evacuation none does).
func escorting(family: int) -> bool:
	if crowd.alarms.stage >= AlarmManager.Stage.EVACUATION:
		return false
	for job in _live:
		if job.started and not bool(job.data.over) and job.data.family == family:
			return true
	return false


## Whether the near miss of a danger at `from` (radius `radius`) does not frighten `p`: he belongs to a started escort, the danger
## does not reach him, and a living squad man in no hand but the town's stands within STEADY_R. False at once with no escort live.
func steadied(p: Person, from: Vector2, radius: float) -> bool:
	if _live.is_empty():
		return false
	var job: Variant = _in.get(p)
	if job == null or not (job as GuardJobs.Job).started or bool(job.data.over):
		return false
	if p.ground_pos.distance_to(from) <= radius:
		return false
	for m: Variant in (job as GuardJobs.Job).crew:
		if is_instance_valid(m) and (m as Person).is_alive() and not (m as Person).held_by_god() \
				and (m as Person).ground_pos.distance_to(p.ground_pos) <= STEADY_R:
			return true
	return false


func may_take(job: GuardJobs.Job, p: Person) -> bool:
	return p.corps == Person.Corps.NONE and not bool(job.data.over)


func on_taken(job: GuardJobs.Job, _p: Person) -> void:
	if job.crew.size() >= job.need:
		_begin(job)


## He is still on the squad while he walks his orders in a post mind (a hold of the god's is left to the board; another's order
## moved him off the spot this duty sent him to: he is theirs).
func still_on(job: GuardJobs.Job, p: Person) -> bool:
	if p.mind != Person.Mind.POST:
		return false
	var spot: Variant = job.data.orders.get(p)
	return spot == null or p.anchor.is_equal_approx(spot)


## A man left the job: he goes back to his post when he is still on the spot this job sent him to; the last man of a started job
## leaving ends it (dead: the household scatters; else it is handed back).
func on_dropped(job: GuardJobs.Job, p: Person) -> void:
	var d: Dictionary = job.data
	var spot: Variant = d.orders.get(p)
	d.orders.erase(p)
	if is_instance_valid(p) and p.is_alive() and spot is Vector2 and (p.mind == Person.Mind.POST or p.held_by_god()) \
			and p.anchor.is_equal_approx(spot) and not p.anchor.is_equal_approx(p.post):
		p.back_to_post()
	if bool(d.over) or not job.started or not job.crew.is_empty():
		return
	if is_instance_valid(p) and not p.is_alive():
		_scatter(job, p.ground_pos)
	else:
		_finish(job, true)


## Counts the clocks: an unstaffed job's wait, a started job's life; a freed man leaves the crew.
func tick(job: GuardJobs.Job, delta: float) -> void:
	var d: Dictionary = job.data
	if bool(d.over):
		return
	for i in range(job.crew.size() - 1, -1, -1):
		if not is_instance_valid(job.crew[i]):
			job.crew.remove_at(i)
	if not job.started:
		d.wait = float(d.wait) - delta
		if float(d.wait) <= 0.0:
			_cool[d.family] = crowd._clock + COOLDOWN
			_finish(job, true)
		return
	d.age = float(d.age) + delta
	if float(d.age) >= LEAD_LIMIT:
		_finish(job, true)


func done(job: GuardJobs.Job) -> bool:
	return bool(job.data.over)


## Once a second: every live job takes its next step; while the town is between City Emergency and the Evacuation waiting
## households get their jobs.
func post_jobs() -> void:
	for i in range(_live.size() - 1, -1, -1):
		if _live[i].ended:
			_live.remove_at(i)
	var stage := crowd.alarms.stage
	var window := stage >= AlarmManager.Stage.CITY_EMERGENCY and stage < AlarmManager.Stage.EVACUATION
	if _live.is_empty() and not window:
		return
	var by_fam := {}
	for p in crowd.citizens:
		if is_instance_valid(p) and p.mind == Person.Mind.REGROUP and p.is_alive() and not p.inside and not p.night_indoors \
				and p.profile != null:
			if not by_fam.has(p.profile.family):
				by_fam[p.profile.family] = []
			(by_fam[p.profile.family] as Array).append(p)
	for job in _live.duplicate():
		_step(job, by_fam)
	if window:
		_post(by_fam)


func tags(job: GuardJobs.Job) -> Array[MapTag]:
	var out: Array[MapTag] = []
	if job.started and not bool(job.data.over) and not job.crew.is_empty() and is_instance_valid(job.crew[0]):
		out.append(MapTag.person(job.crew[0], COLOUR, TAG))
	return out


## The board closed (the Citadel fell): every job ends and its members are handed back as at any other end.
func on_close() -> void:
	for job in _live.duplicate():
		_finish(job, true)
	_release_all(false)


## A new crowd or act: every badge comes off, a squad man out on his orders goes back to his post, every job is forgotten.
func clear() -> void:
	_release_all(true)
	_cool.clear()


## Takes this duty's badges off, forgets the jobs; with `home`, a living squad man still on his order goes back to his post.
func _release_all(home: bool) -> void:
	for job in _live:
		_unbadge(job.data)
		for m: Variant in job.crew:
			if home and is_instance_valid(m):
				var p: Person = m
				var spot: Variant = job.data.orders.get(p)
				if p.is_alive() and not p.held_by_god() and spot is Vector2 and p.anchor.is_equal_approx(spot) \
						and not p.anchor.is_equal_approx(p.post):
					p.back_to_post()
		job.data.over = true
	_live.clear()
	_in.clear()


## Posts a job for each waiting household (nearest to the nearest free man first, then by family key) up to the cap, while two free
## men are about.
func _post(by_fam: Dictionary) -> void:
	var cap := board.cap(ESCORT_SQUADS)
	if _live.size() >= cap:
		return
	var free: Array[Person] = []
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.corps == Person.Corps.NONE and board.is_free(p):
			free.append(p)
	if free.size() < CREW:
		return
	var have := {}
	for job in _live:
		have[job.data.family] = true
	var keys := by_fam.keys()
	keys.sort()
	var cands: Array = []
	for fam in keys:
		if have.has(fam) or float(_cool.get(fam, -INF)) > crowd._clock:
			continue
		var members: Array = by_fam[fam]
		if not _waiting(members):
			continue
		var home: Vector2 = (members[0] as Person).profile.home
		var shelter := crowd.shelters.nearest_with_room(home, SHELTER_REACH, members.size())
		if shelter == null:
			continue
		var d := INF
		for p in free:
			d = minf(d, p.ground_pos.distance_to(home))
		cands.append([d, fam, home, shelter, members])
	cands.sort_custom(func(a: Array, b: Array) -> bool:
		if a[0] != b[0]:
			return a[0] < b[0]
		return a[1] < b[1])
	for c: Array in cands:
		if _live.size() >= cap:
			break
		var home: Vector2 = c[2]
		var shelter: Structure = c[3]
		var job := board.post(GuardJobs.Kind.SHELTER, home, CREW, INF, {"family": c[1], "shelter": shelter, "home": home,
				"door": _door(shelter, home), "members": c[4], "sent": [], "dropped": {}, "orders": {}, "badged": {},
				"wait": OPEN_WAIT, "age": 0.0, "begun": false, "led": false, "over": false})
		if job != null:
			_live.append(job)


## Whether a household's members may be escorted: one is home and standing, none is a director's.
func _waiting(members: Array) -> bool:
	var home_one := false
	for m: Person in members:
		if crowd.held_by_mission(m) or m.answers_lure:
			return false
		var home: Vector2 = m.profile.home
		home_one = home_one or (not m.has_goal() and m.ground_pos.distance_to(home) <= Crowd.HOME_REACH)
	return home_one


## The squad is on: each man runs to his spot beside the house.
func _begin(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	d.begun = true
	d.age = 0.0
	for m: Person in d.members:
		_in[m] = job
	for i in job.crew.size():
		var p: Person = job.crew[i]
		var spot := _snap(Vector2(d.home) + EscortManager.OFFSETS[i % EscortManager.OFFSETS.size()])
		p.send_to_post(spot, false, true)
		d.orders[p] = spot


## One step of a job, once a second.
func _step(job: GuardJobs.Job, by_fam: Dictionary) -> void:
	var d: Dictionary = job.data
	if bool(d.over):
		return
	if crowd.alarms.stage >= AlarmManager.Stage.EVACUATION:
		_finish(job, true)
		return
	var pending: Array[Person] = []
	for m: Person in by_fam.get(d.family, []):
		if not d.dropped.has(m) and not crowd.held_by_mission(m) and not m.answers_lure:
			pending.append(m)
	d.members = pending
	var coming := 0
	var sent: Array = []
	for m: Variant in d.sent:
		if is_instance_valid(m) and (m as Person).is_alive() and ((m as Person).inside or (m as Person).mind == Person.Mind.SHELTER):
			sent.append(m)
			if not (m as Person).inside:
				coming += 1
	d.sent = sent
	if pending.is_empty() and coming == 0:
		_finish(job, false)
		return
	if not pending.is_empty() and crowd.shelters.room(d.shelter) < pending.size():
		var alt := crowd.shelters.nearest_with_room(d.home, SHELTER_REACH, pending.size())
		if alt == null:
			_finish(job, true)
			return
		d.shelter = alt
		d.door = _door(alt, d.home)
	if not job.started or not bool(d.begun):
		return
	for m in pending:
		_in[m] = job
		_badge(m, d)
	for m: Variant in d.badged.keys():
		if not is_instance_valid(m) or not pending.has(m):
			if is_instance_valid(m):
				_clear_badge(m)
			d.badged.erase(m)
	if not bool(d.led):
		if _crew_arrived(job):
			d.led = true
		else:
			return
	var door: Vector2 = d.door
	for m in pending:
		if m.ground_pos.distance_to(door) <= ShelterManager.DOOR_REACH:
			if crowd.shelters.send_in(m, d.shelter):
				d.sent.append(m)
			else:
				d.dropped[m] = true
				if not m.anchor.is_equal_approx(d.home):
					m.regroup(d.home)
		elif not m.anchor.is_equal_approx(door):
			m.regroup(door)
	_follow(job, pending)


## Whether every living squad man in no hand but the town's stands on his spot (and at least one does).
func _crew_arrived(job: GuardJobs.Job) -> bool:
	var any := false
	for m: Variant in job.crew:
		if not is_instance_valid(m) or not (m as Person).is_alive() or (m as Person).held_by_god():
			continue
		var spot: Variant = job.data.orders.get(m)
		if not (spot is Vector2) or (m as Person).ground_pos.distance_to(spot) > Person.GOAL_REACH * 2.0:
			return false
		any = true
	return any


## The squad keeps beside the group: a man whose anchor has drifted more than KEEP from his place about the group's middle is
## sent to it (one order, not one per frame).
func _follow(job: GuardJobs.Job, pending: Array[Person]) -> void:
	var d: Dictionary = job.data
	var centre: Vector2 = d.door
	if not pending.is_empty():
		centre = Vector2.ZERO
		for m in pending:
			centre += m.ground_pos
		centre /= float(pending.size())
	for i in job.crew.size():
		var p: Variant = job.crew[i]
		if not is_instance_valid(p) or not (p as Person).is_alive() or (p as Person).mind != Person.Mind.POST or (p as Person).held_by_god():
			continue
		var spot := _snap(centre + EscortManager.OFFSETS[i % EscortManager.OFFSETS.size()])
		if (p as Person).anchor.distance_to(spot) > KEEP:
			(p as Person).send_to_post(spot, false, true)
			d.orders[p] = spot


## The job is over: badges and membership go; with `hand` the members still outside are given back (home to wait, or at the
## Evacuation the one by the door goes in and the rest flee).
func _finish(job: GuardJobs.Job, hand: bool) -> void:
	var d: Dictionary = job.data
	if bool(d.over):
		return
	d.over = true
	_live.erase(job)
	_unbadge(d)
	for m in _in.keys():
		if not is_instance_valid(m) or _in[m] == job:
			_in.erase(m)
	if not hand:
		return
	for m: Variant in d.members:
		if not is_instance_valid(m):
			continue
		var p: Person = m
		if not p.is_alive() or p.inside or p.mind != Person.Mind.REGROUP:
			continue
		if crowd.alarms.stage >= AlarmManager.Stage.EVACUATION:
			if p.ground_pos.distance_to(d.door) <= ShelterManager.DOOR_REACH and crowd.shelters.send_in(p, d.shelter):
				continue  # by the door at the Evacuation: in
			p.flee()  # no household wait away from home
		elif not p.anchor.is_equal_approx(d.home):
			p.regroup(d.home)


## The last squad man fell at `at`: the members still outside panic and the banner shows.
func _scatter(job: GuardJobs.Job, at: Vector2) -> void:
	var d: Dictionary = job.data
	var members: Array = d.members.duplicate()
	_finish(job, false)
	crowd.duty_event.emit(GuardJobs.Kind.SHELTER, BANNER, at)
	for m: Variant in members:
		if is_instance_valid(m) and (m as Person).is_alive() and not (m as Person).inside and (m as Person).mind == Person.Mind.REGROUP:
			(m as Person).panic(at, 1.0, &"", true, false)


## The shield badge on a member (renewed; never over another badge a mission put on him).
func _badge(m: Person, d: Dictionary) -> void:
	d.badged[m] = true
	if m.badge_left <= 0.0 or m.badge_glyph == GuardJobs.GLYPH_SHIELD:
		m.set_badge(GuardJobs.GLYPH_SHIELD, COLOUR, BADGE_SECONDS)


func _clear_badge(m: Person) -> void:
	if m.badge_glyph == GuardJobs.GLYPH_SHIELD:
		m.clear_badge()


## Takes every shield badge of a job off.
func _unbadge(d: Dictionary) -> void:
	for m: Variant in d.badged.keys():
		if is_instance_valid(m):
			_clear_badge(m)
	d.badged.clear()


## The door of `s` on the side `from` lies (the shelter's own door point, without its jitter: no rng is drawn).
func _door(s: Structure, from: Vector2) -> Vector2:
	var dir := (from - s.center()).normalized() if from.distance_to(s.center()) > 0.01 else Vector2.DOWN
	return _snap(s.center() + dir * (s.footprint.size.length() * 0.5 + 0.3))


## `at` on open ground (the shared rng is never drawn from).
func _snap(at: Vector2) -> Vector2:
	var s := crowd._grid.nearest_walkable(at)
	return at if s == Vector2.INF else s
