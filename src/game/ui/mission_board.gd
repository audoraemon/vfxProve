class_name MissionBoard
extends Node
## The tier board (v0.11 M1, spec §3.1), between the Title and Prepare, in place of v0.08's board of three cards.
## - Five tabs, one per Awakening Tier, and the open tab's missions as cards: name, type, two-line brief, best result, and a
##   tick once cleared.
## - A locked tier shows a padlock and its rule.
## - The header holds the night to come, the believers and an Upgrades button.
## - Input: the mouse, Left and Right choose a card; Tab or 1-5 a tier; a click or Enter picks the card (an open tier's
##   only); U opens the Upgrades; Esc goes back to the title.
## - With --dev (Game sets `dev`), a DEV tab beside the title holds the dev-only missions (MissionBook.dev_missions(): the
##   capital's sandbox), always open; D opens it. Nothing of it shows without the flag.

## "pick" (the player chose `chosen`), "upgrades" or "back" (Esc).
signal action(name: String)

## The tabs' row under the title: five tabs sharing the screen less its margins.
const TAB_TOP := 34.0
const TAB_H := 18.0
const TAB_GAP := 4.0
const BOARD_MARGIN := 8.0
## A card at most CARD wide, the gap between cards, the top of their row (centred on the screen), and a card's padding.
const CARD := Vector2(300.0, 230.0)
const CARD_GAP := 12.0
const CARD_TOP := 62.0
const PAD := 10.0
## The header's Upgrades button.
const UPGRADES_RECT := Rect2(548.0, 8.0, 84.0, 20.0)
## The DEV tab (--dev only): its tier number, past the five, and its button in the header beside the title.
const DEV_TIER := 6
const DEV_RECT := Rect2(112.0, 8.0, 40.0, 20.0)

## The mission picked, once "pick" is emitted.
var chosen := ""
## Whether the DEV tab shows (--dev, set before setup()).
var dev := false
## The tier whose tab is open (1-5, or DEV_TIER), and the selected card on it.
var tier := 1
var selected := 0

var _save: SaveFile
var _ui: Control
var _hover := ""
## Each board mission's def, for its card's words (built once).
var _defs := {}


func setup(save: SaveFile, current: String) -> MissionBoard:
	_save = save
	for id in TierBook.all():
		_defs[id] = TierBook.board(id)
	if dev:
		for m in MissionBook.dev_missions():
			_defs[m.id] = m
	tier = 1
	selected = 0
	var at := _tier_of(current)
	if at > 0 and _is_open(at):
		tier = at
		selected = maxi(_missions_of(at).find(current), 0)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	return self


## The board's state: the save's, or a fresh one with no save.
func _state() -> DescendState:
	if _save == null:
		_save = SaveFile.new()
	return _save.descend


## Tab `i` (from 0): the five share the screen less its margins.
static func tab_rect(i: int) -> Rect2:
	var count := TierBook.NAMES.size()
	var w := floorf((640.0 - BOARD_MARGIN * 2.0 - TAB_GAP * float(count - 1)) / float(count))
	return Rect2(Vector2(BOARD_MARGIN + float(i) * (w + TAB_GAP), TAB_TOP), Vector2(w, TAB_H))


## Where card `i` of `count` sits: side by side, the row centred on 320; a card narrows when `count` of CARD's width would
## not fit (five missions a tier from M6).
static func card_rect(i: int, count: int) -> Rect2:
	var size := CARD
	size.x = minf(CARD.x, floorf((640.0 - BOARD_MARGIN * 2.0 - float(maxi(count - 1, 0)) * CARD_GAP) / float(maxi(count, 1))))
	var total := float(count) * size.x + float(maxi(count - 1, 0)) * CARD_GAP
	var left := roundf(320.0 - total * 0.5)
	return Rect2(Vector2(left + float(i) * (size.x + CARD_GAP), CARD_TOP), size)


## The DEV tab's button (--dev only).
static func dev_rect() -> Rect2:
	return DEV_RECT


## The open tab's missions, by id.
func missions() -> PackedStringArray:
	return _missions_of(tier)


## Tier `t`'s missions: TierBook's, or on the DEV tab (--dev) the dev-only ones.
func _missions_of(t: int) -> PackedStringArray:
	if t == DEV_TIER:
		var out := PackedStringArray()
		if dev:
			for m in MissionBook.dev_missions():
				out.append(m.id)
		return out
	return TierBook.missions(t)


## The tab a mission is on: its tier, DEV_TIER for a dev one (--dev), or 0.
func _tier_of(id: String) -> int:
	if dev and _missions_of(DEV_TIER).has(id):
		return DEV_TIER
	return TierBook.tier_of(id)


## Whether tab `t` is open: its tier's rule, the DEV tab always (--dev).
func _is_open(t: int) -> bool:
	return dev if t == DEV_TIER else _state().is_open(t)


## The open tier's rule while it is locked (spec §3.1: "Clear 3 Omen missions"); "" while open.
func lock_line() -> String:
	return "" if _is_open(tier) else DescendState.lock_text(tier)


## The header's line (spec §3.1): the night about to be played, and the believers.
func header_text() -> String:
	return "Night %d   Believers %d" % [_state().night + 1, _state().believers]


## A card's best (spec §3.1, §3.5): "Not yet cleared", or "Cleared" with its fastest clear and most wishes when it has them.
func best_line(id: String) -> String:
	var s := _state()
	if not s.cleared.has(id):
		return "Not yet cleared"
	var parts := PackedStringArray(["Cleared"])
	if s.fastest.has(id):
		parts.append("best %s" % UiTheme.clock(float(s.fastest[id])))
	if int(s.most_wishes.get(id, 0)) > 0:
		parts.append("wishes %d" % int(s.most_wishes[id]))
	return "  ".join(parts)


## Opens tier `t`'s tab -- locked or not: a locked one shows its rule -- on its first card.
func open_tab(t: int) -> void:
	t = DEV_TIER if dev and t == DEV_TIER else clampi(t, 1, TierBook.NAMES.size())
	if t == tier:
		return
	tier = t
	selected = 0
	UiSound.play(&"ui_click")
	_redraw()


## Picks a mission by id, as a click on its card would (the FLOW test, --show): its tier's tab opens, and the mission is
## picked only when that tier is open.
func choose(id: String) -> void:
	var t := _tier_of(id)
	if t == 0:
		push_warning("KAK has no board mission called " + id)
		return
	tier = t
	selected = maxi(_missions_of(t).find(id), 0)
	if _is_open(t):
		_pick()
	else:
		_redraw()


## What is under a point: "upgrades", "tab:<tier>", "card:<i>" (the open tier's), or "".
func hit(point: Vector2) -> String:
	if UPGRADES_RECT.has_point(point):
		return "upgrades"
	if dev and DEV_RECT.has_point(point):
		return "tab:%d" % DEV_TIER
	for i in TierBook.NAMES.size():
		if tab_rect(i).has_point(point):
			return "tab:%d" % (i + 1)
	var ids := missions()
	for i in ids.size():
		if card_rect(i, ids.size()).has_point(point):
			return "card:%d" % i
	return ""


func _pick() -> void:
	if not _is_open(tier) or missions().is_empty():
		return
	chosen = missions()[selected]
	UiSound.play(&"ui_manifest")
	_redraw()
	action.emit("pick")


func _select(i: int) -> void:
	var ids := missions()
	if ids.is_empty():
		return
	i = posmod(i, ids.size())
	if i != selected:
		selected = i
		UiSound.play(&"ui_hover")
		_redraw()


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode
		if key == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("back")
		elif key == KEY_D and dev:
			open_tab(DEV_TIER)
		elif key == KEY_U:
			UiSound.play(&"ui_click")
			action.emit("upgrades")
		elif key == KEY_LEFT:
			_select(selected - 1)
		elif key == KEY_RIGHT:
			_select(selected + 1)
		elif key == KEY_TAB:
			open_tab(posmod(tier - 1 + (-1 if event.shift_pressed else 1), TierBook.NAMES.size()) + 1)
		elif key >= KEY_1 and key <= KEY_5:
			open_tab(key - KEY_1 + 1)
		elif key in [KEY_ENTER, KEY_KP_ENTER]:
			_pick()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h.begins_with("card:"):
				_select(int(h.substr(5)))
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h := hit(event.position)
		if h == "upgrades":
			UiSound.play(&"ui_click")
			action.emit("upgrades")
		elif h.begins_with("tab:"):
			open_tab(int(h.substr(4)))
		elif h.begins_with("card:"):
			selected = int(h.substr(5))
			_pick()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "THE TIERS", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var head := header_text()
	UiTheme.text(_ui, Vector2(UPGRADES_RECT.position.x - 10.0 - UiTheme.width(head, UiTheme.SIZE_SMALL), 22.0), head,
		UiTheme.SIZE_SMALL)
	_ui.draw_rect(UPGRADES_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, UPGRADES_RECT, _hover == "upgrades")
	UiTheme.text(_ui, Vector2(roundf(UPGRADES_RECT.get_center().x - UiTheme.width("Upgrades") * 0.5), UPGRADES_RECT.position.y + 14.0),
		"Upgrades", UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "upgrades" else UiTheme.COL_TEXT)
	for i in TierBook.NAMES.size():
		_draw_tab(i)
	if dev:
		_draw_dev_tab()
	if _is_open(tier):
		var ids := missions()
		for i in ids.size():
			_draw_card(card_rect(i, ids.size()), ids[i], i == selected)
	else:
		_draw_locked()
	var hint := "Left and Right: missions   Tab or number keys: tiers   Enter: prepare   U: upgrades   Esc: title"
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), 322.0), hint,
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## The DEV tab's button (--dev): gold-framed while open.
func _draw_dev_tab() -> void:
	var open := tier == DEV_TIER
	_ui.draw_rect(DEV_RECT, Color(0.12, 0.1, 0.05, 0.95) if open else (Color(0.1, 0.09, 0.07, 0.9)
		if _hover == "tab:%d" % DEV_TIER else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, DEV_RECT, open)
	UiTheme.text(_ui, Vector2(roundf(DEV_RECT.get_center().x - UiTheme.width("DEV", UiTheme.SIZE_SMALL) * 0.5),
		DEV_RECT.end.y - 6.0), "DEV", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if open else UiTheme.COL_TEXT)


## Tab `i`: "WHISPER", gold-framed while open; a locked tier's dim, with a padlock.
func _draw_tab(i: int) -> void:
	var r := tab_rect(i)
	var open := i + 1 == tier
	var unlocked := _state().is_open(i + 1)
	_ui.draw_rect(r, Color(0.12, 0.1, 0.05, 0.95) if open else (Color(0.1, 0.09, 0.07, 0.9) if _hover == "tab:%d" % (i + 1)
		else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, r, open)
	# No digit in the label: the pixel font's 5 reads as an S ("S ASCENDANCE"); the keys 1-5 are in the hint.
	var label := TierBook.tier_name(i + 1).to_upper()
	UiTheme.text(_ui, Vector2(r.position.x + 5.0, r.end.y - 5.0), label, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if open and unlocked else (UiTheme.COL_TEXT if unlocked else UiTheme.COL_DIM))
	if not unlocked:
		_padlock(Vector2(r.end.x - 12.0, r.position.y + 6.0), 1.0, UiTheme.COL_DIM)


## A padlock drawn in lines, its body's top-left at `at`, `k` times its small size.
func _padlock(at: Vector2, k: float, col: Color) -> void:
	_ui.draw_arc(at + Vector2(3.5, 0.0) * k, 2.5 * k, PI, TAU, 8, col, maxf(k, 1.0))
	_ui.draw_rect(Rect2(at, Vector2(7.0, 6.0) * k), col)


## A locked tier's body (spec §3.1): a large padlock and the rule that opens it.
func _draw_locked() -> void:
	_padlock(Vector2(306.0, 140.0), 4.0, UiTheme.COL_GOLD_DARK)
	var rule := lock_line()
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(rule, UiTheme.SIZE_BIG) * 0.5), 196.0), rule, UiTheme.SIZE_BIG,
		UiTheme.COL_GOLD)


## One card, top to bottom: its name and a tick once cleared, its type, its brief, then under a rule its best.
func _draw_card(r: Rect2, id: String, on: bool) -> void:
	var def: MissionDef = _defs.get(id)
	_ui.draw_rect(r, Color(0.1, 0.09, 0.07, 0.9) if on else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, r, on)
	var x := r.position.x + PAD
	var room := r.size.x - PAD * 2.0
	var text_col := UiTheme.COL_TEXT if on else UiTheme.COL_DIM
	var y := r.position.y + PAD + 14.0
	for line in UiTheme.wrap(def.name, room - 12.0, UiTheme.SIZE_BIG):
		UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BIG, UiTheme.COL_GOLD if on else UiTheme.COL_GOLD_DARK)
		y += UiTheme.LINE_BODY + 3.0
	if _state().cleared.has(id):
		UiTheme.mark(_ui, Vector2(r.end.x - PAD - 7.0, r.position.y + PAD + 2.0), true)
	var kind := "Dev sandbox" if tier == DEV_TIER else TierBook.type_of(id)
	UiTheme.text(_ui, Vector2(x, y), kind.to_upper(), UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
	y += UiTheme.LINE_SMALL + 8.0
	for brief in def.brief:
		for line in UiTheme.wrap(brief, room, UiTheme.SIZE_BODY):
			UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BODY, text_col)
			y += UiTheme.LINE_BODY
	var rule := r.end.y - PAD - UiTheme.LINE_SMALL - 6.0
	_ui.draw_line(Vector2(x, rule), Vector2(r.end.x - PAD, rule), UiTheme.COL_GOLD_DARK, -1.0)
	UiTheme.text(_ui, Vector2(x, rule + 4.0 + UiTheme.LINE_SMALL), best_line(id), UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
