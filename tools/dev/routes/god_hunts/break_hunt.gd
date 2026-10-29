extends RefCounted
## The scripted policies of the Hunt "Break the hunt" (Tier 4; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared), one
## act_<type> per god type, and the report line (state). Stubs casting nothing until the Hunt's own tasks write them (Task 7 the shared plan,
## Task 12 the six types); FILLED lists the types written. Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is
## never edited by a Hunt task).

## The god types whose policy is written (none yet).
const FILLED := []

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(4) Might at level 1, all in GodTree.keys_for(type, 4)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "heaven", "orbital"],
	"death": ["deathmark", "pestilence", "glacial"],
	"veil": ["doom", "blight", "nova"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies", "magnify"],
	"dominion": ["whisper", "discord", "turncoat"],
}


## The shared policy pieces (god T1R, Ruling P5-7): road_ahead(), reached through the Hunts' common file.
const GOD := preload("res://tools/dev/routes/god_t1.gd")
## Heaven Splitter's script (it has no class name), for its strike time.
const HEAVEN := preload("res://src/fx/set2/heaven_splitter.gd")
## How long a cast on a bearer holds the policy off him: the longest strike of the shared plan (Heaven Splitter's T_STRIKE) plus a look.
const HOLD := 2.0


## The director when the night is on, else null.
static func _bh(ctx: Dictionary) -> BreakHuntDirector:
	return ctx.get("d") as BreakHuntDirector


## The numbers this Hunt's report lines print: standards broken, houses taken, standards marching, taken up by an escort, stopped by the walls, the
## soonest standard's seconds to a house and the hint's phase.
static func state(_bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var marching := 0
	for i in d.steps.size():
		marching += 1 if d.steps[i].raised and not d.steps[i].broken else 0
	var soon := d.soonest_eta()
	return "broken=%d taken=%d marching=%d took_up=%d walled=%d soonest=%s phase=%s" % [d.broken_count(), d.taken(), marching, d.took_up_count, d.walled_count,
		"-" if soon == INF else str(roundi(soon)), d.hint_phase()]


## The standards in the street, soonest to a house first (a planted one last): the raised, unbroken ones whose bearer lives and is out of doors.
static func _marching(d: BreakHuntDirector) -> Array[int]:
	var out: Array[int] = []
	for i in d.steps.size():
		if d.steps[i].raised and not d.steps[i].broken and d.bearer(i) != null and not d.bearer(i).inside:
			out.append(i)
	out.sort_custom(func(a: int, b: int) -> bool: return d.eta(a) < d.eta(b))
	return out


## The shared plan with the def's own loadout (Silent Doom, Smite, Heaven Splitter; no `--god`), one look: the standard soonest to a house is
## worked, a strike at its bearer led ahead of his walk (Silent Doom, else Smite, else Heaven Splitter). A death beside a standard frightens its
## escorts too, so a bearer struck down breaks his standard unless the company is steady (MS §5); a bearer struck again within HOLD seconds is
## left alone while the first strike lands (the memo). Returns what it cast, or "".
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var memo: Dictionary = ctx.memo
	var now := rules.mission_time()
	for i in _marching(d):
		var b := d.bearer(i)
		if now - float(memo.get("cast_%d" % i, -99.0)) < HOLD:
			continue
		if bc._slot_ready(rules, slots, "doom"):
			memo["cast_%d" % i] = now
			rules.cast(int(slots.doom), GOD.road_ahead(b, SilentDoom.T_STRIKE))
			return "doom bearer %d" % i
		if bc._slot_ready(rules, slots, "smite"):
			memo["cast_%d" % i] = now
			rules.cast(int(slots.smite), GOD.road_ahead(b, SmiteFx.T_STRIKE))
			return "smite bearer %d" % i
		if bc._slot_ready(rules, slots, "heaven"):
			memo["cast_%d" % i] = now
			rules.cast(int(slots.heaven), GOD.road_ahead(b, HEAVEN.T_STRIKE))
			return "heaven bearer %d" % i
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
