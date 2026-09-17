extends FxTimeline
## Tsunami Breaker: water path telegraph -> a wave wall rises and curls across the lane -> the wall sweeps
## forward, engulfing and carrying enemies -> it crashes in a terminal splash and shockwave ->
## flooded ground with foam, puddles, mist and broken debris.

const LENGTH := 10.0
const WIDTH := 5.4
const T_RISE := 1.0
const RISE_TIME := 0.7
const T_SWEEP := 1.9
const SWEEP_TIME := 3.0
const T_CRASH := T_SWEEP + SWEEP_TIME
const WAVE_HEIGHT := 140.0
const CARRY_BAND := 0.8
const WATER_LIGHT := Color(0.45, 0.75, 1.0)
const SH_FLOOD := preload("res://shaders/flood_water.gdshader")


## Broken planks and beam frames floating on the flood, bobbing and drifting with the current.
## Drawn on the ground plane (ground units).
class Flotsam:
	extends Node2D

	const WOOD := Color("7a5a38")
	const WOOD_LIT := Color("9a7650")
	const WOOD_DARK := Color("4a3422")
	const FOAM := Color(0.9, 0.97, 1.0, 0.85)

	var drift := Vector2.ZERO
	var alpha := 1.0
	var _pieces: Array = []
	var _time := 0.0

	func setup(rng: RandomNumberGenerator, count: int, area_len: float, area_w: float, dir: Vector2) -> void:
		var side := dir.orthogonal()
		for i in count:
			var p := dir * rng.randf_range(0.8, area_len) + side * rng.randf_range(-area_w * 0.45, area_w * 0.45)
			var frame := rng.randf() < 0.35
			_pieces.append({"pos": p, "angle": rng.randf() * TAU, "len": rng.randf_range(0.7, 1.4),
				"frame": frame, "phase": rng.randf() * TAU, "spin": rng.randf_range(-0.25, 0.25)})

	func _process(delta: float) -> void:
		_time += delta
		position += drift * delta
		drift = drift.lerp(Vector2.ZERO, minf(0.6 * delta, 1.0))
		modulate.a = alpha
		queue_redraw()

	func _plank(center: Vector2, angle: float, length: float, w: float) -> void:
		var ax := Vector2.from_angle(angle) * length * 0.5
		var sd := Vector2.from_angle(angle + PI * 0.5) * w * 0.5
		var pts := PackedVector2Array([center - ax - sd, center + ax - sd, center + ax + sd, center - ax + sd])
		# Foam lip around the plank, dark wet underside, lit top and a lighter edge.
		var foam := PackedVector2Array()
		for q in pts:
			foam.append(center + (q - center) * 1.35)
		draw_colored_polygon(foam, FOAM)
		draw_colored_polygon(pts, WOOD_DARK)
		var top := PackedVector2Array()
		for q in pts:
			top.append(center + (q - center) * 0.8 + Vector2(-0.02, -0.02))
		draw_colored_polygon(top, WOOD)
		draw_colored_polygon(PackedVector2Array([top[0], top[1], top[1].lerp(top[2], 0.35), top[0].lerp(top[3], 0.35)]), WOOD_LIT)

	func _draw() -> void:
		for pc in _pieces:
			var bob := sin(_time * 2.2 + pc.phase) * 0.04
			# Screen-up in ground units is (-1, -1).
			var c: Vector2 = pc.pos + Vector2(-bob, -bob)
			var a: float = pc.angle + sin(_time * 0.8 + pc.phase) * 0.15 + _time * pc.spin
			if pc.frame:
				_plank(c, a, pc.len, 0.15)
				_plank(c, a + PI * 0.5, pc.len * 0.8, 0.15)
				_plank(c + Vector2.from_angle(a) * pc.len * 0.3, a + PI * 0.5, pc.len * 0.7, 0.12)
			else:
				_plank(c, a, pc.len, 0.2)

var _dir := Vector2(1, 0)
var _side := Vector2(0, 1)
var _lane: LanePath
var _wave: TsunamiWave
var _front := 0.0
var _sweeping := false
var _carried: Array[DummyEnemy] = []
var _flood: QuadFx
var _roar: Node
var _spray: PixelParticles
var _foam: PixelParticles
var _light: QuadFx


func _build() -> void:
	duration = 9.5
	_dir = (extra.get("dir", Vector2(1, 0)) as Vector2).normalized()
	_side = _dir.orthogonal()
	_lane = Set2Parts.lane(self, origin, _dir, LENGTH, WIDTH, Color("6ac8ff"), "water")
	var swirl := Set2Parts.sigil(self, origin, 1.3, Color("6ac8ff"), "spiral")
	swirl.z_index = 9
	ctx.impact.dim(0.4, 1.2)
	ctx.play(&"ts_surge", origin)
	at(T_RISE, _rise)
	at(T_SWEEP, _sweep)
	at(T_CRASH, _crash)
	at(T_RISE, func(): create_tween().tween_property(swirl, "alpha", 0.0, 0.4))


func _wall_screen(front: float) -> Array:
	# Endpoints of the wall line on screen, left-to-right, and its screen angle.
	var a := Iso.ground_to_screen(origin + _dir * front - _side * WIDTH * 0.5)
	var b := Iso.ground_to_screen(origin + _dir * front + _side * WIDTH * 0.5)
	if a.x > b.x:
		var tmp := a
		a = b
		b = tmp
	return [a, b]


func _place_wave() -> void:
	var ends := _wall_screen(_front)
	_wave.position = (((ends[0] as Vector2) + (ends[1] as Vector2)) * 0.5).round()


func _rise() -> void:
	ctx.play(&"ts_rise", origin)
	_wave = TsunamiWave.new()
	_wave.dir = _dir
	_wave.width = WIDTH
	_wave.max_height = WAVE_HEIGHT
	_wave.seed = ctx.rng.randf()
	# Sorted with the world so enemies behind the wave are hidden and ones in front show.
	_wave.z_index = 0
	track(_wave, ctx.world)
	_place_wave()
	var rise := _wave.create_tween().set_parallel()
	rise.tween_property(_wave, "height", 1.0, RISE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	rise.tween_property(_wave, "curl", 1.0, RISE_TIME + 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ctx.shake.add_trauma(0.4)
	var burst := FxParts.particles(self, ctx.overhead, _wave.position, PixelParticles.Shape.SQUARE, Set2Parts.FOAM_LIFE)
	burst.gravity = 320.0
	burst.drag = 0.8
	burst.burst(90, {"radius": 60.0, "speed": Vector2(10, 60), "alt": Vector2(0, 20), "alt_speed": Vector2(80, 240),
		"life": Vector2(0.6, 1.2), "size": Vector2(1, 3)})
	_spray = FxParts.emitter(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.SQUARE, Set2Parts.FOAM_LIFE, 90.0,
		T_CRASH - t, {"radius": 0.0, "speed": Vector2(10, 50), "alt_speed": Vector2(40, 140), "life": Vector2(0.4, 0.9),
			"size": Vector2(1, 2)})
	_spray.gravity = 300.0
	_foam = FxParts.emitter(self, ctx.overhead_back, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.MIST_LIFE, 14.0,
		T_CRASH - t, {"radius": 0.0, "speed": Vector2(4, 20), "alt": Vector2(0, 20), "alt_speed": Vector2(6, 20),
			"life": Vector2(0.6, 1.0), "size": Vector2(2, 4), "size_end_mul": 1.4})
	_light = FxParts.ground_light(self, origin, 3.0, WATER_LIGHT, 0.0)
	_light.tween_param("intensity", 0.0, 0.35, RISE_TIME)
	var light := _light
	ctx.lights.register_quad(light, origin, 3.4, WATER_LIGHT, func(): return origin + _dir * _front)
	_flood = FxParts.quad(self, SH_FLOOD, Vector2(LENGTH, WIDTH), ctx.ground, Vector2(0.0, 0.5))
	_flood.set_param("width", WIDTH)
	_flood.set_param("seed", ctx.rng.randf() * 10.0)
	_flood.z_index = 2


func _sweep() -> void:
	_sweeping = true
	_roar = ctx.play(&"ts_roar", origin, -2.0)
	create_tween().tween_property(_lane, "alpha", 0.0, 0.6)


func _fx_process(delta: float) -> void:
	if _wave == null or not is_instance_valid(_wave):
		return
	if _sweeping:
		var k := clampf((t - T_SWEEP) / SWEEP_TIME, 0.0, 1.0)
		_front = LENGTH * (k * k * (3.0 - 2.0 * k) * 0.35 + k * 0.65)
		# Enemies in the wall band are swept up and carried along.
		for e in ctx.field.in_lane(origin, _dir, WIDTH * 0.5 + 0.2, _front - CARRY_BAND, _front + 0.3):
			if not e in _carried:
				_carried.append(e)
				e.flash(0.1)
		for e in _carried:
			if is_instance_valid(e) and e.is_alive():
				var target := origin + _dir * (_front + 0.1) + _side * clampf((e.ground_pos - origin).dot(_side), -WIDTH * 0.5, WIDTH * 0.5)
				e.ground_pos = e.ground_pos.lerp(target, minf(12.0 * delta, 1.0))
				e.knock(Vector2.ZERO)
		ctx.env.damage_lane(origin, _dir, WIDTH * 0.5, _front - 0.3, _front + 0.3, &"water")
		ctx.shake.add_trauma(0.35 * delta)
	_place_wave()
	var ends := _wall_screen(_front)
	var mid := ((ends[0] as Vector2) + (ends[1] as Vector2)) * 0.5
	var half := (ends[1] as Vector2).distance_to(ends[0]) * 0.5
	if is_instance_valid(_spray):
		_spray.spec["offset"] = mid + Iso.ground_to_screen(_dir) * 0.8 + Vector2(0, -_wave.lip_height())
		_spray.spec["radius"] = half
	if is_instance_valid(_foam):
		_foam.spec["offset"] = mid
		_foam.spec["radius"] = half
	if _flood != null and is_instance_valid(_flood):
		_flood.position = origin
		_flood.rotation = _dir.angle()
		_flood.visible = _front > 0.2
		_flood.size = Vector2(maxf(_front, 0.01), WIDTH)
		_flood.set_param("length", maxf(_front, 0.01))
		_flood.queue_redraw()


func _crash() -> void:
	_sweeping = false
	ctx.fade_out(_roar, 0.3)
	ctx.play(&"ts_crash", origin + _dir * LENGTH)
	var g := origin + _dir * LENGTH
	var sp := Iso.ground_to_screen(g)
	ctx.impact.impact_frame(0.05, ctx.impact.focus_of(sp), Color(0.9, 0.97, 1.0), Color(0.02, 0.1, 0.25))
	ctx.impact.hitstop(0.08)
	ctx.impact.aberration(3.0, 0.4)
	ctx.impact.dim(0.15, 0.8)
	ctx.flash.call(Color(0.85, 0.95, 1.0, 0.4), 0.3)
	ctx.shake.add_trauma(0.95)
	ctx.shake.kick(_dir.normalized() * 6.0)
	var fall := _wave.create_tween().set_parallel()
	fall.tween_property(_wave, "height", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(_wave, "fade", 0.0, 0.35)
	fall.chain().tween_callback(_wave.queue_free)
	_light.tween_param("intensity", 0.35, 0.0, 0.8)

	# Terminal splash: a towering burst of water and spray fanning up and out.
	var ends := _wall_screen(LENGTH)
	for i in 7:
		var p: Vector2 = (ends[0] as Vector2).lerp(ends[1], (i + 0.5) / 7.0)
		Set2Parts.glow_column(self, p, 30.0, ctx.rng.randf_range(90.0, 170.0), WATER_LIGHT, 0.9, 0.5)
		var jet := FxParts.particles(self, ctx.overhead, p, PixelParticles.Shape.STREAK, Set2Parts.WATER_LIFE)
		jet.gravity = 360.0
		jet.drag = 0.6
		jet.streak_len = 0.06
		jet.burst(40, {"radius": 10.0, "speed": Vector2(20, 140), "alt": Vector2(0, 20), "alt_speed": Vector2(160, 380),
			"life": Vector2(0.6, 1.3), "size": Vector2(2, 4)})
		var foam := FxParts.particles(self, ctx.overhead, p, PixelParticles.Shape.SQUARE, Set2Parts.FOAM_LIFE)
		foam.gravity = 340.0
		foam.drag = 0.5
		foam.burst(30, {"radius": 14.0, "speed": Vector2(40, 180), "alt": Vector2(10, 50), "alt_speed": Vector2(80, 300),
			"life": Vector2(0.6, 1.3), "size": Vector2(1, 3)})
	# Radial splash streaks fanning out across the ground, like water slapped flat.
	var rays := FxParts.ground_rays(self, g, 4.2, Color(0.8, 0.94, 1.0), 40.0)
	rays.tween_param("reach", 0.2, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	rays.tween_param("intensity", 1.4, 0.0, 0.7, 0.15)
	rays.life = 0.9
	var wave := FxParts.shockwave(self, g, 3.2, Set2Parts.WATER)
	wave.z_index = 9
	wave.set_param("thickness", 0.12)
	wave.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.3, 0.35)
	wave.life = 0.7
	var refract := FxParts.refract_ring(self, g, 3.6, Color(0.85, 0.95, 1.0))
	refract.tween_param("progress", 0.05, 1.0, 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	refract.life = 0.72
	var bloom := FxParts.bloom(self, sp + Vector2(0, -40), 110.0, WATER_LIGHT, 1.0, 0.8)
	bloom.tween_param("intensity", 1.0, 0.0, 0.6)
	bloom.life = 0.62
	FxParts.debris(self, sp, 40, 60.0, Vector2(60, 240), Set2Parts.WOOD, Vector2(2, 5), true)
	FxParts.debris(self, sp, 20, 60.0, Vector2(60, 220), FxParts.ROCK, Vector2(2, 4), true)
	var mist := FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, FxParts.MIST_LIFE)
	mist.drag = 1.2
	mist.burst(18, {"radius": 70.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(20, 70), "alt": Vector2(0, 30),
		"alt_speed": Vector2(6, 30), "life": Vector2(0.9, 1.6), "size": Vector2(3, 6), "size_end_mul": 1.5})

	for e in _carried:
		if is_instance_valid(e) and e.is_alive():
			ctx.field.kill(e, &"water", e.ground_pos - _dir)
	for e in ctx.field.in_radius(g, 3.0):
		ctx.field.kill(e, &"water", g)
	ctx.field.knock_from(g, 3.0, 5.0, 6.0)
	ctx.env.damage_radius(g, 3.0, 99999.0, &"water")
	at(t + 0.5, _aftermath)


func _aftermath() -> void:
	ctx.play(&"ts_drip", origin, -6.0)
	# Flooded lane: the water calms, broken planks float and drift, puddles spill past the end,
	# ripples and mist.
	if _flood != null and is_instance_valid(_flood):
		_flood.tween_param("settle", 0.0, 0.6, 1.2)
		_flood.tween_param("fade", 1.0, 0.0, 1.5, duration - t - 1.6)
	var flot := Flotsam.new()
	flot.setup(ctx.rng, 9, LENGTH + 0.5, WIDTH, _dir)
	flot.position = origin
	flot.drift = _dir * 0.6
	flot.z_index = 3
	track(flot, ctx.ground)
	create_tween().tween_property(flot, "alpha", 0.0, 1.2).set_delay(duration - t - 1.4)
	for i in 6:
		var g := origin + _dir * ctx.rng.randf_range(LENGTH - 0.5, LENGTH + 1.8) + _side * ctx.rng.randf_range(-WIDTH * 0.6, WIDTH * 0.6)
		var puddle := FxParts.frost_ground(self, g, ctx.rng.randf_range(0.35, 0.8))
		puddle.set_param("plate", Color(0.18, 0.42, 0.68, 0.6))
		puddle.set_param("crack", Color(0.6, 0.82, 0.98, 0.2))
		puddle.set_param("progress", 1.0)
		puddle.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	for i in 10:
		var g := origin + _dir * ctx.rng.randf_range(0.5, LENGTH) + _side * ctx.rng.randf_range(-WIDTH * 0.4, WIDTH * 0.4)
		var ripple := FxParts.rings(self, g, 0.7, Color(0.8, 0.93, 1.0), 2, 10.0)
		ripple.set_param("scan", 0.0)
		ripple.set_param("fill", 0.0)
		ripple.set_param("crosshair", 0.0)
		ripple.set_param("alpha", 0.0)
		var delay := ctx.rng.randf_range(0.0, 2.0)
		ripple.tween_param("reveal", 0.1, 1.0, 1.2, delay)
		ripple.tween_param("alpha", 0.28, 0.0, 1.2, delay)
		ripple.life = 3.5
	FxParts.emitter(self, ctx.overhead_back, Iso.ground_to_screen(origin + _dir * LENGTH * 0.6), PixelParticles.Shape.PUFF,
		FxParts.MIST_LIFE, 6.0, duration - t - 1.5, {
			"radius": FxParts.particle_radius(LENGTH * 0.5), "speed": Vector2(2, 10), "alt": Vector2(0, 8),
			"alt_speed": Vector2(3, 10), "life": Vector2(1.2, 2.0), "size": Vector2(3, 6), "size_end_mul": 1.4,
		})
	FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin + _dir * LENGTH * 0.6), PixelParticles.Shape.SQUARE,
		Set2Parts.WATER_LIFE, 20.0, duration - t - 1.5, {
			"radius": FxParts.particle_radius(LENGTH * 0.5), "alt": Vector2(0, 30), "alt_speed": Vector2(-40, -10),
			"life": Vector2(0.4, 0.8), "size": Vector2(1, 1),
		})
	at(duration - 1.3, func(): ctx.impact.dim(0.0, 0.6))
