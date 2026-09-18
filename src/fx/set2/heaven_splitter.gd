extends FxTimeline
## Heaven Splitter: glowing line marker + storm sigil charge -> colossal sky lightning column (line nuke) ->
## eight jagged fissures crack outward -> lightning erupts from the fissures -> scorched, glowing cracks with
## static arcs crawling along them and grey smoke drifting up.

const LINE_LENGTH := 10.0
const LINE_HALF_WIDTH := 0.7
const CORE_KILL := 1.6
const FISSURES := 8
const FISSURE_LENGTH := 5.6
const T_STRIKE := 1.4
const T_FISSURE := 2.0
const FISSURE_GROW := 0.8
const T_ERUPT := 2.9
const T_AFTER := 4.3
## Eruption points along each fissure, as fractions of its length.
const ERUPT_AT := [0.28, 0.58, 0.88]
const SIGIL_RADIUS := 1.9
const COLUMN_SIZE := Vector2(170, 470)
const STORM_LIGHT := Color(0.45, 0.65, 1.0)
## Saturated blue for the telegraph lane and sigil.
const RUNE_BLUE := Color("3f7fff")
const CRACK_LIGHT := Color(1.0, 0.6, 0.25)
const SH_COLUMN := preload("res://shaders/storm_column.gdshader")
## Dark stone with a blue-grey lit face, blue-lit dust and grey smoke.
const STONE_LIT := [Color("8a93a8"), Color("6c7488"), Color("535a6c"), Color("3e4352")]
## Saturated blue for the big bolts.
const BOLT_BLUE := Color("4d8dff")
const STORM_DUST := [Color(0.78, 0.85, 1.0, 0.7), Color(0.58, 0.64, 0.78, 0.55), Color(0.45, 0.48, 0.58, 0.4),
	Color(0.38, 0.4, 0.48, 0.22)]
const SMOKE_GREY := [Color(0.47, 0.47, 0.52, 0.82), Color(0.42, 0.42, 0.47, 0.82), Color(0.37, 0.37, 0.42, 0.72),
	Color(0.33, 0.33, 0.38, 0.52), Color(0.3, 0.3, 0.35, 0.26)]


## Jagged crack network radiating from the impact: eight long zig-zag fissures with side forks, plus short
## splinters round the centre. Drawn in screen pixels on the ground layer: an additive orange glow bleeding onto
## the ground, a dark scorched rift, a molten fill and a white-hot core. The growth front runs white-hot; `heat`
## cools it to flickering embers and `charge` flickers blue lightning through it.
class CrackNet:
	extends Node2D

	## Polylines: {pts: screen px from the centre, d: ground units from the centre along the cracks, w: width 0..1}.
	var lines: Array[Dictionary] = []
	## Distance from the centre the growth front reaches at `progress` 1.
	var reach := 1.0
	var progress := 0.0
	var heat := 1.0
	## White-hot growth front; faded out once the cracks have opened.
	var hot := 1.0
	var charge := 0.0
	var fade := 1.0
	var _time := 0.0
	var _glow: Node2D
	var _vis: Array[Dictionary] = []
	var _vis_front := -1.0

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

	## Appends a mitred triangle strip with per-point widths (px) and colours along a polyline.
	func _strip(pts: PackedVector2Array, widths: PackedFloat32Array, cols: PackedColorArray,
			verts: PackedVector2Array, vcols: PackedColorArray, idx: PackedInt32Array) -> void:
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
			vcols.append(cols[i])
			vcols.append(cols[i])
		for i in n - 1:
			var a := base + i * 2
			idx.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))

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
		var rift_v := PackedVector2Array()
		var rift_c := PackedColorArray()
		var rift_i := PackedInt32Array()
		var melt_v := PackedVector2Array()
		var melt_c := PackedColorArray()
		var melt_i := PackedInt32Array()
		var dark := Color(0.07, 0.035, 0.03, 0.95 * fade)
		for vis in _visible():
			var pts: PackedVector2Array = vis.pts
			var ds: PackedFloat32Array = vis.d
			var ws: PackedFloat32Array = vis.w
			var rw := PackedFloat32Array()
			var mw := PackedFloat32Array()
			var rc := PackedColorArray()
			var mc := PackedColorArray()
			for i in pts.size():
				rw.append(1.8 + 3.4 * ws[i])
				mw.append(0.9 + 2.3 * ws[i])
				rc.append(dark)
				mc.append(_molten(ds[i], front, ws[i]))
			_strip(pts, rw, rc, rift_v, rift_c, rift_i)
			_strip(pts, mw, mc, melt_v, melt_c, melt_i)
		var ci := get_canvas_item()
		if not rift_i.is_empty():
			RenderingServer.canvas_item_add_triangle_array(ci, rift_i, rift_v, rift_c)
		if not melt_i.is_empty():
			RenderingServer.canvas_item_add_triangle_array(ci, melt_i, melt_v, melt_c)
		# White-hot core line down the wide part of each crack.
		var core_a := clampf(heat * 1.5 - 0.45, 0.0, 1.0) * fade
		if core_a > 0.0:
			for vis in _visible():
				var pts: PackedVector2Array = vis.pts
				var ws: PackedFloat32Array = vis.w
				var n := 0
				while n < pts.size() and ws[n] > 0.32:
					n += 1
				if n >= 2:
					draw_polyline(pts.slice(0, n), Color(1.0, 0.95, 0.74, core_a), -1.0)
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
		var v := PackedVector2Array()
		var c := PackedColorArray()
		var ix := PackedInt32Array()
		for vis in _visible():
			var pts: PackedVector2Array = vis.pts
			var ds: PackedFloat32Array = vis.d
			var ws: PackedFloat32Array = vis.w
			var wide := PackedFloat32Array()
			var narrow := PackedFloat32Array()
			var wc := PackedColorArray()
			var nc := PackedColorArray()
			for i in pts.size():
				var k := ((0.24 + 0.3 * ws[i]) * heat + 0.3 * _fresh(ds[i], front)) * fade
				var col := Color(1.0 * k, 0.42 * k, 0.1 * k)
				col += Color(0.3, 0.5, 1.0) * (0.3 * charge * ws[i] * fade)
				wide.append(5.0 + 12.0 * ws[i])
				narrow.append(3.0 + 6.0 * ws[i])
				wc.append(Color(col.r * 0.5, col.g * 0.5, col.b * 0.5))
				nc.append(Color(col.r * 0.6, col.g * 0.6, col.b * 0.6))
			_strip(pts, wide, wc, v, c, ix)
			_strip(pts, narrow, nc, v, c, ix)
		if not ix.is_empty():
			RenderingServer.canvas_item_add_triangle_array(_glow.get_canvas_item(), ix, v, c)


var _center_px := Vector2.ZERO
var _dir := Vector2(1, 0)
var _sigil: SigilRune
var _lane: LanePath
var _cracks: CrackNet
## Main fissure polylines in ground units from the origin, for eruptions, arcs and damage.
var _paths: Array[PackedVector2Array] = []
var _static_voice: Node
var _arc_timer := 0.0
var _spark_timer := 0.0


func _build() -> void:
	duration = 8.5
	_center_px = Iso.ground_to_screen(origin)
	_dir = (extra.get("dir", Vector2(1, 0)) as Vector2).normalized()

	_lane = Set2Parts.lane(self, origin - _dir * LINE_LENGTH * 0.5, _dir, LINE_LENGTH, LINE_HALF_WIDTH * 2.0,
		RUNE_BLUE, "storm")
	_sigil = Set2Parts.sigil(self, origin, SIGIL_RADIUS, RUNE_BLUE, "storm")
	var glow := FxParts.ground_light(self, origin, 2.6, STORM_LIGHT, 0.0)
	glow.tween_param("intensity", 0.0, 0.55, T_STRIKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	glow.life = T_STRIKE + 0.05
	ctx.impact.dim(0.55, 1.0)
	ctx.play(&"hs_charge", origin)

	# Storm charge: sparks spiralling up out of the sigil, small arcs leaping skyward and crackling round the ring.
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
	for k in 10:
		at(0.3 + k * 0.1, _ring_arc)

	at(T_STRIKE, _strike)
	at(T_FISSURE, _open_fissures)
	at(T_AFTER, _aftermath)


## A short arc crackling along the sigil ring, with a spark leaping off it.
func _ring_arc() -> void:
	var a := ctx.rng.randf() * TAU
	var p0 := Iso.ground_to_screen(origin + Vector2.from_angle(a) * SIGIL_RADIUS) + Vector2(0, -2)
	var p1 := Iso.ground_to_screen(origin + Vector2.from_angle(a + ctx.rng.randf_range(0.3, 0.6)) * SIGIL_RADIUS) + Vector2(0, -2)
	Set2Parts.bolt(self, ctx.overhead, p0, p1, 0.14, 0.0, 1)
	var out := Iso.ground_to_screen(origin + Vector2.from_angle(a) * SIGIL_RADIUS * 1.3)
	Set2Parts.bolt(self, ctx.overhead, p0, out + Vector2(0, -ctx.rng.randf_range(4, 16)), 0.1, 0.0, 0)


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

	# Colossal sky column: crackling strands round a white core, then crisp forked bolts.
	var column := FxParts.quad(self, SH_COLUMN, COLUMN_SIZE, ctx.overhead, Vector2(0.5, 1.0))
	column.position = _center_px + Vector2(0, 6)
	column.set_param("size", COLUMN_SIZE)
	column.tween_param("intensity", 1.0, 0.0, 0.7, 0.15, Tween.TRANS_QUAD, Tween.EASE_IN)
	column.life = 0.88
	for i in 5:
		at(t + i * 0.07, func():
			var top := _center_px + Vector2(ctx.rng.randf_range(-55, 55), -COLUMN_SIZE.y + 20)
			Set2Parts.bolt(self, ctx.overhead, top, _center_px + Vector2(ctx.rng.randf_range(-8, 8), 0),
				ctx.rng.randf_range(0.3, 0.55), 2.0 if i < 2 else 1.0, 4, BOLT_BLUE))
	# Side arcs lashing out of the column.
	for i in 10:
		at(t + ctx.rng.randf_range(0.0, 0.5), func():
			var side := 1.0 if ctx.rng.randf() < 0.5 else -1.0
			var a := _center_px + Vector2(side * 6.0, -ctx.rng.randf_range(30, 300))
			var b := a + Vector2(side * ctx.rng.randf_range(30, 75), ctx.rng.randf_range(-10, 40))
			Set2Parts.bolt(self, ctx.overhead, a, b, ctx.rng.randf_range(0.12, 0.25), 0.0, 1))
	var bloom := FxParts.bloom(self, _center_px + Vector2(0, -20), 115.0, STORM_LIGHT, 1.1, 0.8)
	bloom.tween_param("intensity", 1.1, 0.0, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	bloom.life = 0.82
	# Starburst of light spikes over the impact.
	var burst := FxParts.screen_rays(self, _center_px + Vector2(0, -8), 175.0, Color(0.72, 0.86, 1.0), 24.0, 0.6)
	burst.set_param("inner", 0.05)
	burst.tween_param("intensity", 2.0, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.6
	var rays := FxParts.ground_rays(self, origin, 4.0, Color(0.7, 0.85, 1.0), 90.0)
	rays.tween_param("intensity", 0.9, 0.0, 0.7)
	rays.life = 0.72
	var light := FxParts.ground_light(self, origin, 3.6, STORM_LIGHT)
	light.tween_param("intensity", 1.1, 0.0, 1.2, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 1.25
	var wave := FxParts.shockwave(self, origin, 3.0, Set2Parts.STORM)
	wave.z_index = 9
	wave.set_param("thickness", 0.1)
	wave.tween_param("progress", 0.05, 1.0, 0.4, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.25, 0.25)
	wave.life = 0.52
	var crater := FxParts.decal(self, origin, 1.7, Color("5aa8ff"), Color("e8f4ff"), Color(0.1, 0.08, 0.1, 0.55))
	crater.tween_param("heat", 1.0, 0.2, 1.5)
	crater.tween_param("fade", 1.0, 0.0, 1.0, duration - t - 1.1)
	# Big lightning-lit stones and gravel thrown out of the impact, and a ring of blue-lit dust.
	FxParts.debris(self, _center_px, 22, 18.0, Vector2(110, 320), STONE_LIT, Vector2(3.5, 7.0), true)
	FxParts.debris(self, _center_px, 24, 14.0, Vector2(80, 280), STONE_LIT, Vector2(1.5, 3.0), true)
	FxParts.sparks(self, ctx.overhead, _center_px, 90, Set2Parts.STORM_LIFE, Vector2(120, 380), Vector2(40, 300))
	var dust := FxParts.particles(self, ctx.overhead_back, _center_px, PixelParticles.Shape.PUFF, STORM_DUST)
	dust.drag = 1.3
	dust.burst(26, {
		"radius": 30.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(50, 160), "alt": Vector2(0, 14),
		"alt_speed": Vector2(4, 36), "life": Vector2(0.8, 1.5), "size": Vector2(4, 8), "size_end_mul": 1.8,
	})

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


## One jagged crack: zig-zag steps that mostly alternate sides around a slowly drifting heading.
## Returns {g: ground points from the origin, pts: screen px from the origin, d: distance from the centre, w: 0..1}.
func _crack_line(start: Vector2, angle: float, length: float, step: float, w0: float, w1: float, d0: float) -> Dictionary:
	var g := PackedVector2Array([start])
	var pts := PackedVector2Array([Iso.ground_to_screen(start)])
	var ds := PackedFloat32Array([d0])
	var ws := PackedFloat32Array([w0])
	var p := start
	var dev := ctx.rng.randf_range(-0.4, 0.4)
	var drift := 0.0
	var run := 0.0
	while run < length:
		var flip := ctx.rng.randf() < 0.7
		var side := (-1.0 if dev > 0.0 else 1.0) if flip else (1.0 if dev > 0.0 else -1.0)
		dev = side * (ctx.rng.randf_range(0.2, 0.7) if flip else ctx.rng.randf_range(0.1, 0.45))
		drift = clampf(drift + ctx.rng.randf_range(-0.08, 0.08), -0.18, 0.18)
		var s := minf(step * ctx.rng.randf_range(0.6, 1.4), length - run + 0.01)
		p += Vector2.from_angle(angle + drift + dev) * s
		run += s
		g.append(p)
		pts.append(Iso.ground_to_screen(p))
		ds.append(d0 + run)
		ws.append(lerpf(w0, w1, clampf(run / length, 0.0, 1.0)))
	return {"g": g, "pts": pts, "d": ds, "w": ws}


func _open_fissures() -> void:
	ctx.play(&"hs_fissure", origin)
	ctx.shake.add_trauma(0.5)
	_cracks = CrackNet.new()
	# Screen-pixel drawing on the ground layer: undo the iso basis, centred on the impact.
	_cracks.transform = Iso.BASIS.affine_inverse()
	_cracks.position = origin
	_cracks.z_index = 8
	var base_angle := _dir.angle()
	var reach := 0.0
	for i in FISSURES:
		var a := base_angle + TAU * i / FISSURES + ctx.rng.randf_range(-0.1, 0.1)
		var main := _crack_line(Vector2.ZERO, a, FISSURE_LENGTH * ctx.rng.randf_range(0.86, 1.08), 0.24, 1.0, 0.15, 0.0)
		_cracks.lines.append(main)
		var g: PackedVector2Array = main.g
		var ds: PackedFloat32Array = main.d
		var ws: PackedFloat32Array = main.w
		_paths.append(g)
		reach = maxf(reach, ds[ds.size() - 1])
		# Side forks, some splitting again.
		for f in ctx.rng.randi_range(3, 5):
			var k := ctx.rng.randi_range(int(g.size() * 0.12), int(g.size() * 0.85))
			var side := 1.0 if ctx.rng.randf() < 0.5 else -1.0
			var fa := a + side * ctx.rng.randf_range(0.45, 1.05)
			var fork := _crack_line(g[k], fa, ctx.rng.randf_range(0.5, 1.5) * (1.0 - 0.45 * float(k) / g.size()), 0.16,
				ws[k] * 0.7, 0.06, ds[k])
			_cracks.lines.append(fork)
			var fg: PackedVector2Array = fork.g
			if ctx.rng.randf() < 0.45 and fg.size() > 3:
				var m := int(fg.size() * 0.5)
				var fws: PackedFloat32Array = fork.w
				var fds: PackedFloat32Array = fork.d
				_cracks.lines.append(_crack_line(fg[m], fa - side * ctx.rng.randf_range(0.5, 0.95),
					ctx.rng.randf_range(0.3, 0.6), 0.13, fws[m] * 0.7, 0.05, fds[m]))
	# Short splinters round the centre.
	for i in 12:
		var a := base_angle + TAU * (i + 0.5) / 12.0 + ctx.rng.randf_range(-0.15, 0.15)
		_cracks.lines.append(_crack_line(Vector2.ZERO, a, ctx.rng.randf_range(0.35, 0.95), 0.14, 0.6, 0.06, 0.0))
	_cracks.reach = reach
	track(_cracks, ctx.ground)
	create_tween().tween_property(_cracks, "progress", 1.0, FISSURE_GROW).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var cool := create_tween()
	cool.tween_interval(FISSURE_GROW)
	cool.tween_property(_cracks, "hot", 0.0, 0.6)
	var heart := FxParts.bloom(self, _center_px, 46.0, Color(1.0, 0.72, 0.38), 0.0, 0.55)
	heart.tween_param("intensity", 0.0, 1.1, FISSURE_GROW * 0.5)
	heart.tween_param("intensity", 1.1, 0.35, 2.0, FISSURE_GROW)
	heart.tween_param("intensity", 0.35, 0.0, 1.0, duration - t - 1.2)
	# Scorched ground spreading with the cracks.
	var scorch := FxParts.decal(self, origin, 3.4, Color("ff6a1a"), Color("ffd27a"), Color(0.07, 0.05, 0.045, 0.5))
	scorch.set_param("heat", 0.0)
	scorch.tween_param("fade", 0.0, 1.0, FISSURE_GROW)
	scorch.tween_param("fade", 1.0, 0.0, 1.0, duration - t - 1.1)
	# Stone bursting out as the front passes (the growth eases out, so the front reaches `frac` later).
	for i in FISSURES:
		for k in 3:
			var frac := (k + 1) / 4.0
			at(t + FISSURE_GROW * (1.0 - sqrt(1.0 - frac)), func():
				var path := _paths[i]
				var sp := Iso.ground_to_screen(origin + path[int(frac * (path.size() - 1))])
				FxParts.debris(self, sp, 3, 3.0, Vector2(20, 90), STONE_LIT, Vector2(2.0, 4.0), true))
	for i in FISSURES:
		var mid := origin + _paths[i][int(_paths[i].size() * 0.5)]
		var l := FxParts.ground_light(self, mid, 2.0, CRACK_LIGHT, 0.0)
		l.tween_param("intensity", 0.0, 0.7, FISSURE_GROW)
		l.tween_param("intensity", 0.7, 0.0, 2.5, duration - T_FISSURE - 2.6)
	# Eruption points along each fissure, rippling outward.
	for i in FISSURES:
		for k in ERUPT_AT.size():
			at(T_ERUPT + k * 0.28 + i * 0.03 + ctx.rng.randf_range(0.0, 0.08), _erupt.bind(i, k))


func _erupt(i: int, k: int) -> void:
	var path := _paths[i]
	var g := origin + path[int(ERUPT_AT[k] * (path.size() - 1))]
	var sp := Iso.ground_to_screen(g)
	if k == 0:
		ctx.play(&"hs_erupt", g, -2.0)
		ctx.shake.add_trauma(0.18)
	_cracks.charge = 1.0
	# Forked lightning bursting up out of the fissure, tallest near the impact, a thinner strand beside it and a
	# quick re-strike.
	var h := lerpf(210.0, 120.0, k / 2.0) * ctx.rng.randf_range(0.8, 1.15)
	var lean := ctx.rng.randf_range(-22.0, 22.0)
	Set2Parts.bolt(self, ctx.overhead, sp, sp + Vector2(lean, -h), 0.42, 2.0 if k == 0 else 1.0, 4, BOLT_BLUE)
	Set2Parts.bolt(self, ctx.overhead, sp + Vector2(ctx.rng.randf_range(-6, 6), 0),
		sp + Vector2(lean * 0.5 + ctx.rng.randf_range(-30, 30), -h * ctx.rng.randf_range(0.45, 0.7)), 0.3, 1.0, 2, BOLT_BLUE)
	at(t + 0.16, func():
		Set2Parts.bolt(self, ctx.overhead, sp, sp + Vector2(-lean * 0.6, -h * ctx.rng.randf_range(0.6, 0.9)), 0.22, 1.0, 3,
			BOLT_BLUE))
	Set2Parts.glow_column(self, sp, 16.0, h, STORM_LIGHT, 0.5, 0.25)
	var flash := FxParts.bloom(self, sp + Vector2(0, -8), 22.0, STORM_LIGHT, 1.0, 0.8)
	flash.tween_param("intensity", 1.0, 0.0, 0.3)
	flash.life = 0.34
	var fire := FxParts.bloom(self, sp, 16.0, CRACK_LIGHT, 1.0, 0.6)
	fire.tween_param("intensity", 1.0, 0.0, 0.4)
	fire.life = 0.42
	var light := FxParts.ground_light(self, g, 1.2, STORM_LIGHT)
	light.tween_param("intensity", 0.8, 0.0, 0.4)
	light.life = 0.42
	FxParts.debris(self, sp, 4, 4.0, Vector2(40, 170), STONE_LIT, Vector2(2.5, 5.0), true)
	FxParts.sparks(self, ctx.overhead, sp, 14, Set2Parts.STORM_LIFE, Vector2(50, 200), Vector2(40, 220))
	FxParts.sparks(self, ctx.overhead, sp, 10, FxParts.FIRE_LIFE, Vector2(40, 140), Vector2(30, 160))
	var a := origin + path[int((ERUPT_AT[k - 1] if k > 0 else 0.0) * (path.size() - 1))]
	for e in ctx.field.alive():
		if e.ground_pos.distance_to(g) < 0.9 or Set2Parts.dist_to_segment(e.ground_pos, a, g) < 0.5:
			ctx.field.kill(e, &"lightning", g)
	ctx.env.damage_radius(g, 1.0, 60.0, &"lightning")


func _aftermath() -> void:
	ctx.impact.dim(0.15, 0.6)
	_static_voice = ctx.play(&"hs_static", origin, -8.0)
	ctx.play(&"hs_rumble", origin, -4.0)
	create_tween().tween_property(_cracks, "heat", 0.72, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var tw := create_tween()
	tw.tween_interval(duration - T_AFTER - 1.9)
	tw.tween_property(_cracks, "heat", 0.3, 0.8)
	tw.tween_property(_cracks, "fade", 0.0, 1.0)
	# Grey smoke plumes rising out of the cracks.
	for i in FISSURES:
		var path := _paths[i]
		var sp := Iso.ground_to_screen(origin + path[int(ctx.rng.randf_range(0.25, 0.65) * (path.size() - 1))])
		var smoke := FxParts.emitter(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, SMOKE_GREY, 3.0,
			duration - T_AFTER - 1.8, {
				"radius": 8.0, "speed": Vector2(4, 14), "alt": Vector2(0, 6), "alt_speed": Vector2(14, 30),
				"life": Vector2(2.2, 3.4), "size": Vector2(4, 8), "size_end_mul": 2.0,
			})
		smoke.drag = 0.4
	FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 20.0, 2.5, {
		"radius": FxParts.particle_radius(3.5), "alt": Vector2(0, 6), "alt_speed": Vector2(10, 35),
		"speed": Vector2(0, 8), "life": Vector2(0.6, 1.3), "size": Vector2(1, 1),
	})
	at(duration - 1.3, func():
		ctx.fade_out(_static_voice, 1.0)
		ctx.impact.dim(0.0, 0.6))


func _fx_process(delta: float) -> void:
	if _cracks == null or not is_instance_valid(_cracks):
		return
	_cracks.charge = move_toward(_cracks.charge, 0.0, delta * 2.5)
	if t < T_AFTER - 0.4 or t > duration - 1.0:
		return
	# Residual static arcs crawling along the fissures.
	_arc_timer -= delta
	if _arc_timer <= 0.0:
		_arc_timer = lerpf(0.05, 0.16, clampf((t - T_AFTER) / (duration - T_AFTER), 0.0, 1.0))
		var path := _paths[ctx.rng.randi() % FISSURES]
		var span := ctx.rng.randi_range(3, 6)
		var k := ctx.rng.randi_range(1, maxi(path.size() - span - 1, 1))
		var a := Iso.ground_to_screen(origin + path[k]) + Vector2(0, -2)
		var b := Iso.ground_to_screen(origin + path[mini(k + span, path.size() - 1)]) + Vector2(0, -3)
		Set2Parts.bolt(self, ctx.overhead, a, b, ctx.rng.randf_range(0.12, 0.26), 1.0 if ctx.rng.randf() < 0.5 else 0.0, 2,
			BOLT_BLUE)
		if ctx.rng.randf() < 0.4:
			FxParts.sparks(self, ctx.overhead, b, 4, Set2Parts.STORM_LIFE, Vector2(20, 80), Vector2(20, 90))
	# Ion sparks: tiny arcs flickering in the air over the cracks for a while.
	if t < T_AFTER + 1.8:
		_spark_timer -= delta
		if _spark_timer <= 0.0:
			_spark_timer = 0.07
			var path := _paths[ctx.rng.randi() % FISSURES]
			var p := Iso.ground_to_screen(origin + path[ctx.rng.randi_range(2, path.size() - 1)])
			p += Vector2(ctx.rng.randf_range(-10, 10), -ctx.rng.randf_range(10, 45))
			Set2Parts.bolt(self, ctx.overhead, p, p + Vector2.from_angle(ctx.rng.randf() * TAU) * ctx.rng.randf_range(8, 16),
				0.08, 0.0, 0)
