class_name BellNetwork
extends RefCounted
## The Bell Tower (v0.05): how a local disaster becomes the whole town's. At the first Local Emergency the bellkeeper
## goes to the tower and climbs it -- CLIMB seconds, with a progress bar over the tower -- and rings the bell: the
## alarm jumps RING_ALARM, every citizen learns of the danger, and the town reaches City Emergency and Evacuation
## sooner (AlarmManager). A frightened bellkeeper abandons the climb and tries again RETRY seconds later; a dead one
## is replaced by one of its escorts if it has any (v0.07; a slower climb), else not; a fallen tower rings no more. An
## Unprepared town (ResponseProfile.bell off) has no bellkeeper. With hold_on_death (v0.08, The Warning) a dead keeper
## neither silences the bell nor calls an escort: the bell waits for whoever the mission sends (replace_keeper()).

signal climbing_started
signal rung
signal silenced(reason: String)
## Someone took over from a fallen bellkeeper: an escort (v0.07), or the citizen a mission sends (v0.08).
signal keeper_replaced

enum State { IDLE, CALLED, CLIMBING, WAITING, RUNG, SILENCED }

const RING_ALARM := 20.0
const RETRY := 10.0
const FOOT_REACH := 0.8
## Anyone climbing in a fallen bellkeeper's place takes this much longer (v0.07: an escort; v0.08: a citizen too).
const ESCORT_CLIMB := 1.5

var state := State.IDLE
var progress := 0.0
var climb := 8.0
var tower: Structure
var keeper: Person
## Whether the one on the rope now is a soldier: an escort that took it over (v0.07; replace_keeper()).
var keeper_is_soldier := false
## Whether the dead keeper waits for replace_keeper() rather than silencing the bell or calling an escort (v0.08).
var hold_on_death := false
## Whether a stand-in has taken the rope: the slower climb applies once, however many fall (v0.08; replace_keeper()).
var _replaced := false
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
		if not hold_on_death:
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
		if hold_on_death:
			return  # the mission sends someone (v0.08)
		# An escort takes the rope (v0.07), else the bell is silenced.
		var sub: Person = _crowd.escorts.bell_stand_in() if _crowd.escorts != null else null
		if sub != null:
			replace_keeper(sub)
			return
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


## Someone climbs in the fallen bellkeeper's place -- an escort (v0.07), or the citizen a mission sends (v0.08) --
## ESCORT_CLIMB times slower (once, however many fall); the climb starts over.
func replace_keeper(p: Person) -> void:
	keeper = p
	if not _replaced:
		climb *= ESCORT_CLIMB
	_replaced = true
	keeper_is_soldier = p.soldier
	progress = 0.0
	state = State.CALLED
	keeper.go_ring(foot)
	keeper_replaced.emit()


## How many times the bell has lied (The Bell Lies).
var lied := 0


## A bell that has rung is as if it had not (Crowd.unring_bell()): the keeper will try again.
func unring() -> void:
	if state == State.RUNG:
		_wait()


func _wait() -> void:
	state = State.WAITING
	_retry_in = RETRY


func _ring() -> void:
	if _crowd.is_hushed():
		_wait()  # a silenced town's bell makes no sound: the keeper tries again
		return
	if _crowd.is_bell_lying():
		# The bell lies: it tolls all is well, and the keeper, baffled, tries again.
		lied += 1
		ring_show = 3.0
		_crowd.false_bell(tower.center())
		_wait()
		return
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
	# A living keeper on the rope (an escort's stand-in, or the bellkeeper itself when the tower falls or cracks under
	# it) is let go: off_duty() sends it back to its post or its day, and does nothing for one that is dead or free.
	# (Only while the keeper exists: one that left the town is freed, and a freed person cannot be passed on.)
	if is_instance_valid(keeper):
		_crowd.off_duty(keeper)
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
