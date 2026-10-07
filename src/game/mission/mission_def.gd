class_name MissionDef
extends RefCounted
## One mission (v0.08): what the board and Prepare show, the loadout it allows, the town it is played in, how it is
## won and lost, and the director that runs its scripted actors. MissionBook makes them.

var id := ""
var name := ""
## The Awakening Tier, 1 (Whisper) to 5 (Ascendance).
var tier := 1
## Two short lines for the board.
var brief := PackedStringArray()
## The goal line, for the board and Prepare.
var goal := ""
## The goal in a few words, for the results (unscored missions).
var goal_label := ""
## How it is lost, for Prepare's briefing.
var lose := ""
## Loadout: how many slots, and how much Divine Power the picks may cost in all (0: no budget).
var slots := 4
var dp_capacity := 0
## The powers it allows; empty for every power.
var pool := PackedStringArray()
var clock := 360.0
## Seconds a completed Banishing Rite takes off the clock (v0.09.1: The Long Night's acts take 20, every other mission
## BanishingRite.PENALTY).
var rite_penalty := BanishingRite.PENALTY
## The town's readiness: "" for the difficulty chosen on Prepare, "unaware" for The Warning's (v0.08 M4), "night" for The
## Long Night's first town (v0.09; each ActDef then sets its own).
var profile := ""
## The intro's camera: from `intro_from` to `camera_at` (ground units); its banner.
var intro_from := Vector2(2.7, 12.0)
var camera_at := TownLayout.CITADEL_ORIGIN
var intro_banner := "MANIFEST"
## A score and a rank in the results (Last Judgement), rather than objectives ticked or crossed.
var scored := false
## For runs with no Prepare screen (scripted runs, a standalone mission).
var default_loadout := PackedStringArray()
## A MissionDirector script, or null.
var director: GDScript
## func() -> Array[Objective], each call a fresh set (objectives may keep state).
var make_objectives: Callable
var make_bonuses: Callable
## The board's town readiness for its tier (v0.11 M1, spec §4), as ResponseProfile.level(): the town is at least this ready,
## whatever the mission sets; -1 off the board.
var tier_floor := -1
## How much slower the director's timeline runs (v0.11 M1, spec §7.2): a board mission's tier clock over its own, so its
## windows still fall inside the night; 1 off the board.
var stretch := 1.0
## func(director: MissionDirector) -> void: a board version's tuning of its director before its setup (v0.11 M1: the
## Festival's raised need); unset elsewhere.
var tune: Callable
## The tags the mission declares for the wishes to filter on (v0.11 M1, spec §5.1): "unaware_town", "spares_houses".
var mission_tags := PackedStringArray()


## A mission played in acts (v0.09, The Long Night): its ActDefs, the first one first. Empty for a single act.
var acts: Array = []


func has_acts() -> bool:
	return not acts.is_empty()


func first_act() -> ActDef:
	return acts[0] if has_acts() else null


func act(id: String) -> ActDef:
	for a in acts:
		if (a as ActDef).id == id:
			return a
	return null


## The primary objectives, fresh, in the order they decide the mission.
func objectives() -> Array[Objective]:
	var out: Array[Objective] = []
	if make_objectives.is_valid():
		out.assign(make_objectives.call())
	return out


## The bonus objectives, fresh; they only report in the results.
func bonuses() -> Array[Objective]:
	var out: Array[Objective] = []
	if make_bonuses.is_valid():
		out.assign(make_bonuses.call())
	return out


## The power keys it allows, in PowerBook's order when it allows every one.
func powers() -> PackedStringArray:
	return pool if not pool.is_empty() else PowerBook.keys()


func allows(key: String) -> bool:
	return powers().has(key)


## Prepare's difficulty picker applies: the mission does not set the town's readiness itself, nor does its board tier
## (v0.11 M1, spec §4: board missions drop the picker).
func chooses_difficulty() -> bool:
	return profile == "" and tier_floor < 0


## The town's response for this mission: the difficulty chosen on Prepare, unless the mission sets its own. A night
## (v0.10) answers with its first act's town, which reads the night it is given: the campaign's Feast after a rung bell.
## On the board (v0.11 M1) the tier's readiness is a floor: raised to, never lowered.
func response_profile(chosen: ResponseProfile.Tier) -> ResponseProfile:
	var own: ResponseProfile
	if profile == "night" and has_acts():
		own = first_act().response_profile(chosen)
	elif profile == "unaware" or profile == "night":
		own = ResponseProfile.unaware()
	elif tier_floor >= 0:
		own = ResponseProfile.for_level(tier_floor)
	else:
		own = ResponseProfile.for_tier(chosen)
	return own.at_least(tier_floor)


## The mission's director, made and tuned but not yet set up (v0.11 M1): its timeline's stretch, and any tuning a board
## version asks for, are in place before its _begin() runs. Null for a mission without one.
func make_director() -> MissionDirector:
	if director == null:
		return null
	var d := director.new() as MissionDirector
	d.stretch = stretch
	if tune.is_valid():
		tune.call(d)
	return d
