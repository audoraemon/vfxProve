extends RefCounted
## The scripted policies of the Hunt "Face Halcyon" (Tier 5; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared), one
## act_<type> per god type, and the report line (state). Stubs casting nothing until the Hunt's own tasks write them (Task 8 the shared plan,
## Task 13 the six types); FILLED lists the types written. Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is
## never edited by a Hunt task).

## The god types whose policy is written (none yet).
const FILLED := []

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(5) Might at level 1, all in GodTree.keys_for(type, 5)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "ember", "heaven"],
	"death": ["deathmark", "pestilence", "glacial"],
	"veil": ["doom", "blight", "tsunami"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies", "magnify"],
	"dominion": ["whisper", "discord", "priority"],
}


## The numbers this Hunt's report lines print (a stub: none yet).
static func state(_bc, _ctx: Dictionary) -> String:
	return ""


## The shared plan with the def's own loadout (no `--god`): what it cast, or "" (a stub).
static func act_shared(_bc, _ctx: Dictionary) -> String:
	return ""


## The ruin policy for this Hunt: what it cast, or "" (a stub).
static func act_ruin(_bc, _ctx: Dictionary) -> String:
	return ""


## The death policy for this Hunt: what it cast, or "" (a stub).
static func act_death(_bc, _ctx: Dictionary) -> String:
	return ""


## The veil policy for this Hunt: what it cast, or "" (a stub).
static func act_veil(_bc, _ctx: Dictionary) -> String:
	return ""


## The passage policy for this Hunt: what it cast, or "" (a stub).
static func act_passage(_bc, _ctx: Dictionary) -> String:
	return ""


## The decree policy for this Hunt: what it cast, or "" (a stub).
static func act_decree(_bc, _ctx: Dictionary) -> String:
	return ""


## The dominion policy for this Hunt: what it cast, or "" (a stub).
static func act_dominion(_bc, _ctx: Dictionary) -> String:
	return ""
