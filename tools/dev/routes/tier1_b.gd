extends RefCounted
## Tier 1 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes, kept the whole run), mission}, rebuilt at every look.
## Stubs until the tier's task writes them: they cast nothing, so the gate fails cleanly.


## The Warning's loadout B (spec 7.2 row 1): Death Mark, Mind Whisper, Discord, on the board's three stars (StarfallDirector).
## For each warning running, in the order the stars fell: act_warning_runner().
static func act_warning(bc, ctx: Dictionary) -> String:
	var d := ctx.d as StarfallDirector
	if d == null:
		return act_warning_runner(bc, ctx, ctx.d as WarningDirector)  # a single warning (the campaign's, or a night's Omen)
	for w: WarningDirector in d.stars:
		var did := act_warning_runner(bc, ctx, w, true)
		if did != "":
			return did
	return ""


static func state_warning(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as StarfallDirector
	if d == null:
		return ""
	return "stopped=%d relays=%d" % [d.stopped(), int(d.report().relays)]


## Nobody within WARN_CLEAR of a spot he is led to die at (Death Mark's fall is judged at Crowd.DOOM_WITNESS = 2.0, and the crowd moves
## in the ten seconds); the least gap at which the mark is cast; the whisper's seconds left below which a fresh one is sent first (the mark
## outlasts what is left of a held man); the spots tried (radii, directions); the walks wanted and allowed.
const WARN_CLEAR := 4.5
## The same once the bell has tolled (v0.11.2): the Herald has some 21 s to be stopped, not a whole street's worth, so a quieter corner is any with nobody
## within this of it (Death Mark's fall is judged at Crowd.DOOM_WITNESS = 2.0), and Discord holds him when no such corner is within Mind Whisper's reach.
const WARN_CLEAR_HERALD := 3.0
const WARN_CAST_GAP := 3.5
## A street too crowded for a WARN_CLEAR corner (the Capital's Great Market): the player takes the emptiest corner within reach instead, with this much
## less room, never under WARN_CLEAR_HERALD (Death Mark's fall is judged at 2.0; a seen death only hands the errand to the witness). Used only when no
## WARN_CLEAR corner exists, so a town that has one plays as before (Aldermere's rows).
const WARN_RELAX := 1.0
const WARN_FRESH := 5.5
const WARN_RADII := [2.0, 3.5, 5.0, 6.5, 8.0, 9.5]
const WARN_DIRS := 24
const WARN_WALK_WANT := 20.0
const WARN_WALK_MAX := 40.0


## One look at one warning (spec 7.2 row 1; Task 12's Omen calls it too): the policy of a player with Death Mark, who cannot let a
## soul see him fall.
## - Hold the carrier with Mind Whisper at a quiet spot (nobody within WARN_CLEAR), sent again whenever the crowd closes on it.
## - Standing there, freshly held, with nobody within WARN_CAST_GAP: Death Mark him; it comes due ten seconds on.
## - Mind Whisper cooling (or he shakes it off): Discord holds him instead, and the mark falls when the street round him is clear.
## - Carried on by a witness (the old carrier seen to fall): the same again.
## Casts through Rules.cast(), only when the slot allows it.
static func act_warning_runner(bc, ctx: Dictionary, w: WarningDirector, hops := false) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	if w == null or w.rules == null or w.warning_dead or w.phase == WarningDirector.Phase.OVER or not w.omen_fallen:
		return ""
	var m := w.messenger
	if not WarningDirector._alive(m) or m.inside or m.statuses.has(&"frail"):
		return ""  # nobody, or already marked: the mark does the rest
	var herald: bool = rules.lantern != null and rules.lantern.tolled
	var clear := WARN_CLEAR_HERALD if herald else WARN_CLEAR
	var gap := _warning_gap(crowd, m.ground_pos, m)
	var mark_ready: bool = bc._slot_ready(rules, slots, "deathmark")
	var whisper_ok: bool = bc._slot_ready(rules, slots, "whisper") and not m.shaken()
	var discord_ok: bool = bc._slot_ready(rules, slots, "discord")
	var whispered := m.mind == Person.Mind.WHISPERED
	var standing := whispered and not m.has_goal()
	var held := (standing and m.whispered_left() >= WARN_FRESH) or m.mind == Person.Mind.CONFUSED
	if mark_ready and gap >= WARN_CAST_GAP and (held or (not whispered and not whisper_ok and not discord_ok)):
		rules.cast(slots.deathmark, m.ground_pos)
		return "deathmark the carrier (nobody within %.1f)" % gap
	if whisper_ok:
		var redo := not whispered
		if whispered and m.has_goal():
			redo = _warning_gap(crowd, m.goal(), m) < clear - 1.0  # the crowd has closed on where he is led
		elif standing:
			redo = gap < WARN_CAST_GAP or m.whispered_left() < WARN_FRESH
		if redo:
			var spot := _warning_spot(bc, crowd, w, m, clear)
			if spot == Vector2.INF:
				spot = _warning_spot(bc, crowd, w, m, maxf(clear - WARN_RELAX, WARN_CLEAR_HERALD))
			if spot != Vector2.INF:
				if hops:
					spot = _warning_hop(crowd, m, spot)
				rules.cast(slots.whisper, m.ground_pos, {"target": m, "to": spot})
				return "whisper the carrier to (%.1f, %.1f)" % [spot.x, spot.y]
	if not whispered and (not whisper_ok or herald) and discord_ok and m.mind != Person.Mind.CONFUSED:
		rules.cast(slots.discord, m.ground_pos)
		return "discord the carrier, to hold him"
	return ""


## The board's Warning (god T1R): a quiet spot outside the walls is now where the warning stops, but the walk there can be long (the postern is shut at
## night: the Postern's watchman goes round by the Main Gate), so the whisper takes him on in hops of WARN_HOP units of walking, each sent again as he stands;
## the hunt for the spot, the mark and the hold are as ever. The Omen's act (hops off) plays as it did.
const WARN_HOP := 8.0


static func _warning_hop(crowd: Crowd, m: Person, spot: Vector2) -> Vector2:
	var path := crowd._grid.path(m.ground_pos, spot)
	var at := m.ground_pos
	var left := WARN_HOP
	for q in path:
		var seg := at.distance_to(q)
		if seg >= left:
			var hop: Vector2 = crowd._grid.nearest_walkable(at.move_toward(q, left), 2)
			return hop if hop != Vector2.INF and hop.distance_to(m.ground_pos) <= MindWhisperFx.REACH - 0.5 else spot
		left -= seg
		at = q
	return spot


## The spot within Mind Whisper's reach of `m` with nobody out of doors within WARN_CLEAR of it: of those, the nearest by his walk
## (WARN_WALK_WANT, else WARN_WALK_MAX). Vector2.INF for none.
static func _warning_spot(bc, crowd: Crowd, w: WarningDirector, m: Person, clear := WARN_CLEAR) -> Vector2:
	var best := Vector2.INF
	var best_way := INF
	for limit: float in [WARN_WALK_WANT, WARN_WALK_MAX]:
		for rad: float in WARN_RADII:
			for k in WARN_DIRS:
				var raw := m.ground_pos + Vector2.from_angle(TAU * float(k) / float(WARN_DIRS)) * rad
				var g: Vector2 = w._walkable(raw)
				if g.distance_to(raw) > 1.0 or g.distance_to(m.ground_pos) > MindWhisperFx.REACH - 0.5:
					continue
				if _warning_gap(crowd, g, m) < clear:
					continue
				var way: float = bc._walk_len(crowd, m.ground_pos, g)
				if way <= limit and way < best_way:
					best = g
					best_way = way
		if best != Vector2.INF:
			return best
	return best


## The distance from `at` to the nearest living person out of doors other than `m`.
static func _warning_gap(crowd: Crowd, at: Vector2, m: Person) -> float:
	var gap := INF
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != m and p.is_alive() and not p.inside:
				gap = minf(gap, p.ground_pos.distance_to(at))
	return gap


## The Tax Collector's loadout B (spec 7.2 row 2, Task 4's burning counting-house): Ember, Smite, Will-o'-the-Wisp.
## - Smite on a collector in the street once the bolt would go unseen: nobody but the man himself within Crowd.DOOM_WITNESS of where he
##   falls. The bolt is loud and he is alarmed as it is cast, so it is aimed where he will be as he turns.
## - Will-o'-the-Wisp to make that moment: its light draws the calm and the guards at their posts (the lure holds a soldier) away from
##   him, behind him as he goes.
## - A collector near the Citadel's gate with no unseen moment left is struck all the same: a death seen calls the bellkeeper and the bell
##   rings 8 s on, before Smite is ready again, so this costs the night unless he was the last (the win comes first); the last one alone
##   is struck from further off.
## - Ember on the counting-house when the last collector hides in it: the fire flushes him, running for the Citadel's gate, into the open.
static func act_tax(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as AssassinateDirector
	var crowd: Crowd = ctx.crowd
	if d == null:
		return ""
	var smite_ready: bool = bc._slot_ready(rules, slots, "smite")
	var wisp_ready: bool = bc._slot_ready(rules, slots, "wisp")
	var alive := 0
	var hiding := 0
	for q in d.quarries:
		if q.dead or not WarningDirector._alive(q.target):
			continue
		if q.state != AssassinateDirector.State.WAITING and not ctx.memo.has("out_%d" % q.index):
			ctx.memo["out_%d" % q.index] = rules.time_left  # when he first went out into the street
		alive += 1
		hiding += 1 if q.state == AssassinateDirector.State.HIDING else 0
	for q in d.quarries:
		if q.dead or not WarningDirector._alive(q.target) or q.state == AssassinateDirector.State.WAITING:
			continue
		var p: Person = q.target
		if not p.inside:
			var fall := _tax_fall(d, crowd, q)
			if smite_ready and (_tax_smite_unseen(crowd, p, fall) or _tax_last_chance(d, crowd, q, alive, float(ctx.memo.get("out_%d" % q.index, rules.time_left)) - rules.time_left)):
				rules.cast(slots.smite, fall)
				return "smite %s%s" % [q.label, "" if _tax_smite_unseen(crowd, p, fall) else ", his last chance"]
		if wisp_ready:
			var spot := _tax_place_ahead(d, crowd, q)
			if spot != Vector2.INF:
				var light := _tax_wisp_spot(d, crowd, p, spot)
				if light != Vector2.INF:
					rules.cast(slots.wisp, light)
					return "wisp %.1f from where %s will be, to draw off those who would see" % [light.distance_to(spot), q.label]
	var house := d.hideout
	if alive == 1 and hiding == 1 and bc._slot_ready(rules, slots, "ember") and smite_ready and is_instance_valid(house) \
			and not house.destroyed and not crowd.fires.is_burning(house):
		rules.cast(slots.ember, house.center())
		return "ember the counting-house, to bring out the last one hiding"
	return ""


static func state_tax(bc, ctx: Dictionary) -> String:
	var d := ctx.d as AssassinateDirector
	if d == null:
		return ""
	var r := d.report()
	return "states=%s killed=%d seen=%d" % [bc._tax_states(d), int(r.killed), int(r.seen)]


## The spots tried round a place for a Wisp's light (distances, directions), and the seconds ahead on his round the place is taken.
const TAX_WISP_R := [3.6, 4.2, 4.8]
const TAX_WISP_DIRS := 24
const TAX_AHEAD := 1.5
## The share of his step in the bolt's 0.35 s a bolt is led by: he turns at the cast, but not from the first frame.
const TAX_TURN := 0.8
## Seconds of road to the Citadel left when the last leg is struck whether seen or not.
const TAX_LAST_S := 9.0
const TAX_LAST_ONLY_S := 20.0
## The last collector left, this many seconds out in the street with no unseen moment: struck seen (the win comes before the bell).
const TAX_PATIENCE := 55.0
## How near a fall a living soul may stand and see it (the director's rule), and the margin the policy keeps.
const TAX_SEE_MARGIN := 0.5
## Only one this near the bolt's centre is sure to fall with him: anyone nearer KILL_R may step out of it in the 0.35 s before it lands,
## and stays a witness.
const TAX_FALLS_WITH := 0.2
## A visit runs out: the Wisp is cast this many seconds before he comes out of the door.
const TAX_DOOR_LEAD := 3.5


## He is out of unseen moments: the last one left, running from a fire or TAX_PATIENCE seconds out in the street; or one on his last leg
## with TAX_LAST_S seconds of road left (TAX_LAST_ONLY_S, alone).
static func _tax_last_chance(d: AssassinateDirector, crowd: Crowd, q: AssassinateDirector.Quarry, alive: int, out_for: float) -> bool:
	if alive == 1 and (q.flushed or out_for >= TAX_PATIENCE):
		return true  # the last one, running or too long in the street: a death seen is the win
	if q.state != AssassinateDirector.State.WALKING or q.leg < q.stops.size():
		return false
	var p: Person = q.target
	var road := 0.0
	var at := p.ground_pos
	for step in crowd._grid.path(p.ground_pos, d.safe_at):
		road += at.distance_to(step)
		at = step
	return road <= p.walk_speed * (TAX_LAST_ONLY_S if alive == 1 else TAX_LAST_S)


## Where a bolt aimed at `q`'s man lands: where he will be SmiteFx.T_STRIKE on. The bolt is loud, so a collector in the street is
## alarmed the moment it is cast (the director's rule) and turns for the hideout (or the safe place): he goes that way, at the pace he runs
## now. Aimed half that step ahead, so a turn that comes late still falls inside KILL_R.
static func _tax_fall(d: AssassinateDirector, crowd: Crowd, q: AssassinateDirector.Quarry) -> Vector2:
	var p: Person = q.target
	return _tax_along(crowd, p, d._hide_goal(q), p.walk_speed * SmiteFx.T_STRIKE * TAX_TURN)


## The point `dist` along the grid's way from `p` to `goal`, as he walks it: to each waypoint more than a step away, in turn (the first is
## often the cell's centre behind him -- Person._pick_target() skips only those within 0.08).
static func _tax_along(crowd: Crowd, p: Person, goal: Vector2, dist: float) -> Vector2:
	var at := p.ground_pos
	var left := dist
	for step in crowd._grid.path(p.ground_pos, goal):
		if at.distance_to(step) <= 0.08:
			continue
		var seg := at.distance_to(step)
		if seg >= left:
			return at.move_toward(step, left)
		left -= seg
		at = step
	return at


## Where the collector will be worth clearing: the door he comes out of, as his visit runs out; else the point TAX_AHEAD seconds ahead on
## the way to where his round (or his flight) takes him. Vector2.INF for neither.
static func _tax_place_ahead(d: AssassinateDirector, crowd: Crowd, q: AssassinateDirector.Quarry) -> Vector2:
	var p: Person = q.target
	match q.state:
		AssassinateDirector.State.VISITING:
			return d._door_in(q) if q.indoors_left <= TAX_DOOR_LEAD else Vector2.INF
		AssassinateDirector.State.WALKING, AssassinateDirector.State.FLEEING:
			var goal := d._leg_goal(q) if q.state == AssassinateDirector.State.WALKING else d._hide_goal(q)
			return _tax_along(crowd, p, goal, p.walk_speed * TAX_AHEAD)
	return Vector2.INF


## Nobody living out of doors would see him fall at `fall`: nobody within Crowd.DOOM_WITNESS plus a margin (a body moves up to half
## a unit in the bolt's SmiteFx.T_STRIKE), bar one at the bolt's very centre.
static func _tax_smite_unseen(crowd: Crowd, p: Person, fall: Vector2) -> bool:
	return _tax_seeing(crowd, p, fall).is_empty()


## The living out of doors who would see a man fall at `at`: within DOOM_WITNESS plus the margin of it, bar those a bolt there takes.
static func _tax_seeing(crowd: Crowd, p: Person, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if not is_instance_valid(o) or o == p or not o.is_alive() or o.inside:
				continue
			var gap := o.ground_pos.distance_to(at)
			if gap > TAX_FALLS_WITH and gap <= Crowd.DOOM_WITNESS + TAX_SEE_MARGIN:
				out.append(o)
	return out


## A light for a Wisp that would draw off everyone who would see a man fall at `spot` (WillOWisp.drawn()), behind him as he goes (so
## the drawn gather at his back, not on the road ahead), its ring no nearer than DOOM_WITNESS to the spot. The nearest such light to the
## man's own place; Vector2.INF for none -- or when nobody would see (nothing to draw).
static func _tax_wisp_spot(d: AssassinateDirector, crowd: Crowd, p: Person, spot: Vector2) -> Vector2:
	var seeing := _tax_seeing(crowd, p, spot)
	if seeing.is_empty():
		return Vector2.INF
	var ahead := (spot - p.ground_pos).normalized() if spot.distance_to(p.ground_pos) > 0.3 else Vector2.ZERO
	var best := Vector2.INF
	var best_gap := INF
	for rad: float in TAX_WISP_R:
		for k in TAX_WISP_DIRS:
			var dir := Vector2.from_angle(TAU * float(k) / float(TAX_WISP_DIRS))
			if ahead != Vector2.ZERO and dir.dot(ahead) > -0.3:
				continue
			var raw := spot + dir * rad
			var g := d._walkable(raw)
			if g.distance_to(raw) > 0.8:
				continue
			var drawn := WillOWisp.drawn(crowd._field, g)
			var all := true
			for o in seeing:
				all = all and drawn.has(o)
			var gap := g.distance_to(p.ground_pos)
			if all and gap < best_gap:
				best = g
				best_gap = gap
	return best


## Spoiled Harvest's loadout B (spec 7.2 row 3): Heaven Splitter, Smite, Mind Whisper. A granary is felled -- Heaven through it, Smite on it
## if Heaven is cooling -- and a fallen granary is spoiled the moment it holds grain (RazeDirector: its fall is judged once it can be). Its
## watchmen only beat out a fire, so they hold nothing back from a fall; a player still sends them off (Mind Whisper, one at HARV_W1 seconds
## before the grain, the next at HARV_W2), and fells it at HARV_HEAVEN, so the minute between grains is worked, not watched.
static func act_harvest(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as HarvestDirector
	var memo: Dictionary = ctx.memo
	if d == null:
		return ""
	for s: Structure in d.targets:
		if d.razed(s) or not is_instance_valid(s):
			continue
		var i := d.targets.find(s)
		var name := String(d.store_names[i])
		var left := d.grain_left(s)
		if s.destroyed:
			continue  # fallen: spoiled the moment the grain is in
		# Mind Whisper sends a watchman off, HARV_W1 / HARV_W2 seconds before the grain.
		for k in 2:
			var key := "sent_%d_%d" % [i, k]
			if memo.has(key) or left > (HARV_W1 if k == 0 else HARV_W2) or not bc._slot_ready(rules, slots, "whisper"):
				continue
			var men := d.watchmen(s)
			if men.size() <= k:
				continue
			var man := men[k]
			if not bc._whisperable(man):
				continue
			memo[key] = true
			var door: Vector2 = d.doors[s]
			var away := (man.ground_pos - door).normalized() if man.ground_pos.distance_to(door) > 0.1 else Vector2.DOWN
			var to := MindWhisperFx.clamp_to(ctx.crowd._grid, man.ground_pos, man.ground_pos + away * HARV_SEND)
			rules.cast(slots.whisper, man.ground_pos, {"target": man, "to": to})
			return "whisper a watchman of the %s granary away" % name
		if left <= HARV_HEAVEN:
			if bc._slot_ready(rules, slots, "heaven"):
				rules.cast(slots.heaven, s.center(), {"dir": Vector2.RIGHT})
				return "heaven splitter through the %s granary" % name
			if d.has_grain(s) and bc._slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, s.center())
				return "smite the %s granary" % name
		return ""  # one granary at a time, in the order the grain comes
	return ""


## Seconds before a granary's grain that the policy sends its first and second watchman off, and fells it, and how far it sends them.
const HARV_W1 := 45.0
const HARV_W2 := 30.0
const HARV_HEAVEN := 15.0
const HARV_SEND := 6.0


static func state_harvest(bc, ctx: Dictionary) -> String:
	var d := ctx.d as HarvestDirector
	if d == null:
		return ""
	return "granaries=%s spoiled=%d" % [bc._harvest_states(d), d.razed_count()]


## The Lost Lamb's loadout B (spec 7.2 row 4): Will-o'-the-Wisp, Discord, Silent Doom. The Wisp leads him: its light, LAMB_HOP ahead of him on
## the road to the way out, draws him -- and the soldiers about it, who stare at it and see nothing (a soldier held by the god is blind)
## -- and he holds where it leaves him. Discord on the watch that would see him, Silent Doom on his seizer when nobody sees it.
static func act_lamb(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as EscortDirector
	var crowd: Crowd = ctx.crowd
	if d == null or not WarningDirector._alive(d.charge):
		return ""
	var lamb := d.charge
	if lamb.inside:
		return ""
	if d.held and WarningDirector._alive(d.seizer):
		var s := d.seizer as Person
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, s.ground_pos)
			return "discord his seizer"
		# (god T1R: a death seen does not lose this night -- route A dooms the seizer all the same -- so no onlooker holds the Doom back)
		if bc._slot_ready(rules, slots, "doom") and lamb.ground_pos.distance_to(s.ground_pos) > SilentDoom.RADIUS + bc.LAMB_CLEAR:
			rules.cast(slots.doom, s.ground_pos)
			return "doom his seizer"
		return ""
	# The watch about to see him: Discord holds the nearest.
	var threat: Person = null
	for v: Variant in d._watchers():
		if not d._watching(v):
			continue
		var p := v as Person
		var gap := p.ground_pos.distance_to(lamb.ground_pos)
		if gap <= EscortDirector.SIGHT + bc.LAMB_WARN and (threat == null or gap < threat.ground_pos.distance_to(lamb.ground_pos)):
			threat = p
	# Silent Doom on a soldier set to watch for him near enough to matter -- at the middle of his squad, so one stroke takes both (the lost
	# lamb's night is not lost by a death seen: the watch is thinner for it).
	if bc._slot_ready(rules, slots, "doom"):
		var aim := _lamb_doom_aim(bc, d, lamb)
		if aim != Vector2.INF:
			rules.cast(slots.doom, aim)
			return "doom the soldiers who would see him"
	if threat != null and bc._slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, threat.ground_pos)
		return "discord a soldier about to see him"
	if bc._slot_ready(rules, slots, "wisp") and lamb.mind != Person.Mind.OBSERVE:
		var wait_at := d._walkable(d.gate_at + (d.gate_at - d.exit_at).normalized() * bc.LAMB_WAIT_DIST)
		var near_gate := lamb.ground_pos.distance_to(d.gate_at) <= EscortDirector.NEAR_GATE
		var to := d.exit_at if near_gate and (d.watch_away or not d._watch_standing()) else wait_at
		if to == wait_at and lamb.ground_pos.distance_to(wait_at) <= 1.0:
			return ""  # waiting for the watch to go for its change
		var light := _lamb_light(d, crowd, lamb, to)
		if light != Vector2.INF:
			rules.cast(slots.wisp, light)
			return "wisp %.1f ahead of him at (%.1f, %.1f)" % [light.distance_to(lamb.ground_pos), light.x, light.y]
	return ""


static func state_lamb(bc, ctx: Dictionary) -> String:
	var d := ctx.d as EscortDirector
	if d == null or not WarningDirector._alive(d.charge):
		return ""
	var gap := d.charge.ground_pos.distance_to(d.gate_at)
	return "held=%s seizures=%d gate=%.1f watch_away=%s" % [d.held, d.seizures, gap, d.watch_away]


## How far ahead of him a light is cast.
const LAMB_HOP := 5.5
## How near him a soldier set to watch for him is when Silent Doom takes him, if unseen.
const LAMB_DOOM_R := 9.0


## Where Silent Doom takes the most of the soldiers set to watch for him within LAMB_DOOM_R of him, never him: the place of one of them with
## the others of his squad close by (within Doom's reach of it), the most of them first. Vector2.INF for none.
static func _lamb_doom_aim(bc, d: EscortDirector, lamb: Person) -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	var watchers: Array[Person] = []
	for v: Variant in d._watchers():
		if d._watching(v) and (v as Person).ground_pos.distance_to(lamb.ground_pos) <= LAMB_DOOM_R:
			watchers.append(v as Person)
	for p in watchers:
		var n := 0
		for o in watchers:
			n += 1 if o.ground_pos.distance_to(p.ground_pos) <= SilentDoom.RADIUS else 0
		if p.ground_pos.distance_to(lamb.ground_pos) > SilentDoom.RADIUS + bc.LAMB_CLEAR and n > best_n:
			best = p.ground_pos
			best_n = n
	return best


## Where a Wisp that leads him on is cast: LAMB_HOP along the grid's way from him to `to` (the road ahead), on walkable ground.
static func _lamb_light(d: EscortDirector, crowd: Crowd, lamb: Person, to: Vector2) -> Vector2:
	var left := LAMB_HOP
	var at := lamb.ground_pos
	for step in crowd._grid.path(lamb.ground_pos, to):
		var seg := at.distance_to(step)
		if seg >= left:
			return d._walkable(at.move_toward(step, left))
		left -= seg
		at = step
	return d._walkable(at)


## First Prayers' loadout B (spec 7.2 row 5): Will-o'-the-Wisp, Discord, Silent Doom. The Wisp by the shrine: the poor within its reach walk to
## the light and stare at it, and one staring by the shrine goes down the well (the director's `_brought()`), one at a time. Discord (or
## Silent Doom where nobody would see) on the Faithful who would see the door, as in loadout A; and a report on its way stopped.
static func act_prayers(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var memo: Dictionary = ctx.memo
	var did := _prayers_look(bc, ctx)
	if did != "":
		memo["last"] = rules.time_left
		return did
	# Idle a while with nothing to fetch or hold: Silent Doom takes a Faithful where nobody would see it (one fewer to stand by the door
	# later), the nearest the door first -- the player always has a hand to play.
	if float(memo.get("last", rules.time_left)) - rules.time_left >= PRAYB_IDLE and bc._slot_ready(rules, ctx.slots, "doom"):
		var d := ctx.d as MirasHouseDirector
		var free := d._free_faithful()
		free.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(d.door) < b.ground_pos.distance_to(d.door))
		for f in free:
			if bc._doom_unseen(ctx.crowd, f.ground_pos, [], 0.3):
				rules.cast(ctx.slots.doom, f.ground_pos)
				memo["last"] = rules.time_left
				return "doom a Faithful where nobody sees"
	return ""


## Seconds without a cast after which the policy takes a Faithful with Silent Doom.
const PRAYB_IDLE := 20.0


static func _prayers_look(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as MirasHouseDirector
	var crowd: Crowd = ctx.crowd
	if d == null:
		return ""
	for r: TempleReport in d.reports:
		var c := r.carrier
		if not is_instance_valid(c) or not c.is_alive() or c.mind == Person.Mind.CONFUSED:
			continue
		if bc._slot_ready(rules, slots, "doom") and bc.crowd_alone(c):
			rules.cast(slots.doom, c.ground_pos)
			return "doom a runner to the Temple"
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, c.ground_pos)
			return "discord a runner to the Temple"
	var watcher := d.faithful_seeing(d.door, MirasHouseDirector.SIGHT + 1.5)
	if watcher != null and bc._prayers_door_matters(d):
		if bc._slot_ready(rules, slots, "doom") and bc.crowd_alone(watcher):
			rules.cast(slots.doom, watcher.ground_pos)
			return "doom a Faithful by the door"
		if bc._slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, watcher.ground_pos)
			return "discord a Faithful by the door"
	# The Wisp at the shrine's door fetches the poor from the streets (the director's fetch_r), when the door is unwatched and the next
	# prayer, by the nearest of them to arrive, would not end in a crowded square (loadout A's _prayers_ready() rule), and no Faithful comes with them.
	if bc._slot_ready(rules, slots, "wisp") and d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) == null:
		var light := d._walkable(d.door)
		var arrive := INF
		var seen := false
		for g in d.grieving:
			if not is_instance_valid(g) or not g.is_alive() or g.inside or d.believers.has(g) or not g.mind in Person.LURABLE:
				continue
			var gap := g.ground_pos.distance_to(light)
			if gap > (d as FirstPrayersDirector).fetch_r:
				continue
			arrive = minf(arrive, bc._walk_len(crowd, g.ground_pos, light) / maxf(g.walk_speed, 0.05))
		for p in WillOWisp.drawn(crowd._field, light):
			seen = seen or d.faithful.has(p)
		if arrive < INF and not seen and _prayers_clear(bc, d, arrive):
			rules.cast(slots.wisp, light)
			return "wisp at the shrine's door, fetching the poor (the first there in %.0f s)" % arrive
	return ""


## The next prayer, begun now by a lure whose first poor arrives in `arrive` seconds (+-PRAYB_JITTER), ends clear of the market's and the
## priests' windows (the director's: Faithful stand by the door), and a prayer already in progress ends first (the fetched wait, staring,
## FETCH_STARE seconds).
const PRAYB_JITTER := 2.0
const PRAYB_SLACK := 3.0


static func _prayers_clear(bc, d: MirasHouseDirector, arrive: float) -> bool:
	var left := d.reading_left()
	if left != INF and left - arrive > FirstPrayersDirector.FETCH_STARE - 1.0:
		return false
	var fp := d as FirstPrayersDirector
	if fp == null:
		return true
	var now := fp.timeline.elapsed()
	var wait := left if left != INF else 0.0
	var enter_from := now + maxf(arrive - PRAYB_JITTER, wait)
	var start := enter_from + fp.read_seconds
	var stop := now + maxf(arrive + PRAYB_JITTER, wait) + fp.read_seconds
	for w: Array in [[fp.market_at, fp.market_seconds], [fp.priests_at, fp.priests_seconds]]:
		var closes := float(w[0]) + float(w[1]) + PRAYB_SLACK
		if stop >= float(w[0]) and start <= closes:
			return false  # it would come out among them
		if now + maxf(arrive + PRAYB_JITTER, wait) >= float(w[0]) and enter_from <= closes:
			return false  # or go in under their eyes
	return true


static func state_prayers(bc, ctx: Dictionary) -> String:
	var d := ctx.d as MirasHouseDirector
	if d == null:
		return ""
	var near := 0
	for g in d.grieving:
		if is_instance_valid(g) and g.is_alive() and not g.inside and not d.believers.has(g) and g.ground_pos.distance_to(d.door) <= WillOWisp.LURE_REACH:
			near += 1
	return "believers=%d inside=%d poor_in_reach=%d gaze=%d reports=%d" % [d.believers_outside(), d.inside().size(), near,
		roundi(d.gaze.value), d.reports_started]


