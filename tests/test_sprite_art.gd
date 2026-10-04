extends RefCounted
## SpriteArt and the sprite-drawn buildings of the PixelLab structures proof.

const K := Structure.Kind
const NAMES := ["cottage_red", "cottage_blue", "tavern", "smithy", "cathedral", "citadel_keep", "citadel_tower",
	"citadel_wall", "citadel_wall_side", "citadel_gate", "town_tower", "town_tower_corner", "town_wall",
	"town_postern", "town_gate", "town_tower_e", "town_tower_s", "town_tower_e_hi", "town_tower_s_hi",
	"town_tower_corner_e", "town_tower_corner_s", "town_tower_corner_e_s", "townhouse_a", "townhouse_b", "barracks", "workshop", "bell_tower",
	"stall_1", "stall_1_red", "stall_1_blue", "stall_1_cream", "stall_2", "stall_2_red", "stall_2_blue",
	"stall_2_cream", "stall_3", "stall_3_red", "stall_3_blue", "stall_3_cream", "stall_4", "stall_5", "stall_6",
	"stall_7", "stall_8", "stall_9", "stall_10", "stall_11", "stall_11_red", "stall_11_blue", "stall_11_cream",
	"stall_12", "torch_post", "lamp_post", "tree_1", "tree_2", "tree_3", "tree_4", "tree_5", "oak_1", "oak_2", "oak_3"]


static func _make(rect: Rect2, h: float, kind: Structure.Kind, sd: int, role: StringName, tag := &"") -> Structure:
	return Structure.new().setup(rect, h, kind, sd, role, tag)


static func run(t) -> void:
	_mapping(t)
	_batch3(t)
	_doors(t)
	_sets(t)
	_view(t)
	_strip(t)
	_structure(t)
	_settled_paths(t)
	_idle_strip(t)
	_flames(t)
	_toggle(t)
	SpriteArt.set_enabled(true)


## Adds fake entries (name -> {}) to the cached manifest so mappings resolve without assets; returns the names
## actually added, for _unfake(). Nothing may return or fail between the two, or the fakes leak into later tests.
static func _fake(names: Array) -> Array:
	var m := SpriteArt.manifest()
	var added := []
	for n: String in names:
		if not m.has(n):
			m[n] = {}
			added.append(n)
	SpriteArt._variants_cache.clear()
	return added


## Take the manifest's real entries starting with `prefix` out (for checks on fake ones); _restore puts them back.
static func _hide(prefix: String) -> Dictionary:
	var m := SpriteArt.manifest()
	var out := {}
	for n: String in m.keys():
		if n.begins_with(prefix):
			out[n] = m[n]
			m.erase(n)
	SpriteArt._variants_cache.clear()
	return out


static func _restore(hidden: Dictionary) -> void:
	var m := SpriteArt.manifest()
	for n: String in hidden:
		m[n] = hidden[n]
	SpriteArt._variants_cache.clear()


static func _unfake(added: Array) -> void:
	var m := SpriteArt.manifest()
	for n: String in added:
		m.erase(n)
		SpriteArt._sets.erase(n)
	SpriteArt._variants_cache.clear()


## Which building gets which sprite, and the manifest behind them.
static func _mapping(t) -> void:
	var fakes := _fake(["barn", "carpenter"])
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
		[Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, &"market", &"", "stall"],
	]
	for c in cases:
		var s := _make(c[0], c[1], c[2], 5, c[3], c[4])
		var got := SpriteArt.name_for(s)
		var want: String = c[5]
		var ok := got.begins_with(want + "_") if want in ["cottage", "townhouse", "stall"] else got == want
		t.check(ok, "sprite for %s/%s/%s is '%s' (got '%s')" % [K.keys()[c[2]], c[3], c[4], want, got])
		s.free()
	_unfake(fakes)
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
	# Market stalls (batch 3): every awning cloth draws a stall design's set.
	for sd in [3, 4, 5]:
		var st := _make(Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, sd, &"market")
		var sn := SpriteArt.name_for(st)
		t.check(sn.begins_with("stall_") and not SpriteArt.set_for(st).is_empty(),
			"a stall with cloth %d draws a stall set (got '%s')" % [int(st.art.cloth), sn])
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
	# An animated set (the smithy's smoke) settles at once: its idle frames are its view's to step (_idle_strip()), so
	# the structure's own time crossing an idle frame syncs nothing.
	var smith := _make(Rect2(0, 0, 0.95, 0.75), 17.0, K.HOUSE, 5, &"house")
	smith.sprite = SpriteArt.sprite("smithy").duplicate()
	t.check(int(smith.sprite.frames) > 1, "the smithy's set is animated")
	smith._process(0.001)
	smith._process(0.001)
	t.check(smith._sprite_settled() and _strip_on(smith._sprite_view), "it settles while its view plays its idle strip")
	var first := smith._sprite_view.shown_frame()
	SpriteView.advance(1.0 / float(smith.sprite.fps))
	t.check(smith._sprite_view.shown_frame() == (first + 1) % int(smith.sprite.frames) and smith._sprite_settled(),
		"the shared idle clock steps its strip to the next frame; the structure stays settled")
	smith.free()


## A playing view's idle strip is stepped by its shader from the shared idle clock (SpriteView.advance()) and its
## phase, so neither the view nor the structure under it processes. True when `v` plays its strip that way.
static func _strip_on(v: SpriteView) -> bool:
	return v.playing and not v.is_processing() and v.still == &"intact" 		and int(v.material.get_shader_parameter("idle_frames")) == int(v.sprite.frames)


## True when `v` shows a held still: no idle strip in its shader.
static func _strip_off(v: SpriteView) -> bool:
	return not v.playing and not v.is_processing() and int(v.material.get_shader_parameter("idle_frames")) == 1


## A set with an idle strip (the town gate's swaying banners) steps it from the shared idle clock in its shader, so
## the structure under it sleeps like a still sprite's; a crack, its ruins or F7 stop or restart the view's animation.
## Views take their phase from their structure's seed, so two gates do not step in step.
static func _idle_strip(t) -> void:
	SpriteArt.set_enabled(true)
	var gate := _make(Rect2(0, 0, 2.0, 1.1), 34.0, K.GATE, 5, &"gate")
	t.check(gate.sprite.get("name", "") == "town_gate" and int(gate.sprite.frames) > 1, "the town gate's set is animated")
	gate._ready()
	for i in 4:
		gate._process(1.0 / 60.0)
	var v := gate._sprite_view
	t.check(gate.idle and not gate.is_processing(), "a quiet animated gate goes idle: it stops processing")
	t.check(_strip_on(v), "while its view plays its idle strip from the shared clock")
	var seen := {}
	for i in 60:
		SpriteView.advance(1.0 / 60.0)
		seen[v.shown_frame()] = true
	t.check(seen.size() == int(gate.sprite.frames), "in a second the clock steps it through all %d idle frames (%d)"
		% [int(gate.sprite.frames), seen.size()])
	t.check(gate.idle and not gate.is_processing(), "and the gate sleeps through them")
	gate.damage(gate.max_hp * 0.4, Vector2(-5, -5), &"blast")
	t.check(gate.is_processing(), "a hit wakes it")
	for i in 90:
		gate._process(1.0 / 60.0)
	t.check(gate.sprite_state() == &"damaged" and v.still == &"damaged" and _strip_off(v),
		"cracked, its view shows the damaged still and stops animating")
	gate.destroy(Vector2(-5, -5), &"blast")
	for i in 120:
		gate._process(1.0 / 60.0)
	t.check(gate.sprite_state() == &"ruins" and _strip_off(v),
		"brought down, its view stops animating")
	gate.restore()
	for i in 4:
		gate._process(1.0 / 60.0)
	t.check(gate.sprite_state() == &"intact" and _strip_on(v), "rebuilt, its view plays again")
	gate.free()
	# F7 on an idle animated building: a new view, animating again.
	var f7 := _make(Rect2(0, 0, 2.0, 1.1), 34.0, K.GATE, 5, &"gate")
	f7._ready()
	for i in 4:
		f7._process(1.0 / 60.0)
	t.check(f7.idle and f7._sprite_view.playing, "an idle animated gate")
	SpriteArt.set_enabled(false)
	f7.refresh_sprite()
	for i in 4:
		f7._process(1.0 / 60.0)
	t.check(f7.sprite.is_empty() and not is_instance_valid(f7._sprite_view), "F7 off: its view is gone")
	SpriteArt.set_enabled(true)
	f7.refresh_sprite()
	t.check(f7.is_processing(), "F7 on wakes it")
	f7._process(1.0 / 60.0)
	t.check(is_instance_valid(f7._sprite_view) and _strip_on(f7._sprite_view),
		"and its new view animates its idle strip again")
	for i in 4:
		f7._process(1.0 / 60.0)
	t.check(f7.idle and not f7.is_processing(), "then it goes idle again")
	f7.free()
	# A sprite fountain draws (and idles) its own water: no procedural spin node, so it sleeps. With sprites off (F7)
	# the procedural running water is back and keeps it awake; on again, the node goes and it sleeps again.
	var fo := _make(Rect2(0, 0, 1.2, 1.2), 24.0, K.FOUNTAIN, 5, &"decor")
	t.check(fo.sprite.get("name", "") == "fountain" and int(fo.sprite.frames) > 1, "the fountain's set is animated")
	fo._ready()
	for i in 4:
		fo._process(1.0 / 60.0)
	t.check(not is_instance_valid(fo._spin) and fo._sprite_view.playing, "a sprite fountain has no spin node, its view plays")
	t.check(fo.idle and not fo.is_processing(), "and the fountain goes idle")
	SpriteArt.set_enabled(false)
	fo.refresh_sprite()
	for i in 4:
		fo._process(1.0 / 60.0)
	t.check(is_instance_valid(fo._spin) and fo._spin.visible and fo._spin.get_index() == 0,
		"F7 off: its procedural running water is back, under its other parts")
	t.check(not fo.idle and fo.is_processing(), "and keeps it awake")
	SpriteArt.set_enabled(true)
	fo.refresh_sprite()
	for i in 4:
		fo._process(1.0 / 60.0)
	t.check(not is_instance_valid(fo._spin) and fo.idle and not fo.is_processing(), "F7 on: the spin node goes, it sleeps again")
	fo.free()
	# A sprite tree sways on its view's own clock and sleeps under it, forest tree and town oak alike.
	for tag in [&"", &"oak"]:
		var tr := _make(Rect2(0, 0, 0.7, 0.7) if tag == &"" else Rect2(0, 0, 0.45, 0.45), 28.0, K.TREE, 5, &"decor", tag)
		tr._ready()
		for i in 4:
			tr._process(1.0 / 60.0)
		t.check(String(tr.sprite.get("name", "")).begins_with("oak_" if tag == &"oak" else "tree_")
			and _strip_on(tr._sprite_view), "a sprite tree's view plays its sway")
		t.check(tr.idle and not tr.is_processing(), "and the tree sleeps under it")
		tr.free()
	# Neighbouring trees sway out of step: each view's phase comes from its structure's seed.
	var shown := {}
	for sd in 8:
		var tr := _make(Rect2(0, 0, 0.7, 0.7), 28.0, K.TREE, sd, &"decor")
		tr._ready()
		tr._process(1.0 / 60.0)
		shown[tr._sprite_view.shown_frame()] = true
		tr.free()
	t.check(shown.size() >= 3, "eight trees at one moment show several sway frames (%d)" % shown.size())
	# A well never had running water: no spin node either way.
	var wl := _make(Rect2(0, 0, 0.5, 0.5), 12.0, K.FOUNTAIN, 5, &"decor", &"well")
	wl._ready()
	SpriteArt.set_enabled(false)
	wl.refresh_sprite()
	t.check(wl.sprite.is_empty() and not is_instance_valid(wl._spin), "a procedural well has no spin node")
	SpriteArt.set_enabled(true)
	wl.free()
	# The Citadel keep's banner-drop stills are plain: a keep showing them never animates.
	var keep := _make(Rect2(0, 0, 2.0, 2.0), 118.0, K.KEEP, 5, &"citadel")
	t.check(keep.sprite.stills.has(&"intact_fallen") and int(keep.sprite.frames) > 1, "the citadel keep is animated")
	keep._process(1.0 / 60.0)
	t.check(keep._sprite_view.playing, "with its banners up its view plays")
	keep.drop_banner()
	for i in 60:
		keep._process(1.0 / 60.0)
	t.check(keep._sprite_view.still == &"intact_fallen" and not keep._sprite_view.playing,
		"with its banners down it shows the bannerless still and stops animating")
	keep.free()


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
	# Street torches and lamps: their sprites paint no flame or lit glass; the procedural flame (or the lantern's glow)
	# burns over the sprite, on the bowl's rim (in the glass), and goes out when the post falls.
	for tag in [&"", &"lamp"]:
		var post := _make(Rect2(0, 0, 0.2, 0.2), 16.0 if tag == &"" else 18.0, K.TORCH, 5, &"decor", tag)
		var label := "a lamp" if tag == &"lamp" else "a torch"
		t.check(post.sprite.get("name", "") == ("lamp_post" if tag == &"lamp" else "torch_post") and post.sprite.keep_flames,
			label + " post is a sprite that keeps its flame")
		post._ready()
		post._process(1.0 / 60.0)
		t.check(is_instance_valid(post._flame) and post._flame.visible
			and post._flame.get_index() > post._sprite_view.get_index(), label + "'s flame burns over its sprite")
		var at: Vector2 = post.sprite.anchor
		var want: Vector2 = (post.sprite.flame if tag == &"" else (post.sprite.glass as Rect2).position) - at
		t.check(post._post_flame_tip() == want and want.y < -12.0,
			"%s's flame sits on its sprite's %s, above the post's foot (%s)" % [label, "glass" if tag else "bowl", want])
		post.crack()
		post._process(1.0 / 60.0)
		t.check(post.sprite_state() == &"damaged" and post._flame.visible
			and post._post_flame_tip() == want + (post.sprite.damaged_shift as Vector2),
			label + " damaged: still lit, its flame moved with the post's lean")
		post.destroy(Vector2(-5, -5), &"blast")
		post._process(1.0 / 60.0)
		t.check(not post._flame.visible, label + " destroyed: its flame is out")
		post.free()
	# With sprites off a procedural post draws its own flame: its flame node stays hidden (no double flame).
	SpriteArt.set_enabled(false)
	var proc := _make(Rect2(0, 0, 0.2, 0.2), 16.0, K.TORCH, 5, &"decor")
	proc._ready()
	proc._process(1.0 / 60.0)
	t.check(proc.sprite.is_empty() and is_instance_valid(proc._flame) and not proc._flame.visible,
		"a procedural torch's flame node stays hidden: it draws its own flame")
	proc.free()
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


## Batch 3 sets (docs/superpowers/specs/2026-10-04-ref-convert-batch3-design.md): stalls with a cloth tint, fountain and
## well, torch and lamp posts, tree and oak variants, bridge and dock, barn and mills, field crops. Each maps only
## when its set is in the manifest; a missing one falls back to "" (procedural).
static func _batch3(t) -> void:
	var hidden := _hide("stall_")
	for prefix in ["fountain", "well", "torch_post", "lamp_post", "tree_", "oak_"]:
		hidden.merge(_hide(prefix))
	var name_of := func(r: Rect2, h: float, k: K, sd: int, role: StringName, tag := &"") -> String:
		var s := _make(r, h, k, sd, role, tag)
		var n := SpriteArt.name_for(s)
		s.free()
		return n
	var fixed := [
		[Rect2(0, 0, 0.6, 0.6), 24.0, K.FOUNTAIN, &"decor", &"", "fountain"],
		[Rect2(0, 0, 0.6, 0.6), 12.0, K.FOUNTAIN, &"decor", &"well", "well"],
		[Rect2(0, 0, 0.2, 0.2), 16.0, K.TORCH, &"decor", &"", "torch_post"],
		[Rect2(0, 0, 0.2, 0.2), 18.0, K.TORCH, &"decor", &"lamp", "lamp_post"],
		[Rect2(0, 0, 2.0, 1.0), 6.0, K.BRIDGE, &"bridge", &"stone", "bridge_stone"],
		[Rect2(0, 0, 2.0, 1.0), 4.0, K.BRIDGE, &"dock", &"dock", "dock"],
		[Rect2(0, 0, 1.3, 1.5), 20.0, K.HOUSE, &"farm", &"", "barn"],
		[Rect2(0, 0, 0.9, 0.9), 60.0, K.HOUSE, &"farm", &"windmill", "windmill"],
		[Rect2(0, 0, 2.4, 1.9), 34.0, K.HOUSE, &"farm", &"watermill", "watermill"],
		[Rect2(0, 0, 2.3, 1.15), 20.0, K.HOUSE, &"house", &"carpenter", "carpenter"],
	]
	# Without the sets in the manifest every one of them stays procedural.
	for c in fixed:
		t.check(name_of.call(c[0], c[1], c[2], 5, c[3], c[4]) == "", "no '%s' set in the manifest: %s is procedural" % [c[5], K.keys()[c[2]]])
	t.check(name_of.call(Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, 5, &"market") == "", "no stall design: procedural")
	t.check(name_of.call(Rect2(0, 0, 0.3, 0.3), 25.0, K.TREE, 5, &"decor") == "", "no tree variant: procedural")
	t.check(name_of.call(Rect2(0, 0, 0.3, 0.3), 25.0, K.TREE, 5, &"decor", &"oak") == "", "no oak variant: procedural")
	t.check(name_of.call(Rect2(0, 0, 2.0, 1.0), 3.0, K.FARM_FIELD, 5, &"farm") == "", "no field set: procedural")
	var fakes := _fake(["stall_1", "stall_2", "stall_3", "stall_1_red", "stall_1_blue", "stall_2_cream",
		"tree_1", "tree_2", "oak_1", "oak_2", "oak_3", "field_0", "field_1"])
	for c in fixed:
		fakes += _fake([c[5]])
	for c in fixed:
		var got: String = name_of.call(c[0], c[1], c[2], 5, c[3], c[4])
		t.check(got == c[5], "%s/%s/%s maps to %s (got '%s')" % [K.keys()[c[2]], c[3], c[4], c[5], got])
	# A tag with no mapping stays procedural even with every set present (a thorn bush is not an oak).
	t.check(name_of.call(Rect2(0, 0, 0.3, 0.3), 25.0, K.TREE, 5, &"decor", &"thorns") == "", "thorns stay procedural")
	# Stall: the design hashes the seed over the stall_<n> in the manifest (never over stall_<n>_<tint>); the cloth
	# picks the tint when it exists and otherwise the plain design.
	var designs := {}
	var tints_ok := true
	for sd in 120:
		var s := _make(Rect2(0, 0, 0.9, 0.7), 10.0, K.MARKET_STALL, sd, &"market")
		var n := SpriteArt.name_for(s)
		var base := n.substr(0, 7)
		designs[base] = true
		var tinted: String = base + "_" + ["red", "blue", "cream"][int(s.art.cloth)]
		tints_ok = tints_ok and (n == tinted if SpriteArt.manifest().has(tinted) else n == base)
		tints_ok = tints_ok and base in ["stall_1", "stall_2", "stall_3"] and n == SpriteArt.name_for(s)
		s.free()
	t.check(tints_ok, "a stall takes its cloth's tint when that variant exists, else its plain design")
	t.check(designs.size() == 3, "all three stall designs get used across seeds (got %d)" % designs.size())
	# Trees: tree_<n> and oak_<n> only from their own lists.
	var trees := {}
	var oaks := {}
	for sd in 80:
		trees[name_of.call(Rect2(0, 0, 0.3, 0.3), 25.0, K.TREE, sd, &"decor")] = true
		oaks[name_of.call(Rect2(0, 0, 0.3, 0.3), 25.0, K.TREE, sd, &"decor", &"oak")] = true
	t.check(trees.size() == 2 and trees.has("tree_1") and trees.has("tree_2"), "trees pick tree_1 / tree_2: %s" % [trees.keys()])
	t.check(oaks.size() == 3 and oaks.has("oak_3"), "oaks pick oak_1..3: %s" % [oaks.keys()])
	# Fields: the crop of the field's plan.
	var crops := {}
	for sd in 40:
		var f := _make(Rect2(0, 0, 2.0, 1.0), 3.0, K.FARM_FIELD, sd, &"farm")
		t.check(SpriteArt.name_for(f) == "field_%d" % int(f.art.crop), "a field draws its crop's set")
		crops[int(f.art.crop)] = true
		f.free()
	t.check(crops.size() == 2, "both crops appear")
	_unfake(fakes)
	t.check(not SpriteArt.manifest().has("stall_1") and not SpriteArt.manifest().has("barn"), "the fake entries were removed")
	_restore(hidden)
	_stall_variety(t)
	_tree_variety(t)
	_flat_sprites(t)


## The town's stalls (TownLayout.STALLS) with the real stall designs: each plot's design comes from its place in the
## market, whatever its seed, so no two neighbouring stalls (side by side, or one behind the other: centres within 1.5)
## share a design, and more than six designs show. Every stall draws a set that exists, in its cloth's tint when the
## design is striped.
static func _stall_variety(t) -> void:
	var designs: Array = SpriteArt.variants("stall")
	t.check(designs.size() >= 7, "at least seven stall designs in the manifest (got %d)" % designs.size())
	t.check(TownLayout.STALLS.size() >= 29, "the town has at least 29 stalls")
	var picked := []
	var ok := true
	for i in TownLayout.STALLS.size():
		var a := _make(TownLayout.STALLS[i], 10.0, K.MARKET_STALL, 11 + i, &"market")
		var b := _make(TownLayout.STALLS[i], 10.0, K.MARKET_STALL, 9001 + 7 * i, &"market")
		var na := SpriteArt.name_for(a)
		var base := SpriteArt._stall_design(a)
		ok = ok and base == SpriteArt._stall_design(b) and SpriteArt.manifest().has(na) and na.begins_with(base)
		ok = ok and not SpriteArt.sprite(na).is_empty()
		picked.append(base)
		a.free()
		b.free()
	t.check(ok, "a market stall's design depends on its plot only, and its set exists")
	var clash := []
	for i in TownLayout.STALLS.size():
		for j in range(i + 1, TownLayout.STALLS.size()):
			var ci: Vector2 = TownLayout.STALLS[i].get_center()
			var cj: Vector2 = TownLayout.STALLS[j].get_center()
			if ci.distance_to(cj) <= 1.5 and picked[i] == picked[j]:
				clash.append("%d/%d %s" % [i, j, picked[i]])
	t.check(clash.is_empty(), "no two neighbouring market stalls share a design (%s)" % [clash])
	var seen := {}
	for p in picked:
		seen[p] = true
	t.check(seen.size() > 6, "the market shows more than six designs (got %d)" % seen.size())


## The town's trees with the real tree and oak sets: across the forest ring (60+) every forest variant shows and none
## takes more than half, and the town's oaks show at least two designs; each draws a set that exists and idles (a crown
## sway) yet sleeps like any quiet structure: its view steps the strip on its own.
static func _tree_variety(t) -> void:
	SpriteArt.set_enabled(true)
	t.check(SpriteArt.variants("tree").size() >= 4 and SpriteArt.variants("oak").size() >= 2,
		"tree and oak variants in the manifest (%s / %s)" % [SpriteArt.variants("tree"), SpriteArt.variants("oak")])
	var env := EnvironmentField.new()
	env.rng.seed = 7
	var town := Town.new()
	town.build(env)
	var forest := {}
	var oaks := {}
	var n_forest := 0
	var ok := true
	for st in env.structures():
		if st.kind != K.TREE:
			continue
		var n := SpriteArt.name_for(st)
		ok = ok and n != "" and not SpriteArt.sprite(n).is_empty() and int(SpriteArt.sprite(n).frames) == 4
		if st.art_tag == &"oak":
			oaks[n] = oaks.get(n, 0) + 1
		elif st.art_tag == &"":
			forest[n] = forest.get(n, 0) + 1
			n_forest += 1
	t.check(ok, "every town tree draws a tree or oak set with a 4-frame sway")
	t.check(n_forest >= 40, "the forest ring has 40+ trees (got %d)" % n_forest)
	var most := 0
	for k in forest:
		most = maxi(most, forest[k])
	t.check(forest.size() == SpriteArt.variants("tree").size() and most * 2 <= n_forest,
		"every forest variant shows and none takes over: %s" % [forest])
	t.check(oaks.size() >= 2, "the town's oaks show several designs: %s" % [oaks])
	town.free()
	env.free()


## Bridge, dock and fields are flat: with a sprite they stay on the ground layer, under the people who walk on them.
static func _flat_sprites(t) -> void:
	SpriteArt.set_enabled(true)
	var cases := [
		[Rect2(0, 0, 2.0, 1.0), 6.0, K.BRIDGE, &"bridge", &"stone", "bridge_stone"],
		[Rect2(0, 0, 2.0, 1.0), 4.0, K.BRIDGE, &"dock", &"dock", "dock"],
		[Rect2(0, 0, 2.0, 1.0), 3.0, K.FARM_FIELD, &"farm", &"", "field_0"],
	]
	for c in cases:
		var fakes := _fake([c[5]])
		# Borrow a real set's textures under the fake name so the structure is truly sprite-drawn.
		SpriteArt._sets[c[5]] = SpriteArt.sprite("smithy")
		var d := _make(c[0], c[1], c[2], 5, c[3], c[4])
		if c[2] == K.FARM_FIELD:
			d.art.crop = 0
			d.refresh_sprite()
		t.check(not d.sprite.is_empty(), "%s is drawn from a sprite" % c[5])
		t.check(d.z_index == -1 and d.walkable, "%s with a sprite stays on the ground layer, walkable" % c[5])
		d.free()
		_unfake(fakes)
