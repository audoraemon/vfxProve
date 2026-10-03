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
