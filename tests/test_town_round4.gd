extends RefCounted
## Lighting trial round 4 (DAY and NIGHT only; CURRENT untouched), after the user's playtest: NIGHT is dark between its
## lights (small pools, a smooth crossfade from the moon grade, no dither), the props are drawn at the house art's scale
## with small flames, and no extra crown of torches on the towers.


const R2 := preload("res://tests/test_town_round2.gd")


static func run(t) -> void:
	_night_pools(t)
	_night_dark_between(t)
	_proportions(t)
	_day_unlit(t)
	_day_props_sunlit(t)


static func _src(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## NIGHT's light map: a smooth falloff (no dither steps), a crossfade capped toward 1, a pool texture that reaches near
## zero before its edge, and small pools: a lantern about a cell, a lamp or torch about two.
static func _night_pools(t) -> void:
	var mix := TownLook.light_mix(Town.Look.NIGHT)
	t.check(float(mix.get("light_steps", 16.0)) == 0.0, "NIGHT's light map is a smooth falloff, not dithered steps")
	var src := _src("res://src/game/town/town_grade.gdshader")
	t.check(src.contains("1.0 - exp(-m * light_gain)") and src.contains("g = mix(g, lit, a);"),
		"the grade crossfades to lamplight by 1 - exp(-light * gain): overlapping pools add up toward a cap")
	t.check(src.contains("if (light_steps <= 0.0)"), "light_steps 0 turns the dither off")
	var img := TownPools.texture().get_image()
	var y := TownPools.TEX.y / 2
	var near_edge := img.get_pixel(int(TownPools.TEX.x * 0.95), y).a
	t.check(near_edge < 0.05, "a pool fades to near zero before its edge (%.3f at 90%% of its radius)" % near_edge)
	var cell := Iso.radius_to_screen(1.0).x
	var l: Dictionary = TownLookDecor.LIGHT
	t.check(float(l[TownLookDecor.Prop.LANTERN].radius) <= 1.5 * cell and float(l[TownLookDecor.Prop.LAMP].radius) <= 2.0 * cell
		and float(l[TownLookDecor.Prop.TORCH].radius) <= 2.0 * cell and TownPools.TORCH_MAX <= 2.0 * cell,
		"pools are small: a lantern at most 1.5 cells, a lamp or torch at most 2")
	for k: TownLookDecor.Prop in l:
		t.check(float(l[k].alpha) <= 1.2, "prop %d's pool is not over-driven (alpha %.2f; round 3's 3-4 lit whole squares)" % [k, l[k].alpha])
	t.check(TownPools.FACE_ALPHA <= 0.3 and TownPools.WALL_H <= 1.5, "a light warms the near wall face only, faintly")
	var parts: Array = R2._build(Town.Look.NIGHT)
	var town: Town = parts[0]
	var pools: TownPools = null
	for n in town.look_nodes():
		if n is TownPools:
			pools = n
	t.check(pools != null and (pools as TownPools).buffer.use_hdr_2d, "the light buffer is float: overlaps add past 1 before the cap")
	var windows_faced := 0
	for p in TownPools.pools_for(town):
		if p.get("structure") != null and not p.get("look_decor", false) and not (p.get("face", PackedVector2Array()) as PackedVector2Array).is_empty():
			windows_faced += 1
	t.check(windows_faced == 0, "a window's fan does not light the whole front (%d did)" % windows_faced)
	R2._free(parts)


## The town's ground between the lights stays dark: under half of the walled town lies inside any pool's lit core (70%
## of its radius, where the crossfade passes about a quarter).
static func _night_dark_between(t) -> void:
	var parts: Array = R2._build(Town.Look.NIGHT)
	var town: Town = parts[0]
	var pools := TownPools.pools_for(town)
	var rect := City.current().town()
	var lit := 0
	var all := 0
	var g := rect.position
	while g.y < rect.end.y:
		g.x = rect.position.x
		while g.x < rect.end.x:
			var p := Iso.ground_to_screen(g)
			all += 1
			for q in pools:
				var r: float = float(q.radius) * 0.7
				var d: Vector2 = p - (q.pos as Vector2)
				if (d.x * d.x) / (r * r) + (d.y * d.y) / (r * r * 0.25) <= 1.0:
					lit += 1
					break
			g.x += 0.5
		g.y += 0.5
	var share := float(lit) / maxf(all, 1)
	t.check(share < 0.5, "NIGHT: %.0f%% of the walled town lies in a pool's lit core (the rest stays moonlit)" % (share * 100.0))
	R2._free(parts)


## The props at the house art's scale: a street lamp a little over a person's height, a lantern a short post, small
## flames, lamps every 5-6 cells, and no prop torches on a tower or gatehouse top.
static func _proportions(t) -> void:
	var sp: Dictionary = TownLookDecor.SPRITES
	t.check((sp[TownLookDecor.Prop.LAMP].size as Vector2i).y <= 24 and (sp[TownLookDecor.Prop.LANTERN].size as Vector2i).y <= 16,
		"a street lamp stands at most 24 px, a lantern 16 px (the art's stood 41 and 38)")
	t.check(TownLookDecor.LAMP_STEP >= 5.0 and TownLookDecor.LAMP_STEP <= 6.0, "a street lamp every 5-6 cells")
	t.check(_src("res://src/game/town/town_look_decor.gd").contains("BAND_Y + ROW_FLAME_SMALL * CELL), cell)])")
		and not _src("res://src/game/town/town_look_decor.gd").contains("BAND_Y + ROW_FLAME * CELL), cell)])"),
		"every prop torch burns the small flame (the art's own torch flames' size)")
	for look: Town.Look in [Town.Look.NIGHT, Town.Look.DAY]:
		var parts: Array = R2._build(look)
		var town: Town = parts[0]
		var on_tops := 0
		for p in town.look_decor.props:
			var h: Structure = p.host
			if p.prop == TownLookDecor.Prop.TORCH and h != null and h.kind != Structure.Kind.CASTLE_WALL:
				on_tops += 1
		t.check(on_tops == 0, "%d: no prop torches on the towers' and gatehouses' tops (their painted braziers glow; %d)" % [look, on_tops])
		R2._free(parts)


## DAY: nothing is lit. No light map (no pools, the grade reads none), no window boost, every prop unlit: no flame and no
## lit glass is drawn (the posts keep their dark glass).
static func _day_unlit(t) -> void:
	t.check(TownLook.light_gain(Town.Look.DAY) == 0.0 and TownLook.window_boost(Town.Look.DAY) == 0.0, "DAY: no lamplight, no window boost")
	var parts: Array = R2._build(Town.Look.DAY)
	var town: Town = parts[0]
	var pools_node := false
	for n in town.look_nodes():
		pools_node = pools_node or n is TownPools
	t.check(not pools_node, "DAY builds no light map")
	var ld := town.look_decor
	var lit_rects := 0
	for n in ld.prop_nodes():
		var rects: Array[Rect2] = (n as TownLookDecor.PropNode).rects
		for i in range(1, rects.size(), 2):
			lit_rects += 1 if rects[i].position.y >= TownLookDecor.BAND_Y and rects[i].position.y < TownLookDecor.BAND_Y + TownLookDecor.ROW_BRACKET * TownLookDecor.CELL else 0
	t.check(ld.props.size() > 0 and lit_rects == 0, "DAY: %d props stand unlit (%d flames or lit glasses drawn)" % [ld.props.size(), lit_rects])
	t.check(ld.lights().is_empty(), "DAY: no prop sends light")
	var glows := 0
	var torches := 0
	for st in (parts[1] as EnvironmentField).structures():
		if st.kind == Structure.Kind.TORCH:
			torches += 1
			glows += 1 if is_instance_valid(st._glow) else 0
	t.check(not Structure.lamp_glow and torches > 0 and glows == 0, "DAY: the town's own %d torches and lamps throw no ground glow" % torches)
	R2._free(parts)
	t.check(Structure.lamp_glow, "teardown lights the lamps again")
	for look: Town.Look in [Town.Look.CURRENT, Town.Look.NIGHT]:
		var p2: Array = R2._build(look)
		t.check(Structure.lamp_glow, "%d: the town's lamps glow" % look)
		R2._free(p2)


## Round 6: DAY's lamp posts and lanterns are drawn from their own sunlit sprites (not near-black iron): the post's wood is a
## warm brown, its left edge lit, its glass shows a pale sky, and the shader no longer squares a DAY post's colour. NIGHT's
## sprites (the atlas rows at the SPRITES entries) keep their colours.
static func _day_props_sunlit(t) -> void:
	var img := TownLookDecor.atlas().get_image()
	var lamp: Dictionary = TownLookDecor.SPRITES[TownLookDecor.Prop.LAMP]
	var at: Vector2i = Vector2i(lamp.at) + TownLookDecor.DAY_SHIFT
	var lit := img.get_pixel(at.x, at.y + 10)
	var shade := img.get_pixel(at.x + 1, at.y + 10)
	t.check(lit.get_luminance() > 0.35 and lit.r > lit.b * 1.5, "DAY lamp post: lit wood is a warm brown (%s)" % lit)
	t.check(shade.get_luminance() < lit.get_luminance(), "DAY lamp post: a darker right side, the lit left edge reads")
	var g := Rect2i(lamp.glass)
	var pane := img.get_pixel(at.x + g.position.x + 1, at.y + g.end.y - 2)
	t.check(pane.b > pane.r and pane.get_luminance() > 0.6, "DAY lamp glass shows a pale sky, not a black pane (%s)" % pane)
	var night := img.get_pixel(int(lamp.at.x), int(lamp.at.y) + 10)
	t.check(night.is_equal_approx(TownLookDecor.COL_POST), "NIGHT's post sprite keeps its colour")
	var ld_src := FileAccess.get_file_as_string("res://src/game/town/town_look_decor.gdshader")
	t.check(ld_src.contains("sun_lit > 0.5 ? COLOR : t * COLOR"), "DAY props take their colour once (no squared sprite)")
