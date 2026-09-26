class_name ArtKit
extends RefCounted
## Shared kit for Aldermere's procedural building art (the town visual upgrade, after
## concepts/TOWN REF/Town Visual Upgrade.png): variety hashed from a structure's seed, so drawing never touches
## its rng stream (tools/dev/state_digest.gd covers that stream); helpers that place points, quads and lines on
## the two visible walls; and the palette sampled from the reference.
##
## Art is collected, not drawn piece by piece: begin(), then poly()/line() calls, then flush(ci), which hands all the
## fills to the canvas as one triangle array and all the hairlines as one multiline. Each lands in a static GPU
## buffer, so a standing building costs a few draw calls a frame and no per-frame vertex work. (Drawn one by one, a
## cottage's ~90 quads and lines broke gl_compatibility's batches ~35 times and were re-uploaded every frame.) Lines
## land on top of the fills of the same flush, so art that needs a fill over a line flushes in between.
##
## Fills carry their unlit material colour and a lighting code (in UV.x); structure_art.gdshader lights them with
## Structure._face_color's maths from uniforms, so a light, scorch or frost change never rebuilds the geometry (it
## used to: ~7 ms a frame of GDScript under Cinderfall's moving lights). Lines cannot carry a code, so detail lines
## are translucent ink that darkens or brightens whatever lit surface is under them.

## Structure numbers its footprint corners 0 = back (north-west), 1 = right, 2 = front, 3 = left. The two walls
## the camera sees are named by their far corner: LEFT runs 3 -> 2 (the +y wall), RIGHT runs 1 -> 2 (the +x wall).
## Along either, u goes from 0 at the far corner to 1 at the front corner.
const LEFT := 3
const RIGHT := 1

## Lighting codes: lit as the left wall, the right wall or a top (roof, walkway); ink (darkens with scorch only);
## emissive (window glow, a gateway's dark).
const LIT_LEFT := 2.0
const LIT_RIGHT := 3.0
const LIT_TOP := 4.0
const INK := 5.0
const EMIT := 6.0

## Plaster [lit (right wall), shade (left wall)], and the timber framing it.
const PLASTER := [Color("e0c290"), Color("b99769")]
const TIMBER := Color("4e3624")
const TIMBER_DARK := Color("35251a")
## Stone foot course under the plaster.
const PLINTH := [Color("8e8478"), Color("73695f")]
## Roofs as [lit, mid, dark, seam, ridge, outline].
const SLATE := [Color("6479a3"), Color("54698f"), Color("45587c"), Color("35435f"), Color("93a6c8"), Color("1d2335")]
const RED_TILE := [Color("bd6a40"), Color("a7532f"), Color("8c4428"), Color("6a3424"), Color("d08a5e"), Color("3b1c12")]
## Ink along wall footings and chimney edges.
const OUTLINE_WALL := Color("2a1c14")
## Town stone: [lit (right wall), shade (left wall)], the walkway, and the ink at its foot.
const STONE := [Color("aaa3a1"), Color("8f898c")]
const STONE_TOP := Color("bcb4b0")
const OUTLINE_STONE := Color("3a3438")
## Banner cloth [blue, lit edge, cross].
const BANNER := [Color("1f45a6"), Color("3563c8"), Color("e8dcc0")]
const IRON := Color("6a5a55")
## A gateway's darkness.
const VOID := Color("171210")
## Barn planks [lit, shade, seam].
const PLANK := [Color("9c6c40"), Color("7e5532"), Color("573a22")]
const CHIMNEY := [Color("a39a92"), Color("847b75"), Color("5f5856")]
const CHIMNEY_CAP := Color("8a3a2a")
const DOOR := [Color("8a5a32"), Color("6a4226")]
## Window glow is emissive: the same at night as at noon.
const GLOW := Color("ffd98a")
const GLOW_RIM := Color("f0a040")
const WINDOW_OFF := Color("2a2220")
## Translucent detail lines: dark ink of a given strength, and a light sheen.
const SHADE_LINE := Color(0.08, 0.05, 0.04, 0.8)

static var _pts := PackedVector2Array()
static var _cols := PackedColorArray()
static var _uvs := PackedVector2Array()
static var _idx := PackedInt32Array()
static var _line_pts := PackedVector2Array()
static var _line_cols := PackedColorArray()
## While recording, every flush is also kept, so the drawing can be replayed without running the art again.
static var _recording := false
static var _rec: Array = []


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
		Structure.Kind.KEEP, Structure.Kind.CASTLE_WALL, Structure.Kind.GATE:
			return StoneArt.plan(s)
	return {}


## Black ink at `strength` alpha, or a white sheen at `strength` alpha when `light` is true.
static func ink(strength: float, light := false) -> Color:
	return Color(1, 1, 1, strength) if light else Color(0.06, 0.04, 0.04, strength)


## The lighting code of a visible wall.
static func face_code(face: int) -> float:
	return LIT_LEFT if face == LEFT else LIT_RIGHT


## Start collecting a drawing (drops anything a previous draw left unflushed).
static func begin() -> void:
	_pts.clear()
	_cols.clear()
	_uvs.clear()
	_idx.clear()
	_line_pts.clear()
	_line_cols.clear()


## Hand what was collected to `ci` (fills, then lines on top) and start over.
static func flush(ci: CanvasItem) -> void:
	_emit(ci, [_idx, _pts, _cols, _uvs, _line_pts, _line_cols])
	if _recording:
		_rec.append([_idx, _pts, _cols, _uvs, _line_pts, _line_cols])
		_idx = PackedInt32Array()
		_pts = PackedVector2Array()
		_cols = PackedColorArray()
		_uvs = PackedVector2Array()
		_line_pts = PackedVector2Array()
		_line_cols = PackedColorArray()
	else:
		begin()


## Start a drawing that is also recorded; take() hands the recording back.
static func record() -> void:
	begin()
	_recording = true
	_rec = []


static func take() -> Array:
	_recording = false
	var out := _rec
	_rec = []
	return out


## Draw a recording again: nothing in it depends on the light, which the shader applies.
static func replay(ci: CanvasItem, rec: Array) -> void:
	for b in rec:
		_emit(ci, b)


static func _emit(ci: CanvasItem, b: Array) -> void:
	if not (b[0] as PackedInt32Array).is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), b[0], b[1], b[2], b[3])
	if not (b[4] as PackedVector2Array).is_empty():
		ci.draw_multiline_colors(b[4], b[5], -1.0)


## One flat triangle or convex quad (3 or 4 points) in unlit colour `c`, lit by `code`.
static func poly(p: PackedVector2Array, c: Color, code: float) -> void:
	var base := _pts.size()
	_pts.append_array(p)
	var uv := Vector2(code, 0.0)
	for i in p.size():
		_cols.append(c)
		_uvs.append(uv)
	_idx.append(base)
	_idx.append(base + 1)
	_idx.append(base + 2)
	if p.size() == 4:
		_idx.append(base)
		_idx.append(base + 2)
		_idx.append(base + 3)


## One hairline (1 px at any zoom). Its colour is final: use ink() for detail over lit surfaces.
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


## A parallelogram on a wall spanning u0..u1 and h0..h1: it leans with the wall, the way iso pixel art draws a
## window. Lit as that wall unless `code` says otherwise.
static func face_quad(s: Structure, face: int, u0: float, u1: float, h0: float, h1: float, c: Color,
		code := -1.0) -> void:
	poly(PackedVector2Array([face_pt(s, face, u0, h0), face_pt(s, face, u1, h0), face_pt(s, face, u1, h1),
		face_pt(s, face, u0, h1)]), c, face_code(face) if code < 0.0 else code)


## Hairline on a wall from (u0, h0) to (u1, h1).
static func face_line(s: Structure, face: int, u0: float, h0: float, u1: float, h1: float, c: Color) -> void:
	line(face_pt(s, face, u0, h0), face_pt(s, face, u1, h1), c)


## A framed window centred at `u` with its sill at `h`: `w` px wide, `tall` px high, glowing when `lit`, with a
## mullion. `frame` is the (unlit) timber colour.
static func window(s: Structure, face: int, u: float, h: float, w: float, tall: float, lit: bool, frame: Color) -> void:
	var du := w / maxf(face_px(s, face), 1.0)
	var fu := 1.0 / maxf(face_px(s, face), 1.0)
	face_quad(s, face, u - du * 0.5 - fu, u + du * 0.5 + fu, h - 1.0, h + tall + 1.0, frame)
	if lit:
		face_quad(s, face, u - du * 0.5, u + du * 0.5, h, h + tall, GLOW_RIM, EMIT)
		face_quad(s, face, u - du * 0.5 + fu, u + du * 0.5, h + 1.0, h + tall, GLOW, EMIT)
	else:
		face_quad(s, face, u - du * 0.5, u + du * 0.5, h, h + tall, WINDOW_OFF)
	face_line(s, face, u, h, u, h + tall, ink(0.7))
