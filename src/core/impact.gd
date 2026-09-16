class_name Impact
extends Node
## Impact feel controller: hit-stop, impact frames, RGB split and world dimming.
## Works in real time so hit-stop never stretches its own recovery.

const POST_SHADER := preload("res://shaders/impact_post.gdshader")

## User-chosen time scale (slow-mo toggle); hit-stop dips below it temporarily.
var base_time_scale := 1.0

var _post: ColorRect
var _mat: ShaderMaterial
var _dim: Node2D
var _camera: Camera2D
var _hitstop_until := 0
var _hitstop_scale := 1.0
var _frame_until := 0
var _aberration := 0.0
var _aberration_decay := 0.0
var _dim_amount := 0.0
var _dim_target := 0.0
var _dim_speed := 1.0


## post_parent: a CanvasLayer above the world; dim_parent: world-space node between world and overhead layers.
func setup(post_parent: CanvasLayer, dim_parent: Node2D, camera: Camera2D) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = camera
	_mat = ShaderMaterial.new()
	_mat.shader = POST_SHADER
	_post = ColorRect.new()
	_post.material = _mat
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.visible = false
	post_parent.add_child(_post)
	_dim = Node2D.new()
	_dim.name = "Dim"
	_dim.draw.connect(_draw_dim)
	dim_parent.add_child(_dim)


func set_base_time_scale(value: float) -> void:
	base_time_scale = value
	if Time.get_ticks_msec() >= _hitstop_until:
		Engine.time_scale = value
	Sfx.speed = value


## Freeze gameplay for `real_seconds` (scaled down to `scale`, not fully stopped).
func hitstop(real_seconds: float, scale := 0.04) -> void:
	_hitstop_until = maxi(_hitstop_until, Time.get_ticks_msec() + int(real_seconds * 1000.0))
	_hitstop_scale = scale
	Engine.time_scale = base_time_scale * scale


## High-contrast inverted frame for `real_seconds` (~2-4 frames).
func impact_frame(real_seconds := 0.05, screen_focus := Vector2(0.5, 0.5),
		light := Color(1.0, 0.97, 0.9), dark := Color(0.05, 0.02, 0.02)) -> void:
	_frame_until = Time.get_ticks_msec() + int(real_seconds * 1000.0)
	_mat.set_shader_parameter("focus", screen_focus)
	_mat.set_shader_parameter("frame_light", light)
	_mat.set_shader_parameter("frame_dark", dark)


## RGB split of `pixels` that decays to zero over `real_seconds`.
func aberration(pixels: float, real_seconds: float) -> void:
	_aberration = maxf(_aberration, pixels)
	_aberration_decay = pixels / maxf(real_seconds, 0.01)


## Darken the world under the overhead effects toward `amount` (0..1) at `speed` per second.
func dim(amount: float, speed := 1.5) -> void:
	_dim_target = clampf(amount, 0.0, 0.9)
	_dim_speed = speed


func focus_of(screen_world_pos: Vector2) -> Vector2:
	var vp := get_viewport()
	var screen := vp.get_canvas_transform() * screen_world_pos
	return screen / vp.get_visible_rect().size


func _process(_delta: float) -> void:
	var real_delta := get_process_delta_time() / maxf(Engine.time_scale, 0.0001)
	var now := Time.get_ticks_msec()
	if _hitstop_until > 0 and now >= _hitstop_until:
		_hitstop_until = 0
		Engine.time_scale = base_time_scale
	var frame_on := now < _frame_until
	_aberration = maxf(_aberration - _aberration_decay * real_delta, 0.0)
	_mat.set_shader_parameter("impact_frame", 1.0 if frame_on else 0.0)
	_mat.set_shader_parameter("aberration", _aberration)
	_post.visible = frame_on or _aberration >= 0.5
	_dim_amount = move_toward(_dim_amount, _dim_target, _dim_speed * real_delta)
	_dim.visible = _dim_amount > 0.005
	if _dim.visible:
		_dim.queue_redraw()


func _draw_dim() -> void:
	var center := _camera.get_screen_center_position() if _camera else Vector2.ZERO
	_dim.draw_rect(Rect2(center - Vector2(400, 260), Vector2(800, 520)), Color(0.01, 0.0, 0.03, _dim_amount))
