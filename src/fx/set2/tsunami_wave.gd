class_name TsunamiWave
extends Node2D
## Tsunami wall painted like the concept (`tsunami_wall.gdshader`): one long standing wall of water along the
## wave front, low at its left end and tallest toward the right, with a row of curling hoods, dark spiral
## hollows, streaked face water, a churning foam crest with spray and a whitewater base.
## Drawn as a quad standing on the wall's screen line, centered on this node.

const SH_WALL := preload("res://shaders/tsunami_wall.gdshader")
## Extra whitewater drawn below the baseline, in pixels.
const BOTTOM_PX := 18.0
## Room above the crest for foam bumps and spray, as a fraction of max height.
const TOP_MARGIN := 0.35
## A wave front that lines up with screen vertical has no width on screen; its base is spread at least this
## fraction of its length horizontally so it still reads as a wall facing the camera.
const MIN_SCREEN_SPREAD := 0.85

## Ground direction the wave travels and wall width in ground units.
var dir := Vector2(1, 0)
var width := 5.4
## Full crest height in pixels.
var max_height := 140.0
## 0..1 rise and curl amounts, driven by tweens.
var height := 0.0
var curl := 0.0
var fade := 1.0
var hoods := 5.0
var seed := 0.0

var _mat: ShaderMaterial
var _time := 0.0


func _init() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = SH_WALL
	material = _mat


func set_param(param: StringName, value: Variant) -> void:
	_mat.set_shader_parameter(param, value)


func _process(delta: float) -> void:
	_time += delta
	_mat.set_shader_parameter(&"u_time", _time)
	_mat.set_shader_parameter(&"fade", fade)
	_mat.set_shader_parameter(&"height", height)
	_mat.set_shader_parameter(&"curl", curl)
	_mat.set_shader_parameter(&"hoods", hoods)
	_mat.set_shader_parameter(&"seed", seed)
	var travel := _travel()
	_mat.set_shader_parameter(&"mirror", 1.0 if travel.x < -0.05 else 0.0)
	_mat.set_shader_parameter(&"back_view", smoothstep(0.2, 0.75, -travel.y))
	queue_redraw()


## Height in pixels where the crest throws spray, for emitters.
func lip_height() -> float:
	return max_height * height * 0.8


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


func _draw() -> void:
	if height <= 0.01 or fade <= 0.01:
		return
	var ends := _ends()
	var a: Vector2 = ends[0]
	var b: Vector2 = ends[1]
	var top := max_height * (1.0 + TOP_MARGIN)
	var up := Vector2(0, -top)
	var down := Vector2(0, BOTTOM_PX)
	_mat.set_shader_parameter(&"length_px", a.distance_to(b))
	_mat.set_shader_parameter(&"top_px", top)
	_mat.set_shader_parameter(&"bottom_px", BOTTOM_PX)
	_mat.set_shader_parameter(&"max_height", max_height)
	var pts := PackedVector2Array([a + up, b + up, b + down, a + down])
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var cols := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	draw_primitive(pts, cols, uvs, _white())


static var _white_tex: ImageTexture


static func _white() -> Texture2D:
	if _white_tex == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white_tex = ImageTexture.create_from_image(img)
	return _white_tex
