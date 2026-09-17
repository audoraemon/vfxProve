class_name TsunamiWave
extends Node2D
## Tsunami wave with volume. Front: the painted wall (`tsunami_wall.gdshader`) like the concept, one long
## standing wall of water with curling hoods, streaked face water, a churning foam crest and a whitewater base.
## Body: a mesh behind it (`tsunami_body.gdshader`) that carries the crest back over the churning top of the
## wave and down a long back slope to the ground, so the wave reads as a thick mass rather than a flat sheet.
## The body draws behind the face when the wave comes toward the camera and in front of it when it travels away.
## Centered on the middle of the wave front.

const SH_WALL := preload("res://shaders/tsunami_wall.gdshader")
const SH_BODY := preload("res://shaders/tsunami_body.gdshader")
## Extra whitewater drawn below the baseline, in pixels.
const BOTTOM_PX := 26.0
## Room above the crest for foam bumps and spray, as a fraction of max height.
const TOP_MARGIN := 0.35
## A wave front that lines up with screen vertical has no width on screen; its base is spread at least this
## fraction of its length horizontally so it still reads as a wall facing the camera.
const MIN_SCREEN_SPREAD := 0.85
## How far the body reaches back behind the front, in ground units, and the mesh resolution.
const THICKNESS := 2.4
const BODY_COLS := 60
const BODY_ROWS := 10
## Fraction of the depth that stays near crest height before the back slope falls away.
const TOP_DEPTH := 0.22

## Ground direction the wave travels and wall width in ground units.
var dir := Vector2(1, 0)
var width := 5.4
## Full crest height in pixels.
var max_height := 140.0
## 0..1 rise and curl amounts, driven by tweens.
var height := 0.0
var curl := 0.0
var fade := 1.0
var hoods := 4.0
var seed := 0.0

var _time := 0.0
var _face: WaveLayer
var _body: WaveLayer
var _face_mat: ShaderMaterial
var _body_mat: ShaderMaterial


class WaveLayer:
	extends Node2D

	var paint: Callable

	func _draw() -> void:
		paint.call(self)


func _init() -> void:
	_face_mat = ShaderMaterial.new()
	_face_mat.shader = SH_WALL
	_body_mat = ShaderMaterial.new()
	_body_mat.shader = SH_BODY
	_body = WaveLayer.new()
	_body.material = _body_mat
	_body.paint = _draw_body
	add_child(_body)
	_face = WaveLayer.new()
	_face.material = _face_mat
	_face.paint = _draw_face
	add_child(_face)


func set_param(param: StringName, value: Variant) -> void:
	_face_mat.set_shader_parameter(param, value)


func _process(delta: float) -> void:
	_time += delta
	var travel := _travel()
	for m in [_face_mat, _body_mat]:
		m.set_shader_parameter(&"u_time", _time)
		m.set_shader_parameter(&"fade", fade)
	_face_mat.set_shader_parameter(&"height", height)
	_face_mat.set_shader_parameter(&"curl", curl)
	_face_mat.set_shader_parameter(&"hoods", hoods)
	_face_mat.set_shader_parameter(&"seed", seed)
	_face_mat.set_shader_parameter(&"mirror", 1.0 if _mirrored() else 0.0)
	_face_mat.set_shader_parameter(&"back_view", _back_view())
	# Travelling away from the camera, the back slope is nearer to the camera than the face.
	var body_front := travel.y < -0.05
	if body_front != (_body.get_index() > _face.get_index()):
		move_child(_body, 1 if body_front else 0)
	_face.queue_redraw()
	_body.queue_redraw()


## Height in pixels where the crest throws spray, for emitters.
func lip_height() -> float:
	return max_height * height * 0.8


func _mirrored() -> bool:
	return _travel().x < -0.05


func _back_view() -> float:
	return smoothstep(0.2, 0.75, -_travel().y)


## Wall end points on screen relative to this node, left end first.
func _ends() -> Array:
	var side := Iso.ground_to_screen(dir.normalized().orthogonal()) * width * 0.5
	var a := -side
	var b := side
	if a.x > b.x:
		var tmp := a
		a = b
		b = tmp
	var half_len := side.length()
	var min_half := half_len * MIN_SCREEN_SPREAD
	if b.x < min_half:
		# Keep the length, lay the base flatter across the screen.
		var dy := sqrt(maxf(half_len * half_len - min_half * min_half, 0.0)) * signf(b.y if absf(b.y) > 0.001 else 1.0)
		a = Vector2(-min_half, -dy)
		b = Vector2(min_half, dy)
	return [a, b]


## Screen travel direction, normalized.
func _travel() -> Vector2:
	var ts := Iso.ground_to_screen(dir.normalized())
	return ts.normalized() if ts.length() > 0.001 else Vector2(1, 0)


# --- Crest profile, mirrors tsunami_wall.gdshader (without the animated noise) ---------------------------

func _envelope(u: float) -> float:
	var ramp := lerpf(0.55, 1.0, smoothstep(0.0, 0.5, u))
	var right := sqrt(maxf(1.0 - pow(smoothstep(0.74, 1.0, u), 2.0), 0.0))
	return ramp * lerpf(0.12, 1.0, right) * smoothstep(0.0, 0.04, u) * smoothstep(1.0, 0.985, u)


func _hood_shape(fx: float) -> float:
	return 0.8 + 0.2 * pow(sin(PI * pow(fx, 1.4)), 0.7)


## Crest height in pixels at fraction u along the wall (left to right on screen).
func _crest(u: float) -> float:
	var um := 1.0 - u if _mirrored() else u
	var cells := um * hoods + seed
	var fx := cells - floorf(cells)
	var back := _back_view()
	var cv := curl * (1.0 - back)
	var shape := lerpf(0.86, _hood_shape(fx), lerpf(cv, curl * 0.5, back))
	return max_height * height * _envelope(um) * shape


# --- Drawing ----------------------------------------------------------------------------------------------

func _draw_face(layer: Node2D) -> void:
	if height <= 0.01 or fade <= 0.01:
		return
	var ends := _ends()
	var a: Vector2 = ends[0]
	var b: Vector2 = ends[1]
	var top := max_height * (1.0 + TOP_MARGIN)
	var up := Vector2(0, -top)
	var down := Vector2(0, BOTTOM_PX)
	_face_mat.set_shader_parameter(&"length_px", a.distance_to(b))
	_face_mat.set_shader_parameter(&"top_px", top)
	_face_mat.set_shader_parameter(&"bottom_px", BOTTOM_PX)
	_face_mat.set_shader_parameter(&"max_height", max_height)
	var pts := PackedVector2Array([a + up, b + up, b + down, a + down])
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var cols := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	layer.draw_primitive(pts, cols, uvs, _white())


func _draw_body(layer: Node2D) -> void:
	if height <= 0.01 or fade <= 0.01:
		return
	var ends := _ends()
	var a: Vector2 = ends[0]
	var b: Vector2 = ends[1]
	var back := -Iso.ground_to_screen(dir.normalized()) * THICKNESS * lerpf(0.5, 1.0, height)
	var len_px := a.distance_to(b)
	var back_px := back.length()
	var hmax := maxf(max_height, 1.0)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	for i in BODY_COLS + 1:
		var u := float(i) / BODY_COLS
		# Sit just under the painted crest so the face's foam covers the seam.
		var crest := _crest(u) * 0.96
		var base := a.lerp(b, u)
		for j in BODY_ROWS + 1:
			var w := float(j) / BODY_ROWS
			var slope := 1.0 - smoothstep(TOP_DEPTH, 1.0, w)
			var h := crest * (1.0 - 0.06 * minf(w / TOP_DEPTH, 1.0)) * pow(slope, 1.3)
			pts.append(base + back * w - Vector2(0, h))
			cols.append(Color(w, h / hmax, u, 1.0))
			uvs.append(Vector2(u * len_px, w * back_px + (crest - h) * 0.5))
	var idx := PackedInt32Array()
	var stride := BODY_ROWS + 1
	# Rows nearest the camera go last so the mesh paints back to front whichever way it faces.
	var row_order: Array[int] = []
	for j in BODY_ROWS:
		row_order.append(j)
	if back.y < 0.0:
		row_order.reverse()
	for j in row_order:
		for i in BODY_COLS:
			var p0 := i * stride + j
			var p1 := p0 + 1
			var p2 := p0 + stride
			var p3 := p2 + 1
			idx.append_array([p0, p2, p1, p1, p2, p3])
	RenderingServer.canvas_item_add_triangle_array(layer.get_canvas_item(), idx, pts, cols, uvs)


static var _white_tex: ImageTexture


static func _white() -> Texture2D:
	if _white_tex == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white_tex = ImageTexture.create_from_image(img)
	return _white_tex
