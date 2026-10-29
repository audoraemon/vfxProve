class_name FaceHalcyonDirector
extends ExodusDirector
## Face Halcyon (god P5, Hunt 5, MS §6; Tier 5, the Lantern Hunt of the Gaze; the Escort type's seizure march read backwards): four believers
## are led to the pyre before the Temple's steps, each bound (deaf to whisper and to fright, as The Prisoner's) and each in the midst of
## FH_ESCORT soldiers, more than two Silent Doom radii apart. A procession waits in a district house, forms up at its door FH_FORM seconds
## (visible, strikable), then walks to the pyre at FH_PROC_PACE and, once within FH_PYRE_REACH of it, is bound to the stake: FH_BURN seconds later the
## believer burns. Three freed of the four win (FH_NEED); two burned lose (FH_LOSE_BURNED), as does the Gaze full or dawn. The Hunt's rule: a believer
## is freed the moment fewer than FH_ESCORT_HOLD of his escort are *able* (alive, out of doors, with the procession, not held by the god, not frail, not
## afraid): break his escort, unseen, and he runs for the nearest way out and is sent off. A believer set down out of the walls is freed too (shared
## rule 1); an escort out of the walls is sent off; a believer the god kills counts as burned. The escorts are soldiers (_free_soldiers), so CALL THE
## GUARD, Mind Whisper and Discord work on them. Nobody seizes: the soldiers escort, they do not hunt, so no town traffic decides a win or a loss
## (MS §0). The director keeps its own Gaze (the base's): every seen death adds GazeMeter.SEEN_DEATH, and the bell's toll adds
## LanternWatch.GAZE_TOLL (the frame's lantern is the gaze).
##
## Each procession is one Exodus Household of one believer (its record keeps the house, door and chain), plus a Procession record of its own
## (phase, escorts, their places, the burn clock). Each is chained on the base's own timing: it forms at FH_PROC_AT or FH_CHAIN seconds after the one
## before is freed or burned. Opposition stands more than 1.6 apart (MS §0): escort_spots() gives each escort a place FH_SPACE or more from the others'
## (the ring of 1.0 where there is room, the file along a lane where there is not: Aldermere's lanes are one or two cells wide), a house is chosen only
## if it has the room at its door and all the way to the pyre (road_roomy()), and two processions are never at one stake at a time (a second waits
## short of the pyre).
##
## Overrides of ExodusDirector (the MS §6 checklist): _plan() (houses, the pyre, no gates, no watch, no patrols), the tune_ vars (setup(), _tune()),
## _place_charge() (a bound believer in the escort; the base's _appoint_charges() serves, one a house by tune_per_house), _step_held() (replaces the
## Escort type's single-seizer march, which frees him the moment one seizer leaves DUTY and takes him at return_to: here the escort walks him to the pyre
## and he is freed only by the fewer-than-FH_ESCORT_HOLD-able rule), _step_free() (a believer waiting inside is left alone), _exit_reached() (no gates),
## _come_out() (the procession forms up; no searchers' strip row), _chain() (this Hunt's banner), _relieve_watch() (a no-op), _households() (the god's
## kills counted as burned), step() (those sent off walk on), _keep_held(), _in_use(), lost_reason() ("burned"), hud_line(), tags(), hint_phase(),
## strip_rows(), busy(), report(), tour().

## The processions' houses (MS §6 *fg*): the dwelling nearest each point whose door the street reaches from the pyre, with a walk of FH_WALK_MIN seconds
## or more and room all the way (_roomy_door()) -- west, north-east, south-east, south-west -- 23-29 units of street from the pyre in Aldermere (the
## spec's 25-32; the north-east point moved from (12.5, -11) to (6.0, -12.4), where no dwelling of the north-east corner is more than 16 units away); their
## words and the names on the tags and banners.
const FH_HOUSE_POINTS := [Vector2(-11.5, 4.0), Vector2(6.0, -12.4), Vector2(12.0, 12.0), Vector2(-11.0, 12.5)]
const FH_HOUSE_WORDS := ["the west procession", "the north-east procession", "the south-east procession", "the south-west procession"]
const FH_HOUSE_NAMES := ["WEST", "NORTH-EAST", "SOUTH-EAST", "SOUTH-WEST"]
## Where the pyre stands from the Temple's door (MS §6): 2.5 south of it, snapped to walkable ground.
const FH_PYRE_OFF := Vector2(0.0, 2.5)
## How many soldiers escort a believer (*fg*; MS §7 tunes it to 2), how far from him they ring where there is room (1.7 apart for three), how many able
## escorts keep him bound (fewer frees him), and how near him -- or his place -- an escort must stand to be with the procession.
const FH_ESCORT := 3
const FH_ESCORT_RING := 1.0
const FH_ESCORT_HOLD := 2
const FH_ESCORT_REACH := 1.6
## Aldermere's lanes are one or two cells wide, so three escorts 1.7 apart cannot all stand within FH_ESCORT_REACH of him (two in a line is all that
## fits): each has his own place in the procession (escort_spots(), at most FH_SPAN from the believer, FH_SPACE or more from the others' places) and is
## with the procession while he stands within FH_ESCORT_REACH of the believer or of his own place (Ruling P5-T8-R1). Walking, he lags his place a
## moment (a corner moves it by two units at once), so an escort that is with the procession by neither is not able only after FH_GRACE seconds of it; one
## the god has disabled is not able at once.
const FH_SPAN := 4.0
const FH_SPACE := 1.7
## The places are first sought this far apart (walkers stop up to a half unit short of or past theirs), then FH_SPACE.
const FH_SPACE_WIDE := 2.0
const FH_GRACE := 2.0
## The shortest walk (seconds, at the believers' pace) a procession's house may be from the pyre: forming and burning with it make at least 45 s, the
## room an instant loss is warned with (MS §0; review of wave 1, point b).
const FH_WALK_MIN := 25.0
## How often along a road (ground units) a house's room is looked at (road_roomy()).
const FH_ROAD_STEP := 0.4
## How far (ground units) an escort's place may move in one look when the gap allows (escort_spots()): a place follows the believer, it does not jump.
const FH_MOVE := 1.0
## An escort within this far of his place stands at it (the pair measure).
const FH_STOPPED := 0.6
## When each procession forms up at the latest (0:30, 1:35, 2:40, 3:45 *fg*) and the chain (a rule: no wait over 45 s after the one before is
## freed or burned).
const FH_PROC_AT := [30.0, 95.0, 160.0, 225.0]
const FH_CHAIN := 45.0
## How long a procession forms up at its door (*fg*; MS §7 tunes it to 12) and its pace to the pyre as a fraction of a soldier's duty pace
## (*fg*). The believer's pace is set to it outright (not times his own), so every walk is as long as its street.
const FH_FORM := 8.0
const FH_PROC_PACE := 0.5
## How near the pyre a believer must come to be bound to the stake, and the seconds he burns (*fg*; MS §7 tunes it to 15).
const FH_PYRE_REACH := 1.2
const FH_BURN := 12.0
## Freed believers that win, and burned ones that lose; how many believers there are.
const FH_NEED := 3
const FH_LOSE_BURNED := 2
const FH_BELIEVERS := 4
## A second procession arriving while a believer burns waits this far short of the pyre (no two processions at one stake).
const FH_QUEUE := 5.0
## The march waits for a fit escort straggling farther than FH_LAG from his place, at most FH_STRAGGLE seconds in all (so street corners never
## free a believer by luck; a stuck escort cannot hold the march for good).
const FH_LAG := 1.0
const FH_STRAGGLE := 3.0
## The Gaze at which the hint turns to it.
const FH_GAZE_HINT := 40.0
## The pyre's pile on the map: half the side of the outlined square (ground units).
const FH_PILE := 0.8
## The map tags' words the Hunt adds.
const FH_ROW := "A believer reaches the pyre"
const FH_ROW_BURN := "The fire takes a believer"
## Where the camera rests (MS §6 leaves it to the frame): the pyre low and right of the middle, the Temple's door above it; the four doors' arrows and the
## pyre's keep 29 px clear of the padded HUD stack (found by search over the town: the doors pull the camera north-west).
const FH_CAMERA_AT := Vector2(-6.0, -5.5)

## One procession (god P5, MS §6): a plain record, so the director holds no cycle.
class Procession:
	extends RefCounted
	## Where it is in its night: waiting in its house, forming up at its door, walking, bound to the stake, freed, burned, or its believer dead.
	enum Phase { WAITING, FORMING, MARCHING, BURNING, FREED, BURNED, DEAD }
	var phase := Phase.WAITING
	## The believer's Charge record and his soldiers (Variants: any may be freed).
	var charge: EscortDirector.Charge
	var escorts: Array = []
	## Where each escort is sent (escort_spots(), kept so the places do not jump between looks).
	var places: Array[Vector2] = []
	## The clock second each escort first stood with the procession by neither of his two measures (-1 while he does).
	var apart: Array[float] = []
	## The believer's own pace before it was slowed.
	var base_pace := 1.0
	## The second (the director's clock) forming ends and the burning ends.
	var form_end := 0.0
	var burn_end := 0.0
	## The ring's turn, and the seconds the march has waited for a straggler.
	var turn := 0.0
	var stall := 0.0
	## Seconds to the pyre as last worked out, and the clock second it was worked out at (INF until then).
	var eta := INF
	var eta_at := 0.0
	## How it was freed ("broken", "walls") or "" if not.
	var freed_by := ""

## The pyre, snapped to walkable ground (_plan()).
var pyre_at := Vector2.INF
## Every procession, in order (the index of its Household).
var procs: Array[Procession] = []
## The believers and each procession's escorts, kept as plain arrays so a test (and Task 1's wish check) sees the people (Variants: any may be freed).
var believers: Array = []
var escort_lists: Array = []
## Frees by the escort's break and by the walls, for the results and the scripted run.
var freed_broken := 0
var freed_walls := 0
## The nearest two escorts of one procession have stood to each other while stopped at their places (what a Silent Doom would take together; INF until
## they stood), how many such looks were taken, and how many of them under two Silent Doom radii; and the same counts for every look, walking too: the
## scripted run prints them (MS §0, review of Task 4).
var pair_min := INF
var pair_looks := 0
var pair_under := 0
var walk_min := INF
var walk_looks := 0
var walk_under := 0


## The Hunt's numbers into the base's tune_ vars before the base sets up (god P5, MS H11, H12, Ruling C2): no gate shuts, no hounds, one believer
## a house, three needed.
func setup(r: Rules, c: Crowd, t: Town, x: FxContext, n: NightState = null) -> MissionDirector:
	_tune()
	return super(r, c, t, x, n)


## Copies the FH_ consts into the base's vars (god P5, MS H11). Public so a test can read what setup() set.
func _tune() -> void:
	tune_out_at = FH_PROC_AT.duplicate()
	tune_shut_at = []
	tune_hounds = 0
	tune_per_house = 1
	tune_believer_pace = FH_PROC_PACE
	tune_need = FH_NEED
	tune_chain = FH_CHAIN
	tune_gate_watch = 0
	tune_beats = []


## The plan (MS §6): the Gaze, no guard change, the Temple, the pyre, no gates, no watch, no patrols, the four processions' houses.
func _plan() -> void:
	gaze = GazeMeter.new()
	watch_changes = false
	temple_door = _walkable(lantern_door())
	pyre_at = _walkable(lantern_door() + FH_PYRE_OFF)
	return_to = pyre_at
	guardhouse = pyre_at
	gate_at = pyre_at
	exit_at = pyre_at
	hunt_at = -1.0
	charge_label = "BELIEVER"
	exit_label = "PYRE"
	return_label = "PYRE"
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			temple = s
			break
	var skip: Array = []
	for i in FH_HOUSE_POINTS.size():
		var h := Household.new()
		h.words = String(FH_HOUSE_WORDS[i])
		h.name = String(FH_HOUSE_NAMES[i])
		h.gate = 0
		var tried := skip.duplicate()
		for k in HOUSE_TRIES:
			var near := _house_near(FH_HOUSE_POINTS[i], tried)
			if near == null:
				break
			tried.append(near)
			var door := _roomy_door(near)
			if door != Vector2.INF:
				h.house = near
				h.door = door
				break
		if h.house == null:
			push_warning("FaceHalcyonDirector: no house for %s" % h.words)
			continue
		skip.append(h.house)
		households.append(h)
		procs.append(Procession.new())


## A door of dwelling `s` for a procession (MS §6): the first of its four sides the street reaches from the pyre, with a walk to the pyre of at least
## FH_WALK_MIN seconds (so a burn is warned FH_FORM + FH_WALK_MIN + FH_BURN seconds ahead) and room all the way (road_roomy()); Vector2.INF for none.
## Only reads.
func _roomy_door(s: Structure) -> Vector2:
	var half := s.footprint.size * 0.5 + Vector2(0.5, 0.5)
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(s.center() + off)
		if crowd._grid != null and crowd._grid.path(pyre_at, door).is_empty():
			continue
		if _walk_secs(door) < FH_WALK_MIN:
			continue
		if road_roomy(door):
			return door
	return Vector2.INF


## The believer and three escorts have room to stand FH_SPACE apart at the door and at every FH_ROAD_STEP of the road from it to the pyre (the walk grid's
## path): a door in a pocket, or a road through a dead-end lane, fails. Only reads.
func road_roomy(door: Vector2) -> bool:
	var line: Array = [door]
	if crowd._grid != null:
		line.append_array(Array(crowd._grid.path(door, pyre_at)))
	line.append(pyre_at)
	var at: Vector2 = line[0]
	var prev: Array = []
	var turn := 0.0
	for k in range(1, line.size()):
		var to: Vector2 = line[k]
		var steps := maxi(1, ceili(at.distance_to(to) / FH_ROAD_STEP))
		turn = (to - at).angle() if at.distance_to(to) > 0.1 else turn
		for q in range(0 if k == 1 else 1, steps + 1):
			var spots := escort_spots(at.lerp(to, float(q) / float(steps)), FH_ESCORT, turn, prev)
			for a in spots.size():
				for b in range(a + 1, spots.size()):
					if spots[a].distance_to(spots[b]) < FH_SPACE - 0.01:
						return false
			prev = spots
		at = to
	return true


## The base's setup, then each procession's escorts inside its house, and the strip and banners on this Hunt's own words.
func _begin() -> void:
	super()
	_appoint_escorts()
	for c: Dictionary in timeline.fired.get_connections():
		timeline.fired.disconnect(c.callable)
	timeline.fired.connect(_on_fired)
	for e in timeline._events:
		if String(e.id).begins_with("out_"):
			var h: Household = households[int(String(e.id).trim_prefix("out_"))]
			e.label = "The %s forms up" % h.words.trim_prefix("the ")


## A timeline event's banner is its label in capitals, but a procession coming out says it forms up (MS §6).
func _on_fired(id: String, label: String) -> void:
	if id.begins_with("out_"):
		rules.banner.emit(_forms_banner(int(id.trim_prefix("out_"))))
	else:
		rules.banner.emit(label.to_upper())


## "THE WEST PROCESSION FORMS UP" for procession `i`.
func _forms_banner(i: int) -> String:
	return "THE %s PROCESSION FORMS UP" % (households[i] as Household).name


## Believer `c` bound in the escort (MS §6): set down at his house's door, slowed to FH_PROC_PACE outright, held there on duty and taken inside
## his house until the procession forms up. The Procession record of his house takes him.
func _place_charge(c: Charge) -> void:
	var p := c.man as Person
	var i := int(_home_of.get(p.get_instance_id(), 0))
	var h: Household = households[i]
	_home[c] = i
	h.members.append(c)
	var pr: Procession = procs[i]
	pr.charge = c
	pr.base_pace = p.pace
	_set_down(p, h.door)
	p.pace = FH_PROC_PACE
	c.hold_at = h.door
	p.go_duty(h.door)
	_take_inside(p, h.house)
	believers.append(p)


## Each procession's escorts (MS §6): the FH_ESCORT free soldiers nearest its door, none already at the night's work, set down at the door and
## taken inside the house with the believer until the procession forms up.
func _appoint_escorts() -> void:
	var taken: Array = []
	for i in households.size():
		var h: Household = households[i]
		var pr: Procession = procs[i]
		var crew := _free_soldiers(h.door, FH_ESCORT, _in_use(charge) + taken)
		if crew.size() < FH_ESCORT:
			push_warning("FaceHalcyonDirector: %d escorts for %s" % [crew.size(), h.words])
		for e in crew:
			taken.append(e)
			_set_down(e, h.door)
			e.go_duty(h.door)
			_take_inside(e, h.house)
			pr.escorts.append(e)
		escort_lists.append(pr.escorts)


## Everyone at the night's work, the escorts too (so no later appointment, and no Lantern errand, takes one).
func _in_use(c: Person) -> Array:
	var out := super(c)
	for list: Array in escort_lists:
		out.append_array(list)
	return out


## Everyone held through an evacuation (the base's list and the escorts), indoors or out.
func _keep_held(evacuating: bool) -> void:
	for list: Array in escort_lists:
		_hold_all(list, evacuating)
	super(evacuating)


## `p`, a believer or one of a procession's escorts, is on the director's errand (the Lantern-Bearer must not take him from it).
func busy(p: Person) -> bool:
	if believers.has(p):
		return true
	for list: Array in escort_lists:
		if list.has(p):
			return true
	return false


# --- The march, the break, the burning ---------------------------------------------------------------------------------------------

## One step: the base's, then those sent off the map walk on (the base does not step them).
func step(delta: float) -> void:
	super(delta)
	_step_leaving()


## A believer waiting inside his house is left alone (the base's free-walking path is not this Hunt's).
func _step_free(_c: Charge) -> void:
	pass


## No gates, so no way out to reach: a believer is freed by the escort's break or by the walls, never by a gate.
func _exit_reached(_c: Charge) -> bool:
	return false


## The watch is not replaced (MS §6): there is none.
func _relieve_watch() -> void:
	pass


## Procession `i` forms up (MS §6): the believer and his escorts brought out at the door, the escorts on their ring, the forming time begun.
func _come_out(i: int) -> void:
	var h: Household = households[i]
	if h.out:
		return
	h.out = true
	h.out_at = _clock
	h.trail.clear()
	var pr: Procession = procs[i]
	var c: Charge = pr.charge
	if c == null or c.taken:
		return
	pr.phase = Procession.Phase.FORMING
	pr.form_end = _clock + FH_FORM
	var p: Person = null
	if _alive(c.man):
		p = c.man as Person
		if p.inside:
			_bring_out(p, h.door)
			_keep_from_flight(p, true)
			p.go_duty(h.door)
			c.hold_at = h.door
		c.held = true
		_bind(p)
	var spots := escort_spots(h.door, pr.escorts.size(), pr.turn)
	pr.places = spots
	for k in pr.escorts.size():
		var v: Variant = pr.escorts[k]
		if not _alive(v) or not (v as Person).inside:
			continue
		var e := v as Person
		_bring_out(e, spots[k])
		_keep_from_flight(e, true)
		e.go_duty(spots[k])
	_refresh_eta(pr)


## One look at a procession in custody (MS §6; replaces the Escort type's single-seizer march): bound; set down out of the walls, he is freed; an
## escort out of the walls is sent off; fewer than FH_ESCORT_HOLD able escorts free him at once; forming, then walking, then at the stake and
## burning; the escorts kept on their ring. Counted in this order so a break always beats the fire's last second.
func _step_held(c: Charge) -> void:
	var i := int(_home.get(c, -1))
	if i < 0 or i >= procs.size():
		return
	var pr: Procession = procs[i]
	if not pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING, Procession.Phase.BURNING] or not _alive(c.man):
		return
	var p := c.man as Person
	_bind(p)
	for v: Variant in pr.escorts:
		if _alive(v) and not (v as Person).inside and Walls.outside((v as Person).ground_pos):
			send_off(v)
	if Walls.outside(p.ground_pos):
		_free(i, "walls")
		return
	_note_apart(pr, p)
	if able_escort(i) < FH_ESCORT_HOLD:
		_free(i, "broken")
		return
	var h: Household = households[i]
	match pr.phase:
		Procession.Phase.FORMING:
			if _clock >= pr.form_end:
				pr.phase = Procession.Phase.MARCHING
			else:
				_stand_at(p, h.door)
		Procession.Phase.BURNING:
			if _clock >= pr.burn_end:
				_burn(i)
				return
			_stand_at(p, pyre_at)
	if pr.phase == Procession.Phase.MARCHING:
		_march(pr, p)
	if pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING, Procession.Phase.BURNING]:
		_order_escorts(pr, p)
		_note_pairs(pr)
		_refresh_eta(pr)


## The march (MS §6): on to the pyre; within FH_PYRE_REACH he is bound to the stake; held short of it while another burns there; held a moment
## for an escort straggling (FH_LAG), at most FH_STRAGGLE seconds in all.
func _march(pr: Procession, p: Person) -> void:
	var dist := p.ground_pos.distance_to(pyre_at)
	if dist <= FH_PYRE_REACH:
		pr.phase = Procession.Phase.BURNING
		pr.burn_end = _clock + FH_BURN
		_stand_at(p, pyre_at)
		return
	if dist > 1.5:
		pr.turn = (pyre_at - p.ground_pos).angle()
	if dist <= FH_QUEUE and _pyre_busy(pr):
		_stand_at(p, p.ground_pos)
		return
	if _straggling(pr):
		if pr.stall < FH_STRAGGLE:
			pr.stall += TICK
			_stand_at(p, p.ground_pos)
			return
	else:
		pr.stall = 0.0
	_stand_at(p, pyre_at)


## `p` is held on duty at `at` (sent only when he is not already on his way to it).
func _stand_at(p: Person, at: Vector2) -> void:
	if p.mind != Person.Mind.DUTY or p.anchor.distance_to(at) > MOVE:
		p.go_duty(at)


## A fit escort of `pr` stands farther than FH_LAG from his place (alive, out of doors, not held by the god).
func _straggling(pr: Procession) -> bool:
	for k in pr.escorts.size():
		var v: Variant = pr.escorts[k]
		if _alive(v) and not (v as Person).inside and not is_leaving(v) and not _disabled(v as Person) and k < pr.places.size() \
				and (v as Person).ground_pos.distance_to(pr.places[k]) > FH_LAG:
			return true
	return false


## Another procession than `pr` is bound to the stake.
func _pyre_busy(pr: Procession) -> bool:
	for o in procs:
		if o != pr and o.phase == Procession.Phase.BURNING:
			return true
	return false


## The `spots` given to the escorts of `pr` so that the sum of their walks is the least (no two cross in a lane): escort k gets the place nearest him that
## no shorter assignment gives another; a dead or indoor escort keeps his old place. The places themselves are escort_spots()'s.
func _match_places(spots: Array[Vector2], pr: Procession) -> Array[Vector2]:
	var n := spots.size()
	var from: Array[Vector2] = []
	for k in n:
		var v: Variant = pr.escorts[k]
		if _alive(v) and not (v as Person).inside:
			from.append((v as Person).ground_pos)
		else:
			from.append(pr.places[k] if k < pr.places.size() else spots[k])
	return _assigned(spots, from)


## The assignment of `spots` to the escorts at `from` (same count) with the least total walk, by trying every order (at most three or four escorts).
func _assigned(spots: Array[Vector2], from: Array[Vector2]) -> Array[Vector2]:
	var n := spots.size()
	var best: Array[Vector2] = spots.duplicate()
	var best_cost := INF
	var perms: Array = [[]]
	for k in n:
		var grown: Array = []
		for p: Array in perms:
			for j in n:
				if not p.has(j):
					var q := p.duplicate()
					q.append(j)
					grown.append(q)
		perms = grown
	for p: Array in perms:
		var cost := 0.0
		for k in n:
			cost += from[k].distance_to(spots[int(p[k])])
		if cost < best_cost - 0.001:
			best_cost = cost
			for k in n:
				best[k] = spots[int(p[k])]
	return best


## Each fit escort of `pr` sent to his place round `p` (MS §6): one under the god's hold, afraid or frail is left be, and one back on his feet (or
## taken off the errand by the town) goes back to his place. Escorts never lose a slot: slot k keeps its side of the believer (escort_spots()).
func _order_escorts(pr: Procession, p: Person) -> void:
	pr.places = _match_places(escort_spots(p.ground_pos, pr.escorts.size(), pr.turn, pr.places), pr)
	for k in pr.escorts.size():
		var v: Variant = pr.escorts[k]
		if not _alive(v):
			continue
		var e := v as Person
		if e.inside or is_leaving(e) or _disabled(e):
			continue
		if e.mind != Person.Mind.DUTY or e.anchor.distance_to(pr.places[k]) > MOVE:
			e.go_duty(pr.places[k])


## The nearest two of `pr`'s escorts now (alive, out of doors, not held by the god), noted in walk_min and, when all of them stand within a step of their places
## (the procession is stopped, at the door or the stake), in pair_min too (the scripted run's check of MS §0's spacing).
func _note_pairs(pr: Procession) -> void:
	var live: Array[Person] = []
	var stopped := true
	for k in pr.escorts.size():
		var v: Variant = pr.escorts[k]
		if _alive(v) and not (v as Person).inside and not _disabled(v as Person):
			live.append(v as Person)
			stopped = stopped and k < pr.places.size() and (v as Person).ground_pos.distance_to(pr.places[k]) <= FH_STOPPED
	if live.size() < 2:
		return
	var low := INF
	for a in live.size():
		for b in range(a + 1, live.size()):
			low = minf(low, live[a].ground_pos.distance_to(live[b].ground_pos))
	walk_looks += 1
	walk_min = minf(walk_min, low)
	walk_under += 1 if low < 2.0 * SilentDoom.RADIUS else 0
	if stopped:
		pair_looks += 1
		pair_min = minf(pair_min, low)
		pair_under += 1 if low < 2.0 * SilentDoom.RADIUS else 0


## The believer is bound: deaf to a whisper and past fear (The Prisoner's hold, EscortDirector.BOUND_HOLD past each look).
func _bind(p: Person) -> void:
	p._shaken_left = maxf(p._shaken_left, BOUND_HOLD)
	p.fearless_left = maxf(p.fearless_left, BOUND_HOLD)


## Escort `e` cannot hold his place now (MS §6): held by the god (Whisper, Discord, The Bell Lies' call, a lure), frail (Death Mark), bound by a
## Leaving Is Prohibited law, afraid or fighting, down or frozen. The same list as the breakers' of the rite (P3-11, B5).
func _disabled(e: Person) -> bool:
	if e.held_by_god() or e.statuses.has(&"frail") or e.is_down() or e.is_frozen():
		return true
	if e.badge_glyph == DecreeParts.BARS and e.badge_left > 0.0:
		return true
	return e.mind == Person.Mind.PANIC or e.mind == Person.Mind.FLEE or e.mind == Person.Mind.SHELTER or e.mind == Person.Mind.FIGHT


## Each escort's standing with the procession, once a look (MS §6): the clock second he first stood farther than FH_ESCORT_REACH from the believer and from
## his own place (-1 while he does not).
func _note_apart(pr: Procession, p: Person) -> void:
	while pr.apart.size() < pr.escorts.size():
		pr.apart.append(-1.0)
	for k in pr.escorts.size():
		var v: Variant = pr.escorts[k]
		if not _alive(v):
			continue
		var e := v as Person
		var near := e.ground_pos.distance_to(p.ground_pos) <= FH_ESCORT_REACH \
				or (k < pr.places.size() and e.ground_pos.distance_to(pr.places[k]) <= FH_ESCORT_REACH)
		if near:
			pr.apart[k] = -1.0
		elif pr.apart[k] < 0.0:
			pr.apart[k] = _clock


## Escort `k` of `pr` is able (MS §6): alive, out of doors, not being sent off, not disabled (held by the god, frail, afraid, ...), and with the procession --
## not apart from it (within FH_ESCORT_REACH of the believer or of his place) for FH_GRACE seconds. Only reads.
func _able(pr: Procession, k: int) -> bool:
	var v: Variant = pr.escorts[k]
	if not _alive(v) or pr.charge == null or not _alive(pr.charge.man):
		return false
	var e := v as Person
	if e.inside or is_leaving(e) or _disabled(e):
		return false
	return k >= pr.apart.size() or pr.apart[k] < 0.0 or _clock - pr.apart[k] < FH_GRACE


## How many of procession `i`'s escorts are able (MS §6). Only reads. Zero for one not in custody (waiting inside, freed, burned or dead).
func able_escort(i: int) -> int:
	var pr: Procession = procs[i]
	if not pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING, Procession.Phase.BURNING] or pr.charge == null or not _alive(pr.charge.man):
		return 0
	var n := 0
	for k in pr.escorts.size():
		n += 1 if _able(pr, k) else 0
	return n


## Believer of procession `i` is freed (MS §6): out; he runs for the nearest way off the map at a run and is sent off; his escort goes back to
## its posts. `why` is "broken" (fewer than FH_ESCORT_HOLD able) or "walls" (set down out of the walls, shared rule 1).
func _free(i: int, why: String) -> void:
	var pr: Procession = procs[i]
	if not pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING, Procession.Phase.BURNING]:
		return
	var c: Charge = pr.charge
	pr.phase = Procession.Phase.FREED
	pr.freed_by = why
	if why == "walls":
		freed_walls += 1
	else:
		freed_broken += 1
	c.held = false
	c.escaped = true
	if _alive(c.man):
		var p := c.man as Person
		p._shaken_left = 0.0
		if p.fearless_left <= BOUND_HOLD:
			p.fearless_left = 0.0
		p.pace = maxf(pr.base_pace, 1.0)
		send_off(p)
	_release_escorts(pr)
	rules.banner.emit(_freed_banner())


## Believer of procession `i` burns (MS §6): the fire takes him -- hidden for good, counted burned -- and his escort goes back to its posts.
func _burn(i: int) -> void:
	var pr: Procession = procs[i]
	var c: Charge = pr.charge
	pr.phase = Procession.Phase.BURNED
	c.held = false
	c.taken = true
	if _alive(c.man):
		_take_inside(c.man as Person, null)
	_release_escorts(pr)
	rules.banner.emit(_burned_banner())


## The god killed believer of procession `i`: counted burned (MS §6). Once a look, from _households().
func _killed(i: int) -> void:
	var pr: Procession = procs[i]
	pr.phase = Procession.Phase.DEAD
	pr.charge.held = false
	_release_escorts(pr)
	rules.banner.emit("A BELIEVER IS KILLED - ONE MORE AND THE HUNT IS LOST" if burned() < FH_LOSE_BURNED else "A BELIEVER IS KILLED")


## A procession's escorts are let go: each one on duty goes back to his post (Crowd.off_duty()); one held by the god or afraid is left to it.
func _release_escorts(pr: Procession) -> void:
	for v: Variant in pr.escorts:
		if _alive(v) and not (v as Person).inside and (v as Person).mind == Person.Mind.DUTY and not is_leaving(v):
			crowd.off_duty(v as Person)


## One look at the processions (the base's, once a TICK): a believer the god killed is counted burned, then the base's households.
func _households() -> void:
	for i in procs.size():
		var pr: Procession = procs[i]
		if pr.charge != null and pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING, Procession.Phase.BURNING] \
				and not _alive(pr.charge.man) and not pr.charge.escaped and not pr.charge.taken:
			_killed(i)
	super()


## The places of `n` escorts round `center` (MS §6, MS §0: more than two Silent Doom radii apart, so one blow never takes two). Slot k wants the cell
## nearest the ring of FH_ESCORT_RING at its side of the believer (`turn` + k/n of a turn; slot 0 leads), among the walkable cells within FH_SPAN of
## `center` with a clear line to it; the first set (in order of wish) whose places are all FH_SPACE or more apart is taken, so on open ground the ring and
## in a lane the file along it (a third man 2.7 away). A slot keeps its previous place `prev[k]` unless another is clearly better (no jumping between
## looks). If no set has the gap, the widest the cells allow (1.5, 1.2, then any). With no walk grid, the plain ring. Only reads.
func escort_spots(center: Vector2, n: int, turn := 0.0, prev: Array = []) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if n <= 0:
		return out
	var grid: WalkGrid = crowd._grid
	if grid == null:
		for k in n:
			out.append(center + Vector2.from_angle(turn + TAU * float(k) / float(n)) * FH_ESCORT_RING)
		return out
	var cells: Array[Vector2] = []
	var span := ceili(FH_SPAN / WalkGrid.CELL)
	var base := grid.world_to_id(center)
	var eye := center if grid.walkable(center) else _walkable(center)  # (a person may graze a solid corner on a diagonal)
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var id := base + Vector2i(dx, dy)
			if not grid.grid.is_in_boundsv(id) or grid.grid.is_point_solid(id):
				continue
			var w := grid.id_to_world(id)
			var d := w.distance_to(center)
			if d > FH_SPAN or d < 0.7 or not grid.clear_line(eye, w):
				continue
			cells.append(w)
	if cells.is_empty():
		for k in n:
			out.append(_walkable(center))
		return out
	var wishes: Array = []
	for k in n:
		var side := turn + TAU * float(k) / float(n)
		var ranked: Array = []
		for w in cells:
			var cost := absf(w.distance_to(center) - FH_ESCORT_RING) + 0.35 * absf(angle_difference(side, (w - center).angle()))
			if k < prev.size() and prev[k] is Vector2:
				var moved := w.distance_to(prev[k] as Vector2)
				cost += 0.9 * moved - (0.6 if moved < 0.1 else 0.0)
			ranked.append([cost, w])
		ranked.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		wishes.append(ranked.slice(0, 40))
	for apart in [FH_SPACE_WIDE, FH_SPACE, 1.5, 1.2, 0.5, 0.0]:
		for reach in [FH_MOVE, FH_MOVE * 2.0, INF]:
			if reach < INF and prev.size() < n:
				continue
			var picked: Array[Vector2] = []
			if _pick_places(wishes, picked, float(apart), prev, float(reach)):
				return picked
	return out


## Fills `picked` with one place per slot of `wishes` (each slot's [cost, place] list, best first), every place `apart` or more from the others and
## no more than `reach` from the slot's previous place `prev[k]` (when it has one); false if no set does. (Depth first, so the first set found is the
## best-wished.)
func _pick_places(wishes: Array, picked: Array[Vector2], apart: float, prev: Array, reach: float) -> bool:
	if picked.size() == wishes.size():
		return true
	var k := picked.size()
	for entry: Array in wishes[k]:
		var w: Vector2 = entry[1]
		if reach < INF and k < prev.size() and prev[k] is Vector2 and w.distance_to(prev[k] as Vector2) > reach:
			continue
		var fits := true
		for q in picked:
			fits = fits and q.distance_to(w) >= apart - 0.001
		if not fits:
			continue
		picked.append(w)
		if _pick_places(wishes, picked, apart, prev, reach):
			return true
		picked.pop_back()
	return false


## Each procession still waiting whose chained time has come forms up (MS §6); its own time is the timeline's. The base's, with this Hunt's banner.
func _chain() -> void:
	for i in range(1, households.size()):
		var h: Household = households[i]
		if not h.out and (households[i - 1] as Household).done and _clock >= out_due(i):
			rules.banner.emit(_forms_banner(i))
			_come_out(i)


# --- The numbers ----------------------------------------------------------------------------------------------------------------------

## How many believers are freed (MS §6): out, by the break or by the walls.
func freed() -> int:
	return out_count()


## How many believers are burned: the fire's, and the god's kills (a believer dead before he was freed).
func burned() -> int:
	var n := 0
	for c in charges:
		if c.taken or (not c.escaped and not _alive(c.man)):
			n += 1
	return n


## Seconds procession `i`'s believer has left to burn once bound to the stake; 0 otherwise.
func burn_left(i: int) -> float:
	var pr: Procession = procs[i]
	return maxf(pr.burn_end - _clock, 0.0) if pr.phase == Procession.Phase.BURNING else 0.0


## Procession `i`'s phase.
func phase_of(i: int) -> Procession.Phase:
	return (procs[i] as Procession).phase


## Seconds until procession `i`'s believer reaches the pyre (INF for one already freed, burned or dead), as of this look: a waiting one counts its
## time to form up, the forming and the walk (Only reads.)
func pyre_in(i: int) -> float:
	var pr: Procession = procs[i]
	match pr.phase:
		Procession.Phase.WAITING:
			var h: Household = households[i]
			return due_in(i) + FH_FORM + _walk_secs(h.door)
		Procession.Phase.FORMING, Procession.Phase.MARCHING:
			return maxf(pr.eta - (_clock - pr.eta_at), 0.0)
		Procession.Phase.BURNING:
			return 0.0
	return INF


## The walk from `from` to the pyre at the believers' pace (the grid path's length over the speed).
func _walk_secs(from: Vector2) -> float:
	return _path_len(from, pyre_at) / maxf(Person.PANIC_SPEED * FH_PROC_PACE, 0.1)


## The grid path's length from `a` to `b` (the straight line with no grid or no path).
func _path_len(a: Vector2, b: Vector2) -> float:
	if crowd._grid == null:
		return a.distance_to(b)
	var path := crowd._grid.path(a, b)
	if path.is_empty():
		return a.distance_to(b)
	var len := 0.0
	var at := a
	for q: Vector2 in path:
		len += at.distance_to(q)
		at = q
	return len


## `pr`'s seconds to the pyre as of now: the forming time left and the believer's walk from where he stands.
func _refresh_eta(pr: Procession) -> void:
	pr.eta_at = _clock
	pr.eta = INF
	if pr.charge == null or not _alive(pr.charge.man):
		return
	var p := pr.charge.man as Person
	var t := 0.0
	if pr.phase == Procession.Phase.FORMING:
		t += maxf(pr.form_end - _clock, 0.0)
	pr.eta = t + _walk_secs(p.ground_pos)


# --- The loss, the banners, the strip, the tags ----------------------------------------------------------------------------------------

## Why the night is lost now (MS §6): "burned" once two believers are burned (or killed by the god). The Gaze and dawn are their own objectives.
func lost_reason() -> String:
	return "burned" if burned() >= FH_LOSE_BURNED else ""


## "Free the believers 1 / 3, 1 burned".
func hud_line() -> String:
	return "Free the believers %d / %d, %d burned" % [out_count(), tune_need, burned()]


func _opening_banner() -> String:
	return "FACE HALCYON"


## "A BELIEVER IS FREED  1/3" (two spaces, as MS §6).
func _freed_banner() -> String:
	return "A BELIEVER IS FREED  %d/%d" % [out_count(), tune_need]


func _burned_banner() -> String:
	return "A BELIEVER BURNS - ONE MORE AND THE HUNT IS LOST" if burned() < FH_LOSE_BURNED else "A BELIEVER BURNS"


## The strip (MS §6): "A believer reaches the pyre" counting down for each procession forming or walking, "The fire takes a believer" for each
## bound to the stake; soonest first.
func strip_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in procs.size():
		var pr: Procession = procs[i]
		if pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING]:
			out.append({"in": pyre_in(i), "label": FH_ROW})
		elif pr.phase == Procession.Phase.BURNING:
			out.append({"in": burn_left(i), "label": FH_ROW_BURN})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["in"]) < float(b["in"]))
	return out


## "pyre" while a believer is bound to the stake; "gaze" once the Gaze is FH_GAZE_HINT or more; else the mission's own line.
func hint_phase() -> String:
	if lost_reason() != "" or out_count() >= tune_need:
		return ""
	for pr in procs:
		if pr.phase == Procession.Phase.BURNING:
			return "pyre"
	if gaze != null and gaze.value >= FH_GAZE_HINT:
		return "gaze"
	return ""


## The map tags, most important first (MS §6): each believer bound to the stake and the pyre ("BURNING 0:12" with its ring filling), the leading
## procession's believer "PYRE IN 0:40", every other believer "BELIEVER", all "- DO NOT KILL", blue and pointed at; each able escort "ESCORT",
## red and pointed at; the pyre ("PYRE IN" its soonest procession's seconds, "PYRE" otherwise), orange, its pile outlined; each house still waiting
## "PROCESSION IN" its seconds, grey, the next pointed at.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if lost_reason() != "" or out_count() >= tune_need:
		return out
	var lead := -1
	var burning := -1
	for i in procs.size():
		var pr: Procession = procs[i]
		if pr.phase == Procession.Phase.BURNING:
			burning = i
		elif pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING] and (lead < 0 or pyre_in(i) < pyre_in(lead)):
			lead = i
	out.append(_pyre_tag(burning, lead))
	var order: Array[int] = []
	if burning >= 0:
		order.append(burning)
	if lead >= 0:
		order.append(lead)
	for i in procs.size():
		if not order.has(i):
			order.append(i)
	for i in order:
		var pr: Procession = procs[i]
		if not pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING, Procession.Phase.BURNING] or not _alive(pr.charge.man):
			continue
		var p := pr.charge.man as Person
		var words := "BELIEVER"
		if i == lead:
			words = "PYRE IN %s" % UiTheme.clock(ceilf(pyre_in(i)))
		out.append(MapTag.person(p.ground_pos, MARK_CHARGE, "%s - DO NOT KILL" % words, true))
	for i in order:
		var pr: Procession = procs[i]
		if not pr.phase in [Procession.Phase.FORMING, Procession.Phase.MARCHING, Procession.Phase.BURNING]:
			continue
		for v: Variant in pr.escorts:
			if _alive(v) and not (v as Person).inside and not is_leaving(v) and not _disabled(v as Person):
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "ESCORT", true))
	for i in households.size():
		if not (households[i] as Household).out:
			out.append(_waiting_tag(i))
	return out


## The pyre's tag: bound believer's countdown and ring, else the soonest procession's, else its name.
func _pyre_tag(burning: int, lead: int) -> MapTag:
	var words := "PYRE"
	var ring := -1.0
	if burning >= 0:
		words = "BURNING %s" % UiTheme.clock(ceilf(burn_left(burning)))
		ring = 1.0 - burn_left(burning) / FH_BURN
	elif lead >= 0:
		words = "PYRE IN %s" % UiTheme.clock(ceilf(pyre_in(lead)))
	var t := MapTag.place(pyre_at, MARK_PLACE, words, 0.0, true)
	t.outline = Rect2(pyre_at - Vector2(FH_PILE, FH_PILE), Vector2(FH_PILE, FH_PILE) * 2.0)
	t.ring = ring
	return t


## A waiting house's tag (MS §6): its door, grey, with the seconds until its procession forms up at the latest, counting down as the strip does.
func _waiting_tag(i: int) -> MapTag:
	var h: Household = households[i]
	return MapTag.place(h.door, MARK_NOT_YET, "PROCESSION IN %s" % UiTheme.clock(due_in(i)), h.house.height, i == upcoming())


## No hint counts down (the base's "waiting" phase is not this Hunt's).
func hint_seconds() -> float:
	return 0.0


## The tour (MS §6, *my call*): the first procession's house, the pyre; each line fits the caption's plate.
func tour() -> Array:
	var out := []
	if not households.is_empty():
		out.append([(households[0] as Household).door, "A believer in chains waits here, three soldiers round him. At %s they march." % UiTheme.clock(
			float(FH_PROC_AT[0]))])
	out.append([pyre_at, "The pyre. A believer burns %d s after he arrives. Break his escort first." % roundi(FH_BURN)])
	return out


## What the results show (MS §6): the base's keys (out, taken, seizures, reliefs, gaze), and the Hunt's.
func report() -> Dictionary:
	var out := super()
	out["freed"] = out_count()
	out["burned"] = burned()
	out["freed_broken"] = freed_broken
	out["freed_walls"] = freed_walls
	return out
