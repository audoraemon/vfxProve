class_name BanishingRite
extends RefCounted
## The Banishing Rite (v0.05): the town's answer to its god. At City Emergency the clergy gather on the cathedral's
## steps; once NEED of them stand in the ring they chant for the profile's rite_time, with a golden ring on the
## steps and a bar on the HUD. Finished, it pushes the god out of the mortal realm sooner: Mission takes the mission's
## rite_penalty off the manifestation (completed) -- PENALTY seconds, 20 in The Long Night's acts (v0.09.1). The rite
## breaks -- its progress lost -- when fewer than HOLD clergy are left in the ring (killed or frightened away) or the
## cathedral falls under MIN_HP of its health; the clergy still on the steps regather COOLDOWN seconds later. A fallen or
## blighted cathedral, or fewer than NEED clergy alive, ends it for good. Only Prepared towns and up
## (ResponseProfile.rite) hold one, and it is done once.

signal gathering
signal started
signal broken(reason: String)
signal completed
signal ended(reason: String)

enum State { IDLE, GATHERING, CHANTING, COOLDOWN, DONE, ENDED }

const NEED := 3
const HOLD := 2
## Clergy called to the steps: the first NEED to arrive start it, the others help hold it. This many by default; the
## profile sets it (ResponseProfile.rite_clergy, v0.08.2: God-Resistant calls more).
const CALL := 4
## Seconds a completed rite takes off the clock, unless the mission sets its own (MissionDef.rite_penalty).
const PENALTY := 40.0
const COOLDOWN := 30.0
const MIN_HP := 0.5
## How near its place in the ring a cleric must stand to count.
const RING_REACH := 1.0
## The ring's centre lies this far in front of the cathedral's doors; its places spread PLACE_GAP apart.
const FRONT := 1.0
const PLACE_GAP := 0.5
## Drawn ring's radius, in ground units: clear of the cathedral's front wall.
const RING_R := 0.95
## Minds a cleric can be called from: not running, sheltering, or busy with a fire.
const AVAILABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

var state := State.IDLE
var progress := 0.0
var duration := 45.0
var cathedral: Structure
var centre := Vector2.INF
## The places in the ring, walkable, nearest the middle first.
var places: Array[Vector2] = []
## The clergy called and the place each was sent to: [[Person, Vector2]].
var circle: Array = []
## The ring's glow, 0..1, easing in while the clergy chant and out after (Crowd's ResponseDrawer draws it).
var glow := 0.0
## Ended only because the town's profile has no rite (v0.09): Crowd.raise_profile() may hold one after all.
var off_by_profile := false
var _cool := 0.0
var _crowd: Crowd


func setup(crowd: Crowd, env: EnvironmentField, grid: WalkGrid) -> BanishingRite:
	_crowd = crowd
	duration = crowd.profile.rite_time
	for s in env.structures():
		if s.role == &"temple":
			cathedral = s
			break
	if cathedral != null:
		var c := Vector2(cathedral.center().x, cathedral.footprint.end.y + FRONT)
		centre = c if grid.walkable(c) else grid.nearest_walkable(c)
		# A shallow arc facing the doors: the outer places a little nearer the cathedral. One place for each cleric the
		# profile calls (v0.08.2; CALL, 4, before), the middle ones first.
		var n: int = crowd.profile.rite_clergy
		var mid := (float(n) - 1.0) * 0.5
		var order := range(n)
		order.sort_custom(func(a: int, b: int) -> bool:
			return absf(a - mid) < absf(b - mid) or (absf(a - mid) == absf(b - mid) and a < b))
		for k in order:
			var off := float(k) - mid
			var g := centre + Vector2(off * PLACE_GAP, -absf(off) * 0.2)
			var w := g if grid.walkable(g) else grid.nearest_walkable(g)
			if w != Vector2.INF:
				places.append(w)
	if not crowd.profile.rite or cathedral == null or centre == Vector2.INF or places.size() < NEED:
		state = State.ENDED
		off_by_profile = not crowd.profile.rite
	return self


## City Emergency: call the clergy to the steps.
func begin() -> void:
	if state != State.IDLE:
		return
	if not is_instance_valid(cathedral) or cathedral.destroyed or cathedral.blighted:
		state = State.GATHERING  # so the end is announced: the town learns its rite cannot be held
		_end("the cathedral has fallen" if not is_instance_valid(cathedral) or cathedral.destroyed
			else "the cathedral is defiled")
		return
	_gather()


func _gather() -> void:
	state = State.GATHERING
	_recruit()
	gathering.emit()


func step(delta: float) -> void:
	glow = move_toward(glow, 1.0 if state == State.CHANTING else 0.0, delta * 1.5)
	if state == State.IDLE or state == State.DONE or state == State.ENDED:
		return
	if not is_instance_valid(cathedral) or cathedral.destroyed:
		_end("the cathedral has fallen")
		return
	if cathedral.blighted:
		_end("the cathedral is defiled")
		return
	if living_clergy() < NEED:
		_end("too few clergy are left")
		return
	_tend()
	match state:
		State.COOLDOWN:
			_cool -= delta
			if _cool <= 0.0:
				_gather()
		State.GATHERING:
			_recruit()
			if in_ring() >= NEED and _sound():
				state = State.CHANTING
				progress = 0.0
				started.emit()
		State.CHANTING:
			if in_ring() < HOLD:
				_break("the clergy were scattered")
			elif not _sound():
				_break("the cathedral is damaged")
			else:
				progress += delta
				if progress >= duration:
					_complete()


## The cathedral is whole enough to hold the rite.
func _sound() -> bool:
	return cathedral.hp >= cathedral.max_hp * MIN_HP


## Drop the dead and the frightened from the circle; send anyone knocked off their place back to it.
func _tend() -> void:
	var kept: Array = []
	for e in circle:
		if not is_instance_valid(e[0]):
			continue
		var p: Person = e[0]
		if not p.is_alive() or p.mind != Person.Mind.DUTY:
			continue
		if not p.has_goal() and p.ground_pos.distance_to(e[1]) > RING_REACH:
			p.go_duty(e[1])
		kept.append(e)
	circle = kept


## Fill the empty places with the nearest available clergy.
func _recruit() -> void:
	var free: Array[Vector2] = places.duplicate()
	for e in circle:
		free.erase(e[1])
	if free.is_empty():
		return
	var pool: Array[Person] = []
	for p in _crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.profile != null and p.profile.role == CitizenProfile.Role.CLERGY \
				and not p.inside and p.mind in AVAILABLE and not _called(p):
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(centre) < b.ground_pos.distance_squared_to(centre))
	for p in pool:
		if free.is_empty():
			break
		var at: Vector2 = free.pop_front()
		p.go_duty(at)
		circle.append([p, at])


func _called(p: Person) -> bool:
	for e in circle:
		if e[0] == p:
			return true
	return false


## Clergy standing at their places in the ring.
func in_ring() -> int:
	var n := 0
	for e in circle:
		if not is_instance_valid(e[0]):
			continue
		var p: Person = e[0]
		if p.is_alive() and p.mind == Person.Mind.DUTY and not p.has_goal() and p.ground_pos.distance_to(e[1]) <= RING_REACH:
			n += 1
	return n


func living_clergy() -> int:
	var n := 0
	for p in _crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.profile != null and p.profile.role == CitizenProfile.Role.CLERGY:
			n += 1
	return n


func _break(reason: String) -> void:
	state = State.COOLDOWN
	progress = 0.0
	_cool = COOLDOWN
	broken.emit(reason)


func _complete() -> void:
	state = State.DONE
	progress = duration
	_release()
	completed.emit()


func _end(reason: String) -> void:
	var was_active := state != State.IDLE
	state = State.ENDED
	progress = 0.0
	_release()
	if was_active:
		ended.emit(reason)


func _release() -> void:
	for e in circle:
		if is_instance_valid(e[0]):
			_crowd.off_duty(e[0])
	circle.clear()


## Seconds of the rite done, 0..1.
func fraction() -> float:
	return clampf(progress / maxf(duration, 0.001), 0.0, 1.0)


## The golden ring on the steps while the clergy chant, filling as the rite goes on, with motes rising from it.
## Into `ci` (world space), under the people and the buildings (Crowd's ground drawer).
func draw_ground(ci: CanvasItem) -> void:
	if glow <= 0.0 or centre == Vector2.INF:
		return
	var t := float(Time.get_ticks_msec()) * 0.001
	var ring := PackedVector2Array()
	for i in 33:
		var a := TAU * float(i) / 32.0
		ring.append(Iso.ground_to_screen(centre + Vector2(cos(a), sin(a)) * RING_R))
	var pulse := 0.75 + 0.25 * sin(t * 3.0)
	ci.draw_colored_polygon(ring.slice(0, 32), Color(1.0, 0.8, 0.35, 0.22 * glow * pulse))
	ci.draw_polyline(ring, Color(1.0, 0.82, 0.38, 0.85 * glow), 1.0)
	# The rite's progress: a bright arc growing round the ring.
	var done := ceili(32.0 * fraction())
	if done > 0:
		ci.draw_polyline(ring.slice(0, done + 1), Color(1.0, 0.95, 0.7, glow), 2.0)


## Over the people: a halo over each cleric chanting in the ring, and motes rising from it.
func draw_over(ci: CanvasItem) -> void:
	if glow <= 0.0 or centre == Vector2.INF:
		return
	var t := float(Time.get_ticks_msec()) * 0.001
	var gold := Color(1.0, 0.88, 0.45, glow)
	for e in circle:
		if is_instance_valid(e[0]) and (e[0] as Person).is_alive() and not (e[0] as Person).has_goal():
			var head := Iso.ground_to_screen((e[0] as Person).ground_pos).round() + Vector2(0.0, -19.0)
			ci.draw_rect(Rect2(head + Vector2(-3, 0), Vector2(6, 1)), gold)
			ci.draw_rect(Rect2(head + Vector2(-4, 1), Vector2(1, 1)), gold)
			ci.draw_rect(Rect2(head + Vector2(3, 1), Vector2(1, 1)), gold)
			ci.draw_rect(Rect2(head + Vector2(-3, 2), Vector2(6, 1)), gold)
	for k in 10:
		var a := TAU * float(k) / 10.0 + t * 0.4
		var rise := fmod(t * 0.5 + float(k) * 0.37, 1.0)
		var at := Iso.ground_to_screen(centre + Vector2(cos(a), sin(a)) * RING_R) + Vector2(0.0, -rise * 30.0)
		ci.draw_rect(Rect2(at.round(), Vector2(1, 2)), Color(1.0, 0.9, 0.55, glow * (1.0 - rise)))
