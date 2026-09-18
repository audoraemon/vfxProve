class_name SigilRune
extends Node2D
## Magic warning circle on the ground plane (ground units): double ring with rune ticks, counter-rotating
## inner ring, spokes and a glyph per skill. Glyphs: storm, magma, spiral, earth, dragon.

var radius := 5.0
var color := Color.WHITE
var glyph := "storm"
var reveal := 0.0
var alpha := 1.0
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if reveal <= 0.0 or alpha <= 0.0:
		return
	var pulse := 0.75 + 0.25 * sin(_time * 7.0)
	var c := Color(color, alpha * pulse)
	var hi := Color(color.lightened(0.55), alpha * pulse)
	var dim := Color(color, alpha * 0.45)
	var r := radius * reveal
	var spin := _time * 0.3
	# Outer double ring with rune ticks.
	_ring(r, c, 2)
	_ring(r * 0.9, dim, 1)
	for i in 36:
		var d := Vector2.RIGHT.rotated(spin + TAU * i / 36.0)
		var t := 0.06 if i % 3 == 0 else 0.03
		draw_line(d * r * (0.9 + 0.005), d * r * (0.9 + t), c, -1.0)
		if i % 6 == 0:
			draw_rect(Rect2(d * r * 0.95 - Vector2(0.06, 0.06), Vector2(0.12, 0.12)), hi)
	# Inner ring counter-rotating with dashes.
	var ri := r * 0.62
	for i in 24:
		if i % 2 == 0:
			var a0 := -spin * 1.4 + TAU * i / 24.0
			draw_arc(Vector2.ZERO, ri, a0, a0 + TAU / 24.0, 4, c, -1.0)
	_ring(ri * 0.95, dim, 1)
	match glyph:
		"storm":
			_draw_storm(r, ri, c, hi)
		"magma":
			_draw_magma(r, ri, c, hi)
		"spiral":
			_draw_spiral(r, c, hi)
		"earth":
			_draw_earth(r, c, hi)
		"dragon":
			_draw_dragon(ri, c, hi)


func _ring(r: float, col: Color, strokes: int) -> void:
	for s in strokes:
		draw_arc(Vector2.ZERO, r + s * 0.035, 0.0, TAU, 72, col, -1.0)


func _thick(a: Vector2, b: Vector2, col: Color) -> void:
	var n := (b - a).orthogonal().normalized() * 0.035
	draw_line(a, b, col, -1.0)
	draw_line(a + n, b + n, col, -1.0)


func _draw_storm(r: float, ri: float, c: Color, hi: Color) -> void:
	# Glowing halo round the outer ring.
	for k in 4:
		var off := 0.03 + k * 0.035
		var halo := Color(color, alpha * (0.5 - k * 0.11))
		draw_arc(Vector2.ZERO, r + off, 0.0, TAU, 72, halo, -1.0)
		draw_arc(Vector2.ZERO, r - off, 0.0, TAU, 72, halo, -1.0)
	# Dotted rune ring and a middle ring.
	for i in 48:
		var d := Vector2.RIGHT.rotated(-_time * 0.5 + TAU * i / 48.0)
		draw_rect(Rect2(d * r * 0.8 - Vector2(0.025, 0.025), Vector2(0.05, 0.05)), hi if i % 4 == 0 else c)
	_ring(ri * 0.62, c, 2)
	# Compass spikes piercing out past the ring, short ticks between them.
	for i in 4:
		var d := Vector2.RIGHT.rotated(TAU * i / 4.0)
		var n := d.orthogonal()
		draw_colored_polygon(PackedVector2Array([d * r * 0.16 + n * r * 0.05, d * r * 1.3, d * r * 0.16 - n * r * 0.05]),
			Color(color.lightened(0.3), alpha * 0.75))
		_thick(d * r * 0.16, d * r * 1.3, hi)
		var diag := d.rotated(TAU / 8.0)
		_thick(diag * ri * 0.5, diag * ri * 0.95, c)
	# Bright eye in the middle.
	draw_circle(Vector2.ZERO, r * 0.11, Color(color.lightened(0.75), alpha))
	_ring(r * 0.18, hi, 2)


func _draw_magma(r: float, ri: float, c: Color, hi: Color) -> void:
	# Bold glowing outer and inner rings with a soft halo, a dotted rune ring and a middle ring.
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(color, alpha * 0.28), 0.34)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(color.lightened(0.25), alpha * 0.9), 0.1)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, hi, -1.0)
	draw_arc(Vector2.ZERO, ri, 0.0, TAU, 72, Color(color, alpha * 0.25), 0.22)
	draw_arc(Vector2.ZERO, ri, 0.0, TAU, 72, Color(color.lightened(0.25), alpha * 0.85), 0.07)
	for i in 60:
		var d := Vector2.RIGHT.rotated(_time * 0.4 + TAU * i / 60.0)
		draw_rect(Rect2(d * r * 0.8 - Vector2(0.03, 0.03), Vector2(0.06, 0.06)), hi if i % 5 == 0 else c)
	_ring(r * 0.8 + 0.08, c, 1)
	_ring(ri * 0.55, hi, 2)
	# Radial spokes reaching out past the ring, and zig-zag crack spokes inside it.
	for i in 12:
		var d := Vector2.RIGHT.rotated(TAU * i / 12.0 + 0.13)
		_thick(d * r * (0.62 if i % 2 == 0 else 0.84), d * r * (1.28 if i % 2 == 0 else 1.1), hi if i % 2 == 0 else c)
		var p0 := d * ri * 0.3
		var p1 := p0 + d * ri * 0.3 + d.orthogonal() * ri * 0.06
		_thick(p0, p1, c)
		_thick(p1, p1 + d * ri * 0.3 - d.orthogonal() * ri * 0.05, c)
	# Bright core and a flame glyph.
	draw_circle(Vector2.ZERO, ri * 0.2, Color(color.lightened(0.6), alpha * 0.9))
	var s := ri * 0.3
	var flame := [Vector2(0, -1), Vector2(0.45, -0.1), Vector2(0.35, 0.55), Vector2(0, 0.8), Vector2(-0.35, 0.55),
		Vector2(-0.45, -0.1), Vector2(-0.1, -0.35), Vector2(0, -1)]
	for i in flame.size() - 1:
		_thick(flame[i] * s, flame[i + 1] * s, hi)
	_thick(Vector2(0, -0.2) * s, Vector2(0.15, 0.45) * s, hi)


func _draw_spiral(r: float, c: Color, hi: Color) -> void:
	# Three spiral arms winding inward, rotating with the wind.
	for arm in 3:
		var prev := Vector2.ZERO
		for k in 40:
			var t := k / 39.0
			var a := -_time * 1.2 + TAU * arm / 3.0 + t * 5.0
			var p := Vector2.RIGHT.rotated(a) * r * 0.85 * t
			if k > 0:
				draw_line(prev, p, hi if t < 0.5 else c, -1.0)
			prev = p
	draw_arc(Vector2.ZERO, r * 0.12, 0.0, TAU, 16, hi, -1.0)


func _draw_earth(r: float, c: Color, hi: Color) -> void:
	# Concentric rings crossed by long radial spokes, like the sun-dial rune of the ancients.
	for k in [0.25, 0.42]:
		_ring(r * k, c, 2)
	for i in 16:
		var d := Vector2.RIGHT.rotated(TAU * i / 16.0)
		_thick(d * r * 0.08, d * r * (0.88 if i % 2 == 0 else 0.62), c if i % 2 else hi)
	var s := r * 0.12
	draw_rect(Rect2(Vector2(-s, -s) * 0.5, Vector2(s, s)), hi, false, -1.0)


func _draw_dragon(ri: float, c: Color, hi: Color) -> void:
	# Stylized coiled dragon: S-curve body, wing chevrons and a head.
	var s := ri * 0.62
	var body: Array[Vector2] = []
	for k in 30:
		var t := k / 29.0
		body.append(Vector2(sin(t * PI * 2.2) * 0.45, -1.0 + t * 2.0) * s)
	for i in body.size() - 1:
		_thick(body[i], body[i + 1], hi)
	var head := body[0]
	_thick(head, head + Vector2(0.4, -0.15) * s, hi)
	_thick(head, head + Vector2(0.15, -0.35) * s, hi)
	for sgn in [-1.0, 1.0]:
		var w0 := Vector2(0.05 * sgn, -0.35) * s
		_thick(w0, Vector2(0.75 * sgn, -0.75) * s, c)
		_thick(Vector2(0.75 * sgn, -0.75) * s, Vector2(0.55 * sgn, -0.3) * s, c)
		_thick(Vector2(0.55 * sgn, -0.3) * s, Vector2(0.8 * sgn, -0.15) * s, c)
