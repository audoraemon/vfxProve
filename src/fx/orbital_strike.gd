extends FxTimeline
## Orbital Strike: zone telegraph -> per-point lock-on -> beam salvo -> ionized aftermath.

const RADIUS := 4.5
const STRIKES := 12
const MIN_SPACING := 0.8
const T_SALVO_START := 1.0
const T_SALVO_END := 4.1
const AIM_TIME := 0.4
const KILL_R := 1.0
const KNOCK_R := 1.8
const T_AFTERMATH := 4.6


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


func _build() -> void:
	duration = 7.0
	_rings = FxParts.rings(self, origin, RADIUS, Color("ff3a2a"), 3, 16.0)
	_rings.tween_param("reveal", 0.0, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_rings.tween_param("alpha", 1.0, 0.4, 0.3, T_SALVO_START)
	ctx.play(&"orb_target", origin)

	_pips = Pips.new()
	_pips.z_index = 4
	for i in 10:
		_pips.points.append(_random_in_disc(RADIUS * 0.9))
	track(_pips, ctx.ground)
	at(T_SALVO_START, func(): create_tween().tween_property(_pips, "alpha", 0.0, 0.3))

	_points = _sample_points()
	var order := range(STRIKES)
	for i in STRIKES:
		_tilts.append(ctx.rng.randf_range(-0.14, 0.14))
		var ts := lerpf(T_SALVO_START, T_SALVO_END - AIM_TIME, float(i) / (STRIKES - 1))
		ts += ctx.rng.randf_range(-0.15, 0.15)
		at(ts, _aim.bind(order[i]))
		at(ts + AIM_TIME, _strike.bind(order[i]))

	at(T_AFTERMATH, _aftermath)


func _random_in_disc(r: float) -> Vector2:
	return origin + Vector2.RIGHT.rotated(ctx.rng.randf() * TAU) * r * sqrt(ctx.rng.randf())


func _sample_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var attempts := 0
	while out.size() < STRIKES:
		var p := _random_in_disc(RADIUS * 0.92)
		attempts += 1
		var ok := true
		for q in out:
			if p.distance_to(q) < MIN_SPACING:
				ok = false
				break
		if ok or attempts > 400:
			out.append(p)
	return out


func _aim(i: int) -> void:
	var p := _points[i]
	var sp := Iso.ground_to_screen(p)
	var reticle := FxParts.rings(self, p, 0.8, Color("ff5a3a"), 2, 6.0)
	reticle.set_param("scan", 0.0)
	reticle.set_param("fill", 0.25)
	reticle.tween_param("reveal", 0.2, 1.0, 0.18, 0.0, Tween.TRANS_BACK, Tween.EASE_OUT)
	reticle.life = AIM_TIME + 0.12

	var aim := FxParts.beam(self, ctx.overhead, sp, 4.0, 380.0, FxParts.FIRE)
	aim.rotation = _tilts[i]
	aim.set_param("band_speed", 14.0)
	aim.tween_param("intensity", 0.15, 0.5, AIM_TIME, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	aim.life = AIM_TIME
	ctx.play(&"orb_charge", p, -3.0)


func _strike(i: int) -> void:
	var p := _points[i]
	var sp := Iso.ground_to_screen(p)
	ctx.shake.add_trauma(0.32)
	ctx.play(&"orb_hit", p)

	var column := FxParts.beam(self, ctx.overhead, sp, 18.0, 420.0, FxParts.FIRE)
	column.rotation = _tilts[i]
	column.set_param("band_speed", 20.0)
	column.tween_param("intensity", 1.0, 0.0, 0.32, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	column.life = 0.34

	var ring := FxParts.shockwave(self, p, 1.4, FxParts.FIRE)
	ring.set_param("thickness", 0.18)
	ring.tween_param("progress", 0.05, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.15)
	ring.life = 0.4

	var ball := FxParts.dome(self, sp, FxParts.PX_PER_UNIT_MAJOR * 0.85)
	ball.tween_param("grow", 0.2, 1.0, 0.12, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ball.tween_param("heat", 1.3, 0.5, 0.5)
	ball.tween_param("dissolve", 0.0, 1.0, 0.35, 0.18, Tween.TRANS_QUAD, Tween.EASE_IN)
	ball.life = 0.6

	var crater := FxParts.decal(self, p, 1.05)
	crater.tween_param("heat", 1.0, 0.0, 3.0)
	crater.tween_param("fade", 1.0, 0.0, 1.0, maxf(duration - t - 1.1, 0.0))

	FxParts.debris(self, sp, 28, 6.0, Vector2(30, 160), FxParts.HOT_ROCK)
	FxParts.sparks(self, ctx.overhead, sp, 30, FxParts.FIRE_LIFE, Vector2(80, 260), Vector2(30, 220))
	FxParts.smoke(self, sp, 8.0, 22.0, 0.7, Vector2(20, 55), Vector2(3, 5), Vector2(0.9, 1.7))

	for e in ctx.field.in_radius(p, KILL_R):
		ctx.field.kill(e, &"orbital")
	ctx.field.knock_from(p, KILL_R, KNOCK_R, 4.5)


func _aftermath() -> void:
	_rings.tween_param("alpha", 0.4, 0.0, 0.5)
	_embers_voice = ctx.play(&"orb_embers", origin, -6.0)
	at(duration - 0.9, func(): ctx.fade_out(_embers_voice, 0.8))

	for n in 6:
		var p: Vector2 = _points[ctx.rng.randi() % _points.size()]
		var sp := Iso.ground_to_screen(p)
		var ion := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, FxParts.ION_LIFE, 30.0, 2.0, {
			"radius": 14.0, "speed": Vector2(60, 160), "alt": Vector2(0, 10), "alt_speed": Vector2(-30, 60),
			"life": Vector2(0.12, 0.3), "size": Vector2(2, 4),
		})
		ion.drag = 2.0
		ion.streak_len = 0.06
		FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.ION_LIFE, 12.0, 2.0, {
			"radius": 12.0, "alt": Vector2(0, 12), "alt_speed": Vector2(-5, 15), "life": Vector2(0.15, 0.4),
			"size": Vector2(1, 2),
		})
		FxParts.smoke(self, sp, 6.0, 10.0, 1.6, Vector2(12, 30), Vector2(3, 5), Vector2(1.0, 1.8))
	FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 28.0, 2.0, {
		"radius": FxParts.particle_radius(RADIUS * 0.85), "alt": Vector2(0, 6), "alt_speed": Vector2(10, 35),
		"speed": Vector2(0, 10), "life": Vector2(0.5, 1.3), "size": Vector2(1, 1),
	})
