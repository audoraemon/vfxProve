class_name GodChamber
extends Node
## The God's Chamber (spec docs/superpowers/specs/2026-11-19-kak-god-chamber-design.md): where a god stands between nights. It replaces the
## hub on Screen.HUB: four stations (World Table, Ability Tree, Faith Altar, Rite Door) in a room that shifts a little against the mouse, a
## slim top bar with the god's status, the Hunt and seal lines, and the bottom lines. The words and decisions come from HubStatus, the
## rects and keys from ChamberLayout, the pictures from ChamberArt (greybox until art is painted).

## "descend", "awaken", "tree", "faith", "title" or "awaken_dev".
signal action(name: String)

## The words the screen says, kept here under their old names (HubStatus holds them).
const BLOCKED := HubStatus.BLOCKED
const HUNT_DUE := HubStatus.HUNT_DUE
const SEALED := HubStatus.SEALED
const AWAKEN_HUNT := HubStatus.AWAKEN_HUNT
const RITE_UNWRITTEN := HubStatus.RITE_UNWRITTEN
const GIFTS_LINE := HubStatus.GIFTS_LINE
## The widest the one-off line may be before it wraps.
const LINE_WIDTH := 600.0
## The Title button at the bar's right end (its width), and the Notice meter's size in the bar.
const TITLE_W := 34.0
const NOTICE_W := 36.0
const BAR_GAP := 8.0

## A one-off message shown near the bottom (e.g. GodNight.ABANDONED); "" for none.
var line := ""
## True in the DEV build: A is the Awaken hook.
var dev := false
var status: HubStatus
## The station whose page the god is coming back from (Task 4 plays the zoom back from it); "" for none.
var from := ""
var _slot: GodSlot
var _ui: Control
var _hover := ""
## The mouse from the area's centre, -1..1 on each axis: what the parallax follows.
var _mouse01 := Vector2.ZERO


func setup(slot: GodSlot, p_line := "", p_dev := false, p_from := "") -> GodChamber:
	_slot = slot
	line = p_line
	dev = p_dev
	from = p_from
	status = HubStatus.new(slot)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = UiScale.design_frame(layer, Control.MOUSE_FILTER_STOP)  # 640x360 coordinates, centred in the area
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	return self


## The Divine Power bar's words (see HubStatus.bar_text).
static func bar_text(slot: GodSlot) -> String:
	return HubStatus.bar_text(slot)


## The status lines (see HubStatus.lines).
func lines() -> PackedStringArray:
	return status.lines()


func can_descend() -> bool:
	return status.can_descend()


## The top bar's rect in frame coordinates: from the area's left edge to its right edge, 22 units high.
func bar_rect() -> Rect2:
	var back := UiScale.backdrop(_ui)
	return Rect2(back.position.x, 0.0, back.size.x, ChamberLayout.BAR_H)


## The Title button's rect, at the bar's right end.
func title_rect() -> Rect2:
	var bar := bar_rect()
	return Rect2(bar.end.x - TITLE_W - 4.0, 3.0, TITLE_W, ChamberLayout.BAR_H - 6.0)


## The station's current rect ("descend", "tree", "faith", "awaken") with the parallax; the Title button's for "title"; empty for none.
func menu_rect(what: String) -> Rect2:
	if what == "title":
		return title_rect()
	if ChamberLayout.STATIONS.has(what):
		return ChamberLayout.rect_of(what, _mouse01)
	return Rect2()


## "", "hover", "dim" or "closed" for a station: the Rite Door is closed while the god is not capped; Descend and a Door that is not ready are
## dim; the hovered station is "hover".
func station_state(key: String) -> String:
	if key == "awaken" and not status.awaken_shown():
		return "closed"
	if (key == "descend" and not status.can_descend()) or (key == "awaken" and status.awaken_dim()):
		return "dim"
	return "hover" if key == _hover else ""


## The red "!" on a station: unspent points on the tree, Faith to spend at the altar, a rite ready (or the Hunt leading) at the door.
func badge(key: String) -> bool:
	match key:
		"tree": return _slot.points > 0
		"faith": return status.faith_affordable()
		"awaken": return status.awaken_shown() and not status.awaken_dim()
	return false


## The keys row: the Awaken key joins it while the door is open, else the dev hook is named under --dev.
func hint_text() -> String:
	var hint := "Enter: Descend   T: Tree   F: Faith   Esc: Title"
	if status.awaken_shown():
		hint += "   A: Awaken"
	elif dev:
		hint += "   DEV  A: awaken"
	return hint


## The station under a frame point; a closed door is skipped (no hover, no click).
func _station_at(point: Vector2) -> String:
	var key := ChamberLayout.at(point, _mouse01)
	if key == "awaken" and not status.awaken_shown():
		return ""
	return key


## A left click at a frame point: the Title button, or the station there.
func click(point: Vector2) -> void:
	if title_rect().has_point(point):
		_press("title")
		return
	var key := _station_at(point)
	if key != "":
		_press(key)


## Plays and sends what HubStatus decided for a press: a buzz, a click and the action, or the one-off line.
func _press(what: String, from_key := false) -> void:
	var result := status.press(what, from_key, dev)
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
	if event.physical_keycode == KEY_ESCAPE:
		_press("title")
		return
	var key := ChamberLayout.key_for(event.physical_keycode)
	if key == "":
		return
	if key == "awaken":
		# The A key is the dev hook and the "rite not written" line; the 4 key is the door and nothing else.
		if event.physical_keycode == KEY_A:
			_press("awaken", true)
		elif status.awaken_shown():
			_press("awaken")
		return
	_press(key)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_follow_mouse(event.position)
	if event is InputEventMouseMotion:
		var h := _station_at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
		_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


## Moves the parallax to follow the mouse (a frame point), and redraws when the room moved.
func _follow_mouse(point: Vector2) -> void:
	var back := UiScale.backdrop(_ui)
	var m := ((point - back.get_center()) / (back.size * 0.5)).clamp(Vector2(-1, -1), Vector2(1, 1))
	if m != _mouse01:
		_mouse01 = m
		_redraw()


# --- drawing -------------------------------------------------------------------------------------------------------------------------------

func _layer_rect(rect: Rect2, layer: String) -> Rect2:
	return Rect2(rect.position + ChamberLayout.shift(layer, _mouse01), rect.size)


func _draw_station(key: String) -> void:
	var state := station_state(key)
	if state == "hover":
		state = ""  # hovering lights the outline, not the picture
	ChamberArt.draw(_ui, key, menu_rect(key), state)


func _draw_ui() -> void:
	var back := UiScale.backdrop(_ui)
	_ui.draw_rect(back, ChamberArt.greybox_color("wall"))
	# Back to front: wall, the stations on the wall, the stations layer, the table with its station, the desk.
	for piece: Dictionary in ChamberLayout.SCENERY:
		if piece.name == "wall":
			ChamberArt.draw(_ui, "wall", _layer_rect(piece.rect, piece.layer))
	for layer in ["wall", "stations", "table"]:
		if layer == "table":
			for piece: Dictionary in ChamberLayout.SCENERY:
				if piece.name == "table":
					ChamberArt.draw(_ui, "table", _layer_rect(piece.rect, piece.layer))
		for key: String in ChamberLayout.ORDER:
			if ChamberLayout.STATIONS[key].layer == layer:
				_draw_station(key)
	for piece: Dictionary in ChamberLayout.SCENERY:
		if piece.name == "desk":
			# The desk is wider than the frame so a wide window still meets it; extend it to the backdrop's edges.
			var r := _layer_rect(piece.rect, piece.layer)
			var left := minf(r.position.x, back.position.x)
			var right := maxf(r.end.x, back.end.x)
			ChamberArt.draw(_ui, "desk", Rect2(left, r.position.y, right - left, r.size.y))
	for key: String in ChamberLayout.ORDER:
		if _hover == key and station_state(key) != "closed":
			_draw_outline_and_plate(key)
	for key: String in ChamberLayout.ORDER:
		if badge(key):
			_draw_badge(menu_rect(key))
	_draw_bar()
	_draw_under_bar()
	_draw_bottom()


func _draw_outline_and_plate(key: String) -> void:
	var r := menu_rect(key)
	_ui.draw_rect(r, UiTheme.COL_GOLD, false, 1.0)
	var name: String = ChamberLayout.STATIONS[key].name
	var w := UiTheme.width(name, UiTheme.SIZE_SMALL) + 10.0
	var plate := Rect2(roundf(r.get_center().x - w * 0.5), r.end.y + 3.0, w, 15.0)
	_ui.draw_rect(plate, Color(0.02, 0.02, 0.03, 0.85))
	UiTheme.text(_ui, Vector2(plate.position.x + 5.0, plate.position.y + 12.0), name, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)


func _draw_badge(r: Rect2) -> void:
	var c := Vector2(r.end.x, r.position.y)
	_ui.draw_circle(c, 6.0, UiTheme.COL_BAD)
	UiTheme.text(_ui, c + Vector2(-2.0, 4.0), "!", UiTheme.SIZE_SMALL, Color.WHITE)


func _draw_bar() -> void:
	var bar := bar_rect()
	_ui.draw_rect(bar, Color(0.03, 0.03, 0.05, 0.92))
	_ui.draw_rect(Rect2(bar.position.x, bar.end.y, bar.size.x, 1.0), UiTheme.COL_GOLD_DARK)
	var text := lines()
	var y := 15.0
	# Left: the type's title, then the level and the tier's name.
	var left_x := bar.position.x + 6.0
	UiTheme.text(_ui, Vector2(left_x, y), text[0], UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	var x := left_x + UiTheme.width(text[0], UiTheme.SIZE_SMALL) + 8.0
	UiTheme.text(_ui, Vector2(x, y), text[1], UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	var left_end := x + UiTheme.width(text[1], UiTheme.SIZE_SMALL)
	# Right, built from the Title button leftwards: Night, the Notice meter and percent, Faith, ability points.
	var tr := title_rect()
	_ui.draw_rect(tr, Color(0.10, 0.09, 0.07, 0.95))
	UiTheme.frame(_ui, tr, false)
	UiTheme.text(_ui, Vector2(roundf(tr.get_center().x - UiTheme.width("Title", UiTheme.SIZE_SMALL) * 0.5), y - 1.0), "Title", UiTheme.SIZE_SMALL,
		UiTheme.COL_TEXT)
	var rx := tr.position.x - BAR_GAP
	var night := text[6]
	rx -= UiTheme.width(night, UiTheme.SIZE_SMALL)
	UiTheme.text(_ui, Vector2(rx, y), night, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	rx -= BAR_GAP
	var pct := "%d%%" % _slot.notice
	rx -= UiTheme.width(pct, UiTheme.SIZE_SMALL)
	UiTheme.text(_ui, Vector2(rx, y), pct, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	var meter := Rect2(rx - 3.0 - NOTICE_W, 8.0, NOTICE_W, 6.0)
	_ui.draw_rect(meter, Color(0.10, 0.04, 0.04, 0.9))
	_ui.draw_rect(Rect2(meter.position, Vector2(roundf(meter.size.x * status.notice_fill()), meter.size.y)), UiTheme.COL_BAD)
	UiTheme.frame(_ui, meter, false)
	rx = meter.position.x - BAR_GAP
	var faith := "Faith %d" % _slot.faith
	rx -= UiTheme.width(faith, UiTheme.SIZE_SMALL)
	UiTheme.text(_ui, Vector2(rx, y), faith, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT)
	rx -= BAR_GAP
	var pts := "Points %d" % _slot.points
	rx -= UiTheme.width(pts, UiTheme.SIZE_SMALL)
	UiTheme.text(_ui, Vector2(rx, y), pts, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if _slot.points > 0 else UiTheme.COL_TEXT)
	# Centre: the Divine Power bar, centred on the area and kept clear of the left and right groups.
	var lo := left_end + BAR_GAP
	var hi := rx - BAR_GAP
	var w := minf(150.0, hi - lo)
	var cx := clampf(bar.get_center().x, lo + w * 0.5, hi - w * 0.5)
	var pr := Rect2(roundf(cx - w * 0.5), 6.0, roundf(w), 10.0)
	_ui.draw_rect(pr, Color(0.04, 0.04, 0.06, 0.85))
	_ui.draw_rect(Rect2(pr.position, Vector2(roundf(pr.size.x * status.bar_fill()), pr.size.y)), UiTheme.COL_GOLD_DARK)
	UiTheme.frame(_ui, pr, false)
	var bt := UiTheme.fit(text[2], pr.size.x - 4.0, UiTheme.SIZE_SMALL)
	UiTheme.text(_ui, Vector2(roundf(pr.get_center().x - UiTheme.width(bt, UiTheme.SIZE_SMALL) * 0.5), pr.position.y + 9.0), bt, UiTheme.SIZE_SMALL,
		UiTheme.COL_TEXT)


## The Hunt and the seal, in red, centred under the bar.
func _draw_under_bar() -> void:
	var y := ChamberLayout.BAR_H + 14.0
	for s: String in [status.hunt_line(), status.seal_line()]:
		if s != "":
			UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(s) * 0.5), y), s, UiTheme.SIZE_BODY, UiTheme.COL_BAD_TEXT)
			y += UiTheme.LINE_BODY


## The bottom block, stacked upward: the keys hint, the blocked line, the stolen gifts, the one-off line (wrapped to 600).
func _draw_bottom() -> void:
	var y := 350.0
	var hint := hint_text()
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), y), hint, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	y -= 14.0
	var blocked := status.blocked_line()
	if blocked != "":
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(blocked, UiTheme.SIZE_SMALL) * 0.5), y), blocked, UiTheme.SIZE_SMALL, UiTheme.COL_BAD_TEXT)
		y -= 14.0
	var gifts := status.gifts_line()
	if gifts != "":
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(gifts) * 0.5), y), gifts, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
		y -= UiTheme.LINE_BODY
	if line != "":
		var wrapped := UiTheme.wrap(line, LINE_WIDTH, UiTheme.SIZE_BODY)
		for i in range(wrapped.size() - 1, -1, -1):
			UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(wrapped[i]) * 0.5), y), wrapped[i], UiTheme.SIZE_BODY, UiTheme.COL_BAD_TEXT)
			y -= UiTheme.LINE_BODY
