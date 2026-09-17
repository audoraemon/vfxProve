class_name TsunamiWave
extends Node2D
## Breaking wave built as a real surface: every section across the wall has a side profile (back slope,
## concave face, curling lip with thickness) that is extruded along the wall and projected to iso.
## Several barrels peel sideways along the wall. Surfaces are painted back to front and shaded by
## `wave_body.gdshader` (palette bands, foam clumps, flow veins).
## Profile units: forward in ground units, height in pixels.

const SH_BODY := preload("res://shaders/wave_body.gdshader")
const SEG_SECTIONS := 12
const BACK_PTS := 9
const FACE_PTS := 9
const LIP_PTS := 12
const SKIRT_PTS := 4
const SURFACES := ["skirt", "back", "face", "lip_in", "lip_out"]
const DEPTH_BUCKETS := 400
const DEPTH_RANGE := 400.0
const BIAS := {"skirt": -10000.0, "back": 0.0, "face": 0.0, "lip_in": 1.0, "lip_out": 2.0}

## Ground direction the wave travels and wall width in ground units.
var dir := Vector2(1, 0)
var width := 5.4
## Full crest height in pixels.
var max_height := 140.0
## 0..1 rise and curl amounts, driven by tweens.
var height := 0.0
var curl := 0.0
var fade := 1.0
var barrels := 3.0
var seed := 0.0

var _mat: ShaderMaterial
var _time := 0.0
var _indices := PackedInt32Array()
var _points := PackedVector2Array()
var _colors := PackedColorArray()
var _uvs := PackedVector2Array()
var _depth := PackedFloat32Array()
var _buckets: Array[PackedInt32Array] = []


func _init() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = SH_BODY
	material = _mat
	_buckets.resize(DEPTH_BUCKETS)
	for b in DEPTH_BUCKETS:
		_buckets[b] = PackedInt32Array()


func set_param(param: StringName, value: Variant) -> void:
	_mat.set_shader_parameter(param, value)


func _process(delta: float) -> void:
	_time += delta
	_mat.set_shader_parameter(&"u_time", _time)
	_mat.set_shader_parameter(&"fade", fade)
	queue_redraw()


## Height in pixels where the lip throws spray, for emitters.
func lip_height() -> float:
	return max_height * height * (1.0 - 0.6 * curl)


func _taper(u: float) -> float:
	return sqrt(smoothstep(0.0, 0.1, u) * smoothstep(1.0, 0.9, u))


## Side profile of one wall section, in pixels: x forward from the foot, y up.
## Returns {surface: [[Vector2 profile point, Color shading], ...], "center": curl center}.
## BACK_PTS == FACE_PTS so back+lip_out and face+lip_in pair up point for point in the cap.
func _profile(h: float, cl: float) -> Dictionary:
	var r := h * (0.14 + 0.3 * cl)
	var xc := h * (0.06 + 0.16 * cl)
	var c := Vector2(xc, h - r)
	var theta_max := cl * 1.5 * PI
	var prof := {"back": [], "face": [], "skirt": [], "lip_in": [], "lip_out": [], "center": c}
	for j in BACK_PTS:
		var w := float(j) / (BACK_PTS - 1)
		var y := h * w * w * (3.0 - 2.0 * w)
		prof.back.append([Vector2(lerpf(-0.65 * h, xc, w), y), Color(0.3 + 0.6 * w * w, smoothstep(0.82, 1.0, w) * 0.75, 0.0)])
	for j in FACE_PTS:
		var w := float(j) / (FACE_PTS - 1)
		var x := lerpf(0.1 * h, xc, w) - 0.14 * h * sin(PI * w) * cl
		var light := 0.62 - 0.5 * smoothstep(0.3, 1.0, w) * cl
		prof.face.append([Vector2(x, lerpf(0.0, h - 0.4 * r, w)), Color(light, 1.0 - smoothstep(0.0, 0.25, w), 0.0)])
	for j in SKIRT_PTS:
		var w := float(j) / (SKIRT_PTS - 1)
		prof.skirt.append([Vector2(lerpf(0.05, 0.5, w) * h, 0.0), Color(0.7, 1.0 - w, 1.0)])
	for j in LIP_PTS:
		var w := float(j) / (LIP_PTS - 1)
		var th := theta_max * w
		var k := 1.0 - 0.5 * th / PI
		var k_in := maxf(k - 0.4 * (1.0 - w), 0.0)
		var dirv := Vector2(sin(th), cos(th))
		prof.lip_out.append([c + dirv * r * k, Color(0.95 - 0.3 * w, 0.45 + 0.6 * smoothstep(0.2, 0.8, w), 0.0)])
		prof.lip_in.append([c + dirv * r * k_in, Color(0.1 + 0.12 * w, smoothstep(0.7, 1.0, w) * 0.8, 0.0)])
	return prof


func _draw() -> void:
	if height <= 0.01 or fade <= 0.01:
		return
	var fwd_hat := Iso.ground_to_screen(dir).normalized()
	var side := Iso.ground_to_screen(dir.orthogonal())
	_points.clear()
	_colors.clear()
	_uvs.clear()
	_indices.clear()
	_depth.clear()
	for b in DEPTH_BUCKETS:
		_buckets[b].clear()
	# The wall is split into barrels that peel sideways. Each barrel swells toward the end nearest the
	# camera and ends in a cut, so its curl cross-section (cap) shows like in hand-painted waves.
	var near_high := side.y >= 0.0
	var phase := fposmod(_time * 0.08 + seed, 1.0)
	for k in int(barrels) + 2:
		var u0 := maxf((k - phase) / barrels, 0.0)
		var u1 := minf((k + 1 - phase) / barrels, 1.0)
		if u1 - u0 < 0.01:
			continue
		var profiles: Array = []
		var us: Array[float] = []
		for i in SEG_SECTIONS + 1:
			var u := lerpf(u0, u1, float(i) / SEG_SECTIONS)
			var f := clampf((u - (k - phase) / barrels) * barrels, 0.0, 1.0)
			if not near_high:
				f = 1.0 - f
			us.append(u)
			profiles.append(_profile(max_height * height * _taper(u) * (0.7 + 0.3 * pow(f, 1.5)), curl * (0.45 + 0.55 * f)))
		for surf in SURFACES:
			_emit_surface(surf, profiles, us, fwd_hat, side)
		var cap_i := SEG_SECTIONS if near_high else 0
		_emit_cap(profiles[cap_i], side * (us[cap_i] - 0.5) * width, fwd_hat, us[cap_i])
	for b in _buckets:
		_indices.append_array(b)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _indices, _points, _colors, _uvs)


func _add_point(foot: Vector2, y: float, col: Color, uv: Vector2) -> int:
	_points.append(foot - Vector2(0.0, y))
	_colors.append(col)
	_uvs.append(uv)
	_depth.append(foot.y)
	return _points.size() - 1


func _add_tri(a: int, b: int, c: int, bias: float) -> void:
	var z := (_depth[a] + _depth[b] + _depth[c]) / 3.0 + bias
	var key := clampi(int((z + DEPTH_RANGE) / (2.0 * DEPTH_RANGE) * DEPTH_BUCKETS), 0, DEPTH_BUCKETS - 1)
	_buckets[key].append_array([a, b, c])


func _emit_surface(surf: String, profiles: Array, us: Array[float], fwd_hat: Vector2, side: Vector2) -> void:
	var start := _points.size()
	var n: int = (profiles[0][surf] as Array).size()
	for i in profiles.size():
		var base := side * (us[i] - 0.5) * width
		var row: Array = profiles[i][surf]
		var arc := 0.0
		var prev := Vector2.ZERO
		for j in n:
			var pp: Vector2 = row[j][0]
			var scr := base + fwd_hat * pp.x - Vector2(0.0, pp.y)
			if j > 0:
				arc += scr.distance_to(prev)
			prev = scr
			_add_point(base + fwd_hat * pp.x, pp.y, row[j][1], Vector2(us[i] * width * 4.0 + seed * 10.0, arc / 14.0))
	var bias: float = BIAS[surf]
	for i in profiles.size() - 1:
		for j in n - 1:
			var a := start + i * n + j
			var c := a + n
			_add_tri(a, a + 1, c, bias)
			_add_tri(a + 1, c + 1, c, bias)


## Cross-section at a barrel's cut: the hooked water body, then the dark hollow inside the curl with
## spiral bands.
func _emit_cap(prof: Dictionary, base: Vector2, fwd_hat: Vector2, u: float) -> void:
	var outer: Array = prof.back + prof.lip_out
	var inner: Array = prof.face + prof.lip_in
	var start := _points.size()
	for j in outer.size():
		var w := float(j) / (outer.size() - 1)
		var po: Vector2 = outer[j][0]
		var pi_: Vector2 = inner[j][0]
		_add_point(base + fwd_hat * po.x, po.y, Color(0.85, 0.72 + 0.4 * smoothstep(0.55, 0.85, w), 0.0), Vector2(u * 20.0, w * 12.0))
		_add_point(base + fwd_hat * pi_.x, pi_.y, Color(0.4, 0.0, 0.0), Vector2(u * 20.0 + 1.5, w * 12.0))
	for j in outer.size() - 1:
		var a := start + j * 2
		_add_tri(a, a + 2, a + 1, 3.0)
		_add_tri(a + 2, a + 3, a + 1, 3.0)
	# Hollow: fan from the curl center over the face and the underside of the lip.
	var h: float = (prof.back[prof.back.size() - 1][0] as Vector2).y
	if h < 4.0:
		return
	var c: Vector2 = prof.center
	var hub := _add_point(base + fwd_hat * c.x, c.y, Color(0.05, 0.0, 0.5), Vector2(0.0, 0.0))
	var first := _points.size()
	for j in inner.size():
		var p: Vector2 = inner[j][0]
		_add_point(base + fwd_hat * p.x, p.y, Color(0.12, 0.0, 0.5), Vector2(float(j) / (inner.size() - 1), 1.0))
	for j in inner.size() - 1:
		_add_tri(hub, first + j, first + j + 1, 3.5)
