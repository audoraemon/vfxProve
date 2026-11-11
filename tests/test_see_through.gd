extends RefCounted
## SeeThrough: the buildings in front of a tall effect go see-through while it stands, and come back after.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var front := env.add_structure(Rect2(Vector2(2.0, 2.0), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	var behind := env.add_structure(Rect2(Vector2(-2.0, -2.0), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	var far := env.add_structure(Rect2(Vector2(20.0, -20.0), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	var foot := Iso.ground_to_screen(Vector2(0.5, 0.5))
	var rect := Rect2(foot.x - 80.0, foot.y - 200.0, 160.0, 200.0)
	t.check(front.base_position().y > foot.y and behind.base_position().y < foot.y and front.view_box().intersects(rect)
		and not far.view_box().intersects(rect), "the setup: one house before the effect, one behind it, one far off")
	var see := SeeThrough.new()
	for k in 20:
		see.step(env.structures(), rect, foot.y, 0.05)
	t.check(is_equal_approx(front.modulate.a, SeeThrough.ALPHA) and is_equal_approx(behind.modulate.a, 1.0)
		and is_equal_approx(far.modulate.a, 1.0), "only the house in front of it, over its rect, goes see-through (%.2f)" % front.modulate.a)
	for k in 20:
		see.step(env.structures(), Rect2(), foot.y, 0.05)
	t.check(is_equal_approx(front.modulate.a, 1.0) and not see.fading(front), "with the effect gone it eases back to its own look (%.2f, fading %s)" % [front.modulate.a, see.fading(front)])
	for k in 3:
		see.step(env.structures(), rect, foot.y, 0.05)
	see.release()
	t.check(is_equal_approx(front.modulate.a, 1.0), "release() gives it back at once")
	env.free()
