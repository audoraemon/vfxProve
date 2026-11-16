class_name MemoryOverlay
extends Node
## Remembrance's look and controls (Skill Tree wheel, Task 4): a pale vignette and a faint cool tint over the world (beneath the HUD), and
## over the HUD a top banner "REMEMBRANCE . <power> . Level n", a 1-5 level picker (keys 1-5 or a click; boxes above the power's top level
## dim), a DAY/NIGHT toggle (key N or a click) and the "Esc . pause" hint. It only reports: level_picked(level) and night_toggled(night);
## Mission acts on them. Remembrance's blue is the only blue the tree uses.

signal level_picked(level: int)
signal night_toggled(night: bool)

const COL_BLUE := Color("6fa8c8")
const COL_PALE := Color(0.82, 0.9, 0.97)
const BOX := Vector2(18.0, 16.0)
const BOX_GAP := 3.0
const PICKER_Y := 26.0
## The DAY/NIGHT toggle on a 640 x 360 screen: night_rect() moves it to the middle of a wider area, like the picker.
const NIGHT_RECT := Rect2(404.0, 26.0, 74.0, 16.0)
## The top banner's plate, and the "Esc . pause" hint's margin from the right edge.
const BANNER_H := 18.0
const HINT_MARGIN := 8.0
## Layers: the memory's tint sits under the HUD (layer 6), its controls over it.
const WORLD_LAYER := 5
const CONTROL_LAYER := 7
const VIGNETTE_STEPS := 14

var power_name := ""
## The power's top level (1 for a power without level tables).
var max_level := 1
var level := 1
var night := false

var _world: Control
var _ui: Control


func setup(p_power_name: String, p_max_level: int, p_level: int, p_night: bool) -> MemoryOverlay:
	power_name = p_power_name
	max_level = clampi(p_max_level, 1, PowerBook.MAX_LEVEL)
	level = clampi(p_level, 1, max_level)
	night = p_night
	name = "MemoryOverlay"
	var under := CanvasLayer.new()
	under.layer = WORLD_LAYER
	add_child(under)
	_world = _full_rect()
	_world.draw.connect(_draw_world)
	under.add_child(_world)
	var over := CanvasLayer.new()
	over.layer = CONTROL_LAYER
	add_child(over)
	_ui = _full_rect()
	_ui.draw.connect(_draw_ui)
	over.add_child(_ui)
	return self


func _full_rect() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## The banner's text.
func banner_text() -> String:
	return "REMEMBRANCE . %s . Level %d" % [power_name, level]


## The picker's box for level `n` (1-5), left to right, centred on the area (`area` defaults to the UI's).
static func box_rect(n: int, area := Vector2.ZERO) -> Rect2:
	var total := PowerBook.MAX_LEVEL * BOX.x + (PowerBook.MAX_LEVEL - 1) * BOX_GAP
	var design := Rect2(Vector2(320.0 - total * 0.5 + (n - 1) * (BOX.x + BOX_GAP), PICKER_Y), BOX)
	return UiScale.anchor(design, UiScale.Anchor.TOP, area)


## The DAY/NIGHT toggle's rectangle, next to the picker (`area` defaults to the UI's).
static func night_rect(area := Vector2.ZERO) -> Rect2:
	return UiScale.anchor(NIGHT_RECT, UiScale.Anchor.TOP, area)


## Picks level `n`: false (nothing sent) when it is above the power's top level.
func pick(n: int) -> bool:
	if n < 1 or n > max_level:
		return false
	level = n
	level_picked.emit(n)
	_redraw()
	return true


## Sets the shown level without telling anyone (Mission keeps it in step).
func set_level(n: int) -> void:
	level = clampi(n, 1, max_level)
	_redraw()


func toggle_night() -> void:
	night = not night
	night_toggled.emit(night)
	_redraw()


## A key; true when the overlay took it (1-5 always, so a level key never also picks the slot; N).
func press(code: Key) -> bool:
	if code >= KEY_1 and code <= KEY_5:
		pick(code - KEY_1 + 1)
		return true
	if code == KEY_N:
		toggle_night()
		return true
	return false


## A left click at `at`; true when it landed on a box or the toggle.
func click(at: Vector2) -> bool:
	for n in range(1, PowerBook.MAX_LEVEL + 1):
		if box_rect(n).has_point(at):
			pick(n)
			return true
	if night_rect().has_point(at):
		toggle_night()
		return true
	return false


func _input(event: InputEvent) -> void:
	var took := false
	if event is InputEventKey and event.pressed and not event.echo:
		took = press(event.physical_keycode)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		took = click(event.position)
	if took and is_inside_tree():
		get_viewport().set_input_as_handled()


func _redraw() -> void:
	if is_instance_valid(_ui):
		_ui.queue_redraw()


func _draw_world() -> void:
	var size := _world.size if _world.size.x > 1.0 else UiScale.area()
	_world.draw_rect(Rect2(Vector2.ZERO, size), Color(0.6, 0.72, 0.85, 0.16))
	for i in VIGNETTE_STEPS:
		var a := 0.42 * pow(1.0 - float(i) / VIGNETTE_STEPS, 2.0)
		var edge := float(i) * 3.0
		var c := Color(COL_PALE.r, COL_PALE.g, COL_PALE.b, a)
		_world.draw_rect(Rect2(edge, edge, size.x - edge * 2.0, size.y - edge * 2.0), c, false, 3.0)


func _draw_ui() -> void:
	var text := banner_text()
	var area := _ui.size if _ui.size.x > 1.0 else UiScale.area()
	var w := UiTheme.width(text, UiTheme.TEXT_S) + 24.0
	var plate := Rect2(roundf(area.x * 0.5 - w * 0.5), 4.0, w, BANNER_H)
	_ui.draw_rect(plate, Color(0.05, 0.09, 0.14, 0.78))
	_ui.draw_rect(plate, COL_BLUE, false, 1.0)
	UiTheme.text(_ui, Vector2(plate.position.x + 12.0, plate.position.y + 13.0), text, UiTheme.TEXT_S, COL_BLUE)
	for n in range(1, PowerBook.MAX_LEVEL + 1):
		var r := box_rect(n, area)
		var open := n <= max_level
		var chosen := n == level
		_ui.draw_rect(r, Color(0.05, 0.09, 0.14, 0.78) if open else Color(0.05, 0.05, 0.07, 0.5))
		var edge := COL_BLUE if open else Color(0.3, 0.33, 0.38, 0.6)
		_ui.draw_rect(r, edge, false, 1.0)
		if chosen:
			_ui.draw_rect(r.grow(-2.0), Color(COL_BLUE.r, COL_BLUE.g, COL_BLUE.b, 0.5))
		var label := str(n)
		var col := UiTheme.COL_TEXT if open else UiTheme.COL_DIM
		UiTheme.text(_ui, r.position + Vector2((r.size.x - UiTheme.width(label, UiTheme.TEXT_S)) * 0.5, 12.0), label, UiTheme.TEXT_S, col)
	var night_box := night_rect(area)
	_ui.draw_rect(night_box, Color(0.05, 0.09, 0.14, 0.78))
	_ui.draw_rect(night_box, COL_BLUE, false, 1.0)
	var look := "N . %s" % ("NIGHT" if night else "DAY")
	UiTheme.text(_ui, night_box.position + Vector2((night_box.size.x - UiTheme.width(look, UiTheme.TEXT_S)) * 0.5, 12.0), look, UiTheme.TEXT_S, UiTheme.COL_TEXT)
	var leave := "Esc . pause"
	var leave_w := UiTheme.width(leave, UiTheme.TEXT_S)
	_ui.draw_rect(Rect2(area.x - HINT_MARGIN - leave_w - 4.0, 4.0, leave_w + 8.0, BANNER_H), Color(0.05, 0.09, 0.14, 0.78))  # a plate: the hint reads over any ground
	UiTheme.text(_ui, Vector2(area.x - HINT_MARGIN - leave_w, 17.0), leave, UiTheme.TEXT_S, UiTheme.COL_DIM)
