class_name TaxCollectorDirector
extends AssassinateDirector
## The Tax Collector (v0.11 M2, Tier 1, spec §1 and §8 row 2, as the controller's Task 2 ruling reshapes it): three collectors
## -- the tax collector and his two deputies, the residents nearest the counting-house, made nobles for the night so their
## capes and crowns pick them out -- count in the counting-house (the workshop hall, east quarter) with their guards at its
## door. The collector walks his round of three debtors' houses from 0:35; the first deputy walks two debtors', the second three,
## each at his own time, or CHAIN_WAIT (45 s) after the one before him dies, whichever is sooner. VISIT_SECONDS (20 s) indoors at
## each debtor, then each takes the taxes to the Citadel's gate, which loses the night. Alarmed one hides 30 s in the counting-house;
## set alight or brought down (v0.11.1), it empties: everyone inside it, those still waiting too, bursts out in a fright and runs for
## the Citadel's gate (FLUSH_GAP seconds apart), and no collector is sent from it again. All three dead wins; a seen kill calls the
## bell (AssassinateDirector._judge()).

## The counting-house is the building with this art tag (v0.11 M2).
const COUNTING_TAG := &"workshop"
## Each collector's debtors live in the dwellings nearest these points whose doors the street reaches (_house_reached()), in
## his order (v0.11 M2): the collector's the south-east quarter by the gate plaza, the south-west and the west (spec §1); the
## first deputy's the north-east and the north-west blocks; the second deputy's the east block by the barracks and the south
## quarter.
const ROUNDS := [
	[Vector2(6.5, 11.5), Vector2(-8.0, 11.5), Vector2(-10.0, 2.5)],
	[Vector2(6.0, -10.4), Vector2(-3.4, -10.4)],
	[Vector2(6.2, 5.4), Vector2(-3.5, 12.5), Vector2(-7.6, 5.4)],
]
## The tags' words for each collector (v0.11 M2).
const LABELS := ["TAX COLLECTOR", "DEPUTY", "DEPUTY"]
## Aldermere's Citadel gate, RescueWish.GATE (v0.11 M2); the director reads the place citadel_gate (Places.point()).
const CITADEL_GATE := RescueWish.GATE
## First guesses (spec §1 and the ruling), tuned in this order if the scripted clear misses its window (v0.11 M2): when each
## collector sets out at the latest; how long after one dies the next sets out at the latest (30-50 s); a visit; a hiding;
## the alarm's reach; how many guards walk with each, and how near.
## v0.11.1 (ruling R4, the no-waiting rule): the collector at 0:35 (was 0:45) and no wait over 60 s (the deputies by 1:35 and 2:35), a visit
## 20 s (was 15) so the scripted clear stays in its window; the gate's numbers are in the v0.11.1 commit.
const SET_OUT_AT := [35.0, 95.0, 155.0]
const CHAIN_WAIT := 45.0
const VISIT_SECONDS := 20.0
const HIDE_SECONDS := 30.0
const ALARM_REACH := 4.0
const GUARDS := [2, 1, 1]
const GUARD_R := 0.6
## v0.11.1 (spec §5): seconds between one waiting collector's burst from a burning counting-house and the next's. 0.0 is "at once";
## the first knob if one strike at the door clears all three (1.5, at most 3.0).
const FLUSH_GAP := 1.5
## The one banner when the counting-house burns or falls with collectors inside (v0.11.1).
const FLUSH_BANNER := "THE COUNTING-HOUSE BURNS - THE COLLECTORS RUN"
## God T1R (spec 5.2, D17): the debtors' mob. A collector bound by a sealed Leaving Is Prohibited (NoLeaveFx.bound) whose centre is within
## MOB_DOOR_R of the door of a debtor he has gone in at tonight, out of doors, with none of his guards (alive, out of doors) within MOB_GUARD_R of him,
## for MOB_AFTER seconds, is mobbed by that house's debtors: he dies (kind &"mob", credited to "noleave"), judged unseen -- the debtors
## raise no cry. His guards must be drawn off first (The Bell Lies, CALL THE GUARD). First guesses, tuned in this order: the policy,
## then MOB_GUARD_R 1.5 -> 1.0, then MOB_AFTER 3 -> 2.
const MOB_DOOR_R := 3.0
const MOB_GUARD_R := 1.5
const MOB_AFTER := 3.0
## How many lay citizens nearest the door are sent to stand round the collector for the mob (the sight of it; the kill does not wait on them).
const MOB_CROWD := 3
const MOB_BANNER := "THE DEBTORS MOB THE COLLECTOR"
## The banner when a collector is stopped out of the walls (spec 2.1).
const OUT_BANNER := "A COLLECTOR LEAVES TOWN - HIS TAXES ARE LOST"


## The town's places and numbers (v0.12, spec 1.5): seeded from the consts above, which are Aldermere's; a town's overrides replace
## them. The counting-house is the building with `counting_tag`, else the dwelling nearest `counting_spot` (INF: the workshop place's
## centre); `set_out_at` reads in the tour's words too.
## The names a town's overrides may set (Overrides): these vars and the base's numbers seeded in _init(); setup reads them and never
## assigns them (the labels, `safe_at` and `flush_waiting` it does assign, so they are not here).
const TOWN_VARS := ["counting_tag", "counting_spot", "rounds", "set_out_at", "guards", "visit_seconds", "hide_seconds",
	"alarm_reach", "guard_r", "chain_wait", "flush_gap"]
var counting_tag: StringName = COUNTING_TAG
var counting_spot := Vector2.INF
var rounds: Array = ROUNDS
var set_out_at: Array = SET_OUT_AT
var guards: Array = GUARDS
## God T1R: the Leaving Is Prohibited effects cast tonight (kept from _on_cast() through Rules.last_fx()), the doors each collector has gone in
## at (by his index), the seconds the mob's conditions have held for each, the lay citizens sent to stand round him, and the one the mob
## is killing this instant (so _on_killed() judges that death unseen).
var _noleave: Array = []
var _visited := {}
var _mob_for := {}
var _mob_crowd := {}
var _mobbing: Variant = null


## AssassinateDirector's numbers start at the consts above (v0.12, R31): set at .new(), so a town's override survives setup.
func _init() -> void:
	walls_stop = true  # (god T1R) a collector out of the walls is stopped
	visit_seconds = VISIT_SECONDS
	hide_seconds = HIDE_SECONDS
	alarm_reach = ALARM_REACH
	guard_r = GUARD_R
	chain_wait = CHAIN_WAIT
	flush_gap = FLUSH_GAP


## The counting-house, the three collectors' rounds and the numbers (v0.11 M2).
func _plan() -> void:
	hideout = _counting_house()
	var door := _front_of(hideout)
	var taken: Array = [hideout]
	for i in rounds.size():
		var stops: Array[Structure] = []
		for spot: Vector2 in rounds[i]:
			var h := _house_reached(spot, door, taken)
			if h != null:
				stops.append(h)
				taken.append(h)
		_add_quarry(String(LABELS[i]), float(set_out_at[i]), stops, int(guards[i]))
	safe_at = Places.point(&"citadel_gate")
	flush_waiting = true
	hideout_label = "COUNTING-HOUSE"
	stop_label = "DEBTOR"
	safe_label = "CITADEL"
	next_label = "NEXT COLLECTOR"


## The workshop hall; else the dwelling nearest it (v0.11 M2). A wish never takes it: Ruin wishes take only plain dwellings and
## towers.
func _counting_house() -> Structure:
	for s: Structure in town._built:
		if is_instance_valid(s) and s.art_tag == counting_tag and not s.destroyed:
			return s
	return _house_near(Places.at(&"workshop") if counting_spot == Vector2.INF else counting_spot)


## The resident nearest the counting-house's door not yet a collector, made a noble for the night (v0.11 M2).
func _appoint_target(_q: Quarry) -> Person:
	var p := _citizen_near(hide_door, CitizenProfile.Role.RESIDENT, _appointed())
	if p != null:
		p.profile.role = CitizenProfile.Role.NOBLE
	return p


## The night's opening banner (v0.11 M2).
func _opening_banner() -> String:
	return "THE TAX COLLECTORS MAKE THEIR ROUNDS"


## The strip's and the banner's words when `q` sets out (v0.11 M2).
func _set_out_label(q: Quarry) -> String:
	return "The tax collector sets out" if q.index == 0 else "A deputy sets out"


## The banner when `q` is alarmed and hides (v0.11 M2).
func _hide_banner(q: Quarry) -> String:
	return "THE TAX COLLECTOR HIDES" if q.index == 0 else "A DEPUTY HIDES"


## The banner when the counting-house burns or falls with collectors inside (v0.11.1).
func _flush_banner() -> String:
	return FLUSH_BANNER


## The banner when a collector reaches the Citadel's gate (v0.11 M2).
func _safe_banner() -> String:
	return "THE TAXES ARE IN"


## The banner when a collector is stopped out of the walls (god T1R, spec 2.1).
func _out_banner(_q: Quarry) -> String:
	return OUT_BANNER


## `q` goes into `s` (v0.11 M2): a debtor's house he goes in at is a door he has visited tonight (god T1R: where the mob can take him).
func _go_in(q: Quarry, s: Structure) -> void:
	super(q, s)
	var i := q.stops.find(s)
	if s != hideout and i >= 0:
		var seen: Array = _visited.get(q.index, [])
		if not seen.has(q.stop_doors[i]):
			seen.append(q.stop_doors[i])
		_visited[q.index] = seen


## A power cast (god T1R): a Leaving Is Prohibited is kept, to read who it binds (Rules.last_fx() is the effect just cast).
func _on_cast(slot: int, key: String, at: Vector2) -> void:
	super(slot, key, at)
	if key == "noleave":
		var fx: Variant = rules.last_fx()
		if fx is NoLeaveFx:
			_noleave.append(fx)


## One step: the base's, then the mob (god T1R).
func step(delta: float) -> void:
	super(delta)
	_step_mob(delta)


## The door the law that binds `q` is laid on (god T1R, D17): the door he went in at tonight nearest the origin of a sealed Leaving Is Prohibited
## that holds him (he is in its `bound`), if that origin is within MOB_DOOR_R of it; Vector2.INF for none. The law's centre is read, not where he
## stands: he is held on the circle's edge, which is a different distance from the door by where he walks, so a click on the door must always work.
func _mob_door(q: Quarry) -> Vector2:
	var best := Vector2.INF
	var best_gap := INF
	for v: Variant in _noleave:
		if not is_instance_valid(v) or not (v as NoLeaveFx).sealed or not (v as NoLeaveFx).bound.has(q.target):
			continue
		var origin: Vector2 = (v as NoLeaveFx).origin
		for door: Vector2 in _visited.get(q.index, []):
			var gap := origin.distance_to(door)
			if gap <= MOB_DOOR_R and gap < best_gap:
				best = door
				best_gap = gap
	return best


## One of `q`'s guards (alive, out of doors) stands within MOB_GUARD_R of him.
func _guarded(q: Quarry) -> bool:
	for g: Variant in q.guards:
		if _alive(g) and not (g as Person).inside and (g as Person).ground_pos.distance_to(q.target.ground_pos) <= MOB_GUARD_R:
			return true
	return false


## `q` is held by a law laid on a visited debtor's door (_mob_door()): bound, and out of doors on his round (or in his flight).
func _held_at_door(q: Quarry) -> bool:
	return not q.dead and _alive(q.target) and not q.target.inside and q.state in [State.WALKING, State.FLEEING] \
		and _mob_door(q) != Vector2.INF


## The debtors can mob `q` now: held at a visited door (_held_at_door()) with no guard of his near. Only reads.
func mob_ready(q: Quarry) -> bool:
	return _held_at_door(q) and not _guarded(q)


## Each collector the mob is working on: the seconds its conditions have held; at MOB_AFTER he is mobbed. The laws that ran out are let go.
func _step_mob(delta: float) -> void:
	_noleave = _noleave.filter(func(v: Variant) -> bool: return is_instance_valid(v) and not (v as NoLeaveFx).finished)
	for q in quarries:
		if not mob_ready(q):
			if _mob_for.has(q.index):
				_mob_for.erase(q.index)
				_release_crowd(q)
			continue
		if not _mob_for.has(q.index):
			_mob_for[q.index] = 0.0
			_call_crowd(q)
		_mob_for[q.index] = float(_mob_for[q.index]) + delta
		if float(_mob_for[q.index]) >= MOB_AFTER:
			_mob_kill(q)


## Seconds left before `q` is mobbed (MOB_AFTER while the conditions are not yet met, or have just been); for his tag.
## (Real seconds, on purpose: the mob's wait is a reflex like a visit's, not a schedule, so a Lantern night's clock rate does not scale it, and
## its tag counts real seconds where the visit's tag counts mission seconds.)
func mob_left(q: Quarry) -> float:
	return maxf(MOB_AFTER - float(_mob_for.get(q.index, 0.0)), 0.0)


## Up to MOB_CROWD lay citizens nearest the door are sent to stand round `q` (the sight of the mob).
func _call_crowd(q: Quarry) -> void:
	var door := _mob_door(q)
	var skip: Array = _appointed()
	for o in quarries:
		skip.append_array(o.guards)
	var crew: Array = []
	var near := _lay_near(door, MOB_CROWD, skip)
	for i in near.size():
		near[i].go_duty(_ring_spot(q.target.ground_pos, 1.2, i, near.size(), 0.5))
		crew.append(near[i])
	_mob_crowd[q.index] = crew


## The debtors sent for the mob go back to their day.
func _release_crowd(q: Quarry) -> void:
	for v: Variant in _mob_crowd.get(q.index, []):
		if is_instance_valid(crowd) and _alive(v) and (v as Person).mind == Person.Mind.DUTY:
			crowd.off_duty(v as Person)
	_mob_crowd.erase(q.index)


## The debtors mob `q`: he falls (kind &"mob"), and _on_killed() judges it unseen and credits Leaving Is Prohibited.
func _mob_kill(q: Quarry) -> void:
	var who: Person = q.target
	rules.banner.emit(MOB_BANNER)
	_mobbing = who
	crowd._field.kill(who, &"mob", _mob_door(q))
	_mobbing = null
	_mob_for.erase(q.index)
	_release_crowd(q)


## A death in the field: the base's; the mob's is judged unseen at once (the debtors raise no cry) and credited to Leaving Is Prohibited
## (god T1R), not left to _judge() with its witnesses.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	var mob: bool = _mobbing != null and _mobbing == e
	super(e, kind)
	if not mob:
		return
	for q in quarries:
		var t: Variant = q.target
		if t == e:
			q.fell_at = Vector2.INF
			q.unseen = true
			q.judged = true
			q.killed_by = "noleave"


## `q`'s own tag: a collector held at a debtor's door shows what is missing or what is coming (god T1R): "GUARDED" while one of his guards
## stands near him, else the mob's seconds. Otherwise the base's.
func _target_tag(q: Quarry) -> MapTag:
	if _held_at_door(q):
		var words := q.label + " - GUARDED"
		if not _guarded(q):
			words = q.label + " - MOB " + UiTheme.clock(ceilf(mob_left(q)))
		return MapTag.person(q.target.ground_pos, MARK_TARGET, words, true)
	return super(q)


## Lets go of the laws kept and the debtors called (god T1R), then the base's.
func teardown() -> void:
	_noleave.clear()
	for q in quarries:
		_release_crowd(q)
	super()


## The tour (spec §1, v0.11 M2): the counting-house and when they set out (the deputies "by" their times: the chain can bring
## them sooner), the collector's first debtor, the Citadel.
func tour() -> Array:
	var out := []
	if hide_door != Vector2.INF:
		out.append([hide_door, "The counting-house. The tax collector sets out at %s, his deputies by %s and %s." % [
			UiTheme.clock(set_out_at[0]), UiTheme.clock(set_out_at[1]), UiTheme.clock(set_out_at[2])]])
	if not quarries.is_empty() and not quarries[0].stop_doors.is_empty():
		out.append([quarries[0].stop_doors[0], "His first debtor. He goes in to collect, then walks on."])
	if safe_at != Vector2.INF:
		out.append([safe_at, "The Citadel. A collector whose rounds are done takes the taxes in."])
	return out
