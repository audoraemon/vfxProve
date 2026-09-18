class_name LanePath
extends Node2D
## Lane telegraph on the ground plane in lane space: x along the lane (0..length), y across.
## Styles: "storm" (glowing road of light with star runes), "water" (flowing ripples and wave glyph),
## "wind" (streaming wind lines).

var length := 10.0
var width := 5.0
var color := Color.WHITE
var style := "storm"
var reveal := 0.0
var alpha := 1.0
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var span := length * reveal
	if span <= 0.01 or alpha <= 0.0:
		return
	var hw := width * 0.5
	if style == "storm":
		_draw_storm(span, hw)
		return
	var pulse := 0.8 + 0.2 * sin(_time * 8.0)
	var edge := Color(color, alpha * pulse)
	var soft := Color(color, alpha * 0.12)
	var hi := Color(color.lightened(0.6), alpha * pulse)
	draw_rect(Rect2(0, -hw, span, width), soft)
	for sgn in [-1.0, 1.0]:
		draw_line(Vector2(0, hw * sgn), Vector2(span, hw * sgn), edge, -1.0)
		draw_line(Vector2(0, hw * sgn * 0.93), Vector2(span, hw * sgn * 0.93), Color(color, alpha * 0.4), -1.0)
	match style:
		"water":
			# Ripples flowing down the lane.
			for row in range(-2, 3):
				var y := row * hw * 0.38
				var x0 := fmod(_time * 1.8 + row * 0.37, 1.2) - 1.2
				while x0 < span:
					var a := maxf(x0, 0.0)
					var b := minf(x0 + 0.5, span)
					if b > a:
						draw_line(Vector2(a, y + sin(a * 3.0) * 0.06), Vector2(b, y + sin(b * 3.0) * 0.06), hi, -1.0)
					x0 += 1.2
			# Boundary markers.
			var m := 0.0
			while m < span:
				for sgn in [-1.0, 1.0]:
					draw_rect(Rect2(Vector2(m, hw * sgn) - Vector2(0.08, 0.08), Vector2(0.16, 0.16)), hi)
				m += 1.5
		"wind":
			for row in range(-3, 4):
				var y := row * hw * 0.28
				var x0 := fmod(_time * 3.0 + row * 0.53, 2.0) - 2.0
				while x0 < span:
					var a := maxf(x0, 0.0)
					var b := minf(x0 + 0.8, span)
					if b > a:
						draw_line(Vector2(a, y), Vector2(b, y + 0.05), Color(hi, hi.a * 0.7), -1.0)
					x0 += 2.0


## Storm: a glowing road of light with haloed double edges, energy pulses running in toward the middle, 4-point
## star runes along the centre line and diamond marks at both ends.
func _draw_storm(span: float, hw: float) -> void:
	var pulse := 0.8 + 0.2 * sin(_time * 8.0)
	var hi := Color(color.lightened(0.6), alpha * pulse)
	draw_rect(Rect2(0, -hw, span, hw * 2.0), Color(color, alpha * 0.3))
	draw_rect(Rect2(0, -hw * 0.4, span, hw * 0.8), Color(color.lightened(0.2), alpha * 0.12))
	for sgn in [-1.0, 1.0]:
		var y: float = hw * sgn
		draw_rect(Rect2(0, y - 0.13, span, 0.26), Color(color, alpha * 0.32 * pulse))
		draw_rect(Rect2(0, y - 0.06, span, 0.12), Color(color.lightened(0.3), alpha * 0.75 * pulse))
		draw_line(Vector2(0, y), Vector2(span, y), hi, -1.0)
		draw_line(Vector2(0, y * 0.84), Vector2(span, y * 0.84), Color(color.lightened(0.2), alpha * 0.6), -1.0)
	# Energy pulses running along the edges from both ends toward the middle.
	var mid := length * 0.5
	for k in 6:
		var f := fposmod(_time * 0.9 + k / 6.0, 1.0)
		var y := hw * (1.0 if k % 2 == 0 else -1.0)
		for side in [-1.0, 1.0]:
			var x: float = mid - side * mid * (1.0 - f)
			if x >= 0.0 and x <= span:
				draw_line(Vector2(x - 0.35, y), Vector2(x + 0.35, y), Color(1, 1, 1, alpha * f), -1.0)
	# Star runes along the centre line.
	var x0 := 0.9
	var i := 0
	while x0 < span - 0.4:
		var s := 0.44 if i % 2 == 0 else 0.3
		_star(Vector2(x0, 0), s * 1.8, Color(color, alpha * 0.35 * pulse))
		_star(Vector2(x0, 0), s, hi)
		x0 += 1.15
		i += 1
	# Diamond marks at both ends.
	for x in [0.0, span]:
		if x > 0.0 and reveal < 1.0:
			continue
		_diamond(Vector2(x, 0), 0.7, hw * 0.8, hi)
		_diamond(Vector2(x, 0), 0.34, hw * 0.38, hi)


func _star(at: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var a := TAU * k / 8.0
		var r := s if k % 2 == 0 else s * 0.26
		pts.append(at + Vector2(cos(a) * r, sin(a) * r * 0.85))
	draw_colored_polygon(pts, col)


func _diamond(at: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array([at + Vector2(-rx, 0), at + Vector2(0, -ry), at + Vector2(rx, 0), at + Vector2(0, ry),
		at + Vector2(-rx, 0)])
	draw_polyline(pts, Color(col, col.a * 0.5), 0.1)
	draw_polyline(pts, col, -1.0)
