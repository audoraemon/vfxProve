extends Logger
## Counts GDScript runtime errors (SCRIPT ERROR: "Invalid call. Nonexistent function ...", a freed instance touched, ...) while it is added
## with OS.add_logger(). A runtime error only aborts the function it happens in: the caller, and the suite's run(), go on, so the check
## count and the `await suite.run(self)` both look normal. tests/run_part.gd and tests/run_all.gd read it around each suite and make an
## error a failure, named. Engine (C++) errors and push_error() are not counted: only ERROR_TYPE_SCRIPT.

var _lock := Mutex.new()  # a logger may be called from any thread
var _count := 0
var _first := ""


func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int,
		_script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type != ERROR_TYPE_SCRIPT:
		return
	_lock.lock()
	_count += 1
	if _first == "":
		_first = "%s (%s:%d)" % [rationale if rationale != "" else code, file, line]
	_lock.unlock()


func _log_message(_message: String, _error: bool) -> void:
	pass


## The script errors seen since the last take(), and the first one's text; resets both.
func take() -> Array:
	_lock.lock()
	var out := [_count, _first]
	_count = 0
	_first = ""
	_lock.unlock()
	return out
