extends RefCounted
## God P2 Task 3 adds the Lantern to these screens: the results' Notice change and Hunt lines, Prepare's Hunt header and stake and its
## sealed cards, and the pause confirm's price (spec §9.1, §10; Rulings P2-4, P2-5, P2-11; preflight B2, R4, R5, R7).
## God P1 Task 10 (spec §9.1, §9.2, Rulings P9 and P21): Endless Night's results (the god's lines and menu), the pause menu's Abandon
## confirm (it says what leaving costs before it asks), and Prepare from the learned abilities at their levels.
##
## `result.god` is read here as a plain dictionary in the shape GodNight.bank() returns (Task 5 builds it beside this task, so this
## file never calls GodNight).

const PATH := "user://test_endless_screens_settings.cfg"


static func run(t) -> void:
	GodTree.dev_fill = true
	_results_menu(t)
	_god_lines(t)
	_god_lines_notice(t)
	_god_lines_hunt(t)
	_hunt_called(t)
	_bar_animation(t)
	_pause_endless(t)
	_pause_hunt(t)
	_pause_lost_notice(t)
	_prepare_god(t)
	_prepare_sealed(t)
	_prepare_hunt(t)
	_prepare_hunt_fits(t)
	_prepare_rite(t)
	_prepare_gifts_row(t)
	_god_lines_rite_won(t)
	_god_lines_rite_lost(t)
	_rite_called(t)
	_pause_rite(t)
	_interlude_endless(t)
	_refuse_and_card_cost(t)
	GodTree.dev_fill = false
	_title_entry(t)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	return e


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _god_result() -> Dictionary:
	return {"mission": "warning", "won": true, "reason": "warning", "time": 80.0,
		"goal": {"label": "Stop the three warnings", "done": true},
		"descend": {"tier": 1, "main": true, "main_reward": 10, "wishes": [], "earned": 30, "ascended": true},
		"god": {"divine_power": 120, "levels": PackedInt32Array([2, 3]), "points": 2, "lost": 0, "capped": false, "level": 3,
			"bar": [20, 50], "believers": 30, "faith": 30, "faith_total": 45, "notice": 0, "notice_change": 0, "night": 1,
			"bests": PackedStringArray()}}


static func _rows(m: Menu) -> Array:
	var out := []
	for item: Dictionary in m.items:
		out.append(String(item.action))
	return out


static func _labels(m: Menu) -> Array:
	var out := []
	for item: Dictionary in m.items:
		out.append(String(item.label))
	return out


static func _results_menu(t) -> void:
	var res := ResultsScreen.new().setup(_god_result())
	var emitted: Array[String] = []
	res.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(res.endless and res.descend, "a result with god is an Endless Night's, and still a board night's (%s %s)" % [res.endless, res.descend])
	t.check(_rows(res._menu) == ["continue", "tree", "faith"], "its menu is Continue / Skill Tree / Faith (%s)" % [_rows(res._menu)])
	t.check(_labels(res._menu) == ["Continue", "Skill Tree", "Faith"], "its labels (%s)" % [_labels(res._menu)])
	res._unhandled_input(_key(KEY_ENTER))
	res._unhandled_input(_key(KEY_ESCAPE))
	t.check(emitted == ["continue", "continue"], "Enter and Esc both continue (%s)" % [emitted])
	res._on_gui_input(_click((res._menu.rect_of("tree") as Rect2).get_center()))
	res._on_gui_input(_click((res._menu.rect_of("faith") as Rect2).get_center()))
	t.check(emitted == ["continue", "continue", "tree", "faith"], "the buttons emit tree and faith (%s)" % [emitted])
	res.free()
	# A board night in test mode and a plain mission are not Endless Night's.
	var board := _god_result()
	board.erase("god")
	var test_night := ResultsScreen.new().setup(board)
	t.check(not test_night.endless and _rows(test_night._menu) == ["missions", "replay", "change"],
		"a board night keeps its three buttons (%s)" % [_rows(test_night._menu)])
	test_night.free()
	var plain := ResultsScreen.new().setup({"won": true, "reason": "escapes", "score": 100, "rank": "B"})
	t.check(not plain.endless and _rows(plain._menu) == ["replay", "change", "missions"], "a plain result keeps its menu")
	plain.free()


static func _god_lines(t) -> void:
	var got := ResultsScreen.god_lines(_god_result())
	var want := PackedStringArray(["Divine Power +120", "Level 2   +1 ability point", "Level 3   +1 ability point",
		"Believers 30   Faith +30, 45 now", "Lantern Notice 0%", "Night 1"])
	t.check(got == want, "the god's lines in spec §9.2's order (%s)" % [got])
	var capped := {"god": {"divine_power": 80, "levels": PackedInt32Array(), "capped": true, "lost": 30, "believers": 0, "faith": 0,
		"faith_total": 7, "notice": 25, "night": 4}}
	var c := ResultsScreen.god_lines(capped)
	t.check(c[0] == "Divine Power +80   AWAKEN TO GROW", "a capped god is told to awaken (%s)" % [c[0]])
	t.check(c.size() == 5 and c[1] == "30 Divine Power lost at the cap" and c[2] == "Believers 0   Faith +0, 7 now"
		and c[3] == "Lantern Notice 25%" and c[4] == "Night 4",
		"no level lines when no level was gained, and the Divine Power lost at the cap is shown as an amount (I1) (%s)" % [c])
	var clean := ResultsScreen.god_lines(_god_result())
	t.check(not "
".join(clean).contains("lost"), "nothing lost, no line about it (%s)" % [clean])
	# Levels may come as a plain Array (a hand-built result).
	var arr := ResultsScreen.god_lines({"god": {"divine_power": 5, "levels": [2], "capped": false, "believers": 1, "faith": 1,
		"faith_total": 1, "notice": 0, "night": 2}})
	t.check(arr.size() == 5 and arr[1] == "Level 2   +1 ability point", "levels as an Array too (%s)" % [arr])
	t.check(ResultsScreen.god_lines({}).is_empty(), "a result without god gives no god lines")


static func _bar_animation(t) -> void:
	# Two levels and two fifths of the next: the bar travels 2.4 bars in ResultsScreen.FILL_SECONDS.
	var total := 2.4
	t.check(is_zero_approx(ResultsScreen.bar_progress(total, 0.0)), "the bar starts empty")
	t.check(is_equal_approx(ResultsScreen.bar_progress(total, ResultsScreen.FILL_SECONDS), total)
		and is_equal_approx(ResultsScreen.bar_progress(total, ResultsScreen.FILL_SECONDS * 5.0), total), "and ends at its total")
	var passed := ResultsScreen.FILL_SECONDS / total   # the moment the bar passes the first level
	t.check(ResultsScreen.level_flash(0, total, passed * 0.5) == 0.0, "a level line is dark before the bar reaches it")
	t.check(ResultsScreen.level_flash(0, total, passed) > 0.9, "and bright as the bar passes it")
	t.check(ResultsScreen.level_flash(0, total, passed + ResultsScreen.FLASH_SECONDS + 0.01) == 0.0, "and the flash is over a moment later")
	t.check(ResultsScreen.level_flash(1, total, passed) == 0.0, "the second level has not flashed yet")
	var fill := ResultsScreen.bar_fill(2, 0.4, ResultsScreen.FILL_SECONDS)
	t.check(fill > 0.39 and fill < 0.41, "the finished bar shows the fraction of the next level (%s)" % [fill])
	t.check(ResultsScreen.bar_fill(0, 0.0, 5.0) == 0.0, "no gain, an empty bar")


static func _pause_endless(t) -> void:
	var pause := PauseMenu.new()
	pause.setup(false, Settings.new(), PATH, true, true)
	var emitted: Array[String] = []
	pause.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(_rows(pause._menu) == ["resume", "options", "abandon"], "Endless Night's pause rows (%s)" % [_rows(pause._menu)])
	t.check(_labels(pause._menu) == ["Resume", "Options", "Abandon night"], "and their labels (%s)" % [_labels(pause._menu)])
	pause._on_gui_input(_click((pause._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(emitted.is_empty() and pause.confirming(), "Abandon emits nothing, it asks (%s)" % [emitted])
	t.check(pause.confirm_line() == PauseMenu.CONFIRM_LOST
		and PauseMenu.CONFIRM_LOST == "Abandon now and the night is lost: no Divine Power, no Faith, Lantern Notice +25%.",
		"and says what it costs (%s)" % [pause.confirm_line()])
	t.check(_rows(pause._menu) == ["abandon", "stay"] and _labels(pause._menu) == ["Abandon", "Stay"],
		"with Abandon and Stay (%s)" % [_rows(pause._menu)])
	pause._on_gui_input(_click((pause._menu.rect_of("stay") as Rect2).get_center()))
	t.check(emitted.is_empty() and not pause.confirming() and _rows(pause._menu) == ["resume", "options", "abandon"],
		"Stay goes back to the rows and emits nothing (%s %s)" % [emitted, _rows(pause._menu)])
	pause._on_gui_input(_click((pause._menu.rect_of("abandon") as Rect2).get_center()))
	pause._unhandled_input(_key(KEY_ESCAPE))
	t.check(emitted.is_empty() and not pause.confirming(), "Esc in the confirm is Stay, not Resume (%s)" % [emitted])
	pause._on_gui_input(_click((pause._menu.rect_of("abandon") as Rect2).get_center()))
	pause._unhandled_input(_key(KEY_ENTER))
	t.check(emitted.is_empty() and pause.confirming(), "Enter does not confirm it (%s)" % [emitted])
	pause._on_gui_input(_click((pause._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(emitted == ["abandon"], "only the confirm's Abandon emits abandon (%s)" % [emitted])
	pause.free()

	var free := PauseMenu.new()
	free.setup(false, Settings.new(), PATH, true, false)
	var out: Array[String] = []
	free.action.connect(func(what: String) -> void: out.append(what))
	free._on_gui_input(_click((free._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(free.confirm_line() == PauseMenu.CONFIRM_FREE and PauseMenu.CONFIRM_FREE == "The clock has not started: leaving is free.",
		"before the clock starts, leaving is free and the confirm says so (%s)" % [free.confirm_line()])
	free._on_gui_input(_click((free._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(out == ["abandon"], "and its Abandon leaves (%s)" % [out])
	free.free()

	var plain := PauseMenu.new()
	plain.setup()
	t.check(_rows(plain._menu) == ["resume", "options", "restart", "change", "missions"], "the defaults keep the five rows (%s)" % [_rows(plain._menu)])
	plain.free()
	var camp := PauseMenu.new()
	camp.setup(true)
	t.check(_rows(camp._menu) == ["resume", "options", "restart", "change", "campaign"], "and a campaign's last is Campaign")
	camp.free()


## The def GodNight.def_for() will make, built here (Task 5 runs beside this one): The Warning's board def, the god's pool, slots, Might.
static func _def_for(god: GodSlot) -> MissionDef:
	var m := TierBook.board("warning")
	m.pool = god.draftable()
	m.slots = god.slots()
	m.dp_capacity = god.max_might()
	return m


static func _prepare_god(t) -> void:
	var god := GodSlot.make(1, "ruin", 7)
	god.learned = {"smite": 3, "ember": 1, "deathmark": 1}
	var prep := PrepareScreen.new()
	prep.god = god
	prep.setup(_def_for(god), PackedStringArray())
	t.check(prep.tabs() == PackedStringArray(["ruin", "death"]), "the tabs are the god's types holding a learned ability, in ring order (%s)" % [prep.tabs()])
	t.check(prep.authority_keys(0) == PackedStringArray(["smite", "ember"]), "ruin holds smite and ember in spot order (%s)" % [prep.authority_keys(0)])
	t.check(prep.authority_keys(1) == PackedStringArray(["deathmark"]), "death holds deathmark (%s)" % [prep.authority_keys(1)])
	t.check(prep.authority_keys(2).is_empty() and prep.authority_keys(-1).is_empty(), "no tab past the last")
	t.check(prep.draft.levels.get("smite", 0) == 3, "the draft carries the learned levels (%s)" % [prep.draft.levels])
	t.check(prep.draft.slots == god.slots() and prep.draft.capacity == god.max_might(),
		"slots and Might are the god's (%d / %d)" % [prep.draft.slots, prep.draft.capacity])
	t.check(prep.draft.toggle("smite") == "" and prep.draft.spent() == PowerBook.might("smite", 3),
		"picking smite spends its Might at level 3 (%d, expected %d)" % [prep.draft.spent(), PowerBook.might("smite", 3)])
	t.check(prep.draft.spent() == 2, "which is 2 (%d)" % prep.draft.spent())
	t.check(prep.draft.refusal("heaven") == "pool", "a power the god has not learned is not in the pool (%s)" % [prep.draft.refusal("heaven")])
	t.check(prep.draft.refusal("whisper") == "pool", "nor is another type's")
	# The level picker is off: no badge to hit, a slot is still a slot.
	t.check(not prep.level_picker, "no level picker for a god")
	var level_hit := false
	for x in range(0, 640, 4):
		for y in range(0, 360, 4):
			level_hit = level_hit or prep.hit(Vector2(x, y)).begins_with("level:")
	t.check(not level_hit, "hit() never returns a level badge")
	# Giving a pick back keeps the god's level for the next pick (the level is the god's, not the picker's).
	prep.click(PrepareScreen.cell_rect(1, prep.shown().size()).get_center())  # ember: smite is picked already
	prep.click(PrepareScreen.slot_rect(0, prep.draft.slots).get_center())      # smite goes back
	t.check(prep.draft.picks == PackedStringArray(["ember"]), "a slot gives its pick back (%s)" % [prep.draft.picks])
	prep.click(PrepareScreen.cell_rect(0, prep.shown().size()).get_center())  # smite again
	t.check(prep.draft.picks.has("smite") and prep.draft.level_of("smite") == 3,
		"and smite comes back at its learned level 3 (%d)" % prep.draft.level_of("smite"))
	# A remembered loadout opens on its first pick's tab.
	var second := PrepareScreen.new()
	second.god = god
	second.setup(_def_for(god), PackedStringArray(["deathmark", "smite"]))
	t.check(second.tab == 1 and second.draft.picks == PackedStringArray(["deathmark", "smite"]) and second.draft.level_of("smite") == 3,
		"a remembered loadout opens on its first pick's tab at the learned levels (tab %d, %s)" % [second.tab, second.draft.picks])
	second.free()
	prep.free()
	# Without a god nothing changes: the mission's Authorities and no forced levels.
	var plain := PrepareScreen.new()
	plain.setup(TierBook.board("warning"), PackedStringArray())
	t.check(plain.god == null and plain.tabs().size() > 0 and plain.draft.levels.is_empty(), "no god: Prepare as before")
	plain.free()


## I2 (final review): in Endless Night the interlude's second button is "Abandon night", Esc does nothing, and the click asks first with
## the pause menu's words before it emits "missions"; Stay (or Esc in the confirm) goes back. A board night's interlude is unchanged.
static func _interlude_endless(t) -> void:
	var ln := MissionBook.long_night()
	var result := {"mission": "omen", "won": true, "goal": {"label": "Stop the warning", "done": true}, "bonuses": [], "time": 21.4}
	var card := InterludeScreen.new()
	card.endless = true
	card.setup(result, [ln.act("festival")], NightState.new())
	var got: Array[String] = []
	card.action.connect(func(what: String) -> void: got.append(what))
	t.check(_labels(card._menu) == ["Choose powers", "Abandon night"], "an Endless Night interlude's buttons (%s)" % [_labels(card._menu)])
	card._unhandled_input(_key(KEY_ESCAPE))
	t.check(got.is_empty() and not card.confirming(), "Esc does nothing between the acts of a night (%s)" % [got])
	card.click(card.button_rect("missions").get_center())
	t.check(got.is_empty() and card.confirming(), "the button opens the confirm and leaves nothing yet (%s)" % [got])
	t.check(card.confirm_line() == PauseMenu.CONFIRM_LOST, "which says what the pause menu says (%s)" % card.confirm_line())
	t.check(_rows(card._menu) == ["missions", "stay"] and _labels(card._menu) == ["Abandon", "Stay"],
		"its buttons are Abandon and Stay (%s)" % [_labels(card._menu)])
	card._unhandled_input(_key(KEY_ENTER))
	t.check(got.is_empty() and card.confirming(), "Enter does not abandon (%s)" % [got])
	card._unhandled_input(_key(KEY_ESCAPE))
	t.check(got.is_empty() and not card.confirming() and card.confirm_line() == "", "Esc in the confirm is Stay")
	card.click(card.button_rect("missions").get_center())
	card.click(card.button_rect("stay").get_center())
	t.check(got.is_empty() and not card.confirming() and _labels(card._menu) == ["Choose powers", "Abandon night"],
		"Stay goes back to the two buttons (%s)" % [got])
	card.click(card.button_rect("missions").get_center())
	card.click(card.button_rect("missions").get_center())
	t.check(got == ["missions"], "Abandon in the confirm leaves the night (%s)" % [got])
	card.free()
	var board := InterludeScreen.new()
	board.setup(result, [ln.act("festival")], NightState.new())
	var board_got: Array[String] = []
	board.action.connect(func(what: String) -> void: board_got.append(what))
	board._unhandled_input(_key(KEY_ESCAPE))
	t.check(board_got == ["missions"] and _labels(board._menu) == ["Choose powers", "Missions"],
		"a board night's interlude is as before: Esc leaves, the button says Missions (%s)" % [board_got])
	board.free()


## M4: Game asks Prepare to refuse an empty draft through a public call. M5: a picked card shows its Might at the level it is picked at.
static func _refuse_and_card_cost(t) -> void:
	var prep := PrepareScreen.new()
	prep.setup(TierBook.board("warning"), PackedStringArray())
	t.check(prep.has_method("refuse"), "PrepareScreen.refuse() is public")
	if prep.has_method("refuse"):
		prep.call("refuse", PrepareScreen.REFUSE_EMPTY)
		t.check(prep.refused_reason == PrepareScreen.REFUSE_EMPTY, "and sets the reason the hint line shows (%s)" % prep.refused_reason)
	prep.level_picker = true
	t.check(prep.draft.toggle("smite") == "", "smite is picked on the board")
	t.check(prep.draft.set_level("smite", 5) == "", "and raised to L5")
	var picked := prep.card_cost_text("smite")
	t.check(picked.begins_with("%d Might" % PowerBook.might("smite", 5)) and PowerBook.might("smite", 5) > PowerBook.might("smite", 1),
		"a picked card shows its Might at L5, not L1 (%s)" % picked)
	var open := prep.card_cost_text("ember")
	t.check(open.begins_with("%d Might" % PowerBook.might("ember", 1)), "a card not picked shows the base Might (%s)" % open)
	prep.free()


## God T1R Task 8 (D7): the title's Endless Night row opens the slot select, and its Back returns to the title; the board's ENDLESS door
## still returns to the board. A suite runs before the tree is up, so no Game is built here: the screens the actions lead to, the Back each
## door picks and the two doors' wiring are proved here, and FLOW walks the screens themselves (the dev fill off from the title, on from the board).
static func _title_entry(t) -> void:
	t.check(Game.next_screen("title:endless") == Game.Screen.SLOTS, "the title's Endless Night leads to the slot select")
	t.check(Game.slots_back_action(Game.Screen.TITLE) == "slots:title" and Game.next_screen("slots:title") == Game.Screen.TITLE,
		"Back from the slots opened at the title returns to the title")
	t.check(Game.slots_back_action(Game.Screen.BOARD) == "slots:back" and Game.next_screen("slots:back") == Game.Screen.BOARD,
		"Back from the slots opened by the board's ENDLESS returns to the board")
	var text := FileAccess.get_file_as_string("res://src/game/game.gd")
	# Each door's lines in game.gd, read from a one-line anchor (a reworded anchor fails here by name, never passes on an empty window).
	var title_door := _lines_after(text, "# The real door into Endless Night", 3)
	t.check(title_door != "", "game.gd still has the title's Endless Night door comment (the anchor of the next check)")
	t.check(title_door.contains("GodTree.dev_fill = false") and title_door.contains("_endless_from = Screen.TITLE"),
		"the title's door turns the dev fill off and remembers it came from the title")
	var board_door := _lines_after(text, 'if what == "endless":', 4)
	t.check(board_door != "", "game.gd still has the board's ENDLESS door (the anchor of the next check)")
	t.check(board_door.contains("GodTree.dev_fill = true") and board_door.contains("_endless_from = Screen.BOARD"),
		"the board's door keeps the dev fill on and remembers it came from the board")


## The line of `text` holding `anchor` and the `more` lines after it, joined; "" when no line holds it.
static func _lines_after(text: String, anchor: String, more: int) -> String:
	var lines := text.split("
")
	for i in lines.size():
		if lines[i].contains(anchor):
			return "
".join(lines.slice(i, i + more + 1))
	return ""


## A key's name, for hand-built results (names are read from PowerBook, never typed).
static func _name_of(key: String) -> String:
	return String(PowerBook.get_power(key).name)


## A god dictionary in bank()'s shape with the Lantern's fields; `extra` overrides.
static func _g(extra := {}) -> Dictionary:
	var g := {"divine_power": 10, "levels": [], "capped": false, "lost": 0, "believers": 1, "faith": 1, "faith_total": 1, "notice": 0,
		"notice_change": 0, "night": 1}
	g.merge(extra, true)
	return g


static func _god_lines_notice(t) -> void:
	var up := ResultsScreen.god_lines({"god": _g({"notice": 25, "notice_change": 25})})
	t.check(up == PackedStringArray(["Divine Power +10", "Believers 1   Faith +1, 1 now", "Lantern Notice 25%  (+25%)", "Night 1"]),
		"a Notice that rose shows the change (%s)" % [up])
	var down := ResultsScreen.god_lines({"god": _g({"notice": 45, "notice_change": -5})})
	t.check(down[2] == "Lantern Notice 45%  (-5%)", "a Notice that fell shows the change (%s)" % [down])
	var same := ResultsScreen.god_lines({"god": _g({"notice": 45})})
	t.check(same[2] == "Lantern Notice 45%", "no change: P1's text (%s)" % [same])
	var absent := _g({"notice": 45})
	absent.erase("notice_change")
	t.check(ResultsScreen.god_lines({"god": absent})[2] == "Lantern Notice 45%", "an absent change: P1's text too")


static func _god_lines_hunt(t) -> void:
	var key: String = GodTree.starting("ruin")[0]
	var name := _name_of(key)
	var hunt := {"tier": 1, "id": "lost_lamb", "title": "Hide the faithful", "won": true, "faith": 50, "sealed": "", "seal_nights": 0}
	var won := ResultsScreen.god_lines({"god": _g({"notice": 0, "notice_change": -100, "hunt": hunt})})
	t.check(won == PackedStringArray(["Divine Power +10", "Believers 1   Faith +1, 1 now", "Lantern Notice 0%  (-100%)",
		"The Hunt is broken: Notice 0%, Faith +50", "Night 1"]), "a won Hunt (%s)" % [won])
	var lost_hunt := {"tier": 1, "id": "lost_lamb", "title": "Hide the faithful", "won": false, "faith": 0, "sealed": key, "seal_nights": 3}
	var lost := ResultsScreen.god_lines({"god": _g({"notice": 50, "notice_change": -50, "hunt": lost_hunt})})
	t.check(lost == PackedStringArray(["Divine Power +10", "Believers 1   Faith +1, 1 now", "Lantern Notice 50%  (-50%)",
		"The Lantern seals %s for 3 nights" % name, "Night 1"]), "a lost Hunt that sealed (%s)" % [lost])
	lost_hunt["sealed"] = ""
	lost_hunt["seal_nights"] = 0
	var nothing := ResultsScreen.god_lines({"god": _g({"notice": 50, "notice_change": -50, "hunt": lost_hunt})})
	t.check(nothing[3] == "The Lantern found nothing to seal" and nothing.size() == 5, "a lost Hunt with nothing to seal (%s)" % [nothing])
	var ended := ResultsScreen.god_lines({"god": _g({"notice": 20, "notice_change": -5, "unsealed": key})})
	t.check(ended == PackedStringArray(["Divine Power +10", "Believers 1   Faith +1, 1 now", "Lantern Notice 20%  (-5%)",
		"%s is no longer sealed" % name, "Night 1"]), "a seal that ended (%s)" % [ended])
	var next := ResultsScreen.god_lines({"god": _g({"notice": 100, "notice_change": 25, "hunt_next": true})})
	t.check(next == PackedStringArray(["Divine Power +10", "Believers 1   Faith +1, 1 now", "Lantern Notice 100%  (+25%)",
		"THE LANTERN HUNTS: the next night is the Hunt", "Night 1"]), "the next night is the Hunt (%s)" % [next])
	# C12: a lost Hunt that found nothing to seal still reports a seal that just ended, in order: Hunt, unsealed.
	var both := ResultsScreen.god_lines({"god": _g({"notice": 50, "notice_change": -50, "hunt": lost_hunt, "unsealed": key})})
	t.check(both[3] == "The Lantern found nothing to seal" and both[4] == "%s is no longer sealed" % name, "Hunt line then unsealed line (%s)" % [both])
	# Colours (Ruling P2-11): the bad news is red, the Hunt won is gold, the rest as ever.
	t.check(ResultsScreen.god_line_color("Lantern Notice 25%  (+25%)") == UiTheme.COL_BAD
		and ResultsScreen.god_line_color("Lantern Notice 45%  (-5%)") == UiTheme.COL_TEXT
		and ResultsScreen.god_line_color("Lantern Notice 45%") == UiTheme.COL_TEXT, "only a Notice rise is red")
	t.check(ResultsScreen.god_line_color("The Lantern seals %s for 3 nights" % name) == UiTheme.COL_BAD
		and ResultsScreen.god_line_color("The Lantern found nothing to seal") == UiTheme.COL_BAD
		and ResultsScreen.god_line_color("THE LANTERN HUNTS: the next night is the Hunt") == UiTheme.COL_BAD
		and ResultsScreen.god_line_color("30 Divine Power lost at the cap") == UiTheme.COL_BAD,
		"a seal, nothing to seal, the next Hunt, a cap loss: red")
	t.check(ResultsScreen.god_line_color("The Hunt is broken: Notice 0%, Faith +50") == UiTheme.COL_GOLD
		and ResultsScreen.god_line_color("Night 1") == UiTheme.COL_TEXT, "the Hunt won is gold, a night line plain")


static func _hunt_called(t) -> void:
	var hunt := {"tier": 1, "id": "lost_lamb", "title": "Hide the faithful", "won": true, "faith": 50, "sealed": "", "seal_nights": 0}
	var called := ResultsScreen.hunt_called({"god": _g({"hunt": hunt})})
	t.check(called == "Lantern Hunt: Hide the faithful  -  Whisper", "a Hunt result is called by its title and tier (%s)" % called)
	t.check(ResultsScreen.hunt_called({"god": _g()}) == "" and ResultsScreen.hunt_called({}) == "", "a night, or no god: nothing")


## A type of the dev fill with two starting keys, so a god of it has a seal target (preflight R3); fails the test with a message if none.
static func _two_key_type(t) -> String:
	for type: String in GodTree.RING:
		if GodTree.starting(type).size() >= 2:
			return type
	t.check(false, "the dev fill has a type with two starting keys")
	return ""


static func _fixture_god(t, tier := 1) -> GodSlot:
	var type := _two_key_type(t)
	var god := GodSlot.make(1, type, 7)
	god.tier = tier
	for key in GodTree.starting(type):
		god.learned[key] = 1
	return god


static func _prepare_sealed(t) -> void:
	var god := _fixture_god(t)
	var keys := god.in_tree()
	var key := keys[0]
	var type := str(GodTree.spot_of(key).get("type", ""))
	god.sealed = key
	god.seal_nights = 2
	var prep := PrepareScreen.new()
	prep.god = god
	prep.setup(_def_for(god), PackedStringArray([key]))
	var tab := prep.tabs().find(type)
	t.check(tab >= 0 and prep.authority_keys(tab).has(key), "a sealed key is listed in its type's tab (%s, tab %d)" % [prep.tabs(), tab])
	t.check(prep.draft.picks.is_empty(), "a remembered loadout cannot pick the sealed key (%s)" % [prep.draft.picks])
	prep.set_tab(maxi(tab, 0))
	t.check(prep.card_cost_text(key) == "Sealed: 2 nights", "its card says it is sealed (%s)" % prep.card_cost_text(key))
	prep.click(PrepareScreen.cell_rect(prep.shown().find(key), prep.shown().size()).get_center())
	t.check(not prep.draft.picks.has(key) and prep.refused_reason == "Sealed by the Lantern: 2 nights left",
		"a click on it picks nothing and says why (%s, %s)" % [prep.draft.picks, prep.refused_reason])
	# R7: even a def whose pool is empty (every power) cannot pick or preselect the sealed key.
	var open := TierBook.board("warning")
	t.check(open.pool.is_empty(), "the board's def has an empty pool, which means every power")
	var loose := PrepareScreen.new()
	loose.god = god
	loose.setup(open, PackedStringArray([key]))
	t.check(loose.draft.picks.is_empty(), "an empty-pool def: preselect keeps the sealed key out (%s)" % [loose.draft.picks])
	loose.set_tab(maxi(loose.tabs().find(type), 0))
	loose.click(PrepareScreen.cell_rect(loose.shown().find(key), loose.shown().size()).get_center())
	t.check(not loose.draft.picks.has(key) and loose.refused_reason == "Sealed by the Lantern: 2 nights left",
		"and a click keeps it out (%s)" % [loose.draft.picks])
	loose.free()
	# The other key still picks.
	prep.refused_reason = ""
	var other := keys[1]
	prep.set_tab(prep.tabs().find(str(GodTree.spot_of(other).get("type", ""))))
	prep.click(PrepareScreen.cell_rect(prep.shown().find(other), prep.shown().size()).get_center())
	t.check(prep.draft.picks.has(other) and prep.refused_reason == "", "an unsealed key is picked as before (%s)" % [prep.draft.picks])
	prep.free()


static func _prepare_hunt(t) -> void:
	var god := _fixture_god(t)
	god.notice = 100
	var hunt := GodNight.hunt_for(god)
	var prep := PrepareScreen.new()
	prep.god = god
	prep.setup(GodNight.def_for(god, String(hunt.id)), PackedStringArray())
	t.check(prep.header_text() == "THE LANTERN HUNT" and PrepareScreen.HUNT_HEADER == "THE LANTERN HUNT", "a Hunt's header (%s)" % prep.header_text())
	var rows := prep.brief_rows()
	var labels := []
	for row: Array in rows:
		labels.append(row[0])
	t.check(labels == ["HUNT", "WIN", "LOSE", "IF WON", "IF LOST"], "a Hunt's briefing rows (%s)" % [labels])
	t.check(String(rows[0][1]) == "%s: %s" % [hunt.title, hunt.plate], "the HUNT row is the title and its plate (%s)" % rows[0][1])
	t.check(String(rows[3][1]) == "Notice 0%%, +%d Faith" % (GodNight.HUNT_FAITH * god.tier), "IF WON (%s)" % rows[3][1])
	t.check(String(rows[4][1]).begins_with(GodNight.hunt_stake(god)) and String(rows[4][1]).ends_with("Notice 50%"),
		"IF LOST names the stake (%s)" % rows[4][1])
	prep.free()
	god.notice = 0
	var plain := PrepareScreen.new()
	plain.god = god
	plain.setup(GodNight.def_for(god, "warning"), PackedStringArray())
	var plain_labels := []
	for row: Array in plain.brief_rows():
		plain_labels.append(row[0])
	t.check(plain.header_text() == "PREPARE THE MANIFESTATION" and plain_labels == ["TARGET", "WIN", "LOSE", "CITY", "LOADOUT", "TEMPLE"],
		"any other night keeps the header and the six rows (%s %s)" % [plain.header_text(), plain_labels])
	plain.free()


## Preflight R4: the Hunt's rows fit the left panel above the hint line, for every god tier.
static func _prepare_hunt_fits(t) -> void:
	for tier in range(1, 6):
		var god := _fixture_god(t, tier)
		god.notice = 100
		var hunt := GodNight.hunt_for(god)
		var prep := PrepareScreen.new()
		prep.god = god
		prep.setup(GodNight.def_for(god, String(hunt.id)), PackedStringArray())
		var hint_lines := UiTheme.wrap(prep.hint_text(), PrepareScreen.PANEL.size.x - 8.0, UiTheme.SIZE_SMALL).size()
		var limit := PrepareScreen.PANEL.end.y - 8.0 - UiTheme.LINE_SMALL * float(hint_lines)
		t.check(prep.brief_bottom() <= limit, "tier %d's Hunt rows end at %s, above the hint (limit %s)" % [tier, prep.brief_bottom(), limit])
		prep.free()


static func _pause_hunt(t) -> void:
	var stake := "The Lantern will seal Judgement of the Ancients for 3 nights"
	var pause := PauseMenu.new()
	pause.hunt_stake = stake
	pause.setup(false, Settings.new(), PATH, true, true)
	pause._on_gui_input(_click((pause._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(pause.confirm_line() == PauseMenu.CONFIRM_HUNT % stake
		and PauseMenu.CONFIRM_HUNT == "Abandon the Hunt and it is lost. %s, and the Notice goes to 50%%.",
		"a Hunt's confirm names the stake (%s)" % pause.confirm_line())
	var lines := UiTheme.wrap(pause.confirm_line(), PauseMenu.CONFIRM_WIDTH, UiTheme.SIZE_BODY)
	var last_baseline := PauseMenu.CONFIRM_Y + UiTheme.LINE_BODY * float(lines.size() - 1)
	var row := pause._menu.rect_of("abandon") as Rect2
	t.check(lines.size() <= 3 and row.position.y > last_baseline + 3.0 and row.end.y < 360.0,
		"it takes at most 3 lines and the buttons sit under them (%d lines, last baseline %s, buttons at %s)" % [lines.size(), last_baseline, row])
	pause.free()
	var plain := PauseMenu.new()
	plain.setup(false, Settings.new(), PATH, true, true)
	plain._on_gui_input(_click((plain._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(plain.confirm_line() == PauseMenu.CONFIRM_LOST and PauseMenu.CONFIRM_LOST.contains("Lantern Notice +25%"),
		"without a stake, a lost night's confirm says the Notice rises (%s)" % plain.confirm_line())
	plain.free()
	var free := PauseMenu.new()
	free.hunt_stake = stake
	free.setup(false, Settings.new(), PATH, true, false)
	free._on_gui_input(_click((free._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(free.confirm_line() == PauseMenu.CONFIRM_FREE, "before the clock starts leaving the Hunt is still free (%s)" % free.confirm_line())
	free.free()


## God P2 fix wave (final review M2, Ruling F1): the lost-night confirm states the Notice rise that will really happen after the clamp
## (min(25, 100 - notice)) and, when the abandon fills the meter, that the Lantern Hunts next; at 100 already it says so plainly. The
## interlude's confirm reads the same words. A board night's and the Hunt's confirms are unchanged.
static func _pause_lost_notice(t) -> void:
	var cases := [
		{"notice": 0, "rise": 25, "hunt": false}, {"notice": 50, "rise": 25, "hunt": false},
		{"notice": 75, "rise": 25, "hunt": true}, {"notice": 95, "rise": 5, "hunt": true}, {"notice": 100, "rise": 0, "hunt": true},
	]
	for c: Dictionary in cases:
		var n: int = c.notice
		var pause := PauseMenu.new()
		pause.notice = n
		pause.setup(false, Settings.new(), PATH, true, true)
		pause._on_gui_input(_click((pause._menu.rect_of("abandon") as Rect2).get_center()))
		var line := pause.confirm_line()
		var rise_text := "Lantern Notice +%d%%" % c.rise
		t.check(line == PauseMenu.lost_line(n) and line.begins_with("Abandon now and the night is lost: no Divine Power, no Faith"),
			"notice %d: the confirm is lost_line (%s)" % [n, line])
		if c.rise > 0:
			t.check(line.contains(rise_text),
				"notice %d: it states the real rise, %s (%s)" % [n, rise_text, line])
		else:
			t.check(not line.contains("+") and line.contains("already 100%"), "notice 100: no rise is promised and it says it is already full (%s)" % line)
		t.check(line.contains("the Lantern Hunts next") == bool(c.hunt), "notice %d: the Hunt is named exactly when the abandon fills the meter (%s)" % [n, line])
		var lines := UiTheme.wrap(line, PauseMenu.CONFIRM_WIDTH, UiTheme.SIZE_BODY)
		var row := pause._menu.rect_of("abandon") as Rect2
		var last_baseline := PauseMenu.CONFIRM_Y + UiTheme.LINE_BODY * float(lines.size() - 1)
		t.check(lines.size() <= 3 and row.position.y > last_baseline + 3.0 and row.end.y < 360.0,
			"notice %d: at most 3 lines, buttons under them (%d lines, last baseline %s, buttons %s)" % [n, lines.size(), last_baseline, row])
		pause.free()
	t.check(PauseMenu.lost_line(0) == PauseMenu.CONFIRM_LOST, "the default (rise 25, no Hunt) is CONFIRM_LOST word for word (%s)" % PauseMenu.lost_line(0))
	# The Hunt's own confirm ignores the Notice; a free exit still says free.
	var hunt := PauseMenu.new()
	hunt.hunt_stake = "The Lantern will seal X for 3 nights"
	hunt.notice = 95
	hunt.setup(false, Settings.new(), PATH, true, true)
	hunt._on_gui_input(_click((hunt._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(hunt.confirm_line() == PauseMenu.CONFIRM_HUNT % hunt.hunt_stake, "a Hunt night's confirm is unchanged at any Notice (%s)" % hunt.confirm_line())
	hunt.free()
	var free := PauseMenu.new()
	free.notice = 95
	free.setup(false, Settings.new(), PATH, true, false)
	free._on_gui_input(_click((free._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(free.confirm_line() == PauseMenu.CONFIRM_FREE, "before the clock, leaving is free at any Notice (%s)" % free.confirm_line())
	free.free()
	# The interlude says the same.
	var ln := MissionBook.long_night()
	var result := {"mission": "omen", "won": true, "goal": {"label": "Stop the warning", "done": true}, "bonuses": [], "time": 21.4}
	for n: int in [0, 95, 100]:
		var card := InterludeScreen.new()
		card.endless = true
		card.notice = n
		card.setup(result, [ln.act("festival")], NightState.new())
		card.click(card.button_rect("missions").get_center())
		t.check(card.confirm_line() == PauseMenu.lost_line(n), "notice %d: the interlude's confirm is lost_line (%s)" % [n, card.confirm_line()])
		card.free()
	var card95 := InterludeScreen.new()
	card95.endless = true
	card95.notice = 95
	card95.setup(result, [ln.act("festival")], NightState.new())
	card95.click(card95.button_rect("missions").get_center())
	t.check(card95.confirm_line().contains("Lantern Notice +5%") and card95.confirm_line().contains("the Lantern Hunts next"),
		"the interlude at 95 says +5%% and the Hunt (%s)" % card95.confirm_line())
	card95.free()


## God P3 (MS §1, §4, §5, Rulings P3-4, P3-8, preflight R1, G1, G2, G6): the god at the cap of tier 1, level 10, bar full.
static func _rite_god(t, notice := 0) -> GodSlot:
	var god := _fixture_god(t)
	god.level = 10
	god.divine_power = god.need()
	god.notice = notice
	return god


## A rite's Prepare, with `god` and the rite's def as the god plays it.
static func _rite_prepare(god: GodSlot) -> PrepareScreen:
	var prep := PrepareScreen.new()
	prep.god = god
	prep.setup(GodNight.def_for(god, MissionBook.FIRST_TASTE), PackedStringArray())
	return prep


## The rite's Prepare: THE AWAKENING RITE in gold, the six rows with the exact copy (tier as "Tier 2: Omen", G6), and every row above the hint.
static func _prepare_rite(t) -> void:
	var god := _rite_god(t)
	var prep := _rite_prepare(god)
	t.check(prep.is_rite() and prep.header_text() == "THE AWAKENING RITE" and PrepareScreen.RITE_HEADER == "THE AWAKENING RITE",
		"a rite's header (%s)" % prep.header_text())
	var rows := prep.brief_rows()
	var labels := []
	for row: Array in rows:
		labels.append(row[0])
	t.check(labels == ["RITE", "WIN", "LOSE", "IF WON", "IF LOST", "CHAIN"], "a rite's briefing rows (%s)" % [labels])
	var row := RiteBook.row(MissionBook.FIRST_TASTE)
	t.check(String(rows[0][1]) == String(row.name), "RITE is the name (the plate does not fit six rows, preflight R1) (%s)" % rows[0][1])
	t.check(String(rows[1][1]) == prep.mission.goal and String(rows[2][1]) == prep.mission.lose, "WIN and LOSE are the mission's (%s, %s)" % [rows[1][1], rows[2][1]])
	t.check(String(rows[3][1]) == "Tier 2: Omen, +2 ability points, The Watchful Bell", "IF WON (%s)" % rows[3][1])
	t.check(String(rows[4][1]) == "Lantern Notice +25%; the god stays capped", "IF LOST (%s)" % rows[4][1])
	t.check(String(rows[5][1]) == "Chain of the Forgotten (C): free", "CHAIN (%s)" % rows[5][1])
	# Milestone review Minor 5: IF LOST shows the real clamped rise and names the Hunt it brings, as the pause confirm does.
	for at in [80, 90, 100]:
		var late := _rite_prepare(_rite_god(t, at))
		var rise: int = PauseMenu.rite_rise(at)
		var line := String(late.brief_rows()[4][1])
		var hunts: bool = at + rise >= GodSlot.NOTICE_MAX
		t.check(line.contains("+%d%%" % rise if rise > 0 else "already 100%") and line.contains("Hunts next") == hunts,
			"notice %d: IF LOST reads the real rise %d%s (%s)" % [at, rise, " and the Hunt" if hunts else "", line])
		var late_hint := UiTheme.wrap(late.hint_text(), PrepareScreen.PANEL.size.x - 8.0, UiTheme.SIZE_SMALL).size()
		t.check(late.brief_bottom() <= PrepareScreen.PANEL.end.y - 8.0 - UiTheme.LINE_SMALL * float(late_hint), "notice %d: the rows still end above the hint (%s)" % [at, late.brief_bottom()])
		late.free()
	var hint_lines := UiTheme.wrap(prep.hint_text(), PrepareScreen.PANEL.size.x - 8.0, UiTheme.SIZE_SMALL).size()
	var limit := PrepareScreen.PANEL.end.y - 8.0 - UiTheme.LINE_SMALL * float(hint_lines)
	t.check(prep.brief_bottom() <= limit, "the six rows end at %s, above the hint (limit %s)" % [prep.brief_bottom(), limit])
	prep.free()
	# A Hunt due (Notice 100) does not turn the rite's Prepare into the Hunt's: the rite is the mission (Game plays the Hunt first, Task 8).
	var due := _rite_god(t, 100)
	var hunt_prep := _rite_prepare(due)
	t.check(hunt_prep.header_text() == "THE AWAKENING RITE" and hunt_prep.brief_rows()[0][0] == "RITE", "a rite mission keeps its own header and rows")
	hunt_prep.free()
	# A god of tier 1 only: the row's tier is one above the god's.
	var tier2 := _rite_god(t)
	tier2.tier = 2
	tier2.level = 20
	var other := PrepareScreen.new()
	other.god = tier2
	other.setup(GodNight.def_for(tier2, MissionBook.FIRST_TASTE), PackedStringArray())
	t.check(String(other.brief_rows()[3][1]).begins_with("Tier 3: Wrath"), "IF WON names the tier above the god's (%s)" % other.brief_rows()[3][1])
	other.free()


## An ordinary night with stolen gifts shows GIFTS in place of CITY (Ruling P3-8); no gifts keep P2's six rows; the Hunt's rows are unchanged.
static func _prepare_gifts_row(t) -> void:
	var god := _fixture_god(t)
	god.gifts = PackedStringArray([RiteBook.WATCHFUL_BELL])
	var prep := PrepareScreen.new()
	prep.god = god
	prep.setup(GodNight.def_for(god, "warning"), PackedStringArray())
	var labels := []
	for row: Array in prep.brief_rows():
		labels.append(row[0])
	t.check(labels == ["TARGET", "WIN", "LOSE", "GIFTS", "LOADOUT", "TEMPLE"], "a gifted night: GIFTS replaces CITY (%s)" % [labels])
	t.check(String(prep.brief_rows()[3][1]) == "The bell takes 20% longer to ring", "its words are the gift's effect (%s)" % prep.brief_rows()[3][1])
	var hint_lines := UiTheme.wrap(prep.hint_text(), PrepareScreen.PANEL.size.x - 8.0, UiTheme.SIZE_SMALL).size()
	t.check(prep.brief_bottom() <= PrepareScreen.PANEL.end.y - 8.0 - UiTheme.LINE_SMALL * float(hint_lines), "and the rows still fit (%s)" % prep.brief_bottom())
	prep.free()
	god.gifts = PackedStringArray()
	var none := PrepareScreen.new()
	none.god = god
	none.setup(GodNight.def_for(god, "warning"), PackedStringArray())
	var none_labels := []
	for row: Array in none.brief_rows():
		none_labels.append(row[0])
	t.check(none_labels == ["TARGET", "WIN", "LOSE", "CITY", "LOADOUT", "TEMPLE"], "no gifts: P2's rows (%s)" % [none_labels])
	none.free()
	god.gifts = PackedStringArray([RiteBook.WATCHFUL_BELL])
	god.notice = 100
	var hunt := GodNight.hunt_for(god)
	var hunt_prep := PrepareScreen.new()
	hunt_prep.god = god
	hunt_prep.setup(GodNight.def_for(god, String(hunt.id)), PackedStringArray())
	var hunt_labels := []
	for row: Array in hunt_prep.brief_rows():
		hunt_labels.append(row[0])
	t.check(hunt_labels == ["HUNT", "WIN", "LOSE", "IF WON", "IF LOST"], "a Hunt with gifts keeps its five rows (%s)" % [hunt_labels])
	hunt_prep.free()
	var board := PrepareScreen.new()
	board.setup(TierBook.board("warning"), PackedStringArray())
	var board_labels := []
	for row: Array in board.brief_rows():
		board_labels.append(row[0])
	t.check(board_labels == ["TARGET", "WIN", "LOSE", "CITY", "LOADOUT", "TEMPLE"], "a board night has no GIFTS row (%s)" % [board_labels])
	board.free()


## A rite result as Game builds it: GodNight.bank()'s dictionary under `god`, the rules' goal row, the reason the rite ended on.
static func _rite_result(t, won: bool, shards := 3, notice := 0) -> Dictionary:
	var god := _rite_god(t, notice)
	var kept := god.draftable()
	var banked := GodNight.bank(god, MissionBook.FIRST_TASTE, kept, {"won": won, "reason": "shards" if won else "cleansed", "rite": {"shards": shards}})
	return {"mission": MissionBook.FIRST_TASTE, "won": won, "reason": "shards" if won else "cleansed", "time": 200.0,
		"goal": {"label": "Three Lantern shards", "done": won}, "bonuses": [], "best": false, "god": banked}


static func _god_lines_rite_won(t) -> void:
	var result := _rite_result(t, true)
	var lines := ResultsScreen.god_lines(result)
	var want := PackedStringArray(["Divine Power: none - the rite feeds no bar", "Tier 2: Omen", "+2 ability points",
		"Stolen: The Watchful Bell - a bell ringer takes 20% longer to start the toll", "Lantern Notice 0%", "Night 1"])
	t.check(lines == want, "a won rite's lines in MS §5's order (%s)" % [lines])
	t.check(not "\n".join(lines).contains("Believers") and not "\n".join(lines).contains("Faith"), "no believers or Faith line (MS §1 R1)")
	t.check(ResultsScreen.god_line_color(lines[1]) == UiTheme.COL_GOLD and ResultsScreen.god_line_color(lines[3]) == UiTheme.COL_GOLD
		and ResultsScreen.god_line_color(lines[2]) == UiTheme.COL_TEXT, "the tier and the gift are gold, the points plain")
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, UiTheme.width(line, UiTheme.SIZE_BODY))
	t.check(widest <= ResultsScreen.PANEL.size.x - 16.0, "every line fits the panel (%s of %s)" % [widest, ResultsScreen.PANEL.size.x])
	# G1: the goal row is ticked by the win, though a rite has no Descent.
	var rows := ResultsScreen.descend_rows(result)
	t.check(rows.size() == 1 and rows[0][0] == "Three Lantern shards" and rows[0][1] == "" and rows[0][2] == "ok",
		"the goal row of a won rite is ticked and pays no believers (%s)" % [rows])
	# Several lines fit above the buttons.
	var res := ResultsScreen.new().setup(result)
	t.check(res.endless and res.descend and _rows(res._menu) == ["continue", "tree", "faith"], "its results lead on with Continue / Skill Tree / Faith")
	res.free()
	# A seal that ran out and the Hunt next are still said.
	var banked: Dictionary = result.god
	banked["unsealed"] = GodTree.starting(_two_key_type(t))[0]
	banked["hunt_next"] = true
	var more := ResultsScreen.god_lines(result)
	t.check(more[more.size() - 3].ends_with("is no longer sealed") and more[more.size() - 2].begins_with("THE LANTERN HUNTS") and more[more.size() - 1] == "Night 1",
		"a seal that ended and the coming Hunt come before the night (%s)" % [more])


static func _god_lines_rite_lost(t) -> void:
	var result := _rite_result(t, false, 2)
	var lines := ResultsScreen.god_lines(result)
	var want := PackedStringArray(["Divine Power: none - the rite feeds no bar", "Lantern shards 2/3",
		"The god is still capped. Awaken again when ready.", "Lantern Notice 25%  (+25%)", "Night 1"])
	t.check(lines == want, "a lost rite's lines (%s)" % [lines])
	t.check(ResultsScreen.god_line_color(lines[2]) == UiTheme.COL_BAD and ResultsScreen.god_line_color(lines[3]) == UiTheme.COL_BAD
		and ResultsScreen.god_line_color(lines[1]) == UiTheme.COL_TEXT, "the capped line and the Notice rise are red, the shards plain")
	var rows := ResultsScreen.descend_rows(result)
	t.check(rows.size() == 1 and rows[0][1] == "" and rows[0][2] == "x", "the goal row of a lost rite is crossed (%s)" % [rows])
	# At the brink, the Hunt is named.
	var near := ResultsScreen.god_lines(_rite_result(t, false, 0, 90))
	t.check(near.has("Lantern Notice 100%  (+10%)") and near.has("THE LANTERN HUNTS: the next night is the Hunt"), "a lost rite that fills the meter names the Hunt (%s)" % [near])
	# G2: the rite's ending titles.
	t.check(ResultsScreen.title_for(true, "shards") == "THE RITE IS DONE" and ResultsScreen.title_for(false, "cleansed") == "THE SHRINE IS CLEANSED"
		and ResultsScreen.title_for(false, "dawn") == "DAWN COMES", "the rite's reasons have their own titles (%s, %s)" % [
			ResultsScreen.title_for(true, "shards"), ResultsScreen.title_for(false, "cleansed")])
	# Not a rite: the old lines and rows.
	var plain := ResultsScreen.god_lines(_god_result())
	t.check(plain[0] == "Divine Power +120" and ResultsScreen.rite_of(_god_result()).is_empty(), "an ordinary night is not a rite (%s)" % [plain])


static func _rite_called(t) -> void:
	var won := ResultsScreen.rite_called(_rite_result(t, true))
	t.check(won == "Awakening Rite: The First Taste  -  Whisper", "a won rite names the tier played, not the one crossed into (%s)" % won)
	var lost := ResultsScreen.rite_called(_rite_result(t, false, 1))
	t.check(lost == "Awakening Rite: The First Taste  -  Whisper", "a lost rite too (%s)" % lost)
	t.check(ResultsScreen.rite_called({"god": _g()}) == "" and ResultsScreen.rite_called({}) == "" and ResultsScreen.hunt_called(_rite_result(t, true)) == "",
		"a night, no god, or a rite for the Hunt's line: nothing")


static func _pause_rite(t) -> void:
	var cases := [{"notice": 0, "rise": 25, "hunt": false}, {"notice": 25, "rise": 25, "hunt": false}, {"notice": 80, "rise": 20, "hunt": true},
		{"notice": 100, "rise": 0, "hunt": true}]
	t.check(PauseMenu.CONFIRM_RITE == "Abandon the rite and it is lost: Lantern Notice +%d%%. The god stays capped.", "the rite's confirm copy")
	for c: Dictionary in cases:
		var pause := PauseMenu.new()
		pause.rite = true
		pause.notice = int(c.notice)
		pause.setup(false, Settings.new(), PATH, true, true)
		pause._on_gui_input(_click((pause._menu.rect_of("abandon") as Rect2).get_center()))
		var line := pause.confirm_line()
		t.check(line == PauseMenu.rite_line(int(c.notice)) and line.begins_with("Abandon the rite and it is lost"), "notice %d: the rite's confirm (%s)" % [c.notice, line])
		if int(c.rise) > 0:
			t.check(line.contains("Lantern Notice +%d%%" % int(c.rise)), "notice %d: it states the real rise +%d%% (%s)" % [c.notice, c.rise, line])
		else:
			t.check(line.contains("already 100%") and not line.contains("+"), "notice 100: no rise is promised (%s)" % line)
		t.check(line.contains("The god stays capped"), "notice %d: it says the god stays capped" % c.notice)
		t.check(line.contains("The Lantern Hunts next") == bool(c.hunt), "notice %d: the Hunt is named only when it comes (%s)" % [c.notice, line])
		var lines := UiTheme.wrap(line, PauseMenu.CONFIRM_WIDTH, UiTheme.SIZE_BODY)
		var row := pause._menu.rect_of("abandon") as Rect2
		t.check(lines.size() <= 3 and row.position.y > PauseMenu.CONFIRM_Y + UiTheme.LINE_BODY * float(lines.size() - 1) + 3.0 and row.end.y < 360.0,
			"notice %d: it takes %d lines and the buttons sit under them" % [c.notice, lines.size()])
		pause.free()
	var free := PauseMenu.new()
	free.rite = true
	free.notice = 25
	free.setup(false, Settings.new(), PATH, true, false)
	free._on_gui_input(_click((free._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(free.confirm_line() == PauseMenu.CONFIRM_FREE, "before the clock starts leaving the rite is free (%s)" % free.confirm_line())
	free.free()
	var plain := PauseMenu.new()
	plain.notice = 25
	plain.setup(false, Settings.new(), PATH, true, true)
	plain._on_gui_input(_click((plain._menu.rect_of("abandon") as Rect2).get_center()))
	t.check(plain.confirm_line() == PauseMenu.lost_line(25), "a night that is not a rite keeps P2's confirm (%s)" % plain.confirm_line())
	plain.free()
