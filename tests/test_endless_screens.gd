extends RefCounted
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
	_bar_animation(t)
	_pause_endless(t)
	_prepare_god(t)
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
	var capped := {"god": {"divine_power": 80, "levels": PackedInt32Array(), "capped": true, "believers": 0, "faith": 0,
		"faith_total": 7, "notice": 25, "night": 4}}
	var c := ResultsScreen.god_lines(capped)
	t.check(c[0] == "Divine Power +80   AWAKEN TO GROW", "a capped god is told to awaken (%s)" % [c[0]])
	t.check(c.size() == 4 and c[1] == "Believers 0   Faith +0, 7 now" and c[2] == "Lantern Notice 25%" and c[3] == "Night 4",
		"no level lines when no level was gained (%s)" % [c])
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
		and PauseMenu.CONFIRM_LOST == "Abandon now and the night is lost: no Divine Power, no Faith.",
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
