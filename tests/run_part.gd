extends SceneTree
## Runs one part of tests/run_all.gd's SUITES (`-- --part=N --of=M`), so tools/dev/run_suite_parallel.sh can run the whole
## suite as M Godot processes at once. Prints "part=N/M suites=S checks=C failures=F"; exits 1 on any failure.

const ALL := preload("res://tests/run_all.gd")

var failures := 0
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: ", msg)


func near(a: float, b: float, eps: float, msg: String) -> void:
	check(absf(a - b) <= eps, "%s (got %f expected %f)" % [msg, a, b])


## Aldermere's world before each suite (v0.12, C3): the active city and the crowd's two process-wide statics a capital suite sets.
func _reset_world() -> void:
	City.use(&"aldermere")
	City._extra.clear()  # a fixture town a failed suite never unregistered
	Person.frame_no = -1
	Person.offscreen_every = Person.OFFSCREEN_EVERY
	GodTree.dev_fill = false  # god P1: the dev fill is on only inside a test that turns it on


func _initialize() -> void:
	var part := 1
	var of := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--part="):
			part = int(a.substr(7))
		elif a.begins_with("--of="):
			of = int(a.substr(5))
	var suites: Array = ALL.SUITES
	var size := ceili(float(suites.size()) / of)
	var mine: Array = suites.slice((part - 1) * size, part * size)
	for path in mine:
		var suite: GDScript = load(path)
		if suite == null or not suite.can_instantiate():
			check(false, "suite failed to load: %s" % path)
			continue
		Hud.reset_session()  # v0.11.1: no suite depends on the display state an earlier one left in this process
		_reset_world()
		var before := checks
		suite.run(self)
		if checks == before:
			check(false, "suite ran no checks (runtime error?): %s" % path)
		# v0.12 (ruling C3): a suite that switched the city puts Aldermere back; one that did not is a failure, named.
		check(City.current().id() == &"aldermere", "suite left a city active: %s (%s)" % [path, City.current().id()])
	print("part=%d/%d suites=%d checks=%d failures=%d" % [part, of, mine.size(), checks, failures])
	quit(1 if failures > 0 else 0)
