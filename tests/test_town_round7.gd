extends RefCounted
## Lighting round 7 (DAY and NIGHT only; CURRENT untouched): no glints on the roofs. DAY's sun glow was cut into steps by
## a dither fixed to the screen, so every pan slid the roofs under it and their pixels flickered; NIGHT's grade saved the
## art's lone orange eave highlights (keep_lit) as bright specks on the dark roofs.


static func run(t) -> void:
	_sun_smooth(t)
	_lone_glow(t)
	_day_lamps_dark(t)


static func _src(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## The sun glow is a smooth screen blend: no screen-locked dither, no steps.
static func _sun_smooth(t) -> void:
	var src := _src("res://src/game/town/town_grade.gdshader")
	var at := src.find("if (sun > 0.0)")
	var block := src.substr(at, src.find("}", at) - at)
	t.check(at >= 0 and not block.contains("bayer4") and not block.contains("floor("),
		"the sun glow is smooth: no screen-fixed dither or steps for the roofs to slide under")


## NIGHT drops the glow of a lone warm pixel (an eave highlight) that is not a window: it takes the moon like the roof
## round it. DAY and CURRENT never set it (the shader's default, off).
static func _lone_glow(t) -> void:
	var src := _src("res://src/environment/art/structure_sprite.gdshader")
	t.check(src.contains("uniform bool lone_glow_off = false;"), "the sprite shader's lone-glow cut is off by default")
	t.check(bool(TownLook.sprite_params(Town.Look.NIGHT).get("lone_glow_off", false)),
		"NIGHT dims lone warm pixels that are not windows")
	t.check(not TownLook.sprite_params(Town.Look.DAY).has("lone_glow_off")
		and not TownLook.sprite_params(Town.Look.CURRENT).has("lone_glow_off"), "DAY and CURRENT keep every glow")


## DAY's lamps are unlit: a building beside a flickering torch takes no light from it (the flicker blinked on its roof),
## while a spell's moving light still reaches it. CURRENT and NIGHT (lamp_glow) still take the torch.
static func _day_lamps_dark(t) -> void:
	var lf := LightField.new()
	var g := Vector2(100, 100)
	lf.add_static(g + Vector2(20, 0), 80.0, Color(1.0, 0.6, 0.2), 1.0, 1.0)
	var sigs := {}
	for i in 20:
		lf._process(0.037)
		sigs[lf.sample_signature(g, 24.0, 4.0, false)] = true
	t.check(sigs.size() == 1 and lf.sample(g, false) == Color(0, 0, 0, 1) and lf.sample_dir(g, false) == Vector2.ZERO,
		"without static lights a building beside a flickering torch is steady and unlit")
	t.check(lf.sample(g).r > 0.0, "with static lights (CURRENT, NIGHT) the torch still lights it")
	lf.pulse(g, 50.0, Color.WHITE, 1.0, 1.0)
	lf._process(0.0)
	t.check(lf.sample(g, false).r > 0.0, "a spell's moving light still reaches it in DAY")
	lf.free()
	var src := _src("res://src/environment/structure.gd")
	t.check(src.contains("lights.sample(center(), lamp_glow)") and src.contains("SIG_DIR_STEPS, lamp_glow)"),
		"buildings drop the static lights when the lamps are unlit (DAY)")
