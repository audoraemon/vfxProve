extends RefCounted
## SpriteArt and the sprite-drawn buildings of the PixelLab structures proof.

const K := Structure.Kind
const NAMES := ["cottage_red", "cottage_blue", "tavern", "smithy", "cathedral", "citadel_keep", "citadel_tower",
	"citadel_wall", "citadel_wall_side"]


static func _make(rect: Rect2, h: float, kind: Structure.Kind, sd: int, role: StringName, tag := &"") -> Structure:
	return Structure.new().setup(rect, h, kind, sd, role, tag)


static func run(t) -> void:
	_mapping(t)
	_sets(t)
	SpriteArt.set_enabled(true)


## Which building gets which sprite, and the manifest behind them.
static func _mapping(t) -> void:
	var cases := [
		[Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, &"house", &"", "cottage"],
		[Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, &"house", &"townhouse", ""],
		[Rect2(0, 0, 1.3, 1.5), 20.0, K.HOUSE, &"farm", &"", ""],
		[Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, &"house", &"tavern", "tavern"],
		[Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy", "smithy"],
		[Rect2(0, 0, 2.6, 1.5), 22.0, K.HOUSE, &"house", &"workshop", ""],
		[Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, &"temple", &"cathedral", "cathedral"],
		[Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, &"citadel", &"", "citadel_keep"],
		[Rect2(0, 0, 1.3, 1.3), 84.0, K.KEEP, &"citadel", &"", "citadel_tower"],
		[Rect2(0, 0, 1.5, 1.5), 50.0, K.KEEP, &"tower", &"", ""],
		[Rect2(0, 0, 2.8, 0.6), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall"],
		[Rect2(0, 0, 0.6, 2.0), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall_side"],
		[Rect2(0, 0, 1.2, 0.6), 34.0, K.CASTLE_WALL, &"wall", &"", ""],
	]
	for c in cases:
		var s := _make(c[0], c[1], c[2], 5, c[3], c[4])
		var got := SpriteArt.name_for(s)
		var want: String = c[5]
		var ok := got.begins_with("cottage_") if want == "cottage" else got == want
		t.check(ok, "sprite for %s/%s/%s is '%s' (got '%s')" % [K.keys()[c[2]], c[3], c[4], want, got])
		s.free()
	# Cottages pick a roof from their seed: stable per seed, and both roofs appear.
	var seen := {}
	for sd in 40:
		var a := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, sd, &"house")
		var b := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, sd, &"house")
		t.check(SpriteArt.name_for(a) == SpriteArt.name_for(b), "a cottage's roof is stable for its seed")
		seen[SpriteArt.name_for(a)] = true
		a.free()
		b.free()
	t.check(seen.has("cottage_red") and seen.has("cottage_blue"), "both cottage roofs appear")
	for n in NAMES:
		var m: Dictionary = SpriteArt.manifest().get(n, {})
		t.check(m.has("size") and m.has("footprint") and m.has("height") and m.has("kind") and m.has("seed"),
			"the manifest describes " + n)
	t.check(SpriteArt.default_anchor(Vector2(76, 64), Vector2(0.95, 0.75)) == Vector2(41, 54),
		"the anchor centres the footprint's diamond across the canvas, 10 px above its bottom")


## Every set loads: three stills on the manifest's canvas, mirrored only on the other footprint orientation.
static func _sets(t) -> void:
	SpriteArt.set_enabled(true)
	for n in NAMES:
		var sp := SpriteArt.sprite(n)
		t.check(not sp.is_empty(), "the %s set loads" % n)
		if sp.is_empty():
			continue
		for st in SpriteArt.STILLS:
			var tex: Texture2D = sp.stills[st]
			t.check(Vector2(tex.get_size()) == sp.size, "%s/%s is %s" % [n, st, sp.size])
	var wide := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	var deep := _make(Rect2(0, 0, 0.75, 0.95), 17.0, K.HOUSE, 5, &"house")
	var side := _make(Rect2(0, 0, 0.6, 2.0), 40.0, K.CASTLE_WALL, 5, &"citadel")
	var keep := _make(Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, 5, &"citadel")
	t.check(not SpriteArt.set_for(wide).get("mirror", true) and SpriteArt.set_for(deep).get("mirror", false),
		"a deep cottage is the wide one mirrored")
	t.check(SpriteArt.set_for(side).get("mirror", false) and not SpriteArt.set_for(keep).get("mirror", true),
		"a west or east wall is mirrored, the square keep never")
	SpriteArt.set_enabled(false)
	t.check(SpriteArt.set_for(wide).is_empty(), "with sprites off nothing gets a set")
	SpriteArt.set_enabled(true)
	for s in [wide, deep, side, keep]:
		s.free()
