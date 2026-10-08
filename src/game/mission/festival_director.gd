class_name FestivalDirector
extends MissionDirector
## Act II-A of The Long Night (v0.09): the Feast of Lanterns. FESTIVAL_CROWD citizens fill the market square and stay;
## bonfires light it; the Mayor is among them. The festival is broken when FESTIVAL_NEED of the goers are dead or have
## broken (a fright or a dash for shelter). If the bell rang in Act I, GUARDS soldiers watch the square.
## v0.09.1 "Calm the feast": a warned town still holds its feast -- only a fright from the god breaks a goer, never the
## town's own alarm or evacuation.

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
## What a goer is doing when the festival has lost it: afraid, or running for a roof. Both come only from a fright
## (Person.panic(): a power's danger, a seen death, a collapse or a fire the god caused, the Mayor's death).
## v0.09.1 "Calm the feast": FLEE is not here -- a citizen flees only when the town itself sends it (its evacuation, a
## household leaving, a shelter emptied for the gates), so a goer the town sends away does not count, nor once it is
## out of town (_on_escaped()); one the god frightened first is counted already. A fleeing goer is past a fright
## (Person.panic()), so the god breaks it by casting within reach of it (_on_cast()).
const BROKE_MINDS := [Person.Mind.PANIC, Person.Mind.SHELTER]

## The act's windows, in seconds from its start: the bonfire lights and the crowd packs round the fountain, the Mayor
## speaks from it for ADDRESS_SECONDS, and the guard closes the square (the act's clock ends it).
const BONFIRE_AT := 45.0
const ADDRESS_AT := 90.0
const ADDRESS_SECONDS := 30.0
const CLOSE_AT := 150.0
## Where the Mayor stands to speak, from the fountain's centre (clear of its footprint, on the side the camera sees).
const ADDRESS_OFFSET := Vector2(0.9, 0.9)
## How far from the fountain's centre the Mayor's death frightens goers, in ground units (v0.09.1: a big push, not the
## whole feast), and its banner.
const MAYOR_PANIC_R := 8.0
const MAYOR_BANNER := "THE MAYOR FALLS - PANIC AT THE FOUNTAIN"
## The map tags' colours (board tags, spec §2): the feast and its goers gold, the Mayor orange.
const MARK_FEAST := Color("d8b23a")
const MARK_GOER := Color(0.85, 0.75, 0.45, 0.8)
const MARK_MAYOR := Color("ff9a3a")

var goers: Array[Person] = []
var mayor: Person
var need := FESTIVAL_NEED
## How many come to the square (v0.11 M1: the board's Festival raises it with the need, TierBook.FESTIVAL_CROWD).
var crowd_size := FESTIVAL_CROWD
var _broke := {}
## Goers who got away unbroken (v0.09.1, _on_escaped()): left the feast, not lost to it. Keyed by the goer, which is
## freed once it is out.
var _left := {}
var _sample_in := 0.0
var _fires: Array[FxTimeline] = []
## The report as it stood when the act ended (empty until then): Mission reads it only after the slow-motion ending,
## and a goer dying in that must not change how the act went.
var _final := {}


func _begin() -> void:
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	mayor = _appoint_mayor()
	_gather()
	# The Mayor's own events are dropped (and left off the strip) once he is dead, or if the town had no merchant.
	var speaks := func() -> bool: return WarningDirector._alive(mayor)
	timeline.add(BONFIRE_AT, "bonfire", "The bonfire lights", _pack)
	timeline.add(ADDRESS_AT, "address", "The Mayor's address", _address, speaks)
	timeline.add(ADDRESS_AT + ADDRESS_SECONDS, "address_end", "The address ends", _address_ends, speaks)
	timeline.add(CLOSE_AT, "close", "The guard closes the square")
	crowd._field.enemy_killed.connect(_on_killed)
	crowd.escaped.connect(_on_escaped)
	rules.cast_made.connect(_on_cast)
	rules.over.connect(_on_over)
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
				and p.profile.role == CitizenProfile.Role.MERCHANT and not reserved.has(p) \
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
				and p.mind in WarningDirector.RESUMABLE and not reserved.has(p):
			pool.append(p)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(c) < b.ground_pos.distance_squared_to(c))
	for p in pool.slice(0, crowd_size):
		goers.append(p)
		_send(p, crowd._spot_near(c, TownLayout.MARKET_SQUARE.size.x * 0.4))


func _send(p: Person, at: Vector2) -> void:
	p.mind = Person.Mind.CALM
	p.stay_left = 1000.0
	p.last_place = RoutineManager.Place.LEISURE
	p.walk_to(at)


## The bell rang in Act I: soldiers with no role, nearest the square, stand watch in it -- GUARDS more than are posted
## there already (v0.09.1: patrols without a role now, some posted in the square, who are not taken).
func _post_guards() -> void:
	var c := TownLayout.MARKET_SQUARE.get_center()
	var pool: Array[Person] = []
	for s in crowd.soldiers:
		if WarningDirector._alive(s) and s.corps == Person.Corps.NONE and s.mind == Person.Mind.POST \
				and not reserved.has(s) and not TownLayout.MARKET_SQUARE.has_point(s.anchor):
			pool.append(s)
	pool.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(c) < b.ground_pos.distance_squared_to(c))
	for s in pool.slice(0, GUARDS):
		s.send_to_post(crowd._spot_near(c, 3.0), false, true)


## A spot within PACK_R of the fountain on walkable ground (its stone is not).
func _pack_spot() -> Vector2:
	var c := TownLayout.FOUNTAIN.get_center()
	for attempt in 12:
		var spot := c + Vector2(crowd._rng.randf_range(-PACK_R, PACK_R), crowd._rng.randf_range(-PACK_R, PACK_R))
		if spot.distance_to(c) <= PACK_R and crowd._grid.walkable(spot):
			return spot
	var free := crowd._grid.nearest_walkable(c)
	return free if free != Vector2.INF else c


## The bonfire is lit: every calm goer closes in on the fountain.
func _pack() -> void:
	for p in goers:
		if WarningDirector._alive(p) and p.mind == Person.Mind.CALM:
			p.walk_to(_pack_spot())


## Where the Mayor speaks from.
func _address_spot() -> Vector2:
	var at := TownLayout.FOUNTAIN.get_center() + ADDRESS_OFFSET
	var free := crowd._grid.nearest_walkable(at)
	return free if free != Vector2.INF else at


## The Mayor takes the fountain on duty and the calm goers turn to him -- unless he is already frightened (a fright, a
## flight, a dash for shelter): he is not pulled back to speak.
func _address() -> void:
	if not WarningDirector._alive(mayor) or not mayor.mind in WarningDirector.RESUMABLE:
		return
	var at := _address_spot()
	mayor.go_duty(at)
	for p in goers:
		if WarningDirector._alive(p):
			p.observe(at, ADDRESS_SECONDS)


func _address_ends() -> void:
	if WarningDirector._alive(mayor):
		crowd.off_duty(mayor)


## The Mayor dies: every living goer within MAYOR_PANIC_R of the fountain panics where he fell, and is broken (v0.09.1:
## the rest of the feast stays).
func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	if e != mayor or e == null:
		return
	var c := TownLayout.FOUNTAIN.get_center()
	for p in goers:
		if WarningDirector._alive(p) and p.ground_pos.distance_to(c) <= MAYOR_PANIC_R:
			p.panic(e.ground_pos, 1.0, &"mayor")
			_broke[p] = true
	rules.banner.emit(MAYOR_BANNER)


func step(delta: float) -> void:
	timeline.step(delta)
	_sample_in -= delta
	if _sample_in <= 0.0:
		_sample_in = SAMPLE
		for p in goers:
			if is_instance_valid(p) and p.is_alive() and p.mind in BROKE_MINDS:
				_broke[p] = true


## Someone out of town (Crowd.escaped: a gate or a boat; v0.09.1 final review). A goer that gets away unbroken has
## left the feast and never counts (count()); one the god broke first still does.
func _on_escaped(p: Person) -> void:
	if not _broke.has(p):
		_left[p] = true


## A cast (Rules.cast_made; v0.09.1 final review): every living goer within its danger is broken, whatever it was doing
## -- a fleeing goer is past the fright (Person.panic()) that breaks the rest. The danger is the one Crowd.on_cast()
## registers: Crowd._cast_radius() plus Person.THREAT_MARGIN round the cast, or round each of its points along a lane
## power's lane (as Targeting hands it on). A quiet power registers none; its kills count as deaths.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if PowerBook.is_quiet(key):
		return
	var radius := Crowd._cast_radius(key)
	var a: Dictionary = Targeting.AREAS.get(key, {})
	var points: Array[Vector2] = [at]
	if String(a.get("shape", "")) == "lane":
		var dir := _cast_dir()
		points = Crowd.cast_points(Targeting.lane_start(key, at, dir), dir, float(a.length), radius)
	var reach := radius + Person.THREAT_MARGIN
	for p in goers:
		if not WarningDirector._alive(p):
			continue
		for point in points:
			if p.ground_pos.distance_to(point) <= reach:
				_broke[p] = true
				break


## The aim of the cast just made: its effect's "dir" (a drag's, a scripted cast's), else an undragged aim's
## (Targeting.DEFAULT_DIR).
func _cast_dir() -> Vector2:
	var fx: Variant = rules._playing  # untyped: a test's caster may hand back nothing
	var dir: Vector2 = (fx as FxTimeline).extra.get("dir", Vector2.ZERO) if is_instance_valid(fx) else Vector2.ZERO
	return dir.normalized() if dir != Vector2.ZERO else Targeting.DEFAULT_DIR


## Goers dead, freed or broken: the festival's losses. A goer that left the town unbroken is none of them (_left).
func count() -> int:
	var n := 0
	for p in goers:
		if _left.has(p):
			continue
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


## The act's clock (seconds from its start), 0 once the director has let go.
func _elapsed() -> float:
	return timeline.elapsed() if timeline != null else 0.0


## The map tags (board tags, spec §2), most important first:
## - the Mayor, pointed at from the edge while he speaks;
## - the feast at the fountain, pointed at from the edge, until it is broken;
## - a gold diamond on each goer still to break (out, alive, neither broken nor gone).
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if WarningDirector._alive(mayor) and not mayor.inside:
		out.append(MapTag.person(mayor.ground_pos, MARK_MAYOR, "MAYOR", hint_phase() == "address"))
	if broken():
		return out
	var rise := town.fountain.height if town != null and is_instance_valid(town.fountain) else 0.0
	out.append(MapTag.place(TownLayout.FOUNTAIN.get_center(), MARK_FEAST, "THE FEAST", rise))
	for p in goers:
		if WarningDirector._alive(p) and not p.inside and not _broke.has(p) and not _left.has(p):
			out.append(MapTag.pip(p.ground_pos, MARK_GOER))
	return out


## The hint's phase (board tags, spec §3): "address" while the Mayor speaks, else "packed" once the bonfire is lit,
## else "".
func hint_phase() -> String:
	var t := _elapsed()
	if t >= ADDRESS_AT and t < ADDRESS_AT + ADDRESS_SECONDS and WarningDirector._alive(mayor):
		return "address"
	return "packed" if t >= BONFIRE_AT else ""


## The tour (board tags, spec §4): the fountain, then the Mayor.
func tour() -> Array:
	var out := []
	out.append([TownLayout.FOUNTAIN.get_center(), "The Feast of Lanterns. Break %s of its crowd." % need])
	if WarningDirector._alive(mayor):
		out.append([mayor.ground_pos, "The Mayor. Mid-feast he speaks from the fountain."])
	return out


func report() -> Dictionary:
	if not _final.is_empty():
		return _final
	return {"festival": "broken" if broken() else "held", "festival_count": count()}


func _on_over(_won: bool, _reason: String) -> void:
	_final = report()


func teardown() -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	if is_instance_valid(crowd) and crowd.escaped.is_connected(_on_escaped):
		crowd.escaped.disconnect(_on_escaped)
	if is_instance_valid(rules) and rules.over.is_connected(_on_over):
		rules.over.disconnect(_on_over)
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	timeline = null  # its banner and guard lambdas hold this director: let both go
	for fire in _fires:
		if is_instance_valid(fire) and not fire.finished:
			fire._finish()
	_fires.clear()
