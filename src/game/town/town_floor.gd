class_name TownFloor
extends Node2D
## Aldermere's ground after concepts/TOWN REF/Town Visual Upgrade.png, at the Scale reference's size:
## - outside the walls, a warm meadow in organic patches, darker under the forest, with dirt trails winding through;
## - dirt roads out of the gates;
## - inside, packed earth, cobbled streets, flagstones in the market and the Citadel court, and the barracks' sand;
## - tilled ground round the farms, and a saturated river (the south river and its west branch) with stony banks.
##
## Everything is painted once into a texture, and the floor draws just that one texture. The painting happens in a
## SubViewport that renders once: ground-unit shapes under the iso basis, then screen-pixel tufts, flowers and
## pebbles on top. It used to be ~10k rects replayed every frame. The river's glints are a small child node that
## redraws on its own. Without a renderer (headless) nothing is baked and the floor paints itself directly.

## Drawn area: past the map so zoomed-out views rarely show the void.
const FILL := Rect2(-34, -34, 68, 68)
## Meadow greens, light to dark, and the forest floor's.
const GRASS := [Color("9aa447"), Color("8a9a3c"), Color("7c8f35"), Color("6e8230"), Color("5f742b")]
const FOREST := [Color("6a7f30"), Color("5c722b"), Color("4f6527"), Color("435823")]
## Packed earth inside the walls.
const EARTH := [Color("b09468"), Color("a4885e"), Color("987c55"), Color("8a704c")]
## Dirt trails and roads [light, mid, dark].
const DIRT := [Color("c49a62"), Color("b08a56"), Color("94744a")]
const COBBLE := [Color("d8cab0"), Color("cbbca1"), Color("bcad92"), Color("ab9d84")]
const COBBLE_MORTAR := Color("857058")
const FLAG := [Color("d6c19a"), Color("cab58f"), Color("bca884"), Color("ad9a78")]
const FLAG_MORTAR := Color("7c6446")
## The house blocks inside the walls: worn ground, from bare warm earth to patches of grass, as in the reference
## (its blocks are gardens, hedges and dirt, not lawn).
const BLOCK := [Color("b8a066"), Color("a89a58"), Color("98984a"), Color("8a9040"), Color("7c8a38")]
const SAND := [Color("cdb07e"), Color("c4a674"), Color("b89a68")]
const WATER := [Color("3a82b4"), Color("2b70a4"), Color("225f93")]
const BANK := Color("4a4a38")
const PEBBLE := [Color("a8a49c"), Color("8e8a82"), Color("76726c")]
const FLOWERS := [Color("f4f0e0"), Color("f2d24a"), Color("f09a3a"), Color("e87aa0"), Color("b0d0f0")]
## Decorative dirt trails through the meadow, forest and farms (ground units), all clear of the walls and the river.
const TRAILS := [
	[Vector2(-26, -19.5), Vector2(-18, -18.8), Vector2(-10, -20.2), Vector2(-2, -19.2), Vector2(6, -20.4),
		Vector2(14, -19.0), Vector2(26, -20.0)],
	[Vector2(-3.0, -19.4), Vector2(-3.5, -24.0), Vector2(-2.5, -29.5)],
	[Vector2(-14.0, -19.2), Vector2(-14.8, -23.5), Vector2(-15.5, -29.5)],
	[Vector2(-19.5, -26), Vector2(-20.2, -18), Vector2(-19.0, -10), Vector2(-20.5, -4), Vector2(-19.4, 4),
		Vector2(-20.2, 12), Vector2(-19.2, 17.5)],
	[Vector2(19.5, -26), Vector2(20.2, -18), Vector2(19.0, -10), Vector2(20.4, -2), Vector2(19.4, 0.6)],
	[Vector2(-26, 29.5), Vector2(-12, 29.0), Vector2(1.5, 29.4)],
	[Vector2(4.0, 29.4), Vector2(14, 29.0), Vector2(26, 29.6)],
	[Vector2(17.2, 11.4), Vector2(22, 11.8), Vector2(27, 11.2)],
]
## Roads outside the walls, as trails: the south road to the bridge and on from its far end, the east road.
const ROAD_TRAILS := [
	[Vector2(2.7, 16.2), Vector2(2.7, 18.8)],
	[Vector2(2.7, 25.8), Vector2(2.8, 27.5), Vector2(2.6, 30.0)],
	[Vector2(16.2, 9.0), Vector2(22, 9.1), Vector2(30, 8.9)],
]
## Grass painting cell (ground units) and the noise lattice spacing.
const CELL := 0.25
## Shrubs over the house blocks: the spacing of their jittered grid, and the share of its points that get one.
const SHRUB_STEP := 0.6
const SHRUB_CHANCE := 0.8
const LATTICE := 1.6


## Light glints drifting down the river, redrawn a few times a second for a stepped pixel flow.
class RiverGlints extends Node2D:
	const STEP := 0.12
	var _time := 0.0
	var _next := 0.0

	func _process(delta: float) -> void:
		_time += delta
		if _time >= _next:
			_next = _time + STEP
			queue_redraw()

	func _draw() -> void:
		var r := TownLayout.RIVER
		for i in 200:
			var h := (i * 7919 + 13) % 997
			var y := r.position.y + 0.15 + float(h % 61) / 61.0 * (r.size.y - 0.3)
			var x := r.position.x - 8.0 + fposmod(float(h) * 0.53 + _time * (0.5 + float(h % 5) * 0.1), r.size.x + 16.0)
			draw_rect(Rect2(x, y, 0.3 + float(h % 3) * 0.12, 0.04), Color(0.82, 0.94, 1.0, 0.6))
		# The west branch flows south, down to the main river.
		var w := TownLayout.RIVER_WEST
		for i in 60:
			var h := (i * 6151 + 29) % 997
			var x := w.position.x + 0.15 + float(h % 43) / 43.0 * (w.size.x - 0.3)
			var y := w.position.y + fposmod(float(h) * 0.41 + _time * (0.7 + float(h % 5) * 0.1), w.size.y)
			draw_rect(Rect2(x, y, 0.04, 0.3 + float(h % 3) * 0.12), Color(0.82, 0.94, 1.0, 0.6))


## Paints the ground-unit layer inside the bake viewport.
class GroundPaint extends Node2D:
	var floor_node: TownFloor

	func _draw() -> void:
		floor_node.paint_ground(self)


## Paints the screen-pixel detail layer inside the bake viewport.
class DetailPaint extends Node2D:
	var floor_node: TownFloor

	func _draw() -> void:
		floor_node.paint_detail(self)


## The world's light colour laid over the baked ground (Town.EVENING).
var tint := Color.WHITE
## Decor painted into the floor (TownDecor spots with `bake`), back to front.
var baked_decor: Array[Dictionary] = []
## Per meadow cell: 1 meadow, 2 forest floor, +4 on a trail. Filled while painting the ground, read by the detail.
var _zones := PackedByteArray()
var _zn := 0
var _texture: Texture2D
## House yards, worked out once per paint (the detail pass asks about them ~36k times).
var _yard_rects: Array[Rect2] = []
## Screen position of the baked texture's top-left corner.
var _origin := Vector2.ZERO


func _ready() -> void:
	var glints := RiverGlints.new()
	glints.name = "RiverGlints"
	add_child(glints)
	if DisplayServer.get_name() != "headless":
		_bake()


func _bake() -> void:
	var bounds := _iso_bounds(FILL)
	var vp := SubViewport.new()
	vp.name = "FloorBake"
	vp.size = Vector2i(ceili(bounds.size.x), ceili(bounds.size.y))
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var ground := GroundPaint.new()
	ground.floor_node = self
	ground.transform = Transform2D.IDENTITY.translated(-bounds.position) * Iso.BASIS
	vp.add_child(ground)
	var detail := DetailPaint.new()
	detail.floor_node = self
	detail.position = -bounds.position
	vp.add_child(detail)
	add_child(vp)
	_texture = vp.get_texture()
	_origin = bounds.position
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		paint_ground(self)
		return
	# The floor sits under the iso basis; undo it and lay the baked screen-space texture down pixel for pixel.
	draw_set_transform_matrix(Iso.BASIS.affine_inverse())
	draw_texture(_texture, _origin, tint)


static func _iso_bounds(r: Rect2) -> Rect2:
	var box := Rect2(Iso.ground_to_screen(r.position), Vector2.ZERO)
	for c in [Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		box = box.expand(Iso.ground_to_screen(c))
	return box


# --- Ground-unit layer ------------------------------------------------------------------

func paint_ground(ci: CanvasItem) -> void:
	_meadow(ci)
	# Inside the walls the lanes are cobbled; the house blocks are worn ground, and each house stands in its own small
	# packed-earth yard, as in the reference.
	_paving(ci, TownLayout.TOWN, COBBLE, COBBLE_MORTAR, 0.2)
	for d: Rect2 in TownLayout.DISTRICTS:
		_yard(ci, d.grow(-0.12), BLOCK)
	_yard_rects = _yards()
	for h: Rect2 in _yard_rects:
		_yard(ci, h, EARTH)
	# Tilled ground round every field and farmhouse.
	for f: Rect2 in TownLayout.FIELDS:
		_patches(ci, f.grow(0.5), DIRT, 0.3)
	for b: Rect2 in TownLayout.BARNS + [TownLayout.WINDMILL, TownLayout.WATERMILL]:
		_patches(ci, b.grow(0.6), DIRT, 0.3)
	for tr in TRAILS:
		_trail(ci, tr, 0.34)
	for tr in ROAD_TRAILS:
		_trail(ci, tr, 0.5)
	_patches(ci, TownLayout.BARRACKS_YARD, SAND, 0.3)
	_paving(ci, TownLayout.MARKET_SQUARE, FLAG, FLAG_MORTAR, 0.42)
	_paving(ci, TownLayout.CITADEL_COURT, FLAG, FLAG_MORTAR, 0.42)
	_paving(ci, TownLayout.FOUNTAIN_PLAZA, FLAG, FLAG_MORTAR, 0.42)
	# The ground inside each gate, where the crowd queues, is cobbled like the streets.
	for plaza: Rect2 in TownLayout.GATE_PLAZAS:
		_paving(ci, plaza.grow(0.3), COBBLE, COBBLE_MORTAR, 0.2)
	_river(ci)


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 997


## Smooth value noise in [0, 1): a hashed lattice, bilinearly blended, plus a finer octave.
func _noise(g: Vector2) -> float:
	return _octave(g / LATTICE, 0) * 0.7 + _octave(g / (LATTICE * 0.35), 1) * 0.3


func _octave(p: Vector2, salt: int) -> float:
	var x0 := floori(p.x)
	var y0 := floori(p.y)
	var fx := p.x - x0
	var fy := p.y - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	# Four lattice corners, hashed inline: this runs ~100k times per bake.
	var hx0 := (x0 * 7 + salt * 131) * 73856093
	var hx1 := ((x0 + 1) * 7 + salt * 131) * 73856093
	var hy0 := (y0 * 13 - salt * 71) * 19349663
	var hy1 := ((y0 + 1) * 13 - salt * 71) * 19349663
	var a := float(absi(hx0 ^ hy0) % 997)
	var b := float(absi(hx1 ^ hy0) % 997)
	var c := float(absi(hx0 ^ hy1) % 997)
	var d := float(absi(hx1 ^ hy1) % 997)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy) / 997.0


## Meadow (or forest floor) in organic patches: noise quantized into the palette, cell by cell.
func _meadow(ci: CanvasItem) -> void:
	var n := int(FILL.size.x / CELL)
	_zn = n
	_zones.resize(n * n)
	for j in n:
		for i in n:
			var g := FILL.position + Vector2(i, j) * CELL
			var c := g + Vector2(CELL, CELL) * 0.5
			var forest := _forest(c)
			_zones[j * n + i] = 2 if forest else 1
			var pal: Array = FOREST if forest else GRASS
			var v := clampf(_noise(c) * 1.25 - 0.12, 0.0, 0.999)
			ci.draw_rect(Rect2(g, Vector2(CELL, CELL)), pal[int(v * pal.size())])


## Forest floor in a ring round the walls (farmland beyond it), north of the river and off the two roads.
func _forest(g: Vector2) -> bool:
	if g.y > TownLayout.RIVER.position.y:
		return false
	var t := TownLayout.TOWN
	if (g.x > t.end.x and absf(g.y - 9.0) < 1.5) or (g.y > t.end.y and absf(g.x - 2.7) < 1.5):
		return false
	var edge := _noise(g * 1.7) * 1.4
	var out := maxf(maxf(t.position.x - g.x, g.x - t.end.x), maxf(t.position.y - g.y, g.y - t.end.y))
	return out > 1.6 + edge and out < 7.0 + edge


## Organic patches of `pal` over a rect, like the meadow but confined.
func _patches(ci: CanvasItem, r: Rect2, pal: Array, cell: float) -> void:
	var nx := int(ceilf(r.size.x / cell))
	var ny := int(ceilf(r.size.y / cell))
	for j in ny:
		for i in nx:
			var sq := Rect2(r.position + Vector2(i, j) * cell, Vector2(cell, cell)).intersection(r)
			var v := clampf(_noise(sq.get_center() * 1.3 + Vector2(40, 40)) * 1.3 - 0.15, 0.0, 0.999)
			ci.draw_rect(sq, pal[int(v * pal.size())])


## A house's yard: packed earth in organic patches, its edge ragged with a few discs so it does not read as a box.
## Every house's yard: its footprint grown a little (the Temple, the tavern and the blacksmith too).
static func _yards() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for h: Rect2 in TownLayout.houses():
		out.append(h.grow(0.22))
	out.append_array([TownLayout.TEMPLE.grow(0.35), TownLayout.SMITHY.grow(0.3), TownLayout.WORKSHOP.grow(0.3)])
	for t: Rect2 in TownLayout.TAVERNS:
		out.append(t.grow(0.3))
	return out


func _yard(ci: CanvasItem, r: Rect2, pal: Array) -> void:
	_patches(ci, r, pal, 0.25)
	var n := int((r.size.x + r.size.y) * 2.0 / 0.35)
	for i in n:
		var h := _hash(roundi(r.position.x * 13.0) + i * 7, roundi(r.position.y * 17.0) - i * 3)
		var t := float(i) / n
		var p: Vector2
		var per := (r.size.x + r.size.y) * 2.0 * t
		if per < r.size.x:
			p = r.position + Vector2(per, 0)
		elif per < r.size.x + r.size.y:
			p = Vector2(r.end.x, r.position.y + per - r.size.x)
		elif per < r.size.x * 2.0 + r.size.y:
			p = Vector2(r.end.x - (per - r.size.x - r.size.y), r.end.y)
		else:
			p = Vector2(r.position.x, r.end.y - (per - r.size.x * 2.0 - r.size.y))
		ci.draw_circle(p, 0.1 + float(h % 5) * 0.03, pal[h % pal.size()])


## A dirt trail: overlapping discs of ragged size along a polyline, dark rim first, then the lighter tread.
func _trail(ci: CanvasItem, pts: Array, width: float) -> void:
	for pass_i in 2:
		for k in pts.size() - 1:
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[k + 1]
			var steps := maxi(int(a.distance_to(b) / 0.14), 1)
			for i in steps + 1:
				var p := a.lerp(b, float(i) / steps)
				var h := _hash(roundi(p.x * 37.0), roundi(p.y * 41.0))
				var r := width * (0.85 + float(h % 23) / 23.0 * 0.35)
				if pass_i == 0:
					ci.draw_circle(p, r + 0.06, DIRT[2])
					_mark_trail(p, r + 0.15)
				else:
					ci.draw_circle(p + Vector2(0.02, -0.02), r * 0.8, DIRT[h % 2])


## Flag the meadow cells within `r` of `p` as trail, so no tuft or flower grows on it.
func _mark_trail(p: Vector2, r: float) -> void:
	if _zn == 0:
		return
	var i0 := maxi(floori((p.x - r - FILL.position.x) / CELL), 0)
	var i1 := mini(floori((p.x + r - FILL.position.x) / CELL), _zn - 1)
	var j0 := maxi(floori((p.y - r - FILL.position.y) / CELL), 0)
	var j1 := mini(floori((p.y + r - FILL.position.y) / CELL), _zn - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			_zones[j * _zn + i] |= 4


## Stones in staggered rows with mortar gaps, each a little jittered in size; some catch the light on top.
func _paving(ci: CanvasItem, r: Rect2, pal: Array, mortar: Color, stone: float) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	ci.draw_rect(r, mortar)
	var nx := int(ceilf(r.size.x / stone)) + 1
	var ny := int(ceilf(r.size.y / stone))
	var ox := int(r.position.x * 8.0)
	var oy := int(r.position.y * 8.0)
	for j in ny:
		var shift := stone * 0.5 if j % 2 == 1 else 0.0
		for i in nx:
			var h := _hash(i * 3 + ox, j * 5 + oy)
			var shrink := 0.02 + float(h % 5) * 0.008
			var sq := Rect2(r.position + Vector2(i * stone - shift, j * stone), Vector2(stone, stone)).intersection(r) \
				.grow(-shrink)
			if sq.size.x <= 0.0 or sq.size.y <= 0.0:
				continue
			var c: Color = pal[h % pal.size()]
			ci.draw_rect(sq, c)
			if h % 3 == 0:
				ci.draw_rect(Rect2(sq.position, Vector2(sq.size.x, 0.04)), c.lightened(0.14))
			elif h % 3 == 1:
				ci.draw_rect(Rect2(sq.position + Vector2(0, sq.size.y - 0.04), Vector2(sq.size.x, 0.04)), c.darkened(0.12))


## Water in bands, lighter at the edges and deep in the middle, with dark wet banks and pebbles along them: the
## south river across the whole drawn width, and the west branch from its source down to it.
func _river(ci: CanvasItem) -> void:
	var r := TownLayout.RIVER
	var x0 := FILL.position.x
	var w := FILL.size.x
	ci.draw_rect(Rect2(x0, r.position.y, w, r.size.y), WATER[0])
	ci.draw_rect(Rect2(x0, r.position.y + r.size.y * 0.15, w, r.size.y * 0.7), WATER[1])
	ci.draw_rect(Rect2(x0, r.position.y + r.size.y * 0.35, w, r.size.y * 0.3), WATER[2])
	ci.draw_rect(Rect2(x0, r.position.y - 0.1, w, 0.1), BANK)
	ci.draw_rect(Rect2(x0, r.end.y, w, 0.1), BANK)
	var b := TownLayout.RIVER_WEST
	var bx0 := FILL.position.x
	var bw := b.end.x - bx0
	ci.draw_rect(Rect2(bx0, b.position.y, bw, b.size.y), WATER[0])
	ci.draw_rect(Rect2(b.position.x + b.size.x * 0.15, b.position.y, b.size.x * 0.7, b.size.y), WATER[1])
	ci.draw_rect(Rect2(b.position.x + b.size.x * 0.35, b.position.y, b.size.x * 0.3, b.size.y), WATER[2])
	ci.draw_rect(Rect2(b.end.x, b.position.y, 0.1, b.size.y), BANK)
	for bank_y: float in [r.position.y - 0.12, r.end.y + 0.12]:
		_pebbles(ci, Vector2(x0, bank_y), Vector2(FILL.end.x, bank_y), 2.7)
	_pebbles(ci, Vector2(b.end.x + 0.12, b.position.y), Vector2(b.end.x + 0.12, r.position.y), -100.0)
	_waterfall(ci, b)


## The west branch's source: a band of grey cliff across its head, and white water falling from it into a pool.
func _waterfall(ci: CanvasItem, b: Rect2) -> void:
	var y := b.position.y
	for i in 26:
		var h := _hash(i * 13 + 5, 77)
		var p := Vector2(FILL.position.x + float(i) / 26.0 * (b.end.x + 1.2 - FILL.position.x), y - 0.35 - float(h % 5) * 0.12)
		var rad := 0.35 + float(h % 4) * 0.12
		ci.draw_circle(p, rad, PEBBLE[2].darkened(0.1))
		ci.draw_circle(p + Vector2(-0.08, -0.08), rad * 0.7, PEBBLE[1])
		ci.draw_circle(p + Vector2(-0.14, -0.14), rad * 0.35, PEBBLE[0])
	# Falling water: pale streaks from the cliff's lip down into foam.
	var x0 := b.position.x + b.size.x * 0.25
	var x1 := b.end.x - b.size.x * 0.25
	ci.draw_rect(Rect2(x0, y - 0.7, x1 - x0, 1.6), Color("7cc0e8"))
	for i in 9:
		var x := lerpf(x0, x1, (float(i) + 0.5) / 9.0)
		ci.draw_rect(Rect2(x, y - 0.7, 0.06, 1.4), Color(0.95, 0.98, 1.0, 0.8))
	for i in 14:
		var h := _hash(i * 7, 91)
		ci.draw_circle(Vector2(lerpf(x0 - 0.3, x1 + 0.3, float(h % 97) / 97.0), y + 0.9 + float(h % 5) * 0.1), 0.12,
			Color(0.95, 0.98, 1.0, 0.85))


## Pebbles along a bank from a to b, leaving a gap round the bridge at x = `gap_x`.
func _pebbles(ci: CanvasItem, a: Vector2, b: Vector2, gap_x: float) -> void:
	var length := a.distance_to(b)
	var d := 0.0
	var i := 0
	while d < length:
		var h := _hash(i * 17, roundi((a.x + a.y) * 10.0))
		d += 0.18 + float(h % 7) * 0.05
		i += 1
		var p := a.lerp(b, minf(d / length, 1.0))
		if absf(p.x - gap_x) < 1.3:
			continue
		var rad := 0.07 + float(h % 5) * 0.025
		p += (Vector2(0, 1) if absf(b.x - a.x) > absf(b.y - a.y) else Vector2(1, 0)) * (float(h % 3) - 1.0) * 0.05
		ci.draw_circle(p, rad, PEBBLE[h % 3])
		ci.draw_circle(p + Vector2(-0.02, -0.02), rad * 0.5, (PEBBLE[h % 3] as Color).lightened(0.12))


# --- Screen-pixel layer ------------------------------------------------------------------

## Tufts, flowers and pebbles in screen pixels over the meadow and the town's earth; none on water, roads or paving.
func paint_detail(ci: CanvasItem) -> void:
	var count := 62000
	for i in count:
		var hx := _hash(i * 3 + 1, i * 7 + 5)
		var hy := _hash(i * 11 + 3, i * 5 + 9)
		var hz := _hash(i * 13 + 7, i * 17 + 1)
		var g := FILL.position + Vector2((float(hx) + float(hz % 10) / 10.0) / 997.0 * FILL.size.x,
			(float(hy) + float(hz % 7) / 7.0) / 997.0 * FILL.size.y)
		var zone := _zone(g)
		if zone == 0:
			continue
		var p := Iso.ground_to_screen(g).round()
		if zone == 1 or zone == 2:
			var pal: Array = FOREST if zone == 2 else GRASS
			var kind := hz % 23
			if kind < 3 and zone == 1:
				# A few flowers in a little cluster.
				var col: Color = FLOWERS[(hx + hy) % FLOWERS.size()]
				for k in 3:
					var o := Vector2(float((hz + k * 5) % 5) - 2.0, float((hz + k * 3) % 3) - 1.0) * 2.0
					ci.draw_rect(Rect2(p + o, Vector2(1, 1)), col)
			elif kind < 4:
				ci.draw_rect(Rect2(p, Vector2(2, 1)), PEBBLE[hz % 3])
				ci.draw_rect(Rect2(p, Vector2(1, 1)), (PEBBLE[hz % 3] as Color).lightened(0.2))
			else:
				# A grass tuft: two or three short blades, lit on one side.
				var dark: Color = (pal[pal.size() - 1] as Color).darkened(0.1)
				var light: Color = (pal[0] as Color).lightened(0.1)
				ci.draw_rect(Rect2(p, Vector2(1, 2)), dark)
				ci.draw_rect(Rect2(p + Vector2(1, -1), Vector2(1, 3)), light if hz % 2 == 0 else dark)
				if hz % 3 == 0:
					ci.draw_rect(Rect2(p + Vector2(2, 0), Vector2(1, 2)), dark)
		elif zone == 3 and hz % 3 == 0:
			# Specks and small stones on the town's packed earth.
			ci.draw_rect(Rect2(p, Vector2(1, 1)), (EARTH[3] as Color).darkened(0.15))
			if hz % 2 == 0:
				ci.draw_rect(Rect2(p + Vector2(1, 0), Vector2(1, 1)), (EARTH[0] as Color).lightened(0.1))
	_shrubs(ci)
	_paint_decor(ci)


## Low shrubs and flower clumps over the house blocks' open ground, as thick as the reference's: painted into the
## floor, since they are too low to hide anyone. Buildings, gardens and trees stand over any that fall under them.
func _shrubs(ci: CanvasItem) -> void:
	var n := 0
	for d: Rect2 in TownLayout.DISTRICTS:
		var nx := int(d.size.x / SHRUB_STEP)
		var ny := int(d.size.y / SHRUB_STEP)
		for j in ny:
			for i in nx:
				n += 1
				var h := _hash(n * 7 + 3, n * 13 + 11)
				if float(h % 100) / 100.0 > SHRUB_CHANCE:
					continue
				var g := d.position + (Vector2(i, j) + Vector2(0.5, 0.5)) * SHRUB_STEP 					+ (Vector2(float(h % 17) / 17.0, float(h % 13) / 13.0) - Vector2(0.5, 0.5)) * SHRUB_STEP * 0.8
				if _zone(g) != 1:
					continue
				var p := Iso.ground_to_screen(g).round()
				ArtKit.begin()
				if h % 5 == 0:
					# A clump of flowers in one colour, among a little green.
					PropArt.leafy(p + Vector2(0, -2), Vector2(4, 2.5), h, 5, ArtKit.OAK)
					var col: Color = FLOWERS[h % FLOWERS.size()]
					for k in 4:
						ci.draw_rect(Rect2(p + Vector2(float((h + k * 7) % 7) - 3.0, float((h + k * 3) % 4) - 5.0), Vector2(1, 1)), col)
				else:
					var r := Vector2(4.0 + float(h % 4), 3.0 + float(h % 3))
					PropArt.leafy(p + Vector2(0, -r.y * 0.6), r, h, 7, ArtKit.OAK)
				ArtKit.flush(ci)


## Baked decor over the detail, back to front: trees, rocks, bushes, reeds and fences nothing ever stands in front of.
func _paint_decor(ci: CanvasItem) -> void:
	for d in baked_decor:
		# The same tuning a live Decor takes: its size about its ground point, and its colour.
		var key := String(Decor.Kind.keys()[d.kind]).to_lower()
		var sc := ArtTuning.scale(key)
		var at := Iso.ground_to_screen(d.at)
		ci.draw_set_transform(at * (1.0 - sc), 0.0, Vector2(sc, sc))
		ArtKit.color_mul = ArtTuning.tint(key)
		ArtKit.begin()
		DecorArt.paint(d.kind, d.at, d.size, d.seed, Vector2.ZERO)
		ArtKit.flush(ci)
	ArtKit.color_mul = Color.WHITE
	ci.draw_set_transform(Vector2.ZERO)


## What lies at a ground point for detail: 0 nothing (water, roads, paving, trails, fields), 1 meadow,
## 2 forest floor, 3 the town's earth.
func _zone(g: Vector2) -> int:
	for river: Rect2 in TownLayout.RIVERS:
		if river.grow(0.25).has_point(g):
			return 0
	for f: Rect2 in TownLayout.FIELDS:
		if f.grow(0.5).has_point(g):
			return 0
	if g.x < TownLayout.RIVER_WEST.end.x + 1.4 and absf(g.y - TownLayout.RIVER_WEST.position.y) < 1.6:
		return 0
	for road: Rect2 in TownLayout.ROADS:
		if road.grow(0.15).has_point(g):
			return 0
	if TownLayout.TOWN.has_point(g):
		if TownLayout.MARKET_SQUARE.has_point(g) or TownLayout.CITADEL_COURT.has_point(g) \
				or TownLayout.BARRACKS_YARD.has_point(g) or TownLayout.FOUNTAIN_PLAZA.has_point(g):
			return 0
		for plaza: Rect2 in TownLayout.GATE_PLAZAS:
			if plaza.grow(0.3).has_point(g):
				return 0
		for y: Rect2 in _yard_rects:
			if y.has_point(g):
				return 3
		for d: Rect2 in TownLayout.DISTRICTS:
			if d.grow(-0.2).has_point(g):
				return 1
		return 0
	if _zn == 0:
		return 2 if _forest(g) else 1
	var i := clampi(floori((g.x - FILL.position.x) / CELL), 0, _zn - 1)
	var j := clampi(floori((g.y - FILL.position.y) / CELL), 0, _zn - 1)
	var z := _zones[j * _zn + i]
	return 0 if z & 4 else (2 if z & 2 else 1)


static func _near_polyline(g: Vector2, pts: Array, d: float) -> bool:
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var ab := b - a
		var t := clampf((g - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if g.distance_to(a + ab * t) < d:
			return true
	return false
