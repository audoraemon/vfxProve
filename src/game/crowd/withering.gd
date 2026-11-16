class_name Withering
extends RefCounted
## The withering (Death's second review, R36): a reusable status any power may lay (Gate Below's wraiths first). Laid on a
## person (lay(); Crowd.wither()) for WITHER seconds, he is drawn grey (Person.withered(), TINT), keeps WITHER_PACE of his
## pace (Person.hold_pace() under this Withering's id) and panics from where it came. When the time is up, alive and out in
## the open, he dies where he stands as KIND -- a body (Remains.BODY_KINDS) and a death the town hears, as any seen death.
## Indoors at the end, dead of something else first, or freed (carried off): it lapses and every hold it laid is freed
## (Death Mark's rule). Laid on one already withering, nothing new runs: the first runs on. p.statuses[KIND] holds the
## seconds left. The Crowd owns one and steps it every frame after the remains (Crowd._advance()); it draws no number from
## any rng, so nothing else in the town moves for it.

const WITHER := 6.0
const WITHER_PACE := 0.5
const TINT := Color(0.62, 0.64, 0.66)
const KIND := &"wither"
## He panics from where it came, a danger this wide.
const FRIGHT_R := 2.0

var _field: EnemyField
## Untyped: one of them may be freed (carried off) before his time is up, and a freed node errors in a typed slot.
var _on: Array = []


func _init(field: EnemyField = null) -> void:
	_field = field


## Lays the withering on `p` for `seconds`, from `from`: false (and nothing laid) when he is gone, dead, inside, or
## withering already.
func lay(p: Person, seconds: float, from: Vector2) -> bool:
	if p == null or not is_instance_valid(p) or not p.is_alive() or p.inside or p.withered() or seconds <= 0.0:
		return false
	p.statuses[KIND] = seconds
	p.hold_pace(get_instance_id(), WITHER_PACE)
	p.panic(from, FRIGHT_R, KIND)
	_on.append(p)
	return true


## Counts every withering down; one whose time is up kills (out in the open) or lapses (indoors); one whose person died
## of something else, or was freed, lapses at once.
func step(delta: float) -> void:
	if _on.is_empty():
		return
	var keep: Array = []
	for p in _on:
		if not is_instance_valid(p):
			continue  # carried off and freed: nothing of his is left to free
		if not p.is_alive() or not p.statuses.has(KIND):
			_lapse(p)
			continue
		var left := float(p.statuses[KIND]) - delta
		if left > 0.0:
			p.statuses[KIND] = left
			keep.append(p)
			continue
		_lapse(p)
		if not p.inside and _field != null:
			_field.kill(p, KIND, p.ground_pos)
	_on = keep


## Every withering lapses at once (the town's end): the holds are freed, nobody dies of it.
func clear() -> void:
	for p in _on:
		if is_instance_valid(p):
			_lapse(p)
	_on.clear()


## How many are withering now.
func count() -> int:
	var n := 0
	for p in _on:
		if is_instance_valid(p) and p.is_alive():
			n += 1
	return n


func _lapse(p: Person) -> void:
	p.statuses.erase(KIND)
	p.free_pace(get_instance_id())
