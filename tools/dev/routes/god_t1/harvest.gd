extends RefCounted
## The scripted player's per-type policies for Spoiled Harvest (god T1R, spec 6.7): one act_<type>(bc, ctx) for each god type, playing only that
## type's two Tier 1 powers (GodTree.keys_for(type, 1)); behaviour_check --god=<type>:1 plays them through _scripted(). `bc` is the
## behaviour_check script, ctx = {rules, slots, d (the director), crowd, memo, mission} as for tier1_b.gd. Each looks the way a player does:
## the granary whose turn it is, its watchmen, its carter -- and casts at most one power a look.
##
## The six routes: Ruin Smites the watchmen and Embers the granary (A's, with Smite); Death marks the watchmen so both are gone when
## Pestilence takes the carter (H2); Veil dooms the watchmen and Blights the full granary (H3); Passage lays a Mirrorfold on the carter's
## road with its way out beyond the wall (H1); Decree holds the carter and calls the guard to him (H4); Dominion whispers him out of the
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
## Passage: how many seconds of the carter's road ahead the way in is laid, and how far along the road from a door it is laid for a carter
## who has yet to set out; the second before the grain a waiting carter's way is laid.
const MIRROR_LEAD := 3.5
const MIRROR_DOOR_STEP := 3.5
const MIRROR_WAIT := 10.0
## Passage: how many seconds of the carter's road ahead the Thornwall is laid (beyond where the Mirrorfold will be).
const THORN_LEAD := 7.0
## Passage: how far past the wall the way out lies at the least (the oval is 2.4 across: a carter set down anywhere on it is out).
const EXIT_MIN := 3.0
const EXIT_MAX := 26.0
## Decree: the seconds of his road ahead the hold is laid for a walking carter (it seals 0.6 s after the cast), and the longest the call waits on
## the hold being laid.
const HOLD_LEAD := 0.6
const HOLD_PLAN := 4.0
## Passage: with the Mirrorfold cooling, a Thornwall across the carter's road is laid once FILL_AFTER - 5 s have passed with nothing cast.
const FILL_AFTER := 30.0
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


## Where the carter will be `seconds` from now on his road: where he stands at his door (he is waiting) or, on the way to or from the door, along
## his walk; a carter at his door about to take a load is looked for a step down the road to the Citadel.
static func _ahead(ctx: Dictionary, d: HarvestDirector, s: Structure, c: Person, seconds: float) -> Vector2:
	if _at_door(d, s, c):
		return _step_off(ctx, d, s) if d.has_grain(s) or d.grain_left(s) <= MIRROR_WAIT else Vector2.INF
	if c.goal() == Vector2.INF:
		return Vector2.INF
	return _god().road_ahead(c, seconds)


## A point MIRROR_DOOR_STEP down the road from the granary's door toward the Citadel.
static func _step_off(ctx: Dictionary, d: HarvestDirector, s: Structure) -> Vector2:
	var path: PackedVector2Array = ctx.crowd._grid.path(d.doors[s], d.citadel_door)
	var run := 0.0
	var at: Vector2 = d.doors[s]
	for k in path.size():
		var seg := at.distance_to(path[k])
		if run + seg >= MIRROR_DOOR_STEP:
			return at.move_toward(path[k], MIRROR_DOOR_STEP - run)
		run += seg
		at = path[k]
	return at


## The shared policy pieces (god_t1.gd preloads this file, so it is loaded when wanted).
static func _god() -> GDScript:
	return load("res://tools/dev/routes/god_t1.gd")


## Ground beyond the wall for a Mirrorfold's way out, reached from `from`: the nearest spot (EXIT_MIN to EXIT_MAX away, round the compass) from which
## a walker set down anywhere on the oval would land outside the walls on walkable ground (Person.fold() puts him on the nearest walkable ground
## within 4 cells of where he would stand, or leaves him where he is). Vector2.INF for none.
static func _exit_spot(ctx: Dictionary, from: Vector2) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var offs: Array[Vector2] = [Vector2.ZERO, MirrorfoldFx.ACROSS * MirrorfoldFx.HALF_WIDE, -MirrorfoldFx.ACROSS * MirrorfoldFx.HALF_WIDE,
		MirrorfoldFx.DOWN * MirrorfoldFx.HALF_DEEP, -MirrorfoldFx.DOWN * MirrorfoldFx.HALF_DEEP]
	var r := EXIT_MIN
	while r <= EXIT_MAX:
		var best := Vector2.INF
		for i in 24:
			var g := from + Vector2.from_angle(TAU * float(i) / 24.0) * r
			var ok := grid.walkable(g)
			for o in offs:
				if not ok:
					break
				var land := g + o
				if grid.walkable(land):
					ok = Walls.outside(land)
				else:
					var near := grid.nearest_walkable(land, 4)
					ok = near != Vector2.INF and Walls.outside(near)
			if ok and (best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from)):
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


# --- Passage: Thornwall, Mirrorfold --------------------------------------------------------------------------------------

## H1: a Mirrorfold laid on the carter's road, its way out beyond the wall, so he is set down outside it and his granary is spoiled. While the
## Mirrorfold cools (54 s), a Thornwall across the road ahead of the carter (42 s) is laid whenever FILL_AFTER - 5 s have passed with nothing cast.
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
	var memo: Dictionary = ctx.memo
	var now := d._clock
	if _ready(bc, ctx, "mirror"):
		var way_in := _ahead(ctx, d, s, c, MIRROR_LEAD)
		if way_in != Vector2.INF:
			var way_out := _exit_spot(ctx, way_in)
			if way_out != Vector2.INF and _god().cast_mirror(bc, ctx, way_in, way_out):
				memo.last = now
				return "mirrorfold on the %s granary's carter's road" % _name(d, s)
	elif _ready(bc, ctx, "thorns") and now - float(memo.get("last", 0.0)) >= FILL_AFTER - 5.0:
		var ahead := _ahead(ctx, d, s, c, THORN_LEAD)
		if ahead == Vector2.INF:
			ahead = _step_off(ctx, d, s)
		var way: Vector2 = (ahead - c.ground_pos).normalized() if ahead.distance_to(c.ground_pos) > 0.1 else Vector2.RIGHT
		rules.cast(int(ctx.slots.thorns), ahead, {"dir": way.orthogonal()})
		memo.last = now
		return "thornwall across the %s granary's carter's road" % _name(d, s)
	return ""


# --- Decree: Leaving Is Prohibited, The Bell Lies ------------------------------------------------------------------------

## H4: hold the carter (Leaving Is Prohibited) at the place the guard are called to (The Bell Lies, CALL THE GUARD): on him, the hold first and the
## call a look after, so he cannot walk out of the seizing radius while the guard run there. The bell's 60 s are the long wait (D12: Decree may idle up
## to 60 s here); the hold once laid at the next granary's door to fill it did nothing, and is gone (D38).
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := ctx.d as HarvestDirector
	var rules: Rules = ctx.rules
	if d == null:
		return ""
	var memo: Dictionary = ctx.memo
	var now := d._clock
	var plan: Dictionary = memo.get("plan", {})
	if not plan.is_empty():
		if now - float(plan.t) > HOLD_PLAN:
			memo.erase("plan")
		elif _god().cast_bell(bc, ctx, "guard", plan.at):
			memo.erase("plan")
			memo.last = now
			return "the bell calls the guard to the %s granary's carter" % plan.name
		else:
			return ""
	var tgt := _target(d)
	if not tgt.is_empty() and _ready(bc, ctx, "belllies"):
		var s: Structure = tgt.s
		var c: Person = tgt.c
		var hold := _ready(bc, ctx, "noleave")
		var place := _guard_place(ctx, d, s, c)
		if hold:
			rules.cast(int(ctx.slots.noleave), place)
			memo.plan = {"at": place, "t": now, "name": _name(d, s)}
			memo.last = now
			return "leaving is prohibited at the %s granary's carter" % _name(d, s)
		if _god().cast_bell(bc, ctx, "guard", place):
			memo.last = now
			return "the bell calls the guard to the %s granary's carter" % _name(d, s)
		return ""
	return ""


## Where the hold and the call are laid: on the carter. He stands at his door (waiting for the grain or about to take a load, then a step down
## the road) or walks his road; the hold, laid on the spot he will be at when it seals, keeps him within Leaving Is Prohibited's radius of it
## -- the radius the guard seize within (HarvestDirector.SEIZE_R) -- whenever the first soldier has come.
static func _guard_place(ctx: Dictionary, d: HarvestDirector, s: Structure, c: Person) -> Vector2:
	if _at_door(d, s, c):
		return d.doors[s] if not d.has_grain(s) and d.grain_left(s) > HOLD_LEAD else _step_off(ctx, d, s)
	if c.goal() == Vector2.INF:
		return c.ground_pos
	return _god().road_ahead(c, HOLD_LEAD)


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
