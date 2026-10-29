extends RefCounted
## v0.11 M1 the tier board (spec §3.1), a test mode since god P1 (spec §3, ruling C3): five tabs and the cards of the open one fit
## the screen; a fresh board opens on Whisper with every tier open (no rule, any mission can be picked); the test header and no Upgrades
## button; a card's best; the board's draft refuses no power (Draft.locked is still a mechanism); Prepare for a board mission has no
## difficulty picker.


static func run(t) -> void:
	City.use(&"aldermere")
	City.register(FixtureCity.ID, FixtureCity.new())
	_dev(t)
	_dev_town(t)
	_dev_card_fits(t)
	_dev_night_banks_nothing(t)
	_reopen(t)
	City.unregister(FixtureCity.ID)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity and not City.has(FixtureCity.ID), "the board test leaves Aldermere active and the fixture gone")
	_layout(t)
	_tabs(t)
	_best(t)
	_draft(t)


static func _layout(t) -> void:
	var bad := 0
	for i in 5:
		var r := MissionBoard.tab_rect(i)
		if not Rect2(0, 0, 640, 360).encloses(r) or r.position.y >= MissionBoard.CARD_TOP:
			bad += 100
		for j in range(i + 1, 5):
			if r.intersects(MissionBoard.tab_rect(j)):
				bad += 1
	t.check(bad == 0, "the five tabs fit above the cards without touching (%d)" % bad)
	for count in [4, 5]:
		var over := 0
		for i in count:
			var r := MissionBoard.card_rect(i, count)
			if not Rect2(0, 0, 640, 310).encloses(r):
				over += 100
			for j in range(i + 1, count):
				if r.intersects(MissionBoard.card_rect(j, count)):
					over += 1
		t.check(over == 0, "%d cards fit the screen without touching (%d)" % [count, over])


static func _tabs(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new().setup(save, "warning")
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	t.check(board.tier == 1 and Array(board.missions()) == ["warning", "tax_collector", "spoiled_harvest", "lost_lamb", "first_prayers"]
		and board.lock_line() == "" and board.header_text() == MissionBoard.TEST_HEADER,
		"a fresh board: Whisper's five, the test header (%s)" % board.header_text())
	board.open_tab(2)
	t.check(board.tier == 2 and board.lock_line() == "", "Omen is open on a fresh save: no rule")
	board.choose("miras_house")
	t.check(picked == ["pick"] and board.chosen == "miras_house" and board.tier == 2, "and its mission can be picked (test mode: no tier is locked)")
	board.choose("warning")
	t.check(picked == ["pick", "pick"] and board.chosen == "warning" and board.tier == 1, "so can a Whisper one")
	board.choose("broken_lanterns")
	t.check(board.chosen == "broken_lanterns" and board.lock_line() == "", "and an Omen one")
	var u := InputEventKey.new()
	u.physical_keycode = KEY_U
	u.pressed = true
	board._unhandled_input(u)
	t.check(picked.size() == 3 and picked.back() == "pick", "U asks for nothing: there are no Upgrades on the board (%s)" % [picked])
	t.check(board.hit(MissionBoard.UPGRADES_RECT.get_center()) == "" and board.hit(MissionBoard.tab_rect(2).get_center()) == "tab:3"
		and board.hit(MissionBoard.card_rect(0, 5).get_center()) == "card:0", "what is under the mouse: no Upgrades button")
	board.free()
	var back := MissionBoard.new().setup(save, "broken_lanterns")
	t.check(back.tier == 2 and back.selected == 1, "it opens on the mission last picked (its tier is open on a fresh save)")
	back.free()
	var shut := MissionBoard.new().setup(SaveFile.new(), "festival")
	t.check(shut.tier == TierBook.tier_of("festival") and shut.tier > 1 and shut.selected == TierBook.missions(shut.tier).find("festival"),
		"and on a high tier's mission even on a fresh save (tier %d)" % shut.tier)
	shut.free()


static func _best(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new().setup(save, "warning")
	t.check(board.best_line("warning") == "Not yet cleared", "never cleared")
	save.descend.cleared.append("warning")
	t.check(board.best_line("warning") == "Cleared", "cleared, no best yet")
	save.descend.fastest["warning"] = 192.0
	save.descend.most_wishes["warning"] = 2
	t.check(board.best_line("warning") == "Cleared  best 3:12  wishes 2", "its fastest and most wishes (%s)" % board.best_line("warning"))
	# A best line wraps between its parts, never inside one, and keeps its double spaces (v0.11 M2, Task 8): on a card with room
	# it is the one line; on a Whisper card (95 px) "Cleared  best 3:12" fills a line and "wishes 2" has the next.
	t.check(Array(board.best_lines("warning", 300.0)) == ["Cleared  best 3:12  wishes 2"],
		"room enough: one line, the double spaces kept (%s)" % [board.best_lines("warning", 300.0)])
	var narrow := board.best_lines("warning", 95.0)
	t.check(Array(narrow) == ["Cleared  best 3:12", "wishes 2"] and "  ".join(narrow) == board.best_line("warning"),
		"95 px: it breaks after a part, so no part is split (%s)" % [narrow])
	t.check(Array(board.best_lines("tax_collector", 95.0)) == ["Not yet cleared"], "a card never cleared is its one line")
	board.free()


static func _draft(t) -> void:
	# Draft.locked stays a mechanism (a later mode may use it): Last Judgement's pool is every power, so the lock is what refuses
	# (The Warning's pool would refuse first).
	var d := Draft.new().for_mission(TierBook.board("last_judgement"))
	d.locked = PackedStringArray(["tsunami", "nova"])
	t.check(d.refusal("tsunami") == "locked" and d.toggle("tsunami") == "locked" and d.refusal("doom") == "", "a locked power is refused")
	d.preselect(PackedStringArray(["tsunami", "doom"]))
	t.check(d.picks == PackedStringArray(["doom"]), "and left out of a saved loadout")
	# The board is a test mode (god P1, C3): its Prepare is opened with no locked power, so every card is open.
	var save := SaveFile.new()
	var prep := PrepareScreen.new().setup(Game.board_def("warning"), PackedStringArray(), ResponseProfile.DEFAULT,
		Game.board_locked_for(save, "warning"))
	t.check(prep.draft.locked.is_empty() and prep.draft.refusal("tsunami") == "" and prep.draft.refusal("nova") == ""
		and prep.budget_text() == "0 / 3 slots   0 / 6 Might"
		and prep.hit(PrepareScreen.arrow_rect(-1).get_center()) == "" and not prep.mission.chooses_difficulty(),
		"the board's Prepare: Tier 1's budget, no power locked, no difficulty picker")
	t.check(String(PrepareScreen.REFUSALS["locked"]) == "Locked: unlock it on the Upgrades screen",
		"and Draft.locked, were it used, still says why it refuses one")
	prep.free()


## The dev entry (Task 15): with --dev a DEV tab holds the dev-only missions (MissionBook.dev_missions(), the capital's
## sandbox), always open and pickable; without it the board shows only the tiers.
static func _dev(t) -> void:
	var save := SaveFile.new()
	var plain := MissionBoard.new().setup(save, "warning")
	var shown := false
	for tier in range(1, TierBook.NAMES.size() + 2):
		plain.tier = tier
		shown = shown or plain.missions().has(MissionBook.CAPITAL_SANDBOX)
	t.check(not shown and plain.hit(MissionBoard.dev_rect().get_center()) == "", "without --dev the board has no dev entry")
	# Nor do its keys reach the DEV tab: D, Tab both ways round every tab, 1-5, or asking for it outright.
	plain.open_tab(1)
	var reached := plain.tier == MissionBoard.DEV_TIER
	var keys := [KEY_D]
	for i in TierBook.NAMES.size() + 2:
		keys.append(KEY_TAB)
	for i in TierBook.NAMES.size() + 2:
		keys.append(-KEY_TAB)
	keys.append_array([KEY_1, KEY_2, KEY_3, KEY_4, KEY_5])
	for k: int in keys:
		var e := InputEventKey.new()
		e.physical_keycode = absi(k) as Key
		e.shift_pressed = k < 0
		e.pressed = true
		plain._unhandled_input(e)
		reached = reached or plain.tier == MissionBoard.DEV_TIER
	plain.open_tab(MissionBoard.DEV_TIER)
	reached = reached or plain.tier == MissionBoard.DEV_TIER
	t.check(not reached, "without --dev, D, Tab and 1-5 never open the DEV tab")
	plain.free()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "warning")
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	t.check(board.hit(MissionBoard.dev_rect().get_center()) == "tab:%d" % MissionBoard.DEV_TIER, "with --dev, a DEV tab")
	board.open_tab(MissionBoard.DEV_TIER)
	# v0.12: the sandbox, then the Capital's hostable missions (none until its overrides files exist).
	var listed: Array = [MissionBook.CAPITAL_SANDBOX]
	listed.append_array(Array(MissionBook.town_missions(&"capital")))
	t.check(board.tier == MissionBoard.DEV_TIER and Array(board.missions()).slice(0, listed.size()) == listed
		and board.lock_line() == "", "the DEV tab lists the capital's sandbox, open (%s)" % [board.missions()])
	# v0.12 M2: the five Capital Tier 1 nights are real (no fixture), in tier order, as composite ids.
	var five := ["warning@capital", "tax_collector@capital", "spoiled_harvest@capital", "lost_lamb@capital", "first_prayers@capital"]
	var tier1 := Array(board.missions()).slice(1, 1 + five.size())
	t.check(tier1 == five and Array(MissionBook.town_missions(&"capital")).slice(0, five.size()) == five,
		"the DEV tab lists the five Capital Tier 1 nights in tier order (%s)" % [board.missions()])
	var real := true
	for id in five:
		var def: MissionDef = board._defs.get(id)
		real = real and def != null and def.city == &"capital" and MissionBook.hostable(String(MissionBook.split_city(id)[0]), City.by_id(&"capital"))
	t.check(real, "each is built in the Capital and hostable there on its own overrides file")
	board.choose(MissionBook.CAPITAL_SANDBOX)
	t.check(picked == ["pick"] and board.chosen == MissionBook.CAPITAL_SANDBOX, "and it can be picked")
	var on_dev := MissionBoard.new()
	on_dev.dev = true
	on_dev.setup(save, MissionBook.CAPITAL_SANDBOX)
	t.check(on_dev.tier == MissionBoard.DEV_TIER, "the board reopens on the DEV tab after a sandbox night")
	on_dev.free()
	board.free()


## v0.12 (spec 1.7): after the sandbox the DEV tab lists every town's hostable missions but Aldermere's, as composite ids; the fixture
## town (registered by run()) adds its one. Their cards show the mission's name, the town, the type; no brief.
static func _dev_town(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "warning")
	var want: Array = [MissionBook.CAPITAL_SANDBOX]
	want.append_array(Array(MissionBook.town_missions(&"capital")))
	want.append_array(["tax_collector@fixture"])
	# God P3 (preflight B4, Ruling P3-7): the Awaken rites come last, after the towns' missions.
	want.append_array([MissionBook.FIRST_TASTE])
	t.check(Array(board._missions_of(MissionBoard.DEV_TIER)) == want, "the DEV tab lists the sandbox, the Capital's missions, the fixture town's, then the rites (%s)" % [board._missions_of(MissionBoard.DEV_TIER)])
	t.check(not Array(board._missions_of(MissionBoard.DEV_TIER)).any(func(id: String) -> bool: return id.ends_with("@aldermere")),
		"Aldermere lists nothing of its own on the DEV tab")
	board.open_tab(MissionBoard.DEV_TIER)
	var composite := "tax_collector@fixture"
	t.check(board._defs.has(composite) and (board._defs[composite] as MissionDef).city == FixtureCity.ID, "a town mission's def is built in its town")
	t.check(board.brief_lines(composite, 74.0).is_empty(), "a town mission's card has no brief")
	t.check(Array(board.kind_lines(composite)) == ["FIXTURE", TierBook.type_of("tax_collector").to_upper()], "its card names the town, then the type (%s)" % [board.kind_lines(composite)])
	t.check(Array(board.kind_lines(MissionBook.CAPITAL_SANDBOX)) == ["DEV SANDBOX"], "the sandbox's card stays as merged")
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	board.choose(composite)
	t.check(picked == ["pick"] and board.chosen == composite and board.tier == MissionBoard.DEV_TIER, "a town mission is picked like any board pick")
	board.free()
	var plain := MissionBoard.new().setup(save, "warning")
	t.check(not Array(plain._missions_of(MissionBoard.DEV_TIER)).has(composite) and plain._missions_of(MissionBoard.DEV_TIER).is_empty(),
		"without --dev no town mission shows")
	plain.free()


## Six cards share the 640 px board, 94 px wide: every text line of a town mission's card fits it, for each Tier 1 mission.
static func _dev_card_fits(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "warning")
	board.tier = MissionBoard.DEV_TIER
	var r := MissionBoard.card_rect(0, 6)
	var room := r.size.x - 2.0 * MissionBoard.PAD
	var wide := []
	# Tier 1's five are the ones a town can host in v0.12 (the sandbox and they make the six cards); later tiers' longer names
	# (Bell-Ringers, Procession...) would wrap at this width and are not hostable anywhere.
	for id in TierBook.missions(1):
		var composite := MissionBook.city_id(id, &"capital")
		board._defs[composite] = Mission.def_for(composite, true, save.descend)
		for line in UiTheme.wrap((board._defs[composite] as MissionDef).name, room - 12.0, UiTheme.SIZE_BIG):
			if UiTheme.width(line, UiTheme.SIZE_BIG) > room:
				wide.append("%s: %s" % [composite, line])
		for line in board.best_lines(composite, room):
			if UiTheme.width(line, UiTheme.SIZE_SMALL) > room:
				wide.append("%s: %s" % [composite, line])
		for line in board.kind_lines(composite):
			if UiTheme.width(line, UiTheme.SIZE_SMALL) > room:
				wide.append("%s: %s" % [composite, line])
		if board.brief_bottom(composite, r) > board.brief_top(composite, r) + 3.0:
			wide.append("%s has a brief" % composite)
		if board.brief_top(composite, r) >= MissionBoard.rule_y(r, 2):
			wide.append("%s: the type lines reach the rule" % composite)
	t.check(wide.is_empty(), "every line of a town card fits six cards (%s)" % [wide])
	# A cleared card's best, too: a wide time and wishes.
	save.descend.cleared.append("tax_collector@capital")
	save.descend.fastest["tax_collector@capital"] = 612.0
	save.descend.most_wishes["tax_collector@capital"] = 3
	var best_wide := false
	for line in board.best_lines("tax_collector@capital", room):
		best_wide = best_wide or UiTheme.width(line, UiTheme.SIZE_SMALL) > room
	t.check(not best_wide, "a cleared town card's best fits (%s)" % [board.best_lines("tax_collector@capital", room)])
	board.free()


## A town night banks nothing (D20): the tier board's night, believers and cleared are unchanged, even for a result carrying a Descent
## bank; the save keeps the best under the composite id. A board night banks as ever. Game.bank_night is the handler's body, so no save is
## written and no screen is built.
static func _dev_night_banks_nothing(t) -> void:
	var save := SaveFile.new()
	var id := "tax_collector@capital"
	var night := save.descend.night
	var believers := save.descend.believers
	var cleared := save.descend.cleared.size()
	var outcome := {"won": true, "reason": "tax", "descend": {"ascended": true, "believers": 40, "progress": ""}}
	Game.bank_night(save, id, PackedStringArray(), outcome, false)
	t.check(save.descend.night == night and save.descend.believers == believers and save.descend.cleared.size() == cleared
		and not save.descend.cleared.has(id), "a town night leaves the tier board's night, believers and cleared alone")
	t.check(not (outcome.descend as Dictionary).has("bank") and bool(save.best(id).won) and not save.best("tax_collector").won,
		"the save's entry for the composite id is won; the board's own is not")
	var plain := {"won": true, "descend": {"ascended": false, "believers": 10, "progress": ""}}
	Game.bank_night(save, "tax_collector", PackedStringArray(), plain, false)
	t.check((plain.descend as Dictionary).has("bank") and save.descend.night == night + 1, "a board night banks as before")


## The board reopens on the DEV tab after a town night (Results go back to it).
static func _reopen(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "tax_collector@fixture")
	t.check(board.tier == MissionBoard.DEV_TIER and board.missions()[board.selected] == "tax_collector@fixture",
		"the board reopens on the DEV tab, on the town mission just played")
	board.free()
	var plain := MissionBoard.new().setup(save, "tax_collector@fixture")
	t.check(plain.tier != MissionBoard.DEV_TIER, "without --dev a town mission's id opens no DEV tab")
	plain.free()
