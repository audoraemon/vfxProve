class_name LanePath
extends Node2D
## Lane telegraph on the ground plane in lane space: x along the lane (0..length), y across.
## Styles: "storm" (glowing line with diamond runes), "water" (flowing ripples and wave glyph),
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
	var pulse := 0.8 + 0.2 * sin(_time * 8.0)
	var edge := Color(color, alpha * pulse)
	var soft := Color(color, alpha * 0.12)
	var hi := Color(color.lightened(0.6), alpha * pulse)
	draw_rect(Rect2(0, -hw, span, width), soft)
	for sgn in [-1.0, 1.0]:
		draw_line(Vector2(0, hw * sgn), Vector2(span, hw * sgn), edge, -1.0)
		draw_line(Vector2(0, hw * sgn * 0.93), Vector2(span, hw * sgn * 0.93), Color(color, alpha * 0.4), -1.0)
	match style:
		"storm":
			draw_line(Vector2(0, 0), Vector2(span, 0), hi, -1.0)
			var x := 0.5
			while x < span:
				var s := 0.22 if int(x) % 2 == 0 else 0.14
				draw_colored_polygon(PackedVector2Array([Vector2(x - s, 0), Vector2(x, -s * 0.7), Vector2(x + s, 0),
					Vector2(x, s * 0.7)]), hi)
				x += 1.0
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
