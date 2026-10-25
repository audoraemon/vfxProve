extends RefCounted
## Lighting trial round 2 (DAY and NIGHT only). A: DAY's clean colour, no global orange; the sun's tone split on lit
## content; NIGHT untouched by it.


static func run(t) -> void:
	_day_colour(t)


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
