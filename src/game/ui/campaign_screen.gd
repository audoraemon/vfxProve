class_name CampaignScreen
extends Node
## The Lantern campaign between nights (v0.10, spec §4-§5): where the campaign stands -- the night and its Tier, the
## god's Divine Power and slots, Halcyon's bites, the title its path has given it -- Cael's memory fragment for tonight,
## and tonight's mission: one line, or a choice card per mission. "Choose powers" goes on to Prepare with `chosen`;
## "New campaign" asks twice before it starts over; "Title", or Esc, leaves.

## "draft" (on to Prepare with `chosen`), "restart" (on the second press) or "title".
signal action(name: String)

const PANEL := Rect2(16.0, 10.0, 608.0, 340.0)
## The baselines of the night's name and the status line; the fragment's title, and the width its text wraps to.
const HEAD_Y := 36.0
const STATUS_Y := 54.0
const FRAGMENT_Y := 80.0
const FRAGMENT_W := 560.0
## The cards: their row's top, their height, the widest a card gets, the gap between two and the padding inside one.
const CARD_TOP := 168.0
const CARD_H := 128.0
const CARD_MAX_W := 284.0
const CARD_GAP := 10.0
const PAD := 8.0
## The single mission's line, the hint over the buttons, and the buttons' row.
const ONE_Y := 210.0
const HINT_Y := 310.0
const BUTTONS_Y := 318.0

## The mission chosen for tonight ("" until a card is chosen); with one mission, that one from setup().
var chosen := ""
## Tonight's missions, ready for Prepare (CampaignState.mission()), and the card the keyboard is on.
var options: Array = []
var selected := 0
## True once "New campaign" has been pressed once: the next press starts over, any other press forgets it.
var confirming := false

var _state: CampaignState
var _ui: Control
var _menu: Menu
var _hover := ""


## Where card `i` of `count` sits: side by side inside the panel, the row centred on 320.
static func card_rect(i: int, count: int) -> Rect2:
	var n := maxi(count, 1)
	var w := minf(CARD_MAX_W, floorf((PANEL.size.x - PAD * 2.0 - float(n - 1) * CARD_GAP) / float(n)))
	var total := float(n) * w + float(n - 1) * CARD_GAP
	var left := roundf(320.0 - total * 0.5)
	return Rect2(Vector2(left + float(i) * (w + CARD_GAP), CARD_TOP), Vector2(w, CARD_H))


## "8 DP   3 slots   Bites 1 / 3   The Deceiver".
static func status_text(s: CampaignState) -> String:
	return "%d DP   %d slots   Bites %d / %d   %s" % [s.dp, s.slots(), s.bites, CampaignDef.MAX_BITES, s.title()]


## Cael's line on a card: his own for a Night 2 mission, else the night's first act's line on how the town will meet the
## player (the Feast, from The Long Night).
static func card_line(def: MissionDef, s: CampaignState) -> String:
	if CampaignText.CARD_LINES.has(def.id):
		return String(CampaignText.CARD_LINES[def.id])
	if def.has_acts():
		var n := NightState.new()
		n.bell_rang = s.bell_rang
		return def.first_act().card_line(n)
	return ""


func setup(state: CampaignState) -> CampaignScreen:
	_state = state
	options = []
	for o: Dictionary in state.options():
		options.append(state.mission(String(o.mission)))
	if options.size() == 1:
		chosen = (options[0] as MissionDef).id
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	_menu = Menu.row(["draft", "restart", "title"], ["Choose powers", "New campaign", "Title"], 320.0, BUTTONS_Y, 128.0)
	return self


## Choose tonight's mission by id, as a click on its card would (the FLOW test).
func choose(id: String) -> void:
	for i in options.size():
		if (options[i] as MissionDef).id == id:
			selected = i
			chosen = id
			if _ui != null:
				_ui.queue_redraw()
			return
	push_warning("KAK has no mission called %s tonight" % id)


func button_rect(what: String) -> Rect2:
	return _menu.rect_of(what)


## The card under a point, or -1. With one mission there are no cards.
func hit(point: Vector2) -> int:
	if options.size() < 2:
		return -1
	for i in options.size():
		if card_rect(i, options.size()).has_point(point):
			return i
	return -1


func click(point: Vector2) -> void:
	var i := hit(point)
	if i >= 0:
		confirming = false
		UiSound.play(&"ui_manifest")
		choose((options[i] as MissionDef).id)
		return
	var a := _menu.at(point)
	if a != "":
		_press(a)


## "Choose powers" goes once a mission is chosen; "New campaign" asks twice; "Title" always goes.
func _press(what: String) -> void:
	if what == "restart" and not confirming:
		confirming = true
		UiSound.play(&"ui_buzz")
		_ui.queue_redraw()
		return
	if what != "restart":
		confirming = false
	if what == "draft" and chosen == "":
		UiSound.play(&"ui_buzz")
		return
	UiSound.play(&"ui_click")
	action.emit(what)


func _select(i: int) -> void:
	if options.size() < 2:
		return
	i = posmod(i, options.size())
	if i != selected:
		selected = i
		UiSound.play(&"ui_hover")
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("title")
		elif event.physical_keycode == KEY_LEFT:
			_select(selected - 1)
		elif event.physical_keycode == KEY_RIGHT:
			_select(selected + 1)
		elif event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			# Enter chooses the card the keyboard is on; once it is chosen, Enter goes on to the draft.
			if options.size() >= 2 and chosen != (options[selected] as MissionDef).id:
				UiSound.play(&"ui_manifest")
				choose((options[selected] as MissionDef).id)
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
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.85))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.92))
	UiTheme.frame(_ui, PANEL, true)
	var n := CampaignDef.night(_state.night)
	_centred("NIGHT %d - TIER %d" % [_state.night + 1, int(n.tier)], HEAD_Y, UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	_centred(status_text(_state), STATUS_Y, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)

	var fragment: Dictionary = CampaignText.FRAGMENTS.get(String(n.fragment), {})
	var y := FRAGMENT_Y
	_centred(String(fragment.get("title", "")), y, UiTheme.SIZE_BODY, UiTheme.COL_GOLD_DARK)
	y += UiTheme.LINE_BODY + 4.0
	for line in UiTheme.wrap(String(fragment.get("text", "")), FRAGMENT_W, UiTheme.SIZE_BODY):
		_centred(line, y, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY

	if options.size() >= 2:
		for i in options.size():
			_draw_card(card_rect(i, options.size()), options[i] as MissionDef, i)
		var hint := "Left and Right, then Enter, to choose tonight's mission" if chosen == "" \
			else "Enter or Choose powers to draft for it"
		if confirming:
			hint = "Press New campaign again to start over"
		_centred(hint, HINT_Y, UiTheme.SIZE_SMALL, UiTheme.COL_BAD if confirming else UiTheme.COL_DIM)
	elif options.size() == 1:
		var def := options[0] as MissionDef
		_centred("Tonight: " + def.name, ONE_Y, UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
		var by := ONE_Y + 22.0
		for k in mini(def.brief.size(), 2):
			_centred(def.brief[k], by, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
			by += UiTheme.LINE_BODY
		if confirming:
			_centred("Press New campaign again to start over", HINT_Y, UiTheme.SIZE_SMALL, UiTheme.COL_BAD)
	_menu.draw_on(_ui, _hover, PackedStringArray(["draft"]) if chosen == "" else PackedStringArray())


func _centred(s: String, y: float, size: int, col: Color) -> void:
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(s, size) * 0.5), y), s, size, col)


## One card, top to bottom: the mission's name, its path, its brief, then Cael's line in gold at the foot. The chosen
## card wears the bright frame; the one the keyboard is on is lit.
func _draw_card(r: Rect2, def: MissionDef, i: int) -> void:
	var on := def.id == chosen
	_ui.draw_rect(r, Color(0.12, 0.1, 0.05, 0.95) if on else (Color(0.1, 0.09, 0.07, 0.9) if i == selected
		else UiTheme.COL_PANEL))
	UiTheme.frame(_ui, r, on)
	var x := r.position.x + PAD
	var room := r.size.x - PAD * 2.0
	var y := r.position.y + PAD + 12.0
	UiTheme.text(_ui, Vector2(x, y), UiTheme.fit(def.name, room, UiTheme.SIZE_BIG), UiTheme.SIZE_BIG,
		UiTheme.COL_GOLD if on else UiTheme.COL_GOLD_DARK)
	y += UiTheme.LINE_BODY
	var p := CampaignDef.path_of(_state.night, def.id)
	if p != "":
		UiTheme.text(_ui, Vector2(x, y), String(CampaignText.PATH_NAMES.get(p, "")), UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	y += UiTheme.LINE_SMALL + 4.0
	var text_col := UiTheme.COL_TEXT if on or i == selected else UiTheme.COL_DIM
	for k in mini(def.brief.size(), 2):
		for line in UiTheme.wrap(def.brief[k], room, UiTheme.SIZE_SMALL):
			UiTheme.text(_ui, Vector2(x, y), line, UiTheme.SIZE_SMALL, text_col)
			y += UiTheme.LINE_SMALL
	var meet := UiTheme.wrap(card_line(def, _state), room, UiTheme.SIZE_SMALL)
	var foot := r.end.y - PAD - UiTheme.LINE_SMALL * float(maxi(meet.size() - 1, 0))
	for line in meet:
		UiTheme.text(_ui, Vector2(x, foot), line, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
		foot += UiTheme.LINE_SMALL
