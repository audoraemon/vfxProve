class_name SlotScreen
extends Node
## The slot select (god P1, spec §4 and §12): three save slots, one god each. An empty slot offers New; a filled one shows its god's
## type, level, tier and night and offers Continue, New and Delete. New over a god and Delete both ask first ("It cannot be undone");
## Esc cancels a question, else goes back. The screen only reports the choice: Game makes, reads and writes the god (a damaged file
## reads as an empty slot, and New still asks before it replaces one: Ruling P23). Delete removes the file only on Confirm.

## "continue", "new" (a slot is chosen for a new god) or "back". `chosen` (1-3) names the slot for the first two.
signal action(name: String)

## One slot's row: the three rows stack down the screen, each holding its line on the left and its buttons on the right.
const SLOT_X := 20.0
const SLOT_Y := 48.0
const SLOT_SIZE := Vector2(600.0, 72.0)
const SLOT_STEP := 84.0
## A slot button's size, and where the first one starts inside its row (Continue; an empty slot's New takes the same place).
const BUTTON_SIZE := Vector2(88.0, 28.0)
const BUTTON_AT := Vector2(308.0, 22.0)
const BUTTON_STEP := 96.0
const BACK_RECT := Rect2(8.0, 322.0, 100.0, 20.0)
## The question panel over the screen, and its two buttons.
const CONFIRM_PANEL := Rect2(120.0, 128.0, 400.0, 104.0)
const CONFIRM_RECT := Rect2(200.0, 190.0, 100.0, 28.0)
const CANCEL_RECT := Rect2(340.0, 190.0, 100.0, 28.0)
## The two questions *(my call)*.
const ASK_OVERWRITE := "Overwrite this god? It cannot be undone."
const ASK_DELETE := "Delete this god? It cannot be undone."

## The slot (1-3) the last Continue or New chose; 0 before any.
var chosen := 0
## The open question: "new" (overwrite), "delete" or "" for none; and the slot (0-2) it is about.
var pending := ""
var pending_slot := -1
var _base := GodSlot.PATH_BASE
var _ui: Control
var _hover := ""


func setup(base := GodSlot.PATH_BASE) -> SlotScreen:
	_base = base
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## Slot `i`'s row (0-2).
static func slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(SLOT_X, SLOT_Y + SLOT_STEP * float(i)), SLOT_SIZE)


## The god in slot `i` (0-2), or null when empty or unreadable. Read from the file each time, so a screen never shows a stale slot.
func god(i: int) -> GodSlot:
	return GodSlot.read(GodSlot.path(i + 1, _base))


## True when slot `i` has a file at all, readable or not: New must ask before it replaces a damaged one (Ruling P23).
func has_file(i: int) -> bool:
	return FileAccess.file_exists(GodSlot.path(i + 1, _base))


## What slot `i` says: "Empty", or the type's title, level, tier and night (counted from 1) (spec §12).
func slot_line(i: int) -> String:
	var g := god(i)
	if g == null:
		return "Empty"
	return "%s   Level %d   %s   Night %d" % [PowerBook.authority_title(g.type), g.level, TierBook.tier_name(g.tier), g.night + 1]


## Where slot `i`'s button `what` ("continue", "new" or "delete") is drawn; an empty Rect2 for one the slot does not have.
func button_rect(i: int, what: String) -> Rect2:
	var filled := god(i) != null
	var column := -1
	match what:
		"continue":
			column = 0 if filled else -1
		"new":
			column = 1 if filled else 0
		"delete":
			column = 2 if filled else -1
	if column < 0 or i < 0 or i >= GodSlot.COUNT:
		return Rect2()
	return Rect2(slot_rect(i).position + BUTTON_AT + Vector2(BUTTON_STEP * float(column), 0.0), BUTTON_SIZE)


## What is under a point: "<what>:<i>" for a slot button, "back:0", or while a question is open only "confirm:0" and "cancel:0".
func hit(point: Vector2) -> String:
	if pending != "":
		if CONFIRM_RECT.has_point(point):
			return "confirm:0"
		if CANCEL_RECT.has_point(point):
			return "cancel:0"
		return ""
	for i in GodSlot.COUNT:
		for what in ["continue", "new", "delete"]:
			if button_rect(i, what).has_point(point):
				return "%s:%d" % [what, i]
	if BACK_RECT.has_point(point):
		return "back:0"
	return ""


## A left click at a screen point.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	var parts := h.split(":")
	var i := int(parts[1])
	UiSound.play(&"ui_click")
	match parts[0]:
		"continue":
			chosen = i + 1
			action.emit("continue")
		"new":
			if has_file(i):
				_ask("new", i)
			else:
				chosen = i + 1
				action.emit("new")
		"delete":
			_ask("delete", i)
		"confirm":
			confirm()
		"cancel":
			cancel()
		"back":
			action.emit("back")


## The open question's text, or "".
func pending_text() -> String:
	match pending:
		"new":
			return ASK_OVERWRITE
		"delete":
			return ASK_DELETE
	return ""


## Confirm: Delete removes the slot's file; New over a god goes on to the type choice (Game replaces the file only once the new god
## is written).
func confirm() -> void:
	if pending == "":
		return
	var what := pending
	var i := pending_slot
	pending = ""
	pending_slot = -1
	if what == "delete":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GodSlot.path(i + 1, _base)))
		_redraw()
	else:
		chosen = i + 1
		action.emit("new")


## Cancel: closes the question and leaves the file alone.
func cancel() -> void:
	if pending == "":
		return
	pending = ""
	pending_slot = -1
	_redraw()


func _ask(what: String, i: int) -> void:
	pending = what
	pending_slot = i
	_redraw()


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		UiSound.play(&"ui_click")
		if pending != "":
			cancel()
		else:
			action.emit("back")


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
	UiTheme.text(_ui, Vector2(20, 30), "CHOOSE A SLOT", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	for i in GodSlot.COUNT:
		_draw_slot(i)
	_draw_button(BACK_RECT, "Back", "back:0")
	UiTheme.text(_ui, Vector2(BACK_RECT.end.x + 12.0, BACK_RECT.position.y + 14.0), "Esc goes back.", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	if pending != "":
		_draw_question()


## One slot's row: its number, its line, and its buttons.
func _draw_slot(i: int) -> void:
	var r := slot_rect(i)
	var g := god(i)
	_ui.draw_rect(r, UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, g != null)
	UiTheme.text(_ui, r.position + Vector2(12.0, 18.0), "Slot %d" % (i + 1), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	var line := slot_line(i)
	var room := BUTTON_AT.x - 20.0
	var size := UiTheme.SIZE_BODY if UiTheme.width(line, UiTheme.SIZE_BODY) <= room else UiTheme.SIZE_SMALL
	UiTheme.text(_ui, r.position + Vector2(12.0, 44.0), line, size, UiTheme.COL_TEXT if g != null else UiTheme.COL_DIM)
	for what in ["continue", "new", "delete"]:
		var b := button_rect(i, what)
		if b.has_area():
			_draw_button(b, String(what).capitalize(), "%s:%d" % [what, i])


func _draw_button(r: Rect2, label: String, what: String) -> void:
	var on := _hover == what and pending == ""
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if on else Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, r, on)
	UiTheme.text(_ui, Vector2(roundf(r.get_center().x - UiTheme.width(label) * 0.5), r.position.y + r.size.y * 0.5 + 5.0), label,
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD if on else UiTheme.COL_TEXT)


## The question over a dimmed screen, with Confirm and Cancel.
func _draw_question() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.6))
	_ui.draw_rect(CONFIRM_PANEL, Color(0.05, 0.05, 0.07, 0.97))
	UiTheme.frame(_ui, CONFIRM_PANEL, true)
	var lines := UiTheme.wrap(pending_text(), CONFIRM_PANEL.size.x - 32.0, UiTheme.SIZE_BODY)
	for k in lines.size():
		UiTheme.text(_ui, Vector2(roundf(CONFIRM_PANEL.get_center().x - UiTheme.width(lines[k]) * 0.5),
			CONFIRM_PANEL.position.y + 44.0 + UiTheme.LINE_BODY * float(k)), lines[k], UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
	for pair in [[CONFIRM_RECT, "Confirm", "confirm:0"], [CANCEL_RECT, "Cancel", "cancel:0"]]:
		var b: Rect2 = pair[0]
		var on: bool = _hover == pair[2]
		_ui.draw_rect(b, Color(0.1, 0.09, 0.07, 0.9) if on else Color(0.04, 0.04, 0.06, 0.85))
		UiTheme.frame(_ui, b, on)
		UiTheme.text(_ui, Vector2(roundf(b.get_center().x - UiTheme.width(pair[1]) * 0.5), b.position.y + b.size.y * 0.5 + 5.0), pair[1],
			UiTheme.SIZE_BODY, UiTheme.COL_GOLD if on else UiTheme.COL_TEXT)
