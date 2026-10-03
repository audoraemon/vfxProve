class_name MissionBoard
extends Node
## The mission board (v0.08), between the Title and Prepare: one card per mission, lowest Tier first -- its name and
## Tier, its brief, its goal, its loadout and the best result the save holds for it. The selected card wears the
## bright gold frame; the mouse or Left and Right move it, a click or Enter picks it, Esc goes back to the title.

## "pick" (the player chose `chosen`) or "back" (Esc).
signal action(name: String)

## One card, the gap between cards, and the top of the row; the row is centred on the screen.
const CARD := Vector2(300.0, 250.0)
const CARD_GAP := 12.0
const CARD_TOP := 48.0
## The padding inside a card.
const PAD := 10.0
## The Tier badge's plate, top-right on a card: tall enough for its digit.
const BADGE_H := 18.0
## The badge's digit is drawn from these 5 x 7 bitmaps, DIGIT_PX screen pixels a cell: the pixel font's 5 is round at
## the top-left like an S, and "TIER 5" read "TIER S" at every size it has.
const DIGITS := [
	[".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	[".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	["#####", "#....", "#....", "####.", "....#", "....#", "####."],
	[".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
	["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	[".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	[".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
]
const DIGIT_PX := 2.0

## The mission picked, once "pick" is emitted.
var chosen := ""
## The missions, lowest Tier first, and the selected one's index.
var missions: Array[MissionDef] = []
var selected := 0

var _save: SaveFile
var _ui: Control


func setup(save: SaveFile, current: String) -> MissionBoard:
	_save = save
	missions = MissionBook.all()
	missions.sort_custom(func(a: MissionDef, b: MissionDef) -> bool: return a.tier < b.tier)
	selected = 0
	for i in missions.size():
		if missions[i].id == current:
			selected = i
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## Where card `i` of `count` sits: side by side, the row centred on 320.
static func card_rect(i: int, count: int) -> Rect2:
	var total := float(count) * CARD.x + float(maxi(count - 1, 0)) * CARD_GAP
	var left := roundf(320.0 - total * 0.5)
	return Rect2(Vector2(left + float(i) * (CARD.x + CARD_GAP), CARD_TOP), CARD)


## The card under a point, or -1.
func hit(point: Vector2) -> int:
	for i in missions.size():
		if card_rect(i, missions.size()).has_point(point):
			return i
	return -1


## Pick a mission by id, as a click on its card would: for the FLOW test and --show=board.
func choose(id: String) -> void:
	for i in missions.size():
		if missions[i].id == id:
			selected = i
			_pick()
			return
	push_warning("KAK has no mission called " + id)


## The best result line on a card: a scored mission's best score and rank, else whether it was won (and its bonus).
func best_line(def: MissionDef) -> String:
	var best := _save.best(def.id) if _save != null else {}
	if def.scored:
		var score := int(best.get("best_score", 0))
		return "Best %s  %s" % [ResultsScreen.thousands(score), String(best.get("best_rank", ""))] if score > 0 \
			else "Not yet played"
	if not bool(best.get("won", false)):
		return "Not yet won"
	var bonuses := def.bonuses()
	if bool(best.get("bonus", false)) and not bonuses.is_empty():
		return "Won, " + bonuses[0].label
	return "Won"


## An unscored mission's best as marks (v0.08): [["Won", won], [each bonus's label, earned]], drawn with a tick or a
## cross each.
func best_marks(def: MissionDef) -> Array:
	var best := _save.best(def.id) if _save != null else {}
	var out := [["Won", bool(best.get("won", false))]]
	for b in def.bonuses():
		out.append([b.label, bool(best.get("bonus", false))])
	return out


func _pick() -> void:
	chosen = missions[selected].id
	UiSound.play(&"ui_manifest")
	if _ui != null:
		_ui.queue_redraw()
	action.emit("pick")


func _select(i: int) -> void:
	if missions.is_empty():
		return
	i = posmod(i, missions.size())
	if i != selected:
		selected = i
		UiSound.play(&"ui_hover")
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("back")
		elif event.physical_keycode == KEY_LEFT:
			_select(selected - 1)
		elif event.physical_keycode == KEY_RIGHT:
			_select(selected + 1)
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and not missions.is_empty():
			_pick()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h >= 0:
			_select(h)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h := hit(event.position)
		if h >= 0:
			selected = h
			_pick()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "CHOOSE A MANIFESTATION", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	for i in missions.size():
		_draw_card(card_rect(i, missions.size()), missions[i], i == selected)
	var hint := "Left and Right to choose, Enter to prepare, Esc for the title"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), 322.0), hint,
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## A digit from DIGITS, its top-left at `at`, with the one-pixel shadow every label wears.
func _digit(at: Vector2, n: int, col: Color) -> void:
	var rows: Array = DIGITS[clampi(n, 0, 9)]
	for layer: Array in [[Vector2.ONE, UiTheme.COL_SHADOW], [Vector2.ZERO, col]]:
		for y in rows.size():
			var row := String(rows[y])
			for x in row.length():
				if row[x] == "#":
					_ui.draw_rect(Rect2(at + layer[0] + Vector2(float(x), float(y)) * DIGIT_PX, Vector2.ONE * DIGIT_PX),
						layer[1])


## One card, top to bottom: the name and its Tier badge, the brief, the goal, the loadout, the best result.
func _draw_card(r: Rect2, def: MissionDef, on: bool) -> void:
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if on else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, on)
	var x := r.position.x + PAD
	var room := r.size.x - PAD * 2.0
	var text_col := UiTheme.COL_TEXT if on else UiTheme.COL_DIM

	# "TIER" in the font, its digit from DIGITS beside it.
	var word_w := UiTheme.width("TIER", UiTheme.SIZE_SMALL)
	var digit_w := 5.0 * DIGIT_PX
	var plate := Rect2(Vector2(r.end.x - PAD - word_w - digit_w - 15.0, r.position.y + PAD),
		Vector2(word_w + digit_w + 15.0, BADGE_H))
	_ui.draw_rect(plate, Color(0.04, 0.04, 0.06, 0.92))
	UiTheme.frame(_ui, plate, on)
	var badge_col := UiTheme.COL_GOLD if on else UiTheme.COL_DIM
	UiTheme.text(_ui, plate.position + Vector2(5.0, 13.0), "TIER", UiTheme.SIZE_SMALL, badge_col)
	_digit(plate.position + Vector2(10.0 + word_w, 2.0), def.tier, badge_col)

	var y := r.position.y + PAD + 14.0
	for line in UiTheme.wrap(def.name, plate.position.x - x - 6.0, UiTheme.SIZE_BIG):
		UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BIG, UiTheme.COL_GOLD if on else UiTheme.COL_GOLD_DARK)
		y += UiTheme.LINE_BODY + 3.0
	y += 8.0
	for brief in def.brief:
		for line in UiTheme.wrap(brief, room, UiTheme.SIZE_BODY):
			UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BODY, text_col)
			y += UiTheme.LINE_BODY
	y += 10.0
	UiTheme.text(_ui, Vector2(x, y), "GOAL", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
	y += UiTheme.LINE_SMALL + 2.0
	for line in UiTheme.wrap(def.goal, room, UiTheme.SIZE_BODY):
		UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BODY, text_col)
		y += UiTheme.LINE_BODY

	# The foot of the card: the loadout, then the best result.
	var loadout := "%d slots" % def.slots if def.dp_capacity == 0 else "%d slots · %d DP" % [def.slots, def.dp_capacity]
	var foot := r.end.y - PAD - 2.0
	_ui.draw_line(Vector2(x, foot - UiTheme.LINE_SMALL * 2.0 - 4.0), Vector2(r.end.x - PAD, foot - UiTheme.LINE_SMALL * 2.0 - 4.0),
		UiTheme.COL_GOLD_DARK, -1.0)
	UiTheme.text(_ui, Vector2(x, foot - UiTheme.LINE_SMALL), loadout, UiTheme.SIZE_SMALL, text_col)
	if def.scored:
		UiTheme.text(_ui, Vector2(x, foot), best_line(def), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
		return
	# An unscored mission (v0.08): "Won" and each bonus, each with a tick or a cross.
	for entry: Array in best_marks(def):
		var label := String(entry[0])
		UiTheme.text(_ui, Vector2(x, foot), label, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
		x += UiTheme.width(label, UiTheme.SIZE_SMALL) + 5.0
		UiTheme.mark(_ui, Vector2(x, foot - 7.0), bool(entry[1]))
		x += 7.0 + 14.0
