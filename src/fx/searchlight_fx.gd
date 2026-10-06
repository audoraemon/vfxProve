class_name SearchlightFx
extends FxTimeline
## Halcyon's Searchlight drawn (v0.10 M4, spec §4.1 "Look"). It reads a Searchlight (extra "light") every frame and
## changes nothing in the world:
## - the Temple's spire glows like a lighthouse;
## - from the spire's lamp each lit beam falls as an additive gold cone onto its pool of light, with dust drifting in it;
## - each pool is a ground light registered with the LightField, so building faces and people in a beam light up;
## - while the light is on, the town is darkened with the impact dim.
## It lasts until end_now() (the director let go). The light put out (the flame home) fades the cones, the pools and
## the dim away over FADE_SECONDS.

## The spire's lamp: how far above the Temple's ground point it stands (screen pixels), its glow's radius, and the
## cone's half-width at the lamp.
const SPIRE_PX := 96.0
const SPIRE_GLOW_PX := 22.0
const LAMP_HALF := 2.0
## The cones: additive gold, brighter at the lamp than at the foot.
const COL_CONE := Color(1.0, 0.84, 0.45)
const CONE_TOP_A := 0.28
const CONE_FOOT_A := 0.08
## The pools of light on the ground (and in the LightField).
const COL_POOL := Color(1.0, 0.86, 0.52)
const POOL_INTENSITY := 1.0
## How dark the town goes under the light (Impact.dim(), scaled by the mission's dim_scale), how fast, and how long the
## light takes to come up or fade.
const DIM := 0.6
const DIM_SPEED := 0.8
const FADE_SECONDS := 1.0
## Dust drifting in each beam: its colours and motes a second.
const DUST := [Color("fff6d8"), Color("ffe08a"), Color(1.0, 0.82, 0.45, 0.6)]
const DUST_RATE := 10.0

var light: Searchlight
var _cones: Node2D
var _glow: QuadFx
var _pools: Array[QuadFx] = []
var _dust: Array[PixelParticles] = []
## The light's own fade (the glow and the dim), and each beam's: a beam comes up when it lights and fades when it goes
## out (the light put out, or the beam count dropping), with where it last lit so a fading beam stays put.
var _fade := 0.0
var _beam_fade: Array[float] = [0.0, 0.0]
var _last: Array[Vector2] = []


## One frame of a beam's fade: up while lit, down while not, over FADE_SECONDS. Pure, for the tests.
static func fade_step(current: float, lit: bool, delta: float) -> float:
	return move_toward(current, 1.0 if lit else 0.0, delta / FADE_SECONDS)


## The cone from the lamp at `top` (screen) onto a pool of ground radius `r` at ground `aim`: the lamp's two sides,
## then the pool's two sides across the beam's direction (its ellipse's reach that way). Pure, for the tests.
static func cone_points(top: Vector2, aim: Vector2, r: float) -> PackedVector2Array:
	var foot := Iso.ground_to_screen(aim)
	var along := foot - top
	var across := along.orthogonal().normalized() if along.length() > 0.01 else Vector2.RIGHT
	var semi := Iso.radius_to_screen(r)
	var half := sqrt(pow(semi.x * across.x, 2.0) + pow(semi.y * across.y, 2.0))
	return PackedVector2Array([top + across * LAMP_HALF, top - across * LAMP_HALF, foot - across * half,
		foot + across * half])


func _build() -> void:
	duration = 1.0e9
	light = extra.get("light") as Searchlight
	_cones = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_cones.material = add
	_cones.z_index = 4
	_cones.draw.connect(_draw_cones)
	track(_cones, ctx.overhead)
	if light == null:
		return
	_last = [light.spire, light.spire]
	_glow = FxParts.bloom(self, _lamp(), SPIRE_GLOW_PX, COL_CONE, 0.0)
	for i in Searchlight.MAX_BEAMS:
		var q := FxParts.quad(self, FxParts.SH_LIGHT, Vector2.ONE * Searchlight.POOL_R * 2.0, ctx.ground)
		q.position = light.spire
		q.z_index = 6
		q.set_param("color", COL_POOL)
		q.set_param("intensity", 0.0)
		if ctx.lights != null:
			var k := i
			ctx.lights.register_quad(q, light.spire, Searchlight.POOL_R * 1.15, COL_POOL, func() -> Vector2: return _lit_at(k))
		_pools.append(q)
		var d := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(light.spire), PixelParticles.Shape.SQUARE, DUST)
		d.auto_free = false
		d.gravity = -6.0
		d.rate = DUST_RATE
		d.spec = {"radius": 22.0, "speed": Vector2(1, 5), "alt": Vector2(2, 30), "alt_speed": Vector2(2, 8),
			"life": Vector2(1.0, 2.0), "size": Vector2(1, 1)}
		_dust.append(d)
	ctx.play(&"grav_shimmer", light.spire, -6.0)


func _fx_process(delta: float) -> void:
	if light == null:
		return
	var was := _fade
	_fade = move_toward(_fade, 1.0 if light.on else 0.0, delta / FADE_SECONDS)
	if ctx.impact != null and (_fade > 0.0 or was > 0.0):
		ctx.impact.dim(DIM * _fade, DIM_SPEED)
	if is_instance_valid(_glow):
		_glow.set_param("intensity", _fade * (0.85 + 0.15 * sin(t * 2.4)))
	for i in _pools.size():
		var lit := i < light.beams()
		if lit:
			_last[i] = light.aim(i)  # a beam fading out keeps the place it last lit
		_beam_fade[i] = fade_step(_beam_fade[i], lit, delta)
		_pools[i].position = _last[i]
		_pools[i].set_param("intensity", POOL_INTENSITY * _beam_fade[i])
		_dust[i].emitting = lit
		_dust[i].position = Iso.ground_to_screen(_last[i])
	_cones.queue_redraw()


## Let go while the light is still on: the town must not stay dark, so the dim goes with it.
func end_now() -> void:
	if not finished and ctx != null and ctx.impact != null and _fade > 0.0:
		ctx.impact.dim(0.0, DIM_SPEED)
	super.end_now()


## Where beam i's pool is: where it is now while lit, else where it last was (the spire before its first lighting).
func _lit_at(i: int) -> Vector2:
	return light.aim(i) if i < light.beams() else _last[i]


func _lamp() -> Vector2:
	return Iso.ground_to_screen(light.spire) + Vector2(0.0, -SPIRE_PX)


func _draw_cones() -> void:
	if light == null:
		return
	var top := _lamp()
	for i in _pools.size():
		if _beam_fade[i] <= 0.0:
			continue
		var top_c := Color(COL_CONE, CONE_TOP_A * _beam_fade[i])
		var foot_c := Color(COL_CONE, CONE_FOOT_A * _beam_fade[i])
		_cones.draw_polygon(cone_points(top, _last[i], Searchlight.POOL_R),
			PackedColorArray([top_c, top_c, foot_c, foot_c]))
