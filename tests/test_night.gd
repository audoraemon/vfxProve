extends RefCounted
## v0.09 The Long Night as data: three acts with a choice after the first, the town each act wants given the night so
## far, what carries between acts, and the night's score and rank.


static func run(t) -> void:
	var m := MissionBook.long_night()
	t.check(m.id == "long_night" and m.tier == 3 and m.has_acts() and not m.chooses_difficulty(),
		"The Long Night is a Tier 3 mission in acts, its town set by the night")
	t.check(m.slots == 4 and m.dp_capacity == 10 and m.powers() == PowerBook.keys(), "4 slots, 10 DP, every power")
	var first := m.first_act()
	t.check(first.id == "omen" and Array(first.next) == ["festival", "procession"], "Act I leads to a choice of two")
	t.check(Array(m.act("festival").next) == ["judgement"] and Array(m.act("procession").next) == ["judgement"],
		"both paths lead to Judgement")
	t.check(m.act("judgement").is_last() and not first.is_last(), "Judgement is the last act")
	t.check(m.act("nonsense") == null, "an unknown act is null")
	t.near(first.clock, 120.0, 0.001, "Act I is two minutes")
	t.near(m.act("judgement").clock, 180.0, 0.001, "Act III is three")
	t.check(MissionBook.all()[1].id == "long_night", "the board lists it between The Warning and Last Judgement")

	# The night remembers what each act did.
	var n := NightState.new()
	n.record("omen", {"won": true, "reason": "warning", "time": 40.0, "bonuses": [{"label": "Unseen", "earned": true}]}, null)
	n.path = "procession"
	n.record("procession", {"won": false, "reason": "sailed", "time": 150.0, "bonuses": [], "prince": "escaped"}, null)
	t.check(n.acts_won() == 1 and n.bonuses_earned() == 1, "one act won, one bonus (%d, %d)" % [n.acts_won(), n.bonuses_earned()])
	t.check(n.prince == "escaped" and n.escape_limit() == NightState.PRINCE_ESCAPED_LIMIT,
		"the Prince escaping lowers Act III's escape limit to 40")
	t.check(NightState.new().escape_limit() == Rules.ESCAPE_LIMIT, "otherwise it is 50")
	t.check(n.act_result("omen").reason == "warning" and n.act_result("judgement").is_empty(), "results by act")
	t.check(n.night_score(9000) == 9000 + NightState.ACT_POINTS + NightState.BONUS_POINTS, "the night's score")
	t.check(NightState.rank_for(20000) == "S" and NightState.rank_for(4999) == "D", "and its rank")
	var final := {"won": true, "reason": "citadel", "time": 170.0, "score": 9000, "lines": [], "bonuses": []}
	var r := n.result(final, "long_night")
	t.check(r.mission == "long_night" and r.won and r.path == "procession" and (r.acts as Array).size() == 2,
		"the night's result keeps every act and the path")
	t.check(int(r.score) == n.night_score(9000) and String(r.rank) == NightState.rank_for(int(r.score)),
		"scored as the night, not the last act")
	t.check(String(r.reason) == "citadel", "and ends on the last act's reason")

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
	t.check(limit == 40, "Act III's escape limit is the night's (%d)" % limit)
