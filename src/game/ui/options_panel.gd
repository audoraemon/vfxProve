class_name OptionsPanel
extends Control
## The Options panel (v0.11.2, spec §2.1): three volume bars of ten steps -- Music, Sounds, Interface -- over the pause menu
## or the title. A change applies at once; closing saves. It lives under whichever menu opened it and eats every click and
## key while it is open, so the menu below it does nothing: Esc closes the panel and never resumes the mission.

signal closed

const TITLE := "OPTIONS"
## [settings key, label]
const ROWS := [["music", "Music"], ["sfx", "Sounds"], ["ui", "Interface"]]
const STEPS := 10
const FOOTER := "Click a bar or use Left/Right   Up/Down to choose   Esc back"
const PANEL := Rect2(120.0, 92.0, 400.0, 176.0)
const BAR_LEFT := 250.0
const BAR_WIDTH := 220.0
const BAR_TOP := 140.0
const BAR_HEIGHT := 14.0
const ROW_GAP := 28.0

## The row the keys act on.
var row := 0

var _settings: Settings
var _path := Settings.PATH
var _open := true
var _was_ducked := false
var _dragging := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## `path` is where closing saves (Game's; a test's own file).
func setup(s: Settings, path := Settings.PATH) -> OptionsPanel:
	_settings = s
	_path = path
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# The pause duck would bury the very thing the Music bar sets.
	_was_ducked = Music.is_ducked()
	Music.set_ducked(false)
	return self


func is_open() -> bool:
	return _open


func bar_rect(i: int) -> Rect2:
	return Rect2(BAR_LEFT, BAR_TOP + float(i) * ROW_GAP, BAR_WIDTH, BAR_HEIGHT)


## One step of the chosen row's bar: -1 quieter, +1 louder. Plays the row's check sound when the level moved.
func step(dir: int) -> void:
	var key := String(ROWS[row][0])
	_set_step(key, roundi(_settings.level(key) * STEPS) + dir)


func _set_step(key: String, steps: int) -> void:
	var before := _settings.level(key)
	_settings.set_level(key, float(clampi(steps, 0, STEPS)) / float(STEPS))
	if not is_equal_approx(before, _settings.level(key)):
		match key:
			"sfx":
				UiSound.play(&"hs_strike", -12.0, Sfx.BUS)  # one Smite crack, on the bus it is moving
			"ui":
				UiSound.play(&"ui_click")
	queue_redraw()


func _close() -> void:
	if not _open:
		return
	_open = false
	_settings.save_to(_path)
	Music.set_ducked(_was_ducked)
	UiSound.play(&"ui_back")
	closed.emit()


func _handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _open or not (event is InputEventKey) or not event.pressed:
		return
	var code: Key = event.physical_keycode
	match code:
		KEY_ESCAPE:
			_handled()
			if not event.echo:
				_close()
		KEY_UP:
			row = maxi(row - 1, 0)
			_handled()
			queue_redraw()
		KEY_DOWN:
			row = mini(row + 1, ROWS.size() - 1)
			_handled()
			queue_redraw()
		KEY_LEFT:
			step(-1)
			_handled()
		KEY_RIGHT:
			step(1)
			_handled()
		_:
			# Nothing else reaches the menu below while this is up (Enter would start the Missions board from the title).
			_handled()


func _gui_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed and _bar_at(event.position) >= 0
		if event.pressed:
			_pick(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_pick(event.position)
	accept_event()


func _bar_at(p: Vector2) -> int:
	for i in ROWS.size():
		if bar_rect(i).grow_individual(6.0, 6.0, 6.0, 6.0).has_point(p):
			return i
	return -1


func _pick(p: Vector2) -> void:
	var i := _bar_at(p)
	if i < 0:
		return
	row = i
	var r := bar_rect(i)
	var key := String(ROWS[i][0])
	_set_step(key, roundi(clampf((p.x - r.position.x) / r.size.x, 0.0, 1.0) * STEPS))


func _draw() -> void:
	if _settings == null:
		return
	draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.55))
	draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.98))
	UiTheme.frame(self, PANEL, true)
	UiTheme.text(self, Vector2(roundf(320.0 - UiTheme.width(TITLE, UiTheme.SIZE_BIG) * 0.5), PANEL.position.y + 26.0), TITLE,
		UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	for i in ROWS.size():
		var r := bar_rect(i)
		var chosen := i == row
		var level := roundi(_settings.level(String(ROWS[i][0])) * STEPS)
		UiTheme.text(self, Vector2(PANEL.position.x + 24.0, r.position.y + 11.0), String(ROWS[i][1]), UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD if chosen else UiTheme.COL_TEXT)
		draw_rect(r, Color(0.04, 0.04, 0.06, 0.9))
		var w := r.size.x / float(STEPS)
		for s in STEPS:
			var cell := Rect2(r.position.x + float(s) * w + 1.0, r.position.y + 2.0, w - 2.0, r.size.y - 4.0)
			draw_rect(cell, UiTheme.COL_GOLD if s < level else Color(0.16, 0.14, 0.1, 1.0))
		UiTheme.frame(self, r, chosen)
		var pct := "%d%%" % (level * 10)
		UiTheme.text(self, Vector2(r.end.x + 10.0, r.position.y + 11.0), pct, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(self, Vector2(roundf(320.0 - UiTheme.width(FOOTER, UiTheme.SIZE_SMALL) * 0.5), PANEL.end.y - 12.0), FOOTER,
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
