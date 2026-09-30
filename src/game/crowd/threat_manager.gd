class_name ThreatManager
extends RefCounted
## What is dangerous in the town, and where (v0.04): every cast and collapse registers a threat -- where it is, its
## radius, how severe, how long it lasts, and how far it is seen and heard. People only react to threats they are
## near (Crowd.on_threat()); a threat that has ended leaves a recent impact behind for RECENT seconds, which people
## returning to their routine avoid. Few threats are ever active at once, so queries walk the list.

## Seconds a spent threat's ground is still avoided.
const RECENT := 8.0

var _next := 1
## id -> {at, radius, severity, until, sight, sound, kind}
var _active := {}
## [{at, radius, until}] of threats that have ended.
var _recent: Array[Dictionary] = []
var _clock := 0.0


func register(at: Vector2, radius: float, severity: float, duration: float, sight: float, sound: float,
		kind: StringName) -> int:
	var id := _next
	_next += 1
	_active[id] = {"id": id, "at": at, "radius": radius, "severity": severity, "until": _clock + duration,
		"sight": sight, "sound": sound, "kind": kind}
	return id


func get_threat(id: int) -> Dictionary:
	return _active.get(id, {})


func is_active(id: int) -> bool:
	return _active.has(id)


func step(delta: float) -> void:
	_clock += delta
	for id in _active.keys():
		var t: Dictionary = _active[id]
		if _clock >= float(t.until):
			_recent.append({"at": t.at, "radius": t.radius, "until": _clock + RECENT})
			_active.erase(id)
	var kept: Array[Dictionary] = []
	for r in _recent:
		if _clock < float(r.until):
			kept.append(r)
	_recent = kept


## Active threats whose radius comes within `reach` of `at`.
func nearby(at: Vector2, reach: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in _active.values():
		if (t.at as Vector2).distance_to(at) <= float(t.radius) + reach:
			out.append(t)
	return out


## Whether `at` lies inside an active threat or a recent impact, grown by `margin`.
func unsafe(at: Vector2, margin := 0.0) -> bool:
	for t: Dictionary in _active.values():
		if (t.at as Vector2).distance_to(at) <= float(t.radius) + margin:
			return true
	for r in _recent:
		if (r.at as Vector2).distance_to(at) <= float(r.radius) + margin:
			return true
	return false


func active_count() -> int:
	return _active.size()


func clear() -> void:
	_active.clear()
	_recent.clear()
	_clock = 0.0
