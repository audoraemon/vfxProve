extends RefCounted
## The DAY and NIGHT cast shadows: down-right, long with height, none for flat kinds, rebuilt on destruction, one
## unstacked layer, nothing in CURRENT.


static func run(t) -> void:
	await _deferred(t)
	_direction(t)
	_length(t)
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.look = Town.Look.DAY
	town.build(env, ground)
	var shadows := _shadows(town)
	t.check(shadows != null, "a DAY town has a TownShadows")
	if shadows != null:
		_flat(t, env, shadows)
		_destroy(t, env, shadows)
		_no_stack(t, shadows)
	town.teardown()
	town.free()
	env.clear()
	env.free()
	ground.free()
	_current_none(t)
	_exit_tree(t)


static func _build_day() -> Array:
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.look = Town.Look.DAY
	town.build(env, ground)
	return [town, env, ground]


static func _free_day(parts: Array) -> void:
	var lights: LightField = (parts[1] as EnvironmentField).lights
	(parts[0] as Town).teardown()
	(parts[0] as Town).free()
	(parts[1] as EnvironmentField).clear()
	(parts[1] as EnvironmentField).free()
	(parts[2] as Node).free()
	lights.free()


static func _standing(env: EnvironmentField, kinds: Array) -> Structure:
	for s in env.structures():
		if s.kind in kinds and not s.destroyed:
			return s
	return null


## The deferred rebuild really runs on the next idle frame, once for any number of changes in a frame; restore, add and
## remove schedule it too; a sprite building's mask turns to its ruins' still's, a building without a sprite casts a
## hull and its ruin RUIN_FACTOR of the height; the forest's trees cast ellipses in their own green-slate group; the
## layer sits over the forest and shares its z.
static func _deferred(t) -> void:
	var parts := _build_day()
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var ground: Node2D = parts[2]
	var shadows := _shadows(town)
	var a := _standing(env, [Structure.Kind.TEMPLE, Structure.Kind.BARRACKS, Structure.Kind.KEEP])
	var b := _standing(env, [Structure.Kind.HOUSE])
	var stills: Dictionary = a.sprite.stills
	t.check(shadows.shadow_texture(a) == stills[&"intact"], "a standing sprite building casts a mask baked from its intact still")
	var n0 := shadows.rebuilds
	a.destroy(a.center(), &"smite")
	b.destroy(b.center(), &"smite")
	t.check(shadows.rebuilds == n0, "nothing is rebuilt inside the frame of a destroy")
	await t.process_frame
	t.check(shadows.rebuilds == n0 + 1, "two destroys in one frame cause one rebuild (%d)" % (shadows.rebuilds - n0))
	t.check(shadows.shadow_texture(a) == stills[&"ruins"], "the deferred rebuild casts the ruins' mask with no hand call")
	a.restore()
	await t.process_frame
	t.check(shadows.rebuilds == n0 + 2 and shadows.shadow_texture(a) == stills[&"intact"],
		"restoring a structure casts its full mask again")
	var added := env.add_structure(Rect2(30, 30, 1, 1), 30.0, Structure.Kind.HOUSE)
	await t.process_frame
	t.check(shadows.has_shadow(added), "an added structure gets a shadow")
	if shadows.shadow_texture(added) == null:
		# Without a sprite: the hull, and its ruin's hull is RUIN_FACTOR of the height, by hand.
		var before := _area(shadows.polygon_of(added))
		added.destroy(added.center(), &"smite")
		await t.process_frame
		var want := _hand_area(added.footprint, added.max_height * 0.15)
		var got := _area(shadows.polygon_of(added))
		t.check(absf(got - want) < 0.5 and got < before and TownShadows.RUIN_FACTOR == 0.15,
			"a ruin without a sprite casts 0.15 of its height (%.1f vs hand-computed %.1f)" % [got, want])
	var added_id := added.get_instance_id()
	env.remove(added)
	await t.process_frame
	t.check(shadows.polygon_count() > 0 and not shadows._polys.has(added_id), "a removed structure's shadow is gone")
	t.check(not town.forest.trees.is_empty() and shadows.tree_count >= town.forest.trees.size() + TownDecor.border_trees().size()
		and shadows.tree_poly.polygons.size() == shadows.tree_count,
		"every forest and border tree casts an ellipse (%d for %d forest + %d border trees)" % [shadows.tree_count,
			town.forest.trees.size(), TownDecor.border_trees().size()])
	var tree := _standing(env, [Structure.Kind.TREE])
	var lamp := _standing(env, [Structure.Kind.TORCH])
	t.check(tree != null and shadows.has_shadow(tree) and shadows.mask_texture(tree) == null
		and _centroid(shadows.polygon_of(tree)).x > Iso.ground_to_screen(tree.footprint.get_center()).x,
		"a town tree casts an ellipse down and to the right of its foot, no mask")
	t.check(lamp != null and shadows.has_shadow(lamp) and shadows.mask_texture(lamp) == null
		and _area(shadows.polygon_of(lamp)) < 60.0, "a lamp or torch post casts a small foot blob (%.0f px2)" % (
			_area(shadows.polygon_of(lamp)) if lamp != null else -1.0))
	t.check(shadows.mask_texture(a) != null and shadows.mask_texture(a) != shadows.shadow_texture(a),
		"a sprite building casts a baked mask, not its still")
	var tc := TownLook.tree_shadow_colour(Town.Look.DAY)
	t.check(shadows.tree_group.self_modulate == tc and tc.g > tc.b and tc.g > tc.r and tc.a <= 0.5,
		"DAY's tree shadows are a low-alpha green-slate, in a group of their own")
	t.check(shadows.get_index() > town.forest.get_index() and shadows.z_index == town.forest.z_index
		and shadows.get_parent() == ground, "the shadows sit over the forest on the same z, under the ground plane")
	t.check(shadows.silhouette_textures() < 150, "the masks draw from %d textures (one draw each)" % shadows.silhouette_textures())
	_free_day(parts)
	_mask_math(t)
	_person(t)
	_ownership(t)


## A baked mask, from a hand-made sprite: a 1x1-cell box (its footprint's diamond, and a block of wall 40 px tall over
## it) with a 1-px gap row in its wall. The diamond is shadowed (attached), the shadow of the box's top lands about
## 40 * SUN right of and below its base, nothing falls up or to the left of the box, the gap leaves no hole, and the
## quad puts the anchor texel on the base point.
static func _mask_math(t) -> void:
	var w := 80
	var h := 90
	var anchor := Vector2(40, 80)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var d := TownShadows.sprite_diamond(anchor, Vector2.ONE)
	t.check(d[0] == anchor and d[1] == anchor + Vector2(-32, -16) and d[3] == anchor + Vector2(32, -16)
		and d[2] == anchor + Vector2(0, -32), "the sprite's diamond: front at the anchor, sides 32 px out and 16 up")
	for x in range(8, 72):
		var base := TownShadows.diamond_y(d, x + 0.5, true)
		for y in range(int(base) - 40, int(base)):
			if y != int(base) - 20:
				img.set_pixel(x, y, Color.WHITE)
	var m := TownShadows.bake_mask(img, anchor, Vector2.ONE, Vector2.ZERO, false, TownShadows.SUN)
	var pad := TownShadows.MASK_PAD
	var at := func(p: Vector2) -> bool:
		var q := Vector2i(p.floor()) + Vector2i(pad, pad)
		return Rect2i(Vector2i.ZERO, m.get_size()).has_point(q) and m.get_pixelv(q).a > 0.5
	t.check(at.call(anchor + Vector2(0, -16)) and at.call(anchor + Vector2(-20, -12)), "the footprint's diamond is shadowed")
	var used := m.get_used_rect()
	var right := float(used.end.x - pad)
	var low := float(used.end.y - pad)
	t.check(absf(right - (72.0 + 40.0 * TownShadows.SUN.x)) <= 2.5 and absf(low - (80.0 + 40.0 * TownShadows.SUN.y)) <= 2.5,
		"the box's top lands 40 px * SUN from its base, no further (right edge %.0f, bottom %.0f)" % [right, low])
	t.check(at.call(anchor + Vector2(5, 2)) and not at.call(anchor + Vector2(-40, 2)) and not at.call(Vector2(4, 30)),
		"the shadow falls down and to the right, never up or to the left")
	var gap := anchor + TownShadows.SUN * 20.0
	t.check(at.call(gap), "a gap in the wall leaves no hole in the shadow")
	var q := TownShadows.mask_quad(Rect2(Vector2.ZERO, Vector2(m.get_size())), anchor, Vector2(500, 300))
	t.check(q[0] == Vector2(500, 300) - anchor - Vector2(pad, pad), "the quad puts the anchor texel on the base point")
	var r := TownShadows.bake_mask(img, anchor, Vector2.ONE, Vector2.ZERO, false, TownShadows.SUN * 0.5)
	var count := func(im: Image) -> int:
		var n := 0
		for y in im.get_height():
			for x in im.get_width():
				n += 1 if im.get_pixel(x, y).a > 0.5 else 0
		return n
	t.check(count.call(r) < count.call(m), "a lower sun casts a shorter shadow")
	t.check(TownShadows.SUN.x >= 0.45 and TownShadows.SUN.x <= 0.7 and TownShadows.SUN.y > 0.0,
		"the sun's length is moderate (%s per px of height)" % str(TownShadows.SUN))
	var art: Dictionary = SpriteArt.sprite("tavern").duplicate()
	var still: Texture2D = art.stills[&"intact"]
	var m1 := TownShadows.mask_for(still, art)
	var m2 := TownShadows.mask_for(still, art)
	art.mirror = true
	var m3 := TownShadows.mask_for(still, art)
	t.check(m1.tex != null and m1.tex == m2.tex and m3.tex != m1.tex and m3.size == m1.size,
		"a still's mask is baked once and shared; its mirrored mask is baked on its own")


## The foot shadow: untouched in CURRENT, the look's colour and a wider ellipse in DAY and NIGHT.
static func _person(t) -> void:
	var r := Rect2(-4, -1, 9, 2)
	var c := Color(0, 0, 0, 0.35)
	var cur := Person.foot_shadow(r, c)
	t.check(cur[0] == r and cur[1] == c, "CURRENT keeps the person's foot shadow")
	var parts := _build_day()
	var day := Person.foot_shadow(r, c)
	t.check((day[0] as Rect2).size.x > r.size.x and (day[1] as Color).b > (day[1] as Color).r,
		"DAY draws a wider, cool foot shadow")
	t.check((day[1] as Color).a <= 0.6001 and (day[1] as Color).a > TownLook.shadow_colour(Town.Look.DAY).a,
		"the foot shadow is a little darker than the cast shadow")
	_free_day(parts)


## Town A DAY, then town B; A freed without teardown: B keeps the statics.
static func _ownership(t) -> void:
	var a := _build_day()
	var b := _build_day()
	(a[0] as Town).free()
	t.check(not Structure.cast_shadows and TownLook.active == Town.Look.DAY, "an older town freed keeps the newer town's look statics")
	_free_day(b)
	t.check(Structure.cast_shadows and TownLook.active == Town.Look.CURRENT, "the owner's teardown puts them back")
	var lights: LightField = (a[1] as EnvironmentField).lights
	(a[1] as EnvironmentField).clear()
	(a[1] as EnvironmentField).free()
	(a[2] as Node).free()
	lights.free()


static func _shadows(town: Town) -> TownShadows:
	for n in town.look_nodes():
		if n is TownShadows:
			return n
	return null


static func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var q := p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return absf(a) * 0.5


## The area of a footprint's shadow by hand, with no use of cast_polygon: the hull of a convex shape and its copy moved by
## a vector o is the shape plus a strip, so area = the diamond's area + (its width across o) * |o|.
static func _hand_area(r: Rect2, height: float) -> float:
	var d := TownShadows.diamond_of(r)
	var o := TownShadows.SHEAR * height
	# Convex hull of a convex shape swept by a vector: area + width-perpendicular-to-o * |o|.
	var dir := o.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var lo := INF
	var hi := -INF
	for p in d:
		lo = minf(lo, p.dot(perp))
		hi = maxf(hi, p.dot(perp))
	return _area(d) + (hi - lo) * o.length()


static func _centroid(p: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for v in p:
		c += v
	return c / float(p.size())


static func _direction(t) -> void:
	var d := TownShadows.diamond_of(Rect2(2, 2, 2, 2))
	var hull := TownShadows.cast_polygon(d, 20.0, TownShadows.SHEAR)
	var c := _centroid(hull)
	var c0 := _centroid(d)
	t.check(c.x > c0.x and c.y > c0.y, "the shadow falls right of and below its footprint")


static func _length(t) -> void:
	var d := TownShadows.diamond_of(Rect2(2, 2, 2, 2))
	var a20 := _area(TownShadows.cast_polygon(d, 20.0, TownShadows.SHEAR))
	var a40 := _area(TownShadows.cast_polygon(d, 40.0, TownShadows.SHEAR))
	t.check(a40 > a20, "a taller structure casts a larger shadow (%.0f vs %.0f)" % [a40, a20])


static func _flat(t, env: EnvironmentField, shadows: TownShadows) -> void:
	var seen := 0
	var flats := 0
	for s in env.structures():
		if s.kind == Structure.Kind.FARM_FIELD or s.kind == Structure.Kind.BRIDGE:
			flats += 1
			if shadows.has_shadow(s):
				seen += 1
	t.check(flats > 0 and seen == 0, "fields and bridges cast no shadow (%d flat, %d with one)" % [flats, seen])


static func _destroy(t, env: EnvironmentField, shadows: TownShadows) -> void:
	var hall: Structure
	for s in env.structures():
		if s.kind in [Structure.Kind.KEEP, Structure.Kind.TEMPLE, Structure.Kind.BARRACKS] and not s.destroyed:
			hall = s
			break
	if hall == null:
		t.check(false, "town hall found")
		return
	hall.destroy(hall.center(), &"smite")
	t.check(shadows._pending, "destroying a structure schedules a shadow rebuild")
	shadows.rebuild()
	var ruins: Texture2D = (hall.sprite.stills as Dictionary).get(&"ruins")
	t.check(ruins != null and shadows.shadow_texture(hall) == ruins, "a destroyed building casts its ruins' mask")


static func _no_stack(t, shadows: TownShadows) -> void:
	var ok := shadows.polygon_count() > 0 and shadows.group.get_child_count() == 2
	for n in shadows.group.get_children():
		ok = ok and (n is Polygon2D and n.color == Color.WHITE or n is TownShadows.SilhouetteCanvas
			and (n as CanvasItem).material == TownShadows.silhouette_material())
	var sp := shadows.group.get_node("Structures") as Polygon2D
	var hulls := 0
	for s in shadows._polys:
		hulls += 0 if shadows._mask_of.has(s) else 1
	ok = ok and sp.polygons.size() == hulls and shadows.silhouette_count > 0
	t.check(ok and shadows.group.self_modulate.a < 1.0,
		"every shadow is white in one group that sets the alpha once: %d silhouettes, %d hulls" % [shadows.silhouette_count, hulls])
	var src := FileAccess.get_file_as_string("res://src/game/town/town_silhouette.gdshader")
	t.check(src.contains("COLOR = vec4(1.0, 1.0, 1.0, step(0.5, texture(TEXTURE, UV).a));"), "a silhouette is white where its texel is opaque")


static func _current_none(t) -> void:
	var env := EnvironmentField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.build(env, ground)
	t.check(_shadows(town) == null and ground.find_children("*", "CanvasGroup", true, false).is_empty(),
		"a CURRENT town has no TownShadows")
	town.teardown()
	town.free()
	env.clear()
	env.free()
	ground.free()


## A DAY town freed without teardown() puts the look statics back.
static func _exit_tree(t) -> void:
	var env := EnvironmentField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.look = Town.Look.DAY
	town.build(env, ground)
	t.check(not Structure.cast_shadows and TownLook.active == Town.Look.DAY, "a DAY town sets the look statics")
	town.free()
	t.check(Structure.cast_shadows and TownLook.active == Town.Look.CURRENT, "a DAY town freed without teardown puts them back")
	env.clear()
	env.free()
	ground.free()
