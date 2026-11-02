class_name FixtureCity
extends CapitalCity
## A test-only town (v0.12 Task 4): the Capital's answers under another id, whose mission overrides live in
## tests/fixtures/town_missions. Tests register it with City.register() and unregister it at the end (never used by the game).

const ID := &"fixture"


func id() -> StringName:
	return ID


func missions_dir() -> String:
	return "res://tests/fixtures/town_missions"
