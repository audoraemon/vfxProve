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

## Structure -> {intensity, renew_in, responders: Array[Person]}
var fires := {}
var _crowd: Crowd
var _env: EnvironmentField
var _rng := RandomNumberGenerator.new()
var _step_in := 0.0
var _recruit_in := 0.0
## True while the fire deals its own damage, so that damage never re-ignites anything.
var _burning_now := false


func setup(crowd: Crowd, env: EnvironmentField, seed_value: int) -> FireManager:
	_crowd = crowd
	_env = env
	_rng.seed = seed_value
	env.structure_hit.connect(_on_hit)
	return self


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
	if not is_instance_valid(s) or s.destroyed or not s.kind in BURNABLE:
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
	_recruit_in -= delta
	if _recruit_in <= 0.0:
		_recruit_in = 1.0
		_recruit()
	_tend_responders(delta)


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
				if n != s and n.kind in BURNABLE and not n.destroyed and not fires.has(n) \
						and n.distance_to(s.center()) <= SPREAD_REACH:
					catching.append(n)
					break
	for n in catching:
		ignite(n, START)


func _windy(g: Vector2) -> bool:
	for t in _crowd.threats.nearby(g, WIND_REACH):
		if t.kind == &"tornado":
			return true
	return false


## The fire on `s` is over (doused, or its building fell): its responders go back to their day.
func _put_out(s: Structure, doused: bool) -> void:
	if not fires.has(s):
		return
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


func nearest_water(g: Vector2) -> Structure:
	var best: Structure = null
	for w in water_points():
		if best == null or w.center().distance_to(g) < best.center().distance_to(g):
			best = w
	return best


func _recruit() -> void:
	# The brigade turns out from the profile's stage (ResponseProfile.fire_from), until the town evacuates.
	var stage := _crowd.alarms.stage
	if stage >= AlarmManager.Stage.EVACUATION or stage < _crowd.profile.fire_from or fires.is_empty():
		return
	var most := _crowd.profile.fire_crew
	for s: Structure in fires.keys():
		var f: Dictionary = fires[s]
		var crew: Array = f.responders.filter(func(p) -> bool:
			return is_instance_valid(p) and p.mind == Person.Mind.ASSIST and p.assist_fire == s)
		f.responders = crew
		if crew.size() >= most or float(f.intensity) >= ABANDON or nearest_water(s.center()) == null:
			continue
		var pool: Array[Person] = []
		for p in _crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and p.profile != null \
					and (p.mind == Person.Mind.CALM or p.mind == Person.Mind.RECOVER) \
					and p.ground_pos.distance_to(s.center()) <= RECRUIT_REACH:
				pool.append(p)
		pool.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_to(s.center()) < b.ground_pos.distance_to(s.center()))
		for k in mini(most - crew.size(), pool.size()):
			pool[k].assist(s)
			crew.append(pool[k])
			_go_to_water(pool[k], s)


## A rescue squad's soldier turns out to the fire on `s` (RescueManager, v0.07): on its crew whatever the brigade's
## numbers.
func enlist(p: Person, s: Structure) -> void:
	if not fires.has(s) or not is_instance_valid(p) or not p.is_alive():
		return
	p.assist(s, true)
	if p.mind != Person.Mind.ASSIST:
		return
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
			if evacuating or float(fires[s].intensity) >= ABANDON:
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
