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
	_view(t)
	_structure(t)
	_toggle(t)
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


## A view shows one still, mirrors with its set, and carries the footprint's corners into the sprite's own pixels.
static func _view(t) -> void:
	var sp := SpriteArt.sprite("cottage_red")
	var left := Vector2(-30.4, -15.2)
	var right := Vector2(24.0, -12.0)
	var v := SpriteView.new().setup(sp, left, right)
	var mat := v.material as ShaderMaterial
	t.check(v.scale == Vector2.ONE and mat.get_shader_parameter("anchor") == sp.anchor, "a view anchors its sprite")
	t.check(mat.get_shader_parameter("corner_left") == left and mat.get_shader_parameter("corner_right") == right,
		"and knows its footprint's corners")
	v.show_still(&"damaged")
	t.check(v.still == &"damaged" and v.frame == 0, "it shows the still it is given")
	v.set_cut(SpriteView.KEEP_BELOW, 12.0, 0.5)
	t.check(mat.get_shader_parameter("cut_mode") == -1 and is_equal_approx(mat.get_shader_parameter("cut_lift"), 12.0),
		"a cut is the shader's to draw")
	v.free()
	var mirrored := sp.duplicate()
	mirrored.mirror = true
	# A deep cottage's corners (0.75 x 0.95): mirrored, they are the wide sprite's own again.
	var m := SpriteView.new().setup(mirrored, Vector2(-24.0, -12.0), Vector2(30.4, -15.2))
	var mm := m.material as ShaderMaterial
	t.check(m.scale.x == -1.0, "a mirrored set flips its view")
	t.check(mm.get_shader_parameter("corner_left") == left and mm.get_shader_parameter("corner_right") == right,
		"and sees the deep footprint as the wide one it was drawn for")
	m.free()


## A sprite building goes intact -> damaged -> falling -> ruins (or cut, under a laser), and back on a rebuild; its
## view box holds the whole sprite; and sprites change only what is drawn.
static func _structure(t) -> void:
	SpriteArt.set_enabled(true)
	var cot := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	t.check(not cot.sprite.is_empty() and cot.sprite_state() == &"intact", "a cottage stands as its intact sprite")
	cot.damage(cot.max_hp * 0.4, Vector2(-5, -5), &"blast")
	t.check(cot.sprite_state() == &"damaged", "cracked under 65%, it shows the damaged sprite")
	cot.destroy(Vector2(-5, -5), &"blast")
	t.check(cot.sprite_state() == &"falling", "a blast brings it down")
	for i in 90:
		cot._process(1.0 / 60.0)
	t.check(cot.sprite_state() == &"ruins", "and leaves its ruins")
	cot.restore()
	for i in 2:
		cot._process(1.0 / 60.0)
	t.check(cot.sprite_state() == &"intact", "rebuilt, it stands intact again")
	cot.free()
	var tav := _make(Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, 6, &"house", &"tavern")
	tav.destroy(Vector2(-5, -5), &"laser")
	t.check(tav.sprite_state() == &"cut", "a laser slices a tall building")
	tav.free()
	var cat := _make(Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, 7, &"temple", &"cathedral")
	var at: Vector2 = cat.sprite.anchor
	t.check(cat.view_box().encloses(Rect2(cat.base_position() - at, cat.sprite.size)),
		"the view box holds the whole sprite")
	cat.free()
	var proc := _make(Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, 8, &"house", &"townhouse")
	t.check(proc.sprite.is_empty() and proc.sprite_state() == &"", "a building without a sprite keeps its art")
	proc.free()
	t.check(_battered(true) == _battered(false), "sprites on or off, the same hits leave the same buildings")
	SpriteArt.set_enabled(true)


## F7 turns every building's sprite off and on again.
static func _toggle(t) -> void:
	SpriteArt.set_enabled(true)
	var env := EnvironmentField.new()
	var s := env.add_structure(Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy")
	t.check(not s.sprite.is_empty(), "the smithy starts as a sprite")
	var toggle := ArtToggle.new()
	toggle.env = env
	toggle.toggle()
	t.check(not SpriteArt.on() and s.sprite.is_empty(), "F7 turns the sprites off for every building")
	toggle.toggle()
	t.check(SpriteArt.on() and s.sprite.get("name", "") == "smithy", "and on again")
	toggle.free()
	env.clear()
	env.free()


## The proof's buildings put through the same hits, with sprites on or off: their state, as text.
static func _battered(sprites: bool) -> String:
	SpriteArt.set_enabled(sprites)
	var rows := PackedStringArray()
	var specs := [
		[Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, &"house", &"", &"blast"],
		[Rect2(0, 0, 0.75, 0.95), 18.0, K.HOUSE, &"house", &"", &"gravity"],
		[Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, &"house", &"tavern", &"laser"],
		[Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy", &"ice"],
		[Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, &"temple", &"cathedral", &"stone"],
		[Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, &"citadel", &"", &"nova"],
	]
	for i in specs.size():
		var c: Array = specs[i]
		var s := _make(c[0], c[1], c[2], 100 + i, c[3], c[4])
		s.damage(s.max_hp * 0.3, Vector2(-4, -4), c[5])
		s.damage(s.max_hp * 0.3, Vector2(-4, -4), c[5])
		for f in 20:
			s._process(1.0 / 60.0)
		s.damage(s.max_hp, Vector2(-4, -4), c[5])
		for f in 90:
			s._process(1.0 / 60.0)
		var rubble := 0.0
		for r in s._rubble:
			for p in r[0]:
				rubble += p.x * 1.7 + p.y * 2.3
		rows.append("%s hp=%.2f h=%.2f sc=%.3f fr=%.3f cr=%d rub=%.3f col=%.3f st=%d pos=%s" % [s.tuning_key(), s.hp,
			s.height, s.scorch, s.frost, s._cracks.size(), rubble, s._collapse, s.rng.state, s.position])
		s.free()
	return "\n".join(rows)
