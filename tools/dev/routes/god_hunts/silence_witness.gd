extends RefCounted
## The scripted policies of the Hunt "Silence the witness" (Tier 2; god P5, MS §7, plan Task 3): the shared plan with the def's loadout (act_shared, Task 5),
## one act_<type> per god type, and the report line (state). All six types are written (Task 10); FILLED lists them. Decree has no route (C9): its policy is
## the best honest delay. Called by god_hunts.gd (Ruling P5-7: the policies live here, behaviour_check is never edited by a Hunt task).

## The god types whose policy is written (all six, god P5 Task 10; Decree is a reported gap: MS §9 open issue 1, ruling C9).
const FILLED := ["ruin", "death", "veil", "passage", "decree", "dominion"]

## What each type drafts here (MS §7: at most 3 keys, within TierBook.dp(2) Might at level 1, all in GodTree.keys_for(type, 2)); god_hunts.gd's
## problems() checks it, and a refusal names the key (Ruling P5-8: checked, not chosen at run time).
const LOADOUT := {
	"ruin": ["smite", "heaven", "tornado"],
	"death": ["deathmark", "pestilence", "glacial"],
	"veil": ["doom", "blight", "tsunami"],
	"passage": ["thorns", "mirror"],
	"decree": ["noleave", "belllies", "magnify"],
	"dominion": ["whisper", "discord", "madness"],
}

## The pieces every Hunt's policy shares (god_t1.gd): road_ahead().
const GodT1 := preload("res://tools/dev/routes/god_t1.gd")
## A mate farther than this from the witness (Crowd.DOOM_WITNESS plus a margin for the step he takes while the Doom falls) cannot carry the word on.
const SW_CLEAR := 2.3
## Discord holds a witness this close to the Temple (mission seconds), when nothing else is ready.
const SW_DISCORD_AT := 14.0
## The last seconds before a house sends its witness in which the policy clears its door of bystanders (the Bell-Ringers' prep, for the idle rule).
const SW_PREP := 25.0
## How near a waiting house's door a bystander is whispered off.
const SW_DOOR_R := 3.0


## The numbers this Hunt's report lines print: the witnesses stopped, the relays, the ones walking and the soonest to the Temple.
static func state(_bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as SilenceWitnessDirector
	if d == null:
		return ""
	var eta := d.word_eta()
	var rules: Rules = ctx.rules
	return "stopped=%d relays=%d running=%d eta=%s word=%s phase=%s rate=%.1f clock=%.0f" % [d.stopped(), int(d.report().relays), d.running().size(),
		"-" if eta == INF else "%.0f" % eta, d.word_in(), d.hint_phase(), rules.clock_rate, d._clock]


## The shared plan with the def's own loadout (Silent Doom, Mind Whisper, Discord): what it cast, or "". As a player plays it: the witness
## closest to the Temple first. His mates carry the word on, so with one close enough to see (SW_CLEAR) the mate is taken off him first -- Mind
## Whisper sends him away (held, he cannot run on), else Silent Doom on one who stands alone -- and Silent Doom takes the witness once no mate stands
## near; Discord holds a witness within SW_DISCORD_AT of the Temple when nothing else is ready. Between witnesses a bystander at the next house's door
## is whispered off in its last SW_PREP seconds, while Mind Whisper will be ready again by then. Never a loud power.
static func act_shared(bc, ctx: Dictionary) -> String:
	var d := ctx.get("d") as SilenceWitnessDirector
	if d == null:
		return ""  # (no night yet, or another mission's: the dispatch test calls it with an empty ctx)
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var doom: bool = bc._slot_ready(rules, slots, "doom")
	var whisper: bool = bc._slot_ready(rules, slots, "whisper")
	var discord: bool = bc._slot_ready(rules, slots, "discord")
	var going: Array[WitnessDirector] = []
	for r in d.running():
		if WarningDirector._alive(r.messenger) and not r.messenger.inside:
			going.append(r as WitnessDirector)
	going.sort_custom(func(a: WitnessDirector, b: WitnessDirector) -> bool: return a.eta() < b.eta())
	for r in going:
		var w := r.messenger
		var near := _near_mates(r, SW_CLEAR)
		if doom and near.is_empty():
			rules.cast(slots.doom, w.ground_pos)
			return "doom the witness"
		if whisper:
			for m in near:
				if bc._whisperable(m):
					rules.cast(slots.whisper, m.ground_pos, {"target": m, "to": bc._ringers_off(d, m, w.ground_pos)})
					return "whisper a mate off the witness"
		if doom:
			if near.size() >= 2 and near[0].ground_pos.distance_to(near[1].ground_pos) <= SilentDoom.RADIUS * 2.0:
				var mid := (near[0].ground_pos + near[1].ground_pos) * 0.5
				if bc._ringers_only(crowd, mid, [near[0], near[1]]):
					rules.cast(slots.doom, mid)
					return "doom both mates"
			for m in near:
				if bc._ringers_only(crowd, m.ground_pos, [m]):
					rules.cast(slots.doom, m.ground_pos)
					return "doom a mate"
		if discord and r.eta() <= SW_DISCORD_AT and w.mind != Person.Mind.CONFUSED:
			rules.cast(slots.discord, w.ground_pos)
			return "discord the witness"
	if going.is_empty():
		return _prep(bc, ctx, d, whisper)
	return ""


## The witness's own mates (alive, out of doors, able to carry the word on) within `reach` of him now or when a Silent Doom would fall, nearest first.
static func _near_mates(r: WitnessDirector, reach: float) -> Array[Person]:
	var out: Array[Person] = []
	var w := r.messenger
	for v: Variant in r.mates:
		if not WarningDirector._alive(v) or v == w:
			continue
		var m := v as Person
		if m.inside or m.held_by_god() or m.mind == Person.Mind.FLEE:
			continue
		if m.ground_pos.distance_to(w.ground_pos) <= reach \
				or GodT1.road_ahead(m, SilentDoom.T_STRIKE).distance_to(GodT1.road_ahead(w, SilentDoom.T_STRIKE)) <= reach:
			out.append(m)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(w.ground_pos) < b.ground_pos.distance_squared_to(w.ground_pos))
	return out


## Between witnesses: in the last SW_PREP seconds before a house sends its witness, a citizen near its door is whispered off (it clears the first
## stretch of his road). "" when nobody stands there or Mind Whisper is not ready.
static func _prep(bc, ctx: Dictionary, d: SilenceWitnessDirector, whisper: bool) -> String:
	var i := d.next_post()
	if i < 0 or not whisper:
		return ""
	var due := d.timeline.seconds_to("out_%d" % i)
	if due > SW_PREP or due < float(PowerBook.get_power("whisper").cooldown):  # (Mind Whisper must be ready again when he comes out)
		return ""
	var crowd: Crowd = ctx.crowd
	for p in crowd.citizens:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or p.ground_pos.distance_to(d.doors[i]) > SW_DOOR_R:
			continue
		if bc._whisperable(p) and not d.ringers[i].crew().has(p):
			(ctx.rules as Rules).cast(ctx.slots.whisper, p.ground_pos, {"target": p, "to": bc._ringers_off(d, p, d.doors[i])})
			return "whisper a bystander off the %s door" % d.post_names[i]
	return ""


## The pacing every type's policy keeps (god P5 Task 10, MS §0 and §7): two real casts to a witness, an opener and a finisher at least SW_GAP seconds
## apart, with the witness stopped by the finisher. The Hunt's items come on the clock (20, 75, 130, 185 s) or 45 s after the witness before is stopped;
## a lone cast per witness, made at once, leaves a 45 s chain plus the time he takes to step out between two casts (idle 46+ s), so the opener works the file
## (a mate, the street) and the finisher stops it -- the "mates first, then the witness" a player plays. Seconds are the mission's (the director's clock).
const SW_GAP := 9.5
## The most seconds a Silent Doom on a witness with no mate left waits for a street where no one would see him fall (the Veil route: "the witness unseen").
const SW_SEEN_PATIENCE := 5.0
## Seconds to the Temple at which a finisher is cast whatever the gap (the walk is nearly out: no time to wait for the opener's effect).
const SW_URGENT := 11.0
## The least seconds a witness must be from the Temple for a Death Mark on a mate (the fuse is 10 s and the mate need not die before him), for Pestilence
## (it takes PlagueManager.PLAGUE_LIFE and the cast's 0.4 s) and for Glacial Cataclysm (its peaks kill at 3.2 s).
const SW_PLAGUE_ETA := 7.5
const SW_GLACIAL_ETA := 5.0
## Heaven Splitter's core kills within CORE_KILL (1.6) of the strike at T_STRIKE: the file must lie within this of its aim, led by that many seconds.
const SW_HEAVEN_FIT := 1.3
## Glacial Cataclysm: the file must lie within this of its aim when the peaks rise (it freezes those within 5 and kills those within 1.6 of the aim).
const SW_GLACIAL_FIT := 1.5
const SW_GLACIAL_LEAD := 2.8
## A mirror's way in is laid this far ahead of the witness along his street, and its way out is looked for within this reach of the way in.
const SW_MIRROR_AHEAD := 3.0
const SW_MIRROR_REACH := 16.0
## A thornwall goes across the street this far ahead of the file.
const SW_THORN_AHEAD := 4.0
## The mirror is laid this long after the thornwall (the wall holds him 25 s: the mirror, which lasts 30 s, waits for him past it).
const SW_MIRROR_WAIT := 15.0
## The whisper that takes a witness out of the walls is cast this long after the Discord that held him (it lifts after 15 s).
const SW_DOM_GAP := 15.0
## Mind Whisper's reach, less a little for the walk's start; the longest hop it sends a witness.
const SW_WHISPER_REACH := MindWhisperFx.REACH - 0.5
## Heaven Splitter's effect (its consts name the strike's moment).
const HEAVEN_FX := preload("res://src/fx/set2/heaven_splitter.gd")
## Leaving Is Prohibited (Decree): the hold lasts HOLD_TIME.
const LEAVING_FX := preload("res://src/fx/decree/leaving_is_prohibited.gd")


## Mission seconds since the Hunt's clock began (the director's).
static func _now(d: SilenceWitnessDirector) -> float:
	return d._clock


## The witnesses walking now (out of doors, not stopped), the soonest to the Temple first.
static func _walkers(d: SilenceWitnessDirector) -> Array[WitnessDirector]:
	var out: Array[WitnessDirector] = []
	for r in d.running():
		if WarningDirector._alive(r.messenger) and not r.messenger.inside:
			out.append(r as WitnessDirector)
	out.sort_custom(func(a: WitnessDirector, b: WitnessDirector) -> bool: return _eta(a) < _eta(b))
	return out


## Mission seconds until the witness reaches the Temple, by the street from where he stands at his pace -- not WitnessDirector.eta(), which counts the walk
## he is on and so reads short for a man frightened off his road (a Doom on his mate sends him running another way): the policy's clocks go by the street.
static func _eta(r: WitnessDirector) -> float:
	if not WarningDirector._alive(r.messenger):
		return INF
	var rate := r.rules.clock_rate if is_instance_valid(r.rules) else 1.0
	return r.street_left() / maxf(Person.PANIC_SPEED * r.messenger.pace, 0.05) * rate


## The key under which a witness's last cast is kept in the memo.
static func _key(r: WitnessDirector, what: String) -> String:
	return "%s_%d" % [what, r.get_instance_id()]


## Mission seconds since this witness was last cast at by the policy (INF for never).
static func _since(d: SilenceWitnessDirector, memo: Dictionary, r: WitnessDirector) -> float:
	var k := _key(r, "cast")
	return _now(d) - float(memo[k]) if memo.has(k) else INF


## The policy cast at this witness now.
static func _noted(d: SilenceWitnessDirector, memo: Dictionary, r: WitnessDirector) -> void:
	memo[_key(r, "cast")] = _now(d)


## The finisher may fall: the opener was cast SW_GAP seconds ago, or there was no mate to open on (`alone`: a witness with none left, who is struck at once), or the
## witness is within SW_URGENT of the Temple.
static func _finish_ok(d: SilenceWitnessDirector, memo: Dictionary, r: WitnessDirector, alone := false) -> bool:
	var since := _since(d, memo, r)
	return (since != INF and since >= SW_GAP) or (alone and since == INF) or _eta(r) <= SW_URGENT


## The witness and the mates who could carry the word on (alive, out of doors, near him, not held by the god): the file one strike has to take.
static func _file(r: WitnessDirector) -> Array[Person]:
	var out: Array[Person] = [r.messenger]
	out.append_array(_near_mates(r, SW_CLEAR))
	return out


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


## Where the file stands `seconds` on, each walking the road he is on.
static func _led(file: Array[Person], seconds: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in file:
		out.append(GodT1.road_ahead(p, seconds))
	return out


## The direction the witness walks (the street ahead of him), or RIGHT.
static func _heading(r: WitnessDirector, ctx: Dictionary) -> Vector2:
	var w := r.messenger
	var ahead := _along(ctx, w.ground_pos, 3.0)
	var d := ahead - w.ground_pos
	return d.normalized() if d.length() > 0.05 else Vector2.RIGHT


## The point `dist` along the street (the walk grid's way) from `from` to the Temple's door; the door if the way is shorter; `from` if there is none.
static func _along(ctx: Dictionary, from: Vector2, dist: float) -> Vector2:
	var d := ctx.d as SilenceWitnessDirector
	var crowd: Crowd = ctx.crowd
	var path := crowd._grid.path(from, d.lantern_door())
	var at := from
	var left := dist
	for q in path:
		var seg := at.distance_to(q)
		if seg >= left:
			return at.move_toward(q, left)
		left -= seg
		at = q
	return at


## The log line for a strike: what it was and how many it took.
static func _said(what: String, file: Array[Person]) -> String:
	return "%s (file of %d)" % [what, file.size()]


# --- Ruin: Smite, Heaven Splitter, Tornado ---

## Mates first, then the witness (the pacing above). The opener is a Smite on the nearest mate who could carry the word on, led by its T_STRIKE; the finisher
## Heaven Splitter along the file when what is left of it fits the strike's core (SW_HEAVEN_FIT, led by T_STRIKE), else Smite again on the next mate and
## last the witness. Cooldowns: Smite 10 s, Heaven Splitter 30 s. A witness within SW_URGENT of the Temple is struck with whatever is ready, at once.
static func act_ruin(bc, ctx: Dictionary) -> String:
	var d := ctx.d as SilenceWitnessDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	for r in _walkers(d):
		var w := r.messenger
		var mates := _near_mates(r, SW_CLEAR)
		var file := _file(r)
		var urgent := _eta(r) <= SW_URGENT
		var heaven: bool = bc._slot_ready(rules, slots, "heaven")
		var smite: bool = bc._slot_ready(rules, slots, "smite")
		if heaven and file.size() >= 2 and _finish_ok(d, ctx.memo, r, mates.is_empty()):
			var aim := _enclose(_led(file, HEAVEN_FX.T_STRIKE))
			if float(aim.r) <= SW_HEAVEN_FIT:
				rules.cast(slots.heaven, aim.at, {"dir": _heading(r, ctx)})
				_noted(d, ctx.memo, r)
				return _said("heaven splitter along the file", file)
		if smite:
			if not mates.is_empty():
				var m := mates[0]
				var at := GodT1.road_ahead(m, SmiteFx.T_STRIKE)
				rules.cast(slots.smite, at)
				_noted(d, ctx.memo, r)
				return "smite a mate who would carry the word on"
			if _finish_ok(d, ctx.memo, r, mates.is_empty()) or urgent:
				rules.cast(slots.smite, GodT1.road_ahead(w, SmiteFx.T_STRIKE))
				_noted(d, ctx.memo, r)
				return "smite the witness (no mate left to see)"
	return ""


# --- Death: Death Mark, Pestilence, Glacial Cataclysm ---

## Mates first, then the witness. The opener is a Death Mark on the nearest mate who could carry the word on (frail and slow, he falls behind the file and
## dies in 10 s); the finisher Pestilence on the file (the three nearest the aim catch it; they die PlagueManager.PLAGUE_LIFE later together), else, with the
## plague cooling (48 s against a witness every 25-55), Glacial Cataclysm when the file lies within SW_GLACIAL_FIT of its aim as the peaks rise, else Death
## Mark on a witness with no mate left. Death stirs the Lantern (every death seen turns the clock), so a second witness may come at x2: the plague is kept
## for the witness who cannot be reached by a Glacial, and neither is cast on a witness with too little road left to wait for it.
static func act_death(bc, ctx: Dictionary) -> String:
	var d := ctx.d as SilenceWitnessDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	for r in _walkers(d):
		var w := r.messenger
		var file := _file(r)
		var mates := _near_mates(r, SW_CLEAR)
		var eta := _eta(r)
		if _sick(file):
			continue  # the plague is on its way: the file dies together
		if _marked(w) and mates.is_empty():
			continue  # the witness is marked and alone: his time is the mark's
		var ready := _finish_ok(d, ctx.memo, r, mates.is_empty())
		if ready and bc._slot_ready(rules, slots, "pestilence") and eta >= SW_PLAGUE_ETA:
			var spot := _plague_aim(crowd, file)
			if spot != Vector2.INF:
				rules.cast(slots.pestilence, spot)
				_noted(d, ctx.memo, r)
				return _said("pestilence on the file", file)
		if ready and bc._slot_ready(rules, slots, "glacial") and eta >= SW_GLACIAL_ETA:
			var aim := _enclose(_led(file, SW_GLACIAL_LEAD))
			if float(aim.r) <= SW_GLACIAL_FIT:
				rules.cast(slots.glacial, aim.at)
				_noted(d, ctx.memo, r)
				return _said("glacial cataclysm on the file (the plague is cooling)", file)
		if bc._slot_ready(rules, slots, "deathmark"):
			var unmarked: Array[Person] = []
			for m in mates:
				if not _marked(m) and m.sick_left <= 0.0:
					unmarked.append(m)
			if not unmarked.is_empty() and eta >= DeathMarkFx.MARK_TIME + 2.0:
				rules.cast(slots.deathmark, unmarked[0].ground_pos)
				_noted(d, ctx.memo, r)
				return "death mark on a mate who would carry the word on"
			if mates.is_empty() and not _marked(w) and w.sick_left <= 0.0 and eta >= DeathMarkFx.MARK_TIME + 1.0:
				rules.cast(slots.deathmark, w.ground_pos)
				_noted(d, ctx.memo, r)
				return "death mark on the witness (no mate left to see)"
	return ""


## `p` wears a Death Mark.
static func _marked(p: Person) -> bool:
	return p.statuses.has(&"frail")


## Every one of `file` is already sick.
static func _sick(file: Array[Person]) -> bool:
	for p in file:
		if p.sick_left <= 0.0:
			return false
	return true


## An aim for Pestilence that infects all of `file` (the three nearest to it within PestilenceFx.INFECT_R, the healthy ones); INF for none. The aim
## that takes the fewest others, the nearest the file's middle among equals.
static func _plague_aim(crowd: Crowd, file: Array[Person]) -> Vector2:
	var pending: Array[Person] = []
	for p in file:
		if p.sick_left <= 0.0:
			pending.append(p)
	if pending.is_empty():
		return Vector2.INF
	var pts: Array[Vector2] = []
	for p in pending:
		pts.append(p.ground_pos)
	var mid: Vector2 = _enclose(pts).at
	var tries: Array[Vector2] = [mid]
	for q in pts:
		tries.append(q)
	var best := Vector2.INF
	var fewest := 99
	for g in tries:
		var victims := PestilenceFx.victims_at(crowd._field, g)
		var all := true
		for p in pending:
			all = all and victims.has(p)
		if all and victims.size() - pending.size() < fewest:
			best = g
			fewest = victims.size() - pending.size()
	return best


# --- Veil: Silent Doom, Blight, Tsunami Breaker ---

## The spec's route (MS §3, Veil): Blight the bell at 0:00, Doom each mate (they stand 1.5 from the witness and 2.4 or more from each other: one Doom each), then
## the witness unseen. Blight ruins the Bell Tower once, so the bell never tolls and the Lantern never turns the clock to x1.5 for a death a bystander saw. Silent
## Doom takes everyone within SilentDoom.RADIUS of its aim as it is cast (not led) and has a 10 s cooldown: the mates are the opener and the second cast, the
## witness the finisher, 20 s on, so a witness is stopped late enough that the schedule, not the chain, brings the next. A witness left a mate sees him fall
## and runs on, so the next Doom is his. A witness within SW_URGENT of the Temple is taken at once with the mate beside him when one Doom reaches both, and
## Tsunami Breaker (loud, 60 s) takes the file when it fits and Doom is cooling.
static func act_veil(bc, ctx: Dictionary) -> String:
	var d := ctx.d as SilenceWitnessDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not ctx.memo.has("blighted") and bc._slot_ready(rules, slots, "blight"):
		ctx.memo["blighted"] = true
		rules.cast(slots.blight, City.current().landmark(&"bell_tower").get_center())
		return "blight the Bell Tower (no toll all night)"
	for r in _walkers(d):
		var w := r.messenger
		var mates := _near_mates(r, SW_CLEAR)
		var file := _file(r)
		var doom: bool = bc._slot_ready(rules, slots, "doom")
		if doom:
			if mates.is_empty():
				# The witness unseen (the spec's words): the Doom waits, at most SW_SEEN_PATIENCE, for a moment when no one but his own is within sight of him.
				var waiting_since := _now(d) if not ctx.memo.has(_key(r, "alone")) else float(ctx.memo[_key(r, "alone")])
				ctx.memo[_key(r, "alone")] = waiting_since
				if _seen_by(ctx.crowd, w, file) > 0 and _now(d) - waiting_since < SW_SEEN_PATIENCE and _eta(r) > SW_URGENT:
					continue
				rules.cast(slots.doom, w.ground_pos)
				_noted(d, ctx.memo, r)
				return "doom the witness (no mate left to see)"
			if _eta(r) <= SW_URGENT:
				for m in mates:
					var mid := (w.ground_pos + m.ground_pos) * 0.5
					if mid.distance_to(w.ground_pos) <= SilentDoom.RADIUS - 0.05 and mid.distance_to(m.ground_pos) <= SilentDoom.RADIUS - 0.05:
						rules.cast(slots.doom, mid)
						_noted(d, ctx.memo, r)
						return "doom the witness and the mate beside him"
				rules.cast(slots.doom, w.ground_pos)
				_noted(d, ctx.memo, r)
				return "doom the witness (a mate runs on)"
			rules.cast(slots.doom, _mate_aim(w, mates[0]))
			_noted(d, ctx.memo, r)
			return "doom the mate nearest the witness"
		if _eta(r) <= SW_URGENT and bc._slot_wait(rules, slots, "doom") > _eta(r) - 3.0 and bc._slot_ready(rules, slots, "tsunami"):
			var wave := _tsunami_aim(r, ctx, file)
			if wave.has("at"):
				rules.cast(slots.tsunami, wave.at, {"dir": wave.dir})
				_noted(d, ctx.memo, r)
				return _said("tsunami over the file", file)
	return ""


## How many people, out of doors and not of `file`, stand within sight of a death at `w` (Crowd.DOOM_WITNESS and a step): who would see him fall.
static func _seen_by(crowd: Crowd, w: Person, file: Array[Person]) -> int:
	var n := 0
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p.is_alive() and not p.inside and not file.has(p) and p.ground_pos.distance_to(w.ground_pos) <= Crowd.DOOM_WITNESS + 0.3:
				n += 1
	return n


## Where a Silent Doom takes the mate `m` and leaves the witness `w` standing: on the mate, or half a unit past him away from the witness when the mate stands
## closer than the Doom's reach to the witness (a Doom takes everyone within SilentDoom.RADIUS, and the mates is to be taken first).
static func _mate_aim(w: Person, m: Person) -> Vector2:
	if m.ground_pos.distance_to(w.ground_pos) > SilentDoom.RADIUS + 0.1:
		return m.ground_pos
	var away := (m.ground_pos - w.ground_pos).normalized() if m.ground_pos.distance_to(w.ground_pos) > 0.01 else Vector2.RIGHT
	var aim := m.ground_pos + away * 0.5
	return aim if aim.distance_to(w.ground_pos) > SilentDoom.RADIUS + 0.05 else m.ground_pos


## Where Tsunami Breaker's wall is laid so the file stands within its crash (3 units round the end of the lane, 4.3 s on) and in its lane: {at, dir}, or {}.
static func _tsunami_aim(r: WitnessDirector, ctx: Dictionary, file: Array[Person]) -> Dictionary:
	var crash_at := 4.3
	var pts := _led(file, crash_at)
	var end := _enclose(pts)
	if float(end.r) > 2.0:
		return {}
	var dir := _heading(r, ctx)
	return {"at": (end.at as Vector2) - dir * 6.5, "dir": dir}


# --- Passage: Thornwall, Mirrorfold Passage ---

## The street first, then the witness out of the walls. The opener is a Thornwall across the street ahead of the file as he stands at his door (in a lane no
## wider than its 3 units it shuts him in until it withers, 25 s); the finisher a Mirrorfold Passage SW_MIRROR_WAIT seconds on, whose way in lies on the
## street ahead of him (beyond the wall when he is still shut in: the street as it ran before the wall, kept in the memo) and whose way out lies on ground past
## the wall: the file walks on, is that instant outside, and the witness is stopped (walls_stop; MS §7). Without a thornwall to cast the mirror is laid at once.
static func act_passage(bc, ctx: Dictionary) -> String:
	var d := ctx.d as SilenceWitnessDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	for r in _walkers(d):
		var w := r.messenger
		var thorn: bool = bc._slot_ready(rules, slots, "thorns")
		if thorn and _since(d, ctx.memo, r) == INF and _eta(r) > SW_URGENT + 4.0:
			var street := _street(crowd, w.ground_pos, d.lantern_door())
			var spot := _street_at(street, SW_THORN_AHEAD)
			if street.size() > 2 and spot != w.ground_pos:
				var dir := (_street_at(street, SW_THORN_AHEAD + 1.0) - _street_at(street, SW_THORN_AHEAD - 1.0)).normalized()
				ctx.memo[_key(r, "street")] = street
				rules.cast(slots.thorns, spot, {"dir": dir.orthogonal() if dir.length() > 0.1 else Vector2.RIGHT})
				_noted(d, ctx.memo, r)
				return "thornwall across the witness's street"
		if _since(d, ctx.memo, r) >= SW_MIRROR_WAIT and bc._slot_ready(rules, slots, "mirror") and not ctx.memo.has(_key(r, "mirror")):
			var live := _street(crowd, w.ground_pos, d.lantern_door())
			var way_in := _street_at(live, SW_MIRROR_AHEAD)
			if live.size() <= 2 and ctx.memo.has(_key(r, "street")):
				way_in = _street_at(ctx.memo[_key(r, "street")], SW_THORN_AHEAD + SW_MIRROR_AHEAD - 0.5)  # (shut in: beyond the wall, not at his feet)
			var way_out := _beyond(crowd, way_in)
			if way_in != Vector2.INF and way_out != Vector2.INF and way_in.distance_to(w.ground_pos) > MirrorfoldFx.HALF_WIDE and way_in.distance_to(way_out) >= MirrorfoldFx.MIN_APART:
				rules.cast(slots.mirror, way_in, {"to": way_out})
				ctx.memo[_key(r, "mirror")] = true
				_noted(d, ctx.memo, r)
				return "mirror the file out past the wall"
	return ""


## The street's polyline from `from` to `to` along the walk grid (the first point is `from`); just `from` when there is no way.
static func _street(crowd: Crowd, from: Vector2, to: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array([from])
	out.append_array(crowd._grid.path(from, to))
	return out


## The point `dist` along the polyline `street` (its end when shorter); its first point for a lone point, INF for none.
static func _street_at(street: PackedVector2Array, dist: float) -> Vector2:
	if street.is_empty():
		return Vector2.INF
	var at := street[0]
	var left := dist
	for k in range(1, street.size()):
		var seg := at.distance_to(street[k])
		if seg >= left:
			return at.move_toward(street[k], left)
		left -= seg
		at = street[k]
	return at


## Walkable ground out of the walls, a little past the wall's own margin, nearest `from` within SW_MIRROR_REACH; INF for none.
static func _beyond(crowd: Crowd, from: Vector2) -> Vector2:
	var best := Vector2.INF
	for rad: float in [3.0, 4.5, 6.0, 8.0, 10.0, 13.0, SW_MIRROR_REACH]:
		for k in 24:
			var g: Vector2 = crowd._grid.nearest_walkable(from + Vector2.from_angle(TAU * float(k) / 24.0) * rad, 2)
			if g == Vector2.INF or not Walls.outside(g) or City.current().town().grow(Walls.MARGIN + 0.8).has_point(g):
				continue
			if g.distance_to(from) >= MirrorfoldFx.MIN_APART and (best == Vector2.INF or g.distance_squared_to(from) < best.distance_squared_to(from)):
				best = g
		if best != Vector2.INF:
			return best
	return best


# --- Decree: Leaving Is Prohibited, The Bell Lies, Magnify ---

## No route (MS §9 open issue 1, ruling C9): nothing in the Decree kit stops a witness for good, so this is its best honest play -- delay. Leaving Is
## Prohibited (3 units round the aim, 15 s of every 20) on the witness as soon as it is ready, so the file cannot leave the circle; it is laid again on
## the leading witness each time it can be. The Bell Lies and Magnify stop no one and are not cast. The losses are expected and reported, never tuned
## around.
static func act_decree(bc, ctx: Dictionary) -> String:
	var d := ctx.d as SilenceWitnessDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if not bc._slot_ready(rules, slots, "noleave"):
		return ""
	for r in _walkers(d):
		var w := r.messenger
		if _held_circle(ctx, w):
			continue
		rules.cast(slots.noleave, w.ground_pos)
		ctx.memo[_key(r, "circle")] = _now(d)
		return "leaving is prohibited round the witness"
	return ""


## A circle of Leaving Is Prohibited laid on this witness is still up (its HOLD_TIME from the cast, kept in the memo).
static func _held_circle(ctx: Dictionary, w: Person) -> bool:
	var d := ctx.d as SilenceWitnessDirector
	for r in d.running():
		if (r as WitnessDirector).messenger == w:
			var k := _key(r as WitnessDirector, "circle")
			return ctx.memo.has(k) and _now(d) - float(ctx.memo[k]) < LEAVING_FX.HOLD_TIME
	return false


# --- Dominion: Mind Whisper, Discord, Madness Bloom ---

## Out of the walls. Mind Whisper sends the witness to ground out of the walls within its reach of where he stands (10 units as the crow flies: every
## house lies within 4 of the wall); he walks there by the street -- round to the gate, 20-35 units, held by the whisper the whole way -- and out of the walls
## he is stopped (walls_stop). The opener is Discord on the witness at his door (he forgets his errand for 15 s: the file stands about), the finisher the
## whisper SW_DOM_GAP seconds on, as Discord lifts (the pacing above); a witness within SW_URGENT of the Temple is whispered at once. Madness Bloom is not
## used: nothing in this Hunt asks a mate to be turned.
static func act_dominion(bc, ctx: Dictionary) -> String:
	var d := ctx.d as SilenceWitnessDirector
	if d == null:
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	for r in _walkers(d):
		var w := r.messenger
		if w.mind == Person.Mind.WHISPERED and w.has_goal():
			continue  # on his way out
		var whisper: bool = bc._slot_ready(rules, slots, "whisper") and not w.shaken() and w.mind != Person.Mind.WHISPERED
		var discord: bool = bc._slot_ready(rules, slots, "discord") and w.mind != Person.Mind.CONFUSED and w.mind != Person.Mind.WHISPERED
		if discord and _since(d, ctx.memo, r) == INF and _eta(r) > SW_URGENT + 4.0:
			rules.cast(slots.discord, w.ground_pos)
			_noted(d, ctx.memo, r)
			return "discord the witness (the opener)"
		if whisper and (_since(d, ctx.memo, r) >= SW_DOM_GAP or _eta(r) <= SW_URGENT):
			var spot := _out_spot(bc, crowd, w)
			if spot != Vector2.INF:
				rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": spot})
				_noted(d, ctx.memo, r)
				return "whisper the witness out of the walls"
	return ""


## Walkable ground out of the walls within a whisper's reach of `w` as the crow flies, the nearest by his walk; INF for none.
static func _out_spot(bc, crowd: Crowd, w: Person) -> Vector2:
	var best := Vector2.INF
	var best_way := INF
	for rad: float in [1.0, 2.0, 3.0, 4.0, 5.0, 6.5, 8.0, SW_WHISPER_REACH]:
		for k in 24:
			var g: Vector2 = crowd._grid.nearest_walkable(w.ground_pos + Vector2.from_angle(TAU * float(k) / 24.0) * rad, 2)
			if g == Vector2.INF or not Walls.outside(g) or g.distance_to(w.ground_pos) > SW_WHISPER_REACH:
				continue
			var way: float = bc._walk_len(crowd, w.ground_pos, g)
			if way < best_way:
				best = g
				best_way = way
	return best
