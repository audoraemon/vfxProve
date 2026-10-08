class_name MissionBook
extends RefCounted
## The missions (v0.08), the way PowerBook lists the powers, lowest Tier first: The Warning, the god's first stirring
## (Tier 1), The Long Night (v0.09, Tier 3), and Last Judgement, v0.07's mission as a Tier 5 Skirmish.

const WARNING := "warning"
const LONG_NIGHT := "long_night"
const LAST_JUDGEMENT := "last_judgement"
## The Lantern campaign's own missions (v0.10): Night 2's three, one per path, and Night 3's two Feast nights.
const MIRAS_HOUSE := "miras_house"
const VIGIL_FLAME := "vigil_flame"
const BROKEN_LANTERNS := "broken_lanterns"
const FEAST_FESTIVAL := "feast_festival"
const FEAST_PROCESSION := "feast_procession"
## The tier board's own missions (v0.11 M2): Tier 1's four new ones.
const TAX_COLLECTOR := "tax_collector"
## The Vigil's pools (v0.10 spec §4.1): the quiet five, and for Broken Lanterns four Ruin powers besides.
const VIGIL_POOL := ["whisper", "doom", "wisp", "discord", "thorns"]
const RUIN_POOL := ["heaven", "tornado", "dragon", "gravity"]
## Seconds a completed Banishing Rite takes off the clock in The Long Night's acts (v0.09.1); every other mission keeps
## BanishingRite.PENALTY.
const NIGHT_RITE_PENALTY := 20.0


static func all() -> Array[MissionDef]:
	var out: Array[MissionDef] = [warning(), long_night(), last_judgement()]
	return out


## The mission with this id, on the board or in the campaign; an unknown id gives Last Judgement.
static func get_mission(id: String) -> MissionDef:
	for m in all():
		if m.id == id:
			return m
	for m in campaign_missions():
		if m.id == id:
			return m
	for m in tier_missions():
		if m.id == id:
			return m
	return last_judgement()


## The Lantern campaign's missions (v0.10): played from the campaign's night screen, never listed on the board.
static func campaign_missions() -> Array[MissionDef]:
	var out: Array[MissionDef] = [miras_house(), vigil_flame(), broken_lanterns(), feast("festival"), feast("procession")]
	return out


## The tier board's own missions (v0.11 M2 on), each made at its tier's numbers -- clock, town, slots and DP, no bonuses -- so
## TierBook.board() only stamps its tier and the god's upgrades on it. Never in all() (the v0.09 interlude's list) nor the
## campaign's.
static func tier_missions() -> Array[MissionDef]:
	var out: Array[MissionDef] = [tax_collector()]
	return out


## A Tier 1 (Whisper) mission's frame (v0.11 M2, spec §4): an Unaware town, 3 slots and 6 DP, a 5:00 clock, no bonuses, every
## power allowed (the board's draft locks what the god has not unlocked).
static func _tier1(id: String, name: String, brief: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 1
	m.brief = brief
	m.slots = 3
	m.dp_capacity = 6
	m.clock = 300.0
	m.profile = "unaware"
	m.intro_banner = name.to_upper()
	return m


## The Tax Collector (v0.11 M2, Tier 1, spec §8 row 2; three collectors by the controller's Task 2 ruling): kill the tax
## collector and his two deputies on their rounds before any takes the taxes into the Citadel (TaxCollectorDirector). A seen
## kill still counts, but calls the bell.
static func tax_collector() -> MissionDef:
	var m := _tier1(TAX_COLLECTOR, "The Tax Collector", PackedStringArray(["The tax collector and his deputies make their rounds.",
		"Strike all three down before the taxes reach the Citadel."]))
	m.goal = "Kill the tax collector and his two deputies before the taxes reach the Citadel"
	m.goal_label = "The collectors are dead"
	m.lose = "A collector reaches the Citadel, the bell tolls, or dawn comes"
	m.camera_at = TownLayout.WORKSHOP.get_center() + Vector2(-2.0, 3.0)
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "discord", "whisper"])
	m.director = TaxCollectorDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [AssassinateObjective.new("Kill the collectors", "collector", "taxes"),
			BellSilentObjective.new(), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Warning (v0.08 M4): a star falls over the Main Gate and a watchman runs to wake the bell; kill whoever carries
## the warning unseen (WarningDirector). v0.08.1 left Thornwall out of its pool: a 3-unit wall is walked round in at most
## 1.5 s, once a mission -- a Last Judgement tool (gates, evacuees). v0.11 M1 (no waiting, spec §7.3): holding the warning
## off until the omen fades no longer wins; dawn with the warning alive loses, as any other dawn does.
static func warning() -> MissionDef:
	var m := MissionDef.new()
	m.id = WARNING
	m.name = "The Warning"
	m.tier = 1
	m.brief = PackedStringArray(["A star falls over the Main Gate.", "A watchman runs to wake the bell."])
	m.goal = "Stop the warning before the bell tolls"
	m.goal_label = "Stop the warning"
	m.lose = "The bell tolls, or dawn comes with the warning alive"
	m.slots = 3
	m.dp_capacity = 6
	m.pool = PackedStringArray(["whisper", "doom", "wisp", "discord"])
	m.clock = 120.0
	m.profile = "unaware"
	m.intro_from = TownLayout.MAIN_GATE.get_center() + Vector2(0.0, 6.0)
	m.camera_at = TownLayout.MAIN_GATE.get_center().lerp(TownLayout.BELL_TOWER.get_center(), 0.35)
	m.intro_banner = "THE FIRST STIRRING"
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.director = WarningDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [WarningObjective.new(), BellSilentObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
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
	m.lose = "%d citizens escape, or the time runs out" % Rules.ESCAPE_LIMIT
	m.slots = 6
	m.dp_capacity = 14
	m.clock = Rules.MISSION_SECONDS
	m.scored = true
	m.default_loadout = PackedStringArray(Mission.DEFAULT_LOADOUT)
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [CitadelObjective.new(), EscapeLimitObjective.new(), ClockObjective.new()]
		return out
	# It runs no actors: it only tags the Citadel and the ways out (board tags).
	m.director = LastJudgementDirector
	return m


## The Long Night (v0.09, Tier 3): three acts in one town. Act I is The Warning; the choice card picks the Festival
## or the Procession; Act III is Judgement in the town the night has made. v0.09.1: the god grows through the night --
## each act has its own slots and DP (Act I 3 / 6, as The Warning; Act II 4 / 10; Act III 4 / 14), and the night itself
## (the board card, the first Prepare) shows Act I's.
static func long_night() -> MissionDef:
	var m := MissionDef.new()
	m.id = LONG_NIGHT
	m.name = "The Long Night"
	m.tier = 3
	m.brief = PackedStringArray(["Three acts, one night.", "Your choices shape the town you face."])
	m.goal = "Stop the warning, strike the town's heart, then bring the Citadel down by dawn"
	m.goal_label = "The night is yours"
	m.lose = "The town holds until dawn"
	m.slots = 3
	m.dp_capacity = 6
	m.clock = 120.0
	m.profile = "night"
	m.scored = true
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.intro_from = TownLayout.MAIN_GATE.get_center() + Vector2(0.0, 6.0)
	m.camera_at = TownLayout.MAIN_GATE.get_center().lerp(TownLayout.BELL_TOWER.get_center(), 0.35)
	m.acts = [_omen(m), _festival(m), _procession(m), _judgement(m)]
	m.make_objectives = (m.acts[0] as ActDef).make_objectives
	m.make_bonuses = (m.acts[0] as ActDef).make_bonuses
	return m


## An act with the night's loadout rules, and its own `slots` and `dp` (v0.09.1); the rite costs NIGHT_RITE_PENALTY.
static func _act(m: MissionDef, id: String, name: String, clock: float, slots: int, dp: int) -> ActDef:
	var a := ActDef.new()
	a.id = id
	a.name = name
	a.tier = m.tier
	a.slots = slots
	a.dp_capacity = dp
	a.clock = clock
	a.rite_penalty = NIGHT_RITE_PENALTY
	a.profile = "night"
	a.default_loadout = m.default_loadout
	return a


static func _omen(m: MissionDef) -> ActDef:
	var w := warning()
	var a := _act(m, "omen", "Act I: The Omen", 120.0, w.slots, w.dp_capacity)
	a.brief = w.brief
	a.goal = w.goal
	a.goal_label = w.goal_label
	a.lose = w.lose
	a.intro_from = w.intro_from
	a.camera_at = w.camera_at
	a.intro_banner = "ACT I - THE OMEN"
	a.director = WarningDirector
	a.make_objectives = w.make_objectives
	a.make_bonuses = w.make_bonuses
	a.next = PackedStringArray(["festival", "procession"])
	a.make_town = func(_n: NightState) -> ResponseProfile: return ResponseProfile.unaware()
	return a


## The town Act II meets: still asleep if the warning died, Organized if the bell rang.
static func _act2_town(n: NightState) -> ResponseProfile:
	return ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED) if n.bell_rang else ResponseProfile.unaware()


static func _festival(m: MissionDef) -> ActDef:
	var a := _act(m, "festival", "Act II: The Festival", 150.0, 4, 10)
	a.brief = PackedStringArray(["The market fills for the Feast of Lanterns.", "Break the festival."])
	a.goal = "Break the festival before the guard closes the square"
	a.goal_label = "The festival is broken"
	a.lose = "The guard closes the square with the festival unbroken"
	a.camera_at = TownLayout.MARKET_SQUARE.get_center()
	a.intro_from = TownLayout.MARKET_SQUARE.get_center() + Vector2(0.0, 8.0)
	a.intro_banner = "ACT II - THE FESTIVAL"
	a.next = PackedStringArray(["judgement"])
	a.make_town = _act2_town
	a.director = FestivalDirector
	a.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [FestivalObjective.new(), ClockObjective.new(false, "Square closes", "closed")]
		return out
	a.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [BellQuietObjective.new()]
		return out
	a.events_text = PackedStringArray(["0:45 The bonfire lights", "1:30 The Mayor's address", "2:30 The guard closes the square"])
	a.make_card_line = func(n: NightState) -> String:
		return "The bell rang: soldiers watch the square." if n.bell_rang else "The town suspects nothing."
	return a


static func _procession(m: MissionDef) -> ActDef:
	var a := _act(m, "procession", "Act II: The Procession", 150.0, 4, 10)
	a.brief = PackedStringArray(["The Prince leaves the Citadel for the ship.", "Stop him before he sails."])
	a.goal = "Kill the Prince before he sails"
	a.goal_label = "The Prince is dead"
	a.lose = "The Prince boards the ship, or the last tide comes"
	a.camera_at = TownLayout.CITADEL_ORIGIN.lerp(TownLayout.DOCK.get_center(), 0.3)
	a.intro_from = TownLayout.CITADEL_ORIGIN
	a.intro_banner = "ACT II - THE PROCESSION"
	a.next = PackedStringArray(["judgement"])
	a.make_town = _act2_town
	a.director = ProcessionDirector
	a.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [PrinceObjective.new(), ClockObjective.new(false, "The tide", "tide")]
		return out
	a.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [QuietSuccessionObjective.new()]
		return out
	a.events_text = PackedStringArray(["1:00 The blessing", "2:00 The ship docks", "2:30 The last tide"])
	a.make_card_line = func(n: NightState) -> String:
		return "The bell rang: his escort is wary." if n.bell_rang else "The Prince travels light."
	return a


## The town Act III meets (spec §2): the Procession's outcome decides it; otherwise Organized.
static func _act3_town(n: NightState) -> ResponseProfile:
	if n.prince == "seen" or n.prince == "escaped":
		return ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	return ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED)


## Act III's clock is five minutes (v0.09 Task 19): breaking the whole city's stability with the night's DP took a
## measured policy four to four and a half.
static func _judgement(m: MissionDef) -> ActDef:
	var a := _act(m, "judgement", "Act III: Judgement", 300.0, 4, 14)
	a.brief = PackedStringArray(["Dawn is coming.", "Bring the Citadel down before it does."])
	a.goal = "Destroy the Citadel and break the city before dawn"
	a.goal_label = "The city has fallen"
	a.lose = "The people escape, or dawn comes"
	a.scored = true
	a.intro_from = TownLayout.MAIN_GATE.get_center()
	a.camera_at = TownLayout.CITADEL_ORIGIN
	a.intro_banner = "ACT III - JUDGEMENT"
	a.make_town = _act3_town
	a.make_act_objectives = func(n: NightState) -> Array[Objective]:
		var out: Array[Objective] = [CitadelObjective.new(), EscapeLimitObjective.new(n.escape_limit()), ClockObjective.new()]
		return out
	a.make_act_bonuses = func(_n: NightState) -> Array[Objective]:
		var out: Array[Objective] = [DawnObjective.new()]
		return out
	a.director = JudgementDirector
	# Only a Prepared town has the rite and the boats (an Organized one has neither), so each window says so.
	a.events_text = PackedStringArray(["1:30 The clergy gather (if Prepared)", "2:00 The boats sail (if Prepared)",
		"2:30 The last ferry leaves (if Prepared)"])
	a.make_card_line = _judgement_line
	return a


## Act III's line on the interlude (v0.09): how the town will meet the player, by how Act II ended.
static func _judgement_line(n: NightState) -> String:
	match n.prince:
		"escaped":
			return "The Prince escaped: the kingdom rallies and is ready."
		"seen":
			return "The Prince's death was seen: the town is ready for you."
		"unseen":
			return "The Prince is gone unseen: the town is leaderless."
	match n.festival:
		"broken":
			return "The feast broke: its crowd still flees into the gates."
		"held":
			return "The feast held: the soldiers take the gates."
	return "Dawn is coming."


## Night 2 of the campaign, the Vigil (v0.10): one mission per path. Mira's House (the Faith path, M2) leads four of the
## grieving to Mira's journal unseen, before dawn (MirasHouseDirector); Broken Lanterns (the Ruin path) is M3's, and the
## Vigil Flame (the Theft path) M4's.
static func miras_house() -> MissionDef:
	var m := _vigil(MIRAS_HOUSE, "Mira's House", PackedStringArray(["Her journal waits in a shuttered house.",
		"Lead the grieving to it unseen."]), PackedStringArray(VIGIL_POOL))
	m.goal = "Lead four of the grieving to Mira's journal, unseen, before dawn"
	m.goal_label = "Four believe"
	m.lose = "The Lantern looks, or fewer than four believe by dawn"
	m.clock = 150.0
	m.camera_at = MirasHouseDirector.MIRA_SPOT
	m.intro_from = MirasHouseDirector.MIRA_SPOT + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "wisp", "discord"])
	m.director = MirasHouseDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), BelieversObjective.new()]
		return out
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [PureFaithObjective.new(), JournalObjective.new()]
		return out
	return m


## Night 2 of the campaign, the Theft path (v0.10 M4): Wren swaps Halcyon's flame out of the Vigil's lantern unseen and
## carries it to Mira's shrine under the Searchlight (VigilFlameDirector). The default loadout costs 5 DP, so it fits a
## Night 2 after a bite.
static func vigil_flame() -> MissionDef:
	var m := _vigil(VIGIL_FLAME, "The Vigil Flame", PackedStringArray(["A priest carries Halcyon's flame.",
		"A mortal hand must steal it."]), PackedStringArray(VIGIL_POOL))
	m.goal = "Have Wren swap Halcyon's flame unseen, and carry it to Mira's shrine under the searchlight"
	m.goal_label = "The flame is stolen"
	m.lose = "The Lantern looks, Wren dies, the flame goes home to the Temple, or dawn comes first"
	m.clock = 180.0
	m.camera_at = VigilFlameDirector.CAMERA_AT
	m.intro_from = VigilFlameDirector.CAMERA_AT + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "wisp"])
	m.director = VigilFlameDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), FlameObjective.new(), ClockObjective.new(false, "Dawn", "late")]
		return out
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [UnseenHandsObjective.new()]
		return out
	return m


## Night 2 of the campaign, the Ruin path (v0.10 M3): break Halcyon's six wayside shrines and let them drain before the
## Vigil relights them (BrokenLanternsDirector). The default loadout costs 5 DP, so it fits a Night 2 after a bite.
static func broken_lanterns() -> MissionDef:
	var m := _vigil(BROKEN_LANTERNS, "Broken Lanterns", PackedStringArray(["Six shrines anchor the Lantern.",
		"Break them before they are relit."]), PackedStringArray(VIGIL_POOL + RUIN_POOL))
	m.goal = "Break Halcyon's six shrines, and let them drain before the Vigil relights them"
	m.goal_label = "The lanterns are dark"
	m.lose = "The bell tolls, the Lantern looks, or dawn finds a shrine still lit"
	m.clock = 180.0
	m.camera_at = BrokenLanternsDirector.CAMERA_AT
	m.intro_from = BrokenLanternsDirector.CAMERA_AT + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["heaven", "doom", "discord"])
	m.director = BrokenLanternsDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [ShrinesObjective.new(), BellSilentObjective.new(), GazeObjective.new(),
			ClockObjective.new(false, "Dawn", "relit")]
		return out
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [ThroughFaithfulObjective.new()]
		return out
	return m


static func _vigil(id: String, name: String, brief: PackedStringArray, pool: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 2
	m.brief = brief
	m.goal = "Hold until dawn: this night is still being built"
	m.goal_label = "Dawn comes"
	m.lose = "Nothing yet"
	m.slots = 3
	m.dp_capacity = 8
	m.pool = pool
	m.clock = 120.0
	m.profile = "unaware"
	m.intro_banner = name.to_upper()
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [ClockObjective.new(true, "Dawn", "held")]
		return out
	return m


## Night 3 of the campaign, the Feast of Lanterns (v0.10): one of The Long Night's middle acts played on its own, as a
## night of one act. Its town comes from Night 1 through Mission.bell_rang; the act's rules are unchanged.
## Its results are its act's own (an unscored night): a one-act night cannot reach the three-act ranks.
static func feast(act_id: String) -> MissionDef:
	var ln := long_night()
	var a := ln.act(act_id)
	a.next = PackedStringArray()
	a.rite_penalty = BanishingRite.PENALTY  # the 20 s rite is The Long Night's (v0.09.1): the campaign keeps 40
	var m := MissionDef.new()
	m.id = "feast_" + act_id
	m.name = a.name.trim_prefix("Act II: ")
	m.tier = 3
	m.brief = a.brief
	m.goal = a.goal
	m.goal_label = a.goal_label
	m.lose = a.lose
	m.slots = 4
	m.dp_capacity = 10
	m.clock = a.clock
	m.profile = "night"
	m.scored = false  # one act, unscored (v0.10 M5): the campaign never used the score
	m.default_loadout = ln.default_loadout
	m.intro_from = a.intro_from
	m.camera_at = a.camera_at
	a.intro_banner = "NIGHT 3 - " + m.name.to_upper()
	m.intro_banner = a.intro_banner
	m.acts = [a]
	m.make_objectives = a.make_objectives
	m.make_bonuses = a.make_bonuses
	return m
