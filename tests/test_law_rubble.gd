extends RefCounted
## Law rubble's one look (Decree review R3, LawRubble): a pile is a heap of real ruins art -- a small building set's ruins
## picked by where it lies, or the ruins of the building it came from -- fitted to its footprint; a jagged heap of stones
## and beams with the sprites off; a dust puff as it lands. Its gameplay (role decree, blocking, a crate's health) is
## unchanged, and it never touches a random-number stream.


static func run(t) -> void:
	SpriteArt.set_enabled(true)
	_generic(t)
	_from(t)
	_procedural(t)
	SpriteArt.set_enabled(true)


static func _env() -> EnvironmentField:
	var env := EnvironmentField.new()
	env.rng.seed = 7
	return env


## A heap with no building of its own: one of SETS by its position's hash, the same every time; its ruins in every
## state, fitted; and the pile itself is what it always was.
static func _generic(t) -> void:
	var env := _env()
	var rect := Rect2(Vector2(10.3, 7.6), Vector2(0.9, 0.9))
	var seed_before := env.rng.state
	var pile := LawRubble.lay(env, rect, 9.0)
	var expected := Structure.new().setup(rect, 9.0, Structure.Kind.CRATES, pile.rng.seed, LawRubble.ROLE)
	t.check(pile.role == LawRubble.ROLE and pile.kind == Structure.Kind.CRATES and not pile.walkable and env.structures().has(pile)
		and is_equal_approx(pile.max_hp, 30.0) and pile.art_tag == &"",
		"a pile is still a blocking crate-health structure of role decree, with no building tag")
	t.check(env.rng.state != seed_before and pile.rng.state == expected.rng.state,
		"laying takes one seed from the field, as add_structure always did, and the pile's own stream is untouched")
	var n := String(pile.sprite.get("name", ""))
	t.check(LawRubble.SETS.has(n) and n == LawRubble.art_name(pile), "with sprites on it wears one of the small sets' ruins (%s)" % n)
	var ruins: Texture2D = SpriteArt.sprite(n).stills[&"ruins"]
	var st: Dictionary = pile.sprite.stills
	t.check(st[&"intact"] == ruins and st[&"damaged"] == ruins and st[&"ruins"] == ruins and pile.sprite.idle == null
		and pile.sprite.collapse == null and pile.sprite.glow_mask == null and pile.sprite.chimney == Vector2.INF,
		"its ruins still in every state; nothing of the standing building (idle, collapse, windows, chimney)")
	var fit := float(pile.sprite.get("fit", 0.0))
	var fp: Vector2 = SpriteArt.sprite(n).footprint
	t.check(is_equal_approx(fit, clampf(1.8 / (fp.x + fp.y), LawRubble.FIT_MIN, LawRubble.FIT_MAX)),
		"fitted to its footprint: its sides over the set's (fit %.2f)" % fit)
	pile._sync_sprite()
	t.check(is_instance_valid(pile._sprite_view) and pile._sprite_view.visible and pile._sprite_view.still == &"intact"
		and pile._sprite_view.sprite.stills[pile._sprite_view.still] == ruins and not is_instance_valid(pile._ruins_view),
		"standing, its view shows the heap (the ruins still) and no ruins view under it")
	# The same spot is the same heap; spots apart pick among the sets.
	var env2 := _env()
	var again := LawRubble.lay(env2, rect, 9.0)
	var seen := {}
	for i in 24:
		var r := Rect2(Vector2(3.0 + float(i) * 1.37, 5.0 + float(i % 5) * 0.91), Vector2(0.9, 0.9))
		seen[LawRubble.art_name(LawRubble.lay(env, r, 9.0))] = true
	t.check(String(again.sprite.name) == n and again.sprite.mirror == pile.sprite.mirror and seen.size() >= 3,
		"the same spot always wears the same heap, mirrored the same; 24 spots wear %d sets" % seen.size())
	# A dust puff on the back layer as it lands; look only.
	var back := Node2D.new()
	env.fx_back = back
	var puffed := LawRubble.lay(env, Rect2(Vector2(20, 20), Vector2(1, 1)), 9.0)
	var made := Structure.new().setup(puffed.footprint, 9.0, Structure.Kind.CRATES, puffed.rng.seed, LawRubble.ROLE)
	t.check(back.get_child_count() == 1 and back.get_child(0) is PixelParticles and puffed.rng.state == made.rng.state,
		"a dust puff rises where it lands, and costs the pile's stream nothing")
	back.free()
	for e in [env, env2]:
		for s in e.structures():
			s.free()
		e.free()
	expected.free()
	made.free()


## A heap from a building wears that building's own ruins; from one with no ruins art to lend (procedural, a strip) it
## is a generic heap.
static func _from(t) -> void:
	var env := _env()
	var house := Structure.new().setup(Rect2(Vector2(4, 4), Vector2(1.3, 0.95)), 30.0, Structure.Kind.HOUSE, 11, &"house", &"townhouse")
	var want := SpriteArt.name_for(house)
	var pile := LawRubble.lay(env, Rect2(Vector2(6, 6), Vector2(0.9, 0.9)), 9.0, house)
	t.check(want.begins_with("townhouse_") and pile.art_tag == StringName(want) and String(pile.sprite.name) == want
		and pile.sprite.stills[&"intact"] == SpriteArt.sprite(want).stills[&"ruins"],
		"from a townhouse it wears that townhouse's own ruins (%s)" % want)
	var crates := Structure.new().setup(Rect2(Vector2(8, 8), Vector2(1, 1)), 10.0, Structure.Kind.CRATES, 3)
	var wall := Structure.new().setup(Rect2(Vector2(0, 0), Vector2(1.2, 0.7)), 34.0, Structure.Kind.CASTLE_WALL, 5, &"wall")
	var p2 := LawRubble.lay(env, Rect2(Vector2(9, 9), Vector2(0.9, 0.9)), 9.0, crates)
	var p3 := LawRubble.lay(env, Rect2(Vector2(12, 9), Vector2(0.9, 0.9)), 9.0, wall)
	t.check(p2.art_tag == &"" and LawRubble.SETS.has(String(p2.sprite.name)) and p3.art_tag == &"" and LawRubble.SETS.has(String(p3.sprite.name)),
		"from a building with no set, or a wall strip, it is a generic heap")
	# The tag is read from the building, not from whether sprites are on: a pile laid with them off wears it once on.
	SpriteArt.set_enabled(false)
	var p4 := LawRubble.lay(env, Rect2(Vector2(14, 9), Vector2(0.9, 0.9)), 9.0, house)
	t.check(p4.art_tag == StringName(want) and p4.sprite.is_empty(), "laid with sprites off it keeps its building's tag, drawn procedural")
	SpriteArt.set_enabled(true)
	p4.refresh_sprite()
	t.check(String(p4.sprite.get("name", "")) == want, "and turned on, it shows that building's ruins")
	for s in env.structures():
		s.free()
	env.free()
	house.free()
	crates.free()
	wall.free()


## Sprites off: a heap of jagged stones and two broken beams, never a crate box, the same every time.
static func _procedural(t) -> void:
	SpriteArt.set_enabled(false)
	var env := _env()
	var rect := Rect2(Vector2(5, 5), Vector2(0.9, 0.9))
	var pile := LawRubble.lay(env, rect, 9.0)
	var parts := LawRubble.heap_parts(rect, 9.0)
	var again := LawRubble.heap_parts(rect, 9.0)
	var stones: Array = parts[0]
	var beams: Array = parts[1]
	var jagged := stones.all(func(s: Array) -> bool: return (s[0] as PackedVector2Array).size() == 5 and int(s[1]) in [0, 1, 2])
	t.check(pile.sprite.is_empty() and stones.size() >= 7 and jagged and beams.size() == 2 and str(parts) == str(again),
		"with sprites off: %d jagged stones and 2 beams, the same heap every time" % stones.size())
	var low := INF
	var high := -INF
	for s: Array in stones:
		for v in s[0] as PackedVector2Array:
			low = minf(low, v.y)
			high = maxf(high, v.y)
	t.check(high > low + 6.0 and low < -6.0, "a mound: its stones rise off the ground toward the middle (%.0f..%.0f px)" % [low, high])
	SpriteArt.set_enabled(true)
	for s in env.structures():
		s.free()
	env.free()
