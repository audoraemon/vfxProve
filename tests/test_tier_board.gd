extends RefCounted
## v0.11 M1 the tier board (spec §3.1): five tabs and the cards of the open one fit the screen; a fresh board opens on Whisper,
## a locked tier shows its rule and its missions cannot be picked; the header; a card's best; the board's draft greys and
## refuses the locked powers (spec §3.4); Prepare for a board mission has no difficulty picker.


static func run(t) -> void:
	_dev(t)
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
	t.check(board.tier == 1 and Array(board.missions()) == ["warning"] and board.lock_line() == ""
		and board.header_text() == "Night 1   Believers 0", "a fresh board: Whisper, The Warning, Night 1 (%s)" % board.header_text())
	board.open_tab(2)
	t.check(board.tier == 2 and board.lock_line() == "Clear 1 Whisper mission", "Omen is locked, its rule shown")
	board.choose("miras_house")
	t.check(picked.is_empty() and board.chosen == "" and board.tier == 2, "a locked mission cannot be picked")
	board.choose("warning")
	t.check(picked == ["pick"] and board.chosen == "warning" and board.tier == 1, "an open one is")
	save.descend.cleared.append("warning")
	save.descend.refresh_open()
	board.choose("broken_lanterns")
	t.check(board.chosen == "broken_lanterns" and board.lock_line() == "", "Omen open: its mission picked")
	var u := InputEventKey.new()
	u.physical_keycode = KEY_U
	u.pressed = true
	board._unhandled_input(u)
	t.check(picked.back() == "upgrades", "U asks for the Upgrades")
	t.check(board.hit(MissionBoard.UPGRADES_RECT.get_center()) == "upgrades" and board.hit(MissionBoard.tab_rect(2).get_center()) == "tab:3"
		and board.hit(MissionBoard.card_rect(0, 2).get_center()) == "card:0", "what is under the mouse")
	board.free()
	var back := MissionBoard.new().setup(save, "broken_lanterns")
	t.check(back.tier == 2 and back.selected == 1, "it opens on the mission last picked, when its tier is open")
	back.free()
	var shut := MissionBoard.new().setup(SaveFile.new(), "festival")
	t.check(shut.tier == 1 and shut.selected == 0, "and on Whisper when it is not")
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
	board.free()


static func _draft(t) -> void:
	# Last Judgement's pool is every power, so the lock is what refuses (The Warning's pool would refuse first).
	var d := Draft.new().for_mission(TierBook.board("last_judgement"))
	d.locked = PackedStringArray(["tsunami", "nova"])
	t.check(d.refusal("tsunami") == "locked" and d.toggle("tsunami") == "locked" and d.refusal("doom") == "", "a locked power is refused")
	d.preselect(PackedStringArray(["tsunami", "doom"]))
	t.check(d.picks == PackedStringArray(["doom"]), "and left out of a saved loadout")
	var prep := PrepareScreen.new().setup(TierBook.board("warning"), PackedStringArray(), ResponseProfile.DEFAULT,
		DescendState.new().locked())
	t.check(prep.draft.locked.size() == 23 and prep.budget_text() == "0 / 3 slots   0 / 6 DP"
		and prep.hit(PrepareScreen.arrow_rect(-1).get_center()) == "" and not prep.mission.chooses_difficulty(),
		"the board's Prepare: Tier 1's budget, the locked powers, no difficulty picker")
	t.check(String(PrepareScreen.REFUSALS["locked"]) == "Locked: unlock it on the Upgrades screen", "and says why it refuses one")
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
	t.check(board.tier == MissionBoard.DEV_TIER and Array(board.missions()) == [MissionBook.CAPITAL_SANDBOX]
		and board.lock_line() == "", "the DEV tab lists the capital's sandbox, open (%s)" % [board.missions()])
	board.choose(MissionBook.CAPITAL_SANDBOX)
	t.check(picked == ["pick"] and board.chosen == MissionBook.CAPITAL_SANDBOX, "and it can be picked")
	var on_dev := MissionBoard.new()
	on_dev.dev = true
	on_dev.setup(save, MissionBook.CAPITAL_SANDBOX)
	t.check(on_dev.tier == MissionBoard.DEV_TIER, "the board reopens on the DEV tab after a sandbox night")
	on_dev.free()
	board.free()
