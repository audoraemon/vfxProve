class_name LanternBearer
extends RefCounted
## The Lantern-Bearer (v0.11.2, spec 4.5): AFTER mission seconds after the toll a priest carries the Lantern's flame from where he stands to
## the bell tower's foot, on DUTY and slowed to SLOW of a messenger's run (~21 s for ~10 units), with two escorts walking in file behind him
## ESCORT_GAP (2.2) and twice that back along his own path -- more than two Silent Doom radii apart, so one Doom never takes two.
## Kill him, by any power, and the Lantern goes Blind (LanternWatch.blind(); dawn slows again).
##
## The escorts take up the flame: an escort living and unheld within ESCORT_SEE (3.0) of the Bearer's fall carries on (banner RELAY), judged
## once the cast's other victims have fallen as TempleReport judges its carrier (Crowd._doomed empty), so a Heaven Splitter that takes all
## three leaves nobody to see. At most two relays; ESCORT_RELAY false makes the escorts witnesses only. At the tower he keeps the vigil
## (state VIGIL): the speed-up stays, and he can still be killed there -- no relay at the vigil, so that kill is final (D23).
##
## Real time: the walk, the file's re-aim and the relay's look are reflexes (D20) and run on real seconds; only the countdown is shown in
## mission seconds (seconds_left() is real, the HUD multiplies it by the clock's rate). Freed bodies: the Bearer, the escorts and the
## candidates may be freed after a death fade, so every read goes through _alive() on a Variant, and `escorts` is an untyped Array.

enum State { WAITING, WALKING, VIGIL, DEAD }

## Mission seconds after the toll that he sets out (set by LanternWatch, which keeps the schedule).
const AFTER := 10.0
## The share of a messenger's run the Bearer walks at (`statuses[&"slow"]`, DUTY only).
const SLOW := 0.3
const ESCORTS := 2
## Where each escort keeps behind him along his path (the second twice this), and how far from the Bearer an escort may see him fall.
const ESCORT_GAP := 2.2
const ESCORT_SEE := 3.0
const ESCORT_RELAY := true
## Seconds between re-aims of the three (real).
const RETARGET := 0.5
## Seconds between the tries of a Bearer with nobody free to appoint (C18).
const SEEK := 1.0
## How near the tower's foot counts as there, and the least straight distance an escort keeps from the walker ahead of him (a corner would
## otherwise cut the 2.2 of path down to 1.56, under two Silent Doom radii). (Left, final review: 1.9 is under Crowd.DOOM_WITNESS 2.0, so at a corner an escort can count as a
## witness to the Bearer's fall where on a straight he would not; 2.05 breaks the file's spread, test_lantern_bearer._spread.)
const REACH := 1.0
const MIN_CHORD := 1.9
## Metres between samples of the Bearer's path, and how far back an escort looks for a place that keeps MIN_CHORD.
const TRAIL_STEP := 0.3
const TRAIL_SEARCH := 4.0
## An escort far behind his place runs at full pace; nearer than CATCH_FAR he keeps CATCH of the run; at his place he keeps the Bearer's.
const CATCH_FAR := 2.0
const CATCH_NEAR := 0.7
const CATCH := 0.6

const SET_OUT := "THE LANTERN-BEARER SETS OUT"
const VIGIL := "THE BEARER KEEPS THE VIGIL"
const RELAY := "AN ESCORT TAKES UP THE FLAME"

## The tags' colours (spec 5.2): the Bearer gold, an escort red, the bell tower orange.
const GOLD := Color("d8b23a")
const RED := Color("c8342a")
const ORANGE := Color("ff9a3a")

## Minds he takes the walk up again from once back on his feet, and the god's holds that blind an escort.
const RESUMABLE := TempleReport.RESUMABLE
const HELD := TempleReport.HELD

var carrier: Person
## The escorts, in file (nearest the Bearer first). Untyped: a body may be freed.
var escorts: Array = []
var state := State.WAITING
var relays := 0
var rules: Rules
var crowd: Crowd
var door := Vector2.INF
var foot := Vector2.INF

var _reserved: Array = []
## func(p: Person) -> bool: someone a director has busy (its own actor, a report's carrier, a Herald). Empty: nobody is.
var _skip: Callable
## The Bearer's path, oldest first (seeded with a tail behind where he set out, so the escorts have a place from the first second).
var _trail := PackedVector2Array()
## Path length ÷ straight distance, from the start (the countdown's allowance for corners).
var _detour := 1.0
var _retarget_in := 0.0
var _fell_at := Vector2.INF
## The first re-aim after an appointment sends them whatever they were doing (a sheltering or frightened citizen included).
var _force_next := false
var _last_at := Vector2.INF
## Where he stands at the vigil, and each escort's place in the file (parallel to `escorts`).
var _stand := Vector2.INF
var _places: Array = []


## Appoints the Bearer, the clergy citizen nearest `door_point` (else the nearest citizen free for it), and the two nearest lay citizens as
## escorts, and sends them. With nobody free he waits (WAITING) and tries again every SEEK. `reserved`: people the night has set aside.
func setup(r: Rules, c: Crowd, door_point: Vector2, foot_point: Vector2, reserved: Array = [], skip := Callable()) -> LanternBearer:
	rules = r
	crowd = c
	door = door_point
	foot = foot_point
	_reserved = reserved
	_skip = skip
	_appoint()
	return self


## Seconds the Bearer still needs to reach the tower's foot, REAL seconds (the HUD multiplies by the clock's rate for the tag, D21).
func seconds_left() -> float:
	if state != State.WALKING or not _alive(carrier):
		return 0.0
	var speed := Person.PANIC_SPEED * carrier.pace * SLOW
	return carrier.ground_pos.distance_to(foot) * _detour / maxf(speed, 0.05)


func dead() -> bool:
	return state == State.DEAD


## "" while waiting, then "walking", "vigil" or "dead" (LanternWatch's hint).
func phase() -> String:
	match state:
		State.WALKING:
			return "walking"
		State.VIGIL:
			return "vigil"
		State.DEAD:
			return "dead"
	return ""


## `p` is one of the three on the errand (a director's report must not pull him off it).
func has_errand(p: Variant) -> bool:
	if state != State.WALKING and state != State.VIGIL:
		return false
	return p == carrier or escorts.has(p)


## Every living one of the three.
func walkers() -> Array[Person]:
	var out: Array[Person] = []
	if _alive(carrier):
		out.append(carrier)
	for e: Variant in escorts:
		if _alive(e):
			out.append(e as Person)
	return out


func step(delta: float) -> void:
	if state == State.DEAD:
		return
	if state == State.WAITING:
		_retarget_in -= delta
		if _retarget_in <= 0.0:
			_retarget_in = SEEK
			_appoint()
		return
	_prune()
	if _fell_at == Vector2.INF and not _alive(carrier):
		_fell_at = _last_at  # he left the town or was freed with no death to judge: as if he fell where he was last seen
	if _fell_at != Vector2.INF:
		if not crowd._doomed.is_empty():
			return  # the cast's other victims have not fallen yet
		_judge()
		if state == State.DEAD or not _alive(carrier):
			return
	_last_at = carrier.ground_pos
	_apply_slow()
	if state == State.WALKING:
		_trail_add(carrier.ground_pos)
		if carrier.ground_pos.distance_to(foot) <= REACH:
			state = State.VIGIL
			_stand = carrier.ground_pos
			rules.banner.emit(VIGIL)
			_retarget_in = 0.0
	_retarget_in -= delta
	if _retarget_in > 0.0:
		return
	_retarget_in = RETARGET
	_drive()


## A death (the field's enemy_killed): only the Bearer's matters, noted now and judged once the cast's other victims have fallen.
func on_killed(e: DummyEnemy) -> void:
	if (state == State.WALKING or state == State.VIGIL) and e == carrier and _fell_at == Vector2.INF:
		_fell_at = e.ground_pos


## The tags (spec 5.2): the Bearer gold, edge-arrowed (his countdown in mission seconds); each escort red; the bell tower orange while he walks.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if state != State.WALKING and state != State.VIGIL:
		return out
	if _alive(carrier):
		var label := "LANTERN-BEARER - KEEPS THE VIGIL"
		if state == State.WALKING:
			label = "LANTERN-BEARER - AT THE TOWER IN %s" % UiTheme.clock(seconds_left() * rules.clock_rate)
		out.append(MapTag.person(carrier.ground_pos, GOLD, label, true))
	for e: Variant in escorts:
		if _alive(e):
			out.append(MapTag.person((e as Person).ground_pos, RED, "ESCORT", true))
	if state == State.WALKING and crowd.bell != null and is_instance_valid(crowd.bell.tower) and not crowd.bell.tower.destroyed:
		out.append(MapTag.place(crowd.bell.tower.center(), ORANGE, "BELL TOWER", crowd.bell.tower.height))
	return out


## Let the three go: the slowing undone and everyone back to their day (the Lantern is blind, or the act is over). The vigil's escorts stay
## only while the act runs.
func release() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	_let_go()


# --- appointing -----------------------------------------------------------------------------------------------------------------------

## The free citizens as [distance to the door, index, person], nearest first.
func _pool() -> Array:
	var rows: Array = []
	var keeper: Variant = crowd.bell.keeper if crowd.bell != null else null
	for i in crowd.citizens.size():
		var p: Variant = crowd.citizens[i]
		if not _alive(p) or (p as Person).profile == null or (p as Person).inside or p == keeper or _reserved.has(p):
			continue
		var q := p as Person
		if q.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			continue
		if q.mind in [Person.Mind.DUTY, Person.Mind.FLEE, Person.Mind.FIGHT] or q.held_by_god():
			continue
		if _skip.is_valid() and bool(_skip.call(q)):
			continue
		rows.append([q.ground_pos.distance_to(door), i, q])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
	return rows


func _appoint() -> void:
	var pool := _pool()
	if pool.is_empty():
		return
	var chosen: Person = null
	for row: Array in pool:
		if CitizenProfile.is_clergy((row[2] as Person).profile.role):
			chosen = row[2]
			break
	if chosen == null:
		chosen = pool[0][2]
	carrier = chosen
	escorts.clear()
	# The lay citizens nearest the door first, then whoever is left if the town is short of them.
	for lay in [true, false]:
		for row: Array in pool:
			if escorts.size() >= ESCORTS:
				break
			var p: Person = row[2]
			if p == carrier or escorts.has(p) or (lay and CitizenProfile.is_clergy(p.profile.role)):
				continue
			escorts.append(p)
	state = State.WALKING
	_fell_at = Vector2.INF
	_last_at = carrier.ground_pos
	_start_trail()
	rules.banner.emit(SET_OUT)
	_retarget_in = 0.0
	_force_next = true
	_apply_slow()
	_drive()


## The path so far: a tail running back from where he stands, away from the tower along real walkable ground (the grid's own path to a point
## behind him, the first direction that connects), so the file has places before he has walked a step.
func _start_trail() -> void:
	var start := carrier.ground_pos
	var away := (start - foot).normalized() if start.distance_to(foot) > 0.01 else Vector2.DOWN
	var need := ESCORT_GAP * float(ESCORTS) + TRAIL_SEARCH
	_trail = PackedVector2Array()
	_detour = 1.0
	if crowd._grid != null:
		for turn: float in [0.0, 0.6, -0.6, 1.2, -1.2, 2.0, -2.0]:
			var far: Vector2 = crowd._grid.nearest_walkable(start + away.rotated(turn) * need)
			if far == Vector2.INF or far.distance_to(foot) <= start.distance_to(foot):
				continue
			var way: PackedVector2Array = crowd._grid.path(start, far)
			if way.size() >= 2 and _length(start, way) >= ESCORT_GAP * float(ESCORTS) + 1.0:
				for i in range(way.size() - 1, -1, -1):
					_trail.append(way[i])
				break
		if start.distance_to(foot) > 1.0:
			var home: PackedVector2Array = crowd._grid.path(start, foot)
			_detour = maxf(1.0, _length(start, home) / start.distance_to(foot))
	_trail.append(start)


static func _length(from: Vector2, way: PackedVector2Array) -> float:
	var total := 0.0
	var prev := from
	for p in way:
		total += prev.distance_to(p)
		prev = p
	return total


# --- the walk -------------------------------------------------------------------------------------------------------------------------

## The Bearer's pace and the escorts', every frame: DUTY is the walk and the slow is the walk's alone, so a fright runs at its own pace.
func _apply_slow() -> void:
	_slow(carrier, SLOW)
	for i in escorts.size():
		var e: Variant = escorts[i]
		if not _alive(e):
			continue
		var share := SLOW
		if state == State.WALKING and i < _places.size() and (_places[i] as Vector2) != Vector2.INF:
			var gap := (e as Person).ground_pos.distance_to(_places[i] as Vector2)
			share = 1.0 if gap > CATCH_FAR else (CATCH if gap > CATCH_NEAR else SLOW)
		_slow(e, share)


func _slow(p: Variant, share: float) -> void:
	if not _alive(p):
		return
	var q := p as Person
	if q.mind == Person.Mind.DUTY and share < 1.0:
		q.statuses[&"slow"] = share
	else:
		q.statuses.erase(&"slow")


## One re-aim of the three (every RETARGET).
func _drive() -> void:
	if not _alive(carrier):
		return
	var force := _force_next
	_force_next = false
	var to := foot if state == State.WALKING else _stand
	_walk(carrier, to, force)
	_places = []
	var ahead := carrier.ground_pos
	var n := 0
	for e: Variant in escorts:
		if not _alive(e):
			_places.append(Vector2.INF)
			continue
		var place := Vector2.INF
		if state == State.WALKING:
			place = _file_place(n, ahead)
		else:
			place = _ring_place(n)
		_places.append(place)
		if place != Vector2.INF:
			_walk(e as Person, place, force)
		ahead = (e as Person).ground_pos
		n += 1
	_apply_slow()


## Sends `p` to `to` on DUTY unless he is already on his way there; after a fright, once he is back on his feet (`force`: a relay, at once
## unless the god holds him).
func _walk(p: Person, to: Vector2, force: bool) -> void:
	if p.mind == Person.Mind.DUTY:
		if not p.has_goal() or p.anchor.distance_to(to) > 0.5:
			p.go_duty(to)
	elif p.mind in RESUMABLE or (force and not p.mind in HELD):
		p.go_duty(to)


## The place `n` (0 = nearest) live escorts back in file: the point on the Bearer's path ESCORT_GAP × (n + 1) behind him, or further back where a
## corner would bring it under MIN_CHORD of the walker ahead. Vector2.INF (hold where he stands) when the path is too short for that.
func _file_place(n: int, ahead: Vector2) -> Vector2:
	var arc := ESCORT_GAP * float(n + 1)
	var back := 0.0
	while back <= TRAIL_SEARCH:
		var at := _on_trail(arc + back)
		if at.distance_to(ahead) >= MIN_CHORD:
			return at
		back += TRAIL_STEP
	return Vector2.INF


## The point `arc` metres back along the path from where the Bearer stands now (the oldest point when the path is shorter).
func _on_trail(arc: float) -> Vector2:
	var here := carrier.ground_pos
	var prev := here
	var acc := 0.0
	for i in range(_trail.size() - 1, -1, -1):
		var seg := prev.distance_to(_trail[i])
		if seg > 0.0 and acc + seg >= arc:
			return prev.lerp(_trail[i], (arc - acc) / seg)
		acc += seg
		prev = _trail[i]
	return _trail[0] if not _trail.is_empty() else here


func _trail_add(at: Vector2) -> void:
	if _trail.is_empty() or _trail[_trail.size() - 1].distance_to(at) >= TRAIL_STEP:
		_trail.append(at)


## At the vigil the escorts stand ESCORT_GAP from him, round him, apart from each other.
func _ring_place(n: int) -> Vector2:
	var out := (door - _stand).normalized() if door.distance_to(_stand) > 0.01 else Vector2.RIGHT
	var live := 0
	for e: Variant in escorts:
		if _alive(e):
			live += 1
	var turn := TAU / float(maxi(live + 1, 3))
	var at := _stand + out.rotated(turn * float(n + 1)) * ESCORT_GAP
	if crowd._grid != null:
		var w := crowd._grid.nearest_walkable(at)
		if w != Vector2.INF:
			at = w
	return at


# --- the fall -------------------------------------------------------------------------------------------------------------------------

## Judged once a cast's other victims have fallen: an escort living, unheld, out of doors and within ESCORT_SEE of the fall takes the flame up
## (the nearest first); none, or at the vigil, and the Bearer is dead.
func _judge() -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	if state == State.VIGIL or not ESCORT_RELAY:
		_die()
		return
	var best: Person = null
	var best_d := ESCORT_SEE
	for e: Variant in escorts:
		if not _alive(e):
			continue
		var p := e as Person
		if p.inside or p.held_by_god() or p.mind in HELD:
			continue
		var d := p.ground_pos.distance_to(at)
		if d <= best_d:
			best = p
			best_d = d
	if best == null:
		_die()
		return
	if _alive(carrier):
		carrier.statuses.erase(&"slow")
	escorts.erase(best)
	_places = []  # (the file's indices just shifted)
	carrier = best
	relays += 1
	_last_at = best.ground_pos
	rules.banner.emit(RELAY)
	_trail_add(best.ground_pos)
	_retarget_in = 0.0
	_apply_slow()
	_walk(best, foot, true)


func _die() -> void:
	state = State.DEAD
	_let_go()


## Everyone alive of the three goes back to their day, the slowing undone.
func _let_go() -> void:
	for p in walkers():
		p.statuses.erase(&"slow")
		if is_instance_valid(crowd):
			crowd.off_duty(p)


## Drops the bodies that were freed (a death fade over, or a person gone from the town) from the file, so it closes up.
func _prune() -> void:
	var live: Array = []
	for e: Variant in escorts:
		if is_instance_valid(e):
			live.append(e)
	if live.size() != escorts.size():
		_places = []
	escorts = live


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
