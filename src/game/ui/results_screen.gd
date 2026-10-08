class_name ResultsScreen
extends Node
## Results (spec §5): the ending in gold for a win or red for a loss, the big rank letter, the score, NEW BEST!
## when it is one, the stat table with what each line was worth, and Replay / Change powers / Missions. A mission
## without a score (v0.08: The Warning) shows its goal and bonus ticked or crossed, the time and "Solved by" instead.
## A night (v0.09: a result with acts) shows each act's mark and bonuses, the path and the night's total.
## It is drawn over the mission's frozen ruins, which Game keeps up underneath it.

## "replay" (the same four powers again), "change" (back to the draft) or "missions" (the mission board, v0.08); a board night's
## also "upgrades" (v0.11 M1).
signal action(name: String)

const PANEL := Rect2(36.0, 20.0, 568.0, 320.0)
## The stat table's columns: label, value (right-aligned), points (right-aligned).
const TABLE_X := 300.0
const VALUE_R := 500.0
const POINTS_R := 588.0
const ROW := 14.0
## An unscored mission's table (v0.08): its labels' left edge, its values' right edge, the first row and the row step.
const PLAIN_L := 196.0
const PLAIN_R := 444.0
const PLAIN_TOP := 124.0
const PLAIN_ROW := 22.0
## A night's act table (v0.09): how far its bonus rows are indented.
const BONUS_INDENT := 10.0
## What "Solved by" says when nothing solved it.
const NOBODY := "-"
## The baseline of a campaign night's line, over the button.
const CAMPAIGN_Y := 304.0

## A board night's table (v0.11 M1): its labels' left edge, its values' and marks' right edge, the first row and the step.
const DESCEND_L := 100.0
const DESCEND_R := 540.0
const DESCEND_TOP := 112.0
const DESCEND_ROW := 18.0

var _result := {}
var _ui: Control
var _menu: Menu
var _hover := ""
## A campaign night's results (v0.10): one Continue, and a line on what the night did to the god's power.
var campaign := false
## A board night's results (v0.11 M1, spec §6): Board, Again and Upgrades, and the night's rows and lines.
var descend := false


## The act-end words for The Long Night's Act II (v0.09), by the reason its objective ended it.
## v0.11 M1: "dawn" is The Warning's loss at the clock's end (no waiting, spec §7.3) and a board night caught by dawn.
## v0.11 M2: the new Tier 1 missions' endings.
const ACT_TITLES := {"festival": "THE FEAST IS BROKEN", "closed": "THE SQUARE IS CLOSED", "prince": "THE PRINCE IS DEAD",
	"sailed": "THE PRINCE HAS SAILED", "tide": "THE TIDE HAS TURNED", "held": "THE NIGHT PASSES",
	"gaze": "THE LANTERN LOOKS", "believers": "THEY BELIEVE", "few": "TOO FEW BELIEVE",
	"drained": "THE LANTERNS ARE DARK", "relit": "THE LANTERNS BURN ON", "flame": "THE FLAME IS STOLEN",
	"kept": "THE FLAME IS KEPT", "wren": "THE BOY IS DEAD", "late": "DAWN FINDS THE FLAME",
	"dawn": "DAWN COMES", "collector": "THE COLLECTORS ARE DEAD", "taxes": "THE TAXES ARE IN",
	"spoiled": "THE HARVEST IS SPOILED", "emptied": "A GRANARY IS EMPTIED"}

## The line across the top for each way a mission can end.
static func title_for(won: bool, reason: String) -> String:
	if reason in ["warning", "omen"]:
		return "THE WARNING DIES"  # (v0.08: the messenger killed unseen, or the omen faded with the bell silent; the board's: all three stars stopped)
	if reason == "bell":
		return "THE BELL TOLLS"
	if ACT_TITLES.has(reason):
		return String(ACT_TITLES[reason])
	if won:
		return "THE CITY HAS FALLEN"
	return "THE PEOPLE ESCAPED" if reason == "escapes" else "MANIFESTATION ENDED"


## "Solved by" in an unscored mission's results (v0.08): the Authorities' titles, or NOBODY -- and NOBODY for a loss,
## whose delays solved nothing.
static func solved_text(result: Dictionary) -> String:
	var by := PackedStringArray(result.get("solved_by", PackedStringArray()))
	if not bool(result.get("won", false)) or by.is_empty():
		return NOBODY
	return ", ".join(by)


## 12450 -> "12,450".
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


func setup(result: Dictionary) -> ResultsScreen:
	_result = result
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	campaign = result.has("campaign")
	descend = result.has("descend") and not campaign
	if campaign:
		_menu = Menu.row(["next"], ["Continue"], 320.0, PANEL.end.y - 28.0, 120.0)
	elif descend:
		_menu = Menu.row(["missions", "replay", "upgrades"], ["Board", "Again", "Upgrades"], 320.0, PANEL.end.y - 28.0, 120.0)
	else:
		_menu = Menu.row(["replay", "change", "missions"], ["Replay", "Change powers", "Missions"], 320.0,
			PANEL.end.y - 28.0, 120.0)
	return self


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if campaign:
			if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
				action.emit("next")
			return
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			action.emit("replay")
		elif event.physical_keycode == KEY_ESCAPE:
			action.emit("missions")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _menu.at(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_ui.queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var a := _menu.at(event.position)
		if a != "":
			UiSound.play(&"ui_click")
			action.emit(a)


func _draw_ui() -> void:
	var won := bool(_result.get("won", false))
	_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.0, 0.0, 0.0, 0.5))
	_ui.draw_rect(PANEL, Color(0.03, 0.03, 0.05, 0.9))
	UiTheme.frame(_ui, PANEL, true)

	var title := title_for(won, String(_result.get("reason", "")))
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(title, UiTheme.SIZE_TITLE) * 0.5), 60.0), title,
		UiTheme.SIZE_TITLE, UiTheme.COL_GOLD if won else UiTheme.COL_BAD)
	if descend:
		_draw_descend()
		_draw_menu()
		return
	if not _result.has("score"):
		_draw_unscored()
		_draw_menu()
		return

	_draw_rank()
	if _result.has("acts"):
		_draw_night()
		_draw_menu()
		return

	# The stat table: what happened, and what each line was worth.
	var y := 100.0
	var total := 0
	for line: Dictionary in _result.get("lines", []):
		var label := String(line.label)
		var value := String(line.value)
		var points := int(line.points)
		total += points
		UiTheme.text(_ui, Vector2(TABLE_X, y), label, UiTheme.SIZE_SMALL)
		if value != "":
			UiTheme.text(_ui, Vector2(VALUE_R - UiTheme.width(value, UiTheme.SIZE_SMALL), y), value, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		var pts := thousands(points)
		UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(pts, UiTheme.SIZE_SMALL), y), pts, UiTheme.SIZE_SMALL,
			UiTheme.COL_TEXT if points > 0 else UiTheme.COL_DIM)
		y += ROW
	_ui.draw_line(Vector2(TABLE_X, y - 7.0), Vector2(POINTS_R, y - 7.0), UiTheme.COL_GOLD_DARK, -1.0)
	var sum := thousands(total)
	UiTheme.text(_ui, Vector2(TABLE_X, y + 4.0), "Total", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(sum, UiTheme.SIZE_SMALL), y + 4.0), sum, UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)

	_draw_menu()


## The rank on the left, big, with the score beside it and NEW BEST! under it when it is one.
func _draw_rank() -> void:
	var rank := String(_result.get("rank", "D"))
	UiTheme.text(_ui, Vector2(64.0, 162.0), rank, UiTheme.SIZE_HUGE, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(66.0, 176.0), "RANK", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(132.0, 102.0), "SCORE", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(130.0, 132.0), thousands(int(_result.get("score", 0))), UiTheme.SIZE_TITLE)
	if bool(_result.get("best", false)):
		UiTheme.text(_ui, Vector2(132.0, 154.0), "NEW BEST!", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)


## The path's name for the night's results: "festival" -> "The Festival".
static func path_name(path: String) -> String:
	return "" if path == "" else "The " + path.capitalize()


## A night (v0.09), on the right of the rank: one row per act -- its name, a tick or a cross, each of its bonuses
## beneath with its own -- then the path taken and the night's total. Act III's own lines (seven rows, and its
## "Citizens escaped" counts from its start alone) do not fit under the acts, so they are left to the total.
func _draw_night() -> void:
	var night := MissionBook.get_mission(String(_result.get("mission", MissionBook.LONG_NIGHT)))
	var y := 100.0
	for a: Dictionary in _result.get("acts", []):
		var act := night.act(String(a.get("act", "")))
		var called := act.name if act != null else String(a.get("act", ""))
		var won := bool(a.get("won", false))
		UiTheme.text(_ui, Vector2(TABLE_X, y), called, UiTheme.SIZE_SMALL, UiTheme.COL_TEXT if won else UiTheme.COL_DIM)
		UiTheme.mark(_ui, Vector2(POINTS_R - 7.0, y - 8.0), won)
		y += ROW
		for b: Dictionary in a.get("bonuses", []):
			var earned := bool(b.get("earned", false))
			UiTheme.text(_ui, Vector2(TABLE_X + BONUS_INDENT, y), String(b.get("label", "")), UiTheme.SIZE_SMALL,
				UiTheme.COL_DIM)
			UiTheme.mark(_ui, Vector2(POINTS_R - 7.0, y - 8.0), earned)
			y += ROW
	var path := path_name(String(_result.get("path", "")))
	if path != "":
		UiTheme.text(_ui, Vector2(TABLE_X, y), "Path", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(path, UiTheme.SIZE_SMALL), y), path, UiTheme.SIZE_SMALL,
			UiTheme.COL_GOLD)
		y += ROW
	_ui.draw_line(Vector2(TABLE_X, y - 7.0), Vector2(POINTS_R, y - 7.0), UiTheme.COL_GOLD_DARK, -1.0)
	var sum := thousands(int(_result.get("score", 0)))
	UiTheme.text(_ui, Vector2(TABLE_X, y + 4.0), "Night total", UiTheme.SIZE_SMALL, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(POINTS_R - UiTheme.width(sum, UiTheme.SIZE_SMALL), y + 4.0), sum, UiTheme.SIZE_SMALL,
		UiTheme.COL_GOLD)


## An unscored result's rows (v0.08; v0.10 M5 the Feast's too), as [label, value, ok]: the goal and each bonus with a tick
## or a cross (value ""), the time, and "Solved by" only when the result says what solved it (The Warning's).
static func plain_rows(result: Dictionary) -> Array:
	var goal: Dictionary = result.get("goal", {})
	var rows := [[String(goal.get("label", "")), "", bool(goal.get("done", false))]]
	for b: Dictionary in result.get("bonuses", []):
		rows.append([String(b.get("label", "")), "", bool(b.get("earned", false))])
	rows.append(["Time", UiTheme.clock(float(result.get("time", 0.0))), false])
	if result.has("solved_by"):
		rows.append(["Solved by", solved_text(result), false])
	return rows


## An unscored mission (v0.08): the mission's name under the title, then its goal and each bonus with a tick or a
## cross, the time it took, "Solved by" when the result has it (v0.10 M5), and NEW BEST! when it is one.
func _draw_unscored() -> void:
	var called := MissionBook.get_mission(String(_result.get("mission", ""))).name
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(called, UiTheme.SIZE_BODY) * 0.5), 84.0), called,
		UiTheme.SIZE_BODY, UiTheme.COL_DIM)
	var y := PLAIN_TOP
	var rows := plain_rows(_result)
	var ticks := 1 + (_result.get("bonuses", []) as Array).size()
	for i in rows.size():
		if i == ticks:
			# The rule between the ticked rows and the figures.
			_ui.draw_line(Vector2(PLAIN_L, y - 13.0), Vector2(PLAIN_R, y - 13.0), UiTheme.COL_GOLD_DARK, -1.0)
			y += 4.0
		var row: Array = rows[i]
		_plain_row(y, String(row[0]), String(row[1]), bool(row[2]))
		y += PLAIN_ROW
	if bool(_result.get("best", false)):
		var best := "NEW BEST!"
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(best, UiTheme.SIZE_BIG) * 0.5), y + 10.0), best,
			UiTheme.SIZE_BIG, UiTheme.COL_GOLD)


## One row of the unscored table, `y` its baseline: the label, then its value right-aligned -- or, with no value, a
## tick for `ok` or a cross.
func _plain_row(y: float, label: String, value: String, ok := false) -> void:
	UiTheme.text(_ui, Vector2(PLAIN_L, y), label, UiTheme.SIZE_BODY)
	if value != "":
		UiTheme.text(_ui, Vector2(PLAIN_R - UiTheme.width(value, UiTheme.SIZE_BODY), y), value, UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD)
	else:
		UiTheme.mark(_ui, Vector2(PLAIN_R - 7.0, y - 8.0), ok)


## What a campaign night did to the god (v0.10): grown, bitten, or eaten.
static func campaign_line(c: Dictionary) -> String:
	if String(c.get("ending", "")) == CampaignDef.EATEN:
		return "Halcyon has eaten you."
	if bool(c.get("won", false)):
		return "The god grows: +%d DP, %d DP now." % [int(c.get("dp_gain", 0)), int(c.get("dp", 0))]
	return "Halcyon bites: %d DP now. Bites %d / %d." % [int(c.get("dp", 0)), int(c.get("bites", 0)), CampaignDef.MAX_BITES]


## A board night's rows (v0.11 M1, spec §6) as [label, value, mark, note]:
## - the main objective: its believers and a tick, or a cross;
## - each wish granted (its believers, a tick), lost (struck through, the reason in `note`), failed (a cross, unanswered) or
##   never answered ("open").
static func descend_rows(result: Dictionary) -> Array:
	var d: Dictionary = result.get("descend", {})
	var goal: Dictionary = result.get("goal", {})
	var main := bool(d.get("main", false))
	var rows := [[String(goal.get("label", "")), ("+%d" % int(d.get("main_reward", 0))) if main else "", "ok" if main else "x", ""]]
	for w: Dictionary in d.get("wishes", []):
		var text := String(w.get("text", ""))
		var state := String(w.get("state", "open"))
		if state == "granted" and bool(w.get("lost", false)):
			rows.append([text, "", "lost", String(d.get("lost_text", ""))])
		elif state == "granted":
			rows.append([text, "+%d" % int(w.get("reward", 0)), "ok", ""])
		elif state == "failed":
			rows.append([text, "", "x", Wish.UNANSWERED])
		else:
			rows.append([text, "", "open", ""])
	return rows


## The line under a caught board night's title (v0.11 M1, spec §6): why the night ended after its main objective, from the
## reason Descent already lost its wishes to ("lost: dawn came" reads "Caught: dawn came."), and that the win stands. "" for
## an ascended night, a lost one, or any result off the board.
static func caught_line(result: Dictionary) -> String:
	var d: Dictionary = result.get("descend", {})
	var why := String(d.get("lost_text", "")).trim_prefix("lost: ")
	if not bool(d.get("main", false)) or bool(d.get("ascended", false)) or String(d.get("caught", "")) == "" or why == "":
		return ""
	return "Caught: %s. The night's main win stands." % why


## A board night's lines under its rows (v0.11 M1, spec §6): the believers banked and the new total, the night, the tier's
## progress, and each best beaten.
static func summary_lines(result: Dictionary) -> PackedStringArray:
	var d: Dictionary = result.get("descend", {})
	var bank: Dictionary = d.get("bank", {})
	var out := PackedStringArray()
	out.append("Believers +%d, %d now" % [int(bank.get("believers", d.get("earned", 0))), int(bank.get("total", 0))])
	out.append("Night %d" % int(bank.get("night", 0)))
	if String(bank.get("progress", "")) != "":
		out.append(String(bank.get("progress", "")))
	for b in bank.get("bests", PackedStringArray()):
		out.append("New best: " + String(b))
	return out


## A board night (v0.11 M1, spec §6): the mission and its tier under the title, its rows, a rule, then its lines.
func _draw_descend() -> void:
	var d: Dictionary = _result.get("descend", {})
	var def := TierBook.board(String(_result.get("mission", "")))
	var called := "%s  -  %s" % [def.name if def != null else String(_result.get("mission", "")),
		TierBook.tier_name(int(d.get("tier", 1)))]
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(called, UiTheme.SIZE_BODY) * 0.5), 84.0), called, UiTheme.SIZE_BODY,
		UiTheme.COL_DIM)
	var caught := caught_line(_result)
	if caught != "":
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(caught, UiTheme.SIZE_SMALL) * 0.5), 98.0), caught, UiTheme.SIZE_SMALL,
			UiTheme.COL_BAD)
	var y := DESCEND_TOP
	for row: Array in descend_rows(_result):
		_descend_row(y, row)
		y += DESCEND_ROW
	_ui.draw_line(Vector2(DESCEND_L, y - 10.0), Vector2(DESCEND_R, y - 10.0), UiTheme.COL_GOLD_DARK, -1.0)
	y += 4.0
	var lines := summary_lines(_result)
	for i in lines.size():
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(lines[i], UiTheme.SIZE_BODY) * 0.5), y), lines[i], UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD if i == 0 or lines[i].begins_with("New best") else UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY


## One board row, `y` its baseline: the label (struck through when lost, dim when unanswered), its note in red before the
## right edge, then its value or its mark at the right edge.
func _descend_row(y: float, row: Array) -> void:
	var label := String(row[0])
	var value := String(row[1])
	var mark := String(row[2])
	var note := String(row[3])
	var dim := mark == "lost" or mark == "open"
	UiTheme.text(_ui, Vector2(DESCEND_L, y), label, UiTheme.SIZE_BODY, UiTheme.COL_DIM if dim else UiTheme.COL_TEXT)
	if mark == "lost":
		_ui.draw_line(Vector2(DESCEND_L, y - 5.0), Vector2(DESCEND_L + UiTheme.width(label, UiTheme.SIZE_BODY), y - 5.0),
			UiTheme.COL_DIM, -1.0)
	if note != "":
		UiTheme.text(_ui, Vector2(DESCEND_R - 12.0 - UiTheme.width(note, UiTheme.SIZE_SMALL), y), note, UiTheme.SIZE_SMALL,
			UiTheme.COL_BAD)
	if value != "":
		UiTheme.text(_ui, Vector2(DESCEND_R - UiTheme.width(value, UiTheme.SIZE_BODY) - (12.0 if mark == "ok" else 0.0), y),
			value, UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	if mark == "ok" or mark == "x":
		UiTheme.mark(_ui, Vector2(DESCEND_R - 7.0, y - 8.0), mark == "ok")


## The buttons, and over them a campaign night's line.
func _draw_menu() -> void:
	if campaign:
		var c: Dictionary = _result.campaign
		var line := campaign_line(c)
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(line, UiTheme.SIZE_BODY) * 0.5), CAMPAIGN_Y), line,
			UiTheme.SIZE_BODY, UiTheme.COL_GOLD if bool(c.get("won", false)) else UiTheme.COL_BAD)
	_menu.draw_on(_ui, _hover)
