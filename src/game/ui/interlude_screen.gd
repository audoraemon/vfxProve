class_name InterludeScreen
extends Node
## The interlude between the acts of a night (v0.09), over the frozen town: the act just played -- its goal and each
## bonus ticked or crossed, and the time it took -- then what comes next. After Act I that is the choice card, one card
## per path with its brief, its timed events and how the town will meet the player; after Act II it is a single line
## naming the last act. "Choose powers" goes on to the re-draft, "Missions" leaves the night for the board.

## "draft" (on to Prepare with `chosen`) or "missions" (Esc, or the button).
signal action(name: String)

const PANEL := Rect2(16.0, 10.0, 608.0, 340.0)
## One choice card, the gap between the two, and the top of the row; the row is centred on the screen.
const CARD := Vector2(284.0, 220.0)
const CARD_GAP := 12.0
const CARD_TOP := 78.0
## The padding inside a card.
const PAD := 10.0
## The baselines of the act's name, its result row, the single next act's line and the hint over the buttons.
const NAME_Y := 40.0
const RESULT_Y := 62.0
const NEXT_Y := 170.0
const HINT_Y := 312.0

## The act the player chose to play next ("" until then); with only one act to follow, that one from setup().
var chosen := ""
## The acts that may follow, and the card the keyboard is on.
var choices: Array = []
var selected := 0

var _result := {}
## The name of the act just played, looked up once.
var _called := ""
var _night: NightState
var _ui: Control
var _menu: Menu
var _hover := ""


## Where card `i` of `count` sits: side by side inside the panel, the row centred on 320.
static func card_rect(i: int, count: int) -> Rect2:
	var size := CARD
	size.x = minf(CARD.x, floorf((PANEL.size.x - PAD * 2.0 - float(maxi(count - 1, 0)) * CARD_GAP) / float(maxi(count, 1))))
	var total := float(count) * size.x + float(maxi(count - 1, 0)) * CARD_GAP
	var left := roundf(320.0 - total * 0.5)
	return Rect2(Vector2(left + float(i) * (size.x + CARD_GAP), CARD_TOP), size)


## The name of the act a result is for: an act of any mission in the book, else the mission's own name.
static func act_name(id: String) -> String:
	for m in MissionBook.all():
		var a := m.act(id)
		if a != null:
			return a.name
	return MissionBook.get_mission(id).name


func setup(result: Dictionary, next: Array, night: NightState) -> InterludeScreen:
	_result = result
	_called = act_name(String(result.get("mission", "")))
	choices = next
	_night = night if night != null else NightState.new()
	if choices.size() == 1:
		chosen = (choices[0] as ActDef).id
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.row(["draft", "missions"], ["Choose powers", "Missions"], 320.0, PANEL.end.y - 28.0, 120.0)
	return self


## Choose the act to play next by id, as a click on its card would: for the FLOW test, and the way back from Prepare.
func choose(id: String) -> void:
	for i in choices.size():
		if (choices[i] as ActDef).id == id:
			selected = i
			chosen = id
			if _ui != null:
				_ui.queue_redraw()
			return
	push_warning("KAK has no act called %s to follow this one" % id)


## Where a button sits: "draft" or "missions".
func button_rect(what: String) -> Rect2:
	return _menu.rect_of(what)


## The card under a point, or -1. With one act to follow there are no cards.
func hit(point: Vector2) -> int:
	if choices.size() < 2:
		return -1
	for i in choices.size():
		if card_rect(i, choices.size()).has_point(point):
			return i
	return -1


## A left click at a screen point: a card is chosen, a button pressed.
func click(point: Vector2) -> void:
	var i := hit(point)
	if i >= 0:
		_choose_card(i)
		return
	var a := _menu.at(point)
	if a != "":
		_press(a)


## "Choose powers" goes once an act is chosen, and buzzes before; "Missions" always goes.
func _press(what: String) -> void:
	if what == "draft" and chosen == "":
		UiSound.play(&"ui_buzz")
		return
	UiSound.play(&"ui_click")
	action.emit(what)


func _choose_card(i: int) -> void:
	UiSound.play(&"ui_manifest")
	choose((choices[i] as ActDef).id)


func _select(i: int) -> void:
	if choices.size() < 2:
		return
	i = posmod(i, choices.size())
	if i != selected:
		selected = i
		UiSound.play(&"ui_hover")
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("missions")
		elif event.physical_keycode == KEY_LEFT:
			_select(selected - 1)
		elif event.physical_keycode == KEY_RIGHT:
			_select(selected + 1)
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			# Enter chooses the card the keyboard is on; once that card is chosen, Enter goes on to the draft.
			if choices.size() >= 2 and chosen != (choices[selected] as ActDef).id:
				_choose_card(selected)
			else:
				_press("draft")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var card := hit(event.position)
		if card >= 0:
			_select(card)
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	var won := bool(_result.get("won", false))
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.5))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.9))
	UiTheme.frame(_ui, PANEL, true)
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(_called, UiTheme.SIZE_BIG) * 0.5), NAME_Y), _called,
		UiTheme.SIZE_BIG, UiTheme.COL_GOLD if won else UiTheme.COL_BAD)
	_draw_result_row()

	if choices.size() >= 2:
		for i in choices.size():
			_draw_card(card_rect(i, choices.size()), choices[i] as ActDef, i)
		var hint := "Left and Right, then Enter, to choose the next act" if chosen == "" \
			else "Enter or Choose powers to draft for it, Esc for the missions"
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(hint, UiTheme.SIZE_SMALL) * 0.5), HINT_Y), hint,
			UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	elif choices.size() == 1:
		var next := choices[0] as ActDef
		var line := "Next: " + next.name
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(line, UiTheme.SIZE_BIG) * 0.5), NEXT_Y), line,
			UiTheme.SIZE_BIG)
		var y := NEXT_Y + 22.0
		for l in UiTheme.wrap(next.card_line(_night), PANEL.size.x - 80.0, UiTheme.SIZE_BODY):
			UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(l, UiTheme.SIZE_BODY) * 0.5), y), l, UiTheme.SIZE_BODY,
				UiTheme.COL_GOLD)
			y += UiTheme.LINE_BODY
	_menu.draw_on(_ui, _hover, PackedStringArray(["draft"]) if chosen == "" else PackedStringArray())


## The act's result on one centred row: its goal and each bonus with a tick or a cross, then "Time m:ss".
func _draw_result_row() -> void:
	var goal: Dictionary = _result.get("goal", {})
	var entries := [[String(goal.get("label", "")), bool(goal.get("done", false))]]
	for b: Dictionary in _result.get("bonuses", []):
		entries.append([String(b.get("label", "")), bool(b.get("earned", false))])
	var time := "Time " + UiTheme.clock(float(_result.get("time", 0.0)))
	var gap := 18.0
	var total := UiTheme.width(time, UiTheme.SIZE_BODY)
	for e: Array in entries:
		total += 7.0 + 5.0 + UiTheme.width(String(e[0]), UiTheme.SIZE_BODY) + gap
	var x := roundf(320.0 - total * 0.5)
	for e: Array in entries:
		UiTheme.mark(_ui, Vector2(x, RESULT_Y - 8.0), bool(e[1]))
		x += 7.0 + 5.0
		UiTheme.text(_ui, Vector2(x, RESULT_Y), String(e[0]), UiTheme.SIZE_BODY)
		x += UiTheme.width(String(e[0]), UiTheme.SIZE_BODY) + gap
	UiTheme.text(_ui, Vector2(x, RESULT_Y), time, UiTheme.SIZE_BODY, UiTheme.COL_DIM)


## One choice card, top to bottom: the act's name, its brief, its timed events, then how the town will meet the player,
## in gold. The chosen card wears the bright frame; the one the keyboard is on is lit.
func _draw_card(r: Rect2, act: ActDef, i: int) -> void:
	var on := act.id == chosen
	_ui.draw_rect(r, Color(0.12, 0.1, 0.05, 0.95) if on else (Color(0.1, 0.09, 0.07, 0.9) if i == selected
		else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, r, on)
	var x := r.position.x + PAD
	var room := r.size.x - PAD * 2.0
	var text_col := UiTheme.COL_TEXT if on or i == selected else UiTheme.COL_DIM
	var y := r.position.y + PAD + 14.0
	for line in UiTheme.wrap(act.name, room, UiTheme.SIZE_BIG):
		UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BIG, UiTheme.COL_GOLD if on else UiTheme.COL_GOLD_DARK)
		y += UiTheme.LINE_BODY + 3.0
	y += 8.0
	for k in mini(act.brief.size(), 2):
		for line in UiTheme.wrap(act.brief[k], room, UiTheme.SIZE_BODY):
			UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_BODY, text_col)
			y += UiTheme.LINE_BODY
	if not act.events_text.is_empty():
		y += 6.0
		for event in act.events_text:
			for line in UiTheme.wrap(event, room, UiTheme.SIZE_SMALL):
				UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
				y += UiTheme.LINE_SMALL
	# How the town will meet the player, at the foot of the card.
	var meet := UiTheme.wrap(act.card_line(_night), room, UiTheme.SIZE_BODY)
	var foot := r.end.y - PAD - UiTheme.LINE_BODY * float(maxi(meet.size() - 1, 0))
	for line in meet:
		UiTheme.text(_ui, Vector2(x, foot), line, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
		foot += UiTheme.LINE_BODY
