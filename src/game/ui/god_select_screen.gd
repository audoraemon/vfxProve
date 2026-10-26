class_name GodSelectScreen
extends Node
## The god select (god P1, spec §4 and §12): the ring of six types, drawn as six boxes on an ellipse with RING[0] at the top and the
## rest clockwise. The selected type shows in the middle its name, one line of flavour, its two Tier 1 spots ("Not yet chosen" while
## the tree is empty) and its two neighbours. Choose, or Enter, picks it -- once, for the slot being made (spec §4) -- and Esc or Back
## goes back. The screen only reports; Game makes the god.

## "chosen" (`chosen_type` is the type) or "back".
signal action(name: String)

## The ring's centre, its half-width and half-height, and one type's box.
const CENTRE := Vector2(320.0, 172.0)
const RADIUS := Vector2(220.0, 100.0)
const BOX := Vector2(104.0, 30.0)
## The middle panel the selected type's lines are drawn in: it sits inside the ring, clear of the six boxes.
const INFO_RECT := Rect2(192.0, 98.0, 256.0, 156.0)
const CHOOSE_RECT := Rect2(270.0, 296.0, 100.0, 22.0)
const BACK_RECT := Rect2(8.0, 322.0, 100.0, 20.0)

## The type chosen by confirm(), or "".
var chosen_type := ""
## The ring position (0-5) in the middle panel; clicks and Left/Right move it.
var selected := 0
var _ui: Control
var _hover := ""


func setup() -> GodSelectScreen:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## Type `i`'s box (0-5): on an ellipse around CENTRE, RING[0] at the top, then clockwise in 60 degree steps.
static func ring_rect(i: int) -> Rect2:
	var angle := deg_to_rad(-90.0 + 60.0 * float(i))
	var at := CENTRE + Vector2(cos(angle) * RADIUS.x, sin(angle) * RADIUS.y)
	return Rect2((at - BOX * 0.5).round(), BOX)


## What the middle panel says of a type: its title, its flavour line, its Tier 1 spots' power names (or "Not yet chosen"), and its
## neighbours. Empty for a type that is not on the ring.
func type_lines(type: String) -> PackedStringArray:
	if not GodTree.RING.has(type):
		return PackedStringArray()
	var names := PackedStringArray()
	for i in GodTree.PER_TIER:
		var key := GodTree.spot(type, 1, i)
		names.append(String(PowerBook.get_power(key).name) if key != "" else GodTree.NOT_CHOSEN)
	var beside := PackedStringArray()
	for n in GodTree.neighbours(type):
		beside.append(PowerBook.authority_title(n))
	return PackedStringArray([PowerBook.authority_title(type), String(GodTree.FLAVOUR.get(type, "")),
		"Tier 1: %s" % ", ".join(names), "Neighbours: %s" % ", ".join(beside)])


## Puts the middle panel on ring position `i` (0-5); it does not choose.
func select(i: int) -> void:
	selected = clampi(i, 0, GodTree.RING.size() - 1)
	_redraw()


## Chooses the selected type: `chosen_type` is set and "chosen" is emitted.
func confirm() -> void:
	chosen_type = GodTree.RING[selected]
	UiSound.play(&"ui_manifest")
	action.emit("chosen")


## What is under a point: "ring:<i>", "choose:0", "back:0" or "".
func hit(point: Vector2) -> String:
	for i in GodTree.RING.size():
		if ring_rect(i).has_point(point):
			return "ring:%d" % i
	if CHOOSE_RECT.has_point(point):
		return "choose:0"
	if BACK_RECT.has_point(point):
		return "back:0"
	return ""


## A left click at a screen point.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	var parts := h.split(":")
	match parts[0]:
		"ring":
			UiSound.play(&"ui_click")
			select(int(parts[1]))
		"choose":
			confirm()
		"back":
			UiSound.play(&"ui_click")
			action.emit("back")


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("back")
		KEY_LEFT:
			UiSound.play(&"ui_hover")
			select((selected + GodTree.RING.size() - 1) % GodTree.RING.size())
		KEY_RIGHT:
			UiSound.play(&"ui_hover")
			select((selected + 1) % GodTree.RING.size())
		KEY_ENTER, KEY_KP_ENTER:
			confirm()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(20, 30), "CHOOSE YOUR GOD", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var note := "A god's type is chosen once, for this slot."
	UiTheme.text(_ui, Vector2(620.0 - UiTheme.width(note, UiTheme.SIZE_SMALL), 30.0), note, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	for i in GodTree.RING.size():
		var r := ring_rect(i)
		var on := i == selected
		var hot := _hover == "ring:%d" % i
		_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if on or hot else UiTheme.COL_PANEL)
		UiTheme.frame(_ui, r, on or hot)
		var title := PowerBook.authority_title(GodTree.RING[i])
		UiTheme.text(_ui, Vector2(roundf(r.get_center().x - UiTheme.width(title) * 0.5), r.position.y + 20.0), title, UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD if on else UiTheme.COL_TEXT)
	_draw_info()
	var choose_on := _hover == "choose:0"
	_ui.draw_rect(CHOOSE_RECT, Color(0.1, 0.09, 0.07, 0.9) if choose_on else Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, CHOOSE_RECT, choose_on)
	UiTheme.text(_ui, Vector2(roundf(CHOOSE_RECT.get_center().x - UiTheme.width("Choose") * 0.5), CHOOSE_RECT.position.y + 16.0), "Choose",
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back:0")
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width("Back") * 0.5), BACK_RECT.position.y + 14.0), "Back",
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back:0" else UiTheme.COL_TEXT)
	UiTheme.text(_ui, Vector2(BACK_RECT.end.x + 12.0, BACK_RECT.position.y + 14.0), "Left and Right look round the ring. Enter chooses. Esc goes back.",
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## The selected type's four lines, centred in the middle panel and wrapped to it.
func _draw_info() -> void:
	var lines := type_lines(GodTree.RING[selected])
	var x := INFO_RECT.get_center().x
	var y := INFO_RECT.position.y + 20.0
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(lines[0], UiTheme.SIZE_BIG) * 0.5), y), lines[0], UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	y += 22.0
	for row in UiTheme.wrap(lines[1], INFO_RECT.size.x, UiTheme.SIZE_BODY):
		UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row) * 0.5), y), row, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY
	y += 12.0
	for k in [2, 3]:
		for row in UiTheme.wrap(lines[k], INFO_RECT.size.x, UiTheme.SIZE_SMALL):
			UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row, UiTheme.SIZE_SMALL) * 0.5), y), row, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
			y += UiTheme.LINE_SMALL + 2.0
