extends FxTimeline
## Heaven Splitter: line marker + storm sigil charge -> colossal sky lightning column (line nuke) ->
## 8 fissures crack outward -> lightning erupts from the fissures -> scorched glowing cracks, static arcs.

const LINE_LENGTH := 10.0
const LINE_HALF_WIDTH := 0.7
const CORE_KILL := 1.6
const FISSURES := 8
const FISSURE_LENGTH := 5.4
const T_STRIKE := 1.4
const T_FISSURE := 2.0
const FISSURE_GROW := 0.8
const T_ERUPT := 2.9
const T_AFTER := 4.3
const STORM_LIGHT := Color(0.45, 0.65, 1.0)
const CRACK_LIGHT := Color(1.0, 0.6, 0.25)


## Eight jagged fissures on the ground plane: dark rift, molten orange glow, white-hot core while fresh.
class Fissures:
	extends Node2D

	var paths: Array[PackedVector2Array] = []
	var progress := 0.0
	var heat := 1.0
	var charge := 0.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _band(a: Vector2, b: Vector2, n: Vector2, half: float, col: Color) -> void:
		if col.a <= 0.01:
			return
		draw_primitive(PackedVector2Array([a + n * half, b + n * half, b - n * half, a - n * half]),
			PackedColorArray([col, col, col, col]), PackedVector2Array())

	func _draw() -> void:
		if progress <= 0.0:
			return
		for path in paths:
			var total := path.size() - 1
			var reach := progress * total
			for i in total:
				if i >= reach:
					break
				var a := path[i]
				var b := path[i + 1]
				if i + 1 > reach:
					b = a.lerp(b, reach - i)
				var n := (b - a).orthogonal().normalized()
				var taper := 1.0 - float(i) / total * 0.65
				var flick := 0.85 + 0.15 * sin(_time * 20.0 + i * 1.7)
				# Filled bands: wide soft glow, dark rift, molten fill, white-hot core line.
				_band(a, b, n, 0.34 * taper, Color(1.0, 0.42, 0.1, 0.28 * heat * flick))
				_band(a, b, n, 0.17 * taper, Color(0.07, 0.04, 0.04, 0.92))
				_band(a, b, n, 0.1 * taper, Color(1.0, 0.55, 0.15, heat * flick))
				_band(a, b, n, 0.045 * taper, Color(1.0, 0.85, 0.45, clampf(heat * 1.2, 0.0, 1.0)))
				draw_line(a, b, Color(1.0, 0.97, 0.85, clampf(heat * 1.4 - 0.4, 0.0, 1.0)), -1.0)
				if charge > 0.0 and int(_time * 18.0 + i) % 4 == 0:
					draw_line(a, b, Color(0.7, 0.85, 1.0, charge), -1.0)


var _center_px := Vector2.ZERO
var _dir := Vector2(1, 0)
var _sigil: SigilRune
var _lane: LanePath
var _fissures: Fissures
var _static_voice: Node
var _arc_timer := 0.0


func _build() -> void:
	duration = 8.5
	_center_px = Iso.ground_to_screen(origin)
	_dir = (extra.get("dir", Vector2(1, 0)) as Vector2).normalized()

	_lane = Set2Parts.lane(self, origin - _dir * LINE_LENGTH * 0.5, _dir, LINE_LENGTH, LINE_HALF_WIDTH * 2.0,
		Color("6aa8ff"), "storm")
	_sigil = Set2Parts.sigil(self, origin, 1.9, Color("6aa8ff"), "storm")
	var glow := FxParts.ground_light(self, origin, 2.6, STORM_LIGHT, 0.0)
	glow.tween_param("intensity", 0.0, 0.8, T_STRIKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	glow.life = T_STRIKE + 0.05
	ctx.impact.dim(0.55, 1.0)
	ctx.play(&"hs_charge", origin)

	# Storm charge: sparks spiralling up out of the sigil, small arcs leaping skyward.
	var motes := FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.STREAK, Set2Parts.STORM_LIFE,
		60.0, T_STRIKE, {
			"radius": FxParts.particle_radius(1.6), "alt": Vector2(0, 6), "alt_speed": Vector2(60, 160),
			"speed": Vector2(0, 10), "life": Vector2(0.3, 0.6), "size": Vector2(1, 3),
		})
	motes.streak_len = 0.05
	for k in 7:
		at(0.35 + k * 0.14, func():
			var off := Vector2(ctx.rng.randf_range(-40, 40), ctx.rng.randf_range(-6, 10))
			Set2Parts.bolt(self, ctx.overhead, _center_px + off, _center_px + off * 0.3 + Vector2(0, -ctx.rng.randf_range(60, 130)),
				0.12, 0.0, 1))

	at(T_STRIKE, _strike)
	at(T_FISSURE, _open_fissures)
	at(T_AFTER, _aftermath)


func _strike() -> void:
	ctx.play(&"hs_strike", origin)
	ctx.impact.impact_frame(0.06, ctx.impact.focus_of(_center_px), Color(0.9, 0.95, 1.0), Color(0.03, 0.05, 0.18))
	ctx.impact.hitstop(0.1)
	ctx.impact.aberration(4.0, 0.5)
	ctx.impact.dim(0.35, 1.5)
	ctx.flash.call(Color(0.8, 0.9, 1.0, 0.55), 0.35)
	ctx.shake.add_trauma(1.0)
	ctx.shake.kick(Vector2(0, 9))
	create_tween().tween_property(_sigil, "alpha", 0.0, 0.3)
	create_tween().tween_property(_lane, "alpha", 0.0, 0.5)

	# Colossal sky column: additive halo, beam core and several thick bolts.
	Set2Parts.glow_column(self, _center_px, 90.0, 420.0, STORM_LIGHT, 1.3, 0.7)
	var core := FxParts.beam(self, ctx.overhead, _center_px, 26.0, 420.0, Set2Parts.STORM)
	core.set_param("taper", 0.0)
	core.tween_param("intensity", 1.0, 0.0, 0.55, 0.05, Tween.TRANS_QUAD, Tween.EASE_IN)
	core.life = 0.62
	for i in 4:
		var top := _center_px + Vector2(ctx.rng.randf_range(-50, 50), -380)
		Set2Parts.bolt(self, ctx.overhead, top, _center_px + Vector2(ctx.rng.randf_range(-8, 8), 0), 0.35, 2.0 if i == 0 else 1.0, 3)
	var bloom := FxParts.bloom(self, _center_px + Vector2(0, -20), 120.0, STORM_LIGHT, 1.3, 0.8)
	bloom.tween_param("intensity", 1.3, 0.0, 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	bloom.life = 0.72
	var rays := FxParts.ground_rays(self, origin, 4.0, Color(0.7, 0.85, 1.0), 90.0)
	rays.tween_param("intensity", 1.3, 0.0, 0.7)
	rays.life = 0.72
	var light := FxParts.ground_light(self, origin, 4.5, STORM_LIGHT)
	light.tween_param("intensity", 1.6, 0.0, 1.2, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 1.25
	var wave := FxParts.shockwave(self, origin, 3.0, Set2Parts.STORM)
	wave.z_index = 9
	wave.set_param("thickness", 0.1)
	wave.tween_param("progress", 0.05, 1.0, 0.4, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.25, 0.25)
	wave.life = 0.52
	var crater := FxParts.decal(self, origin, 1.7, Color("5aa8ff"), Color("e8f4ff"))
	crater.tween_param("heat", 1.0, 0.2, 1.5)
	crater.tween_param("fade", 1.0, 0.0, 1.0, duration - t - 1.1)
	FxParts.debris(self, _center_px, 60, 12.0, Vector2(80, 300), FxParts.ROCK, Vector2(2, 5), true)
	FxParts.sparks(self, ctx.overhead, _center_px, 90, Set2Parts.STORM_LIFE, Vector2(120, 380), Vector2(40, 300))
	FxParts.smoke(self, _center_px, 20.0, 30.0, 0.6, Vector2(20, 60), Vector2(4, 7), Vector2(1.0, 1.8))

	for e in ctx.field.in_radius(origin, CORE_KILL):
		ctx.field.kill(e, &"lightning", origin)
	ctx.env.damage_radius(origin, CORE_KILL, 99999.0, &"lightning")
	ctx.env.shake_radius(origin, 6.0, 2.0)

	# Line nuke: lightning crawls along the marked line in both directions.
	for sgn in [-1.0, 1.0]:
		var steps := 5
		for k in steps:
			var g0: Vector2 = origin + _dir * sgn * (LINE_LENGTH * 0.5) * k / steps
			var g1: Vector2 = origin + _dir * sgn * (LINE_LENGTH * 0.5) * (k + 1) / steps
			at(t + 0.04 + k * 0.05, _line_segment.bind(g0, g1))


func _line_segment(g0: Vector2, g1: Vector2) -> void:
	Set2Parts.bolt(self, ctx.overhead, Iso.ground_to_screen(g0) + Vector2(0, -3), Iso.ground_to_screen(g1) + Vector2(0, -3),
		0.3, 1.0, 1)
	FxParts.sparks(self, ctx.overhead, Iso.ground_to_screen(g1), 10, Set2Parts.STORM_LIFE, Vector2(40, 150), Vector2(30, 120))
	var along_min := (g0 - origin).dot(_dir)
	var along_max := (g1 - origin).dot(_dir)
	for e in ctx.field.in_lane(origin, _dir, LINE_HALF_WIDTH, minf(along_min, along_max) - 0.2, maxf(along_min, along_max) + 0.2):
		ctx.field.kill(e, &"lightning", e.ground_pos - _dir.orthogonal())
	ctx.env.damage_lane(origin, _dir, LINE_HALF_WIDTH, minf(along_min, along_max), maxf(along_min, along_max), &"lightning")


func _open_fissures() -> void:
	ctx.play(&"hs_fissure", origin)
	ctx.shake.add_trauma(0.5)
	_fissures = Fissures.new()
	_fissures.position = origin
	_fissures.z_index = 8
	var base_angle := _dir.angle()
	for i in FISSURES:
		var a := base_angle + TAU * i / FISSURES + ctx.rng.randf_range(-0.12, 0.12)
		var path := PackedVector2Array([Vector2.ZERO])
		var p := Vector2.ZERO
		var heading := a
		var segs := 12
		for k in segs:
			heading += ctx.rng.randf_range(-0.35, 0.35)
			heading = lerp_angle(heading, a, 0.35)
			p += Vector2.RIGHT.rotated(heading) * FISSURE_LENGTH / segs
			path.append(p)
		_fissures.paths.append(path)
	track(_fissures, ctx.ground)
	create_tween().tween_property(_fissures, "progress", 1.0, FISSURE_GROW).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Rock bursting out along the opening cracks.
	for i in FISSURES:
		for k in 3:
			var frac := (k + 1) / 4.0
			at(t + FISSURE_GROW * frac * 0.8, func():
				var g := origin + _fissures.paths[i][int(frac * 12)]
				FxParts.debris(self, Iso.ground_to_screen(g), 6, 3.0, Vector2(20, 90), FxParts.ROCK, Vector2(1.5, 3.0), true))
	for i in FISSURES:
		var mid := origin + _fissures.paths[i][6]
		var l := FxParts.ground_light(self, mid, 2.0, CRACK_LIGHT, 0.0)
		l.tween_param("intensity", 0.0, 0.7, FISSURE_GROW)
		l.tween_param("intensity", 0.7, 0.0, 2.5, duration - T_FISSURE - 2.6)
	# Eruption points along each fissure, rippling outward.
	for i in FISSURES:
		for k in 3:
			var idx := 4 + k * 4
			at(T_ERUPT + k * 0.28 + i * 0.03 + ctx.rng.randf_range(0.0, 0.08), _erupt.bind(i, idx))


func _erupt(i: int, idx: int) -> void:
	var path: PackedVector2Array = _fissures.paths[i]
	var g := origin + path[idx]
	var sp := Iso.ground_to_screen(g)
	if idx == 4:
		ctx.play(&"hs_erupt", g, -2.0)
		ctx.shake.add_trauma(0.18)
	_fissures.charge = 1.0
	var h := ctx.rng.randf_range(110.0, 190.0)
	Set2Parts.bolt(self, ctx.overhead, sp, sp + Vector2(ctx.rng.randf_range(-25, 25), -h), 0.3, 1.0, 3)
	Set2Parts.glow_column(self, sp, 30.0, h, STORM_LIGHT, 1.1, 0.35)
	var flash := FxParts.bloom(self, sp + Vector2(0, -6), 26.0, STORM_LIGHT, 1.2, 0.8)
	flash.tween_param("intensity", 1.2, 0.0, 0.3)
	flash.life = 0.32
	var light := FxParts.ground_light(self, g, 1.6, STORM_LIGHT)
	light.tween_param("intensity", 1.3, 0.0, 0.4)
	light.life = 0.42
	FxParts.debris(self, sp, 10, 4.0, Vector2(40, 160), FxParts.ROCK, Vector2(1.5, 3.5), true)
	FxParts.sparks(self, ctx.overhead, sp, 16, Set2Parts.STORM_LIFE, Vector2(50, 200), Vector2(40, 220))
	var a := origin + path[maxi(idx - 4, 0)]
	for e in ctx.field.alive():
		if e.ground_pos.distance_to(g) < 0.9 or Set2Parts.dist_to_segment(e.ground_pos, a, g) < 0.5:
			ctx.field.kill(e, &"lightning", g)
	ctx.env.damage_radius(g, 1.0, 60.0, &"lightning")


func _aftermath() -> void:
	ctx.impact.dim(0.15, 0.6)
	_static_voice = ctx.play(&"hs_static", origin, -8.0)
	ctx.play(&"hs_rumble", origin, -4.0)
	create_tween().tween_property(_fissures, "heat", 0.25, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	create_tween().tween_property(_fissures, "charge", 0.0, 1.0)
	var fade_at := duration - T_AFTER - 1.2
	var tw := create_tween()
	tw.tween_interval(fade_at)
	tw.tween_property(_fissures, "heat", 0.0, 1.0)
	for i in FISSURES:
		var g := origin + _fissures.paths[i][ctx.rng.randi_range(3, 10)]
		FxParts.smoke(self, Iso.ground_to_screen(g), 6.0, 5.0, 2.8, Vector2(12, 30), Vector2(3, 5), Vector2(1.2, 2.0))
	FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 20.0, 2.5, {
		"radius": FxParts.particle_radius(3.5), "alt": Vector2(0, 6), "alt_speed": Vector2(10, 35),
		"speed": Vector2(0, 8), "life": Vector2(0.6, 1.3), "size": Vector2(1, 1),
	})
	at(duration - 1.3, func():
		ctx.fade_out(_static_voice, 1.0)
		ctx.impact.dim(0.0, 0.6))


func _fx_process(delta: float) -> void:
	# Residual static arcs hopping along the fissures after the eruption.
	if t < T_AFTER or t > duration - 1.0 or _fissures == null:
		return
	_arc_timer -= delta
	if _arc_timer > 0.0:
		return
	_arc_timer = lerpf(0.08, 0.35, (t - T_AFTER) / (duration - T_AFTER))
	var path: PackedVector2Array = _fissures.paths[ctx.rng.randi() % FISSURES]
	var k := ctx.rng.randi_range(1, path.size() - 3)
	var a := Iso.ground_to_screen(origin + path[k]) + Vector2(0, -2)
	var b := Iso.ground_to_screen(origin + path[k + 2]) + Vector2(0, -2)
	Set2Parts.bolt(self, ctx.overhead, a, b, 0.12, 0.0, 1)
