class_name RouteBook
extends RefCounted
## The second way to win every board mission (v0.11.1, spec §7): the main step has a route in two families, loadout A's and
## loadout B's. One row per board mission (TierBook.all()), kept in its own file so the tier tasks that prove a B each tune only
## their own lines (Decision 32). The rows are exactly spec §7.2's: "a" is loadout A's main-step power, "b" loadout B's, and
## "loadout" is loadout B, which holds "b" and not "a", fits the mission's board slots and DP, draws from its board pool, and
## differs from loadout A (tests/test_routes.gd checks all of it against TierBook.board()).
## The scripted player plays a B loadout through behaviour_check's `--route=b`.

const ROUTES := {
	# Tier 1, Whisper
	"warning": {"a": "doom", "b": "deathmark", "loadout": ["deathmark", "whisper", "discord"]},
	"tax_collector": {"a": "doom", "b": "smite", "loadout": ["ember", "smite", "wisp"]},
	"spoiled_harvest": {"a": "ember", "b": "heaven", "loadout": ["heaven", "smite", "whisper"]},
	"lost_lamb": {"a": "whisper", "b": "wisp", "loadout": ["wisp", "discord", "doom"]},
	"first_prayers": {"a": "whisper", "b": "wisp", "loadout": ["wisp", "discord", "doom"]},
	# Tier 2, Omen
	"miras_house": {"a": "whisper", "b": "wisp", "loadout": ["wisp", "discord", "doom"]},
	"broken_lanterns": {"a": "heaven", "b": "dragon", "loadout": ["dragon", "discord", "wisp"]},
	"bell_ringers": {"a": "doom", "b": "deathmark", "loadout": ["deathmark", "whisper", "wisp"]},
	"market_panic": {"a": "heaven", "b": "ember", "loadout": ["ember", "whisper", "deathmark"]},
	"informer": {"a": "whisper", "b": "discord", "loadout": ["discord", "wisp", "deathmark"]},
	# Tier 3, Wrath
	"vigil_flame": {"a": "whisper", "b": "wisp", "loadout": ["wisp", "discord", "doom", "thorns"]},
	"festival": {"a": "doom", "b": "heaven", "loadout": ["heaven", "smite", "ember", "wisp"]},
	"crowns_bread": {"a": "ember", "b": "verdict", "loadout": ["heaven", "verdict", "discord", "wisp"]},
	"prisoner": {"a": "whisper", "b": "wisp", "loadout": ["wisp", "smite", "discord", "deathmark"]},
	"heretic_hunt": {"a": "smite", "b": "blight", "loadout": ["blight", "discord", "wisp", "deathmark"]},
	# Tier 4, Reckoning
	"procession": {"a": "doom", "b": "deathmark", "loadout": ["smite", "heaven", "wisp", "discord", "deathmark"]},
	"bishop": {"a": "ember", "b": "heaven", "loadout": ["heaven", "smite", "whisper", "discord", "wisp"]},
	"armoury": {"a": "ember", "b": "verdict", "loadout": ["verdict", "heaven", "whisper", "discord", "wisp"]},
	"sermon": {"a": "whisper", "b": "wisp", "loadout": ["wisp", "discord", "deathmark", "belllies", "thorns"]},
	"relic_run": {"a": "whisper", "b": "wisp", "loadout": ["wisp", "discord", "deathmark", "oath", "thorns"]},
	# Tier 5, Ascendance. The Long Night's own row is Act I's; ACTS_B has each act's.
	"last_judgement": {"a": "heaven", "b": "verdict", "loadout": ["dragon", "ember", "verdict", "pestilence", "madness", "blight"]},
	"long_night": {"a": "doom", "b": "deathmark", "loadout": ["deathmark", "whisper", "discord"]},
	"lantern_eye": {"a": "smite", "b": "blight", "loadout": ["blight", "whisper", "discord", "wisp", "deathmark", "thorns"]},
	"exodus": {"a": "whisper", "b": "oath", "loadout": ["wisp", "deathmark", "oath", "discord", "thorns"]},
	"heart_of_faith": {"a": "ember", "b": "heaven", "loadout": ["heaven", "deathmark", "whisper", "discord", "wisp", "smite"]},
}

## The Long Night's loadout B for each act, by act id (rows 1, 12, 16 and 21): The Omen as The Warning, The Festival, The
## Procession, Judgement as Last Judgement. The behaviour check drafts the act's own before it begins.
const ACTS_B := {
	"omen": ["deathmark", "whisper", "discord"],
	"festival": ["heaven", "smite", "ember", "wisp"],
	"procession": ["smite", "heaven", "wisp", "discord", "deathmark"],
	"judgement": ["dragon", "ember", "verdict", "pestilence", "madness", "blight"],
}


## Mission `id`'s loadout B (empty for an unknown id).
static func loadout_b(id: String) -> PackedStringArray:
	return PackedStringArray(ROUTES.get(id, {}).get("loadout", []))


## Mission `id`'s loadout B for its act `act_id` (The Long Night); the mission's own loadout B when the id has no acts.
static func loadout_b_for_act(id: String, act_id: String) -> PackedStringArray:
	if id == "long_night" and ACTS_B.has(act_id):
		return PackedStringArray(ACTS_B[act_id])
	return loadout_b(id)


## Loadout A's main-step power for `id` ("" for an unknown id).
static func main_a(id: String) -> String:
	return String(ROUTES.get(id, {}).get("a", ""))


## Loadout B's main-step power for `id` ("" for an unknown id).
static func main_b(id: String) -> String:
	return String(ROUTES.get(id, {}).get("b", ""))
