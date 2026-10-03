extends SceneTree
## Paint the icons of Light of Solaris and Mirrorfold Passage, in the painted icons' manner -- a dark field with one
## glowing subject -- at 84x84 for the Prepare cards and 42x42 for the HUD slots. (make_power_icons.py paints the
## earlier procedural icons; this one needs only Godot.)
##
## usage: godot --headless --path . --script res://tools/dev/make_divine_icons.gd
##        (writes assets/pixellab/icons/<key>.png and hud/<key>.png; re-import afterwards)

const SIZE := 84
const OUT := "res://assets/pixellab/icons/"
## Colour steps per channel: down to a pixel-art palette, as the painted icons are.
const STEPS := 20.0


func _initialize() -> void:
	_save(_solaris(), "solaris")
	_save(_mirror(), "mirror")
	_save(_congregation(), "congregation")
	_save(_madness(), "madness")
	print("wrote ", ProjectSettings.globalize_path(OUT))
	quit()


func _save(img: Image, key: String) -> void:
	for y in SIZE:
		for x in SIZE:
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(roundf(c.r * STEPS) / STEPS, roundf(c.g * STEPS) / STEPS, roundf(c.b * STEPS) / STEPS))
	img.save_png(ProjectSettings.globalize_path(OUT + key + ".png"))
	var small: Image = img.duplicate()
	small.resize(42, 42, Image.INTERPOLATE_LANCZOS)
	small.save_png(ProjectSettings.globalize_path(OUT + "hud/" + key + ".png"))


static func _mix(base: Color, col: Color, a: float) -> Color:
	return base.lerp(col, clampf(a, 0.0, 1.0))


static func _noise(seed_value: int, frequency: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = frequency
	return n


## A pillar of sunfire from a burning sky down onto a dark town's skyline, and the molten ring where it lands.
func _solaris() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var n := _noise(11, 0.09)
	var fine := _noise(5, 0.3)
	for py in SIZE:
		for px in SIZE:
			var x := float(px) - SIZE * 0.5 + 0.5
			var y := float(py) - SIZE * 0.5 + 0.5
			var grain := n.get_noise_2d(px, py) * 0.5 + 0.5
			# A dusk sky, burning where the light breaks through at the top.
			var c := Color(0.07, 0.04, 0.1).lerp(Color(0.2, 0.08, 0.06), clampf((y + 42.0) / 84.0, 0.0, 1.0))
			c = _mix(c, Color(0.95, 0.5, 0.12), exp(-(x * x + (y + 46.0) * (y + 46.0)) / 900.0) * (0.7 + 0.3 * grain))
			# The ground: a dark plain, and a skyline of roofs either side.
			var roof := 22.0 + 5.0 * sin(float(px) * 0.9) * signf(sin(float(px) * 0.37)) + 3.0 * fine.get_noise_1d(px * 3.0)
			if y > roof and absf(x) > 15.0:
				c = Color(0.05, 0.035, 0.05)
			elif y > 26.0:
				c = Color(0.09, 0.06, 0.06)
			# The pillar: wide, white at its heart, gold through its body, orange at its ragged edge.
			var half := 12.5 + 1.6 * n.get_noise_2d(px * 0.4, py * 2.2)
			var foot := 28.0 + 6.0 * sqrt(maxf(1.0 - (x / half) * (x / half), 0.0))
			if y < foot:
				var d := absf(x) / half
				var streak := 0.82 + 0.18 * fine.get_noise_2d(px * 1.4, py * 0.25)
				c = _mix(c, Color(1.0, 0.45, 0.08), clampf((1.25 - d) * 3.0, 0.0, 1.0) * 0.9)
				c = _mix(c, Color(1.0, 0.76, 0.22), clampf((1.0 - d) * 2.4, 0.0, 1.0) * streak)
				c = _mix(c, Color(1.0, 0.98, 0.86), clampf((0.6 - d) * 3.0, 0.0, 1.0))
			# Where it lands: a molten ring on the ground and its light thrown up the pillar's sides.
			var ring := Vector2(x / 24.0, (y - 28.0) / 9.0).length()
			c = _mix(c, Color(1.0, 0.62, 0.15), exp(-pow((ring - 1.0) / 0.16, 2.0)) * 0.95)
			c = _mix(c, Color(1.0, 0.85, 0.45), exp(-pow(ring / 1.5, 2.0)) * 0.35 * float(y > 12.0))
			c = _mix(c, Color(1.0, 0.7, 0.25), exp(-absf(x) / 26.0) * 0.22)
			# Vignette.
			var r := Vector2(x, y).length()
			c = c * clampf(1.3 - (r / 50.0) * (r / 50.0), 0.3, 1.0)
			img.set_pixel(px, py, c)
	return img


## Two thin mirrors lying on a dark street, one above the other, and a walker who steps onto one and is on the other.
func _mirror() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var n := _noise(23, 0.07)
	var centers := [Vector2(-9.0, -15.0), Vector2(9.0, 17.0)]
	for py in SIZE:
		for px in SIZE:
			var x := float(px) - SIZE * 0.5 + 0.5
			var y := float(py) - SIZE * 0.5 + 0.5
			var grain := n.get_noise_2d(px, py) * 0.5 + 0.5
			var c := Color(0.04, 0.06, 0.09).lerp(Color(0.08, 0.13, 0.17), grain)
			# A fold of pale light between the two, like a crease in the air.
			var fold := absf((x + 9.0) * 0.87 - (y + 15.0) * 0.49)
			c = _mix(c, Color(0.45, 0.75, 0.85), exp(-fold * fold / 5.0) * 0.22 * float(y > -15.0 and y < 17.0))
			for k in 2:
				var m: Vector2 = centers[k]
				var e := Vector2((x - m.x) / 27.0, (y - m.y) / 8.5).length()
				# The surface: a ghost of sky and a soft band of light; the rim a hairline, brightest on one side.
				var face := clampf((1.0 - e) * 6.0, 0.0, 1.0)
				c = _mix(c, Color(0.2, 0.36, 0.46), face * 0.75)
				var band := exp(-pow(((x - m.x) * 0.8 + (y - m.y) * 1.6 + 4.0) / 5.0, 2.0))
				c = _mix(c, Color(0.75, 0.95, 1.0), face * band * 0.55)
				var rim := exp(-pow((e - 1.0) / 0.07, 2.0))
				c = _mix(c, Color(0.8, 0.97, 1.0), rim * (0.45 + 0.5 * clampf(-(x - m.x) / 27.0 - (y - m.y) / 17.0, 0.0, 1.0)))
			# The walker: whole on the far mirror, a fading outline on the near one.
			c = _mix(c, Color(0.03, 0.04, 0.06), _figure(x - centers[1].x, y - centers[1].y + 9.0))
			c = _mix(c, Color(0.7, 0.92, 1.0), _figure(x - centers[0].x, y - centers[0].y + 9.0) * 0.5)
			var r := Vector2(x, y).length()
			c = c * clampf(1.3 - (r / 50.0) * (r / 50.0), 0.3, 1.0)
			img.set_pixel(px, py, c)
	return img


## A small standing figure about (0, 0): head, body, legs. Returns its cover 0..1 at (x, y).
static func _figure(x: float, y: float) -> float:
	var head := clampf(1.6 - Vector2(x, y + 7.0).length() / 1.6, 0.0, 1.0)
	var body := float(absf(x) < 2.6 and y > -5.0 and y < 3.0)
	var legs := float(absf(absf(x) - 1.4) < 1.0 and y >= 3.0 and y < 9.0)
	return clampf(head + body + legs, 0.0, 1.0)


## A soft pillar of light over a plaza, with small figures walking in toward it from all sides along threads of gold.
func _congregation() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var n := _noise(31, 0.08)
	for py in SIZE:
		for px in SIZE:
			var x := float(px) - SIZE * 0.5 + 0.5
			var y := float(py) - SIZE * 0.5 + 0.5
			var grain := n.get_noise_2d(px, py) * 0.5 + 0.5
			var c := Color(0.09, 0.08, 0.12).lerp(Color(0.16, 0.13, 0.12), clampf((y + 42.0) / 84.0, 0.0, 1.0))
			c = _mix(c, Color(0.35, 0.3, 0.22), grain * 0.25)
			# The ground: a pale plaza ellipse with faint rings.
			var e := Vector2(x / 36.0, (y - 20.0) / 13.0).length()
			c = _mix(c, Color(0.42, 0.36, 0.26), clampf((1.0 - e) * 4.0, 0.0, 1.0) * 0.6)
			c = _mix(c, Color(1.0, 0.86, 0.5), exp(-pow((e - 0.7) / 0.05, 2.0)) * 0.5 + exp(-pow((e - 0.98) / 0.04, 2.0)) * 0.6)
			# Threads of gold toward the middle.
			var ang := atan2(y - 20.0, x)
			var thread := exp(-pow(sin(ang * 4.0) / 0.08, 2.0)) * clampf((e - 0.25) * 2.0, 0.0, 1.0) * float(e < 1.0)
			c = _mix(c, Color(1.0, 0.9, 0.6), thread * 0.5)
			# The pillar: soft, white at heart, gold at its edge, fading upward.
			var half := 7.0 + 2.0 * clampf((y + 10.0) / 40.0, 0.0, 1.0)
			var d := absf(x) / half
			var up := clampf((y + 40.0) / 60.0, 0.0, 1.0)
			if y < 22.0:
				c = _mix(c, Color(1.0, 0.8, 0.4), clampf((1.3 - d) * 2.0, 0.0, 1.0) * 0.55 * up)
				c = _mix(c, Color(1.0, 0.95, 0.8), clampf((0.7 - d) * 2.5, 0.0, 1.0) * 0.85 * up)
			# The icon: a small ring and point above.
			var ring := Vector2(x, y + 30.0).length()
			c = _mix(c, Color(1.0, 0.92, 0.65), exp(-pow((ring - 4.0) / 0.9, 2.0)) + exp(-ring * ring / 1.5))
			# Figures on the plaza, walking in.
			for k in 6:
				var a := TAU * float(k) / 6.0 + 0.4
				var fx_ := cos(a) * 24.0
				var fy := 20.0 + sin(a) * 9.0
				c = _mix(c, Color(0.08, 0.07, 0.1), _figure((x - fx_) * 1.3, (y - fy + 5.0) * 1.3))
				c = _mix(c, Color(1.0, 0.85, 0.45), exp(-(Vector2(x - fx_, y - fy - 10.0).length_squared()) / 1.2))
			var r := Vector2(x, y).length()
			c = c * clampf(1.3 - (r / 50.0) * (r / 50.0), 0.3, 1.0)
			img.set_pixel(px, py, c)
	return img


## A dark bloom of purple-red veins opening round a staring eye, with faces in the petals turned the wrong ways.
func _madness() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var n := _noise(47, 0.1)
	var fine := _noise(53, 0.35)
	for py in SIZE:
		for px in SIZE:
			var x := float(px) - SIZE * 0.5 + 0.5
			var y := float(py) - SIZE * 0.5 + 0.5
			var grain := n.get_noise_2d(px, py) * 0.5 + 0.5
			var c := Color(0.06, 0.03, 0.07).lerp(Color(0.14, 0.05, 0.1), grain)
			var r := Vector2(x, y).length()
			var ang := atan2(y, x)
			# Petals: five lobes of dark red with lighter veins.
			var lobe := 0.5 + 0.5 * cos(ang * 5.0 + fine.get_noise_2d(px, py) * 1.5)
			var petal := clampf((26.0 + 12.0 * lobe - r) / 3.0, 0.0, 1.0)
			c = _mix(c, Color(0.42, 0.08, 0.2), petal * 0.9)
			var vein := exp(-pow(sin(ang * 5.0 + r * 0.12) / 0.07, 2.0)) * petal * float(r > 8.0)
			c = _mix(c, Color(0.75, 0.2, 0.4), vein * 0.8)
			var rim := exp(-pow((26.0 + 12.0 * lobe - r) / 1.3, 2.0))
			c = _mix(c, Color(0.9, 0.35, 0.55), rim * 0.7)
			# Tendrils reaching out from the bloom into the dark.
			var tendril := exp(-pow(sin(ang * 9.0 + 0.3 * sin(r * 0.3)) / 0.05, 2.0)) * clampf((r - 30.0) / 6.0, 0.0, 1.0) * clampf((44.0 - r) / 6.0, 0.0, 1.0)
			c = _mix(c, Color(0.55, 0.12, 0.3), tendril * 0.7)
			# The eye: a pale almond with a dark pupil and a red glint.
			var eye := clampf((1.0 - Vector2(x / 11.0, y / 5.5).length()) * 6.0, 0.0, 1.0)
			c = _mix(c, Color(0.95, 0.9, 0.98), eye)
			var pupil := clampf((1.0 - Vector2(x / 4.0, y / 4.0).length()) * 6.0, 0.0, 1.0)
			c = _mix(c, Color(0.1, 0.02, 0.06), pupil)
			c = _mix(c, Color(1.0, 0.3, 0.4), exp(-(Vector2(x - 1.0, y - 1.0).length_squared()) / 1.5))
			c = c * clampf(1.3 - (r / 50.0) * (r / 50.0), 0.3, 1.0)
			img.set_pixel(px, py, c)
	return img
