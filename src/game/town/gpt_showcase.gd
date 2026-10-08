class_name GptShowcase
extends Node
## Dev only: the GPT showcase district (feat/gpt-buildings-proof). Every converted ChatGPT building (the gpt_* sets,
## tools/dev/ref_convert/gpt_convert.py) stands on open meadow outside the walls, in clean rows by category, each on a
## plot of its own footprint (the one its blockout used, the painting centred on it), and one of the game's own
## buildings of a similar kind in each row's first slot to compare against. A temporary look at the art, not a layout.
##
## Only the town debug scene builds it (town_debug.gd: on by default, `-- --no-showcase` leaves it out): the game, the
## mission, the tests' towns and the dev checks (state_digest, crowd_check, behaviour_check) never do. It is built after
## the town, so no town building's seed moves; Town.keep_clear keeps decor, trees, fields, pastures, trails and rocky
## outcrops off its ground (clear_rects()).
##
## Layout (plots()): nothing on screen overlaps anything else. Each row of plots is a screen-level lane (constant
## x + y: the plots' front corners on one screen line), its plots left to right with their sprites' boxes (the union of
## their three stills' drawn pixels) BOX_GAP px apart and the plots at least GAP apart in plan. The next lane goes as far
## down the screen as the lowest sprite foot of this one plus the tallest sprite of the next ones, so no sprite box
## overlaps another (tests/test_sprite_art.gd checks every pair). The rows run tallest category first (at the back) in
## the regions REGIONS lists, east meadow first; a row that does not fit its lane carries on in the next one.
##
## Each plot is a real Structure, kind HOUSE and role "showcase" (no rules, homes, smoke or chores count it), carrying
## the set it draws as GptProof.SHOWCASE_META (SpriteArt.name_for asks GptProof.set_for first). The sets that repeat
## along x (REPEATS: the aqueduct, the tilt barrier) stand as REPEAT_COPIES copies end to end, to show their seam;
## the wagon (MIRRORS) stands a second time on its plot turned, so it draws mirrored: both facings.
## `--showcase-state=damaged` cracks every showcase building, `ruins` brings them down (their fall plays once at the
## start). F9 shows or hides the name under each plot (town_debug.gd).
##
## Drop this file, its lines in town_debug.gd and Town.keep_clear to remove it.

const ROLE := &"showcase"
## The open meadow it fills, in this order (plan units; plan north = -y):
## - east of the east wall, from the trail beside the forest ring to the map's edge, the whole height of the map down
##   to the river: in front of the walls on screen, so nothing of the town stands before it;
## - north of the north wall, beyond the forest ring: far enough out (y <= -22) that the wall's towers, in front of it
##   on screen, stay clear of the plots' sprites.
const REGIONS := [Rect2(18.7, -29.4, 10.7, 48.9), Rect2(-29.4, -29.4, 48.1, 7.4)]
## What a plot keeps OBSTACLE_GAP clear of: the walls (with their towers), the rivers, the roads, the bridge and the
## dock, the farmhouses and the mills. Fields, pastures, trees and decor on the regions go instead (clear_rects()).
const OBSTACLE_GAP := 0.6
## The farmhouses and the windmill near the regions, with their sets: no showcase sprite overlaps theirs on screen.
const DRAWN_OBSTACLES := [
	[Rect2(-12.5, -28.4, 1.3, 1.5), "barn"], [Rect2(18.0, -26.5, 1.3, 1.5), "barn"],
	[Rect2(19.5, 17.2, 1.3, 1.5), "barn"], [Rect2(-11.9, -24.9, 0.9, 0.9), "windmill"],
]
## Open ground between two plots (plan units) and between two sprites' boxes (screen px).
const GAP := 1.2
const BOX_GAP := 8.0
## How far round the regions the ground is cleared, and in front of the north region up to this y (short of the north
## wall's towers), so no tree stands in front of a plot.
const CLEAR_MARGIN := 1.2
const FRONT_OF_NORTH := -17.2
## A lane's search step along it (plan units) and an empty lane's step down the screen (x + y units).
const STEP := 0.05
const LANE_STEP := 0.5
## [category, the game's own building in its first slot, its sets]. Each row after its first slot runs largest plot
## first. The rows themselves run tallest first (row_order()).
const ROWS := [
	["faith", "townhouse_a",
		["gpt_chapel", "gpt_monastery", "gpt_graveyard", "gpt_hospital", "gpt_leperhouse", "gpt_bathhouse"]],
	["trade", "townhouse_b",
		["gpt_inn", "gpt_shophouse", "gpt_guildhall", "gpt_markethall", "gpt_weighhouse", "gpt_fishmarket"]],
	["defence", "tavern",
		["gpt_townhall", "gpt_armoury", "gpt_jail", "gpt_courthouse", "gpt_watchtower", "gpt_treasury"]],
	["crafts", "smithy",
		["gpt_bakery", "gpt_butcher", "gpt_brewery", "gpt_tannery", "gpt_dyers", "gpt_weavers",
		"gpt_potter", "gpt_cooper", "gpt_masonyard", "gpt_lumberyard", "gpt_charcoal", "gpt_glassworks"]],
	["food", "cottage_red",
		["gpt_granary", "gpt_warehouse", "gpt_orchard", "gpt_vineyard", "gpt_beehives", "gpt_dovecote"]],
	["water", "well",
		["gpt_cistern", "gpt_aqueduct", "gpt_washhouse", "gpt_latrine", "gpt_sluice", "gpt_footbridge"]],
	["housing", "cottage_blue",
		["gpt_manor", "gpt_patrician", "gpt_rowhouses", "gpt_tenement", "gpt_shacks", "gpt_hut"]],
	["public", "fountain",
		["gpt_monument", "gpt_noticeboard", "gpt_crierstage", "gpt_grandstand", "gpt_tiltbarrier", "gpt_playstage"]],
	["civic_b", "workshop",
		["gpt_school", "gpt_library", "gpt_pavilion", "gpt_farmhouse", "gpt_fishpond", "gpt_icehouse"]],
	["transport", "barn",
		["gpt_stables", "gpt_wagon", "gpt_handcart", "gpt_crane", "gpt_ferry", "gpt_pens"]],
	["defence_b", "town_gate",
		["gpt_barbican", "gpt_drawbridge", "gpt_gallows", "gpt_districtgate"]],
	["small", "lamp_post",
		["gpt_milestone", "gpt_waysidecross", "gpt_alleysteps"]],
]
## The sets that tile along x, and how many copies of each stand end to end.
const REPEATS := ["gpt_aqueduct", "gpt_tiltbarrier"]
const REPEAT_COPIES := 3
## The props that also stand a second time on their plot turned (W and D swapped), so the engine draws them mirrored
## (SpriteArt.set_for): both facings. The wagon (gpt_convert.MIRRORS).
const MIRRORS := ["gpt_wagon"]
const STATES := ["intact", "damaged", "ruins"]
const LABEL_SIZE := 9

var structures: Array[Structure] = []
var smoke: ChimneySmoke
var labels: Node2D
var _plots: Array[Dictionary] = []

static var _cache: Array[Dictionary] = []


## Whether the town debug scene's user args want the showcase (on unless `--no-showcase`).
static func wanted(args: PackedStringArray) -> bool:
	return not "--no-showcase" in args


## The ground Town.keep_clear keeps bare for it: each region and its margin, and in front of the north region the
## forest ring up to the wall's towers, so no tree stands in front of a plot.
static func clear_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for a: Rect2 in REGIONS:
		out.append(a.grow(CLEAR_MARGIN).intersection(TownLayout.MAP))
	out[1] = out[1].expand(Vector2(out[1].position.x, FRONT_OF_NORTH))
	return out


## The ground no plot may touch (grown OBSTACLE_GAP).
static func obstacles() -> Array[Rect2]:
	var out: Array[Rect2] = [TownLayout.TOWN.grow(1.2)]
	for r: Rect2 in TownLayout.RIVERS + TownLayout.ROADS + TownLayout.BARNS + [TownLayout.WINDMILL,
			TownLayout.WATERMILL, TownLayout.DOCK, TownLayout.BRIDGE]:
		out.append(r)
	for i in out.size():
		out[i] = out[i].grow(OBSTACLE_GAP)
	return out


## The screen box (px, relative to the plot's front corner on screen) of set `n`'s drawn pixels, all three stills;
## `mirror`: drawn mirrored (scale.x = -1 about its anchor).
static func sprite_box(n: String, mirror := false) -> Rect2:
	var sp := SpriteArt.sprite(n)
	var box := Rect2()
	var first := true
	for st in SpriteArt.STILLS:
		var tex: Texture2D = sp.stills[st]
		var used := Rect2(tex.get_image().get_used_rect())
		box = used if first else box.merge(used)
		first = false
	var rel := Rect2(box.position - (sp.anchor as Vector2), box.size)
	if mirror:
		rel.position.x = -rel.end.x
	return rel


## Whether set `n` stands mirrored on `rect` (SpriteArt.set_for's rule: a wide sprite on a deep plot, or the reverse).
static func mirrored(rect: Rect2, n: String) -> bool:
	var f: Array = SpriteArt.manifest()[n].footprint
	var fp := Vector2(float(f[0]), float(f[1]))
	return not is_equal_approx(fp.x, fp.y) and (fp.x >= fp.y) != (rect.size.x >= rect.size.y)


## A plot's screen box (world px): its set's box at its front corner (mirrored as it draws there).
static func screen_box(rect: Rect2, n: String) -> Rect2:
	var b := sprite_box(n, mirrored(rect, n))
	return Rect2(Iso.ground_to_screen(rect.end) + b.position, b.size)


## The rows in the order they are laid: tallest sprite first (stable for a tie).
static func row_order() -> Array:
	var tall := {}
	for row: Array in ROWS:
		var t := 0.0
		for n: String in [row[1]] + row[2]:
			t = maxf(t, -sprite_box(n).position.y)
		tall[row[0]] = t
	var out: Array = ROWS.duplicate()
	var idx := {}
	for i in ROWS.size():
		idx[ROWS[i][0]] = i
	out.sort_custom(func(a: Array, b: Array) -> bool:
		if not is_equal_approx(tall[a[0]], tall[b[0]]):
			return tall[a[0]] > tall[b[0]]
		return idx[a[0]] < idx[b[0]])
	return out


## The layout items: per row, its game building then its sets largest plot first; a repeating set is one item of
## REPEAT_COPIES copies end to end along x, and a MIRRORS prop is followed by itself turned (mirrored). {row, sets (one
## per copy, back to front), fp (the whole), box (screen px from the front corner, all copies), mirror}.
static func _items() -> Array[Dictionary]:
	var man := SpriteArt.manifest()
	var out: Array[Dictionary] = []
	for row: Array in row_order():
		var sets: Array = row[2].duplicate()
		sets.sort_custom(func(p: String, q: String) -> bool:
			var fp: Array = man[p].footprint
			var fq: Array = man[q].footprint
			var ap := float(fp[0]) * float(fp[1]) * (REPEAT_COPIES if p in REPEATS else 1)
			var aq := float(fq[0]) * float(fq[1]) * (REPEAT_COPIES if q in REPEATS else 1)
			if not is_equal_approx(ap, aq):
				return ap > aq
			return p < q)
		sets.push_front(row[1])
		for n: String in sets:
			var f: Array = man[n].footprint
			var fp := Vector2(float(f[0]), float(f[1]))
			var k := REPEAT_COPIES if n in REPEATS else 1
			var box := sprite_box(n)
			for j in range(1, k):
				box = box.merge(Rect2(box.position - Vector2(32.0, 16.0) * fp.x * j, box.size))
			var copies: Array = []
			copies.resize(k)
			copies.fill(n)
			out.append({"row": row[0], "sets": copies, "fp": Vector2(fp.x * k, fp.y), "box": box, "mirror": false})
			if n in MIRRORS:
				out.append({"row": row[0], "sets": [n], "fp": Vector2(fp.y, fp.x), "box": sprite_box(n, true),
					"mirror": true})
	return out


## Every plot, back to front: {rect, set, row, height, group, page, mirror}. A plot is its set's own footprint, wide
## (W along x, D along y) as the set is drawn, so nothing is mirrored but a MIRRORS prop's second plot (D x W); the
## copies of a repeating set share a group and touch.
## The meadow holds about thirty buildings laid out this way, so the rows fill pages: a row that does not fit what is
## left of a page starts the next one (pages() counts them; the town debug scene shows one at a time). Computed once
## (the sprites' boxes read their stills).
static func plots() -> Array[Dictionary]:
	if not _cache.is_empty():
		return _cache
	var man := SpriteArt.manifest()
	var items := _items()
	var obs := obstacles()
	var drawn: Array[Rect2] = []
	for o: Array in DRAWN_OBSTACLES:
		drawn.append(screen_box(o[0], o[1]))
	var out: Array[Dictionary] = []
	var page := 1
	var st := _fresh()
	var group := 0
	var start := 0
	while start < items.size():
		var end := start
		while end < items.size() and items[end].row == items[start].row:
			end += 1
		var was_empty: bool = (st.rects as Array).is_empty()
		var placed := _pack_row(st, items, start, end, obs, drawn)
		if placed.is_empty():
			if was_empty:
				push_error("GptShowcase: the %s row does not fit an empty page" % items[start].row)
				break
			page += 1
			st = _fresh()
			continue
		for k in placed.size():
			var it: Dictionary = items[start + k]
			var whole: Rect2 = placed[k]
			var w: float = whole.size.x / it.sets.size()
			for j in it.sets.size():
				var r := Rect2(whole.position.x + w * j, whole.position.y, w, whole.size.y)
				out.append({"rect": r, "set": it.sets[j], "row": it.row, "group": group, "page": page,
					"height": float(man[it.sets[j]].get("height", 20)), "mirror": it.mirror})
			group += 1
		start = end
	_cache = out
	return out


## How many pages the rows fill.
static func pages() -> int:
	var n := 1
	for p: Dictionary in plots():
		n = maxi(n, p.page)
	return n


## The page a row stands on.
static func page_of(row: String) -> int:
	for p: Dictionary in plots():
		if p.row == row:
			return p.page
	return 1


## An empty page's packing state: the region, the lane (x + y of its front corners), this lane's boxes, and every
## placed plot's rect and box.
static func _fresh() -> Dictionary:
	var lane: Array[Dictionary] = []
	var rects: Array[Rect2] = []
	var boxes: Array[Rect2] = []
	return {"region": 0, "c": _region_start(REGIONS[0]), "lane": lane, "rects": rects, "boxes": boxes}


## Lays items [start, end) (one row) from where state `st` left off, starting a new lane, all in one region: their
## plots (whole groups), or [] when the page runs out first (`st` is then spent: the caller starts a new page).
static func _pack_row(st: Dictionary, items: Array[Dictionary], start: int, end: int, obs: Array[Rect2],
		drawn: Array[Rect2]) -> Array[Rect2]:
	var placed: Array[Rect2] = []
	var none: Array[Rect2] = []
	var lane: Array[Dictionary] = st.lane
	var rects: Array[Rect2] = st.rects
	var boxes: Array[Rect2] = st.boxes
	if not lane.is_empty():
		st.c = _next_lane(st.c, lane, items, start)
		lane.clear()
	var i := start
	while i < end:
		var it: Dictionary = items[i]
		var at := _fit(it, st.c, REGIONS[st.region], lane, obs, drawn, rects, boxes)
		if at.is_empty():
			if lane.is_empty():
				st.c += LANE_STEP
			else:
				st.c = _next_lane(st.c, lane, items, i)
				lane.clear()
			var r: Rect2 = REGIONS[st.region]
			if st.c > r.end.x + r.end.y:
				st.region += 1
				if st.region >= REGIONS.size():
					return none
				st.c = _region_start(REGIONS[st.region])
				lane.clear()
				# a row stands in one region: what it had laid in the last one starts again here
				rects.resize(rects.size() - placed.size())
				boxes.resize(boxes.size() - placed.size())
				placed.clear()
				i = start
			continue
		rects.append(at.rect)
		boxes.append(at.box)
		lane.append({"box": at.box})
		placed.append(at.rect)
		i += 1
	return placed


static func _region_start(r: Rect2) -> float:
	return r.position.x + r.position.y + 1.0


## The next lane's line: below this lane's lowest sprite foot by the tallest sprite still to come in this row and the
## next (each lane's front corners sit on screen y = 16 c).
static func _next_lane(c: float, lane: Array[Dictionary], items: Array[Dictionary], from: int) -> float:
	var foot := -INF
	for l: Dictionary in lane:
		foot = maxf(foot, (l.box as Rect2).end.y)
	var above := 0.0
	var rows_seen := 0
	for k in range(from, items.size()):
		if k > from and items[k].row != items[k - 1].row:
			rows_seen += 1
			if rows_seen > 1:
				break
		above = maxf(above, -(items[k].box as Rect2).position.y)
	return maxf(c + LANE_STEP, (foot + above + BOX_GAP) / 16.0)


## Where item `it` first fits along lane `c` in region `r`, right of the lane's last item: {rect, box}, or {} if it
## does not fit before the region's end.
static func _fit(it: Dictionary, c: float, r: Rect2, lane: Array[Dictionary], obs: Array[Rect2],
		drawn: Array[Rect2], rects: Array[Rect2], boxes: Array[Rect2]) -> Dictionary:
	var fp: Vector2 = it.fp
	var b: Rect2 = it.box
	# front corner (fx, c - fx): the plot inside r
	var lo := maxf(r.position.x + fp.x, c - r.end.y)
	var hi := minf(r.end.x, c - r.position.y - fp.y)
	if not lane.is_empty():
		# its box right of the lane's last box: screen x of the front corner = 32 (2 fx - c)
		var last: Rect2 = lane[-1].box
		lo = maxf(lo, ((last.end.x + BOX_GAP - b.position.x) / 32.0 + c) / 2.0)
	var fx := lo
	while fx <= hi + 0.0001:
		var rect := Rect2(fx - fp.x, c - fx - fp.y, fp.x, fp.y)
		var box := Rect2(Iso.ground_to_screen(rect.end) + b.position, b.size)
		if _clear(rect, box, obs, drawn, rects, boxes):
			return {"rect": rect, "box": box}
		fx += STEP
	return {}


static func _clear(rect: Rect2, box: Rect2, obs: Array[Rect2], drawn: Array[Rect2], rects: Array[Rect2],
		boxes: Array[Rect2]) -> bool:
	for o in obs:
		if o.intersects(rect):
			return false
	var g := box.grow(BOX_GAP * 0.5 - 0.01)
	for d in drawn:
		if d.intersects(g):
			return false
	for q in rects:
		if q.grow(GAP * 0.5 - 0.001).intersects(rect.grow(GAP * 0.5 - 0.001)):
			return false
	for q in boxes:
		if q.grow(BOX_GAP * 0.5 - 0.01).intersects(g):
			return false
	return true


## The middle of a row's plots ("overview": of page 1's), for the dev shots.
static func shot_point(row: String) -> Vector2:
	var box := Rect2()
	var first := true
	for p: Dictionary in plots():
		if not _in_shot(p, row):
			continue
		box = p.rect if first else box.merge(p.rect)
		first = false
	return box.get_center()


## Whether plot `p` is in the shot of `row`: a row, or "overview" / "overview_<n>" (every row of page 1 / page n).
static func _in_shot(p: Dictionary, row: String) -> bool:
	if row.begins_with("overview"):
		return p.page == shot_page(row)
	return p.row == row


## The page a shot shows (see _in_shot).
static func shot_page(row: String) -> int:
	if row.begins_with("overview"):
		return int(row.get_slice("_", 1)) if row.contains("_") else 1
	return page_of(row)


## The screen rect (world px) round a row's sprites ("overview": every row's on page 1), for the dev shots.
static func shot_frame(row: String) -> Rect2:
	var box := Rect2()
	var first := true
	for p: Dictionary in plots():
		if not _in_shot(p, row):
			continue
		var b := screen_box(p.rect, p.set)
		box = b if first else box.merge(b)
		first = false
	return box


## Builds the district into `env` (after the town): a structure per plot, the smoke from their chimneys, and their
## labels as a child of `parent` (a node in world screen space; null: none). `state`: "intact", "damaged" (cracked)
## or "ruins" (brought down). `page`: which page of rows (plots()).
func build(env: EnvironmentField, parent: Node2D = null, state := "intact", page := 1) -> GptShowcase:
	_plots = []
	for p: Dictionary in plots():
		if p.page == page:
			_plots.append(p)
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


## The page asked for with `--showcase-page=` (1 when absent or out of range).
static func page_arg(args: PackedStringArray) -> int:
	var v := int(Battlefield.arg_value(args, "--showcase-page"))
	return v if v >= 1 and v <= pages() else 1


## The state asked for with `--showcase-state=` ("intact" when absent or unknown).
static func state_arg(args: PackedStringArray) -> String:
	var v := Battlefield.arg_value(args, "--showcase-state")
	return v if v in STATES else "intact"


func toggle_labels() -> void:
	if is_instance_valid(labels):
		labels.visible = not labels.visible


## Frees what it put outside the field (the field's own clear() takes the structures; with `env`, they are taken out
## of it now, to show another page).
func teardown(env: EnvironmentField = null) -> void:
	if env != null:
		for s in structures:
			if is_instance_valid(s):
				env.remove(s, false)
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
	var seen := {}
	for p: Dictionary in _plots:
		if seen.has(p.group):    # one label for a repeating set's copies
			continue
		seen[p.group] = true
		var r: Rect2 = p.rect
		# on the plot's middle, a little below it
		var at := Iso.ground_to_screen(r.get_center()) + Vector2(0, 14)
		var text: String = p.set + (" (mirrored)" if p.mirror else "")
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		labels.draw_rect(Rect2(at + Vector2(-w * 0.5 - 2, -LABEL_SIZE), Vector2(w + 4, LABEL_SIZE + 3)),
			Color(0, 0, 0, 0.55))
		labels.draw_string(font, at + Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE,
			Color(1, 0.96, 0.85))
