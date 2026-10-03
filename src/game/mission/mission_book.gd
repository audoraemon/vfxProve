class_name MissionBook
extends RefCounted
## The missions (v0.08), the way PowerBook lists the powers. Last Judgement is v0.07's mission as a Tier 5 Skirmish;
## The Warning (Tier 1) joins it in M4.

const LAST_JUDGEMENT := "last_judgement"


static func all() -> Array[MissionDef]:
	var out: Array[MissionDef] = [last_judgement()]
	return out


## The mission with this id; an unknown id gives Last Judgement.
static func get_mission(id: String) -> MissionDef:
	for m in all():
		if m.id == id:
			return m
	return last_judgement()


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
