extends FxTimeline
## Gravity Distortion: field forms -> pull -> compression -> implosion -> warped scar.

const RADIUS := 4.5
const T_PULL := 0.8
const T_COMPRESS := 3.5
const T_IMPLODE := 4.1
const KILL_R := 1.5
const RUBBLE_COUNT := 36


## Rock chunks orbiting and spiraling in, then blasted out. Simulated around the cast origin.
class Rubble:
	extends Node2D

	const COL := [Color("4a4758"), Color("5d5a6e"), Color("3a3846")]
	const COL_TOP := Color("76708a")
	const COL_RIM := Color("b98cff")

	var origin := Vector2.ZERO
	var radius := 4.5
	## 0..1 pull intensity; 0 = dormant.
	var pull := 0.0
	var exploded := false
	var rng: RandomNumberGenerator
	var chunks: Array[Dictionary] = []

	func setup(count: int) -> void:
		for i in count:
			chunks.append(_new_chunk(rng.randf_range(radius * 0.5, radius)))

	func _new_chunk(r: float) -> Dictionary:
		return {
			"a": rng.randf() * TAU, "r": r, "alt": rng.randf_range(0.0, 4.0), "vel": Vector2.ZERO,
			"valt": 0.0, "w": rng.randi_range(3, 5), "h": rng.randi_range(3, 4), "c": rng.randi() % 3,
			"life": 1.0,
		}

	func explode() -> void:
		exploded = true
		for c in chunks:
			var dir := Vector2.RIGHT.rotated(c.a)
			c.vel = Vector2(dir.x, dir.y * 0.5) * rng.randf_range(120.0, 320.0)
			c.valt = rng.randf_range(60.0, 220.0)
			c.pos = (Iso.ground_to_screen(origin + dir * c.r) - Iso.ground_to_screen(origin))
			c.life = rng.randf_range(0.8, 1.5)

	func _process(delta: float) -> void:
		for c in chunks:
			if exploded:
				c.pos += c.vel * delta
				c.vel *= maxf(1.0 - 1.2 * delta, 0.0)
				c.valt -= 420.0 * delta
				c.alt = maxf(c.alt + c.valt * delta, 0.0)
				c.life -= delta
			elif pull > 0.0:
				var k: float = 1.0 - c.r / radius
				c.a += (0.6 + 3.0 * k * k) * pull * delta
				c.r -= (0.3 + 2.2 * k) * pull * delta
				c.alt = move_toward(c.alt, 6.0 + 26.0 * k * pull, 30.0 * delta)
				if c.r < 0.3:
					var fresh := _new_chunk(radius * rng.randf_range(0.85, 1.0))
					c.merge(fresh, true)
		queue_redraw()

	func _draw() -> void:
		for c in chunks:
			var at: Vector2
			if exploded:
				if c.life <= 0.0:
					continue
				at = c.pos
			else:
				at = Iso.ground_to_screen(origin + Vector2.RIGHT.rotated(c.a) * c.r) - Iso.ground_to_screen(origin)
			at = (at + Vector2(0, -c.alt)).round()
			var w: int = c.w
			var h: int = c.h
			draw_rect(Rect2(at.x - 1, at.y + c.alt, w, 1), Color(0, 0, 0, 0.35))
			draw_rect(Rect2(at, Vector2(w, h)), COL[c.c])
			draw_rect(Rect2(at, Vector2(w, 1)), COL_TOP)
			if not exploded and pull > 0.5:
				draw_rect(Rect2(at + Vector2(w, 1), Vector2.ONE), COL_RIM)


var _center_px := Vector2.ZERO
var _rings: QuadFx
var _sing: QuadFx
var _streaks: PixelParticles
var _rubble: Rubble
var _imploded := false
var _voices: Array[Node] = []


func _build() -> void:
	duration = 6.6
	_center_px = Iso.ground_to_screen(origin)

	_rings = FxParts.rings(self, origin, RADIUS, Color("9a5cff"), 5, 22.0)
	_rings.set_param("fill", 0.16)
	_rings.set_param("pulse", 0.5)
	_rings.tween_param("reveal", 0.0, 1.0, 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	_sing = FxParts.singularity(self, origin, RADIUS)

	_rubble = Rubble.new()
	_rubble.rng = ctx.rng
	_rubble.origin = origin
	_rubble.radius = RADIUS
	_rubble.position = _center_px
	_rubble.setup(RUBBLE_COUNT)
	track(_rubble, ctx.overhead)

	_voices.append(ctx.play(&"grav_field", origin))
	_voices.append(ctx.play(&"grav_drone", origin, -3.0))
	at(T_PULL, _start_pull)
	at(T_COMPRESS, func(): _voices.append(ctx.play(&"grav_compress", origin)))
	at(T_IMPLODE, _implode)


func _start_pull() -> void:
	_voices.append(ctx.play(&"grav_suction", origin))
	_streaks = FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.STREAK,
		[Color("3b1470"), Color("7a3cf0"), Color("b98cff"), Color("f4ecff")], 70.0, T_IMPLODE - T_PULL, {
			"radius": FxParts.particle_radius(RADIUS), "dir": PixelParticles.Dir.INWARD, "speed": Vector2(150, 260),
			"life": Vector2(0.5, 0.9), "size": Vector2(2, 4),
		})
	_streaks.streak_len = 0.05


## Piecewise-linear lookup over (time, value) keys.
func _curve(keys: Array) -> float:
	if t <= keys[0][0]:
		return keys[0][1]
	for i in range(1, keys.size()):
		if t <= keys[i][0]:
			var k: float = (t - keys[i - 1][0]) / (keys[i][0] - keys[i - 1][0])
			return lerpf(keys[i - 1][1], keys[i][1], k)
	return keys[-1][1]


func _fx_process(delta: float) -> void:
	if _imploded:
		return
	var strength := _curve([[0.0, 0.0], [T_PULL, 0.6], [T_COMPRESS, 2.4], [T_IMPLODE, 3.6]])
	var pinch := _curve([[0.0, 0.0], [T_PULL, 0.12], [T_COMPRESS, 0.35], [T_IMPLODE, 0.65]])
	var core := _curve([[0.0, 0.0], [T_PULL, 7.0], [T_COMPRESS, 19.0], [T_IMPLODE, 5.0]])
	var arms := _curve([[0.0, 0.0], [T_PULL, 0.35], [T_PULL + 1.0, 1.0], [T_IMPLODE, 1.0]])
	var compress := clampf((t - T_COMPRESS) / (T_IMPLODE - T_COMPRESS), 0.0, 1.0)
	if compress > 0.0:
		# Unstable flicker as the core collapses.
		core *= 1.0 + 0.35 * sin(t * 70.0) * compress
		_rings.set_param("reveal", lerpf(1.0, 0.3, compress * compress))
		ctx.shake.add_trauma(0.9 * delta)
	_sing.set_param("strength", strength)
	_sing.set_param("pinch", pinch)
	_sing.set_param("core_px", core)
	_sing.set_param("arm_alpha", arms)
	_sing.set_param("rim_boost", compress)

	_rubble.pull = clampf((t - 0.3) / T_PULL, 0.0, 1.0) * (1.0 + compress)
	if t >= T_PULL:
		var pull_strength := _curve([[T_PULL, 0.8], [T_COMPRESS, 3.2], [T_IMPLODE, 4.2]])
		ctx.field.pull(origin, RADIUS, pull_strength, 1.0, delta)


func _implode() -> void:
	_imploded = true
	for v in _voices:
		ctx.fade_out(v, 0.03)
	at(T_IMPLODE + 0.08, func(): ctx.play(&"grav_implode", origin))
	at(T_IMPLODE + 0.2, func(): ctx.play(&"grav_shimmer", origin, -4.0))

	ctx.flash.call(Color(0.06, 0.0, 0.12, 0.85), 0.07)
	at(T_IMPLODE + 0.07, func(): ctx.flash.call(Color(0.85, 0.72, 1.0, 0.9), 0.4))
	ctx.shake.add_trauma(0.95)

	_sing.queue_free()
	_rings.tween_param("alpha", 1.0, 0.0, 0.15)

	for e in ctx.field.in_radius(origin, KILL_R):
		ctx.field.kill(e, &"gravity")
	ctx.field.release_all()
	ctx.field.knock_from(origin, 0.0, RADIUS + 1.0, 7.0)

	var wave := FxParts.shockwave(self, origin, RADIUS, FxParts.VOID)
	wave.set_param("thickness", 0.1)
	wave.tween_param("progress", 0.02, 1.0, 0.6, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.35, 0.3)
	wave.life = 0.7

	var burst := FxParts.dome(self, _center_px, FxParts.PX_PER_UNIT_MAJOR * 1.5, FxParts.VOID)
	burst.tween_param("grow", 0.1, 1.0, 0.14, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	burst.tween_param("heat", 1.3, 0.6, 0.4)
	burst.tween_param("dissolve", 0.0, 1.0, 0.3, 0.12, Tween.TRANS_QUAD, Tween.EASE_IN)
	burst.life = 0.45

	var radial := FxParts.particles(self, ctx.overhead, _center_px, PixelParticles.Shape.STREAK, FxParts.VOID_LIFE)
	radial.drag = 1.8
	radial.streak_len = 0.05
	radial.burst(150, {
		"radius": 6.0, "dir": PixelParticles.Dir.ANGLE, "speed": Vector2(160, 460), "alt": Vector2(4, 16),
		"life": Vector2(0.3, 0.8), "size": Vector2(2, 4),
	})
	_rubble.explode()

	var scar := FxParts.decal(self, origin, 3.0, Color("7a3cf0"), Color("e6d4ff"), Color(0.05, 0.02, 0.09, 0.85), 1.0)
	scar.tween_param("heat", 1.0, 0.25, 2.2)
	scar.tween_param("fade", 1.0, 0.0, 0.9, duration - T_IMPLODE - 1.0)

	var ripple := FxParts.rings(self, origin, 3.2, Color("b98cff"), 3, 14.0)
	ripple.set_param("scan", 0.0)
	ripple.set_param("fill", 0.0)
	ripple.set_param("crosshair", 0.0)
	ripple.set_param("alpha", 0.0)
	ripple.tween_param("alpha", 0.0, 0.5, 0.4, 0.3)
	ripple.tween_param("alpha", 0.5, 0.0, 1.2, duration - T_IMPLODE - 1.3)

	FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.VOID_LIFE, 32.0, 2.2, {
		"radius": FxParts.particle_radius(3.0), "alt": Vector2(0, 10), "alt_speed": Vector2(8, 26),
		"speed": Vector2(0, 8), "life": Vector2(0.7, 1.5), "size": Vector2(1, 2),
	})
