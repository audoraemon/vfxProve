extends RefCounted
## The DAY and NIGHT colour grade and the NIGHT light pools: pools counted from the static lights and the lit windows,
## LightField untouched, layer order under the glow, pools locked to the world, no pools by day.


static func run(t) -> void:
	_params(t)
	_layers_and_counts(t)
	_lightfield_untouched(t)
	_day(t)
	_capital_lamps(t)
	_calm(t)
	await _world_space(t)
	_band_texture(t)


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


static func _find(town: Town, script: GDScript) -> Node:
	for n in town.look_nodes():
		if is_instance_of(n, script):
			return n
	return null


static func _params(t) -> void:
	var day := TownLook.grade(Town.Look.DAY)
	var night := TownLook.grade(Town.Look.NIGHT)
	t.check(day.warm.x > day.warm.z and day.cool.z > day.cool.x, "DAY: warm highlights, cool darks")
	t.check(night.calm > 0.0 and day.calm == 0.0, "NIGHT calms its dark blues (the water), DAY does not")
	t.check(night.gain.x < 0.7 and night.gain.z > night.gain.x, "NIGHT darkens toward moonlight blue")
	var c := TownLook.shadow_colour(Town.Look.DAY)
	t.check(c.b > c.r and c.r > 0.12 and c.b < 0.5, "DAY shadow is a cool slate, not a navy patch")
	t.check(TownLook.shadow_colour(Town.Look.NIGHT).a > 0.0, "NIGHT shadows still read")


static func _layers_and_counts(t) -> void:
	var parts := _build(Town.Look.NIGHT)
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var grade := _find(town, TownGrade) as TownGrade
	var pools := _find(town, TownPools) as TownPools
	t.check(grade != null and pools != null, "a NIGHT town has a grade and pools")
	if grade != null and pools != null:
		t.check(grade.layer < pools.layer and pools.layer < Battlefield.GLOW_LAYER,
			"grade layer %d < pools layer %d < glow layer %d" % [grade.layer, pools.layer, Battlefield.GLOW_LAYER])
		t.check(pools.follow_viewport_enabled, "the pools follow the viewport")
		var statics := 0
		for l in env.lights._lights:
			if l.get("static", false):
				statics += 1
		var windows := 0
		for s in env.structures():
			if not s.destroyed and s.sprite is Dictionary and s.sprite.get("glow_mask") != null \
					and TownPools.lit_pixels(s.sprite.glow_mask) > 0:
				windows += 1
		var lamps := 0
		for d: Decor in town._decor:
			if d.kind == Decor.Kind.LAMP and not d.down:
				lamps += 1
		var listed := TownPools.pools_for(town)
		t.check(statics > 0 and windows > 0 and lamps > 0, "Aldermere has torches (%d), lit windows (%d) and decor lamps (%d)" % [statics, windows, lamps])
		t.check(listed.size() == statics + windows + lamps, "pools_for: %d == %d torches + %d windows + %d decor lamps" % [listed.size(), statics, windows, lamps])
		t.check(pools.pool_count() == listed.size(), "a Sprite2D per pool")
		var ok := true
		for p in listed:
			ok = ok and p.radius > 0.0 and p.color.a > 0.0 and p.has("flicker")
		t.check(ok, "every pool has a radius, a colour and a flicker")
	_free(parts)


## The capital's street lamps are decor, not LightField lights: at NIGHT each throws a pool, so the capital has more pools
## than static lights alone; a lamp knocked down loses its pool; nothing is registered in LightField.
static func _capital_lamps(t) -> void:
	City.use(&"capital")
	var parts := _build(Town.Look.NIGHT)
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var statics := 0
	for l in env.lights._lights:
		if l.get("static", false):
			statics += 1
	var before: int = env.lights._lights.size()
	var listed := TownPools.pools_for(town)
	var from_decor := 0
	for p in listed:
		if p.has("decor"):
			from_decor += 1
	t.check(listed.size() > statics, "the capital at NIGHT has more pools (%d) than static lights (%d)" % [listed.size(), statics])
	t.check(from_decor > 0, "the capital's decor lamps throw pools (%d)" % from_decor)
	t.check(env.lights._lights.size() == before, "the lamp pools register nothing in LightField")
	var pools := _find(town, TownPools) as TownPools
	t.check(pools != null and pools.pool_count() == listed.size(), "a Sprite2D per pool, decor lamps included")
	var fallen: Decor = null
	for d: Decor in town._decor:
		if not TownPools.lamp_pool(d).is_empty():
			fallen = d
			break
	if fallen != null:
		var idx := -1
		for i in pools.pool_count():
			if pools._pools[i].decor == fallen:
				idx = i
		t.check(idx >= 0 and pools.pool_sprite(idx).visible, "the lamp's pool shows while it stands")
		fallen.down = true
		t.check(TownPools.lamp_pool(fallen).is_empty(), "a lamp knocked down has no pool")
		pools._process(0.016)
		t.check(idx >= 0 and not pools.pool_sprite(idx).visible, "the live pool sprite hides after the lamp falls")
	_free(parts)
	City.use(&"aldermere")


## `calm` greys only what was already saturated blue before the grade (water): grey stone, warm wood and a lit window are
## untouched by it, a river-blue pixel is greyed, and with calm at 0 (DAY) the output is the grade's alone.
static func _calm(t) -> void:
	var night := TownLook.grade(Town.Look.NIGHT)
	var no_calm := night.duplicate()
	no_calm.calm = 0.0
	var stone := Color(0.46, 0.46, 0.48)
	var wood := Color(0.55, 0.38, 0.22)
	var river := Color(0.16, 0.38, 0.78)
	for c: Color in [stone, wood]:
		var a := TownGrade.grade_pixel(c, night)
		var b := TownGrade.grade_pixel(c, no_calm)
		t.check(a.is_equal_approx(b), "calm leaves %s untouched" % str(c))
	var wet := TownGrade.grade_pixel(river, night)
	var dry := TownGrade.grade_pixel(river, no_calm)
	var sat := func(x: Color) -> float: return maxf(x.r, maxf(x.g, x.b)) - minf(x.r, minf(x.g, x.b))
	t.check(sat.call(wet) < sat.call(dry) * 0.7, "calm greys a saturated river blue (%.3f -> %.3f)" % [sat.call(dry), sat.call(wet)])
	var day := TownLook.grade(Town.Look.DAY)
	var day0 := day.duplicate()
	day0.calm = 0.0
	var same := true
	for c: Color in [stone, wood, river, Color(0.9, 0.8, 0.6)]:
		same = same and TownGrade.grade_pixel(c, day).is_equal_approx(TownGrade.grade_pixel(c, day0))
	t.check(same and day.calm == 0.0, "DAY output is identical with calm at 0")
	# The shader and grade_pixel() are the same formula: the shader measures the ungraded colour.
	var src := FileAccess.get_file_as_string("res://src/game/town/town_grade.gdshader")
	t.check(src.contains("c.b - max(c.r, c.g)") and not src.contains("g.b - max"), "the shader measures blueness on the ungraded colour")


static func _lightfield_untouched(t) -> void:
	var a := _build(Town.Look.CURRENT)
	var b := _build(Town.Look.NIGHT)
	var la: LightField = (a[1] as EnvironmentField).lights
	var lb: LightField = (b[1] as EnvironmentField).lights
	t.check(la._lights.size() == lb._lights.size(), "NIGHT registers no light of its own (%d vs %d)" % [la._lights.size(), lb._lights.size()])
	var same := true
	for p in [Vector2(0, 0), Vector2(1.4, -2.6), Vector2(0.8, 2.0), Vector2(-3, 2), Vector2(5, 5)]:
		same = same and la.sample(p).is_equal_approx(lb.sample(p))
	t.check(same, "LightField.sample is the same in CURRENT and NIGHT")
	_free(b)
	_free(a)


static func _day(t) -> void:
	var parts := _build(Town.Look.DAY)
	var town: Town = parts[0]
	t.check(_find(town, TownGrade) != null and _find(town, TownPools) == null, "DAY has a grade and no pools")
	_free(parts)
	var cur := _build(Town.Look.CURRENT)
	t.check((cur[0] as Town).look_nodes().is_empty(), "CURRENT has no grade and no pools")
	_free(cur)


## The pools follow the camera: a pool's on-screen position moves by -dx * zoom when the camera moves by dx.
static func _world_space(t) -> void:
	await t.process_frame
	var parts := _build(Town.Look.NIGHT)
	var town: Town = parts[0]
	var pools := _find(town, TownPools) as TownPools
	var cam := Camera2D.new()
	t.root.add_child(cam)
	t.root.add_child(town)
	cam.make_current()
	cam.zoom = Vector2(1.5, 1.5)
	cam.position = Vector2(300, 100)
	cam.force_update_scroll()
	var sp := pools.pool_sprite(0)
	var before := _on_screen(pools, sp)
	cam.position += Vector2(100, 0)
	cam.force_update_scroll()
	var after := _on_screen(pools, sp)
	t.check(is_equal_approx(after.x - before.x, -150.0) and is_equal_approx(after.y, before.y),
		"a pool moves -100 * zoom on screen when the camera moves 100 (moved %s)" % str(after - before))
	t.root.remove_child(town)
	t.root.remove_child(cam)
	cam.free()
	_free(parts)


static func _on_screen(layer: CanvasLayer, sp: Sprite2D) -> Vector2:
	return layer.get_final_transform() * sp.position


static func _band_texture(t) -> void:
	var tex := TownPools.texture()
	var img := tex.get_image()
	var alphas := {}
	for y in img.get_height():
		for x in img.get_width():
			alphas[snappedf(img.get_pixel(x, y).a, 0.001)] = true
	t.check(alphas.size() == TownPools.BAND_ALPHA.size() + 1, "the pool texture has %d hard steps (and nothing smooth)" % alphas.size())
