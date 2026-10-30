extends RefCounted
## The scripted policies of the Hunt "Face Halcyon" (Tier 5; god P5, MS §6, §7, plan Tasks 3, 8, 13): the shared plan with the def's loadout (act_shared),
## one act_<type> per god type, and the report line (state). FILLED lists the types written (all six). Called by god_hunts.gd (Ruling P5-7: the policies
## live here, behaviour_check is never edited by a Hunt task). A believer is freed the moment fewer than FH_ESCORT_HOLD of his escort are able (alive, out of
## doors, with the procession, not held by the god, not frail, not afraid), so each type breaks the escort its own way, unseen where it can:
##   ruin     Smite the escort, the rear of the file first (nobody stands within the witness's reach of him); a Smite is loud, so a seen death costs the Gaze
##            (GazeMeter.SEEN_DEATH) and the bell's toll another 40: _room(). Ember lights a house the escort walks past and nothing happens to him (measured).
##   death    Death Mark (frail at once, so counted unable at once; dead in 10 s), the rear of the file first. Pestilence and Glacial Cataclysm are not
##            used: a plague spreads to the believer, and the freeze (5 units) shatters him when it thaws (a believer the god kills counts as burned).
##   veil     Blight the Bell Tower early (no toll all night), Silent Doom on the escort, the rear of the file first, aimed where he stands; Tsunami Breaker is
##            not used (its wave would take the believer on the same road).
##   passage  Mirrorfold Passage laid across the road ahead with its way out beyond the walls: the file walks in, is outside, and he is freed (the walls rule).
##            The Thornwall is not cast (a wall across a lane the file must walk shuts it in: tried, all four stood at the wall until dawn).
##   decree   Leaving Is Prohibited at the door of a house in the last moment before its procession forms up (those who come out are bound at once; the bars
##            count as held), else round the file; The Bell Lies, CALL THE GUARD, on the file when the law is cooling.
##   dominion Mind Whisper sends an escort off, Discord holds one more; Rewrite Priority only when both are cooling (its seal takes a second).
## Ruin, Veil and Death break a procession in an opener and a finisher FH_GAP apart (Silence the witness's precedent): _may_finish().
## Unlike Hunts 2-4, Decree has a route here (C9: those three Hunts report it as a gap).

## The god types whose policy is written (all six).
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

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

## The pieces every Hunt's policy shares (god_t1.gd): road_ahead(), cast_mirror(), cast_bell().
const GOD := preload("res://tools/dev/routes/god_t1.gd")

## How near the Gaze may climb before the shared plan stops striking where it can be seen (each seen death is GazeMeter.SEEN_DEATH of 100; three freed
## take at most six strikes).
const GAZE_CAP := 60.0


## The director when the night is on, else null.
static func _fh(ctx: Dictionary) -> FaceHalcyonDirector:
	return ctx.get("d") as FaceHalcyonDirector


## The numbers this Hunt's report lines print (MS §6): believers freed (and by what), burned and still to come, the Gaze, each procession's phase
## (W waiting, F forming, M marching, B burning, R freed, X burned, D dead) with its able escorts, the nearest two escorts of one procession have stood
## (ground units; min/looks under 1.6/looks) stopped at their places and walking, at a halt (forming, at the stake, held: halt=min/under/looks), the nearest two escorts of different companies (cross=min/looks under
## 1.6/looks with two companies out; the south-west house keeps less than 2.7 from the west and south-east roads, ruling P5-T8-R7), the hint's phase.
static func state(_bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var phases := ""
	var able := []
	for i in d.procs.size():
		phases += "WFMBRXD"[int(d.phase_of(i))]
		able.append(d.able_escort(i))
	return "freed=%d (broken %d walls %d) burned=%d left=%d gaze=%d phases=%s able=%s stopped=%.2f/%d/%d walking=%.2f/%d/%d pair_min=%.2f under1.6=%.1f%% halt=%.2f/%d/%d cross=%.2f/%d/%d phase=%s" % [d.freed(),
		d.freed_broken, d.freed_walls, d.burned(), d.left_count(), roundi(d.gaze.value), phases, able, minf(d.pair_min, 99.0), d.pair_under, d.pair_looks,
		minf(d.walk_min, 99.0), d.walk_under, d.walk_looks, minf(d.walk_min, 99.0), 100.0 * float(d.walk_under) / float(maxi(d.walk_looks, 1)),
		minf(d.halt_min, 99.0), d.halt_under, d.halt_looks, minf(d.cross_min, 99.0), d.cross_under, d.cross_looks, d.hint_phase()]


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


# --- Shared pieces for the types ---------------------------------------------------------------------------------------------------

## The second of the night (mission seconds): the director's clock.
static func _now(d: FaceHalcyonDirector) -> float:
	return d._clock


## How many more of procession `i`'s escorts must be broken before he is freed (able less one that may stay).
static func _need(d: FaceHalcyonDirector, i: int) -> int:
	return d.able_escort(i) - (FaceHalcyonDirector.FH_ESCORT_HOLD - 1)


## The processions that need work now, the one pressing hardest first (_pressing()): in custody, with more able escorts than the rule leaves him.
static func _works(d: FaceHalcyonDirector) -> Array[int]:
	var out: Array[int] = []
	for i in _pressing(d):
		if _need(d, i) > 0:
			out.append(i)
	return out


## Procession `i`'s escorts that count as able now, the rear of the file first (their index is their place: 0 the lead, then the second, the rear last).
static func _ables(d: FaceHalcyonDirector, i: int) -> Array[Person]:
	var pr: FaceHalcyonDirector.Procession = d.procs[i]
	var out: Array[Person] = []
	for k in range(pr.escorts.size() - 1, -1, -1):
		if d._able(pr, k) and d._fit(pr, k):
			out.append(pr.escorts[k] as Person)
	return out


## The believer of procession `i`.
static func _man(d: FaceHalcyonDirector, i: int) -> Person:
	return (d.procs[i] as FaceHalcyonDirector.Procession).charge.man as Person


## Everyone living out of doors within `radius` of `at`, citizens and soldiers: who a blow there takes.
static func _within(crowd: Crowd, at: Vector2, radius: float) -> Array[Person]:
	var out: Array[Person] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= radius:
				out.append(p)
	return out


## How many living people out of doors, `victims` bar, stand where they would see a death at `at` (Crowd.DOOM_WITNESS and a hair; the file's places are FH_APART, 2.2, apart): the believer too.
static func _seers(crowd: Crowd, at: Vector2, victims: Array) -> int:
	var n := 0
	for p in _within(crowd, at, Crowd.DOOM_WITNESS + 0.1):
		n += 0 if victims.has(p) else 1
	return n


## What a blow at `at` of `radius` would do to procession `i`: {"hit": the escorts it takes, "other": how many others it takes (the believer among them is
## fatal), "seen": how many stand where they would see it, "believer": it takes the believer}. Only reads.
static func _blow(d: FaceHalcyonDirector, crowd: Crowd, i: int, at: Vector2, radius: float) -> Dictionary:
	var pr: FaceHalcyonDirector.Procession = d.procs[i]
	var victims := _within(crowd, at, radius)
	var hit: Array[Person] = []
	var other := 0
	var believer := false
	for v in victims:
		if pr.escorts.has(v):
			hit.append(v)
		elif v == pr.charge.man or d.believers.has(v):
			believer = true
		else:
			other += 1
	return {"hit": hit, "other": other, "seen": _seers(crowd, at, victims), "believer": believer}


## How much of the Gaze a strike may still spend: GazeMeter.FULL less a death's worth of margin (a full Gaze loses), less what is there, less the toll the bell may
## still add (unless it is ruined or has tolled), less a seen death for each procession still to come after this one (each of those has an unseen rear to
## take and a second escort the believer sees). A strike that takes `n` deaths seen is allowed while this is at least SEEN_DEATH x n.
static func _room(d: FaceHalcyonDirector, rules: Rules, bell_ruined: bool) -> float:
	var toll := 0.0
	if not bell_ruined and rules.lantern != null and not rules.lantern.tolled:
		toll = LanternWatch.GAZE_TOLL
	var later := maxi(FaceHalcyonDirector.FH_NEED - d.freed() - 1, 0)
	return GazeMeter.FULL - GazeMeter.SEEN_DEATH - d.gaze.value - toll - GazeMeter.SEEN_DEATH * float(later)


## The pacing every type's policy keeps (god P5 Task 13, MS §0 and §7; the precedent is Silence the witness's SW_GAP): a procession is broken by an opener and a
## finisher at least FH_GAP seconds apart, the finisher the cast that leaves him no more than the rule allows. The Hunt's items come on the clock (30, 95, 160,
## 225 s) or 45 s after the one before is freed, and a lone cast made the moment a procession forms up frees it at once, so the next forms 45 s plus the cast's
## own delay after the last cast (idle 46 s); with the finisher FH_GAP after the opener the free comes at least 20 s after the forming, the next procession
## forms on its own clock (at 95 and 160), and the policy is never idle longer than the chain. Seconds are the mission's (the director's clock).
## Round 3 (P5-T13-R5 as amended): a HELD real cast -- the opener kills or marks an escort when it is made, and the finisher does the same FH_GAP later; neither is a filler.
## Without the hold (FH_GAP 0, schedule 44/109/174/239): ruin 175 / 175 / 158 s idle 45 / 45 / 44, veil 184 / 176 / 172 s idle 46 (over the bar), death unchanged
## (its cooldown is 20 s). With it: ruin 186 / 196 / 158 idle 44-45, veil 195 / 200 / 196 idle 45.
const FH_GAP := 20.0


## The cast that leaves procession `i` with no more able escorts than the rule allows may be made now: it is not the opener (the procession was opened FH_GAP
## seconds ago, `memo["open_<i>"]`), or the fire is near (URGENT). A cast that leaves more of them able than that is the opener and is always allowed.
static func _may_finish(d: FaceHalcyonDirector, ctx: Dictionary, i: int) -> bool:
	if _need(d, i) > 1:
		return true  # (this cast opens him: one more will still be wanted)
	var key := "open_%d" % i
	return not ctx.memo.has(key) or _now(d) - float(ctx.memo[key]) >= FH_GAP or d.pyre_in(i) <= URGENT


## Notes the cast on procession `i` that opened him (the first), for _may_finish().
static func _opened(d: FaceHalcyonDirector, ctx: Dictionary, i: int) -> void:
	if not ctx.memo.has("open_%d" % i):
		ctx.memo["open_%d" % i] = _now(d)


## The smallest circle round `points` that is centred on one of them, on the middle of two, or on all: {at, r}. (Silence the witness's, Task 10.)
static func _enclose(points: Array[Vector2]) -> Dictionary:
	var tries: Array[Vector2] = []
	var sum := Vector2.ZERO
	for q in points:
		tries.append(q)
		sum += q
	tries.append(sum / float(maxi(points.size(), 1)))
	for a in points.size():
		for b in range(a + 1, points.size()):
			tries.append((points[a] + points[b]) * 0.5)
	var best := {"at": Vector2.INF, "r": INF}
	for c in tries:
		var far := 0.0
		for q in points:
			far = maxf(far, c.distance_to(q))
		if far < float(best.r):
			best = {"at": c, "r": far}
	return best


# --- Ruin: Smite, Ember, Heaven Splitter -----------------------------------------------------------------------------------------------

## The seconds to the pyre at or under which a procession is struck whatever is seen (the Gaze permitting): the fire is near, and a death seen is cheaper than a
## believer burned (GazeMeter.SEEN_DEATH is 10 of 100).
const URGENT := 18.0


## The escort of procession `i` to be struck by a blow of `radius` led `lead` seconds, or {}: the rear of the file first (nearest nobody), the blow taking no
## believer and no bystander; one nobody would see fall before one somebody would. The believer sees whoever falls beside him, so each procession has one seen
## fall it cannot do without; a second is struck only once the fire is URGENT and the Gaze has room (_room()) -- until then the policy waits for a moment
## nobody is looking. {"e", "at", "seen", "hit"}.
static func _strike(d: FaceHalcyonDirector, ctx: Dictionary, i: int, radius: float, lead: float, bell_ruined: bool) -> Dictionary:
	var room := _room(d, ctx.rules, bell_ruined)
	var spent: int = int(ctx.memo.get("seen_%d" % i, 0))
	var urgent := d.pyre_in(i) <= URGENT
	var best := {}
	for e in _ables(d, i):
		var at: Vector2 = GOD.road_ahead(e, lead) if lead > 0.0 else e.ground_pos
		var b := _blow(d, ctx.crowd, i, at, radius)
		if b.believer or int(b.other) > 0 or (b.hit as Array).is_empty():
			continue
		var seen := int(b.seen)
		var cost := GazeMeter.SEEN_DEATH * float((b.hit as Array).size())
		if seen > 0:
			if room < cost or not (spent < 1 or urgent):
				continue
		if best.is_empty() or (seen == 0 and int(best.seen) > 0) or ((seen == 0) == (int(best.seen) == 0) and (b.hit as Array).size() > (best.hit as Array).size()):
			best = {"e": e, "at": at, "seen": seen, "hit": b.hit}
	return best


## Smite an escort (the rear of the file first, then the one nobody would see fall), led by the bolt's T_STRIKE. Heaven Splitter and Ember are not cast: the
## splitter's fissures reach seven units and would take the believer on the same road, and a fire is no answer to an escort who walks away from it.
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not bc._slot_ready(rules, slots, "smite"):
		return ""
	for i in _works(d):
		if not _may_finish(d, ctx, i):
			continue
		var pick := _strike(d, ctx, i, SmiteFx.KILL_R, SmiteFx.T_STRIKE, false)
		if not pick.is_empty():
			rules.cast(int(slots.smite), pick.at)
			_opened(d, ctx, i)
			ctx.memo["seen_%d" % i] = int(ctx.memo.get("seen_%d" % i, 0)) + (1 if int(pick.seen) > 0 else 0)
			return "smite an escort of procession %d%s" % [i, "" if int(pick.seen) == 0 else ", seen"]
	return ""


# --- Death: Death Mark, Pestilence, Glacial Cataclysm ----------------------------------------------------------------------------------

## Death Mark on an escort not yet marked, the rear of the file first: frail at once, so counted unable at once, and dead in ten seconds. (Pestilence would
## spread to the believer, and Glacial Cataclysm's freeze, five units wide, shatters him when it thaws: a believer the god kills counts as burned.)
static func act_death(bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not bc._slot_ready(rules, slots, "deathmark"):
		return ""
	for i in _works(d):
		if not _may_finish(d, ctx, i):
			continue
		for e in _ables(d, i):
			rules.cast(int(slots.deathmark), e.ground_pos)
			_opened(d, ctx, i)
			return "death mark an escort of procession %d" % i
	return ""


# --- Veil: Silent Doom, Blight, Tsunami Breaker ----------------------------------------------------------------------------------------

## Blight the Bell Tower first (no toll all night: the toll adds 40 to the Gaze); then Silent Doom on an escort, aimed where he stands (the victims are fixed
## at the cast), the rear of the file first, unseen at once and seen only after PATIENCE (_strike()). Tsunami Breaker's wave would take the believer on the
## same road.
static func act_veil(bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var tower: Structure = crowd.bell.tower if crowd.bell != null else null
	var cracked := tower == null or not is_instance_valid(tower) or tower.blighted or tower.destroyed
	if not cracked and bc._slot_ready(rules, slots, "blight"):
		rules.cast(int(slots.blight), tower.center())
		return "blight the Bell Tower, so a seen death tolls nothing"
	if not bc._slot_ready(rules, slots, "doom"):
		return ""
	for i in _works(d):
		if not _may_finish(d, ctx, i):
			continue
		var pick := _strike(d, ctx, i, SilentDoom.RADIUS, 0.0, true)
		if not pick.is_empty():
			rules.cast(int(slots.doom), pick.at)
			_opened(d, ctx, i)
			ctx.memo["seen_%d" % i] = int(ctx.memo.get("seen_%d" % i, 0)) + (1 if int(pick.seen) > 0 else 0)
			return "doom an escort of procession %d%s" % [i, "" if int(pick.seen) == 0 else ", seen"]
	return ""


# --- Passage: Thornwall, Mirrorfold Passage ---------------------------------------------------------------------------------------------

## How far ahead of the believer along his road the mirror's way in is laid, and the least road he must have left for it.
const MIRROR_AHEAD := 6.0
const MIRROR_ROAD := 8.0
## How far the way out may lie from the way in, and how far past the wall's own margin it is (so a man put there is out at the director's next look).
const MIRROR_REACH := 24.0
const MIRROR_BEYOND := 0.8


## Walkable ground out of the walls, a little past the wall's own margin, nearest `from` and no nearer than the mirror's MIN_APART; INF for none.
static func _beyond(crowd: Crowd, from: Vector2) -> Vector2:
	var best := Vector2.INF
	for rad: float in [3.0, 4.5, 6.0, 8.0, 10.0, 13.0, 16.0, MIRROR_REACH]:
		for k in 24:
			var g: Vector2 = crowd._grid.nearest_walkable(from + Vector2.from_angle(TAU * float(k) / 24.0) * rad, 2)
			if g == Vector2.INF or not Walls.outside(g) or City.current().town().grow(Walls.MARGIN + MIRROR_BEYOND).has_point(g):
				continue
			if g.distance_to(from) >= MirrorfoldFx.MIN_APART and (best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from)):
				best = g
		if best != Vector2.INF:
			return best
	return best


## Mirrorfold Passage across the believer's road ahead of his file, its way out past the walls: the file walks onto it, is that instant outside, and he is
## freed (the walls rule; an escort outside is sent off). The Thornwall is not cast: a wall across a lane the file must walk shuts it in (tried: a wall ahead of
## the file and the mirror beyond it left all four processions standing at the wall until dawn), and nothing else in this kit helps the mirror.
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	for i in _works(d):
		var p := _man(d, i)
		var road := d._road(p.ground_pos)
		if d._along_length(road) < MIRROR_ROAD or ctx.memo.has("mirror_%d" % i):
			continue
		if bc._slot_ready(rules, slots, "mirror"):
			var way_in := FaceHalcyonDirector._along(road, MIRROR_AHEAD)
			var way_out := _beyond(crowd, way_in)
			if way_out != Vector2.INF and GOD.cast_mirror(bc, ctx, way_in, way_out):
				ctx.memo["mirror_%d" % i] = true
				return "mirror procession %d out past the walls: in %.1f ahead of him, out at (%.1f, %.1f)" % [i, way_in.distance_to(p.ground_pos), way_out.x, way_out.y]
	return ""


# --- Decree: Leaving Is Prohibited, The Bell Lies, Magnify -----------------------------------------------------------------------------

## The law's circle must hold the file a moment on (its T_SEAL after the cast): how much of the circle's radius is kept in hand for the walk.
const LAW_SLACK := 0.5
## The law is laid at a house's door when its procession forms up in this many seconds or fewer (the seal takes NoLeaveFx.T_SEAL, 0.6).
const LAW_LEAD := 0.8


## Leaving Is Prohibited round as many of the able escorts as one circle holds (radius 3, less the walk to the seal), centred where the file will be; the bars
## count as held (Ruling P5-T8-R3). The Bell Lies, CALL THE GUARD, at the file when the law cools: up to twelve soldiers, the nearest first, run to the click
## and stand: the escort among them.
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	# The law at a house's door in the last moment before its procession forms up: those who come out are inside the circle and bound at once (the cast's own
	# delay, T_SEAL, is spent before the door opens, so the free is not 45 s plus the delay after the last cast).
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		if not h.out and d.due_in(i) <= LAW_LEAD and bc._slot_ready(rules, slots, "noleave") and not ctx.memo.has("law_%d" % i):
			ctx.memo["law_%d" % i] = true
			rules.cast(int(slots.noleave), h.door)
			return "leaving is prohibited at the door of the %s procession, as it forms up" % h.name.to_lower()
	for i in _works(d):
		var able := _ables(d, i)
		var led: Array[Vector2] = []
		for e in able:
			led.append(GOD.road_ahead(e, NoLeaveFx.T_SEAL))
		if led.is_empty():
			continue
		if bc._slot_ready(rules, slots, "noleave") and not ctx.memo.has("law_%d" % i):
			var circle := _enclose(led)
			if float(circle.r) <= NoLeaveFx.RADIUS - LAW_SLACK:
				ctx.memo["law_%d" % i] = true
				rules.cast(int(slots.noleave), circle.at)
				return "leaving is prohibited round the file of procession %d (%d escorts)" % [i, able.size()]
		if bc._slot_ready(rules, slots, "belllies") and not ctx.memo.has("call_%d" % i):
			var mid: Vector2 = _enclose(led).at
			ctx.memo["call_%d" % i] = true
			GOD.cast_bell(bc, ctx, "guard", mid)
			return "call the guard to procession %d" % i
	return ""


# --- Dominion: Mind Whisper, Discord, Rewrite Priority ----------------------------------------------------------------------------------

## What Rewrite Priority puts above all else for the company.
const PRIORITY_MODE := "hide"


## Mind Whisper sends an escort six units from the believer (held while he walks and lingers), then Discord holds one more (he forgets his task for fifteen
## seconds): two held, and the believer is freed with no death. Rewrite Priority round the believer, a compulsion of the district (the escort are held), only when
## the whisper and Discord are both cooling and the company stands within its radius: its seal takes a second (T_CAST), so a cast of it made first would leave the
## next procession 46 s after the last cast, not 45.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := _fh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	for i in _works(d):
		var p := _man(d, i)
		var able := _ables(d, i)
		if bc._slot_ready(rules, slots, "whisper"):
			for e in able:
				if not e.shaken() and e.mind != Person.Mind.WHISPERED:
					rules.cast(int(slots.whisper), e.ground_pos, {"target": e, "to": bc._prisoner_away(crowd, e, p.ground_pos)})
					return "whisper an escort of procession %d away" % i
		if bc._slot_ready(rules, slots, "discord"):
			for e in able:
				if e.mind != Person.Mind.CONFUSED and e.mind != Person.Mind.WHISPERED:
					rules.cast(int(slots.discord), e.ground_pos)
					return "discord an escort of procession %d" % i
		if bc._slot_ready(rules, slots, "priority") and not ctx.memo.has("priority_%d" % i):
			var near := 0
			for e in able:
				near += 1 if e.ground_pos.distance_to(p.ground_pos) <= RewritePriorityFx.RADIUS - 0.5 else 0
			if near >= _need(d, i):
				ctx.memo["priority_%d" % i] = true
				rules.cast(int(slots.priority), p.ground_pos, {"mode": PRIORITY_MODE})
				return "rewrite priority (%s) round procession %d" % [PRIORITY_MODE, i]
	return ""
