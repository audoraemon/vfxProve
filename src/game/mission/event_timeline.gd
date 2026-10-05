class_name EventTimeline
extends RefCounted
## An act's timed events (v0.09): each fires once, in time order, when the act has run `at` seconds -- its callback, then
## `fired` (the director shows it as a banner). The HUD shows the next few so the player can see the windows coming.

signal fired(id: String, label: String)

var _events: Array[Dictionary] = []
var _elapsed := 0.0


## `when`, if given, is asked as the event falls due: false and the event is dropped without a word (no callback, no
## `fired`), and the strip stops listing it as soon as it answers false -- its response started, or ended, on its own.
func add(at: float, id: String, label: String, fn := Callable(), when := Callable()) -> EventTimeline:
	_events.append({"at": at, "id": id, "label": label, "fn": fn, "when": when, "done": false, "skipped": false,
		"n": _events.size()})
	# sort_custom is not stable: events due together keep the order they were added in.
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.n) < int(b.n) if is_equal_approx(float(a.at), float(b.at)) else float(a.at) < float(b.at))
	return self


func step(delta: float) -> void:
	_elapsed += delta
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


func upcoming(n := 2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in _events:
		if not bool(e.done) and out.size() < n and _applies(e):
			out.append({"at": e.at, "id": e.id, "label": e.label, "in": maxf(float(e.at) - _elapsed, 0.0)})
	return out


func fired_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for e in _events:
		if bool(e.done) and not bool(e.skipped):
			out.append(String(e.id))
	return out


## Does the event still apply (no guard, or the guard says so)?
func _applies(e: Dictionary) -> bool:
	var when := e.when as Callable
	return not when.is_valid() or bool(when.call())


func elapsed() -> float:
	return _elapsed
