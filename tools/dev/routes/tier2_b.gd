extends RefCounted
## Tier 2 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes, kept the whole run), mission}, rebuilt at every look.
## Stubs until the tier's task writes them: they cast nothing, so the gate fails cleanly.


static func act_miras(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_miras(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_lanterns(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_lanterns(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_ringers(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_ringers(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_panic(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_panic(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_informer(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_informer(_bc, _ctx: Dictionary) -> String:
	return ""
