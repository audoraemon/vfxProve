class_name TownFloor
extends Node2D
## Aldermere's ground after concepts/TOWN REF/Town Visual Upgrade.png:
## - outside the walls, a warm meadow in organic patches, darker under the forest, with dirt trails winding through;
## - dirt roads out of the gates;
## - inside, packed earth, cobbled streets, flagstones in the market and the Citadel court, and the barracks' sand;
## - farm tracks, and a saturated river with stony banks.
##
## Everything is painted once into a texture, and the floor draws just that one texture. The painting happens in a
## SubViewport that renders once: ground-unit shapes under the iso basis, then screen-pixel tufts, flowers and
## pebbles on top. It used to be ~10k rects replayed every frame. The river's glints are a small child node that
## redraws on its own. Without a renderer (headless) nothing is baked and the floor paints itself directly.

## Drawn area: past the map so zoomed-out views rarely show the void.
const FILL := Rect2(-24, -24, 52, 52)
## Meadow greens, light to dark, and the forest floor's.
const GRASS := [Color("9aa447"), Color("8a9a3c"), Color("7c8f35"), Color("6e8230"), Color("5f742b")]
const FOREST := [Color("6a7f30"), Color("5c722b"), Color("4f6527"), Color("435823")]
## Packed earth inside the walls.
const EARTH := [Color("b09468"), Color("a4885e"), Color("987c55"), Color("8a704c")]
## Dirt trails and roads [light, mid, dark].
const DIRT := [Color("c49a62"), Color("b08a56"), Color("94744a")]
const COBBLE := [Color("c4baac"), Color("b8ad9e"), Color("aa9f90"), Color("9c9082")]
const COBBLE_MORTAR := Color("6e6458")
const FLAG := [Color("c8c2b8"), Color("bdb6ac"), Color("b1a99e"), Color("a69e93")]
const FLAG_MORTAR := Color("7a7268")
const SAND := [Color("cdb07e"), Color("c4a674"), Color("b89a68")]
const WATER := [Color("3a82b4"), Color("2b70a4"), Color("225f93")]
const BANK := Color("4a4a38")
const PEBBLE := [Color("a8a49c"), Color("8e8a82"), Color("76726c")]
const FLOWERS := [Color("f4f0e0"), Color("f2d24a"), Color("f09a3a"), Color("e87aa0"), Color("b0d0f0")]
## Tilled band the farm fields sit in: dirt tracks show between them.
const FARM_BAND := Rect2(-12, 13.4, 28, 2.4)
## Decorative dirt trails through the meadow and forest (ground units), all clear of the walls.
const TRAILS := [
	[Vector2(-19, -12.2), Vector2(-14, -11.2), Vector2(-10, -12.6), Vector2(-5, -11.6), Vector2(0, -12.8),
		Vector2(6, -11.4), Vector2(12, -12.9), Vector2(19, -11.2)],
	[Vector2(-12.4, -19), Vector2(-11.6, -14), Vector2(-12.9, -8), Vector2(-11.3, -2), Vector2(-12.7, 4),
		Vector2(-11.8, 10.6)],
	[Vector2(11.2, -1.0), Vector2(12.6, -4.5), Vector2(11.4, -8.5), Vector2(13.8, -12.6), Vector2(17.5, -18)],
	[Vector2(-19, 16.4), Vector2(-8, 16.1), Vector2(0, 16.5), Vector2(10, 16.2), Vector2(19, 16.6)],
	[Vector2(16.0, 0.4), Vector2(17.5, 4.5), Vector2(15.8, 8.5), Vector2(17.8, 10.8)],
]
## Roads outside the walls, as trails: the south road to the bridge and beyond, the east road to the forest.
const ROAD_TRAILS := [
	[Vector2(0, 9.3), Vector2(0, 11.0)],
	[Vector2(0, 13.4), Vector2(0.1, 16.0), Vector2(-0.2, 19)],
	[Vector2(9.3, 0), Vector2(16, 0.1), Vector2(19, -0.2)],
]
## Grass painting cell (ground units) and the noise lattice spacing.
const CELL := 0.25
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
		for i in 90:
			var h := (i * 7919 + 13) % 997
			var y := r.position.y + 0.15 + float(h % 61) / 61.0 * (r.size.y - 0.3)
			var x := r.position.x - 8.0 + fposmod(float(h) * 0.53 + _time * (0.5 + float(h % 5) * 0.1), r.size.x + 16.0)
			draw_rect(Rect2(x, y, 0.3 + float(h % 3) * 0.12, 0.04), Color(0.82, 0.94, 1.0, 0.6))


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


## Decor painted into the floor (TownDecor spots with `bake`), back to front.
var baked_decor: Array[Dictionary] = []
## Per meadow cell: 1 meadow, 2 forest floor, +4 on a trail. Filled while painting the ground, read by the detail.
var _zones := PackedByteArray()
var _zn := 0
var _texture: Texture2D
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
	draw_texture(_texture, _origin)


static func _iso_bounds(r: Rect2) -> Rect2:
	var box := Rect2(Iso.ground_to_screen(r.position), Vector2.ZERO)
	for c in [Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		box = box.expand(Iso.ground_to_screen(c))
	return box


# --- Ground-unit layer ------------------------------------------------------------------

func paint_ground(ci: CanvasItem) -> void:
	_meadow(ci)
	# Inside the walls the lanes are cobbled throughout; each house stands in its own packed-earth yard.
	_paving(ci, TownLayout.TOWN, COBBLE, COBBLE_MORTAR, 0.2)
	for h: Rect2 in TownLayout.houses():
		_yard(ci, h.grow(0.3))
	_yard(ci, TownLayout.TEMPLE.grow(0.35))
	_patches(ci, FARM_BAND, DIRT, 0.3)
	for tr in TRAILS:
		_trail(ci, tr, 0.34)
	for tr in ROAD_TRAILS:
		_trail(ci, tr, 0.5)
	_patches(ci, TownLayout.BARRACKS_YARD, SAND, 0.3)
	_paving(ci, TownLayout.MARKET_SQUARE, FLAG, FLAG_MORTAR, 0.42)
	_paving(ci, TownLayout.CITADEL_COURT, FLAG, FLAG_MORTAR, 0.42)
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


## Forest floor beyond the walls on the west, north and east, north of the river and off the east road.
func _forest(g: Vector2) -> bool:
	if g.y > TownLayout.RIVER.position.y or (absf(g.y) < 1.2 and g.x > TownLayout.TOWN.end.x):
		return false
	var town := TownLayout.TOWN.grow(1.6)
	var edge := _noise(g * 1.7) * 1.4
	return g.x < town.position.x - edge or g.y < town.position.y - edge or g.x > town.end.x + edge


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
func _yard(ci: CanvasItem, r: Rect2) -> void:
	_patches(ci, r, EARTH, 0.25)
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
		ci.draw_circle(p, 0.1 + float(h % 5) * 0.03, EARTH[h % EARTH.size()])


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


## Water across the whole drawn width in bands, lighter at the edges and deep in the middle, with dark wet banks
## and pebbles along both of them.
func _river(ci: CanvasItem) -> void:
	var r := TownLayout.RIVER
	var x0 := FILL.position.x
	var w := FILL.size.x
	ci.draw_rect(Rect2(x0, r.position.y, w, r.size.y), WATER[0])
	ci.draw_rect(Rect2(x0, r.position.y + r.size.y * 0.15, w, r.size.y * 0.7), WATER[1])
	ci.draw_rect(Rect2(x0, r.position.y + r.size.y * 0.35, w, r.size.y * 0.3), WATER[2])
	ci.draw_rect(Rect2(x0, r.position.y - 0.1, w, 0.1), BANK)
	ci.draw_rect(Rect2(x0, r.end.y, w, 0.1), BANK)
	for bank_y in [r.position.y - 0.12, r.end.y + 0.12]:
		var x := x0
		var i := 0
		while x < FILL.end.x:
			var h := _hash(i * 17, roundi(bank_y * 10.0))
			x += 0.18 + float(h % 7) * 0.05
			i += 1
			if absf(x) < 1.3:
				continue
			var rad := 0.07 + float(h % 5) * 0.025
			var p := Vector2(x, bank_y + (float(h % 3) - 1.0) * 0.05)
			ci.draw_circle(p, rad, PEBBLE[h % 3])
			ci.draw_circle(p + Vector2(-0.02, -0.02), rad * 0.5, (PEBBLE[h % 3] as Color).lightened(0.12))


# --- Screen-pixel layer ------------------------------------------------------------------

## Tufts, flowers and pebbles in screen pixels over the meadow and the town's earth; none on water, roads or paving.
func paint_detail(ci: CanvasItem) -> void:
	var count := 36000
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
	_paint_decor(ci)


## Baked decor over the detail, back to front: trees, rocks, bushes, reeds and fences nothing ever stands in front of.
func _paint_decor(ci: CanvasItem) -> void:
	for d in baked_decor:
		ArtKit.begin()
		DecorArt.paint(d.kind, d.at, d.size, d.seed, Vector2.ZERO)
		ArtKit.flush(ci)


## What lies at a ground point for detail: 0 nothing (water, roads, paving, trails, fields), 1 meadow,
## 2 forest floor, 3 the town's earth.
func _zone(g: Vector2) -> int:
	var river := TownLayout.RIVER
	if g.y > river.position.y - 0.25 and g.y < river.end.y + 0.25:
		return 0
	if FARM_BAND.has_point(g):
		return 0
	for road: Rect2 in TownLayout.ROADS:
		if road.grow(0.15).has_point(g):
			return 0
	if TownLayout.TOWN.has_point(g):
		if TownLayout.MARKET_SQUARE.has_point(g) or TownLayout.CITADEL_COURT.has_point(g) \
				or TownLayout.BARRACKS_YARD.has_point(g):
			return 0
		return 3
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
