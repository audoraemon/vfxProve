extends FxTimeline
## Cinderfall Barrage: magma sigil and quake -> a volcano thrusts out of the ground -> the crater launches
## fire stones -> stones rain across the area -> burning craters, lava pools, smoke and embers.

const RADIUS := 5.8
const VOLCANO_RADIUS := 1.9
const VOLCANO_HEIGHT := 135.0
const T_RISE := 1.2
const RISE_TIME := 1.3
const T_ERUPT := 2.6
const T_BARRAGE := 3.3
const T_BARRAGE_END := 7.0
const T_SINK := 8.2
const STONES := 20
const STONE_KILL := 0.9
const LAVA_LIGHT := Color(1.0, 0.45, 0.15)


## Volcano cone: lava-filled silhouette covered in lit rock plates so molten light shows in the gaps.
class Volcano:
	extends Node2D

	const ROCK_DARK := Color("2a2222")
	const ROCK := Color("3e3230")
	const ROCK_LIT := Color("5e4a42")
	const LAVA_DEEP := Color("8a1a0a")
	const LAVA := Color("e8501a")
	const LAVA_HOT := Color("ffb040")
	const LAVA_WHITE := Color("fff0b8")

	var radius_px := 120.0
	var height := 130.0
	var rise := 0.0
	var heat := 1.0
	var sink := 0.0
	var lights: LightField
	var ground_pos := Vector2.ZERO
	var _plates: Array = []
	var _time := 0.0
	var _redraw_in := 0.0

	func setup(rng: RandomNumberGenerator) -> void:
		# Plates in rows up the visible front of the cone; u across (-1..1), v up (0..1).
		var rows := 12
		for r in rows:
			var v := (r + 0.1) / rows
			var count := int(lerpf(14.0, 4.0, v))
			for c in count:
				# Outer columns overhang the silhouette so the cone edge reads jagged.
				var u := ((c + 0.5) / count) * 2.2 - 1.1 + rng.randf_range(-0.05, 0.05)
				_plates.append({
					"u": u, "v": v + rng.randf_range(-0.025, 0.025), "size": lerpf(0.21, 0.1, v) * rng.randf_range(0.85, 1.25),
					"rot": rng.randf() * TAU, "seed": rng.randf() * 10.0, "tone": rng.randf(),
				})
		# Boulder apron around the base.
		for c in 16:
			var u := -1.15 + c * 2.3 / 15.0
			_plates.append({"u": u, "v": rng.randf_range(-0.04, 0.02), "size": rng.randf_range(0.14, 0.22),
				"rot": rng.randf() * TAU, "seed": rng.randf() * 10.0, "tone": rng.randf()})
		# Back-to-front: higher rows and outer plates first.
		_plates.sort_custom(func(a, b): return a.v > b.v)

	func _process(delta: float) -> void:
		_time += delta
		# Many plate polygons: redraw at ~20 Hz while static, every frame while rising or sinking.
		_redraw_in -= delta
		var moving := (rise > 0.0 and rise < 1.0) or (sink > 0.0 and sink < 1.0)
		if moving or _redraw_in <= 0.0:
			_redraw_in = 0.05
			queue_redraw()

	func _cone_point(u: float, v: float, h: float) -> Vector2:
		# Concave slopes, narrowing to the crater; front bulge sits lower on screen (iso base ellipse).
		var w := radius_px * (1.0 - pow(maxf(v, 0.0), 0.8) * 0.8)
		var x := u * w
		var y := -v * h + sqrt(maxf(1.0 - minf(u * u, 1.0), 0.0)) * w * 0.5 * (1.0 - v)
		return Vector2(x, y)

	func _draw() -> void:
		if rise <= 0.01:
			return
		var h := height * rise * (1.0 - sink)
		var amb := maxf(lights.ambient, 0.6) if lights else 1.0
		var pulse := 0.8 + 0.2 * sin(_time * 4.0)
		var lava_c := LAVA.lerp(LAVA_DEEP, 1.0 - heat) * (0.8 + 0.2 * pulse)
		var hot_c := LAVA_HOT.lerp(LAVA, 1.0 - heat)
		# Lava body silhouette.
		var sil := PackedVector2Array()
		for i in 17:
			var u := -1.0 + i / 8.0
			sil.append(_cone_point(u, 0.0, h))
		sil.append(_cone_point(0.22, 1.0, h))
		sil.append(_cone_point(-0.22, 1.0, h))
		draw_colored_polygon(sil, lava_c)
		# Molten streams running down between plates.
		for k in 5:
			var u0 := -0.6 + k * 0.3
			var prev := _cone_point(u0 * 0.2, 0.95, h)
			for s in range(1, 8):
				var v := 0.95 - s * 0.13
				var p := _cone_point(u0 * (0.2 + (1.0 - v) * 0.8) + sin(s * 1.7 + k) * 0.05, v, h)
				draw_line(prev, p, hot_c, -1.0)
				prev = p
		# Rock plates.
		var rise_v := clampf(rise * 1.2, 0.0, 1.0)
		for pl in _plates:
			if pl.v > rise_v:
				continue
			var c := _cone_point(pl.u, pl.v, h)
			var s: float = pl.size * radius_px
			var poly := PackedVector2Array()
			for k in 5:
				var a: float = pl.rot + TAU * k / 5.0
				var j := 0.7 + 0.3 * fposmod(sin(pl.seed + k * 3.1) * 43758.5, 1.0)
				poly.append(c + Vector2(cos(a), sin(a) * 0.8) * s * j)
			var shade: float = (0.7 + 0.3 * (1.0 - pl.v)) * (0.8 + 0.35 * pl.tone)
			draw_colored_polygon(poly, ROCK * amb * shade)
			# Lit upper-left facet and lava glow catching the lower edge.
			var inner := PackedVector2Array()
			for p in poly:
				inner.append(c + (p - c) * 0.55 + Vector2(-s * 0.15, -s * 0.2))
			draw_colored_polygon(inner, ROCK_LIT * amb * shade)
			var low_a: Vector2 = poly[1]
			var low_b: Vector2 = poly[2]
			draw_line(low_a.round(), low_b.round(), Color(hot_c, 0.9 * heat), -1.0)
			draw_line((poly[3] as Vector2).round(), (poly[4] as Vector2).round(), ROCK_LIT.lightened(0.15) * amb, -1.0)
		# Crater mouth.
		var top := _cone_point(0.0, 1.0, h)
		var cw := radius_px * 0.22
		draw_colored_polygon(_ellipse(top, cw, cw * 0.45), ROCK_DARK * amb)
		draw_colored_polygon(_ellipse(top + Vector2(0, 1), cw * 0.8, cw * 0.32), hot_c)
		draw_colored_polygon(_ellipse(top + Vector2(0, 1), cw * 0.45, cw * 0.18), LAVA_WHITE.lerp(LAVA, 1.0 - heat))

	func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts

	func crater_top() -> Vector2:
		return position + _cone_point(0.0, 1.0, height * rise * (1.0 - sink))


## Flaming boulder: cracked rock with molten seams and a long tail of fire.
class FireStone:
	extends Node2D

	var size := 9.0
	var dir := Vector2(0, 1)
	var seed := 0.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var back := -dir.normalized()
		var side := back.orthogonal()
		# Tapered flame tail: outer red, orange body, yellow core, flickering.
		for layer in 3:
			var width: float = size * [1.25, 0.9, 0.5][layer]
			var length: float = size * [7.0, 5.5, 3.5][layer]
			var col: Color = [Color(0.8, 0.16, 0.05, 0.75), Color(1.0, 0.45, 0.1, 0.9), Color(1.0, 0.85, 0.4, 1.0)][layer]
			var steps := 7
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			for k in steps + 1:
				var f := float(k) / steps
				var wob := sin(_time * 35.0 + k * 1.9 + layer) * size * 0.18 * f
				var mid := back * length * f + side * wob
				left.append(mid + side * width * (1.0 - f))
				right.append(mid - side * width * (1.0 - f))
			# Quad strip: never self-intersects even while the tail wobbles.
			for k in steps:
				draw_primitive(PackedVector2Array([left[k], left[k + 1], right[k + 1], right[k]]),
					PackedColorArray([col, col, col, col]), PackedVector2Array())
		var poly := PackedVector2Array()
		for k in 8:
			var a := seed + TAU * k / 8.0 + _time * 2.0
			poly.append(Vector2(cos(a), sin(a)) * size * (0.78 + 0.22 * fposmod(sin(seed + k) * 91.7, 1.0)))
		draw_colored_polygon(poly, Color("2e2220"))
		var lit := PackedVector2Array()
		for p in poly:
			lit.append(p * 0.6 + dir.normalized() * size * 0.18)
		draw_colored_polygon(lit, Color("4e3a32"))
		draw_line(poly[0], poly[4], Color("ffd070"), -1.0)
		draw_line(poly[4], poly[6], Color("ff8a2a"), -1.0)
		draw_line(poly[2], poly[5], Color("ff8a2a"), -1.0)


var _center_px := Vector2.ZERO
var _sigil: SigilRune
var _volcano: Volcano
var _plume: PixelParticles
var _lava_voice: Node
var _quake := 0.0


func _build() -> void:
	duration = 11.0
	_center_px = Iso.ground_to_screen(origin)

	_sigil = Set2Parts.sigil(self, origin, 3.2, Color("ff6a2a"), "magma")
	var outer := FxParts.rings(self, origin, RADIUS, Color("ff5a2a"), 2, 22.0)
	outer.z_index = 8
	outer.set_param("crosshair", 0.0)
	outer.set_param("fill", 0.06)
	outer.tween_param("reveal", 0.0, 1.0, 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	outer.tween_param("alpha", 1.0, 0.0, 0.6, T_BARRAGE_END)
	var cracks := FxParts.decal(self, origin, 2.8, Color("ff6a1a"), Color("ffd27a"), Color(0.08, 0.05, 0.04, 0.6))
	cracks.z_index = 7
	cracks.tween_param("heat", 0.0, 1.0, T_RISE)
	var glow := FxParts.ground_light(self, origin, 3.2, LAVA_LIGHT, 0.0)
	glow.tween_param("intensity", 0.0, 0.9, T_RISE)
	glow.tween_param("intensity", 0.9, 0.3, 2.0, T_ERUPT)
	glow.tween_param("intensity", 0.3, 0.0, 1.5, T_SINK)
	ctx.impact.dim(0.45, 1.0)
	ctx.play(&"cf_rumble", origin)
	_quake = 0.25

	at(T_RISE, _rise)
	at(T_ERUPT, _erupt)
	_schedule_barrage()
	at(T_SINK, _sink)


func _fx_process(delta: float) -> void:
	if _quake > 0.0:
		ctx.shake.add_trauma(_quake * delta * 2.0)
		ctx.env.shake_radius(origin, RADIUS, _quake * 4.0)


func _rise() -> void:
	ctx.play(&"cf_rise", origin)
	_quake = 1.0
	create_tween().tween_property(_sigil, "alpha", 0.0, 0.6)
	_volcano = Volcano.new()
	_volcano.radius_px = FxParts.PX_PER_UNIT_MAJOR * VOLCANO_RADIUS
	_volcano.height = VOLCANO_HEIGHT
	_volcano.lights = ctx.lights
	_volcano.ground_pos = origin
	_volcano.position = _center_px
	_volcano.setup(ctx.rng)
	track(_volcano, ctx.world)
	create_tween().tween_property(_volcano, "rise", 1.0, RISE_TIME).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	var ring := FxParts.shockwave(self, origin, 3.2, FxParts.DUST_RING)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.1, 1.0, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.4, 0.5)
	ring.life = 0.95
	var crater := FxParts.decal(self, origin, VOLCANO_RADIUS * 1.5, Color("ff6a1a"), Color("ffd27a"))
	crater.z_index = 1
	crater.tween_param("heat", 1.0, 0.3, 6.0)
	crater.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	# Rock tearing loose as the mountain shoulders up.
	for k in 6:
		at(t + k * 0.2, func():
			FxParts.debris(self, _center_px, 14, FxParts.PX_PER_UNIT_MAJOR * 1.6, Vector2(60, 220), FxParts.HOT_ROCK,
				Vector2(2, 5), true)
			FxParts.smoke(self, _center_px, FxParts.PX_PER_UNIT_MAJOR * 1.8, 20.0, 0.25, Vector2(10, 30), Vector2(4, 7),
				Vector2(1.0, 1.8)))
	for e in ctx.field.in_radius(origin, VOLCANO_RADIUS + 0.3):
		ctx.field.kill(e, &"stone", origin)
	ctx.field.knock_from(origin, VOLCANO_RADIUS + 0.3, VOLCANO_RADIUS + 2.0, 6.0)
	ctx.env.damage_radius(origin, VOLCANO_RADIUS + 0.3, 99999.0, &"stone")
	at(t + RISE_TIME, func(): _quake = 0.2)


func _erupt() -> void:
	ctx.play(&"cf_erupt", origin)
	ctx.impact.impact_frame(0.05, ctx.impact.focus_of(_volcano.crater_top()), Color(1.0, 0.9, 0.7), Color(0.12, 0.02, 0.0))
	ctx.impact.hitstop(0.07)
	ctx.impact.aberration(3.0, 0.4)
	ctx.flash.call(Color(1.0, 0.7, 0.35, 0.4), 0.3)
	ctx.shake.add_trauma(0.9)
	ctx.shake.kick(Vector2(0, -7))
	var top := _volcano.crater_top()
	var bloom := FxParts.bloom(self, top, 90.0, LAVA_LIGHT, 1.3, 0.9)
	bloom.tween_param("intensity", 1.3, 0.0, 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	bloom.life = 0.72
	var rays := FxParts.screen_rays(self, top, 160.0, Color(1.0, 0.75, 0.4), 60.0, 1.0)
	rays.tween_param("intensity", 1.2, 0.0, 0.7)
	rays.life = 0.72
	# Lava fountain and launched fire stones.
	var fountain := FxParts.emitter(self, ctx.overhead, top, PixelParticles.Shape.SQUARE, FxParts.FIRE_LIFE, 160.0, 1.2, {
		"radius": 6.0, "speed": Vector2(20, 110), "alt_speed": Vector2(120, 320), "life": Vector2(0.5, 1.0),
		"size": Vector2(1, 3),
	})
	fountain.gravity = 380.0
	FxParts.debris(self, top, 40, 8.0, Vector2(40, 200), FxParts.HOT_ROCK, Vector2(2, 5), true)
	for i in 6:
		var s := FireStone.new()
		s.size = ctx.rng.randf_range(12.0, 17.0)
		s.seed = ctx.rng.randf() * 10.0
		s.dir = Vector2(ctx.rng.randf_range(-0.5, 0.5), -1.0)
		s.position = top
		track(s, ctx.overhead)
		var tw := s.create_tween()
		tw.tween_property(s, "position", top + Vector2(s.dir.x * 260.0, -360.0), 0.7 + i * 0.05) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(s.queue_free)
	_plume = FxParts.smoke(self, top, 14.0, 28.0, duration - t - 2.0, Vector2(50, 110), Vector2(5, 9), Vector2(1.8, 3.0),
		Color("ff5a1a"))
	_plume.underglow_life = 0.35
	_lava_voice = ctx.play(&"cf_lava", origin, -6.0)


func _schedule_barrage() -> void:
	var placed: Array[Vector2] = []
	var misses := 0
	while placed.size() < STONES and misses < 800:
		var a := ctx.rng.randf() * TAU
		var d := lerpf(VOLCANO_RADIUS + 0.6, RADIUS, sqrt(ctx.rng.randf()))
		var g := origin + Vector2.RIGHT.rotated(a) * d
		var ok := true
		for q in placed:
			if q.distance_to(g) < 1.1:
				ok = false
				break
		if ok:
			placed.append(g)
			misses = 0
		else:
			misses += 1
	for i in placed.size():
		var when := lerpf(T_BARRAGE, T_BARRAGE_END - 0.5, float(i) / placed.size()) + ctx.rng.randf_range(-0.08, 0.08)
		at(when, _drop_stone.bind(placed[i]))


func _drop_stone(g: Vector2) -> void:
	var target := Iso.ground_to_screen(g)
	var side := signf(target.x - _center_px.x)
	if side == 0.0:
		side = 1.0
	var start := target + Vector2(-side * ctx.rng.randf_range(80, 160), -ctx.rng.randf_range(260, 320))
	var s := FireStone.new()
	s.size = ctx.rng.randf_range(10.0, 14.0)
	s.seed = ctx.rng.randf() * 10.0
	s.dir = (target - start).normalized()
	s.position = start
	track(s, ctx.overhead)
	if ctx.rng.randf() < 0.5:
		ctx.play(&"cf_fall", g, -8.0)
	var fall := 0.45
	var tw := s.create_tween()
	tw.tween_property(s, "position", target, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		s.queue_free()
		_stone_impact(g))
	var trail := FxParts.emitter(self, ctx.overhead_back, Vector2.ZERO, PixelParticles.Shape.PUFF, FxParts.SMOKE_LIFE, 40.0, fall, {
		"radius": 3.0, "speed": Vector2(2, 10), "alt_speed": Vector2(4, 14), "life": Vector2(0.6, 1.1),
		"size": Vector2(2, 4), "size_end_mul": 2.0,
	})
	var follow := create_tween()
	follow.tween_method(func(k): trail.spec["offset"] = start.lerp(target, k * k), 0.0, 1.0, fall)


func _stone_impact(g: Vector2) -> void:
	var sp := Iso.ground_to_screen(g)
	ctx.play(&"cf_impact", g, -2.0)
	ctx.shake.add_trauma(0.22)
	var ball := FxParts.dome(self, sp, FxParts.PX_PER_UNIT_MAJOR * 0.75)
	ball.set_param("detail", 0.8)
	ball.tween_param("grow", 0.2, 1.0, 0.14, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ball.tween_param("heat", 1.2, 0.5, 0.5)
	ball.tween_param("soot", 0.0, 0.5, 0.5, 0.1)
	ball.tween_param("dissolve", 0.0, 1.0, 0.4, 0.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	ball.life = 0.62
	var ring := FxParts.shockwave(self, g, 1.4, FxParts.FIRE)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.15)
	ring.life = 0.4
	var light := FxParts.ground_light(self, g, 1.8, LAVA_LIGHT)
	# Short-lived: every live light is sampled by each enemy and building per frame.
	light.tween_param("intensity", 1.3, 0.0, 1.0, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 1.05
	# Lava splash puddle that keeps glowing.
	var pool := FxParts.decal(self, g, 0.85, Color("ff7a1a"), Color("ffe08a"), Color(0.1, 0.04, 0.03, 0.7))
	pool.tween_param("heat", 1.0, 0.45, 3.0)
	pool.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	FxParts.debris(self, sp, 14, 4.0, Vector2(40, 160), FxParts.HOT_ROCK, Vector2(1.5, 3.5), true)
	FxParts.sparks(self, ctx.overhead, sp, 22, FxParts.FIRE_LIFE, Vector2(70, 240), Vector2(40, 220))
	FxParts.smoke(self, sp, 6.0, 7.0, duration - t - 2.5, Vector2(14, 32), Vector2(3, 5), Vector2(1.2, 2.0))
	FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 10.0, ctx.rng.randf_range(2.0, 3.5), {
		"radius": 5.0, "speed": Vector2(0, 6), "alt_speed": Vector2(16, 40), "life": Vector2(0.3, 0.6),
		"size": Vector2(1.5, 3.0), "size_end_mul": 0.3,
	})
	for e in ctx.field.in_radius(g, STONE_KILL):
		ctx.field.kill(e, &"cinder", g)
	ctx.field.knock_from(g, STONE_KILL, 1.8, 4.5)
	ctx.env.damage_radius(g, 1.1, 70.0, &"cinder")


func _sink() -> void:
	_quake = 0.3
	ctx.play(&"cf_rise", origin, -8.0)
	create_tween().tween_property(_volcano, "heat", 0.3, 1.2)
	var tw := create_tween()
	tw.tween_property(_volcano, "sink", 1.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _quake = 0.0)
	FxParts.smoke(self, _center_px, FxParts.PX_PER_UNIT_MAJOR * 1.5, 18.0, 1.6, Vector2(15, 40), Vector2(5, 8), Vector2(1.2, 2.2))
	var haze := FxParts.heat_haze(self, _center_px, 110.0, 1.6)
	haze.tween_param("strength", 1.6, 0.0, 1.5, 1.2)
	haze.life = 2.8
	FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 30.0, duration - t - 0.6, {
		"radius": FxParts.particle_radius(RADIUS * 0.8), "alt": Vector2(0, 6), "alt_speed": Vector2(12, 40),
		"speed": Vector2(0, 10), "life": Vector2(0.6, 1.4), "size": Vector2(1, 1),
	})
	at(duration - 1.3, func():
		ctx.fade_out(_lava_voice, 1.2)
		ctx.impact.dim(0.0, 0.6))
