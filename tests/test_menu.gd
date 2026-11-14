extends RefCounted
## Buttons: laid out in a column or a row without touching, centred where asked, and the point under the
## mouse maps to the right one -- or to none, between them.


static func run(t) -> void:
	await _frames(t)
	var col := Menu.column(["play", "sandbox", "quit"], ["Play", "VFX Sandbox", "Quit"], 320.0, 200.0, 120.0)
	t.check(col.items.size() == 3, "a column of three buttons (%d)" % col.items.size())
	var a := col.rect_of("play")
	var b := col.rect_of("sandbox")
	var c := col.rect_of("quit")
	t.check(a.end.y < b.position.y and b.end.y < c.position.y, "stacked top to bottom, with a gap between")
	t.near(a.get_center().x, 320.0, 0.51, "centred on the x it was given (%.1f)" % a.get_center().x)
	t.near(a.size.y, Menu.HEIGHT, 0.001, "every button is one height")

	t.check(col.at(b.get_center()) == "sandbox", "the point over a button is that button (%s)" % col.at(b.get_center()))
	t.check(col.at(Vector2(320.0, a.end.y + 2.0)) == "", "the gap between two buttons is nobody's")
	t.check(col.at(Vector2(10.0, 10.0)) == "", "and so is the rest of the screen")
	t.check(col.rect_of("nothing") == Rect2(), "an action the menu does not have has no rect")

	var row := Menu.row(["replay", "change", "title"], ["Replay", "Change powers", "Title"], 320.0, 300.0, 100.0)
	var left := row.rect_of("replay")
	var right := row.rect_of("title")
	t.check(left.end.x < row.rect_of("change").position.x and row.rect_of("change").end.x < right.position.x,
		"a row runs left to right without touching")
	t.near((left.position.x + right.end.x) * 0.5, 320.0, 0.51, "and is centred as a whole")
	t.check(row.at(right.get_center()) == "title", "the last one answers to its own point")



static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


## UI resolution Task 6a: title, pause, options and board draw in a 640x360 design frame centred in the area; clicks in frame coordinates still land.
static func _frames(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	await t.process_frame  # the tree is only live after the first frame
	UiScale.set_test_area(Vector2i(800, 450))
	var offset := Vector2(80, 45)

	var pause := PauseMenu.new()
	tree.root.add_child(pause)
	pause.setup(false, Settings.new(), "user://test_menu_settings.cfg")
	var frame: Control = pause._ui
	t.check(frame.position == offset and frame.size == Vector2(640, 360), "pause: the frame is 640x360 at (80, 45) in an 800x450 area")
	t.check(UiTheme.word_spacing, "pause: holds the word spacing while it lives")
	var emitted: Array[String] = []
	pause.action.connect(func(what: String) -> void: emitted.append(what))
	pause._on_gui_input(_click(pause._menu.rect_of("resume").get_center()))
	t.check(emitted == ["resume"], "pause: a click at Resume's frame-local centre hits it (%s)" % [emitted])
	pause._on_gui_input(_click(pause._menu.rect_of("options").get_center()))
	t.check(pause.options_open() and UiScale.backdrop_of(pause._panel) == Rect2(-offset, Vector2(800, 450)),
		"pause: the options panel's dimmer reaches all four edges of the area")
	t.check(PauseMenu.TITLE_Y <= Hud.BANNER_TOP - 6.0, "pause: PAUSED sits above the mission's name bar (%s < %s)" % [PauseMenu.TITLE_Y, Hud.BANNER_TOP])
	var lines := UiTheme.wrap(PauseMenu.CONFIRM_HUNT % "Two believers would be sealed", PauseMenu.CONFIRM_WIDTH, UiTheme.SIZE_BODY)
	t.check(lines.size() <= 3, "pause: the Hunt's confirm stays within three lines with the wide spaces (%d)" % lines.size())
	pause.queue_free()
	await t.process_frame
	t.check(not UiTheme.word_spacing, "pause: gives the word spacing back when freed")

	var board := MissionBoard.new()
	board.dev = true
	tree.root.add_child(board)
	board.setup(SaveFile.new(), "warning")
	t.check(board._ui.position == offset and board._ui.size == Vector2(640, 360), "board: the frame is 640x360 at (80, 45)")
	board._on_gui_input(_click(MissionBoard.tab_rect(2).get_center()))
	t.check(board.tier == 3, "board: a click at the Wrath tab's frame-local centre opens it (%d)" % board.tier)
	var picks: Array[String] = []
	board.action.connect(func(what: String) -> void: picks.append(what))
	board._on_gui_input(_click(MissionBoard.card_rect(1, board.missions().size()).get_center()))
	t.check(picks == ["pick"], "board: a click on a card's centre picks it (%s)" % [picks])
	# every card name and kind row stays inside its card, on every tab, with the wide spaces
	var over := []
	for tab in [1, 2, 3, 4, 5, MissionBoard.DEV_TIER]:
		board.open_tab(tab)
		var ids := board.missions()
		for i in ids.size():
			var r := MissionBoard.card_rect(i, ids.size())
			var size := board.title_size(ids[i], r)
			var room := board.title_room(ids[i], r)
			for line in UiTheme.wrap(board.card_title(ids[i]), room, size):
				if UiTheme.width(line, size) > room + 0.01:
					over.append("%s: %s" % [ids[i], line])
			for row in board.kind_rows(ids[i], r):
				if UiTheme.width(row, UiTheme.SIZE_SMALL) > r.size.x - MissionBoard.PAD * 2.0 + 0.01:
					over.append("%s kind: %s" % [ids[i], row])
	t.check(over.is_empty(), "board: no card name or kind line is wider than its card (%s)" % [over])
	var hint_w := UiTheme.width(MissionBoard.HINT_DEV, UiTheme.SIZE_SMALL)
	t.check(hint_w <= 632.0, "board: the widest hint fits the screen with the wide spaces (%.0f)" % hint_w)
	var head_w := UiTheme.width(MissionBoard.TEST_HEADER, UiTheme.SIZE_SMALL)
	t.check(8.0 + UiTheme.width("THE TIERS", UiTheme.SIZE_BIG) + 4.0 + 72.0 + 158.0 < 632.0 - head_w,
		"board: the header line clears THE TIERS, DEV and ENDLESS (%.0f wide)" % head_w)
	board.queue_free()

	var title := TitleScreen.new()
	tree.root.add_child(title)
	WorldView.test_host = true
	title.setup(3483, "D", Settings.new(), "user://test_menu_settings.cfg")
	t.check(title._ui.position == offset, "title: the frame is at (80, 45)")
	var started: Array[String] = []
	title.action.connect(func(what: String) -> void: started.append(what))
	title._on_gui_input(_click(title._menu.rect_of("play").get_center()))
	t.check(started == ["play"], "title: a click at Missions' frame-local centre hits it (%s)" % [started])
	var best_w := UiTheme.width("Best 3483  D", UiTheme.SIZE_SMALL)
	t.check(TitleScreen.best_rect(best_w).size.x > best_w and TitleScreen.best_rect(best_w).end.y < 330.0, "title: the best line has a plate")
	t.check(UiTheme.word_spacing, "title: holds the word spacing")
	title.queue_free()
	for i in 3:
		await t.process_frame
	WorldView.test_host = false
	t.check(not UiTheme.word_spacing, "title: gives it back")

	var panel := OptionsPanel.new().setup(Settings.new(), "user://test_menu_settings.cfg")
	t.check(UiTheme.width(OptionsPanel.FOOTER, UiTheme.SIZE_SMALL) <= OptionsPanel.PANEL.size.x - 16.0,
		"options: the footer fits the panel with the wide spaces (%.0f of %.0f)" % [UiTheme.width(OptionsPanel.FOOTER, UiTheme.SIZE_SMALL), OptionsPanel.PANEL.size.x])
	panel.free()
	UiScale.clear_test_area()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_menu_settings.cfg"))
