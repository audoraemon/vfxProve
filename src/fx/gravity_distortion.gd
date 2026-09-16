extends FxTimeline
## Gravity Distortion: field forms -> pull -> compression -> implosion -> warped scar with hovering fragments.

const RADIUS := 4.5
const T_PULL := 0.8
const T_COMPRESS := 3.5
const T_IMPLODE := 4.1
const KILL_R := 1.5
const RUBBLE_COUNT := 48
const VOID_LIGHT := Color(0.55, 0.3, 1.0)
const PALE_LIGHT := Color(0.85, 0.75, 1.0)


## Angular rock fragments orbiting and spiraling in, blasted out on implosion; some keep hovering after.
class Rubble:
	extends Node2D

	const COL := [Color("3c3947"), Color("4a4657"), Color("2e2c37")]
	const COL_LIT := Color("8a82a6")
	const COL_RIM := Color("b98cff")

	var origin := Vector2.ZERO
	var radius := 4.5
	## 0..2 pull intensity; 0 = dormant.
	var pull := 0.0
	var exploded := false
	var rng: RandomNumberGenerator
	var chunks: Array[Dictionary] = []
	var _time := 0.0

	func setup(count: int) -> void:
		for i in count:
			chunks.append(_new_chunk(rng.randf_range(radius * 0.45, radius)))

	func _new_chunk(r: float) -> Dictionary:
		var big := rng.randf() < 0.35
		return {
			"a": rng.randf() * TAU, "r": r, "alt": rng.randf_range(0.0, 4.0), "vel": Vector2.ZERO,
			"valt": 0.0, "size": rng.randf_range(6.0, 11.0) if big else rng.randf_range(2.5, 5.0),
			"c": rng.randi() % 3, "rot": rng.randf() * TAU, "spin": rng.randf_range(-2.5, 2.5),
			"life": 1.0, "hover": false, "phase": rng.randf() * TAU, "pos": Vector2.ZERO,
		}

	func explode() -> void:
		exploded = true
		for c in chunks:
			var dir := Vector2.RIGHT.rotated(c.a)
			c.pos = Iso.ground_to_screen(origin + dir * c.r) - Iso.ground_to_screen(origin)
			# About a third survive as levitating remnants around the scar.
			c.hover = rng.randf() < 0.35
			var speed := rng.randf_range(40.0, 110.0) if c.hover else rng.randf_range(140.0, 340.0)
			c.vel = Vector2(dir.x, dir.y * 0.5) * speed
			c.valt = rng.randf_range(20.0, 80.0) if c.hover else rng.randf_range(60.0, 230.0)
			c.life = 2.6 if c.hover else rng.randf_range(0.8, 1.5)
			c.spin *= 3.0

	func _process(delta: float) -> void:
		_time += delta
		for c in chunks:
			c.rot += c.spin * delta
			if exploded:
				c.pos += c.vel * delta
				c.life -= delta
				if c.hover:
					c.vel *= maxf(1.0 - 2.5 * delta, 0.0)
					var target: float = 14.0 + 10.0 * sin(_time * 1.6 + c.phase)
					c.alt = move_toward(c.alt, target, 40.0 * delta)
					c.spin = move_toward(c.spin, signf(c.spin) * 0.6, 3.0 * delta)
				else:
					c.vel *= maxf(1.0 - 1.2 * delta, 0.0)
					c.valt -= 420.0 * delta
					c.alt = maxf(c.alt + c.valt * delta, 0.0)
			elif pull > 0.0:
				var k: float = 1.0 - c.r / radius
				c.a += (0.5 + 3.2 * k * k) * pull * delta
				c.r -= (0.25 + 2.2 * k) * pull * delta
				c.alt = move_toward(c.alt, 6.0 + 30.0 * k * pull, 30.0 * delta)
				if c.r < 0.3:
					c.merge(_new_chunk(radius * rng.randf_range(0.85, 1.0)), true)
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
			var fade := clampf(c.life / 0.5, 0.0, 1.0) if exploded else 1.0
			var sz: float = c.size
			var top: Vector2 = at + Vector2(0, -c.alt)
			draw_rect(Rect2((at - Vector2(sz * 0.5, 0)).round(), Vector2(roundf(sz), 1)), Color(0, 0, 0, 0.3 * fade))
			var pts := PackedVector2Array()
			var lit := PackedVector2Array()
			for i in 5:
				var ang: float = c.rot + TAU * i / 5.0
				var jitter := fposmod(sin(float(i) * 12.9898 + float(c.c) * 7.1 + sz) * 43758.5453, 1.0)
				var v := Vector2(cos(ang), sin(ang)) * sz * (0.6 + 0.45 * jitter)
				pts.append(top + v)
				lit.append(top + v * 0.5 + Vector2(-0.5, -0.8) * sz * 0.3)
			var base: Color = COL[c.c]
			draw_colored_polygon(pts, Color(base, fade))
			draw_colored_polygon(lit, Color(COL_LIT, fade))
			if pull > 0.3 or (exploded and c.hover):
				# Violet rim light on the side facing the singularity.
				var to_core := (-at).normalized()
				draw_line((top + to_core * sz * 0.5).round(), (top + to_core * sz * 0.5 + to_core.orthogonal() * sz * 0.6).round(),
					Color(COL_RIM, fade), -1.0)


## Short-lived jagged lightning arcs (hairlines), screen space around the cast point.
class Arcs:
	extends Node2D

	var arcs: Array[Dictionary] = []
	var rng: RandomNumberGenerator

	func spawn(from: Vector2, to: Vector2) -> void:
		var pts := PackedVector2Array([from])
		var segs := 7
		var perp := (to - from).orthogonal().normalized()
		for i in range(1, segs):
			var k := float(i) / segs
			pts.append((from.lerp(to, k) + perp * rng.randf_range(-7.0, 7.0)).round())
		pts.append(to)
		arcs.append({"pts": pts, "life": rng.randf_range(0.06, 0.14)})

	func _process(delta: float) -> void:
		for a in arcs:
			a.life -= delta
		arcs = arcs.filter(func(a): return a.life > 0.0)
		queue_redraw()

	func _draw() -> void:
		for a in arcs:
			var pts: PackedVector2Array = a.pts
			for i in pts.size() - 1:
				draw_line(pts[i] + Vector2(0, 1), pts[i + 1] + Vector2(0, 1), Color(0.48, 0.24, 0.94, 0.8), -1.0)
				draw_line(pts[i], pts[i + 1], Color(0.94, 0.9, 1.0), -1.0)


var _center_px := Vector2.ZERO
var _rings: QuadFx
var _sing: QuadFx
var _streaks: PixelParticles
var _rubble: Rubble
var _arcs: Arcs
var _light: QuadFx
var _rays: QuadFx
var _cracks: QuadFx
var _next_arc := 0.0
var _imploded := false
var _voices: Array[Node] = []


func _build() -> void:
	duration = 7.2
	_center_px = Iso.ground_to_screen(origin)

	_rings = FxParts.rings(self, origin, RADIUS, Color("8f58f0"), 5, 22.0)
	_rings.set_param("fill", 0.14)
	_rings.set_param("pulse", 0.5)
	_rings.tween_param("reveal", 0.0, 1.0, 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	_light = FxParts.ground_light(self, origin, RADIUS * 1.05, VOID_LIGHT, 0.0)
	_light.set_param("falloff", 1.4)

	_cracks = FxParts.decal(self, origin, 2.4, Color("7a3cf0"), Color("d8c4ff"), Color(0.04, 0.02, 0.08, 0.7), 1.0)
	_cracks.set_param("fade", 0.0)

	# Energy beam from above seeds the anomaly.
	var sky := FxParts.beam(self, ctx.overhead, _center_px, 10.0, 420.0, FxParts.VOID)
	sky.tween_param("intensity", 1.0, 0.0, 0.9, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	sky.life = 0.95

	_sing = FxParts.singularity(self, origin, RADIUS)

	_rays = FxParts.screen_rays(self, _center_px + Vector2(0, -14), 150.0, PALE_LIGHT, 90.0, 0.6)
	_rays.set_param("intensity", 0.0)

	_rubble = Rubble.new()
	_rubble.rng = ctx.rng
	_rubble.origin = origin
	_rubble.radius = RADIUS
	_rubble.position = _center_px
	_rubble.setup(RUBBLE_COUNT)
	# Above the lens so fragments stay crisp silhouettes instead of being smeared.
	_rubble.z_index = 5
	track(_rubble, ctx.distort)

	_arcs = Arcs.new()
	_arcs.rng = ctx.rng
	_arcs.position = _center_px
	_arcs.z_index = 6
	track(_arcs, ctx.distort)

	_voices.append(ctx.play(&"grav_field", origin))
	_voices.append(ctx.play(&"grav_drone", origin, -3.0))
	at(T_PULL, _start_pull)
	at(T_COMPRESS, func(): _voices.append(ctx.play(&"grav_compress", origin)))
	at(T_IMPLODE, _implode)


func _start_pull() -> void:
	_voices.append(ctx.play(&"grav_suction", origin))
	_streaks = FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.STREAK,
		[Color("3b1470"), Color("7a3cf0"), Color("b98cff"), Color("f4ecff")], 90.0, T_IMPLODE - T_PULL, {
			"radius": FxParts.particle_radius(RADIUS), "dir": PixelParticles.Dir.INWARD, "speed": Vector2(150, 280),
			"life": Vector2(0.5, 0.9), "size": Vector2(2, 4),
		})
	_streaks.streak_len = 0.06


func _fx_process(delta: float) -> void:
	if _imploded:
		return
	var strength := curve([[0.0, 0.0], [T_PULL, 0.6], [T_COMPRESS, 2.4], [T_IMPLODE, 3.6]])
	var pinch := curve([[0.0, 0.0], [T_PULL, 0.12], [T_COMPRESS, 0.35], [T_IMPLODE, 0.65]])
	var core := curve([[0.0, 0.0], [T_PULL, 7.0], [T_COMPRESS, 18.0], [T_IMPLODE, 5.0]])
	var arms := curve([[0.0, 0.0], [T_PULL, 0.35], [T_PULL + 1.0, 1.0], [T_IMPLODE, 1.0]])
	var compress := clampf((t - T_COMPRESS) / (T_IMPLODE - T_COMPRESS), 0.0, 1.0)
	if compress > 0.0:
		# Unstable flicker as the core collapses.
		core *= 1.0 + 0.35 * sin(t * 70.0) * compress
		_rings.set_param("reveal", lerpf(1.0, 0.3, compress * compress))
		ctx.shake.add_trauma(0.9 * delta)

	var drone: Node = _voices[1]
	if drone != null and is_instance_valid(drone) and ctx.sfx != null:
		drone.volume_db = lerpf(-8.0, -1.0, strength / 3.6)
		ctx.sfx.set_voice_pitch(drone, 1.0 + 0.3 * strength / 3.6)

	_sing.set_param("strength", strength)
	_sing.set_param("pinch", pinch)
	_sing.set_param("core_px", core)
	_sing.set_param("arm_alpha", arms)
	_sing.set_param("rim_boost", compress)

	# Light drains from the world into the anomaly.
	ctx.impact.dim(0.12 + 0.45 * strength / 3.6, 2.0)
	_light.set_param("intensity", 0.25 + 0.55 * strength / 3.6 + 0.3 * compress * (0.5 + 0.5 * sin(t * 50.0)))
	_rays.set_param("intensity", clampf((t - T_PULL) / 2.0, 0.0, 1.0) * (0.55 + 0.6 * compress))
	_rays.set_param("reach", 0.7 + 0.3 * sin(t * 2.0))
	_cracks.set_param("fade", clampf((t - T_PULL) / 2.2, 0.0, 1.0))
	_cracks.set_param("heat", 0.5 + 0.5 * sin(t * 6.0 + compress * 20.0))

	_next_arc -= delta
	if t > T_PULL + 0.4 and _next_arc <= 0.0:
		_next_arc = lerpf(0.16, 0.04, compress)
		var a := ctx.rng.randf() * TAU
		var from_ground := Vector2.RIGHT.rotated(a) * ctx.rng.randf_range(1.2, 3.2)
		var from := Iso.ground_to_screen(origin + from_ground) - _center_px + Vector2(0, -ctx.rng.randf_range(4, 30))
		_arcs.spawn(from, Vector2(0, -core * 1.1))
		ctx.play(&"grav_arc", origin + from_ground * 0.5)

	_rubble.pull = clampf((t - 0.3) / T_PULL, 0.0, 1.0) * (1.0 + compress)
	ctx.env.shake_radius(origin, RADIUS + 0.5, 0.4 + 2.6 * strength / 3.6)
	if t >= T_PULL:
		var pull_strength := curve([[T_PULL, 0.8], [T_COMPRESS, 3.2], [T_IMPLODE, 4.2]])
		ctx.field.pull(origin, RADIUS, pull_strength, 1.0, delta)


func _implode() -> void:
	_imploded = true
	for v in _voices:
		ctx.fade_out(v, 0.03)
	at(T_IMPLODE + 0.08, func(): ctx.play(&"grav_implode", origin))
	at(T_IMPLODE + 0.2, func(): ctx.play(&"grav_shimmer", origin, -4.0))

	ctx.impact.impact_frame(0.07, ctx.impact.focus_of(_center_px), Color(0.9, 0.85, 1.0), Color(0.07, 0.0, 0.13))
	ctx.impact.hitstop(0.1)
	ctx.impact.aberration(5.0, 0.6)
	ctx.impact.dim(0.0, 1.4)
	at(T_IMPLODE + 0.03, func(): ctx.flash.call(Color(0.82, 0.7, 1.0, 0.55), 0.35))
	ctx.shake.add_trauma(0.95)
	ctx.shake.kick(Vector2(0, -8))

	_sing.queue_free()
	_rays.queue_free()
	_cracks.queue_free()
	_rings.tween_param("alpha", 1.0, 0.0, 0.15)
	_light.tween_param("intensity", 1.6, 0.0, 1.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)

	for e in ctx.field.in_radius(origin, KILL_R):
		ctx.field.kill(e, &"gravity", origin)
	ctx.field.release_all()
	ctx.field.knock_from(origin, 0.0, RADIUS + 1.0, 7.0)
	ctx.env.damage_radius(origin, RADIUS * 0.75, 99999.0, &"gravity")
	ctx.env.damage_radius(origin, RADIUS + 1.0, 50.0, &"gravity")

	var wave := FxParts.shockwave(self, origin, RADIUS, FxParts.VOID)
	wave.set_param("thickness", 0.08)
	wave.tween_param("progress", 0.02, 1.0, 0.6, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.35, 0.3)
	wave.life = 0.7

	var refract := FxParts.refract_ring(self, origin, RADIUS * 1.3, PALE_LIGHT)
	refract.tween_param("progress", 0.05, 1.0, 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	refract.life = 0.72

	var burst := FxParts.dome(self, _center_px, FxParts.PX_PER_UNIT_MAJOR * 1.4, FxParts.VOID)
	burst.set_param("smoke_hot", Color(0.2, 0.08, 0.3))
	burst.set_param("smoke_cold", Color(0.08, 0.04, 0.12))
	burst.tween_param("grow", 0.1, 1.0, 0.14, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	burst.tween_param("heat", 1.2, 0.6, 0.4)
	burst.tween_param("dissolve", 0.0, 1.0, 0.3, 0.12, Tween.TRANS_QUAD, Tween.EASE_IN)
	burst.life = 0.45

	var starburst := FxParts.screen_rays(self, _center_px + Vector2(0, -14), 230.0, PALE_LIGHT, 120.0, 0.7)
	starburst.tween_param("intensity", 1.5, 0.0, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	starburst.life = 0.85
	var bloom := FxParts.bloom(self, _center_px + Vector2(0, -12), 110.0, VOID_LIGHT, 1.2, 0.7)
	bloom.tween_param("intensity", 1.2, 0.0, 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	bloom.life = 0.75

	var radial := FxParts.particles(self, ctx.overhead, _center_px, PixelParticles.Shape.STREAK, FxParts.VOID_LIFE)
	radial.drag = 1.8
	radial.streak_len = 0.06
	radial.burst(170, {
		"radius": 6.0, "dir": PixelParticles.Dir.ANGLE, "speed": Vector2(160, 480), "alt": Vector2(4, 20),
		"life": Vector2(0.3, 0.85), "size": Vector2(2, 4),
	})
	_rubble.explode()

	var scar := FxParts.decal(self, origin, 3.1, Color("7a3cf0"), Color("e6d4ff"), Color(0.05, 0.02, 0.09, 0.88), 1.0)
	scar.tween_param("heat", 1.0, 0.3, 2.4)
	scar.tween_param("fade", 1.0, 0.0, 0.9, duration - T_IMPLODE - 1.0)

	var ripple := FxParts.rings(self, origin, 3.4, Color("a57cf0"), 4, 14.0)
	ripple.set_param("scan", 0.0)
	ripple.set_param("fill", 0.0)
	ripple.set_param("crosshair", 0.0)
	ripple.set_param("alpha", 0.0)
	ripple.tween_param("alpha", 0.0, 0.45, 0.4, 0.3)
	ripple.tween_param("alpha", 0.45, 0.0, 1.2, duration - T_IMPLODE - 1.3)

	var haze := FxParts.fog(self, origin, 3.8, Color(0.5, 0.35, 0.9, 0.45))
	haze.set_param("scale", 3.0)
	haze.tween_param("density", 0.0, 1.0, 0.8, 0.2)
	haze.tween_param("fade", 1.0, 0.0, 1.0, duration - T_IMPLODE - 1.1)

	var residual := FxParts.ground_light(self, origin, 3.2, VOID_LIGHT, 0.0)
	residual.set_param("flicker", 1.0)
	residual.tween_param("intensity", 0.0, 0.35, 0.6, 0.5)
	residual.tween_param("intensity", 0.35, 0.0, 1.0, duration - T_IMPLODE - 1.1)

	FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.VOID_LIFE, 36.0, 2.6, {
		"radius": FxParts.particle_radius(3.0), "alt": Vector2(0, 10), "alt_speed": Vector2(8, 26),
		"speed": Vector2(0, 8), "life": Vector2(0.7, 1.5), "size": Vector2(1, 2),
	})
