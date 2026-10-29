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


## How near the Gaze may climb before the shared plan stops striking where it can be seen (each seen death is GazeMeter.SEEN_DEATH of 100; three freed
## take at most six strikes), and how far Mind Whisper sends an escort off (MS §6: Dominion's "Whisper an escort away").
const GAZE_CAP := 60.0
const WHISPER_AWAY := 6.0


## The director when the night is on, else null.
static func _fh(ctx: Dictionary) -> FaceHalcyonDirector:
	return ctx.get("d") as FaceHalcyonDirector


## The numbers this Hunt's report lines print (MS §6): believers freed (and by what), burned and still to come, the Gaze, each procession's phase
## (W waiting, F forming, M marching, B burning, R freed, X burned, D dead) with its able escorts, the nearest two escorts of one procession have stood
## (ground units; min/looks under 1.6/looks) stopped at their places and walking, the hint's phase.
static func state(_bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var phases := ""
	var able := []
	for i in d.procs.size():
		phases += "WFMBRXD"[int(d.phase_of(i))]
		able.append(d.able_escort(i))
	return "freed=%d (broken %d walls %d) burned=%d left=%d gaze=%d phases=%s able=%s stopped=%.2f/%d/%d walking=%.2f/%d/%d phase=%s" % [d.freed(),
		d.freed_broken, d.freed_walls, d.burned(), d.left_count(), roundi(d.gaze.value), phases, able, minf(d.pair_min, 99.0), d.pair_under, d.pair_looks,
		minf(d.walk_min, 99.0), d.walk_under, d.walk_looks, d.hint_phase()]


## The processions in the order they press: the one at the stake first, then by the seconds to the pyre.
static func _pressing(d: FaceHalcyonDirector) -> Array[int]:
	var out: Array[int] = []
	for i in d.procs.size():
		if d.phase_of(i) in [FaceHalcyonDirector.Procession.Phase.FORMING, FaceHalcyonDirector.Procession.Phase.MARCHING, FaceHalcyonDirector.Procession.Phase.BURNING]:
			out.append(i)
	out.sort_custom(func(a: int, b: int) -> bool:
		var ba := d.phase_of(a) == FaceHalcyonDirector.Procession.Phase.BURNING
		var bb := d.phase_of(b) == FaceHalcyonDirector.Procession.Phase.BURNING
		if ba != bb:
			return ba
		return d.pyre_in(a) < d.pyre_in(b))
	return out


## Procession `i`'s escorts that still hold him: alive, out of doors, and not disabled.
static func _fit(d: FaceHalcyonDirector, i: int) -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in (d.procs[i] as FaceHalcyonDirector.Procession).escorts:
		if MissionDirector._alive(v) and not (v as Person).inside and not d.is_leaving(v) and not d._disabled(v as Person):
			out.append(v as Person)
	return out


## The shared plan with the def's own loadout (Mind Whisper, Discord, Silent Doom; no `--god`), for the procession pressing hardest (_pressing()): the
## believer is freed once fewer than two of his escort are able, so `need` of them (able less one) must be broken. The first that applies: Discord where
## it takes `need` of them at once (it holds a Doom's worth of ground, DiscordFx.DISCORD_R); Silent Doom on an escort whose death goes unseen
## (behaviour_check's _doom_unseen(), sparing the believers); Mind Whisper sends an escort six units off; Silent Doom on an escort seen, while the Gaze
## is under GAZE_CAP. "" when nothing serves.
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var flock: Array = d.believers.filter(func(b: Variant) -> bool: return MissionDirector._alive(b))
	for i in _pressing(d):
		var fit := _fit(d, i)
		var need := d.able_escort(i) - (FaceHalcyonDirector.FH_ESCORT_HOLD - 1)
		if need <= 0 or fit.is_empty():
			continue
		if bc._slot_ready(rules, slots, "discord"):
			var best := Vector2.INF
			var most := 0
			for e in fit:
				var held := 0
				for o in fit:
					held += 1 if o.ground_pos.distance_to(e.ground_pos) <= DiscordFx.DISCORD_R - 0.1 else 0
				if held > most:
					most = held
					best = e.ground_pos
			if most >= need and best != Vector2.INF:
				rules.cast(slots.discord, best)
				return "discord the escort of procession %d" % i
		if bc._slot_ready(rules, slots, "doom"):
			for e in fit:
				if bc._doom_unseen(crowd, e.ground_pos, flock, bc.EXODUS_MARGIN):
					rules.cast(slots.doom, e.ground_pos)
					return "doom an escort of procession %d" % i
		if bc._slot_ready(rules, slots, "whisper"):
			for e in fit:
				if not e.shaken() and e.mind != Person.Mind.WHISPERED:
					var b := (d.procs[i] as FaceHalcyonDirector.Procession).charge.man as Person
					rules.cast(slots.whisper, e.ground_pos, {"target": e, "to": bc._prisoner_away(crowd, e, b.ground_pos)})
					return "whisper an escort of procession %d" % i
		if bc._slot_ready(rules, slots, "doom") and d.gaze.value + GazeMeter.SEEN_DEATH <= GAZE_CAP:
			for e in fit:
				var spare := false
				for b: Variant in flock:
					spare = spare or (b as Person).ground_pos.distance_to(e.ground_pos) <= SilentDoom.RADIUS
				if not spare:
					rules.cast(slots.doom, e.ground_pos)
					return "doom an escort of procession %d, seen" % i
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
