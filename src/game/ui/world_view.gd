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
## Everything under it freezes with the mission (`Mission.set_frozen` disables this subtree) unless it is PROCESS_MODE_ALWAYS,
## so a persistent node must not be parented here.
var ui: Node
## Tests only: host in a headless run too (the references and the suite leave it false). Always put it back.
static var test_host := false
## Tests only: a root mouse position (in area units) that `mouse_in_view` answers instead of the real mouse; INF = off. Always put it back.
static var test_mouse := Vector2.INF
var _hosted: Node
var _dying := false


func _init() -> void:
	name = "WorldView"
	viewport = SubViewport.new()
	viewport.name = "World"
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.snap_2d_vertices_to_pixel = true
	viewport.audio_listener_enable_2d = true  # the world's positional sound pans against this viewport, not the root
	viewport.size = Vector2i(UiScale.area())
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
	if is_inside_tree():
		UiScale.install(get_tree())  # idempotent; tools that host without a main scene of their own get the UI scale too
	if _hosted != null and is_instance_valid(_hosted) and _hosted.tree_exited.is_connected(_on_hosted_exited):
		_hosted.tree_exited.disconnect(_on_hosted_exited)  # one host per view: only the newest node's exit frees it (the old one stays in the viewport, the caller's to remove)
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


func _enter_tree() -> void:
	UiScale.notifier.changed.connect(_on_layout)
	_on_layout(UiScale.layout_now())


func _exit_tree() -> void:
	if UiScale.notifier.changed.is_connected(_on_layout):
		UiScale.notifier.changed.disconnect(_on_layout)


## The window changed: the world viewport (and the picture of it) takes the UI area, and every camera in it takes the new fit, keeping
## its logical zoom. The simulation reads neither (SIM_VIEW, logical zoom).
## The fit goes first: resizing the viewport emits its size_changed at once, and the hosted scene re-clamps its camera on it, which must
## see the new fit (the render zoom) together with the new size.
func _on_layout(lay: Dictionary) -> void:
	for cam in viewport.find_children("*", "CameraShake", true, false):
		(cam as CameraShake).set_view_fit(float(lay["fit"]))
	resize(Vector2i(lay["area"]))


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_dying = true


func _on_hosted_exited() -> void:
	if not _dying and not is_queued_for_deletion():
		queue_free()


## Input is forwarded only while the view processes (INHERIT), so a paused tree would starve the world of input, even a node set to
## PROCESS_MODE_ALWAYS. The game never pauses the tree: the pause menu and the legend freeze the Mission (`set_frozen`, process_mode
## DISABLED on its subtree), the view keeps forwarding and the frozen subtree simply takes none, as before hosting.
func _unhandled_input(event: InputEvent) -> void:
	viewport.push_input(event, true)
	if viewport.is_input_handled():
		get_viewport().set_input_as_handled()


## Whether this run hosts worlds in a view at all: never headless (the references and the suite run unhosted, the root is the world).
static func can_host() -> bool:
	return test_host or DisplayServer.get_name() != "headless"


## Put `node` under `parent`: inside a new WorldView added under `parent` when hosting is on (`can_host()`, or `force`), else straight
## under `parent` as before. The view is added first, so `node`'s _ready runs inside the world viewport. Returns the view, or null.
static func add_hosted(parent: Node, node: Node, force := false) -> WorldView:
	if not (can_host() or force):
		parent.add_child(node)
		return null
	var wv := WorldView.new()
	parent.add_child(wv)
	wv.host(node)
	return wv


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
	if test_mouse != Vector2.INF:
		return test_mouse
	var wv := of(world_node)
	if wv != null and wv.is_inside_tree():
		return wv.get_viewport().get_mouse_position()
	return world_node.get_viewport().get_mouse_position()


## Windowed main scenes (Mission, TownDebug, Sandbox) host themselves: reparent `node` into a new view added to the root,
## and make that view the current scene (so change_scene_* and reload_current_scene free the view and its world together;
## `hosted()` is the node). Contract: call this FIRST in `_ready` and return at once when it returns true; the node's _ready runs
## again after the (deferred) reparent, by request_ready(), and that second run finds it hosted (false) and builds as usual.
## False (nothing done) when headless (unless `force`, for tests), when `node` is not the current scene under the root, or when hosted.
static func self_host(node: Node, force := false) -> bool:
	if not node.is_inside_tree():
		return false
	var tree := node.get_tree()
	UiScale.install(tree)  # before the first frame, so --window sizes the window before anything is drawn
	if node.get_parent() != tree.root or tree.current_scene != node:
		return false
	if not (can_host() or force) or of(node) != null:
		return false
	node.request_ready()
	_reparent.call_deferred(node, tree)
	return true


static func _reparent(node: Node, tree: SceneTree) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var wv := WorldView.new()
	tree.root.add_child(wv)
	wv.host(node)
	tree.current_scene = wv
