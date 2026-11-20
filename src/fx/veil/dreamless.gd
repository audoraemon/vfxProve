class_name DreamlessFx
extends FxTimeline
## Dreamless (Veil, Tier 3): the nearest MOST within REACH (VeilRules: 1 within 1.0 light / 4 within 2.0 dark) are fixed at the click and,
## by T_SIT, sit down against the nearest wall as if to rest -- deep asleep (Person.sleep(.., true)), statuses[&"dreamless"] on them.
## For the next REST seconds the town sees only people resting: no witness reacts, no alarm. At T_SIT + REST each still-sleeping one
## dies with kind &"dreamless" (a body, found like any other dead; credited to the cast by Rules.POWER_KINDS). Anyone already asleep
## at T_SIT (Slumber, Curfew, a night sleeper) or a shadow's owner is taken at once, kind &"dreamt": no body, never found. Quiet: no
## danger, no fright, no alarm, no cue. Its dusk is laid at the cast (VeilParts.land(); VB0).
## Teardown: the status is lifted and the sit's sleep ends in _finish() AND in _exit_tree(); nobody dies after an early end.

const REST := 20.0
const T_SIT := 0.8
## How far someone walks to the nearest wall to sit against it.
const WALL_REACH := 2.0
## How far off the wall the sitter's back is.
const WALL_GAP := 0.3
const BREATH := [Color("3a2a55"), Color("1a1030"), Color("0b0716"), Color(0.03, 0.02, 0.06, 0.5)]

var _victims: Array[Person] = []
var _sat: Array[Person] = []
var _undone := false
## How many were taken at once (&"dreamt") and how many were set to rest.
var taken := 0
var resting := 0


## Who Dreamless would take at `at`: the nearest `most` living people in the open within `r`, by distance and then instance id (no luck).
static func victims_at(field: EnemyField, at: Vector2, r: float, most: int) -> Array[Person]:
	var out := DominionParts.near(field, at, r)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		if is_equal_approx(da, db):
			return a.get_instance_id() < b.get_instance_id()
		return da < db)
	return out.slice(0, most)


func _build() -> void:
	var r := VeilParts.size(self, "dreamless", "REACH")
	var most := int(VeilParts.size(self, "dreamless", "MOST"))
	duration = T_SIT + REST + 1.0
	busy = T_SIT
	VeilParts.land(self, origin, r)
	ctx.play(&"v_dreamless", origin)
	if ctx.field != null:
		_victims = victims_at(ctx.field, origin, r, most)
	for p in _victims:
		var spot := _wall_spot(p)
		if spot != Vector2.INF:
			p.set_goal(spot)
	at(T_SIT, _sit)
	at(T_SIT + REST, _found)


## Where `p` sits: against the nearest standing wall within WALL_REACH, else where he stands (Vector2.INF: stay).
func _wall_spot(p: Person) -> Vector2:
	if ctx.env == null:
		return Vector2.INF
	var best: Structure = null
	var best_d := INF
	for s in ctx.env.near(p.ground_pos, WALL_REACH):
		if s.destroyed or s.walkable:
			continue
		var d := s.distance_to(p.ground_pos)
		if d < best_d or (is_equal_approx(d, best_d) and s.get_instance_id() < best.get_instance_id()):
			best_d = d
			best = s
	if best == null or best_d > WALL_REACH:
		return Vector2.INF
	var edge := p.ground_pos.clamp(best.footprint.position, best.footprint.end)
	var out := p.ground_pos - edge
	if out.length() < 0.001:
		return Vector2.INF  # standing in the footprint's box: sit here
	var spot := edge + out.normalized() * WALL_GAP
	if ctx.env.blocked(spot, 0.0) or spot.distance_to(p.ground_pos) > WALL_REACH:
		return Vector2.INF
	return spot


func _sit() -> void:
	for p in _victims:
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue  # died, boarded or went in since the cast
		if p.is_asleep() or p.is_shadow():
			if ctx.crowd != null and ctx.crowd.take(p, &"dreamt"):
				taken += 1
			continue
		var spot := _wall_spot(p)
		if spot != Vector2.INF:
			p.ground_pos = spot  # the last steps to the wall, settled
		if p.sleep(REST + 5.0, true):
			p.statuses[&"dreamless"] = 1.0
			_sat.append(p)
			resting += 1
			_breath(p)


## A sitter who is awake again (a hurt wakes a deep sleeper) is no longer resting: his status goes and he leaves the sitters, so a later
## deep sleep (a dark Slumber) is a plain sleep and the find does not kill him (VB1).
func _fx_process(_delta: float) -> void:
	if _sat.is_empty() or _undone:
		return
	var i := _sat.size() - 1
	while i >= 0:
		var p := _sat[i]
		if not is_instance_valid(p) or not p.is_alive() or not p.is_asleep():
			if is_instance_valid(p):
				p.statuses.erase(&"dreamless")
			_sat.remove_at(i)
		i -= 1


func _found() -> void:
	var dying: Array[Person] = []
	for p in _sat:
		if is_instance_valid(p) and p.is_alive() and p.statuses.has(&"dreamless") and p.is_deep_asleep():
			dying.append(p)
	for p in dying:
		p.statuses.erase(&"dreamless")  # the status ends with the rest; the kill is the god's
		if p.is_alive():
			ctx.field.kill(p, &"dreamless")
	_undo()


## One dark breath leaving the sitter, nothing more.
func _breath(p: Person) -> void:
	if not DominionParts.staged(self):
		return
	var m := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(p.ground_pos) + Vector2(0, -10), PixelParticles.Shape.PUFF, BREATH)
	m.gravity = -14.0
	m.drag = 1.6
	m.burst(5, {"radius": 2.0, "speed": Vector2(2, 8), "alt": Vector2(0, 4), "alt_speed": Vector2(4, 10),
		"life": Vector2(0.7, 1.1), "size": Vector2(2, 3), "size_end_mul": 1.8})


## Lifts the status and ends the rest of everyone still resting (whoever the effect set down; a hurt may have woken them already).
func _undo() -> void:
	if _undone:
		return
	_undone = true
	for p in _sat:
		if not is_instance_valid(p):
			continue
		p.statuses.erase(&"dreamless")
		if p.is_alive() and p.is_asleep():
			p.wake()
	_sat.clear()


func _finish() -> void:
	_undo()
	super._finish()


func _exit_tree() -> void:
	_undo()
	super._exit_tree()
