class_name FrightWish
extends Wish
## "Scare off the bully, unharmed" (v0.11 M3, mission spec §5, Fright): frighten the marked citizen -- he panics or runs for shelter
## (the Festival's broken minds, FestivalDirector.BROKE_MINDS) while he lives and is unhurt -- and it is granted. The town's own
## flight (FLEE, its evacuation) is not a fright. "Unharmed" is unhurt: a bully struck at all (his health below a citizen's full,
## Person.HEALTH_CITIZEN -- the frenzy powers panic him as they hit) fails it. His death first, or his leaving the town, fails it
## too; so does the wisher's death (Wish).

## The target's tag (v0.11 M3).
const LABEL := "BULLY"

## The bully (v0.11 M3).
var target: Person


## A lay wisher and a lay bully, two people or none (v0.11 M3): checked before either is taken, so a failed choose takes nobody.
func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	if Wish.lay(crowd, taken).size() < 2 or not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	return true


## The wisher and the bully, while his body is there (v0.11 M3).
func people() -> Array[Person]:
	var out := super()
	var v: Variant = target
	if is_instance_valid(v):
		out.append(v as Person)
	return out


## Granted the moment he is frightened while he lives unhurt; failed once he is dead, gone or hurt -- judged before his mind, so a
## blow that panics him fails it rather than grants it (v0.11 M3).
func _act(_rules: Rules) -> Status:
	if not MissionDirector._alive(target) or target.health < Person.HEALTH_CITIZEN:
		return Status.FAILED
	return Status.DONE if target.mind in FestivalDirector.BROKE_MINDS else Status.PENDING


## BULLY on him while he is out of doors, pointed at from the edge: he walks the town, and the player must find him (v0.11 M3).
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if MissionDirector._alive(target) and not target.inside:
		out.append(MapTag.person(target.ground_pos, COLOR, LABEL, true))
	return out
