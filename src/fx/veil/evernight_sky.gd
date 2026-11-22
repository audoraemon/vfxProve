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
## The wall's height in pixels at full size, and the pixels of wall per noise tile along it.
const WALL_H := 420.0
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

## The night's absolute z (VRF1): the shade just over the world (0-1: people, houses and the pieces standing among them), the moon,
## the air and the wall over it (in that tree order), all under the aim (Targeting, absolute 5), so the ring, the previews, the kill
## colour and the DARK / LIGHT tag are never multiplied by the night. The HUD is a CanvasLayer of its own, over all of it.
const Z_SHADE := 2
const Z_AIR := 3
## The size of evernight_shade.gdshader's `uniform vec2 torches[6]` (a shader cannot read GDScript: the pair is named on both sides).
## EvernightFx asserts its TORCHES fits.
const SHADE_TORCHES := 6

static var _white: ImageTexture


static func white() -> ImageTexture:
	if _white == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	return _white


## The rect every town-wide quad draws (world pixels): far past any town and any zoom, so no edge of it is ever in view. (Fitting it to
## the camera's view left its edges on screen at zoom 2.2: hard upright and level lines through the night, fix round 1.) The GPU
## shades only the pixels in view.
const COVER := Rect2(-20000.0, -20000.0, 40000.0, 40000.0)


## A quad over the whole town (COVER) with one of the night's shaders (the shade or the air).
class View extends Node2D:
	var mat := ShaderMaterial.new()

	func _init(shader: Shader) -> void:
		mat.shader = shader
		material = mat

	func set_param(param: StringName, value: Variant) -> void:
		mat.set_shader_parameter(param, value)

	func _draw() -> void:
		draw_texture_rect(EvernightSky.white(), EvernightSky.COVER, false)


## A wall of night standing on the ring of `front` ground units round `center` (Evernight's front; The Swallowing Dark's rim). One
## quad over the ring's bounds; the shader finds the near and far walls at each pixel, so the wall has no joins at all
## (drawn as a strip of quads it broke at every join, fix round 1). `height` in pixels; with `rise_with_front` it is lower while the
## ring is small.
class Wall extends Node2D:
	var center := Vector2.ZERO
	var front := 0.0
	var amount := 0.0
	var height := EvernightSky.WALL_H
	var rise_with_front := true
	var mat := ShaderMaterial.new()

	func _init() -> void:
		mat.shader = EvernightSky.SH_WALL
		material = mat

	func _draw() -> void:
		if amount <= 0.0 or front <= 0.05:
			return
		var semi := Iso.radius_to_screen(front)
		var h := height * (clampf(front / 12.0, 0.45, 1.0) if rise_with_front else 1.0)
		var c := Iso.ground_to_screen(center)
		var box := Rect2(c.x - semi.x, c.y - semi.y - h * 1.3, semi.x * 2.0, semi.y * 2.0 + h * 1.3)
		mat.set_shader_parameter(&"amount", amount)
		mat.set_shader_parameter(&"ring_c", c)
		mat.set_shader_parameter(&"ring_a", semi.x)
		mat.set_shader_parameter(&"ring_b", semi.y)
		mat.set_shader_parameter(&"wall_h", h)
		mat.set_shader_parameter(&"tiles", maxf(semi.x / EvernightSky.WALL_TILE, 0.25))
		draw_texture_rect(EvernightSky.white(), box, false)


## A burning torch's warm halo (added light, flickering on its own beat: no luck) with sparks rising off it. Stands where the torch
## is held; `lit` false hides it and stops the sparks.
class TorchGlow extends Node2D:
	var phase := 0.0
	var clock := 0.0
	var lit := true
	## 0..1: how much of it shows (at dawn it fades with the night, VRF5d).
	var fade := 1.0
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
		sparks.emitting = lit and fade > 0.5
		queue_redraw()

	func _draw() -> void:
		if not lit or fade <= 0.0:
			return
		var f := 0.84 + 0.09 * sin(clock * 11.0 + phase) + 0.07 * sin(clock * 23.7 + phase * 2.0)
		# The flame's own halo where it is held up (its light on the ground and the people is the light field's and the shade's
		# warm island: more here blew the huddle out to white).
		draw_circle(Vector2.ZERO, 18.0 * f, Color(1.0, 0.55, 0.25, 0.07 * fade))
		draw_circle(Vector2.ZERO, 8.0 * f, Color(1.0, 0.68, 0.34, 0.16 * fade))
		draw_circle(Vector2.ZERO, 3.0 * f, Color(1.0, 0.86, 0.58, 0.5 * fade))


## A brief dark wisp rising from `screen_pos` (where one was taken), `puffs` puffs on its own seed; it frees itself when spent.
static func wisp(fx: FxTimeline, parent: Node, screen_pos: Vector2, seed_value: int, puffs := 11) -> PixelParticles:
	var p := PixelParticles.new()
	p.rng.seed = seed_value
	p.shape = PixelParticles.Shape.PUFF
	p.ramp = PackedColorArray(WISP)
	p.position = screen_pos
	p.gravity = -35.0
	p.drag = 1.2
	fx.track(p, parent)
	p.burst(puffs, {"radius": 5.0, "speed": Vector2(2, 10), "alt": Vector2(2, 12), "alt_speed": Vector2(18, 42),
		"life": Vector2(1.0, 1.7), "size": Vector2(2.5, 4.5), "size_end_mul": 1.9})
	return p
