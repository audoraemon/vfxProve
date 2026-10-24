class_name MisnamedCity
extends CapitalCity
## A test-only town (v0.12 M1 fix wave, C6): the Capital's answers under another id, whose overrides file is misnamed
## (tests/fixtures/misnamed_missions/tax.gd, not tax_collector.gd), so it has no overrides for any mission and hosts none.

const ID := &"fixture_misnamed"


func id() -> StringName:
	return ID


func missions_dir() -> String:
	return "res://tests/fixtures/misnamed_missions"
