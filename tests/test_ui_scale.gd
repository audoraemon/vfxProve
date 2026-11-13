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
	layer2.get_parent().remove_child(layer2)
	layer2.free()
	var connected := false
	for c in UiScale.notifier.changed.get_connections():
		if (c["callable"] as Callable).get_object() is UiScale.FrameFollower:
			connected = true
	t.check(not connected, "a freed frame leaves no connection behind")


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


static func run(t) -> void:
	_integer_setting(t)
	_layout_table(t)
	_anchor(t)
	await _snap_and_frame(t)
	_icons(t)
	_crisp(t)
