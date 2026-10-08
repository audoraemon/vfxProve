class_name GptProof
extends RefCounted
## Dev proof (feat/gpt-buildings-proof): ChatGPT-painted buildings (the defence and faith sheets), converted by
## tools/dev/ref_convert/gpt_convert.py into the gpt_* sprite sets, each drawn on one existing town plot (a temporary
## comparison beside the town's own sprites, not a layout). Art only: the
## structures keep their kind, role, tag, height, seed and everything else, so gameplay is untouched. SpriteArt.name_for
## asks set_for_plot() first while sprites are on (F7 still flips the whole town to procedural). Drop this file and the
## lookup in SpriteArt.name_for to remove the proof; promote it by giving the buildings their own tags instead.

## Plot (TownLayout footprint) -> sprite set. The townhouse and cottage plots are TownLayout.houses()' own rects.
const PLOTS := [
	# TAVERNS[0], the north tavern by the Citadel's lane: the same 2.4 x 1.5 the town hall was blocked out on.
	[Rect2(-9.6, -7.6, 2.4, 1.5), "gpt_townhall"],
	# TAVERNS[1], west of the market, a deep 1.6 x 2.4 plot: the courthouse (2.2 x 1.5 with its porch) drawn mirrored.
	[Rect2(-5.3, -0.6, 1.6, 2.4), "gpt_courthouse"],
	# WORKSHOP, east of the market by the barracks (2.6 x 1.5): the armoury and its open weapon shed (2.3 x 1.2 as
	# blocked out). The carpenter's plot (2.3 x 1.15) matches it exactly but hides behind the south-east corner tower.
	[Rect2(10.2, -1.3, 2.6, 1.5), "gpt_armoury"],
	# Two townhouses (1.3 x 0.95) in the block west of the market: the jail and the treasury.
	[Rect2(-8.4, 1.3796573, 1.3, 0.95), "gpt_jail"],
	[Rect2(-10.389771, -0.38437223, 1.3, 0.95), "gpt_treasury"],
	# A cottage (0.95 x 0.75) in the same block: the watchtower.
	[Rect2(-8.277581, 3.2723403, 0.95, 0.75), "gpt_watchtower"],
	# The faith sheet. TAVERNS[2], east of the market (2.8 x 1.8): the monastery (2.4 x 2.0 as blocked out), beside
	# the bell tower and the east block's cottages.
	[Rect2(5.6, 2.4, 2.8, 1.8), "gpt_monastery"],
	# A townhouse in the east block, north of it: the bathhouse. (The deep townhouse west of the bell tower stands
	# right behind it on screen.)
	[Rect2(7.1, -3.998646, 1.3, 0.95), "gpt_bathhouse"],
	# Two townhouses east of the cathedral: the graveyard by its east side (a deep plot, drawn mirrored) and the
	# chapel north of it. (The townhouses south of the market sit behind the south wall and its tower, and those west
	# of the cathedral behind its corner.)
	[Rect2(3.527535, -7.5, 0.95, 1.3), "gpt_graveyard"],
	[Rect2(5.328989, -10.89543, 1.3, 0.95), "gpt_chapel"],
	# South-east, below the east-west street: the leper house and its yard on a deep townhouse plot (drawn mirrored),
	# and the hospital (2.8 x 1.0 as blocked out) on CARPENTER (2.3 x 1.15), the only long plot left: the south wall
	# and its tower hide its ground floor.
	[Rect2(7.436442, 10.3, 0.95, 1.3), "gpt_leperhouse"],
	[Rect2(11.6, 13.1, 2.3, 1.15), "gpt_hospital"],
]
## How far a footprint may sit from a table plot and still be it (the house plots are computed floats).
const SLACK := 0.01


## The proof's set for a structure on `plot`, or "" (not one of its plots).
static func set_for_plot(plot: Rect2) -> String:
	for row: Array in PLOTS:
		var r: Rect2 = row[0]
		if r.position.distance_to(plot.position) <= SLACK and r.size.distance_to(plot.size) <= SLACK:
			return row[1]
	return ""
