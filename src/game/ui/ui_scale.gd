class_name UiScale
extends RefCounted
## The UI's size model (UI resolution spec §4, §5). One integer scale k for world and UI: k = max(1, floor(min(W/640, H/360))).
## A "UI unit" is k device px; the UI area is floor(window / k) units, 640x360 in headless runs and until the root is expanded.
## Menus keep their 640x360 layout constants in a "design frame" centred in the area; the HUD anchors to the area's edges.
## All statics. Task 3a: the model, anchoring and frames; `apply()` is how the root's size will reach it (UiScale.install, in 3b).

const DESIGN := Vector2i(640, 360)
## The widest the visible world may be, in reference px (21:9), and the height it is measured against.
const MAX_WORLD_W := 840.0
const REF_H := 360.0

enum Anchor { TOP_LEFT, TOP, TOP_RIGHT, LEFT, CENTRE, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT }

## Emits `changed(layout)` after every apply().
static var notifier := UiScaleNotifier.new()

static var _layout := {"k": 1, "area": DESIGN, "offset": Vector2i.ZERO, "fit": 1.0}
static var _test_area := Vector2i.ZERO


## The pure table: for a window in device px, the integer scale, the UI area in units, the design frame's offset in the area
## and the camera fit (render zoom = logical zoom x fit) that keeps the visible world within 840x360 reference px.
static func layout(window: Vector2i) -> Dictionary:
	var k := maxi(1, floori(minf(window.x / float(DESIGN.x), window.y / float(DESIGN.y))))
	var area := Vector2i(floori(window.x / float(k)), floori(window.y / float(k)))
	var offset := Vector2i(floori((area.x - DESIGN.x) / 2.0), floori((area.y - DESIGN.y) / 2.0))
	var fit := maxf(area.x / MAX_WORLD_W, area.y / REF_H)
	return {"k": k, "area": area, "offset": offset, "fit": fit}


## Whether the root is expanded to the whole window (Task 9). Until then the area stays 640x360 and Godot's own integer scaling
## (aspect "keep") centres the frame; k is the real integer scale either way.
const EXPAND_ON := false

static var _installed := false


## Once per process, no-op in headless runs: applies `--window=WxH` (a borderless window of that size at the screen's origin,
## before the first frame), gives the root the design size (aspect "keep" and scale mode "integer" come from project.godot) and follows
## the root's size from then on. Call it first in a windowed main scene's _ready.
static func install(tree: SceneTree) -> void:
	if _installed or DisplayServer.get_name() == "headless":
		return
	_installed = true
	var root := tree.root
	var want := window_arg(OS.get_cmdline_user_args())
	if want != Vector2i.ZERO:
		root.mode = Window.MODE_WINDOWED
		root.borderless = true
		root.size = want
		root.position = Vector2i.ZERO
	root.content_scale_size = DESIGN
	root.size_changed.connect(_follow_root.bind(root))
	_follow_root(root)


## `--window=WxH` from the user args, or (0, 0).
static func window_arg(args: PackedStringArray) -> Vector2i:
	for a in args:
		if a.begins_with("--window="):
			var parts := a.substr(9).to_lower().split("x")
			if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int() and parts[0].to_int() > 0 and parts[1].to_int() > 0:
				return Vector2i(parts[0].to_int(), parts[1].to_int())
	return Vector2i.ZERO


## The layout the game uses for a window: layout(), but with the area, offset and fit of an unexpanded root until EXPAND_ON.
static func effective(window: Vector2i) -> Dictionary:
	var lay := layout(window)
	if not EXPAND_ON:
		lay["area"] = DESIGN
		lay["offset"] = Vector2i.ZERO
		lay["fit"] = 1.0
	return lay


static func _follow_root(root: Window) -> void:
	var lay := effective(root.size)
	if EXPAND_ON:
		root.content_scale_size = lay["area"]
	apply(lay)


## Make `lay` (a layout() result) the current one and tell the listeners.
static func apply(lay: Dictionary) -> void:
	_layout = lay
	notifier.changed.emit(lay)


static func k() -> int:
	return _layout["k"]


## The UI area in units: 640x360 when not installed, headless, or before the root is expanded.
static func area() -> Vector2:
	if _test_area != Vector2i.ZERO:
		return Vector2(_test_area)
	return Vector2(_layout["area"])


static func fit() -> float:
	return _layout["fit"]


## Where the 640x360 design frame sits in the area.
static func design_offset() -> Vector2:
	return ((area() - Vector2(DESIGN)) / 2.0).floor()


## Headless tests of other areas (800x450): area(), design_offset(), anchor() and design_frame() use it. Always clear it again.
## It changes only those four: k() and fit() still answer for the applied layout (fit is 1.0 at a test area of 800x450, not the real 1.25).
static func set_test_area(a: Vector2i) -> void:
	_test_area = a


static func clear_test_area() -> void:
	_test_area = Vector2i.ZERO


## `design_rect`, laid out for 640x360, moved to the area by its edge: left/top edges stay, right/bottom edges follow the area's,
## centred ones shift by half. The identity when the area is 640x360. `in_area` defaults to area() (the Hud passes its own view).
static func anchor(design_rect: Rect2, where: int, in_area := Vector2.ZERO) -> Rect2:
	var a := in_area if in_area != Vector2.ZERO else area()
	var d := a - Vector2(DESIGN)
	var shift := Vector2.ZERO
	match where:
		Anchor.TOP: shift.x = floorf(d.x / 2.0)
		Anchor.TOP_RIGHT: shift.x = d.x
		Anchor.LEFT: shift.y = floorf(d.y / 2.0)
		Anchor.CENTRE: shift = (d / 2.0).floor()
		Anchor.RIGHT: shift = Vector2(d.x, floorf(d.y / 2.0))
		Anchor.BOTTOM_LEFT: shift.y = d.y
		Anchor.BOTTOM: shift = Vector2(floorf(d.x / 2.0), d.y)
		Anchor.BOTTOM_RIGHT: shift = d
	return Rect2(design_rect.position + shift, design_rect.size)


## A point snapped to the device pixel grid (units are k device px).
static func snap(p: Vector2) -> Vector2:
	var kk := float(k())
	return (p * kk).round() / kk


## A screen's frame: a full-area Control (the blocker: `filter` is its mouse_filter, STOP for modal screens) on `layer`, holding a
## 640x360 child at design_offset(). Returns the child: the screen draws on it and takes gui_input from it, in today's 640x360
## coordinates. Its parent is the blocker. Follows `notifier.changed` while it lives.
static func design_frame(layer: CanvasLayer, filter: int) -> Control:
	var blocker := Control.new()
	blocker.name = "Blocker"
	blocker.mouse_filter = filter
	var child := Control.new()
	child.name = "Design"
	child.mouse_filter = filter
	blocker.add_child(child)
	var follower := FrameFollower.new()
	follower.blocker = blocker
	follower.child = child
	blocker.add_child(follower)
	_place(blocker, child)
	layer.add_child(blocker)
	return child


## The whole area in `frame`'s local coordinates (a design frame): what a backdrop or dimmer fills.
static func backdrop(frame: Control) -> Rect2:
	return Rect2(-frame.position, area())


static func _place(blocker: Control, child: Control) -> void:
	blocker.position = Vector2.ZERO
	blocker.size = area()
	child.position = design_offset()
	child.size = Vector2(DESIGN)
	blocker.queue_redraw()
	child.queue_redraw()


## Re-places a frame when the layout changes; connected only while it is in the tree.
class FrameFollower extends Node:
	var blocker: Control
	var child: Control

	func _enter_tree() -> void:
		UiScale.notifier.changed.connect(_on_changed)

	func _exit_tree() -> void:
		if UiScale.notifier.changed.is_connected(_on_changed):
			UiScale.notifier.changed.disconnect(_on_changed)

	func _on_changed(_lay: Dictionary) -> void:
		UiScale._place(blocker, child)
