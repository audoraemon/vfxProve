class_name FxParts
extends RefCounted
## Shared VFX building blocks. Every builder parents + tracks the node on the given effect.

const SH_RINGS := preload("res://shaders/iso_rings.gdshader")
const SH_SHOCK := preload("res://shaders/shockwave.gdshader")
const SH_DOME := preload("res://shaders/fireball_dome.gdshader")
const SH_BEAM := preload("res://shaders/beam_glow.gdshader")
const SH_DECAL := preload("res://shaders/scorch_decal.gdshader")
const SH_FOG := preload("res://shaders/fog.gdshader")
const SH_SING := preload("res://shaders/singularity.gdshader")
const SH_LIGHT := preload("res://shaders/light_glow.gdshader")
const SH_RAYS := preload("res://shaders/god_rays.gdshader")
const SH_HAZE := preload("res://shaders/heat_haze.gdshader")
const SH_REFRACT := preload("res://shaders/refract_ring.gdshader")
const SH_BEAM_ADD := preload("res://shaders/beam_add.gdshader")
const SH_MOLTEN := preload("res://shaders/molten_trail.gdshader")
const SH_MUSHROOM := preload("res://shaders/mushroom_cloud.gdshader")
const SH_FROST := preload("res://shaders/frost_ground.gdshader")

## Vertical screen pixels per ground unit along a ground radius (minor ellipse axis).
const PX_PER_UNIT_MINOR := 16.0 * sqrt(2.0)
## Horizontal screen pixels per ground unit along a ground radius (major ellipse axis).
const PX_PER_UNIT_MAJOR := 32.0 * sqrt(2.0)

# Shader ramps: darkest -> brightest (c0..c4).
const FIRE := [Color(0.35, 0.04, 0.03, 0.55), Color("b3240f"), Color("ff6a1a"), Color("ffc14a"), Color("fff6d8")]
const VOID := [Color(0.1, 0.02, 0.18, 0.6), Color("3b1470"), Color("7a3cf0"), Color("b98cff"), Color("f4ecff")]
const ICE := [Color(0.06, 0.12, 0.3, 0.55), Color("2a5aa8"), Color("5aa0e8"), Color("b8e6ff"), Color("f4fcff")]
const ICE_WAVE := [Color(0.55, 0.78, 1.0, 0.3), Color("8cc8f0"), Color("c8ecff"), Color("eaf8ff"), Color("ffffff")]
const LASER := [Color(0.45, 0.03, 0.05, 0.5), Color("c8141e"), Color("ff3a2a"), Color("ff9a6a"), Color("fff0e8")]
const ION := [Color(0.05, 0.12, 0.35, 0.5), Color("1f4fd6"), Color("2fa0ff"), Color("8fe6ff"), Color("f0fdff")]

# Particle lifetime ramps: first color at birth.
const FIRE_LIFE := [Color("fff6d8"), Color("ffc14a"), Color("ff6a1a"), Color("b3240f"), Color(0.35, 0.05, 0.03, 0.7)]
const EMBER_LIFE := [Color("ffd27a"), Color("ff8a2a"), Color("d0401a"), Color(0.45, 0.1, 0.05, 0.6)]
const SMOKE_LIFE := [Color("54443d"), Color("463f3d"), Color("3a383b"), Color("302f34"), Color(0.17, 0.17, 0.2, 0.8), Color(0.13, 0.13, 0.15, 0.45)]
const DUST_LIFE := [Color("7a6656"), Color("675a50"), Color(0.33, 0.3, 0.29, 0.85), Color(0.24, 0.23, 0.23, 0.55)]
const LAVA := [Color("4a0c06"), Color("9a1e0a"), Color("e04a12"), Color("ffa030"), Color("fff0b0")]
const DUST_RING := [Color(0.2, 0.16, 0.13, 0.5), Color("4a3c32"), Color("6e5848"), Color("9a7e62"), Color("c8a47a")]
const ROCK := [Color("5d6170"), Color("4b4f5b"), Color("3a3d47"), Color("2b2d35")]
const HOT_ROCK := [Color("ffc060"), Color("e0602a"), Color("8a3a22"), Color("4a3632"), Color("33343c")]
const RAD_LIFE := [Color("f0ffb0"), Color("a8ff4a"), Color("5fcf2a"), Color(0.2, 0.5, 0.1, 0.55)]
const ION_LIFE := [Color("f0fdff"), Color("8fe6ff"), Color("2fa0ff"), Color(0.1, 0.3, 0.8, 0.5)]
const VOID_LIFE := [Color("f4ecff"), Color("b98cff"), Color("7a3cf0"), Color("3b1470"), Color(0.12, 0.03, 0.2, 0.5)]
const ICE_LIFE := [Color("ffffff"), Color("dff4ff"), Color("8cc8f0"), Color("4f8fd0"), Color(0.18, 0.36, 0.7, 0.5)]
const ICE_CHUNK := [Color("eaf8ff"), Color("a8dcff"), Color("5a9ee0"), Color("2e5a98")]
const SNOW_LIFE := [Color("ffffff"), Color("eef8ff"), Color(0.85, 0.93, 1.0, 0.7), Color(0.8, 0.9, 1.0, 0.35)]
const MIST_LIFE := [Color(0.85, 0.92, 1.0, 0.45), Color(0.75, 0.85, 0.98, 0.35), Color(0.65, 0.78, 0.95, 0.22)]
const LASER_LIFE := [Color("fff0e8"), Color("ff9a6a"), Color("ff3a2a"), Color("c8141e"), Color(0.4, 0.03, 0.05, 0.5)]


## Draw every VFX shader once, nearly invisible, so the renderer compiles them up front
## instead of hitching on an effect's first impact frame.
static func prewarm(parent: Node2D, frames := 3) -> void:
	for shader in [SH_RINGS, SH_SHOCK, SH_DOME, SH_BEAM, SH_DECAL, SH_FOG, SH_SING, SH_LIGHT, SH_RAYS, SH_HAZE, SH_REFRACT, SH_BEAM_ADD, SH_MOLTEN, SH_MUSHROOM, SH_FROST, preload("res://shaders/tsunami_wall.gdshader"), preload("res://shaders/tsunami_body.gdshader"), preload("res://shaders/flood_water.gdshader"), preload("res://shaders/flame_stream.gdshader"), preload("res://shaders/tornado_funnel.gdshader"), preload("res://shaders/fire_cone.gdshader")]:
		var q := QuadFx.new().setup(shader, Vector2(4, 4))
		q.modulate.a = 0.02
		parent.add_child(q)
		for i in frames:
			await parent.get_tree().process_frame
		q.queue_free()


static func quad(fx: FxTimeline, shader: Shader, size: Vector2, parent: Node, anchor := Vector2(0.5, 0.5)) -> QuadFx:
	var q := QuadFx.new().setup(shader, size, anchor)
	fx.track(q, parent)
	return q


static func set_ramp(q: QuadFx, ramp: Array) -> void:
	for i in 5:
		q.set_param("c%d" % i, ramp[i])


static func px_for_radius(radius: float) -> float:
	return 1.0 / (PX_PER_UNIT_MINOR * radius)


## Screen-pixel spawn radius (major axis) of a ground radius, for PixelParticles.
static func particle_radius(ground_radius: float) -> float:
	return PX_PER_UNIT_MAJOR * ground_radius


# --- Ground plane --------------------------------------------------------

static func rings(fx: FxTimeline, center: Vector2, radius: float, color: Color, count := 4, dashes := 18.0) -> QuadFx:
	var q := quad(fx, SH_RINGS, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = center
	q.z_index = 3
	q.set_param("color", color)
	q.set_param("rings", float(count))
	q.set_param("dashes", dashes)
	q.set_param("px", px_for_radius(radius))
	return q


static func shockwave(fx: FxTimeline, center: Vector2, radius: float, ramp: Array = FIRE) -> QuadFx:
	var q := quad(fx, SH_SHOCK, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = center
	q.z_index = 4
	q.set_param("px", px_for_radius(radius))
	set_ramp(q, ramp)
	return q


static func decal(fx: FxTimeline, center: Vector2, radius: float, edge := Color("ff6a1a"), edge_hot := Color("ffd27a"),
		char_color := Color(0.06, 0.045, 0.04, 0.9), warp := 0.0) -> QuadFx:
	var q := quad(fx, SH_DECAL, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = center
	q.z_index = 1
	q.set_param("edge_color", edge)
	q.set_param("edge_hot", edge_hot)
	q.set_param("char_color", char_color)
	q.set_param("warp", warp)
	q.set_param("seed", fx.ctx.rng.randf() * 100.0)
	return q


static func fog(fx: FxTimeline, center: Vector2, radius: float, color: Color) -> QuadFx:
	var q := quad(fx, SH_FOG, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = center
	q.z_index = 5
	q.set_param("color", color)
	return q


## Additive light pool on the ground (lights tiles, decals; enemies stay unlit above it).
static func ground_light(fx: FxTimeline, center: Vector2, radius: float, color: Color, intensity := 1.0) -> QuadFx:
	var q := quad(fx, SH_LIGHT, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = center
	q.z_index = 6
	q.set_param("color", color)
	q.set_param("intensity", intensity)
	# Every light pool also lights structures and enemies.
	if fx.ctx.lights != null:
		fx.ctx.lights.register_quad(q, center, radius * 1.15, color)
	return q


## Radial god-rays streaking across the ground from center.
static func ground_rays(fx: FxTimeline, center: Vector2, radius: float, color: Color, count := 64.0) -> QuadFx:
	var q := quad(fx, SH_RAYS, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = center
	q.z_index = 7
	q.set_param("color", color)
	q.set_param("count", count)
	q.set_param("radius_px", (PX_PER_UNIT_MAJOR + PX_PER_UNIT_MINOR) * 0.5 * radius)
	return q


# --- Screen space --------------------------------------------------------

## Additive round bloom in screen space (px radius), drawn over everything below the distort layer.
static func bloom(fx: FxTimeline, screen_pos: Vector2, radius_px: float, color: Color, intensity := 1.0,
		squash := 1.0) -> QuadFx:
	var q := quad(fx, SH_LIGHT, Vector2(radius_px * 2.0, radius_px * 2.0 * squash), fx.ctx.overhead)
	q.position = screen_pos
	q.z_index = 5
	q.set_param("color", color)
	q.set_param("intensity", intensity)
	return q


## Screen-space rays (round), e.g. a starburst over an explosion.
static func screen_rays(fx: FxTimeline, screen_pos: Vector2, radius_px: float, color: Color, count := 48.0,
		squash := 1.0) -> QuadFx:
	var q := quad(fx, SH_RAYS, Vector2(radius_px * 2.0, radius_px * 2.0 * squash), fx.ctx.overhead)
	q.position = screen_pos
	q.z_index = 6
	q.set_param("color", color)
	q.set_param("count", count)
	q.set_param("radius_px", radius_px)
	return q


## Screen-refracting shock ring over a ground radius; drive `progress` 0..1.
static func refract_ring(fx: FxTimeline, center: Vector2, radius: float, tint: Color) -> QuadFx:
	var size := Iso.radius_to_screen(radius) * 2.0
	var q := quad(fx, SH_REFRACT, size, fx.ctx.distort)
	q.position = Iso.ground_to_screen(center)
	q.set_param("size_px", size)
	q.set_param("tint", tint)
	return q


## Frozen-ground decal on the ground plane; drive `progress` 0..1 to spread it.
static func frost_ground(fx: FxTimeline, center: Vector2, radius: float) -> QuadFx:
	var q := quad(fx, SH_FROST, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = center
	q.z_index = 2
	q.set_param("seed", fx.ctx.rng.randf() * 40.0)
	return q


## Heat shimmer over a ground point; semi_px = half width in px (ellipse 2:1).
static func heat_haze(fx: FxTimeline, screen_pos: Vector2, semi_px: float, strength := 2.0) -> QuadFx:
	var q := quad(fx, SH_HAZE, Vector2(semi_px * 2.0, semi_px * 1.4), fx.ctx.distort)
	q.position = screen_pos + Vector2(0, -semi_px * 0.35)
	q.set_param("strength", strength)
	return q


## Vertical beam standing on screen_pos (bottom center).
static func beam(fx: FxTimeline, parent: Node, screen_pos: Vector2, width: float, height: float, ramp: Array = FIRE) -> QuadFx:
	var q := quad(fx, SH_BEAM, Vector2(width, height), parent, Vector2(0.5, 1.0))
	q.position = screen_pos
	set_ramp(q, ramp)
	return q


## Beam from screen point a to b.
static func link_beam(fx: FxTimeline, parent: Node, a: Vector2, b: Vector2, width: float, ramp: Array = LASER) -> QuadFx:
	var q := quad(fx, SH_BEAM, Vector2(width, maxf(a.distance_to(b), 1.0)), parent, Vector2(0.5, 0.0))
	q.position = a
	q.rotation = (b - a).angle() - PI * 0.5
	q.set_param("taper", 0.0)
	q.set_param("bands", maxf(a.distance_to(b) / 6.0, 1.0))
	set_ramp(q, ramp)
	return q


## Fireball dome over screen_pos; semi_x = half width in px.
static func dome(fx: FxTimeline, screen_pos: Vector2, semi_x: float, ramp: Array = FIRE) -> QuadFx:
	# Quad reaches 1.0 radii above ground (dome top is 0.866) so the billowing surface is never clipped.
	const DOME := 1.0
	const BASE := 0.62
	const WIDTH := 1.16
	var q := quad(fx, SH_DOME, Vector2(semi_x * 2.0 * WIDTH, semi_x * (DOME + BASE)), fx.ctx.overhead,
		Vector2(0.5, DOME / (DOME + BASE)))
	q.set_param("width_ratio", WIDTH)
	q.position = screen_pos
	q.set_param("dome_ratio", DOME)
	q.set_param("seed", fx.ctx.rng.randf() * 40.0)
	q.set_param("base_ratio", BASE)
	set_ramp(q, ramp)
	return q


## Screen-distorting singularity over a ground point, covering a ground radius.
static func singularity(fx: FxTimeline, center: Vector2, radius: float, ramp: Array = VOID) -> QuadFx:
	var size := Iso.radius_to_screen(radius) * 2.0
	var q := quad(fx, SH_SING, size, fx.ctx.distort)
	q.position = Iso.ground_to_screen(center)
	q.set_param("size_px", size)
	set_ramp(q, ramp)
	return q


static func particles(fx: FxTimeline, parent: Node, screen_pos: Vector2, shape: PixelParticles.Shape, ramp: Array) -> PixelParticles:
	var p := PixelParticles.new()
	p.rng.seed = fx.ctx.rng.randi()
	p.shape = shape
	p.ramp = PackedColorArray(ramp)
	p.position = screen_pos
	fx.track(p, parent)
	return p


static func debris(fx: FxTimeline, screen_pos: Vector2, count: int, radius_px: float, speed := Vector2(30, 200),
		ramp: Array = ROCK, size := Vector2(1.5, 4.5), outward := false) -> PixelParticles:
	var p := particles(fx, fx.ctx.overhead, screen_pos, PixelParticles.Shape.CHUNK, ramp)
	p.gravity = 420.0
	p.bounce = true
	p.drag = 0.6
	p.shadows = true
	p.burst(count, {
		"radius": radius_px, "speed": speed, "alt": Vector2(0, 6), "alt_speed": Vector2(60, 280),
		"life": Vector2(1.2, 2.4), "size": size,
		"dir": PixelParticles.Dir.OUTWARD if outward else PixelParticles.Dir.ANGLE,
	})
	return p


static func sparks(fx: FxTimeline, parent: Node, screen_pos: Vector2, count: int, ramp: Array = FIRE_LIFE,
		speed := Vector2(80, 300), alt_speed := Vector2(20, 180)) -> PixelParticles:
	var p := particles(fx, parent, screen_pos, PixelParticles.Shape.STREAK, ramp)
	p.gravity = 260.0
	p.drag = 1.5
	p.burst(count, {
		"speed": speed, "alt": Vector2(2, 10), "alt_speed": alt_speed, "life": Vector2(0.25, 0.7),
		"size": Vector2(1, 2),
	})
	return p


## Continuous emitter that stops after `seconds`.
static func emitter(fx: FxTimeline, parent: Node, screen_pos: Vector2, shape: PixelParticles.Shape, ramp: Array,
		rate: float, seconds: float, spec: Dictionary) -> PixelParticles:
	var p := particles(fx, parent, screen_pos, shape, ramp)
	p.rate = rate
	p.spec = spec
	p.emitting = true
	var stop_at := fx.t + seconds
	fx.at(stop_at, func():
		if is_instance_valid(p):
			p.emitting = false)
	return p


static func smoke(fx: FxTimeline, screen_pos: Vector2, radius_px: float, rate: float, seconds: float,
		rise := Vector2(20, 50), size := Vector2(3, 6), life := Vector2(1.2, 2.2), underglow := Color(0, 0, 0, 0)) -> PixelParticles:
	var p := emitter(fx, fx.ctx.overhead_back, screen_pos, PixelParticles.Shape.PUFF, SMOKE_LIFE, rate, seconds, {
		"radius": radius_px, "speed": Vector2(4, 18), "alt": Vector2(0, 8), "alt_speed": rise,
		"life": life, "size": size, "size_end_mul": 1.8,
	})
	p.drag = 0.4
	p.underglow = underglow
	return p
