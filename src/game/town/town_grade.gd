class_name TownGrade
extends CanvasLayer
## The DAY and NIGHT colour grade (Town.Look): one full-screen pass over the finished world and under the Battlefield's
## glow, post and flash layers and the HUD, so spell glows and flashes stay bright whatever the look. It grades the
## colour, then multiplies in the light map (TownPools' buffer): lit = graded + base * light (town_grade.gdshader).

## The canvas layer of the grade; Battlefield's glow sits above.
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
	var top := out.x * 0.299 + out.y * 0.587 + out.z * 0.114
	out *= 1.0 - float(g.get("shoulder", 0.0)) * smoothstep(float(g.get("knee", 0.45)), 1.0, top)
	var glum := out.x * 0.299 + out.y * 0.587 + out.z * 0.114
	var blueness := smoothstep(0.08, 0.22, c.b - maxf(c.r, c.g))
	var dark := 1.0 - smoothstep(0.55, 0.95, lum)
	out = out.lerp(Vector3(glum, glum, glum) * Vector3(0.92, 1.0, 1.1), float(g.get("calm", 0.0)) * blueness * dark)
	var ember := smoothstep(0.6, 0.9, c.r) * smoothstep(0.2, 0.45, c.r - c.b) * float(g.keep_lit)
	var src := Vector3(c.r, c.g, c.b)
	var res := out.lerp(src, ember)
	return Color(clampf(res.x, 0.0, 1.0), clampf(res.y, 0.0, 1.0), clampf(res.z, 0.0, 1.0), 1.0)


func setup(look_value, light: Texture2D = null) -> TownGrade:
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
	var atm := TownLook.atmosphere(look_value)
	for k: String in atm:
		mat.set_shader_parameter(k, atm[k])
	if light != null:
		mat.set_shader_parameter("light_tex", light)
		mat.set_shader_parameter("light_gain", TownLook.light_gain(look_value))
		mat.set_shader_parameter("light_warm", TownLook.light_warm(look_value))
	rect.material = mat
	add_child(rect)
	return self


func _enter_tree() -> void:
	if not RenderingServer.frame_pre_draw.is_connected(follow_view):
		RenderingServer.frame_pre_draw.connect(follow_view)


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(follow_view):
		RenderingServer.frame_pre_draw.disconnect(follow_view)


## The light map's dither is locked to the world: hand the shader the view (its size, origin and zoom) just before each
## frame is drawn.
func follow_view() -> void:
	if not is_inside_tree() or mat == null:
		return
	var vp := get_viewport()
	var ct := vp.canvas_transform
	mat.set_shader_parameter("view_size", vp.get_visible_rect().size)
	mat.set_shader_parameter("view_origin", ct.origin)
	mat.set_shader_parameter("view_zoom", ct.get_scale().x)


## The shader's light step (town_grade.gdshader light_at) in GDScript, for the tests: the light `m` (0..1) at a world
## cell, cut into `steps` levels through the 4x4 Bayer dither.
static func light_step(m: float, cell: Vector2i, steps: float) -> float:
	const B := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var b := (float(B[posmod(cell.y, 4) * 4 + posmod(cell.x, 4)]) + 0.5) / 16.0
	return floorf(m * steps + b) / steps
