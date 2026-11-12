class_name FaithScreen
extends Node
## The Faith screen (god P1, spec §7, Ruling P12): the god's Faith, spent on the rows of GodSlot.FAITH -- +1 slot, +1 Might, +15 s
## of descent clock and the ability-point reset. A list, so a new upgrade is a new row in the data and nothing here. A click buys
## what it can afford; one it cannot buzzes and says why. Esc or Back goes back to the hub. It is modelled on UpgradesScreen, which
## stays in the code, unreachable from the board (Ruling P12).

## "bought" (something was bought: Game writes the god's file) or "back".
signal action(name: String)

## Where the first row sits, a row's size and the gap between two rows.
const ROWS_AT := Vector2(8.0, 52.0)
const ROW_SIZE := Vector2(624.0, 40.0)
const ROW_GAP := 8.0
const BACK_RECT := Rect2(8.0, 322.0, 100.0, 20.0)
## How long a refusal's reason stays up.
const REFUSE_SECONDS := 1.5
## What a refused purchase says, by GodSlot.faith_refusal().
const REFUSALS := {"faith": "Not enough Faith", "limit": "None left to buy", "nothing": "No ability point spent yet",
	"unknown": "Not an upgrade"}

## Why the last click bought nothing, shown for REFUSE_SECONDS; "" for none.
var refused_reason := ""
var _refuse_left := 0.0
var _slot: GodSlot
var _ui: Control
var _hover := ""


func setup(slot: GodSlot) -> FaithScreen:
	_slot = slot
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The keys of GodSlot.FAITH, in order: one row each.
func rows() -> PackedStringArray:
	var out := PackedStringArray()
	for row: Dictionary in GodSlot.FAITH:
		out.append(String(row.key))
	return out


## Row `i`'s rectangle.
static func row_rect(i: int) -> Rect2:
	return Rect2(ROWS_AT + Vector2(0.0, float(i) * (ROW_SIZE.y + ROW_GAP)), ROW_SIZE)


## What is under a point: a row's key, "back", or "".
func hit(point: Vector2) -> String:
	if BACK_RECT.has_point(point):
		return "back"
	var keys := rows()
	for i in keys.size():
		if row_rect(i).has_point(point):
			return keys[i]
	return ""


## The row `what` as a line: its name, price and count ("+1 SLOT   150 Faith   0 / 3"; "bought 2" for a row with no limit; "All
## bought" at its limit).
func row_line(what: String) -> String:
	var row := _row(what)
	if row.is_empty():
		return ""
	var count := int(_slot.bought.get(what, 0))
	var limit := int(row.limit)
	if limit > 0 and count >= limit:
		return "%s   All bought" % row.name
	if limit > 0:
		return "%s   %d Faith   %d / %d" % [row.name, _slot.faith_price(what), count, limit]
	return "%s   %d Faith   bought %d" % [row.name, _slot.faith_price(what), count]


## A left click at a screen point: Back goes back; a row is bought if it can be.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	if h == "back":
		UiSound.play(&"ui_click")
		action.emit("back")
		return
	buy(h)


## Buys one of `what`; true when bought. A refusal buzzes and says why for REFUSE_SECONDS.
func buy(what: String) -> bool:
	var why := _slot.faith_refusal(what)
	if why != "":
		UiSound.play(&"ui_buzz")
		refused_reason = String(REFUSALS.get(why, why))
		_refuse_left = REFUSE_SECONDS
		_redraw()
		return false
	_slot.buy(what)
	UiSound.play(&"ui_manifest")
	refused_reason = ""
	_redraw()
	action.emit("bought")
	return true


## What a row gives the god now (the small line under the row's name); "" for a row this does not know.
func effect_line(what: String) -> String:
	match what:
		"slot":
			return "Slots in a draft: %d" % _slot.slots()
		"might":
			return "Might to spend: %d" % _slot.max_might()
		"clock":
			return "Extra descent time: %d s" % int(_slot.extra_clock())
		"respec":
			return "Gives back every ability point spent (%d held)" % _slot.points
	return ""


func _row(what: String) -> Dictionary:
	for row: Dictionary in GodSlot.FAITH:
		if row.key == what:
			return row
	return {}


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _process(delta: float) -> void:
	if _refuse_left > 0.0:
		_refuse_left -= delta
		if _refuse_left <= 0.0:
			refused_reason = ""
			_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		UiSound.play(&"ui_click")
		action.emit("back")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "FAITH   %d" % _slot.faith, UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var keys := rows()
	for i in keys.size():
		_draw_row(i, keys[i])
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back")
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width("Back") * 0.5), BACK_RECT.position.y + 14.0),
		"Back", UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back" else UiTheme.COL_TEXT)
	var hint := refused_reason if refused_reason != "" else "Click to buy. Esc to go back."
	UiTheme.text(_ui, Vector2(BACK_RECT.end.x + 12.0, BACK_RECT.position.y + 14.0), hint, UiTheme.SIZE_SMALL,
		UiTheme.COL_BAD if refused_reason != "" else UiTheme.COL_DIM)


## A row: its line, and under it what it gives now; dim when it cannot be bought now.
func _draw_row(i: int, what: String) -> void:
	var r := row_rect(i)
	var can := _slot.faith_refusal(what) == ""
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == what else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, can and _hover == what)
	UiTheme.text(_ui, r.position + Vector2(8.0, 17.0), row_line(what), UiTheme.SIZE_BODY, UiTheme.COL_GOLD if can else UiTheme.COL_DIM)
	UiTheme.text(_ui, r.position + Vector2(8.0, 33.0), effect_line(what), UiTheme.SIZE_SMALL, UiTheme.COL_TEXT if can else UiTheme.COL_DIM)
