class_name Searchlight
extends RefCounted
## Halcyon's Searchlight (v0.10 M4, spec §4.1, the Vigil Flame's Phase 2): beams of gold light from the Temple's spire.
## Each beam is a pool of light on the ground, POOL_R round, swept out from the spire on a slow, predictable path: turning
## round it at SPIN while reaching in and out between NEAR and FAR over REACH_PERIOD, so at its farthest it lights the
## ground past the town's walls, up to FAR + POOL_R (28 units) from the spire. One beam lights first, a
## second SECOND_AFTER later, turning the other way. A Will-o'-Wisp is a decoy (lure()): the beam nearest it goes to it
## and stays DECOY_SECONDS. In the clock's last SEARCH_LAST seconds a beam stops to search at the latest noise (hear():
## the director hears casts and deaths), and a newer noise moves it. A beam moves at most BEAM_SPEED, so it slides
## rather than jumps. touches() is the night's test of being seen. Pure logic, stepped by VigilFlameDirector: headless
## tests run it alone, and SearchlightFx draws it.

## How many beams there can be, and the radius of each beam's pool of light (ground units).
const MAX_BEAMS := 2
const POOL_R := 2.0
## The sweep: radians a second round the spire (one round in 40 s), and how near and far from it the pool swings, there
## and back over REACH_PERIOD seconds.
const SPIN := TAU / 40.0
const NEAR := 5.0
const FAR := 26.0
const REACH_PERIOD := 30.0
## Where each beam's sweep starts (radians from ground +x: PI / 2 points from the spire towards the market) and which
## way it turns.
const START := [PI * 0.5, -PI * 0.5]
const TURN := [1.0, -1.0]
## The second beam lights this long after the first.
const SECOND_AFTER := 30.0
## The clock's last seconds, in which a beam stops to search at the latest noise.
const SEARCH_LAST := 20.0
## How long a decoy holds its beam.
const DECOY_SECONDS := 5.0
## The fastest a beam's pool moves (ground units a second): faster than its sweep, so it can catch a decoy or a noise
## and catch its sweep up again.
const BEAM_SPEED := 8.0

var spire := Vector2.ZERO
var on := false
## Seconds since the light woke.
var age := 0.0
## The latest noise, or Vector2.INF before any.
var noise := Vector2.INF
## A Will-o'-Wisp's light, how long it holds its beam, and which beam (-1: none).
var decoy := Vector2.INF
var decoy_left := 0.0
var decoy_beam := -1
## Searching (the clock's last seconds, with a noise heard), and which beam searches (-1: none).
var searching := false
var search_beam := -1
var _aims: Array[Vector2] = [Vector2.INF, Vector2.INF]
## The noise the searching beam was sent to: a newer one sends a beam again.
var _searched := Vector2.INF


func setup(at: Vector2) -> Searchlight:
	spire = at
	return self


## Wake the light, `from` seconds into its sweep (the bench lights both beams at once).
func light(from := 0.0) -> void:
	if on:
		return
	on = true
	age = from
	for i in MAX_BEAMS:
		_aims[i] = sweep_point(i, beam_age(i)) if i < beams() else Vector2.INF


func put_out() -> void:
	on = false
	searching = false
	search_beam = -1
	decoy_left = 0.0
	decoy_beam = -1


## How many beams are lit.
func beams() -> int:
	if not on:
		return 0
	return MAX_BEAMS if age >= SECOND_AFTER else 1


## Beam i's own time: seconds since it lit.
func beam_age(i: int) -> float:
	return age - (SECOND_AFTER if i == 1 else 0.0)


## Where beam i's sweep has its pool `t` seconds after the beam lit.
func sweep_point(i: int, t: float) -> Vector2:
	var angle := float(START[i]) + float(TURN[i]) * SPIN * t
	var reach := lerpf(NEAR, FAR, 0.5 - 0.5 * cos(TAU * t / REACH_PERIOD))
	return spire + Vector2.from_angle(angle) * reach


## Where beam i's pool is now, or Vector2.INF while it is not lit.
func aim(i: int) -> Vector2:
	return _aims[i] if i < beams() else Vector2.INF


## A lit beam's pool covers `at`: whoever stands there is seen.
func touches(at: Vector2) -> bool:
	for i in beams():
		if _aims[i].distance_to(at) <= POOL_R:
			return true
	return false


## A noise at `at` (a cast, a death): the latest is where a searching beam stops.
func hear(at: Vector2) -> void:
	noise = at


## A Will-o'-Wisp at `at`: the nearest lit beam goes to it for DECOY_SECONDS. Nothing while the light sleeps.
func lure(at: Vector2) -> void:
	if not on:
		return
	decoy = at
	decoy_left = DECOY_SECONDS
	decoy_beam = _nearest(at, -1)


func step(delta: float, time_left: float) -> void:
	if not on:
		return
	age += delta
	decoy_left = maxf(0.0, decoy_left - delta)
	if decoy_left <= 0.0:
		decoy_beam = -1
	searching = time_left <= SEARCH_LAST and noise != Vector2.INF
	if not searching:
		search_beam = -1
	elif search_beam < 0 or _searched != noise:
		_searched = noise
		search_beam = _nearest(noise, decoy_beam if beams() > 1 else -1)
	for i in beams():
		if _aims[i] == Vector2.INF:
			_aims[i] = sweep_point(i, beam_age(i))  # the second beam lights where its sweep begins
		_aims[i] = _aims[i].move_toward(_want(i), BEAM_SPEED * delta)


## Where beam i is going: its decoy, else its search, else its sweep. A decoy holds a beam before a search does.
func _want(i: int) -> Vector2:
	if i == decoy_beam:
		return decoy
	if i == search_beam:
		return noise
	return sweep_point(i, beam_age(i))


## The lit beam nearest `at`, other than `skip`; -1 when there is none.
func _nearest(at: Vector2, skip: int) -> int:
	var best := -1
	for i in beams():
		if i == skip:
			continue
		if best < 0 or _aims[i].distance_to(at) < _aims[best].distance_to(at):
			best = i
	return best
