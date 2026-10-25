class_name TownMist
extends Node2D
## The mist of the DAY and NIGHT looks (Town.Look), and DAY's sunbeams. Mist lies on the ground in the places the reference
## has it: the forest ring at the map's edge, the river and harbour water. It never covers the town (zones() leaves out
## the walled core), and it sits in the ground plane above the floor, the plants, the forest and the shadows but under
## everything that stands, so it cannot hide a person, a building or a tag. One Polygon2D per zone, drawn by
## town_mist.gdshader: drifting noise snapped to world pixels and cut into three alpha steps. The sunbeams (DAY only) are
## slanted stripes from the upper left, each a few nested pale parallelograms, so their edges are stepped.

## The mist keeps this far off the walls (ground units), then thickens over RING_FADE more.
const KEEP_PAD := 1.0
const RING_FADE := 8.0
## Water zones: the band grown past the water, and how far in from its edges the mist thickens.
const BANK_BAND := 1.2
const WATER_FADE := 0.8
const WATER_ALPHA := 0.6
## The sunbeams light open ground only: they lie in the ground plane with the mist (z 0, under everything that stands), so
## buildings, people and tags are never covered. Each of a stripe's three nested steps adds up to BEAM_MAX_ALPHA.
const BEAM_MAX_ALPHA := 0.14
const BEAM_Z := 0
## DAY mist starts lower (town_mist.gdshader floor_level; NIGHT keeps the shader's 0.28), so it is thicker.
const DAY_FLOOR := 0.16

var look := 0
var _beams: Array[Polygon2D] = []
var _polys: Array[Polygon2D] = []


## The ground rects the ring mist keeps off, in ground units: the town and any paved ground the city treats as inside
## its walls (the capital's second wall ring), each grown by KEEP_PAD.
static func keep_outs() -> Array[Rect2]:
	var city := City.current()
	var out: Array[Rect2] = [city.town().grow(KEEP_PAD)]
	var paved: Array = city.floor_areas().get(&"paved", [])
	for r: Rect2 in paved:
		out.append(r.grow(KEEP_PAD))
	return out


## The water of the active city (rivers and the harbour basin), each run on out through the border band where it meets the
## map's edge, as the floor draws it.
static func water_rects() -> Array[Rect2]:
	var city := City.current()
	var map := city.map()
	var outer := map.grow(city.border())
	var out: Array[Rect2] = []
	for o: Rect2 in city.rivers():
		var e := o
		if o.position.x <= map.position.x:
			e = e.expand(Vector2(outer.position.x, e.position.y))
		if o.end.x >= map.end.x:
			e = e.expand(Vector2(outer.end.x, e.position.y))
		if o.position.y <= map.position.y:
			e = e.expand(Vector2(e.position.x, outer.position.y))
		if o.end.y >= map.end.y:
			e = e.expand(Vector2(e.position.x, outer.end.y))
		out.append(e)
	return out


## The mist of the active city, tagged: {rect, kind}, in ground units. Ring pieces tile the map and its border band round
## the town, thickening with the distance from the walls (keep_outs(), in the shader), and leave out all open water
## (water_rects()). Water pieces are thin bands that hug the banks (BANK_BAND wide), also off the water. All are cut to
## leave out the town rect (City.current().town()).
static func tagged_zones() -> Array[Dictionary]:
	var city := City.current()
	var town := city.town()
	var map := city.map()
	var outer := map.grow(city.border())
	var water := water_rects()
	var pieces: Array[Dictionary] = [{"rect": outer, "kind": &"ring"}]
	for w: Rect2 in water:
		pieces.append({"rect": w.grow(BANK_BAND).intersection(outer), "kind": &"water"})
	var out: Array[Dictionary] = []
	for p in pieces:
		var r: Rect2 = p.rect
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			continue
		var parts: Array[Rect2] = [r]
		var cuts: Array[Rect2] = [town]
		cuts.append_array(water)
		for c in cuts:
			var next: Array[Rect2] = []
			for part in parts:
				next.append_array(_minus(part, c))
			parts = next
		for part in parts:
			if part.has_area():
				out.append({"rect": part, "kind": p.kind})
	return out


## The rects of the mist (tagged_zones()): none touches the town rect. `_town` is the town being built; the active
## city answers.
static func zones(_town: Town = null) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for z in tagged_zones():
		out.append(z.rect)
	return out


## `r` without `cut`: up to four rects that tile what remains.
static func _minus(r: Rect2, cut: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if not r.intersects(cut):
		out.append(r)
		return out
	var c := r.intersection(cut)
	if c.position.y > r.position.y:
		out.append(Rect2(r.position, Vector2(r.size.x, c.position.y - r.position.y)))
	if c.end.y < r.end.y:
		out.append(Rect2(Vector2(r.position.x, c.end.y), Vector2(r.size.x, r.end.y - c.end.y)))
	if c.position.x > r.position.x:
		out.append(Rect2(Vector2(r.position.x, c.position.y), Vector2(c.position.x - r.position.x, c.size.y)))
	if c.end.x < r.end.x:
		out.append(Rect2(Vector2(c.end.x, c.position.y), Vector2(r.end.x - c.end.x, c.size.y)))
	return out


## DAY mist: a pale warm haze. NIGHT mist: thinner, a grey blue light enough to survive the grade.
static func mist_colour(look_value) -> Color:
	if look_value == Town.Look.NIGHT:
		return Color(0.62, 0.72, 0.90, 0.20)
	return Color(0.98, 0.93, 0.80, 0.46)


func setup(look_value) -> TownMist:
	name = "Mist"
	look = look_value
	# Drawn in screen pixels on the ground plane, as the shadows are.
	transform = Iso.BASIS.affine_inverse()
	var keeps := keep_outs()
	for z in tagged_zones():
		var r: Rect2 = z.rect
		var poly := Polygon2D.new()
		poly.name = "Mist_%s" % String(z.kind)
		poly.polygon = PackedVector2Array([Iso.ground_to_screen(r.position), Iso.ground_to_screen(Vector2(r.end.x, r.position.y)),
			Iso.ground_to_screen(r.end), Iso.ground_to_screen(Vector2(r.position.x, r.end.y))])
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://src/game/town/town_mist.gdshader")
		var col := mist_colour(look_value)
		# Over water the ring's mist already lies: the water zone adds only a thin extra haze.
		if z.kind == &"water":
			col.a *= WATER_ALPHA
		mat.set_shader_parameter("mist_col", col)
		if look_value == Town.Look.DAY:
			# Thick, soft-edged volumes, dithered (town_mist.gdshader dither), lying lower so more of the ring is in them.
			mat.set_shader_parameter("dither", 1.0)
			mat.set_shader_parameter("floor_level", DAY_FLOOR)
		if z.kind == &"ring":
			for i in mini(keeps.size(), 2):
				var k: Rect2 = keeps[i]
				mat.set_shader_parameter("keep_out" if i == 0 else "keep_out2", Vector4(k.position.x, k.position.y, k.size.x, k.size.y))
			mat.set_shader_parameter("fade", RING_FADE)
		else:
			mat.set_shader_parameter("zone", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
			mat.set_shader_parameter("edge_fade", WATER_FADE)
		poly.material = mat
		add_child(poly)
		_polys.append(poly)
	if look_value == Town.Look.DAY:
		_add_beams(City.current().town())
	return self


## Slanted stripes of sun from the upper left across the town (screen px, world-space), on the same stripes the grade
## draws outside the walls (TownLook.beam_stripe()), so a beam runs on from the forest into the town: three nested pale
## parallelograms each, so a stripe has a bright core and two stepped edges. They span the town's diamond top to bottom.
func _add_beams(town_rect: Rect2) -> void:
	var holder := Node2D.new()
	holder.name = "Beams"
	add_child(holder)
	var c := TownLook.beam_origin()
	var top := Iso.ground_to_screen(town_rect.position).y
	var bottom := Iso.ground_to_screen(town_rect.end).y
	var left := Iso.ground_to_screen(Vector2(town_rect.position.x, town_rect.end.y)).x
	var right := Iso.ground_to_screen(Vector2(town_rect.end.x, town_rect.position.y)).x
	var y0 := top
	var length := bottom - top
	var slant := TownLook.BEAM_SLANT
	var widths := [1.0, 0.62, 0.30]
	var diamond := PackedVector2Array([Iso.ground_to_screen(town_rect.position),
		Iso.ground_to_screen(Vector2(town_rect.end.x, town_rect.position.y)), Iso.ground_to_screen(town_rect.end),
		Iso.ground_to_screen(Vector2(town_rect.position.x, town_rect.end.y))])
	# Every stripe whose band crosses the town's screen box somewhere between its top and bottom.
	var n0 := floori((left - c.x - (bottom - c.y) * slant) / TownLook.BEAM_PERIOD) - 1
	var n1 := ceili((right - c.x - (top - c.y) * slant) / TownLook.BEAM_PERIOD) + 1
	for n in range(n0, n1 + 1):
		var st := TownLook.beam_stripe(n)
		# The stripe's centre on the line y = y0: u = x - c.x - (y0 - c.y) * slant.
		var x0: float = st.x + c.x + (y0 - c.y) * slant
		var half: float = st.y * 0.8
		for k in 3:
			var w: float = half * widths[k]
			var quad := PackedVector2Array([Vector2(x0 - w, y0), Vector2(x0 + w, y0),
				Vector2(x0 + w + length * slant, y0 + length), Vector2(x0 - w + length * slant, y0 + length)])
			# Cut to the town's diamond: outside it the grade draws the beam.
			for piece in Geometry2D.intersect_polygons(quad, diamond):
				for j in piece.size():
					piece[j] = piece[j].round()
				var poly := Polygon2D.new()
				poly.name = "Beam%d_%d" % [n - n0, k]
				poly.polygon = piece
				poly.color = Color(1.0, 0.94, 0.74, BEAM_MAX_ALPHA)
				holder.add_child(poly)
				_beams.append(poly)


func zone_count() -> int:
	return _polys.size()


func beams() -> Array[Polygon2D]:
	return _beams


func beam_count() -> int:
	return _beams.size()
