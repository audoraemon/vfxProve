extends RefCounted
## SpriteArt and the sprite-drawn buildings of the PixelLab structures proof.

const K := Structure.Kind
const NAMES := ["cottage_red", "cottage_blue", "tavern", "smithy", "cathedral", "citadel_keep", "citadel_tower",
	"citadel_wall", "citadel_wall_side", "citadel_gate", "town_tower", "town_tower_corner", "town_wall",
	"town_postern", "town_gate", "town_tower_e", "town_tower_s", "town_tower_e_hi", "town_tower_s_hi",
	"town_tower_corner_e", "town_tower_corner_s", "town_tower_corner_e_s", "townhouse_a", "townhouse_b", "barracks", "workshop"]


static func _make(rect: Rect2, h: float, kind: Structure.Kind, sd: int, role: StringName, tag := &"") -> Structure:
	return Structure.new().setup(rect, h, kind, sd, role, tag)


static func run(t) -> void:
	_mapping(t)
	_doors(t)
	_sets(t)
	_view(t)
	_strip(t)
	_structure(t)
	_settled_paths(t)
	_flames(t)
	_toggle(t)
	SpriteArt.set_enabled(true)


## Which building gets which sprite, and the manifest behind them.
static func _mapping(t) -> void:
	var cases := [
		[Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, &"house", &"", "cottage"],
		[Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, &"house", &"townhouse", "townhouse"],
		[Rect2(0, 0, 1.3, 1.5), 20.0, K.HOUSE, &"farm", &"", "barn"],
		[Rect2(0, 0, 0.9, 0.9), 60.0, K.HOUSE, &"farm", &"windmill", ""],
		[Rect2(0, 0, 2.4, 1.9), 34.0, K.HOUSE, &"farm", &"watermill", ""],
		[Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, &"house", &"tavern", "tavern"],
		[Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, &"house", &"smithy", "smithy"],
		[Rect2(0, 0, 2.6, 1.5), 22.0, K.HOUSE, &"house", &"workshop", "workshop"],
		[Rect2(0, 0, 2.3, 1.15), 20.0, K.HOUSE, &"house", &"carpenter", "carpenter"],
		[Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, &"temple", &"cathedral", "cathedral"],
		[Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, &"citadel", &"", "citadel_keep"],
		[Rect2(0, 0, 1.3, 1.3), 84.0, K.KEEP, &"citadel", &"", "citadel_tower"],
		[Rect2(0, 0, 1.6, 1.6), 46.0, K.KEEP, &"tower", &"", "town_tower"],
		[Rect2(0, 0, 2.0, 2.0), 50.0, K.KEEP, &"tower", &"", "town_tower_corner"],
		[Rect2(0, 0, 1.1, 1.1), 60.0, K.KEEP, &"tower", &"bell_tower", "bell_tower"],
		[Rect2(0, 0, 1.6, 1.6), 46.0, K.KEEP, &"tower", &"door_e", "town_tower_e"],
		[Rect2(0, 0, 1.6, 1.6), 52.0, K.KEEP, &"tower", &"door_s_hi", "town_tower_s_hi"],
		[Rect2(0, 0, 2.0, 2.0), 50.0, K.KEEP, &"tower", &"door_e_s", "town_tower_corner_e_s"],
		[Rect2(0, 0, 2.0, 2.0), 50.0, K.KEEP, &"tower", &"door_s", "town_tower_corner_s"],
		# A door tag without its variant in the manifest falls back to the plain tower, never a blank one.
		[Rect2(0, 0, 1.6, 1.6), 46.0, K.KEEP, &"tower", &"door_e_hi_s_hi", "town_tower"],
		[Rect2(0, 0, 2.0, 2.0), 50.0, K.KEEP, &"tower", &"door_e_hi", "town_tower_corner"],
		[Rect2(0, 0, 2.8, 0.6), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall"],
		[Rect2(0, 0, 0.6, 2.0), 40.0, K.CASTLE_WALL, &"citadel", &"", "citadel_wall_side"],
		[Rect2(0, 0, 2.8, 0.6), 40.0, K.CASTLE_WALL, &"citadel", &"gate", "citadel_gate"],
		[Rect2(0, 0, 1.2, 0.7), 34.0, K.CASTLE_WALL, &"wall", &"", "town_wall"],
		[Rect2(0, 0, 0.7, 1.1), 34.0, K.CASTLE_WALL, &"wall", &"", "town_wall"],
		[Rect2(0, 0, 2.0, 1.1), 34.0, K.GATE, &"gate", &"", "town_gate"],
		[Rect2(0, 0, 1.1, 2.0), 34.0, K.GATE, &"gate", &"", "town_gate"],
		[Rect2(0, 0, 1.15, 0.7), 34.0, K.GATE, &"gate", &"postern", "town_postern"],
		[Rect2(0, 0, 4.4, 1.9), 36.0, K.BARRACKS, &"barracks", &"", "barracks"],
		[Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, &"market", &"", ""],
	]
	for c in cases:
		var s := _make(c[0], c[1], c[2], 5, c[3], c[4])
		var got := SpriteArt.name_for(s)
		var want: String = c[5]
		var ok := got.begins_with(want + "_") if want in ["cottage", "townhouse"] else got == want
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
	# Townhouses pick one of two looks from their seed, as cottages pick a roof.
	var looks := {}
	for sd in 40:
		var th := _make(Rect2(0, 0, 1.3, 0.95), 29.0, K.HOUSE, sd, &"house", &"townhouse")
		looks[SpriteArt.name_for(th)] = true
		th.free()
	t.check(looks.has("townhouse_a") and looks.has("townhouse_b") and looks.size() == 2, "both townhouse looks appear")
	# Market stalls stay procedural for now (user review 2026-10-04): every awning cloth, no sprite set.
	for sd in [3, 4, 5]:
		var st := _make(Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, sd, &"market")
		t.check(SpriteArt.name_for(st) == "" and SpriteArt.set_for(st).is_empty(),
			"a stall with cloth %d stays procedural" % int(st.art.cloth))
		st.free()
	for n in NAMES:
		var m: Dictionary = SpriteArt.manifest().get(n, {})
		t.check(m.has("size") and m.has("footprint") and m.has("height") and m.has("kind") and m.has("seed"),
			"the manifest describes " + n)
	t.check(SpriteArt.default_anchor(Vector2(76, 64), Vector2(0.95, 0.75)) == Vector2(41, 54),
		"the anchor centres the footprint's diamond across the canvas, 10 px above its bottom")


## The town towers' walkway doors: each tower's tag names the visible faces (east = right, south = left on screen)
## a wall walk (LOW) or a gatehouse walkway (HIGH) enters, and every tag the layout gives has its sprite.
static func _doors(t) -> void:
	var tags := {}
	for d in TownLayout.structures():
		if d.role == &"tower":
			tags[d.rect] = d.tag
	var corners := TownLayout.corner_towers()  # NW, NE, SE, SW
	t.check(tags[corners[0]] == &"door_e_s", "the NW corner opens on both faces (got '%s')" % tags[corners[0]])
	t.check(tags[corners[1]] == &"door_s", "the NE corner opens south (got '%s')" % tags[corners[1]])
	t.check(tags[corners[2]] == &"", "the SE corner's walls join hidden faces (got '%s')" % tags[corners[2]])
	t.check(tags[corners[3]] == &"door_e", "the SW corner opens east (got '%s')" % tags[corners[3]])
	var gt := TownLayout.GATE_TOWERS
	t.check(tags[gt[0]] == &"door_e_hi", "the Main Gate's west tower opens high onto the gate (got '%s')" % tags[gt[0]])
	t.check(tags[gt[1]] == &"door_e", "the Main Gate's east tower opens onto the wall (got '%s')" % tags[gt[1]])
	t.check(tags[gt[2]] == &"door_s_hi", "the Side Gate's north tower opens high onto the gate (got '%s')" % tags[gt[2]])
	t.check(tags[gt[3]] == &"door_s", "the Side Gate's south tower opens onto the wall (got '%s')" % tags[gt[3]])
	var bare: Array = []
	var missing: Array = []
	for r: Rect2 in tags:
		var tag: StringName = tags[r]
		if tag == &"bell_tower":
			continue
		if tag == &"" and not r in corners:
			bare.append(r)
		var s := _make(r, 46.0, K.KEEP, 5, &"tower", tag)
		var base := "town_tower_corner" if r.size.x >= 1.8 else "town_tower"
		if tag != &"" and SpriteArt.name_for(s) == base:
			missing.append("%s %s" % [r, tag])
		s.free()
	t.check(bare.is_empty(), "every wall and gate tower meets a wall on a visible face (%s)" % [bare])
	t.check(missing.is_empty(), "every door tag the layout gives has its sprite (%s)" % [missing])


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
	# Smoke rises from a sprite's own chimney (mirrored with it); a sprite with its smoke drawn in has none.
	var red := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	red.sprite = SpriteArt.sprite("cottage_red").duplicate()
	var at: Vector2 = red.sprite.anchor
	var chim := Vector2(SpriteArt.manifest().cottage_red.chimney[0], SpriteArt.manifest().cottage_red.chimney[1])
	t.check(ChimneySmoke.tip_of(red) == chim - at, "a cottage smokes from its sprite's chimney")
	red.sprite.mirror = true
	t.check(ChimneySmoke.tip_of(red) == Vector2(at.x - chim.x, chim.y - at.y), "mirrored with it")
	red.free()
	var inn := _make(Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, 5, &"house", &"tavern")
	t.check(ChimneySmoke.tip_of(inn) == Vector2.INF, "the tavern's smoke is in its sprite")
	inn.free()
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
	# The same cut again never reaches the material: a parameter set re-uploads it even when nothing changed.
	mat.set_shader_parameter("cut_lift", 3.0)
	v.set_cut(SpriteView.KEEP_BELOW, 12.0, 0.5)
	t.check(is_equal_approx(mat.get_shader_parameter("cut_lift"), 3.0), "an unchanged cut is not set again")
	v.set_cut(SpriteView.KEEP_ALL, 0.0)
	t.check(mat.get_shader_parameter("cut_mode") == 0 and is_equal_approx(mat.get_shader_parameter("cut_lift"), 0.0),
		"a changed one is")
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


## A wall piece reads its own stretch of its strip, from where it stands: neighbours join, a run wraps at the strip's
## period without a jog, and a run along y reads the strip mirrored the way a run along x reads it.
static func _strip(t) -> void:
	# A strip spanning 3.7 units (period 2.5 + one 1.2 piece) whose run starts (u = 0) at pixel (30, 100).
	var base := {"anchor": Vector2(30, 100) + Vector2(32, 16) * 3.7, "footprint": Vector2(3.7, 0.7),
		"size": Vector2(170, 170), "period": 2.5}
	var a := SpriteArt.strip_piece(base, Rect2(10.0, 3.0, 1.2, 0.7), false)
	var b := SpriteArt.strip_piece(base, Rect2(11.2, 3.0, 1.1, 0.7), false)
	var c := SpriteArt.strip_piece(base, Rect2(12.3, 3.0, 1.2, 0.7), false)
	var d := SpriteArt.strip_piece(base, Rect2(13.5, 3.0, 1.0, 0.7), false)
	t.check(a.region.position.is_equal_approx(Vector2(30, 0)) and is_equal_approx(a.region.size.x, 38.4)
		and is_equal_approx(a.region.size.y, 170.0), "a piece at the period's start reads the strip's first stretch")
	t.check(a.anchor.is_equal_approx(Vector2(30, 100) + Vector2(32, 16) * 1.2), "anchored at its own front corner")
	t.check(is_equal_approx(b.region.position.x, a.region.end.x) and is_equal_approx(c.region.position.x, b.region.end.x),
		"each piece starts where the one before it ends")
	t.check((b.anchor - a.anchor).is_equal_approx(Vector2(32, 16) * 1.1)
		and (c.anchor - b.anchor).is_equal_approx(Vector2(32, 16) * 1.2), "and is placed one piece further along")
	t.check(c.region.end.x <= 170.0 + 0.001, "a piece running past the period stays inside the strip")
	# d wraps to the period's start: its stretch is c's continuation one period back.
	t.check(d.anchor.x < c.anchor.x and (d.anchor + Vector2(32, 16) * 2.5 - c.anchor).is_equal_approx(Vector2(32, 16) * 1.0),
		"a run wraps at the period without a jog")
	var y := SpriteArt.strip_piece(base, Rect2(3.0, 10.0, 0.7, 1.2), true)
	t.check(y.anchor.is_equal_approx(a.anchor) and y.region.is_equal_approx(a.region),
		"a run along y reads the strip mirrored, measured along y")
	for n in SpriteArt.manifest():
		var m: Dictionary = SpriteArt.manifest()[n]
		if m.get("strip", false):
			t.check(float(m.footprint[0]) >= float(m.period) + TownLayout.WALL_PIECE - 0.001 and is_equal_approx(fmod(float(m.period) * 16.0, 1.0), 0.0),
				"%s spans a period plus a piece, and its period is a whole number of pixels" % n)
	t.check(is_equal_approx(SpriteArt.STRIP_PIECE, TownLayout.WALL_PIECE), "a strip's longest piece is the town's")
	# A strip set without a positive period would read its stretch at fposmod(start, 0) = NaN and vanish: it is drawn
	# as one whole frame instead (with a warning).
	var real: Dictionary = SpriteArt.manifest()["town_wall"]
	var bad := real.duplicate(true)
	bad.erase("period")
	SpriteArt.manifest()["town_wall"] = bad
	SpriteArt._sets.erase("town_wall")
	var no_period := SpriteArt.sprite("town_wall")
	SpriteArt.manifest()["town_wall"] = real
	SpriteArt._sets.erase("town_wall")
	t.check(not no_period.is_empty() and not no_period.strip, "a strip set without a period is drawn whole, not as a strip")
	t.check(SpriteArt.sprite("town_wall").strip, "and the real town wall is a strip again")


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
	# A quiet sprite building stops re-syncing its views every frame; a crack or the blight still reaches them.
	var calm := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	for i in 2:
		calm._process(1.0 / 60.0)
	t.check(calm._sprite_settled(), "a quiet sprite building is settled: its views are not synced again")
	calm.set_blighted(true)
	calm._process(1.0 / 60.0)
	t.check(calm._sprite_view.color == Structure.BLIGHT_TINT, "the blight's tint still reaches its sprite")
	calm.crack()
	calm._process(1.0 / 60.0)
	t.check(calm._sprite_view.still == &"damaged" and calm._sprite_settled(), "and so does a crack, then it settles again")
	calm.free()
	# A set with a generated collapse plays it as it falls, ending on its ruins; gravity keeps the engine's squeeze.
	var red := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 9, &"house")
	red.sprite = SpriteArt.sprite("cottage_red").duplicate()
	t.check(red.sprite.collapse != null and int(red.sprite.collapse_frames) > 1, "the red cottage has a generated collapse")
	red.destroy(Vector2(-5, -5), &"blast")
	for i in 24:
		red._process(1.0 / 60.0)
	t.check(red._sprite_view.still == &"collapse" and red._sprite_view.frame > 0 and red._sprite_view.position == Vector2.ZERO
		and not is_instance_valid(red._ruins_view), "a blast plays the generated collapse instead of sinking")
	for i in 60:
		red._process(1.0 / 60.0)
	t.check(red.sprite_state() == &"ruins" and red._ruins_view.still == &"ruins", "and leaves the ruins it ends on")
	red.free()
	var pulled := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 9, &"house")
	pulled.sprite = SpriteArt.sprite("cottage_red").duplicate()
	pulled.destroy(Vector2(-5, -5), &"gravity")
	for i in 24:
		pulled._process(1.0 / 60.0)
	t.check(pulled._sprite_view.still == &"damaged" and pulled._sprite_view.position.y > 0.0,
		"gravity still sinks and squeezes it")
	pulled.free()
	var tav := _make(Rect2(0, 0, 2.4, 1.5), 30.0, K.HOUSE, 6, &"house", &"tavern")
	tav.destroy(Vector2(-5, -5), &"laser")
	t.check(tav.sprite_state() == &"cut", "a laser slices a tall building")
	tav.free()
	var cat := _make(Rect2(0, 0, 4.2, 6.2), 56.0, K.TEMPLE, 7, &"temple", &"cathedral")
	var at: Vector2 = cat.sprite.anchor
	t.check(cat.view_box().encloses(Rect2(cat.base_position() - at, cat.sprite.size)),
		"the view box holds the whole sprite")
	# The cathedral's sprite covers less than its plot: its shadow is the building's, centred on the plot.
	var own := cat._sprite_shadow()
	var plot := cat._shadow()
	var lean := Vector2(6, -3)
	t.check(own[1].x - own[3].x < plot[1].x - plot[3].x - 20.0, "a sprite smaller than its plot casts a smaller shadow")
	t.check(((own[0] + own[2] - lean) * 0.5).distance_to((plot[0] + plot[2] - lean) * 0.5) < 1.0,
		"centred on the plot")
	var hut := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	t.check(hut._sprite_shadow() == hut._shadow(), "a sprite without its own shadow casts its footprint's")
	hut.free()
	# The Citadel's 20% signal: the sprite keep's banners slide down and fade, then it stands bannerless.
	var keep := _make(Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, 5, &"citadel", &"keep")
	t.root.add_child(keep)
	keep.drop_banner()
	for i in 20:
		keep._process(1.0 / 60.0)
	t.check(keep._sprite_view.still == &"intact_fallen" and is_instance_valid(keep._flag_view)
		and keep._flag_view.still == &"banners_intact" and keep._flag_view.position.y > 0.0,
		"the keep's banners fall, and it shows the bannerless keep behind them")
	for i in 60:
		keep._process(1.0 / 60.0)
	t.check(not is_instance_valid(keep._flag_view) and keep._sprite_view.still == &"intact_fallen",
		"once they have fallen the keep stays bannerless")
	keep.crack()
	keep._process(1.0 / 60.0)
	t.check(keep._sprite_view.still == &"damaged_fallen", "and cracked, it is the bannerless damaged keep")
	keep.free()
	cat.free()
	var proc := _make(Rect2(0, 0, 0.9, 0.9), 60.0, K.HOUSE, 8, &"farm", &"windmill")
	t.check(proc.sprite.is_empty() and proc.sprite_state() == &"", "a building without a sprite keeps its art")
	proc.free()
	t.check(_battered(true) == _battered(false), "sprites on or off, the same hits leave the same buildings")
	SpriteArt.set_enabled(true)
	# The Citadel tags its keep and its gateway after making them; they still get their own sprites.
	var env := EnvironmentField.new()
	var cit := Citadel.new().setup(env, Vector2.ZERO)
	t.check(cit.parts[5].sprite.get("name", "") == "citadel_gate" and cit.keep.sprite.get("name", "") == "citadel_keep"
		and cit.parts[4].sprite.get("name", "") == "citadel_wall", "the Citadel's gateway and keep get their own sprites")
	cit.free()
	env.clear()
	env.free()


## The settled skip's riskiest paths: a settled building re-read by F7, and one rebuilt from settled ruins.
static func _settled_paths(t) -> void:
	SpriteArt.set_enabled(true)
	var cot := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	for i in 4:
		cot._process(1.0 / 60.0)
	t.check(cot._sprite_settled(), "a quiet cottage settles")
	SpriteArt.set_enabled(false)
	cot.refresh_sprite()
	cot.crack()
	for i in 4:
		cot._process(1.0 / 60.0)
	t.check(cot.sprite.is_empty() and not is_instance_valid(cot._sprite_view), "F7 off: the settled cottage drops its sprite")
	SpriteArt.set_enabled(true)
	cot.refresh_sprite()
	for i in 4:
		cot._process(1.0 / 60.0)
	t.check(is_instance_valid(cot._sprite_view) and cot._sprite_view.visible and cot._sprite_view.still == &"damaged",
		"F7 on: it gets a new view showing the crack it took while sprites were off")
	cot.free()
	var fell := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	fell.destroy(Vector2(-5, -5), &"blast")
	for i in 120:
		fell._process(1.0 / 60.0)
	t.check(fell.sprite_state() == &"ruins" and fell._sprite_settled() and is_instance_valid(fell._ruins_view)
		and not fell._sprite_view.visible, "its ruins settle")
	fell.restore()
	for i in 4:
		fell._process(1.0 / 60.0)
	t.check(fell._sprite_view.visible and fell._sprite_view.still == &"intact" and not is_instance_valid(fell._ruins_view),
		"rebuilt from settled ruins, it shows its intact still again and its ruins are gone")
	fell.free()
	# An animated set (the smithy's smoke) settles between its idle frames, and still steps to the next one.
	var smith := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	smith.sprite = SpriteArt.sprite("smithy").duplicate()
	t.check(smith._sprite_frames == int(smith.sprite.frames) and smith._sprite_frames > 1, "the smithy's set is animated")
	smith._process(0.001)
	var first := smith._sprite_view.frame
	smith._process(0.001)
	t.check(smith._sprite_settled() and smith._sprite_view.frame == first,
		"between its idle frames it is settled: its views are not synced every frame")
	smith._process(1.0 / float(smith.sprite.fps))
	t.check(smith._sprite_view.frame == (first + 1) % smith._sprite_frames, "on its next idle frame it syncs and steps")
	smith.free()


## Wall torches and the barracks' forge keep their procedural flames over their sprites (the sprites paint none);
## sets that paint their own light (the cottages' none, the gate's torches) get no flame node or keep it hidden.
static func _flames(t) -> void:
	SpriteArt.set_enabled(true)
	t.check(SpriteArt.sprite("town_wall").keep_flames and SpriteArt.sprite("barracks").keep_flames
		and not SpriteArt.sprite("town_gate").keep_flames and not SpriteArt.sprite("smithy").keep_flames,
		"the town wall and the barracks keep their flames; the gate and the smithy paint their own")
	var wall: Structure = null
	for sd in range(1, 80):
		var w := _make(Rect2(0, 0, 1.2, 0.7), 34.0, K.CASTLE_WALL, sd, &"wall")
		if w.art.get("torch", false):
			wall = w
			break
		w.free()
	t.check(wall != null and wall.sprite.get("name", "") == "town_wall", "a town wall piece with a torch")
	wall._ready()
	wall._process(1.0 / 60.0)
	t.check(is_instance_valid(wall._flame) and wall._flame.visible, "keeps its torch's flame with sprites on")
	t.check(wall._flame.get_index() > wall._sprite_view.get_index(), "drawn over its sprite, not hidden behind it")
	wall.destroy(Vector2(-5, -5), &"blast")
	wall._process(1.0 / 60.0)
	t.check(not wall._flame.visible, "and loses it when it falls")
	wall.free()
	var bar := _make(Rect2(0, 0, 4.4, 1.9), 36.0, K.BARRACKS, 5, &"barracks")
	bar._ready()
	bar._process(1.0 / 60.0)
	t.check(bar.sprite.get("name", "") == "barracks" and is_instance_valid(bar._flame) and bar._flame.visible,
		"the barracks' forge stays lit with sprites on")
	bar.free()
	var smith := _make(Rect2(0, 0, 1.5, 1.25), 20.0, K.HOUSE, 5, &"house", &"smithy")
	smith._ready()
	smith._process(1.0 / 60.0)
	t.check(not smith._flame.visible, "the sprite smithy's painted forge is not doubled")
	smith.free()
	var cot := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	cot._ready()
	t.check(not is_instance_valid(cot._flame), "a cottage has no flame")
	cot.free()


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
