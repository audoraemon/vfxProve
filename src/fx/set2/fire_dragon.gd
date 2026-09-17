class_name FireDragon
extends Node2D
## Colossal fire dragon rising out of the ground, seen in three-quarter profile: a continuous S-curved
## scaled neck with a pale plated belly and flame-tipped dorsal spikes, a horned profile head with a hinged
## jaw, and bat wings with finger bones, membranes and burning trailing edges.
## Everything is one triangle mesh shaded by `dragon_skin.gdshader`; vertex COLOR = (shade, heat, material,
## alpha). Positioned on its ground point; `aim` is the local screen point the head looks at.

const SH_SKIN := preload("res://shaders/dragon_skin.gdshader")
const HEIGHT := 170.0
const HEAD_SIZE := 1.6
const SEGMENTS := 36
# Materials (vertex COLOR.b).
const M_SCALES := 0.0
const M_BELLY := 0.25
const M_MEMBRANE := 0.5
const M_FLAT := 0.75
const M_GLOW := 1.0
const OUTLINE := 1.5

var rise := 0.0
var jaw := 0.0
var wings := 0.0
var fade := 1.0
var aim := Vector2(80, 0)
## +1 faces screen right, -1 left. 0 = pick from `aim` on first draw.
var facing := 0.0

var _time := 0.0
var _mat: ShaderMaterial
var _pts := PackedVector2Array()
var _cols := PackedColorArray()
var _uvs := PackedVector2Array()
var _idx := PackedInt32Array()


func _init() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = SH_SKIN
	material = _mat


func _process(delta: float) -> void:
	_time += delta
	_mat.set_shader_parameter(&"u_time", _time)
	_mat.set_shader_parameter(&"fade", fade)
	queue_redraw()


func _f() -> float:
	if facing == 0.0:
		facing = 1.0 if aim.x >= 0.0 else -1.0
	return facing


## Point on the spine at fraction s (0 ground .. 1 neck top) of the risen body.
func spine_point(s: float) -> Vector2:
	var f := _f()
	var sway := sin(_time * 1.5 + s * 2.2) * 4.0 * s
	var lean := clampf(aim.x, -160.0, 160.0) * 0.1 * s * s * s
	var x := f * sin(s * PI * 1.5 + 0.25) * 30.0 * (1.0 - 0.45 * s) + sway + lean
	return Vector2(x, -s * HEIGHT * clampf(rise, 0.0, 1.0))


func _radius(s: float) -> float:
	return lerpf(26.0, 11.0, pow(s, 0.8))


func head_pos() -> Vector2:
	return spine_point(1.0)


func _head_angle() -> float:
	var f := _f()
	var d := aim - head_pos()
	return clampf(atan2(d.y, d.x * f), -0.6, 0.8)


## Head-local point (x forward, y down, before HEAD_SIZE) to this node's space.
func _hp(p: Vector2) -> Vector2:
	var f := _f()
	return head_pos() + Vector2(p.x * f, p.y).rotated(_head_angle() * f) * HEAD_SIZE


func mouth_pos() -> Vector2:
	return _hp(Vector2(48, 3))


# --- Mesh building -------------------------------------------------------------

func _vert(p: Vector2, shade: float, heat: float, mat: float, uv := Vector2.ZERO, alpha := 1.0) -> int:
	_pts.append(p)
	_cols.append(Color(clampf(shade, 0.0, 1.0), heat, mat, alpha))
	_uvs.append(uv)
	return _pts.size() - 1


func _tri(a: int, b: int, c: int) -> void:
	_idx.append_array([a, b, c])


## Filled polygon (concave allowed) with one shade, UVs from position.
func _poly(points: PackedVector2Array, shade: float, heat: float, mat: float, alpha := 1.0) -> void:
	var tris := Geometry2D.triangulate_polygon(points)
	if tris.is_empty():
		return
	var start := _pts.size()
	for p in points:
		_vert(p, shade, heat, mat, p / 5.0, alpha)
	for i in tris:
		_idx.append(start + i)


func _inflate(points: PackedVector2Array, px: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in points:
		c += p
	c /= points.size()
	var out := PackedVector2Array()
	for p in points:
		var d := p - c
		out.append(c + d + d.normalized() * px)
	return out


## Polygon with a dark outline behind it.
func _outlined(points: PackedVector2Array, shade: float, heat: float, mat: float) -> void:
	_poly(_inflate(points, OUTLINE), 0.0, 0.0, M_FLAT)
	_poly(points, shade, heat, mat)


## Tapered quad from a to b (bones, horns).
func _limb(a: Vector2, b: Vector2, wa: float, wb: float, shade_a: float, shade_b: float, heat: float, outline := true) -> void:
	var n := (b - a).normalized().orthogonal()
	if outline:
		var e := (b - a).normalized() * OUTLINE
		_quad(a - e + n * (wa * 0.5 + OUTLINE), a - e - n * (wa * 0.5 + OUTLINE), b + e - n * (wb * 0.5 + OUTLINE),
			b + e + n * (wb * 0.5 + OUTLINE), 0.0, 0.0, 0.0)
	_quad(a + n * wa * 0.5, a - n * wa * 0.5, b - n * wb * 0.5, b + n * wb * 0.5, shade_a, shade_b, heat)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, shade_ab: float, shade_cd: float, heat: float) -> void:
	var i0 := _vert(a, shade_ab, heat, M_FLAT)
	var i1 := _vert(b, shade_ab, heat, M_FLAT)
	var i2 := _vert(c, shade_cd, heat, M_FLAT)
	var i3 := _vert(d, shade_cd, heat, M_FLAT)
	_tri(i0, i1, i2)
	_tri(i0, i2, i3)


## Flickering flame tongue from base (width w) out along dir.
func _flame(base: Vector2, dir: Vector2, length: float, w: float, phase: float) -> void:
	var l := length * (0.8 + 0.25 * sin(_time * 13.0 + phase) + 0.1 * sin(_time * 29.0 + phase * 2.0))
	var n := dir.orthogonal()
	var bend := n * sin(_time * 7.0 + phase) * l * 0.2
	var a := _vert(base + n * w * 0.5, 0.45, 1.0, M_FLAT)
	var b := _vert(base - n * w * 0.5, 0.45, 1.0, M_FLAT)
	var m := _vert(base + dir * l * 0.5 + bend * 0.5, 0.8, 1.0, M_FLAT)
	var tip := _vert(base + dir * l + bend, 0.95, 1.0, M_FLAT)
	_tri(a, b, m)
	_tri(a, m, tip)
	_tri(b, tip, m)


func _draw() -> void:
	if rise <= 0.01 or fade <= 0.0:
		return
	_pts.clear()
	_cols.clear()
	_uvs.clear()
	_idx.clear()
	if wings > 0.01:
		var shoulder := spine_point(0.6) + _back_normal(0.6) * _radius(0.6) * 0.5
		# Far wing peeks out behind the head, the near wing spreads back behind the body.
		_draw_wing(shoulder + Vector2(_f() * 10.0, -14.0), _f(), wings * 0.6, 0.7, 1.3)
		_draw_wing(shoulder, -_f(), wings, 1.0, 0.0)
	_draw_body()
	_draw_head()
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _idx, _pts, _cols, _uvs)


## Normal pointing to the dragon's back (away from where it faces).
func _back_normal(s: float) -> Vector2:
	var t := (spine_point(minf(s + 0.02, 1.0)) - spine_point(maxf(s - 0.02, 0.0))).normalized()
	if t == Vector2.ZERO:
		t = Vector2(0, -1)
	return t.orthogonal() * _f()


func _draw_body() -> void:
	# Across the tube: -1 back edge .. +1 belly edge. Back is scaled, belly has pale plates.
	var across := [-1.0, -0.55, -0.1, 0.25, 0.25, 0.65, 1.0]
	var spine: Array[Vector2] = []
	var normals: Array[Vector2] = []
	var radii: Array[float] = []
	var arc := 0.0
	var arcs: Array[float] = []
	for i in SEGMENTS + 1:
		var s := float(i) / SEGMENTS
		var p := spine_point(s)
		if i > 0:
			arc += p.distance_to(spine[i - 1])
		spine.append(p)
		normals.append(_back_normal(s))
		radii.append(_radius(s))
		arcs.append(arc)
	# Dorsal spikes first so the body covers their roots.
	for i in range(2, SEGMENTS + 1, 2):
		var s := float(i) / SEGMENTS
		var n: Vector2 = normals[i]
		var t := (spine[mini(i + 1, SEGMENTS)] - spine[i - 1]).normalized()
		var size: float = radii[i] * (1.0 + 1.3 * s)
		var base: Vector2 = spine[i] + n * radii[i] * 0.75
		var tip := base + (n * 1.0 - t * 0.55).normalized() * size
		var sa := _vert(base + t * size * 0.32, 0.25, 0.4, M_FLAT)
		var sb := _vert(base - t * size * 0.32, 0.25, 0.4, M_FLAT)
		var st := _vert(tip, 0.7, 0.8, M_FLAT)
		_tri(sa, sb, st)
		_flame(tip - (tip - base) * 0.15, (tip - base).normalized(), size * 0.55, size * 0.3, i * 1.7)
	# Outline tube.
	_strip(spine, normals, radii, arcs, [-1.0, 1.0], OUTLINE, true)
	_strip(spine, normals, radii, arcs, across, 0.0, false)


## Quad strip along the spine across the listed offsets. Outline strips are flat dark.
func _strip(spine: Array[Vector2], normals: Array[Vector2], radii: Array[float], arcs: Array[float], across: Array,
		grow: float, outline: bool) -> void:
	var cols := across.size()
	var start := _pts.size()
	for i in spine.size():
		var s := float(i) / SEGMENTS
		for k in cols:
			var v: float = across[k]
			var p: Vector2 = spine[i] - normals[i] * v * (radii[i] + grow)
			if outline:
				_vert(p, 0.0, 0.0, M_FLAT)
				continue
			var belly := k >= 4
			var shade: float
			if belly:
				shade = 0.54 + 0.14 * (1.0 - absf(v - 0.6) * 2.0)
			else:
				shade = 0.2 + 0.26 * (1.0 - absf(v + 0.1))
			# Rim light on the back edge from the flames.
			if v <= -0.99:
				shade = 0.42
			var uv := Vector2(arcs[i] / 11.0, v * radii[i] / 8.0)
			_vert(p, shade, 0.45 + 0.3 * s, M_BELLY if belly else M_SCALES, uv)
	for i in spine.size() - 1:
		for k in cols - 1:
			if not outline and k == 3:
				continue
			var a := start + i * cols + k
			_tri(a, a + 1, a + cols)
			_tri(a + 1, a + cols + 1, a + cols)


func _draw_head() -> void:
	var open := jaw * 0.45
	var hinge := Vector2(4, 4)
	var jaw_pts := [Vector2(2, 3), Vector2(26, 5), Vector2(44, 5), Vector2(47, 8), Vector2(36, 12), Vector2(14, 15), Vector2(-4, 12)]
	var lower := PackedVector2Array()
	for p in jaw_pts:
		lower.append(_hp(hinge + (p - hinge).rotated(open)))
	# Horns and cheek frills behind the skull.
	var horns := [
		[Vector2(0, -9), Vector2(-8, -14), Vector2(-28, -20), Vector2(-54, -22), Vector2(-30, -12), Vector2(-10, -4)],
		[Vector2(8, -13), Vector2(0, -18), Vector2(-18, -28), Vector2(-40, -40), Vector2(-16, -22), Vector2(0, -11)],
	]
	for h in horns:
		var poly := PackedVector2Array()
		for p in h:
			poly.append(_hp(p))
		_outlined(poly, 0.55, 0.3, M_FLAT)
	for k in 4:
		var root := _hp(Vector2(-4 + k * 3, -2 + k * 5))
		var out := (_hp(Vector2(-30 + k * 2, -6 + k * 9)) - root)
		_flame(root, out.normalized(), out.length(), 7.0, k * 2.3)
	# Lower jaw, mouth fire, teeth.
	_outlined(lower, 0.32, 0.3, M_FLAT)
	if jaw > 0.05:
		# Mouth interior: dark throat with fire welling up between the jaws.
		_poly(PackedVector2Array([_hp(hinge + Vector2(-2, -1)), _hp(Vector2(47, 1)), lower[2], lower[1]]), 0.1, 0.0, M_FLAT)
		_poly(PackedVector2Array([_hp(hinge + Vector2(4, 0)), _hp(Vector2(40, 2)), _hp(hinge + (Vector2(36, 5) - hinge).rotated(open))]),
			0.85, 1.0, M_GLOW)
		for k in 5:
			var x := 16.0 + k * 6.0
			_poly(PackedVector2Array([_hp(Vector2(x, 2.5)), _hp(Vector2(x + 3.0, 2.5)), _hp(Vector2(x + 1.5, 7.0))]), 1.0, 0.0, M_FLAT)
			var lp := hinge + (Vector2(x, 5.0) - hinge).rotated(open)
			var lq := hinge + (Vector2(x + 3.0, 5.0) - hinge).rotated(open)
			var lt := hinge + (Vector2(x + 1.5, 1.0) - hinge).rotated(open)
			_poly(PackedVector2Array([_hp(lp), _hp(lq), _hp(lt)]), 1.0, 0.0, M_FLAT)
	# Skull and snout.
	var skull_pts := [Vector2(-12, -3), Vector2(-5, -12), Vector2(8, -16), Vector2(18, -12), Vector2(32, -9), Vector2(46, -6),
		Vector2(51, -2), Vector2(49, 2), Vector2(30, 3), Vector2(8, 5), Vector2(-6, 7)]
	var skull := PackedVector2Array()
	for p in skull_pts:
		skull.append(_hp(p))
	_outlined(skull, 0.42, 0.35, M_FLAT)
	# Lit snout ridge and brow plates.
	_poly(PackedVector2Array([_hp(Vector2(8, -15)), _hp(Vector2(18, -11)), _hp(Vector2(45, -5)), _hp(Vector2(30, -6)), _hp(Vector2(10, -10))]),
		0.78, 0.4, M_FLAT)
	for k in 3:
		var bx := 2.0 + k * 9.0
		_poly(PackedVector2Array([_hp(Vector2(bx, -13 + k)), _hp(Vector2(bx + 6, -13 + k)), _hp(Vector2(bx - 4, -21 + k * 2))]), 0.35, 0.5, M_FLAT)
	# Brow, glowing eye, nostril.
	_poly(PackedVector2Array([_hp(Vector2(10, -11)), _hp(Vector2(25, -12)), _hp(Vector2(24, -9)), _hp(Vector2(11, -9))]), 0.0, 0.0, M_FLAT)
	var blink := 0.0 if int(_time * 5.0) % 17 == 0 else 1.0
	_poly(PackedVector2Array([_hp(Vector2(13, -8.5)), _hp(Vector2(23, -9.5)), _hp(Vector2(20, -6.5)), _hp(Vector2(14, -6.5))]),
		0.95 * blink, 1.0, M_GLOW)
	_poly(PackedVector2Array([_hp(Vector2(42, -5)), _hp(Vector2(46, -5)), _hp(Vector2(44, -2.5))]), 0.0, 0.0, M_FLAT)


## Bat wing unfolding from `shoulder` toward screen side `side` (+1 right). `shade_mul` darkens the far wing.
func _draw_wing(shoulder: Vector2, side: float, spread: float, shade_mul: float, phase: float) -> void:
	if spread <= 0.01:
		return
	var flap := sin(_time * 2.4 + phase) * 0.12
	var tip_spread := pow(clampf(spread, 0.0, 1.2), 1.4)
	var wp := func(p: Vector2, k: float) -> Vector2:
		var q := Vector2(p.x * side, p.y).rotated(flap * side) * lerpf(spread, tip_spread, k)
		return shoulder + q
	var elbow: Vector2 = wp.call(Vector2(40, -46), 0.3)
	var wrist: Vector2 = wp.call(Vector2(70, -104), 0.5)
	var tips: Array[Vector2] = []
	for p in [Vector2(78, -150), Vector2(134, -128), Vector2(166, -76), Vector2(156, -18), Vector2(116, 26)]:
		tips.append(wp.call(p, 1.0))
	var body_attach := spine_point(0.28) + _back_normal(0.28) * _radius(0.28) * 0.4
	# Membranes: panels between fingers with scalloped trailing edges, then the panel back to the body.
	for k in tips.size() - 1:
		var poly := PackedVector2Array([wrist, tips[k]])
		poly.append_array(_scallop(tips[k], tips[k + 1], wrist))
		poly.append(tips[k + 1])
		_membrane(poly, wrist, shade_mul)
	var last := PackedVector2Array([shoulder, elbow, wrist, tips[tips.size() - 1]])
	var sc := _scallop(tips[tips.size() - 1], body_attach, wrist)
	last.append_array(sc)
	last.append(body_attach)
	_membrane(last, wrist, shade_mul)
	# Burning trailing edge.
	for k in tips.size() - 1:
		var mid := (tips[k] + tips[k + 1]) * 0.5
		var out := (mid - wrist).normalized()
		_flame(mid - out * 10.0, out, 16.0 * spread, 8.0, phase + k * 1.9)
	# Bones: arm, fingers, claw.
	_limb(shoulder, elbow, 7.0, 5.0, 0.5 * shade_mul, 0.58 * shade_mul, 0.3)
	_limb(elbow, wrist, 5.0, 4.0, 0.58 * shade_mul, 0.66 * shade_mul, 0.3)
	for k in tips.size():
		_limb(wrist, tips[k], 3.5, 1.2, 0.62 * shade_mul, 0.82 * shade_mul, 0.4, false)
	_limb(wrist, wrist + (tips[0] - wrist).normalized().rotated(-0.5 * side) * 12.0, 3.0, 0.5, 0.9, 1.0, 0.0, false)


func _scallop(a: Vector2, b: Vector2, toward: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var mid := (a + b) * 0.5
	for i in [0.25, 0.5, 0.75]:
		out.append(a.lerp(b, i) + (toward - mid) * 0.22 * sin(PI * i))
	return out


func _membrane(poly: PackedVector2Array, root: Vector2, shade_mul: float) -> void:
	var tris := Geometry2D.triangulate_polygon(poly)
	if tris.is_empty():
		return
	var start := _pts.size()
	var reach := 1.0
	for p in poly:
		reach = maxf(reach, p.distance_to(root))
	for p in poly:
		var k := p.distance_to(root) / reach
		_vert(p, (0.3 + 0.25 * k) * shade_mul, 0.2 + 0.8 * k * k, M_MEMBRANE, p / 6.0, 0.93)
	for i in tris:
		_idx.append(start + i)
