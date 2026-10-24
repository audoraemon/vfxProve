extends RefCounted
## The mist of the DAY and NIGHT looks: its zones lie outside the town in both cities, a CURRENT town has none, the
## sunbeams are DAY only, the mist sits on the ground under everything that stands.


static func run(t) -> void:
	for id: StringName in [&"aldermere", &"capital"]:
		City.use(id)
		_zones(t, id)
		_looks(t, id)
	City.use(&"aldermere")


static func _build(look: Town.Look) -> Array:
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.look = look
	town.build(env, ground)
	return [town, env, ground]


static func _free(parts: Array) -> void:
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var lights := env.lights
	town.teardown()
	town.free()
	env.clear()
	env.free()
	(parts[2] as Node).free()
	lights.free()


static func _mist(town: Town) -> TownMist:
	for n in town.look_nodes():
		if n is TownMist:
			return n
	return null


static func _zones(t, id: StringName) -> void:
	var city := City.current()
	var zones := TownMist.zones(null)
	t.check(zones.size() >= 4, "%s: the mist has zones (%d)" % [id, zones.size()])
	var clear := true
	var inside_world := true
	var outer := city.map().grow(city.border())
	for r in zones:
		clear = clear and not r.intersects(city.town())
		inside_world = inside_world and outer.grow(0.01).encloses(r) and r.has_area()
	t.check(clear, "%s: no mist zone touches the town rect" % id)
	t.check(inside_world, "%s: every zone lies inside the map and its border band" % id)
	var water := 0
	for z in TownMist.tagged_zones():
		if z.kind == &"water":
			water += 1
	t.check(water > 0, "%s: the river has mist (%d water zones)" % [id, water])


static func _looks(t, id: StringName) -> void:
	var cur := _build(Town.Look.CURRENT)
	t.check(_mist(cur[0]) == null and (cur[0] as Town).look_nodes().is_empty(), "%s: a CURRENT town has no TownMist" % id)
	_free(cur)
	var day := _build(Town.Look.DAY)
	var dm := _mist(day[0])
	t.check(dm != null and dm.zone_count() == TownMist.zones(null).size(), "%s: a DAY town has a mist, one quad per zone" % id)
	t.check(dm != null and dm.beam_count() >= 3 * 3, "%s: DAY has sunbeams (%d)" % [id, dm.beam_count() if dm != null else 0])
	if dm != null:
		var ground: Node2D = day[2]
		var forest_i := ground.get_children().find((day[0] as Town).forest)
		t.check(forest_i >= 0 and dm.get_index() > forest_i, "%s: the mist lies over the forest, in the ground plane" % id)
		t.check(dm.get_parent() == ground, "%s: the mist is in the ground plane, under everything that stands" % id)
		t.check(TownMist.mist_colour(Town.Look.DAY).a > TownMist.mist_colour(Town.Look.NIGHT).a, "%s: NIGHT mist is thinner" % id)
	if dm != null:
		_beam_rules(t, dm, id)
	_free(day)
	var night := _build(Town.Look.NIGHT)
	var nm := _mist(night[0])
	t.check(nm != null and nm.zone_count() > 0 and nm.beam_count() == 0, "%s: NIGHT has mist and no sunbeams" % id)
	_free(night)


## The sunbeams: in a "Beams" node under the mist at TownMist.BEAM_Z (above the y-sorted world, where they would be seen),
## so pale that they hide nothing (alpha at most BEAM_MAX_ALPHA a step), with whole-pixel vertices.
static func _beam_rules(t, mist: TownMist, id: StringName) -> void:
	var worst := 0.0
	var whole := true
	var layered := true
	for b in mist.beams():
		worst = maxf(worst, b.color.a)
		var holder := b.get_parent()
		var in_holder: bool = holder != null and holder.get_parent() == mist and holder.name == &"Beams"
		layered = layered and in_holder and holder.z_index == TownMist.BEAM_Z and not holder.z_as_relative \
			and b.z_index == 0
		for p in b.polygon:
			whole = whole and p == p.round()
	t.check(layered, "%s: every beam sits in the mist's Beams node at z %d" % [id, TownMist.BEAM_Z])
	t.check(worst <= TownMist.BEAM_MAX_ALPHA + 0.0001 and worst > 0.0,
		"%s: beam alpha %.3f is within %.3f" % [id, worst, TownMist.BEAM_MAX_ALPHA])
	t.check(whole, "%s: beam vertices are whole world pixels" % id)
