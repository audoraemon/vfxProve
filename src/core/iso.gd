class_name Iso
extends RefCounted
## Isometric projection between Cartesian ground units and screen pixels.
## One ground unit = one 64x32 cell.

const CELL_W := 64
const CELL_H := 32
const BASIS := Transform2D(Vector2(32, 16), Vector2(-32, 16), Vector2.ZERO)


static func ground_to_screen(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * 32.0, (g.x + g.y) * 16.0)


static func screen_to_ground(s: Vector2) -> Vector2:
	var a := s.x / 32.0
	var b := s.y / 16.0
	return Vector2((a + b) * 0.5, (b - a) * 0.5)


## Screen-space semi-axes of the ellipse a ground circle of radius r projects to.
static func radius_to_screen(r: float) -> Vector2:
	return Vector2(32.0, 16.0) * sqrt(2.0) * r
