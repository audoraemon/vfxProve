class_name FarmArt
extends RefCounted
## The Scale reference's countryside buildings, houses tagged by kind of work:
## - Windmill (&"windmill"): a tall timber and plaster tower under a slate cap. Its four lattice sails turn on the
##   structure's spin node, so the tower itself stays cached.
## - Watermill (&"watermill"): a plaster cottage under slate, with a great wooden wheel against its front (left)
##   wall, standing in a mill race, that turns on the spin node.
## Colours are unlit: the structure's shader lights them (see ArtKit). The spin node has no shader: its colours are
## tinted by the light passed in.

## Windmill cap rise and sail length (px).
const CAP_RISE := 24.0
const SAIL := 36.0
## Watermill wheel radius (px), and how far along its wall (ground units from the west corner) its axle sits.
const WHEEL := 32.0
const WHEEL_AT := 0.9
## The wheel stands this far out from its wall, and is this thick (ground units).
const WHEEL_OUT := 0.2
const WHEEL_DEPTH := 0.22
const WATER := Color("2f6fa0")
const FOAM := Color(0.9, 0.96, 1.0, 0.8)


static func draw(s: Structure) -> void:
	_windmill(s)


## Where the sails' hub or the wheel's axle sits (structure-local px).
static func hub(s: Structure) -> Vector2:
	var r := s.footprint
	if s.art_tag == &"windmill":
		# High on the tower's front, just under the cap, facing the camera's left.
		return s._gp(Vector2(r.get_center().x, r.end.y + 0.1), s.height * 0.86)
	return s._gp(Vector2(r.position.x + WHEEL_AT, r.end.y + WHEEL_OUT), WHEEL - 5.0)


## The turning part at `angle` (radians), drawn onto `ci` (the structure's spin node), tinted by `tint`.
static func draw_spin(s: Structure, ci: CanvasItem, angle: float, tint: Color) -> void:
	ArtKit.begin()
	if s.art_tag == &"windmill":
		_sails(s, angle, tint)
	else:
		_wheel(s, angle, tint)
	ArtKit.flush(ci)


## Four lattice sails in an X, their cloth on the trailing side of each stock.
static func _sails(s: Structure, angle: float, tint: Color) -> void:
	var c := hub(s)
	var e := ArtKit.EMIT
	var dark := ArtKit.WOOD[2] * tint
	var cloth := Color("f0e8d8") * tint
	var shade := Color("cfc4ae") * tint
	for k in 4:
		var a := angle + PI * 0.25 + k * PI * 0.5
		# The sails face the camera's left: squash them a little across so they read as iso.
		var d := Vector2(cos(a), sin(a) * 0.9)
		var n := Vector2(-d.y, d.x)
		var tip := c + d * SAIL
		var b0 := c + d * 7.0
		ArtKit.poly(PackedVector2Array([b0, tip, tip + n * 9.0, b0 + n * 7.0]), cloth, e)
		ArtKit.poly(PackedVector2Array([b0 + n * 4.0, tip + n * 5.0, tip + n * 9.0, b0 + n * 7.0]), shade, e)
		# The lattice: bars across and a rail down the outer edge.
		for j in 6:
			var p0 := b0.lerp(tip, float(j) / 5.0)
			ArtKit.line(p0, p0 + n * lerpf(7.0, 9.0, float(j) / 5.0), Color(dark.r, dark.g, dark.b, 0.9))
		ArtKit.line(b0 + n * 7.0, tip + n * 9.0, Color(dark.r, dark.g, dark.b, 0.9))
		ArtKit.line(b0 + n * 3.5, tip + n * 4.5, Color(dark.r, dark.g, dark.b, 0.5))
		ArtKit.poly(PackedVector2Array([c - n * 1.2, c + n * 1.2, tip + n * 1.2, tip - n * 1.2]), dark, e)
	ArtKit.blob(c, Vector2(3.5, 3.5), dark, e, 8)
	ArtKit.blob(c, Vector2(1.5, 1.5), ArtKit.IRON * tint, e, 6)


## The wheel stands in the plane of the front wall: a rim and hub joined by spokes, with paddles standing out.
static func _wheel(s: Structure, angle: float, tint: Color) -> void:
	var r := s.footprint
	var e := ArtKit.EMIT
	var wood := ArtKit.WOOD[1] * tint
	var light := ArtKit.WOOD[0] * tint
	var dark := ArtKit.WOOD[2] * tint
	var cx := r.position.x + WHEEL_AT
	var y := r.end.y + WHEEL_OUT
	var cz := WHEEL - 5.0
	var ru := WHEEL / 32.0
	var seg := 20
	# Back rim first, then paddles, then spokes and the front rim over them.
	var back := func(t: float, rad: float) -> Vector2:
		return s._gp(Vector2(cx + cos(t) * rad / 32.0, y - WHEEL_DEPTH), cz + sin(t) * rad)
	var front := func(t: float, rad: float) -> Vector2:
		return s._gp(Vector2(cx + cos(t) * rad / 32.0, y), cz + sin(t) * rad)
	for i in seg:
		var t0 := angle + TAU * i / seg
		var t1 := angle + TAU * (i + 1) / seg
		ArtKit.poly(PackedVector2Array([back.call(t0, WHEEL), back.call(t1, WHEEL), back.call(t1, WHEEL - 5.0),
			back.call(t0, WHEEL - 5.0)]), dark, e)
	# The wheel's dark inside, so it reads as a solid wheel rather than a hoop.
	var disk := PackedVector2Array()
	for i in seg:
		disk.append(back.call(TAU * i / seg, WHEEL - 5.0))
	ArtKit.fan(disk, Color(0.2, 0.14, 0.09) * tint, e)
	for i in 12:
		var t := angle + TAU * i / 12.0
		ArtKit.poly(PackedVector2Array([back.call(t, WHEEL + 1.0), front.call(t, WHEEL + 1.0), front.call(t, WHEEL - 5.0),
			back.call(t, WHEEL - 5.0)]), light if sin(t) < 0.0 else wood, e)
	for i in 8:
		var t := angle + TAU * i / 8.0 + 0.2
		var n := Vector2(-sin(t), cos(t)) * 0.9
		ArtKit.poly(PackedVector2Array([front.call(t, 3.0) - n, front.call(t, 3.0) + n, front.call(t, WHEEL - 2.0) + n,
			front.call(t, WHEEL - 2.0) - n]), wood, e)
	for i in seg:
		var t0 := angle + TAU * i / seg
		var t1 := angle + TAU * (i + 1) / seg
		ArtKit.poly(PackedVector2Array([front.call(t0, WHEEL), front.call(t1, WHEEL), front.call(t1, WHEEL - 5.0),
			front.call(t0, WHEEL - 5.0)]), wood if sin(t0) < 0.0 else dark, e)
	var c := hub(s)
	ArtKit.blob(c, Vector2(4.0, 4.0), dark, e, 10)
	ArtKit.blob(c, Vector2(2.0, 2.0), ArtKit.IRON * tint, e, 8)
	# Water spilling off the paddles into the race.
	for i in 5:
		var t := angle * 3.0 + i * 1.3
		var p := s._gp(Vector2(cx - ru + fposmod(t, 2.0 * ru), y + 0.1), 1.0)
		ArtKit.poly(PackedVector2Array([p, p + Vector2(3, 0), p + Vector2(3, 2), p + Vector2(0, 2)]), FOAM * tint, e)


static func _windmill(s: Structure) -> void:
	ArtKit.begin()
	var h := s.height
	var r := s.footprint
	# A stone foot, then a tall plaster tower framed in timber, tapering a little, with windows up its faces.
	var inset := 0.1
	var top_r := r.grow(-inset)
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var base: Color = ArtKit.PLASTER[0] if face == ArtKit.RIGHT else ArtKit.PLASTER[1]
		var code := ArtKit.face_code(face)
		var a0 := s._s[face]
		var a1 := s._s[2]
		var t0 := s._gp(_corner(top_r, face), h)
		var t1 := s._gp(top_r.end, h)
		ArtKit.poly(PackedVector2Array([a0, a1, t1, t0]), base, code)
		ArtKit.poly(PackedVector2Array([a0, a1, a1 + Vector2(0, -6), a0 + Vector2(0, -6)]),
			ArtKit.PLINTH[0 if face == ArtKit.RIGHT else 1], code)
		# Timber frame: posts at the corners and middle, two floor beams, braces between them.
		for k in [0.36, 0.7]:
			ArtKit.line(a0.lerp(t0, k), a1.lerp(t1, k), ArtKit.ink(0.7))
		ArtKit.line(a0, t0, ArtKit.ink(0.8))
		var m0 := a0.lerp(a1, 0.5)
		var m1 := t0.lerp(t1, 0.5)
		ArtKit.line(m0, m1, ArtKit.ink(0.6))
		ArtKit.line(a0.lerp(t0, 0.36), m0.lerp(m1, 0.7), ArtKit.ink(0.45))
		ArtKit.line(a1.lerp(t1, 0.36), m0.lerp(m1, 0.7), ArtKit.ink(0.45))
	# A door on the left face, lit windows up both.
	ArtKit.face_quad(s, ArtKit.LEFT, 0.6, 0.8, 0.0, 12.0, ArtKit.DOOR[1])
	ArtKit.face_quad(s, ArtKit.LEFT, 0.2, 0.34, h * 0.45, h * 0.45 + 7.0, ArtKit.GLOW_RIM, ArtKit.EMIT)
	ArtKit.face_quad(s, ArtKit.RIGHT, 0.3, 0.44, h * 0.42, h * 0.42 + 7.0, ArtKit.GLOW_RIM, ArtKit.EMIT)
	ArtKit.face_quad(s, ArtKit.RIGHT, 0.6, 0.74, h * 0.74, h * 0.74 + 6.0, ArtKit.GLOW_RIM, ArtKit.EMIT)
	ArtKit.flush(s)
	# The cap: a steep pyramid of slate with an overhang.
	var g0 := top_r.grow(0.14)
	var peak := s._gp(g0.get_center(), h + CAP_RISE)
	var gl := Vector2(g0.position.x, g0.end.y)
	var gr := Vector2(g0.end.x, g0.position.y)
	ArtKit.poly(PackedVector2Array([s._gp(g0.position, h), s._gp(gr, h), peak]), ArtKit.SLATE[2], ArtKit.LIT_TOP)
	ArtKit.poly(PackedVector2Array([s._gp(g0.position, h), s._gp(gl, h), peak]), ArtKit.SLATE[2], ArtKit.LIT_TOP)
	ArtKit.poly(PackedVector2Array([s._gp(gl, h), s._gp(g0.end, h), peak]), ArtKit.SLATE[1], ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(gr, h), s._gp(g0.end, h), peak]), ArtKit.SLATE[0], ArtKit.LIT_RIGHT)
	for k in [0.3, 0.55, 0.78]:
		ArtKit.line(s._gp(gl, h).lerp(peak, k), s._gp(g0.end, h).lerp(peak, k), ArtKit.ink(0.25))
		ArtKit.line(s._gp(g0.end, h).lerp(peak, k), s._gp(gr, h).lerp(peak, k), ArtKit.ink(0.25))
	ArtKit.line(s._gp(g0.end, h), peak, ArtKit.ink(0.3, true))
	ArtKit.line(s._gp(gl, h), s._gp(g0.end, h), ArtKit.SLATE[5])
	ArtKit.line(s._gp(g0.end, h), s._gp(gr, h), ArtKit.SLATE[5])
	ArtKit.flush(s)


static func _corner(r: Rect2, face: int) -> Vector2:
	# The far corner of a visible wall: LEFT runs from (x0, y1), RIGHT from (x1, y0).
	return Vector2(r.position.x, r.end.y) if face == ArtKit.LEFT else Vector2(r.end.x, r.position.y)


## The watermill's race: a stone-lined channel of water along its front wall, under the wheel. Drawn after the
## cottage.
static func watermill_race(s: Structure) -> void:
	ArtKit.begin()
	var r := s.footprint
	var y0 := r.end.y + 0.02
	var y1 := r.end.y + WHEEL_OUT + 0.3
	var x0 := r.position.x - 0.1
	var x1 := r.position.x + WHEEL_AT * 2.0 + 0.1
	var lip := func(a: Vector2, b: Vector2) -> void:
		ArtKit.poly(PackedVector2Array([s._gp(a, 3.0), s._gp(b, 3.0), s._gp(b, 0.0), s._gp(a, 0.0)]), ArtKit.PLINTH[1],
			ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(Vector2(x0, y0), 0.0), s._gp(Vector2(x1, y0), 0.0), s._gp(Vector2(x1, y1), 0.0),
		s._gp(Vector2(x0, y1), 0.0)]), WATER, ArtKit.EMIT)
	for i in 4:
		var x := lerpf(x0 + 0.1, x1 - 0.2, float(i) / 3.0)
		ArtKit.line(s._gp(Vector2(x, y0 + 0.15), 0.0), s._gp(Vector2(x + 0.18, y0 + 0.15), 0.0), FOAM)
	lip.call(Vector2(x0, y1), Vector2(x1, y1))
	ArtKit.flush(s)
