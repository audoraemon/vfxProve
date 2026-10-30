class_name WitnessDirector
extends RingerDirector
## One witness's errand in Silence the witness (god P5, MS §3, Ruling P5-12, C3): a RingerDirector's lay crew -- a witness and his two mates
## inside a house until SilenceWitnessDirector sends them -- with the bell taken out of it. He runs for the Temple's door, not the bell: he
## tells no keeper (`_rings_himself()` stays true, so `_run()` never calls `_deliver()` near a living bellkeeper), never takes the rope
## (`_take_rope()` and `_give_back()` do nothing: C3) and loses the night by his own check each step -- alive, out of doors, within
## TempleReport.REACH of the door (`in_temple`).
##
## The Hunt's rule: only his own mates carry the word on. His death seen by one of them (alive, out of doors, within Crowd.DOOM_WITNESS, not held
## by the god) sends that mate on as the witness (`THE MATE RUNS ON`); seen by anyone else, the word dies with him (`_relay_witness()` picks only
## from `mates`). The numbers come from SilenceWitnessDirector's SW_ consts, set on the vars below before setup() (C2: no const is redeclared).

## The mates walk in file (_heel()): the first this far behind the witness on his trail, the second this far ahead of him on the street -- 2.4 apart in a straight
## lane, and, since a mate walks a step off his place, more than two Silent Doom radii (1.6) apart at all but the turns of the road (MS §0).
const SW_HEEL_BEHIND := 1.6
const SW_HEEL_AHEAD := 1.0
## A mate is sent to a new place only when it lies this far from where he was sent.
const SW_HEEL_RETARGET := 0.3
## The trail: a place kept every SW_HEEL_STEP of his walk, this many of them.
## A mate walks at least this many times the witness's pace, or he could not keep to his place beside a man who walks at 0.65 of a citizen's.
const SW_MATE_QUICK := 2.0
const SW_HEEL_STEP := 0.4
const SW_HEEL_KEEP := 24
## How far ahead his street is read for the way he faces.
const SW_HEEL_LOOK := 1.5

## The share of his pace the witness walks at (SilenceWitnessDirector.SW_WITNESS_PACE), set before setup().
var witness_pace := 0.65
## At this many mission seconds from the Temple's door the banner `A WITNESS NEARS THE TEMPLE` shows once (SW_NEAR_WARN), set before setup().
var near_warn := 15.0
## Word has reached the Temple: the messenger, alive and out of doors, came within TempleReport.REACH of its door. The night is lost on it.
var in_temple := false
## Everyone whose pace is already the witness's (by instance id): none is slowed twice.
var _slowed_ids := {}
## The mates already given their pace (by instance id).
var _quick_ids := {}
## The messenger the warning banner was last shown for (a Variant: he may be a body freed after his death fade).
var _warned_for: Variant = null
## The Temple's door, found once (it does not move in a night).
var _temple := Vector2.INF
## His mates who could carry the word on, as the witness fell (alive, out of doors, within Crowd.DOOM_WITNESS, not held by the god): taken at the death,
## before the town's fright can lift a hold, and kept until _judge() picks from them.
var _saw: Array = []
## Seconds to the next look at the distance to the Temple.
var _near_in := 0.0
## His trail (_note_trail()) and whose it is (a mate who runs on starts his own).
var _trail := PackedVector2Array()
var _trail_for: Variant = null
## The street's length from the messenger's standing place to the Temple's door, kept for the step it was found in (eta() is asked by the tag, the strip and the
## hint every frame while he has no walk path; the grid's path is looked up once per step and place, not once per call).
var _street_left := -1.0
## Whom and where `_street_left` was found for.
var _street_for: Variant = null
var _street_at := Vector2.INF


## The witness walks at his share of the pace once he is sent (MS §3: `SW_WITNESS_PACE`).
func set_out() -> void:
	var was_waiting := waiting
	super()
	if was_waiting and _alive(watchman):
		_slow(watchman)
	if was_waiting:
		for v: Variant in mates:
			if _alive(v) and not _quick_ids.has((v as Person).get_instance_id()):
				_quick_ids[(v as Person).get_instance_id()] = true
				(v as Person).pace = maxf((v as Person).pace, watchman.pace * SW_MATE_QUICK)  # (the mates keep up with a man who walks slowly: Task 10, I3)


## His errand is the Temple's door, whatever the bell does (MS §3, C3).
func _goal() -> Vector2:
	return _door()


## The Temple's door (lantern_door()), found once.
func _door() -> Vector2:
	if _temple == Vector2.INF:
		_temple = lantern_door()
	return _temple


## C3: he never takes the rope, at the bell's foot or anywhere.
func _take_rope() -> void:
	pass


## C3: he never held the rope, so there is nothing to give back.
func _give_back() -> void:
	pass


## `p` walks at the witness's share of his pace, once.
func _slow(p: Person) -> void:
	var id := p.get_instance_id()
	if _slowed_ids.has(id):
		return
	_slowed_ids[id] = true
	p.pace *= witness_pace


## One step: the crew held through an evacuation (the one shared rule, MissionDirector._hold_all()), the Ringer's step, then the word-in check and
## the warning at near_warn.
func step(delta: float) -> void:
	_note_trail()
	_street_left = -1.0  # (a new step: the street from where he stands is looked up afresh, once)
	MissionDirector._hold_all(crew(), _evacuation_began())
	super(delta)
	if waiting or warning_dead or phase != Phase.RUN or not _alive(messenger) or messenger.inside:
		return
	if messenger.ground_pos.distance_to(_door()) <= TempleReport.REACH:
		in_temple = true  # word reaches the Temple: SilenceWitnessDirector.lost_reason() says so, WitnessObjective loses the night
		return
	if messenger.mind == Person.Mind.DUTY and not messenger.has_goal():
		messenger.go_duty(_door())  # (standing at the bell's foot with no way on, WarningDirector._run() would only offer him the rope: C3 gives him none)
	_near_in -= delta
	if _near_in <= 0.0:
		_near_in = RETARGET
		if _warned_for != messenger and eta() <= near_warn:
			_warned_for = messenger
			rules.banner.emit("A WITNESS NEARS THE TEMPLE")


## Mission seconds until the messenger reaches the Temple's door at his pace (the remaining walk in real seconds times the clock's rate); INF for
## none walking. A witness sheltering indoors (review of Task 5, M8) still counts: the seconds until he comes out (shelter_left()) and then the street.
func eta() -> float:
	if waiting or warning_dead or phase == Phase.OVER or not _alive(messenger):
		return INF
	var rate := rules.clock_rate if rules != null else 1.0
	if messenger.inside:
		return (shelter_left() + street_left() / maxf(Person.PANIC_SPEED * messenger.pace, 0.05)) * rate
	if messenger.has_goal() and not messenger._path.is_empty() and messenger.goal().distance_to(_door()) <= TempleReport.REACH:
		return TempleReport.walk_seconds(messenger, _door()) * rate  # (his errand's walk; one run off it by a fright is timed by the street below)
	# Standing at his door (the stare), or between two walks: the street's length, not the straight line.
	return street_left() / maxf(Person.PANIC_SPEED * messenger.pace, 0.05) * rate


## True while the messenger waits indoors out a fright (a shelter, not his house before he is sent): hidden and out of reach, he comes out when the danger has passed.
func sheltering() -> bool:
	return not waiting and not warning_dead and phase != Phase.OVER and _alive(messenger) and messenger.inside and messenger.mind == Person.Mind.SHELTER


## Real seconds until a sheltering messenger comes out: ShelterManager.CLEAR_SECONDS less the quiet so far (more if a danger comes near again); 0 for none.
func shelter_left() -> float:
	if not sheltering() or crowd.shelters == null or not crowd.shelters.shelters.has(messenger.shelter):
		return 0.0
	return maxf(0.0, ShelterManager.CLEAR_SECONDS - float(crowd.shelters.shelters[messenger.shelter].clear))


## The street's length from where the messenger stands to the Temple's door, looked up once per step and place (the straight line when the town has no grid).
func street_left() -> float:
	if not _alive(messenger):
		return 0.0
	if _street_left >= 0.0 and _street_for == messenger and _street_at == messenger.ground_pos:
		return _street_left
	var left := 0.0
	var at := messenger.ground_pos
	var path := crowd._grid.path(at, _door()) if crowd._grid != null else PackedVector2Array()
	for q in path:
		left += at.distance_to(q)
		at = q
	if path.is_empty():
		left = at.distance_to(_door())
	_street_left = left
	_street_for = messenger
	_street_at = messenger.ground_pos
	return left


## Judged after his death (MS §3, the Hunt's rule): the nearest of his own able mates who saw it carries the word on; with none the word dies with
## him (the base's, but for the banner `THE MATE RUNS ON` and the pace).
func _judge() -> void:
	var at := _fell_at
	_fell_at = Vector2.INF
	var mate := _relay_witness(at)
	if mate == null:
		warning_dead = true
		stopped_how = "kill"
		phase = Phase.OVER
		return
	relays += 1
	messenger = mate
	killed_by = ""
	_descend = 0.0
	_slow(mate)
	if walls_stop and _out_of_walls():
		return
	rules.banner.emit("THE MATE RUNS ON")
	phase = Phase.RUN
	_retarget_in = RETARGET
	_run(true)


## The messenger fell (WarningDirector._on_killed()): the mates who see it are taken now, before the crowd reacts -- a fright lifts a whisper, and the
## mate who stood held by the god when his witness fell could not carry the word on.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	var fresh := e == messenger and phase != Phase.OVER and _fell_at == Vector2.INF
	super(e, kind)
	if not fresh:
		return
	_saw = []
	for v: Variant in mates:
		if _alive(v) and v != messenger and _could_carry(v as Person, e.ground_pos):
			_saw.append(v)


## `p`, one of his mates, could carry the word on from a death at `at`: out of doors, within Crowd.DOOM_WITNESS, not held by the god (Whispered,
## Confused, compelled or staring at a lure), not fleeing the town.
func _could_carry(p: Person, at: Vector2) -> bool:
	return not p.inside and not p.held_by_god() and p.mind != Person.Mind.FLEE and not reserved.has(p) \
		and p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS


## The nearest of his own mates who saw him fall at `at` (_saw, taken at the death) and still stand out of doors; null for none, and the word dies.
## Nobody else ever carries it (MS §3).
func _relay_witness(at: Vector2) -> Person:
	var best: Person = null
	var best_d := INF
	for v: Variant in _saw:
		if not _alive(v) or (v as Person).inside:
			continue
		var d := (v as Person).ground_pos.distance_to(at)
		if d < best_d:
			best = v as Person
			best_d = d
	_saw = []
	return best


## The mates who would carry the word on from his death where he stands: his own, able (_could_carry()'s rule) and within Crowd.DOOM_WITNESS of him.
## Only reads.
func witnesses() -> Array[Person]:
	var out: Array[Person] = []
	if not _alive(messenger):
		return out
	for v: Variant in mates:
		if _alive(v) and v != messenger and _could_carry(v as Person, messenger.ground_pos):
			out.append(v as Person)
	return out


## Where the mates stand at the door by the witness at `at`: the Ringer's places (beyond one Silent Doom of him and within sight, the two farthest apart) but
## only ground the street reaches (review of Task 10, I3: at the south-west house one place lay in a pocket behind a fence, and the mate set down there
## never walked with him). Fewer if fewer fit.
func _door_spots(at: Vector2) -> Array[Vector2]:
	var fit: Array[Vector2] = []
	for k in DOOR_RING:
		var g := _walkable(at + Vector2.from_angle(TAU * float(k) / float(DOOR_RING)) * tune_mate_gap)
		var gap := g.distance_to(at)
		if gap > SilentDoom.RADIUS and gap <= Crowd.DOOM_WITNESS - DOOR_MARGIN and not fit.has(g) 				and (crowd._grid == null or not crowd._grid.path(g, _door()).is_empty()):
			fit.append(g)
	var out: Array[Vector2] = []
	out.assign(fit.slice(0, 1))
	var far := 0.0
	for i in fit.size():
		for j in range(i + 1, fit.size()):
			if fit[i].distance_to(fit[j]) > far:
				far = fit[i].distance_to(fit[j])
				out = [fit[i], fit[j]]
	return out


## The mates at his heels, as the Ringer's (RingerDirector._step_mates()) but sent anew only when their place has moved SW_HEEL_RETARGET: at the Ringer's 0.3 a
## mate is set off at every step of the witness and walks stop and go, far behind his place (review of Task 10, I3, Ruling P5-T10-R3).
func _step_mates() -> void:
	mates = mates.filter(func(v: Variant) -> bool: return is_instance_valid(v) and v != messenger)
	if (phase != Phase.RUN and phase != Phase.DELIVERED) or not _alive(messenger) or messenger.inside or _goal() == Vector2.INF:
		return
	_order_mates()
	for i in mates.size():
		var v: Variant = mates[i]
		if not _alive(v):
			continue
		var p := v as Person
		if p.inside or p.held_by_god() or not (p.mind == Person.Mind.DUTY or _resumable(p)):
			continue
		var spot := _heel(messenger.ground_pos, Vector2.ZERO, i)
		if p.mind != Person.Mind.DUTY or p.anchor.distance_to(spot) > SW_HEEL_RETARGET:
			p.go_duty(spot)


## The mate nearer the place behind him is the first, the other the second, so the two do not cross to change places as he sets out (they would pass through
## each other's ground and bunch). Swapped only when it saves SW_HEEL_RETARGET or more of their walking.
func _order_mates() -> void:
	if mates.size() != 2 or not _alive(mates[0]) or not _alive(mates[1]):
		return
	var back := _heel(messenger.ground_pos, Vector2.ZERO, 0)
	var front := _heel(messenger.ground_pos, Vector2.ZERO, 1)
	var a: Vector2 = (mates[0] as Person).ground_pos
	var b: Vector2 = (mates[1] as Person).ground_pos
	if a.distance_to(back) + b.distance_to(front) > a.distance_to(front) + b.distance_to(back) + SW_HEEL_RETARGET:
		mates = [mates[1], mates[0]]


## The witness's trail, kept as he walks: his places, SW_HEEL_STEP apart, the newest last (the mates' places behind him lie on ground he has walked).
func _note_trail() -> void:
	if not _alive(messenger) or messenger.inside:
		return
	if _trail_for != messenger:
		_trail_for = messenger
		_trail = PackedVector2Array()
	if _trail.is_empty() or _trail[_trail.size() - 1].distance_to(messenger.ground_pos) > SW_HEEL_STEP:
		_trail.append(messenger.ground_pos)
		if _trail.size() > SW_HEEL_KEEP:
			_trail.remove_at(0)


## The point `dist` back along his trail from where he stands; the trail's oldest place (or his own) when it is not that long yet.
func _behind(dist: float) -> Vector2:
	var at := messenger.ground_pos
	var left := dist
	for k in range(_trail.size() - 1, -1, -1):
		var seg := at.distance_to(_trail[k])
		if seg >= left:
			return at.move_toward(_trail[k], left)
		left -= seg
		at = _trail[k]
	var way := _ahead(SW_HEEL_LOOK) - messenger.ground_pos  # (the trail is short: straight back from the way he faces)
	return _walkable(at - (way.normalized() if way.length() > 0.05 else Vector2.UP) * left)


## The point `dist` ahead of him along the street to the Temple's door; the door when the street is shorter, his own place when it gives nothing.
func _ahead(dist: float) -> Vector2:
	var at := messenger.ground_pos
	var left := dist
	if crowd._grid != null:
		for q in crowd._grid.path(at, _door()):
			var seg := at.distance_to(q)
			if seg >= left:
				return at.move_toward(q, left)
			left -= seg
			at = q
	return at


## Where mate `k` walks: in file on his own ground, so the two never cross and a narrow lane or a bend does not fold them onto one place (review of Task 10, I3,
## Ruling P5-T10-R3; MS §0, more than 1.6 apart as one Silent Doom is wide): the first SW_HEEL_BEHIND back along the trail he has walked, the second
## SW_HEEL_AHEAD ahead of him on the street -- SW_HEEL_BEHIND + SW_HEEL_AHEAD apart, each within sight of him. `dir` is not read.
func _heel(at: Vector2, dir: Vector2, k: int) -> Vector2:
	if tune_mates != 2 or k > 1 or not _alive(messenger):
		return super(at, dir, k)
	return _walkable(_behind(SW_HEEL_BEHIND) if k == 0 else _ahead(SW_HEEL_AHEAD))


## W1 (shared rule 1), in the witness's words: out of the walls he is stopped and walks on off the map.
func _out_of_walls() -> bool:
	if not _alive(messenger) or messenger.inside or not Walls.outside(messenger.ground_pos):
		return false
	var gone := messenger
	_end("out")
	send_off(gone)
	rules.banner.emit("THE WITNESS LEAVES TOWN")
	return true


## The map tags, most important first: the witness (gold, pointed at from the edge) with the time to the Temple -- sheltering indoors too, as
## `WITNESS INSIDE - TEMPLE IN m:ss` (no hidden state) -- then each of his mates who is out of doors (red, pointed at). No bellkeeper and no
## bell-tower tag (MS §3). None while they wait, or once he is stopped.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if waiting or phase == Phase.OVER or warning_dead or not _alive(messenger):
		return out
	var label := "WITNESS - TEMPLE IN %s" % UiTheme.clock(eta())
	if messenger.inside:
		label = "WITNESS INSIDE - TEMPLE IN %s" % UiTheme.clock(eta())  # (sheltering: hidden, but the tag and the strip's row go on, review M8)
	out.append(MapTag.person(messenger.ground_pos, MARK_MESSENGER, label, true))
	for v: Variant in mates:
		if _alive(v) and v != messenger and not (v as Person).inside:
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "MATE", true))
	return out


## The hint's phase: "near" within near_warn of the Temple, "relay" once a mate runs on, else "" (the mission's own line). "" while waiting or stopped.
func hint_phase() -> String:
	if waiting or phase == Phase.OVER or warning_dead or not _alive(messenger):
		return ""
	if eta() <= near_warn:
		return "near"
	return "relay" if relays > 0 else ""
