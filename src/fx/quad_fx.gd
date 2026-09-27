class_name QuadFx
extends Node2D
## A textured quad driven by a canvas_item shader. Drives u_time (respects time scale).

static var _white: ImageTexture

var size := Vector2.ONE
## 0..1 of size; (0.5, 1.0) = bottom center.
var anchor := Vector2(0.5, 0.5)
## Auto free after this many seconds when > 0.
var life := 0.0
var age := 0.0
var mat: ShaderMaterial
## Set by run_on_shader_clock(): the shader keeps time, and this node never processes.
var _shader_clock := false


func setup(shader: Shader, quad_size: Vector2, quad_anchor := Vector2(0.5, 0.5)) -> QuadFx:
	mat = ShaderMaterial.new()
	mat.shader = shader
	material = mat
	size = quad_size
	anchor = quad_anchor
	return self


## For a permanent light_glow quad (a torch's, a lamp's): the shader keeps its own time, so the node does no work
## each frame. A town has a hundred of them, each once setting u_time every frame.
func run_on_shader_clock() -> QuadFx:
	_shader_clock = true
	set_param(&"shader_clock", true)
	return self


func _ready() -> void:
	# Processing is switched on for a script with _process() just before _ready(), so it is switched off here.
	if _shader_clock:
		set_process(false)


func set_param(param: StringName, value: Variant) -> void:
	mat.set_shader_parameter(param, value)


func tween_param(param: StringName, from: Variant, to: Variant, seconds: float, delay := 0.0,
		trans := Tween.TRANS_LINEAR, ease_type := Tween.EASE_IN_OUT) -> Tween:
	if delay <= 0.0:
		set_param(param, from)
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
		tw.tween_callback(set_param.bind(param, from))
	tw.tween_method(func(v): set_param(param, v), from, to, seconds) \
		.set_trans(trans).set_ease(ease_type)
	return tw


func _process(delta: float) -> void:
	age += delta
	set_param(&"u_time", age)
	if life > 0.0 and age >= life:
		queue_free()


func _draw() -> void:
	if _white == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	draw_texture_rect(_white, Rect2(-size * anchor, size), false)
