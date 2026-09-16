extends RefCounted


static func run(t) -> void:
	var s := Iso.ground_to_screen(Vector2(1, 0))
	t.check(s == Vector2(32, 16), "unit x projects to (32,16)")
	t.check(Iso.ground_to_screen(Vector2(0, 1)) == Vector2(-32, 16), "unit y projects to (-32,16)")
	for g in [Vector2(3.5, -2.25), Vector2(-7, 4), Vector2.ZERO]:
		var back := Iso.screen_to_ground(Iso.ground_to_screen(g))
		t.check(back.is_equal_approx(g), "round trip %s" % g)
	var axes := Iso.radius_to_screen(1.0)
	t.near(axes.x, 32.0 * sqrt(2.0), 0.001, "ellipse semi-axis x")
	t.near(axes.y, 16.0 * sqrt(2.0), 0.001, "ellipse semi-axis y")
	t.check(Iso.BASIS * Vector2(2, 3) == Iso.ground_to_screen(Vector2(2, 3)), "BASIS matches projection")
