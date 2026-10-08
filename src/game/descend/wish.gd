class_name Wish
extends Objective
## A wish heard at a board night's descent (v0.11 M1, spec §5), run as an Objective: check() is where it stands -- PENDING,
## DONE (granted) or FAILED -- and it stays where it ends. Each has a wisher, a real citizen tagged WISH; the wisher dying
## before it is granted fails it ("Their prayer goes unanswered"). Granted, the wisher becomes a Believer. A kind's script
## chooses its targets (choose()), watches them (step(), on_cast()) and judges its act (_act()).

## The wishes' colour on the map and the HUD (spec §5.1): soft blue.
const COLOR := Color("8fb8ff")
## The wisher's tag.
const WISHER_LABEL := "WISH"
## A failed wish's words (spec §5.1).
const UNANSWERED := "Their prayer goes unanswered"
## Roles a wisher or a target never has: the town's responders and the directors' own people.
const NOT_LAY := [CitizenProfile.Role.CLERGY, CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER,
	CitizenProfile.Role.WATCHMAN, CitizenProfile.Role.MAYOR, CitizenProfile.Role.NOBLE]

var def: WishDef
## The believers it pays, at the night's multiplier (Descent.hear()).
var reward := 0
var wisher: Person
## Where it ended: PENDING while open.
var status := Status.PENDING
var _crowd: Crowd


## "open", "granted" or "failed", for the HUD and the results.
static func state_name(s: Status) -> String:
	match s:
		Status.DONE:
			return "granted"
		Status.FAILED:
			return "failed"
	return "open"


## Virtual: chooses the wisher and the targets from the town (spec §5.1), none of them in `taken` (each added to it); false
## when the town cannot give them, and the wish is not heard. The base takes a wisher among the lay citizens.
func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	wisher = pick_lay(crowd, rng, taken)
	return wisher != null


## Everyone the wish sets aside (v0.11 M1): its wisher, and its kind's people (PunishWish adds its target). The Descent
## reserves them on the director.
func people() -> Array[Person]:
	var out: Array[Person] = []
	if wisher != null:
		out.append(wisher)
	return out


## Virtual: one frame of the night, while the wish is open.
func step(_rules: Rules, _delta: float) -> void:
	pass


## Virtual: a power was cast at `at` (Descent passes Rules.cast_made on).
func on_cast(_key: String, _at: Vector2) -> void:
	pass


## Virtual: where the wish's own act stands, the wisher aside.
func _act(_rules: Rules) -> Status:
	return Status.PENDING


## Where the wish stands (spec §5.2): granted the moment its act is done; failed when its act fails or its wisher dies
## first. Once ended, it stays ended.
func check(rules: Rules) -> Status:
	if status != Status.PENDING:
		return status
	var s := _act(rules)
	if s == Status.PENDING and not MissionDirector._alive(wisher):
		s = Status.FAILED
	status = s
	return status


## Granted (spec §5.2): the wisher believes.
func grant() -> void:
	if MissionDirector._alive(wisher) and wisher.profile != null:
		wisher.profile.faith = CitizenProfile.Faith.BELIEVER


## "Burn the moneylender's house (+10)".
func hud_text(_rules: Rules) -> String:
	return "%s (+%d)" % [def.text, reward]


## The map's tags while open (spec §5.1-§5.2): the act's targets first, then the wisher, WISH.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if status != Status.PENDING:
		return out
	out.append_array(_target_tags())
	if MissionDirector._alive(wisher) and not wisher.inside:
		out.append(MapTag.person(wisher.ground_pos, COLOR, WISHER_LABEL))
	return out


## Virtual: the act's targets' tags.
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	return out


## Virtual: a timed wish (spec §5.2: the Rescue kind) waits for the player to engage it.
func timed() -> bool:
	return false


## Virtual: open and not yet engaged (a timed wish); its tag answers a click.
func waiting() -> bool:
	return false


## Virtual: the player engages it; true when it was waiting and now runs.
func engage() -> bool:
	return false


## Virtual: lets go of the world's signals.
func release() -> void:
	pass


## A lay citizen at random for a wisher or a target, added to `taken`; null when there is none.
static func pick_lay(crowd: Crowd, rng: RandomNumberGenerator, taken: Array) -> Person:
	var pool := lay(crowd, taken)
	if pool.is_empty():
		return null
	var p := pool[rng.randi_range(0, pool.size() - 1)]
	taken.append(p)
	return p


## The lay citizens not in `taken`, in the crowd's order: alive, out of doors, of no faith, of no role in NOT_LAY.
static func lay(crowd: Crowd, taken: Array) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and p.profile != null and not p.profile.role in NOT_LAY \
				and p.profile.faith == CitizenProfile.Faith.NONE and not taken.has(p):
			out.append(p)
	return out
