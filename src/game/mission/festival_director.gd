class_name FestivalDirector
extends MissionDirector
## Act II-A of The Long Night (v0.09): the Feast of Lanterns. FESTIVAL_CROWD citizens fill the market square and stay;
## bonfires light it; the Mayor is among them. The festival is broken when FESTIVAL_NEED of the goers are dead or have
## broken and fled (a fright, flight or a dash for shelter). If the bell rang in Act I, GUARDS soldiers watch the square.

## Citizens who come to the square, and how many of them must be dead or broken to break the festival. Tuned in Task 19.
const FESTIVAL_CROWD := 80
const FESTIVAL_NEED := 50
## How far round the square's centre a crowd counts as packed, in ground units (read by the Festival's objectives).
const PACK_R := 3.0
## Seconds between looks at who has broken.
const SAMPLE := 0.25
## Soldiers who stand watch in the square when the bell rang.
const GUARDS := 6
## Roles that never come: the town's responders, the Mayor and the Prince.
const SKIP_ROLES := [CitizenProfile.Role.BELLKEEPER, CitizenProfile.Role.WATCHMAN, CitizenProfile.Role.CLERGY,
	CitizenProfile.Role.ENGINEER, CitizenProfile.Role.MAYOR, CitizenProfile.Role.NOBLE]
## What a goer is doing when the festival has lost it: afraid, running, or running for a roof.
const BROKE_MINDS := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]

var goers: Array[Person] = []
var mayor: Person
var need := FESTIVAL_NEED
var _broke := {}
var _sample_in := 0.0
var _fires: Array[FxTimeline] = []


func _begin() -> void:
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	mayor = _appoint_mayor()
	_gather()
	if night != null and night.bell_rang:
		_post_guards()
	if ctx != null:
		for at in [TownLayout.MARKET_SQUARE.get_center() + Vector2(-2.0, -2.5), TownLayout.MARKET_SQUARE.get_center() + Vector2(2.5, 2.0)]:
			var fire := FxTimeline.cast(BonfireFx, ctx, at, {"seconds": rules.time_left})
			if fire != null:
				_fires.append(fire)


## The merchant living nearest the market square is the Mayor tonight.
func _appoint_mayor() -> Person:
	var best: Person = null
	var c := TownLayout.MARKET_SQUARE.get_center()
	for p in crowd.citizens:
		if WarningDirector._alive(p) and p.profile != null and not p.inside \
				and p.profile.role == CitizenProfile.Role.MERCHANT \
				and (best == null or p.profile.home.distance_to(c) < best.profile.home.distance_to(c)):
			best = p
	if best != null:
		best.profile.role = CitizenProfile.Role.MAYOR
	return best


## The FESTIVAL_CROWD calm citizens nearest the square walk to a spot in it and stay.
func _gather() -> void:
	var c := TownLayout.MARKET_SQUARE.get_center()
	var pool: Array[Person] = []
	for p in crowd.citizens:
		if WarningDirector._alive(p) and p.profile != null and not p.inside and not p.profile.role in SKIP_ROLES \
				and p.mind in WarningDirector.RESUMABLE:
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(c) < b.ground_pos.distance_squared_to(c))
	for p in pool.slice(0, FESTIVAL_CROWD):
		goers.append(p)
		_send(p, crowd._spot_near(c, TownLayout.MARKET_SQUARE.size.x * 0.4))


func _send(p: Person, at: Vector2) -> void:
	p.mind = Person.Mind.CALM
	p.stay_left = 1000.0
	p.last_place = RoutineManager.Place.LEISURE
	p.walk_to(at)


## The bell rang in Act I: soldiers with no role, nearest the square, stand watch in it.
func _post_guards() -> void:
	var c := TownLayout.MARKET_SQUARE.get_center()
	var pool: Array[Person] = []
	for s in crowd.soldiers:
		if WarningDirector._alive(s) and s.corps == Person.Corps.NONE and s.mind == Person.Mind.POST:
			pool.append(s)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(c) < b.ground_pos.distance_squared_to(c))
	for s in pool.slice(0, GUARDS):
		s.send_to_post(crowd._spot_near(c, 3.0), false, true)


func step(delta: float) -> void:
	timeline.step(delta)
	_sample_in -= delta
	if _sample_in <= 0.0:
		_sample_in = SAMPLE
		for p in goers:
			if is_instance_valid(p) and p.is_alive() and p.mind in BROKE_MINDS:
				_broke[p] = true


## Goers dead, freed or broken: the festival's losses.
func count() -> int:
	var n := 0
	for p in goers:
		if not is_instance_valid(p) or not p.is_alive() or _broke.has(p):
			n += 1
	return n


func broken() -> bool:
	return count() >= need


func broke_list() -> Array[Person]:
	var out: Array[Person] = []
	for p in goers:
		if is_instance_valid(p) and p.is_alive() and _broke.has(p):
			out.append(p)
	return out


func carry(n: NightState) -> void:
	n.festival_broke = broke_list()


func report() -> Dictionary:
	return {"festival": "broken" if broken() else "held", "festival_count": count()}


func teardown() -> void:
	for fire in _fires:
		if is_instance_valid(fire) and not fire.finished:
			fire._finish()
	_fires.clear()
