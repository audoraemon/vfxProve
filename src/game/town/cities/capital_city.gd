class_name CapitalCity
extends CityDef
## The capital: a river-port city about twice Aldermere's size (docs/superpowers/specs/2026-10-09-capital-city-design.md
## §1 and the district plan beside it). This is its geography: the map, the Great River and the harbour basin, the
## three bridges, the two wall rings with their gatehouses, the avenues and lanes, the districts, the exits and the
## dock; and its buildings (Task 7): every ChatGPT set on its blockout footprint (CapitalPlots), the town's own sets
## (the cathedral, barracks, taverns, smithy, workshop, carpenter, bell tower, stalls, farms) as Aldermere uses them,
## and the house blocks filled with cottages and townhouses (CapitalPlots.row()).
##
## Coordinates are ground cells, plan north = -y. The old town's wall ring (INNER) holds the Keep, the noble, civic and
## guild quarters, the Great Market and the old town houses; the river runs between it and the new town's ring
## (OUTER), crossed by two stone bridges and a footbridge, each landing at a gatehouse in both rings.

const MAP := Rect2(-40, -40, 80, 80)
## The Great River, a band across the whole map, and the harbour basin it widens into east of the old town.
const RIVER := Rect2(-40, 6, 80, 6)
const HARBOUR := Rect2(22, -2, 18, 20)
## The two wall rings: the old town's and the new town's.
const INNER := Rect2(-24, -30, 42, 34)
const OUTER := Rect2(-30, 12, 52, 22)
## Wall towers along each run, at these offsets from its middle (ring_wall_towers() leaves out those that would reach
## a corner).
const TOWER_AT := [-16.0, -8.0, 0.0, 8.0, 16.0]
## Where each ring's gatehouses stand (TownLayout.ring_gatehouse()): the old town's west gate, its three river gates at
## the bridges and its harbour gate; the new town's three river gates and the south barbican.
const INNER_GATES := [Vector2(-24, -13), Vector2(-14, 4), Vector2(4, 4), Vector2(14, 4), Vector2(18, -9)]
const OUTER_GATES := [Vector2(-14, 12), Vector2(4, 12), Vector2(14, 12), Vector2(7, 34)]
## The bridges, gate to gate across the river: the two stone bridges (bridge_stone's own 2.0 x 7.6 footprint) and the
## footbridge, laid as FOOTBRIDGE_SPANS lengths of the gpt_footbridge set (a set about two cells long) end to end.
const BRIDGES := [Rect2(-15, 4.2, 2.0, 7.6), Rect2(3, 4.2, 2.0, 7.6)]
const FOOTBRIDGE := Rect2(13.5, 4.2, 1.0, 7.6)
const FOOTBRIDGE_SPANS := 4
const BRIDGE_H := 6.0
## The harbour's ferry pier, out from the basin's north quay (a structure people walk onto, as Aldermere's dock), the
## quay where people wait for the ferry, and the ferry's landing: reaching it is an escape by water.
const DOCK := Rect2(29.5, -2.4, 3.0, 1.0)
const DOCK_H := 3.0
const DOCK_WAIT := Rect2(28.7, -5.6, 4.6, 3.0)
const FERRY_LANDING := Vector2(31.0, -2.9)
## The Citadel (Town builds one per city, citadel.gd) stands on the Royal Keep's hill, its paved court round it as
## at Aldermere (the same offsets from its origin).
const CITADEL_ORIGIN := Vector2(0, -25.5)
const CITADEL_COURT := Rect2(-2.9, -28.0, 5.8, 5.0)
## The Great Market's open square, east of the west bridge avenue (which runs between it and the west market) and
## clear of every street; its stalls stand in STALL_ROWS. The west market is a second, smaller square west of the
## avenue.
const MARKET_SQUARE := Rect2(-12.0, -6.0, 9.0, 7.0)
const WEST_MARKET := Rect2(-22.4, -4.0, 5.4, 4.6)
## The stall rows (each one stall deep: CapitalPlots.row() lays the stalls along it STALL_GAP apart): four in the
## square, west of its fountain, and three in the west market.
const STALL := Vector2(0.9, 0.7)
const STALL_GAP := 0.3
const STALL_ROWS := [
	Rect2(-11.7, -5.4, 5.4, 0.7), Rect2(-11.7, -3.9, 5.4, 0.7), Rect2(-11.7, -2.4, 5.4, 0.7), Rect2(-11.7, -0.9, 5.4, 0.7),
	Rect2(-22.1, -3.5, 4.8, 0.7), Rect2(-22.1, -2.0, 4.8, 0.7), Rect2(-22.1, -0.5, 4.8, 0.7),
]

## The town's own buildings, on the plots the plan gives them (spec §1), with Aldermere's footprints and heights.
## The Royal Keep: the barracks and their yard west of the Citadel.
const BARRACKS := Rect2(-7.8, -28.2, 4.4, 1.9)
const BARRACKS_YARD := Rect2(-7.8, -26.0, 4.4, 2.0)
## The cathedral square: the cathedral, its bell tower west of it (taller than the cathedral, so never in front of it).
const CATHEDRAL := Rect2(-6.0, -20.8, 4.2, 6.2)
const BELL_TOWER := Rect2(-8.6, -20.6, 1.1, 1.1)
const BELL_TOWER_H := 60.0
## Inns: the Great Market's (with its patio), the old town's and the harbour's.
const TAVERNS := [Rect2(-21.8, -7.7, 2.4, 1.5), Rect2(-1.0, -7.6, 2.4, 1.5), Rect2(21.5, -7.2, 2.4, 1.5)]
const TAVERN_PATIO := Rect2(-21.8, -6.0, 2.4, 0.42)
## The crafts quarter: the carpenter and his yard, the smithy and its yard, the workshop.
const CARPENTER := Rect2(-19.8, 13.6, 2.3, 1.15)
const CARPENTER_YARD := Rect2(-17.1, 13.9, 0.9, 0.7)
const SMITHY := Rect2(-23.8, 16.2, 1.5, 1.25)
const SMITHY_YARD := Rect2(-23.7, 17.65, 1.3, 0.55)
const WORKSHOP := Rect2(-21.5, 16.2, 2.6, 1.5)
## The farms: fields, farmhouses (Aldermere's barn) and the windmill, in the west farms and the south-east fields.
const FIELDS := [
	Rect2(-39.5, 13.0, 4.5, 3.4), Rect2(-34.6, 13.0, 3.6, 3.4), Rect2(-39.5, 17.0, 4.5, 3.4), Rect2(-39.5, 26.0, 4.5, 3.4),
	Rect2(-39.5, 30.0, 4.5, 3.4), Rect2(24.0, 27.0, 5.0, 3.4), Rect2(30.0, 27.0, 5.0, 3.4), Rect2(24.0, 31.0, 5.0, 3.4),
	Rect2(30.0, 31.0, 5.0, 3.4),
]
const BARNS := [Rect2(-34.0, 21.0, 1.3, 1.5), Rect2(28.0, 23.8, 1.3, 1.5)]
const WINDMILL := Rect2(-36.0, 23.0, 0.9, 0.9)
## The fountains (the Great Market's, the civic square's) and the wells.
const FOUNTAINS := [Rect2(-5.0, -3.0, 1.2, 1.2), Rect2(5.5, -17.0, 1.2, 1.2)]
const WELLS := [Rect2(-27.5, 19.6, 0.5, 0.5), Rect2(-16.5, 28.0, 0.5, 0.5), Rect2(16.0, 28.5, 0.5, 0.5),
	Rect2(9.0, 0.6, 0.5, 0.5)]
## Every ChatGPT plot: [set, its footprint's back corner]. The set's footprint and height come from CapitalPlots.SETS.
## By district (spec §1). The landmarks that must be seen (the Citadel's keep, the cathedral, the town hall, the market
## hall) have nothing taller just in front of them (tests/test_capital_plots.gd).
const GPT_PLOTS := [
	# Royal Keep: armoury and treasury before the barracks; a watchtower, the keep's drawbridge gatehouse and its
	# barbican east of the Citadel, clear of its front.
	[&"gpt_armoury", Vector2(-7.8, -23.5)], [&"gpt_treasury", Vector2(-5.0, -23.5)],
	[&"gpt_watchtower", Vector2(6.6, -28.2)], [&"gpt_drawbridge", Vector2(5.8, -26.6)],
	[&"gpt_barbican", Vector2(5.3, -22.4)],
	# The palace gardens north-west, inside the old town's wall: ice house, orchard.
	[&"gpt_icehouse", Vector2(-22.0, -27.8)], [&"gpt_orchard", Vector2(-19.4, -27.6)],
	# Noble quarter: the manor and its garden (pavilion, fishpond), library, school, patrician townhouses, and a
	# street of them between the west road and the cross avenue.
	[&"gpt_manor", Vector2(-22.3, -20.6)], [&"gpt_library", Vector2(-17.9, -20.6)], [&"gpt_school", Vector2(-15.0, -20.6)],
	[&"gpt_patrician", Vector2(-12.8, -20.6)], [&"gpt_patrician", Vector2(-11.6, -20.6)],
	[&"gpt_patrician", Vector2(-10.4, -20.6)], [&"gpt_pavilion", Vector2(-22.3, -17.6)],
	[&"gpt_fishpond", Vector2(-20.4, -17.4)],
	[&"gpt_patrician", Vector2(-19.0, -11.6)], [&"gpt_patrician", Vector2(-17.8, -11.6)],
	[&"gpt_patrician", Vector2(-16.6, -11.6)], [&"gpt_patrician", Vector2(-15.4, -11.6)],
	[&"gpt_patrician", Vector2(-14.2, -11.6)], [&"gpt_patrician", Vector2(-13.0, -11.6)],
	[&"gpt_patrician", Vector2(-11.8, -11.6)], [&"gpt_patrician", Vector2(-10.6, -11.6)],
	# Cathedral and civic square: town hall, courthouse and monument east of the cathedral, the jail and its notice
	# board west of it, alley steps down to the cross avenue.
	[&"gpt_townhall", Vector2(-1.2, -20.8)], [&"gpt_courthouse", Vector2(-1.0, -18.6)],
	[&"gpt_monument", Vector2(-0.6, -16.0)], [&"gpt_jail", Vector2(-8.7, -18.6)],
	[&"gpt_noticeboard", Vector2(-8.6, -16.5)], [&"gpt_alleysteps", Vector2(1.2, -11.5)],
	# Guild quarter: the guild hall, the weavers' hall, shop-houses.
	[&"gpt_guildhall", Vector2(9.0, -20.6)], [&"gpt_weavers", Vector2(11.0, -20.6)],
	[&"gpt_shophouse", Vector2(13.8, -20.6)], [&"gpt_shophouse", Vector2(15.2, -20.6)],
	# Great Market: the covered market hall at the square's head (only stalls in front of it), the weigh house, the
	# crier's stage by the west bridge avenue.
	[&"gpt_markethall", Vector2(-12.0, -7.7)], [&"gpt_weighhouse", Vector2(-6.2, -7.7)],
	[&"gpt_crierstage", Vector2(-16.4, -3.6)],
	# Old town houses: hospital, bathhouse, the cistern at the aqueduct's end.
	[&"gpt_hospital", Vector2(5.5, -7.6)], [&"gpt_bathhouse", Vector2(9.0, -7.6)], [&"gpt_cistern", Vector2(11.7, -7.6)],
	# Banks: wash houses on the north bank below the old town's wall, the sluice west of it.
	[&"gpt_washhouse", Vector2(-9.0, 4.44)], [&"gpt_washhouse", Vector2(7.5, 4.44)], [&"gpt_sluice", Vector2(-28.0, 4.15)],
	# Harbour district: the fish market by the harbour gate; the sets painted with water at their front (the dock
	# warehouses, the crane, the ferry landing) on the basin's north quay and the river's bank, their water side to the
	# water; the stables, a dockworkers' tenement and shop-houses behind the avenue.
	[&"gpt_fishmarket", Vector2(19.0, -7.0)], [&"gpt_warehouse", Vector2(22.5, -4.6)],
	[&"gpt_warehouse", Vector2(25.0, -4.6)], [&"gpt_crane", Vector2(33.8, -3.7)], [&"gpt_ferry", Vector2(36.6, -3.9)],
	[&"gpt_warehouse", Vector2(19.5, 3.9)], [&"gpt_stables", Vector2(19.0, -13.0)],
	[&"gpt_tenement", Vector2(22.5, -13.0)], [&"gpt_shophouse", Vector2(24.6, -13.0)],
	[&"gpt_shophouse", Vector2(26.1, -13.0)],
	# Northern woods: charcoal kilns, the aqueduct from the springs (a run of segments along x).
	[&"gpt_charcoal", Vector2(24.0, -35.0)], [&"gpt_charcoal", Vector2(31.0, -31.0)],
	[&"gpt_aqueduct", Vector2(19.0, -24.6)], [&"gpt_aqueduct", Vector2(20.2, -24.6)],
	[&"gpt_aqueduct", Vector2(21.4, -24.6)], [&"gpt_aqueduct", Vector2(22.6, -24.6)],
	[&"gpt_aqueduct", Vector2(23.8, -24.6)], [&"gpt_aqueduct", Vector2(25.0, -24.6)],
	[&"gpt_aqueduct", Vector2(26.2, -24.6)], [&"gpt_aqueduct", Vector2(27.4, -24.6)],
	# Crafts quarter: brewery, lumber yard, mason's yard (the carpenter beside them), cooper, potter (the smithy and the
	# workshop beside them), bakery and butcher by the west bridge's gate.
	[&"gpt_brewery", Vector2(-28.3, 13.6)], [&"gpt_lumberyard", Vector2(-25.2, 13.6)],
	[&"gpt_masonyard", Vector2(-22.4, 13.6)], [&"gpt_cooper", Vector2(-28.3, 16.2)],
	[&"gpt_potter", Vector2(-26.2, 16.2)], [&"gpt_bakery", Vector2(-12.5, 17.0)], [&"gpt_butcher", Vector2(-12.5, 19.2)],
	# New town: the chapel, row houses, shop-houses along the south road.
	[&"gpt_chapel", Vector2(-7.0, 13.6)], [&"gpt_rowhouses", Vector2(-7.0, 16.0)], [&"gpt_rowhouses", Vector2(-4.3, 16.0)],
	[&"gpt_rowhouses", Vector2(-1.6, 16.0)], [&"gpt_rowhouses", Vector2(-7.0, 18.6)],
	[&"gpt_rowhouses", Vector2(-4.3, 18.6)], [&"gpt_rowhouses", Vector2(-1.6, 18.6)],
	[&"gpt_shophouse", Vector2(1.4, 16.8)], [&"gpt_shophouse", Vector2(5.4, 16.8)], [&"gpt_shophouse", Vector2(6.8, 16.8)],
	# Tanners and dyers (downstream, east): tannery, dyers' works, glassworks.
	[&"gpt_tannery", Vector2(16.5, 13.6)], [&"gpt_dyers", Vector2(18.9, 13.6)], [&"gpt_glassworks", Vector2(16.5, 16.4)],
	# Poor quarter: tenements, shacks, latrines, a notice board.
	[&"gpt_tenement", Vector2(-28.3, 23.6)], [&"gpt_tenement", Vector2(-26.4, 23.6)],
	[&"gpt_tenement", Vector2(-24.5, 23.6)], [&"gpt_tenement", Vector2(-27.8, 31.0)],
	[&"gpt_shacks", Vector2(-21.0, 23.6)], [&"gpt_shacks", Vector2(-19.2, 23.6)], [&"gpt_shacks", Vector2(-10.6, 31.2)],
	[&"gpt_latrine", Vector2(-17.0, 23.6)], [&"gpt_latrine", Vector2(-8.6, 31.5)],
	[&"gpt_noticeboard", Vector2(-14.0, 23.6)],
	# Road quarter: the coaching inn, stables, livestock pens, the district gate, alley steps.
	[&"gpt_inn", Vector2(-3.0, 23.5)], [&"gpt_stables", Vector2(9.0, 23.5)], [&"gpt_pens", Vector2(12.0, 23.5)],
	[&"gpt_districtgate", Vector2(15.5, 23.5)], [&"gpt_alleysteps", Vector2(18.5, 23.5)],
	# Monastery hill: monastery, graveyard, chapel; the leper house far off; a wayside cross and a milestone by the west
	# road.
	[&"gpt_monastery", Vector2(-36.0, -36.0)], [&"gpt_graveyard", Vector2(-32.5, -36.0)],
	[&"gpt_chapel", Vector2(-36.0, -32.4)], [&"gpt_leperhouse", Vector2(-38.5, -26.0)],
	[&"gpt_waysidecross", Vector2(-30.0, -15.0)], [&"gpt_milestone", Vector2(-35.0, -11.7)],
	# West farms: a farmhouse and orchards by the fields.
	[&"gpt_farmhouse", Vector2(-34.5, 17.5)], [&"gpt_orchard", Vector2(-34.4, 26.4)], [&"gpt_orchard", Vector2(-32.6, 26.4)],
	# South-east fields: vineyard rows, beehives, dovecote, granary, orchards, a farmhouse.
	[&"gpt_vineyard", Vector2(24.0, 20.0)], [&"gpt_vineyard", Vector2(26.2, 20.0)], [&"gpt_vineyard", Vector2(28.4, 20.0)],
	[&"gpt_vineyard", Vector2(24.0, 21.5)], [&"gpt_vineyard", Vector2(26.2, 21.5)], [&"gpt_vineyard", Vector2(28.4, 21.5)],
	[&"gpt_beehives", Vector2(31.0, 20.0)], [&"gpt_dovecote", Vector2(33.5, 20.0)], [&"gpt_granary", Vector2(35.0, 20.0)],
	[&"gpt_orchard", Vector2(31.0, 23.0)], [&"gpt_orchard", Vector2(33.0, 23.0)], [&"gpt_farmhouse", Vector2(36.0, 23.0)],
	# Suburbs and gallows hill: huts, the gallows.
	[&"gpt_gallows", Vector2(-26.0, 36.0)], [&"gpt_hut", Vector2(-20.0, 35.5)], [&"gpt_hut", Vector2(-18.0, 35.5)],
	[&"gpt_hut", Vector2(-16.0, 35.5)], [&"gpt_hut", Vector2(-11.0, 36.5)], [&"gpt_hut", Vector2(-9.0, 36.5)],
	[&"gpt_hut", Vector2(-2.0, 35.5)],
	# Tournament field: grandstand, the tilt barrier (a run of segments along x), a play stage.
	[&"gpt_grandstand", Vector2(12.0, 35.0)], [&"gpt_tiltbarrier", Vector2(10.0, 37.5)],
	[&"gpt_tiltbarrier", Vector2(11.2, 37.5)], [&"gpt_tiltbarrier", Vector2(12.4, 37.5)],
	[&"gpt_tiltbarrier", Vector2(13.6, 37.5)], [&"gpt_tiltbarrier", Vector2(14.8, 37.5)],
	[&"gpt_playstage", Vector2(18.0, 35.5)],
]
## The craft sets whose fronts are workplaces (anchors' "craft").
const CRAFTS := [&"gpt_bakery", &"gpt_butcher", &"gpt_brewery", &"gpt_tannery", &"gpt_dyers", &"gpt_weavers",
	&"gpt_potter", &"gpt_cooper", &"gpt_masonyard", &"gpt_lumberyard", &"gpt_glassworks"]
## How each walled district's house blocks are filled (CapitalPlots.row()): [plot, gap, townhouses]. Districts not
## listed (the Royal Keep, the cathedral square) take no houses.
const HOUSING := {
	&"noble_quarter": [Vector2(1.3, 0.95), 1.2, true], &"guild_quarter": [Vector2(1.3, 0.95), 0.8, true],
	&"great_market": [Vector2(1.3, 0.95), 0.8, true], &"old_town_houses": [Vector2(1.3, 0.95), 0.6, true],
	&"crafts_quarter": [Vector2(0.95, 0.75), 0.7, false], &"new_town": [Vector2(1.3, 0.95), 0.8, true],
	&"tanners_dyers": [Vector2(0.95, 0.75), 0.9, false], &"poor_quarter": [Vector2(0.95, 0.75), 0.6, false],
	&"road_quarter": [Vector2(0.95, 0.75), 0.7, false],
}
## How far a house keeps from every other building, yard and square, and from the streets; how far inside its ring's
## wall (Aldermere's WALL_T + WALL_CLEAR).
const HOUSE_CLEAR := 0.5
const HOUSE_STREET_CLEAR := 0.5
const HOUSE_WALL_CLEAR := 1.7
## Avenues (2 cells wide) and lanes (1 cell), as axis-aligned polylines: roads() turns each segment into a street rect.
const AVENUE_W := 2.0
const LANE_W := 1.0
const AVENUES := [
	# The south road: from the map's south edge through the barbican, over the east stone bridge, up to the Keep.
	[Vector2(7, 40), Vector2(7, 27), Vector2(4, 27), Vector2(4, -21)],
	# The west road: from the map's west edge through the west gate to the cathedral square.
	[Vector2(-40, -13), Vector2(4, -13)],
	# The cross avenue between the upper quarters and the market and old town, out through the harbour gate.
	[Vector2(-22, -9), Vector2(34, -9)],
	# The west bridge avenue: from the cross avenue through the market, over the west stone bridge, into the new town.
	[Vector2(-14, -9), Vector2(-14, 22)],
	# The new town's avenue, between its upper and lower quarters.
	[Vector2(-28, 22), Vector2(20, 22)],
]
const LANES := [
	# Over the footbridge, from the cross avenue to the new town avenue.
	[Vector2(14, -9), Vector2(14, 22)],
	# From the cross avenue down to the harbour's ferry quay.
	[Vector2(31, -9), Vector2(31, -3)],
	# Between the cathedral square and the guild quarter; between the market and the old town houses.
	[Vector2(8, -20), Vector2(8, -9)],
	[Vector2(-2, -9), Vector2(-2, 2)],
	# The new town's quarter lanes, and the lane between the poor quarter and the road quarter.
	[Vector2(-8, 13.5), Vector2(-8, 21)],
	[Vector2(10, 13.5), Vector2(10, 21)],
	[Vector2(-4, 23), Vector2(-4, 32.5)],
]
## Every area of the district plan (spec §1): name, rect, kind. &"old_town" lies in the old town's wall ring,
## &"new_town" in the new town's, &"outside" beyond both.
const DISTRICT_TABLE := [
	[&"royal_keep", Rect2(-8, -30, 16, 9), &"old_town"],
	[&"noble_quarter", Rect2(-24, -21, 15, 12), &"old_town"],
	[&"cathedral_square", Rect2(-9, -21, 17, 12), &"old_town"],
	[&"guild_quarter", Rect2(8, -21, 10, 12), &"old_town"],
	[&"great_market", Rect2(-24, -9, 22, 13), &"old_town"],
	[&"old_town_houses", Rect2(-2, -9, 20, 13), &"old_town"],
	[&"harbour_district", Rect2(18, -22, 22, 20), &"outside"],
	[&"crafts_quarter", Rect2(-30, 12, 22, 10), &"new_town"],
	[&"new_town", Rect2(-8, 12, 18, 10), &"new_town"],
	[&"tanners_dyers", Rect2(10, 12, 12, 10), &"new_town"],
	[&"poor_quarter", Rect2(-30, 22, 26, 12), &"new_town"],
	[&"road_quarter", Rect2(-4, 22, 26, 12), &"new_town"],
	[&"monastery_hill", Rect2(-40, -40, 16, 28), &"outside"],
	[&"northern_woods", Rect2(14, -40, 26, 18), &"outside"],
	[&"west_farms", Rect2(-40, 12, 10, 28), &"outside"],
	[&"south_east_fields", Rect2(22, 18, 18, 22), &"outside"],
	[&"suburbs", Rect2(-30, 34, 36, 6), &"outside"],
	[&"tournament_field", Rect2(6, 34, 16, 6), &"outside"],
]
## A house block narrower than this either way is left as street.
const BLOCK_MIN := 1.0
## How deep the cobbled queue ground inside each gatehouse is, and its gap from the gate towers.
const GATE_PLAZA := Vector2(3.6, 2.6)
const GATE_PLAZA_GAP := 0.6


func id() -> StringName:
	return &"capital"


func map() -> Rect2:
	return MAP


## The old town's wall ring: the walled core the crowd's patrols and the floor's cobbles keep to.
func town() -> Rect2:
	return INNER


func rivers() -> Array[Rect2]:
	return [RIVER, HARBOUR]


## Every avenue's and lane's segments as street rects, each segment grown by half its width at both ends so the
## corners join, and cut to the map.
func roads() -> Array:
	var out: Array = []
	for line: Array in AVENUES:
		_segments(out, line, AVENUE_W)
	for line: Array in LANES:
		_segments(out, line, LANE_W)
	return out


## The road polylines themselves: {points, width}, avenues first.
func road_lines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line: Array in AVENUES:
		out.append({"points": line.duplicate(), "width": AVENUE_W})
	for line: Array in LANES:
		out.append({"points": line.duplicate(), "width": LANE_W})
	return out


## Where an escape ends: the south road and the west road at the map's edge, and the harbour's ferry landing.
func exits() -> Array[Vector2]:
	return [Vector2(7, 39.6), Vector2(-39.6, -13), FERRY_LANDING]


## The house blocks, as Aldermere's districts are: each walled district of the plan (district_table(), spec §1) less
## its streets, in DISTRICT_TABLE order; slivers under BLOCK_MIN across are left as street. The floor paints them as
## worn ground between the cobbled streets, and the alarms count a local emergency per block.
func districts() -> Array:
	var out: Array = []
	for row: Array in DISTRICT_TABLE:
		if row[2] != &"outside":
			out.append_array(_blocks(row[1]))
	return out


## Every area of the district plan: {name, rect, kind}.
func district_table() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Array in DISTRICT_TABLE:
		out.append({"name": row[0], "rect": row[1], "kind": row[2]})
	return out


## Every structure: the walls, towers and gatehouses of both rings (old town first), then the buildings (buildings()),
## the stalls and the houses, then the bridges and the dock last (so Town's `bridge` is still the last footbridge span).
## The seeds come from the field's own generator in this order.
func structures() -> Array[Dictionary]:
	if _structures.is_empty():
		var out: Array[Dictionary] = _ring_structures().duplicate(true)
		out.append_array(_buildings())
		for r: Rect2 in stalls():
			out.append({"rect": r, "height": 10.0, "kind": Structure.Kind.MARKET_STALL, "role": &"market", "tag": &""})
		var hs := houses()
		for i in hs.size():
			if _townhouse.get(hs[i], false):
				out.append({"rect": hs[i], "height": 28.0 + float(i * 7 % 3), "kind": Structure.Kind.HOUSE,
					"role": &"house", "tag": &"townhouse"})
			else:
				out.append({"rect": hs[i], "height": 15.0 + float(i * 7 % 5), "kind": Structure.Kind.HOUSE,
					"role": &"house", "tag": &""})
		for r: Rect2 in BRIDGES:
			out.append({"rect": r, "height": BRIDGE_H, "kind": Structure.Kind.BRIDGE, "role": &"bridge", "tag": &"stone"})
		var span := FOOTBRIDGE.size.y / FOOTBRIDGE_SPANS
		for k in FOOTBRIDGE_SPANS:
			out.append({"rect": Rect2(FOOTBRIDGE.position.x, FOOTBRIDGE.position.y + span * k, FOOTBRIDGE.size.x, span),
				"height": BRIDGE_H, "kind": Structure.Kind.BRIDGE, "role": &"bridge", "tag": &"gpt_footbridge"})
		out.append({"rect": DOCK, "height": DOCK_H, "kind": Structure.Kind.BRIDGE, "role": &"dock", "tag": &"dock"})
		_structures = out
	return _structures.duplicate(true)


## The houses: each listed district's house blocks (HOUSING) filled by CapitalPlots.row() with its cottages or
## townhouses, every house kept HOUSE_CLEAR from the other buildings, the stalls, yards, squares, gate plazas, fountains
## and wells, HOUSE_STREET_CLEAR from the streets and HOUSE_WALL_CLEAR inside its ring's wall. Worked out once.
func houses() -> Array[Rect2]:
	if _houses.is_empty():
		var keep_off: Array[Rect2] = []
		for d: Dictionary in _ring_structures() + _buildings():
			keep_off.append((d.rect as Rect2).grow(HOUSE_CLEAR))
		for r: Rect2 in stalls() + _fixed_ground():
			keep_off.append(r.grow(HOUSE_CLEAR))
		for r: Rect2 in roads():
			keep_off.append(r.grow(HOUSE_STREET_CLEAR))
		var inside: Array[Rect2] = [INNER.grow(-HOUSE_WALL_CLEAR), OUTER.grow(-HOUSE_WALL_CLEAR)]
		var n := 0
		for row: Array in DISTRICT_TABLE:
			var style: Array = HOUSING.get(row[0], [])
			if style.is_empty():
				continue
			for block: Rect2 in _blocks(row[1]):
				n += 1
				for h: Rect2 in CapitalPlots.row(block.grow(-HOUSE_STREET_CLEAR), style[0], style[1], n):
					var ok := inside[0].encloses(h) or inside[1].encloses(h)
					for k: Rect2 in keep_off:
						ok = ok and not k.intersects(h)
					if ok:
						_houses.append(h)
						_townhouse[h] = style[2]
	return _houses.duplicate()


## The market stalls: each of STALL_ROWS laid with stalls (CapitalPlots.row()), in row order.
func stalls() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i in STALL_ROWS.size():
		out.append_array(CapitalPlots.row(STALL_ROWS[i], STALL, STALL_GAP, i + 1))
	return out


func fields() -> Array[Rect2]:
	return _typed(FIELDS)


func fountains() -> Array[Rect2]:
	return _typed(FOUNTAINS)


func wells() -> Array[Rect2]:
	return _typed(WELLS)


func taverns() -> Array[Rect2]:
	return _typed(TAVERNS)


## Ground people walk round besides the buildings: the working yards (the tavern's patio, the smithy's and the
## carpenter's yards), as at Aldermere.
func blockers() -> Array[Rect2]:
	return [TAVERN_PATIO, SMITHY_YARD, CARPENTER_YARD]


## Where citizens go about their day, by kind, as Aldermere's anchors (TownLayout.anchors()): "home" in front of each
## house and of the ChatGPT sets people live in (CapitalPlots.HOMES), "stall" before each stall, "craft" at the smithy's
## and carpenter's yards, the workshop and each craft set (CRAFTS), "tavern" at the inns, "cathedral" on its steps,
## "plaza" the squares' and gate plazas' quarter points, "water" by the fountains and wells, "field", "mill", "dock",
## "barn" (the farmhouses) and "bell" (the bell tower's foot).
func anchors() -> Dictionary:
	var out := {"home": [], "stall": [], "craft": [], "tavern": [], "cathedral": [], "plaza": [], "water": [],
		"field": [], "mill": [], "dock": [], "barn": [], "bell": []}
	for h: Rect2 in houses():
		out.home.append(Vector2(h.get_center().x, h.end.y + 0.35))
	for d: Dictionary in _buildings():
		var r: Rect2 = d.rect
		if d.tag in CapitalPlots.HOMES:
			out.home.append(Vector2(r.get_center().x, r.end.y + 0.35))
		elif d.tag in CRAFTS:
			out.craft.append(Vector2(r.get_center().x, r.end.y + 0.35))
		elif d.tag == &"gpt_inn":
			out.tavern.append(Vector2(r.get_center().x, r.end.y + 0.4))
	for st: Rect2 in stalls():
		out.stall.append(Vector2(st.get_center().x, st.end.y + 0.3))
	for r: Rect2 in [SMITHY_YARD, WORKSHOP, CARPENTER_YARD]:
		out.craft.append(Vector2(r.get_center().x, r.end.y + 0.35))
	for t: Rect2 in TAVERNS:
		out.tavern.append(Vector2(t.get_center().x, t.end.y + 0.4))
	for k in 3:
		out.cathedral.append(Vector2(CATHEDRAL.position.x + 0.8 + k * 1.3, CATHEDRAL.end.y + 0.4))
	var squares: Array[Rect2] = [MARKET_SQUARE, WEST_MARKET]
	squares.append_array(gate_plazas())
	for pl: Rect2 in squares:
		for k in 4:
			out.plaza.append(pl.position + pl.size * Vector2(0.25 + 0.5 * (k % 2), 0.25 + 0.5 * (k / 2)))
	for w: Rect2 in fountains() + wells():
		out.water.append(Vector2(w.get_center().x, w.end.y + 0.3))
		out.water.append(Vector2(w.end.x + 0.3, w.get_center().y))
	for f: Rect2 in FIELDS:
		out.field.append(Vector2(f.get_center().x, f.end.y + 0.3))
	out.mill.append(Vector2(WINDMILL.get_center().x, WINDMILL.end.y + 0.4))
	out.dock.append(Vector2(DOCK.get_center().x, DOCK.position.y - 0.4))
	for b: Rect2 in BARNS:
		out.barn.append(Vector2(b.get_center().x, b.end.y + 0.4))
	out.bell.append(Vector2(BELL_TOWER.position.x - 0.45, BELL_TOWER.get_center().y))
	return out


## Torch posts: the market square's four corners first (TownDecor strings bunting between them), then two inside
## every gatehouse, as at Aldermere's gates.
func torches() -> Array[Vector2]:
	var m := MARKET_SQUARE
	var out: Array[Vector2] = [m.position - Vector2(0.3, 0.3), Vector2(m.end.x + 0.1, m.position.y - 0.3),
		Vector2(m.position.x - 0.3, m.end.y + 0.1), m.end + Vector2(0.1, 0.1)]
	for ring: Array in _rings():
		for at: Vector2 in ring[1]:
			var inward := _inward(ring[0], at)
			var mid := _wall_mid(ring[0], at)
			if inward.y != 0.0:
				out.append(Vector2(mid.x - 1.4, mid.y + inward.y * 1.25))
				out.append(Vector2(mid.x + 1.2, mid.y + inward.y * 1.25))
			else:
				out.append(Vector2(mid.x + inward.x * 1.25, mid.y - 1.4))
				out.append(Vector2(mid.x + inward.x * 1.25, mid.y + 1.2))
	return out


## The cobbled queue ground inside each gatehouse, in gate order (old town's gates, then the new town's).
func gate_plazas() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var off := WALL_TOWER_HALF + GATE_PLAZA_GAP
	for ring: Array in _rings():
		for at: Vector2 in ring[1]:
			var inward := _inward(ring[0], at)
			var mid := _wall_mid(ring[0], at)
			if inward.y != 0.0:
				var y0 := mid.y + off if inward.y > 0.0 else mid.y - off - GATE_PLAZA.y
				out.append(Rect2(mid.x - GATE_PLAZA.x * 0.5, y0, GATE_PLAZA.x, GATE_PLAZA.y))
			else:
				var x0 := mid.x + off if inward.x > 0.0 else mid.x - off - GATE_PLAZA.y
				out.append(Rect2(x0, mid.y - GATE_PLAZA.x * 0.5, GATE_PLAZA.y, GATE_PLAZA.x))
	return out


func citadel_origin() -> Vector2:
	return CITADEL_ORIGIN


## A named place: the water, the bridges and dock, the squares, the walls and gates, the districts (spec §1), and the
## capital's own buildings under the names shared code asks Aldermere for (the temple is the cathedral; the barracks,
## workshop, smithy, carpenter, their yards, the tavern's patio, the bell tower and the windmill are its own). Rect2()
## for a name it has no equivalent of (river_west, watermill: their callers check has_area()). Worked out once.
func landmark(name: StringName) -> Rect2:
	if _landmarks.is_empty():
		var inner: Array[Rect2] = _gatehouses(INNER, INNER_GATES).gates
		var outer: Array[Rect2] = _gatehouses(OUTER, OUTER_GATES).gates
		_landmarks = {
			&"river": RIVER, &"harbour": HARBOUR, &"bridge": BRIDGES[1], &"footbridge": FOOTBRIDGE, &"dock": DOCK,
			&"dock_wait": DOCK_WAIT, &"market_square": MARKET_SQUARE, &"west_market": WEST_MARKET,
			&"citadel_court": CITADEL_COURT, &"old_town_wall": INNER, &"new_town_wall": OUTER,
			&"west_gate": inner[0], &"harbour_gate": inner[4], &"barbican": outer[3], &"main_gate": outer[3],
			&"temple": CATHEDRAL, &"barracks": BARRACKS, &"barracks_yard": BARRACKS_YARD, &"workshop": WORKSHOP,
			&"smithy": SMITHY, &"smithy_yard": SMITHY_YARD, &"carpenter": CARPENTER, &"carpenter_yard": CARPENTER_YARD,
			&"tavern_patio": TAVERN_PATIO, &"bell_tower": BELL_TOWER, &"windmill": WINDMILL,
		}
		for row: Array in DISTRICT_TABLE:
			_landmarks[row[0]] = row[1]
	return _landmarks.get(name, Rect2())


func floor_areas() -> Dictionary:
	var building_yards: Array[Rect2] = [CATHEDRAL.grow(0.35), SMITHY.grow(0.3), WORKSHOP.grow(0.3), CARPENTER.grow(0.3),
		CARPENTER_YARD.grow(0.2)]
	for t: Rect2 in TAVERNS:
		building_yards.append(t.grow(0.3))
	var farm := _typed(BARNS)
	farm.append(WINDMILL)
	var plazas: Array[Rect2] = [MARKET_SQUARE, WEST_MARKET, CITADEL_COURT]
	var yards: Array[Rect2] = [BARRACKS_YARD]
	return {
		&"plazas": plazas, &"yards": yards, &"gate_plazas": gate_plazas(),
		&"building_yards": building_yards, &"farm": farm,
		&"paved": [OUTER.grow(-TownLayout.WALL_T)] as Array[Rect2],
	}


# --- Helpers ---------------------------------------------------------------------------------------------

const WALL_TOWER_HALF := TownLayout.WALL_TOWER * 0.5

## Worked out once (the layout is constant): the structures, the houses (and which are townhouses), the buildings,
## the rings' pieces and the landmarks.
static var _structures: Array[Dictionary] = []
static var _houses: Array[Rect2] = []
static var _townhouse := {}
static var _buildings_cache: Array[Dictionary] = []
static var _rings_cache: Array[Dictionary] = []
static var _landmarks := {}


## The walls, towers and gatehouses of both rings, old town first.
func _ring_structures() -> Array[Dictionary]:
	if _rings_cache.is_empty():
		var streets := roads()
		for ring: Array in _rings():
			var g := _gatehouses(ring[0], ring[1])
			_rings_cache.append_array(TownLayout.ring_structures(ring[0], streets, g.towers, g.gates, TOWER_AT))
	return _rings_cache


## The buildings on their plots: the town's own sets (as Aldermere builds them: the cathedral, the barracks, the
## taverns, smithy, workshop, carpenter, the bell tower, the farms), then every ChatGPT plot (CapitalPlots.plot()).
func _buildings() -> Array[Dictionary]:
	if _buildings_cache.is_empty():
		var out: Array[Dictionary] = []
		out.append({"rect": CATHEDRAL, "height": 56.0, "kind": Structure.Kind.TEMPLE, "role": &"temple",
			"tag": &"cathedral"})
		out.append({"rect": BARRACKS, "height": 36.0, "kind": Structure.Kind.BARRACKS, "role": &"barracks", "tag": &""})
		for r: Rect2 in TAVERNS:
			out.append({"rect": r, "height": 30.0, "kind": Structure.Kind.HOUSE, "role": &"house", "tag": &"tavern"})
		out.append({"rect": SMITHY, "height": 20.0, "kind": Structure.Kind.HOUSE, "role": &"house", "tag": &"smithy"})
		out.append({"rect": WORKSHOP, "height": 22.0, "kind": Structure.Kind.HOUSE, "role": &"house", "tag": &"workshop"})
		out.append({"rect": CARPENTER, "height": 20.0, "kind": Structure.Kind.HOUSE, "role": &"house",
			"tag": &"carpenter"})
		out.append({"rect": BELL_TOWER, "height": BELL_TOWER_H, "kind": Structure.Kind.KEEP, "role": &"tower",
			"tag": &"bell_tower"})
		for r: Rect2 in FIELDS:
			out.append({"rect": r, "height": 3.0, "kind": Structure.Kind.FARM_FIELD, "role": &"farm", "tag": &""})
		for r: Rect2 in BARNS:
			out.append({"rect": r, "height": 20.0, "kind": Structure.Kind.HOUSE, "role": &"farm", "tag": &""})
		out.append({"rect": WINDMILL, "height": 60.0, "kind": Structure.Kind.HOUSE, "role": &"farm", "tag": &"windmill"})
		for p: Array in GPT_PLOTS:
			out.append(CapitalPlots.plot(p[0], p[1]))
		_buildings_cache = out
	return _buildings_cache


## The open ground no house may take: the squares, yards, patios, gate plazas, the Citadel's court and its whole
## footprint, the fountains and the wells.
func _fixed_ground() -> Array[Rect2]:
	var out: Array[Rect2] = [MARKET_SQUARE, WEST_MARKET, CITADEL_COURT, BARRACKS_YARD, TAVERN_PATIO, SMITHY_YARD,
		CARPENTER_YARD]
	out.append_array(gate_plazas())
	out.append_array(fountains())
	out.append_array(wells())
	return out


## The rect `area` less every street, slivers under BLOCK_MIN across left out.
func _blocks(area: Rect2) -> Array[Rect2]:
	var pieces: Array[Rect2] = [area]
	for road: Rect2 in roads():
		var next: Array[Rect2] = []
		for r: Rect2 in pieces:
			next.append_array(_minus(r, road))
		pieces = next
	var out: Array[Rect2] = []
	for r: Rect2 in pieces:
		if r.size.x >= BLOCK_MIN and r.size.y >= BLOCK_MIN:
			out.append(r)
	return out


static func _typed(src: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.assign(src)
	return out


## Each ring with its gate points: [rect, gate points].
func _rings() -> Array:
	return [[INNER, INNER_GATES], [OUTER, OUTER_GATES]]


## The ring's gatehouses at `points`: {gates, towers}, both Array[Rect2], the towers in gate order.
func _gatehouses(ring: Rect2, points: Array) -> Dictionary:
	var gates: Array[Rect2] = []
	var towers: Array[Rect2] = []
	for at: Vector2 in points:
		var g := TownLayout.ring_gatehouse(ring, at)
		gates.append(g.gate)
		towers.append_array(g.towers)
	return {"gates": gates, "towers": towers}


## The middle of the ring's wall band at the gate point `at` (on the side nearest it).
func _wall_mid(ring: Rect2, at: Vector2) -> Vector2:
	var g: Rect2 = TownLayout.ring_gatehouse(ring, at).gate
	return g.get_center()


## The unit step from the gate at `at` into the ring.
func _inward(ring: Rect2, at: Vector2) -> Vector2:
	var g: Rect2 = TownLayout.ring_gatehouse(ring, at).gate
	if g.size.x > g.size.y:
		return Vector2(0.0, 1.0 if g.get_center().y < ring.get_center().y else -1.0)
	return Vector2(1.0 if g.get_center().x < ring.get_center().x else -1.0, 0.0)


## `r` less `cut`: up to four rects (the strips above and below the cut across r's width, then those left and right of
## it); `r` itself when they do not meet.
static func _minus(r: Rect2, cut: Rect2) -> Array[Rect2]:
	if not r.intersects(cut):
		return [r]
	var out: Array[Rect2] = []
	var c := r.intersection(cut)
	if c.position.y > r.position.y:
		out.append(Rect2(r.position.x, r.position.y, r.size.x, c.position.y - r.position.y))
	if c.end.y < r.end.y:
		out.append(Rect2(r.position.x, c.end.y, r.size.x, r.end.y - c.end.y))
	if c.position.x > r.position.x:
		out.append(Rect2(r.position.x, c.position.y, c.position.x - r.position.x, c.size.y))
	if c.end.x < r.end.x:
		out.append(Rect2(c.end.x, c.position.y, r.end.x - c.end.x, c.size.y))
	return out


## Appends the polyline's segments as street rects `width` wide.
func _segments(out: Array, line: Array, width: float) -> void:
	for k in line.size() - 1:
		var a: Vector2 = line[k]
		var b: Vector2 = line[k + 1]
		var r := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs()).grow(width * 0.5)
		out.append(r.intersection(MAP))
