extends RefCounted
## v0.11 M1 the board's screens (spec §3.4, §6): the results' rows -- the main objective, each wish granted, failed or lost
## with why -- and lines -- believers banked and the total, the night, the tier's progress, bests beaten (a test-mode night's say
## nothing was banked: god P1) -- and its Board, Again and Change powers (god P1: the Upgrades button went with the test mode); the
## Upgrades screen's buttons and grid fit, a click buys what it can afford and refuses what it cannot.

const RESULT := {
	"mission": "warning", "won": true, "reason": "warning", "goal": {"label": "The warnings die", "done": true},
	"descend": {"tier": 1, "main": true, "main_time": 201.0, "main_reward": 10, "ascended": false, "caught": "dawn",
		"lost_text": "lost: dawn came", "earned": 10, "kept": 0,
		"wishes": [{"text": "Burn the moneylender's house", "reward": 10, "state": "granted", "lost": true},
			{"text": "Show me a sign", "reward": 5, "state": "failed", "lost": false},
			{"text": "Lead my brother out", "reward": 10, "state": "open", "lost": false}],
		"bank": {"believers": 10, "total": 35, "night": 3, "cleared": true, "first_clear": true, "opened": 2,
			"progress": "Whisper 1 / 1 cleared: Omen is open", "bests": ["Fastest clear 3:21"]}},
}


static func run(t) -> void:
	_frames(t)
	_results(t)
	_upgrades(t)


## UI resolution Task 6b: the Upgrades screen draws in a 640x360 design frame centred in the area, holds the wide spaces while it lives, and no power's name is cut to another's.
static func _frames(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	UiScale.set_test_area(Vector2i(800, 450))
	var offset := Vector2(80, 45)
	var up := UpgradesScreen.new()
	tree.root.add_child(up)
	up.setup(DescendState.new())
	t.check(up._ui.position == offset and up._ui.size == Vector2(640, 360), "upgrades: the frame is 640x360 at (80, 45) in an 800x450 area")
	t.check(UiScale.backdrop(up._ui) == Rect2(-offset, Vector2(800, 450)), "upgrades: the backdrop is the whole area in frame coordinates")
	t.check(UiTheme.word_spacing, "upgrades: holds the word spacing while it lives")
	var got := []
	up.action.connect(func(what: String) -> void: got.append(what))
	up._on_gui_input(_click(UpgradesScreen.BACK_RECT.get_center()))
	t.check(got == ["back"], "upgrades: a click at Board's frame-local centre hits it (%s)" % [got])
	var n := up.powers.size()
	var cell_w := UpgradesScreen.cell_rect(0, n).size.x
	var bad := []
	var cut := 0
	for key in up.powers:
		var full := String(PowerBook.get_power(key).name)
		var room := cell_w - UiTheme.width("%d" % DescendState.unlock_price(key), UiTheme.SIZE_SMALL) - 14.0
		var shown := UpgradesScreen.cell_name(full, room)
		if UiTheme.width(shown, UiTheme.SIZE_SMALL) > room + 0.01:
			bad.append(key)
		if shown != full:
			cut += 1
			if not shown.ends_with("…"):
				bad.append(key + " (no ellipsis)")
	t.check(bad.is_empty(), "upgrades: every power's name fits its cell, a cut one ends in an ellipsis (%s)" % [bad])
	t.check(UpgradesScreen.cell_name("Judgement of the Ancients", 109.0).begins_with("Judgement of"), "upgrades: a long name keeps its words, not just its first (%s)" % UpgradesScreen.cell_name("Judgement of the Ancients", 109.0))
	t.check(UpgradesScreen.cell_name("Magnify", 109.0) == "Magnify", "upgrades: a name that fits is whole")
	t.check(cut <= 3, "upgrades: only a few names need a cut (%d)" % cut)
	up.free()
	t.check(not UiTheme.word_spacing, "upgrades: gives the word spacing back when freed")
	UiScale.clear_test_area()


static func _results(t) -> void:
	var rows := ResultsScreen.descend_rows(RESULT)
	t.check(rows == [["The warnings die", "+10", "ok", ""], ["Burn the moneylender's house", "", "lost", "lost: dawn came"],
		["Show me a sign", "", "x", Wish.UNANSWERED], ["Lead my brother out", "", "open", ""]],
		"the main objective banked; a granted wish lost to dawn; a failed one; one never answered (%s)" % [rows])
	t.check(Array(ResultsScreen.summary_lines(RESULT)) == ["Believers +10, 35 now", "Night 3", "Whisper 1 / 1 cleared: Omen is open",
		"New best: Fastest clear 3:21"], "the believers, the night, the tier's progress, the best (%s)" % [ResultsScreen.summary_lines(RESULT)])
	t.check(ResultsScreen.caught_line(RESULT) == "Caught: dawn came. The night's main win stands.",
		"a caught night says why, and that its win stands (%s)" % ResultsScreen.caught_line(RESULT))
	var saw := RESULT.duplicate(true)
	saw.descend.lost_text = "lost: Halcyon saw you"
	t.check(ResultsScreen.caught_line(saw) == "Caught: Halcyon saw you. The night's main win stands.", "whatever caught it")
	var won := RESULT.duplicate(true)
	won.descend.ascended = true
	t.check(ResultsScreen.caught_line(won) == "", "an ascended night has no such line")
	won.descend.wishes[0].lost = false
	t.check(ResultsScreen.descend_rows(won)[1] == ["Burn the moneylender's house", "+10", "ok", ""], "ascended: the wish banked")
	var lost := {"mission": "warning", "won": false, "reason": "bell", "goal": {"label": "The warnings die", "done": false},
		"descend": {"main": false, "main_reward": 10, "wishes": [], "bank": {"believers": 0, "total": 5, "night": 4}}}
	t.check(ResultsScreen.caught_line(lost) == "", "a lost night was not caught after a win")
	t.check(ResultsScreen.descend_rows(lost) == [["The warnings die", "", "x", ""]]
		and ResultsScreen.summary_lines(lost)[0] == "Believers +0, 5 now", "a loss: the main objective crossed, nothing banked")
	var screen := ResultsScreen.new().setup(RESULT)
	var emitted := []
	screen.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(screen.descend and not screen.campaign, "a board night's results")
	for a in ["missions", "replay", "change"]:
		var r := screen._menu.rect_of(a)
		screen._on_gui_input(_click(r.get_center()))
	t.check(emitted == ["missions", "replay", "change"], "Board, Again and Change powers, no Upgrades (%s)" % [emitted])
	t.check(not screen._menu.rect_of("upgrades").has_area(), "and no button for the Upgrades")
	screen.free()
	# A test-mode night (god P1, ruling P11): the same rows, but its lines say nothing was banked.
	var test := RESULT.duplicate(true)
	test.descend.bank = {"test": true, "night": 3, "cleared": true, "first_clear": false, "bests": ["Fastest clear 3:21"]}
	t.check(Array(ResultsScreen.summary_lines(test)) == ["Test mode: nothing banked", "New best: Fastest clear 3:21"]
		and ResultsScreen.descend_rows(test) == rows, "a test-mode night: nothing banked, its best shown (%s)" % [ResultsScreen.summary_lines(test)])


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _upgrades(t) -> void:
	var bad := 0
	var state := DescendState.new()
	var up := UpgradesScreen.new().setup(state)
	var n := up.powers.size()
	for i in n:
		var r := UpgradesScreen.cell_rect(i, n)
		if not Rect2(0, 0, 640, 316).encloses(r) or r.intersects(UpgradesScreen.DP_RECT) or r.intersects(UpgradesScreen.SLOT_RECT) 				or r.size.y < UpgradesScreen.MIN_CELL_H:
			bad += 1
		for j in i:
			if r.intersects(UpgradesScreen.cell_rect(j, n)):
				bad += 1
	t.check(n == 38 and bad == 0, "the 38 locked powers' grid fits beside the upgrades, no two cells overlapping (%d)" % bad)
	t.check(UpgradesScreen.cell_height(36) == UpgradesScreen.CELL.y and UpgradesScreen.cell_height(37) < UpgradesScreen.CELL.y
		and UpgradesScreen.cell_height(37) >= UpgradesScreen.MIN_CELL_H,
		"the rows keep their full height while they fit and share the room when they do not (%.0f px for 38)" % UpgradesScreen.cell_height(38))
	var emitted := []
	up.action.connect(func(what: String) -> void: emitted.append(what))
	up.click(up.button_rect("dp").get_center())
	t.check(state.dp_bought == 0 and up.refused_reason == "Not enough believers" and emitted.is_empty(), "too few believers: refused, and why")
	state.believers = 100
	up.click(up.button_rect("dp").get_center())
	t.check(state.dp_bought == 1 and state.believers == 75 and emitted == ["bought"], "a click buys the first +1 DP for 25")
	up.click(up.button_rect("tsunami").get_center())
	t.check(state.is_unlocked("tsunami") and state.believers == 15 and up.button_rect("tsunami").has_area(),
		"a locked power unlocked for 60, its cell kept in place")
	up.click(up.button_rect("tsunami").get_center())
	t.check(up.refused_reason == "Already unlocked" and state.believers == 15, "and not bought twice")
	t.check(up.hit(UpgradesScreen.BACK_RECT.get_center()) == "back", "Board goes back")
	up.click(UpgradesScreen.BACK_RECT.get_center())
	t.check(emitted.back() == "back", "to the tier board")
	up.free()
