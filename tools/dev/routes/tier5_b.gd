extends RefCounted
## Tier 5 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes, kept the whole run), mission}, rebuilt at every look.
## The Lantern's Eye, Exodus and The Heart of Faith play their B loadouts here; Last Judgement and The Long Night (a Death Mark Omen, the
## Festival's or Procession's B, Judgement's) too, the night through behaviour_check's _night().

## The Lantern's Eye: how soon before the next mirror goes up the policy clears its party; how soon a power still cooling counts as ready
## for the crew (the shattering blow waits until Discord and Mind Whisper will both be ready as Blight lands: two wrights hang a glass in 5 s);
## how far from the tower's face Blight's aim may lie (BlightFx.REACH less a margin); how far along the face the aim slides when the middle is lit.
const EYE_AHEAD := 25.0
const EYE_CREW_WAIT := 2.0
const EYE_BLIGHT_REACH := 0.9
const EYE_SLIDE := 0.6

## The Heart of Faith. A Heaven Splitter's reach (HeavenSplitter): its core, its line's half-length and half-width, and the farthest an eruption
## kills from where it lands; the step of the search for a place to drop it; the most of the living in that reach it waits for (whispering
## them off, HEART_HUSH units) and for how long.
const HEART_CORE_R := 1.6
const HEART_LINE := 5.0
const HEART_LINE_HALF := 0.7
const HEART_BLAST := 6.2
const HEART_STEP := 0.8
const HEART_NEAR_OK := 1
const HEART_WAIT := 20.0
const HEART_HUSH := 8.0
## A Knight counts as drawn by a Will-o'-Wisp within HEART_DRAW of its light (its reach less a margin) and HEART_WALK on foot; the ring
## they stand in is HEART_RING to HEART_RING_MAX round it; one free of the god's hold counts as coming to guard within HEART_COMING beyond
## the guard's reach (a Heaven Splitter takes 1.4 s to strike); a bearers' litter is in a Heaven Splitter's core within HEART_CORE.
const HEART_DRAW := 5.4
const HEART_WALK := 6.5
const HEART_RING := 0.8
const HEART_RING_MAX := 1.8
const HEART_COMING := 2.0
const HEART_CORE := 1.5
## How soon before the next target comes into use the policy sends its standing Knights off (the A policy's HEART_AHEAD); how far off the
## steps Mind Whisper sends Odran in his rite.
const HEART_AHEAD := 25.0
const HEART_OFF := 4.0

## Exodus: a watcher within EXODUS_THREAT of a believer is a threat (his sight is EscortDirector.SIGHT), within EXODUS_IMMINENT on him now; a
## lamp within EXODUS_GATE_AHEAD of a watched gate's mouth has its watch held; Oathbound is kept for leading when a household is due within
## EXODUS_OATH_WAIT (its cooldown) or a lamp is not yet led; a household is led again after EXODUS_REPEAT; Death Mark takes only what keeps
## Halcyon's Gaze within EXODUS_GAZE_CAP.
const EXODUS_THREAT := 6.5
const EXODUS_IMMINENT := 3.8
const EXODUS_GATE_AHEAD := 7.0
const EXODUS_OATH_WAIT := 45.0
const EXODUS_REPEAT := 60.0
const EXODUS_GAZE_CAP := 60.0

## The Long Night's Festival: the second of the act from which loadout B casts.
const FESTIVAL_FROM := 4.0

## Last Judgement: a gate's queue this long is jammed by Blight; the share of the population's breaking point lost beyond which the plague
## and the madness stop; Dragonfire Parade's breath, its reach and the angles about its facing (east) it sweeps, in radians
## (DragonfireParade's SWEEP_ARC and BEAM_HALF_ANGLE).
const JUDGEMENT_QUEUE := 3
const JUDGEMENT_STOP := 0.85
const DRAGON_R := 11.0
const DRAGON_FROM := -0.62
const DRAGON_TO := 0.34


# ---------------------------------------------------------------------------------------------------------------------------------
# Last Judgement and The Long Night
# ---------------------------------------------------------------------------------------------------------------------------------

## Last Judgement's loadout B (v0.11.1, spec §7.2 row 21): Mob Verdict on the Citadel, Dragonfire and Ember on the standing city, Pestilence
## and Madness Bloom on its people, Blight on the gate with the longest queue (it jams for Crowd.GATE_JAM seconds, so fewer escape).

## The thickest knot of living citizens out of doors within `r` of its middle, nearest `near` first when given: its middle, or INF.
static func _knot(crowd: Crowd, r: float, near := Vector2.INF, within := INF) -> Vector2:
	var pts: Array[Vector2] = []
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and (near == Vector2.INF or p.ground_pos.distance_to(near) <= within):
			pts.append(p.ground_pos)
	var best := Vector2.INF
	var best_n := 0
	for a in pts:
		var sum := Vector2.ZERO
		var n := 0
		for b in pts:
			if b.distance_to(a) <= r:
				sum += b
				n += 1
		if n > best_n:
			best_n = n
			best = sum / float(n)
	return best


## What a standing building is worth to the stability still to break (the weights of the behaviour check's _richest()): its share of the
## part's breaking point, 0 for a part already broken or a building City Stability does not count.
static func _worth(rules: Rules, b: Structure) -> float:
	var st := rules.stability
	if Stability.INFRA_ROLES.has(b.role) and st.infrastructure > 0.0:
		return Stability.W_INFRASTRUCTURE * b.footprint.get_area() / (st._infra_area * Stability.INFRASTRUCTURE_BROKEN)
	if Stability.RESOURCE_ROLES.has(b.role) and st.resources > 0.0:
		return Stability.W_RESOURCES / (float(st._resource_count) * Stability.RESOURCES_BROKEN)
	if b.role == &"barracks" and st._barracks_count > 0:
		return Stability.W_MILITARY * (1.0 - Stability.MILITARY_SOLDIER_SHARE) / float(st._barracks_count)
	if b.role == &"citadel" and st.leadership > 0.0:
		return Stability.W_LEADERSHIP * st.leadership / 9.0
	return 0.0


## Where a Dragonfire Parade's breath takes the most worth (v0.11.1): the dragon faces east and sweeps DRAGON_SWEEP radians about its facing
## out to DRAGON_R, so of the standing buildings' middles the one whose sector holds the most is where it rises.
static func _dragon_aim(rules: Rules, env: EnvironmentField) -> Vector2:
	var pts: Array[Vector2] = []
	var ws: Array[float] = []
	for b in env.structures():
		if is_instance_valid(b) and not b.destroyed:
			var w := _worth(rules, b)
			if w > 0.0:
				pts.append(b.footprint.get_center())
				ws.append(w)
	var best := Vector2.INF
	var best_w := -1.0
	for i in pts.size():
		for off: Vector2 in [Vector2(-1.5, 0.0), Vector2(0.0, 0.0), Vector2(0.0, -1.5), Vector2(0.0, 1.5)]:
			var o := pts[i] + off
			var sum := 0.0
			for j in pts.size():
				var rel := pts[j] - o
				if rel.length() <= DRAGON_R and rel.length() > 1.0 and rel.angle() >= DRAGON_FROM and rel.angle() <= DRAGON_TO:
					sum += ws[j]
			if sum > best_w:
				best_w = sum
				best = o
	return best


static func act_judgement(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var mission: Mission = ctx.mission
	var town: Town = mission._town
	if rules.elapsed() < 3.0:
		return ""
	var lost := float(crowd.killed_citizens + crowd.escaped_count) / maxf(float(crowd.spawned_citizens) * Stability.POPULATION_BROKEN, 1.0)
	# Gates first while the town runs for them: the longest queue jams for Crowd.GATE_JAM seconds.
	if bc._slot_ready(rules, slots, "blight"):
		var best: Structure = null
		var most := 0
		for g in town.gates:
			if is_instance_valid(g) and not g.destroyed:
				var n := crowd.waiting_at(g)
				if n > most:
					most = n
					best = g
		if best != null and most >= JUDGEMENT_QUEUE:
			rules.cast(slots.blight, best.center())
			return "blight a gate (%d waiting)" % most
	if bc._slot_ready(rules, slots, "verdict") and not town.citadel.is_fallen():
		var keep := town.citadel.keep.center()
		var mob := _knot(crowd, MobVerdictFx.RADIUS - 1.0, keep, 14.0)
		if mob != Vector2.INF:
			rules.cast(slots.verdict, keep, {"to": mob})
			return "verdict on the Citadel"
	if bc._slot_ready(rules, slots, "dragon"):
		var at := _dragon_aim(rules, mission._bf.ctx.env)
		rules.cast(slots.dragon, at, {"dir": Vector2(1, 0)})
		return "dragonfire"
	# The plague and the madness on the thickest knots of the living, until the people are as good as broken: the Gaze counts every death seen.
	if lost < JUDGEMENT_STOP:
		for key in ["pestilence", "madness"]:
			if bc._slot_ready(rules, slots, key):
				var at := _knot(crowd, 3.0)
				if at != Vector2.INF:
					rules.cast(slots[key], at)
					return key
	if bc._slot_ready(rules, slots, "ember"):
		var at: Vector2 = bc._richest(rules, mission._bf.ctx.env, crowd)
		rules.cast(slots.ember, at)
		return "ember"
	return ""


static func state_judgement(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	var town: Town = ctx.mission._town
	var gaze: GazeMeter = ctx.mission._descent.gaze if ctx.mission._descent != null else null
	return "citadel=%d%% stability=%s escaped=%d killed=%d/%d buildings=%d gaze=%d stage=%s" % [roundi(town.citadel.fraction() * 100.0),
		bc._stability(rules), crowd.escaped_count, crowd.killed_citizens, crowd.killed_soldiers, rules.buildings_down,
		roundi(gaze.value) if gaze != null else -1, crowd.alarms.stage_name()]


## The Long Night on loadout B (v0.11.1, spec §7.2 row 22; behaviour_check's _night() drafts each act's from RouteBook.ACTS_B and calls this
## at every look of the act it plays): the Omen as The Warning's B, the Festival's and the Procession's, Judgement as Last Judgement's.
## The Festival's and the Procession's policies are written here as the night needs them (Tier 3's and Tier 4's own, for their board
## missions, are in their tier files; the controller dedupes after merging).
static func act_night(bc, ctx: Dictionary) -> String:
	match String(ctx.mission.act().id):
		"omen":
			return _omen_runner(bc, ctx, ctx.d as WarningDirector)
		"festival":
			return _night_festival(bc, ctx)
		"procession":
			return _night_procession(bc, ctx)
		"judgement":
			return act_judgement(bc, ctx)
	return ""


static func state_night(bc, ctx: Dictionary) -> String:
	match String(ctx.mission.act().id):
		"omen":
			var w := ctx.d as WarningDirector
			return "phase=%s relays=%d messenger=%s" % [WarningDirector.Phase.keys()[w.phase], w.relays, bc._warning_mind(w.messenger)]
		"festival":
			var f := ctx.d as FestivalDirector
			return "lost=%d/%d mayor=%s" % [f.count(), f.need, bc._warning_mind(f.mayor)]
		"procession":
			var pr := ctx.d as ProcessionDirector
			return "leg=%d prince=%s boarded=%s" % [pr.leg, bc._warning_mind(pr.prince), pr.boarded]
		"judgement":
			return state_judgement(bc, ctx)
	return ""


## One look of The Warning's runner on loadout B (v0.11.1, Task 8's act_warning_runner(bc, ctx, w) in tier1_b.gd, rebuilt here from the same
## rule): Death Mark the runner once he is out of doors and alone (nobody within the witness distance, now nor where he will be), and
## while the mark works Mind Whisper sends him back toward the gate, Discord holds him -- the death comes 10 s late and fails if he is inside.
static func _omen_runner(bc, ctx: Dictionary, w: WarningDirector) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var m := w.messenger
	if not is_instance_valid(m) or not m.is_alive() or w.warning_dead or m.inside:
		return ""
	if not _marked(m) and bc._slot_ready(rules, slots, "deathmark") and bc._warning_alone(m, crowd):
		rules.cast(slots.deathmark, m.ground_pos)
		return "mark the runner"
	if m.mind == Person.Mind.DUTY:
		if bc._slot_ready(rules, slots, "whisper") and not m.shaken():
			var back: Vector2 = w.gate_spot - m.ground_pos
			if back.length() < 0.5:
				back = -bc._warning_heading(m)
			var to := MindWhisperFx.clamp_to(crowd._grid, m.ground_pos, m.ground_pos + back.normalized() * bc.WARNING_WHISPER_BACK)
			rules.cast(slots.whisper, m.ground_pos, {"to": to, "target": m})
			return "whisper the runner back"
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, m.ground_pos)
			return "discord the runner"
	return ""


## The Festival on loadout B (v0.11.1, spec §7.2 row 12): Heaven Splitter through the thickest knot of the crowd, Smite on the Mayor,
## Ember on the square once the others cool -- from FESTIVAL_FROM, no waiting for the bonfire (the goers are in the square from the start).
static func _night_festival(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as FestivalDirector
	var t := d.timeline.elapsed()
	if t < FESTIVAL_FROM:
		return ""
	if bc._slot_ready(rules, slots, "heaven"):
		var at := _goers_knot(d, 2.5)
		if at != Vector2.INF:
			rules.cast(slots.heaven, at, {"dir": Vector2(1, 0)})
			return "heaven the crowd"
	if bc._slot_ready(rules, slots, "smite") and WarningDirector._alive(d.mayor):
		rules.cast(slots.smite, d.mayor.ground_pos)
		return "smite the Mayor"
	if bc._slot_ready(rules, slots, "ember"):
		var at := _goers_knot(d, 3.0)
		if at != Vector2.INF:
			rules.cast(slots.ember, at)
			return "ember the square"
	return ""


## The middle of the thickest knot of the Festival's living goers within `r`, or INF. Only reads.
static func _goers_knot(d: FestivalDirector, r: float) -> Vector2:
	var pts: Array[Vector2] = []
	for g in d.goers:
		if is_instance_valid(g) and g.is_alive() and not g.inside:
			pts.append(g.ground_pos)
	var best := Vector2.INF
	var best_n := 0
	for a in pts:
		var sum := Vector2.ZERO
		var n := 0
		for b in pts:
			if b.distance_to(a) <= r:
				sum += b
				n += 1
		if n > best_n:
			best_n = n
			best = sum / float(n)
	return best


## The Procession on loadout B (v0.11.1, spec §7.2 row 16): Smite on the Prince himself the moment he is out of doors, Heaven Splitter
## and Death Mark on him when Smite cools (a blow on one man, seen or not -- the escort and the crowd are not his).
static func _night_procession(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as ProcessionDirector
	if d.boarded or not WarningDirector._alive(d.prince):
		return ""
	var p := d.prince
	if p.inside:
		return ""
	if bc._slot_ready(rules, slots, "smite"):
		rules.cast(slots.smite, p.ground_pos)
		return "smite the Prince"
	if bc._slot_ready(rules, slots, "heaven"):
		rules.cast(slots.heaven, p.ground_pos, {"dir": Vector2(1, 0)})
		return "heaven the Prince"
	if bc._slot_ready(rules, slots, "deathmark") and not _marked(p):
		rules.cast(slots.deathmark, p.ground_pos)
		return "mark the Prince"
	return ""


# ---------------------------------------------------------------------------------------------------------------------------------
# Exodus
# ---------------------------------------------------------------------------------------------------------------------------------

## Exodus on loadout B (v0.11.1, spec §7.2 row 24: wisp, deathmark, oath, discord, thorns). A held charge is on duty and no Wisp draws him
## (Person.lure() takes a charge only if the director set answers_lure -- and then only within WillOWisp.CHARGE_LURE_R, a few units a
## cast, a household's road is twelve to sixteen): the household is led by Oathbound's HOLD A PLACE instead, one cast to the way out, and
## every watcher about to see a believer is held (Oathbound REMAIN, Discord) or marked (Death Mark).

## The living out of doors who watch for a believer (the Exodus director's _watching()), as people. Only reads.
static func _exodus_watchers(d: ExodusDirector) -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in d._watchers():
		if d._watching(v) and not d._seizing(v):
			out.append(v as Person)
	return out


## The nearest distance from `at` to a believer out of doors and not yet resolved; INF with none. Only reads.
static func _exodus_gap(d: ExodusDirector, at: Vector2) -> float:
	var gap := INF
	for c in d.charges:
		if not d._resolved(c) and not (c.man as Person).inside:
			gap = minf(gap, at.distance_to((c.man as Person).ground_pos))
	return gap


## Holds watcher `p` where he stands (Oathbound first only for a rescue, or when no household waits to be led): Oathbound REMAIN on him and the watchers within its reach of him, else Discord when no believer would be
## taken with it, else Death Mark when his fall goes unseen. "" when nothing serves.
static func _exodus_hold(bc, ctx: Dictionary, p: Person, rescue := false) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d: ExodusDirector = ctx.d
	var crowd: Crowd = ctx.crowd
	if bc._slot_ready(rules, slots, "oath") and (rescue or not ctx.memo.get("oath_for_lead", false)):
		rules.cast(slots.oath, p.ground_pos, {"mode": "remain"})
		return "oath an Inquisitor to stay"
	if bc._slot_ready(rules, slots, "discord") and _exodus_gap(d, p.ground_pos) > DiscordFx.DISCORD_R + 0.5:
		rules.cast(slots.discord, p.ground_pos)
		return "discord an Inquisitor"
	if bc._slot_ready(rules, slots, "deathmark") and not _marked(p) and bc._doom_unseen(crowd, p.ground_pos, bc._exodus_flock(d), bc.EXODUS_MARGIN):
		rules.cast(slots.deathmark, p.ground_pos)
		return "mark an Inquisitor"
	return ""


static func act_exodus(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d: ExodusDirector = ctx.d
	var crowd: Crowd = ctx.crowd
	var memo: Dictionary = ctx.memo
	var led: Dictionary = memo.get("led", {})
	memo.led = led
	# Oathbound is kept for leading: a household out and not led, or the next due within its cooldown.
	var due := d.upcoming()
	memo.oath_for_lead = due >= 0 and d.due_in(due) <= EXODUS_OATH_WAIT
	# A believer seized: his seizer held, else marked.
	for c in d.charges:
		if not c.held or d._resolved(c) or not WarningDirector._alive(c.seizer):
			continue
		var did := _exodus_hold(bc, ctx, c.seizer as Person, true)
		if did != "":
			return did
	# Each household out is led to its gate in one cast of Oathbound's HOLD A PLACE, before anything else.
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		if not h.out or h.done:
			continue
		var lead := d.lamp(i)
		if lead == null:
			continue
		var lp := lead.man as Person
		var mates := 0
		for c: EscortDirector.Charge in h.members:
			if not d._resolved(c) and not c.held and not (c.man as Person).inside and (c.man as Person).ground_pos.distance_to(lp.ground_pos) <= OathboundFx.PICK_R:
				mates += 1
		var last: float = float(led.get(i, -1000.0))
		if mates >= 1 and d._clock - last >= EXODUS_REPEAT:
			memo.oath_for_lead = true
			if bc._slot_ready(rules, slots, "oath"):
				var exit: Vector2 = d.road(i).back()
				var centre := Vector2.ZERO
				var n := 0
				for c: EscortDirector.Charge in h.members:
					if not d._resolved(c) and not c.held and not (c.man as Person).inside and (c.man as Person).ground_pos.distance_to(lp.ground_pos) <= OathboundFx.PICK_R:
						centre += (c.man as Person).ground_pos
						n += 1
				led[i] = d._clock
				rules.cast(slots.oath, centre / float(maxi(n, 1)), {"mode": "hold", "to": exit})
				return "oath the %s household to its gate (%d)" % [h.name.to_lower(), n]
	# The gate a household's lamp is nearing, watched: its pair held as the household arrives (Discord on both, else Oathbound REMAIN).
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		var lead := d.lamp(i)
		if not h.out or h.done or lead == null:
			continue
		var exit: Vector2 = d.road(i).back()
		for g in d.gates.size():
			var gate: ExodusDirector.Gate = d.gates[g]
			if gate.way_out != exit or gate.shut or not d.gate_watched(g):
				continue
			if bc._walk_len(crowd, (lead.man as Person).ground_pos, gate.mouth) > EXODUS_GATE_AHEAD:
				continue
			var pair: Array[Person] = []
			var centre := Vector2.ZERO
			for k in d.watch.size():
				if k / ExodusDirector.GATE_WATCH == g and d._watching(d.watch[k]) and (d.watch[k] as Person).ground_pos.distance_to(gate.mouth) <= EscortDirector.SIGHT + 2.0:
					pair.append(d.watch[k] as Person)
					centre += (d.watch[k] as Person).ground_pos
			if pair.is_empty():
				continue
			centre /= float(pair.size())
			var together := true
			for p in pair:
				together = together and p.ground_pos.distance_to(centre) <= DiscordFx.DISCORD_R - 0.05
			if together and _exodus_gap(d, centre) > DiscordFx.DISCORD_R + 0.5 and bc._slot_ready(rules, slots, "discord"):
				rules.cast(slots.discord, centre)
				return "discord the %s's watch" % gate.words
			if together and bc._slot_ready(rules, slots, "oath") and not memo.get("oath_for_lead", false):
				rules.cast(slots.oath, centre, {"mode": "remain"})
				return "oath the %s's watch to stay" % gate.words
	# Death Mark, whenever it is ready: a searcher out after a believer, else a patrolman (neither is ever replaced), a seen death costing
	# Halcyon's Gaze its SEEN_DEATH, within a player's budget.
	if bc._slot_ready(rules, slots, "deathmark") and d.gaze.value + GazeMeter.SEEN_DEATH <= EXODUS_GAZE_CAP:
		var pick: Person = null
		for v: Variant in d._watchers():
			if d._watching(v) and not _marked(v as Person) and d._is_searcher(v):
				pick = v as Person
				break
		if pick == null:
			for squad: Array in d.patrols:
				for v: Variant in squad:
					if pick == null and d._watching(v) and not _marked(v as Person):
						pick = v as Person
		if pick == null and d.upcoming() >= 0:  # none on the beat: a watchman of the gate the next household will make for
			var exit: Vector2 = d.road(d.upcoming()).back()
			for g in d.gates.size():
				if (d.gates[g] as ExodusDirector.Gate).way_out != exit:
					continue
				for k in d.watch.size():
					if pick == null and k / ExodusDirector.GATE_WATCH == g and d._watching(d.watch[k]) and not _marked(d.watch[k] as Person):
						pick = d.watch[k] as Person
		if pick != null:
			rules.cast(slots.deathmark, pick.ground_pos)
			return "mark an Inquisitor on the beat"
	# The watchers about to see a believer, nearest first: held when they are on him (Oathbound, Discord), marked while there is time.
	var threats: Array[Person] = []
	for p in _exodus_watchers(d):
		if _exodus_gap(d, p.ground_pos) <= EXODUS_THREAT:
			threats.append(p)
	threats.sort_custom(func(a: Person, b: Person) -> bool: return _exodus_gap(d, a.ground_pos) < _exodus_gap(d, b.ground_pos))
	for p in threats:
		var did := ""
		if _exodus_gap(d, p.ground_pos) <= EXODUS_IMMINENT:
			did = _exodus_hold(bc, ctx, p)
		elif bc._slot_ready(rules, slots, "deathmark") and not _marked(p) and bc._doom_unseen(crowd, p.ground_pos, bc._exodus_flock(d), bc.EXODUS_MARGIN):
			rules.cast(slots.deathmark, p.ground_pos)
			did = "mark an Inquisitor"
		if did != "":
			return did
	return ""


static func state_exodus(_bc, ctx: Dictionary) -> String:
	var d: ExodusDirector = ctx.d
	return "out=%d left=%d current=%d seizures=%d gaze=%d phase=%s" % [d.out_count(), d.left_count(), d.current(), d.seizures,
		roundi(d.gaze.value), d.hint_phase()]


# ---------------------------------------------------------------------------------------------------------------------------------
# The Lantern's Eye
# ---------------------------------------------------------------------------------------------------------------------------------

## Where Blight clouds mirror `i`'s glass: a point just off the tower's outer face (the middle, then either side) within BlightFx.REACH of
## the tower that no lit pool lies near (bc._eye_lit()); Vector2.INF for none. Blight kills no one, so no onlooker matters. Only reads.
static func _eye_aim(bc, d: LanternEyeDirector, i: int) -> Vector2:
	var tw := d.towers[i]
	var face := d.outer_face(i)
	var side := d.along(i)
	for at: Vector2 in [face, face + side * EYE_SLIDE, face - side * EYE_SLIDE]:
		if tw.distance_to(at) <= EYE_BLIGHT_REACH and not bc._eye_lit(d, at):
			return at
	return Vector2.INF


## `p` carries Death Mark's frail mark already. Only reads.
static func _marked(p: Person) -> bool:
	return p.statuses.has(&"frail")


## One look of The Lantern's Eye on loadout B (v0.11.1, spec §7.2 row 23; mission spec §1's rules: never cast where a beam shines): what
## was cast, or "". The first that applies: a shattered mirror's wrights at work -- Mind Whisper sends one off, Discord takes one, else
## Death Mark on one alone; the current mirror open, none of its party walking back, Discord and Mind Whisper ready (or soon) for its
## wrights -- Blight at its tower's outer face, else, a beam on that face, a Will-o'-Wisp six units beyond it; the current mirror standing,
## or the next due within EYE_AHEAD -- Death Mark on a guard of its party that nobody would see fall, else a Will-o'-Wisp draws off the
## passers-by who would see it, else Mind Whisper sends one on guard off; a relief walking in -- the same.
static func act_eye(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d: LanternEyeDirector = ctx.d
	var crowd: Crowd = ctx.crowd
	for i in d.steps.size():
		if not d.shattered[i] or d.steps[i].broken:
			continue
		var crew: Array[Person] = []
		for w: HuntDirector.Guard in d.wrights[i]:
			if d._working(w) and not bc._eye_lit(d, (w.man as Person).ground_pos):
				crew.append(w.man as Person)
		if crew.is_empty():
			continue
		if bc._slot_ready(rules, slots, "whisper"):
			for p in crew:
				if not p.shaken():
					rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": bc._eye_off(d, crowd, p, d.towers[i].center())})
					return "whisper a wright off %s" % d.steps[i].words
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, crew[0].ground_pos)
			return "discord a wright at %s" % d.steps[i].words
		if bc._slot_ready(rules, slots, "deathmark"):
			for p in crew:
				if not _marked(p) and bc._eye_unseen(crowd, p.ground_pos):
					rules.cast(slots.deathmark, p.ground_pos)
					return "mark a wright at %s" % d.steps[i].words
	var cur := d.current()
	var crew_ready := slots.has("discord") and slots.has("whisper") and rules.cooldown_left(int(slots.discord)) <= EYE_CREW_WAIT \
		and rules.cooldown_left(int(slots.whisper)) <= EYE_CREW_WAIT
	if cur >= 0 and not d.shattered[cur] and not d.guarded(cur) and not bc._eye_coming(d, cur) and crew_ready \
			and bc._slot_ready(rules, slots, "blight"):
		var aim := _eye_aim(bc, d, cur)
		if aim != Vector2.INF:
			rules.cast(slots.blight, aim)
			return "blight the mirror on %s" % d.steps[cur].words
		if bc._eye_lit(d, d.outer_face(cur)) and bc._slot_ready(rules, slots, "wisp"):
			var lure: Vector2 = d.outer_face(cur) + (d.outer_face(cur) - d.towers[cur].center()).normalized() * bc.EYE_WISP
			if not bc._eye_lit(d, lure):
				rules.cast(slots.wisp, lure)
				return "wisp off %s" % d.steps[cur].words
	var struck := cur >= 0 and d.shattered[cur]
	var work: Array[int] = []
	if cur >= 0 and not d.shattered[cur]:
		work.append(cur)
	var n := d.next_step()
	if n >= 0 and d.due_in(n) <= EYE_AHEAD and not struck:
		work.append(n)
	for i in work:
		var on := d.party_on(i)
		var relief := d.relief_walking(i)
		if relief != null:
			on.append(relief)
		if bc._slot_ready(rules, slots, "deathmark"):
			for p in on:
				if not _marked(p) and not bc._eye_lit(d, p.ground_pos) and bc._eye_unseen(crowd, p.ground_pos):
					rules.cast(slots.deathmark, p.ground_pos)
					return "mark a guard of %s" % d.steps[i].words
			if bc._slot_ready(rules, slots, "wisp"):
				for p in on:
					if _marked(p):
						continue
					var lure: Vector2 = bc._eye_lure(d, crowd, i, p)
					if lure != Vector2.INF:
						rules.cast(slots.wisp, lure)
						return "wisp the passers-by off a guard of %s" % d.steps[i].words
		if bc._slot_ready(rules, slots, "whisper"):
			for p in on:
				if not bc._eye_lit(d, p.ground_pos) and not p.shaken():
					rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": bc._eye_off(d, crowd, p, d.towers[i].center())})
					return "whisper a guard of %s off" % d.steps[i].words
	return ""


static func state_eye(_bc, ctx: Dictionary) -> String:
	var d: LanternEyeDirector = ctx.d
	return "gone=%d current=%d next=%d shattered=%d eye=%.0f gaze=%d phase=%s" % [d.broken_count(), d.current(), d.next_step(),
		d.shattered_now(), d.eye_left(), roundi(d.gaze.value), d.hint_phase()]


# ---------------------------------------------------------------------------------------------------------------------------------
# The Heart of Faith
# ---------------------------------------------------------------------------------------------------------------------------------

## Whether a Heaven Splitter landing at `at` along `dir` fells structure `s`: inside its killing core, or its line (HeavenSplitter's
## LINE_LENGTH / LINE_HALF_WIDTH band, EnvironmentField.damage_lane()'s test). Only reads.
static func _heart_fells(s: Structure, at: Vector2, dir: Vector2) -> bool:
	if s.distance_to(at) <= HEART_CORE_R:
		return true
	var side := dir.orthogonal()
	var half := s.footprint.size * 0.5
	var rel := s.center() - at
	var along := rel.dot(dir)
	var across := rel.dot(side)
	var ext_along := absf(half.x * dir.x) + absf(half.y * dir.y)
	var ext_side := absf(half.x * side.x) + absf(half.y * side.y)
	return along + ext_along >= -HEART_LINE and along - ext_along <= HEART_LINE and absf(across) <= HEART_LINE_HALF + ext_side


## Where to drop a Heaven Splitter that fells target `s` and kills the fewest of the living out of doors (not those in `spare`, who are drawn
## away): of the points within reach of its line the one with the fewest within HEART_BLAST, then the nearest the target; its line aimed
## at the target. {"at", "dir", "n"}. Only reads.
static func _heart_drop(crowd: Crowd, s: Structure, spare: Array[Person], avoid: Array[Structure]) -> Dictionary:
	var people: Array[Vector2] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if is_instance_valid(o) and o.is_alive() and not o.inside and not spare.has(o):
				people.append(o.ground_pos)
	var c := s.center()
	var reach := s.footprint.size.length() * 0.5 + HEART_LINE
	var best := {"at": c, "dir": Vector2(1, 0), "n": 100000}
	var best_gap := INF
	var y := -reach
	while y <= reach:
		var x := -reach
		while x <= reach:
			var at := c + Vector2(x, y)
			var dir := (c - at).normalized() if c.distance_to(at) > 0.5 else Vector2(1, 0)
			var spares := true
			for a in avoid:
				spares = spares and not _heart_fells(a, at, dir) and a.distance_to(at) > HEART_CORE_R + 1.0
			if spares and _heart_fells(s, at, dir):
				var n := 0
				for q in people:
					if q.distance_to(at) <= HEART_BLAST:
						n += 1
				var gap := c.distance_to(at)
				if n < int(best.n) or (n == int(best.n) and gap < best_gap):
					best = {"at": at, "dir": dir, "n": n}
					best_gap = gap
			x += HEART_STEP
		y += HEART_STEP
	return best


## The Heart's other targets standing: a Heaven Splitter meant for target `i` spares them (a fall ahead of its time would hurry the night).
static func _heart_others(d: HeartOfFaithDirector, i: int) -> Array[Structure]:
	var out: Array[Structure] = []
	for k in d.targets.size():
		if k != i and is_instance_valid(d.targets[k]) and not d.targets[k].destroyed:
			out.append(d.targets[k])
	return out


## Where a Will-o'-Wisp draws target `i`'s Knights `on` off it, beyond a Heaven Splitter at `drop`: of the points on walkable ground at least
## HEART_BLAST + HEART_RING from `drop`, within the Knights' reach, the one that draws the most of them (within HEART_DRAW), and of those the
## one with fewest others drawn too; Vector2.INF when it draws none. `n` gets how many it draws. Only reads.
static func _heart_lure_spot(bc, d: HeartOfFaithDirector, crowd: Crowd, i: int, on: Array[Person], drop: Vector2, n: Array) -> Vector2:
	var mean := Vector2.ZERO
	for p in on:
		mean += p.ground_pos
	mean /= float(maxi(on.size(), 1))
	var best := Vector2.INF
	var best_score := -INF
	var best_n := 0
	var y := -HEART_DRAW
	while y <= HEART_DRAW:
		var x := -HEART_DRAW
		while x <= HEART_DRAW:
			var at := mean + Vector2(x, y)
			x += HEART_STEP
			if at.distance_to(drop) < HEART_BLAST + HEART_RING or d._walkable(at).distance_to(at) > 0.3 \
					or d.targets[i].distance_to(at) < d.GUARD_REACH + HEART_RING_MAX:
				continue
			var drawn := 0
			for p in on:
				if p.ground_pos.distance_to(at) <= HEART_DRAW and bc._walk_len(crowd, p.ground_pos, at) <= HEART_WALK:
					drawn += 1
			if drawn == 0:
				continue
			var others := 0
			for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
				for o in group:
					if is_instance_valid(o) and o.is_alive() and not o.inside and not on.has(o) and o.ground_pos.distance_to(at) <= HEART_DRAW:
						others += 1
			var score := float(drawn) * 10.0 - float(others)
			if score > best_score:
				best_score = score
				best = at
				best_n = drawn
		y += HEART_STEP
	n.clear()
	n.append(best_n)
	return best


## Target `i`'s Knights on guard or about to be: standing guard now, or free of the god's hold and within HEART_COMING of the target (a relief
## walking in, one walking back from a whisper). Only reads.
static func _heart_on(d: HeartOfFaithDirector, i: int) -> Array[Person]:
	var out := d.guards_at(i)
	for p in d.standing_at(i):
		if not out.has(p) and not p.mind in [Person.Mind.WHISPERED, Person.Mind.CONFUSED, Person.Mind.OBSERVE] \
				and d.targets[i].distance_to(p.ground_pos) <= HeartOfFaithDirector.GUARD_REACH + HEART_COMING:
			out.append(p)
	return out


## Target `i`'s Knights on guard (or a relief about to be), cleared the way a player does it: a Will-o'-Wisp draws the ones it reaches off
## the target, Mind Whisper sends one off, Discord takes those within its swirl. "" when nothing serves.
static func _heart_clear(bc, ctx: Dictionary, i: int) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d: HeartOfFaithDirector = ctx.d
	var crowd: Crowd = ctx.crowd
	var on := _heart_on(d, i)
	if on.is_empty():
		return ""
	var words: String = HeartOfFaithDirector.WORDS[i]
	var drop := _heart_drop(crowd, d.targets[i], [], _heart_others(d, i))
	if bc._slot_ready(rules, slots, "wisp"):
		var n := []
		var at := _heart_lure_spot(bc, d, crowd, i, on, drop.at, n)
		if at != Vector2.INF and (int(n[0]) >= 2 or int(n[0]) == on.size()):
			rules.cast(slots.wisp, at)
			return "wisp the Knights off the %s" % words
	if bc._slot_ready(rules, slots, "whisper"):
		for p in on:
			if not p.shaken() and p.mind != Person.Mind.WHISPERED:
				var away := p.ground_pos - d.targets[i].center()
				away = away.normalized() if away.length() > 0.01 else Vector2.RIGHT
				rules.cast(slots.whisper, p.ground_pos, {"target": p,
					"to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + away * 8.0)})
				return "whisper a Knight off the %s" % words
	if bc._slot_ready(rules, slots, "wisp"):
		var n := []
		var at := _heart_lure_spot(bc, d, crowd, i, on, drop.at, n)
		if at != Vector2.INF:
			rules.cast(slots.wisp, at)
			return "wisp a Knight off the %s" % words
	return ""


## Nobody living out of doors but those of `who` stands within HEART_BLAST of `at`: a Heaven Splitter there takes only them. Only reads.
static func _heart_alone(crowd: Crowd, at: Vector2, who: Array[Person]) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if is_instance_valid(o) and o.is_alive() and not o.inside and not who.has(o) and o.ground_pos.distance_to(at) <= HEART_BLAST:
				return false
	return true


## Mind Whisper sends off the one nearest `at` within `reach` of it who is free of the god's hold: HEART_HUSH units straight away from `at`.
## "" when none, or the whisper is not ready.
static func _heart_hush(bc, ctx: Dictionary, at: Vector2, reach: float, words: String) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	if not bc._slot_ready(rules, slots, "whisper"):
		return ""
	var best: Person = null
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if is_instance_valid(o) and o.is_alive() and not o.inside and not o.shaken() and o.mind != Person.Mind.WHISPERED \
					and o.mind != Person.Mind.OBSERVE and o.ground_pos.distance_to(at) <= reach:
				if best == null or o.ground_pos.distance_to(at) < best.ground_pos.distance_to(at):
					best = o
	if best == null:
		return ""
	var away := best.ground_pos - at
	away = away.normalized() if away.length() > 0.01 else Vector2.RIGHT
	rules.cast(slots.whisper, best.ground_pos, {"target": best,
		"to": MindWhisperFx.clamp_to(crowd._grid, best.ground_pos, best.ground_pos + away * HEART_HUSH)})
	return "whisper %s" % words


## No one living out of doors stands within Crowd.DOOM_WITNESS of `p`: a Smite on him goes unseen. Only reads.
static func _heart_unseen(crowd: Crowd, p: Person) -> bool:
	return crowd.nearest_witness(p.ground_pos, p) == null


## Everyone living out of doors within Crowd.DOOM_WITNESS of `p`, but him: who would see him fall. Only reads.
static func _heart_seers(crowd: Crowd, p: Person) -> Array[Person]:
	var out: Array[Person] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if is_instance_valid(o) and o.is_alive() and not o.inside and o != p and o.ground_pos.distance_to(p.ground_pos) <= Crowd.DOOM_WITNESS:
				out.append(o)
	return out


## The point where a Heaven Splitter takes the most of `who` within HEART_CORE -- one of theirs, or their mean; Vector2.INF for fewer than
## `least`. Only reads.
static func _heart_core(who: Array[Person], least: int) -> Vector2:
	if who.is_empty():
		return Vector2.INF
	var pts: Array[Vector2] = []
	var mean := Vector2.ZERO
	for p in who:
		pts.append(p.ground_pos)
		mean += p.ground_pos
	pts.append(mean / float(who.size()))
	var best := Vector2.INF
	var best_n := 0
	for c in pts:
		var n := 0
		for p in who:
			if p.ground_pos.distance_to(c) <= HEART_CORE:
				n += 1
		if n > best_n:
			best_n = n
			best = c
	return best if best_n >= least else Vector2.INF


## One look of The Heart of Faith on loadout B (v0.11.1): what was cast, or "". The first that applies: Odran on foot out of doors -- Smite him
## (his death is the win, seen or not), else Death Mark, else Heaven Splitter, else, his rite running, Mind Whisper sends him off the steps; the
## litter's bearers (the flame out, Odran riding or not yet out) -- a Heaven Splitter where it takes two or more in its core, else Smite, else
## Death Mark, one; the target in use guarded -- its Knights cleared (_heart_clear()); unguarded -- Heaven Splitter on it. Never a blow on a
## target ahead of its time.
static func act_heart(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d: HeartOfFaithDirector = ctx.d
	var crowd: Crowd = ctx.crowd
	var afoot := d.odran_out and not d.riding and not d.odran_down() and not (d.odran as Person).inside
	if afoot:
		var o := d.odran as Person
		if bc._slot_ready(rules, slots, "smite"):
			rules.cast(slots.smite, o.ground_pos)
			return "smite Odran"
		if bc._slot_ready(rules, slots, "deathmark") and not _marked(o):
			rules.cast(slots.deathmark, o.ground_pos)
			return "mark Odran"
		if bc._slot_ready(rules, slots, "heaven"):
			rules.cast(slots.heaven, o.ground_pos, {"dir": Vector2(1, 0)})
			return "heaven Odran"
		if d.rite_on and bc._slot_ready(rules, slots, "whisper") and not o.shaken():
			var off: Vector2 = o.ground_pos + (o.ground_pos - d.temple.center()).normalized() * HEART_OFF
			rules.cast(slots.whisper, o.ground_pos, {"target": o, "to": MindWhisperFx.clamp_to(crowd._grid, o.ground_pos, off)})
			return "whisper Odran off the steps"
	if d.flame_out and (d.riding or not d.odran_out):
		var bs := d.bearers_standing()
		if bc._slot_ready(rules, slots, "heaven"):
			var at := _heart_core(bs, 2)
			if at != Vector2.INF and _heart_alone(crowd, at, bs):
				rules.cast(slots.heaven, at, {"dir": Vector2(1, 0)})
				return "heaven the litter's bearers"
		if bc._slot_ready(rules, slots, "smite"):
			for p in bs:
				if _heart_unseen(crowd, p):
					rules.cast(slots.smite, p.ground_pos)
					return "smite a bearer"
			for p in bs:
				var seers := _heart_seers(crowd, p)
				if seers.size() == 1:
					var did := _heart_hush(bc, ctx, p.ground_pos, Crowd.DOOM_WITNESS, "a witness off a bearer")
					if did != "":
						return did
		# at last, seen: Death Mark takes only the one it marks, within a player's Gaze budget (A's HEART_GAZE_CAP)
		if bc._slot_ready(rules, slots, "deathmark") and d.gaze.value + HeartOfFaithDirector.FURY <= bc.HEART_GAZE_CAP:
			for p in bs:
				if not _marked(p):
					rules.cast(slots.deathmark, p.ground_pos)
					return "mark a bearer, seen or not"
	if d.flame_out:
		return ""
	var cur := d.current()
	if cur >= 0:
		var did := _heart_clear(bc, ctx, cur)
		if did != "":
			return did
		var s := d.targets[cur]
		if _heart_on(d, cur).is_empty() and is_instance_valid(s) and not s.destroyed and bc._slot_ready(rules, slots, "heaven"):
			var drop := _heart_drop(crowd, s, [], _heart_others(d, cur))
			if int(drop.n) > HEART_NEAR_OK and ctx.memo.get("wait_from", -1.0) < 0.0:
				ctx.memo.wait_from = d._clock
			var waited: float = d._clock - float(ctx.memo.get("wait_from", d._clock))
			if int(drop.n) > HEART_NEAR_OK and waited < HEART_WAIT:
				return _heart_hush(bc, ctx, drop.at, HEART_BLAST, "off the %s's blast" % HeartOfFaithDirector.WORDS[cur])
			ctx.memo.wait_from = -1.0
			rules.cast(slots.heaven, drop.at, {"dir": drop.dir})
			return "heaven the %s (%d near)" % [HeartOfFaithDirector.WORDS[cur], int(drop.n)]
	var n := d.next_target()
	if n >= 0 and n != cur and d.stage_due(n) - d._clock <= HEART_AHEAD and bc._slot_ready(rules, slots, "whisper"):
		for p in d.standing_at(n):
			if not p.shaken() and p.mind != Person.Mind.WHISPERED:
				var away := p.ground_pos - d.targets[n].center()
				away = away.normalized() if away.length() > 0.01 else Vector2.RIGHT
				rules.cast(slots.whisper, p.ground_pos, {"target": p,
					"to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + away * 8.0)})
				return "whisper a Knight ahead of the %s" % HeartOfFaithDirector.WORDS[n]
	return ""


static func state_heart(_bc, ctx: Dictionary) -> String:
	var d: HeartOfFaithDirector = ctx.d
	return "razed=%d flame_out=%s odran=%s riding=%s rite=%.0f gaze=%d phase=%s" % [d.razed_count(), d.flame_out, d.odran_out, d.riding,
		d.rite_left, roundi(d.gaze.value), d.hint_phase()]
