extends SceneTree

const SUITES := [
	"res://tests/test_iso.gd",
	"res://tests/test_enemy_field.gd",
	"res://tests/test_fx_timeline.gd",
	"res://tests/test_sfx_catalog.gd",
	"res://tests/test_environment.gd",
	"res://tests/test_freeze.gd",
	"res://tests/test_structure_roles.gd",
	"res://tests/test_building_kinds.gd",
	"res://tests/test_town_layout.gd",
	"res://tests/test_citadel.gd",
	"res://tests/test_town.gd",
	"res://tests/test_power_book.gd",
	"res://tests/test_walk_grid.gd",
	"res://tests/test_person.gd",
	"res://tests/test_crowd.gd",
	"res://tests/test_stability.gd",
	"res://tests/test_rebuild.gd",
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
