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
## The town's readiness: "" for the difficulty chosen on Prepare, "unaware" for The Warning's (v0.08 M4).
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


## Prepare's difficulty picker applies: the mission does not set the town's readiness itself.
func chooses_difficulty() -> bool:
	return profile == ""


## The town's response for this mission: the difficulty chosen on Prepare, unless the mission sets its own.
func response_profile(chosen: ResponseProfile.Tier) -> ResponseProfile:
	if profile == "unaware":
		return ResponseProfile.unaware()
	return ResponseProfile.for_tier(chosen)
