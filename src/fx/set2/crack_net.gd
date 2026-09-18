class_name CrackNet
extends Node2D
## Jagged glowing crack network on the ground: zig-zag cracks with side forks and splinters, drawn in screen pixels
## on the ground layer (see `place`): an additive orange glow bleeding onto the ground, a dark scorched rift, a
## molten fill and a white-hot core. The growth front runs white-hot while `progress` spreads it out; `heat` cools
## it to flickering embers and `charge` flickers blue lightning through it.

## Polylines: {pts: screen px from the centre, d: ground units from the centre along the cracks, w: width 0..1}.
var lines: Array[Dictionary] = []
## Distance from the centre the growth front reaches at `progress` 1.
var reach := 0.0
var progress := 0.0
var heat := 1.0
## White-hot growth front; faded out once the cracks have opened.
var hot := 1.0
var charge := 0.0
var fade := 1.0
## Draw the bright star where the cracks meet.
var star := true
## Once fully grown, redraw only every this many seconds (0 = every frame); for many small nets at once.
var redraw_every := 0.0
var _time := 0.0
var _redraw_in := 0.0
var _glow: Node2D
var _vis: Array[Dictionary] = []
var _vis_front := -1.0
## Strips for the current growth front (rift, molten fill, two glow bands) with each vertex's (distance, width),
## so colours refresh without rebuilding the geometry; rebuilt only when the front moves.
var _geo_front := -1.0
var _rift_v := PackedVector2Array()
var _rift_i := PackedInt32Array()
var _melt_v := PackedVector2Array()
var _melt_i := PackedInt32Array()
var _melt_dw := PackedVector2Array()
var _glow_v := PackedVector2Array()
var _glow_i := PackedInt32Array()
## (distance, width, band brightness) per glow vertex.
var _glow_dw := PackedVector3Array()
var _cores: Array[PackedVector2Array] = []


func _ready() -> void:
	_glow = Node2D.new()
	_glow.show_behind_parent = true
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.draw.connect(_draw_glow)
	add_child(_glow)


func _process(delta: float) -> void:
	_time += delta
	if redraw_every > 0.0 and progress >= 1.0:
		_redraw_in -= delta
		if _redraw_in > 0.0:
			return
		_redraw_in = redraw_every
	queue_redraw()
	_glow.queue_redraw()


## The parts of every polyline the growth front has reached (cached while the front stands still).
func _visible() -> Array[Dictionary]:
	var front := progress * reach
	if is_equal_approx(front, _vis_front):
		return _vis
	_vis_front = front
	_vis.clear()
	for line in lines:
		var pts: PackedVector2Array = line.pts
		var ds: PackedFloat32Array = line.d
		var ws: PackedFloat32Array = line.w
		var vp := PackedVector2Array()
		var vd := PackedFloat32Array()
		var vw := PackedFloat32Array()
		for i in pts.size():
			if ds[i] <= front:
				vp.append(pts[i])
				vd.append(ds[i])
				vw.append(ws[i])
				continue
			if i > 0:
				var k := (front - ds[i - 1]) / maxf(ds[i] - ds[i - 1], 0.0001)
				vp.append(pts[i - 1].lerp(pts[i], k))
				vd.append(front)
				vw.append(lerpf(ws[i - 1], ws[i], k))
			break
		if vp.size() >= 2:
			_vis.append({"pts": vp, "d": vd, "w": vw})
	return _vis


## Appends a mitred triangle strip with per-point widths (px) along a polyline: two vertices per point.
func _strip(pts: PackedVector2Array, widths: PackedFloat32Array, verts: PackedVector2Array, idx: PackedInt32Array) -> void:
	var n := pts.size()
	var base := verts.size()
	for i in n:
		var d1 := (pts[mini(i + 1, n - 1)] - pts[i]).normalized() if i < n - 1 else (pts[i] - pts[i - 1]).normalized()
		var d0 := (pts[i] - pts[i - 1]).normalized() if i > 0 else d1
		var tangent := d0 + d1
		tangent = tangent.normalized() if tangent.length_squared() > 0.0001 else d1
		var nrm := tangent.orthogonal()
		var miter := 1.0 / maxf(nrm.dot(d1.orthogonal()), 0.55)
		var off := nrm * widths[i] * 0.5 * miter
		verts.append(pts[i] + off)
		verts.append(pts[i] - off)
	for i in n - 1:
		var a := base + i * 2
		idx.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))


func _build_geometry(front: float) -> void:
	if is_equal_approx(front, _geo_front):
		return
	_geo_front = front
	_rift_v = PackedVector2Array()
	_rift_i = PackedInt32Array()
	_melt_v = PackedVector2Array()
	_melt_i = PackedInt32Array()
	_melt_dw = PackedVector2Array()
	_glow_v = PackedVector2Array()
	_glow_i = PackedInt32Array()
	_glow_dw = PackedVector3Array()
	_cores.clear()
	for vis in _visible():
		var pts: PackedVector2Array = vis.pts
		var ds: PackedFloat32Array = vis.d
		var ws: PackedFloat32Array = vis.w
		var rw := PackedFloat32Array()
		var mw := PackedFloat32Array()
		var wide := PackedFloat32Array()
		var narrow := PackedFloat32Array()
		for i in pts.size():
			rw.append(1.8 + 3.4 * ws[i])
			mw.append(0.9 + 2.3 * ws[i])
			wide.append(5.0 + 12.0 * ws[i])
			narrow.append(3.0 + 6.0 * ws[i])
		_strip(pts, rw, _rift_v, _rift_i)
		_strip(pts, mw, _melt_v, _melt_i)
		_strip(pts, wide, _glow_v, _glow_i)
		_strip(pts, narrow, _glow_v, _glow_i)
		for i in pts.size():
			var dw := Vector2(ds[i], ws[i])
			_melt_dw.append_array(PackedVector2Array([dw, dw]))
		for band in [0.5, 0.6]:
			for i in pts.size():
				var g := Vector3(ds[i], ws[i], band)
				_glow_dw.append_array(PackedVector3Array([g, g]))
		# White-hot core line down the wide part of the crack.
		var n := 0
		while n < pts.size() and ws[n] > 0.32:
			n += 1
		if n >= 2:
			_cores.append(pts.slice(0, n))


func _fresh(d: float, front: float) -> float:
	return clampf(1.0 - (front - d) / 0.9, 0.0, 1.0) * hot


func _molten(d: float, front: float, w: float) -> Color:
	var flick := 0.84 + 0.16 * sin(_time * 19.0 + d * 11.0) * sin(_time * 6.3 + d * 2.7)
	var h := heat * flick
	var c := Color(0.42, 0.08, 0.04).lerp(Color(1.0, 0.5, 0.1), clampf(h * 1.5 - 0.25, 0.0, 1.0))
	c = c.lerp(Color(1.0, 0.84, 0.42), clampf((h - 0.5) * 2.0, 0.0, 1.0) * clampf(w * 1.4, 0.0, 1.0))
	c = c.lerp(Color(1.0, 0.97, 0.88), _fresh(d, front))
	if charge > 0.0:
		var zap := 1.0 if fposmod(sin(floorf(_time * 24.0) * 12.9898 + d * 3.1) * 43758.5453, 1.0) > 0.5 else 0.0
		c = c.lerp(Color(0.72, 0.86, 1.0), charge * (0.1 + 0.35 * zap))
	c.a = fade * clampf(0.35 + heat * 1.5, 0.0, 1.0)
	return c


func _draw() -> void:
	if progress <= 0.0 or fade <= 0.0:
		return
	var front := progress * reach
	_build_geometry(front)
	var ci := get_canvas_item()
	if not _rift_i.is_empty():
		var rift_c := PackedColorArray()
		rift_c.resize(_rift_v.size())
		rift_c.fill(Color(0.07, 0.035, 0.03, 0.95 * fade))
		RenderingServer.canvas_item_add_triangle_array(ci, _rift_i, _rift_v, rift_c)
	if not _melt_i.is_empty():
		var melt_c := PackedColorArray()
		melt_c.resize(_melt_v.size())
		var k := 0
		while k < _melt_dw.size():
			var c := _molten(_melt_dw[k].x, front, _melt_dw[k].y)
			melt_c[k] = c
			melt_c[k + 1] = c
			k += 2
		RenderingServer.canvas_item_add_triangle_array(ci, _melt_i, _melt_v, melt_c)
	var core_a := clampf(heat * 1.5 - 0.45, 0.0, 1.0) * fade
	if core_a > 0.0:
		for core in _cores:
			draw_polyline(core, Color(1.0, 0.95, 0.74, core_a), -1.0)
	if star:
		_draw_star(front)


## Bright star where the cracks meet.
func _draw_star(front: float) -> void:
	var k := clampf(front / 0.6, 0.0, 1.0) * clampf(heat * 1.4 - 0.3, 0.0, 1.0) * fade
	if k <= 0.0:
		return
	for layer in 2:
		var s := 21.0 if layer == 0 else 9.0
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			var r := s * (1.0 if i % 4 == 0 else 0.55) if i % 2 == 0 else s * 0.2
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.55))
		var col := Color(1.0, 0.72, 0.3, 0.9 * k) if layer == 0 else Color(1.0, 0.97, 0.85, k)
		draw_colored_polygon(pts, col)


func _draw_glow() -> void:
	if progress <= 0.0 or fade <= 0.0:
		return
	var front := progress * reach
	_build_geometry(front)
	if _glow_i.is_empty():
		return
	var cols := PackedColorArray()
	cols.resize(_glow_v.size())
	var k := 0
	while k < _glow_dw.size():
		var g := _glow_dw[k]
		var b := ((0.24 + 0.3 * g.y) * heat + 0.3 * _fresh(g.x, front)) * fade
		var col := Color(b, 0.42 * b, 0.1 * b) + Color(0.3, 0.5, 1.0) * (0.3 * charge * g.y * fade)
		col = Color(col.r * g.z, col.g * g.z, col.b * g.z)
		cols[k] = col
		cols[k + 1] = col
		k += 2
	RenderingServer.canvas_item_add_triangle_array(_glow.get_canvas_item(), _glow_i, _glow_v, cols)


## Puts the net on the ground layer centred on ground point `at`, drawing in screen pixels from there.
func place(at: Vector2) -> void:
	transform = Iso.BASIS.affine_inverse()
	position = at


## Builds `count` long cracks radiating from the centre (starting at `base_angle`), each with side forks that
## sometimes split again, plus short splinters round the centre. `width` scales how wide the cracks start.
## Returns the main cracks as ground polylines from the centre.
func build_radial(rng: RandomNumberGenerator, count: int, length: float, base_angle: float, width := 1.0,
		splinters := 12, step := 0.24, forks := Vector2i(3, 5)) -> Array[PackedVector2Array]:
	var mains: Array[PackedVector2Array] = []
	for i in count:
		var a := base_angle + TAU * i / count + rng.randf_range(-0.1, 0.1)
		var main := crack_line(rng, Vector2.ZERO, a, length * rng.randf_range(0.86, 1.08), step, width, 0.15 * width, 0.0)
		lines.append(main)
		var g: PackedVector2Array = main.g
		var ds: PackedFloat32Array = main.d
		var ws: PackedFloat32Array = main.w
		mains.append(g)
		reach = maxf(reach, ds[ds.size() - 1])
		# Side forks, some splitting again.
		for f in rng.randi_range(forks.x, forks.y):
			var k := rng.randi_range(int(g.size() * 0.12), int(g.size() * 0.85))
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var fa := a + side * rng.randf_range(0.45, 1.05)
			var fork := crack_line(rng, g[k], fa, rng.randf_range(0.5, 1.5) * (1.0 - 0.45 * float(k) / g.size()) * length / 5.6,
				step / 1.5, ws[k] * 0.7, 0.06 * width, ds[k])
			lines.append(fork)
			var fg: PackedVector2Array = fork.g
			if rng.randf() < 0.45 and fg.size() > 3:
				var m := int(fg.size() * 0.5)
				var fws: PackedFloat32Array = fork.w
				var fds: PackedFloat32Array = fork.d
				lines.append(crack_line(rng, fg[m], fa - side * rng.randf_range(0.5, 0.95),
					rng.randf_range(0.3, 0.6) * length / 5.6, step * 0.54, fws[m] * 0.7, 0.05 * width, fds[m]))
	# Short splinters round the centre.
	for i in splinters:
		var a := base_angle + TAU * (i + 0.5) / splinters + rng.randf_range(-0.15, 0.15)
		lines.append(crack_line(rng, Vector2.ZERO, a, rng.randf_range(0.35, 0.95) * length / 5.6, step * 0.58, 0.6 * width,
			0.06 * width, 0.0))
	reach = maxf(reach, 0.01)
	return mains


## One jagged crack: zig-zag steps that mostly alternate sides around a slowly drifting heading.
## Returns {g: ground points from the centre, pts: screen px from the centre, d: distance from the centre, w: 0..1}.
static func crack_line(rng: RandomNumberGenerator, start: Vector2, angle: float, length: float, step: float, w0: float,
		w1: float, d0: float) -> Dictionary:
	var g := PackedVector2Array([start])
	var pts := PackedVector2Array([Iso.ground_to_screen(start)])
	var ds := PackedFloat32Array([d0])
	var ws := PackedFloat32Array([w0])
	var p := start
	var dev := rng.randf_range(-0.4, 0.4)
	var drift := 0.0
	var run := 0.0
	while run < length:
		var flip := rng.randf() < 0.7
		var side := (-1.0 if dev > 0.0 else 1.0) if flip else (1.0 if dev > 0.0 else -1.0)
		dev = side * (rng.randf_range(0.2, 0.7) if flip else rng.randf_range(0.1, 0.45))
		drift = clampf(drift + rng.randf_range(-0.08, 0.08), -0.18, 0.18)
		var s := minf(step * rng.randf_range(0.6, 1.4), length - run + 0.01)
		p += Vector2.from_angle(angle + drift + dev) * s
		run += s
		g.append(p)
		pts.append(Iso.ground_to_screen(p))
		ds.append(d0 + run)
		ws.append(lerpf(w0, w1, clampf(run / length, 0.0, 1.0)))
	return {"g": g, "pts": pts, "d": ds, "w": ws}
