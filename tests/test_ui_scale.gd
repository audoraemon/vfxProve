extends RefCounted
## UI resolution milestone: integer scaling of the 640x360 frame (Task 1); UiScale, UiIcon and the crisp text sizes (Task 3a).

## The spec's size table: window, k, area, fit.
const TABLE := [
	[Vector2i(1280, 720), 2, Vector2i(640, 360), 1.0],
	[Vector2i(1366, 768), 2, Vector2i(683, 384), 1.0667],
	[Vector2i(1600, 900), 2, Vector2i(800, 450), 1.25],
	[Vector2i(1920, 1080), 3, Vector2i(640, 360), 1.0],
	[Vector2i(1920, 1200), 3, Vector2i(640, 400), 1.1111],
	[Vector2i(2560, 1080), 3, Vector2i(853, 360), 1.0155],
	[Vector2i(3440, 1440), 4, Vector2i(860, 360), 1.0238],
	[Vector2i(2560, 1440), 4, Vector2i(640, 360), 1.0],
	[Vector2i(1024, 600), 1, Vector2i(1024, 600), 1.6667],
]


static func _integer_setting(t) -> void:
	t.check(str(ProjectSettings.get_setting("display/window/stretch/scale_mode")) == "integer", "the frame scales by whole numbers only (crisp at every window size)")


static func _install(t) -> void:
	t.check(str(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items" and str(ProjectSettings.get_setting("display/window/stretch/aspect")) == "keep",
		"the root draws at full resolution (canvas_items) and keeps its aspect in the project file (the expand is applied at run time)")
	t.check(UiScale.window_arg(PackedStringArray(["--window=1366x768"])) == Vector2i(1366, 768), "--window=WxH is read")
	t.check(UiScale.window_arg(PackedStringArray(["--show=tree", "--window=1280X720"])) == Vector2i(1280, 720), "among other args, either case of x")
	t.check(UiScale.window_arg(PackedStringArray(["--window=big", "--window=0x5", "--window=12"])) == Vector2i.ZERO, "a bad or missing size is ignored")
	t.check(UiScale.window_arg(PackedStringArray()) == Vector2i.ZERO, "no argument, no size")
	t.check(UiScale.window_arg(PackedStringArray(["--window=99999x600"])) == Vector2i(UiScale.MAX_WINDOW, 600), "a huge side is clamped to MAX_WINDOW")
	var eff := UiScale.effective(Vector2i(1366, 768))
	t.check(UiScale.EXPAND_ON and eff["k"] == 2 and eff["area"] == Vector2i(683, 384) and eff["offset"] == Vector2i(21, 12) and absf(eff["fit"] - 1.0667) < 1e-4,
		"expanded: the effective layout is the table's (%s)" % [eff])
	var before := UiScale.layout(Vector2i(1920, 1080))
	UiScale.install(Engine.get_main_loop() as SceneTree)  # headless: a no-op
	t.check(UiScale.k() == 1 and UiScale.area() == Vector2(640, 360) and before["k"] == 3, "install does nothing in a headless run")


## Headless runs never expand: the root keeps aspect KEEP and the visible rect stays 640x360, fit 1.
static func _headless_keeps(t) -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	t.check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "headless: UiScale.install leaves the root's aspect at KEEP")
	t.check(Vector2i(root.get_visible_rect().size) == Vector2i(640, 360) and UiScale.fit() == 1.0, "headless: the visible rect is 640x360 and fit 1")


## In every window of the size table the visible world (area / fit, reference px at zoom 1) is within 840x360, and fills the area.
static func _visible_capped(t) -> void:
	for row in TABLE:
		var lay := UiScale.layout(row[0])
		var seen := Vector2(lay["area"]) / float(lay["fit"])
		t.check(seen.x <= 840.0 + 1e-3 and seen.y <= 360.0 + 1e-3, "window %s sees %s reference px, within 840x360" % [row[0], seen])
		t.check(absf(seen.x - 840.0) < 1e-2 or absf(seen.y - 360.0) < 1e-2, "window %s uses its full allowance on one side" % [row[0]])


## No code in src/ writes a camera's zoom directly: every writer goes through CameraShake.zoom_to (the fit applies).
static func _zoom_lint(t) -> void:
	var rx := RegEx.create_from_string("(?<![A-Za-z0-9_])(camera|cam|_camera|_cam|shake|_shake)\\.zoom\\s*=[^=]|\\.zoom\\s*=\\s*Vector2")
	var bad: Array = []
	var seen := 0
	var stack: Array = ["res://src"]
	while not stack.is_empty():
		var dir_path: String = stack.pop_back()
		var dir := DirAccess.open(dir_path)
		for d in dir.get_directories():
			stack.append(dir_path + "/" + d)
		for f in dir.get_files():
			if not f.ends_with(".gd") or f == "camera_shake.gd":
				continue
			seen += 1
			var src := FileAccess.get_file_as_string(dir_path + "/" + f)
			for m in rx.search_all(src):
				bad.append("%s/%s:%d" % [dir_path, f, src.substr(0, m.get_start()).count(char(10)) + 1])
	t.check(seen > 100, "the zoom lint scans src (%d files)" % seen)
	t.check(bad.is_empty(), "no direct camera zoom writes outside camera_shake.gd: %s" % [bad])


## CameraShake: render zoom = logical zoom x fit.
static func _fit(t) -> void:
	var cam := CameraShake.new()
	cam.zoom_to(0.85)
	t.check(cam.zoom == Vector2.ONE * 0.85 and cam.logical_zoom() == cam.zoom.x, "fit 1: zoom is exactly 0.85 and the logical zoom is the same number")
	cam.set_view_fit(1.25)
	t.near(cam.zoom.x, 0.85 * 1.25, 1e-6, "fit 1.25: render zoom is 0.85 x 1.25")
	t.near(cam.logical_zoom(), 0.85, 1e-6, "and the logical zoom is still 0.85")
	cam.zoom_to(0.6)
	t.near(cam.zoom.x, 0.75, 1e-6, "zoom_to under a fit multiplies by it")
	cam.set_view_fit(1.0)
	t.near(cam.zoom.x, 0.6, 1e-6, "back to fit 1 keeps the logical zoom")
	cam.free()


static func _layout_table(t) -> void:
	for row in TABLE:
		var lay := UiScale.layout(row[0])
		t.check(lay["k"] == row[1] and lay["area"] == row[2] and absf(lay["fit"] - row[3]) < 1e-4,
			"layout %s = k %d area %s fit %.4f (got %s)" % [row[0], row[1], row[2], row[3], lay])
	t.check(UiScale.layout(Vector2i(640, 360))["offset"] == Vector2i.ZERO and UiScale.layout(Vector2i(1600, 900))["offset"] == Vector2i(80, 45),
		"the design frame's offset centres 640x360 in the area")
	t.check(UiScale.k() == 1 and UiScale.area() == Vector2(640, 360) and UiScale.design_offset() == Vector2.ZERO,
		"not installed (headless): k 1, area 640x360, no offset")


static func _anchor(t) -> void:
	var r := Rect2(600, 316, 40, 20)
	for where in UiScale.Anchor.values():
		t.check(UiScale.anchor(r, where) == r, "at 640x360 anchor %d is the identity" % where)
	UiScale.set_test_area(Vector2i(800, 450))
	t.check(UiScale.area() == Vector2(800, 450) and UiScale.design_offset() == Vector2(80, 45), "the test area stands in for area() and design_offset()")
	t.check(UiScale.anchor(r, UiScale.Anchor.BOTTOM_RIGHT) == Rect2(760, 406, 40, 20), "bottom right follows the area's corner")
	t.check(UiScale.anchor(r, UiScale.Anchor.CENTRE) == Rect2(680, 361, 40, 20), "centre shifts by half the growth")
	t.check(UiScale.anchor(r, UiScale.Anchor.TOP_LEFT) == r, "top left stays")
	t.check(UiScale.anchor(r, UiScale.Anchor.TOP) == Rect2(680, 316, 40, 20) and UiScale.anchor(r, UiScale.Anchor.BOTTOM) == Rect2(680, 406, 40, 20),
		"top and bottom shift x by half; bottom also y by all")
	t.check(UiScale.anchor(r, UiScale.Anchor.RIGHT) == Rect2(760, 361, 40, 20) and UiScale.anchor(r, UiScale.Anchor.LEFT) == Rect2(600, 361, 40, 20),
		"left and right shift y by half; right also x by all")
	t.check(UiScale.anchor(r, UiScale.Anchor.TOP_RIGHT) == Rect2(760, 316, 40, 20) and UiScale.anchor(r, UiScale.Anchor.BOTTOM_LEFT) == Rect2(600, 406, 40, 20),
		"the other two corners")
	t.check(UiScale.anchor(r, UiScale.Anchor.BOTTOM_RIGHT, Vector2(640, 360)) == r, "an explicit area overrides the test area")
	UiScale.set_test_area(Vector2i(683, 384))
	t.check(UiScale.anchor(Rect2(0, 0, 10, 10), UiScale.Anchor.CENTRE).position == Vector2(21, 12), "odd growth floors to whole units")
	UiScale.clear_test_area()
	t.check(UiScale.area() == Vector2(640, 360), "cleared")


static func _snap_and_frame(t) -> void:
	t.check(UiScale.snap(Vector2(1.3, 2.7)) == Vector2(1, 3), "snap at k 1 rounds to whole units")
	UiScale.apply(UiScale.layout(Vector2i(1920, 1080)))
	t.check(UiScale.k() == 3 and UiScale.snap(Vector2(1.2, 2.5)).is_equal_approx(Vector2(4.0 / 3.0, 2.6666667)), "snap at k 3 rounds to thirds")
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))
	var layer := CanvasLayer.new()
	UiScale.set_test_area(Vector2i(800, 450))
	var frame := UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)
	var blocker := frame.get_parent() as Control
	t.check(blocker.get_parent() == layer and blocker.size == Vector2(800, 450) and blocker.mouse_filter == Control.MOUSE_FILTER_STOP,
		"the blocker fills the area and takes the filter")
	t.check(frame.position == Vector2(80, 45) and frame.size == Vector2(640, 360), "the design frame is 640x360 at the offset")
	t.check(UiScale.backdrop(frame) == Rect2(-80, -45, 800, 450), "the backdrop is the whole area in the frame's coordinates")
	UiScale.clear_test_area()
	layer.free()
	# the frame follows the notifier while in the tree
	var tree := Engine.get_main_loop() as SceneTree
	var layer2 := CanvasLayer.new()
	tree.root.add_child(layer2)
	await tree.process_frame
	var frame2 := UiScale.design_frame(layer2, Control.MOUSE_FILTER_IGNORE)
	t.check(frame2.position == Vector2.ZERO, "at 640x360 the frame is at the origin")
	UiScale.set_test_area(Vector2i(800, 450))
	UiScale.apply(UiScale.layout(Vector2i(1600, 900)))
	t.check(frame2.position == Vector2(80, 45) and (frame2.get_parent() as Control).size == Vector2(800, 450), "a layout change re-places a frame in the tree")
	UiScale.clear_test_area()
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))
	layer2.get_parent().remove_child(layer2)  # out of the tree but alive: only the follower's _exit_tree can have disconnected it
	var connected := false
	for c in UiScale.notifier.changed.get_connections():
		if (c["callable"] as Callable).get_object() is UiScale.FrameFollower:
			connected = true
	layer2.free()
	t.check(not connected, "a frame out of the tree leaves no connection behind")


static func _icons(t) -> void:
	var want := [1, 1, 1, 2, 2, 3]
	for i in 6:
		t.check(UiIcon.multiple(21.0, i + 1) == want[i], "multiple(21) at k %d is %d (got %d)" % [i + 1, want[i], UiIcon.multiple(21.0, i + 1)])
	t.check(UiIcon.multiple(1.0, 1) == 1, "never under one")
	for k in range(1, 7):
		var m := UiIcon.multiple(21.0, k)
		var rect := UiIcon.native_rect(Vector2(100, 100), 21.0, k)
		t.check(is_equal_approx(rect.size.x, 42.0 * m / k) and rect.size.x == rect.size.y, "native_rect side at k %d is 42*%d/k (%s)" % [k, m, rect.size])
		var dev := rect.position * k
		t.check(absf(dev.x - roundf(dev.x)) < 1e-4 and absf(dev.y - roundf(dev.y)) < 1e-4 and rect.size.x * k >= 42.0 - 1e-4,
			"native_rect at k %d sits on whole device px, at least 42 wide" % k)
	t.check(UiIcon.native_rect(Vector2(100, 100), 14.0, 3).size == Vector2(14, 14), "k 3 want 14 = 42 device px = 14 units")
	var img := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(1, 0, 0, 1))
	img.set_pixel(1, 0, Color(0, 1, 0, 0.5))
	var g := UiIcon.grey_image(img)
	var a := g.get_pixel(0, 0)
	var b := g.get_pixel(1, 0)
	t.check(is_equal_approx(a.r, a.g) and is_equal_approx(a.g, a.b) and is_equal_approx(b.r, b.g) and is_equal_approx(b.g, b.b), "grey_image: r = g = b")
	t.check(absf(a.r - 0.299 * 0.85) < 0.01 and absf(b.r - 0.587 * 0.85) < 0.01, "grey_image: luma x 0.85")
	t.check(is_equal_approx(a.a, 1.0) and absf(b.a - 0.5) < 0.01, "grey_image: alpha kept")
	t.check(img.get_pixel(0, 0) == Color(1, 0, 0, 1), "the source image is untouched")
	var tex := ImageTexture.create_from_image(img)
	var gt := UiIcon.grey(tex)
	t.check(gt != null and UiIcon.grey(tex) == gt, "grey() is cached")
	t.check((gt.has_meta("ui_grey") and UiIcon.locked_tint(gt) == Color.WHITE) or (gt == tex and UiIcon.locked_tint(gt) == UiIcon.LOCKED_TINT),
		"a grey copy draws untinted; the stand-in (no image, headless) draws with the old tint")
	t.check(UiIcon.grey(null) == null, "grey(null) is null")
	var pts := UiIcon.round_points(Rect2(10, 20, 14, 14))
	t.check(pts.size() == 32 and UiIcon.round_uvs().size() == 32, "the round clip has 32 segments")
	var ok := true
	for p in pts:
		ok = ok and absf(p.distance_to(Vector2(17, 27)) - 7.0) < 1e-4
	t.check(ok, "every point is on the inscribed circle")
	var small := UiIcon.texture_for("abolition", 1)
	var big := UiIcon.texture_for("abolition", 2)
	t.check(small != null and big != null and small.get_width() == 42 and big.get_width() == 84, "odd m takes the 42 px icon, even m the 84 px icon")
	t.check(UiIcon.texture_for("no_such_power", 1) == null, "an unpainted power has no icon")


static func _crisp(t) -> void:
	for s in [UiTheme.TEXT_S, UiTheme.TEXT_L, UiTheme.TEXT_XL, UiTheme.TEXT_XXL]:
		t.check(s % 11 == 0, "text size %d is a multiple of 11" % s)
	t.check(UiTheme.TEXT_S == 11 and UiTheme.TEXT_L == 22 and UiTheme.TEXT_XL == 33 and UiTheme.TEXT_XXL == 66, "11/22/33/66")
	t.check(UiTheme.LINE_S == 12.0 and UiTheme.LINE_L == 24.0, "line steps 12 and 24")


## The argument index of the width in each outline call, and the call text of every `name(` in `src` joined across lines.
const WIDTH_ARG := {"draw_line": 3, "draw_polyline": 2, "draw_arc": 6, "draw_rect": 3, "draw_dashed_line": 3, "draw_multiline": 2, "draw_polyline_colors": 2, "draw_circle": 4}


## Top-level arguments of the call whose "(" is at `open` in `src`; also the index of its closing ")" in the last slot.
static func _call_args(src: String, open: int) -> Array:
	var args: Array = []
	var depth := 0
	var start := open + 1
	var quote := ""
	var i := open
	while i < src.length():
		var c := src[i]
		if quote != "":
			if c == "\\":
				i += 1
			elif c == quote:
				quote = ""
		elif c == "\"" or c == "'":
			quote = c
		elif c == "(" or c == "[" or c == "{":
			depth += 1
		elif c == ")" or c == "]" or c == "}":
			depth -= 1
			if depth == 0:
				args.append(src.substr(start, i - start).strip_edges())
				args.append(i)
				return args
		elif c == "," and depth == 1:
			args.append(src.substr(start, i - start).strip_edges())
			start = i + 1
		i += 1
	return args


## Whether a width argument is a positive literal or a named constant (UPPER_CASE, maybe dotted: UiTheme.LINE_S).
static func _width_ok(arg: String) -> bool:
	if arg.is_valid_float():
		return arg.to_float() > 0.0
	var rx := RegEx.create_from_string("^([A-Za-z_][A-Za-z0-9_]*\\.)*[A-Z][A-Z0-9_]*$")
	return rx.search(arg) != null


## Every UI outline has an explicit positive width: -1.0 (and a missing width, which defaults to it) is one DEVICE px, a hairline
## that thins out as the scale grows; 1.0 is one UI unit, k device px. Filled draw_rect calls (the default or a literal true) are not outlines.
static func _hairline_lint(t) -> void:
	var dir := DirAccess.open("res://src/game/ui")
	var files := Array(dir.get_files()).filter(func(f): return f.ends_with(".gd"))
	var bad: Array = []
	var seen := 0
	var rx := RegEx.create_from_string("(?<![A-Za-z0-9_])(draw_line|draw_polyline_colors|draw_polyline|draw_arc|draw_rect|draw_dashed_line|draw_multiline)\\(")
	for f in files:
		var src := FileAccess.get_file_as_string("res://src/game/ui/" + f)
		for m in rx.search_all(src):
			var name := m.get_string(1)
			var args := _call_args(src, m.get_end() - 1)
			var n := args.size() - 1
			var line := src.substr(0, m.get_start()).count(char(10)) + 1
			if name == "draw_rect":
				if n < 3 or args[2] == "true":
					continue  # filled (the default, or literally): no outline; a filled flag that is not a literal counts as an outline
			elif name == "draw_circle":
				if n < 4 or args[3] == "true":
					continue  # filled likewise (draw_circle(pos, radius, color, filled, width))
			seen += 1
			var w: int = WIDTH_ARG[name]
			if n <= w or not _width_ok(args[w]):
				bad.append("%s:%d %s" % [f, line, name])
	t.check(seen > 50, "the lint sees the outline calls (%d)" % seen)
	t.check(bad.is_empty(), "every UI outline has an explicit positive width; offenders: %s" % [bad.slice(0, 60)])


## No UI text under 11 units: a numeric literal size in a UiTheme.text / width / wrap / fit call is at least 11; so is a
## `SMALL_PX - n` (the old shrunk size) is gone. Named sizes (SIZE_*, TEXT_*) are all 11 or more (checked below).
static func _text_size_lint(t) -> void:
	var dir := DirAccess.open("res://src/game/ui")
	var files := Array(dir.get_files()).filter(func(f): return f.ends_with(".gd"))
	var bad: Array = []
	var seen := 0
	var rx := RegEx.create_from_string("(?<![A-Za-z0-9_])UiTheme\\.(text|width|wrap|fit)\\(")
	var size_at := {"text": 3, "width": 1, "wrap": 2, "fit": 2}
	var shrunk := RegEx.create_from_string("SMALL_PX\\s*-\\s*[0-9]")
	for f in files:
		if f == "ui_theme.gd":
			continue
		var src := FileAccess.get_file_as_string("res://src/game/ui/" + f)
		for m in rx.search_all(src):
			var args := _call_args(src, m.get_end() - 1)
			var n := args.size() - 1
			var line := src.substr(0, m.get_start()).count(char(10)) + 1
			var idx: int = size_at[m.get_string(1)]
			if n <= idx:
				continue  # the default size (SIZE_BODY, 13)
			seen += 1
			var a: String = args[idx]
			if a.is_valid_int() and a.to_int() < 11:
				bad.append("%s:%d %s" % [f, line, a])
		for m in shrunk.search_all(src):
			bad.append("%s:%d SMALL_PX - n" % [f, src.substr(0, m.get_start()).count(char(10)) + 1])
	t.check(seen > 100, "the text lint sees the sized calls (%d)" % seen)
	t.check(bad.is_empty(), "no UI text is sized under 11 units; offenders: %s" % [bad.slice(0, 40)])
	for named in [UiTheme.SIZE_SMALL, UiTheme.SIZE_BODY, UiTheme.SIZE_BIG, UiTheme.SIZE_TITLE, UiTheme.SIZE_HUGE, UiTheme.TEXT_S, UiTheme.TEXT_L, UiTheme.TEXT_XL, UiTheme.TEXT_XXL]:
		t.check(named >= 11, "the named text size %d is at least 11" % named)


## The digits are drawn from UiTheme's own bitmaps (Pixelify Sans's 5 and 8 both read as S): every digit has its own shape, the same at every place it is
## drawn, each whole multiple of 11 u scales it exactly, and the rest of the string still comes from the pixel font.
static func _digits(t) -> void:
	for medium in [false, true]:
		var rows_of: Dictionary = UiTheme.DIGITS_MEDIUM if medium else UiTheme.DIGITS_SMALL
		var seen := {}
		var all_ok := true
		for d in 10:
			var rows: Array = rows_of[str(d)]
			var key := "".join(PackedStringArray(rows))
			seen[key] = true
			all_ok = all_ok and rows.size() == (9 if medium else 7) and rows.all(func(r): return String(r).length() == (6 if medium else 5))
		t.check(seen.size() == 10 and all_ok, "%s digits: ten different shapes, each %s" % ["medium" if medium else "small", "6 x 9" if medium else "5 x 7"])
	var f := UiTheme.font_for(UiTheme.TEXT_S)
	var f22 := UiTheme.font_for(UiTheme.TEXT_L)
	t.check(f.has_char(48) and f.has_char(57) and f.has_char(65) and f.has_char(44), "a digit font still has the letters and the comma behind it")
	var w11 := f.get_string_size("0123456789", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.TEXT_S).x
	var w22 := f22.get_string_size("0123456789", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.TEXT_L).x
	var w33 := UiTheme.font_for(UiTheme.TEXT_XL).get_string_size("0123456789", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.TEXT_XL).x
	t.check(is_equal_approx(w11, 60.0) and is_equal_approx(w22, 120.0) and is_equal_approx(w33, 180.0), "ten digits advance 60 u at 11, 120 at 22, 180 at 33 (%s %s %s)" % [w11, w22, w33])
	var w13 := UiTheme.width("0123456789", UiTheme.SIZE_BODY)
	t.check(is_equal_approx(w13, 70.0), "and 70 u at 13 u (the medium set, 7 per digit): %s" % w13)
	# A digit has its own bitmap: not the pixel font's. Pixelify's 5 and 8 are the same ink as an S; the bitmap's are not.
	t.check(UiTheme.DIGITS_SMALL["5"] != UiTheme.DIGITS_SMALL["8"] and String(UiTheme.DIGITS_SMALL["5"][0]) == "#####", "the 5 has a flat top bar and the 8 does not")


static func run(t) -> void:
	_integer_setting(t)
	_install(t)
	_headless_keeps(t)
	_visible_capped(t)
	_zoom_lint(t)
	_fit(t)
	_layout_table(t)
	_anchor(t)
	await _snap_and_frame(t)
	_icons(t)
	_crisp(t)
	_hairline_lint(t)
	_text_size_lint(t)
	_digits(t)
