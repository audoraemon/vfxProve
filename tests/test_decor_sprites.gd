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
	_motion(t)
	_plants(t)
	_anim(t)
	_anim_cover(t)
	_strips(t)
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


## Decor moves by material class (Decor.material_for): trees sway most, plants less, boats bob, the rest stand still.
static func _motion(t) -> void:
	var reeds := Decor.material_for(D.REEDS)
	t.check(reeds != null and reeds == Decor.material_for(D.REEDS), "two reeds share one material")
	t.check(Decor.material_for(D.BUSH) == reeds and Decor.material_for(D.FLOWERS) == reeds,
		"bushes and flowers share the reeds' plant material")
	var tree := Decor.material_for(D.OAK)
	t.check(tree != null and tree != reeds, "a tree's material is not a plant's")
	t.check(Decor.material_for(D.PINE) == tree and Decor.material_for(D.BUNTING) == tree, "pines and bunting sway as trees")
	t.check(tree == Decor.wind_material(), "the tree material is the forest's wind material")
	var bob := Decor.material_for(D.SHIP)
	t.check(bob != null and bob == Decor.material_for(D.BOAT), "a ship and a boat share the bob material")
	t.check(bob != tree and bob != reeds, "the bob material is its own")
	t.check(Decor.material_for(D.BARREL) == null, "a barrel stands still (no material)")
	t.check(Decor.material_for(D.DOCK) == null, "a dock stands still though it is on the water")
	t.check(bob.shader == tree.shader and reeds.shader == tree.shader, "every class runs on the one wind shader")
	t.check(float(bob.get_shader_parameter("bob")) > 0.0, "the bob material bobs")
	t.check(float(tree.get_shader_parameter("bob")) == 0.0 and float(reeds.get_shader_parameter("bob")) == 0.0,
		"trees and plants do not bob")
	t.check(float(reeds.get_shader_parameter("sprite_sway")) < 1.5, "a plant sways less than a tree")
	t.check(float(tree.get_shader_parameter("sprite_sway")) == 1.5, "a tree sways 1.5 px at its top")
	for k: int in [D.REEDS, D.BUSH, D.FLOWERS, D.OAK, D.PINE, D.BUNTING]:
		t.check(k in Decor.SWAYS, "%s sways" % Decor.Kind.keys()[k])
	t.check(Decor.BOBS == [D.SHIP, D.BOAT], "ships and boats bob")
	var live := Decor.new().setup(D.REEDS, Vector2(1, 1), Vector2.ZERO, 3)
	live._ready()
	t.check(live.material == reeds, "a live reed takes the plant material")
	live.free()
	live = Decor.new().setup(D.BOAT, Vector2(1, 1), Vector2.ZERO, 3)
	live._ready()
	t.check(live.material == bob, "a live boat takes the bob material")
	live.free()
	live = Decor.new().setup(D.BARREL, Vector2(1, 1), Vector2.ZERO, 3)
	live._ready()
	t.check(live.material == null, "a live barrel has no material")
	live.free()


## Low plants leave the floor bake for the plant layer's wind bands while their sprites are on (Task 8): the baked
## reeds, bushes and flowers, and the floor's meadow shrubs and flowerbeds. Rocks and the rest stay baked.
static func _plants(t) -> void:
	DecorSprites.reload()
	SpriteArt.set_enabled(true)
	var reed := {}
	var rock := {}
	for d in TownDecor.spots():
		if d.bake and d.kind == D.REEDS and reed.is_empty():
			reed = d
		if d.bake and d.kind == D.ROCK and rock.is_empty():
			rock = d
	t.check(not reed.is_empty() and not rock.is_empty(), "the town bakes a reed and a rock")
	t.check(TownFloor.plant_in_layer(reed), "sprites on: a baked reed sways in the plant layer")
	t.check(not TownFloor.plant_in_layer(rock), "sprites on: a baked rock stays in the floor")
	var spots := TownFloor.shrub_spots()
	t.check(spots.size() > 100, "the floor has its meadow shrubs (%d)" % spots.size())
	t.check(TownFloor.shrub_spots().size() == spots.size(), "shrub_spots() is deterministic")
	t.check(spots.all(func(s: Dictionary) -> bool: return s.base in ["shrub", "flowerbed"] and s.at is Vector2),
		"each shrub spot is a shrub or a flowerbed at a ground point")
	t.check(TownFloor.plant_in_layer(spots[0]), "sprites on: a floor shrub sways in the plant layer")
	SpriteArt.set_enabled(false)
	t.check(not TownFloor.plant_in_layer(reed) and not TownFloor.plant_in_layer(rock)
		and not TownFloor.plant_in_layer(spots[0]), "sprites off: every plant stays in the floor bake")
	SpriteArt.set_enabled(true)
	# A plant the bake paints a baked piece over (a garden plot over a shrub; a rock in front of a reed) stays in the
	# bake; a plant in front of the piece, or clear of it, sways.
	var shrub: Dictionary = spots[0].duplicate()
	var plot := {"kind": D.GARDEN, "at": shrub.at - Vector2(0.4, 0.4), "size": Vector2(0.8, 0.8), "seed": 1}
	var far := {"kind": D.GARDEN, "at": shrub.at + Vector2(6, -6), "size": Vector2(0.8, 0.8), "seed": 1}
	var reed_front: Dictionary = reed.duplicate()
	reed_front.at = Vector2(rock.at) + Vector2(0.1, 0.1)
	var reed_back: Dictionary = reed.duplicate()
	reed_back.at = Vector2(rock.at) - Vector2(0.1, 0.1)
	var free_shrub: Dictionary = spots[0].duplicate()
	# In bake paint order (shrubs first, then baked pieces back to front), as the town passes them.
	var marked: Array[Dictionary] = [shrub, reed_back, reed_front]
	TownFloor.mark_under(marked, [plot, rock] as Array[Dictionary])
	var clear: Array[Dictionary] = [free_shrub]
	TownFloor.mark_under(clear, [far] as Array[Dictionary])
	t.check(shrub.get("under", false) and not TownFloor.plant_in_layer(shrub),
		"a shrub under a baked garden plot stays in the bake")
	t.check(reed_back.get("under", false), "a reed behind a baked rock stays in the bake")
	t.check(not reed_front.get("under", false) and TownFloor.plant_in_layer(reed_front), "a reed in front of the rock sways")
	t.check(not free_shrub.get("under", false), "a shrub clear of every baked piece sways")
	# The mark carries back through plants: a reed behind a reed the rock keeps in the bake stays in the bake too
	# (in the layer it would paint over the front reed), though it never touches the rock.
	var front: Dictionary = reed.duplicate()
	front.at = Vector2(rock.at) - Vector2(0.1, 0.1)
	var rock_box := TownFloor._cover_box(rock)
	var front_box := TownFloor._plant_box(front)
	var back := {}
	for si in range(1, 16):
		for ti in range(-15, 16):
			var c: Dictionary = reed.duplicate()
			c.at = Vector2(front.at) + Vector2(-0.1 * si, 0.1 * ti)
			var cb := TownFloor._plant_box(c)
			if back.is_empty() and (c.at as Vector2).x + (c.at as Vector2).y < (front.at as Vector2).x + (front.at as Vector2).y \
					and cb.intersects(front_box) and not cb.intersects(rock_box):
				back = c
	t.check(not back.is_empty(), "a reed behind the front reed that misses the rock exists")
	var chain: Array[Dictionary] = [back, front]
	TownFloor.mark_under(chain, [rock] as Array[Dictionary])
	t.check(front.get("under", false) and back.get("under", false),
		"a reed behind a reed kept in the bake stays in the bake too")
	# The set lookups can be forced past F7 (mark_under sizes its boxes from the sets whatever the art).
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.plant_set(front).is_empty() and not DecorSprites.plant_set(front, true).is_empty(),
		"a forced plant set lookup ignores F7")
	t.check(DecorSprites.name_for(D.REEDS, 3, Vector2.ZERO, Vector2.INF, true) != "", "and so does a forced name_for")
	SpriteArt.set_enabled(true)
	# The town hands the layer every floor shrub spot and every baked low plant, back to front.
	var env := EnvironmentField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.build(env, ground)
	var layer: PlantLayer = town.plant_layer
	t.check(layer != null and ground.get_child_count() == 3 and ground.get_child(0) is TownFloor
		and ground.get_child(1) is PlantLayer and ground.get_child(2) is ForestLayer,
		"the floor, the plant layer, then the forest, under the ground plane")
	var low := town.floor_node.baked_decor.filter(func(d: Dictionary) -> bool: return d.kind in Decor.PLANTS)
	t.check(layer != null and layer.plants.size() == spots.size() + low.size(),
		"the plant layer takes %d shrub spots and %d baked plants (got %d)"
			% [spots.size(), low.size(), layer.plants.size() if layer != null else -1])
	var sorted := true
	if layer != null:
		for i in range(1, layer.plants.size()):
			var a: Vector2 = layer.plants[i - 1].at
			var b: Vector2 = layer.plants[i].at
			if a.x + a.y > b.x + b.y:
				sorted = false
	t.check(sorted, "the plant layer's pieces run back to front")
	var under := layer.plants.filter(func(d: Dictionary) -> bool: return d.get("under", false)) if layer != null else []
	t.check(under.size() > 0 and under.size() < layer.plants.size() / 5,
		"a few plants stay in the bake under baked pieces (%d)" % under.size())
	t.check(town.floor_node.shrubs.size() == spots.size() and town.floor_node.shrubs.all(func(s: Dictionary) -> bool:
			return layer.plants.has(s)), "the floor and the layer share the town's shrub pieces")
	t.check(not TownFloor.shrub_spots().any(func(s: Dictionary) -> bool: return s.has("under")),
		"marking leaves shrub_spots() itself unmarked")
	# A band batches by atlas where the order allows: plants clear of one another, interleaved low / reed / bush, are
	# one segment per atlas, every piece drawn once.
	var base_at := Vector2(-20, 20)
	var mixed: Array = []
	for i in 6:
		var at := base_at + Vector2(i * 2.0, -i * 2.0)
		match i % 3:
			0:
				mixed.append({"base": "shrub", "at": at, "seed": 11 + i})
			1:
				mixed.append({"kind": D.REEDS, "at": at, "size": Vector2.ZERO, "seed": 11 + i})
			2:
				mixed.append({"kind": D.BUSH, "at": at, "size": Vector2.ZERO, "seed": 11 + i})
	var band := PlantLayer.Band.new()
	band.plants = PlantLayer.painter_order(mixed)
	ArtKit.begin()
	band.queue()
	var bsegs := ArtKit.segments()
	t.check(bsegs.size() == 3 and bsegs.all(func(g: Array) -> bool: return g[0] == "tex" and g[2] == 2),
		"six clear plants on three atlases are three textured segments of two (got %s)" % [bsegs])
	# Overlapping plants on two atlases keep their back-to-front order: a shrub, a reed over it, a shrub over that.
	var stack: Array = [
		{"base": "shrub", "at": base_at, "seed": 5},
		{"kind": D.REEDS, "at": base_at + Vector2(0.1, 0.1), "size": Vector2.ZERO, "seed": 5},
		{"base": "shrub", "at": base_at + Vector2(0.2, 0.2), "seed": 6},
	]
	var ordered := PlantLayer.painter_order(stack)
	t.check(ordered == stack, "overlapping plants on two atlases keep their back-to-front order")
	band.plants = ordered
	ArtKit.begin()
	band.queue()
	var ssegs := ArtKit.segments()
	t.check(ssegs.size() == 3 and ssegs[0][1] == ssegs[2][1] and ssegs[1][1] != ssegs[0][1],
		"and draw low, reed, low (got %s)" % [ssegs])
	# The town's bands keep painter order for every overlapping pair, in few segments.
	var inversions := 0
	var segments := 0
	# Off the scene tree the layer has not built its bands yet.
	layer._ready()
	for b in layer.get_children():
		var ps: Array = (b as PlantLayer.Band).plants
		var last := "?"
		for i in ps.size():
			var si := DecorSprites.plant_set(ps[i], true)
			var a := DecorSprites.plant_atlas(si.name) if not si.is_empty() else ""
			if a != last:
				segments += 1
				last = a
			for j in range(i + 1, ps.size()):
				var aj: Vector2 = ps[j].at
				var ai: Vector2 = ps[i].at
				if aj.x + aj.y < ai.x + ai.y and TownFloor._plant_box(ps[i]).intersects(TownFloor._plant_box(ps[j])):
					inversions += 1
	t.check(inversions == 0, "no band draws a plant before an overlapping plant behind it (%d)" % inversions)
	t.check(segments < layer.get_child_count() * 4, "the bands stay a few segments each (%d for %d bands)"
		% [segments, layer.get_child_count()])
	# A piece left in the bake under a baked piece is not drawn by the layer too.
	band.plants = [shrub]
	ArtKit.begin()
	band.queue()
	t.check(ArtKit.segments().is_empty(), "a band leaves a plant marked under to the bake (got %s)" % [ArtKit.segments()])
	ArtKit.begin()
	band.free()
	# A band draws its pieces from the plant atlases: a run of floor shrubs is one textured segment.
	ArtKit.begin()
	for i in 12:
		DecorSprites.paint_plant(spots[i], DecorSprites.plant_set(spots[i]))
	var segs := ArtKit.segments()
	t.check(segs.size() == 1 and segs[0][0] == "tex" and segs[0][2] == 12,
		"twelve floor shrubs and flowerbeds are one textured segment (one atlas, got %s)" % [segs])
	ArtKit.begin()
	# Drawn from its atlas, a plant still stands where its own sprite did.
	var s0 := DecorSprites.plant_set(spots[0])
	DecorSprites.paint_plant(spots[0], s0)
	var q := ArtKit.last_quad()
	t.check(q[0].size == s0.size and q[1] == (Iso.ground_to_screen(spots[0].at) - s0.anchor).round(),
		"a shrub draws its atlas rect at its anchor (got %s)" % [q])
	ArtKit.begin()
	town.free()
	env.clear()
	env.free()
	ground.free()


## A strip of `frames` frames, each w x h, side by side.
static func _strip(frames: int, w: int, h: int) -> Texture2D:
	return _tex(w * frames, h)


## Fake animated sets for `names` (strips of 4 frames at 3 fps), in the set cache; returns what to undo.
static func _animate(names: Array, w := 8, h := 6) -> Array:
	var fakes := _fake(names)
	for n: String in names:
		DecorSprites._sets[n] = DecorSprites._build(n, {"frames": 4, "fps": 3, "size": [w, h], "anchor": [w / 2, h - 1]},
			_strip(4, w, h))
	return fakes


static func _unanimate(names: Array, fakes: Array) -> void:
	for n: String in names:
		DecorSprites._sets.erase(n)
	_unfake(fakes)


## Animated decor (Group C): a set with "frames" > 1 is a horizontal strip, `size` one frame; the piece paints frame
## 0's rect and the wind shader steps the frame on the idle clock. Such a piece is drawn live while sprites are on:
## never in the floor bake, never in a pile.
static func _anim(t) -> void:
	DecorSprites.reload()
	SpriteArt.set_enabled(true)
	# Loading: frames and fps from the manifest; a still is one frame.
	var a := DecorSprites._build("animtest_1", {"frames": 4, "fps": 3, "size": [8, 6], "anchor": [4, 5]}, _strip(4, 8, 6))
	t.check(a.get("frames") == 4 and is_equal_approx(float(a.get("fps", 0.0)), 3.0),
		"a strip set loads frames 4 at 3 fps (got %s)" % [a])
	t.check(a.get("size") == Vector2(8, 6), "its size is one frame")
	var b := DecorSprites._build("animtest_2", {"frames": 4, "fps": 3, "anchor": [4, 5]}, _strip(4, 8, 6))
	t.check(b.get("size") == Vector2(8, 6),
		"with no size, one frame is the strip's width over its frames (got %s)" % [b.get("size")])
	t.check(DecorSprites.decor_set("barrel_1").get("frames") == 1, "a still set is one frame")
	# animated(): by the piece's set.
	var names := ["sheep_1", "sheep_2", "ship"]
	var fakes := _animate(names)
	var seed1 := TownDecor.SEED
	var seed2 := TownDecor.SEED + 7919 * 2
	t.check(DecorSprites.animated(D.SHEEP, seed1) and DecorSprites.animated(D.SHEEP, seed2),
		"a sheep with a strip set is animated")
	t.check(not DecorSprites.animated(D.BARREL, 7), "a barrel (barrel_1, a still) is not")
	# The material: shared per (motion class, frames, fps), with the strip's uniforms.
	var s1 := Decor.new().setup(D.SHEEP, Vector2(1, 1), Vector2.ZERO, seed1)
	var s2 := Decor.new().setup(D.SHEEP, Vector2(3, 1), Vector2.ZERO, seed2)
	s1._ready()
	s2._ready()
	var m := s1.material as ShaderMaterial
	t.check(m != null and m == s2.material, "two animated sheep share one material")
	t.check(m != null and m == Decor.material_for(D.SHEEP, DecorSprites.decor_set("sheep_1")),
		"material_for(kind, set) gives it")
	t.check(m != null and int(m.get_shader_parameter("anim_frames")) == 4
		and is_equal_approx(float(m.get_shader_parameter("anim_fps")), 3.0)
		and is_equal_approx(float(m.get_shader_parameter("frame_u")), 0.25),
		"with anim_frames 4, anim_fps 3 and frame_u a quarter of the strip")
	t.check(m != null and m.shader == Decor.wind_material().shader, "on the one wind shader")
	t.check(Decor.material_for(D.SHEEP) == null, "a still sheep still has no material")
	var ship := Decor.material_for(D.SHIP, DecorSprites.decor_set("ship"))
	t.check(ship != null and ship != m and float(ship.get_shader_parameter("bob")) > 0.0
		and int(ship.get_shader_parameter("anim_frames")) == 4, "an animated ship keeps its bob and steps frames")
	t.check(ship != Decor.material_for(D.SHIP), "apart from the still ships' bob material")
	var still_frames: Variant = Decor.material_for(D.SHIP).get_shader_parameter("anim_frames")
	t.check(still_frames == null or int(still_frames) <= 1, "which steps no frames")
	# It paints frame 0's rect from the strip.
	ArtKit.begin()
	DecorSprites.paint(D.SHEEP, Vector2(1, 1), Vector2.ZERO, seed1, Vector2.ZERO)
	var q := ArtKit.last_quad()
	t.check(q.size() == 2 and q[0] == Rect2(0, 0, 8, 6), "an animated piece paints frame 0's rect (got %s)" % [q])
	ArtKit.begin()
	# F7 off: procedural, no frames, no material.
	SpriteArt.set_enabled(false)
	t.check(not DecorSprites.animated(D.SHEEP, seed1), "F7 off: the sheep is not animated")
	t.check(DecorSprites.animated(D.SHEEP, seed1, Vector2.ZERO, Vector2.INF, true), "unless forced")
	t.check(not DecorSprites.paint(D.SHEEP, Vector2(1, 1), Vector2.ZERO, seed1, Vector2.ZERO),
		"F7 off: the sheep is procedural")
	s1.art_changed()
	t.check(s1.material == null, "and F7 takes its animated material away")
	SpriteArt.set_enabled(true)
	s1.art_changed()
	t.check(s1.material == m, "and gives it back")
	s1.free()
	s2.free()
	# The town: its baked sheep stay in the spot data and the floor's list, but the floor leaves them to a live node.
	var env := EnvironmentField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.build(env, ground)
	var baked_sheep := town.floor_node.baked_decor.filter(func(d: Dictionary) -> bool: return d.kind == D.SHEEP)
	t.check(baked_sheep.size() > 0, "the town bakes sheep (%d)" % baked_sheep.size())
	t.check(baked_sheep.all(func(d: Dictionary) -> bool: return not TownFloor.bakes(d)),
		"sprites on: the floor bakes none of its animated sheep")
	t.check(town.floor_node.baked_decor.any(func(d: Dictionary) -> bool: return d.kind == D.ROCK and TownFloor.bakes(d)),
		"and still bakes its rocks")
	var live := town._decor.filter(func(d: Decor) -> bool: return d.kind == D.SHEEP and d.sprite_only)
	t.check(live.size() == baked_sheep.size(),
		"a live sheep stands for each baked one (%d for %d)" % [live.size(), baked_sheep.size()])
	for d: Decor in live:
		d._ready()
	t.check(live.all(func(d: Decor) -> bool: return d.visible and d.material == m),
		"drawn, with the animated material")
	t.check(live.all(func(d: Decor) -> bool: return not env.decor().has(d)),
		"no gameplay decor (blasts never reach a baked piece)")
	SpriteArt.set_enabled(false)
	for d: Decor in live:
		d.art_changed()
	t.check(baked_sheep.all(func(d: Dictionary) -> bool: return TownFloor.bakes(d)), "F7 off: the floor bakes them again")
	t.check(live.all(func(d: Decor) -> bool: return not d.visible), "and their live stand-ins hide")
	SpriteArt.set_enabled(true)
	town.free()
	env.clear()
	env.free()
	ground.free()
	_unanimate(names, fakes)
	# Piles: an animated part leaves its pile for a live node of its own, which falls with the pile.
	var gnames := ["barrel_1", "barrel_2"]
	var gfakes := _animate(gnames)
	var pile := Decor.new().setup(D.PILE, Vector2(1, 1), Vector2.ZERO, 5)
	pile.parts = [{"kind": D.BARREL, "at": Vector2(1, 1), "size": Vector2.ZERO, "seed": 5},
		{"kind": D.CRATES, "at": Vector2(1.2, 1), "size": Vector2.ZERO, "seed": 6}]
	var drawn := pile.pile_parts_drawn()
	t.check(drawn.size() == 1 and drawn[0].kind == D.CRATES, "sprites on: a pile does not draw its animated barrel")
	SpriteArt.set_enabled(false)
	t.check(pile.pile_parts_drawn().size() == 2, "F7 off: it draws them all")
	SpriteArt.set_enabled(true)
	pile.free()
	env = EnvironmentField.new()
	ground = Node2D.new()
	town = Town.new()
	town.build(env, ground)
	var piled := 0
	var piles := town._decor.filter(func(d: Decor) -> bool: return d.kind == D.PILE)
	for p: Decor in piles:
		piled += p.parts.filter(func(x: Dictionary) -> bool: return x.kind == D.BARREL).size()
	var lone := town._decor.filter(func(d: Decor) -> bool: return d.kind == D.BARREL and d.sprite_only)
	t.check(piled > 0 and lone.size() == piled,
		"each piled barrel gets a live node of its own (%d for %d)" % [lone.size(), piled])
	var host: Decor = null
	for p: Decor in piles:
		if not p.followers.is_empty():
			host = p
			break
	t.check(host != null, "a pile has live parts")
	if host != null:
		host.hit(Decor.KNOCK_AT, &"blast")
		t.check(host.followers.all(func(f: Decor) -> bool: return f.down),
			"knocked down, the pile takes its live parts down too")
	town.free()
	env.clear()
	env.free()
	ground.free()
	_unanimate(gnames, gfakes)
	DecorSprites.reload()


## A live animated piece sits over the whole bake, so what the bake painted over it goes live with it (TownFloor.
## mark_live): a fence in front of a cow and overlapping it is live while sprites are on; one behind it or clear of it
## stays baked. A piece mark_under() keeps under a cover stays baked and still. Stand-ins take the bake's light.
static func _anim_cover(t) -> void:
	DecorSprites.reload()
	SpriteArt.set_enabled(true)
	var names := ["cow_1", "cow_2", "sheep_1", "sheep_2"]
	var fakes := _animate(names)
	var c := Vector2(10, 10)
	var cow := {"kind": D.COW, "at": c, "size": Vector2.ZERO, "seed": 3, "bake": true}
	var behind := {"kind": D.FENCE, "at": c + Vector2(-1.5, -0.6), "size": Vector2(1.5, 0), "seed": 4, "bake": true}
	var front := {"kind": D.FENCE, "at": c + Vector2(-0.3, 0.6), "size": Vector2(1.5, 0), "seed": 5, "bake": true}
	var clear := {"kind": D.FENCE, "at": c + Vector2(5, 5), "size": Vector2(1.5, 0), "seed": 6, "bake": true}
	t.check(TownFloor._cover_box(behind).intersects(TownFloor._cover_box(cow)), "the fence behind overlaps the cow")
	var baked: Array[Dictionary] = [behind, cow, front, clear]
	TownFloor.mark_live(baked)
	t.check(cow.get("live", false) and not TownFloor.bakes(cow), "sprites on: the animated cow is live")
	t.check(front.get("live", false) and not TownFloor.bakes(front), "a fence in front of it, overlapping it, is live too")
	t.check(not behind.get("live", false) and TownFloor.bakes(behind), "a fence behind it stays baked")
	t.check(not clear.get("live", false) and TownFloor.bakes(clear), "a fence clear of it stays baked")
	SpriteArt.set_enabled(false)
	t.check(baked.all(func(d: Dictionary) -> bool: return TownFloor.bakes(d)), "F7 off: all four are baked")
	SpriteArt.set_enabled(true)
	# Under a cover: the animated piece stays baked, at frame 0, and covers nothing live.
	var under := {"kind": D.COW, "at": c, "size": Vector2.ZERO, "seed": 3, "bake": true, "under": true}
	var front2: Dictionary = front.duplicate()
	front2.erase("live")
	var baked2: Array[Dictionary] = [under, front2]
	TownFloor.mark_live(baked2)
	t.check(not under.get("live", false) and TownFloor.bakes(under), "an animated piece marked under stays baked")
	t.check(not front2.get("live", false), "and the fence in front of it stays baked")
	# The town: each stand-in is lit as the bake around it, from the moment it joins the decor layer (in the game the
	# layer is in the tree, so its _ready() runs inside add_child; here it never runs: the colour must not wait on it).
	var env := EnvironmentField.new()
	var world := Node2D.new()
	env.world_parent = world
	var ground := Node2D.new()
	var town := Town.new()
	town.build(env, ground)
	t.check(town._decor_layer != null and town._decor.filter(func(d: Decor) -> bool: return d.sprite_only)
		.all(func(d: Decor) -> bool: return d.get_parent() == town._decor_layer), "the stand-ins join the decor layer")
	var stand := town._decor.filter(func(d: Decor) -> bool: return d.sprite_only)
	var fences := stand.filter(func(d: Decor) -> bool: return d.kind == D.FENCE)
	t.check(fences.size() > 0, "a pasture fence in front of its animals goes live (%d)" % fences.size())
	var lit_ok := true
	for d: Decor in stand:
		var spot: Dictionary = {}
		for b: Dictionary in town.floor_node.baked_decor + town.forest.trees:
			if b.kind == d.kind and b.seed == d.seed_value and b.at == d.at:
				spot = b
		var key := d.tuning_key()
		var baked_col: Color = ArtTuning.tint(key) * (spot.get("tint", Color.WHITE) as Color) * Town.GROUND_EVENING
		var live_col: Color = d.self_modulate * Town.EVENING
		lit_ok = lit_ok and not spot.is_empty() and live_col.is_equal_approx(baked_col)
	t.check(stand.size() > 0 and lit_ok, "every stand-in takes the baked tint (%d stand-ins)" % stand.size())
	var drawn_trees := 0
	for b: Dictionary in town.forest.trees:
		if TownFloor.live_now(b):
			drawn_trees += 1
	t.check(stand.filter(func(d: Decor) -> bool: return d.kind in [D.OAK, D.PINE]).size() == drawn_trees,
		"a tree that goes live is one the forest leaves out (%d)" % drawn_trees)
	# The bug order (ready first, as add_child in the tree runs it, then the multiplier) colours it too.
	var late := Decor.new().setup(D.FENCE, Vector2(1, 1), Vector2(1, 0), 4)
	late._ready()
	late.tint_mul = Color(0.5, 0.5, 0.5)
	t.check(late.self_modulate.is_equal_approx(ArtTuning.tint("fence") * Color(0.5, 0.5, 0.5)),
		"a multiplier set after _ready() still colours the piece")
	late.free()
	town.free()
	env.clear()
	env.free()
	world.free()
	ground.free()
	_unanimate(names, fakes)
	DecorSprites.reload()


## The Group C strips (Task 11): the grazing animals, the scarecrow, the house lantern and the ship's pennant are
## shipped as 4-frame strips: each set loads 4 frames at its rate, its texture is exactly 4 frames wide, and each draws
## live (animated) while sprites are on, with its own frame_u. A mirrored sheep keeps the strip's material.
static func _strips(t) -> void:
	DecorSprites.reload()
	SpriteArt.set_enabled(true)
	var want := {"sheep_1": 2.5, "sheep_2": 2.5, "cow_1": 2.5, "cow_2": 2.5, "scarecrow": 4.0, "lamp_house": 6.0,
		"ship": 5.0}
	for n: String in want:
		var s := DecorSprites.decor_set(n)
		t.check(not s.is_empty() and int(s.get("frames", 1)) == 4, "%s loads 4 frames (got %s)" % [n, s.get("frames")])
		t.check(not s.is_empty() and is_equal_approx(float(s.get("fps", 0.0)), want[n]),
			"%s steps at %s fps (got %s)" % [n, want[n], s.get("fps")])
		var w := (s.get("tex") as Texture2D).get_width() if s.get("tex") != null else -1
		t.check(not s.is_empty() and w == int((s.size as Vector2).x) * 4,
			"%s's strip is 4 frames wide (%d = %s x 4)" % [n, w, s.get("size")])
	# Every kind that draws these sets is animated, and a mirrored sheep draws the same strip material.
	for k: int in [D.SHEEP, D.COW, D.SCARECROW, D.LAMP, D.SHIP]:
		t.check(DecorSprites.animated(k, 1), "kind %d draws an animated set" % k)
	var mirrored := -1
	var plain := -1
	for i in range(40):
		var sd := TownDecor.SEED + i * 7919
		if DecorSprites.name_for(D.SHEEP, sd, Vector2.ZERO) != "sheep_1":
			continue
		if DecorSprites.flipped(D.SHEEP, sd) and mirrored < 0:
			mirrored = sd
		elif not DecorSprites.flipped(D.SHEEP, sd) and plain < 0:
			plain = sd
	t.check(mirrored != -1 and plain != -1, "sheep_1 draws both mirrored and plain (%d, %d)" % [mirrored, plain])
	t.check(DecorSprites.animated(D.SHEEP, mirrored) and DecorSprites.animated(D.SHEEP, plain),
		"a mirrored sheep_1 is animated as a plain one")
	var mat := Decor.material_for(D.SHEEP, DecorSprites.decor_set("sheep_1"))
	t.check(mat != null and is_equal_approx(float(mat.get_shader_parameter("frame_u")), 0.25),
		"sheep_1's material steps quarter-width frames")
