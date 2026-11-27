extends SceneTree
## Real-path probe (2026-11-17 sweep): runs the game (game.tscn) in its window and checks, all the time, that every world view and every
## UI layer agrees with the UI area, whatever order the window and the views were made in. Not a test: a windowed dev tool, driven by
## tools/dev/real_path.ps1 (OS-level input and window changes).
##
##   powershell -File tools/dev/real_path.ps1 -Out DIR -Size max|WxH|none [-Extra --window=1920x1080] -Mode route -Route main|god|hunt
##   powershell -File tools/dev/real_path.ps1 -Out DIR -Size max -Mode flow [-Resize]
## (the script runs Godot.exe --path . -s res://tools/dev/real_path_probe.gd -- --sweep-out=DIR plus --flow-test, or --dev --sweep-route=NAME
## --sweep-chan=DIR). Routes: main (title, board, Tier 1/3/5 missions, pause, legend, options, Restart, Change powers, Results Replay, the
## DEV tab's Capital night), god (Endless Night: slots, god select, hub, Skill Tree, Remembrance day and night, Descend, Abandon), hunt (the
## DEV tab's Hunts). A route run plays on its own save, settings and god files (user://test_real_path*), never the player's.
## 125% DPI maximized is 1920x991 (k 2); --window=1920x1080 with -Size none is borderless k 3; 1392x711 is k 1.
##
## Checks (each logged as one "CHECK ok|FAIL" line in DIR/probe.log):
## - layout: the root's content size is the area; every WorldView's display is the area at the origin (expand mode IGNORE), its viewport
##   is area x k px with the area as its 2D override; every camera in it has the current fit; the HUD is the area.
## - oversize: no visible Control drawn in the root is bigger than the area (the k x picture of 18d32435).
## - pixel: a magenta mark drawn in the world at known ground points shows on the window where the HUD's world transform puts it
##   (tags, outlines and clicks all use that transform), after every screen change, layout change, pan and zoom.
## - mouse: after an OS cursor move, the root's mouse is the cursor's window px through the root's stretch (what clicks pick with).
## With --flow-test the game's own FLOW walks every route (board, tiers, night and wishes, the Lantern Hunt, campaign and ending, endless,
## Capital, tours, First Taste);
## with --sweep-route the probe drives a route with OS input through the channel DIR (cmd_N.txt / ack_N.txt) to real_path.ps1.

const MARK_LAYER := 200
const FRACS := [Vector2(0.5, 0.5), Vector2(0.3, 0.35), Vector2(0.7, 0.62)]

var out_dir := ""
var chan := ""
var route := ""
var _log: FileAccess
var _game: Node
var _t := 0.0
var _frame := 0
var _key := ""  # the screen state last captured
var _settle := -1
var _pix_due := 0.0
var _busy := false
var _cmd := 0
var checks := 0
var fails := 0
var _flagged := {}
var _shot := 0
var _layout_frames := -1
var _driving := false
var _new_ui := false  # a CanvasLayer, screen or WorldView joined the tree this frame
var _new_key := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sweep-out="):
			out_dir = a.substr(12)
		elif a.begins_with("--sweep-chan="):
			chan = a.substr(13)
		elif a.begins_with("--sweep-route="):
			route = a.substr(14)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_log = FileAccess.open(out_dir.path_join("probe.log"), FileAccess.WRITE)
	UiScale.notifier.changed.connect(func(_l: Dictionary) -> void: _layout_frames = 12)
	node_added.connect(_on_node_added)
	if "--flow-test" in OS.get_cmdline_user_args():
		change_scene_to_file.call_deferred("res://scenes/game.tscn")  # FLOW keeps its own save, settings and gods
	else:
		_start_on_own_files.call_deferred()


const ROUTE_SAVE := "user://test_real_path.cfg"
const ROUTE_SETTINGS := "user://test_real_path_settings.cfg"
const ROUTE_GOD := "user://test_real_path_god_"


## A route run plays on files of its own (fresh each run), never the player's save, settings or gods.
func _start_on_own_files() -> void:
	for f in [ROUTE_SAVE, ROUTE_SETTINGS] + [1, 2, 3].map(func(i: int) -> String: return GodSlot.path(i, ROUTE_GOD)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var g: Game = load("res://scenes/game.tscn").instantiate()
	g.save_path = ROUTE_SAVE
	g.settings_path = ROUTE_SETTINGS
	g.god_base = ROUTE_GOD
	root.add_child(g)
	current_scene = g


## A UI layer, a screen or a world view joined the tree: check the layout on the next frame, however soon the flow moves on.
func _on_node_added(n: Node) -> void:
	if n is CanvasLayer or n is WorldView or (n is Control and n.name == "Blocker"):
		_new_ui = true


func say(s: String) -> void:
	var line := "[%7.2f] %s" % [_t, s]
	print(line)
	if _log != null:
		_log.store_line(line)
		_log.flush()


func check(ok: bool, what: String) -> bool:
	checks += 1
	if not ok:
		fails += 1
	say("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
	return ok


## Logged once per distinct message (a bad layout would otherwise log every 20 frames).
func flag(what: String) -> void:
	if _flagged.has(what):
		return
	_flagged[what] = true
	check(false, what)


func _process(delta: float) -> bool:
	_t += delta
	_frame += 1
	if _game == null:
		for n in root.get_children():
			if n is Game:
				_game = n
				say("game up, window %s area %s k %d" % [root.size, UiScale.area(), UiScale.k()])
				if route != "":
					_drive.call_deferred()
		return false
	if not is_instance_valid(_game):
		return false
	if _frame % 20 == 0:
		_structure()
	var key := _state_key()
	if _new_ui and not _busy:
		_new_ui = false
		_quick_shot.call_deferred(key)
	if key != _key:
		_key = key
		_settle = 20
	if _settle > 0:
		_settle -= 1
		if _settle == 0 and not _busy:
			_after_change.call_deferred("screen " + key)
	if _layout_frames > 0:
		_layout_frames -= 1
		if _layout_frames == 0 and not _busy:
			_after_change.call_deferred("layout %s area %s k %d" % [root.size, UiScale.area(), UiScale.k()])
	if not _driving and _t > _pix_due and not _busy and _live_view() != null:
		_pix_due = _t + 4.0
		_pixel_check.call_deferred("periodic")
	return false


func _state_key() -> String:
	var s := "%s" % Game.Screen.keys()[_game.screen]
	var p = _game.get("_pause")
	if p != null and is_instance_valid(p):
		s += "+pause"
		if p.has_method("options_open") and p.options_open():
			s += "+options"
	var m = _game.get("_mission")
	if m != null and is_instance_valid(m):
		if m.has_method("legend_open") and m.legend_open():
			s += "+legend"
		if m.has_method("in_intro") and m.in_intro():
			s += "+intro"
	var sn = _game.get("_screen_node")
	if sn != null and is_instance_valid(sn):
		s += ":" + sn.get_class() + ("" if sn.get_script() == null else "/" + str(sn.get_script().get_global_name()))
		if sn.has_method("options_open") and sn.options_open():
			s += "+options"
	return s


## The layout checked at once and the frame captured (once per state): FLOW moves on within a frame or two.
func _quick_shot(key: String) -> void:
	await RenderingServer.frame_post_draw
	_structure(true)
	if key != _new_key and not _busy:
		_new_key = key
		_save(root.get_texture().get_image(), "new " + key)


func _after_change(why: String) -> void:
	if _busy:
		return
	_busy = true
	say("== " + why)
	_structure(true)
	await _capture(why)
	_busy = false
	if _live_view() != null:
		await _pixel_check(why.get_slice(" ", 0))


# --- structure -------------------------------------------------------------------------------------------------------------------

func _structure(log_ok := false) -> void:
	var area := UiScale.area()
	var k := UiScale.k()
	var ok := root.content_scale_size == Vector2i(area)
	if not ok:
		flag("root content size %s != area %s (window %s)" % [root.content_scale_size, area, root.size])
	for wv: WorldView in root.find_children("*", "WorldView", true, false):
		if not wv.is_inside_tree() or wv.is_queued_for_deletion():
			continue
		var d := wv.display
		var r := d.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, d.size)
		var where := "%s" % wv.get_path()
		if r.position.distance_to(Vector2.ZERO) > 0.01 or (r.size - area).abs().x > 0.01 or (r.size - area).abs().y > 0.01:
			flag("%s display rect %s != area %s (window %s)" % [where, r, area, root.size])
			ok = false
		if d.expand_mode != TextureRect.EXPAND_IGNORE_SIZE or d.stretch_mode != TextureRect.STRETCH_SCALE:
			flag("%s display modes expand=%d stretch=%d" % [where, d.expand_mode, d.stretch_mode])
			ok = false
		if wv.viewport.size_2d_override != Vector2i(area) or wv.viewport.size != Vector2i(area) * k:
			flag("%s viewport %s override %s (area %s k %d)" % [where, wv.viewport.size, wv.viewport.size_2d_override, area, k])
			ok = false
		for cam: CameraShake in wv.viewport.find_children("*", "CameraShake", true, false):
			if absf(cam.view_fit - UiScale.fit()) > 0.0001:
				flag("%s camera %s fit %.4f != %.4f" % [where, cam.name, cam.view_fit, UiScale.fit()])
				ok = false
	var m = _game.get("_mission")
	if m != null and is_instance_valid(m) and m.is_inside_tree():
		var hud = m.get("_hud")
		if hud != null and is_instance_valid(hud) and hud.is_inside_tree():
			var hr: Rect2 = hud.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hud.size)
			if hr.position.length() > 0.01 or (hr.size - area).length() > 0.01 or hud._view() != area:
				flag("HUD rect %s view %s != area %s" % [hr, hud._view(), area])
				ok = false
			var wvp = hud.get("world_viewport")
			var wv := WorldView.of(m)
			if wv != null and wvp != wv.viewport:
				flag("HUD world_viewport %s is not the mission's view %s" % [wvp, wv.viewport])
				ok = false
		var outl = m.get("_outlines")
		if outl != null and is_instance_valid(outl) and outl.is_inside_tree():
			var dx: Transform2D = outl.device_xf()
			var want: Transform2D = Transform2D().scaled(Vector2(k, k)) * WorldView.world_xf(outl.world_vp) if outl.get("world_vp") != null else dx
			if not dx.is_equal_approx(want):
				flag("outline device_xf %s != k x world xf %s" % [dx, want])
				ok = false
	# Every visible Control drawn in the root: none bigger than the area.
	for c: Control in root.find_children("*", "Control", true, false):
		if c.get_viewport() != root or not c.is_visible_in_tree():
			continue
		var cr := c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)
		if cr.size.x > area.x + 1.0 or cr.size.y > area.y + 1.0:
			flag("oversize %s (%s) rect %s > area %s" % [c.get_path(), c.get_class(), cr, area])
			ok = false
	# Every full-rect Control (anchors 0,0,1,1) straight under a CanvasLayer, in the root or a world view: exactly the area.
	var vps: Array = [root]
	for wv: WorldView in root.find_children("*", "WorldView", true, false):
		vps.append(wv.viewport)
	for vp: Viewport in vps:
		for c: Control in vp.find_children("*", "Control", true, false):
			if c.get_viewport() != vp or not c.is_visible_in_tree() or not (c.get_parent() is CanvasLayer):
				continue
			if c.anchor_left != 0.0 or c.anchor_top != 0.0 or c.anchor_right != 1.0 or c.anchor_bottom != 1.0:
				continue
			if c.position.length() > 0.01 or (c.size - area).length() > 0.01:
				flag("full-rect %s (%s) at %s size %s != area %s" % [c.get_path(), c.get_class(), c.position, c.size, area])
				ok = false
	if log_ok and ok:
		check(true, "layout: window %s area %s k %d, %d view(s), screen %s" % [root.size, area, k,
			root.find_children("*", "WorldView", true, false).size(), _state_key()])


# --- pixels ------------------------------------------------------------------------------------------------------------------------

class Mark extends Node2D:
	var pts: Array = []
	func _draw() -> void:
		for p in pts:
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(1, 0, 1))


## The view the player sees a world through right now: the mission's, else the title's backdrop; null when an opaque screen covers it.
func _live_view() -> WorldView:
	var scr: int = _game.screen
	if scr in [Game.Screen.MISSION, Game.Screen.RESULTS, Game.Screen.INTERLUDE]:
		var m = _game.get("_mission")
		if m != null and is_instance_valid(m) and m.is_inside_tree():
			return WorldView.of(m)
	if scr == Game.Screen.TITLE:
		for wv: WorldView in root.find_children("*", "WorldView", true, false):
			if wv.is_inside_tree():
				return wv
	return null


func _pixel_check(label: String) -> bool:
	var wv := _live_view()
	if wv == null or not wv.is_inside_tree():
		return true
	_busy = true
	var vp := wv.viewport
	var layer := CanvasLayer.new()
	layer.layer = MARK_LAYER
	layer.follow_viewport_enabled = true
	var mark := Mark.new()
	layer.add_child(mark)
	vp.add_child(layer)
	var area := UiScale.area()
	var xf0 := WorldView.world_xf(vp)
	var pts := []
	for f: Vector2 in FRACS:
		pts.append((xf0.affine_inverse() * (area * f)).round())
	var all_ok := true
	var found_any := false
	for i in pts.size():
		if not is_instance_valid(wv) or not wv.is_inside_tree():
			break
		mark.pts = [pts[i]]
		mark.queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if not is_instance_valid(wv) or not wv.is_inside_tree():
			break
		var xf := WorldView.world_xf(vp)  # the transform the frame just drawn used
		var img := root.get_texture().get_image()
		var stretch := root.get_final_transform()
		var exp: Vector2 = stretch * (xf * Vector2(pts[i]))
		var box := _find_box(img, exp, 24)
		var got := box.get_center() if box.size != Vector2(-1, -1) else Vector2.INF
		var hud_xf := xf
		var m = _game.get("_mission")
		if m != null and is_instance_valid(m) and WorldView.of(m) == wv and m.get("_hud") != null and is_instance_valid(m._hud):
			hud_xf = m._hud._world_xf()
			if not hud_xf.is_equal_approx(xf):
				all_ok = check(false, "%s HUD xf %s != view xf %s" % [label, hud_xf, xf]) and all_ok
		if got == Vector2.INF:
			var far := _find_all(img)
			if far != Vector2.INF:
				all_ok = check(false, "%s pixel pt%d: mark expected at win %s, found at %s (d %s) window %s area %s k %d zoom %.3f" % [label, i, exp.round(),
					far.round(), (far - exp).round(), root.size, area, UiScale.k(), (vp.get_camera_2d().zoom.x if vp.get_camera_2d() != null else 0.0)]) and all_ok
				_save(img, "FAIL_%s_pt%d" % [label, i], true)
			else:
				say("  pixel pt%d hidden (covered) at %s" % [i, exp.round()])
			continue
		found_any = true
		# The mark is 4 units square about the point: every mark pixel found must lie in that square (a light beam or a panel
		# over part of it hides pixels but cannot move them), with 1.5 px of rounding.
		var half := 2.0 * absf(xf.get_scale().x) * stretch.get_scale().x + 1.5  # 2 world px each way, through the camera and the stretch
		var want := Rect2(exp - Vector2(half, half), Vector2(half, half) * 2.0)
		if not want.encloses(box):
			all_ok = check(false, "%s pixel pt%d: mark expected in %s, drawn at %s (centre d=%s)" % [label, i, want, box, got - exp]) and all_ok
			_save(img, "FAIL_%s_pt%d" % [label, i], true)
	if is_instance_valid(layer):
		layer.queue_free()
	if found_any and all_ok:
		check(true, "%s pixel: world marks where the HUD transform puts them (window %s area %s k %d)" % [label, root.size, area, UiScale.k()])
	elif not found_any and all_ok:
		say("  %s pixel: every mark covered" % label)
	_busy = false
	return all_ok


static func _is_mark(c: Color) -> bool:
	return c.r > 0.2 and c.b > 0.2 and absf(c.r - c.b) < 0.08 and c.g < 0.06


func _find(img: Image, near: Vector2, r: int) -> Vector2:
	var box := _find_box(img, near, r)
	return box.get_center() if box.size != Vector2(-1, -1) else Vector2.INF


## The bounding box (window px, pixel edges) of the mark's pixels within `r` of `near`; size (-1, -1) when there are none.
func _find_box(img: Image, near: Vector2, r: int) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for y in range(maxi(0, int(near.y) - r), mini(img.get_height(), int(near.y) + r)):
		for x in range(maxi(0, int(near.x) - r), mini(img.get_width(), int(near.x) + r)):
			if _is_mark(img.get_pixel(x, y)):
				lo = lo.min(Vector2(x, y))
				hi = hi.max(Vector2(x + 1, y + 1))
	return Rect2(lo, hi - lo) if lo.x != INF else Rect2(Vector2.ZERO, Vector2(-1, -1))


## The mark anywhere in the frame (slow; only when it is not near where it should be).
func _find_all(img: Image) -> Vector2:
	var data := img.get_data()
	var w := img.get_width()
	var h := img.get_height()
	if img.get_format() != Image.FORMAT_RGBA8 and img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGBA8)
		data = img.get_data()
	var bpp := 4 if img.get_format() == Image.FORMAT_RGBA8 else 3
	var sum := Vector2.ZERO
	var n := 0
	for y in range(0, h, 2):
		var row := y * w * bpp
		for x in range(0, w, 2):
			var o := row + x * bpp
			var r := data[o]
			var g := data[o + 1]
			var b := data[o + 2]
			if r > 50 and b > 50 and absi(r - b) < 20 and g < 15:
				sum += Vector2(x, y)
				n += 1
	return sum / n + Vector2(0.5, 0.5) if n > 0 else Vector2.INF


func _capture(why: String) -> void:
	await RenderingServer.frame_post_draw
	_save(root.get_texture().get_image(), why)


func _save(img: Image, why: String, full := false) -> void:
	_shot += 1
	var name := "%03d_%dx%d_%s" % [_shot, root.size.x, root.size.y, why.replace(" ", "_").replace(":", "-").replace("/", "-").replace("+", "_").left(70)]
	var im := img.duplicate() as Image
	if not full and im.get_width() > 1000:
		im.resize(im.get_width() / 2, im.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	im.save_png(out_dir.path_join(name + ".png"))
	say("  shot " + name)


# --- OS-input driving --------------------------------------------------------------------------------------------------------------

## One request to real_path.ps1; waits for its ack. Returns false on a timeout.
func os_do(line: String, timeout := 30.0) -> bool:
	_cmd += 1
	var p := chan.path_join("cmd_%d.txt" % _cmd)
	var f := FileAccess.open(p + ".tmp", FileAccess.WRITE)
	f.store_string(line)
	f.close()
	DirAccess.rename_absolute(p + ".tmp", p)
	var end := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not FileAccess.file_exists(chan.path_join("ack_%d.txt" % _cmd)):
		if Time.get_ticks_msec() > end:
			say("OS timeout on " + line)
			return false
		await process_frame
	await _frames(3)
	return true


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _secs(s: float) -> void:
	await create_timer(s).timeout


## Window px of a point in a screen's design frame (its `_ui`).
func win_of(frame: CanvasItem, design_pt: Vector2) -> Vector2i:
	return Vector2i((root.get_final_transform() * (frame.get_global_transform_with_canvas() * design_pt)).round())


func os_click_design(frame: CanvasItem, design_pt: Vector2, what: String) -> bool:
	var w := win_of(frame, design_pt)
	say("OS click %s at win %s" % [what, w])
	return await os_do("click %d %d" % [w.x, w.y])


func _until(cond: Callable, seconds: float) -> bool:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call():
		if Time.get_ticks_msec() > end:
			return false
		await process_frame
	return true


## The mouse check: an OS cursor move to `w` (window px) lands at the root mouse position the stretch says, and the world point under
## it (what a click picks) draws at that window px.
func mouse_check(w: Vector2i, label: String) -> void:
	await os_do("move %d %d" % [w.x, w.y])
	await _frames(4)
	var want: Vector2 = root.get_final_transform().affine_inverse() * Vector2(w)
	var got := root.get_mouse_position()
	check(got.distance_to(want) <= 1.0, "%s mouse: cursor win %s -> root %s (want %s)" % [label, w, got, want])
	var m = _game.get("_mission")
	if m != null and is_instance_valid(m):
		var bf = m._bf
		var miv: Vector2 = WorldView.mouse_in_view(bf)
		check(miv.distance_to(want) <= 1.0, "%s mouse_in_view %s == root mouse %s" % [label, miv, want])


func _mission_up() -> bool:
	var m = _game.get("_mission")
	return _game.screen == Game.Screen.MISSION and m != null and is_instance_valid(m) and m.started() and not _game._fading


func _drive() -> void:
	_driving = true
	await _secs(4.0)
	match route:
		"main":
			await _route_main()
		"god":
			await _route_god()
		"hunt":
			await _route_hunt()
		_:
			say("unknown route " + route)
	say("RESULT checks=%d failures=%d" % [checks, fails])
	await os_do("done", 5.0)
	quit()


## In a running mission: the pixel check, then pans (keys, middle drag), wheel zooms and the mouse check, each followed by the pixel check.
func play_checks(tag: String) -> void:
	await _pixel_check(tag + "-enter")
	var c := Vector2i(root.size / 2)
	await os_do("key 68 900")  # D
	await _pixel_check(tag + "-keyD")
	await os_do("key 83 700")  # S
	await _pixel_check(tag + "-keyS")
	await os_do("mdrag %d %d -300 -180" % [c.x, c.y])
	await _pixel_check(tag + "-mdrag")
	await os_do("wheel -4 %d %d" % [c.x, c.y])
	await _pixel_check(tag + "-wheelout")
	await os_do("wheel 6 %d %d" % [c.x + 200, c.y - 100])
	await _pixel_check(tag + "-wheelin")
	await mouse_check(Vector2i(c.x / 2, c.y / 2), tag)
	await _capture(tag + "-played")


func resize_checks(tag: String) -> void:
	await os_do("restore")
	await _secs(1.0)
	await _pixel_check(tag + "-restored")
	await os_do("size 1517 843")
	await _secs(1.0)
	await _pixel_check(tag + "-1517x843")
	await _capture(tag + "-1517x843")
	await os_do("dragcorner 140 60")
	await _secs(1.0)
	await _pixel_check(tag + "-dragged")
	await _capture(tag + "-dragged")
	await os_do("wheel -2 %d %d" % [root.size.x / 2, root.size.y / 2])
	await _pixel_check(tag + "-dragged-wheel")
	await os_do("max")
	await _secs(1.5)
	await _pixel_check(tag + "-remax")
	await os_do("key 65 600")  # A
	await _pixel_check(tag + "-remax-keyA")
	await mouse_check(Vector2i(root.size.x * 3 / 4, root.size.y / 3), tag + "-remax")
	await os_do("start")  # back to the run's own size (a no-op when it is maximized)
	await _secs(1.0)
	await _pixel_check(tag + "-back")


## Title -> board (OS clicks) -> a card -> Prepare -> MANIFEST -> the mission; Space skips the intro.
func enter_from_board(tier: int, id: String) -> bool:
	var board = _game._screen_node
	if not (board is MissionBoard):
		return check(false, "board not up for %s (%s)" % [id, _state_key()])
	await os_click_design(board._ui, MissionBoard.tab_rect(tier - 1).get_center(), "tier %d tab" % tier)
	await _frames(5)
	var ids: PackedStringArray = board.missions()
	var i := ids.find(id)
	if i < 0:
		return check(false, "%s not on tier %d (%s)" % [id, tier, ids])
	await os_click_design(board._ui, MissionBoard.card_rect(i, ids.size()).get_center(), "card " + id)
	if not await _until(func() -> bool: return _game._screen_node is PrepareScreen, 5.0):
		# a card click may only select; a second click picks
		await os_click_design(board._ui, MissionBoard.card_rect(i, ids.size()).get_center(), "card again " + id)
	if not await _until(func() -> bool: return _game._screen_node is PrepareScreen, 5.0):
		return check(false, "card %s did not open Prepare (%s)" % [id, _state_key()])
	await _secs(1.0)
	var prep = _game._screen_node
	await _capture("prepare-" + id)
	if not prep.can_manifest():
		prep.draft.preselect(prep.mission.default_loadout)
		say("  (draft preselected in-process: default loadout)")
	await os_click_design(prep._ui, PrepareScreen.MANIFEST_RECT.get_center(), "MANIFEST")
	if not await _until(_mission_up, 20.0):
		return check(false, "MANIFEST did not start %s (%s)" % [id, _state_key()])
	await _secs(1.0)
	await _pixel_check(id + "-intro")
	await os_do("key 32 80")  # Space skips the intro
	await _until(func() -> bool: return not _game._mission.in_intro(), 8.0)
	await _secs(1.0)
	return check(_game.mission_id == id, "%s running from the board (OS clicks; night id %s)" % [id, _game.mission_id])


func pause_click(action: String) -> bool:
	if not is_instance_valid(_game._pause):
		await os_do("key 27 60")  # Esc
		await _until(func() -> bool: return is_instance_valid(_game._pause), 3.0)
	var pm = _game._pause
	if pm == null or not is_instance_valid(pm):
		return check(false, "pause did not open")
	await _secs(0.5)
	return await os_click_design(pm._ui, pm._menu.rect_of(action).get_center(), "pause " + action)


func _route_main() -> void:
	await _until(func() -> bool: return _game._screen_node is TitleScreen, 20.0)
	await _secs(3.0)
	await _pixel_check("title")
	var title = _game._screen_node
	# Options over the title's live world, then Play.
	await os_click_design(title._ui, title._menu.rect_of("options").get_center(), "title options")
	await _secs(1.0)
	await _capture("title-options")
	await os_do("key 27 60")
	await _secs(0.5)
	await os_click_design(title._ui, title._menu.rect_of("play").get_center(), "title play")
	if not check(await _until(func() -> bool: return _game._screen_node is MissionBoard, 5.0), "title Play opens the board (OS click)"):
		return
	await _secs(1.0)
	# 1. Tier 1 Tax Collector: play checks, mid-mission resizes, the pause menu and its options, the legend.
	if await enter_from_board(1, "tax_collector"):
		await play_checks("tax")
		await resize_checks("tax")
		await os_do("key 72 60")  # H: the legend
		await _secs(0.8)
		await _capture("tax-legend")
		await _pixel_check("tax-legend")
		await os_do("key 27 60")
		await _secs(0.5)
		await pause_click("options")
		await _secs(0.8)
		await _capture("tax-pause-options")
		await os_do("key 27 60")
		await _secs(0.4)
		# Pause -> Restart: a fresh mission in a fresh view.
		var old: int = _game._mission.get_instance_id()
		await pause_click("restart")
		await _until(func() -> bool: return _mission_up() and _game._mission.get_instance_id() != old, 15.0)
		await _secs(1.0)
		await os_do("key 32 80")
		await _secs(1.0)
		await play_checks("tax-restart")
		# Pause -> Change powers -> Esc back to the board.
		await pause_click("change")
		await _until(func() -> bool: return _game._screen_node is PrepareScreen, 5.0)
		await _secs(0.8)
		await _capture("tax-change-prepare")
		await os_click_design(_game._screen_node._ui, PrepareScreen.MANIFEST_RECT.get_center(), "MANIFEST again")
		await _until(_mission_up, 20.0)
		await os_do("key 32 80")
		await _secs(1.0)
		await play_checks("tax-change")
		# Results (the clock run out in-process), then Replay by OS click.
		_game._mission.rules().time_left = 0.01
		await _until(func() -> bool: return _game._screen_node is ResultsScreen, 10.0)
		await _secs(1.0)
		await _pixel_check("tax-results")
		var rs = _game._screen_node
		old = _game._mission.get_instance_id()
		await os_click_design(rs._ui, rs._menu.rect_of("replay").get_center(), "results replay")
		await _until(func() -> bool: return _mission_up() and _game._mission.get_instance_id() != old, 15.0)
		await os_do("key 32 80")
		await _secs(1.0)
		await play_checks("tax-replay")
		# Pause -> Missions: back to the board (a second view in the same session next).
		await pause_click("missions")
		await _until(func() -> bool: return _game._screen_node is MissionBoard, 5.0)
		await _secs(0.8)
	# 2. Lost Lamb, First Prayers, a Tier 3 and a Tier 5 mission, each from the board; a resize in two of them.
	for pair in [[1, "lost_lamb"], [1, "first_prayers"], [3, "festival"], [5, "long_night"]]:
		if not (_game._screen_node is MissionBoard):
			break
		if await enter_from_board(pair[0], pair[1]):
			await play_checks(pair[1])
			if pair[1] in ["lost_lamb", "long_night"]:
				await resize_checks(pair[1])
		if _game.screen == Game.Screen.MISSION:
			await pause_click("missions")
			await _until(func() -> bool: return _game._screen_node is MissionBoard, 5.0)
			await _secs(0.8)
	# 3. The DEV tab: Tier 1 in the Capital.
	if _game._screen_node is MissionBoard:
		var board = _game._screen_node
		await os_click_design(board._ui, MissionBoard.DEV_RECT.get_center(), "DEV tab")
		await _secs(0.8)
		await _capture("board-dev")
		var ids: PackedStringArray = board.missions()
		say("  DEV tab: %s" % [ids])
		var pick := -1
		for j in ids.size():
			if "@capital" in ids[j] and "tax_collector" in ids[j]:
				pick = j
		if pick < 0 and ids.size() > 1:
			pick = 1
		if pick >= 0:
			board.selected = pick  # the DEV tab pages its row: scroll the window to the card, then click its real rect
			board._follow()
			await os_click_design(board._ui, board.row1_rect(pick).get_center(), "card " + ids[pick])
			if not await _until(func() -> bool: return _game._screen_node is PrepareScreen, 4.0):
				await os_click_design(board._ui, board.row1_rect(pick).get_center(), "card again")
			if await _until(func() -> bool: return _game._screen_node is PrepareScreen, 5.0):
				await _secs(0.8)
				var prep = _game._screen_node
				if not prep.can_manifest():
					prep.draft.preselect(prep.mission.default_loadout)
				await os_click_design(prep._ui, PrepareScreen.MANIFEST_RECT.get_center(), "MANIFEST capital")
				if await _until(_mission_up, 30.0):
					await os_do("key 32 80")
					await _secs(1.5)
					await play_checks("capital")
					await resize_checks("capital")
			else:
				check(false, "DEV card did not open Prepare")


func _screen_is(cls: String) -> bool:
	var sn = _game._screen_node
	return sn != null and is_instance_valid(sn) and sn.get_script() != null and str(sn.get_script().get_global_name()) == cls


## Endless Night, all by OS clicks: title -> slots -> New -> god select -> CHOOSE -> hub -> Skill Tree -> REMEMBRANCE (a memory of the
## Capital: pan, zoom, resize, the DAY/NIGHT toggle rebuilds it in a new view) -> Leave -> tree -> hub -> Descend -> the god's Prepare
## -> MANIFEST -> the night (pan, zoom, resize) -> Abandon -> hub.
func _route_god() -> void:
	await _until(func() -> bool: return _screen_is("TitleScreen"), 20.0)
	await _secs(3.0)
	var title = _game._screen_node
	await os_click_design(title._ui, title._menu.rect_of("endless").get_center(), "title Endless Night")
	if not check(await _until(func() -> bool: return _screen_is("SlotScreen"), 5.0), "Endless Night opens the slots (OS click)"):
		return
	await _secs(0.8)
	await _capture("slots")
	var slots = _game._screen_node
	await os_click_design(slots._ui, slots.button_rect(0, "new").get_center(), "slot 1 New")
	if not check(await _until(func() -> bool: return _screen_is("GodSelectScreen"), 5.0), "New opens the god select (OS click)"):
		return
	await _secs(1.5)
	await _capture("god-select")
	var pick = _game._screen_node
	await os_click_design(pick._ui, GodSelectScreen.CHOOSE_RECT.get_center(), "god select CHOOSE")
	if not check(await _until(func() -> bool: return _screen_is("GodChamber"), 5.0), "CHOOSE makes the god and opens the hub (OS click)"):
		return
	await _secs(1.0)
	await _capture("hub")
	var hub = _game._screen_node
	await os_click_design(hub._ui, hub.menu_rect("tree").get_center(), "hub Skill Tree")
	if not check(await _until(func() -> bool: return _screen_is("SkillTreeScreen"), 5.0), "Skill Tree opens (OS click)"):
		return
	await _secs(1.5)
	await _capture("tree")
	var tree = _game._screen_node
	say("  tree selected %s" % tree.selected_key())
	await os_click_design(tree._ui, SkillTreeScreen.REMEMBER_RECT.get_center(), "tree REMEMBRANCE")
	if check(await _until(_mission_up, 20.0), "REMEMBRANCE opens the memory (OS click)"):
		await _secs(1.0)
		await os_do("key 32 80")
		await _secs(1.0)
		await play_checks("memory")
		await resize_checks("memory")
		# DAY/NIGHT: the same power rebuilt with the night look, in a new view.
		var old: int = _game._mission.get_instance_id()
		var nr: Rect2 = MemoryOverlay.night_rect(UiScale.area())
		var w := Vector2i((root.get_final_transform() * nr.get_center()).round())
		say("OS click memory NIGHT at win %s" % w)
		await os_do("click %d %d" % [w.x, w.y])
		if check(await _until(func() -> bool: return _mission_up() and _game._mission.get_instance_id() != old, 20.0), "the memory's NIGHT toggle rebuilds it (OS click)"):
			await _secs(1.0)
			await os_do("key 32 80")
			await _secs(1.0)
			await play_checks("memory-night")
		await pause_click("leave_memory")
		check(await _until(func() -> bool: return _screen_is("SkillTreeScreen"), 8.0), "Leave from the memory's pause returns to the tree (OS click)")
		await _secs(1.0)
		await _capture("tree-after-memory")
	tree = _game._screen_node
	if _screen_is("SkillTreeScreen"):
		await os_click_design(tree._ui, SkillTreeScreen.BACK_RECT.get_center(), "tree Back")
		await _until(func() -> bool: return _screen_is("GodChamber"), 5.0)
		await _secs(0.8)
	if _screen_is("GodChamber"):
		hub = _game._screen_node
		await os_click_design(hub._ui, hub.menu_rect("descend").get_center(), "hub Descend")
		if check(await _until(func() -> bool: return _screen_is("WorldMap"), 5.0), "the table opens the World Map (OS click)"):
			await _secs(0.5)
			var map = _game._screen_node
			await os_click_design(map._ui, map.descend_rect().get_center(), "map Descend")
		if check(await _until(func() -> bool: return _screen_is("PrepareScreen"), 5.0), "Descend opens the god's Prepare (OS click)"):
			await _secs(1.0)
			await _capture("god-prepare")
			var prep = _game._screen_node
			var shown: PackedStringArray = prep.shown()
			for i in mini(2, shown.size()):  # draft the god's first powers by OS clicks on their cards
				await os_click_design(prep._ui, PrepareScreen.cell_rect(i, shown.size()).get_center(), "card " + shown[i])
				await _secs(0.3)
			await _capture("god-prepare-drafted")
			await os_click_design(prep._ui, PrepareScreen.MANIFEST_RECT.get_center(), "god MANIFEST")
			if check(await _until(_mission_up, 20.0), "the god's night starts (OS click)"):
				await _secs(1.0)
				await os_do("key 32 80")
				await _secs(1.0)
				await play_checks("endless")
				await resize_checks("endless")
				await pause_click("abandon")
				await _secs(0.8)
				await _capture("endless-abandon-confirm")
				var pm = _game._pause
				if pm != null and is_instance_valid(pm):
					await os_click_design(pm._ui, pm._menu.rect_of("abandon").get_center(), "confirm Abandon")
				check(await _until(func() -> bool: return _screen_is("GodChamber"), 8.0), "Abandon returns to the hub (OS clicks)")
				await _secs(1.0)
				await _capture("hub-after-abandon")


## The DEV tab's Hunts row (break_hunt, face_halcyon ...), each by OS clicks: card -> Prepare -> MANIFEST -> the Hunt (pan, zoom,
## resize) -> Pause -> Missions.
func _route_hunt() -> void:
	await _until(func() -> bool: return _screen_is("TitleScreen"), 20.0)
	await _secs(3.0)
	var title = _game._screen_node
	await os_click_design(title._ui, title._menu.rect_of("play").get_center(), "title play")
	if not check(await _until(func() -> bool: return _screen_is("MissionBoard"), 5.0), "Missions opens the board (OS click)"):
		return
	await _secs(0.8)
	var n := 0
	for hunt in ["break_hunt", "face_halcyon"]:
		var board = _game._screen_node
		await os_click_design(board._ui, MissionBoard.DEV_RECT.get_center(), "DEV tab")
		await _secs(0.6)
		var hunts: PackedStringArray = board.dev_hunts()
		var i := hunts.find(hunt)
		if i < 0:
			check(false, "%s not in the DEV tab's Hunts (%s)" % [hunt, hunts])
			continue
		await os_click_design(board._ui, MissionBoard.hunt_rect(i, hunts.size()).get_center(), "hunt card " + hunt)
		if not check(await _until(func() -> bool: return _screen_is("PrepareScreen"), 5.0), "%s's card opens its Prepare (OS click)" % hunt):
			continue
		await _secs(1.0)
		await _capture("prepare-" + hunt)
		var prep = _game._screen_node
		if not prep.can_manifest():
			var shown: PackedStringArray = prep.shown()
			for j in mini(2, shown.size()):
				await os_click_design(prep._ui, PrepareScreen.cell_rect(j, shown.size()).get_center(), "card " + shown[j])
				await _secs(0.3)
		await os_click_design(prep._ui, PrepareScreen.MANIFEST_RECT.get_center(), "MANIFEST " + hunt)
		if check(await _until(_mission_up, 30.0), "%s starts (OS click)" % hunt):
			await _secs(1.0)
			await os_do("key 32 80")
			await _secs(1.0)
			await play_checks(hunt)
			if n == 0:
				await resize_checks(hunt)
			n += 1
		if _game.screen == Game.Screen.MISSION:
			await pause_click("missions")
			await _until(func() -> bool: return _screen_is("MissionBoard"), 6.0)
			await _secs(0.8)
		if not _screen_is("MissionBoard"):
			check(false, "back on the board after %s (%s)" % [hunt, _state_key()])
			return
