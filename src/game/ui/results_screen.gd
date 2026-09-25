class_name ResultsScreen
extends Node
## Results (spec §5): the ending in gold for a win or red for a loss, the big rank letter, the score, NEW BEST!
## when it is one, the stat table with what each line was worth, and Replay / Change powers / Title. It is drawn
## over the mission's frozen ruins, which Game keeps up underneath it.

## "replay" (the same four powers again), "change" (back to the draft) or "title".
signal action(name: String)

const PANEL := Rect2(36.0, 20.0, 568.0, 320.0)
## The stat table's columns: label, value (right-aligned), points (right-aligned).
const TABLE_X := 300.0
const VALUE_R := 500.0
const POINTS_R := 588.0
const ROW := 14.0

var _result := {}
var _ui: Control
var _menu: Menu
var _hover := ""


## The line across the top for each way a mission can end.
static func title_for(won: bool, reason: String) -> String:
	if won:
		return "THE CITY HAS FALLEN"
	return "THE PEOPLE ESCAPED" if reason == "escapes" else "MANIFESTATION ENDED"


## 12450 -> "12,450".
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


func setup(result: Dictionary) -> ResultsScreen:
	_result = result
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.row(["replay", "change", "title"], ["Replay", "Change powers", "Title"], 320.0, PANEL.end.y - 28.0, 120.0)
	return self


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			action.emit("replay")
		elif event.physical_keycode == KEY_ESCAPE:
			action.emit("title")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a != "":
			action.emit(a)


func _draw_ui() -> void:
	var won := bool(_result.get("won", false))
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.5))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.9))
	UiTheme.frame(_ui, PANEL, true)

	var title := title_for(won, String(_result.get("reason", "")))
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 60.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD if won else UiTheme.COL_BAD)

	# The rank on the left, big, with the score beside it.
	var rank := String(_result.get("rank", "D"))
	UiTheme.text(_ui, Vector2(64.0, 162.0), rank, UiTheme.SIZE_HUGE, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(66.0, 176.0), "RANK", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(132.0, 102.0), "SCORE", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(130.0, 132.0), thousands(int(_result.get("score", 0))), UiTheme.SIZE_TITLE)
	if bool(_result.get("best", false)):
		UiTheme.text(_ui, Vector2(132.0, 154.0), "NEW BEST!", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)

	# The stat table: what happened, and what each line was worth.
	var y := 100.0
	var total := 0
	for line: Dictionary in _result.get("lines", []):
		var label := String(line.label)
		var value := String(line.value)
		var points := int(line.points)
		total += points
		UiTheme.text(_ui, Vector2(TABLE_X, y), label, UiTheme.SIZE_SMALL)
		if value != "":
			UiTheme.text(_ui, Vector2(VALUE_R - UiTheme.width(value, UiTheme.SIZE_SMALL), y), value, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		var pts := thousands(points)
		UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(pts, UiTheme.SIZE_SMALL), y), pts, UiTheme.SIZE_SMALL,
			UiTheme.COL_TEXT if points > 0 else UiTheme.COL_DIM)
		y += ROW
	_ui.draw_line(Vector2(TABLE_X, y - 7.0), Vector2(POINTS_R, y - 7.0), UiTheme.COL_GOLD_DARK, -1.0)
	var sum := thousands(total)
	UiTheme.text(_ui, Vector2(TABLE_X, y + 4.0), "Total", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(sum, UiTheme.SIZE_SMALL), y + 4.0), sum, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)

	_menu.draw_on(_ui, _hover)
