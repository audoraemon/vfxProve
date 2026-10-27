extends RefCounted
## The scripted player's per-type policies for The Tax Collector (god T1R, spec 5.3 and 9): one act_<type>(bc, ctx) for each god type, playing only
## that type's two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the
## behaviour_check script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd. Each returns what it cast, or "".
##   ruin     Smite where the fall goes unseen (B's, led ahead), as a last chance, or once he has been in the street a few seconds (seen: the
##            bell tolls, the Lantern stirs, nothing is lost); Ember on the counting-house for the last one hiding.
##   death    Death Mark a collector with 11 s of street left (a marked man indoors at the fuse lives); Pestilence on him with his guards when
##            the mark cannot be laid, and on the waiting deputies' guards at the door between collectors.
##   veil     Blight the Bell Tower first (a seen death then rings nothing), then Silent Doom on a collector in the street (A's, unseen first).
##   passage  Mirrorfold laid across his road ahead, its way out beyond the nearest wall; a Thornwall by the counting-house's door (smoking out
##            the next one) or along his road when nothing else is ready.
##   decree   The Bell Lies (CALL THE GUARD) from a spot 8+ away that takes his guards, once for each visit, as it begins or runs; Leaving Is
##            Prohibited over the door as he comes out: the debtors mob him.
##   dominion Mind Whisper relayed: a hop of 9 toward the way off the map each time the last has been reached, until he is out of the walls.

## The types whose policy is written.
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

const GOD := preload("res://tools/dev/routes/god_t1.gd")
const B := preload("res://tools/dev/routes/tier1_b.gd")

## Ruin: the seconds a collector has been in the street this leg before a seen Smite is struck on him (tunable).
const RUIN_PATIENCE := 5.0
## Ruin: the seconds a visit has left when the bolt is cast at the door (SmiteFx.T_STRIKE 0.35 and a look's tenth over).
const RUIN_DOOR := 0.45
## Death: the street seconds a Death Mark needs (MARK_TIME 10 and a second over), and the pace a marked man walks at (DeathMarkFx.SLOW).
const DEATH_STREET := 11.0
## Seconds with no cast after which a cast at the counting-house's door smokes the next collector out (the A policy's TAX_SMOKE_AFTER).
const SMOKE_AFTER := 30.0
## Passage: how many seconds ahead on his road the way in is laid, and how far beyond the wall's margin the way out is (the oval is 2.4 across).
const MIRROR_AHEAD := 9.0
const MIRROR_BEYOND := 3.2
## Passage: the seconds a mirror laid for a collector has to take him (it lasts 30) before another is laid for him.
const MIRROR_RETRY := 40.0
## Passage: the seconds with no cast after which a Thornwall is laid along his road, so the policy acts while the mirror cools.
const THORN_IDLE := 30.0
## Passage: how far to the side of his road the Thornwall stands.
const THORN_SIDE := 2.0
## Decree: The Bell Lies calls his guards away at the first look where his visit ends between BELL_MAX and BELL_MIN seconds on (they are gone
## for the call's 20 s and the walk back, so he comes out unguarded), and Leaving Is Prohibited is laid over the door LIP_LEAD seconds before
## he comes out. A visit not yet begun counts: his walk to the door and the visit's seconds.
const BELL_MAX := 22.0
const BELL_MIN := 3.0
const LIP_LEAD := 1.2
## Decree: his guards are called off when none stands within this of the door (the mob needs them beyond MOB_GUARD_R of him).
const LIP_CLEAR := 3.0
## Decree: how far from the door the guards are called, and how far behind the door (against his heading) the law is centred.
const BELL_FAR := [8.0, 9.0, 10.0]
const LIP_BEHIND := 1.0
## Dominion: how far a hop of the whisper goes (REACH is 10).
const WHISPER_HOP := 9.0


# --- Shared pieces -----------------------------------------------------------------------------------------------------------

## The collectors out in the open now: walking or fleeing, alive, not indoors.
static func _street(d: AssassinateDirector) -> Array[AssassinateDirector.Quarry]:
	var out: Array[AssassinateDirector.Quarry] = []
	for q in d.quarries:
		if q.dead or not q.state in [AssassinateDirector.State.WALKING, AssassinateDirector.State.FLEEING]:
			continue
		if MissionDirector._alive(q.target) and not (q.target as Person).inside:
			out.append(q)
	return out


## The second of the night (mission seconds); the director's clock.
static func _now(ctx: Dictionary) -> float:
	return float((ctx.d as AssassinateDirector)._clock)


## Notes a cast in the policy's memo and passes its words on.
static func _did(ctx: Dictionary, words: String) -> String:
	if words != "":
		ctx.memo["last"] = _now(ctx)
	return words


## Seconds since the policy's last cast.
static func _since(ctx: Dictionary) -> float:
	return _now(ctx) - float(ctx.memo.get("last", 0.0))


## Between collectors (one stopped, none out, the next waiting), with the policy's last cast SMOKE_AFTER ago: the spot by the counting-house's
## door a cast smokes the next one out at (AssassinateDirector._on_cast()); Vector2.INF when it is not time.
static func _smoke_spot(bc, ctx: Dictionary) -> Vector2:
	var d := ctx.d as AssassinateDirector
	if d.stopped() > 0 and not d._anyone_out() and d._next_waiting() != null and _since(ctx) >= SMOKE_AFTER:
		return bc._tax_smoke_spot(d, ctx.crowd)
	return Vector2.INF


## The road `q` is on to where he is bound: the grid's path from him to his stop (or the Citadel), and its length in seconds at his pace.
static func _road(ctx: Dictionary, q: AssassinateDirector.Quarry) -> PackedVector2Array:
	var d := ctx.d as AssassinateDirector
	var goal: Vector2 = d._leg_goal(q) if q.state == AssassinateDirector.State.WALKING else d._hide_goal(q)
	return (ctx.crowd as Crowd)._grid.path(q.target.ground_pos, goal)


static func _road_seconds(q: AssassinateDirector.Quarry, road: PackedVector2Array, pace: float) -> float:
	var at: Vector2 = q.target.ground_pos
	var len_ := 0.0
	for step in road:
		len_ += at.distance_to(step)
		at = step
	return len_ / maxf(pace, 0.1)


# --- Ruin ----------------------------------------------------------------------------------------------------------------------

## B's Smite without the Wisp: a bolt aimed where he will be, when nobody would see him fall, as a last chance, or once he has been in the
## street RUIN_PATIENCE seconds; Ember on the counting-house for the last one hiding; a Smite at the door smokes the next one out.
static func act_ruin(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	var crowd: Crowd = ctx.crowd
	if d == null:
		return ""
	var smite_ready: bool = bc._slot_ready(rules, slots, "smite")
	var alive := 0
	var hiding := 0
	for q in d.quarries:
		if q.dead or q.state in [AssassinateDirector.State.OUT, AssassinateDirector.State.SAFE] or not MissionDirector._alive(q.target):
			continue
		if q.state != AssassinateDirector.State.WAITING and not ctx.memo.has("out_%d" % q.index):
			ctx.memo["out_%d" % q.index] = rules.time_left  # when he first went out into the street
		alive += 1
		hiding += 1 if q.state == AssassinateDirector.State.HIDING else 0
	# A visit runs out: the bolt cast RUIN_DOOR seconds before he comes out lands at his door as he does, where he cannot have walked from.
	for q in d.quarries:
		if q.state == AssassinateDirector.State.VISITING and q.indoors_left <= RUIN_DOOR and q.indoors_left > 0.0 and smite_ready 				and MissionDirector._alive(q.target):
			rules.cast(slots.smite, d._door_in(q))
			return _did(ctx, "smite %s at the door as he comes out" % q.label)
	var street := _street(d)
	for q in d.quarries:
		if not street.has(q):
			ctx.memo.erase("street_%d" % q.index)
	for q in street:
		var p: Person = q.target
		# Where he is when the bolt lands: along the road he is on (the danger lands with the bolt, so he has not turned yet).
		var fall: Vector2 = GOD.road_ahead(p, SmiteFx.T_STRIKE)
		var out_for := float(ctx.memo.get("out_%d" % q.index, rules.time_left)) - rules.time_left
		if not ctx.memo.has("street_%d" % q.index):
			ctx.memo["street_%d" % q.index] = _now(ctx)  # when he came out into the street this leg
		var street_for := _now(ctx) - float(ctx.memo["street_%d" % q.index])
		var clean: bool = B._tax_smite_unseen(crowd, p, fall)
		if smite_ready and (clean or B._tax_last_chance(d, crowd, q, alive, out_for) or street_for >= RUIN_PATIENCE):
			rules.cast(slots.smite, fall)
			return _did(ctx, "smite %s%s" % [q.label, "" if clean else ", seen"])
	var house := d.hideout
	if alive == 1 and hiding == 1 and bc._slot_ready(rules, slots, "ember") and smite_ready and is_instance_valid(house) \
			and not house.destroyed and not crowd.fires.is_burning(house):
		rules.cast(slots.ember, house.center())
		return _did(ctx, "ember the counting-house, to bring out the last one hiding")
	var smoke := _smoke_spot(bc, ctx)
	if smoke != Vector2.INF and smite_ready:
		rules.cast(slots.smite, smoke)
		return _did(ctx, "smite the door, smoking out the next collector")
	return ""


# --- Death ---------------------------------------------------------------------------------------------------------------------

## Death Mark on a collector with DEATH_STREET seconds of street left at the pace a marked man walks (DeathMarkFx.SLOW of his own); a man
## already marked is left to his fuse. Pestilence on him with his guards (the aim that takes him) when the mark cannot be laid in time or is
## cooling, and on a waiting deputy's guards at the door when nothing else is to do (one fewer to stand round him later). A Death Mark at
## the door smokes the next one out.
static func act_death(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	var crowd: Crowd = ctx.crowd
	if d == null:
		return ""
	var mark_ready: bool = bc._slot_ready(rules, slots, "deathmark")
	var plague_ready: bool = bc._slot_ready(rules, slots, "pestilence")
	for q in _street(d):
		var p: Person = q.target
		if p.statuses.has(&"frail") or p.sick_left > 0.0:
			continue  # his fuse is lit
		var road := _road(ctx, q)
		var left := _road_seconds(q, road, p.walk_speed * DeathMarkFx.SLOW)
		if mark_ready and left >= DEATH_STREET:
			rules.cast(slots.deathmark, p.ground_pos)
			return _did(ctx, "death mark %s (%.0f s of street)" % [q.label, left])
		if plague_ready:
			var aim: Vector2 = GOD.plague_aim(crowd, p.ground_pos)
			if aim != Vector2.INF and PestilenceFx.victims_at(crowd._field, aim).has(p):
				rules.cast(slots.pestilence, aim)
				return _did(ctx, "pestilence %s and those about him" % q.label)
	if plague_ready and _since(ctx) >= SMOKE_AFTER - 10.0:
		var next := d._next_waiting()
		if next != null:
			var guards: Array[Person] = []
			for g: Variant in next.guards:
				if MissionDirector._alive(g) and not (g as Person).inside:
					guards.append(g as Person)
			if not guards.is_empty():
				var aim: Vector2 = GOD.plague_aim(crowd, guards[0].ground_pos, [next.target])
				if aim != Vector2.INF:
					rules.cast(slots.pestilence, aim)
					return _did(ctx, "pestilence the guards at the counting-house door")
	var smoke := _smoke_spot(bc, ctx)
	if smoke != Vector2.INF and mark_ready:
		rules.cast(slots.deathmark, smoke)
		return _did(ctx, "death mark at the door (nobody), smoking out the next collector")
	return ""


# --- Veil ----------------------------------------------------------------------------------------------------------------------

## Blight the Bell Tower first: a cracked bell is never rung, so a seen death rings nothing. Then Silent Doom on a collector in the street
## where nobody would see (A's check), or on any once the bell is cracked; Doom at the door smokes the next one out.
static func act_veil(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	var crowd: Crowd = ctx.crowd
	if d == null:
		return ""
	var tower: Structure = crowd.bell.tower if crowd.bell != null else null
	var cracked := tower == null or not is_instance_valid(tower) or tower.blighted or tower.destroyed
	if not cracked and bc._slot_ready(rules, slots, "blight") and _now(ctx) >= 10.0:
		rules.cast(slots.blight, tower.center())
		return _did(ctx, "blight the Bell Tower, so a seen death rings nothing")
	var doom_ready: bool = bc._slot_ready(rules, slots, "doom")
	if not doom_ready:
		return ""
	for q in _street(d):
		if cracked or bc._tax_unseen(q.target, crowd):
			rules.cast(slots.doom, q.target.ground_pos)
			return _did(ctx, "doom %s%s" % [q.label, "" if bc._tax_unseen(q.target, crowd) else ", seen"])
	var smoke := _smoke_spot(bc, ctx)
	if smoke != Vector2.INF:
		rules.cast(slots.doom, smoke)
		return _did(ctx, "doom at the door, smoking out the next collector")
	return ""


# --- Passage -------------------------------------------------------------------------------------------------------------------

## The way out for a mirror whose way in is at `from`: the walkable ground nearest to it that lies MIRROR_BEYOND past the wall's margin (so
## the whole oval stands out of the walls); Vector2.INF when there is none within 30.
static func _exit_spot(ctx: Dictionary, from: Vector2) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var town := City.current().town().grow(Walls.MARGIN + MIRROR_BEYOND)
	var best := Vector2.INF
	var dist := 1.0
	while dist <= 30.0 and best == Vector2.INF:
		for i in 36:
			var g := from + Vector2.from_angle(TAU * float(i) / 36.0) * dist
			if not town.has_point(g) and grid.walkable(g):
				if best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from):
					best = g
		dist += 1.0
	return best


## The Mirrorfold laid across the road of the collector with the longest road ahead of him (his way in MIRROR_AHEAD seconds on), its way out
## beyond the nearest wall; else, with nothing cast for THORN_IDLE seconds, a Thornwall across his road a few seconds on.
static func act_passage(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	if d == null:
		return ""
	var street := _street(d)
	if street.is_empty():
		# Between collectors, with nothing cast for SMOKE_AFTER seconds, a Thornwall by the counting-house's door smokes the next one out (it
		# stands along the line out from the door, not across his way).
		var smoke := _smoke_spot(bc, ctx)
		if smoke != Vector2.INF and bc._slot_ready(rules, slots, "thorns"):
			rules.cast(slots.thorns, smoke, {"dir": (smoke - d.hide_door).normalized()})
			return _did(ctx, "thornwall by the door, smoking out the next collector")
		return ""
	var q: AssassinateDirector.Quarry = street[0]
	var p: Person = q.target
	if bc._slot_ready(rules, slots, "mirror") and _now(ctx) - float(ctx.memo.get("mirror_for_%d" % q.index, -999.0)) >= MIRROR_RETRY:
		var way_in: Vector2 = GOD.road_ahead(p, MIRROR_AHEAD)
		var way_out := _exit_spot(ctx, way_in)
		if way_out != Vector2.INF and way_in.distance_to(p.ground_pos) >= 4.0 and GOD.cast_mirror(bc, ctx, way_in, way_out):
			ctx.memo["mirror_for_%d" % q.index] = _now(ctx)
			return _did(ctx, "mirror %s: in %.1f from him, out at (%.1f, %.1f)" % [q.label, way_in.distance_to(p.ground_pos), way_out.x, way_out.y])
	if bc._slot_ready(rules, slots, "thorns") and _since(ctx) >= THORN_IDLE:
		# Along the road, not across it: a wall in his way would hold him from the mirror; this one keeps him to the street.
		var ahead: Vector2 = GOD.road_ahead(p, 5.0)
		var heading := (ahead - p.ground_pos).normalized() if ahead.distance_to(p.ground_pos) > 0.3 else Vector2.RIGHT
		rules.cast(slots.thorns, ahead + heading.orthogonal() * THORN_SIDE, {"dir": heading})
		return _did(ctx, "thornwall along %s's road" % q.label)
	return ""


# --- Decree --------------------------------------------------------------------------------------------------------------------

## The collector's guards that stand out of doors.
static func _guards_out(q: AssassinateDirector.Quarry) -> Array[Person]:
	var out: Array[Person] = []
	for g: Variant in q.guards:
		if MissionDirector._alive(g) and not (g as Person).inside:
			out.append(g as Person)
	return out


## A spot 8+ from `door` where The Bell Lies, CALL THE GUARD, would take all of `guards` (they are among the GUARDS nearest soldiers to it);
## Vector2.INF when none of the spots tried does. The spot with the fewest other soldiers called.
static func _bell_spot(ctx: Dictionary, door: Vector2, guards: Array[Person]) -> Vector2:
	var crowd: Crowd = ctx.crowd
	var soldiers: Array[Person] = []
	for s in crowd.soldiers:
		if is_instance_valid(s) and s.is_alive() and not s.inside:
			soldiers.append(s)
	var best := Vector2.INF
	var best_n := 1000
	for far: float in BELL_FAR:
		for k in 24:
			var spot := door + Vector2.from_angle(TAU * float(k) / 24.0) * far
			if not crowd._grid.walkable(spot):
				continue
			var pool := soldiers.duplicate()
			pool.sort_custom(func(a: Person, b: Person) -> bool:
				return a.ground_pos.distance_squared_to(spot) < b.ground_pos.distance_squared_to(spot))
			var called: Array = pool.slice(0, BellLiesFx.GUARDS)
			var all := true
			for g in guards:
				all = all and called.has(g)
			if all and called.size() < best_n:
				best = spot
				best_n = called.size()
	return best


## The debtor's door `q` comes out of next and the seconds until he does: the visit he is in, or the one he walks to (his walk and the
## visit's seconds). Empty for none (hiding, fleeing, or his round done).
static func _next_exit(ctx: Dictionary, q: AssassinateDirector.Quarry) -> Dictionary:
	var d := ctx.d as TaxCollectorDirector
	if q.state == AssassinateDirector.State.VISITING:
		return {"door": d._door_in(q), "in": q.indoors_left, "leg": q.leg}
	if q.state == AssassinateDirector.State.WALKING and q.leg < q.stops.size() and not (q.target as Person).inside:
		var secs := _road_seconds(q, _road(ctx, q), (q.target as Person).walk_speed)
		return {"door": q.stop_doors[q.leg], "in": secs + d.visit_seconds, "leg": q.leg}
	return {}


## One of `guards` stands within `r` of `at`.
static func _any_near(guards: Array[Person], at: Vector2, r: float) -> bool:
	for g in guards:
		if g.ground_pos.distance_to(at) <= r:
			return true
	return false


## CALL THE GUARD when a collector's next exit from a debtor's door is BELL_MAX to BELL_MIN seconds away (once for that visit), from a spot that
## takes his guards; then Leaving Is Prohibited over the door LIP_LEAD seconds before he comes out, if none of his guards stands near it. Bound
## at the door with the guards away, the debtors mob him. The law is centred behind the door against his heading so the edge he is held at is
## well inside the mob's reach. With nothing else to do for SMOKE_AFTER seconds, the law at the counting-house's door smokes the next one out.
static func act_decree(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as TaxCollectorDirector
	if d == null:
		return ""
	for q in d.quarries:
		if q.dead or not q.state in [AssassinateDirector.State.WALKING, AssassinateDirector.State.VISITING] 				or not MissionDirector._alive(q.target):
			continue
		var nx := _next_exit(ctx, q)
		if nx.is_empty():
			continue
		var door: Vector2 = nx["door"]
		var left: float = nx["in"]
		var key := "%d_%d" % [q.index, int(nx["leg"])]
		var guards := _guards_out(q)
		if q.state == AssassinateDirector.State.VISITING and left <= LIP_LEAD and bc._slot_ready(rules, slots, "noleave") 				and not ctx.memo.has("lip_" + key) and not _any_near(guards, door, LIP_CLEAR):
			var next: Vector2 = q.stop_doors[q.leg + 1] if q.leg + 1 < q.stop_doors.size() else d.safe_at
			var heading := (next - door).normalized()
			ctx.memo["lip_" + key] = _now(ctx)
			rules.cast(slots.noleave, door - heading * LIP_BEHIND)
			return _did(ctx, "leaving is prohibited over %s's door, %d guard(s) out of doors" % [q.label, guards.size()])
		if left <= BELL_MAX and left >= BELL_MIN and not guards.is_empty() and not ctx.memo.has("bell_" + key) 				and bc._slot_ready(rules, slots, "belllies"):
			var spot := _bell_spot(ctx, door, guards)
			if spot != Vector2.INF and GOD.cast_bell(bc, ctx, "guard", spot):
				ctx.memo["bell_" + key] = _now(ctx)
				return _did(ctx, "call the guard to (%.1f, %.1f), %.1f from %s's door, his exit in %.0f s" % [spot.x, spot.y,
					spot.distance_to(door), q.label, left])
	var smoke := _smoke_spot(bc, ctx)
	if smoke != Vector2.INF and bc._slot_ready(rules, slots, "noleave"):
		rules.cast(slots.noleave, smoke)
		return _did(ctx, "leaving is prohibited at the door, smoking out the next collector")
	return ""


# --- Dominion ------------------------------------------------------------------------------------------------------------------

## Mind Whisper in hops of WHISPER_HOP toward the way off the map, along the road the grid gives him: the farthest point of it within the hop
## of where he stands. A new hop when he has reached the last (or was not whispered yet), always before the linger runs out, so he is never
## free to be whispered again (Person.SHAKE_OFF) and never turns back. A collector in the open whose whisper is ready is relayed on.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	var crowd: Crowd = ctx.crowd
	if d == null or not bc._slot_ready(rules, slots, "whisper"):
		return ""
	for q in _street(d):
		var p: Person = q.target
		if p.shaken() or (p.mind == Person.Mind.WHISPERED and p.has_goal()):
			continue  # on his way to the last hop, or shaking a whisper off
		var way := Walls.way_off(p.ground_pos)
		if way == Vector2.INF:
			continue
		var hop := Vector2.INF
		for step in crowd._grid.path(p.ground_pos, way):
			if step.distance_to(p.ground_pos) <= WHISPER_HOP:
				hop = step
			else:
				break
		if hop == Vector2.INF or hop.distance_to(p.ground_pos) < 1.0:
			continue
		rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": hop})
		return _did(ctx, "whisper %s %.1f toward the way off, to (%.1f, %.1f)" % [q.label, hop.distance_to(p.ground_pos), hop.x, hop.y])
	return ""


## The numbers a report line prints (the same as the route B's, tier1_b.gd), and what was stopped out of the walls.
static func state(bc, ctx: Dictionary) -> String:
	var d := ctx.d as AssassinateDirector
	var more := " out=%d" % d.out_count() if d != null else ""
	return String(B.state_tax(bc, ctx)) + more
