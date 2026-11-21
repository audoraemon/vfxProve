class_name EvernightSky
extends RefCounted
## Evernight's look over the whole town (spec 7; looks only: nothing here decides who is taken, or when). A few large pieces, never
## one per person or per building:
## - Shade: the night multiplied over everything in view inside the front (ground, houses, people), deeper at the screen's edge,
##   lighter under the moon, with a warm island round each burning torch (evernight_shade.gdshader).
## - Air: the mist drifting over the roofs, the stars glittering, a few falling, motes of dark rising (evernight_air.gdshader).
## - Wall: the front itself, a towering wall of night standing on the front's ring as it runs out (and rolls back at dawn).
## - TorchGlow: a warm flickering halo with sparks round a burning torch, the one warm thing in the night.
## - wisp(): a brief dark wisp rising where the lone one was taken.
## Every piece is tracked by its cast (FxTimeline.track) and goes with it; scatter uses each piece's own seed, never the shared stream.

const SH_SHADE := preload("res://shaders/evernight_shade.gdshader")
const SH_AIR := preload("res://shaders/evernight_air.gdshader")
const SH_WALL := preload("res://shaders/evernight_wall.gdshader")
## The wall's height in pixels at full size, its segments round the ring, and the pixels of wall per noise tile along it.
const WALL_H := 420.0
const WALL_SEGMENTS := 96
const WALL_TILE := 240.0
## The torch is held this far above the bearer's feet (pixels).
const HELD := 20.0
## The night multiplied over the town: in the middle of the view and at its edge; lighter when the town's own look is already
## night (the grade has darkened it once).
const NIGHT := Color(0.40, 0.39, 0.64)
const NIGHT_EDGE := Color(0.22, 0.20, 0.40)
const NIGHT_ON_NIGHT := Color(0.68, 0.64, 0.84)
const NIGHT_ON_NIGHT_EDGE := Color(0.44, 0.40, 0.60)
## Where the moon hangs on the screen (a share of the view), and how much its light lifts the night round it.
const MOON_UV := Vector2(0.82, 0.16)
const MOON_LIGHT := 0.12
const EMBERS := [Color("ffe2a0"), Color("ffb25a"), Color("e0702a"), Color(0.55, 0.2, 0.08, 0.6)]
const WISP := [Color(0.06, 0.03, 0.10, 0.9), Color(0.12, 0.05, 0.20, 0.85), Color(0.22, 0.09, 0.38, 0.7),
	Color(0.42, 0.30, 0.62, 0.45), Color(0.62, 0.52, 0.82, 0.2)]

static var _white: ImageTexture


static func white() -> ImageTexture:
	if _white == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	return _white


## The camera's view in world pixels (with a margin), or a wide square round the origin off the tree.
static func view_rect(n: CanvasItem) -> Rect2:
	if not n.is_inside_tree():
		return Rect2(-2048, -2048, 4096, 4096)
	var inv := n.get_canvas_transform().affine_inverse()
	var size := n.get_viewport_rect().size
	var a := inv * Vector2.ZERO
	var b := inv * size
	return Rect2(a, b - a).abs().grow(96.0)


## A quad over the camera's view with one of the night's shaders (the shade or the air).
class View extends Node2D:
	var mat := ShaderMaterial.new()
	var _rect := Rect2()

	func _init(shader: Shader) -> void:
		mat.shader = shader
		material = mat

	func set_param(param: StringName, value: Variant) -> void:
		mat.set_shader_parameter(param, value)

	func _process(_delta: float) -> void:
		var r := EvernightSky.view_rect(self)
		if r != _rect:
			_rect = r
			queue_redraw()

	func _draw() -> void:
		if _rect.size == Vector2.ZERO:
			_rect = EvernightSky.view_rect(self)
		draw_texture_rect(EvernightSky.white(), _rect, false)


## The front: a strip standing on the ring of `front` ground units round `center`, far side first.
class Wall extends Node2D:
	var center := Vector2.ZERO
	var front := 0.0
	var amount := 0.0
	var mat := ShaderMaterial.new()

	func _init() -> void:
		mat.shader = EvernightSky.SH_WALL
		material = mat

	func _draw() -> void:
		if amount <= 0.0 or front <= 0.05:
			return
		mat.set_shader_parameter(&"amount", amount)
		var n := EvernightSky.WALL_SEGMENTS
		var h := EvernightSky.WALL_H * clampf(front / 12.0, 0.45, 1.0)
		var seg := Iso.radius_to_screen(front).x * TAU / float(n)
		var view := EvernightSky.view_rect(self).grow(h)
		var rows: Array = []
		for i in n:
			var b0 := Iso.ground_to_screen(center + Vector2.from_angle(TAU * float(i) / float(n)) * front)
			var b1 := Iso.ground_to_screen(center + Vector2.from_angle(TAU * float(i + 1) / float(n)) * front)
			if view.has_point(b0) or view.has_point(b1):
				rows.append([minf(b0.y, b1.y), i, b0, b1])
		rows.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		var white := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
		for r: Array in rows:
			var i: int = r[1]
			var b0: Vector2 = r[2]
			var b1: Vector2 = r[3]
			var u0 := float(i) * seg / EvernightSky.WALL_TILE
			var u1 := float(i + 1) * seg / EvernightSky.WALL_TILE
			draw_primitive(PackedVector2Array([b0, b1, b1 + Vector2(0, -h), b0 + Vector2(0, -h)]), white,
				PackedVector2Array([Vector2(u0, 0.0), Vector2(u1, 0.0), Vector2(u1, 1.0), Vector2(u0, 1.0)]))


## A burning torch's warm halo (added light, flickering on its own beat: no luck) with sparks rising off it. Stands where the torch
## is held; `lit` false hides it and stops the sparks.
class TorchGlow extends Node2D:
	var phase := 0.0
	var clock := 0.0
	var lit := true
	var sparks: PixelParticles

	func _init(seed_value: int) -> void:
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = add
		phase = float(seed_value % 17)
		sparks = PixelParticles.new()
		sparks.rng.seed = seed_value
		sparks.shape = PixelParticles.Shape.STREAK
		sparks.ramp = PackedColorArray(EvernightSky.EMBERS)
		sparks.gravity = -30.0
		sparks.drag = 0.8
		sparks.auto_free = false
		sparks.rate = 9.0
		sparks.spec = {"radius": 3.0, "speed": Vector2(4, 16), "alt": Vector2(0, 3), "alt_speed": Vector2(25, 60),
			"life": Vector2(0.5, 1.1), "size": Vector2(1, 1.5)}
		sparks.emitting = true
		sparks.use_parent_material = false
		add_child(sparks)

	func _process(delta: float) -> void:
		clock += delta
		sparks.emitting = lit
		queue_redraw()

	func _draw() -> void:
		if not lit:
			return
		var f := 0.84 + 0.09 * sin(clock * 11.0 + phase) + 0.07 * sin(clock * 23.7 + phase * 2.0)
		# The flame's own halo where it is held up (its light on the ground and the people is the light field's and the shade's
		# warm island: more here blew the huddle out to white).
		draw_circle(Vector2.ZERO, 18.0 * f, Color(1.0, 0.55, 0.25, 0.07))
		draw_circle(Vector2.ZERO, 8.0 * f, Color(1.0, 0.68, 0.34, 0.16))
		draw_circle(Vector2.ZERO, 3.0 * f, Color(1.0, 0.86, 0.58, 0.5))


## A brief dark wisp rising from `screen_pos` (where a lone one was taken), on its own seed; it frees itself when spent.
static func wisp(fx: FxTimeline, parent: Node, screen_pos: Vector2, seed_value: int) -> PixelParticles:
	var p := PixelParticles.new()
	p.rng.seed = seed_value
	p.shape = PixelParticles.Shape.PUFF
	p.ramp = PackedColorArray(WISP)
	p.position = screen_pos
	p.gravity = -35.0
	p.drag = 1.2
	fx.track(p, parent)
	p.burst(11, {"radius": 5.0, "speed": Vector2(2, 10), "alt": Vector2(2, 12), "alt_speed": Vector2(18, 42),
		"life": Vector2(1.0, 1.7), "size": Vector2(2.5, 4.5), "size_end_mul": 1.9})
	return p
