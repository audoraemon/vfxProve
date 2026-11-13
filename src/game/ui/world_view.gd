class_name WorldView
extends Node
## Hosts a world (a Battlefield and what draws in it) in a SubViewport and shows it at the origin of the root with
## nearest filtering. The UI never lives in the world viewport: `ui` is the node the HUD, overlays and legend are
## parented to (they draw in the root, at full resolution once the root leaves viewport mode). Identity mapping: one UI unit
## is one world-viewport px, so a root mouse position is also the position in the world viewport. Headless runs never host.

## The world's own viewport; the hosted node is its child.
var viewport: SubViewport
## Shows the viewport's texture at the origin.
var display: TextureRect
## Parent of every UI node of the hosted world (hud_layer, FpsMeter, ArtToggle, ZoomReadout, overlays, legend).
var ui: Node
var _hosted: Node
var _dying := false


func _init() -> void:
	name = "WorldView"
	viewport = SubViewport.new()
	viewport.name = "World"
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.snap_2d_vertices_to_pixel = true
	viewport.size = Vector2i(640, 360)
	add_child(viewport)
	display = TextureRect.new()
	display.name = "Display"
	display.texture = viewport.get_texture()
	display.position = Vector2.ZERO
	display.size = Vector2(viewport.size)
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	ui = Node.new()
	ui.name = "Ui"
	add_child(ui)


## Put `node` in the world viewport. The view frees itself (and its ui subtree) when the hosted node leaves the tree.
func host(node: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	viewport.add_child(node)
	_hosted = node
	node.tree_exited.connect(_on_hosted_exited, CONNECT_ONE_SHOT)


func hosted() -> Node:
	return _hosted


func resize(area: Vector2i) -> void:
	viewport.size = area
	display.size = Vector2(area)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_dying = true


func _on_hosted_exited() -> void:
	if not _dying and not is_queued_for_deletion():
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	viewport.push_input(event, true)
	if viewport.is_input_handled():
		get_viewport().set_input_as_handled()


## The view hosting `node`, or null (not hosted).
static func of(node: Node) -> WorldView:
	var p := node.get_parent() if node != null else null
	while p != null:
		if p is WorldView:
			return p
		p = p.get_parent()
	return null


## Where UI for `node`'s world goes: the view's ui node when hosted, else `node` itself.
static func ui_parent(node: Node) -> Node:
	var wv := of(node)
	return wv.ui if wv != null else node


## The camera's canvas transform of a world viewport (ground-side drawing to world-viewport px).
static func world_xf(world: Viewport) -> Transform2D:
	return world.get_canvas_transform()


## The mouse in world-viewport px: the root's mouse when hosted (identity mapping), else the node's own viewport's.
static func mouse_in_view(world_node: Node) -> Vector2:
	var wv := of(world_node)
	if wv != null and wv.is_inside_tree():
		return wv.get_viewport().get_mouse_position()
	return world_node.get_viewport().get_mouse_position()


## Windowed main scenes (Mission, TownDebug, Sandbox) host themselves: reparent `node` into a new view added to the root.
## False (nothing done) when headless, when `node` is not the current scene under the root, or when already hosted.
static func self_host(node: Node) -> bool:
	var tree := node.get_tree()
	if tree == null or node.get_parent() != tree.root or tree.current_scene != node:
		return false
	if DisplayServer.get_name() == "headless" or of(node) != null:
		return false
	var wv := WorldView.new()
	tree.root.add_child.call_deferred(wv)
	node.request_ready()
	(func():
		if is_instance_valid(node) and is_instance_valid(wv):
			wv.host(node)
			tree.current_scene = node).call_deferred()
	return true
