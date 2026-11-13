extends RefCounted
## The scripted policies of the Hunt "Expel the inquisitor" (Tier 3; god P5, MS §7, plan Tasks 3, 6, 11): the shared plan with the def's loadout
## (act_shared), one act_<type> per god type, and the report line (state). FILLED lists the types written. Called by god_hunts.gd (Ruling P5-7:
## the policies live here, behaviour_check is never edited by a Hunt task). Each type plays the "Plays" row of MS §4 with the keys of LOADOUT:
##   ruin     Smite each warden and the captain, led ahead of his walk; Light of Solaris and Tornado on him when the bolt is cooling;
##            the next warden's guard is struck at his door while he waits indoors.
##   death    Death Mark on a man with 11 s of street left (a marked man indoors at the fuse lives); Pestilence when the mark cannot be laid;
##            Gravecall on the captain's last leg (a fright: he hides in the Temple); Death Mark on the next warden's guard while the warden waits.
##   veil     Blight the Bell Tower early (a seen death then rings nothing), Silent Doom aimed to take the guard with the man (_doom_aim());
##            Doom on the next warden's guard while he waits.
##   passage  Skylift a man in the street, the captain first, out past the wall (walls stop him); Mirrorfold laid across a man's road with
##            its way out past the wall while the lift cools; a Windfall of stone crushes the next warden's guard at his door while he waits.
##   decree   Leaving Is Prohibited over a man in the street (or at the door he is about to come out of), then Breathing Is Prohibited on him
##            where the cell holds him (the user's Decree tree, 2026-11-12; MS §9 open issue 1 found no route in the old keys); the same two on the
##            next warden's guard at his door.
##   dominion Mind Whisper in relayed hops toward the way off the map, wardens and captain alike; Madness Bloom on the captain's company
##            when the whisper is cooling.

## The god types whose policy is written (all six).
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## The shared policy pieces (god T1R, Ruling P5-7): road_ahead() and the filler words, reached through the Hunts' common file.
const GOD := preload("res://tools/dev/routes/god_t1.gd")

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(3) Might at level 1, all in GodTree.keys_for(type, 3)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "solaris", "tornado"],
	"death": ["deathmark", "pestilence", "gravecall"],
	"veil": ["doom", "blight", "nova"],
	"passage": ["skylift", "windfall", "mirror"],
	"decree": ["noleave", "breath"],
	"dominion": ["whisper", "discord", "madness"],
}

const B := preload("res://tools/dev/routes/tier1_b.gd")
## Ruin: the seconds since a man first came out before a Smite is struck where he would be seen (a seen death tolls the bell).
const RUIN_PATIENCE := 6.0
## Ruin: the guard at the next man's door is struck in the last this many seconds of the wait, so the bolt that kills him (after the patience) is not
## 50 s after the last cast (Task 11 round 2: the first warden at 44 s printed idle 50).
const RUIN_PREP_LEAD := 24.0
## A guard counts as at the door when he stands within this of it (the door ring is 1 unit; the captain's guards stand up to 1.6 off).
const DOOR_REACH := 3.0
## Death: the seconds either side of the fuse (MARK_TIME 10) a marked man must be out of doors for the mark to take him (a man indoors at the
## fuse lives), and the captain's countdown (real seconds) at or under which Gravecall is spent on his last leg.
const DEATH_MARGIN := 0.8
const GRAVE_ETA := 30.0
## Passage: how far along his road the way in is laid, the least road ahead of him that takes it (else the road from his next door), and the
## seconds before another is laid for the same man (a mirror lasts 30).
const MIRROR_ON := 6.0
const MIRROR_ROAD := 5.0
const MIRROR_RETRY := 40.0
## Passage: how far past the wall's margin the way out (and the Skylift's setting down) lies (the oval is 2.4 across).
const MIRROR_BEYOND := 2.0
## Passage: the guard at the next man's door is crushed in the last this many seconds of the wait (Ruin's RUIN_PREP_LEAD), and the Windfall line laid
## through him keeps more than FALL_CLEAR off the door (so no heap bars the man's way out) and off the other guards.
const FALL_PREP_LEAD := 24.0
const FALL_CLEAR := WindfallFx.KILL_R + 0.25
## Passage: a man lifted is left alone this long: the light takes him T_TAKE after the cast, and the director's next look finds him out of the walls.
const LIFT_HOLD := SkyliftFx.T_TAKE + 1.0
## Decree: the seconds from the cell's cast to the breath stopping a man in it (the seal, a look, the air going: he then stands choking), and the
## door's ring with a step's slack: a man nearer his door than his walk in that time and this is indoors before he is stopped (indoors the law
## leaves him alone), so the cell is not laid on him. The guard at the next warden's door is taken in the last DECREE_PREP_LEAD seconds of the wait
## (the breath's 25 s cooldown is then spent by the time the warden comes out), and at a visited door in the last LAW_DOOR_LEAD seconds of the
## visit (the seal, and a look).
const LAW_DOOR_LEAD := NoLeaveFx.T_SEAL + 0.3
const LAW_TO_BREATH := NoLeaveFx.T_SEAL + BreathFx.T_LAND + 0.3
const LAW_DOOR_CLEAR := 1.5
const DECREE_PREP_LEAD := 30.0
## Dominion: how far a hop of the whisper goes (REACH is 10).
const WHISPER_HOP := 9.0


## The numbers this Hunt's report lines print: each target's state and leg (behaviour_check's _tax_states(): W waiting, A walking, V visiting, F
## fleeing, H hiding, S safe, D dead, O out of the walls), the dead and the stopped, the counted frights and whether the captain fled.
static func state(bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as ExpelInquisitorDirector
	if d == null:
		return ""
	return "states=%s killed=%d stopped=%d frights=%d fled=%s" % [bc._tax_states(d), d.killed(), d.stopped(), d.frights(), d.fled()]


## The targets in the street now (walking or fleeing, alive, out of doors), the captain first, then the wardens in their order.
static func _street(d: ExpelInquisitorDirector) -> Array[AssassinateDirector.Quarry]:
	var out: Array[AssassinateDirector.Quarry] = []
	for q in d.quarries:
		if q.dead or not q.state in [AssassinateDirector.State.WALKING, AssassinateDirector.State.FLEEING]:
			continue
		if not MissionDirector._alive(q.target) or (q.target as Person).inside:
			continue
		if d._is_captain(q):
			out.insert(0, q)
		else:
			out.append(q)
	return out


## Where a Silent Doom cast now lands to take `q`'s man: on him where he stands now, for the Doom takes whoever stands within its RADIUS at the
## cast and they fall T_STRIKE later wherever they have walked (a lead ahead of a fast walker, 0.86 at the top pace, is a miss -- found in Task
## 11). A target with a guard within a Doom's reach of the midpoint is aimed at the midpoint, so the guard falls with him and nobody is left to
## cry murder.
static func _doom_aim(q: AssassinateDirector.Quarry) -> Vector2:
	var at: Vector2 = q.target.ground_pos
	var best := at
	var best_gap := INF
	for g: Variant in q.guards:
		if not MissionDirector._alive(g) or (g as Person).inside:
			continue
		var there: Vector2 = (g as Person).ground_pos
		var mid := (at + there) * 0.5
		var gap := at.distance_to(there)
		if gap <= SilentDoom.RADIUS * 1.6 and gap < best_gap:
			best = mid
			best_gap = gap
	return best


## The shared plan with the def's own loadout (no `--god`: Silent Doom, Smite, Mind Whisper), one look: the first target in the street (the
## captain first) is struck, Silent Doom aimed to take his guard with him if one stands near (_doom_aim()), else Smite led ahead of him. A kill
## seen only tolls the bell, and the Lantern turns: nothing is lost (MS §0). Returns what it cast, or "".
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	for q in _street(d):
		if bc._slot_ready(rules, slots, "doom"):
			rules.cast(int(slots.doom), _doom_aim(q))
			return "doom %s" % q.label
		if bc._slot_ready(rules, slots, "smite"):
			rules.cast(int(slots.smite), GOD.road_ahead(q.target, SmiteFx.T_STRIKE))
			return "smite %s" % q.label
	return ""


# --- Shared pieces ----------------------------------------------------------------------------------------------------------

## The second of the night (mission seconds): the director's clock.
static func _now(ctx: Dictionary) -> float:
	return float((ctx.d as AssassinateDirector)._clock)


## Mission seconds per real second (the Lantern's clock).
static func _rate(ctx: Dictionary) -> float:
	return maxf(float((ctx.rules as Rules).clock_rate), 0.01)


## The guards of the next target to set out, standing out of doors at his door, while nobody is out: the men a player strikes in the wait
## between one stopped and the next coming out, so the target comes out alone; with a `lead`, only in its last `lead` seconds. Empty when somebody
## is out, or the next target has none out. With a `reach`, only the guards standing within it of the door (the Bloom's, _bloom_aim()).
static func _door_guards(d: ExpelInquisitorDirector, lead := INF, reach := INF) -> Array[Person]:
	var out: Array[Person] = []
	var next := d._next_waiting()
	if d._anyone_out() or next == null or not MissionDirector._alive(next.target) or d.out_at(next.index) - d._clock > lead:
		return out
	var door: Vector2 = d.hide_door if d._is_captain(next) else next.stop_doors[0]
	for g: Variant in next.guards:
		if MissionDirector._alive(g) and not (g as Person).inside and (g as Person).ground_pos.distance_to(door) <= reach:
			out.append(g as Person)
	return out


## Where a Madness Bloom lands on the next target's guards at his door, or Vector2.INF: once for each target (`memo` keeps the ones done, _bloom_done()),
## and only on a guard standing within DOOR_REACH of his door -- the bloom takes the men who would stand by him, not one who has wandered off. A Bloom
## laid for any other reason is a filler (D38; review of Task 11, I1; Ruling P5-T11-R7).
static func _bloom_aim(d: ExpelInquisitorDirector, memo: Dictionary) -> Vector2:
	var next := d._next_waiting()
	if next == null or memo.has("bloom_%d" % next.index):
		return Vector2.INF
	for g in _door_guards(d, INF, DOOR_REACH):
		return g.ground_pos
	return Vector2.INF


## The Bloom for the next target has been cast.
static func _bloom_done(d: ExpelInquisitorDirector, memo: Dictionary) -> void:
	var next := d._next_waiting()
	if next != null:
		memo["bloom_%d" % next.index] = true


## The length of the street walk from `a` to `b` (straight when the grid finds no path).
static func _road_len(ctx: Dictionary, a: Vector2, b: Vector2) -> float:
	var at := a
	var len_ := 0.0
	for step in (ctx.crowd as Crowd)._grid.path(a, b):
		len_ += at.distance_to(step)
		at = step
	return len_ + at.distance_to(b)


## The door `q` goes to after the one he is bound for or in: a warden's round loops, the captain's runs on to the waypoint, then the gate.
static func _next_goal(ctx: Dictionary, q: AssassinateDirector.Quarry) -> Vector2:
	var d := ctx.d as ExpelInquisitorDirector
	var n := q.stops.size()
	if d._is_captain(q):
		if q.leg + 1 < n:
			return q.stop_doors[q.leg + 1]
		return d._walkable(ExpelInquisitorDirector.EI_FINAL_WAYPOINT) if q.leg + 1 == n else d.safe_at
	return q.stop_doors[(q.leg + 1) % n]


## Whether `q`, marked now, is indoors `secs` seconds on: the rest of the road to his door at the pace of a marked man (DeathMarkFx.SLOW), the
## visit (EI_VISIT real seconds, or what is left of the one he is in), the road to the next door, and so on for a few legs. A man out of the
## walking states, or past his last stop (the Citadel is not a house), is never indoors.
static func _indoors_at(ctx: Dictionary, q: AssassinateDirector.Quarry, secs: float) -> bool:
	var d := ctx.d as ExpelInquisitorDirector
	var pace := maxf(q.target.walk_speed * DeathMarkFx.SLOW, 0.1)
	var t := 0.0
	var leg := q.leg
	var from: Vector2 = q.target.ground_pos
	var n := q.stops.size()
	if q.state == AssassinateDirector.State.VISITING:
		if secs < q.indoors_left:
			return true
		t = q.indoors_left
		from = q.stop_doors[leg]
		leg += 1
	elif q.state != AssassinateDirector.State.WALKING:
		return false
	for _i in 4:
		if leg >= n:
			if d._is_captain(q) or leg > n:
				return false  # the captain's last leg: no house ahead
			leg = 0
		var door: Vector2 = q.stop_doors[leg]
		t += _road_len(ctx, from, door) / pace
		if secs < t:
			return false
		t += d.visit_seconds
		if secs < t:
			return true
		from = door
		leg += 1
	return false


## A Death Mark laid on `q` now finds him in the open when its fuse burns (a margin either side of MARK_TIME).
static func _mark_holds(ctx: Dictionary, q: AssassinateDirector.Quarry) -> bool:
	var d := ctx.d as ExpelInquisitorDirector
	if d._is_captain(q) and d._warned(q):
		return d.captain_eta() / _rate(ctx) / DeathMarkFx.SLOW >= DeathMarkFx.MARK_TIME + DEATH_MARGIN
	for slack: float in [-DEATH_MARGIN, 0.0, DEATH_MARGIN]:
		if _indoors_at(ctx, q, DeathMarkFx.MARK_TIME + slack):
			return false
	return true


# --- Ruin ---------------------------------------------------------------------------------------------------------------------

## Smite each man in the street, the captain first, led ahead of his walk, where nobody would see him fall (a seen death tolls the bell and
## hastens dawn) -- or once RUIN_PATIENCE seconds have passed since he first came out, or on the captain's last leg; Light of Solaris where he will stand
## when its pillar opens (T_CHARGE), and Tornado on him, when the bolt is cooling and the patience is spent. With no one in the street, a Smite on the next
## warden's guard at his door. (2026-11-02: Solaris replaces Heaven Splitter, out of Ruin's real tree; Dragonfire Parade breathes one way only and Scatter
## Strike falls at random, so neither is drafted.)
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var street := _street(d)
	for q in street:
		var p: Person = q.target
		var key := "street_%d" % q.index
		if not ctx.memo.has(key):
			ctx.memo[key] = _now(ctx)  # when he first came out into the street
		var waited := _now(ctx) - float(ctx.memo[key])
		var urgent := d._is_captain(q) and d._warned(q)
		var fall: Vector2 = GOD.road_ahead(p, SmiteFx.T_STRIKE)
		if bc._slot_ready(rules, slots, "smite") and (urgent or waited >= RUIN_PATIENCE or B._tax_smite_unseen(ctx.crowd, p, fall)):
			rules.cast(int(slots.smite), fall)
			return "smite %s" % q.label
		if not (urgent or waited >= RUIN_PATIENCE):
			continue
		if bc._slot_ready(rules, slots, "solaris"):
			rules.cast(int(slots.solaris), GOD.road_ahead(p, LightOfSolaris.T_CHARGE))
			return "solaris %s" % q.label
		if bc._slot_ready(rules, slots, "tornado"):
			rules.cast(int(slots.tornado), GOD.road_ahead(p, 1.0))
			return "tornado %s" % q.label
	if street.is_empty() and bc._slot_ready(rules, slots, "smite"):
		for g in _door_guards(d, RUIN_PREP_LEAD):
			rules.cast(int(slots.smite), g.ground_pos)
			return "smite the guard at the door"
	return ""


# --- Death --------------------------------------------------------------------------------------------------------------------

## Death Mark on a man the fuse will find out of doors (_mark_holds(): his round's visits are walked forward at the marked pace); Gravecall on the
## captain once his countdown reads GRAVE_ETA or less and the mark cannot take him: its wraiths rise and haunt where he will stand at T_RISE (both
## clicks on that spot), a loud danger within his alarm reach, so it counts a fright and he runs to hide in the Temple, off the Citadel's road (his
## guards are frozen as the wraiths pass them); Pestilence on a man the mark cannot take. With no one in the street, a Death Mark on the next warden's
## guard at his door. (Corpse Guise, Walking Corpse and Raise the Dead answer nothing here: nobody of the god's is hunted, and no body lies in a man's
## way.)
static func act_death(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var mark_ready: bool = bc._slot_ready(rules, slots, "deathmark")
	for q in _street(d):
		var p: Person = q.target
		if p.statuses.has(&"frail") or p.sick_left > 0.0:
			continue  # his fuse is lit
		if mark_ready and _mark_holds(ctx, q):
			rules.cast(int(slots.deathmark), p.ground_pos)
			return "death mark %s" % q.label
		if d._is_captain(q) and d._warned(q) and d.captain_eta() / _rate(ctx) <= GRAVE_ETA and bc._slot_ready(rules, slots, "gravecall"):
			var at: Vector2 = GOD.road_ahead(p, GravecallFx.T_RISE)
			rules.cast(int(slots.gravecall), at, {"to": at})
			return "gravecall %s on his last leg: a fright, and he hides" % q.label
		if bc._slot_ready(rules, slots, "pestilence"):
			var aim: Vector2 = GOD.plague_aim(crowd, p.ground_pos)
			if aim != Vector2.INF and PestilenceFx.victims_at(crowd._field, aim).has(p):
				rules.cast(int(slots.pestilence), aim)
				return "pestilence %s and those about him" % q.label
	if mark_ready:
		for g in _door_guards(d):
			rules.cast(int(slots.deathmark), g.ground_pos)
			return "death mark the guard at the door"
	return ""


# --- Veil ---------------------------------------------------------------------------------------------------------------------

## Blight the Bell Tower early (a seen death then rings nothing); Silent Doom on each man in the street, the captain first, aimed to take the
## guard beside him with him (_doom_aim()). With no one in the street, a Doom on the next warden's guard at his door.
static func act_veil(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var tower: Structure = crowd.bell.tower if crowd.bell != null else null
	var cracked := tower == null or not is_instance_valid(tower) or tower.blighted or tower.destroyed
	var street := _street(d)
	if not cracked and street.is_empty() and bc._slot_ready(rules, slots, "blight") and _now(ctx) >= 5.0:
		rules.cast(int(slots.blight), tower.center())
		return "blight the Bell Tower, so a seen death rings nothing"
	if not bc._slot_ready(rules, slots, "doom"):
		return ""
	for q in street:
		rules.cast(int(slots.doom), _doom_aim(q))
		return "doom %s" % q.label
	for g in _door_guards(d):
		rules.cast(int(slots.doom), g.ground_pos)
		return "doom the guard at the door"
	return ""


# --- Passage ------------------------------------------------------------------------------------------------------------------

## The walkable ground nearest `from` that lies MIRROR_BEYOND past the wall's margin on every side of a 1-unit ring (so a man put there is out of the
## walls for the director's next look and cannot walk back in before it); Vector2.INF when there is none within 30 units.
static func _exit_spot(ctx: Dictionary, from: Vector2) -> Vector2:
	var grid: WalkGrid = ctx.crowd._grid
	var best := Vector2.INF
	var dist := 1.0
	while dist <= 30.0 and best == Vector2.INF:
		for i in 36:
			var g := from + Vector2.from_angle(TAU * float(i) / 36.0) * dist
			if not grid.walkable(g) or not _well_outside(g):
				continue
			if best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from):
				best = g
		dist += 1.0
	return best


## `g` and the ring of a unit round it are out of the walls by MIRROR_BEYOND more than the margin.
static func _well_outside(g: Vector2) -> bool:
	var town := City.current().town().grow(Walls.MARGIN + MIRROR_BEYOND)
	return not town.has_point(g)


## Where a mirror for `q` is laid: on the road he is walking, MIRROR_ON units on (when his way is at least MIRROR_ROAD long), else along the road
## he takes from his next door to the one after (the mirror lasts 30 s, so it waits for him while he visits). Vector2.INF when he has no road.
static func _mirror_in(ctx: Dictionary, q: AssassinateDirector.Quarry) -> Vector2:
	var p: Person = q.target
	var d := ctx.d as ExpelInquisitorDirector
	var from: Vector2 = p.ground_pos
	if q.state == AssassinateDirector.State.WALKING:
		var left := 0.0
		var at: Vector2 = p.ground_pos
		for k in range(p._leg, p._path.size()):
			left += at.distance_to(p._path[k])
			at = p._path[k]
		if left >= MIRROR_ROAD:
			return GOD.road_ahead(p, minf(left - 1.0, MIRROR_ON) / maxf(p.walk_speed, 0.1))
		from = d._leg_goal(q)
	elif q.state == AssassinateDirector.State.VISITING and q.leg < q.stop_doors.size():
		from = q.stop_doors[q.leg]
	else:
		return Vector2.INF
	var path: PackedVector2Array = (ctx.crowd as Crowd)._grid.path(from, _next_goal(ctx, q))
	var at2 := from
	var left2 := clampf(_road_len(ctx, from, _next_goal(ctx, q)) * 0.5, 1.5, MIRROR_ON * 0.67)
	for step in path:
		var seg := at2.distance_to(step)
		if seg >= left2:
			return at2.move_toward(step, left2)
		left2 -= seg
		at2 = step
	return Vector2.INF


## The Skylift for the first man in the street (the captain first): taken where he will stand when the light takes (T_TAKE on along his road), with
## whoever walks beside him, and set down out past the wall (_exit_spot()), where the walls stop him. While the lift cools, a Mirrorfold across the
## road of the first man out who has a road to lay it on, its way out past the wall. With nobody in the street, a Windfall of stone crushes a guard at
## the next man's door in the last FALL_PREP_LEAD seconds of the wait (Ruin's Smite there; a guard lifted out of the walls only walks back to his post),
## laid along the door's side so it bars no way out (_fall_dir()).
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var lift: bool = bc._slot_ready(rules, slots, "skylift")
	var street := _street(d)
	if lift:
		for q in street:
			var from: Vector2 = GOD.road_ahead(q.target, SkyliftFx.T_TAKE)
			var to := _exit_spot(ctx, from)
			if Walls.outside(from) or to == Vector2.INF:
				continue
			ctx.memo["lift_%d" % q.index] = _now(ctx)
			rules.cast(int(slots.skylift), from, {"to": to})
			return "skylift %s out past the wall, to (%.1f, %.1f)" % [q.label, to.x, to.y]
	var out: Array[AssassinateDirector.Quarry] = []
	for q in d.quarries:
		if not q.dead and q.state in [AssassinateDirector.State.WALKING, AssassinateDirector.State.VISITING] and MissionDirector._alive(q.target):
			if d._is_captain(q):
				out.insert(0, q)
			else:
				out.append(q)
	for q in out:
		var key := "mirror_%d" % q.index
		if not bc._slot_ready(rules, slots, "mirror") or _now(ctx) - float(ctx.memo.get(key, -999.0)) < MIRROR_RETRY \
				or _now(ctx) - float(ctx.memo.get("lift_%d" % q.index, -999.0)) < LIFT_HOLD:
			continue
		var way_in := _mirror_in(ctx, q)
		if way_in == Vector2.INF or Walls.outside(way_in):
			continue
		var way_out := _exit_spot(ctx, way_in)
		if way_out == Vector2.INF or way_in.distance_to(way_out) < MirrorfoldFx.OVAL_MIN_APART:
			continue
		if GOD.cast_mirror(bc, ctx, way_in, way_out):
			ctx.memo[key] = _now(ctx)
			return "mirror %s: in %.1f from him, out at (%.1f, %.1f)" % [q.label, way_in.distance_to(q.target.ground_pos), way_out.x, way_out.y]
	if street.is_empty() and bc._slot_ready(rules, slots, "windfall"):
		var guards := _door_guards(d, FALL_PREP_LEAD)
		for g in guards:
			var dir := _fall_dir(d, g, guards)
			if dir != Vector2.ZERO:
				rules.cast(int(slots.windfall), g.ground_pos, {"dir": dir, "mode": "stone"})
				return "windfall on the guard at the door"
	return ""


## The direction of a Windfall line through guard `g` at the next man's door: across the line from the door to him, so the line keeps FALL_CLEAR off the
## door and off the other guards `guards`; Vector2.ZERO when it cannot.
static func _fall_dir(d: ExpelInquisitorDirector, g: Person, guards: Array[Person]) -> Vector2:
	var next := d._next_waiting()
	var door: Vector2 = d.hide_door if d._is_captain(next) else next.stop_doors[0]
	var dir := (g.ground_pos - door).orthogonal().normalized()
	if dir == Vector2.ZERO:
		return dir
	var clear: Array[Vector2] = [door]
	for o in guards:
		if o != g:
			clear.append(o.ground_pos)
	for c in clear:
		var t := clampf((c - g.ground_pos).dot(dir), -WindfallFx.LENGTH * 0.5, WindfallFx.LENGTH * 0.5)
		if c.distance_to(g.ground_pos + dir * t) <= FALL_CLEAR:
			return Vector2.ZERO
	return dir


# --- Decree -------------------------------------------------------------------------------------------------------------------

## Whether `p` stands in a Leaving Is Prohibited cell now (he cannot run from a Breathing Is Prohibited laid on him).
static func _celled(ctx: Dictionary, p: Person) -> bool:
	return (ctx.crowd as Crowd).in_law(p, LawZone.NO_LEAVING)


## The cell and the breath, the two laws together a sure kill (spec 5.2), laid only when the breath is ready to follow the cell: Leaving Is
## Prohibited over the first man in the street (the captain first), ahead of his walk, while his door is farther than he walks before the breath
## stops him (indoors the law leaves him alone); else at the door of a man visiting there in the last LAW_DOOR_LEAD seconds of his visit, so he comes
## out into it (a warden's round is short legs and long visits). Then Breathing Is Prohibited on the man the cell holds: he cannot run for the edge,
## and three seconds kill him with whoever stands by him. With nobody in the street, the same two on the next warden's guard at his door in the last
## DECREE_PREP_LEAD seconds of the wait, so the warden comes out alone (Ruin's Smite there).
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not bc._slot_ready(rules, slots, "breath"):
		return ""
	var street := _street(d)
	var guards := _door_guards(d, DECREE_PREP_LEAD) if street.is_empty() else ([] as Array[Person])
	for q in street:
		if _celled(ctx, q.target):
			rules.cast(int(slots.breath), GOD.road_ahead(q.target, BreathFx.T_LAND))
			return "breathing is prohibited on %s, held in the cell" % q.label
	for g in guards:
		if _celled(ctx, g):
			rules.cast(int(slots.breath), g.ground_pos)
			return "breathing is prohibited on the guard at the door, held in the cell"
	if not bc._slot_ready(rules, slots, "noleave"):
		return ""
	for q in street:
		var reach: float = q.target.walk_speed * LAW_TO_BREATH + LAW_DOOR_CLEAR
		if q.state == AssassinateDirector.State.WALKING and q.target.ground_pos.distance_to(d._leg_goal(q)) <= reach:
			continue  # he is at his door before the breath stops him
		rules.cast(int(slots.noleave), GOD.road_ahead(q.target, NoLeaveFx.T_SEAL))
		return "leaving is prohibited round %s" % q.label
	for q in _visiting(d):
		if q.indoors_left <= LAW_DOOR_LEAD:
			rules.cast(int(slots.noleave), q.stop_doors[q.leg])
			return "leaving is prohibited at the door of %s, as he comes out" % q.label
	for g in guards:
		rules.cast(int(slots.noleave), g.ground_pos)
		return "leaving is prohibited round the guard at the door"
	return ""


## The targets visiting a stop now (alive, indoors at one of their round's doors), the captain first.
static func _visiting(d: ExpelInquisitorDirector) -> Array[AssassinateDirector.Quarry]:
	var out: Array[AssassinateDirector.Quarry] = []
	for q in d.quarries:
		if q.dead or q.state != AssassinateDirector.State.VISITING or not MissionDirector._alive(q.target) or q.leg >= q.stop_doors.size():
			continue
		if d._is_captain(q):
			out.insert(0, q)
		else:
			out.append(q)
	return out


# --- Dominion -----------------------------------------------------------------------------------------------------------------

## Mind Whisper in hops of WHISPER_HOP toward the way off the map along the road the grid gives, on the first man in the street who is free:
## a new hop when he has reached the last, always before the linger runs out, so he never turns back (Person.SHAKE_OFF); out of the walls he
## is stopped. With no one in the street, Madness Bloom once on the next target's guards at his door, while they stand at it (_bloom_aim()).
static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ExpelInquisitorDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var street := _street(d)
	if street.is_empty() and bc._slot_ready(rules, slots, "madness"):
		var aim := _bloom_aim(d, ctx.memo)
		if aim != Vector2.INF:
			_bloom_done(d, ctx.memo)
			rules.cast(int(slots.madness), aim)
			return "madness bloom on the guards at the door"
	if not bc._slot_ready(rules, slots, "whisper"):
		return ""
	for q in street:
		var p: Person = q.target
		if p.shaken() or (p.mind == Person.Mind.WHISPERED and p.has_goal()):
			continue  # on his way to the last hop, or shaking a whisper off
		var way := Walls.way_off(p.ground_pos)
		if way == Vector2.INF:
			continue
		var hop := Vector2.INF
		for step in crowd._grid.path(p.ground_pos, way):
			if step.distance_to(p.ground_pos) <= WHISPER_HOP:
				hop = step
			else:
				break
		if hop == Vector2.INF or hop.distance_to(p.ground_pos) < 1.0:
			continue
		rules.cast(int(slots.whisper), p.ground_pos, {"target": p, "to": hop})
		return "whisper %s %.1f toward the way off, to (%.1f, %.1f)" % [q.label, hop.distance_to(p.ground_pos), hop.x, hop.y]
	return ""
