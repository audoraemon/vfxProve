class_name EventTimeline
extends RefCounted
## An act's timed events (v0.09): each fires once, in time order, when the act has run `at` seconds -- its callback, then
## `fired` (the director shows it as a banner). The HUD shows the next few so the player can see the windows coming.

signal fired(id: String, label: String)

var _events: Array[Dictionary] = []
var _elapsed := 0.0
## How many times slower the timeline's own seconds run than the night's (v0.11 M1, stretched()): an event `at` seconds in,
## and every wait a director measures with elapsed(), comes that many times later in real seconds. 1 off the board.
var _scale := 1.0


## A timeline whose events and elapsed() run `factor` times slower than real time (v0.11 M1, spec §7.2: a board mission's
## windows stretched to its tier's longer clock). 1 leaves it as it was.
func stretched(factor: float) -> EventTimeline:
	_scale = maxf(factor, 0.01)
	return self


func stretch_factor() -> float:
	return _scale


## `when`, if given, is asked as the event falls due: false and the event is dropped without a word (no callback, no
## `fired`), and the strip stops listing it as soon as it answers false -- its response started, or ended, on its own.
func add(at: float, id: String, label: String, fn := Callable(), when := Callable()) -> EventTimeline:
	_events.append({"at": at, "shown": at, "id": id, "label": label, "fn": fn, "when": when, "done": false, "skipped": false,
		"n": _events.size()})
	# sort_custom is not stable: events due together keep the order they were added in.
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.n) < int(b.n) if is_equal_approx(float(a.at), float(b.at)) else float(a.at) < float(b.at))
	return self


func step(delta: float) -> void:
	_elapsed += delta / _scale
	for e in _events:
		if bool(e.done) or float(e.at) > _elapsed:
			continue
		e.done = true
		if not _applies(e):
			e.skipped = true
			continue
		if (e.fn as Callable).is_valid():
			(e.fn as Callable).call()
		fired.emit(String(e.id), String(e.label))


## The next `n` events still to come, soonest first as the strip shows them (v0.11 M3: each at its shown time -- its own, or the
## sooner one a director's chain expects, expect() -- ties in the order added; for a timeline that never calls expect() this is
## the order of old).
func upcoming(n := 2) -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	for e in _events:
		if not bool(e.done) and _applies(e):
			due.append(e)
	due.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.n) < int(b.n) if is_equal_approx(float(a.shown), float(b.shown)) else float(a.shown) < float(b.shown))
	var out: Array[Dictionary] = []
	for e in due.slice(0, n):
		out.append({"at": float(e.shown) * _scale, "id": e.id, "label": e.label,
			"in": maxf((float(e.shown) - _elapsed) * _scale, 0.0)})
	return out


func fired_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for e in _events:
		if bool(e.done) and not bool(e.skipped):
			out.append(String(e.id))
	return out


## The event `id` has come, fired or dropped by its guard (v0.11 M1: EventObjective's deadline); false for none.
func has_come(id: String) -> bool:
	for e in _events:
		if String(e.id) == id:
			return bool(e.done)
	return false


## Real seconds until the event `id` comes (v0.11 M1); 0 once it has, or for no such event. v0.11 M3: to its shown time (expect()).
func seconds_to(id: String) -> float:
	for e in _events:
		if String(e.id) == id and not bool(e.done):
			return maxf((float(e.shown) - _elapsed) * _scale, 0.0)
	return 0.0


## The strip shows the event `id` coming at `at`, the night's real second a director's chain brings it to, when that is sooner
## than its own time (v0.11 M3, mission spec §6). Display only: upcoming() and seconds_to() read it; the event still fires at its
## own time, so a director that brings an item forward fires it itself, as the chains do. No event `id`: nothing.
func expect(id: String, at: float) -> void:
	for e in _events:
		if String(e.id) == id:
			e.shown = minf(float(e.shown), at / _scale)
			return


## Does the event still apply (no guard, or the guard says so)?
func _applies(e: Dictionary) -> bool:
	var when := e.when as Callable
	return not when.is_valid() or bool(when.call())


func elapsed() -> float:
	return _elapsed
