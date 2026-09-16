extends FxTimeline
## Nuclear Nova: telegraph -> warhead descent -> impact -> blast wave -> fallout zone.

const RADIUS := 5.0
const KILL_CORE := 1.2
const T_LOCK := 1.3
const T_DESCENT := 1.5
const T_IMPACT := 2.3
const WAVE_TIME := 1.0
const DESCENT_FROM := Vector2(-110, -250)


class Warhead:
	extends Node2D

	const BODY := Color("8c929c")
	const BODY_HI := Color("c3c8d0")
	const BODY_DARK := Color("4a4f59")
	const BAND := Color("d8b23a")
	const HOT := Color("ffb04a")

	func _draw() -> void:
		# Local +y points along the fall direction; nose at bottom.
		draw_rect(Rect2(-3, -12, 6, 16), BODY)
		draw_rect(Rect2(-3, -12, 2, 16), BODY_HI)
		draw_rect(Rect2(2, -12, 1, 16), BODY_DARK)
		draw_rect(Rect2(-3, -4, 6, 1), BAND)
		draw_rect(Rect2(-2, 4, 4, 3), BODY)
		draw_rect(Rect2(-1, 7, 2, 2), HOT)
		draw_rect(Rect2(-5, -14, 2, 5), BODY_DARK)
		draw_rect(Rect2(3, -14, 2, 5), BODY_DARK)
		draw_rect(Rect2(-2, -15, 4, 3), BODY_DARK)


var _target_px := Vector2.ZERO
var _rings: QuadFx
var _warhead: Warhead
var _fire_trail: PixelParticles
var _smoke_trail: PixelParticles
var _wave: QuadFx
var _wave_done := false
var _descent_voice: Node
var _geiger: Node


func _build() -> void:
	duration = 9.5
	_target_px = Iso.ground_to_screen(origin)

	_rings = FxParts.rings(self, origin, RADIUS, Color("ff3a2a"), 4, 20.0)
	_rings.tween_param("reveal", 0.0, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ctx.play(&"nova_alarm", origin)

	at(T_LOCK, func(): ctx.play(&"nova_lock", origin))
	at(T_DESCENT, _start_descent)
	at(T_IMPACT, _impact)
	at(T_IMPACT + 0.9, _aftermath)


func _start_descent() -> void:
	_warhead = Warhead.new()
	var dir := -DESCENT_FROM.normalized()
	_warhead.rotation = dir.angle() - PI * 0.5
	track(_warhead, ctx.overhead)
	_warhead.position = _target_px + DESCENT_FROM

	_fire_trail = FxParts.emitter(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 140.0, 0.8, {
		"radius": 2.0, "speed": Vector2(5, 25), "life": Vector2(0.15, 0.4), "size": Vector2(1.5, 3.5),
		"size_end_mul": 0.4,
	})
	_smoke_trail = FxParts.emitter(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.SMOKE_LIFE, 60.0, 0.8, {
		"radius": 3.0, "speed": Vector2(2, 10), "alt_speed": Vector2(4, 12), "life": Vector2(0.6, 1.3),
		"size": Vector2(2, 4), "size_end_mul": 2.2,
	})
	_smoke_trail.drag = 0.8
	_descent_voice = ctx.play(&"nova_descent", origin)


func _fx_process(_delta: float) -> void:
	if is_instance_valid(_warhead):
		var k := clampf((t - T_DESCENT) / (T_IMPACT - T_DESCENT), 0.0, 1.0)
		var pos := _target_px + DESCENT_FROM * (1.0 - pow(k, 1.5))
		_warhead.position = pos.round()
		# Trail spawns just behind the warhead tail.
		var tail := pos + DESCENT_FROM.normalized() * 12.0
		if is_instance_valid(_fire_trail):
			_fire_trail.spec["offset"] = tail
		if is_instance_valid(_smoke_trail):
			_smoke_trail.spec["offset"] = tail + DESCENT_FROM.normalized() * 6.0
	if _wave != null and not _wave_done:
		var k := clampf((t - T_IMPACT) / WAVE_TIME, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - k, 3.0)
		_wave.set_param("progress", eased)
		_wave.set_param("fade", 1.0 - smoothstep(0.7, 1.0, k))
		var wave_r := eased * RADIUS
		for e in ctx.field.in_radius(origin, wave_r):
			ctx.field.kill(e, &"nova")
		if k >= 1.0:
			_wave_done = true
			ctx.field.knock_from(origin, RADIUS, RADIUS + 2.5, 7.0)
			_wave.visible = false


func _impact() -> void:
	if is_instance_valid(_warhead):
		_warhead.queue_free()
	ctx.fade_out(_descent_voice, 0.05)
	_rings.tween_param("alpha", 1.0, 0.0, 0.12)
	ctx.flash.call(Color(1.0, 0.96, 0.88, 0.95), 0.45)
	ctx.shake.add_trauma(1.0)
	ctx.play(&"nova_crack", origin)
	ctx.play(&"nova_boom", origin)
	ctx.play(&"nova_shockwave", origin)

	for e in ctx.field.in_radius(origin, KILL_CORE):
		ctx.field.kill(e, &"nova")

	var pillar := FxParts.beam(self, ctx.overhead, _target_px, 34.0, 420.0, FxParts.FIRE)
	pillar.tween_param("intensity", 1.0, 0.0, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)

	_wave = FxParts.shockwave(self, origin, RADIUS, FxParts.FIRE)
	_wave.set_param("thickness", 0.07)
	_wave.set_param("inner_heat", 0.12)

	var dome := FxParts.dome(self, _target_px, FxParts.PX_PER_UNIT_MAJOR * 2.4)
	dome.tween_param("grow", 0.1, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	dome.tween_param("heat", 1.25, 0.55, 1.3, 0.0, Tween.TRANS_SINE, Tween.EASE_IN)
	dome.tween_param("dissolve", 0.0, 1.0, 0.8, 0.7, Tween.TRANS_QUAD, Tween.EASE_IN)
	dome.life = 1.6

	var crater := FxParts.decal(self, origin, 2.6)
	crater.tween_param("heat", 1.0, 0.0, 6.0)
	crater.tween_param("fade", 1.0, 0.0, 1.5, 5.6)

	FxParts.debris(self, _target_px, 130, 16.0, Vector2(40, 240), FxParts.HOT_ROCK)
	FxParts.debris(self, _target_px, 60, 30.0, Vector2(20, 140))
	FxParts.sparks(self, ctx.overhead, _target_px, 90, FxParts.FIRE_LIFE, Vector2(120, 380), Vector2(40, 320))


func _aftermath() -> void:
	ctx.play(&"nova_rumble", origin)
	_geiger = ctx.play(&"nova_geiger", origin, -4.0)
	at(t + 5.2, func(): ctx.fade_out(_geiger, 1.5))

	FxParts.smoke(self, _target_px, 22.0, 55.0, 2.6, Vector2(40, 95), Vector2(4, 7), Vector2(1.6, 2.8))
	# Ring of lingering fires around the crater rim.
	for i in 7:
		var a := TAU * i / 7.0 + ctx.rng.randf() * 0.4
		var rim := Iso.ground_to_screen(origin + Vector2.RIGHT.rotated(a) * ctx.rng.randf_range(1.6, 2.6))
		FxParts.emitter(self, ctx.overhead, rim, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 14.0,
			ctx.rng.randf_range(2.5, 4.0), {
				"radius": 5.0, "speed": Vector2(0, 6), "alt_speed": Vector2(18, 40), "life": Vector2(0.3, 0.6),
				"size": Vector2(1.5, 3.0), "size_end_mul": 0.3,
			})

	var rad := FxParts.fog(self, origin, 4.4, Color(0.45, 1.0, 0.3, 0.55))
	rad.tween_param("density", 0.0, 1.0, 1.5, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	rad.tween_param("fade", 1.0, 0.0, 1.6, 4.6)

	var fallout := FxParts.emitter(self, ctx.overhead, _target_px, PixelParticles.Shape.SQUARE, FxParts.RAD_LIFE, 45.0, 4.8, {
		"radius": FxParts.particle_radius(4.0), "alt": Vector2(0, 14), "alt_speed": Vector2(6, 20),
		"speed": Vector2(0, 6), "life": Vector2(0.9, 1.9), "size": Vector2(1, 2),
	})
	fallout.drag = 0.0
	FxParts.emitter(self, ctx.overhead, _target_px, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 30.0, 3.0, {
		"radius": FxParts.particle_radius(2.4), "alt": Vector2(0, 10), "alt_speed": Vector2(15, 45),
		"speed": Vector2(0, 12), "life": Vector2(0.6, 1.4), "size": Vector2(1, 1),
	})
