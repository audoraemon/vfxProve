extends RefCounted
## The scripted player's per-type policies for The Tax Collector (god T1R, spec 5.3 and 9): one act_<type>(bc, ctx) for each god type, playing only
## that type's two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the
## behaviour_check script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd. Each returns what it cast, or "".
##   ruin     Smite where the fall goes unseen (B's, led ahead), as a last chance, or once he has been in the street a few seconds (seen: the
##            bell tolls, the Lantern stirs, nothing is lost); Ember on the counting-house for the last one hiding.
##   death    Death Mark a collector with 11 s of street left (a marked man indoors at the fuse lives); Raise the Dead has no work here.
##   veil     Blight the Bell Tower first (a seen death then rings nothing), then Silent Doom on a collector in the street (A's, unseen first).
##   passage  Skylift takes a collector in the street (and whoever walks with him) and sets him down beyond the nearest wall; a Windfall of
##            stone by the counting-house's door smokes the next one out.
##   decree   Leaving Is Prohibited over a debtor's door as he comes out (or on him in the street), then Breathing Is Prohibited on him
##            once the cell holds him: he cannot run from it, and dies with his guards.
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
## Passage: how far beyond the wall's margin Skylift sets a collector down.
const LIFT_BEYOND := 1.0
## Decree: Leaving Is Prohibited is laid over a debtor's door LIP_LEAD seconds before he comes out (it seals NoLeaveFx.T_SEAL on, and he walks
## out into it).
const LIP_LEAD := 1.2
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
		if q.state == AssassinateDirector.State.VISITING and q.indoors_left <= RUIN_DOOR and q.indoors_left > 0.0 and smite_ready \
				and MissionDirector._alive(q.target):
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
## already marked is left to his fuse. A Death Mark at the door smokes the next one out. Raise the Dead has no work on this night: each
## collector's round leaves him time for the mark.
static func act_death(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	if d == null:
		return ""
	var mark_ready: bool = bc._slot_ready(rules, slots, "deathmark")
	for q in _street(d):
		var p: Person = q.target
		if p.statuses.has(&"frail"):
			continue  # his fuse is lit
		var road := _road(ctx, q)
		var left := _road_seconds(q, road, p.walk_speed * DeathMarkFx.SLOW)
		if mark_ready and left >= DEATH_STREET:
			rules.cast(slots.deathmark, p.ground_pos)
			return _did(ctx, "death mark %s (%.0f s of street)" % [q.label, left])
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

## Where Skylift sets a collector taken at `from` down: the walkable ground nearest to it that lies LIFT_BEYOND past the wall's margin;
## Vector2.INF when there is none within 30.
static func _exit_spot(ctx: Dictionary, from: Vector2) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var town := City.current().town().grow(Walls.MARGIN + LIFT_BEYOND)
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


## Skylift on the first collector in the street, where he will stand when the beam takes (SkyliftFx.T_TAKE on, along his road), set down
## beyond the nearest wall: out of the walls, he is stopped. Between collectors, with nothing cast for SMOKE_AFTER seconds, a Windfall of stone
## by the counting-house's door smokes the next one out.
static func act_passage(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	if d == null:
		return ""
	var street := _street(d)
	if street.is_empty():
		# The line lies along the way out from the door, not across it.
		var smoke := _smoke_spot(bc, ctx)
		if smoke != Vector2.INF and bc._slot_ready(rules, slots, "windfall"):
			rules.cast(slots.windfall, smoke, {"dir": (smoke - d.hide_door).normalized(), "mode": "stone"})
			return _did(ctx, "windfall by the door, smoking out the next collector")
		return ""
	if not bc._slot_ready(rules, slots, "skylift"):
		return ""
	for q in street:
		var p: Person = q.target
		var from: Vector2 = GOD.road_ahead(p, SkyliftFx.T_TAKE)
		var to := _exit_spot(ctx, from)
		if to != Vector2.INF:
			rules.cast(slots.skylift, from, {"to": to})
			return _did(ctx, "skylift %s out of the walls, from (%.1f, %.1f) to (%.1f, %.1f)" % [q.label, from.x, from.y, to.x, to.y])
	return ""


# --- Decree --------------------------------------------------------------------------------------------------------------------

## The cell and the breath (GOD.cast_amber(), GOD.amber_breath()) on a collector: Leaving Is Prohibited laid over a debtor's door LIP_LEAD seconds
## before he comes out, so he steps out into it, or on a collector in the street where he will stand as it seals (on the spot that holds the
## fewest others with him: GOD.amber_aim()); once it holds him, Breathing Is Prohibited on him. Held, he cannot run from the airless circle,
## and he dies three seconds on with the guards at his side (seen: the bell tolls, the Lantern stirs, nothing is lost). Between collectors,
## with nothing cast for SMOKE_AFTER seconds, the cell laid at the counting-house's door smokes the next one out into it.
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := ctx.d as TaxCollectorDirector
	if d == null:
		return ""
	var follow: String = GOD.amber_breath(bc, ctx)
	if follow != "":
		return _did(ctx, follow)
	if GOD.amber_pending(ctx):
		return ""
	for q in d.quarries:
		if q.dead or not MissionDirector._alive(q.target):
			continue
		var p := q.target as Person
		if q.state == AssassinateDirector.State.VISITING and q.indoors_left <= LIP_LEAD and q.indoors_left > 0.0:
			var door := d._door_in(q)
			if GOD.cast_amber(bc, ctx, door, [p]):
				return _did(ctx, "leaving is prohibited over %s's door as he comes out: the breath follows" % q.label)
	for q in _street(d):
		var p := q.target as Person
		var aim: Dictionary = GOD.amber_aim(ctx.crowd, GOD.road_ahead(p, NoLeaveFx.T_SEAL), [p])
		if GOD.cast_amber(bc, ctx, aim.at, [p]):
			return _did(ctx, "leaving is prohibited round %s in the street (%d others held): the breath follows" % [q.label, int(aim.others)])
	var smoke := _smoke_spot(bc, ctx)
	var next := d._next_waiting()
	if smoke != Vector2.INF and next != null and MissionDirector._alive(next.target) and GOD.cast_amber(bc, ctx, d.hide_door, [next.target]):
		return _did(ctx, "leaving is prohibited at the counting-house's door, smoking %s out into it" % next.label)
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
