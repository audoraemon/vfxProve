class_name ProcessionDirector
extends MissionDirector
## Act II-B of The Long Night (v0.09): the Procession. The Prince (a resident made a NOBLE) leaves the Citadel on foot
## for the ship at the dock, walking the route leg by leg, with ATTENDANTS residents about him and ESCORTS soldiers of
## the Citadel's guard closing round him. He never runs. A fright stops the walk (the escort closes in); once he is
## on his feet again he takes the route up where he left it, not home.

## The people about him: residents who walk with him, soldiers who guard him.
const ATTENDANTS := 6
const ESCORTS := 4
## How far round the Prince the escort stands (ESCORT_CLOSE while he is frightened) and the attendants walk, in ground units.
const ESCORT_R := 1.6
const ESCORT_CLOSE := 0.8
const ATTEND_R := 1.2
## Seconds between the director's looks at the party, and how near a leg's point counts as arrived.
const TICK := 0.5
const ARRIVE := 0.6
## An escort is re-sent only when its post has moved this far; an attendant when its place is this far off.
const ESCORT_MOVE := 0.3
const ATTEND_OFF := 0.5
## Minds the Prince is frightened in.
const FRIGHT := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]

var prince: Person
var attendants: Array[Person] = []
var escorts: Array[Person] = []
## The leg of the route he is walking to (an index into `route`).
var leg := 0
var route := PackedVector2Array()
## Set by the act's events: he has boarded the ship; nobody has seen him since the alarm; the act has been judged.
var boarded := false
var unseen := true
var judged := false
var _tick_in := 0.0


func _begin() -> void:
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	route = _route()
	prince = _appoint_prince()
	if prince == null:
		return
	_place(prince, route[0])
	_gather_attendants()
	_gather_escorts()


## The way to the ship, each point on walkable ground: out of the Citadel, the cathedral steps, the market's south
## side, the dock's waiting ground and the boarding point.
func _route() -> PackedVector2Array:
	var points := [
		Vector2(TownLayout.CITADEL_COURT.get_center().x, TownLayout.CITADEL_COURT.end.y + 0.6),
		Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.5),
		Vector2(TownLayout.MARKET_SQUARE.get_center().x, TownLayout.MARKET_SQUARE.end.y - 0.5),
		TownLayout.DOCK_WAIT.get_center(),
		Vector2(TownLayout.DOCK.get_center().x, TownLayout.DOCK.position.y - 0.4),
	]
	var out := PackedVector2Array()
	for at: Vector2 in points:
		out.append(_ground(at))
	return out


func _ground(at: Vector2) -> Vector2:
	var free := crowd._grid.nearest_walkable(at) if crowd._grid != null else at
	return free if free != Vector2.INF else at


## The resident nearest the Citadel is the Prince tonight. Null in a town with no resident to spare.
func _appoint_prince() -> Person:
	var pool := _residents()
	if pool.is_empty():
		return null
	var best := pool[0]
	best.profile.role = CitizenProfile.Role.NOBLE
	return best


## Living residents indoors or out of doors, nearest the Citadel first (the Prince, once made a NOBLE, is not one).
func _residents() -> Array[Person]:
	var pool: Array[Person] = []
	for p in crowd.citizens:
		if WarningDirector._alive(p) and p.profile != null and not p.inside \
				and p.profile.role == CitizenProfile.Role.RESIDENT:
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(TownLayout.CITADEL_ORIGIN) < b.ground_pos.distance_squared_to(TownLayout.CITADEL_ORIGIN))
	return pool


## A person set down at `at` before the first frame, with whatever walk the routine gave them dropped (as the Warning's
## watchman is), and kept there.
func _place(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p.anchor = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p.last_place = RoutineManager.Place.LEISURE
	p.stay_left = 1000.0


func _gather_attendants() -> void:
	for p in _residents().slice(0, ATTENDANTS):
		attendants.append(p)
		_place(p, _ring(prince.ground_pos, ATTEND_R, attendants.size() - 1, ATTENDANTS, 0.0))


## Soldiers with no corps from the Citadel's own posts (Crowd lays the soldiers out yard, walls, Citadel, patrols).
func _gather_escorts() -> void:
	var first := Crowd.POST_YARD + Crowd.POST_WALLS
	for i in range(first, mini(first + Crowd.POST_CITADEL, crowd.soldiers.size())):
		var s := crowd.soldiers[i]
		if escorts.size() < ESCORTS and WarningDirector._alive(s) and s.corps == Person.Corps.NONE:
			escorts.append(s)
			_send_escort(s, escorts.size() - 1)


## The `i`th of `n` places on a ring of `radius` round `center`, on walkable ground. `turn` offsets the ring.
func _ring(center: Vector2, radius: float, i: int, n: int, turn: float) -> Vector2:
	return _ground(center + Vector2.from_angle(turn + TAU * float(i) / float(n)) * radius)


func frightened() -> bool:
	return WarningDirector._alive(prince) and prince.mind in FRIGHT


func _send_escort(s: Person, i: int) -> void:
	var r := ESCORT_CLOSE if frightened() else ESCORT_R
	s.send_to_post(_ring(prince.ground_pos, r, i, ESCORTS, 0.5), false, true)


func step(delta: float) -> void:
	timeline.step(delta)
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	_tick()


## One look at the party. Nothing happens once the Prince is dead or missing: the act's objectives judge that.
func _tick() -> void:
	if not WarningDirector._alive(prince):
		return
	_walk()
	for i in escorts.size():
		var s := escorts[i]
		if not WarningDirector._alive(s):
			continue
		var r := ESCORT_CLOSE if frightened() else ESCORT_R
		var spot := _ring(prince.ground_pos, r, i, ESCORTS, 0.5)
		if s.anchor.distance_to(spot) > ESCORT_MOVE:
			s.send_to_post(spot, false, true)
	for i in attendants.size():
		var a := attendants[i]
		if not WarningDirector._alive(a) or not a.mind in WarningDirector.RESUMABLE:
			continue
		a.mind = Person.Mind.CALM
		a.stay_left = 1000.0
		var spot := _ring(prince.ground_pos, ATTEND_R, i, ATTENDANTS, 0.0)
		if a.anchor.distance_to(spot) > ATTEND_OFF or (not a.has_goal() and a.ground_pos.distance_to(spot) > ATTEND_OFF):
			a.walk_to(spot)


## The Prince's walk: in a calm mind he keeps to the route at a walk, taking the next leg on arriving at one. A fright
## drops his goal, so on coming round (RECOVER) he sets out for the leg he was on.
func _walk() -> void:
	if not prince.mind in WarningDirector.RESUMABLE:
		return
	var resumed := prince.mind != Person.Mind.CALM
	prince.mind = Person.Mind.CALM
	prince.stay_left = 1000.0
	var at := route[leg]
	if not resumed and not prince.has_goal() and prince.ground_pos.distance_to(at) <= ARRIVE:
		if leg >= route.size() - 1:
			return  # at the boarding point: nowhere further to walk
		leg += 1
		at = route[leg]
		resumed = true
	if resumed or not prince.has_goal():
		prince.walk_to(at)
