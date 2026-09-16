class_name Structure
extends Node2D
## Destructible iso building/prop drawn as a lit pixel box. Faces pick up light from the LightField
## on the side facing each light. Damage scorches and cracks it; destruction collapses it into
## rubble with dust and debris, reacting to the damage type (blast, beam cut, gravity).

enum Kind { TOWER, BLOCK, WALL, CRATES }

const RUBBLE_H := 5.0
const COLLAPSE_TIME := 0.8
const COL_CHAR := Color("141112")
const COL_WINDOW := [Color("ffcf7a"), Color("9fe8ff"), Color("ffb060")]
const COL_WINDOW_OFF := Color("1b1f28")
const COL_MOLTEN := Color("ffb040")

var kind := Kind.BLOCK
var footprint := Rect2()
var max_height := 60.0
var height := 60.0
var max_hp := 100.0
var hp := 100.0
var destroyed := false
var scorch := 0.0
var lights: LightField
## Overhead layer for debris/sparks, and the back layer for dust and smoke. Null in headless tests.
var fx_parent: Node
var fx_back: Node
var rng := RandomNumberGenerator.new()

var _collapse := -1.0
var _collapse_from := 0.0
var _destroy_kind := &""
var _shake := 0.0
var _time := 0.0
var _windows: Array = []
var _cracks: Array[PackedVector2Array] = []
var _rubble: Array = []
var _top_piece := {}
var _molten := 0.0
var _burning := false
var _s: Array[Vector2] = []
var _emitters: Array[PixelParticles] = []


func setup(rect: Rect2, h: float, k: Kind, seed_value: int) -> Structure:
	footprint = rect
	max_height = h
	height = h
	kind = k
	rng.seed = seed_value
	max_hp = {Kind.TOWER: 160.0, Kind.BLOCK: 110.0, Kind.WALL: 60.0, Kind.CRATES: 30.0}[k]
	hp = max_hp
	var g0 := rect.position
	var g2 := rect.end
	var front := Iso.ground_to_screen(g2)
	position = front
	_s = [Iso.ground_to_screen(g0) - front, Iso.ground_to_screen(Vector2(g2.x, g0.y)) - front,
		Vector2.ZERO, Iso.ground_to_screen(Vector2(g0.x, g2.y)) - front]
	if k == Kind.TOWER or k == Kind.BLOCK:
		_build_windows()
	return self


func contains(g: Vector2, margin := 0.0) -> bool:
	return footprint.grow(margin).has_point(g)


func center() -> Vector2:
	return footprint.get_center()


func distance_to(g: Vector2) -> float:
	var c := g.clamp(footprint.position, footprint.end)
	return c.distance_to(g)


func damage(amount: float, source: Vector2, damage_kind: StringName) -> void:
	if destroyed:
		return
	hp -= amount
	scorch = minf(scorch + amount / max_hp * 0.9, 1.0)
	_shake = maxf(_shake, 2.5)
	if hp <= 0.0:
		destroy(source, damage_kind)
		return
	if hp < max_hp * 0.65 and _cracks.is_empty():
		_build_cracks()
	for w in _windows:
		if rng.randf() < 0.3:
			w[3] = false
	if (damage_kind == &"nova" or damage_kind == &"orbital") and hp < max_hp * 0.7 and not _burning:
		_burning = true
		_spawn_fire(Vector2(0, -height), 3.5)


func shake(amount: float) -> void:
	if not destroyed:
		_shake = maxf(_shake, amount)


func destroy(source: Vector2, damage_kind: StringName) -> void:
	if destroyed:
		return
	destroyed = true
	hp = 0.0
	_destroy_kind = damage_kind
	scorch = maxf(scorch, 0.6)
	for w in _windows:
		w[3] = false
	_build_rubble()
	if damage_kind == &"laser" and max_height > 20.0:
		# Cut clean through: the top slides off and falls, a molten stump remains.
		var cut := clampf(max_height * 0.35, 10.0, 28.0)
		var away := (Iso.ground_to_screen(center()) - Iso.ground_to_screen(source)).normalized()
		_top_piece = {"h0": cut, "h1": max_height, "off": Vector2.ZERO, "vel": away * 55.0, "fall": 0.0, "t": 0.0}
		height = cut
		_molten = 1.0
		_spawn_sparks(Vector2(0, -cut), 26)
	else:
		_collapse = 0.0
		_collapse_from = height
		var toward := damage_kind == &"gravity"
		_spawn_debris(source, toward)
		_spawn_dust(1.0)
		if damage_kind != &"gravity":
			_spawn_fire(Vector2.ZERO, 3.0)


func _process(delta: float) -> void:
	_time += delta
	_shake = move_toward(_shake, 0.0, 10.0 * delta)
	if _collapse >= 0.0 and _collapse < 1.0:
		_collapse = minf(_collapse + delta / COLLAPSE_TIME, 1.0)
		var k := _collapse * _collapse
		height = lerpf(_collapse_from, RUBBLE_H, k)
		_shake = maxf(_shake, 2.0 * (1.0 - _collapse))
		if _collapse >= 1.0:
			_spawn_dust(0.5)
	if not _top_piece.is_empty():
		_top_piece.t += delta
		_top_piece.off += _top_piece.vel * delta
		if _top_piece.t > 0.35:
			_top_piece.fall += (_top_piece.t - 0.35) * 420.0 * delta
		if _top_piece.fall > _top_piece.h0 + 4.0:
			_spawn_debris(center() - (_top_piece.vel as Vector2).normalized(), false, _top_piece.off)
			_spawn_dust(0.7, _top_piece.off)
			_top_piece = {}
	_molten = maxf(_molten - delta * 0.5, 0.0)
	queue_redraw()


# --- Drawing -----------------------------------------------------------------

func _palette() -> Array:
	match kind:
		Kind.WALL:
			return [Color("4d525c"), Color("3d424b"), Color("31353d")]
		Kind.CRATES:
			return [Color("6a5638"), Color("56452d"), Color("433523")]
		_:
			return [Color("3d4453"), Color("2f3542"), Color("252a34")]


func _face_color(base: Color, normal: Vector2, light: Color, dir: Vector2) -> Color:
	var facing := 0.35
	if normal != Vector2.ZERO and dir.length() > 0.001:
		facing += 0.9 * clampf(dir.normalized().dot(normal), 0.0, 1.0)
	elif normal == Vector2.ZERO:
		facing = 0.9
	var lit := Color(light.r * facing, light.g * facing, light.b * facing)
	var amb := lights.ambient if lights else 1.0
	var c := Color(
		minf(base.r * amb * (1.0 + lit.r * 4.0) + lit.r * 0.35, 1.0),
		minf(base.g * amb * (1.0 + lit.g * 4.0) + lit.g * 0.35, 1.0),
		minf(base.b * amb * (1.0 + lit.b * 4.0) + lit.b * 0.35, 1.0))
	return c.lerp(COL_CHAR, scorch * 0.65)


func _draw() -> void:
	var light := lights.sample(center()) if lights else Color.BLACK
	var dir := lights.sample_dir(center()) if lights else Vector2.ZERO
	var pal := _palette()
	var top_c := _face_color(pal[0], Vector2.ZERO, light, dir)
	var right_c := _face_color(pal[1], Vector2(1, 0), light, dir)
	var left_c := _face_color(pal[2], Vector2(0, 1), light, dir)
	var jitter := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake if _shake > 0.2 else Vector2.ZERO
	draw_set_transform(jitter.round())

	# Ground shadow toward the back.
	draw_colored_polygon(PackedVector2Array([_s[0], _s[1] + Vector2(6, -3), _s[2] + Vector2(6, -3), _s[3]]),
		Color(0, 0, 0, 0.25))

	var rubble_top := _collapse >= 0.0
	_draw_box(0.0, height, top_c, right_c, left_c, rubble_top)
	if not rubble_top and kind != Kind.CRATES and kind != Kind.WALL:
		_draw_windows(light)
	_draw_kind_details(top_c, right_c, left_c)
	for crack in _cracks:
		var pts := PackedVector2Array()
		for p in crack:
			pts.append(Vector2(p.x, p.y * height))
		draw_polyline(pts, Color(0.05, 0.04, 0.05, 0.9), -1.0)

	if _molten > 0.0:
		var m := COL_MOLTEN
		m.a = _molten
		draw_polyline(PackedVector2Array([_s[3] + Vector2(0, -height), _s[2] + Vector2(0, -height),
			_s[1] + Vector2(0, -height)]), m, -1.0)

	if not _top_piece.is_empty():
		draw_set_transform((jitter + _top_piece.off + Vector2(0, _top_piece.fall)).round())
		_draw_box(_top_piece.h0, _top_piece.h1, top_c, right_c, left_c, false)
		draw_set_transform(Vector2.ZERO)

	if _collapse >= 1.0 or (destroyed and _top_piece.is_empty() and _collapse < 0.0):
		for r in _rubble:
			draw_colored_polygon(r[0], r[1].lerp(COL_CHAR, scorch * 0.5))
	draw_set_transform(Vector2.ZERO)


func _draw_box(h0: float, h1: float, top_c: Color, right_c: Color, left_c: Color, jagged: bool) -> void:
	var b := Vector2(0, -h0)
	var t := Vector2(0, -h1)
	draw_colored_polygon(PackedVector2Array([_s[3] + b, _s[2] + b, _s[2] + t, _s[3] + t]), left_c)
	draw_colored_polygon(PackedVector2Array([_s[1] + b, _s[2] + b, _s[2] + t, _s[1] + t]), right_c)
	var top := PackedVector2Array([_s[0] + t, _s[1] + t, _s[2] + t, _s[3] + t])
	if jagged:
		# Broken, uneven top while collapsing / as rubble.
		top = PackedVector2Array()
		for i in 4:
			var a := _s[i] + t
			var c := _s[(i + 1) % 4] + t
			for k in 3:
				var p := a.lerp(c, k / 3.0)
				top.append(p + Vector2(0, -fposmod(sin(float(i * 7 + k) * 12.9898) * 43758.5, 5.0)))
	draw_colored_polygon(top, top_c)
	var edge := top_c.lightened(0.18)
	draw_polyline(PackedVector2Array([_s[3] + t, _s[2] + t, _s[1] + t]), edge, -1.0)
	draw_line(_s[2] + b, _s[2] + t, right_c.lightened(0.1), -1.0)


func _build_windows() -> void:
	var rows := int((max_height - 8.0) / 9.0)
	for face in [[3, 2], [1, 2]]:
		var a: Vector2 = _s[face[0]]
		var b: Vector2 = _s[face[1]]
		var cols := int(absf(b.x - a.x) / 8.0)
		for c in cols:
			for r in rows:
				var u := (c + 0.6) / float(cols)
				var v := (r * 9.0 + 7.0) / max_height
				_windows.append([face[0], u, v, rng.randf() < 0.35, rng.randi() % 3])


func _draw_windows(light: Color) -> void:
	for w in _windows:
		if w[2] * max_height > height - 4.0:
			continue
		var a: Vector2 = _s[w[0]]
		var p: Vector2 = a.lerp(_s[2], w[1]) + Vector2(0, -w[2] * max_height)
		var col: Color = COL_WINDOW[w[4]] if w[3] else COL_WINDOW_OFF.lerp(Color(light.r, light.g, light.b), 0.25)
		if w[3] and fmod(_time * 0.7 + w[1] * 13.0, 9.0) < 0.12:
			col = COL_WINDOW_OFF
		draw_rect(Rect2(p.round() + Vector2(-1, -2), Vector2(2, 3)), col)


func _draw_kind_details(top_c: Color, right_c: Color, left_c: Color) -> void:
	if destroyed:
		return
	var roof := _s[0].lerp(_s[2], 0.5) + Vector2(0, -height)
	match kind:
		Kind.TOWER:
			draw_rect(Rect2(roof + Vector2(-4, -4), Vector2(7, 4)), right_c.lightened(0.05))
			draw_rect(Rect2(roof + Vector2(-4, -4), Vector2(7, 1)), top_c.lightened(0.15))
			draw_line(roof + Vector2(5, 0), roof + Vector2(5, -14), left_c.lightened(0.25), -1.0)
			if fmod(_time, 1.2) < 0.5:
				draw_rect(Rect2(roof + Vector2(5, -15), Vector2.ONE), Color("ff3a2a"))
		Kind.WALL:
			# Hazard stripes along the front face.
			for i in 6:
				var u := (i + 0.5) / 6.0
				var p := _s[3].lerp(_s[2], u) + Vector2(0, -height * 0.55)
				draw_rect(Rect2(p.round(), Vector2(2, 2)), Color("c89a2a").lerp(COL_CHAR, scorch))
		Kind.CRATES:
			draw_line(_s[3].lerp(_s[2], 0.5), _s[3].lerp(_s[2], 0.5) + Vector2(0, -height), left_c.darkened(0.3), -1.0)
			draw_line(_s[1].lerp(_s[2], 0.5), _s[1].lerp(_s[2], 0.5) + Vector2(0, -height), right_c.darkened(0.3), -1.0)


func _build_cracks() -> void:
	for n in 3:
		var face := 3 if n % 2 == 0 else 1
		var u := rng.randf_range(0.15, 0.85)
		var p: Vector2 = _s[face].lerp(_s[2], u)
		var pts := PackedVector2Array()
		var v := rng.randf_range(0.5, 0.9)
		for i in 5:
			pts.append(Vector2(p.x + rng.randf_range(-3, 3), -v))
			v -= rng.randf_range(0.08, 0.16)
		_cracks.append(pts)


func _build_rubble() -> void:
	var pal := _palette()
	var count := int(clampf(footprint.get_area() * 10.0, 6.0, 26.0))
	for i in count:
		var g := Vector2(rng.randf_range(footprint.position.x - 0.25, footprint.end.x + 0.25),
			rng.randf_range(footprint.position.y - 0.25, footprint.end.y + 0.25))
		var c := Iso.ground_to_screen(g) - position
		var size := rng.randf_range(2.0, 5.5)
		var poly := PackedVector2Array()
		for k in 5:
			var ang := TAU * k / 5.0 + rng.randf() * 0.6
			poly.append(c + Vector2(cos(ang), sin(ang) * 0.7) * size * rng.randf_range(0.6, 1.0) + Vector2(0, -size * 0.4))
		_rubble.append([poly, pal[rng.randi() % 3]])


# --- Effects -----------------------------------------------------------------

func _particles(parent: Node, shape: PixelParticles.Shape, ramp: Array, offset := Vector2.ZERO) -> PixelParticles:
	var p := PixelParticles.new()
	p.rng.seed = rng.randi()
	p.shape = shape
	p.ramp = PackedColorArray(ramp)
	p.position = position + offset
	parent.add_child(p)
	return p


func _footprint_radius_px() -> float:
	return maxf(footprint.size.x, footprint.size.y) * FxParts.PX_PER_UNIT_MAJOR * 0.6


func _spawn_debris(source: Vector2, toward: bool, offset := Vector2.ZERO) -> void:
	if fx_parent == null:
		return
	var away := (Iso.ground_to_screen(center()) - Iso.ground_to_screen(source)).normalized()
	if toward:
		away = -away
	var p := _particles(fx_parent, PixelParticles.Shape.CHUNK, FxParts.ROCK, offset + Vector2(0, -height * 0.5))
	p.gravity = 420.0
	p.bounce = true
	p.drag = 0.8
	p.shadows = true
	var count := int(clampf(max_height * 0.5, 10.0, 40.0))
	for i in count:
		var v := (away * rng.randf_range(40.0, 170.0) + Vector2(rng.randf_range(-60, 60), rng.randf_range(-30, 30)))
		p.burst(1, {"radius": _footprint_radius_px(), "velocity": v, "alt": Vector2(0, height * 0.6),
			"alt_speed": Vector2(30, 180), "life": Vector2(1.0, 2.0), "size": Vector2(1.5, 4.5)})


func _spawn_dust(amount: float, offset := Vector2.ZERO) -> void:
	if fx_back == null:
		return
	var p := _particles(fx_back, PixelParticles.Shape.PUFF, FxParts.DUST_LIFE, offset)
	p.drag = 1.4
	p.burst(int(12.0 * amount * clampf(max_height / 50.0, 0.5, 1.6)), {
		"radius": _footprint_radius_px() * 1.1, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(20, 70),
		"alt": Vector2(0, maxf(height * 0.4, 4.0)), "alt_speed": Vector2(4, 22), "life": Vector2(0.9, 1.8),
		"size": Vector2(4, 8), "size_end_mul": 1.5,
	})


func _spawn_sparks(offset: Vector2, count: int) -> void:
	if fx_parent == null:
		return
	var p := _particles(fx_parent, PixelParticles.Shape.STREAK, FxParts.LASER_LIFE, offset)
	p.gravity = 260.0
	p.drag = 1.5
	p.burst(count, {"radius": _footprint_radius_px() * 0.6, "speed": Vector2(60, 200), "alt_speed": Vector2(20, 120),
		"life": Vector2(0.3, 0.7), "size": Vector2(1, 2)})


func _spawn_fire(offset: Vector2, seconds: float) -> void:
	if fx_parent == null or fx_back == null:
		return
	var f := _particles(fx_parent, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, offset)
	f.rate = 18.0
	f.emitting = true
	f.spec = {"radius": _footprint_radius_px() * 0.5, "alt_speed": Vector2(20, 50), "speed": Vector2(0, 6),
		"life": Vector2(0.3, 0.6), "size": Vector2(1.5, 3.5), "size_end_mul": 0.3}
	var smoke := _particles(fx_back, PixelParticles.Shape.PUFF, FxParts.SMOKE_LIFE, offset)
	smoke.rate = 6.0
	smoke.emitting = true
	smoke.drag = 0.4
	smoke.spec = {"radius": _footprint_radius_px() * 0.4, "alt": Vector2(4, 10), "alt_speed": Vector2(18, 40),
		"speed": Vector2(2, 10), "life": Vector2(1.2, 2.2), "size": Vector2(3, 5), "size_end_mul": 1.7}
	_emitters.append(f)
	_emitters.append(smoke)
	var tw := create_tween() if is_inside_tree() else null
	if tw:
		tw.tween_interval(seconds)
		tw.tween_callback(_stop_emitters.bind([f, smoke]))


func _stop_emitters(list: Array) -> void:
	for e in list:
		if is_instance_valid(e):
			e.emitting = false


func _exit_tree() -> void:
	# Emitters live in the fx layers; make sure they wind down if this structure goes away first.
	_stop_emitters(_emitters)
