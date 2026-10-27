class_name TempleReport
extends RefCounted
## A report of the god at work on its way to the Temple (v0.10): one of the Faithful runs (a duty) to the Temple's door,
## re-aimed every RETARGET; within REACH of it the report is delivered and the carrier goes back to their day. A carrier
## killed with nobody living near enough to see it (Crowd.DOOM_WITNESS) ends the report; a death that is seen passes
## it to the nearest witness, who runs on. Judged once a cast's other victims have fallen (Crowd._settle_doom()), as
## The Warning judges its messenger. A frightened, confused or whispered carrier drops the run and picks it up again
## once back on its feet; only a relay overrides a fright.
##
## v0.11.2 (the Herald, spec 4.6): `slow` is the share of its pace a carrier keeps (LanternWatch.HERALD_SLOW) and `descend` the seconds the
## first carrier stands still before he is sent (he is coming down the bell tower); a relay's new carrier is sent at once. Both default
## to the report's old ways (full pace, sent at once), so no other mission changes.

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
## Called off by drop() (god T1R): undelivered, the carrier let go.
var dropped := false
var relays := 0
## func(p: Person) -> bool (v0.11 M5): a witness a relay passes over -- The Sermon's and The Relic Run's: one fleeing the town or
## reserved. Empty: any witness carries it on, as before.
var skip: Callable
## The share of the carrier's pace kept on the run (1.0: all of it).
var slow := 1.0
## Seconds the first carrier is held before he is sent (0: sent at once).
var descend := 0.0
var _fell_at := Vector2.INF
var _retarget_in := 0.0
var _descend_left := 0.0


func _init(p: Person, temple_door: Vector2, slow_pace := 1.0, descend_seconds := 0.0) -> void:
	carrier = p
	door = temple_door
	slow = slow_pace
	descend = descend_seconds
	_descend_left = descend_seconds
	if _descend_left <= 0.0:
		_send(true)


## Still on its way: neither delivered nor ended.
func is_open() -> bool:
	return not delivered and not dead and not dropped


## The report is called off, undelivered (god T1R, First Prayers' ALL IS WELL): the carrier goes back to his day, and nothing reaches the
## Temple. Nothing else calls it.
func drop() -> void:
	if not is_open():
		return
	dropped = true
	_fell_at = Vector2.INF
	if _alive(carrier):
		if carrier.mind == Person.Mind.DUTY:
			carrier.leave_shelter(false)
		unslow()


func step(delta: float, crowd: Crowd) -> void:
	if not is_open():
		return
	if _fell_at != Vector2.INF and crowd._doomed.is_empty():
		_judge(crowd)
		if not is_open():
			return
	if not _alive(carrier):
		return
	if _descend_left > 0.0:
		_descend_left -= delta
		if _descend_left > 0.0:
			hold(carrier)  # still coming down the tower: stands where he is
			return
		_retarget_in = RETARGET
		_send(false)  # the first carrier is sent in the normal form: a fright he came down the tower in is respected (v0.11.2 review)
		return
	if carrier.ground_pos.distance_to(door) <= REACH:
		delivered = true
		if carrier.mind == Person.Mind.DUTY:
			carrier.leave_shelter(false)
		unslow()
		return
	_retarget_in -= delta
	if _retarget_in <= 0.0:
		_retarget_in = RETARGET
		_send(false)


## Seconds the first carrier is still held (0 once he walks, and for a relay).
func descend_left() -> float:
	return maxf(_descend_left, 0.0)


## The carrier left the town (or was freed) with no fall to judge: nothing is left to stop, so the report is over. Only reads.
func gone() -> bool:
	return is_open() and _fell_at == Vector2.INF and not is_instance_valid(carrier)


## Real seconds `p` still needs to walk to `to` at the Herald's pace: along the rest of his path when he has one, else straight.
## `slow` is the share of his pace kept. Only reads.
static func walk_seconds(who: Variant, to: Vector2, slow_pace := 1.0) -> float:
	if not is_instance_valid(who):
		return 0.0
	var p := who as Person
	var at := p.ground_pos
	var d := 0.0
	if not p._path.is_empty() and p._goal != Vector2.INF:
		if p._leg > 0 and p._target != Vector2.INF:
			d += at.distance_to(p._target)
			at = p._target
		for i in range(p._leg, p._path.size()):
			d += at.distance_to(p._path[i])
			at = p._path[i]
	d += at.distance_to(to)
	return d / maxf(Person.PANIC_SPEED * p.pace * slow_pace, 0.05)


## `who` stands where he is for the next moment (called every frame while a Herald comes down the tower): his idle pause, which the base
## walk honours on every frame, not only on the frames he thinks.
static func hold(who: Variant) -> void:
	if is_instance_valid(who):
		(who as Person)._idle = maxf((who as Person)._idle, 0.2)


## The carrier's slowing and duty are undone (the report ends: delivered, or the act does).
func unslow() -> void:
	if slow < 1.0 and is_instance_valid(carrier):
		carrier.statuses.erase(&"slow")


func on_killed(e: DummyEnemy) -> void:
	if is_open() and e == carrier and _fell_at == Vector2.INF:
		_fell_at = e.ground_pos


func _judge(crowd: Crowd) -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	var witness := crowd.nearest_witness(at) if not skip.is_valid() else _witness(crowd, at)
	if witness == null:
		dead = true
		return
	if witness != carrier:
		relays += 1
	carrier = witness
	_descend_left = 0.0  # a relay is sent at once, wherever the first carrier was
	_send(true)


## The nearest witness to `at` a relay may take (v0.11 M5): as Crowd.nearest_witness() finds one, passing over everyone `skip` names;
## null for none, and the report ends. A copy of that search: a change to the rule there belongs here too.
func _witness(crowd: Crowd, at: Vector2) -> Person:
	var best: Person = null
	var best_d := Crowd.DOOM_WITNESS
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside or bool(skip.call(p)):
				continue
			var d := p.ground_pos.distance_to(at)
			if d <= best_d:
				best = p
				best_d = d
	return best


## On the run: re-aimed only when it has stopped short. Off it: again once back on its feet, or at once for a relay
## unless the god holds the witness.
func _send(relay: bool) -> void:
	if not _alive(carrier):
		return
	if carrier.mind == Person.Mind.DUTY:
		_slow_down()
		if not carrier.has_goal() or carrier.anchor.distance_to(door) > 0.3:
			carrier.go_duty(door)
		return
	if carrier.soldier and carrier.held_by_god():
		return  # whispered, confused or lured off (v0.11.1): the hold ends by itself, and the errand is given again then
	if carrier.mind in RESUMABLE or carrier.soldier or (relay and not carrier.mind in HELD):
		_slow_down()
		carrier.go_duty(door)
	elif slow < 1.0 and is_equal_approx(float(carrier.statuses.get(&"slow", 1.0)), slow):
		carrier.statuses.erase(&"slow")  # frightened (PANIC, FLEE, ...): he runs at his own pace until he is back on his feet (v0.11.2 review)


## The Herald's pace, written just before he is given the Temple's door: the pace go_duty() reads. A frightened carrier is not given it.
func _slow_down() -> void:
	if slow < 1.0:
		carrier.statuses[&"slow"] = slow


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
