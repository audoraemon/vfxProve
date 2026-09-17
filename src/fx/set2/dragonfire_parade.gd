extends FxTimeline
## Dragonfire Parade: draconic sigil -> the earth ruptures in lava and obsidian -> a colossal fire dragon rises ->
## it sweeps its head left to right breathing a devastating cone of flame -> it sinks away, leaving scorched
## earth and fires that keep burning.

const CONE_RADIUS := 5.6
const SWEEP_ARC := 2.1
const T_ERUPT := 1.2
const T_RISE := 2.2
const RISE_TIME := 1.2
const T_INHALE := 3.6
const T_BREATH := 4.1
const BREATH_TIME := 2.4
const T_SINK := T_BREATH + BREATH_TIME + 0.4
const BEAM_HALF_ANGLE := 0.2
const FIRE_LIGHT := Color(1.0, 0.5, 0.18)
const SH_CONE := preload("res://shaders/fire_cone.gdshader")
const SH_STREAM := preload("res://shaders/flame_stream.gdshader")
const JET_REACH := 0.55


var _center_px := Vector2.ZERO
var _dir := Vector2(1, 0)
var _start_angle := 0.0
var _sigil: SigilRune
var _dragon: FireDragon
var _cone: QuadFx
var _stream: PixelParticles
var _jet: QuadFx
var _breath_voice: Node
var _burn_voice: Node
var _sweep := 0.0
var _breathing := false
var _next_patch := 0.0


func _build() -> void:
	duration = 11.5
	_center_px = Iso.ground_to_screen(origin)
	_dir = (extra.get("dir", Vector2(1, 1)) as Vector2).normalized()
	_start_angle = _dir.angle() - SWEEP_ARC * 0.5
	_sigil = Set2Parts.sigil(self, origin, 2.4, Color("ff5a2a"), "dragon")
	# Sweep arc indicator showing the coming cone.
	var arc := FxParts.quad(self, SH_CONE, Vector2.ONE * CONE_RADIUS * 2.0, ctx.ground)
	arc.position = origin
	arc.z_index = 8
	arc.set_param("start", _start_angle)
	arc.set_param("sweep", SWEEP_ARC)
	arc.set_param("heat", 0.35)
	arc.set_param("fade", 0.0)
	arc.tween_param("fade", 0.0, 0.35, 0.8)
	arc.tween_param("fade", 0.35, 0.0, 0.4, T_BREATH - 0.4)
	arc.life = T_BREATH + 0.05
	var glow := FxParts.ground_light(self, origin, 3.0, FIRE_LIGHT, 0.0)
	glow.tween_param("intensity", 0.0, 0.8, T_ERUPT)
	ctx.impact.dim(0.5, 1.0)
	ctx.play(&"dr_rumble", origin)
	at(T_ERUPT, _erupt)
	at(T_RISE, _rise)
	at(T_INHALE, _inhale)
	at(T_BREATH, _breathe)
	at(T_SINK, _sink)


func _erupt() -> void:
	ctx.play(&"dr_erupt", origin)
	ctx.shake.add_trauma(0.7)
	create_tween().tween_property(_sigil, "alpha", 0.0, 0.6)
	var fissure := FxParts.decal(self, origin, 2.6, Color("ff6a1a"), Color("ffd27a"), Color(0.12, 0.05, 0.03, 0.9))
	fissure.z_index = 2
	fissure.tween_param("heat", 1.0, 0.5, 4.0)
	fissure.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	# Obsidian shards and lava bursting out of the ground in a ring.
	for i in 16:
		var a := TAU * i / 16.0 + ctx.rng.randf_range(-0.15, 0.15)
		var g := origin + Vector2.RIGHT.rotated(a) * ctx.rng.randf_range(0.7, 1.9)
		var s := IceSpike.new()
		s.palette = 2
		s.ground_pos = g
		s.position = Iso.ground_to_screen(g).round()
		s.height = ctx.rng.randf_range(22.0, 44.0)
		s.width = ctx.rng.randf_range(6.0, 10.0)
		s.angle = clampf((Iso.ground_to_screen(g) - _center_px).x * 0.012, -0.6, 0.6)
		s.seed = ctx.rng.randf() * 100.0
		s.glow = 1.0
		s.lights = ctx.lights
		track(s, ctx.world)
		var tw := s.create_tween()
		tw.tween_interval(i * 0.02)
		tw.tween_property(s, "grow", 1.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(T_SINK - T_ERUPT + ctx.rng.randf_range(0.0, 0.6))
		tw.tween_property(s, "shatter", 1.0, 0.6)
		tw.tween_interval(duration - T_SINK - 2.0)
		tw.tween_property(s, "fade", 0.0, 0.8)
	var lava := FxParts.particles(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.FIRE_LIFE)
	lava.gravity = 360.0
	lava.drag = 0.5
	lava.burst(120, {"radius": 30.0, "speed": Vector2(20, 120), "alt_speed": Vector2(100, 300), "life": Vector2(0.6, 1.2),
		"size": Vector2(1, 3)})
	FxParts.debris(self, _center_px, 40, 30.0, Vector2(50, 220), Set2Parts.OBSIDIAN, Vector2(2, 5), true)
	FxParts.smoke(self, _center_px, 40.0, 30.0, 0.8, Vector2(20, 60), Vector2(5, 8), Vector2(1.2, 2.0), Color("ff5a1a"))
	for e in ctx.field.in_radius(origin, 1.9):
		ctx.field.kill(e, &"cinder", origin)
	ctx.env.damage_radius(origin, 1.9, 99999.0, &"cinder")


func _rise() -> void:
	ctx.play(&"dr_roar", origin)
	ctx.impact.impact_frame(0.05, ctx.impact.focus_of(_center_px + Vector2(0, -80)), Color(1.0, 0.9, 0.6), Color(0.15, 0.02, 0.0))
	ctx.impact.hitstop(0.06)
	ctx.impact.aberration(3.0, 0.4)
	ctx.shake.add_trauma(0.9)
	_dragon = FireDragon.new()
	_dragon.position = _center_px
	_dragon.aim = Iso.ground_to_screen(origin + _dir * 4.0) - _center_px + Vector2(0, -150)
	track(_dragon, ctx.overhead_back)
	create_tween().tween_property(_dragon, "rise", 1.0, RISE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(_dragon, "wings", 1.0, 0.7).set_delay(RISE_TIME * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var light := FxParts.ground_light(self, origin, 4.8, FIRE_LIGHT)
	light.set_param("flicker", 1.0)
	light.tween_param("intensity", 0.0, 1.1, RISE_TIME)
	light.tween_param("intensity", 1.1, 0.0, 1.2, T_SINK - t)
	var bloom := FxParts.bloom(self, _center_px + Vector2(0, -90), 120.0, FIRE_LIGHT, 0.0, 1.2)
	bloom.tween_param("intensity", 0.0, 0.75, RISE_TIME)
	bloom.tween_param("intensity", 0.75, 0.0, 1.0, T_SINK - t)
	bloom.life = T_SINK - t + 1.1
	var haze := FxParts.heat_haze(self, _center_px + Vector2(0, -60), 120.0, 2.0)
	haze.tween_param("strength", 2.0, 0.0, 1.0, T_SINK - t)
	haze.life = T_SINK - t + 1.1
	FxParts.emitter(self, ctx.overhead, _center_px + Vector2(0, -60), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 40.0,
		T_SINK - t, {
			"radius": 60.0, "alt": Vector2(0, 80), "alt_speed": Vector2(20, 60), "speed": Vector2(0, 14),
			"life": Vector2(0.6, 1.3), "size": Vector2(1, 2),
		})
	for e in ctx.field.in_radius(origin, 2.4):
		ctx.field.kill(e, &"fire", origin)


func _inhale() -> void:
	ctx.play(&"dr_inhale", origin)
	# Head rears back toward the start of the sweep, jaw opens, a flash gathers in the mouth.
	var start_target := Iso.ground_to_screen(origin + Vector2.RIGHT.rotated(_start_angle) * CONE_RADIUS) - _center_px
	var tw := create_tween()
	tw.tween_property(_dragon, "aim", start_target + Vector2(0, -60), T_BREATH - T_INHALE).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_dragon, "jaw", 1.0, T_BREATH - T_INHALE)
	var flash := FxParts.bloom(self, _center_px + _dragon.mouth_pos(), 20.0, Color(1.0, 0.85, 0.5), 0.0)
	flash.tween_param("intensity", 0.0, 1.4, T_BREATH - T_INHALE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	flash.life = T_BREATH - T_INHALE + 0.05


func _breathe() -> void:
	ctx.play(&"dr_ignite", origin)
	_breath_voice = ctx.play(&"dr_breath", origin, -1.0)
	ctx.impact.dim(0.3, 1.5)
	ctx.impact.aberration(2.5, 0.3)
	ctx.shake.add_trauma(0.5)
	_breathing = true
	_cone = QuadFx.new().setup(SH_CONE, Vector2.ONE * CONE_RADIUS * 2.0)
	_cone.position = origin
	_cone.z_index = 7
	_cone.set_param("start", _start_angle)
	_cone.set_param("sweep", 0.0)
	_cone.set_param("seed", ctx.rng.randf() * 20.0)
	track(_cone, ctx.ground)
	_jet = QuadFx.new().setup(SH_STREAM, Vector2(100, 72), Vector2(0.0, 0.5))
	_jet.set_param("seed", ctx.rng.randf() * 100.0)
	_jet.set_param("width_px", 72.0)
	_jet.z_index = 1
	track(_jet, ctx.overhead)
	_jet.tween_param("fade", 0.0, 1.0, 0.12)
	_stream = FxParts.particles(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE)
	_stream.auto_free = false
	_stream.drag = 0.6
	ctx.lights.register_quad(_cone, origin, 3.2, FIRE_LIGHT,
		func(): return origin + Vector2.RIGHT.rotated(_start_angle + _sweep) * CONE_RADIUS * 0.6)
	_cone.set_param("intensity", 0.7)


func _fx_process(delta: float) -> void:
	if not _breathing:
		return
	var k := clampf((t - T_BREATH) / BREATH_TIME, 0.0, 1.0)
	_sweep = SWEEP_ARC * (k * k * (3.0 - 2.0 * k) * 0.5 + k * 0.5)
	_cone.set_param("sweep", _sweep)
	var beam_angle := _start_angle + _sweep
	var beam_dir := Vector2.RIGHT.rotated(beam_angle)
	var far := origin + beam_dir * CONE_RADIUS
	var far_px := Iso.ground_to_screen(far) - _center_px
	_dragon.aim = far_px + Vector2(0, -60)
	var mouth := _center_px + _dragon.mouth_pos()
	# Thick flame jet from the mouth to where it hits the ground, then puffs rolling on along the cone.
	var hit := Iso.ground_to_screen(origin + beam_dir * CONE_RADIUS * JET_REACH)
	_jet.position = mouth
	_jet.rotation = (hit - mouth).angle()
	_jet.size = Vector2(mouth.distance_to(hit) + 12.0, 72.0)
	_jet.set_param("length_px", _jet.size.x)
	_jet.queue_redraw()
	for i in int(ceil(70.0 * delta)):
		var along := ctx.rng.randf_range(JET_REACH, 1.0)
		var target := Iso.ground_to_screen(origin + beam_dir.rotated(ctx.rng.randf_range(-BEAM_HALF_ANGLE, BEAM_HALF_ANGLE)) * CONE_RADIUS * along)
		var life := ctx.rng.randf_range(0.25, 0.45)
		_stream.burst(1, {"offset": hit, "velocity": (target - hit) / life, "life": Vector2(life, life),
			"size": Vector2(3, 5), "size_end_mul": 1.6})
	# Enemies and buildings inside the beam band burn.
	for e in ctx.field.in_radius(origin, CONE_RADIUS):
		var rel := e.ground_pos - origin
		if absf(angle_difference(rel.angle(), beam_angle)) < BEAM_HALF_ANGLE and rel.length() > 0.8:
			ctx.field.kill(e, &"fire", origin)
	for s in ctx.env.structures():
		if is_instance_valid(s) and not s.destroyed:
			var rel := s.center() - origin
			if rel.length() < CONE_RADIUS and absf(angle_difference(rel.angle(), beam_angle)) < BEAM_HALF_ANGLE:
				s.damage(260.0 * delta, origin, &"fire")
	ctx.shake.add_trauma(0.4 * delta)
	# Residual fire patches left along the swept area.
	if _sweep >= _next_patch:
		_next_patch += 0.2
		for n in 2:
			var g := origin + Vector2.RIGHT.rotated(beam_angle + ctx.rng.randf_range(-0.1, 0.1)) * ctx.rng.randf_range(1.4, CONE_RADIUS * 0.9)
			_fire_patch(g)
	if k >= 1.0:
		_breathing = false
		ctx.fade_out(_breath_voice, 0.4)
		_stream.auto_free = true
		_jet.tween_param("fade", 1.0, 0.0, 0.25)
		_jet.life = _jet.age + 0.3
		create_tween().tween_property(_dragon, "jaw", 0.0, 0.3)
		_cone.tween_param("heat", 1.0, 0.45, 1.5)
		_cone.tween_param("intensity", 0.7, 0.0, 1.2)
		_cone.tween_param("fade", 1.0, 0.0, 2.0, duration - t - 2.1)


func _fire_patch(g: Vector2) -> void:
	var sp := Iso.ground_to_screen(g)
	var flame := FlameSprite.new()
	flame.size = ctx.rng.randf_range(0.8, 1.3)
	flame.setup(ctx.rng, ctx.rng.randi_range(3, 5))
	flame.position = sp.round()
	track(flame, ctx.world)
	var burn_out := duration - t - ctx.rng.randf_range(0.6, 2.0)
	var tw := flame.create_tween()
	tw.tween_property(flame, "strength", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(burn_out - 0.9, 0.1))
	tw.tween_property(flame, "strength", 0.0, 0.6)
	FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -14), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 5.0, burn_out, {
		"radius": 8.0, "alt_speed": Vector2(20, 50), "life": Vector2(0.4, 0.9), "size": Vector2(1, 1),
	})
	FxParts.smoke(self, sp, 6.0, 1.2, duration - t - 2.0, Vector2(14, 34), Vector2(3, 5), Vector2(1.2, 2.2))
	var light := FxParts.ground_light(self, g, 1.2, FIRE_LIGHT, 0.7)
	light.set_param("flicker", 1.0)
	light.tween_param("intensity", 0.7, 0.0, 1.2, duration - t - 1.3)


func _sink() -> void:
	ctx.play(&"dr_sink", origin)
	_burn_voice = ctx.play(&"laser_fire", origin, -6.0)
	var tw := create_tween()
	tw.tween_property(_dragon, "wings", 0.0, 0.5)
	tw.parallel().tween_property(_dragon, "rise", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_dragon, "fade", 0.0, 1.2).set_delay(0.4)
	FxParts.emitter(self, ctx.overhead, _center_px + Vector2(0, -70), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 120.0, 1.2, {
		"radius": 50.0, "alt": Vector2(0, 90), "alt_speed": Vector2(30, 90), "speed": Vector2(10, 40),
		"life": Vector2(0.6, 1.4), "size": Vector2(1, 3),
	})
	FxParts.smoke(self, _center_px, 30.0, 20.0, 1.5, Vector2(30, 80), Vector2(5, 9), Vector2(1.6, 2.6), Color("ff5a1a"))
	at(duration - 1.3, func():
		ctx.fade_out(_burn_voice, 1.2)
		ctx.impact.dim(0.0, 0.6))
