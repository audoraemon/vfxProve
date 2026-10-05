class_name EndingScreen
extends Node
## The campaign's ending (v0.10, spec §5.4): Cael's last memory first when the path has one (The Vision, before the
## Faith and Theft endings), then the ending's title, its epilogue and, for an ending with no playable last night yet,
## a note saying so. Enter or a click turns the page; on the last page it leaves for the title, as Esc always does.

## "title".
signal action(name: String)

const PANEL := Rect2(56.0, 40.0, 528.0, 280.0)
## The page's title baseline, the width its text wraps to, and the button's row.
const TITLE_Y := 100.0
const TEXT_W := 440.0
const BUTTON_Y := 288.0

## The pages in order: {title, text, note}.
var pages: Array[Dictionary] = []
var page := 0

var _ui: Control
var _menu: Menu
var _hover := ""


func setup(ending: String, fragment: String) -> EndingScreen:
	if fragment != "" and CampaignText.FRAGMENTS.has(fragment):
		pages.append(CampaignText.FRAGMENTS[fragment])
	pages.append(CampaignText.ENDINGS.get(ending, CampaignText.ENDINGS[CampaignDef.EATEN]))
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_build_menu()
	return self


## The next page, or the title from the last one.
func turn() -> void:
	if page < pages.size() - 1:
		page += 1
		_build_menu()
		_ui.queue_redraw()
		return
	action.emit("title")


func _build_menu() -> void:
	var last := page >= pages.size() - 1
	_menu = Menu.row(["next"], ["Title" if last else "Continue"], 320.0, BUTTON_Y, 120.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("title")
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			UiSound.play(&"ui_click")
			turn()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _menu.at(event.position) != "":
			UiSound.play(&"ui_click")
			turn()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.9))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.92))
	UiTheme.frame(_ui, PANEL, true)
	var p := pages[page]
	var title := String(p.get("title", ""))
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), TITLE_Y), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	var y := TITLE_Y + 36.0
	for line in UiTheme.wrap(String(p.get("text", "")), TEXT_W, UiTheme.SIZE_BODY):
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(line, UiTheme.SIZE_BODY) * 0.5), y), line, UiTheme.SIZE_BODY)
		y += UiTheme.LINE_BODY
	var note := String(p.get("note", ""))
	if note != "":
		y += 12.0
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(note, UiTheme.SIZE_SMALL) * 0.5), y), note,
			UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_menu.draw_on(_ui, _hover)
