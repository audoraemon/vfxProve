extends FxTimeline
## Glacial Cataclysm: frost rune -> ice spikes erupt -> freeze wave spreads -> crystal mountain peaks
## -> spikes shatter, frozen ground, icy fog and snow remain.

const RADIUS := 5.0
const T_ERUPT := 1.2
const T_FREEZE := 2.2
const FREEZE_TIME := 0.9
const T_PEAK := 3.2
const T_AFTER := 4.6
const ERUPT_KILL := 1.4
const PEAK_KILL := 1.6
const FREEZE_SECONDS := 5.0
## Spike field: covers most of the radius; height follows a mountain profile.
const SPIKE_RADIUS := 4.5
const SPIKE_COUNT := 105
const PEAK_HEIGHT := 128.0
const EDGE_HEIGHT := 16.0
## Inner fraction of the field that surges at the crystal peak.
const CORE_FRACTION := 0.22
const ICE_LIGHT := Color(0.55, 0.8, 1.0)
const ICE_WHITE := Color(0.85, 0.95, 1.0)


## Frost warning rune on the ground plane: six-arm snowflake with branches, hex ring and rune ticks.
class FrostRune:
	extends Node2D

	var radius := 5.0
	var reveal := 0.0
	var alpha := 1.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		if reveal <= 0.0 or alpha <= 0.0:
			return
		var pulse := 0.75 + 0.25 * sin(_time * 7.0)
		var c := Color(0.85, 0.96, 1.0, alpha * pulse)
		var dim := Color(0.55, 0.8, 1.0, alpha * 0.7)
		var arm := radius * 0.5 * reveal
		var spin := _time * 0.25
		for i in 6:
			var d := Vector2.RIGHT.rotated(spin + TAU * i / 6.0)
			# Doubled strokes so the snowflake arms read at pixel scale.
			draw_line(Vector2.ZERO, d * arm, c, -1.0)
			draw_line(d.orthogonal() * 0.04, d * arm + d.orthogonal() * 0.04, c, -1.0)
			for k in [0.45, 0.72]:
				var base: Vector2 = d * arm * k
				var bl := arm * (0.28 if k < 0.5 else 0.2)
				draw_line(base, base + d.rotated(0.8) * bl, c, -1.0)
				draw_line(base, base + d.rotated(-0.8) * bl, c, -1.0)
			draw_rect(Rect2(d * arm - Vector2(0.06, 0.06), Vector2(0.12, 0.12)), c)
		var hex := PackedVector2Array()
		for i in 7:
			hex.append(Vector2.RIGHT.rotated(spin + TAU * i / 6.0 + PI / 6.0) * arm * 0.3)
		draw_polyline(hex, c, -1.0)
		# Outer rune ticks between two rings.
		var r_in := radius * 0.72 * reveal
		var r_out := radius * 0.84 * reveal
		draw_arc(Vector2.ZERO, r_in, 0.0, TAU, 64, dim, -1.0)
		draw_arc(Vector2.ZERO, r_out, 0.0, TAU, 64, c, -1.0)
		for i in 24:
			var a := -spin * 0.6 + TAU * i / 24.0
			var d := Vector2.RIGHT.rotated(a)
			var tick := 0.5 if i % 3 == 0 else 0.25
			draw_line(d * r_in, d * (r_in + (r_out - r_in) * tick), c, -1.0)


var _center_px := Vector2.ZERO
var _rune: FrostRune
var _rings: QuadFx
var _frost: QuadFx
var _wave: QuadFx
var _spikes: Array[IceSpike] = []
var _core_spikes: Array[IceSpike] = []
var _wind: Node
var _freeze_done := false


func _build() -> void:
	duration = 10.5
	_center_px = Iso.ground_to_screen(origin)

	_rune = FrostRune.new()
	_rune.radius = RADIUS
	_rune.position = origin
	# Above the dim layer so the rune glows while the world darkens.
	_rune.z_index = 9
	track(_rune, ctx.ground)
	create_tween().tween_property(_rune, "reveal", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_rings = FxParts.rings(self, origin, RADIUS, Color("9fdcff"), 3, 24.0)
	_rings.set_param("crosshair", 0.0)
	_rings.set_param("fill", 0.1)
	_rings.set_param("pulse", 0.6)
	_rings.z_index = 8
	var rune_light := FxParts.ground_light(self, origin, RADIUS * 0.95, ICE_LIGHT, 0.0)
	rune_light.set_param("falloff", 2.2)
	rune_light.tween_param("intensity", 0.0, 0.7, 0.9)
	rune_light.tween_param("intensity", 0.7, 0.0, 0.3, T_ERUPT)
	_rings.tween_param("reveal", 0.0, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	# Cold mist rolling in along the rim.
	var mist := FxParts.fog(self, origin, RADIUS * 1.05, Color(0.8, 0.9, 1.0, 0.5))
	mist.set_param("scale", 3.2)
	mist.tween_param("density", 0.0, 0.9, 1.0)
	mist.tween_param("fade", 1.0, 0.0, 0.6, T_ERUPT)
	var motes := FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.SNOW_LIFE, 40.0, T_ERUPT, {
		"radius": FxParts.particle_radius(RADIUS * 0.9), "alt": Vector2(0, 4), "alt_speed": Vector2(10, 30),
		"speed": Vector2(0, 8), "life": Vector2(0.6, 1.2), "size": Vector2(1, 1),
	})
	motes.drag = 0.5

	ctx.impact.dim(0.35, 1.2)
	ctx.play(&"glac_rune", origin)
	_wind = ctx.play(&"glac_wind", origin, -6.0)

	at(T_ERUPT, _erupt)
	at(T_FREEZE, _freeze)
	at(T_PEAK, _peak)
	at(T_AFTER, _aftermath)


## Place a spike at ground point g; height/width scale with closeness to center.
func _make_spike(g: Vector2, h: float, w: float, delay: float) -> IceSpike:
	var s := IceSpike.new()
	s.ground_pos = g
	s.position = Iso.ground_to_screen(g).round()
	s.height = h
	s.width = w
	var out := (Iso.ground_to_screen(g) - _center_px)
	# Lean outward more toward the rim, like crystals bursting out of the mountain's flanks.
	var k := g.distance_to(origin) / SPIKE_RADIUS
	s.angle = clampf(out.x * 0.0026, -0.5, 0.5) * (0.3 + 0.7 * k) + ctx.rng.randf_range(-0.1, 0.1)
	s.seed = ctx.rng.randf() * 100.0
	s.lights = ctx.lights
	track(s, ctx.world)
	_spikes.append(s)
	var tw := s.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(s, "grow", 1.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return s


func _erupt() -> void:
	ctx.play(&"glac_erupt", origin)
	ctx.impact.impact_frame(0.05, ctx.impact.focus_of(_center_px), Color(0.92, 0.97, 1.0), Color(0.04, 0.08, 0.2))
	ctx.impact.hitstop(0.07)
	ctx.impact.aberration(3.0, 0.4)
	ctx.shake.add_trauma(0.8)
	ctx.shake.kick(Vector2(0, -6))
	_rings.tween_param("alpha", 1.0, 0.0, 0.3)
	create_tween().tween_property(_rune, "alpha", 0.0, 0.5)

	_build_mountain()

	var burst := FxParts.particles(self, ctx.overhead, _center_px, PixelParticles.Shape.STREAK, FxParts.ICE_LIFE)
	burst.gravity = 300.0
	burst.drag = 1.2
	burst.streak_len = 0.05
	burst.burst(130, {"radius": 14.0, "speed": Vector2(90, 330), "alt": Vector2(10, 50), "alt_speed": Vector2(60, 260),
		"life": Vector2(0.5, 1.1), "size": Vector2(2, 4)})
	FxParts.debris(self, _center_px, 40, 20.0, Vector2(60, 220), FxParts.ICE_CHUNK, Vector2(2, 4.5), true)
	var light := FxParts.ground_light(self, origin, 3.4, ICE_LIGHT)
	light.tween_param("intensity", 1.4, 0.5, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	var bloom := FxParts.bloom(self, _center_px + Vector2(0, -40), 90.0, ICE_LIGHT, 1.1, 0.9)
	bloom.tween_param("intensity", 1.1, 0.0, 0.6)
	bloom.life = 0.62

	for e in ctx.field.in_radius(origin, ERUPT_KILL):
		ctx.field.kill(e, &"ice", origin)
	ctx.env.damage_radius(origin, ERUPT_KILL, 99999.0, &"ice")
	ctx.env.shake_radius(origin, RADIUS + 2.0, 2.0)


## Spikes spread evenly over the whole field (area-uniform samples with a minimum spacing) so nothing
## clumps; height and width follow a mountain profile: tallest at the center, sloping to the rim.
## They erupt from the center outward.
func _build_mountain() -> void:
	# Summit: one tall slender shard crowning the cone.
	_core_spikes.append(_make_spike(origin, PEAK_HEIGHT * 1.02, 18.0, 0.0))
	var placed: Array[Vector2] = [origin]
	var attempts := 0
	while placed.size() < SPIKE_COUNT and attempts < 4000:
		attempts += 1
		var d := SPIKE_RADIUS * sqrt(ctx.rng.randf())
		var k := d / SPIKE_RADIUS
		var g := origin + Vector2.RIGHT.rotated(ctx.rng.randf() * TAU) * d
		# Denser toward the middle so the cone reads as a solid layered mass.
		var spacing := lerpf(0.36, 0.5, k)
		var ok := true
		for q in placed:
			if q.distance_squared_to(g) < spacing * spacing:
				ok = false
				break
		if not ok:
			continue
		placed.append(g)
		# Cone profile: height falls off steadily from the summit to the rim.
		var profile := 1.0 - pow(k, 0.8)
		var h := lerpf(EDGE_HEIGHT, PEAK_HEIGHT, profile) * ctx.rng.randf_range(0.7, 1.05)
		var w := lerpf(8.0, 19.0, profile) * ctx.rng.randf_range(0.8, 1.2)
		var s := _make_spike(g, h, w, k * 0.75 + ctx.rng.randf() * 0.06)
		if k < CORE_FRACTION:
			_core_spikes.append(s)


## An enemy's ice ran out: it bursts shortly after, staggered so the field pops like a chain.
func _on_thaw(e: DummyEnemy) -> void:
	at(t + ctx.rng.randf_range(0.0, 0.45), _ice_burst.bind(e))


func _ice_burst(e: DummyEnemy) -> void:
	if not is_instance_valid(e) or not e.is_alive():
		return
	var g := e.ground_pos
	ctx.field.kill(e, &"ice", g)
	ctx.field.knock_from(g, 0.05, 1.3, 3.5)
	_ice_explosion(g, 1.0)


## Icy explosion: flash, frost ring, shards, ice chunks, crystal pops, mist and a frost patch.
func _ice_explosion(g: Vector2, size: float) -> void:
	var sp := Iso.ground_to_screen(g)
	ctx.play(&"glac_shatter", g, -3.0)
	ctx.shake.add_trauma(0.12 * size)

	var flash := FxParts.bloom(self, sp + Vector2(0, -8), 30.0 * size, ICE_LIGHT, 1.3)
	flash.tween_param("intensity", 1.3, 0.0, 0.3, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	flash.life = 0.32
	var light := FxParts.ground_light(self, g, 1.4 * size, ICE_LIGHT)
	light.tween_param("intensity", 1.2, 0.0, 0.45, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 0.47

	var ring := FxParts.shockwave(self, g, 1.25 * size, FxParts.ICE_WAVE)
	ring.z_index = 9
	ring.set_param("thickness", 0.14)
	ring.set_param("inner_heat", 0.0)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.18)
	ring.life = 0.4

	var patch := FxParts.frost_ground(self, g, 0.9 * size)
	patch.z_index = 8
	patch.tween_param("progress", 0.0, 1.0, 0.25, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	patch.tween_param("fade", 1.0, 0.0, 1.2, 0.8)
	patch.life = 2.05

	var shards := FxParts.particles(self, ctx.overhead, sp + Vector2(0, -6), PixelParticles.Shape.STREAK, FxParts.ICE_LIFE)
	shards.gravity = 320.0
	shards.drag = 1.1
	shards.streak_len = 0.05
	shards.burst(int(26 * size), {"radius": 3.0, "speed": Vector2(60, 220), "alt": Vector2(2, 14),
		"alt_speed": Vector2(40, 200), "life": Vector2(0.35, 0.8), "size": Vector2(1, 3)})
	FxParts.debris(self, sp, int(8 * size), 4.0, Vector2(30, 120), FxParts.ICE_CHUNK, Vector2(1.5, 3.0), true)
	var mist := FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, FxParts.MIST_LIFE)
	mist.drag = 1.8
	mist.burst(int(8 * size), {"radius": 5.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(20, 60),
		"alt": Vector2(0, 8), "alt_speed": Vector2(4, 20), "life": Vector2(0.6, 1.1), "size": Vector2(3, 6),
		"size_end_mul": 1.6})

	# A star of crystals bursts out radially from the enemy, like a snowflake of prisms.
	var rays := 8
	for i in rays:
		var dir_a := TAU * i / rays + ctx.rng.randf_range(-0.15, 0.15)
		var c := IceSpike.new()
		c.cluster = false
		c.style = IceSpike.Style.PRISM
		c.ground_pos = g
		c.position = (sp + Vector2(0, -8)).round()
		c.angle = dir_a
		c.height = ctx.rng.randf_range(18.0, 30.0) * size * (0.7 if absf(sin(dir_a)) < 0.4 else 1.0)
		c.width = ctx.rng.randf_range(4.5, 6.5) * size
		c.seed = ctx.rng.randf() * 100.0
		c.lights = ctx.lights
		c.glow = 1.0
		track(c, ctx.world)
		var tw := c.create_tween()
		tw.tween_property(c, "grow", 1.0, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.3)
		tw.tween_property(c, "shatter", 1.0, 0.35)
		tw.parallel().tween_property(c, "fade", 0.0, 0.45)
		tw.tween_callback(c.queue_free)


func _freeze() -> void:
	ctx.play(&"glac_freeze", origin)
	_frost = FxParts.frost_ground(self, origin, RADIUS * 1.05)
	_frost.set_param("progress", 0.0)
	_frost.z_index = 7
	_wave = FxParts.shockwave(self, origin, RADIUS * 1.05, FxParts.ICE_WAVE)
	_wave.z_index = 9
	_wave.set_param("thickness", 0.05)
	_wave.set_param("inner_heat", 0.0)
	var refract := FxParts.refract_ring(self, origin, RADIUS * 1.2, ICE_WHITE)
	refract.set_param("strength", 7.0)
	refract.tween_param("progress", 0.05, 1.0, FREEZE_TIME, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	refract.life = FREEZE_TIME + 0.02
	var spray := FxParts.particles(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.SNOW_LIFE)
	spray.drag = 1.4
	spray.burst(160, {"radius": 20.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(90, 260),
		"alt": Vector2(0, 10), "alt_speed": Vector2(10, 60), "life": Vector2(0.6, 1.2), "size": Vector2(1, 2)})
	ctx.shake.add_trauma(0.35)


func _fx_process(delta: float) -> void:
	if _wave != null and not _freeze_done:
		var k := clampf((t - T_FREEZE) / FREEZE_TIME, 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - k, 2.2)
		_wave.set_param("progress", eased)
		_wave.set_param("fade", 1.0 - smoothstep(0.8, 1.0, k))
		_frost.set_param("progress", eased)
		var r := eased * RADIUS
		ctx.field.freeze_radius(origin, r, FREEZE_SECONDS, _on_thaw)
		ctx.env.damage_radius(origin, r, 30.0 * delta, &"ice")
		if k >= 1.0:
			_freeze_done = true
			_wave.visible = false


func _peak() -> void:
	ctx.play(&"glac_peak", origin)
	ctx.impact.hitstop(0.05)
	ctx.impact.aberration(2.5, 0.5)
	ctx.flash.call(Color(0.85, 0.95, 1.0, 0.3), 0.35)
	ctx.shake.add_trauma(0.7)
	ctx.shake.kick(Vector2(0, -5))
	# The mountain surges to its full towering form.
	for s in _core_spikes:
		s.create_tween().tween_property(s, "grow", ctx.rng.randf_range(1.06, 1.18), 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		s.create_tween().tween_property(s, "glow", 1.0, 0.2)
	var rays := FxParts.screen_rays(self, _center_px + Vector2(0, -70), 210.0, ICE_WHITE, 70.0, 0.9)
	rays.tween_param("intensity", 0.9, 0.0, 1.0, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	rays.life = 1.15
	var bloom := FxParts.bloom(self, _center_px + Vector2(0, -60), 120.0, ICE_LIGHT, 0.7, 1.0)
	bloom.tween_param("intensity", 0.7, 0.3, 1.0, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	bloom.tween_param("intensity", 0.3, 0.0, 1.0, 1.3)
	bloom.life = 2.4
	var light := FxParts.ground_light(self, origin, RADIUS * 1.1, ICE_LIGHT)
	light.set_param("falloff", 1.2)
	light.tween_param("intensity", 1.5, 0.35, 1.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.tween_param("intensity", 0.35, 0.0, 2.5, 3.0)
	var shards := FxParts.particles(self, ctx.overhead, _center_px + Vector2(0, -60), PixelParticles.Shape.STREAK, FxParts.ICE_LIFE)
	shards.gravity = 280.0
	shards.drag = 1.0
	shards.burst(90, {"radius": 20.0, "speed": Vector2(80, 260), "alt": Vector2(0, 40), "alt_speed": Vector2(40, 200),
		"life": Vector2(0.6, 1.2), "size": Vector2(2, 3)})

	# Glowing white frost mist hugging the mountain's base, and shards drifting around it.
	var base_glow := FxParts.bloom(self, _center_px + Vector2(0, -6), 120.0, ICE_WHITE, 0.0, 0.42)
	base_glow.tween_param("intensity", 0.0, 0.45, 0.4)
	base_glow.tween_param("intensity", 0.45, 0.0, 1.6, duration - t - 2.2)
	var mist := FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.PUFF, FxParts.MIST_LIFE, 12.0,
		duration - t - 2.0, {
			"radius": FxParts.particle_radius(1.8), "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(10, 35),
			"alt": Vector2(0, 4), "alt_speed": Vector2(2, 8), "life": Vector2(0.8, 1.4), "size": Vector2(3, 5),
			"size_end_mul": 1.5,
		})
	mist.drag = 0.6
	var floaters := FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.STREAK, FxParts.ICE_LIFE, 18.0,
		duration - t - 2.0, {
			"radius": FxParts.particle_radius(2.6), "alt": Vector2(20, 110), "alt_speed": Vector2(6, 22),
			"speed": Vector2(2, 10), "life": Vector2(1.0, 2.0), "size": Vector2(2, 4),
		})
	floaters.streak_len = 0.25

	# Enemies inside the surging mountain burst immediately.
	for e in ctx.field.frozen_in_radius(origin, PEAK_KILL):
		var g := e.ground_pos
		ctx.field.kill(e, &"ice", origin)
		_ice_explosion(g, 0.8)
	ctx.env.damage_radius(origin, PEAK_KILL * 0.7, 99999.0, &"ice")


func _aftermath() -> void:
	ctx.impact.dim(0.2, 0.6)
	# Outer spikes crack and shatter one by one; the mountain holds until the end.
	for s in _spikes:
		if s in _core_spikes:
			continue
		var when := ctx.rng.randf_range(0.2, 3.2)
		at(t + when, _break_spike.bind(s, 0.5))
	for s in _core_spikes:
		at(t + ctx.rng.randf_range(3.4, 4.6), _break_spike.bind(s, 0.9))

	var fog := FxParts.fog(self, origin, RADIUS * 1.1, Color(0.78, 0.88, 1.0, 0.42))
	fog.set_param("scale", 2.4)
	fog.tween_param("density", 0.0, 1.0, 1.2)
	fog.tween_param("fade", 1.0, 0.0, 1.5, duration - t - 1.6)
	FxParts.emitter(self, ctx.overhead, _center_px + Vector2(0, -90), PixelParticles.Shape.SQUARE, FxParts.SNOW_LIFE, 36.0,
		duration - t - 1.0, {
			"radius": FxParts.particle_radius(RADIUS), "alt": Vector2(40, 120), "alt_speed": Vector2(-28, -12),
			"speed": Vector2(4, 14), "life": Vector2(2.0, 3.5), "size": Vector2(1, 2),
		})
	_frost.tween_param("fade", 1.0, 0.0, 1.8, duration - t - 2.0)
	for s in _spikes:
		s.create_tween().tween_property(s, "fade", 0.0, 1.2).set_delay(duration - t - 1.4)
	at(duration - 1.4, func():
		ctx.fade_out(_wind, 1.2)
		ctx.impact.dim(0.0, 0.6))


func _break_spike(s: IceSpike, seconds: float) -> void:
	if not is_instance_valid(s):
		return
	s.create_tween().tween_property(s, "shatter", 1.0, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var top := s.mid_point()
	var p := FxParts.particles(self, ctx.overhead, top, PixelParticles.Shape.CHUNK, FxParts.ICE_CHUNK)
	p.gravity = 360.0
	p.bounce = true
	p.drag = 0.8
	p.shadows = true
	p.burst(int(clampf(s.height / 6.0, 3.0, 14.0)), {"radius": s.width, "speed": Vector2(20, 90),
		"alt": Vector2(0, s.height * 0.4), "alt_speed": Vector2(10, 90), "life": Vector2(0.7, 1.4), "size": Vector2(1.5, 3.5)})
	if ctx.rng.randf() < 0.35:
		ctx.play(&"glac_shatter", s.ground_pos, -8.0)
