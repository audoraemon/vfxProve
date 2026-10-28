class_name GodHub
extends Node
## The Endless Night hub (god P1, spec §9.1, Rulings P8, P18, P24): where a god stands between nights -- its type, level and tier, the
## Divine Power bar, the unspent ability points, Faith, the Lantern Notice and the night -- and the ways on: Descend, the Skill Tree,
## Faith and Title. A god with nothing to draft cannot Descend (Ruling P8). In the DEV build the A key is the Awaken hook (Ruling P18).
## God P2 (spec §9.1, §10) draws the Notice as a meter beside its line and says in red above the buttons when the Hunt is next and
## which ability the Lantern has sealed, for how long; the dev Awaken is refused while the Hunt is due (Ruling P2-4).

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
## The Lantern Notice meter, beside its line (index 5, baseline 142) (god P2, Ruling P2-11; preflight R6).
const NOTICE_BAR := Rect2(176.0, 134.0, 120.0, 8.0)
## The widest the one-off line may be before it wraps (preflight R6).
const LINE_WIDTH := 600.0
## What the hub says when the Hunt is next (god P2, spec §10.2, Ruling P2-11; *my call*): `%s` is the Hunt's title.
const HUNT_DUE := "THE LANTERN HUNTS: the next night is the Hunt, %s"
## What the hub says of a sealed ability (spec §10.3, Ruling P2-11; *my call*): its name, the nights left.
const SEALED := "Sealed by the Lantern: %s, %s left"
## What the dev Awaken says while the Hunt is due (Ruling P2-4; *my call*).
const AWAKEN_HUNT := "The Lantern hunts: face the Hunt first"

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


## The Notice as a fraction of a full meter, 0 to 1 (god P2, spec §10.1).
func notice_fill() -> float:
	return clampf(float(_slot.notice) / float(GodSlot.NOTICE_MAX), 0.0, 1.0)


## "THE LANTERN HUNTS: ..." with the Hunt's title when the next night is the Hunt (Notice 100), else "" (god P2, spec §10.2).
func hunt_line() -> String:
	var hunt := GodNight.hunt_for(_slot)
	return "" if hunt.is_empty() else HUNT_DUE % String(hunt.title)


## "Sealed by the Lantern: <ability>, <n> nights left" while an ability is sealed, else "" (god P2, spec §10.3).
func seal_line() -> String:
	if _slot.sealed == "" or _slot.seal_nights <= 0:
		return ""
	return SEALED % [PowerBook.get_power(_slot.sealed).name, GodSlot.nights_text(_slot.seal_nights)]


## Where the text above the buttons sits (preflight R6): "line_ys" the baselines of the wrapped one-off line (the last at BUTTONS_Y - 14,
## the old place), then "seal_y" and "hunt_y" one line step above the block each (-1 when not shown), and "top" the highest baseline.
func status_layout() -> Dictionary:
	var last := BUTTONS_Y - 14.0
	var wrapped := UiTheme.wrap(line, LINE_WIDTH, UiTheme.SIZE_BODY) if line != "" else PackedStringArray()
	var ys := []
	for i in wrapped.size():
		ys.append(last - UiTheme.LINE_BODY * float(wrapped.size() - 1 - i))
	# The block's top baseline; with no one-off line the next line up takes its last baseline.
	var top := float(ys[0]) if not ys.is_empty() else last + UiTheme.LINE_BODY
	var seal_y := -1.0
	var hunt_y := -1.0
	if seal_line() != "":
		top -= UiTheme.LINE_BODY
		seal_y = top
	if hunt_line() != "":
		top -= UiTheme.LINE_BODY
		hunt_y = top
	return {"line_ys": ys, "seal_y": seal_y, "hunt_y": hunt_y, "top": top if (not ys.is_empty() or seal_y > 0.0 or hunt_y > 0.0) else BUTTONS_Y}


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
				if GodNight.hunt_for(_slot).is_empty():
					UiSound.play(&"ui_click")
					action.emit("awaken_dev")
				else:
					# The Hunt cannot be skipped (Ruling P2-4): say so, emit nothing.
					UiSound.play(&"ui_buzz")
					line = AWAKEN_HUNT
					_redraw()


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
	_ui.draw_rect(NOTICE_BAR, Color(0.04, 0.04, 0.06, 0.85))
	_ui.draw_rect(Rect2(NOTICE_BAR.position, Vector2(roundf(NOTICE_BAR.size.x * notice_fill()), NOTICE_BAR.size.y)), UiTheme.COL_BAD)
	UiTheme.frame(_ui, NOTICE_BAR, false)
	for i in range(3, text.size()):
		UiTheme.text(_ui, LINES_AT + Vector2(0.0, UiTheme.LINE_BODY * float(i - 3)), text[i], UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD if i == 3 and _slot.points > 0 else UiTheme.COL_TEXT)
	var lay := status_layout()
	var wrapped := UiTheme.wrap(line, LINE_WIDTH, UiTheme.SIZE_BODY) if line != "" else PackedStringArray()
	for i in wrapped.size():
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(wrapped[i]) * 0.5), float(lay.line_ys[i])), wrapped[i], UiTheme.SIZE_BODY,
			UiTheme.COL_BAD)
	for pair: Array in [[seal_line(), float(lay.seal_y)], [hunt_line(), float(lay.hunt_y)]]:
		if String(pair[0]) != "":
			UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(String(pair[0])) * 0.5), float(pair[1])), String(pair[0]),
				UiTheme.SIZE_BODY, UiTheme.COL_BAD)
	_menu.draw_on(_ui, _hover, PackedStringArray() if can_descend() else PackedStringArray(["descend"]))
	var blocked := blocked_line()
	if blocked != "":
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(blocked, UiTheme.SIZE_SMALL) * 0.5), BUTTONS_Y + Menu.HEIGHT + 16.0),
			blocked, UiTheme.SIZE_SMALL, UiTheme.COL_BAD)
	var hint := "Enter: Descend   T: Skill Tree   F: Faith   Esc: Title"
	if dev:
		hint += "   DEV  A: awaken"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), 346.0), hint, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
