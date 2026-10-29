class_name ExpelInquisitorDirector
extends AssassinateDirector
## Expel the inquisitor (god P5, MS §4, plan Task 6; Hunt 3 of the Lantern Hunts, Tier 3): three lantern-wardens walk looping rounds along
## the walls, each with a guard, then the Lantern's captain walks a round of four stops and makes for the Citadel's gate, which loses the
## night. Stop all four -- dead, out of the walls, or (the captain) frightened out. The Hunt's own rule: three frights drive the captain out
## of Aldermere. A fright is an alarm on the captain while he walks (a loud power near him, a guard of his felled, his mind turned afraid), at
## most one count every EI_FRIGHT_GAP seconds; the first two send him to hide, the third sends him running for the nearest gate and he is
## stopped at once (counted with the dead, as one out of the walls) and walked off the map.
##
## It is the Assassinate type with its places and numbers changed, and (Ruling C5, pre-flight B5) its flight changed: no target ever flees to the
## Citadel's gate. A warden has no safe place (he hides in his own waiting house, else a house of his round, and his round loops for ever); the
## captain hides in the Temple, else a house of his round, and only the captain at the end of his round walks to the Citadel. The Temple down or
## burning therefore never turns an alarm into an escape. Guards are the base's soldiers, appointed nearest each target's first door. Opposition
## stands more than 1.6 apart (MS §0): the captain's two guards 0.9 each side of him, the door rings three slots wide. The town's people
## are held through an evacuation every look (MS §0, _hold_all). Banners and tags are MS §4's.

## The wardens' rounds, one per warden: four stops each as spots, snapped to the dwelling nearest each whose door the street reaches
## (_house_reached()). The west round keeps to the wall side of its quarter; the south-east and north-east rounds sit at x 6-8, inside the
## town, because the dwellings nearest the spec's wall-side spots are there (the wall side has none the street reaches), so those two wardens
## walk the interior (MS §4 *fg*; Task 6's geometry probe). Aldermere's.
const EI_ROUNDS := [
	[Vector2(-13.9, -3.5), Vector2(-12.1, 3.8), Vector2(-9.9, 5.5), Vector2(-9.9, -3.5)],
	[Vector2(5.9, 7.2), Vector2(7.9, 10.9), Vector2(6.2, 13.8), Vector2(7.9, 12.5)],
	[Vector2(7.9, -6.6), Vector2(7.9, -8.4), Vector2(7.85, -12.3), Vector2(6.0, -10.4)],
]
## The captain's four stops as spots (MS §4 *fg*): the bell tower's door, the market's south end, the Main Gate's plaza, and last the far
## south-east house by the east wall (Aldermere has no well in the east; this is the house farthest by path from the Citadel's gate, 41 units,
## so his last walk is the longest the town gives: Ruling P5-T6-R1). Then the final waypoint, then the Citadel.
const EI_CAPTAIN_STOPS := [Vector2(7.0, 0.8), Vector2(-3.5, 8.0), Vector2(1.7, 13.5), Vector2(13.8, 12.3)]
## The street point the captain walks through between his last stop and the Citadel's gate (north of the Temple, snapped to walkable ground):
## from the south-east house the town gives only 41 units to the gate, so the long way round the north wall (about 80) makes the warned
## last walk 40-60 s at the fast and slow ends of PACE_RANGE (Ruling P5-T6-R1; MS §4's example reads `CITADEL IN 1:12`).
const EI_FINAL_WAYPOINT := Vector2(0.8, -14.5)
## The tags' words, in the quarries' order: three wardens, then the captain.
const EI_LABELS := ["WARDEN", "WARDEN", "WARDEN", "CAPTAIN"]
## How many wardens there are (the captain is the quarry after them).
const EI_WARDENS := 3
## Each warden's guards and the captain's (MS §4: one a warden, two the captain, 0.9 off him).
const EI_GUARDS := [1, 1, 1, 2]
## When each warden sets out at the latest (the strip's seconds, MS §4 *fg*): 0:44, 1:34, 2:24; each next sooner if the one before is stopped.
## Round 2 of Task 11 tuning (Ruling P5-T11-R1, P5-C10 "harder"): was 20 / 70 / 120. A fast killer is bound by the first warden's time plus three
## chains (45 s), so the Hunt's pooled median sat at 157 s (round 1's VISIT / HIDE / FRIGHT_GAP left it there); 44 keeps the first wait under 45 s.
const EI_WARDEN_AT := [44.0, 94.0, 144.0]
## How long after one is stopped the next sets out at the latest (MS §0: no wait over 60 s; the chain is 45).
const EI_CHAIN := 45.0
## When the captain sets out at the latest (3:10 *fg*), or this long after the third warden is stopped, whichever is sooner.
const EI_CAPTAIN_AT := 190.0
## Seconds a target stays indoors at a stop (real seconds, 6 *fg*; MS §7 tunes it to 8) and hiding (12 *fg*; tunes to 18).
const EI_VISIT := 6.0
const EI_HIDE := 12.0
## How near a loud power must land to alarm a walking target (the Assassinate type's own 4).
const EI_ALARM_REACH := 4.0
## How far a guard walks off his target (MS §4: 0.9; two guards stand 1.8 apart).
const EI_GUARD_OFF := 0.9
## How many counted frights drive the captain out, and the real seconds between two counts (8 *fg*; MS §7 tunes it to 6).
const EI_FRIGHTS := 3
const EI_FRIGHT_GAP := 8.0
## Mission seconds before the captain reaches the Citadel at which the banner and the hint warn (MS §4: 20 s).
const EI_NEAR_WARN := 20.0
## The share of a walked road's seconds the captain's countdown adds back (god P5 Task 11, review of Task 6): he walks the last leg 10-15 % slower
## than PANIC_SPEED x pace says (measured with Person.tick from the last door through the waypoint to the gate: 1.09 at the slow end of
## PACE_RANGE, 1.11 mid, 1.14 at the fast end), so the tag read 0:00 about 6 s before he came. 1.15 keeps the tag at or just over the real walk
## (0.3 to 3.5 s over) and the window above its 45 s floor.
const EI_WALK_SCALE := 1.15
## The slots on a door's ring of guards, so the captain's two guards at the Temple's door stand 1.73 apart (more than 1.6, MS §0).
const EI_DOOR_SLOTS := 3
## The map tags' grey for a target waiting for his time.
const EI_MARK_WAIT := Color("9aa0a8")
## The Citadel's gate: Aldermere's place citadel_gate.
const EI_SAFE_PLACE := &"citadel_gate"
## Banners (MS §4).
const EI_OPENING := "EXPEL THE INQUISITOR"
const EI_FLEES := "THE CAPTAIN FLEES ALDERMERE"
const EI_NEARS := "THE CAPTAIN NEARS THE CITADEL"
const EI_ROW := "The captain reaches the Citadel"
## Where the camera stands (the west warden's quarter, clear of the HUD stack) and the strip row's key are the frame's.
const EI_CAMERA_AT := Vector2(-12.0, 1.0)

## Counted frights on the captain (EI_FRIGHTS ends it), the real seconds before the next can count, whether he fled, and whether the
## nearing banner was told for this approach.
var _frights := 0
var _fright_wait := 0.0
var _fled := false
var _near_told := false
## The captain has walked through EI_FINAL_WAYPOINT on his last leg (so his goal is the Citadel's gate).
var _via := false
## Seconds to the next hold of the town's people (TICK).
var _hold_in := 0.0
## The last countdown computed and what it was computed from (the director's clock, the captain's place, state, leg, pace, slow, visit clock and
## the waypoint passed), so the four asks of one look share one search (captain_eta()); and how many searches have run (eta_runs(), the tests').
var _eta := INF
var _eta_key: Array = []
var _eta_runs := 0


## The Assassinate numbers start at this Hunt's consts (MS §4); a board tune may override them after .new().
func _init() -> void:
	walls_stop = true  # (MS §0, shared rule 1) a target out of the walls is stopped
	smoke_out = false  # the wardens wait in their houses, not at the Temple's door: only the chain and the time set them out
	visit_seconds = EI_VISIT
	hide_seconds = EI_HIDE
	alarm_reach = EI_ALARM_REACH
	guard_r = EI_GUARD_OFF
	chain_wait = EI_CHAIN


## The Temple as the hideout (the captain's), the Citadel's gate as the safe place, the three wardens' rounds and then the captain's.
func _plan() -> void:
	hideout = _temple()
	safe_at = Places.point(EI_SAFE_PLACE)
	hideout_label = "TEMPLE"
	stop_label = "STOP"
	safe_label = "CITADEL"
	var door := _walkable(lantern_door())
	var taken: Array = [hideout]
	var captain_stops := _resolve(EI_CAPTAIN_STOPS, door, taken)  # first, so no warden's round takes the captain's houses
	for i in EI_WARDENS:
		_add_quarry(String(EI_LABELS[i]), float(EI_WARDEN_AT[i]), _resolve(EI_ROUNDS[i], door, taken), int(EI_GUARDS[i]))
	_add_quarry(String(EI_LABELS[EI_WARDENS]), EI_CAPTAIN_AT, captain_stops, int(EI_GUARDS[EI_WARDENS]))


## The houses nearest `spots` whose doors the street reaches from `door`, each different from the rest and from `taken` (which grows).
func _resolve(spots: Array, door: Vector2, taken: Array) -> Array[Structure]:
	var stops: Array[Structure] = []
	for spot: Vector2 in spots:
		var h := _house_reached(spot, door, taken)
		if h != null:
			stops.append(h)
			taken.append(h)
	return stops


## The Temple, by its role; null for none.
func _temple() -> Structure:
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple" and not s.destroyed:
			return s
	return null


## The setup: the base's (each target appointed, set down and taken indoors, guards appointed), then the door rings made three slots wide so the
## captain's guards stand apart, and the guards sent to their doors. A warden goes in at his own waiting house (_go_in()), not the Temple.
func _begin() -> void:
	super()
	_guard_total = EI_DOOR_SLOTS
	_send_guards()
	_hold_people(false)


## Who `q` is tonight: a warden, the resident nearest his first door, made a watchman for the night (the lantern and cloak mark him); the
## captain, the cleric nearest the Temple's door, else the resident.
func _appoint_target(q: Quarry) -> Person:
	if _is_captain(q):
		var cleric := _citizen_near(hide_door, CitizenProfile.Role.CLERGY, _appointed())
		return cleric if cleric != null else _citizen_near(hide_door, CitizenProfile.Role.RESIDENT, _appointed())
	var at: Vector2 = q.stop_doors[0] if not q.stop_doors.is_empty() else hide_door
	var p := _citizen_near(at, CitizenProfile.Role.RESIDENT, _appointed())
	if p != null:
		p.profile.role = CitizenProfile.Role.WATCHMAN
	return p


## The guards walk with their target: the free soldiers nearest his first door (a warden's waiting house, the captain's Temple door).
func _appoint_guards(q: Quarry, taken: Array) -> Array[Person]:
	var at: Vector2 = q.stop_doors[0] if (not _is_captain(q) and not q.stop_doors.is_empty()) else hide_door
	return _free_soldiers(at, q.guard_count, taken)


## `q` is the captain (the last quarry).
func _is_captain(q: Quarry) -> bool:
	return q.index == EI_WARDENS


## The captain's quarry; null before the plan.
func captain() -> Quarry:
	return quarries[EI_WARDENS] if quarries.size() > EI_WARDENS else null


## `q` goes into `s`. A warden still waiting goes in at his own first house, never the Temple: the base's setup puts every target in the
## hideout, and this is where a warden's wait is (Ruling C5). Anything else is the base's.
func _go_in(q: Quarry, s: Structure) -> void:
	if q.state == State.WAITING and s == hideout and not _is_captain(q) and not q.stops.is_empty():
		super(q, q.stops[0])
		return
	super(q, s)


## `q` sets out. A warden comes out of his own door and walks to the second stop of his round (he has just stood in the first); the base's
## otherwise (the captain out of the Temple's door).
func _set_out(q: Quarry) -> void:
	if q.state == State.WAITING and not _is_captain(q) and _alive(q.target) and q.stops.size() > 1:
		q.leg = 1
	super(q)


## Where `q`'s round takes him next. A warden's round loops (he has no safe place): past his last stop it starts again. The captain's ends at
## the Citadel's gate. A warden with no stop to go to stays where he stands.
func _leg_goal(q: Quarry) -> Vector2:
	if not _is_captain(q):
		if q.stops.is_empty():
			return _walkable(q.target.ground_pos)
		if q.leg >= q.stops.size():
			q.leg = 0
	if _is_captain(q) and q.leg >= q.stops.size() and not _via:
		return _walkable(EI_FINAL_WAYPOINT)
	return super(q)


## `q` arrived. Fleeing, he hides in a house (_hide_house()), never at the Citadel: with none standing he takes his round up again. A warden
## with no stops waits where he is; the base's otherwise (at a stop he goes in; the captain past his last stop is safe).
func _arrive(q: Quarry) -> void:
	if q.state == State.FLEEING:
		var house := _hide_house(q)
		if house != null:
			_go_in(q, house)
			q.state = State.HIDING
			q.indoors_left = hide_seconds
		else:
			q.state = State.WALKING
			q.target.go_duty(_leg_goal(q))
		return
	if not _is_captain(q) and q.stops.is_empty():
		return
	if _is_captain(q) and q.leg >= q.stops.size() and not _via:
		_via = true  # through the final waypoint: now the Citadel's gate
		q.target.go_duty(safe_at)
		return
	super(q)


## Where an alarmed `q` flees to: his hiding house's door (_hide_goal_of()); where he stands when there is none. Never the Citadel's gate (Ruling C5).
func _hide_goal(q: Quarry = null) -> Vector2:
	if q == null:
		return hide_door
	var house := _hide_house(q)
	if house == null:
		return _walkable(q.target.ground_pos)
	return hide_door if house == hideout else q.stop_doors[q.stops.find(house)]


## The house `q` hides in: the captain the Temple while it stands unburnt; a warden his waiting house (the first of his round) while it stands;
## else the nearest standing, unburnt house of his own round; null when none. Only reads.
func _hide_house(q: Quarry) -> Structure:
	if _is_captain(q) and _hideout_stands():
		return hideout
	if not _is_captain(q) and not q.stops.is_empty() and _house_stands(q.stops[0]):
		return q.stops[0]
	var best: Structure = null
	var best_gap := INF
	for i in q.stops.size():
		var s := q.stops[i]
		if not _house_stands(s):
			continue
		var gap := q.target.ground_pos.distance_squared_to(q.stop_doors[i])
		if gap < best_gap:
			best = s
			best_gap = gap
	return best


## `s` stands, unburnt.
func _house_stands(s: Structure) -> bool:
	return is_instance_valid(s) and not s.destroyed and not _burning(s)


## No target ever flees to the Citadel (Ruling C5): false always, so no flight is "for the safe place".
func fleeing_to_safe(_q: Quarry) -> bool:
	return false


## `q` alarmed in the street. A warden: the base's (he hides). The captain: the alarm counts once every EI_FRIGHT_GAP seconds (MS §4); the third
## count sends him running for the nearest gate and stops him at once; the first two the base's (he hides). While he flees, hides or visits
## the base ignores the alarm, and so does the count.
func _alarm(q: Quarry) -> void:
	if q.state != State.WALKING:
		return
	if not _is_captain(q):
		super(q)
		return
	if _fright_wait <= 0.0:
		_frights += 1
		_fright_wait = EI_FRIGHT_GAP
		if _frights >= EI_FRIGHTS:
			_flee(q)
			return
	super(q)


## The third fright: the captain runs for the nearest gate, stopped for the night at once (as one out of the walls), and is walked off the map.
func _flee(q: Quarry) -> void:
	_fled = true
	q.alarms += 1
	_stop_out(q)


## `q`'s body is gone without his death (it left the map in a fright): stopped, never safe -- a warden has no safe place, and the captain
## who left the town is expelled (the base's would call it an escape and lose).
func _lost(q: Quarry) -> void:
	if q.state == State.OUT:
		return
	q.state = State.OUT
	q.died_at = _clock
	q.inside_of = null
	var text := _out_banner(q)
	if text != "":
		rules.banner.emit(text)


## The banner when `q` is stopped out of the walls (or, the captain, by the third fright).
func _out_banner(q: Quarry) -> String:
	if _is_captain(q):
		return EI_FLEES if _fled else "THE CAPTAIN LEAVES ALDERMERE"
	return "A WARDEN LEAVES TOWN"


## The banner when `q` is alarmed and hides.
func _hide_banner(q: Quarry) -> String:
	return "THE CAPTAIN HIDES" if _is_captain(q) else "A WARDEN HIDES"


## The banner when `q` sets out (the strip's words; the banner is them in capitals).
func _set_out_label(q: Quarry) -> String:
	return "The captain sets out" if _is_captain(q) else "A warden sets out"


## The banner when the captain reaches the Citadel's gate: the night is lost.
func _safe_banner() -> String:
	return "THE CAPTAIN REACHES THE CITADEL"


## The night's opening banner.
func _opening_banner() -> String:
	return EI_OPENING


## One step: the base's (the timeline, the chain, each target's look and guards), then the fright clock, the town's people held, and the
## nearing warning.
func step(delta: float) -> void:
	_fright_wait = maxf(_fright_wait - delta, 0.0)
	_hold_in -= delta
	if _hold_in <= 0.0:
		_hold_in = TICK
		_hold_people(_evacuation_began())
	super(delta)
	_warn_near()


## The director's own people kept out of the town's flight: every target and guard, every look (MS §0, _hold_all(): a held man is never lost to
## the evacuation).
func _hold_people(evacuating: bool) -> void:
	var people: Array = []
	for q in quarries:
		people.append(q.target)
		people.append_array(q.guards)
	_hold_all(people, evacuating)


## The captain's last walk is warned (Ruling P5-T6-R1): from the moment his last visit begins until he is stopped or there -- inside the last
## stop, or walking the last leg (through the waypoint, to the gate).
func _warned(q: Quarry) -> bool:
	if not _is_captain(q) or q.stops.is_empty() or not _alive(q.target):
		return false
	return (q.state == State.VISITING and q.leg == q.stops.size() - 1) or (q.state == State.WALKING and q.leg >= q.stops.size())


## Mission seconds until the captain reaches the Citadel on his warned walk: the rest of his last visit, then the walk from the stop's door
## (or from where he stands) through the waypoint to the gate, at his pace (EI_WALK_SCALE over PANIC_SPEED x pace), all times the clock's rate;
## INF while he is not warned. Computed once for a look: the same place, state, pace and clock give the answer already found.
func captain_eta() -> float:
	var q := captain()
	if q == null or not _warned(q):
		return INF
	var p: Person = q.target
	var key := [_clock, p.ground_pos, int(q.state), q.leg, _via, p.pace, float(p.statuses.get(&"slow", 1.0)), q.indoors_left,
		rules.clock_rate if is_instance_valid(rules) else 1.0]
	if key == _eta_key:
		return _eta
	_eta_key = key
	_eta = _compute_eta(q)
	return _eta


## How many times the countdown's road has been searched (captain_eta() answers from the last search when nothing it reads has moved).
func eta_runs() -> int:
	return _eta_runs


## The countdown's search: the visit that is left, then the road door -> waypoint -> gate at his pace times EI_WALK_SCALE, in mission seconds.
func _compute_eta(q: Quarry) -> float:
	_eta_runs += 1
	var rate: float = rules.clock_rate if is_instance_valid(rules) else 1.0
	var p: Person = q.target
	var speed := maxf(Person.PANIC_SPEED * p.pace * float(p.statuses.get(&"slow", 1.0)), 0.05)
	var wait := 0.0
	var from: Vector2 = p.ground_pos
	if q.state == State.VISITING:
		wait = maxf(q.indoors_left, 0.0)
		from = q.stop_doors[q.stops.size() - 1]
	var way := 0.0
	if not _via:
		way += _way(from, _walkable(EI_FINAL_WAYPOINT))
		from = _walkable(EI_FINAL_WAYPOINT)
	way += _way(from, safe_at)
	return (wait + way / speed * EI_WALK_SCALE) * rate


## The length of the street walk from `a` to `b` (straight when no path is found).
func _way(a: Vector2, b: Vector2) -> float:
	var steps := crowd._grid.path(a, b) if crowd._grid != null else PackedVector2Array()
	var total := 0.0
	var at := a
	for pt in steps:
		total += at.distance_to(pt)
		at = pt
	return total + at.distance_to(b)


## Mission seconds until the captain sets out, 0 once he has.
func captain_out_in() -> float:
	var q := captain()
	if q == null or q.state != State.WAITING:
		return 0.0
	return maxf(out_at(q.index) - _clock, 0.0)


## The banner when the captain is 20 s from the Citadel, once for each approach.
func _warn_near() -> void:
	var q := captain()
	if q == null:
		return
	if not _warned(q):
		_near_told = false
		return
	if not _near_told and captain_eta() <= EI_NEAR_WARN:
		_near_told = true
		rules.banner.emit(EI_NEARS)


## How many frights have been counted on the captain.
func frights() -> int:
	return _frights


## The captain fled the town in the third fright.
func fled() -> bool:
	return _fled


## The strip's row for the captain's last leg: when he reaches the Citadel.
func strip_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var q := captain()
	if q != null and _warned(q):
		out.append({"in": captain_eta(), "label": EI_ROW})
	return out


## "near" when the captain is within EI_NEAR_WARN of the Citadel; "captain" while he is out; else "" (the mission's own line).
func hint_phase() -> String:
	var q := captain()
	if q == null or not _alive(q.target) or q.dead or q.state == State.OUT or q.state == State.SAFE:
		return ""
	if _warned(q) and captain_eta() <= EI_NEAR_WARN:
		return "near"
	if _is_out(q):
		return "captain"
	return ""


## The map tags, most important first: the captain, each warden out (or his door while he is inside), each waiting target's countdown, the
## stop each walks to, the Citadel's gate, then the guards of every target in the street (red, pointed at) and anyone who would see a target die.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if any_safe() or all_fallen():
		return out
	var street: Array[Quarry] = []
	for q in quarries:
		if q.dead or q.state == State.SAFE or q.state == State.OUT or not _alive(q.target):
			continue
		if q.state == State.WAITING:
			continue
		street.append(q)
	var order: Array[Quarry] = []
	for q in street:
		if _is_captain(q):
			order.insert(0, q)
		else:
			order.append(q)
	for q in order:
		out.append(_target_tag(q))
	for q in quarries:
		if q.state == State.WAITING and not q.dead and _alive(q.target):
			out.append(_waiting_tag(q))
	for q in order:
		if _warned(q):
			out.append(MapTag.place(safe_at, MARK_WATCHED, safe_label, 0.0, true))  # his last leg: red, and pointed at from the edge
		elif _is_captain(q) or q.leg < q.stops.size():
			_place_tag(q, out)  # (a warden whose last stop was just skipped has no stop tag until his round turns, never the Citadel's)
	var cap := captain()
	var told := false
	for m in out:
		told = told or m.label == safe_label
	if not told and cap != null and not cap.dead and cap.state != State.OUT and cap.state != State.SAFE:
		out.append(MapTag.place(safe_at, MARK_PLACE, safe_label, 0.0, false))
	for q in order:
		if q.target.inside:
			continue
		var seeing := witnesses(q)
		for p in seeing:
			if not q.guards.has(p):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
		for g: Variant in q.guards:
			if _alive(g) and not (g as Person).inside:
				out.append(MapTag.person((g as Person).ground_pos, MARK_WATCHED, "GUARD", true))
	return out


## `q`'s own tag. The captain: his Citadel countdown once his last visit begins, his fright count otherwise, the seconds he is inside; a warden: the base's.
func _target_tag(q: Quarry) -> MapTag:
	if not _is_captain(q):
		return super(q)
	if q.target.inside:
		if _warned(q):
			return MapTag.place(_door_in(q), MARK_TARGET, "%s - CITADEL IN %s" % [q.label, UiTheme.clock(ceilf(captain_eta()))], 0.0, true)
		var words := "%s - INSIDE %s" % [q.label, UiTheme.clock(maxf(q.indoors_left, 0.0) * (rules.clock_rate if is_instance_valid(rules) else 1.0))]
		if _frights > 0:
			words += " - SHAKEN %d/%d" % [_frights, EI_FRIGHTS]
		return MapTag.place(_door_in(q), MARK_TARGET, words, 0.0, true)
	var label := "%s - SHAKEN %d/%d" % [q.label, _frights, EI_FRIGHTS]
	if _warned(q):
		label = "%s - CITADEL IN %s" % [q.label, UiTheme.clock(ceilf(captain_eta()))]
	return MapTag.person(q.target.ground_pos, MARK_TARGET, label, true)


## The grey tag over the door of a target still waiting: his word and the seconds to his time (the strip's, mission seconds).
func _waiting_tag(q: Quarry) -> MapTag:
	var seconds := ceilf(maxf(out_at(q.index) - _clock, 0.0))
	var at: Vector2 = hide_door if (_is_captain(q) or q.stop_doors.is_empty()) else q.stop_doors[0]
	return MapTag.place(at, EI_MARK_WAIT, "%s OUT IN %s" % [q.label, UiTheme.clock(seconds)], 0.0, false)


## The results' report: the base's, with the counted frights and whether the captain fled.
func report() -> Dictionary:
	var out := super()
	out["frights"] = _frights
	out["fled"] = _fled
	return out


## The tour: the west warden's door and when he sets out, the Temple and the captain, the Citadel.
func tour() -> Array:
	var out := []
	var w := quarries[0] if not quarries.is_empty() else null
	if w != null and not w.stop_doors.is_empty():
		out.append([w.stop_doors[0], "A lantern-warden waits in his house. He sets out at %s; two more follow." % UiTheme.clock(EI_WARDEN_AT[0])])
	if hide_door != Vector2.INF:
		out.append([hide_door, "The captain waits in the Temple. Frighten him three times, or kill him."])
	if safe_at != Vector2.INF:
		out.append([safe_at, "The Citadel. If the captain reaches it, the night is lost."])
	return out
