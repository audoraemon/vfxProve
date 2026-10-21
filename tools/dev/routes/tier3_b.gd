extends RefCounted
## Tier 3 second routes (v0.11.1, spec §7.2): the scripted player's loadout-B policy for each of this tier's missions, played by
## behaviour_check --route=b through _scripted(). Per mission: act_<name>(bc, ctx) is one look of the policy (what it cast, or ""),
## state_<name>(bc, ctx) the numbers its report lines print. `bc` is the behaviour_check script (its helpers: _slots, _doom_unseen,
## _slot_ready, ...); ctx = {rules, slots (power key -> slot), d (the director), crowd, memo (the policy's own notes, kept the whole run), mission}, rebuilt at every look.
## Tier 3 (v0.11.1 Task 10): the Vigil Flame, the Festival, the Crown's Bread, the Prisoner and the Heretic Hunt. Each policy plays only the
## powers of its RouteBook loadout, as a player would, and is held to the mission's gate (tools/dev/gate.sh <scenario> --route=b).


## The Vigil Flame, loadout B (wisp, discord, doom, thorns; v0.11.1 row 11), on the board (a star mission: wins and idle only). A look of
## the policy: what was cast, or "". Before Wren comes: a Wisp ahead of the Vigil draws the bystanders off its road, the bystanders about the
## lantern are thinned by Silent Doom where none would see, and one Discord holds the Vigil still for him. Wren come: Doom takes each
## bystander a Wisp at the lantern would draw round it; Discord takes the watchers and the bearer (whose stillness holds the lantern); and,
## all being ready, a Wisp at the lantern draws Wren to its light, where he takes hold as a whispered boy does -- else he comes for the
## lantern himself 0:30 after he appears, and the Discord is cast just before. With the flame: a Wisp that draws Wren off the road of a beam
## due on him (so near him it is no decoy), a decoy Wisp when the quiet has lasted, and Discord at the Temple's door in the clock's last
## seconds, as loadout A's carry -- with no whisper to steer him.
static func act_flame(bc, ctx: Dictionary) -> String:
	var d := ctx.d as VigilFlameDirector
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	if d == null or d.home:
		return ""
	var track := d.flame_at()
	var real: float = d.timeline.elapsed() * d.timeline.stretch_factor()
	if track != Vector2.INF and (not ctx.memo.has("lt") or real - float(ctx.memo.lt) >= 2.0):  # the lantern's heading over the last two seconds
		ctx.memo["lp"] = ctx.memo.get("lc", track)
		ctx.memo["lc"] = track
		ctx.memo["lt"] = real
	var did := ""
	if not d.appeared:
		did = _flame_prep(bc, d, rules, slots, ctx)
	elif not MissionDirector._alive(d.wren) or d.wren.inside:
		return ""
	elif d.swapped:
		did = _flame_carry(bc, d, rules, slots, ctx, real - float(ctx.memo.get("last", 0.0)) >= FLAME_QUIET)
	else:
		did = _flame_swap(bc, d, rules, slots, ctx)
	if did != "":
		ctx.memo["last"] = real
	return did


static func state_flame(bc, ctx: Dictionary) -> String:
	var d := ctx.d as VigilFlameDirector
	return "phase=%s touches=%d praying=%d reports=%d gaze=%d beams=%d" % [bc._flame_phase(d), d.touches, d.praying_count(),
		d.reports_started, roundi(d.gaze.value), d.searchlight.beams()]


## The Faithful going about their day near `lantern`, who could wander into the swap, as a mean point (INF for none) and how many.
static func _flame_strays(bc, d: VigilFlameDirector, lantern: Vector2, within: float) -> Array:
	var walking: Array[Person] = d.vigil.walkers() if d.vigil != null and d.vigil.active else ([] as Array[Person])
	var mean := Vector2.ZERO
	var n := 0
	for f in d.faithful:
		if not MissionDirector._alive(f) or f.inside or walking.has(f) or not f.mind in Person.LURABLE:
			continue
		if f.ground_pos.distance_to(lantern) <= within:
			mean += f.ground_pos
			n += 1
	return [mean / float(n) if n > 0 else Vector2.INF, n]


## A Wisp that draws the strays near `lantern` off: FLAME_STRAY_LURE (or half of it) from their mean point on the side away from the lantern,
## else any side -- but never within CHARGE_LURE_R (and a margin) of Wren, whom a Wisp would draw as well. Nothing cast when no such spot.
static func _flame_draw_off(bc, d: VigilFlameDirector, rules: Rules, slots: Dictionary, ctx: Dictionary, lantern: Vector2, strays: Vector2) -> String:
	var grid: WalkGrid = (ctx.crowd as Crowd)._grid
	var from: Vector2 = strays - lantern if strays.distance_to(lantern) > 0.5 else Vector2.RIGHT
	var away: Vector2 = from.normalized() if from.length() > 0.01 else Vector2.RIGHT
	var best := Vector2.INF
	var best_gap := -1.0
	for reach: float in [float(bc.FLAME_STRAY_LURE), float(bc.FLAME_STRAY_LURE) * 0.5]:
		for k in 8:
			var at := grid.nearest_walkable(strays + away.rotated(TAU * float(k) / 8.0) * reach)
			if at == Vector2.INF:
				continue
			if d.wren != null and d.appeared and MissionDirector._alive(d.wren) \
					and at.distance_to(d.wren.ground_pos) <= WillOWisp.CHARGE_LURE_R + FLAME_WREN_MARGIN:
				continue
			var gap := at.distance_to(lantern)
			if gap > best_gap:
				best = at
				best_gap = gap
	if best == Vector2.INF:
		return ""
	rules.cast(slots.wisp, best)
	return "wisp the bystanders off the lantern"


static func _flame_prep(bc, d: VigilFlameDirector, rules: Rules, slots: Dictionary, ctx: Dictionary) -> String:
	var lantern := d.flame_at()
	var now: float = d.timeline.elapsed() * d.timeline.stretch_factor()  # real seconds
	if lantern == Vector2.INF or d.vigil == null or not d.vigil.active:
		return ""
	# Early: a Wisp ahead of the Vigil on its road draws the bystanders there off it (and is ready again for the boy by 0:50).
	if now >= FLAME_ROAD_AT and not ctx.memo.has("road") and bc._slot_ready(rules, slots, "wisp"):
		ctx.memo["road"] = true
		var heading: Vector2 = lantern - ctx.memo.get("lp", lantern)
		var ahead: Vector2 = lantern + (heading.normalized() * FLAME_ROAD_AHEAD if heading.length() > 0.001 else Vector2.ZERO)
		var at: Vector2 = (ctx.crowd as Crowd)._grid.nearest_walkable(ahead)
		rules.cast(slots.wisp, at if at != Vector2.INF else lantern)
		return "wisp the bystanders off the Vigil's road"
	# (v0.11.2) The Discord must be ready again (30 real seconds) when the boy tries for the lantern himself, WREN_AT + WREN_OWN_AFTER mission
	# seconds in: the faster the clock runs, the sooner the first one is cast.
	var own_try: float = float(VigilFlameDirector.WREN_AT) + float(VigilFlameDirector.WREN_OWN_AFTER)
	if now < minf(FLAME_HOLD_AT, own_try - 30.0 * rules.clock_rate - 2.0):
		return ""
	# Before the boy comes, the bystanders about the lantern thinned: Silent Doom where none would see it.
	var thinned := _flame_doom_stray(bc, d, rules, slots, ctx, lantern, null)
	if thinned != "":
		return thinned
	if ctx.memo.has("held") or not bc._slot_ready(rules, slots, "discord"):
		return ""
	# One Discord on the Vigil just before Wren comes: the bearer stands still with his acolytes blind, so the boy finds the lantern held
	# (and no stretch of the opening passes 45 s).
	var take: Array[Vector2] = []
	for p in d.vigil.walkers():
		if MissionDirector._alive(p):
			take.append(p.ground_pos)
	var mid := Vector2.ZERO
	for at in take:
		mid += at / float(take.size())
	var one := not take.is_empty()
	for at in take:
		one = one and at.distance_to(mid) <= DiscordFx.DISCORD_R - float(bc.FLAME_DISCORD_MARGIN)
	if not one:
		return ""
	ctx.memo["held"] = true
	rules.cast(slots.discord, mid)
	return "discord the Vigil, to hold the lantern still for the boy"


static func _flame_swap(bc, d: VigilFlameDirector, rules: Rules, slots: Dictionary, ctx: Dictionary) -> String:
	var lantern := d.flame_at()
	if lantern == Vector2.INF or d.swapping:
		return ""
	var w := d.wren
	var bearer: Person = d.vigil.bearer if d.vigil != null and MissionDirector._alive(d.vigil.bearer) else null
	var walking: Array[Person] = d.vigil.walkers() if d.vigil != null and d.vigil.active else ([] as Array[Person])
	# The Wisp that draws him: on the lantern, a step toward Wren so that he stands within WillOWisp.CHARGE_LURE_R of it.
	var step: float = maxf(w.ground_pos.distance_to(lantern) - (WillOWisp.CHARGE_LURE_R - 0.3), FLAME_LIGHT_OFF)
	var light: Vector2 = lantern.move_toward(w.ground_pos, step)
	# The calm Faithful a Wisp at the lantern would draw round it (they would stand beside the boy and see): Silent Doom takes each in turn
	# where none would see it (the Vigil's own, held or not, are spared).
	var drawn: Array[Person] = _flame_drawn(d, light, walking, w)
	var did := _flame_doom_stray(bc, d, rules, slots, ctx, lantern, w)
	if did != "":
		return did
	# The Vigil's watchers (the acolytes at the lantern, any bystander too near to take) and the bearer, whose stillness holds the lantern.
	var watchers: Array[Person] = []
	for f in d.faithful:
		if MissionDirector._alive(f) and f != bearer and d.faithful_seeing(f.ground_pos, 0.01, bearer) == f \
				and (walking.has(f) or f.ground_pos.distance_to(lantern) <= float(bc.FLAME_WATCH_R)):
			watchers.append(f)
	var wisp_ready: bool = bc._slot_ready(rules, slots, "wisp")
	var held := bearer == null or bearer.mind in MissionDirector.BLIND
	var free: bool = wisp_ready and not w.held_by_god() and not w.shaken()
	var crowded: bool = not drawn.is_empty()
	# All is ready for him: the Wisp that draws him to the lantern.
	if free and watchers.is_empty() and held and not crowded and step <= FLAME_LIGHT_MAX:
		rules.cast(slots.wisp, light)
		return "wisp Wren to the lantern"
	# Bystanders about the lantern that Silent Doom could not take unseen: the Wisp draws them off (never within reach of Wren).
	if wisp_ready and not d.whispered:
		for f in drawn:
			if f.ground_pos.distance_to(lantern) <= float(bc.FLAME_STRAY_R):
				var did_off := _flame_draw_off(bc, d, rules, slots, ctx, lantern, f.ground_pos)
				if did_off != "":
					return did_off
				break
	# The watchers and the bearer taken by Discord: just before the boy, left alone, comes for the lantern himself (he is quick over the
	# last steps and Discord is a moment landing), or as he does, or as the lure is about to be cast.
	# (v0.11.2: his thirty seconds are mission seconds, and the Discord lasts real ones, so what is left is counted at the clock's rate.)
	var coming: float = (float(VigilFlameDirector.WREN_OWN_AFTER) - (d.timeline.elapsed() - d._appeared_at) * d.timeline.stretch_factor()) 		/ maxf(rules.clock_rate, 0.01)
	if (not watchers.is_empty() or not held) and bc._slot_ready(rules, slots, "discord") and (d.attempting or coming <= FLAME_DISCORD_LEAD or wisp_ready):
		var fit := _flame_discord_point(bc, lantern, watchers, held)
		if fit == Vector2.INF and (d.attempting or coming <= 0.5):
			fit = _flame_discord_best(bc, lantern, watchers, held)
		if fit != Vector2.INF and (d.attempting or coming <= FLAME_DISCORD_LEAD or (wisp_ready and not crowded)):
			rules.cast(slots.discord, fit)
			return "discord the watchers and the bearer"
	return ""


## The point where one Discord takes the most of the bearer (when not held) and the watchers, nearest the lantern first; INF for none.
static func _flame_discord_best(bc, lantern: Vector2, watchers: Array[Person], held: bool) -> Vector2:
	var points: Array[Vector2] = []
	if not held:
		points.append(lantern)
	for f in watchers:
		points.append(f.ground_pos)
	var best := Vector2.INF
	var most := 0
	var reach: float = DiscordFx.DISCORD_R - float(bc.FLAME_DISCORD_MARGIN)
	for at in points:
		var n := 0
		for q in points:
			n += 1 if q.distance_to(at) <= reach else 0
		if n > most:
			most = n
			best = at
	return best


## The calm Faithful a Wisp cast at `light` would draw (within its reach, going about their day, not of the Vigil, nearest the light first).
static func _flame_drawn(d: VigilFlameDirector, light: Vector2, walking: Array[Person], wren: Person) -> Array[Person]:
	var out: Array[Person] = []
	for f in d.faithful:
		if MissionDirector._alive(f) and not f.inside and not walking.has(f) and f != wren and f.mind in Person.LURABLE \
				and f.ground_pos.distance_to(light) <= WillOWisp.LURE_REACH:
			out.append(f)
	out.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(light) < b.ground_pos.distance_to(light))
	return out


## Silent Doom on the nearest of those bystanders (to `lantern`) whom none would see fall, when Doom is ready; "" when none.
static func _flame_doom_stray(bc, d: VigilFlameDirector, rules: Rules, slots: Dictionary, ctx: Dictionary, lantern: Vector2, wren: Person) -> String:
	if not bc._slot_ready(rules, slots, "doom"):
		return ""
	var walking: Array[Person] = d.vigil.walkers() if d.vigil != null and d.vigil.active else ([] as Array[Person])
	var spare: Array = walking.duplicate()
	if wren != null:
		spare.append(wren)
	for f in _flame_drawn(d, lantern, walking, wren):
		if bc._doom_unseen(ctx.crowd, f.ground_pos, spare):
			rules.cast(slots.doom, f.ground_pos)
			return "doom a bystander near the lantern, unseen"
	return ""


## Where one Discord takes the lantern's bearer (when not held) and every watcher, or Vector2.INF when they do not all fit within its reach:
## the first of their mean point, each of them and each midway between two that holds them all.
static func _flame_discord_point(bc, lantern: Vector2, watchers: Array[Person], held: bool) -> Vector2:
	var take: Array[Vector2] = []
	if not held:
		take.append(lantern)
	for f in watchers:
		take.append(f.ground_pos)
	if take.is_empty():
		return Vector2.INF
	var mean := Vector2.ZERO
	for at in take:
		mean += at / float(take.size())
	var centres: Array[Vector2] = [mean]
	for i in take.size():
		centres.append(take[i])
		for k in range(i + 1, take.size()):
			centres.append((take[i] + take[k]) * 0.5)
	for c in centres:
		var all := true
		for at in take:
			all = all and at.distance_to(c) <= DiscordFx.DISCORD_R - float(bc.FLAME_DISCORD_MARGIN)
		if all:
			return c
	return Vector2.INF


## Where a decoy Wisp draws the beam at `beam` away from Wren: DODGE round the beam, beyond DODGE + POOL_R of him, with the fewest Faithful in reach.
static func _flame_decoy_spot(bc, d: VigilFlameDirector, ctx: Dictionary, beam: Vector2, w: Person) -> Vector2:
	var grid: WalkGrid = (ctx.crowd as Crowd)._grid
	var lure := Vector2.INF
	var fewest := 0
	for k in int(bc.FLAME_DIRS):
		var at := grid.nearest_walkable(beam + Vector2.from_angle(TAU * float(k) / float(bc.FLAME_DIRS)) * float(bc.FLAME_DODGE))
		if at == Vector2.INF or at.distance_to(w.ground_pos) < float(bc.FLAME_DODGE) + Searchlight.POOL_R:
			continue
		var n := 0
		for f in d.faithful:
			if MissionDirector._alive(f) and f.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH:
				n += 1
		if lure == Vector2.INF or n < fewest:
			lure = at
			fewest = n
	return lure


static func _flame_carry(bc, d: VigilFlameDirector, rules: Rules, slots: Dictionary, ctx: Dictionary, quiet := false) -> String:
	var w := d.wren
	var light := d.searchlight
	if rules.time_left <= Searchlight.SEARCH_LAST + 1.0 and w.ground_pos.distance_to(d.temple_door) > float(bc.FLAME_DANGER) \
			and bc._slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, d.temple_door)
		return "discord at the Temple's door, to draw the searching beam"
	if w.held_by_god() or bc._flame_clear(light, w, Vector2.INF, float(bc.FLAME_LOOKAHEAD)) > Searchlight.POOL_R + float(bc.FLAME_MARGIN):
		# No beam is due on him. A long quiet is spent drawing a beam off his road before it comes (a decoy far from him), so no stretch
		# passes 45 s.
		if quiet and light.on and light.decoy_beam < 0 and bc._slot_ready(rules, slots, "wisp"):
			var beam := light.aim(bc._flame_threat(light, w))
			var lure := _flame_decoy_spot(bc, d, ctx, beam, w)
			if lure != Vector2.INF:
				rules.cast(slots.wisp, lure)
				return "wisp, a decoy to keep the beam off his road"
		return ""
	# A beam is due on him. A Wisp within WillOWisp.CHARGE_LURE_R of him draws him off the road to stand in its ring while it passes (and,
	# so near him, is no decoy: the director lets it call no beam); the spot whose stand is farthest from every beam over FLAME_PLAN.
	var grid: WalkGrid = (ctx.crowd as Crowd)._grid
	if bc._slot_ready(rules, slots, "wisp"):
		var best := Vector2.INF
		var best_clear := 0.0
		var walk_on: float = bc._flame_clear(light, w, Vector2.INF, float(bc.FLAME_PLAN))
		for reach: float in [FLAME_RETREAT * 0.5, FLAME_RETREAT]:
			for k in int(bc.FLAME_DIRS):
				var at := grid.nearest_walkable(w.ground_pos + Vector2.from_angle(TAU * float(k) / float(bc.FLAME_DIRS)) * reach)
				if at == Vector2.INF or at.distance_to(w.ground_pos) > WillOWisp.CHARGE_LURE_R - 0.2:
					continue
				var clear: float = bc._flame_clear(light, w, at, float(bc.FLAME_PLAN))
				if clear > best_clear and clear > walk_on:
					best = at
					best_clear = clear
		if best != Vector2.INF:
			rules.cast(slots.wisp, best)
			return "wisp Wren out of the beam's way"
	# No Wisp: Discord stops him where he stands for its fifteen seconds, if the beam is due and not yet near.
	if bc._slot_ready(rules, slots, "discord") and bc._flame_clear(light, w, Vector2.INF, float(bc.FLAME_LOOKAHEAD)) > Searchlight.POOL_R:
		var held: float = bc._flame_clear(light, w, w.ground_pos, float(bc.FLAME_PLAN))
		if held > Searchlight.POOL_R + float(bc.FLAME_MARGIN):
			rules.cast(slots.discord, w.ground_pos)
			return "discord Wren, to hold him while the beam passes"
	return ""


## The Vigil Flame's numbers: when the Wisp is cast ahead of the Vigil's road (ready again for the boy by 0:50) and how far ahead of the
## lantern; when the Vigil is held still by Discord ahead of Wren's coming (0:50), so he finds the lantern held and its watchers blind; how
## far toward Wren from the lantern the Wisp that draws him is cast, at most (past it, wait for him to come nearer); how far past
## WillOWisp.CHARGE_LURE_R of Wren the Wisp that draws the bystanders off is kept (it would draw him too); how many seconds before he tries
## the swap himself Discord may be cast; how long a quiet with the flame in hand may last before a decoy; how far from Wren, at most, the
## Wisp that draws him off a beam's way is cast (inside WillOWisp.CHARGE_LURE_R of him).
const FLAME_ROAD_AT := 18.0
const FLAME_ROAD_AHEAD := 3.0
const FLAME_HOLD_AT := 41.0
const FLAME_LIGHT_OFF := 0.3
const FLAME_LIGHT_MAX := 0.9
const FLAME_WREN_MARGIN := 0.4
const FLAME_DISCORD_LEAD := 9.0
const FLAME_QUIET := 30.0
const FLAME_RETREAT := 2.6


## Seconds after its Wisp that the Festival's policy lets a Heaven Splitter fall on the knot it drew (before the square packs).
const KNOT_AFTER := 8.0


## The Festival, loadout B (heaven, smite, ember, wisp; v0.11.1 row 12), on the board (a star mission: wins and idle only). A look of the
## policy: what was cast, or "". The first that applies: the packed square's Mayor alive and out, Smite on him (his fall frightens every goer
## within MAYOR_PANIC_R of the fountain); Heaven Splitter along the thickest knot of goers (any loud cast breaks the goers in its danger);
## a Wisp at the square while goers still gather, to draw them into a knot for the next Heaven; Ember on a house or stall by the square.
static func act_festival(bc, ctx: Dictionary) -> String:
	var d := ctx.d as FestivalDirector
	if d == null or d.broken():
		return ""
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var packed: bool = d.timeline.elapsed() >= FestivalDirector.BONFIRE_AT * d.timeline.stretch_factor()
	if packed and MissionDirector._alive(d.mayor) and not d.mayor.inside and bc._slot_ready(rules, slots, "smite"):
		rules.cast(slots.smite, d.mayor.ground_pos)
		return "smite the Mayor"
	var memo: Dictionary = ctx.memo
	var now: float = d.timeline.elapsed()
	var knot: Vector2 = bc._densest(d.goers)
	var drawn: bool = memo.has("wisp_at") and now >= float(memo.wisp_at) + KNOT_AFTER
	if knot != Vector2.INF and (packed or drawn) and bc._slot_ready(rules, slots, "heaven"):
		rules.cast(slots.heaven, knot, {"dir": Vector2(1, 0)})
		return "heaven through the thickest knot of goers"
	if not packed and not memo.has("wisp_at") and bc._slot_ready(rules, slots, "wisp"):
		memo["wisp_at"] = now
		rules.cast(slots.wisp, TownLayout.MARKET_SQUARE.get_center())
		return "wisp the goers into a knot"
	if bc._slot_ready(rules, slots, "ember"):
		var house := _by_square(ctx.crowd)
		if house != null:
			rules.cast(slots.ember, house.center())
			return "ember a building by the square"
	return ""


static func state_festival(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as FestivalDirector
	if d == null:
		return ""
	return "lost=%d/%d mayor=%s" % [d.count(), d.need, "alive" if MissionDirector._alive(d.mayor) else "gone"]


## The nearest standing house or stall to the market square that is not already burning, or null.
static func _by_square(crowd: Crowd) -> Structure:
	var c := TownLayout.MARKET_SQUARE.get_center()
	var best: Structure = null
	for s in crowd._env.structures():
		if not is_instance_valid(s) or s.destroyed or not (s.kind == Structure.Kind.HOUSE or s.kind == Structure.Kind.MARKET_STALL) \
				or crowd.fires.is_burning(s):
			continue
		if best == null or s.center().distance_to(c) < best.center().distance_to(c):
			best = s
	return best


## The Crown's Bread, loadout B (heaven, verdict, discord, wisp; v0.11.1 row 13). A look of the policy: what was cast, or "". It never holds a
## target down ahead of its time (as loadout A's). Mob Verdict is the work it means to do, on the granary and the bridge (it recovers in
## ninety seconds, between them): a Wisp ahead of the stage draws a crowd to the building, then the mob's circle on the most people (the
## crew among them, who tear at the building instead of mending it) -- the mob's tearing takes the seconds a mob takes. The mill, Heaven
## Splitter at the stage (its core brings a building down whatever mends it), a Wisp ahead having drawn the bystanders off it. A Verdict
## spent or failed, Heaven takes what stands.
static func act_bread(bc, ctx: Dictionary) -> String:
	var d := ctx.d as CrownsBreadDirector
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var crowd: Crowd = ctx.crowd
	var memo: Dictionary = ctx.memo
	var cur := -1
	for i in d.targets.size():
		if d.in_use[i] and not d.razed(d.targets[i]):
			cur = i
			break
	var up := d.upcoming()
	var verdict_ready: bool = bc._slot_ready(rules, slots, "verdict")
	# Ahead of a stage: the Wisp, once.
	if cur < 0 and up >= 0 and d.due_in(up) <= BREAD_PREP and not memo.has("prep%d" % up) and bc._slot_ready(rules, slots, "wisp"):
		memo["prep%d" % up] = true
		if up != 1 and verdict_ready:
			rules.cast(slots.wisp, _mob_centre(crowd, d.targets[up], true))
			return "wisp a crowd to the %s ahead of its time" % CrownsBreadDirector.WORDS[up]
		rules.cast(slots.wisp, _mob_centre(crowd, d.targets[up], false))
		return "wisp the bystanders off the %s ahead of its time" % CrownsBreadDirector.WORDS[up]
	if cur < 0 and up >= 0 and (up == 1 or not verdict_ready) and d.due_in(up) <= BREAD_LEAD and bc._slot_ready(rules, slots, "heaven"):
		rules.cast(slots.heaven, d.targets[up].center(), {"dir": Vector2(1, 0)})  # its strike falls as the stage opens
		return "heaven the %s as it opens" % CrownsBreadDirector.WORDS[up]
	if cur < 0 or not is_instance_valid(d.targets[cur]) or d.targets[cur].destroyed:
		return ""
	var s := d.targets[cur]
	var now: float = float(d._clock)
	if cur != 1 and verdict_ready:
		var to: Vector2 = _mob_centre(crowd, s, true)
		memo["verdict_at"] = now
		rules.cast(slots.verdict, s.center(), {"to": to})
		return "verdict on the %s (%d near)" % [CrownsBreadDirector.WORDS[cur], _near_count(crowd, to)]
	if bc._slot_ready(rules, slots, "heaven") and (cur == 1 or not memo.has("verdict_at") or now >= float(memo.verdict_at) + BREAD_HEAVEN_AFTER):
		rules.cast(slots.heaven, s.center(), {"dir": Vector2(1, 0)})
		return "heaven the %s" % CrownsBreadDirector.WORDS[cur]
	return ""


static func state_bread(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as CrownsBreadDirector
	return "razed=%d current=%d guards=%d rebuilt=%d phase=%s" % [d.razed_count(), d.current(), d.guards(d.current()).size(), d.rebuilt,
		d.hint_phase()]


## Fewer than this many people near the bridge and the Wisp draws more before the Verdict; the Verdict spent for this long and the
## bridge still stands, Heaven takes it.
const BREAD_MOB := 12
const BREAD_HEAVEN_AFTER := 40.0
## How near its time the bridge's Wisp is cast ahead (the crowd is drawn by the time it opens).
const BREAD_PREP := 25.0
## Heaven Splitter is cast this many seconds before a granary or mill opens (its strike falls 1.4 s later).
const BREAD_LEAD := 5.0


## A point round building `s`, on rings of 2 and 4 (the building's own centre too): with `most`, the one with the most people within Mob Verdict's
## reach (the centre of the mob's circle, or of a Wisp that draws a crowd); without, the one with the most in a Wisp's reach 5 from the building
## (where a Wisp draws the bystanders off it).
static func _mob_centre(crowd: Crowd, s: Structure, most_near := true) -> Vector2:
	var grid: WalkGrid = crowd._grid
	var best: Vector2 = grid.nearest_walkable(s.center())
	var most := _near_count(crowd, best) if most_near else -1
	var rings: Array = [2.0, 4.0] if most_near else [5.0]
	for r: float in rings:
		for k in 8:
			var at: Vector2 = grid.nearest_walkable(s.center() + Vector2.from_angle(TAU * float(k) / 8.0) * r)
			if at == Vector2.INF:
				continue
			var n := _near_count(crowd, at)
			if n > most:
				most = n
				best = at
	return best


## How many people out of doors stand within the Verdict's reach of `at`.
static func _near_count(crowd: Crowd, at: Vector2) -> int:
	var n := 0
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= MobVerdictFx.RADIUS:
				n += 1
	return n


## The Prisoner, loadout B (wisp, smite, discord, deathmark; v0.11.1 row 14). A look of the policy: what was cast, or "". Bound: each gaoler
## not held by the god taken (Smite, else Death Mark, else Discord), then Smite on the stocks' far side. Free: her seizer Smitten; a watcher
## near her or her next stretch dealt with -- Smite where he stands alone, Discord on a pair, else Death Mark; a Wisp cast ahead of her on her
## road, which she follows (the director gives her that), stopping short of a watched postern.
static func act_prisoner(bc, ctx: Dictionary) -> String:
	var d := ctx.d as PrisonerDirector
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var her := d.charge
	if not MissionDirector._alive(her) or her.inside:
		return ""
	if d.bound:
		for v: Variant in d.gaolers:
			if MissionDirector._alive(v) and not (v as Person).inside and not (v as Person).held_by_god():
				var did := _prisoner_remove(bc, rules, slots, ctx, d, v as Person)
				if did != "":
					return did
				return ""
		if is_instance_valid(d.stocks) and not d.stocks.destroyed and bc._slot_ready(rules, slots, "smite"):
			rules.cast(slots.smite, d.stocks_far)
			return "smite the stocks"
		return ""
	if d.held and MissionDirector._alive(d.seizer):
		return _prisoner_remove(bc, rules, slots, ctx, d, d.seizer as Person)
	var road: Array = PrisonerDirector.ROAD
	var ahead: Vector2 = bc._road_ahead(road, her.ground_pos, float(bc.PRISONER_STRETCH))
	for v: Variant in d._watchers():
		if not d._watching(v):
			continue
		var p := v as Person
		if p.ground_pos.distance_to(her.ground_pos) > float(bc.PRISONER_NEAR) and bc._seg_dist(p.ground_pos, her.ground_pos, ahead) > float(bc.PRISONER_NEAR):
			continue
		var did := _prisoner_remove(bc, rules, slots, ctx, d, p)
		if did != "":
			return did
	if bc._slot_ready(rules, slots, "wisp") and her.mind == Person.Mind.DUTY and not d.held:
		var watched := not d.watch_away and d._watch_standing()
		var to: Vector2 = bc._road_ahead(road, her.ground_pos, PrisonerDirector.WISP_R - 0.8)
		var wait: Vector2 = d._walkable(d.gate_at + bc.PRISONER_WAIT)
		if watched and bc._road_progress(road, to) > bc._road_progress(road, wait):
			to = wait
		# the light within her reach (PrisonerDirector.WISP_R) of where she stands now, toward the road ahead
		to = her.ground_pos + (to - her.ground_pos).limit_length(PrisonerDirector.WISP_R - 0.3)
		to = d._walkable(to)
		if her.ground_pos.distance_to(to) > 1.0:
			rules.cast(slots.wisp, to)
			return "wisp her on to (%.1f, %.1f)" % [to.x, to.y]
	return ""


static func state_prisoner(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as PrisonerDirector
	return "bound=%s held=%s seizures=%d gate=%.1f watch_away=%s hounds=%d phase=%s" % [d.bound, d.held, d.seizures,
		d.charge.ground_pos.distance_to(d.gate_at) if MissionDirector._alive(d.charge) else -1.0, d.watch_away, d.hunters.size(), d.hint_phase()]


## Takes watcher `p` out of her way: Smite where he stands alone (none else within a Smite's kill of him and she is clear of it), Discord
## where another stands by him, else Death Mark on him; "" with all of them cooling.
static func _prisoner_remove(bc, rules: Rules, slots: Dictionary, ctx: Dictionary, d: PrisonerDirector, p: Person) -> String:
	var her := d.charge
	var crowd: Crowd = ctx.crowd
	var clear: bool = her.ground_pos.distance_to(p.ground_pos) > SmiteFx.KILL_R + 0.4
	if clear and bc._slot_ready(rules, slots, "smite"):
		rules.cast(slots.smite, p.ground_pos)
		return "smite a watcher"
	if bc._slot_ready(rules, slots, "deathmark") and not p.statuses.has(&"frail") and her.ground_pos.distance_to(p.ground_pos) > 1.5:
		rules.cast(slots.deathmark, p.ground_pos)
		return "death mark a watcher"
	if bc._slot_ready(rules, slots, "discord") and her.ground_pos.distance_to(p.ground_pos) > DiscordFx.DISCORD_R + float(bc.PRISONER_CLEAR):
		rules.cast(slots.discord, p.ground_pos)
		return "discord a watcher"
	return ""


## The Heretic Hunt, loadout B (blight, discord, wisp, deathmark; v0.11.1 row 15). A look of the policy: what was cast, or "". The first
## that applies: the captain out of doors and not marked, Death Mark on him; a raised standard that takes Blight (unguarded), Blight it;
## a raised standard with one guard left standing, Discord holds him; a sweep (raised, or within HUNT_AHEAD of its raising) with two or
## more guards standing and none marked, Death Mark one (two Discords' reach is a single man: guards stand 2.5 apart, Discord holds
## 1.2; the replacement waits 30 s and walks in, so the dead are not yet replaced when the standard stands). Never a loud power.
static func act_hunt(bc, ctx: Dictionary) -> String:
	var rules: Rules = ctx.rules
	var slots: Dictionary = ctx.slots
	var d := ctx.d as HereticHuntDirector
	var head: Variant = d.head
	if d.head_out and MissionDirector._alive(head) and not (head as Person).inside and bc._slot_ready(rules, slots, "deathmark") \
			and not (head as Person).statuses.has(&"frail"):
		rules.cast(slots.deathmark, (head as Person).ground_pos)
		return "death mark the captain"
	for i in d.steps.size():
		var s := d.standard(i)
		if not d.steps[i].raised or d.steps[i].broken or s == null or s.destroyed:
			continue
		if d.blight_takes(s.center()):
			if bc._slot_ready(rules, slots, "blight"):
				rules.cast(slots.blight, s.center())
				return "blight the standard of %s" % d.steps[i].words
			continue
		var on := d.party_on(i)
		if on.size() == 1 and not on[0].statuses.has(&"frail") and bc._slot_ready(rules, slots, "discord") \
				and rules.cooldown_left(int(slots.blight)) <= 6.0:
			rules.cast(slots.discord, on[0].ground_pos)
			return "discord the last guard of %s" % d.steps[i].words
	for i in d.steps.size():
		if d.steps[i].broken or (not d.steps[i].raised and d.due_in(i) > float(bc.HUNT_AHEAD)):
			continue
		var did: String = _mark_guard(bc, rules, slots, ctx.crowd, d, i, d.party_on(i))
		if did != "":
			return did
	return ""


static func state_hunt(_bc, ctx: Dictionary) -> String:
	var d := ctx.d as HereticHuntDirector
	var on := PackedStringArray()
	for i in d.steps.size():
		on.append("%d/%d" % [d.party_on(i).size(), d.steps[i].party.size()])
	return "broken=%d current=%d next=%d captain=%s searching=%s phase=%s on=%s" % [d.broken_count(), d.current(), d.next_step(), d.head_out,
		d.searching, d.hint_phase(), ",".join(on)]


## Death Mark on the guard of step `i` who stands apart from the rest (most alone first), when two or more stand, it is ready and no
## guard is marked already.
static func _mark_guard(bc, rules: Rules, slots: Dictionary, crowd: Crowd, d: HereticHuntDirector, i: int, on: Array[Person]) -> String:
	if on.size() < 2 or not bc._slot_ready(rules, slots, "deathmark"):
		return ""
	for p in on:
		if p.statuses.has(&"frail"):
			return ""
	var pick := on[0]
	for p in on:
		if bc._bread_alone(crowd, p):
			pick = p
			break
	rules.cast(slots.deathmark, pick.ground_pos)
	return "death mark a guard of %s" % d.steps[i].words
