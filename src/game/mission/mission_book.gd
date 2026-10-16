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
const SPOILED_HARVEST := "spoiled_harvest"
const LOST_LAMB := "lost_lamb"
const FIRST_PRAYERS := "first_prayers"
## The tier board's own missions (v0.11 M3): Tier 2's three new ones.
const BELL_RINGERS := "bell_ringers"
const MARKET_PANIC := "market_panic"
const INFORMER := "informer"
## The new Tier 3 missions (v0.11 M4, mission spec §1-§3), built by tier_missions() at Tier 3's numbers.
const CROWNS_BREAD := "crowns_bread"
const PRISONER := "prisoner"
const HERETIC_HUNT := "heretic_hunt"
## The new Tier 4 missions (v0.11 M5, mission spec §1-§4), built by tier_missions() at Tier 4's numbers.
const BISHOP := "bishop"
const ARMOURY := "armoury"
const SERMON := "sermon"
const RELIC_RUN := "relic_run"
## The new Tier 5 missions (v0.11 M6, mission spec §1-§3), built by tier_missions() at Tier 5's numbers.
const LANTERN_EYE := "lantern_eye"
const EXODUS := "exodus"
const HEART_OF_FAITH := "heart_of_faith"
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
	var out: Array[MissionDef] = [tax_collector(), spoiled_harvest(), lost_lamb(), first_prayers(), bell_ringers(), market_panic(),
		informer(), crowns_bread(), prisoner(), heretic_hunt(), bishop(), armoury(), sermon(), relic_run(), lantern_eye(), exodus(),
		heart_of_faith()]
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


## A Tier 2 (Omen) mission's frame (v0.11 M3, mission spec §0, Decision 1): an Organized town -- tier_floor 2 and no profile, so a
## scripted run meets the board's town -- 3 slots and 8 DP, a 5:30 clock, no bonuses, every power allowed unless the mission
## narrows its pool.
static func _tier2(id: String, name: String, brief: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 2
	m.brief = brief
	m.slots = 3
	m.dp_capacity = 8
	m.clock = 330.0
	m.tier_floor = 2
	m.intro_banner = name.to_upper()
	return m


## A Tier 3 (Wrath) mission's frame (v0.11 M4, mission spec §0, Decision 57): a Prepared town -- tier_floor 3 and no profile, so a
## scripted run meets the board's town -- 4 slots and 10 DP, a 6:00 clock, no bonuses, every power allowed unless the mission
## narrows its pool.
static func _tier3(id: String, name: String, brief: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 3
	m.brief = brief
	m.slots = 4
	m.dp_capacity = 10
	m.clock = 360.0
	m.tier_floor = 3
	m.intro_banner = name.to_upper()
	return m


## A Tier 4 (Reckoning) mission's frame (v0.11 M5, mission spec §0, Decision 121): a God-Resistant town -- tier_floor 4 and no profile,
## so a scripted run meets the board's town -- 5 slots and 13 DP, a 6:30 clock, no bonuses, every power allowed unless the mission
## narrows its pool.
static func _tier4(id: String, name: String, brief: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 4
	m.brief = brief
	m.slots = 5
	m.dp_capacity = 13
	m.clock = 390.0
	m.tier_floor = 4
	m.intro_banner = name.to_upper()
	return m


## A Tier 5 (Ascendance) mission's frame (v0.11 M6, mission spec §0, Decision 207): a God-Resistant town -- tier_floor 4 and no profile,
## so a scripted run meets the board's town -- 6 slots and 16 DP, a 7:00 clock, no bonuses, every power allowed unless the mission
## narrows its pool.
static func _tier5(id: String, name: String, brief: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 5
	m.brief = brief
	m.slots = 6
	m.dp_capacity = 16
	m.clock = 420.0
	m.tier_floor = 4
	m.intro_banner = name.to_upper()
	return m


## The Tax Collector (v0.11 M2, Tier 1, spec §8 row 2; three collectors by the controller's Task 2 ruling): kill the tax
## collector and his two deputies on their rounds before any takes the taxes into the Citadel (TaxCollectorDirector). A seen
## kill still counts, but calls the bell.
static func tax_collector() -> MissionDef:
	var m := _tier1(TAX_COLLECTOR, "The Tax Collector", PackedStringArray(["Three tax collectors make their rounds.",
		"Kill them before the taxes arrive."]))
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


## Spoiled Harvest (v0.11 M2, Tier 1, spec §8 row 3, reshaped by the controller's Task 3 fix-round rulings): spoil three
## granaries one at a time as their grain arrives, each watched by two men who beat out its fire, before their carts empty them
## to the Citadel (HarvestDirector).
static func spoiled_harvest() -> MissionDef:
	var m := _tier1(SPOILED_HARVEST, "Spoiled Harvest", PackedStringArray(["Carts empty the granaries to the Citadel.",
		"Spoil the harvest before they do."]))
	m.goal = "Spoil the three granaries before their carts empty them"
	m.goal_label = "The harvest is spoiled"
	m.lose = "A granary is emptied, or dawn comes"
	# On the first granary (v0.11 M2, Task 8): at (1, 8) its tag and watchmen sat under the HUD's left stack of objectives and hints.
	m.camera_at = Vector2(-9.0, 13.5)
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["ember", "doom", "discord"])
	m.director = HarvestDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [RazeObjective.new("Granaries spoiled", "spoiled"), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Lost Lamb (v0.11 M2, Tier 1, spec §8 row 4): lead a runaway acolyte out through the west gate past the patrols, the
## watch and the Temple's searchers (LostLambDirector).
static func lost_lamb() -> MissionDef:
	var m := _tier1(LOST_LAMB, "The Lost Lamb", PackedStringArray(["A runaway acolyte hides from the Temple.",
		"Lead him out through the west gate."]))
	m.goal = "Lead the runaway acolyte out through the west gate"
	m.goal_label = "The lamb is free"
	m.lose = "He is taken back to the Temple, he dies, or dawn comes"
	m.camera_at = LostLambDirector.START.lerp(LostLambDirector.GATE_MOUTH, 0.3)
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "doom"])
	m.director = LostLambDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [EscortObjective.new("Lead the acolyte out", "lamb_out", "lamb_taken", "lamb"),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## First Prayers (v0.11 M2, Tier 1, spec §8 row 5): lead three of the poor to the old well shrine by the market, unseen by
## Halcyon's few Faithful (FirstPrayersDirector, Mira's House's Convert).
static func first_prayers() -> MissionDef:
	var m := _tier1(FIRST_PRAYERS, "First Prayers", PackedStringArray(["The poor have no shrine of their own.",
		"Lead three to the old well, unseen."]))
	m.goal = "Lead three of the poor to the old well shrine, unseen"
	m.goal_label = "Three believe"
	m.lose = "The Lantern looks, or fewer than three believe by dawn"
	m.camera_at = FirstPrayersDirector.SHRINE_AT
	m.intro_from = FirstPrayersDirector.SHRINE_AT + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord"])
	m.director = FirstPrayersDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), BelieversObjective.new()]
		return out
	return m


## The Bell-Ringers (v0.11 M3, Tier 2, mission spec §1 and §8 row 8): three watch posts each send a ringer for the bell, his mates
## at his heels; stop all three warnings before the bell tolls (BellRingersDirector). Blight and The Bell Lies are left out of its
## pool: either silences the bell outright.
static func bell_ringers() -> MissionDef:
	var m := _tier2(BELL_RINGERS, "The Bell-Ringers", PackedStringArray(["Three watch posts guard the walls.",
		"Stop their ringers before the bell."]))
	m.goal = "Stop the ringers of all three watch posts before the bell tolls"
	m.goal_label = "The ringers are stopped"
	m.lose = "The bell tolls, or dawn comes"
	var pool := PackedStringArray()
	for key in PowerBook.keys():
		if not key in BellRingersDirector.LEFT_OUT:
			pool.append(key)
	m.pool = pool
	m.camera_at = BellRingersDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "whisper", "discord"])
	m.director = BellRingersDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [StarsObjective.new("Stop the ringers", "ringers", "Ringers stopped"), BellSilentObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## Market Panic (v0.11 M3, Tier 2, mission spec §2 and §8 row 9): scatter a night fair at the north-east fountain -- four crowds
## walking in, wardens steadying them -- before the guard closes the market (MarketPanicDirector, a smaller Festival).
static func market_panic() -> MissionDef:
	var m := _tier2(MARKET_PANIC, "Market Panic", PackedStringArray(["A night fair fills the north-east square.",
		"Scatter it before the market closes."]))
	m.goal = "Scatter %d of the night fair's crowd before the guard closes the market at %s" % [MarketPanicDirector.FAIR_NEED,
		UiTheme.clock(MarketPanicDirector.MARKET_CLOSE)]
	m.goal_label = "The fair is scattered"
	m.lose = "The guard closes the market, or dawn comes"
	m.camera_at = MarketPanicDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["heaven", "doom", "smite"])
	m.director = MarketPanicDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [FestivalObjective.new("Scatter the fair", "fair"),
			EventObjective.new("close", "Market closes", "market_closed"), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Informer (v0.11 M3, Tier 2, mission spec §3 and §8 row 10): find the hidden informer through his four contacts -- each turned
## by an unseen whisper -- and kill him before the names reach the Temple (InformerDirector, the Assassinate type reused).
static func informer() -> MissionDef:
	var m := _tier2(INFORMER, "The Informer", PackedStringArray(["An informer carries your believers' names.",
		"Find him by his contacts. Kill him."]))
	m.goal = "Find the informer through his four contacts, and kill him before the names reach the Temple"
	m.goal_label = "The informer is dead"
	m.lose = "The names reach the Temple, a contact dies or leaves the town before he is turned, the bell tolls, or dawn comes"
	m.camera_at = InformerDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "doom"])
	m.director = InformerDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [AssassinateObjective.new("Kill the informer", "informer", "names"), BellSilentObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Crown's Bread (v0.11 M4, Tier 3, mission spec §1 and §8 row 13): raze the granary, the mill and the bridge, each while it is in
## use, before the Crown's carts roll; engineers mend and rebuild them (CrownsBreadDirector, the Raze type reused).
static func crowns_bread() -> MissionDef:
	var m := _tier3(CROWNS_BREAD, "The Crown's Bread", PackedStringArray(["The Crown's bread is made tonight.",
		"Destroy the granary, the mill and the bridge."]))
	m.goal = "Raze the granary, the mill and the bridge, each while it is in use, before the Crown's carts roll at %s" % UiTheme.clock(
		CrownsBreadDirector.CARTS_AT)
	m.goal_label = "The Crown's bread is ruined"
	m.lose = "The Crown's carts roll, or dawn comes"
	m.camera_at = CrownsBreadDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "ember", "whisper"])
	m.director = CrownsBreadDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [RazeObjective.new("Raze the Crown's bread", "bread"), EventObjective.new("carts", "Carts roll", "fed"),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Prisoner (v0.11 M4, Tier 3, mission spec §2 and §8 row 14): break a woman who spoke the god's name out of the stocks and lead
## her out by the postern past lay watchmen (PrisonerDirector, the Escort type reused).
static func prisoner() -> MissionDef:
	var m := _tier3(PRISONER, "The Prisoner", PackedStringArray(["A woman who spoke your name stands in the stocks.",
		"Break her free and lead her out."]))
	m.goal = "Break the prisoner out of the stocks by %s and lead her out by the postern" % UiTheme.clock(PrisonerDirector.FREE_BY)
	m.goal_label = "The prisoner is free"
	m.lose = "The gaolers take her inside, she is taken back to the Citadel, she dies, or dawn comes"
	m.camera_at = PrisonerDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "doom", "ember", "discord"])
	m.director = PrisonerDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [EscortObjective.new("Lead her out", "prisoner_out", "prisoner_taken", "prisoner"),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Heretic Hunt (v0.11 M4, Tier 3, mission spec §3 and §8 row 15): break the Inquisition's three lantern-standards and kill its
## captain before he finds the believers' cellar (HereticHuntDirector, the Hunt type's first night).
static func heretic_hunt() -> MissionDef:
	var m := _tier3(HERETIC_HUNT, "The Heretic Hunt", PackedStringArray(["The Inquisition hunts your believers.",
		"Break the hunt before it finds their cellar."]))
	m.goal = "Break the hunt's three standards and kill its captain before he finds your believers' cellar"
	m.goal_label = "The hunt is broken"
	m.lose = "The captain finds the cellar, or dawn comes"
	m.camera_at = HereticHuntDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "whisper", "discord"])
	m.director = HereticHuntDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [HuntObjective.new("Break the hunt", "hunt"), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Bishop (v0.11 M5, Tier 4, mission spec §1 and §8 row 17): burn the bishop out of his three refuges -- each guarded by Lantern
## Knights -- and kill him in the square before the Knights take him away (BishopDirector, the Assassinate type reused).
static func bishop() -> MissionDef:
	var m := _tier4(BISHOP, "The Bishop", PackedStringArray(["The bishop hides behind his Knights.", "Smoke him out. Kill him."]))
	m.goal = "Burn the bishop out of his refuges, then kill him before the Knights take him away at %s" % UiTheme.clock(
		BishopDirector.TAKEN_AT)
	m.goal_label = "The bishop is dead"
	m.lose = "He reaches the Citadel, the Knights take him away, or dawn comes"
	m.camera_at = BishopDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "ember"])
	m.director = BishopDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [AssassinateObjective.new("Kill the bishop", "bishop", "bishop_safe"),
			EventObjective.new("taken", "Knights come", "bishop_taken"), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Armoury (v0.11 M5, Tier 4, mission spec §2 and §8 row 18): raze the north barracks, the gate barracks and the armoury, each
## mustering at its horn and guarded by armed men who come faster each minute, before the garrison marches (ArmouryDirector, the Raze
## type reused on M4's stages: every blow lands from the start, a fall before its horn counts when it sounds).
static func armoury() -> MissionDef:
	var m := _tier4(ARMOURY, "The Armoury", PackedStringArray(["The muster horn arms the garrison.",
		"Destroy the armoury and two barracks."]))
	m.goal = "Destroy the two barracks and the armoury before the garrison marches at %s" % UiTheme.clock(ArmouryDirector.MARCH_AT)
	m.goal_label = "The garrison is broken"
	m.lose = "The garrison marches, or dawn comes"
	m.camera_at = ArmouryDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "ember", "heaven"])
	m.director = ArmouryDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [RazeObjective.new("Raze the garrison", "garrison"), EventObjective.new("march", "Garrison marches", "marches"),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Sermon (v0.11 M5, Tier 4, mission spec §3 and §8 row 19): silence a preacher who holds the poor quarter and lead eight of his
## crowd, in four waves, to the god's house unseen by the Faithful, before the sermon ends (SermonDirector, Mira's House's Convert).
static func sermon() -> MissionDef:
	var m := _tier4(SERMON, "The Sermon", PackedStringArray(["A preacher holds the poor quarter.", "Silence him. Turn eight of his crowd."]))
	m.goal = "Silence the preacher and lead eight of his crowd to the god's house, unseen, before the sermon ends at %s" % UiTheme.clock(
		SermonDirector.SERMON_ENDS)
	m.goal_label = "The crowd believes"
	m.lose = "The Lantern looks, the sermon ends, or too few are left to turn"
	m.camera_at = SermonDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "doom", "belllies"])  # no lure takes a listener on duty
	m.director = SermonDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), BelieversObjective.new("Turn the crowd", "sermon", "sermon_over"),
			EventObjective.new("ends", "Sermon ends", "sermon_over")]
		return out
	return m


## The Relic Run (v0.11 M5, Tier 4, mission spec §4 and §8 row 20): Pip slips aboard the relic cart at one checkpoint's halt, picks the
## reliquary's lock on the way and swaps the relic at the next, then carries it to your believers' house under the Searchlight
## (RelicRunDirector, The Vigil Flame's Steal).
static func relic_run() -> MissionDef:
	var m := _tier4(RELIC_RUN, "The Relic Run", PackedStringArray(["The Temple's relic rides to the Citadel.", "Swap it while the cart halts."]))
	m.goal = "Have Pip slip aboard the relic cart at one halt and swap the relic at the next, then bring it to your believers' house"
	m.goal_label = "The relic is ours"
	m.lose = "The relic reaches the Citadel, Pip dies, the Lantern looks, or dawn comes"
	m.camera_at = RelicRunDirector.CART_CAMERA
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "doom", "wisp"])
	m.director = RelicRunDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), FlameObjective.new("The relic", "relic", "relic_kept", "pip"),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Lantern's Eye (v0.11 M6, Tier 5, mission spec §1 and §8 row 23): shatter the three mirrors the Inquisition hangs on the wall
## towers to aim Halcyon's Searchlight, each kept shattered 20 s, before all three stand together (LanternEyeDirector, the Hunt type
## with an Anchors drain).
static func lantern_eye() -> MissionDef:
	var m := _tier5(LANTERN_EYE, "The Lantern's Eye", PackedStringArray(["Halcyon hangs mirrors to aim his light.",
		"Shatter all three before the Eye opens."]))
	m.goal = "Shatter the three mirrors on the wall towers, each kept shattered %d s, before all three stand together for %d s" % [
		roundi(LanternEyeDirector.DRAIN), roundi(LanternEyeDirector.EYE_OPENS)]
	m.goal_label = "The Eye is blind"
	m.lose = "All three mirrors stand together for %d s, Halcyon's Gaze fills, or dawn comes" % roundi(LanternEyeDirector.EYE_OPENS)
	m.camera_at = LanternEyeDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "whisper", "wisp", "heaven"])
	m.director = LanternEyeDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [HuntObjective.new("Blind the Eye", "eye_blind"), GazeObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## Exodus (v0.11 M6, Tier 5, mission spec §2 and §8 row 24): lead ten of twelve believers, in three households that come out one at a time,
## out of the town before the Inquisition shuts the last gate (ExodusDirector, the Escort type with many charges).
static func exodus() -> MissionDef:
	var m := _tier5(EXODUS, "Exodus", PackedStringArray(["The Inquisition comes for your flock.",
		"Lead ten out before the gates shut."]))
	m.goal = "Lead ten of your twelve believers out of Aldermere before the Inquisition shuts the last gate at %s" % UiTheme.clock(
		float(ExodusDirector.SHUT_AT[2]))
	m.goal_label = "The faithful are out"
	m.lose = "Too few are left to make ten, the last gate shuts, Halcyon's Gaze fills, or dawn comes"
	m.camera_at = ExodusDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord", "wisp"])
	m.director = ExodusDirector
	m.mission_tags = PackedStringArray(["shuts_gates"])
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [EscortObjective.new("Lead them out", "exodus", "exodus_taken", "exodus_dead", ExodusDirector.NEED),
			GazeObjective.new(), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m


## The Heart of Faith (v0.11 M6, Tier 5, mission spec §3 and §8 row 25): burn the oil-house and the Great Temple under their Lantern
## Knights to put out Halcyon's Great Flame, then kill High Priest Odran, borne to the Temple's steps in his litter, before he rekindles it
## (HeartOfFaithDirector, a staged Raze and an Assassinate of its own). It burns the Temple (burns_temple, M5's tag).
static func heart_of_faith() -> MissionDef:
	var m := _tier5(HEART_OF_FAITH, "The Heart of Faith", PackedStringArray(["Halcyon's Great Flame burns in his Temple.",
		"Put it out. Then kill his High Priest."]))
	m.goal = "Burn the oil-house and the Great Temple to put out the Great Flame by %s, then kill High Priest Odran before he rekindles it" % UiTheme.clock(
		HeartOfFaithDirector.BLESSED_AT)
	m.goal_label = "The Heart of Faith is broken"
	m.lose = "The flame is blessed at %s, Odran rekindles it, Halcyon's Gaze fills, or dawn comes" % UiTheme.clock(HeartOfFaithDirector.BLESSED_AT)
	m.camera_at = HeartOfFaithDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "ember", "whisper", "heaven"])
	m.director = HeartOfFaithDirector
	m.mission_tags = PackedStringArray(["burns_temple"])
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [StagesObjective.new("Put out the flame", "heart"), GazeObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
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
