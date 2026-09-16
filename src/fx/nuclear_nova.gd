extends FxTimeline
## Nuclear Nova: telegraph -> warhead descent -> impact core swells slowly -> blast accelerates outward
## -> mushroom smoke, crater and fallout zone.

const RADIUS := 5.0
const KILL_CORE := 1.2
const T_LOCK := 1.3
const T_DESCENT := 1.5
const T_IMPACT := 2.3
## The core builds from impact until the blast releases.
const T_BLAST := 2.9
const WAVE_TIME := 0.55
const CORE_GROW := 0.4
const DESCENT_FROM := Vector2(-110, -250)
const FIRE_LIGHT := Color(1.0, 0.55, 0.2)
const HOT_LIGHT := Color(1.0, 0.8, 0.5)


class Warhead:
	extends Node2D

	const BODY := Color("8c929c")
	const BODY_HI := Color("c3c8d0")
	const BODY_DARK := Color("4a4f59")
	const BAND := Color("d8b23a")
	const HOT := Color("ffb04a")
	const HOTTER := Color("fff0c0")

	func _draw() -> void:
		# Local +y points along the fall direction; nose at bottom.
		draw_rect(Rect2(-4, -16, 8, 20), BODY)
		draw_rect(Rect2(-4, -16, 3, 20), BODY_HI)
		draw_rect(Rect2(3, -16, 1, 20), BODY_DARK)
		draw_rect(Rect2(-4, -8, 8, 1), BAND)
		draw_rect(Rect2(-4, -2, 8, 1), BODY_DARK)
		draw_rect(Rect2(-3, 4, 6, 3), BODY)
		draw_rect(Rect2(-2, 7, 4, 2), HOT)
		draw_rect(Rect2(-1, 9, 2, 2), HOTTER)
		draw_rect(Rect2(-6, -19, 2, 7), BODY_DARK)
		draw_rect(Rect2(4, -19, 2, 7), BODY_DARK)
		draw_rect(Rect2(-3, -20, 6, 4), BODY_DARK)


var _target_px := Vector2.ZERO
var _rings: QuadFx
var _warhead: Warhead
var _nose_glow: QuadFx
var _fire_trail: PixelParticles
var _smoke_trail: PixelParticles
var _core: QuadFx
var _wave: QuadFx
var _wave_done := false
var _dust: PixelParticles
var _descent_voice: Node
var _geiger: Node
var _mushroom: QuadFx
var _mushroom_t0 := 0.0


func _build() -> void:
	duration = 10.0
	_target_px = Iso.ground_to_screen(origin)

	_rings = FxParts.rings(self, origin, RADIUS, Color("e8321f"), 4, 20.0)
	_rings.tween_param("reveal", 0.0, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ctx.play(&"nova_alarm", origin)

	at(T_LOCK, func(): ctx.play(&"nova_lock", origin))
	at(T_DESCENT, _start_descent)
	at(T_IMPACT, _impact)
	at(T_BLAST, _blast)
	at(T_BLAST + 0.6, _aftermath)


func _start_descent() -> void:
	_warhead = Warhead.new()
	var dir := -DESCENT_FROM.normalized()
	_warhead.rotation = dir.angle() - PI * 0.5
	track(_warhead, ctx.overhead)
	_warhead.position = _target_px + DESCENT_FROM
	_nose_glow = FxParts.bloom(self, _warhead.position, 22.0, FIRE_LIGHT, 0.8)

	_fire_trail = FxParts.emitter(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 160.0, 0.8, {
		"radius": 2.5, "speed": Vector2(5, 25), "life": Vector2(0.15, 0.45), "size": Vector2(2, 4),
		"size_end_mul": 0.4,
	})
	_smoke_trail = FxParts.emitter(self, ctx.overhead_back, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.SMOKE_LIFE, 70.0, 0.8, {
		"radius": 3.0, "speed": Vector2(2, 10), "alt_speed": Vector2(4, 12), "life": Vector2(0.8, 1.6),
		"size": Vector2(2.5, 4.5), "size_end_mul": 2.2,
	})
	_smoke_trail.drag = 0.8
	_descent_voice = ctx.play(&"nova_descent", origin)


func _fx_process(delta: float) -> void:
	if is_instance_valid(_warhead):
		var k := clampf((t - T_DESCENT) / (T_IMPACT - T_DESCENT), 0.0, 1.0)
		var pos := _target_px + DESCENT_FROM * (1.0 - pow(k, 1.5))
		_warhead.position = pos.round()
		var nose := pos - DESCENT_FROM.normalized() * 8.0
		if is_instance_valid(_nose_glow):
			_nose_glow.position = nose.round()
		var tail := pos + DESCENT_FROM.normalized() * 16.0
		if is_instance_valid(_fire_trail):
			_fire_trail.spec["offset"] = tail
		if is_instance_valid(_smoke_trail):
			_smoke_trail.spec["offset"] = tail + DESCENT_FROM.normalized() * 8.0

	if is_instance_valid(_mushroom):
		_drive_mushroom()

	if _wave != null and not _wave_done:
		# Slow start, fast finish: the blast front accelerates outward.
		var k := clampf((t - T_BLAST) / WAVE_TIME, 0.0, 1.0)
		var eased := lerpf(CORE_GROW * 0.5, 1.0, pow(k, 1.7))
		_wave.set_param("progress", eased)
		_wave.set_param("fade", 1.0 - smoothstep(0.85, 1.0, k))
		var wave_r := eased * RADIUS
		for e in ctx.field.in_radius(origin, wave_r):
			ctx.field.kill(e, &"nova", origin)
		ctx.env.damage_radius(origin, wave_r, 99999.0, &"nova")
		# Rolling dust ring riding the front.
		if is_instance_valid(_dust):
			var spawn := int(ceil(110.0 * delta))
			for i in spawn:
				var a := ctx.rng.randf() * TAU
				var g := origin + Vector2.RIGHT.rotated(a) * wave_r
				var outward := (Iso.ground_to_screen(g) - _target_px).normalized()
				_dust.burst(1, {
					"offset": Iso.ground_to_screen(g) - _target_px, "velocity": outward * ctx.rng.randf_range(40, 90),
					"alt": Vector2(0, 6), "alt_speed": Vector2(8, 30), "life": Vector2(0.9, 1.7),
					"size": Vector2(5, 9), "size_end_mul": 1.4,
				})
		if k >= 1.0:
			_wave_done = true
			ctx.field.knock_from(origin, RADIUS, RADIUS + 2.5, 7.0)
			ctx.env.damage_radius(origin, RADIUS + 2.5, 70.0, &"nova")
			_wave.visible = false
			if is_instance_valid(_dust):
				_dust.auto_free = true


func _impact() -> void:
	if is_instance_valid(_warhead):
		_warhead.queue_free()
	if is_instance_valid(_nose_glow):
		_nose_glow.queue_free()
	ctx.fade_out(_descent_voice, 0.05)
	_rings.tween_param("alpha", 1.0, 0.0, 0.25)
	ctx.flash.call(Color(1.0, 0.85, 0.6, 0.5), 0.25)
	ctx.shake.add_trauma(0.45)
	ctx.shake.kick(Vector2(0, 4))
	ctx.play(&"nova_crack", origin)
	ctx.play(&"nova_swell", origin)
	# Anticipation: the world sinks into darkness while the core gathers light.
	ctx.impact.dim(0.6, 1.1)

	for e in ctx.field.in_radius(origin, KILL_CORE):
		ctx.field.kill(e, &"nova", origin)
	ctx.env.damage_radius(origin, KILL_CORE, 99999.0, &"nova")
	ctx.env.shake_radius(origin, RADIUS + 3.0, 1.5)

	var pillar := FxParts.beam(self, ctx.overhead, _target_px, 24.0, 420.0, FxParts.FIRE)
	pillar.tween_param("intensity", 0.5, 1.0, T_BLAST - T_IMPACT, 0.0, Tween.TRANS_SINE, Tween.EASE_IN)
	pillar.tween_param("intensity", 1.0, 0.0, 0.9, T_BLAST - T_IMPACT, Tween.TRANS_QUAD, Tween.EASE_IN)
	pillar.life = T_BLAST - T_IMPACT + 1.0

	# White-hot core swells slowly before the blast releases.
	_core = FxParts.dome(self, _target_px, FxParts.PX_PER_UNIT_MAJOR * 2.6)
	_core.set_param("detail", 1.8)
	_core.tween_param("grow", 0.1, CORE_GROW, T_BLAST - T_IMPACT, 0.0, Tween.TRANS_SINE, Tween.EASE_OUT)
	_core.set_param("heat", 1.35)

	var core_light := FxParts.ground_light(self, origin, 3.2, FIRE_LIGHT)
	core_light.tween_param("intensity", 0.3, 1.3, T_BLAST - T_IMPACT, 0.0, Tween.TRANS_SINE, Tween.EASE_IN)
	core_light.life = T_BLAST - T_IMPACT + 0.05

	var rays := FxParts.ground_rays(self, origin, 3.0, HOT_LIGHT, 72.0)
	rays.tween_param("reach", 0.25, 0.9, T_BLAST - T_IMPACT, 0.0, Tween.TRANS_SINE, Tween.EASE_IN)
	rays.life = T_BLAST - T_IMPACT + 0.05

	var crackle := FxParts.emitter(self, ctx.overhead, _target_px, PixelParticles.Shape.STREAK, FxParts.FIRE_LIFE, 90.0,
		T_BLAST - T_IMPACT, {
			"radius": 6.0, "speed": Vector2(60, 200), "alt": Vector2(0, 10), "alt_speed": Vector2(20, 120),
			"life": Vector2(0.15, 0.4), "size": Vector2(1, 3),
		})
	crackle.gravity = 200.0
	FxParts.debris(self, _target_px, 24, 6.0, Vector2(20, 110), FxParts.HOT_ROCK, Vector2(2, 5))

	var cracks := FxParts.decal(self, origin, 1.6)
	cracks.tween_param("heat", 1.0, 1.0, 0.6)
	cracks.life = T_BLAST - T_IMPACT + 0.1


func _blast() -> void:
	ctx.impact.impact_frame(0.06, ctx.impact.focus_of(_target_px))
	ctx.impact.hitstop(0.09)
	ctx.impact.aberration(4.0, 0.5)
	ctx.impact.dim(0.0, 0.9)
	at(T_BLAST + 0.02, func(): ctx.flash.call(Color(1.0, 0.92, 0.8, 0.55), 0.35))
	ctx.shake.add_trauma(1.0)
	ctx.shake.kick(Vector2(0, 9))
	ctx.play(&"nova_boom", origin)
	ctx.play(&"nova_shockwave", origin)

	# The core erupts: accelerating growth, then burns out.
	_core.tween_param("grow", CORE_GROW, 1.0, 0.3, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	_core.tween_param("heat", 1.15, 0.55, 1.5, 0.0, Tween.TRANS_SINE, Tween.EASE_IN)
	_core.tween_param("soot", 0.0, 0.7, 1.3, 0.4)
	_core.tween_param("dissolve", 0.0, 1.0, 0.9, 0.85, Tween.TRANS_QUAD, Tween.EASE_IN)
	_core.life = 1.8
	at(T_BLAST + 0.25, _start_mushroom)

	_wave = FxParts.shockwave(self, origin, RADIUS, FxParts.FIRE)
	_wave.set_param("thickness", 0.06)
	_wave.set_param("inner_heat", 0.1)

	# Air refraction ring leads, a slower rolling dust wave follows.
	var refract := FxParts.refract_ring(self, origin, RADIUS * 1.5, Color(1.0, 0.85, 0.6))
	refract.set_param("strength", 12.0)
	refract.tween_param("progress", 0.1, 1.0, 0.75, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	refract.life = 0.77
	var dust_wave := FxParts.shockwave(self, origin, RADIUS * 1.3, FxParts.DUST_RING)
	dust_wave.set_param("thickness", 0.14)
	dust_wave.set_param("inner_heat", 0.0)
	dust_wave.tween_param("progress", 0.1, 1.0, 1.4, 0.15, Tween.TRANS_QUAD, Tween.EASE_OUT)
	dust_wave.tween_param("fade", 1.0, 0.0, 0.6, 1.0)
	dust_wave.life = 1.6

	var light := FxParts.ground_light(self, origin, RADIUS * 1.15, FIRE_LIGHT)
	light.set_param("falloff", 1.2)
	light.tween_param("intensity", 1.6, 0.0, 2.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 2.7

	var rays := FxParts.ground_rays(self, origin, RADIUS * 1.1, HOT_LIGHT, 110.0)
	rays.tween_param("reach", 0.3, 1.0, WAVE_TIME, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	rays.tween_param("intensity", 1.4, 0.0, 1.1, WAVE_TIME * 0.6)
	rays.life = 1.8

	var burst := FxParts.screen_rays(self, _target_px + Vector2(0, -30), 190.0, HOT_LIGHT, 56.0)
	burst.tween_param("intensity", 1.2, 0.0, 0.9, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 1.0
	var glow := FxParts.bloom(self, _target_px + Vector2(0, -24), 160.0, FIRE_LIGHT, 1.0, 0.8)
	glow.tween_param("intensity", 1.1, 0.0, 1.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 1.7

	_dust = FxParts.particles(self, ctx.overhead_back, _target_px, PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
	_dust.auto_free = false
	_dust.drag = 1.2
	_dust.underglow = Color("ff7a2a")
	_dust.underglow_life = 0.5

	var crater := FxParts.decal(self, origin, 2.9)
	crater.tween_param("heat", 1.0, 0.0, 6.5)
	crater.tween_param("fade", 1.0, 0.0, 1.5, 5.6)

	FxParts.debris(self, _target_px, 55, 70.0, Vector2(120, 360), FxParts.HOT_ROCK, Vector2(2, 6), true)
	FxParts.debris(self, _target_px, 35, 90.0, Vector2(60, 240), FxParts.ROCK, Vector2(2, 5), true)
	FxParts.sparks(self, ctx.overhead, _target_px, 140, FxParts.FIRE_LIFE, Vector2(140, 460), Vector2(40, 360))


## Shader mushroom cloud: the fireball lifts into a rolling cap on a stem, cooling from fire to smoke.
func _start_mushroom() -> void:
	_mushroom_t0 = t
	_mushroom = QuadFx.new().setup(FxParts.SH_MUSHROOM, Vector2(310, 250), Vector2(0.5, 1.0))
	_mushroom.position = _target_px
	_mushroom.set_param("size_px", Vector2(310, 250))
	_mushroom.set_param("seed", ctx.rng.randf() * 30.0)
	FxParts.set_ramp(_mushroom, FxParts.FIRE)
	track(_mushroom, ctx.overhead_back)
	_drive_mushroom()


func _drive_mushroom() -> void:
	var m := t - _mushroom_t0
	# Proportions of a real nuclear mushroom: a rounded fireball lifts off, flattens into a cap
	# ~0.6 as tall as it is wide, on a stem roughly twice the cap's height, over a wide low skirt.
	var rx := curve([[0.0, 30.0], [0.8, 40.0], [2.3, 52.0], [4.5, 58.0], [6.5, 60.0]], m)
	_mushroom.set_param("rise", curve([[0.0, 26.0], [0.8, 64.0], [2.3, 108.0], [4.5, 126.0], [6.5, 132.0]], m))
	_mushroom.set_param("cap_rx", rx)
	_mushroom.set_param("cap_ry", rx * curve([[0.0, 0.9], [1.2, 0.68], [3.0, 0.58]], m))
	_mushroom.set_param("stem_w", curve([[0.0, 5.0], [1.2, 8.0], [4.0, 9.0]], m))
	_mushroom.set_param("base_w", curve([[0.0, 10.0], [1.2, 14.0], [4.0, 16.0]], m))
	_mushroom.set_param("skirt_rx", curve([[0.3, 0.0], [1.0, 50.0], [3.0, 80.0], [6.0, 92.0]], m))
	_mushroom.set_param("heat", curve([[0.0, 1.5], [0.8, 1.2], [2.3, 0.55], [3.8, 0.18], [5.5, 0.0]], m))
	_mushroom.set_param("ring", curve([[0.9, 0.0], [1.2, 1.0], [2.0, 0.8], [2.8, 0.0]], m))
	_mushroom.set_param("fade", curve([[5.6, 1.0], [6.6, 0.0]], m))


func _aftermath() -> void:
	ctx.play(&"nova_rumble", origin)
	_geiger = ctx.play(&"nova_geiger", origin, -4.0)
	at(t + 5.2, func(): ctx.fade_out(_geiger, 1.5))


	var haze := FxParts.heat_haze(self, _target_px, 130.0, 2.0)
	haze.tween_param("strength", 2.0, 0.0, 2.0, 3.2)
	haze.life = 5.4

	var fire_light := FxParts.ground_light(self, origin, 3.0, FIRE_LIGHT, 0.55)
	fire_light.set_param("flicker", 1.0)
	fire_light.tween_param("intensity", 0.55, 0.0, 2.0, 2.2)
	fire_light.life = 4.3

	# Ring of lingering fires around the crater rim.
	for i in 9:
		var a := TAU * i / 9.0 + ctx.rng.randf() * 0.4
		var rim := Iso.ground_to_screen(origin + Vector2.RIGHT.rotated(a) * ctx.rng.randf_range(1.8, 2.8))
		FxParts.emitter(self, ctx.overhead, rim, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 16.0,
			ctx.rng.randf_range(2.5, 4.0), {
				"radius": 6.0, "speed": Vector2(0, 6), "alt_speed": Vector2(18, 45), "life": Vector2(0.3, 0.65),
				"size": Vector2(1.5, 3.5), "size_end_mul": 0.3,
			})
		FxParts.smoke(self, rim, 5.0, 4.0, 3.5, Vector2(15, 35), Vector2(2, 4), Vector2(1.2, 2.0))

	var rad := FxParts.fog(self, origin, 4.6, Color(0.42, 0.95, 0.28, 0.5))
	rad.tween_param("density", 0.0, 1.0, 1.8, 0.4, Tween.TRANS_SINE, Tween.EASE_OUT)
	rad.tween_param("fade", 1.0, 0.0, 1.6, 5.0)

	var fallout := FxParts.emitter(self, ctx.overhead, _target_px, PixelParticles.Shape.SQUARE, FxParts.RAD_LIFE, 45.0, 5.2, {
		"radius": FxParts.particle_radius(4.0), "alt": Vector2(0, 14), "alt_speed": Vector2(6, 20),
		"speed": Vector2(0, 6), "life": Vector2(0.9, 1.9), "size": Vector2(1, 2),
	})
	fallout.drag = 0.0
	FxParts.emitter(self, ctx.overhead, _target_px, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 36.0, 3.0, {
		"radius": FxParts.particle_radius(2.6), "alt": Vector2(0, 10), "alt_speed": Vector2(15, 45),
		"speed": Vector2(0, 12), "life": Vector2(0.6, 1.4), "size": Vector2(1, 1),
	})
