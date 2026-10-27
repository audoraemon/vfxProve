extends RefCounted
## The scripted player's per-type policies for First Prayers (god T1R, spec 9): one act_<type>(bc, ctx) for each god type, playing only that type's
## two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the behaviour_check
## script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd.
##
## The poor walk to the shrine on their own (FirstPrayersDirector, rule 3), one at a time, so the night is the door: at the two instants a
## walker goes in and a prayer ends (the crits, crit_in()) no Faithful may see it. Each type clears the door in its own way (spec 8.6): Ruin
## with fire (F2), Death and Veil by killing the ones who would watch, Passage with brambles and a mirror (F3), Decree with ALL IS WELL (F5),
## Dominion as loadout A does (Whisper and Discord).

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


# --- Death: Death Mark and Pestilence ---

static func act_death(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	for c in _runners(d):
		if _ready(bc, ctx, "deathmark") and not c.statuses.has(&"frail"):
			return _cast(ctx, "deathmark", c.ground_pos, "death mark a runner to the Temple")
		if _ready(bc, ctx, "pestilence") and c.sick_left <= 0.0 and _alone(d, c, 3.0):
			return _cast(ctx, "pestilence", c.ground_pos, "pestilence on a runner to the Temple")
	var faithful := _faithful(d)
	var doomed: Array[Person] = []
	for f in faithful:
		if not f.statuses.has(&"frail") and f.sick_left <= 0.0 and not d._carrying(f):
			doomed.append(f)
	# The plague takes a clustered few at once (the clergy at the Temple's door) when no one else stands by to catch it, or one alone.
	if _ready(bc, ctx, "pestilence"):
		var aim := _plague_on(ctx, doomed, 1)
		if aim != Vector2.INF:
			return _cast(ctx, "pestilence", aim, "pestilence on the Faithful")
	# Death Mark: one at a time, the nearest the door first, each alone where he stands (seen, while the Gaze can bear it, once the night is under way).
	if _ready(bc, ctx, "deathmark"):
		var room := d.gaze.value + GazeMeter.SEEN_DEATH <= BEAR_GAZE and d.timeline.elapsed() > 8.0
		for f in doomed:
			if _alone(d, f, 2.6) or room:
				return _cast(ctx, "deathmark", f.ground_pos, "death mark a Faithful")
	return ""


## Where Pestilence would take at least `least` of `pool` and nobody else, with no one within 1.7 (the plague spreads 1.5) to catch it.
static func _plague_on(ctx: Dictionary, pool: Array[Person], least: int) -> Vector2:
	var d := ctx.d as FirstPrayersDirector
	var best := Vector2.INF
	var most := 0
	for f in pool:
		var victims := PestilenceFx.victims_at(ctx.crowd._field, f.ground_pos)
		var mine := 0
		var clear := true
		for v in victims:
			if pool.has(v):
				mine += 1
			else:
				clear = false
		if not clear or mine <= most or mine < least:
			continue
		for group: Array[Person] in [d.crowd.citizens, d.crowd.soldiers]:
			for o in group:
				if is_instance_valid(o) and o.is_alive() and not o.inside and not victims.has(o) \
						and o.ground_pos.distance_to(f.ground_pos) < 1.7:
					clear = false
		if clear:
			best = f.ground_pos
			most = mine
	return best


# --- Veil: Silent Doom and Blight ---

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
	if _ready(bc, ctx, "blight") and _idle(ctx) > FILL_AFTER:
		for s in ctx.crowd._env.structures():
			if is_instance_valid(s) and not s.destroyed and s.kind == Structure.Kind.FOUNTAIN and not s.blighted:
				return _cast(ctx, "blight", s.center(), "blight a fountain")
	return ""


# --- Passage: Thornwall and Mirrorfold ---

static func act_passage(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var tl := d.timeline.elapsed()
	var now := _t(ctx)
	var trapped := now < float(ctx.memo.get("trap_until", -1.0))
	var crit := INF if trapped else crit_in(bc, ctx)
	var watchers := _watchers(d)
	# The market's four stand at the door for 40 s, and there is no wall long enough for all four. A mirror laid over the door as the first walker sets out
	# sets him down, far off, whenever he steps onto it, and he walks back into it again
	# (the loop of F4's mirror) while it lies, 30 s, and the walk back: he comes after the market has closed.
	if _ready(bc, ctx, "mirror") and not ctx.memo.has("trap") and MissionDirector._alive(d.walker) and tl >= d.market_at \
			and tl <= d.market_at + d.market_seconds - 15.0 and bc._walk_len(ctx.crowd, d.walker.ground_pos, d.door) > 1.5:
		var at := d.door
		var out := _loop_exit(ctx, at)
		if out != Vector2.INF:
			ctx.memo["trap"] = true
			ctx.memo["trap_until"] = now + MirrorfoldFx.MIRROR_TIME + 1.0
			return _cast(ctx, "mirror", at, "mirror over the door: the walker is set down far off, and again", {"to": out})
	# Thornwall between the door and the Faithful who would see it (F3), as a crit nears; one wall holds 25 s.
	var wall_free: bool = ctx.memo.has("trap") or tl > d.market_at + d.market_seconds - 15.0  # the market is the mirror's work, until it has been laid
	if _ready(bc, ctx, "thorns") and wall_free and not watchers.is_empty() and crit <= WALL_LEAD:
		var c := Vector2.ZERO
		for w in watchers:
			c += w.ground_pos - d.door
		c /= float(watchers.size())
		var toward := c.normalized() if c.length() > 0.1 else Vector2.DOWN
		return _cast(ctx, "thorns", d._walkable(d.door + toward * 0.8), "thornwall between the door and the Faithful", {"dir": toward.orthogonal()})
	# Never idle past the clock: a bramble wall at the door's blind side, or the mirror laid where no one walks.
	if _idle(ctx) > FILL_AFTER - 6.0 and crit > 20.0:
		if _ready(bc, ctx, "thorns") and watchers.is_empty():
			return _cast(ctx, "thorns", d._walkable(d.door + Vector2(0.0, 1.6)), "thornwall at the door", {"dir": Vector2(1.0, 0.0)})
		if _ready(bc, ctx, "mirror") and ctx.memo.has("trap") and not MissionDirector._alive(d.walker):
			var out := _mirror_exit(bc, ctx)
			if out != Vector2.INF:
				return _cast(ctx, "mirror", d._walkable(d.door - (out - d.door)), "mirror laid away from the door", {"to": out})
	return ""


## The seconds before a crit a bramble wall is raised.
const WALL_LEAD := 8.0


## Where a mirror laid at `centre` sets its walkers down so that their way back to the door crosses it again: the farthest ground (a lattice of 2) whose
## way to the door steps onto the mirror, so each fold costs the walk from there and he is folded again, for as long as the mirror lies.
static func _loop_exit(ctx: Dictionary, centre: Vector2) -> Vector2:
	var d := ctx.d as FirstPrayersDirector
	var grid: WalkGrid = ctx.crowd._grid
	var best := Vector2.INF
	var far := 0.0
	var x := -16.0
	while x <= 16.0:
		var y := -16.0
		while y <= 16.0:
			var g := Vector2(x, y)
			if grid.walkable(g) and g.distance_to(d.door) > far and g.distance_to(centre) >= MirrorfoldFx.MIN_APART + 0.5 and not Walls.outside(g) \
					and _crosses(grid.path(g, d.door), g, centre):
				best = g
				far = g.distance_to(d.door)
			y += 2.0
		x += 2.0
	return best


## The way `way` from `from` steps onto the mirror at `centre`.
static func _crosses(way: PackedVector2Array, from: Vector2, centre: Vector2) -> bool:
	if way.is_empty():
		return false
	var at := from
	for step in way:
		var n := maxi(1, int(at.distance_to(step) / 0.25))
		for i in n + 1:
			if MirrorfoldFx.on_mirror(centre, at.lerp(step, float(i) / float(n))):
				return true
		at = step
	return false


## Where a mirror's way out is laid: ground 12-15 from the door, in the direction most away from the poor, clear of the walkers' road.
static func _mirror_exit(_bc, ctx: Dictionary) -> Vector2:
	var d := ctx.d as FirstPrayersDirector
	var away := (d.door - d.poor_spot).normalized()
	var best := Vector2.INF
	for k in 8:
		var dir := away.rotated(float(k) * TAU / 8.0)
		var spot := d._walkable(d.door + dir * 13.0)
		if spot.distance_to(d.door) > 10.0 and spot.distance_to(d.poor_spot) > 6.0 and ctx.crowd._grid.walkable(spot):
			return spot
	return best


# --- Decree: Leaving Is Prohibited and The Bell Lies ---

static func act_decree(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FirstPrayersDirector
	var crowd: Crowd = ctx.crowd
	var tl := d.timeline.elapsed()
	# ALL IS WELL (F5): rung BELL_LEAD seconds before the next crit (a walker's arrival or a prayer's end), it lies through the walker's going in and
	# his coming out (32 s), and stands the line down on the spot; and with the bell free, for a report on the run.
	if _ready(bc, ctx, "belllies") and not crowd.is_bell_lying():
		if crit_in(bc, ctx) <= BELL_LEAD or not _runners(d).is_empty():
			return _cast(ctx, "belllies", d.door, "the bell lies: all is well", {"mode": "well"})
	# A window that came due in the lie forms the moment it ends: Leaving Is Prohibited on the ones who would line it (the clergy at the
	# Temple, for the priests) as the lie ends keeps them off the door until it has closed.
	if _ready(bc, ctx, "noleave") and crowd.is_bell_lying() and crowd.lie_left() <= 4.0 and not d._late.is_empty():
		var late: Array[Person] = (d._late[0].pool as Callable).call()
		late.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(d.door) < b.ground_pos.distance_to(d.door))
		if not late.is_empty():
			return _cast(ctx, "noleave", late[0].ground_pos, "leaving is prohibited: the Faithful who would line the door")
	# Leaving Is Prohibited pins the Faithful where they stand -- the clergy at the Temple before the priests are due, else a Faithful or two
	# on their way to the door -- so the line comes late, if at all.
	if _ready(bc, ctx, "noleave") and _idle(ctx) > FILL_AFTER - 14.0 and (not crowd.is_bell_lying() or crowd.lie_left() > 22.0 or d._late.is_empty()):
		var pin := _pin_at(ctx)
		if pin != Vector2.INF:
			return _cast(ctx, "noleave", pin, "leaving is prohibited: pin the Faithful")
	return ""


## The seconds before a crit the bell is rung: its 45 s then cover a walker going in and his prayer's end (32 s on).
const BELL_LEAD := 13.0


## Where Leaving Is Prohibited would pin the most Faithful and none of the poor (within its radius), the clergy first; Vector2.INF for none.
static func _pin_at(ctx: Dictionary) -> Vector2:
	var d := ctx.d as FirstPrayersDirector
	var best := Vector2.INF
	var most := 0
	for f in _faithful(d):
		var n := 0
		var clear := true
		for g in d.grieving:
			if MissionDirector._alive(g) and g.ground_pos.distance_to(f.ground_pos) <= NoLeaveFx.RADIUS + 0.5:
				clear = false
		for o in _faithful(d):
			n += 1 if o.ground_pos.distance_to(f.ground_pos) <= NoLeaveFx.RADIUS else 0
		if clear and n > most:
			best = f.ground_pos
			most = n
	return best


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
	# Never idle past the clock: Discord at the Temple's door, where only the clergy loiter, or a Faithful sent a way off from the shrine.
	if _idle(ctx) > FILL_AFTER - 2.0 and crit > 16.0 and not market_open and walker == null:
		if _ready(bc, ctx, "discord"):
			return _cast(ctx, "discord", d.temple_door, "discord at the Temple's door")
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
