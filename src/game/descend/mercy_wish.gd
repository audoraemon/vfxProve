class_name MercyWish
extends Wish
## "Lead my brother out" (v0.11 M1, spec §5.3, Mercy): whisper the marked citizen to a way out and he escapes, granting the
## wish; him dying first fails it. A way out is one of the town's gates (exits()): the map's own exits lie past the river
## and the fields, beyond any whisper's reach.

## How near a gate a whispered brother must come.
const EXIT_REACH := 1.5

## The brother to be led out.
var target: Person
var _out := false


## The ways out: the active city's gates out of its walls (CityDef.gate_exits(); Aldermere: the Main Gate, the Side
## Gate and the postern).
static func exits() -> Array[Vector2]:
	return City.current().gate_exits()


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	# Two people or none: checked before either is taken, so a failed choose leaves nobody in `taken`.
	if Wish.lay(crowd, taken).size() < 2 or not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	return target != null


func people() -> Array[Person]:
	var out := super()
	if target != null:
		out.append(target)
	return out


## Whispered and at a gate: he escapes (Crowd.escape(), as a boat's passenger does; it counts as an escape).
func step(_rules: Rules, _delta: float) -> void:
	if _out or not MissionDirector._alive(target) or target.mind != Person.Mind.WHISPERED:
		return
	for e in exits():
		if target.ground_pos.distance_to(e) <= EXIT_REACH:
			_out = true
			_crowd._field.remove(target)
			_crowd.escape(target)
			return


func _act(_rules: Rules) -> Status:
	if _out:
		return Status.DONE
	return Status.PENDING if MissionDirector._alive(target) else Status.FAILED


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if not _out and MissionDirector._alive(target) and not target.inside:
		out.append(MapTag.person(target.ground_pos, COLOR, "BROTHER"))
	return out
