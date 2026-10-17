extends RefCounted
## Tier 4 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes, kept the whole run), mission}, rebuilt at every look.
## Stubs until the tier's task writes them: they cast nothing, so the gate fails cleanly.


static func act_procession(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_procession(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_bishop(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_bishop(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_armoury(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_armoury(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_sermon(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_sermon(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_relic(_bc, _ctx: Dictionary) -> String:
	return ""


static func state_relic(_bc, _ctx: Dictionary) -> String:
	return ""
