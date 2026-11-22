extends RefCounted
## The board as a test mode (god P1, spec §3, rulings C3, P11, P13, C14, pre-flight G1 and R7): all five tiers open with no padlock, no
## Upgrades button, no locked power, TierBook's slots and Might and no upgrades, a night banks no believers and opens no tier (it keeps
## its cleared tick and bests), the results lead to Board, Again and Change powers, and Prepare's level picker steps a slot's power
## through levels 1 to 5, refused when the Might would go over.

## A board night's outcome, as Descent.report() gives it: the main objective done at 190 s, 25 believers earned, two wishes kept.
static func _outcome() -> Dictionary:
	return {"won": true, "descend": {"main": true, "main_time": 190.0, "earned": 25, "kept": 2}}


static func run(t) -> void:
	_all_open(t)
	_no_upgrades(t)
	_no_locks(t)
	_tier_budget(t)
	_bank_test(t)
	_results(t)
	_level_picker(t)
	_picker_off(t)
	_picker_layout(t)
	_unpick_clears(t)
	_levels_carried(t)
	_dev_tab_rite(t)
	_dev_tab_hunts(t)
	_dev_tab_paging(t)


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	return e


static func _all_open(t) -> void:
	var board := MissionBoard.new().setup(SaveFile.new(), "warning")
	var open := true
	for tier in range(1, 6):
		board.open_tab(tier)
		open = open and board.tier == tier and board.lock_line() == "" and board.missions().size() > 0
	t.check(open, "a fresh board: all five tiers open with no rule line")
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	board.choose("heart_of_faith")
	t.check(picked == ["pick"] and board.chosen == "heart_of_faith" and board.tier == 5,
		"and a Tier 5 mission can be picked on a fresh save (%s, %d)" % [picked, board.tier])
	board.free()


static func _no_upgrades(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new().setup(save, "warning")
	var seen := []
	board.action.connect(func(what: String) -> void: seen.append(what))
	t.check(board.hit(MissionBoard.UPGRADES_RECT.get_center()) != "upgrades", "no Upgrades button to hit (%s)" % board.hit(
		MissionBoard.UPGRADES_RECT.get_center()))
	board._unhandled_input(_key(KEY_U))
	t.check(seen.is_empty(), "U does nothing (%s)" % [seen])
	t.check(board.header_text() == MissionBoard.TEST_HEADER and MissionBoard.TEST_HEADER == "TEST MODE: every tier, mission and power open",
		"the header says test mode, not the night or the believers (%s)" % board.header_text())
	save.descend.night = 7
	save.descend.believers = 99
	t.check(board.header_text() == MissionBoard.TEST_HEADER, "whatever the save holds")
	t.check(MissionBoard.HINT == "Left and Right: missions   Tab or number keys: tiers   Enter: prepare   Esc: title",
		"the hint lists no Upgrades key (%s)" % MissionBoard.HINT)
	# The cards keep their ticks and bests.
	save.descend.cleared.append("warning")
	save.descend.fastest["warning"] = 190.0
	save.descend.most_wishes["warning"] = 2
	t.check(board.best_line("warning") == "Cleared  best 3:10  wishes 2", "a card keeps its tick and its bests (%s)" % board.best_line("warning"))
	board.free()


static func _no_locks(t) -> void:
	t.check(Game.locked_for(SaveFile.new(), false).is_empty() and Game.locked_for(SaveFile.new(), true).is_empty(),
		"no power is locked on the board or in the campaign")
	t.check(Game.board_locked_for(SaveFile.new(), "warning").is_empty() and Game.board_locked_for(SaveFile.new(), MissionBook.CAPITAL_SANDBOX).is_empty()
		and Game.board_locked_for(SaveFile.new(), "feast_festival").is_empty(), "nor for any mission picked outside the campaign")


static func _tier_budget(t) -> void:
	var w := Game.board_def("warning")
	var lj := Game.board_def("last_judgement")
	t.check(w.slots == 3 and w.dp_capacity == 6, "The Warning on the board: 3 slots, 6 Might (%d, %d)" % [w.slots, w.dp_capacity])
	t.check(lj.slots == 6 and lj.dp_capacity == 16, "Last Judgement: 6 slots, 16 Might (%d, %d)" % [lj.slots, lj.dp_capacity])
	# It takes no state: a god's bought Might and slot change nothing.
	var s := DescendState.new()
	s.dp_bought = 3
	s.slot_bought = 1
	t.check(Game.board_def("warning").dp_capacity == 6 and Game.board_def("warning").slots == 3 and TierBook.board("warning", s).dp_capacity == 9,
		"a save's upgrades do not reach board_def (the old call would give %d)" % TierBook.board("warning", s).dp_capacity)


static func _bank_test(t) -> void:
	var save := SaveFile.new()
	var out := _outcome()
	Game.bank_night(save, "warning", PackedStringArray(["smite"]), out, false)
	var bank: Dictionary = (out.descend as Dictionary).bank
	t.check(save.descend.believers == 0 and save.descend.night == 1 and save.descend.cleared.has("warning")
		and int(save.descend.most_wishes.get("warning", 0)) == 2 and is_equal_approx(float(save.descend.fastest.get("warning", 0.0)), 190.0),
		"a board night banks no believers; the night, the cleared tick and the bests are kept (%d, %d)" % [save.descend.believers, save.descend.night])
	t.check(bool(bank.get("test", false)) and int(bank.night) == 1 and bool(bank.cleared) and bool(bank.first_clear)
		and not bank.has("believers") and Array(bank.bests).size() == 2 and out.best == false,
		"the bank reports a test night (%s)" % [bank])
	t.check(save.descend.open_tier == 1, "and no tier opens by it")
	# Three more clears, still nothing opened, nothing paid.
	for id in ["tax_collector", "spoiled_harvest", "lost_lamb"]:
		Game.bank_night(save, id, PackedStringArray(["smite"]), _outcome(), false)
	t.check(save.descend.open_tier == 1 and save.descend.believers == 0 and save.descend.night == 4 and save.descend.cleared_in(1) == 4,
		"four clears of Whisper open nothing and pay nothing (open %d, believers %d)" % [save.descend.open_tier, save.descend.believers])
	# A second, slower, narrower clear changes no best and is not a first clear.
	var slow := {"won": true, "descend": {"main": true, "main_time": 250.0, "earned": 25, "kept": 1}}
	Game.bank_night(save, "warning", PackedStringArray(["smite"]), slow, false)
	var again: Dictionary = (slow.descend as Dictionary).bank
	t.check(bool(again.test) and not bool(again.first_clear) and Array(again.bests).is_empty()
		and is_equal_approx(float(save.descend.fastest["warning"]), 190.0) and int(save.descend.most_wishes["warning"]) == 2,
		"a worse night beats no best (%s)" % [again])
	# A lost night counts the night and clears nothing.
	var lost := {"won": false, "descend": {"main": false, "earned": 0, "kept": 0}}
	var before := save.descend.night
	Game.bank_night(save, "bell_ringers", PackedStringArray(["smite"]), lost, false)
	t.check(save.descend.night == before + 1 and not save.descend.cleared.has("bell_ringers") and not bool((lost.descend as Dictionary).bank.cleared),
		"a lost night counts and clears nothing")
	# The old bank() is unchanged for Endless Night and the like: believers and tiers.
	var s := DescendState.new()
	var b := s.bank("warning", {"main": true, "main_time": 100.0, "earned": 10, "kept": 1})
	t.check(s.believers == 10 and int(b.believers) == 10 and b.has("progress") and not b.has("test"), "bank() still banks believers (%s)" % [b])


static func _results(t) -> void:
	var save := SaveFile.new()
	var out := _outcome()
	Game.bank_night(save, "warning", PackedStringArray(["smite"]), out, false)
	var screen := ResultsScreen.new().setup(out)
	var actions: Array = []
	var labels: Array = []
	for item: Dictionary in screen._menu.items:
		actions.append(item.action)
		labels.append(item.label)
	t.check(actions == ["missions", "replay", "change"] and labels == ["Board", "Again", "Change powers"],
		"a board night's results lead to Board, Again and Change powers (%s, %s)" % [actions, labels])
	var lines := ResultsScreen.summary_lines(out)
	t.check(lines[0] == "Test mode: nothing banked" and Array(lines) == ["Test mode: nothing banked", "New best: Fastest clear 3:10",
		"New best: Most wishes granted: 2"], "the lines say nothing was banked, then each best (%s)" % [lines])
	t.check(Game.next_screen("results:change") == Game.Screen.PREPARE and Game.next_screen("results:replay") == Game.Screen.MISSION
		and Game.next_screen("results:missions") == Game.Screen.BOARD, "and each button has a screen")
	var emitted: Array = []
	screen.action.connect(func(what: String) -> void: emitted.append(what))
	for a in ["missions", "replay", "change"]:
		screen._on_gui_input(_click(screen._menu.rect_of(a).get_center()))
	t.check(emitted == ["missions", "replay", "change"], "and each button clicks (%s)" % [emitted])
	screen.free()


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _level_picker(t) -> void:
	var prep := PrepareScreen.new()
	prep.level_picker = true
	prep.setup(TierBook.board("warning"), PackedStringArray(["smite", "tornado"]))
	t.check(prep.draft.capacity == 6 and prep.draft.slots == 3 and prep.draft.levels.is_empty(), "the picker opens at level 1 (%s)" % [prep.draft.levels])
	var badge := PrepareScreen.level_rect(1, 3)
	t.check(prep.hit(badge.get_center()) == "level:1" and prep.hit(PrepareScreen.level_rect(0, 3).get_center()) == "level:0",
		"a filled slot's badge is a hit of its own (%s)" % prep.hit(badge.get_center()))
	for i in 4:
		prep.click(badge.get_center())
	t.check(prep.draft.levels.get("tornado") == 5 and prep.draft.spent() == 6 and prep.draft.picks == PackedStringArray(["smite", "tornado"]),
		"four clicks take Tornado to level 5 for 5 Might, 6 spent, and the badge keeps both picks (%s, %d)" % [prep.draft.levels, prep.draft.spent()])
	t.check(prep.budget_text() == "2 / 3 slots   6 / 6 Might", "the budget counts the level (%s)" % prep.budget_text())
	var smite := PrepareScreen.level_rect(0, 3)
	prep.click(smite.get_center())
	t.check(prep.draft.level_of("smite") == 2 and prep.refused_reason == "", "Smite to level 2 fits (no Might change)")
	prep.click(smite.get_center())
	t.check(prep.draft.level_of("smite") == 2 and prep.refused_reason == "Not enough Might",
		"level 3 would go over: refused with the pick's reason ('%s')" % prep.refused_reason)
	prep.click(badge.get_center())
	t.check(prep.draft.level_of("tornado") == 1 and not prep.draft.levels.has("tornado"), "level 5 wraps to 1")
	prep.click(smite.get_center())
	t.check(prep.draft.level_of("smite") == 3 and prep.draft.spent() == 5, "and now Smite's level 3 fits (%d)" % prep.draft.spent())
	# Pre-flight R7: the badge raises a level; the rest of the slot still gives the pick back.
	var slot0 := PrepareScreen.slot_rect(0, 3)
	t.check(prep.hit(Vector2(slot0.position.x + 3.0, slot0.get_center().y)) == "slot:0", "the rest of the slot is still the slot (%s)" % prep.hit(
		Vector2(slot0.position.x + 3.0, slot0.get_center().y)))
	prep.click(Vector2(slot0.position.x + 3.0, slot0.get_center().y))
	t.check(prep.draft.picks == PackedStringArray(["tornado"]), "and a click on it takes the pick out (%s)" % [prep.draft.picks])
	prep.free()


static func _picker_off(t) -> void:
	var prep := PrepareScreen.new()
	prep.setup(TierBook.board("warning"), PackedStringArray(["smite", "tornado"]))
	var at := PrepareScreen.level_rect(0, 3).get_center()
	t.check(not prep.hit(at).begins_with("level:") and prep.hit(at) == "slot:0", "picker off: the badge's place is the slot (%s)" % prep.hit(at))
	prep.click(PrepareScreen.level_rect(1, 3).get_center())
	t.check(prep.draft.levels.is_empty() and prep.draft.picks == PackedStringArray(["smite"]),
		"a click there gives the pick back and sets no level (%s, %s)" % [prep.draft.levels, prep.draft.picks])
	prep.free()


static func _picker_layout(t) -> void:
	var bad := 0
	for count in range(1, 7):
		for i in count:
			var slot := PrepareScreen.slot_rect(i, count)
			var badge := PrepareScreen.level_rect(i, count)
			if not slot.encloses(badge) or badge.size != PrepareScreen.LEVEL_BADGE or badge.end.x < slot.end.x - 4.0:
				bad += 1
			# It leaves the icon (24 px from the slot's left, 2 px in) and the digit alone.
			if badge.position.x < slot.position.x + 28.0:
				bad += 10
	t.check(bad == 0, "the badge sits inside the slot at its top right, clear of the icon, for 1-6 slots (%d)" % bad)
	t.check(UiTheme.width("L5", UiTheme.SIZE_SMALL) <= PrepareScreen.LEVEL_BADGE.x,
		"\"L5\" fits the badge (%.1f of %.1f px)" % [UiTheme.width("L5", UiTheme.SIZE_SMALL), PrepareScreen.LEVEL_BADGE.x])


## Ruling C14: giving a power back clears its level.
static func _unpick_clears(t) -> void:
	var d := Draft.new()
	d.slots = 3
	d.capacity = 10
	d.toggle("smite")
	d.toggle("tornado")
	d.set_level("tornado", 4)
	t.check(d.level_of("tornado") == 4 and d.spent() == 1 + 4, "Tornado at level 4 costs 4 (%d)" % d.spent())
	d.toggle("tornado")
	t.check(not d.levels.has("tornado") and d.level_of("tornado") == 1, "unpicked: the level is gone")
	d.toggle("tornado")
	t.check(d.level_of("tornado") == 1 and d.spent() == 1 + 3, "and a re-pick starts at level 1 (%d)" % d.spent())


## Pre-flight G1: the levels chosen come back into Prepare (Change powers, the between-acts re-draft), and a level for a power that is
## not in the loadout is dropped.
static func _levels_carried(t) -> void:
	var prep := PrepareScreen.new()
	prep.level_picker = true
	prep.levels = {"tornado": 5, "smite": 2, "doom": 4}
	prep.setup(TierBook.board("warning"), PackedStringArray(["smite", "tornado"]))
	t.check(prep.draft.levels == {"tornado": 5, "smite": 2} and prep.draft.spent() == 6,
		"Prepare opens on the levels chosen before; a level for an unpicked power is dropped (%s)" % [prep.draft.levels])
	prep.levels["smite"] = 9
	t.check(prep.draft.levels["smite"] == 2, "and its draft holds a copy")
	prep.free()
	# A level that no longer fits drops its pick, as any over-Might preselect does.
	var over := PrepareScreen.new()
	over.level_picker = true
	over.levels = {"tornado": 5}
	over.setup(TierBook.board("warning"), PackedStringArray(["smite", "tornado", "doom", "ember"]))
	t.check(over.draft.spent() <= over.draft.capacity, "levels never take a draft over its Might (%d)" % over.draft.spent())
	over.free()


## God P3 (MS §1 R6, Ruling P3-7, preflight B4): with --dev the DEV tab ends with the Awaken rite, titled "The First Taste (rite)", kind line
## RITE and no brief; without --dev it is nowhere on the board; the Capital's ids still come first; the card fits however many cards the tab holds.
static func _dev_tab_rite(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "warning")
	board.open_tab(MissionBoard.DEV_TIER)
	var ids := board.missions()
	t.check(ids.size() >= 2 and ids[ids.size() - 1] == MissionBook.FIRST_TASTE, "first_taste is last on the DEV tab (%s)" % [ids])
	var capital := Array(MissionBook.town_missions(&"capital"))
	t.check(Array(ids).slice(0, 1 + capital.size()) == [MissionBook.CAPITAL_SANDBOX] + capital,
		"the sandbox and the Capital's ids still come first (%s)" % [ids])
	t.check(board.card_title(MissionBook.FIRST_TASTE) == "The First Taste (rite)", "its title (%s)" % board.card_title(MissionBook.FIRST_TASTE))
	t.check(Array(board.kind_lines(MissionBook.FIRST_TASTE)) == ["RITE"], "its kind line (%s)" % [board.kind_lines(MissionBook.FIRST_TASTE)])
	t.check(board.brief_lines(MissionBook.FIRST_TASTE, 60.0).is_empty(), "it shows no brief")
	t.check(board.card_title("warning") == TierBook.board("warning").name and board.card_title(MissionBook.CAPITAL_SANDBOX) == MissionBook.capital_sandbox().name,
		"other cards keep their names")
	# It fits the card: every wrapped title line, the kind line and the best are inside the card, and the type lines clear the rule.
	var r := MissionBoard.card_rect(0, mini(ids.size(), MissionBoard.DEV_PAGE))
	var room := r.size.x - 2.0 * MissionBoard.PAD
	var wide := []
	# (No tick sits at the title's right: a rite is never "cleared", so the whole room is the title's.)
	for line in UiTheme.wrap(board.card_title(MissionBook.FIRST_TASTE), room, UiTheme.SIZE_BIG):
		if UiTheme.width(line, UiTheme.SIZE_BIG) > room:
			wide.append("%s (%s px of %s)" % [line, UiTheme.width(line, UiTheme.SIZE_BIG), room])
	for line in board.best_lines(MissionBook.FIRST_TASTE, room):
		if UiTheme.width(line, UiTheme.SIZE_SMALL) > room:
			wide.append(line)
	for line in board.kind_lines(MissionBook.FIRST_TASTE):
		if UiTheme.width(line, UiTheme.SIZE_SMALL) > room:
			wide.append(line)
	t.check(wide.is_empty(), "every line of the rite's card fits the %d cards of a page (%s)" % [mini(ids.size(), MissionBoard.DEV_PAGE), wide])
	var rite_at := ids.find(MissionBook.FIRST_TASTE)
	t.check(rite_at >= 0, "the rite is on the DEV tab (%d)" % rite_at)
	if rite_at >= 0:
		board.selected = rite_at
		board._select(rite_at - 1)
		board._select(rite_at)
		var rr := board.row1_rect(rite_at)
		var win := board.dev_window()
		t.check(rite_at >= win.x and rite_at < win.x + win.y and rr.size != Vector2.ZERO and Rect2(0, 0, 640, 360).encloses(rr),
			"the rite is reachable: the window %s holds it, inside the frame (%s)" % [win, rr])
	t.check(board.brief_top(MissionBook.FIRST_TASTE, r) < MissionBoard.rule_y(r, board.best_rows()),
		"its title and kind line end above the rule (%s < %s)" % [board.brief_top(MissionBook.FIRST_TASTE, r), MissionBoard.rule_y(r, board.best_rows())])
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	board.choose(MissionBook.FIRST_TASTE)
	t.check(picked == ["pick"] and board.chosen == MissionBook.FIRST_TASTE and board.tier == MissionBoard.DEV_TIER, "it can be picked (%s)" % [picked])
	board.free()
	var plain := MissionBoard.new().setup(save, "warning")
	var seen := false
	for tier in range(1, TierBook.NAMES.size() + 2):
		plain.tier = tier
		seen = seen or plain.missions().has(MissionBook.FIRST_TASTE)
	t.check(not seen, "without --dev the rite is on no tab")
	plain.free()


## God P5 (MS §1, plan Ruling C6, P5-22): with --dev the DEV tab has a second row of five compact Hunt cards under the first; row 1 (the
## sandbox, the towns' missions, the rite last) is unchanged. Each card is inside the screen, under row 1's cards and above the hint (y 344), clear
## of the others; its label is "<title> (Hunt)" when that wraps to at most two lines in the card, else the title alone; a click on a card picks it;
## without --dev there is no Hunt on any tab.
static func _dev_tab_hunts(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "warning")
	board.open_tab(MissionBoard.DEV_TIER)
	var hunts := board.dev_hunts()
	t.check(Array(hunts) == Array(HuntBook.ids()), "dev_hunts() is HuntBook.ids() (%s)" % [hunts])
	var row1 := board.missions()
	var in_row1 := false
	for id in hunts:
		in_row1 = in_row1 or row1.has(id)
	t.check(not in_row1, "none of the five is in row 1 (%s)" % [row1])
	t.check(board.tab_of(HuntBook.ids()[0]) == MissionBoard.DEV_TIER and board.tab_of(MissionBook.FIRST_TASTE) == MissionBoard.DEV_TIER,
		"a Hunt id is on the DEV tab")
	var row1_end := MissionBoard.card_rect(0, mini(row1.size(), MissionBoard.DEV_PAGE)).end.y
	var bad := []
	for i in hunts.size():
		var r := MissionBoard.hunt_rect(i, hunts.size())
		if not Rect2(0, 0, 640, 360).encloses(r) or r.position.y < row1_end or r.end.y > 344.0:
			bad.append("card %d %s (row 1 ends %s)" % [i, r, row1_end])
		for j in range(i + 1, hunts.size()):
			if r.intersects(MissionBoard.hunt_rect(j, hunts.size())):
				bad.append("cards %d and %d touch" % [i, j])
	t.check(bad.is_empty(), "each Hunt card is on the screen, under row 1, above the hint and clear of the others (%s)" % [bad])
	var wide := []
	for i in hunts.size():
		var id := String(hunts[i])
		var label := board.hunt_label(id)
		var title := String(HuntBook.row(id).title)
		var room := MissionBoard.hunt_rect(i, hunts.size()).size.x - 2.0 * MissionBoard.HUNT_PAD
		var lines := UiTheme.wrap(label, room, UiTheme.SIZE_SMALL)
		for line in lines:
			if UiTheme.width(line, UiTheme.SIZE_SMALL) > room:
				wide.append("%s: %s px of %s" % [line, UiTheme.width(line, UiTheme.SIZE_SMALL), room])
		if lines.size() > 2:
			wide.append("%s wraps to %d lines" % [label, lines.size()])
		t.check(label == "%s (Hunt)" % title or label == title, "the label of %s is the title, with (Hunt) or without (%s)" % [id, label])
		t.check(board.card_title(id) == label and Array(board.kind_lines(id)) == ["HUNT"], "card_title and kind_lines of %s (%s, %s)" % [id, board.card_title(id), board.kind_lines(id)])
	t.check(wide.is_empty(), "each label's lines fit their card in at most two lines (%s)" % [wide])
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	var at := MissionBoard.hunt_rect(2, hunts.size()).get_center()
	t.check(board.hit(at) == "hunt:2", "the centre of card 2 is hunt:2 (%s)" % board.hit(at))
	board.click(at)
	t.check(picked == ["pick"] and board.chosen == "expel_inquisitor" and board.tier == MissionBoard.DEV_TIER,
		"a click on card 2 picks expel_inquisitor on the DEV tab (%s, %s, %d)" % [picked, board.chosen, board.tier])
	board.free()
	_dev_tab_hunt_keys(t, save)
	var plain := MissionBoard.new().setup(save, "warning")
	t.check(plain.dev_hunts().is_empty(), "without --dev dev_hunts() is empty")
	var seen := false
	for tier in range(1, TierBook.NAMES.size() + 2):
		plain.tier = tier
		for id in HuntBook.ids():
			seen = seen or plain.missions().has(id)
	t.check(not seen, "without --dev no Hunt is on any tab")
	plain.free()


## The keyboard on the DEV tab's Hunt row (god P5, review minor 2): Down crosses to row 2 (the card nearest by x), Up back to row 1, Left and Right
## step within row 2 and wrap, Enter picks the Hunt; on a tier tab Down and Up do nothing; the DEV tab's hint names Up and Down, a tier tab's does not.
static func _dev_tab_hunt_keys(t, save: SaveFile) -> void:
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "warning")
	board.open_tab(MissionBoard.DEV_TIER)
	var hunts := board.dev_hunts()
	t.check(board.hint_text() == MissionBoard.HINT_DEV and board.hint_text().contains("Up and Down")
		and UiTheme.width(board.hint_text(), UiTheme.SIZE_SMALL) <= 624.0,
		"the DEV tab's hint names Up and Down and fits the screen (%s px)" % UiTheme.width(board.hint_text(), UiTheme.SIZE_SMALL))
	t.check(not board.row2 and board.selected == 0, "the DEV tab opens on row 1, card 0 (%s, %d)" % [board.row2, board.selected])
	board._unhandled_input(_key(KEY_DOWN))
	t.check(board.row2 and board.selected == 0, "Down from the first card of row 1 lands on the first Hunt (%s, %d)" % [board.row2, board.selected])
	board._unhandled_input(_key(KEY_RIGHT))
	t.check(board.row2 and board.selected == 1, "Right steps within row 2 (%d)" % board.selected)
	board._unhandled_input(_key(KEY_LEFT))
	board._unhandled_input(_key(KEY_LEFT))
	t.check(board.row2 and board.selected == hunts.size() - 1, "Left wraps within row 2 (%d)" % board.selected)
	board._unhandled_input(_key(KEY_RIGHT))
	board._unhandled_input(_key(KEY_RIGHT))
	board._unhandled_input(_key(KEY_RIGHT))
	t.check(board.row2 and board.selected == 2, "and Right again (%d)" % board.selected)
	board._unhandled_input(_key(KEY_UP))
	t.check(not board.row2 and board.selected >= 0 and board.selected < board.missions().size(), "Up returns to row 1 (%s, %d)" % [board.row2, board.selected])
	board._unhandled_input(_key(KEY_DOWN))
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	board._unhandled_input(_key(KEY_ENTER))
	t.check(picked == ["pick"] and board.chosen == hunts[board.selected] and HuntBook.has(board.chosen),
		"Enter on row 2 picks that Hunt (%s, %s)" % [picked, board.chosen])
	board.open_tab(1)
	var before := board.selected
	board._unhandled_input(_key(KEY_DOWN))
	t.check(not board.row2 and board.selected == before and board.hint_text() == MissionBoard.HINT,
		"on a tier tab Down does nothing and the hint is the plain one (%s, %d)" % [board.row2, board.selected])
	board.free()


## The DEV tab's row 1 is paged: DEV_PAGE cards at a time, the window follows the selection, markers show what is hidden.
static func _dev_tab_paging(t) -> void:
	var save := SaveFile.new()
	var board := MissionBoard.new()
	board.dev = true
	board.setup(save, "warning")
	board.open_tab(MissionBoard.DEV_TIER)
	var ids := board.missions()
	var n := ids.size()
	t.check(n > MissionBoard.DEV_PAGE, "the DEV tab has more than a page of cards (%d)" % n)
	var visible := 0
	var outside := 0
	for i in n:
		var r := board.row1_rect(i)
		if r.size != Vector2.ZERO:
			visible += 1
			if not Rect2(0, 0, 640, 360).encloses(r):
				outside += 1
	t.check(visible == MissionBoard.DEV_PAGE and outside == 0, "exactly a page of cards has a rect, inside the frame (%d, %d outside)" % [visible, outside])
	t.check(board.dev_window() == Vector2i(0, MissionBoard.DEV_PAGE) and board.dev_first == 0, "the window opens at the first card (%s)" % [board.dev_window()])
	var wide := []
	var r0 := board.row1_rect(0)
	for line in UiTheme.wrap(board.card_title(ids[0]), board.title_room(ids[0], r0), board.title_size(ids[0], r0)):
		if UiTheme.width(line, board.title_size(ids[0], r0)) > board.title_room(ids[0], r0) + 0.01:
			wide.append(line)
	t.check(wide.is_empty(), "card 0's title lines fit (%s)" % [wide])
	var h := board.hidden_sides()
	t.check(h == Vector2i(0, n - MissionBoard.DEV_PAGE) and board.marker_rect(-1).size == Vector2.ZERO and board.marker_rect(1).size != Vector2.ZERO,
		"only the right marker shows at first (%s)" % [h])
	var m := board.marker_rect(1)
	var cards_hit := false
	for i in n:
		var r := board.row1_rect(i)
		cards_hit = cards_hit or (r.size != Vector2.ZERO and r.intersects(m))
	t.check(not cards_hit and Rect2(0, 0, 640, 360).encloses(m), "the marker overlaps no card and is inside the frame (%s)" % [m])
	# Right from the last visible card scrolls by one.
	board.selected = MissionBoard.DEV_PAGE - 1
	board._select(MissionBoard.DEV_PAGE)
	t.check(board.selected == MissionBoard.DEV_PAGE and board.dev_first == 1 and board.row1_rect(0).size == Vector2.ZERO,
		"Right from the last visible card scrolls by one (%d, first %d)" % [board.selected, board.dev_first])
	# Left from the first visible card scrolls back.
	board._select(0)
	t.check(board.dev_first == 0 and board.selected == 0, "going back to card 0 scrolls to it (first %d)" % board.dev_first)
	# Wrap: Left from the first goes to the last, Right from the last to the first.
	board._select(-1)
	t.check(board.selected == n - 1 and board.dev_first == n - MissionBoard.DEV_PAGE and board.row1_rect(n - 1).size != Vector2.ZERO,
		"Left from the first wraps to the last, the window at the end (%d, first %d)" % [board.selected, board.dev_first])
	t.check(board.hidden_sides().y == 0 and board.marker_rect(1).size == Vector2.ZERO and board.marker_rect(-1).size != Vector2.ZERO, "and only the left marker shows")
	board._select(n)
	t.check(board.selected == 0 and board.dev_first == 0, "Right from the last wraps to the first and resets the window (%d, first %d)" % [board.selected, board.dev_first])
	# A click on a marker pages; one where a hidden card would have been picks nothing.
	var picked := []
	board.action.connect(func(what: String) -> void: picked.append(what))
	t.check(board.hit(board.marker_rect(1).get_center()) == "page:1", "the right marker is hit as a page")
	board.click(board.marker_rect(1).get_center())
	t.check(board.dev_first == MissionBoard.DEV_PAGE and board.selected == MissionBoard.DEV_PAGE and picked.is_empty(),
		"a marker click pages by one page without picking (first %d, selected %d, %s)" % [board.dev_first, board.selected, picked])
	t.check(board.hit(board.marker_rect(-1).get_center()) == "page:-1", "the left marker is hit as a page")
	board.click(board.marker_rect(-1).get_center())
	t.check(board.dev_first == 0 and board.selected == MissionBoard.DEV_PAGE - 1, "the left marker pages back (selects the last card of the new window) (first %d, selected %d)" % [board.dev_first, board.selected])
	board.dev_first = 2
	board.selected = 2
	var hidden_slot := MissionBoard.card_rect(0, MissionBoard.DEV_PAGE)  # where card 0 was; card 2 is first now
	var got := board.hit(hidden_slot.get_center())
	t.check(got == "card:2", "a click on the first slot picks the window's first card, not a hidden one (%s)" % got)
	var gap_point := Vector2(MissionBoard.card_rect(0, MissionBoard.DEV_PAGE).end.x + MissionBoard.CARD_GAP * 0.5, 150.0)
	t.check(board.hit(gap_point) == "", "a point between two visible cards hits nothing (%s)" % board.hit(gap_point))
	board.click(gap_point)
	t.check(picked.is_empty(), "a click in the gap between cards picks nothing (%s)" % [picked])
	# Every real id, twice round (the wrap is crossed): the selected card is always drawn, inside the frame, a page of cards at a time.
	board.row2 = false
	board._select(0)
	var steps_bad := []
	for step in 2 * n + 1:
		var sr := board.row1_rect(board.selected)
		var shown := 0
		for i in n:
			if board.row1_rect(i).size != Vector2.ZERO:
				shown += 1
		if sr.size == Vector2.ZERO or not Rect2(0, 0, 640, 360).encloses(sr) or shown != mini(n, MissionBoard.DEV_PAGE):
			steps_bad.append("step %d selected %d rect %s shown %d" % [step, board.selected, sr, shown])
		board._select(board.selected + 1)
	t.check(steps_bad.is_empty(), "stepping Right over all %d ids twice: the selection is always shown, a page of cards at a time (%s)" % [n, steps_bad])
	# A marker clicked while the Hunt row is selected pages from the window, not from a Hunt index.
	board.row2 = false
	board.dev_first = 0
	board.selected = 0
	board._cross_rows(true)
	t.check(board.row2, "Down crosses to the Hunt row")
	board.selected = 3
	board.click(board.marker_rect(1).get_center())
	var win2 := board.dev_window()
	t.check(not board.row2 and board.selected >= win2.x and board.selected < win2.x + win2.y and win2.x == MissionBoard.DEV_PAGE and picked.is_empty(),
		"a marker click from the Hunt row leaves it and pages the window (row2 %s, selected %d, window %s)" % [board.row2, board.selected, win2])
	# Arithmetic with 27 cards, stepping Right from the first to the last: every card is visible in turn, the window moves by one.
	var first := 0
	var reached := 0
	var bad := 0
	for sel in 27:
		var next := MissionBoard.follow_first(first, sel, 27)
		if sel >= next and sel < next + MissionBoard.DEV_PAGE:
			reached += 1
		if next - first > 1 or next < 0 or next + MissionBoard.DEV_PAGE > 27:
			bad += 1
		first = next
	for k in MissionBoard.DEV_PAGE:
		if not Rect2(0, 0, 640, 360).encloses(MissionBoard.card_rect(k, MissionBoard.DEV_PAGE)):
			bad += 1
	t.check(reached == 27 and bad == 0 and first == 27 - MissionBoard.DEV_PAGE, "27 cards: all reachable, the window steps by one, rects inside the frame (%d, %d bad, first %d)" % [reached, bad, first])
	board.free()
