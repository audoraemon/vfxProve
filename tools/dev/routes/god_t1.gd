extends RefCounted
## The per-type scripted policies for the five Tier 1 missions (god T1R, spec 9): behaviour_check --god=<type>:1 on a scenario named in
## SCENARIOS drafts the type's own two Tier 1 powers (GodTree.keys_for(type, 1)) and plays act_<type> of that scenario's file through
## _scripted(). Each god_t1/<scenario>.gd holds one policy per god type (a stub casting nothing until its mission task writes it) and
## FILLED, the types it has written. Also the policy pieces every mission uses; they only read the world, and cast only through the
## `cast_` ones. (No class_name: preloaded as GOD_T1 by behaviour_check.gd and as GodT1 by the tests, as the tier files are.)

const SCENARIOS := ["warning", "tax", "harvest", "lamb", "prayers"]
const FILES := {
	"warning": preload("res://tools/dev/routes/god_t1/warning.gd"),
	"tax": preload("res://tools/dev/routes/god_t1/tax.gd"),
	"harvest": preload("res://tools/dev/routes/god_t1/harvest.gd"),
	"lamb": preload("res://tools/dev/routes/god_t1/lamb.gd"),
	"prayers": preload("res://tools/dev/routes/god_t1/prayers.gd"),
}

## The spots tried for ground past the wall (outside_spot()): every OUTSIDE_STEP out from the person, in OUTSIDE_DIRS directions.
const OUTSIDE_STEP := 0.5
const OUTSIDE_DIRS := 24


## The scenario has a policy file with an act_<type> for the god type.
static func has_policy(scenario: String, type: String) -> bool:
	if not FILES.has(scenario):
		return false
	for m: Dictionary in (FILES[scenario] as GDScript).get_script_method_list():
		if m.name == "act_" + type:
			return true
	return false


## The types whose policy the scenario's file has written (its FILLED).
static func filled(scenario: String) -> PackedStringArray:
	if not FILES.has(scenario):
		return PackedStringArray()
	return PackedStringArray((FILES[scenario] as GDScript).get_script_constant_map().get("FILLED", []))


## One look of the policy of `type` for `scenario`: what it cast, or "".
static func act(scenario: String, type: String, bc, ctx: Dictionary) -> String:
	if not has_policy(scenario, type):
		return ""
	return String((FILES[scenario] as GDScript).call("act_" + type, bc, ctx))


## The numbers the scenario's report lines print.
static func state(scenario: String, bc, ctx: Dictionary) -> String:
	if not FILES.has(scenario):
		return ""
	return String((FILES[scenario] as GDScript).call("state", bc, ctx))


## The loadout a god type plays at Tier 1: its two Tier 1 keys in the real tree (GodTree.keys_for).
static func loadout(type: String) -> PackedStringArray:
	return GodTree.keys_for(type, 1)


# --- Shared policy pieces (god T1R, preflight 18): read-only unless the name starts with cast_ ---

## Walkable ground out of the walls (Walls.outside()) nearest to `from` and within `reach` of it, tried every OUTSIDE_STEP along
## OUTSIDE_DIRS directions; Vector2.INF when there is none. Where a whisper or a mirror's way out is aimed to put someone outside.
static func outside_spot(_bc, ctx: Dictionary, from: Vector2, reach: float) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var best := Vector2.INF
	var dist := OUTSIDE_STEP
	while dist <= reach and best == Vector2.INF:
		for i in OUTSIDE_DIRS:
			var g := from + Vector2.from_angle(TAU * float(i) / float(OUTSIDE_DIRS)) * dist
			if Walls.outside(g) and (grid == null or grid.walkable(g)):
				if best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from):
					best = g
		dist += OUTSIDE_STEP
	return best


## Where `p` will be `seconds` from now, walking on the path he is on at the pace he walks now (his own place when he has no path).
## Only reads.
static func road_ahead(p: Person, seconds: float) -> Vector2:
	var at := p.ground_pos
	var left := p.walk_speed * seconds
	for k in range(p._leg, p._path.size()):
		var step: Vector2 = p._path[k]
		var seg := at.distance_to(step)
		if seg >= left:
			return at.move_toward(step, left)
		left -= seg
		at = step
	return at


## Mirrorfold Passage laid in at `way_in` and out at `way_out`, when its slot is ready: true when it was cast.
static func cast_mirror(bc, ctx: Dictionary, way_in: Vector2, way_out: Vector2) -> bool:
	var rules: Rules = ctx.rules
	if not bc._slot_ready(rules, ctx.slots, "mirror"):
		return false
	rules.cast(int(ctx.slots.mirror), way_in, {"to": way_out})
	return true


## The Bell Lies in `mode` ("well": ALL IS WELL; "guard": CALL THE GUARD, to `at`), when its slot is ready: true when it was cast.
static func cast_bell(bc, ctx: Dictionary, mode: String, at: Vector2) -> bool:
	var rules: Rules = ctx.rules
	if not mode in ["well", "guard"] or not bc._slot_ready(rules, ctx.slots, "belllies"):
		return false
	rules.cast(int(ctx.slots.belllies), at, {"mode": mode})
	return true


## Where Pestilence would take the most people (three at most, PestilenceFx.INFECT_MAX) round `at`, without taking any of `avoid`: the
## aim, at `at` itself or at one of those round it; Vector2.INF when no aim takes anyone. The nearest to `at` of equals. Only reads.
static func plague_aim(crowd: Crowd, at: Vector2, avoid: Array = []) -> Vector2:
	var tries: Array[Vector2] = [at]
	for e in crowd._field.in_radius(at, PestilenceFx.INFECT_R * 2.0):
		var p := e as Person
		if p != null and not p.inside:
			tries.append(p.ground_pos)
	var best := Vector2.INF
	var most := 0
	for g in tries:
		var victims := PestilenceFx.victims_at(crowd._field, g)
		var clean := true
		for v: Person in victims:
			if avoid.has(v):
				clean = false
				break
		if clean and (victims.size() > most or (victims.size() == most and most > 0 and g.distance_squared_to(at) < best.distance_squared_to(at))):
			best = g
			most = victims.size()
	return best
