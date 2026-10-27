class_name HarvestDirector
extends RazeDirector
## Spoiled Harvest (v0.11 M2, Tier 1, spec §2 and §8 row 3; reshaped by the controller's Task 3 fix-round rulings: work, not
## waiting; the grain arrives one granary at a time): three granary stores -- the dwellings nearest STORE_SPOTS, far from the
## Citadel. A granary holds nothing to spoil until its grain arrives: fire on an empty one is put out at once and counts for
## nothing. The first granary's grain arrives at GRAIN_AT[0]; each next one at its own time, or chain_after seconds after the one
## before it is spoiled, whichever is sooner (the board Warning's stars' rule). The moment a granary's grain is in, its carter
## sets out from the Citadel's gate and carries its LOADS to the Citadel, a load taken at a time; the last load taken empties
## it, and a granary emptied cannot be spoiled: the night is lost. Each granary has WATCHMEN watchmen, lay citizens at its door,
## present from the start: while one is alive, out of doors, at his post and calm (not frightened, confused, whispered,
## compelled, fighting or dead) he holds his post while his granary burns and, after SMOTHER_AFTER seconds, beats the fire out,
## and what it had burned is forgotten. The god must remove every one of them (strike them down, scare them off, whisper them
## away), then keep the fire burning SPOIL_SECONDS in all, or bring the granary down. A frightened watchman who is calm again
## returns to his post after RETURN_AFTER; a fallen one is replaced RELIEF_AFTER after he fell, so clearing a granary long
## before its grain arrives is undone. Spoil all three to win. The controller's Task 3 ruling: a 50-hp house falls in about 13 s
## of burning, so 15 s of burning could never be reached; a granary is spoiled after 10 s alight or when it falls, whichever is
## first.
##
## God T1R (Tier 1 routes, spec 6): a granary can be spoiled in more ways than fire. Its carter sets out CARTER_LEAD before the
## grain is due and waits at the door (H0); a carter out of the town's walls, or sick (Pestilence) with no watchman on guard,
## or seized by the guard The Bell Lies calls to him, spoils his granary at once (H1, H2, H4); Blight rots a granary whose grain
## is in and whose watchmen are not on guard (H3); a carter who dies is replaced RELIEF_AFTER later and killing one never spoils
## (H5). Every spoil is recorded in `spoiled_by`.

## One watchman's post (v0.11 M2): a plain record, so the director holds no cycle.
class Watch:
	extends RefCounted
	## The watchman, held as a Variant and read only through MissionDirector._alive(): he may be a body freed after his death
	## fade.
	var man: Variant = null
	## Where he stands, beside the granary's door.
	var post := Vector2.INF
	## Seconds since he was last on guard (he is alive but frightened, held or away).
	var away := 0.0
	## Seconds since he fell (a relief is sent RELIEF_AFTER after).
	var fallen := 0.0


## Where the granaries stand (the nearest dwelling to each), and their names on the banners and the tour (v0.11 M2).
const STORE_SPOTS := [Vector2(-9.0, 12.0), Vector2(12.0, 12.0), Vector2(12.0, -12.0)]
const STORE_NAMES := ["south-west", "south-east", "north-east"]
## First guesses (the controller's Task 3 fix-round rulings), tuned if the scripted clear or the loss misses its window
## (v0.11 M2): when each granary's grain arrives at the latest; how long after one is spoiled the next one's arrives at the
## latest (30-45 s); how long a granary must burn to be spoiled; how many loads it holds; how many carters take them; how many
## watchmen guard it.
const GRAIN_AT := [60.0, 120.0, 180.0]
const CHAIN_AFTER := 45.0
const SPOIL_SECONDS := 10.0
const LOADS := 5
const CARTERS := 1
const WATCHMEN := 2
## The watchman (v0.11 M2): how long a fire burns on his granary before he beats it out; how near the granary he must stand to
## be on guard; how long a watchman off his post waits before he is sent back to it; how long after one fell the next is sent.
const SMOTHER_AFTER := 3.0
const GUARD_REACH := 2.5
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
## God T1R (spec 6.9, tunable): how long before its grain is due a granary's carter sets out from the Citadel's gate (20-40); and how
## near the place The Bell Lies called the guard to a carter must stand to be seized (2.0-3.0), once the first called soldier has come. (Tuned
## 2.5 -> 3.0 in round 2: Leaving Is Prohibited, which holds a carter on the spot while the guard run, binds within 3.0 -- NoLeaveFx.RADIUS --
## and sets him back onto that edge, so a held carter is always within it. SEIZE_SLACK covers the float of "onto the edge".)
const CARTER_LEAD := 30.0
const SEIZE_R := 3.0
## How near his ring spot the first called soldier must be for the guard to have come (spec 6.5), and how far from the place a ring
## spot may lie (BellLiesFx.GUARD_RING, a blocked one moved to the nearest walkable ground).
const SEIZE_ARRIVE := 0.8
const SEIZE_SLACK := 0.05
const SEIZE_RING := 2.4
## A watchman at his post while his granary burns is not frightened (Person.fearless_left): the town's ordinary flight from a
## fire would empty his post before he could beat the fire out. Held this many seconds past the last look; the god's own holds
## (a kill, a whisper, Discord) still take him (v0.11 M2).
const HOLD_POST := 1.0
## Where the watchmen stand, from their granary's door (v0.11 M2): either side of it, further apart than one Silent Doom
## reaches, so each needs a cast.
const WATCH_OFFS := [Vector2(-1.4, 0.3), Vector2(1.4, 0.3)]
## The minds a watchman keeps guard in (v0.11 M2): going about his day, looking on, or on duty at his post. Any other -- fright,
## flight, shelter, the rally, a fight, the god's hold, fetching water at a fire -- and he does not.
const GUARD_MINDS := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.DUTY]
## Aldermere's Citadel gate (the director reads the place citadel_gate; Tiers 2-5 alias this); how near a door a carter takes or leaves a load; seconds between looks (v0.11 M2).
const CITADEL_GATE := Vector2(-10.5, -7.6)
const TAKE_REACH := 0.8
const TICK := 0.5
## The map tags' colours (v0.11 M2): a carter steel blue.
const MARK_CARTER := Color("8fb8e8")

## The town's places and numbers (v0.12, spec 1.5): seeded from the consts above, which are Aldermere's; a town's overrides replace
## them. (`loads` below is the granaries' loads left, so the count of loads each holds is `load_count`.)
## The names a town's overrides may set (Overrides): the vars below, which setup reads and never assigns.
const TOWN_VARS := ["store_spots", "store_names", "grain_at", "chain_after", "load_count"]
var store_spots: Array = STORE_SPOTS
var store_names: Array = STORE_NAMES
var grain_at: Array = GRAIN_AT
var chain_after: float = CHAIN_AFTER
var load_count: int = LOADS

## Structure -> loads left in it (v0.11 M2).
var loads := {}
## Structure -> its carters (v0.11 M2; untyped: a carter may be a freed body).
var carters := {}
## Structure -> its Watch records (v0.11 M2).
var watches := {}
## Structure -> true once its grain has arrived (v0.11 M2).
var grain := {}
## Structure -> how it was spoiled: "fire", "fall", "out", "plague", "blight" or "seized" (god T1R, for the report and the tests).
var spoiled_by := {}
## Structure -> the second its first carter set out (god T1R, H0).
var _out_at := {}
## Structure -> seconds since its carter was last alive (god T1R, H5: a relief is sent RELIEF_AFTER after).
var _carter_fallen := {}
## Instance ids of the sick carters the watch has already turned away (god T1R, H2: the banner shows once per carter).
var _turned := {}
## The Bell Lies' CALL THE GUARD cast that may still seize a cart, and where it called them (god T1R, H4).
var _guard_fx: BellLiesFx
var _guard_at := Vector2.INF
## The words of the Blight that just landed (blighted() keeps them: the granary is spoiled by the time BlightFx asks).
var _blight_said := ""

## The granaries whose grain has arrived, in order (v0.11 M2).
var carting: Array[Structure] = []
## The first granary emptied (the night is lost), or null (v0.11 M2).
var emptied: Structure
## The Citadel's gate on walkable ground, and each granary's door (Structure -> Vector2) (v0.11 M2).
var citadel_door := Vector2.INF
var doors := {}
## The second of the night each granary was spoiled (-1 until it is), in the order of `targets` (v0.11 M2).
var spoiled_at: Array[float] = []
## Structure -> seconds its fire has burned with a watchman on guard (v0.11 M2).
var _alight := {}
## Instance ids of the carters carrying a load to the Citadel (v0.11 M2).
var _hauling := {}
## Seconds into the night, for the chain (v0.11 M2).
var _clock := 0.0
## Seconds to the next look at the carters and the watchmen's orders (v0.11 M2, TICK).
var _tick_in := 0.0


## The night's setup (v0.11 M2): the three granaries, their watchmen set down at the doors, and each one's grain on the
## timeline.
func _begin() -> void:
	spoil_seconds = SPOIL_SECONDS
	citadel_door = _walkable(Places.point(&"citadel_gate"))
	for spot: Vector2 in store_spots:
		var s := _house_near(spot, targets)
		if s == null:
			continue
		targets.append(s)
		loads[s] = load_count
		carters[s] = []
		doors[s] = _front_of(s)
		spoiled_at.append(-1.0)
	for s in targets:
		var posts: Array[Watch] = []
		for k in WATCHMEN:
			var w := Watch.new()
			w.post = _walkable(doors[s] + (WATCH_OFFS[k % WATCH_OFFS.size()] as Vector2))
			var crew := _lay_near(w.post, 1, _busy())
			if not crew.is_empty():
				w.man = crew[0]
				_set_down(crew[0], w.post)
			posts.append(w)
		watches[s] = posts
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		var s := targets[i]
		timeline.add(float(grain_at[i]), "grain_%d" % i, _grain_label(i), _deliver.bind(s),
			func() -> bool: return not has_grain(s) and not razed(s))
	rules.cast_made.connect(_on_cast)
	left_the_map.connect(_on_left)
	rules.banner.emit("SPOIL THE HARVEST")


## Lets go of the casts and the leavers (god T1R), then the Raze type's seals and timeline.
func teardown() -> void:
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	if left_the_map.is_connected(_on_left):
		left_the_map.disconnect(_on_left)
	_guard_fx = null
	super()


## The strip's and the banner's words when granary `i`'s grain arrives (v0.11 M2).
func _grain_label(i: int) -> String:
	return "Grain arrives at the %s granary" % store_names[i]


## Everyone the director has put to work (v0.11 M2): every granary's carters and watchmen, for a new one to leave out.
func _busy() -> Array:
	var out: Array = []
	for crew: Array in carters.values():
		out.append_array(crew)
	for posts: Array in watches.values():
		for w: Watch in posts:
			if w.man != null:
				out.append(w.man)
	return out


## Whether `s` holds its grain yet (v0.11 M2).
func has_grain(s: Structure) -> bool:
	return grain.has(s)


## The granary `s` has something to spoil once its grain is in (v0.11 M2; RazeDirector._spoilable()).
func _spoilable(s: Structure) -> bool:
	return grain.has(s)


## The second of the night granary `i`'s grain arrives at the latest (v0.11 M2): its own time, or chain_after after the one
## before it is spoiled if that is sooner. The one before it still unspoiled never brings it forward.
func grain_due(i: int) -> float:
	var at := float(grain_at[i]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if i > 0 and spoiled_at[i - 1] >= 0.0:
		at = minf(at, spoiled_at[i - 1] + chain_after)
	return at


## Seconds until granary `s`'s grain arrives at the latest (v0.11 M2); 0 once it has.
func grain_left(s: Structure) -> float:
	return 0.0 if has_grain(s) else maxf(grain_due(targets.find(s)) - _clock, 0.0)


## Each granary still empty whose chain time has come gets its grain (v0.11 M2); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, targets.size()):
		var s := targets[i]
		if not has_grain(s) and not razed(s) and spoiled_at[i - 1] >= 0.0 and _clock >= grain_due(i):
			rules.banner.emit(_grain_label(i).to_upper())
			_deliver(s)


## The grain arrives at `s` (v0.11 M2): it can be spoiled now. Its carter is already at the door (H0, god T1R); one not yet set out
## (a grain brought in early by a test or a chain) sets out now.
func _deliver(s: Structure) -> void:
	if has_grain(s):
		return
	grain[s] = true
	carting.append(s)
	if not _out_at.has(s):
		_send_carter(s)


## When granary `i`'s carter sets out from the Citadel's gate (god T1R, H0): CARTER_LEAD before its grain is due, at once if that is
## past; the second he did, once he has.
func carter_out_at(i: int) -> float:
	var s := targets[i]
	if _out_at.has(s):
		return float(_out_at[s])
	return maxf(grain_due(i) - CARTER_LEAD, _clock)


## A carter sets out for `s`'s door from the Citadel's gate: the lay citizen nearest it not already at work (v0.11 M2; god T1R: the
## first one early, a replacement after a death).
func _send_carter(s: Structure) -> void:
	if not _out_at.has(s):
		_out_at[s] = _clock
	_carter_fallen[s] = 0.0
	var crew := _lay_near(citadel_door, CARTERS, _busy())
	carters[s] = crew
	for c in crew:
		c.go_duty(doors[s])


## Whether granary `s`'s carter is alive (god T1R, H5): any of the crew set out for it.
func _carter_alive(s: Structure) -> bool:
	for c: Variant in carters.get(s, []):
		if _alive(c):
			return true
	return false


## Granary `s` is spoiled by `how` (god T1R): recorded, then razed as a fire or a fall would raze it. Once only.
func _spoil(s: Structure, how: String) -> void:
	if razed(s):
		return
	spoiled_by[s] = how
	_raze(s)


## One step (v0.11 M2): the Raze type's, the chain, each granary's watchmen every frame, then every TICK a look at the carters
## and the watchmen's orders. (God T1R: the carters set out early, the leavers walk on, and a fallen carter is replaced.)
func step(delta: float) -> void:
	_clock += delta
	super(delta)
	_chain()
	_step_leaving()
	_tick_in -= delta
	var looking := _tick_in <= 0.0
	if looking:
		_tick_in = TICK
	for i in targets.size():
		var s := targets[i]
		if razed(s):
			continue
		_watch(s, delta, looking)
		if not _out_at.has(s):
			if _clock >= carter_out_at(i):
				_send_carter(s)
		elif _carter_alive(s):
			_carter_fallen[s] = 0.0
		else:
			_carter_fallen[s] = float(_carter_fallen.get(s, 0.0)) + delta
			if looking and float(_carter_fallen[s]) >= RELIEF_AFTER and emptied == null:
				_send_carter(s)
				rules.banner.emit("A NEW CARTER SETS OUT")
	if not looking:
		return
	_seize_look()
	for s in targets:
		if razed(s) or not _out_at.has(s):
			continue
		_out_look(s)
		if not razed(s):
			_sick_look(s)
	for s in targets:
		if emptied == null and _out_at.has(s) and not razed(s):
			_cart(s)


## A carter out of the town's walls (god T1R, H1, spec 2.1): his granary is spoiled at once, before or after its grain, and he is sent
## on off the map.
func _out_look(s: Structure) -> void:
	for c: Variant in carters.get(s, []):
		if _alive(c) and not (c as Person).inside and Walls.outside((c as Person).ground_pos):
			rules.banner.emit("THE CARTER LEAVES TOWN - THE GRAIN ROTS")
			_spoil(s, "out")
			send_off(c)
			return


## A sick carter (god T1R, H2): with no watchman of his granary on guard, the plague spoils it at the first look (he may have caught it
## while they stood on guard and be sick still when they fall); with one on guard the watch turns the cart away -- once for each carter.
func _sick_look(s: Structure) -> void:
	for c: Variant in carters.get(s, []):
		if not _alive(c) or (c as Person).inside or (c as Person).sick_left <= 0.0:
			continue
		if guarding(s):
			var id := (c as Person).get_instance_id()
			if not _turned.has(id):
				_turned[id] = true
				rules.banner.emit("THE WATCH TURNS THE SICK CART AWAY")
			continue
		rules.banner.emit("THE PLAGUE SPOILS THE GRAIN")
		_spoil(s, "plague")
		return


## A person was taken off the map (MissionDirector.left_the_map, god T1R): a carter of a granary not yet spoiled has gone for the night
## and so has his load -- the granary is spoiled. (The out look has done so already, one tick after he passed the wall; this catches a carter
## who was taken off the map by another way.)
func _on_left(p: Person) -> void:
	for s in targets:
		if razed(s):
			continue
		for c: Variant in carters.get(s, []):
			if c == p:
				_spoil(s, "out")
				return


## A power was cast (god T1R, H4): The Bell Lies in CALL THE GUARD is kept to see when its first soldier comes (_seize_look()).
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if key != "belllies":
		return
	var fx := rules.last_fx() as BellLiesFx
	if fx != null and fx.mode == "guard":
		_guard_fx = fx
		_guard_at = at


## The guard The Bell Lies called have come (god T1R, H4): once the first called soldier stands within SEIZE_ARRIVE of his ring spot, every
## carter alive and out of doors within SEIZE_R of the place is seized -- his granary spoiled at once, the carter sent home -- and the
## call is spent.
func _seize_look() -> void:
	if _guard_at == Vector2.INF:
		return
	if _guard_fx == null or not is_instance_valid(_guard_fx) or _guard_fx.finished:
		_guard_fx = null
		_guard_at = Vector2.INF
		return
	var arrived := false
	for sol in crowd.soldiers:
		if is_instance_valid(sol) and sol.mind == Person.Mind.COMPELLED and sol.compel_glyph == DecreeParts.BELL \
				and sol.anchor.distance_to(_guard_at) <= SEIZE_RING and sol.ground_pos.distance_to(sol.anchor) <= SEIZE_ARRIVE:
			arrived = true
			break
	if not arrived:
		return
	var at := _guard_at
	_guard_fx = null
	_guard_at = Vector2.INF
	for s in targets:
		if razed(s):
			continue
		for c: Variant in carters.get(s, []):
			if _alive(c) and not (c as Person).inside and (c as Person).ground_pos.distance_to(at) <= SEIZE_R + SEIZE_SLACK:
				rules.banner.emit("THE GUARD SEIZE THE CART")
				_spoil(s, "seized")
				break


## Whether watchman `w` of `s` is on guard now (v0.11 M2): alive, out of doors, in a calm mind, and at his post.
func _on_guard(s: Structure, w: Watch) -> bool:
	if not _alive(w.man):
		return false
	var p := w.man as Person
	return not p.inside and p.mind in GUARD_MINDS and s.distance_to(p.ground_pos) <= GUARD_REACH


## The watchmen of `s` on guard now (v0.11 M2).
func guards(s: Structure) -> Array[Person]:
	var out: Array[Person] = []
	for w: Watch in watches.get(s, []):
		if _on_guard(s, w):
			out.append(w.man as Person)
	return out


## Whether any watchman of `s` is on guard now (v0.11 M2).
func guarding(s: Structure) -> bool:
	return not guards(s).is_empty()


## The watchmen of `s` alive and out of doors, on guard or not (v0.11 M2).
func watchmen(s: Structure) -> Array[Person]:
	var out: Array[Person] = []
	for w: Watch in watches.get(s, []):
		if _alive(w.man) and not (w.man as Person).inside:
			out.append(w.man as Person)
	return out


## One granary's watchmen (v0.11 M2). While one is on guard and the granary, with its grain in, burns, they hold their posts
## (HOLD_POST) and the fire is beaten out once it has burned SMOTHER_AFTER with one on guard; what it had burned is forgotten.
## A watchman off his post but alive is sent back RETURN_AFTER after he left (once calm); a fallen one is replaced RELIEF_AFTER
## after he fell.
func _watch(s: Structure, delta: float, looking: bool) -> void:
	var on_guard := false
	for w: Watch in watches[s]:
		if _on_guard(s, w):
			on_guard = true
			w.away = 0.0
			w.fallen = 0.0
		elif _alive(w.man):
			w.fallen = 0.0
			w.away += delta
			if looking and w.away >= RETURN_AFTER:
				_recall(w)
		else:
			w.fallen += delta
			if looking and w.fallen >= RELIEF_AFTER:
				_relieve(w)
	if not (on_guard and has_grain(s) and burning(s)):
		_alight[s] = 0.0
		return
	for w: Watch in watches[s]:
		if _on_guard(s, w):
			var man := w.man as Person
			man.fearless_left = maxf(man.fearless_left, HOLD_POST)
	_alight[s] = float(_alight.get(s, 0.0)) + delta
	if float(_alight[s]) >= SMOTHER_AFTER:
		_alight[s] = 0.0
		crowd.fires._put_out(s, true)
		forget_burn(s)


## The watchman off his post, calm again, goes back to it (v0.11 M2).
func _recall(w: Watch) -> void:
	var p := w.man as Person
	if p.inside:
		return
	if p.mind in WarningDirector.RESUMABLE or (p.mind == Person.Mind.DUTY and p.anchor.distance_to(w.post) > 0.3):
		p.go_duty(w.post)


## A relief for a fallen watchman (v0.11 M2): the lay citizen nearest his post not already at work walks to it.
func _relieve(w: Watch) -> void:
	var crew := _lay_near(w.post, 1, _busy())
	if crew.is_empty():
		return
	w.man = crew[0]
	w.fallen = 0.0
	w.away = 0.0
	crew[0].go_duty(w.post)
	rules.banner.emit("A NEW WATCHMAN TAKES THE POST")


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
			elif has_grain(s):  # (god T1R, H0: he waits at the door for the grain)
				_take(s, id)
				if emptied != null:
					return
			goal = citadel_door if _hauling.has(id) else doors[s]
		if p.mind != Person.Mind.DUTY or p.anchor.distance_to(goal) > 0.3 or (p.goal() == Vector2.INF and p.ground_pos.distance_to(goal) > TAKE_REACH):
			p.go_duty(goal)  # (god T1R: also a carter whose road was closed -- a Thornwall -- and who stands with no walk, once it opens)


## A load taken from `s` by the carter `id` (v0.11 M2); the last one empties it.
func _take(s: Structure, id: int) -> void:
	loads[s] = int(loads[s]) - 1
	_hauling[id] = true
	if int(loads[s]) <= 0 and emptied == null:
		emptied = s
		rules.banner.emit("A GRANARY IS EMPTIED")


## Spoiled (v0.11 M2): the chain starts for the next granary; its carters and its watchmen go home, and any load they carry is
## lost. v0.11 M3: the strip shows the next grain's chained time.
func _on_razed(s: Structure) -> void:
	if not spoiled_by.has(s):
		spoiled_by[s] = "fall" if not is_instance_valid(s) or s.destroyed else "fire"
	rules.banner.emit("A GRANARY IS SPOILED")
	var i := targets.find(s)
	spoiled_at[i] = _clock
	if timeline != null and i + 1 < targets.size():
		timeline.expect("grain_%d" % (i + 1), grain_due(i + 1))  # v0.11 M3: the strip shows the chained time
	for c: Variant in carters.get(s, []):
		if _alive(c):
			var p := c as Person
			_hauling.erase(p.get_instance_id())
			if p.mind == Person.Mind.DUTY:
				crowd.off_duty(p)
	carters[s] = []
	for w: Watch in watches.get(s, []):
		_release(w)


## A spoiled granary's watchman goes home (v0.11 M2, final review). One on duty is stood down (Crowd.off_duty()); one calm at his
## post is sent home too -- the first watchmen are set down with a stay of 1000 s, so left to his day he would stand at the
## spoiled granary all night. One frightened, held or fighting is left to the town. The hold that kept him at his post while his
## granary burned ends with it.
func _release(w: Watch) -> void:
	if not _alive(w.man):
		return
	var p := w.man as Person
	if p.fearless_left <= HOLD_POST:
		p.fearless_left = 0.0
	if p.mind == Person.Mind.DUTY:
		crowd.off_duty(p)
	elif p.mind in GUARD_MINDS and p.profile != null:
		p.regroup(p.profile.home)


## Blight's mark (god T1R, H3, spec 6.4): a granary not yet spoiled within BlightFx.REACH of `at`, guarded or empty or not (a refusal is
## still a mark, so the player is told why). The granary's middle. Only reads.
func blight_target(at: Vector2) -> Vector2:
	var i := _blight_granary(at)
	return targets[i].center() if i >= 0 else Vector2.INF


## Blight rots a granary whose grain is in and that no watchman of it guards (god T1R, H3; Decision 29: no route round the opposition).
## Only reads.
func blight_takes(at: Vector2) -> bool:
	var i := _blight_granary(at)
	return i >= 0 and has_grain(targets[i]) and not guarding(targets[i])


## Blight landed on a granary (god T1R, H3): taken, it is spoiled and the town's alarm rises (the base); not, only the banner shows.
func blighted(at: Vector2) -> bool:
	var i := _blight_granary(at)
	_blight_said = _blight_words_now(at)
	if not super(at):
		return false
	_spoil(targets[i], "blight")
	return true


## The words of the Blight that just landed (god T1R, H3): kept by blighted(), for the granary is spoiled by the time BlightFx asks.
func blight_words(at: Vector2) -> String:
	return _blight_said if _blight_said != "" else _blight_words_now(at)


func _blight_words_now(at: Vector2) -> String:
	var i := _blight_granary(at)
	if i < 0:
		return ""
	if not has_grain(targets[i]):
		return "NO GRAIN TO ROT YET"
	return "THEIR WATCH KEEPS IT" if guarding(targets[i]) else "BLIGHT - THE GRAIN ROTS"


## The granary not yet spoiled whose footprint lies within BlightFx.REACH of `at`, or -1.
func _blight_granary(at: Vector2) -> int:
	for i in targets.size():
		var s := targets[i]
		if not razed(s) and is_instance_valid(s) and not s.destroyed and s.distance_to(at) <= BlightFx.REACH:
			return i
	return -1


## The night is lost once a granary is emptied (v0.11 M2).
func lost_reason() -> String:
	return "emptied" if emptied != null else ""


## The map tags, most important first (v0.11 M2): each granary not yet spoiled -- burning with the seconds left to spoil it,
## else empty with the time to its grain, else its loads left -- then each watchman (a red diamond labelled WATCHMAN while he is
## on guard, a small red mark while he is away), and a blue diamond on each carter.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s):
			continue
		if burning(s):
			out.append(MapTag.place(s.center(), MARK_BURNING, "GRANARY - BURNING %d" % ceili(maxf(spoil_seconds - burned(s), 0.0)),
				s.height, true))
		elif not has_grain(s):
			out.append(MapTag.place(s.center(), MARK_SEALED, "GRANARY - EMPTY, GRAIN IN %s" % UiTheme.clock(grain_left(s)), s.height, true))
		else:
			out.append(MapTag.place(s.center(), MARK_TARGET, "GRANARY - %d LEFT" % int(loads[s]), s.height, true))
	for s in targets:
		if razed(s):
			continue
		for w: Watch in watches[s]:
			if not _alive(w.man) or (w.man as Person).inside:
				continue
			var p := w.man as Person
			if _on_guard(s, w):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED, "WATCHMAN"))
			else:
				out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
	for s in targets:
		if razed(s) or not _out_at.has(s):
			continue
		var label := "CARTER - %d LEFT" % int(loads[s]) if has_grain(s) else "CARTER - GRAIN IN %s" % UiTheme.clock(grain_left(s))
		for c: Variant in carters.get(s, []):
			if _alive(c) and not (c as Person).inside:
				out.append(MapTag.person((c as Person).ground_pos, MARK_CARTER, label, true))
	return out


## The hint's phase (v0.11 M2): "burning" while a granary burns with no watchman on guard to beat it out, "watchman" while one
## burns under a watchman's eye, "empty" while every granary left is waiting for its grain; else "" (the mission's own line).
func hint_phase() -> String:
	var phase := ""
	var waiting := true
	for s in targets:
		if razed(s):
			continue
		if has_grain(s):
			waiting = false
		if not burning(s):
			continue
		if not guarding(s):
			return "burning"
		phase = "watchman"
	if phase == "" and waiting and razed_count() < targets.size():
		return "empty"
	return phase


## The tour (spec §2, v0.11 M2): the three granaries with their watchmen and when their grain arrives, then the Citadel.
func tour() -> Array:
	var out := []
	for i in targets.size():
		out.append([doors[targets[i]], "The %s granary. Its watchmen put out fires. Its grain arrives by %s." % [store_names[i],
			UiTheme.clock(float(grain_at[i]))]])
	if citadel_door != Vector2.INF:
		out.append([citadel_door, "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled."])
	return out


## What the results show (v0.11 M2): the granaries spoiled, and whether one was emptied.
func report() -> Dictionary:
	return {"spoiled": razed_count(), "emptied": emptied != null}
