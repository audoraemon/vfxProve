class_name PrepareScreen
extends Node
## Prepare (spec §1, §5): the briefing and the card under the mouse on the left, the eleven power cards in a
## grid on the right, and MANIFEST in the grid's twelfth cell once four are picked.
##
## One deviation from the spec's layout, forced by 640x360: the cards carry the 42-pixel HUD icons, and the
## 84-pixel card art is shown large in the left panel for the card under the mouse. Eleven cards with the big
## art and a readable name do not fit on this screen.

## "manifest" (four are picked and the player pressed MANIFEST or Enter) or "back" (Esc).
signal action(name: String)

const CARD := Vector2(140.0, 64.0)
const GAP := 6.0
const GRID_AT := Vector2(196.0, 40.0)
const COLUMNS := 3
## The left panel: briefing above, the card under the mouse below.
const PANEL := Rect2(8.0, 40.0, 180.0, 274.0)
const BADGE := 13.0
## Where the briefing's values start, right of its labels (TARGET is the widest, 31 px at SIZE_SMALL).
const VALUE_X := 42.0

var draft := Draft.new()

var _ui: Control
## Both icon sizes, loaded once here and never inside _draw() (a texture loaded while drawing can reach the
## draw list before the GPU has it and paint a white block that stays).
var _icons := {}
var _art := {}
var _best_score := 0
var _best_rank := ""
## The power key under the mouse, "manifest", or "".
var _hover := ""


func setup(preselect: PackedStringArray, best_score: int, best_rank: String) -> PrepareScreen:
	draft.preselect(preselect)
	_best_score = best_score
	_best_rank = best_rank
	for p: Dictionary in PowerBook.POWERS:
		var key := String(p.key)
		_icons[key] = PowerBook.hud_icon(key)
		_art[key] = PowerBook.icon(key)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## Where cell `i` sits: 0-10 are the powers in PowerBook order, 11 is MANIFEST.
static func cell_rect(i: int) -> Rect2:
	var col := i % COLUMNS
	var row := i / COLUMNS
	return Rect2(GRID_AT + Vector2(float(col) * (CARD.x + GAP), float(row) * (CARD.y + GAP)), CARD)


## What is under a point: a power key, "manifest", or "".
func hit(point: Vector2) -> String:
	for i in PowerBook.POWERS.size():
		if cell_rect(i).has_point(point):
			return String(PowerBook.POWERS[i].key)
	if cell_rect(PowerBook.POWERS.size()).has_point(point):
		return "manifest"
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			action.emit("back")
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and draft.is_full():
			action.emit("manifest")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h := hit(event.position)
		if h == "manifest":
			if draft.is_full():
				action.emit("manifest")
		elif h != "":
			draft.toggle(h)
			_ui.queue_redraw()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "PREPARE THE MANIFESTATION", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	if _best_score > 0:
		var best := "Best %d  %s" % [_best_score, _best_rank]
		UiTheme.text(_ui, Vector2(632.0 - UiTheme.width(best, UiTheme.SIZE_SMALL), 24.0), best, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_draw_panel()
	for i in PowerBook.POWERS.size():
		_draw_card(i)
	_draw_manifest()


func _draw_panel() -> void:
	_ui.draw_rect(PANEL, UiTheme.COL_PANEL)
	var brief := [
		["TARGET", "Aldermere and its Royal Citadel"],
		["WIN", "Bring down the Citadel and break the city before %s" % UiTheme.clock(Rules.MISSION_SECONDS)],
		["LOSE", "%d citizens escape, or the time runs out" % Rules.ESCAPE_LIMIT],
		["CITY", "%d citizens, %d soldiers, a nine-part fortress" % [Crowd.CITIZENS, Crowd.SOLDIERS]],
		["POWER", "%d DP, +%.1f a second; towers, gates, soldiers and chains pay back" % [int(Rules.DP_MAX), Rules.DP_REGEN]],
	]
	var y := PANEL.position.y + 10.0
	for pair: Array in brief:
		UiTheme.text(_ui, Vector2(PANEL.position.x + 4.0, y), String(pair[0]), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		for line in UiTheme.wrap(String(pair[1]), PANEL.size.x - VALUE_X - 4.0, UiTheme.SIZE_SMALL):
			UiTheme.text(_ui, Vector2(PANEL.position.x + VALUE_X, y), line, UiTheme.SIZE_SMALL)
			y += UiTheme.LINE_SMALL
		y += 3.0
	# The card under the mouse, with its big art.
	var p := PowerBook.get_power(_hover)
	if p.is_empty():
		var hint := UiTheme.wrap("Pick four powers, in the order you want them", PANEL.size.x - 8.0, UiTheme.SIZE_SMALL)
		for i in hint.size():
			UiTheme.text(_ui, Vector2(PANEL.position.x + 4.0, PANEL.end.y - 8.0 - UiTheme.LINE_SMALL * float(hint.size() - 1 - i)),
				hint[i], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		return
	var art_at := Vector2(PANEL.position.x + 4.0, PANEL.end.y - 92.0)
	var art: Texture2D = _art.get(_hover)
	if art != null:
		_ui.draw_texture_rect(art, Rect2(art_at, Vector2(84, 84)), false)
		UiTheme.frame(_ui, Rect2(art_at, Vector2(84, 84)), true)
	var tx := art_at.x + 92.0
	var ty := art_at.y + 10.0
	for line in UiTheme.wrap(String(p.name), PANEL.end.x - tx - 4.0, UiTheme.SIZE_SMALL):
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		ty += UiTheme.LINE_SMALL
	ty += 3.0
	for line in ["%d DP  %d s" % [int(p.dp), int(p.cooldown)], "aim: %s" % String(p.aim)]:
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL)
		ty += UiTheme.LINE_SMALL
	for line in UiTheme.wrap(String(p.shape), PANEL.end.x - tx - 4.0, UiTheme.SIZE_SMALL):
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		ty += UiTheme.LINE_SMALL


func _draw_card(i: int) -> void:
	var p: Dictionary = PowerBook.POWERS[i]
	var key := String(p.key)
	var r := cell_rect(i)
	var slot := draft.slot_of(key)
	_ui.draw_rect(r, UiTheme.COL_PANEL if key != _hover else Color(0.1, 0.09, 0.07, 0.9))
	var icon: Texture2D = _icons.get(key)
	if icon != null:
		_ui.draw_texture_rect(icon, Rect2(r.position + Vector2(4, 4), Vector2(42, 42)), false)
	# Gold for a picked card (spec §5), so the four read at a glance across the grid.
	UiTheme.frame(_ui, r, slot > 0)
	var tx := r.position.x + 52.0
	var ty := r.position.y + 14.0
	for line in UiTheme.wrap(String(p.name), CARD.x - 56.0, UiTheme.SIZE_SMALL):
		UiTheme.text(_ui, Vector2(tx, ty), line, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if slot > 0 else UiTheme.COL_TEXT)
		ty += UiTheme.LINE_SMALL
	UiTheme.text(_ui, Vector2(tx, r.position.y + 42.0), "%d DP  %d s" % [int(p.dp), int(p.cooldown)], UiTheme.SIZE_SMALL)
	# The shape's first clause is short enough for the card; the whole of it is in the left panel.
	var short := String(p.shape).split(",")[0]
	UiTheme.text(_ui, Vector2(r.position.x + 4.0, r.end.y - 4.0), short, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	if slot > 0:
		var badge := Rect2(Vector2(r.end.x - BADGE - 3.0, r.position.y + 3.0), Vector2(BADGE, BADGE))
		_ui.draw_rect(badge, UiTheme.COL_GOLD)
		UiTheme.text(_ui, badge.position + Vector2(3.0, 11.0), "%d" % slot, UiTheme.SIZE_SMALL, Color(0.08, 0.06, 0.02))


func _draw_manifest() -> void:
	var r := cell_rect(PowerBook.POWERS.size())
	var full := draft.is_full()  # not "ready": that is Node's own signal, and shadowing it warns
	_ui.draw_rect(r, Color(0.12, 0.1, 0.04, 0.95) if full else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, full and _hover == "manifest")
	var label := "MANIFEST"
	var col := UiTheme.COL_GOLD if full else UiTheme.COL_DIM
	UiTheme.text(_ui, Vector2(roundf(r.get_center().x - UiTheme.width(label, UiTheme.SIZE_BIG) * 0.5), r.position.y + 30.0), label, UiTheme.SIZE_BIG, col)
	var count := "loadout %d / %d" % [draft.picks.size(), Draft.SLOTS]
	UiTheme.text(_ui, Vector2(roundf(r.get_center().x - UiTheme.width(count, UiTheme.SIZE_SMALL) * 0.5), r.position.y + 46.0), count, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
