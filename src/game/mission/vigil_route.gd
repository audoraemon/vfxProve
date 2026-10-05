class_name VigilRoute
extends RefCounted
## The Vigil (v0.10, spec §4.1): a priest, the flame-bearer, walks a route point by point, two acolytes keeping beside
## him. A fright stops him; once on his feet again he takes the route up where he left it. At the last point the walk is
## over and all three go back to their day; a dead bearer ends it at once. Mira's House walks it past her door; M3 and
## M4 walk it round Halcyon's six wayside shrines.

## How near a point counts as reached, and seconds between looks at the walk.
const ARRIVE := 0.6
const TICK := 0.5
## Where each acolyte keeps beside the bearer (ground units), and how far off their place they may drift.
const ACOLYTE_OFFSETS := [Vector2(-0.7, 0.4), Vector2(0.7, 0.4)]
const ACOLYTE_DRIFT := 0.5
## Minds the bearer takes the route up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

var bearer: Person
var acolytes: Array[Person] = []
var route := PackedVector2Array()
var leg := 0
var active := false
var finished := false
var _tick := 0.0


func setup(points: PackedVector2Array, bearer_p: Person, acolyte_ps: Array[Person]) -> VigilRoute:
	route = points
	bearer = bearer_p
	acolytes = acolyte_ps
	return self


func start() -> void:
	if route.is_empty() or not _alive(bearer):
		finish()
		return
	active = true
	leg = 0
	_tick = TICK
	bearer.go_duty(route[0])
	_keep_acolytes()


## The living bearer and acolytes.
func walkers() -> Array[Person]:
	var out: Array[Person] = []
	for p in [bearer] + acolytes:
		if _alive(p):
			out.append(p)
	return out


func step(delta: float) -> void:
	if not active:
		return
	if not _alive(bearer):
		finish()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	if bearer.mind != Person.Mind.DUTY:
		if bearer.mind in RESUMABLE:
			bearer.go_duty(route[leg])
		return
	if bearer.ground_pos.distance_to(route[leg]) <= ARRIVE or not bearer.has_goal():
		if bearer.ground_pos.distance_to(route[leg]) <= ARRIVE:
			leg += 1
			if leg >= route.size():
				finish()
				return
		bearer.go_duty(route[leg])
	_keep_acolytes()


## The walk is over: everyone still on it goes back to their day.
func finish() -> void:
	active = false
	finished = true
	for p in walkers():
		if p.mind == Person.Mind.DUTY:
			p.leave_shelter(false)


func _keep_acolytes() -> void:
	for i in acolytes.size():
		var a := acolytes[i]
		if not _alive(a) or not (a.mind == Person.Mind.DUTY or a.mind in RESUMABLE):
			continue
		var place := bearer.ground_pos + (ACOLYTE_OFFSETS[i % ACOLYTE_OFFSETS.size()] as Vector2)
		if a.mind != Person.Mind.DUTY or a.anchor.distance_to(place) > ACOLYTE_DRIFT:
			a.go_duty(place)


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
