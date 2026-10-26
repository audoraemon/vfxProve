class_name GodHub
extends Node
## The Endless Night hub (god P1, spec §9.1, Rulings P8, P18, P24): where a god stands between nights -- its type, level and tier, the
## Divine Power bar, the unspent ability points, Faith, the Lantern Notice (written in P1 and shown as 0%: C9) and the night -- and the
## ways on: Descend, the Skill Tree, Faith and Title. A god with nothing to draft cannot Descend (Ruling P8). In the DEV build the A
## key is the Awaken hook (Ruling P18).

## "descend", "tree", "faith", "title" or "awaken_dev".
signal action(name: String)

## What the hub says when the god has nothing to draft (Ruling P8).
const BLOCKED := "Nothing to draft: the tree's Tier 1 is not filled yet"
## The Divine Power bar, and the buttons' row.
const BAR_RECT := Rect2(24.0, 74.0, 280.0, 14.0)
const BUTTONS_Y := 280.0
const BUTTON_W := 120.0
## Where the lines under the bar begin.
const LINES_AT := Vector2(24.0, 112.0)

## A one-off message shown over the buttons (e.g. GodNight.ABANDONED); "" for none.
var line := ""
## True in the DEV build: A is the Awaken hook.
var dev := false
var _slot: GodSlot
var _menu: Menu
var _ui: Control
var _hover := ""


func setup(slot: GodSlot, p_line := "", p_dev := false) -> GodHub:
	_slot = slot
	line = p_line
	dev = p_dev
	_menu = Menu.row(["descend", "tree", "faith", "title"], ["Descend", "Skill Tree", "Faith", "Title"], 320.0, BUTTONS_Y, BUTTON_W)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The Divine Power bar's words: "n / need Divine Power"; at the level cap below level 50 "AWAKEN TO GROW"; at level 50 "MAX LEVEL"
## (spec §8).
static func bar_text(slot: GodSlot) -> String:
	if slot.level >= GodSlot.MAX_LEVEL:
		return "MAX LEVEL"
	if slot.capped():
		return "AWAKEN TO GROW"
	return "%d / %d Divine Power" % [slot.divine_power, slot.need()]


## The hub's lines, in order: the type's title, level and tier, the bar's words, ability points, Faith, Notice, and the night. The
## night counts from 1 (Ruling P24 adds the ability points).
func lines() -> PackedStringArray:
	return PackedStringArray([PowerBook.authority_title(_slot.type), "Level %d   %s" % [_slot.level, TierBook.tier_name(_slot.tier)],
		bar_text(_slot), "Ability points %d" % _slot.points, "Faith %d" % _slot.faith, "Lantern Notice %d%%" % _slot.notice,
		"Night %d" % (_slot.night + 1)])


## True when the god has an ability to draft; a god with none cannot Descend (Ruling P8).
func can_descend() -> bool:
	return not _slot.draftable().is_empty()


## BLOCKED when the god cannot Descend, else "".
func blocked_line() -> String:
	return "" if can_descend() else BLOCKED


## Where the button for `what` ("descend", "tree", "faith", "title") is drawn; empty for none.
func menu_rect(what: String) -> Rect2:
	return _menu.rect_of(what)


## A left click at a screen point: a button's action; Descend does nothing (a buzz) while blocked.
func click(point: Vector2) -> void:
	var what := _menu.at(point)
	if what != "":
		_emit(what)


func _emit(what: String) -> void:
	if what == "descend" and not can_descend():
		UiSound.play(&"ui_buzz")
		return
	UiSound.play(&"ui_click")
	action.emit(what)


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_emit("descend")
		KEY_T:
			_emit("tree")
		KEY_F:
			_emit("faith")
		KEY_ESCAPE:
			_emit("title")
		KEY_A:
			if dev:
				UiSound.play(&"ui_click")
				action.emit("awaken_dev")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	var text := lines()
	UiTheme.text(_ui, Vector2(24.0, 44.0), text[0], UiTheme.SIZE_TITLE, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(24.0, 66.0), text[1], UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
	var full := 1.0 if _slot.capped() else clampf(float(_slot.divine_power) / float(maxi(_slot.need(), 1)), 0.0, 1.0)
	_ui.draw_rect(BAR_RECT, Color(0.04, 0.04, 0.06, 0.85))
	_ui.draw_rect(Rect2(BAR_RECT.position, Vector2(BAR_RECT.size.x * full, BAR_RECT.size.y)), UiTheme.COL_GOLD_DARK)
	UiTheme.frame(_ui, BAR_RECT, false)
	UiTheme.text(_ui, Vector2(roundf(BAR_RECT.get_center().x - UiTheme.width(text[2], UiTheme.SIZE_SMALL) * 0.5), BAR_RECT.position.y + 11.0),
		text[2], UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	for i in range(3, text.size()):
		UiTheme.text(_ui, LINES_AT + Vector2(0.0, UiTheme.LINE_BODY * float(i - 3)), text[i], UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD if i == 3 and _slot.points > 0 else UiTheme.COL_TEXT)
	if line != "":
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(line) * 0.5), BUTTONS_Y - 14.0), line, UiTheme.SIZE_BODY, UiTheme.COL_BAD)
	_menu.draw_on(_ui, _hover, PackedStringArray() if can_descend() else PackedStringArray(["descend"]))
	var blocked := blocked_line()
	if blocked != "":
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(blocked, UiTheme.SIZE_SMALL) * 0.5), BUTTONS_Y + Menu.HEIGHT + 16.0),
			blocked, UiTheme.SIZE_SMALL, UiTheme.COL_BAD)
	var hint := "Enter: Descend   T: Skill Tree   F: Faith   Esc: Title"
	if dev:
		hint += "   DEV  A: awaken"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), 346.0), hint, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
