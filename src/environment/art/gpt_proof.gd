class_name GptProof
extends RefCounted
## Dev proof (feat/gpt-buildings-proof): ChatGPT-painted buildings, converted by tools/dev/ref_convert/gpt_convert.py
## into the gpt_* sprite sets. They are shown in the dev showcase district (GptShowcase, the town debug scene only):
## each showcase structure carries its set's name (SHOWCASE_META) and SpriteArt.name_for asks set_for() first while
## sprites are on (F7 still flips everything to procedural). PLOTS can still put a set on one of the town's own plots
## (art only: the structure keeps its kind, role, tag, height and seed); it is empty since the showcase took the
## proof buildings out of the town. Drop this file, GptShowcase and the lookup in SpriteArt.name_for to remove the
## proof; promote a building by giving it its own tag instead.

## The meta a showcase structure carries: the name of the set it draws (GptShowcase).
const SHOWCASE_META := &"gpt_showcase_set"
## Plot (TownLayout footprint) -> sprite set: [Rect2, set name] rows. Empty: the town looks as Develop-Main does.
const PLOTS := []
## How far a footprint may sit from a table plot and still be it (the house plots are computed floats).
const SLACK := 0.01


## The proof's set for `s`: its showcase set, else its plot's (set_for_plot()), else "".
static func set_for(s: Structure) -> String:
	if s.has_meta(SHOWCASE_META):
		return String(s.get_meta(SHOWCASE_META))
	return set_for_plot(s.footprint)


## The proof's set for a structure on `plot`, or "" (not one of its plots).
static func set_for_plot(plot: Rect2) -> String:
	for row: Array in PLOTS:
		var r: Rect2 = row[0]
		if r.position.distance_to(plot.position) <= SLACK and r.size.distance_to(plot.size) <= SLACK:
			return row[1]
	return ""
