extends RefCounted
## v0.09 The Long Night as data: three acts with a choice after the first, the town each act wants given the night so
## far, what carries between acts, and the night's score and rank.


static func run(t) -> void:
	var m := MissionBook.long_night()
	t.check(m.id == "long_night" and m.tier == 3 and m.has_acts() and not m.chooses_difficulty(),
		"The Long Night is a Tier 3 mission in acts, its town set by the night")
	# v0.09.1 per-act DP: the god grows through the night. The night itself (the board card, the first Prepare) shows
	# Act I's budget; each act has its own.
	t.check(m.slots == 3 and m.dp_capacity == 6 and m.powers() == PowerBook.keys(),
		"the night opens on Act I's 3 slots and 6 DP, every power (%d, %d)" % [m.slots, m.dp_capacity])
	var budgets := {}
	for a: ActDef in m.acts:
		budgets[a.id] = [a.slots, a.dp_capacity]
	t.check(budgets == {"omen": [3, 6], "festival": [4, 10], "procession": [4, 10], "judgement": [4, 14]},
		"Act I 3 slots / 6 DP, Act II 4 / 10, Act III 4 / 14 (%s)" % [budgets])
	var kit_dp := 0
	for key in m.default_loadout:
		kit_dp += int(PowerBook.get_power(key).dp)
	t.check(m.default_loadout.size() <= 3 and kit_dp <= 6, "the night's default loadout fits Act I (%d DP)" % kit_dp)
	var first := m.first_act()
	t.check(first.id == "omen" and Array(first.next) == ["festival", "procession"], "Act I leads to a choice of two")
	t.check(Array(m.act("festival").next) == ["judgement"] and Array(m.act("procession").next) == ["judgement"],
		"both paths lead to Judgement")
	t.check(m.act("judgement").is_last() and not first.is_last(), "Judgement is the last act")
	t.check(m.act("nonsense") == null, "an unknown act is null")
	t.near(first.clock, 120.0, 0.001, "Act I is two minutes")
	t.near(m.act("judgement").clock, 300.0, 0.001, "Act III is five")
	t.check(MissionBook.all()[1].id == "long_night", "the board lists it between The Warning and Last Judgement")

	# The night remembers what each act did.
	var n := NightState.new()
	n.record("omen", {"won": true, "reason": "warning", "time": 40.0, "bonuses": [{"label": "Unseen", "earned": true}]}, null)
	n.path = "procession"
	n.record("procession", {"won": false, "reason": "sailed", "time": 150.0, "bonuses": [], "prince": "escaped"}, null)
	t.check(n.acts_won() == 1 and n.bonuses_earned() == 1, "one act won, one bonus (%d, %d)" % [n.acts_won(), n.bonuses_earned()])
	t.check(n.prince == "escaped" and n.escape_limit() == NightState.PRINCE_ESCAPED_LIMIT,
		"the Prince escaping lowers Act III's escape limit to %d" % NightState.PRINCE_ESCAPED_LIMIT)
	t.check(NightState.new().escape_limit() == NightState.ESCAPE_LIMIT and NightState.PRINCE_ESCAPED_LIMIT < NightState.ESCAPE_LIMIT,
		"otherwise it is the night's own, the higher")
	t.check(n.act_result("omen").reason == "warning" and n.act_result("judgement").is_empty(), "results by act")
	t.check(n.night_score(9000) == 9000 + NightState.ACT_POINTS + NightState.BONUS_POINTS, "the night's score")
	t.check(NightState.rank_for(30000) == "S" and NightState.rank_for(29999) == "A" and NightState.rank_for(6999) == "D",
		"and its rank")
	var final := {"won": true, "reason": "citadel", "time": 170.0, "score": 9000, "lines": [], "bonuses": []}
	var r := n.result(final, "long_night")
	t.check(r.mission == "long_night" and r.won and r.path == "procession" and (r.acts as Array).size() == 2,
		"the night's result keeps every act and the path")
	t.check(int(r.score) == n.night_score(9000) and String(r.rank) == NightState.rank_for(int(r.score)),
		"scored as the night, not the last act")
	t.check(String(r.reason) == "citadel", "and ends on the last act's reason")
	# v0.10 M5: a night of one unscored act (the campaign's Feast) has the act's own goal, bonuses and time, and no rank.
	var one := NightState.new()
	var act := {"won": true, "reason": "festival", "time": 96.0, "bonuses": [{"label": "Before the bell", "earned": true}],
		"goal": {"label": "The festival is broken", "done": true}}
	one.record("festival", act, null)
	var fr := one.result(act, "feast_festival", false)
	t.check(not fr.has("score") and not fr.has("rank") and fr.won and String(fr.reason) == "festival"
		and String(fr.goal.label) == "The festival is broken" and (fr.bonuses as Array).size() == 1
		and is_equal_approx(float(fr.time), 96.0) and (fr.acts as Array).size() == 1,
		"an unscored night of one act: its own goal, bonus and time, no rank (%s)" % [fr.keys()])
	t.check(n.result(final, "long_night").has("rank"), "The Long Night keeps its rank")

	# v0.09.1: losing an act caps the night's rank at B; S and A need all three acts. 30000 is an S's floor.
	var lost := NightState.new()
	lost.record("omen", {"won": true, "time": 20.0, "bonuses": []}, null)
	lost.record("festival", {"won": false, "time": 150.0, "bonuses": []}, null)
	var last := {"won": true, "reason": "citadel", "time": 250.0, "score": 30000 - 2 * NightState.ACT_POINTS,
		"lines": [], "bonuses": []}
	lost.record("judgement", last, null)
	var capped := lost.result(last, "long_night")
	t.check(int(capped.score) == 30000 and String(capped.rank) == "B",
		"an act lost at 30000 points: a B, not an S (%d, %s)" % [int(capped.score), capped.rank])
	var all_won := NightState.new()
	all_won.record("omen", {"won": true, "time": 20.0, "bonuses": []}, null)
	all_won.record("festival", {"won": true, "time": 95.0, "bonuses": []}, null)
	var last3 := last.duplicate()
	last3.score = 30000 - 3 * NightState.ACT_POINTS
	all_won.record("judgement", last3, null)
	var full := all_won.result(last3, "long_night")
	t.check(int(full.score) == 30000 and String(full.rank) == "S", "all three won at 30000: an S (%d, %s)"
		% [int(full.score), full.rank])
	var low := NightState.new()
	low.record("omen", {"won": false, "time": 25.0, "bonuses": []}, null)
	var c_final := {"won": false, "reason": "timeout", "time": 300.0, "score": 8000, "lines": [], "bonuses": []}
	low.record("judgement", c_final, null)
	t.check(String(low.result(c_final, "long_night").rank) == NightState.rank_for(low.night_score(8000)),
		"under a B the cap changes nothing (%s)" % low.result(c_final, "long_night").rank)
	var feast_lost := NightState.new()
	var fl := {"won": false, "reason": "closed", "time": 150.0, "bonuses": [], "goal": {"label": "x", "done": false}}
	feast_lost.record("festival", fl, null)
	t.check(not feast_lost.result(fl, "feast_festival", false).has("rank"), "an unscored night still has no rank")

	# v0.09.1: the Banishing Rite costs 20 s in The Long Night's acts, BanishingRite.PENALTY (40) everywhere else.
	for row in [[m.act("judgement"), 20.0], [m.act("festival"), 20.0], [MissionBook.last_judgement(), BanishingRite.PENALTY],
			[MissionBook.warning(), BanishingRite.PENALTY]]:
		var rules := Rules.new()
		rules.mission = row[0]
		rules.time_left = 100.0
		var cost := rules.banish()
		t.check(is_equal_approx(cost, float(row[1])) and is_equal_approx(rules.time_left, 100.0 - float(row[1])),
			"a completed rite in %s takes %d s (%.1f, %.1f left)" % [(row[0] as MissionDef).id, roundi(float(row[1])), cost,
			rules.time_left])
		rules.free()

	# The town each act wants: Act I asleep; a rung bell wakes Act II; the Procession's outcome sets Act III.
	var asleep := NightState.new()
	t.check(m.act("festival").town(asleep).tier_name() == "Unaware", "no bell in Act I: Act II's town still sleeps")
	asleep.bell_rang = true
	t.check(m.act("festival").town(asleep).tier == ResponseProfile.Tier.ORGANIZED
		and m.act("festival").town(asleep).title == "", "a rung bell: Organized")
	var seen := NightState.new()
	seen.prince = "seen"
	t.check(m.act("judgement").town(seen).tier == ResponseProfile.Tier.PREPARED, "a seen killing: Prepared")
	var unseen := NightState.new()
	unseen.prince = "unseen"
	t.check(m.act("judgement").town(unseen).tier == ResponseProfile.Tier.ORGANIZED, "unseen: Organized")
	# Act III's escape limit comes from the night it is given.
	var j := m.act("judgement")
	j.night = n
	var limit := -1
	for o in j.objectives():
		if o is EscapeLimitObjective:
			limit = (o as EscapeLimitObjective).limit
	t.check(limit == NightState.PRINCE_ESCAPED_LIMIT, "Act III's escape limit is the night's (%d)" % limit)

	# Prepare between acts (v0.09) shows the town the act will play: an act's response profile is its town for the
	# night so far, whatever difficulty is passed; the mission itself still shows Unaware on the board and first Prepare.
	var ln := MissionBook.long_night()
	var fest := ln.act("festival")
	fest.night = NightState.new()
	fest.night.bell_rang = true
	var warned := fest.response_profile(ResponseProfile.Tier.PREPARED)
	t.check(warned.tier == ResponseProfile.Tier.ORGANIZED and warned.title == "",
		"after a rung bell the Festival's Prepare shows Organized (%s)" % warned.tier_name())
	fest.night = NightState.new()
	t.check(fest.response_profile(ResponseProfile.Tier.ORGANIZED).tier_name() == "Unaware",
		"with a quiet night it shows Unaware (%s)" % fest.response_profile(ResponseProfile.Tier.ORGANIZED).tier_name())
	fest.night = null
	t.check(fest.response_profile(ResponseProfile.Tier.ORGANIZED).tier_name() == "Unaware",
		"and with no night yet, a fresh night's town")
	t.check(ln.response_profile(ResponseProfile.Tier.PREPARED).tier_name() == "Unaware",
		"the Long Night itself still shows Unaware on the board and the first Prepare")
