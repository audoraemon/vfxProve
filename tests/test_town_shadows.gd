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
## remove schedule it too; a ruin casts RUIN_FACTOR of the height; the forest's trees have blobs; the layer sits over
## the forest and shares its z.
static func _deferred(t) -> void:
	var parts := _build_day()
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var ground: Node2D = parts[2]
	var shadows := _shadows(town)
	var a := _standing(env, [Structure.Kind.TEMPLE, Structure.Kind.BARRACKS, Structure.Kind.KEEP])
	var b := _standing(env, [Structure.Kind.HOUSE])
	var before := _area(shadows.polygon_of(a).polygon)
	var n0 := shadows.rebuilds
	a.destroy(a.center(), &"smite")
	b.destroy(b.center(), &"smite")
	t.check(shadows.rebuilds == n0, "nothing is rebuilt inside the frame of a destroy")
	await t.process_frame
	t.check(shadows.rebuilds == n0 + 1, "two destroys in one frame cause one rebuild (%d)" % (shadows.rebuilds - n0))
	var after := _area(shadows.polygon_of(a).polygon)
	t.check(after < before, "the deferred rebuild shrank the shadow with no hand call (%.0f to %.0f)" % [before, after])
	var ruin := TownShadows.cast_polygon(TownShadows.diamond_of(a.footprint), a.max_height * TownShadows.RUIN_FACTOR, TownShadows.SHEAR)
	t.check(absf(_area(shadows.polygon_of(a).polygon) - _area(ruin)) < 0.01 and TownShadows.RUIN_FACTOR == 0.15,
		"a ruin casts 0.15 of its height")
	a.restore()
	await t.process_frame
	t.check(shadows.rebuilds == n0 + 2 and absf(_area(shadows.polygon_of(a).polygon) - before) < 0.01,
		"restoring a structure rebuilds its full shadow")
	var added := env.add_structure(Rect2(30, 30, 1, 1), 30.0, Structure.Kind.HOUSE)
	await t.process_frame
	t.check(shadows.polygon_of(added) != null, "an added structure gets a shadow")
	var added_id := added.get_instance_id()
	env.remove(added)
	await t.process_frame
	t.check(shadows.polygon_count() > 0 and not shadows._polys.has(added_id), "a removed structure's shadow is gone")
	t.check(not town.forest.trees.is_empty() and shadows._tree_poly.polygon.size() >= town.forest.trees.size() * 3,
		"every forest tree has a blob (%d points for %d trees)" % [shadows._tree_poly.polygon.size(), town.forest.trees.size()])
	# DAY's tree shadows are soft: 2 stepped bands, low alpha, green-slate (not blue), each blob short and low (no stripes).
	var bands := TownLook.tree_shadow_bands(Town.Look.DAY)
	var soft := shadows.tree_bands.size() == bands.size() and bands.size() >= 2 and bands.size() <= 3
	var green := true
	for bd in bands:
		var c: Color = bd.colour
		soft = soft and c.a <= 0.25
		green = green and c.g > c.b and c.g > c.r
	t.check(soft and green, "DAY tree shadows: 2-3 low-alpha bands, green-slate")
	var minp := Vector2(INF, INF)
	var maxp := Vector2(-INF, -INF)
	for idx: PackedInt32Array in shadows._tree_poly.polygons.slice(0, 1):
		for i in idx:
			var p := shadows._tree_poly.polygon[i]
			minp = minp.min(p)
			maxp = maxp.max(p)
	t.check((maxp.x - minp.x) < 40.0 and (maxp.y - minp.y) < (maxp.x - minp.x) * 0.7,
		"one tree's shadow is a short low ellipse (%.0f x %.0f)" % [maxp.x - minp.x, maxp.y - minp.y])
	t.check(shadows.get_index() > town.forest.get_index() and shadows.z_index == town.forest.z_index
		and shadows.get_parent() == ground, "the shadows sit over the forest on the same z, under the ground plane")
	_free_day(parts)
	_person(t)
	_ownership(t)


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
			if shadows.polygon_of(s) != null:
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
	var before := _area(shadows.polygon_of(hall).polygon)
	hall.destroy(hall.center(), &"smite")
	t.check(shadows._pending, "destroying a structure schedules a shadow rebuild")
	shadows.rebuild()
	var after := _area(shadows.polygon_of(hall).polygon)
	t.check(after < before, "a destroyed building's shadow shrinks to its ruin (%.0f to %.0f)" % [before, after])


static func _no_stack(t, shadows: TownShadows) -> void:
	var ok := shadows.polygon_count() > 0
	for n in shadows.group.get_children():
		ok = ok and n is Polygon2D and n.color == Color.WHITE
	for s in shadows._polys.values():
		ok = ok and (s as Node).get_parent() == shadows.group
	t.check(ok and shadows.group.self_modulate.a < 1.0, "every shadow is an opaque child of one group that sets the alpha")


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
