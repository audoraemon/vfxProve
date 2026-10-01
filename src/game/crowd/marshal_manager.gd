class_name MarshalManager
extends RefCounted
## Marshals (v0.07): at the Evacuation stage the soldiers from the walls take the ways out -- the profile's
## marshals_per_exit at the Main Gate, the Side Gate and, in a town with boats, the postern and the dock -- standing
## either side of the crowd's head. Each way out takes the nearest of the marshals not yet posted. Each living marshal within REACH of a way out makes it SPEED faster (speed_at(): a
## gate lets the next one through sooner, the boat takes them aboard sooner), and a confused evacuee near one is
## brought round within STEADY_TIME. Kill them or knock them away and the way out slows again.

signal posted

## How close to a way out's mouth a marshal must stand to speed it up.
const REACH := 2.0
## How much faster each marshal at a way out makes it (a fraction of its normal rate).
const SPEED := 0.15
## How near a marshal a confused evacuee must be to be steadied.
const STEADY_R := 3.0
## The longest a steadied evacuee stays confused.
const STEADY_TIME := 3.0
## How often the confused near a marshal are checked.
const STEADY_EVERY := 0.5
## How far either side of a way out's mouth the first marshals stand, how much farther each next pair, and how far
## back from the mouth.
const FLANK := 0.9
const FLANK_STEP := 0.45
const BACK := 0.4

var active := false
## A way out's mouth -> the marshals posted there.
var posts := {}
var _crowd: Crowd
var _town: Town
var _grid: WalkGrid
var _steady_in := 0.0


func setup(crowd: Crowd, town: Town, grid: WalkGrid) -> MarshalManager:
	_crowd = crowd
	_town = town
	_grid = grid
	return self


## The ways out, each [mouth, outward]: every open gate's mouth (where Crowd queues its crowd), and the dock's
## boarding point while the boats can run.
func exits() -> Array:
	var out := []
	for g in _town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			var o := Crowd.outward_of(g)
			out.append([g.center() - o * (absf(g.footprint.size.dot(o)) * 0.5 + Crowd.GATE_DOOR), o])
	if _crowd.ferry != null and _crowd.ferry.state != RiverFerry.State.ENDED and _crowd.ferry.board_at != Vector2.INF:
		out.append([_crowd.ferry.board_at, Vector2(0, 1)])
	return out


## The Evacuation stage: the marshals leave the walls for the ways out, each taking the `marshals_per_exit` nearest
## of those not yet posted. `posted` is emitted only if at least one marshal was sent.
func begin() -> void:
	if active:
		return
	active = true
	var pool: Array[Person] = []
	for p in _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL:
			pool.append(p)
	var per := _crowd.profile.marshals_per_exit
	var sent := 0
	for e in exits():
		var mouth: Vector2 = e[0]
		var out_dir: Vector2 = e[1]
		var side := Vector2(-out_dir.y, out_dir.x)
		var mine: Array = []
		pool.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_squared_to(mouth) < b.ground_pos.distance_squared_to(mouth))
		for j in per:
			if pool.is_empty():
				break
			var p: Person = pool.pop_front()
			var sgn := -1.0 if j % 2 == 0 else 1.0
			var spot := mouth - out_dir * BACK + side * sgn * (FLANK + FLANK_STEP * float(j / 2))
			if not _grid.walkable(spot):
				var near := _grid.nearest_walkable(spot, 3)
				spot = near if near != Vector2.INF else mouth
			p.send_to_post(spot)
			mine.append(p)
			sent += 1
		posts[mouth] = mine
	if sent > 0:
		posted.emit()


## How much faster the way out at `mouth` runs: 1 + SPEED for each living marshal within REACH of it, once the
## evacuation has begun (before it, the marshals are only soldiers on the walls, and nothing is faster).
func speed_at(mouth: Vector2) -> float:
	if not active:
		return 1.0
	var n := 0
	for p in _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL \
				and p.ground_pos.distance_to(mouth) <= REACH:
			n += 1
	return 1.0 + SPEED * float(n)


## Confused evacuees near a marshal come to within STEADY_TIME.
func step(delta: float) -> void:
	if not active:
		return
	_steady_in -= delta
	if _steady_in > 0.0:
		return
	_steady_in = STEADY_EVERY
	var marshals: Array[Person] = []
	for p in _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.corps == Person.Corps.MARSHAL:
			marshals.append(p)
	if marshals.is_empty():
		return
	for c in _crowd.citizens:
		if not is_instance_valid(c) or c.mind != Person.Mind.CONFUSED or not c._was_fleeing:
			continue
		for m in marshals:
			if m.ground_pos.distance_to(c.ground_pos) <= STEADY_R:
				c._confused_left = minf(c._confused_left, STEADY_TIME)
				break


func clear() -> void:
	posts.clear()
	active = false
