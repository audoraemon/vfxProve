class_name CorpseDuty
extends Duty
## Corpse duty (soldier duties, slice b): a street beat pair that sees a whole body (the Remains ledger) within CORPSE_NOTICE
## goes to it, the nearer man crouching over it for INSPECT seconds while the other stands off facing out; then it is found:
## the district's incident, the alarm the kill never gave, a banner. They lift it and carry it to open ground off the street,
## lay it down and go back to their beat. A held, dead, fighting, pulled or taken man ends the job before the find; a carrier
## held or killed drops the body where he stands. Nothing here draws a number from any rng.

## How far a beat man sees a body (scaled by the light, cut by Decree's NO SIGHT).
const CORPSE_NOTICE := 4.0
## Seconds the inspector looks before it is found.
const INSPECT := 4.0
## How far from where it lay the body is carried to open ground.
const CARRY_REACH := 4.0
## The watcher stands this far past the body, facing out.
const WATCH_OFF := 0.8
## Seconds the TAKEN tag shows after the lift.
const TAKEN_SHOW := 2.0
## The banner at the find.
const BANNER := "A BODY IS FOUND"
## The tags' colour.
const COLOUR := Color(0.86, 0.72, 0.4)
## The two carriers walk this far apart across their way.
const CARRIER_APART := 0.25
## Seconds a pair may spend walking (to the body, then with it) before the job gives up.
const WALK_LIMIT := 40.0
## The phases of a job (job.data.phase). `data.carrying` is true in CARRY and LAY (GuardJobs.pullable() reads it).
enum { WALK, INSPECT_PHASE, CARRY, LAY }

## Person -> true for each man who crouches now (so a restart stands them up).
var _crouched := {}


func kind() -> int:
	return GuardJobs.Kind.CORPSE


## Whether some corpse job (open or running) is on `r`.
func assigned(r: Remains.Remain) -> bool:
	for job in board.jobs:
		if job.kind == GuardJobs.Kind.CORPSE and job.data.remain == r:
			return true
	return false


## Whole seconds until the body is found (0 once it is): the inspector's walk to it plus the look still to do.
func found_in(job: GuardJobs.Job) -> int:
	var d: Dictionary = job.data
	if int(d.phase) >= CARRY:
		return 0
	var insp: Person = d.inspector
	var r: Remains.Remain = d.remain
	return ceili(insp.ground_pos.distance_to(r.pos) / maxf(insp.walk_speed, 0.1) + float(d.left))


## Once a second: each beat pair standing free that sees an unhidden, unassigned body gets a job on it (one body per pair, one
## pair per body).
func post_jobs() -> void:
	var ledger := crowd.remains
	if ledger == null or not ledger.enabled:
		return
	var pairs := {}
	for e in crowd._beats:
		if is_instance_valid(e[0]):
			var men: Array = pairs.get(e[3], [])
			men.append(e[0])
			pairs[e[3]] = men
	for k in pairs:
		var men: Array = pairs[k]
		if men.size() != 2 or not board.is_free(men[0]) or not board.is_free(men[1]) or _named(men[0]) or _named(men[1]):
			continue
		var r := _seen_by(men)
		if r == null:
			continue
		board.post(GuardJobs.Kind.CORPSE, r.pos, 2, INF, {"remain": r, "pair": men, "phase": WALK, "carrying": false,
				"begun": false, "over": false, "left": INSPECT, "walk_left": WALK_LIMIT, "taken_left": 0.0, "fade_left": 0.0,
				"inspector": null, "watcher": null, "spot": Vector2.INF, "to": Vector2.INF, "carry_spots": []})


func may_take(job: GuardJobs.Job, p: Person) -> bool:
	return job.data.pair.has(p)


func on_taken(job: GuardJobs.Job, _p: Person) -> void:
	if job.crew.size() >= job.need:
		_begin(job)


func still_on(_job: GuardJobs.Job, p: Person) -> bool:
	return p.mind == Person.Mind.POST


func on_dropped(job: GuardJobs.Job, p: Person) -> void:
	var d: Dictionary = job.data
	p.crouching = false
	p.stand_face = Vector2.INF
	_crouched.erase(p)
	if bool(d.begun) and not bool(d.over):
		# He left a running job (dead, fighting, pulled, taken): it is over, and a body in the air falls where they are.
		if int(d.phase) == CARRY:
			_put_back(job)
		d.over = true
	if p.is_alive() and (p.mind == Person.Mind.POST or p.held_by_god()) and not board.mission_man(p):
		p.back_to_post()


func tick(job: GuardJobs.Job, delta: float) -> void:
	var d: Dictionary = job.data
	if not bool(d.begun):
		return
	if bool(d.over):
		for p in job.crew.duplicate():
			board.drop(job, p)
		return
	if int(d.phase) >= CARRY:
		d.taken_left = maxf(float(d.taken_left) - delta, 0.0)
	match int(d.phase):
		WALK, INSPECT_PHASE:
			_look(job, delta)
		CARRY:
			_carry(job, delta)
		LAY:
			d.fade_left = float(d.fade_left) - delta
			if float(d.fade_left) <= 0.0 and float(d.taken_left) <= 0.0:
				_end(job)


func done(job: GuardJobs.Job) -> bool:
	var d: Dictionary = job.data
	if bool(d.over):
		return true
	if job.started:
		return false
	var r: Remains.Remain = d.remain
	if not crowd.remains.holds(r) or r.hidden:
		return true
	for p in d.pair:
		if not is_instance_valid(p) or not p.is_alive():
			return true
	return false


func tags(job: GuardJobs.Job) -> Array[MapTag]:
	var out: Array[MapTag] = []
	var d: Dictionary = job.data
	if not bool(d.begun) or bool(d.over):
		return out
	var r: Remains.Remain = d.remain
	if int(d.phase) < CARRY:
		out.append(MapTag.place(r.pos, COLOUR, "FOUND IN %d" % found_in(job)))
	elif float(d.taken_left) > 0.0:
		out.append(MapTag.place(r.pos, COLOUR, "TAKEN"))
	return out


## The body drawn between its carriers, fading as it is laid down.
func draw(canvas: Node2D) -> void:
	if not SpriteArt.on() or not PeopleArt.ready():
		return
	for job in board.live(GuardJobs.Kind.CORPSE):
		var d: Dictionary = job.data
		if not _shown(job):
			continue
		var r: Remains.Remain = d.remain
		if not PeopleArt.has(r.design):
			continue
		var info := PeopleArt.info(r.design)
		var row := 4 * 4 + r.facing  # the "death" animation's row
		var n: int = info[4][row]
		var cell: Vector2 = info[3]
		var foot: Vector2 = info[2]
		var src := Rect2(info[0] + Vector2((n - 1) * cell.x, row * cell.y), cell)
		var alpha := 1.0 if int(d.phase) == CARRY else clampf(float(d.fade_left) / DummyEnemy.DEATH_FADE, 0.0, 1.0)
		canvas.draw_texture_rect_region(PeopleArt.atlas(), Rect2(Iso.ground_to_screen(_mid(job)) - foot, cell), src,
				Color(1.0, 1.0, 1.0, alpha))


func showing() -> bool:
	for job in board.live(GuardJobs.Kind.CORPSE):
		if _shown(job):
			return true
	return false


func clear() -> void:
	for p in _crouched:
		if is_instance_valid(p):
			p.crouching = false
	_crouched.clear()


## Whether the body of `job` is in the carriers' hands or being laid down.
func _shown(job: GuardJobs.Job) -> bool:
	var d: Dictionary = job.data
	return bool(d.begun) and not bool(d.over) and int(d.phase) >= CARRY


## Whether an open or running job already names `p`.
func _named(p: Person) -> bool:
	for job in board.jobs:
		if job.kind == GuardJobs.Kind.CORPSE and job.data.pair.has(p):
			return true
	return false


## The first body either man of `men` sees: unhidden, on no job, not under a veil, within his sight.
func _seen_by(men: Array) -> Remains.Remain:
	var reach := CORPSE_NOTICE * crowd.sight_scale
	for m: Person in men:
		for r in crowd.remains.near(m.ground_pos, reach):
			if not assigned(r) and m.ground_pos.distance_to(r.pos) <= crowd.sight(m, r.pos, reach) and not crowd.is_veiled(r.pos):
				return r
	return null


## The pair is whole: the nearer man goes to crouch over the body, the other stands off past it, facing out.
func _begin(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	var r: Remains.Remain = d.remain
	var a: Person = job.crew[0]
	var b: Person = job.crew[1]
	var da := a.ground_pos.distance_to(r.pos)
	var db := b.ground_pos.distance_to(r.pos)
	var insp := a if da < db or (da == db and a.stagger <= b.stagger) else b
	var watch := b if insp == a else a
	var out := (r.pos - insp.ground_pos).normalized()
	if out == Vector2.ZERO:
		out = Vector2.DOWN
	var spot := _snap(r.pos)
	insp.send_to_post(spot)
	var toward := r.pos - spot
	insp.stand_face = toward.normalized() if toward.length() > 0.05 else -out
	watch.send_to_post(_snap(r.pos + out * WATCH_OFF))
	watch.stand_face = out
	d.inspector = insp
	d.watcher = watch
	d.spot = spot
	d.begun = true


## Walking to the body, then looking at it: the clock runs only while the inspector stands at his spot.
func _look(job: GuardJobs.Job, delta: float) -> void:
	var d: Dictionary = job.data
	var insp: Person = d.inspector
	var watch: Person = d.watcher
	var r: Remains.Remain = d.remain
	if insp.held_by_god() or watch.held_by_god() or not crowd.remains.holds(r) or r.hidden:
		_end(job)
		return
	if insp.ground_pos.distance_to(d.spot) <= Person.GOAL_REACH * 2.0:
		d.phase = INSPECT_PHASE
		insp.crouching = true
		_crouched[insp] = true
		d.left = float(d.left) - delta
		if float(d.left) <= 0.000001:
			_found(job)
		return
	insp.crouching = false
	d.walk_left = float(d.walk_left) - delta
	if float(d.walk_left) <= 0.0:
		_end(job)


## The find: the district's incident (a sweep if it tipped the district into emergency), the alarm the kill never gave, the
## banner; then the body is lifted and the pair sets off with it.
func _found(job: GuardJobs.Job) -> void:
	var d: Dictionary = job.data
	var r: Remains.Remain = d.remain
	var insp: Person = d.inspector
	insp.crouching = false
	_crouched.erase(insp)
	if crowd.alarms.incident(r.pos):
		crowd._investigate(r.pos)
	if not r.counted:
		crowd._hear_alarm(Crowd.ALARM_KILL)
	crowd.duty_event.emit(GuardJobs.Kind.CORPSE, BANNER, r.pos)
	crowd.remains.take(r)
	var to := _lay_spot(r.pos)
	var dir := to - r.pos
	var across := dir.orthogonal().normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var spots: Array[Vector2] = []
	for i in job.crew.size():
		var side := CARRIER_APART if i == 0 else -CARRIER_APART
		var at := _snap(to + across * side)
		spots.append(at)
		(job.crew[i] as Person).send_to_post(at)
	d.to = to
	d.carry_spots = spots
	d.phase = CARRY
	d.carrying = true
	d.taken_left = TAKEN_SHOW
	d.walk_left = WALK_LIMIT


## Carrying: a held carrier drops the body where they are; both at their spots (or too long on the way) lay it down.
func _carry(job: GuardJobs.Job, delta: float) -> void:
	var d: Dictionary = job.data
	var insp: Person = d.inspector
	var watch: Person = d.watcher
	if insp.held_by_god() or watch.held_by_god():
		_put_back(job)
		_end(job)
		return
	d.walk_left = float(d.walk_left) - delta
	var there := true
	for i in job.crew.size():
		there = there and (job.crew[i] as Person).ground_pos.distance_to(d.carry_spots[i]) <= Person.GOAL_REACH * 2.0
	if there or float(d.walk_left) <= 0.0:
		d.phase = LAY
		d.fade_left = DummyEnemy.DEATH_FADE


## Ends the job now: every man goes back to his post.
func _end(job: GuardJobs.Job) -> void:
	job.data.over = true
	for p in job.crew.duplicate():
		board.drop(job, p)


## Puts a body that was in the air back on the ledger where the carriers are, its clock fresh.
func _put_back(job: GuardJobs.Job) -> void:
	var r: Remains.Remain = job.data.remain
	crowd.remains.move(r, _mid(job), false)


## The midpoint of the two men (of the one left, if the other is gone).
func _mid(job: GuardJobs.Job) -> Vector2:
	var at := Vector2.ZERO
	var n := 0
	for p in [job.data.inspector, job.data.watcher]:
		if is_instance_valid(p):
			at += (p as Person).ground_pos
			n += 1
	return at / float(n) if n > 0 else (job.data.remain as Remains.Remain).pos


## The open cell centre nearest `at` within CARRY_REACH that is on no road (ties: the lowest y, then x), else `at` itself.
func _lay_spot(at: Vector2) -> Vector2:
	var grid := crowd._grid
	var roads: Array = City.current().roads()
	var c := grid.world_to_id(at)
	var n := ceili(CARRY_REACH / WalkGrid.CELL)
	var best := at
	var best_d := INF
	for y in range(c.y - n, c.y + n + 1):
		for x in range(c.x - n, c.x + n + 1):
			var g := grid.id_to_world(Vector2i(x, y))
			var d := g.distance_to(at)
			if d > CARRY_REACH or d >= best_d or not grid.walkable(g):
				continue
			var on_road := false
			for road: Rect2 in roads:
				if road.has_point(g):
					on_road = true
					break
			if not on_road:
				best = g
				best_d = d
	return best


## `at` on open ground (the shared rng is never drawn from).
func _snap(at: Vector2) -> Vector2:
	var s := crowd._grid.nearest_walkable(at)
	return at if s == Vector2.INF else s
