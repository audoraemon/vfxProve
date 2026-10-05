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
const GRIEVING := 12
const FAITHFUL := 12
## How near the door a person must stand to go in; how long a reading takes.
const DOOR_REACH := 0.7
const READ_SECONDS := 8.0
## How far a Faithful sees someone at the door, and hears a Believer crying out.
const SIGHT := 3.0
const HEAR := 6.0
## The marks over the grieving and the Believers.
const MARK_GRIEVING := Color(0.85, 0.75, 0.45, 0.8)
const MARK_BELIEVER := Color("ff9a3a")
## Minds a Faithful does not see from: the god's own holds.
const BLIND := [Person.Mind.CONFUSED, Person.Mind.WHISPERED]
## How near a lure's light must stand to the house, and its lured to the house, for them to go in: a Will-o'-Wisp stands
## its lured on a ring up to WillOWisp.RING.y from the light.
const LURE_REACH := WillOWisp.RING.y + Person.GOAL_REACH
## 0:40 -- the Inquisitor searches the west quarter house by house, ending at Mira's: she stops VENN_STOP seconds at each
## of the VENN_HOUSES houses nearest the door (farthest first), and at Mira's, with anyone inside, she reports at once.
const VENN_AT := 40.0
const VENN_STOP := 3.0
const VENN_REACH := 1.0
const VENN_HOUSES := 6
## 1:15 -- the newest Believer out runs into the street crying (SHOUT_OFF from the door); left SHOUT_SECONDS with a
## Faithful within HEAR, it is reported.
const SHOUT_AT := 75.0
const SHOUT_SECONDS := 15.0
const SHOUT_OFF := Vector2(0.0, 3.0)
## 1:45 -- the Vigil passes the door, and Faithful line the street by it for VIGIL_SECONDS (offsets from the door).
const VIGIL_AT := 105.0
const VIGIL_SECONDS := 30.0
const LINE_SPOTS := [Vector2(-1.2, 1.5), Vector2(1.2, 1.5), Vector2(-1.2, -1.5), Vector2(1.2, -1.5)]
## The Vigil's way past the door (offsets from it).
const VIGIL_ROUTE := [Vector2(6.0, -4.0), Vector2(0.0, -2.5), Vector2(0.0, 2.5), Vector2(6.0, 4.0)]
## 2:00 -- the priests burn the house.
const FIRE_AT := 120.0
const FIRE_LEVEL := 0.6
## Minds a searcher takes the search up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

var house: Structure
var door := Vector2.INF
var temple_door := Vector2.INF
## The grieving, Believers among them once they have read.
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
var venn_searching := false
var shouter: Person
var vigil: VigilRoute
var liners: Array[Person] = []
var _venn_houses: Array[Vector2] = []
var _venn_i := 0
var _venn_wait := 0.0
var _shout_left := 0.0
var _liners_left := 0.0
## Person -> seconds of reading left, for everyone inside.
var _reading := {}
## Persons turned away at the door, until they step away from it.
var _turned := {}


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


## The GRIEVING lay citizens nearest the door grieve; the clergy and FAITHFUL others, spread through the rest, are Halcyon's
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
	gaze.judge_deaths(crowd)
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


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)
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
		if not _brought(p):
			_turned.erase(p)
			continue
		if _turned.has(p):
			continue
		var seer := faithful_seeing(door, SIGHT)
		if seer != null:
			_turned[p] = true
			_report(seer)
			continue
		_enter(p)


## Brought to the house by the god: whispered to any face of it (the drawn door may be on another face than `door`), or
## lured to a light standing by it and watching it from the light's ring. A citizen who stops by the house to look at
## something else is not.
func _brought(p: Person) -> bool:
	match p.mind:
		Person.Mind.WHISPERED:
			return _near_house(p.ground_pos, DOOR_REACH)
		Person.Mind.OBSERVE:
			return p._threat != Vector2.INF and _near_house(p._threat, LURE_REACH) and _near_house(p.ground_pos, LURE_REACH)
	return false


func _near_house(at: Vector2, reach: float) -> bool:
	if at.distance_to(door) <= reach:
		return true
	return house != null and house.footprint.grow(reach).has_point(at)


func _enter(p: Person) -> void:
	p.inside = true
	p.visible = false
	p.ground_pos = house.center() if house != null else door
	crowd._field.remove(p)
	_reading[p] = READ_SECONDS
	_entered(p)




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
	vigil = null
	timeline = null


func _add_events() -> void:
	timeline.add(VENN_AT, "venn", "The Inquisitor searches", _venn_starts, func() -> bool: return _alive(venn))
	timeline.add(SHOUT_AT, "shout", "A believer cries out", _shout, func() -> bool: return _newest_outside() != null)
	timeline.add(VIGIL_AT, "vigil", "The Vigil passes", _vigil_passes)
	timeline.add(FIRE_AT, "fire", "They burn her house", _burn, func() -> bool: return house != null and not house.destroyed)


func _step_events(delta: float) -> void:
	_venn_step(delta)
	_shout_step(delta)
	if vigil != null:
		vigil.step(delta)
	_liners_step(delta)
	if not burning and house != null and house.destroyed:
		_flush()  # destroyed before the fire (review focus 2)


## The crying Believer whispered back in: the cry is over.
func _entered(p: Person) -> void:
	if p == shouter:
		shouter = null


func _venn_starts() -> void:
	var near: Array[Structure] = []
	for s: Structure in town._built:
		if s.kind == Structure.Kind.HOUSE and s.role == &"house" and not s.destroyed and s != house \
				and s.center().distance_to(door) <= 9.0:
			near.append(s)
	near.sort_custom(func(a: Structure, b: Structure) -> bool: return a.center().distance_to(door) > b.center().distance_to(door))
	_venn_houses = []
	for s in near.slice(maxi(0, near.size() - VENN_HOUSES)):
		_venn_houses.append(_door_of(s))
	_venn_houses.append(door)
	_venn_i = 0
	_venn_wait = 0.0
	venn_searching = true
	venn.go_duty(_venn_houses[0])


func _venn_step(delta: float) -> void:
	if not venn_searching:
		return
	if not _alive(venn) or _carrying(venn):
		venn_searching = false
		return
	var goal := _venn_houses[_venn_i]
	if venn.mind != Person.Mind.DUTY:
		if venn.mind in RESUMABLE:
			venn.go_duty(goal)
		return
	if venn.ground_pos.distance_to(goal) > VENN_REACH and venn.has_goal():
		return
	if goal == door and not _reading.is_empty():
		venn_searching = false
		_report(venn)
		return
	_venn_wait += delta
	if _venn_wait >= VENN_STOP:
		_venn_wait = 0.0
		_venn_i = (_venn_i + 1) % _venn_houses.size()
		venn.go_duty(_venn_houses[_venn_i])


func _newest_outside() -> Person:
	for i in range(believers.size() - 1, -1, -1):
		var p := believers[i]
		if _alive(p) and not p.inside:
			return p
	return null


func _shout() -> void:
	shouter = _newest_outside()
	if shouter == null:
		return
	_shout_left = SHOUT_SECONDS
	shouter.go_duty(_walkable(door + SHOUT_OFF))


func _shout_step(delta: float) -> void:
	if shouter == null:
		return
	if not _alive(shouter):
		shouter = null
		return
	_shout_left -= delta
	if _shout_left > 0.0:
		return
	var heard := faithful_seeing(shouter.ground_pos, HEAR)
	if shouter.mind == Person.Mind.DUTY:
		shouter.leave_shelter(false)
	shouter = null
	if heard != null:
		_report(heard)


## The flame-bearer and his acolytes: the clergy nearest the Temple (not the Inquisitor), else any Faithful.
func _vigil_passes() -> void:
	var free: Array[Person] = []
	for f in faithful:
		if _alive(f) and not f.inside and f != venn and not _carrying(f):
			free.append(f)
	free.sort_custom(func(a: Person, b: Person) -> bool:
		var ca := a.profile.role == CitizenProfile.Role.CLERGY
		var cb := b.profile.role == CitizenProfile.Role.CLERGY
		if ca != cb:
			return ca
		return a.ground_pos.distance_to(temple_door) < b.ground_pos.distance_to(temple_door))
	if not free.is_empty():
		var route := PackedVector2Array()
		for off in VIGIL_ROUTE:
			route.append(_walkable(door + (off as Vector2)))
		var acolytes: Array[Person] = []
		acolytes.assign(free.slice(1, 3))
		vigil = VigilRoute.new().setup(route, free[0], acolytes)
		vigil.busy = _carrying
		vigil.start()
	var walking := vigil.walkers() if vigil != null else ([] as Array[Person])
	var lining: Array[Person] = []
	for f in free:
		if not walking.has(f):
			lining.append(f)
	lining.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	liners = []
	for i in mini(LINE_SPOTS.size(), lining.size()):
		lining[i].go_duty(_walkable(door + (LINE_SPOTS[i] as Vector2)))
		liners.append(lining[i])
	_liners_left = VIGIL_SECONDS


func _liners_step(delta: float) -> void:
	if liners.is_empty():
		return
	_liners_left -= delta
	if _liners_left > 0.0:
		return
	for f in liners:
		if _alive(f) and f.mind == Person.Mind.DUTY and not _carrying(f):
			f.leave_shelter(false)
	liners = []


func _burn() -> void:
	burning = true
	if crowd.fires != null:
		crowd.fires.ignite(house, FIRE_LEVEL)
	_flush()


## Everyone inside runs out at the door in a fright, unconverted if their reading was not done.
func _flush() -> void:
	burning = true
	for p: Person in _reading.keys():
		_reading.erase(p)
		if not is_instance_valid(p):
			continue
		_exit(p)
		p.panic(house.center() if house != null else door, 2.0)


func _carrying(p: Person) -> bool:
	for r in reports:
		if r.carrier == p:
			return true
	return false


## The HUD's arrow: the Believer crying in the street.
func marker() -> Vector2:
	return shouter.ground_pos if _alive(shouter) else Vector2.INF


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
