class_name CrownsBreadDirector
extends RazeDirector
## The Crown's Bread (v0.11 M4, Tier 3, mission spec §1; Raze, reused): the Crown's bread is made tonight. Destroy the granary (the
## farmhouse by the east road, TownLayout.BARNS[3]), the mill (the watermill on the south bank) and the bridge (the stone bridge on
## the south road). Each comes into use on the chain (Spoiled Harvest's grain rule, RazeDirector._spoilable()): the granary at
## STAGE_AT[0], each next at its own time or CHAIN after the one before is razed, whichever is sooner. Every blow lands from the start
## -- nothing is sealed -- but fire on a target not in use is put out at once, and a fall counts only once it is in use: a target down
## when its time comes is razed at once. Each target has a night crew of NIGHT_CREW engineers on posts along its open face from the
## start, and a shift of SHIFT who wait indoors until its stage (the granary's and mill's in their own building, the bridge's in the
## Main Gate's west tower) and then each comes out at his own post POST_GAP beyond, spread like the night crew (the controller's fix
## round 1 ruling: one strike never clears a stage). An engineer on guard -- alive, out of doors, within GUARD_REACH and calm
## (Spoiled Harvest's GUARD_MINDS) -- mends MEND of its health a second, beats out a fire in use after SMOTHER_AFTER, and
## rebuilds a fall not in use (Structure.restore()) in REBUILD with two, REBUILD_ONE with one. One off his post walks back
## RETURN_AFTER after he left; a fallen one is replaced RELIEF_AFTER after he fell. The town's own teams keep off (hands_off). All
## three razed wins; the Crown's carts roll at CARTS_AT (EventObjective) and lose.

## One crewman's post (v0.11 M4): a plain record, so the director holds no cycle.
class Crew:
	extends RefCounted
	## The crewman, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## Where he stands on guard.
	var post := Vector2.INF
	## He is of the shift (indoors until his target's stage), not the night crew.
	var shift := false
	## Seconds since he was last on guard (alive but away), and since he fell.
	var away := 0.0
	var fallen := 0.0
	## He is a relief walking in, until he first stands guard.
	var relief := false


## The targets' names on the tags and the banners, and in words (v0.11 M4), in order: granary, mill, bridge.
const NAMES := ["GRANARY", "MILL", "BRIDGE"]
const WORDS := ["granary", "mill", "bridge"]
## The strip's and the banners' words as each comes into use (v0.11 M4, mission spec §1).
const STAGE_LABELS := ["The grain carts fill the granary", "The mill grinds the Crown's flour", "The bread carts gather at the bridge"]
## Mission spec §1's numbers (v0.11 M4), tuned by Task 2's gate in this order: SHIFT (1-3), STAGE_AT[0] (30-60), CHAIN (30-45),
## RELIEF_AFTER (20-30), MEND -- SHIFT 2 -> 3 (round 1); with the shift come out spread (fix round 1), STAGE_AT[0] back at 45. When
## each target comes into use at the latest; how long after one is razed the next does; the crews; the posts' spacing; how near an
## engineer stands to be on guard; the work's rates; return and relief; the carts.
const STAGE_AT := [45.0, 115.0, 185.0]
const CHAIN := 45.0
const NIGHT_CREW := 2
const SHIFT := 3
const POST_GAP := 1.8
const GUARD_REACH := 2.5
const MEND := 0.025
const SMOTHER_AFTER := 3.0
const REBUILD := 20.0
const REBUILD_ONE := 40.0
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const CARTS_AT := 300.0
## How near its time a target not yet in use puts the hint on "not_yet" (v0.11 M4, decision 102): the spec's "last 25 s".
const WORK_AHEAD := 25.0
## Where the camera rests (v0.11 M4, Decision 80): above the Main Gate's road; the bridge left of the centre, the granary at the
## right, the mill's arrow on the left edge at mid height.
const CAMERA_AT := Vector2(6.0, 20.0)
## Seconds between looks at the crews' orders (v0.11 M4).
const TICK := 0.5

## Each target's Crew records, in the order of `targets` (v0.11 M4).
var crews: Array = []
## Each target in use yet; the second of the night it was razed (-1 until then) (v0.11 M4).
var in_use: Array[bool] = []
var razed_at: Array[float] = []
## Each target's face, the centre of its crew's line (decision 99); where its shift waits (decision 100) (v0.11 M4).
var faces: Array[Vector2] = []
var waiting_in: Array[Structure] = []
## Each target's rebuild so far, 0..1 (decision 101); how many rebuilds in all (v0.11 M4).
var rebuild_progress: Array[float] = []
var rebuilt := 0
## Each target's fire's seconds with one on guard, in use (v0.11 M4).
var _alight: Array[float] = []
## Seconds into the night, and to the next look (v0.11 M4).
var _clock := 0.0
var _tick_in := 0.0


## The night's setup (v0.11 M4): the three targets, kept from the town's teams; at each its night crew set down and kept on duty on
## its face, and its shift taken indoors; each stage and the carts on the strip.
func _begin() -> void:
	targets.assign(_find_targets())
	if crowd.engineers != null:
		crowd.engineers.hands_off.append_array(targets)
	for i in targets.size():
		var s := targets[i]
		in_use.append(false)
		razed_at.append(-1.0)
		rebuild_progress.append(0.0)
		_alight.append(0.0)
		faces.append(_face(s))
		waiting_in.append(s if i < 2 else _gate_tower())
		var list: Array = []
		for k in NIGHT_CREW:
			list.append(_appoint(i, _post(i, k, false, list), false, list))
		for k in SHIFT:
			list.append(_appoint(i, _post(i, k, true, list), true, list))
		crews.append(list)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		timeline.add(float(STAGE_AT[i]), "stage_%d" % i, String(STAGE_LABELS[i]), _open.bind(i),
			func() -> bool: return not in_use[i] and not razed(targets[i]))
	timeline.add(CARTS_AT, "carts", "The Crown's carts roll", Callable(), func() -> bool: return not all_razed())
	rules.banner.emit("THE CROWN'S BREAD")


## The granary, the mill and the bridge (v0.11 M4, Decision 61), those the town has.
func _find_targets() -> Array[Structure]:
	var granary: Structure = null
	var mill: Structure = null
	var barn: Rect2 = TownLayout.BARNS[3]
	for s: Structure in town._built:
		if not is_instance_valid(s):
			continue
		if s.role == &"farm" and s.kind == Structure.Kind.HOUSE and s.footprint.position.is_equal_approx(barn.position):
			granary = s
		elif s.art_tag == &"watermill":
			mill = s
	var out: Array[Structure] = []
	for s in [granary, mill, town.bridge]:
		if s != null:
			out.append(s)
	return out


## Target `s`'s face (v0.11 M4, decision 99): a building's door the nearest town gate's street reaches; the bridge's town end.
func _face(s: Structure) -> Vector2:
	if s == town.bridge:
		return _walkable(s.center() - Vector2(0.0, s.footprint.size.y * 0.5 + 0.5))
	var gate := Vector2.INF
	for g: Structure in town.gates:
		if is_instance_valid(g) and (gate == Vector2.INF or g.center().distance_to(s.center()) < gate.distance_to(s.center())):
			gate = g.center()
	var door := _open_door(s, _walkable(gate)) if gate != Vector2.INF else Vector2.INF
	return door if door != Vector2.INF else _front_of(s)


## Where the bridge's shift waits (v0.11 M4, decision 100): the Main Gate's west tower, else the east one; never one a wish has set
## aside; null for neither.
func _gate_tower() -> Structure:
	for r: Rect2 in [TownLayout.GATE_TOWERS[0], TownLayout.GATE_TOWERS[1]]:
		for s: Structure in town._built:
			if is_instance_valid(s) and s.role == &"tower" and s.footprint.position.is_equal_approx(r.position) \
					and not reserved_places.has(s):
				return s
	return null


## The `k`th post of target `i` (v0.11 M4, decision 99): along its face, the night crew POST_GAP apart about its centre, the shift
## POST_GAP beyond them; a third of the shift POST_GAP out from the face. Each is kept one Silent Doom apart from the posts already
## set (`mates`, the controller's fix round 1 ruling) by _spread().
func _post(i: int, k: int, shift: bool, mates: Array) -> Vector2:
	var face := faces[i]
	var out := face - targets[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	var side := -1.0 if k % 2 == 0 else 1.0
	var want := face + along * side * POST_GAP * 0.5
	if shift:
		want = face + out * POST_GAP if k >= 2 else face + along * side * POST_GAP * 1.5
	return _spread(i, want, mates)


## A post at or near `want` for target `i` (v0.11 M4, the controller's fix round 1 ruling): walkable, within GUARD_REACH of the
## target, reached on foot from its face (a crewman sent back or a relief must get there), and farther than two Silent Doom radii
## from every post in `mates`, so one strike never takes two of its crew. The nearest such point on rings of POST_GAP / 2 steps
## round `want`; `want` made walkable when there is none.
func _spread(i: int, want: Vector2, mates: Array) -> Vector2:
	var first := _walkable(want)
	for ring in 5:
		var r := POST_GAP * 0.5 * float(ring)
		var n := 1 if ring == 0 else 12
		for k in n:
			var at := first if ring == 0 else _walkable(want + Vector2.from_angle(TAU * float(k) / float(n)) * r)
			if targets[i].distance_to(at) > GUARD_REACH or (crowd._grid != null and (not crowd._grid.walkable(at)
					or (at.distance_to(faces[i]) > 0.1 and crowd._grid.path(faces[i], at).is_empty()))):
				continue
			var clear := true
			for m: Crew in mates:
				clear = clear and m.post.distance_to(at) > 2.0 * SilentDoom.RADIUS
			if clear:
				return at
	return first


## A crewman for target `i` at `post` (v0.11 M4): the free lay citizen nearest it, none of the crews so far nor of `mates` (the
## target's own crew being made), made an engineer (and never hired by the town's workshop, decision 97). The night crew is set down
## and kept on duty there; the shift goes indoors where it waits.
func _appoint(i: int, post: Vector2, shift: bool, mates: Array) -> Crew:
	var c := Crew.new()
	c.post = post
	c.shift = shift
	var taken := _busy()
	for m: Crew in mates:
		if m.man != null:
			taken.append(m.man)
	var near := _lay_near(post, 1, taken)
	if near.is_empty():
		return c
	var p := near[0]
	_make_engineer(p)
	c.man = p
	_set_down(p, post)
	p.go_duty(post)
	if shift:
		_take_inside(p, waiting_in[i])
	return c


## `p` dressed as an engineer (the apron, cap and hammer) and kept from the workshop's hiring (v0.11 M4).
func _make_engineer(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.ENGINEER
	if crowd.engineers != null and not crowd.engineers.not_hired.has(p):
		crowd.engineers.not_hired.append(p)


## Everyone the director has put to work (v0.11 M4), for a new one to leave out.
func _busy() -> Array:
	var out: Array = []
	for list: Array in crews:
		for c: Crew in list:
			if c.man != null:
				out.append(c.man)
	return out


## Target `s` can be razed: it is in use (v0.11 M4; RazeDirector._spoilable()).
func _spoilable(s: Structure) -> bool:
	var i := targets.find(s)
	return i >= 0 and i < in_use.size() and in_use[i]


## The second of the night target `i` comes into use at the latest (v0.11 M4): its own time, or CHAIN after the one before is razed if
## that is sooner. The one before still standing never brings it forward.
func stage_due(i: int) -> float:
	var at := float(STAGE_AT[i]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if i > 0 and razed_at[i - 1] >= 0.0:
		at = minf(at, razed_at[i - 1] + CHAIN)
	return at


## Seconds until target `i` comes into use at the latest (v0.11 M4); 0 once it is.
func due_in(i: int) -> float:
	return 0.0 if in_use[i] else maxf(stage_due(i) - _clock, 0.0)


## Each target not yet in use whose chained time has come comes into use (v0.11 M4); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, targets.size()):
		if not in_use[i] and not razed(targets[i]) and razed_at[i - 1] >= 0.0 and _clock >= stage_due(i):
			rules.banner.emit(String(STAGE_LABELS[i]).to_upper())
			_open(i)


## Target `i` comes into use (v0.11 M4): each of its shift comes out at his own post, on duty there.
func _open(i: int) -> void:
	if in_use[i]:
		return
	in_use[i] = true
	for c: Crew in crews[i]:
		if c.shift:
			_bring_out_shift(c)
			if _alive(c.man):
				(c.man as Person).go_duty(c.post)


## Shift man `c`, if still indoors, comes out at his own post (v0.11 M4, the controller's fix round 1 ruling): the shift spread like
## the night crew, POST_GAP apart, never bunched at one door where one strike would take them all.
func _bring_out_shift(c: Crew) -> void:
	if not _alive(c.man) or not (c.man as Person).inside:
		return
	_bring_out(c.man as Person, c.post)
	_keep_from_flight(c.man as Person, true)  # Crowd._evacuate() sends one waiting indoors running too, if he was not on duty


## One step (v0.11 M4): the Raze type's (the timeline, each target judged), the chain, then every frame each target's crew at its
## work, with every TICK a look at their orders.
func step(delta: float) -> void:
	_clock += delta
	super(delta)
	_chain()
	_tick_in -= delta
	var looking := _tick_in <= 0.0
	var evacuating := false
	if looking:
		_tick_in = TICK
		evacuating = _evacuation_began()
		_keep_held(evacuating)
	for i in targets.size():
		if not razed(targets[i]):
			_work(i, delta, looking, evacuating)


## Every crewman of a target not razed who stands out of doors is kept out of the town's flight (v0.11 M4, the controller's ruling;
## M3's final review's rule, MissionDirector._keep_from_flight(): `evacuating`, at the first look after the evacuation began, stops
## one it sent running; a whisper it found him under ends with him on his feet). _work() then puts him on duty again by its own
## rules. A shift man waiting indoors is on duty and the evacuation passes him by.
func _keep_held(evacuating: bool) -> void:
	for i in targets.size():
		if razed(targets[i]):
			continue
		for c: Crew in crews[i]:
			if _alive(c.man) and not (c.man as Person).inside:
				_keep_from_flight(c.man as Person, evacuating)


## Crewman `c` of target `i` is on guard now (v0.11 M4): alive, out of doors, calm (GUARD_MINDS) and within GUARD_REACH of it.
func _on_guard(i: int, c: Crew) -> bool:
	if not _alive(c.man):
		return false
	var p := c.man as Person
	return not p.inside and p.mind in HarvestDirector.GUARD_MINDS and targets[i].distance_to(p.ground_pos) <= GUARD_REACH


## Target `i`'s crewmen on guard now (v0.11 M4). Only reads.
func guards(i: int) -> Array[Person]:
	var out: Array[Person] = []
	if i < 0 or i >= crews.size():
		return out
	for c: Crew in crews[i]:
		if _on_guard(i, c):
			out.append(c.man as Person)
	return out


## Target `i`'s Crew records (v0.11 M4). Only reads.
func crew_of(i: int) -> Array:
	return crews[i]


## A relief of target `i` walking in, or null (v0.11 M4, for the scripted player). Only reads.
func relief_walking(i: int) -> Person:
	for c: Crew in crews[i]:
		if c.relief and _alive(c.man) and not (c.man as Person).inside and not _on_guard(i, c):
			return c.man as Person
	return null


## The current target (v0.11 M4, decision 102): the first not razed, or -1.
func current() -> int:
	for i in targets.size():
		if not razed(targets[i]):
			return i
	return -1


## The first target not razed and not yet in use, or -1 (v0.11 M4).
func upcoming() -> int:
	for i in targets.size():
		if not razed(targets[i]) and not in_use[i]:
			return i
	return -1


## Seconds left of target `i`'s rebuild at the rate its crew on guard works now (v0.11 M4); 0 when none is on guard or it stands.
func rebuild_left(i: int) -> float:
	var on := guards(i).size()
	if on == 0 or not targets[i].destroyed:
		return 0.0
	return (1.0 - rebuild_progress[i]) * (REBUILD if on >= 2 else REBUILD_ONE)


## Target `i`'s crew at its work (v0.11 M4). Each on guard is held there; one off his post but alive is sent back RETURN_AFTER after he
## left (a shift man waiting indoors is not away), or at once at the first look after the town began to evacuate (`evacuating`: one
## _keep_held() just stopped from running is put straight back on duty); a fallen one is replaced RELIEF_AFTER after he fell (a
## shift slot, filled or never filled, only once its target is in use). With one or more on guard: a fallen target not in use is
## rebuilt (decision 101); a standing one is mended; one in use and alight is held to and beaten out after SMOTHER_AFTER, its burning
## forgotten. Copied from Spoiled Harvest's watch record (Decision 89).
func _work(i: int, delta: float, looking: bool, evacuating := false) -> void:
	var s := targets[i]
	var on := 0
	for c: Crew in crews[i]:
		if _on_guard(i, c):
			on += 1
			c.away = 0.0
			c.fallen = 0.0
			c.relief = false
			if looking and (c.man as Person).mind != Person.Mind.DUTY:
				_recall_to(c.man, c.post, evacuating)  # back on his feet within reach: on duty again, so the town's flight passes him by
		elif _alive(c.man):
			c.fallen = 0.0
			if (c.man as Person).inside:
				continue
			c.away += delta
			if looking and (c.away >= RETURN_AFTER or evacuating):
				_recall_to(c.man, c.post, evacuating)
		elif not c.shift or in_use[i]:
			c.fallen += delta  # a shift slot never filled gets no relief before its stage: none stands outdoors ahead of it
			if looking and c.fallen >= RELIEF_AFTER:
				_relieve(i, c)
	if not is_instance_valid(s):
		return
	if s.destroyed:
		_alight[i] = 0.0
		if in_use[i] or on == 0:
			return
		rebuild_progress[i] += delta / (REBUILD if on >= 2 else REBUILD_ONE)
		if rebuild_progress[i] >= 1.0:
			rebuild_progress[i] = 0.0
			s.restore()
			rebuilt += 1
			rules.banner.emit("THE ENGINEERS REBUILD THE %s" % NAMES[i])
		return
	if on == 0:
		_alight[i] = 0.0
		return
	s.repair(MEND * s.max_hp * delta * float(on))
	if not (in_use[i] and burning(s)):
		_alight[i] = 0.0
		return
	for c: Crew in crews[i]:
		if _on_guard(i, c):
			var man := c.man as Person
			man.fearless_left = maxf(man.fearless_left, HarvestDirector.HOLD_POST)
	_alight[i] += delta
	if _alight[i] >= SMOTHER_AFTER:
		_alight[i] = 0.0
		crowd.fires._put_out(s, true)
		forget_burn(s)


## A relief for fallen crewman `c` of target `i` (v0.11 M4): the nearest lay citizen with a way to the post, made an engineer. One
## chosen once the town is running is stopped from the flight first (Task 1's Hunt relief, the review's fix round 2): go_duty() refuses
## a fleeing man, and he would run on to the gates.
func _relieve(i: int, c: Crew) -> void:
	var p := _lay_reaching(c.post, _busy())
	if p == null:
		return
	_make_engineer(p)
	c.man = p
	c.fallen = 0.0
	c.away = 0.0
	c.relief = true
	if crowd._fled_all:
		_keep_from_flight(p, true)  # chosen once the town is running: never one of the flight
	p.go_duty(c.post)
	rules.banner.emit("A NEW ENGINEER TAKES THE %s" % NAMES[i])


## Razed (v0.11 M4): the chain starts for the next target and the strip shows its time; its crew and shift go home (a shift still
## indoors comes out first).
func _on_razed(s: Structure) -> void:
	var i := targets.find(s)
	rules.banner.emit("THE %s IS RAZED" % NAMES[i])
	razed_at[i] = _clock
	if timeline != null and i + 1 < targets.size():
		timeline.expect("stage_%d" % (i + 1), stage_due(i + 1))
	for c: Crew in crews[i]:
		_bring_out_shift(c)
		_release(c)


## A razed target's crewman goes home (v0.11 M4, Spoiled Harvest's _release()): one on duty stood down, one calm sent home; the hold
## that kept him at his post while it burned ends with it.
func _release(c: Crew) -> void:
	if not _alive(c.man):
		return
	var p := c.man as Person
	if p.fearless_left <= HarvestDirector.HOLD_POST:
		p.fearless_left = 0.0
	if p.mind == Person.Mind.DUTY:
		crowd.off_duty(p)
	elif p.mind in HarvestDirector.GUARD_MINDS and p.profile != null:
		p.regroup(p.profile.home)


## The map tags, most important first (v0.11 M4, mission spec §1): each target not razed, pointed at -- not in use, grey, "IN USE BY"
## its chained time, or "DOWN" (with its rebuild's seconds while one works on it); in use, gold, or orange while burning -- then each
## crewman: ENGINEER on guard, a red diamond on a relief walking in, a small red mark on one away.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s):
			continue
		var name := String(NAMES[i])
		if not in_use[i]:
			var label := "%s - IN USE BY %s" % [name, UiTheme.clock(stage_due(i))]
			if s.destroyed:
				var left := rebuild_left(i)
				label = "%s - DOWN, REBUILT IN %d" % [name, ceili(left)] if left > 0.0 else "%s - DOWN" % name
			out.append(MapTag.place(s.center(), MARK_SEALED, label, s.height, true))
		elif burning(s):
			out.append(MapTag.place(s.center(), MARK_BURNING, "%s - BURNING" % name, s.height, true))
		else:
			out.append(MapTag.place(s.center(), MARK_TARGET, name, s.height, true))
	for i in targets.size():
		if razed(targets[i]):
			continue
		for c: Crew in crews[i]:
			if not _alive(c.man) or (c.man as Person).inside:
				continue
			var p := c.man as Person
			if _on_guard(i, c):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED, "ENGINEER"))
			elif c.relief:
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M4, decision 102), for the current target: not in use, "not_yet" when down or WORK_AHEAD or less from its
## time, else ""; in use, "engineers" while one is on guard, else "open".
func hint_phase() -> String:
	var i := current()
	if i < 0:
		return ""
	if not in_use[i]:
		return "not_yet" if targets[i].destroyed or due_in(i) <= WORK_AHEAD else ""
	return "engineers" if not guards(i).is_empty() else "open"


## The tour (v0.11 M4, mission spec §1): the granary, the mill, the bridge, each with its time.
func tour() -> Array:
	var words := ["The granary by the east road. In use at %s. Its engineers mend and rebuild.",
		"The mill across the river. In use by %s.", "The bridge. The bread carts gather here by %s. It takes blows, not fire."]
	var out := []
	for i in targets.size():
		out.append([faces[i], String(words[i]) % UiTheme.clock(float(STAGE_AT[i]))])
	return out


## What the results show (v0.11 M4): the targets razed and the rebuilds.
func report() -> Dictionary:
	return {"razed": razed_count(), "rebuilt": rebuilt}


## Lets go of the town's engineers' lists, then the Raze type's (v0.11 M4).
func teardown() -> void:
	if is_instance_valid(crowd) and crowd.engineers != null:
		for s in targets:
			if is_instance_valid(s):
				crowd.engineers.hands_off.erase(s)
		for v: Variant in _busy():
			crowd.engineers.not_hired.erase(v)
	super()
