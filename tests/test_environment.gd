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

	# In view with nothing going on, a building goes idle: it stops processing, and the field checks its light for it.
	var field := EnvironmentField.new()
	field.lights = LightField.new()
	var house := field.add_structure(Rect2(0, 0, 1, 1), 20.0, Structure.Kind.HOUSE)
	var torch := field.add_structure(Rect2(3, 3, 0.2, 0.2), 16.0, Structure.Kind.TORCH)
	house._ready()
	torch._ready()
	# The first frame draws it (a new building is dirty); the next finds nothing to do.
	for i in 2:
		house._process(1.0 / 60.0)
		torch._process(1.0 / 60.0)
	t.check(house.idle and house.asleep and field._idle.has(house), "a quiet building in view goes idle")
	t.check(not torch.idle, "a torch, whose flame steps with time, never does")
	var drawn := house._drawn_sig
	field.lights.add_static(house.center(), 2.0, Color(1.0, 0.6, 0.3), 1.0)
	field.tick_idle(1.0 / Structure.LIGHT_HZ, Rect2())
	t.check(house._drawn_sig != drawn, "a light placed on it is seen within 1/LIGHT_HZ")
	house.mark_hit(0.1, &"blast")
	t.check(not house.idle and not house.asleep, "a hit wakes it")
	# A fallen building settles: once its collapse is over it stops redrawing every frame and goes idle. (It used
	# to count as collapsing for ever, and every heap of rubble in view repainted itself each frame.)
	var hut := field.add_structure(Rect2(6, 0, 1, 1), 20.0, Structure.Kind.HOUSE)
	hut._ready()
	hut.destroy(Vector2(5, 0), &"blast")
	for i in 150:
		hut._process(1.0 / 60.0)
	t.check(hut.destroyed and hut.idle, "a fallen building settles and goes idle once its collapse is over")
	field.tick_idle(1.0, Rect2())
	t.check(not field._idle.has(house), "and the field lets it go")
	field.clear()
	field.lights.free()
	field.free()
	_batch_remove(t)


## The town of `made` as signatures: its structure list, its spatial index (both grids, non-empty cells only) and its walk grid's
## solid cells, each structure named by its place in the town's build order.
static func _sig(env: EnvironmentField, grid: WalkGrid, order: Dictionary) -> Dictionary:
	var name := func(s: Structure) -> String: return str(order.get(s, -1))
	var list := PackedStringArray()
	for s in env.structures():
		list.append(name.call(s))
	var out := {"list": ",".join(list)}
	for which in ["_grid", "_fine"]:
		var cells: Dictionary = env.get(which)
		var keys := []
		for k in cells:
			if not (cells[k] as Array).is_empty():
				keys.append(k)
		keys.sort()
		var rows := PackedStringArray()
		for k in keys:
			var names := PackedStringArray()
			for s in cells[k]:
				names.append(name.call(s))
			rows.append("%s:%s" % [k, ",".join(names)])
		out[which] = "|".join(rows)
	var solid := PackedStringArray()
	var reg := grid.grid.region
	for y in range(reg.position.y, reg.end.y):
		for x in range(reg.position.x, reg.end.x):
			if grid.grid.is_point_solid(Vector2i(x, y)):
				solid.append("%d,%d" % [x, y])
	out["walk"] = "|".join(solid)
	return out


## Task 10b (C19): removing N structures with `reindex = false` and one reindex() after leaves the same structure list, spatial index,
## walk grid and structure_removed order as N single removes -- two towns built alike, one each way. Before the reindex() too: the
## deferred index already holds none of them (nothing reads a stale one in between).
static func _batch_remove(t) -> void:
	var sides := []
	for way in ["single", "batch"]:
		var env := EnvironmentField.new()
		var town := Town.new()
		town.build(env)
		var grid := WalkGrid.new().setup(env, town)
		var order := {}
		for i in env.structures().size():
			order[env.structures()[i]] = i
		# A dense block: every plain building whose footprint lies within 10 of the market square, neighbours sharing cells.
		var at := Places.at(&"market_square")
		var keep: Array = []
		keep.append_array(town.gates)
		keep.append_array(town.bridges)
		keep.append_array([town.bridge, town.postern, town.dock, town.fountain])
		var take: Array[Structure] = []
		for s in env.structures():
			if not s.walkable and not keep.has(s) and TheSwallowingDarkFx.wholly_inside(s, at, 10.0):
				take.append(s)
		var seen := PackedStringArray()
		var on_removed := func(s: Structure) -> void: seen.append(str(order[s]))
		env.structure_removed.connect(on_removed)
		var epoch := env.layout_epoch
		for s in take:
			env.remove(s, true, true, way == "single")
		var before := _sig(env, grid, order)
		if way == "batch":
			env.reindex()
		sides.append({"n": take.size(), "seen": ",".join(seen), "before": before, "after": _sig(env, grid, order),
			"epoch": env.layout_epoch > epoch})
		env.structure_removed.disconnect(on_removed)
		env.clear()
		env.clear_decor()
		town.free()
		env.free()
	var one: Dictionary = sides[0]
	var all: Dictionary = sides[1]
	t.check(one.n >= 10 and one.n == all.n, "a dense block to take (%d structures)" % one.n)
	t.check(one.seen == all.seen, "batch: structure_removed in the same order as single removes")
	for k in ["list", "_grid", "_fine", "walk"]:
		t.check(one.after[k] == all.after[k], "batch then reindex(): the same %s as N single removes" % k)
		t.check(one.after[k] == all.before[k], "batch before reindex(): the deferred %s is already the same (never stale)" % k)
	t.check(one.epoch and all.epoch, "both ways bump layout_epoch (caches built from the layout go stale)")
