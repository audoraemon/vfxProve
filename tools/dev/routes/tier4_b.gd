extends RefCounted
## Tier 4 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes, kept the whole run), mission}, rebuilt at every look.
##
## The Procession (loadout smite, heaven, wisp, discord, deathmark), the Bishop (heaven, smite, whisper, discord, wisp), the Armoury
## (verdict, heaven, whisper, discord, wisp), the Sermon (wisp, discord, deathmark, belllies, thorns) and the Relic Run (wisp, discord,
## deathmark, oath, thorns). Each is worked as a player works the opposition: the strike where the mission lets it fall, the hold where
## the opposition would see.


const Tier3B := preload("res://tools/dev/routes/tier3_b.gd")

## How far Mind Whisper sends a Knight off his refuge's door (bishop).
const BISHOP_SENT := 4.0
const BISHOP_DIRS := 12
const BISHOP_LIGHT_R := 5.5


## How long after a Mob Verdict on a target the policy leaves it to the mob before it tries Heaven Splitter (MobVerdictFx.VERDICT_TIME and a
## margin for the mob's walk).
const ARMOURY_VERDICT_WAIT := 30.0
## The Relic Run's policy: how near the next checkpoint Pip counts as there (a Wisp lit at the cart then takes him), the margin inside
## WillOWisp.CHARGE_LURE_R a light is lit from him, how far from the cart the Oath sends the watch, and how far ahead of a halt a warden's
## Death Mark is cast beyond the halt's own lead (RELIC_AHEAD / RELIC_LEG of behaviour_check are the A policy's; these mirror them).
const RELIC_OATH_LEAD := 42.0
const RELIC_OATH_AHEAD := 58.0
const RELIC_HOP_MARGIN := 0.4
const RELIC_OATH_AWAY := 9.0
const RELIC_LURE := 4.0
const RELIC_DRAW := 0.0
const RELIC_GATHER := 0.7
const RELIC_GATHERED := 4
const RELIC_GATHER_WAIT := 10.0
const RELIC_AHEAD := 20.0
const RELIC_LEG := 35.0
const RELIC_LATE := 10.0
const RELIC_MARGIN := 0.15
## The rolling stretch's job: how far before a halt (s) a Death Mark may fall on a Faithful stroller, and how near the checkpoint he must stand.
const RELIC_STROLL_AHEAD := 80.0
const RELIC_STROLL_R := 8.0
## The Sermon's policy: how near a watcher of the door no one else may stand for a Death Mark on him (his death goes unseen), and how far
## inside the Wisp's reach a listener must stand for the light to count him (he walks while the cast lands).
const SERMON_MARK_ALONE := Crowd.DOOM_WITNESS
## How many seconds a ready Death Mark waits for a watcher of the door with no one by him before it takes the one with the fewest.
const SERMON_PATIENCE := 10.0
## The Gaze from which a seen death is not risked; the seconds a dead sentry's relief must still be away for the crowd to be sent; how soon
## the Wisp must be ready for the Discord on the pulpit to be cast.
const SERMON_SEEN_UNTIL := 70.0
const SERMON_HOLDS := 10.0
## Seconds into a Death Mark on the preacher that Discord is cast on the pulpit (the mark falls at DeathMarkFx.MARK_TIME, Discord holds 15 s), and the
## seconds before it falls from which a marked watcher no longer counts as one the crowd must be kept from.
const SERMON_HOLD_AT := 7.5
const SERMON_FALLS := 1.0
const SERMON_WISP_SOON := 2.0
const SERMON_LIGHT_MARGIN := 0.3
## How far Mind Whisper sends an armed man off his target (armoury).
const ARMOURY_SENT := 8.0
const ARMOURY_AHEAD := 25.0
const ARMOURY_DIRS := 12
const ARMOURY_LIGHT_R := 5.5


## Where `p` will stand `ahead` seconds on, walking the path it has now at its pace (a person with no goal stands). Only reads.
static func lead(p: Person, ahead: float) -> Vector2:
	if not p.has_goal():
		return p.ground_pos
	var left := p.walk_speed * ahead
	var at := p.ground_pos
	for k in range(p._leg, p._path.size()):
		var gap := at.distance_to(p._path[k])
		if gap >= left:
			return at.move_toward(p._path[k], left)
		left -= gap
		at = p._path[k]
	return at


## The Procession (board, ★): Death Mark on the Prince the moment he steps out of his carriage (EMERGE_AT, 36 s). RouteBook's row says the
## main step is a death (Smite proved a gamble, ruling in the Task 11 report): the cast is quiet, he grows frail and slow, and ten
## seconds on he dies wherever he stands -- out of doors, as he always is -- and his death is judged. A Smite, aimed where he will stand
## when its bolt lands, is taken by a standing Prince only by the width of KILL_R (the cast frightens him and he runs at once, 1.6 *
## pace * 0.35 s against 0.6), and missed by a walking one; the policy does not play it. One mark, ready again after 20 s: recast only if
## he lives past it (marked once, never twice).
static func act_procession(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ProcessionDirector
	if d == null or not d.under_way() or d.fallen():
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var p := d.prince
	if p.inside:
		return ""  # in his carriage nothing of the god's reaches him (the board's wait is EMERGE_AT, 36 s: no casts are padded into it)
	if p.statuses.has(&"frail") or not bc._slot_ready(rules, slots, "deathmark"):
		return ""
	rules.cast(slots.deathmark, p.ground_pos)
	return "death mark the Prince"


static func state_procession(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as ProcessionDirector
	if d == null:
		return ""
	return "prince=%s leg=%d fallen=%s boarded=%s" % [d.report().prince, d.leg, d.fallen(), d.boarded]


## The Bishop (loadout heaven, smite, whisper, discord, wisp): fell the refuge he is in with blows -- Heaven Splitter through it, Smite
## while Heaven cools -- which drives him out as a fire does, and no Knight beats a blow out; in the square, Smite him (he walks at half
## pace, so the bolt that frightens him lands on him), Heaven if Smite cools. A refuge he is not in yet is stone: nothing is cast at it.
static func act_bishop(bc, ctx: Dictionary) -> String:
	var d := ctx.d as BishopDirector
	if d == null or d.quarries.is_empty():
		return ""
	var q := d.quarries[0]
	if q.dead or not WarningDirector._alive(q.target):
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if d.in_square and not q.target.inside:
		var at := lead(q.target, SmiteFx.T_STRIKE)
		if bc._slot_ready(rules, slots, "smite"):
			rules.cast(slots.smite, at)
			return "smite the bishop"
		return ""
	var cur := d.current_refuge()
	if cur < 0 or not is_instance_valid(d.refuges[cur]) or d.refuges[cur].destroyed:
		return _bishop_ahead(bc, ctx, d, cur)
	var s := d.refuges[cur]
	var on := d.guards_at(cur)
	if not on.is_empty():
		# His Knights at the door turn blows aside (BishopDirector._seal_guarded()): a Will-o'-Wisp lit where it draws the most of them off
		# (they stand staring at the light, away from the door, and walk back after), else a whisper or Discord on one.
		var crowd: Crowd = ctx.crowd
		if bc._slot_ready(rules, slots, "wisp"):
			var best := Vector2.INF
			var best_n := 0
			for r in [3.0, 5.0, 7.0, 9.0, 12.0]:
				for k in BISHOP_DIRS:
					var at := d._walkable(s.center() + Vector2.from_angle(TAU * float(k) / float(BISHOP_DIRS)) * r)
					var gap := s.distance_to(at)
					if gap < BishopDirector.GUARD_REACH + WillOWisp.RING.y + 0.3 or gap > BISHOP_LIGHT_R:
						continue
					var n := 0
					for p in on:
						n += 1 if p.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH - 0.4 and not p.hurrying and p.mind == Person.Mind.POST else 0
					if n > best_n:
						best_n = n
						best = at
			if best != Vector2.INF:
				rules.cast(slots.wisp, best)
				return "wisp %d Knights off refuge %d" % [best_n, cur]
		for p in on:
			if p.held_by_god() or p.shaken():
				continue
			var away := p.ground_pos - s.center()
			var to := MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * BISHOP_SENT)
			if bc._slot_ready(rules, slots, "whisper"):
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": to})
				return "whisper a Knight off refuge %d" % cur
			if bc._slot_ready(rules, slots, "discord"):
				rules.cast(slots.discord, p.ground_pos)
				return "discord a Knight at refuge %d" % cur
		return ""
	if bc._slot_ready(rules, slots, "heaven"):
		rules.cast(slots.heaven, s.center(), {"dir": Vector2.RIGHT})
		return "heaven through refuge %d" % cur
	if bc._slot_ready(rules, slots, "smite"):
		rules.cast(slots.smite, s.center())
		return "smite refuge %d" % cur
	return ""


## Between refuges: the next refuge's Knights still at their posts are sent off or held, one at a time -- a whisper first (it cools in
## 8 s), Discord on one it will not take -- so that when he is in, no Knight stands at the door (they walk back when the hold lifts).
## The blows do not need it (a Knight beats out a fire, not a blow); a player who has nothing else to do clears the door.
static func _bishop_ahead(bc, ctx: Dictionary, d: BishopDirector, cur: int) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var nxt := d.next_refuge()
	if nxt < 0 or nxt == cur:
		return ""
	var crowd: Crowd = ctx.crowd
	for p in d.standing_at(nxt):
		if p.mind != Person.Mind.POST or p.shaken():
			continue
		var away := p.ground_pos - d.refuges[nxt].center()
		var to := MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * BISHOP_SENT)
		if bc._slot_ready(rules, slots, "whisper"):
			rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": to})
			return "whisper a Knight off refuge %d" % nxt
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, p.ground_pos)
			return "discord a Knight at refuge %d" % nxt
		return ""
	return ""


static func state_bishop(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as BishopDirector
	if d == null:
		return ""
	return "refuge=%d flight=%s square=%s driven=%d guards=%d reliefs=%d phase=%s" % [d.at_refuge, d.in_flight, d.in_square, d.driven,
		d.guards_at(d.current_refuge()).size() if d.current_refuge() >= 0 else 0, d.reliefs, d.hint_phase()]


## The Armoury (loadout verdict, heaven, whisper, discord, wisp): a target is stone until its horn (ArmouryDirector, v0.11.1), so the work
## is on the target that musters, against its armed men: Mob Verdict when it is ready (the first click on the building, the second on the
## crowd about it -- the circle takes the armed men within it too, and bound to the walls they no longer guard); else a Will-o'-Wisp lit
## where it draws the most of them off their posts (they stand staring at it away from the building), else a whisper or Discord on one;
## with none on guard, Heaven Splitter through it.
static func act_armoury(bc, ctx: Dictionary) -> String:
	var d := ctx.d as ArmouryDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var i := d.mustering_now()
	if i < 0:
		# Before the next horn, its night watch is thinned: a whisper (cooling in 8 s) sends one off the target, Discord holds another.
		var nxt := d.upcoming()
		if nxt >= 0 and d.due_in(nxt) <= ARMOURY_AHEAD:
			for p in d.guards(nxt):
				if p.held_by_god() or p.shaken():
					continue
				var away := p.ground_pos - d.targets[nxt].center()
				var to := MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * ARMOURY_SENT)
				if bc._slot_ready(rules, slots, "whisper"):
					rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": to})
					return "whisper a night watchman off the %s" % String(ArmouryDirector.WORDS[nxt])
				if bc._slot_ready(rules, slots, "discord"):
					rules.cast(slots.discord, p.ground_pos)
					return "discord a night watchman at the %s" % String(ArmouryDirector.WORDS[nxt])
		return ""
	var s := d.targets[i]
	if not is_instance_valid(s) or s.destroyed:
		return ""
	var word := String(ArmouryDirector.WORDS[i])
	var memo: Dictionary = ctx.memo
	var waiting: bool = d._clock - float(memo.get("verdict_%d" % i, -100.0)) < ARMOURY_VERDICT_WAIT
	if waiting:
		return ""  # its mob is at the walls: nothing else is wasted on what the verdict is taking down
	if bc._slot_ready(rules, slots, "verdict"):
		rules.cast(slots.verdict, s.center(), {"to": _armoury_mob(d, crowd, s)})
		memo["verdict_%d" % i] = d._clock
		return "mob verdict on the %s" % word
	var on := d.guards(i)
	if on.is_empty():
		if bc._slot_ready(rules, slots, "heaven"):
			rules.cast(slots.heaven, s.center(), {"dir": Vector2.RIGHT})
			return "heaven through the %s" % word
		return ""
	if bc._slot_ready(rules, slots, "wisp"):
		var best := Vector2.INF
		var best_n := 0
		for r in [3.0, 5.0, 7.0, 9.0]:
			for k in ARMOURY_DIRS:
				var at := d._walkable(s.center() + Vector2.from_angle(TAU * float(k) / float(ARMOURY_DIRS)) * r)
				var gap := s.distance_to(at)
				if gap < ArmouryDirector.GUARD_REACH + WillOWisp.RING.y + 0.3 or gap > ARMOURY_LIGHT_R:
					continue
				var n := 0
				for p in on:
					n += 1 if p.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH - 0.4 else 0
				if n > best_n:
					best_n = n
					best = at
		if best != Vector2.INF:
			rules.cast(slots.wisp, best)
			return "wisp %d armed men off the %s" % [best_n, word]
	for p in on:
		if p.held_by_god() or p.shaken():
			continue
		var away := p.ground_pos - s.center()
		var to := MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * ARMOURY_SENT)
		if bc._slot_ready(rules, slots, "whisper"):
			rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": to})
			return "whisper an armed man off the %s" % word
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, p.ground_pos)
			return "discord an armed man at the %s" % word
	return ""


## The target to work on: the first standing one not razed, or -1.
static func _armoury_target(d: ArmouryDirector) -> int:
	for i in d.targets.size():
		var s := d.targets[i]
		if not d.razed(s) and is_instance_valid(s) and not s.destroyed:
			return i
	return -1


## The middle of the mob's circle for a verdict on `s`: the densest knot of the crowd within MobVerdictFx.RADIUS of the building, no
## armed man in it; else the building's own middle.
static func _armoury_mob(d: ArmouryDirector, crowd: Crowd, s: Structure) -> Vector2:
	var near: Array[Person] = []
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(s.center()) <= MobVerdictFx.RADIUS:
			near.append(p)
	var best := s.center()
	var best_n := 0
	for a in near:
		var n := 0
		for b in near:
			if b.ground_pos.distance_to(a.ground_pos) <= MobVerdictFx.RADIUS * 0.5:
				n += 1
		if n > best_n:
			best_n = n
			best = a.ground_pos
	return best


static func state_armoury(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as ArmouryDirector
	if d == null:
		return ""
	return "razed=%d mustering=%d guards=%d reinforced=%d reliefs=%d reserve=%d phase=%s" % [d.razed_count(), d.mustering_now(),
		d.guards(d.current()).size(), d.reinforced, d.reliefs, d.reserve.size(), d.hint_phase()]


## The Sermon (loadout wisp, discord, deathmark, belllies, thorns), one look of the policy -- the first that applies:
## 1. the bellkeeper called: Discord on him (it drops the climb), else The Bell Lies, else a Death Mark;
## 2. a report running: Discord on its runner, else a Death Mark on him (he is slowed);
## 3. the preacher alive: a Death Mark on him at once, and SERMON_HOLD_AT seconds on (two before he dies) Discord on the pulpit, so that his
##    acolytes, held, see nothing (they run to the Temple if they see the fall); dead, he is silent for good and no Discord is spent on
##    his crowd again -- and it is not rapt, so the Wisp draws it;
## 4. a crowd to bring (a wave walked in, unturned, outside) and a Faithful who would see the god's door (a sentry, or any other) not yet
##    dealt with: a Death Mark on him (the one with no one by him, for a death near others is seen and raises the Gaze), else Discord on
##    him; the sentries come back RELIEF_AFTER after they fall, RELIEFS times in all, so they are dealt with when a crowd waits;
## 5. the door dealt with (every watcher held, or marked and due to fall before the crowd arrives), the Wisp lit by the god's house where
##    it draws the most of the crowd and lures no Faithful who would watch the door (_sermon_light()).
static func act_sermon(bc, ctx: Dictionary) -> String:
	var d := ctx.d as SermonDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var memo: Dictionary = ctx.memo
	if not memo.has("marks"):
		memo["marks"] = {}
	var marks: Dictionary = memo.marks
	var keeper := d.bellkeeper()
	if keeper != null:
		if bc._slot_ready(rules, slots, "discord") and not d.held(keeper):
			rules.cast(slots.discord, keeper.ground_pos)
			return "discord the bellkeeper"
		if not crowd.is_bell_lying() and bc._slot_ready(rules, slots, "belllies"):
			rules.cast(slots.belllies, TownLayout.BELL_TOWER.get_center(), {"mode": "well"})
			return "the bell lies"
		if bc._slot_ready(rules, slots, "deathmark"):
			rules.cast(slots.deathmark, keeper.ground_pos)
			return "death mark the bellkeeper"
	for r in d.reports:
		if not r.is_open() or not WarningDirector._alive(r.carrier) or r.carrier.inside:
			continue
		if bc._slot_ready(rules, slots, "discord") and not d.held(r.carrier):
			rules.cast(slots.discord, r.carrier.ground_pos)
			return "discord a report's runner"
		if bc._slot_ready(rules, slots, "deathmark") and not r.carrier.statuses.has(&"frail"):
			rules.cast(slots.deathmark, r.carrier.ground_pos)
			return "death mark a report's runner"
	var coming := 0
	for p in d.unturned():
		coming += 1
	var unhandled := _sermon_unhandled(d, marks)
	if not unhandled.is_empty():
		var pick: Person = null
		var pick_n := 0
		for p in unhandled:
			var n := _near_count(crowd, p, SERMON_MARK_ALONE)
			var sentry := d.sentries_on_guard().has(p)
			if pick == null or (sentry and not d.sentries_on_guard().has(pick)) or (sentry == d.sentries_on_guard().has(pick) and n < pick_n):
				pick = p
				pick_n = n
		if bc._slot_ready(rules, slots, "deathmark"):
			# One with no one by him dies unseen. Until the Death Mark has been ready SERMON_PATIENCE seconds, a player waits for such a moment;
			# then the one with the fewest by him dies, seen (the Gaze rises).
			if not memo.has("ready_since"):
				memo["ready_since"] = d._clock
			if pick_n > 0 and (d._clock - float(memo.ready_since) < SERMON_PATIENCE or d.gaze.value >= SERMON_SEEN_UNTIL):
				return ""
			memo.erase("ready_since")
			rules.cast(slots.deathmark, pick.ground_pos)
			marks[pick] = d._clock
			return "death mark a %s of the door (%d by him)" % ["sentry" if d.sentries_on_guard().has(pick) else "watcher", pick_n]
		return ""
	memo.erase("ready_since")
	if coming == 0 or d.relief_walking() != null or not _sermon_door_holds(d):
		return ""
	var light := _sermon_light(d, crowd, true)
	if light == Vector2.INF:
		return ""
	if d.preaching():
		# The crowd is rapt: silence the pulpit only when the Wisp is ready to follow at once and a light waits for it.
		if bc._slot_ready(rules, slots, "discord") and rules.cooldown_left(int(slots.wisp)) <= SERMON_WISP_SOON:
			rules.cast(slots.discord, d.pulpit)
			return "discord the preacher and his acolytes"
		return ""
	if bc._slot_ready(rules, slots, "wisp"):
		light = _sermon_light(d, crowd, false)
		if light != Vector2.INF:
			rules.cast(slots.wisp, light)
			return "wisp the crowd to the god's house"
	return ""


## The Faithful who would see the god's door now and are not dealt with: not held (confused), not marked to fall within SERMON_FALLS
## seconds (before the crowd he is to be kept from can arrive). `marks` is Person -> the second of the night he was marked.
static func _sermon_unhandled(d: SermonDirector, marks: Dictionary) -> Array[Person]:
	var out: Array[Person] = []
	for p in d.watchers(d.door, MirasHouseDirector.SIGHT):
		if marks.has(p) and p.statuses.has(&"frail") and DeathMarkFx.MARK_TIME - (d._clock - float(marks[p])) <= SERMON_FALLS:
			continue
		out.append(p)
	return out


## The god's door will stay unwatched long enough for the crowd to walk in and read (v0.11.1 Sermon B): no dead sentry's relief is due
## within SERMON_HOLDS seconds (RELIEF_AFTER less the seconds since he fell), while reliefs remain.
static func _sermon_door_holds(d: SermonDirector) -> bool:
	for st: SermonDirector.Sentry in d.sentries:
		if not MissionDirector._alive(st.man) and SermonDirector.RELIEF_AFTER - st.fallen < SERMON_HOLDS and d.reliefs < SermonDirector.RELIEFS:
			return false
	return true


## Where a Will-o'-Wisp lit by the god's house draws the most of the crowd that answers a lure (SermonDirector, answers_lure: called,
## unturned, not rapt), within WillOWisp.LURE_REACH of the light less a margin; the light a point from which the lured stand on the ring
## by the house (the house's footprint grown by one unit: their ring is WillOWisp.RING.y wide and LURE_REACH reaches that far); not where a
## Faithful who goes about his day (Person.LURABLE) within the Wisp's reach would be drawn to stand by the door and watch. Vector2.INF
## for none.
static func _sermon_light(d: SermonDirector, crowd: Crowd, assume_silent: bool) -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	var best_gap := INF
	var x := d.house.footprint.position.x - 2.0
	while x <= d.house.footprint.end.x + 2.0:
		var y := d.house.footprint.position.y - 2.0
		while y <= d.house.footprint.end.y + 2.0:
			var at := Vector2(x, y)
			y += 0.5
			if crowd._grid != null and not crowd._grid.walkable(at):
				continue
			if not d._near_house(at, 1.0):
				continue
			var n := 0
			for l: SermonDirector.Listener in d.listeners:
				if not WarningDirector._alive(l.man):
					continue
				var m := l.man as Person
				var eligible: bool = (d.called[l.wave] and not m.inside and not d.believers.has(m)) if assume_silent else m.answers_lure
				if eligible and m.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH - SERMON_LIGHT_MARGIN:
					n += 1
			if n == 0 or n < best_n:
				continue
			var watched := false
			for f in d.faithful:
				if WarningDirector._alive(f) and not f.inside and f.mind in Person.LURABLE and not d._busy().has(f) \
						and f.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH:
					watched = true
			if watched:
				continue
			var gap := -at.distance_to(d.door)  # the farthest from the door: the crowd's walk takes longest, the Faithful's ring lies furthest from it
			if n > best_n or gap < best_gap:
				best = at
				best_n = n
				best_gap = gap
		x += 0.5
	return best


## How many others, alive and out of doors, stand within `r` of `p`.
static func _near_count(crowd: Crowd, p: Person, r: float) -> int:
	var n := 0
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if o != p and is_instance_valid(o) and o.is_alive() and not o.inside and o.ground_pos.distance_to(p.ground_pos) <= r:
				n += 1
	return n


static func state_sermon(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as SermonDirector
	if d == null:
		return ""
	return "believers=%d left=%d preaching=%s sentries=%d reports=%d gaze=%d phase=%s" % [d.believers_outside(),
		d.unturned().size(), d.preaching(), d.sentries_on_guard().size(), d.reports_started, roundi(d.gaze.value), d.hint_phase()]


## The Relic Run (loadout wisp, discord, deathmark, oath, thorns), one look of the policy -- the first that applies:
## 1. the bellkeeper called: Discord on him, else a Death Mark; 2. a report running: Discord on its runner, else a Death Mark on him;
## 3. with the relic, the Vigil Flame's loadout-B carry (Tier3B._flame_carry(): the Wisp draws a due beam off his road, a decoy Wisp draws
##    the next beam off it when 30 s have passed quiet, Discord stops the light at the end -- no whisper in this loadout);
## 4. before a halt, Pip not aboard: a Will-o'-Wisp lit RELIC_HOP toward the next checkpoint draws him a stretch nearer (he answers a lure
##    within CHARGE_LURE_R of the light and holds where it leaves him); within RELIC_CLOSE of a halted cart, a Wisp lit at the cart draws
##    him to its ring, where a lured Pip can slip aboard;
## 5. the next halt within RELIC_AHEAD (the first) or RELIC_LEG (the second): a Death Mark on a warden of it with no one else by him
##    (the fall goes unseen: it comes DeathMarkFx.MARK_TIME on), or in its last RELIC_LATE seconds on one seen;
## 6. halted, Pip by the cart or aboard, and the cart watched: Oathbound sends the four nearest the cart's middle to hold a place away from
##    it (60 s: the carter and the nearest of the watch), Discord where it holds every watcher left (all within DiscordFx.DISCORD_R -
##    RELIC_MARGIN of their midpoint), else a Death Mark on one with no one by him.
static func act_relic(bc, ctx: Dictionary) -> String:
	var d := ctx.d as RelicRunDirector
	if d == null:
		return ""
	var v: Variant = d.wren
	if not WarningDirector._alive(v) or d.home:
		return ""
	var pip := v as Person
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var keeper := d.bellkeeper()
	if keeper != null:
		if bc._slot_ready(rules, slots, "discord") and not keeper.mind in MissionDirector.BLIND:
			rules.cast(slots.discord, keeper.ground_pos)
			return "discord the bellkeeper"
		if bc._slot_ready(rules, slots, "deathmark") and not keeper.statuses.has(&"frail"):
			rules.cast(slots.deathmark, keeper.ground_pos)
			return "death mark the bellkeeper"
	for r in d.reports:
		if not r.is_open() or not WarningDirector._alive(r.carrier) or r.carrier.inside:
			continue
		var c := r.carrier
		if bc._slot_ready(rules, slots, "discord") and not c.mind in MissionDirector.BLIND:
			rules.cast(slots.discord, c.ground_pos)
			return "discord a report's runner"
		if bc._slot_ready(rules, slots, "deathmark") and not c.statuses.has(&"frail") and (pip.inside or pip.ground_pos.distance_to(c.ground_pos) > 1.0):
			rules.cast(slots.deathmark, c.ground_pos)
			return "death mark a report's runner"
	if d.swapped:
		# The carry is the Searchlight's to hunt Pip on his way: the Vigil Flame's loadout-B carry (a Wisp that draws a due beam off his road,
		# and, when the quiet has lasted, a decoy that draws the next beam off it before it comes), as the Flame's own B route plays it.
		if not ctx.memo.has("carry_last"):
			ctx.memo["carry_last"] = d._clock
		var did: String = Tier3B._flame_carry(bc, d, rules, slots, ctx, d._clock - float(ctx.memo.carry_last) >= Tier3B.FLAME_QUIET)
		if did != "":
			ctx.memo["carry_last"] = d._clock
			return "carry the relic: " + did
		return ""
	var cart := d.cart_at()
	var k := d.next_halt()
	var due := d.halt_in()
	# Pip is sent to the checkpoint by Oathbound's hold a place (60 s: it walks him there, to the very spot the cart stops at, where no building
	# draws the spot aside) when the cart is RELIC_OATH_LEAD from it, so he stands by the cart as it halts.
	if not d.aboard and not pip.inside and bc._slot_ready(rules, slots, "oath") and not pip.mind in [Person.Mind.COMPELLED, Person.Mind.WHISPERED]:
		var kk := d.next_halt()
		if kk >= 0 and ((d.halt < 0 and due <= RELIC_OATH_LEAD) or d.halt == kk) \
				and pip.ground_pos.distance_to(d.checkpoints[kk]) > RelicRunDirector.CART_REACH * 0.5:
			rules.cast(slots.oath, pip.ground_pos, {"mode": "hold", "to": d.checkpoints[kk]})
			return "oath Pip to the halt (%.1f off)" % pip.ground_pos.distance_to(d.checkpoints[kk])
	# A warden of the last halt is bound ahead of it: Oathbound's hold a place sends him off to hold it 60 s, and a Faithful bound by an oath
	# neither watches the cart nor sees a fall (RelicRunDirector._sees()).
	if d.halt < 0 and k == 1 and due <= RELIC_OATH_AHEAD and bc._slot_ready(rules, slots, "oath"):
		for p in d.wardens_at(k):
			if p.mind == Person.Mind.COMPELLED:
				continue
			rules.cast(slots.oath, p.ground_pos, {"mode": "hold", "to": d._walkable(d.checkpoints[k] + Vector2(RELIC_OATH_AWAY, 0.0))})
			return "oath a warden ahead away from the last halt"
	# A warden of the next halt whose fall goes quite unseen (no one at all within Crowd.DOOM_WITNESS of him) is marked ahead of it: one fewer
	# at the cart (his relief comes RELIEF_AFTER after he falls, and the cart's watch is drawn off together by the Wisp then).
	if d.halt < 0 and k == 1 and due <= RELIC_LEG + DeathMarkFx.MARK_TIME and bc._slot_ready(rules, slots, "deathmark"):
		for p in d.wardens_at(k):
			if p.statuses.has(&"frail") or not bc._none_within(crowd, p, Crowd.DOOM_WITNESS + RELIC_MARGIN):
				continue  # (no other Faithful by him: a seen fall by a lay person only raises the Gaze, a Faithful's runs to the Temple)
			rules.cast(slots.deathmark, p.ground_pos)
			return "death mark a warden ahead"
	# The Faithful going about their day near the next checkpoint -- not the cart's people nor its wardens -- are the ones who stop to look at
	# the halted cart: those whose fall goes quite unseen are marked while the cart rolls, so fewer eyes meet it there (R8: a job in the
	# rolling stretch, when the Oath and the Wisp are cooling).
	if d.halt < 0 and k >= 0 and due <= RELIC_STROLL_AHEAD and bc._slot_ready(rules, slots, "deathmark"):
		var mates: Array = d.escorts.duplicate()
		mates.append(d.carter)
		for w: RelicRunDirector.Warden in d.wardens:
			mates.append(w.man)
		for f in d.faithful:
			if not WarningDirector._alive(f) or f.inside or mates.has(f) or f.statuses.has(&"frail") or f.ground_pos.distance_to(d.checkpoints[k]) > RELIC_STROLL_R:
				continue
			if bc._none_within(crowd, f, Crowd.DOOM_WITNESS + RELIC_MARGIN):
				rules.cast(slots.deathmark, f.ground_pos)
				return "death mark a Faithful who would watch the cart"
	if d.halt >= 0 and (d.aboard or pip.held_by_god() or pip.ground_pos.distance_to(cart) <= RelicRunDirector.CART_REACH):
		var seen := d.watchers_now()
		if seen.is_empty():
			return ""
		# Not before the watch has gathered: the wardens step up to the cart a few seconds after it halts, and a cast on the first two to
		# arrive leaves the other two a clear view.
		var core := d.escorts.size() + d.wardens_at(d.halt).size()
		var here := 0
		for esc: Variant in d.escorts:
			here += 1 if WarningDirector._alive(esc) and (esc as Person).ground_pos.distance_to(cart) <= RelicRunDirector.WATCH + RELIC_GATHER else 0
		for p in d.wardens_at(d.halt):
			here += 1 if p.ground_pos.distance_to(cart) <= RelicRunDirector.WATCH + RELIC_GATHER else 0
		if here < mini(core, RELIC_GATHERED) and d.halt_time < RELIC_GATHER_WAIT:
			return ""
		# Only passers-by left (Faithful going about their day who stopped to look at the cart): a Wisp lit RELIC_LURE past them, away from the
		# cart, draws them off to stand staring at it.
		# Once Pip has been led by the god's light or oath (RelicRunDirector.pip_led) the watch itself answers it: the same light draws the
		# escorts and wardens off to stare at it, and the cart stands unwatched for as long as they do.
		var strollers: Array[Person] = []
		for p in seen:
			if p.mind in Person.LURABLE or (d.pip_led and p.answers_lure and p.mind == Person.Mind.DUTY):
				strollers.append(p)
		if not strollers.is_empty() and strollers.size() == seen.size() - _relic_leaving(seen) and bc._slot_ready(rules, slots, "wisp"):
			var c := Vector2.ZERO
			for p in strollers:
				c += p.ground_pos / float(strollers.size())
			var off := c - cart
			var dir := off.normalized() if off.length() > 0.01 else Vector2.RIGHT
			rules.cast(slots.wisp, d._walkable(cart + dir * (maxf(off.length(), 1.0) + RELIC_LURE)))
			ctx.memo["wisp_at"] = d._clock
			return "wisp the passers-by off the cart"
		# The Wisp's draw takes a few seconds to clear the cart; Discord and Oathbound are kept for the ones it leaves, not spent at once.
		if d._clock - float(ctx.memo.get("wisp_at", -100.0)) < RELIC_DRAW:
			return ""
		# Discord holds the watchers within its reach of a spot that leaves Pip and the carter out; Oathbound sends the four nearest a click to
		# hold a place away from the cart (they walk off slowly, but they walk): the one that takes the more of the watch goes first.
		var d_at := Vector2.INF
		var d_n := 0
		if bc._slot_ready(rules, slots, "discord"):
			for p in seen:
				if p.mind in MissionDirector.BLIND:
					continue
				var at := p.ground_pos
				if not pip.inside and at.distance_to(pip.ground_pos) <= DiscordFx.DISCORD_R + RELIC_MARGIN:
					continue  # (aboard he is hidden in the straw, and nothing can reach him)
				var n := 0
				for q in seen:
					if q.ground_pos.distance_to(at) <= DiscordFx.DISCORD_R - RELIC_MARGIN and not q.mind in MissionDirector.BLIND:
						n += 1
				if n > d_n:
					d_n = n
					d_at = at
		var o_at := Vector2.INF
		var o_n := 0
		if bc._slot_ready(rules, slots, "oath"):
			for p in seen:
				var n := 0
				var bad := 0
				for b in OathboundFx.bound_at(crowd._field, p.ground_pos):
					if seen.has(b):
						n += 1
					elif b == pip or b == d.carter:
						bad += 1
				if bad == 0 and n > o_n:
					o_n = n
					o_at = p.ground_pos
		if d_n > 0 and d_n >= o_n and not (o_n >= 2 and d_n < 2):
			rules.cast(slots.discord, d_at)
			return "discord %d of the watch" % d_n
		if o_n > 0:
			rules.cast(slots.oath, o_at, {"mode": "hold", "to": d._walkable(cart + Vector2(RELIC_OATH_AWAY, 0.0))})
			return "oath %d of the watch away from the cart" % o_n
	return ""


## How many of `seen` walk off already under the Oath (Person.Mind.COMPELLED): they leave the cart's watch within seconds.
static func _relic_leaving(seen: Array[Person]) -> int:
	var n := 0
	for p in seen:
		n += 1 if p.mind == Person.Mind.COMPELLED else 0
	return n


static func state_relic(bc, ctx: Dictionary) -> String:
	var d := ctx.d as RelicRunDirector
	if d == null:
		return ""
	return "halt=%d halts=%s aboard=%s lock=%.0f swapped=%s stalled=%s touches=%d gaze=%d reports=%d phase=%s bell=%s" % [d.halt, d.halts_done,
		d.aboard, d.lock_left, d.swapped, d.stalled, d.touches, roundi(d.gaze.value), d.reports_started, d.hint_phase(), bc._bell_state(ctx.crowd)]
