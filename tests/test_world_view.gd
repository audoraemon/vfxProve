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


static func run(t) -> void:
	await _hosting(t)
	await _bf_layers(t)
	await _keys(t)
	await _mouse_identity(t)
	await _sim_view_pinned(t)
	await _self_host(t)
