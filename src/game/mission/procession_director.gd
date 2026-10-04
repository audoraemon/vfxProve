class_name ProcessionDirector
extends MissionDirector
## Act II-B of The Long Night (v0.09): the Procession. The Prince (a resident made a NOBLE) leaves the Citadel on foot
## for the ship at the dock, walking the route leg by leg, with ATTENDANTS residents about him and ESCORTS soldiers of
## the Citadel's guard closing round him. He never runs. A fright stops the walk (the escort closes in); once he is
## on his feet again he takes the route up where he left it, not home.
##
## The act's windows: he holds at the cathedral steps for the blessing (BLESSING_AT), waits at the dock for the ship
## (SHIP_AT) and then boards it -- which loses the act. The clock (TIDE_AT) ends it. His death is judged as the Warning's
## messenger's is: seen or unseen, once the cast's other victims have fallen.

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

## The act's windows, in seconds from its start. The blessing: the Prince holds at the cathedral steps (leg STEPS_LEG)
## from BLESSING_AT for BLESSING_SECONDS, and up to ONLOOKERS calm citizens within ONLOOK_R of the steps watch it
## (ONLOOK_SECONDS). The ship docks at SHIP_AT: he waits at the dock's waiting ground (leg DOCK_LEG) until then. The last
## tide, TIDE_AT, is the act's clock.
const BLESSING_AT := 60.0
const BLESSING_SECONDS := 20.0
const ONLOOKERS := 10
const ONLOOK_R := 8.0
const ONLOOK_SECONDS := 20.0
const SHIP_AT := 120.0
const TIDE_AT := 150.0
const STEPS_LEG := 1
const DOCK_LEG := 3

var prince: Person
var attendants: Array[Person] = []
var escorts: Array[Person] = []
## The leg of the route he is walking to (an index into `route`).
var leg := 0
var route := PackedVector2Array()
## Set by the act's events: he has got away (boarded the ship, or any other way out of the town); nobody has seen him since the alarm; the act has been judged.
var boarded := false
var unseen := true
var judged := false
## The power credited with his death (a key; "" for none).
var killed_by := ""
## The citizens called to watch the blessing.
var onlookers: Array[Person] = []
var _tick_in := 0.0
## Where he fell, waiting to be judged once the cast's other victims have fallen too.
var _fell_at := Vector2.INF
## He was killed (not merely gone: boarding, or reaching an exit while fleeing, is his escape).
var _dead := false


func _begin() -> void:
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	route = _route()
	# His events are dropped (and left off the strip) once he is dead, boarded, or if the town had nobody to be him.
	var travelling := func() -> bool: return WarningDirector._alive(prince) and not boarded
	timeline.add(BLESSING_AT, "blessing", "The blessing", _bless, travelling)
	timeline.add(SHIP_AT, "ship", "The ship docks", Callable(), travelling)
	timeline.add(TIDE_AT, "tide", "The last tide", Callable(), travelling)
	prince = _appoint_prince()
	if prince == null:
		return
	crowd.escaped.connect(_on_escaped)
	crowd._field.enemy_killed.connect(_on_killed)
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


## The `i`th escort's post: on a ring round the Prince, closer while he is frightened.
func _escort_spot(i: int) -> Vector2:
	var r := ESCORT_CLOSE if frightened() else ESCORT_R
	return _ring(prince.ground_pos, r, i, ESCORTS, 0.5)


func _send_escort(s: Person, i: int) -> void:
	s.send_to_post(_escort_spot(i), false, true)


func step(delta: float) -> void:
	timeline.step(delta)
	# Judged once the crowd has judged its own doomed (Crowd._settle_doom()), so a cast's victims never witness each other.
	if _fell_at != Vector2.INF and crowd._doomed.is_empty():
		_judge()
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
		var spot := _escort_spot(i)
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


## The Prince's walk: in a calm mind he keeps to the route at a walk, taking the next leg on arriving at one -- but not
## before the blessing is over at the steps, nor before the ship has docked at the waiting ground; at the boarding point
## he boards. A fright drops his goal, so on coming round (RECOVER) he sets out for the leg he was on.
func _walk() -> void:
	if not prince.mind in WarningDirector.RESUMABLE:
		return
	var resumed := prince.mind != Person.Mind.CALM
	prince.mind = Person.Mind.CALM
	prince.stay_left = 1000.0
	var at := route[leg]
	if not resumed and not prince.has_goal() and prince.ground_pos.distance_to(at) <= ARRIVE:
		if leg >= route.size() - 1:
			_board()  # at the boarding point: nowhere further to walk
			return
		if timeline.elapsed() < _hold_until(leg):
			return  # waits here for the blessing, or the ship
		leg += 1
		at = route[leg]
		resumed = true
	if resumed or not prince.has_goal():
		prince.walk_to(at)


## When the Prince may leave leg `at`: the end of the blessing at the steps, the ship's docking at the waiting ground, else
## at once.
func _hold_until(at: int) -> float:
	match at:
		STEPS_LEG:
			return BLESSING_AT + BLESSING_SECONDS
		DOCK_LEG:
			return SHIP_AT
	return 0.0


## The blessing: the calm citizens nearest the steps turn to watch it (the Prince's own party stays with him).
func _bless() -> void:
	var steps := route[STEPS_LEG]
	var pool: Array[Person] = []
	for p in crowd.citizens:
		if WarningDirector._alive(p) and not p.inside and p.mind == Person.Mind.CALM and p != prince \
				and not attendants.has(p) and p.ground_pos.distance_to(steps) <= ONLOOK_R:
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(steps) < b.ground_pos.distance_squared_to(steps))
	for p in pool.slice(0, ONLOOKERS):
		onlookers.append(p)
		p.observe(steps, ONLOOK_SECONDS)


## He steps aboard: out of the town by the escape path, which counts for Act II's escapes (Rules.escaped_this_act()).
func _board() -> void:
	if boarded or timeline.elapsed() < SHIP_AT:
		return
	boarded = true
	crowd._field.remove(prince)
	crowd.escape(prince)


func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if e == prince and not _dead:
		_dead = true
		_fell_at = e.ground_pos
		killed_by = rules.credited_key(kind)


## However he left the town (the ship, a river boat, an exit he fled to), he has got away.
func _on_escaped(p: Person) -> void:
	if p == prince:
		boarded = true


## Judged after the death: nobody living near enough to see it (Crowd.nearest_witness) and it was unseen.
func _judge() -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	unseen = crowd.nearest_witness(at) == null
	judged = true


## He was killed.
func fallen() -> bool:
	return _dead


## How the Prince's night ended, for the night's carry-over: "unseen" or "seen" for a death, else "escaped" (boarded, or
## alive when the act ended).
func report() -> Dictionary:
	if not fallen():
		return {"prince": "escaped"}
	return {"prince": "unseen" if unseen else "seen"}


func teardown() -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	if is_instance_valid(crowd) and crowd.escaped.is_connected(_on_escaped):
		crowd.escaped.disconnect(_on_escaped)
