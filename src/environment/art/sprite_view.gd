class_name SpriteView
extends Node2D
## One building sprite (SpriteArt) on a Structure: a still, or a frame of its idle strip, drawn with the footprint's
## front corner at this node's origin through structure_sprite.gdshader, which lights, chars and frosts it like the
## procedural art and clips it along the footprint's ground line for a collapse or a laser cut. A deep footprint shows a
## wide sprite mirrored (scale.x = -1); the clip works in the sprite's own pixels, so it mirrors with it.

const SHADER := preload("res://src/environment/art/structure_sprite.gdshader")
## Clip modes (the shader's cut_mode): everything, what is above the cut line, or what is below it.
const KEEP_ALL := 0
const KEEP_ABOVE := 1
const KEEP_BELOW := -1

var sprite := {}
var still := &"intact"
var frame := 0
## The draw's modulate: the blight's tint, a fade.
var color := Color.WHITE
var _mat: ShaderMaterial


## `left` and `right`: the footprint's left and right corners relative to its front corner, in the structure's space
## (Structure._s[3] and _s[1]).
func setup(sprite_set: Dictionary, left: Vector2, right: Vector2) -> SpriteView:
	sprite = sprite_set
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	var m := -1.0 if sprite.mirror else 1.0
	scale = Vector2(m, 1.0)
	# In the sprite's own pixels a mirrored right corner is the left one.
	var a := Vector2(left.x * m, left.y)
	var b := Vector2(right.x * m, right.y)
	_mat.set_shader_parameter("corner_left", a if a.x < b.x else b)
	_mat.set_shader_parameter("corner_right", b if a.x < b.x else a)
	_mat.set_shader_parameter("anchor", sprite.anchor)
	return self


## Show `st` (&"intact", &"damaged", &"ruins"). The intact still plays its idle strip's `frame_index` when the set
## has one. Redraws only on a change.
func show_still(st: StringName, frame_index := 0) -> void:
	var f := frame_index % int(sprite.frames) if st == &"intact" and sprite.idle != null else 0
	if st == still and f == frame:
		return
	still = st
	frame = f
	queue_redraw()


func set_color(c: Color) -> void:
	if c != color:
		color = c
		queue_redraw()


## Clip along the ground line raised by `lift` px (see the shader); `molten` lights a stump's cut edge.
func set_cut(mode: int, lift: float, molten := 0.0) -> void:
	_mat.set_shader_parameter("cut_mode", mode)
	_mat.set_shader_parameter("cut_lift", lift)
	_mat.set_shader_parameter("molten", molten)


func set_light(light: Color, ambient: float, scorch: float, frost: float, tint: Color) -> void:
	_mat.set_shader_parameter("light_col", Vector3(light.r, light.g, light.b))
	_mat.set_shader_parameter("ambient", ambient)
	_mat.set_shader_parameter("scorch", scorch)
	_mat.set_shader_parameter("frost", frost)
	_mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))


func _draw() -> void:
	var size: Vector2 = sprite.size
	var at: Vector2 = sprite.anchor
	var strip: bool = still == &"intact" and sprite.idle != null
	var tex: Texture2D = sprite.idle if strip else sprite.stills[still]
	var origin := Vector2(frame * size.x, 0.0)
	_mat.set_shader_parameter("frame_origin", origin)
	draw_texture_rect_region(tex, Rect2(-at, size), Rect2(origin, size), color)
