extends RefCounted
## v0.08 missions as data: Last Judgement keeps today's mission -- every power, its clock, the chosen difficulty, the
## Citadel's objectives in today's order -- and an unknown id falls back to it.


static func run(t) -> void:
	var lj := MissionBook.get_mission(MissionBook.LAST_JUDGEMENT)
	t.check(lj != null and lj.id == "last_judgement" and lj.tier == 5 and lj.scored, "Last Judgement is a scored Tier 5")
	t.near(lj.clock, Rules.MISSION_SECONDS, 0.001, "on today's clock")
	t.check(lj.powers() == PowerBook.keys(), "every power is in its pool")
	t.check(lj.chooses_difficulty() and lj.director == null, "the player picks its difficulty, and it has no director")
	t.check(lj.response_profile(ResponseProfile.Tier.PREPARED).tier == ResponseProfile.Tier.PREPARED,
		"its town is the chosen tier")
	var reasons := []
	for o in lj.objectives():
		reasons.append(o.reason)
	t.check(reasons == ["citadel", "escapes", "timeout"], "its objectives in today's order (%s)" % [reasons])
	t.check(lj.objectives()[0] != lj.objectives()[0], "each mission gets fresh objectives")
	t.check(lj.bonuses().is_empty(), "and no bonus")
	t.check(Array(lj.default_loadout) == Mission.DEFAULT_LOADOUT, "its default loadout is today's four")
	t.check(MissionBook.get_mission("nonsense").id == MissionBook.LAST_JUDGEMENT, "an unknown id is Last Judgement")
	var ids := []
	for m in MissionBook.all():
		ids.append(m.id)
	t.check(ids == ["warning", "long_night", "last_judgement"], "the book lists them lowest Tier first (%s)" % [ids])

	# The Warning (v0.08 M4): Tier 1, its own small pool and an Unaware town, first on the board.
	var w := MissionBook.warning()
	t.check(w.id == MissionBook.WARNING and w.tier == 1 and w.slots == 3 and w.dp_capacity == 6,
		"The Warning is Tier 1, 3 slots, 6 DP")
	t.check(Array(w.powers()) == ["whisper", "doom", "wisp", "discord"], "its pool is the four small powers (%s)"
		% [w.powers()])
	t.check(not w.allows("thorns") and lj.allows("thorns"), "Thornwall is Last Judgement's only (v0.08.1)")
	t.near(w.clock, 120.0, 0.001, "on a 2:00 clock")
	t.check(w.profile == "unaware" and not w.chooses_difficulty() and not w.scored and w.director == WarningDirector,
		"an Unaware town, unscored, with WarningDirector")
	t.check(w.response_profile(ResponseProfile.Tier.GOD_RESISTANT).tier_name() == "Unaware", "whatever difficulty was chosen")
	var w_reasons := []
	for o in w.objectives():
		w_reasons.append(o.reason)
	t.check(w_reasons == ["warning", "bell", "omen"], "its objectives in order (%s)" % [w_reasons])
	t.check(w.bonuses().size() == 1 and w.bonuses()[0].label == "Unseen", "one bonus, Unseen")
	t.check(MissionBook.all()[0].id == MissionBook.WARNING and MissionBook.get_mission(MissionBook.WARNING).id == "warning",
		"it is first in the book")
	for key in w.default_loadout:
		t.check(w.allows(key), "its default loadout is in its pool (%s)" % key)

	# The Lantern campaign's missions (v0.10): found by their ids, never on the board.
	var board := []
	for m in MissionBook.all():
		board.append(m.id)
	for id in [MissionBook.MIRAS_HOUSE, MissionBook.VIGIL_FLAME, MissionBook.BROKEN_LANTERNS,
			MissionBook.FEAST_FESTIVAL, MissionBook.FEAST_PROCESSION]:
		t.check(MissionBook.get_mission(id).id == id, "the campaign's %s is found by its id" % id)
		t.check(not board.has(id), "and it is not on the board (%s)" % id)
	t.check(board == ["warning", "long_night", "last_judgement"], "the board lists what it did (%s)" % [board])

	# Night 2's placeholders (M1): Tier 2, an Unaware town, unscored, held until dawn.
	var mh := MissionBook.miras_house()
	var mh_reasons := []
	for o in mh.objectives():
		mh_reasons.append(o.reason)
	t.check(mh.tier == 2 and mh.profile == "unaware" and not mh.scored and mh.director == MirasHouseDirector
		and mh_reasons == ["gaze", "believers"] and is_equal_approx(mh.clock, 150.0),
		"Mira's House is Tier 2, Unaware, on 2:30, lost to the Gaze, won by Believers (%s)" % [mh_reasons])
	var vf := MissionBook.vigil_flame()
	var held := []
	for o in vf.objectives():
		held.append(o.reason)
	t.check(vf.director == null and held == ["held"], "the Vigil Flame is still a placeholder held until dawn")
	t.check(Array(mh.powers()) == MissionBook.VIGIL_POOL and Array(MissionBook.vigil_flame().powers()) == MissionBook.VIGIL_POOL,
		"Mira's House and the Vigil Flame draft from the quiet five (%s)" % [mh.powers()])
	var bl := MissionBook.broken_lanterns()
	t.check(bl.allows("thorns") and bl.allows("heaven") and bl.allows("gravity") and not bl.allows("nova"),
		"Broken Lanterns adds four Ruin powers, not Nova")
	var bl_reasons := []
	for o in bl.objectives():
		bl_reasons.append(o.reason)
	var bl_dp := 0
	for key in bl.default_loadout:
		bl_dp += int(PowerBook.get_power(key).dp)
	t.check(bl.tier == 2 and bl.profile == "unaware" and not bl.scored and bl.director == BrokenLanternsDirector
		and bl_reasons == ["drained", "bell", "gaze", "relit"] and is_equal_approx(bl.clock, 180.0),
		"Broken Lanterns is Tier 2, Unaware, on 3:00: won by six drained, lost to the bell, the Gaze or dawn (%s)" % [bl_reasons])
	t.check(bl_dp <= 5 and Array(bl.default_loadout).all(func(k: String) -> bool: return bl.allows(k)),
		"its default loadout is in its pool and fits a bitten Night 2's 5 DP (%d)" % bl_dp)
	t.check(ResultsScreen.title_for(true, "held") == "THE NIGHT PASSES", "a held night has its own title")

	# Night 3, the Feast (v0.10): one of The Long Night's middle acts as a night of one act.
	var fe := MissionBook.feast("festival")
	t.check(fe.id == MissionBook.FEAST_FESTIVAL and fe.name == "The Festival" and fe.tier == 3 and fe.has_acts()
		and fe.acts.size() == 1 and fe.first_act().id == "festival" and fe.first_act().is_last()
		and fe.first_act().director == FestivalDirector, "the Feast's Festival is The Long Night's act, alone and last")
	t.check(MissionBook.feast("procession").first_act().director == ProcessionDirector, "and so is the Procession")
	var warned := NightState.new()
	warned.bell_rang = true
	fe.first_act().night = warned
	t.check(fe.response_profile(ResponseProfile.DEFAULT).tier == ResponseProfile.Tier.ORGANIZED,
		"after a rung bell the Feast's Prepare shows the Organized town")
	t.check(MissionBook.long_night().response_profile(ResponseProfile.DEFAULT).tier_name() == "Unaware",
		"The Long Night still opens on a sleeping town")
