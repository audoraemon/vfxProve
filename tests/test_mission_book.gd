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
	t.check(ids.has(MissionBook.LAST_JUDGEMENT), "the book lists it (%s)" % [ids])

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
