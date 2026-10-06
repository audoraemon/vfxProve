extends RefCounted
## v0.10 the campaign's screens: the night screen's cards fit and choose like the interlude's, Choose powers waits for a
## card, "New campaign" asks twice (review focus 4), the status line names the budget, bites and title; a draft opened
## after a bite keeps what fits (review focus 1); the ending turns its pages.


static func run(t) -> void:
	for count in [1, 2, 3]:
		var bad := 0
		for i in count:
			var r := CampaignScreen.card_rect(i, count)
			if not CampaignScreen.PANEL.encloses(r) or r.end.y > CampaignScreen.HINT_Y - 8.0:
				bad += 100
			for j in range(i + 1, count):
				if r.intersects(CampaignScreen.card_rect(j, count)):
					bad += 1
		t.check(bad == 0, "%d night card(s) fit the panel above the hint without touching (%d)" % [count, bad])

	var s := CampaignState.new()
	s.night = 1
	var night := CampaignScreen.new()
	night.setup(s)
	var emitted: Array[String] = []
	night.action.connect(func(what: String) -> void: emitted.append(what))
	t.check(night.options.size() == 3 and night.chosen == "", "Night 2 shows three cards, none chosen")
	t.check((night.options[2] as MissionDef).slots == 3 and (night.options[2] as MissionDef).dp_capacity == 6,
		"each card's mission carries the campaign's slots and budget")
	night.click(night.button_rect("draft").get_center())
	t.check(emitted.is_empty(), "Choose powers is refused until a card is chosen (%s)" % [emitted])
	night.click(CampaignScreen.card_rect(2, 3).get_center())
	t.check(night.chosen == MissionBook.BROKEN_LANTERNS, "a click on the third card chooses Broken Lanterns (%s)" % night.chosen)
	night.click(night.button_rect("restart").get_center())
	t.check(emitted.is_empty() and night.confirming, "New campaign asks again before it starts over")
	night.click(night.button_rect("restart").get_center())
	t.check(emitted.is_empty(), "a double-click on New campaign does not start over (%s)" % [emitted])
	night._confirm_ms -= CampaignScreen.CONFIRM_MS + 1
	night.click(night.button_rect("restart").get_center())
	night.click(night.button_rect("draft").get_center())
	t.check(",".join(emitted) == "restart,draft", "a second press a moment later starts over; Choose powers goes (%s)" % [emitted])

	# v0.10 M5: a card chosen before (Back from the draft, Pause > Campaign) is chosen again; a pick tonight does not offer
	# chooses nothing.
	var back := CampaignScreen.new()
	back.setup(s, MissionBook.VIGIL_FLAME)
	t.check(back.chosen == MissionBook.VIGIL_FLAME and back.selected == 1, "a card chosen before is chosen again (%s)" % back.chosen)
	back.free()
	var stray := CampaignScreen.new()
	stray.setup(s, MissionBook.LAST_JUDGEMENT)
	t.check(stray.chosen == "" and stray.selected == 0, "a mission tonight does not offer chooses nothing")
	stray.free()

	# Spec §5.3 (v0.10 M5): every card shows its mission's goal, clear of Cael's line at its foot -- Night 2's three and
	# Night 3's two, in a sleeping and a warned town (review focus 5).
	var cramped := PackedStringArray()
	for n in [1, 2]:
		for rang in [false, true]:
			var cs := CampaignState.new()
			cs.night = n
			cs.bell_rang = rang
			var count := cs.options().size()
			for i in count:
				var def := cs.mission(String((cs.options()[i] as Dictionary).mission))
				var lay := CampaignScreen.card_layout(def, cs, CampaignScreen.card_rect(i, count))
				if (lay.goal as PackedStringArray).is_empty() or (lay.goal as PackedStringArray)[0] == "" \
						or float(lay.goal_end) > float(lay.line_top) - UiTheme.LINE_SMALL:
					cramped.append("%s %.0f/%.0f" % [def.id, float(lay.goal_end), float(lay.line_top)])
	t.check(cramped.is_empty(), "every card shows its goal, clear of Cael's line (cramped: %s)" % ", ".join(cramped))
	night.free()

	var one := CampaignScreen.new()
	one.setup(CampaignState.new())
	t.check(one.options.size() == 1 and one.chosen == MissionBook.WARNING, "Night 1's one mission is chosen at setup")
	one.free()
	t.check(CampaignScreen.status_text(CampaignState.new()) == "6 DP   3 slots   Bites 0 / 3   The Forgotten",
		"the status line: %s" % CampaignScreen.status_text(CampaignState.new()))
	t.check(CampaignScreen.card_line(MissionBook.vigil_flame(), s) == CampaignText.CARD_LINES["vigil_flame"],
		"a Night 2 card carries Cael's line")
	var warned := CampaignState.new()
	warned.night = 2
	warned.bell_rang = true
	t.check(CampaignScreen.card_line(warned.mission(MissionBook.FEAST_FESTIVAL), warned)
		== "The bell rang: soldiers watch the square.", "a Feast card carries The Long Night's line for the town it meets")

	# Review focus 1: after a bite the budget is 4; a saved 6-DP loadout opens with what fits, in its order.
	var bitten := CampaignState.new()
	bitten.dp = 4
	var draft := Draft.new().for_mission(bitten.mission(MissionBook.WARNING))
	draft.preselect(PackedStringArray(["wisp", "discord", "whisper"]))
	t.check(draft.picks == PackedStringArray(["wisp", "discord"]) and draft.spent() == 4,
		"a loadout over the bitten budget keeps what fits (%s)" % [draft.picks])

	var end := EndingScreen.new()
	end.setup(CampaignDef.FALSE_LANTERN, "vision")
	var out: Array[String] = []
	end.action.connect(func(what: String) -> void: out.append(what))
	t.check(end.pages.size() == 2 and end.page == 0 and String(end.pages[0].title) == "The Vision"
		and String(end.pages[1].title) == "The False Lantern", "the Theft ending: The Vision, then The False Lantern")
	end.turn()
	t.check(end.page == 1 and out.is_empty(), "a turn shows the ending")
	end.turn()
	t.check(",".join(out) == "title", "a turn on the last page leaves for the title (%s)" % [out])
	end.free()
	var eaten := EndingScreen.new()
	eaten.setup(CampaignDef.EATEN, "")
	t.check(eaten.pages.size() == 1 and String(eaten.pages[0].title) == "Eaten", "Eaten has one page")
	eaten.free()

	# The ending's last page closes on the campaign (v0.10 M5): the god's title, the nights won, the bites.
	var ts := CampaignState.new()
	ts.tally["theft"] = 1
	ts.last_path = "theft"
	ts.nights_won = 2
	ts.bites = 1
	t.check(EndingScreen.summary_text(ts) == "The Deceiver   Nights won 2   Bites 1 / 3",
		"the closing line: %s" % EndingScreen.summary_text(ts))
	var told := EndingScreen.new()
	told.setup(CampaignDef.FALSE_LANTERN, "vision", EndingScreen.summary_text(ts))
	t.check(told.summary == EndingScreen.summary_text(ts) and told.pages.size() == 2, "the ending keeps it for its last page")
	told.free()

	# Results in a campaign: one Continue, and the line on what the night did.
	var res := ResultsScreen.new()
	res.setup({"mission": "warning", "won": true, "reason": "omen", "goal": {"label": "Stop the warning", "done": true},
		"campaign": {"won": true, "dp_gain": 2, "dp": 8, "bites": 0, "ending": ""}})
	t.check(res.campaign and res._menu.items.size() == 1 and String(res._menu.items[0].action) == "next",
		"a campaign night's results offer one Continue")
	res.free()
	t.check(ResultsScreen.campaign_line({"won": true, "dp_gain": 3, "dp": 9}) == "The god grows: +3 DP, 9 DP now.",
		"a won night's line")
	t.check(ResultsScreen.campaign_line({"won": false, "dp": 5, "bites": 1}) == "Halcyon bites: 5 DP now. Bites 1 / 3.",
		"a lost night's line")
	t.check(ResultsScreen.campaign_line({"won": false, "dp": 4, "bites": 3, "ending": "eaten"}) == "Halcyon has eaten you.",
		"the last bite's line")
	# v0.10 M5: the Feast's results -- its own goal and bonus, the time, no rank and no "Solved by" (it has none); The
	# Warning still says what solved it.
	var feast := {"mission": "feast_festival", "won": true, "reason": "festival", "time": 96.0,
		"goal": {"label": "The festival is broken", "done": true}, "bonuses": [{"label": "Before the bell", "earned": true}]}
	t.check(ResultsScreen.plain_rows(feast) == [["The festival is broken", "", true], ["Before the bell", "", true],
		["Time", "1:36", false]], "the Feast's rows (%s)" % [ResultsScreen.plain_rows(feast)])
	t.check(ResultsScreen.title_for(true, "festival") == "THE FEAST IS BROKEN"
		and MissionBook.get_mission("feast_festival").name == "The Festival", "named the Festival, not Act II")
	t.check((ResultsScreen.plain_rows(Game.SAMPLE_WARNING_RESULT).back() as Array) == ["Solved by", "VEIL", false],
		"The Warning still says what solved it")
	var pause := PauseMenu.new()
	pause.setup(true)
	t.check(String(pause._menu.items[3].action) == "campaign" and String(pause._menu.items[3].label) == "Campaign",
		"in a campaign, Pause's last button is Campaign")
	pause.free()
