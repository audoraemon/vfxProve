class_name IceSpike
extends Node2D
## Ice crystal group standing on a ground point (y-sorted in the world layer).
## Style SHARD (mountain): slender triangular shards with dark slate-blue shaded faces, a pale lit face,
## a white ridge and a glowing white rim, grouped 2-3 per node pointing roughly the same way.
## Style PRISM (explosion star): hexagonal prism with faceted point.
## `grow` drives the rise (overshoot allowed); `shatter` shortens and cracks it into residue.

enum Style { SHARD, PRISM }

# Shard palette (concept sheet: dark translucent cores, luminous edges).
const SH_CORE := Color("1a2d52")
const SH_DARK := Color("2c4c82")
const SH_MID := Color("4f7fc0")
const SH_LIGHT := Color("9cc8f2")
const SH_RIM := Color("dff2ff")
# Prism palette.
const PR_EDGE := Color("145a96")
const PR_LEFT := Color("2a8fd0")
const PR_RIGHT := Color("6cc4ec")
const PR_FRONT := Color("d4f1fb")
const PR_TIP_L := Color("a8def5")
const PR_TIP_R := Color("4aaee0")
const PR_TIP_F := Color("f2fcff")
const DEEP := Color("0f2a4f")
const HI := Color("ffffff")

## Main crystal length and half width in px.
var height := 60.0
var width := 10.0
## Main crystal tilt in radians (0 = straight up, positive leans right).
var angle := 0.0
var style := Style.SHARD
## Extra shards grouped with the main one.
var cluster := true
var grow := 0.0
var shatter := 0.0
var glow := 0.0
var fade := 1.0
var seed := 0.0
var lights: LightField
var ground_pos := Vector2.ZERO

## Each crystal: [base offset px, angle, length, half width, draw order, is_main].
var _crystals: Array = []
var _time := 0.0
var _drawn := PackedFloat32Array()


func _ready() -> void:
	_build_crystals()


func _build_crystals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed * 1000.0) + 17
	_crystals.clear()
	_crystals.append([Vector2.ZERO, angle, height, width, 0, true])
	if not cluster:
		return
	# Companion shards beside the main one, slightly shorter and pointing nearly the same way.
	var extra := rng.randi_range(1, 2)
	for i in extra:
		var sgn := -1.0 if (i + int(seed)) % 2 == 0 else 1.0
		var off := Vector2(sgn * width * rng.randf_range(0.9, 1.6), rng.randf_range(-1.0, 4.0))
		_crystals.append([off, angle + sgn * rng.randf_range(0.08, 0.3), height * rng.randf_range(0.45, 0.8),
			width * rng.randf_range(0.6, 0.9), 1 if off.y > 1.5 else -1, false])
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
	var boost := 1.0 + glow * 0.18
	var shrink := 1.0 - shatter * 0.78
	for c in _crystals:
		var is_main: bool = c[5]
		# Companions lag the main shard slightly as they grow.
		var g := clampf(grow if is_main else grow * 1.15 - 0.15, 0.0, 1.6)
		var length: float = c[2] * g * shrink
		var w: float = c[3] * clampf(0.6 + g * 0.4, 0.0, 1.2)
		if style == Style.PRISM:
			_draw_prism(c[0], c[1], length, w, amb, lit, boost, alpha, is_main)
		else:
			_draw_shard(c[0], c[1], length, w, amb, lit, boost, alpha, is_main)


## Tapering triangular shard: shadowed left face with a dark core, pale right face, white ridge, glowing rim.
func _draw_shard(base: Vector2, a: float, length: float, w: float, amb: float, lit: Color, boost: float,
		alpha: float, is_main: bool) -> void:
	if length < 2.0:
		return
	var u := Vector2(sin(a), -cos(a))
	var p := Vector2(cos(a), sin(a))
	var skew := (fposmod(seed * 7.3, 1.0) - 0.5) * 0.3
	var bl := base - p * w
	var br := base + p * w * 0.9
	var ridge := base + p * w * (0.1 + skew * 0.5) + u * minf(w * 0.3, length * 0.1)
	var apex := base + u * length + p * w * skew
	var knee := bl.lerp(apex, 0.42) - p * w * 0.12

	var c_core := _shade(SH_CORE, amb, lit, boost, alpha)
	var c_dark := _shade(SH_DARK, amb, lit, boost, alpha)
	var c_mid := _shade(SH_MID, amb, lit, boost, alpha)
	var c_light := _shade(SH_LIGHT, amb, lit, boost, alpha)
	_tri(bl, ridge, knee, c_dark)
	_tri(knee, ridge, apex, c_mid)
	_tri(ridge, br, apex, c_light)
	# Dark translucent core running up the shadow side.
	var core_a := ridge.lerp(bl, 0.35)
	_tri(core_a, ridge, ridge.lerp(apex, 0.55), c_core)
	# Buried dark foot.
	_quad(bl - u * w * 0.25, br - u * w * 0.25, br, bl, _shade(DEEP, amb, lit, boost, alpha * 0.9))

	var rim := Color(SH_RIM, alpha * clampf(0.6 + glow * 0.35, 0.0, 1.0))
	draw_line(bl.round(), knee.round(), rim, -1.0)
	draw_line(knee.round(), apex.round(), rim, -1.0)
	draw_line(apex.round(), br.round(), Color(SH_LIGHT, alpha * 0.6), -1.0)
	draw_line(ridge.round(), apex.round(), Color(HI, alpha), -1.0)
	if w >= 7.0:
		draw_line(bl.lerp(ridge, 0.5).round(), knee.lerp(apex, 0.4).round(), Color(SH_LIGHT, alpha * 0.55), -1.0)

	if shatter > 0.05 and length > 10.0:
		var cu := fposmod(sin(seed * 3.3) * 9171.3, 1.0)
		var q0 := ridge.lerp(apex, 0.2)
		draw_line(q0.round(), (q0 + u * length * 0.3 + p * (cu - 0.5) * w).round(), Color(HI, alpha), -1.0)

	if is_main and fmod(_time * 1.3 + seed, 2.2) < 0.2:
		_glint(apex.lerp(ridge, 0.25), alpha)


func _draw_prism(base: Vector2, a: float, length: float, w: float, amb: float, lit: Color, boost: float,
		alpha: float, is_main: bool) -> void:
	if length < 2.0:
		return
	var u := Vector2(sin(a), -cos(a))
	var p := Vector2(cos(a), sin(a))
	var tip_len := minf(w * 1.35, length * 0.45)
	var sh := base + u * (length - tip_len)
	var apex := base + u * length
	var b0 := base + p * -w
	var b1 := base + p * (-w * 0.35)
	var b2 := base + p * (w * 0.45)
	var b3 := base + p * w
	var s0 := sh + p * -w - u * w * 0.35
	var s1 := sh + p * (-w * 0.35)
	var s2 := sh + p * (w * 0.45)
	var s3 := sh + p * w - u * w * 0.3
	_quad(b0, b1, s1, s0, _shade(PR_LEFT, amb, lit, boost, alpha))
	_quad(b1, b2, s2, s1, _shade(PR_FRONT, amb, lit, boost, alpha))
	_quad(b2, b3, s3, s2, _shade(PR_RIGHT, amb, lit, boost, alpha))
	_tri(s0, s1, apex, _shade(PR_TIP_L, amb, lit, boost, alpha))
	_tri(s1, s2, apex, _shade(PR_TIP_F, amb, lit, boost, alpha))
	_tri(s2, s3, apex, _shade(PR_TIP_R, amb, lit, boost, alpha))
	var edge := _shade(PR_EDGE, amb, lit, boost, alpha)
	var hi := Color(HI, alpha)
	draw_line(b0.round(), s0.round(), edge, -1.0)
	draw_line(s0.round(), apex.round(), edge, -1.0)
	draw_line(b3.round(), s3.round(), edge, -1.0)
	draw_line(s1.round(), apex.round(), hi, -1.0)
	draw_line((b1.lerp(b2, 0.28) + u * w * 0.4).round(), (s1.lerp(s2, 0.28) - u * w * 0.2).round(), hi, -1.0)
	if is_main and fmod(_time * 1.3 + seed, 2.2) < 0.2:
		_glint(s1.lerp(s2, 0.3), alpha)


func _glint(at: Vector2, alpha: float) -> void:
	var gp := at.round()
	var hi := Color(HI, alpha)
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
