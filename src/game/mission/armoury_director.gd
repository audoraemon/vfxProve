class_name ArmouryDirector
extends RazeDirector
## The Armoury (v0.11 M5, Tier 4, mission spec §2 with the controller's staged ruling replacing Decision 137; Raze, reused): the muster
## horn arms the garrison. Destroy the north barracks (the north tavern by the Citadel's lane, TownLayout.TAVERNS[0]), the gate barracks
## (the Main Gate's east tower, GATE_TOWERS[1]: stone, blows only) and the armoury (the barracks shed); a target a wish has set aside
## gives way to the west tavern or tower. Each musters on the chain (The Crown's Bread's stages, RazeDirector._spoilable()): the north
## barracks at STAGE_AT[0], each next at its own time or CHAIN after the one before is razed, whichever is sooner. Every blow lands from
## the start, but fire on a target not mustering is put out at once and its fall is judged only at its horn: one down then is razed at
## once. Two armed men -- lay citizens made watchmen -- stand each target's night watch from the start on posts along its face, POST_GAP
## apart; at its horn its squad of SQUAD comes out of its door to posts POST_GAP beyond them. An armed man on guard (alive, out of doors,
## within GUARD_REACH, not frightened or whispered) is held deaf to a whisper and past fear and set back on his post at every look; while
## one stands guard the target is sealed (RazeDirector.seal(): a blow only shakes it, its fire is put out), before or after its horn,
## and the seconds it burned stay counted. One off his post walks back RETURN_AFTER after he left; a fallen one is replaced RELIEF_AFTER
## later from the reserve of RESERVE waiting inside the Citadel's gate. From each horn, while a target musters, one armed man marches
## out of the Citadel's gate every REINFORCE seconds (by the clock's minute) to the first mustering target -- from the Citadel, not the
## armoury, so the armoury felled early never stops them (the controller's ruling). Razed -- fallen, or burned SPOIL_SECONDS in all
## after its horn -- its men go home, and those still running in walk back into the Citadel. All three razed wins; the garrison marches
## at MARCH_AT (EventObjective) and loses (plan decisions 177-182).

## One armed man's post (v0.11 M5): a plain record, so the director holds no cycle.
class Armed:
	extends RefCounted
	## The man, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## Where he stands on guard.
	var post := Vector2.INF
	## He is of the squad (indoors until his target's horn).
	var squad := false
	## He is a reinforcement from the Citadel.
	var reinforcement := false
	## Seconds since he was last on guard (alive but away).
	var away := 0.0
	## Seconds since he fell.
	var fallen := 0.0
	## He is running in (a relief or a reinforcement) until he first stands guard.
	var relief := false


## The targets' names on the tags (v0.11 M5, mission spec §2).
const NAMES := ["BARRACKS", "BARRACKS", "ARMOURY"]
## The targets in words, for the banners (v0.11 M5).
const WORDS := ["north barracks", "gate barracks", "armoury"]
## The strip's and the banners' words at each horn (v0.11 M5, mission spec §2).
const HORN_LABELS := ["The muster horn: the north barracks turns out", "The muster horn: the gate barracks turns out",
	"The muster horn: the garrison arms"]
## When each target musters at the latest (v0.11 M5, mission spec §2's numbers, tuned by the gate in this order: SQUAD (1-3),
## STAGE_AT[0] (30-45), CHAIN (30-45), REINFORCE, SPOIL_SECONDS (10-15)).
const STAGE_AT := [40.0, 110.0, 180.0]
## How long after one target is razed the next musters, if sooner than its own time (v0.11 M5).
const CHAIN := 40.0
## The armed men on each target's night watch from the start (v0.11 M5).
const NIGHT_WATCH := 2
## The armed men of each target's squad, indoors until its horn (v0.11 M5).
const SQUAD := 3
## The spacing of the posts along a target's face (v0.11 M5): more than two Silent Doom radii, so one strike takes one man.
const POST_GAP := 1.8
## How near a target an armed man stands to be on guard (v0.11 M5), measured to its footprint (Structure.distance_to()).
const GUARD_REACH := 2.5
## Seconds of burning, in all, after its horn, that raze a target (v0.11 M5; RazeDirector.spoil_seconds).
const SPOIL_SECONDS := 12.0
## Seconds an armed man off his post and back on his feet waits before he walks back (v0.11 M5).
const RETURN_AFTER := 20.0
## Seconds after an armed man falls that one from the reserve runs to his post (v0.11 M5).
const RELIEF_AFTER := 30.0
## Seconds between reinforcements by the clock's minute (v0.11 M5, plan decision 179): 40 in the first two, 30 in the third, 20 in
## the fourth, 12 from the fifth on.
const REINFORCE := [40.0, 40.0, 30.0, 20.0, 12.0]
## The armed men waiting inside the Citadel's gate for reliefs and reinforcements (v0.11 M5).
const RESERVE := 8
## When the garrison marches and the night is lost (v0.11 M5).
const MARCH_AT := 300.0
## How near its horn a target not mustering puts the hint on "not_yet" (v0.11 M5): the spec's "last 25 s".
const WORK_AHEAD := 25.0
## How long past each look an armed man on guard is kept deaf and fearless (v0.11 M5): more than a TICK, so neither lapses between looks.
const ARMED_HOLD := 1.0
## The minds that take an armed man off guard (v0.11 M5, plan decision 178): Discord's does not.
const OFF_GUARD := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER, Person.Mind.WHISPERED]
## Where the camera rests (v0.11 M5, Decision 159): the north barracks just above the centre, the other two pointed at from the bottom.
const CAMERA_AT := Vector2(-5.5, -4.5)
## The Citadel's gate (v0.11 M5, the controller's ruling): where the reserve waits and the reinforcements march from.
const CITADEL_GATE := HarvestDirector.CITADEL_GATE
## Seconds between looks at the armed men (v0.11 M5).
const TICK := 0.5

## Each target's Armed records, in the order of `targets` (v0.11 M5).
var armed: Array = []
## Each target musters yet (v0.11 M5).
var mustering: Array[bool] = []
## The second of the night each target was razed, -1 until then (v0.11 M5).
var razed_at: Array[float] = []
## Each target's face, the middle of its posts (v0.11 M5).
var faces: Array[Vector2] = []
## The Citadel's gate on walkable ground (v0.11 M5).
var citadel_door := Vector2.INF
## The reserve, waiting inside the Citadel's gate (v0.11 M5; untyped: one may be freed).
var reserve: Array = []
## How many reinforcements came (v0.11 M5).
var reinforced := 0
## How many reliefs came (v0.11 M5).
var reliefs := 0
## The second of the night the next reinforcement marches (-1 while nothing musters) (v0.11 M5).
var _next_arms := -1.0
## Men who were running in when their target was razed, walking back into the Citadel (v0.11 M5; untyped: one may be freed).
var _returning: Array = []
## Seconds into the night (v0.11 M5).
var _clock := 0.0
## Seconds to the next look (v0.11 M5).
var _tick_in := 0.0


## The night's setup (v0.11 M5): the three targets, kept from the town's teams; at each its night watch set down and kept on duty on
## its face and its squad taken indoors; the reserve inside the Citadel's gate; each horn and the march on the strip.
func _begin() -> void:
	targets.assign(_find_targets())
	spoil_seconds = SPOIL_SECONDS
	citadel_door = _walkable(CITADEL_GATE)
	if crowd.engineers != null:
		crowd.engineers.hands_off.append_array(targets)
	for i in targets.size():
		mustering.append(false)
		razed_at.append(-1.0)
		faces.append(_face(targets[i]))
		var list: Array = []
		armed.append(list)  # first, so _busy() leaves out the men this target has already
		for k in NIGHT_WATCH + SQUAD:
			list.append(_appoint(i, k, k >= NIGHT_WATCH))
	for k in RESERVE:
		var near := _lay_near(citadel_door, 1, _busy())
		if near.is_empty():
			break
		var p := near[0]
		p.profile.role = CitizenProfile.Role.WATCHMAN
		_set_down(p, citadel_door)
		p.go_duty(citadel_door)
		_take_inside(p, null)
		reserve.append(p)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		timeline.add(float(STAGE_AT[i]), "horn_%d" % i, String(HORN_LABELS[i]), _muster.bind(i),
			func() -> bool: return not mustering[i] and not razed(targets[i]))
	timeline.add(MARCH_AT, "march", "The garrison marches", Callable(), func() -> bool: return not all_razed())
	rules.banner.emit("THE ARMOURY")


## The north barracks, the gate barracks and the armoury (v0.11 M5, Decision 136), those the town has; a target a wish has set aside
## gives way to the next named.
func _find_targets() -> Array[Structure]:
	var out: Array[Structure] = []
	for rects: Array in [[TownLayout.TAVERNS[0], TownLayout.TAVERNS[1]], [TownLayout.GATE_TOWERS[1], TownLayout.GATE_TOWERS[0]],
			[TownLayout.BARRACKS]]:
		var s := _built_at(rects)
		if s != null:
			out.append(s)
	return out


## The first standing building whose footprint is one of `rects`, in order, not set aside by a wish (v0.11 M5); null for none.
func _built_at(rects: Array) -> Structure:
	for r: Rect2 in rects:
		for s: Structure in town._built:
			if is_instance_valid(s) and not s.destroyed and s.footprint.position.is_equal_approx(r.position) and not reserved_places.has(s):
				return s
	return null


## Target `s`'s face (v0.11 M5, plan decision 181): a tower's town side (its -y face); else the door the nearest town gate's street
## reaches (The Crown's Bread's rule).
func _face(s: Structure) -> Vector2:
	if s.role == &"tower":
		return _walkable(s.center() - Vector2(0.0, s.footprint.size.y * 0.5 + 0.5))
	var gate := Vector2.INF
	for g: Structure in town.gates:
		if is_instance_valid(g) and (gate == Vector2.INF or g.center().distance_to(s.center()) < gate.distance_to(s.center())):
			gate = g.center()
	var door := _open_door(s, _walkable(gate)) if gate != Vector2.INF else Vector2.INF
	return door if door != Vector2.INF else _front_of(s)


## The `k`th post of target `i` (v0.11 M5): along its face, the night watch POST_GAP apart about its middle, the squad POST_GAP beyond
## them; reinforcements in a second row half POST_GAP out, the same spacing; each kept within reach and apart by _spread().
func _post(i: int, k: int) -> Vector2:
	var face := faces[i]
	var out := face - targets[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	var side := -1.0 if k % 2 == 0 else 1.0
	var wide := 0.5 if (k / 2) % 2 == 0 else 1.5
	var depth := 0.0 if k < NIGHT_WATCH + SQUAD else POST_GAP * 0.5
	return _spread(i, face + out * depth + along * side * POST_GAP * wide)


## A post at or near `want` for target `i` (v0.11 M5, The Crown's Bread's _spread()): walkable, within GUARD_REACH of the target and
## reached on foot from its face, and farther than two Silent Doom radii from every post it has so far, so one strike takes one man.
## The nearest such point on rings of POST_GAP / 2 steps round `want`; with none apart, the nearest within reach; `want` made walkable
## when there is neither.
func _spread(i: int, want: Vector2) -> Vector2:
	var first := _walkable(want)
	var near := Vector2.INF
	for ring in 5:
		var r := POST_GAP * 0.5 * float(ring)
		var n := 1 if ring == 0 else 12
		for k in n:
			var at := first if ring == 0 else _walkable(want + Vector2.from_angle(TAU * float(k) / float(n)) * r)
			if targets[i].distance_to(at) > GUARD_REACH or (crowd._grid != null and (not crowd._grid.walkable(at)
					or (at.distance_to(faces[i]) > 0.1 and crowd._grid.path(faces[i], at).is_empty()))):
				continue
			if near == Vector2.INF:
				near = at
			var clear := true
			for a: Armed in armed[i]:
				clear = clear and a.post.distance_to(at) > 2.0 * SilentDoom.RADIUS
			if clear:
				return at
	return near if near != Vector2.INF else first


## An armed man for target `i` at its `k`th post (v0.11 M5): the free lay citizen nearest it, made a watchman, set down and kept on duty
## there; a squad man goes indoors in the target until its horn.
func _appoint(i: int, k: int, squad: bool) -> Armed:
	var a := Armed.new()
	a.post = _post(i, k)
	a.squad = squad
	var near := _lay_near(a.post, 1, _busy())
	if near.is_empty():
		return a
	var p := near[0]
	p.profile.role = CitizenProfile.Role.WATCHMAN
	a.man = p
	_set_down(p, a.post)
	p.go_duty(a.post)
	if squad:
		_take_inside(p, targets[i])
	return a


## Everyone the director has armed (v0.11 M5), for a new one to leave out.
func _busy() -> Array:
	var out: Array = reserve.duplicate()
	out.append_array(_returning)
	for list: Array in armed:
		for a: Armed in list:
			if a.man != null:
				out.append(a.man)
	return out


## Target `s` can be razed: it musters (v0.11 M5; RazeDirector._spoilable()). Before its horn its fire goes out and its fall waits.
func _spoilable(s: Structure) -> bool:
	var i := targets.find(s)
	return i >= 0 and i < mustering.size() and mustering[i]


## The second of the night target `i` musters at the latest (v0.11 M5): its own time, or CHAIN after the one before is razed if sooner.
func stage_due(i: int) -> float:
	var at := float(STAGE_AT[i]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if i > 0 and razed_at[i - 1] >= 0.0:
		at = minf(at, razed_at[i - 1] + CHAIN)
	return at


## Seconds until target `i` musters at the latest (v0.11 M5); 0 once it does.
func due_in(i: int) -> float:
	return 0.0 if mustering[i] else maxf(stage_due(i) - _clock, 0.0)


## Each target not mustering whose chained time has come musters (v0.11 M5); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, targets.size()):
		if not mustering[i] and not razed(targets[i]) and razed_at[i - 1] >= 0.0 and _clock >= stage_due(i):
			rules.banner.emit(String(HORN_LABELS[i]).to_upper())
			_muster(i)


## Target `i`'s horn (v0.11 M5): it musters, each of its squad comes out at his own post (The Crown's Bread's shift, M4's fix round 1
## ruling: never bunched at one door, where one strike would take them all), on duty there, and the reinforcement clock starts anew.
func _muster(i: int) -> void:
	if mustering[i]:
		return
	mustering[i] = true
	for a: Armed in armed[i]:
		if a.squad and _alive(a.man) and (a.man as Person).inside:
			var p := a.man as Person
			_bring_out(p, a.post)
			_keep_from_flight(p, true)  # Crowd._evacuate() sends one waiting indoors running too, if he was not on duty
			p.go_duty(a.post)
	_next_arms = _clock + arms_every()


## Seconds between reinforcements now (v0.11 M5, plan decision 179): REINFORCE by the clock's minute.
func arms_every() -> float:
	return float(REINFORCE[mini(int(_clock / 60.0), REINFORCE.size() - 1)])


## One step (v0.11 M5): each target sealed while guarded, the Raze type's (the timeline, each target judged), the chain, then every
## frame each target's armed men at their work, and every TICK the hold on them all, the reinforcements and those walking back.
func step(delta: float) -> void:
	_clock += delta
	_guard_seals()
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
	if looking:
		_arms()
		_back_inside(evacuating)


## Each standing target not razed is sealed while an armed man stands guard, and open while none does (v0.11 M5, plan decision 177);
## a fallen one is never left sealed.
func _guard_seals() -> void:
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s):
			continue
		var held := not s.destroyed and not guards(i).is_empty()
		if held and not is_sealed(s):
			seal(s)
		elif not held and is_sealed(s):
			unseal(s)


## Every armed man of a target not razed, the reserve and those walking back are kept out of the town's flight by the one rule (v0.11
## M5, the controller's ruling: MissionDirector._hold_all(), `evacuating` at the first look after the evacuation began). _work() then
## puts each out of doors on duty again, one away recalled at once.
func _keep_held(evacuating: bool) -> void:
	var people: Array = reserve.duplicate()
	people.append_array(_returning)
	for i in targets.size():
		if razed(targets[i]):
			continue
		for a: Armed in armed[i]:
			people.append(a.man)
	_hold_all(people, evacuating)


## Armed man `a` of target `i` stands guard now (v0.11 M5): alive, out of doors, not in OFF_GUARD, within GUARD_REACH of it.
func _on_guard(i: int, a: Armed) -> bool:
	if not _alive(a.man):
		return false
	var p := a.man as Person
	return not p.inside and not p.mind in OFF_GUARD and is_instance_valid(targets[i]) and targets[i].distance_to(p.ground_pos) <= GUARD_REACH


## Target `i`'s armed men on guard now (v0.11 M5). Only reads.
func guards(i: int) -> Array[Person]:
	var out: Array[Person] = []
	if i < 0 or i >= armed.size():
		return out
	for a: Armed in armed[i]:
		if _on_guard(i, a):
			out.append(a.man as Person)
	return out


## Target `i`'s armed men at their work (v0.11 M5). One on guard is held deaf and fearless and set back on his post at each look; one off
## his post walks back RETURN_AFTER after he left, at once when running in or at the first look after the evacuation began
## (`evacuating`); a fallen one is replaced RELIEF_AFTER after he fell, from the reserve -- a squad slot only once its target musters,
## and none for a target already down.
func _work(i: int, delta: float, looking: bool, evacuating: bool) -> void:
	for a: Armed in armed[i]:
		if not _alive(a.man):
			if a.squad and not mustering[i]:
				continue
			a.fallen += delta
			if looking and a.fallen >= RELIEF_AFTER:
				_relieve(i, a)
			continue
		a.fallen = 0.0
		var p := a.man as Person
		if p.inside:
			continue
		if _on_guard(i, a):
			a.away = 0.0
			a.relief = false
			if looking:
				p._shaken_left = maxf(p._shaken_left, ARMED_HOLD)
				p.fearless_left = maxf(p.fearless_left, ARMED_HOLD)
				if p.mind != Person.Mind.DUTY or p.anchor.distance_to(a.post) > 0.3:
					p.go_duty(a.post)
		else:
			a.away += delta
			if looking and (a.relief or evacuating or a.away >= RETURN_AFTER):
				_recall_to(p, a.post, evacuating)


## A relief for fallen armed man `a` of target `i` from the reserve (v0.11 M5; The Crown's Bread's _relieve(): flight-proofed, and
## backed off -- tried again RELIEF_AFTER later -- while its target is down, the reserve is spent or no way leads from the Citadel's gate
## to the post).
func _relieve(i: int, a: Armed) -> void:
	var s := targets[i]
	if not is_instance_valid(s) or s.destroyed or not _reaches(a.post):
		a.fallen = 0.0
		return
	var p := _from_reserve(a.post)
	if p == null:
		a.fallen = 0.0
		return
	a.man = p
	a.fallen = 0.0
	a.away = 0.0
	a.relief = true
	reliefs += 1
	rules.banner.emit("AN ARMED MAN RUNS FROM THE CITADEL")


## A way leads on foot from the Citadel's gate to `post` (v0.11 M5); true with no walk grid.
func _reaches(post: Vector2) -> bool:
	return crowd._grid == null or post.distance_to(citadel_door) <= 0.1 or not crowd._grid.path(citadel_door, post).is_empty()


## The next of the reserve, out of the Citadel's gate and running on duty to `post` (v0.11 M5); null once it is spent.
func _from_reserve(post: Vector2) -> Person:
	while not reserve.is_empty():
		var v: Variant = reserve.pop_front()
		if not _alive(v):
			continue
		var p := v as Person
		if p.inside:
			_bring_out(p, citadel_door)
		_keep_from_flight(p, true)  # out once the town may be running: never one of the flight
		p.go_duty(post)
		return p
	return null


## The first target that musters and is not razed, or -1 (v0.11 M5).
func mustering_now() -> int:
	for i in targets.size():
		if mustering[i] and not razed(targets[i]):
			return i
	return -1


## A reinforcement when its time has come (v0.11 M5, plan decision 179): one man from the reserve to a new post of the first mustering
## target; the clock stops while nothing musters.
func _arms() -> void:
	if _next_arms < 0.0 or _clock < _next_arms:
		return
	var i := mustering_now()
	if i < 0:
		_next_arms = -1.0
		return
	_next_arms = _clock + arms_every()
	var a := Armed.new()
	a.reinforcement = true
	a.post = _post(i, armed[i].size())
	var p := _from_reserve(a.post)
	if p == null:
		return
	a.man = p
	a.relief = true
	armed[i].append(a)
	reinforced += 1


## Men walking back (v0.11 M5): at the Citadel's gate one goes in again, back in the reserve.
func _back_inside(evacuating: bool) -> void:
	for v: Variant in _returning.duplicate():
		if not _alive(v) or (v as Person).inside:
			_returning.erase(v)
			continue
		var p := v as Person
		if p.ground_pos.distance_to(citadel_door) <= 0.6:
			_take_inside(p, null)
			reserve.append(p)
			_returning.erase(v)
		else:
			_recall_to(p, citadel_door, evacuating)


## Razed (v0.11 M5): unsealed for good; the next horn chained and on the strip; its men go home, but one still running in walks back
## into the Citadel.
func _on_razed(s: Structure) -> void:
	var i := targets.find(s)
	unseal(s)
	rules.banner.emit("THE %s IS RAZED" % String(WORDS[i]).to_upper())
	razed_at[i] = _clock
	if timeline != null and i + 1 < targets.size():
		timeline.expect("horn_%d" % (i + 1), stage_due(i + 1))
	for a: Armed in armed[i]:
		if not _alive(a.man):
			continue
		var p := a.man as Person
		if a.relief and not p.inside:
			_returning.append(p)
			p.go_duty(citadel_door)
			continue
		if p.inside:
			_bring_out(p, faces[i])
			_keep_from_flight(p, true)
		_release_man(p)
	if mustering_now() < 0:
		_next_arms = -1.0


## An armed man goes home (v0.11 M5, Spoiled Harvest's _release()): the hold ends; one on duty stood down, one calm sent home.
func _release_man(p: Person) -> void:
	if p.fearless_left <= ARMED_HOLD:
		p.fearless_left = 0.0
	if p.mind == Person.Mind.DUTY:
		crowd.off_duty(p)
	elif p.mind in HarvestDirector.GUARD_MINDS and p.profile != null:
		p.regroup(p.profile.home)


## The current target (v0.11 M5): the first not razed, or -1.
func current() -> int:
	for i in targets.size():
		if not razed(targets[i]):
			return i
	return -1


## The first target not razed and not mustering, or -1 (v0.11 M5).
func upcoming() -> int:
	for i in targets.size():
		if not razed(targets[i]) and not mustering[i]:
			return i
	return -1


## A relief or reinforcement of target `i` running in, or null (v0.11 M5, for the scripted player). Only reads.
func relief_walking(i: int) -> Person:
	for a: Armed in armed[i]:
		if a.relief and _alive(a.man) and not (a.man as Person).inside and not _on_guard(i, a):
			return a.man as Person
	return null


## The HUD's main row while a target musters and the reserve lasts (v0.11 M5, plan decision 182); "" for RazeObjective's own.
func hud_line() -> String:
	if mustering_now() < 0 or reserve.is_empty():
		return ""
	return "Raze the garrison %d / %d, armed men every %d s" % [razed_count(), targets.size(), roundi(arms_every())]


## The map tags, most important first (v0.11 M5, mission spec §2, plan decision 206): each target not razed, pointed at -- not
## mustering, grey, "MUSTERS BY" its chained time or "DOWN, COUNTS AT" it; mustering, gold, GUARDED while one stands guard, orange
## and its seconds left while it burns -- then each armed man: ARMED on guard, a red diamond on one running in, a small red mark on
## one away.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s):
			continue
		var name := String(NAMES[i])
		if not mustering[i]:
			var when := UiTheme.clock(stage_due(i))
			var label := "%s - DOWN, COUNTS AT %s" % [name, when] if s.destroyed else "%s - MUSTERS BY %s" % [name, when]
			out.append(MapTag.place(s.center(), MARK_SEALED, label, s.height, true))
		elif not guards(i).is_empty():
			out.append(MapTag.place(s.center(), MARK_TARGET, "%s - GUARDED" % name, s.height, true))
		elif burning(s):
			var left := ceili(maxf(SPOIL_SECONDS - burned(s), 0.0))
			out.append(MapTag.place(s.center(), MARK_BURNING, "%s - BURNING %d" % [name, left], s.height, true))
		else:
			out.append(MapTag.place(s.center(), MARK_TARGET, name, s.height, true))
	for i in targets.size():
		if razed(targets[i]):
			continue
		for a: Armed in armed[i]:
			if not _alive(a.man) or (a.man as Person).inside:
				continue
			var p := a.man as Person
			if _on_guard(i, a):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED, "ARMED"))
			elif a.relief:
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5), for the current target: not mustering, "not_yet" when down or WORK_AHEAD or less from its horn, else
## ""; mustering, "guarded" while one stands guard, else "stone" for a target fire cannot take, else "open".
func hint_phase() -> String:
	var i := current()
	if i < 0:
		return ""
	var s := targets[i]
	if not mustering[i]:
		return "not_yet" if (is_instance_valid(s) and s.destroyed) or due_in(i) <= WORK_AHEAD else ""
	if not guards(i).is_empty():
		return "guarded"
	return "stone" if is_instance_valid(s) and not s.kind in FireManager.BURNABLE else "open"


## The tour (v0.11 M5, mission spec §2): the north barracks, the gate barracks, the armoury.
func tour() -> Array:
	var words := ["The north barracks. The muster horn calls it at %s.", "The gate barracks, by %s. It is stone: blows, not fire.",
		"The armoury, last. It arms the garrison, faster each minute."]
	var out := []
	for i in targets.size():
		var line := String(words[i]) % UiTheme.clock(float(STAGE_AT[i])) if i < 2 else String(words[i])
		out.append([faces[i], line])
	return out


## What the results show (v0.11 M5): the targets razed, the reinforcements and the reliefs.
func report() -> Dictionary:
	return {"razed": razed_count(), "reinforced": reinforced, "reliefs": reliefs}


## Lets go of the town's engineers' list, then the Raze type's (every seal) (v0.11 M5).
func teardown() -> void:
	if is_instance_valid(crowd) and crowd.engineers != null:
		for s in targets:
			if is_instance_valid(s):
				crowd.engineers.hands_off.erase(s)
	super()
