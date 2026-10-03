class_name MissionBook
extends RefCounted
## The missions (v0.08), the way PowerBook lists the powers, lowest Tier first: The Warning, the god's first stirring
## (Tier 1), and Last Judgement, v0.07's mission as a Tier 5 Skirmish.

const WARNING := "warning"
const LAST_JUDGEMENT := "last_judgement"


static func all() -> Array[MissionDef]:
	var out: Array[MissionDef] = [warning(), last_judgement()]
	return out


## The mission with this id; an unknown id gives Last Judgement.
static func get_mission(id: String) -> MissionDef:
	for m in all():
		if m.id == id:
			return m
	return last_judgement()


## The Warning (v0.08 M4): a star falls over the Main Gate and a watchman runs to wake the bell; kill whoever carries
## the warning unseen, or hold it off until the omen fades (WarningDirector).
static func warning() -> MissionDef:
	var m := MissionDef.new()
	m.id = WARNING
	m.name = "The Warning"
	m.tier = 1
	m.brief = PackedStringArray(["A star falls over the Main Gate.", "A watchman runs to wake the bell."])
	m.goal = "Stop the warning before the bell tolls, or until the omen fades"
	m.goal_label = "Stop the warning"
	m.slots = 3
	m.dp_capacity = 6
	m.pool = PackedStringArray(["whisper", "doom", "wisp", "discord", "thorns"])
	m.clock = 120.0
	m.profile = "unaware"
	m.intro_from = TownLayout.MAIN_GATE.get_center() + Vector2(0.0, 6.0)
	m.camera_at = TownLayout.MAIN_GATE.get_center().lerp(TownLayout.BELL_TOWER.get_center(), 0.35)
	m.intro_banner = "THE FIRST STIRRING"
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.director = WarningDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [WarningObjective.new(), BellSilentObjective.new(),
			ClockObjective.new(true, "Omen fades", "omen")]
		return out
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [UnseenObjective.new()]
		return out
	return m


static func last_judgement() -> MissionDef:
	var m := MissionDef.new()
	m.id = LAST_JUDGEMENT
	m.name = "Last Judgement"
	m.tier = 5
	m.brief = PackedStringArray(["Aldermere and its Royal Citadel.", "Bring the whole kingdom down."])
	m.goal = "Destroy the Citadel and break the city before %s" % UiTheme.clock(Rules.MISSION_SECONDS)
	m.goal_label = "The city has fallen"
	m.slots = 6
	m.dp_capacity = 14
	m.clock = Rules.MISSION_SECONDS
	m.scored = true
	m.default_loadout = PackedStringArray(Mission.DEFAULT_LOADOUT)
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [CitadelObjective.new(), EscapeLimitObjective.new(), ClockObjective.new()]
		return out
	return m
