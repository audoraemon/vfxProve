class_name StoneArt
extends RefCounted
## Aldermere's stonework after concepts/TOWN REF/Town Visual Upgrade.png: curtain walls, towers, gates and the
## Citadel (CASTLE_WALL, KEEP, GATE).
## - Walls: warm grey blocks, each its own shade, in 6 px courses with dark mortar; a pale walkway with a lit
##   coping edge; chunky merlons along every edge; lit arrow slits; a black portcullis in a gate.
## - Ornament: some wall pieces carry a torch on the walkway, whose flame animates on its own child node (see
##   Structure._draw_flame) so the piece stays cached. Towers hang a blue banner with a white cross on each wall wide
##   enough for one, and the Citadel keep flies a flag; banners and flag live on Structure's _banner node, which
##   redraws only as they wave.

## Block course height and length, px; merlon height, px.
const COURSE := 6.0
const BLOCK := 12.0
const MERLON_H := 7.0
## Merlon size (ground units) on walls and gates, and on towers and keeps.
const MERLON_WALL := 0.26
const MERLON_TOWER := 0.34
## A wall wide enough (px) for a banner.
const BANNER_FACE := 36.0


static func plan(s: Structure) -> Dictionary:
	return {"torch": s.kind == Structure.Kind.CASTLE_WALL and s.role == &"wall" and ArtKit.hash01(s.rng.seed, 11) < 0.34}


## Two layers: the stone (faces, blocks, walkway, merlons, then mortar lines over it all), then what is set into
## the walls (slits, a gate's portcullis, a Citadel door, a torch post) so the mortar never crosses them.
static func draw(s: Structure, light: Color, dir: Vector2) -> void:
	ArtKit.begin()
	var h := s.height
	var face_c := {ArtKit.RIGHT: _lit(s, ArtKit.STONE[0], ArtKit.RIGHT, light, dir),
		ArtKit.LEFT: _lit(s, ArtKit.STONE[1], ArtKit.LEFT, light, dir)}
	var top_c := _lit(s, ArtKit.STONE_TOP, 0, light, dir)
	var sd := s.rng.seed
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var fc: Color = face_c[face]
		ArtKit.face_quad(s, face, 0.0, 1.0, 0.0, h, fc.darkened(0.3))
		var px := maxf(ArtKit.face_px(s, face), 1.0)
		var rows := ceili(h / COURSE)
		for row in rows:
			var y0 := row * COURSE
			var y1 := minf(y0 + COURSE, h)
			var shift := BLOCK * 0.5 if row % 2 == 1 else 0.0
			var i := 0
			var x := -shift
			while x < px:
				var x0 := maxf(x, 0.0)
				var x1 := minf(x + BLOCK, px)
				if x1 - x0 >= 2.0:
					var tint := (ArtKit.hash01(sd, face * 100003 + row * 211 + i) - 0.5) * 0.16
					var bc := fc.lightened(tint) if tint > 0.0 else fc.darkened(-tint)
					ArtKit.face_quad(s, face, (x0 + (1.0 if x0 > 0.0 else 0.0)) / px, x1 / px, y0 + 1.0, y1, bc)
				x += BLOCK
				i += 1
		# Lit coping along the top of the wall.
		ArtKit.face_quad(s, face, 0.0, 1.0, h - 2.0, h, fc.lightened(0.14))
	ArtKit.poly(PackedVector2Array([s._s[0] + Vector2(0, -h), s._s[1] + Vector2(0, -h), s._s[2] + Vector2(0, -h),
		s._s[3] + Vector2(0, -h)]), top_c)
	_draw_merlons(s, face_c, top_c)
	# Mortar: joints between the blocks, over the fills (merlons stand above the walls, so they never cross).
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var mc: Color = (face_c[face] as Color).darkened(0.38)
		var px := maxf(ArtKit.face_px(s, face), 1.0)
		var rows := ceili(h / COURSE)
		for row in range(1, rows):
			ArtKit.face_line(s, face, 0.0, row * COURSE, 1.0, row * COURSE, mc)
		ArtKit.face_line(s, face, 0.0, 0.0, 1.0, 0.0, ArtKit.OUTLINE_STONE)
	if s.kind != Structure.Kind.CASTLE_WALL:
		# A lit corner on towers and gates; a curtain wall is built of pieces, and the line would mark every seam.
		ArtKit.line(s._s[2], s._s[2] + Vector2(0, -h), (face_c[ArtKit.RIGHT] as Color).lightened(0.1))
	ArtKit.flush(s)

	_draw_slits(s, light)
	if s.kind == Structure.Kind.GATE:
		_draw_portcullis(s, 3 if s.footprint.size.x >= s.footprint.size.y else 1, 0.3, 0.7, roundf(h * 0.6), face_c, false)
	elif s.art_tag == &"gate":
		_draw_portcullis(s, ArtKit.LEFT, 0.36, 0.64, roundf(h * 0.55), face_c, true)
	if s.art.get("torch", false):
		var base := s._gp(s.center(), h)
		ArtKit.poly(PackedVector2Array([base + Vector2(-1, 0), base + Vector2(1, 0), base + Vector2(1, -7),
			base + Vector2(-1, -7)]), ArtKit.TIMBER_DARK)
		ArtKit.poly(PackedVector2Array([base + Vector2(-2, -7), base + Vector2(2, -7), base + Vector2(2, -8),
			base + Vector2(-2, -8)]), ArtKit.IRON)
	ArtKit.flush(s)


## Where a wall torch's flame sits (structure-local px).
static func torch_tip(s: Structure) -> Vector2:
	return s._gp(s.center(), s.height) + Vector2(0, -8)


## Banners on every tower wall wide enough, and the keep's flag, drawn onto `ci` (the structure's banner node).
static func draw_banners(s: Structure, ci: CanvasItem, time: float, ambient: float) -> void:
	ArtKit.begin()
	var tint := Color(ambient, ambient, ambient)
	var blue := ArtKit.BANNER[0].lerp(Structure.COL_CHAR, s.scorch) * tint
	var blue_hi := ArtKit.BANNER[1].lerp(Structure.COL_CHAR, s.scorch) * tint
	var cross := ArtKit.BANNER[2].lerp(Structure.COL_CHAR, s.scorch) * tint
	var gold := Structure.COL_GOLD.lerp(Structure.COL_CHAR, s.scorch) * tint
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
			blue)
		ArtKit.poly(PackedVector2Array([p.call(ul, bot) + sway, p.call(um, bot) + sway, p.call(ul, bot - 4.0) + sway]), blue)
		ArtKit.poly(PackedVector2Array([p.call(um, bot) + sway, p.call(ur, bot) + sway, p.call(ur, bot - 4.0) + sway]), blue)
		ArtKit.poly(PackedVector2Array([p.call(ul, top), p.call(ul + 1.0 / px, top), p.call(ul + 1.0 / px, bot) + sway,
			p.call(ul, bot) + sway]), blue_hi)
		# White cross.
		var cy := top - 4.0
		ArtKit.poly(PackedVector2Array([p.call(um - 1.0 / px, cy), p.call(um + 1.0 / px, cy),
			p.call(um + 1.0 / px, cy - 10.0) + sway * 0.5, p.call(um - 1.0 / px, cy - 10.0) + sway * 0.5]), cross)
		ArtKit.poly(PackedVector2Array([p.call(um - 3.0 / px, cy - 3.0), p.call(um + 3.0 / px, cy - 3.0),
			p.call(um + 3.0 / px, cy - 5.0), p.call(um - 3.0 / px, cy - 5.0)]), cross)
		# Gold rod with round finials.
		ArtKit.poly(PackedVector2Array([p.call(ul - 1.5 / px, top + 1.0), p.call(ur + 1.5 / px, top + 1.0),
			p.call(ur + 1.5 / px, top), p.call(ul - 1.5 / px, top)]), gold.darkened(0.2))
		for u in [ul - 1.5 / px, ur + 1.5 / px]:
			var f: Vector2 = p.call(u, top + 1.0)
			ArtKit.poly(PackedVector2Array([f + Vector2(-1, -1), f + Vector2(1, -1), f + Vector2(1, 1), f + Vector2(-1, 1)]),
				gold)
	if s.art_tag == &"keep":
		# Flag pole from the middle of the roof, flag streaming to the right.
		var foot := s._gp(s.center(), s.height)
		var pole_top := foot + Vector2(0, -26)
		ArtKit.poly(PackedVector2Array([foot + Vector2(0, 0), foot + Vector2(1, 0), pole_top + Vector2(1, 0), pole_top]),
			ArtKit.TIMBER.lerp(Structure.COL_CHAR, s.scorch) * tint)
		var w1 := roundf(sin(time * 4.0))
		var w2 := roundf(sin(time * 4.0 + 1.6))
		var f0 := pole_top + Vector2(1, 1)
		ArtKit.poly(PackedVector2Array([f0, f0 + Vector2(6, w1), f0 + Vector2(6, 8 + w1), f0 + Vector2(0, 8)]), blue)
		ArtKit.poly(PackedVector2Array([f0 + Vector2(6, w1), f0 + Vector2(12, w2), f0 + Vector2(12, 8 + w2),
			f0 + Vector2(6, 8 + w1)]), blue_hi)
		ArtKit.poly(PackedVector2Array([f0 + Vector2(4, w1 - 0), f0 + Vector2(6, w1), f0 + Vector2(6, 8 + w1),
			f0 + Vector2(4, 8)]), cross)
		ArtKit.poly(PackedVector2Array([f0 + Vector2(0, 3), f0 + Vector2(12, 3 + w2), f0 + Vector2(12, 5 + w2),
			f0 + Vector2(0, 5)]), cross)
		ArtKit.poly(PackedVector2Array([pole_top + Vector2(-1, -2), pole_top + Vector2(2, -2), pole_top + Vector2(2, 0),
			pole_top + Vector2(-1, 0)]), gold)
	ArtKit.flush(ci)


## Merlons along the edges, the back edges first so the front ones overlap them. A curtain wall only crenellates
## its two long edges: its short ends are where the next piece joins on.
static func _draw_merlons(s: Structure, face_c: Dictionary, top_c: Color) -> void:
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
	var left: Color = face_c[ArtKit.LEFT]
	var right: Color = face_c[ArtKit.RIGHT]
	var cap := top_c.lightened(0.12)
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
			ArtKit.poly(PackedVector2Array([s._gp(gl, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gl, h1)]), left)
			ArtKit.poly(PackedVector2Array([s._gp(gr, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gr, h1)]), right)
			ArtKit.poly(PackedVector2Array([s._gp(g0, h1), s._gp(gr, h1), s._gp(g1, h1), s._gp(gl, h1)]), cap)


## Arrow slits from the structure's window list (their lit flags go dark under damage).
static func _draw_slits(s: Structure, light: Color) -> void:
	var dark := ArtKit.WINDOW_OFF.lerp(Color(light.r, light.g, light.b), 0.2)
	for w in s._windows:
		var hh: float = w[2] * s.max_height
		if hh > s.height - 6.0:
			continue
		var face: int = w[0]
		var px := maxf(ArtKit.face_px(s, face), 1.0)
		var u: float = w[1]
		if w[3]:
			ArtKit.face_quad(s, face, u - 1.0 / px, u + 1.0 / px, hh - 5.0, hh, ArtKit.GLOW_RIM)
			ArtKit.face_quad(s, face, u - 1.0 / px, u, hh - 4.0, hh - 1.0, ArtKit.GLOW)
		else:
			ArtKit.face_quad(s, face, u - 1.0 / px, u + 1.0 / px, hh - 5.0, hh, dark)


## A black gateway with an iron portcullis, a stone lintel and jambs; `steps` adds stairs up to it.
static func _draw_portcullis(s: Structure, face: int, u0: float, u1: float, tall: float, face_c: Dictionary,
		steps: bool) -> void:
	var px := maxf(ArtKit.face_px(s, face), 1.0)
	var fc: Color = face_c[face]
	var base := 3.0 if steps else 0.0
	ArtKit.face_quad(s, face, u0 - 2.0 / px, u1 + 2.0 / px, base, tall + base + 3.0, fc.lightened(0.12))
	ArtKit.face_quad(s, face, u0, u1, base, tall + base, ArtKit.VOID)
	var iron := ArtKit.IRON.lerp(Structure.COL_CHAR, s.scorch * 0.65)
	var bars := maxi(int((u1 - u0) * px / 5.0), 2)
	for i in range(1, bars):
		var u := lerpf(u0, u1, float(i) / bars)
		ArtKit.face_line(s, face, u, base + 1.0, u, tall + base, iron)
	ArtKit.face_line(s, face, u0, base + tall * 0.55, u1, base + tall * 0.55, iron)
	ArtKit.face_line(s, face, u0, base + tall * 0.2, u1, base + tall * 0.2, iron.darkened(0.3))
	if steps:
		# Three stone steps up to the sill, each a little narrower than the one below.
		for k in 3:
			var grow := (3.0 - k) / px
			ArtKit.face_quad(s, face, u0 - grow, u1 + grow, k, k + 1.0, fc.lightened(0.2 - k * 0.05))


## A material colour lit for the wall it sits on (0 = a top, facing the sky).
static func _lit(s: Structure, base: Color, face: int, light: Color, dir: Vector2) -> Color:
	var normal := Vector2(1, 0) if face == ArtKit.RIGHT else (Vector2(0, 1) if face == ArtKit.LEFT else Vector2.ZERO)
	return s._face_color(base, normal, light, dir)
