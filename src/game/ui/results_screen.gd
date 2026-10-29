class_name ResultsScreen
extends Node
## Results (spec §5): the ending in gold for a win or red for a loss, the big rank letter, the score, NEW BEST!
## when it is one, the stat table with what each line was worth, and Replay / Change powers / Missions. A mission
## without a score (v0.08: The Warning) shows its goal and bonus ticked or crossed, the time and "Solved by" instead.
## A night (v0.09: a result with acts) shows each act's mark and bonuses, the path and the night's total.
## It is drawn over the mission's frozen ruins, which Game keeps up underneath it.

## "replay" (the same four powers again), "change" (back to the draft) or "missions" (the mission board, v0.08). A board night
## (the test mode since god P1) has the same three; "upgrades" (v0.11 M1) went with the Upgrades button. An Endless Night's
## (god P1, spec §9.2) are "continue" (the hub), "tree" and "faith".
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

## Endless Night's Divine Power bar (god P1, spec §9.2): how long it takes to fill, how long a level line's gold flash lasts once the
## bar has passed it, and where the bar sits (its width, height, and the lowest baseline a line may have above the buttons).
const FILL_SECONDS := 1.0
const FLASH_SECONDS := 0.6
const BAR_WIDTH := 200.0
const BAR_HEIGHT := 6.0
const LINES_BOTTOM := 304.0

var _result := {}
var _ui: Control
var _menu: Menu
var _hover := ""
## A campaign night's results (v0.10): one Continue, and a line on what the night did to the god's power.
var campaign := false
## A board night's results (v0.11 M1, spec §6): Board, Again and Change powers (god P1: the test mode), and the night's rows and lines.
var descend := false
## An Endless Night's results (god P1, spec §9.2): the result carries `god`, GodNight.bank()'s dictionary. It is a board night's rows
## and title, then the god's lines (god_lines()), and Continue / Skill Tree / Faith.
var endless := false
## Seconds since the results opened: drives the Divine Power bar's fill and the level lines' flash (drawing only).
var _t := 0.0


## The act-end words for The Long Night's Act II (v0.09), by the reason its objective ended it.
## v0.11 M1: "dawn" is The Warning's loss at the clock's end (no waiting, spec §7.3) and a board night caught by dawn.
## v0.11 M2: the new Tier 1 missions' endings. The Lost Lamb has its own keys (`lamb_out`, `lamb_taken`, `lamb`), never the Escort
## type's defaults (`out`, `taken`), so a later Escort mission using them is not given the lamb's words (final review).
## v0.11 M3: Omen's new missions' endings, each under the mission's own reason keys.
## v0.11 M4: Wrath's new missions' endings, each under the mission's own reason keys.
## v0.11 M5: Reckoning's new missions' endings, each under the mission's own reason keys.
## v0.11 M6: Ascendance's new missions' endings, each under the mission's own reason keys.
## God P3 (preflight G2): an Awaken rite's endings, `shards` (the last shard, won) and `cleansed` (the shrine lost); a rite that dawn ends reads "dawn".
const ACT_TITLES := {"festival": "THE FEAST IS BROKEN", "closed": "THE SQUARE IS CLOSED", "prince": "THE PRINCE IS DEAD",
	"sailed": "THE PRINCE HAS SAILED", "tide": "THE TIDE HAS TURNED", "held": "THE NIGHT PASSES",
	"gaze": "THE LANTERN LOOKS", "lantern": "THE LANTERN HEARS", "believers": "THEY BELIEVE", "few": "TOO FEW BELIEVE",
	"drained": "THE LANTERNS ARE DARK", "relit": "THE LANTERNS BURN ON", "flame": "THE FLAME IS STOLEN",
	"kept": "THE FLAME IS KEPT", "wren": "THE BOY IS DEAD", "late": "DAWN FINDS THE FLAME",
	"dawn": "DAWN COMES", "collector": "THE COLLECTORS ARE DEAD", "taxes": "THE TAXES ARE IN",
	"spoiled": "THE HARVEST IS SPOILED", "emptied": "A GRANARY IS EMPTIED", "lamb_out": "THE LAMB IS FREE",
	"lamb_taken": "THE LAMB IS TAKEN BACK", "lamb": "THE ACOLYTE IS DEAD",
	"ringers": "THE RINGERS ARE STOPPED", "fair": "THE FAIR IS SCATTERED", "market_closed": "THE MARKET IS CLOSED",
	"informer": "THE INFORMER IS DEAD", "names": "THE NAMES REACH THE TEMPLE", "cold": "THE TRAIL GOES COLD",
	"bread": "THE CROWN'S BREAD IS RUINED", "fed": "THE CROWN IS FED", "prisoner_out": "THE PRISONER IS FREE",
	"prisoner_taken": "THE PRISONER IS TAKEN BACK", "prisoner_inside": "THE PRISONER IS TAKEN INSIDE", "prisoner": "THE PRISONER IS DEAD",
	"hunt": "THE HUNT IS BROKEN", "cellar": "THE CELLAR IS FOUND", "bishop": "THE BISHOP IS DEAD",
	"bishop_safe": "THE BISHOP REACHES THE CITADEL", "bishop_taken": "THE KNIGHTS TAKE HIM AWAY",
	"garrison": "THE GARRISON IS BROKEN", "marches": "THE GARRISON MARCHES",
	"sermon": "THE CROWD BELIEVES", "sermon_over": "THE SERMON ENDS", "flock": "THE FLOCK IS SCATTERED",
	"relic": "THE RELIC IS OURS", "relic_kept": "THE RELIC REACHES THE CITADEL", "pip": "THE BOY IS DEAD",
	"eye_blind": "THE LANTERN'S EYE IS BLIND", "eye_open": "THE EYE OPENS",
	"exodus": "THE FAITHFUL ARE OUT", "exodus_few": "TOO FEW ARE LEFT", "gates_shut": "THE GATES ARE SHUT",
	"heart": "THE HEART OF FAITH IS BROKEN", "blessed": "THE GREAT FLAME IS BLESSED", "kindled": "THE FLAME IS KINDLED ANEW",
	"shards": "THE RITE IS DONE", "cleansed": "THE SHRINE IS CLEANSED"}

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
	endless = result.has("god") and not campaign
	descend = (result.has("descend") or endless) and not campaign
	set_process(endless)
	if endless:
		_menu = Menu.row(["continue", "tree", "faith"], ["Continue", "Skill Tree", "Faith"], 320.0, PANEL.end.y - 28.0, 120.0)
	elif campaign:
		_menu = Menu.row(["next"], ["Continue"], 320.0, PANEL.end.y - 28.0, 120.0)
	elif descend:
		_menu = Menu.row(["missions", "replay", "change"], ["Board", "Again", "Change powers"], 320.0, PANEL.end.y - 28.0, 120.0)
	else:
		_menu = Menu.row(["replay", "change", "missions"], ["Replay", "Change powers", "Missions"], 320.0,
			PANEL.end.y - 28.0, 120.0)
	return self


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if endless:
			if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
				action.emit("continue")
			return
		if campaign:
			if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
				action.emit("next")
			return
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			action.emit("replay")
		elif event.physical_keycode == KEY_ESCAPE:
			action.emit("missions")


## Runs the Divine Power bar and the level flashes (god P1, spec §9.2); it stops once they are over.
func _process(delta: float) -> void:
	_t += delta
	if _ui != null:
		_ui.queue_redraw()
	if _t >= FILL_SECONDS + FLASH_SECONDS:
		set_process(false)


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
		return "The god grows: +%d Might, %d Might now." % [int(c.get("dp_gain", 0)), int(c.get("dp", 0))]
	return "Halcyon bites: %d Might now. Bites %d / %d." % [int(c.get("dp", 0)), int(c.get("bites", 0)), CampaignDef.MAX_BITES]


## A board night's rows (v0.11 M1, spec §6) as [label, value, mark, note]:
## - the main objective: its believers and a tick, or a cross;
## - each wish granted (its believers, a tick), lost (struck through, the reason in `note`), failed (a cross, unanswered) or
##   never answered ("open").
static func descend_rows(result: Dictionary) -> Array:
	var d: Dictionary = result.get("descend", {})
	var goal: Dictionary = result.get("goal", {})
	# An Awaken rite has no Descent (god P3, preflight G1): its goal row is ticked by the rite's win and pays no believers.
	if not rite_of(result).is_empty():
		var rite_won := bool(result.get("won", false))
		return [[String(goal.get("label", "")), "", "ok" if rite_won else "x", ""]]
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
## progress, and each best beaten. A test-mode night (god P1, ruling P11: `bank.test`) banks nothing: "Test mode: nothing banked",
## then each best beaten.
static func summary_lines(result: Dictionary) -> PackedStringArray:
	var d: Dictionary = result.get("descend", {})
	var bank: Dictionary = d.get("bank", {})
	var out := PackedStringArray()
	if bool(bank.get("test", false)):
		out.append("Test mode: nothing banked")
		for b in bank.get("bests", PackedStringArray()):
			out.append("New best: " + String(b))
		return out
	out.append("Believers +%d, %d now" % [int(bank.get("believers", d.get("earned", 0))), int(bank.get("total", 0))])
	out.append("Night %d" % int(bank.get("night", 0)))
	if String(bank.get("progress", "")) != "":
		out.append(String(bank.get("progress", "")))
	for b in bank.get("bests", PackedStringArray()):
		out.append("New best: " + String(b))
	return out


## An Endless Night's lines under its rows (god P1, spec §9.2), from `result.god` (GodNight.bank()'s dictionary), in order: the Divine
## Power earned (and AWAKEN TO GROW when the god is at its cap), one line per level gained, the Divine Power lost at the cap when any
## was (spec §8: the loss is simple and visible), the believers with the Faith they became and the Faith now, the Lantern Notice (with
## its change when it moved: god P2, Ruling P2-11), the Hunt's outcome, a seal that ended, a warning that the next night is the Hunt, and
## the night. Empty for a result with no god.
static func god_lines(result: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var g := _god_of(result)
	if g.is_empty():
		return out
	if not rite_of(result).is_empty():
		return _rite_lines(g)
	out.append("Divine Power +%d%s" % [int(g.get("divine_power", 0)), "   AWAKEN TO GROW" if bool(g.get("capped", false)) else ""])
	for level in _levels_of(g):
		out.append("Level %d   +1 ability point" % level)
	if int(g.get("lost", 0)) > 0:
		out.append("%d Divine Power lost at the cap" % int(g.get("lost", 0)))
	out.append("Believers %d   Faith +%d, %d now" % [int(g.get("believers", 0)), int(g.get("faith", 0)), int(g.get("faith_total", 0))])
	var change := int(g.get("notice_change", 0))
	if change == 0:
		out.append("Lantern Notice %d%%" % int(g.get("notice", 0)))
	else:
		out.append("Lantern Notice %d%%  (%s%d%%)" % [int(g.get("notice", 0)), "+" if change > 0 else "-", absi(change)])
	var hunt: Dictionary = g.get("hunt", {}) if g.get("hunt") is Dictionary else {}
	if not hunt.is_empty():
		if bool(hunt.get("won", false)):
			out.append("The Hunt is broken: Notice 0%%, Faith +%d" % int(hunt.get("faith", 0)))
		elif String(hunt.get("sealed", "")) != "":
			out.append("The Lantern seals %s for %s" % [PowerBook.get_power(String(hunt.sealed)).name,
				GodSlot.nights_text(int(hunt.get("seal_nights", 0)))])
		else:
			out.append("The Lantern found nothing to seal")
	var unsealed := String(g.get("unsealed", ""))
	if unsealed != "":
		out.append("%s is no longer sealed" % PowerBook.get_power(unsealed).name)
	if bool(g.get("hunt_next", false)):
		out.append("THE LANTERN HUNTS: the next night is the Hunt")
	out.append("Night %d" % int(g.get("night", 0)))
	return out


## An Awaken rite's god lines (god P3, MS §5, Ruling P3-4, preflight G6), in order: the Divine Power it feeds (none), then won: the tier
## crossed into ("Tier 2: Omen"), the points, the gift stolen; lost: the shards brought and that the god is still capped; then the Notice (with
## its change), a seal that ended, the Hunt coming and the night. No believers line (MS §1 R1).
static func _rite_lines(g: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var rite: Dictionary = g.rite
	out.append("Divine Power: none - the rite feeds no bar")
	if bool(rite.get("won", false)):
		out.append("Tier %d: %s" % [int(rite.get("tier", 1)), TierBook.tier_name(int(rite.get("tier", 1)))])
		out.append("+%d ability points" % int(rite.get("points", 0)))
		var gift: Dictionary = RiteBook.GIFTS.get(String(rite.get("gift", "")), {})
		if not gift.is_empty():
			out.append("Stolen: %s - %s" % [gift.name, gift.stolen])
	else:
		out.append("Lantern shards %d/%d" % [int(rite.get("shards", 0)), int(rite.get("need", 0))])
		out.append("The god is still capped. Awaken again when ready.")
	var change := int(g.get("notice_change", 0))
	if change == 0:
		out.append("Lantern Notice %d%%" % int(g.get("notice", 0)))
	else:
		out.append("Lantern Notice %d%%  (%s%d%%)" % [int(g.get("notice", 0)), "+" if change > 0 else "-", absi(change)])
	var unsealed := String(g.get("unsealed", ""))
	if unsealed != "":
		out.append("%s is no longer sealed" % PowerBook.get_power(unsealed).name)
	if bool(g.get("hunt_next", false)):
		out.append("THE LANTERN HUNTS: the next night is the Hunt")
	out.append("Night %d" % int(g.get("night", 0)))
	return out


## The colour of a god line that is not a level line (god P2, Ruling P2-11): a Notice rise, a seal, nothing to seal, the next Hunt and a
## loss at the cap are red, the Hunt won is gold, the rest plain. Matched by content, as P1 matched the cap loss.
static func god_line_color(line: String) -> Color:
	if line.begins_with("Lantern Notice") and line.contains("(+"):
		return UiTheme.COL_BAD
	if line.begins_with("The Lantern seals") or line.begins_with("The Lantern found nothing") or line.begins_with("THE LANTERN HUNTS") or line.ends_with("lost at the cap"):
		return UiTheme.COL_BAD
	if line.begins_with("The Hunt is broken"):
		return UiTheme.COL_GOLD
	# A rite (god P3): the tier crossed into and the gift are gold, the god left capped is red.
	if line.begins_with("The god is still capped"):
		return UiTheme.COL_BAD
	if line.begins_with("Stolen: ") or (line.begins_with("Tier ") and line.contains(": ")):
		return UiTheme.COL_GOLD
	return UiTheme.COL_TEXT


## "Lantern Hunt: <title>  -  <tier>" when the night was the Lantern's Hunt (god P2, Ruling P2-5), else "": results draw it in place of the
## mission line.
static func hunt_called(result: Dictionary) -> String:
	var g := _god_of(result)
	var hunt: Dictionary = g.get("hunt", {}) if g.get("hunt") is Dictionary else {}
	if hunt.is_empty():
		return ""
	return "Lantern Hunt: %s  -  %s" % [String(hunt.get("title", "")), TierBook.tier_name(int(hunt.get("tier", 1)))]


## "Awakening Rite: <name>  -  <tier played>" when the night was an Awaken rite (god P3, MS §1), else "": results draw it in place of the mission
## line. The tier is the one played: a won rite's `tier` is the one crossed into, so it is one less.
static func rite_called(result: Dictionary) -> String:
	var rite := rite_of(result)
	if rite.is_empty():
		return ""
	var played := maxi(int(rite.get("tier", 1)) - (1 if bool(rite.get("won", false)) else 0), 1)
	return "Awakening Rite: %s  -  %s" % [String(rite.get("name", "")), TierBook.tier_name(played)]


## The rite's entry (GodNight.bank()'s "rite") in a result, or {} when the night was not an Awaken rite (god P3).
static func rite_of(result: Dictionary) -> Dictionary:
	var g := _god_of(result)
	return g.rite if g.get("rite") is Dictionary and not (g.rite as Dictionary).is_empty() else {}


## The god's dictionary in a result: `result.god`, or the dictionary itself when it is one (it has Divine Power); {} otherwise.
static func _god_of(result: Dictionary) -> Dictionary:
	if result.get("god") is Dictionary:
		return result.god
	return result if result.has("divine_power") else {}


## The levels a night gained, as the bank listed them (a PackedInt32Array, or an Array in a hand-built result).
static func _levels_of(g: Dictionary) -> Array:
	var out := []
	var raw: Variant = g.get("levels", [])
	if raw is PackedInt32Array or raw is Array:
		for level: Variant in raw:
			out.append(int(level))
	return out


## The bar as the bank left it, as a fraction of the level the god is now on.
static func _bar_frac(g: Dictionary) -> float:
	var bar: Variant = g.get("bar", [0, 1])
	if bar is Array and bar.size() >= 2 and int(bar[1]) > 0:
		return clampf(float(bar[0]) / float(bar[1]), 0.0, 1.0)
	return 0.0


## The Divine Power bar's travel `t` seconds in (god P1, spec §9.2): `total` is the levels gained plus the fraction of the next
## one, covered evenly in FILL_SECONDS.
static func bar_progress(total: float, t: float) -> float:
	return total * clampf(t / FILL_SECONDS, 0.0, 1.0)


## What the bar shows `t` seconds in: the fraction of the level it is crossing, ending at `frac` after `levels` full bars.
static func bar_fill(levels: int, frac: float, t: float) -> float:
	var total := float(levels) + frac
	if total <= 0.0:
		return 0.0
	var p := bar_progress(total, t)
	if p >= total:
		return frac
	return p - floorf(p)


## True once the bar has passed level line `k` (from 0) of the `total`-long travel, `t` seconds in.
static func level_reached(k: int, total: float, t: float) -> bool:
	return total > 0.0 and t >= FILL_SECONDS * float(k + 1) / total


## The gold flash on level line `k`: 1 as the bar passes it, gone FLASH_SECONDS later; 0 before it and after.
static func level_flash(k: int, total: float, t: float) -> float:
	if not level_reached(k, total, t):
		return 0.0
	return clampf(1.0 - (t - FILL_SECONDS * float(k + 1) / total) / FLASH_SECONDS, 0.0, 1.0)


## A board night (v0.11 M1, spec §6): the mission and its tier under the title, its rows, a rule, then its lines. An Endless Night
## (god P1, spec §9.2) has the same rows and, in place of the bank's lines, the god's, with the Divine Power bar under the first.
func _draw_descend() -> void:
	var d: Dictionary = _result.get("descend", {})
	var called := hunt_called(_result)
	if called == "":
		called = rite_called(_result)
	if called == "":
		var def := TierBook.board(String(_result.get("mission", "")))
		called = "%s  -  %s" % [def.name if def != null else String(_result.get("mission", "")), TierBook.tier_name(int(d.get("tier", 1)))]
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
	if endless:
		_draw_god_lines(y)
		return
	var lines := summary_lines(_result)
	for i in lines.size():
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(lines[i], UiTheme.SIZE_BODY) * 0.5), y), lines[i], UiTheme.SIZE_BODY,
			UiTheme.COL_GOLD if i == 0 or lines[i].begins_with("New best") else UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY


## An Endless Night's lines from baseline `y` (god P1, spec §9.2): the Divine Power line in gold with its bar under it, which fills over
## FILL_SECONDS; then one line per level gained, dim until the bar passes it and gold as it does; then the rest. Lines close up (and
## shrink) only when a big night gains so many levels that they would run into the buttons.
func _draw_god_lines(y: float) -> void:
	var lines := god_lines(_result)
	var g := _god_of(_result)
	var gained := _levels_of(g)
	var frac := _bar_frac(g)
	var total := float(gained.size()) + frac
	UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(lines[0], UiTheme.SIZE_BODY) * 0.5), y), lines[0], UiTheme.SIZE_BODY,
		UiTheme.COL_GOLD)
	var bar := Rect2(roundf(320.0 - BAR_WIDTH * 0.5), y + 4.0, BAR_WIDTH, BAR_HEIGHT)
	_ui.draw_rect(bar, Color(0.04, 0.04, 0.06, 0.9))
	var fill := bar_fill(gained.size(), frac, _t)
	if fill > 0.0:
		_ui.draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * fill), bar.size.y)), UiTheme.COL_GOLD)
	UiTheme.frame(_ui, bar, false)
	y += 4.0 + BAR_HEIGHT + UiTheme.LINE_BODY - 2.0
	var rest := lines.size() - 1
	var step := UiTheme.LINE_BODY if rest <= 0 else minf(UiTheme.LINE_BODY, (LINES_BOTTOM - y) / float(rest))
	var size := UiTheme.SIZE_BODY if step >= UiTheme.LINE_BODY - 0.5 else UiTheme.SIZE_SMALL
	for i in range(1, lines.size()):
		var col := god_line_color(lines[i])
		if i <= gained.size():
			var k := i - 1
			col = UiTheme.COL_DIM
			if level_reached(k, total, _t):
				col = UiTheme.COL_TEXT.lerp(UiTheme.COL_GOLD, level_flash(k, total, _t))
		UiTheme.text(_ui, Vector2(roundf(320.0 - UiTheme.width(lines[i], size) * 0.5), y), lines[i], size, col)
		y += step


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
