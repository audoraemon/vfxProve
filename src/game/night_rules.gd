class_name NightRules
extends RefCounted
## Endless Night's look and what a NIGHT costs the town. Every Endless Night mission is rolled DAY or NIGHT (GodNight.look_for()); only
## NIGHT (never CURRENT, never DAY) applies these: people see less far (Crowd.sight_scale), some of the ordinary citizens stay indoors for
## the whole mission, and the rest walk less (RoutineManager.night). Hearing is untouched. Every constant of the rules lives here.

## Sight at NIGHT as a share of the day's (Crowd.sight_scale).
const NIGHT_SIGHT := 0.6
## The share of the eligible citizens kept indoors all mission.
const NIGHT_INDOORS := 0.4
## The routine's night: the home weight is this many times, and a stay at home this many times as long.
const HOME_WEIGHT_X := 2.0
const HOME_STAY_X := 1.5
## A stay this long marks a person a director holds in place (MissionDirector._set_down()).
const HOLD_STAY := 999.0


static func is_night(look: int) -> bool:
	return look == Town.Look.NIGHT


## Crowd.sight_scale for a look.
static func sight_scale(look: int) -> float:
	return NIGHT_SIGHT if is_night(look) else 1.0


## `p` may be sent indoors for the night: an ordinary citizen, standing calm and unoccupied, with no faith, no role a mission or the town
## gives (Wish.NOT_LAY: clergy, engineers, the bellkeeper, the watchman, the mayor, the prince, monks), no charge or duty, not in the
## director's `reserved` nor a wish's people, not one the director calls busy, not one held in place (stay_left at HOLD_STAY or more: the
## `_set_down` / festival / procession marker, as the Spoiled Harvest's granary watchmen). When unsure, not eligible.
static func eligible(p: Variant, reserved: Array, director: MissionDirector = null) -> bool:
	if not is_instance_valid(p):
		return false
	var c := p as Person
	return c.is_alive() and not c.soldier and not c.inside and c.profile != null and c.mind == Person.Mind.CALM \
		and c.corps == Person.Corps.NONE and c.profile.faith == CitizenProfile.Faith.NONE \
		and not c.profile.role in Wish.NOT_LAY and not c.answers_lure and not c.engineer_duty and not c.chained \
		and not c.has_goal() and c.statuses.is_empty() and not reserved.has(c) \
		and c.stay_left < HOLD_STAY and not (director != null and director.busy(c))


## The citizens kept indoors: NIGHT_INDOORS of the eligible ones, chosen by a generator of its own seeded from `seed_value` (never the crowd's).
static func pick_indoors(crowd: Crowd, reserved: Array, seed_value: int, director: MissionDirector = null) -> Array[Person]:
	var pool: Array[Person] = []
	for p in crowd.citizens:
		if eligible(p, reserved, director):
			pool.append(p)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "indoors"])
	for i in range(pool.size() - 1, 0, -1):  # Fisher-Yates
		var j := rng.randi_range(0, i)
		var t := pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var out: Array[Person] = []
	out.assign(pool.slice(0, roundi(float(pool.size()) * NIGHT_INDOORS)))
	return out


## Sets the night on `crowd` for `look`: sight, the routine's flag and the people indoors (hidden, out of the field, never stepped, never
## coming out; still in `citizens`, so alive for every count). Call after the directors' setup, so the named people are already appointed.
## Nothing at all for a look that is not NIGHT. Returns how many went indoors.
static func apply(crowd: Crowd, look: int, reserved: Array, seed_value: int, director: MissionDirector = null) -> int:
	crowd.sight_scale = sight_scale(look)
	if not is_night(look):
		return 0
	if crowd.routine != null:
		crowd.routine.night = true
	var inside := pick_indoors(crowd, reserved, seed_value, director)
	for p in inside:
		p.inside = true
		p.night_indoors = true
		p.visible = false
		crowd._field.remove(p)
	return inside.size()
