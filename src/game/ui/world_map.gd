class_name WorldMap
extends Node
## The World Map (World Map + Conquer Progress, Task 5): the page between the Chamber's table and Prepare. Six spots (WorldLayout): the two towns
## the god can go to, and four sealed ones. A town shows its people's percent; a town not yet opened says what opens it. Arrows or the mouse
## choose, Enter or the Descend button goes down, Esc or Back returns. Whether the god can descend is HubStatus's word.

## "descend" (the chosen town is `selected`) or "back".
signal action(name: String)

const SEALED_LINE := "Beyond your reach"
const LOCK_LINE := "Conquer %d%% of %s"
const NO_NIGHT := "No night waits there yet"
const HINT := "Arrows: choose   Enter: Descend   Esc: Back"
const BACK_W := 60.0
const BACK_H := 18.0
const PLATE := Rect2(190.0, 290.0, 260.0, 56.0)
const HINT_Y := 356.0
const LINE_Y := 284.0

var selected := ""
## A one-off message shown above the info plate ("" for none).
var line := ""
var status: HubStatus
var _slot: GodSlot
var _ui: Control
var _dev := false


func setup(slot: GodSlot, p_dev := false) -> WorldMap:
	_slot = slot
	_dev = p_dev
	status = HubStatus.new(slot)
	# The town last played, when it is open and a night is drawn there (a Hunt due, or a tier it hosts nothing of, would only buzz).
	selected = Conquest.HOME
	if WorldLayout.is_town(slot.last_town) and Conquest.is_open(slot, slot.last_town) and GodNight.draw(slot, slot.last_town) != "":
		selected = slot.last_town
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)
	_ui.draw.connect(_draw_ui)
	# As the Chamber: the blocker takes the mouse and hands it on in frame units; the 640x360 child ignores it.
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(_ui.get_parent() as Control).gui_input.connect(_on_blocker_input)
	return self


## "sealed", "locked", "dim" (open, but no night is drawn there; a conquered town too), "conquered" or "open".
func spot_state(id: String) -> String:
	if not WorldLayout.is_town(id):
		return "sealed"
	if not Conquest.is_open(_slot, id):
		return "locked"
	if GodNight.draw(_slot, id) == "":
		return "dim"  # before "conquered" (spec 4.6): a conquered town with no night to go to is dim too
	if Conquest.conquered(_slot, id):
		return "conquered"
	return "open"


func selectable(id: String) -> bool:
	return spot_state(id) in ["open", "dim", "conquered"]


func select(id: String) -> bool:
	if not selectable(id):
		return false
	selected = id
	line = ""  # a refusal's words belong to the spot it was said of
	_redraw()
	return true


## Moves the selection to the selectable spot lying most nearly in `dir` (a positive dot with it; a tie goes to the nearer); nothing when none.
func move(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var from: Vector2 = WorldLayout.spot(selected).get("place", Vector2.ZERO)
	var best := ""
	var best_dot := 0.0
	var best_dist := 0.0
	for id in WorldLayout.ids():
		if id == selected or not selectable(id):
			continue
		var v: Vector2 = (WorldLayout.spot(id).place as Vector2) - from
		var dot := v.normalized().dot(dir.normalized())
		if dot <= 0.0:
			continue
		var dist := v.length()
		if dot > best_dot + 0.0001 or (absf(dot - best_dot) <= 0.0001 and dist < best_dist):
			best = id
			best_dot = dot
			best_dist = dist
	if best != "":
		UiSound.play(&"ui_hover")
		select(best)


## Enter or the Descend button: refused when the god has nothing to draft or no night waits in the town; else emits "descend".
func press_descend() -> void:
	if not status.can_descend():
		UiSound.play(&"ui_buzz")
		line = HubStatus.BLOCKED
		_redraw()
		return
	if GodNight.draw(_slot, selected) == "":
		UiSound.play(&"ui_buzz")
		line = NO_NIGHT
		_redraw()
		return
	UiSound.play(&"ui_click")
	action.emit("descend")


## The Back button, at the bottom left of the screen.
func back_rect() -> Rect2:
	var back := UiScale.backdrop(_ui)
	return Rect2(back.position.x + 12.0, 330.0, BACK_W, BACK_H)


## The Descend button, on the info plate.
func descend_rect() -> Rect2:
	return Rect2(PLATE.end.x - 72.0, PLATE.position.y + 30.0, 64.0, 18.0)


## What the plate says of a spot: an open town its name, percent and believers (and "Conquered"); a locked one its name and what opens it; a
## sealed one its name and that it is beyond reach.
func info_lines(id: String) -> PackedStringArray:
	var out := PackedStringArray([WorldLayout.name_of(id)])
	match spot_state(id):
		"sealed":
			out.append(SEALED_LINE)
		"locked":
			out.append(LOCK_LINE % [Conquest.UNLOCK_PERCENT, Conquest.town_name(Conquest.opener_of(id))])
		_:
			out.append("%d%%" % Conquest.percent_of(_slot, id))
			out.append("%d / %d believers" % [Conquest.count_of(_slot, id), Conquest.population(id)])
			if Conquest.conquered(_slot, id):
				out.append("Conquered")
	return out


## A left click at a frame point.
func click(point: Vector2) -> void:
	if back_rect().has_point(point):
		UiSound.play(&"ui_click")
		action.emit("back")
		return
	if descend_rect().has_point(point):
		press_descend()
		return
	var id := WorldLayout.at(point)
	if id == "":
		return
	if id == selected:
		press_descend()
	elif selectable(id):
		UiSound.play(&"ui_hover")
		select(id)
	else:
		UiSound.play(&"ui_buzz")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_LEFT: move(Vector2.LEFT)
		KEY_RIGHT: move(Vector2.RIGHT)
		KEY_UP: move(Vector2.UP)
		KEY_DOWN: move(Vector2.DOWN)
		KEY_ENTER, KEY_KP_ENTER: press_descend()
		KEY_ESCAPE: action.emit("back")


func _on_blocker_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var e := event.duplicate() as InputEventMouse
	e.position = (event.position - _ui.position) / maxf(_ui.scale.x, 0.0001)
	_on_gui_input(e)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


# --- drawing -------------------------------------------------------------------------------------------------------------------------------

func _spot_color(id: String) -> Color:
	if id == selected:
		return UiTheme.COL_GOLD
	match spot_state(id):
		"open", "conquered": return Color.WHITE
		"dim", "locked": return Color(0.55, 0.55, 0.58)
	return Color(0.16, 0.16, 0.18)


func _draw_ui() -> void:
	var back := UiScale.backdrop(_ui)
	_ui.draw_rect(back, Color(0.04, 0.07, 0.12))
	var tex := ChamberArt.texture("map")
	if tex != null:
		_ui.draw_texture_rect(tex, back, false)
	else:
		_ui.draw_rect(WorldLayout.LAND, ChamberArt.greybox_color("table").lerp(Color(0.22, 0.30, 0.22), 0.7))
		_ui.draw_rect(WorldLayout.LAND, UiTheme.COL_GOLD_DARK, false, 1.0)
	for road: Array in WorldLayout.ROADS:
		_ui.draw_line(WorldLayout.spot(road[0]).place, WorldLayout.spot(road[1]).place, Color(0.62, 0.52, 0.34), 2.0)
	for id in WorldLayout.ids():
		_draw_spot(id)
	var title := "THE WORLD"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_BODY) * 0.5), 22.0), title, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	_draw_plate()
	_draw_button(back_rect(), "Back")
	var hint_x := roundf(320.0 - UiTheme.width(HINT, UiTheme.SIZE_SMALL) * 0.5)
	UiTheme.text(_ui, Vector2(hint_x, HINT_Y), HINT, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	if line != "":
		var w := UiTheme.width(line, UiTheme.SIZE_SMALL) + 12.0
		var pill := Rect2(roundf(320.0 - w * 0.5), LINE_Y - 12.0, w, 16.0)
		_ui.draw_rect(pill, Color(0.02, 0.02, 0.03, 0.85))
		UiTheme.text(_ui, Vector2(pill.position.x + 6.0, LINE_Y), line, UiTheme.SIZE_SMALL, UiTheme.COL_BAD_TEXT)


func _draw_spot(id: String) -> void:
	var p: Vector2 = WorldLayout.spot(id).place
	var state := spot_state(id)
	var col := _spot_color(id)
	var r := 9.0
	var diamond := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)])
	_ui.draw_colored_polygon(diamond, col)
	diamond.append(diamond[0])
	_ui.draw_polyline(diamond, Color(0.0, 0.0, 0.0, 0.8), 1.0)
	if Conquest.conquered(_slot, id):
		_ui.draw_arc(p, r + 3.0, 0.0, TAU, 20, UiTheme.COL_GOLD, 1.5)
	var y := p.y + r + 3.0
	if WorldLayout.is_town(id) and state != "locked":
		var bar := Rect2(p.x - 14.0, y, 28.0, 3.0)
		_ui.draw_rect(bar, Color(0.08, 0.08, 0.1))
		_ui.draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * float(Conquest.percent_of(_slot, id)) / 100.0), bar.size.y)), UiTheme.COL_GOLD)
		y += 5.0
	var label := WorldLayout.name_of(id)
	var tcol := UiTheme.COL_TEXT if state in ["open", "conquered", "dim"] else UiTheme.COL_DIM
	UiTheme.text(_ui, Vector2(roundf(p.x - UiTheme.width(label, UiTheme.SIZE_SMALL) * 0.5), y + 10.0), label, UiTheme.SIZE_SMALL, tcol)


func _draw_plate() -> void:
	_ui.draw_rect(PLATE, Color(0.02, 0.02, 0.03, 0.88))
	UiTheme.frame(_ui, PLATE, false)
	var lines := info_lines(selected)
	for i in lines.size():
		var col := UiTheme.COL_GOLD if i == 0 else UiTheme.COL_TEXT
		UiTheme.text(_ui, Vector2(PLATE.position.x + 8.0, PLATE.position.y + 12.0 + 12.0 * float(i)), lines[i], UiTheme.SIZE_SMALL, col)
	_draw_button(descend_rect(), "Descend", status.can_descend() and GodNight.draw(_slot, selected) != "")


func _draw_button(r: Rect2, label: String, lit := true) -> void:
	_ui.draw_rect(r, Color(0.10, 0.09, 0.07, 0.95))
	UiTheme.frame(_ui, r, lit)
	var col := UiTheme.COL_TEXT if lit else UiTheme.COL_DIM
	UiTheme.text(_ui, Vector2(roundf(r.get_center().x - UiTheme.width(label, UiTheme.SIZE_SMALL) * 0.5), r.position.y + 13.0), label, UiTheme.SIZE_SMALL, col)
