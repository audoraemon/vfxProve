extends SceneTree

const SUITES := [
	"res://tests/test_iso.gd",
	"res://tests/test_enemy_field.gd",
]

var failures := 0
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: ", msg)


func near(a: float, b: float, eps: float, msg: String) -> void:
	check(absf(a - b) <= eps, "%s (got %f expected %f)" % [msg, a, b])


func _initialize() -> void:
	for path in SUITES:
		var suite: GDScript = load(path)
		if suite == null or not suite.can_instantiate():
			check(false, "suite failed to load: %s" % path)
			continue
		var before := checks
		suite.run(self)
		if checks == before:
			check(false, "suite ran no checks (runtime error?): %s" % path)
	print("checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
