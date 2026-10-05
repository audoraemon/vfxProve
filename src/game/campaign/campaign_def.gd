class_name CampaignDef
extends RefCounted
## The Lantern campaign as data (v0.10, spec §3-§4): four nights in Aldermere, the missions each night offers with the
## path each belongs to, and the numbers by which the god's Divine Power grows and Halcyon bites it.

const FAITH := "faith"
const THEFT := "theft"
const RUIN := "ruin"
## The paths, in the tally's order.
const PATHS := ["faith", "theft", "ruin"]
## The endings: a path's, after its last night, or Halcyon's, after the third bite.
const NEW_FAITH := "new_faith"
const FALSE_LANTERN := "false_lantern"
const KATACLYSM := "kataclysm"
const EATEN := "eaten"
const ENDINGS := ["new_faith", "false_lantern", "kataclysm", "eaten"]
## The budget the god wakes with; what a won night, its bonus and a bite change; the floor; the bites that end it.
const START_DP := 6
const WIN_DP := 2
const BONUS_DP := 1
const BITE_DP := 1
const MIN_DP := 4
const MAX_BITES := 3
## The nights in order: the Awakening Tier, the slots, the memory fragment shown before it (CampaignText.FRAGMENTS), and
## the missions it offers, {mission, path}: one, or a choice card. Night 4 is the finale, on the Ruin path only.
const NIGHTS := [
	{"tier": 1, "slots": 3, "fragment": "shrine", "options": [{"mission": "warning", "path": ""}]},
	{"tier": 2, "slots": 3, "fragment": "pyre", "options": [{"mission": "miras_house", "path": "faith"},
		{"mission": "vigil_flame", "path": "theft"}, {"mission": "broken_lanterns", "path": "ruin"}]},
	{"tier": 3, "slots": 4, "fragment": "lanterns", "options": [{"mission": "feast_festival", "path": ""},
		{"mission": "feast_procession", "path": ""}]},
	{"tier": 5, "slots": 6, "fragment": "vision", "options": [{"mission": "last_judgement", "path": ""}]},
]
## Night 4's index: the finale.
const FINALE := 3


static func night(i: int) -> Dictionary:
	return NIGHTS[clampi(i, 0, NIGHTS.size() - 1)]


## The path a mission belongs to on night `i`: "" for a night without paths, or a mission the night does not offer.
static func path_of(i: int, mission_id: String) -> String:
	for o: Dictionary in night(i).options:
		if String(o.mission) == mission_id:
			return String(o.path)
	return ""


## The ending a path reaches: Faith and Theft after Night 3, Ruin after the finale.
static func ending_for(path: String) -> String:
	match path:
		FAITH:
			return NEW_FAITH
		THEFT:
			return FALSE_LANTERN
	return KATACLYSM
