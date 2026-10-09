class_name BuildingTypes
extends RefCounted
## The gameplay of the ChatGPT building sets (the capital's plots, CapitalPlots): one row per gpt_* set, the single
## source of what each one is in play. CapitalPlots plots a set with its kind and height from here, and a structure of
## role CapitalPlots.ROLE takes its health, walkability and flatness from here (Structure.setup()); FireManager reads
## whether it burns, Town whether it smokes. Aldermere has no such plots, so none of this touches it.
##
## Each set maps to the closest existing Structure.Kind, so it keeps that kind's behaviour (how it falls, its sound, what
## the town's rules make of it); only what differs is data. No new kind was needed:
## - hp: its own health, sized to what it is (a shack 25, a cottage-sized workshop 50, a stone civic hall 100-140, the
##   keep's outworks 140-180).
## - walkable: people walk over it while it stands (the bridges, the ferry landing, the sluice's deck, the district
##   gate's paving under its arch, the vineyard). The fishpond's rim and the monument's plinth are not walked on.
## - flat: drawn under the people on it (the bridges, the ferry landing, the sluice, the vineyard). The district gate's
##   arch stands up over them, as a town gate does.
## - burns: a fire-kind hit can set it alight and a fire can spread to it (FireManager). Bare masonry (the walls,
##   towers and gates, the cistern, the fishpond, the aqueduct, the sluice, the monuments, the graveyard) never does;
##   the wooden landing does not either, as the dock does not.
## - smokes: it smokes from its chimney, exactly the sets whose art carries a chimney key (the manifest's "chimney").
## Damaged and ruins come from each set's own stills; a fall is the engine's sink (the sets have no collapse strips).
## The props (wagon, hand cart) are decor, never placed; they keep a row so every set has one.
## - over water (OVER_WATER, polish 1): a set painted with water at its quay (the crane, the ferry landing, the dock
##   warehouse, the wash house, the sluice) has had that water cut from its stills (gpt_convert.py cut_water) and stands
##   over the city's real water: the front (south) strip of its plot this deep, the manifest's water_depth for its art,
##   lies on the river or the basin from the bank, the rest on land. Only that strip may be wet (the off-river test);
##   the water under it stays closed to walkers (WalkGrid), and it is not a crossing (Town.bridges).

const K := Structure.Kind

## tag -> [kind, hp, walkable, flat, burns, smokes]
const TYPES := {
	&"gpt_alleysteps": [K.HOUSE, 60.0, false, false, false, false],
	&"gpt_aqueduct": [K.CASTLE_WALL, 90.0, false, false, false, false],
	&"gpt_armoury": [K.BARRACKS, 150.0, false, false, true, true],
	&"gpt_bakery": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_barbican": [K.KEEP, 180.0, false, false, false, false],
	&"gpt_bathhouse": [K.HOUSE, 60.0, false, false, true, true],
	&"gpt_beehives": [K.HOUSE, 20.0, false, false, true, false],
	&"gpt_brewery": [K.HOUSE, 70.0, false, false, true, true],
	&"gpt_butcher": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_chapel": [K.TEMPLE, 120.0, false, false, true, false],
	&"gpt_charcoal": [K.HOUSE, 40.0, false, false, true, true],
	&"gpt_cistern": [K.FOUNTAIN, 120.0, false, false, false, false],
	&"gpt_cooper": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_courthouse": [K.HOUSE, 110.0, false, false, true, true],
	&"gpt_crane": [K.HOUSE, 60.0, false, false, true, false],
	&"gpt_crierstage": [K.HOUSE, 30.0, false, false, true, false],
	&"gpt_districtgate": [K.KEEP, 150.0, true, false, false, false],
	&"gpt_dovecote": [K.HOUSE, 40.0, false, false, true, false],
	&"gpt_drawbridge": [K.KEEP, 160.0, false, false, false, false],
	&"gpt_dyers": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_farmhouse": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_ferry": [K.BRIDGE, 80.0, true, true, false, false],
	&"gpt_fishmarket": [K.MARKET_STALL, 40.0, false, false, true, false],
	&"gpt_fishpond": [K.FOUNTAIN, 60.0, false, false, false, false],
	&"gpt_footbridge": [K.BRIDGE, 140.0, true, true, false, false],
	&"gpt_gallows": [K.HOUSE, 30.0, false, false, true, false],
	&"gpt_glassworks": [K.HOUSE, 60.0, false, false, true, true],
	&"gpt_granary": [K.HOUSE, 60.0, false, false, true, true],
	&"gpt_grandstand": [K.HOUSE, 60.0, false, false, true, false],
	&"gpt_graveyard": [K.TEMPLE, 80.0, false, false, false, false],
	&"gpt_guildhall": [K.HOUSE, 100.0, false, false, true, true],
	&"gpt_handcart": [K.HOUSE, 15.0, false, false, true, false],
	&"gpt_hospital": [K.HOUSE, 90.0, false, false, true, true],
	&"gpt_hut": [K.HOUSE, 35.0, false, false, true, true],
	&"gpt_icehouse": [K.HOUSE, 80.0, false, false, false, false],
	&"gpt_inn": [K.HOUSE, 80.0, false, false, true, true],
	&"gpt_jail": [K.HOUSE, 90.0, false, false, true, true],
	&"gpt_latrine": [K.HOUSE, 20.0, false, false, true, false],
	&"gpt_leperhouse": [K.HOUSE, 45.0, false, false, true, true],
	&"gpt_library": [K.HOUSE, 90.0, false, false, true, false],
	&"gpt_lumberyard": [K.HOUSE, 50.0, false, false, true, false],
	&"gpt_manor": [K.HOUSE, 120.0, false, false, true, true],
	&"gpt_markethall": [K.HOUSE, 100.0, false, false, true, false],
	&"gpt_masonyard": [K.HOUSE, 70.0, false, false, true, false],
	&"gpt_milestone": [K.SHRINE, 40.0, false, false, false, false],
	&"gpt_monastery": [K.TEMPLE, 180.0, false, false, true, true],
	&"gpt_monument": [K.SHRINE, 120.0, false, false, false, false],
	&"gpt_noticeboard": [K.HOUSE, 20.0, false, false, true, false],
	&"gpt_orchard": [K.TREE, 30.0, false, false, true, false],
	&"gpt_patrician": [K.HOUSE, 70.0, false, false, true, true],
	&"gpt_pavilion": [K.HOUSE, 40.0, false, false, true, false],
	&"gpt_pens": [K.HOUSE, 30.0, false, false, true, false],
	&"gpt_playstage": [K.HOUSE, 40.0, false, false, true, false],
	&"gpt_potter": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_rowhouses": [K.HOUSE, 80.0, false, false, true, true],
	&"gpt_school": [K.HOUSE, 60.0, false, false, true, true],
	&"gpt_shacks": [K.HOUSE, 25.0, false, false, true, true],
	&"gpt_shophouse": [K.HOUSE, 60.0, false, false, true, true],
	&"gpt_sluice": [K.BRIDGE, 120.0, true, true, false, false],
	&"gpt_stables": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_tannery": [K.HOUSE, 50.0, false, false, true, true],
	&"gpt_tenement": [K.HOUSE, 80.0, false, false, true, true],
	&"gpt_tiltbarrier": [K.HOUSE, 20.0, false, false, true, false],
	&"gpt_townhall": [K.HOUSE, 120.0, false, false, true, true],
	&"gpt_treasury": [K.HOUSE, 140.0, false, false, true, true],
	&"gpt_vineyard": [K.FARM_FIELD, 20.0, true, true, false, false],
	&"gpt_wagon": [K.HOUSE, 15.0, false, false, true, false],
	&"gpt_warehouse": [K.HOUSE, 90.0, false, false, true, true],
	&"gpt_washhouse": [K.HOUSE, 50.0, false, false, true, false],
	&"gpt_watchtower": [K.KEEP, 140.0, false, false, false, false],
	&"gpt_waysidecross": [K.SHRINE, 40.0, false, false, false, false],
	&"gpt_weavers": [K.HOUSE, 60.0, false, false, true, true],
	&"gpt_weighhouse": [K.HOUSE, 70.0, false, false, true, true],
}


## tag -> how deep its water strip reaches into its plot from the front (south) edge, ground units (OVER_WATER above).
const OVER_WATER := {
	&"gpt_crane": 0.55, &"gpt_ferry": 1.29, &"gpt_sluice": 1.77, &"gpt_warehouse": 0.49, &"gpt_washhouse": 0.54,
}


## The type of set `tag`: {kind, hp, height (its blockout's, CapitalPlots.SETS), walkable, flat, burns, smokes,
## over_water, water_depth (0 when not over water)}; {} for a tag that is not a ChatGPT set.
static func info(tag: StringName) -> Dictionary:
	var row: Array = TYPES.get(tag, [])
	if row.is_empty():
		return {}
	return {"kind": row[0], "hp": row[1], "height": float(CapitalPlots.SETS[tag][1]), "walkable": row[2],
		"flat": row[3], "burns": row[4], "smokes": row[5], "over_water": OVER_WATER.has(tag),
		"water_depth": float(OVER_WATER.get(tag, 0.0))}


## Whether set `tag` stands over water (OVER_WATER); false for anything that is not a ChatGPT set.
static func over_water(tag: StringName) -> bool:
	return OVER_WATER.has(tag)
