extends RefCounted
## Dev-only frame timers for the bench (capital plan, Task 13): `--bench --bench-prof` times each system's share of a
## frame (the people, the crowd's own step and its gates, the structures, the fire and smoke, the floor and decor) and
## Battlefield.bench() prints them as ms a frame. Off -- every other run, and a plain --bench -- each hook is one static
## bool test. Preloaded where used (no class_name, so the global class cache is untouched).

static var on := false
static var _usec := {}
static var _count := {}


## Start timing: the clock now, or 0 when off.
static func begin() -> int:
	return Time.get_ticks_usec() if on else 0


## Add the time since `since` (from begin()) to `key`.
static func add(key: StringName, since: int) -> void:
	if on:
		_usec[key] = int(_usec.get(key, 0)) + Time.get_ticks_usec() - since


## Count `n` of `key` (people stepped, structures processed).
static func count(key: StringName, n := 1) -> void:
	if on:
		_count[key] = int(_count.get(key, 0)) + n


static func reset() -> void:
	_usec.clear()
	_count.clear()


## Every timer as ms a frame and every count as a number a frame, over `frames`, keys sorted.
static func report(frames: int) -> String:
	var parts: PackedStringArray = []
	var keys := _usec.keys()
	keys.sort()
	for k in keys:
		parts.append("%s=%.2fms" % [k, float(_usec[k]) / 1000.0 / maxf(frames, 1)])
	keys = _count.keys()
	keys.sort()
	for k in keys:
		parts.append("%s=%.1f" % [k, float(_count[k]) / maxf(frames, 1)])
	return " ".join(parts)
