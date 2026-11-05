class_name TownBloom
extends CanvasLayer
## The glow of the DAY and NIGHT looks (Town.Look): a soft warm halo round every bright pixel of the graded world
## (flames, lit windows, lamp glass, the sun), from a bright pass over the screen's half, quarter and eighth resolution
## mipmaps, added on top (town_bloom.gdshader). Over the grade, under Battlefield's glow layer (spell glows already sit
## above and are left alone). DAY glows lightly on its highlights, NIGHT more strongly.

## One above the grade (TownGrade.LAYER), under Battlefield.GLOW_LAYER.
const LAYER := 2

var look := 0
var rect: ColorRect
var mat: ShaderMaterial


func setup(look_value) -> TownBloom:
	name = "Bloom"
	layer = LAYER
	look = look_value
	rect = ColorRect.new()
	rect.name = "BloomRect"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	mat = ShaderMaterial.new()
	mat.shader = preload("res://src/game/town/town_bloom.gdshader")
	var b := TownLook.bloom(look_value)
	for k: String in b:
		mat.set_shader_parameter(k, b[k])
	rect.material = mat
	add_child(rect)
	return self


func _process(_delta: float) -> void:
	mat.set_shader_parameter("view_size", get_viewport().get_visible_rect().size)
