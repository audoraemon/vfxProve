class_name VigilRoute
extends RefCounted
## The Vigil (v0.10, spec §4.1): a priest, the flame-bearer, walks a route point by point, two acolytes keeping beside
## him. A fright stops him; once on his feet again he takes the route up where he left it. At the last point the walk is
## over and all three go back to their day; a dead bearer ends it at once. Mira's House walks it past her door.
## Broken Lanterns (M3) walks it round Halcyon's six wayside shrines and asks three things more, each off unless set:
## the walk goes round again from the first point (`loop`); the bearer turns aside to one place, then takes the route up
## where he left it (divert()); and a dead bearer's flame passes to the first living acolyte (`pass_flame`), so only all
## three dead end the walk.

## The flame passed to `to` (pass_flame).
signal flame_passed(to: Person)

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
## func(p: Person) -> bool: a walker busy elsewhere (v0.10: carrying a report to the Temple), not to be pulled back.
var busy: Callable
## Round again from the first point after the last (v0.10 M3), rather than finishing.
var loop := false
## A dead bearer's flame passes to the first living acolyte (v0.10 M3), rather than ending the walk.
var pass_flame := false
## Where the bearer has turned aside to (divert()), or Vector2.INF while he walks the route.
var detour := Vector2.INF
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


## Where the bearer is walking now: his detour, else the route's next point.
func goal() -> Vector2:
	return detour if detour != Vector2.INF else route[leg]


## Turn the bearer aside to `at` (Vector2.INF: back to the route). On his way he makes for it at once; once there he
## takes the route up where he left it.
func divert(at: Vector2) -> void:
	detour = at
	if not active or not _alive(bearer) or bearer.mind != Person.Mind.DUTY:
		return
	if busy.is_valid() and bool(busy.call(bearer)):
		return
	bearer.go_duty(goal())


func step(delta: float) -> void:
	if not active:
		return
	if not _alive(bearer) and not _take_flame():
		finish()
		return
	if busy.is_valid() and bool(busy.call(bearer)):
		return  # carrying a report: the walk waits for him
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	if bearer.mind != Person.Mind.DUTY:
		if bearer.mind in RESUMABLE:
			bearer.go_duty(goal())
		return
	var at := goal()
	if bearer.ground_pos.distance_to(at) <= ARRIVE or not bearer.has_goal():
		if bearer.ground_pos.distance_to(at) <= ARRIVE:
			if detour != Vector2.INF:
				detour = Vector2.INF
			else:
				leg += 1
				if leg >= route.size():
					if not loop:
						finish()
						return
					leg = 0
		bearer.go_duty(goal())
	_keep_acolytes()


## The walk is over: everyone still on it goes back to their day.
func finish() -> void:
	active = false
	finished = true
	for p in walkers():
		if p.mind == Person.Mind.DUTY:
			p.leave_shelter(false)


## The bearer is dead: with pass_flame, the first living acolyte takes the flame up and walks on (at once, if on his
## feet and not busy elsewhere, whose errand the flame waits on); false when nobody can.
func _take_flame() -> bool:
	if not pass_flame:
		return false
	for a in acolytes:
		if not _alive(a):
			continue
		bearer = a
		acolytes.erase(a)
		_tick = 0.0
		var errand := busy.is_valid() and bool(busy.call(a))
		if not errand and (a.mind == Person.Mind.DUTY or a.mind in RESUMABLE):
			a.go_duty(goal())
		flame_passed.emit(a)
		return true
	return false


func _keep_acolytes() -> void:
	for i in acolytes.size():
		var a := acolytes[i]
		if not _alive(a) or not (a.mind == Person.Mind.DUTY or a.mind in RESUMABLE):
			continue
		if busy.is_valid() and bool(busy.call(a)):
			continue
		var place := bearer.ground_pos + (ACOLYTE_OFFSETS[i % ACOLYTE_OFFSETS.size()] as Vector2)
		if a.mind != Person.Mind.DUTY or a.anchor.distance_to(place) > ACOLYTE_DRIFT:
			a.go_duty(place)


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
