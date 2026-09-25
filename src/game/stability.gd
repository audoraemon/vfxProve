class_name Stability
extends RefCounted
## City Stability (spec §4.3): five parts, each falling linearly from 1 (untouched) to 0 (broken), weighted
## 30 / 25 / 20 / 15 / 10. Every part breaks well before its last target is gone, so the player never has to
## hunt one surviving farmer. Pure measurement: it reads the town, the crowd and the Citadel and keeps no
## history of its own.

const W_POPULATION := 0.30
const W_INFRASTRUCTURE := 0.25
const W_LEADERSHIP := 0.20
const W_MILITARY := 0.15
const W_RESOURCES := 0.10

## Population breaks when this fraction of the citizens are dead or escaped.
const POPULATION_BROKEN := 0.75
## Infrastructure breaks when this fraction of the town's footprint is rubble.
const INFRASTRUCTURE_BROKEN := 0.70
## The soldier share of Military breaks at this fraction dead.
const SOLDIERS_BROKEN := 0.80
## Resources break when this fraction of the market stalls and farm fields are destroyed.
const RESOURCES_BROKEN := 0.80
## Military is two thirds soldiers, one third the Barracks.
const MILITARY_SOLDIER_SHARE := 2.0 / 3.0

## The roles Infrastructure measures, by footprint (spec §4.3: houses, walls, towers, gates, the Bridge, the
## Temple). The Citadel is Leadership's business, and decor (trees, torch posts) is nobody's.
const INFRA_ROLES := [&"house", &"wall", &"tower", &"gate", &"bridge", &"temple"]
## The roles Resources measures, counted per building: a stall and a field weigh the same.
const RESOURCE_ROLES := [&"market", &"farm"]

var population := 1.0
var infrastructure := 1.0
var leadership := 1.0
var military := 1.0
var resources := 1.0

## Footprint area and building counts of the town as it was built, so each part measures against the whole
## city and not against whatever is left of it.
var _infra_area := 0.0
var _resource_count := 0
var _barracks_count := 0


## Take the totals from the standing town. Call once, after Town.build().
func setup(env: EnvironmentField) -> Stability:
	_infra_area = 0.0
	_resource_count = 0
	_barracks_count = 0
	for s in env.structures():
		if INFRA_ROLES.has(s.role):
			_infra_area += s.footprint.get_area()
		elif RESOURCE_ROLES.has(s.role):
			_resource_count += 1
		elif s.role == &"barracks":
			_barracks_count += 1
	return self


## Recompute the five parts. Cheap enough for a few times a second, not for every frame of every effect:
## Rules calls it once a frame at most, and only when something it measures has changed.
func measure(env: EnvironmentField, crowd: Crowd, citadel: Citadel) -> void:
	var lost_citizens := crowd.killed_citizens + crowd.escaped_count
	population = _part(float(lost_citizens), float(crowd.spawned_citizens) * POPULATION_BROKEN)

	var razed := 0.0
	var resources_down := 0
	var barracks_down := 0
	for s in env.structures():
		if not s.destroyed:
			continue
		if INFRA_ROLES.has(s.role):
			razed += s.footprint.get_area()
		elif RESOURCE_ROLES.has(s.role):
			resources_down += 1
		elif s.role == &"barracks":
			barracks_down += 1
	infrastructure = _part(razed, _infra_area * INFRASTRUCTURE_BROKEN)
	resources = _part(float(resources_down), float(_resource_count) * RESOURCES_BROKEN)

	leadership = citadel.fraction() if is_instance_valid(citadel) else 0.0

	var soldiers := _part(float(crowd.killed_soldiers), float(crowd.spawned_soldiers) * SOLDIERS_BROKEN)
	var barracks := 1.0
	if _barracks_count > 0:
		barracks = _part(float(barracks_down), float(_barracks_count))
	military = soldiers * MILITARY_SOLDIER_SHARE + barracks * (1.0 - MILITARY_SOLDIER_SHARE)


## The weighted total, 1 (untouched) down to 0 (fallen).
func total() -> float:
	return population * W_POPULATION + infrastructure * W_INFRASTRUCTURE + leadership * W_LEADERSHIP \
		+ military * W_MILITARY + resources * W_RESOURCES


func is_broken() -> bool:
	return total() <= 0.0


## One part: `lost` of `broken_at` gone, as a health from 1 down to 0. A city with none of something (no farms
## at all) counts that part as whole rather than as already broken.
func _part(lost: float, broken_at: float) -> float:
	if broken_at <= 0.0:
		return 1.0
	return clampf(1.0 - lost / broken_at, 0.0, 1.0)
