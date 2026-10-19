class_name PauseMenu
extends Node
## Pause (spec §1): the mission frozen underneath, and Resume, Options (v0.11.2), Restart, Change powers, Missions. Esc resumes, the
## way it paused -- unless the Options panel is open, when it closes that first. This node lives beside the mission, not inside it, so it keeps running while the mission is
## switched off.

## "resume", "restart" (a new mission with the same four powers), "change" (back to the draft), "missions" (the
## mission board, v0.08) or, in a campaign, "campaign" (its night screen, v0.10).
signal action(name: String)

var _ui: Control
var _menu: Menu
var _hover := ""
var _panel: OptionsPanel
var _settings: Settings
var _settings_path := Settings.PATH


## `campaign` (v0.10): the last button leads back to the campaign's night screen instead of the board. `settings` and `path`
## (v0.11.2) are what the Options row edits and where it saves; "options" opens the panel here and is never emitted.
func setup(campaign := false, settings: Settings = null, path := Settings.PATH) -> PauseMenu:
	_settings = settings if settings != null else Settings.new().load_from(path)
	_settings_path = path
	var layer := CanvasLayer.new()
	layer.layer = 20  # over the HUD
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.column(["resume", "options", "restart", "change", "campaign" if campaign else "missions"],
		["Resume", "Options", "Restart", "Change powers", "Campaign" if campaign else "Missions"],
		320.0, 148.0, 140.0)
	return self


func options_open() -> bool:
	return is_instance_valid(_panel) and _panel.is_open()


func _open_options() -> void:
	if options_open():
		return
	_panel = OptionsPanel.new().setup(_settings, _settings_path)
	_panel.closed.connect(_on_options_closed)
	_ui.add_child(_panel)


func _on_options_closed() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if options_open():
		return  # the panel has it (Esc closes the panel, it does not resume)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		var vp := get_viewport()
		if vp != null:
			vp.set_input_as_handled()
		UiSound.play(&"ui_resume")
		action.emit("resume")


func _on_gui_input(event: InputEvent) -> void:
	if options_open():
		return
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a == "options":
			UiSound.play(&"ui_click")
			_open_options()
		elif a != "":
			# Resume is ui_pause turned upward; every other button leaves the mission, and clicks.
			UiSound.play(&"ui_resume" if a == "resume" else &"ui_click")
			action.emit(a)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.55))
	var title := "PAUSED"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 126.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	_menu.draw_on(_ui, _hover)
