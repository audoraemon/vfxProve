class_name FireManager
extends RefCounted
## Fires in the town (v0.04 P1): a fire-kind hit sets a burnable building burning; a fire grows, eats its building,
## can spread to its neighbours (faster in a tornado's wind) and keeps a short danger about it so people run from it
## and routes bend round it. Nearby calm citizens turn out to fight it: each fetches water from the nearest standing
## fountain or well and douses the fire, until it is out -- or too big, or the water is gone, or the town evacuates.

const BURNABLE := [Structure.Kind.HOUSE, Structure.Kind.MARKET_STALL, Structure.Kind.TREE, Structure.Kind.BARRACKS,
	Structure.Kind.TEMPLE]
const FIRE_KINDS := [&"fire", &"cinder", &"nova", &"orbital", &"lightning"]
const START := 0.35
const GROW := 0.03
const WIND_GROW := 3.0
const WIND_REACH := 6.0
## Damage a second at full intensity (hp), how often the fire is stepped, and its chance a second (at full
## intensity) to catch a neighbour within SPREAD_REACH.
const BURN_DPS := 6.0
const HZ := 4.0
const SPREAD := 0.08
const SPREAD_REACH := 1.5
## How often the flames, smoke and danger are renewed.
const RENEW := 3.0
## Responders: at most this many per fire by default (the profile sets it: ResponseProfile.fire_crew), recruited
## within RECRUIT_REACH, never for a fire past ABANDON; a bucket
## takes DOUSE off the intensity; filling and dousing each take ACT seconds.
const MAX_RESPONDERS := 4
const RECRUIT_REACH := 10.0
const ABANDON := 0.85
const DOUSE := 0.15
const ACT := 1.0
## A beater short of its ring spot (stopped by the crowd, or its walk ran out) picks a new one at most this often.
const RESPOT := 0.25

## Structure -> {intensity, renew_in, responders: Array[Person]}
var fires := {}
var _crowd: Crowd
var _env: EnvironmentField
var _rng := RandomNumberGenerator.new()
var _step_in := 0.0
var _recruit_in := 0.0
## True while the fire deals its own damage, so that damage never re-ignites anything.
var _burning_now := false
## How many fires have ended so far (v0.08.2, for the behaviour reports): put out by the water, or with their
## building fallen while it burned.
var doused_out := 0
var burned_down := 0
## Burning ground (Dragonfire Parade, GroundFire), in lay order: a separate list from `fires`, so every reader of the
## building fires stays right. They roll their spread on their own stream, never `_rng`, so the building fires draw
## the same numbers with or without them.
var patches: Array[GroundFire] = []
var _patch_rng := RandomNumberGenerator.new()
## DummyEnemy -> {heat, in}: seconds of fire each person has taken (GroundFire.scorch()).
var _heat := {}
var _harm_in := 0.0
var _next_patch_id := 1
## For the behaviour reports.
var patches_laid := 0
var patches_beaten := 0
var patches_burned_out := 0


func setup(crowd: Crowd, env: EnvironmentField, seed_value: int) -> FireManager:
	_crowd = crowd
	_env = env
	_rng.seed = seed_value
	_patch_rng.seed = seed_value + 1
	env.structure_hit.connect(_on_hit)
	return self


## Whether `s` can burn: its kind's say (BURNABLE), or, for a ChatGPT plot (the capital's), its building type's
## (BuildingTypes: bare masonry never burns).
static func burns(s: Structure) -> bool:
	if s.role == CapitalPlots.ROLE:
		return bool(BuildingTypes.info(s.art_tag).get("burns", false))
	return s.kind in BURNABLE


func is_burning(s: Structure) -> bool:
	return fires.has(s)


func intensity(s: Structure) -> float:
	return float(fires[s].intensity) if fires.has(s) else 0.0


func _on_hit(s: Structure, amount: float, kind: StringName) -> void:
	if _burning_now or not kind in FIRE_KINDS:
		return
	ignite(s, START + amount / maxf(s.max_hp, 1.0))


## Set `s` burning at `level` (or raise its fire to it).
func ignite(s: Structure, level: float) -> void:
	if not is_instance_valid(s) or s.destroyed or not burns(s):
		return
	if fires.has(s):
		fires[s].intensity = clampf(maxf(float(fires[s].intensity), level), 0.0, 1.0)
		return
	fires[s] = {"intensity": clampf(level, 0.0, 1.0), "renew_in": 0.0, "responders": []}


## One frame: fires grow, burn, spread and renew; responders are recruited and walk their rounds.
func step(delta: float) -> void:
	_step_in -= delta
	if _step_in <= 0.0:
		_step_in = 1.0 / HZ
		_burn(1.0 / HZ)
		_burn_patches(1.0 / HZ)
	_harm_in = maxf(_harm_in - delta, -GroundFire.HARM_TICK)  # a stall leaves no catch-up debt
	if _harm_in <= 0.0:
		_harm_in += GroundFire.HARM_TICK
		if not patches.is_empty() or not _heat.is_empty():
			GroundFire.scorch(_crowd._field, patches, _heat, GroundFire.HARM_TICK)
	_recruit_in -= delta
	if _recruit_in <= 0.0:
		_recruit_in = 1.0
		_recruit()
	_tend_responders(delta)
	_tend_beaters(delta)


func _burn(dt: float) -> void:
	var catching: Array = []
	for s: Structure in fires.keys():
		var f: Dictionary = fires[s]
		if not is_instance_valid(s) or s.destroyed:
			_put_out(s, false)
			continue
		var windy := _windy(s.center())
		f.intensity = minf(float(f.intensity) + GROW * (WIND_GROW if windy else 1.0) * dt, 1.0)
		_burning_now = true
		s.damage(BURN_DPS * float(f.intensity) * dt, s.center(), &"fire")
		_burning_now = false
		if not is_instance_valid(s) or s.destroyed:
			_put_out(s, false)
			continue
		f.renew_in = float(f.renew_in) - dt
		if float(f.renew_in) <= 0.0:
			f.renew_in = RENEW
			s.ignite(Vector2(0, -s.height * 0.6), RENEW + 0.3)
			var radius := s.footprint.size.length() * 0.5 + 0.8
			_crowd.threats.register(s.center(), radius, 0.5, RENEW + 0.5, 5.0, 7.0, &"fire")
		if _rng.randf() < float(f.intensity) * SPREAD * (WIND_GROW if windy else 1.0) * dt:
			for n in _env.near(s.center(), SPREAD_REACH):
				if n != s and burns(n) and not n.destroyed and not fires.has(n) \
						and n.distance_to(s.center()) <= SPREAD_REACH:
					catching.append(n)
					break
	for n in catching:
		ignite(n, START)


## Lay a patch of burning ground at `at`, at full strength; its danger is registered at once.
func lay(at: Vector2, radius := GroundFire.RADIUS) -> GroundFire:
	var p := GroundFire.new(at, radius, _next_patch_id)
	_next_patch_id += 1
	p.owned = true
	patches.append(p)
	patches_laid += 1
	_renew_patch(p)
	return p


## One step of the patches: burn down, renew the danger, and roll for a building catching.
func _burn_patches(dt: float) -> void:
	# No tornado anywhere (nearly always): no patch is windy, and none need ask the threats near it.
	var wind := _crowd.threats.has_kind(&"tornado")
	for p: GroundFire in patches.duplicate():
		if p.out:
			continue
		p.burn_down(dt, _beaters(p))
		if p.out:
			_patch_out(p)
			continue
		p.renew_in -= dt
		if p.renew_in <= 0.0:
			_renew_patch(p)
		if _patch_rng.randf() < spread_chance(p.strength, wind and _windy(p.at), dt):
			var s := patch_catch(_env, p, fires)
			if s != null:
				ignite(s, START)


## How many beaters are at work on `p`: its crew members beating, within reach of the beat ring.
func _beaters(p: GroundFire) -> int:
	var n := 0
	for b in p.crew:
		if is_instance_valid(b) and b.is_alive() and b.mind == Person.Mind.ASSIST and b.assist_patch == p and b.assist_beating \
				and b.ground_pos.distance_to(p.at) <= p.radius + GroundFire.BEAT_GAP + Person.GOAL_REACH:
			n += 1
	return n


## A patch's chance in `dt` seconds to set a touching building alight (today's building rule).
static func spread_chance(strength: float, windy: bool, dt: float) -> float:
	return strength * SPREAD * (WIND_GROW if windy else 1.0) * dt


## The building a patch would set alight: the first standing burnable within radius + TOUCH of its centre (`env.near`
## order) that is not already burning; null when none.
static func patch_catch(env: EnvironmentField, p: GroundFire, fires: Dictionary) -> Structure:
	var reach := p.radius + GroundFire.TOUCH
	for n in env.near(p.at, reach):
		if burns(n) and not n.destroyed and not fires.has(n) and n.distance_to(p.at) <= reach:
			return n
	return null


## Renew the patch's danger in place (ThreatManager.refresh(): no new id, no re-weighing of the walk grid), or register
## it -- a burning house's numbers -- when it has none (at laying, or while its place was veiled).
func _renew_patch(p: GroundFire) -> void:
	p.renew_in = RENEW
	if not _crowd.threats.refresh(p.threat_id, RENEW + 0.5):
		p.threat_id = _crowd.threats.register(p.at, p.radius + GroundFire.THREAT_PAD, 0.5, RENEW + 0.5, 5.0, 7.0, &"fire")


## The patch is out (beaten, or burned out): its danger ends at once, its crew stands down, it leaves the list.
func _patch_out(p: GroundFire) -> void:
	p.out = true
	if p.beaten:
		patches_beaten += 1
	else:
		patches_burned_out += 1
	_end_danger(p)
	for b in p.crew:
		if not is_instance_valid(b) or b.assist_patch != p:
			continue
		if b.is_alive() and b.mind == Person.Mind.ASSIST:
			b.stand_down()
		else:
			# Frightened off (or dead) this very frame: nothing of this patch is kept.
			b.assist_patch = null
			b.assist_beating = false
	p.crew.clear()
	patches.erase(p)


## The patch's danger ends at once.
func _end_danger(p: GroundFire) -> void:
	_crowd.threats.end(p.threat_id)


## Put every patch out without counting it (the stage is cleared, or the town reset).
func clear_patches() -> void:
	for p in patches:
		p.out = true
		_end_danger(p)
	patches.clear()
	_heat.clear()


func _windy(g: Vector2) -> bool:
	for t in _crowd.threats.nearby(g, WIND_REACH):
		if t.kind == &"tornado":
			return true
	return false


## The fire on `s` is over (doused, or its building fell): its responders go back to their day.
func _put_out(s: Structure, doused: bool) -> void:
	if not fires.has(s):
		return
	if doused:
		doused_out += 1
	else:
		burned_down += 1
	for p in fires[s].responders:
		if is_instance_valid(p) and p.mind == Person.Mind.ASSIST:
			p.stand_down()
	fires.erase(s)
	if doused and is_instance_valid(s):
		_crowd.threats.register(s.center(), s.footprint.size.length() * 0.5, 0.2, 0.1, 3.0, 4.0, &"smoke")


## A bucket of water on `s`.
func douse(s: Structure) -> void:
	if not fires.has(s):
		return
	fires[s].intensity = float(fires[s].intensity) - DOUSE
	if float(fires[s].intensity) <= 0.0:
		_put_out(s, true)


## The fountains and wells the brigade draws from; a blighted one gives none (v0.05).
func water_points() -> Array[Structure]:
	var out: Array[Structure] = []
	for s in _env.structures():
		if s.kind == Structure.Kind.FOUNTAIN and not s.destroyed and not s.blighted:
			out.append(s)
	return out


## The nearest fire to `from`, within `reach`, that can still be fought: not past ABANDON, with water to fetch
## (v0.08.2, for the engineers); null when there is none.
func nearest_fightable(from: Vector2, reach: float) -> Structure:
	var best: Structure = null
	var best_d := INF
	for s: Structure in fires.keys():
		if not is_instance_valid(s) or s.destroyed or float(fires[s].intensity) >= ABANDON \
				or nearest_water(s.center()) == null or _crowd.structure_mark(s) == &"cursed":
			continue
		var d := s.center().distance_to(from)
		if d <= reach and d < best_d:
			best_d = d
			best = s
	return best


func nearest_water(g: Vector2) -> Structure:
	var best: Structure = null
	for w in water_points():
		if best == null or w.center().distance_to(g) < best.center().distance_to(g):
			best = w
	return best


func _recruit() -> void:
	# The brigade turns out from the profile's stage (ResponseProfile.fire_from), until the town evacuates.
	var stage := _crowd.alarms.stage
	if stage >= AlarmManager.Stage.EVACUATION or stage < _crowd.profile.fire_from:
		return
	var most := _crowd.profile.fire_crew
	var jobs := _crowd.guard_jobs
	if jobs.is_open():
		jobs.prune()
	for s: Structure in fires.keys():
		if _crowd.is_veiled(s.center()) or _crowd.structure_mark(s) == &"cursed":
			continue  # a fire nobody sees (Unseen Hour), or on a cursed house (Anathema), is not fought
		var f: Dictionary = fires[s]
		var crew: Array = f.responders.filter(func(p) -> bool:
			return is_instance_valid(p) and p.mind == Person.Mind.ASSIST and p.assist_fire == s)
		f.responders = crew
		if float(f.intensity) >= ABANDON or nearest_water(s.center()) == null:
			continue
		# The citizens' brigade: its cap counts the citizens (and squads), not the guards on a job.
		var citizens_on := crew.filter(func(p) -> bool: return not jobs.on_job(p)).size()
		if citizens_on < most:
			var pool: Array[Person] = []
			for p in _crowd.citizens:
				if is_instance_valid(p) and p.is_alive() and p.profile != null and not p.night_indoors and p.fearless_left <= 0.0 and not p.is_child() \
						and (p.mind == Person.Mind.CALM or p.mind == Person.Mind.RECOVER) \
						and p.ground_pos.distance_to(s.center()) <= RECRUIT_REACH:
					pool.append(p)
			pool.sort_custom(func(a: Person, b: Person) -> bool:
				return a.ground_pos.distance_to(s.center()) < b.ground_pos.distance_to(s.center()))
			for k in mini(most - citizens_on, pool.size()):
				pool[k].assist(s)
				crew.append(pool[k])
				_go_to_water(pool[k], s)
		# The guards: ordinary guards at their posts turn out to a fire until the rally (soldier jobs).
		if jobs.is_open():
			for p in jobs.pick(s.center(), RECRUIT_REACH, guards_on(s), 1 << 20):
				enlist(p, s)
				if p.mind == Person.Mind.ASSIST:
					jobs.take(p, s)
	_recruit_patches()



## How many of the responders on `s` are guards on a job.
func guards_on(s: Structure) -> int:
	if not fires.has(s):
		return 0
	var n := 0
	for p in fires[s].responders:
		if is_instance_valid(p) and p.mind == Person.Mind.ASSIST and p.assist_fire == s and _crowd.guard_jobs.job_of(p) == s:
			n += 1
	return n


## The beaters (GS section 8): each burning patch short of `mini(CREW, profile.fire_crew)` beaters takes the nearest calm
## citizens, after the buildings have had theirs. They go to the wait ring while the patch is at full strength, else to the
## beat ring.
func _recruit_patches() -> void:
	var most := mini(GroundFire.CREW, _crowd.profile.fire_crew)
	# Who could beat at all, in citizen order -- worked out once a round, not once a patch: alive, a citizen with a day,
	# outdoors, no engineer (their team mends; G8), not standing in a fire. Only the mind changes as the round picks.
	var able: Array = []
	var able_known := false
	for p in patches:
		if p.out or _crowd.is_veiled(p.at):
			continue
		var crew: Array[Person] = []
		for b in p.crew:
			if is_instance_valid(b) and b.is_alive() and b.mind == Person.Mind.ASSIST and b.assist_patch == p:
				crew.append(b)
			elif is_instance_valid(b) and b.assist_patch == p:
				b.assist_patch = null  # dead, or frightened off: no longer on this patch
				b.assist_beating = false
		p.crew = crew
		if crew.size() >= most:
			continue
		if not able_known:
			able_known = true
			for i in _crowd.citizens.size():
				var c: Person = _crowd.citizens[i]
				if is_instance_valid(c) and c.is_alive() and c.profile != null and not c.inside and not c.engineer_duty and not c.is_child() \
						and not _in_a_patch(c.ground_pos):
					able.append([i, c])
		var pool: Array = []
		for entry in able:
			var c: Person = entry[1]
			if (c.mind == Person.Mind.CALM or c.mind == Person.Mind.RECOVER) and c.ground_pos.distance_to(p.at) <= RECRUIT_REACH:
				pool.append([c.ground_pos.distance_to(p.at), entry[0], c])
		pool.sort_custom(func(a: Array, b: Array) -> bool:
			return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
		var gap := GroundFire.WAIT_GAP if p.full() else GroundFire.BEAT_GAP
		for entry in pool:
			if crew.size() >= most:
				break
			var c: Person = entry[2]
			if p.base_angle == INF or crew.is_empty():
				p.base_angle = (c.ground_pos - p.at).angle()
			var slot := _free_slot(crew)
			var spot := _patch_spot(p, slot, gap)
			if spot == Vector2.INF:
				continue
			c.beat(p)
			if c.mind != Person.Mind.ASSIST or c.assist_patch != p:
				continue  # refused (held by a will)
			c.assist_slot = slot
			crew.append(c)
			c.walk_to(spot)


## Whether the ground point `g` lies in any burning patch.
func _in_a_patch(g: Vector2) -> bool:
	for q in patches:
		if not q.out and q.over(g):
			return true
	return false


## The lowest ring slot no one on `crew` holds.
func _free_slot(crew: Array) -> int:
	for k in GroundFire.CREW:
		var taken := false
		for b: Person in crew:
			taken = taken or b.assist_slot == k
		if not taken:
			return k
	return crew.size() % GroundFire.CREW


## A walkable spot on the ring `gap` outside the patch's edge for crew slot `slot`: the angle is `base_angle` plus the slot's
## share of the circle, turned by an eighth up to eight times if the spot is bad (not walkable near the ring, or within
## radius + 0.2 of a burning patch). Vector2.INF when none is good: no goal is ever inside a patch.
func _patch_spot(p: GroundFire, slot: int, gap: float) -> Vector2:
	var base := p.base_angle + float(slot) * TAU / float(GroundFire.CREW)
	for turn in 8:
		var dir := Vector2.RIGHT.rotated(base + float(turn) * TAU / 8.0)
		var spot := _crowd._spot_near(p.at + dir * (p.radius + gap), 0.1)
		if spot.distance_to(p.at) > p.radius + gap + 0.3:
			continue
		var clear := true
		for q in patches:
			if not q.out and spot.distance_to(q.at) <= q.radius + 0.2:
				clear = false
		if clear:
			return spot
	return Vector2.INF


## A rescue squad's soldier (RescueManager, v0.07), or an engineer with nothing to mend (EngineerManager, v0.08.2),
## turns out to the fire on `s`: on its crew whatever the brigade's numbers. `stays` keeps it on through the
## evacuation, when the brigade and the squads stand down.
func enlist(p: Person, s: Structure, stays := false) -> void:
	if not fires.has(s) or not is_instance_valid(p) or not p.is_alive():
		return
	p.assist(s, true, stays)
	if p.mind != Person.Mind.ASSIST:
		return
	if not (fires[s].responders as Array).has(p):
		(fires[s].responders as Array).append(p)
	_go_to_water(p, s)


## Each responder's round: to the water, fill, to the fire, douse, again -- or stand down.
func _tend_responders(delta: float) -> void:
	var evacuating := _crowd.alarms.stage >= AlarmManager.Stage.EVACUATION
	for s: Structure in fires.keys():
		if not fires.has(s):
			continue
		for p in fires[s].responders.duplicate():
			if not is_instance_valid(p) or p.mind != Person.Mind.ASSIST or p.assist_fire != s:
				continue
			if (evacuating and not p.assist_stays) or float(fires[s].intensity) >= ABANDON or _crowd.structure_mark(s) == &"cursed":
				p.stand_down()
				continue
			if p.has_goal():
				continue
			p.assist_wait -= delta
			if p.assist_wait > 0.0:
				continue
			if p.assist_full:
				douse(s)
				p.assist_full = false
				if not fires.has(s):
					break
				_go_to_water(p, s)
			elif p.assist_at_water:
				p.assist_full = true
				p.assist_at_water = false
				p.assist_wait = ACT
				p.walk_to(_edge_of(s, p.ground_pos))
			else:
				_go_to_water(p, s)


## Each beater's round: walk to the ring, wait a step back while the patch is at full strength, then beat it, swinging
## every BEAT_SWING. Out of the crew when its mind changed; stood down for the evacuation.
func _tend_beaters(delta: float) -> void:
	var evacuating := _crowd.alarms.stage >= AlarmManager.Stage.EVACUATION
	# Walked by index, not over copies: nothing below adds or removes a patch, and a beater leaving its crew is removed in
	# place (the next one then takes its index).
	for pi in patches.size():
		var p: GroundFire = patches[pi]
		if p.out:
			continue
		var i := 0
		while i < p.crew.size():
			var b = p.crew[i]
			if not is_instance_valid(b) or not b.is_alive() or b.mind != Person.Mind.ASSIST or b.assist_patch != p:
				if is_instance_valid(b) and b.assist_patch == p:
					b.assist_patch = null  # frightened off, dead (or taken for another job): no longer on this patch
					b.assist_beating = false
				p.crew.remove_at(i)
				continue
			if evacuating and not b.assist_stays:
				b.stand_down()
				p.crew.remove_at(i)
				continue
			i += 1
			b.assist_respot_in = maxf(b.assist_respot_in - delta, 0.0)
			if b.has_goal():
				continue
			var slot: int = b.assist_slot
			if p.full():
				b.assist_beating = false
				# At the wait spot when it last walked to one and stands there.
				var waiting: bool = b.ground_pos.distance_to(b.anchor) <= Person.GOAL_REACH \
						and b.anchor.distance_to(p.at) > p.radius + GroundFire.BEAT_GAP + 0.3
				if not waiting and b.assist_respot_in <= 0.0:
					b.assist_respot_in = RESPOT
					var spot := _patch_spot(p, slot, GroundFire.WAIT_GAP)
					if spot == Vector2.INF:
						b.stand_down()
						p.crew.remove_at(i - 1)
						i -= 1
					else:
						b.walk_to(spot)
				continue
			if b.ground_pos.distance_to(p.at) > p.radius + GroundFire.BEAT_GAP + Person.GOAL_REACH:
				b.assist_beating = false
				if b.assist_respot_in <= 0.0:
					b.assist_respot_in = RESPOT
					var spot := _patch_spot(p, slot, GroundFire.BEAT_GAP)
					if spot == Vector2.INF:
						b.stand_down()
						p.crew.remove_at(i - 1)
						i -= 1
					else:
						b.walk_to(spot)
				continue
			b.assist_beating = true
			b._beat_in -= delta
			if b._beat_in <= 0.0:
				b._beat_in = GroundFire.BEAT_SWING
				b.swing_at(p.at)


func _go_to_water(p: Person, s: Structure) -> void:
	var w := nearest_water(s.center())
	if w == null:
		p.stand_down()
		return
	p.assist_at_water = true
	p.assist_wait = ACT
	var to := w.center() + (s.center() - w.center()).normalized() * (w.footprint.size.x * 0.5 + 0.4)
	p.walk_to(_crowd._spot_near(to, 0.3))


## A walkable spot at the edge of `s`, on the side facing `from`.
func _edge_of(s: Structure, from: Vector2) -> Vector2:
	var dir := (from - s.center()).normalized() if from.distance_to(s.center()) > 0.01 else Vector2.DOWN
	return _crowd._spot_near(s.center() + dir * (s.footprint.size.length() * 0.5 + 0.35), 0.3)


func clear() -> void:
	fires.clear()
	clear_patches()
