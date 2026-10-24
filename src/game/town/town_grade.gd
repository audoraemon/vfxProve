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


## The shader's colour transform in GDScript (the same formula, for the tests): `c` ungraded, `g` the TownLook.grade()
## dictionary. Returns the graded colour.
static func grade_pixel(c: Color, g: Dictionary) -> Color:
	var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var t := smoothstep(float(g.split) - float(g.spread), float(g.split) + float(g.spread), lum)
	var gain: Vector3 = g.gain
	var warm: Vector3 = g.warm
	var cool: Vector3 = g.cool
	var lift: Vector3 = g.lift
	var out := Vector3(c.r, c.g, c.b) * gain * cool.lerp(warm, t) + lift
	var glum := out.x * 0.299 + out.y * 0.587 + out.z * 0.114
	var blueness := smoothstep(0.08, 0.22, c.b - maxf(c.r, c.g))
	var dark := 1.0 - smoothstep(0.55, 0.95, lum)
	out = out.lerp(Vector3(glum, glum, glum) * Vector3(0.92, 1.0, 1.1), float(g.get("calm", 0.0)) * blueness * dark)
	var ember := smoothstep(0.6, 0.9, c.r) * smoothstep(0.2, 0.45, c.r - c.b) * float(g.keep_lit)
	var src := Vector3(c.r, c.g, c.b)
	var res := out.lerp(src, ember)
	return Color(clampf(res.x, 0.0, 1.0), clampf(res.y, 0.0, 1.0), clampf(res.z, 0.0, 1.0), 1.0)


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
