class_name FlameSprite
extends Node2D
## A burning patch of flames: a few flickering tongues, each a layered teardrop (dark red rim, orange,
## yellow, white core) that sways and stretches. Lives in the y-sorted world at its ground point.

const LAYERS := [Color(0.55, 0.08, 0.04, 0.9), Color("e8501a"), Color("ffa030"), Color("fff0b0")]
## Each layer's colour as the one-colour array a polygon command takes.
static var _LAYER_COLORS: Array[PackedColorArray] = [PackedColorArray([LAYERS[0]]), PackedColorArray([LAYERS[1]]),
	PackedColorArray([LAYERS[2]]), PackedColorArray([LAYERS[3]])]

## 0..1 overall size; tween to 0 to burn out.
var strength := 0.0
var size := 1.0
var _tongues: Array = []
## _draw()'s point array, reused for every tongue (the server keeps its own copy of what it is handed).
var _pts := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var _time := 0.0


func setup(rng: RandomNumberGenerator, count := 4) -> void:
	for i in count:
		_tongues.append({"x": rng.randf_range(-9.0, 9.0) * size, "y": rng.randf_range(-3.0, 3.0) * size,
			"h": rng.randf_range(12.0, 24.0) * size, "w": rng.randf_range(6.0, 10.0) * size, "phase": rng.randf() * TAU})
	# Back tongues first (smaller y), front ones over them.
	_tongues.sort_custom(func(a, b): return a.y < b.y)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if strength <= 0.01:
		return
	# Every tongue's layers in one loop, into one reused point array, each triangulated once and handed to the server as
	# the command draw_colored_polygon() would make: the same points, rounded the same, the same triangles and colours.
	var item := get_canvas_item()
	for tg in _tongues:
		var ph: float = tg.phase
		var h: float = tg.h * strength * (0.8 + 0.2 * sin(_time * 11.0 + ph) + 0.12 * sin(_time * 23.0 + ph * 3.0))
		var w: float = tg.w * (0.7 + 0.3 * strength)
		var base := Vector2(tg.x, tg.y)
		var sway := sin(_time * 5.0 + ph) * h * 0.18
		for li in LAYERS.size():
			var k := 1.0 - li * 0.22
			var lw := w * k
			var lh := h * (1.0 - li * 0.16)
			if lw < 1.0 or lh < 2.0:
				continue
			var ls := sway * k
			var b := base + Vector2(0, -li * 1.0)
			_pts[0] = (b + Vector2(-lw * 0.5, 0)).round()
			_pts[1] = (b + Vector2(-lw * 0.55 + ls * 0.2, -lh * 0.3)).round()
			_pts[2] = (b + Vector2(-lw * 0.25 + ls * 0.6, -lh * 0.65)).round()
			_pts[3] = (b + Vector2(ls, -lh)).round()
			_pts[4] = (b + Vector2(lw * 0.3 + ls * 0.5, -lh * 0.6)).round()
			_pts[5] = (b + Vector2(lw * 0.55 + ls * 0.15, -lh * 0.28)).round()
			_pts[6] = (b + Vector2(lw * 0.5, 0)).round()
			_pts[7] = (b + Vector2(0, lw * 0.2)).round()
			var tris := Geometry2D.triangulate_polygon(_pts)
			if not tris.is_empty():
				RenderingServer.canvas_item_add_triangle_array(item, tris, _pts, _LAYER_COLORS[li])
