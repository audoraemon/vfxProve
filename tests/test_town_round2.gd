extends RefCounted
## Lighting trial round 2 (DAY and NIGHT only). A: DAY's clean colour, no global orange; the sun's tone split on lit
## content; NIGHT untouched by it. B: the look's extra lights (TownLookDecor): none in CURRENT, visual only (the walk
## grid, the field's structures, decor and lights are as CURRENT's), each feeding the light map.


static func run(t) -> void:
	_day_colour(t)
	for city: StringName in [&"aldermere", &"capital"]:
		City.use(city)
		_props(t, city)
	City.use(&"aldermere")


## DAY keeps hues (greens green, roofs red and blue, grey stone grey), splits lit and shaded faces, and lifts contrast and
## saturation; NIGHT's grade has none of the round-2 keys, so its shader runs with them off.
static func _day_colour(t) -> void:
	var day := TownLook.grade(Town.Look.DAY)
	var night := TownLook.grade(Town.Look.NIGHT)
	for k: String in ["local_amt", "saturation", "contrast"]:
		t.check(not night.has(k), "NIGHT's grade leaves %s at the shader's default (off)" % k)
	var grey := TownGrade.grade_pixel(Color(0.5, 0.5, 0.5), day)
	t.check(absf(grey.r - grey.b) < 0.08, "DAY keeps a mid grey grey, no orange cast (%s)" % str(grey))
	var green := TownGrade.grade_pixel(Color(0.30, 0.50, 0.20), day)
	t.check(green.g > green.r and green.g > green.b, "DAY keeps grass green (%s)" % str(green))
	var red := TownGrade.grade_pixel(Color(0.62, 0.22, 0.18), day)
	t.check(red.r > red.g * 2.0, "DAY keeps a red roof red (%s)" % str(red))
	var blue := TownGrade.grade_pixel(Color(0.25, 0.32, 0.55), day)
	t.check(blue.b > blue.r + 0.2, "DAY keeps a blue roof blue (%s)" % str(blue))
	# Contrast: a dark pixel gets darker and a light one lighter than with the lift off.
	var flat := day.duplicate()
	flat.contrast = 1.0
	flat.saturation = 1.0
	var dark := Color(0.22, 0.20, 0.18)
	var light := Color(0.62, 0.60, 0.56)
	t.check(_lum(TownGrade.grade_pixel(dark, day)) < _lum(TownGrade.grade_pixel(dark, flat)), "DAY's contrast deepens the darks")
	t.check(_lum(TownGrade.grade_pixel(light, day)) > _lum(TownGrade.grade_pixel(light, flat)), "DAY's contrast lifts the lights")
	var c := Color(0.5, 0.48, 0.44)
	var plain := TownGrade.grade_pixel(c, day)
	var sunlit := TownGrade.grade_pixel(c, day, 0.30)
	var shaded := TownGrade.grade_pixel(c, day, 0.70)
	t.check(_lum(sunlit) > _lum(plain) and sunlit.r - sunlit.b > plain.r - plain.b,
		"a face brighter than round it turns brighter and warmer (%s vs %s)" % [str(sunlit), str(plain)])
	t.check(_lum(shaded) < _lum(plain) and shaded.b - shaded.r > plain.b - plain.r,
		"a face darker than round it turns deeper and cooler (%s vs %s)" % [str(shaded), str(plain)])
	t.check(TownGrade.grade_pixel(c, day, _lum(c) + 0.03).is_equal_approx(plain),
		"fine texture inside the dead zone is left alone")
	var src := FileAccess.get_file_as_string("res://src/game/town/town_grade.gdshader")
	t.check(src.contains("vec3 tone_split(") and src.contains("if (local_amt > 0.0)"), "the shader has the tone split, off by default")
	var ground := TownLook.ground_tint(Town.Look.DAY)
	t.check(ground.b > 0.85 and ground.r - ground.b < 0.2, "DAY's ground is no longer baked orange (%s)" % str(ground))


static func _lum(c: Color) -> float:
	return c.r * 0.299 + c.g * 0.587 + c.b * 0.114


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


static func _solid_cells(env: EnvironmentField, town: Town) -> PackedByteArray:
	var wg := WalkGrid.new().setup(env, town)
	var out := PackedByteArray()
	var r := wg.grid.region
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			out.append(1 if wg.grid.is_point_solid(Vector2i(x, y)) else 0)
	return out


static func _props(t, city: StringName) -> void:
	var cur := _build(Town.Look.CURRENT)
	var cur_town: Town = cur[0]
	var cur_env: EnvironmentField = cur[1]
	t.check(cur_town.look_decor == null, "%s: CURRENT has no look decor" % city)
	var none := true
	for n in cur_town.get_children() + (cur[2] as Node).get_children():
		none = none and not (n is TownLookDecor)
	t.check(none, "%s: CURRENT creates no TownLookDecor node" % city)
	var cur_cells := _solid_cells(cur_env, cur_town)
	var cur_counts := [cur_env.structures().size(), cur_env.decor().size(), cur_env.lights._lights.size()]
	_free(cur)
	var night_counts := []
	for look: Town.Look in [Town.Look.NIGHT, Town.Look.DAY]:
		var parts := _build(look)
		var town: Town = parts[0]
		var env: EnvironmentField = parts[1]
		var ld := town.look_decor
		t.check(is_instance_valid(ld) and ld.is_in_group(TownLook.GROUP), "%s %d: the look builds its decor" % [city, look])
		if not is_instance_valid(ld):
			_free(parts)
			continue
		var n_torch := ld.count(TownLookDecor.Prop.TORCH)
		var n_lamp := ld.count(TownLookDecor.Prop.LAMP)
		var n_lantern := ld.count(TownLookDecor.Prop.LANTERN)
		if look == Town.Look.NIGHT:
			night_counts = [n_torch, n_lamp, n_lantern]
			t.check(n_torch > 100 and n_lamp > 20 and n_lantern > 80,
				"%s NIGHT: torches %d, lamps %d, lanterns %d" % [city, n_torch, n_lamp, n_lantern])
		else:
			# Round 3: DAY shows far fewer props (no wall-walk torches, lamps on the main avenues and squares only, lanterns
			# only near them), and its torches are unlit.
			t.check(n_lamp * 2 <= int(night_counts[1]) and n_lantern * 2 <= int(night_counts[2]) and n_torch < int(night_counts[0]),
				"%s DAY: far fewer props (torches %d, lamps %d, lanterns %d against NIGHT's %s)" % [city, n_torch, n_lamp,
					n_lantern, str(night_counts)])
			var unlit := true
			for p in ld.props:
				if p.prop == TownLookDecor.Prop.TORCH:
					unlit = unlit and not ld.lit(p)
			t.check(unlit, "%s DAY: the torches are unlit" % city)
		# Visual only: the walk grid and the field are exactly CURRENT's.
		t.check(_solid_cells(env, town) == cur_cells, "%s %d: the walk grid is CURRENT's (no prop enters it)" % [city, look])
		t.check([env.structures().size(), env.decor().size(), env.lights._lights.size()] == cur_counts,
			"%s %d: no structure, decor or LightField entry is added" % [city, look])
		# A street lamp stands off the road and off every footprint; a lantern off its house; a torch on its wall or tower.
		var feet: Array[Rect2] = []
		for s in env.structures():
			if s.kind != Structure.Kind.FARM_FIELD:
				feet.append(s.footprint)
		var roads: Array = City.current().roads()
		var off := true
		var hosted := true
		for p in ld.props:
			var g: Vector2 = p.at
			match p.prop:
				TownLookDecor.Prop.LAMP:
					for r: Rect2 in feet:
						off = off and not r.has_point(g)
					for r: Rect2 in roads:
						off = off and not r.has_point(g)
				TownLookDecor.Prop.LANTERN:
					off = off and not (p.host as Structure).footprint.has_point(g)
				TownLookDecor.Prop.TORCH:
					hosted = hosted and (p.host as Structure).footprint.grow(0.01).has_point(g)
		t.check(off, "%s %d: every lamp and lantern stands off the roads and footprints" % [city, look])
		t.check(hosted, "%s %d: every torch stands on its wall or tower" % [city, look])
		# Batched: one canvas item per building or lamp, all on the one atlas and material.
		var same := true
		for n in ld.prop_nodes():
			same = same and (n as CanvasItem).material == TownLookDecor.material()
		t.check(same and ld.prop_nodes().size() < ld.props.size(), "%s %d: %d props on %d canvas items, one material" % [city, look,
			ld.props.size(), ld.prop_nodes().size()])
		# Every prop feeds the light map.
		var pools := TownPools.pools_for(town)
		var from_decor := 0
		for p in pools:
			if p.get("look_decor", false):
				from_decor += 1
		var lit := 0
		for p in ld.props:
			lit += 1 if ld.lit(p) else 0
		t.check(from_decor == lit, "%s %d: every lit prop has a pool (%d of %d)" % [city, look, from_decor, lit])
		if look == Town.Look.NIGHT:
			# Round 1's sources: the same town without the look decor and without the look-only window masks.
			town.look_decor = null
			TownLook.active = Town.Look.CURRENT
			var round1 := TownPools.pools_for(town).size()
			TownLook.active = look
			town.look_decor = ld
			t.check(pools.size() >= 3 * round1, "%s NIGHT: light sources %d >= 3x round 1's %d" % [city, pools.size(), round1])
			# A wall's torches hide while it is down.
			var wall: Structure = null
			for p in ld.props:
				if p.prop == TownLookDecor.Prop.TORCH:
					wall = p.host
					break
			ld._on_destroyed(wall)
			var node: Node2D = ld._host_nodes[wall.get_instance_id()]
			t.check(not node.visible, "%s: a fallen wall's torches go out" % city)
			ld._on_restored(wall)
			t.check(node.visible, "%s: a rebuilt wall's torches burn again" % city)
		_free(parts)
