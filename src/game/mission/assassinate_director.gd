class_name AssassinateDirector
extends MissionDirector
## The Assassinate type (v0.11 M2, spec §7.1, generalised by the controller's Task 2 ruling to N targets): named targets walk
## their rounds of stops on a schedule, a few soldiers about each; find them and kill them all. Every target starts indoors at
## the hideout (with none, out of doors where the safe place is). Each sets out at his own time -- or, after the first, `chain_wait` seconds after the one before him dies,
## whichever is sooner (the board Warning's stars' rule: no idle wait over 60 s) -- and sooner still if a power is cast by
## the hideout's door while none is out. At each stop he goes indoors for `visit_seconds`, untouchable, then walks on;
## after the last he walks to the safe place, and reaching it is his escape (AssassinateObjective fails). Alarmed -- a loud
## power cast within `alarm_reach` of him in the street, a guard felled, a fright -- he makes for the hideout and hides
## `hide_seconds`, then takes his round up at the stop he was walking to; with the hideout gone he makes for the safe place
## instead. A house he is in set alight or brought down flushes him out in a fright -- a target out on his round or hiding;
## one still waiting at the hideout stays in and sets out at his time (the controller's Task 2 fix ruling). Each death is
## judged as the Procession's Prince's: unseen when nobody living stands within Crowd.DOOM_WITNESS once a cast's other
## victims have fallen; seen, the guards cry murder and the bellkeeper is called. A subclass names the places, the targets and
## the numbers in _plan() (TaxCollectorDirector).

## What a target is doing (v0.11 M2): waiting indoors at the hideout, walking his round, indoors at a stop, fleeing to hide,
## hiding, safe (escaped), dead.
enum State { WAITING, WALKING, VISITING, FLEEING, HIDING, SAFE, DEAD }

## Seconds between looks at the targets (v0.11 M2).
const TICK := 0.5
## How near a door counts as arrived (v0.11 M2).
const ARRIVE := 0.6
## How far a walker's or a guard's place must move before he is sent again (v0.11 M2).
const GUARD_MOVE := 0.3
## How far round a door the guards stand while their target is indoors (v0.11 M2).
const DOOR_GUARD_R := 1.0
## How many of the dwellings nearest a stop's spot _house_reached() weighs before giving up (v0.11 M2).
const HOUSE_TRIES := 12
## The minds a frightened target is in (v0.11 M2).
const FRIGHT := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]
## The minds a guard takes his place again from (v0.11 M2, Decision 20). In any other -- the rally, a fight, the god's hold --
## he is left to it.
const GUARD_MINDS := [Person.Mind.POST, Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## The map tags' colours (v0.11 M2): a target gold, the places orange, the guards steel blue, the safe place and anyone who
## would see a target die red.
const MARK_TARGET := Color("d8b23a")
const MARK_PLACE := Color("ff9a3a")
const MARK_GUARD := Color("8fb8e8")
const MARK_WATCHED := Color("c8342a")


## One target and his round (v0.11 M2): what _plan() gives him (his label, his time, his stops, how many guards) and what the
## night makes of him. A plain record: the director does all the work, so it holds no director back (no reference cycle).
class Quarry:
	extends RefCounted
	## His place in the order (0 first), and the tags' word for him.
	var index := 0
	var label := "TARGET"
	## Seconds into the night he sets out at the latest (the timeline's seconds).
	var set_out_at := 45.0
	## His stops in order, and each one's door.
	var stops: Array[Structure] = []
	var stop_doors: Array[Vector2] = []
	## How many guards walk with him, and who they are. Held as typed, read only through MissionDirector._alive(): either
	## may be a body freed after its death fade.
	var guard_count := 2
	var guards: Array[Person] = []
	var target: Person
	## What he is doing (AssassinateDirector.State).
	var state := 0
	## The stop he walks to or is at (an index into `stops`); stops.size() once he makes for the safe place.
	var leg := 0
	## Seconds he has left indoors at a stop, or hiding.
	var indoors_left := 0.0
	## How many times he was alarmed.
	var alarms := 0
	## One of his guards fell: he is alarmed at the next look, unless he fell in the same blow.
	var guard_fell := false
	## He was killed; the second of the night he fell (-1 alive); where, waiting to be judged once a cast's other victims
	## have fallen too.
	var dead := false
	var died_at := -1.0
	var fell_at := Vector2.INF
	## His death was judged; nobody saw it; the power credited with it ("" for none).
	var judged := false
	var unseen := true
	var killed_by := ""
	## The building he is inside, or null (out of doors, or inside the safe place).
	var inside_of: Structure


## Set by _plan(): the hideout every target starts in (null: none), and the safe place.
var hideout: Structure
var safe_at := Vector2.INF
## Set by _plan(): how long a target stays at a stop and hides, how near a loud cast alarms him, how far from him his guards
## walk, and how long after one dies the next sets out at the latest (v0.11 M2).
var visit_seconds := 25.0
var hide_seconds := 30.0
var alarm_reach := 4.0
var guard_r := 0.6
var chain_wait := 40.0
## Set by _plan(): the tags' words for the hideout, a stop, the safe place, and the next target still indoors while another
## is out (v0.11 M2).
var hideout_label := "HIDEOUT"
var stop_label := "STOP"
var safe_label := "SAFE"
var next_label := "NEXT TARGET"
## The targets in the order they set out (v0.11 M2; _add_quarry() in _plan()).
var quarries: Array[Quarry] = []
## The hideout's door (the safe place's when there is no hideout) (v0.11 M2).
var hide_door := Vector2.INF
## Seconds into the night (v0.11 M2), for the chain rule.
var _clock := 0.0
## Seconds to the next look at the targets (v0.11 M2, TICK).
var _tick_in := 0.0
## How many guards there are in all, for their places round a shared door (v0.11 M2).
var _guard_total := 0


## The night's setup (v0.11 M2): the plan, each target's reachable stops, the targets appointed and taken indoors at the
## hideout, each one's time on the strip, their guards, and the world's signals.
func _begin() -> void:
	_plan()
	hide_door = _front_of(hideout) if hideout != null else _walkable(safe_at)
	safe_at = _walkable(safe_at)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for q in quarries:
		var reached: Array[Structure] = []
		for s in q.stops:
			var door := _open_door(s, hide_door)
			if door != Vector2.INF:
				reached.append(s)
				q.stop_doors.append(door)
		q.stops = reached
		q.target = _appoint_target(q)
		if q.target == null:
			# Nobody to be him (a town with no one left to appoint): counted as already gone, so the night can still be won.
			q.dead = true
			q.judged = true
			q.died_at = 0.0
			q.state = State.DEAD
			continue
		_set_down(q.target, hide_door)
		if hideout != null:
			_go_in(q, hideout)
		timeline.add(q.set_out_at, "out_%d" % q.index, _set_out_label(q), _set_out.bind(q),
			func() -> bool: return q.state == State.WAITING and _alive(q.target))
	var taken: Array = []
	for q in quarries:
		q.guards = _free_soldiers(hide_door, q.guard_count, taken)
		taken.append_array(q.guards)
		_guard_total += q.guards.size()
	_send_guards()
	crowd._field.enemy_killed.connect(_on_killed)
	rules.cast_made.connect(_on_cast)
	rules.banner.emit(_opening_banner())


## Virtual (v0.11 M2): the mission's places and numbers (hideout, safe_at, the seconds, the tags' words), and its targets with
## _add_quarry().
func _plan() -> void:
	pass


## A target for _plan() (v0.11 M2): his tag word, his time, his stops in order and how many guards; appended to `quarries`.
func _add_quarry(label: String, set_out_at: float, stops: Array[Structure], guard_count: int) -> Quarry:
	var q := Quarry.new()
	q.index = quarries.size()
	q.label = label
	q.set_out_at = set_out_at
	q.stops = stops
	q.guard_count = guard_count
	quarries.append(q)
	return q


## A door of `s` someone at `from` can walk to (v0.11 M2): its front (_front_of()), else its back, else a side -- the first
## with a route from `from`; Vector2.INF for none (a house walled in by its neighbours, whose front is a closed yard).
func _open_door(s: Structure, from: Vector2) -> Vector2:
	var half := s.footprint.size * 0.5 + Vector2(0.5, 0.5)
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(s.center() + off)
		if crowd._grid == null or not crowd._grid.path(from, door).is_empty():
			return door
	return Vector2.INF


## The standing dwelling nearest `spot` with a door someone at `from` can walk to (v0.11 M2, for _plan()'s stops): as
## _house_near() chooses, so never reserved nor one of `exclude`; null when none of the HOUSE_TRIES nearest has one.
func _house_reached(spot: Vector2, from: Vector2, exclude: Array = []) -> Structure:
	var skip := exclude.duplicate()
	for i in HOUSE_TRIES:
		var h := _house_near(spot, skip)
		if h == null:
			return null
		if _open_door(h, from) != Vector2.INF:
			return h
		skip.append(h)
	return null


## Virtual (v0.11 M2): who target `q` is tonight; null for none. Never reserved, and never a target already appointed
## (_appointed(): a subclass passes it on too, as a target without a hideout waits out of doors, still eligible). The base takes
## the resident nearest the hideout's door.
func _appoint_target(_q: Quarry) -> Person:
	return _citizen_near(hide_door, CitizenProfile.Role.RESIDENT, _appointed())


## The targets appointed so far (v0.11 M2), for _appoint_target() to leave out.
func _appointed() -> Array:
	var out: Array = []
	for q in quarries:
		if q.target != null:
			out.append(q.target)
	return out


## Virtual (v0.11 M2): the night's opening banner.
func _opening_banner() -> String:
	return "FIND THEM AND KILL THEM"


## Virtual (v0.11 M2): the timeline's words when `q` sets out (the banner is them in capitals).
func _set_out_label(q: Quarry) -> String:
	return "%s sets out" % q.label.capitalize()


## Virtual (v0.11 M2): the banner when `q` is alarmed.
func _hide_banner(q: Quarry) -> String:
	return "%s HIDES" % q.label


## Virtual (v0.11 M2): the banner when a target reaches the safe place.
func _safe_banner() -> String:
	return "HE IS SAFE"


## Virtual (v0.11 M2): the banner when a death is seen.
func _seen_banner() -> String:
	return "THE GUARDS CRY MURDER"


## One step (v0.11 M2): the timeline (each target's own time), the chain (sooner after the one before dies), the deaths still
## to judge, each target indoors, and every TICK a look at each in the street and his guards.
func step(delta: float) -> void:
	_clock += delta
	timeline.step(delta)
	_chain()
	# Judged once the crowd has judged its own doomed (Crowd._settle_doom()), so a cast's victims never witness each other.
	if crowd._doomed.is_empty():
		for q in quarries:
			if q.fell_at != Vector2.INF:
				_judge(q)
	_tick_in -= delta
	var looking := _tick_in <= 0.0
	if looking:
		_tick_in = TICK
	for q in quarries:
		if q.dead or q.state == State.SAFE:
			continue
		if not _alive(q.target):
			_lost(q)
			continue
		if q.inside_of != null:
			_indoors(q, delta)
		if looking:
			_tick(q)
	if looking:
		_send_guards()


## The second into the night target `i` sets out at the latest (v0.11 M2): his own time, or `chain_wait` after the one before
## him died if that is sooner. One before him still alive never brings it forward, and the first is never earlier (a cast at
## the door can still smoke him out).
func out_at(i: int) -> float:
	var at := quarries[i].set_out_at * timeline.stretch_factor()
	if i > 0 and quarries[i - 1].died_at >= 0.0:
		at = minf(at, quarries[i - 1].died_at + chain_wait)
	return at


## Each target still waiting whose chain time has come sets out (v0.11 M2); his own time is the timeline's.
func _chain() -> void:
	for i in range(1, quarries.size()):
		var q := quarries[i]
		if q.state == State.WAITING and quarries[i - 1].died_at >= 0.0 and _clock >= out_at(i) and _alive(q.target):
			rules.banner.emit(_set_out_label(q).to_upper())
			_set_out(q)


## `q` sets out on his round (v0.11 M2: the timeline's event at his time, the chain, or a power cast by the hideout's door).
func _set_out(q: Quarry) -> void:
	if q.state != State.WAITING or not _alive(q.target):
		return
	if q.inside_of != null:
		_come_out(q)
	q.state = State.WALKING
	q.target.go_duty(_leg_goal(q))


## `q`'s body is gone without his death (v0.11 M2: he escaped the town, Crowd.escape()): he got away, as at the safe place.
func _lost(q: Quarry) -> void:
	q.state = State.SAFE
	q.inside_of = null
	rules.banner.emit(_safe_banner())


## `q` indoors (v0.11 M2): waiting for his time, he stays -- even in a hideout alight or fallen, so one fire never sets the
## whole night out at once (the controller's Task 2 fix ruling). Visiting or hiding, the house alight or fallen flushes him out
## in a fright (a stop's visit then counts as done); else his time there runs down and he walks on.
func _indoors(q: Quarry, delta: float) -> void:
	var was := q.state
	if was == State.WAITING:
		return
	var house := q.inside_of
	if not is_instance_valid(house) or house.destroyed or _burning(house):
		var from := house.center() if is_instance_valid(house) else q.target.ground_pos
		_come_out(q)
		if was == State.VISITING:
			q.leg += 1
		q.state = State.WALKING
		q.target.panic(from, 2.0)
		return
	q.indoors_left -= delta
	if q.indoors_left > 0.0:
		return
	_come_out(q)
	if was == State.VISITING:
		q.leg += 1
	q.state = State.WALKING
	q.target.go_duty(_leg_goal(q))


## One look at `q` in the street (v0.11 M2): a fright or a fallen guard alarms him; else he is kept on his way -- to the stop or
## the safe place, or, fleeing, to the hideout.
func _tick(q: Quarry) -> void:
	match q.state:
		State.WALKING:
			if q.target.mind in FRIGHT or q.guard_fell:
				q.guard_fell = false
				_alarm(q)
				return
			_walk(q, _leg_goal(q))
		State.FLEEING:
			_walk(q, _hide_goal())
	q.guard_fell = false


## `q` on his way to `goal` in his own mind (on duty, back on his feet, or -- fleeing -- frightened) (v0.11 M2): arrived, he
## does what his state asks; else he is kept walking to it. Held by the god (whispered, confused) he is left be.
func _walk(q: Quarry, goal: Vector2) -> void:
	var t := q.target
	var own := t.mind == Person.Mind.DUTY or t.mind in WarningDirector.RESUMABLE \
		or (q.state == State.FLEEING and t.mind in FRIGHT)
	if not own:
		return
	if t.ground_pos.distance_to(goal) <= ARRIVE:
		_arrive(q)
		return
	if t.mind != Person.Mind.DUTY or t.anchor.distance_to(goal) > GUARD_MOVE:
		t.go_duty(goal)


## `q` arrived (v0.11 M2): fleeing, he hides (or, with no hideout standing, he is safe); at a stop he goes in, unless its house
## is down or burning (then that stop is skipped); past the last stop, he is safe.
func _arrive(q: Quarry) -> void:
	if q.state == State.FLEEING:
		if _hideout_stands():
			_go_in(q, hideout)
			q.state = State.HIDING
			q.indoors_left = hide_seconds
		else:
			_reach_safe(q)
		return
	if q.leg >= q.stops.size():
		_reach_safe(q)
		return
	var s := q.stops[q.leg]
	if not is_instance_valid(s) or s.destroyed or _burning(s):
		q.leg += 1
		return
	_go_in(q, s)
	q.state = State.VISITING
	q.indoors_left = visit_seconds


## `q` reaches the safe place (v0.11 M2): indoors there for good, and the night is lost (AssassinateObjective fails).
func _reach_safe(q: Quarry) -> void:
	q.state = State.SAFE
	q.inside_of = null
	_take_inside(q.target, null)
	rules.banner.emit(_safe_banner())


## `q` alarmed in the street (v0.11 M2): he makes for the hideout (or the safe place, with none standing).
func _alarm(q: Quarry) -> void:
	if q.state != State.WALKING:
		return
	q.state = State.FLEEING
	q.alarms += 1
	rules.banner.emit(_hide_banner(q))
	q.target.go_duty(_hide_goal())


## A power cast (Rules.cast_made, v0.11 M2): by the hideout's door while no target is out, it smokes the next one out; a loud
## one near a target in the street alarms him. Quiet powers never alarm.
func _on_cast(slot: int, _key: String, at: Vector2) -> void:
	if not _anyone_out():
		var next := _next_waiting()
		if next != null and at.distance_to(hide_door) <= alarm_reach:
			rules.banner.emit(_set_out_label(next).to_upper())
			_set_out(next)
		return
	if bool(rules.power(slot).get("quiet", false)):
		return
	for q in quarries:
		if q.state == State.WALKING and _alive(q.target) and at.distance_to(q.target.ground_pos) <= alarm_reach:
			_alarm(q)


## A death in the field (v0.11 M2): a target falls (judged once the cast's other victims have fallen too); a guard falls, and
## his target is alarmed at the next look.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	for q in quarries:
		# Variant: a target's body may be freed by now; comparing it is safe, passing it on as a Person is not.
		var t: Variant = q.target
		if not q.dead and t == e:
			q.dead = true
			q.died_at = _clock
			q.fell_at = e.ground_pos
			q.killed_by = rules.credited_key(kind)
			q.state = State.DEAD
			q.inside_of = null
			_release_guards(q)
			return
	for q in quarries:
		for g: Variant in q.guards:
			if g == e and not q.dead and _alive(q.target):
				q.guard_fell = true
				return


## `q`'s death judged (v0.11 M2): unseen with nobody living within Crowd.DOOM_WITNESS; seen, the guards cry murder and the
## bellkeeper is called (on the board a bell rung after the main objective catches the night, its wishes lost).
func _judge(q: Quarry) -> void:
	var at := q.fell_at
	q.fell_at = Vector2.INF
	q.unseen = crowd.nearest_witness(at) == null
	q.judged = true
	if not q.unseen:
		rules.banner.emit(_seen_banner())
		if crowd.bell != null and crowd.bell.state == BellNetwork.State.IDLE:
			crowd.bell.call_keeper()


## Each guard sent to his place (v0.11 M2): on a ring of `guard_r` round his target in the street, of DOOR_GUARD_R round the
## door his target is in (one ring for every guard, so those at a shared door stand apart). A guard reserved, of a corps, or
## in a mind not his own (GUARD_MINDS) is left be; so are a dead or safe target's.
func _send_guards() -> void:
	var slot := 0
	for q in quarries:
		var base := slot
		slot += q.guards.size()
		if q.dead or q.state == State.SAFE or not _alive(q.target):
			continue
		var out := not q.target.inside
		var hurried := q.state == State.FLEEING
		for i in q.guards.size():
			var g: Variant = q.guards[i]
			if not _alive(g) or reserved.has(g):
				continue
			var p := g as Person
			if p.corps != Person.Corps.NONE or not p.mind in GUARD_MINDS:
				continue
			var spot := _ring_spot(q.target.ground_pos, guard_r, i, q.guards.size(), 0.5) if out \
				else _ring_spot(_door_in(q), DOOR_GUARD_R, base + i, _guard_total, 0.5)
			if p.anchor.distance_to(spot) > GUARD_MOVE:
				p.send_to_post(spot, false, hurried)


## A dead target's guards go back to their own posts (v0.11 M2), unless the town has them (GUARD_MINDS) or they have none.
func _release_guards(q: Quarry) -> void:
	for g: Variant in q.guards:
		if not _alive(g):
			continue
		var p := g as Person
		if p.corps == Person.Corps.NONE and p.mind in GUARD_MINDS and p.post != Vector2.INF:
			p.send_to_post(p.post)


## `q` goes into `s` (v0.11 M2).
func _go_in(q: Quarry, s: Structure) -> void:
	q.inside_of = s
	_take_inside(q.target, s)


## `q` comes out at the door of the house he is in (v0.11 M2).
func _come_out(q: Quarry) -> void:
	var door := _door_in(q)
	q.inside_of = null
	_bring_out(q.target, door)


## The door of the house `q` is in (v0.11 M2): the hideout's or a stop's; where he stands when in none.
func _door_in(q: Quarry) -> Vector2:
	if q.inside_of == null:
		return q.target.ground_pos
	if q.inside_of == hideout:
		return hide_door
	var i := q.stops.find(q.inside_of)
	return q.stop_doors[i] if i >= 0 else q.target.ground_pos


## Where `q`'s round takes him next (v0.11 M2): the stop he walks to, or the safe place.
func _leg_goal(q: Quarry) -> Vector2:
	return q.stop_doors[q.leg] if q.leg < q.stops.size() else safe_at


## Where an alarmed target flees to (v0.11 M2): the hideout while it stands unburnt, else the safe place.
func _hide_goal() -> Vector2:
	return hide_door if _hideout_stands() else safe_at


## The hideout stands, unburnt (v0.11 M2).
func _hideout_stands() -> bool:
	return hideout != null and is_instance_valid(hideout) and not hideout.destroyed and not _burning(hideout)


## `q` is alarmed with no hiding place left (v0.11 M2, final review): he flees, and the hideout is gone or alight, so he runs for
## the safe place -- where arriving loses the night. Only reads.
func fleeing_to_safe(q: Quarry) -> bool:
	return q.state == State.FLEEING and not _hideout_stands()


## `s` is on fire (v0.11 M2).
func _burning(s: Structure) -> bool:
	return crowd.fires != null and crowd.fires.is_burning(s)


## `q` is on his round or hiding from it (v0.11 M2): set out, neither dead nor safe.
func _is_out(q: Quarry) -> bool:
	return q.state in [State.WALKING, State.VISITING, State.FLEEING, State.HIDING]


## Some target is out (v0.11 M2).
func _anyone_out() -> bool:
	for q in quarries:
		if _is_out(q):
			return true
	return false


## The first target still waiting at the hideout (v0.11 M2), or null.
func _next_waiting() -> Quarry:
	for q in quarries:
		if q.state == State.WAITING:
			return q
	return null


## The target the HUD speaks of (v0.11 M2): the first one out, else the next still waiting; null once none is left.
func current() -> Quarry:
	for q in quarries:
		if _is_out(q):
			return q
	return _next_waiting()


## How many targets are dead (v0.11 M2).
func killed() -> int:
	var n := 0
	for q in quarries:
		n += 1 if q.dead else 0
	return n


## Every target is dead (v0.11 M2): AssassinateObjective is done.
func all_fallen() -> bool:
	return not quarries.is_empty() and killed() == quarries.size()


## Some target reached the safe place (v0.11 M2): AssassinateObjective fails.
func any_safe() -> bool:
	for q in quarries:
		if q.state == State.SAFE:
			return true
	return false


## Everyone who would see `q` (the current target when null) die by a Silent Doom cast on him (v0.11 M2): living, out of doors,
## within Crowd.DOOM_WITNESS of him but beyond SilentDoom.RADIUS (those nearer fall with him). Only reads.
func witnesses(q: Quarry = null) -> Array[Person]:
	var out: Array[Person] = []
	var w := q if q != null else current()
	if w == null or w.dead or not _alive(w.target) or w.target.inside:
		return out
	var at := w.target.ground_pos
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != w.target and p.is_alive() and not p.inside:
				var d := p.ground_pos.distance_to(at)
				if d <= Crowd.DOOM_WITNESS and d > SilentDoom.RADIUS:
					out.append(p)
	return out


## The map tags, most important first (v0.11 M2):
## - each target out, pointed at from the edge -- over the door of the house he is in while indoors; with none out, the next
##   one still waiting, over the hideout's door;
## - the hideout while it stands;
## - each target out's stop (or the safe place once his round is done, or he runs for it with no hiding place: then pointed at
##   from the edge); with none out, the next one's first stop;
## - with one out and another still waiting, the next one at the hideout's door (`next_label`);
## - round each target in the street, a red diamond on each person who would see him die, and a blue one on each guard who
##   would not.
## None once every target is dead, or one is safe.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if current() == null or any_safe():
		return out
	var walking: Array[Quarry] = []
	for q in quarries:
		if _is_out(q) and _alive(q.target):
			walking.append(q)
	var next := _next_waiting()
	if next != null and not _alive(next.target):
		next = null
	for q in walking:
		out.append(_target_tag(q))
	if walking.is_empty() and next != null:
		out.append(_target_tag(next))
	if _hideout_stands():
		out.append(MapTag.place(hideout.center(), MARK_PLACE, hideout_label, hideout.height, false))
	for q in walking:
		_place_tag(q, out)
	if walking.is_empty() and next != null:
		_place_tag(next, out)
	elif next != null:
		out.append(MapTag.place(hide_door, MARK_PLACE, next_label, 0.0, false))
	for q in walking:
		if q.target.inside:
			continue
		var seeing := witnesses(q)
		for p in seeing:
			out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
		for g: Variant in q.guards:
			if _alive(g) and not (g as Person).inside and not seeing.has(g):
				out.append(MapTag.person((g as Person).ground_pos, MARK_GUARD))
	return out


## `q`'s own tag (v0.11 M2): on him out of doors, over the door he is behind indoors.
func _target_tag(q: Quarry) -> MapTag:
	if q.target.inside:
		return MapTag.place(_door_in(q), MARK_TARGET, q.label + " - INSIDE", 0.0, true)
	return MapTag.person(q.target.ground_pos, MARK_TARGET, q.label, true)


## The place `q` is bound for, appended to `out` (v0.11 M2): his stop while it stands, or the safe place once his round is done --
## and the safe place, pointed at from the screen's edge, while he runs for it with no hiding place (fleeing_to_safe(), final
## review: his next stop is no longer where he is bound). One tag to the safe place, however many head there.
func _place_tag(q: Quarry, out: Array[MapTag]) -> void:
	var running := fleeing_to_safe(q)
	if q.leg < q.stops.size() and not running:
		var s := q.stops[q.leg]
		if is_instance_valid(s) and not s.destroyed:
			out.append(MapTag.place(s.center(), MARK_PLACE, stop_label, s.height, false))
		return
	for m in out:
		if m.label == safe_label and m.edge == running:
			return
	out.append(MapTag.place(safe_at, MARK_WATCHED, safe_label, 0.0, running))


## The hint's phase (v0.11 M2), for the current target: "running" while he flees with no hiding place, for the safe place (final
## review); "hiding" while he flees to the hideout or hides in it; "inside" while he is indoors at a stop, or waits for the first
## set-out; "next" while he waits after another has died; "safe" once he makes for the safe place; else "". "" once none is left.
func hint_phase() -> String:
	var q := current()
	if q == null or not _alive(q.target):
		return ""
	if fleeing_to_safe(q):
		return "running"
	match q.state:
		State.FLEEING, State.HIDING:
			return "hiding"
		State.VISITING:
			return "inside"
		State.WAITING:
			return "next" if killed() > 0 else "inside"
	return "safe" if q.leg >= q.stops.size() else ""


## The results' report (v0.11 M2): how the night ended for the targets ("escaped" if one got away; with all dead, "seen" if any
## death was seen, else "unseen"; else "alive"), how many died and how many of those were seen, and the alarms.
func report() -> Dictionary:
	var seen := 0
	var alarms := 0
	for q in quarries:
		seen += 1 if q.dead and q.judged and not q.unseen else 0
		alarms += q.alarms
	var how := "alive"
	if any_safe():
		how = "escaped"
	elif all_fallen():
		how = "seen" if seen > 0 else "unseen"
	return {"target": how, "killed": killed(), "seen": seen, "alarms": alarms}


## Lets go of the field's deaths, the casts and the timeline (v0.11 M2).
func teardown() -> void:
	_unhook_kills(_on_killed)
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	timeline = null  # its banner and guard lambdas hold this director: let both go
