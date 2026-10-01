class_name RiverFerry
extends RefCounted
## The river boats (v0.05): from the Evacuation stage the ship moored at the dock ferries people away -- a third way
## out besides the two roads. Evacuees who choose the dock (EvacuationManager scores it like a gate, by the route
## there and the crowd already waiting) wait on the bank in a crowd that forms behind the pier; the one at its head
## steps aboard every LOAD_TIME / LOAD seconds. Full -- or LOAD_TIME after the first stepped aboard with nobody left
## waiting -- the ship sails: everyone aboard has escaped, and it is back TRIP seconds later. A destroyed dock stops the service until the
## engineers rebuild it; a blighted one ends it for good. Either way those still waiting go for the gates. Only towns
## whose profile has boats run one.

signal opened
signal sailed(count: int)
signal closed(reason: String)

## MOORED until the Evacuation stage; CLOSED while the dock lies destroyed; ENDED for good.
enum State { MOORED, LOADING, AWAY, CLOSED, ENDED }

const LOAD := 6
const LOAD_TIME := 4.0
const TRIP := 12.0
## How near its place at the head of the crowd someone must be to step aboard.
const BOARD_REACH := 0.35
## How far from the pier an evacuee bound for it joins the waiting crowd, and how far apart the waiting stand.
const WAIT_REACH := 4.0
const SPACING := 0.34
## The ship's trip, as drawn: it slips this far downriver (west) as it fades out, and back as it returns.
const SAIL := 3.0
const FADE := 0.2

var state := State.MOORED
var dock: Structure
## Where people step aboard: the pier's end beside the ship. EvacuationManager's boat exit.
var board_at := Vector2.INF
## The waiting crowd's places, the pier's end first, then back along the pier and the bank behind it.
var spots: Array[Vector2] = []
var aboard: Array[Person] = []
var trips := 0
var carried := 0
var ship: Decor
var _ship_home := Vector2.ZERO
var _board_in := 0.0
## Seconds since the first passenger of this load stepped aboard (-1: nobody yet).
var _loading := -1.0
var _away := 0.0
## Waiting now (refreshed each step), for EvacuationManager's score.
var _waiting: Array[Person] = []
var _crowd: Crowd
var _field: EnemyField


func setup(crowd: Crowd, env: EnvironmentField, grid: WalkGrid, field: EnemyField) -> RiverFerry:
	_crowd = crowd
	_field = field
	for s in env.structures():
		if s.role == &"dock":
			dock = s
			break
	for d in env.decor():
		if d.kind == Decor.Kind.SHIP:
			ship = d
			_ship_home = d.at
			break
	if dock != null:
		var r := dock.footprint
		var end := Vector2(r.get_center().x, r.end.y - 0.3)
		board_at = end if grid.walkable(end) else grid.nearest_walkable(end, 2)
		spots = _spots(grid, r)
	if not crowd.profile.boats or dock == null or board_at == Vector2.INF:
		state = State.ENDED
	return self


## The pier's end, back along the pier, then rows across the bank behind it, nearest the pier's root first.
func _spots(grid: WalkGrid, r: Rect2) -> Array[Vector2]:
	var out: Array[Vector2] = [board_at]
	var root := Vector2(r.get_center().x, r.position.y)
	var along := board_at.y - SPACING
	while along > root.y:
		var g := Vector2(board_at.x, along)
		if grid.walkable(g):
			out.append(g)
		along -= SPACING
	var bank: Array[Vector2] = []
	var w := TownLayout.DOCK_WAIT
	var y := r.position.y - 0.25
	while y > w.position.y:
		var x := w.position.x + 0.2
		while x < w.end.x - 0.1:
			var g := Vector2(x, y)
			if grid.walkable(g):
				bank.append(g)
			x += SPACING
		y -= SPACING * 0.87
	bank.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(root) < b.distance_squared_to(root))
	out.append_array(bank)
	return out


## The Evacuation stage: the ship takes on passengers.
func begin() -> void:
	if state != State.MOORED:
		return
	if not _dock_ok():
		_stop()
		return
	_open()


func _open() -> void:
	state = State.LOADING
	_loading = -1.0
	opened.emit()


## Is the dock a way out right now (in service, even while the ship is away)?
func open() -> bool:
	return state == State.LOADING or state == State.AWAY


func waiting() -> int:
	return _waiting.size()


func _dock_ok() -> bool:
	return is_instance_valid(dock) and not dock.destroyed and not dock.blighted


func step(delta: float) -> void:
	if state == State.AWAY:
		_away -= delta
		if _away <= 0.0:
			state = State.LOADING
			_loading = -1.0
	_draw_ship()
	if state == State.CLOSED and _dock_ok():
		_open()  # rebuilt
	if not open():
		return
	if not _dock_ok():
		if not aboard.is_empty():
			_sail()  # the ship casts off with whoever is aboard
		_stop()
		return
	_queue()
	if state != State.LOADING:
		return
	_board_in -= delta
	if _loading >= 0.0:
		_loading += delta
	if _board_in <= 0.0 and aboard.size() < LOAD and not _waiting.is_empty():
		var head := _waiting[0]
		if head.queue_spot == spots[0] and head.ground_pos.distance_to(board_at) <= BOARD_REACH:
			_board(head)
			# Marshals at the dock (v0.07) see them aboard faster.
			var speed := _crowd.marshals.speed_at(board_at) if _crowd.marshals != null else 1.0
			_board_in = LOAD_TIME / float(LOAD) / speed
	if aboard.size() >= LOAD or (_loading >= LOAD_TIME and not aboard.is_empty() and _waiting.is_empty()):
		_sail()


## The waiting crowd: evacuees bound for the dock and near it, in the order they came, each given its place.
func _queue() -> void:
	var here: Array[Person] = []
	for p in _crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.mind == Person.Mind.FLEE \
				and p.goal() == board_at and p.ground_pos.distance_to(board_at) <= WAIT_REACH:
			here.append(p)
	here.sort_custom(func(a: Person, b: Person) -> bool:
		if a.queue_since < 0.0 and b.queue_since < 0.0:
			return a.ground_pos.distance_squared_to(board_at) < b.ground_pos.distance_squared_to(board_at)
		if a.queue_since < 0.0 or b.queue_since < 0.0:
			return b.queue_since < 0.0
		if not is_equal_approx(a.queue_since, b.queue_since):
			return a.queue_since < b.queue_since
		return a.stagger_key() < b.stagger_key())
	for i in here.size():
		var p := here[i]
		if p.queue_since < 0.0:
			p.queue_since = _crowd._clock
		p.queue_spot = spots[mini(i, spots.size() - 1)]
	_waiting = here


func _board(p: Person) -> void:
	p.release_from_queue()
	p.inside = true
	p.visible = false
	p.ground_pos = board_at
	_field.remove(p)
	_waiting.erase(p)
	aboard.append(p)
	if _loading < 0.0:
		_loading = 0.0


## Cast off: everyone aboard has got away.
func _sail() -> void:
	trips += 1
	var n := 0
	for p in aboard:
		if is_instance_valid(p):
			_crowd.escape(p)
			n += 1
	carried += n
	aboard.clear()
	_loading = -1.0
	state = State.AWAY
	_away = TRIP
	sailed.emit(n)


## The dock is gone: closed until it is rebuilt, or ended if blighted. The waiting crowd makes for the gates.
func _stop() -> void:
	var was_open := open()
	var blighted := is_instance_valid(dock) and dock.blighted
	state = State.ENDED if blighted or not is_instance_valid(dock) else State.CLOSED
	for p in _waiting:
		if is_instance_valid(p) and p.is_alive():
			p.release_from_queue()
			p.replan()
	_waiting.clear()
	if was_open:
		closed.emit("the dock is sunk" if blighted else "the dock is destroyed")


## The ship on its trip: it slips downriver as it fades out, is gone, and fades back in as it returns.
func _draw_ship() -> void:
	if not is_instance_valid(ship):
		return
	var off := 0.0
	var alpha := 1.0
	if state == State.AWAY:
		var k := 1.0 - _away / TRIP
		if k < FADE:
			off = SAIL * k / FADE
			alpha = 1.0 - k / FADE
		elif k > 1.0 - FADE:
			off = SAIL * (1.0 - k) / FADE
			alpha = (k - (1.0 - FADE)) / FADE
		else:
			off = SAIL
			alpha = 0.0
	var at := _ship_home - Vector2(off, 0.0)
	if ship.at != at:
		ship.at = at
		ship.position = Iso.ground_to_screen(at)
	ship.visible = alpha > 0.0
	ship.modulate.a = alpha
