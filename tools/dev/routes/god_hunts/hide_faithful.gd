extends RefCounted
## The scripted policies of the Hunt "Hide the faithful" (Tier 1; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared), one
## act_<type> per god type, and the report line (state). Stubs casting nothing until the Hunt's own tasks write them (Task 4 the shared plan,
## Task 9 the six types); FILLED lists the types written. Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is
## never edited by a Hunt task).

## The god types whose policy is written (none yet).
const FILLED := []

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(1) Might at level 1, all in GodTree.keys_for(type, 1)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "ember"],
	"death": ["deathmark", "pestilence"],
	"veil": ["doom", "blight"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies"],
	"dominion": ["whisper", "discord"],
}


## How near a believer an inquisitor must walk for the shared plan to clear him (the search is otherwise left alone: a fallen one is replaced).
const HUNT_NEAR := 9.0
## How far along a household's road ahead of its lamp a watcher is worked, and how near its gate's way out (the outer post's men).
const ROAD_AHEAD := 16.0
const GATE_NEAR := 6.0


## The director when the night is on, else null.
static func _hf(ctx: Dictionary) -> HideFaithfulDirector:
	return ctx.get("d") as HideFaithfulDirector


## The numbers this Hunt's report lines print (MS §7): believers out, lost, left; seizures; the search's place (houses stood at, the trail it
## follows), the inquisitors alive and their reliefs; the hint's phase.
static func state(_bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var alive := 0
	for v: Variant in d.inquisitors:
		alive += 1 if MissionDirector._alive(v) else 0
	return "out=%d lost=%d left=%d seizures=%d searched=%d trail=%d inquisitors=%d reliefs=%d pair=%.2f/%d phase=%s" % [d.out_count(), d.lost(), d.left_count(),
		d.seizures, d.searched, d.trail_of(), alive, d.inq_reliefs, minf(d.stopped_gap_min, 99.0), d.stopped_gaps, d.hint_phase()]


## The shared plan with the def's own loadout (Mind Whisper, Silent Doom, Discord; no `--god`): the households walk themselves, so the
## player works the opposition as it comes. The first that applies: a believer seized -- Discord on his seizer, else Mind Whisper sends the
## seizer off, else Silent Doom on him unseen; an inquisitor within HUNT_NEAR of a believer (or the search on a household's trail) -- cleared;
## a watcher about to see a believer (SIGHT + EXODUS_WARN) -- cleared; a watcher on a walking household's road ahead of its lamp (ROAD_AHEAD),
## or at its gate -- cleared; the next household about to come out -- the first watcher on its road. Every Doom unseen and sparing the
## believers (behaviour_check's Exodus pieces: _exodus_off() and the rest).
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var flock: Array = bc._exodus_flock(d)
	for c in d.charges:
		if not c.held or d._resolved(c) or not MissionDirector._alive(c.seizer):
			continue
		var s := c.seizer as Person
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, s.ground_pos)
			return "discord a seizer"
		if bc._slot_ready(rules, slots, "whisper") and not s.shaken():
			rules.cast(slots.whisper, s.ground_pos, {"target": s, "to": bc._prisoner_away(crowd, s, (c.man as Person).ground_pos)})
			return "whisper a seizer off"
		if bc._slot_ready(rules, slots, "doom") and bc._doom_unseen(crowd, s.ground_pos, flock, bc.EXODUS_MARGIN):
			rules.cast(slots.doom, s.ground_pos)
			return "doom a seizer"
	for v: Variant in d.inquisitors:
		if not d._watching(v) or d._seizing(v):
			continue
		var p := v as Person
		var near := d.trail_of() >= 0
		var from := p.ground_pos + Vector2.LEFT
		for b: Variant in flock:
			if (b as Person).ground_pos.distance_to(p.ground_pos) <= HUNT_NEAR:
				near = true
				from = (b as Person).ground_pos
		if near:
			var did: String = bc._exodus_off(rules, slots, d, crowd, p, from)
			if did != "":
				return did
	for v: Variant in d._watchers():
		if not d._watching(v) or d._seizing(v):
			continue
		var p := v as Person
		for b: Variant in flock:
			if (b as Person).ground_pos.distance_to(p.ground_pos) <= EscortDirector.SIGHT + bc.EXODUS_WARN:
				var did: String = bc._exodus_off(rules, slots, d, crowd, p, (b as Person).ground_pos)
				if did != "":
					return did
				break
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		var lead := d.lamp(i)
		if not h.out or h.done or lead == null:
			continue
		var lp := lead.man as Person
		var road := d.road(i)
		var here: float = bc._road_progress(road, lp.ground_pos)
		for v: Variant in d._watchers():
			if not d._watching(v) or d._seizing(v):
				continue
			var p := v as Person
			var on: float = bc._road_progress(road, p.ground_pos)
			var off := p.ground_pos.distance_to(bc._road_ahead(road, road[0], on))
			var at_gate := p.ground_pos.distance_to(road.back()) <= GATE_NEAR
			if at_gate or (off <= bc.EXODUS_NEAR and on >= here - bc.EXODUS_NEAR and on <= here + ROAD_AHEAD):
				var did: String = bc._exodus_off(rules, slots, d, crowd, p, lp.ground_pos)
				if did != "":
					return did
	var nxt := d.upcoming()
	if nxt >= 0 and d.due_in(nxt) <= bc.EXODUS_AHEAD:
		var road := d.road(nxt)
		for v: Variant in d._watchers():
			if not d._watching(v):
				continue
			var p := v as Person
			for k in range(road.size() - 1):
				if bc._seg_dist(p.ground_pos, road[k], road[k + 1]) <= bc.EXODUS_NEAR:
					var did: String = bc._exodus_off(rules, slots, d, crowd, p, road[k], d.due_in(nxt) <= bc.EXODUS_SOON)
					if did != "":
						return did
					break
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
