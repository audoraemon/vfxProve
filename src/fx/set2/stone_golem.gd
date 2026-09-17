class_name StoneGolem
extends Node2D
## Ancient stone titan's hunched upper body rising out of the ground, facing the viewer: a broad torso of
## angular sandstone plates, boulder shoulders with the skull-like head sunk between them, and massive
## segmented arms ending in knuckled fists. Each part is a patch of jittered plates separated by dark
## cracks, lit from above and rimmed gold from the rune light below. When it crumbles, plates drop apart.
## Positioned on its ground point (screen). Arms reach toward fist targets (local screen px).

const PAL := [Color("241c14"), Color("4a3c2e"), Color("6c5a44"), Color("8e7a5c"), Color("b19b76"), Color("d6c39a")]
const GOLD := Color("ffd060")
const GOLD_HOT := Color("fff6d0")
const UPPER_ARM := 100.0
const FOREARM := 108.0
const BURY_Y := 22.0
## Draw scale of the whole titan; fist targets and crown() stay in unscaled local screen px.
const SCALE := 0.8

## 0 buried .. 1 fully risen.
var emerge := 0.0
## Eye and rune glow 0..1.
var glow := 0.0
## Crumble 0..1 (plates sag and fall apart).
var crumble := 0.0
var fist_l := Vector2(-150, -40)
var fist_r := Vector2(150, -40)
var lights: LightField
var ground_pos := Vector2.ZERO
var _time := 0.0
var _tint := Color.WHITE
var _rise := 0.0
var _part := 0
## Plates below this local y are underground (cut). Fists planted in front sit lower than the torso base.
var _cut_y := BURY_Y


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Local point above the head where energy gathers for the final slam.
func crown() -> Vector2:
	return Vector2(0, -250) * SCALE


func _draw() -> void:
	if emerge <= 0.01:
		return
	var amb := maxf(lights.ambient, 0.62) if lights else 1.0
	var lit := lights.sample(ground_pos) if lights else Color.BLACK
	_tint = Color(amb + lit.r * 0.2, amb + lit.g * 0.2, amb + lit.b * 0.2)
	_rise = (1.0 - emerge) * 210.0 + sin(_time * 1.4) * 2.0 * emerge
	modulate.a = clampf(emerge * 2.0, 0.0, 1.0)
	_part = 0
	_cut_y = BURY_Y
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(SCALE, SCALE))
	var sh_l := Vector2(-112, -150)
	var sh_r := Vector2(112, -150)
	_torso()
	var arms := [[sh_l, fist_l / SCALE, -1.0], [sh_r, fist_r / SCALE, 1.0]]
	arms.sort_custom(func(a, b): return (a[1] as Vector2).y < (b[1] as Vector2).y)
	for arm in arms:
		_arm(arm[0], arm[1], arm[2])


func _torso() -> void:
	# Hips and belly sinking into the ground, broad chest, then boulder shoulders and the sunken head.
	_patch([Vector2(-58, -70), Vector2(58, -70), Vector2(52, 30), Vector2(-52, 30)], 3, 3, 0.45)
	_patch([Vector2(-96, -186), Vector2(96, -186), Vector2(64, -60), Vector2(-64, -60)], 4, 5, 0.62)
	if glow > 0.02:
		_runes(Vector2(0, -124))
	_patch([Vector2(-164, -206), Vector2(-84, -236), Vector2(-60, -134), Vector2(-142, -112)], 3, 3, 0.58)
	_patch([Vector2(84, -236), Vector2(164, -206), Vector2(142, -112), Vector2(60, -134)], 3, 3, 0.54)
	_head(Vector2(0, -172))


func _head(c: Vector2) -> void:
	# Skull block with a heavy brow, deep eye sockets, nose ridge and a squared jaw.
	_patch([c + Vector2(-34, -30), c + Vector2(34, -30), c + Vector2(30, 14), c + Vector2(-30, 14)], 2, 3, 0.6)
	_patch([c + Vector2(-24, 12), c + Vector2(24, 12), c + Vector2(20, 32), c + Vector2(-20, 32)], 1, 3, 0.42)
	var o := _offset(c + Vector2(0, -8))
	# Brow ridge overhang.
	_poly(PackedVector2Array([o + Vector2(-36, -16), o + Vector2(36, -16), o + Vector2(30, -8), o + Vector2(3, -2), o + Vector2(-3, -2),
		o + Vector2(-30, -8)]), PAL[0])
	_poly(PackedVector2Array([o + Vector2(-35, -18), o + Vector2(35, -18), o + Vector2(31, -12), o + Vector2(-31, -12)]), PAL[4] * _tint)
	var eye := GOLD_HOT.lerp(GOLD, 0.35)
	for sx in [-1.0, 1.0]:
		_poly(PackedVector2Array([o + Vector2(sx * 6, -7), o + Vector2(sx * 24, -9), o + Vector2(sx * 22, 3), o + Vector2(sx * 8, 3)]), PAL[0])
		if glow > 0.02:
			var e := Color(eye, 0.35 + 0.65 * glow)
			_poly(PackedVector2Array([o + Vector2(sx * 10, -4), o + Vector2(sx * 20, -6), o + Vector2(sx * 19, -1), o + Vector2(sx * 11, 0)]), e)
			if glow > 0.6:
				draw_rect(Rect2((o + Vector2(sx * 15 - 5, -6)).round(), Vector2(10, 1)), Color(GOLD_HOT, (glow - 0.6) * 2.0))
	# Nose ridge and mouth slit.
	_poly(PackedVector2Array([o + Vector2(-4, -3), o + Vector2(4, -3), o + Vector2(6, 12), o + Vector2(-6, 12)]), PAL[3] * _tint)
	_poly(PackedVector2Array([o + Vector2(-16, 22), o + Vector2(16, 22), o + Vector2(14, 25), o + Vector2(-14, 25)]), PAL[0])


func _runes(c: Vector2) -> void:
	var o := _offset(c)
	var g := Color(GOLD, glow)
	var h := Color(GOLD_HOT, glow * 0.8)
	for seg in [[Vector2(-6, -40), Vector2(4, -18)], [Vector2(4, -18), Vector2(-5, 4)], [Vector2(4, -18), Vector2(30, -10)],
			[Vector2(-5, 4), Vector2(10, 22)], [Vector2(-50, -20), Vector2(-24, -8)], [Vector2(-24, -8), Vector2(-5, 4)],
			[Vector2(30, -10), Vector2(48, 6)], [Vector2(10, 22), Vector2(6, 44)]]:
		for w in 2:
			draw_line((o + seg[0] + Vector2(w, 0)).round(), (o + seg[1] + Vector2(w, 0)).round(), g if w == 0 else h, -1.0)


func _arm(shoulder: Vector2, fist: Vector2, side: float) -> void:
	# Stable plate jitter per arm whichever is drawn first.
	_part = 100 if side < 0.0 else 200
	_cut_y = maxf(BURY_Y, fist.y + 34.0)
	# Two-bone arm; the elbow bends outward. Past full reach the segments stretch.
	var reach := shoulder.distance_to(fist)
	var dir := (fist - shoulder).normalized() if reach > 0.1 else Vector2(0, 1)
	var elbow: Vector2
	if reach >= UPPER_ARM + FOREARM:
		elbow = shoulder + dir * reach * UPPER_ARM / (UPPER_ARM + FOREARM)
	else:
		var a := (UPPER_ARM * UPPER_ARM + reach * reach - FOREARM * FOREARM) / (2.0 * reach)
		var h := sqrt(maxf(UPPER_ARM * UPPER_ARM - a * a, 0.0))
		var out := dir.orthogonal()
		if out.x * side < 0.0:
			out = -out
		elbow = shoulder + dir * a + out * h
	_limb(shoulder, elbow, 60.0, 50.0, 4)
	_limb(elbow, fist, 48.0, 62.0, 5)
	# Elbow boulder.
	_patch([elbow + Vector2(-26, -24), elbow + Vector2(26, -24), elbow + Vector2(24, 22), elbow + Vector2(-24, 22)], 2, 2, 0.55)
	# Fist: knuckled block with a thumb on the inside.
	var f := fist
	_patch([f + Vector2(-40, -26), f + Vector2(40, -26), f + Vector2(36, 30), f + Vector2(-36, 30)], 2, 3, 0.56)
	for k in 4:
		var kx := -30.0 + k * 20.0
		_patch([f + Vector2(kx - 10, -40), f + Vector2(kx + 10, -40), f + Vector2(kx + 11, -18), f + Vector2(kx - 11, -18)], 1, 1, 0.66)
	var th := f + Vector2(-side * 36, 4)
	_patch([th + Vector2(-12, -14), th + Vector2(12, -14), th + Vector2(10, 16), th + Vector2(-10, 16)], 2, 1, 0.48)
	if glow > 0.3:
		var o := _offset(f)
		draw_line((o + Vector2(-34, 24)).round(), (o + Vector2(34, 24)).round(), Color(GOLD, glow * 0.7), -1.0)


func _limb(a: Vector2, b: Vector2, wa: float, wb: float, rows: int) -> void:
	var n := (b - a).normalized().orthogonal()
	if n.x > 0.0:
		n = -n
	_patch([a + n * wa * 0.5, a - n * wa * 0.5, b - n * wb * 0.5, b + n * wb * 0.5], rows, 3, 0.52)


## Plated stone patch over a quad (tl, tr, br, bl): rows x cols jittered plates with crack gaps between
## them, shaded lighter toward the top-left, darker at the bottom, gold-rimmed from below when glowing.
func _patch(q: Array, rows: int, cols: int, tone: float) -> void:
	_part += 1
	var grid: Array[Vector2] = []
	for i in rows + 1:
		for j in cols + 1:
			var u := float(j) / cols
			var v := float(i) / rows
			var p: Vector2 = (q[0] as Vector2).lerp(q[1], u).lerp((q[3] as Vector2).lerp(q[2], u), v)
			if i > 0 and i < rows and j > 0 and j < cols:
				p += Vector2(_hash(i * 7 + j, 1) - 0.5, _hash(i * 7 + j, 2) - 0.5) * 16.0
			elif (i > 0 and i < rows) or (j > 0 and j < cols):
				# Edge points wobble outward a little so silhouettes read chunky, not ruled.
				p += Vector2(_hash(i * 7 + j, 3) - 0.5, _hash(i * 7 + j, 4) - 0.5) * 8.0
			grid.append(p)
	# Dark base (outline and crack color) over the whole patch, cut flat at the ground line.
	var ring := PackedVector2Array()
	for j in cols + 1:
		ring.append(grid[j])
	for i in range(1, rows + 1):
		ring.append(grid[i * (cols + 1) + cols])
	for j in range(cols - 1, -1, -1):
		ring.append(grid[rows * (cols + 1) + j])
	for i in range(rows - 1, 0, -1):
		ring.append(grid[i * (cols + 1)])
	var center := Vector2.ZERO
	for p in ring:
		center += p
	center /= ring.size()
	if crumble < 0.3:
		var base := PackedVector2Array()
		for p in ring:
			base.append(_ground_cut(_offset(p + (p - center).normalized() * 1.5)))
		if not Geometry2D.triangulate_polygon(base).is_empty():
			draw_colored_polygon(base, PAL[0] * Color(_tint, 1.0))
	for i in rows:
		for j in cols:
			var a := grid[i * (cols + 1) + j]
			var b := grid[i * (cols + 1) + j + 1]
			var c := grid[(i + 1) * (cols + 1) + j + 1]
			var d := grid[(i + 1) * (cols + 1) + j]
			var mid := (a + b + c + d) * 0.25
			var drop := _drop(mid, i * 13 + j)
			if _offset(mid).y + drop.y > _cut_y:
				continue
			var u := (j + 0.5) / cols
			var v := (i + 0.5) / rows
			var shade := tone + (1.0 - v) * 0.16 - v * 0.08 + (0.5 - u) * 0.08 + (_hash(i * 5 + j, 5) - 0.5) * 0.24
			var gold := glow * 0.25 * clampf((v - 0.55) / 0.45, 0.0, 1.0)
			var corners: Array[Vector2] = []
			var inner: Array[Vector2] = []
			for k in [a, b, c, d]:
				var outer: Vector2 = mid + (k - mid) * 0.94 - (k - mid).normalized() * 0.8
				corners.append(_ground_cut(_offset(outer) + drop))
				inner.append(_ground_cut(_offset(mid + (outer - mid) * 0.72) + drop))
			# Bevelled block: dark lower-right facet, lit upper-left facet, then the face.
			# Convex quads only (draw_primitive), no per-plate triangulation.
			_quad(corners[0], corners[1], corners[2], corners[3], _plate_col(shade - 0.24, gold))
			var lit := _plate_col(shade + 0.2, gold)
			_quad(corners[0], corners[1], inner[1], inner[0], lit)
			_quad(corners[0], inner[0], inner[3], corners[3], lit)
			_quad(inner[0], inner[1], inner[2], inner[3], _plate_col(shade, gold))
			# Weathering: a hairline crack running in from one edge on some plates.
			var hk := _hash(i * 3 + j * 11, 6)
			if hk > 0.55:
				var from: Vector2 = inner[int(hk * 40.0) % 4].lerp(inner[(int(hk * 40.0) + 1) % 4], 0.5)
				var to := from.lerp((inner[0] + inner[2]) * 0.5, 0.7) + Vector2(hk * 6.0 - 3.0, 2.0)
				draw_line(from.round(), to.round(), _plate_col(shade - 0.35, 0.0), -1.0)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	draw_primitive(PackedVector2Array([a, b, c, d]), PackedColorArray([col, col, col, col]), PackedVector2Array())


func _plate_col(shade: float, gold: float) -> Color:
	var col := _pal(shade)
	if gold > 0.0:
		col = col.lerp(GOLD, gold)
	col = col * Color(_tint, 1.0)
	if crumble > 0.0:
		col.a = 1.0 - smoothstep(0.6, 1.0, crumble)
	return col


func _ground_cut(p: Vector2) -> Vector2:
	return Vector2(p.x, minf(p.y, _cut_y))


func _offset(p: Vector2) -> Vector2:
	return p + Vector2(0, _rise)


## Crumble displacement for a plate: falls with gravity and spreads outward, staggered per plate.
func _drop(p: Vector2, k: int) -> Vector2:
	if crumble <= 0.0:
		return Vector2.ZERO
	var delay := _hash(k, 9) * 0.4
	var c := clampf((crumble - delay) / (1.0 - delay), 0.0, 1.0)
	var fall := c * c * (60.0 + _hash(k, 10) * 120.0) * (1.0 + maxf(-p.y, 0.0) / 200.0)
	return Vector2(p.x * c * 0.25 + (_hash(k, 11) - 0.5) * 30.0 * c, fall)


func _pal(shade: float) -> Color:
	return PAL[clampi(int(round(clampf(shade, 0.0, 1.0) * (PAL.size() - 1))), 0, PAL.size() - 1)]


func _hash(k: int, salt: int) -> float:
	return float(absi((k * 73856093) ^ ((_part * 131 + salt) * 19349663)) % 1000) / 1000.0


func _poly(pts: PackedVector2Array, col: Color) -> void:
	var out := PackedVector2Array()
	var drop := _drop(Vector2(0, -180), 0)
	for p in pts:
		out.append(p + drop)
	if crumble > 0.6:
		return
	draw_colored_polygon(out, col)
