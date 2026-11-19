extends RefCounted
## God's Chamber Task 3: the screen that replaces the hub -- its frame, the four stations by click and by key, the dim and closed states,
## the badges, the Title button, the bar at every window shape, and the lines FLOW reads. The words and decisions are HubStatus's
## (test_hub_status.gd); this suite proves the screen wires them to the room.


static func run(t) -> void:
	GodTree.dev_fill = true
	_frame(t)
	_stations(t)
	_blocked(t)
	_door_closed(t)
	_door_rite(t)
	_door_unwritten(t)
	_door_dev(t)
	_hunt_refuses_both(t)
	_badges(t)
	_title(t)
	_hover(t)
	_hint_and_lines(t)
	_resolutions(t)
	GodTree.dev_fill = false


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _motion(at: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = at
	return e


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


static func _slot(type := "ruin") -> GodSlot:
	return GodSlot.make(1, type, 7)


## A god capped at `level` of its tier: the Rite Door shows (a rite is written at level 10 of tier 1).
static func _capped(level: int, tier := 1) -> GodSlot:
	var god := _slot()
	god.tier = tier
	god.level = level
	god.divine_power = god.need()
	return god


## A chamber on the tree, with its actions collected: [chamber, got].
static func _make(god: GodSlot, p_dev := false, p_line := "") -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var ch := GodChamber.new()
	tree.root.add_child(ch)
	ch.setup(god, p_line, p_dev, "")
	var got := []
	ch.action.connect(func(what: String) -> void: got.append(what))
	return [ch, got]


static func _frame(t) -> void:
	UiScale.set_test_area(Vector2i(960, 495))
	var made := _make(_slot(), true)
	var ch: GodChamber = made[0]
	var f := 1.375
	t.check(ch._ui.position == Vector2(40, 0) and ch._ui.size == Vector2(640, 360) and ch._ui.scale == Vector2(f, f),
		"chamber: the frame is 640x360 at (40, 0), scaled 1.375x, in a 960x495 area")
	ch.free()
	UiScale.clear_test_area()


static func _stations(t) -> void:
	var god := _capped(10)
	var made := _make(god)
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	for key: String in ChamberLayout.ORDER:
		var r := ch.menu_rect(key)
		t.check(r.has_area() and Rect2(0, 0, 640, 360).encloses(r), "the %s station is on the screen" % key)
		got.clear()
		ch._on_gui_input(_click(r.get_center()))
		t.check(got == [key], "a click at the %s station emits it once (%s)" % [key, got])
		for code in ChamberLayout.STATIONS[key].keys:
			got.clear()
			ch._unhandled_input(_key(code))
			t.check(got == [key], "key %s on %s emits it once (%s)" % [OS.get_keycode_string(code), key, got])
	ch.free()


static func _blocked(t) -> void:
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var made := _make(_slot())
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	t.check(not ch.can_descend() and ch.station_state("descend") == "dim" and ch.status.blocked_line() == GodChamber.BLOCKED,
		"nothing to draft: the table is dim and the blocked line is set (%s)" % ch.status.blocked_line())
	ch._on_gui_input(_click(ch.menu_rect("descend").get_center()))
	ch._unhandled_input(_key(KEY_ENTER))
	t.check(got.is_empty(), "the table click and Enter emit nothing (%s)" % [got])
	ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
	t.check(got == ["tree"], "the other stations still work (%s)" % [got])
	ch.free()
	GodTree.use_table({})
	GodTree.dev_fill = true


static func _door_closed(t) -> void:
	var made := _make(_slot())
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	t.check(ch.station_state("awaken") == "closed" and not ch.badge("awaken"), "not capped: the door is closed, no badge")
	ch._on_gui_input(_click(ch.menu_rect("awaken").get_center()))
	ch._unhandled_input(_key(KEY_4))
	t.check(got.is_empty() and ch.line == "", "a click on the closed door and the 4 key emit nothing (%s, %s)" % [got, ch.line])
	ch._on_gui_input(_motion(ch.menu_rect("awaken").get_center()))
	t.check(ch._hover == "" and ch.station_state("awaken") == "closed", "hovering the closed door lights nothing and shows no plate")
	ch._unhandled_input(_key(KEY_A))
	t.check(got.is_empty(), "A does nothing without dev (%s)" % [got])
	ch.free()


static func _door_rite(t) -> void:
	var god := _capped(10)
	var made := _make(god)
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	t.check(ch.station_state("awaken") == "" and ch.status.awaken_shown() and not ch.status.awaken_dim(), "capped with a rite: the door is lit")
	ch._on_gui_input(_click(ch.menu_rect("awaken").get_center()))
	ch._unhandled_input(_key(KEY_A))
	ch._unhandled_input(_key(KEY_4))
	t.check(got == ["awaken", "awaken", "awaken"], "the click, A and 4 emit awaken in any build (%s)" % [got])
	ch.free()


static func _door_unwritten(t) -> void:
	var god := _capped(20, 2)
	var made := _make(god)
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	t.check(ch.station_state("awaken") == "dim", "capped, no rite written: the door is dim")
	ch._on_gui_input(_click(ch.menu_rect("awaken").get_center()))
	t.check(got.is_empty() and ch.line == HubStatus.RITE_UNWRITTEN, "a click says Rite not yet written and emits nothing (%s, %s)" % [got, ch.line])
	ch.free()


static func _door_dev(t) -> void:
	var made := _make(_slot(), true)
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	ch._unhandled_input(_key(KEY_A))
	ch._unhandled_input(_key(KEY_4))
	t.check(got == ["awaken_dev"], "dev, not capped: A is awaken_dev and 4 does nothing (%s)" % [got])
	ch.free()
	var low := _slot()
	low.notice = 100
	var m2 := _make(low, true)
	var c2: GodChamber = m2[0]
	c2._unhandled_input(_key(KEY_A))
	t.check((m2[1] as Array).is_empty() and c2.line == HubStatus.AWAKEN_HUNT, "dev A with the Hunt due: refused with its line (%s, %s)" % [m2[1], c2.line])
	c2.free()


## Review Focus 5: capped, nothing to draft, the Hunt due: the table and the door both refuse.
static func _hunt_refuses_both(t) -> void:
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var god := _capped(10)
	god.notice = 100
	var made := _make(god)
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	ch._on_gui_input(_click(ch.menu_rect("descend").get_center()))
	ch._on_gui_input(_click(ch.menu_rect("awaken").get_center()))
	ch._unhandled_input(_key(KEY_A))
	t.check(got.is_empty(), "nothing to draft with the Hunt due: the table and the door both refuse (%s)" % [got])
	t.check(ch.station_state("descend") == "dim" and ch.station_state("awaken") == "dim", "and both are dim")
	ch.free()
	GodTree.use_table({})
	GodTree.dev_fill = true


static func _badges(t) -> void:
	var god := _slot()
	var made := _make(god)
	var ch: GodChamber = made[0]
	t.check(not ch.badge("tree") and not ch.badge("faith"), "a fresh god has no badge")
	god.points = 1
	t.check(ch.badge("tree"), "a point to spend: the tree has its badge")
	god.faith = 24
	t.check(not ch.badge("faith"), "Faith one short of the cheapest row: no badge")
	god.faith = 25
	t.check(ch.badge("faith"), "Faith at the cheapest row: the altar has its badge")
	ch.free()
	var rite := _make(_capped(10))
	t.check((rite[0] as GodChamber).badge("awaken"), "a rite ready: the door has its badge")
	(rite[0] as GodChamber).free()
	var unw := _make(_capped(20, 2))
	t.check(not (unw[0] as GodChamber).badge("awaken"), "no rite written: no badge")
	(unw[0] as GodChamber).free()


static func _title(t) -> void:
	var made := _make(_slot())
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	ch._unhandled_input(_key(KEY_ESCAPE))
	ch._on_gui_input(_click(ch.menu_rect("title").get_center()))
	t.check(got == ["title", "title"], "Esc and the Title button emit title (%s)" % [got])
	ch.free()


static func _hover(t) -> void:
	var made := _make(_slot())
	var ch: GodChamber = made[0]
	var c := ch.menu_rect("tree").get_center()
	ch._on_gui_input(_motion(c))
	t.check(ch._hover == "tree" and ch.station_state("tree") == "hover", "entering a station hovers it")
	ch._on_gui_input(_motion(Vector2(320, 10)))
	t.check(ch._hover == "", "leaving it clears the hover")
	ch.free()


static func _hint_and_lines(t) -> void:
	var plain := _make(_slot())
	var p: GodChamber = plain[0]
	t.check(p.hint_text() == "Enter: Descend   T: Tree   F: Faith   Esc: Title", "the hint without dev or a door (%s)" % p.hint_text())
	t.check(Array(p.lines()) == ["RUIN", "Level 1   Whisper", "0 / 50 Divine Power", "Ability points 0", "Faith 0", "Lantern Notice 0%", "Night 1"]
		and p.lines()[6] == "Night 1", "a fresh god's lines, as FLOW reads them (%s)" % [p.lines()])
	p.free()
	var dev := _make(_slot(), true)
	t.check((dev[0] as GodChamber).hint_text().ends_with("   DEV  A: awaken"), "dev names the hook")
	(dev[0] as GodChamber).free()
	var door := _make(_capped(10), true)
	var h: String = (door[0] as GodChamber).hint_text()
	t.check(h.ends_with("   A: Awaken") and not h.contains("DEV") and UiTheme.width(h, UiTheme.SIZE_SMALL) <= 620.0, "the door names A once and the row fits (%s)" % h)
	(door[0] as GodChamber).free()
	for s: String in [GodChamber.BLOCKED, GodChamber.AWAKEN_HUNT, GodChamber.RITE_UNWRITTEN]:
		t.check(UiTheme.width(s, UiTheme.SIZE_BODY) <= 632.0, "the line fits the screen: %s" % s)


## Review Focus 4: at four window shapes no station meets the bar, the bar runs edge to edge, and every station is still clickable.
static func _resolutions(t) -> void:
	for area: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1024, 768)]:
		UiScale.set_test_area(area)
		var made := _make(_capped(10))
		var ch: GodChamber = made[0]
		var got: Array = made[1]
		var bar := ch.bar_rect()
		var back := UiScale.backdrop(ch._ui)
		t.check(is_equal_approx(bar.position.x, back.position.x) and is_equal_approx(bar.end.x, back.end.x),
			"%s: the bar runs from the area's left edge to its right" % area)
		var clear := true
		for key: String in ChamberLayout.ORDER:
			clear = clear and not ch.menu_rect(key).intersects(bar)
		t.check(clear, "%s: no station meets the bar" % area)
		t.check(bar.encloses(ch.title_rect()), "%s: the Title button is inside the bar" % area)
		for key: String in ChamberLayout.ORDER:
			got.clear()
			ch._on_gui_input(_click(ch.menu_rect(key).get_center()))
			t.check(got == [key], "%s: a click at the %s station still emits it (%s)" % [area, key, got])
		ch.free()
		UiScale.clear_test_area()
