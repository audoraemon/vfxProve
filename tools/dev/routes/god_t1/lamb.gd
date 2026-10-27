extends RefCounted
## The scripted player's per-type policies for The Lost Lamb (god T1R, spec 9): one act_<type>(bc, ctx) for each god type, playing only that type's
## two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the behaviour_check
## script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd. A stub casts nothing and returns "" until
## its mission task writes it and adds the type to FILLED.

## The types whose policy is written.
const FILLED := []


static func act_ruin(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_death(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_veil(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_passage(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_decree(_bc, _ctx: Dictionary) -> String:
	return ""


static func act_dominion(_bc, _ctx: Dictionary) -> String:
	return ""


## The numbers a report line prints (the same as the route B's, tier1_b.gd).
static func state(bc, ctx: Dictionary) -> String:
	return String(preload("res://tools/dev/routes/tier1_b.gd").state_lamb(bc, ctx))
