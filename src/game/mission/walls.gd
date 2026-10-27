class_name Walls
extends RefCounted
## The walls of the town a mission is played in (god T1R, spec 2.1): who is out of them, and which way off the map a person who has left
## them goes. Static and read-only; MissionDirector keeps the leavers (send_off(), _step_leaving()).

## How far past the wall's ring a person must stand to be out of the walls (tunable, 0.3-1.0): past the wall's band (TownLayout.WALL_T
## 0.7 inside the edge) and a gate's passage (the Main Gate ends at y 16.2).
const MARGIN := 0.5


## `at` is out of the walls of `city` (the town being played when null): past the old town's ring by MARGIN, whatever way he got there.
static func outside(at: Vector2, city: CityDef = null) -> bool:
	var c: CityDef = city if city != null else City.current()
	return not c.town().grow(MARGIN).has_point(at)


## Where a person at `at` who has left the walls goes to be gone: the nearest of the town's exits whose straight walk from `at` does not
## cross the old town (he never walks back in, spec 2.1: from a Capital bridge the ferry landing is nearer, but the way to it runs back
## through the harbour gate); the nearest exit when every one does. Vector2.INF when the town has no exit.
static func way_off(at: Vector2) -> Vector2:
	var town := City.current().town()
	var best := Vector2.INF
	var best_clear := Vector2.INF
	for e: Vector2 in City.current().exits():
		if best == Vector2.INF or at.distance_squared_to(e) < at.distance_squared_to(best):
			best = e
		if not _crosses(at, e, town) and (best_clear == Vector2.INF or at.distance_squared_to(e) < at.distance_squared_to(best_clear)):
			best_clear = e
	return best_clear if best_clear != Vector2.INF else best


## The straight walk from `a` to `b` passes through the inside of `r` (touching its edge does not count). One that starts inside it crosses.
static func _crosses(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a):
		return true
	var lo := 0.0
	var hi := 1.0
	var d := b - a
	for axis in 2:
		var p := d[axis]
		var min_edge := r.position[axis]
		var max_edge := r.end[axis]
		if absf(p) < 0.000001:
			if a[axis] <= min_edge or a[axis] >= max_edge:
				return false
			continue
		var t0 := (min_edge - a[axis]) / p
		var t1 := (max_edge - a[axis]) / p
		lo = maxf(lo, minf(t0, t1))
		hi = minf(hi, maxf(t0, t1))
		if lo >= hi:
			return false
	return true
