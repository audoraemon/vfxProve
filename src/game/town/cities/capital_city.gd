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
## (OUTER), crossed by three stone bridges, each landing at a gatehouse in both rings.

const MAP := Rect2(-40, -40, 80, 80)
## The border band drawn past the map's edge (border(), polish 3): distant meadow and woods, the river and the harbour
## basin carried out through it.
const BORDER := 12.0
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
## The bridges, gate to gate across the river, each the stone bridge set on its own 2.0 x 7.6 footprint: the west and
## east bridges on the avenues, and the third (polish 1: once gpt_footbridge spans) on a lane, the minor crossing.
const BRIDGES := [Rect2(-15, 4.2, 2.0, 7.6), Rect2(3, 4.2, 2.0, 7.6), Rect2(13, 4.2, 2.0, 7.6)]
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
## The farms: fields, farmhouses (Aldermere's barn) and the windmill, in the west farms and the south-east fields;
## and (polish 3) two fields and a barn in the suburbs beside gallows hill, one more field and barn at the west farms'
## south end, two more fields and a barn at the south-east fields' south end.
const FIELDS := [
	Rect2(-39.5, 13.0, 4.5, 3.4), Rect2(-34.6, 13.0, 3.6, 3.4), Rect2(-39.5, 17.0, 4.5, 3.4), Rect2(-39.5, 26.0, 4.5, 3.4),
	Rect2(-39.5, 30.0, 4.5, 3.4), Rect2(24.0, 27.0, 5.0, 3.4), Rect2(30.0, 27.0, 5.0, 3.4), Rect2(24.0, 31.0, 5.0, 3.4),
	Rect2(30.0, 31.0, 5.0, 3.4),
	Rect2(-24.4, 35.0, 4.0, 2.7), Rect2(-19.8, 35.0, 4.0, 2.7), Rect2(-39.5, 34.2, 4.5, 3.2), Rect2(24.4, 37.0, 4.0, 2.4),
	Rect2(31.0, 36.6, 4.5, 3.0),
]
const BARNS := [Rect2(-34.0, 21.0, 1.3, 1.5), Rect2(28.0, 23.8, 1.3, 1.5), Rect2(-15.0, 35.2, 1.3, 1.5),
	Rect2(-38.4, 37.9, 1.3, 1.5), Rect2(36.4, 36.8, 1.3, 1.5)]
const WINDMILL := Rect2(-36.0, 23.0, 0.9, 0.9)
## The fountains (the Great Market's, the civic square's) and the wells.
const FOUNTAINS := [Rect2(-5.0, -3.0, 1.2, 1.2), Rect2(5.5, -17.0, 1.2, 1.2)]
const WELLS := [Rect2(-27.5, 19.6, 0.5, 0.5), Rect2(-16.5, 28.0, 0.5, 0.5), Rect2(16.0, 28.5, 0.5, 0.5),
	Rect2(9.0, 0.6, 0.5, 0.5), KEEP_YARD_WELL, PLAZA_WELL, SUBURB_WELL]
## The suburbs' hamlet well (polish 3), on its little square between the huts.
const SUBURB_WELL := Rect2(-4.3, 37.1, 0.5, 0.5)
## Gallows hill (polish 3): the gallows on a rocky outcrop at the suburbs' west end (OUTCROPS).
const GALLOWS_HILL := Vector2(-26.8, 36.0)
## The tournament field (polish 3): the tilt yard's fences either side of the tilt barrier, and gear by the play stage.
const LISTS_DECOR := [
	[Decor.Kind.FENCE, Vector2(9.4, 36.5), Vector2(6.4, 0.0)], [Decor.Kind.FENCE, Vector2(9.4, 37.7), Vector2(6.4, 0.0)],
	[Decor.Kind.BARREL, Vector2(16.6, 37.3), Vector2.ZERO], [Decor.Kind.BARREL, Vector2(16.95, 37.45), Vector2.ZERO],
	[Decor.Kind.CRATES, Vector2(18.7, 37.1), Vector2.ZERO],
]
## The Keep's courtyard (polish 1): the paved yard inside the old town's north-west walls, between the wall patrols'
## loop and the noble quarter, the barracks at its east end. Its west half is the royal garden: lawn, gravel paths
## crossing at a fountain, hedges, flower beds, benches and trees (court_decor()), the monument and the pavilion
## (GPT_PLOTS); the townsfolk do not draw water there. Its east half is the garrison's drill yard, left paved: the
## practice dummies (scarecrows: batch 4 has no dummy, target or weapon rack), barrels, crates, logs and a table, and
## DRILL_SPOTS, where the last of the Keep's yard posts stand facing a dummy.
const KEEP_COURT := Rect2(-23.3, -29.3, 15.1, 8.3)
const ROYAL_GARDEN := Rect2(-21.8, -27.8, 6.2, 6.4)
const DRILL_YARD := Rect2(-15.0, -27.8, 6.6, 6.4)
const GARDEN_FOUNTAIN := Rect2(-19.3, -25.2, 1.2, 1.2)
## The gravel paths: the four arms of the garden's cross from the fountain (the east arm runs on into the drill yard),
## and their width.
const GARDEN_PATHS := [
	[Vector2(-21.6, -24.6), Vector2(-19.6, -24.6)], [Vector2(-17.8, -24.6), Vector2(-15.2, -24.6)],
	[Vector2(-18.7, -25.5), Vector2(-18.7, -26.2)], [Vector2(-18.7, -23.7), Vector2(-18.7, -21.3)],
]
const GARDEN_PATH_W := 0.26
## The garden's pieces: [kind, at, size]. Hedges (bushes) along its north, west and east edges, flower beds, benches
## either side of its south path, trees in the quiet corners.
const GARDEN_DECOR := [
	[Decor.Kind.BUSH, Vector2(-21.4, -27.45)], [Decor.Kind.BUSH, Vector2(-20.85, -27.45)],
	[Decor.Kind.BUSH, Vector2(-20.3, -27.45)], [Decor.Kind.BUSH, Vector2(-19.75, -27.45)],
	[Decor.Kind.BUSH, Vector2(-17.65, -27.45)], [Decor.Kind.BUSH, Vector2(-17.1, -27.45)],
	[Decor.Kind.BUSH, Vector2(-16.55, -27.45)], [Decor.Kind.BUSH, Vector2(-16.0, -27.45)],
	[Decor.Kind.BUSH, Vector2(-21.45, -26.85)], [Decor.Kind.BUSH, Vector2(-21.45, -26.3)],
	[Decor.Kind.BUSH, Vector2(-21.45, -25.75)],
	[Decor.Kind.BUSH, Vector2(-15.95, -26.85)], [Decor.Kind.BUSH, Vector2(-15.95, -26.3)],
	[Decor.Kind.BUSH, Vector2(-15.95, -25.75)],
	[Decor.Kind.BUSH, Vector2(-15.95, -23.45)], [Decor.Kind.BUSH, Vector2(-15.95, -22.9)],
	[Decor.Kind.BUSH, Vector2(-15.95, -22.35)], [Decor.Kind.BUSH, Vector2(-15.95, -21.8)],
	[Decor.Kind.FLOWERS, Vector2(-20.6, -26.45)], [Decor.Kind.FLOWERS, Vector2(-20.05, -26.05)],
	[Decor.Kind.FLOWERS, Vector2(-20.6, -25.75)], [Decor.Kind.FLOWERS, Vector2(-17.3, -23.35)],
	[Decor.Kind.FLOWERS, Vector2(-16.8, -22.9)], [Decor.Kind.FLOWERS, Vector2(-17.35, -22.45)],
	[Decor.Kind.FLOWERS, Vector2(-20.1, -23.3)], [Decor.Kind.FLOWERS, Vector2(-19.95, -22.4)],
	[Decor.Kind.BENCH, Vector2(-19.25, -23.6), Vector2(0.0, 0.7)], [Decor.Kind.BENCH, Vector2(-18.15, -23.6), Vector2(0.0, 0.7)],
	[Decor.Kind.OAK, Vector2(-16.9, -26.6), Vector2(30.0, 0.0)], [Decor.Kind.OAK, Vector2(-16.5, -21.95), Vector2(27.0, 0.0)],
	[Decor.Kind.PINE, Vector2(-21.1, -23.75), Vector2(28.0, 0.0)],
]
## The drill yard's pieces: the dummies in two tidy rows of four (polish 3), each drawn at DUMMY_SCALE (the scarecrow
## art stands about one and a half soldiers tall: at this scale about one), the drill's gear along its north edge and
## in its south-west corner.
const DRILL_DUMMIES := [
	Vector2(-12.6, -26.6), Vector2(-12.6, -25.4), Vector2(-12.6, -24.2), Vector2(-12.6, -23.0),
	Vector2(-9.4, -26.6), Vector2(-9.4, -25.4), Vector2(-9.4, -24.2), Vector2(-9.4, -23.0),
]
const DUMMY_SCALE := 0.62
const DRILL_DECOR := [
	[Decor.Kind.BARREL, Vector2(-14.6, -27.3)], [Decor.Kind.BARREL, Vector2(-14.15, -27.45)],
	[Decor.Kind.CRATES, Vector2(-13.5, -27.4)], [Decor.Kind.LOGS, Vector2(-12.4, -27.5)],
	[Decor.Kind.TABLE, Vector2(-10.9, -27.45)], [Decor.Kind.CRATES, Vector2(-14.6, -21.9)],
	[Decor.Kind.BARREL, Vector2(-14.1, -21.8)],
]
## Where the drilling soldiers stand: one before each dummy, DRILL_RANKS cells west of it, facing it (polish 3: two
## rows of soldiers, each facing its row of dummies).
const DRILL_RANKS := [1.5]
## The ground each kind of courtyard piece closes to walkers, about its point (a bench's along its size); a piece's
## own "half" overrides it (the avenues' trees close only their trunks).
const COURT_HALF := {Decor.Kind.BUSH: 0.2, Decor.Kind.FLOWERS: 0.15, Decor.Kind.OAK: 0.3, Decor.Kind.PINE: 0.3,
	Decor.Kind.SCARECROW: 0.2, Decor.Kind.BARREL: 0.15, Decor.Kind.CRATES: 0.25, Decor.Kind.LOGS: 0.3,
	Decor.Kind.TABLE: 0.35, Decor.Kind.BENCH: 0.15, Decor.Kind.LAMP: 0.1, Decor.Kind.FENCE: 0.1}
## The avenues (polish 3): trees and lamp posts in turn along both sides of every avenue inside the walls, every
## AVENUE_STEP, AVENUE_OUT past the avenue's edge (avenue_decor()); a spot that is not clear is skipped, so the rest
## keep the step. A tree closes only its trunk (AVENUE_TRUNK).
const AVENUE_STEP := 2.5
const AVENUE_OUT := 0.3
const AVENUE_TRUNK := 0.12
## The larger leftover strips between the avenues (polish 3): [the pocket's open ground, &"garden" or &"market"]. A
## pocket garden: flower beds, a bench or two and a tree; a market corner: one or two stalls (stalls(), after the
## plaza's) and crates and barrels. The capital's shrubs are thinned (SHRUB_CHANCE) and none grows in a pocket.
const POCKETS := [
	[Rect2(5.25, -21.0, 2.0, 3.5), &"garden"], [Rect2(5.25, -15.0, 2.0, 4.75), &"garden"],
	[Rect2(-9.0, -16.75, 2.5, 2.5), &"garden"], [Rect2(-18.25, -18.25, 2.25, 1.75), &"garden"],
	[Rect2(9.5, -2.5, 3.75, 2.0), &"garden"], [Rect2(5.25, -2.5, 2.0, 2.0), &"garden"],
	[Rect2(10.75, 16.75, 2.5, 2.0), &"garden"], [Rect2(2.25, 28.25, 2.75, 1.5), &"garden"],
	[Rect2(-1.25, -2.5, 3.25, 2.75), &"market"], [Rect2(-9.0, -7.75, 2.25, 1.5), &"market"],
	[Rect2(-18.25, 15.5, 2.25, 3.75), &"market"], [Rect2(8.25, 25.75, 3.25, 3.5), &"market"],
]
const SHRUB_CHANCE := 0.35
## The Keep's grounds (polish 3): the paving south-east of the Keep, between it, the avenue's head and the service
## yard, where the Keep's gate stood in polish 2 (the barbican and the alley steps are unused since: CapitalPlots.UNUSED).
## The watchtower stands on the Keep's wall line (WATCHTOWER, its back corner: in line with the Citadel's south wall,
## east of its south-east tower, clear of the rally ring's posts), its two guards at its foot; trees round it
## (KEEP_DECOR, carried with the courtyard's: court_decor()).
const KEEP_GROUNDS := Rect2(2.9, -25.0, 3.6, 4.0)
const WATCHTOWER := Vector2(3.6, -24.2)
const KEEP_DECOR := [
	[Decor.Kind.OAK, Vector2(5.65, -24.55), Vector2(28.0, 0.0)], [Decor.Kind.PINE, Vector2(6.15, -23.15), Vector2(26.0, 0.0)],
	[Decor.Kind.OAK, Vector2(5.75, -21.7), Vector2(26.0, 0.0)],
]
## The district gate's back corner (polish 2): across the lane between the poor and the road quarters, its arch on the
## lane, which runs on beyond both its ends.
const DISTRICT_GATE := Vector2(-4.8, 27.0)
## The Keep's service yard (polish 2): the paving east of the Keep inside the old town's wall, between the Keep's gate
## and the wall patrols' loop. The royal stables and horse pens along its north side under the wall, a granary, a well,
## the wagon (both ways round) and hand carts parked (GPT_PLOTS); wood piles by the stables, barrels and crates by the
## granary (YARD_DECOR, carried with the courtyard's: court_decor()). No hay: no set or decor piece is hay. Its stable
## hands (SPAWN_ROLES' keep_yard) work at the stables' fronts and YARD_WORK.
const KEEP_YARD := Rect2(6.6, -28.3, 9.7, 7.0)
const KEEP_YARD_WELL := Rect2(11.3, -24.6, 0.5, 0.5)
const YARD_DECOR := [
	[Decor.Kind.LOGS, Vector2(9.35, -26.2)], [Decor.Kind.LOGS, Vector2(6.95, -26.15)],
	[Decor.Kind.BARREL, Vector2(12.5, -22.2)], [Decor.Kind.BARREL, Vector2(12.55, -21.75)],
	[Decor.Kind.CRATES, Vector2(12.3, -23.0)], [Decor.Kind.CRATES, Vector2(9.0, -22.55)],
]
## The yard's own work places besides the stables' fronts: the pens' gate, the granary's door, the cart stand.
const YARD_WORK := [Vector2(13.3, -26.5), Vector2(13.4, -21.5), Vector2(10.6, -23.0)]
## The cathedral close (polish 2): the lawns round the cathedral between the avenues. The churchyard, on the lawn east
## of it below the courthouse: the monastery's graveyard set once more (no single grave art exists), the wayside cross
## and three yews (town pines, CLOSE_DECOR). The pilgrim plaza, on the lawn before its steps across the west road,
## paved with the floor's plaza paving: a well (PLAZA_WELL), two benches, the jail's notice board (moved here), a second
## crier stage and four stalls of the market's designs (PLAZA_STALL_ROWS). Nothing there stands taller than the
## cathedral. Priests and monks walk the close (CLOSE_PRAY in the churchyard); townsfolk gather at the plaza
## (CLOSE_PRAY and CLOSE_MARKET there).
const CHURCHYARD := Rect2(-1.35, -16.95, 4.2, 2.85)
const PILGRIM_PLAZA := Rect2(-8.0, -11.9, 9.5, 1.8)
const PLAZA_WELL := Rect2(-3.7, -11.7, 0.5, 0.5)
const PLAZA_STALL_ROWS := [Rect2(-6.8, -11.0, 2.1, 0.7), Rect2(-1.2, -11.0, 2.1, 0.7)]
const CLOSE_DECOR := [
	[Decor.Kind.PINE, Vector2(2.5, -16.55), Vector2(26.0, 0.0)], [Decor.Kind.PINE, Vector2(2.55, -14.65), Vector2(24.0, 0.0)],
	[Decor.Kind.PINE, Vector2(1.4, -14.5), Vector2(22.0, 0.0)],
	[Decor.Kind.BENCH, Vector2(-2.6, -10.45), Vector2(0.7, 0.0)], [Decor.Kind.BENCH, Vector2(-2.6, -11.75), Vector2(0.7, 0.0)],
]
const CLOSE_PRAY := [Vector2(1.95, -15.15), Vector2(1.0, -16.65), Vector2(-6.1, -11.7), Vector2(0.0, -11.7)]
const CLOSE_MARKET := [Vector2(-5.1, -11.6), Vector2(-0.8, -11.6)]
## The aqueduct (polish 2): its west end's back corner, against the old town's north-east corner tower's east face (the
## tower hides the run's missing end piece: no aqueduct end set exists), across the tower's middle; it runs east into
## the northern woods to a spring among rocks (AQUEDUCT_SPRING, an outcrop). The woods stand back from the arches
## (forest_gaps(): AQUEDUCT_CLEAR, a little north of them, more to the south, in front of them on screen), so they read.
## The cistern it feeds stands just inside the wall at that corner.
const AQUEDUCT := Vector2(18.7, -29.9)
const AQUEDUCT_PIECES := 9
const AQUEDUCT_SPRING := Vector2(30.6, -28.2)
const AQUEDUCT_CLEAR := Rect2(18.7, -31.0, 11.4, 3.6)
const CISTERN := Vector2(15.5, -29.25)
## The bank lines the over-water sets stand from (BuildingTypes.OVER_WATER): the river's north bank and the harbour
## basin's north quay (RIVER's and HARBOUR's north edges).
const NORTH_BANK := 6.0
const NORTH_QUAY := -2.0
## Every ChatGPT plot: [set, its footprint's back corner], or for a set standing over water [set, Vector2(its back
## corner's x, the bank line), true] (CapitalPlots.on_bank()). The set's footprint and height come from CapitalPlots.SETS.
## By district (spec §1). The landmarks that must be seen (the Citadel's keep, the cathedral, the town hall, the market
## hall) have nothing taller just in front of them (tests/test_capital_plots.gd).
const GPT_PLOTS := [
	# Royal Keep: armoury and treasury before the barracks; the watchtower on the Keep's wall line (polish 3:
	# WATCHTOWER). (No gatehouse of its own: the barbican and the alley steps stood at the avenue's head in polish 2 and
	# are unused since; no drawbridge either, as no gate of the capital faces open water. CapitalPlots.UNUSED.)
	[&"gpt_armoury", Vector2(-7.8, -23.5)], [&"gpt_treasury", Vector2(-5.0, -23.5)],
	[&"gpt_watchtower", WATCHTOWER],
	# The Keep's service yard (KEEP_YARD): two royal stables and the horse pens along its north side, the granary, the
	# wagon parked both ways round (turned, it draws mirrored: CapitalPlots.TURNS) and two hand carts.
	[&"gpt_stables", Vector2(6.9, -28.1)], [&"gpt_stables", Vector2(9.6, -28.1)], [&"gpt_pens", Vector2(12.3, -28.1)],
	[&"gpt_granary", Vector2(12.8, -23.0)], [&"gpt_wagon", Vector2(7.4, -23.4)],
	[&"gpt_wagon", Vector2(9.6, -24.4), &"turned"],
	[&"gpt_handcart", Vector2(11.0, -22.4)], [&"gpt_handcart", Vector2(7.4, -25.4)],
	# The royal garden, the Keep courtyard's west half (KEEP_COURT): the monument at the head of its north path, the
	# pavilion in its south-west corner.
	[&"gpt_monument", Vector2(-19.285, -27.75)], [&"gpt_pavilion", Vector2(-21.5, -23.0)],
	# Noble quarter: the manor and its garden (the ice house by the fishpond that gives it its ice), library, school,
	# patrician townhouses, and a street of them between the west road and the cross avenue.
	[&"gpt_manor", Vector2(-22.3, -20.6)], [&"gpt_library", Vector2(-17.9, -20.6)], [&"gpt_school", Vector2(-15.0, -20.6)],
	[&"gpt_patrician", Vector2(-12.8, -20.6)], [&"gpt_patrician", Vector2(-11.6, -20.6)],
	[&"gpt_patrician", Vector2(-10.4, -20.6)], [&"gpt_icehouse", Vector2(-22.3, -17.6)],
	[&"gpt_fishpond", Vector2(-20.4, -17.4)],
	[&"gpt_patrician", Vector2(-19.0, -11.6)], [&"gpt_patrician", Vector2(-17.8, -11.6)],
	[&"gpt_patrician", Vector2(-16.6, -11.6)], [&"gpt_patrician", Vector2(-15.4, -11.6)],
	[&"gpt_patrician", Vector2(-14.2, -11.6)], [&"gpt_patrician", Vector2(-13.0, -11.6)],
	[&"gpt_patrician", Vector2(-11.8, -11.6)], [&"gpt_patrician", Vector2(-10.6, -11.6)],
	# Cathedral and civic square: town hall and courthouse east of the cathedral, the jail west of it. The cathedral
	# close (polish 2): the churchyard east of it (a graveyard, the wayside cross), the pilgrim plaza before its steps
	# (the jail's notice board, moved here, and a crier's stage).
	[&"gpt_townhall", Vector2(-1.2, -20.8)], [&"gpt_courthouse", Vector2(-1.0, -18.6)],
	[&"gpt_jail", Vector2(-8.7, -18.6)],
	[&"gpt_graveyard", Vector2(-1.1, -16.4)], [&"gpt_waysidecross", Vector2(1.7, -16.0)],
	[&"gpt_noticeboard", Vector2(0.5, -11.8)], [&"gpt_crierstage", Vector2(-7.8, -11.8)],
	# Guild quarter: the guild hall, the weavers' hall, shop-houses; and (polish 3) a row of shop-houses on the cross
	# avenue's north side, their fronts on it.
	[&"gpt_guildhall", Vector2(9.0, -20.6)], [&"gpt_weavers", Vector2(11.0, -20.6)],
	[&"gpt_shophouse", Vector2(13.8, -20.6)], [&"gpt_shophouse", Vector2(15.2, -20.6)],
	[&"gpt_shophouse", Vector2(9.6, -12.12)], [&"gpt_shophouse", Vector2(11.0, -12.12)],
	[&"gpt_shophouse", Vector2(12.4, -12.12)],
	# Great Market: the covered market hall at the square's head (only stalls in front of it), the weigh house, the
	# crier's stage by the west bridge avenue.
	[&"gpt_markethall", Vector2(-12.0, -7.7)], [&"gpt_weighhouse", Vector2(-6.2, -7.7)],
	[&"gpt_crierstage", Vector2(-16.4, -3.6)],
	# Old town houses: hospital, bathhouse; and (polish 3) a shop-house beside the bathhouse on the cross avenue's south
	# side.
	[&"gpt_hospital", Vector2(5.5, -7.6)], [&"gpt_bathhouse", Vector2(9.0, -7.6)],
	[&"gpt_shophouse", Vector2(11.7, -7.5)],
	# The cistern at the aqueduct's end (polish 2), just inside the wall at the north-east corner tower it runs into.
	[&"gpt_cistern", CISTERN],
	# Banks: wash houses on the river's north bank below the old town's wall, their washing steps over the river; the
	# sluice west of them, standing out into the river from the bank.
	[&"gpt_washhouse", Vector2(-9.0, NORTH_BANK), true], [&"gpt_washhouse", Vector2(7.5, NORTH_BANK), true],
	[&"gpt_sluice", Vector2(-28.0, NORTH_BANK), true],
	# Harbour district: the fish market by the harbour gate; the sets painted with water at their front (the dock
	# warehouses, the crane, the ferry landing) on the basin's north quay and the river's bank, their posts and piles
	# over the water; the stables, a dockworkers' tenement and shop-houses behind the avenue.
	[&"gpt_fishmarket", Vector2(19.0, -7.0)], [&"gpt_warehouse", Vector2(22.5, NORTH_QUAY), true],
	[&"gpt_warehouse", Vector2(25.0, NORTH_QUAY), true], [&"gpt_crane", Vector2(33.8, NORTH_QUAY), true],
	[&"gpt_ferry", Vector2(36.6, NORTH_QUAY), true],
	[&"gpt_warehouse", Vector2(19.5, NORTH_BANK), true], [&"gpt_stables", Vector2(19.0, -13.0)],
	[&"gpt_tenement", Vector2(22.5, -13.0)], [&"gpt_shophouse", Vector2(24.6, -13.0)],
	[&"gpt_shophouse", Vector2(26.1, -13.0)],
	# Northern woods: charcoal kilns; the aqueduct (polish 2) from the spring (AQUEDUCT_SPRING) west to the old town's
	# north-east corner tower, a run of AQUEDUCT_PIECES segments along x (AQUEDUCT).
	[&"gpt_charcoal", Vector2(24.0, -35.0)], [&"gpt_charcoal", Vector2(31.0, -31.0)],
	[&"gpt_aqueduct", AQUEDUCT], [&"gpt_aqueduct", AQUEDUCT + Vector2(1.2, 0.0)],
	[&"gpt_aqueduct", AQUEDUCT + Vector2(2.4, 0.0)], [&"gpt_aqueduct", AQUEDUCT + Vector2(3.6, 0.0)],
	[&"gpt_aqueduct", AQUEDUCT + Vector2(4.8, 0.0)], [&"gpt_aqueduct", AQUEDUCT + Vector2(6.0, 0.0)],
	[&"gpt_aqueduct", AQUEDUCT + Vector2(7.2, 0.0)], [&"gpt_aqueduct", AQUEDUCT + Vector2(8.4, 0.0)],
	[&"gpt_aqueduct", AQUEDUCT + Vector2(9.6, 0.0)],
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
	# Road quarter: the coaching inn, stables, livestock pens; the district gate across the lane between it and the
	# poor quarter (polish 2), the lane running on through its arch (DISTRICT_GATE).
	[&"gpt_inn", Vector2(-3.0, 23.5)], [&"gpt_stables", Vector2(9.0, 23.5)], [&"gpt_pens", Vector2(12.0, 23.5)],
	[&"gpt_districtgate", DISTRICT_GATE],
	# Monastery hill: monastery, graveyard, chapel; the leper house far off; a wayside cross and a milestone by the west
	# road.
	[&"gpt_monastery", Vector2(-36.0, -36.0)], [&"gpt_graveyard", Vector2(-32.5, -36.0)],
	[&"gpt_chapel", Vector2(-36.0, -32.4)], [&"gpt_leperhouse", Vector2(-38.5, -26.0)],
	[&"gpt_waysidecross", Vector2(-30.0, -15.0)], [&"gpt_milestone", Vector2(-35.0, -11.7)],
	# West farms: a farmhouse and orchards by the fields (the third, once in the Keep's courtyard, below the other two).
	[&"gpt_farmhouse", Vector2(-34.5, 17.5)], [&"gpt_orchard", Vector2(-34.4, 26.4)], [&"gpt_orchard", Vector2(-32.6, 26.4)],
	[&"gpt_orchard", Vector2(-32.6, 28.3)],
	# South-east fields: vineyard rows, beehives, dovecote, granary, orchards, a farmhouse.
	[&"gpt_vineyard", Vector2(24.0, 20.0)], [&"gpt_vineyard", Vector2(26.2, 20.0)], [&"gpt_vineyard", Vector2(28.4, 20.0)],
	[&"gpt_vineyard", Vector2(24.0, 21.5)], [&"gpt_vineyard", Vector2(26.2, 21.5)], [&"gpt_vineyard", Vector2(28.4, 21.5)],
	[&"gpt_beehives", Vector2(31.0, 20.0)], [&"gpt_dovecote", Vector2(33.5, 20.0)], [&"gpt_granary", Vector2(35.0, 20.0)],
	[&"gpt_orchard", Vector2(31.0, 23.0)], [&"gpt_orchard", Vector2(33.0, 23.0)], [&"gpt_farmhouse", Vector2(36.0, 23.0)],
	# Suburbs and gallows hill (polish 3): the gallows on its rocky hill at the west end (GALLOWS_HILL), the fields and
	# the barn beside it (FIELDS, BARNS), then a hamlet of huts in two rows round its well (SUBURB_WELL), clear of the
	# south road.
	[&"gpt_gallows", GALLOWS_HILL - Vector2(0.6, 0.7)],
	[&"gpt_hut", Vector2(-12.6, 35.0)], [&"gpt_hut", Vector2(-10.6, 35.0)], [&"gpt_hut", Vector2(-8.6, 35.0)],
	[&"gpt_hut", Vector2(-6.6, 35.0)], [&"gpt_hut", Vector2(-4.6, 35.0)], [&"gpt_hut", Vector2(-2.4, 35.0)],
	[&"gpt_hut", Vector2(-0.4, 35.0)], [&"gpt_hut", Vector2(1.6, 35.0)],
	[&"gpt_hut", Vector2(-11.6, 36.8)], [&"gpt_hut", Vector2(-9.4, 36.8)], [&"gpt_hut", Vector2(-7.2, 36.8)],
	[&"gpt_hut", Vector2(-2.0, 36.8)], [&"gpt_hut", Vector2(0.2, 36.8)], [&"gpt_hut", Vector2(2.4, 36.8)],
	# Tournament field (polish 3): two grandstands side by side facing the tilt yard (a run of tilt barriers along x
	# between two fences: LISTS_DECOR), the play stage at its east end.
	[&"gpt_grandstand", Vector2(9.6, 35.0)], [&"gpt_grandstand", Vector2(12.6, 35.0)],
	[&"gpt_tiltbarrier", Vector2(9.6, 37.1)], [&"gpt_tiltbarrier", Vector2(10.8, 37.1)],
	[&"gpt_tiltbarrier", Vector2(12.0, 37.1)], [&"gpt_tiltbarrier", Vector2(13.2, 37.1)],
	[&"gpt_tiltbarrier", Vector2(14.4, 37.1)],
	[&"gpt_playstage", Vector2(16.8, 35.2)],
]
## The craft sets whose fronts are workplaces (anchors' "craft").
const CRAFTS := [&"gpt_bakery", &"gpt_butcher", &"gpt_brewery", &"gpt_tannery", &"gpt_dyers", &"gpt_weavers",
	&"gpt_potter", &"gpt_cooper", &"gpt_masonyard", &"gpt_lumberyard", &"gpt_glassworks"]
## How each walled district's house blocks are filled (CapitalPlots.row()): [plot, gap, townhouses, jitter (0 for
## none), mix]. Districts not listed (the Royal Keep, the cathedral square) take no houses. The poor quarter's cottages
## are jittered and gapped, so they crowd in unevenly rather than stand in a lattice. The mix (polish 3): the GPT housing
## sets whose rows stand among the district's own, each [set, share, on an avenue only] -- a row's hash picks one by the
## shares, and its plots stand on the set's own footprint (_house_rows()): patrician rows in the noble quarter and the
## guild quarter by the Keep, shop-house rows in the market and along the avenues, rows of shacks and tenements in the
## poor quarter, a few shacks by the tanners; the new town is plain cottages.
const HOUSING := {
	&"noble_quarter": [Vector2(1.3, 0.95), 0.9, true, 0.0, [[&"gpt_patrician", 0.5, false]]],
	&"guild_quarter": [Vector2(1.3, 0.95), 0.8, true, 0.0, [[&"gpt_shophouse", 0.45, true], [&"gpt_patrician", 0.25, false]]],
	&"great_market": [Vector2(1.3, 0.95), 0.8, true],
	&"old_town_houses": [Vector2(1.3, 0.95), 0.6, true, 0.0, [[&"gpt_shophouse", 0.5, true]]],
	&"crafts_quarter": [Vector2(0.95, 0.75), 0.7, false],
	&"new_town": [Vector2(0.95, 0.75), 0.7, false],
	&"tanners_dyers": [Vector2(0.95, 0.75), 0.9, false, 0.0, [[&"gpt_shacks", 0.5, false]]],
	&"poor_quarter": [Vector2(0.95, 0.75), 0.5, false, 0.6, [[&"gpt_shacks", 0.25, false], [&"gpt_tenement", 0.15, false]]],
	&"road_quarter": [Vector2(0.95, 0.75), 0.7, false],
}
## A set's row (_house_rows()) spaces its plots MIX_GAP apart; SALT_MIX hashes the rows' picks.
const MIX_GAP := 0.5
const SALT_MIX := 8363
## How far a house keeps from a wall patrol's post (_house_ok()).
const LOOP_POST_CLEAR := 0.45
const GOLDEN := 0.618034
## How far a house keeps from every other building, yard and square, and from the streets; how far inside its ring's
## wall (Aldermere's WALL_T + WALL_CLEAR).
const HOUSE_CLEAR := 0.5
const HOUSE_STREET_CLEAR := 0.5
const HOUSE_WALL_CLEAR := 1.7
## The sets whose fronts are workplaces besides the crafts (anchors' "work"): civic, guild and trade buildings.
const WORKS := [&"gpt_guildhall", &"gpt_shophouse", &"gpt_townhall", &"gpt_courthouse", &"gpt_library", &"gpt_school",
	&"gpt_hospital", &"gpt_bathhouse", &"gpt_stables", &"gpt_markethall", &"gpt_weighhouse", &"gpt_fishmarket",
	&"gpt_inn", &"gpt_treasury", &"gpt_jail"]
## The bakery's bread queue (anchors' "queue"): how many places, how far out on the avenue, how far apart.
const QUEUE_LENGTH := 6
const QUEUE_OFF := 0.5
const QUEUE_STEP := 0.45
## Each district's citizens by job (spawn_roles()), about 420 in all.
const SPAWN_ROLES := {
	&"noble_quarter": {&"noble": 12, &"resident": 10, &"caregiver": 8},
	&"cathedral_square": {&"clergy": 8, &"beggar": 4, &"monk": 2},
	&"guild_quarter": {&"guild_craftsman": 12, &"trader": 4, &"resident": 6, &"caregiver": 4},
	&"great_market": {&"merchant": 22, &"trader": 6, &"innkeeper": 3, &"beggar": 3},
	&"old_town_houses": {&"resident": 16, &"caregiver": 10, &"craft": 4, &"washer": 6, &"clergy": 3},
	&"harbour_district": {&"dockworker": 24, &"ferryman": 3, &"trader": 6, &"innkeeper": 2, &"stable_hand": 3,
		&"beggar": 2},
	&"crafts_quarter": {&"craft": 20, &"baker": 5, &"labourer": 6, &"resident": 6, &"caregiver": 4},
	&"new_town": {&"resident": 14, &"caregiver": 8, &"merchant": 4, &"washer": 6, &"clergy": 2},
	&"tanners_dyers": {&"craft": 10, &"labourer": 6, &"resident": 4},
	&"poor_quarter": {&"labourer": 14, &"beggar": 8, &"resident": 22, &"caregiver": 12, &"washer": 4},
	&"road_quarter": {&"innkeeper": 3, &"stable_hand": 4, &"labourer": 6, &"resident": 16, &"caregiver": 8,
		&"merchant": 3},
	&"monastery_hill": {&"monk": 12},
	&"keep_yard": {&"stable_hand": 3},
	&"west_farms": {&"farmer": 12},
	&"south_east_fields": {&"farmer": 12},
	&"suburbs": {&"labourer": 4, &"resident": 4, &"farmer": 2},
}
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
	# Over the third bridge, the minor crossing (a lane, half an avenue's width), from the cross avenue to the new town
	# avenue.
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
## The garrison (soldier_posts()): the Keep's yard and Citadel ring; how far inside a gate its two guards stand and how
## far apart; how far beside a bridge its bank guards stand; the harbour watch on the quays; the wall loops
## (patrol_loops(): how far inside the wall's face, a point about every LOOP_STEP, walkers per ring, the old town's
## first) and the street patrols' pairs.
const POSTS_YARD := 24
const POSTS_CITADEL := 30
const GUARD_IN := 1.6
const GUARD_SIDE := 1.4
const BRIDGE_GUARD_SIDE := 1.0
const HARBOUR_WATCH := [Vector2(19.6, -8.0), Vector2(21.0, -2.9), Vector2(24.0, -4.3), Vector2(27.2, -2.9),
	Vector2(28.7, -4.0), Vector2(33.3, -4.0), Vector2(30.2, -8.0), Vector2(36.0, -6.0)]
const LOOP_IN := 1.0
const LOOP_STEP := 3.0
const LOOP_WALKERS := [24, 20]
const STREET_PAIRS := 20
## One person through a gate this often (gate_interval()).
const GATE_INTERVAL := 1.0
## A house block narrower than this either way is left as street.
const BLOCK_MIN := 1.0
## How deep the cobbled queue ground inside each gatehouse is, and its gap from the gate towers.
const GATE_PLAZA := Vector2(3.6, 2.6)
const GATE_PLAZA_GAP := 0.6

## The countryside (CityDef's trails(), road_trails() and the rest), all outside both rings.
## Meadow trails through the woods north of the old town, and the west meadow above the river.
const TRAILS := [
	[Vector2(-22, -34.5), Vector2(-12, -35.2), Vector2(-2, -34.4), Vector2(8, -35.0), Vector2(16, -34.0),
		Vector2(21, -32.4), Vector2(28, -32.6), Vector2(34, -32.4), Vector2(39.5, -33.2)],
	[Vector2(-39.5, -4.0), Vector2(-33.0, -5.2), Vector2(-27.5, -3.6)],
]
## The dirt roads beyond the walls: [polyline, width]. The avenues' and the harbour lane's outside stretches (the south
## road from the barbican, the west road to the west gate, the cross avenue from the harbour gate, the ferry lane), and
## the farm tracks from the south road to the west farms and the south-east fields, and the monastery's track up from
## the west road.
const AVENUE_TRAIL := 0.85
const TRACK := 0.5
const ROAD_TRAILS := [
	[[Vector2(7.0, 34.6), Vector2(7.0, 40.0)], AVENUE_TRAIL],
	[[Vector2(-40.0, -13.0), Vector2(-24.6, -13.0)], AVENUE_TRAIL],
	[[Vector2(18.4, -9.0), Vector2(34.6, -9.0)], AVENUE_TRAIL],
	[[Vector2(31.0, -8.5), Vector2(31.0, -2.6)], TRACK],
	[[Vector2(6.2, 38.8), Vector2(-28.5, 38.8), Vector2(-33.0, 36.0), Vector2(-33.9, 32.0), Vector2(-33.9, 28.8)], TRACK],
	[[Vector2(7.8, 38.8), Vector2(21.5, 38.8), Vector2(23.0, 36.4), Vector2(29.5, 35.9), Vector2(29.5, 26.2)], TRACK],
	[[Vector2(-33.6, -14.0), Vector2(-33.0, -20.0), Vector2(-33.6, -26.0), Vector2(-33.2, -30.0), Vector2(-33.2, -33.8)],
		TRACK],
]
## Rocky outcrops in the woods and on the monastery's hill: [centre, radius].
const OUTCROPS := [
	[Vector2(35.5, -37.0), 1.6], [Vector2(-27.0, -37.2), 1.6], [Vector2(-29.0, -21.5), 1.6], [Vector2(12.0, -37.0), 1.4],
	[Vector2(37.5, -17.0), 1.5], [AQUEDUCT_SPRING, 0.6], [GALLOWS_HILL, 1.4],
]
## Rowing boats on the river, clear of the bridges, and in the harbour basin.
const BOATS := [Vector2(-31.0, 8.2), Vector2(-22.5, 9.8), Vector2(-5.5, 10.4), Vector2(9.0, 8.0), Vector2(27.5, 4.0),
	Vector2(35.0, 12.5)]
## Scarecrows between the fields, signposts at the west road's track, the south road and the harbour, carts by the farms
## and on the quay.
const SCARECROWS := [Vector2(-37.2, 16.7), Vector2(-37.2, 29.7), Vector2(27.0, 30.7), Vector2(32.5, 30.7),
	Vector2(-24.7, 36.4), Vector2(-15.6, 36.4), Vector2(-37.2, 37.7), Vector2(24.1, 38.2), Vector2(35.8, 38.0)]
const SIGNPOSTS := [Vector2(-36.5, -15.4), Vector2(9.3, 36.6), Vector2(33.2, -11.2)]
const CARTS := [Vector2(-33.0, 19.8), Vector2(26.6, 24.6), Vector2(21.4, -4.4)]
## Street props and cottage gardens (TownLayout's sizes and steps): a garden keeps GARDEN_CLEAR from every building but
## its own cottage, so a walkable cell stays between; SALT_PROP and SALT_GARDEN hash their rolls.
const GARDEN_CLEAR := 0.6
## The ground before every house's front no other cottage's garden takes (gardens()): this wide and deep.
const DOORSTEP := Vector2(1.5, 1.4)
const SALT_PROP := 8111
## How far behind a street prop (away from its street) a building must stand at both its ends.
const PROP_BACK := 1.0
const SALT_GARDEN := 8237


func id() -> StringName:
	return &"capital"


func map() -> Rect2:
	return MAP


## The country past the map's edge (polish 3): BORDER deep on every side.
func border() -> float:
	return BORDER


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


## The gates out of the walls (the exits' gates of soldier_posts()): the old town's west gate, its harbour gate and the
## new town's south barbican. The river gates only cross between the rings.
func gate_exits() -> Array[Vector2]:
	return [_wall_mid(INNER, INNER_GATES[0]), _wall_mid(INNER, INNER_GATES[4]), _wall_mid(OUTER, OUTER_GATES[3])]


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
## the stalls and the houses, then the bridges and the dock last (so Town's `bridge` is the third bridge).
## The seeds come from the field's own generator in this order.
func structures() -> Array[Dictionary]:
	if _structures.is_empty():
		var out: Array[Dictionary] = _ring_structures().duplicate(true)
		out.append_array(_buildings())
		for r: Rect2 in stalls():
			out.append({"rect": r, "height": 10.0, "kind": Structure.Kind.MARKET_STALL, "role": &"market", "tag": &""})
		var hs := houses()
		for i in hs.size():
			if _house_set.has(hs[i]):
				# A GPT housing set dealt into the block (polish 3): its own type, height and art.
				out.append(CapitalPlots.plot(_house_set[hs[i]], hs[i].position))
			elif _townhouse.get(hs[i], false):
				out.append({"rect": hs[i], "height": 28.0 + float(i * 7 % 3), "kind": Structure.Kind.HOUSE,
					"role": &"house", "tag": &"townhouse"})
			else:
				out.append({"rect": hs[i], "height": 15.0 + float(i * 7 % 5), "kind": Structure.Kind.HOUSE,
					"role": &"house", "tag": &""})
		for r: Rect2 in BRIDGES:
			out.append({"rect": r, "height": BRIDGE_H, "kind": Structure.Kind.BRIDGE, "role": &"bridge", "tag": &"stone"})
		out.append({"rect": DOCK, "height": DOCK_H, "kind": Structure.Kind.BRIDGE, "role": &"dock", "tag": &"dock"})
		_structures = out
	return _structures.duplicate(true)


## The houses: each listed district's house blocks (HOUSING) filled by CapitalPlots.row() with its cottages or
## townhouses, every house kept HOUSE_CLEAR from the other buildings, the stalls, yards, squares, gate plazas, fountains
## and wells, HOUSE_STREET_CLEAR from the streets and HOUSE_WALL_CLEAR inside its ring's wall; then the district's mix
## of GPT housing sets in rows of their own (_house_rows(), polish 3: house_set() names a plot's set). Worked out once.
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
		var avenues: Array[Rect2] = []
		for line: Array in AVENUES:
			_segments(avenues, line, AVENUE_W)
		var n := 0
		for row: Array in DISTRICT_TABLE:
			var style: Array = HOUSING.get(row[0], [])
			if style.is_empty():
				continue
			for block: Rect2 in _blocks(row[1]):
				n += 1
				var south := false
				for a: Rect2 in avenues:
					south = south or a.intersects(Rect2(block.position.x, block.end.y, block.size.x, 0.1))
				for pl: Array in _house_rows(block.grow(-HOUSE_STREET_CLEAR), style, n, south):
					var h: Rect2 = pl[0]
					var ok: bool = _house_ok(h, keep_off, inside) and (pl[1] == &"" or _clear_of_posts(h))
					if not ok and pl[1] != &"":
						# A set's plot that does not fit: the district's own house in its place (front and middle kept).
						var own: Vector2 = style[0]
						h = Rect2(Vector2(h.get_center().x - own.x * 0.5, h.end.y - own.y), own)
						pl[1] = &""
						ok = _house_ok(h, keep_off, inside)
					if ok:
						_houses.append(h)
						_townhouse[h] = style[2] or pl[1] != &""
						if pl[1] != &"":
							_house_set[h] = pl[1]
	return _houses.duplicate()


## Whether house plot `h` may stand: inside a ring's wall, out of the queue fans, clear of `keep_off`.
func _house_ok(h: Rect2, keep_off: Array[Rect2], inside: Array[Rect2]) -> bool:
	var ok := (inside[0].encloses(h) or inside[1].encloses(h)) and not _in_fan(h)
	for k: Rect2 in keep_off:
		ok = ok and not k.intersects(h)
	return ok


## Whether a set's plot `h` keeps clear of the wall patrols' posts, which stand on the line HOUSE_WALL_CLEAR inside the
## wall (a set's row stands still and wide: polish 3).
func _clear_of_posts(h: Rect2) -> bool:
	for loop: Dictionary in patrol_loops():
		for p: Vector2 in loop.points:
			if h.grow(LOOP_POST_CLEAR).has_point(p):
				return false
	return true


## The GPT housing set standing on house plot `h` (houses()), or &"" for a cottage or a townhouse.
func house_set(h: Rect2) -> StringName:
	houses()
	return _house_set.get(h, &"")


## One house block's plots (polish 3), as [rect, set] (set &"" for the district's own house), in rows from the
## block's south edge up, `gap` apart: a row of the district's houses (CapitalPlots.row(): `plot`, slid by its hash,
## jittered as the district is), or a row of one of the mix's sets on its own footprint, picked by the row's hash and
## the shares. A set kept to the avenues ("on an avenue only") stands only in the bottom row, and only where the
## block's south edge lies on an avenue (`avenue_south`): its fronts face it.
func _house_rows(block: Rect2, style: Array, n: int, avenue_south: bool) -> Array:
	var plot: Vector2 = style[0]
	var gap: float = style[1]
	var jitter: float = style[3] if style.size() > 3 else 0.0
	var mix: Array = style[4] if style.size() > 4 else []
	if mix.is_empty():
		# No mix: the block filled as a whole (CapitalPlots.row()), as before polish 3.
		var plain: Array = []
		for r: Rect2 in CapitalPlots.row(block, plot, gap, n, jitter):
			plain.append([r, &""])
		return plain
	# The rows, bottom up: each [set, size, the space before it].
	var rows: Array = []
	var used := 0.0
	var j := 0
	# The rows' rolls step round by the golden ratio from the block's own hash, so each set's rows come up in about its
	# share in every block, spread out, rather than by chance.
	var start := ArtKit.hash01(SALT_MIX, n)
	while true:
		var roll := fposmod(start + float(j) * GOLDEN, 1.0)
		var set_name := &""
		for m: Array in mix:
			if m[2] and (j > 0 or not avenue_south):
				continue
			if roll < float(m[1]):
				set_name = m[0]
				break
			roll -= float(m[1])
		var size: Vector2 = plot if set_name == &"" else CapitalPlots.SETS[set_name][0]
		var lead := _row_lead(rows, set_name, gap, jitter)
		if used + lead + size.y > block.size.y + 0.0001:
			lead = _row_lead(rows, &"", gap, jitter)
			if set_name == &"" or used + lead + plot.y > block.size.y + 0.0001:
				break
			set_name = &""
			size = plot
		rows.append([set_name, size, lead])
		used += lead + size.y
		j += 1
	# The stack centred down the block, or on its south edge under a row kept to the avenue there.
	var on_avenue := false
	for m: Array in mix:
		on_avenue = on_avenue or (not rows.is_empty() and m[0] == rows[0][0] and m[2])
	var bottom := block.end.y - (0.0 if on_avenue else (block.size.y - used) * 0.5)
	var out: Array = []
	for k in rows.size():
		var set_name: StringName = rows[k][0]
		var size: Vector2 = rows[k][1]
		# A jittered row's strip leaves it room to shift up and down by its jitter.
		var shift := gap * jitter if set_name == &"" else 0.0
		var strip := Rect2(block.position.x, bottom - size.y - shift * 0.5, block.size.x, size.y + shift).intersection(block)
		for r: Rect2 in CapitalPlots.row(strip, size, gap if set_name == &"" else MIX_GAP, n * 100 + k,
				jitter if set_name == &"" else 0.0):
			out.append([r, set_name])
		if k + 1 < rows.size():
			bottom -= size.y + float(rows[k + 1][2])
	return out


## The space before a row of `set_name` stacked after `rows` (none before the first): the district's gap, and in a
## jittered district its jitter's room more beside a set's row (the set's row stands still, its neighbour shifts).
static func _row_lead(rows: Array, set_name: StringName, gap: float, jitter: float) -> float:
	if rows.is_empty():
		return 0.0
	var beside_set: bool = set_name != &"" or rows[rows.size() - 1][0] != &""
	return gap + (gap * jitter if beside_set else 0.0)


## The market stalls: each of STALL_ROWS laid with stalls (CapitalPlots.row()), in row order.
func stalls() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i in STALL_ROWS.size():
		out.append_array(CapitalPlots.row(STALL_ROWS[i], STALL, STALL_GAP, i + 1))
	# The pilgrim plaza's (polish 2), after the market's, so theirs keep their rows' seeds.
	for i in PLAZA_STALL_ROWS.size():
		out.append_array(CapitalPlots.row(PLAZA_STALL_ROWS[i], STALL, STALL_GAP, STALL_ROWS.size() + i + 1))
	# The market corners' (polish 3), after the plaza's: one or two along each corner's back edge.
	var k := STALL_ROWS.size() + PLAZA_STALL_ROWS.size()
	for p: Array in POCKETS:
		if p[1] == &"market":
			k += 1
			out.append_array(CapitalPlots.row(_corner_row(p[0]), STALL, STALL_GAP, k))
	return out


## A market corner's stall row: along its back edge, room for two stalls at most.
static func _corner_row(r: Rect2) -> Rect2:
	return Rect2(r.position + Vector2(0.15, 0.15), Vector2(minf(r.size.x - 0.3, STALL.x * 2.0 + STALL_GAP), STALL.y))


## The pockets' pieces (POCKETS), in order: a garden's tree in its back corner, flower beds along its back half, a
## bench (two in a deep one) before them and a lamp post at its front; a market corner's crates and barrels before
## and beside its stalls (stalls()).
func pocket_decor() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p: Array in POCKETS:
		var r: Rect2 = p[0]
		var o := r.position
		var s := r.size
		if p[1] == &"garden":
			out.append({"kind": Decor.Kind.OAK, "at": o + Vector2(0.4, 0.4), "size": Vector2(27.0, 0.0)})
			var beds := maxi(1, floori((s.x - 0.9) / 0.6))
			for i in beds:
				out.append({"kind": Decor.Kind.FLOWERS, "at": o + Vector2(1.0 + i * 0.6, 0.45), "size": Vector2.ZERO})
			for i in maxi(1, floori((s.y - 0.9) / 0.7)):
				out.append({"kind": Decor.Kind.FLOWERS, "at": o + Vector2(0.4, 1.1 + i * 0.7), "size": Vector2.ZERO})
			out.append({"kind": Decor.Kind.BENCH, "at": o + Vector2(s.x * 0.5 - 0.2, s.y * 0.5 + 0.1),
				"size": Vector2(0.7, 0.0)})
			if s.y >= 3.0:
				out.append({"kind": Decor.Kind.BENCH, "at": o + Vector2(s.x * 0.5 - 0.2, s.y - 0.5), "size": Vector2(0.7, 0.0)})
			out.append({"kind": Decor.Kind.LAMP, "at": o + Vector2(s.x - 0.25, s.y - 0.25), "size": Vector2.ZERO})
		else:
			var row := _corner_row(r)
			out.append({"kind": Decor.Kind.CRATES, "at": Vector2(row.position.x + 0.3, row.end.y + 0.55), "size": Vector2.ZERO})
			out.append({"kind": Decor.Kind.BARREL, "at": Vector2(row.position.x + 0.75, row.end.y + 0.45), "size": Vector2.ZERO})
			if s.x >= 2.5:
				out.append({"kind": Decor.Kind.BARREL, "at": Vector2(r.end.x - 0.3, row.end.y + 0.5), "size": Vector2.ZERO})
			if s.y >= 2.5:
				out.append({"kind": Decor.Kind.CRATES, "at": Vector2(r.end.x - 0.4, r.end.y - 0.4), "size": Vector2.ZERO})
	return out


## The avenues' trees and lamp posts (AVENUE_STEP): along both sides of each avenue's stretch inside a wall ring,
## AVENUE_OUT past its edge, a tree and a lamp in turn, each where it is clear -- of every building (and its walk), the
## squares, yards and gate plazas, the queue fans, the other streets' crossings, the street props, gardens, torches,
## fountains and wells, every routine place and soldier's post, and the city's other pieces. Worked out once.
func avenue_decor() -> Array[Dictionary]:
	if _avenue_done:
		return _avenue.duplicate(true)
	_avenue_done = true
	var solid: Array[Rect2] = []
	for d: Dictionary in structures():
		solid.append((d.rect as Rect2).grow(0.15))
	for r: Rect2 in Citadel.TOWERS + Citadel.WALLS + [Citadel.KEEP]:
		solid.append(Rect2(r.position + CITADEL_ORIGIN, r.size).grow(0.3))
	for r: Rect2 in _fixed_ground():
		solid.append(r.grow(0.4))
	for g: Rect2 in gardens():
		solid.append(g.grow(0.3))
	for p: Dictionary in street_props():
		solid.append((p.rect as Rect2).grow(0.35))
	for p: Array in POCKETS:
		solid.append((p[0] as Rect2).grow(0.3))
	var points: Array[Vector2] = []
	points.append_array(torches())
	var an := anchors()
	for k: String in an:
		points.append_array(an[k])
	var posts := soldier_posts()
	for k: String in posts:
		points.append_array(posts[k])
	for loop: Dictionary in patrol_loops():
		points.append_array(loop.points)
	var others: Array[Vector2] = []
	for row: Array in GARDEN_DECOR + DRILL_DECOR + YARD_DECOR + CLOSE_DECOR + KEEP_DECOR + LISTS_DECOR:
		others.append(row[1])
	for d: Dictionary in pocket_decor():
		others.append(d.at)
	var streets := roads()
	var n := 0
	for ring: Rect2 in [INNER.grow(-TownLayout.WALL_T - 0.4), OUTER.grow(-TownLayout.WALL_T - 0.4)]:
		for line: Array in AVENUES:
			var segs: Array = []
			_segments(segs, line, AVENUE_W)
			for road: Rect2 in segs:
				var r := road.intersection(ring)
				if r.size.x <= 0.0 or r.size.y <= 0.0:
					continue
				var along_y := r.size.y > r.size.x
				var length := r.size.y if along_y else r.size.x
				for side: float in [-1.0, 1.0]:
					var k := AVENUE_STEP * 0.5
					var turn := 0
					while k < length:
						var at := Vector2(r.position.x - AVENUE_OUT if side < 0.0 else r.end.x + AVENUE_OUT, r.position.y + k) 							if along_y else Vector2(r.position.x + k, r.position.y - AVENUE_OUT if side < 0.0 else r.end.y + AVENUE_OUT)
						k += AVENUE_STEP
						turn += 1
						if not _avenue_clear(at, road, streets, solid, points, others, ring):
							continue
						others.append(at)
						n += 1
						if turn % 2 == 1:
							_avenue.append({"kind": Decor.Kind.OAK if n % 3 else Decor.Kind.PINE, "at": at,
								"size": Vector2(25.0 + float(n % 4) * 1.5, 0.0), "half": AVENUE_TRUNK})
						else:
							_avenue.append({"kind": Decor.Kind.LAMP, "at": at, "size": Vector2.ZERO})
	return _avenue.duplicate(true)


## Whether an avenue piece may stand at `at` beside `road` (avenue_decor()).
func _avenue_clear(at: Vector2, road: Rect2, streets: Array, solid: Array[Rect2], points: Array[Vector2],
		others: Array[Vector2], ring: Rect2) -> bool:
	if not ring.has_point(at) or _in_fan(Rect2(at - Vector2(0.25, 0.25), Vector2(0.5, 0.5))):
		return false
	for s: Rect2 in streets:
		if s.grow(0.05 if s == road or s.encloses(road) or road.encloses(s) else 0.6).has_point(at):
			return false
	for r: Rect2 in solid:
		if r.has_point(at):
			return false
	for p: Vector2 in points:
		if p.distance_to(at) < 0.45:
			return false
	for p: Vector2 in others:
		if p.distance_to(at) < 0.8:
			return false
	return true


## Thinner shrubs than Aldermere's (polish 3).
func shrub_chance() -> float:
	return SHRUB_CHANCE


## No shrub in a pocket garden or a market corner (POCKETS).
func shrub_clear() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for p: Array in POCKETS:
		out.append((p[0] as Rect2).grow(0.2))
	return out


func fields() -> Array[Rect2]:
	return _typed(FIELDS)


## The Great Market's and the civic square's fountains, then the royal garden's.
func fountains() -> Array[Rect2]:
	return _typed(FOUNTAINS + [GARDEN_FOUNTAIN])


func wells() -> Array[Rect2]:
	return _typed(WELLS)


func taverns() -> Array[Rect2]:
	return _typed(TAVERNS)


## Ground people walk round besides the buildings: the working yards (the tavern's patio, the smithy's and the
## carpenter's yards), the cottage gardens and the street props, as at Aldermere; then the Keep courtyard's pieces.
func blockers() -> Array[Rect2]:
	var out: Array[Rect2] = [TAVERN_PATIO, SMITHY_YARD, CARPENTER_YARD]
	out.append_array(gardens())
	for p: Dictionary in street_props():
		out.append(p.rect)
	out.append_array(court_blockers())
	return out


## The Keep courtyard's pieces (KEEP_COURT): the garden's, then the dummies, then the drill yard's gear; then the service
## yard's (KEEP_YARD, polish 2), then the cathedral close's (CLOSE_DECOR), then the Keep's grounds' (KEEP_DECOR), the
## tournament field's (LISTS_DECOR), the pockets' (pocket_decor()) and the avenues' (avenue_decor(), polish 3).
func court_decor() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Array in GARDEN_DECOR:
		out.append({"kind": row[0], "at": row[1], "size": row[2] if row.size() > 2 else Vector2.ZERO})
	for g: Vector2 in DRILL_DUMMIES:
		out.append({"kind": Decor.Kind.SCARECROW, "at": g, "size": Vector2.ZERO, "scale": DUMMY_SCALE})
	for row: Array in DRILL_DECOR:
		out.append({"kind": row[0], "at": row[1], "size": Vector2.ZERO})
	for row: Array in YARD_DECOR:
		out.append({"kind": row[0], "at": row[1], "size": Vector2.ZERO})
	for row: Array in CLOSE_DECOR:
		out.append({"kind": row[0], "at": row[1], "size": row[2]})
	for row: Array in KEEP_DECOR:
		out.append({"kind": row[0], "at": row[1], "size": row[2]})
	for row: Array in LISTS_DECOR:
		out.append({"kind": row[0], "at": row[1], "size": row[2]})
	out.append_array(pocket_decor())
	out.append_array(avenue_decor())
	return out


## The ground each courtyard piece closes (COURT_HALF about its point; a bench along its length).
func court_blockers() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d: Dictionary in court_decor():
		var half: float = d.get("half", COURT_HALF[d.kind])
		var r := Rect2(d.at, Vector2.ZERO).grow(half)
		if d.kind in [Decor.Kind.BENCH, Decor.Kind.FENCE]:
			r = r.merge(Rect2(d.at + d.size, Vector2.ZERO).grow(half))
		out.append(r)
	return out


## The drill: for each dummy, DRILL_RANKS west of it, a spot facing it.
func drill_spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g: Vector2 in DRILL_DUMMIES:
		for off: float in DRILL_RANKS:
			out.append({"at": g - Vector2(off, 0.0), "face": g})
	return out


## Fenced vegetable gardens beside the cottages (not the townhouses), as at Aldermere (TownLayout.gardens()): a plot
## along one of a cottage's sides, those facing the camera first, on its house block, TownLayout.GARDEN_STREET_CLEAR
## from the streets, out of the gates' queue fans, GARDEN_CLEAR from every other building and square, and clear of the
## other gardens. Worked out once.
func gardens() -> Array[Rect2]:
	if _gardens_done:
		return _gardens.duplicate()
	_gardens_done = true
	var others: Array[Rect2] = []
	for d: Dictionary in structures():
		others.append(d.rect)
	others.append_array(_fixed_ground())
	for r: Rect2 in Citadel.TOWERS + Citadel.WALLS + [Citadel.KEEP]:
		others.append(Rect2(r.position + CITADEL_ORIGIN, r.size))
	var blocks: Array[Rect2] = []
	for d: Rect2 in districts():
		blocks.append(d.grow(-0.05))
	var streets := roads()
	var hs := houses()
	for i in hs.size():
		var h := hs[i]
		if _townhouse.get(h, false) or ArtKit.hash01(SALT_GARDEN, i * 2) > TownLayout.GARDEN_CHANCE:
			continue
		var long_x := minf(h.size.x + 0.2, TownLayout.GARDEN_LONG)
		var long_y := minf(h.size.y + 0.2, TownLayout.GARDEN_LONG)
		var gap := TownLayout.GARDEN_GAP
		var short := TownLayout.GARDEN_SHORT
		var sides := [
			Rect2(Vector2(h.position.x - 0.05, h.end.y + gap), Vector2(long_x, short)),
			Rect2(Vector2(h.end.x + gap, h.position.y - 0.05), Vector2(short, long_y)),
			Rect2(Vector2(h.position.x - 0.05, h.position.y - gap - short), Vector2(long_x, short)),
			Rect2(Vector2(h.position.x - gap - short, h.position.y - 0.05), Vector2(short, long_y)),
		]
		var order := [0, 1, 3, 2] if ArtKit.hash01(SALT_GARDEN, i * 2 + 1) < 0.5 else [1, 0, 3, 2]
		for k in 4:
			var plot: Rect2 = sides[order[k]]
			var ok := false
			for bl in blocks:
				ok = ok or bl.encloses(plot)
			for road: Rect2 in streets:
				ok = ok and not road.grow(TownLayout.GARDEN_STREET_CLEAR).intersects(plot)
			ok = ok and not _in_fan(plot.grow(0.1))
			for o in others:
				ok = ok and not o.grow(0.1 if o == h else GARDEN_CLEAR).intersects(plot)
			for g in _gardens:
				ok = ok and not g.grow(0.45).intersects(plot)
			# (polish 3) Never on another house's doorstep: the ground just before its front stays a way in.
			for o_h: Rect2 in hs:
				ok = ok and (o_h == h or not Rect2(Vector2(o_h.get_center().x - DOORSTEP.x * 0.5, o_h.end.y + 0.1),
					DOORSTEP).intersects(plot))
			if ok:
				_gardens.append(plot)
				break
	return _gardens.duplicate()


## Props lining the streets inside both rings, as at Aldermere (TownLayout.street_props()): each {"rect", "kind" (a
## TownLayout.Prop), "along_y"}, every TownLayout.STREET_PROP_STEP along each side of each street, in the margin before
## the houses, clear of junctions, squares, gates and their queues, every building, garden, torch and fountain, and
## only against a building's front (PROP_BACK behind both its ends and its middle lies in a building or garden), never
## across the mouth of an alley people walk into; a spot that is not clear is skipped. Worked out once.
func street_props() -> Array[Dictionary]:
	if _props_done:
		return _props.duplicate(true)
	_props_done = true
	var clear_of: Array[Rect2] = []
	var backs: Array[Rect2] = []
	for d: Dictionary in structures():
		var r: Rect2 = d.rect
		var grow := 0.03 if d.role in [&"house", CapitalPlots.ROLE] else (0.5 if d.kind == Structure.Kind.GATE else 0.3)
		clear_of.append(r.grow(grow))
		var walked: bool = d.kind in Structure.WALKABLE or (d.role == CapitalPlots.ROLE
			and bool(BuildingTypes.info(d.tag).get("walkable", false)))
		if not walked:
			backs.append(r)
	for g: Rect2 in gardens():
		clear_of.append(g.grow(0.03))
		backs.append(g)
	for r: Rect2 in _fixed_ground():
		clear_of.append(r.grow(0.3))
	for p: Vector2 in torches():
		clear_of.append(Rect2(p, Vector2(0.2, 0.2)).grow(0.3))
	for r: Rect2 in Citadel.TOWERS + Citadel.WALLS + [Citadel.KEEP]:
		clear_of.append(Rect2(r.position + CITADEL_ORIGIN, r.size).grow(0.3))
	var streets := roads()
	var n := 0
	for inner: Rect2 in [INNER.grow(-TownLayout.WALL_T - 0.4), OUTER.grow(-TownLayout.WALL_T - 0.4)]:
		for road: Rect2 in streets:
			var along_y := road.size.y > road.size.x
			var r := road.intersection(inner)
			if r.size.x <= 0.0 or r.size.y <= 0.0:
				continue
			var length := r.size.y if along_y else r.size.x
			for side: float in [-1.0, 1.0]:
				var k := TownLayout.STREET_PROP_STEP * (0.25 if side < 0.0 else 0.75)
				while k < length:
					n += 1
					var kind := TownLayout._prop_kind(ArtKit.hash01(SALT_PROP, n), along_y)
					var size: Vector2 = TownLayout.PROP_SIZE[kind]
					var dims := Vector2(size.y, size.x) if along_y else size
					var at: Vector2
					if along_y:
						var x := r.position.x - TownLayout.STREET_PROP_GAP - dims.x if side < 0.0 \
							else r.end.x + TownLayout.STREET_PROP_GAP
						at = Vector2(x, r.position.y + k - dims.y * 0.5)
					else:
						var y := r.position.y - TownLayout.STREET_PROP_GAP - dims.y if side < 0.0 \
							else r.end.y + TownLayout.STREET_PROP_GAP
						at = Vector2(r.position.x + k - dims.x * 0.5, y)
					k += TownLayout.STREET_PROP_STEP
					var rect := Rect2(at, dims)
					# Its back edge's two ends, a little in from them, and its middle, then PROP_BACK further from the
					# street: a long prop whose middle faces an alley mouth is not against a front.
					var away := Vector2(side, 0.0) if along_y else Vector2(0.0, side)
					var edge := (rect.end.x if side > 0.0 else rect.position.x) if along_y \
						else (rect.end.y if side > 0.0 else rect.position.y)
					var mid := rect.get_center()
					var samples := [Vector2(edge, rect.position.y + 0.05), Vector2(edge, mid.y),
						Vector2(edge, rect.end.y - 0.05)] if along_y \
						else [Vector2(rect.position.x + 0.05, edge), Vector2(mid.x, edge), Vector2(rect.end.x - 0.05, edge)]
					var against := true
					for g: Vector2 in samples:
						against = against and _in_rects(g + away * PROP_BACK, backs)
					if against and _prop_clear(rect, road, streets, clear_of, inner):
						_props.append({"rect": rect, "kind": kind, "along_y": along_y})
						clear_of.append(rect.grow(0.5))
	return _props.duplicate(true)


## Each gate's queue fan, as at Aldermere (TownLayout.queue_fans()): from the doorway into the ring out to the last
## queue row, widening as the rows do, grown by `margin`; in gate order (gate_plazas()).
func queue_fans(margin := 0.3) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for ring: Array in _rings():
		for at: Vector2 in ring[1]:
			var gate: Rect2 = TownLayout.ring_gatehouse(ring[0], at).gate
			var dir := -_inward(ring[0], at)
			var side := Vector2(-dir.y, dir.x)
			var face := gate.get_center() - dir * (absf(gate.size.dot(dir)) * 0.5 + Crowd.GATE_DOOR)
			var far := Crowd.QUEUE_DEPTH0 + Crowd.QUEUE_REACH
			var near_half := 1.2 + margin
			var far_half := 1.2 + far * 0.6 + margin
			out.append(PackedVector2Array([face + dir * margin + side * near_half, face + dir * margin - side * near_half,
				face - dir * (far + margin) - side * far_half, face - dir * (far + margin) + side * far_half]))
	return out


func trails() -> Array:
	return TRAILS.duplicate(true)


func road_trails() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Array in ROAD_TRAILS:
		out.append({"points": (row[0] as Array).duplicate(), "width": row[1]})
	return out


func outcrops() -> Array:
	return OUTCROPS.duplicate(true)


func boats() -> Array[Vector2]:
	return _vectors(BOATS)


func scarecrows() -> Array[Vector2]:
	return _vectors(SCARECROWS)


func signposts() -> Array[Vector2]:
	return _vectors(SIGNPOSTS)


func carts() -> Array[Vector2]:
	return _vectors(CARTS)


## The roads' gaps (CityDef's), and the harbour district: its quays and streets stay open ground; and the ground under
## and beside the aqueduct (AQUEDUCT_CLEAR), so its arches read.
func forest_gaps() -> Array[Rect2]:
	var out := super.forest_gaps()
	out.append(landmark(&"harbour_district"))
	out.append(AQUEDUCT_CLEAR)
	return out


## No tree, forest or meadow, under or beside the aqueduct's arches (AQUEDUCT_CLEAR).
func tree_clear() -> Array[Rect2]:
	return [AQUEDUCT_CLEAR]


## Where citizens go about their day, by kind, as Aldermere's anchors (TownLayout.anchors()): "home" in front of each
## house and of the ChatGPT sets people live in (CapitalPlots.HOMES), out of the gates' queue fans as at Aldermere;
## "stall" before each stall, "craft" at the smithy's and carpenter's yards, the workshop and each craft set (CRAFTS),
## "tavern" at the inns, "cathedral" on its steps, "plaza" the squares' and gate plazas' quarter points, "water" by the
## fountains and wells, "field", "mill", "dock", "barn" (the farmhouses) and "bell" (the bell tower's foot). Then the
## capital's routine points (spec section 3), each from its district's buildings:
##   "work"     the fronts of the civic, guild and trade buildings (WORKS: the guild quarter, the cathedral square, the
##              Great Market, the old town houses, the harbour's stables, the road quarter's inn and stables);
##   "queue"    the crafts quarter's bakery: its counter on the west bridge avenue, then the bread queue up the avenue;
##   "wash"     beside the wash houses on the old town's river bank;
##   "pray"     before the new town's chapel and monastery hill's chapel, monastery and graveyard;
##   "market"   the Great Market's and the west market's quarter points, the market hall, weigh house and crier's stage;
##   "harbour"  on the quay by the warehouses, the crane and the fish market, and the ferry quay;
##   "gate"     the middle of each gate's plaza (every district's way in and out);
##   "field"    before each field (the west farms and the south-east fields).
func anchors() -> Dictionary:
	var out := {"home": [], "stall": [], "craft": [], "tavern": [], "cathedral": [], "plaza": [], "water": [],
		"field": [], "mill": [], "dock": [], "barn": [], "bell": [], "work": [], "queue": [], "wash": [], "pray": [],
		"market": [], "harbour": [], "gate": []}
	for h: Rect2 in houses():
		out.home.append(Vector2(h.get_center().x, h.end.y + 0.35))
	for d: Dictionary in _buildings():
		var r: Rect2 = d.rect
		var front := Vector2(r.get_center().x, r.end.y + 0.35)
		if d.tag in CapitalPlots.HOMES:
			out.home.append(front)
		elif d.tag in CRAFTS:
			out.craft.append(front)
		elif d.tag == &"gpt_inn":
			out.tavern.append(Vector2(r.get_center().x, r.end.y + 0.4))
		if d.tag in WORKS:
			out.work.append(front)
		if d.tag == &"gpt_bakery":
			# The counter at its avenue side, then the queue up the avenue's edge, QUEUE_STEP apart.
			for k in QUEUE_LENGTH:
				out.queue.append(Vector2(r.position.x - QUEUE_OFF, r.get_center().y - k * QUEUE_STEP))
		elif d.tag == &"gpt_washhouse":
			# Either side of its dry part (its washing steps stand over the river), and at its back, where the washing
			# is carried in.
			var dry := _dry(d)
			out.wash.append(Vector2(r.position.x - 0.35, dry.get_center().y))
			out.wash.append(Vector2(r.end.x + 0.35, dry.get_center().y))
			out.wash.append(Vector2(r.get_center().x, r.position.y - 0.35))
		elif d.tag in [&"gpt_chapel", &"gpt_monastery", &"gpt_graveyard"]:
			out.pray.append(Vector2(r.get_center().x, r.end.y + 0.4))
		elif d.tag in [&"gpt_markethall", &"gpt_weighhouse", &"gpt_crierstage"]:
			out.market.append(front)
		elif d.tag in [&"gpt_warehouse", &"gpt_crane", &"gpt_fishmarket"]:
			# The fish market's front; behind a set standing over the water, on the land.
			out.harbour.append(Vector2(r.get_center().x, r.position.y - 0.35) if BuildingTypes.over_water(d.tag) else front)
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
	for pl: Rect2 in [MARKET_SQUARE, WEST_MARKET]:
		for k in 4:
			out.market.append(pl.position + pl.size * Vector2(0.25 + 0.5 * (k % 2), 0.25 + 0.5 * (k / 2)))
	for pl: Rect2 in gate_plazas():
		out.gate.append(pl.get_center())
	out.work.append_array(YARD_WORK)
	out.pray.append_array(CLOSE_PRAY)
	out.market.append_array(CLOSE_MARKET)
	out.harbour.append(DOCK_WAIT.get_center())
	for w: Rect2 in _typed(FOUNTAINS) + wells():
		out.water.append(Vector2(w.get_center().x, w.end.y + 0.3))
		out.water.append(Vector2(w.end.x + 0.3, w.get_center().y))
	for f: Rect2 in FIELDS:
		out.field.append(Vector2(f.get_center().x, f.end.y + 0.3))
	out.mill.append(Vector2(WINDMILL.get_center().x, WINDMILL.end.y + 0.4))
	out.dock.append(Vector2(DOCK.get_center().x, DOCK.position.y - 0.4))
	for b: Rect2 in BARNS:
		out.barn.append(Vector2(b.get_center().x, b.end.y + 0.4))
	out.bell.append(Vector2(BELL_TOWER.position.x - 0.45, BELL_TOWER.get_center().y))
	var homes := []
	for g: Vector2 in out.home:
		if not _in_fan(Rect2(g - Vector2(0.05, 0.05), Vector2(0.1, 0.1))):
			homes.append(g)
	out.home = homes
	return out


## Who lives where (spec section 3): about 420 citizens, by district, by job (CitizenProfile.JOBS). The old town's
## upper quarters hold the nobles, the clergy and the guilds; the Great Market its merchants and traders; the harbour
## its dockworkers and ferrymen; the new town its crafts, bakers and washers; the poor quarter its labourers and
## beggars; monastery hill its monks; the farms their farmers. The Royal Keep holds only soldiers.
func spawn_roles() -> Dictionary:
	return SPAWN_ROLES.duplicate(true)


func citizens() -> int:
	var n := 0
	for d: StringName in SPAWN_ROLES:
		for job: StringName in SPAWN_ROLES[d]:
			n += int(SPAWN_ROLES[d][job])
	return n


## The garrison: every post soldier_posts() lays out, about 180.
func soldiers() -> int:
	var n := 0
	var posts := soldier_posts()
	for k: String in posts:
		n += (posts[k] as Array).size()
	return n


## Where the soldiers stand (spec section 3), by the crowd's groups (CityDef.soldier_posts()):
##   "yard"     the Keep's garrison in the barracks yard (POSTS_YARD; its first are the rescue squads), its last at
##              the drill yard's drill spots (drill_spots());
##   "walls"    two guards inside every gate of both rings, the exits' gates first (the west gate, the harbour gate, the
##              barbican), two more outside the barbican, two at the Keep's watchtower (polish 3), two at each end
##              of every bridge, and the harbour watch on the quays (HARBOUR_WATCH);
##   "citadel"  the Keep's garrison round the Citadel, on the rally ring (POSTS_CITADEL);
##   "patrol"   the wall patrols, in pairs at their loops' starts (patrol_loops()), then street patrols in pairs along
##              the streets inside both rings (STREET_PAIRS).
## Worked out once.
func soldier_posts() -> Dictionary:
	if not _posts.is_empty():
		return _posts.duplicate(true)
	var yard: Array[Vector2] = []
	var cols := 8
	var drills := drill_spots()
	for k in POSTS_YARD - drills.size():
		yard.append(BARRACKS_YARD.position + Vector2(0.35 + (k % cols) * (BARRACKS_YARD.size.x - 0.7) / (cols - 1),
			0.4 + (k / cols) * 0.6))
	for d: Dictionary in drills:
		yard.append(d.at)
	var walls: Array[Vector2] = []
	var gates: Array = []  # [ring, gate point], the exits' gates first
	for k in [0, 4]:
		gates.append([INNER, INNER_GATES[k]])
	gates.append([OUTER, OUTER_GATES[3]])
	for k in [1, 2, 3]:
		gates.append([INNER, INNER_GATES[k]])
	for k in [0, 1, 2]:
		gates.append([OUTER, OUTER_GATES[k]])
	for g: Array in gates:
		var inward := _inward(g[0], g[1])
		var mid := _wall_mid(g[0], g[1])
		var side := Vector2(-inward.y, inward.x)
		for sgn: float in [-1.0, 1.0]:
			walls.append(mid + inward * GUARD_IN + side * GUARD_SIDE * sgn)
	var barbican: Vector2 = OUTER_GATES[3]
	var b_out := -_inward(OUTER, barbican)
	for sgn: float in [-1.0, 1.0]:
		walls.append(_wall_mid(OUTER, barbican) + b_out * GUARD_IN + Vector2(-b_out.y, b_out.x) * GUARD_SIDE * sgn)
	for d: Dictionary in _buildings():
		if d.tag in [&"gpt_barbican", &"gpt_drawbridge"]:
			var r: Rect2 = d.rect
			walls.append(Vector2(r.position.x + 0.4, r.end.y + 0.45))
			walls.append(Vector2(r.end.x - 0.4, r.end.y + 0.45))
		elif d.tag == &"gpt_watchtower":
			# The Keep's two guards (polish 3: the barbican's, once), either side of the watchtower's foot.
			var r: Rect2 = d.rect
			walls.append(Vector2(r.position.x - 0.3, r.end.y + 0.45))
			walls.append(Vector2(r.end.x + 0.3, r.end.y + 0.45))
	for r: Rect2 in BRIDGES:
		var cx := r.get_center().x
		var half := r.size.x * 0.5 + BRIDGE_GUARD_SIDE
		# The north end on the bank beside the bridge, the south end just inside the new town's gate.
		walls.append(Vector2(cx - half, RIVER.position.y - 1.0))
		walls.append(Vector2(cx + half, RIVER.position.y - 1.0))
		walls.append(Vector2(cx - 0.5, OUTER.position.y + 1.3))
		walls.append(Vector2(cx + 0.5, OUTER.position.y + 1.3))
	walls.append_array(_vectors(HARBOUR_WATCH))
	var citadel: Array[Vector2] = []
	for k in POSTS_CITADEL:
		var a := TAU * float(k) / float(POSTS_CITADEL)
		citadel.append(CITADEL_ORIGIN + Vector2(cos(a), sin(a)) * Crowd.RING_RADIUS)
	var patrol: Array[Vector2] = []
	for loop: Dictionary in patrol_loops():
		var points: Array = loop.points
		var pairs := int(loop.walkers) / 2
		for k in pairs:
			var at: Vector2 = points[CityDef.loop_start(k, pairs, points.size())]
			patrol.append(at)
			patrol.append(at)
	var streets: Array[Rect2] = []
	for ring: Rect2 in [INNER, OUTER]:
		for road: Rect2 in roads():
			var r := road.intersection(ring.grow(-TownLayout.WALL_T - 1.0))
			if r.size.x > 2.0 or r.size.y > 2.0:
				streets.append(r)
	for i in STREET_PAIRS:
		var road := streets[i % streets.size()]
		var along := (float(i / streets.size()) + 0.5) / ceilf(float(STREET_PAIRS) / streets.size())
		var at := Vector2(road.get_center().x, lerpf(road.position.y, road.end.y, along)) if road.size.y > road.size.x \
			else Vector2(lerpf(road.position.x, road.end.x, along), road.get_center().y)
		patrol.append(at)
		patrol.append(at)
	_posts = {"yard": yard, "walls": walls, "citadel": citadel, "patrol": patrol}
	return _posts.duplicate(true)


## The wall patrols' loops: one just inside each ring's wall (LOOP_IN from its inner face), a point about every
## LOOP_STEP round it, clockwise on the plan from the north-west corner; walked in pairs by LOOP_WALKERS of each ring.
func patrol_loops() -> Array:
	var out: Array = []
	for k in 2:
		var ring: Rect2 = [INNER, OUTER][k]
		var r := ring.grow(-TownLayout.WALL_T - LOOP_IN)
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		var points: Array[Vector2] = []
		for c in 4:
			var a: Vector2 = corners[c]
			var b: Vector2 = corners[(c + 1) % 4]
			var n := maxi(1, roundi(a.distance_to(b) / LOOP_STEP))
			for j in n:
				points.append(a.lerp(b, float(j) / float(n)))
		out.append({"points": points, "walkers": LOOP_WALKERS[k]})
	return out


## Each district's ways out (spec section 3): the new town's quarters by the barbican and the south road only; the old
## town by its west gate, over the bridges to the barbican, or (its east side and the guilds) the harbour gate to the
## ferry; the harbour by its ferry, or back through the town; the countryside by whichever road or landing serves it.
func district_exits() -> Dictionary:
	var ex := exits()
	var south: Vector2 = ex[0]
	var west: Vector2 = ex[1]
	var ferry: Vector2 = ex[2]
	return {
		&"royal_keep": [west, south], &"keep_yard": [west, south], &"noble_quarter": [west, south], &"cathedral_square": [west, south, ferry],
		&"guild_quarter": [ferry, south, west], &"great_market": [west, south], &"old_town_houses": [south, ferry, west],
		&"harbour_district": [ferry, south], &"crafts_quarter": [south], &"new_town": [south], &"tanners_dyers": [south],
		&"poor_quarter": [south], &"road_quarter": [south], &"monastery_hill": [west], &"northern_woods": [ferry, west],
		&"west_farms": [south], &"south_east_fields": [south], &"suburbs": [south], &"tournament_field": [south],
	}


## A ring gate's way out is away from its ring: the old town's west gate west, its river gates south over the bridges,
## its harbour gate east; the new town's river gates north over the bridges and the barbican south. A gate's crowd waits
## on its ring's side, so the old town queues for the bridges and the new town for the barbican, while those coming off
## a bridge into the new town walk straight on. INF for anything else.
func gate_outward(gate: Rect2) -> Vector2:
	if _outward.is_empty():
		for ring: Array in _rings():
			for at: Vector2 in ring[1]:
				_outward[TownLayout.ring_gatehouse(ring[0], at).gate] = -_inward(ring[0], at)
	return _outward.get(gate, Vector2.INF)


## The capital's ~600 people (Task 14, the crowd LOD): those off screen update every 6th frame, half Aldermere's
## rate -- a frame steps ~100 fewer people at play zoom. Nobody sees a stride or a light reading off screen.
func offscreen_every() -> int:
	return Person.OFFSCREEN_EVERY * 2


## The capital's gatehouses are wide double gates: two pass in the time Aldermere's lets one (Crowd.GATE_INTERVAL).
func gate_interval() -> float:
	return GATE_INTERVAL


## A bridge falls into the water and closes it; its ends on the banks and in the gates stay open ground.
func fallen_bridge(footprint: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r: Rect2 in rivers():
		if r.intersects(footprint):
			out.append(r.intersection(footprint))
	if out.is_empty():
		out.append(footprint)
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
			&"river": RIVER, &"harbour": HARBOUR, &"bridge": BRIDGES[1], &"third_bridge": BRIDGES[2], &"dock": DOCK,
			&"dock_wait": DOCK_WAIT, &"market_square": MARKET_SQUARE, &"west_market": WEST_MARKET,
			&"citadel_court": CITADEL_COURT, &"old_town_wall": INNER, &"new_town_wall": OUTER,
			&"west_gate": inner[0], &"harbour_gate": inner[4], &"barbican": outer[3], &"main_gate": outer[3],
			&"temple": CATHEDRAL, &"barracks": BARRACKS, &"barracks_yard": BARRACKS_YARD, &"workshop": WORKSHOP,
			&"smithy": SMITHY, &"smithy_yard": SMITHY_YARD, &"carpenter": CARPENTER, &"carpenter_yard": CARPENTER_YARD,
			&"tavern_patio": TAVERN_PATIO, &"bell_tower": BELL_TOWER, &"windmill": WINDMILL,
			&"keep_court": KEEP_COURT, &"royal_garden": ROYAL_GARDEN, &"drill_yard": DRILL_YARD, &"keep_yard": KEEP_YARD,
			&"churchyard": CHURCHYARD, &"pilgrim_plaza": PILGRIM_PLAZA,
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
	var plazas: Array[Rect2] = [MARKET_SQUARE, WEST_MARKET, CITADEL_COURT, PILGRIM_PLAZA]
	var yards: Array[Rect2] = [BARRACKS_YARD]
	return {
		&"plazas": plazas, &"yards": yards, &"gate_plazas": gate_plazas(),
		&"building_yards": building_yards, &"farm": farm,
		&"paved": [OUTER.grow(-TownLayout.WALL_T)] as Array[Rect2],
		&"crossings": _typed(BRIDGES),
		&"lawns": [ROYAL_GARDEN] as Array[Rect2], &"paths": _garden_paths(),
	}


## The garden's gravel paths, as the floor paints them: {points, width}.
func _garden_paths() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line: Array in GARDEN_PATHS:
		out.append({"points": line.duplicate(), "width": GARDEN_PATH_W})
	return out


# --- Helpers ---------------------------------------------------------------------------------------------

const WALL_TOWER_HALF := TownLayout.WALL_TOWER * 0.5

## Worked out once (the layout is constant): the structures, the houses (and which are townhouses), the buildings,
## the rings' pieces and the landmarks.
static var _structures: Array[Dictionary] = []
static var _houses: Array[Rect2] = []
static var _townhouse := {}
## Each house plot's GPT housing set (polish 3: _house_rows()).
static var _house_set := {}
static var _buildings_cache: Array[Dictionary] = []
static var _rings_cache: Array[Dictionary] = []
static var _landmarks := {}
static var _gardens: Array[Rect2] = []
static var _gardens_done := false
static var _props: Array[Dictionary] = []
static var _props_done := false
static var _avenue: Array[Dictionary] = []
static var _avenue_done := false
static var _fans: Array[PackedVector2Array] = []
static var _posts := {}
static var _outward := {}


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
			if p.size() > 2 and p[2] is bool:
				out.append(CapitalPlots.on_bank(p[0], p[1].x, p[1].y))
			else:
				out.append(CapitalPlots.plot(p[0], p[1], p.size() > 2 and p[2] == &"turned"))
		_buildings_cache = out
	return _buildings_cache


## The part of a ChatGPT plot on land: all of it but an over-water set's water strip (BuildingTypes.OVER_WATER).
static func _dry(d: Dictionary) -> Rect2:
	var r: Rect2 = d.rect
	return Rect2(r.position, Vector2(r.size.x, r.size.y - float(BuildingTypes.info(d.tag).get("water_depth", 0.0))))


## The open ground no house may take: the squares, yards, patios, gate plazas, the Citadel's court and its whole
## footprint, the fountains and the wells.
func _fixed_ground() -> Array[Rect2]:
	var out: Array[Rect2] = [MARKET_SQUARE, WEST_MARKET, CITADEL_COURT, BARRACKS_YARD, TAVERN_PATIO, SMITHY_YARD,
		CARPENTER_YARD, PILGRIM_PLAZA]
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


static func _vectors(src: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.assign(src)
	return out


static func _in_rects(g: Vector2, rects: Array[Rect2]) -> bool:
	for r in rects:
		if r.has_point(g):
			return true
	return false


## Whether `r` reaches into a gate's queue fan (queue_fans(), worked out once).
func _in_fan(r: Rect2) -> bool:
	if _fans.is_empty():
		_fans = queue_fans()
	var poly := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	for fan in _fans:
		if not Geometry2D.intersect_polygons(poly, fan).is_empty():
			return true
	return false


## A street prop's spot is clear: inside its ring, out of the queue fans, clear of everything in `clear_of`, and of
## every other street by a junction's width (TownLayout.STREET_TREE_JUNCTION).
func _prop_clear(rect: Rect2, road: Rect2, streets: Array, clear_of: Array[Rect2], inner: Rect2) -> bool:
	if not inner.encloses(rect) or _in_fan(rect.grow(0.3)):
		return false
	for c in clear_of:
		if c.intersects(rect):
			return false
	for other: Rect2 in streets:
		if other.grow(0.05 if other == road else TownLayout.STREET_TREE_JUNCTION).intersects(rect):
			return false
	return true


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
