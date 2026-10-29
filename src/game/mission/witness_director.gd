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

## Two mates' heel places that the walkable ground has snapped closer than two Silent Doom radii plus this are moved wider (MS §0: the pair stands
## more than 1.6 apart, so one Doom never takes both).
const SW_HEEL_MARGIN := 0.05
## The tries when the usual places do not fit: how much farther behind (negative: nearer) and how much wider.
const SW_HEEL_GAPS := [0.0, 0.2, -0.2, 0.4, -0.4]
const SW_HEEL_SIDES := [0.0, 0.15, -0.15, 0.3, 0.45]

## The share of his pace the witness walks at (SilenceWitnessDirector.SW_WITNESS_PACE), set before setup().
var witness_pace := 0.65
## At this many mission seconds from the Temple's door the banner `A WITNESS NEARS THE TEMPLE` shows once (SW_NEAR_WARN), set before setup().
var near_warn := 15.0
## Word has reached the Temple: the messenger, alive and out of doors, came within TempleReport.REACH of its door. The night is lost on it.
var in_temple := false
## Everyone whose pace is already the witness's (by instance id): none is slowed twice.
var _slowed_ids := {}
## The messenger the warning banner was last shown for (a Variant: he may be a body freed after his death fade).
var _warned_for: Variant = null
## The Temple's door, found once (it does not move in a night).
var _temple := Vector2.INF
## His mates who could carry the word on, as the witness fell (alive, out of doors, within Crowd.DOOM_WITNESS, not held by the god): taken at the death,
## before the town's fright can lift a hold, and kept until _judge() picks from them.
var _saw: Array = []
## Seconds to the next look at the distance to the Temple.
var _near_in := 0.0


## The witness walks at his share of the pace once he is sent (MS §3: `SW_WITNESS_PACE`).
func set_out() -> void:
	var was_waiting := waiting
	super()
	if was_waiting and _alive(watchman):
		_slow(watchman)


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
## none out of doors.
func eta() -> float:
	if waiting or warning_dead or phase == Phase.OVER or not _alive(messenger) or messenger.inside:
		return INF
	var rate := rules.clock_rate if rules != null else 1.0
	if messenger.has_goal() and not messenger._path.is_empty():
		return TempleReport.walk_seconds(messenger, _door()) * rate
	# Standing at his door (the stare), or between two walks: the street's length, not the straight line.
	var path := crowd._grid.path(messenger.ground_pos, _door()) if crowd._grid != null else PackedVector2Array()
	var left := 0.0
	var at := messenger.ground_pos
	for q in path:
		left += at.distance_to(q)
		at = q
	if path.is_empty():
		left = at.distance_to(_door())
	return left / maxf(Person.PANIC_SPEED * messenger.pace, 0.05) * rate


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


## Where mate `k` walks from a witness at `at` going `dir` (RingerDirector._heel(): the gap behind him, the side to his side), with the pair kept more
## than two Silent Doom radii apart and each within sight of him (SW_HEEL_*) where the walkable ground (cells of 0.5) has snapped the usual places
## otherwise: the nearest pair of places, a little nearer or farther behind and wider, that fits. Both mates search alike, so they agree on the pair.
func _heel(at: Vector2, dir: Vector2, k: int) -> Vector2:
	var nominal := [_heel_at(at, dir, 0, 0.0, 0.0), _heel_at(at, dir, 1, 0.0, 0.0)]
	if tune_mates != 2 or k > 1 or _pair_fits(at, nominal[0], nominal[1]):
		return nominal[k] if k <= 1 else super(at, dir, k)
	var best := nominal
	var best_score := INF
	for far: float in SW_HEEL_GAPS:
		for wide: float in SW_HEEL_SIDES:
			var a := _heel_at(at, dir, 0, far, wide)
			var b := _heel_at(at, dir, 1, far, wide)
			if _pair_fits(at, a, b):
				var score := absf(a.distance_to(b) - 2.0 * tune_mate_side) + absf(far) * 0.5
				if score < best_score:
					best = [a, b]
					best_score = score
	return best[k]


## The two heel places `a` and `b` of a witness at `at` stand more than two Silent Doom radii apart (plus SW_HEEL_MARGIN) and each within
## Crowd.DOOM_WITNESS (less SW_HEEL_MARGIN) of him.
func _pair_fits(at: Vector2, a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) > 2.0 * SilentDoom.RADIUS + SW_HEEL_MARGIN and a.distance_to(at) <= Crowd.DOOM_WITNESS - SW_HEEL_MARGIN \
		and b.distance_to(at) <= Crowd.DOOM_WITNESS - SW_HEEL_MARGIN


## Mate `k`'s heel place with the gap `far` farther behind and the side `wide` wider (the base's _heel() with both at 0).
func _heel_at(at: Vector2, dir: Vector2, k: int, far: float, wide: float) -> Vector2:
	var side := tune_mate_side + wide if k % 2 == 0 else -(tune_mate_side + wide)
	return _walkable(at - dir * (tune_mate_gap + far) + dir.orthogonal() * side)


## W1 (shared rule 1), in the witness's words: out of the walls he is stopped and walks on off the map.
func _out_of_walls() -> bool:
	if not _alive(messenger) or messenger.inside or not Walls.outside(messenger.ground_pos):
		return false
	var gone := messenger
	_end("out")
	send_off(gone)
	rules.banner.emit("THE WITNESS LEAVES TOWN")
	return true


## The map tags out of doors, most important first: the witness (gold, pointed at from the edge) with the time to the Temple, then each of his mates
## who is out of doors (red, pointed at). No bellkeeper and no bell-tower tag (MS §3). None while they wait, or once he is stopped.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if waiting or phase == Phase.OVER or warning_dead or not _alive(messenger) or messenger.inside:
		return out
	out.append(MapTag.person(messenger.ground_pos, MARK_MESSENGER, "WITNESS - TEMPLE IN %s" % UiTheme.clock(eta()), true))
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
