class_name CivicArt
extends RefCounted
## The Temple and the barracks, after concepts/TOWN REF/Town Visual Upgrade.png; the Scale reference's cathedral
## (tag &"cathedral") adds carved pinnacles on its front and buttress piers along its nave, and its workshop hall
## (a house tagged &"workshop") is an open timber pavilion.
## - Temple: sandstone blocks under a teal seamed roof. Pointed windows glow along its long wall. Its gable end is
##   a west front that hides the roof end, with a bell turret, a great banner, two small ones, and an arched door
##   up three steps.
## - Barracks: an open shed under red tile on stone pillars. Racks, tables and barrels stand in the dark inside,
##   a stone gable closes the far end, and a forge chimney with a glowing furnace stands at the east corner.
## Colours are unlit: the structure's shader lights them (see ArtKit).

const TEMPLE_RISE := 30.0
const BARRACKS_RISE := 16.0
const OVERHANG := 0.12
const DROP := 3.0
const BOARD := 2.0
## The barracks forge chimney: its ground square and how far it stands above the ridge.
## Where along the barracks the main roof stops and the lower lean-to over its east end begins.
const LEAN_AT := 0.78
const FORGE_SIDE := 0.5
const FORGE_UP := 18.0


static func plan(s: Structure) -> Dictionary:
	if s.kind == Structure.Kind.BARRACKS:
		var r := s.footprint
		return {"forge": Rect2(r.end - Vector2(FORGE_SIDE, FORGE_SIDE), Vector2(FORGE_SIDE, FORGE_SIDE))}
	return {"turret_left": true}


static func draw(s: Structure) -> void:
	if s.kind == Structure.Kind.TEMPLE:
		_temple(s)
	else:
		_barracks(s)


## Flicker spots for the structure's flame node (structure-local px): the forge's furnace mouth.
static func flame_tips(s: Structure) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if s.kind == Structure.Kind.BARRACKS:
		var f: Rect2 = s.art.forge
		out.append(s._gp(Vector2(f.get_center().x, f.end.y), 0.0) + Vector2(0, -2))
	return out


# --- Temple ------------------------------------------------------------------

static func _temple(s: Structure) -> void:
	ArtKit.begin()
	var h := s.height
	var r := s.footprint
	var ax := r.size.x >= r.size.y
	var eave_face := ArtKit.LEFT if ax else ArtKit.RIGHT
	var front_face := ArtKit.RIGHT if ax else ArtKit.LEFT
	var stone := {ArtKit.RIGHT: ArtKit.SANDSTONE[0], ArtKit.LEFT: ArtKit.SANDSTONE[1]}
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		ArtKit.masonry(s, face, 0.0, h, stone[face], 7, 5.0, 10.0, 0.0, 1.0, 0.2)
	ArtKit.face_quad(s, eave_face, 0.0, 1.0, h - DROP - BOARD - 4.0, h, (stone[eave_face] as Color).darkened(0.3))
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		ArtKit.mortar_lines(s, face, 0.0, h, 5.0)
		ArtKit.face_line(s, face, 0.0, 0.0, 1.0, 0.0, ArtKit.ink(0.6))
	ArtKit.flush(s)

	# Roof: ridge along the long side, no overhang at the west front (the front covers the roof end).
	var g := _roof(s, ax, TEMPLE_RISE, true)
	_roof_back(g, ArtKit.TEAL)
	ArtKit.flush(s)
	_roof_front(s, g, ArtKit.TEAL, 8.0, false)
	ArtKit.flush(s)

	# West front: the gable wall rises to a point that follows the roof line, with a coping along both rakes and a
	# small grey bell block on its far corner, as in the reference.
	var top: float = g.top
	var peak := top + 3.0
	var fc: Color = stone[front_face]
	var fcode := ArtKit.face_code(front_face)
	ArtKit.face_quad(s, front_face, 0.0, 1.0, h - 1.0, h + 1.0, fc)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, front_face, 0.0, h), ArtKit.face_pt(s, front_face, 1.0, h),
		ArtKit.face_pt(s, front_face, 0.5, peak)]), fc.darkened(0.3), fcode)
	var rows := ceili((peak - h) / 5.0)
	for row in rows:
		var y0 := h + row * 5.0
		var y1 := minf(y0 + 5.0, peak)
		var f := 1.0 - (y1 - h) / (peak - h)
		if f > 0.04:
			ArtKit.masonry(s, front_face, y0, y1, fc, 91 + row * 7, 5.0, 10.0, 0.5 - f * 0.5, 0.5 + f * 0.5, 0.2)
	var cope := fc.lightened(0.16)
	for side in [0.0, 1.0]:
		ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, front_face, side, h - 1.0),
			ArtKit.face_pt(s, front_face, 0.5, peak + 1.0), ArtKit.face_pt(s, front_face, 0.5, peak - 3.0),
			ArtKit.face_pt(s, front_face, side, h - 4.0)]), cope, fcode)
		ArtKit.line(ArtKit.face_pt(s, front_face, side, h - 1.0), ArtKit.face_pt(s, front_face, 0.5, peak + 1.0),
			ArtKit.ink(0.5))
	ArtKit.flush(s)
	if s.art_tag == &"cathedral":
		_pinnacles(s, front_face, top)
	else:
		_turret(s, front_face, h)
	ArtKit.flush(s)

	# The long wall's pointed windows and side door; the west front's door, steps and banners.
	var cathedral := s.art_tag == &"cathedral"
	var sill := roundf(h * (0.22 if cathedral else 0.3))
	var tall := minf(roundf(h * (0.42 if cathedral else 0.3)), h - sill - DROP - BOARD - 8.0)
	var n := 0
	# The cathedral's windows sit between its buttress piers, taller and wider.
	var spots: Array = [0.14, 0.33, 0.52, 0.71, 0.9] if cathedral else [0.14, 0.33, 0.52, 0.7]
	for u in spots:
		_pointed_window(s, eave_face, u, sill, 7.0 if cathedral else 5.0, tall, _lit(s, n) or cathedral)
		n += 1
	if not cathedral:
		_door(s, eave_face, 0.87, 5.0, 10.0, false)
	var arch := roundf(h * 0.3)
	_door(s, front_face, 0.5, 9.0, arch, true)
	_banner(s, front_face, 0.5, h + 6.0, 11.0, 24.0)
	_banner(s, front_face, 0.2, arch + 3.0, 6.0, 11.0)
	_banner(s, front_face, 0.8, arch + 3.0, 6.0, 11.0)
	# Lancets either side of the great banner.
	_pointed_window(s, front_face, 0.3, h - 14.0, 3.0, 9.0, _lit(s, n))
	_pointed_window(s, front_face, 0.7, h - 14.0, 3.0, 9.0, _lit(s, n + 1))
	ArtKit.flush(s)


## The cathedral's front: a slender pinnacle tower at each corner of the west front, rising past the ridge to a
## spire with a gold finial, and between the nave's windows, buttress piers stepping out of the long wall.
static func _pinnacles(s: Structure, front_face: int, roof_top: float) -> void:
	var r := s.footprint
	var ax := r.size.x >= r.size.y
	var side := 0.4
	var eave_face := ArtKit.RIGHT if front_face == ArtKit.LEFT else ArtKit.LEFT
	# Buttresses first: they stand against the long wall, behind the front's pinnacles on screen.
	var h := s.height
	for u: float in [0.235, 0.425, 0.615, 0.805]:
		var g: Vector2
		var lo: Vector2
		var hi: Vector2
		if eave_face == ArtKit.RIGHT:
			g = Vector2(r.end.x, lerpf(r.position.y, r.end.y, u))
			lo = g + Vector2(0.0, -0.13)
			hi = g + Vector2(0.28, 0.13)
		else:
			g = Vector2(lerpf(r.position.x, r.end.x, u), r.end.y)
			lo = g + Vector2(-0.13, 0.0)
			hi = g + Vector2(0.13, 0.28)
		var top := h - 6.0
		PropArt._box(s, lo, hi, 0.0, top, ArtKit.SANDSTONE[1].lightened(0.04), ArtKit.SANDSTONE[0].lightened(0.06),
			ArtKit.SANDSTONE[0].lightened(0.12))
		# A sloped cap leaning back to the wall.
		var gl := Vector2(lo.x, hi.y)
		var gr := Vector2(hi.x, lo.y)
		var back_l := gl if eave_face == ArtKit.LEFT else lo
		var wall_pt := s._gp(g, top + 6.0)
		ArtKit.poly(PackedVector2Array([s._gp(gl, top), s._gp(hi, top), s._gp(gr, top), wall_pt]),
			ArtKit.SANDSTONE[0].lightened(0.14), ArtKit.LIT_TOP)
		ArtKit.line(s._gp(hi, 0.0), s._gp(hi, top), ArtKit.ink(0.3))
		ArtKit.line(s._gp(back_l, 0.0), s._gp(back_l, top), ArtKit.ink(0.35))
	ArtKit.flush(s)
	# The front's two corners, far one first.
	var corners: Array[Rect2] = []
	if ax:
		corners = [Rect2(Vector2(r.end.x - side, r.position.y), Vector2(side, side)),
			Rect2(r.end - Vector2(side, side), Vector2(side, side))]
	else:
		corners = [Rect2(Vector2(r.position.x, r.end.y - side), Vector2(side, side)),
			Rect2(r.end - Vector2(side, side), Vector2(side, side))]
	for c in corners:
		_pinnacle(s, c, roof_top + 2.0)


## One pinnacle over the ground square `g`: carved sandstone up to `top`, a four-sided spire above it.
static func _pinnacle(s: Structure, g: Rect2, top: float) -> void:
	var g0 := g.position
	var g1 := g.end
	var gl := Vector2(g0.x, g1.y)
	var gr := Vector2(g1.x, g0.y)
	_box_masonry(s, gl, g1, 0.0, top, ArtKit.SANDSTONE[1], ArtKit.LIT_LEFT, 260)
	_box_masonry(s, gr, g1, 0.0, top, ArtKit.SANDSTONE[0], ArtKit.LIT_RIGHT, 280)
	ArtKit.poly(PackedVector2Array([s._gp(g0, top), s._gp(gr, top), s._gp(g1, top), s._gp(gl, top)]),
		ArtKit.SANDSTONE[0].lightened(0.1), ArtKit.LIT_TOP)
	# Carved bands and niches.
	for hh: float in [top * 0.35, top * 0.7]:
		ArtKit.poly(PackedVector2Array([s._gp(gl, hh), s._gp(g1, hh), s._gp(g1, hh + 2.0), s._gp(gl, hh + 2.0)]),
			ArtKit.SANDSTONE[0].lightened(0.12), ArtKit.LIT_LEFT)
		ArtKit.poly(PackedVector2Array([s._gp(gr, hh), s._gp(g1, hh), s._gp(g1, hh + 2.0), s._gp(gr, hh + 2.0)]),
			ArtKit.SANDSTONE[0].lightened(0.18), ArtKit.LIT_RIGHT)
	var nl := gl.lerp(g1, 0.5)
	ArtKit.poly(PackedVector2Array([s._gp(nl, top * 0.75) + Vector2(-1, 0), s._gp(nl, top * 0.75) + Vector2(1, 0),
		s._gp(nl, top * 0.9) + Vector2(1, 0), s._gp(nl, top * 0.9) + Vector2(-1, 0)]), ArtKit.VOID, ArtKit.EMIT)
	# The spire: four faces to a point, the two the camera sees lit and shaded, a gold finial on top.
	var tip := s._gp(g.get_center(), top + 18.0)
	ArtKit.poly(PackedVector2Array([s._gp(gl, top), s._gp(g1, top), tip]), ArtKit.SANDSTONE[1].darkened(0.1), ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(gr, top), s._gp(g1, top), tip]), ArtKit.SANDSTONE[0], ArtKit.LIT_RIGHT)
	ArtKit.line(s._gp(g1, top), tip, ArtKit.ink(0.35))
	ArtKit.poly(PackedVector2Array([tip + Vector2(-1, -1), tip + Vector2(1, -1), tip + Vector2(1, 1), tip + Vector2(-1, 1)]),
		Structure.COL_GOLD, ArtKit.EMIT)
	ArtKit.line(s._gp(gl, 0.0), s._gp(gl, top), ArtKit.ink(0.5))
	ArtKit.line(s._gp(gr, 0.0), s._gp(gr, top), ArtKit.ink(0.4))


## A small grey stone bell block on the front's far corner, open for its bell.
static func _turret(s: Structure, front_face: int, base_h: float) -> void:
	var r := s.footprint
	var side := 0.34
	var ax := r.size.x >= r.size.y
	# Far corner of the front: the front runs along the +y wall (x from pos.x) or the +x wall (y from pos.y).
	var g0 := Vector2(r.position.x, r.end.y - side) if not ax else Vector2(r.end.x - side, r.position.y)
	var g1 := g0 + Vector2(side, side)
	var h1 := base_h + 11.0
	var gl := Vector2(g0.x, g1.y)
	var gr := Vector2(g1.x, g0.y)
	ArtKit.poly(PackedVector2Array([s._gp(gl, base_h), s._gp(g1, base_h), s._gp(g1, h1), s._gp(gl, h1)]),
		ArtKit.STONE[1], ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(gr, base_h), s._gp(g1, base_h), s._gp(g1, h1), s._gp(gr, h1)]),
		ArtKit.STONE[0], ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([s._gp(g0, h1), s._gp(gr, h1), s._gp(g1, h1), s._gp(gl, h1)]),
		ArtKit.STONE_TOP, ArtKit.LIT_TOP)
	# Bell openings on both visible sides, and a dark mouth on top.
	for side_pts in [[gl, g1], [gr, g1]]:
		var a: Vector2 = side_pts[0]
		var b: Vector2 = side_pts[1]
		var m0 := a.lerp(b, 0.3)
		var m1 := a.lerp(b, 0.7)
		ArtKit.poly(PackedVector2Array([s._gp(m0, h1 - 9.0), s._gp(m1, h1 - 9.0), s._gp(m1, h1 - 4.0),
			s._gp(m0, h1 - 4.0)]), ArtKit.VOID, ArtKit.EMIT)
	var c := (g0 + g1) * 0.5
	var i0 := g0.lerp(c, 0.4)
	var i1 := g1.lerp(c, 0.4)
	ArtKit.poly(PackedVector2Array([s._gp(i0, h1), s._gp(Vector2(i1.x, i0.y), h1), s._gp(i1, h1),
		s._gp(Vector2(i0.x, i1.y), h1)]), ArtKit.VOID, ArtKit.INK)
	for e in [[gl, g1], [g1, gr]]:
		ArtKit.line(s._gp(e[0], h1), s._gp(e[1], h1), ArtKit.ink(0.2, true))
	ArtKit.line(s._gp(g1, base_h), s._gp(g1, h1), ArtKit.ink(0.15, true))


## A tall pointed window: a dark stone surround, glowing glass (or dark), a pointed head and a mullion.
static func _pointed_window(s: Structure, face: int, u: float, sill: float, w: float, tall: float, lit: bool) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var du := w * 0.5 / px
	var fu := 1.0 / px
	var frame := ArtKit.SANDSTONE[1].darkened(0.45)
	ArtKit.face_quad(s, face, u - du - fu, u + du + fu, sill - 1.0, sill + tall, frame)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, face, u - du - fu, sill + tall),
		ArtKit.face_pt(s, face, u + du + fu, sill + tall), ArtKit.face_pt(s, face, u, sill + tall + w * 0.5 + 2.0)]),
		frame, ArtKit.face_code(face))
	var glass := ArtKit.GLOW_RIM if lit else ArtKit.WINDOW_OFF
	var code := ArtKit.EMIT if lit else ArtKit.face_code(face)
	ArtKit.face_quad(s, face, u - du, u + du, sill, sill + tall, glass, code)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, face, u - du, sill + tall),
		ArtKit.face_pt(s, face, u + du, sill + tall), ArtKit.face_pt(s, face, u, sill + tall + w * 0.5)]), glass, code)
	if lit:
		ArtKit.face_quad(s, face, u - du + fu, u + du - fu * 0.5, sill + 1.0, sill + tall - 1.0, ArtKit.GLOW, ArtKit.EMIT)
	ArtKit.face_line(s, face, u, sill, u, sill + tall, ArtKit.ink(0.6))
	ArtKit.face_line(s, face, u - du, sill + tall * 0.55, u + du, sill + tall * 0.55, ArtKit.ink(0.5))


## An arched door (dark mouth, lighter jambs) `w` px wide and `tall` px high; `steps` adds three steps before it.
static func _door(s: Structure, face: int, u: float, w: float, tall: float, steps: bool) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var du := w * 0.5 / px
	var fu := 1.0 / px
	var base := 3.0 if steps else 0.0
	var jamb := ArtKit.SANDSTONE[0].lightened(0.1)
	ArtKit.face_quad(s, face, u - du - 2.0 * fu, u + du + 2.0 * fu, base, base + tall, jamb)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, face, u - du - 2.0 * fu, base + tall),
		ArtKit.face_pt(s, face, u + du + 2.0 * fu, base + tall), ArtKit.face_pt(s, face, u, base + tall + w * 0.5 + 3.0)]),
		jamb, ArtKit.face_code(face))
	if steps:
		ArtKit.face_quad(s, face, u - du, u + du, base, base + tall, ArtKit.VOID, ArtKit.EMIT)
		ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, face, u - du, base + tall),
			ArtKit.face_pt(s, face, u + du, base + tall), ArtKit.face_pt(s, face, u, base + tall + w * 0.5)]),
			ArtKit.VOID, ArtKit.EMIT)
		for k in 3:
			var grow := (3.0 - k) * 2.0 / px
			ArtKit.face_quad(s, face, u - du - grow, u + du + grow, k, k + 1.0, ArtKit.STONE[0].lightened(0.1 - k * 0.04))
	else:
		ArtKit.face_quad(s, face, u - du, u + du, 0.0, tall, ArtKit.DOOR[0])
		ArtKit.face_line(s, face, u, 0.0, u, tall, ArtKit.ink(0.4))


## A still banner on a wall: blue with a white cross, gold rod, swallowtail foot. `top` is the rod's height.
static func _banner(s: Structure, face: int, u: float, top: float, w: float, length: float) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var du := w * 0.5 / px
	var code := ArtKit.face_code(face)
	var bot := top - length + 4.0
	var p := func(uu: float, hh: float) -> Vector2: return ArtKit.face_pt(s, face, uu, hh)
	ArtKit.poly(PackedVector2Array([p.call(u - du, top), p.call(u + du, top), p.call(u + du, bot), p.call(u - du, bot)]),
		ArtKit.BANNER[0], code)
	ArtKit.poly(PackedVector2Array([p.call(u - du, bot), p.call(u, bot), p.call(u - du, bot - 4.0)]), ArtKit.BANNER[0], code)
	ArtKit.poly(PackedVector2Array([p.call(u, bot), p.call(u + du, bot), p.call(u + du, bot - 4.0)]), ArtKit.BANNER[0], code)
	ArtKit.poly(PackedVector2Array([p.call(u - du, top), p.call(u - du + 1.0 / px, top), p.call(u - du + 1.0 / px, bot),
		p.call(u - du, bot)]), ArtKit.BANNER[1], code)
	var arm := minf(3.0, w * 0.5 - 1.0) / px
	var cy := top - 3.0
	var cl := minf(length - 8.0, 10.0)
	ArtKit.poly(PackedVector2Array([p.call(u - 1.0 / px, cy), p.call(u + 1.0 / px, cy), p.call(u + 1.0 / px, cy - cl),
		p.call(u - 1.0 / px, cy - cl)]), ArtKit.BANNER[2], code)
	ArtKit.poly(PackedVector2Array([p.call(u - arm, cy - 3.0), p.call(u + arm, cy - 3.0), p.call(u + arm, cy - 5.0),
		p.call(u - arm, cy - 5.0)]), ArtKit.BANNER[2], code)
	ArtKit.poly(PackedVector2Array([p.call(u - du - 1.0 / px, top + 1.0), p.call(u + du + 1.0 / px, top + 1.0),
		p.call(u + du + 1.0 / px, top), p.call(u - du - 1.0 / px, top)]), Structure.COL_GOLD, code)


# --- Barracks ------------------------------------------------------------------

static func _barracks(s: Structure) -> void:
	ArtKit.begin()
	var h := s.height
	var r := s.footprint
	var ax := r.size.x >= r.size.y
	var open_face := ArtKit.LEFT if ax else ArtKit.RIGHT
	var end_face := ArtKit.RIGHT if ax else ArtKit.LEFT
	var px := maxf(ArtKit.face_px(s, open_face), 1.0)
	# The open front: dark inside, a lit floor, then what stands in the dark.
	ArtKit.face_quad(s, open_face, 0.0, 1.0, 0.0, h, ArtKit.INTERIOR)
	ArtKit.face_quad(s, open_face, 0.0, 1.0, 0.0, 3.0, ArtKit.INTERIOR_FLOOR)
	var bays := 4
	var pillar := 6.0 / px
	for b in bays:
		var u0 := float(b) / bays + pillar
		var u1 := float(b + 1) / bays
		var mid := (u0 + u1) * 0.5
		var span := u1 - u0
		# A table with a lamp glow, a weapon rack and a barrel in each bay, shuffled by the seed.
		var shift := (ArtKit.hash01(s.rng.seed, 70 + b) - 0.5) * span * 0.3
		var t0 := mid - span * 0.28 + shift
		var t1 := mid + span * 0.05 + shift
		ArtKit.face_quad(s, open_face, t0, t1, 5.0, 7.0, ArtKit.WOOD[1])
		ArtKit.face_quad(s, open_face, t0, t0 + 1.0 / px, 2.0, 5.0, ArtKit.WOOD[2])
		ArtKit.face_quad(s, open_face, t1 - 1.0 / px, t1, 2.0, 5.0, ArtKit.WOOD[2])
		var bx := mid + span * 0.22
		ArtKit.face_quad(s, open_face, bx - 2.0 / px, bx + 2.0 / px, 2.0, 7.0, ArtKit.WOOD[1])
		ArtKit.face_quad(s, open_face, bx - 2.0 / px, bx + 2.0 / px, 4.0, 5.0, ArtKit.IRON)
		ArtKit.face_quad(s, open_face, t0 + span * 0.1, t0 + span * 0.1 + 2.0 / px, 7.0, 9.0, ArtKit.GLOW_RIM, ArtKit.EMIT)
	ArtKit.face_quad(s, open_face, 0.0, 1.0, h - 5.0, h, ArtKit.TIMBER)
	ArtKit.face_quad(s, open_face, 0.0, 1.0, h - 7.0, h - 5.0, ArtKit.INTERIOR.darkened(0.3))
	# Stone pillars, including one at each end.
	for b in bays + 1:
		var u := float(b) / bays
		var u0 := clampf(u - pillar * 0.5, 0.0, 1.0)
		var u1 := clampf(u + pillar * 0.5, 0.0, 1.0)
		if b == 0:
			u1 = pillar
		elif b == bays:
			u0 = 1.0 - pillar * 0.6
		ArtKit.masonry(s, open_face, 0.0, h - 5.0, ArtKit.STONE[1], 30 + b, 5.0, 6.0, u0, u1, 0.24)
	ArtKit.masonry(s, end_face, 0.0, h, ArtKit.STONE[0], 50, 5.0, 10.0)
	# Spears on the racks: thin shafts with bright heads.
	for b in bays:
		var u := (float(b) + 0.5) / bays - 0.08
		for k in 3:
			var su := u + k * 2.0 / px
			ArtKit.face_line(s, open_face, su, 3.0, su, 16.0, Color(0.55, 0.4, 0.25, 0.9))
			ArtKit.face_line(s, open_face, su, 16.0, su, 18.0, Color(0.85, 0.85, 0.8, 0.9))
	ArtKit.mortar_lines(s, end_face, 0.0, h, 5.0)
	ArtKit.face_line(s, end_face, 0.0, 0.0, 1.0, 0.0, ArtKit.ink(0.6))
	ArtKit.flush(s)

	# The main roof over most of the length, and a lower lean-to over the east end, as in the reference.
	var a_lo: float = (r.position.x if ax else r.position.y) - OVERHANG
	var a_hi: float = (r.end.x if ax else r.end.y) + OVERHANG
	var a_split: float = lerpf(r.position.x if ax else r.position.y, r.end.x if ax else r.end.y, LEAN_AT)
	var g := _roof_span(s, ax, BARRACKS_RISE, a_lo, a_split, 0.0)
	var lean := _roof_span(s, ax, BARRACKS_RISE * 0.55, a_split, a_hi, 3.0)
	_roof_back(g, ArtKit.RED_TILE)
	_roof_back(lean, ArtKit.RED_TILE)
	var gc: Color = ArtKit.STONE[0]
	var gcode := ArtKit.face_code(end_face)
	# The main roof's stone gable where it steps down to the lean-to.
	var b0: float = r.position.y if ax else r.position.x
	var b1: float = r.end.y if ax else r.end.x
	var bm: float = (b0 + b1) * 0.5
	ArtKit.poly(PackedVector2Array([s._gp(_g(ax, a_split, b0), h), s._gp(_g(ax, a_split, b1), h),
		s._gp(_g(ax, a_split, b1), g.shoulder), s._gp(_g(ax, a_split, b0), g.shoulder)]), gc, gcode)
	ArtKit.poly(PackedVector2Array([s._gp(_g(ax, a_split, b0), g.shoulder), s._gp(_g(ax, a_split, b1), g.shoulder),
		s._gp(_g(ax, a_split, bm), g.top)]), gc, gcode)
	ArtKit.flush(s)
	_roof_front(s, g, ArtKit.RED_TILE, 4.0, true)
	ArtKit.flush(s)
	# The lean-to's gable on the end wall, then its own front slope.
	ArtKit.face_quad(s, end_face, 0.0, 1.0, h, lean.shoulder, gc)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, end_face, 0.0, lean.shoulder),
		ArtKit.face_pt(s, end_face, 1.0, lean.shoulder), ArtKit.face_pt(s, end_face, 0.5, lean.top)]), gc, gcode)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, end_face, 0.0, lean.shoulder), ArtKit.face_pt(s, end_face, 0.5, lean.top),
		ArtKit.face_pt(s, end_face, 0.5, lean.top - 3.0), ArtKit.face_pt(s, end_face, 0.0, lean.shoulder - 3.0)]),
		gc.darkened(0.3), gcode)
	ArtKit.flush(s)
	_roof_front(s, lean, ArtKit.RED_TILE, 4.0, true)
	ArtKit.flush(s)
	_forge(s, g.top)
	ArtKit.flush(s)


## The forge chimney at the barracks' east corner: stone up past the roof, a glowing furnace mouth at its foot.
static func _forge(s: Structure, roof_top: float) -> void:
	var f: Rect2 = s.art.forge
	var g0 := f.position
	var g1 := f.end
	var gl := Vector2(g0.x, g1.y)
	var gr := Vector2(g1.x, g0.y)
	var top := roof_top + FORGE_UP
	var dark := [ArtKit.STONE[0].darkened(0.15), ArtKit.STONE[1].darkened(0.15)]
	_box_masonry(s, gl, g1, 0.0, top, dark[1], ArtKit.LIT_LEFT, 170)
	_box_masonry(s, gr, g1, 0.0, top, dark[0], ArtKit.LIT_RIGHT, 190)
	# A narrower stack above the firebox.
	var inset := 0.14
	var s0 := g0 + Vector2(inset, inset)
	var s1 := g1 - Vector2(inset * 0.5, inset * 0.5)
	var neck := top - 14.0
	for face_pts in [[Vector2(s0.x, s1.y), s1, dark[1], ArtKit.LIT_LEFT], [Vector2(s1.x, s0.y), s1, dark[0], ArtKit.LIT_RIGHT]]:
		var a: Vector2 = face_pts[0]
		var b: Vector2 = face_pts[1]
		ArtKit.poly(PackedVector2Array([s._gp(a, top), s._gp(b, top), s._gp(b, top + 8.0), s._gp(a, top + 8.0)]),
			(face_pts[2] as Color).lightened(0.05), face_pts[3])
	ArtKit.poly(PackedVector2Array([s._gp(s0, top + 8.0), s._gp(Vector2(s1.x, s0.y), top + 8.0), s._gp(s1, top + 8.0),
		s._gp(Vector2(s0.x, s1.y), top + 8.0)]), ArtKit.VOID, ArtKit.INK)
	ArtKit.poly(PackedVector2Array([s._gp(g0, top), s._gp(gr, top), s._gp(g1, top), s._gp(gl, top)]),
		ArtKit.STONE_TOP.darkened(0.1), ArtKit.LIT_TOP)
	# Furnace mouth on the front side, glowing.
	var m0 := gl.lerp(g1, 0.25)
	var m1 := gl.lerp(g1, 0.75)
	ArtKit.poly(PackedVector2Array([s._gp(m0, 0.0), s._gp(m1, 0.0), s._gp(m1, 7.0), s._gp(m0, 7.0)]), ArtKit.FURNACE[1],
		ArtKit.EMIT)
	ArtKit.poly(PackedVector2Array([s._gp(m0, 7.0), s._gp(m1, 7.0), s._gp(m0.lerp(m1, 0.5), 10.0)]), ArtKit.FURNACE[1],
		ArtKit.EMIT)
	ArtKit.poly(PackedVector2Array([s._gp(m0.lerp(m1, 0.2), 0.0), s._gp(m0.lerp(m1, 0.8), 0.0),
		s._gp(m0.lerp(m1, 0.8), 5.0), s._gp(m0.lerp(m1, 0.2), 5.0)]), ArtKit.FURNACE[0], ArtKit.EMIT)
	for k in range(1, int(neck / 5.0)):
		var hh := k * 5.0
		ArtKit.line(s._gp(gl, hh), s._gp(g1, hh), ArtKit.ink(0.3))
		ArtKit.line(s._gp(g1, hh), s._gp(gr, hh), ArtKit.ink(0.3))
	ArtKit.line(s._gp(g1, 0.0), s._gp(g1, top), ArtKit.ink(0.15, true))
	ArtKit.line(s._gp(gl, 0.0), s._gp(gl, top + 8.0), ArtKit.ink(0.5))
	ArtKit.line(s._gp(gr, 0.0), s._gp(gr, top + 8.0), ArtKit.ink(0.5))


## Block masonry on a free-standing vertical face from ground point a to b (b nearer the camera), h0..h1.
static func _box_masonry(s: Structure, a: Vector2, b: Vector2, h0: float, h1: float, base: Color, code: float,
		salt: int) -> void:
	ArtKit.poly(PackedVector2Array([s._gp(a, h0), s._gp(b, h0), s._gp(b, h1), s._gp(a, h1)]), base.darkened(0.3), code)
	var px := maxf(absf(s._gp(b, 0.0).x - s._gp(a, 0.0).x), 1.0)
	var rows := ceili((h1 - h0) / 5.0)
	for row in rows:
		var y0 := h0 + row * 5.0
		var y1 := minf(y0 + 5.0, h1)
		var x := -4.0 if row % 2 == 1 else 0.0
		var i := 0
		while x < px:
			var xa := maxf(x, 0.0)
			var xb := minf(x + 8.0, px)
			if xb - xa >= 2.0:
				var t := (ArtKit.hash01(s.rng.seed, salt + row * 31 + i) - 0.5) * 0.2
				var bc := base.lightened(t) if t > 0.0 else base.darkened(-t)
				var ua := (xa + (1.0 if xa > 0.0 else 0.0)) / px
				var ub := xb / px
				ArtKit.poly(PackedVector2Array([s._gp(a.lerp(b, ua), y0 + 1.0), s._gp(a.lerp(b, ub), y0 + 1.0),
					s._gp(a.lerp(b, ub), y1), s._gp(a.lerp(b, ua), y1)]), bc, code)
			x += 8.0
			i += 1


# --- Workshop ------------------------------------------------------------------

const WORKSHOP_RISE := 14.0


## The workshop hall: an open timber pavilion under red tile, posts along its sides, and goods under the roof --
## crates, barrels, a workbench -- all drawn inside the footprint.
static func workshop(s: Structure) -> void:
	ArtKit.begin()
	var h := s.height
	var r := s.footprint
	var ax := r.size.x >= r.size.y
	# Goods on the floor, back to front.
	var goods: Array[Vector3] = []
	# Along the open front, where the eave does not hide them (a row just inside it, one just outside).
	for i in 8:
		var t := (float(i) + 0.5) / 8.0
		var inside := 0.3 if i % 2 == 0 else -0.12
		var gpos := Vector2(lerpf(r.position.x + 0.2, r.end.x - 0.2, t), r.end.y - inside) if ax \
			else Vector2(r.end.x - inside, lerpf(r.position.y + 0.2, r.end.y - 0.2, t))
		goods.append(Vector3(gpos.x, gpos.y, float(ArtKit.pick(s.rng.seed, 340 + i, 3))))
	goods.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.x + a.y < b.x + b.y)
	ArtKit.poly(PackedVector2Array([s._gp(r.position, 0.0), s._gp(Vector2(r.end.x, r.position.y), 0.0), s._gp(r.end, 0.0),
		s._gp(Vector2(r.position.x, r.end.y), 0.0)]), ArtKit.INTERIOR_FLOOR, ArtKit.LIT_TOP)
	# Back posts before the goods, front posts after.
	var posts: Array[Vector2] = []
	var n := maxi(int((r.size.x if ax else r.size.y) / 0.9), 2)
	for i in n + 1:
		var t := float(i) / n
		posts.append(Vector2(lerpf(r.position.x + 0.08, r.end.x - 0.08, t), r.position.y + 0.08) if ax
			else Vector2(r.position.x + 0.08, lerpf(r.position.y + 0.08, r.end.y - 0.08, t)))
		posts.append(Vector2(lerpf(r.position.x + 0.08, r.end.x - 0.08, t), r.end.y - 0.08) if ax
			else Vector2(r.end.x - 0.08, lerpf(r.position.y + 0.08, r.end.y - 0.08, t)))
	posts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x + a.y < b.x + b.y)
	var back_posts := posts.slice(0, posts.size() / 2)
	var front_posts := posts.slice(posts.size() / 2)
	for p: Vector2 in back_posts:
		PropArt._post(s, p, 0.0, h, 1.5)
	for gd in goods:
		var g := Vector2(gd.x, gd.y)
		if int(gd.z) == 0:
			PropArt._box(s, g - Vector2(0.14, 0.14), g + Vector2(0.14, 0.14), 0.0, 6.0, ArtKit.WOOD[1], ArtKit.WOOD[0],
				ArtKit.WOOD[0].lightened(0.1))
		elif int(gd.z) == 1:
			var p := s._gp(g, 0.0)
			ArtKit.poly(PackedVector2Array([p + Vector2(-3, -8), p + Vector2(3, -8), p + Vector2(3, 0), p + Vector2(-3, 0)]),
				ArtKit.WOOD[1], ArtKit.LIT_LEFT)
			ArtKit.blob(p + Vector2(0, -8), Vector2(3, 1.4), ArtKit.WOOD[0], ArtKit.LIT_TOP, 8)
			ArtKit.line(p + Vector2(-3, -2), p + Vector2(3, -2), ArtKit.ink(0.5))
			ArtKit.line(p + Vector2(-3, -6), p + Vector2(3, -6), ArtKit.ink(0.5))
		else:
			PropArt._box(s, g - Vector2(0.3, 0.1), g + Vector2(0.3, 0.1), 5.0, 6.5, ArtKit.WOOD[2], ArtKit.WOOD[1],
				ArtKit.WOOD[0])
			for x in [-0.25, 0.25]:
				PropArt._post(s, g + Vector2(x, 0.05), 0.0, 5.0, 1.0)
	for p: Vector2 in front_posts:
		PropArt._post(s, p, 0.0, h, 1.5)
	ArtKit.flush(s)
	var g := _roof(s, ax, WORKSHOP_RISE, false)
	_roof_back(g, ArtKit.RED_TILE)
	ArtKit.flush(s)
	_roof_front(s, g, ArtKit.RED_TILE, 4.0, true)
	ArtKit.flush(s)


# --- Shared roof ------------------------------------------------------------------

## A gable roof's key points, in the building's own frame (a along the ridge, b across it; +b faces the camera).
## `open_end` leaves the +a end without an overhang (the temple's west front covers it).
static func _roof(s: Structure, ax: bool, rise: float, open_end: bool) -> Dictionary:
	var r := s.footprint
	return _roof_span(s, ax, rise, (r.position.x if ax else r.position.y) - OVERHANG,
		(r.end.x if ax else r.end.y) + (0.0 if open_end else OVERHANG), 0.0)


## A gable roof over the span a0..a1 along the ridge; `lower` drops the whole roof (a lean-to) by that many px.
static func _roof_span(s: Structure, ax: bool, rise: float, a0: float, a1: float, lower: float) -> Dictionary:
	var r := s.footprint
	var b0: float = r.position.y if ax else r.position.x
	var b1: float = r.end.y if ax else r.end.x
	var bm := (b0 + b1) * 0.5
	var half := (b1 - b0) * 0.5
	var h := s.height
	var top := h + rise
	var eave := h - DROP - lower
	return {
		"s": s, "ax": ax, "a0": a0, "a1": a1, "bm": bm, "b1": b1, "top": top, "eave": eave,
		"shoulder": top - (top - eave) * half / (half + OVERHANG),
		"ridge0": s._gp(_g(ax, a0, bm), top), "ridge1": s._gp(_g(ax, a1, bm), top),
		"front0": s._gp(_g(ax, a0, b1 + OVERHANG), eave), "front1": s._gp(_g(ax, a1, b1 + OVERHANG), eave),
		"back0": s._gp(_g(ax, a0, b0 - OVERHANG), eave), "back1": s._gp(_g(ax, a1, b0 - OVERHANG), eave),
	}

static func _roof_back(g: Dictionary, pal: Array) -> void:
	ArtKit.poly(PackedVector2Array([g.back0, g.back1, g.ridge1, g.ridge0]), (pal[2] as Color).darkened(0.1), ArtKit.LIT_TOP)


## The front slope: body, a lit band under the ridge, seams down the slope every `seam_px`, tile courses when `tiled`,
## edge boards, trim and an outline. `pal` is [lit, mid, dark, seam, ridge, outline].
static func _roof_front(s: Structure, g: Dictionary, pal: Array, seam_px: float, tiled: bool) -> void:
	var ridge0: Vector2 = g.ridge0
	var ridge1: Vector2 = g.ridge1
	var front0: Vector2 = g.front0
	var front1: Vector2 = g.front1
	var top_code := ArtKit.LIT_TOP
	ArtKit.poly(PackedVector2Array([front0, front1, ridge1, ridge0]), pal[1], top_code)
	ArtKit.poly(PackedVector2Array([ridge0, ridge1, ridge1.lerp(front1, 0.1), ridge0.lerp(front0, 0.1)]), pal[0], top_code)
	ArtKit.poly(PackedVector2Array([front0.lerp(ridge0, 0.08), front1.lerp(ridge1, 0.08), front1, front0]), pal[2],
		top_code)
	var n := maxi(int(ridge0.distance_to(ridge1) / seam_px), 3)
	for i in range(1, n):
		var k := float(i) / n
		var hi := ridge0.lerp(ridge1, k)
		var lo := front0.lerp(front1, k)
		ArtKit.line(hi, lo, ArtKit.ink(0.25))
		if not tiled:
			ArtKit.line(hi.lerp(lo, 0.05) + Vector2(1, 0), hi.lerp(lo, 0.6) + Vector2(1, 0), ArtKit.ink(0.12, true))
	if tiled:
		var rows := maxi(int(ridge0.distance_to(front0) / 4.0), 2)
		for j in range(1, rows):
			var k := float(j) / rows
			ArtKit.line(ridge0.lerp(front0, k), ridge1.lerp(front1, k), ArtKit.ink(0.18))
	var board := Vector2(0, BOARD)
	ArtKit.poly(PackedVector2Array([front0, front1, front1 + board, front0 + board]), pal[3], ArtKit.LIT_LEFT)
	ArtKit.line(ridge0, ridge1, ArtKit.ink(0.3, true))
	# A light dotted trim along the eave, as on the reference's roofs.
	ArtKit.line(front0 + Vector2(0, -1), front1 + Vector2(0, -1), ArtKit.ink(0.22, true))
	var ol: Color = pal[5]
	ArtKit.line(g.back0, g.back1, ol)
	ArtKit.line(g.back0, ridge0, ol)
	ArtKit.line(ridge0, front0, ol)
	ArtKit.line(front0, front0 + board, ol)
	ArtKit.line(front0 + board, front1 + board, ol)
	ArtKit.line(front1, front1 + board, ol)
	ArtKit.line(ridge1, front1, ol)
	ArtKit.line(ridge1, g.back1, ol)


static func _lit(s: Structure, n: int) -> bool:
	if s._windows.is_empty():
		return true
	return s._windows[n % s._windows.size()][3]


static func _g(ax: bool, a: float, b: float) -> Vector2:
	return Vector2(a, b) if ax else Vector2(b, a)
