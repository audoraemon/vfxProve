extends RefCounted
## The scripted policies of the Hunt "Break the hunt" (Tier 4; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared), one
## act_<type> per god type, and the report line (state). All six types are written (Task 12); FILLED lists them. Decree has no route (MS §9 open
## issue 1, ruling C9): its policy is the best honest delay. Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is
## never edited by a Hunt task).

## The god types whose policy is written (all six, god P5 Task 12; Decree is a reported gap: MS §9 open issue 1, ruling C9).
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(4) Might at level 1, all in GodTree.keys_for(type, 4)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "heaven", "orbital"],
	"death": ["deathmark", "pestilence", "glacial"],
	"veil": ["doom", "blight", "nova"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies", "magnify"],
	"dominion": ["whisper", "discord", "turncoat"],
}


## The shared policy pieces (god T1R, Ruling P5-7): road_ahead(), reached through the Hunts' common file.
const GOD := preload("res://tools/dev/routes/god_t1.gd")
## Heaven Splitter's script (it has no class name), for its strike time.
const HEAVEN := preload("res://src/fx/set2/heaven_splitter.gd")
## How long a cast on a bearer holds the policy off him: the longest strike of the shared plan (Heaven Splitter's T_STRIKE) plus a look.
const HOLD := 2.0


## The director when the night is on, else null.
static func _bh(ctx: Dictionary) -> BreakHuntDirector:
	return ctx.get("d") as BreakHuntDirector


## The numbers this Hunt's report lines print: standards broken, houses taken, standards marching, taken up by an escort, stopped by the walls, the
## soonest standard's seconds to a house, the closest the two escorts of a marching standard stood to each other in motion and the looks that was 1.6
## or less (`pair=min/low`, as Hunt 1's check prints), and the hint's phase.
static func state(_bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var marching := 0
	for i in d.steps.size():
		marching += 1 if d.steps[i].raised and not d.steps[i].broken else 0
	var soon := d.soonest_eta()
	return "broken=%d taken=%d marching=%d took_up=%d walled=%d soonest=%s pair=%.2f/%d phase=%s" % [d.broken_count(), d.taken(), marching, d.took_up_count,
		d.walled_count, "-" if soon == INF else str(roundi(soon)), minf(d.pair_min, 99.0), d.pair_low, d.hint_phase()]


## The standards in the street, soonest to a house first (a planted one last): the raised, unbroken ones whose bearer lives and is out of doors.
static func _marching(d: BreakHuntDirector) -> Array[int]:
	var out: Array[int] = []
	for i in d.steps.size():
		if d.steps[i].raised and not d.steps[i].broken and d.bearer(i) != null and not d.bearer(i).inside:
			out.append(i)
	out.sort_custom(func(a: int, b: int) -> bool: return d.eta(a) < d.eta(b))
	return out


## The shared plan with the def's own loadout (Silent Doom, Smite, Heaven Splitter; no `--god`), one look: the standard soonest to a house is
## worked, a strike at its bearer led ahead of his walk (Silent Doom, else Smite, else Heaven Splitter). A death beside a standard frightens its
## escorts too, so a bearer struck down breaks his standard unless the company is steady (MS §5); a bearer struck again within HOLD seconds is
## left alone while the first strike lands (the memo). Returns what it cast, or "".
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var memo: Dictionary = ctx.memo
	var now := rules.mission_time()
	for i in _marching(d):
		var b := d.bearer(i)
		if now - float(memo.get("cast_%d" % i, -99.0)) < HOLD:
			continue
		if bc._slot_ready(rules, slots, "doom"):
			memo["cast_%d" % i] = now
			rules.cast(int(slots.doom), GOD.road_ahead(b, SilentDoom.T_STRIKE))
			return "doom bearer %d" % i
		if bc._slot_ready(rules, slots, "smite"):
			memo["cast_%d" % i] = now
			rules.cast(int(slots.smite), GOD.road_ahead(b, SmiteFx.T_STRIKE))
			return "smite bearer %d" % i
		if bc._slot_ready(rules, slots, "heaven"):
			memo["cast_%d" % i] = now
			rules.cast(int(slots.heaven), GOD.road_ahead(b, HEAVEN.T_STRIKE))
			return "heaven bearer %d" % i
	return ""


## The seconds before a muster's raise at which its escorts are worked (they stand killable from 0:00): the idle rule's real work between two bearers
## (review-t7, Task 12), not a filler -- an escort felled early is a guard the bearer will not have when he marches.
const BH_PREP := 24.0
## How far apart the file of a marching standard must fit for one wide strike (Heaven Splitter's core is 1.6 wide; the file is the bearer between two escorts
## 1.3 along the street each way).
const BH_HEAVEN_FIT := 1.35
## Death: the seconds to a house at or under which the plague is laid on the bearer and the escort beside him (it kills them PLAGUE_LIFE and a cast on): the
## Death Mark's 10 s fuse and 20 s cooldown are the plan, and the plague is what a player keeps for the standard that is nearly there.
const BH_PLAGUE_ETA := 14.0


## Mission seconds since the Hunt's clock began (the director's).
static func _now(d: BreakHuntDirector) -> float:
	return d._clock


## The escorts of step `i` who stand and live (a fallen one stays in the party list as a freed or dead body).
static func _men(d: BreakHuntDirector, i: int) -> Array[Person]:
	var out: Array[Person] = []
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man) and not (g.man as Person).inside:
			out.append(g.man as Person)
	return out


## The nearest to `from` of `people`.
static func _nearest(people: Array[Person], from: Vector2) -> Person:
	var best: Person = null
	for p in people:
		if best == null or p.ground_pos.distance_squared_to(from) < best.ground_pos.distance_squared_to(from):
			best = p
	return best


## The smallest circle round `points` that is centred on one of them, on the middle of two, or on all: {at, r}.
static func _enclose(points: Array[Vector2]) -> Dictionary:
	var tries: Array[Vector2] = []
	var sum := Vector2.ZERO
	for p in points:
		tries.append(p)
		sum += p
	tries.append(sum / float(maxi(points.size(), 1)))
	for i in points.size():
		for j in range(i + 1, points.size()):
			tries.append((points[i] + points[j]) * 0.5)
	var best := {"at": Vector2.INF, "r": INF}
	for c in tries:
		var far := 0.0
		for p in points:
			far = maxf(far, c.distance_to(p))
		if far < float(best.r):
			best = {"at": c, "r": far}
	return best


## Where `people` stand `seconds` on, each walking the road he is on.
static func _led(people: Array[Person], seconds: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in people:
		out.append(GOD.road_ahead(p, seconds))
	return out


## The file of standard `i`: its bearer and its escorts who stand.
static func _file(d: BreakHuntDirector, i: int) -> Array[Person]:
	var out: Array[Person] = []
	if d.bearer(i) != null:
		out.append(d.bearer(i))
	out.append_array(_men(d, i))
	return out


## The cast's words: what, and on whom.
static func _said(what: String, i: int, who: String) -> String:
	return "%s (standard %d: %s)" % [what, i, who]


# --- Ruin: Smite, Heaven Splitter, Orbital Strike ---

## Heaven Splitter across the file when the file fits its core (BH_HEAVEN_FIT, led by its T_STRIKE): the three fall together and nobody is left to take the
## standard up. Else Smite: the escorts one by one, then the bearer (10 s apart). Between two bearers, Smite fells an escort of the muster next to be raised
## (BH_PREP). Orbital Strike falls at random and is not cast.
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var heaven: bool = bc._slot_ready(rules, slots, "heaven")
	var smite: bool = bc._slot_ready(rules, slots, "smite")
	for i in _marching(d):
		var file := _file(d, i)
		var men := _men(d, i)
		if heaven and file.size() >= 2:
			var aim := _enclose(_led(file, HEAVEN.T_STRIKE))
			if float(aim.r) <= BH_HEAVEN_FIT:
				rules.cast(int(slots.heaven), aim.at, {"dir": d._heading(i)})
				return _said("heaven splitter along the file", i, "%d of the file" % file.size())
		if smite:
			var target: Person = _nearest(men, d.bearer(i).ground_pos) if not men.is_empty() else d.bearer(i)
			rules.cast(int(slots.smite), GOD.road_ahead(target, SmiteFx.T_STRIKE))
			return _said("smite", i, "an escort" if not men.is_empty() else "the bearer")
	var n := d.next_step()
	if smite and n >= 0 and d.due_in(n) <= BH_PREP:
		var waiting := _men(d, n)
		if not waiting.is_empty():
			rules.cast(int(slots.smite), waiting[0].ground_pos)
			return _said("smite an escort of the muster", n, "before his raise")
	return ""


# --- Death: Death Mark, Pestilence, Glacial Cataclysm ---

## Death Mark on an escort not yet marked (he is frail and no guard at once, and dies in 10 s), the other escort next, last the bearer: a cast every 20 s. Pestilence
## on the bearer and the escort beside him when a standard is within BH_PLAGUE_ETA of its house (the plague takes the nearest three within 1.2 of the aim and they
## die together PLAGUE_LIFE on). Between two bearers Death Mark falls on an escort of the muster next to be raised. Glacial Cataclysm is loud (it turns the Lantern's
## clock) and is not cast.
static func act_death(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var mark: bool = bc._slot_ready(rules, slots, "deathmark")
	for i in _marching(d):
		var file := _file(d, i)
		var men := _men(d, i)
		var unmarked: Array[Person] = []
		for m in men:
			if not m.statuses.has(&"frail") and m.sick_left <= 0.0:
				unmarked.append(m)
		var b := d.bearer(i)
		if bc._slot_ready(rules, slots, "pestilence") and d.eta(i) <= BH_PLAGUE_ETA and b.sick_left <= 0.0:
			var mid := b.ground_pos if men.is_empty() else (b.ground_pos + _nearest(men, b.ground_pos).ground_pos) * 0.5
			var spot: Vector2 = GOD.plague_aim(crowd, mid)
			if spot != Vector2.INF and PestilenceFx.victims_at(crowd._field, spot).has(b):
				rules.cast(int(slots.pestilence), spot)
				return _said("pestilence", i, "the bearer, a house near")
		if mark:
			if not unmarked.is_empty():
				rules.cast(int(slots.deathmark), _nearest(unmarked, b.ground_pos).ground_pos)
				return _said("death mark", i, "an escort")
			if men.is_empty() and not b.statuses.has(&"frail") and b.sick_left <= 0.0:
				rules.cast(int(slots.deathmark), b.ground_pos)
				return _said("death mark", i, "the bearer")
	var n := d.next_step()
	if mark and n >= 0 and d.due_in(n) <= BH_PREP:
		for m in _men(d, n):
			if not m.statuses.has(&"frail"):
				rules.cast(int(slots.deathmark), m.ground_pos)
				return _said("death mark an escort of the muster", n, "before his raise")
	return ""


# --- Veil: Silent Doom, Blight, Nuclear Nova ---

## Silent Doom on each escort (one each: they stand 2.6 apart), then on the bearer, 10 s apart from the raise: three casts in 20 s, so the 45 s chain between two
## bearers never leaves a stretch of idle over 45 s and no work is done ahead of the raise. Blight ruins the Bell Tower first, so the bell never tolls and the
## Lantern never turns the clock.
static func act_veil(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not ctx.memo.has("blighted") and bc._slot_ready(rules, slots, "blight"):
		ctx.memo["blighted"] = true
		rules.cast(int(slots.blight), City.current().landmark(&"bell_tower").get_center())
		return "blight the Bell Tower (no toll all night)"
	if not bc._slot_ready(rules, slots, "doom"):
		return ""
	for i in _marching(d):
		var men := _men(d, i)
		var b := d.bearer(i)
		var target: Person = _nearest(men, b.ground_pos) if not men.is_empty() else b
		rules.cast(int(slots.doom), GOD.road_ahead(target, SilentDoom.T_STRIKE))
		return _said("doom", i, "an escort" if not men.is_empty() else "the bearer")
	var n := d.next_step()
	if n >= 0 and d.due_in(n) <= BH_PREP and not ctx.memo.has("prep_%d" % n):
		var waiting := _men(d, n)
		if not waiting.is_empty():
			ctx.memo["prep_%d" % n] = true
			rules.cast(int(slots.doom), waiting[0].ground_pos)
			return _said("doom an escort of the muster", n, "before his raise")
	return ""


# --- Passage: Thornwall, Mirrorfold Passage ---

## A thornwall goes across the street this far ahead of a standard's bearer; a mirror's way in is laid this far ahead (and, with a wall up, this far beyond it).
const BH_THORN_AHEAD := 4.0
const BH_MIRROR_AHEAD := 3.5
## A mirror laid on a muster's street before the raise lies this far from the muster, so the company standing there (a file 2.6 long) is not already on it: whoever is on
## the way in when it is laid is left alone until he steps off and back on.
const BH_MIRROR_MUSTER := 6.0
## How far past the wall's margin the mirror's way out lies (the oval is 2.4 across).
const BH_MIRROR_BEYOND := 2.0
## A standard with less than this many seconds to its house is not walled (the wall holds him 25 s, but a house this near is lost before the mirror cools).
const BH_THORN_ETA := 12.0
## How long a thornwall stands (Thornwall's THORN_TIME).
const THORN_FX := preload("res://src/fx/control/thornwall.gd")


## The street's polyline from `from` to `to` along the walk grid (the first point is `from`); just `from` when there is no way.
static func _line(crowd: Crowd, from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array([from])
	out.append_array(crowd._grid.path(from, to))
	return out


## The point `dist` along the polyline `line` (its end when shorter); INF for none.
static func _line_at(line: PackedVector2Array, dist: float) -> Vector2:
	if line.is_empty():
		return Vector2.INF
	var at := line[0]
	var left := dist
	for k in range(1, line.size()):
		var seg := at.distance_to(line[k])
		if seg >= left:
			return at.move_toward(line[k], left)
		left -= seg
		at = line[k]
	return at


## `g` is out of the walls by BH_MIRROR_BEYOND more than the margin.
static func _well_outside(g: Vector2) -> bool:
	return not City.current().town().grow(Walls.MARGIN + BH_MIRROR_BEYOND).has_point(g)


## Whoever steps onto the way in is set down at the way out plus his offset from the way in's middle (MirrorfoldFx._fold_step()), at the first step onto
## it -- and left to walk on across it, for good, if that is not walkable -- so every point of the oval round the way out must be walkable ground out of
## the walls, and its middle well out of them.
static func _lands(crowd: Crowd, g: Vector2) -> bool:
	if not _well_outside(g):
		return false
	for u in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		for v in [-1.0, 0.0, 1.0]:
			var at: Vector2 = g + MirrorfoldFx.ACROSS * (u * MirrorfoldFx.HALF_WIDE) + MirrorfoldFx.DOWN * (v * MirrorfoldFx.HALF_DEEP)
			if not crowd._grid.walkable(at) or not Walls.outside(at):
				return false
	return true


## Walkable ground well out of the walls nearest `from` and at least a mirror's MIN_APART from it, within 30 units; INF for none.
static func _exit_spot(crowd: Crowd, from: Vector2) -> Vector2:
	var best := Vector2.INF
	var dist := MirrorfoldFx.MIN_APART + 0.3
	while dist <= 30.0 and best == Vector2.INF:
		for k in 36:
			var g := from + Vector2.from_angle(TAU * float(k) / 36.0) * dist
			if not _lands(crowd, g):
				continue
			if best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from):
				best = g
		dist += 1.0
	return best


## A Mirrorfold laid across `line` at `ahead` along it, its way out past the wall; true when it was cast.
static func _mirror_on(bc, ctx: Dictionary, line: PackedVector2Array, ahead: float) -> bool:
	var way_in := _line_at(line, ahead)
	if way_in == Vector2.INF or Walls.outside(way_in):
		return false
	var way_out := _exit_spot(ctx.crowd, way_in)
	if way_out == Vector2.INF or way_in.distance_to(way_out) < MirrorfoldFx.MIN_APART:
		return false
	return GOD.cast_mirror(bc, ctx, way_in, way_out)


## A thornwall across `line` BH_THORN_AHEAD along it, kept in the memo under `key` with the street it shuts.
static func _wall_on(rules: Rules, slots: Dictionary, memo: Dictionary, key: String, line: PackedVector2Array, now: float) -> void:
	var spot := _line_at(line, BH_THORN_AHEAD)
	var dir := (_line_at(line, BH_THORN_AHEAD + 1.0) - _line_at(line, BH_THORN_AHEAD - 1.0)).normalized()
	memo[key] = {"t": now, "line": line}
	rules.cast(int(slots.thorns), spot, {"dir": dir.orthogonal() if dir.length() > 0.1 else Vector2.RIGHT})


## The street first, then the file out of the walls. Mirrorfold across the street ahead of a marching bearer (his file walks into it, comes out past the wall
## and is stopped there: walls_stop), laid beyond a thornwall when he is shut in behind one; when the mirror is cooling, a Thornwall across his street holds
## him (25 s) until it is ready. Between two bearers the same for the muster next to be raised: the mirror waiting on its street, or the wall that holds it.
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var memo: Dictionary = ctx.memo
	var now := _now(d)
	var mirror: bool = bc._slot_ready(rules, slots, "mirror")
	var thorns: bool = bc._slot_ready(rules, slots, "thorns")
	for i in _marching(d):
		var b := d.bearer(i)
		var line := _line(crowd, b.ground_pos, d.house_doors[d._dest[i]])
		var wall: Variant = memo.get("wall_%d" % i)
		var walled: bool = wall != null and now - float(wall.t) < THORN_FX.THORN_TIME
		if mirror and not memo.has("mirror_%d" % i):
			var ahead := BH_MIRROR_AHEAD
			var use := line
			if walled:
				use = wall.line
				ahead = BH_THORN_AHEAD + BH_MIRROR_AHEAD
			if _mirror_on(bc, ctx, use, ahead):
				memo["mirror_%d" % i] = now
				return _said("mirror the file out past the wall", i, "%.0f s from his house" % d.eta(i))
		elif thorns and not mirror and not memo.has("wall_%d" % i) and not memo.has("mirror_%d" % i) and d.eta(i) > BH_THORN_ETA and line.size() > 2:
			_wall_on(rules, slots, memo, "wall_%d" % i, line, now)
			return _said("thornwall across the street", i, "until the mirror is ready")
	var n := d.next_step()
	if n >= 0 and d.due_in(n) <= BH_PREP:
		var door: int = d._pick_dest(n)
		if door >= 0:
			var line := _line(crowd, d.steps[n].spot, d.house_doors[door])
			if mirror and not memo.has("mirror_%d" % n):
				if _mirror_on(bc, ctx, line, BH_MIRROR_MUSTER):
					memo["mirror_%d" % n] = now
					return _said("mirror laid on the street of the muster", n, "before the raise")
			elif thorns and not mirror and not memo.has("wall_%d" % n) and not memo.has("mirror_%d" % n) \
					and bc._slot_wait(rules, slots, "mirror") > d.due_in(n) and line.size() > 2:
				_wall_on(rules, slots, memo, "wall_%d" % n, line, now)
				return _said("thornwall across the street of the muster", n, "to hold it until the mirror is ready")
	return ""


# --- Decree: Leaving Is Prohibited, The Bell Lies, Magnify ---

## The law is laid this many seconds ahead of the bearer's walk (NoLeaveFx.T_SEAL).
const BH_LAW_AHEAD := 0.6
## Leaving Is Prohibited (Decree): the hold lasts HOLD_TIME.
const LEAVING_FX := preload("res://src/fx/decree/leaving_is_prohibited.gd")


## A circle of Leaving Is Prohibited laid over standard `i` is still up (its HOLD_TIME from the cast, kept in the memo).
static func _held_circle(ctx: Dictionary, i: int) -> bool:
	var k := "circle_%d" % i
	return ctx.memo.has(k) and _now(ctx.d as BreakHuntDirector) - float(ctx.memo[k]) < LEAVING_FX.HOLD_TIME


## NO ROUTE (MS §9 open issue 1, ruling C9): nothing in Decree kills, frightens or moves a man. The best it has is delay: Leaving Is Prohibited laid over the
## soonest bearer, ahead of his walk, whenever it is ready, so the circle holds him and his escorts for its 15 s. It cannot break a standard, so the night is
## lost at the second house or at dawn; recorded as it falls, never tuned around. The Bell Lies (CALL THE GUARD answers soldiers, and these escorts are lay) and
## Magnify (doubles what is already there) stop no one and are not cast.
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not bc._slot_ready(rules, slots, "noleave"):
		return ""
	for i in _marching(d):
		if _held_circle(ctx, i):
			continue
		ctx.memo["circle_%d" % i] = _now(d)
		rules.cast(int(slots.noleave), GOD.road_ahead(d.bearer(i), BH_LAW_AHEAD))
		return _said("law over the bearer", i, "to delay him")
	return ""


# --- Dominion: Mind Whisper, Discord, Turncoat ---

## Mind Whisper's reach, less a little for the walk's start; the longest hop it sends a bearer.
const BH_WHISPER_REACH := MindWhisperFx.REACH - 0.5
## The whisper that takes a bearer out of the walls is cast this long after the Discord that held him (it lifts after 15 s).
const BH_DOM_GAP := 15.0


## Walkable ground out of the walls within a whisper's reach of `w` as the crow flies, the nearest by his walk; INF for none.
static func _out_spot(bc, crowd: Crowd, w: Person) -> Vector2:
	var best := Vector2.INF
	var best_way := INF
	for rad: float in [1.0, 2.0, 3.0, 4.0, 5.0, 6.5, 8.0, BH_WHISPER_REACH]:
		for k in 24:
			var g: Vector2 = crowd._grid.nearest_walkable(w.ground_pos + Vector2.from_angle(TAU * float(k) / 24.0) * rad, 2)
			if g == Vector2.INF or not Walls.outside(g) or g.distance_to(w.ground_pos) > BH_WHISPER_REACH:
				continue
			var way: float = bc._walk_len(crowd, w.ground_pos, g)
			if way < best_way:
				best = g
				best_way = way
	return best


## Out of the walls. Mind Whisper sends the bearer to the ground out of the walls within its reach of where he stands, the nearest by his walk; he walks there by the
## street, held by the whisper the whole way (a whispered man walks slowly), and out of the walls his standard is broken. The opener is Discord on him as he
## sets out (he forgets his errand for 15 s: the file stands about), the finisher the whisper BH_DOM_GAP seconds on, as Discord lifts (a held real cast: the
## whisper reaches him as well at his raise, but then the clock between two casts is the 50 s of the schedule, not the 45 s the idle rule allows).
static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var memo: Dictionary = ctx.memo
	var now := _now(d)
	for i in _marching(d):
		var b := d.bearer(i)
		if b.mind == Person.Mind.WHISPERED and b.has_goal():
			continue  # on his way out
		var opened := "opened_%d" % i
		var whisper: bool = bc._slot_ready(rules, slots, "whisper") and not b.shaken() and b.mind != Person.Mind.WHISPERED
		if not memo.has(opened) and bc._slot_ready(rules, slots, "discord") and b.mind != Person.Mind.CONFUSED:
			memo[opened] = now
			rules.cast(int(slots.discord), b.ground_pos)
			return _said("discord the bearer", i, "the opener")
		if whisper and (not memo.has(opened) or now - float(memo[opened]) >= BH_DOM_GAP):
			var spot := _out_spot(bc, crowd, b)
			if spot != Vector2.INF:
				rules.cast(int(slots.whisper), b.ground_pos, {"target": b, "to": spot})
				return _said("whisper the bearer", i, "out of the walls")
	return ""
