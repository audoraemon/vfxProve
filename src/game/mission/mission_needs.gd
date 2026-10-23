class_name MissionNeeds
extends RefCounted
## What each mission needs a town to have (v0.12): the names of Places.has(), one table so it is reviewed in one place.
## MissionDef.needs() reads it; tests/test_mission_needs.gd checks that every Places.rect/at/point(&"name") a mission's
## director reads is listed. A mission is hostable in a town that has all its needs (Places.can_host()) and either is its
## home city or has its overrides (MissionBook.hostable()). Rows for the other missions are filled by Task 3.

## The rows are plain string arrays: a PackedStringArray is not a constant expression. of() hands them out packed.
const TABLE := {
	# Tier 1 (spec 1.4). Every director reads the Temple (MissionDirector.lantern_door_in), so every row lists it.
	"warning": ["temple", "bell_tower"],
	"tax_collector": ["temple", "bell_tower", "citadel", "citadel_gate", "workshop"],
	"spoiled_harvest": ["citadel", "citadel_gate", "temple"],
	"lost_lamb": ["temple"],
	"first_prayers": ["temple", "bell_tower", "market_square"],
	# The Capital's sandbox is a bare town.
	"capital_sandbox": [],
}


## The needs of mission `id`; an error and none for an id the table does not know.
static func of(id: String) -> PackedStringArray:
	if not TABLE.has(id):
		push_error("MissionNeeds.of: no needs listed for '%s'" % id)
		return PackedStringArray()
	return PackedStringArray(TABLE[id])
