extends Node2D
## Sci-fi floor. Lives under the iso-basis GroundPlane, so it draws in ground units.

const HALF := 7

const COL_BASE := [Color("1a1e29"), Color("1d2230"), Color("171b25")]
const COL_PANEL := Color("232937")
const COL_SEAM := Color("0e1017")
const COL_EDGE := Color("2e3648")
const COL_LIGHT := Color("2fd0ff")
const COL_WARN := Color("5a3a1a")


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 997


func _draw() -> void:
	for y in range(-HALF, HALF):
		for x in range(-HALF, HALF):
			var h := _hash(x, y)
			draw_rect(Rect2(x, y, 1, 1), COL_BASE[h % 3])
			if h % 4 == 0:
				draw_rect(Rect2(x + 0.18, y + 0.18, 0.64, 0.64), COL_PANEL)
			if h % 29 == 0:
				draw_rect(Rect2(x + 0.1, y + 0.45, 0.8, 0.1), COL_WARN)
	for i in range(-HALF, HALF + 1):
		draw_line(Vector2(i, -HALF), Vector2(i, HALF), COL_SEAM, -1.0)
		draw_line(Vector2(-HALF, i), Vector2(HALF, i), COL_SEAM, -1.0)
	for y in range(-HALF, HALF):
		for x in range(-HALF, HALF):
			if _hash(x, y) % 17 == 0:
				draw_rect(Rect2(x + 0.02, y + 0.02, 0.05, 0.05), COL_LIGHT)
	draw_rect(Rect2(-HALF, -HALF, HALF * 2, HALF * 2), COL_EDGE, false, -1.0)
