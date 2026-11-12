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
## His seizer is struck when he trails him by more than the blow's radius plus this.
const SEIZER_GAP := 0.4
## Death Mark: how far a citizen may be from him to be marked for the run (the mark dies 10 s on, slowed, within BOLT_REACH of him).
const MARK_NEAR := 2.0
## Death: his run is started once no more than RUN_PATROLS patrolmen live, or at RUN_AT; a zombie rises only this far from him or more.
const RUN_PATROLS := 2
const RUN_AT := 40.0
const ZOMBIE_CLEAR := RaiseTheDeadFx.SEEK



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


## The negative case of the gate (D22): `--startle-only` (gate.sh --extra) plays Ruin's Ember or Veil's Blight at 0:00 and then casts nothing; the
## night must be lost, so that a short night is won by the play and not by the bolt alone.
static func _startle_only() -> bool:
	return "--startle-only" in OS.get_cmdline_user_args()


## The middle of where these soldiers stand.
static func _mid(members: Array) -> Vector2:
	var mid := Vector2.ZERO
	for m: Person in members:
		mid += m.ground_pos
	return mid / float(maxi(members.size(), 1))


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
		if _startle_only():
			return ""
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
	if _ready(bc, ctx, "smite") and not _startle_only():
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
		if _startle_only():
			return ""
		if _ready(bc, ctx, "doom") and _seizer_clear(d, SilentDoom.RADIUS):
			_cast(ctx, "doom", _pieces().road_ahead(d.seizer as Person, SilentDoom.T_STRIKE))
			return "doom his seizer"
		return ""
	if not d.bolting and not d.led and d.fountain != null and _ready(bc, ctx, "blight") and not d.fountain.blighted:
		_cast(ctx, "blight", d.fountain.center())
		return "blight his fountain"
	if _ready(bc, ctx, "doom") and not _startle_only():
		var blow := _first_blow(d, ctx, SilentDoom.RADIUS, SilentDoom.T_STRIKE)
		if not blow.is_empty():
			_cast(ctx, "doom", blow.at)
			return "doom %s (%d)" % [blow.squad.kind, (blow.squad.members as Array).size()]
	return ""


# --- Death: Death Mark, Raise the Dead ---

## The citizen nearest him within MARK_NEAR (a lay one, out of doors, not marked): Death Mark's victim whose death starts his run.
static func _citizen_beside(d: LostLambDirector, crowd: Crowd) -> Person:
	var best: Person = null
	for p in crowd.citizens:
		if not WarningDirector._alive(p) or p == d.charge or p.inside or p.statuses.has(&"frail") or d.reserved.has(p):
			continue
		var g := p.ground_pos.distance_to(d.charge.ground_pos)
		if g <= MARK_NEAR and (best == null or g < best.ground_pos.distance_to(d.charge.ground_pos)):
			best = p
	return best


## Death works the soldiers ahead of him in the order he meets them. Death Mark takes one man at a time (he dies 10 s on): a patrol's man, a
## watchman, a searcher, his seizer. Raise the Dead's ZOMBIE gets up from a soldier's body where he fell, among his own, when he is beyond its
## sight (ZOMBIE_CLEAR): it hunts the nearest, the soldiers at their posts are drawn to it, and whoever it kills gets up too. His run is started
## by a citizen marked beside him once the patrols are thinned (RUN_PATROLS), or at RUN_AT.
static func act_death(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	var lamb := d.charge
	var crowd: Crowd = ctx.crowd
	if d.held and WarningDirector._alive(d.seizer):
		if _ready(bc, ctx, "deathmark") and not (d.seizer as Person).statuses.has(&"frail"):
			_cast(ctx, "deathmark", (d.seizer as Person).ground_pos)
			return "death mark his seizer"
		return ""
	if _ready(bc, ctx, "raise"):
		var body := _zombie_body(d, crowd)
		if body != Vector2.INF:
			_cast(ctx, "raise", body, {"mode": "zombie"})
			return "raise a zombie among the soldiers (%.1f, %.1f)" % [body.x, body.y]
	var squads := _squads(d, _road(ctx, d))
	if not d.bolting and not d.led and _ready(bc, ctx, "deathmark") and (_patrolmen(d) <= RUN_PATROLS or d._clock >= RUN_AT):
		var one := _citizen_beside(d, crowd)
		if one != null:
			_cast(ctx, "deathmark", one.ground_pos)
			return "death mark a citizen beside him"
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


## The living patrolmen.
static func _patrolmen(d: LostLambDirector) -> int:
	var n := 0
	for k in d.patrols.size():
		n += _living(d.patrols[k]).size()
	return n


## A soldier's body a zombie may rise from: beyond ZOMBIE_CLEAR of him, with a living soldier nearer it than any citizen (its first prey is
## one of them). Its place, or Vector2.INF.
static func _zombie_body(d: LostLambDirector, crowd: Crowd) -> Vector2:
	if crowd.remains == null:
		return Vector2.INF
	for r in crowd.remains.all():
		if not r.soldier or r.pos.distance_to(d.charge.ground_pos) < ZOMBIE_CLEAR:
			continue
		var near := DominionParts.near(crowd._field, r.pos, RaiseTheDeadFx.SEEK, 1)
		if not near.is_empty() and near[0].soldier:
			return r.pos
	return Vector2.INF


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
			var mid := _mid(sq.members)
			var tight := true
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


# --- Passage: Skylift, Windfall ---

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


static func _length(road: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, road.size()):
		total += road[i - 1].distance_to(road[i])
	return total


## Where Passage's beam sets the soldiers off the way out down: Aldermere's north-west corner (FLING_TO, which has no way back to the streets);
## another town's, the corner of its old town farthest from the gate.
static func _far_corner(d: LostLambDirector) -> Vector2:
	if City.current().id() == &"aldermere":
		return d._walkable(FLING_TO)
	var town := City.current().town().grow(-1.0)
	var best := town.position
	for c in [town.position, Vector2(town.end.x, town.position.y), town.end, Vector2(town.position.x, town.end.y)]:
		if c.distance_to(d.gate_at) > best.distance_to(d.gate_at):
			best = c
	return d._walkable(best)


## Passage: Skylift clears the way out, then lifts him through it. Each soldier who would see him at the way out (watching, within SIGHT + LIFT_MARGIN
## of it: the watch's two posts both lie within one beam of their middle) is taken by the beam and set down in the far corner (Aldermere's has no
## way back to the streets, D25); with the way out clear, the beam takes him where he stands and sets him down on it, and he is out. Seized, his
## seizer is crushed by a Windfall of stone laid across the seizer's way, clear of him: he is free again, and the beam takes him on.
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := _lamb(ctx, bc)
	if d == null or d.charge.inside:
		return ""
	var lamb := d.charge
	if d.held and WarningDirector._alive(d.seizer):
		var s := d.seizer as Person
		if _ready(bc, ctx, "windfall"):
			# Where the seizer and he will stand when it lands: the line across the seizer's way there, none of its heaps within reach of the boy.
			var at: Vector2 = _pieces().road_ahead(s, WindfallFx.T_DROP)
			var his: Vector2 = _pieces().road_ahead(lamb, WindfallFx.T_DROP)
			var way := (at - his).normalized() if at.distance_to(his) > 0.05 else Vector2.RIGHT
			var clear := true
			for r in WindfallFx.rects(at, way.orthogonal()):
				clear = clear and r.get_center().distance_to(his) > WindfallFx.HIT_R + CRUSH_ROOM
			if clear:
				_cast(ctx, "windfall", at, {"dir": way.orthogonal(), "mode": "stone"})
				return "windfall on his seizer at (%.1f, %.1f)" % [at.x, at.y]
		return ""
	if not _ready(bc, ctx, "skylift"):
		return ""
	var eyes := _eyes_on_exit(d)
	if not eyes.is_empty():
		var at := _lift_aim(eyes)
		_cast(ctx, "skylift", at, {"to": _far_corner(d)})
		return "skylift %d soldier(s) off the way out at (%.1f, %.1f) to the far corner" % [SkyliftFx.lifted_at(ctx.crowd._field, at).size(), at.x, at.y]
	var from: Vector2 = _pieces().road_ahead(lamb, SkyliftFx.T_TAKE) if lamb.has_goal() else lamb.ground_pos
	_cast(ctx, "skylift", from, {"to": d.exit_at})
	return "skylift him from (%.1f, %.1f) onto the way out" % [from.x, from.y]


## The soldiers watching for him who stand within SIGHT + LIFT_MARGIN of the way out (they would see him set down there), the nearest it first.
static func _eyes_on_exit(d: LostLambDirector) -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in d._watchers():
		if d._watching(v) and (v as Person).ground_pos.distance_to(d.exit_at) <= EscortDirector.SIGHT + LIFT_MARGIN:
			out.append(v as Person)
	out.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(d.exit_at) < b.ground_pos.distance_to(d.exit_at))
	return out


## Where one beam takes the most of `eyes` (where each will stand when it takes): their middle when all lie within its radius of it (less a margin
## for their shifting on post), else the nearest the way out alone.
static func _lift_aim(eyes: Array[Person]) -> Vector2:
	var pts: Array[Vector2] = []
	var mid := Vector2.ZERO
	for e in eyes:
		pts.append(_pieces().road_ahead(e, SkyliftFx.T_TAKE))
		mid += pts.back()
	mid /= float(pts.size())
	for p in pts:
		if p.distance_to(mid) > SkyliftFx.RADIUS - 0.4:
			return pts[0]
	return mid


## Passage: a soldier this much beyond SIGHT of the way out is lifted off it too (he shifts about his post); a seizer is crushed only when every
## heap of the line lands at least this much beyond its blow's reach of the boy, else the policy waits a look.
const LIFT_MARGIN := 0.5
const CRUSH_ROOM := 0.1
## Where the beam sets the soldiers lifted off the way out down: Aldermere's north-west pocket.
const FLING_TO := Vector2(-12.0, -12.0)


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
	var total := _length(road)
	if d.bolting and _ready(bc, ctx, "belllies") and total / speed <= BELL_LEAD and total > 1.0:
		# To the middle of the watch: it is then among the twelve nearest soldiers to the click, whatever else the town has about.
		var live := _living(d.watch)
		var mid := _mid(live) if not live.is_empty() else d.guardhouse
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
			var mid := _mid(sq.members)
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
