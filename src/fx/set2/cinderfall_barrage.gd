extends FxTimeline
## Cinderfall Barrage: magma sigil, quake and glowing ground cracks -> a colossal volcano of rock shards thrusts
## out of the ground -> the crater launches giant fire stones -> they rain across the area, bursting into fire ->
## the volcano sinks back into a smoking crater, leaving burning lava pools, glowing cracks, smoke and embers.

const RADIUS := 5.8
const VOLCANO_RADIUS := 2.1
const VOLCANO_HEIGHT := 215.0
const T_RISE := 1.2
const RISE_TIME := 1.3
const T_ERUPT := 2.6
const T_BARRAGE := 3.3
const T_BARRAGE_END := 7.0
const T_SINK := 8.2
const STONES := 20
const STONE_KILL := 0.9
const LAVA_LIGHT := Color(1.0, 0.45, 0.15)
## Volcanic smoke: dark ash grey, thinning as it rises.
const ASH_SMOKE := [Color(0.42, 0.37, 0.36, 0.85), Color(0.36, 0.33, 0.33, 0.85), Color(0.31, 0.29, 0.3, 0.75),
	Color(0.27, 0.26, 0.28, 0.55), Color(0.24, 0.23, 0.26, 0.3)]


## Volcano: a steep, jagged mountain of chunky rock slabs in staggered rows, each lit from the upper left and glowing
## orange where the lava wells up round its foot, with tall spires round the summit crater and bright lava in every
## gap. `rise` pushes it up out of the ground and `sink` lowers it back, `heat` cools the lava, `erupting` fans
## flames out of the crater.
class Volcano:
	extends Node2D

	const ROCK_SHADE := Color("1f1a1b")
	const ROCK_LIT := Color("4a4143")
	const ROCK_TOP := Color("6a5e5c")
	const ROCK_EDGE := Color("857673")
	const OUTLINE := Color("0e0909")
	const LAVA_DEEP := Color("7a1206")
	const LAVA := Color("e8501a")
	const LAVA_HOT := Color("ffa83a")
	const LAVA_WHITE := Color("fff0b8")
	const ROWS := 7

	var radius_px := 95.0
	var height := 215.0
	var rise := 0.0
	var heat := 1.0
	var sink := 0.0
	var erupting := 0.0
	var lights: LightField
	var ground_pos := Vector2.ZERO
	## Rock chunks, back to front: {u, v, w, h, tilt, shape (normalised outline, x -0.5..0.5, y 0..-1), apex, ridge,
	## tone, vein}.
	var _chunks: Array[Dictionary] = []
	var _streams: Array[Dictionary] = []
	var _time := 0.0
	var _redraw_in := 0.0

	func setup(rng: RandomNumberGenerator) -> void:
		# Summit spires round the crater.
		for i in 5:
			var u := lerpf(-0.9, 0.9, (i + 0.5) / 5.0) + rng.randf_range(-0.08, 0.08)
			_chunks.append(_chunk(rng, u, rng.randf_range(0.8, 0.86), 0.34 * rng.randf_range(0.8, 1.0),
				rng.randf_range(2.0, 2.8), true, ROWS))
		# Staggered rows of chunky slabs down to the foot.
		for r in range(ROWS - 1, -1, -1):
			var v := r / float(ROWS) * 0.86
			var count := int(round(lerpf(8.0, 3.0, v / 0.86)))
			var offset := 0.5 if r % 2 == 1 else 0.0
			for c in count:
				var u := lerpf(-1.05, 1.05, (c + 0.25 + offset * 0.5) / count) + rng.randf_range(-0.06, 0.06)
				_chunks.append(_chunk(rng, u, v + rng.randf_range(-0.03, 0.03), 2.0 / count * rng.randf_range(0.9, 1.35),
					rng.randf_range(1.0, 1.7) * lerpf(1.0, 1.4, v), rng.randf() < 0.5, r))
		# Back to front: higher rows first, and within a row the outer chunks before the middle ones.
		_chunks.sort_custom(func(a, b): return a.row > b.row or (a.row == b.row and absf(a.u) > absf(b.u)))
		for k in 4:
			_streams.append({"u": rng.randf_range(-0.6, 0.6), "phase": rng.randf() * TAU, "wig": rng.randf_range(0.03, 0.07)})

	## A chunk outline in normalised coordinates: a flat-ish foot, bulging sides and a pointed or broken top.
	func _chunk(rng: RandomNumberGenerator, u: float, v: float, w: float, hk: float, pointy: bool, row: int) -> Dictionary:
		# Sides lean in toward an off-centre top so chunks read as broken rock rather than blocks.
		var shape := PackedVector2Array()
		shape.append(Vector2(-0.5, 0.0))
		shape.append(Vector2(-0.5 + rng.randf_range(-0.08, 0.06), -rng.randf_range(0.3, 0.55)))
		shape.append(Vector2(-0.3 + rng.randf_range(-0.1, 0.1), -rng.randf_range(0.7, 0.92)))
		var apex := Vector2(rng.randf_range(-0.2, 0.28), -1.0)
		if pointy:
			shape.append(apex)
		else:
			apex = Vector2(rng.randf_range(-0.22, 0.05), -1.0)
			shape.append(apex)
			shape.append(Vector2(apex.x + rng.randf_range(0.25, 0.42), -rng.randf_range(0.72, 0.9)))
		shape.append(Vector2(0.34 + rng.randf_range(-0.1, 0.1), -rng.randf_range(0.5, 0.78)))
		shape.append(Vector2(0.5 + rng.randf_range(-0.06, 0.06), -rng.randf_range(0.15, 0.38)))
		shape.append(Vector2(0.5, 0.0))
		return {"u": u, "v": v, "w": w, "h": hk, "row": row, "tilt": u * 0.35 + rng.randf_range(-0.1, 0.1), "shape": shape,
			"apex": 3, "ridge": rng.randf_range(0.05, 0.25), "tone": rng.randf(), "vein": rng.randf() < 0.35,
			"vy": rng.randf_range(0.3, 0.6), "pointy": pointy}

	func _process(delta: float) -> void:
		_time += delta
		modulate.a = 1.0 - sink * sink
		# Many chunk polygons: redraw at ~20 Hz while standing, every frame while rising or sinking.
		_redraw_in -= delta
		var moving := (rise > 0.0 and rise < 1.0) or (sink > 0.0 and sink < 1.0)
		if moving or _redraw_in <= 0.0:
			_redraw_in = 0.08
			queue_redraw()

	func _half_width(v: float) -> float:
		return radius_px * lerpf(1.0, 0.18, pow(clampf(v, 0.0, 1.0), 0.85))

	## Point on the front face of the cone: u across (-1..1), v up (0..1); the base bulges down like the iso ellipse.
	func _cone_point(u: float, v: float, h: float) -> Vector2:
		var w := _half_width(v)
		var cv := clampf(v, 0.0, 1.0)
		return Vector2(u * w, -v * h + sqrt(maxf(1.0 - minf(u * u, 1.0), 0.0)) * w * 0.5 * (1.0 - cv))

	func _lava(k: float) -> Color:
		var c := LAVA_DEEP.lerp(LAVA, clampf(k * 1.4, 0.0, 1.0)).lerp(LAVA_HOT, clampf(k * 1.6 - 0.8, 0.0, 1.0))
		return c.lerp(Color(0.14, 0.05, 0.04), 1.0 - heat)

	func _draw() -> void:
		if rise <= 0.01 or sink >= 0.98:
			return
		var h := height * rise * (1.0 - sink)
		var amb := maxf(lights.ambient, 0.6) if lights else 1.0
		_draw_body(h)
		_draw_streams(h)
		_draw_crater(h)
		var grow := clampf(rise * 1.3, 0.35, 1.0) * (1.0 - sink)
		var rise_v := clampf(rise * 1.2, 0.0, 1.2)
		# Every chunk goes into one triangle mesh, back to front, instead of hundreds of polygon calls.
		var verts := PackedVector2Array()
		var cols := PackedColorArray()
		var idx := PackedInt32Array()
		for s in _chunks:
			if s.v > rise_v:
				continue
			_add_chunk(s, h, amb, grow, verts, cols, idx)
		if not idx.is_empty():
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, verts, cols)

	## Lava body filling the cone, brightest down the middle; shows through the gaps between chunks.
	func _draw_body(h: float) -> void:
		var cols := 10
		var rows := 8
		var pts := PackedVector2Array()
		var colors := PackedColorArray()
		for j in rows + 1:
			var v := float(j) / rows
			for i in cols + 1:
				var u := -1.0 + 2.0 * i / cols
				pts.append(_cone_point(u, v, h))
				var k := (1.0 - absf(u) * 0.5) * (0.8 + 0.2 * sin(_time * 3.0 + v * 9.0 + u * 4.0)) + 0.1
				colors.append(_lava(k))
		var idx := PackedInt32Array()
		for j in rows:
			for i in cols:
				var a := j * (cols + 1) + i
				idx.append_array(PackedInt32Array([a, a + 1, a + cols + 1, a + 1, a + cols + 2, a + cols + 1]))
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, colors)

	## Crater among the summit spires: a molten pool and, while erupting, flames licking up out of it.
	func _draw_crater(h: float) -> void:
		var top := Vector2(0, -h * 0.97)
		var rx := _half_width(1.0) * 1.3
		var ry := rx * 0.45
		draw_colored_polygon(_ellipse(top, rx, ry), _lava(1.0))
		draw_colored_polygon(_ellipse(top, rx * 0.55, ry * 0.5), LAVA_WHITE.lerp(LAVA, 1.0 - heat))
		if erupting <= 0.01:
			return
		for k in 7:
			var x := (k / 6.0 - 0.5) * rx * 1.4
			var f := 0.6 + 0.4 * sin(_time * 17.0 + k * 2.1)
			var tall := (20.0 + 30.0 * f) * erupting * (1.0 - absf(x) / rx * 0.5)
			var base := top + Vector2(x, 0)
			var lean := sin(_time * 5.0 + k) * 4.0
			draw_colored_polygon(PackedVector2Array([base + Vector2(-5, 0), base + Vector2(lean, -tall), base + Vector2(5, 0)]),
				Color(1.0, 0.45, 0.1, 0.9))
			draw_colored_polygon(PackedVector2Array([base + Vector2(-2.5, 0), base + Vector2(lean * 0.6, -tall * 0.6),
				base + Vector2(2.5, 0)]), Color(1.0, 0.86, 0.45))

	## One rock chunk standing on the cone, added to the mesh: a glowing molten rim, a dark outline, then inset a lit
	## left face and a shadowed right face split by a ridge from the top, a pale top on broken tops, lit upper edges,
	## lava light warming its foot and sometimes a lava vein.
	func _add_chunk(s: Dictionary, h: float, amb: float, grow: float, verts: PackedVector2Array, cols: PackedColorArray,
			idx: PackedInt32Array) -> void:
		var v: float = s.v
		var base := _cone_point(s.u, v, h) + Vector2(0, 3)
		var cw: float = _half_width(v) * s.w
		var ch: float = cw * s.h * grow
		var rot: float = s.tilt
		var shape: PackedVector2Array = s.shape
		var pts := PackedVector2Array()
		for p in shape:
			pts.append(base + Vector2(p.x * cw, p.y * ch).rotated(rot))
		var n := pts.size()
		var apex_i: int = s.apex
		var apex := pts[apex_i]
		var ridge: Vector2 = base + Vector2(cw * s.ridge, 0).rotated(rot)
		var glow := 0.55 + 0.35 * sin(_time * 3.0 + v * 9.0 + s.u * 5.0)
		var rim_c := _lava(glow + 0.35)
		var c := (pts[0] + pts[n - 1] + apex) / 3.0
		_fan(_scaled(pts, c, 1.09), rim_c, verts, cols, idx)
		_fan(pts, OUTLINE * amb, verts, cols, idx)
		# Faces inset a pixel or so, leaving the outline showing round them and along the ridge.
		var inset := 1.0 - 1.4 / maxf(minf(cw, ch), 6.0)
		var ins := _scaled(pts, c, inset)
		var ridge_in := c + (ridge - c) * inset
		var shade: float = (0.78 + 0.32 * s.tone) * amb
		var lit := PackedVector2Array()
		for i in apex_i + 1:
			lit.append(ins[i])
		lit.append(ridge_in)
		var dark := PackedVector2Array([ridge_in])
		for i in range(apex_i, n):
			dark.append(ins[i])
		_fan(lit, ROCK_LIT * shade, verts, cols, idx)
		_fan(dark, ROCK_SHADE * shade, verts, cols, idx)
		if not s.pointy:
			_fan(PackedVector2Array([ins[2], ins[apex_i], ins[apex_i + 1], ins[apex_i].lerp(ridge_in, 0.18)]), ROCK_TOP * shade,
				verts, cols, idx)
		_seg(ins[1], ins[2], 1.0, ROCK_EDGE * amb, verts, cols, idx)
		_seg(ins[2], ins[apex_i], 1.0, ROCK_EDGE * amb, verts, cols, idx)
		_fan(PackedVector2Array([ins[0], ins[0].lerp(ins[1], 0.22), ins[n - 1].lerp(ins[n - 2], 0.22), ins[n - 1]]),
			Color(rim_c.r, rim_c.g * 0.8, rim_c.b * 0.6, 0.35), verts, cols, idx)
		if s.vein:
			var k: float = s.vy
			var a := ins[1].lerp(ins[2], k)
			var b := ridge_in.lerp(ins[apex_i], k)
			var m := a.lerp(b, 0.5) + Vector2(0, -2)
			var vein_c := Color(1.0, 0.62, 0.25, heat)
			_seg(a, m, 1.2, vein_c, verts, cols, idx)
			_seg(m, b, 1.2, vein_c, verts, cols, idx)

	func _scaled(pts: PackedVector2Array, c: Vector2, k: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append(c + (p - c) * k)
		return out

	## Triangle fan from the polygon's centroid (the chunk outlines are star-shaped round it).
	func _fan(poly: PackedVector2Array, col: Color, verts: PackedVector2Array, cols: PackedColorArray,
			idx: PackedInt32Array) -> void:
		var n := poly.size()
		var c := Vector2.ZERO
		for p in poly:
			c += p
		c /= n
		var base := verts.size()
		verts.append(c)
		verts.append_array(poly)
		for i in n + 1:
			cols.append(col)
		for i in n:
			idx.append_array(PackedInt32Array([base, base + 1 + i, base + 1 + (i + 1) % n]))

	## A thin quad along a segment, `width` px wide.
	func _seg(a: Vector2, b: Vector2, width: float, col: Color, verts: PackedVector2Array, cols: PackedColorArray,
			idx: PackedInt32Array) -> void:
		var off := (b - a).orthogonal().normalized() * width * 0.5
		var base := verts.size()
		verts.append_array(PackedVector2Array([a + off, b + off, b - off, a - off]))
		cols.append_array(PackedColorArray([col, col, col, col]))
		idx.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))

	## Molten channels running down the flanks from the crater; drawn behind the chunks so they show in the gaps.
	func _draw_streams(h: float) -> void:
		if rise < 0.6 or heat < 0.2:
			return
		for st in _streams:
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for k in 14:
				var v := 0.97 - k * 0.068
				var u: float = st.u * (0.25 + 0.75 * (1.0 - v)) + sin(v * 14.0 + st.phase) * st.wig
				pts.append(_cone_point(u, v, h))
				var pulse := maxf(sin(v * 20.0 + _time * 6.0 + st.phase), 0.0)
				cols.append(LAVA_HOT.lerp(LAVA_WHITE, pulse * 0.8).lerp(LAVA_DEEP, 1.0 - heat))
			draw_polyline(pts, _lava(1.0), 4.0)
			draw_polyline_colors(pts, cols, 2.0)

	func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts

	func crater_top() -> Vector2:
		return position + Vector2(0, -height * rise * (1.0 - sink) * 0.97)


## Flaming boulder: dark cracked rock glowing through molten seams, wrapped in fire that streams into a long tail.
class FireStone:
	extends Node2D

	var size := 20.0
	var dir := Vector2(0, 1)
	var seed := 0.0
	var _time := 0.0
	var _rock := PackedVector2Array()

	func _ready() -> void:
		for k in 9:
			var a := seed + TAU * k / 9.0
			_rock.append(Vector2(cos(a), sin(a) * 0.85) * size * (0.75 + 0.25 * fposmod(sin(seed * 7.0 + k * 1.3) * 91.7, 1.0)))

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var fwd := dir.normalized()
		var back := -fwd
		var side := back.orthogonal()
		# Flame tail: outer red, orange body, yellow core; long, tapering and flickering.
		for layer in 3:
			var width: float = size * [1.35, 1.0, 0.6][layer]
			var length: float = minf(size * 7.0, 140.0) * [1.0, 0.76, 0.47][layer]
			var col: Color = [Color(0.85, 0.18, 0.05, 0.75), Color(1.0, 0.45, 0.1, 0.9), Color(1.0, 0.85, 0.4, 1.0)][layer]
			var steps := 8
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			for k in steps + 1:
				var f := float(k) / steps
				var wob := sin(_time * 35.0 + k * 1.9 + layer) * size * 0.2 * f
				var mid := back * length * f + side * wob
				left.append(mid + side * width * (1.0 - f))
				right.append(mid - side * width * (1.0 - f))
			# Quad strip: never self-intersects even while the tail wobbles.
			for k in steps:
				draw_primitive(PackedVector2Array([left[k], left[k + 1], right[k + 1], right[k]]),
					PackedColorArray([col, col, col, col]), PackedVector2Array())
		# Fire wrapping the rock, swelling behind it.
		for layer in 2:
			var col: Color = [Color(1.0, 0.42, 0.1, 0.9), Color(1.0, 0.78, 0.32)][layer]
			for k in 4:
				var r: float = size * [1.3, 1.1, 0.85, 0.6][k] * (1.0 if layer == 0 else 0.72)
				r *= 1.0 + 0.1 * sin(_time * 28.0 + k * 1.7 + layer)
				draw_circle(back * size * 0.45 * k, r, col)
		# Rock with a face lit by the fire, and glowing seams.
		var rock := PackedVector2Array()
		for p in _rock:
			rock.append(p.rotated(_time * 2.5))
		draw_colored_polygon(rock, Color("2a1e1c"))
		var lit := PackedVector2Array()
		for p in rock:
			lit.append(p * 0.62 + fwd * size * 0.18)
		draw_colored_polygon(lit, Color("4c3830"))
		# Glowing seams: two bent cracks running in from the edge, off to either side of the middle.
		for k in [1, 5]:
			var a: Vector2 = rock[k] * 0.92
			var m: Vector2 = rock[k] * 0.5 + rock[(k + 3) % 9] * 0.15
			var e: Vector2 = rock[(k + 2) % 9] * 0.45
			draw_polyline(PackedVector2Array([a, m, e]), Color("ff8a2a"), 2.0 if size >= 18.0 else -1.0)
			draw_polyline(PackedVector2Array([a, m, e]), Color("ffd070"), -1.0)


var _center_px := Vector2.ZERO
var _sigil: SigilRune
var _volcano: Volcano
var _cracks: CrackNet
var _glow: QuadFx
var _plume: PixelParticles
var _lava_voice: Node
var _quake := 0.0


func _build() -> void:
	duration = 12.0
	_center_px = Iso.ground_to_screen(origin)

	_sigil = Set2Parts.sigil(self, origin, 3.2, Color("ff5a22"), "magma")
	var outer := FxParts.rings(self, origin, RADIUS, Color("ff5a2a"), 2, 22.0)
	outer.z_index = 8
	outer.set_param("crosshair", 0.0)
	outer.set_param("fill", 0.06)
	outer.tween_param("reveal", 0.0, 1.0, 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	outer.tween_param("alpha", 1.0, 0.0, 0.6, T_BARRAGE_END)
	var glow := FxParts.ground_light(self, origin, 3.4, LAVA_LIGHT, 0.0)
	glow.tween_param("intensity", 0.0, 1.0, T_RISE)
	glow.tween_param("intensity", 1.0, 0.35, 2.0, T_ERUPT)
	glow.tween_param("intensity", 0.35, 0.0, 1.5, T_SINK)
	ctx.impact.dim(0.5, 1.0)
	ctx.play(&"cf_rumble", origin)
	_quake = 0.25
	# The earth warns: glowing cracks spread out under the sigil.
	_cracks = CrackNet.new()
	_cracks.place(origin)
	_cracks.z_index = 7
	_cracks.heat = 0.7
	_cracks.hot = 0.3
	_cracks.redraw_every = 0.1
	_cracks.star = false
	_cracks.build_radial(ctx.rng, 10, 3.6, ctx.rng.randf() * TAU, 0.85, 6, 0.22, Vector2i(2, 3))
	track(_cracks, ctx.ground)
	var spread := create_tween()
	spread.tween_interval(0.3)
	spread.tween_property(_cracks, "progress", 1.0, T_RISE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	at(T_RISE, _rise)
	at(T_ERUPT, _erupt)
	_schedule_barrage()
	at(T_SINK, _sink)


func _fx_process(delta: float) -> void:
	if _quake > 0.0:
		ctx.shake.add_trauma(_quake * delta * 2.0)
		ctx.env.shake_radius(origin, RADIUS, _quake * 4.0)


func _rise() -> void:
	ctx.play(&"cf_rise", origin)
	_quake = 1.0
	create_tween().tween_property(_sigil, "alpha", 0.0, 0.6)
	create_tween().tween_property(_cracks, "heat", 1.0, 0.4)
	_volcano = Volcano.new()
	_volcano.radius_px = FxParts.PX_PER_UNIT_MAJOR * VOLCANO_RADIUS
	_volcano.height = VOLCANO_HEIGHT
	_volcano.lights = ctx.lights
	_volcano.ground_pos = origin
	_volcano.position = _center_px
	_volcano.setup(ctx.rng)
	track(_volcano, ctx.world)
	create_tween().tween_property(_volcano, "rise", 1.0, RISE_TIME).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# Molten glow on the ground round the foot of the mountain (on the ground only, so the rock stays dark).
	_glow = FxParts.ground_light(self, origin, VOLCANO_RADIUS * 1.8, LAVA_LIGHT, 0.0)
	_glow.tween_param("intensity", 0.0, 0.9, RISE_TIME)
	var ring := FxParts.shockwave(self, origin, 3.4, FxParts.DUST_RING)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.1, 1.0, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.4, 0.5)
	ring.life = 0.95
	var crater := FxParts.decal(self, origin, VOLCANO_RADIUS * 1.5, Color("ff6a1a"), Color("ffd27a"))
	crater.z_index = 1
	crater.tween_param("heat", 1.0, 0.3, 6.0)
	crater.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	# Rock tearing loose as the mountain shoulders up.
	for k in 6:
		at(t + k * 0.2, func():
			FxParts.debris(self, _center_px, 14, FxParts.PX_PER_UNIT_MAJOR * 1.6, Vector2(60, 220), FxParts.HOT_ROCK,
				Vector2(2.5, 6.0), true)
			FxParts.smoke(self, _center_px, FxParts.PX_PER_UNIT_MAJOR * 1.9, 18.0, 0.25, Vector2(10, 30), Vector2(4, 8),
				Vector2(1.0, 1.8), Color(0, 0, 0, 0), Set2Parts.DUST_CLOUD))
	for e in ctx.field.in_radius(origin, VOLCANO_RADIUS + 0.3):
		ctx.field.kill(e, &"stone", origin)
	ctx.field.knock_from(origin, VOLCANO_RADIUS + 0.3, VOLCANO_RADIUS + 2.0, 6.0)
	ctx.env.damage_radius(origin, VOLCANO_RADIUS + 0.3, 99999.0, &"stone")
	at(t + RISE_TIME, func(): _quake = 0.2)


func _erupt() -> void:
	ctx.play(&"cf_erupt", origin)
	ctx.impact.impact_frame(0.05, ctx.impact.focus_of(_volcano.crater_top()), Color(1.0, 0.9, 0.7), Color(0.12, 0.02, 0.0))
	ctx.impact.hitstop(0.07)
	ctx.impact.aberration(3.0, 0.4)
	ctx.flash.call(Color(1.0, 0.7, 0.35, 0.4), 0.3)
	ctx.shake.add_trauma(0.9)
	ctx.shake.kick(Vector2(0, -7))
	var tw := create_tween()
	tw.tween_property(_volcano, "erupting", 1.0, 0.15)
	tw.tween_interval(T_BARRAGE_END - T_ERUPT)
	tw.tween_property(_volcano, "erupting", 0.0, 1.0)
	var top := _volcano.crater_top()
	var bloom := FxParts.bloom(self, top, 70.0, LAVA_LIGHT, 1.0, 0.9)
	bloom.tween_param("intensity", 1.0, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	bloom.life = 0.62
	var rays := FxParts.screen_rays(self, top, 170.0, Color(1.0, 0.72, 0.38), 36.0, 1.0)
	rays.tween_param("intensity", 1.2, 0.0, 0.6)
	rays.life = 0.72
	# Lava fountain, a spray of hot rock and giant fire stones hurled into the sky.
	var fountain := FxParts.emitter(self, ctx.overhead, top, PixelParticles.Shape.SQUARE, FxParts.FIRE_LIFE, 170.0, 1.2, {
		"radius": 8.0, "speed": Vector2(20, 120), "alt_speed": Vector2(140, 340), "life": Vector2(0.5, 1.0),
		"size": Vector2(1, 3),
	})
	fountain.gravity = 380.0
	FxParts.debris(self, top, 55, 10.0, Vector2(50, 230), FxParts.HOT_ROCK, Vector2(2.5, 6.5), true)
	for i in 5:
		var s := FireStone.new()
		s.size = ctx.rng.randf_range(22.0, 30.0)
		s.seed = ctx.rng.randf() * 10.0
		s.dir = Vector2(ctx.rng.randf_range(-0.55, 0.55), -1.0)
		s.position = top
		track(s, ctx.overhead)
		var fly := s.create_tween()
		fly.tween_interval(i * 0.08)
		fly.tween_property(s, "position", top + Vector2(s.dir.x * 280.0, -420.0), 0.75) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fly.tween_callback(s.queue_free)
	_plume = FxParts.smoke(self, top, 16.0, 30.0, duration - t - 2.0, Vector2(50, 110), Vector2(6, 10), Vector2(1.8, 3.0),
		Color("ff5a1a"), ASH_SMOKE)
	_plume.underglow_life = 0.35
	_lava_voice = ctx.play(&"cf_lava", origin, -6.0)


func _schedule_barrage() -> void:
	var placed: Array[Vector2] = []
	var misses := 0
	while placed.size() < STONES and misses < 800:
		var a := ctx.rng.randf() * TAU
		var d := lerpf(VOLCANO_RADIUS + 0.6, RADIUS, sqrt(ctx.rng.randf()))
		var g := origin + Vector2.RIGHT.rotated(a) * d
		var ok := true
		for q in placed:
			if q.distance_to(g) < 1.1:
				ok = false
				break
		if ok:
			placed.append(g)
			misses = 0
		else:
			misses += 1
	for i in placed.size():
		var when := lerpf(T_BARRAGE, T_BARRAGE_END - 0.5, float(i) / placed.size()) + ctx.rng.randf_range(-0.08, 0.08)
		at(when, _drop_stone.bind(placed[i]))


func _drop_stone(g: Vector2) -> void:
	var target := Iso.ground_to_screen(g)
	var side := signf(target.x - _center_px.x)
	if side == 0.0:
		side = 1.0
	var start := target + Vector2(-side * ctx.rng.randf_range(90, 170), -ctx.rng.randf_range(280, 340))
	var s := FireStone.new()
	s.size = ctx.rng.randf_range(17.0, 25.0)
	s.seed = ctx.rng.randf() * 10.0
	s.dir = (target - start).normalized()
	s.position = start
	track(s, ctx.overhead)
	if ctx.rng.randf() < 0.5:
		ctx.play(&"cf_fall", g, -8.0)
	var fall := 0.5
	var tw := s.create_tween()
	tw.tween_property(s, "position", target, fall).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		s.queue_free()
		_stone_impact(g))
	# Ash smoke and embers streaming off the falling stone.
	var trail := FxParts.emitter(self, ctx.overhead_back, Vector2.ZERO, PixelParticles.Shape.PUFF, ASH_SMOKE, 36.0, fall, {
		"radius": 4.0, "speed": Vector2(2, 10), "alt_speed": Vector2(4, 14), "life": Vector2(0.6, 1.1),
		"size": Vector2(3, 5), "size_end_mul": 2.0,
	})
	var embers := FxParts.emitter(self, ctx.overhead, Vector2.ZERO, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 50.0, fall, {
		"radius": 6.0, "speed": Vector2(10, 40), "alt_speed": Vector2(-10, 20), "life": Vector2(0.3, 0.6),
		"size": Vector2(1, 2),
	})
	var follow := func(k: float) -> void:
		var p: Vector2 = start.lerp(target, k * k)
		trail.spec["offset"] = p
		embers.spec["offset"] = p
	create_tween().tween_method(follow, 0.0, 1.0, fall)


func _stone_impact(g: Vector2) -> void:
	var sp := Iso.ground_to_screen(g)
	ctx.play(&"cf_impact", g, -2.0)
	ctx.shake.add_trauma(0.25)
	# Spiky burst of fire: flame spikes, a flash, fireball puffs rolling out and flaming shrapnel.
	var burst := FxParts.screen_rays(self, sp + Vector2(0, -6), 72.0, Color(1.0, 0.6, 0.22), 22.0, 0.75)
	burst.set_param("inner", 0.05)
	burst.tween_param("intensity", 1.9, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.42
	var flash := FxParts.bloom(self, sp + Vector2(0, -10), 50.0, LAVA_LIGHT, 1.4, 0.8)
	flash.tween_param("intensity", 1.4, 0.0, 0.4)
	flash.life = 0.42
	var fire := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE)
	fire.drag = 2.2
	fire.burst(16, {
		"radius": 8.0, "dir": PixelParticles.Dir.OUTWARD, "speed": Vector2(40, 130), "alt": Vector2(0, 8),
		"alt_speed": Vector2(30, 110), "life": Vector2(0.3, 0.6), "size": Vector2(3, 6), "size_end_mul": 1.5,
	})
	FxParts.sparks(self, ctx.overhead, sp, 26, FxParts.FIRE_LIFE, Vector2(70, 240), Vector2(60, 280))
	FxParts.debris(self, sp, 12, 5.0, Vector2(50, 180), FxParts.HOT_ROCK, Vector2(2.0, 5.0), true)
	var ring := FxParts.shockwave(self, g, 1.5, FxParts.FIRE)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.15)
	ring.life = 0.4
	var light := FxParts.ground_light(self, g, 1.8, LAVA_LIGHT)
	# Short-lived: every live light is sampled by each enemy and building per frame.
	light.tween_param("intensity", 1.3, 0.0, 1.0, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 1.05
	# Scorched crater with a glowing lava pool and cracks, flames licking up and a thin smoke column.
	var scorch := FxParts.decal(self, g, 1.05, Color("ff6a1a"), Color("ffd27a"), Color(0.08, 0.05, 0.04, 0.75))
	scorch.tween_param("heat", 1.0, 0.25, 2.0)
	scorch.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	var pool := FxParts.decal(self, g, 0.42, Color("ffb040"), Color("fff0b8"), Color(1.0, 0.52, 0.12, 0.95))
	pool.z_index = 2
	pool.tween_param("heat", 1.0, 0.6, 3.0)
	pool.tween_param("fade", 1.0, 0.0, 1.2, duration - t - 1.3)
	var cracks := CrackNet.new()
	cracks.place(g)
	cracks.z_index = 7
	cracks.redraw_every = 0.15
	cracks.build_radial(ctx.rng, 5, 1.3, ctx.rng.randf() * TAU, 0.6, 2, 0.15, Vector2i(1, 1))
	track(cracks, ctx.ground)
	cracks.create_tween().tween_property(cracks, "progress", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var cool := cracks.create_tween()
	cool.tween_property(cracks, "hot", 0.0, 0.5)
	cool.parallel().tween_property(cracks, "heat", 0.75, 2.5)
	cool.tween_interval(maxf(duration - t - 4.3, 0.1))
	cool.tween_property(cracks, "fade", 0.0, 1.0)
	FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.PUFF, FxParts.FIRE_LIFE, 12.0, maxf(duration - t - 1.0, 1.5), {
		"radius": 6.0, "speed": Vector2(0, 6), "alt_speed": Vector2(16, 44), "life": Vector2(0.3, 0.6),
		"size": Vector2(1.5, 3.5), "size_end_mul": 0.3,
	})
	FxParts.smoke(self, sp, 6.0, 5.0, duration - t - 2.5, Vector2(14, 32), Vector2(3, 6), Vector2(1.4, 2.2), Color(0, 0, 0, 0),
		ASH_SMOKE)
	for e in ctx.field.in_radius(g, STONE_KILL):
		ctx.field.kill(e, &"cinder", g)
	ctx.field.knock_from(g, STONE_KILL, 1.8, 4.5)
	ctx.env.damage_radius(g, 1.1, 70.0, &"cinder")


func _sink() -> void:
	_quake = 0.3
	ctx.play(&"cf_rise", origin, -8.0)
	create_tween().tween_property(_volcano, "heat", 0.35, 1.2)
	var tw := create_tween()
	tw.tween_property(_volcano, "sink", 1.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _quake = 0.0)
	if is_instance_valid(_glow):
		_glow.tween_param("intensity", 0.9, 0.0, 1.4)
	# The ground cracks cool to embers and fade out at the end.
	var cool := create_tween()
	cool.tween_property(_cracks, "heat", 0.6, 1.4)
	cool.tween_interval(maxf(duration - T_SINK - 2.6, 0.1))
	cool.tween_property(_cracks, "fade", 0.0, 1.0)
	FxParts.smoke(self, _center_px, FxParts.PX_PER_UNIT_MAJOR * 1.5, 18.0, 1.6, Vector2(15, 40), Vector2(5, 9),
		Vector2(1.2, 2.2), Color(0, 0, 0, 0), Set2Parts.DUST_CLOUD)
	# Smoking crater left behind: a molten pool and a column of ash smoke.
	var pool := FxParts.decal(self, origin, 0.9, Color("ffb040"), Color("fff0b8"), Color(1.0, 0.5, 0.12, 0.95))
	pool.z_index = 2
	pool.tween_param("fade", 0.0, 1.0, 1.2)
	pool.tween_param("heat", 1.0, 0.5, 2.5)
	pool.tween_param("fade", 1.0, 0.0, 1.0, duration - t - 1.2)
	FxParts.smoke(self, _center_px, 14.0, 12.0, duration - t - 1.4, Vector2(30, 70), Vector2(5, 9), Vector2(1.6, 2.6),
		Color("ff5a1a"), ASH_SMOKE)
	var haze := FxParts.heat_haze(self, _center_px, 110.0, 1.6)
	haze.tween_param("strength", 1.6, 0.0, 1.5, 1.2)
	haze.life = 2.8
	FxParts.emitter(self, ctx.overhead, _center_px, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 30.0, duration - t - 0.6, {
		"radius": FxParts.particle_radius(RADIUS * 0.8), "alt": Vector2(0, 6), "alt_speed": Vector2(12, 40),
		"speed": Vector2(0, 10), "life": Vector2(0.6, 1.4), "size": Vector2(1, 1),
	})
	at(duration - 1.3, func():
		ctx.fade_out(_lava_voice, 1.2)
		ctx.impact.dim(0.0, 0.6))
