extends RefCounted
## God P1 Task 7 (spec §4, §12 rows 1-2): the slot select (3 slots, New / Continue / Delete with confirms) and the god select ring.

const BASE := "user://test_slot_screens_"
const FRAME := Rect2(0, 0, 640, 360)


static func run(t) -> void:
	_clear()
	_layout(t)
	_empty(t)
	_filled(t)
	_delete_confirm(t)
	_overwrite_confirm(t)
	_damaged(t)
	_slot_keys(t)
	_ring(t)
	_choose(t)
	GodTree.dev_fill = false
	_clear()


static func _clear() -> void:
	for n in range(1, GodSlot.COUNT + 1):
		if FileAccess.file_exists(GodSlot.path(n, BASE)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(GodSlot.path(n, BASE)))


static func _write(n: int, type: String, level: int, night: int) -> void:
	var g := GodSlot.make(n, type, 5)
	g.level = level
	g.night = night
	g.write(GodSlot.path(n, BASE))


## Collects the names a screen emits.
static func _listen(screen: Object) -> Array:
	var got := []
	screen.action.connect(func(what: String) -> void: got.append(what))
	return got


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.pressed = true
	e.physical_keycode = code
	return e


static func _layout(t) -> void:
	_clear()
	_write(1, "ruin", 1, 0)
	var rects: Array[Rect2] = []
	var bad := 0
	var screen := SlotScreen.new().setup(BASE)
	for i in GodSlot.COUNT:
		var slot := SlotScreen.slot_rect(i)
		if not FRAME.encloses(slot):
			bad += 1
		for other in rects:
			if other.intersects(slot):
				bad += 1
		rects.append(slot)
	t.check(bad == 0, "the three slot rects sit inside the frame and do not overlap (%d)" % bad)
	var buttons: Array[Rect2] = [SlotScreen.BACK_RECT]
	for i in GodSlot.COUNT:
		for what in ["continue", "new", "delete"]:
			var r := screen.button_rect(i, what)
			if not r.has_area():
				continue
			if not FRAME.encloses(r) or not SlotScreen.slot_rect(i).encloses(r):
				bad += 1
			for other in buttons:
				if other.intersects(r):
					bad += 1
			buttons.append(r)
	t.check(bad == 0 and buttons.size() == 1 + 3 + 1 + 1, "slot 1 (filled) has three buttons, 2-3 (empty) one each, none overlapping (%d, %d)" % [bad, buttons.size()])
	t.check(not screen.button_rect(1, "continue").has_area() and not screen.button_rect(1, "delete").has_area(),
		"an empty slot has no Continue or Delete")
	t.check(FRAME.encloses(SlotScreen.CONFIRM_PANEL) and FRAME.encloses(SlotScreen.CONFIRM_RECT) and FRAME.encloses(SlotScreen.CANCEL_RECT)
		and not SlotScreen.CONFIRM_RECT.intersects(SlotScreen.CANCEL_RECT), "the confirm panel and its two buttons fit and do not touch")
	screen.free()
	_clear()

	var ring: Array[Rect2] = []
	bad = 0
	for i in GodTree.RING.size():
		var r := GodSelectScreen.ring_rect(i)
		if not FRAME.encloses(r) or r.intersects(GodSelectScreen.CHOOSE_RECT) or r.intersects(GodSelectScreen.BACK_RECT) \
				or r.intersects(GodSelectScreen.INFO_RECT):
			bad += 1
		for other in ring:
			if other.intersects(r):
				bad += 1
		ring.append(r)
	t.check(bad == 0, "the six ring rects sit inside the frame, clear of the info panel and buttons, none overlapping (%d)" % bad)
	t.check(not GodSelectScreen.CHOOSE_RECT.intersects(GodSelectScreen.BACK_RECT) and FRAME.encloses(GodSelectScreen.INFO_RECT),
		"Choose and Back do not touch, and the info panel fits")
	var top := GodSelectScreen.ring_rect(0).get_center()
	var right := GodSelectScreen.ring_rect(1).get_center()
	var left := GodSelectScreen.ring_rect(5).get_center()
	t.check(is_equal_approx(top.x, 320.0) and top.y < right.y and right.x > top.x and left.x < top.x,
		"RING[0] is at the top and the ring runs clockwise (%s, %s, %s)" % [top, right, left])


static func _empty(t) -> void:
	_clear()
	var screen := SlotScreen.new().setup(BASE)
	var got := _listen(screen)
	for i in GodSlot.COUNT:
		t.check(screen.slot_line(i) == "Empty", "no file: slot %d reads Empty (%s)" % [i + 1, screen.slot_line(i)])
	var at: Vector2 = screen.button_rect(1, "new").get_center()
	t.check(screen.hit(at) == "new:1", "the New button answers as new:1 (%s)" % screen.hit(at))
	screen.click(at)
	t.check(got == ["new"] and screen.chosen == 2, "New on an empty slot emits new at once, chosen == 2 (%s, %d)" % [got, screen.chosen])
	screen.click(SlotScreen.BACK_RECT.get_center())
	t.check(got == ["new", "back"], "Back emits back (%s)" % [got])
	screen.free()


static func _filled(t) -> void:
	_clear()
	_write(2, "ruin", 3, 3)
	var screen := SlotScreen.new().setup(BASE)
	var got := _listen(screen)
	t.check(screen.slot_line(1) == "RUIN   Level 3   Whisper   Night 4", "a filled slot reads type, level, tier, night (%s)" % screen.slot_line(1))
	t.check(screen.slot_line(0) == "Empty" and screen.slot_line(2) == "Empty", "the others stay Empty")
	screen.click(screen.button_rect(1, "continue").get_center())
	t.check(got == ["continue"] and screen.chosen == 2, "Continue emits continue, chosen == 2 (%s, %d)" % [got, screen.chosen])
	screen.free()
	_clear()


static func _delete_confirm(t) -> void:
	_clear()
	_write(2, "veil", 1, 0)
	var file := GodSlot.path(2, BASE)
	var screen := SlotScreen.new().setup(BASE)
	var got := _listen(screen)
	screen.click(screen.button_rect(1, "delete").get_center())
	t.check(got.is_empty() and FileAccess.file_exists(file) and screen.pending == "delete",
		"Delete asks first: nothing emitted, the file stays (%s)" % screen.pending)
	t.check(screen.pending_text() == "Delete this god? It cannot be undone.", "and the question reads as written (%s)" % screen.pending_text())
	t.check(screen.hit(screen.button_rect(1, "continue").get_center()) == "", "while a question is open the slots do not answer")
	screen.cancel()
	t.check(FileAccess.file_exists(file) and screen.pending == "" and screen.slot_line(1) != "Empty", "Cancel keeps the file")
	screen.click(screen.button_rect(1, "delete").get_center())
	screen.click(SlotScreen.CANCEL_RECT.get_center())
	t.check(FileAccess.file_exists(file) and screen.pending == "", "clicking Cancel keeps it too")
	screen.click(screen.button_rect(1, "delete").get_center())
	screen.confirm()
	t.check(not FileAccess.file_exists(file) and screen.slot_line(1) == "Empty" and got.is_empty(),
		"Delete then Confirm removes the file; the slot reads Empty (%s)" % screen.slot_line(1))
	screen.free()
	_clear()


static func _overwrite_confirm(t) -> void:
	_clear()
	_write(2, "death", 4, 1)
	var file := GodSlot.path(2, BASE)
	var screen := SlotScreen.new().setup(BASE)
	var got := _listen(screen)
	screen.click(screen.button_rect(1, "new").get_center())
	t.check(got.is_empty() and screen.pending == "new", "New on a filled slot asks first, no new yet (%s)" % [got])
	t.check(screen.pending_text() == "Overwrite this god? It cannot be undone.", "and the question reads as written (%s)" % screen.pending_text())
	screen.cancel()
	t.check(got.is_empty() and FileAccess.file_exists(file), "Cancel emits nothing and keeps the god")
	screen.click(screen.button_rect(1, "new").get_center())
	screen.click(SlotScreen.CONFIRM_RECT.get_center())
	t.check(got == ["new"] and screen.chosen == 2, "Confirm emits new, chosen == 2 (%s, %d)" % [got, screen.chosen])
	t.check(FileAccess.file_exists(file), "the old god stays on disk until the new one is written (Game's job)")
	screen.free()
	_clear()


## Ruling P23: a damaged file reads as Empty, and New still asks before replacing it.
static func _damaged(t) -> void:
	_clear()
	var f := FileAccess.open(GodSlot.path(1, BASE), FileAccess.WRITE)
	f.store_string("[god]\ntype=\"nonsense\"\n")
	f.close()
	var screen := SlotScreen.new().setup(BASE)
	var got := _listen(screen)
	t.check(screen.slot_line(0) == "Empty" and not screen.button_rect(0, "delete").has_area(), "a damaged file reads as Empty with only New")
	screen.click(screen.button_rect(0, "new").get_center())
	t.check(got.is_empty() and screen.pending == "new", "New on it asks to overwrite first")
	screen.confirm()
	t.check(got == ["new"] and screen.chosen == 1, "and Confirm goes on (%s)" % [got])
	screen.free()
	_clear()


static func _slot_keys(t) -> void:
	_clear()
	_write(3, "decree", 1, 0)
	var screen := SlotScreen.new().setup(BASE)
	var got := _listen(screen)
	screen.click(screen.button_rect(2, "delete").get_center())
	screen._unhandled_input(_key(KEY_ESCAPE))
	t.check(got.is_empty() and screen.pending == "" and FileAccess.file_exists(GodSlot.path(3, BASE)), "Esc with a question open cancels it only")
	screen._unhandled_input(_key(KEY_ESCAPE))
	t.check(got == ["back"], "Esc otherwise goes back (%s)" % [got])
	screen.free()
	_clear()


static func _ring(t) -> void:
	GodTree.dev_fill = false
	var screen := GodSelectScreen.new().setup()
	var lines := screen.type_lines("ruin")
	var want := PackedStringArray(["RUIN", GodTree.FLAVOUR.ruin, "Tier 1: Not yet chosen, Not yet chosen", "Neighbours: DOMINION, DEATH"])
	t.check(lines == want, "ruin's lines with the dev fill off (%s)" % [lines])
	GodTree.dev_fill = true
	t.check(screen.type_lines("ruin")[2] == "Tier 1: Smite, Ember", "with the dev fill on, its Tier 1 names the two powers (%s)" % screen.type_lines("ruin")[2])
	GodTree.dev_fill = false
	t.check(screen.type_lines("veil")[3] == "Neighbours: DEATH, PASSAGE", "veil's neighbours are death and passage (%s)" % screen.type_lines("veil")[3])
	t.check(screen.type_lines("nonsense").is_empty(), "an unknown type has no lines")
	screen.free()


static func _choose(t) -> void:
	var screen := GodSelectScreen.new().setup()
	var got := _listen(screen)
	t.check(screen.chosen_type == "", "nothing is chosen at first")
	screen.select(2)
	t.check(screen.chosen_type == "" and got.is_empty(), "selecting alone chooses nothing")
	screen.confirm()
	t.check(screen.chosen_type == "veil" and got == ["chosen"], "select(2) then confirm() chooses veil (%s, %s)" % [screen.chosen_type, got])
	screen.free()

	screen = GodSelectScreen.new().setup()
	got = _listen(screen)
	screen._unhandled_input(_key(KEY_RIGHT))
	screen._unhandled_input(_key(KEY_RIGHT))
	t.check(screen.selected == 2, "Right steps the ring (%d)" % screen.selected)
	screen._unhandled_input(_key(KEY_LEFT))
	screen._unhandled_input(_key(KEY_LEFT))
	screen._unhandled_input(_key(KEY_LEFT))
	t.check(screen.selected == 5, "Left steps back and wraps (%d)" % screen.selected)
	screen._unhandled_input(_key(KEY_ENTER))
	t.check(screen.chosen_type == "dominion" and got == ["chosen"], "Enter chooses the selected type (%s, %s)" % [screen.chosen_type, got])
	screen.free()

	screen = GodSelectScreen.new().setup()
	got = _listen(screen)
	screen.click(GodSelectScreen.ring_rect(3).get_center())
	t.check(screen.selected == 3 and got.is_empty(), "a click on a type selects it (%d)" % screen.selected)
	screen.click(GodSelectScreen.CHOOSE_RECT.get_center())
	t.check(screen.chosen_type == "passage" and got == ["chosen"], "the Choose button chooses it (%s)" % screen.chosen_type)
	screen.click(GodSelectScreen.BACK_RECT.get_center())
	t.check(got.back() == "back", "Back emits back")
	screen._unhandled_input(_key(KEY_ESCAPE))
	t.check(got.back() == "back" and got.size() == 3, "Esc emits back (%s)" % [got])
	screen.free()
