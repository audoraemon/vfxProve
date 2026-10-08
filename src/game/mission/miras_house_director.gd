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
## The tags' other colours (v0.10 M6, spec §4.1): the house's gold; its door clear (green) or watched (red), the red a
## runner, the Temple and each watcher share; the Inquisitor's violet.
const MARK_HOUSE := Color("d8b23a")
const MARK_CLEAR := Color("7fc46a")
const MARK_WATCHED := Color("c8342a")
const MARK_VENN := Color("c070ff")
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
var believers: Array[Person] = []
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
## How many Believers out win the night (v0.11 M2: First Prayers needs three); BelieversObjective reads it.
var need := BelieversObjective.NEED
## Seconds a reading takes (v0.11 M2: First Prayers' prayer is longer).
var read_seconds := READ_SECONDS
## Only one inside at a time (v0.11 M2: the old well shrine): the next waits at the door until it is free.
var one_at_a_time := false


func _begin() -> void:
	gaze = GazeMeter.new()
	house = _find_house()
	door = _door_of(house) if house != null else _walkable(MIRA_SPOT)
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	_choose_people()
	crowd._field.enemy_killed.connect(_on_killed)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	_add_events()
	rules.banner.emit(_opening_banner())


## The night's opening banner (v0.11 M2: a subclass names its own).
func _opening_banner() -> String:
	return "LEAD THE GRIEVING TO MIRA'S HOUSE"


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


## The GRIEVING lay citizens nearest the door grieve; the clergy and FAITHFUL others, spread through the rest, are Halcyon's
## Faithful; the cleric nearest the Temple is the Inquisitor.
func _choose_people() -> void:
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	lay.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_to(door) < b.ground_pos.distance_to(door))
	for i in mini(GRIEVING, lay.size()):
		lay[i].profile.faith = CitizenProfile.Faith.GRIEVING
		grieving.append(lay[i])
	for p in clergy:
		_make_faithful(p)
	var rest: Array[Person] = []
	rest.assign(lay.slice(GRIEVING))
	_spread_faithful(rest, FAITHFUL)
	var pool := clergy if not clergy.is_empty() else faithful
	for p in pool:
		if venn == null or p.ground_pos.distance_to(temple_door) < venn.ground_pos.distance_to(temple_door):
			venn = p


func step(delta: float) -> void:
	timeline.step(delta)
	gaze.judge_deaths(crowd)
	_doors()
	_read(delta)
	_step_reports(delta)
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
		if one_at_a_time and not _reading.is_empty():
			continue  # (v0.11 M2) the next waits at the door
		var seer := faithful_seeing(door, SIGHT)
		if seer != null:
			_turned[p] = true
			_report(seer, temple_door)
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
	_reading[p] = read_seconds
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
		_report(seer, temple_door)


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


## The seconds the soonest reading inside has left (v0.11 M2: First Prayers' shrine counts them down); INF when nobody is inside.
func reading_left() -> float:
	var least := INF
	for p: Variant in _reading.keys():
		least = minf(least, float(_reading[p]))
	return least


## The tags (v0.10 M6, spec §4.1), the most important first:
## - the house, named (_house_label()), outlined and pointed at from the edge, until it is destroyed;
## - its door, clear or watched, until it burns;
## - each report's runner, pointed at from the edge;
## - the crying Believer, pointed at;
## - the Inquisitor, pointed at while she searches, and named as watching while she can see the door (she wears her own
##   violet, not a watcher's red);
## - the Temple, pointed at from the edge, while a report runs;
## - a red diamond on each Faithful watching the door (but her);
## - the grieving, and the Believers among them.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if house != null and not house.destroyed:
		var h := MapTag.place(house.center(), MARK_HOUSE, _house_label(), house.height)
		h.outline = house.footprint
		out.append(h)
	var open := not burning and not roof_fallen
	if open:
		var watched := faithful_seeing(door, SIGHT) != null
		out.append(MapTag.place(door, MARK_WATCHED if watched else MARK_CLEAR,
			"DOOR - WATCHED" if watched else "DOOR - CLEAR", 0.0, false))
	var running := false
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			out.append(MapTag.person(r.carrier.ground_pos, MARK_WATCHED, "TO THE TEMPLE", true))
			running = true
	if _alive(shouter):
		out.append(MapTag.person(shouter.ground_pos, MARK_BELIEVER, "CRYING OUT", true))
	if _alive(venn) and not venn.inside:
		var eyes := open and _sees(venn, door, SIGHT, null)
		out.append(MapTag.person(venn.ground_pos, MARK_VENN, "INQUISITOR - WATCHING" if eyes else "INQUISITOR", venn_searching))
	if running:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE"))
	if open:
		for f in watchers(door, SIGHT, venn):
			out.append(MapTag.person(f.ground_pos, MARK_WATCHED))
	for p in grieving:
		if _alive(p) and not p.inside:
			out.append(MapTag.person(p.ground_pos, MARK_BELIEVER if believers.has(p) else MARK_GRIEVING))
	return out


## What the house's tag says (v0.11 M2: a subclass names its own place).
func _house_label() -> String:
	return "MIRA'S HOUSE"


## The hint's phase (v0.10 M6, spec §4.1): "burning" once the house burns or falls, else "four" with four or more
## Believers out, else "".
func hint_phase() -> String:
	if burning or roof_fallen:
		return "burning"
	return "four" if believers_outside() >= need else ""


## The tour (v0.10 M6, spec §5): her door, the Temple, the Inquisitor.
func tour() -> Array:
	var out := []
	if door != Vector2.INF:
		out.append([door, "Mira's house. Her journal is inside."])
	if temple_door != Vector2.INF:
		out.append([temple_door, "The Temple. Faithful who see you run here."])
	if _alive(venn):
		out.append([venn.ground_pos, "Venn, the Inquisitor. Soon she searches the houses."])
	return out


func report() -> Dictionary:
	return {"believers": believers_outside(), "reports": reports_started}


func teardown() -> void:
	_unhook_kills(_on_killed)
	vigil = null
	timeline = null


func _add_events() -> void:
	timeline.add(VENN_AT, "venn", "The Inquisitor searches", _venn_starts, func() -> bool: return _alive(venn) and not _carrying(venn))
	timeline.add(SHOUT_AT, "shout", "A believer cries out", _shout, func() -> bool: return _newest_outside() != null)
	timeline.add(VIGIL_AT, "vigil", "The Vigil passes", _vigil_passes, func() -> bool: return not _free_faithful().is_empty())
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
	_say("venn")


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
		_report(venn, temple_door)
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
		_report(heard, temple_door)


## The Faithful free to walk the Vigil or line the street (v0.10 M5): alive, out, not the Inquisitor, not carrying a
## report.
func _free_faithful() -> Array[Person]:
	var free: Array[Person] = []
	for f in faithful:
		if _alive(f) and not f.inside and f != venn and not _carrying(f):
			free.append(f)
	return free


## The flame-bearer and his acolytes: the clergy nearest the Temple (not the Inquisitor), else any Faithful.
func _vigil_passes() -> void:
	var free := _free_faithful()
	var walkers := _vigil_walkers(free, temple_door)
	if not walkers.is_empty():
		var route := PackedVector2Array()
		for off in VIGIL_ROUTE:
			route.append(_walkable(door + (off as Vector2)))
		var acolytes: Array[Person] = []
		acolytes.assign(walkers.slice(1))
		vigil = VigilRoute.new().setup(route, walkers[0], acolytes)
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
	_say("fire")


## Everyone inside runs out at the door in a fright, unconverted if their reading was not done.
func _flush() -> void:
	burning = true
	for p: Person in _reading.keys():
		_reading.erase(p)
		if not is_instance_valid(p):
			continue
		_exit(p)
		p.panic(house.center() if house != null else door, 2.0)
