extends RefCounted
## The fortified Citadel: nine parts on one hidden health pool, at most 25% lost per rolling second, the part
## nearest each blow collapses at every 10% mark, and the keep falls last.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var c := Citadel.new().setup(env, TownLayout.CITADEL_ORIGIN)
	t.check(c.parts.size() == 9 and c.keep == c.parts[8], "nine parts, keep last")
	var ok := true
	for p in c.parts:
		ok = ok and p.role == &"citadel" and p.damage_filter.is_valid() and TownLayout.CITADEL_AREA.encloses(p.footprint)
	t.check(ok, "parts are tagged, routed through the budget and inside the Citadel ground")
	var down: Array = []
	c.part_collapsed.connect(func(p: Structure) -> void: down.append(p))
	var fell := [false]
	c.fallen.connect(func() -> void: fell[0] = true)
	var reported: Array = []
	c.health_changed.connect(func(f: float) -> void: reported.append(f))

	# A colossal blast from the north-west takes only this second's budget (25%): two 10% marks, so the two
	# parts nearest the blast collapse, nearest first.
	var nw := TownLayout.CITADEL_ORIGIN + Vector2(-4.5, -1.3)
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	t.near(c.fraction(), 0.75, 0.001, "one blast takes only 25%")
	t.check(down == [c.parts[0], c.parts[6]], "the NW tower then the W wall collapse (%s)" % [_indices(c, down)])
	t.check(c.keep.hp == c.keep.max_hp and c.standing_parts() == 7, "parts keep their own hp; 7 still stand")

	# The budget is a rolling second.
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	c.advance(0.6)
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	t.near(c.fraction(), 0.75, 0.001, "no more loss inside the same second")
	c.advance(0.4)
	env.damage_radius(nw, 3.0, 99999.0, &"stone")
	t.near(c.fraction(), 0.5, 0.001, "the budget refills after one second")
	t.check(down.size() == 5 and down.slice(2) == [c.parts[2], c.parts[4], c.parts[5]],
		"then the SW tower, N wall and S wall (%s)" % [_indices(c, down)])

	# Small hits add up.
	c.advance(1.0)
	for i in 5:
		c.keep.damage(20.0, c.origin, &"orbital")
	t.near(c.fraction(), 0.4, 0.001, "five small hits take 10%")
	t.check(down.size() == 6, "the 40% mark drops a sixth part")

	# At 15% every outer part is down and only the keep stands.
	c.advance(1.0)
	env.damage_radius(c.origin, 4.0, 99999.0, &"nova")
	t.near(c.fraction(), 0.15, 0.001, "another 25%")
	t.check(c.standing_parts() == 1 and not c.keep.destroyed and not fell[0], "only the keep stands at 15%")

	# The keep falls last, at 0%.
	c.advance(1.0)
	env.damage_radius(c.origin, 4.0, 99999.0, &"nova")
	t.check(c.is_fallen() and fell[0] and c.keep.destroyed and c.fraction() == 0.0, "the keep falls at 0%")
	t.check(down.size() == 9 and down[8] == c.keep, "the keep collapses last")
	t.near(reported[-1], 0.0, 0.0001, "health_changed reports the fall")
	c.advance(1.0)
	env.damage_radius(c.origin, 4.0, 99999.0, &"nova")
	t.check(down.size() == 9 and c.standing_parts() == 0, "nothing more happens after the fall")
	env.clear()
	env.free()
	c.free()


static func _indices(c: Citadel, list: Array) -> Array:
	return list.map(func(p): return c.parts.find(p))
