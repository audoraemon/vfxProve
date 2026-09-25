class_name TitleScreen
extends Node
## The title (spec §1, §5): "KINGDOMS AMID KATACLYSM" with "KAK" small, over the town of Aldermere drifting
## slowly past, and three ways on: Play, the VFX Sandbox, Quit. The town is the real one, built without its
## people -- nothing here needs a crowd, and nothing here should cost a frame.

## "play", "sandbox" or "quit".
signal action(name: String)

## One slow loop of the camera every 1 / DRIFT_SPEED seconds, this far each way (screen pixels).
const DRIFT_SPEED := 0.02
const DRIFT := Vector2(240.0, 60.0)
const ZOOM := 0.7
## The band the title sits on, so it reads over any part of the town.
const BAND := Rect2(0.0, 76.0, 640.0, 88.0)

var _bf: Battlefield
var _town: Town
var _ui: Control
var _menu: Menu
var _hover := ""
var _best_score := 0
var _best_rank := ""
var _t := 0.0


func setup(best_score: int, best_rank: String) -> TitleScreen:
	_best_score = best_score
	_best_rank = best_rank
	_bf = Battlefield.new()
	_bf.name = "Backdrop"
	add_child(_bf)
	_bf.reset(7)
	_town = Town.new()
	_town.name = "Town"
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_bf.camera.zoom = Vector2.ONE * ZOOM
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.column(["play", "sandbox", "quit"], ["Play", "VFX Sandbox", "Quit"], 320.0, 206.0, 132.0)
	return self


func _process(delta: float) -> void:
	_t += delta
	var base := Iso.ground_to_screen(Vector2(0.0, -1.0))
	var phase := _t * DRIFT_SPEED * TAU
	_bf.camera.position = (base + Vector2(sin(phase) * DRIFT.x, sin(phase * 0.7) * DRIFT.y)).round()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			action.emit("play")


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
	_ui.draw_rect(BAND, Color(0.02, 0.02, 0.04, 0.66))
	_ui.draw_line(BAND.position, Vector2(BAND.end.x, BAND.position.y), UiTheme.COL_GOLD_DARK, -1.0)
	_ui.draw_line(Vector2(BAND.position.x, BAND.end.y), BAND.end, UiTheme.COL_GOLD_DARK, -1.0)
	var title := "KINGDOMS AMID KATACLYSM"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 128.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	var small := "KAK"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(small) * 0.5), 150.0), small, UiTheme.SIZE_BODY, UiTheme.COL_DIM)
	_menu.draw_on(_ui, _hover)
	if _best_score > 0:
		var best := "Best %d  %s" % [_best_score, _best_rank]
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(best, UiTheme.SIZE_SMALL) * 0.5), 300.0), best,
			UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
