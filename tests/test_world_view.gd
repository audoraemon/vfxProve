extends RefCounted
## UI resolution, Task 2a: WorldView hosts the world in a SubViewport; UI layers stay in the root; the sim view is pinned.


class KeyNode extends Node:
	var handled_keys := true
	var seen: InputEvent

	func _input(event: InputEvent) -> void:
		seen = event
		if handled_keys and event is InputEventKey:
			get_viewport().set_input_as_handled()


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
	n.handled_keys = true
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
	_drop(wv)


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
	Person.view = person
	Structure.view = structure
	_drop(wv)


static func run(t) -> void:
	await _hosting(t)
	await _bf_layers(t)
	await _keys(t)
	await _mouse_identity(t)
	await _sim_view_pinned(t)
