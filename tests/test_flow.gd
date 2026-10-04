extends RefCounted
## The screen flow as data: every button on every screen leads somewhere, and the table matches the spec's
## flow (v0.08: title -> mission board -> prepare -> mission -> results, with pause over the mission, and Results
## and Pause going back to the board).


static func run(t) -> void:
	t.check(Game.next_screen("title:play") == Game.Screen.BOARD, "Play leads to the mission board")
	t.check(Game.next_screen("board:pick") == Game.Screen.PREPARE, "picking a mission leads to Prepare")
	t.check(Game.next_screen("board:back") == Game.Screen.TITLE, "the board can go back to the title")
	t.check(Game.next_screen("prepare:manifest") == Game.Screen.MISSION, "Manifest leads to the mission")
	t.check(Game.next_screen("prepare:back") == Game.Screen.BOARD, "Prepare goes back to the board")
	t.check(Game.next_screen("mission:over") == Game.Screen.RESULTS, "a finished mission leads to the results")
	t.check(Game.next_screen("results:replay") == Game.Screen.MISSION, "Replay runs the same loadout again")
	t.check(Game.next_screen("results:change") == Game.Screen.PREPARE, "Change powers goes back to the draft")
	t.check(Game.next_screen("results:missions") == Game.Screen.BOARD, "and Missions goes to the board")
	t.check(Game.next_screen("results:title") == -1, "the results no longer offer the title")
	t.check(Game.next_screen("pause:resume") == Game.Screen.MISSION, "Resume stays in the mission")
	t.check(Game.next_screen("pause:restart") == Game.Screen.MISSION, "Restart is a new mission")
	t.check(Game.next_screen("pause:change") == Game.Screen.PREPARE, "Change powers from the pause menu drafts again")
	t.check(Game.next_screen("pause:missions") == Game.Screen.BOARD, "and the pause menu can go to the board")
	t.check(Game.next_screen("pause:title") == -1, "but not to the title")
	t.check(Game.next_screen("prepare:nonsense") == -1, "an action nobody offers leads nowhere")

	# Every action in the table names a screen that exists, and every screen can be reached.
	var reachable := {}
	for action in Game.FLOW:
		var to: int = Game.FLOW[action]
		t.check(to >= 0 and to <= Game.Screen.RESULTS, "%s leads to a real screen (%d)" % [action, to])
		reachable[to] = true
	t.check(reachable.size() == Game.Screen.size() and Game.Screen.size() == 5,
		"all five screens are reachable (%d)" % reachable.size())

	# The board's cards sit side by side inside the screen, above its hint, without touching (v0.08).
	for count in [1, 2, 3]:
		var bad := 0
		for i in count:
			var r := MissionBoard.card_rect(i, count)
			if not Rect2(0, 0, 640, 310).encloses(r):
				bad += 100
			for j in range(i + 1, count):
				if r.intersects(MissionBoard.card_rect(j, count)):
					bad += 1
		t.check(bad == 0, "%d board card(s) fit the screen without touching (%d)" % [count, bad])
	t.near(MissionBoard.card_rect(0, 1).get_center().x, 320.0, 0.51, "one mission's card sits in the middle")
