extends RefCounted
## The scripted player's per-type policies for The Warning (god T1R, spec 4.2 and 9): one act_<type>(bc, ctx) for each god type, playing only that
## type's two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the behaviour_check
## script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd. The board's Warning (the Warning rework, spec 12): three watchmen
## hold three quiet posts and set off at 20, 40 and 60 s, so each policy first works the watchmen still AT THEIR POSTS, the soonest set-off first
## (_posted(): what the tags' countdowns tell a player), and then, for a watchman who has set off (a runner), the policy it always had.

const GodT1 := preload("res://tools/dev/routes/god_t1.gd")

## The types whose policy is written.
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## Nobody but the carrier within this of where a death falls: Crowd.DOOM_WITNESS plus the room a man on the run covers meanwhile.
const UNSEEN := 2.0
const MOVE_ROOM := 0.9
## The room a blow's neighbours are given before it lands: how far a walker covers in a Silent Doom's T_STRIKE and a little more.
const CLUSTER_MARGIN := 0.6
## Passage's Windfall falls across his road this far along it (beyond the reach of its crush when it lands: he walks on meanwhile).
const WALL_AT := 4.0
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
## Mind Whisper's reach, less a little for the walk's start.
const WHISPER_REACH := MindWhisperFx.REACH - 0.5
## The longest walk a single whisper sends the carrier on towards the gate.
const HOP := 8.0


## Every warning that has a carrier to work: set up, not stopped, its carrier alive and out of doors and not yet out of the walls. `posted` picks the
## watchmen still at their posts (before their set-off); else the runners (set off, and any relay).
static func _carriers(ctx: Dictionary, posted := false) -> Array[WarningDirector]:
	var out: Array[WarningDirector] = []
	var d := ctx.d as StarfallDirector
	if d == null:
		return out
	for w: WarningDirector in d.stars:
		if w.rules == null or w.warning_dead or w.phase == WarningDirector.Phase.OVER or w.at_post() != posted:
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


## The watchmen still at their posts, the soonest set-off first: [{"w": the warning, "i": its star, "eta": mission seconds until he sets off}].
static func _posted(ctx: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var d := ctx.d as StarfallDirector
	if d == null:
		return out
	for w: WarningDirector in _carriers(ctx, true):
		var i := d.stars.find(w)
		out.append({"w": w, "i": i, "eta": d.sets_off_in(i)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.eta) < float(b.eta))
	return out


## One look for every type but those that hold the carrier: the first warning a move serves. `posted` works the watchmen at their posts, else the runners.
static func _each(ctx: Dictionary, move: Callable, posted := false) -> String:
	for w in _carriers(ctx, posted):
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
	# A watchman at his post stands still in his quiet ring: the bolt falls on him where he stands when nobody is near to see (the fright it throws
	# reaches past the ring and frightens nobody into it), the soonest set-off first.
	if bc._slot_ready(rules, ctx.slots, "smite"):
		for row: Dictionary in _posted(ctx):
			var at: Vector2 = (row.w as WarningDirector).messenger.ground_pos
			if _seers(crowd, at, UNSEEN + MOVE_ROOM, (row.w as WarningDirector).messenger) == 0:
				rules.cast(ctx.slots.smite, _off_the_wall(crowd, at))
				return "smite the watchman at his post (%s, sets off in %.0f s)" % [(row.w as WarningDirector).post_name.to_lower(), float(row.eta)]
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
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


## Where a bolt for the man at `at` falls: still within the bolt's kill radius of him (KILL_R, with a hand's margin), but past the blow's reach (SmiteFx.HIT_R) of every
## building -- his post is 0.6 inside the gate's face, so a bolt on his feet hits the gate for 45 (preflight M4). The best of eight points round him, else `at`.
static func _off_the_wall(crowd: Crowd, at: Vector2) -> Vector2:
	var best := at
	var best_gap := _wall_gap(crowd, at)
	if best_gap > SmiteFx.HIT_R + 0.05:
		return at
	for k in 8:
		var v := at + Vector2.RIGHT.rotated(TAU * float(k) / 8.0) * (SmiteFx.KILL_R - 0.15)
		var gap := _wall_gap(crowd, v)
		if gap > best_gap:
			best_gap = gap
			best = v
	return best


## How near the nearest standing building is to `at` (its footprint's edge).
static func _wall_gap(crowd: Crowd, at: Vector2) -> float:
	var gap := INF
	for b in crowd._env._structures:
		if is_instance_valid(b) and not b.destroyed:
			gap = minf(gap, b.distance_to(at))
	return gap


## The centre of the house within 3.5 of `at` that burns and is not burning yet; INF for none.
static func _house_near(ctx: Dictionary, at: Vector2) -> Vector2:
	var env: EnvironmentField = (ctx.crowd as Crowd)._env
	var best := Vector2.INF
	for st in env.near(at, 3.5):
		if is_instance_valid(st) and not st.destroyed and FireManager.burns(st) and st.kind == Structure.Kind.HOUSE \
				and not (ctx.crowd as Crowd).fires.is_burning(st) and not Walls.outside(st.center()):
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


# --- Death: Death Mark, Raise the Dead ---

## Death Mark on the watchman at his post with the soonest set-off that leaves the mark its MARK_TIME (and a hand's breadth) to fall in: the mark falls
## on him where he stands, ten seconds on, before he sets off. When the soonest is too near his set-off, a later watchman is marked; else the policy works a
## runner: Raise the Dead on a body near him (its zombies hunt, a bite kills), or Death Mark on him.
static func act_death(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	if bc._slot_ready(rules, ctx.slots, "deathmark"):
		for row: Dictionary in _posted(ctx):
			var m: Person = (row.w as WarningDirector).messenger
			if m.statuses.has(&"frail") or float(row.eta) < DeathMarkFx.MARK_TIME + MARK_SLACK:
				continue
			rules.cast(ctx.slots.deathmark, m.ground_pos)
			return "deathmark the watchman at his post (%s, sets off in %.0f s)" % [(row.w as WarningDirector).post_name.to_lower(), float(row.eta)]
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		if m.statuses.has(&"frail"):
			return ""
		if bc._slot_ready(rules, ctx.slots, "raise"):
			var body := GodT1.body_near(crowd, m.ground_pos, RAISE_NEAR)
			if body != Vector2.INF:
				rules.cast(ctx.slots.raise, body)
				return "raise the dead beside the carrier"
		if bc._slot_ready(rules, ctx.slots, "deathmark"):
			rules.cast(ctx.slots.deathmark, m.ground_pos)
			return "deathmark the carrier"
		return "")


## The mark must have this much more than MARK_TIME before his set-off.
const MARK_SLACK := 0.5
## A body this near a runner is worth a Raise the Dead (it takes bodies within 3).
const RAISE_NEAR := 2.5


# --- Veil: Silent Doom, Blight ---

## Silent Doom where he stands when nobody else is within the witness distance of him and the room he covers in its T_STRIKE; as Ruin's Smite, a blow with
## few to see it after SEEN_AFTER seconds, and whoever sees when he is nearly at the keeper. Never Blight the tower (a silenced bell sends the warning to the
## Temple at once).
static func act_veil(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	if not bc._slot_ready(rules, ctx.slots, "doom"):
		return ""
	# A watchman at his post, the soonest set-off first: Silent Doom where he stands when the cluster aim is clean, else wait until it is.
	for row: Dictionary in _posted(ctx):
		var pm: Person = (row.w as WarningDirector).messenger
		var at := _cluster_aim(crowd, pm, SilentDoom.RADIUS, SilentDoom.RADIUS - 0.1, CLUSTER_MARGIN)
		if at != Vector2.INF:
			rules.cast(ctx.slots.doom, at)
			return "doom the watchman at his post (%s, sets off in %.0f s)" % [(row.w as WarningDirector).post_name.to_lower(), float(row.eta)]
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

## A watchman is left for Discord only when it is ready this many seconds before his set-off.
const DISCORD_SLACK := 2.0

## Mind Whisper sends him through his gate to ground outside the walls within its reach (the nearest by his walk); Discord holds him while the whisper
## cools or he is shaking one off.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	# A watchman at his post, the soonest set-off first (W-R7): Discord on him when it is ready (he dreams he saw the star, and the warning stops).
	# One that Discord will not be ready for before he sets off is led out instead: the whisper takes him through his gate to ground beyond the walls
	# (the postern's by its key, K2) where W1 stops him. A watchman Discord will reach in time waits for it.
	var posted := _posted(ctx)
	if bc._slot_ready(rules, ctx.slots, "discord"):
		for row: Dictionary in posted:
			var pm: Person = (row.w as WarningDirector).messenger
			if pm.mind != Person.Mind.CONFUSED:
				rules.cast(ctx.slots.discord, pm.ground_pos)
				return "discord the watchman at his post, he will think he dreamt it (%s, sets off in %.0f s)" % [(row.w as WarningDirector).post_name.to_lower(), float(row.eta)]
	if bc._slot_ready(rules, ctx.slots, "whisper"):
		var cools := float(bc._slot_wait(rules, ctx.slots, "discord"))
		for row: Dictionary in posted:
			var pm: Person = (row.w as WarningDirector).messenger
			if pm.shaken() or (pm.mind == Person.Mind.WHISPERED and pm.has_goal()) or float(row.eta) - DISCORD_SLACK > cools:
				continue  # he is led already, or Discord will be ready for him in time
			var spot := _out_spot(bc, crowd, pm)
			if spot != Vector2.INF:
				var to := _hop(crowd, pm, spot)
				rules.cast(ctx.slots.whisper, pm.ground_pos, {"target": pm, "to": to})
				return "whisper the watchman at his post %s (%.1f, %.1f) (%s, sets off in %.0f s)" % ["out to" if to == spot else "a hop towards the gate:", to.x, to.y,
					(row.w as WarningDirector).post_name.to_lower(), float(row.eta)]
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


# --- Passage: Skylift, Windfall ---

## Skylift takes the carrier where he will stand when its beam takes (SkyliftFx.T_TAKE on, along his road) and sets him down on the ground beyond
## the nearest wall: out of the walls, the warning stops (W1). While the beam cools and he would reach the keeper first, a Windfall of stone across
## his road ahead (WALL_AT on) bars it, so he goes round, and the beam is ready again before he arrives.
static func act_passage(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	# A watchman at his post, the soonest set-off first: the lift (its beam takes only him: the quiet ring is wider than its reach) sets him down beyond the wall.
	if bc._slot_ready(rules, ctx.slots, "skylift"):
		for row: Dictionary in _posted(ctx):
			var pm: Person = (row.w as WarningDirector).messenger
			var out := _beyond(bc, crowd, pm.ground_pos)
			if out != Vector2.INF:
				rules.cast(ctx.slots.skylift, pm.ground_pos, {"to": out})
				return "skylift the watchman at his post out (%s, sets off in %.0f s)" % [(row.w as WarningDirector).post_name.to_lower(), float(row.eta)]
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		if bc._slot_ready(rules, ctx.slots, "skylift"):
			var from := GodT1.road_ahead(m, SkyliftFx.T_TAKE) if m.has_goal() else m.ground_pos
			var to := _beyond(bc, crowd, from)
			if to != Vector2.INF:
				rules.cast(ctx.slots.skylift, from, {"to": to})
				return "skylift the carrier out, from (%.1f, %.1f) to (%.1f, %.1f)" % [from.x, from.y, to.x, to.y]
		var road := _road(ctx, m)
		var wkey := "windfall_for_%d" % m.get_instance_id()
		if road.size() < 2 or ctx.memo.has(wkey) or w.phase == WarningDirector.Phase.DELIVERED or not bc._slot_ready(rules, ctx.slots, "windfall"):
			return ""
		var eta := _eta(ctx, m)
		if bc._slot_wait(rules, ctx.slots, "skylift") + SkyliftFx.T_TAKE < eta or _length(road) < WALL_AT + 2.0:
			return ""
		var spot: Dictionary = _along(road, WALL_AT)
		rules.cast(ctx.slots.windfall, spot.at, {"dir": (spot.dir as Vector2).orthogonal(), "mode": "stone"})
		ctx.memo[wkey] = true
		return "windfall of stone across the carrier's road (the beam cools %.0f s, he is %.0f s from the keeper)" % [
			bc._slot_wait(rules, ctx.slots, "skylift"), eta])


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


# --- Decree: Leaving Is Prohibited, Breathing Is Prohibited ---

## A fright first, as Ruin's Smite: once his star has fallen, the air goes out (Breathing Is Prohibited) behind the watchman on the side away from
## his gate's way out -- he runs from it, out through the gate (the postern's watchman with its key), and the walls stop the warning (W1). Its
## circle is left at a run, but one boxed in against the wall chokes, so it is laid only where it takes at most FRIGHT_FEW others (_fright_at()).
## A carrier on the road (the fright spent, or no room for it) is walled in amber (Leaving Is Prohibited) where he will stand as it seals, on the
## spot that holds the fewest others with him (GodT1.amber_aim()), and the breath follows (GodT1.amber_breath()): held, he cannot run from it, and
## three seconds kill him; whoever stood near him either chokes with him in the cell or ran from the air. Each held by him dies too, and four
## deaths in a district call the bell (AlarmManager.LOCAL_EVENTS): it waits until his death and theirs leave the district short of that
## (GodT1.deaths_left()), unless he is nearly at the keeper (URGENT_ETA), the keeper has it, or his is the night's last warning (the bell those
## deaths call is not rung before he is dead and the night won).
static func act_decree(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var crowd: Crowd = ctx.crowd
	var follow := GodT1.amber_breath(bc, ctx)
	if follow != "" or GodT1.amber_pending(ctx):
		return follow
	# A watchman at his post (W-R10), the soonest set-off first: Leaving Is Prohibited, then Breathing Is Prohibited on him (breath alone never kills a
	# standing man: he walks out of its circle). Three Might each, and the breath ready by the time the cell seals; he holds still, so the cell is laid on him.
	if rules.might == null or rules.might.can_pay(DECREE_MIGHT):
		for row: Dictionary in _posted(ctx):
			var pm: Person = (row.w as WarningDirector).messenger
			if GodT1.cast_amber(bc, ctx, pm.ground_pos, [pm]):
				return "leaving is prohibited round the watchman at his post (%s, sets off in %.0f s): the breath follows" % [(row.w as WarningDirector).post_name.to_lower(), float(row.eta)]
	return _each(ctx, func(w: WarningDirector) -> String:
		var m := w.messenger
		var door := w.key_door()
		var out := door if door != Vector2.INF else _out_spot(bc, crowd, m)
		var way: float = (m.ground_pos.distance_to(door) if door != Vector2.INF else bc._walk_len(crowd, m.ground_pos, out)) if out != Vector2.INF else INF
		var skey := "scared_%d" % m.get_instance_id()
		if m.mind != Person.Mind.FLEE and w.omen_fallen and w.phase != WarningDirector.Phase.DELIVERED and bc._slot_ready(rules, ctx.slots, "breath") \
				and way <= SCARE_WALK and not ctx.memo.has(skey):
			var back := _fright_at(crowd, m, out)
			if back != Vector2.INF:
				ctx.memo[skey] = true
				rules.cast(ctx.slots.breath, back)
				return "breathing is prohibited behind the carrier, to send him out through the gate"
		var at := GodT1.road_ahead(m, NoLeaveFx.T_SEAL) if m.has_goal() else m.ground_pos
		var aim: Dictionary = GodT1.amber_aim(crowd, at, [m])
		var urgent := w.phase == WarningDirector.Phase.DELIVERED or _eta(ctx, m) < URGENT_ETA or _last(ctx, w)
		if int(aim.doomed) + 1 > GodT1.deaths_left(crowd, at) and not urgent:
			return ""
		if GodT1.cast_amber(bc, ctx, aim.at, [m]):
			return "leaving is prohibited round the carrier (%d others held, %d of them by him): the breath follows" % [int(aim.others), int(aim.doomed)]
		return "")


## The Might both of Decree's laws cost together (Leaving Is Prohibited 1, Breathing Is Prohibited 2).
const DECREE_MIGHT := 3


## `w` is the last warning of the night: every other star's warning is stopped.
static func _last(ctx: Dictionary, w: WarningDirector) -> bool:
	var d := ctx.d as StarfallDirector
	if d == null or d.stars.size() < d.star_falls.size():
		return false
	for o: WarningDirector in d.stars:
		if o != w and not o.warning_dead:
			return false
	return true


## Decree's fright: the airless circle's centre FRIGHT_BACK behind him from `out` (turned up to FRIGHT_TURN either way), where it takes the fewest
## others, at most FRIGHT_FEW; Vector2.INF for none.
static func _fright_at(crowd: Crowd, m: Person, out: Vector2) -> Vector2:
	var away := (m.ground_pos - out).normalized()
	var best := Vector2.INF
	var fewest := FRIGHT_FEW + 1
	for back: float in FRIGHT_BACK:
		for turn: float in [0.0, FRIGHT_TURN, -FRIGHT_TURN]:
			var g := m.ground_pos + away.rotated(turn) * back
			var n := 0
			for e in crowd._field.in_radius(g, BreathFx.RADIUS + FRIGHT_ROOM):
				var p := e as Person
				if p != null and p != m and p.is_alive() and not p.inside:
					n += 1
			if n < fewest:
				best = g
				fewest = n
	return best


## The fright's circle lies these far behind him (inside its radius, so he is in it), turned up to FRIGHT_TURN radians from straight behind; it
## takes at most FRIGHT_FEW others within its radius and FRIGHT_ROOM.
const FRIGHT_BACK := [1.4, 1.0, 1.8]
const FRIGHT_TURN := 0.45
const FRIGHT_FEW := 1
const FRIGHT_ROOM := 0.3


## The numbers the report lines print.
static func state(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as StarfallDirector
	if d == null:
		return ""
	var r := d.report()
	var crowd: Crowd = ctx.crowd
	return "stopped=%d relays=%d out=%d lies=%d dreamt=%d alarm=%d bell=%s" % [d.stopped(), int(r.relays), int(r.out), int(r.lies), int(r.dreamt), roundi(crowd.alarm),
		BellNetwork.State.keys()[crowd.bell.state] if crowd.bell != null else "none"]
