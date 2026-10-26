extends RefCounted
## God P1 Task 9 (spec §7, §9.1, C9, Rulings P8, P12, P18, P24): the Faith screen and the Endless Night hub -- the Faith rows fit and
## buy (or refuse and say why), the hub's lines, the Divine Power bar's text, its buttons and keys, and a god with nothing to draft
## cannot Descend.


static func run(t) -> void:
	GodTree.dev_fill = true
	_faith_rows(t)
	_faith_buy(t)
	_hub_lines(t)
	_hub_buttons(t)
	GodTree.dev_fill = false
	_hub_blocked(t)


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
	t.check(screen.row_line("slot") == "+1 SLOT   150 Faith   0 / 3", "the slot row (%s)" % screen.row_line("slot"))
	t.check(screen.row_line("respec") == "RESET ABILITY POINTS   100 Faith   bought 0", "a row with no limit says bought (%s)" % screen.row_line("respec"))
	god.bought["slot"] = 3
	t.check(screen.row_line("slot") == "+1 SLOT   All bought", "a row at its limit (%s)" % screen.row_line("slot"))
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
		"a click on +1 SLOT with 150 Faith buys it (%s, faith %d)" % [emitted, god.faith])
	t.check(screen.row_line("slot") == "+1 SLOT   300 Faith   1 / 3", "and the row reads the next price (%s)" % screen.row_line("slot"))
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


static func _hub_lines(t) -> void:
	var god := _slot()
	var hub := GodHub.new().setup(god)
	t.check(Array(hub.lines()) == ["RUIN", "Level 1   Whisper", "0 / 50 Divine Power", "Ability points 0", "Faith 0", "Lantern Notice 0%",
		"Night 1"], "a fresh ruin god's hub lines (%s)" % [hub.lines()])
	god.level = 10
	god.divine_power = 50
	t.check(GodHub.bar_text(god) == "AWAKEN TO GROW", "at the cap below level 50 the bar says to Awaken (%s)" % GodHub.bar_text(god))
	god.tier = 5
	god.level = 50
	god.divine_power = 250
	t.check(GodHub.bar_text(god) == "MAX LEVEL", "tier 5 level 50 is max level (%s)" % GodHub.bar_text(god))
	god.points = 4
	god.faith = 77
	god.night = 6
	god.notice = 0
	t.check(Array(hub.lines()) == ["RUIN", "Level 50   Ascendance", "MAX LEVEL", "Ability points 4", "Faith 77", "Lantern Notice 0%",
		"Night 7"], "the lines follow the god (%s)" % [hub.lines()])
	hub.free()


static func _hub_buttons(t) -> void:
	var god := _slot()
	var hub := GodHub.new().setup(god, "", false)
	var emitted := []
	hub.action.connect(func(what: String) -> void: emitted.append(what))
	for a in ["descend", "tree", "faith", "title"]:
		var r := hub.menu_rect(a)
		t.check(r.has_area() and Rect2(0, 0, 640, 360).encloses(r), "the %s button is on the screen" % a)
		hub._on_gui_input(_click(r.get_center()))
	t.check(emitted == ["descend", "tree", "faith", "title"], "each button emits its action (%s)" % [emitted])
	emitted.clear()
	hub._unhandled_input(_key(KEY_ENTER))
	hub._unhandled_input(_key(KEY_T))
	hub._unhandled_input(_key(KEY_F))
	hub._unhandled_input(_key(KEY_ESCAPE))
	t.check(emitted == ["descend", "tree", "faith", "title"], "Enter, T, F and Esc do the same (%s)" % [emitted])
	emitted.clear()
	hub._unhandled_input(_key(KEY_A))
	t.check(emitted.is_empty(), "A does nothing without dev (%s)" % [emitted])
	hub.free()
	var dev := GodHub.new().setup(god, "", true)
	dev.action.connect(func(what: String) -> void: emitted.append(what))
	dev._unhandled_input(_key(KEY_A))
	t.check(emitted == ["awaken_dev"], "A is the dev Awaken when set up with dev (%s)" % [emitted])
	dev.free()
	# Task 5's GodNight.ABANDONED is built in parallel: any string stands in for it here (the hub only shows it).
	var shown := GodHub.new().setup(god, "The night was abandoned")
	t.check(shown.line == "The night was abandoned", "a one-off line is kept for the hub to show")
	shown.free()


static func _hub_blocked(t) -> void:
	GodTree.dev_fill = false
	var god := _slot()
	var hub := GodHub.new().setup(god)
	var emitted := []
	hub.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(not hub.can_descend() and hub.blocked_line() == GodHub.BLOCKED,
		"with the tree empty the god cannot Descend, and the hub says why (%s)" % hub.blocked_line())
	hub._on_gui_input(_click(hub.menu_rect("descend").get_center()))
	hub._unhandled_input(_key(KEY_ENTER))
	t.check(emitted.is_empty(), "the Descend click and Enter emit nothing (%s)" % [emitted])
	hub._on_gui_input(_click(hub.menu_rect("tree").get_center()))
	t.check(emitted == ["tree"], "the other buttons still work (%s)" % [emitted])
	hub.free()
	GodTree.dev_fill = true
	var full := GodHub.new().setup(_slot())
	t.check(full.can_descend() and full.blocked_line() == "", "with a filled tree it can Descend and has no blocked line")
	full.free()
	GodTree.dev_fill = false
