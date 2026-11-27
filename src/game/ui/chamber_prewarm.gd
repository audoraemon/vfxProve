class_name ChamberPrewarm
extends RefCounted
## God's Chamber: what the stations' pages and the room's transition sounds will read, loaded on other threads while the god stands in
## the room, so a zoom into a station does not stop on its last frame to read the page's pictures from disk (the Ability Tree's icons
## took ~150 ms, the Rite Door's Prepare ~1-3 s). GodChamber.setup() hands start() the paths once per room; what is already asked for is
## skipped, so a second room asks for nothing. step() runs while the room is at rest: it takes what has finished (kept for the session,
## so the page's own load() finds it in the cache) and makes the grey copies (UiIcon.grey) of the icons a page will draw locked, a few
## per frame. A page opened before it is done loads the rest itself, as before. Nothing runs headless (no pictures to wait for there),
## unless a test sets `force`.

## How long step() may work in one frame, microseconds, by default.
const BUDGET_USEC := 3000

## Tests only: run under the headless display too.
static var force := false
## How many paths start() has asked to load, all told, and how many times it was called (tests).
static var requested := 0
static var calls := 0
static var _asked := {}
static var _pending := PackedStringArray()
static var _held := {}
## Paths whose grey copy is wanted, and the held ones still waiting for it.
static var _grey := {}
static var _grey_todo := PackedStringArray()


static func active() -> bool:
	return force or DisplayServer.get_name() != "headless"


## Starts loading `paths` (those that exist and were not asked for before) on other threads; the textures among `grey_paths` get their
## grey copy once loaded. Returns how many paths it asked for now (0 headless, and 0 for a second call with the same paths).
static func start(paths: PackedStringArray, grey_paths := PackedStringArray()) -> int:
	calls += 1
	if not active():
		return 0
	for path in grey_paths:
		if _grey.has(path):
			continue
		_grey[path] = true
		if _held.has(path):
			_grey_todo.append(path)  # loaded by an earlier room, wanted grey only now (a tier, a type)
	var n := 0
	for path in paths:
		if _asked.has(path):
			continue
		_asked[path] = true
		if not ResourceLoader.exists(path):
			continue
		if ResourceLoader.load_threaded_request(path) != OK:
			continue
		_pending.append(path)
		n += 1
	requested += n
	return n


## Takes what has finished loading and makes its grey copy, for at most `budget_usec`; true when nothing is left waiting.
static func step(budget_usec := BUDGET_USEC) -> bool:
	if _pending.is_empty() and _grey_todo.is_empty():
		return true
	var t0 := Time.get_ticks_usec()
	var i := 0
	while i < _pending.size():
		if Time.get_ticks_usec() - t0 >= budget_usec:
			break
		var path := _pending[i]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			i += 1
			continue
		_pending.remove_at(i)
		if status != ResourceLoader.THREAD_LOAD_LOADED:
			continue
		_held[path] = ResourceLoader.load_threaded_get(path)
		if _grey.has(path):
			_grey_todo.append(path)
	while not _grey_todo.is_empty() and Time.get_ticks_usec() - t0 < budget_usec:
		var tex := _held.get(_grey_todo[0]) as Texture2D
		_grey_todo.remove_at(0)
		if tex != null:
			UiIcon.grey(tex)
	return _pending.is_empty() and _grey_todo.is_empty()


## How many asked-for paths (and grey copies) are still waiting for step().
static func pending() -> int:
	return _pending.size() + _grey_todo.size()


## Whether `path` has been loaded and is kept (tests).
static func held(path: String) -> bool:
	return _held.has(path)


## Whether `path` was asked for (tests).
static func asked(path: String) -> bool:
	return _asked.has(path)


## Tests only: forget everything asked and held (a load still under way is waited for, so no task is left behind).
static func reset() -> void:
	for path in _pending:
		ResourceLoader.load_threaded_get(path)
	_asked.clear()
	_pending.clear()
	_grey.clear()
	_grey_todo.clear()
	_held.clear()
	requested = 0
