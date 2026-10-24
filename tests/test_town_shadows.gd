extends RefCounted
## The DAY and NIGHT cast shadows: down-right, long with height, none for flat kinds, rebuilt on destruction, one
## unstacked layer, nothing in CURRENT.


static func run(t) -> void:
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
