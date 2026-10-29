extends RefCounted
## The scripted policies of the five Lantern Hunts (god P5, MS §7, R37-R38, plan Task 3): behaviour_check on a scenario named in SCENARIOS
## plays the Hunt's shared plan (no `--god`: the def's own loadout, act_shared) or, with `--god=<type>:<tier> --dev-tree`, that type's own
## policy (act_<type>) with the loadout the file's LOADOUT names for it, held to the tree by problems(). One file per Hunt in god_hunts/
## (a stub casting nothing until its Task 4-13 fills it); FILLED lists the types a file has written. (No class_name: preloaded as GOD_HUNTS
## by behaviour_check.gd and by the tests, as god_t1.gd is. The policy pieces every Hunt shares are god_t1.gd's: FILL, note_cast(),
## outside_spot(), road_ahead(), cast_mirror(), cast_bell(), plague_aim(); reached through GOD_T1, never copied -- Ruling P5-7.)

## The shared pieces (god T1R): the filler words, the idle measure and the casts. Reached as GOD_HUNTS.GOD_T1.
const GOD_T1 := preload("res://tools/dev/routes/god_t1.gd")

## The Hunts' mission ids in HuntBook.ids() order (tier 1-5). A test holds this equal to HuntBook.ids().
const SCENARIOS := ["hide_faithful", "silence_witness", "expel_inquisitor", "break_hunt", "face_halcyon"]
## Each Hunt's policy file (stubs until Tasks 4-13 fill them).
const FILES := {
	"hide_faithful": preload("res://tools/dev/routes/god_hunts/hide_faithful.gd"),
	"silence_witness": preload("res://tools/dev/routes/god_hunts/silence_witness.gd"),
	"expel_inquisitor": preload("res://tools/dev/routes/god_hunts/expel_inquisitor.gd"),
	"break_hunt": preload("res://tools/dev/routes/god_hunts/break_hunt.gd"),
	"face_halcyon": preload("res://tools/dev/routes/god_hunts/face_halcyon.gd"),
}
## The god types a policy file writes an act_<type> for.
const TYPES := ["ruin", "death", "veil", "passage", "decree", "dominion"]


## The tier of the Hunt `scenario` (HuntBook's row), 0 for an id that is not a Hunt.
static func tier_of(scenario: String) -> int:
	return int(HuntBook.row(scenario).get("tier", 0))


## The keys the Hunt's file plays for god type `type` at level 1 (its LOADOUT[type]); empty when the file names none. (`_tier` is the
## Hunt's tier, given by callers for symmetry with problems(); the file's lists are per Hunt, so it is not read.)
static func loadout(scenario: String, type: String, _tier := 0) -> PackedStringArray:
	if not FILES.has(scenario):
		return PackedStringArray()
	var table: Dictionary = (FILES[scenario] as GDScript).get_script_constant_map().get("LOADOUT", {})
	return PackedStringArray(table.get(type, []))


## The keys of `keys` that god `type` has not learned by `tier` (GodTree.keys_for under the tree as it stands: the dev fill if on), in the
## order given, each named alone. Empty when all are in the tree.
static func missing(type: String, tier: int, keys: PackedStringArray) -> PackedStringArray:
	var known := GodTree.keys_for(type, tier)
	var out := PackedStringArray()
	for key in keys:
		if not known.has(key):
			out.append(key)
	return out


## What is wrong with the loadout `keys` for god `type` at `tier` (ruling C9, the loadout floor), one line each, empty when it is the floor
## a god of that tier has: every key in the tree at that tier (named alone, as missing() gives it), at most GodSlot.BASE_SLOTS keys ("slots
## n>3"), and their Might at level 1 within TierBook.dp(tier) ("might n>m"). An empty list is "no keys".
static func check(type: String, tier: int, keys: PackedStringArray) -> PackedStringArray:
	var out := missing(type, tier, keys)
	if keys.is_empty():
		out.append("no keys")
	if keys.size() > GodSlot.BASE_SLOTS:
		out.append("slots %d>%d" % [keys.size(), GodSlot.BASE_SLOTS])
	var might := 0
	for key in keys:
		might += PowerBook.might(key, 1)
	if might > TierBook.dp(tier):
		out.append("might %d>%d" % [might, TierBook.dp(tier)])
	return out


## What is wrong with the Hunt's loadout for `type` at `tier`: check() of its LOADOUT[type]. A refusal names the key (behaviour_check prints
## it as `missing=<...>`). Empty when the loadout is playable.
static func problems(scenario: String, type: String, tier: int) -> PackedStringArray:
	if not FILES.has(scenario):
		return PackedStringArray(["no such Hunt"])
	return check(type, tier, loadout(scenario, type, tier))


## The scenario has a policy file with an act_<type> (for "", its act_shared).
static func has_policy(scenario: String, type: String) -> bool:
	if not FILES.has(scenario):
		return false
	var want := "act_" + (type if type != "" else "shared")
	for m: Dictionary in (FILES[scenario] as GDScript).get_script_method_list():
		if m.name == want:
			return true
	return false


## The types whose policy the Hunt's file has written (its FILLED).
static func filled(scenario: String) -> PackedStringArray:
	if not FILES.has(scenario):
		return PackedStringArray()
	return PackedStringArray((FILES[scenario] as GDScript).get_script_constant_map().get("FILLED", []))


## One look of the policy of `type` ("" = the shared plan with the def's loadout) for `scenario`: what it cast, or "".
static func act(scenario: String, type: String, bc, ctx: Dictionary) -> String:
	if not has_policy(scenario, type):
		return ""
	return String((FILES[scenario] as GDScript).call("act_" + (type if type != "" else "shared"), bc, ctx))


## The numbers the Hunt's report lines print.
static func state(scenario: String, bc, ctx: Dictionary) -> String:
	if not FILES.has(scenario):
		return ""
	return String((FILES[scenario] as GDScript).call("state", bc, ctx))
