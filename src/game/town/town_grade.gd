class_name TownGrade
extends CanvasLayer
## The DAY and NIGHT colour grade (Town.Look): one full-screen pass over the finished world and under the light pools, the
## Battlefield's glow, post and flash layers and the HUD, so spell glows and flashes stay bright whatever the look. The
## only screen-space piece of the look; it is a colour transform with no positions (town_grade.gdshader).

## The canvas layer of the grade; the pools sit one above, Battlefield's glow above those.
const LAYER := 1

var look := 0
var rect: ColorRect
var mat: ShaderMaterial


func setup(look_value) -> TownGrade:
	name = "Grade"
	layer = LAYER
	look = look_value
	rect = ColorRect.new()
	rect.name = "GradeRect"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	mat = ShaderMaterial.new()
	mat.shader = preload("res://src/game/town/town_grade.gdshader")
	var g := TownLook.grade(look_value)
	for k: String in g:
		mat.set_shader_parameter(k, g[k])
	rect.material = mat
	add_child(rect)
	return self
