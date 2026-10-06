class_name IntroTour
extends RefCounted
## The camera's tour of a mission's key places before its clock starts (v0.10 M6, spec §5): from where the intro opens to
## each stop in turn -- MOVE_SECONDS on the way, smoothed, then HOLD_SECONDS there under the stop's caption -- and on to
## where play begins. A pure timeline: Mission moves the camera, and the HUD shows the caption.

## Each move between points, and each hold at a stop.
const MOVE_SECONDS := 1.0
const HOLD_SECONDS := 1.6

## The tour's points in order -- where it opens, each stop, where play begins -- and each stop's caption.
var _points: Array[Vector2] = []
var _captions: Array[String] = []
## Seconds into the tour.
var _t := 0.0


## `stops`: [ground point, caption] pairs, in order.
func setup(from: Vector2, stops: Array, to: Vector2) -> IntroTour:
	_points.clear()
	_captions.clear()
	_points.append(from)
	for s: Array in stops:
		_points.append(s[0] as Vector2)
		_captions.append(String(s[1]))
	_points.append(to)
	_t = 0.0
	return self


## The whole tour: a move to each stop and one on to where play begins, and a hold at each stop.
func seconds() -> float:
	return float(_captions.size() + 1) * MOVE_SECONDS + float(_captions.size()) * HOLD_SECONDS


## The tour runs on by `delta` seconds, to its end at most.
func step(delta: float) -> void:
	_t = minf(_t + delta, seconds())


## To the end at once.
func skip() -> void:
	_t = seconds()


## The tour has reached where play begins.
func done() -> bool:
	return _t >= seconds()


## Where the camera looks now (ground units).
func camera() -> Vector2:
	var leg := _leg()
	var k := _leg_k()
	return _points[leg].lerp(_points[leg + 1], k * k * (3.0 - 2.0 * k))


## The caption of the stop the tour is moving to or holding at; "" on the way to where play begins.
func caption() -> String:
	var leg := _leg()
	return _captions[leg] if leg < _captions.size() else ""


## How far the zoom has come in, 0 to 1: over the first move, then held.
func zoom_k() -> float:
	var k := clampf(_t / MOVE_SECONDS, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## The leg under way: leg i runs from point i to point i + 1, a move and then (to a stop) a hold.
func _leg() -> int:
	return mini(floori(_t / (MOVE_SECONDS + HOLD_SECONDS)), _captions.size())


## How far along its move the leg under way is, 0 to 1 (1 while it holds).
func _leg_k() -> float:
	var into := _t - float(_leg()) * (MOVE_SECONDS + HOLD_SECONDS)
	return clampf(into / MOVE_SECONDS, 0.0, 1.0)
