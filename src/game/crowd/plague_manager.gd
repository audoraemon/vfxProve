class_name PlagueManager
extends RefCounted
## Pestilence (v0.06): the sick (Person.sick_left) die PLAGUE_LIFE after they caught it, and every SPREAD_EVERY seconds
## each one gives it to each healthy citizen within SPREAD_R with SPREAD_CHANCE -- so a packed gate queue, the dock's
## crowd or a full shelter spreads it fast -- up to PLAGUE_MAX sick at once. People sheltering together pass it on
## inside; one who dies in there is carried out first, to be seen. Soldiers do not catch it. A plague death is an
## ordinary death (damage kind plague): it counts, raises the alarm and is an incident.

const PLAGUE_LIFE := 30.0
const SPREAD_EVERY := 3.0
const SPREAD_R := 1.0
const SPREAD_CHANCE := 0.3
const PLAGUE_MAX := 60
## How often the town is searched for the newly sick (the effect's infections); the sick list itself is kept every frame.
const SCAN_EVERY := 0.5

var sick: Array[Person] = []
var deaths := 0
var _crowd: Crowd
var _field: EnemyField
var _rng := RandomNumberGenerator.new()
var _spread_in := SPREAD_EVERY
var _scan_in := 0.0


func setup(crowd: Crowd, field: EnemyField, seed_value: int) -> PlagueManager:
	_crowd = crowd
	_field = field
	_rng.seed = seed_value
	return self


func step(delta: float) -> void:
	_scan_in -= delta
	_collect(_scan_in <= 0.0)
	if _scan_in <= 0.0:
		_scan_in = SCAN_EVERY
	if sick.is_empty():
		_spread_in = SPREAD_EVERY
		return
	var dying: Array[Person] = []
	for p in sick:
		if _crowd.rescue != null and _crowd.rescue.holds(p):
			continue  # the sickness waits under the rubble (v0.07): it neither runs down nor is cured
		p.sick_left -= delta
		if p.sick_left <= 0.0:
			dying.append(p)
	for p in dying:
		sick.erase(p)
		p.sick_left = 0.0
		if p.inside and _crowd.shelters != null:
			_crowd.shelters.release(p)
		if p.inside:
			continue  # aboard a boat: it sails away with the others
		if _field.kill(p, &"plague"):
			deaths += 1
	_spread_in -= delta
	if _spread_in <= 0.0:
		_spread_in = SPREAD_EVERY
		_spread()


## The sick list: the dead, the freed and the escaped leave it; on a scan, the effect's newly infected join it.
func _collect(scan: bool) -> void:
	var kept: Array[Person] = []
	for p in sick:
		if is_instance_valid(p) and p.is_alive() and p.sick_left > 0.0:
			kept.append(p)
	sick = kept
	if not scan or sick.size() >= PLAGUE_MAX:
		return
	for p in _crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.sick_left > 0.0 and not sick.has(p):
			sick.append(p)


func _spread() -> void:
	var fresh: Array[Person] = []
	for p in sick:
		var near: Array = []
		if p.inside:
			if _crowd.shelters != null:
				near = _crowd.shelters.occupants_with(p)
		else:
			near = _field.in_radius(p.ground_pos, SPREAD_R)
		for e in near:
			if sick.size() + fresh.size() >= PLAGUE_MAX:
				break
			var q := e as Person
			if q != null and q != p and not q.soldier and q.is_alive() and q.sick_left <= 0.0 and not fresh.has(q) \
					and _rng.randf() < SPREAD_CHANCE:
				fresh.append(q)
	for q in fresh:
		q.infect(PLAGUE_LIFE)
		sick.append(q)


func clear() -> void:
	sick.clear()
	deaths = 0
	_spread_in = SPREAD_EVERY
	_scan_in = 0.0
