class_name UpgradesScreen
extends Node
## The Upgrades (v0.11 M1, spec §3.4): believers spent on the tier board's god -- +1 Divine Power (the n-th for 25 x n, six
## at most), +1 slot (150, once) and each locked power (15 x its DP). Board missions only: the campaign keeps its own DP. A
## click buys what it can afford; one it cannot buzzes and says why. Esc or Board goes back to the tier board.

## "bought" (something was bought: Game writes the save) or "back".
signal action(name: String)

## The two upgrades' buttons on the left, the locked powers' grid beside them (COLUMNS a row), the Board button, and how long
## a refusal's reason stays up.
const DP_RECT := Rect2(8.0, 52.0, 196.0, 40.0)
const SLOT_RECT := Rect2(8.0, 100.0, 196.0, 40.0)
const GRID_AT := Vector2(216.0, 52.0)
const CELL := Vector2(136.0, 20.0)
const CELL_GAP := 4.0
const COLUMNS := 3
const BACK_RECT := Rect2(8.0, 322.0, 100.0, 20.0)
const REFUSE_SECONDS := 1.5
## What a refused purchase says, by DescendState.refusal().
const REFUSALS := {"believers": "Not enough believers", "limit": "None left to buy", "owned": "Already unlocked",
	"unknown": "Not a power"}

## The powers locked when the screen opened, in PowerBook's order: the grid keeps their places as they are bought.
var powers := PackedStringArray()
## Why the last click bought nothing, shown for REFUSE_SECONDS; "" for none.
var refused_reason := ""
var _refuse_left := 0.0
var _state: DescendState
var _ui: Control
var _hover := ""


func setup(state: DescendState) -> UpgradesScreen:
	_state = state
	powers = state.locked()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The grid's cell `i`.
static func cell_rect(i: int) -> Rect2:
	var col := i % COLUMNS
	var row := i / COLUMNS
	return Rect2(GRID_AT + Vector2(float(col) * (CELL.x + CELL_GAP), float(row) * (CELL.y + CELL_GAP)), CELL)


## What is under a point: "dp", "slot", "back", a power key, or "".
func hit(point: Vector2) -> String:
	if DP_RECT.has_point(point):
		return "dp"
	if SLOT_RECT.has_point(point):
		return "slot"
	if BACK_RECT.has_point(point):
		return "back"
	for i in powers.size():
		if cell_rect(i).has_point(point):
			return powers[i]
	return ""


## Where `what` is drawn: "dp", "slot", "back" or a power key's cell; an empty Rect2 for none.
func button_rect(what: String) -> Rect2:
	match what:
		"dp":
			return DP_RECT
		"slot":
			return SLOT_RECT
		"back":
			return BACK_RECT
	var i := powers.find(what)
	return cell_rect(i) if i >= 0 else Rect2()


## A left click at a screen point: Board goes back; anything else is bought if it can be.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	if h == "back":
		UiSound.play(&"ui_click")
		action.emit("back")
		return
	buy(h)


## Buys `what`; true when bought. A refusal buzzes and says why for REFUSE_SECONDS.
func buy(what: String) -> bool:
	var why := _state.refusal(what)
	if why != "":
		UiSound.play(&"ui_buzz")
		refused_reason = String(REFUSALS.get(why, why))
		_refuse_left = REFUSE_SECONDS
		_redraw()
		return false
	_state.buy(what)
	UiSound.play(&"ui_manifest")
	refused_reason = ""
	_redraw()
	action.emit("bought")
	return true


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
	UiTheme.text(_ui, Vector2(8, 24), "UPGRADES", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var purse := "Believers %d" % _state.believers
	UiTheme.text(_ui, Vector2(632.0 - UiTheme.width(purse, UiTheme.SIZE_BODY), 24.0), purse, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	var dp_line := "All six bought" if _state.dp_bought >= DescendState.DP_LIMIT else "%d believers   %d / %d" % [_state.dp_price(),
		_state.dp_bought, DescendState.DP_LIMIT]
	_draw_button(DP_RECT, "+1 DIVINE POWER", dp_line, "dp")
	var slot_line := "Bought" if _state.slot_bought >= DescendState.SLOT_LIMIT else "%d believers" % DescendState.SLOT_PRICE
	_draw_button(SLOT_RECT, "+1 SLOT", slot_line, "slot")
	var budget := "Board missions: their tier's budget +%d DP, +%d slot" % [_state.dp_bought, _state.slot_bought]
	for i in UiTheme.wrap(budget, DP_RECT.size.x, UiTheme.SIZE_SMALL).size():
		UiTheme.text(_ui, Vector2(8.0, SLOT_RECT.end.y + 16.0 + UiTheme.LINE_SMALL * float(i)),
			UiTheme.wrap(budget, DP_RECT.size.x, UiTheme.SIZE_SMALL)[i], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(GRID_AT.x, GRID_AT.y - 6.0), "UNLOCK A POWER", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	for i in powers.size():
		_draw_cell(i, powers[i])
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back")
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width("Board") * 0.5), BACK_RECT.position.y + 14.0),
		"Board", UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back" else UiTheme.COL_TEXT)
	var hint := refused_reason if refused_reason != "" else "Click to buy. Esc for the board."
	UiTheme.text(_ui, Vector2(BACK_RECT.end.x + 12.0, BACK_RECT.position.y + 14.0), hint, UiTheme.SIZE_SMALL,
		UiTheme.COL_BAD if refused_reason != "" else UiTheme.COL_DIM)


## An upgrade's button: its name, and under it its price and count; dim when it cannot be bought now.
func _draw_button(r: Rect2, title: String, line: String, what: String) -> void:
	var can := _state.refusal(what) == ""
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == what else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, can and _hover == what)
	UiTheme.text(_ui, r.position + Vector2(8.0, 16.0), title, UiTheme.SIZE_BODY, UiTheme.COL_GOLD if can else UiTheme.COL_DIM)
	UiTheme.text(_ui, r.position + Vector2(8.0, 32.0), line, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT if can else UiTheme.COL_DIM)


## A locked power's cell: its name cut to fit and its price; "Unlocked" once bought; dim when unaffordable.
func _draw_cell(i: int, key: String) -> void:
	var r := cell_rect(i)
	var owned := _state.is_unlocked(key)
	var can := _state.refusal(key) == ""
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if _hover == key else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, owned or (can and _hover == key))
	var price := "Unlocked" if owned else "%d" % DescendState.unlock_price(key)
	var price_w := UiTheme.width(price, UiTheme.SIZE_SMALL)
	var name := UiTheme.fit(String(PowerBook.get_power(key).name), r.size.x - price_w - 14.0)
	UiTheme.text(_ui, r.position + Vector2(4.0, 14.0), name, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if owned else (UiTheme.COL_TEXT if can else UiTheme.COL_DIM))
	UiTheme.text(_ui, Vector2(r.end.x - 4.0 - price_w, r.position.y + 14.0), price, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if owned else UiTheme.COL_DIM)
