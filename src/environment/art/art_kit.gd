class_name ArtKit
extends RefCounted
## Shared kit for Aldermere's procedural building art (the town visual upgrade, after
## concepts/TOWN REF/Town Visual Upgrade.png): variety hashed from a structure's seed, so drawing never touches
## its rng stream (tools/dev/state_digest.gd covers that stream); helpers that place points, quads and lines on
## the two visible walls; and the palette sampled from the reference.
##
## Art is collected, not drawn piece by piece: begin(), then poly()/line() calls, then flush(ci), which hands all the
## fills to the canvas as one triangle array and all the hairlines as one multiline. Each lands in a static GPU
## buffer, so a standing building costs two draw calls a frame and no per-frame vertex work. Drawn one by one, a
## cottage's ~90 quads and lines kept switching primitive type, broke gl_compatibility's batches ~35 times per
## house, and were re-uploaded every frame (about +6 ms for the town). Lines always land on top of the fills in the
## same flush, so art that needs a fill over a line flushes in between (see HouseArt's layers).

## Structure numbers its footprint corners 0 = back (north-west), 1 = right, 2 = front, 3 = left. The two walls
## the camera sees are named by their far corner: LEFT runs 3 -> 2 (the +y wall), RIGHT runs 1 -> 2 (the +x wall).
## Along either, u goes from 0 at the far corner to 1 at the front corner.
const LEFT := 3
const RIGHT := 1

## Plaster [lit (right wall), shade (left wall)], and the timber framing it.
const PLASTER := [Color("e6d6b2"), Color("c8ae86")]
const TIMBER := Color("4e3624")
const TIMBER_DARK := Color("35251a")
## Stone foot course under the plaster.
const PLINTH := [Color("8e8478"), Color("73695f")]
## Roofs as [lit, mid, dark, seam, ridge].
const SLATE := [Color("6b7a99"), Color("5b6a8a"), Color("4b5878"), Color("3c4661"), Color("8f9bb4")]
const RED_TILE := [Color("bd6a40"), Color("a7532f"), Color("8c4428"), Color("6a3424"), Color("d08a5e")]
## Barn planks [lit, shade, seam].
const PLANK := [Color("9c6c40"), Color("7e5532"), Color("573a22")]
const CHIMNEY := [Color("a39a92"), Color("847b75"), Color("5f5856")]
const CHIMNEY_CAP := Color("8a3a2a")
const DOOR := [Color("8a5a32"), Color("6a4226")]
## Window glow is emissive: the same at night as at noon.
const GLOW := Color("ffd98a")
const GLOW_RIM := Color("f0a040")
const WINDOW_OFF := Color("2a2220")

static var _pts := PackedVector2Array()
static var _cols := PackedColorArray()
static var _idx := PackedInt32Array()
static var _line_pts := PackedVector2Array()
static var _line_cols := PackedColorArray()


## A stable number in [0, 1) for this seed and salt. Different salts give independent choices.
static func hash01(seed_value: int, salt: int) -> float:
	return float(absi(hash(Vector2i(seed_value & 0x7fffffff, salt * 7919 + 17))) % 100003) / 100003.0


## A stable choice in [0, n).
static func pick(seed_value: int, salt: int, n: int) -> int:
	return mini(int(hash01(seed_value, salt) * n), n - 1)


## The art plan a structure keeps from setup(): pure data from its seed, kind and role; empty for kinds with no art.
static func plan_for(s: Structure) -> Dictionary:
	match s.kind:
		Structure.Kind.HOUSE:
			return HouseArt.plan(s)
	return {}


## Start collecting a drawing (drops anything a previous draw left unflushed).
static func begin() -> void:
	_pts.clear()
	_cols.clear()
	_idx.clear()
	_line_pts.clear()
	_line_cols.clear()


## Hand what was collected to `ci` (fills, then lines on top) and start over.
static func flush(ci: CanvasItem) -> void:
	if not _idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), _idx, _pts, _cols)
	if not _line_pts.is_empty():
		ci.draw_multiline_colors(_line_pts, _line_cols, -1.0)
	begin()


## One flat triangle or convex quad (3 or 4 points).
static func poly(p: PackedVector2Array, c: Color) -> void:
	var base := _pts.size()
	_pts.append_array(p)
	for i in p.size():
		_cols.append(c)
	_idx.append(base)
	_idx.append(base + 1)
	_idx.append(base + 2)
	if p.size() == 4:
		_idx.append(base)
		_idx.append(base + 2)
		_idx.append(base + 3)


## One hairline (1 px at any zoom).
static func line(a: Vector2, b: Vector2, c: Color) -> void:
	_line_pts.append(a)
	_line_pts.append(b)
	_line_cols.append(c)


## Screen point (structure-local) on a visible wall: `u` along it (0 far corner, 1 front corner), `h` px up.
static func face_pt(s: Structure, face: int, u: float, h: float) -> Vector2:
	return s._s[face].lerp(s._s[2], u) + Vector2(0, -h)


## Width of a visible wall in screen px.
static func face_px(s: Structure, face: int) -> float:
	return absf(s._s[2].x - s._s[face].x)


## A parallelogram on a wall spanning u0..u1 and h0..h1: it leans with the wall, the way iso pixel art draws a window.
static func face_quad(s: Structure, face: int, u0: float, u1: float, h0: float, h1: float, c: Color) -> void:
	poly(PackedVector2Array([face_pt(s, face, u0, h0), face_pt(s, face, u1, h0), face_pt(s, face, u1, h1),
		face_pt(s, face, u0, h1)]), c)


## Hairline on a wall from (u0, h0) to (u1, h1).
static func face_line(s: Structure, face: int, u0: float, h0: float, u1: float, h1: float, c: Color) -> void:
	line(face_pt(s, face, u0, h0), face_pt(s, face, u1, h1), c)


## A framed window centred at `u` with its sill at `h`: `w` px wide, `tall` px high, glowing when `lit`, with a
## cross mullion. `frame` is the timber colour already lit for this wall.
static func window(s: Structure, face: int, u: float, h: float, w: float, tall: float, lit: bool, frame: Color,
		shade: Color) -> void:
	var du := w / maxf(face_px(s, face), 1.0)
	var fu := 1.0 / maxf(face_px(s, face), 1.0)
	face_quad(s, face, u - du * 0.5 - fu, u + du * 0.5 + fu, h - 1.0, h + tall + 1.0, frame)
	var glass := GLOW_RIM if lit else WINDOW_OFF.lerp(shade, 0.2)
	face_quad(s, face, u - du * 0.5, u + du * 0.5, h, h + tall, glass)
	if lit:
		face_quad(s, face, u - du * 0.5 + fu, u + du * 0.5, h + 1.0, h + tall, GLOW)
	face_line(s, face, u, h, u, h + tall, frame)
