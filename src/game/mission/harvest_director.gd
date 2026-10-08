class_name HarvestDirector
extends RazeDirector
## Spoiled Harvest (v0.11 M2, Tier 1, spec §2 and §8 row 3; reshaped by the controller's Task 3 fix-round ruling: work, not
## waiting): three granary stores -- the dwellings nearest STORE_SPOTS, far from the Citadel -- all open to the god from the
## start. Each has a watchman, a lay citizen at its door: while he is alive, out of doors and calm (not frightened, confused,
## whispered, compelled, fighting or dead) and at his post, he beats out any fire on his granary after SMOTHER_AFTER seconds,
## and what it had burned is forgotten. The god must first remove him -- strike him down, scare him off, whisper him away --
## then keep the fire burning SPOIL_SECONDS in all, or bring the granary down. A frightened watchman who is calm again returns
## to his post after RETURN_AFTER; a fallen one is replaced RELIEF_AFTER after he fell. Meanwhile CARTERS lay citizens set out
## from the Citadel's gate for each granary at CART_AT and carry its LOADS there, a load taken at a time; the last load taken
## empties it, and a granary emptied cannot be spoiled: the night is lost. Spoil all three to win. The controller's Task 3
## ruling: a 50-hp house falls in about 13 s of burning, so 15 s of burning could never be reached; a granary is spoiled after
## 10 s alight or when it falls, whichever is first.

## One granary's watchman and his post (v0.11 M2): a plain record, so the director holds no cycle.
class Watch:
	extends RefCounted
	## The watchman, held as a Variant and read only through MissionDirector._alive(): he may be a body freed after his death
	## fade.
	var man: Variant = null
	## Where he stands, beside the granary's door.
	var post := Vector2.INF
	## Seconds a fire has burned on the granary with him on guard.
	var alight := 0.0
	## Seconds since he was last on guard (he is alive but frightened, held or away).
	var away := 0.0
	## Seconds since he fell (a relief is sent RELIEF_AFTER after).
	var fallen := 0.0


## Where the granaries stand (the nearest dwelling to each), and their names on the banners and the tour (v0.11 M2).
const STORE_SPOTS := [Vector2(-9.0, 12.0), Vector2(12.0, 12.0), Vector2(12.0, -12.0)]
const STORE_NAMES := ["south-west", "south-east", "north-east"]
## First guesses (the controller's Task 3 fix-round ruling), tuned if the scripted clear or the loss misses its window
## (v0.11 M2): when each granary's carts set out, how long it must burn to be spoiled, how many loads it holds, how many
## carters take them.
const CART_AT := [30.0, 90.0, 150.0]
const SPOIL_SECONDS := 10.0
const LOADS := 6
const CARTERS := 1
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
## Where the watchman stands, from his granary's door (v0.11 M2).
const WATCH_OFF := Vector2(-1.2, 0.3)
## The minds a watchman keeps guard in (v0.11 M2): going about his day, looking on, or on duty at his post. Any other -- fright,
## flight, shelter, the rally, a fight, the god's hold, fetching water at a fire -- and he does not.
const GUARD_MINDS := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.DUTY]
## The Citadel's gate, where the grain goes; how near a door a carter takes or leaves a load; seconds between looks (v0.11 M2).
const CITADEL_GATE := Vector2(-10.5, -7.6)
const TAKE_REACH := 0.8
const TICK := 0.5
## The map tags' colours (v0.11 M2): a watchman red, a carter steel blue.
const MARK_CARTER := Color("8fb8e8")

## Structure -> loads left in it (v0.11 M2).
var loads := {}
## Structure -> its carters (v0.11 M2; untyped: a carter may be a freed body).
var carters := {}
## Structure -> its Watch (v0.11 M2).
var watches := {}
## The granaries whose carts have set out, in order (v0.11 M2).
var carting: Array[Structure] = []
## The first granary emptied (the night is lost), or null (v0.11 M2).
var emptied: Structure
## The Citadel's gate on walkable ground, and each granary's door (Structure -> Vector2) (v0.11 M2).
var citadel_door := Vector2.INF
var doors := {}
## Instance ids of the carters carrying a load to the Citadel (v0.11 M2).
var _hauling := {}
## Seconds to the next look at the carters and the watchmen's orders (v0.11 M2, TICK).
var _tick_in := 0.0


## The night's setup (v0.11 M2): the three granaries, a watchman set down at each, and each one's carts on the timeline.
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
	for s in targets:
		var w := Watch.new()
		w.post = _walkable(doors[s] + WATCH_OFF)
		var crew := _lay_near(w.post, 1, _busy())
		if not crew.is_empty():
			w.man = crew[0]
			_set_down(crew[0], w.post)
		watches[s] = w
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		var s := targets[i]
		timeline.add(float(CART_AT[i]), "cart_%d" % i, "The %s granary's carts set out" % STORE_NAMES[i], _send_carts.bind(s),
			func() -> bool: return not razed(s))
	rules.banner.emit("SPOIL THE HARVEST")


## Everyone the director has put to work (v0.11 M2): every granary's carters and watchman, for a new one to leave out.
func _busy() -> Array:
	var out: Array = []
	for crew: Array in carters.values():
		out.append_array(crew)
	for w: Watch in watches.values():
		if w.man != null:
			out.append(w.man)
	return out


## A granary's carts set out (v0.11 M2): the lay citizens nearest the Citadel's gate not already at work go to its door.
func _send_carts(s: Structure) -> void:
	carting.append(s)
	var crew := _lay_near(citadel_door, CARTERS, _busy())
	carters[s] = crew
	for c in crew:
		c.go_duty(doors[s])


## One step (v0.11 M2): the Raze type's, each watchman at his post every frame, then every TICK a look at the carters and the
## watchmen's orders.
func step(delta: float) -> void:
	super(delta)
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


## Whether `s`'s watchman is on guard now (v0.11 M2): alive, out of doors, in a calm mind, and at his post.
func guarding(s: Structure) -> bool:
	var w: Watch = watches.get(s)
	if w == null or not _alive(w.man):
		return false
	var p := w.man as Person
	return not p.inside and p.mind in GUARD_MINDS and s.distance_to(p.ground_pos) <= GUARD_REACH


## `s`'s watchman, or null while there is none standing (v0.11 M2).
func watchman(s: Structure) -> Person:
	var w: Watch = watches.get(s)
	return w.man as Person if w != null and _alive(w.man) else null


## One granary's watchman (v0.11 M2): on guard, he holds his post while his granary burns (HOLD_POST) and beats the fire out
## once it has burned SMOTHER_AFTER on his granary, and what it had burned is forgotten. Off guard but alive, he is sent back to his post RETURN_AFTER after (once calm); fallen, a relief is
## sent RELIEF_AFTER after.
func _watch(s: Structure, delta: float, looking: bool) -> void:
	var w: Watch = watches[s]
	if guarding(s):
		w.away = 0.0
		w.fallen = 0.0
		if not burning(s):
			w.alight = 0.0
			return
		var man := w.man as Person
		man.fearless_left = maxf(man.fearless_left, HOLD_POST)
		w.alight += delta
		if w.alight >= SMOTHER_AFTER:
			w.alight = 0.0
			crowd.fires._put_out(s, true)
			forget_burn(s)
		return
	w.alight = 0.0
	if _alive(w.man):
		w.fallen = 0.0
		w.away += delta
		if looking and w.away >= RETURN_AFTER:
			_recall(w)
	else:
		w.fallen += delta
		if looking and w.fallen >= RELIEF_AFTER:
			_relieve(w)


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


## Spoiled (v0.11 M2): its carters and its watchman go home, and any load they carry is lost.
func _on_razed(s: Structure) -> void:
	rules.banner.emit("A GRANARY IS SPOILED")
	for c: Variant in carters.get(s, []):
		if _alive(c):
			var p := c as Person
			_hauling.erase(p.get_instance_id())
			if p.mind == Person.Mind.DUTY:
				crowd.off_duty(p)
	carters[s] = []
	var w: Watch = watches.get(s)
	if w != null and _alive(w.man) and (w.man as Person).mind == Person.Mind.DUTY:
		crowd.off_duty(w.man as Person)


## The night is lost once a granary is emptied (v0.11 M2).
func lost_reason() -> String:
	return "emptied" if emptied != null else ""


## The map tags, most important first (v0.11 M2): each granary not yet spoiled -- its carts still to come with the time to
## them, burning with the seconds left to spoil it, else its loads left -- then each watchman (a red diamond labelled
## WATCHMAN while he is on guard, a small red mark while he is away), and a blue diamond on each carter.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s):
			continue
		if burning(s):
			out.append(MapTag.place(s.center(), MARK_BURNING, "GRANARY - BURNING %d" % ceili(maxf(spoil_seconds - burned(s), 0.0)),
				s.height, true))
		elif not carting.has(s):
			var left := timeline.seconds_to("cart_%d" % i) if timeline != null else 0.0
			out.append(MapTag.place(s.center(), MARK_TARGET, "GRANARY - CARTS IN %s" % UiTheme.clock(left), s.height, true))
		else:
			out.append(MapTag.place(s.center(), MARK_TARGET, "GRANARY - %d LEFT" % int(loads[s]), s.height, true))
	for s in targets:
		var w: Watch = watches[s]
		if razed(s) or not _alive(w.man) or (w.man as Person).inside:
			continue
		var p := w.man as Person
		if guarding(s):
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


## The hint's phase (v0.11 M2): "burning" while an unspoiled granary burns with no watchman to beat it out, "watchman" while
## one burns under his eye; else "" (the mission's own line).
func hint_phase() -> String:
	var phase := ""
	for s in targets:
		if razed(s) or not burning(s):
			continue
		if not guarding(s):
			return "burning"
		phase = "watchman"
	return phase


## The tour (spec §2, v0.11 M2): the three granaries with their watchmen and when their carts set out, then the Citadel.
func tour() -> Array:
	var out := []
	for i in targets.size():
		out.append([doors[targets[i]], "The %s granary. Its watchman puts out fires. Its carts set out at %s." % [STORE_NAMES[i],
			UiTheme.clock(float(CART_AT[i]))]])
	if citadel_door != Vector2.INF:
		out.append([citadel_door, "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled."])
	return out


## What the results show (v0.11 M2): the granaries spoiled, and whether one was emptied.
func report() -> Dictionary:
	return {"spoiled": razed_count(), "emptied": emptied != null}
