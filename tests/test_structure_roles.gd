extends RefCounted
## Structure roles, walkability, the damage filter, the destroy signal and the stage helpers the Citadel uses.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var down: Array = []
	env.structure_destroyed.connect(func(s: Structure, _kind: StringName) -> void: down.append(s))

	var house := env.add_structure(Rect2(0, 0, 1, 1), 24.0, Structure.Kind.HOUSE, &"house")
	var plain := env.add_structure(Rect2(3, 0, 1, 1), 24.0, Structure.Kind.HOUSE)
	t.check(house.role == &"house", "role tag stored")
	t.check(plain.role == &"", "role defaults to empty")
	env.damage_radius(Vector2(0.5, 0.5), 0.6, 99999.0, &"nova")
	t.check(down == [house], "structure_destroyed fires for the destroyed house (%s)" % [down])
	house.destroy(Vector2.ZERO, &"nova")
	t.check(down.size() == 1, "a second destroy does not signal again")

	# Walkable structures never block units.
	t.check(env.blocked(Vector2(3.5, 0.5)), "a standing house blocks")
	plain.walkable = true
	t.check(not env.blocked(Vector2(3.5, 0.5)), "a walkable structure does not block")

	# A damage filter owns the hp: it receives every hit and the building's own hp stays put.
	var wall := env.add_structure(Rect2(-4, 0, 2, 0.6), 34.0, Structure.Kind.CASTLE_WALL)
	var hits: Array = []
	wall.damage_filter = func(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
		hits.append([s, amount, source, kind])
	wall.damage(500.0, Vector2(-3, 1), &"stone")
	t.check(hits.size() == 1 and hits[0] == [wall, 500.0, Vector2(-3, 1), &"stone"], "filter receives the hit (%s)" % [hits])
	t.check(not wall.destroyed and wall.hp == wall.max_hp, "a filtered hit leaves hp to the filter")

	# Hit reactions and stage helpers work without touching hp.
	wall.mark_hit(0.5, &"nova")
	t.near(wall.scorch, 0.45, 0.001, "mark_hit scorches by share")
	wall.mark_hit(0.2, &"ice")
	t.near(wall.frost, 0.6, 0.001, "mark_hit frosts on ice")
	t.check(wall._cracks.is_empty(), "no cracks before crack()")
	wall.crack()
	var n := wall._cracks.size()
	wall.crack()
	t.check(n > 0 and wall._cracks.size() == n, "crack() adds cracks once")
	wall.ignite(Vector2(0, -10), 1.0)
	wall.dust_burst(1.0)
	wall.drop_banner()
	t.check(wall.hp == wall.max_hp and not wall.destroyed, "stage helpers are safe headless and leave hp alone")

	# The keep's banner can be dropped: it falls, fades and is removed.
	var keep := env.add_structure(Rect2(10, 10, 2, 2), 96.0, Structure.Kind.KEEP)
	# Nothing is in a scene tree here, and the test runner never reaches a frame, so build the banner directly.
	keep._ready()
	t.check(is_instance_valid(keep._banner), "the keep builds its banner")
	keep.drop_banner()
	keep._process(0.5)
	var alpha := keep._banner.modulate.a
	keep._process(0.6)
	t.check(alpha < 1.0 and keep._banner.is_queued_for_deletion(), "a dropped banner fades and is removed")
	keep.free()

	# Plain damage works as before: cracks under 65% and destroys at 0.
	var hut := env.add_structure(Rect2(20, 0, 1, 1), 22.0, Structure.Kind.HOUSE)
	hut.damage(hut.max_hp * 0.5, Vector2(19, 0), &"orbital")
	t.check(not hut.destroyed and not hut._cracks.is_empty(), "half damage cracks without destroying")
	hut.damage(hut.max_hp, Vector2(19, 0), &"orbital")
	t.check(hut.destroyed and down.has(hut), "full damage destroys and signals")
	env.clear()
	env.free()

	# The spatial index answers blocked() exactly like a full scan.
	var castle := EnvironmentField.new()
	castle.build_castle()
	var mismatches := 0
	for i in 400:
		var p := Vector2(fposmod(i * 0.731, 14.0) - 7.0, fposmod(i * 0.377, 14.0) - 7.0)
		for margin in [0.15, 0.3]:
			var scan := false
			for s in castle.structures():
				scan = scan or (not s.destroyed and not s.walkable and s.contains(p, margin))
			if scan != castle.blocked(p, margin):
				mismatches += 1
	t.check(mismatches == 0, "indexed blocked() matches a full scan (%d mismatches)" % mismatches)
	castle.clear()
	castle.free()
