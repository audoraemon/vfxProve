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
	night.click(night.button_rect("draft").get_center())
	t.check(",".join(emitted) == "restart,draft", "the second press starts over; Choose powers goes (%s)" % [emitted])
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
