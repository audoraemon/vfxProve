class_name BailiffWish
extends Wish
## "Stop the bailiff" (v0.11 M2, mission spec §5, Rescue): a timed wish. It waits until engaged -- the bailiff's or the home's
## tag clicked, or a power cast within ENGAGE_REACH of either -- then the bailiff, a free soldier at least MIN_WALK from the
## wisher's home and no more than MAX_ROUTE of street from it, walks there to seize what they owe. Stop him (dead), turn him
## (RescueWish.TURNED: the god's own effects), or keep him from the door until SECONDS run out, and it is granted. His reaching
## the door fails it; so does the wisher dying (Wish). A town order taking him off the errand (the rally, a post) sends him back
## on it. Engagement is judged first, as Save my child's: the bailiff felled by the god's own cast before it was engaged engages
## and grants it; felled by any other hand before, it fails.

## The most time he has to reach the door once engaged (v0.11 M2): a cap, not a countdown the player is shown -- from MIN_WALK he
## reaches it in about 16 s (the median of sixteen seeded towns), so a bailiff left alone is at the door long before it runs out.
const SECONDS := 50.0
## How near a cast must land to the bailiff or the home to engage the wish (v0.11 M2).
const ENGAGE_REACH := 2.0
## How near the door counts as there (v0.11 M2).
const HOME_REACH := 1.0
## How far from the home he starts at least (v0.11 M2): 20 units is a walk of some 16 s after engagement, fair for a click.
const MIN_WALK := 20.0
## How long his route to the door may be at most, in units of path (v0.11 M2, Task 8): a courtyard's winding street can make a
## 20-unit distance a long walk, and one the 50 s cap would run out on grants the wish for doing nothing. About 40 units is a
## walk of some 30 s after engagement.
const MAX_ROUTE := 40.0
## How often he is re-aimed (v0.11 M2).
const RETARGET := 0.5

## The soldier sent to the door (v0.11 M2).
var bailiff: Person
## The wisher's door, on walkable ground (v0.11 M2).
var home := Vector2.INF
## The player has engaged it: he is set out and the clock runs (v0.11 M2).
var engaged := false
## The clock, from SECONDS once engaged (v0.11 M2).
var seconds_left := SECONDS
## Seconds to the next re-aim (v0.11 M2).
var _retarget_in := 0.0
## check() has let him go (v0.11 M2).
var _ended := false
## He has been on his errand (his mind was DUTY): only then does leaving it turn him (v0.11 M2).
var _started := false
## The damage kind that felled him before the wish was engaged, or &"" for none yet (v0.11 M2).
var _fell: StringName = &""


## A lay wisher with a home, and a free soldier at least MIN_WALK from its door who can walk there; false when the town cannot
## give both. Wishers are tried from a random start: a home whose nearest open ground is shut in by the buildings round it
## (a quarter of the town's, with no route to or from it) is passed over, or the bailiff would never set out and the wish
## would be granted for nothing at SECONDS.
func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var homes: Array[Person] = []
	for p in Wish.lay(crowd, taken):
		if p.profile.home != Vector2.INF:
			homes.append(p)
	if homes.is_empty():
		return false
	var start := rng.randi_range(0, homes.size() - 1)
	for k in homes.size():
		var who := homes[(start + k) % homes.size()]
		var door := crowd._grid.nearest_walkable(who.profile.home) if crowd._grid != null else who.profile.home
		door = door if door != Vector2.INF else who.profile.home
		var guard := _bailiff_for(crowd, door, taken)
		if guard == null:
			continue
		wisher = who
		home = door
		bailiff = guard
		taken.append_array([wisher, bailiff])
		crowd._field.enemy_killed.connect(_on_killed)
		return true
	return false


## The free soldier nearest `door` at least MIN_WALK from it, with a route to it of at most MAX_ROUTE: alive, out of doors, of
## no corps, not in `taken`; null for none. The route is asked from the door, where a shut-in courtyard fails at once.
static func _bailiff_for(crowd: Crowd, door: Vector2, taken: Array) -> Person:
	var free: Array[Person] = []
	for v: Variant in crowd.soldiers:
		if not MissionDirector._alive(v):
			continue
		var s := v as Person
		if not s.inside and s.corps == Person.Corps.NONE and not taken.has(s) and s.ground_pos.distance_to(door) >= MIN_WALK:
			free.append(s)
	free.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	for s in free:
		if crowd._grid == null or route_length(crowd._grid, door, s.ground_pos) <= MAX_ROUTE:
			return s
	return null


## How far the street runs from `from` to `to` (v0.11 M2, Task 8): the length of the grid's route, with the hops to and from its
## ends; INF when there is no route.
static func route_length(grid: WalkGrid, from: Vector2, to: Vector2) -> float:
	var route := grid.path(from, to)
	if route.is_empty():
		return INF
	var length := from.distance_to(route[0]) + route[route.size() - 1].distance_to(to)
	for i in range(1, route.size()):
		length += route[i - 1].distance_to(route[i])
	return length


## The wisher and the bailiff, if his body is still there (v0.11 M2).
func people() -> Array[Person]:
	var out := super()
	if bailiff != null and is_instance_valid(bailiff):
		out.append(bailiff)
	return out


## A timed wish: it waits for the player to engage it (v0.11 M2).
func timed() -> bool:
	return true


## Open and not yet engaged: its tags answer a click (v0.11 M2).
func waiting() -> bool:
	return not engaged and status == Status.PENDING


## Engaged (spec §5.2): the bailiff sets out for the door and the clock starts. Once only, while he lives.
func engage() -> bool:
	if not waiting() or not MissionDirector._alive(bailiff):
		return false
	engaged = true
	seconds_left = SECONDS
	_retarget_in = 0.0
	bailiff.go_duty(home)
	_started = bailiff.mind == Person.Mind.DUTY
	return true


## A power cast within ENGAGE_REACH of the home or the bailiff engages it (v0.11 M2).
func on_cast(_key: String, at: Vector2) -> void:
	if engaged:
		return
	if at.distance_to(home) <= ENGAGE_REACH or (MissionDirector._alive(bailiff) and bailiff.ground_pos.distance_to(at) <= ENGAGE_REACH):
		engage()


## Notes how he fell before the wish was engaged; judged in _act(), where the rules can say whose it was.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if e == bailiff and not engaged and _fell == &"":
		_fell = kind


## The clock runs; every RETARGET he is kept on his way to the door. One who could not set out is sent again; one the town
## took off the errand is sent back on it; one the god turned is left be.
func step(_rules: Rules, delta: float) -> void:
	if not engaged or status != Status.PENDING:
		return
	seconds_left = maxf(seconds_left - delta, 0.0)
	_retarget_in -= delta
	if _retarget_in > 0.0 or not MissionDirector._alive(bailiff):
		return
	_retarget_in = RETARGET
	if not _started:
		bailiff.go_duty(home)
		_started = bailiff.mind == Person.Mind.DUTY
		return
	if bailiff.mind != Person.Mind.DUTY:
		if not RescueWish.TURNED.has(bailiff.mind):
			bailiff.go_duty(home)
		return
	if bailiff.anchor.distance_to(home) > 0.3:
		bailiff.go_duty(home)


## Where the errand stands: granted when he is dead, turned or kept off for SECONDS; failed at the door (v0.11 M2).
func _act(rules: Rules) -> Status:
	if not engaged and not MissionDirector._alive(bailiff):
		if _fell == &"" or rules.credited_key(_fell) == "":
			return Status.FAILED
		engaged = true
	if not MissionDirector._alive(bailiff):
		return Status.DONE
	if not engaged:
		return Status.PENDING
	if bailiff.ground_pos.distance_to(home) <= HOME_REACH:
		return Status.FAILED
	if _started and RescueWish.TURNED.has(bailiff.mind):
		return Status.DONE
	return Status.DONE if seconds_left <= 0.0 else Status.PENDING


## Once ended, a bailiff still on his errand is let go (Crowd.off_duty(): back to his post).
func check(rules: Rules) -> Status:
	var s := super(rules)
	if s != Status.PENDING and not _ended:
		_ended = true
		if MissionDirector._alive(bailiff) and bailiff.mind == Person.Mind.DUTY:
			_crowd.off_duty(bailiff)
	return s


## "Stop the bailiff before he reaches the door (+15)": the act, with no countdown (v0.11 M2: SECONDS is only a cap, which he
## never nears).
func hud_text(_rules: Rules) -> String:
	return "%s before he reaches the door (+%d)" % [def.text, reward]


## BAILIFF on him (edged once engaged), HOME on the door (v0.11 M2).
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if MissionDirector._alive(bailiff) and not bailiff.inside:
		out.append(MapTag.person(bailiff.ground_pos, COLOR, "BAILIFF", engaged))
	if home != Vector2.INF:
		out.append(MapTag.place(home, COLOR, "HOME", 0.0, false))
	return out


## Lets go of the kill signal (v0.11 M2).
func release() -> void:
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)
