class_name MirasHouseDirector
extends MissionDirector
## Mira's House (v0.10 M2, the Faith path's Night 2): Mira's house in the west quarter has been shut since the burning;
## inside are her shrine and Cael's journal. A grieving citizen brought to its door -- by Mind Whisper, or a
## Will-o'-Wisp's lure -- goes in, reads for READ_SECONDS and comes out a Believer. Halcyon's Faithful must not see it: a
## Faithful who sees someone go in turns them away, one who sees a Believer come out lets them go; either runs to the
## Temple to report it (TempleReport), and a report reaching the Temple fills Halcyon's Gaze. A death someone sees adds to
## it; the bell fills it. A Faithful held by Discord or a whisper sees nothing. Task 5's windows: the Inquisitor's search,
## a Believer crying out, the Vigil passing the door, and the priests burning the house.

## Where Mira lived: her house is the one nearest this point (ground units).
const MIRA_SPOT := Vector2(-12.0, 2.0)
## How many grieving there are, and how many Faithful besides the clergy.
const GRIEVING := 10
const FAITHFUL := 20
## How near the door a person must stand to go in; how long a reading takes.
const DOOR_REACH := 0.7
const READ_SECONDS := 10.0
## How far a Faithful sees someone at the door, and hears a Believer crying out.
const SIGHT := 4.0
const HEAR := 6.0
## The marks over the grieving and the Believers.
const MARK_GRIEVING := Color(0.85, 0.75, 0.45, 0.8)
const MARK_BELIEVER := Color("ff9a3a")
## Minds a Faithful does not see from: the god's own holds.
const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]
## Minds a person going in may be in: brought by the god (a whisper, or a lure's watching mind).
const BROUGHT := [Person.Mind.WHISPERED, Person.Mind.OBSERVE]

var house: Structure
var door := Vector2.INF
var temple_door := Vector2.INF
## The ten grieving, Believers among them once they have read.
var grieving: Array[Person] = []
var faithful: Array[Person] = []
var believers: Array[Person] = []
var reports: Array[TempleReport] = []
var reports_started := 0
var venn: Person
## The last Believer to finish reading: the journal goes with them.
var journal: Person
var burning := false
var roof_fallen := false
## Person -> seconds of reading left, for everyone inside.
var _reading := {}
## Persons turned away at the door, until they step away from it.
var _turned := {}
## Where people died this step, judged once the crowd has judged its own doomed.
var _deaths: Array[Vector2] = []


func _begin() -> void:
	gaze = GazeMeter.new()
	house = _find_house()
	door = _door_of(house) if house != null else _walkable(MIRA_SPOT)
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	_choose_people()
	crowd._field.enemy_killed.connect(_on_killed)
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	_add_events()
	rules.banner.emit("LEAD THE GRIEVING TO MIRA'S HOUSE")


## Task 5 fills this in with the night's windows.
func _add_events() -> void:
	pass


func _find_house() -> Structure:
	var best: Structure = null
	for s: Structure in town._built:
		if s.kind != Structure.Kind.HOUSE or s.role != &"house" or s.destroyed:
			continue
		if best == null or s.center().distance_to(MIRA_SPOT) < best.center().distance_to(MIRA_SPOT):
			best = s
	return best


## A house's door: free ground just off its front (its +y face).
func _door_of(s: Structure) -> Vector2:
	return _walkable(s.center() + Vector2(0.0, s.footprint.size.y * 0.5 + 0.5))


func _walkable(g: Vector2) -> Vector2:
	var w := crowd._grid.nearest_walkable(g) if crowd._grid != null else g
	return w if w != Vector2.INF else g


## The ten lay citizens nearest the door grieve; the clergy and FAITHFUL others, spread through the rest, are Halcyon's
## Faithful; the cleric nearest the Temple is the Inquisitor.
func _choose_people() -> void:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper:
			continue
		if p.profile.role == CitizenProfile.Role.CLERGY:
			clergy.append(p)
		elif not p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			lay.append(p)
	lay.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	for i in mini(GRIEVING, lay.size()):
		lay[i].profile.faith = CitizenProfile.Faith.GRIEVING
		grieving.append(lay[i])
	for p in clergy:
		_make_faithful(p)
	var rest := lay.slice(GRIEVING)
	if not rest.is_empty():
		var stride := maxi(1, rest.size() / FAITHFUL)
		var i := stride / 2
		var added := 0
		while i < rest.size() and added < FAITHFUL:
			_make_faithful(rest[i])
			added += 1
			i += stride
	var pool := clergy if not clergy.is_empty() else faithful
	for p in pool:
		if venn == null or p.ground_pos.distance_to(temple_door) < venn.ground_pos.distance_to(temple_door):
			venn = p


func _make_faithful(p: Person) -> void:
	p.profile.faith = CitizenProfile.Faith.FAITHFUL
	faithful.append(p)


func step(delta: float) -> void:
	timeline.step(delta)
	_judge_deaths()
	_doors()
	_read(delta)
	for r in reports:
		r.step(delta, crowd)
		if r.delivered:
			gaze.fill()
	reports.assign(reports.filter(func(r: TempleReport) -> bool: return r.is_open()))
	_step_events(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()
	if rules.time_left <= 0.0 and not roof_fallen:
		_roof()


## Task 5's windows, stepped each frame.
func _step_events(_delta: float) -> void:
	pass


## A death someone saw adds to the Gaze, judged once the cast's other victims are dead too.
func _judge_deaths() -> void:
	if _deaths.is_empty() or not crowd._doomed.is_empty():
		return
	for at in _deaths:
		if crowd.nearest_witness(at) != null:
			gaze.seen_death()
	_deaths.clear()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	_deaths.append(e.ground_pos)
	for r in reports:
		r.on_killed(e)


## The grieving the god has brought to the door go in, unless a Faithful sees: then they are turned away and reported.
## Once the house burns, nobody goes in.
func _doors() -> void:
	if burning or roof_fallen:
		return
	for p in grieving:
		if not _alive(p) or p.inside or _reading.has(p):
			continue
		if p.ground_pos.distance_to(door) > DOOR_REACH:
			_turned.erase(p)
			continue
		if _turned.has(p) or not p.mind in BROUGHT:
			continue
		var seer := faithful_seeing(door, SIGHT)
		if seer != null:
			_turned[p] = true
			_report(seer)
			continue
		_enter(p)


func _enter(p: Person) -> void:
	p.inside = true
	p.visible = false
	p.ground_pos = house.center() if house != null else door
	crowd._field.remove(p)
	_reading[p] = READ_SECONDS
	_entered(p)


## Task 5: someone went in (the crying Believer whispered back resolves the cry).
func _entered(_p: Person) -> void:
	pass


func _read(delta: float) -> void:
	for p: Person in _reading.keys():
		if not is_instance_valid(p):
			_reading.erase(p)
			continue
		_reading[p] = float(_reading[p]) - delta
		if float(_reading[p]) > 0.0:
			continue
		_reading.erase(p)
		if not believers.has(p):
			believers.append(p)
			p.profile.faith = CitizenProfile.Faith.BELIEVER
			journal = p
			rules.banner.emit("%d BELIEVE" % believers.size())
		_exit(p)


## Out at the door, back to their day -- and reported if a Faithful sees.
func _exit(p: Person) -> void:
	p.inside = false
	p.visible = true
	p.ground_pos = door
	crowd._field.add(p)
	p.leave_shelter(false)
	var seer := faithful_seeing(door, SIGHT)
	if seer != null:
		_report(seer)


## A Faithful runs to the Temple, unless already carrying a report.
func _report(seer: Person) -> void:
	for r in reports:
		if r.carrier == seer:
			return
	reports.append(TempleReport.new(seer, temple_door))
	reports_started += 1
	rules.banner.emit("A FAITHFUL RUNS TO THE TEMPLE")


## Dawn: the roof falls on whoever is still inside, and the house is gone.
func _roof() -> void:
	roof_fallen = true
	for p: Person in _reading.keys():
		if not is_instance_valid(p):
			continue
		p.inside = false
		p.visible = true
		p.ground_pos = door
		crowd._field.add(p)
		crowd._field.kill(p, &"fire")
	_reading.clear()
	if house != null and not house.destroyed:
		house.destroy(house.center(), &"fire")


## The nearest Faithful within `reach` of `at` who is out in the open, alive, and not held by the god; else null.
func faithful_seeing(at: Vector2, reach: float) -> Person:
	var best: Person = null
	for f in faithful:
		if not _alive(f) or f.inside or f.mind in BLIND:
			continue
		var d := f.ground_pos.distance_to(at)
		if d <= reach and (best == null or d < best.ground_pos.distance_to(at)):
			best = f
	return best


func believers_outside() -> int:
	var n := 0
	for p in believers:
		n += 1 if _alive(p) and not p.inside else 0
	return n


func inside() -> Array[Person]:
	var out: Array[Person] = []
	for p: Person in _reading.keys():
		out.append(p)
	return out


func marks() -> Array:
	var out := []
	for p in grieving:
		if _alive(p) and not p.inside:
			out.append([p.ground_pos, MARK_BELIEVER if believers.has(p) else MARK_GRIEVING])
	return out


func report() -> Dictionary:
	return {"believers": believers_outside(), "reports": reports_started}


func teardown() -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	timeline = null


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
