class_name HouseArt
extends RefCounted
## Aldermere's cottages and the farms' barns, after concepts/TOWN REF/Town Visual Upgrade.png.
## - Cottage: warm plaster between dark timbers; a steep slate roof with a deep overhang, thick edge boards and a
##   dark outline, over a timbered gable; a stone chimney, glowing windows and a plank door.
## - Barn: planks instead of plaster, red tile instead of slate.
## - Tavern (tag &"tavern"): two storeys of timber and plaster under red tile, windows on both floors, an awning
##   over the door, and a hanging blue sign.
## - Blacksmith (tag &"smithy"): a dark plank shed under a wooden roof, open at the front on a glowing forge and an
##   anvil, with a tall stone chimney at its end.
##
## The ridge runs along the longer side, so one visible wall is the eave wall (under the roof's edge) and the other
## is the gable end. Planning is pure data from the seed; drawing only runs while the house stands whole
## (Structure falls back to its plain box while collapsing, cut or in ruins). Colours are unlit: the structure's
## shader lights them (see ArtKit).

## Ridge height above the wall top: px per ground unit of half-depth (the roof's pitch), clamped.
const RISE_PER_HALF := 40.0
const RISE_MIN := 14.0
const RISE_MAX := 32.0
## How far the roof reaches past the walls (ground units), and how far below the wall top its eaves hang (px).
const OVERHANG := 0.11
const DROP := 3.0
## Thickness of the boards along the eave and the near rakes, px.
const BOARD := 2.0
const PLINTH_H := 2.0
## Chimney: ground-unit side, how far down the front slope from the ridge it stands, px it rises above the ridge.
const CHIMNEY_W := 0.17
const CHIMNEY_FRONT := 0.12
const CHIMNEY_UP := 6.0


static func plan(s: Structure) -> Dictionary:
	var sd := s.rng.seed
	var ax := s.footprint.size.x >= s.footprint.size.y
	var half := (s.footprint.size.y if ax else s.footprint.size.x) * 0.5
	var plan := {
		"along_x": ax,
		"rise": clampf(roundf(half * RISE_PER_HALF), RISE_MIN, RISE_MAX),
		"chimney_u": 0.22 if ArtKit.hash01(sd, 1) < 0.5 else 0.78,
		"door_face": ArtKit.LEFT if ArtKit.hash01(sd, 2) < 0.5 else ArtKit.RIGHT,
		"door_u": lerpf(0.32, 0.68, ArtKit.hash01(sd, 3)),
		"roof_shade": ArtKit.pick(sd, 4, 3) - 1,
		"gable_window": ArtKit.hash01(sd, 5) < 0.5,
		"barn": s.role == &"farm",
		"tavern": s.art_tag == &"tavern",
		"smithy": s.art_tag == &"smithy",
	}
	if plan.tavern or plan.smithy:
		# The front is the long wall facing the street; the tavern's chimney stands at its far end.
		plan.door_face = ArtKit.LEFT if ax else ArtKit.RIGHT
		plan.door_u = 0.5
		plan.chimney_u = 0.2
		plan.gable_window = true
		plan.roof_shade = 0
	return plan


## Three layers, each flushed so the next one's fills cover its lines: walls, openings, back slope and gable; the
## front slope with its seams, boards and outline; the chimney standing on it.
static func draw(s: Structure) -> void:
	ArtKit.begin()
	var p := s.art
	if p.smithy:
		_smithy(s)
		return
	var barn: bool = p.barn
	var tavern: bool = p.tavern
	var h := s.height
	var ax: bool = p.along_x
	var rise: float = p.rise
	var eave_face := ArtKit.LEFT if ax else ArtKit.RIGHT
	var gable_face := ArtKit.RIGHT if ax else ArtKit.LEFT
	var wall_pal: Array = ArtKit.PLANK if barn else ArtKit.PLASTER
	var wall_c := {ArtKit.RIGHT: wall_pal[0], ArtKit.LEFT: wall_pal[1]}
	var timber_c := {ArtKit.RIGHT: ArtKit.TIMBER, ArtKit.LEFT: ArtKit.TIMBER_DARK}

	# Roof geometry, in the house's own frame: a runs along the ridge, b across it; +b is the slope facing the camera.
	var r := s.footprint
	var a0: float = (r.position.x if ax else r.position.y) - OVERHANG
	var a1: float = (r.end.x if ax else r.end.y) + OVERHANG
	var b0: float = r.position.y if ax else r.position.x
	var b1: float = r.end.y if ax else r.end.x
	var bm := (b0 + b1) * 0.5
	var half := (b1 - b0) * 0.5
	var top := h + rise
	var eave := h - DROP
	# Where the roof crosses the wall line: the gable's shoulders.
	var shoulder := top - (rise + DROP) * half / (half + OVERHANG)

	# Walls: plaster (or planks), stone foot, corner posts, the roof's shadow under the eave, a dark footing line.
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var wc: Color = wall_c[face]
		var tc: Color = timber_c[face]
		ArtKit.face_quad(s, face, 0.0, 1.0, 0.0, h, wc)
		var px := ArtKit.face_px(s, face)
		if barn:
			var seams := int(px / 3.0)
			for i in range(1, seams):
				var u := float(i) / seams
				ArtKit.face_line(s, face, u, 0.0, u, eave - BOARD, ArtKit.ink(0.3))
		else:
			ArtKit.face_quad(s, face, 0.0, 1.0, 0.0, PLINTH_H, ArtKit.PLINTH[0 if face == ArtKit.RIGHT else 1])
		if face == eave_face:
			ArtKit.face_quad(s, face, 0.0, 1.0, eave - BOARD - 3.0, h, wc.darkened(0.32))
		var post := 2.0 / maxf(px, 1.0)
		ArtKit.face_quad(s, face, 0.0, post, 0.0, h, tc)
		ArtKit.face_quad(s, face, 1.0 - post * 0.5, 1.0, 0.0, h, tc)
		if not barn and face == eave_face and px > 34.0 \
				and (p.door_face != face or absf(float(p.door_u) - 0.5) > 0.12):
			ArtKit.face_quad(s, face, 0.5 - post * 0.5, 0.5 + post * 0.5, PLINTH_H, h, tc)
		if tavern:
			# Storey beam, and posts between the bays on both floors.
			ArtKit.face_quad(s, face, 0.0, 1.0, h * 0.5 - 1.0, h * 0.5 + 1.0, tc)
			for u: float in ([0.25, 0.75] if face == eave_face else [0.5]):
				ArtKit.face_quad(s, face, u - post * 0.5, u + post * 0.5, PLINTH_H, h, tc)
		ArtKit.face_line(s, face, 0.0, 0.0, 1.0, 0.0, ArtKit.ink(0.75))

	var door_c := {ArtKit.RIGHT: ArtKit.DOOR[0], ArtKit.LEFT: ArtKit.DOOR[1]}
	if tavern:
		_tavern_front(s, h, eave_face, gable_face, timber_c, door_c)
	else:
		_draw_openings(s, p, h, eave_face, gable_face, timber_c, door_c, barn)

	# Roof: back slope, then the gable in front of it; the front slope comes over both in the next layer.
	var pal: Array = ArtKit.RED_TILE if barn or tavern else ArtKit.SLATE
	var shade: int = p.roof_shade
	var roof: Array[Color] = []
	for i in pal.size():
		var base: Color = pal[i]
		roof.append(base.lightened(0.06) if shade > 0 else (base.darkened(0.06) if shade < 0 else base))
	var top_code := ArtKit.LIT_TOP
	var ridge0 := s._gp(_g(ax, a0, bm), top)
	var ridge1 := s._gp(_g(ax, a1, bm), top)
	var front0 := s._gp(_g(ax, a0, b1 + OVERHANG), eave)
	var front1 := s._gp(_g(ax, a1, b1 + OVERHANG), eave)
	var back0 := s._gp(_g(ax, a0, b0 - OVERHANG), eave)
	var back1 := s._gp(_g(ax, a1, b0 - OVERHANG), eave)
	ArtKit.poly(PackedVector2Array([back0, back1, ridge1, ridge0]), roof[2], top_code)
	var gc: Color = wall_c[gable_face]
	var gt: Color = timber_c[gable_face]
	var gcode := ArtKit.face_code(gable_face)
	ArtKit.face_quad(s, gable_face, 0.0, 1.0, h, shoulder, gc)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, gable_face, 0.0, shoulder),
		ArtKit.face_pt(s, gable_face, 1.0, shoulder), ArtKit.face_pt(s, gable_face, 0.5, top)]), gc, gcode)
	# Shade under the far rake, then the gable's timbers.
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, gable_face, 0.0, shoulder),
		ArtKit.face_pt(s, gable_face, 0.5, top), ArtKit.face_pt(s, gable_face, 0.5, top - 3.0),
		ArtKit.face_pt(s, gable_face, 0.0, shoulder - 3.0)]), gc.darkened(0.3), gcode)
	if barn:
		for u in [0.25, 0.5, 0.75]:
			ArtKit.face_line(s, gable_face, u, h, u, lerpf(shoulder, top, 1.0 - absf(u - 0.5) * 2.0) - 2.0,
				ArtKit.ink(0.3))
	else:
		ArtKit.face_quad(s, gable_face, 0.0, 1.0, h - 1.0, h + 1.0, gt)
		var kp := 1.0 / maxf(ArtKit.face_px(s, gable_face), 1.0)
		ArtKit.face_quad(s, gable_face, 0.5 - kp, 0.5 + kp, h, top - 4.0, gt)
		var knee := h + (top - h) * 0.42
		ArtKit.face_line(s, gable_face, 0.5, knee, 0.22, h + 1.0, ArtKit.ink(0.75))
		ArtKit.face_line(s, gable_face, 0.5, knee, 0.78, h + 1.0, ArtKit.ink(0.75))
		if p.gable_window:
			ArtKit.window(s, gable_face, 0.33, h + 3.0, 2.0, 3.0, _window_lit(s, 7), gt)
	ArtKit.flush(s)

	# Front slope: tiles, a lit band under the ridge and a dark one above the eave, seams and streaks.
	ArtKit.poly(PackedVector2Array([front0, front1, ridge1, ridge0]), roof[1], top_code)
	ArtKit.poly(PackedVector2Array([ridge0, ridge1, ridge1.lerp(front1, 0.12), ridge0.lerp(front0, 0.12)]), roof[0],
		top_code)
	ArtKit.poly(PackedVector2Array([front0.lerp(ridge0, 0.1), front1.lerp(ridge1, 0.1), front1, front0]), roof[2],
		top_code)
	var length_px := ridge0.distance_to(ridge1)
	var seams := maxi(int(length_px / 4.0), 3)
	for i in range(1, seams * 2):
		var a := lerpf(a0, a1, float(i) / (seams * 2))
		var hi := s._gp(_g(ax, a, bm), top)
		var lo := s._gp(_g(ax, a, b1 + OVERHANG), eave)
		if i % 2 == 0:
			ArtKit.line(hi.lerp(lo, 0.06), lo, ArtKit.ink(0.22))
		elif ArtKit.hash01(s.rng.seed, 20 + i) < 0.6:
			var from := lerpf(0.04, 0.3, ArtKit.hash01(s.rng.seed, 60 + i))
			ArtKit.line(hi.lerp(lo, from), hi.lerp(lo, from + lerpf(0.2, 0.5, ArtKit.hash01(s.rng.seed, 40 + i))),
				ArtKit.ink(0.12, true))
	# Edge boards along the eave and down both near rakes: the roof's thickness seen end-on.
	var board := Vector2(0, BOARD)
	ArtKit.poly(PackedVector2Array([front0, front1, front1 + board, front0 + board]), roof[3], ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([ridge1, front1, front1 + board, ridge1 + board]), roof[3], ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([back1, ridge1, ridge1 + board, back1 + board]), roof[3].darkened(0.2),
		ArtKit.LIT_RIGHT)
	# Ridge cap and the lit top edge of the near rakes.
	ArtKit.line(ridge0, ridge1, ArtKit.ink(0.3, true))
	ArtKit.line(ridge1, front1, ArtKit.ink(0.18, true))
	ArtKit.line(ridge1, back1, ArtKit.ink(0.12, true))
	# Dark outline round the roof's silhouette.
	var ol: Color = roof[5]
	ArtKit.line(back0, back1, ol)
	ArtKit.line(back0, ridge0, ol)
	ArtKit.line(ridge0, front0, ol)
	ArtKit.line(front0, front0 + board, ol)
	ArtKit.line(front0 + board, front1 + board, ol)
	ArtKit.line(front1 + board, ridge1 + board, ol)
	ArtKit.line(ridge1 + board, back1 + board, ol)
	ArtKit.line(back1, back1 + board, ol)
	ArtKit.flush(s)
	if not barn:
		_draw_chimney(s, p, ax, a0, a1, bm, half, top, rise)
		ArtKit.flush(s)


## Where the chimney's smoke leaves it (structure-local screen px), or Vector2.INF for a barn.
static func chimney_top(s: Structure) -> Vector2:
	var p := s.art
	if p.is_empty() or p.barn:
		return Vector2.INF
	if p.smithy:
		var f := _smithy_stack(s)
		return s._gp(f.get_center(), s.height + SMITHY_RISE + SMITHY_STACK_UP + 2.0)
	var r := s.footprint
	var ax: bool = p.along_x
	var a := lerpf(r.position.x if ax else r.position.y, r.end.x if ax else r.end.y, p.chimney_u)
	var bm: float = (r.get_center().y if ax else r.get_center().x) + CHIMNEY_FRONT
	return s._gp(_g(ax, a, bm), s.height + float(p.rise) + CHIMNEY_UP)


static func _draw_openings(s: Structure, p: Dictionary, h: float, eave_face: int, gable_face: int,
		timber_c: Dictionary, door_c: Dictionary, barn: bool) -> void:
	var door_face: int = p.door_face
	var door_u: float = p.door_u
	var big := h >= 22.0
	var w := 4.0 if big else 3.0
	var tall := 5.0 if big else 4.0
	var sill := minf(roundf(h * 0.36), h - DROP - BOARD - 3.0 - tall)
	var n := 0
	for face in [eave_face, gable_face]:
		var px := ArtKit.face_px(s, face)
		var spots: Array[float] = []
		if face == door_face:
			var dw := 8.0 if barn else 5.0
			_draw_door(s, face, door_u, dw, minf(roundf(h * (0.62 if barn else 0.55)), h - DROP - BOARD - 2.0),
				door_c[face], timber_c[face], barn)
			var side := 0.3 if px > 34.0 else 0.26
			for u in [door_u - side, door_u + side]:
				if u > 0.16 and u < 0.84:
					spots.append(u)
		elif face == eave_face and px > 34.0:
			spots.append_array([0.27, 0.73])
		else:
			spots.append(0.5)
		if barn:
			spots = spots.slice(0, 1)
		for u in spots:
			ArtKit.window(s, face, u, sill, w, tall, _window_lit(s, n), timber_c[face])
			n += 1


static func _draw_door(s: Structure, face: int, u: float, w: float, tall: float, wood: Color, timber: Color,
		barn: bool) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var du := w * 0.5 / px
	var fu := 1.0 / px
	ArtKit.face_quad(s, face, u - du - fu, u + du + fu, 0.0, tall + 1.0, timber)
	ArtKit.face_quad(s, face, u - du, u + du, 0.0, tall, wood)
	if barn:
		ArtKit.face_line(s, face, u - du, 0.0, u + du, tall, ArtKit.ink(0.7))
		ArtKit.face_line(s, face, u - du, tall, u + du, 0.0, ArtKit.ink(0.7))
		ArtKit.face_line(s, face, u, 0.0, u, tall, ArtKit.ink(0.7))
	else:
		ArtKit.face_line(s, face, u, 0.0, u, tall, ArtKit.ink(0.35))
		ArtKit.face_quad(s, face, u + du * 0.45, u + du * 0.45 + fu, tall * 0.45, tall * 0.45 + 1.0, ArtKit.GLOW_RIM,
			ArtKit.EMIT)


static func _draw_chimney(s: Structure, p: Dictionary, ax: bool, a0: float, a1: float, bm: float, half: float,
		top: float, rise: float) -> void:
	var a := lerpf(a0 + OVERHANG, a1 - OVERHANG, p.chimney_u)
	var hw := CHIMNEY_W * 0.5
	var b := bm + CHIMNEY_FRONT
	var cap := top + CHIMNEY_UP
	# Corners in the house frame: (a -/+ hw) x (b -/+ hw); the camera sees the +a and +b sides.
	var fa := a + hw
	var fb := b + hw
	var na := a - hw
	var nb := b - hw
	# The +b side faces the eave wall's way, the +a side the gable end's.
	var b_face := ArtKit.LEFT if ax else ArtKit.RIGHT
	var a_face := ArtKit.RIGHT if ax else ArtKit.LEFT
	for side in [[[_g(ax, na, fb), _g(ax, fa, fb)], b_face], [[_g(ax, fa, nb), _g(ax, fa, fb)], a_face]]:
		var g: Array = side[0]
		var face: int = side[1]
		var code := ArtKit.face_code(face)
		var c: Color = ArtKit.CHIMNEY[0] if face == ArtKit.RIGHT else ArtKit.CHIMNEY[1]
		var g0: Vector2 = g[0]
		var g1: Vector2 = g[1]
		var h0 := _roof_h(ax, g0, bm, half, top, rise) - 1.0
		var h1 := _roof_h(ax, g1, bm, half, top, rise) - 1.0
		ArtKit.poly(PackedVector2Array([s._gp(g0, h0), s._gp(g1, h1), s._gp(g1, cap), s._gp(g0, cap)]), c, code)
		for k in [5.0, 9.0]:
			ArtKit.line(s._gp(g0, cap - k), s._gp(g1, cap - k), ArtKit.ink(0.3))
		ArtKit.poly(PackedVector2Array([s._gp(g0, cap - 2.0), s._gp(g1, cap - 2.0), s._gp(g1, cap), s._gp(g0, cap)]),
			ArtKit.CHIMNEY_CAP if face == ArtKit.LEFT else ArtKit.CHIMNEY_CAP.lightened(0.1), code)
	ArtKit.poly(PackedVector2Array([s._gp(_g(ax, na, nb), cap), s._gp(_g(ax, fa, nb), cap), s._gp(_g(ax, fa, fb), cap),
		s._gp(_g(ax, na, fb), cap)]), ArtKit.CHIMNEY[2].darkened(0.5), ArtKit.INK)
	# Outline down the three visible edges.
	for g: Vector2 in [_g(ax, na, fb), _g(ax, fa, fb), _g(ax, fa, nb)]:
		ArtKit.line(s._gp(g, _roof_h(ax, g, bm, half, top, rise) - 1.0), s._gp(g, cap), ArtKit.ink(0.75))


## The tavern's front: windows on both floors, a door under an awning, and a hanging sign with a blue banner.
static func _tavern_front(s: Structure, h: float, eave_face: int, gable_face: int, timber_c: Dictionary,
		door_c: Dictionary) -> void:
	var n := 0
	for face in [eave_face, gable_face]:
		var spots: Array = [0.12, 0.38, 0.62, 0.88] if face == eave_face else [0.3, 0.7]
		for sill: float in [roundf(h * 0.16), roundf(h * 0.6)]:
			for u: float in spots:
				if face == eave_face and sill < h * 0.5 and absf(u - 0.5) < 0.2:
					continue
				ArtKit.window(s, face, u, sill, 4.0, 5.0, _window_lit(s, n), timber_c[face])
				n += 1
	var dh := roundf(h * 0.4)
	_draw_door(s, eave_face, 0.5, 7.0, dh, door_c[eave_face], timber_c[eave_face], false)
	# Awning: a slanted red board over the door, reaching out from the wall.
	var out := Vector2(0, 0.28) if s.art.along_x else Vector2(0.28, 0)
	var a0 := ArtKit.face_pt(s, eave_face, 0.36, dh + 5.0)
	var a1 := ArtKit.face_pt(s, eave_face, 0.64, dh + 5.0)
	var drop := Iso.ground_to_screen(out) + Vector2(0, 3)
	ArtKit.poly(PackedVector2Array([a0, a1, a1 + drop, a0 + drop]), ArtKit.RED_TILE[1], ArtKit.LIT_TOP)
	ArtKit.poly(PackedVector2Array([a0 + drop, a1 + drop, a1 + drop + Vector2(0, 2), a0 + drop + Vector2(0, 2)]),
		ArtKit.RED_TILE[3], ArtKit.face_code(eave_face))
	for k in 5:
		var q := ArtKit.face_pt(s, eave_face, lerpf(0.36, 0.64, (k + 0.5) / 5.0), dh + 5.0)
		ArtKit.line(q, q + drop, ArtKit.ink(0.25))
	# Hanging sign on a bracket at the front corner: a blue banner with a gold mug.
	var code := ArtKit.face_code(gable_face)
	var corner := ArtKit.face_pt(s, eave_face, 0.97, h * 0.75)
	var arm := corner + Vector2(5, 3)
	ArtKit.line(corner, arm, ArtKit.ink(0.8))
	var sg := arm + Vector2(-3, 1)
	ArtKit.poly(PackedVector2Array([sg, sg + Vector2(7, 0), sg + Vector2(7, 9), sg + Vector2(0, 9)]), ArtKit.BANNER[0], code)
	ArtKit.poly(PackedVector2Array([sg + Vector2(0, 9), sg + Vector2(7, 9), sg + Vector2(3.5, 11)]), ArtKit.BANNER[0], code)
	ArtKit.poly(PackedVector2Array([sg + Vector2(2, 3), sg + Vector2(5, 3), sg + Vector2(5, 7), sg + Vector2(2, 7)]),
		Structure.COL_GOLD, code)


# --- Blacksmith ------------------------------------------------------------------

const SMITHY_RISE := 14.0
const SMITHY_STACK := 0.45
const SMITHY_STACK_UP := 16.0
## Wooden shingles [lit, mid, dark, board, ridge, outline].
const ROOF_WOOD := [Color("8a6440"), Color("745234"), Color("5e4128"), Color("4a3220"), Color("a07a52"), Color("2a1a10")]


## The chimney's ground square at the blacksmith's far end.
static func _smithy_stack(s: Structure) -> Rect2:
	var r := s.footprint
	if s.art.along_x:
		return Rect2(Vector2(r.position.x + 0.05, r.position.y + (r.size.y - SMITHY_STACK) * 0.5),
			Vector2(SMITHY_STACK, SMITHY_STACK))
	return Rect2(Vector2(r.position.x + (r.size.x - SMITHY_STACK) * 0.5, r.position.y + 0.05),
		Vector2(SMITHY_STACK, SMITHY_STACK))


## Where the forge glows inside the open front (structure-local px), for the flame node.
static func forge_tip(s: Structure) -> Vector2:
	var face := ArtKit.LEFT if s.art.along_x else ArtKit.RIGHT
	return ArtKit.face_pt(s, face, 0.3, 4.0)


static func _smithy(s: Structure) -> void:
	var h := s.height
	var ax: bool = s.art.along_x
	var open_face := ArtKit.LEFT if ax else ArtKit.RIGHT
	var end_face := ArtKit.RIGHT if ax else ArtKit.LEFT
	var plank := [ArtKit.PLANK[0].darkened(0.25), ArtKit.PLANK[1].darkened(0.3)]
	# The open front: dark inside, the forge's hearth glowing, an anvil and hanging tools; a plank end wall.
	ArtKit.face_quad(s, open_face, 0.0, 1.0, 0.0, h, ArtKit.INTERIOR)
	ArtKit.face_quad(s, open_face, 0.0, 1.0, 0.0, 3.0, ArtKit.INTERIOR_FLOOR)
	var px := maxf(ArtKit.face_px(s, open_face), 1.0)
	ArtKit.face_quad(s, open_face, 0.14, 0.46, 2.0, 9.0, ArtKit.STONE[1].darkened(0.2))
	ArtKit.face_quad(s, open_face, 0.2, 0.4, 3.0, 7.0, ArtKit.FURNACE[1], ArtKit.EMIT)
	ArtKit.face_quad(s, open_face, 0.24, 0.36, 3.0, 5.0, ArtKit.FURNACE[0], ArtKit.EMIT)
	ArtKit.face_quad(s, open_face, 0.6, 0.78, 4.0, 6.0, ArtKit.IRON)
	ArtKit.face_quad(s, open_face, 0.66, 0.72, 1.0, 4.0, ArtKit.IRON.darkened(0.3))
	for k in 4:
		var u := 0.52 + k * 3.0 / px
		ArtKit.face_line(s, open_face, u, h - 6.0, u, h - 12.0, Color(0.55, 0.52, 0.5, 0.9))
	var post := 2.0 / px
	for u: float in [0.0, 0.5, 1.0 - post]:
		ArtKit.face_quad(s, open_face, u, u + post, 0.0, h, plank[1])
	ArtKit.face_quad(s, open_face, 0.0, 1.0, h - 3.0, h, plank[1])
	ArtKit.face_quad(s, end_face, 0.0, 1.0, 0.0, h, plank[0])
	var seams := maxi(int(ArtKit.face_px(s, end_face) / 3.0), 1)
	for i in range(1, seams):
		var u := float(i) / seams
		ArtKit.face_line(s, end_face, u, 0.0, u, h, ArtKit.ink(0.3))
	ArtKit.face_line(s, end_face, 0.0, 0.0, 1.0, 0.0, ArtKit.ink(0.75))
	ArtKit.flush(s)
	# A plain wooden gable roof.
	var r := s.footprint
	var a0: float = (r.position.x if ax else r.position.y) - OVERHANG
	var a1: float = (r.end.x if ax else r.end.y) + OVERHANG
	var b0: float = r.position.y if ax else r.position.x
	var b1: float = r.end.y if ax else r.end.x
	var bm := (b0 + b1) * 0.5
	var half := (b1 - b0) * 0.5
	var top := h + SMITHY_RISE
	var eave := h - DROP
	var shoulder := top - (SMITHY_RISE + DROP) * half / (half + OVERHANG)
	var ridge0 := s._gp(_g(ax, a0, bm), top)
	var ridge1 := s._gp(_g(ax, a1, bm), top)
	var front0 := s._gp(_g(ax, a0, b1 + OVERHANG), eave)
	var front1 := s._gp(_g(ax, a1, b1 + OVERHANG), eave)
	var back0 := s._gp(_g(ax, a0, b0 - OVERHANG), eave)
	var back1 := s._gp(_g(ax, a1, b0 - OVERHANG), eave)
	ArtKit.poly(PackedVector2Array([back0, back1, ridge1, ridge0]), ROOF_WOOD[2], ArtKit.LIT_TOP)
	ArtKit.face_quad(s, end_face, 0.0, 1.0, h, shoulder, plank[0])
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, end_face, 0.0, shoulder), ArtKit.face_pt(s, end_face, 1.0, shoulder),
		ArtKit.face_pt(s, end_face, 0.5, top)]), plank[0], ArtKit.face_code(end_face))
	ArtKit.flush(s)
	ArtKit.poly(PackedVector2Array([front0, front1, ridge1, ridge0]), ROOF_WOOD[1], ArtKit.LIT_TOP)
	for i in range(1, 6):
		var k := i / 6.0
		ArtKit.line(ridge0.lerp(front0, k), ridge1.lerp(front1, k), ArtKit.ink(0.3))
	var board := Vector2(0, BOARD)
	ArtKit.poly(PackedVector2Array([front0, front1, front1 + board, front0 + board]), ROOF_WOOD[3], ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([ridge1, front1, front1 + board, ridge1 + board]), ROOF_WOOD[3], ArtKit.LIT_RIGHT)
	ArtKit.line(ridge0, ridge1, ArtKit.ink(0.3, true))
	var ol: Color = ROOF_WOOD[5]
	for e in [[back0, back1], [back0, ridge0], [ridge0, front0], [front0 + board, front1 + board],
			[front1 + board, ridge1 + board]]:
		ArtKit.line(e[0], e[1], ol)
	ArtKit.flush(s)
	# The tall stone chimney at the far end, standing through the roof.
	var f := _smithy_stack(s)
	var g0 := f.position
	var g1 := f.end
	var gl := Vector2(g0.x, g1.y)
	var gr := Vector2(g1.x, g0.y)
	var stack_top := top + SMITHY_STACK_UP
	ArtKit.poly(PackedVector2Array([s._gp(gl, 0.0), s._gp(g1, 0.0), s._gp(g1, stack_top), s._gp(gl, stack_top)]),
		ArtKit.STONE[1], ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(gr, 0.0), s._gp(g1, 0.0), s._gp(g1, stack_top), s._gp(gr, stack_top)]),
		ArtKit.STONE[0], ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([s._gp(g0, stack_top), s._gp(gr, stack_top), s._gp(g1, stack_top), s._gp(gl, stack_top)]),
		ArtKit.VOID, ArtKit.INK)
	for k in range(1, int(stack_top / 5.0)):
		ArtKit.line(s._gp(gl, k * 5.0), s._gp(g1, k * 5.0), ArtKit.ink(0.3))
		ArtKit.line(s._gp(g1, k * 5.0), s._gp(gr, k * 5.0), ArtKit.ink(0.3))
	ArtKit.line(s._gp(gl, 0.0), s._gp(gl, stack_top), ArtKit.ink(0.6))
	ArtKit.line(s._gp(g1, 0.0), s._gp(g1, stack_top), ArtKit.ink(0.15, true))
	ArtKit.flush(s)


## Height of the roof surface over a ground point (px), from the ridge down either slope.
static func _roof_h(ax: bool, g: Vector2, bm: float, half: float, top: float, rise: float) -> float:
	var b := g.y if ax else g.x
	return top - (rise + DROP) * absf(b - bm) / (half + OVERHANG)


## Window n's light: the house's own window flags when it has them (damage puts them out), else a hashed guess.
static func _window_lit(s: Structure, n: int) -> bool:
	if s._windows.is_empty():
		return ArtKit.hash01(s.rng.seed, 60 + n) < 0.65
	return s._windows[n % s._windows.size()][3]


## Ground point from the house's own frame (a along the ridge, b across it).
static func _g(ax: bool, a: float, b: float) -> Vector2:
	return Vector2(a, b) if ax else Vector2(b, a)
