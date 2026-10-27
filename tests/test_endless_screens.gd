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
	_interlude_endless(t)
	_refuse_and_card_cost(t)
	GodTree.dev_fill = false
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
		"the interlude at 95 says +5% and the Hunt (%s)" % card95.confirm_line())
	card95.free()
