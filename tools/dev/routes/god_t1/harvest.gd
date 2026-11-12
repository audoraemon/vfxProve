extends RefCounted
## The scripted player's per-type policies for Spoiled Harvest (god T1R, spec 6.7): one act_<type>(bc, ctx) for each god type, playing only that
## type's two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the
## behaviour_check script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd. Each looks the way a player does:
## the granary whose turn it is, its watchmen, its carter -- and casts at most one power a look.
##
## The six routes: Ruin Smites the watchmen and Embers the granary (A's, with Smite); Death marks the watchmen so both are gone when
## Pestilence takes the carter (H2); Veil dooms the watchmen and Blights the full granary (H3); Passage Skylifts the carter out beyond the
## wall (H1); Decree has no route with Leaving and Breathing Is Prohibited (act_decree()); Dominion whispers him out of the
## gate a step at a time (H1).

## The types whose policy is written.
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## Ruin and Veil clear a granary's watchmen when its grain is due within this many seconds (A's HARVEST_PRE: sooner, the relief walks in
## before the fire has burned its 10 s; Veil's Blight needs them gone at the grain, 30 s of relief after the first).
const CLEAR_PRE := 20.0
## Death starts marking the watchmen when Pestilence is ready within this many seconds (two marks, 20 s apart, the second falling 10 s after
## its cast: 20 + 10 = 30), and counts a marked watchman as gone with this much of his fuse left.
const DEATH_LEAD := 31.0
const MARK_GONE := 3.0
## Passage: how far from where the beam takes him a carter is set down, at the least and the most (the nearest ground out of the walls).
const EXIT_MIN := 1.0
const EXIT_MAX := 26.0
## Passage: how many seconds of a hauling carter's road ahead a Windfall of stone is laid across it (beyond its crush when it lands).
const WALL_LEAD := 4.0
## Dominion: how far ahead along his road a carter is whispered (Mind Whisper's REACH is 10).
const WHISPER_STEP := 9.0


# --- Reading the night ---------------------------------------------------------------------------------------------------

## Whether the power `key` can be cast now.
static func _ready(bc, ctx: Dictionary, key: String) -> bool:
	return bc._slot_ready(ctx.rules, ctx.slots, key)


## Seconds until the power `key` is ready (its cooldown), INF when it is not in the kit.
static func _cd(ctx: Dictionary, key: String) -> float:
	return ctx.rules.cooldown_left(int(ctx.slots[key])) if ctx.slots.has(key) else INF


## The granaries still to spoil, the soonest to fall first: those with their grain in, fewest loads first, then those waiting, soonest grain first.
static func _order(d: HarvestDirector) -> Array[Structure]:
	var out: Array[Structure] = []
	for s in d.targets:
		if not d.razed(s) and is_instance_valid(s) and d.has_grain(s):
			out.append(s)
	out.sort_custom(func(a: Structure, b: Structure) -> bool: return int(d.loads[a]) < int(d.loads[b]))
	var waiting: Array[Structure] = []
	for s in d.targets:
		if not d.razed(s) and is_instance_valid(s) and not d.has_grain(s):
			waiting.append(s)
	waiting.sort_custom(func(a: Structure, b: Structure) -> bool: return d.grain_left(a) < d.grain_left(b))
	out.append_array(waiting)
	return out


## The carter of `s`, alive and out of doors, or null (before he sets out, after he dies).
static func _carter(d: HarvestDirector, s: Structure) -> Person:
	for c: Variant in d.carters.get(s, []):
		if HarvestDirector._alive(c) and not (c as Person).inside:
			return c as Person
	return null


## The first granary still to spoil whose carter is out, with the carter.
static func _target(d: HarvestDirector) -> Dictionary:
	for s in _order(d):
		var c := _carter(d, s)
		if c != null:
			return {"s": s, "c": c}
	return {}


static func _name(d: HarvestDirector, s: Structure) -> String:
	return String(d.store_names[d.targets.find(s)])


## The carter is standing at his door, not walking anywhere.
static func _at_door(d: HarvestDirector, s: Structure, c: Person) -> bool:
	return c.ground_pos.distance_to(d.doors[s]) <= 1.0 and not d._hauling.has(c.get_instance_id())


## The shared policy pieces (god_t1.gd preloads this file, so it is loaded when wanted).
static func _god() -> GDScript:
	return load("res://tools/dev/routes/god_t1.gd")


## Ground beyond the wall where Skylift sets a carter taken at `from` down: the nearest walkable spot out of the walls, EXIT_MIN to EXIT_MAX
## away round the compass. Vector2.INF for none.
static func _exit_spot(ctx: Dictionary, from: Vector2) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var r := EXIT_MIN
	while r <= EXIT_MAX:
		var best := Vector2.INF
		for i in 24:
			var g := from + Vector2.from_angle(TAU * float(i) / 24.0) * r
			if grid.walkable(g) and Walls.outside(g) and (best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from)):
				best = g
		if best != Vector2.INF:
			return best
		r += 0.5
	return Vector2.INF


# --- Ruin: Smite, Ember --------------------------------------------------------------------------------------------------

## A's night with Smite for Doom: each granary's watchmen are smitten (one bolt each) when its grain is due within CLEAR_PRE, and the granary
## with its grain in and no watchman on guard is set alight. Smite is a loud power; the watchmen are 2.8 apart, so one bolt takes one.
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := ctx.d as HarvestDirector
	var rules: Rules = ctx.rules
	if d == null:
		return ""
	var order := _order(d)
	for s in order:
		if not d.has_grain(s):
			continue
		if d.guarding(s):
			if _ready(bc, ctx, "smite"):
				rules.cast(int(ctx.slots.smite), d.guards(s)[0].ground_pos)
				return "smite a watchman of the %s granary" % _name(d, s)
		elif not d.burning(s) and _ready(bc, ctx, "ember"):
			rules.cast(int(ctx.slots.ember), s.center())
			return "ember the %s granary" % _name(d, s)
	if not _ready(bc, ctx, "smite"):
		return ""
	for s in order:
		if not d.has_grain(s) and d.grain_left(s) <= CLEAR_PRE and d.guarding(s):
			rules.cast(int(ctx.slots.smite), d.guards(s)[0].ground_pos)
			return "smite a watchman of the %s granary (grain in %.0f s)" % [_name(d, s), d.grain_left(s)]
	return ""


# --- Death: Death Mark, Pestilence ---------------------------------------------------------------------------------------

## H2: the carter is sick with no watchman on guard. Death Mark the watchmen (a mark kills in 10 s, the cooldown is 20) timed to have both gone
## as Pestilence comes ready, then Pestilence on the carter; one marked that way counts as gone with MARK_GONE of his fuse left.
static func act_death(bc, ctx: Dictionary) -> String:
	var d := ctx.d as HarvestDirector
	var rules: Rules = ctx.rules
	if d == null:
		return ""
	var memo: Dictionary = ctx.memo
	if not memo.has("marks"):
		memo.marks = {}
	var tgt := _target(d)
	if tgt.is_empty():
		return ""
	var s: Structure = tgt.s
	var c: Person = tgt.c
	var left: Array[Person] = []
	for g in d.guards(s):
		var at: float = memo.marks.get(g.get_instance_id(), -INF)
		if at == -INF or d._clock - at < 10.0 - MARK_GONE:
			left.append(g)
	if left.is_empty() and _ready(bc, ctx, "pestilence") and c.sick_left <= 0.0:
		rules.cast(int(ctx.slots.pestilence), c.ground_pos)
		return "pestilence on the %s granary's carter" % _name(d, s)
	if not left.is_empty() and _cd(ctx, "pestilence") <= DEATH_LEAD and _ready(bc, ctx, "deathmark"):
		var man := left[0]
		for g in left:
			if not memo.marks.has(g.get_instance_id()):
				man = g
				break
		memo.marks[man.get_instance_id()] = d._clock
		rules.cast(int(ctx.slots.deathmark), man.ground_pos)
		return "death mark a watchman of the %s granary" % _name(d, s)
	return ""


# --- Veil: Silent Doom, Blight -------------------------------------------------------------------------------------------

## H3: Silent Doom the watchmen when the grain is due within CLEAR_PRE (the first at once if Blight will be ready), Blight the granary once its
## grain is in and none of them is on guard.
static func act_veil(bc, ctx: Dictionary) -> String:
	var d := ctx.d as HarvestDirector
	var rules: Rules = ctx.rules
	if d == null:
		return ""
	var order := _order(d)
	for s in order:
		if d.has_grain(s) and not d.guarding(s) and _ready(bc, ctx, "blight"):
			rules.cast(int(ctx.slots.blight), s.center())
			return "blight the %s granary" % _name(d, s)
	if not _ready(bc, ctx, "doom"):
		return ""
	for s in order:
		if d.guarding(s) and (d.has_grain(s) or d.grain_left(s) <= CLEAR_PRE) and _cd(ctx, "blight") <= d.grain_left(s) + 10.0:
			rules.cast(int(ctx.slots.doom), d.guards(s)[0].ground_pos)
			return "doom a watchman of the %s granary (grain in %.0f s)" % [_name(d, s), d.grain_left(s)]
	return ""


# --- Passage: Skylift, Windfall -----------------------------------------------------------------------------------------

## H1: Skylift takes the carter of the first granary still to spoil where he will stand when the beam takes (SkyliftFx.T_TAKE on, along his road;
## where he stands at his door) and sets him down out of the walls: his granary is spoiled at once. While the beam cools longer than a carter
## hauling a load needs to reach the Citadel, a Windfall of stone across his road (WALL_LEAD s ahead) makes him go round.
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := ctx.d as HarvestDirector
	var rules: Rules = ctx.rules
	if d == null:
		return ""
	var tgt := _target(d)
	if tgt.is_empty():
		return ""
	var s: Structure = tgt.s
	var c: Person = tgt.c
	var walking := c.goal() != Vector2.INF and not _at_door(d, s, c)
	if _ready(bc, ctx, "skylift"):
		var from: Vector2 = _god().road_ahead(c, SkyliftFx.T_TAKE) if walking else c.ground_pos
		var to := _exit_spot(ctx, from)
		if to != Vector2.INF:
			rules.cast(int(ctx.slots.skylift), from, {"to": to})
			return "skylift the %s granary's carter out of the walls, to (%.1f, %.1f)" % [_name(d, s), to.x, to.y]
		return ""
	if walking and d._hauling.has(c.get_instance_id()) and _ready(bc, ctx, "windfall"):
		var road: PackedVector2Array = ctx.crowd._grid.path(c.ground_pos, c.goal())
		var left: float = _length_from(c.ground_pos, road) / maxf(c.walk_speed, 0.1)
		if _cd(ctx, "skylift") + SkyliftFx.T_TAKE >= left and left > WALL_LEAD + 1.0:
			var ahead: Vector2 = _god().road_ahead(c, WALL_LEAD)
			var way: Vector2 = (ahead - c.ground_pos).normalized() if ahead.distance_to(c.ground_pos) > 0.1 else Vector2.RIGHT
			rules.cast(int(ctx.slots.windfall), ahead, {"dir": way.orthogonal(), "mode": "stone"})
			return "windfall of stone across the %s granary's carter's road (the beam cools %.0f s, the Citadel %.0f s off)" % [_name(d, s),
				_cd(ctx, "skylift"), left]
	return ""


## The length of the walk `road` from `at`.
static func _length_from(at: Vector2, road: PackedVector2Array) -> float:
	var n := 0.0
	for step in road:
		n += at.distance_to(step)
		at = step
	return n


# --- Decree: Leaving Is Prohibited, Breathing Is Prohibited -------------------------------------------------------------

## No route (reported, not tuned around): every way a granary is spoiled needs a power Decree's Tier 1 lacks -- fire or a fall (a Ruin or Veil
## power), the carter out of the walls (a lift, a whisper), sick (Pestilence), rotted (Blight), or seized by the guard The Bell Lies calls
## (HarvestDirector._on_cast() keeps only a CALL THE GUARD cast for the seizure). A carter held in the amber, or choked in it, is no spoil: one
## who dies is replaced (H5). So the policy casts nothing; the night is lost as the none run's.
static func act_decree(_bc, _ctx: Dictionary) -> String:
	return ""


# --- Dominion: Mind Whisper, Discord -------------------------------------------------------------------------------------

## H1: whisper the carter out of the nearest gate a step at a time (Mind Whisper's reach is 10, its cooldown 8; one still whispered hears the next),
## and Discord him when he is not under a whisper and Mind Whisper is cooling: a confused carter takes no load.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := ctx.d as HarvestDirector
	var rules: Rules = ctx.rules
	if d == null:
		return ""
	var tgt := _target(d)
	if tgt.is_empty():
		return ""
	var s: Structure = tgt.s
	var c: Person = tgt.c
	if _ready(bc, ctx, "whisper") and not c.soldier and not c.shaken():
		var to := _whisper_to(ctx, c)
		if to != Vector2.INF:
			rules.cast(int(ctx.slots.whisper), c.ground_pos, {"target": c, "to": to})
			return "whisper the %s granary's carter toward the gate" % _name(d, s)
	if _ready(bc, ctx, "discord") and c.mind != Person.Mind.WHISPERED and d.has_grain(s) and c.mind != Person.Mind.CONFUSED:
		rules.cast(int(ctx.slots.discord), c.ground_pos)
		return "discord the %s granary's carter" % _name(d, s)
	return ""


## The farthest point along the shortest walk from `c` out of the walls that lies within WHISPER_STEP of him; Vector2.INF when no way out is found.
static func _whisper_to(ctx: Dictionary, c: Person) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var best_path := PackedVector2Array()
	var best_len := INF
	for e: Vector2 in City.current().exits():
		var path := grid.path(c.ground_pos, e)
		if path.is_empty():
			continue
		var total := 0.0
		var from := c.ground_pos
		for pt in path:
			total += from.distance_to(pt)
			from = pt
		if total < best_len:
			best_len = total
			best_path = path
	if best_path.is_empty():
		return Vector2.INF
	var at := c.ground_pos
	var out := c.ground_pos
	for pt in best_path:
		var seg := at.distance_to(pt)
		var n := maxi(1, ceili(seg / 0.5))
		for k in range(1, n + 1):
			var g := at.lerp(pt, float(k) / float(n))
			if g.distance_to(c.ground_pos) > WHISPER_STEP:
				return out
			out = g
		at = pt
	return out


## The numbers a report line prints (the same as the route B's, tier1_b.gd).
static func state(bc, ctx: Dictionary) -> String:
	return String(preload("res://tools/dev/routes/tier1_b.gd").state_harvest(bc, ctx))
