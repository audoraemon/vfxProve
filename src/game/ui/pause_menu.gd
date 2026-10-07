class_name PauseMenu
extends Node
## Pause (spec §1): the mission frozen underneath, and Resume, Restart, Change powers, Missions. Esc resumes, the
## way it paused. This node lives beside the mission, not inside it, so it keeps running while the mission is
## switched off.

## "resume", "restart" (a new mission with the same four powers), "change" (back to the draft), "missions" (the
## mission board, v0.08) or, in a campaign, "campaign" (its night screen, v0.10).
signal action(name: String)

var _ui: Control
var _menu: Menu
var _hover := ""


## `campaign` (v0.10): the last button leads back to the campaign's night screen instead of the board.
func setup(campaign := false) -> PauseMenu:
	var layer := CanvasLayer.new()
	layer.layer = 20  # over the HUD
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.column(["resume", "restart", "change", "campaign" if campaign else "missions"],
		["Resume", "Restart", "Change powers", "Campaign" if campaign else "Missions"],
		320.0, 148.0, 140.0)
	return self


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		UiSound.play(&"ui_resume")
		action.emit("resume")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a != "":
			# Resume is ui_pause turned upward; every other button leaves the mission, and clicks.
			UiSound.play(&"ui_resume" if a == "resume" else &"ui_click")
			action.emit(a)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.55))
	var title := "PAUSED"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 126.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	_menu.draw_on(_ui, _hover)
