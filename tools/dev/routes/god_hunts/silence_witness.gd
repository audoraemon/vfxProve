extends RefCounted
## The scripted policies of the Hunt "Silence the witness" (Tier 2; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared, Task 5),
## one act_<type> per god type, and the report line (state). The six types are stubs casting nothing until Task 10 writes them; FILLED lists the types
## written. Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is never edited by a Hunt task).

## The god types whose policy is written (none yet).
const FILLED := []

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(2) Might at level 1, all in GodTree.keys_for(type, 2)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "heaven", "tornado"],
	"death": ["deathmark", "pestilence", "glacial"],
	"veil": ["doom", "blight", "tsunami"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies", "magnify"],
	"dominion": ["whisper", "discord", "madness"],
}

## The pieces every Hunt's policy shares (god_t1.gd): road_ahead().
const GodT1 := preload("res://tools/dev/routes/god_t1.gd")
## A mate farther than this from the witness (Crowd.DOOM_WITNESS plus a margin for the step he takes while the Doom falls) cannot carry the word on.
const SW_CLEAR := 2.3
## Discord holds a witness this close to the Temple (mission seconds), when nothing else is ready.
const SW_DISCORD_AT := 14.0
## The last seconds before a house sends its witness in which the policy clears its door of bystanders (the Bell-Ringers' prep, for the idle rule).
const SW_PREP := 25.0
## How near a waiting house's door a bystander is whispered off.
const SW_DOOR_R := 3.0


## The numbers this Hunt's report lines print: the witnesses stopped, the relays, the ones walking and the soonest to the Temple.
static func state(_bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as SilenceWitnessDirector
	if d == null:
		return ""
	var eta := d.word_eta()
	return "stopped=%d relays=%d running=%d eta=%s word=%s phase=%s" % [d.stopped(), int(d.report().relays), d.running().size(),
		"-" if eta == INF else "%.0f" % eta, d.word_in(), d.hint_phase()]


## The shared plan with the def's own loadout (Silent Doom, Mind Whisper, Discord): what it cast, or "". As a player plays it: the witness
## closest to the Temple first. His mates carry the word on, so with one close enough to see (SW_CLEAR) the mate is taken off him first -- Mind
## Whisper sends him away (held, he cannot run on), else Silent Doom on one who stands alone -- and Silent Doom takes the witness once no mate stands
## near; Discord holds a witness within SW_DISCORD_AT of the Temple when nothing else is ready. Between witnesses a bystander at the next house's door
## is whispered off in its last SW_PREP seconds, while Mind Whisper will be ready again by then. Never a loud power.
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as SilenceWitnessDirector
	if d == null:
		return ""  # (no night yet, or another mission's: the dispatch test calls it with an empty ctx)
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var doom: bool = bc._slot_ready(rules, slots, "doom")
	var whisper: bool = bc._slot_ready(rules, slots, "whisper")
	var discord: bool = bc._slot_ready(rules, slots, "discord")
	var going: Array[WitnessDirector] = []
	for r in d.running():
		if WarningDirector._alive(r.messenger) and not r.messenger.inside:
			going.append(r as WitnessDirector)
	going.sort_custom(func(a: WitnessDirector, b: WitnessDirector) -> bool: return a.eta() < b.eta())
	for r in going:
		var w := r.messenger
		var near := _near_mates(r, SW_CLEAR)
		if doom and near.is_empty():
			rules.cast(slots.doom, w.ground_pos)
			return "doom the witness"
		if whisper:
			for m in near:
				if bc._whisperable(m):
					rules.cast(slots.whisper, m.ground_pos, {"target": m, "to": bc._ringers_off(d, m, w.ground_pos)})
					return "whisper a mate off the witness"
		if doom:
			if near.size() >= 2 and near[0].ground_pos.distance_to(near[1].ground_pos) <= SilentDoom.RADIUS * 2.0:
				var mid := (near[0].ground_pos + near[1].ground_pos) * 0.5
				if bc._ringers_only(crowd, mid, [near[0], near[1]]):
					rules.cast(slots.doom, mid)
					return "doom both mates"
			for m in near:
				if bc._ringers_only(crowd, m.ground_pos, [m]):
					rules.cast(slots.doom, m.ground_pos)
					return "doom a mate"
		if discord and r.eta() <= SW_DISCORD_AT and w.mind != Person.Mind.CONFUSED:
			rules.cast(slots.discord, w.ground_pos)
			return "discord the witness"
	if going.is_empty():
		return _prep(bc, ctx, d, whisper)
	return ""


## The witness's own mates (alive, out of doors, able to carry the word on) within `reach` of him now or when a Silent Doom would fall, nearest first.
static func _near_mates(r: WitnessDirector, reach: float) -> Array[Person]:
	var out: Array[Person] = []
	var w := r.messenger
	for v: Variant in r.mates:
		if not WarningDirector._alive(v) or v == w:
			continue
		var m := v as Person
		if m.inside or m.held_by_god() or m.mind == Person.Mind.FLEE:
			continue
		if m.ground_pos.distance_to(w.ground_pos) <= reach \
				or GodT1.road_ahead(m, SilentDoom.T_STRIKE).distance_to(GodT1.road_ahead(w, SilentDoom.T_STRIKE)) <= reach:
			out.append(m)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(w.ground_pos) < b.ground_pos.distance_squared_to(w.ground_pos))
	return out


## Between witnesses: in the last SW_PREP seconds before a house sends its witness, a citizen near its door is whispered off (it clears the first
## stretch of his road). "" when nobody stands there or Mind Whisper is not ready.
static func _prep(bc, ctx: Dictionary, d: SilenceWitnessDirector, whisper: bool) -> String:
	var i := d.next_post()
	if i < 0 or not whisper:
		return ""
	var due := d.timeline.seconds_to("out_%d" % i)
	if due > SW_PREP or due < float(PowerBook.get_power("whisper").cooldown):  # (Mind Whisper must be ready again when he comes out)
		return ""
	var crowd: Crowd = ctx.crowd
	for p in crowd.citizens:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or p.ground_pos.distance_to(d.doors[i]) > SW_DOOR_R:
			continue
		if bc._whisperable(p) and not d.ringers[i].crew().has(p):
			(ctx.rules as Rules).cast(ctx.slots.whisper, p.ground_pos, {"target": p, "to": bc._ringers_off(d, p, d.doors[i])})
			return "whisper a bystander off the %s door" % d.post_names[i]
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
