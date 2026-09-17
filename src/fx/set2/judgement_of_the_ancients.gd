extends FxTimeline
## Judgement of the Ancients: golden earth rune and dust ring -> stone hands and a titan rise from the ground ->
## knuckle combo barrage slamming the battlefield -> two-hand final slam with a golden shockwave -> the titan
## crumbles, leaving rubble and dust.

const RADIUS := 5.2
const T_HANDS := 1.3
const T_RISE := 2.0
const RISE_TIME := 1.1
const T_COMBO := 3.4
const PUNCHES := 8
const PUNCH_GAP := 0.5
## Punch clip timing: fist raise and slam down, then pull back.
const PUNCH_BEFORE := 0.24
const PUNCH_AFTER := 0.24
const T_FINAL := T_COMBO + PUNCHES * PUNCH_GAP + 0.3
const FINAL_WINDUP := 0.55
const T_CRUMBLE := T_FINAL + FINAL_WINDUP + 1.6
const GOLD_LIGHT := Color(1.0, 0.8, 0.4)


var _center_px := Vector2.ZERO
var _sigil: SigilRune
var _golem: GolemSprite


func _build() -> void:
	duration = 13.0
	# The titan stands just behind the target so its fists land around the cast point.
	_center_px = Iso.ground_to_screen(origin)
	_sigil = Set2Parts.sigil(self, origin, 3.4, Color("ffc85a"), "earth")
	var dust_ring := FxParts.rings(self, origin, RADIUS, Color("e8c078"), 2, 30.0)
	dust_ring.z_index = 8
	dust_ring.set_param("crosshair", 0.0)
	dust_ring.set_param("fill", 0.05)
	dust_ring.tween_param("reveal", 0.0, 1.0, 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	dust_ring.tween_param("alpha", 1.0, 0.0, 0.8, T_FINAL)
	var glow := FxParts.ground_light(self, origin, 3.8, GOLD_LIGHT, 0.0)
	glow.tween_param("intensity", 0.0, 0.8, T_HANDS)
	glow.tween_param("intensity", 0.8, 0.0, 1.0, T_RISE + RISE_TIME)
	ctx.impact.dim(0.5, 1.0)
	ctx.play(&"jg_rumble", origin)
	# Falling pebbles and dust kicking up around the rune.
	FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.CHUNK, Set2Parts.STONE_CHUNK, 16.0, T_RISE, {
		"radius": FxParts.particle_radius(RADIUS * 0.8), "alt": Vector2(90, 160), "alt_speed": Vector2(-40, 0),
		"life": Vector2(0.5, 0.9), "size": Vector2(1.5, 3.0),
	}).gravity = 300.0
	FxParts.emitter(self, ctx.overhead_back, _center_px, PixelParticles.Shape.PUFF, Set2Parts.DUST_CLOUD, 14.0, T_RISE, {
		"radius": FxParts.particle_radius(RADIUS * 0.95), "speed": Vector2(4, 16), "alt_speed": Vector2(4, 14),
		"life": Vector2(0.8, 1.4), "size": Vector2(3, 5), "size_end_mul": 1.5,
	})

	at(T_HANDS, _hands)
	at(T_RISE, _rise)
	for i in PUNCHES:
		at(T_COMBO + i * PUNCH_GAP, _punch.bind(i))
	at(T_FINAL, _final_windup)
	at(T_FINAL + FINAL_WINDUP, _final_slam)
	at(T_CRUMBLE, _crumble)


func _fx_process(delta: float) -> void:
	if t < T_CRUMBLE and t > T_HANDS:
		ctx.env.shake_radius(origin, RADIUS, 0.8)


func _hands() -> void:
	ctx.play(&"jg_hands", origin)
	ctx.shake.add_trauma(0.5)
	create_tween().tween_property(_sigil, "alpha", 0.0, 0.8)
	# Stone hands and rock spikes breaking out of the ground first.
	for side in [-1.0, 1.0]:
		var g := origin + Vector2(side * 1.6, -side * 1.6) * 0.8
		var sp := Iso.ground_to_screen(g)
		_spike_burst(g, 1.0, 7)
		FxParts.debris(self, sp, 24, 14.0, Vector2(40, 180), Set2Parts.STONE_CHUNK, Vector2(2, 5), true)
		FxParts.smoke(self, sp, 18.0, 16.0, 0.8, Vector2(10, 30), Vector2(4, 7), Vector2(1.0, 1.6))
	var burst := FxParts.bloom(self, _center_px, 70.0, GOLD_LIGHT, 1.0, 0.8)
	burst.tween_param("intensity", 1.0, 0.0, 0.8)
	burst.life = 0.82


func _rise() -> void:
	ctx.play(&"jg_rise", origin)
	_golem = GolemSprite.new()
	# Locked facing the camera, standing on the cast point; its fists land just in front of it.
	_golem.position = _center_px
	track(_golem, ctx.overhead_back)
	create_tween().tween_property(_golem, "emerge", 1.0, RISE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ctx.shake.add_trauma(0.7)
	for k in 5:
		at(t + k * 0.2, func():
			FxParts.debris(self, _center_px, 20, 60.0, Vector2(50, 220), Set2Parts.STONE_CHUNK, Vector2(2, 6), true)
			FxParts.smoke(self, _center_px, 60.0, 30.0, 0.2, Vector2(10, 40), Vector2(5, 9), Vector2(1.2, 2.0)))
	var mound := FxParts.decal(self, origin, 2.2, Color("e8b860"), Color("fff0c0"), Color(0.2, 0.16, 0.12, 0.85))
	mound.tween_param("heat", 1.0, 0.3, 3.0)
	mound.tween_param("fade", 1.0, 0.0, 1.0, duration - t - 1.1)
	var light := FxParts.ground_light(self, origin, 4.5, GOLD_LIGHT, 0.0)
	light.tween_param("intensity", 0.0, 0.45, RISE_TIME)
	light.tween_param("intensity", 0.45, 0.0, 1.0, T_CRUMBLE - t)
	for e in ctx.field.in_radius(origin, 1.3):
		ctx.field.kill(e, &"stone", origin)
	ctx.field.knock_from(origin, 1.3, 3.0, 5.5)


## Alternating left/right knuckle punches from the sprite clips. Each lands where the fist hits the ground,
## then a second shock bursts further out in front so the barrage covers the battlefield.
func _punch(i: int) -> void:
	var clip := "punch_l" if i % 2 == 0 else "punch_r"
	var fist := _golem.play(clip, PUNCH_BEFORE, PUNCH_AFTER)
	var g := Iso.screen_to_ground(_golem.position + fist)
	var out := (g - origin).normalized() if g.distance_to(origin) > 0.05 else Vector2(1, 1).normalized()
	var reach := (out * 0.5 + Vector2(1, 1).normalized() * 0.5).normalized().rotated(ctx.rng.randf_range(-0.45, 0.45))
	var far := g + reach * ctx.rng.randf_range(1.5, 2.6)
	at(t + PUNCH_BEFORE, _knuckle_impact.bind(g, 1.0, i % 3 == 2))
	at(t + PUNCH_BEFORE + 0.08, _knuckle_impact.bind(far, 0.8, false))


func _knuckle_impact(g: Vector2, size: float, heavy: bool) -> void:
	var sp := Iso.ground_to_screen(g)
	ctx.play(&"jg_punch", g)
	ctx.shake.add_trauma(0.35 * size)
	ctx.shake.kick(Vector2(0, 5 * size))
	if heavy:
		ctx.impact.hitstop(0.05)
		ctx.impact.aberration(2.0, 0.25)
	var ring := FxParts.shockwave(self, g, 1.8 * size, Set2Parts.GOLD)
	ring.z_index = 9
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.25, 0.15)
	ring.life = 0.45
	var flash := FxParts.bloom(self, sp + Vector2(0, -6), 34.0 * size, GOLD_LIGHT, 1.2, 0.7)
	flash.tween_param("intensity", 1.2, 0.0, 0.35)
	flash.life = 0.37
	var rays := FxParts.ground_rays(self, g, 1.8 * size, Color(1.0, 0.85, 0.5), 40.0)
	rays.tween_param("intensity", 1.2, 0.0, 0.45)
	rays.life = 0.47
	var light := FxParts.ground_light(self, g, 2.0 * size, GOLD_LIGHT)
	light.tween_param("intensity", 1.2, 0.0, 0.6)
	light.life = 0.62
	var crack := FxParts.decal(self, g, 1.1 * size, Color("e8b860"), Color("fff0c0"), Color(0.16, 0.13, 0.1, 0.85))
	crack.tween_param("heat", 1.0, 0.15, 1.6)
	crack.tween_param("fade", 1.0, 0.0, 1.0, duration - t - 1.1)
	_spike_burst(g, size, 6)
	FxParts.debris(self, sp, int(26 * size), 8.0, Vector2(50, 220), Set2Parts.STONE_CHUNK, Vector2(2, 5), true)
	FxParts.sparks(self, ctx.overhead, sp, int(18 * size), Set2Parts.GOLD_LIFE, Vector2(60, 220), Vector2(30, 200))
	var dust := FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, Set2Parts.DUST_CLOUD)
	dust.drag = 1.4
	dust.burst(int(14 * size), {"radius": 10.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(30, 90),
		"alt": Vector2(0, 8), "alt_speed": Vector2(4, 20), "life": Vector2(0.8, 1.4), "size": Vector2(3, 6), "size_end_mul": 1.5})
	for e in ctx.field.in_radius(g, 1.1 * size):
		ctx.field.kill(e, &"stone", g)
	ctx.field.knock_from(g, 1.1 * size, 2.4 * size, 5.0)
	ctx.env.damage_radius(g, 1.3 * size, 90.0 * size, &"stone")


## Sandstone shards bursting out of the ground around a point.
func _spike_burst(g: Vector2, size: float, count: int) -> void:
	var sp := Iso.ground_to_screen(g)
	for i in count:
		var a := TAU * i / count + ctx.rng.randf_range(-0.3, 0.3)
		var pg := g + Vector2.RIGHT.rotated(a) * ctx.rng.randf_range(0.3, 0.8) * size
		var s := IceSpike.new()
		s.palette = 1
		s.ground_pos = pg
		s.position = Iso.ground_to_screen(pg).round()
		s.height = ctx.rng.randf_range(20.0, 40.0) * size
		s.width = ctx.rng.randf_range(5.0, 9.0) * size
		s.angle = clampf((Iso.ground_to_screen(pg) - sp).x * 0.03, -0.7, 0.7)
		s.seed = ctx.rng.randf() * 100.0
		s.lights = ctx.lights
		track(s, ctx.world)
		var tw := s.create_tween()
		tw.tween_property(s, "grow", 1.0, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(ctx.rng.randf_range(0.8, 1.6))
		tw.tween_property(s, "shatter", 1.0, 0.5)
		tw.parallel().tween_property(s, "fade", 0.0, 0.6)
		tw.tween_callback(s.queue_free)


func _final_windup() -> void:
	ctx.play(&"jg_windup", origin)
	ctx.impact.dim(0.6, 2.0)
	_golem.play("slam", FINAL_WINDUP, 1.4)
	var gather := FxParts.bloom(self, _golem.position + _golem.crown(), 90.0, GOLD_LIGHT, 0.0, 1.0)
	gather.tween_param("intensity", 0.0, 1.3, FINAL_WINDUP, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	gather.life = FINAL_WINDUP + 0.05
	var motes := FxParts.emitter(self, ctx.overhead, _golem.position + _golem.crown(), PixelParticles.Shape.STREAK,
		Set2Parts.GOLD_LIFE, 80.0, FINAL_WINDUP, {
			"radius": 110.0, "dir": PixelParticles.Dir.INWARD, "speed": Vector2(80, 180), "life": Vector2(0.3, 0.5),
			"size": Vector2(2, 3),
		})
	motes.streak_len = 0.05


func _final_slam() -> void:
	_final_impact(Iso.screen_to_ground(_golem.position + _golem.impact_pos("slam")))


func _final_impact(g: Vector2) -> void:
	var sp := Iso.ground_to_screen(g)
	ctx.play(&"jg_slam", g)
	ctx.impact.impact_frame(0.06, ctx.impact.focus_of(sp), Color(1.0, 0.95, 0.8), Color(0.14, 0.08, 0.02))
	ctx.impact.hitstop(0.12)
	ctx.impact.aberration(4.0, 0.5)
	ctx.impact.dim(0.2, 1.2)
	ctx.flash.call(Color(1.0, 0.9, 0.65, 0.5), 0.35)
	ctx.shake.add_trauma(1.0)
	ctx.shake.kick(Vector2(0, 10))
	_knuckle_impact(g, 1.6, false)
	var wave := FxParts.shockwave(self, g, RADIUS * 1.1, Set2Parts.GOLD)
	wave.z_index = 9
	wave.set_param("thickness", 0.06)
	wave.tween_param("progress", 0.05, 1.0, 0.7, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.35, 0.45)
	wave.life = 0.85
	var dust_wave := FxParts.shockwave(self, g, RADIUS * 1.3, FxParts.DUST_RING)
	dust_wave.set_param("thickness", 0.14)
	dust_wave.tween_param("progress", 0.1, 1.0, 1.2, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	dust_wave.tween_param("fade", 1.0, 0.0, 0.5, 0.9)
	dust_wave.life = 1.45
	var refract := FxParts.refract_ring(self, g, RADIUS * 1.4, Color(1.0, 0.9, 0.7))
	refract.tween_param("progress", 0.05, 1.0, 0.75, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	refract.life = 0.77
	var rays := FxParts.ground_rays(self, g, RADIUS, Color(1.0, 0.85, 0.5), 110.0)
	rays.tween_param("reach", 0.3, 1.0, 0.5, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	rays.tween_param("intensity", 1.4, 0.0, 0.9, 0.2)
	rays.life = 1.12
	var light := FxParts.ground_light(self, g, RADIUS * 1.1, GOLD_LIGHT)
	light.set_param("falloff", 1.2)
	light.tween_param("intensity", 1.6, 0.0, 1.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 1.42
	for i in 14:
		var a := TAU * i / 14.0
		_spike_burst(g + Vector2.RIGHT.rotated(a) * ctx.rng.randf_range(1.2, 2.6), 1.2, 3)
	FxParts.debris(self, sp, 90, 30.0, Vector2(80, 340), Set2Parts.STONE_CHUNK, Vector2(2, 6), true)
	for e in ctx.field.in_radius(g, 3.4):
		ctx.field.kill(e, &"stone", g)
	ctx.field.knock_from(g, 3.4, RADIUS + 2.0, 7.0)
	ctx.env.damage_radius(g, 3.4, 99999.0, &"stone")
	ctx.env.damage_radius(g, RADIUS + 1.0, 60.0, &"stone")


func _crumble() -> void:
	ctx.play(&"jg_crumble", origin)
	var tw := create_tween()
	tw.tween_property(_golem, "crumble", 1.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_golem, "emerge", 0.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.3)
	for k in 6:
		at(t + k * 0.28, func():
			var p := _golem.position + Vector2(ctx.rng.randf_range(-140, 140), ctx.rng.randf_range(-220, -40))
			FxParts.debris(self, p, 12, 20.0, Vector2(20, 110), Set2Parts.STONE_CHUNK, Vector2(3, 7), true)
			FxParts.smoke(self, _golem.position + Vector2(0, 30), 60.0, 24.0, 0.3, Vector2(10, 30), Vector2(5, 9), Vector2(1.2, 2.2)))
	ctx.shake.add_trauma(0.5)
	# Lingering rubble mound and dust.
	for i in 10:
		var g := origin + Vector2.RIGHT.rotated(ctx.rng.randf() * TAU) * ctx.rng.randf_range(0.3, 1.6)
		var rubble := IceSpike.new()
		rubble.palette = 1
		rubble.cluster = true
		rubble.ground_pos = g
		rubble.position = Iso.ground_to_screen(g).round()
		rubble.height = ctx.rng.randf_range(10.0, 20.0)
		rubble.width = ctx.rng.randf_range(8.0, 12.0)
		rubble.angle = ctx.rng.randf_range(-0.9, 0.9)
		rubble.seed = ctx.rng.randf() * 100.0
		rubble.lights = ctx.lights
		track(rubble, ctx.world)
		var rt := rubble.create_tween()
		rt.tween_interval(0.8 + i * 0.05)
		rt.tween_property(rubble, "grow", 1.0, 0.2)
		rt.tween_interval(duration - t - 2.2)
		rt.tween_property(rubble, "fade", 0.0, 1.0)
	at(duration - 1.2, func(): ctx.impact.dim(0.0, 0.6))
