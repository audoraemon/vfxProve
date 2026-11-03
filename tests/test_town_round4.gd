extends RefCounted
## Lighting trial round 4 (DAY and NIGHT only; CURRENT untouched), after the user's playtest: NIGHT is dark between its
## lights (small pools, a smooth crossfade from the moon grade, no dither).


const R2 := preload("res://tests/test_town_round2.gd")


static func run(t) -> void:
	_night_pools(t)


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
