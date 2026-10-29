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
## before is freed or burned. Opposition stands more than 1.6 apart (MS §0): the escorts walk in file along the believer's road (Aldermere's lanes are one or
## two cells wide, no ring fits: _file_places(), the lead ahead, two behind along his trail, 2.4 apart along it), a house is chosen only if a lane behind
## its door has room for the file (_tail_from()), two escorts under 1.7 apart give way and the march waits for them (_give_way(), _march()), and two
## processions are never at one stake at a time (a second waits short of the pyre).
##
## Overrides of ExodusDirector (the MS §6 checklist): _plan() (houses, the pyre, no gates, no watch, no patrols), the tune_ vars (setup(), _tune()),
## _place_charge() (a bound believer in the escort; the base's _appoint_charges() serves, one a house by tune_per_house), _step_held() (replaces the
## Escort type's single-seizer march, which frees him the moment one seizer leaves DUTY and takes him at return_to: here the escort walks him to the pyre
## and he is freed only by the fewer-than-FH_ESCORT_HOLD-able rule), _step_free() (a believer waiting inside is left alone), _exit_reached() (no gates),
## _come_out() (the procession forms up; no searchers' strip row), _chain() (this Hunt's banner), _relieve_watch() (a no-op), _households() (the god's
## kills counted as burned), step() (those sent off walk on), _keep_held(), _in_use(), lost_reason() ("burned"), hud_line(), tags(), hint_phase(),
## strip_rows(), busy(), report(), tour().

## The processions' houses (MS §6 *fg*): the dwelling nearest each point whose door the street reaches from the pyre, with a walk of FH_WALK_MIN seconds
## or more and a lane behind it for the file (_roomy_door()): the west, the north, the south-east and the south-west (the spec's north-east (12.5, -11) has
## no dwelling more than 16 units from the pyre, and the north-east corner's doors are in pockets). The walk is 28-33 s estimated at pace 0.5 (the spec's
## 25-32 units and 50-64 s do not agree: Task 13's to tune); their words and the names on the tags and banners.
const FH_HOUSE_POINTS := [Vector2(-11.5, 7.0), Vector2(3.0, -12.0), Vector2(12.0, 12.0), Vector2(-8.0, 11.0)]
const FH_HOUSE_WORDS := ["the west procession", "the north procession", "the south-east procession", "the south-west procession"]
const FH_HOUSE_NAMES := ["WEST", "NORTH", "SOUTH-EAST", "SOUTH-WEST"]
## Where the pyre stands from the Temple's door (MS §6): 2.5 south of it, snapped to walkable ground.
const FH_PYRE_OFF := Vector2(0.0, 2.5)
## How many soldiers escort a believer (*fg*; MS §7 tunes it to 2), how far from him they ring where there is room (1.7 apart for three), how many able
## escorts keep him bound (fewer frees him), and how near him -- or his place -- an escort must stand to be with the procession.
const FH_ESCORT := 3
const FH_ESCORT_RING := 1.0
const FH_ESCORT_HOLD := 2
const FH_ESCORT_REACH := 1.6
## Aldermere's lanes are one or two cells wide, so three escorts more than 1.6 apart cannot all stand within FH_ESCORT_REACH of the believer (two in a
## line is all that fits), and a ring cannot be walked in a lane. The escorts therefore walk in file along the believer's own road (review of Task 8, I1):
## the lead FH_LEAD ahead of him along the road to the pyre, the second FH_BACK1 behind him along his trail and the third FH_BACK2 behind (2.4 apart along
## the road, so even round a right-angled lane corner they are 1.7 apart), each place moving smoothly with him so nobody passes another. Each escort is
## with the procession while he stands within FH_ESCORT_REACH of the believer or of his own place (Ruling P5-T8-R1). Walking, he lags his place a moment,
## so an escort that is with the procession by neither is not able only after FH_GRACE seconds of it; one the god has disabled is not able at once.
const FH_LEAD := 1.4
const FH_BACK1 := 1.8
const FH_BACK2 := 4.4
const FH_SPAN := 5.0
const FH_SPACE := 1.7
const FH_GRACE := 2.0
## How far the believer must move before his trail takes another point.
const FH_TRAIL_STEP := 0.25
## A walker stops up to this far short of his place (Person.GOAL_REACH): a give-way cell is this much farther than FH_SPACE from the others.
const FH_STOP_SHORT := 0.45
## The shortest walk (seconds, estimated at the believers' pace) a procession's house may be from the pyre: he is bound at 1.2 from the pyre and a walker stops
## short of a goal, which together take about 2.5 s off the estimate, so forming 8 + (27.5 - 2.5) + burning 12 make at least 45 s, the room an instant loss is
## warned with (MS §0; review of wave 1, point b).
const FH_WALK_MIN := 27.5
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
## pyre's keep 60 px clear of the padded HUD stack (found by search over the town: the doors pull the camera north-west).
const FH_CAMERA_AT := Vector2(-7.0, -4.5)

## One procession (god P5, MS §6): a plain record, so the director holds no cycle.
class Procession:
	extends RefCounted
	## Where it is in its night: waiting in its house, forming up at its door, walking, bound to the stake, freed, burned, or its believer dead.
	enum Phase { WAITING, FORMING, MARCHING, BURNING, FREED, BURNED, DEAD }
	var phase := Phase.WAITING
	## The believer's Charge record and his soldiers (Variants: any may be freed).
	var charge: EscortDirector.Charge
	var escorts: Array = []
	## Where each escort is sent (_file_places()).
	var places: Array[Vector2] = []
	## The clock second each escort first stood with the procession by neither of his two measures (-1 while he does).
	var apart: Array[float] = []
	## The believer's own pace before it was slowed.
	var base_pace := 1.0
	## The second (the director's clock) forming ends and the burning ends.
	var form_end := 0.0
	var burn_end := 0.0
	## The seconds the march has waited for a straggler or a close pair.
	var stall := 0.0
	## Where the believer has been, oldest first (seeded with the lane behind his door): the second and third escorts walk along it.
	var trail: Array[Vector2] = []
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
## FH_WALK_MIN seconds (so a burn is warned FH_FORM + FH_WALK_MIN + FH_BURN seconds ahead) and a lane behind it for the escorts (_tail_from()); Vector2.INF for none.
## Only reads.
func _roomy_door(s: Structure) -> Vector2:
	var half := s.footprint.size * 0.5 + Vector2(0.5, 0.5)
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(0.0, -half.y), Vector2(half.x, 0.0), Vector2(-half.x, 0.0)]:
		var door := _walkable(s.center() + off)
		if crowd._grid != null and crowd._grid.path(pyre_at, door).is_empty():
			continue
		if _walk_secs(door) < FH_WALK_MIN:
			continue
		if not _tail_from(door, _road(door)).is_empty():
			return door
	return Vector2.INF


## A lane behind `door`, off the road (the walk grid's path from it to the pyre), long enough for the second and third escorts to stand in (BFS over the
## cells that are not within a unit of the road's first three units): the cells from its far end to `door`, rear first, the last `door` itself; empty
## when there is no such lane (a door in a pocket).
func _tail_from(door: Vector2, road: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var grid: WalkGrid = crowd._grid
	if grid == null:
		return out
	var shut: Array[Vector2] = []
	var along := 0.5
	while along <= 2.0:
		shut.append(_along(road, along))
		along += 0.5
	var lead := _along(road, FH_LEAD)
	var start := grid.world_to_id(door)
	var depth := {start: 0}
	var parent := {start: start}
	var queue: Array[Vector2i] = [start]
	var ends: Array[Vector2i] = []
	var limit := ceili((FH_BACK2 + 0.6) / WalkGrid.CELL)
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		var d: int = depth[at]
		if d >= limit:
			ends.append(at)
			continue
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt := at + step
			if depth.has(nxt) or not grid.grid.is_in_boundsv(nxt) or grid.grid.is_point_solid(nxt):
				continue
			var w := grid.id_to_world(nxt)
			var blocked := false
			for q in shut:
				blocked = blocked or w.distance_to(q) < 0.7
			if blocked:
				continue
			depth[nxt] = d + 1
			parent[nxt] = at
			queue.append(nxt)
	ends.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return grid.id_to_world(a).distance_to(door) > grid.id_to_world(b).distance_to(door))
	for end in ends.slice(0, 24):
		var tail: Array[Vector2] = []
		var cell: Vector2i = end
		while cell != start:
			tail.append(grid.id_to_world(cell))
			cell = parent[cell]
		tail.append(door)
		var back: Array[Vector2] = []
		for k in range(tail.size() - 1, -1, -1):
			back.append(tail[k])
		var mid := _along(back, FH_BACK1)
		var rear := _along(back, FH_BACK2)
		if lead.distance_to(mid) >= FH_SPACE + 0.1 and mid.distance_to(rear) >= FH_SPACE + 0.1 and lead.distance_to(rear) >= FH_SPACE + 0.1:
			return tail
	return out


## The grid path from `from` to the pyre as a polyline starting at `from`, points behind him (the path starts at the cell he stands in) dropped.
func _road(from: Vector2) -> Array[Vector2]:
	var line: Array[Vector2] = [from]
	if crowd._grid == null:
		line.append(pyre_at)
		return line
	var path := crowd._grid.path(from, pyre_at)
	for k in path.size():
		var q: Vector2 = path[k]
		if k + 1 < path.size() and (from - q).dot(path[k + 1] - q) > 0.0:
			continue
		if q.distance_to(line.back()) > 0.05:
			line.append(q)
	return line


## The point `d` along polyline `line` from its first point (its last point if it is shorter).
static func _along(line: Array[Vector2], d: float) -> Vector2:
	var left := d
	for k in range(line.size() - 1):
		var seg := line[k].distance_to(line[k + 1])
		if seg >= left:
			return line[k].move_toward(line[k + 1], left)
		left -= seg
	return line.back()


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
	pr.trail = _tail_from(h.door, _road(h.door))
	if pr.trail.is_empty():
		pr.trail = [h.door]
	pr.places = _file_places(pr, h.door)
	var spots := pr.places
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
## for an escort straggling (FH_LAG) or a fit pair under FH_SPACE apart (they sort themselves out, _give_way()), at most FH_STRAGGLE seconds in all.
func _march(pr: Procession, p: Person) -> void:
	var dist := p.ground_pos.distance_to(pyre_at)
	if dist <= FH_PYRE_REACH:
		pr.phase = Procession.Phase.BURNING
		pr.burn_end = _clock + FH_BURN
		_stand_at(p, pyre_at)
		return
	if dist <= FH_QUEUE and _pyre_busy(pr):
		_stand_at(p, p.ground_pos)
		return
	if _straggling(pr) or _pair_close(pr):
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


## The trail takes the believer's place when he has moved FH_TRAIL_STEP, and is cut to what the file needs (FH_BACK2 and a margin).
func _note_trail(pr: Procession, p: Person) -> void:
	if pr.trail.is_empty() or p.ground_pos.distance_to(pr.trail.back()) >= FH_TRAIL_STEP:
		pr.trail.append(p.ground_pos)
	var run := 0.0
	for k in range(pr.trail.size() - 1, 0, -1):
		run += pr.trail[k].distance_to(pr.trail[k - 1])
		if run > FH_BACK2 + 1.5:
			pr.trail = pr.trail.slice(k - 1)
			break


## The three escorts' places for a believer standing at `at` (review of Task 8, I1): the lead FH_LEAD ahead along the road to the pyre (past its end, straight
## on), the second FH_BACK1 and the third FH_BACK2 behind along his trail (the last point of it if shorter); one place each, in that order. Only reads.
func _file_places(pr: Procession, at: Vector2) -> Array[Vector2]:
	var ahead := _road(at)
	if _along_length(ahead) < FH_LEAD + 0.1:
		var dir := Vector2.ZERO
		if ahead.size() >= 2:
			dir = (ahead[ahead.size() - 1] - ahead[ahead.size() - 2]).normalized()
		elif pr.trail.size() > 1 and at.distance_to(pr.trail[maxi(pr.trail.size() - 5, 0)]) > 0.05:
			dir = (at - pr.trail[maxi(pr.trail.size() - 5, 0)]).normalized()
		ahead.append(ahead.back() + (dir if dir != Vector2.ZERO else Vector2.DOWN) * 3.0)
	var behind: Array[Vector2] = [at]
	for k in range(pr.trail.size() - 1, -1, -1):
		if pr.trail[k].distance_to(behind.back()) > 0.05:
			behind.append(pr.trail[k])
	var out: Array[Vector2] = [_walkable(_along(ahead, FH_LEAD)), _walkable(_along(behind, FH_BACK1)), _walkable(_along(behind, FH_BACK2))]
	return out.slice(0, pr.escorts.size())


## The length of polyline `line`.
func _along_length(line: Array[Vector2]) -> float:
	var n := 0.0
	for k in range(line.size() - 1):
		n += line[k].distance_to(line[k + 1])
	return n


## Each fit escort of `pr` sent to his place in the file (MS §6): one under the god's hold, afraid or frail is left be, and one back on his feet (or taken
## off the errand by the town) goes back to his place. The places move with the believer; two fit escorts under FH_SPACE apart give way (_give_way()).
func _order_escorts(pr: Procession, p: Person) -> void:
	_note_trail(pr, p)
	pr.places = _file_places(pr, p.ground_pos)
	var target: Array[Vector2] = pr.places.duplicate()
	_give_way(pr, target)
	for k in pr.escorts.size():
		if not _fit(pr, k):
			continue
		var e := pr.escorts[k] as Person
		if e.mind != Person.Mind.DUTY or e.anchor.distance_to(target[k]) > MOVE:
			e.go_duty(target[k])


## Escort `k` of `pr` is fit: alive, out of doors, not being sent off, not disabled by the god (he can be sent to his place).
func _fit(pr: Procession, k: int) -> bool:
	var v: Variant = pr.escorts[k]
	return _alive(v) and not (v as Person).inside and not is_leaving(v) and not _disabled(v as Person)


## Two fit escorts of `pr` stand under FH_SPACE apart (the walk's give-way, review of Task 8, I1): the one farther from his own place is sent to the walkable
## cell nearest his place that is FH_SPACE or more from the other and from every other fit escort, on the side away from the other (not through him).
## `target` (one place per escort) is changed for him. Only reads the world.
func _give_way(pr: Procession, target: Array[Vector2]) -> void:
	var fit: Array[int] = []
	for k in pr.escorts.size():
		if _fit(pr, k):
			fit.append(k)
	for a in fit.size():
		for b in range(a + 1, fit.size()):
			var i := fit[a]
			var j := fit[b]
			var ei := pr.escorts[i] as Person
			var ej := pr.escorts[j] as Person
			if ei.ground_pos.distance_to(ej.ground_pos) >= FH_SPACE:
				continue
			var loser := i if ei.ground_pos.distance_to(target[i]) > ej.ground_pos.distance_to(target[j]) else j
			var other := j if loser == i else i
			var rest: Array[Vector2] = []
			for k in fit:
				if k != loser:
					rest.append((pr.escorts[k] as Person).ground_pos)
			var cell := _give_way_cell((pr.escorts[loser] as Person).ground_pos, target[loser], (pr.escorts[other] as Person).ground_pos, rest)
			if cell != Vector2.INF:
				target[loser] = cell


## The walkable cell nearest `place` (within FH_SPAN of it) that a man standing at `from` can step to without passing the one at `away`: FH_SPACE or more
## from every point of `rest` (the other fit escorts), a clear line from `from`, on the far side of `from` from `away`. Vector2.INF for none.
func _give_way_cell(from: Vector2, place: Vector2, away: Vector2, rest: Array[Vector2]) -> Vector2:
	var grid: WalkGrid = crowd._grid
	if grid == null:
		return Vector2.INF
	var span := ceili(FH_SPAN / WalkGrid.CELL)
	var base := grid.world_to_id(place)
	var best := Vector2.INF
	var best_cost := INF
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var id := base + Vector2i(dx, dy)
			if not grid.grid.is_in_boundsv(id) or grid.grid.is_point_solid(id):
				continue
			var w := grid.id_to_world(id)
			if w.distance_to(place) > FH_SPAN or (w - from).dot(from - away) < -0.01 or w.distance_to(away) < FH_SPACE + FH_STOP_SHORT:
				continue
			var fits := true
			for q in rest:
				fits = fits and w.distance_to(q) >= FH_SPACE + FH_STOP_SHORT
			if not fits or not grid.clear_line(from, w):
				continue
			var cost := w.distance_to(place) + 0.2 * w.distance_to(from)
			if cost < best_cost:
				best_cost = cost
				best = w
	return best


## Two fit escorts of `pr` stand under FH_SPACE apart now.
func _pair_close(pr: Procession) -> bool:
	var live: Array[Vector2] = []
	for k in pr.escorts.size():
		if _fit(pr, k):
			live.append((pr.escorts[k] as Person).ground_pos)
	for a in live.size():
		for b in range(a + 1, live.size()):
			if live[a].distance_to(live[b]) < FH_SPACE:
				return true
	return false


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
	if pr.phase == Procession.Phase.MARCHING and (_straggling(pr) or _pair_close(pr)):
		pr.eta += maxf(FH_STRAGGLE - pr.stall, 0.0)  # the countdown counts the wait the march may be holding for


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
		for k in pr.escorts.size():
			if _able(pr, k):
				out.append(MapTag.person((pr.escorts[k] as Person).ground_pos, MARK_WATCHED, "ESCORT", true))
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
