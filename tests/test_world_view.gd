extends RefCounted
## UI resolution, Task 2a: WorldView hosts the world in a SubViewport; UI layers stay in the root; the sim view is pinned.


class KeyNode extends Node:
	var handled_keys := true
	var seen: InputEvent
	var count := 0
	var handle_mouse := false

	func _input(event: InputEvent) -> void:
		seen = event
		count += 1
		if (handled_keys and event is InputEventKey) or (handle_mouse and event is InputEventMouseButton):
			get_viewport().set_input_as_handled()


## Mimics a self-hosting scene: self_host first, children only when it returned false.
class SelfHoster extends Node2D:
	var readies := 0

	func _ready() -> void:
		readies += 1
		if readies == 1:
			get_tree().current_scene = self  # as a main scene is
		if WorldView.self_host(self, true):
			return
		add_child(Node.new())


## A view on the root, once the tree is live (the suite starts before the root enters the tree; one frame fixes that).
static func _view(t) -> WorldView:
	var tree := Engine.get_main_loop() as SceneTree
	var wv := WorldView.new()
	tree.root.add_child(wv)
	await t.process_frame
	return wv


static func _drop(wv: WorldView) -> void:
	wv.get_parent().remove_child(wv)
	wv.free()


static func _key(code: Key) -> InputEventKey:
	var k := InputEventKey.new()
	k.keycode = code
	k.physical_keycode = code
	k.pressed = true
	return k


static func _hosting(t) -> void:
	var wv: WorldView = await _view(t)
	var n := Node2D.new()
	wv.host(n)
	t.check(n.get_parent() == wv.viewport, "host() puts the node under the world viewport")
	t.check(WorldView.of(n) == wv, "of() finds the view from the hosted node")
	t.check(WorldView.ui_parent(n) == wv.ui, "ui_parent is the view's ui when hosted")
	var loose := Node2D.new()
	t.check(WorldView.of(loose) == null and WorldView.ui_parent(loose) == loose, "an unhosted node is its own ui parent")
	t.check(wv.display.texture == wv.viewport.get_texture() and wv.display.position == Vector2.ZERO, "the display shows the viewport at the origin")
	t.check(wv.display.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and wv.display.mouse_filter == Control.MOUSE_FILTER_IGNORE, "nearest, ignoring the mouse")
	loose.free()
	_drop(wv)


static func _bf_layers(t) -> void:
	var wv: WorldView = await _view(t)
	var bf := Battlefield.new()
	wv.host(bf)
	t.check(bf.hud_layer.get_parent() == wv.ui, "a hosted battlefield's hud layer is in the view's ui")
	t.check(wv.ui.get_node_or_null("FpsMeter") != null and wv.ui.get_node_or_null("ArtToggle") != null, "F3 and F7 handlers are in the ui")
	t.check(bf.get_node_or_null("FpsMeter") == null and bf.ui_parent() == wv.ui, "none left in the world")
	_drop(wv)
	var plain := Battlefield.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(plain)
	await t.process_frame
	t.check(plain.hud_layer.get_parent() == plain, "an unhosted battlefield keeps its hud layer")
	plain.get_parent().remove_child(plain)
	plain.free()


static func _keys(t) -> void:
	var wv: WorldView = await _view(t)
	var n := KeyNode.new()
	n.set_process_input(true)
	n.handled_keys = false
	wv.host(n)
	var root := wv.get_viewport()
	t.check(not root.is_input_handled(), "start unhandled")
	wv._unhandled_input(_key(KEY_Q))
	t.check(n.seen is InputEventKey and not root.is_input_handled(), "a key the world ignores leaves the root unhandled")
	var click := InputEventMouseButton.new()
	click.position = Vector2(10, 10)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	wv._unhandled_input(click)
	t.check(not root.is_input_handled(), "a click the world ignores leaves the root unhandled")
	n.handle_mouse = true
	wv._unhandled_input(click)
	t.check(root.is_input_handled(), "a click the world handles marks the root handled")
	n.handle_mouse = false
	_drop(wv)
	wv = await _view(t)
	n = KeyNode.new()
	n.set_process_input(true)
	wv.host(n)
	wv._unhandled_input(_key(KEY_Q))
	t.check(root.is_input_handled(), "a key the world handles leaves the root handled")
	_drop(wv)


static func _mouse_identity(t) -> void:
	var wv: WorldView = await _view(t)
	var n := KeyNode.new()
	n.set_process_input(true)
	wv.host(n)
	var e := InputEventMouseButton.new()
	e.position = Vector2(123, 45)
	e.global_position = e.position
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	wv._unhandled_input(e)
	t.check(n.seen is InputEventMouseButton and (n.seen as InputEventMouseButton).position == Vector2(123, 45), "a click reaches the world at the same position")
	t.check(n.count == 1, "the world sees the click once")
	wv._unhandled_input(e)
	t.check(n.count == 2, "each click once")
	var m := InputEventMouseMotion.new()
	m.position = Vector2(300, 200)
	wv._unhandled_input(m)
	t.check(n.seen is InputEventMouseMotion and (n.seen as InputEventMouseMotion).position == Vector2(300, 200) and n.count == 3, "motion is forwarded, once")
	_drop(wv)


## Maximized at 125% DPI (1920x991, k 2, area 960x495, fit 1.375): the world renders at device resolution (area x k px) with its
## canvas in UI units, so the picture is the area at k x, the camera's canvas transform and every mapping are what they were at
## area px, and a mouse point lands on the same world position as before; only the render (final transform) gains k.
static func _device_resolution(t) -> void:
	var wv: WorldView = await _view(t)
	var bf := Battlefield.new()
	wv.host(bf)
	UiScale.apply(UiScale.layout(Vector2i(1920, 991)))
	bf.camera.zoom_to(0.8)
	bf.camera.position = Vector2(120, 40)
	await t.process_frame
	await t.process_frame
	t.check(wv.viewport.size == Vector2i(1920, 990), "the world viewport renders area x k = 1920x990 px (%s)" % [wv.viewport.size])
	t.check(wv.viewport.size_2d_override == Vector2i(960, 495) and wv.viewport.size_2d_override_stretch, "its 2D canvas is the 960x495 area, stretched")
	t.check(wv.viewport.get_visible_rect().size == Vector2(960, 495), "the visible rect (camera clamps, sounds, shaders) is still the area")
	t.check(wv.display.size == Vector2(960, 495), "the picture covers the area in units (k device px each: 1:1)")
	var cam := bf.camera
	t.near(cam.zoom.x, 0.8 * 1.375, 1e-6, "the camera zoom is logical x fit, as before")
	var xf := wv.viewport.get_canvas_transform()
	t.near(xf.get_scale().x, cam.zoom.x, 1e-5, "the canvas transform (world to UI units) is the camera's zoom")
	var render := wv.viewport.get_final_transform() * xf
	t.near(render.get_scale().x, cam.zoom.x * 2.0, 1e-5, "the render (world to device px) is zoom x k: 2.75 device px per art px")
	t.check(WorldView.world_xf(wv.viewport) == xf, "world_xf (HUD tags) is the canvas transform, in UI units")
	# A real mouse event forwarded by the view lands where the same root point did when the viewport was area px.
	var p := Vector2(700, 120)
	var mm := InputEventMouseMotion.new()
	mm.position = p
	mm.global_position = p
	wv._unhandled_input(mm)
	t.check(wv.viewport.get_mouse_position() == p, "the world viewport's mouse is the root point (%s)" % [wv.viewport.get_mouse_position()])
	var want := xf.affine_inverse() * p
	t.check(bf.get_global_mouse_position().is_equal_approx(want), "the world mouse is the world point under it (%s vs %s)" % [bf.get_global_mouse_position(), want])
	WorldView.test_mouse = p
	var centre := cam.get_screen_center_position()
	var ground := Iso.screen_to_ground(centre + (p - Vector2(960, 495) * 0.5) / cam.zoom.x)
	t.check(bf.mouse_ground().is_equal_approx(ground), "mouse_ground is the ground under it (%s vs %s)" % [bf.mouse_ground(), ground])
	WorldView.test_mouse = Vector2.INF
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))
	t.check(wv.viewport.size == Vector2i(640, 360), "back to 640x360 at k 1")
	_drop(wv)


## Where the player actually sees the world point `p` (root UI units): the camera's canvas transform, the viewport's stretch to its
## device px (the texture), then the display's mapping of that texture onto its rect in the root.
static func _shown(wv: WorldView, p: Vector2) -> Vector2:
	var tex := wv.viewport.get_final_transform() * wv.viewport.get_canvas_transform() * p
	return wv.display.position + tex * wv.display.size / Vector2(wv.viewport.size)


## The world point the player sees under the root point `s` (the inverse of _shown()).
static func _seen_at(wv: WorldView, s: Vector2) -> Vector2:
	var tex := (s - wv.display.position) * Vector2(wv.viewport.size) / wv.display.size
	return (wv.viewport.get_final_transform() * wv.viewport.get_canvas_transform()).affine_inverse() * tex


## 2026-11-17 tag fix 2: the HUD's tags (world_xf), the picture the player sees (the camera, the viewport's stretch, the display) and
## mouse picking agree on every world point, at k 1 (any area, 1392x711 too), k 2 (odd remainders) and k 3, at zoom 0.5 .. 1.6, before
## and after panning; with the view made after the window has its size (a mission started from the board: the display once took the
## texture's size, area x k, and showed the world k times too big while the tags stayed true) and before it (a --show run).
static func _display_mapping(t) -> void:
	var windows := [Vector2i(1392, 711), Vector2i(1300, 700), Vector2i(1000, 640), Vector2i(1100, 900), Vector2i(1280, 720),
		Vector2i(1920, 991), Vector2i(1517, 803), Vector2i(2560, 1369)]
	for window: Vector2i in windows:
		for late in [true, false]:
			var lay := UiScale.layout(window)
			if late:
				UiScale.apply(lay)  # the window first, then the view (the board's missions, the title)
			var wv: WorldView = await _view(t)
			var bf := Battlefield.new()
			wv.host(bf)
			if not late:
				UiScale.apply(lay)  # the view first, then the window (a --show run)
			await t.process_frame
			var area := Vector2(lay["area"])
			var what := "%s k%d %s" % [window, lay["k"], "view made after the resize" if late else "view resized"]
			t.check(wv.display.size == area and wv.display.position == Vector2.ZERO, "%s: the picture covers the area %s (%s)" % [what, area, wv.display.size])
			t.check(wv.viewport.size == Vector2i(area) * int(lay["k"]), "%s: the viewport renders area x k (%s)" % [what, wv.viewport.size])
			var worst := 0.0
			var worst_pick := 0.0
			for z in [0.5, 0.85, 1.6]:
				bf.camera.zoom_to(z)
				for pan in [Vector2.ZERO, Vector2(300, -150), Vector2(-700, 420)]:
					bf.camera.position = pan
					await t.process_frame
					var xf := WorldView.world_xf(wv.viewport)
					for f in [Vector2(0.5, 0.5), Vector2(0.1, 0.1), Vector2(0.9, 0.2), Vector2(0.2, 0.85), Vector2(0.95, 0.95)]:
						var p: Vector2 = xf.affine_inverse() * (area * (f as Vector2))  # a world point on screen
						worst = maxf(worst, (xf * p).distance_to(_shown(wv, p)))
						var s: Vector2 = area * (f as Vector2)
						WorldView.test_mouse = s
						worst_pick = maxf(worst_pick, Iso.ground_to_screen(bf.mouse_ground()).distance_to(_seen_at(wv, s)))
						WorldView.test_mouse = Vector2.INF
			t.check(worst < 0.01, "%s: every tag sits on the world point it marks as drawn, at zoom 0.5/0.85/1.6, panned (off by %.3f units)" % [what, worst])
			t.check(worst_pick < 0.01, "%s: a click picks the world point drawn under it (off by %.3f px)" % [what, worst_pick])
			_drop(wv)
			UiScale.apply(UiScale.layout(Vector2i(640, 360)))


## People and animals draw nearest (sharp); the world viewport defaults to linear, so buildings, ground and props soften.
static func _filters(t) -> void:
	var wv: WorldView = await _view(t)
	t.check(wv.viewport.canvas_item_default_texture_filter == Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR, "the world defaults to linear")
	var person := Person.new()
	var enemy := DummyEnemy.new()
	var animal := Animal.new()
	var building := Structure.new()
	t.check(person.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "a person draws nearest")
	t.check(enemy.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "an enemy draws nearest")
	t.check(animal.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "an animal draws nearest")
	t.check(building.texture_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE, "a building inherits the world's linear")
	for n: Node in [person, enemy, animal, building]:
		n.free()
	_drop(wv)


static func _self_host(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var loose := Node2D.new()
	t.check(not WorldView.self_host(loose), "a node off the tree is never self-hosted")
	loose.free()
	var n := SelfHoster.new()
	tree.root.add_child(n)
	await t.process_frame
	await t.process_frame
	var wv := WorldView.of(n)
	t.check(wv != null and n.get_parent() == wv.viewport and wv.get_parent() == tree.root, "the scene is reparented into a new view on the root")
	t.check(tree.current_scene == wv and wv.hosted() == n, "the view is the current scene, hosted() is the node")
	t.check(n.readies == 2 and n.get_child_count() == 1, "_ready runs twice and the second run builds the children once")
	var other := Node2D.new()
	wv.host(other)
	t.check(wv.hosted() == other, "a view hosts one node at a time")
	n.free()
	await t.process_frame
	t.check(is_instance_valid(wv) and not wv.is_queued_for_deletion(), "the old node leaving does not free a view that moved on")
	tree.current_scene = null
	wv.get_parent().remove_child(wv)
	wv.free()


static func _sim_view_pinned(t) -> void:
	var wv: WorldView = await _view(t)
	var bf := Battlefield.new()
	wv.host(bf)
	wv.resize(Vector2i(853, 360))
	bf.sim_zoom = 0.6
	var person := Person.view
	var structure := Structure.view
	bf._process(0.0)
	var want := Battlefield.SIM_VIEW / 0.6 + Vector2.ONE * 2.0 * Battlefield.VIEW_MARGIN
	t.near(Person.view.size.x, want.x, 0.001, "the sim view width ignores the viewport width")
	t.near(Person.view.size.y, want.y, 0.001, "the sim view height")
	t.check(Structure.view == Person.view, "structures see the same view")
	t.check(bf.sim_view_size().is_equal_approx(Battlefield.SIM_VIEW / 0.6), "sim_view_size")
	bf.sim_zoom = 0.0
	bf.camera.zoom = Vector2.ONE * 0.8
	bf._process(0.0)
	var want2 := Battlefield.SIM_VIEW / 0.8 + Vector2.ONE * 2.0 * Battlefield.VIEW_MARGIN
	t.near(Person.view.size.x, want2.x, 0.001, "without sim_zoom the camera zoom decides, width ignores the viewport")
	t.near(Person.view.size.y, want2.y, 0.001, "and the height")
	Person.view = person
	Structure.view = structure
	_drop(wv)


## The simulation's view does not depend on the window: a hosted Battlefield at 860x360 with fit 1.0238 (3440x1440) steps
## the same Person.view as at 640x360 with fit 1, at the same logical zoom and camera position.
static func _sim_independent(t) -> void:
	var wv: WorldView = await _view(t)
	var bf := Battlefield.new()
	wv.host(bf)
	var person := Person.view
	var structure := Structure.view
	bf.sim_zoom = 0.0
	bf.camera.zoom_to(0.8)
	bf.camera.position = Vector2(120, 40)
	await t.process_frame  # the camera's screen centre follows its position a frame later
	bf._process(0.0)
	var narrow := Person.view
	var lay := UiScale.layout(Vector2i(3440, 1440))
	UiScale.apply(lay)
	t.check(wv.viewport.size_2d_override == Vector2i(860, 360) and wv.viewport.get_visible_rect().size == Vector2(860, 360),
		"the world viewport's canvas follows the layout's area (%s)" % [wv.viewport.size_2d_override])
	t.check(wv.viewport.size == Vector2i(3440, 1440), "rendered at k (4) x the area (%s)" % [wv.viewport.size])
	t.check(wv.display.size == Vector2(860, 360), "and so does the picture of it")
	t.near(bf.camera.view_fit, 1.0238, 1e-3, "the hosted camera takes the layout's fit")
	t.near(bf.camera.logical_zoom(), 0.8, 1e-6, "keeping its logical zoom")
	t.near(bf.camera.zoom.x, 0.8 * bf.camera.view_fit, 1e-6, "and rendering at logical x fit")
	await t.process_frame
	bf._process(0.0)
	t.check(Person.view == narrow, "Person.view is the same at 860x360 / fit 1.0238 as at 640x360 / fit 1 (%s vs %s)" % [Person.view, narrow])
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))
	t.check(wv.viewport.size == Vector2i(640, 360) and wv.viewport.size_2d_override == Vector2i(640, 360) and bf.camera.view_fit == 1.0,
		"back to 640x360 at k 1, fit 1")
	Person.view = person
	Structure.view = structure
	_drop(wv)


## The wheel stops at the player's zoom-out limit (Settings.zoom_out): 0.85 by default, 0.5 when set; a raised limit
## brings a camera that is further out back in, and the view stays on the ground at 0.35.
static func _zoom_limit(t) -> void:
	var made := await _hosted_mission(t)
	var wv: WorldView = made[0]
	var m: Mission = made[1]
	m.skip_intro()
	await t.process_frame
	var wheel := func(up: bool, n: int) -> void:
		for i in n:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
			e.pressed = true
			m._unhandled_input(e)
	var cam := m._bf.camera
	wheel.call(false, 30)
	t.near(cam.logical_zoom(), 0.85, 1e-4, "default: the wheel stops at 0.85 (%f)" % cam.logical_zoom())
	var s := Settings.new()
	s.zoom_out = 0.5
	s.apply()
	t.near(Mission.zoom_min(), 0.5, 1e-6, "Mission.zoom_min() follows the setting")
	wheel.call(false, 30)
	t.near(cam.logical_zoom(), 0.5, 1e-4, "set to 0.5: the wheel stops at 0.5 (%f)" % cam.logical_zoom())
	s.zoom_out = 0.35
	s.apply()
	wheel.call(false, 30)
	t.near(cam.logical_zoom(), 0.35, 1e-4, "set to 0.35: the wheel stops at 0.35 (%f)" % cam.logical_zoom())
	var view := wv.viewport.get_visible_rect().size
	m._pan(Vector2(1.0e6, 1.0e6))
	t.check(Mission.clamp_view(cam.position, cam.zoom.x, view).is_equal_approx(cam.position), "panned to the far corner at 0.35: still clamped")
	var outer := TownFloor.drawn_area()
	var half := view * 0.5 / cam.zoom.x
	var ok := true
	for c: Vector2 in [cam.position - half, cam.position + half, cam.position + Vector2(half.x, -half.y), cam.position + Vector2(-half.x, half.y)]:
		ok = ok and outer.grow(0.01).has_point(Iso.screen_to_ground(c))
	t.check(ok, "at 0.35 in the far corner the view's corners are on drawn ground")
	s.zoom_out = 0.7  # raised in the pause Options: the next frame steps the camera back in
	s.apply()
	await t.process_frame
	t.check(cam.logical_zoom() >= 0.7 - 1e-4, "a raised limit brings the camera back to it (%f)" % cam.logical_zoom())
	Settings.new().apply()
	_drop(wv)


## A resize re-clamps the camera with the NEW fit: panned to an edge, zoomed out, then a wider layout: the view stays on the drawn ground.
static func _resize_reclamps(t) -> void:
	var made := await _hosted_mission(t)
	var wv: WorldView = made[0]
	var m: Mission = made[1]
	m.skip_intro()
	await t.process_frame
	m._bf.camera.zoom_to(Mission.ZOOM_MIN)
	m._pan(Vector2(1.0e6, 1.0e6))
	m._pan(Vector2.ZERO)
	for window in [Vector2i(3440, 1440), Vector2i(1600, 900), Vector2i(1366, 768), Vector2i(1280, 720)]:
		UiScale.apply(UiScale.layout(window))
		var view := wv.viewport.get_visible_rect().size
		var cam := m._bf.camera
		t.near(cam.view_fit, UiScale.layout(window)["fit"], 1e-6, "%s: the camera has the layout's fit" % [window])
		var held := Mission.clamp_view(cam.position, cam.zoom.x, view)
		t.check(held.is_equal_approx(cam.position), "%s: after the resize the camera is inside the clamp for the new fit and size (%s vs %s)" % [window, cam.position, held])
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))
	_drop(wv)


## Picking at a 2560x1080-shaped area (853x360 units, off-centre frame): a mouse position (the test hook) lands on the ground point the
## camera's own transform gives for that screen point. The real root-mouse path (get_viewport().get_mouse_position() under canvas_items)
## is not reachable headless; FLOW's _flow_click_ground (game.gd) covers it.
static func _picking(t) -> void:
	var wv: WorldView = await _view(t)
	var bf := Battlefield.new()
	wv.host(bf)
	UiScale.apply(UiScale.layout(Vector2i(2560, 1080)))  # 853x360 units
	bf.camera.zoom_to(0.8)
	bf.camera.position = Vector2(120, 40)
	await t.process_frame
	await t.process_frame
	var area := wv.viewport.get_visible_rect().size
	t.check(area == Vector2(853, 360), "the world viewport's canvas is the 853x360 area")
	var zoom := bf.camera.zoom.x
	var centre := bf.camera.get_screen_center_position()
	var ground_of := func(p: Vector2) -> Vector2: return Iso.screen_to_ground(centre + (p - area * 0.5) / zoom)
	var points := [area * 0.5, Vector2(0, 0), Vector2(852, 359), Vector2(100, 300), Vector2(700, 40)]
	for p: Vector2 in points:
		WorldView.test_mouse = p
		var got := bf.mouse_ground()
		var want: Vector2 = ground_of.call(p)
		t.check(got.is_equal_approx(want), "mouse_ground at %s is the ground under that screen point (%s vs %s)" % [p, got, want])
	WorldView.test_mouse = area * 0.5
	t.check(bf.mouse_ground().is_equal_approx(Iso.screen_to_ground(centre)), "the area's centre picks the camera's own ground point")
	WorldView.test_mouse = Vector2.INF
	UiScale.apply(UiScale.layout(Vector2i(640, 360)))
	_drop(wv)


## A real Mission (Warning, seed 7) hosted in a view on the root; the caller frees the view.
static func _hosted_mission(t) -> Array:
	City.use(&"aldermere")
	var wv: WorldView = await _view(t)
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	wv.host(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(PackedStringArray(["heaven", "tsunami", "cinder", "nova"]), 7)
	await t.process_frame
	return [wv, m]


## UI never lives in the world viewport (Task 2b invariant): only the world's own full-rect post ColorRects, on layers 1-5.
static func _no_ui_in_world(t) -> void:
	var made := await _hosted_mission(t)
	var wv: WorldView = made[0]
	var m: Mission = made[1]
	var stray := PackedStringArray()
	var layers := {}
	var stack: Array[Node] = [wv.viewport]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is CanvasLayer:
			layers[(n as CanvasLayer).layer] = true
		if n is Hud or n is FpsMeter or n is ZoomReadout or n is LegendPanel or n is MemoryOverlay or n is BehaviourOverlay or n is ArtToggle:
			stray.append("%s %s" % [n.get_class(), n.get_path()])
		elif n is Control:
			var c := n as Control
			var ok := c is ColorRect and c.mouse_filter == Control.MOUSE_FILTER_IGNORE and c.get_parent() is CanvasLayer \
				and c.anchor_right == 1.0 and c.anchor_bottom == 1.0
			if not ok:
				stray.append("%s %s" % [c.get_class(), c.get_path()])
	t.check(stray.is_empty(), "no UI node in the world viewport (found: %s)" % ", ".join(stray))
	var bad_layers := []
	for l: int in layers:
		if l < 1 or l > 5:
			bad_layers.append(l)
	t.check(bad_layers.is_empty(), "the world's canvas layers are all within 1-5 (found %s)" % str(layers.keys()))
	t.check(m._hud.get_parent() == m._bf.hud_layer and m._bf.hud_layer.get_parent() == wv.ui, "the HUD is in the view's ui")
	t.check(m._zoom_readout.get_parent() == wv.ui and m._overlay.get_parent() == wv.ui, "the zoom readout and the behaviour overlay are in the view's ui")
	t.check(m._hud.world_viewport == wv.viewport, "the HUD marks the world with the world viewport's camera")
	t.check(m.world_xf() == wv.viewport.get_canvas_transform(), "Mission.world_xf is the world camera's transform")
	m._bf.camera.position = Vector2(200, 100)
	m._bf.camera.zoom = Vector2.ONE * 1.5
	await t.process_frame
	t.check(m.world_xf() == wv.viewport.get_canvas_transform() and m.world_xf() != m._hud.get_viewport().get_canvas_transform(),
		"the camera moves the world's transform and not the root's (the HUD must use the world's)")
	t.check(m._hud._world_xf() == m.world_xf(), "the HUD's tag transform follows the world camera")
	m.open_legend()
	t.check(m.legend_open() and m._legend.get_parent() == m._bf.hud_layer, "the legend opens in the HUD layer, outside the world viewport")
	m._legend.close()
	m._on_legend_closed()
	_drop(wv)


## Freezing: the pause menu and the legend freeze the Mission; the view's ui (HUD, readout, meters) freezes with it, the legend keeps
## running, and a frozen mission takes no forwarded input (the tree itself is never paused).
static func _frozen(t) -> void:
	var made := await _hosted_mission(t)
	var wv: WorldView = made[0]
	var m: Mission = made[1]
	t.check(not m.get_tree().paused, "the tree is not paused")
	m.set_frozen(true)
	t.check(m.process_mode == Node.PROCESS_MODE_DISABLED and wv.ui.process_mode == Node.PROCESS_MODE_DISABLED, "frozen: the mission and the view's ui are disabled")
	t.check(not m._hud.can_process() and not m._zoom_readout.can_process() and not m._bf.can_process(), "frozen: the HUD, the readout and the battlefield do not process")
	var before := m.ui_hidden
	wv._unhandled_input(_key(KEY_F1))
	t.check(m.ui_hidden == before, "frozen: a key forwarded by the view reaches no mission code")
	m.set_frozen(false)
	t.check(m.process_mode == Node.PROCESS_MODE_INHERIT and wv.ui.process_mode == Node.PROCESS_MODE_INHERIT and m._hud.can_process(), "unfrozen: all of it runs again")
	wv._unhandled_input(_key(KEY_F1))
	t.check(m.ui_hidden != before, "unfrozen: the same key through the view toggles the interface")
	m.set_ui_hidden(false)
	m.open_legend()
	t.check(m.legend_open() and m.process_mode == Node.PROCESS_MODE_DISABLED and wv.ui.process_mode == Node.PROCESS_MODE_DISABLED, "the legend freezes mission and ui")
	t.check(m._legend.can_process() and m._legend.process_mode == Node.PROCESS_MODE_ALWAYS, "the legend itself keeps running under the disabled ui")
	m._legend.close()
	m._on_legend_closed()
	t.check(wv.ui.process_mode == Node.PROCESS_MODE_INHERIT, "closing the legend thaws the ui")
	_drop(wv)


## Positional sound: an AudioStreamPlayer2D pans and attenuates only against viewports that are 2D listeners and share its World2D.
## The world viewport is the listener (the root owns another World2D and takes no part), so Sfx, FireSounds and AnimalVoices keep
## playing and panning once hosted. (How it sounds is by ear; this proves the engine's conditions for it hold.)
static func _positional_audio(t) -> void:
	var made := await _hosted_mission(t)
	var wv: WorldView = made[0]
	var m: Mission = made[1]
	var player := AudioStreamPlayer2D.new()
	m._bf.add_child(player)
	t.check(player.get_viewport() == wv.viewport, "a world player's viewport is the world viewport")
	t.check(wv.viewport.is_audio_listener_2d(), "the world viewport is a 2D audio listener")
	t.check(player.get_viewport().find_world_2d() == wv.viewport.find_world_2d() and wv.viewport.find_world_2d() != m.get_tree().root.find_world_2d(),
		"the player and the listener share the world viewport's own World2D, which is not the root's")
	t.check(wv.viewport.get_camera_2d() == m._bf.camera, "the listener's centre is the world camera (Sfx also pans from it)")
	player.queue_free()
	# The ear itself (Task 10): a steady tone on a probe bus with a capture effect; the left/right energy says where the engine put it.
	var cam: CameraShake = m._bf.camera
	var bus_idx := AudioServer.bus_count
	AudioServer.add_bus(bus_idx)
	AudioServer.set_bus_name(bus_idx, &"PanProbe")
	var cap := AudioEffectCapture.new()
	cap.buffer_length = 0.5
	AudioServer.add_bus_effect(bus_idx, cap)
	m.process_mode = Node.PROCESS_MODE_DISABLED  # the mission steers the camera every frame; hold it where the probe puts it (the probe's sources live outside this subtree)
	var results := {}
	for row in [["left", -250.0, 0.0], ["right", 250.0, 0.0], ["centre", 0.0, 0.0], ["follow_left", 250.0, 500.0], ["follow_right", 250.0, -500.0]]:
		cam.position = Vector2(500.0, 300.0) + Vector2(float(row[2]), 0.0)
		await t.create_timer(0.05).timeout
		var src := AudioStreamPlayer2D.new()
		src.bus = &"PanProbe"
		src.stream = _tone()
		src.max_distance = 2000.0
		src.attenuation = 1.0
		wv.viewport.add_child(src)
		src.global_position = Vector2(500.0, 300.0) + Vector2(float(row[1]), 0.0)
		cap.clear_buffer()
		src.play()
		await t.create_timer(0.35).timeout
		var l := 0.0
		var r := 0.0
		var got := cap.get_frames_available()
		for fr in cap.get_buffer(got):
			l += absf(fr.x)
			r += absf(fr.y)
		results[row[0]] = [l, r, got]
		print("PAN %s: source %+.0f from the camera's start, camera at x %.0f: left %.3f right %.3f over %d frames" % [row[0], row[1], cam.position.x, l, r, got])
		src.queue_free()
	var lr: Array = results["left"]
	var rr: Array = results["right"]
	var cr: Array = results["centre"]
	t.check(lr[2] > 1000 and lr[0] + lr[1] > 1.0, "the probe heard the tone (%d frames)" % lr[2])
	t.check(lr[0] > lr[1] * 1.25, "a sound left of the camera pans left (L %.2f R %.2f)" % [lr[0], lr[1]])
	t.check(rr[1] > rr[0] * 1.25, "a sound right of the camera pans right (L %.2f R %.2f)" % [rr[0], rr[1]])
	t.check(absf(cr[0] - cr[1]) < 0.15 * maxf(cr[0], cr[1]), "a sound at the camera is centred (L %.2f R %.2f)" % [cr[0], cr[1]])
	# Same source, camera moved 500 px right (source now 250 left of the listener) and 500 px left (750 right of it): the pan follows the camera.
	var fl: Array = results["follow_left"]
	var fr2: Array = results["follow_right"]
	t.check(fl[0] > fl[1] * 1.25, "the camera moved right past the source: the source now pans left (L %.2f R %.2f)" % [fl[0], fl[1]])
	t.check(fr2[1] > fr2[0] * 1.25, "the camera moved left: the same source pans right (L %.2f R %.2f)" % [fr2[0], fr2[1]])
	AudioServer.remove_bus(bus_idx)
	_drop(wv)


## A mission moment's sound (MissionDirector._sound -> the FX context -> the battlefield's Sfx) plays on a player inside the world
## viewport, on the world's own World2D, so it pans against the camera's listener and not the root's.
static func _mission_sound_heard(t) -> void:
	var made := await _hosted_mission(t)
	var wv: WorldView = made[0]
	var m: Mission = made[1]
	var d := MissionDirector.new()
	d.ctx = m._bf.ctx
	d._sound(&"msn_door", Vector2(120, 80))
	var heard: AudioStreamPlayer2D = null
	for p in m._bf.get_node("Sfx").get_children():
		if p is AudioStreamPlayer2D and p.has_meta(&"cue") and p.get_meta(&"cue") == &"msn_door":
			heard = p
	t.check(heard != null, "a mission moment's cue is played through the battlefield's Sfx")
	if heard != null:
		t.check(heard.get_viewport() == wv.viewport and heard.is_inside_tree(), "its player lives in the world viewport, not the root or the ui")
		t.check(heard.get_viewport().find_world_2d() == wv.viewport.find_world_2d() and wv.ui.get_viewport() != wv.viewport,
			"it shares the listener's World2D; the ui is outside it")
		t.check(heard.playing and heard.position.is_equal_approx(Iso.ground_to_screen(Vector2(120, 80))), "it is playing at the moment's place")
	_drop(wv)


## 0.5 s of a 440 Hz tone, mono 16-bit, for the pan probe.
static func _tone() -> AudioStreamWAV:
	var rate := 22050
	var data := PackedByteArray()
	data.resize(rate)  # 0.5 s of 16-bit mono
	for i in rate / 2:
		data.encode_s16(i * 2, int(sin(TAU * 440.0 * float(i) / float(rate)) * 12000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


## Hosting call sites (carry-over from the 2b review): add_hosted in both modes, the title's backdrop, and a view that goes with its world.
static func _add_hosted(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var holder := Node.new()
	tree.root.add_child(holder)
	var plain := Node2D.new()
	t.check(WorldView.add_hosted(holder, plain) == null and plain.get_parent() == holder, "headless: add_hosted returns null and parents straight")
	holder.remove_child(plain)
	plain.free()
	var ready_in := []
	var probe := ReadyProbe.new()
	probe.log_into = ready_in
	var wv := WorldView.add_hosted(holder, probe, true)
	await t.process_frame
	t.check(wv != null and wv.get_parent() == holder and probe.get_parent() == wv.viewport, "forced: a view under the parent, the node in its viewport")
	t.check(ready_in.size() == 1 and ready_in[0] == wv.viewport, "the node's _ready ran inside the world viewport (the view was added first)")
	probe.queue_free()
	await t.process_frame
	await t.process_frame
	t.check(not is_instance_valid(wv), "freeing the hosted node frees its view (and its ui) with it, as Game's per-mission view does")
	holder.get_parent().remove_child(holder)
	holder.free()


class ReadyProbe extends Node2D:
	var log_into: Array

	func _ready() -> void:
		log_into.append(get_viewport())


static func _title(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	WorldView.test_host = true
	var title := TitleScreen.new()
	tree.root.add_child(title)
	title.setup(0, "")
	await t.process_frame
	var view: WorldView = null
	for c in title.get_children():
		if c is WorldView:
			view = c
	t.check(view != null and view.hosted() is Battlefield, "the title's backdrop battlefield is hosted")
	t.check(view != null and view.viewport.get_node_or_null("Town") != null and title.get_node_or_null("Town") == null, "the Town is in the world viewport, not the title")
	t.check(view != null and (view.hosted() as Battlefield).hud_layer.get_parent() == view.ui, "the backdrop's UI layers are in the view's ui")
	var had_view := view != null
	title.queue_free()
	for i in 3:
		await t.process_frame
	t.check(had_view and not is_instance_valid(view), "the view goes with the title")
	WorldView.test_host = false


static func run(t) -> void:
	await _hosting(t)
	await _bf_layers(t)
	await _keys(t)
	await _mouse_identity(t)
	await _sim_view_pinned(t)
	await _sim_independent(t)
	await _resize_reclamps(t)
	await _zoom_limit(t)
	await _picking(t)
	await _device_resolution(t)
	await _display_mapping(t)
	await _filters(t)
	await _self_host(t)
	await _no_ui_in_world(t)
	await _frozen(t)
	await _positional_audio(t)
	await _mission_sound_heard(t)
	await _add_hosted(t)
	await _title(t)
