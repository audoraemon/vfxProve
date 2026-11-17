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
	var eff := UiScale.layout(Vector2i(1366, 768))
	t.check(eff["k"] == 2 and eff["area"] == Vector2i(683, 384) and eff["offset"] == Vector2i.ZERO and absf(eff["frame"] - 1.0667) < 1e-4 and absf(eff["fit"] - 1.0667) < 1e-4,
		"the layout of a 1366x768 window is the table's (%s)" % [eff])
	var before := UiScale.layout(Vector2i(1920, 1080))
	UiScale.install(Engine.get_main_loop() as SceneTree)  # headless: a no-op
	t.check(UiScale.k() == 1 and UiScale.area() == Vector2(640, 360) and before["k"] == 3, "install does nothing in a headless run")


## Headless runs never expand: the root keeps aspect KEEP and the visible rect stays 640x360, fit 1.
static func _headless_keeps(t) -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	t.check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "headless: UiScale.install leaves the root's aspect at KEEP")
	t.check(Vector2i(root.get_visible_rect().size) == Vector2i(640, 360) and UiScale.fit() == 1.0, "headless: the visible rect is 640x360 and fit 1")
	# A missed size_changed (maximize ending mid-change): the watcher's test sees a window size other than the last one followed.
	var kept := UiScale._followed_size
	UiScale._followed_size = root.size
	t.check(not UiScale.needs_follow(root), "watcher: no re-follow while the window keeps the size last followed")
	UiScale._followed_size = Vector2i(697, 360)
	t.check(UiScale.needs_follow(root), "watcher: a window size other than the one followed asks for a re-follow")
	UiScale._followed_size = kept


## In every window of the size table the visible world (area / fit, reference px at zoom 1) is within 840x360, and fills the area.
static func _visible_capped(t) -> void:
	for row in TABLE:
		var lay := UiScale.layout(row[0])
		var cam := CameraShake.new()
		cam.set_view_fit(float(lay["fit"]))
		cam.zoom_to(1.0)
		var seen := Vector2(lay["area"]) / cam.zoom.x  # what a real camera of that fit shows at logical zoom 1
		t.check(seen.x <= 840.0 + 1e-3 and seen.y <= 360.0 + 1e-3, "window %s: a real camera sees %s reference px, within 840x360" % [row[0], seen])
		t.check(absf(seen.x - 840.0) < 1e-2 or absf(seen.y - 360.0) < 1e-2, "window %s uses its full allowance on one side" % [row[0]])
		cam.zoom_to(0.6)
		t.check((Vector2(lay["area"]) / cam.zoom.x * 0.6).x <= 840.0 + 1e-3, "window %s: the cap holds at another zoom" % [row[0]])
		cam.free()


## The pattern for a camera zoom write that bypasses zoom_to().
static func _zoom_regex() -> RegEx:
	return RegEx.create_from_string("(?<![A-Za-z0-9_])(camera|cam|_camera|_cam|shake|_shake)\\.zoom(\\.[xy])?\\s*([-+*/]?=)[^=]|\\.zoom\\s*[-+*/]?=\\s*Vector2|tween_property\\([^)]*\"zoom(:[xy])?\"|\\.set\\(\"zoom(:[xy])?\"|set_deferred\\(\"zoom(:[xy])?\"")


## The matcher itself: every bad form is caught, a zoom_to( call and a read are not (a lint that matches nothing passes for ever).
static func _zoom_lint_fixture(t) -> void:
	var rx := _zoom_regex()
	var bad_lines := [
		"cam.zoom = Vector2.ONE * 2.0", "_camera.zoom = Vector2(1, 1)", "bf.camera.zoom *= 1.1", "camera.zoom += Vector2.ONE",
		"cam.zoom.x = 0.5", "camera.zoom.y -= 0.1", "foo.zoom = Vector2.ONE",
		"tween.tween_property(_camera, \"zoom\", Vector2.ONE, 1.0)", "tween.tween_property(cam, \"zoom:x\", 2.0, 1.0)",
		"tween.tween_property(cam, \"zoom:y\", 2.0, 1.0)", "cam.set(\"zoom\", Vector2.ONE)",
		"cam.set_deferred(\"zoom\", Vector2.ONE)"]
	for l: String in bad_lines:
		t.check(rx.search(l) != null, "zoom lint catches: %s" % [l])
	var ok_lines := ["cam.zoom_to(0.8)", "var z := cam.zoom.x", "if cam.zoom.x == 1.0:", "_camera.logical_zoom()", "tween.tween_method(_camera.zoom_to, 1.0, 2.0, 1.0)",
		"var zoom := 1.0", "zoom = 2.0"]
	for l: String in ok_lines:
		t.check(rx.search(l) == null, "zoom lint ignores: %s" % [l])


## No code in src/ writes a camera's zoom directly: every writer goes through CameraShake.zoom_to (the fit applies).
static func _zoom_lint(t) -> void:
	var rx := _zoom_regex()
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
	t.check(UiScale.layout(Vector2i(640, 360))["offset"] == Vector2i.ZERO and UiScale.layout(Vector2i(1600, 900))["offset"] == Vector2i.ZERO
		and UiScale.layout(Vector2i(1600, 900))["frame"] == 1.25,
		"the design frame fills an area of 16:9 (scaled up, no offset)")
	t.check(UiScale.layout(Vector2i(2560, 1080))["frame"] == 1.0 and UiScale.layout(Vector2i(1920, 1200))["offset"] == Vector2i(0, 20),
		"the frame is limited by the shorter axis and centred on the other (a 640x400 area: y 20)")
	t.check(UiScale.layout(Vector2i(2560, 1080))["offset"] == Vector2i(106, 0), "an 853x360 area centres the 640x360 page at x 106")
	t.check(UiScale.k() == 1 and UiScale.area() == Vector2(640, 360) and UiScale.design_offset() == Vector2.ZERO,
		"not installed (headless): k 1, area 640x360, no offset")


static func _anchor(t) -> void:
	var r := Rect2(600, 316, 40, 20)
	for where in UiScale.Anchor.values():
		t.check(UiScale.anchor(r, where) == r, "at 640x360 anchor %d is the identity" % where)
	UiScale.set_test_area(Vector2i(800, 450))
	t.check(UiScale.area() == Vector2(800, 450) and UiScale.design_offset() == Vector2.ZERO and UiScale.frame_scale() == 1.25,
		"the test area stands in for area(), design_offset() and frame_scale(): 800x450 is a 1.25x page at the origin")
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
	UiScale.set_test_area(Vector2i(960, 495))  # a 1.375x page: 880x495 at x 40
	var frame := UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)
	var blocker := frame.get_parent() as Control
	t.check(blocker.get_parent() == layer and blocker.size == Vector2(960, 495) and blocker.mouse_filter == Control.MOUSE_FILTER_STOP,
		"the blocker fills the area and takes the filter")
	t.check(frame.position == Vector2(40, 0) and frame.size == Vector2(640, 360) and frame.scale == Vector2(1.375, 1.375),
		"the design frame is 640x360, scaled 1.375x and centred (40, 0)")
	var bd := UiScale.backdrop(frame)
	t.check(bd == Rect2(Vector2(-40, 0) / 1.375, Vector2(960, 495) / 1.375), "the backdrop is the whole area in the frame's coordinates")
	# What the frame's transform makes of that backdrop is the whole area, edge to edge (the real drawing check, with the scale in it).
	var xf := Transform2D(0.0, frame.scale, 0.0, frame.position)
	var on_screen := xf * bd
	t.check(on_screen.position.is_equal_approx(Vector2.ZERO) and on_screen.size.is_equal_approx(Vector2(960, 495)), "drawn through the frame's scale the backdrop covers the area exactly (%s)" % on_screen)
	# The page is centred: equal margins left and right of the scaled 640x360, none above or below at this aspect.
	var page := xf * Rect2(Vector2.ZERO, Vector2(640, 360))
	t.check(is_equal_approx(page.position.x, 960.0 - page.end.x) and page.position.y == 0.0 and is_equal_approx(page.end.y, 495.0),
		"the scaled page is centred: %s in 960x495" % page)
	# Frame-local click mapping: a point on the screen reaches gui_input as frame coordinates.
	for design in [Vector2(0, 0), Vector2(320, 180), Vector2(639, 359), Vector2(100.5, 40.25)]:
		var screen: Vector2 = xf * design
		t.check((xf.affine_inverse() * screen).is_equal_approx(design) and page.has_point(screen), "a click at the page's %s is at %s on the screen and maps back" % [design, screen])
	# A different aspect: a tall area is limited by the width and the page sits in the middle vertically; under 640x360 it never shrinks.
	UiScale.set_test_area(Vector2i(800, 800))
	t.check(UiScale.frame_scale() == 1.25 and UiScale.design_offset() == Vector2(0, 175), "an 800x800 area: 1.25x, centred vertically at y 175")
	UiScale.set_test_area(Vector2i(500, 300))
	t.check(UiScale.frame_scale() == 1.0, "an area under 640x360 does not shrink the page")
	UiScale.set_test_area(Vector2i(960, 495))
	UiScale.clear_test_area()
	layer.free()
	# the frame follows the notifier while in the tree
	var tree := Engine.get_main_loop() as SceneTree
	var layer2 := CanvasLayer.new()
	tree.root.add_child(layer2)
	await tree.process_frame
	var frame2 := UiScale.design_frame(layer2, Control.MOUSE_FILTER_IGNORE)
	t.check(frame2.position == Vector2.ZERO, "at 640x360 the frame is at the origin")
	UiScale.set_test_area(Vector2i(960, 495))
	UiScale.apply(UiScale.layout(Vector2i(1920, 990)))
	t.check(frame2.position == Vector2(40, 0) and frame2.scale == Vector2(1.375, 1.375) and (frame2.get_parent() as Control).size == Vector2(960, 495),
		"a layout change re-places and re-scales a frame in the tree")
	# The engine's own hit test: a click on the screen reaches the scaled frame's gui_input in the page's coordinates.
	frame2.mouse_filter = Control.MOUSE_FILTER_STOP
	var got: Array[Vector2] = []
	frame2.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			got.append((e as InputEventMouseButton).position))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(40.0 + 100.0 * 1.375, 40.0 * 1.375)  # the page's (100, 40)
	press.global_position = press.position
	tree.root.push_input(press)
	t.check(got.size() == 1 and got[0].is_equal_approx(Vector2(100, 40)), "the engine maps a screen click into the scaled frame's coordinates (%s)" % [got])
	UiScale.clear_test_area()
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))
	layer2.get_parent().remove_child(layer2)  # out of the tree but alive: only the follower's _exit_tree can have disconnected it
	var connected := false
	for c in UiScale.notifier.changed.get_connections():
		if (c["callable"] as Callable).get_object() is UiScale.FrameFollower:
			connected = true
	layer2.free()
	t.check(not connected, "a frame out of the tree leaves no connection behind")


## A mouse event at the screen point where `frame`'s local point `local` is drawn (through the frame's own scale and offset), pushed into the tree as the engine would.
static func _press_at(tree: SceneTree, frame: Control, local: Vector2, pressed := true, motion := false) -> void:
	var at := frame.get_global_transform_with_canvas() * local
	var e: InputEventMouse
	if motion:
		e = InputEventMouseMotion.new()
	else:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = pressed
		e = b
	e.position = at
	e.global_position = at
	tree.root.push_input(e)


## Scaled frames, real input: on a 960x495 area (a 1.375x page at x 40) a click or drag at the screen point where a button or card is drawn reaches it,
## through the engine's own hit test (buttons, the board's tabs and cards, the upgrade screen, the skill tree's nodes, the options bars and their drag).
static func _scaled_input(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	UiScale.set_test_area(Vector2i(960, 495))
	var up := UpgradesScreen.new()
	tree.root.add_child(up)
	up.setup(DescendState.new())
	var got := []
	up.action.connect(func(what: String) -> void: got.append(what))
	await tree.process_frame
	_press_at(tree, up._ui, UpgradesScreen.BACK_RECT.get_center())
	t.check(got == ["back"], "scaled input: a click where the upgrades screen draws Board lands on it (%s)" % [got])
	_press_at(tree, up._ui, UpgradesScreen.BACK_RECT.get_center() + Vector2(0.0, -40.0))
	t.check(got == ["back"], "scaled input: and a click above it hits nothing (%s)" % [got])
	up.free()

	var board := MissionBoard.new()
	board.dev = true
	tree.root.add_child(board)
	board.setup(SaveFile.new(), "warning")
	await tree.process_frame
	_press_at(tree, board._ui, MissionBoard.tab_rect(2).get_center())
	t.check(board.tier == 3, "scaled input: a click where the board draws the Wrath tab opens it (%d)" % board.tier)
	var picks: Array[String] = []
	board.action.connect(func(what: String) -> void: picks.append(what))
	_press_at(tree, board._ui, MissionBoard.card_rect(1, board.missions().size()).get_center())
	t.check(picks == ["pick"], "scaled input: a click where the board draws a card picks it (%s)" % [picks])
	board.free()

	var slot := GodSlot.make(1, "ruin", 7)
	slot.tier = 1
	var tree_screen := SkillTreeScreen.new().setup(slot, {})
	tree.root.add_child(tree_screen)
	await tree.process_frame
	var backs := []
	tree_screen.action.connect(func(what: String) -> void: backs.append(what))
	_press_at(tree, tree_screen._ui, SkillTreeScreen.BACK_RECT.get_center())
	t.check(backs == ["back"], "scaled input: a click where the skill tree draws Back leaves (%s)" % [backs])
	var node := TreeWheel.node_at(1, 0)
	_press_at(tree, tree_screen._ui, node)
	t.check(tree_screen.selected_key() != "", "scaled input: a click where the skill tree draws a node selects it (%s)" % tree_screen.selected_key())
	tree_screen.free()

	var layer := CanvasLayer.new()
	tree.root.add_child(layer)
	var frame := UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)
	var settings := Settings.new()
	var panel := OptionsPanel.new().setup(settings, "user://test_ui_scale_settings.cfg")
	frame.add_child(panel)
	await tree.process_frame
	var key := String(OptionsPanel.ROWS[0][0])
	var bar := panel.bar_rect(0)
	_press_at(tree, frame, Vector2(bar.position.x + bar.size.x * 0.25, bar.get_center().y))
	var low := settings.level(key)
	_press_at(tree, frame, Vector2(bar.position.x + bar.size.x * 0.75, bar.get_center().y), true, true)
	var high := settings.level(key)
	_press_at(tree, frame, Vector2(bar.position.x + bar.size.x * 0.75, bar.get_center().y), false)
	t.check(absf(low - 0.25) <= 0.1 and absf(high - 0.75) <= 0.1, "scaled input: a press and a drag along the options bar set the level where it is drawn (%.2f then %.2f)" % [low, high])
	var dim := UiScale.backdrop_of(panel)
	var covered: Rect2 = frame.get_global_transform_with_canvas() * dim
	t.check(covered.position.is_equal_approx(Vector2.ZERO) and covered.size.is_equal_approx(Vector2(960, 495)), "scaled input: the options dimmer, drawn through the frame's scale, covers the area (%s)" % covered)
	layer.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_ui_scale_settings.cfg"))
	UiScale.clear_test_area()


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


## The outline calls in `src` that have no explicit positive width, as "name:line"; `seen` counts the outline calls looked at.
static func _hairline_offenders(src: String, seen: Array) -> Array:
	var bad: Array = []
	var rx := RegEx.create_from_string("(?<![A-Za-z0-9_])(draw_line|draw_polyline_colors|draw_polyline|draw_arc|draw_rect|draw_dashed_line|draw_multiline|draw_circle)\\(")
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
		seen[0] += 1
		var w: int = WIDTH_ARG[name]
		if n <= w or not _width_ok(args[w]):
			bad.append("%s:%d" % [name, line])
	return bad


## The lint itself: one bad sample per drawing call is caught, the good forms are not (a lint that matches nothing passes for ever).
static func _hairline_fixture(t) -> void:
	var bad_calls := [
		"draw_line(a, b, c)", "draw_line(a, b, c, -1.0)", "draw_polyline(p, c)", "draw_polyline(p, c, -1.0)",
		"draw_polyline_colors(p, cs)", "draw_arc(c, r, 0.0, 1.0, 16, col)", "draw_arc(c, r, 0.0, 1.0, 16, col, -1.0)",
		"draw_rect(r, c, false)", "draw_rect(r, c, false, -1.0)", "draw_rect(r, c, filled)",
		"draw_dashed_line(a, b, c)", "draw_multiline(pts, c)",
		"draw_circle(c, r, col, false)", "draw_circle(c, r, col, false, -1.0)", "draw_circle(c, r, col, filled)"]
	for l: String in bad_calls:
		var seen := [0]
		t.check(_hairline_offenders(l, seen).size() == 1, "hairline lint catches: %s" % [l])
	var ok_calls := [
		"draw_line(a, b, c, 1.0)", "draw_line(a, b, c, UiTheme.LINE_W)", "draw_polyline(p, c, 2.0)", "draw_arc(c, r, 0.0, 1.0, 16, col, 1.0)",
		"draw_rect(r, c)", "draw_rect(r, c, true)", "draw_rect(r, c, false, 1.0)",
		"draw_circle(c, r, col)", "draw_circle(c, r, col, true)", "draw_circle(c, r, col, false, 1.0)",
		"draw_circle(c + Vector2(1, 2), r, Color(1, 0, 0, 0.5), false, LINE_W)"]
	for l: String in ok_calls:
		var seen := [0]
		t.check(_hairline_offenders(l, seen).is_empty(), "hairline lint accepts: %s" % [l])


## Every UI outline has an explicit positive width: -1.0 (and a missing width, which defaults to it) is one DEVICE px, a hairline
## that thins out as the scale grows; 1.0 is one UI unit, k device px. Filled draw_rect / draw_circle calls are not outlines.
static func _hairline_lint(t) -> void:
	var dir := DirAccess.open("res://src/game/ui")
	var files := Array(dir.get_files()).filter(func(f): return f.ends_with(".gd"))
	var bad: Array = []
	var seen := [0]
	for f in files:
		var src := FileAccess.get_file_as_string("res://src/game/ui/" + f)
		for o in _hairline_offenders(src, seen):
			bad.append("%s %s" % [f, o])
	t.check(seen[0] > 50, "the lint sees the outline calls (%d)" % seen[0])
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


## The capitals Pixelify Sans draws alike (B as 8/G, G as B, E as C, H as W, Z as 2) are bitmaps too, at 11 u and its multiples.
static func _letters(t) -> void:
	var seen := {}
	var ok := true
	for k in UiTheme.LETTERS_SMALL:
		var rows: Array = UiTheme.LETTERS_SMALL[k]
		seen["".join(PackedStringArray(rows))] = true
		ok = ok and rows.size() == 7 and rows.all(func(r): return String(r).length() == 5)
	for d in 10:
		seen["".join(PackedStringArray(UiTheme.DIGITS_SMALL[str(d)]))] = true
	t.check(seen.size() == UiTheme.LETTERS_SMALL.size() + 10 and ok, "the confusable capitals are 5 x 7 and differ from each other and from every digit")
	t.check(String(UiTheme.LETTERS_SMALL["B"][0]) == "####." and String(UiTheme.LETTERS_SMALL["Z"][0]) == "#####" and String(UiTheme.LETTERS_SMALL["Z"][6]) == "#####", "B has a square shoulder and Z a flat top and foot (not a 2)")
	var base := UiTheme.base_font()
	for size in [11, 22, 33]:
		var f := UiTheme.digit_font(size)
		var every := true
		var same := true
		for k in UiTheme.LETTERS_SMALL:
			var c := String(k).unicode_at(0)
			every = every and f.has_char(c)
			same = same and absf(f.get_char_size(c, size).x - base.get_char_size(c, size).x) <= (0.0 if size == 11 else 1.0) + 0.01
		t.check(every, "the %d u face draws B, E, G, H and Z itself" % size)
		t.check(same, "and each advances as the pixel font's own at %d u (within 1 u above 11 u: whole advances only)" % size)
	t.check(is_equal_approx(UiTheme.font_for(UiTheme.SIZE_BODY).get_char_size(66, UiTheme.SIZE_BODY).x, base.get_char_size(66, UiTheme.SIZE_BODY).x), "the legacy 13-21 sizes keep the font's own B")
	t.check(UiTheme.font_for(UiTheme.TEXT_S).has_char(65), "a letter that is not replaced still comes from the font behind")
	# The face's own space must draw nothing, not an empty rect from its atlas: that rect breaks the canvas batch at every space in every string (+86 draw calls in the Warning, -4 fps).
	for size in [11, 22]:
		var face := UiTheme.digit_font(size)
		var native := UiTheme.DIGIT_SMALL_NATIVE
		t.check(face.get_glyph_texture_idx(0, Vector2i(native, 0), 32) == -1, "the %d u face's space has no texture, so it cannot break a batch" % size)


## Full-rect nodes follow a resize (user report 2026-11-16: maximized, the mission HUD sat in a 320x135 corner). set_anchors_preset keeps
## the offsets that hold the node's current size, so a node made full-rect while 0 wide inside a 640x360 parent kept offsets of -640/-360
## and shrank to (area - 640x360) on every resize. set_anchors_and_offsets_preset zeroes them.
static func _full_rect_follows(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	# The HUD's own shape: a CanvasLayer straight under a viewport (the root in the game; a SubViewport here, which a test can resize).
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	tree.root.add_child(vp)
	var layer := CanvasLayer.new()
	vp.add_child(layer)
	var c := Control.new()
	layer.add_child(c)
	var old := Control.new()
	layer.add_child(old)
	await tree.process_frame  # the layer knows its 640x360 area, as the HUD's does when Mission sets it up
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # as Hud.setup does, after the add
	old.set_anchors_preset(Control.PRESET_FULL_RECT)  # the old call, for the contrast
	vp.size = Vector2i(960, 495)
	await tree.process_frame
	t.check(c.size == Vector2(960, 495), "a full-rect node added at 640x360 fills 960x495 after the resize (%s)" % c.size)
	t.check(old.size != Vector2(960, 495), "the old call left it short (%s): the check would see the bug" % old.size)
	vp.free()


## No full-rect anchoring in src keeps stale offsets: set_anchors_preset(Control.PRESET_FULL_RECT) is the bug above.
static func _full_rect_lint(t) -> void:
	var bad: Array = []
	var seen := 0
	var stack: Array = ["res://src"]
	while not stack.is_empty():
		var dir_path: String = stack.pop_back()
		var dir := DirAccess.open(dir_path)
		for d in dir.get_directories():
			stack.append(dir_path + "/" + d)
		for f in dir.get_files():
			if not f.ends_with(".gd"):
				continue
			seen += 1
			var src := FileAccess.get_file_as_string(dir_path + "/" + f)
			if src.contains("set_anchors_preset(Control.PRESET_FULL_RECT"):
				bad.append("%s/%s" % [dir_path, f])
	t.check(seen > 100, "the full-rect lint scans src (%d files)" % seen)
	t.check(bad.is_empty(), "full-rect anchoring uses set_anchors_and_offsets_preset: %s" % [bad])


## The TextureRects in `src` (a {path: source} map) that are given a texture or a size before their expand mode (2026-11-17, 18d32435:
## under the default EXPAND_KEEP_SIZE the texture is the minimum size, so a size set first was clamped up to the texture's: WorldView's
## picture, area x k px, came out k times the area whenever the view was made after the window).
static func texture_rect_offenders(sources: Dictionary) -> Array:
	var bad: Array = []
	var made := RegEx.create_from_string("(?m)^\\s*(?:var\\s+)?([A-Za-z_][A-Za-z0-9_.]*)\\s*:?=\\s*TextureRect\\.new\\(\\)")
	for path: String in sources:
		var src: String = sources[path]
		for m in made.search_all(src):
			var v := m.get_string(1)
			var after := src.substr(m.get_end())
			var mode := after.find(v + ".expand_mode")
			for prop in [".texture =", ".size =", ".custom_minimum_size =", ".set_size("]:
				var at := after.find(v + prop)
				if at >= 0 and (mode < 0 or at < mode):
					bad.append("%s: %s%s before %s.expand_mode" % [path, v, prop, v])
	return bad


static func _texture_rect_fixture(t) -> void:
	var old := "\tdisplay = TextureRect.new()\n\tdisplay.texture = vp.get_texture()\n\tdisplay.size = area\n\tdisplay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n"
	var fixed := "\tdisplay = TextureRect.new()\n\tdisplay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE\n\tdisplay.texture = vp.get_texture()\n\tdisplay.size = area\n"
	t.check(texture_rect_offenders({"old": old}).size() == 2, "the TextureRect lint sees the old WorldView order (texture and size before the expand mode)")
	t.check(texture_rect_offenders({"fixed": fixed}).is_empty(), "and passes the fixed order")


static func _texture_rect_lint(t) -> void:
	var sources := {}
	var stack: Array = ["res://src"]
	while not stack.is_empty():
		var dir_path: String = stack.pop_back()
		var dir := DirAccess.open(dir_path)
		for d in dir.get_directories():
			stack.append(dir_path + "/" + d)
		for f in dir.get_files():
			if f.ends_with(".gd"):
				var src := FileAccess.get_file_as_string(dir_path + "/" + f)
				if src.contains("TextureRect.new()"):
					sources["%s/%s" % [dir_path, f]] = src
	var bad := texture_rect_offenders(sources)
	t.check(sources.size() >= 1, "the TextureRect lint scans src (%d files make one)" % sources.size())
	t.check(bad.is_empty(), "every TextureRect in src has its expand mode before its texture and size: %s" % [bad])


## A design frame made after the window (every screen the real game opens once it is maximized) is the area at k 2 and k 3, and follows
## a later resize: the blocker fills the area, the 640x360 page is scaled by frame_scale() and centred.
static func _frame_after_resize(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for window: Vector2i in [Vector2i(1920, 991), Vector2i(2560, 1369), Vector2i(1517, 803)]:
		UiScale.apply(UiScale.layout(window))
		var layer := CanvasLayer.new()
		tree.root.add_child(layer)
		var frame := UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)
		await tree.process_frame  # the suite's root joins the tree a frame late; the frame's follower connects on entering it
		var first := true
		for now: Vector2i in [window, Vector2i(1392, 711), Vector2i(2560, 1369), Vector2i(1517, 803)]:
			if not first:
				UiScale.apply(UiScale.layout(now))
			first = false
			var area := UiScale.area()
			var blocker := frame.get_parent() as Control
			t.check(blocker.size == area and blocker.position == Vector2.ZERO and frame.position == UiScale.design_offset()
				and frame.scale == Vector2.ONE * UiScale.frame_scale(),
				"a design frame made at %s, now %s: fills area %s, page at %s x%.3f (%s, %s x%.3f)" % [window, now, area, UiScale.design_offset(),
				UiScale.frame_scale(), blocker.size, frame.position, frame.scale.x])
		layer.free()
	# A frame made off the tree, then a resize, then added: placed for the window it joins in.
	UiScale.apply(UiScale.layout(Vector2i(1920, 991)))
	var off := CanvasLayer.new()
	var made := UiScale.design_frame(off, Control.MOUSE_FILTER_STOP)
	UiScale.apply(UiScale.layout(Vector2i(2560, 1369)))
	tree.root.add_child(off)
	t.check((made.get_parent() as Control).size == UiScale.area() and made.position == UiScale.design_offset(),
		"a design frame made off the tree at 1920x991 and added after a resize to 2560x1369 fills the new area (%s)" % (made.get_parent() as Control).size)
	off.free()
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))


static func run(t) -> void:
	_texture_rect_fixture(t)
	_texture_rect_lint(t)
	await _frame_after_resize(t)
	_integer_setting(t)
	_install(t)
	_headless_keeps(t)
	_visible_capped(t)
	_zoom_lint(t)
	await _full_rect_follows(t)
	_full_rect_lint(t)
	_zoom_lint_fixture(t)
	_fit(t)
	_layout_table(t)
	_anchor(t)
	await _snap_and_frame(t)
	await _scaled_input(t)
	_icons(t)
	_crisp(t)
	_hairline_fixture(t)
	_hairline_lint(t)
	_text_size_lint(t)
	_digits(t)
	_letters(t)
