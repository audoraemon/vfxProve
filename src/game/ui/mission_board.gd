class_name MissionBoard
extends Node
## The tier board (v0.11 M1, spec §3.1), between the Title and Prepare, in place of v0.08's board of three cards. Since god P1
## (spec §3, ruling C3) it is a test mode: every tier, mission and power is open, and nothing is banked but bests.
## - Five tabs, one per Awakening Tier, and the open tab's missions as cards: name, type, two-line brief, best result, and a
##   tick once cleared.
## - No tier is locked, so there is no padlock and no unlock rule; the header says TEST_HEADER and there is no Upgrades button.
## - Input: the mouse, Left and Right choose a card; Tab or 1-5 a tier; a click or Enter picks the card; Esc goes back to the title.
## - With --dev (Game sets `dev`), a DEV tab beside the title holds the dev-only missions (MissionBook.dev_missions(): the
##   capital's sandbox, then each town's hostable missions as composite ids, `tax_collector@capital`: v0.12), always open;
##   D opens it. A town mission's card shows its name, the town (gold) and its type, no brief. Nothing of it shows without the flag.
## - With --dev, an ENDLESS button beside DEV (god P1, Ruling P14) emits "endless": Game opens Endless Night's slot select.

## "pick" (the player chose `chosen`) or "back" (Esc).
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
## The most lines a card's brief may wrap to (v0.11 M2): five cards a tab are 115 px wide, and seven lines end above the rule
## in the worst case, a best that wraps to three lines (a cleared card with a wide time and wishes; card 230 high: two name
## lines, the type, then 15 px a line, which leaves 5 px).
const BRIEF_LINES := 7
## Where the header's Upgrades button was (v0.11 M1). The test mode has none (god P1, spec §3): nothing is drawn or hit here.
const UPGRADES_RECT := Rect2(548.0, 8.0, 84.0, 20.0)
## The header's line in the test mode (god P1, spec §3, ruling C3), where the night and the believers were.
const TEST_HEADER := "TEST MODE: every tier, mission and power open"
## The hint under the cards.
const HINT := "Left and Right: missions   Tab or number keys: tiers   Enter: prepare   Esc: title"
## The DEV tab (--dev only): its tier number, past the five, and its button in the header beside the title.
const DEV_TIER := 6
const DEV_RECT := Rect2(112.0, 8.0, 40.0, 20.0)
## The ENDLESS button (god P1, Ruling P14; --dev only), beside DEV in the header: it opens Endless Night's slot select. A card would need
## a fake MissionDef, so it is a button. A click emits "endless".
const ENDLESS_RECT := Rect2(158.0, 8.0, 72.0, 20.0)

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
		for id in _missions_of(DEV_TIER):
			if not _defs.has(id):
				_defs[id] = Mission.def_for(id, true, _state())
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


## Tier `t`'s missions: TierBook's, or on the DEV tab (--dev) the dev-only ones, then (v0.12) each town's but Aldermere's hostable
## missions, `<mission>@<city>`, in tier order.
func _missions_of(t: int) -> PackedStringArray:
	if t == DEV_TIER:
		var out := PackedStringArray()
		if dev:
			for m in MissionBook.dev_missions():
				out.append(m.id)
			for city: StringName in City.ids():
				if city != &"aldermere":
					out.append_array(MissionBook.town_missions(city))
		return out
	return TierBook.missions(t)


## The tab a mission is on: its tier, DEV_TIER for a dev one (--dev), or 0.
func _tier_of(id: String) -> int:
	if dev and _missions_of(DEV_TIER).has(id):
		return DEV_TIER
	return TierBook.tier_of(id)


## Whether tab `t` is open (god P1, ruling C3): the five tiers always, the DEV tab with --dev.
func _is_open(t: int) -> bool:
	return dev if t == DEV_TIER else t >= 1 and t <= TierBook.NAMES.size()


## The open tier's rule while it is locked (v0.11 M1: "Clear 3 Omen missions"); always "" now that no tier is locked (god P1, C3).
func lock_line() -> String:
	return ""


## The header's line (god P1, spec §3): TEST_HEADER. It was the night to come and the believers (v0.11 M1); the test mode banks neither.
func header_text() -> String:
	return TEST_HEADER


## A card's best, part by part (spec §3.1, §3.5; v0.11 M2, Task 8): "Not yet cleared", or "Cleared" with its fastest clear and most
## wishes when it has them.
func best_parts(id: String) -> PackedStringArray:
	var s := _state()
	if not s.cleared.has(id):
		return PackedStringArray(["Not yet cleared"])
	var parts := PackedStringArray(["Cleared"])
	if s.fastest.has(id):
		parts.append("best %s" % UiTheme.clock(float(s.fastest[id])))
	if int(s.most_wishes.get(id, 0)) > 0:
		parts.append("wishes %d" % int(s.most_wishes[id]))
	return parts


## A card's best (spec §3.1, §3.5): its parts, two spaces apart.
func best_line(id: String) -> String:
	return "  ".join(best_parts(id))


## A card's brief wrapped to `room`, line by line (v0.11 M2: Whisper's five cards are 115 px wide).
func brief_lines(id: String, room: float) -> PackedStringArray:
	var out := PackedStringArray()
	var def: MissionDef = _defs.get(id)
	if def != null and MissionBook.split_city(id)[1] == &"":
		for brief in def.brief:
			out.append_array(UiTheme.wrap(brief, room, UiTheme.SIZE_BODY))
	return out


## A card's best wrapped to `room` (v0.11 M2: Whisper's five cards are 115 px wide), between its parts and never inside one, so
## "best 3:12" stays whole and the two spaces between parts survive on a line. A part wider than `room` wraps by its words.
func best_lines(id: String, room: float) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for part in best_parts(id):
		if UiTheme.width(part, UiTheme.SIZE_SMALL) > room:
			if line != "":
				lines.append(line)
				line = ""
			lines.append_array(UiTheme.wrap(part, room, UiTheme.SIZE_SMALL))
			continue
		var tried := part if line == "" else line + "  " + part
		if line != "" and UiTheme.width(tried, UiTheme.SIZE_SMALL) > room:
			lines.append(line)
			line = part
		else:
			line = tried
	if line != "":
		lines.append(line)
	return lines


## The most lines any card of the open tab's best takes (v0.11 M2, Task 8). Every card's rule is lifted by this many, so the rules
## of a row sit level, a short best on one card and a long one beside it.
func best_rows() -> int:
	var ids := missions()
	var room := card_rect(0, ids.size()).size.x - PAD * 2.0
	var rows := 1
	for id in ids:
		rows = maxi(rows, best_lines(id, room).size())
	return rows


## The y of the rule above a card's best, when `rows` lines of it sit under it (v0.11 M2, Task 8).
static func rule_y(r: Rect2, rows: int) -> float:
	return r.end.y - PAD - UiTheme.LINE_SMALL * float(rows) - 6.0


## The lines under a card's name, each drawn small and upper-case (v0.12, D21): a town mission's town, then its type; any other card's
## type, or "Dev sandbox" on the DEV tab.
func kind_lines(id: String) -> PackedStringArray:
	var parts := MissionBook.split_city(id)
	if parts[1] != &"":
		return PackedStringArray([String(parts[1]).to_upper(), TierBook.type_of(parts[0]).to_upper()])
	return PackedStringArray([("Dev sandbox" if tier == DEV_TIER else TierBook.type_of(id)).to_upper()])


## The y of the first line of a card's brief (v0.11 M2, Task 8): under its name, however many lines that wraps to, and its type.
func brief_top(id: String, r: Rect2) -> float:
	var def: MissionDef = _defs.get(id)
	var names := UiTheme.wrap(def.name, r.size.x - PAD * 2.0 - 12.0, UiTheme.SIZE_BIG).size()
	return r.position.y + PAD + 14.0 + (UiTheme.LINE_BODY + 3.0) * float(names) + UiTheme.LINE_SMALL * float(kind_lines(id).size()) + 8.0


## Where a card's brief ends (v0.11 M2, Task 8): its last line's baseline and a few pixels of descender.
func brief_bottom(id: String, r: Rect2) -> float:
	var room := r.size.x - PAD * 2.0
	return brief_top(id, r) + UiTheme.LINE_BODY * float(maxi(brief_lines(id, room).size() - 1, 0)) + 3.0


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


## What is under a point: "endless" (--dev only), "tab:<tier>", "card:<i>" (the open tier's), or "".
func hit(point: Vector2) -> String:
	if dev and ENDLESS_RECT.has_point(point):
		return "endless"
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
		click(event.position)


## A left click at a screen point: ENDLESS (--dev) opens Endless Night, a tab opens, a card is picked.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "endless":
		UiSound.play(&"ui_click")
		action.emit("endless")
	elif h.begins_with("tab:"):
		open_tab(int(h.substr(4)))
	elif h.begins_with("card:"):
		selected = int(h.substr(5))
		_pick()


func _draw_ui() -> void:
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	UiTheme.text(_ui, Vector2(8, 24), "THE TIERS", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	var head := header_text()
	UiTheme.text(_ui, Vector2(632.0 - UiTheme.width(head, UiTheme.SIZE_SMALL), 22.0), head, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	for i in TierBook.NAMES.size():
		_draw_tab(i)
	if dev:
		_draw_dev_tab()
		_draw_endless_button()
	if _is_open(tier):
		var ids := missions()
		var rows := best_rows()
		for i in ids.size():
			_draw_card(card_rect(i, ids.size()), ids[i], i == selected, rows)
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(HINT, UiTheme.SIZE_SMALL) * 0.5), 322.0), HINT,
		UiTheme.SIZE_SMALL, UiTheme.COL_DIM)


## The DEV tab's button (--dev): gold-framed while open.
func _draw_dev_tab() -> void:
	var open := tier == DEV_TIER
	_ui.draw_rect(DEV_RECT, Color(0.12, 0.1, 0.05, 0.95) if open else (Color(0.1, 0.09, 0.07, 0.9)
		if _hover == "tab:%d" % DEV_TIER else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, DEV_RECT, open)
	UiTheme.text(_ui, Vector2(roundf(DEV_RECT.get_center().x - UiTheme.width("DEV", UiTheme.SIZE_SMALL) * 0.5),
		DEV_RECT.end.y - 6.0), "DEV", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if open else UiTheme.COL_TEXT)


## The ENDLESS button (--dev, god P1): lit while the mouse is over it.
func _draw_endless_button() -> void:
	var lit := _hover == "endless"
	_ui.draw_rect(ENDLESS_RECT, Color(0.12, 0.1, 0.05, 0.95) if lit else UiTheme.COL_PANEL)
	UiTheme.frame(_ui, ENDLESS_RECT, lit)
	UiTheme.text(_ui, Vector2(roundf(ENDLESS_RECT.get_center().x - UiTheme.width("ENDLESS", UiTheme.SIZE_SMALL) * 0.5),
		ENDLESS_RECT.end.y - 6.0), "ENDLESS", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD if lit else UiTheme.COL_TEXT)


## Tab `i`: "WHISPER", gold-framed while open. No tier is locked, so none is dim or carries a padlock (god P1, C3).
func _draw_tab(i: int) -> void:
	var r := tab_rect(i)
	var open := i + 1 == tier
	_ui.draw_rect(r, Color(0.12, 0.1, 0.05, 0.95) if open else (Color(0.1, 0.09, 0.07, 0.9) if _hover == "tab:%d" % (i + 1)
		else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, r, open)
	# No digit in the label: the pixel font's 5 reads as an S ("S ASCENDANCE"); the keys 1-5 are in the hint.
	var label := TierBook.tier_name(i + 1).to_upper()
	UiTheme.text(_ui, Vector2(r.position.x + 5.0, r.end.y - 5.0), label, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD if open else UiTheme.COL_TEXT)


## One card, top to bottom: its name and a tick once cleared, its type, its brief, then under a rule its best. `rows` is the most
## lines any card of the row has for its best (v0.11 M2, Task 8), so the rules sit level.
func _draw_card(r: Rect2, id: String, on: bool, rows: int) -> void:
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
	var town: bool = MissionBook.split_city(id)[1] != &""
	var kinds := kind_lines(id)
	for i in kinds.size():
		# A town mission's town is gold on every card (v0.12); the type follows the card's own colour.
		UiTheme.text(_ui, Vector2(x, y + UiTheme.LINE_SMALL * float(i)), kinds[i], UiTheme.SIZE_SMALL,
			UiTheme.COL_GOLD if on or (town and i == 0) else UiTheme.COL_DIM)
	y = brief_top(id, r)
	for line in brief_lines(id, room):
		UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BODY, text_col)
		y += UiTheme.LINE_BODY
	var best := best_lines(id, room)
	var rule := rule_y(r, maxi(rows, best.size()))
	_ui.draw_line(Vector2(x, rule), Vector2(r.end.x - PAD, rule), UiTheme.COL_GOLD_DARK, -1.0)
	for i in best.size():
		UiTheme.text(_ui, Vector2(x, rule + 4.0 + UiTheme.LINE_SMALL * float(i + 1)), best[i], UiTheme.SIZE_SMALL,
			UiTheme.COL_GOLD if on else UiTheme.COL_DIM)
