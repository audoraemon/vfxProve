extends RefCounted
## Lighting trial round 3 (DAY and NIGHT only; CURRENT untouched): NIGHT's amber light (the light map replaces the moon
## grade where it falls), the window boost, the sprite rim light, DAY's softer grade.


static func run(t) -> void:
	_night_colour(t)


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
