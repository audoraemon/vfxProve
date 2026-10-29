extends RefCounted
## The scripted policies of the Hunt "Expel the inquisitor" (Tier 3; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared), one
## act_<type> per god type, and the report line (state). Stubs casting nothing until the Hunt's own tasks write them (Task 6 the shared plan,
## Task 11 the six types); FILLED lists the types written. Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is
## never edited by a Hunt task).

## The god types whose policy is written (none yet: Task 11 writes the six; this task writes the shared plan).
const FILLED := []

## The shared policy pieces (god T1R, Ruling P5-7): road_ahead() and the filler words, reached through the Hunts' common file.
const GOD := preload("res://tools/dev/routes/god_t1.gd")

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(3) Might at level 1, all in GodTree.keys_for(type, 3)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "heaven", "tornado"],
	"death": ["deathmark", "pestilence", "glacial"],
	"veil": ["doom", "blight", "nova"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies", "magnify"],
	"dominion": ["whisper", "discord", "madness"],
}


## The numbers this Hunt's report lines print: each target's state and leg (behaviour_check's _tax_states(): W waiting, A walking, V visiting, F
## fleeing, H hiding, S safe, D dead, O out of the walls), the dead and the stopped, the counted frights and whether the captain fled.
static func state(bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as ExpelInquisitorDirector
	if d == null:
		return ""
	return "states=%s killed=%d stopped=%d frights=%d fled=%s" % [bc._tax_states(d), d.killed(), d.stopped(), d.frights(), d.fled()]


## The targets in the street now (walking or fleeing, alive, out of doors), the captain first, then the wardens in their order.
static func _street(d: ExpelInquisitorDirector) -> Array[AssassinateDirector.Quarry]:
	var out: Array[AssassinateDirector.Quarry] = []
	for q in d.quarries:
		if q.dead or not q.state in [AssassinateDirector.State.WALKING, AssassinateDirector.State.FLEEING]:
			continue
		if not MissionDirector._alive(q.target) or (q.target as Person).inside:
			continue
		if d._is_captain(q):
			out.insert(0, q)
		else:
			out.append(q)
	return out


## Where a Silent Doom cast now lands to take `q`'s man: where he will be SilentDoom.T_STRIKE on along his road. A target with a guard within a
## Doom's reach of the midpoint is aimed at the midpoint, so the guard falls with him and nobody is left to cry murder.
static func _doom_aim(q: AssassinateDirector.Quarry) -> Vector2:
	var at: Vector2 = GOD.road_ahead(q.target, SilentDoom.T_STRIKE)
	var best := at
	var best_gap := INF
	for g: Variant in q.guards:
		if not MissionDirector._alive(g) or (g as Person).inside:
			continue
		var there: Vector2 = GOD.road_ahead(g as Person, SilentDoom.T_STRIKE)
		var mid := (at + there) * 0.5
		var gap := at.distance_to(there)
		if gap <= SilentDoom.RADIUS * 1.6 and gap < best_gap:
			best = mid
			best_gap = gap
	return best


## The shared plan with the def's own loadout (no `--god`: Silent Doom, Smite, Mind Whisper), one look: the first target in the street (the
## captain first) is struck, Silent Doom aimed to take his guard with him if one stands near (_doom_aim()), else Smite led ahead of him. A kill
## seen only tolls the bell, and the Lantern turns: nothing is lost (MS §0). Returns what it cast, or "".
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	for q in _street(d):
		if bc._slot_ready(rules, slots, "doom"):
			rules.cast(int(slots.doom), _doom_aim(q))
			return "doom %s" % q.label
		if bc._slot_ready(rules, slots, "smite"):
			rules.cast(int(slots.smite), GOD.road_ahead(q.target, SmiteFx.T_STRIKE))
			return "smite %s" % q.label
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
