class_name IceSpike
extends Node2D
## Ice crystal cluster standing on a ground point (y-sorted in the world layer).
## Each crystal is a hexagonal prism with a faceted point: dark cyan left face, pale front face,
## mid-blue right face, three tip facets, a white ridge highlight and star glints.
## `cluster` fans extra smaller crystals and loose gems out from the same base.
## `grow` drives the rise (overshoot allowed); `shatter` shortens and cracks it into residue.

const EDGE := Color("145a96")
const LEFT := Color("2a8fd0")
const RIGHT := Color("6cc4ec")
const FRONT := Color("d4f1fb")
const TIP_L := Color("a8def5")
const TIP_R := Color("4aaee0")
const TIP_F := Color("f2fcff")
const DEEP := Color("0f3f73")
const HI := Color("ffffff")

## Main crystal length and half width in px.
var height := 60.0
var width := 10.0
## Main crystal tilt in radians (0 = straight up, positive leans right).
var angle := 0.0
var cluster := true
var grow := 0.0
var shatter := 0.0
var glow := 0.0
var fade := 1.0
var seed := 0.0
var lights: LightField
var ground_pos := Vector2.ZERO

## Each crystal: [base offset px, angle, length, half width, depth order].
var _crystals: Array = []
var _time := 0.0
var _drawn := PackedFloat32Array()


func _ready() -> void:
	_build_crystals()


func _build_crystals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed * 1000.0) + 17
	_crystals.clear()
	_crystals.append([Vector2.ZERO, angle, height, width, 0])
	if not cluster:
		return
	# Side crystals fanning out from the base, some behind (drawn first), some in front.
	var sides := rng.randi_range(2, 4)
	for i in sides:
		var sgn := -1.0 if i % 2 == 0 else 1.0
		var a := angle + sgn * rng.randf_range(0.35, 0.95)
		var off := Vector2(sgn * width * rng.randf_range(0.3, 0.9), rng.randf_range(-2.0, 5.0))
		var order := -1 if off.y < 1.0 else 1
		_crystals.append([off, a, height * rng.randf_range(0.4, 0.72), width * rng.randf_range(0.55, 0.85), order])
	# Loose gems lying low at the foot.
	if rng.randf() < 0.7:
		var sgn := -1.0 if rng.randf() < 0.5 else 1.0
		_crystals.append([Vector2(sgn * width * rng.randf_range(0.9, 1.5), rng.randf_range(2.0, 6.0)),
			sgn * rng.randf_range(1.0, 1.35), maxf(height * 0.22, 7.0), width * 0.55, 2])
	_crystals.sort_custom(func(x, y): return x[4] < y[4])


func _process(delta: float) -> void:
	_time += delta
	# Redraw only when the look changes (growth, shatter, light, glint).
	var l := lights.sample(ground_pos) if lights != null else Color.BLACK
	var amb := lights.ambient if lights != null else 1.0
	var glint := float(int(fmod(_time * 1.3 + seed, 2.2) < 0.2))
	var state := PackedFloat32Array([snappedf(grow, 0.02), snappedf(shatter, 0.02), snappedf(fade, 0.02),
		snappedf(glow, 0.05), snappedf(amb, 0.05), snappedf(l.r, 0.08), snappedf(l.g, 0.08), snappedf(l.b, 0.08), glint])
	if state != _drawn:
		_drawn = state
		queue_redraw()


func _draw() -> void:
	if grow <= 0.01:
		return
	var alpha := fade * (1.0 - shatter * 0.2)
	if alpha <= 0.0:
		return
	var amb := 1.0
	var lit := Color.BLACK
	if lights != null:
		amb = maxf(lights.ambient, 0.72)
		lit = lights.sample(ground_pos)
	var boost := 1.0 + glow * 0.12
	var pal := {
		"edge": _shade(EDGE, amb, lit, boost, alpha), "left": _shade(LEFT, amb, lit, boost, alpha),
		"right": _shade(RIGHT, amb, lit, boost, alpha), "front": _shade(FRONT, amb, lit, boost, alpha),
		"tip_l": _shade(TIP_L, amb, lit, boost, alpha), "tip_r": _shade(TIP_R, amb, lit, boost, alpha),
		"tip_f": _shade(TIP_F, amb, lit, boost, alpha), "deep": _shade(DEEP, amb, lit, boost, alpha * 0.9),
		"hi": Color(HI, alpha),
	}
	var shrink := 1.0 - shatter * 0.78
	for i in _crystals.size():
		var c: Array = _crystals[i]
		var is_main: bool = c[4] == 0 and c[0] == Vector2.ZERO
		# Side crystals lag the main one slightly as they grow.
		var g := clampf(grow if is_main else grow * 1.15 - 0.15, 0.0, 1.6)
		_draw_crystal(c[0], c[1], c[2] * g * shrink, c[3] * clampf(0.6 + g * 0.4, 0.0, 1.2), pal, is_main, i)


func _draw_crystal(base: Vector2, a: float, length: float, w: float, pal: Dictionary, is_main: bool, index: int) -> void:
	if length < 2.0:
		return
	var u := Vector2(sin(a), -cos(a))
	var p := Vector2(cos(a), sin(a))
	var tip_len := minf(w * 1.35, length * 0.45)
	var sh := base + u * (length - tip_len)
	var apex := base + u * length
	# Cross-section offsets of the three visible faces (left narrow, front wide, right narrow).
	var b0 := base + p * -w
	var b1 := base + p * (-w * 0.35)
	var b2 := base + p * (w * 0.45)
	var b3 := base + p * w
	# Outer shoulders sit lower than the front ones so the point reads as cut facets.
	var s0 := sh + p * -w - u * w * 0.35
	var s1 := sh + p * (-w * 0.35)
	var s2 := sh + p * (w * 0.45)
	var s3 := sh + p * w - u * w * 0.3

	# Buried dark foot.
	var down := -u * w * 0.35
	_quad(b0 + down, b3 + down, b3, b0, pal.deep)
	_quad(b0, b1, s1, s0, pal.left)
	_quad(b1, b2, s2, s1, pal.front)
	_quad(b2, b3, s3, s2, pal.right)
	_tri(s0, s1, apex, pal.tip_l)
	_tri(s1, s2, apex, pal.tip_f)
	_tri(s2, s3, apex, pal.tip_r)

	# Edges and highlights.
	var hi: Color = pal.hi
	draw_line(b0.round(), s0.round(), pal.edge, -1.0)
	draw_line(s0.round(), apex.round(), pal.edge, -1.0)
	draw_line(b3.round(), s3.round(), pal.edge, -1.0)
	draw_line(s1.round(), apex.round(), hi, -1.0)
	var streak_a := b1.lerp(b2, 0.28) + u * w * 0.4
	var streak_b := s1.lerp(s2, 0.28) - u * w * 0.2
	draw_line(streak_a.round(), streak_b.round(), hi, -1.0)
	draw_line(s1.round(), s2.round(), Color(hi, hi.a * 0.7), -1.0)

	if shatter > 0.05 and length > 10.0:
		for k in 2:
			var cu := fposmod(sin(seed * 3.3 + index * 5.7 + k * 1.9) * 9171.3, 1.0)
			var q0 := b1.lerp(b2, cu).lerp(s1.lerp(s2, cu), 0.3)
			draw_line(q0.round(), (q0 + u * length * 0.35 + p * (cu - 0.5) * w).round(), hi, -1.0)

	# Star glint near the shoulder of the main crystal.
	if is_main and fmod(_time * 1.3 + seed, 2.2) < 0.2:
		var gp := s1.lerp(s2, 0.3).round()
		draw_line(gp + Vector2(-3, 0), gp + Vector2(3, 0), hi, -1.0)
		draw_line(gp + Vector2(0, -3), gp + Vector2(0, 3), hi, -1.0)
		draw_rect(Rect2(gp + Vector2(-1, -1), Vector2(3, 3)), hi)


func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col, col, col]), PackedVector2Array())


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c, d]), PackedColorArray([col, col, col, col]), PackedVector2Array())


## Screen point at the middle of the main crystal (for shatter debris).
func mid_point() -> Vector2:
	var u := Vector2(sin(angle), -cos(angle))
	return position + u * height * grow * 0.5


func _shade(c: Color, amb: float, lit: Color, boost: float, a: float) -> Color:
	return Color(minf(c.r * amb * boost + lit.r * 0.18, 1.0), minf(c.g * amb * boost + lit.g * 0.18, 1.0),
		minf(c.b * amb * boost + lit.b * 0.18, 1.0), a)
