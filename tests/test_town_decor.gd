extends RefCounted
## The town's floor trails and decor: placement rules, damage, the fountain and chimney smoke.


static func run(t) -> void:
	var trails_ok := not TownFloor.TRAILS.is_empty()
	for tr: Array in TownFloor.TRAILS:
		for p: Vector2 in tr:
			trails_ok = trails_ok and not TownLayout.TOWN.grow(0.8).has_point(p) \
				and not TownLayout.RIVER.grow(0.3).has_point(p)
	t.check(trails_ok, "dirt trails stay outside the walls and out of the river")

	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var spots := TownDecor.spots()
	t.check(spots.size() >= 120, "the town gets plenty of decor (%d)" % spots.size())
	var inside_ok := true
	var outside_ok := true
	var no_overlap := true
	for d in spots:
		var at: Vector2 = d.at
		for st in env.structures():
			if not st.walkable and st.footprint.grow(-0.05).has_point(at):
				no_overlap = false
		if TownLayout.TOWN.has_point(at):
			inside_ok = inside_ok and not grid.walkable(at)
		else:
			for road: Rect2 in TownLayout.ROADS:
				outside_ok = outside_ok and not road.grow(1.0).has_point(at)
			for ex: Vector2 in TownLayout.EXITS:
				outside_ok = outside_ok and at.distance_to(ex) >= 1.0
			if not Decor.ON_WATER.has(d.kind):
				for r: Rect2 in TownLayout.RIVERS:
					outside_ok = outside_ok and not r.has_point(at)
	t.check(inside_ok, "decor inside the walls only stands where people already cannot walk")
	t.check(outside_ok, "decor outside keeps off the roads, the exits and the river")
	t.check(no_overlap, "no decor stands inside a building")
	t.check(spots == TownDecor.spots(), "decor placement is the same every time")
	t.check(env.decor().size() == spots.size(), "without a floor to bake into, every piece is live decor")

	# Fewer live nodes, same look: low pieces inside the walls go into the floor where nothing taller covers them,
	# and goods standing together share one PILE node.
	var baked_low := 0
	var piles_ok := true
	var piles := 0
	for d in spots:
		if d.bake and TownDecor.LOW_BOX.has(d.kind) and TownLayout.TOWN.grow(1.0).has_point(d.at):
			baked_low += 1
			piles_ok = piles_ok and d.has("tint")
		if d.kind != Decor.Kind.PILE:
			continue
		piles += 1
		var parts: Array = d.parts
		piles_ok = piles_ok and parts.size() >= 2 and parts.size() <= TownDecor.PILE_MAX
		var front_y := -INF
		for k in parts.size():
			var part: Dictionary = parts[k]
			piles_ok = piles_ok and part.kind in TownDecor.PILE_KINDS
			var y := Iso.ground_to_screen(part.at).y
			piles_ok = piles_ok and y >= front_y  # back to front
			front_y = y
			var near := k == 0
			for m in k:
				near = near or (part.at as Vector2).distance_to(parts[m].at) <= TownDecor.PILE_REACH
			piles_ok = piles_ok and near
		piles_ok = piles_ok and d.at == parts[parts.size() - 1].at
	t.check(baked_low >= 50 and piles >= 30 and piles_ok,
		"low decor painted into the floor (%d), goods merged into piles (%d), each pile back to front and close" % [
		baked_low, piles])
	var d0 := Decor.new().setup(Decor.Kind.BARREL, Vector2(40.5, 40.5), Vector2.ZERO, 1)
	env.add_decor(d0)
	env.damage_radius(Vector2(40.5, 40.5), 1.0, 12.0, &"nova")
	t.check(d0.char_amount > 0.0 and not d0.down, "a light hit chars decor")
	env.damage_radius(Vector2(40.5, 40.5), 1.0, 99999.0, &"nova")
	t.check(d0.down, "a lethal hit knocks it down")
	var d1 := Decor.new().setup(Decor.Kind.BUSH, Vector2(44.0, 40.0), Vector2.ZERO, 2)
	env.add_decor(d1)
	env.damage_lane(Vector2(42.0, 40.0), Vector2(1, 0), 0.5, 0.0, 4.0, &"laser")
	t.check(d1.down, "a lane cuts decor down too")

	t.check(town.fountain != null and town.fountain.kind == Structure.Kind.FOUNTAIN, "the market has a fountain")
	var fc: Vector2 = TownLayout.FOUNTAIN.get_center()
	t.check(env.blocked(fc) and not grid.walkable(fc), "people walk round the fountain")
	var houses := 0
	for st in env.structures():
		# A sprite with its smoke drawn in (the PixelLab proof's tavern and smithy) smokes on its own.
		if st.kind == Structure.Kind.HOUSE and st.role == &"house" and not st.sprite.get("own_smoke", false):
			houses += 1
	var before := town.smoke.wisp_count()
	t.check(before == houses, "every cottage smokes (%d of %d)" % [before, houses])
	for st in env.structures():
		if st.kind == Structure.Kind.HOUSE and st.role == &"house":
			st.destroy(st.center(), &"nova")
			break
	t.check(town.smoke.wisp_count() == before - 1, "a fallen house stops smoking")
	town.teardown()
	t.check(env.decor().is_empty() and town.smoke == null, "teardown takes the decor and the smoke away")
	d0.free()
	d1.free()
	town.free()
	env.free()
