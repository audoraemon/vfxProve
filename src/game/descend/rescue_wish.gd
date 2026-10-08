class_name RescueWish
extends Wish
## "Save my child" (v0.11 M1, spec §5.3, Rescue): a timed wish. It waits until the player engages it -- the child's or the
## soldier's tag clicked, or a power cast within ENGAGE_REACH of either -- then a soldier walks to the child and drags them
## toward the Citadel's gate. Stop him (dead) or turn him (frightened, fleeing, confused, whispered or compelled: the god's
## own effects) within SECONDS, the child alive, and it is granted. A town order (the rally ring, a post) is not the god's
## doing: it sends him back on his errand and the wish stays pending. The child dying, the gate reached, or the time run
## out fails it. Unengaged, it waits as long as the night lasts. Engagement is judged first: the soldier felled by the
## god's own cast before it was engaged engages it and grants it; felled any other way before, it fails with no reward. The
## child is a lay citizen of the wisher's household (CitizenProfile.family: the town has no ages).

## How long the soldier has to reach the gate once engaged.
const SECONDS := 45.0
## How near a cast must land to the child or the soldier to engage the wish.
const ENGAGE_REACH := 2.0
## The Citadel's gate the child is dragged to (snapped to walkable ground), and how near counts as there.
const GATE := Vector2(-10.5, -7.6)
const GATE_REACH := 1.0
## The minds that are the god's own doing (v0.11 M1): a soldier in one of them has been turned. Every other mind off his
## duty is the town's order (RALLY, POST, HOLD, ...), which the wish answers by sending him back on his errand.
const TURNED := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.CONFUSED, Person.Mind.WHISPERED, Person.Mind.COMPELLED]
## How near the soldier must come to take the child, and how often the pair are re-aimed.
const TAKE_REACH := 0.9
const RETARGET := 0.5

## The wisher's child, and the soldier sent for them.
var child: Person
var soldier: Person
## The player has engaged it: the soldier is set out and the clock runs.
var engaged := false
## The soldier has the child and walks them to the gate.
var dragging := false
## The clock, from SECONDS once engaged.
var seconds_left := SECONDS
var _gate := GATE
var _retarget_in := 0.0
var _ended := false
## The soldier has been on his errand (his mind was DUTY): only then does leaving it turn him.
var _started := false
## The damage kind that felled the soldier before the wish was engaged, or &"" for none yet.
var _soldier_fell: StringName = &""


func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var homes := Wish.lay(crowd, taken)
	var parents: Array[Person] = []
	for p in homes:
		if p.profile.family >= 0 and _child_of(p, homes) != null:
			parents.append(p)
	if parents.is_empty():
		return false
	var parent := parents[rng.randi_range(0, parents.size() - 1)]
	var kid := _child_of(parent, homes)
	var guard := _soldier_near(crowd, kid.ground_pos, taken)
	if guard == null:
		return false
	wisher = parent
	child = kid
	soldier = guard
	taken.append_array([wisher, child, soldier])
	var snap := crowd._grid.nearest_walkable(GATE) if crowd._grid != null else GATE
	_gate = snap if snap != Vector2.INF else GATE
	crowd._field.enemy_killed.connect(_on_killed)
	return true


## The first of `homes` but `p` in `p`'s household, or null.
static func _child_of(p: Person, homes: Array[Person]) -> Person:
	for q in homes:
		if q != p and q.profile.family == p.profile.family:
			return q
	return null


## The free soldier nearest `at`: alive, out of doors, of no corps, not in `taken`; null for none.
static func _soldier_near(crowd: Crowd, at: Vector2, taken: Array) -> Person:
	var best: Person = null
	for s in crowd.soldiers:
		if MissionDirector._alive(s) and not s.inside and s.corps == Person.Corps.NONE and not taken.has(s) \
				and (best == null or s.ground_pos.distance_to(at) < best.ground_pos.distance_to(at)):
			best = s
	return best


func people() -> Array[Person]:
	var out := super()
	for p: Variant in [child, soldier]:
		if p != null and is_instance_valid(p):
			out.append(p)
	return out


func timed() -> bool:
	return true


func waiting() -> bool:
	return not engaged and status == Status.PENDING


## Engaged (spec §5.2): the soldier sets out for the child and the clock starts. Once only, while both live.
func engage() -> bool:
	if not waiting() or not MissionDirector._alive(soldier) or not MissionDirector._alive(child):
		return false
	engaged = true
	seconds_left = SECONDS
	_retarget_in = 0.0
	soldier.go_duty(child.ground_pos)
	_started = soldier.mind == Person.Mind.DUTY
	return true


func on_cast(_key: String, at: Vector2) -> void:
	if engaged:
		return
	for p: Variant in [child, soldier]:
		if MissionDirector._alive(p) and (p as Person).ground_pos.distance_to(at) <= ENGAGE_REACH:
			engage()
			return


## Notes how the soldier fell before the wish was engaged; judged in _act(), where the rules can say whose it was.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	if e == soldier and not engaged and _soldier_fell == &"":
		_soldier_fell = kind


## The clock runs; every RETARGET the soldier is re-aimed at the child, then, once he has them, at the gate, the child
## following him. A soldier who could not set out (held, fleeing) is sent again.
func step(_rules: Rules, delta: float) -> void:
	if not engaged or status != Status.PENDING:
		return
	seconds_left = maxf(seconds_left - delta, 0.0)
	_retarget_in -= delta
	if _retarget_in > 0.0 or not MissionDirector._alive(soldier) or not MissionDirector._alive(child):
		return
	if not _started:
		_retarget_in = RETARGET
		soldier.go_duty(child.ground_pos)
		_started = soldier.mind == Person.Mind.DUTY
		return
	_retarget_in = RETARGET
	if soldier.mind != Person.Mind.DUTY:
		# The town's order took him off the errand (turned by the god, he is left be): back to it, toward the child or the gate.
		if not _turned():
			soldier.go_duty(_gate if dragging else child.ground_pos)
		return
	if not dragging and soldier.ground_pos.distance_to(child.ground_pos) <= TAKE_REACH:
		dragging = true
	if dragging:
		soldier.go_duty(_gate)
		child.go_duty(soldier.ground_pos)
	else:
		soldier.go_duty(child.ground_pos)


func _act(rules: Rules) -> Status:
	if not MissionDirector._alive(child):
		return Status.FAILED
	if not engaged and not MissionDirector._alive(soldier):
		# Engagement first: the god's own cast on him engages the wish and grants it; any other end of him fails it.
		if _soldier_fell == &"" or rules.credited_key(_soldier_fell) == "":
			return Status.FAILED
		engaged = true
	if not MissionDirector._alive(soldier):
		return Status.DONE
	if not engaged:
		return Status.PENDING
	if _started and _turned():
		return Status.DONE
	if dragging and soldier.ground_pos.distance_to(_gate) <= GATE_REACH:
		return Status.FAILED
	return Status.FAILED if seconds_left <= 0.0 else Status.PENDING


## Whether the soldier has been turned by the god's own effect (v0.11 M1): his mind is one of TURNED.
func _turned() -> bool:
	return TURNED.has(soldier.mind)


## Once ended, whoever is still on its errand is let go (Crowd.off_duty()): the child home, the soldier to his post.
func check(rules: Rules) -> Status:
	var s := super(rules)
	if s != Status.PENDING and not _ended:
		_ended = true
		for p: Variant in [child, soldier]:
			if MissionDirector._alive(p) and (p as Person).mind == Person.Mind.DUTY:
				_crowd.off_duty(p)
	return s


func hud_text(_rules: Rules) -> String:
	var clock := " %s" % UiTheme.clock(seconds_left) if engaged and status == Status.PENDING else ""
	return "%s (+%d)%s" % [def.text, reward, clock]


func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if MissionDirector._alive(child) and not child.inside:
		out.append(MapTag.person(child.ground_pos, COLOR, "THE CHILD", engaged))
	if MissionDirector._alive(soldier) and not soldier.inside:
		out.append(MapTag.person(soldier.ground_pos, COLOR, "SOLDIER", engaged))
	return out


func release() -> void:
	if is_instance_valid(_crowd) and _crowd._field != null and _crowd._field.enemy_killed.is_connected(_on_killed):
		_crowd._field.enemy_killed.disconnect(_on_killed)
