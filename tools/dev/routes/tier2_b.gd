extends RefCounted
## Tier 2 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes, kept the whole run), mission}, rebuilt at every look.
## Stubs until the tier's task writes them: they cast nothing, so the gate fails cleanly.


## Mira's House, loadout B (wisp, discord, doom; spec row 6): the same watch as loadout A keeps -- Silent Doom on a runner nobody
## would see die, else Discord on him; Discord on a Faithful who watches the door -- but the grieving are drawn to the house by a
## Will-o'-Wisp's light set by its door (`_wisp_spot()`), not whispered. It casts the Wisp only when the door is unwatched.
static func act_miras(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as MirasHouseDirector
	for r: TempleReport in d.reports:
		var c := r.carrier
		if not is_instance_valid(c) or not c.is_alive() or c.mind == Person.Mind.CONFUSED:
			continue
		if bc._slot_ready(rules, slots, "doom") and bc.crowd_alone(c):
			return "doom a runner to the Temple" if rules.cast(slots.doom, c.ground_pos) != null else ""
		if bc._slot_ready(rules, slots, "discord"):
			return "discord a runner to the Temple" if rules.cast(slots.discord, c.ground_pos) != null else ""
	var watcher := d.faithful_seeing(d.door, MirasHouseDirector.SIGHT + 1.5)
	if watcher != null and bc._slot_ready(rules, slots, "discord"):
		return "discord a Faithful by the door" if rules.cast(slots.discord, watcher.ground_pos) != null else ""
	if watcher != null or d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) != null or not bc._slot_ready(rules, slots, "wisp"):
		return ""
	var at := _wisp_spot(d)
	if at == Vector2.INF:
		return ""
	return "wisp by the door (%.1f, %.1f)" % [at.x, at.y] if rules.cast(slots.wisp, at) != null else ""


## Where a Wisp by Mira's door draws the most grieving (not yet read, not shaking a whisper off) without drawing a Faithful (any within its
## reach would stand in the ring and watch the door): the best of the door and a ring of spots round it, within LURE_REACH of it. Vector2.INF
## when none draws a grieving citizen.
static func _wisp_spot(d: MirasHouseDirector) -> Vector2:
	var spots: Array[Vector2] = [d.door]
	for r in [1.0, 2.0]:
		for k in 8:
			spots.append(d._walkable(d.door + Vector2.from_angle(TAU * float(k) / 8.0) * r))
	var best := Vector2.INF
	var best_n := 0
	for at in spots:
		if at.distance_to(d.door) > MirasHouseDirector.LURE_REACH or _faithful_within(d, at, WillOWisp.LURE_REACH + 0.5):
			continue
		var n := 0
		for g in d.grieving:
			if is_instance_valid(g) and g.is_alive() and not g.inside and not d.believers.has(g) and not g.shaken() \
					and g.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH and g.mind in Person.LURABLE:
				n += 1
		if n > best_n:
			best = at
			best_n = n
	return best


## A Faithful (alive, out of doors, not held blind by the god) within `reach` of `at`: one a Wisp would draw to watch.
static func _faithful_within(d: MissionDirector, at: Vector2, reach: float) -> bool:
	for f in d.faithful:
		if is_instance_valid(f) and f.is_alive() and not f.inside and not (f.mind in MissionDirector.BLIND) \
				and f.ground_pos.distance_to(at) <= reach:
			return true
	return false


static func state_miras(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as MirasHouseDirector
	return "believers=%d inside=%d gaze=%d reports=%d" % [d.believers_outside(), d.inside().size(), roundi(d.gaze.value), d.reports_started]


## Broken Lanterns, loadout B (dragon, discord, wisp; spec row 7), played on the board's night. The Dragonfire Parade is the only breaker
## and is loud, so the first cast takes the bell tower (a fallen tower silences the bell; no Silent Doom on the keeper here); after that
## each cast goes where its eruption (1.9, a Knight beside the shrine falls first) and its breath (a cone of LANTERN_CONE_R, down-right on
## screen, its band swept from LANTERN_CONE_FROM to LANTERN_CONE_TO; a shrine has 40 hp) break the most unguarded shrines, with the fewest
## people near its eruption (_lantern_origin()). Discord holds the flame-bearer who turns aside to relight a draining shrine; the Wisp draws
## the Knights off a shrine the next Parade will take, 4.5 from it on the side away from the breath. `none` is not played here.
static func act_lanterns(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var memo: Dictionary = ctx.memo
	if not memo.has("last"):
		memo.last = rules.time_left
	var did := _lantern_look(bc, ctx)
	if did == "" and float(memo.last) - rules.time_left >= LANTERN_FILL:
		did = _lantern_fill(bc, ctx)
	if did != "":
		memo.last = rules.time_left
	return did


## While the Parade cools nothing else is worth a cast: after this long without one the policy still draws the bystanders off the next
## Parade's spot, or confuses the prayers at the next shrine it will take (what a player does in the lull).
const LANTERN_FILL := 34.0
## The lull's Discord leaves the flame-bearer's Discord (30 s to cool) ready for when the next Parade's shrines break: only while the
## Parade has this long to cool.
const LANTERN_FILL_DISCORD_COOL := 19.0


static func _lantern_fill(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as BrokenLanternsDirector
	var pick := _lantern_origin(d, ctx.crowd)
	if pick.shrines.is_empty():
		return ""
	var did := _lantern_wisp(bc, ctx, pick)
	if did != "":
		return did
	var sh: Structure = pick.shrines[0]
	if bc._slot_ready(rules, slots, "discord") and rules.cooldown_left(int(slots.dragon)) >= LANTERN_FILL_DISCORD_COOL:
		return "discord the prayers at a lantern" if rules.cast(slots.discord, sh.center()) != null else ""
	return ""


static func _lantern_look(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as BrokenLanternsDirector
	var crowd: Crowd = ctx.crowd
	var v := d.vigil
	if bc._slot_ready(rules, slots, "discord") and v != null and v.active and is_instance_valid(v.bearer) and v.bearer.is_alive() \
			and v.bearer.mind != Person.Mind.CONFUSED and not d.drain_left.is_empty():
		var near := INF
		for s: Structure in d.drain_left.keys():
			near = minf(near, v.bearer.ground_pos.distance_to(d.relight_point(s)))
		if near <= LANTERN_BEARER_REACH:
			return "discord the flame-bearer" if rules.cast(slots.discord, v.bearer.ground_pos) != null else ""
	var bell := crowd.bell
	var tower: Structure = bell.tower if bell != null else null
	var tower_up := bell != null and bell.state != BellNetwork.State.SILENCED and is_instance_valid(tower) and not tower.destroyed
	if bc._slot_ready(rules, slots, "dragon"):
		if tower_up and not ctx.memo.has("tower"):
			ctx.memo.tower = true
			return "dragon the bell tower" if rules.cast(slots.dragon, tower.center()) != null else ""
		var pick := _lantern_origin(d, crowd)
		if pick.shrines.is_empty():
			return ""
		var wisp := _lantern_wisp(bc, ctx, pick)
		if wisp != "" and not pick.shrines.filter(func(sh: Structure) -> bool: return d.guarded(sh)).is_empty():
			return wisp  # the Knights drawn off first; the Parade next look
		var spot: Vector2 = pick.at
		return "dragon at (%.1f, %.1f) for %d lanterns" % [spot.x, spot.y, pick.shrines.size()] \
				if rules.cast(slots.dragon, spot) != null else ""
	if bc._slot_ready(rules, slots, "wisp") and rules.cooldown_left(int(slots.dragon)) <= LANTERN_WISP_BEFORE:
		var pick := _lantern_origin(d, crowd)
		if not pick.shrines.is_empty():
			return _lantern_wisp(bc, ctx, pick)
	return ""


## The Wisp before a Parade at `pick` ({at, shrines}): it draws the Knights off a guarded shrine the Parade will take (the light 4.5 from
## the shrine, away from the breath's axis), else the bystanders off the spot (4.5 behind it, out of the breath's cone), when any
## stand within reach of the light. "" when it is not ready or would draw no one.
static func _lantern_wisp(bc, ctx: Dictionary, pick: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as BrokenLanternsDirector
	var crowd: Crowd = ctx.crowd
	if not bc._slot_ready(rules, slots, "wisp"):
		return ""
	var from: Vector2 = pick.at
	var light := d._walkable(from + Vector2(-LANTERN_WISP_OFF, 0.0))
	var why := "the bystanders off the Parade"
	for sh: Structure in pick.shrines:
		if d.guarded(sh):
			var away: Vector2 = (sh.center() - from).normalized() if from.distance_to(sh.center()) > 0.1 else Vector2(-1.0, 0.0)
			light = d._walkable(sh.center() + away * LANTERN_WISP_OFF)
			why = "the Knights off a lantern"
			break
	if WillOWisp.drawn(crowd._field, light).is_empty():
		return ""
	return "wisp %s" % why if rules.cast(slots.wisp, light) != null else ""


## The flame-bearer within this of a draining shrine is worth a Discord (he could relight it in time).
const LANTERN_BEARER_REACH := 12.0
## The Wisp that draws Knights off a shrine lands this far from it; it is cast when the Parade has this long to cool.
const LANTERN_WISP_OFF := 4.5
const LANTERN_WISP_BEFORE := 12.0
## The Parade's breath (dragonfire_parade.gd): its cone's reach and its band's first and last angle (ground), shortened a little.
const LANTERN_CONE_R := 10.0
const LANTERN_CONE_FROM := -0.62
const LANTERN_CONE_TO := 0.34
const LANTERN_ERUPT_R := 1.8


## Where the Parade falls (v0.11.1, loadout B): the spot on a 0.5 grid whose eruption and breath break the most standing, undrained shrines
## (a guarded shrine counts only within the eruption, which kills its Knight first, or when `knights_off` -- the Wisp's job -- is
## asked for by the caller, who reads `shrines` for guards); ties to the fewest people within the eruption. {at, shrines}.
static func _lantern_origin(d: BrokenLanternsDirector, crowd: Crowd) -> Dictionary:
	var standing: Array[Structure] = d.standing_shrines().filter(func(s: Structure) -> bool: return not d.draining(s))
	var best := {"at": Vector2.INF, "shrines": [] as Array}
	if standing.is_empty():
		return best
	var people: Array[Vector2] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p.is_alive() and not p.inside:
				people.append(p.ground_pos)
	var best_score := -INF
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for s in standing:
		lo = lo.min(s.center())
		hi = hi.max(s.center())
	for gx in range(int(floor((lo.x - LANTERN_CONE_R) * 2.0)), int(ceil((hi.x + LANTERN_CONE_R) * 2.0)) + 1):
		for gy in range(int(floor((lo.y - LANTERN_CONE_R) * 2.0)), int(ceil((hi.y + LANTERN_CONE_R) * 2.0)) + 1):
			var at := Vector2(float(gx), float(gy)) * 0.5
			var got: Array = []
			for s in standing:
				var rel := s.center() - at
				if rel.length() <= LANTERN_ERUPT_R or (rel.length() <= LANTERN_CONE_R and rel.angle() >= LANTERN_CONE_FROM \
						and rel.angle() <= LANTERN_CONE_TO and rel.length() > 0.8):
					got.append(s)
			if got.is_empty():
				continue
			var n := 0
			for q in people:
				n += 1 if q.distance_to(at) <= LANTERN_ERUPT_R + 0.6 else 0
			var score := 100.0 * float(got.size()) - float(n)
			if score > best_score:
				best_score = score
				best = {"at": at, "shrines": got}
	return best


static func state_lanterns(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as BrokenLanternsDirector
	return "drained=%d broken=%d relit=%d praying=%d gaze=%d knights=%d bell=%s" % [d.drained_count(), d.drain_left.size(), d.relit,
		d.praying_count(), roundi(d.gaze.value), d.living_knights(), BellNetwork.State.keys()[(ctx.crowd as Crowd).bell.state]]


## The Bell-Ringers, loadout B (deathmark, whisper, wisp; spec row 8). Two things changed from the spec's text, by rulings: Smite is dodged
## (the cast frightens everyone within 2.1 of its mark and the bolt lands 0.35 s later), so the death is Death Mark's; and a Will-o'-Wisp
## clears the mates only because they now answer its lure (RingerDirector). The carrier is marked as soon as he is out and dies 10 s on,
## unseen if no one stands within Crowd.DOOM_WITNESS of him then: the Wisp is laid behind him (_ringers_light()), drawing his mates off his
## heels, and Mind Whisper sends a lone stranger near him off. A warning passed on to a witness is a new carrier, marked when the mark is ready
## again (20 s). Per look, the first that applies: the town's bellkeeper once called (Mind Whisper holds him back; the mark when it cools);
## an unmarked carrier marked; the Wisp for his mates; Mind Whisper for a stranger by a marked carrier.
static func act_ringers(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as BellRingersDirector
	var crowd: Crowd = ctx.crowd
	var bell := crowd.bell
	var mark: bool = bc._slot_ready(rules, slots, "deathmark")
	var whisper: bool = bc._slot_ready(rules, slots, "whisper")
	var wisp: bool = bc._slot_ready(rules, slots, "wisp")
	if d.called():
		var k := bell.keeper
		if whisper and k.mind == Person.Mind.DUTY and not k.shaken():
			var back: Vector2 = d._walkable(k.ground_pos + (k.ground_pos - bell.foot).normalized() * RINGERS_KEEPER_BACK)
			rules.cast(slots.whisper, k.ground_pos, {"target": k, "to": back})
			return "whisper the bellkeeper back"
		if mark and not k.statuses.has(&"frail"):
			rules.cast(slots.deathmark, k.ground_pos)
			return "death mark the bellkeeper"
	var going: Array[RingerDirector] = []
	for r in d.running():
		if WarningDirector._alive(r.messenger) and not r.messenger.inside:
			going.append(r)
	for r in going:
		var c := r.messenger
		if mark and not c.statuses.has(&"frail"):
			rules.cast(slots.deathmark, c.ground_pos)
			return "death mark the carrier"
	if wisp:
		for r in going:
			var light := _ringers_light(r)
			if light != Vector2.INF:
				rules.cast(slots.wisp, light)
				return "wisp the mates off the carrier's heels"
	if whisper:
		for r in going:
			var c := r.messenger
			if not c.statuses.has(&"frail"):
				continue
			var lone: Person = null
			for p in r.witnesses():
				if WarningDirector._alive(p) and not p.inside and not p.shaken() and p.mind != Person.Mind.WHISPERED and not r.crew().has(p) \
					and (lone == null or p.ground_pos.distance_to(c.ground_pos) < lone.ground_pos.distance_to(c.ground_pos)):
					lone = p
			if lone != null:
				rules.cast(slots.whisper, lone.ground_pos, {"target": lone, "to": _ringers_far(d, lone, c.ground_pos, crowd)})
				return "whisper a witness off"
	return ""


## The bellkeeper is whispered this far back from the foot.
const RINGERS_KEEPER_BACK := 8.0


## A witness is whispered as far from the carrier as the whisper reaches (MindWhisperFx.REACH - 0.5), straight away from him.
static func _ringers_far(d: BellRingersDirector, m: Person, from: Vector2, crowd: Crowd) -> Vector2:
	var away := m.ground_pos - from
	var to: Vector2 = m.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * (MindWhisperFx.REACH - 0.5)
	return MindWhisperFx.clamp_to(crowd._grid, m.ground_pos, d._walkable(to))


## Where the Wisp's light stands to hold carrier `r`'s mates where they are: at the middle of the mates still with him, brought to the one nearer
## him if the other stands beyond WillOWisp.CHARGE_LURE_R of it. They stop to stare at it for WISP_TIME while the ringer, marked and slowed, runs
## on, so that when the mark comes due they are many steps behind him. Vector2.INF when he has no mate with him.
static func _ringers_light(r: RingerDirector) -> Vector2:
	var c := r.messenger
	if not c.statuses.has(&"frail"):
		return Vector2.INF
	var mates := r.mates_with()
	if mates.is_empty():
		return Vector2.INF
	var mid := Vector2.ZERO
	for m in mates:
		mid += m.ground_pos
	mid /= float(mates.size())
	for m in mates:
		if m.ground_pos.distance_to(mid) > WillOWisp.CHARGE_LURE_R - 0.1:
			return Vector2.INF
	for p in WillOWisp.drawn(r.crowd._field, mid):  # it also draws every calm stranger within its reach: they would stand round the road
		if not r.crew().has(p):
			return Vector2.INF
	return mid


static func state_ringers(bc, ctx: Dictionary) -> String:
	var d := ctx.d as BellRingersDirector
	return "stopped=%d relays=%d running=%d phase=%s bell=%s" % [d.stopped(), int(d.report().relays), d.running().size(), d.hint_phase(),
		bc._bell_state(ctx.crowd)]


## Market Panic, loadout B (ember, whisper, discord; spec row 9). The fair's wardens steady every goer within WARD_R and are fearless, so
## a fire breaks nobody while one guards. Discord on one warden and Mind Whisper on the others take them off guard (RETURN_AFTER 20 s
## before any goes back), and with none on guard Ember sets alight the house round which the most goers still to break stand, their
## panic at the fire (a threat of its footprint and 0.8, and Person.THREAT_MARGIN) being what breaks them. The wardens are sent off only
## once Ember is ready within PANIC_EMBER_SOON and the goers are packed at the fair (PANIC_PACK within the fair). `none` is not played here.
static func act_panic(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as MarketPanicDirector
	if d.timeline.elapsed() < bc.PANIC_SETTLE:
		return ""
	var memo: Dictionary = ctx.memo
	if not memo.has("last"):
		memo.last = rules.time_left
	var lull: bool = float(memo.last) - rules.time_left >= PANIC_LULL
	var did := _panic_look(bc, ctx, d, lull)
	if did != "":
		memo.last = rules.time_left
	return did


## After this long without a cast the policy keeps its hand in: a stroller far from the fair is whispered a few steps (it touches nothing the
## fair holds, and costs the town no alarm).
const PANIC_LULL := 36.0
## Goers packed at the fair before the wardens are sent off.
const PANIC_B_PACK := 6


static func _panic_look(bc, ctx: Dictionary, d: MarketPanicDirector, lull: bool) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var wardens := d.on_guard()
	var push := d.need - d.count() <= PANIC_PUSH  # the last few: every goer near a house counts, and the town's alarm no longer matters
	if bc._slot_ready(rules, slots, "ember"):
		var ahead := _panic_ahead(d, ctx.crowd)
		if ahead != null:
			rules.cast(slots.ember, ahead.center())
			return "ember a house on the next crowd's road"
	if wardens.is_empty() and bc._slot_ready(rules, slots, "ember"):
		var house := _panic_house(d, ctx.crowd, 1 if push else PANIC_EMBER_MIN)
		if house != null:
			rules.cast(slots.ember, house.center())
			return "ember a house (%d goers by it)" % _panic_by(d, house)
	if lull and bc._slot_ready(rules, slots, "whisper"):
		var far := _panic_far_citizen(d, ctx.crowd)
		if far != null:
			rules.cast(slots.whisper, far.ground_pos, {"target": far, "to": d._walkable(far.ground_pos + Vector2(3.0, 0.0))})
			return "whisper a stroller far from the fair"
	if wardens.is_empty() or rules.cooldown_left(int(slots.ember)) > PANIC_EMBER_SOON:
		return ""
	if not lull and bc._panic_near(d, MarketPanicDirector.HEART, MarketPanicDirector.FAIR_R).size() < PANIC_B_PACK:
		return ""
	var warden: Person = wardens[0]
	if bc._slot_ready(rules, slots, "discord") and wardens.size() >= 2:
		warden = wardens[wardens.size() - 1]  # the one farthest from the fountain's heart
		rules.cast(slots.discord, warden.ground_pos)
		return "discord a warden off guard"
	if bc._slot_ready(rules, slots, "whisper") and not warden.shaken():
		var away: Vector2 = d._walkable(warden.ground_pos + (warden.ground_pos - MarketPanicDirector.HEART).normalized() * PANIC_SEND)
		rules.cast(slots.whisper, warden.ground_pos, {"target": warden, "to": away})
		return "whisper a warden off his post"
	return ""


## Ember is sent for only when it will be ready this soon after the last warden is sent off.
const PANIC_EMBER_SOON := 10.0
## From this many goers short of the need the Ember's threshold drops to one goer.
const PANIC_PUSH := 0
## A warden is whispered this far from the fountain.
const PANIC_SEND := 8.0
## A house is worth an Ember when at least this many goers still to break stand where its fire frightens them.
const PANIC_EMBER_MIN := 3

## Seconds before a crowd sets out that an Ember is laid on its road (a fire frightens a walker who comes within its reach, and no warden
## steadies the road), and how near the road a house must stand.
const PANIC_AHEAD := 12.0
const PANIC_ROAD := 2.0


## The burnable thing nearest the road of the next crowd, laid when it sets out within PANIC_AHEAD: within PANIC_ROAD of the line from its
## source to the fountain, in the middle of it (0.3 to 0.8 of the way); null when no crowd is due, or none stands there.
static func _panic_ahead(d: MarketPanicDirector, crowd: Crowd, within := PANIC_AHEAD) -> Structure:
	var i := d.next_wave()
	if i < 1 or d.wave_due(i) - d._clock > within:
		return null
	var from: Vector2 = MarketPanicDirector.SOURCES[i]
	var line := MarketPanicDirector.HEART - from
	var best: Structure = null
	var best_gap := PANIC_ROAD
	for s: Structure in crowd._env.structures():
		if not is_instance_valid(s) or s.destroyed or not s.kind in FireManager.BURNABLE or crowd.fires.is_burning(s):
			continue
		var t := (s.center() - from).dot(line) / line.length_squared()
		if t < 0.3 or t > 0.8:
			continue
		var gap := (from + line * t).distance_to(s.center())
		if gap < best_gap:
			best_gap = gap
			best = s
	return best


## A citizen far from the fair, not a goer nor a warden, who can hear a whisper; null for none.
static func _panic_far_citizen(d: MarketPanicDirector, crowd: Crowd) -> Person:
	for p in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and not p.shaken() and p.mind == Person.Mind.CALM \
				and p.ground_pos.distance_to(MarketPanicDirector.HEART) >= 14.0 and not d.goers.has(p):
			return p
	return null


## The burnable thing whose fire frightens the most goers still to break: those within its footprint radius + 0.8 + Person.THREAT_MARGIN of
## it (the fire's threat, Crowd._watch_threats()); null when fewer than PANIC_EMBER_MIN stand by any.
static func _panic_house(d: MarketPanicDirector, crowd: Crowd, least := PANIC_EMBER_MIN) -> Structure:
	var best: Structure = null
	var best_n := least - 1
	for s: Structure in crowd._env.structures():
		if not is_instance_valid(s) or s.destroyed or not s.kind in FireManager.BURNABLE or crowd.fires.is_burning(s):
			continue
		var n := _panic_by(d, s)
		if n > best_n:
			best_n = n
			best = s
	return best


## The goers still to break within the fright of a fire in `s`.
static func _panic_by(d: MarketPanicDirector, s: Structure) -> int:
	var reach := s.footprint.size.length() * 0.5 + 0.8 + Person.THREAT_MARGIN
	var n := 0
	for p in d.unbroken():
		n += 1 if p.ground_pos.distance_to(s.center()) <= reach else 0
	return n


static func state_panic(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as MarketPanicDirector
	var crowd := ctx.crowd as Crowd
	return "broken=%d/%d wardens=%d walkers=%d phase=%s alarm=%s fires=%d left=%d" % [d.count(), d.need, d.on_guard().size(), d.walkers().size(),
		d.hint_phase(), AlarmManager.Stage.keys()[crowd.alarms.stage], crowd.fires.fires.size(), d._left.size()]


## The Informer, loadout B (discord, wisp, smite; spec row 10). Before he is found: with word at the contact, Discord on the spot that holds
## the contact and the most onlookers (_informer_spot()); when some would still see (passers-by, a soldier), the Wisp draws them off to a
## light 5 beyond them first (and in the INFORMER_EARLY seconds before a visit it clears the bystanders by his door already). Found: Smite on the
## informer, aimed where he will stand 0.35 s later -- a cast within ALARM_REACH of one in the street sends him running for his hiding
## place, so that is the way he goes (_informer_lead()); Smite on the town's bellkeeper once called. Never a Smite near a contact.
static func act_informer(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as InformerDirector
	var crowd: Crowd = ctx.crowd
	var smite: bool = bc._slot_ready(rules, slots, "smite")
	var bell := crowd.bell
	if smite and bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING] and WarningDirector._alive(bell.keeper) \
			and bell.keeper.profile != null and bell.keeper.profile.role == CitizenProfile.Role.BELLKEEPER:
		var k := bell.keeper
		rules.cast(slots.smite, k.ground_pos + (bc._tax_lead(k) if k.has_goal() else Vector2.ZERO))
		return "smite the bellkeeper"
	if d.found:
		var q := d.quarries[0]
		var t := q.target as Person
		if smite and WarningDirector._alive(t) and not t.inside and not bc._informer_takes_contact(d, t):
			var aim: Vector2 = t.ground_pos + _informer_lead(d, crowd, q)
			rules.cast(slots.smite, aim)
			return "smite the informer (%s)" % AssassinateDirector.State.keys()[q.state]
		return ""
	var c := d.contact_now()
	if c == null or not WarningDirector._alive(c.man) or (c.man as Person).inside:
		return ""
	var man := c.man as Person
	var wisp: bool = bc._slot_ready(rules, slots, "wisp")
	var seeing := d.onlookers(c)
	var strangers: Array[Person] = []
	for p in seeing:
		if not c.company.has(p):
			strangers.append(p)
	if not c.word:
		var due := d.visit_in(d.contacts.find(c))
		if wisp and due <= INFORMER_EARLY and not strangers.is_empty():
			return _informer_wisp(rules, slots, crowd, c, strangers)
		if wisp and due <= INFORMER_LULL:  # the lane by his door, lit already: no one lingers to see (the cast is cheap and wears off)
			return _informer_wisp(rules, slots, crowd, c, strangers, true)
		return ""
	var pick := _informer_spot(c, seeing)
	if pick.left.is_empty() and bc._slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, pick.at)
		return "discord the %s (%d held)" % [c.trade, seeing.size() - pick.left.size()]
	if wisp and not pick.left.is_empty():
		var left: Array[Person] = []
		left.assign(pick.left)
		return _informer_wisp(rules, slots, crowd, c, left)
	return ""


## The seconds before a visit in which the Wisp already clears the bystanders by the contact's door.
const INFORMER_EARLY := 12.0
## From this many seconds before a visit the Wisp is laid by the contact's door even with no one standing there to draw off.
const INFORMER_LULL := 25.0
## How much of his stride in the bolt's 0.35 s the aim leads him by.
const INFORMER_LEAD := 0.0
## The Wisp's light stands this far past the ones it is to draw off, from the contact.
const INFORMER_LIGHT := 5.0


## The Wisp draws `who` away from contact `c`: its light INFORMER_LIGHT from him, toward where they stand. "" when it is not ready or would
## not draw one of them.
static func _informer_wisp(rules: Rules, slots: Dictionary, crowd: Crowd, c: InformerDirector.Contact, who: Array[Person], always := false) -> String:
	var man := c.man as Person
	var centre := man.ground_pos + Vector2.RIGHT
	if not who.is_empty():
		centre = Vector2.ZERO
		for p in who:
			centre += p.ground_pos
		centre /= float(who.size())
	var dir := (centre - man.ground_pos).normalized() if centre.distance_to(man.ground_pos) > 0.1 else Vector2.RIGHT
	var light: Vector2 = crowd._grid.nearest_walkable(man.ground_pos + dir * INFORMER_LIGHT, 8)
	if light == Vector2.INF:
		return ""
	var drawn := WillOWisp.drawn(crowd._field, light)
	var any := false
	for p in who:
		any = any or drawn.has(p)
	if not any and not always:
		return ""
	return "wisp the bystanders off the %s" % c.trade if rules.cast(slots.wisp, light) != null else ""


## Where a Discord holds the most of `seeing` and still holds the contact: a spot within DiscordFx.DISCORD_R - 0.1 of him on a 0.25 grid
## round him, covering the most onlookers, the nearest to him among equals. {at, left}: the ones it leaves seeing.
static func _informer_spot(c: InformerDirector.Contact, seeing: Array[Person]) -> Dictionary:
	var man := c.man as Person
	var best := man.ground_pos
	var best_left: Array = seeing.duplicate()
	var reach := DiscordFx.DISCORD_R - 0.1
	for ix in range(-4, 5):
		for iy in range(-4, 5):
			var at := man.ground_pos + Vector2(float(ix), float(iy)) * 0.25
			if at.distance_to(man.ground_pos) > reach:
				continue
			var left: Array = []
			for p in seeing:
				if p.soldier or p.ground_pos.distance_to(at) > reach:
					left.append(p)
			if left.size() < best_left.size() or (left.size() == best_left.size() and at.distance_to(man.ground_pos) < best.distance_to(man.ground_pos)):
				best = at
				best_left = left
	return {"at": best, "left": best_left}


## Where informer `q` will stand DiscordFx... SmiteFx.T_STRIKE after a Smite is cast at him: a cast within ALARM_REACH of one in the street
## sends him on duty for his hiding place (_hide_goal()), at his pace, along the walk grid's way; one already running keeps his way.
static func _informer_lead(d: InformerDirector, crowd: Crowd, q) -> Vector2:
	var t := q.target as Person
	var goal: Vector2 = d._hide_goal(q) if q.state == AssassinateDirector.State.WALKING else (t.goal() if t.has_goal() else d._hide_goal(q))
	var path := crowd._grid.path(t.ground_pos, goal)
	var next := goal
	for p in path:
		if p.distance_to(t.ground_pos) > 0.05:
			next = p
			break
	var dir := (next - t.ground_pos).normalized() if next.distance_to(t.ground_pos) > 0.01 else Vector2.ZERO
	return dir * t.walk_speed * SmiteFx.T_STRIKE * INFORMER_LEAD


static func state_informer(bc, ctx: Dictionary) -> String:
	var d := ctx.d as InformerDirector
	return "turned=%d found=%s cold=%s phase=%s bell=%s" % [d.turned_count(), d.found, d.cold, d.hint_phase(), bc._bell_state(ctx.crowd)]
