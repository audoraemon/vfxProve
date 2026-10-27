extends RefCounted
## The scripted player's per-type policies for The Warning (god T1R, spec 4.2 and 9): one act_<type>(bc, ctx) for each god type, playing only that
## type's two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the behaviour_check
## script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd. Each iterates StarfallDirector.stars as tier1_b's
## act_warning does, and works the warning whose carrier is on the road (the stare counts: the watchman is the carrier already).

const GodT1 := preload("res://tools/dev/routes/god_t1.gd")

## The types whose policy is written.
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## Nobody but the carrier within this of where a death falls: Crowd.DOOM_WITNESS plus the room a man on the run covers meanwhile.
const UNSEEN := 2.0
const MOVE_ROOM := 0.9
## The room a blow's neighbours are given before it lands: how far a walker covers in a Silent Doom's T_STRIKE and a little more.
const CLUSTER_MARGIN := 0.6
## Thornwall goes this far along his road; the mirror's way in is where he will be WAY_IN_SECONDS on.
const THORN_AT := 2.5
const WAY_IN_SECONDS := 2.2
## Ruin's and Veil's blows wait this long for a clear street, then fall with at most SEEN_FEW to see; a carrier with less than URGENT_ETA seconds to the keeper is struck whoever sees.
const SEEN_AFTER := 5.0
const SEEN_FEW := 2
## The longer a carrier stands about (a man frightened against a gate), the more eyes a blow puts up with: SEEN_MORE after SEEN_LATE seconds, any after SEEN_ANY.
const SEEN_MORE := 6
const SEEN_LATE := 20.0
const SEEN_ANY := 40.0
const URGENT_ETA := 5.0
## Where a gate's way out is within SCARE_WALK units of his walk, Smite falls SCARE_BACK units behind him (outside its kill radius, inside the fright it throws).
const SCARE_WALK := 5.0
const SCARE_BACK := 1.4
## The room left between Smite's fright (its kill radius and Person.THREAT_MARGIN) and the watchman when it strikes a man outside his gate.
const SMITE_CLEAR := 0.4
## The fire is lit beside his road this far along.
const FIRE_AT := 3.0
## Smite may fall near the tower this many times in a night (the tower stands a few blows; five silenced it).
const TOWER_HITS := 2
## Smite keeps this far from the bell tower's walls (beyond its own blow's reach).
const TOWER_KEEP := 1.0
## The Decree policy sends the lie when the runner is this many seconds from the keeper.
const LIE_LEAD := 5.0
## The Decree policy holds a runner with Leaving Is Prohibited while the lie is not up yet, and sends the lie when this many seconds of his run are left.
const PIN_SECONDS := 15.0
## Mind Whisper's reach, less a little for the walk's start.
const WHISPER_REACH := MindWhisperFx.REACH - 0.5
## The longest walk a single whisper sends the carrier on towards the gate.
const HOP := 8.0


## Every warning that has a carrier to work: set up, not stopped, its carrier alive and out of doors and not yet out of the walls.
static func _carriers(ctx: Dictionary) -> Array[WarningDirector]:
	var out: Array[WarningDirector] = []
	var d := ctx.d as StarfallDirector
	if d == null:
		return out
	for w: WarningDirector in d.stars:
		if w.rules == null or w.warning_dead or w.phase == WarningDirector.Phase.OVER:
			continue
		var m := w.messenger
		if not WarningDirector._alive(m) or m.inside or Walls.outside(m.ground_pos):
			continue
		out.append(w)
	return out


## Where the carrier is bound: the keeper while he lives, else the tower's foot.
static func _goal(ctx: Dictionary) -> Vector2:
	var bell: BellNetwork = (ctx.crowd as Crowd).bell
	if bell == null:
		return Vector2.INF
	return bell.keeper.ground_pos if WarningDirector._alive(bell.keeper) else bell.foot


## The carrier's walk to the keeper, as the town's paths would take him (a stare has no path yet).
static func _road(ctx: Dictionary, m: Person) -> PackedVector2Array:
	var goal := _goal(ctx)
	if goal == Vector2.INF:
		return PackedVector2Array()
	var path := (ctx.crowd as Crowd)._grid.path(m.ground_pos, goal)
	var out := PackedVector2Array([m.ground_pos])
	out.append_array(path)
	return out


## The point `dist` along the polyline `road` (its end when it is shorter), and the direction there.
static func _along(road: PackedVector2Array, dist: float) -> Dictionary:
	var left := dist
	var at := Vector2.INF
	var dir := Vector2.RIGHT
	for k in range(1, road.size()):
		var seg := road[k - 1].distance_to(road[k])
		dir = (road[k] - road[k - 1]).normalized() if seg > 0.001 else dir
		if seg >= left:
			return {"at": road[k - 1].move_toward(road[k], left), "dir": dir}
		left -= seg
		at = road[k]
	return {"at": at if at != Vector2.INF else (road[0] if not road.is_empty() else Vector2.INF), "dir": dir}


static func _length(road: PackedVector2Array) -> float:
	var n := 0.0
	for k in range(1, road.size()):
		n += road[k - 1].distance_to(road[k])
	return n


## How fast he goes: his run, which he has already in the stare's last moment.
static func _pace(m: Person) -> float:
	return maxf(m.walk_speed, Person.PANIC_SPEED * m.pace)


## Seconds until he stands at the keeper, at his pace.
static func _eta(ctx: Dictionary, m: Person) -> float:
	var road := _road(ctx, m)
	return _length(road) / _pace(m) if not road.is_empty() else 99.0


## Everyone alive out of doors but `m` (and `spare`) within `reach` of `at`.
static func _near(crowd: Crowd, at: Vector2, reach: float, m: Person) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != m and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= reach:
				return true
	return false


static func _tower() -> Vector2:
	return City.current().landmark(&"bell_tower").get_center()


## One look for every type but those that hold the carrier: the first warning a move serves.
static func _each(ctx: Dictionary, move: Callable) -> String:
	for w in _carriers(ctx):
		var did := String(move.call(w))
		if did != "":
			return "%s [%s, phase %d]" % [did, w.post_name.to_lower(), w.phase]
	return ""


# --- Ruin: Smite, Ember ---

## Smite, led half a step ahead of the runner, when nobody stands within reach of where he will be as it lands; once he has been on the road SEEN_AFTER seconds a
## blow with only one or two to see it falls anyway, and nearly at the keeper (or with the keeper climbing) whoever sees -- the witness who carries the warning on
## is struck in his turn. Ember sets a house beside his road alight when the street is full, to thin it (people run from a fire, the brigade turns out to it).
static func act_ruin(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		# W3: while the watchman stares at his star, a bolt on a man standing just outside his gate draws him out to the body (the postern's watchman
		# through his barred postern, with its key); the man struck stands clear of the watchman, so the blow's fright does not reach him.
		var gkey := "gate_smite_%d" % w.get_instance_id()
		if w.phase == WarningDirector.Phase.STARE and m == w.watchman and bc._slot_ready(rules, ctx.slots, "smite") and not ctx.memo.has(gkey):
			var man := _outside_man(crowd, w.gate_spot, m, SmiteFx.KILL_R + Person.THREAT_MARGIN + SMITE_CLEAR)
			if man != null:
				ctx.memo[gkey] = true
				rules.cast(ctx.slots.smite, man.ground_pos)
				return "smite the man outside the gate (%.1f, %.1f): the watchman goes out to him" % [man.ground_pos.x, man.ground_pos.y]
		# At a gate whose way out is a few steps off, the bolt falls behind him on the side away from it: he bolts from it, out through the gate. The
		# postern's watchman holds its key (W3), so his barred postern is a way out a step off; the fright waits for the star (the key turns only then).
		var door := w.key_door()
		var out := door if door != Vector2.INF else _out_spot(bc, crowd, m)
		var way: float = (m.ground_pos.distance_to(door) if door != Vector2.INF else bc._walk_len(crowd, m.ground_pos, out)) if out != Vector2.INF else INF
		var skey := "scared_%d" % m.get_instance_id()
		if m.mind != Person.Mind.FLEE and w.omen_fallen and w.phase != WarningDirector.Phase.DELIVERED and bc._slot_ready(rules, ctx.slots, "smite") \
				and way <= SCARE_WALK and not ctx.memo.has(skey):
			var back := m.ground_pos - (out - m.ground_pos).normalized() * SCARE_BACK
			if not _by_tower(crowd, back):
				ctx.memo[skey] = true  # once: a man frightened against the gate may stand there, alone, for the next blow
				rules.cast(ctx.slots.smite, back)
				return "smite behind the carrier, to send him out through the gate"
		# Where the way out is far (the shut postern: round by the Main Gate), a fire beside his first steps sends him running from it, and the way he runs is
		# the way round to the gate.
		var fkey := "fire_lit"  # one fire a night: the town rings its bell for a burning street
		if way > SCARE_WALK * 2.0 and bc._slot_ready(rules, ctx.slots, "ember") and not ctx.memo.has(fkey) and w.phase != WarningDirector.Phase.DELIVERED:
			var near := _house_near(ctx, _along(_road(ctx, m), FIRE_AT).at)
			if near != Vector2.INF:
				ctx.memo[fkey] = true
				rules.cast(ctx.slots.ember, near)
				return "ember the house beside his first steps (%.1f, %.1f)" % [near.x, near.y]
		var led := GodT1.road_ahead(m, SmiteFx.T_STRIKE) if m.has_goal() and w.phase != WarningDirector.Phase.DELIVERED else m.ground_pos
		var seers := _seers(crowd, led, UNSEEN + MOVE_ROOM, m)
		var tower_ok := not _by_tower(crowd, led) or int(ctx.memo.get("tower_hits", 0)) < TOWER_HITS
		if bc._slot_ready(rules, ctx.slots, "smite") and tower_ok and _fire_ok(ctx, w, seers):
			if _by_tower(crowd, led):
				ctx.memo["tower_hits"] = int(ctx.memo.get("tower_hits", 0)) + 1
			rules.cast(ctx.slots.smite, led)
			return "smite the carrier (%d to see)" % seers
		return "")


## The centre of the house within 3.5 of `at` that burns and is not burning yet; INF for none.
static func _house_near(ctx: Dictionary, at: Vector2) -> Vector2:
	var env: EnvironmentField = (ctx.crowd as Crowd)._env
	var best := Vector2.INF
	for st in env.near(at, 3.5):
		if is_instance_valid(st) and not st.destroyed and FireManager.burns(st) and st.kind == Structure.Kind.HOUSE 				and not (ctx.crowd as Crowd).fires.is_burning(st) and not Walls.outside(st.center()):
			if best == Vector2.INF or st.center().distance_to(at) < best.distance_to(at):
				best = st.center()
	return best


## `at` is so near the bell tower that a bolt's blow to the building beside it (Smite's HIT_R) would bring the tower down, and a silenced bell sends the
## warning to the Temple at once.
static func _by_tower(crowd: Crowd, at: Vector2) -> bool:
	var tower: Structure = crowd.bell.tower if crowd.bell != null else null
	return is_instance_valid(tower) and tower.distance_to(at) <= SmiteFx.HIT_R + TOWER_KEEP


## Whether a blow falls now: nobody to see it; or, once he has been on the road SEEN_AFTER seconds, no more than SEEN_FEW; or he is nearly at the keeper (or the
## keeper has the warning), whoever sees.
static func _fire_ok(ctx: Dictionary, w: WarningDirector, seers: int) -> bool:
	if seers == 0:
		return true
	if w.phase == WarningDirector.Phase.DELIVERED or _eta(ctx, w.messenger) < URGENT_ETA:
		return true
	var since := _since(ctx, w)
	return (seers <= SEEN_FEW and since >= SEEN_AFTER) or (seers <= SEEN_MORE and since >= SEEN_LATE) or since >= SEEN_ANY


## Seconds since this carrier first came under the policy's eye (the stare counts), kept in the memo.
static func _since(ctx: Dictionary, w: WarningDirector) -> float:
	var key := "since_%d_%d" % [w.get_instance_id(), w.messenger.get_instance_id()]
	if not ctx.memo.has(key):
		ctx.memo[key] = w._clock
	return w._clock - float(ctx.memo[key])


## Living people out of doors, `m` apart, within `reach` of `at`.
static func _seers(crowd: Crowd, at: Vector2, reach: float, m: Person) -> int:
	var n := 0
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != m and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= reach:
				n += 1
	return n


## A blow of `radius` aimed within `reach` of the carrier that takes him and whoever else is close, and leaves nobody out of its reach to see: the aim, or
## Vector2.INF. A pair walking together, or the guard at his post, fall with him. `margin` is the room the crowd covers before the blow lands.
static func _cluster_aim(crowd: Crowd, m: Person, radius: float, reach: float, margin: float) -> Vector2:
	var tries: Array[Vector2] = [m.ground_pos]
	for rad: float in [reach * 0.5, reach]:
		for k in 16:
			tries.append(m.ground_pos + Vector2.from_angle(TAU * float(k) / 16.0) * rad)
	var best := Vector2.INF
	var most := 0
	for aim in tries:
		if aim.distance_to(m.ground_pos) > radius - 0.05:
			continue
		var victims: Array[Person] = []
		var others: Array[Person] = []
		for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
			for p in group:
				if not is_instance_valid(p) or not p.is_alive() or p.inside:
					continue
				if p.ground_pos.distance_to(aim) <= radius:
					victims.append(p)
				else:
					others.append(p)
		var clean := m in victims
		for v in victims:
			for o in others:
				if clean and o.ground_pos.distance_to(v.ground_pos) <= Crowd.DOOM_WITNESS + margin:
					clean = false
		if clean and (best == Vector2.INF or victims.size() < most):
			best = aim
			most = victims.size()
	return best


# --- Death: Death Mark, Pestilence ---

## The gate mark (W3): Death Mark a man standing just outside the next star's gate -- a guard at his post outside it, who keeps still -- timed so he falls
## MARK_LANDS seconds into the watchman's stare: the body draws the watchman out to it (the postern's goes through his barred postern with its key), and
## the walls stop the warning. Only once the star's time is known (the warning before it stopped). As before when no gate mark is up for a carrier: Pestilence
## on him where he stands with the neighbours who would see him (the nearest three within 1.2 of its aim), so they die with him five seconds on, and Death
## Mark on him.
static func act_death(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	if bc._slot_ready(rules, ctx.slots, "deathmark"):
		var marked := _gate_mark(ctx)
		if marked != "":
			return marked
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		if m.statuses.has(&"frail") or m.sick_left > 0.0 or _mark_pending(ctx, w):
			return ""
		if bc._slot_ready(rules, ctx.slots, "pestilence"):
			var aim := _plague_aim(crowd, m)
			if aim != Vector2.INF:
				rules.cast(ctx.slots.pestilence, aim)
				return "pestilence on the carrier and his neighbours"
		if bc._slot_ready(rules, ctx.slots, "deathmark"):
			rules.cast(ctx.slots.deathmark, m.ground_pos)
			return "deathmark the carrier"
		return "")


## The gate mark falls this many seconds into the star's four-second stare (WarningDirector.STARE): time for the watchman to go out before he would run.
const MARK_LANDS := 1.5
## How far past the wall's ring a guard's post must lie for the gate mark: as far as a soldier shifts about his post.
const POST_OUT := Person.POST_SPREAD
## A man for the gate mark stands within this of the gate's post: inside W3's reach (WarningDirector.GATE_SIGHT) with room for him to shift on his post.
const MARK_NEAR := WarningDirector.GATE_SIGHT - 0.3


## Death Mark for the next star still to fall, cast DeathMarkFx.MARK_TIME - MARK_LANDS seconds before it: what was cast, or "".
static func _gate_mark(ctx: Dictionary) -> String:
	var d := ctx.d as StarfallDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	for i in d.stars.size():
		var w := d.stars[i]
		if w.warning_dead or w.omen_fallen:
			continue
		if i > 0 and not d.stars[i - 1].warning_dead:
			return ""  # its time may still come sooner (stop_wait): wait for the warning before it
		var key := "gate_mark_%d" % i
		if ctx.memo.has(key):
			return ""
		if d.next_star() != i:
			return ""
		# What the NEXT STAR tag shows (D29): the policy times the mark by the countdown a player reads, no finer.
		var left := d.next_fall_in() / maxf(rules.clock_rate, 0.001)
		if left > DeathMarkFx.MARK_TIME - MARK_LANDS:
			return ""
		ctx.memo[key] = null
		if left < DeathMarkFx.MARK_TIME - (WarningDirector.STARE - 1.0):
			return ""  # too late: he would fall after the watchman has run
		var crowd: Crowd = ctx.crowd
		var post: Vector2 = d.star_falls[i][1]
		var free := crowd._grid.nearest_walkable(post)
		var guard := _outside_man(crowd, free if free != Vector2.INF else post)
		if guard == null:
			return ""
		ctx.memo[key] = guard
		rules.cast(ctx.slots.deathmark, guard.ground_pos)
		return "deathmark the man outside %s, to fall as its star does (%.1f, %.1f)" % [w.post_name.to_lower(), guard.ground_pos.x, guard.ground_pos.y]
	return ""


## A guard standing at his post out of the walls within MARK_NEAR of `post` (a soldier at his post keeps still, and no citizen who might walk in and be
## made the next watchman), the nearest the post; null for none. With `clear`, only one at least that far from `m` (a blow's fright must not reach the
## watchman it is meant to draw out).
static func _outside_man(crowd: Crowd, post: Vector2, m: Person = null, clear := 0.0) -> Person:
	return outside_guard(crowd, post, m.ground_pos if m != null else Vector2.INF, clear)


## The guard _outside_man() picks for the post `post`, clear by `clear` of the point `away` (INF for none). Public for the test that pins the board town's
## gate guards (D29: tests/test_starfall.gd _gate_guards).
static func outside_guard(crowd: Crowd, post: Vector2, away := Vector2.INF, clear := 0.0) -> Person:
	var best: Person = null
	var best_d := INF
	for p in crowd.soldiers:
		# Judged by his post (he shifts about it): a post past the wall's ring by POST_OUT (how far he shifts about it), so he cannot shift back inside it before he falls.
		if not is_instance_valid(p) or not p.is_alive() or p.inside or p.mind != Person.Mind.POST or p.hurrying or p.statuses.has(&"frail") \
				or City.current().town().grow(POST_OUT).has_point(p.anchor) or City.current().town().has_point(p.ground_pos):
			continue
		var dist := maxf(p.ground_pos.distance_to(post), p.anchor.distance_to(post))
		if dist > MARK_NEAR or (away != Vector2.INF and p.ground_pos.distance_to(away) < clear):
			continue
		if dist < best_d:
			best = p
			best_d = dist
	return best


## A gate mark is up for this star: its man is marked and not yet fallen, or its watchman is on his way out to the body (W3).
static func _mark_pending(ctx: Dictionary, w: WarningDirector) -> bool:
	if w._drawn_to != Vector2.INF:
		return true
	var d := ctx.d as StarfallDirector
	var i := d.stars.find(w)
	var guard: Variant = ctx.memo.get("gate_mark_%d" % i, null)
	return w.phase in [WarningDirector.Phase.OMEN, WarningDirector.Phase.STARE] and is_instance_valid(guard) and (guard as Person).is_alive() and (guard as Person).statuses.has(&"frail")


## Where Pestilence takes the carrier and the fewest others (the plague goes on through a crowd by itself, and every death is heard by the alarm): the aim, or INF if none takes him.
static func _plague_aim(crowd: Crowd, m: Person) -> Vector2:
	var tries: Array[Vector2] = [m.ground_pos]
	for e in crowd._field.in_radius(m.ground_pos, PestilenceFx.INFECT_R * 2.0):
		var p := e as Person
		if p != null and p != m and not p.inside:
			tries.append(m.ground_pos.lerp(p.ground_pos, 0.5))
			tries.append(p.ground_pos)
	var best := Vector2.INF
	var most := 0
	for g in tries:
		var victims := PestilenceFx.victims_at(crowd._field, g)
		if victims.has(m) and (best == Vector2.INF or victims.size() < most):
			best = g
			most = victims.size()
	return best


# --- Veil: Silent Doom, Blight ---

## Silent Doom where he stands when nobody else is within the witness distance of him and the room he covers in its T_STRIKE; as Ruin's Smite, a blow with
## few to see it after SEEN_AFTER seconds, and whoever sees when he is nearly at the keeper. Never Blight the tower (a silenced bell sends the warning to the
## Temple at once).
static func act_veil(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	if not bc._slot_ready(rules, ctx.slots, "doom"):
		return ""
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		var aim := _cluster_aim(crowd, m, SilentDoom.RADIUS, SilentDoom.RADIUS - 0.1, CLUSTER_MARGIN)
		if aim != Vector2.INF:
			rules.cast(ctx.slots.doom, aim)
			return "doom the carrier, unseen"
		var seers := _seers(crowd, m.ground_pos, UNSEEN + MOVE_ROOM, m)
		if not _fire_ok(ctx, w, seers):
			return ""
		rules.cast(ctx.slots.doom, m.ground_pos)
		return "doom the carrier (%d to see)" % seers)


# --- Dominion: Mind Whisper, Discord ---

## Mind Whisper sends him through his gate to ground outside the walls within its reach (the nearest by his walk); Discord holds him while the whisper
## cools or he is shaking one off.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		if m.mind == Person.Mind.WHISPERED and m.has_goal():
			return ""  # on his way out
		if bc._slot_ready(rules, ctx.slots, "whisper") and not m.shaken():
			var spot := _out_spot(bc, crowd, m)
			if spot != Vector2.INF:
				var to := _hop(crowd, m, spot)
				rules.cast(ctx.slots.whisper, m.ground_pos, {"target": m, "to": to})
				return "whisper the carrier %s (%.1f, %.1f)" % ["out to" if to == spot else "a hop towards the gate:", to.x, to.y]
		if m.mind != Person.Mind.CONFUSED and m.mind != Person.Mind.WHISPERED and bc._slot_ready(rules, ctx.slots, "discord"):
			rules.cast(ctx.slots.discord, m.ground_pos)
			return "discord the carrier, to hold him"
		return "")


## A whisper's next stop on the way to `spot`: the spot itself when his walk to it is short, else the point HOP along that walk (the postern is shut at
## night, so the Postern's watchman goes round by the Main Gate in two hops: a whisper reaches 10 units and no further).
static func _hop(crowd: Crowd, m: Person, spot: Vector2) -> Vector2:
	var road := PackedVector2Array([m.ground_pos])
	road.append_array(crowd._grid.path(m.ground_pos, spot))
	if _length(road) <= HOP:
		return spot
	var to: Vector2 = crowd._grid.nearest_walkable(_along(road, HOP).at, 2)
	return to if to != Vector2.INF and to.distance_to(m.ground_pos) <= WHISPER_REACH else spot


## Walkable ground outside the walls within a whisper's reach of `m`, the nearest by his walk; Vector2.INF for none.
static func _out_spot(bc, crowd: Crowd, m: Person) -> Vector2:
	var best := Vector2.INF
	var best_way := INF
	for rad: float in [1.0, 2.0, 3.0, 4.5, 6.0, 8.0, 9.5]:
		for k in 24:
			var g: Vector2 = crowd._grid.nearest_walkable(m.ground_pos + Vector2.from_angle(TAU * float(k) / 24.0) * rad, 2)
			if g == Vector2.INF or not Walls.outside(g) or g.distance_to(m.ground_pos) > WHISPER_REACH:
				continue
			var way: float = bc._walk_len(crowd, m.ground_pos, g)
			if way < best_way:
				best = g
				best_way = way
	return best


# --- Passage: Thornwall, Mirrorfold ---

## A way in laid on the carrier's road a little ahead of him and a way out on the ground beyond the nearest wall (Mirrorfold keeps its goal; the next
## look finds him outside). When the mirror is cooling and he would arrive before it can be laid, Thornwall across his road makes him go round.
static func act_passage(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		var road := _road(ctx, m)
		if road.size() < 2:
			return ""
		# Thornwall across the first of his road, just outside the post, before he sets out: a real delay.
		var tkey := "thorns_for_%d" % m.get_instance_id()
		if bc._slot_ready(rules, ctx.slots, "thorns") and not ctx.memo.has(tkey) and w.phase != WarningDirector.Phase.DELIVERED \
					and _length(road) > THORN_AT + 2.0:
			var spot: Dictionary = _along(road, THORN_AT)
			rules.cast(ctx.slots.thorns, spot.at, {"dir": (spot.dir as Vector2).orthogonal()})
			ctx.memo[tkey] = true
			return "thornwall across the carrier's road"
		# The mirror when he is on his way: a way in on the road he is walking, a moment ahead of him; a way out on the ground beyond the nearest wall.
		var key := "mirror_for_%d" % m.get_instance_id()
		if bc._slot_ready(rules, ctx.slots, "mirror") and not ctx.memo.has(key) and m.mind == Person.Mind.DUTY and m.has_goal():
			var in_at := GodT1.road_ahead(m, WAY_IN_SECONDS)
			var out_at := _beyond(bc, crowd, in_at)
			if out_at != Vector2.INF:
				rules.cast(ctx.slots.mirror, in_at, {"to": out_at})
				ctx.memo[key] = true
				return "mirror the carrier out (in %.1f, %.1f)" % [in_at.x, in_at.y]
		return "")


## Walkable ground outside the walls near `from`: the nearest outside it by the straight line, 1.5 further out than the wall's margin where it can.
static func _beyond(bc, crowd: Crowd, from: Vector2) -> Vector2:
	var best := Vector2.INF
	for rad: float in [2.0, 3.0, 4.0, 5.0, 6.5, 8.0, 10.0, 14.0]:
		for k in 24:
			var g: Vector2 = crowd._grid.nearest_walkable(from + Vector2.from_angle(TAU * float(k) / 24.0) * rad, 2)
			if g == Vector2.INF or not Walls.outside(g) or Walls.outside(g) and City.current().town().grow(Walls.MARGIN + 0.8).has_point(g):
				continue
			if best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from):
				best = g
		if best != Vector2.INF:
			return best
	return best


# --- Decree: Leaving Is Prohibited, The Bell Lies ---

## ALL IS WELL when the runner is within LIE_LEAD seconds of the keeper and the bell is not lying, so his delivery falls inside the lie (it holds 45 s); Leaving Is Prohibited on him at his post when
## he would arrive before the lie can be sent, to hold him until it is up.
static func act_decree(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	var memo: Dictionary = ctx.memo
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		var lying := crowd.is_bell_lying()
		var eta := _eta(ctx, m)
		if not lying and bc._slot_ready(rules, ctx.slots, "belllies") and (eta <= LIE_LEAD or w.phase == WarningDirector.Phase.DELIVERED):
			if GodT1.cast_bell(bc, ctx, "well", _tower()):
				return "the bell lies: ALL IS WELL (he is %.0f s from the keeper)" % eta
		var wait: float = bc._slot_wait(rules, ctx.slots, "belllies")
		var key := "pin_until_%d" % w.get_instance_id()
		var pinned: float = float(memo.get(key, -1.0))
		# Held when neither the lie that is up nor the next one (ready in `wait`) will be there when he arrives.
		if crowd.lie_left() <= eta and wait + 1.5 > eta and bc._slot_ready(rules, ctx.slots, "noleave") and w._clock > pinned:
			rules.cast(ctx.slots.noleave, m.ground_pos)
			memo[key] = w._clock + PIN_SECONDS - 1.0
			return "hold the carrier at his post (the lie is %.0f s off, he would arrive in %.0f)" % [wait, eta]
		return "")


## The numbers the report lines print.
static func state(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as StarfallDirector
	if d == null:
		return ""
	var r := d.report()
	var crowd: Crowd = ctx.crowd
	return "stopped=%d relays=%d out=%d lies=%d alarm=%d bell=%s" % [d.stopped(), int(r.relays), int(r.out), int(r.lies), roundi(crowd.alarm),
		BellNetwork.State.keys()[crowd.bell.state] if crowd.bell != null else "none"]
