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
## Rises whenever a threat starts, ends or a recent impact fades: EvacuationManager re-weighs the walk grid on it.
var epoch := 0
## func(at: Vector2) -> bool: where nothing is seen (Crowd.veil()); a danger there is not registered (-1).
var blind := Callable()
## first_near()'s box round the active threats, and the epoch it was fitted at.
var _box_min := Vector2.ZERO
var _box_max := Vector2.ZERO
var _box_epoch := -1
const _NONE := {}


func register(at: Vector2, radius: float, severity: float, duration: float, sight: float, sound: float,
		kind: StringName) -> int:
	if blind.is_valid() and blind.call(at):
		return -1
	var id := _next
	_next += 1
	epoch += 1
	_active[id] = {"id": id, "at": at, "radius": radius, "severity": severity, "until": _clock + duration,
		"sight": sight, "sound": sound, "kind": kind}
	return id


## Threat `id` lasts `duration` more seconds from now, in place: the same id, the same place in the list, no epoch bump (a
## ground fire renewing its danger every few seconds would otherwise re-weigh the walk grid each time). False, and nothing
## changes, when `id` is not active (-1, expired, ended) or its place is no longer seen: the caller registers it anew.
func refresh(id: int, duration: float) -> bool:
	if not _active.has(id):
		return false
	var t: Dictionary = _active[id]
	if blind.is_valid() and blind.call(t.at):
		return false
	t.until = maxf(float(t.until), _clock + duration)
	return true


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
			epoch += 1
	var kept: Array[Dictionary] = []
	for r in _recent:
		if _clock < float(r.until):
			kept.append(r)
	if kept.size() != _recent.size():
		epoch += 1
	_recent = kept


## Threat `id` is over now (a ground fire put out): it moves to the recent impacts exactly as step() does at its
## expiry. An unknown id (already expired, or -1 when the place was veiled) does nothing.
func end(id: int) -> void:
	if not _active.has(id):
		return
	var t: Dictionary = _active[id]
	_recent.append({"at": t.at, "radius": t.radius, "until": _clock + RECENT})
	_active.erase(id)
	epoch += 1


## Every dangerous zone, active or a recent impact: [{at, radius}].
func all_zones() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in _active.values():
		out.append(t)
	out.append_array(_recent)
	return out


## Active threats whose radius comes within `reach` of `at`.
func nearby(at: Vector2, reach: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in _active.values():
		if (t.at as Vector2).distance_to(at) <= float(t.radius) + reach:
			out.append(t)
	return out


## The first active threat (list order) whose radius comes within `reach` of `at`, or an empty dictionary: nearby()'s first
## entry without building the list. Citizens are asked several times a second while many dangers burn, so it allocates
## nothing and skips at once a point outside the box round every active threat.
func first_near(at: Vector2, reach: float) -> Dictionary:
	if _active.is_empty():
		return _NONE
	if _box_epoch != epoch:
		_box_epoch = epoch
		_fit_box()
	if at.x < _box_min.x - reach or at.x > _box_max.x + reach or at.y < _box_min.y - reach or at.y > _box_max.y + reach:
		return _NONE
	for id in _active:
		var t: Dictionary = _active[id]
		if (t.at as Vector2).distance_to(at) <= float(t.radius) + reach:
			return t
	return _NONE


## The box round every active threat's disc (first_near()), refitted when the epoch has moved.
func _fit_box() -> void:
	_box_min = Vector2(INF, INF)
	_box_max = Vector2(-INF, -INF)
	for id in _active:
		var t: Dictionary = _active[id]
		var c: Vector2 = t.at
		# Padded a little, so float rounding at the edge can never reject a point the exact test would accept.
		var r := float(t.radius) + 0.01
		_box_min = Vector2(minf(_box_min.x, c.x - r), minf(_box_min.y, c.y - r))
		_box_max = Vector2(maxf(_box_max.x, c.x + r), maxf(_box_max.y, c.y + r))


## Whether `at` lies inside an active threat or a recent impact, grown by `margin`.
func unsafe(at: Vector2, margin := 0.0) -> bool:
	for t: Dictionary in _active.values():
		if (t.at as Vector2).distance_to(at) <= float(t.radius) + margin:
			return true
	for r in _recent:
		if (r.at as Vector2).distance_to(at) <= float(r.radius) + margin:
			return true
	return false


## Whether any active threat is of `kind` (allocates nothing).
func has_kind(kind: StringName) -> bool:
	for id in _active:
		if (_active[id] as Dictionary).kind == kind:
			return true
	return false


func active_count() -> int:
	return _active.size()


func clear() -> void:
	_active.clear()
	_recent.clear()
	_clock = 0.0
	epoch += 1
