class_name GptShowcase
extends Node
## Dev only: the GPT showcase district (feat/gpt-buildings-proof). Every converted ChatGPT building (the gpt_* sets,
## tools/dev/ref_convert/gpt_convert.py) stands on open meadow outside the walls, in clean rows by category, each on a
## plot of its own footprint (the one its blockout used) with nothing in front of it, and one of the game's own
## buildings of a similar size in each row's first slot to compare against. A temporary look at the art, not a layout.
##
## Only the town debug scene builds it (town_debug.gd: on by default, `-- --no-showcase` leaves it out): the game, the
## mission, the tests' towns and the dev checks (state_digest, crowd_check, behaviour_check) never do. It is built after
## the town, so no town building's seed moves; Town.keep_clear keeps decor off its two areas and takes out the trees
## standing on them.
##
## Each plot is a real Structure, kind HOUSE and role "showcase" (no rules, homes, smoke or chores count it), carrying
## the set it draws as GptProof.SHOWCASE_META (SpriteArt.name_for asks GptProof.set_for first). `--showcase-state=
## damaged` cracks every showcase building, `ruins` brings them down (their fall plays once at the start). F9 shows or
## hides the name under each plot (town_debug.gd).
##
## Batch 1 (this file's ROWS): the defence and faith proof buildings, and the trade, crafts and food sheets. Batches 2
## and 3 add their rows to ROWS (and their shots to town_debug's TOWN_SHOTS). Drop this file, its lines in
## town_debug.gd and Town.keep_clear to remove it.

const ROLE := &"showcase"
## The two open areas, plan units (each clear of the fields, the barns, the pastures, the roads and the meadow's dirt
## trails, and far enough from the walls that no wall or tower stands in front of a plot):
## - north of the north wall, between the north fields and the trail along the forest ring: one band of plots along x;
## - east of the east wall, from the trail beside the forest ring to the map's edge, between the north-east fields'
##   barn and the east pasture: three bands along y, stacked back to front in x.
const NORTH := Rect2(-2.6, -23.0, 18.6, 2.05)
const EAST := Rect2(20.9, -29.4, 8.9, 29.8)
const AREAS := [NORTH, EAST]
## Open ground between two plots in a row and between two bands; between two rows sharing a band, twice that.
const GAP := 0.6
const ROW_GAP := 0.6
## Decor and trees are kept this far off the areas (Town.keep_clear); in front of the north area, up to this y (just
## short of the north wall's towers).
const CLEAR_MARGIN := 0.4
const FRONT_OF_NORTH := -17.2
## [category, area (AREAS index), band (back to front), the game's own building in its first slot, its sets]. A band
## is a strip of plots along the area (along x in the north, along y in the east), as deep as its deepest plot; its
## rows follow one another along it. The tallest buildings stand in the back bands; each row after its first slot
## runs largest plot first (in plan, toward the viewer), so no building stands in front of a bigger one.
const ROWS := [
	["faith", 0, 0, "townhouse_a",
		["gpt_chapel", "gpt_monastery", "gpt_graveyard", "gpt_hospital", "gpt_leperhouse", "gpt_bathhouse"]],
	["trade", 1, 0, "townhouse_b",
		["gpt_inn", "gpt_shophouse", "gpt_guildhall", "gpt_markethall", "gpt_weighhouse", "gpt_fishmarket"]],
	["defence", 1, 0, "tavern",
		["gpt_townhall", "gpt_armoury", "gpt_jail", "gpt_courthouse", "gpt_watchtower", "gpt_treasury"]],
	["crafts", 1, 1, "smithy",
		["gpt_bakery", "gpt_butcher", "gpt_brewery", "gpt_tannery", "gpt_dyers", "gpt_weavers",
		"gpt_potter", "gpt_cooper", "gpt_masonyard", "gpt_lumberyard", "gpt_charcoal", "gpt_glassworks"]],
	["food", 1, 2, "cottage_red",
		["gpt_granary", "gpt_warehouse", "gpt_orchard", "gpt_vineyard", "gpt_beehives", "gpt_dovecote"]],
]
const STATES := ["intact", "damaged", "ruins"]
const LABEL_SIZE := 9

var structures: Array[Structure] = []
var smoke: ChimneySmoke
var labels: Node2D
var _plots: Array[Dictionary] = []


## Whether the town debug scene's user args want the showcase (on unless `--no-showcase`).
static func wanted(args: PackedStringArray) -> bool:
	return not "--no-showcase" in args


## The ground Town.keep_clear keeps bare for it: each area and its margin, and in the north the forest ring between
## it and the wall too, so no tree stands in front of a plot.
static func clear_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for a: Rect2 in AREAS:
		out.append(a.grow(CLEAR_MARGIN))
	out[0] = out[0].expand(Vector2(NORTH.end.x + CLEAR_MARGIN, FRONT_OF_NORTH))
	return out


## Every plot, bands back to front: {rect, set, row, height}. A plot is its set's own footprint, wide (W along x, D
## along y) as the set is drawn, so nothing is mirrored. Plots line up on their band's back edge, except in an area's
## last band of several, which lines up on its front edge: a shallow plot then leaves its spare depth between the bands,
## where a building in front would otherwise hide the foot of the one behind.
static func plots() -> Array[Dictionary]:
	var man := SpriteArt.manifest()
	var out: Array[Dictionary] = []
	for area in AREAS.size():
		var a: Rect2 = AREAS[area]
		var back: float = a.position.y if area == 0 else a.position.x
		var bands := 0
		for row: Array in ROWS:
			if row[1] == area:
				bands = maxi(bands, int(row[2]) + 1)
		var band := 0
		while true:
			var rows: Array = []
			for row: Array in ROWS:
				if row[1] == area and row[2] == band:
					rows.append(row)
			if rows.is_empty():
				break
			var depth := 0.0
			var lists: Array = []
			for row: Array in rows:
				var sets: Array = row[4].duplicate()
				sets.sort_custom(func(p: String, q: String) -> bool:
					var fp: Array = man[p].footprint
					var fq: Array = man[q].footprint
					return float(fp[0]) * float(fp[1]) > float(fq[0]) * float(fq[1]))
				sets.push_front(row[3])
				lists.append(sets)
				for n: String in sets:
					var f: Array = man[n].footprint
					depth = maxf(depth, float(f[1]) if area == 0 else float(f[0]))
			var along: float = a.position.x if area == 0 else a.position.y
			for i in rows.size():
				if i > 0:
					along += GAP
				for n: String in lists[i]:
					var f: Array = man[n].footprint
					var w := float(f[0])
					var d := float(f[1])
					var front := bands > 1 and band == bands - 1
					var r: Rect2
					if area == 0:
						r = Rect2(along, back + (depth - d if front else 0.0), w, d)
						along += w + GAP
					else:
						r = Rect2(back + (depth - w if front else 0.0), along, w, d)
						along += d + GAP
					out.append({"rect": r, "set": n, "row": rows[i][0], "height": float(man[n].get("height", 20))})
			back += depth + ROW_GAP
			band += 1
	return out


## The middle of a row's plots ("overview": of everything), for the dev shots.
static func shot_point(row: String) -> Vector2:
	var box := Rect2()
	var first := true
	for p: Dictionary in plots():
		if row != "overview" and p.row != row:
			continue
		box = p.rect if first else box.merge(p.rect)
		first = false
	return box.get_center()


## Builds the district into `env` (after the town): a structure per plot, the smoke from their chimneys, and their
## labels as a child of `parent` (a node in world screen space; null: none). `state`: "intact", "damaged" (cracked) or "ruins" (brought down).
func build(env: EnvironmentField, parent: Node2D = null, state := "intact") -> GptShowcase:
	_plots = plots()
	for p: Dictionary in _plots:
		var s := env.add_structure(p.rect, p.height, Structure.Kind.HOUSE, ROLE)
		s.set_meta(GptProof.SHOWCASE_META, p.set)
		s.refresh_sprite()
		structures.append(s)
	smoke = ChimneySmoke.new().setup(structures)
	smoke.name = "ShowcaseSmoke"
	smoke.lights = env.lights
	if env.fx_back != null:
		env.fx_back.add_child(smoke)
	if parent != null:
		labels = Node2D.new()
		labels.name = "ShowcaseLabels"
		labels.z_index = 6
		labels.z_as_relative = false  # absolute z 6: above the world (0), below the overhead layer (8).
		labels.draw.connect(_draw_labels)
		parent.add_child(labels)
	if state == "damaged":
		for s in structures:
			s.crack()
	elif state == "ruins":
		for s in structures:
			s.destroy(s.center(), &"stone")
	return self


## The state asked for with `--showcase-state=` ("intact" when absent or unknown).
static func state_arg(args: PackedStringArray) -> String:
	var v := Battlefield.arg_value(args, "--showcase-state")
	return v if v in STATES else "intact"


func toggle_labels() -> void:
	if is_instance_valid(labels):
		labels.visible = not labels.visible


## Frees what it put outside the field (the field's own clear() takes the structures).
func teardown() -> void:
	for n in [smoke, labels]:
		if is_instance_valid(n):
			if n.is_inside_tree():
				n.queue_free()
			else:
				n.free()
	smoke = null
	labels = null
	structures.clear()


func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	for p: Dictionary in _plots:
		var r: Rect2 = p.rect
		# on the plot's middle, a little below it
		var at := Iso.ground_to_screen(r.get_center()) + Vector2(0, 14)
		var text: String = p.set
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		labels.draw_rect(Rect2(at + Vector2(-w * 0.5 - 2, -LABEL_SIZE), Vector2(w + 4, LABEL_SIZE + 3)),
			Color(0, 0, 0, 0.55))
		labels.draw_string(font, at + Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE,
			Color(1, 0.96, 0.85))
