class_name RingerDirector
extends WarningDirector
## One watch post's warning in The Bell-Ringers (v0.11 M3, mission spec §1, Decisions 3, 6, 7): The Warning's carrier, relay and
## unseen kill, with a ringer and his MATES at a wall tower's door in place of a watchman at a gate. They are the lay citizens
## nearest the door, made watchmen and kept inside the tower (hidden, untouchable) until BellRingersDirector sends them
## (set_out()); out of doors they stand OUT_PAUSE to light their lanterns -- WarningDirector's stare, with no star -- then the
## ringer runs for the bell's foot, his mates at his heels. He never seeks the keeper (_rings_himself()): at the foot he takes the
## rope himself and climbs the town's climb x1.5. One rope: a carrier who finds it taken waits at the foot, and one pulled off it
## loses his place to the carrier waiting. Stopped on the rope, the bell goes back to its own keeper, idle (BellNetwork.restore()),
## and is called again if the town is at Local Emergency. A relay never picks another warning's people (`claimed`).

## How many mates run with the ringer (v0.11 M3, Decision 6): the spec's first guess 2, tuned to 1 by Task 2's gate (its round 1:
## with two, the scripted player stopped no warning in three nights; the spec's range is 1-2).
const MATES := 1
## How far behind the carrier the mates run (v0.11 M3, Decision 6): with MATE_SIDE, about 1.4 off him -- beyond one Silent Doom of
## him, within Crowd.DOOM_WITNESS. A first guess, kept by Task 2's gate.
const MATE_GAP := 1.2
## How far to either side of the carrier's way the mates run (v0.11 M3, Decision 6): two mates run 2 x MATE_SIDE apart, so one Doom
## between them takes both.
const MATE_SIDE := 0.7
## Seconds the ringer and his mates stand at the door to light their lanterns before the ringer runs (v0.11 M3, Decision 8).
const OUT_PAUSE := 3.0
## Seconds between looks at the mates (v0.11 M3).
const MATE_TICK := 0.5
## How near the carrier a mate counts as with him, for his tag and the hint (v0.11 M3).
const WITH_HIM := 3.0
## How many spots round the door are tried for the mates to stand on (v0.11 M3, _door_spots()).
const DOOR_RING := 16
## How far inside Crowd.DOOM_WITNESS of the ringer the mates stand at the door, for his first steps (v0.11 M3, _door_spots()).
const DOOR_MARGIN := 0.3

## The post's tower (v0.11 M3), set before setup().
var tower: Structure
## The bell's own keeper to give the rope back to (v0.11 M3), set before setup(); a Variant: he may be a body freed after his
## death fade.
var own_keeper: Variant = null
## The mates (v0.11 M3), held as Variants: any may be a body freed after its death fade.
var mates: Array = []
## Still inside the tower, waiting to be sent (v0.11 M3).
var waiting := true
## Who the other warnings own (v0.11 M3, controller ruling): set by BellRingersDirector before setup(), it returns an Array of
## their ringers, carriers and mates (as Variants), whom this warning's relay never picks nor its tags mark. None if not set.
var claimed := Callable()
## The bell was looked at once this warning died (v0.11 M3, _give_back()).
var _restored := false
## Seconds to the next look at the mates (v0.11 M3).
var _mate_in := 0.0


## The Warning's setup (v0.11 M3), then: with nobody to send, the warning counts as stopped, so the night can still be won.
func _begin() -> void:
	super()
	if watchman == null:
		warning_dead = true
		phase = Phase.OVER
		waiting = false


## The ringer and his mates (v0.11 M3, Decision 6): the 1 + MATES lay citizens nearest the post's door (none reserved), made
## watchmen -- the watch cloak and lantern -- and taken inside the tower. Returns the ringer; null with nobody to spare.
func _appoint_watchman() -> Person:
	var crew := _lay_near(gate_spot, 1 + MATES)
	if crew.is_empty():
		return null
	for p in crew:
		p.profile.role = CitizenProfile.Role.WATCHMAN
		p.profile.work = gate_spot
		_take_inside(p, tower)
	for i in range(1, crew.size()):
		mates.append(crew[i])
	return crew[0]


## The post sends its ringer (v0.11 M3): the ringer and his mates come out at the door and stand -- the ringer on the doorstep,
## his mates either side of him (_door_spots(): beyond one Silent Doom of him and within sight, Decision 6, so one strike at the
## door never ends it); WarningDirector's stare runs its last OUT_PAUSE, then the ringer runs. Once only.
func set_out() -> void:
	if not waiting:
		return
	waiting = false
	if _alive(watchman):
		_bring_out(watchman, gate_spot)
		_set_down(watchman, gate_spot)
	var spots := _door_spots(gate_spot)
	for k in mates.size():
		var v: Variant = mates[k]
		if not _alive(v):
			continue
		var at := spots[k] if k < spots.size() else gate_spot
		_bring_out(v as Person, at)
		_set_down(v as Person, at)
	omen_fallen = true
	phase = Phase.STARE
	_clock = OMEN_AT + STARE - OUT_PAUSE


## No star falls (v0.11 M3): set_out() starts the warning.
func _omen() -> void:
	omen_fallen = true


## The bell's foot: the keeper is never his goal (v0.11 M3, Decision 7).
func _goal() -> Vector2:
	return crowd.bell.foot if crowd.bell != null else Vector2.INF


## He rings it himself (v0.11 M3).
func _rings_himself() -> bool:
	return true


## At the foot (v0.11 M3, Decision 7): he takes the rope -- unless it is taken (the bell called or climbed by a living keeper on
## duty who is not him): then he waits at the foot, and _run() asks again at its next look.
func _take_rope() -> void:
	var bell := crowd.bell
	if bell == null:
		return
	var on_rope: Variant = bell.keeper
	if _alive(on_rope) and on_rope != messenger and (on_rope as Person).mind == Person.Mind.DUTY \
			and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
		return
	super()


## The people this warning owns (v0.11 M3): its ringer, its carrier and its mates, as Variants (any may be a body freed after
## its death fade). Only reads.
func crew() -> Array:
	var out: Array = [watchman, messenger]
	out.append_array(mates)
	return out


## The other warnings' people (v0.11 M3, controller ruling): `claimed`'s answer, or none.
func _others() -> Array:
	return claimed.call() if claimed.is_valid() else []


## Who carries the warning on from a death seen at `at` (v0.11 M3, controller ruling): the nearest living witness out of doors
## within Crowd.DOOM_WITNESS (Crowd.nearest_witness()'s rule) who is none of the other warnings' people -- so one kill never
## stops two warnings, and no man takes orders from two directors; null for none, and the warning dies.
func _relay_witness(at: Vector2) -> Person:
	var others := _others()
	var best: Person = null
	var best_d := Crowd.DOOM_WITNESS
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside or others.has(p):
				continue
			var d := p.ground_pos.distance_to(at)
			if d <= best_d:
				best = p
				best_d = d
	return best


## Everyone who would see the carrier die and carry the warning on (v0.11 M3): WarningDirector's witnesses but the other
## warnings' people, whom the relay passes over (_relay_witness()). Only reads.
func witnesses() -> Array[Person]:
	var others := _others()
	var out: Array[Person] = []
	for p in super():
		if not others.has(p):
			out.append(p)
	return out


## One step (v0.11 M3): nothing while they wait inside; else The Warning's step, then the rope lost while he was pulled off
## (back to the foot, to wait his turn), the bell given back once the warning dies, and every MATE_TICK a look at the mates.
func step(delta: float) -> void:
	if waiting:
		return
	super(delta)
	var bell := crowd.bell
	if phase == Phase.DELIVERED and bell != null and _alive(messenger) and bell.keeper != messenger \
			and not bell.state in [BellNetwork.State.RUNG, BellNetwork.State.SILENCED]:
		phase = Phase.RUN
		_retarget_in = RETARGET
	if warning_dead and not _restored:
		_restored = true
		_give_back()
		_stand_down_mates()
	_mate_in -= delta
	if _mate_in <= 0.0:
		_mate_in = MATE_TICK
		_step_mates()


## The warning died (v0.11 M3, Decision 7): if a stand-in held the rope and no longer stands -- its carrier, stopped on it -- the
## bell goes back to its own keeper, idle; and if the town is at Local Emergency, whose call the bell could not take while the
## stand-in held it, the keeper is called again (controller ruling, review focus 2).
func _give_back() -> void:
	var bell := crowd.bell
	if bell == null:
		return
	var on_rope: Variant = bell.keeper
	if on_rope == own_keeper or _alive(on_rope):
		return
	bell.restore(own_keeper)
	if _alive(own_keeper) and crowd.alarms.stage >= AlarmManager.Stage.LOCAL_EMERGENCY:
		bell.call_keeper()


## The mates go back to their day once the warning is dead (v0.11 M3).
func _stand_down_mates() -> void:
	for v: Variant in mates:
		if _alive(v) and (v as Person).mind == Person.Mind.DUTY:
			crowd.off_duty(v as Person)


## The mates run at the carrier's heels (v0.11 M3, mission spec §1): each on his own feet -- on duty, or back on them -- is sent to
## his place MATE_GAP behind the carrier and MATE_SIDE to his side of the way to the bell; one frightened, whispered or confused
## falls behind, and runs to catch up once back on his feet. A mate who now carries the warning is no longer a mate.
func _step_mates() -> void:
	mates = mates.filter(func(v: Variant) -> bool: return is_instance_valid(v) and v != messenger)
	if (phase != Phase.RUN and phase != Phase.DELIVERED) or not _alive(messenger) or messenger.inside:
		return
	var ahead := _goal() - messenger.ground_pos
	var dir := ahead.normalized() if ahead.length() > 0.01 else Vector2.UP
	for i in mates.size():
		var v: Variant = mates[i]
		if not _alive(v):
			continue
		var p := v as Person
		if p.inside or not (p.mind == Person.Mind.DUTY or _resumable(p)):
			continue
		var spot := _heel(messenger.ground_pos, dir, i)
		if p.mind != Person.Mind.DUTY or p.anchor.distance_to(spot) > RETARGET_MOVE:
			p.go_duty(spot)


## Where mate `k` runs from a carrier at `at` going `dir` (v0.11 M3, mission spec §1): MATE_GAP behind him and MATE_SIDE to his
## side -- the first mate on one side, the second on the other -- on walkable ground.
func _heel(at: Vector2, dir: Vector2, k: int) -> Vector2:
	var side := MATE_SIDE if k % 2 == 0 else -MATE_SIDE
	return _walkable(at - dir * MATE_GAP + dir.orthogonal() * side)


## Where the mates stand at the door by the ringer at `at` (v0.11 M3, Decision 6): of DOOR_RING walkable spots round him at
## MATE_GAP, those beyond one Silent Doom of him and within sight (DOOM_WITNESS less DOOR_MARGIN), the two farthest apart -- one
## either side of him, where the ground allows (a wall tower's door may open on a narrow lane); fewer if fewer fit.
func _door_spots(at: Vector2) -> Array[Vector2]:
	var fit: Array[Vector2] = []
	for k in DOOR_RING:
		var g := _walkable(at + Vector2.from_angle(TAU * float(k) / float(DOOR_RING)) * MATE_GAP)
		var gap := g.distance_to(at)
		if gap > SilentDoom.RADIUS and gap <= Crowd.DOOM_WITNESS - DOOR_MARGIN and not fit.has(g):
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


## The mates still with the carrier (v0.11 M3): standing, out of doors, within WITH_HIM of him. Only reads.
func mates_with() -> Array[Person]:
	var out: Array[Person] = []
	if waiting or not _alive(messenger) or messenger.inside:
		return out
	for v: Variant in mates:
		if _alive(v) and v != messenger and not (v as Person).inside \
				and (v as Person).ground_pos.distance_to(messenger.ground_pos) <= WITH_HIM:
			out.append(v as Person)
	return out


## The map tags of a warning out of doors (v0.11 M3, mission spec §1), most important first: its carrier, pointed at from the
## edge -- RINGER, or RINGER - CLIMBING on the rope; MATE on each mate with him; a red diamond on everyone else who would see him
## die (witnesses()). None while they wait inside, or once the warning is dead.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if waiting or phase == Phase.OVER or warning_dead or not _alive(messenger) or messenger.inside:
		return out
	var bell := crowd.bell
	var climbing := bell != null and bell.keeper == messenger and bell.state == BellNetwork.State.CLIMBING
	out.append(MapTag.person(messenger.ground_pos, MARK_MESSENGER, "RINGER - CLIMBING" if climbing else "RINGER", true))
	var with_him := mates_with()
	for p in with_him:
		out.append(MapTag.person(p.ground_pos, MARK_WATCHED, "MATE"))
	for p in witnesses():
		if not with_him.has(p):
			out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
	return out


## The hint's phase of a warning out of doors (v0.11 M3): "climbing" on the rope, "relay" while a witness carries it on, "mates"
## while a mate is with the carrier, else "". "" while waiting, or once dead.
func hint_phase() -> String:
	if waiting or phase == Phase.OVER or warning_dead:
		return ""
	if phase == Phase.DELIVERED:
		return "climbing"
	if relays > 0:
		return "relay"
	return "mates" if not mates_with().is_empty() else ""


## No tour of its own: BellRingersDirector shows the posts (v0.11 M3).
func tour() -> Array:
	return []
