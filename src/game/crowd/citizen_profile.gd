class_name CitizenProfile
extends RefCounted
## Who a citizen is and where their day takes them (v0.04): a role, a home, a workplace for the roles that have one,
## and a few leisure spots near home. RoutineManager picks among these; Crowd.spawn() hands them out.

## WATCHMAN (v0.08): never dealt by SHARES -- The Warning's director appoints one at the Main Gate and sets his work.
## MAYOR and NOBLE (v0.09) are never dealt either: The Long Night's festival makes a merchant the Mayor, and the Prince's
## procession dresses the Prince as a noble.
enum Role { RESIDENT, MERCHANT, CRAFT, LABORER, CLERGY, CAREGIVER, FARMER, BELLKEEPER, ENGINEER, WATCHMAN, MAYOR, NOBLE }
## Where a citizen stands with the gods (v0.10, the campaign's Night 2): one of Halcyon's Faithful, who report the god
## at work; one of the grieving, who can be led to Mira's journal; or a Believer, who has read it.
enum Faith { NONE, FAITHFUL, GRIEVING, BELIEVER }

## Each role's share of the town (the v0.04 spec's table). Farmers work the fields and mills outside the walls.
const SHARES := [
	[Role.RESIDENT, 0.30], [Role.MERCHANT, 0.15], [Role.CRAFT, 0.15], [Role.LABORER, 0.08], [Role.CLERGY, 0.04],
	[Role.CAREGIVER, 0.18], [Role.FARMER, 0.10],
]
## Where each working role works (the city's anchors() kinds).
const WORK := {
	Role.MERCHANT: ["stall", "tavern"], Role.CRAFT: ["craft"], Role.LABORER: ["stall", "dock"],
	Role.CLERGY: ["cathedral"], Role.FARMER: ["field", "mill"], Role.BELLKEEPER: ["bell"], Role.ENGINEER: ["craft"],
}
## Where anyone spends leisure: the kinds, and how many of the nearest to home each citizen may pick from.
const LEISURE := ["plaza", "water", "tavern"]
const LEISURE_NEAREST := 5
## A workplace is one of this many of its kind nearest home (a farmer's farmhouse is the one nearest its field).
const WORK_NEAREST := 4
## A spawn-order stride through the town (coprime with any sensible crowd size), so the roles interleave.
const STRIDE := 97

var role := Role.RESIDENT
var home := Vector2.INF
## Vector2.INF for a role with no workplace.
var work := Vector2.INF
var leisure := PackedVector2Array()
## Family group (-1: none); used from v0.04's P1.
var family := -1
var faith := Faith.NONE


## The role of the `i`-th of `n` citizens: every role gets round(share * n) (the last takes the remainder), dealt in
## a strided order so neighbours in the spawn order differ.
static func role_for(i: int, n: int) -> Role:
	var slot := (i * STRIDE) % n
	var edge := 0
	for k in SHARES.size():
		edge = n if k == SHARES.size() - 1 else edge + roundi(float(SHARES[k][1]) * n)
		if slot < edge:
			return SHARES[k][0]
	return Role.RESIDENT


func works() -> bool:
	return work != Vector2.INF
