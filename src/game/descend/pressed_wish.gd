class_name PressedWish
extends RescueWish
## "Free the pressed man" (v0.11 M3, mission spec §5, Rescue; Decision 32 by its fallback: a subclass, RescueWish untouched): a timed
## wish. The wisher's son -- a lay citizen of the household standing at least MIN_FROM from the barracks' door, with at most
## MAX_ROUTE of street to it -- is to be pressed into the army. It waits until engaged (his tag or a press-ganger's clicked, or a
## power cast within ENGAGE_REACH of any of them); then the two free soldiers nearest him (RescueWish.soldier and `mate`) walk to him
## and march him to the barracks' door. Kill or turn (RescueWish.TURNED) both within SECONDS, the son alive, and it is granted. His
## death, the door reached, or the time run out fails it. A town order taking a man off the errand sends him back on it. Engagement
## is judged first, as Save my child's: a man felled by the god's own cast before it was engaged engages it; felled any other way,
## it fails.

## How far from the barracks' door the son stands at least, and how much street lies between at most (v0.11 M3, Decision 32).
const MIN_FROM := 15.0
const MAX_ROUTE := 40.0
## How near the barracks' door counts as there (v0.11 M3).
const DOOR_REACH := 1.0

## The second press-ganger (v0.11 M3); the first is RescueWish.soldier, the son RescueWish.child, the barracks' door RescueWish._gate.
var mate: Person
## The two men's instance ids, taken while both stand (v0.11 M3): a freed body has none to ask for.
var _ids: Array[int] = []
## Instance id -> true once that man has been on his errand (v0.11 M3): only then does leaving it turn him.
var _on_errand := {}
## The damage kind that felled each man before engagement, by his place (0 the first, 1 the second) (v0.11 M3).
var _fell := {}


## The barracks' door (v0.11 M3): the middle of TownLayout.BARRACKS's front, in its yard, on walkable ground.
static func barracks_door(crowd: Crowd) -> Vector2:
	var r := TownLayout.BARRACKS
	var at := Vector2(r.get_center().x, r.end.y + 0.5)
	var snap := crowd._grid.nearest_walkable(at) if crowd._grid != null else at
	return snap if snap != Vector2.INF else at


## A wisher with a son who fits, and the two free soldiers nearest the son; false when the town cannot give them (v0.11 M3).
## Households are tried from a random start, as Stop the bailiff tries its homes.
func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var door := barracks_door(crowd)
	var homes := Wish.lay(crowd, taken)
	var parents: Array[Person] = []
	for p in homes:
		if p.profile.family >= 0 and RescueWish._child_of(p, homes) != null:
			parents.append(p)
	if parents.is_empty():
		return false
	var start := rng.randi_range(0, parents.size() - 1)
	for k in parents.size():
		var parent := parents[(start + k) % parents.size()]
		var son := _son_of(crowd, parent, homes, door)
		if son == null:
			continue
		var first := RescueWish._soldier_near(crowd, son.ground_pos, taken)
		if first == null:
			return false
		var others := taken.duplicate()
		others.append(first)
		var second := RescueWish._soldier_near(crowd, son.ground_pos, others)
		if second == null:
			return false
		wisher = parent
		child = son
		soldier = first
		mate = second
		_ids.assign([first.get_instance_id(), second.get_instance_id()])
		_gate = door
		taken.append_array([wisher, child, soldier, mate])
		crowd._field.enemy_killed.connect(_on_killed)
		return true
	return false


## The first of `homes` in `parent`'s household but him, standing at least MIN_FROM from `door` with at most MAX_ROUTE of street to
## it -- measured where he stands at the draw (v0.11 M3, decision 56); null for none.
static func _son_of(crowd: Crowd, parent: Person, homes: Array[Person], door: Vector2) -> Person:
	for q in homes:
		if q == parent or q.profile.family != parent.profile.family or q.ground_pos.distance_to(door) < MIN_FROM:
			continue
		if crowd._grid == null or BailiffWish.route_length(crowd._grid, q.ground_pos, door) <= MAX_ROUTE:
			return q
	return null


## The wisher, the son and both men, while their bodies are there (v0.11 M3).
func people() -> Array[Person]:
	var out := super()
	var v: Variant = mate
	if is_instance_valid(v):
		out.append(v as Person)
	return out


## The press-gang still standing (v0.11 M3).
func _men() -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in [soldier, mate]:
		if MissionDirector._alive(v):
			out.append(v as Person)
	return out


## `p` has been turned by the god (v0.11 M3): on his errand once, and now in one of RescueWish.TURNED.
func _turned_man(p: Person) -> bool:
	return _on_errand.has(p.get_instance_id()) and TURNED.has(p.mind)


## Each man not turned is sent on the errand: to the son, or, once one has him, to the barracks' door (v0.11 M3).
func _send_men() -> void:
	for p in _men():
		if _turned_man(p):
			continue
		p.go_duty(_gate if dragging else child.ground_pos)
		if p.mind == Person.Mind.DUTY:
			_on_errand[p.get_instance_id()] = true


## Engaged (spec §5.2): both men set out for the son and the clock starts. Once only, while the son and a man stand (v0.11 M3).
func engage() -> bool:
	if not waiting() or not MissionDirector._alive(child) or _men().is_empty():
		return false
	engaged = true
	seconds_left = SECONDS
	_retarget_in = 0.0
	_send_men()
	return true


## A power cast within ENGAGE_REACH of the son or either man engages it (v0.11 M3).
func on_cast(_key: String, at: Vector2) -> void:
	if engaged:
		return
	for v: Variant in [child, soldier, mate]:
		if MissionDirector._alive(v) and (v as Person).ground_pos.distance_to(at) <= ENGAGE_REACH:
			engage()
			return


## Notes how a man fell before the wish was engaged (v0.11 M3); judged in _act(), where the rules can say whose it was.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if engaged:
		return
	var k := _ids.find(e.get_instance_id())
	if k >= 0 and not _fell.has(k):
		_fell[k] = kind


## The clock runs; every RETARGET each man not turned is kept on the errand -- a town order undone -- to the son, then, once one is
## within TAKE_REACH of him, to the barracks' door, the son following the first man on duty (v0.11 M3).
func step(_rules: Rules, delta: float) -> void:
	if not engaged or status != Status.PENDING:
		return
	seconds_left = maxf(seconds_left - delta, 0.0)
	_retarget_in -= delta
	if _retarget_in > 0.0 or not MissionDirector._alive(child):
		return
	_retarget_in = RETARGET
	var lead: Person = null
	for p in _men():
		if _turned_man(p):
			continue
		if p.mind == Person.Mind.DUTY:
			if not dragging and p.ground_pos.distance_to(child.ground_pos) <= TAKE_REACH:
				dragging = true
			if lead == null:
				lead = p
	_send_men()
	if dragging and lead != null:
		child.go_duty(lead.ground_pos)


## Where the act stands (v0.11 M3): the son dead fails it. Unengaged, a man felled by the god's own cast engages it (any other end
## of him fails it). Both men dead or turned grants it; the son at the barracks' door, or the time run out, fails it.
func _act(rules: Rules) -> Status:
	if not MissionDirector._alive(child):
		return Status.FAILED
	if not engaged:
		var felled := false
		for k in 2:
			var man: Variant = soldier if k == 0 else mate
			if MissionDirector._alive(man):
				continue
			var kind: StringName = _fell.get(k, &"")
			if kind == &"" or rules.credited_key(kind) == "":
				return Status.FAILED
			felled = true
		if not felled:
			return Status.PENDING
		engaged = true
		seconds_left = SECONDS
		_send_men()
	var standing := 0
	for p in _men():
		standing += 0 if _turned_man(p) else 1
	if standing == 0:
		return Status.DONE
	if dragging and child.ground_pos.distance_to(_gate) <= DOOR_REACH:
		return Status.FAILED
	return Status.FAILED if seconds_left <= 0.0 else Status.PENDING


## Once ended, the second man is let go too (v0.11 M3; RescueWish lets the son and the first go).
func check(rules: Rules) -> Status:
	var s := super(rules)
	if s != Status.PENDING and MissionDirector._alive(mate) and mate.mind == Person.Mind.DUTY:
		_crowd.off_duty(mate)
	return s


## PRESSED MAN on the son, always pointed at from the edge -- he is the one to find while the wish waits -- and PRESS-GANG on each
## man, pointed at once engaged and marching (v0.11 M3).
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if MissionDirector._alive(child) and not child.inside:
		out.append(MapTag.person(child.ground_pos, COLOR, "PRESSED MAN", true))
	for p in _men():
		if not p.inside:
			out.append(MapTag.person(p.ground_pos, COLOR, "PRESS-GANG", engaged))
	return out
