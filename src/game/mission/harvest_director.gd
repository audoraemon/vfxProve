class_name HarvestDirector
extends RazeDirector
## Spoiled Harvest (v0.11 M2, Tier 1, spec §2 and §8 row 3; reshaped by the controller's Task 3 fix-round rulings: work, not
## waiting; the grain arrives one granary at a time): three granary stores -- the dwellings nearest STORE_SPOTS, far from the
## Citadel. A granary holds nothing to spoil until its grain arrives: fire on an empty one is put out at once and counts for
## nothing. The first granary's grain arrives at GRAIN_AT[0]; each next one at its own time, or CHAIN_AFTER seconds after the one
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
## The Citadel's gate, where the grain goes; how near a door a carter takes or leaves a load; seconds between looks (v0.11 M2).
const CITADEL_GATE := Vector2(-10.5, -7.6)
const TAKE_REACH := 0.8
const TICK := 0.5
## The map tags' colours (v0.11 M2): a carter steel blue.
const MARK_CARTER := Color("8fb8e8")

## Structure -> loads left in it (v0.11 M2).
var loads := {}
## Structure -> its carters (v0.11 M2; untyped: a carter may be a freed body).
var carters := {}
## Structure -> its Watch records (v0.11 M2).
var watches := {}
## Structure -> true once its grain has arrived (v0.11 M2).
var grain := {}
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
	citadel_door = _walkable(CITADEL_GATE)
	for spot: Vector2 in STORE_SPOTS:
		var s := _house_near(spot, targets)
		if s == null:
			continue
		targets.append(s)
		loads[s] = LOADS
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
		timeline.add(float(GRAIN_AT[i]), "grain_%d" % i, _grain_label(i), _deliver.bind(s),
			func() -> bool: return not has_grain(s) and not razed(s))
	rules.banner.emit("SPOIL THE HARVEST")


## The strip's and the banner's words when granary `i`'s grain arrives (v0.11 M2).
func _grain_label(i: int) -> String:
	return "Grain arrives at the %s granary" % STORE_NAMES[i]


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


## The second of the night granary `i`'s grain arrives at the latest (v0.11 M2): its own time, or CHAIN_AFTER after the one
## before it is spoiled if that is sooner. The one before it still unspoiled never brings it forward.
func grain_due(i: int) -> float:
	var at := float(GRAIN_AT[i]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if i > 0 and spoiled_at[i - 1] >= 0.0:
		at = minf(at, spoiled_at[i - 1] + CHAIN_AFTER)
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


## The grain arrives at `s` (v0.11 M2): it can be spoiled now, and its carter sets out from the Citadel's gate for its door.
func _deliver(s: Structure) -> void:
	if has_grain(s):
		return
	grain[s] = true
	carting.append(s)
	var crew := _lay_near(citadel_door, CARTERS, _busy())
	carters[s] = crew
	for c in crew:
		c.go_duty(doors[s])


## One step (v0.11 M2): the Raze type's, the chain, each granary's watchmen every frame, then every TICK a look at the carters
## and the watchmen's orders.
func step(delta: float) -> void:
	_clock += delta
	super(delta)
	_chain()
	_tick_in -= delta
	var looking := _tick_in <= 0.0
	if looking:
		_tick_in = TICK
	for s in targets:
		if not razed(s):
			_watch(s, delta, looking)
	if not looking:
		return
	for s in carting:
		if emptied == null and not razed(s):
			_cart(s)


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


## Spoiled (v0.11 M2): the chain starts for the next granary; its carters and its watchmen go home, and any load they carry is
## lost. v0.11 M3: the strip shows the next grain's chained time.
func _on_razed(s: Structure) -> void:
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
	for s in carting:
		if razed(s):
			continue
		for c: Variant in carters[s]:
			if _alive(c) and not (c as Person).inside:
				out.append(MapTag.person((c as Person).ground_pos, MARK_CARTER))
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
		out.append([doors[targets[i]], "The %s granary. Its watchmen put out fires. Its grain arrives by %s." % [STORE_NAMES[i],
			UiTheme.clock(float(GRAIN_AT[i]))]])
	if citadel_door != Vector2.INF:
		out.append([citadel_door, "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled."])
	return out


## What the results show (v0.11 M2): the granaries spoiled, and whether one was emptied.
func report() -> Dictionary:
	return {"spoiled": razed_count(), "emptied": emptied != null}
