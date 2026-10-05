extends RefCounted
## DecorSprites: which decor piece draws from which sprite set (decor batch 4).

const D := Decor.Kind


static func run(t) -> void:
	_mapping(t)
	_trees(t)
	_missing(t)
	_paint(t)
	_runs(t)
	_down(t)
	_toggle(t)
	_glow(t)
	_boats(t)
	_mirror(t)
	_herds(t)
	_floor(t)
	_real_trees(t)
	DecorSprites.reload()
	SpriteArt.set_enabled(true)


## Fake decor entries (name -> {}) in the cached manifest; returns the names added, for _unfake().
static func _fake(names: Array) -> Array:
	var m := DecorSprites.manifest()
	var added := []
	for n: String in names:
		if not m.has(n):
			m[n] = {}
			added.append(n)
	DecorSprites._variants_cache.clear()
	return added


static func _unfake(added: Array) -> void:
	var m := DecorSprites.manifest()
	for n: String in added:
		m.erase(n)
	DecorSprites._variants_cache.clear()


static func _mapping(t) -> void:
	var fakes := _fake(["barrel_1", "barrel_2", "crates_1", "ship", "fence_x", "fence_y", "sheep_1", "lamp_house"])
	t.check(DecorSprites.name_for(D.BARREL, 7, Vector2.ZERO).begins_with("barrel_"), "a barrel maps to a barrel set")
	var seen := {}
	for s in 64:
		seen[DecorSprites.name_for(D.BARREL, s * 977, Vector2.ZERO)] = true
	t.check(seen.size() == 2, "both barrel variants appear over seeds (got %s)" % [seen.keys()])
	t.check(DecorSprites.name_for(D.SHIP, 1, Vector2.ZERO) == "ship", "a single set maps by its bare name")
	t.check(DecorSprites.name_for(D.LAMP, 1, Vector2.ZERO) == "lamp_house", "a house-front lamp maps to lamp_house")
	t.check(DecorSprites.name_for(D.FENCE, 1, Vector2(2.0, 0.0)) == "fence_x", "an x-run fence takes fence_x")
	t.check(DecorSprites.name_for(D.FENCE, 1, Vector2(0.0, -1.5)) == "fence_y", "a -y run fence takes fence_y")
	t.check(DecorSprites.name_for(D.DOCK, 1, Vector2.ZERO) == "", "a kind with no set stays procedural")
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.name_for(D.BARREL, 7, Vector2.ZERO) == "", "F7 off: every decor piece is procedural")
	SpriteArt.set_enabled(true)
	_unfake(fakes)
	_gardens(t)
	for n: String in ["barrel_1", "barrel_2", "crates_1", "crates_2", "bench_x", "bench_y", "table_1", "table_2",
			"logs_1", "cart_1", "cart_2", "signpost", "lamp_house", "bunting_x", "bunting_y", "fence_x", "fence_y",
			"garden_1", "garden_2", "garden_3", "garden_4", "scarecrow"]:
		t.check(not DecorSprites.decor_set(n).is_empty(), "decor set %s loads" % n)


## A garden is a still per plot size (TownLayout's gardens come in four): GARDEN is not a run; it takes the
## garden_<n> whose manifest "footprint" is nearest its plot.
static func _gardens(t) -> void:
	t.check(not (D.GARDEN in DecorSprites.RUNS), "a garden is not a run")
	# Two fake plots stand in for the shipped garden sets (kept aside and put back after).
	var m := DecorSprites.manifest()
	var kept := {}
	for n: String in m.keys():
		if n.begins_with("garden_"):
			kept[n] = m[n]
			m.erase(n)
	m["garden_1"] = {"footprint": [1.0, 0.45]}
	m["garden_2"] = {"footprint": [0.45, 1.0]}
	DecorSprites._variants_cache.clear()
	t.check(DecorSprites.name_for(D.GARDEN, 3, Vector2(1.0, 0.45)) == "garden_1", "a 1 x 0.45 garden takes garden_1")
	t.check(DecorSprites.name_for(D.GARDEN, 3, Vector2(0.95, 0.45)) == "garden_1",
		"a 0.95 x 0.45 garden takes the nearest plot, garden_1")
	var seen := {}
	for s in 16:
		seen[DecorSprites.name_for(D.GARDEN, s * 977, Vector2(0.45, 0.95))] = true
	t.check(seen.keys() == ["garden_2"], "a 0.45 x 0.95 garden takes garden_2 for every seed (got %s)" % [seen.keys()])
	m.erase("garden_1")
	m.erase("garden_2")
	m.merge(kept)
	DecorSprites._variants_cache.clear()
	# The shipped sets match the town's four plot sizes exactly.
	var sizes := {}
	for g: Rect2 in TownLayout.gardens():
		sizes[g.size] = true
	t.check(sizes.size() == 4, "the town's gardens come in four sizes (got %s)" % [sizes.keys()])
	for size: Vector2 in sizes:
		var n := DecorSprites.name_for(D.GARDEN, 1, size)
		var f: Variant = DecorSprites.manifest().get(n, {}).get("footprint", null)
		t.check(f != null and Vector2(f[0], f[1]).is_equal_approx(size),
			"the town's %s garden has a set of its size (got '%s')" % [size, n])


static func _forest(stump: Texture2D = null) -> Array:
	var hidden := _hide_trees()
	var fakes := _fake(["forest_oak_1", "forest_oak_2", "forest_pine_1"])
	for n: String in ["forest_oak_1", "forest_oak_2", "forest_pine_1"]:
		DecorSprites._sets[n] = {"name": n, "tex": _tex(40, 60), "stump": stump, "size": Vector2(40, 60),
			"anchor": Vector2(20, 58), "segment": 0.0}
	return [fakes, hidden]


static func _unforest(fakes: Array) -> void:
	for n: String in ["forest_oak_1", "forest_oak_2", "forest_pine_1"]:
		DecorSprites._sets.erase(n)
	_unfake(fakes[0])
	_show_trees(fakes[1])


## Take the real decor tree sets (forest_* and town_oak / town_pine) out of the cached manifest, so a test sees only
## its fakes; returns them for _show_trees().
static func _hide_trees() -> Dictionary:
	var m := DecorSprites.manifest()
	var out := {}
	for n: String in m.keys():
		if n.begins_with("forest_") or n.begins_with("town_oak_") or n.begins_with("town_pine_"):
			out[n] = m[n]
			m.erase(n)
			DecorSprites._sets.erase(n)
	DecorSprites._variants_cache.clear()
	return out


static func _show_trees(hidden: Dictionary) -> void:
	var m := DecorSprites.manifest()
	for n: String in hidden:
		m[n] = hidden[n]
		DecorSprites._sets.erase(n)
	DecorSprites._variants_cache.clear()


static func _trees(t) -> void:
	# OAK and PINE use forest-scale decor sets: forest_oak_<n> and forest_pine_<n>; none yet means procedural.
	var fakes := _forest()
	var seen := {}
	for s in 16:
		var oak: String = DecorSprites.tree_set(D.OAK, s * 31).get("name", "")
		t.check(oak.begins_with("forest_oak_"), "a decor oak takes a forest oak set (got '%s')" % oak)
		seen[oak] = true
		var pine: String = DecorSprites.tree_set(D.PINE, s * 31).get("name", "")
		t.check(pine == "forest_pine_1", "a decor pine takes a forest pine set (got '%s')" % pine)
	t.check(seen.size() == 2, "both oak variants appear over seeds")
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.tree_set(D.OAK, 3).is_empty(), "F7 off: decor trees are procedural")
	SpriteArt.set_enabled(true)
	# A town decor tree (its height in size.x, 24..32: TownDecor._houses) is half a forest tree's size: it takes a
	# town_oak / town_pine set, and stays procedural without one (never a forest set at twice its size).
	t.check(DecorSprites.tree_set(D.OAK, 3, 28.0).is_empty(), "no town sets: a town decor oak is procedural")
	ArtKit.begin()
	t.check(not DecorSprites.paint(D.OAK, Vector2(1, 1), Vector2(28, 0), 3, Vector2.ZERO),
		"and paint leaves it to DecorArt")
	var tf := _fake(["town_oak_1", "town_pine_1"])
	for n: String in ["town_oak_1", "town_pine_1"]:
		DecorSprites._sets[n] = {"name": n, "tex": _tex(24, 32), "stump": null, "size": Vector2(24, 32),
			"anchor": Vector2(12, 29), "segment": 0.0}
	t.check(DecorSprites.tree_set(D.OAK, 3, 28.0).get("name", "") == "town_oak_1", "a town decor oak takes a town oak set")
	t.check(DecorSprites.tree_set(D.PINE, 3, 28.0).get("name", "") == "town_pine_1", "a town decor pine takes a town pine set")
	t.check(DecorSprites.tree_set(D.OAK, 3).get("name", "").begins_with("forest_oak_"), "a forest oak still takes a forest set")
	ArtKit.begin()
	t.check(DecorSprites.paint(D.PINE, Vector2(1, 1), Vector2(30, 0), 3, Iso.ground_to_screen(Vector2(1, 1)))
		and ArtKit.last_quad()[0] == Rect2(0, 0, 24, 32), "paint draws a town tree from its town set")
	# A baked forest tree (origin zero) at a fractional ground point lands on whole pixels.
	var at := Vector2(2.31, 3.17)
	ArtKit.begin()
	DecorSprites.paint(D.OAK, at, Vector2.ZERO, 3, Vector2.ZERO)
	var q := ArtKit.last_quad()
	t.check(q.size() == 2 and q[1] == q[1].round() and q[1].distance_to(Iso.ground_to_screen(at) - Vector2(20, 58)) <= 0.71,
		"a baked forest tree sits on the whole pixel nearest its point (got %s)" % [q])
	ArtKit.begin()
	for n: String in ["town_oak_1", "town_pine_1"]:
		DecorSprites._sets.erase(n)
	_unfake(tf)
	var hidden: Dictionary = fakes[1]
	_unfake(fakes[0])
	for n: String in ["forest_oak_1", "forest_oak_2", "forest_pine_1"]:
		DecorSprites._sets.erase(n)
	t.check(DecorSprites.tree_set(D.OAK, 3).is_empty(), "no forest sets: the decor oak is procedural")
	ArtKit.begin()
	t.check(not DecorSprites.paint(D.OAK, Vector2(1, 1), Vector2.ZERO, 3, Vector2.ZERO), "and paint leaves it to DecorArt")
	ArtKit.begin()
	_show_trees(hidden)


static func _missing(t) -> void:
	# An entry whose PNG is missing falls back to procedural instead of failing.
	var fakes := _fake(["rock_9"])
	DecorSprites.manifest()["rock_9"] = {"size": [8, 8]}  # declared, no PNG: takes the warn branch (once)
	t.check(DecorSprites.decor_set("rock_9").is_empty(), "a set without its PNG reads as missing")
	_unfake(fakes)
	DecorSprites._sets.erase("rock_9")


static func _paint(t) -> void:
	var fakes := _fake(["barrel_1"])
	DecorSprites._sets["barrel_1"] = {"name": "barrel_1", "tex": _tex(10, 12), "size": Vector2(10, 12),
		"anchor": Vector2(5, 11), "segment": 0.0}
	ArtKit.begin()
	t.check(DecorSprites.paint(Decor.Kind.BARREL, Vector2(2, 3), Vector2.ZERO, 5, Vector2.ZERO),
		"a barrel with a set paints from it")
	var s := ArtKit.segments()
	t.check(s.size() == 1 and s[0][0] == "tex" and s[0][2] == 1, "one textured quad, no polygons")
	# A baked piece (origin zero) at a fractional ground point lands on whole pixels; a live one stays at -anchor.
	var at := Vector2(2.31, 3.17)
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.BARREL, at, Vector2.ZERO, 5, Vector2.ZERO)
	var q := ArtKit.last_quad()
	t.check(q.size() == 2 and q[1] == q[1].round() and q[1].distance_to(Iso.ground_to_screen(at) - Vector2(5, 11)) <= 0.71,
		"a baked still sits on the whole pixel nearest its point (got %s)" % [q])
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.BARREL, at, Vector2.ZERO, 5, Iso.ground_to_screen(at))
	q = ArtKit.last_quad()
	t.check(q.size() == 2 and q[1] == Vector2(-5, -11), "a live still sits at -anchor from its own point (got %s)" % [q])
	ArtKit.begin()
	t.check(not DecorSprites.paint(Decor.Kind.DOCK, Vector2(2, 3), Vector2.ZERO, 5, Vector2.ZERO),
		"a kind without a set is left to the procedural art")
	t.check(ArtKit.segments().is_empty(), "and queues nothing")
	ArtKit.begin()
	DecorSprites._sets.erase("barrel_1")
	_unfake(fakes)


static func _runs(t) -> void:
	var fakes := _fake(["fence_x"])
	DecorSprites._sets["fence_x"] = {"name": "fence_x", "tex": _tex(32, 20), "size": Vector2(32, 20),
		"anchor": Vector2(0, 18), "segment": 1.0}
	for c in [[Vector2(3.0, 0.0), 3], [Vector2(2.5, 0.0), 3], [Vector2(0.4, 0.0), 1], [Vector2(-2.0, 0.0), 2]]:
		ArtKit.begin()
		DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), c[0], 1, Vector2.ZERO)
		var s := ArtKit.segments()
		var quads: int = s[0][2] if s.size() == 1 else -1
		t.check(quads == c[1], "a fence run of %s draws %d tiles (got %d)" % [c[0], c[1], quads])
	# The last tile is cut on its near side, its kept columns where they sit in a whole tile: an x set keeps its
	# left columns; a y set (anchored at its right, running down-left) its right ones.
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), Vector2(1.5, 0.0), 1, Vector2.ZERO)
	var q := ArtKit.last_quad()
	t.check(q.size() == 2 and q[0] == Rect2(0, 0, 16, 20) and q[1] == Iso.ground_to_screen(Vector2(6, 5)) - Vector2(0, 18),
		"an x run's last tile keeps its left half (got %s)" % [q])
	fakes.append_array(_fake(["fence_y"]))
	DecorSprites._sets["fence_y"] = {"name": "fence_y", "tex": _tex(32, 20), "size": Vector2(32, 20),
		"anchor": Vector2(32, 18), "segment": 1.0}
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), Vector2(0.0, 1.5), 1, Vector2.ZERO)
	q = ArtKit.last_quad()
	t.check(q.size() == 2 and q[0].position.x == 16.0 and q[0].size.x == 16.0,
		"a y run's last tile keeps its right half (got %s)" % [q])
	t.check(q.size() == 2 and q[1] == Iso.ground_to_screen(Vector2(5, 6)) - Vector2(32, 18) + Vector2(16, 0),
		"and draws it where it sits in a whole tile (got %s)" % [q])
	# A run closes with its set's "end_post" (a sub-rect of the sprite) at its far end: tiles + 1 quads.
	DecorSprites._sets["fence_x"]["end_post"] = Rect2(0, 2, 3, 16)
	for c in [[Vector2(1.5, 0.0), 2], [Vector2(-2.0, 0.0), 2], [Vector2(0.4, 0.0), 1]]:
		ArtKit.begin()
		DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), c[0], 1, Vector2.ZERO)
		var s := ArtKit.segments()
		var quads: int = s[0][2] if s.size() == 1 else -1
		t.check(quads == c[1] + 1, "a fence run of %s with an end post draws %d quads (got %d)" % [c[0], c[1] + 1, quads])
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), Vector2(1.5, 0.0), 1, Vector2.ZERO)
	q = ArtKit.last_quad()
	t.check(q.size() == 2 and q[0].is_equal_approx(Rect2(0, 2, 3, 16))
		and q[1].is_equal_approx(Iso.ground_to_screen(Vector2(6.5, 5)) - Vector2(0, 18) + Vector2(0, 2)),
		"the end post is drawn last, at the run's far end (got %s)" % [q])
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), Vector2(-1.5, 0.0), 1, Vector2.ZERO)
	q = ArtKit.last_quad()
	t.check(q.size() == 2 and q[1].is_equal_approx(Iso.ground_to_screen(Vector2(5, 5)) - Vector2(0, 18) + Vector2(0, 2)),
		"a reversed run's end post stands at its near end, `at` (got %s)" % [q])
	DecorSprites._sets["fence_x"].erase("end_post")
	# A slanted run starts from its back end along its main axis: (0.4, -0.1) runs along x from `at`, though y falls.
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), Vector2(0.4, -0.1), 1, Vector2.ZERO)
	q = ArtKit.last_quad()
	t.check(q.size() == 2 and q[1] == Iso.ground_to_screen(Vector2(5, 5)) - Vector2(0, 18),
		"a slanted x run tiles from its x start (got %s)" % [q])
	ArtKit.begin()
	DecorSprites.paint(Decor.Kind.FENCE, Vector2(5, 5), Vector2(-0.1, 0.4), 1, Vector2.ZERO)
	q = ArtKit.last_quad()
	t.check(q.size() == 2 and q[1].is_equal_approx(Iso.ground_to_screen(Vector2(5, 5)) - Vector2(32, 18) + Vector2(q[0].position.x, 0)),
		"a slanted y run tiles from its y start (got %s)" % [q])
	ArtKit.begin()
	DecorSprites._sets.erase("fence_y")
	DecorSprites._sets.erase("fence_x")
	_unfake(fakes)


static func _down(t) -> void:
	# A felled decor oak draws its set's stump texture; without one it is left to the procedural stump.
	var stump := _tex(12, 8)
	var fakes := _forest(stump)
	ArtKit.begin()
	var drew := DecorSprites.paint(D.OAK, Vector2(1, 1), Vector2.ZERO, 9, Vector2.ZERO, true)
	var s := ArtKit.segments()
	t.check(drew and s.size() == 1 and s[0][0] == "tex", "a down oak draws its set's stump")
	t.check(s.size() == 1 and s[0][1] == stump, "the stump is the set's stump texture")
	ArtKit.begin()
	_unforest(fakes)
	fakes = _forest()
	t.check(not DecorSprites.paint(D.OAK, Vector2(1, 1), Vector2.ZERO, 9, Vector2.ZERO, true),
		"a down oak without a stump texture is left to the procedural stump")
	t.check(ArtKit.segments().is_empty(), "and queues nothing")
	_unforest(fakes)
	ArtKit.begin()
	var bfakes := _fake(["barrel_1"])
	DecorSprites._sets["barrel_1"] = {"name": "barrel_1", "tex": _tex(10, 12), "size": Vector2(10, 12),
		"anchor": Vector2(5, 11), "segment": 0.0}
	t.check(DecorSprites.paint(Decor.Kind.BARREL, Vector2(1, 1), Vector2.ZERO, 9, Vector2.ZERO, true)
		and ArtKit.segments().is_empty(), "a knocked-over barrel draws nothing")
	DecorSprites._sets.erase("barrel_1")
	_unfake(bfakes)
	ArtKit.begin()


static func _toggle(t) -> void:
	# F7 reaches every decor drawer: live decor and the forest bands redraw, the floor re-bakes.
	# The test runner's root is never inside a scene tree (see test_sprite_art _idle_clock_frozen), so _ready() is
	# called by hand and nothing here uses get_tree().
	var d := Decor.new().setup(Decor.Kind.BARREL, Vector2(1, 1), Vector2.ZERO, 3)
	d._ready()
	t.check(d.is_in_group(&"decor_art"), "a live decor piece listens for art changes")
	t.check(d.has_method("art_changed"), "and has art_changed()")
	d.free()
	var band := ForestLayer.Band.new()
	band._ready()
	t.check(band.is_in_group(&"decor_art") and band.has_method("art_changed"), "a forest band listens for art changes")
	band.free()
	var floor_node := TownFloor.new()
	floor_node._ready()
	t.check(floor_node.is_in_group(&"decor_art"), "the floor listens for art changes")
	t.check(floor_node.has_method("rebake") and floor_node.has_method("art_changed"), "the floor can re-bake")
	floor_node.rebake()
	t.check(floor_node.get_node_or_null("FloorBake") == null, "headless, a re-bake does nothing (no bake to redo)")
	floor_node.free()
	# Off the tree, F7 still flips the art without touching any group.
	var toggle := ArtToggle.new()
	var was := SpriteArt.on()
	toggle.toggle()
	t.check(SpriteArt.on() != was, "ArtToggle.toggle() flips the art off the tree")
	toggle.toggle()
	toggle.free()


static func _tex(w: int, h: int) -> Texture2D:
	return ImageTexture.create_from_image(Image.create(w, h, false, Image.FORMAT_RGBA8))


## A lamp's light pool sits at its set's manifest "glow" (sprite px from the anchor), else at its ground point.
static func _glow(t) -> void:
	DecorSprites.reload()
	var m: Dictionary = DecorSprites.manifest().get("lamp_house", {})
	t.check(m.has("glow"), "lamp_house's manifest entry has a glow")
	var want := Vector2(m.glow[0], m.glow[1]) if m.has("glow") else Vector2(-999, -999)
	t.check(DecorSprites.decor_set("lamp_house").glow == want, "decor_set reads the glow from the manifest")
	t.check(DecorSprites.decor_set("barrel_1").glow == Vector2.ZERO, "a set without a glow reads zero")
	t.check(DecorSprites.glow_offset(D.LAMP, 3, Vector2.ZERO) == want, "a sprite lamp's glow offset is its set's")
	var lamp := Decor.new().setup(D.LAMP, Vector2(1, 1), Vector2.ZERO, 3)
	lamp._ready()
	t.check(lamp._glow.position == want * ArtTuning.scale("lamp"), "the lamp's light pool moves to it")
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.glow_offset(D.LAMP, 3, Vector2.ZERO) == Vector2.ZERO, "F7 off: the glow is at the ground point")
	lamp.art_changed()
	t.check(lamp._glow.position == Vector2.ZERO, "and F7 moves the lamp's pool back")
	SpriteArt.set_enabled(true)
	lamp.free()


static func _boats(t) -> void:
	# A boat lies along the river holding it: boat_1 (along x) on TownLayout.RIVER, boat_2 (along y) on RIVER_WEST.
	var fakes := _fake(["boat_1", "boat_2"])
	var on_river := TownLayout.RIVER.get_center()
	var on_west := TownLayout.RIVER_WEST.get_center()
	var ok_x := true
	var ok_y := true
	for s in 16:
		ok_x = ok_x and DecorSprites.name_for(D.BOAT, s * 131, Vector2.ZERO, on_river) == "boat_1"
		ok_y = ok_y and DecorSprites.name_for(D.BOAT, s * 131, Vector2.ZERO, on_west) == "boat_2"
	t.check(ok_x, "a boat on the river (along x) takes boat_1 for every seed")
	t.check(ok_y, "a boat on the west river (along y) takes boat_2 for every seed")
	var boats := 0
	for d: Dictionary in TownDecor.spots():
		if d.kind != D.BOAT:
			continue
		boats += 1
		var want := "boat_2" if TownLayout.RIVER_WEST.has_point(d.at) else "boat_1"
		t.check(TownLayout.RIVER.has_point(d.at) or TownLayout.RIVER_WEST.has_point(d.at),
			"the town's boat at %s is on a river" % [d.at])
		t.check(DecorSprites.name_for(D.BOAT, d.seed, d.size, d.at) == want,
			"the town's boat at %s takes %s" % [d.at, want])
	t.check(boats == 5, "the town has its five boats (got %d)" % boats)
	_unfake(fakes)


## Sheep and cows (DecorSprites.MIRRORED) face either way by seed: the quad's UVs swap left and right, the drawn rect
## stays, and the anchor's x mirrors so the ground point holds. Other kinds never flip.
static func _mirror(t) -> void:
	t.check(D.SHEEP in DecorSprites.MIRRORED and D.COW in DecorSprites.MIRRORED, "sheep and cows are mirrored kinds")
	var tx := _tex(12, 9)
	ArtKit.begin()
	ArtKit.tex(tx, Rect2(2, 1, 4, 3), Vector2(10, 20), Color.WHITE, true)
	var q := ArtKit.last_quad()
	t.check(ArtKit.last_flip(), "a flip_h quad reports its flip")
	t.check(q.size() == 2 and q[0].is_equal_approx(Rect2(2, 1, 4, 3)) and q[1] == Vector2(10, 20),
		"a flipped quad keeps its source rect and top-left (got %s)" % [q])
	var segs: Array = ArtKit._segs
	var uv: PackedVector2Array = segs[-1][5]
	t.check(uv[0].x > uv[1].x and is_equal_approx(uv[0].x * 12.0, 6.0) and is_equal_approx(uv[1].x * 12.0, 2.0),
		"flip_h swaps the left and right u (got %s)" % [uv])
	ArtKit.tex(tx, Rect2(2, 1, 4, 3), Vector2(10, 20))
	t.check(not ArtKit.last_flip(), "a plain quad does not flip")
	var fakes := _fake(["sheep_1", "barrel_1"])
	DecorSprites._sets["sheep_1"] = {"name": "sheep_1", "tex": _tex(12, 9), "size": Vector2(12, 9),
		"anchor": Vector2(4, 8), "segment": 0.0}
	DecorSprites._sets["barrel_1"] = {"name": "barrel_1", "tex": _tex(10, 12), "size": Vector2(10, 12),
		"anchor": Vector2(5, 11), "segment": 0.0}
	var flips := {}
	var placed := true
	var g := Iso.ground_to_screen(Vector2(1, 1))
	for s in 32:
		ArtKit.begin()
		DecorSprites.paint(Decor.Kind.SHEEP, Vector2(1, 1), Vector2.ZERO, s * 131, Vector2.ZERO)
		var f := ArtKit.last_flip()
		flips[f] = true
		q = ArtKit.last_quad()
		if DecorSprites.name_for(D.SHEEP, s * 131, Vector2.ZERO) == "sheep_1":
			var want := g - (Vector2(12 - 4, 8) if f else Vector2(4, 8))
			placed = placed and q.size() == 2 and q[1] == want
			placed = placed and f == (ArtKit.hash01(s * 131, DecorSprites.SALT_VARIANT + 1) < 0.5)
	t.check(flips.size() == 2, "sheep face both ways over seeds")
	t.check(placed, "a flipped sheep's anchor mirrors (x = size.x - anchor.x), flipped for half the seeds' hash")
	var barrel_flips := {}
	for s in 32:
		ArtKit.begin()
		DecorSprites.paint(Decor.Kind.BARREL, Vector2(1, 1), Vector2.ZERO, s * 131, Vector2.ZERO)
		barrel_flips[ArtKit.last_flip()] = true
	t.check(barrel_flips.keys() == [false], "a barrel never flips")
	ArtKit.begin()
	DecorSprites._sets.erase("sheep_1")
	DecorSprites._sets.erase("barrel_1")
	_unfake(fakes)


## The town's own sheep and cows (TownDecor.spots(), piles' parts too) show every design and both facings: a pasture's
## few cows are mixed by their place in the decor order, not left to seed chance.
static func _herds(t) -> void:
	SpriteArt.set_enabled(true)
	DecorSprites.reload()
	var seen := {D.SHEEP: {}, D.COW: {}}
	var flips := {D.SHEEP: {}, D.COW: {}}
	var pieces := []
	for d: Dictionary in TownDecor.spots():
		pieces.append(d)
		pieces.append_array(d.get("parts", []))
	for d: Dictionary in pieces:
		if d.kind in seen:
			seen[d.kind][DecorSprites.name_for(d.kind, d.seed, d.size, d.at)] = true
			flips[d.kind][DecorSprites.flipped(d.kind, d.seed)] = true
	for k: int in seen:
		var base: String = DecorSprites.BASE[k]
		var want := {}
		for v: int in DecorSprites.variants(base):
			want["%s_%d" % [base, v]] = true
		t.check(want.size() == 2 and seen[k].size() == want.size() and seen[k].keys().all(func(n): return want.has(n)),
			"the town's %s show both designs (got %s)" % [base, seen[k].keys()])
		t.check(flips[k].size() == 2, "the town's %s face both ways (got %s)" % [base, flips[k].keys()])
	var cows := []
	for d: Dictionary in pieces:
		if d.kind == D.COW and TownLayout.PASTURES[1].has_point(d.at):
			cows.append([DecorSprites.name_for(d.kind, d.seed, d.size, d.at), DecorSprites.flipped(d.kind, d.seed)])
	var names := {}
	var fl := {}
	for c: Array in cows:
		names[c[0]] = true
		fl[c[1]] = true
	t.check(cows.size() >= 2 and names.size() == 2 and fl.size() == 2,
		"the east pasture's own cows mix both designs and both facings (got %s)" % [cows])
	t.check(not DecorSprites.flipped(D.BARREL, TownDecor.SEED + 7919), "a barrel never flips, town seed or not")


## The floor's baked meadow shrubs draw the small shrub_<n> / flowerbed_<n> sets (DecorSprites.paint_named); live
## bushes and flowers keep bush_<n> / flowers_<n>; with no such set the floor stays procedural.
static func _floor(t) -> void:
	DecorSprites.reload()
	SpriteArt.set_enabled(true)
	for s in 12:
		t.check(DecorSprites.name_for(D.BUSH, s * 31 + 1, Vector2.ZERO).begins_with("bush_"), "a live bush takes a bush set")
		t.check(DecorSprites.name_for(D.FLOWERS, s * 31 + 1, Vector2.ZERO).begins_with("flowers_"),
			"live flowers take a flowers set")
	t.check(not DecorSprites.variants("shrub").is_empty() and not DecorSprites.variants("flowerbed").is_empty(),
		"the floor's shrub and flowerbed sets are in the manifest")
	t.check(DecorSprites.variants("flowers") == [1, 2, 3], "flowerbed_<n> is not read as a flowers variant (got %s)"
		% [DecorSprites.variants("flowers")])
	var tx := _tex(10, 8)
	var fakes := _fake(["floortest_1"])
	DecorSprites._sets["floortest_1"] = {"name": "floortest_1", "tex": tx, "size": Vector2(10, 8), "anchor": Vector2(5, 7)}
	var at := Vector2(4.37, 2.11)
	ArtKit.begin()
	t.check(DecorSprites.paint_named("floortest", at, 77, Vector2.ZERO), "a floor set paints by its base name")
	var s := ArtKit.segments()
	var q := ArtKit.last_quad()
	t.check(s.size() == 1 and s[0][0] == "tex" and s[0][1] == tx, "from that set's texture")
	t.check(q.size() == 2 and q[1] == (Iso.ground_to_screen(at) - Vector2(5, 7)).round(),
		"at its anchor, on whole pixels (got %s)" % [q])
	ArtKit.begin()
	var drew := true
	for seed_value in 20:
		drew = DecorSprites.paint_named("shrub", at, seed_value, Vector2.ZERO) and drew
	var names := {}
	for seg: Array in ArtKit.segments():
		names[(seg[1] as Texture2D).resource_path.get_base_dir().get_file()] = true
	t.check(drew and names.keys().all(func(n: String) -> bool: return n.begins_with("shrub_")),
		"the floor shrub path draws shrub_<n> sets (got %s)" % [names.keys()])
	ArtKit.begin()
	t.check(not DecorSprites.paint_named("nosuchset", at, 1, Vector2.ZERO) and ArtKit.segments().is_empty(),
		"no set: nothing drawn, the floor keeps its procedural shrub")
	SpriteArt.set_enabled(false)
	ArtKit.begin()
	t.check(not DecorSprites.paint_named("shrub", at, 1, Vector2.ZERO), "F7 off: the floor shrubs are procedural")
	SpriteArt.set_enabled(true)
	ArtKit.begin()
	DecorSprites._sets.erase("floortest_1")
	_unfake(fakes)


static func _real_trees(t) -> void:
	# The real decor tree sets (decor_trees.py), at the procedural trees' size (PropArt.tree: the forest's tall
	# 46..64, the town's 24..32), each with a stump on its own canvas.
	DecorSprites.reload()
	t.check(DecorSprites.variants("forest_oak").size() == 3 and DecorSprites.variants("forest_pine").size() == 2,
		"three forest oak sets and two forest pine sets")
	t.check(DecorSprites.variants("town_oak").size() == 3 and DecorSprites.variants("town_pine").size() == 2,
		"three town oak sets and two town pine sets")
	for base: String in ["forest_oak", "forest_pine", "town_oak", "town_pine"]:
		for v: int in DecorSprites.variants(base):
			var d := DecorSprites.decor_set("%s_%d" % [base, v])
			var lo := 46.0 if base.begins_with("forest") else 24.0
			t.check(not d.is_empty() and d.anchor.y >= lo and d.anchor.y <= lo * 1.3 + 2.0,
				"%s_%d stands as tall as the procedural tree (anchor %s)" % [base, v, d.get("anchor")])
			t.check(d.get("stump") != null and Vector2(d.stump.get_size()) == d.size,
				"%s_%d has a stump on its own canvas" % [base, v])
	# A forest band of oaks and pines queues textured quads only.
	ArtKit.begin()
	for i in 6:
		DecorArt.tree(D.OAK if i % 2 == 0 else D.PINE, Vector2(i, i), Vector2.ZERO, i * 17, Vector2.ZERO,
			ForestLayer.FOREST_CLUSTERS)
	var polys := 0
	for s: Array in ArtKit.segments():
		if s[0] == "poly":
			polys += 1
	t.check(polys == 0, "with the tree sets present, forest trees queue sprites only")
	var segs := ArtKit.segments()
	t.check(segs.size() == 1 and segs[0][0] == "tex" and segs[0][2] == 6,
		"a forest band of mixed oaks and pines is one textured segment (one atlas, got %s)" % [segs])
	ArtKit.begin()
	# Each family is one atlas: its stills side by side, bottom-aligned, each rect its set's size, none overlapping.
	for a: String in DecorSprites.ATLASES:
		var tex: Texture2D = null
		var rects: Array[Rect2] = []
		for base: String in DecorSprites.ATLASES[a]:
			for v: int in DecorSprites.variants(base):
				var d := DecorSprites.decor_set("%s_%d" % [base, v])
				var r: Rect2 = d.get("src", Rect2())
				if tex == null:
					tex = d.tex
				t.check(d.tex == tex, "%s_%d draws from the %s atlas" % [base, v, a])
				t.check(r.size == d.size and r.end.y == float(tex.get_height()),
					"%s_%d's rect is its size, standing on the atlas's bottom (got %s)" % [base, v, r])
				for o: Rect2 in rects:
					t.check(not o.intersects(r), "%s_%d's rect overlaps no other" % [base, v])
				rects.append(r)
	t.check(DecorSprites.decor_set("forest_oak_1").tex != DecorSprites.decor_set("town_oak_1").tex,
		"the town's trees have their own atlas")
	# Drawn from the atlas, a tree takes its rect; knocked down, its stump is still its own texture.
	var oak := DecorSprites.tree_set(D.OAK, 5)
	ArtKit.begin()
	DecorSprites.paint(D.OAK, Vector2(1, 1), Vector2.ZERO, 5, Vector2.ZERO)
	var q := ArtKit.last_quad()
	t.check(q[0] == oak.src and q[1] == (Iso.ground_to_screen(Vector2(1, 1)) - oak.anchor).round(),
		"a forest tree draws its atlas rect at its anchor (got %s)" % [q])
	ArtKit.begin()
	DecorSprites.paint(D.OAK, Vector2(1, 1), Vector2.ZERO, 5, Vector2.ZERO, true)
	var st := ArtKit.segments()
	t.check(st.size() == 1 and st[0][1] == oak.stump and ArtKit.last_quad()[0] == Rect2(Vector2.ZERO, oak.size),
		"a felled forest tree draws its whole stump texture at the same anchor")
	ArtKit.begin()
