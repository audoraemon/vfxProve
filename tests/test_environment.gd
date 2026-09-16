extends RefCounted


static func run(t) -> void:
	# LightField: falloff and direction.
	var lights := LightField.new()
	lights.pulse(Vector2(0, 0), 4.0, Color(1, 0.5, 0), 1.0, 10.0)
	var near := lights.sample(Vector2(0.5, 0))
	var far := lights.sample(Vector2(3.5, 0))
	t.check(near.r > far.r and far.r > 0.0, "light falls off with distance (%s vs %s)" % [near, far])
	t.check(lights.sample(Vector2(6, 0)).r == 0.0, "no light beyond radius")
	var dir := lights.sample_dir(Vector2(2, 0))
	t.check(dir.x < 0.0, "light direction points back toward the source")
	lights.free()

	# EnvironmentField: queries and damage.
	var env := EnvironmentField.new()
	var a := env.add_structure(Rect2(2, 2, 2, 1), 60.0, Structure.Kind.BLOCK)
	var b := env.add_structure(Rect2(-6, -6, 1, 1), 80.0, Structure.Kind.TOWER)
	t.check(env.blocked(Vector2(3, 2.5)), "point inside footprint is blocked")
	t.check(not env.blocked(Vector2(0, 0)), "open ground not blocked")
	env.damage_radius(Vector2(0, 0), 3.0, 1000.0, &"nova")
	t.check(a.destroyed, "structure touching blast radius destroyed")
	t.check(not b.destroyed, "structure outside radius untouched")
	t.check(not env.blocked(Vector2(3, 2.5)), "rubble no longer blocks")

	var c := env.add_structure(Rect2(4, -0.5, 1, 1), 40.0, Structure.Kind.BLOCK)
	env.damage_lane(Vector2(0, 0), Vector2(1, 0), 1.0, 4.2, 4.8, &"laser")
	t.check(c.destroyed, "lane band through footprint destroys it")

	var d := env.add_structure(Rect2(-1, 5, 1, 1), 40.0, Structure.Kind.BLOCK)
	env.damage_radius(Vector2(-0.5, 5.5), 1.0, 40.0, &"orbital")
	t.check(not d.destroyed and d.hp < d.max_hp, "partial damage lowers hp without destroying")
	env.damage_radius(Vector2(-0.5, 5.5), 1.0, 80.0, &"orbital")
	t.check(d.destroyed, "accumulated damage destroys")
	env.clear()
	env.free()
