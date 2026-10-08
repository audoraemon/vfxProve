class_name HarvestDirector
extends RazeDirector
## Spoiled Harvest (v0.11 M2, Tier 1, spec §2 and §8 row 3): three granary stores -- the dwellings nearest STORE_SPOTS, far
## from the Citadel -- sealed until their doors open at OPEN_AT. Each opened sends CARTERS lay citizens from the Citadel's gate
## to carry its LOADS there, a load taken at a time; the last load taken empties it, and a granary emptied cannot be spoiled:
## the night is lost. Spoil all three (SPOIL_SECONDS of burning in all, or their fall) to win. The town's fire crews douse what
## burns: the Raze type's repair crews. The controller's ruling: a 50-hp house falls in about 13 s of burning, so 15 s of
## burning could never be reached; a granary is spoiled after 10 s alight or when it falls, whichever is first.

## Where the granaries stand (the nearest dwelling to each), and their names on the banners and the tour (v0.11 M2).
const STORE_SPOTS := [Vector2(-9.0, 12.0), Vector2(12.0, 12.0), Vector2(12.0, -12.0)]
const STORE_NAMES := ["south-west", "south-east", "north-east"]
## First guesses (spec §2), tuned in this order if the scripted clear misses its window (v0.11 M2): when each granary opens,
## how long it must burn to be spoiled, how many loads it holds, and how many carters take them.
const OPEN_AT := [60.0, 120.0, 180.0]
const SPOIL_SECONDS := 10.0
const LOADS := 5
const CARTERS := 2
## The Citadel's gate, where the grain goes; how near a door a carter takes or leaves a load; seconds between looks (v0.11 M2).
const CITADEL_GATE := Vector2(-10.5, -7.6)
const TAKE_REACH := 0.8
const TICK := 0.5

## Structure -> loads left in it (v0.11 M2).
var loads := {}
## Structure -> its carters (v0.11 M2; untyped: a carter may be a freed body).
var carters := {}
## The granaries opened, in order (v0.11 M2).
var opened: Array[Structure] = []
## The first granary emptied (the night is lost), or null (v0.11 M2).
var emptied: Structure
## The Citadel's gate on walkable ground, and each granary's door (Structure -> Vector2) (v0.11 M2).
var citadel_door := Vector2.INF
var doors := {}
## Instance ids of the carters carrying a load to the Citadel (v0.11 M2).
var _hauling := {}
## Seconds to the next look at the carters (v0.11 M2, TICK).
var _tick_in := 0.0


## The night's setup (v0.11 M2): the three granaries sealed, each opening on the timeline.
func _begin() -> void:
	spoil_seconds = SPOIL_SECONDS
	citadel_door = _walkable(CITADEL_GATE)
	for spot: Vector2 in STORE_SPOTS:
		var s := _house_near(spot, targets)
		if s == null:
			continue
		targets.append(s)
		loads[s] = LOADS
		carters[s] = []
		doors[s] = _front_of(s)
		seal(s)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		var s := targets[i]
		timeline.add(float(OPEN_AT[i]), "open_%d" % i, "The %s granary opens" % STORE_NAMES[i], _open.bind(s),
			func() -> bool: return not razed(s))
	rules.banner.emit("SPOIL THE HARVEST")


## A granary opens (v0.11 M2): unsealed, and its carters -- the lay citizens nearest the Citadel's gate not already carting --
## set out.
func _open(s: Structure) -> void:
	unseal(s)
	opened.append(s)
	var busy: Array = []
	for others: Array in carters.values():
		busy.append_array(others)
	var crew := _lay_near(citadel_door, CARTERS, busy)
	carters[s] = crew
	for c in crew:
		c.go_duty(doors[s])


## One step (v0.11 M2): the Raze type's, then every TICK a look at each open granary's carters.
func step(delta: float) -> void:
	super(delta)
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	for s in opened:
		if emptied == null and not razed(s):
			_cart(s)


## `s`'s carters at their work (v0.11 M2): one at its door takes a load (the last empties it); one at the Citadel's gate leaves
## his and goes back. A carter frightened, whispered or confused is left be, and takes his errand up again after.
func _cart(s: Structure) -> void:
	for c: Variant in carters[s]:
		if not _alive(c):
			continue
		var p := c as Person
		if not (p.mind == Person.Mind.DUTY or p.mind in WarningDirector.RESUMABLE):
			continue
		var id := p.get_instance_id()
		var goal: Vector2 = citadel_door if _hauling.has(id) else doors[s]
		if p.ground_pos.distance_to(goal) <= TAKE_REACH:
			if _hauling.has(id):
				_hauling.erase(id)
			else:
				_take(s, id)
				if emptied != null:
					return
			goal = citadel_door if _hauling.has(id) else doors[s]
		if p.mind != Person.Mind.DUTY or p.anchor.distance_to(goal) > 0.3:
			p.go_duty(goal)


## A load taken from `s` by the carter `id` (v0.11 M2); the last one empties it.
func _take(s: Structure, id: int) -> void:
	loads[s] = int(loads[s]) - 1
	_hauling[id] = true
	if int(loads[s]) <= 0 and emptied == null:
		emptied = s
		rules.banner.emit("A GRANARY IS EMPTIED")


## Spoiled (v0.11 M2): its carters go home, and any load they carry is lost.
func _on_razed(s: Structure) -> void:
	rules.banner.emit("A GRANARY IS SPOILED")
	for c: Variant in carters.get(s, []):
		if _alive(c):
			var p := c as Person
			_hauling.erase(p.get_instance_id())
			if p.mind == Person.Mind.DUTY:
				crowd.off_duty(p)
	carters[s] = []


## The night is lost once a granary is emptied (v0.11 M2).
func lost_reason() -> String:
	return "emptied" if emptied != null else ""


## The map tags, most important first (v0.11 M2): each granary not yet spoiled -- sealed, with the time to its opening; burning,
## with the seconds left to spoil it; else open, with its loads left -- and a red diamond on each carter of an open one.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s):
			continue
		if is_sealed(s):
			var left := timeline.seconds_to("open_%d" % i) if timeline != null else 0.0
			out.append(MapTag.place(s.center(), MARK_SEALED, "GRANARY - OPENS IN %s" % UiTheme.clock(left), s.height, false))
		elif burning(s):
			out.append(MapTag.place(s.center(), MARK_BURNING, "GRANARY - BURNING %d" % ceili(maxf(spoil_seconds - burned(s), 0.0)),
				s.height, true))
		else:
			out.append(MapTag.place(s.center(), MARK_TARGET, "GRANARY - %d LEFT" % int(loads[s]), s.height, true))
	for s in opened:
		if razed(s):
			continue
		for c: Variant in carters[s]:
			if _alive(c) and not (c as Person).inside:
				out.append(MapTag.person((c as Person).ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M2): "burning" while an open granary burns unspoiled; "" while one stands open; else "sealed".
func hint_phase() -> String:
	for s in opened:
		if not razed(s) and burning(s):
			return "burning"
	for s in opened:
		if not razed(s):
			return ""
	return "sealed"


## The tour (spec §2, v0.11 M2): the three granaries with their opening times, then the Citadel.
func tour() -> Array:
	var out := []
	for i in targets.size():
		out.append([doors[targets[i]], "The %s granary. Its doors open at %s." % [STORE_NAMES[i], UiTheme.clock(float(OPEN_AT[i]))]])
	if citadel_door != Vector2.INF:
		out.append([citadel_door, "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled."])
	return out


## What the results show (v0.11 M2): the granaries spoiled, and whether one was emptied.
func report() -> Dictionary:
	return {"spoiled": razed_count(), "emptied": emptied != null}
