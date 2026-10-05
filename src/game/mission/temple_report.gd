class_name TempleReport
extends RefCounted
## A report of the god at work on its way to the Temple (v0.10): one of the Faithful runs (a duty) to the Temple's door,
## re-aimed every RETARGET; within REACH of it the report is delivered and the carrier goes back to their day. A carrier
## killed with nobody living near enough to see it (Crowd.DOOM_WITNESS) ends the report; a death that is seen passes
## it to the nearest witness, who runs on. Judged once a cast's other victims have fallen (Crowd._settle_doom()), as
## The Warning judges its messenger. A frightened, confused or whispered carrier drops the run and picks it up again
## once back on its feet; only a relay overrides a fright.

const REACH := 1.0
const RETARGET := 0.5
## Minds a carrier picks the run up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## Minds a relay leaves alone: the god's own hold wears off first.
const HELD := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]

var carrier: Person
var door := Vector2.INF
var delivered := false
## Ended by a death nobody saw.
var dead := false
var relays := 0
var _fell_at := Vector2.INF
var _retarget_in := 0.0


func _init(p: Person, temple_door: Vector2) -> void:
	carrier = p
	door = temple_door
	_send(true)


## Still on its way: neither delivered nor ended.
func is_open() -> bool:
	return not delivered and not dead


func step(delta: float, crowd: Crowd) -> void:
	if not is_open():
		return
	if _fell_at != Vector2.INF and crowd._doomed.is_empty():
		_judge(crowd)
		if not is_open():
			return
	if not _alive(carrier):
		return
	if carrier.ground_pos.distance_to(door) <= REACH:
		delivered = true
		if carrier.mind == Person.Mind.DUTY:
			carrier.leave_shelter(false)
		return
	_retarget_in -= delta
	if _retarget_in <= 0.0:
		_retarget_in = RETARGET
		_send(false)


func on_killed(e: DummyEnemy) -> void:
	if is_open() and e == carrier and _fell_at == Vector2.INF:
		_fell_at = e.ground_pos


func _judge(crowd: Crowd) -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	var witness := crowd.nearest_witness(at)
	if witness == null:
		dead = true
		return
	if witness != carrier:
		relays += 1
	carrier = witness
	_send(true)


## On the run: re-aimed only when it has stopped short. Off it: again once back on its feet, or at once for a relay
## unless the god holds the witness.
func _send(relay: bool) -> void:
	if not _alive(carrier):
		return
	if carrier.mind == Person.Mind.DUTY:
		if not carrier.has_goal() or carrier.anchor.distance_to(door) > 0.3:
			carrier.go_duty(door)
		return
	if carrier.mind in RESUMABLE or carrier.soldier or (relay and not carrier.mind in HELD):
		carrier.go_duty(door)


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
