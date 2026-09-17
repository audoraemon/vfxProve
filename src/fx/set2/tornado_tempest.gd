extends FxTimeline
## Tornado Tempest: spiral wind rune and suction ring -> a tornado forms from swirling dust -> it pulls enemies,
## rocks and planks into its spiral -> it walks forward shredding everything in its path ->
## it unravels, dropping debris, leaving dust clouds, wind ribbons and a scarred trail.

const LENGTH := 8.0
const PULL_RADIUS := 3.2
const CORE_RADIUS := 0.6
const T_FORM := 1.0
const FORM_TIME := 1.2
const T_WALK := 3.0
const WALK_TIME := 4.2
const T_END := T_WALK + WALK_TIME
const FUNNEL_HEIGHT := 240.0
## Seconds a captured enemy spirals up the funnel before it is flung out.
const CAPTURE_TIME := 1.1


## Tornado: shader funnel volume (`tornado_funnel.gdshader`) between two debris layers, so rocks and planks
## orbit behind and in front of it. Positioned on the ground point.
class Funnel:
	extends Node2D

	const DEBRIS := [Color("6e5234"), Color("8a6a44"), Color("5d6170"), Color("4b4f5b"), Color("3a3032")]
	const SH_FUNNEL := preload("res://shaders/tornado_funnel.gdshader")
	const BASE_R := 22.0
	const TOP_R := 115.0
	const MARGIN := 40.0

	var grow := 0.0
	var fade := 1.0
	var lean := 0.0
	var spin := 1.0
	var lights: LightField
	var ground_pos := Vector2.ZERO
	var rng: RandomNumberGenerator
	var _time := 0.0
	var _debris: Array = []
	var _body: QuadFx
	var _back: DebrisLayer
	var _front: DebrisLayer

	func setup() -> void:
		for i in 60:
			_debris.append(_new_chunk(rng.randf()))
		_back = DebrisLayer.new()
		_back.funnel = self
		add_child(_back)
		var w := (TOP_R * 1.4 + 60.0) * 2.0
		var h := FUNNEL_HEIGHT + TOP_R * 0.5 + MARGIN + 20.0
		_body = QuadFx.new().setup(SH_FUNNEL, Vector2(w, h), Vector2(0.5, (h - MARGIN) / h))
		_body.set_param("size", Vector2(w, h))
		_body.set_param("base_margin", MARGIN)
		_body.set_param("height_px", FUNNEL_HEIGHT)
		_body.set_param("base_r", BASE_R)
		_body.set_param("top_r", TOP_R)
		add_child(_body)
		_front = DebrisLayer.new()
		_front.funnel = self
		_front.front = true
		add_child(_front)

	func _new_chunk(h: float) -> Dictionary:
		return {"a": rng.randf() * TAU, "h": h, "speed": rng.randf_range(0.08, 0.2), "size": rng.randf_range(4.0, 10.0),
			"kind": rng.randi() % 5, "rot": rng.randf() * TAU, "plank": rng.randf() < 0.4, "orbit": rng.randf_range(0.6, 1.2)}

	func _process(delta: float) -> void:
		_time += delta
		for c in _debris:
			c.a += delta * spin * lerpf(4.5, 1.4, c.h)
			c.h += delta * c.speed * grow
			c.rot += delta * 6.0
			if c.h > 1.0:
				c.merge(_new_chunk(0.0), true)
		var amb := maxf(lights.ambient, 0.55) if lights else 1.0
		_body.modulate = Color(amb, amb, amb)
		_body.set_param("grow", grow)
		_body.set_param("fade", fade)
		_body.set_param("lean", lean)
		_body.set_param("spin", spin)
		_back.queue_redraw()
		_front.queue_redraw()

	## Funnel radius in px at height fraction k (matches the shader).
	func radius(k: float) -> float:
		return lerpf(BASE_R, TOP_R, pow(clampf(k, 0.0, 1.2), 1.4)) * lerpf(0.35, 1.0, grow)

	func center(k: float) -> Vector2:
		return Vector2(sin(_body.age * 1.3 + k * 2.4) * 8.0 * k + lean * k * k, -k * FUNNEL_HEIGHT * grow)

	func draw_debris(layer: Node2D, front: bool) -> void:
		if grow <= 0.01 or fade <= 0.0:
			return
		var amb := maxf(lights.ambient, 0.55) if lights else 1.0
		for c in _debris:
			if (sin(c.a) > 0.0) != front:
				continue
			var k: float = c.h
			var r: float = radius(k) * c.orbit
			var p := center(k) + Vector2(cos(c.a) * r, sin(c.a) * r * 0.32)
			var col: Color = DEBRIS[c.kind] * amb * (1.0 if front else 0.7)
			col.a = fade * clampf(k * 6.0, 0.0, 1.0) * clampf((1.0 - k) * 6.0, 0.0, 1.0)
			var s: float = c.size
			if c.plank:
				var d := Vector2(cos(c.rot), sin(c.rot)) * s * 1.6
				var n := d.orthogonal().normalized()
				for w in 3:
					var shade := col.lightened(0.2) if w == 0 else (col if w == 1 else col.darkened(0.35))
					layer.draw_line((p - d + n * (w - 1)).round(), (p + d + n * (w - 1)).round(), shade, -1.0)
			else:
				var q := PackedVector2Array()
				for i in 5:
					var a: float = c.rot + TAU * i / 5.0
					q.append(p + Vector2(cos(a), sin(a)) * s * (0.5 + 0.15 * sin(i * 2.3 + c.kind)))
				layer.draw_colored_polygon(q, Color(0.1, 0.08, 0.08, col.a))
				var inner := PackedVector2Array()
				for v in q:
					inner.append(p + (v - p) * 0.75 + Vector2(-0.5, -0.5))
				layer.draw_colored_polygon(inner, col)

	func release_debris(overhead: Node, back: Node) -> void:
		# Everything in the funnel drops out at once.
		var p := PixelParticles.new()
		p.rng.seed = rng.randi()
		p.shape = PixelParticles.Shape.CHUNK
		p.ramp = PackedColorArray(Set2Parts.WOOD)
		p.gravity = 380.0
		p.bounce = true
		p.drag = 0.7
		p.shadows = true
		p.position = position
		overhead.add_child(p)
		for c in _debris:
			var k: float = c.h
			var r: float = radius(k) * c.orbit
			var off := center(k) + Vector2(cos(c.a) * r, 0)
			p.burst(1, {"offset": Vector2(off.x, 0), "velocity": Vector2(-sin(c.a), cos(c.a) * 0.5) * 110.0,
				"alt": Vector2(k * FUNNEL_HEIGHT, k * FUNNEL_HEIGHT), "alt_speed": Vector2(-20, 40),
				"life": Vector2(1.0, 1.8), "size": Vector2(2.0, 5.0)})


class DebrisLayer:
	extends Node2D

	var funnel: Funnel
	var front := false

	func _draw() -> void:
		funnel.draw_debris(self, front)


var _dir := Vector2(1, 0)
var _center := Vector2.ZERO
var _sigil: SigilRune
var _lane: LanePath
var _funnel: Funnel
var _suction: QuadFx
var _dust: PixelParticles
var _wind: Node
var _pulling := false
var _next_scar := 0.0
var _flung := 0
## Enemies spiralling up the funnel: {e, t, a}.
var _captured: Array[Dictionary] = []


func _build() -> void:
	duration = 10.0
	_dir = (extra.get("dir", Vector2(1, 0)) as Vector2).normalized()
	_center = origin
	_lane = Set2Parts.lane(self, origin, _dir, LENGTH, PULL_RADIUS * 1.4, Color("d8e4f0"), "wind")
	_lane.z_index = 8
	_sigil = Set2Parts.sigil(self, origin, 2.4, Color("dfeaf5"), "spiral")
	_suction = FxParts.rings(self, origin, PULL_RADIUS, Color("cfdcea"), 3, 26.0)
	_suction.z_index = 8
	_suction.set_param("crosshair", 0.0)
	_suction.set_param("fill", 0.05)
	_suction.set_param("color", Color(0.8, 0.86, 0.92, 0.55))
	_suction.tween_param("reveal", 0.0, 1.0, 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ctx.impact.dim(0.35, 1.0)
	ctx.play(&"tn_gust", origin, -4.0)
	var motes := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin), PixelParticles.Shape.STREAK,
		Set2Parts.WIND_LIFE, 40.0, T_FORM, {
			"radius": FxParts.particle_radius(2.4), "dir": PixelParticles.Dir.INWARD, "speed": Vector2(60, 140),
			"alt": Vector2(0, 8), "life": Vector2(0.4, 0.8), "size": Vector2(2, 4),
		})
	motes.streak_len = 0.08
	at(T_FORM, _form)
	at(T_WALK, _walk)
	at(T_END, _dissipate)


func _form() -> void:
	ctx.play(&"tn_form", origin)
	_wind = ctx.play(&"tn_wind", origin, -2.0)
	create_tween().tween_property(_sigil, "alpha", 0.0, 0.6)
	_funnel = Funnel.new()
	_funnel.rng = ctx.rng
	_funnel.lights = ctx.lights
	_funnel.ground_pos = origin
	_funnel.position = Iso.ground_to_screen(origin)
	_funnel.setup()
	# Overhead like the other titans: long castle walls sort badly against a 240 px tall funnel.
	track(_funnel, ctx.overhead_back)
	create_tween().tween_property(_funnel, "grow", 1.0, FORM_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ctx.shake.add_trauma(0.4)
	var ring := FxParts.shockwave(self, origin, 2.6, Set2Parts.WIND)
	ring.z_index = 9
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.3, 0.3)
	ring.life = 0.65
	_dust = FxParts.emitter(self, ctx.overhead_back, Vector2.ZERO, PixelParticles.Shape.PUFF, Set2Parts.DUST_CLOUD, 26.0,
		T_END - t + 0.3, {
			"radius": 30.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(40, 100), "alt": Vector2(0, 6),
			"alt_speed": Vector2(4, 14), "life": Vector2(0.5, 0.9), "size": Vector2(2, 4), "size_end_mul": 1.6,
		})
	_dust.drag = 1.0
	_pulling = true


func _walk() -> void:
	create_tween().tween_property(_lane, "alpha", 0.0, 0.8)
	ctx.play(&"tn_gust", origin, -2.0)


func _fx_process(delta: float) -> void:
	if _funnel == null or not is_instance_valid(_funnel):
		return
	var walk_k := clampf((t - T_WALK) / WALK_TIME, 0.0, 1.0)
	var prev := _center
	_center = origin + _dir * LENGTH * (walk_k * walk_k * (3.0 - 2.0 * walk_k))
	var sp := Iso.ground_to_screen(_center)
	_funnel.position = sp.round()
	_funnel.ground_pos = _center
	var move := Iso.ground_to_screen(_center) - Iso.ground_to_screen(prev)
	_funnel.lean = lerpf(_funnel.lean, clampf(-move.x / maxf(delta, 0.001) * 0.25, -30.0, 30.0), minf(3.0 * delta, 1.0))
	_suction.position = _center
	if is_instance_valid(_dust):
		_dust.spec["offset"] = sp
	if not _pulling:
		return
	var strength := curve([[T_FORM, 0.5], [T_FORM + FORM_TIME, 2.6], [T_END, 3.0]])
	ctx.field.pull(_center, PULL_RADIUS, strength, 1.4, delta)
	# Enemies reaching the core are caught: they circle up the funnel, then get flung out.
	for e in ctx.field.in_radius(_center, CORE_RADIUS):
		if not _captured.any(func(c): return c.e == e):
			var rel := e.ground_pos - _center
			_captured.append({"e": e, "t": 0.0, "a": rel.angle() if rel.length() > 0.01 else ctx.rng.randf() * TAU})
	var keep: Array[Dictionary] = []
	for c in _captured:
		var e: DummyEnemy = c.e
		if not is_instance_valid(e) or not e.is_alive():
			continue
		c.t += delta
		var k: float = clampf(c.t / CAPTURE_TIME, 0.0, 1.0)
		c.a += delta * lerpf(9.0, 4.0, k)
		var height := k * FUNNEL_HEIGHT * 0.7
		# Funnel radius at that height, px -> ground units (a ground unit is ~36 px across).
		var r := _funnel.radius(height / FUNNEL_HEIGHT) * 0.8 / 36.0
		e.ground_pos = _center + Vector2(cos(c.a), sin(c.a)) * r
		e.lift_target = height
		if k >= 1.0:
			_fling(e)
		else:
			keep.append(c)
	_captured = keep
	ctx.env.damage_radius(_center, 1.1, 140.0 * delta, &"wind")
	ctx.env.shake_radius(_center, PULL_RADIUS, 1.5)
	ctx.shake.add_trauma(0.25 * delta)
	# Scarred swirl decal and turbulence ribbons left behind while walking.
	if walk_k > 0.0 and walk_k < 1.0 and (_center - origin).length() >= _next_scar:
		_next_scar += 0.9
		var scar := FxParts.decal(self, _center, 1.3, Color("8a7258"), Color("c8ae86"), Color(0.2, 0.16, 0.12, 0.7), 1.0)
		scar.set_param("heat", 0.35)
		scar.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
		var trail := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, Set2Parts.WIND_LIFE, 10.0, 1.2, {
			"radius": 30.0, "speed": Vector2(40, 90), "angle": Vector2(-0.3, 0.3) + Vector2.ONE * (-_dir).angle(),
			"alt": Vector2(2, 30), "life": Vector2(0.5, 1.0), "size": Vector2(3, 5),
		})
		trail.streak_len = 0.12


func _fling(e: DummyEnemy) -> void:
	ctx.field.kill(e, &"wind", _center - _dir.orthogonal() * (1.0 if _flung % 2 == 0 else -1.0))
	_flung += 1
	if _flung % 3 == 0:
		ctx.play(&"tn_gust", _center, -10.0)


func _dissipate() -> void:
	_pulling = false
	for c in _captured:
		if is_instance_valid(c.e) and (c.e as DummyEnemy).is_alive():
			_fling(c.e)
	_captured.clear()
	ctx.play(&"tn_dissipate", _center)
	ctx.fade_out(_wind, 1.0)
	ctx.field.release_all()
	_funnel.release_debris(ctx.overhead, ctx.overhead_back)
	_funnel.spin = 0.4
	var tw := create_tween()
	tw.tween_property(_funnel, "fade", 0.0, 0.9)
	tw.parallel().tween_property(_funnel, "grow", 1.25, 0.9)
	create_tween().tween_property(_suction, "modulate:a", 0.0, 0.5)
	_suction.tween_param("alpha", 1.0, 0.0, 0.5)
	var sp := Iso.ground_to_screen(_center)
	var cloud := FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, Set2Parts.DUST_CLOUD)
	cloud.drag = 1.1
	cloud.burst(26, {"radius": 40.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(20, 70), "alt": Vector2(0, 30),
		"alt_speed": Vector2(4, 20), "life": Vector2(1.2, 2.0), "size": Vector2(3, 6), "size_end_mul": 1.6})
	# Fading wind ribbons curling across the scarred path.
	for i in 5:
		var g := origin + _dir * ctx.rng.randf_range(0.0, LENGTH) + _dir.orthogonal() * ctx.rng.randf_range(-1.5, 1.5)
		var ribbon := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(g), PixelParticles.Shape.STREAK,
			Set2Parts.WIND_LIFE, 6.0, 2.0, {
				"radius": 20.0, "speed": Vector2(30, 70), "alt": Vector2(2, 14), "life": Vector2(0.8, 1.4), "size": Vector2(4, 6),
			})
		ribbon.streak_len = 0.15
	at(duration - 1.2, func(): ctx.impact.dim(0.0, 0.6))
