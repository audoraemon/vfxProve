class_name GravecallFx
extends FxTimeline
## Gravecall (Death, Tier II; spec 5.2): no body is needed. The first click calls SPIRITS wraiths up out of the ground
## (DeathParts.haunt()), the second (extra["to"]) sends them: they drift through walls, slightly apart, to that spot and haunt a
## circle of HAUNT_R there for HAUNT seconds -- everyone within it flees, afresh each second. A soldier a spirit passes through
## (within PASS_R) is frozen for FREEZE seconds, once per soldier per spirit. At the end every spirit is recalled and thins away.
## It kills nobody (Rules.POWER_KINDS: []). Loud (PowerBook.REACH): the danger counts from T_RISE, when the dead rise.

## The ground breathes, and the spirits stand at T_RISE.
const T_RISE := 0.8
const SPIRITS := 3
## The circle they haunt, how long they haunt it, how long a soldier they pass through stays frozen, how close counts as through.
const HAUNT_R := DeathParts.SPIRIT_FRIGHT_R
const HAUNT := 20.0
const FREEZE := 3.0
const PASS_R := 0.5
## How far apart the three float (at the rise and at the haunt), the longest they take to get there (a farther haunt is drifted
## to faster), how near their spot counts as there, and how often the haunt frightens (a spirit's own rhythm).
const SPREAD := 0.6
const TRAVEL_MAX := 12.0
const ARRIVED := 0.3
const FRIGHT_EVERY := Visitors.FRIGHT_EVERY
## At the end they thin away over FADE.
const FADE := 0.6
## The cold glow under each wraith.
const GLOW := 0.35
## Cold grave light and pale fire (Death's palette).
const PALE := [Color("eaf4ff"), Color("c8f0dc"), Color(0.5, 0.9, 0.7, 0.5), Color(0.2, 0.4, 0.35, 0.0)]
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]

var visitors: Visitors
var spirits: Array[Animal] = []
## Whether they have all reached the spot and are haunting it now.
var haunting := false

var _to := Vector2.ZERO
var _slots: Array[Vector2] = []
var _started := -1.0
var _fright_in := 0.0
var _passed := {}  # spirit -> {soldier: true}
var _ended := false
## A cold glow under each wraith while it haunts (staged only), by wraith.
var _glows := {}  # Animal -> QuadFx


func _build() -> void:
	_to = extra.get("to", origin)
	duration = T_RISE + TRAVEL_MAX + HAUNT + FADE + 2.0  # a safe ceiling: _end_life() sets the real end
	busy = T_RISE
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, grid, parent)
	for k in SPIRITS:
		var ang := TAU * float(k) / float(SPIRITS) + 0.5
		_slots.append(_to + Vector2.from_angle(ang) * SPREAD)
	at(T_RISE, _rise)
	ctx.play(&"gravecall_rise", origin, 0.0)
	if not DominionParts.staged(self):
		return
	var light := FxParts.ground_light(self, origin, 1.6, DeathParts.GRAVE_GREEN, 0.0)
	light.tween_param("intensity", 0.0, 0.7, T_RISE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	light.tween_param("intensity", 0.7, 0.0, 1.0, T_RISE)
	FxParts.smoke(self, Iso.ground_to_screen(origin), 12.0, 20.0, T_RISE, Vector2(8, 18), Vector2(2, 4), Vector2(0.5, 1.0), Color(DeathParts.GRAVE_GREEN, 0.2), DUST)


## The spirits stand, a little apart, and set off for the second click.
func _rise() -> void:
	var trip := origin.distance_to(_to)
	var base := DeathParts.SPIRIT_SPEED * Animal.DOG_SPEED * Animal.RUN
	var mul := maxf(1.0, trip / (base * TRAVEL_MAX))
	for k in SPIRITS:
		var ang := TAU * float(k) / float(SPIRITS) + 0.5
		var a := DeathParts.haunt(visitors, origin + Vector2.from_angle(ang) * SPREAD * 0.5)
		a.speed_mul *= mul
		spirits.append(a)
		_passed[a] = {}
		if DominionParts.staged(self):
			_glows[a] = FxParts.ground_light(self, a.ground_pos, 1.0, DeathParts.GRAVE_GREEN, GLOW)
	if DominionParts.staged(self):
		var sp := Iso.ground_to_screen(origin)
		var burst := FxParts.bloom(self, sp + Vector2(0, -10), 26.0, DeathParts.PALE_FIRE, 1.0, 1.0)
		burst.tween_param("intensity", 1.0, 0.0, 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		burst.life = 0.75
		FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -8), 12, PALE, Vector2(20, 80), Vector2(40, 120))


func _fx_process(delta: float) -> void:
	if visitors == null:
		return
	visitors.step(delta)
	if spirits.is_empty() or _ended:
		return
	var all_there := true
	for k in spirits.size():
		var a := spirits[k]
		if not is_instance_valid(a):
			continue
		if a.ground_pos.distance_to(_slots[k]) > ARRIVED:
			a.walk_to(_slots[k], delta, null)  # straight through whatever stands between
			all_there = false
		_freeze_soldiers(a)
		if _glows.has(a):
			(_glows[a] as QuadFx).position = a.ground_pos
	if all_there and not haunting:
		haunting = true
		_started = t
	_fright_in -= delta
	if _fright_in <= 0.0:
		_fright_in = FRIGHT_EVERY
		_haunt_fright()
	if haunting and t - _started >= HAUNT:
		_end_life()


## The people near the spirits flee: around the spot once they are there, around their middle on the way.
func _haunt_fright() -> void:
	if ctx.crowd == null:
		return
	var mid := Vector2.ZERO
	var n := 0
	for a in spirits:
		if is_instance_valid(a):
			mid += a.ground_pos
			n += 1
	if n == 0:
		return
	ctx.crowd.fright(_to if haunting else mid / float(n), HAUNT_R, 0.5, 2.0, 3.0, 3.0, &"beast")


## A soldier within PASS_R of spirit `a` is rooted for FREEZE, once per soldier per spirit.
func _freeze_soldiers(a: Animal) -> void:
	if ctx.crowd == null:
		return
	var seen: Dictionary = _passed[a]
	for s: Person in ctx.crowd.soldiers:
		if not is_instance_valid(s) or not s.is_alive() or seen.has(s):
			continue
		if s.ground_pos.distance_to(a.ground_pos) <= PASS_R:
			seen[s] = true
			s.stun(FREEZE)


## The 20 s are up: every spirit is recalled and thins away.
func _end_life() -> void:
	if _ended:
		return
	_ended = true
	haunting = false
	if visitors == null:
		return
	for q: QuadFx in _glows.values():
		q.tween_param("intensity", GLOW, 0.0, FADE)
	if DominionParts.staged(self):
		for a in visitors.living():
			FxParts.smoke(self, Iso.ground_to_screen(a.ground_pos), 6.0, 24.0, FADE * 0.5, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 1.0), Color(0, 0, 0, 0), PALE)
	visitors.recall(FADE)
	duration = t + FADE + 0.1


func _finish() -> void:
	if visitors != null:
		visitors.clear()
	super()


## Freed without _finish (Battlefield.clear_effects() on a restart): the spirits are gone all the same, the pack only queued for
## freeing (its parents may be mid-teardown). After _finish there is nothing left to do here.
func _exit_tree() -> void:
	if visitors != null:
		visitors.clear(true)
	spirits.clear()
	super()
