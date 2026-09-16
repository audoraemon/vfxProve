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
const FUNNEL_HEIGHT := 160.0


## Funnel of stacked wind ribbons with orbiting debris. Positioned on the ground point.
class Funnel:
	extends Node2D

	const RIBBON := Color(0.93, 0.95, 1.0)
	const RIBBON_DIM := Color(0.7, 0.74, 0.8)
	const BODY := Color(0.72, 0.72, 0.75)
	const DEBRIS := [Color("6e5234"), Color("8a6a44"), Color("5d6170"), Color("4b4f5b"), Color("3a3032")]

	var grow := 0.0
	var fade := 1.0
	var lean := 0.0
	var spin := 1.0
	var lights: LightField
	var ground_pos := Vector2.ZERO
	var rng: RandomNumberGenerator
	var _time := 0.0
	var _debris: Array = []

	func setup() -> void:
		for i in 46:
			_debris.append(_new_chunk(rng.randf()))

	func _new_chunk(h: float) -> Dictionary:
		return {"a": rng.randf() * TAU, "h": h, "speed": rng.randf_range(0.08, 0.2), "size": rng.randf_range(3.0, 7.0),
			"kind": rng.randi() % 5, "rot": rng.randf() * TAU, "plank": rng.randf() < 0.35, "orbit": rng.randf_range(0.7, 1.15)}

	func _process(delta: float) -> void:
		_time += delta
		for c in _debris:
			c.a += delta * spin * lerpf(4.5, 1.6, c.h)
			c.h += delta * c.speed * grow
			c.rot += delta * 6.0
			if c.h > 1.0:
				c.merge(_new_chunk(0.0), true)
		queue_redraw()

	func _radius(k: float) -> float:
		return lerpf(10.0, 78.0, pow(k, 1.35))

	func _center(k: float) -> Vector2:
		var sway := sin(_time * 1.3 + k * 2.4) * 10.0 * k + lean * k * k
		return Vector2(sway, -k * FUNNEL_HEIGHT * grow)

	func _draw() -> void:
		if grow <= 0.01 or fade <= 0.0:
			return
		var amb := maxf(lights.ambient, 0.55) if lights else 1.0
		var levels := 22
		# Translucent dusty body between the silhouette edges.
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in levels + 1:
			var k := float(i) / levels
			var c := _center(k)
			var r := _radius(k) * grow
			left.append(c - Vector2(r, 0))
			right.append(c + Vector2(r, 0))
		for i in levels:
			var col := Color(BODY * amb, 0.42 * fade * (1.0 - float(i) / levels * 0.35))
			draw_primitive(PackedVector2Array([left[i], left[i + 1], right[i + 1], right[i]]),
				PackedColorArray([col, col, col, col]), PackedVector2Array())
			# Darker core column and bright rim streaks give the funnel volume.
			var core := Color(0.42, 0.44, 0.5, 0.35 * fade)
			var ml := left[i].lerp(right[i], 0.38)
			var mr := left[i].lerp(right[i], 0.62)
			var ml2 := left[i + 1].lerp(right[i + 1], 0.38)
			var mr2 := left[i + 1].lerp(right[i + 1], 0.62)
			draw_primitive(PackedVector2Array([ml, ml2, mr2, mr]), PackedColorArray([core, core, core, core]),
				PackedVector2Array())
			var rim := Color(RIBBON * amb, 0.7 * fade)
			draw_line(left[i].round(), left[i + 1].round(), rim, -1.0)
			draw_line(right[i].round(), right[i + 1].round(), Color(RIBBON_DIM * amb, 0.6 * fade), -1.0)
		# Back half of the ribbons and debris, then front.
		for pass_i in 2:
			var front := pass_i == 1
			for i in levels:
				var k := (i + 0.5) / levels
				_ribbon(k, front, amb)
			for c in _debris:
				var is_front := sin(c.a) > 0.0
				if is_front == front:
					_chunk(c, amb)

	func _ribbon(k: float, front: bool, amb: float) -> void:
		var c := _center(k)
		var rx := _radius(k) * grow
		var ry := rx * 0.34
		var col := Color(RIBBON * amb, fade * (1.0 if front else 0.45))
		# Dashed ribbon segments rotating around the funnel, faster low down.
		var phase := _time * spin * lerpf(5.0, 2.0, k) + k * 7.0
		var dashes := 4
		for d in dashes:
			var a0 := phase + TAU * d / dashes
			var a1 := a0 + lerpf(1.2, 1.9, k)
			var steps := 8
			var prev := Vector2.ZERO
			for s in steps + 1:
				var a := lerpf(a0, a1, float(s) / steps)
				var p := c + Vector2(cos(a) * rx, sin(a) * ry)
				var in_front := sin(a) > 0.0
				if s > 0 and in_front == front:
					draw_line(prev.round(), p.round(), col, -1.0)
					draw_line(prev.round() + Vector2(0, 1), p.round() + Vector2(0, 1), Color(RIBBON_DIM * amb, col.a * 0.8), -1.0)
					if front:
						draw_line(prev.round() + Vector2(0, -1), p.round() + Vector2(0, -1), Color(1, 1, 1, col.a * 0.55), -1.0)
				prev = p

	func _chunk(c: Dictionary, amb: float) -> void:
		var k: float = c.h
		var center := _center(k)
		var r: float = _radius(k) * grow * c.orbit
		var p := center + Vector2(cos(c.a) * r, sin(c.a) * r * 0.34)
		var col: Color = DEBRIS[c.kind] * amb * (1.0 if sin(c.a) > 0.0 else 0.7)
		col.a = fade * clampf(k * 6.0, 0.0, 1.0) * clampf((1.0 - k) * 6.0, 0.0, 1.0)
		var s: float = c.size
		if c.plank:
			var d := Vector2(cos(c.rot), sin(c.rot)) * s * 1.4
			draw_line((p - d).round(), (p + d).round(), col, -1.0)
			draw_line((p - d).round() + Vector2(0, 1), (p + d).round() + Vector2(0, 1), col.darkened(0.3), -1.0)
		else:
			draw_rect(Rect2((p - Vector2(s, s) * 0.5).round(), Vector2(s, s).round()), col)
			draw_rect(Rect2((p - Vector2(s, s) * 0.5).round(), Vector2(roundf(s), 1)), col.lightened(0.25))

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
			var r: float = _radius(k) * grow * c.orbit
			var off := _center(k) + Vector2(cos(c.a) * r, 0)
			p.burst(1, {"offset": Vector2(off.x, 0), "velocity": Vector2(-sin(c.a), cos(c.a) * 0.5) * 90.0,
				"alt": Vector2(k * FUNNEL_HEIGHT, k * FUNNEL_HEIGHT), "alt_speed": Vector2(-20, 40),
				"life": Vector2(1.0, 1.8), "size": Vector2(1.5, 4.0)})


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
	track(_funnel, ctx.world)
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
	for e in ctx.field.in_radius(_center, CORE_RADIUS):
		ctx.field.kill(e, &"wind", _center - _dir.orthogonal() * (1.0 if _flung % 2 == 0 else -1.0))
		_flung += 1
		if _flung % 3 == 0:
			ctx.play(&"tn_gust", _center, -10.0)
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


func _dissipate() -> void:
	_pulling = false
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
