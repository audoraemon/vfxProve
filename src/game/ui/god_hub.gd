class_name GodHub
extends Node
## The Endless Night hub (god P1, spec §9.1, Rulings P8, P18, P24): where a god stands between nights -- its type, level and tier, the
## Divine Power bar, the unspent ability points, Faith, the Lantern Notice and the night -- and the ways on: Descend, the Skill Tree,
## Faith and Title. A god with nothing to draft cannot Descend (Ruling P8). In the DEV build the A key is the Awaken hook (Ruling P18).
## God P2 (spec §9.1, §10) draws the Notice as a meter beside its line and says in red above the buttons when the Hunt is next and
## which ability the Lantern has sealed, for how long; the dev Awaken is refused while the Hunt is due (Ruling P2-4).
## God P3 (MS §1, §4, parent spec §9.3, Ruling P3-2) adds the Awaken button beside Descend while the god is capped, and the stolen gifts.

## "descend", "awaken", "tree", "faith", "title" or "awaken_dev".
signal action(name: String)

## The words the hub says, kept here under their old names (HubStatus holds them).
const BLOCKED := HubStatus.BLOCKED
const HUNT_DUE := HubStatus.HUNT_DUE
const SEALED := HubStatus.SEALED
const AWAKEN_HUNT := HubStatus.AWAKEN_HUNT
const RITE_UNWRITTEN := HubStatus.RITE_UNWRITTEN
const GIFTS_LINE := HubStatus.GIFTS_LINE
## The Divine Power bar, and the buttons' row.
const BAR_RECT := Rect2(24.0, 74.0, 280.0, 14.0)
const BUTTONS_Y := 280.0
const BUTTON_W := 120.0
## A button's width when Awaken makes the row five (god P3, MS §1): five of 108 and four gaps of 8 are 572 px, inside the 640.
const BUTTON_W_FIVE := 108.0
## Where the lines under the bar begin.
const LINES_AT := Vector2(24.0, 112.0)
## The Lantern Notice meter, beside its line (index 5, baseline 142) (god P2, Ruling P2-11; preflight R6).
const NOTICE_BAR := Rect2(176.0, 134.0, 120.0, 8.0)
## The widest the one-off line may be before it wraps (preflight R6).
const LINE_WIDTH := 600.0

## A one-off message shown over the buttons (e.g. GodNight.ABANDONED); "" for none.
var line := ""
## True in the DEV build: A is the Awaken hook.
var dev := false
var _slot: GodSlot
var _status: HubStatus
var _menu: Menu
var _ui: Control
var _hover := ""


func setup(slot: GodSlot, p_line := "", p_dev := false) -> GodHub:
	_slot = slot
	line = p_line
	dev = p_dev
	_status = HubStatus.new(slot)
	if _status.awaken != "":
		_menu = Menu.row(["descend", "awaken", "tree", "faith", "title"], ["Descend", "Awaken", "Skill Tree", "Faith", "Title"], 320.0,
			BUTTONS_Y, BUTTON_W_FIVE)
	else:
		_menu = Menu.row(["descend", "tree", "faith", "title"], ["Descend", "Skill Tree", "Faith", "Title"], 320.0, BUTTONS_Y, BUTTON_W)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)  # today's 640x360 coordinates, centred in the area
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	return self


## The Divine Power bar's words (see HubStatus.bar_text).
static func bar_text(slot: GodSlot) -> String:
	return HubStatus.bar_text(slot)


## The hub's lines (see HubStatus.lines).
func lines() -> PackedStringArray:
	return _status.lines()


func gifts_line() -> String:
	return _status.gifts_line()


func awaken_shown() -> bool:
	return _status.awaken_shown()


func awaken_dim() -> bool:
	return _status.awaken_dim()


func notice_fill() -> float:
	return _status.notice_fill()


func hunt_line() -> String:
	return _status.hunt_line()


func seal_line() -> String:
	return _status.seal_line()


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


func can_descend() -> bool:
	return _status.can_descend()


func blocked_line() -> String:
	return _status.blocked_line()


## Where the button for `what` ("descend", "awaken", "tree", "faith", "title") is drawn; empty for none.
func menu_rect(what: String) -> Rect2:
	return _menu.rect_of(what)


## A left click at a screen point: a button's action; Descend does nothing (a buzz) while blocked.
func click(point: Vector2) -> void:
	var what := _menu.at(point)
	if what != "":
		_press(what)


## Plays and sends what HubStatus decided for a press: a buzz, a click and the action, or the one-off line.
func _press(what: String, from_key := false) -> void:
	var result := _status.press(what, from_key, dev)
	if result.buzz:
		UiSound.play(&"ui_buzz")
	elif result.emit != "":
		UiSound.play(&"ui_click")
	if result.line != "":
		line = result.line
		_redraw()
	if result.emit != "":
		action.emit(result.emit)


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_press("descend")
		KEY_T:
			_press("tree")
		KEY_F:
			_press("faith")
		KEY_ESCAPE:
			_press("title")
		KEY_A:
			_press("awaken", true)


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
	_ui.draw_rect(UiScale.backdrop(_ui), Color(0.03, 0.03, 0.05, 1.0))
	var text := lines()
	UiTheme.text(_ui, Vector2(24.0, 44.0), text[0], UiTheme.TEXT_XL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(24.0, 66.0), text[1], UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
	var full := _status.bar_fill()
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
	if gifts_line() != "":
		UiTheme.text(_ui, LINES_AT + Vector2(0.0, UiTheme.LINE_BODY * float(text.size() - 3)), gifts_line(), UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	var lay := status_layout()
	var wrapped := UiTheme.wrap(line, LINE_WIDTH, UiTheme.SIZE_BODY) if line != "" else PackedStringArray()
	for i in wrapped.size():
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(wrapped[i]) * 0.5), float(lay.line_ys[i])), wrapped[i], UiTheme.SIZE_BODY,
			UiTheme.COL_BAD_TEXT)
	for pair: Array in [[seal_line(), float(lay.seal_y)], [hunt_line(), float(lay.hunt_y)]]:
		if String(pair[0]) != "":
			UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(String(pair[0])) * 0.5), float(pair[1])), String(pair[0]),
				UiTheme.SIZE_BODY, UiTheme.COL_BAD_TEXT)
	var dim := PackedStringArray() if can_descend() else PackedStringArray(["descend"])
	if awaken_dim():
		dim.append("awaken")
	_menu.draw_on(_ui, _hover, dim)
	var blocked := blocked_line()
	if blocked != "":
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(blocked, UiTheme.SIZE_SMALL) * 0.5), BUTTONS_Y + Menu.HEIGHT + 16.0),
			blocked, UiTheme.SIZE_SMALL, UiTheme.COL_BAD_TEXT)
	var hint := hint_text()
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), 346.0), hint, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## The keys row under the buttons: Awaken's key joins it while the button is shown (god P3), else the dev hook is named under --dev.
func hint_text() -> String:
	var hint := "Enter: Descend   T: Skill Tree   F: Faith   Esc: Title"
	if awaken_shown():
		hint += "   A: Awaken"
	elif dev:
		hint += "   DEV  A: awaken"
	return hint
