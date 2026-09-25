extends RefCounted
## The screen flow as data: every button on every screen leads somewhere, and the table matches the spec's
## flow (title -> prepare -> mission -> results, with pause over the mission).


static func run(t) -> void:
	t.check(Game.next_screen("title:play") == Game.Screen.PREPARE, "Play leads to Prepare")
	t.check(Game.next_screen("prepare:manifest") == Game.Screen.MISSION, "Manifest leads to the mission")
	t.check(Game.next_screen("prepare:back") == Game.Screen.TITLE, "Prepare can go back to the title")
	t.check(Game.next_screen("mission:over") == Game.Screen.RESULTS, "a finished mission leads to the results")
	t.check(Game.next_screen("results:replay") == Game.Screen.MISSION, "Replay runs the same loadout again")
	t.check(Game.next_screen("results:change") == Game.Screen.PREPARE, "Change powers goes back to the draft")
	t.check(Game.next_screen("results:title") == Game.Screen.TITLE, "and Title goes home")
	t.check(Game.next_screen("pause:resume") == Game.Screen.MISSION, "Resume stays in the mission")
	t.check(Game.next_screen("pause:restart") == Game.Screen.MISSION, "Restart is a new mission")
	t.check(Game.next_screen("pause:change") == Game.Screen.PREPARE, "Change powers from the pause menu drafts again")
	t.check(Game.next_screen("pause:title") == Game.Screen.TITLE, "and the pause menu can quit to the title")
	t.check(Game.next_screen("prepare:nonsense") == -1, "an action nobody offers leads nowhere")

	# Every action in the table names a screen that exists, and every screen can be reached.
	var reachable := {}
	for action in Game.FLOW:
		var to: int = Game.FLOW[action]
		t.check(to >= 0 and to <= Game.Screen.RESULTS, "%s leads to a real screen (%d)" % [action, to])
		reachable[to] = true
	t.check(reachable.size() == 4, "all four screens are reachable (%d)" % reachable.size())
