extends RefCounted
## Placeholder (Veil Task 1): registered in tests/run_all.gd now so the task that builds this replaces this file and never edits
## run_all.gd.


static func run(t) -> void:
	t.check(load("res://src/fx/veil/shadow_play.gd") != null, "stub loads")
