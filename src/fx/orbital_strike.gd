extends FxTimeline
## Orbital Strike: zone telegraph -> per-point lock-on -> beam salvo -> ionized aftermath.

const RADIUS := 4.5
## Poisson-disc spacing: strikes blanket the whole zone without clumping.
const SPACING := 1.2
const MAX_STRIKES := 34
const T_SALVO_START := 1.0
const T_SALVO_END := 5.0
const AIM_TIME := 0.45
const KILL_R := 1.05
const KNOCK_R := 1.9
const T_AFTERMATH := 5.6
const FIRE_LIGHT := Color(1.0, 0.55, 0.2)
const HOT_LIGHT := Color(1.0, 0.8, 0.5)


## Blinking target pips on the ground plane (ground units).
class Pips:
	extends Node2D

	var points := PackedVector2Array()
	var alpha := 1.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var on := fmod(_time * 6.0, 1.0) < 0.65
		var col := Color(1.0, 0.35, 0.25, alpha if on else alpha * 0.45)
		for p in points:
			draw_line(p + Vector2(-0.16, 0), p + Vector2(0.16, 0), col, -1.0)
			draw_line(p + Vector2(0, -0.16), p + Vector2(0, 0.16), col, -1.0)
			draw_rect(Rect2(p - Vector2(0.04, 0.04), Vector2(0.08, 0.08)), Color(1, 0.85, 0.8, col.a))


var _rings: QuadFx
var _pips: Pips
var _points: Array[Vector2] = []
var _tilts: Array[float] = []
var _embers_voice: Node
var _first_hit := true


func _build() -> void:
	duration = 8.4
	_rings = FxParts.rings(self, origin, RADIUS, Color("e8321f"), 3, 16.0)
	_rings.tween_param("reveal", 0.0, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_rings.tween_param("alpha", 1.0, 0.45, 0.3, T_SALVO_START)
	# Darken the battlefield under the bombardment so every beam reads hot.
	at(T_SALVO_START - 0.3, func(): ctx.impact.dim(0.35, 0.8))
	ctx.play(&"orb_target", origin)

	_points = _sample_points()
	_points.shuffle()

	_pips = Pips.new()
	_pips.z_index = 4
	for p in _points:
		_pips.points.append(p)
	track(_pips, ctx.ground)
	at(T_SALVO_START + 0.2, func(): create_tween().tween_property(_pips, "alpha", 0.0, 0.4))

	# Strikes land in bursts of 1-3 across the salvo window.
	var i := 0
	var ts := T_SALVO_START
	var gap := (T_SALVO_END - AIM_TIME - T_SALVO_START) / float(_points.size()) * 2.0
	while i < _points.size():
		var group := mini(ctx.rng.randi_range(1, 3), _points.size() - i)
		for g in group:
			_tilts.append(ctx.rng.randf_range(-0.14, 0.14))
			var jitter := ctx.rng.randf_range(0.0, 0.07)
			at(ts + jitter, _aim.bind(i))
			at(ts + jitter + AIM_TIME, _strike.bind(i))
			i += 1
		ts += gap * ctx.rng.randf_range(0.7, 1.3)

	at(T_AFTERMATH, _aftermath)


func _random_in_disc(r: float) -> Vector2:
	return origin + Vector2.RIGHT.rotated(ctx.rng.randf() * TAU) * r * sqrt(ctx.rng.randf())


## Dart-throwing Poisson disc: accept a candidate only if it keeps SPACING from all others.
func _sample_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var misses := 0
	while out.size() < MAX_STRIKES and misses < 600:
		var p := _random_in_disc(RADIUS * 0.96)
		var ok := true
		for q in out:
			if p.distance_to(q) < SPACING:
				ok = false
				break
		if ok:
			out.append(p)
			misses = 0
		else:
			misses += 1
	return out


func _aim(i: int) -> void:
	var p := _points[i]
	var sp := Iso.ground_to_screen(p)
	var reticle := FxParts.rings(self, p, 0.8, Color("ff5a3a"), 2, 6.0)
	reticle.set_param("scan", 0.0)
	reticle.set_param("fill", 0.25)
	reticle.tween_param("reveal", 0.2, 1.0, 0.18, 0.0, Tween.TRANS_BACK, Tween.EASE_OUT)
	reticle.life = AIM_TIME + 0.12

	var aim := FxParts.beam(self, ctx.overhead, sp, 4.0, 400.0, FxParts.FIRE)
	aim.rotation = _tilts[i]
	aim.set_param("band_speed", 14.0)
	aim.tween_param("intensity", 0.15, 0.55, AIM_TIME, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	aim.life = AIM_TIME
	ctx.play(&"orb_charge", p, -3.0)


func _strike(i: int) -> void:
	var p := _points[i]
	var sp := Iso.ground_to_screen(p)
	ctx.shake.add_trauma(0.26)
	ctx.shake.kick(Vector2.RIGHT.rotated(ctx.rng.randf() * TAU) * 3.0 + Vector2(0, 2))
	ctx.impact.aberration(1.6, 0.15)
	if _first_hit:
		_first_hit = false
		ctx.impact.hitstop(0.05)
	ctx.play(&"orb_hit", p)

	var column := FxParts.beam(self, ctx.overhead, sp, 20.0, 420.0, FxParts.FIRE)
	column.rotation = _tilts[i]
	column.set_param("band_speed", 20.0)
	column.tween_param("intensity", 1.0, 0.0, 0.34, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	column.life = 0.36
	var halo := FxParts.bloom(self, sp + Vector2(0, -12), 42.0, FIRE_LIGHT, 1.1, 0.8)
	halo.tween_param("intensity", 1.1, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	halo.life = 0.52

	var light := FxParts.ground_light(self, p, 2.0, FIRE_LIGHT)
	light.tween_param("intensity", 1.5, 0.0, 0.9, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 0.92
	var rays := FxParts.ground_rays(self, p, 2.2, HOT_LIGHT, 40.0)
	rays.tween_param("reach", 0.3, 1.0, 0.25, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	rays.tween_param("intensity", 1.2, 0.0, 0.4, 0.15)
	rays.life = 0.56

	var refract := FxParts.refract_ring(self, p, 2.0, Color(1.0, 0.8, 0.55))
	refract.set_param("strength", 6.0)
	refract.tween_param("progress", 0.1, 1.0, 0.35, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	refract.life = 0.37

	var ring := FxParts.shockwave(self, p, 1.5, FxParts.FIRE)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.15)
	ring.life = 0.4

	var ball := FxParts.dome(self, sp, FxParts.PX_PER_UNIT_MAJOR * 0.95)
	ball.tween_param("grow", 0.2, 1.0, 0.14, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ball.tween_param("heat", 1.2, 0.5, 0.55)
	ball.tween_param("dissolve", 0.0, 1.0, 0.4, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	ball.tween_param("soot", 0.0, 0.55, 0.5, 0.1)
	ball.life = 0.65

	var crater := FxParts.decal(self, p, 1.1)
	crater.tween_param("heat", 1.0, 0.0, 3.2)
	crater.tween_param("fade", 1.0, 0.0, 1.0, maxf(duration - t - 1.1, 0.0))

	var haze := FxParts.heat_haze(self, sp, 40.0, 1.5)
	haze.tween_param("strength", 1.5, 0.0, 1.0, 0.3)
	haze.life = 1.35

	FxParts.debris(self, sp, 16, 8.0, Vector2(50, 200), FxParts.HOT_ROCK, Vector2(1.5, 4.0), true)
	FxParts.sparks(self, ctx.overhead, sp, 26, FxParts.FIRE_LIFE, Vector2(80, 280), Vector2(30, 240))
	FxParts.smoke(self, sp, 8.0, 20.0, 0.8, Vector2(22, 60), Vector2(3, 6), Vector2(1.1, 2.0), Color("ff7a2a"))

	for e in ctx.field.in_radius(p, KILL_R):
		ctx.field.kill(e, &"orbital", p)
	ctx.field.knock_from(p, KILL_R, KNOCK_R, 4.5)


func _aftermath() -> void:
	_rings.tween_param("alpha", 0.45, 0.0, 0.5)
	ctx.impact.dim(0.0, 0.5)
	_embers_voice = ctx.play(&"orb_embers", origin, -6.0)
	at(duration - 0.9, func(): ctx.fade_out(_embers_voice, 0.8))

	var haze := FxParts.heat_haze(self, Iso.ground_to_screen(origin), FxParts.PX_PER_UNIT_MAJOR * RADIUS, 1.2)
	haze.tween_param("strength", 1.2, 0.0, 1.5, 1.0)
	haze.life = 2.6

	for n in 9:
		var p: Vector2 = _points[ctx.rng.randi() % _points.size()]
		var sp := Iso.ground_to_screen(p)
		var ion := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, FxParts.ION_LIFE, 30.0, 2.2, {
			"radius": 14.0, "speed": Vector2(60, 160), "alt": Vector2(0, 10), "alt_speed": Vector2(-30, 60),
			"life": Vector2(0.12, 0.3), "size": Vector2(2, 4),
		})
		ion.drag = 2.0
		ion.streak_len = 0.06
		FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.ION_LIFE, 12.0, 2.2, {
			"radius": 12.0, "alt": Vector2(0, 12), "alt_speed": Vector2(-5, 15), "life": Vector2(0.15, 0.4),
			"size": Vector2(1, 2),
		})
		var ion_light := FxParts.ground_light(self, p, 0.9, Color(0.3, 0.6, 1.0), 0.6)
		ion_light.set_param("flicker", 1.0)
		ion_light.tween_param("intensity", 0.6, 0.0, 0.6, 1.6)
		ion_light.life = 2.3
		FxParts.smoke(self, sp, 7.0, 10.0, 1.8, Vector2(12, 30), Vector2(3, 6), Vector2(1.2, 2.0))
	FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 36.0, 2.2, {
		"radius": FxParts.particle_radius(RADIUS * 0.9), "alt": Vector2(0, 6), "alt_speed": Vector2(10, 35),
		"speed": Vector2(0, 10), "life": Vector2(0.5, 1.3), "size": Vector2(1, 1),
	})
