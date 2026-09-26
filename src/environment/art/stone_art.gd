class_name StoneArt
extends RefCounted
## Aldermere's stonework after concepts/TOWN REF/Town Visual Upgrade.png: curtain walls, towers, gates and the
## Citadel (CASTLE_WALL, KEEP, GATE).
## - Walls: warm grey blocks, each its own shade, in 6 px courses with dark mortar; a pale walkway with a lit
##   coping edge; chunky merlons (a curtain wall piece only along its long edges); lit arrow slits; a black
##   portcullis in a gate.
## - Ornament: some wall pieces carry a torch on the walkway, whose flame animates on its own child node (see
##   Structure._draw_flame) so the piece stays cached. Towers hang a blue banner with a white cross on each wall wide
##   enough for one, and the Citadel keep flies a flag; banners and flag live on Structure's _banner node, which
##   redraws only as they wave.
## Colours are unlit: the structure's shader lights them (see ArtKit).

## Block course height and length, px; merlon height, px.
const COURSE := 5.0
const BLOCK := 9.0
const MERLON_H := 7.0
## Merlon size (ground units) on walls and gates, and on towers and keeps.
const MERLON_WALL := 0.25
const MERLON_TOWER := 0.32
## A wall wide enough (px) for a banner.
const BANNER_FACE := 36.0


static func plan(s: Structure) -> Dictionary:
	return {"torch": s.kind == Structure.Kind.CASTLE_WALL and s.role == &"wall" and ArtKit.hash01(s.rng.seed, 11) < 0.34}


## Two layers: the stone (faces, blocks, walkway, merlons, then mortar lines over it all), then what is set into
## the walls (slits, a gate's portcullis, a Citadel door, a torch post) so the mortar never crosses them.
static func draw(s: Structure) -> void:
	ArtKit.begin()
	var h := s.height
	var face_c := {ArtKit.RIGHT: ArtKit.STONE[0], ArtKit.LEFT: ArtKit.STONE[1]}
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var fc: Color = face_c[face]
		ArtKit.masonry(s, face, 0.0, h, fc, 0, COURSE, BLOCK)
		# Lit coping along the top of the wall.
		ArtKit.face_quad(s, face, 0.0, 1.0, h - 2.0, h, fc.lightened(0.14))
	var up := Vector2(0, -h)
	ArtKit.poly(PackedVector2Array([s._s[0] + up, s._s[1] + up, s._s[2] + up, s._s[3] + up]), ArtKit.STONE_TOP,
		ArtKit.LIT_TOP)
	_draw_merlons(s)
	# Mortar courses over the fills (merlons stand above the walls, so the lines never cross them).
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		ArtKit.mortar_lines(s, face, 0.0, h, COURSE)
		ArtKit.face_line(s, face, 0.0, 0.0, 1.0, 0.0, ArtKit.ink(0.6))
	if s.kind != Structure.Kind.CASTLE_WALL:
		# A lit corner on towers and gates; a curtain wall is built of pieces, and the line would mark every seam.
		ArtKit.line(s._s[2], s._s[2] + up, ArtKit.ink(0.18, true))
	ArtKit.flush(s)

	_draw_slits(s)
	if s.kind == Structure.Kind.GATE:
		var gate_face := ArtKit.LEFT if s.footprint.size.x >= s.footprint.size.y else ArtKit.RIGHT
		_draw_portcullis(s, gate_face, 0.32, 0.68, roundf(h * 0.85), face_c)
		_draw_gate_stones(s, gate_face)
	elif s.art_tag == &"gate":
		_draw_arched_door(s, ArtKit.LEFT, 0.5, 12.0, roundf(h * 0.5))
	if s.art.get("torch", false):
		var base := s._gp(s.center(), h)
		ArtKit.poly(PackedVector2Array([base + Vector2(-1, 0), base + Vector2(1, 0), base + Vector2(1, -7),
			base + Vector2(-1, -7)]), ArtKit.TIMBER_DARK, ArtKit.LIT_RIGHT)
		ArtKit.poly(PackedVector2Array([base + Vector2(-2, -7), base + Vector2(2, -7), base + Vector2(2, -8),
			base + Vector2(-2, -8)]), ArtKit.IRON, ArtKit.LIT_RIGHT)
	ArtKit.flush(s)


## Where a wall torch's flame sits (structure-local px).
static func torch_tip(s: Structure) -> Vector2:
	return s._gp(s.center(), s.height) + Vector2(0, -8)


## Banners on every tower wall wide enough, and the keep's flag, drawn onto `ci` (the structure's banner node,
## which has no lighting shader: the cloth is tinted here by the ambient light and the world's tint).
static func draw_banners(s: Structure, ci: CanvasItem, time: float, tint: Color) -> void:
	ArtKit.begin()
	var blue := ArtKit.BANNER[0].lerp(Structure.COL_CHAR, s.scorch) * tint
	var blue_hi := ArtKit.BANNER[1].lerp(Structure.COL_CHAR, s.scorch) * tint
	var cross := ArtKit.BANNER[2].lerp(Structure.COL_CHAR, s.scorch) * tint
	var gold := Structure.COL_GOLD.lerp(Structure.COL_CHAR, s.scorch) * tint
	var e := ArtKit.EMIT
	var wave := roundf(sin(time * 3.0))
	var length := clampf(roundf(s.max_height * 0.26), 16.0, 30.0)
	var top := roundf(s.max_height * 0.82)
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var px := ArtKit.face_px(s, face)
		if px < BANNER_FACE:
			continue
		var du := 4.0 / px
		var um := 0.5
		var ul := um - du
		var ur := um + du
		var bot := top - length + 4.0
		var sway := Vector2(wave, 0)
		var p := func(u: float, hh: float) -> Vector2: return ArtKit.face_pt(s, face, u, hh)
		ArtKit.poly(PackedVector2Array([p.call(ul, top), p.call(ur, top), p.call(ur, bot) + sway, p.call(ul, bot) + sway]),
			blue, e)
		ArtKit.poly(PackedVector2Array([p.call(ul, bot) + sway, p.call(um, bot) + sway, p.call(ul, bot - 4.0) + sway]),
			blue, e)
		ArtKit.poly(PackedVector2Array([p.call(um, bot) + sway, p.call(ur, bot) + sway, p.call(ur, bot - 4.0) + sway]),
			blue, e)
		ArtKit.poly(PackedVector2Array([p.call(ul, top), p.call(ul + 1.0 / px, top), p.call(ul + 1.0 / px, bot) + sway,
			p.call(ul, bot) + sway]), blue_hi, e)
		# White cross.
		var cy := top - 4.0
		ArtKit.poly(PackedVector2Array([p.call(um - 1.0 / px, cy), p.call(um + 1.0 / px, cy),
			p.call(um + 1.0 / px, cy - 10.0) + sway * 0.5, p.call(um - 1.0 / px, cy - 10.0) + sway * 0.5]), cross, e)
		ArtKit.poly(PackedVector2Array([p.call(um - 3.0 / px, cy - 3.0), p.call(um + 3.0 / px, cy - 3.0),
			p.call(um + 3.0 / px, cy - 5.0), p.call(um - 3.0 / px, cy - 5.0)]), cross, e)
		# Gold rod with round finials.
		ArtKit.poly(PackedVector2Array([p.call(ul - 1.5 / px, top + 1.0), p.call(ur + 1.5 / px, top + 1.0),
			p.call(ur + 1.5 / px, top), p.call(ul - 1.5 / px, top)]), gold.darkened(0.2), e)
		for u in [ul - 1.5 / px, ur + 1.5 / px]:
			var f: Vector2 = p.call(u, top + 1.0)
			ArtKit.poly(PackedVector2Array([f + Vector2(-1, -1), f + Vector2(1, -1), f + Vector2(1, 1), f + Vector2(-1, 1)]),
				gold, e)
	if s.art_tag == &"keep":
		# A tall pole on a wooden stand in the middle of the roof, a banner hanging from its crossbar.
		var foot := s._gp(s.center(), s.height)
		var wood := ArtKit.TIMBER.lerp(Structure.COL_CHAR, s.scorch) * tint
		var stand := ArtKit.PLANK[0].lerp(Structure.COL_CHAR, s.scorch) * tint
		ArtKit.poly(PackedVector2Array([foot + Vector2(-5, 1), foot + Vector2(5, 1), foot + Vector2(2, -4),
			foot + Vector2(-2, -4)]), stand, e)
		var pole_top := foot + Vector2(0, -34)
		ArtKit.poly(PackedVector2Array([foot + Vector2(0, -4), foot + Vector2(2, -4), pole_top + Vector2(2, 0),
			pole_top]), wood, e)
		ArtKit.poly(PackedVector2Array([pole_top + Vector2(-5, 2), pole_top + Vector2(7, 2), pole_top + Vector2(7, 4),
			pole_top + Vector2(-5, 4)]), wood, e)
		ArtKit.poly(PackedVector2Array([pole_top + Vector2(-1, -2), pole_top + Vector2(3, -2), pole_top + Vector2(3, 0),
			pole_top + Vector2(-1, 0)]), gold, e)
		var f0 := pole_top + Vector2(-4, 4)
		var sway := Vector2(roundf(sin(time * 4.0)), 0)
		var sway2 := Vector2(roundf(sin(time * 4.0 + 1.6)), 0)
		ArtKit.poly(PackedVector2Array([f0, f0 + Vector2(10, 0), f0 + Vector2(10, 14) + sway, f0 + Vector2(0, 14) + sway]),
			blue, e)
		ArtKit.poly(PackedVector2Array([f0 + Vector2(0, 14) + sway, f0 + Vector2(5, 14) + sway,
			f0 + Vector2(0, 18) + sway2]), blue, e)
		ArtKit.poly(PackedVector2Array([f0 + Vector2(5, 14) + sway, f0 + Vector2(10, 14) + sway,
			f0 + Vector2(10, 18) + sway2]), blue, e)
		ArtKit.poly(PackedVector2Array([f0, f0 + Vector2(1, 0), f0 + Vector2(1, 14) + sway, f0 + Vector2(0, 14) + sway]),
			blue_hi, e)
		ArtKit.poly(PackedVector2Array([f0 + Vector2(4, 2), f0 + Vector2(6, 2), f0 + Vector2(6, 12) + sway,
			f0 + Vector2(4, 12) + sway]), cross, e)
		ArtKit.poly(PackedVector2Array([f0 + Vector2(2, 5), f0 + Vector2(8, 5), f0 + Vector2(8, 7), f0 + Vector2(2, 7)]),
			cross, e)
	ArtKit.flush(ci)


## Merlons along the edges, the back edges first so the front ones overlap them. A curtain wall only crenellates
## its two long edges: its short ends are where the next piece joins on.
static func _draw_merlons(s: Structure) -> void:
	var r := s.footprint
	var size := MERLON_TOWER if s.kind == Structure.Kind.KEEP else MERLON_WALL
	var along_x := r.size.x >= r.size.y
	var wall := s.kind == Structure.Kind.CASTLE_WALL
	var edges := []
	if not wall or along_x:
		edges.append([r.position, Vector2(r.end.x, r.position.y)])
	if not wall or not along_x:
		edges.append([r.position, Vector2(r.position.x, r.end.y)])
	if not wall or along_x:
		edges.append([Vector2(r.position.x, r.end.y), r.end])
	if not wall or not along_x:
		edges.append([Vector2(r.end.x, r.position.y), r.end])
	var h0 := s.height
	var h1 := s.height + MERLON_H
	var cap := ArtKit.STONE_TOP.lightened(0.12)
	for e in edges:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var n := maxi(int(a.distance_to(b) / (size * 2.0)), 1)
		for i in n + 1:
			var c := a.lerp(b, float(i) / n)
			var g0 := (c - Vector2(size, size) * 0.5).clamp(r.position, r.end - Vector2(size, size))
			var g1 := g0 + Vector2(size, size)
			var gl := Vector2(g0.x, g1.y)
			var gr := Vector2(g1.x, g0.y)
			ArtKit.poly(PackedVector2Array([s._gp(gl, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gl, h1)]),
				ArtKit.STONE[1], ArtKit.LIT_LEFT)
			ArtKit.poly(PackedVector2Array([s._gp(gr, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gr, h1)]),
				ArtKit.STONE[0], ArtKit.LIT_RIGHT)
			ArtKit.poly(PackedVector2Array([s._gp(g0, h1), s._gp(gr, h1), s._gp(g1, h1), s._gp(gl, h1)]), cap,
				ArtKit.LIT_TOP)


## Arrow slits from the structure's window list (their lit flags go dark under damage).
static func _draw_slits(s: Structure) -> void:
	for w in s._windows:
		var hh: float = w[2] * s.max_height
		if hh > s.height - 6.0:
			continue
		var face: int = w[0]
		var px := maxf(ArtKit.face_px(s, face), 1.0)
		var u: float = w[1]
		if w[3]:
			ArtKit.face_quad(s, face, u - 1.0 / px, u + 1.0 / px, hh - 5.0, hh, ArtKit.GLOW_RIM, ArtKit.EMIT)
			ArtKit.face_quad(s, face, u - 1.0 / px, u, hh - 4.0, hh - 1.0, ArtKit.GLOW, ArtKit.EMIT)
		else:
			ArtKit.face_quad(s, face, u - 1.0 / px, u + 1.0 / px, hh - 5.0, hh, ArtKit.WINDOW_OFF)


## A dark gateway in the wall with a lighter stone surround and a raised portcullis's faint bars.
static func _draw_portcullis(s: Structure, face: int, u0: float, u1: float, tall: float, face_c: Dictionary) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var fc: Color = face_c[face]
	ArtKit.face_quad(s, face, u0 - 2.0 / px, u1 + 2.0 / px, 0.0, tall + 2.0, fc.lightened(0.14))
	ArtKit.face_quad(s, face, u0, u1, 0.0, tall, ArtKit.VOID, ArtKit.EMIT)
	var bars := maxi(int((u1 - u0) * px / 7.0), 2)
	for i in range(1, bars):
		var u := lerpf(u0, u1, float(i) / bars)
		ArtKit.face_line(s, face, u, tall * 0.35, u, tall, Color(0.35, 0.3, 0.28, 0.9))
	ArtKit.face_line(s, face, u0, tall * 0.62, u1, tall * 0.62, Color(0.35, 0.3, 0.28, 0.9))
	ArtKit.face_line(s, face, u0, tall * 0.35, u1, tall * 0.35, Color(0.3, 0.25, 0.22, 0.9))


## Rough stone blocks at the gateway's feet on the outer side, as in the reference, two either side of the way
## through.
static func _draw_gate_stones(s: Structure, face: int) -> void:
	var r := s.footprint
	for u: float in [0.2, 0.27, 0.73, 0.8]:
		var g: Vector2
		var along: Vector2
		var out: Vector2
		if face == ArtKit.LEFT:
			g = Vector2(lerpf(r.position.x, r.end.x, u), r.end.y)
			along = Vector2(1, 0)
			out = Vector2(0, 1)
		else:
			g = Vector2(r.end.x, lerpf(r.position.y, r.end.y, u))
			along = Vector2(0, 1)
			out = Vector2(1, 0)
		var hgt := 4.0 + float(ArtKit.pick(s.rng.seed, 170 + int(u * 100.0), 3))
		var g0 := g - along * 0.09 + out * 0.04
		var g1 := g + along * 0.09 + out * 0.26
		var lo := Vector2(minf(g0.x, g1.x), minf(g0.y, g1.y))
		var hi := Vector2(maxf(g0.x, g1.x), maxf(g0.y, g1.y))
		_block(s, lo, hi, hgt)


## An iso block of stone over the ground rect lo..hi, `hgt` px tall, with a light top and an outline.
static func _block(s: Structure, lo: Vector2, hi: Vector2, hgt: float) -> void:
	var gl := Vector2(lo.x, hi.y)
	var gr := Vector2(hi.x, lo.y)
	ArtKit.poly(PackedVector2Array([s._gp(gl, 0.0), s._gp(hi, 0.0), s._gp(hi, hgt), s._gp(gl, hgt)]), ArtKit.STONE[1],
		ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(gr, 0.0), s._gp(hi, 0.0), s._gp(hi, hgt), s._gp(gr, hgt)]), ArtKit.STONE[0],
		ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([s._gp(lo, hgt), s._gp(gr, hgt), s._gp(hi, hgt), s._gp(gl, hgt)]), ArtKit.STONE_TOP,
		ArtKit.LIT_TOP)
	ArtKit.line(s._gp(gl, 0.0), s._gp(hi, 0.0), ArtKit.ink(0.5))
	ArtKit.line(s._gp(hi, 0.0), s._gp(gr, 0.0), ArtKit.ink(0.5))
	ArtKit.line(s._gp(hi, 0.0), s._gp(hi, hgt), ArtKit.ink(0.3))


## The Citadel's great door: a dark arch in a pale surround, up a wide flight of steps.
static func _draw_arched_door(s: Structure, face: int, u: float, w: float, tall: float) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var du := w * 0.5 / px
	var base := 5.0
	var jamb := ArtKit.STONE[0].lightened(0.16)
	var code := ArtKit.face_code(face)
	ArtKit.face_quad(s, face, u - du - 3.0 / px, u + du + 3.0 / px, base, base + tall, jamb)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, face, u - du - 3.0 / px, base + tall),
		ArtKit.face_pt(s, face, u + du + 3.0 / px, base + tall), ArtKit.face_pt(s, face, u, base + tall + w * 0.6 + 3.0)]),
		jamb, code)
	ArtKit.face_quad(s, face, u - du, u + du, base, base + tall, ArtKit.VOID, ArtKit.EMIT)
	ArtKit.poly(PackedVector2Array([ArtKit.face_pt(s, face, u - du, base + tall), ArtKit.face_pt(s, face, u + du, base + tall),
		ArtKit.face_pt(s, face, u, base + tall + w * 0.6)]), ArtKit.VOID, ArtKit.EMIT)
	ArtKit.face_line(s, face, u, base, u, base + tall, Color(0.3, 0.22, 0.16, 0.8))
	# Five steps, each wider than the one above, reaching out of the wall's foot.
	for k in 5:
		var grow := (5.0 - k) * 3.0 / px
		ArtKit.face_quad(s, face, u - du - 3.0 / px - grow, u + du + 3.0 / px + grow, k, k + 1.0,
			ArtKit.STONE[0].lightened(0.12 - k * 0.02))
		ArtKit.face_line(s, face, u - du - 3.0 / px - grow, k + 1.0, u + du + 3.0 / px + grow, k + 1.0, ArtKit.ink(0.3))
