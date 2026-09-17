class_name FlameSprite
extends Node2D
## A burning patch of flames: a few flickering tongues, each a layered teardrop (dark red rim, orange,
## yellow, white core) that sways and stretches. Lives in the y-sorted world at its ground point.

const LAYERS := [Color(0.55, 0.08, 0.04, 0.9), Color("e8501a"), Color("ffa030"), Color("fff0b0")]

## 0..1 overall size; tween to 0 to burn out.
var strength := 0.0
var size := 1.0
var _tongues: Array = []
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
	for tg in _tongues:
		var ph: float = tg.phase
		var h: float = tg.h * strength * (0.8 + 0.2 * sin(_time * 11.0 + ph) + 0.12 * sin(_time * 23.0 + ph * 3.0))
		var w: float = tg.w * (0.7 + 0.3 * strength)
		var base := Vector2(tg.x, tg.y)
		var sway := sin(_time * 5.0 + ph) * h * 0.18
		for li in LAYERS.size():
			var k := 1.0 - li * 0.22
			_tongue(base + Vector2(0, -li * 1.0), w * k, h * (1.0 - li * 0.16), sway * k, LAYERS[li])


func _tongue(base: Vector2, w: float, h: float, sway: float, col: Color) -> void:
	if w < 1.0 or h < 2.0:
		return
	var pts := PackedVector2Array([
		base + Vector2(-w * 0.5, 0),
		base + Vector2(-w * 0.55 + sway * 0.2, -h * 0.3),
		base + Vector2(-w * 0.25 + sway * 0.6, -h * 0.65),
		base + Vector2(sway, -h),
		base + Vector2(w * 0.3 + sway * 0.5, -h * 0.6),
		base + Vector2(w * 0.55 + sway * 0.15, -h * 0.28),
		base + Vector2(w * 0.5, 0),
		base + Vector2(0, w * 0.2),
	])
	for i in pts.size():
		pts[i] = pts[i].round()
	if Geometry2D.triangulate_polygon(pts).is_empty():
		return
	draw_colored_polygon(pts, col)
