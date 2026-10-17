extends RefCounted
## Tier 3 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes), mission}.
## Stubs until the tier's task writes them: they cast nothing, so the gate fails cleanly.


static func act_flame(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_flame(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_festival(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_festival(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_bread(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_bread(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_prisoner(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_prisoner(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_hunt(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_hunt(_bc, _ctx: Dictionary) -> String:
	return ""
