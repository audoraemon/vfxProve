extends RefCounted
## The scripted player's per-type policies for First Prayers (god T1R, spec 9): one act_<type>(bc, ctx) for each god type, playing only that type's
## two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the behaviour_check
## script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd.
##
## The poor walk to the shrine on their own (FirstPrayersDirector, rule 3), one at a time, so the night is the door: at the two instants a
## walker goes in and a prayer ends (the crits, crit_in()) no Faithful may see it. Each type clears the door in its own way (spec 8.6): Ruin
## with fire (F2), Death, Veil and Decree by killing the ones who would watch (Decree: Leaving and Breathing Is Prohibited together), Passage by
## lifting the watchers off it (Skylift), Dominion as loadout A does (Whisper and Discord).

const GodT1 := preload("res://tools/dev/routes/god_t1.gd")

## The types whose policy is written.
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## A policy that has not cast for this long casts something (the no-waiting rule: 45 s).
const FILL_AFTER := 34.0
## The seconds before a crit a door-clearing cast begins.
const LEAD := 9.0
## A fire lit this long before a crit has pulled the line away by then and still burns at it.
const FIRE_LEAD := 8.5
const SIGHT := MirasHouseDirector.SIGHT
## The most the Gaze may stand at for a seen kill to be worth it.
const BEAR_GAZE := 60.0


# --- the pieces every type uses ---

static func _t(ctx: Dictionary) -> float:
	return (ctx.rules as Rules).elapsed()


static func _ready(bc, ctx: Dictionary, key: String) -> bool:
	return bc._slot_ready(ctx.rules, ctx.slots, key)


## Casts `key` at `at` (extra for the effect) and notes the second; the cast's words, or "" when the rules refused it.
static func _cast(ctx: Dictionary, key: String, at: Vector2, words: String, extra := {}) -> String:
	if ctx.rules.cast(int(ctx.slots[key]), at, extra) == null:
		return ""
	ctx.memo["plast"] = _t(ctx)
	return words


## Seconds since the policy last cast.
static func _idle(ctx: Dictionary) -> float:
	return _t(ctx) - float(ctx.memo.get("plast", 0.0))


## The Faithful alive and out of doors, the nearest the door first.
static func _faithful(d: FirstPrayersDirector) -> Array[Person]:
	var out: Array[Person] = []
	for f in d.faithful:
		if MissionDirector._alive(f) and not f.inside:
			out.append(f)
	out.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(d.door) < b.ground_pos.distance_to(d.door))
	return out


## The living who must not be struck: the poor (the walker among them).
static func _spare(d: FirstPrayersDirector) -> Array:
	var out := []
	for g in d.grieving:
		if MissionDirector._alive(g):
			out.append(g)
	return out


## The carriers of the reports on the run.
static func _runners(d: FirstPrayersDirector) -> Array[Person]:
	var out: Array[Person] = []
	for r in d.reports:
		if r.is_open() and MissionDirector._alive(r.carrier):
			out.append(r.carrier)
	return out


## Seconds to the next moment the door must be unwatched, or INF: the prayer inside ending (and the walker waiting going in), or the
## walker's walk to the door.
static func crit_in(bc, ctx: Dictionary) -> float:
	var d := ctx.d as FirstPrayersDirector
	var left := d.reading_left()
	if left != INF:
		return left
	if MissionDirector._alive(d.walker):
		return bc._walk_len(ctx.crowd, d.walker.ground_pos, d.door) / maxf(d.walker.walk_speed, 0.05)
	# No one walks yet: the next walker's set-out and his walk (the nearest of the poor goes on duty at PANIC_SPEED x his pace).
	var next := d.next_walker()
	var due := d.walk_due()
	if next != null and due != INF:
		return maxf(due - d.timeline.elapsed(), 0.0) / maxf((ctx.rules as Rules).clock_rate, 0.1) + bc._walk_len(ctx.crowd, next.ground_pos, d.door) / (Person.PANIC_SPEED * next.pace)
	return INF


## Who would see the door now.
static func _watchers(d: FirstPrayersDirector) -> Array[Person]:
	return d.watchers(d.door, SIGHT)


## The aim of a Silent Doom that takes the most of `pool` and nobody else, unseen (or seen, with `seen_ok`; a Faithful's spot), or Vector2.INF.
static func _doom_aim(bc, ctx: Dictionary, pool: Array[Person], seen_ok := false) -> Vector2:
	var best := Vector2.INF
	var most := 0
	var spare := _spare(ctx.d)
	for f in pool:
		var mine := 0
		var foreign := false
		for v in SilentDoom.victims_at(ctx.crowd._field, f.ground_pos):
			if pool.has(v):
				mine += 1
			else:
				foreign = true
		if foreign or mine <= most or not (seen_ok or bc._doom_unseen(ctx.crowd, f.ground_pos, spare, 0.3)):
			continue
		best = f.ground_pos
		most = mine
	return best


## The burnable building nearest the best distance from the door for a fire that pulls the line away (within FIRE_PULL, `far` or more off the
## door so those pulled stand out of its sight), not yet burning, a house before a stall; null for none.
static func _kindling(ctx: Dictionary, far: float) -> Structure:
	var d := ctx.d as FirstPrayersDirector
	var best: Structure = null
	for s in (ctx.crowd._env as EnvironmentField).near(d.door, FirstPrayersDirector.FIRE_PULL + 1.0):
		if not is_instance_valid(s) or s.destroyed or s == d.house or not FireManager.burns(s) or ctx.crowd.fires.is_burning(s):
			continue
		var gap: float = s.center().distance_to(d.door)
		if gap > FirstPrayersDirector.FIRE_PULL or gap < far or s.role == &"decor":
			continue
		if best == null or s.max_hp > best.max_hp or (is_equal_approx(s.max_hp, best.max_hp) and gap > best.center().distance_to(d.door)):
			best = s
	return best


# --- Ruin: Smite and Ember ---

static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	# A report on the run: a bolt on the runner (alone, or when it is nearly at the Temple's door).
	if _ready(bc, ctx, "smite"):
		for c in _runners(d):
			if _alone(d, c, 2.4) or c.ground_pos.distance_to(d.temple_door) < 5.0:
				return _cast(ctx, "smite", c.ground_pos, "smite a runner to the Temple")
	# Fire pulls the Faithful from the door (F2): kept burning while a line stands (or lit as a crit nears with a watcher by), one fire after
	# another -- a house burns about as long as Ember takes to cool.
	var crit := crit_in(bc, ctx)
	var watched := not _watchers(d).is_empty()
	var lining := not d.liners.is_empty() or watched
	for f in _faithful(d):
		lining = lining or f.ground_pos.distance_to(d.door) <= FirstPrayersDirector.FIRE_PULL + 2.0  # one nearby may stroll up to the door
	if _ready(bc, ctx, "ember") and d._blaze == null and ((lining and crit <= FIRE_LEAD) or (not d.liners.is_empty() and crit > 25.0)
			or (_idle(ctx) > FILL_AFTER - 8.0 and crit > 25.0)):
		var s := _kindling(ctx, 4.0)
		if s != null:
			return _cast(ctx, "ember", s.center(), "ember a building by the shrine (%.1f off the door)" % s.center().distance_to(d.door))
	# The Faithful, one at a time, the nearest the door first, where the bolt takes nobody else and nobody sees: when the fire is idle.
	if _ready(bc, ctx, "smite") and _idle(ctx) > FILL_AFTER - 14.0:
		for f in _faithful(d):
			if _alone(d, f, 2.4):
				return _cast(ctx, "smite", f.ground_pos, "smite a Faithful where nobody sees")
	return ""


## Nobody living stands within `reach` of `p` but `p` (the poor included).
static func _alone(d: FirstPrayersDirector, p: Person, reach: float) -> bool:
	for group: Array[Person] in [d.crowd.citizens, d.crowd.soldiers]:
		for o in group:
			if is_instance_valid(o) and o != p and o.is_alive() and not o.inside and o.ground_pos.distance_to(p.ground_pos) < reach:
				return false
	return true


# --- Death: Death Mark and Raise the Dead ---

## Death (D34) takes every Faithful as fast as Death Mark allows, the nearest the door first -- the market lines the door with the four nearest at 1:15
## and a walker comes at 1:20, so they must all be gone by then or kept from seeing. With the door empty the poor hurry in and pray together, and the
## night ends about one prayer after the last death: its idle stretch (D34: up to 60 s) is that kill's fuse, the walk and the prayer. Raise the Dead
## keeps the door blind: as a crit nears with a Faithful watching it, a SPIRIT rises from a body by the door (everyone within its fright flees it)
## and possesses a watcher still in sight, walking him off it (the possessed see nothing); a runner to the Temple the mark cannot reach is possessed
## and walked back the way he came.

static func act_death(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var spirit: RaiseTheDeadFx = GodT1.free_spirit(ctx)
	for c in _runners(d):
		if _ready(bc, ctx, "deathmark") and not c.statuses.has(&"frail"):
			return _cast(ctx, "deathmark", c.ground_pos, "death mark a runner to the Temple")
		if spirit != null and c.ground_pos.distance_to(spirit.follow_up_from()) <= RaiseTheDeadFx.POSSESS_R - 0.2:
			var back := _whisper_spot(ctx, c, c.ground_pos * 2.0 - d.temple_door, RaiseTheDeadFx.POSSESS_R - 0.5)
			if back != Vector2.INF and GodT1.cast_possess(ctx, c, {"to": back}):
				ctx.memo["plast"] = _t(ctx)
				return "the spirit possesses a runner to the Temple: back the way he came"
	# The door at a crit: a watcher within the spirit's reach is possessed and walked off; else a spirit rises from a body by the door.
	var crit := crit_in(bc, ctx)
	var watchers: Array[Person] = []
	for w in _watchers(d):
		if _fuse_left(ctx, w) > crit:
			watchers.append(w)  # (one whose mark falls first sees nothing)
	if crit <= LEAD and not watchers.is_empty():
		if spirit != null:
			var from := spirit.follow_up_from()
			for w in watchers:
				if w.ground_pos.distance_to(from) > RaiseTheDeadFx.POSSESS_R - 0.2 or w.shaken() or w.resists_mind():
					continue
				var off := _whisper_spot(ctx, w, w.ground_pos * 2.0 - d.door, RaiseTheDeadFx.POSSESS_R - 0.5)
				if off != Vector2.INF and GodT1.cast_possess(ctx, w, {"to": off}):
					ctx.memo["plast"] = _t(ctx)
					return "the spirit possesses a Faithful at the door: off out of sight"
		elif _ready(bc, ctx, "raise"):
			var body: Vector2 = GodT1.body_near(ctx.crowd, d.door, RISE_NEAR, true)
			if body != Vector2.INF:
				return _cast(ctx, "raise", body, "raise a spirit by the door", {"mode": "spirit"})
	var faithful := _faithful(d)
	var doomed: Array[Person] = []
	for f in faithful:
		if not f.statuses.has(&"frail") and not d._carrying(f):
			doomed.append(f)
	# Death Mark: one at a time, the nearest the door first, each alone where he stands (seen, while the Gaze can bear it, once the night is under way).
	if _ready(bc, ctx, "deathmark"):
		var room := d.gaze.value + GazeMeter.SEEN_DEATH <= BEAR_GAZE and d.timeline.elapsed() > 8.0
		for f in doomed:
			if _alone(d, f, 2.6) or room:
				return _cast(ctx, "deathmark", f.ground_pos, "death mark a Faithful")
	return ""


## Seconds until `p`'s Death Mark falls on him (the mark still running), INF when he wears none.
static func _fuse_left(ctx: Dictionary, p: Person) -> float:
	var fx := (ctx.rules as Rules).live_fx("deathmark") as DeathMarkFx
	if fx == null or fx.marked != p or not p.statuses.has(&"frail"):
		return INF
	return DeathMarkFx.MARK_TIME - fx.t


## Death: a spirit rises from a body with its soul still near within this of the door (its fright reaches FRIGHT_R about it).
const RISE_NEAR := 4.0


# --- Veil: Silent Doom and Blight ---
# (Blight has no use at First Prayers: the fountain it once rotted only to break an idle stretch was a filler, D38, and is gone.)

static func act_veil(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	if _ready(bc, ctx, "doom"):
		# A runner to the Temple first, where nobody would see it fall.
		var runners := _runners(d)
		if not runners.is_empty():
			var aim := _doom_aim(bc, ctx, runners)
			if aim != Vector2.INF:
				return _cast(ctx, "doom", aim, "doom a runner to the Temple")
		# The Faithful who would watch the door at a crit: unseen if it can be, else seen while the Gaze can bear it.
		var crit := crit_in(bc, ctx)
		var watchers := _watchers(d)
		var room := d.gaze.value + GazeMeter.SEEN_DEATH <= BEAR_GAZE
		if crit <= LEAD and not watchers.is_empty():
			var aim := _doom_aim(bc, ctx, watchers)
			if aim == Vector2.INF and room:
				aim = _doom_aim(bc, ctx, watchers, true)
			if aim != Vector2.INF:
				return _cast(ctx, "doom", aim, "doom a Faithful by the door")
		# The Faithful, the clustered first (the clergy at the Temple's door fall to one), whenever they can be taken unseen; seen, as a window nears.
		var near_window := d.timeline.elapsed() > d.market_at - 30.0 and d.timeline.elapsed() < d.market_at + 10.0
		var all := _doom_aim(bc, ctx, _faithful(d))
		if all == Vector2.INF and room and (near_window or d.timeline.elapsed() > 8.0):
			all = _doom_aim(bc, ctx, _faithful(d), true)
		if all != Vector2.INF:
			return _cast(ctx, "doom", all, "doom the Faithful where nobody sees")
	return ""


# --- Passage: Skylift and Windfall ---

## Passage: the door is cleared by lifting its watchers off it, or the walker off the door while a line stands at it. A line (the market's four,
## the priests' two) that will still stand at the door when the walker comes would see him: the beam takes him where he will stand when it takes,
## clear of the Faithful, and sets him down where his walk back to the door is longest, so he comes back after it. Otherwise, as a crit nears --
## the walker going in, a prayer ending -- Skylift takes the Faithful who would see the door then (one beam on the door takes a whole line: every
## line spot lies within its radius), never the walker, and sets them down where their walk back is longest. While the beam cools and the walker
## would reach a watched door first, a Windfall of stone across his way makes him go round. A report on the run (one delivered fills the Gaze)
## is lifted where its walk to the Temple's door is longest, or, the beam cooling, crushed by a Windfall (a seen death costs the Gaze a tenth).
## With nothing to clear now, a Faithful walking near the shrine is lifted far off (_passage_fold(), D38), out of the door's watch for his long
## walk back.
## The beam is cast when the crit is LIFT_LEAD seconds off or less (at LIFT_LAST when one beam cannot take them all yet); it takes those
## standing within its radius less LIFT_EDGE (they shift on their spots), and never where the walker will stand within its radius and LIFT_CLEAR
## when it takes. Watchers are those within SIGHT + WATCH_ROOM of the door (one a step off walks up to it), now or by the crit.
const LIFT_LEAD := 4.0
const LIFT_LAST := SkyliftFx.T_TAKE + 0.6
const LIFT_EDGE := 0.15
const LIFT_CLEAR := 0.3
const WATCH_ROOM := 0.8
## The walker is carried off when the line stands LINE_ROOM seconds past his coming and he is HOLD_LEAD seconds or less from the door.
const LINE_ROOM := 2.0
const HOLD_LEAD := 20.0
## The Windfall falls across the walker's way when he is WALL_WHEN seconds or less from the door, WALL_AHEAD seconds ahead of him and at least
## WALL_NEAR units off him (its crush lands T_DROP on), with none of its heaps within WALL_SPARE of anyone where they will stand when it lands.
const WALL_WHEN := 9.0
const WALL_AHEAD := 3.0
const WALL_NEAR := 2.0
const WALL_SPARE := 0.4


static func act_passage(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var lift_ready := _ready(bc, ctx, "skylift")
	# A report on the run (the door was seen): the beam sets the runner down where his way to the Temple is longest; cooling, a Windfall crushes him.
	for r in _runners(d):
		var at: Vector2 = GodT1.road_ahead(r, SkyliftFx.T_TAKE)
		var to: Vector2 = _far_from(bc, ctx, at, d.temple_door) if lift_ready and not _takes_walker(ctx, at) else Vector2.INF
		if to != Vector2.INF:
			return _cast(ctx, "skylift", at, "skylift a runner to the Temple far off (%.0f to walk)" % bc._walk_len(ctx.crowd, to, d.temple_door), {"to": to})
		if _ready(bc, ctx, "windfall"):
			var line := _crush(ctx, r)
			if not line.is_empty():
				return _cast(ctx, "windfall", line[0], "windfall on a runner to the Temple", {"dir": line[1], "mode": "stone"})
	var crit := crit_in(bc, ctx)
	var walker: Person = d.walker if MissionDirector._alive(d.walker) and not d.walker.inside and d.walker.mind == Person.Mind.DUTY else null
	# A line will stand at the door when he comes: the beam carries him off, clear of the Faithful, so he comes back after it.
	if walker != null and crit <= HOLD_LEAD and _line_left(ctx, crit) > crit + LINE_ROOM:
		var at: Vector2 = GodT1.road_ahead(walker, SkyliftFx.T_TAKE)
		if lift_ready and at.distance_to(d.door) > MirasHouseDirector.DOOR_REACH + 0.5:
			var to: Vector2 = _far_from(bc, ctx, at, d.door) if not _takes_faithful(ctx, at) else Vector2.INF
			if to != Vector2.INF:
				return _cast(ctx, "skylift", at, "skylift the walker off the door while the line stands (%.0f to walk back, the line %.0f s more)" % [
					bc._walk_len(ctx.crowd, to, d.door), _line_left(ctx, 0.0)], {"to": to})
		if crit <= WALL_WHEN and _ready(bc, ctx, "windfall"):
			var wall := _wall_across(ctx, walker)
			if not wall.is_empty():
				return _cast(ctx, "windfall", wall[0], "windfall across the walker's way while the line stands (the beam cools %.0f s)" % [
					bc._slot_wait(ctx.rules, ctx.slots, "skylift")], {"dir": wall[1], "mode": "stone"})
	var eyes := _eyes_at(ctx, crit)
	# A crit near and the door watched: the beam takes the watchers off it -- at once if one beam takes them all, else at the last moment
	# (LIFT_LAST), when those still coming stand where they will see from.
	if lift_ready and crit <= LIFT_LEAD and not eyes.is_empty():
		var at := _lift_aim(ctx, eyes)
		if at != Vector2.INF and (_taken(ctx, at, eyes) == eyes.size() or crit <= LIFT_LAST):
			var to := _far_from(bc, ctx, at, d.door)
			if to != Vector2.INF:
				return _cast(ctx, "skylift", at, "skylift %d watcher(s) off the door (the crit in %.1f s)" % [_taken(ctx, at, eyes), crit], {"to": to})
	# The walker would reach a watched door before the beam is ready: stone across his way.
	var late: bool = bc._slot_wait(ctx.rules, ctx.slots, "skylift") + SkyliftFx.T_TAKE > crit - 0.5
	if walker != null and not eyes.is_empty() and late and crit <= WALL_WHEN and _ready(bc, ctx, "windfall"):
		var wall := _wall_across(ctx, walker)
		if not wall.is_empty():
			return _cast(ctx, "windfall", wall[0], "windfall across the walker's way (the beam cools %.0f s, the door %.0f s off)" % [
				bc._slot_wait(ctx.rules, ctx.slots, "skylift"), crit], {"dir": wall[1], "mode": "stone"})
	return _passage_fold(bc, ctx)


## The Faithful who would see the door `crit` seconds from now: within SIGHT + WATCH_ROOM of it now, or where their walk takes them by then.
static func _eyes_at(ctx: Dictionary, crit: float) -> Array[Person]:
	var d := ctx.d as FirstPrayersDirector
	var out := d.watchers(d.door, SIGHT + WATCH_ROOM)
	if crit == INF:
		return out
	for f in d.watchers(d.door, SIGHT + WATCH_ROOM + 30.0):
		if not out.has(f) and GodT1.road_ahead(f, crit).distance_to(d.door) <= SIGHT + WATCH_ROOM:
			out.append(f)
	return out


## Seconds from now that the door's line stands, if one stands there `after` seconds from now (the open one, or the market's or the priests'
## to come, on the strip's clock); 0 when none does then.
static func _line_left(ctx: Dictionary, after: float) -> float:
	var d := ctx.d as FirstPrayersDirector
	var rate := maxf((ctx.rules as Rules).clock_rate, 0.1)
	var tl := d.timeline.elapsed()
	var then := tl + after * rate
	for w: Array in [[d.market_at, d.market_seconds], [d.priests_at, d.priests_seconds]]:
		var start := float(w[0])
		var end := start + float(w[1])
		if then >= start and then < end:
			return (end - tl) / rate
	return 0.0


## A Faithful will stand within the beam's reach (and LIFT_CLEAR) of `at` when it takes: he would be set down beside the walker and walk back with him.
static func _takes_faithful(ctx: Dictionary, at: Vector2) -> bool:
	for f in _faithful(ctx.d):
		if GodT1.road_ahead(f, SkyliftFx.T_TAKE).distance_to(at) <= SkyliftFx.RADIUS + LIFT_CLEAR:
			return true
	return false


## A Windfall's line that crushes `r`: across his way where he will stand when it lands (T_DROP on), none of its heaps within reach of the poor
## where they will stand; [centre, direction], or [].
static func _crush(ctx: Dictionary, r: Person) -> Array:
	var at: Vector2 = GodT1.road_ahead(r, WindfallFx.T_DROP)
	var way := (at - r.ground_pos).normalized() if at.distance_to(r.ground_pos) > 0.05 else Vector2.RIGHT
	for rect in WindfallFx.rects(at, way.orthogonal()):
		for g in _spare(ctx.d):
			if GodT1.road_ahead(g as Person, WindfallFx.T_DROP).distance_to(rect.get_center()) <= WindfallFx.HIT_R + WALL_SPARE:
				return []
	return [at, way.orthogonal()]


## Skylift's cooldown.
static func _lift_cool() -> float:
	return float(PowerBook.get_power("skylift").cooldown)


## How many of `eyes` a beam at `at` takes (where they will stand when it takes).
static func _taken(_ctx: Dictionary, at: Vector2, eyes: Array[Person]) -> int:
	var n := 0
	for e in eyes:
		n += 1 if GodT1.road_ahead(e, SkyliftFx.T_TAKE).distance_to(at) <= SkyliftFx.RADIUS - LIFT_EDGE else 0
	return n


## The walker on his way, or one of the poor hurrying to an empty door (D34), will stand within the beam's reach (and LIFT_CLEAR) of `at` when
## it takes. (Others of the poor it may take: set down far off, they only walk the longer when their turn comes.)
static func _takes_walker(ctx: Dictionary, at: Vector2) -> bool:
	var d := ctx.d as FirstPrayersDirector
	var going: Array = d._hurrying.duplicate()
	going.append(d.walker)
	for g: Variant in going:
		if MissionDirector._alive(g) and not (g as Person).inside \
				and GodT1.road_ahead(g as Person, SkyliftFx.T_TAKE).distance_to(at) <= SkyliftFx.RADIUS + LIFT_CLEAR:
			return true
	return false


## Where one beam takes the most of `eyes` without the walker: the door, their middle, each of them, and points round the door are tried; the one
## that takes the most (the nearest the door of equals); Vector2.INF when none takes anyone.
static func _lift_aim(ctx: Dictionary, eyes: Array[Person]) -> Vector2:
	var d := ctx.d as FirstPrayersDirector
	var tries: Array[Vector2] = [d.door]
	var mid := Vector2.ZERO
	for e in eyes:
		var at: Vector2 = GodT1.road_ahead(e, SkyliftFx.T_TAKE)
		tries.append(at)
		mid += at
	tries.append(mid / float(eyes.size()))
	for k in 8:
		for r: float in [0.8, 1.6]:
			tries.append(d.door + Vector2.from_angle(TAU * float(k) / 8.0) * r)
	var best := Vector2.INF
	var most := 0
	for at in tries:
		var n := _taken(ctx, at, eyes)
		if n == 0 or _takes_walker(ctx, at):
			continue
		if n > most or (n == most and at.distance_to(d.door) < best.distance_to(d.door)):
			best = at
			most = n
	return best


## Where a beam taking at `at` sets them down: walkable ground FOLD_FAR off it, round the compass, with the longest walk back to `home` (the
## shrine's door, or the Temple's for a runner); Vector2.INF for none.
static func _far_from(bc, ctx: Dictionary, at: Vector2, home: Vector2) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var best := Vector2.INF
	var longest := 0.0
	for i in 16:
		var spot := at + Vector2.from_angle(TAU * float(i) / 16.0) * FOLD_FAR
		if not grid.walkable(spot):
			continue
		var back: float = bc._walk_len(ctx.crowd, spot, home)
		if back != INF and back > longest:
			best = spot
			longest = back
	return best


## A Windfall's line across the walker's way WALL_AHEAD seconds ahead of him: [centre, direction], or [] when it would fall within WALL_NEAR of him,
## on the shrine, or with a heap within WALL_SPARE (beyond its crush) of anyone where they will stand when it lands.
static func _wall_across(ctx: Dictionary, w: Person) -> Array:
	var d := ctx.d as FirstPrayersDirector
	var at: Vector2 = GodT1.road_ahead(w, WALL_AHEAD)
	if at.distance_to(w.ground_pos) < WALL_NEAR or at.distance_to(d.door) < SIGHT:
		return []
	var way := (at - w.ground_pos).normalized()
	var along := way.orthogonal()
	for r in WindfallFx.rects(at, along):
		if d.house != null and r.intersects(d.house.footprint.grow(0.1)):
			return []
		for e in ctx.crowd._field.in_radius(r.get_center(), WindfallFx.HIT_R + WALL_SPARE + 3.0):
			var p := e as Person
			if p != null and not p.inside and p.is_alive() \
					and GodT1.road_ahead(p, WindfallFx.T_DROP).distance_to(r.get_center()) <= WindfallFx.HIT_R + WALL_SPARE:
				return []
	return [at, along]


## With nothing to clear now (D38): a Faithful walking near the shrine is lifted far off -- the beam where he will stand when it takes, set down
## where his walk back to the door is longest -- so he is out of the door's watch for that walk (a market liner on his way to the line, a priest
## coming to the well, one strolling by). Only when the beam is ready again before the next crit and the next walker sets out, and never where
## it takes the walker or the next to set out, or lies near their way to the door. "" for none.
static func _passage_fold(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var out_in: float = (d.walk_due() - d.timeline.elapsed()) / maxf((ctx.rules as Rules).clock_rate, 0.1) if d.walk_due() != INF else INF
	if _idle(ctx) < FOLD_IDLE or not _ready(bc, ctx, "skylift") or _door_due(ctx) > FOLD_LEAD \
			or minf(crit_in(bc, ctx), out_in) < _lift_cool() + LIFT_LEAD + 1.0:
		return ""
	# One of the poor by the shrine who stops to look at the light is brought to its door (Mira's rule): with one there, only a beam that leaves
	# nobody watching the door.
	var poor_by := false
	for g in d.grieving:
		poor_by = poor_by or (MissionDirector._alive(g) and not g.inside and not d.believers.has(g) and g.ground_pos.distance_to(d.door) <= FOLD_POOR)
	var watching := d.watchers(d.door, SIGHT + WATCH_ROOM)
	var ways: Array[PackedVector2Array] = []
	for w: Variant in [d.walker, d.next_walker()]:
		if MissionDirector._alive(w) and not (w as Person).inside:
			var way: PackedVector2Array = ctx.crowd._grid.path((w as Person).ground_pos, d.door)
			way.insert(0, (w as Person).ground_pos)
			ways.append(way)
	for f in _faithful(d):
		if f.ground_pos.distance_to(d.door) > FOLD_NEAR or not f.has_goal() or f.held_by_god() or d._carrying(f):
			continue
		var at: Vector2 = GodT1.road_ahead(f, SkyliftFx.T_TAKE)
		var clear := not _takes_walker(ctx, at)
		for g in _spare(d):
			clear = clear and GodT1.road_ahead(g as Person, SkyliftFx.T_TAKE).distance_to(at) > SkyliftFx.RADIUS + LIFT_CLEAR
		for way in ways:
			clear = clear and not _way_near(way, at, SkyliftFx.RADIUS + 1.0)
		if not clear or (poor_by and _taken(ctx, at, watching) < watching.size()):
			continue
		var out := _far_from(bc, ctx, at, d.door)
		if out != Vector2.INF:
			return _cast(ctx, "skylift", at, "skylift a Faithful off from the shrine (%.0f to walk back)" % bc._walk_len(ctx.crowd, out, d.door), {"to": out})
	return ""


## Passage's fold (D38): with FOLD_IDLE seconds since the last cast and the door next mattering within FOLD_LEAD, a Faithful this near the door,
## walking, is lifted off FOLD_FAR, round the compass, the spot with the longest walk back to the door.
const FOLD_IDLE := 8.0
const FOLD_LEAD := 50.0
const FOLD_NEAR := 10.0
const FOLD_FAR := 16.0
## ...and with one of the poor this near the door, only when the beam takes every Faithful watching it.
const FOLD_POOR := 6.0


## Seconds until the door next matters: the next walker sets out, or the market's or the priests' line is called (0 while one is open), on the
## night's clock as the strip shows them.
static func _door_due(ctx: Dictionary) -> float:
	var d := ctx.d as FirstPrayersDirector
	var tl := d.timeline.elapsed()
	var due := d.walk_due()
	for w: Array in [[d.market_at, d.market_seconds], [d.priests_at, d.priests_seconds]]:
		if tl >= float(w[0]) and tl <= float(w[0]) + float(w[1]):
			return 0.0
		if float(w[0]) > tl:
			due = minf(due, float(w[0]))
	return maxf(due - tl, 0.0) / maxf((ctx.rules as Rules).clock_rate, 0.1)


## The way `way` (its first point where he stands) passes within `reach` of `at`.
static func _way_near(way: PackedVector2Array, at: Vector2, reach: float) -> bool:
	for k in range(1, way.size()):
		if Geometry2D.get_closest_point_to_segment(at, way[k - 1], way[k]).distance_to(at) <= reach:
			return true
	return way.size() == 1 and way[0].distance_to(at) <= reach


# --- Decree: Leaving Is Prohibited and Breathing Is Prohibited ---

## Decree takes the Faithful (as Death, D34) with the cell and the breath together (GodT1.cast_amber(), amber_breath()): walled in amber where
## they will stand as it seals, held, they cannot run from the airless circle, and die three seconds on; with the door empty the poor hurry in.
## A report on the run first, whatever it costs (one delivered fills the Gaze); and while a crit nears with a line at the door or one by it
## (RESERVE), the two are kept for that report. Otherwise the most Faithful for the fewest others doomed with them (DOOMED_OK at most: a death
## someone sees adds 10 to the Gaze), never holding one of the poor, and while their deaths leave the district short of Local Emergency
## (GodT1.deaths_left(): its bell would toll, and the toll adds 40).
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var follow := GodT1.amber_breath(bc, ctx)
	if follow != "":
		ctx.memo["plast"] = _t(ctx)
		return follow
	if GodT1.amber_pending(ctx):
		return ""
	for c in _runners(d):
		var cell := _cell_on(ctx, [c])
		if not cell.is_empty() and GodT1.cast_amber(bc, ctx, cell.at, [c]):
			ctx.memo["plast"] = _t(ctx)
			return "leaving is prohibited round a runner to the Temple: the breath follows"
	var crit := crit_in(bc, ctx)
	if crit <= RESERVE and (not d.liners.is_empty() or _line_left(ctx, crit) > 0.0 or not _watchers(d).is_empty()):
		return ""
	var best := {}
	for f in _faithful(d):
		var group: Array[Person] = []
		var at := GodT1.road_ahead(f, NoLeaveFx.T_SEAL)
		for o in _faithful(d):
			if GodT1.road_ahead(o, NoLeaveFx.T_SEAL).distance_to(at) <= NoLeaveFx.RADIUS - CELL_IN * 2.0:
				group.append(o)
		var cell := _cell_on(ctx, group)
		if cell.is_empty() or int(cell.doomed) > DOOMED_OK or group.size() + int(cell.doomed) > GodT1.deaths_left(ctx.crowd, cell.at):
			continue
		if best.is_empty() or group.size() - int(cell.doomed) > (best.group as Array).size() - int(best.doomed):
			best = {"at": cell.at, "group": group, "doomed": int(cell.doomed)}
	if not best.is_empty() and GodT1.cast_amber(bc, ctx, best.at, best.group):
		ctx.memo["plast"] = _t(ctx)
		return "leaving is prohibited round %d Faithful (%d others by them): the breath follows" % [(best.group as Array).size(), int(best.doomed)]
	return ""


## The cell and the breath are kept for a report while a crit with a line at the door (or one by it) is this near: their cooldown and a few seconds.
const RESERVE := 30.0
## A cell is laid on the Faithful where it dooms at most DOOMED_OK others with them.
const DOOMED_OK := 1


## The cell for `group` (Faithful, or a runner): laid on the middle of where they will stand as it seals, shifted as far as keeps each CELL_IN
## inside its edge to doom the fewest others (GodT1.amber_aim()); empty when it would hold one of the poor, or one of `group` would stand outside
## it. {"at", "doomed"}.
static func _cell_on(ctx: Dictionary, group: Array) -> Dictionary:
	var d := ctx.d as FirstPrayersDirector
	var mid := Vector2.ZERO
	for p: Person in group:
		mid += GodT1.road_ahead(p, NoLeaveFx.T_SEAL)
	mid /= float(group.size())
	var spread := 0.0
	for p: Person in group:
		spread = maxf(spread, GodT1.road_ahead(p, NoLeaveFx.T_SEAL).distance_to(mid))
	if spread > NoLeaveFx.RADIUS - CELL_IN:
		return {}
	var aim: Dictionary = GodT1.amber_aim(ctx.crowd, mid, group, clampf(NoLeaveFx.RADIUS - CELL_IN - spread, 0.0, GodT1.AMBER_SHIFT))
	for g: Person in _spare(d):
		if not g.inside and g.ground_pos.distance_to(aim.at) <= NoLeaveFx.RADIUS + GodT1.AMBER_ROOM:
			return {}
	return {"at": aim.at, "doomed": int(aim.doomed)}


## Those a cell is laid for stand at least this far inside its edge (they shift as it seals).
const CELL_IN := 0.4


# --- Dominion: Mind Whisper and Discord (loadout A's policy) ---

static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var tl := d.timeline.elapsed()
	var walker := d.walker if MissionDirector._alive(d.walker) else null
	var market_open := tl >= d.market_at - 6.0 and tl <= d.market_at + d.market_seconds + 2.0
	# A report on the run: sent back from the Temple (a whisper), or its carrier made to forget the errand (Discord).
	for c in _runners(d):
		if _ready(bc, ctx, "whisper") and not c.shaken() and c.mind != Person.Mind.WHISPERED:
			var away := c.ground_pos + (c.ground_pos - d.temple_door).normalized() * (MindWhisperFx.REACH - 0.5)
			return _cast(ctx, "whisper", c.ground_pos, "whisper a runner away from the Temple", {"target": c, "to": d._walkable(away)})
		if _ready(bc, ctx, "discord") and c.mind != Person.Mind.CONFUSED:
			return _cast(ctx, "discord", c.ground_pos, "discord a runner to the Temple")
	# The market's four stand at the door for 40 s: the walker is sent back down his road (a whisper, then a Discord) so that he comes after them.
	if walker != null and market_open and walker.ground_pos.distance_to(d.door) < 13.0 and d.reading_left() == INF:
		if _ready(bc, ctx, "whisper") and not walker.shaken() and walker.mind != Person.Mind.WHISPERED:
			var back := _whisper_spot(ctx, walker, d.poor_spot, MindWhisperFx.REACH - 0.5)
			if back != Vector2.INF:
				return _cast(ctx, "whisper", walker.ground_pos, "whisper the walker back down his road", {"target": walker, "to": back})
		if _ready(bc, ctx, "discord") and walker.shaken() and walker.mind != Person.Mind.WHISPERED and walker.mind != Person.Mind.CONFUSED:
			return _cast(ctx, "discord", walker.ground_pos, "discord the walker: he forgets his errand a while")
	# At a crit the Faithful who would see the door are put out of sight: Discord on two at once (15 s), else a whisper sending one away.
	var crit := crit_in(bc, ctx)
	var watchers := _watchers(d)
	if crit <= DOMINION_LEAD and not watchers.is_empty() and not market_open:
		if _ready(bc, ctx, "discord"):
			var best := Vector2.INF
			var most := 0
			for w in watchers:
				var n := 0
				for o in watchers:
					n += 1 if o.ground_pos.distance_to(w.ground_pos) <= DiscordFx.DISCORD_R else 0
				if n > most:
					most = n
					best = w.ground_pos
			if most >= 1:
				return _cast(ctx, "discord", best, "discord on the Faithful at the door")
		if _ready(bc, ctx, "whisper"):
			for w in watchers:
				if not w.shaken() and w.mind != Person.Mind.WHISPERED and not d._carrying(w):
					var away := w.ground_pos + (w.ground_pos - d.door).normalized() * (MindWhisperFx.REACH - 0.5)
					return _cast(ctx, "whisper", w.ground_pos, "whisper a Faithful away from the door", {"target": w, "to": d._walkable(away)})
	# The poor are fetched to the door as in loadout A (hop by hop, the door unwatched, the prayer ending outside the windows).
	if _ready(bc, ctx, "whisper") and d.faithful_seeing(d.door, SIGHT) == null and bc._prayers_ready(d) and not market_open and crit_in(bc, ctx) > 14.0:
		var best_g: Person = null
		for g in d.grieving:
			if not MissionDirector._alive(g) or g.inside or d.believers.has(g) or g == walker or g.shaken() or g.mind == Person.Mind.WHISPERED:
				continue
			if not d.inside().is_empty() and g.ground_pos.distance_to(d.door) < bc.PRAYERS_FAR:
				continue
			if best_g == null or g.ground_pos.distance_to(d.door) < best_g.ground_pos.distance_to(d.door):
				best_g = g
		if best_g != null:
			var to := d.door
			var hop := to - best_g.ground_pos
			if hop.length() > MindWhisperFx.REACH - 0.5:
				to = d._walkable(best_g.ground_pos + hop.normalized() * (MindWhisperFx.REACH - 0.5))
			return _cast(ctx, "whisper", best_g.ground_pos, "whisper one of the poor toward the shrine", {"target": best_g, "to": to})
	# With nothing else to do: a Faithful sent a way off from the shrine (he walks back from farther off). (D38: the Discord at the empty Temple
	# door that stood here was a filler, and is gone.)
	if _idle(ctx) > FILL_AFTER - 2.0 and crit > 16.0 and not market_open and walker == null:
		if _ready(bc, ctx, "whisper"):
			for f in _faithful(d):
				if not f.shaken() and f.mind != Person.Mind.WHISPERED and not d._carrying(f):
					var off := _whisper_spot(ctx, f, d.door + (f.ground_pos - d.door) * 2.0, MindWhisperFx.REACH - 0.5)
					if off != Vector2.INF and off.distance_to(d.door) > f.ground_pos.distance_to(d.door):
						return _cast(ctx, "whisper", f.ground_pos, "whisper a Faithful a way off from the shrine", {"target": f, "to": off})
	return ""


## The seconds before a crit the Dominion policy begins putting the watchers out of sight.
const DOMINION_LEAD := 12.0


## The numbers a report line prints (route B's, with the walker).
static func state(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var walker := "-"
	if d != null and MissionDirector._alive(d.walker):
		walker = "%.0f%s%s" % [d.walker.ground_pos.distance_to(d.door), Person.Mind.keys()[d.walker.mind].substr(0, 2), "g" if d.walker.has_goal() else "-"]
	var faithful := 0
	if d != null:
		faithful = _faithful(d).size()
	return "%s walker=%s faithful=%d[%s] liners=%d(%.0f) blaze=%s" % [String(preload("res://tools/dev/routes/tier1_b.gd").state_prayers(bc, ctx)), walker,
		faithful, faithful_line(d) if d != null else "", d.liners.size() if d != null else 0, d._liners_left if d != null else 0.0, "y" if d != null and d._blaze != null else "-"]


## The Faithful as `distance to the door` and the first letter of the mind (D duty, C calm, ...), for the report lines.
static func faithful_line(d: FirstPrayersDirector) -> String:
	var out := PackedStringArray()
	for f in d.faithful:
		if MissionDirector._alive(f):
			out.append("%.0f%s%s" % [f.ground_pos.distance_to(d.door), Person.Mind.keys()[f.mind].substr(0, 1), "i" if f.inside else ""])
	return ",".join(out)


## Silent Doom on the Faithful whenever a cast can take them and nobody else: unseen, or seen while the Gaze can bear it once the night is under
## way (after `seen_after` seconds; the clustered first: the clergy at the Temple's door fall to one). Loadout B's filler; "" when none can be taken or Doom is not ready.
static func doom_faithful(bc, ctx: Dictionary, seen_after := 8.0) -> String:
	if not _ready(bc, ctx, "doom"):
		return ""
	var d := ctx.d as FirstPrayersDirector
	var aim := _doom_aim(bc, ctx, _faithful(d))
	if aim == Vector2.INF and d.gaze.value + GazeMeter.SEEN_DEATH <= BEAR_GAZE and d.timeline.elapsed() > seen_after:
		aim = _doom_aim(bc, ctx, _faithful(d), true)
	return _cast(ctx, "doom", aim, "doom a Faithful where nobody sees") if aim != Vector2.INF else ""


## A spot to whisper `p` to, `reach` from him, on the side of `toward` first and then round the compass, that he has a way to (and is not shut in
## a pocket of ground); Vector2.INF for none.
static func _whisper_spot(ctx: Dictionary, p: Person, toward: Vector2, reach: float) -> Vector2:
	var d := ctx.d as FirstPrayersDirector
	var grid: WalkGrid = ctx.crowd._grid
	var base := (toward - p.ground_pos).normalized()
	for k in 8:
		var turn := (float((k + 1) / 2) * (1.0 if k % 2 == 0 else -1.0)) * TAU / 8.0
		var spot := d._walkable(p.ground_pos + base.rotated(turn) * reach)
		var way := grid.path(p.ground_pos, spot)
		if spot.distance_to(p.ground_pos) > reach * 0.6 and not way.is_empty() and way[way.size() - 1].distance_to(spot) < 1.0:
			return spot
	return Vector2.INF
