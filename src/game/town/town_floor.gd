class_name TownFloor
extends Node2D
## Aldermere's ground after concepts/TOWN REF/Town Visual Upgrade.png, at the Scale reference's size:
## - outside the walls, a warm meadow in organic patches, darker under the forest, with dirt trails winding through;
## - dirt roads out of the gates;
## The countryside (trails, roads, outcrops, rosettes, the forest's gaps, other water) is the active city's (CityDef).
## - inside, packed earth, cobbled streets, flagstones in the market and the Citadel court, and the barracks' sand;
## - tilled ground round the farms, and a saturated river (the south river and its west branch) with stony banks.
##
## Everything is painted once into a texture, and the floor draws just that one texture. The painting happens in a
## SubViewport that renders once: ground-unit shapes under the iso basis, then screen-pixel tufts, flowers and
## pebbles on top. It used to be ~10k rects replayed every frame. The river's glints are a small child node that
## redraws on its own. Without a renderer (headless) nothing is baked and the floor paints itself directly.

## Drawn area: past the map by this much (Aldermere: Rect2(-34, -34, 68, 68)), so zoomed-out views rarely show the
## void. _fill() is the active city's.
const FILL_MARGIN := 4.0
## Screen-pixel tufts, flowers and pebbles over Aldermere's drawn area; a larger city gets as many per cell.
const DETAIL_COUNT := 62000
const DETAIL_AREA := 68.0 * 68.0
## How far out from the walls the forest ring reaches (ground units): the reference's woods fill nearly all the land
## its fields leave.
const FOREST_OUT := 11.0
const ROCKY := [Color("b0aca3"), Color("99958c"), Color("827e76"), Color("6a675f")]
## Meadow greens, light to dark, and the forest floor's.
const GRASS := [Color("8aab4c"), Color("7a9d43"), Color("6c8f3c"), Color("5e8036"), Color("507030")]
const FOREST := [Color("5c7e34"), Color("4f712f"), Color("43632a"), Color("385524")]
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
## Grass painting cell (ground units) and the noise lattice spacing.
const CELL := 0.25
## Shrubs over the house blocks: the spacing of their jittered grid, and the share of its points that get one.
const SHRUB_STEP := 0.6
const SHRUB_CHANCE := 0.8
const LATTICE := 1.6
## The square the harbour basin's water is shaded in (_basins()).
const BASIN_CELL := 0.125
## The border band past the drawn fill (polish 3, CityDef.border()): its ground fades towards HAZE with distance, up to
## HAZE_MAX at the band's outer edge, so it reads as far-off country; woods grow in BAND_WOODS-sized patches where the
## band's own noise passes BAND_FOREST (next to the fill, within BAND_JOIN, the fill's own forest decides, so the two
## join); its tufts are as thick as the meadow's, hashed with BAND_SALT apart from the fill's.
const HAZE := Color("56653e")
const HAZE_MAX := 0.5
const BAND_WOODS := 6.0
const BAND_FOREST := 0.5
const BAND_JOIN := 2.5
const BAND_SALT := 4111
## How near the map's edge a road or trail must end to run on out through the band (border_roads()): one that reaches
## it. (A meadow trail stopping short of the edge fades out in the band's meadow.)
const EDGE_REACH := 0.05
## A tuft this near the map, past its edge, keeps the zone it had before the border band (its px may reach onto the map).
const EDGE_KEEP := 0.2

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
		for r: Rect2 in glints(_time):
			draw_rect(r, Color(0.82, 0.94, 1.0, 0.6))

	## The glints at `time` (ground rects): drifting down the river from past its west end to past its east, only where
	## the river is drawn (the border band carries it on past the map: TownFloor.drawn_area()); then the west branch's,
	## flowing south down to the main river (a city without one, the capital, has none).
	static func glints(time: float) -> Array[Rect2]:
		var out: Array[Rect2] = []
		var r := City.current().landmark(&"river")
		var drawn := TownFloor.drawn_area()
		for i in 200:
			var h := (i * 7919 + 13) % 997
			var y := r.position.y + 0.15 + float(h % 61) / 61.0 * (r.size.y - 0.3)
			var x := r.position.x - 8.0 + fposmod(float(h) * 0.53 + time * (0.5 + float(h % 5) * 0.1), r.size.x + 16.0)
			var g := Rect2(x, y, 0.3 + float(h % 3) * 0.12, 0.04)
			if g.position.x >= drawn.position.x and g.end.x <= drawn.end.x:
				out.append(g)
		var w := City.current().landmark(&"river_west")
		if not w.has_area():
			return out
		for i in 60:
			var h := (i * 6151 + 29) % 997
			var x := w.position.x + 0.15 + float(h % 43) / 43.0 * (w.size.x - 0.3)
			var y := w.position.y + fposmod(float(h) * 0.41 + time * (0.7 + float(h % 5) * 0.1), w.size.y)
			out.append(Rect2(x, y, 0.04, 0.3 + float(h % 3) * 0.12))
		return out


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
## The meadow shrubs this floor paints (shrub_spots() order); the town hands over its own copies, marked "under"
## (mark_under()), and shares them with the plant layer. Empty: shrub_spots() itself.
var shrubs: Array[Dictionary] = []
## Ground kept bare (Town.keep_clear, dev only): no rocky outcrop, meadow trail or field's tilled ground is painted on
## it. Empty in the game.
var keep_clear: Array[Rect2] = []
## Per meadow cell: 1 meadow, 2 forest floor, +4 on a trail. Filled while painting the ground, read by the detail.
var _zones := PackedByteArray()
var _zn := 0
var _texture: Texture2D
## House yards, worked out once per paint (the detail pass asks about them ~36k times).
var _yard_rects: Array[Rect2] = []
## Screen position of the baked texture's top-left corner.
var _origin := Vector2.ZERO
## shrub_spots(), worked out on first use per city (rebuilt when City.current() is another city object, as _geo()).
static var _shrub_spots: Array[Dictionary] = []
static var _shrubs_city: CityDef = null
## The active city's ground the floor asks about per cell (_geo()), read once per city.
static var _geo_city: CityDef = null
static var _geo_cache := {}


func _ready() -> void:
	add_to_group(&"decor_art")
	var glints := RiverGlints.new()
	glints.name = "RiverGlints"
	add_child(glints)
	if DisplayServer.get_name() != "headless":
		_bake()


func _bake() -> void:
	var bounds := _iso_bounds(drawn_area())
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


## F7 switched the art (ArtToggle): bake the floor again, so its baked decor and shrubs follow.
func art_changed() -> void:
	rebake()


## Frees the FloorBake viewport and bakes again. Headless there is no bake (`_texture` null), so nothing to redo.
func rebake() -> void:
	if _texture == null:
		return
	var old := get_node_or_null("FloorBake")
	if old != null:
		remove_child(old)
		old.queue_free()
	_bake()


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
	var geo := _geo()
	# The border band past the fill first (polish 3): the fill paints its own ground over it.
	_band_ground(ci)
	_meadow(ci)
	# Inside the walls the lanes are cobbled; the house blocks are worn ground, and each house stands in its own small
	# packed-earth yard, as in the reference.
	_paving(ci, geo.town, COBBLE, COBBLE_MORTAR, 0.2)
	for r: Rect2 in geo.paved:
		_paving(ci, r, COBBLE, COBBLE_MORTAR, 0.2)
	for d: Rect2 in geo.districts:
		_yard(ci, d.grow(-0.12), BLOCK)
	_yard_rects = _yards()
	for h: Rect2 in _yard_rects:
		_yard(ci, h, EARTH)
	# Tilled ground round every field and farmhouse.
	for f: Rect2 in geo.fields:
		if not _kept_clear(f):
			_patches(ci, f.grow(0.5), DIRT, 0.3)
	for b: Rect2 in geo.farm:
		_patches(ci, b.grow(0.6), DIRT, 0.3)
	for o: Array in geo.outcrops:
		var bare := false
		for k: Rect2 in keep_clear:
			bare = bare or k.grow(o[1]).has_point(o[0])
		if not bare:
			_outcrop(ci, o[0], o[1])
	for tr in geo.trails:
		_trail(ci, tr, 0.34, true)
	for tr: Dictionary in geo.road_trails:
		_trail(ci, tr.points, tr.width)
	# The roads and trails leaving the map run on out through the border band.
	for e: Array in border_roads():
		_edge_trail(ci, e[0], e[1], e[2])
	# A city's lawns inside the walls (the capital's royal garden) and the gravel paths across them.
	for l: Rect2 in geo.lawns:
		_patches(ci, l, GRASS, 0.25)
	for p: Dictionary in geo.paths:
		_trail(ci, p.points, p.width)
	for y: Rect2 in geo.yards:
		_patches(ci, y, SAND, 0.3)
	for p: Rect2 in geo.plazas:
		_paving(ci, p, FLAG, FLAG_MORTAR, 0.42)
	# The ground inside each gate, where the crowd queues, is cobbled like the streets.
	var gate_plazas: Array = geo.gate_plazas
	for plaza: Rect2 in gate_plazas:
		_paving(ci, plaza.grow(0.3), COBBLE, COBBLE_MORTAR, 0.2)
	# The gate plazas are the crowd's queue ground and stay open (the city's queue_fans()): dressed on the floor
	# instead, with a paved rosette and the ruts carts have worn towards each gate.
	var rosettes: Array = geo.rosettes
	for i in gate_plazas.size():
		# Each plaza's rosette, by index (the city's rosettes()): only a plaza holding its rosette gets it and its ruts.
		if i >= rosettes.size() or not (gate_plazas[i] as Rect2).has_point(rosettes[i].at):
			continue
		_ruts(ci, gate_plazas[i], i, rosettes[i].along_y, rosettes[i].across)
		_rosette(ci, rosettes[i].at, rosettes[i].radius)
	_river(ci)


static func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 997


## Smooth value noise in [0, 1): a hashed lattice, bilinearly blended, plus a finer octave.
static func _noise(g: Vector2) -> float:
	return _octave(g / LATTICE, 0) * 0.7 + _octave(g / (LATTICE * 0.35), 1) * 0.3


static func _octave(p: Vector2, salt: int) -> float:
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
	var n := int(_fill().size.x / CELL)
	_zn = n
	_zones.resize(n * n)
	for j in n:
		for i in n:
			var g := _fill().position + Vector2(i, j) * CELL
			var c := g + Vector2(CELL, CELL) * 0.5
			var forest := _forest(c)
			_zones[j * n + i] = 2 if forest else 1
			var pal: Array = FOREST if forest else GRASS
			var v := clampf(_noise(c) * 1.25 - 0.12, 0.0, 0.999)
			ci.draw_rect(Rect2(g, Vector2(CELL, CELL)), pal[int(v * pal.size())])


## Forest floor in a ring round the walls (farmland beyond it), north of the river and off the city's forest gaps (its
## roads out of the walls: CityDef.forest_gaps()).
static func _forest(g: Vector2) -> bool:
	var geo := _geo()
	if g.y > (geo.river as Rect2).position.y:
		return false
	var t: Rect2 = geo.town
	if in_forest_gap(g):
		return false
	var edge := _noise(g * 1.7) * 1.4
	var out := maxf(maxf(t.position.x - g.x, g.x - t.end.x), maxf(t.position.y - g.y, g.y - t.end.y))
	return out > 1.6 + edge and out < FOREST_OUT + edge


## Whether `g` lies in one of the active city's forest gaps (CityDef.forest_gaps()), where no forest grows.
static func in_forest_gap(g: Vector2) -> bool:
	for gap: Rect2 in _geo().forest_gaps:
		if gap.has_point(g):
			return true
	return false


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
	var city := City.current()
	for h: Rect2 in city.houses():
		out.append(h.grow(0.22))
	out.append_array(city.floor_areas().get(&"building_yards", []))
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


## A paved rosette: rings of flagstones round a dark centre stone, as the reference's squares have.
func _rosette(ci: CanvasItem, c: Vector2, rad: float) -> void:
	ci.draw_circle(c, rad + 0.08, FLAG_MORTAR.darkened(0.15))
	var rings := int(rad / 0.36)
	for k in range(rings, 0, -1):
		var r0 := rad * float(k - 1) / rings + 0.05
		var r1 := rad * float(k) / rings
		ci.draw_circle(c, r1, FLAG_MORTAR)
		var n := maxi(int(TAU * (r0 + r1) * 0.5 / 0.42), 6)
		for i in n:
			var a0 := TAU * (i + 0.06) / n
			var a1 := TAU * (i + 0.94) / n
			var col: Color = FLAG[(i + k) % FLAG.size()] if k % 2 == 0 else COBBLE[(i * 3 + k) % COBBLE.size()]
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2.from_angle(a0) * r0, c + Vector2.from_angle(a1) * r0,
				c + Vector2.from_angle(a1) * (r1 - 0.04), c + Vector2.from_angle(a0) * (r1 - 0.04)]), col)
	ci.draw_circle(c, rad / rings * 0.8, ROCKY[2])
	ci.draw_circle(c + Vector2(-0.05, -0.05), rad / rings * 0.55, ROCKY[1])


## Ruts worn into the cobbles by carts: two dark tracks through the plaza towards its gate, a wheel apart, along the
## line `across` (x when `along_y`: they run north-south; else y, west-east). `salt` is the plaza's index.
func _ruts(ci: CanvasItem, plaza: Rect2, salt: int, along_y: bool, across: float) -> void:
	var rut := (COBBLE_MORTAR as Color).darkened(0.3)
	var from := plaza.position.y - 2.0 if along_y else plaza.position.x - 2.0
	var to := plaza.end.y + 0.8 if along_y else plaza.end.x + 0.8
	for side: float in [-0.32, 0.32]:
		var t := from
		while t < to:
			var h := _hash(int(t * 10.0) + salt * 31, int(side * 10.0) + 50)
			var off := across + side + sin(t * 1.3 + side * 9.0) * 0.05
			var seg := Rect2(off - 0.08, t, 0.16, 0.2) if along_y else Rect2(t, off - 0.08, 0.2, 0.16)
			ci.draw_rect(seg, rut if h % 4 != 0 else rut.lightened(0.12))
			t += 0.22


## Whether a ground point lies on one of the rocky outcrops (nothing grows there but rocks).
static func on_outcrop(g: Vector2) -> bool:
	for o: Array in _geo().outcrops:
		if g.distance_to(o[0]) < float(o[1]):
			return true
	return false


## A rocky outcrop: boulders of grey stone heaped together, dark between them and lit on their upper faces, with no
## grass growing on it.
func _outcrop(ci: CanvasItem, c: Vector2, rad: float) -> void:
	var n := int(rad * 9.0)
	var stones: Array[Vector3] = []
	for i in n:
		var h := _hash(i * 17 + roundi(c.x * 7.0), i * 29 + roundi(c.y * 11.0))
		var a := float(h % 360) * PI / 180.0
		var d := sqrt(float(h % 97) / 97.0) * rad * 0.78
		stones.append(Vector3(c.x + cos(a) * d, c.y + sin(a) * d, 0.3 + float(h % 11) / 11.0 * 0.45))
	# Back to front, so the nearer boulders overlap the farther.
	stones.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.x + p.y < q.x + q.y)
	for s in stones:
		var p := Vector2(s.x, s.y)
		ci.draw_circle(p, s.z + 0.08, ROCKY[3].darkened(0.25))
		_mark_trail(p, s.z + 0.15)
	for s in stones:
		var p := Vector2(s.x, s.y)
		var h := _hash(roundi(s.x * 31.0), roundi(s.y * 37.0))
		ci.draw_circle(p, s.z, ROCKY[1 + h % 2])
		ci.draw_circle(p + Vector2(-0.08, -0.08) * s.z * 2.0, s.z * 0.62, ROCKY[0])
		ci.draw_circle(p + Vector2(0.1, 0.1) * s.z * 2.0, s.z * 0.35, ROCKY[3])


## Whether `r` touches the ground kept bare (keep_clear: the dev showcase only).
func _kept_clear(r: Rect2) -> bool:
	for k: Rect2 in keep_clear:
		if k.intersects(r):
			return true
	return false


## A dirt trail: overlapping discs of ragged size along a polyline, dark rim first, then the lighter tread. `clearable`:
## none of it on the ground kept bare (keep_clear; a meadow trail, not a road).
func _trail(ci: CanvasItem, pts: Array, width: float, clearable := false) -> void:
	for pass_i in 2:
		for k in pts.size() - 1:
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[k + 1]
			var steps := maxi(int(a.distance_to(b) / 0.14), 1)
			for i in steps + 1:
				var p := a.lerp(b, float(i) / steps)
				if clearable and not keep_clear.is_empty() and _kept_clear(Rect2(p, Vector2.ZERO).grow(width)):
					continue
				var h := _hash(roundi(p.x * 37.0), roundi(p.y * 41.0))
				var r := width * (0.85 + float(h % 23) / 23.0 * 0.35)
				if pass_i == 0:
					ci.draw_circle(p, r + 0.06, DIRT[2])
					_mark_trail(p, r + 0.15)
				else:
					ci.draw_circle(p + Vector2(0.02, -0.02), r * 0.8, DIRT[h % 2])


## Flag the meadow cells within `r` of `p` as trail, so no tuft or flower grows on it.
func _mark_trail(p: Vector2, r: float) -> void:
	# (a road carried on through the border band reaches past the fill: those stretches mark nothing)
	if _zn == 0 or not _fill().grow(r).has_point(p):
		return
	var i0 := maxi(floori((p.x - r - _fill().position.x) / CELL), 0)
	var i1 := mini(floori((p.x + r - _fill().position.x) / CELL), _zn - 1)
	var j0 := maxi(floori((p.y - r - _fill().position.y) / CELL), 0)
	var j1 := mini(floori((p.y + r - _fill().position.y) / CELL), _zn - 1)
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
	var r := City.current().landmark(&"river")
	# Across the whole drawn ground, the border band's too (its pebbles: the fill's run, then the band's either side).
	var x0 := drawn_area().position.x
	var w := drawn_area().size.x
	ci.draw_rect(Rect2(x0, r.position.y, w, r.size.y), WATER[0])
	ci.draw_rect(Rect2(x0, r.position.y + r.size.y * 0.15, w, r.size.y * 0.7), WATER[1])
	ci.draw_rect(Rect2(x0, r.position.y + r.size.y * 0.35, w, r.size.y * 0.3), WATER[2])
	ci.draw_rect(Rect2(x0, r.position.y - 0.1, w, 0.1), BANK)
	ci.draw_rect(Rect2(x0, r.end.y, w, 0.1), BANK)
	# Any other water of the city's (the capital's harbour basin), shaded as the river is: by distance from its shore.
	_basins(ci)
	var b := City.current().landmark(&"river_west")
	if b.has_area():
		var bx0 := drawn_area().position.x
		var bw := b.end.x - bx0
		ci.draw_rect(Rect2(bx0, b.position.y, bw, b.size.y), WATER[0])
		ci.draw_rect(Rect2(b.position.x + b.size.x * 0.15, b.position.y, b.size.x * 0.7, b.size.y), WATER[1])
		ci.draw_rect(Rect2(b.position.x + b.size.x * 0.35, b.position.y, b.size.x * 0.3, b.size.y), WATER[2])
		ci.draw_rect(Rect2(b.end.x, b.position.y, 0.1, b.size.y), BANK)
	var gaps: Array[float] = _geo().crossings
	var fill := _fill()
	var drawn := drawn_area()
	for bank_y: float in [r.position.y - 0.12, r.end.y + 0.12]:
		_pebbles(ci, Vector2(fill.position.x, bank_y), Vector2(fill.end.x, bank_y), gaps)
		# The banks run on through the border band either side of the fill.
		if drawn.position.x < fill.position.x:
			_pebbles(ci, Vector2(drawn.position.x, bank_y), Vector2(fill.position.x, bank_y), gaps)
			_pebbles(ci, Vector2(fill.end.x, bank_y), Vector2(drawn.end.x, bank_y), gaps)
	if b.has_area():
		_pebbles(ci, Vector2(b.end.x + 0.12, b.position.y), Vector2(b.end.x + 0.12, r.position.y), [] as Array[float])
		_waterfall(ci, b)
		_band_cliff(ci, b)
	for s: Array in _geo().basin_shores:
		var n: Vector2 = s[2]
		_pebbles(ci, (s[0] as Vector2) + n * 0.12, (s[1] as Vector2) + n * 0.12, gaps)


## The west branch's source: a band of grey cliff across its head, and white water falling from it into a pool.
func _waterfall(ci: CanvasItem, b: Rect2) -> void:
	var y := b.position.y
	for i in 26:
		var h := _hash(i * 13 + 5, 77)
		var p := Vector2(_fill().position.x + float(i) / 26.0 * (b.end.x + 1.2 - _fill().position.x), y - 0.35 - float(h % 5) * 0.12)
		var rad := 0.35 + float(h % 4) * 0.12
		ci.draw_circle(p, rad, PEBBLE[2].darkened(0.1))
		ci.draw_circle(p + Vector2(-0.08, -0.08), rad * 0.7, PEBBLE[1])
		ci.draw_circle(p + Vector2(-0.14, -0.14), rad * 0.35, PEBBLE[0])
	# Falling water: a ragged sheet of pale water down over the cliff's lip, broken white streaks along the fall, and
	# churned foam at its foot. Nothing evenly spaced: a regular comb of thin stripes aliased into a pale checkerboard
	# at the overview's zoom.
	var x0 := b.position.x + b.size.x * 0.3
	var x1 := b.end.x - b.size.x * 0.3
	var cols := 12
	for i in cols:
		var h := _hash(i * 31 + 7, 53)
		var top := y - 0.75 + float(h % 4) * 0.06
		var bottom := y + 0.15 + float(h % 3) * 0.08
		var cx := lerpf(x0, x1, float(i) / float(cols))
		ci.draw_rect(Rect2(cx, top, (x1 - x0) / float(cols) + 0.01, bottom - top), Color("6cb4e0"))
	for i in 6:
		var h := _hash(i * 19 + 11, 67)
		var x := lerpf(x0 + 0.08, x1 - 0.2, (float(i) + float(h % 7) / 7.0) / 6.0)
		var top := y - 0.7 + float(h % 5) * 0.08
		ci.draw_rect(Rect2(x, top, 0.1, 0.35 + float(h % 4) * 0.14), Color(0.95, 0.98, 1.0, 0.75))
	for i in 22:
		var h := _hash(i * 7, 91)
		var k := _hash(i * 5 + 3, 29)
		var spread := 0.15 + float(k % 5) * 0.08
		var p := Vector2(lerpf(x0 - spread, x1 + spread, float(h % 97) / 97.0), y + 0.1 + float(k % 7) * 0.11)
		ci.draw_circle(p, 0.08 + float(h % 4) * 0.035, Color(0.95, 0.98, 1.0, 0.85) if k % 3 else Color("cfe8f4"))


## Pebbles along a bank from a to b, leaving a gap round each bridge (the x of each in `gaps`, the city's crossings),
## and none where other water (a basin) opens off the bank.
func _pebbles(ci: CanvasItem, a: Vector2, b: Vector2, gaps: Array[float]) -> void:
	var length := a.distance_to(b)
	var d := 0.0
	var i := 0
	var basins: Array = _geo().basins
	while d < length:
		var h := _hash(i * 17, roundi((a.x + a.y) * 10.0))
		d += 0.18 + float(h % 7) * 0.05
		i += 1
		var p := a.lerp(b, minf(d / length, 1.0))
		var skip := false
		for gx: float in gaps:
			skip = skip or absf(p.x - gx) < 1.3
		for o: Rect2 in basins:
			skip = skip or o.has_point(p)
		if skip:
			continue
		var rad := 0.07 + float(h % 5) * 0.025
		p += (Vector2(0, 1) if absf(b.x - a.x) > absf(b.y - a.y) else Vector2(1, 0)) * (float(h % 3) - 1.0) * 0.05
		ci.draw_circle(p, rad, PEBBLE[h % 3])
		ci.draw_circle(p + Vector2(-0.02, -0.02), rad * 0.5, (PEBBLE[h % 3] as Color).lightened(0.12))


## The city's other water (the capital's harbour basin), shaded by distance from its shore as the river is across its
## width (_water_band()): light water along the quays, then mid, then deep; and a dark wet bank along its quays
## (their pebbles in _river()). Drawn in runs of BASIN_CELL squares, worked out once per city.
func _basins(ci: CanvasItem) -> void:
	var geo := _geo()
	if (geo.basins as Array).is_empty():
		return
	if not geo.has(&"basin_runs"):
		var runs: Array = []
		for o: Rect2 in geo.basins:
			var y := o.position.y
			while y < o.end.y:
				var x := o.position.x
				var run_x := x
				var run_band := -2
				while x <= o.end.x + 0.001:
					var band := _water_band(Vector2(x + BASIN_CELL * 0.5, y + BASIN_CELL * 0.5)) if x < o.end.x - 0.001 else -3
					if band != run_band:
						if run_band >= 0:
							runs.append([Rect2(run_x, y, x - run_x, BASIN_CELL), run_band])
						run_x = x
						run_band = band
					x += BASIN_CELL
				y += BASIN_CELL
		geo[&"basin_runs"] = runs
	for run: Array in geo.basin_runs:
		ci.draw_rect(run[0], WATER[run[1]])
	for s: Array in geo.basin_shores:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var n: Vector2 = s[2]
		ci.draw_rect(Rect2(a.min(b) + n.min(Vector2.ZERO) * 0.1, (b - a).abs() + n.abs() * 0.1), BANK)


## Which band of water `g` lies in -- 0 light, 1 mid, 2 deep -- or -1 on dry land. The river's bands run across its
## width (its outer 15% light, the next 20% mid, the middle deep); a basin's are the same widths, measured from the
## nearest shore (its quays and the river's banks), so the two join where they meet.
static func _water_band(g: Vector2) -> int:
	var geo := _geo()
	var r: Rect2 = geo.river
	for o: Rect2 in geo.basins:
		if o.has_point(g):
			var d := INF
			for s: Array in geo.shores:
				d = minf(d, _seg_dist(g, s[0], s[1]))
			return _band(d / r.size.y)
	var fill: Rect2 = geo.outer
	if g.y >= r.position.y and g.y < r.end.y and g.x >= fill.position.x and g.x < fill.end.x:
		return _band(minf(g.y - r.position.y, r.end.y - g.y) / r.size.y)
	return -1


static func _band(f: float) -> int:
	return 0 if f < 0.15 else (1 if f < 0.35 else 2)


static func _seg_dist(g: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((g - a).dot(ab) / ab.length_squared(), 0.0, 1.0) if ab.length_squared() > 0.0 else 0.0
	return g.distance_to(a + ab * t)


## A basin's quays: each side of `o` (as drawn) not on the drawn area's edge, less where `water` opens off it, as
## [a, b, the land side's unit normal].
static func _shores(o: Rect2, fill: Rect2, water: Array[Rect2]) -> Array:
	var out: Array = []
	var sides := [
		[Vector2(o.position.x, o.position.y), Vector2(o.end.x, o.position.y), Vector2(0, -1)],
		[Vector2(o.position.x, o.end.y), Vector2(o.end.x, o.end.y), Vector2(0, 1)],
		[Vector2(o.position.x, o.position.y), Vector2(o.position.x, o.end.y), Vector2(-1, 0)],
		[Vector2(o.end.x, o.position.y), Vector2(o.end.x, o.end.y), Vector2(1, 0)],
	]
	for sd: Array in sides:
		var a: Vector2 = sd[0]
		var n: Vector2 = sd[2]
		var on_edge := (n.x < 0.0 and a.x <= fill.position.x) or (n.x > 0.0 and a.x >= fill.end.x) \
			or (n.y < 0.0 and a.y <= fill.position.y) or (n.y > 0.0 and a.y >= fill.end.y)
		if not on_edge:
			out.append_array(_cut(a, sd[1], n, water))
	return out


## The axis-aligned segment a-b less the stretches where any of `water` lies just past it on its land side `n`, each
## piece as [a, b, n].
static func _cut(a: Vector2, b: Vector2, n: Vector2, water: Array[Rect2]) -> Array:
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	var pieces: Array = [[minf(a.x, b.x), maxf(a.x, b.x)] if along_x else [minf(a.y, b.y), maxf(a.y, b.y)]]
	var probe := a + n * 0.01
	for w: Rect2 in water:
		var across := (w.position.y <= probe.y and probe.y <= w.end.y) if along_x \
			else (w.position.x <= probe.x and probe.x <= w.end.x)
		if not across:
			continue
		var w0 := w.position.x if along_x else w.position.y
		var w1 := w.end.x if along_x else w.end.y
		var next: Array = []
		for pc: Array in pieces:
			if w1 <= pc[0] or w0 >= pc[1]:
				next.append(pc)
				continue
			if w0 > pc[0]:
				next.append([pc[0], w0])
			if w1 < pc[1]:
				next.append([w1, pc[1]])
		pieces = next
	var out: Array = []
	for pc: Array in pieces:
		if pc[1] - pc[0] > 0.01:
			out.append([Vector2(pc[0], a.y), Vector2(pc[1], a.y), n] if along_x else [Vector2(a.x, pc[0]), Vector2(a.x, pc[1]), n])
	return out


# --- The border band (polish 3) ---------------------------------------------------------------

## The whole drawn ground: the active city's map grown by its border band (CityDef.border()), or by FILL_MARGIN when
## that is deeper. The camera keeps its view on it (Mission.clamp_view()).
static func drawn_area() -> Rect2:
	return _geo().outer


## The camera position nearest `pos` (screen px) at which a view `view` px across at `zoom` lies wholly on the drawn
## ground: its corners' ground points inside drawn_area() (every view corner reaches the same ground distance past its
## middle, so the middle keeps that far inside, clamped on the ground's axes). The drawn ground's middle when it is
## too small for the view.
static func keep_in_view(pos: Vector2, zoom: float, view: Vector2) -> Vector2:
	var half := view * 0.5 / maxf(zoom, 0.01)
	var reach := (half.x / 32.0 + half.y / 16.0) * 0.5
	var outer := drawn_area()
	var room := outer.grow(-reach)
	var mid := outer.get_center()
	var g := Iso.screen_to_ground(pos)
	g.x = clampf(g.x, room.position.x, room.end.x) if room.size.x >= 0.0 else mid.x
	g.y = clampf(g.y, room.position.y, room.end.y) if room.size.y >= 0.0 else mid.y
	var out := Iso.ground_to_screen(g)
	# A position already in reach stays exactly where it was (no round trip through ground units).
	return pos if out.is_equal_approx(pos) else out


## Whether `g` lies on the city's water as drawn: its rivers, each carried on to the drawn area's edge past every side
## of the map it meets (the harbour basin too).
static func wet(g: Vector2) -> bool:
	for w: Rect2 in _geo().wet:
		if w.has_point(g):
			return true
	return false


## `rivers`, each run on from every side of `map` it meets out to that side of `outer`.
static func _wet_rects(rivers: Array[Rect2], map: Rect2, outer: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r: Rect2 in rivers:
		var e := r
		if r.position.x <= map.position.x + 0.01:
			e = e.expand(Vector2(outer.position.x, e.position.y))
		if r.end.x >= map.end.x - 0.01:
			e = e.expand(Vector2(outer.end.x, e.position.y))
		if r.position.y <= map.position.y + 0.01:
			e = e.expand(Vector2(e.position.x, outer.position.y))
		if r.end.y >= map.end.y - 0.01:
			e = e.expand(Vector2(e.position.x, outer.end.y))
		out.append(e)
	return out


## The roads and trails that leave the map, run on out through the border band: each [polyline, width, beyond], from
## the end lying within EDGE_REACH of the map's edge straight out across the band, past the drawn area's edge; `beyond`
## is the ground past that side of the map, the only ground it is painted on (_edge_trail()).
static func border_roads() -> Array:
	var geo := _geo()
	var map := City.current().map()
	var outer: Rect2 = geo.outer
	var out: Array = []
	var lines: Array = []
	for tr: Dictionary in geo.road_trails:
		lines.append([tr.points, tr.width])
	for tr: Array in geo.trails:
		lines.append([tr, 0.34])
	for line: Array in lines:
		var pts: Array = line[0]
		for end: Vector2 in [pts[0], pts[pts.size() - 1]]:
			var dir := Vector2.ZERO
			if end.x - map.position.x < EDGE_REACH:
				dir = Vector2(-1, 0)
			elif map.end.x - end.x < EDGE_REACH:
				dir = Vector2(1, 0)
			elif end.y - map.position.y < EDGE_REACH:
				dir = Vector2(0, -1)
			elif map.end.y - end.y < EDGE_REACH:
				dir = Vector2(0, 1)
			if dir == Vector2.ZERO:
				continue
			var reach := absf((outer.position.x if dir.x < 0.0 else outer.end.x) - end.x) if dir.x != 0.0 \
				else absf((outer.position.y if dir.y < 0.0 else outer.end.y) - end.y)
			var big := outer.grow(2.0)
			var beyond := Rect2(map.end.x, big.position.y, big.end.x - map.end.x, big.size.y)
			if dir.x < 0.0:
				beyond = Rect2(big.position.x, big.position.y, map.position.x - big.position.x, big.size.y)
			elif dir.y < 0.0:
				beyond = Rect2(big.position.x, big.position.y, big.size.x, map.position.y - big.position.y)
			elif dir.y > 0.0:
				beyond = Rect2(big.position.x, map.end.y, big.size.x, big.end.y - map.end.y)
			out.append([[end, end + dir * (reach + 0.5)], line[1], beyond])
	return out


## A road carried out through the band (border_roads()): a dirt trail as _trail() paints one, faded as the band's
## ground, its discs cut to `beyond`, the ground past the map's edge it leaves by, so none of it reaches back onto the
## map; its tread is marked for the detail there only.
func _edge_trail(ci: CanvasItem, pts: Array, width: float, beyond: Rect2) -> void:
	var clip := PackedVector2Array([beyond.position, Vector2(beyond.end.x, beyond.position.y), beyond.end,
		Vector2(beyond.position.x, beyond.end.y)])
	for pass_i in 2:
		for k in pts.size() - 1:
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[k + 1]
			var steps := maxi(int(a.distance_to(b) / 0.14), 1)
			for i in steps + 1:
				var p := a.lerp(b, float(i) / steps)
				var h := _hash(roundi(p.x * 37.0), roundi(p.y * 41.0))
				var r := width * (0.85 + float(h % 23) / 23.0 * 0.35)
				var c := p if pass_i == 0 else p + Vector2(0.02, -0.02)
				var rad := r + 0.06 if pass_i == 0 else r * 0.8
				var col: Color = DIRT[2] if pass_i == 0 else DIRT[h % 2]
				var disc := PackedVector2Array()
				for q in 20:
					disc.append(c + Vector2.from_angle(TAU * q / 20.0) * rad)
				for poly: PackedVector2Array in Geometry2D.intersect_polygons(disc, clip):
					ci.draw_colored_polygon(poly, col.lerp(HAZE, band_haze(c)))
				if pass_i == 0:
					_mark_trail_in(p, r + 0.15, beyond)


## _mark_trail() for the fill's cells whose middles lie inside `within` only, and not within EDGE_KEEP of the map (a
## tuft there may reach a px or two onto the map: it stays as it was).
func _mark_trail_in(p: Vector2, r: float, within: Rect2) -> void:
	if _zn == 0 or not _fill().grow(r).has_point(p):
		return
	var keep := City.current().map().grow(EDGE_KEEP)
	var i0 := maxi(floori((p.x - r - _fill().position.x) / CELL), 0)
	var i1 := mini(floori((p.x + r - _fill().position.x) / CELL), _zn - 1)
	var j0 := maxi(floori((p.y - r - _fill().position.y) / CELL), 0)
	var j1 := mini(floori((p.y + r - _fill().position.y) / CELL), _zn - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var c := _fill().position + (Vector2(i, j) + Vector2(0.5, 0.5)) * CELL
			if within.has_point(c) and not keep.has_point(c):
				_zones[j * _zn + i] |= 4


## How far `g` lies past the fill, as a share of the band's depth (0 at the fill's edge, 1 at the drawn area's).
static func _band_depth(g: Vector2) -> float:
	var fill := _fill()
	var outer := drawn_area()
	var out := maxf(maxf(fill.position.x - g.x, g.x - fill.end.x), maxf(fill.position.y - g.y, g.y - fill.end.y))
	var deep := maxf(fill.position.x - outer.position.x, 0.01)
	return clampf(out / deep, 0.0, 1.0)


## How much a point of the band fades to HAZE: none at the fill's edge, HAZE_MAX at the drawn area's.
static func band_haze(g: Vector2) -> float:
	var d := _band_depth(g)
	return HAZE_MAX * d * (2.0 - d)


## Whether band point `g` is woodland: within BAND_JOIN of the fill, as the fill's forest at its nearest edge point;
## further out, the band's own large patches; never on the water or a bank.
static func band_forest(g: Vector2) -> bool:
	if wet(g) or wet(g + Vector2(0.9, 0.9)) or wet(g - Vector2(0.9, 0.9)):
		return false
	var fill := _fill()
	var edge := g.clamp(fill.position, fill.end - Vector2(0.01, 0.01))
	if g.distance_to(edge) < BAND_JOIN:
		return _forest(edge)
	return _octave(g / BAND_WOODS, 7) > BAND_FOREST


## The border band's ground: meadow or forest floor in the fill's patches, fading to HAZE with distance; the water is
## painted over it after (_river()).
func _band_ground(ci: CanvasItem) -> void:
	var fill := _fill()
	var outer := drawn_area()
	if outer.is_equal_approx(fill):
		return
	var n := int(outer.size.x / CELL)
	var m := int(outer.size.y / CELL)
	for j in m:
		for i in n:
			var g := outer.position + Vector2(i, j) * CELL
			var c := g + Vector2(CELL, CELL) * 0.5
			if fill.has_point(c):
				continue
			var pal: Array = FOREST if band_forest(c) else GRASS
			var v := clampf(_noise(c) * 1.25 - 0.12, 0.0, 0.999)
			ci.draw_rect(Rect2(g, Vector2(CELL, CELL)), (pal[int(v * pal.size())] as Color).lerp(HAZE, band_haze(c)))


## The west branch's cliff carried on through the band, west of the fill (_waterfall()'s boulders end at the fill).
func _band_cliff(ci: CanvasItem, b: Rect2) -> void:
	var x0 := drawn_area().position.x
	var x1 := _fill().position.x
	if x1 - x0 < 0.5:
		return
	var y := b.position.y
	var n := int((x1 - x0) / 0.32)
	for i in n:
		var h := _hash(i * 13 + 5, 177)
		var p := Vector2(x0 + (float(i) + 0.5) / float(n) * (x1 - x0), y - 0.35 - float(h % 5) * 0.12)
		var rad := 0.35 + float(h % 4) * 0.12
		var k := band_haze(p)
		ci.draw_circle(p, rad, (PEBBLE[2] as Color).darkened(0.1).lerp(HAZE, k))
		ci.draw_circle(p + Vector2(-0.08, -0.08), rad * 0.7, (PEBBLE[1] as Color).lerp(HAZE, k))
		ci.draw_circle(p + Vector2(-0.14, -0.14), rad * 0.35, (PEBBLE[0] as Color).lerp(HAZE, k))


## The band's tufts and flowers in screen pixels, as thick as the fill's: on its meadow and forest floor only, off the
## water and the roads carried out through it, faded as its ground is.
func _band_detail(ci: CanvasItem) -> void:
	var fill := _fill()
	var outer := drawn_area()
	if outer.is_equal_approx(fill):
		return
	var roads := border_roads()
	var count := roundi(DETAIL_COUNT * outer.get_area() / DETAIL_AREA)
	for i in count:
		var hx := _hash(i * 3 + BAND_SALT, i * 7 + 5)
		var hy := _hash(i * 11 + 3, i * 5 + BAND_SALT)
		var hz := _hash(i * 13 + 7 + BAND_SALT, i * 17 + 1)
		var g := outer.position + Vector2((float(hx) + float(hz % 10) / 10.0) / 997.0 * outer.size.x,
			(float(hy) + float(hz % 7) / 7.0) / 997.0 * outer.size.y)
		if fill.grow(0.2).has_point(g) or wet(g) or wet(g + Vector2(0.25, 0.25)) or wet(g - Vector2(0.25, 0.25)):
			continue
		var on_road := false
		for e: Array in roads:
			on_road = on_road or _near_polyline(g, e[0], float(e[1]) + 0.2)
		if on_road:
			continue
		var forest := band_forest(g)
		var k := band_haze(g)
		var p := Iso.ground_to_screen(g).round()
		var pal: Array = FOREST if forest else GRASS
		var kind := hz % 23
		if kind < 3 and not forest:
			var col: Color = (FLOWERS[(hx + hy) % FLOWERS.size()] as Color).lerp(HAZE, k)
			for q in 3:
				var o := Vector2(float((hz + q * 5) % 5) - 2.0, float((hz + q * 3) % 3) - 1.0) * 2.0
				ci.draw_rect(Rect2(p + o, Vector2(1, 1)), col)
		elif kind >= 4:
			var dark: Color = (pal[pal.size() - 1] as Color).darkened(0.1).lerp(HAZE, k)
			var light: Color = (pal[0] as Color).lightened(0.1).lerp(HAZE, k)
			ci.draw_rect(Rect2(p, Vector2(1, 2)), dark)
			ci.draw_rect(Rect2(p + Vector2(1, -1), Vector2(1, 3)), light if hz % 2 == 0 else dark)
			if hz % 3 == 0:
				ci.draw_rect(Rect2(p + Vector2(2, 0), Vector2(1, 2)), dark)


# --- Screen-pixel layer ------------------------------------------------------------------

## Tufts, flowers and pebbles in screen pixels over the meadow and the town's earth; none on water, roads or paving.
func paint_detail(ci: CanvasItem) -> void:
	# The border band's first: the fill's own never reaches it.
	_band_detail(ci)
	var count := roundi(DETAIL_COUNT * _fill().get_area() / DETAIL_AREA)
	for i in count:
		var hx := _hash(i * 3 + 1, i * 7 + 5)
		var hy := _hash(i * 11 + 3, i * 5 + 9)
		var hz := _hash(i * 13 + 7, i * 17 + 1)
		var g := _fill().position + Vector2((float(hx) + float(hz % 10) / 10.0) / 997.0 * _fill().size.x,
			(float(hy) + float(hz % 7) / 7.0) / 997.0 * _fill().size.y)
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
## While their sprites are on they sway in the plant layer instead (plant_in_layer), and the bake leaves them out.
func _shrubs(ci: CanvasItem) -> void:
	for s: Dictionary in (shrubs if not shrubs.is_empty() else shrub_spots()):
		if plant_in_layer(s):
			continue
		var g: Vector2 = s.at
		var h: int = s.seed
		var p := Iso.ground_to_screen(g).round()
		ArtKit.begin()
		# A floor shrub or flowerbed sprite set, when one exists (DecorSprites.paint_named), stands in for the
		# procedural shrub: small sets at the procedural shrub's size (live bushes and flowers draw bigger ones).
		if DecorSprites.paint_named(s.base, g, h, Vector2.ZERO):
			pass
		elif h % 5 == 0:
			# A clump of flowers in one colour, among a little green.
			PropArt.leafy(p + Vector2(0, -2), Vector2(4, 2.5), h, 5, ArtKit.OAK)
			var col: Color = FLOWERS[h % FLOWERS.size()]
			for k in 4:
				ci.draw_rect(Rect2(p + Vector2(float((h + k * 7) % 7) - 3.0, float((h + k * 3) % 4) - 5.0), Vector2(1, 1)), col)
		else:
			var r := Vector2(4.0 + float(h % 4), 3.0 + float(h % 3))
			PropArt.leafy(p + Vector2(0, -r.y * 0.6), r, h, 7, ArtKit.OAK)
		ArtKit.flush(ci)


## The floor's meadow shrubs over the house blocks, in paint order: {"base": "shrub" or "flowerbed", "at" (ground
## units), "seed"} each, on a jittered SHRUB_STEP grid, SHRUB_CHANCE of its points, on open meadow only (_fixed_zone
## 1). Deterministic; the floor bake and the plant layer both read it.
static func shrub_spots() -> Array[Dictionary]:
	var city := City.current()
	if city == _shrubs_city:
		return _shrub_spots
	_shrubs_city = city
	_shrub_spots = []
	var yards := _yards()
	var n := 0
	for d: Rect2 in city.districts():
		var nx := int(d.size.x / SHRUB_STEP)
		var ny := int(d.size.y / SHRUB_STEP)
		for j in ny:
			for i in nx:
				n += 1
				var h := _hash(n * 7 + 3, n * 13 + 11)
				if float(h % 100) / 100.0 > SHRUB_CHANCE:
					continue
				var g := d.position + (Vector2(i, j) + Vector2(0.5, 0.5)) * SHRUB_STEP \
					+ (Vector2(float(h % 17) / 17.0, float(h % 13) / 13.0) - Vector2(0.5, 0.5)) * SHRUB_STEP * 0.8
				# The house blocks lie inside the walls, where the zone does not hang on the painted meadow.
				if _fixed_zone(g, yards) != 1:
					continue
				_shrub_spots.append({"base": "flowerbed" if h % 5 == 0 else "shrub", "at": g, "seed": h})
	return _shrub_spots


## Whether a low plant sways in the plant layer (PlantLayer) rather than lying in the floor bake: while sprites are on,
## a baked REEDS / BUSH / FLOWERS piece or a floor shrub spot (shrub_spots) that has a set (DecorSprites.plant_set).
## F7 moves them between the two: the layer redraws and the floor re-bakes.
## A piece marked "under" (mark_under()) stays in the bake: a baked piece the bake paints over it would otherwise draw
## under it.
static func plant_in_layer(d: Dictionary) -> bool:
	return not d.get("under", false) and not DecorSprites.plant_set(d).is_empty() and not live_now(d)


## Whether the floor bake paints baked piece `d` now: not while the plant layer draws it (plant_in_layer), nor while
## a live stand-in does (live_now). F7 moves a piece between them: the floor re-bakes and the live node shows or hides.
static func bakes(d: Dictionary) -> bool:
	return not plant_in_layer(d) and not live_now(d)


## Whether baked piece `d` is drawn by a live sprite_only Decor now (the town stands one for each piece mark_live()
## marked): while sprites are on.
static func live_now(d: Dictionary) -> bool:
	return bool(d.get("live", false)) and SpriteArt.on()


## Mark "live" the baked pieces drawn by a live node while sprites are on (Town stands a sprite_only Decor for each),
## so an animated set's frames step: `baked` is every baked piece (trees too), back to front by x + y, as the town
## sorts them, after mark_under().
## - An animated piece (DecorSprites.animated, forced: F7 may turn sprites on later) goes live, unless mark_under()
##   marked it "under": a baked piece covers it, so it stays baked, still, at frame 0.
## - Then a live piece sits over the whole bake, so every baked piece painted after it that overlaps it goes live too
##   (a pasture's front fence over a cow's feet), and on from there: y-sort then orders them as the bake did. A piece
##   painted before it stays baked, under it, as it was. Boxes are the drawn sprites' (_live_box).
## Deterministic, from the pieces alone; the placement data is untouched (the marks live on the town's own copies).
static func mark_live(baked: Array[Dictionary]) -> void:
	var live_boxes: Array[Rect2] = []
	for d in baked:
		var box := _live_box(d)
		var live: bool = not d.get("under", false) and DecorSprites.animated(d.kind, d.seed, d.size, d.at, true)
		if not live:
			for b in live_boxes:
				if b.intersects(box):
					live = true
					break
		if live:
			d["live"] = true
			live_boxes.append(box)


## A baked piece's screen box for mark_live(): the box its sprite is drawn in while sprites are on (its set's `size`
## about its `anchor`, mirrored as paint() mirrors it, times its ArtTuning scale about the ground point; a tree's from
## its forest or town tree set), grown a px for rounding. A run (fence, bunting) or a piece with no set keeps
## _cover_box(), and a tree with no set the generous canopy TownDecor.SCREEN_BOX. Real boxes keep a tree whose crown
## stands clear of an animal out of the live cascade (draw calls), while a crown that overlaps it still goes live.
static func _live_box(d: Dictionary) -> Rect2:
	var tree: bool = d.kind == Decor.Kind.OAK or d.kind == Decor.Kind.PINE
	var s := {}
	if tree:
		s = DecorSprites.tree_set(d.kind, d.seed, (d.size as Vector2).x, true)
	elif not d.kind in DecorSprites.RUNS:
		var n := DecorSprites.name_for(d.kind, d.seed, d.size, d.at, true)
		s = DecorSprites.decor_set(n) if n != "" else {}
	var a := Iso.ground_to_screen(d.at)
	if s.is_empty():
		if tree:
			return Rect2(a + TownDecor.SCREEN_BOX.position, TownDecor.SCREEN_BOX.size)
		return _cover_box(d)
	var size: Vector2 = s.size
	var anchor: Vector2 = s.anchor
	if DecorSprites.flipped(d.kind, d.seed):
		anchor.x = size.x - anchor.x
	var sc := ArtTuning.scale(String(Decor.Kind.keys()[d.kind]).to_lower())
	return Rect2(a - anchor * sc, size * sc).grow(1.0)


## Mark each low plant in `plants` "under" (it stays in the bake, still) when the bake would paint something over it
## that the plant layer, drawn over the whole bake, would then sit under. `plants` are the shrub spots and the baked
## REEDS / BUSH / FLOWERS in bake paint order (every shrub first, then the baked pieces back to front by x + y), as
## the town passes them.
## - A baked piece of `baked` the bake paints after the plant overlaps it: a shrub under a garden plot, reeds behind a
##   moored boat or a rock. Trees and plants are no such cover: the forest layer stands over the plant layer.
## - Then, to a fixed point, an "under" plant overlaps it that the bake paints after it: in the layer the plant would
##   paint over that front plant. One pass from the front back reaches it, since a mark only spreads backwards.
## Boxes are the sprite boxes, generous (a run's or a procedural piece's whole span, raised for its height).
static func mark_under(plants: Array[Dictionary], baked: Array[Dictionary]) -> void:
	var covers: Array = []
	for o in baked:
		if o.kind in Decor.PLANTS or o.kind in [Decor.Kind.OAK, Decor.Kind.PINE]:
			continue
		covers.append([o, _cover_box(o)])
	var boxes: Array[Rect2] = []
	for p in plants:
		var box := _plant_box(p)
		boxes.append(box)
		if not box.has_area():
			continue
		var depth: float = (p.at as Vector2).x + (p.at as Vector2).y
		for c: Array in covers:
			var o: Dictionary = c[0]
			if p.has("kind") and (o.at as Vector2).x + (o.at as Vector2).y < depth:
				continue
			if box.intersects(c[1]):
				p["under"] = true
				break
	for i in range(plants.size() - 1, -1, -1):
		if not plants[i].get("under", false):
			continue
		for j in i:
			if not plants[j].get("under", false) and boxes[j].intersects(boxes[i]):
				plants[j]["under"] = true


## A low plant's screen box (its sprite's while sprites are on, a little grown for the tuned scale); empty with no set.
static func _plant_box(p: Dictionary) -> Rect2:
	var s := DecorSprites.plant_set(p, true)
	if s.is_empty():
		return Rect2()
	return Rect2(Iso.ground_to_screen(p.at) - s.anchor, s.size).grow(2.0)


## A baked piece's screen box, generously: its sprite's box when it has a still, and always its ground span raised by
## 24 px (a run, a garden plot, a procedural piece).
static func _cover_box(o: Dictionary) -> Rect2:
	var a := Iso.ground_to_screen(o.at)
	var box := Rect2(a, Vector2.ZERO).expand(Iso.ground_to_screen(o.at + o.size)).grow(4.0)
	box = box.merge(Rect2(box.position - Vector2(0, 24), Vector2(box.size.x, 24)))
	var n := DecorSprites.name_for(o.kind, o.seed, o.size, o.at, true)
	var d := DecorSprites.decor_set(n) if n != "" else {}
	if not d.is_empty() and not o.kind in DecorSprites.RUNS:
		box = box.merge(Rect2(a - d.anchor, d.size))
	return box


## Baked decor over the detail, back to front: trees, rocks, bushes, reeds and fences nothing ever stands in front of.
func _paint_decor(ci: CanvasItem) -> void:
	for d in baked_decor:
		if not bakes(d):
			continue
		# The same tuning a live Decor takes: its size about its ground point, and its colour.
		var key := String(Decor.Kind.keys()[d.kind]).to_lower()
		var sc := ArtTuning.scale(key) * float(d.get("scale", 1.0))
		var at := Iso.ground_to_screen(d.at)
		ci.draw_set_transform(at * (1.0 - sc), 0.0, Vector2(sc, sc))
		# A piece from inside the walls keeps the colour it had live (see TownDecor._bake_low()).
		ArtKit.color_mul = ArtTuning.tint(key) * (d.get("tint", Color.WHITE) as Color)
		ArtKit.begin()
		DecorArt.paint(d.kind, d.at, d.size, d.seed, Vector2.ZERO)
		ArtKit.flush(ci)
	ArtKit.color_mul = Color.WHITE
	ci.draw_set_transform(Vector2.ZERO)


## What lies at a ground point for detail: 0 nothing (water, roads, paving, trails, fields), 1 meadow,
## 2 forest floor, 3 the town's earth.
func _zone(g: Vector2) -> int:
	var z := _fixed_zone(g, _yard_rects)
	if z >= 0:
		return z
	if _zn == 0:
		return 2 if _forest(g) else 1
	var i := clampi(floori((g.x - _fill().position.x) / CELL), 0, _zn - 1)
	var j := clampi(floori((g.y - _fill().position.y) / CELL), 0, _zn - 1)
	var c := _zones[j * _zn + i]
	return 0 if c & 4 else (2 if c & 2 else 1)


## _zone() where it does not hang on the painted meadow (water, fields, roads, and everything inside the walls, with
## the house yards `yards`); -1 out in the meadow and the forest, where the painted cells decide.
static func _fixed_zone(g: Vector2, yards: Array[Rect2]) -> int:
	var geo := _geo()
	for river: Rect2 in geo.rivers:
		if river.grow(0.25).has_point(g):
			return 0
	# The water carried on past the map's edge (wet()): no tuft on it either, but for those within EDGE_KEEP of the map,
	# which may reach a px or two onto it and stay as they were.
	if not geo.map_keep.has_point(g):
		for river: Rect2 in geo.wet:
			if river.grow(0.25).has_point(g):
				return 0
	for f: Rect2 in geo.fields:
		if f.grow(0.5).has_point(g):
			return 0
	var west: Rect2 = geo.river_west
	if west.has_area() and g.x < west.end.x + 1.4 and absf(g.y - west.position.y) < 1.6:
		return 0
	for road: Rect2 in geo.roads:
		if road.grow(0.15).has_point(g):
			return 0
	if (geo.town as Rect2).has_point(g) or _paved(g):
		for open: Rect2 in geo.open:
			if open.has_point(g):
				return 0
		for plaza: Rect2 in geo.gate_plazas:
			if plaza.grow(0.3).has_point(g):
				return 0
		for y: Rect2 in yards:
			if y.has_point(g):
				return 3
		for d: Rect2 in geo.districts:
			if d.grow(-0.2).has_point(g):
				return 1
		# A lawn's tufts grow as the meadow's do, off its paths (the painted cells decide).
		for l: Rect2 in geo.lawns:
			if l.has_point(g):
				return -1
		return 0
	return -1


## The drawn area: the active city's map, FILL_MARGIN past it.
static func _fill() -> Rect2:
	return _geo().fill


## Whether `g` is on the city's extra paved ground (floor_areas() &"paved": none at Aldermere).
static func _paved(g: Vector2) -> bool:
	for r: Rect2 in _geo().paved:
		if r.has_point(g):
			return true
	return false


## The active city's ground, as the per-cell tests read it: worked out once per city (City.current()).
static func _geo() -> Dictionary:
	var city := City.current()
	if city != _geo_city:
		_geo_city = city
		var areas := city.floor_areas()
		var plazas: Array = areas.get(&"plazas", [])
		var yards: Array = areas.get(&"yards", [])
		_geo_cache = {
			town = city.town(), districts = city.districts(), rivers = city.rivers(), fields = city.fields(),
			roads = city.roads(), river = city.landmark(&"river"), river_west = city.landmark(&"river_west"),
			plazas = plazas, yards = yards, open = plazas + yards, gate_plazas = areas.get(&"gate_plazas", []),
			farm = areas.get(&"farm", []), paved = areas.get(&"paved", []), fill = city.map().grow(FILL_MARGIN),
			trails = city.trails(), road_trails = city.road_trails(), outcrops = city.outcrops(),
			rosettes = city.rosettes(), forest_gaps = city.forest_gaps(), lawns = areas.get(&"lawns", []),
			paths = areas.get(&"paths", []), outer = city.map().grow(maxf(FILL_MARGIN, city.border())),
		}
		var crossings: Array[float] = []
		for c: Rect2 in areas.get(&"crossings", []):
			crossings.append(c.get_center().x)
		_geo_cache.crossings = crossings
		_water_geo(_geo_cache)
		_geo_cache.wet = _wet_rects(city.rivers(), city.map(), _geo_cache.outer)
		_geo_cache.map_keep = city.map().grow(EDGE_KEEP)
	return _geo_cache


## The basins (the city's water besides the river and the west branch), each run on to the drawn area's edge where it
## meets the map's; their quays (basin_shores, [a, b, land normal]); and every shore a basin's water is measured from
## (shores: the quays and the river's banks, less where a basin opens off them).
static func _water_geo(geo: Dictionary) -> void:
	# The whole drawn ground: a basin meeting the map's edge runs on out through the border band.
	var fill: Rect2 = geo.outer
	var map := City.current().map()
	var river: Rect2 = geo.river
	var basins: Array[Rect2] = []
	for o: Rect2 in geo.rivers:
		if o == river or o == geo.river_west:
			continue
		var e := o
		if o.position.x <= map.position.x:
			e = e.expand(Vector2(fill.position.x, e.position.y))
		if o.end.x >= map.end.x:
			e = e.expand(Vector2(fill.end.x, e.position.y))
		if o.position.y <= map.position.y:
			e = e.expand(Vector2(e.position.x, fill.position.y))
		if o.end.y >= map.end.y:
			e = e.expand(Vector2(e.position.x, fill.end.y))
		basins.append(e)
	var band := Rect2(fill.position.x, river.position.y, fill.size.x, river.size.y)
	var quays: Array = []
	var shores: Array = []
	for e: Rect2 in basins:
		var water: Array[Rect2] = [band]
		for other: Rect2 in basins:
			if other != e:
				water.append(other)
		quays.append_array(_shores(e, fill, water))
	if not basins.is_empty():
		shores.append_array(quays)
		shores.append_array(_cut(band.position, Vector2(band.end.x, band.position.y), Vector2(0, -1), basins))
		shores.append_array(_cut(Vector2(band.position.x, band.end.y), band.end, Vector2(0, 1), basins))
	geo.basins = basins
	geo.basin_shores = quays
	geo.shores = shores


static func _near_polyline(g: Vector2, pts: Array, d: float) -> bool:
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var ab := b - a
		var t := clampf((g - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if g.distance_to(a + ab * t) < d:
			return true
	return false
