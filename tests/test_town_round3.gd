extends RefCounted
## Lighting trial round 3 (DAY and NIGHT only; CURRENT untouched): NIGHT's amber light (the light map replaces the moon
## grade where it falls), the window boost, the sprite rim light, DAY's softer grade.


const R2 := preload("res://tests/test_town_round2.gd")


static func run(t) -> void:
	_night_colour(t)
	_sprite_params(t)


static func _src(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## NIGHT's light mix is on and DAY's (and CURRENT's) off: the shader's defaults leave the old formula.
static func _night_colour(t) -> void:
	var night := TownLook.light_mix(Town.Look.NIGHT)
	t.check(TownLook.light_mix(Town.Look.DAY).is_empty() and TownLook.light_mix(Town.Look.CURRENT).is_empty(),
		"only NIGHT mixes its light (DAY and CURRENT keep the shader's defaults)")
	t.check(float(night.light_replace) > 0.5 and float(night.light_mono) > 0.0 and float(night.light_knee) > 0.0,
		"NIGHT's lamplight replaces the moon grade, lights the luminance and has a shoulder (%s)" % str(night))
	var warm := TownLook.light_warm(Town.Look.NIGHT)
	t.check(warm.x > warm.y and warm.y > warm.z * 1.5, "NIGHT's light is amber (%s)" % str(warm))
	var src := _src("res://src/game/town/town_grade.gdshader")
	for u: String in ["light_replace = 0.0", "light_mono = 0.0", "light_floor = 0.0", "light_boost = 1.0", "light_knee = 0.0",
			"light_pow = 1.0"]:
		t.check(src.contains("uniform float " + u), "the grade's %s by default (off)" % u)
	t.check(float(TownLook.bloom(Town.Look.NIGHT).threshold) > float(night.light_knee),
		"NIGHT's glow threshold sits over the lamplit ground's brightest, so the pools do not smear")


## The sprite shader's look settings (SpriteView.look_params): none in CURRENT (no parameter is ever set, so the shader
## runs its defaults and CURRENT's art is untouched), NIGHT's hot windows; teardown puts them back.
static func _sprite_params(t) -> void:
	t.check(TownLook.sprite_params(Town.Look.CURRENT).is_empty(), "CURRENT has no sprite look settings")
	t.check(float(TownLook.sprite_params(Town.Look.NIGHT).get("window_hot", 0.0)) > 0.0, "NIGHT's windows burn hot")
	t.check(TownLook.window_pool(Town.Look.NIGHT) > 1.0 and TownLook.window_pool(Town.Look.DAY) == 1.0,
		"NIGHT's windows throw a brighter fan on the ground")
	var src := _src("res://src/environment/art/structure_sprite.gdshader")
	t.check(src.contains("uniform float window_hot = 0.0;") and src.contains("if (window_hot > 0.0)"),
		"the sprite shader's hot windows are off by default")
	for look: Town.Look in [Town.Look.CURRENT, Town.Look.DAY, Town.Look.NIGHT]:
		var parts: Array = R2._build(look)
		var want := TownLook.sprite_params(look)
		t.check(SpriteView.look_params == want, "%d: the build sets the look's sprite settings" % look)
		var s := _a_sprite(parts[1])
		var v := SpriteView.new().setup(s.sprite, Vector2(-32, -16), Vector2(32, -16))
		var m := v.material as ShaderMaterial
		var ok := true
		for k: String in ["window_hot", "rim_amt", "rim_col", "rim_moon"]:
			var got = m.get_shader_parameter(k)
			ok = ok and (got == null if not want.has(k) else got == want[k])
		t.check(ok, "%d: a sprite view carries exactly the look's settings (none in CURRENT)" % look)
		v.free()
		R2._free(parts)
		t.check(SpriteView.look_params.is_empty(), "%d: teardown puts the sprite settings back" % look)


static func _a_sprite(env: EnvironmentField) -> Structure:
	for s in env.structures():
		if s.sprite is Dictionary and SpriteArt.window_mask(s.sprite) != null:
			return s
	return null
