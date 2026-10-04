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
	t.check(DecorSprites.name_for(D.COW, 1, Vector2.ZERO) == "", "a kind with no set stays procedural")
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.name_for(D.BARREL, 7, Vector2.ZERO) == "", "F7 off: every decor piece is procedural")
	SpriteArt.set_enabled(true)
	_unfake(fakes)


static func _trees(t) -> void:
	# OAK and PINE use the batch 3 building sets: oaks over oak_* and the leafy tree_*, pines over the pine tree_*.
	for s in 16:
		var oak: String = DecorSprites.tree_set(D.OAK, s * 31).get("name", "")
		t.check(oak in DecorSprites.OAK_SETS, "a decor oak takes a leafy set (got '%s')" % oak)
		var pine: String = DecorSprites.tree_set(D.PINE, s * 31).get("name", "")
		t.check(pine in DecorSprites.PINE_SETS, "a decor pine takes a pine set (got '%s')" % pine)
	SpriteArt.set_enabled(false)
	t.check(DecorSprites.tree_set(D.OAK, 3).is_empty(), "F7 off: decor trees are procedural")
	SpriteArt.set_enabled(true)


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
	ArtKit.begin()
	t.check(not DecorSprites.paint(Decor.Kind.COW, Vector2(2, 3), Vector2.ZERO, 5, Vector2.ZERO),
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
	ArtKit.begin()
	DecorSprites._sets.erase("fence_x")
	_unfake(fakes)


static func _down(t) -> void:
	# A felled decor oak shows its tree set's ruins (stump and log); a knocked-over barrel shows nothing.
	ArtKit.begin()
	var drew := DecorSprites.paint(Decor.Kind.OAK, Vector2(1, 1), Vector2.ZERO, 9, Vector2.ZERO, true)
	var s := ArtKit.segments()
	t.check(drew and s.size() == 1 and s[0][0] == "tex", "a down oak draws its set's stump")
	var tree := DecorSprites.tree_set(Decor.Kind.OAK, 9)
	t.check(s.size() == 1 and s[0][1] == tree.stills[&"ruins"], "the stump is the set's ruins still")
	ArtKit.begin()


static func _tex(w: int, h: int) -> Texture2D:
	return ImageTexture.create_from_image(Image.create(w, h, false, Image.FORMAT_RGBA8))
