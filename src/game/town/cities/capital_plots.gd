class_name CapitalPlots
extends RefCounted
## The capital's building plots (CapitalCity): the ChatGPT building sets it stands on its plots, each on its own
## blockout footprint and at its blockout height, and the block generator that fills its house blocks.
##
## SETS: every gpt_* set -> [footprint W x D (ground units, W along x as the set is drawn), height]. The footprints
## and heights are the ones the blockouts used (concepts/GPT/blockout_sheets.py, carried into the sprite manifest by
## tools/dev/ref_convert/gpt_convert.py: its showcase plot), so a set stands on exactly the ground its painting fits.
## A plot is never turned: a turned plot draws its set mirrored, and a mirrored painting is lit from the right.
## Its kind (and its health, fire, smoke and walkability) are its building type's (BuildingTypes); the role is ROLE and
## the tag the set's name, which SpriteArt.name_for draws.

const ROLE := &"gpt"
## The props: decor pieces (carts on the streets), never structures, so they are not plotted.
const PROPS := [&"gpt_wagon", &"gpt_handcart"]
## Sets the capital no longer places (polish 1): the footbridge (its third crossing is the stone bridge set) and the
## drawbridge (no gate of the capital faces open water: its river gates land the stone bridges).
const UNUSED := [&"gpt_footbridge", &"gpt_drawbridge"]

const SETS := {
	&"gpt_alleysteps": [Vector2(0.9, 1.0), 32.0],
	&"gpt_aqueduct": [Vector2(1.2, 0.35), 47.0],
	&"gpt_armoury": [Vector2(2.3, 1.2), 22.0],
	&"gpt_bakery": [Vector2(1.66, 1.17), 18.0],
	&"gpt_barbican": [Vector2(2.58, 0.88), 34.0],
	&"gpt_bathhouse": [Vector2(2.1, 1.24), 20.0],
	&"gpt_beehives": [Vector2(1.6, 0.4), 18.0],
	&"gpt_brewery": [Vector2(2.32, 1.51), 24.0],
	&"gpt_butcher": [Vector2(1.7, 1.2), 26.0],
	&"gpt_chapel": [Vector2(2.05, 1.26), 22.0],
	&"gpt_charcoal": [Vector2(1.92, 1.39), 18.0],
	&"gpt_cistern": [Vector2(1.07, 0.8), 44.0],
	&"gpt_cooper": [Vector2(1.52, 1.34), 14.0],
	&"gpt_courthouse": [Vector2(2.2, 1.5), 26.0],
	&"gpt_crane": [Vector2(1.95, 1.5), 25.0],
	&"gpt_crierstage": [Vector2(0.8, 1.22), 40.0],
	&"gpt_districtgate": [Vector2(1.6, 2.1), 51.0],
	&"gpt_dovecote": [Vector2(0.88, 0.91), 30.0],
	&"gpt_drawbridge": [Vector2(2.3, 1.78), 32.0],
	&"gpt_dyers": [Vector2(2.2, 1.29), 20.0],
	&"gpt_farmhouse": [Vector2(2.15, 1.17), 16.0],
	&"gpt_ferry": [Vector2(2.1, 1.8), 15.0],
	&"gpt_fishmarket": [Vector2(1.8, 1.43), 14.0],
	&"gpt_fishpond": [Vector2(1.5, 1.22), 4.0],
	&"gpt_footbridge": [Vector2(2.08, 1.95), 18.0],
	&"gpt_gallows": [Vector2(1.2, 1.42), 50.0],
	&"gpt_glassworks": [Vector2(2.47, 1.28), 22.0],
	&"gpt_granary": [Vector2(1.21, 1.19), 26.0],
	&"gpt_grandstand": [Vector2(2.4, 1.0), 50.0],
	&"gpt_graveyard": [Vector2(2.09, 1.52), 14.0],
	&"gpt_guildhall": [Vector2(1.4, 2.0), 30.0],
	&"gpt_handcart": [Vector2(0.9, 0.4), 9.0],
	&"gpt_hospital": [Vector2(2.8, 1.49), 30.0],
	&"gpt_hut": [Vector2(1.19, 0.87), 22.0],
	&"gpt_icehouse": [Vector2(1.404, 1.482), 22.0],
	&"gpt_inn": [Vector2(3.3, 2.0), 30.0],
	&"gpt_jail": [Vector2(1.1, 0.9), 20.0],
	&"gpt_latrine": [Vector2(0.585, 0.715), 19.0],
	&"gpt_leperhouse": [Vector2(1.9, 1.4), 16.0],
	&"gpt_library": [Vector2(2.04, 1.4), 34.0],
	&"gpt_lumberyard": [Vector2(2.05, 1.37), 16.0],
	&"gpt_manor": [Vector2(3.54, 1.86), 42.0],
	&"gpt_markethall": [Vector2(2.4, 1.4), 20.0],
	&"gpt_masonyard": [Vector2(1.72, 1.19), 16.0],
	&"gpt_milestone": [Vector2(0.224, 0.179), 12.0],
	&"gpt_monastery": [Vector2(2.4, 2.0), 26.0],
	&"gpt_monument": [Vector2(1.17, 1.17), 52.0],
	&"gpt_noticeboard": [Vector2(0.936, 0.078), 26.0],
	&"gpt_orchard": [Vector2(1.5, 1.5), 25.0],
	&"gpt_patrician": [Vector2(0.8, 1.0), 41.0],
	&"gpt_pavilion": [Vector2(1.196, 1.196), 18.0],
	&"gpt_pens": [Vector2(2.04, 1.24), 14.0],
	&"gpt_playstage": [Vector2(1.6, 1.4), 49.0],
	&"gpt_potter": [Vector2(1.76, 1.11), 16.0],
	&"gpt_rowhouses": [Vector2(2.4, 1.12), 28.0],
	&"gpt_school": [Vector2(1.4, 1.32), 20.0],
	&"gpt_shacks": [Vector2(1.47, 0.92), 13.0],
	&"gpt_shophouse": [Vector2(1.0, 1.62), 30.0],
	&"gpt_sluice": [Vector2(0.8, 1.8), 25.0],
	&"gpt_stables": [Vector2(2.2, 1.43), 16.0],
	&"gpt_tannery": [Vector2(1.98, 1.53), 16.0],
	&"gpt_tenement": [Vector2(1.52, 1.25), 42.0],
	&"gpt_tiltbarrier": [Vector2(1.2, 0.08), 14.0],
	&"gpt_townhall": [Vector2(2.4, 1.5), 34.0],
	&"gpt_treasury": [Vector2(1.2, 1.2), 18.0],
	&"gpt_vineyard": [Vector2(1.83, 1.08), 14.0],
	&"gpt_wagon": [Vector2(1.35, 0.48), 19.0],
	&"gpt_warehouse": [Vector2(1.9, 2.05), 40.0],
	&"gpt_washhouse": [Vector2(2.1, 1.55), 20.0],
	&"gpt_watchtower": [Vector2(0.8, 0.8), 46.0],
	&"gpt_waysidecross": [Vector2(0.448, 0.448), 48.0],
	&"gpt_weavers": [Vector2(2.2, 1.24), 30.0],
	&"gpt_weighhouse": [Vector2(1.7, 1.49), 24.0],
}
## The sets people live in (their fronts are homes, CapitalCity.anchors()).
const HOMES := [&"gpt_manor", &"gpt_patrician", &"gpt_rowhouses", &"gpt_tenement", &"gpt_shacks", &"gpt_hut",
	&"gpt_shophouse", &"gpt_farmhouse"]
## The salt a block's row offsets are hashed with (ArtKit.hash01), and its plots' jitter and gaps (row() `jitter`).
const SALT_ROW := 7121
const SALT_JITTER_X := 7331
const SALT_JITTER_Y := 7457
const SALT_SKIP := 7583
## With a jitter, the share of plots (times the jitter) left empty, so the rows open up here and there.
const SKIP_SHARE := 0.25


## The structure for set `set_name` standing over water from the bank line `bank_y` (BuildingTypes.OVER_WATER: its
## water strip on the water, from the bank to its front edge), its back corner's x at `x`.
static func on_bank(set_name: StringName, x: float, bank_y: float) -> Dictionary:
	var s: Array = SETS[set_name]
	return plot(set_name, Vector2(x, bank_y + float(BuildingTypes.OVER_WATER[set_name]) - (s[0] as Vector2).y))


## The structure for set `set_name` with its footprint's back corner at `at`: {rect, height, kind, role, tag}.
static func plot(set_name: StringName, at: Vector2) -> Dictionary:
	var s: Array = SETS[set_name]
	var type := BuildingTypes.info(set_name)
	return {"rect": Rect2(at, s[0]), "height": type.height, "kind": type.kind, "role": ROLE, "tag": set_name}


## The sets a city plots: every set but the props and the unused.
static func plotted_sets() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in SETS:
		if not k in PROPS and not k in UNUSED:
			out.append(k)
	return out


## Fills `block` with plots of size `plot` in rows, `gap` apart both ways: as many columns and rows as fit, the rows
## centred down the block, each row slid along x within the block's spare width by its own hash of `seed_value` (so
## the rows of a block do not line up like a chessboard). With a `jitter` (0..1), each plot also moves up to
## jitter * gap / 2 either way on both axes (so neighbours keep at least (1 - jitter) * gap apart) and about
## jitter * SKIP_SHARE of them are left out: a loose, uneven quarter rather than a lattice. Deterministic; every plot
## lies inside the block.
static func row(block: Rect2, plot: Vector2, gap: float, seed_value: int, jitter := 0.0) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var cols := floori((block.size.x + gap) / (plot.x + gap) + 0.0001)
	var rows := floori((block.size.y + gap) / (plot.y + gap) + 0.0001)
	if cols < 1 or rows < 1:
		return out
	var spare := block.size - Vector2(cols * plot.x + (cols - 1) * gap, rows * plot.y + (rows - 1) * gap)
	var y := block.position.y + spare.y * 0.5
	for j in rows:
		var x := block.position.x + spare.x * ArtKit.hash01(seed_value, SALT_ROW + j)
		for i in cols:
			var r := Rect2(x + i * (plot.x + gap), y, plot.x, plot.y)
			if jitter > 0.0:
				var k := j * 1000 + i
				if ArtKit.hash01(seed_value, SALT_SKIP + k) < jitter * SKIP_SHARE:
					continue
				var off := Vector2(ArtKit.hash01(seed_value, SALT_JITTER_X + k) - 0.5,
					ArtKit.hash01(seed_value, SALT_JITTER_Y + k) - 0.5) * gap * jitter
				r.position = (r.position + off).clamp(block.position, block.end - plot)
			out.append(r)
		y += plot.y + gap
	return out
