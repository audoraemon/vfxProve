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

## A filler cast (god T1R, D38): one with no lasting effect, cast only so the scripted player is not idle (a power aimed at nobody who matters).
## A policy's words for it start with FILL, and the idle measure (behaviour_check's _scripted(), through note_cast()) does not count it as an
## act, so the idle the gate prints is the real wait. A policy should not need one: a filler that remains is printed, never hidden.
const FILL := "fill: "

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


## A cast's words mark a filler (FILL).
static func is_fill(did: String) -> bool:
	return did.begins_with(FILL)


## The idle measure (D38): a cast `did` at second `t` ends the stretch since the last act in `acts` {last, longest} -- unless it is a filler,
## which leaves the stretch running. A play run's printed idle is `acts.longest` with the stretch to the night's end counted.
static func note_cast(acts: Dictionary, t: float, did: String) -> void:
	if did == "" or is_fill(did):
		return
	acts.longest = maxf(float(acts.longest), t - float(acts.last))
	acts.last = t


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


## Decree's two Tier 1 laws together (spec 5.2: the combo is meant): Leaving Is Prohibited laid on `at`, where those it is for (`who`) stand as
## it seals, then Breathing Is Prohibited on them once it holds them (amber_breath()). Held where nobody can leave, they cannot run from the
## airless circle, and BreathFx.CHOKE seconds kill them and whoever else stands in it inside the cell. The cell is laid only when the breath is
## ready by the time it seals (NoLeaveFx.T_SEAL, while it keeps the caster busy); it is kept in ctx.memo.amber. True when the cell was cast.
static func cast_amber(bc, ctx: Dictionary, at: Vector2, who: Array) -> bool:
	var rules: Rules = ctx.rules
	if who.is_empty() or not bc._slot_ready(rules, ctx.slots, "noleave") or float(bc._slot_wait(rules, ctx.slots, "breath")) > NoLeaveFx.T_SEAL:
		return false
	var fx := rules.cast(int(ctx.slots.noleave), at) as NoLeaveFx
	if fx == null:
		return false
	ctx.memo["amber"] = {"fx": fx, "who": who.duplicate()}
	return true


## A cell cast_amber() laid is closing or holds those it is for, and its breath is still to come: the policy waits on it rather than cast
## anything else. Only reads (a cell lifted, or holding none of them once sealed, is forgotten by amber_breath()).
static func amber_pending(ctx: Dictionary) -> bool:
	return ctx.memo.has("amber")


## The breath that follows a cell cast_amber() laid: once it has sealed, Breathing Is Prohibited on the middle of those it was laid for that it
## holds, where they will stand as the air goes (BreathFx.T_LAND on), kept within the cell. What was cast ("" for nothing); the cell is
## forgotten once the breath is cast, or when it has lifted or holds none of them AMBER_JOIN after its seal.
static func amber_breath(bc, ctx: Dictionary) -> String:
	var amber: Dictionary = ctx.memo.get("amber", {})
	if amber.is_empty():
		return ""
	var fx: NoLeaveFx = null
	if is_instance_valid(amber.fx):
		fx = amber.fx as NoLeaveFx
	if fx == null or fx.finished or (fx.t >= NoLeaveFx.T_SEAL and not fx.sealed):
		ctx.memo.erase("amber")
		return ""
	if not fx.sealed:
		return ""
	var held: Array[Person] = []
	for v: Variant in amber.who:
		if is_instance_valid(v) and (v as Person).is_alive() and fx.bound.has(v):
			held.append(v as Person)
	if held.is_empty():
		if fx.t - NoLeaveFx.T_SEAL < AMBER_JOIN:
			return ""  # one who walks in is held as well: he may be on the step of a door yet
		ctx.memo.erase("amber")
		return ""
	var rules: Rules = ctx.rules
	if not bc._slot_ready(rules, ctx.slots, "breath"):
		return ""
	var mid := Vector2.ZERO
	for p in held:
		mid += road_ahead(p, BreathFx.T_LAND)
	mid /= float(held.size())
	var off := mid - fx.origin
	if off.length() > NoLeaveFx.RADIUS - AMBER_EDGE:
		mid = fx.origin + off.normalized() * (NoLeaveFx.RADIUS - AMBER_EDGE)
	var more := 0
	for v: Variant in fx.bound:
		if is_instance_valid(v) and not held.has(v) and (v as Person).is_alive() and (v as Person).ground_pos.distance_to(mid) <= BreathFx.RADIUS:
			more += 1
	rules.cast(int(ctx.slots.breath), mid)
	ctx.memo.erase("amber")
	return "breathing is prohibited in the amber, on %d held there (%d more held in its reach)" % [held.size(), more]


## The breath's aim is kept this far inside the cell's edge (a man set back onto the edge stands on it).
const AMBER_EDGE := 0.3
## A cell that holds none of those it is for is kept this long after its seal for them to walk in (out of a door onto it), then forgotten.
const AMBER_JOIN := 2.5
## A cell's centre may lie up to AMBER_SHIFT from where those it is for will stand as it seals (so they stand at least RADIUS - AMBER_SHIFT
## inside its edge), and one standing within its radius and AMBER_ROOM (he shifts meanwhile) counts as held with them.
const AMBER_SHIFT := 2.0
const AMBER_ROOM := 0.4


## Where a cell for those who will stand at `at` dooms the fewest others: `at` itself or a point round it within `shift` (AMBER_SHIFT; less for
## a group spread round `at`), the nearest `at` of equals. {"at", "others" (living, out of doors, not in `who`, held by it), "doomed" (those of
## them within the breath's reach of `at`: they choke with them)}. Fewest doomed first, then fewest held. Only reads.
static func amber_aim(crowd: Crowd, at: Vector2, who: Array, shift := AMBER_SHIFT) -> Dictionary:
	var tries: Array[Vector2] = [at]
	if shift > 0.05:
		for rad: float in [shift * 0.35, shift * 0.7, shift]:
			for k in 12:
				tries.append(at + Vector2.from_angle(TAU * float(k) / 12.0) * rad)
	var near: Array[Person] = []
	for e in crowd._field.in_radius(at, NoLeaveFx.RADIUS + AMBER_ROOM + shift):
		var p := e as Person
		if p != null and p.is_alive() and not p.inside and not who.has(p):
			near.append(p)
	var best := {"at": at, "others": 1 << 20, "doomed": 1 << 20}
	for g in tries:
		var n := 0
		var doomed := 0
		for p in near:
			if p.ground_pos.distance_to(g) <= NoLeaveFx.RADIUS + AMBER_ROOM:
				n += 1
				doomed += 1 if p.ground_pos.distance_to(at) <= BreathFx.RADIUS + AMBER_ROOM else 0
		if doomed < int(best.doomed) or (doomed == int(best.doomed) and n < int(best.others)):
			best = {"at": g, "others": n, "doomed": doomed}
	return best


## How many more deaths the district round `at` takes before it is in Local Emergency and the bell is called (AlarmManager.LOCAL_EVENTS
## deaths or falls in one district); a large number once the town is past it. Only reads.
static func deaths_left(crowd: Crowd, at: Vector2) -> int:
	var alarms: AlarmManager = crowd.alarms
	if alarms.stage >= AlarmManager.Stage.LOCAL_EMERGENCY:
		return 1 << 20
	return AlarmManager.LOCAL_EVENTS - 1 - int(alarms._events.get(AlarmManager.district_of(at), 0))


## Death's Tier 1 (the user's tree): the nearest body Raise the Dead can take within `reach` of `at` (one whose soul is still near, with
## `soul`: a SPIRIT needs it), its place; Vector2.INF for none. Bodies are on the ledger only while the loadout carries Raise. Only reads.
static func body_near(crowd: Crowd, at: Vector2, reach: float, soul := false) -> Vector2:
	if crowd.remains == null:
		return Vector2.INF
	for r in crowd.remains.near(at, reach):
		if not soul or crowd.remains.has_soul(r):
			return r.pos
	return Vector2.INF


## The spirit Raise the Dead has up and free to possess someone now (RaiseTheDeadFx.can_follow_up()), or null. Only reads.
static func free_spirit(ctx: Dictionary) -> RaiseTheDeadFx:
	var fx := (ctx.rules as Rules).live_fx("raise") as RaiseTheDeadFx
	return fx if fx != null and fx.can_follow_up() else null


## Raise the Dead's spirit possesses `who` with one of Mind Whisper's orders (`extra`: "order" "attack" + "foe", "burn" + "building", or
## a walk "to"): a follow-up recast of the slot (Rules.recast()), no cooldown. True when it took.
static func cast_possess(ctx: Dictionary, who: Person, extra: Dictionary) -> bool:
	if not ctx.slots.has("raise"):
		return false
	var said := extra.duplicate()
	said["target"] = who
	return (ctx.rules as Rules).recast(int(ctx.slots.raise), who.ground_pos, said)


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
