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
	# Between the acts of a night (v0.09): the interlude, its re-draft, and BEGIN back into the same town.
	t.check(Game.next_screen("mission:act_over") == Game.Screen.INTERLUDE, "an act that is over leads to the interlude")
	t.check(Game.next_screen("interlude:draft") == Game.Screen.PREPARE, "the interlude's Choose powers leads to Prepare")
	t.check(Game.next_screen("interlude:missions") == Game.Screen.BOARD, "and its Missions to the board")
	t.check(Game.next_screen("prepare:begin") == Game.Screen.MISSION, "BEGIN leads back into the mission")
	# The Lantern campaign (v0.10): the night screen, its draft, the night's results, Pause's way back, the ending.
	t.check(Game.next_screen("title:campaign") == Game.Screen.CAMPAIGN, "Campaign leads to the night screen")
	t.check(Game.next_screen("campaign:draft") == Game.Screen.PREPARE, "its Choose powers leads to Prepare")
	t.check(Game.next_screen("campaign:title") == Game.Screen.TITLE, "and its Title to the title")
	t.check(Game.next_screen("prepare:campaign") == Game.Screen.CAMPAIGN, "Back from a campaign draft returns to the night")
	t.check(Game.next_screen("results:next") == Game.Screen.CAMPAIGN, "a campaign night's Continue leads to the next night")
	t.check(Game.next_screen("results:ending") == Game.Screen.ENDING, "or to the ending")
	t.check(Game.next_screen("pause:campaign") == Game.Screen.CAMPAIGN, "Pause can leave a night for the night screen")
	t.check(Game.next_screen("ending:title") == Game.Screen.TITLE, "and the ending leads to the title")
	t.check(Game.next_screen("title:ending") == Game.Screen.ENDING, "an ending not yet seen opens from the title (v0.10 M5)")

	# The tier board (v0.11 M1): the Upgrades from the board's header and from the results, and back to the board.
	t.check(Game.next_screen("board:upgrades") == Game.Screen.UPGRADES, "the board's Upgrades button opens the Upgrades")
	t.check(Game.next_screen("results:upgrades") == Game.Screen.UPGRADES, "and so do the results'")
	t.check(Game.next_screen("upgrades:back") == Game.Screen.BOARD, "whose Back is the board")

	# A --show sample never writes the player's save (v0.10 M5 final review): --show=ending, campaign-choice and the
	# rest build a state of their own, and the first key pressed on one -- Enter on the ending, MANIFEST after a card --
	# used to write it over the player's real campaign. Every sample writes to a throwaway file instead; an ordinary
	# run is untouched.
	var leaking := PackedStringArray()
	for sample in ["board", "prepare", "results", "results-night", "results-feast", "results-warning", "interlude",
			"pause", "campaign", "campaign-choice", "ending", "miras", "cael", "lanterns", "flame", "flame-beams",
			"some-later-sample"]:
		if Game.save_path_for(sample, SaveFile.PATH) != Game.SHOW_SAVE:
			leaking.append(sample)
	t.check(leaking.is_empty(),
		"every --show sample writes its throwaway save, not the player's (leaking: %s)" % ", ".join(leaking))
	t.check(Game.save_path_for("", SaveFile.PATH) == SaveFile.PATH, "a run with no sample writes the real save")
	t.check(Game.save_path_for("", Game.FLOW_TEST_SAVE) == Game.FLOW_TEST_SAVE, "and --flow-test keeps its own file")
	t.check(Game.SHOW_SAVE != SaveFile.PATH and Game.SHOW_SAVE != Game.FLOW_TEST_SAVE,
		"the samples' throwaway is a file of its own")

	# Every action in the table names a screen that exists, and every screen can be reached.
	var reachable := {}
	for action in Game.FLOW:
		var to: int = Game.FLOW[action]
		t.check(to >= 0 and to < Game.Screen.size(), "%s leads to a real screen (%d)" % [action, to])
		reachable[to] = true
	t.check(reachable.size() == Game.Screen.size() and Game.Screen.size() == 9,
		"all nine screens are reachable, the Upgrades too (v0.11 M1) (%d)" % reachable.size())

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

	# The interlude (v0.09): with two acts to choose from, nothing is chosen until the player picks one, and Choose
	# powers is refused until then; with one, it is chosen already. Its two cards fit the screen without touching.
	var ln := MissionBook.long_night()
	var two := InterludeScreen.new()
	two.setup({"mission": "omen", "won": true, "goal": {"label": "Stop the warning", "done": true}, "bonuses": [],
		"time": 21.4}, [ln.act("festival"), ln.act("procession")], NightState.new())
	var emitted: Array[String] = []
	two.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(two.chosen == "", "with two acts to choose from, none is chosen at first ('%s')" % two.chosen)
	two.click(two.button_rect("draft").get_center())
	t.check(two.chosen == "" and emitted.is_empty(), "Choose powers is refused while no act is chosen (%s)" % [emitted])
	two.choose("procession")
	t.check(two.chosen == "procession" and emitted.is_empty(), "choose() picks the Procession without leaving ('%s')" % two.chosen)
	two.click(two.button_rect("draft").get_center())
	t.check(",".join(emitted) == "draft", "then Choose powers goes (%s)" % [emitted])
	two.click(two.button_rect("missions").get_center())
	t.check(",".join(emitted) == "draft,missions", "and Missions goes to the board (%s)" % [emitted])
	two.free()
	var one := InterludeScreen.new()
	one.setup({"mission": "festival", "won": true}, [ln.act("judgement")], NightState.new())
	t.check(one.chosen == "judgement", "with one act to follow, it is chosen at setup ('%s')" % one.chosen)
	one.free()
	var a := InterludeScreen.card_rect(0, 2)
	var b := InterludeScreen.card_rect(1, 2)
	t.check(Rect2(0, 0, 640, 360).encloses(a) and Rect2(0, 0, 640, 360).encloses(b) and not a.intersects(b),
		"the interlude's two cards fit the screen without touching (%s, %s)" % [a, b])
