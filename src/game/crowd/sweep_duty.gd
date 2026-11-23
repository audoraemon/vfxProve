class_name SweepDuty
extends Duty
## The sweep (soldier duties, slice d), which replaces the two investigators: a power seen by someone, or a district's Local
## Emergency, posts a SWEEP job. Four free soldiers go to the district, hurried, and for SWEEP_SECONDS (counted from the first man
## inside it) walk its houses' doors one after the other, standing SWEEP_STAND s at each with the eye badge over them. They see a
## power from WATCH_SIGHT instead of DOOM_WITNESS (Person.watch_far), a power seen under their eyes adds a little alarm, and they
## are no posted watch (they are on a guard job). Nothing here draws a number from any rng.

## Sweeps at once (scaled by the board's cap()), the men of one, how many doors a sweep walks.
const SWEEPS := 2
const CREW := 4
const SWEEP_DOORS := 6
## Seconds the crew stands at each door, and how long a sweep lasts from its first man inside the district.
const SWEEP_STAND := 3.0
const SWEEP_SECONDS := 30.0
## The extra alarm a power seen under the sweep adds (Crowd.ALARM_BUILDING's worth), at most SWEEP_ALARM_CAP per sweep.
const SWEEP_ALARM := 2.0
const SWEEP_ALARM_CAP := 6.0
## Seconds an unstaffed sweep waits for its men before it gives up (it blocks its district until then).
const OPEN_SECONDS := 20.0
## Seconds a crew may be on one leg before it stands where it is (blocked ground never holds a sweep).
const LEG_LIMIT := 15.0
## How far apart the crew stands around a door.
const SPOT_APART := 0.6
## Seconds of nerve a sweep man is given (Person.fearless_left), renewed every board tick while he is on the job: the investigators'
## exemption from fright.
const NERVE_SECONDS := 2.5
## The badge's and the tag's colour, and how long a badge is set for (renewed every board tick).
const COLOUR := Color(0.6, 0.82, 0.95)
const BADGE_SECONDS := 1.5
## Seconds a man inside a power's danger is remembered as its witness-to-be (R21) before the danger counts as over: anyone alive then tells.
const TELL_SECONDS := 20.0
## The banners.
const BANNER := "SOLDIERS SWEEP THE DISTRICT"
const BANNER_HEARS := "THE SWEEP HEARS IT"
const BANNER_BROKEN := "THE SWEEP IS BROKEN"

## The phases of a job's walk.
enum Phase { WALK, STAND, WAIT }

## The sweep jobs that are not over (a district is swept while it holds one).
var _live: Array[GuardJobs.Job] = []
## The sightings still to be settled (R21): each {"people": Array[Person] by stagger, "at": the point nearest each, "points",
## "radius", "born": the board's clock}, a power whose only witnesses stood inside its own danger.
var _pending: Array[Dictionary] = []


func kind() -> int:
	return GuardJobs.Kind.SWEEP


func setup(b: GuardJobs, c: Crowd) -> Duty:
	super.setup(b, c)
	c.danger_landed.connect(_on_danger)
	return self


## A power seen at `at` (or a Local Emergency there) asks for a sweep of its district: none when the town or the place is hushed or
## veiled, the town is at EVACUATION, the board is closed, the district is swept already or the cap is reached.
func request(at: Vector2) -> void:
	if board == null or not board.is_open() or crowd.is_hushed() or crowd.is_hushed_at(at) or crowd.is_veiled(at):
		return
	if crowd.alarms.stage >= AlarmManager.Stage.EVACUATION:
		return
	var district := AlarmManager.district_of(at)
	if swept(district) or _live.size() >= board.cap(SWEEPS):
		return
	var job := board.post(GuardJobs.Kind.SWEEP, at, CREW, INF, {"district": district, "seen_at": at,
			"rect": City.current().districts()[district] as Rect2, "doors": [] as Array[Vector2], "door": -1, "at_spot": {},
			"phase": Phase.WALK, "held": false, "leg": 0.0, "stand": 0.0, "left": SWEEP_SECONDS, "wait": OPEN_SECONDS, "begun": false,
			"on": false, "over": false, "added": 0.0, "charged": -INF, "idle": LEG_LIMIT + SWEEP_SECONDS})
	if job != null:
		_live.append(job)


## A power seen at `at`: a sweep of that district with a living, unheld man inside it hears of it (extra alarm, at most
## SWEEP_ALARM_CAP a sweep, and one charge per district per frame: a cast that fells three seen men is one power). Nothing is
## heard when the town or the place is hushed or veiled.
func on_seen(at: Vector2) -> void:
	if crowd.is_hushed() or crowd.is_hushed_at(at) or crowd.is_veiled(at):
		return
	var district := AlarmManager.district_of(at)
	for job in _live:
		if job.data.district != district or not bool(job.data.begun) or bool(job.data.over):
			continue
		if float(job.data.added) + SWEEP_ALARM > SWEEP_ALARM_CAP + 0.001 or not _any_inside(job) \
				or float(job.data.charged) == crowd._clock:
			return
		job.data.charged = crowd._clock
		job.data.added = float(job.data.added) + SWEEP_ALARM
		crowd._hear_alarm(SWEEP_ALARM)
		crowd.duty_event.emit(GuardJobs.Kind.SWEEP, BANNER_HEARS, at)
		return


## Whether a sweep (open or begun) holds `district`.
func swept(district: int) -> bool:
	for job in _live:
		if job.data.district == district and not bool(job.data.over):
			return true
	return false


## Up to SWEEP_DOORS doors of `district`'s standing houses: the house nearest `from` first, then each next the nearest to the last
## (ties by the house's position, y then x). A door is the open ground just outside the house on the side facing `from`.
func doors(district: int, from: Vector2) -> Array[Vector2]:
	var rect: Rect2 = City.current().districts()[district]
	var houses: Array[Structure] = []
	for s in crowd._env.structures():
		if s.kind == Structure.Kind.HOUSE and not s.destroyed and rect.has_point(s.center()):
			houses.append(s)
	var out: Array[Vector2] = []
	var last := from
	while out.size() < SWEEP_DOORS and not houses.is_empty():
		var best: Structure = null
		for h in houses:
			if best == null or _nearer(h, best, last):
				best = h
		houses.erase(best)
		var c := best.center()
		var dir := (from - c).normalized() if not from.is_equal_approx(c) else Vector2.DOWN
		var door := crowd._grid.nearest_walkable(c + dir * (best.footprint.size.length() * 0.5 + 0.3))
		if door == Vector2.INF:
			continue
		out.append(door)
		last = c
	return out


## Whether house `a` is nearer `to` than `b` (equal: the one further north, then west).
func _nearer(a: Structure, b: Structure, to: Vector2) -> bool:
	var da := a.center().distance_to(to)
	var db := b.center().distance_to(to)
	if da != db:
		return da < db
	if a.footprint.position.y != b.footprint.position.y:
		return a.footprint.position.y < b.footprint.position.y
	return a.footprint.position.x < b.footprint.position.x


## Whether `p` counts as inside the job's district: alive, in no hand but the town's, standing in its rect.
func counts_inside(job: GuardJobs.Job, p: Variant) -> bool:
	if not is_instance_valid(p):
		return false
	var s := p as Person
	return s.is_alive() and not s.held_by_god() and (job.data.rect as Rect2).has_point(s.ground_pos)


func may_take(_job: GuardJobs.Job, p: Person) -> bool:
	return p.corps == Person.Corps.NONE


func on_taken(job: GuardJobs.Job, p: Person) -> void:
	p.fearless_left = maxf(p.fearless_left, NERVE_SECONDS)
	if job.crew.size() >= job.need:
		_begin(job)


func still_on(_job: GuardJobs.Job, p: Person) -> bool:
	return p.mind == Person.Mind.POST


func on_taken_away(job: GuardJobs.Job, p: Person) -> void:
	_release(p)
	(job.data.at_spot as Dictionary).erase(p)
	if job.crew.is_empty():
		_stop(job)


func on_dropped(job: GuardJobs.Job, p: Person) -> void:
	on_taken_away(job, p)
	if p.is_alive() and (p.mind == Person.Mind.POST or p.held_by_god()) and not board.mission_man(p):
		p.back_to_post()


## Counts the clocks: an open job's wait, the 30 s, who is inside, the stage, the walk from door to door.
func tick(job: GuardJobs.Job, delta: float) -> void:
	var d: Dictionary = job.data
	if bool(d.over):
		return
	_drop_strays(job)
	if crowd.alarms.stage >= AlarmManager.Stage.EVACUATION:
		_finish(job)
		return
	if not bool(d.begun):
		d.wait = float(d.wait) - delta
		if float(d.wait) <= 0.0:
			_finish(job)
		return
	var inside := _any_inside(job)
	if not bool(d.on):
		d.on = inside
		d.idle = float(d.idle) - delta
		if not inside and float(d.idle) <= 0.0:
			_finish(job)  # nobody ever got into the district: the sweep ends without a word
			return
	else:
		d.left = float(d.left) - delta
		if float(d.left) <= 0.0:
			_finish(job)
			return
		if not inside:
			crowd.duty_event.emit(GuardJobs.Kind.SWEEP, BANNER_BROKEN, d.seen_at)
			_finish(job)
			return
	_walk(job, delta)


## Once a second: every sweep man keeps his nerve, and every begun sweep renews its men's badges.
func post_jobs() -> void:
	_settle()
	for job in _live:
		for m: Variant in job.crew:
			if is_instance_valid(m):
				var p: Person = m
				p.fearless_left = maxf(p.fearless_left, NERVE_SECONDS)
				if bool(job.data.begun) and not bool(job.data.over):
					p.set_badge(GuardJobs.GLYPH_EYE, COLOUR, BADGE_SECONDS)


func done(job: GuardJobs.Job) -> bool:
	return bool(job.data.over)


func tags(job: GuardJobs.Job) -> Array[MapTag]:
	var out: Array[MapTag] = []
	if bool(job.data.begun) and not bool(job.data.over) and not job.crew.is_empty() and is_instance_valid(job.crew[0]):
		out.append(MapTag.person(job.crew[0], COLOUR, "SWEEP %d" % ceili(float(job.data.left))))
	return out


func clear() -> void:
	_pending.clear()
	for job in _live.duplicate():
		_stop(job)
		for m: Variant in job.crew:
			if is_instance_valid(m):
				var p: Person = m
				_release(p)
				if p.is_alive() and not p.held_by_god() and not p.anchor.is_equal_approx(p.post):
					p.back_to_post()
	_live.clear()


## A seen power lands: a sweep hears of it, and the district is swept, when a man outside its danger saw it. When only men inside
## the danger did, they are remembered and tell the soldiers only if they come out of it alive (R21, see `_settle()`).
func _on_danger(_key: String, points: Array[Vector2], radius: float) -> void:
	if board == null or not board.is_open() or crowd.is_hushed() 			or (_live.is_empty() and crowd.alarms.stage >= AlarmManager.Stage.EVACUATION):
		return  # no sweep could follow and none live could hear it
	if points.is_empty():
		return
	var seen: Array[Vector2] = []
	var inside: Array[Person] = []
	var inside_at: Array[Vector2] = []
	if crowd.power_witness(points, radius, seen, inside, inside_at) != null:
		on_seen(seen[0])
		request(seen[0])
	elif not inside.is_empty():
		_pending.append({"people": inside, "at": inside_at, "points": points.duplicate(), "radius": radius, "born": board.clock})


## Settles every pending sighting once a board step: the dead and the freed are dropped; a man still alive who stands outside the
## radius of every point, or at whose point no danger is live any more, or any man alive once TELL_SECONDS have passed, tells the
## soldiers (the lowest stagger first) and the sighting is done; none left alive, it is dropped with no sweep.
func _settle() -> void:
	for i in range(_pending.size() - 1, -1, -1):
		var s := _pending[i]
		var people: Array[Person] = s.people
		var at: Array[Vector2] = s.at
		var over: bool = board.clock - float(s.born) > TELL_SECONDS
		var told := Vector2.INF
		var alive := false
		for k in range(people.size() - 1, -1, -1):
			if not is_instance_valid(people[k]) or not people[k].is_alive():
				people.remove_at(k)
				at.remove_at(k)
		for k in people.size():
			alive = true
			if over or _out_of_it(people[k], s.points, float(s.radius)) or danger_near(at[k]).is_empty():
				told = at[k]
				break
		if told != Vector2.INF:
			_pending.remove_at(i)
			on_seen(told)
			request(told)
		elif not alive:
			_pending.remove_at(i)


## Whether `p` stands outside the radius of every one of `points`.
func _out_of_it(p: Person, points: Array[Vector2], radius: float) -> bool:
	for at in points:
		if p.ground_pos.distance_to(at) <= radius:
			return false
	return true


## Drops the freed and the men whose record is no longer this job's from the crew.
func _drop_strays(job: GuardJobs.Job) -> void:
	for i in range(job.crew.size() - 1, -1, -1):
		var m: Variant = job.crew[i]
		if not is_instance_valid(m):
			job.crew.remove_at(i)
		elif board.job_of(m) != job:
			job.crew.remove_at(i)
			on_taken_away(job, m as Person)


## Takes every flag a sweep put on `p` off him (his nerve too, unless something else gave him more).
func _release(p: Person) -> void:
	if p.fearless_left <= NERVE_SECONDS:
		p.fearless_left = 0.0
	p.watch_far = false
	p.clear_badge()
	p.talk_left = 0.0
	p.stand_face = Vector2.INF


## Whether any crew man counts as inside the district.
func _any_inside(job: GuardJobs.Job) -> bool:
	for m: Variant in job.crew:
		if counts_inside(job, m):
			return true
	return false


## The crew is full: its doors are found, the men see far and are sent to the first door at a run.
func _begin(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	d.begun = true
	d.left = SWEEP_SECONDS
	var list := doors(d.district, d.seen_at)
	if list.is_empty():
		list.append(_snap(d.seen_at))
	d.doors = list
	d.door = 0
	for m: Variant in job.crew:
		var p: Person = m
		p.watch_far = true
		p.set_badge(GuardJobs.GLYPH_EYE, COLOUR, BADGE_SECONDS)
	_go(job)
	crowd.duty_event.emit(GuardJobs.Kind.SWEEP, BANNER, d.seen_at)
	if crowd.sfx != null and crowd.soldier_voices.order(crowd._clock):
		crowd.sfx.play(&"sol_order", (job.crew[0] as Person).ground_pos)


## Sends every free crew man to his spot round the current door (the first leg at a run).
func _go(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	var door: Vector2 = (d.doors as Array[Vector2])[d.door]
	var n := job.crew.size()
	for i in n:
		var p: Person = job.crew[i]
		p.talk_left = 0.0
		if p.held_by_god():
			continue
		var spot := _snap(door + Vector2(SPOT_APART * (float(i) - float(n - 1) * 0.5), 0.0))
		var danger := danger_near(door)
		if not danger.is_empty():
			spot = off_spot(danger, p.ground_pos)  # a live danger at the door: he stands off outside it
		d.at_spot[p] = spot
		p.send_to_post(spot, false, int(d.door) == 0)
	d.held = not danger_near(door).is_empty()
	d.phase = Phase.WALK
	d.leg = 0.0


## The walk: to a door, stand there SWEEP_STAND s talking, on to the next; after the last door wait at it.
func _walk(job: GuardJobs.Job, delta: float) -> void:
	var d: Dictionary = job.data
	if int(d.phase) != Phase.WAIT:
		# A door in a live danger is not walked to: the men stand off until it is over, then go (R19).
		var live := not danger_near((d.doors as Array[Vector2])[d.door]).is_empty()
		if live != bool(d.held):
			_go(job)
		if live:
			return
	match int(d.phase):
		Phase.WALK:
			d.leg = float(d.leg) + delta
			if _all_there(job) or float(d.leg) >= LEG_LIMIT:
				d.phase = Phase.STAND
				d.stand = SWEEP_STAND
				for m: Variant in job.crew:
					if is_instance_valid(m) and not (m as Person).held_by_god():
						(m as Person).talk_left = SWEEP_STAND
		Phase.STAND:
			d.stand = float(d.stand) - delta
			if float(d.stand) <= 0.0:
				if int(d.door) + 1 < (d.doors as Array).size():
					d.door = int(d.door) + 1
					_go(job)
				else:
					d.phase = Phase.WAIT


## Whether every living crew man the god does not hold is on his spot.
func _all_there(job: GuardJobs.Job) -> bool:
	for m: Variant in job.crew:
		if not is_instance_valid(m):
			continue
		var p: Person = m
		var at: Variant = job.data.at_spot.get(p)
		if p.is_alive() and not p.held_by_god() and at is Vector2 and p.ground_pos.distance_to(at) > Person.GOAL_REACH * 2.0:
			return false
	return true


## The sweep is over: every man goes back to his post.
func _finish(job: GuardJobs.Job) -> void:
	_stop(job)
	for i in range(job.crew.size() - 1, -1, -1):
		var m: Variant = job.crew[i]
		if is_instance_valid(m):
			board.drop(job, m as Person)
		else:
			job.crew.remove_at(i)


## The job is over at once (the board drops it at its next tick).
func _stop(job: GuardJobs.Job) -> void:
	job.data.over = true
	_live.erase(job)


## `at` on open ground (the shared rng is never drawn from).
func _snap(at: Vector2) -> Vector2:
	var s := crowd._grid.nearest_walkable(at)
	return at if s == Vector2.INF else s
