extends RefCounted
## The scripted player's per-type policies for The Lost Lamb (god T1R, spec 9 and 7.3): one act_<type>(bc, ctx) for each god type, playing only that type's
## two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the behaviour_check
## script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd.
##
## The shape of the night: he hides at the north-east fountain until the god leads him (a whisper, a Wisp), a startle near him, or 1:00 --
## then he runs for the west gate on his road (the grid's way to `exit_at`) at his slow pace, and everything that would see him (SIGHT
## 2.5) must be cleared from it or kept off it: two patrols, the watch at the gate (an inner and an outer post, each judged on sight
## before the way out) and, from 2:30, the searchers. A player works the soldiers ahead of him in the order he meets them.

## The types whose policy is written.
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## A patrol is worked when its beat passes this near his road (SIGHT 2.5 and a margin for its ring).
const BEAT_NEAR := 3.2
## A killing blow lands this far (plus its radius) from him at the least, or it takes him too.
const BLOW_GAP := 0.4
## Pestilence is cast this far from him at the least: the plague can spread to him (rulings D13, spec Problem 11).
const PLAGUE_CLEAR := 8.0
## His seizer is struck when he trails him by more than the blow's radius plus this.
const SEIZER_GAP := 0.4
## Death Mark: how far a citizen may be from him to be marked for the run (the mark dies 10 s on, slowed, within BOLT_REACH of him).
const MARK_NEAR := 2.0



# --- Reading the night ---

## god_t1.gd, which preloads this file (so this file loads it when it needs it): its policy pieces.
static func _pieces() -> GDScript:
	return load("res://tools/dev/routes/god_t1.gd")


## The director when the night is on: he is alive and not out; null otherwise.
static func _lamb(ctx: Dictionary, bc = null) -> LostLambDirector:
	var d := ctx.d as LostLambDirector
	if d == null or not WarningDirector._alive(d.charge) or d.escaped or d.taken:
		return null
	# A seizure is reported where it falls, and by whom (the report lines come every ten seconds).
	var memo: Dictionary = ctx.memo
	if d.seizures != int(memo.get("seizures", 0)):
		memo.seizures = d.seizures
		if bc != null and WarningDirector._alive(d.seizer):
			print("BEHAVIOUR lamb seized by %s at (%.1f, %.1f), he at (%.1f, %.1f), clock %.1f" % [bc._lamb_who(d, d.seizer),
				(d.seizer as Person).ground_pos.x, (d.seizer as Person).ground_pos.y, d.charge.ground_pos.x, d.charge.ground_pos.y, d._clock])
	return d


## His road: the grid's way from where he stands to the way out, kept a second (he walks slowly).
static func _road(ctx: Dictionary, d: LostLambDirector) -> PackedVector2Array:
	var memo: Dictionary = ctx.memo
	var at: Vector2 = d.charge.ground_pos
	if memo.has("road") and d._clock - float(memo.road_at) < 1.0 and at.distance_to(memo.road_from) < 1.0:
		return memo.road
	var road := PackedVector2Array([at])
	road.append_array((ctx.crowd as Crowd)._grid.path(at, d.exit_at))
	memo.road = road
	memo.road_at = d._clock
	memo.road_from = at
	return road


## How near `p` lies to the road (x) and how far along it, from him, that nearest point is (y).
static func _probe(road: PackedVector2Array, p: Vector2) -> Vector2:
	if road.size() == 1:
		return Vector2(p.distance_to(road[0]), 0.0)
	var best := INF
	var along := 0.0
	var run := 0.0
	for i in range(1, road.size()):
		var a := road[i - 1]
		var b := road[i]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var g := p.distance_to(q)
		if g < best:
			best = g
			along = run + a.distance_to(q)
		run += a.distance_to(b)
	return Vector2(best, along)


## The living soldiers of an Array (the squads are untyped: any may be a freed body).
static func _living(squad: Array) -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in squad:
		if WarningDirector._alive(v) and not (v as Person).inside:
			out.append(v as Person)
	return out


## The soldiers worth working now, in the order he meets them: [{members, along, kind}]. A patrol is one whose beat meets his road; the
## watch's men and the searchers are each their own.
static func _squads(d: LostLambDirector, road: PackedVector2Array) -> Array:
	var out := []
	for k in d.patrols.size():
		var live := _living(d.patrols[k])
		if live.is_empty():
			continue
		var beat: PackedVector2Array = d.beats[k]
		var best := Vector2(INF, 0.0)
		var steps := int(beat[0].distance_to(beat[1]) / 0.5) + 1
		for i in steps + 1:
			var g := _probe(road, beat[0].lerp(beat[1], float(i) / float(steps)))
			if g.x < best.x:
				best = g
		if best.x <= BEAT_NEAR:
			out.append({"members": live, "along": best.y, "kind": "patrol"})
	for w in _living(d.watch):
		out.append({"members": [w] as Array[Person], "along": _probe(road, w.ground_pos).y, "kind": "watch"})
	for h in _living(d.hunters):
		out.append({"members": [h] as Array[Person], "along": _probe(road, h.ground_pos).y, "kind": "hunt"})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.along) < float(b.along))
	return out


## Where one blow of radius `r`, landing `delay` s after the cast, takes the squad: the middle of where its men will be when all of them
## fall within r of it, else the first of them alone. {"at", "n"}; Vector2.INF for no members.
static func _blow_at(squad: Dictionary, r: float, delay: float) -> Dictionary:
	var pts: Array[Vector2] = []
	var mid := Vector2.ZERO
	for m: Person in squad.members:
		pts.append(_pieces().road_ahead(m, delay))
		mid += pts.back()
	if pts.is_empty():
		return {"at": Vector2.INF, "n": 0}
	mid /= float(pts.size())
	var tight := true
	for p in pts:
		tight = tight and p.distance_to(mid) <= r - 0.1
	return {"at": mid if tight else pts[0], "n": pts.size() if tight else 1}


## The first squad (in the order he meets them) a blow of radius `r` (landing after `delay`) can take without taking him: {"at", "squad"}, or
## an empty dictionary.
static func _first_blow(d: LostLambDirector, ctx: Dictionary, r: float, delay: float) -> Dictionary:
	var lamb := d.charge
	for sq: Dictionary in _squads(d, _road(ctx, d)):
		var blow := _blow_at(sq, r, delay)
		var at: Vector2 = blow.at
		if at != Vector2.INF and lamb.ground_pos.distance_to(at) > r + BLOW_GAP:
			return {"at": at, "squad": sq}
	return {}


## Whether his seizer trails far enough ahead of him for a blow of radius `r` to take only the seizer.
static func _seizer_clear(d: LostLambDirector, r: float) -> bool:
	return d.held and WarningDirector._alive(d.seizer) \
		and d.charge.ground_pos.distance_to((d.seizer as Person).ground_pos) > r + SEIZER_GAP


static func _ready(bc, ctx: Dictionary, key: String) -> bool:
	return bc._slot_ready(ctx.rules, ctx.slots, key)


static func _cast(ctx: Dictionary, key: String, at: Vector2, extra := {}) -> void:
	ctx.rules.cast(int(ctx.slots[key]), at, extra)
	ctx.memo.last_cast = (ctx.d as LostLambDirector)._clock


## A burnable building within `reach` of `from` (the nearest), or null: Ember's house for the run.
static func _house_near(ctx: Dictionary, from: Vector2, reach: float) -> Structure:
	var best: Structure = null
	for s in (ctx.crowd as Crowd)._env.structures():
		if not is_instance_valid(s) or s.destroyed or not FireManager.burns(s) or s.role == &"temple":
			continue
		var g: float = s.distance_to(from)
		if g <= reach and (best == null or g < best.distance_to(from)):
			best = s
	return best


# --- Ruin: Smite, Ember ---

## Ember a house beside him starts his run at once; Smite takes each patrol pair at its middle (both within 0.6), each watchman and each
## searcher in the order he meets them, and his seizer. Loud: the kills raise the town's alarm, and the rally takes the rest.
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	var lamb := d.charge
	if d.held and WarningDirector._alive(d.seizer):
		if _ready(bc, ctx, "smite") and _seizer_clear(d, SmiteFx.KILL_R):
			var s := d.seizer as Person
			_cast(ctx, "smite", _pieces().road_ahead(s, SmiteFx.T_STRIKE))
			return "smite his seizer"
		return ""
	if not d.bolting and not d.led and _ready(bc, ctx, "ember"):
		var house := _house_near(ctx, lamb.ground_pos, LostLambDirector.BOLT_REACH - 1.0)
		if house != null:
			_cast(ctx, "ember", house.center())
			return "ember a house beside him"
	if _ready(bc, ctx, "smite"):
		var blow := _first_blow(d, ctx, SmiteFx.KILL_R, SmiteFx.T_STRIKE)
		if not blow.is_empty():
			_cast(ctx, "smite", blow.at)
			return "smite %s (%d)" % [blow.squad.kind, (blow.squad.members as Array).size()]
	return ""


# --- Veil: Silent Doom, Blight ---

## Blight his fountain starts his run at once; Silent Doom takes each patrol pair at its middle, each watchman and each searcher in the order he
## meets them, and his seizer once he trails it clear of the Doom.
static func act_veil(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	if d.held and WarningDirector._alive(d.seizer):
		if _ready(bc, ctx, "doom") and _seizer_clear(d, SilentDoom.RADIUS):
			_cast(ctx, "doom", _pieces().road_ahead(d.seizer as Person, SilentDoom.T_STRIKE))
			return "doom his seizer"
		return ""
	if not d.bolting and not d.led and d.fountain != null and _ready(bc, ctx, "blight") and not d.fountain.blighted:
		_cast(ctx, "blight", d.fountain.center())
		return "blight his fountain"
	if _ready(bc, ctx, "doom"):
		var blow := _first_blow(d, ctx, SilentDoom.RADIUS, SilentDoom.T_STRIKE)
		if not blow.is_empty():
			_cast(ctx, "doom", blow.at)
			return "doom %s (%d)" % [blow.squad.kind, (blow.squad.members as Array).size()]
	return ""


# --- Death: Death Mark, Pestilence ---

## The citizen nearest him within MARK_NEAR (a lay one, out of doors, not marked): Death Mark's first victim, whose death starts his run.
static func _citizen_beside(d: LostLambDirector, crowd: Crowd) -> Person:
	var best: Person = null
	for p in crowd.citizens:
		if not WarningDirector._alive(p) or p == d.charge or p.inside or p.statuses.has(&"frail") or d.reserved.has(p):
			continue
		var g := p.ground_pos.distance_to(d.charge.ground_pos)
		if g <= MARK_NEAR and (best == null or g < best.ground_pos.distance_to(d.charge.ground_pos)):
			best = p
	return best


## Pestilence takes a squad whole (every one of its men within 1.2 of the aim) when the aim is PLAGUE_CLEAR or more from him; Death Mark
## takes one man at a time (it dies 10 s on): a watchman, a patrol's man, a searcher, his seizer; and a citizen marked beside him starts his run.
static func act_death(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	var lamb := d.charge
	var crowd: Crowd = ctx.crowd
	if d.held and WarningDirector._alive(d.seizer):
		if _ready(bc, ctx, "deathmark"):
			_cast(ctx, "deathmark", (d.seizer as Person).ground_pos)
			return "death mark his seizer"
		return ""
	var squads := _squads(d, _road(ctx, d))
	# The run: a citizen beside him marked, dying within reach of him in 10 s, starts it.
	if not d.bolting and not d.led and _ready(bc, ctx, "deathmark"):
		var one := _citizen_beside(d, crowd)
		if one != null:
			_cast(ctx, "deathmark", one.ground_pos)
			return "death mark a citizen beside him"
	if _ready(bc, ctx, "pestilence"):
		for sq: Dictionary in squads:
			if (sq.members as Array).size() < 2:
				continue  # one man is Death Mark's
			var mid := Vector2.ZERO
			for m: Person in sq.members:
				mid += m.ground_pos
			mid /= float((sq.members as Array).size())
			var victims := PestilenceFx.victims_at(crowd._field, mid)
			var whole := true
			for m: Person in sq.members:
				whole = whole and victims.has(m)
			if whole and not victims.has(lamb) and lamb.ground_pos.distance_to(mid) >= PLAGUE_CLEAR:
				_cast(ctx, "pestilence", mid)
				return "pestilence on a %s (%d)" % [sq.kind, (sq.members as Array).size()]
	if _ready(bc, ctx, "deathmark"):
		for sq: Dictionary in squads:
			var mark: Person = null
			for m: Person in sq.members:
				if m.ground_pos.distance_to(lamb.ground_pos) >= 2.0 and not m.statuses.has(&"frail"):
					mark = m
					break
			if mark != null:
				_cast(ctx, "deathmark", mark.ground_pos)
				return "death mark a %s" % sq.kind
	return ""


# --- Dominion: Mind Whisper, Discord ---

## Dominion: Discord a patrol that would see him on the road (a quarter-minute blind), Mind Whisper each watchman off his post in the half minute
## before he comes to the gate (blind while he walks to his spot and lingers, and a long walk back). He is never led: he bolts at 1:00. Before it,
## a Discord on patrol 1 is the work there is.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	var lamb := d.charge
	var memo: Dictionary = ctx.memo
	var road := _road(ctx, d)
	var speed := maxf(lamb.walk_speed, 0.3)
	if d.held and WarningDirector._alive(d.seizer):
		if _ready(bc, ctx, "discord"):
			_cast(ctx, "discord", (d.seizer as Person).ground_pos)
			return "discord his seizer"
		return ""
	var remaining := _length(road)
	# The watch: each man whispered off to the spot farthest from his road, when the rest of it takes him less than WATCH_LEAD seconds.
	if d.bolting and _ready(bc, ctx, "whisper") and remaining / speed <= WATCH_LEAD:
		for w in _living(d.watch):
			if w.mind == Person.Mind.WHISPERED or w.shaken() or w.held_by_god():
				continue
			var spot := _spot_off_road(d, road, w.ground_pos)
			_cast(ctx, "whisper", w.ground_pos, {"target": w, "to": spot})
			return "whisper a watchman to (%.1f, %.1f)" % [spot.x, spot.y]
	# A patrol that would see him: Discord on its middle.
	if _ready(bc, ctx, "discord") and (d.bolting or d._clock >= DISCORD_FILL_AT):
		for sq: Dictionary in _squads(d, road):
			if sq.kind != "patrol":
				continue
			var mid := Vector2.ZERO
			var tight := true
			for m: Person in sq.members:
				mid += m.ground_pos
			mid /= float((sq.members as Array).size())
			for m: Person in sq.members:
				tight = tight and m.ground_pos.distance_to(mid) <= DiscordFx.DISCORD_R - 0.2
			var near := _probe(road, mid)
			var meets := near.x <= DISCORD_NEAR and near.y / speed <= DISCORD_LEAD
			if tight and (meets or not d.bolting):
				_cast(ctx, "discord", mid)
				return "discord a patrol"
	# Between the strokes: a patrol's man whispered off his beat, so the stretch is not idle (and the patrol thinner).
	if _ready(bc, ctx, "whisper") and d._clock - float(memo.get("last_cast", 0.0)) >= WHISPER_FILL_GAP and remaining / speed > WATCH_LEAD:
		for sq: Dictionary in _squads(d, road):
			if sq.kind != "patrol":
				continue
			for m: Person in sq.members:
				if not m.shaken() and not m.held_by_god():
					var spot := _spot_off_road(d, road, m.ground_pos)
					_cast(ctx, "whisper", m.ground_pos, {"target": m, "to": spot})
					return "whisper a patrolman off his beat to (%.1f, %.1f)" % [spot.x, spot.y]
	return ""


## A walkable spot within Mind Whisper's reach of `from`, as far from his road as any of a few candidates (east, west and north of the gate).
static func _spot_off_road(d: LostLambDirector, road: PackedVector2Array, from: Vector2) -> Vector2:
	var best := d.guardhouse
	var far := -1.0
	for c in [d.guardhouse, d.gate_at + Vector2(-4.0, -3.0), d.gate_at + Vector2(-2.0, -7.0)]:
		var g := d._walkable(c)
		if from.distance_to(g) > MindWhisperFx.REACH - 0.5:
			g = d._walkable(from + (g - from).normalized() * (MindWhisperFx.REACH - 0.5))
		var off := _probe(road, g).x
		if off > far:
			far = off
			best = g
	return best


## Dominion: the watch is whispered off when the rest of his road takes him less than this (seconds); a patrol is Discorded when it comes within
## DISCORD_NEAR of his road and he reaches that place within DISCORD_LEAD s; before he bolts, a Discord on patrol 1 from DISCORD_FILL_AT.
const WATCH_LEAD := 24.0
const DISCORD_NEAR := 3.5
const DISCORD_LEAD := 9.0
const DISCORD_FILL_AT := 30.0
## Seconds without a cast after which Dominion whispers a patrolman off his beat.
const WHISPER_FILL_GAP := 28.0


# --- Passage: Thornwall, Mirrorfold ---

## The road's point `along` from the start of the polyline.
static func _at_along(road: PackedVector2Array, along: float) -> Vector2:
	var run := 0.0
	for i in range(1, road.size()):
		var seg := road[i - 1].distance_to(road[i])
		if run + seg >= along:
			return road[i - 1].move_toward(road[i], along - run)
		run += seg
	return road[road.size() - 1]


## The first `length` units of the road (at least its first point, so a probe has a segment to measure).
static func _prefix(road: PackedVector2Array, length: float) -> PackedVector2Array:
	var out := PackedVector2Array([road[0]])
	var run := 0.0
	for i in range(1, road.size()):
		var seg := road[i - 1].distance_to(road[i])
		if run + seg >= length:
			out.append(road[i - 1].move_toward(road[i], length - run))
			return out
		out.append(road[i])
		run += seg
	return out


## The whole road from his hiding place to the way out, made once.
static func _full_road(ctx: Dictionary, d: LostLambDirector) -> PackedVector2Array:
	var memo: Dictionary = ctx.memo
	if not memo.has("full"):
		var from := d._walkable(d.charge_start)
		var road := PackedVector2Array([from])
		road.append_array((ctx.crowd as Crowd)._grid.path(from, d.exit_at))
		memo.full = road
	return memo.full


static func _length(road: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, road.size()):
		total += road[i - 1].distance_to(road[i])
	return total


## How far along the road it first comes within `reach` of the gate (the watch's clock starts there), or -1 for never.
static func _zone_entry(d: LostLambDirector, road: PackedVector2Array, reach: float) -> float:
	var total := _length(road)
	var s := 0.0
	while s <= total:
		if _at_along(road, s).distance_to(d.gate_at) <= reach:
			return s
		s += 0.1
	return -1.0


## The lap (Passage): the mirror's way in lies across the whole road where it enters the zone by the gate (so he steps on it just after the
## watch's change clock has started there, unseen), and its way out back along the road, one lap of his walk behind the place he steps on it. The
## mirror lives 30 s: he is folded back at the start (the clock c0), walks home, is folded back again (the mirror still lives), walks home -- by
## then it is gone, two laps after c0: when the watch has changed (c0 + 30) and walked off his road, and before it walks back (c0 + 55). So a lap is
## half of the 30 s to the change plus the watch's time off the road (_watch_clears()). The fold sets him down where he stood on the way in,
## relative to the way out. {"in", "out", "touch"} (touch: how far along the whole road he steps onto the way in), or an empty dictionary when
## the road does not reach the zone.
static func _lap(ctx: Dictionary, d: LostLambDirector) -> Dictionary:
	var road := _full_road(ctx, d)
	var entry := _zone_entry(d, road, LAP_ENTRY)
	if entry < 0.0:
		return {}
	var centre := _at_along(road, entry + 1.6)
	var touch := entry
	var s := 0.0
	while s <= entry + 4.0:
		if MirrorfoldFx.on_mirror(centre, _at_along(road, s)):
			touch = s
			break
		s += 0.1
	var speed := maxf(d.charge.walk_speed, 0.3)
	var offset := _at_along(road, touch) - centre
	var lap := (EscortDirector.WATCH_CHANGE + _watch_clears(ctx, d, road, entry)) * 0.5
	return {"in": centre, "out": _at_along(road, maxf(touch - speed * lap, 0.0)) - offset, "touch": touch}


## Seconds after the change begins until the last watchman is off the rest of his road (from the place `from` along it): he walks his way to the
## guardhouse at WATCH_PACE and is clear once he is farther than WATCH_CLEAR from it for good.
static func _watch_clears(ctx: Dictionary, d: LostLambDirector, road: PackedVector2Array, from: float) -> float:
	var rest := PackedVector2Array([_at_along(road, from)])
	var run := 0.0
	for i in range(1, road.size()):
		var seg := road[i - 1].distance_to(road[i])
		if run + seg > from:
			rest.append(road[i])
		run += seg
	var worst := 0.0
	for post: Vector2 in d.watch_posts:
		var way := PackedVector2Array([post])
		way.append_array((ctx.crowd as Crowd)._grid.path(post, d.guardhouse))
		var last := 0.0
		var walked := 0.0
		for i in range(1, way.size()):
			walked += way[i - 1].distance_to(way[i])
			if _probe(rest, way[i]).x < WATCH_CLEAR:
				last = walked
		worst = maxf(worst, last / WATCH_PACE)
	return worst + WATCH_SLACK


## Where the first mirror sets a patrol down: Aldermere's north-west corner (FLING_TO, which has no way back to the streets); another town's, the
## corner of its old town farthest from the gate.
static func _far_corner(d: LostLambDirector) -> Vector2:
	if City.current().id() == &"aldermere":
		return d._walkable(FLING_TO)
	var town := City.current().town().grow(-1.0)
	var best := town.position
	for c in [town.position, Vector2(town.end.x, town.position.y), town.end, Vector2(town.position.x, town.end.y)]:
		if c.distance_to(d.gate_at) > best.distance_to(d.gate_at):
			best = c
	return d._walkable(best)


## Where a Thornwall lies across the patrol's beat, clear of his road (a wall across it would hold him): west of where the beat meets the road, else
## just ahead of the patrol where it walks, else the beat's middle; Vector2.INF when none keeps clear.
static func _wall_spot(d: LostLambDirector, road: PackedVector2Array, sq: Dictionary) -> Vector2:
	var lead: Person = sq.members[0]
	var cands: Array[Vector2] = [_at_along(road, float(sq.along)) + Vector2(-THORN_BACK, 0.0)]
	for k in d.patrols.size():
		if (d.patrols[k] as Array).has(lead):
			var beat: PackedVector2Array = d.beats[k]
			var heading := (beat[d._beat_at[k]] - lead.ground_pos).normalized()
			cands.append(lead.ground_pos + heading * 2.5)
			cands.append(beat[0].lerp(beat[1], 0.5))
	for c in cands:
		var touches := false
		for k in 7:
			touches = touches or _probe(road, c + Vector2.DOWN * (float(k - 3) * 0.5)).x < THORN_OFF
		if not touches:
			return c
	return Vector2.INF


## Where the first mirror lies: just ahead of the patrol that walks across his road, on its beat, so that the patrol steps onto it within a few
## seconds (it is set down in the far corner, which has no road back). Vector2.INF when no patrol's beat meets his road.
static func _fling_at(d: LostLambDirector, road: PackedVector2Array) -> Vector2:
	var best := Vector2.INF
	var near := INF
	for k in d.patrols.size():
		var live := _living(d.patrols[k])
		if live.is_empty():
			continue
		var beat: PackedVector2Array = d.beats[k]
		var meets := INF
		var cross := beat[0]
		var len := maxf(beat[0].distance_to(beat[1]), 0.1)
		for i in int(len / 0.5) + 2:
			var q := beat[0].lerp(beat[1], minf(float(i) * 0.5 / len, 1.0))
			var g := _probe(road, q).x
			if g < meets:
				meets = g
				cross = q
		if meets > BEAT_NEAR or meets >= near:
			continue
		var lead := live[0]
		var to: Vector2 = beat[d._beat_at[k]]
		var heading := (to - lead.ground_pos).normalized()
		var ahead := lead.ground_pos + heading * FLING_AHEAD
		if lead.ground_pos.distance_to(to) < FLING_AHEAD + 1.0:
			ahead = to - heading * (FLING_AHEAD * 0.5)
		near = meets
		# Never on his road (he would be set down in the far corner himself): then the beat's middle, west of where it meets the road.
		best = ahead if _probe(road, ahead).x >= FLING_OFF else cross + Vector2(-FLING_BACK, 0.0)
	return best


## Passage: the lap, a first mirror that flings patrol 1 away, and a Thornwall across its beat. Bolting, he runs the road; as he nears the
## zone by the gate a mirror lays its way in across the road there (the clock starts when he comes near) and its way out back along the road,
## so he is folded back and walks the road again -- home when the watch has changed.
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	var lamb := d.charge
	var memo: Dictionary = ctx.memo
	var road := _road(ctx, d)
	var speed := maxf(lamb.walk_speed, 0.3)
	var mirror_ready := _ready(bc, ctx, "mirror")
	if d.bolting and mirror_ready and float(memo.get("mirror_until", -1.0)) < d._clock:
		var lap := _lap(ctx, d)
		if not lap.is_empty():
			var full := _full_road(ctx, d)
			var to_touch := float(lap.touch) - _probe(full, lamb.ground_pos).y
			if to_touch / speed <= LAP_LEAD and to_touch > 0.5:
				_cast(ctx, "mirror", lap["in"], {"to": lap["out"]})
				memo.mirror_until = d._clock + MirrorfoldFx.MIRROR_TIME
				return "mirror lap: in at (%.1f, %.1f), out at (%.1f, %.1f)" % [lap["in"].x, lap["in"].y, lap["out"].x, lap["out"].y]
	if mirror_ready and d._clock >= FLING_AT and not memo.get("flung", false) and not d.bolting:
		var at := _fling_at(d, road)
		if at != Vector2.INF:
			_cast(ctx, "mirror", at, {"to": _far_corner(d)})
			memo.flung = true
			memo.mirror_until = d._clock + MirrorfoldFx.MIRROR_TIME
			return "mirror across the patrol's beat at (%.1f, %.1f): flung to the far corner" % [at.x, at.y]
	if _ready(bc, ctx, "thorns") and d._clock >= THORN_AT:
		var full := _full_road(ctx, d)
		for sq: Dictionary in _squads(d, full):
			if sq.kind != "patrol":
				continue
			var wall := _wall_spot(d, full, sq)
			if wall != Vector2.INF:
				_cast(ctx, "thorns", wall, {"dir": Vector2.DOWN})
				return "thornwall across the patrol's beat at (%.1f, %.1f)" % [wall.x, wall.y]
	return ""


## The lap's numbers: the watch walks WATCH_PACE units a second off the road once the change begins, and is clear WATCH_SLACK s after it is more than
## WATCH_CLEAR from the rest of his road for good; the zone's reach where the clock starts (units from the gate), LAP_ENTRY; and how many seconds
## before he steps on the way in the mirror is laid, LAP_LEAD.
const WATCH_PACE := 1.2
const WATCH_CLEAR := 3.2
const WATCH_SLACK := 0.5
const LAP_ENTRY := 4.3
const LAP_LEAD := 3.0
## The first mirror: laid this far west of where a patrol's beat meets his road, from this second, flinging whoever steps on it to the far corner.
const FLING_AT := 30.0
## ...ahead of the patrol, on its beat, this far.
const FLING_AHEAD := 3.5
## ...and never nearer his road than this; else this far west of where the beat meets it.
const FLING_OFF := 3.8
const FLING_BACK := 5.0
const FLING_TO := Vector2(-12.0, -12.0)
## Thornwall: laid this far west of where a patrol's beat meets his road, from this second -- after the first mirror has gone, or its wall
## would hold the patrol back from the mirror.
const THORN_BACK := 3.5
## ...and never nearer his road than this.
const THORN_OFF := 1.0
const THORN_AT := 61.0


# --- Decree: Leaving Is Prohibited, The Bell Lies ---

## Decree: Leaving Is Prohibited holds a patrol where it stands (a circle of 3, fifteen seconds in twenty), re-laid on it each time it is
## ready, so the patrol that walks his road crawls; The Bell Lies calls the guard, once he nears the gate, to the middle of the watch: it and the
## soldiers nearest it run there and see nothing for 20 s. He bolts at 1:00 by himself.
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	var lamb := d.charge
	var road := _road(ctx, d)
	var speed := maxf(lamb.walk_speed, 0.3)
	if d.held and WarningDirector._alive(d.seizer):
		if _ready(bc, ctx, "belllies"):
			var s := d.seizer as Person
			_cast(ctx, "belllies", s.ground_pos + Vector2(3.0, 0.0), {"mode": "guard"})
			return "call the guard away from his seizer"
		return ""
	var total := 0.0
	for i in range(1, road.size()):
		total += road[i - 1].distance_to(road[i])
	if d.bolting and _ready(bc, ctx, "belllies") and total / speed <= BELL_LEAD and total > 1.0:
		# To the middle of the watch: it is then among the twelve nearest soldiers to the click, whatever else the town has about.
		var mid := Vector2.ZERO
		var live := _living(d.watch)
		for w in live:
			mid += w.ground_pos
		mid = mid / float(live.size()) if not live.is_empty() else d.guardhouse
		_cast(ctx, "belllies", mid, {"mode": "guard"})
		return "call the guard to the gate"
	if _ready(bc, ctx, "noleave"):
		# The patrols that meet his road first, then any (a patrol off his road is pinned all the same: it is work, and it holds it there).
		var squads := _squads(d, road)
		for k in d.patrols.size():
			var live := _living(d.patrols[k])
			if not live.is_empty():
				squads.append({"members": live, "along": INF, "kind": "patrol"})
		# The ground he walks while the law holds (HOLD_TIME + T_SEAL): the circle binds whoever walks into it, and he must not.
		var walk := _prefix(road, maxf(NoLeaveFx.HOLD_TIME + NoLeaveFx.T_SEAL - d.bolt_left(), 0.0) * speed)
		for sq: Dictionary in squads:
			if sq.kind != "patrol":
				continue
			var mid := Vector2.ZERO
			for m: Person in sq.members:
				mid += m.ground_pos
			mid /= float((sq.members as Array).size())
			var tight := true
			for m: Person in sq.members:
				tight = tight and m.ground_pos.distance_to(mid) <= NoLeaveFx.RADIUS - 0.5
			if tight and _probe(walk, mid).x >= NoLeaveFx.RADIUS + LIP_MARGIN:
				_cast(ctx, "noleave", mid)
				return "leaving is prohibited on a patrol"
	return ""


## The Bell Lies' guard lasts 20 s: it is called when the rest of his road takes him less than this (seconds) to walk.
const BELL_LEAD := 16.0
## Leaving Is Prohibited is laid only where its circle keeps this far off his road (it would hold him too).
const LIP_MARGIN := 1.0


## The numbers a report line prints: where he is, who holds him, where the soldiers of each patrol and the watch stand.
static func state(bc, ctx: Dictionary) -> String:
	var d := ctx.d as LostLambDirector
	if d == null or not WarningDirector._alive(d.charge):
		return ""
	var gap := d.charge.ground_pos.distance_to(d.gate_at)
	var who := ""
	if d.held and WarningDirector._alive(d.seizer):
		who = " seizer=%s" % bc._lamb_who(d, d.seizer)
	var seen := ""
	for k in d.patrols.size():
		for p in _living(d.patrols[k]):
			seen += " p%d(%.0f,%.0f)" % [k + 1, p.ground_pos.x, p.ground_pos.y]
	for p in _living(d.watch):
		seen += " w(%.0f,%.0f)" % [p.ground_pos.x, p.ground_pos.y]
	return "he=(%.1f,%.1f) held=%s%s seizures=%d gate=%.1f watch_away=%s bolting=%s led=%s%s" % [d.charge.ground_pos.x, d.charge.ground_pos.y,
		d.held, who, d.seizures, gap, d.watch_away, d.bolting, d.led, seen]
