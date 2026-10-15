class_name MercyWish
extends Wish
## "Lead my brother out" (v0.11 M1, spec §5.3, Mercy): whisper the marked citizen to a way out and he escapes, granting the
## wish; him dying first fails it. A way out is one of the town's gates (exits()): the map's own exits lie past the river
## and the fields, beyond any whisper's reach.
## v0.11 M5 (mission spec §6): "count" -- how many of the wisher's household are to be led out (1, the default: Lead my brother out, as
## before); more (Lead my family out) are chosen as Show yourself to my family chooses (FamilyWish._household()), each tagged FAMILY and
## pointed at from the edge, granted when the last escapes and failed when one dies first. An escaped body is freed at once, so escapes
## are kept by instance id.

## How near a gate a whispered brother must come.
const EXIT_REACH := 1.5
## The household's tag (v0.11 M5).
const FAMILY_LABEL := "FAMILY"

## The brother to be led out.
var target: Person
var _out := false
## With "count" above 1 (v0.11 M5): the household to be led out (untyped: one may be freed), each one's instance id, and the ids of those
## who escaped.
var family := []
var _ids: Array[int] = []
var _escaped: Array[int] = []


## The ways out: the Main Gate, the Side Gate and the postern.
static func exits() -> Array[Vector2]:
	var out: Array[Vector2] = [TownLayout.MAIN_GATE.get_center(), TownLayout.SIDE_GATE.get_center(), TownLayout.POSTERN_AT]
	return out


## How many are to be led out (v0.11 M5): "count", 1 by default.
func count() -> int:
	return int(def.params.get("count", 1)) if def != null else 1


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	if count() > 1:
		return _choose_family(crowd, rng, taken)
	# Two people or none: checked before either is taken, so a failed choose leaves nobody in `taken`.
	if Wish.lay(crowd, taken).size() < 2 or not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	return target != null


## The wisher and count() of his household (v0.11 M5): as Show yourself to my family chooses, from a random start; false when no household
## is big enough.
func _choose_family(crowd: Crowd, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var pool := Wish.lay(crowd, taken)
	if pool.is_empty():
		return false
	var start := rng.randi_range(0, pool.size() - 1)
	for k in pool.size():
		var w := pool[(start + k) % pool.size()]
		var near := FamilyWish._household(w, pool)
		if near.size() >= count():
			wisher = w
			for p in near.slice(0, count()):
				family.append(p)
				_ids.append(p.get_instance_id())
			taken.append(wisher)
			taken.append_array(family)
			return true
	return false


func people() -> Array[Person]:
	var out := super()
	if target != null:
		out.append(target)
	for v: Variant in family:
		if is_instance_valid(v):
			out.append(v as Person)
	return out


## `p` stands within EXIT_REACH of a way out (v0.11 M5, the old step's test).
static func _at_exit(p: Person) -> bool:
	for e in exits():
		if p.ground_pos.distance_to(e) <= EXIT_REACH:
			return true
	return false


## Whispered and at a gate: he escapes (Crowd.escape(), as a boat's passenger does; it counts as an escape). v0.11 M5: each of the family
## the same way.
func step(_rules: Rules, _delta: float) -> void:
	if count() > 1:
		for k in family.size():
			var v: Variant = family[k]
			if _escaped.has(_ids[k]) or not MissionDirector._alive(v) or (v as Person).mind != Person.Mind.WHISPERED:
				continue
			if _at_exit(v as Person):
				_escaped.append(_ids[k])
				_crowd._field.remove(v as Person)
				_crowd.escape(v as Person)
		return
	if _out or not MissionDirector._alive(target) or target.mind != Person.Mind.WHISPERED:
		return
	if _at_exit(target):
		_out = true
		_crowd._field.remove(target)
		_crowd.escape(target)


func _act(_rules: Rules) -> Status:
	if count() > 1:
		if _escaped.size() >= family.size():
			return Status.DONE
		for k in family.size():
			if not _escaped.has(_ids[k]) and not MissionDirector._alive(family[k]):
				return Status.FAILED
		return Status.PENDING
	if _out:
		return Status.DONE
	return Status.PENDING if MissionDirector._alive(target) else Status.FAILED


## "Lead my family out (+15) 1 / 3" (v0.11 M5); the brother's as before.
func hud_text(rules: Rules) -> String:
	if count() > 1:
		return "%s (+%d) %d / %d" % [def.text, reward, _escaped.size(), family.size()]
	return super(rules)


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if count() > 1:
		for k in family.size():
			var v: Variant = family[k]
			if not _escaped.has(_ids[k]) and MissionDirector._alive(v) and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, COLOR, FAMILY_LABEL, true))
		return out
	if not _out and MissionDirector._alive(target) and not target.inside:
		out.append(MapTag.person(target.ground_pos, COLOR, "BROTHER"))
	return out
