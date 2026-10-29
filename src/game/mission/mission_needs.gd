class_name MissionNeeds
extends RefCounted
## What each mission needs a town to have (v0.12): the names of Places.has(), one table so it is reviewed in one place.
## MissionDef.needs() reads it; tests/test_mission_needs.gd checks that every Places.rect/at/point(&"name") a mission's
## director reads is listed. A mission is hostable in a town that has all its needs (Places.can_host()) and either is its
## home city or has its overrides (MissionBook.hostable()). Every mission of MissionBook, the campaign, the board and the dev list has a row.

## The rows are plain string arrays: a PackedStringArray is not a constant expression. of() hands them out packed.
const TABLE := {
	# Tier 1 (spec 1.4). Every director reads the Temple (MissionDirector.lantern_door_in), so every row lists it.
	"warning": ["temple", "bell_tower"],
	"tax_collector": ["temple", "bell_tower", "citadel", "citadel_gate", "workshop"],
	"spoiled_harvest": ["citadel", "citadel_gate", "temple"],
	"lost_lamb": ["temple"],
	"first_prayers": ["temple", "bell_tower", "market_square"],
	# Tier 2: the Bell-Ringers' three towers (the bell's), the Festival's market (Market Panic), the Informer.
	"miras_house": ["temple"],
	"broken_lanterns": ["temple"],
	"bell_ringers": ["temple", "bell_tower"],
	"market_panic": ["temple", "market_square", "fountain"],
	"informer": ["temple"],
	# Tier 3: the granary and the gate towers (barns:4 = BARNS[3]); the sweep's districts (index 7 = eight of them).
	"vigil_flame": ["temple"],
	"festival": ["temple", "market_square", "fountain"],
	"crowns_bread": ["temple", "barns:4", "gate_towers:2"],
	"prisoner": ["temple"],
	"heretic_hunt": ["temple", "districts:8"],
	# Tier 4: the Procession's route, the Armoury's two taverns, two gate towers and barracks, the Sermon's third well.
	"procession": ["temple", "citadel", "citadel_court", "market_square", "dock", "dock_wait"],
	"bishop": ["temple"],
	"armoury": ["temple", "barracks", "taverns:2", "gate_towers:2"],
	"sermon": ["temple", "wells:3"],
	"relic_run": ["temple"],
	# Tier 5 and the three-act night (its acts: the Warning's, the Festival's, the Procession's and the Judgement's).
	"last_judgement": ["temple"],
	"long_night": ["temple", "bell_tower", "citadel", "citadel_court", "market_square", "fountain", "dock", "dock_wait"],
	"lantern_eye": ["temple"],
	"exodus": ["temple"],
	"heart_of_faith": ["temple"],
	# The campaign's Feast nights are the Long Night's acts as nights of their own.
	"feast_festival": ["temple", "market_square", "fountain"],
	"feast_procession": ["temple", "citadel", "citadel_court", "market_square", "dock", "dock_wait"],
	# The Awaken rite (god P3): Mira's shrine and the Temple's door.
	"first_taste": ["temple"],
	# The Capital's sandbox is a bare town.
	"capital_sandbox": [],
}


## The needs of mission `id`; an error and none for an id the table does not know.
static func of(id: String) -> PackedStringArray:
	if not TABLE.has(id):
		push_error("MissionNeeds.of: no needs listed for '%s'" % id)
		return PackedStringArray()
	return PackedStringArray(TABLE[id])
