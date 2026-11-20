class_name CitadelGuard
extends Duty
## The Citadel guard (soldier duties, slice a1): at the call-up (Crowd.rally()) a guard of GUARD_SLOTS forms in still ranks round
## the Citadel, every mission man first, then the Citadel's own post group, then the nearest free guards; the rest of the
## Citadel's post group stands down to the barracks yard and the other soldiers keep the city. One CITADEL job on the board holds
## the guard; the board refills it from the free men (and, under GUARD_MIN, from men pulled off other jobs) while the Citadel
## stands. Nothing here draws a number from any rng.

## Slots in the guard (rank 0 front); more only for mission men, who stand in rear ranks.
const GUARD_SLOTS := 20
## Under this many the board may pull men off fires, piles and the like to fill the guard.
const GUARD_MIN := 15
## Distance between ranks, and between men along a side.
const RANK_STEP := 0.6
## The four sides, the south (the gateway) first.
const SIDES: Array[Vector2] = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]
## The banner at the call-up.
const BANNER := "THE CITADEL GUARD FORMS"

## The one CITADEL job (null before the call-up).
var job: GuardJobs.Job
## Person -> his slot index.
var _slot := {}
## Person -> true for every man assigned at the call-up itself.
var _answered := {}
## Person -> true for a director's man the guard took (he never leaves it).
var _mission := {}


## Slot `k` round `origin`: where he stands (unsnapped) and the way he faces.
static func slot_at(origin: Vector2, k: int) -> Dictionary:
	var side := SIDES[k % 4]
	var i := (k % GUARD_SLOTS) / 4
	var rank := k / GUARD_SLOTS
	var off := RANK_STEP * float((i + 1) / 2) * (1.0 if i % 2 == 1 else -1.0)
	var along := Vector2(-side.y, side.x)
	return {"at": origin + side * (Crowd.RING_RADIUS + RANK_STEP * float(rank)) + along * off, "face": side}


func kind() -> int:
	return GuardJobs.Kind.CITADEL


## Forms the guard (Crowd.rally()).
func call_up() -> void:
	if not board.is_open():
		return
	var origin := City.current().citadel_origin()
	job = board.post(GuardJobs.Kind.CITADEL, origin, GUARD_SLOTS)
	job.started = true
	_slot.clear()
	_answered.clear()
	_mission.clear()
	for p in crowd.soldiers:
		if _live(p, true) and board.mission_man(p):
			if board.on_job(p):
				board.pull(p)
			_mission[p] = true
			_join(p, _next_slot())
	for p in crowd.soldiers:
		if count() >= GUARD_SLOTS:
			break
		if _live(p) and p.post_group == 2 and not board.mission_man(p) and not job.crew.has(p):
			if board.on_job(p):
				if count() >= GUARD_MIN or not board.pullable(p):
					continue
				board.pull(p)
			_join(p, _nearest_slot(p.ground_pos))
	var left := {}
	for p in crowd.soldiers:
		if board.is_free(p):
			left[p.post_group] = int(left.get(p.post_group, 0)) + 1
	while count() < GUARD_SLOTS:
		var k := _next_slot()
		var at := _snap(slot_at(origin, k).at)
		var free: Array[Person] = []
		var pulls: Array[Person] = []
		for p in crowd.soldiers:
			if board.is_free(p):
				if int(left.get(p.post_group, 0)) - 1 >= GuardJobs.GROUP_KEEP:
					free.append(p)
			elif count() < GUARD_MIN and board.pullable(p):
				pulls.append(p)
		var pick: Person = _nearest(free, at)
		if pick != null:
			left[pick.post_group] = int(left[pick.post_group]) - 1
		elif count() < GUARD_MIN:
			pick = _nearest(pulls, at)
			if pick != null:
				board.pull(pick)
		if pick == null:
			break
		_join(pick, k)
	var town: Array[Person] = []
	for p in crowd.soldiers:
		if _live(p) and p.post_group == 2 and not board.mission_man(p) and not job.crew.has(p) \
				and (not board.on_job(p) or board.pullable(p)):
			town.append(p)
	var spots := crowd.yard_spots(town.size())
	var yard := City.current().landmark(&"barracks_yard").get_center()
	for i in town.size():
		var p := town[i]
		if board.on_job(p):
			board.pull(p)
		p.post = spots[i] if i < spots.size() else crowd._grid.nearest_walkable(yard)
		p.town_post = p.post
		p.post_group = 0
		p.send_to_post(p.post)


## His slot (snapped to open ground), INF when he is not a guard man.
func slot_of(p: Variant) -> Vector2:
	if not is_instance_valid(p) or not _slot.has(p):
		return Vector2.INF
	return _snap(slot_at(City.current().citadel_origin(), int(_slot[p])).at)


## Whether `p` stands in the guard: living, no corps, on the CITADEL job, marching or standing as a rallied man, and within
## Crowd.RING_REACH of his slot.
func on_slot(p: Variant) -> bool:
	if job == null or not is_instance_valid(p):
		return false
	var s := p as Person
	if s == null or not s.soldier or not s.is_alive() or s.corps != Person.Corps.NONE or s.mind != Person.Mind.RALLY:
		return false
	if board.job_of(s) != job:
		return false
	var at := slot_of(s)
	return at != Vector2.INF and s.ground_pos.distance_to(at) <= Crowd.RING_REACH


## The guard men, walking or standing.
func count() -> int:
	if job == null:
		return 0
	var n := 0
	for p in job.crew:
		if is_instance_valid(p) and p.is_alive():
			n += 1
	return n


## Whether `p` was assigned at the call-up itself (marked once, kept until clear()).
func answered(p: Variant) -> bool:
	return is_instance_valid(p) and _answered.has(p)


## Whether `p` is a director's man the guard took.
func is_mission(p: Variant) -> bool:
	return is_instance_valid(p) and _mission.has(p)


## The lowest empty slot below GUARD_SLOTS, -1 for none.
func free_slot() -> int:
	var k := _next_slot()
	return k if k < GUARD_SLOTS else -1


func target(j: GuardJobs.Job) -> Vector2:
	var k := free_slot()
	if k < 0:
		return j.at
	return _snap(slot_at(j.at, k).at)


func refills(_j: GuardJobs.Job) -> int:
	return GUARD_SLOTS - count()


func may_pull(_j: GuardJobs.Job) -> bool:
	return count() < GUARD_MIN


func on_taken(j: GuardJobs.Job, p: Person) -> void:
	if not _slot.has(p):
		_slot[p] = _next_slot()
	var s := slot_at(j.at, int(_slot[p]))
	p.send_to_post(_snap(s.at), true)
	p.stand_face = s.face


func on_dropped(_j: GuardJobs.Job, p: Person) -> void:
	_slot.erase(p)


func clear() -> void:
	job = null
	_slot.clear()
	_answered.clear()
	_mission.clear()


## Puts `p` in slot `k` of the guard.
func _join(p: Person, k: int) -> void:
	_slot[p] = k
	_answered[p] = true
	board.assign(job, p)


## A living soldier of no corps, out of doors (`any_place`: wherever he is).
func _live(p: Variant, any_place := false) -> bool:
	if not is_instance_valid(p):
		return false
	var s := p as Person
	return s != null and s.soldier and s.is_alive() and s.corps == Person.Corps.NONE and (any_place or not s.inside)


## The slots held by a valid, living man.
func _used() -> Dictionary:
	var used := {}
	for p in _slot:
		if is_instance_valid(p) and p.is_alive():
			used[_slot[p]] = true
	return used


## The lowest slot index nobody holds (no upper bound).
func _next_slot() -> int:
	var used := _used()
	var k := 0
	while used.has(k):
		k += 1
	return k


## The empty slot below GUARD_SLOTS nearest `from` (ties: the lowest).
func _nearest_slot(from: Vector2) -> int:
	var used := _used()
	var best := -1
	var best_d := INF
	for k in GUARD_SLOTS:
		if used.has(k):
			continue
		var d := _snap(slot_at(job.at, k).at).distance_to(from)
		if d < best_d:
			best = k
			best_d = d
	return best if best >= 0 else _next_slot()


## The nearest of `list` to `at` (ties by stagger), null for none.
func _nearest(list: Array[Person], at: Vector2) -> Person:
	var best: Person = null
	for p in list:
		if best == null:
			best = p
			continue
		var d := p.ground_pos.distance_to(at)
		var bd := best.ground_pos.distance_to(at)
		if d < bd or (d == bd and p.stagger < best.stagger):
			best = p
	return best


## `at` on open ground (the shared rng is never drawn from).
func _snap(at: Vector2) -> Vector2:
	var s := crowd._grid.nearest_walkable(at)
	return at if s == Vector2.INF else s
