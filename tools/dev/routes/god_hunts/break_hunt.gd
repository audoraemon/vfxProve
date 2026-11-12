extends RefCounted
## The scripted policies of the Hunt "Break the hunt" (Tier 4; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared), one
## act_<type> per god type, and the report line (state). All six types are written (Task 12); FILLED lists them. Decree's route came with the
## user's Decree tree (2026-11-12; MS §9 open issue 1 and ruling C9 reported none with its old keys). Called by god_hunts.gd (Ruling P5-7: the
## policies live here, behaviour_check is never edited by a Hunt task).

## The god types whose policy is written (all six, god P5 Task 12).
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(4) Might at level 1, all in GodTree.keys_for(type, 4)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "tornado"],
	"death": ["deathmark", "pestilence"],
	"veil": ["doom", "blight", "nova"],
	"passage": ["skylift", "windfall"],
	"decree": ["noleave", "breath"],
	"dominion": ["whisper", "discord", "sanctuary"],
}


## The shared policy pieces (god T1R, Ruling P5-7): road_ahead(), reached through the Hunts' common file.
const GOD := preload("res://tools/dev/routes/god_t1.gd")
## Heaven Splitter's script (it has no class name), for its strike time: the shared plan's, which plays the def's own loadout (no god tree).
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
## How far apart the file of a marching standard must fit for one wide strike (Tornado Tempest pulls all within its PULL_RADIUS, 3.2, into its core; the file is
## the bearer between two escorts 1.3 along the street each way), led by its T_FORM so the pull holds all of it before the funnel roams off.
const BH_TORNADO_FIT := 1.6
## Tornado Tempest's script (it has no class name), for the moment it forms.
const TORNADO := preload("res://src/fx/set2/tornado_tempest.gd")
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


# --- Ruin: Smite, Tornado Tempest ---

## Tornado Tempest on the file when the file fits well inside its pull (BH_TORNADO_FIT, led by its T_FORM): the three are drawn in together and nobody is left
## to take the standard up. Else Smite: the escorts one by one, then the bearer (10 s apart). Between two bearers, Smite fells an escort of the muster next to
## be raised (BH_PREP). (2026-11-02: Tornado replaces Heaven Splitter, out of Ruin's real tree; Scatter Strike and Cinderfall Barrage fall at random and are
## not drafted.)
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var tornado: bool = bc._slot_ready(rules, slots, "tornado")
	var smite: bool = bc._slot_ready(rules, slots, "smite")
	for i in _marching(d):
		var file := _file(d, i)
		var men := _men(d, i)
		if tornado and file.size() >= 2:
			var aim := _enclose(_led(file, TORNADO.T_FORM))
			if float(aim.r) <= BH_TORNADO_FIT:
				rules.cast(int(slots.tornado), aim.at)
				return _said("tornado on the file", i, "%d of the file" % file.size())
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


# --- Death: Death Mark, Pestilence ---

## Death Mark on an escort not yet marked (he is frail and no guard at once, and dies in 10 s), the other escort next, last the bearer: a cast every 20 s. Pestilence
## on the bearer and the escort beside him when a standard is within BH_PLAGUE_ETA of its house (the plague takes the nearest three within 1.2 of the aim and they
## die together PLAGUE_LIFE on). Between two bearers Death Mark falls on an escort of the muster next to be raised. Two keys are the whole answer: the quiet fuse
## breaks every standard short of its house. The Gate Below and Pale Reign are loud (they turn the Lantern's clock) and take whoever stands near; Corpse Guise and
## Walking Corpse answer a watch or a body, and the march has neither.
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


# --- Passage: Skylift, Windfall ---

## How far past the wall's margin the Skylift sets a bearer down.
const BH_LIFT_BEYOND := 2.0
## A bearer lifted is left alone this long: the light takes him T_TAKE after the cast, and the next look finds him out of the walls.
const BH_LIFT_HOLD := SkyliftFx.T_TAKE + 1.0
## A Windfall on an escort of the muster leaves the bearer and the other escort standing: each stands more than this from the line (its crush, KILL_R, and a
## step's slack).
const BH_FALL_CLEAR := WindfallFx.KILL_R + 0.25


## `g` is out of the walls by BH_LIFT_BEYOND more than the margin.
static func _well_outside(g: Vector2) -> bool:
	return not City.current().town().grow(Walls.MARGIN + BH_LIFT_BEYOND).has_point(g)


## Whoever the Skylift takes is set down at its second click plus his offset from the first, so the ground round `g` (a mirror's oval of it, the shape the
## mirror policy measured: MirrorfoldFx's ACROSS and DOWN) must be walkable ground out of the walls, and its middle well out of them.
static func _lands(crowd: Crowd, g: Vector2) -> bool:
	if not _well_outside(g):
		return false
	for u in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		for v in [-1.0, 0.0, 1.0]:
			var at: Vector2 = g + MirrorfoldFx.ACROSS * (u * MirrorfoldFx.HALF_WIDE) + MirrorfoldFx.DOWN * (v * MirrorfoldFx.HALF_DEEP)
			if not crowd._grid.walkable(at) or not Walls.outside(at):
				return false
	return true


## Walkable ground well out of the walls nearest `from` and at least a mirror's MIN_APART from it, within 30 units, where a Skylift sets a bearer down
## (_lands()); INF for none.
static func _exit_spot(crowd: Crowd, from: Vector2) -> Vector2:
	var best := Vector2.INF
	var dist := MirrorfoldFx.OVAL_MIN_APART + 0.3
	while dist <= 30.0 and best == Vector2.INF:
		for k in 36:
			var g := from + Vector2.from_angle(TAU * float(k) / 36.0) * dist
			if not _lands(crowd, g):
				continue
			if best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from):
				best = g
		dist += 1.0
	return best


## How far `p` stands from the Windfall line `length` long through `at` along `dir`.
static func _off_line(p: Vector2, at: Vector2, dir: Vector2, length: float) -> float:
	var t := clampf((p - at).dot(dir), -length * 0.5, length * 0.5)
	return p.distance_to(at + dir * t)


## A Windfall line through escort `e` of the muster `n`, laid along the bearer's side (across the line from the bearer to him) so that the bearer and the other
## escort stand clear of it (BH_FALL_CLEAR): its direction, or Vector2.ZERO when no such line spares them.
static func _fall_dir(d: BreakHuntDirector, n: int, e: Person) -> Vector2:
	var b := d.bearer(n)
	var others: Array[Vector2] = []
	if b != null:
		others.append(b.ground_pos)
	for m in _men(d, n):
		if m != e:
			others.append(m.ground_pos)
	var across := (e.ground_pos - b.ground_pos) if b != null else Vector2.RIGHT
	var dir := across.orthogonal().normalized() if across.length() > 0.1 else Vector2.RIGHT
	for o in others:
		if _off_line(o, e.ground_pos, dir, WindfallFx.LENGTH) <= BH_FALL_CLEAR:
			return Vector2.ZERO
	return dir


## The file out of the walls, in an opener and a finisher as the other types play it. The finisher: Skylift on a marching bearer where he will stand when the
## light takes (T_TAKE on along his walk), set down past the wall: out of the walls his standard breaks. The opener, between two bearers: a Windfall of stone
## crushes an escort of the muster next to be raised in the last BH_PREP seconds before the raise (a guard the bearer will not have), laid so it spares the
## bearer and the other escort (_fall_dir()).
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var memo: Dictionary = ctx.memo
	var now := _now(d)
	if bc._slot_ready(rules, slots, "skylift"):
		for i in _marching(d):
			if now - float(memo.get("lift_%d" % i, -99.0)) < BH_LIFT_HOLD:
				continue
			var from: Vector2 = GOD.road_ahead(d.bearer(i), SkyliftFx.T_TAKE)
			var to := _exit_spot(crowd, from)
			if to != Vector2.INF and not Walls.outside(from):
				memo["lift_%d" % i] = now
				rules.cast(int(slots.skylift), from, {"to": to})
				return _said("skylift the bearer out past the wall", i, "%.0f s from his house" % d.eta(i))
	var n := d.next_step()
	if bc._slot_ready(rules, slots, "windfall") and n >= 0 and d.due_in(n) <= BH_PREP:
		for e in _men(d, n):
			var dir := _fall_dir(d, n, e)
			if dir != Vector2.ZERO:
				rules.cast(int(slots.windfall), e.ground_pos, {"dir": dir, "mode": "stone"})
				return _said("windfall on an escort of the muster", n, "before his raise")
	return ""


# --- Decree: Leaving Is Prohibited, Breathing Is Prohibited ---

## The breath is laid where the file will stand when the air goes (BreathFx.T_LAND on), centred on the file when all of it fits within its RADIUS less
## this (a man at the rim is out of it by a step), else on the first of it.
const BH_BREATH_SLACK := 0.4
## The cell is not laid on a marching bearer whose house is nearer than this many seconds (the seal, a look, the air going: then he stands choking) and
## a step's slack: he would plant the standard before the breath stops him.
const BH_LAW_ETA := NoLeaveFx.T_SEAL + BreathFx.T_LAND + 1.0
## The cell is laid over a muster in the last this many seconds before its standard rises: its seal (NoLeaveFx.T_SEAL 0.6), a look and the director's
## own look (HuntDirector.TICK 0.5), with a little in hand, are spent before the raise, so the file is held where it stands as it rises and the breath
## follows at once (Face Halcyon's door law, LAW_LEAD there: the next is not 45 s plus the cast's delay after the last cast; seed 2's idle is 44).
const BH_LAW_LEAD := 2.0


## Whether `p` stands in a Leaving Is Prohibited cell now (he cannot run from a Breathing Is Prohibited laid on him).
static func _celled(ctx: Dictionary, p: Person) -> bool:
	return (ctx.crowd as Crowd).in_law(p, LawZone.NO_LEAVING)


## Where the breath takes `people` together: the middle of where they will stand when the air goes, when all of them fit in it; else on the first.
static func _breath_aim(people: Array[Person]) -> Vector2:
	var led := _led(people, BreathFx.T_LAND)
	var circle := _enclose(led)
	return circle.at if float(circle.r) <= BreathFx.RADIUS - BH_BREATH_SLACK else led[0]


## The cell and the breath, the two laws together a sure kill (spec 5.2), laid only when the breath is ready to follow the cell. Leaving Is Prohibited
## over the muster next to be raised in the last BH_LAW_LEAD seconds before its standard rises (the bearer and his escorts stand together there, 1.3
## apart), so the file is held where it stands as it rises; else over the file of a marching standard, centred on the bearer where he will be at the
## seal, while his house is more than BH_LAW_ETA off. Then Breathing Is Prohibited on the raised file the cell holds (_breath_aim()): nobody can run for
## the edge, and three seconds kill them together, so nobody is left to take the standard up.
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := _bh(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not bc._slot_ready(rules, slots, "breath"):
		return ""
	var marching := _marching(d)
	for i in marching:
		var held: Array[Person] = []
		for p in _file(d, i):
			if _celled(ctx, p):
				held.append(p)
		if not held.is_empty():
			rules.cast(int(slots.breath), _breath_aim(held))
			return _said("breathing is prohibited on the file held in the cell", i, "%d of the file" % held.size())
	if not bc._slot_ready(rules, slots, "noleave"):
		return ""
	var n := d.next_step()
	if n >= 0 and d.due_in(n) <= BH_LAW_LEAD and not _file(d, n).is_empty():
		rules.cast(int(slots.noleave), _enclose(_led(_file(d, n), NoLeaveFx.T_SEAL)).at)
		return _said("leaving is prohibited over the muster as its standard rises", n, "%d of the file" % _file(d, n).size())
	for i in marching:
		if d.eta(i) <= BH_LAW_ETA:
			continue  # he plants the standard before the breath stops him
		rules.cast(int(slots.noleave), GOD.road_ahead(d.bearer(i), NoLeaveFx.T_SEAL))
		return _said("leaving is prohibited round the file", i, "%.0f s from his house" % d.eta(i))
	return ""


# --- Dominion: Mind Whisper, Discord (Sacred Sanctuary drafted, not cast) ---

## (2026-11-06: Sacred Sanctuary replaces Turncoat, out of Dominion's real Tier 4; neither was ever cast here.)

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
