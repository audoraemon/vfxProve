class_name BellNetwork
extends RefCounted
## The Bell Tower (v0.05): how a local disaster becomes the whole town's. At the first Local Emergency the bellkeeper
## goes to the tower and climbs it -- CLIMB seconds, with a progress bar over the tower -- and rings the bell: the
## alarm jumps RING_ALARM, every citizen learns of the danger, and the town reaches City Emergency and Evacuation
## sooner (AlarmManager). A frightened bellkeeper abandons the climb and tries again RETRY seconds later; a dead one
## is not replaced; a fallen tower rings no more. An Unprepared town (ResponseProfile.bell off) has no bellkeeper.

signal climbing_started
signal rung
signal silenced(reason: String)

enum State { IDLE, CALLED, CLIMBING, WAITING, RUNG, SILENCED }

const RING_ALARM := 20.0
const RETRY := 10.0
const FOOT_REACH := 0.8

var state := State.IDLE
var progress := 0.0
var climb := 8.0
var tower: Structure
var keeper: Person
var foot := Vector2.INF
var _crowd: Crowd
var _retry_in := 0.0
## Seconds left showing the ring's waves over the tower.
var ring_show := 0.0


func setup(crowd: Crowd, env: EnvironmentField, keeper_person: Person, foot_point: Vector2) -> BellNetwork:
	_crowd = crowd
	climb = crowd.profile.bell_climb
	keeper = keeper_person
	foot = foot_point
	for s in env.structures():
		if s.art_tag == &"bell_tower":
			tower = s
			break
	if not crowd.profile.bell or tower == null or keeper == null:
		state = State.SILENCED
	return self


## The first Local Emergency: send the bellkeeper.
func call_keeper() -> void:
	if state != State.IDLE:
		return
	if not _keeper_ok():
		state = State.CALLED
		_silence("the bellkeeper is dead")
		return
	_send()


func _send() -> void:
	if not _keeper_ok():
		return
	keeper.go_ring(foot)
	state = State.CALLED


func _keeper_ok() -> bool:
	return is_instance_valid(keeper) and keeper.is_alive()


func step(delta: float) -> void:
	ring_show = maxf(ring_show - delta, 0.0)
	if state == State.RUNG or state == State.SILENCED or state == State.IDLE:
		return
	if not is_instance_valid(tower) or tower.destroyed:
		_silence("the tower has fallen")
		return
	if tower.blighted:
		_silence("the bell is cracked")
		return
	if not _keeper_ok():
		_silence("the bellkeeper is dead")
		return
	match state:
		State.CALLED:
			if keeper.mind != Person.Mind.DUTY:
				_wait()
			elif not keeper.has_goal() and keeper.ground_pos.distance_to(foot) <= FOOT_REACH:
				state = State.CLIMBING
				progress = 0.0
				climbing_started.emit()
			elif not keeper.has_goal():
				keeper.go_ring(foot)
		State.CLIMBING:
			if keeper.mind != Person.Mind.DUTY:
				progress = 0.0
				_wait()
				return
			progress += delta
			if progress >= climb:
				_ring()
		State.WAITING:
			_retry_in -= delta
			if _retry_in <= 0.0 and keeper.mind in [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE,
					Person.Mind.REGROUP]:
				_send()


func _wait() -> void:
	state = State.WAITING
	_retry_in = RETRY


func _ring() -> void:
	state = State.RUNG
	ring_show = 3.0
	_crowd.off_duty(keeper)
	_crowd.ring_bell(tower.center())
	_crowd.add_alarm(RING_ALARM)
	rung.emit()


func _silence(reason: String) -> void:
	var was_called := state != State.IDLE
	state = State.SILENCED
	progress = 0.0
	if was_called:
		silenced.emit(reason)


## Draws the climb's progress bar over the tower, and the ring's waves, into `ci` (world space).
func draw(ci: CanvasItem) -> void:
	if not is_instance_valid(tower):
		return
	var top := Iso.ground_to_screen(tower.center()) + Vector2(0, -tower.height - 44.0)
	if state == State.CLIMBING:
		var w := 28.0
		var r := Rect2(top - Vector2(w * 0.5, 0), Vector2(w, 4))
		ci.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.75))
		ci.draw_rect(Rect2(r.position, Vector2(w * clampf(progress / climb, 0.0, 1.0), 4)), UiTheme.COL_GOLD)
	if ring_show > 0.0:
		var k := 1.0 - ring_show / 3.0
		for i in 3:
			var rad := 8.0 + fmod(k * 3.0 + float(i) / 3.0, 1.0) * 40.0
			ci.draw_arc(top + Vector2(0, 26), rad, 0.0, TAU, 32, Color(1.0, 0.85, 0.4, 0.8 * (1.0 - rad / 48.0)), 1.0)
