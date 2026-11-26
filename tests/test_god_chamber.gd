extends RefCounted
## God's Chamber Task 3: the screen that replaces the hub -- its frame, the four stations by click and by key, the dim and closed states,
## the badges, the Title button, the bar at every window shape, and the lines FLOW reads. The words and decisions are HubStatus's
## (test_hub_status.gd); this suite proves the screen wires them to the room.


static func run(t) -> void:
	GodTree.dev_fill = true
	GodChamber.transitions = false
	_frame(t)
	_stations(t)
	_blocked(t)
	_table_opens_map(t)
	_door_closed(t)
	_door_rite(t)
	_door_unwritten(t)
	_door_dev(t)
	_hunt_refuses_both(t)
	_badges(t)
	_title(t)
	_hover(t)
	_hover_art(t)
	_hint_and_lines(t)
	_hint_strip(t)
	_resolutions(t)
	_bar_town(t)
	_blocker(t)
	_long_line(t)
	_transition_out(t)
	_transition_skip(t)
	await _transition_freed(t)
	_transition_none(t)
	_transition_back(t)
	_transitions_off(t)
	_fade_colours(t)
	_parallax_mouse(t)
	GodChamber.transitions = false
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
	t.check(not ch.can_descend() and ch.station_state("descend") != "dim" and ch.status.blocked_line() == GodChamber.BLOCKED,
		"nothing to draft: the table is not dim (the map says why) and the blocked line is set (%s)" % ch.status.blocked_line())
	ch._on_gui_input(_click(ch.menu_rect("descend").get_center()))
	ch._unhandled_input(_key(KEY_ENTER))
	t.check(got == ["descend", "descend"], "the table click and Enter both open the map (%s)" % [got])
	got.clear()
	ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
	t.check(got == ["tree"], "the other stations still work (%s)" % [got])
	ch.free()
	GodTree.use_table({})
	GodTree.dev_fill = true


## The World Table opens the map: its action is "descend", and coming back from the map zooms back out from the table.
static func _table_opens_map(t) -> void:
	t.check(ChamberLayout.STATIONS.descend.action == "descend", "the table's action is descend")
	GodChamber.transitions = true
	var tree := Engine.get_main_loop() as SceneTree
	var ch := GodChamber.new()
	tree.root.add_child(ch)
	ch.setup(_slot(), "", false, "descend")
	t.check(ch.in_transition() and ch.zoom() == GodChamber.ZOOM_TO, "coming back from the map starts at the zoomed table (%s)" % ch.zoom())
	ch.free()
	GodChamber.transitions = false


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


## Review Focus 5: capped, nothing to draft, the Hunt due: the table opens the map, the door refuses.
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
	t.check(got == ["descend"], "nothing to draft with the Hunt due: the table opens the map (it says why), the door refuses (%s)" % [got])
	t.check(ch.station_state("descend") != "dim" and ch.station_state("awaken") == "dim", "the door is dim, the table is not")
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


## Round 3 (art direction): hovering lights the object itself -- its own picture brightened and a soft warm rim round its silhouette, no
## box -- and keeps the name plate; the hit rects are the same.
static func _hover_art(t) -> void:
	t.check(not GodChamber.HOVER_BOX, "no gold box is drawn round a hovered station")
	var made := _make(_capped(10))
	var ch: GodChamber = made[0]
	t.check(ch.hover_drawn().is_empty(), "nothing hovered: nothing drawn")
	for key: String in ChamberLayout.ORDER:
		ch._on_gui_input(_motion(ch.menu_rect(key).get_center()))
		var art := ch.hover_drawn()
		t.check(ch._hover == key and art.get("glow", "") == "hover_" + key and art.get("rim", "") == "rim_" + key,
			"hovering %s draws its own light and rim (%s)" % [key, art])
		for piece: String in [String(art.get("glow", "")), String(art.get("rim", ""))]:
			var tex := ChamberArt.texture(ChamberLife.DIR + piece)
			t.check(tex != null and ChamberLife.FILES.has(piece) and Vector2(tex.get_size()) == (ChamberLife.FILES[piece].rect as Rect2).size,
				"%s exists and fits its rect" % piece)
		var plate := ch.plate_rect(key)
		var hit := ch.menu_rect(key)
		t.check(plate.has_area() and absf(plate.get_center().x - hit.get_center().x) <= 1.0 and plate.position.y >= hit.end.y,
			"%s keeps its name plate under it (%s, %s)" % [key, plate, hit])
		t.check(float(art.get("tint", 0.0)) == 1.0, "%s at full light: the hover is not dimmed" % key)
	ch.free()
	# A dim door's hover is dimmed with it (its light copy darkened as the door is); a closed door shows none.
	var dim := _make(_capped(20, 2))
	var d: GodChamber = dim[0]
	if d.station_state("awaken") == "dim":
		d._on_gui_input(_motion(d.menu_rect("awaken").get_center()))
		t.check(is_equal_approx(float(d.hover_drawn().get("tint", 0.0)), ChamberArt.DIM), "a dim door's hover is as dim as the door (%s)" % [d.hover_drawn()])
	d.free()
	var shut := _make(_slot())
	var c: GodChamber = shut[0]
	c._on_gui_input(_motion(c.menu_rect("awaken").get_center()))
	t.check(c.hover_drawn().is_empty(), "a closed door shows no hover")
	c.free()


## Round 3: the keys hint sits on a dark parchment strip of the desk, edge to edge, at every window shape; the stack above still clears it.
static func _hint_strip(t) -> void:
	var col := GodChamber.HINT_STRIP
	t.check((col.h < 0.15 or col.h > 0.95) and col.s > 0.2 and col.v < 0.45 and col.a >= 0.6 and col.a < 1.0,
		"the strip is dark parchment, translucent (%s)" % col)
	for area: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1024, 768)]:
		UiScale.set_test_area(area)
		var made := _make(_capped(10), true)
		var ch: GodChamber = made[0]
		var strip := ch.hint_strip_rect()
		var back := UiScale.backdrop(ch._ui)
		t.check(is_equal_approx(strip.position.x, back.position.x) and is_equal_approx(strip.end.x, back.end.x),
			"%s: the strip runs the desk's width, edge to edge (%s vs %s)" % [area, strip, back])
		t.check(strip.position.y >= ChamberLayout.SCENERY[1].rect.position.y and strip.end.y <= 360.0 and strip.size.y >= 13.0,
			"%s: the strip lies on the desk, inside the frame (%s)" % [area, strip])
		t.check(strip.has_point(Vector2(320.0, GodChamber.HINT_Y - 4.0)) and UiTheme.width(ch.hint_text(), UiTheme.SIZE_SMALL) <= strip.size.x - 8.0,
			"%s: the hint's row is inside the strip and fits it" % area)
		t.check(ch.one_off_baseline() <= strip.position.y - 4.0, "%s: the stack above stays clear of the strip" % area)
		ch.free()
		UiScale.clear_test_area()


## Round 3: the zoom's fade passes through the station's own colour and ends dark; the way back mirrors it; the timings are the same.
static func _fade_colours(t) -> void:
	for key: String in ChamberLayout.ORDER:
		GodChamber.transitions = true
		var made := _make(_capped(10))
		var ch: GodChamber = made[0]
		ch._press(key)
		var hue: Color = GodChamber.FADE_COLORS[key]
		var mid := Color()
		while ch.in_transition() and ch.fade() < 0.5:
			ch.advance(1.0 / 120.0)
			mid = ch.fade_color()
		t.check(mid.v > 0.15 and absf(wrapf(mid.h - hue.h, -0.5, 0.5)) < 0.06, "%s: half way, the fade is the station's colour (%s vs %s)" % [key, mid, hue])
		ch.advance(GodChamber.ZOOM_TIME)
		var end := ch.fade_color()
		t.check(ch.fade() == 1.0 and end.a == 1.0 and end.v < 0.06, "%s: it ends dark and opaque, so the page cut is clean (%s)" % [key, end])
		ch.free()
		var back := GodChamber.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(back)
		back.setup(_capped(10), "", false, key)
		if key == "descend" or key == "tree" or key == "faith":
			back.advance(GodChamber.ZOOM_TIME * 0.5)
			var out := _make(_capped(10))
			var o: GodChamber = out[0]
			o._press(key)
			o.advance(GodChamber.ZOOM_TIME * 0.5)
			t.check(o.fade_color().is_equal_approx(back.fade_color()) and is_equal_approx(o.fade(), back.fade()),
				"%s: the way back passes through the same colours (%s vs %s)" % [key, back.fade_color(), o.fade_color()])
			o.free()
		back.free()
	GodChamber.transitions = false


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
		t.check(is_equal_approx(bar.position.y, back.position.y), "%s: the bar sits at the screen's top edge (%s vs %s)" % [area, bar.position.y, back.position.y])
		t.check(ch._ui.mouse_filter == Control.MOUSE_FILTER_IGNORE and (ch._ui.get_parent() as Control).mouse_filter == Control.MOUSE_FILTER_STOP,
			"%s: the blocker takes the mouse, the 640x360 child ignores it" % area)
		var door_top := 1000.0
		for m: float in [-1.0, 1.0]:
			door_top = minf(door_top, ChamberLayout.rect_of("awaken", Vector2(m, m)).position.y)
		t.check(ch.under_bar_baseline(1) + 4.0 < door_top, "%s: two under-bar lines stay clear of the Rite Door (%s vs %s)" % [area, ch.under_bar_baseline(1), door_top])
		t.check(bar.encloses(ch.title_rect()), "%s: the Title button is inside the bar" % area)
		for key: String in ChamberLayout.ORDER:
			got.clear()
			ch._on_gui_input(_click(ch.menu_rect(key).get_center()))
			t.check(got == [key], "%s: a click at the %s station still emits it (%s)" % [area, key, got])
		ch.free()
		UiScale.clear_test_area()


## Task 3 review (a): a long one-off line wraps to two lines and the stack stays clear of the keys hint.
static func _long_line(t) -> void:
	var long := "Night 7 was abandoned: the Hunt is lost. The Lantern seals Smite for 3 nights. Lantern Notice 50%. The Hunt is lost and the Lantern is angry."
	var made := _make(_slot(), false, long)
	var ch: GodChamber = made[0]
	var wrapped := UiTheme.wrap(long, GodChamber.LINE_WIDTH, UiTheme.SIZE_BODY)
	t.check(wrapped.size() >= 2, "the long one-off line wraps to %d lines" % wrapped.size())
	t.check(ch.one_off_baseline() <= GodChamber.HINT_Y - 16.0, "the one-off line's last row sits clear above the hint (%s)" % ch.one_off_baseline())
	ch.free()


static func _on(god: GodSlot = null) -> Array:
	GodChamber.transitions = true
	return _make(god if god != null else _capped(10))


## Out: a click starts the zoom, the action comes when it ends.
static func _transition_out(t) -> void:
	var made := _on()
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
	t.check(got.is_empty() and ch.in_transition() and ch.zoom() == 1.0, "transitions on: a click on tree emits nothing at once (%s)" % [got])
	ch.advance(0.2)
	t.check(got.is_empty() and ch.zoom() > 1.0 and ch.zoom() < GodChamber.ZOOM_TO and ch.fade() == 0.0,
		"0.2 s in: nothing yet, zoom %.2f between 1 and 2.2, fade 0" % ch.zoom())
	ch.advance(0.2)
	t.check(got == ["tree"] and ch.fade() == 1.0 and ch.zoom() == GodChamber.ZOOM_TO, "0.4 s in: tree emitted exactly once, fade 1 (%s)" % [got])
	ch.advance(0.1)
	ch._on_gui_input(_click(ch.menu_rect("faith").get_center()))
	t.check(got == ["tree"] and ch.in_transition() and ch.fade() == 1.0, "held black after the zoom: a click neither restarts it nor re-sends (%s)" % [got])
	ch.advance(GodChamber.HELD_TIME)
	t.check(got == ["tree"] and not ch.in_transition() and ch.zoom() == 1.0 and ch.fade() == 0.0,
		"a room Game did not replace comes back to rest (zoom %.2f, fade %.2f)" % [ch.zoom(), ch.fade()])
	got.clear()
	ch._on_gui_input(_click(ch.menu_rect("faith").get_center()))
	ch.advance(GodChamber.ZOOM_TIME)
	t.check(got == ["faith"], "and its stations work again (%s)" % [got])
	ch.free()
	GodChamber.transitions = false


## Review Focus 1: any click or key during a zoom only finishes it.
static func _transition_skip(t) -> void:
	var made := _on()
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
	ch._on_gui_input(_motion(ch.menu_rect("faith").get_center()))
	t.check(ch._hover == "", "hover does not change in a transition")
	ch._on_gui_input(_click(ch.menu_rect("faith").get_center()))
	t.check(got == ["tree"] and ch.fade() == 1.0, "a click on faith during the zoom to tree skips: tree once, never faith (%s)" % [got])
	ch._on_gui_input(_click(ch.menu_rect("faith").get_center()))
	t.check(got == ["tree"], "and a click while it is held black does not restart the zoom or re-send (%s)" % [got])
	ch.free()
	made = _on()
	ch = made[0]
	got = made[1]
	ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
	ch._unhandled_input(_key(KEY_F))
	t.check(got == ["tree"], "a key during the zoom does the same (%s)" % [got])
	ch.free()
	# The Title button never zooms (the table does, even when nothing can be drafted).
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	made = _on(_slot())
	ch = made[0]
	got = made[1]
	ch._on_gui_input(_click(ch.menu_rect("descend").get_center()))
	t.check(ch.in_transition(), "the table zooms even with nothing to draft: the map says why")
	ch.free()
	made = _on(_slot())
	ch = made[0]
	got = made[1]
	ch._on_gui_input(_click(ch.menu_rect("title").get_center()))
	t.check(not ch.in_transition() and got == ["title"], "the Title button starts no transition and emits at once (%s)" % [got])
	ch.free()
	GodTree.use_table({})
	GodTree.dev_fill = true
	GodChamber.transitions = false


## Review Focus 2: a room freed mid-zoom emits nothing.
static func _transition_freed(t) -> void:
	await (Engine.get_main_loop() as SceneTree).process_frame  # the tree is only live after the first frame: _exit_tree needs it
	var made := _on()
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
	ch.free()
	var tree := Engine.get_main_loop() as SceneTree
	# A room taken off the tree mid-zoom has its pending action cleared: stepping or skipping it emits nothing.
	var made2 := _on()
	var d: GodChamber = made2[0]
	d._on_gui_input(_click(d.menu_rect("tree").get_center()))
	tree.root.remove_child(d)
	d.advance(0.5)
	d.skip()
	t.check((made2[1] as Array).is_empty(), "a detached room stepped and skipped emits nothing (%s)" % [made2[1]])
	d.free()
	await tree.process_frame
	await tree.process_frame
	t.check(got.is_empty(), "a room freed mid-zoom emits nothing (%s)" % [got])
	GodChamber.transitions = false


static func _transition_none(t) -> void:
	var made := _on(_slot())
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	ch._on_gui_input(_click(Vector2(5, 100)))
	t.check(not ch.in_transition() and got.is_empty(), "a click on bare wall starts nothing")
	ch.free()
	GodChamber.transitions = false


static func _transition_back(t) -> void:
	GodChamber.transitions = true
	var ch := GodChamber.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ch)
	ch.setup(_capped(10), "", false, "tree")
	var got := []
	ch.action.connect(func(what: String) -> void: got.append(what))
	t.check(ch.zoom() == GodChamber.ZOOM_TO and ch.fade() == 1.0 and ch.in_transition(), "back from tree starts zoomed in, black, in transition")
	ch._on_gui_input(_click(ch.menu_rect("faith").get_center()))
	t.check(got.is_empty() and not ch.in_transition() and ch.zoom() == 1.0, "a click during the return only skips it (%s)" % [got])
	ch.free()
	ch = GodChamber.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ch)
	ch.setup(_capped(10), "", false, "faith")
	ch.advance(0.1)
	t.check(ch.zoom() < GodChamber.ZOOM_TO and ch.zoom() > 1.0, "back from faith is zooming out")
	ch.advance(0.35)
	t.check(ch.zoom() == 1.0 and ch.fade() == 0.0 and not ch.in_transition(), "and at rest after 0.35 s")
	ch.free()
	ch = GodChamber.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ch)
	ch.setup(_capped(10), "", false, "")
	t.check(ch.zoom() == 1.0 and not ch.in_transition(), "any other origin starts at rest")
	ch.free()
	GodChamber.transitions = false


static func _transitions_off(t) -> void:
	GodChamber.transitions = false
	var ch := GodChamber.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ch)
	ch.setup(_capped(10), "", false, "tree")
	var got := []
	ch.action.connect(func(what: String) -> void: got.append(what))
	t.check(ch.zoom() == 1.0 and not ch.in_transition(), "transitions off: back from tree is at rest")
	ch._on_gui_input(_click(ch.menu_rect("tree").get_center()))
	t.check(got == ["tree"] and not ch.in_transition(), "and a click emits in the same call (%s)" % [got])
	ch.free()


## Review Focus 3: the parallax at the corners and outside the area; hit rects follow the draw rects.
static func _parallax_mouse(t) -> void:
	GodChamber.transitions = false
	UiScale.set_test_area(Vector2i(1280, 720))
	var made := _make(_capped(10))
	var ch: GodChamber = made[0]
	var got: Array = made[1]
	t.check(ch.mouse01() == Vector2.ZERO, "before any motion the mouse is at (0, 0)")
	var back := UiScale.backdrop(ch._ui)
	for p: Vector2 in [back.position, back.end, back.end + Vector2(500, 500), back.position - Vector2(300, 300)]:
		ch._on_gui_input(_motion(p))
		var m := ch.mouse01()
		t.check(absf(m.x) <= 1.0 and absf(m.y) <= 1.0, "the mouse %s is clamped to -1..1 (%s)" % [p, m])
		for key: String in ["descend", "tree", "faith", "awaken"]:
			ch._on_gui_input(_motion(p))  # a click moves the parallax too: put the mouse back at the corner first
			m = ch.mouse01()
			var expect: Rect2 = ChamberLayout.STATIONS[key].rect
			expect.position += ChamberLayout.shift(ChamberLayout.STATIONS[key].layer, m)
			t.check(ch.menu_rect(key) == expect, "%s: the %s rect moved by its layer's shift" % [p, key])
			got.clear()
			ch._on_gui_input(_click(ch.menu_rect(key).get_center()))
			t.check(got == [key], "%s: a click at the %s centre emits it (%s)" % [p, key, got])
	ch.free()
	UiScale.clear_test_area()


## Final review: mouse events outside the 640x360 child (the bands of a wide or tall window) reach the room through the blocker: the Title
## button works, hover clears and the parallax keeps following.
static func _blocker(t) -> void:
	for area: Vector2i in [Vector2i(2560, 1080), Vector2i(1024, 768)]:
		UiScale.set_test_area(area)
		var made := _make(_capped(10))
		var ch: GodChamber = made[0]
		var got: Array = made[1]
		var blocker := ch._ui.get_parent() as Control
		var f: float = ch._ui.scale.x
		var title := ch.title_rect()
		var outside := not Rect2(Vector2.ZERO, Vector2(640, 360)).encloses(title)
		t.check(outside, "%s: the Title button lies outside the 640x360 child" % area)
		# the same point in the blocker's units
		blocker.gui_input.emit(_click(ch._ui.position + title.get_center() * f))
		t.check(got == ["title"], "%s: a mouse click on Title through the blocker emits title (%s)" % [area, got])
		var c := ch.menu_rect("tree").get_center()
		blocker.gui_input.emit(_motion(ch._ui.position + c * f))
		t.check(ch._hover == "tree", "%s: hover through the blocker lights the station" % area)
		var band := ChamberLayout.FRAME.position - Vector2(30.0, -100.0)  # left of the frame, in frame units
		if area.x > 2000:
			blocker.gui_input.emit(_motion(ch._ui.position + band * f))
			t.check(ch._hover == "", "%s: moving into a side band clears the hover" % area)
			t.check(ch.mouse01().x < -0.5, "%s: the parallax keeps following in the band (%s)" % [area, ch.mouse01()])
		ch.free()
		UiScale.clear_test_area()


## The town line joins the bar: at the four window shapes every part lies in the bar and no two overlap.
static func _bar_town(t) -> void:
	for area: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1024, 768)]:
		UiScale.set_test_area(area)
		var made := _make(_capped(10))
		var ch: GodChamber = made[0]
		var bar := ch.bar_rect()
		var parts := ch.bar_parts()
		var keys := ["town", "night", "notice", "faith", "points", "power"]
		var ok := parts.size() == keys.size()
		for k: String in keys:
			ok = ok and parts.has(k) and bar.encloses(parts[k])
		t.check(ok, "%s: the bar's six parts lie inside it (%s)" % [area, parts])
		var apart := true
		for i in keys.size():
			for j in range(i + 1, keys.size()):
				if parts.has(keys[i]) and parts.has(keys[j]) and (parts[keys[i]] as Rect2).intersects(parts[keys[j]]):
					apart = false
					print("overlap ", keys[i], " ", keys[j])
		t.check(apart, "%s: no two parts of the bar overlap" % area)
		ch.free()
		UiScale.clear_test_area()
