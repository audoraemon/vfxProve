class_name HouseArt
extends RefCounted
## Aldermere's cottages and the farms' barns, after concepts/TOWN REF/Town Visual Upgrade.png.
## - Cottage: cream plaster between dark timbers on a stone foot; a slate roof with a deep overhang over a timbered
##   gable; a stone chimney, glowing windows and a plank door.
## - Barn: planks instead of plaster, red tile instead of slate.
##
## The ridge runs along the longer side, so one visible wall is the eave wall (under the roof's edge) and the other
## is the gable end. Planning is pure data from the seed; drawing only runs while the house stands whole
## (Structure falls back to its plain box while collapsing, cut or in ruins).

## Ridge height above the wall top, px.
const RISE := 17.0
## How far the roof reaches past the walls (ground units), and how far below the wall top its eaves hang (px).
const OVERHANG := 0.1
const DROP := 2.0
const PLINTH_H := 2.0
## Chimney: ground-unit side, how far down the front slope from the ridge it stands, px it rises above the ridge.
const CHIMNEY_W := 0.17
const CHIMNEY_FRONT := 0.12
const CHIMNEY_UP := 7.0


static func plan(s: Structure) -> Dictionary:
	var sd := s.rng.seed
	return {
		"along_x": s.footprint.size.x >= s.footprint.size.y,
		"chimney_u": 0.22 if ArtKit.hash01(sd, 1) < 0.5 else 0.78,
		"door_face": ArtKit.LEFT if ArtKit.hash01(sd, 2) < 0.5 else ArtKit.RIGHT,
		"door_u": lerpf(0.32, 0.68, ArtKit.hash01(sd, 3)),
		"roof_shade": ArtKit.pick(sd, 4, 3) - 1,
		"gable_window": ArtKit.hash01(sd, 5) < 0.5,
		"barn": s.role == &"farm",
	}


## Three layers, each flushed so the next one's fills cover its lines: walls, openings, back slope and gable; the
## front slope with its seams; the chimney standing on it.
static func draw(s: Structure, light: Color, dir: Vector2) -> void:
	ArtKit.begin()
	var p := s.art
	var barn: bool = p.barn
	var h := s.height
	var ax: bool = p.along_x
	var eave_face := ArtKit.LEFT if ax else ArtKit.RIGHT
	var gable_face := ArtKit.RIGHT if ax else ArtKit.LEFT
	var wall_pal: Array = ArtKit.PLANK if barn else ArtKit.PLASTER
	var wall_c := {ArtKit.RIGHT: _lit(s, wall_pal[0], ArtKit.RIGHT, light, dir),
		ArtKit.LEFT: _lit(s, wall_pal[1], ArtKit.LEFT, light, dir)}
	var timber_c := {ArtKit.RIGHT: _lit(s, ArtKit.TIMBER, ArtKit.RIGHT, light, dir),
		ArtKit.LEFT: _lit(s, ArtKit.TIMBER_DARK, ArtKit.LEFT, light, dir)}

	# Roof geometry, in the house's own frame: a runs along the ridge, b across it; +b is the slope facing the camera.
	var r := s.footprint
	var a0: float = (r.position.x if ax else r.position.y) - OVERHANG
	var a1: float = (r.end.x if ax else r.end.y) + OVERHANG
	var b0: float = r.position.y if ax else r.position.x
	var b1: float = r.end.y if ax else r.end.x
	var bm := (b0 + b1) * 0.5
	var half := (b1 - b0) * 0.5
	var top := h + RISE
	var eave := h - DROP
	# Where the roof crosses the wall line: the gable's shoulders.
	var shoulder := top - (RISE + DROP) * half / (half + OVERHANG)

	# Walls, foot course, framing.
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var wc: Color = wall_c[face]
		var tc: Color = timber_c[face]
		ArtKit.face_quad(s, face, 0.0, 1.0, 0.0, h, wc)
		var px := ArtKit.face_px(s, face)
		if barn:
			var seams := int(px / 3.0)
			for i in range(1, seams):
				var u := float(i) / seams
				ArtKit.face_line(s, face, u, 0.0, u, h, wc.darkened(0.22))
		else:
			ArtKit.face_quad(s, face, 0.0, 1.0, 0.0, PLINTH_H, _lit(s, ArtKit.PLINTH[0 if face == ArtKit.RIGHT else 1],
				face, light, dir))
		var post := 2.0 / maxf(px, 1.0)
		ArtKit.face_quad(s, face, 0.0, post, 0.0, h, tc)
		ArtKit.face_quad(s, face, 1.0 - post * 0.5, 1.0, 0.0, h, tc)
		if face == eave_face:
			# The roof's shadow under the eave.
			ArtKit.face_quad(s, face, 0.0, 1.0, h - 5.0, h - 2.0, wc.darkened(0.16))
		ArtKit.face_quad(s, face, 0.0, 1.0, h - 2.0, h, tc)
		if not barn and face == eave_face and px > 34.0:
			for u in [0.36, 0.64]:
				if absf(u - float(p.door_u)) > 0.14 or p.door_face != face:
					ArtKit.face_quad(s, face, u - post * 0.5, u + post * 0.5, PLINTH_H, h - 2.0, tc)

	var door_c := {ArtKit.RIGHT: _lit(s, ArtKit.DOOR[0], ArtKit.RIGHT, light, dir),
		ArtKit.LEFT: _lit(s, ArtKit.DOOR[1], ArtKit.LEFT, light, dir)}
	_draw_openings(s, p, h, eave_face, gable_face, wall_c, timber_c, door_c, barn)

	# Roof: back slope, chimney (behind the ridge), the gable in front of both, the front slope over its overhang.
	var pal: Array = ArtKit.RED_TILE if barn else ArtKit.SLATE
	var shade: int = p.roof_shade
	var roof: Array[Color] = []
	for i in pal.size():
		var base: Color = pal[i]
		base = base.lightened(0.07) if shade > 0 else (base.darkened(0.07) if shade < 0 else base)
		roof.append(_lit(s, base, 0, light, dir))
	var ridge0 := s._gp(_g(ax, a0, bm), top)
	var ridge1 := s._gp(_g(ax, a1, bm), top)
	var front0 := s._gp(_g(ax, a0, b1 + OVERHANG), eave)
	var front1 := s._gp(_g(ax, a1, b1 + OVERHANG), eave)
	var back0 := s._gp(_g(ax, a0, b0 - OVERHANG), eave)
	var back1 := s._gp(_g(ax, a1, b0 - OVERHANG), eave)
	ArtKit.poly(PackedVector2Array([back0, back1, ridge1, ridge0]), roof[2])
	# Gable end: the wall rises into a triangle under the rakes.
	var gc: Color = wall_c[gable_face]
	var gt: Color = timber_c[gable_face]
	ArtKit.face_quad(s, gable_face, 0.0, 1.0, h, shoulder, gc)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, gable_face, 0.0, shoulder),
		ArtKit.face_pt(s, gable_face, 1.0, shoulder), ArtKit.face_pt(s, gable_face, 0.5, top)]), gc)
	if barn:
		for u in [0.25, 0.5, 0.75]:
			ArtKit.face_line(s, gable_face, u, h, u, lerpf(shoulder, top, 1.0 - absf(u - 0.5) * 2.0), gc.darkened(0.22))
	else:
		ArtKit.face_line(s, gable_face, 0.5, h, 0.5, top - 2.0, gt)
		ArtKit.face_line(s, gable_face, 0.5, h + (top - h) * 0.45, 0.2, h, gt)
		ArtKit.face_line(s, gable_face, 0.5, h + (top - h) * 0.45, 0.8, h, gt)
	if p.gable_window and not barn:
		ArtKit.window(s, gable_face, 0.5, h + 3.0, 2.0, 3.0, _window_lit(s, 7), gt, gc)
	# Shadow under the rakes.
	ArtKit.line(ArtKit.face_pt(s, gable_face, 0.0, shoulder - 1.0), ArtKit.face_pt(s, gable_face, 0.5, top - 1.0),
		gc.darkened(0.3))
	ArtKit.line(ArtKit.face_pt(s, gable_face, 0.5, top - 1.0), ArtKit.face_pt(s, gable_face, 1.0, shoulder - 1.0),
		gc.darkened(0.3))

	ArtKit.flush(s)

	ArtKit.poly(PackedVector2Array([front0, front1, ridge1, ridge0]), roof[1])
	# Seams run down the slope, with a lighter streak between some of them.
	var length_px := ridge0.distance_to(ridge1)
	var seams := maxi(int(length_px / 4.0), 3)
	for i in range(1, seams * 2):
		var a := lerpf(a0, a1, float(i) / (seams * 2))
		var hi := s._gp(_g(ax, a, bm), top)
		var lo := s._gp(_g(ax, a, b1 + OVERHANG), eave)
		if i % 2 == 0:
			ArtKit.line(hi.lerp(lo, 0.08), lo, roof[3])
		elif ArtKit.hash01(s.rng.seed, 20 + i) < 0.55:
			var from := lerpf(0.05, 0.35, ArtKit.hash01(s.rng.seed, 60 + i))
			ArtKit.line(hi.lerp(lo, from), hi.lerp(lo, from + lerpf(0.2, 0.45, ArtKit.hash01(s.rng.seed, 40 + i))),
				roof[0])
	# Ridge cap, eave lip and the rake boards at the gable end.
	ArtKit.line(ridge0, ridge1, roof[4])
	ArtKit.line(front0, front1, roof[3])
	ArtKit.line(front0 + Vector2(0, -1), front1 + Vector2(0, -1), roof[2])
	ArtKit.line(ridge1, front1, roof[3])
	ArtKit.line(ridge1, back1, roof[3])
	ArtKit.flush(s)
	if not barn:
		_draw_chimney(s, p, ax, a0, a1, bm, half, top, light, dir)
		ArtKit.flush(s)


## Where the chimney's smoke leaves it (structure-local screen px), or Vector2.INF for a barn.
static func chimney_top(s: Structure) -> Vector2:
	var p := s.art
	if p.is_empty() or p.barn:
		return Vector2.INF
	var r := s.footprint
	var ax: bool = p.along_x
	var a := lerpf(r.position.x if ax else r.position.y, r.end.x if ax else r.end.y, p.chimney_u)
	var bm: float = (r.get_center().y if ax else r.get_center().x) + CHIMNEY_FRONT
	return s._gp(_g(ax, a, bm), s.height + RISE + CHIMNEY_UP)


static func _draw_openings(s: Structure, p: Dictionary, h: float, eave_face: int, gable_face: int, wall_c: Dictionary,
		timber_c: Dictionary, door_c: Dictionary, barn: bool) -> void:
	var door_face: int = p.door_face
	var door_u: float = p.door_u
	var sill := roundf(h * 0.42)
	var tall := 4.0 if h >= 22.0 else 3.0
	var n := 0
	for face in [eave_face, gable_face]:
		var px := ArtKit.face_px(s, face)
		var spots: Array[float] = []
		if face == door_face:
			var dw := 8.0 if barn else 5.0
			_draw_door(s, face, door_u, dw, minf(roundf(h * (0.62 if barn else 0.5)), h - 5.0), door_c[face],
				timber_c[face], barn)
			var side := 0.3 if px > 34.0 else 0.24
			for u in [door_u - side, door_u + side]:
				if u > 0.14 and u < 0.86:
					spots.append(u)
		elif face == eave_face and px > 34.0:
			spots.append_array([0.3, 0.7])
		else:
			spots.append(0.5)
		if barn:
			spots = spots.slice(0, 1)
		for u in spots:
			ArtKit.window(s, face, u, sill, 3.0, tall, _window_lit(s, n), timber_c[face], wall_c[face])
			n += 1


static func _draw_door(s: Structure, face: int, u: float, w: float, tall: float, wood: Color, timber: Color,
		barn: bool) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var du := w * 0.5 / px
	var fu := 1.0 / px
	ArtKit.face_quad(s, face, u - du - fu, u + du + fu, 0.0, tall + 1.0, timber)
	ArtKit.face_quad(s, face, u - du, u + du, 0.0, tall, wood)
	if barn:
		ArtKit.face_line(s, face, u - du, 0.0, u + du, tall, timber)
		ArtKit.face_line(s, face, u - du, tall, u + du, 0.0, timber)
		ArtKit.face_line(s, face, u, 0.0, u, tall, timber)
	else:
		ArtKit.face_line(s, face, u, 0.0, u, tall, wood.darkened(0.3))
		ArtKit.face_quad(s, face, u + du * 0.4, u + du * 0.4 + fu, tall * 0.45, tall * 0.45 + 1.0, ArtKit.GLOW_RIM)


static func _draw_chimney(s: Structure, p: Dictionary, ax: bool, a0: float, a1: float, bm: float, half: float,
		top: float, light: Color, dir: Vector2) -> void:
	var a := lerpf(a0 + OVERHANG, a1 - OVERHANG, p.chimney_u)
	var hw := CHIMNEY_W * 0.5
	var b := bm + CHIMNEY_FRONT
	var cap := top + CHIMNEY_UP
	# Corners in the house frame: (a -/+ hw) x (b -/+ hw); the camera sees the +a and +b sides.
	var fa := a + hw
	var fb := b + hw
	var na := a - hw
	var nb := b - hw
	var right_c := _lit(s, ArtKit.CHIMNEY[0], ArtKit.RIGHT, light, dir)
	var left_c := _lit(s, ArtKit.CHIMNEY[1], ArtKit.LEFT, light, dir)
	var cap_c := _lit(s, ArtKit.CHIMNEY_CAP, 0, light, dir)
	# In the house frame the +b side is the wall facing the eave side, the +a side the one facing the gable end.
	var b_face := [_g(ax, na, fb), _g(ax, fa, fb)]
	var a_face := [_g(ax, fa, nb), _g(ax, fa, fb)]
	var b_c := left_c if ax else right_c
	var a_c := right_c if ax else left_c
	for side in [[b_face, b_c], [a_face, a_c]]:
		var g: Array = side[0]
		var c: Color = side[1]
		var g0: Vector2 = g[0]
		var g1: Vector2 = g[1]
		var h0 := _roof_h(ax, g0, bm, half, top) - 1.0
		var h1 := _roof_h(ax, g1, bm, half, top) - 1.0
		ArtKit.poly(PackedVector2Array([s._gp(g0, h0), s._gp(g1, h1), s._gp(g1, cap), s._gp(g0, cap)]), c)
		for k in [5.0, 9.0]:
			ArtKit.line(s._gp(g0, cap - k), s._gp(g1, cap - k), c.darkened(0.3))
		ArtKit.poly(PackedVector2Array([s._gp(g0, cap - 2.0), s._gp(g1, cap - 2.0), s._gp(g1, cap), s._gp(g0, cap)]),
			cap_c if c == b_c else cap_c.lightened(0.1))
	ArtKit.poly(PackedVector2Array([s._gp(_g(ax, na, nb), cap), s._gp(_g(ax, fa, nb), cap), s._gp(_g(ax, fa, fb), cap),
		s._gp(_g(ax, na, fb), cap)]), ArtKit.CHIMNEY[2].darkened(0.5))


## Height of the roof surface over a ground point (px), from the ridge down either slope.
static func _roof_h(ax: bool, g: Vector2, bm: float, half: float, top: float) -> float:
	var b := g.y if ax else g.x
	return top - (RISE + DROP) * absf(b - bm) / (half + OVERHANG)


## A material colour lit for the wall it sits on (0 = a roof or top, facing the sky).
static func _lit(s: Structure, base: Color, face: int, light: Color, dir: Vector2) -> Color:
	var normal := Vector2(1, 0) if face == ArtKit.RIGHT else (Vector2(0, 1) if face == ArtKit.LEFT else Vector2.ZERO)
	return s._face_color(base, normal, light, dir)


## Window n's light: the house's own window flags when it has them (damage puts them out), else a hashed guess.
static func _window_lit(s: Structure, n: int) -> bool:
	if s._windows.is_empty():
		return ArtKit.hash01(s.rng.seed, 60 + n) < 0.65
	return s._windows[n % s._windows.size()][3]


## Ground point from the house's own frame (a along the ridge, b across it).
static func _g(ax: bool, a: float, b: float) -> Vector2:
	return Vector2(a, b) if ax else Vector2(b, a)
