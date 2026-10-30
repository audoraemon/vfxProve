extends RefCounted
## The scripted policies of the Hunt "Hide the faithful" (Tier 1; god P5, MS §7, plan Tasks 3 and 9): the shared plan with the def's loadout
## (act_shared), one act_<type> per god type (the six, playing only that type's two Tier 1 powers from LOADOUT), and the report line (state).
## Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is never edited by a Hunt task).
##
## The night the six types play: two households walk themselves out along their roads (39.5 and 33.2 units at 0.72 a second), and everything
## that would see a believer within SIGHT 2.5 must be answered before it does: two patrols on their beats, the watch at each gate, the two
## inquisitors on their list. A player reads the night one way: for each watcher, when will a believer first come within sight of him, on the
## road as it lies ahead (_view()); the type's own two powers then answer the soonest, in the lead its power needs (a kill lands within a
## second, a mark in ten, a law holds fifteen). A seized believer is freed by taking his seizer away (_seizers()). No policy casts only to
## end an idle stretch (T1R D38): every cast here is an answer to a watcher, a seizer or the search, or the type's one set-piece (the mirror).

## The god types whose policy is written.
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(1) Might at level 1, all in GodTree.keys_for(type, 1)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "ember"],
	"death": ["deathmark", "pestilence"],
	"veil": ["doom", "blight"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies"],
	"dominion": ["whisper", "discord"],
}

## The shared pieces (god T1R): the road_ahead() of a walker, outside_spot(), plague_aim(). Reached through GOD_T1, never copied.
const GOD_T1 := preload("res://tools/dev/routes/god_t1.gd")

## How near a believer an inquisitor must walk for the shared plan to clear him (the search is otherwise left alone: a fallen one is replaced).
const HUNT_NEAR := 9.0
## How far along a household's road ahead of its lamp a watcher is worked, and how near its gate's way out (the outer post's men).
const ROAD_AHEAD := 16.0
const GATE_NEAR := 6.0

## The reading of the night (_view()): how far ahead, in seconds, a watcher's sight of a believer is looked for, in what step, and the margin
## added to SIGHT (a believer walks a hand off the road's line, a watcher a step beyond his place).
const READ_AHEAD := 75.0
const READ_STEP := 0.5
const SIGHT_PAD := 0.35
## A reading is kept this long (seconds of the night's clock) before it is made again.
const READ_KEEP := 0.2
## A killing blow lands this far (plus its radius) from a believer at the least, or it takes him too.
const BLOW_GAP := 0.4

## A gate watchman is answered this far ahead of his sight once nothing has been cast for IDLE_AFTER seconds: a power ready and a real threat to the
## households known, so a player strikes rather than waits (and the night's real idle stays short).
const LONG_LEAD := 70.0
const IDLE_AFTER := 30.0
## ...and the last of them too, once this long has passed (the wait before the win is a stretch of the night's idle like any other).
const IDLE_LAST := 38.0
## ...and a kill nobody was to see is made seen after this long without a cast (Silent Doom: the alarm costs less than a night's idle).
const IDLE_RELAX := 38.0

## Ruin: Smite is cast on the soonest watcher when his sight of a believer is this near (a second watcher of a pair is cast ten seconds later,
## so the first goes early enough for it); Silent Doom the same.
const SMITE_LEAD := 13.0
const DOOM_LEAD := 13.0
## Death: a Death Mark dies its man in ten seconds, so it is cast this long before his sight; Pestilence kills in about six (it is cast
## PLAGUE_LEAD before, and never within PLAGUE_CLEAR of a believer).
const MARK_LEAD := 17.0
const PLAGUE_LEAD := 13.0
const PLAGUE_CLEAR := 6.0
## ...and two men are "of the same hour" when their sight of a household is this many seconds apart or fewer.
const MARK_HOUR := 14.0
## Decree: the law holds a circle fifteen seconds from its seal, and a group within 40 s of its sight of a household is caged (LAW_CRAWL); the call
## of the guard stands soldiers away twenty from 0.8, and is cast GUARD_LEAD before the first of them would see a household.
const LAW_CRAWL := 40.0
## ...the cage's centre lies this much inside the law's radius behind the group's lead.
const CAGE_SLACK := 1.0
const GUARD_LEAD := 9.0
const GUARD_SPAN := 20.0
## Dominion: Mind Whisper is cast on a watcher this near his sight of a believer (it holds him some twenty seconds, so never far ahead: ruling P5-T9-R9);
## Discord on a tight pair the same.
const WHISPER_LEAD := 9.0
const DISCORD_LEAD := 10.0
## Passage: the mirror's way in is laid this many seconds of the household's walk ahead of its lamp, its way out this far beyond the wall.
const MIRROR_AHEAD := 3.5
const MIRROR_BEYOND := 2.5
## A household comes out within this many seconds: the mirror for it is laid (it lives thirty).
const MIRROR_FOR := 22.0


## The director when the night is on, else null.
static func _hf(ctx: Dictionary) -> HideFaithfulDirector:
	return ctx.get("d") as HideFaithfulDirector


## The numbers this Hunt's report lines print (MS §7): believers out, lost, left; seizures; the search's place (houses stood at, the trail it
## follows), the inquisitors alive and their reliefs; the nearest the pair stood at each listed door (what one Doom would take together; "-"
## for a door not stood at); the hint's phase.
static func state(_bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var alive := 0
	for v: Variant in d.inquisitors:
		alive += 1 if MissionDirector._alive(v) else 0
	var doors := PackedStringArray()
	for k in d._search.size():
		var g: float = d.stopped_door_gap[k] if k < d.stopped_door_gap.size() else INF
		doors.append("%.1f" % g if g < INF else "-")
	var lamps := PackedStringArray()
	for i in d.households.size():
		var lead := d.lamp(i)
		lamps.append("%.0f" % _progress(_road(ctx, d, i), (lead.man as Person).ground_pos) if lead != null and (d.households[i] as ExodusDirector.Household).out else "-")
	return "out=%d lost=%d left=%d seizures=%d searched=%d trail=%d inquisitors=%d reliefs=%d pair=%.2f/%d doors=%s lamps=%s phase=%s" % [d.out_count(), d.lost(),
		d.left_count(), d.seizures, d.searched, d.trail_of(), alive, d.inq_reliefs, minf(d.stopped_gap_min, 99.0), d.stopped_gaps, "/".join(doors),
		"/".join(lamps), d.hint_phase()]


# --- Reading the night (every type) ---

## The living watchers out of doors and watching, whom a believer's sight would meet: [{p, kind}], kind "watch", "patrol" or "inquisitor".
static func _watchers(d: HideFaithfulDirector) -> Array:
	var out := []
	for v: Variant in d.watch:
		if d._watching(v) and not d._seizing(v):
			out.append({"p": v as Person, "kind": "watch"})
	for squad: Array in d.patrols:
		for v: Variant in squad:
			if d._watching(v) and not d._seizing(v):
				out.append({"p": v as Person, "kind": "patrol"})
	for v: Variant in d.inquisitors:
		if d._watching(v) and not d._seizing(v):
			out.append({"p": v as Person, "kind": "inquisitor"})
	return out


## Household `i`'s road with its running lengths, made once: {pts, cum}.
static func _road(ctx: Dictionary, d: HideFaithfulDirector, i: int) -> Dictionary:
	var memo: Dictionary = ctx.memo
	var key := "road%d" % i
	if not memo.has(key):
		var pts: Array = []
		for q: Vector2 in d.road(i):
			if pts.is_empty() or (pts.back() as Vector2).distance_to(q) > 0.01:
				pts.append(q)
		var cum := PackedFloat32Array()
		var run := 0.0
		for k in pts.size():
			if k > 0:
				run += (pts[k - 1] as Vector2).distance_to(pts[k])
			cum.append(run)
		memo[key] = {"pts": pts, "cum": cum}
	return memo[key]


## How far along the road the point nearest `at` lies.
static func _progress(rc: Dictionary, at: Vector2) -> float:
	var pts: Array = rc.pts
	var best := INF
	var along := 0.0
	for k in range(pts.size() - 1):
		var q := Geometry2D.get_closest_point_to_segment(at, pts[k], pts[k + 1])
		var g := at.distance_to(q)
		if g < best:
			best = g
			along = float((rc.cum as PackedFloat32Array)[k]) + (pts[k] as Vector2).distance_to(q)
	return along


## The point `along` units from the road's start (its end if past it).
static func _point(rc: Dictionary, along: float) -> Vector2:
	var pts: Array = rc.pts
	var cum: PackedFloat32Array = rc.cum
	if pts.size() < 2 or along >= float(cum[cum.size() - 1]):
		return pts.back()
	if along <= 0.0:
		return pts[0]
	var k := clampi(cum.bsearch(along) - 1, 0, pts.size() - 2)
	var seg := float(cum[k + 1]) - float(cum[k])
	return (pts[k] as Vector2).lerp(pts[k + 1], (along - float(cum[k])) / maxf(seg, 0.001))


## The believers a watcher must not see, as walkers on their roads: [{rc, from, speed, delay, i}] -- each believer out and free on his
## road (from his place on it), and each household still inside from its door (after its time).
static func _exposed(ctx: Dictionary, d: HideFaithfulDirector) -> Array:
	var out := []
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		if h.done:
			continue
		var rc := _road(ctx, d, i)
		if not h.out:
			out.append({"rc": rc, "from": 0.0, "speed": Person.PANIC_SPEED * d.tune_believer_pace, "delay": d.due_in(i), "i": i})
			continue
		for c: EscortDirector.Charge in h.members:
			if d._resolved(c) or c.held or (c.man as Person).inside:
				continue
			var p := c.man as Person
			out.append({"rc": rc, "from": _progress(rc, p.ground_pos), "speed": maxf(p.walk_speed, 0.2), "delay": 0.0, "i": i})
	return out


## The walk between two doors through the town's streets, made once: {pts, len}.
static func _leg(ctx: Dictionary, a: Vector2, b: Vector2) -> Dictionary:
	var memo: Dictionary = ctx.memo
	var key := "leg%s>%s" % [a, b]
	if not memo.has(key):
		var path: PackedVector2Array = (ctx.crowd as Crowd)._grid.path(a, b) if (ctx.crowd as Crowd)._grid != null else PackedVector2Array()
		var pts: Array = [a]
		pts.append_array(Array(path))
		var len := 0.0
		for k in range(1, pts.size()):
			len += (pts[k - 1] as Vector2).distance_to(pts[k])
		memo[key] = {"pts": pts, "len": len}
	return memo[key]


## The point `along` units down a leg (its end if past it).
static func _along(leg: Dictionary, along: float) -> Vector2:
	var pts: Array = leg.pts
	var run := 0.0
	for k in range(1, pts.size()):
		var seg := (pts[k - 1] as Vector2).distance_to(pts[k])
		if run + seg >= along:
			return (pts[k - 1] as Vector2).move_toward(pts[k], along - run)
		run += seg
	return pts.back()


## Where watcher `p` will stand `s` seconds on. A soldier walks the path he is on. An inquisitor walks the search as it lies ahead -- the strip
## and the tags give the player the listed doors and when the search reaches them: the rest of his stop, then each leg between doors at his
## pace and HF_SEARCH_STOP at each door; on a trail, the path he is on.
static func _where(ctx: Dictionary, d: HideFaithfulDirector, w: Dictionary, s: float) -> Vector2:
	var p: Person = w.p
	if w.kind != "inquisitor" or d.trail_of() >= 0 or d._search_at >= d._search.size() or p.inside:
		return GOD_T1.road_ahead(p, s)
	var speed := maxf(Person.PANIC_SPEED * float(d._inq_base.get(p.get_instance_id(), p.pace)) * HideFaithfulDirector.HF_SEARCH_PACE, 0.2)
	var left := s
	var at := p.ground_pos
	var k: int = d._search_at
	if d._search_stop >= 0.0:
		var wait := maxf(d._search_stop - d._clock, 0.0)
		if left <= wait:
			return at
		left -= wait
		at = d._search[k].door
		k += 1
	while k < d._search.size():
		var leg := _leg(ctx, at, d._search[k].door)
		var run := float(leg.len) / speed
		if left <= run:
			return _along(leg, left * speed)
		left -= run
		at = d._search[k].door
		if left <= HideFaithfulDirector.HF_SEARCH_STOP:
			return at
		left -= HideFaithfulDirector.HF_SEARCH_STOP
		k += 1
	return at


## Seconds until watcher `w` first comes within SIGHT of an exposed believer walking on; INF when not within READ_AHEAD.
static func _sight_in(ctx: Dictionary, d: HideFaithfulDirector, w: Dictionary, exposed: Array) -> float:
	var s := 0.0
	while s <= READ_AHEAD:
		var at := _where(ctx, d, w, s)
		for e: Dictionary in exposed:
			if s < float(e.delay):
				continue
			var spot := _point(e.rc, float(e.from) + float(e.speed) * (s - float(e.delay)))
			if at.distance_to(spot) <= EscortDirector.SIGHT + SIGHT_PAD:
				return s
		s += READ_STEP
	return INF


## The night as the policy reads it, kept READ_KEEP of the clock: {exposed, threats: [{p, kind, t}] soonest first}.
static func _view(ctx: Dictionary, d: HideFaithfulDirector) -> Dictionary:
	var memo: Dictionary = ctx.memo
	if memo.has("view") and d._clock - float(memo.view.at) < READ_KEEP and int(memo.view.n) == d.charges.size():
		return memo.view
	var exposed := _exposed(ctx, d)
	var threats := []
	if not exposed.is_empty():
		for w: Dictionary in _watchers(d):
			var t := _sight_in(ctx, d, w, exposed)
			if t < INF:
				threats.append({"p": w.p, "kind": w.kind, "t": t})
		threats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.t) < float(b.t))
	memo.view = {"at": d._clock, "n": d.charges.size(), "exposed": exposed, "threats": threats}
	return memo.view


## How far ahead of his sight a watcher is answered now: `lead`, and for a stationary one (the gates' watch) LONG_LEAD once IDLE_AFTER seconds have
## passed with nothing cast and two or more of the gates' watch are waiting; the last one waits for his own lead until IDLE_LAST. The men who
## move (patrols, inquisitors and their reliefs) are answered in their own lead only: killed early they leave nothing to answer later, and the night's
## real idle is its longest wait, the one before the win included.
static func _lead(ctx: Dictionary, d: HideFaithfulDirector, th: Dictionary, lead: float) -> float:
	if th.kind == "watch":
		var idle := d._clock - float(ctx.memo.get("last_cast", 0.0))
		var stationary := 0
		for o: Dictionary in _view(ctx, d).threats:
			stationary += 1 if o.kind == "watch" else 0
		if (stationary >= 2 and idle >= IDLE_AFTER) or idle >= IDLE_LAST:
			return LONG_LEAD
	return lead


## The marched believers' seizers: [{c, s, b, kind}] (the charge, the seizer, the believer's person, and what the seizer is), the seizer alive.
static func _seizers(d: HideFaithfulDirector) -> Array:
	var out := []
	for c: EscortDirector.Charge in d.charges:
		if c.held and not d._resolved(c) and MissionDirector._alive(c.seizer):
			out.append({"c": c, "s": c.seizer as Person, "b": c.man as Person, "kind": _kind(d, c.seizer as Person)})
	return out


## What watcher `p` is: "watch", "patrol" or "inquisitor".
static func _kind(d: HideFaithfulDirector, p: Person) -> String:
	if d.watch.has(p):
		return "watch"
	if d.inquisitors.has(p):
		return "inquisitor"
	return "patrol"


## No believer who is out and free stands within `r` of `at`.
static func _flock_clear(bc, d: HideFaithfulDirector, at: Vector2, r: float) -> bool:
	for b: Variant in bc._exodus_flock(d):
		if (b as Person).ground_pos.distance_to(at) <= r:
			return false
	return true


static func _ready(bc, ctx: Dictionary, key: String) -> bool:
	return bc._slot_ready(ctx.rules, ctx.slots, key)


static func _cast(ctx: Dictionary, key: String, at: Vector2, extra := {}) -> void:
	ctx.rules.cast(int(ctx.slots[key]), at, extra)
	ctx.memo.last_cast = (ctx.d as HideFaithfulDirector)._clock


## Where a blow of radius `r` landing `delay` after the cast takes the seizer without the believer: the seizer's place then, when the believer
## (where he is, and where he will be then) is more than r + BLOW_GAP from it; Vector2.INF for none yet.
static func _seizer_aim(sz: Dictionary, r: float, delay: float) -> Vector2:
	var s: Person = sz.s
	var b: Person = sz.b
	var at := GOD_T1.road_ahead(s, delay)
	if at.distance_to(GOD_T1.road_ahead(b, delay)) > r + BLOW_GAP and b.ground_pos.distance_to(at) > r + BLOW_GAP:
		return at
	return Vector2.INF


## `p` is already marked or sick: another mark or plague on him is wasted.
static func _doomed(p: Person) -> bool:
	return p.statuses.has(&"frail") or p.sick_left > 0.0


# --- Shared plan (the def's own loadout: Mind Whisper, Silent Doom, Discord; no --god) ---

## The shared plan with the def's own loadout (Mind Whisper, Silent Doom, Discord; no `--god`): the households walk themselves, so the
## player works the opposition as it comes. The first that applies: a believer seized -- Discord on his seizer, else Mind Whisper sends the
## seizer off, else Silent Doom on him unseen; an inquisitor within HUNT_NEAR of a believer (or the search on a household's trail) -- cleared;
## a watcher about to see a believer (SIGHT + EXODUS_WARN) -- cleared; a watcher on a walking household's road ahead of its lamp (ROAD_AHEAD),
## or at its gate -- cleared; the next household about to come out -- the first watcher on its road. Every Doom unseen and sparing the
## believers (behaviour_check's Exodus pieces: _exodus_off() and the rest).
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var flock: Array = bc._exodus_flock(d)
	for c in d.charges:
		if not c.held or d._resolved(c) or not MissionDirector._alive(c.seizer):
			continue
		var s := c.seizer as Person
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, s.ground_pos)
			return "discord a seizer"
		if bc._slot_ready(rules, slots, "whisper") and not s.shaken():
			rules.cast(slots.whisper, s.ground_pos, {"target": s, "to": bc._prisoner_away(crowd, s, (c.man as Person).ground_pos)})
			return "whisper a seizer off"
		if bc._slot_ready(rules, slots, "doom") and bc._doom_unseen(crowd, s.ground_pos, flock, bc.EXODUS_MARGIN):
			rules.cast(slots.doom, s.ground_pos)
			return "doom a seizer"
	for v: Variant in d.inquisitors:
		if not d._watching(v) or d._seizing(v):
			continue
		var p := v as Person
		var near := d.trail_of() >= 0
		var from := p.ground_pos + Vector2.LEFT
		for b: Variant in flock:
			if (b as Person).ground_pos.distance_to(p.ground_pos) <= HUNT_NEAR:
				near = true
				from = (b as Person).ground_pos
		if near:
			var did: String = bc._exodus_off(rules, slots, d, crowd, p, from)
			if did != "":
				return did
	for v: Variant in d._watchers():
		if not d._watching(v) or d._seizing(v):
			continue
		var p := v as Person
		for b: Variant in flock:
			if (b as Person).ground_pos.distance_to(p.ground_pos) <= EscortDirector.SIGHT + bc.EXODUS_WARN:
				var did: String = bc._exodus_off(rules, slots, d, crowd, p, (b as Person).ground_pos)
				if did != "":
					return did
				break
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		var lead := d.lamp(i)
		if not h.out or h.done or lead == null:
			continue
		var lp := lead.man as Person
		var road := d.road(i)
		var here: float = bc._road_progress(road, lp.ground_pos)
		for v: Variant in d._watchers():
			if not d._watching(v) or d._seizing(v):
				continue
			var p := v as Person
			var on: float = bc._road_progress(road, p.ground_pos)
			var off := p.ground_pos.distance_to(bc._road_ahead(road, road[0], on))
			var at_gate := p.ground_pos.distance_to(road.back()) <= GATE_NEAR
			if at_gate or (off <= bc.EXODUS_NEAR and on >= here - bc.EXODUS_NEAR and on <= here + ROAD_AHEAD):
				var did: String = bc._exodus_off(rules, slots, d, crowd, p, lp.ground_pos)
				if did != "":
					return did
	var nxt := d.upcoming()
	if nxt >= 0 and d.due_in(nxt) <= bc.EXODUS_AHEAD:
		var road := d.road(nxt)
		for v: Variant in d._watchers():
			if not d._watching(v):
				continue
			var p := v as Person
			for k in range(road.size() - 1):
				if bc._seg_dist(p.ground_pos, road[k], road[k + 1]) <= bc.EXODUS_NEAR:
					var did: String = bc._exodus_off(rules, slots, d, crowd, p, road[k], d.due_in(nxt) <= bc.EXODUS_SOON)
					if did != "":
						return did
					break
	return ""


# --- Ruin: Smite, Ember ---

## Smite takes a marched believer's seizer (clear of the believer), then the soonest watcher whose sight of a believer is within SMITE_LEAD,
## one man at a time (a pair walks 2.0 apart: Smite's bolt takes 0.6). Loud: each kill rings the town's alarm, and the rally takes the rest.
## Ember burns no one and is not cast: a burning house draws no one off a post.
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null or not _ready(bc, ctx, "smite"):
		return ""
	for sz: Dictionary in _seizers(d):
		var at := _seizer_aim(sz, SmiteFx.KILL_R, SmiteFx.T_STRIKE)
		if at != Vector2.INF:
			_cast(ctx, "smite", at)
			return "smite a %s seizer" % sz.kind
	for th: Dictionary in _view(ctx, d).threats:
		if float(th.t) > _lead(ctx, d, th, SMITE_LEAD):
			continue
		var at := GOD_T1.road_ahead(th.p, SmiteFx.T_STRIKE)
		if _flock_clear(bc, d, at, SmiteFx.KILL_R + BLOW_GAP):
			_cast(ctx, "smite", at)
			return "smite a %s" % th.kind
	return ""


# --- Death: Death Mark, Pestilence ---

## Pestilence takes a pair whole (both within its reach -- victims_at() says so -- and nobody of the flock within PLAGUE_CLEAR) when the soonest
## of them is within PLAGUE_LEAD of his sight; a Death Mark takes one man, MARK_LEAD before his sight (it dies him in ten seconds) and, for each man
## of the same hour still to be marked before him, twenty seconds more (it is ready every twenty), a seizer first of all.
static func act_death(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var crowd: Crowd = ctx.crowd
	if _ready(bc, ctx, "deathmark"):
		for sz: Dictionary in _seizers(d):
			if not _doomed(sz.s):
				_cast(ctx, "deathmark", (sz.s as Person).ground_pos)
				return "death mark a %s seizer" % sz.kind
	var threats: Array = _view(ctx, d).threats
	if _ready(bc, ctx, "pestilence"):
		for th: Dictionary in threats:
			if float(th.t) > _lead(ctx, d, th, PLAGUE_LEAD):
				continue
			var p: Person = th.p
			if _doomed(p):
				continue
			for o: Dictionary in threats:
				if o.p == p or _doomed(o.p) or (o.p as Person).ground_pos.distance_to(p.ground_pos) > PestilenceFx.INFECT_R * 2.0:
					continue
				var mid := (p.ground_pos + (o.p as Person).ground_pos) * 0.5
				var taken := PestilenceFx.victims_at(crowd._field, mid)
				if taken.has(p) and taken.has(o.p) and _flock_clear(bc, d, mid, PLAGUE_CLEAR):
					_cast(ctx, "pestilence", mid)
					return "pestilence on a %s pair" % th.kind
	if _ready(bc, ctx, "deathmark"):
		var live: Array = threats.filter(func(th: Dictionary) -> bool: return not _doomed(th.p))
		for i in live.size():
			var th: Dictionary = live[i]
			var behind := 0  # the men of the same hour still to be marked after this one, each twenty seconds on
			for j in range(i + 1, live.size()):
				if float(live[j].t) - float(th.t) <= MARK_HOUR:
					behind += 1
			if float(th.t) <= _lead(ctx, d, th, MARK_LEAD) + 21.0 * float(behind):
				_cast(ctx, "deathmark", (th.p as Person).ground_pos)
				return "death mark a %s" % th.kind
	return ""


# --- Veil: Silent Doom, Blight ---

## Silent Doom is a kill nobody sees when it can be: a victim's witnesses within Crowd.DOOM_WITNESS are the opposition only (a patrolman's own
## mate), never a citizen; not `strict` lets a citizen see too (a watcher about to see a believer, last resort).
static func _doom_ok(d: HideFaithfulDirector, crowd: Crowd, at: Vector2, strict: bool) -> bool:
	if not strict:
		return true
	var watchers := {}
	for w: Dictionary in _watchers(d):
		watchers[w.p] = true
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside or p.ground_pos.distance_to(at) <= SilentDoom.RADIUS:
				continue
			if p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + 0.3 and not watchers.has(p):
				return false
	return true


## Blight the Bell Tower once (a cracked bell is never rung, so a seen death rings nothing); then Silent Doom a marched believer's seizer, then
## the soonest watcher within DOOM_LEAD of his sight, one man at a time, seen only by his own side.
static func act_veil(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var crowd: Crowd = ctx.crowd
	if _ready(bc, ctx, "blight") and crowd.bell != null and crowd.bell.tower != null and not crowd.bell.tower.blighted and d._clock >= 2.0:
		_cast(ctx, "blight", crowd.bell.tower.center())
		return "blight the Bell Tower, so a seen death rings nothing"
	if not _ready(bc, ctx, "doom"):
		return ""
	for sz: Dictionary in _seizers(d):
		var at := _seizer_aim(sz, SilentDoom.RADIUS, SilentDoom.T_STRIKE)
		if at != Vector2.INF:
			_cast(ctx, "doom", at)
			return "doom a %s seizer" % sz.kind
	for th: Dictionary in _view(ctx, d).threats:
		if float(th.t) > _lead(ctx, d, th, DOOM_LEAD):
			continue
		var at := GOD_T1.road_ahead(th.p, SilentDoom.T_STRIKE)
		if _flock_clear(bc, d, at, SilentDoom.RADIUS + BLOW_GAP) and _doom_ok(d, crowd, at, float(th.t) > 6.0 and d._clock - float(ctx.memo.get("last_cast", 0.0)) < IDLE_RELAX):
			_cast(ctx, "doom", at)
			return "doom a %s" % th.kind
	return ""


# --- Passage: Thornwall, Mirrorfold (Thornwall is drafted and not cast: no trail is ever taken in these runs, a wall across the search's street changed nothing) ---

## Where household `i`'s mirror lies: the way in on its road, MIRROR_AHEAD seconds of the walk beyond where its lamp is (from the door while it
## is inside), and the way out past the wall: the outside ground nearest the way in, pushed MIRROR_BEYOND farther out (and kept off the gates'
## outer posts), with room all round for the file. {in, out}, empty when no way out is found.
static func _mirror_for(bc, ctx: Dictionary, d: HideFaithfulDirector, i: int) -> Dictionary:
	var rc := _road(ctx, d, i)
	var h: ExodusDirector.Household = d.households[i]
	var lead := d.lamp(i)
	var from := 0.0
	if h.out and lead != null:
		from = _progress(rc, (lead.man as Person).ground_pos)
	var speed := maxf(Person.PANIC_SPEED * d.tune_believer_pace, 0.3)
	var way_in := _point(rc, from + MIRROR_AHEAD * speed + 2.0)
	var spot: Vector2 = GOD_T1.outside_spot(bc, ctx, way_in, 14.0)
	if spot == Vector2.INF:
		return {}
	var away := (spot - way_in).normalized()
	var way_out := spot
	for k in 8:
		var try := spot + away * (MIRROR_BEYOND + 0.5 * float(k))
		if (ctx.crowd as Crowd)._grid.walkable(try) and Walls.outside(try + away * 1.5) and way_in.distance_to(try) >= MirrorfoldFx.MIN_APART:
			way_out = try
			break
	# Not within sight of an outer post (the fold sets the file down out of the walls, and an outer post sees them first).
	for post: Vector2 in d.watch_posts:
		if post.distance_to(way_out) < EscortDirector.SIGHT + 2.5:
			return {}
	return {"in": way_in, "out": way_out}


## Mirrorfold: the household about to come out (or walking) is folded out past the wall at once -- the way in laid across its road a few seconds
## ahead of the lamp, the way out beyond the wall, the whole file stepping on it one by one. The mirror lives 30 s and takes 54 to ready: one
## household each. (The idle between the two mirrors is the first one's cooldown, 54.2 s: ruling P5-T9-R9 / P5-T11-R2.)
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var memo: Dictionary = ctx.memo
	if _ready(bc, ctx, "mirror"):
		for i in d.households.size():
			var h: ExodusDirector.Household = d.households[i]
			if h.done or memo.get("folded_%d" % i, false):
				continue
			var live := false
			for c: EscortDirector.Charge in h.members:
				live = live or (not d._resolved(c) and not c.held)
			if not live or (not h.out and d.due_in(i) > MIRROR_FOR):
				continue
			var m := _mirror_for(bc, ctx, d, i)
			if m.is_empty():
				continue
			_cast(ctx, "mirror", m["in"], {"to": m["out"]})
			memo["folded_%d" % i] = true
			return "mirror %s out: in at (%.1f, %.1f), out at (%.1f, %.1f)" % [h.words, m["in"].x, m["in"].y, m["out"].x, m["out"].y]
	return ""


# --- Decree: Leaving Is Prohibited, The Bell Lies ---

## The law is a circle its people cannot leave (NoLeaveFx: they are set back onto its edge), not a hand on a shoulder: laid so a group stands at
## the edge on the side it is walking from, it stops that group for the hold. The centre is NoLeaveFx.RADIUS - CAGE_SLACK behind the group's lead
## along its way; the others of the group stand within the circle. {} when the group's way is not known.
static func _cage(d: HideFaithfulDirector, members: Array) -> Dictionary:
	if members.is_empty():
		return {}
	var lead: Person = members[0]
	var dir := Vector2.ZERO
	for m: Person in members:
		var way := GOD_T1.road_ahead(m, 3.0) - m.ground_pos
		if way.length() > dir.length():
			dir = way
	if dir.length() < 0.05:
		return {}
	dir = dir.normalized()
	for m: Person in members:
		if m.ground_pos.dot(dir) > lead.ground_pos.dot(dir):
			lead = m
	var centre := lead.ground_pos - dir * (NoLeaveFx.RADIUS - CAGE_SLACK)
	for m: Person in members:
		if m.ground_pos.distance_to(centre) > NoLeaveFx.RADIUS - 0.1:
			return {}
	return {"at": centre, "lead": lead}


## A cage at `at` keeps every believer of the next fifteen seconds out of reach of anyone inside it (RADIUS + SIGHT + SIGHT_PAD from its centre:
## the law holds a believer who walks in too, and a watcher caged sees whatever comes within sight of any place of the circle).
static func _cage_safe(view: Dictionary, at: Vector2) -> bool:
	var reach := NoLeaveFx.RADIUS + EscortDirector.SIGHT + SIGHT_PAD
	var s := 0.0
	while s <= NoLeaveFx.HOLD_TIME + 1.0:
		for e: Dictionary in view.exposed:
			if s >= float(e.delay) and at.distance_to(_point(e.rc, float(e.from) + float(e.speed) * (s - float(e.delay)))) <= reach:
				return false
		s += READ_STEP
	return true


## Walkable ground within 14 of `from` as far as it can be found from every household's road (at least FAR_ROAD when it can): where the guard is
## called, so the soldiers it takes stand and then walk back a long way from the roads, not at them.
static func _far_from_roads(ctx: Dictionary, d: HideFaithfulDirector, from: Vector2) -> Vector2:
	var best := from
	var far := -1.0
	for dist in [6.0, 9.0, 12.0, 14.0]:
		for k in 16:
			var g: Vector2 = from + Vector2.from_angle(TAU * float(k) / 16.0) * float(dist)
			if not (ctx.crowd as Crowd)._grid.walkable(g) or Walls.outside(g):
				continue
			var near := INF
			for i in d.households.size():
				var rc := _road(ctx, d, i)
				var pts: Array = rc.pts
				for q in range(pts.size() - 1):
					near = minf(near, Geometry2D.get_closest_point_to_segment(g, pts[q], pts[q + 1]).distance_to(g))
			if near > far:
				far = near
				best = g
	return best


## The Bell Lies calls the guard to the soldiers a household would meet (the call takes soldiers only: they stand away twenty seconds, blind) when
## the first of them is near his sight, or away from a seizer. Leaving Is Prohibited cages the group that is the soonest to meet a household -- the
## inquisitors, or a patrol -- at the edge of the circle on the side it walks from (_cage()), whenever it is ready and the cage keeps the households
## out of reach (_cage_safe()): fifteen seconds in twenty the group stands, and walks the other five.
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var view := _view(ctx, d)
	if _ready(bc, ctx, "belllies"):
		for sz: Dictionary in _seizers(d):
			_cast(ctx, "belllies", (sz.s as Person).ground_pos + Vector2(3.0, 0.0), {"mode": "guard"})
			return "call the guard away from a %s seizer at (%.1f, %.1f)" % [sz.kind, (sz.s as Person).ground_pos.x, (sz.s as Person).ground_pos.y]
		var group := PackedVector2Array()
		var first := INF
		for th: Dictionary in view.threats:
			if th.kind == "watch":  # the gate's watch: the one the law cannot hold (a patrol can be caged); lay inquisitors the call does not take
				first = minf(first, float(th.t))
		if first <= GUARD_LEAD:
			for th: Dictionary in view.threats:
				if th.kind != "inquisitor" and float(th.t) <= first + GUARD_SPAN:
					group.append((th.p as Person).ground_pos)
			var mid := Vector2.ZERO
			for g in group:
				mid += g
			var there := _far_from_roads(ctx, d, mid / float(group.size()))
			_cast(ctx, "belllies", there, {"mode": "guard"})
			return "call the guard away from the roads, to (%.1f, %.1f)" % [there.x, there.y]
	if _ready(bc, ctx, "noleave"):
		# A marched believer and his seizer caged behind them on the road to the Temple: the march stops fifteen seconds in twenty, and a believer
		# held until dawn is neither taken nor dead.
		for sz: Dictionary in _seizers(d):
			var march := _cage(d, [sz.s, sz.b])
			if not march.is_empty():
				_cast(ctx, "noleave", march.at)
				return "leaving is prohibited on a %s seizer and his prisoner" % sz.kind
		var groups: Array = []  # [{members, t, kind}] by the squad each belongs to
		for th: Dictionary in view.threats:
			if th.kind == "watch" or float(th.t) > LAW_CRAWL:
				continue
			var squad: Array = d.inquisitors if th.kind == "inquisitor" else []
			if th.kind == "patrol":
				for sq: Array in d.patrols:
					if sq.has(th.p):
						squad = sq
			var found := false
			for g: Dictionary in groups:
				if g.squad == squad:
					found = true
			if not found:
				var members: Array = []
				for v: Variant in squad:
					if d._watching(v) and not d._seizing(v):
						members.append(v)
				groups.append({"squad": squad, "members": members, "t": th.t, "kind": th.kind})
		for g: Dictionary in groups:
			var cage := _cage(d, g.members)
			if not cage.is_empty() and _cage_safe(view, cage.at):
				_cast(ctx, "noleave", cage.at)
				return "leaving is prohibited: a %s group caged behind its lead" % g.kind
	return ""


# --- Dominion: Mind Whisper, Discord ---

## Discord on a tight pair of watchers (both within its circle) a household would see, no believer inside it; Mind Whisper sends the soonest
## watcher eight units straight away from the household; a marched believer's seizer is Discorded, else whispered off.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := _hf(ctx)
	if d == null:
		return ""
	var crowd: Crowd = ctx.crowd
	for sz: Dictionary in _seizers(d):
		var s: Person = sz.s
		if _ready(bc, ctx, "discord"):
			_cast(ctx, "discord", s.ground_pos)
			return "discord a %s seizer" % sz.kind
		if _ready(bc, ctx, "whisper") and not s.shaken():
			_cast(ctx, "whisper", s.ground_pos, {"target": s, "to": bc._prisoner_away(crowd, s, (sz.b as Person).ground_pos)})
			return "whisper a %s seizer off" % sz.kind
	var view := _view(ctx, d)
	var threats: Array = view.threats
	if _ready(bc, ctx, "discord"):
		for th: Dictionary in threats:
			if float(th.t) > DISCORD_LEAD:
				continue
			var p: Person = th.p
			var mid := p.ground_pos
			var together := 1
			for o: Dictionary in threats:
				if o.p != p and (o.p as Person).ground_pos.distance_to(p.ground_pos) <= DiscordFx.DISCORD_R * 2.0 - 0.3:
					together += 1
					mid = (p.ground_pos + (o.p as Person).ground_pos) * 0.5
					break
			if together >= 2 and _flock_clear(bc, d, mid, DiscordFx.DISCORD_R + 0.6):
				_cast(ctx, "discord", mid)
				return "discord a %s pair" % th.kind
	if _ready(bc, ctx, "whisper"):
		for th: Dictionary in threats:
			if float(th.t) > WHISPER_LEAD:
				continue
			var p: Person = th.p
			if p.shaken() or p.mind == Person.Mind.WHISPERED:
				continue
			var from := p.ground_pos + Vector2.LEFT
			var exposed: Array = view.exposed
			if not exposed.is_empty():
				var e: Dictionary = exposed[0]
				from = _point(e.rc, float(e.from))
			_cast(ctx, "whisper", p.ground_pos, {"target": p, "to": bc._prisoner_away(crowd, p, from)})
			return "whisper a %s off" % th.kind
	return ""
