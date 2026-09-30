class_name RoutineManager
extends RefCounted
## The calm town's day (v0.04): where each calm citizen goes next and how long it stays. The crowd steps it every
## frame; it visits a slice of the citizens so each is seen HZ times a second. A citizen that has arrived counts down
## its stay, then gets its next place by its role's weights (CitizenProfile): home, work, a leisure spot, or an
## errand to a market stall. Movement stays the person's own.

const HZ := 1.0
## Chance of each kind of place next, per role: [home, work, leisure, errand].
const WEIGHTS := {
	CitizenProfile.Role.RESIDENT: [0.45, 0.0, 0.4, 0.15],
	CitizenProfile.Role.CAREGIVER: [0.55, 0.0, 0.3, 0.15],
	CitizenProfile.Role.MERCHANT: [0.2, 0.6, 0.15, 0.05],
	CitizenProfile.Role.CRAFT: [0.2, 0.55, 0.15, 0.1],
	CitizenProfile.Role.LABORER: [0.15, 0.55, 0.1, 0.2],
	CitizenProfile.Role.CLERGY: [0.2, 0.6, 0.2, 0.0],
	CitizenProfile.Role.FARMER: [0.2, 0.6, 0.05, 0.15],
}
## How long a citizen stays (seconds, min and max) at each kind of place.
const STAY := [Vector2(10, 30), Vector2(25, 60), Vector2(8, 25), Vector2(5, 12)]
## An errand is to one of this many market stalls nearest the citizen's home.
const ERRAND_NEAREST := 6
enum Place { HOME, WORK, LEISURE, ERRAND }

var _crowd: Crowd
var _rng := RandomNumberGenerator.new()
var _stalls: Array[Vector2] = []
var _due := 0.0
var _at := 0


func setup(crowd: Crowd, seed_value: int, stalls: Array[Vector2]) -> RoutineManager:
	_crowd = crowd
	_rng.seed = seed_value
	_stalls = stalls
	for p in crowd.citizens:
		# Staggered, so the whole town does not set off at once.
		p.stay_left = _rng.randf_range(0.0, 12.0)
	return self


func step(delta: float) -> void:
	var n := _crowd.citizens.size()
	if n == 0:
		return
	_due = minf(_due + n * HZ * delta, n)
	var k := int(_due)
	_due -= k
	for j in k:
		visit(_at, 1.0 / HZ)
		_at = (_at + 1) % n


## One look at citizen `i`, `dt` seconds after the last: count down its stay once it has arrived, then send it on.
func visit(i: int, dt: float) -> void:
	var p: Person = _crowd.citizens[i]
	if not is_instance_valid(p) or p.profile == null or p.mind != Person.Mind.CALM or p.state == DummyEnemy.State.DEAD \
			or p.has_goal():
		return
	p.stay_left -= dt
	if p.stay_left > 0.0:
		return
	var place := pick(p.profile, p.last_place)
	var to := destination(p.profile, place)
	p.last_place = place
	p.stay_left = _rng.randf_range(STAY[place].x, STAY[place].y)
	p.anchor = to
	p.set_goal(to)


## The next kind of place by the role's weights, never the same kind twice running (unless it is the only one).
func pick(pr: CitizenProfile, last: int) -> Place:
	var w: Array = (WEIGHTS[pr.role] as Array).duplicate()
	if not pr.works():
		w[Place.WORK] = 0.0
	if _stalls.is_empty():
		w[Place.ERRAND] = 0.0
	var total := 0.0
	for k in w.size():
		if k == last and w.reduce(func(a: float, b: float) -> float: return a + b) > w[k]:
			w[k] = 0.0
		total += w[k]
	var roll := _rng.randf() * total
	for k in w.size():
		roll -= w[k]
		if roll < 0.0:
			return k as Place
	return Place.HOME


func destination(pr: CitizenProfile, place: Place) -> Vector2:
	match place:
		Place.WORK:
			return pr.work
		Place.LEISURE:
			return pr.leisure[_rng.randi_range(0, pr.leisure.size() - 1)] if not pr.leisure.is_empty() else pr.home
		Place.ERRAND:
			var near := _stalls.duplicate()
			near.sort_custom(func(a: Vector2, b: Vector2) -> bool:
				return a.distance_squared_to(pr.home) < b.distance_squared_to(pr.home))
			near = near.slice(0, ERRAND_NEAREST)
			return near[_rng.randi_range(0, near.size() - 1)]
	return pr.home
