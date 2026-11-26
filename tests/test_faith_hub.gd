extends RefCounted
## The Faith screen (God P1 Task 9; spec §7, Rulings P8, P12): its rows fit and buy, or refuse and say why. The hub cases (lines, buttons, Notice,
## Hunt, seal, Awaken, gifts) moved to test_god_chamber.gd and test_hub_status.gd when the Chamber replaced the hub.


static func run(t) -> void:
	_frames(t)
	GodTree.dev_fill = true
	_faith_rows(t)
	_faith_buy(t)
	GodTree.dev_fill = false


## UI resolution Task 6b: the Faith screen draws in a 640x360 design frame centred in the area, holds the wide spaces while it lives, and its lines fit.
static func _frames(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	UiScale.set_test_area(Vector2i(960, 495))
	var offset := Vector2(40, 0)
	var f := 1.375  # 960x495 is a 1.375x page: 880x495, centred
	var god := _slot()
	var faith := FaithScreen.new()
	tree.root.add_child(faith)
	faith.setup(god)
	t.check(faith._ui.position == offset and faith._ui.size == Vector2(640, 360) and faith._ui.scale == Vector2(f, f), "faith: the frame is 640x360 at (40, 0), scaled 1.375x, in a 960x495 area")
	t.check(UiScale.backdrop(faith._ui) == Rect2(-offset / f, Vector2(960, 495) / f), "faith: the backdrop is the whole area in frame coordinates")
	var got := []
	faith.action.connect(func(what: String) -> void: got.append(what))
	faith._on_gui_input(_click(FaithScreen.BACK_RECT.get_center()))
	t.check(got == ["back"], "faith: a click at Back's frame-local centre hits it (%s)" % [got])
	var widest := 0.0
	for key in faith.rows():
		widest = maxf(widest, UiTheme.width(faith.row_line(key), UiTheme.SIZE_BODY))
		widest = maxf(widest, UiTheme.width(faith.effect_line(key), UiTheme.SIZE_SMALL))
	t.check(widest <= FaithScreen.ROW_SIZE.x - 16.0, "faith: every row's line fits its row with the wide spaces (%.0f)" % widest)
	for why in FaithScreen.REFUSALS:
		t.check(UiTheme.width(FaithScreen.REFUSALS[why], UiTheme.SIZE_SMALL) <= 632.0 - FaithScreen.BACK_RECT.end.x - 12.0,
			"faith: the refusal '%s' fits beside Back" % why)
	faith.free()

	UiScale.clear_test_area()


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


static func _slot(type := "ruin") -> GodSlot:
	return GodSlot.make(1, type, 7)


static func _faith_rows(t) -> void:
	var god := _slot()
	var screen := FaithScreen.new().setup(god)
	t.check(screen.rows() == PackedStringArray(["slot", "might", "clock", "respec"]), "the Faith rows, in order (%s)" % [screen.rows()])
	var bad := 0
	var screen_rect := Rect2(0, 0, 640, 360)
	for i in screen.rows().size():
		var r := FaithScreen.row_rect(i)
		if not screen_rect.encloses(r) or r.intersects(FaithScreen.BACK_RECT):
			bad += 1
		for j in range(i + 1, screen.rows().size()):
			if r.intersects(FaithScreen.row_rect(j)):
				bad += 1
	t.check(bad == 0, "every row is on the screen and clear of Back and of the other rows (%d)" % bad)
	t.check(screen.row_line("slot") == "FASTER MIGHT   150 Faith   0 / 3", "the slot row (%s)" % screen.row_line("slot"))
	t.check(screen.row_line("respec") == "RESET ABILITY POINTS   100 Faith   bought 0", "a row with no limit says bought (%s)" % screen.row_line("respec"))
	t.check(screen.effect_line("slot") == "Full refill: 60 s" and screen.effect_line("might") == "Might gauge: 6",
		"the detail lines (%s, %s)" % [screen.effect_line("slot"), screen.effect_line("might")])
	god.bought["slot"] = 3
	t.check(screen.effect_line("slot") == "Full refill: 45 s", "three buys read 45 s (%s)" % screen.effect_line("slot"))
	t.check(screen.row_line("slot") == "FASTER MIGHT   All bought", "a row at its limit (%s)" % screen.row_line("slot"))
	t.check(screen.hit(FaithScreen.row_rect(1).get_center()) == "might" and screen.hit(FaithScreen.BACK_RECT.get_center()) == "back"
		and screen.hit(Vector2(639, 359)) == "", "hit finds a row, Back, or nothing")
	screen.free()


static func _faith_buy(t) -> void:
	var god := _slot()
	god.faith = 150
	var screen := FaithScreen.new().setup(god)
	var emitted := []
	screen.action.connect(func(what: String) -> void: emitted.append(what))
	screen.click(FaithScreen.row_rect(0).get_center())
	t.check(emitted == ["bought"] and god.faith == 0 and int(god.bought.get("slot", 0)) == 1,
		"a click on FASTER MIGHT with 150 Faith buys it (%s, faith %d)" % [emitted, god.faith])
	t.check(screen.row_line("slot") == "FASTER MIGHT   300 Faith   1 / 3", "and the row reads the next price (%s)" % screen.row_line("slot"))
	emitted.clear()
	god.faith = 10
	screen.click(FaithScreen.row_rect(1).get_center())
	t.check(emitted.is_empty() and screen.refused_reason == "Not enough Faith" and god.faith == 10,
		"too little Faith: nothing bought, the reason shown (%s)" % screen.refused_reason)
	screen.click(FaithScreen.row_rect(3).get_center())
	t.check(emitted.is_empty() and screen.refused_reason == "No ability point spent yet",
		"respec with nothing spent says so (%s)" % screen.refused_reason)
	god.bought["slot"] = 3
	god.faith = 9999
	screen.click(FaithScreen.row_rect(0).get_center())
	t.check(emitted.is_empty() and screen.refused_reason == "None left to buy", "a row at its limit says none left (%s)" % screen.refused_reason)
	t.check(not screen.buy("nope") and screen.refused_reason == "Not an upgrade", "an unknown row (%s)" % screen.refused_reason)
	screen.click(FaithScreen.BACK_RECT.get_center())
	screen._unhandled_input(_key(KEY_ESCAPE))
	t.check(emitted == ["back", "back"], "Back and Esc both go back (%s)" % [emitted])
	screen.free()
