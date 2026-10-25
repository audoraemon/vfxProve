extends RefCounted
## The DAY and NIGHT colour grade and the light map: pools counted from the static lights and the lit windows,
## LightField untouched, layer order under the glow, the buffer locked to the world, a faint light map by day.


static func run(t) -> void:
	_params(t)
	_layers_and_counts(t)
	_lightfield_untouched(t)
	_day(t)
	_capital_lamps(t)
	_calm(t)
	await _world_space(t)
	_band_texture(t)
	await _one_draw(t)


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
		t.check(grade.layer < Battlefield.GLOW_LAYER, "grade layer %d < glow layer %d" % [grade.layer, Battlefield.GLOW_LAYER])
		var pn: Node = pools
		t.check(not (pn is CanvasItem) and not (pn is CanvasLayer), "the pools draw nothing on the screen: they are a light map")
		t.check(pools.buffer is SubViewport and pools.canvas().get_parent() == pools.buffer, "the pools draw into the light buffer")
		var gm := grade.rect.material as ShaderMaterial
		t.check(gm.get_shader_parameter("light_tex") == pools.light_texture() and float(gm.get_shader_parameter("light_gain")) > 0.0,
			"the grade multiplies the world by the light buffer")
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
		t.check(pools.pool_count() == listed.size(), "one pool per listed light")
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
	t.check(pools != null and pools.pool_count() == listed.size(), "one pool per listed light, decor lamps included")
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
		t.check(idx >= 0 and pools.pool_visible(idx), "the lamp's pool shows while it stands")
		var drawn := pools.redraws
		fallen.hit(999.0, &"stone")
		t.check(TownPools.lamp_pool(fallen).is_empty(), "a lamp knocked down has no pool")
		t.check(idx >= 0 and not pools.pool_visible(idx), "the live pool hides at once when the lamp falls (an event, no polling)")
		t.check(pools.redraws == drawn, "hiding schedules a redraw, it does not draw inside the call")
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
	t.check(src.contains("clamp(mix(g, c, ember), 0.0, 1.0)"), "the shader clamps its output as grade_pixel() does")
	_shoulder(t)


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
	t.check(_find(town, TownGrade) != null and _find(town, TownPools) != null, "DAY has a grade and a light map")
	t.check(TownLook.light_gain(Town.Look.DAY) < TownLook.light_gain(Town.Look.NIGHT) * 0.5, "DAY's light map is faint beside NIGHT's")
	_free(parts)
	var cur := _build(Town.Look.CURRENT)
	t.check((cur[0] as Town).look_nodes().is_empty(), "CURRENT has no grade and no pools")
	_free(cur)


## The light buffer follows the camera: half the view's size, and a pool's place in it moves by -dx * zoom / 2 when the
## camera moves by dx.
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
	pools.follow_view()
	var view: Vector2 = t.root.get_visible_rect().size
	t.check(pools.buffer.size == Vector2i(view * TownPools.BUFFER_SCALE), "the buffer is half the view (%s for %s)" % [str(pools.buffer.size), str(view)])
	var before := pools.buffer.canvas_transform * pools.pool_position(0)
	cam.position += Vector2(100, 0)
	cam.force_update_scroll()
	pools.follow_view()
	var after := pools.buffer.canvas_transform * pools.pool_position(0)
	var k: float = float(pools.buffer.size.x) / view.x
	t.check(is_equal_approx(after.x - before.x, -150.0 * k) and is_equal_approx(after.y, before.y),
		"a pool moves -100 * zoom * %.2f in the buffer when the camera moves 100 (moved %s)" % [k, str(after - before)])
	t.root.remove_child(town)
	t.root.remove_child(cam)
	cam.free()
	_free(parts)


static func _on_screen(layer: CanvasLayer, pos: Vector2) -> Vector2:
	return layer.get_final_transform() * pos


## The pool texture falls off smoothly (many levels, brightest at the centre, none at the edge); the grade cuts it into
## dithered steps per world pixel: a 4x4 block averages back to the light, and a pixel only takes whole steps.
static func _band_texture(t) -> void:
	var tex := TownPools.texture()
	var img := tex.get_image()
	var alphas := {}
	for y in img.get_height():
		for x in img.get_width():
			alphas[snappedf(img.get_pixel(x, y).a, 0.001)] = true
	t.check(alphas.size() > 20, "the pool texture falls off smoothly (%d levels)" % alphas.size())
	var mid := img.get_pixel(TownPools.TEX.x / 2, TownPools.TEX.y / 2).a
	var half := img.get_pixel(TownPools.TEX.x * 3 / 4, TownPools.TEX.y / 2).a
	t.check(mid > 0.95 and half > 0.2 and half < mid and img.get_pixel(0, 0).a == 0.0, "brightest at the centre, none at the corner")
	for m: float in [0.1, 0.37, 0.5, 0.83]:
		var sum := 0.0
		var whole := true
		for y in 4:
			for x in 4:
				var v := TownGrade.light_step(m, Vector2i(x + 8, y - 4), 6.0)
				sum += v
				whole = whole and is_equal_approx(v * 6.0, roundf(v * 6.0))
		t.check(absf(sum / 16.0 - m) < 0.04 and whole, "a 4x4 block of dithered light %.2f averages %.3f in whole steps" % [m, sum / 16.0])
	var src := FileAccess.get_file_as_string("res://src/game/town/town_grade.gdshader")
	t.check(src.contains("0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5"), "the shader's Bayer matrix is light_step()'s")


## All pools are one draw node: a single CanvasItem under the layer, additive and nearest filtered, whose scale snaps to
## 1/48 steps; a window's pool hides on its building's destruction and shows again on restore; the strength is re-read
## ten times a second (not every frame); a pool outside the view is skipped.
static func _one_draw(t) -> void:
	var parts := _build(Town.Look.NIGHT)
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var pools := _find(town, TownPools) as TownPools
	var drawers := 0
	for c in pools.buffer.get_children():
		if c is CanvasItem:
			drawers += 1
	t.check(drawers == 1 and pools.canvas() is Node2D, "all %d pools draw on one node" % pools.pool_count())
	var mat := pools.canvas().material as CanvasItemMaterial
	t.check(mat != null and mat.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "the draw node is additive")
	var even := true
	for i in pools.pool_count():
		var k := pools._sz[i].x / float(TownPools.TEX.x)
		even = even and absf(k / TownPools.SCALE_STEP - roundf(k / TownPools.SCALE_STEP)) < 0.001 and pools._sz[i].x == roundf(pools._sz[i].x)
	t.check(even, "every pool's scale is a whole step of 1/48 (whole-pixel size)")
	var win := -1
	for p in pools._pools:
		if p.structure != null:
			win = p.i
			break
	if win >= 0:
		var st: Structure = pools._pools[win].structure
		t.check(pools.pool_visible(win), "a window pool shows while its building stands")
		st.destroy(st.center(), &"smite")
		t.check(not pools.pool_visible(win), "a window pool hides when its building is destroyed")
		st.restore()
		t.check(pools.pool_visible(win), "a window pool shows again when its building is restored")
	# The flicker is re-read at 10 Hz: frames inside one step leave the colours alone.
	var first := -1
	for p in pools._pools:
		if p.light == null:
			first = p.i
			break
	if first >= 0:
		pools._process(0.0)
		var a0 := pools.pool_alpha(first)
		pools._process(0.03)
		t.check(pools.pool_alpha(first) == a0, "the strength does not change between flicker steps")
		var moved := false
		for step in 40:
			pools._process(TownPools.FLICKER_STEP)
			moved = moved or absf(pools.pool_alpha(first) - a0) > 0.01
		t.check(moved, "the strength flickers over time")
	# Culling: with a view that holds no pool nothing is drawn; with a view over the first pool that one is.
	var old_view := Structure.view
	Structure.view = Rect2(1.0e6, 1.0e6, 10, 10)
	pools._process(0.0)
	t.check(pools.drawn_indices().is_empty(), "a view with no pool in it draws none")
	Structure.view = Rect2(pools.pool_position(0) - Vector2(5, 5), Vector2(10, 10))
	pools._process(0.0)
	var in_view := pools.drawn_indices()
	t.check(in_view.size() >= 1 and in_view.size() < pools.pool_count() and 0 in in_view, "a view over one pool draws it and not them all (%d of %d)" % [in_view.size(), pools.pool_count()])
	Structure.view = old_view
	_free(parts)


## DAY's shoulder: the brightest pixel is pulled down (keeping its hue order), mid-tones are untouched (their luminance is
## under the knee), and with the shoulder at 0 the output is the grade alone.
static func _shoulder(t) -> void:
	var day := TownLook.grade(Town.Look.DAY)
	t.check(float(day.get("shoulder", 0.0)) > 0.0, "DAY has a shoulder")
	var flat := day.duplicate()
	flat["shoulder"] = 0.0
	var bright := Color(0.97, 0.93, 0.80)
	var mid := Color(0.34, 0.30, 0.24)
	var hi_s := TownGrade.grade_pixel(bright, day)
	var hi_f := TownGrade.grade_pixel(bright, flat)
	t.check(hi_s.r + hi_s.g + hi_s.b < hi_f.r + hi_f.g + hi_f.b - 0.05, "the shoulder pulls the brightest pixel down (%s vs %s)" % [str(hi_s), str(hi_f)])
	t.check(hi_s.r >= hi_s.g and hi_s.g >= hi_s.b, "the brightest pixel keeps its warm hue order")
	t.check(TownGrade.grade_pixel(mid, day).is_equal_approx(TownGrade.grade_pixel(mid, flat)), "mid-tones are unchanged by the shoulder")
