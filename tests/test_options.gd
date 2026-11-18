extends RefCounted
## v0.11.2 Task 3: Settings (its own file), the Options panel (bars, keys, clicks, Esc) and its place on Pause and the title.

const PATH := "user://test_settings.cfg"


static func run(t) -> void:
	var kept := _bus_levels()
	_settings(t)
	_panel(t)
	_pause(t)
	_title(t)
	_restore(kept)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


static func _bus_levels() -> Dictionary:
	var out := {}
	for b in ["Music", "SFX", "UI"]:
		var i := AudioServer.get_bus_index(b)
		if i >= 0:
			out[b] = AudioServer.get_bus_volume_db(i)
	return out


static func _restore(kept: Dictionary) -> void:
	for b: String in kept:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(b), float(kept[b]))


static func _bus_db(b: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(b))


static func _settings(t) -> void:
	var s := Settings.new()
	s.music = 0.3
	s.ui = 0.0
	s.save_to(PATH)
	var r := Settings.new().load_from(PATH)
	t.check(is_equal_approx(r.music, 0.3) and r.ui == 0.0 and r.sfx == 1.0, "round trip, defaults for the rest")
	r.apply()
	t.check(is_equal_approx(_bus_db("Music"), linear_to_db(0.3)), "applied to the bus")
	t.check(_bus_db("UI") <= -79.0, "a bar at 0 mutes its bus (%f)" % _bus_db("UI"))
	t.check(Settings.bus_db(0.0) <= -79.0 and is_equal_approx(Settings.bus_db(1.0), 0.0), "0 is silent, 1 is unity")
	t.check(Settings.new().load_from("user://no_such.cfg").music == 1.0, "missing file: defaults")
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("this is [not a config\n[audio\nmusic = = \"\n")
	f.close()
	var bad := Settings.new().load_from(PATH)
	t.check(bad.music == 1.0 and bad.sfx == 1.0 and bad.ui == 1.0, "a damaged file: defaults")
	var cf := ConfigFile.new()
	cf.set_value("audio", "music", 7.5)
	cf.set_value("audio", "sfx", -2.0)
	cf.set_value("audio", "ui", "loud")
	cf.save(PATH)
	var clamped := Settings.new().load_from(PATH)
	t.check(clamped.music == 1.0 and clamped.sfx == 0.0 and clamped.ui == 1.0, "out of range clamps, a word is the default (%f %f %f)"
		% [clamped.music, clamped.sfx, clamped.ui])
	var nan_cf := ConfigFile.new()
	nan_cf.set_value("audio", "music", NAN)
	nan_cf.set_value("audio", "sfx", INF)
	nan_cf.set_value("audio", "ui", -INF)
	nan_cf.save(PATH)
	var nanned := Settings.new().load_from(PATH)
	t.check(nanned.music == 1.0 and nanned.sfx == 1.0 and nanned.ui == 1.0, "nan and inf read from the file are the default (%f %f %f)"
		% [nanned.music, nanned.sfx, nanned.ui])
	var g := Settings.new()
	g.set_level("Music", 0.4)
	g.set_level("SFX", 0.6)
	t.check(g.music == 0.4 and g.level("music") == 0.4 and g.level("SFX") == 0.6 and g.level("UI") == 1.0, "bus names work like keys")
	g.set_level("music", NAN)
	t.check(g.music == 1.0, "set_level with nan: the default")
	g.set_level("sfx", 2.0)
	t.check(g.level("sfx") == 1.0 and g.level("music") == 1.0, "set_level clamps; level reads it back")
	g.set_level("sfx", 0.5)
	t.check(is_equal_approx(_bus_db("SFX"), linear_to_db(0.5)), "set_level applies at once")
	# The zoom-out limit: its own key, round trip, clamped, damage is the default.
	var zs := Settings.new()
	t.check(zs.zoom_out == 0.5 and Settings.new().load_from("user://no_such.cfg").zoom_out == 0.5, "zoom_out defaults to 0.5")
	zs.set_zoom_step(6)
	zs.save_to(PATH)
	t.check(is_equal_approx(Settings.new().load_from(PATH).zoom_out, 0.55), "zoom_out round trips (0.55)")
	for pair in [[0.1, 0.35], [3.0, 0.85], [NAN, 0.5], [INF, 0.5], [-INF, 0.5]]:
		var zcf := ConfigFile.new()
		zcf.set_value("view", "zoom_out", float(pair[0]))
		zcf.save(PATH)
		t.check(is_equal_approx(Settings.new().load_from(PATH).zoom_out, float(pair[1])), "zoom_out %s reads as %s" % [pair[0], pair[1]])
	var zw := ConfigFile.new()
	zw.set_value("view", "zoom_out", "far")
	zw.save(PATH)
	t.check(Settings.new().load_from(PATH).zoom_out == 0.5, "a word is the default")
	Settings.new().apply()  # leaves Mission.zoom_min() at the default for whoever runs next
	# Settings never touch the progress save.
	t.check(Settings.PATH != SaveFile.PATH and Settings.PATH == "user://kak_settings.cfg", "its own file")


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	return e


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


## The Zoom out row (4th): Down reaches it and stops there; Left/Right move 0.05 a step between 0.85 (near) and 0.35 (far); a click picks a step.
static func _zoom_row(t, p: OptionsPanel, s: Settings) -> void:
	p.row = 2
	p._unhandled_input(_key(KEY_DOWN))
	p._unhandled_input(_key(KEY_DOWN))
	t.check(p.row == 3 and String(OptionsPanel.ROWS[3][0]) == "zoom_out", "Down reaches Zoom out and stops")
	t.check(s.zoom_out == 0.5 and Mission.zoom_min() == 0.5, "it starts at the default, 0.5 (step %d)" % s.zoom_step())
	s.set_zoom_step(0)
	s.apply()
	p._unhandled_input(_key(KEY_LEFT))  # the bar is empty at Near: Left does nothing
	t.check(s.zoom_out == 0.85, "Left at Near stays")
	p._unhandled_input(_key(KEY_RIGHT))
	t.check(is_equal_approx(s.zoom_out, 0.8) and is_equal_approx(Mission.zoom_min(), 0.8), "Right: one step further out, live at once (%f)" % s.zoom_out)
	for i in 14:
		p._unhandled_input(_key(KEY_RIGHT))
	t.check(is_equal_approx(s.zoom_out, 0.35), "and not past 0.35 (%f)" % s.zoom_out)
	var r3 := p.bar_rect(3)
	p._gui_input(_click(r3.position + Vector2(r3.size.x * 0.5, 5.0)))
	t.check(is_equal_approx(s.zoom_out, 0.6) and p.row == 3, "a click at the middle: 0.60 (%f)" % s.zoom_out)
	p._gui_input(_click(r3.position + Vector2(1.0, 5.0)))
	t.check(is_equal_approx(s.zoom_out, 0.85), "a click at the left end: back to 0.85")
	s.zoom_out = Settings.ZOOM_OUT_DEFAULT
	s.apply()
	t.check(Mission.zoom_min() == 0.5, "Mission.zoom_min() is back at the default")
	p.row = 0


static func _panel(t) -> void:
	var s := Settings.new()
	var p := OptionsPanel.new().setup(s, PATH)
	var closed := [0]
	p.closed.connect(func() -> void: closed[0] += 1)
	t.check(p.row == 0 and OptionsPanel.TITLE == "OPTIONS" and OptionsPanel.ROWS.size() == 4, "opens on Music, four rows")
	p.step(-1)
	t.check(is_equal_approx(s.music, 0.9), "Left on Music: 0.9 (%f)" % s.music)
	p.step(1)
	p.step(1)
	t.check(s.music == 1.0, "and not past full")
	p._unhandled_input(_key(KEY_DOWN))
	p._unhandled_input(_key(KEY_DOWN))
	t.check(p.row == 2, "two Down: Interface")
	p._unhandled_input(_key(KEY_LEFT))
	t.check(is_equal_approx(s.ui, 0.9), "Left on Interface: 0.9")
	for i in 12:
		p.step(-1)
	t.check(s.ui == 0.0, "and not below silence")
	var r1 := p.bar_rect(1)
	p._gui_input(_click(r1.position + Vector2(r1.size.x * 0.5, r1.size.y * 0.5)))
	t.check(is_equal_approx(s.sfx, 0.5) and p.row == 1, "a click at the middle of Sounds: 0.5 (%f)" % s.sfx)
	p._gui_input(_click(r1.position + Vector2(r1.size.x * 0.83, 2.0)))
	t.check(is_equal_approx(s.sfx, 0.8), "snapped to a tenth (%f)" % s.sfx)
	p._gui_input(_click(Vector2(2.0, 2.0)))
	t.check(is_equal_approx(s.sfx, 0.8), "a click away from the bars changes nothing")
	UiSound.asked.clear()
	p.row = 2
	p.step(1)
	t.check(UiSound.asked.back() == &"ui_click", "changing Interface plays ui_click")
	_zoom_row(t, p, s)
	p.row = 1
	p.step(1)
	t.check(UiSound.asked.back() == &"smite_strike", "changing Sounds plays one Smite crack")
	var esc := _key(KEY_ESCAPE)
	p._unhandled_input(esc)
	t.check(closed[0] == 1, "Esc closes once (%d)" % closed[0])
	p._unhandled_input(esc)
	t.check(closed[0] == 1, "a closed panel ignores keys")
	var saved := Settings.new().load_from(PATH)
	t.check(is_equal_approx(saved.sfx, s.sfx) and is_equal_approx(saved.ui, s.ui) and saved.music == 1.0, "closing saved the file to the given path")
	p.free()


static func _pause(t) -> void:
	var pause := PauseMenu.new()
	pause.setup(false, Settings.new(), PATH)
	var rows := []
	for item: Dictionary in pause._menu.items:
		rows.append(String(item.action))
	t.check(rows == ["resume", "options", "restart", "change", "missions"], "Pause rows (%s)" % [rows])
	t.check(String(pause._menu.items[1].label) == "Options", "Options is the second button")
	var emitted: Array[String] = []
	pause.action.connect(func(what: String) -> void: emitted.append(what))
	var rect: Rect2 = pause._menu.rect_of("options")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = rect.get_center()
	pause._on_gui_input(click)
	t.check(emitted.is_empty() and pause.options_open(), "Options opens the panel and emits nothing (%s)" % [emitted])
	pause._unhandled_input(_key(KEY_ESCAPE))
	t.check(emitted.is_empty() and pause.options_open(), "pause ignores Esc while the panel is open")
	pause._panel._unhandled_input(_key(KEY_ESCAPE))
	t.check(emitted.is_empty() and not pause.options_open(), "Esc closes the panel and does not resume (%s)" % [emitted])
	pause._unhandled_input(_key(KEY_ESCAPE))
	t.check(emitted == ["resume"], "Esc again resumes (%s)" % [emitted])
	var camp := PauseMenu.new()
	camp.setup(true, Settings.new(), PATH)
	t.check(String(camp._menu.items[4].action) == "campaign" and camp._menu.items.size() == 5, "in a campaign the last is Campaign")
	camp.free()
	pause.free()


static func _title(t) -> void:
	var rows := []
	for a in TitleScreen.ROWS:
		rows.append(String(a))
	t.check(rows == ["endless", "play", "options", "sandbox", "quit"], "Title rows (%s)" % [rows])
	var labels := []
	for l in TitleScreen.LABELS:
		labels.append(String(l))
	t.check(labels == ["Endless Night", "Missions", "Options", "VFX Sandbox", "Quit"], "Title labels (%s)" % [labels])
