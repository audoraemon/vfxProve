class_name MindWhisperFx
extends FxTimeline
## Mind Whisper (v0.08, Dominion): one person -- the citizen pressed on -- drops what they are doing, walks to where the
## player released, lingers LINGER seconds and resumes (Person.whisper()). Quiet: no threat, no alarm. A soft gold
## ring marks the spot while they are on their way and lingering; the glyph over them is the person's own.
##
## The order wheel (god/whisper-wheel): the cast may carry an `order`. None, or "walk", is the whisper above, unchanged.
##   "attack" (+ "foe")      the whispered one goes for that person alone for ATTACK_SECS (Person.whisper_fight()), then comes to as a
##                           whisper wears off, and shakes it off for Person.SHAKE_OFF.
##   "burn"   (+ "building") they walk to the building's edge (a whisper to it), stay BURN_SECS, then light it at Ember's START_LEVEL
##                           (FireManager.ignite()); a building gone or no longer burnable by then, or a town with no fires, is not lit.
## Both stay quiet: the fire itself alarms as fires do.

## How near the press must be to a citizen.
const PICK_R := 0.6
## How far from them the spot may be.
const REACH := 10.0
## How long they linger at the spot.
const LINGER := 8.0
## The ring at the spot: a soft gold, bright enough to read over lit paving (it is the player's only sign of where
## the person goes), and its radius (ground units).
const COL_RING := Color(1.0, 0.88, 0.45, 0.9)
const RING_R := 0.5
## A faint halo ring around it, breathing against the ring's own gentle pulse.
const COL_HALO := Color(1.0, 0.86, 0.5, 0.45)
const HALO_R := 0.85
## The pulse: how fast (radians a second) and how deep.
const PULSE_RATE := 3.0
const PULSE_DEPTH := 0.25
## The orders' reach: how far from the whispered one the foe may stand and the building may be (Rules and Targeting check both),
## how long the attack lasts, how long they stay at the building before it is lit, and how long past that they linger there
## (so the whisper is still on them when the match is struck). The civil blow is Divine Schism's.
const ATTACK_R := 6.0
const BURN_R := 6.0
const ATTACK_SECS := 10.0
const BURN_SECS := 3.0
const BURN_AFTER := 0.5
const CIVIL_BLOW := 0.25
## How near a click must be to a building to pick it.
const BUILDING_PICK_R := 0.6
## The ring is drawn for as long as this, at most: a walk of REACH along the town's paths at a stroll, then LINGER.
const MAX_SHOW := 40.0

var _target: Person
var _to := Vector2.INF
var _ring: QuadFx
var _halo: QuadFx
## The order ("", "attack" or "burn") and what it is set on.
var _order := ""
var _foe: Person
var _building: Structure
## Burn: when (the effect's own clock) they got to the building, or -1 while on the way; whether it has been lit.
var _arrived := -1.0
var _lit := false


## The person (v0.11.1: a soldier too) a press at `at` whispers to: the nearest living one out in the open within PICK_R, or null. One still
## shaking the last whisper off (Person.shaken(), v0.08.1) is picked all the same, so the refusal can name why.
static func pick(field: EnemyField, at: Vector2) -> Person:
	var best: Person = null
	for e in field.in_radius(at, PICK_R):
		var p := e as Person
		if p == null or p.resists_mind() or p.inside or not p.is_alive():
			continue
		if best == null or p.ground_pos.distance_squared_to(at) < best.ground_pos.distance_squared_to(at):
			best = p
	return best


## Where a release at `to` sends someone standing at `from`: at most REACH away, on walkable ground. A release on
## something solid snaps to the nearest free ground, or -- when that lies past REACH -- to the last free ground
## short of it on the way there.
static func clamp_to(grid: WalkGrid, from: Vector2, to: Vector2) -> Vector2:
	var g := from + (to - from).limit_length(REACH)
	if grid == null or grid.walkable(g):
		return g
	var free := grid.nearest_walkable(g, 6)
	if free != Vector2.INF and free.distance_to(from) <= REACH:
		return free
	var span := g - from
	var steps := int(span.length() / (WalkGrid.CELL * 0.5))
	for i in range(steps, 0, -1):
		var back := from + span * (float(i) / float(steps))
		if grid.walkable(back):
			return back
	return from


## Whom a click at `at` would set the whispered one on: the nearest living person out in the open within PICK_R, or null. The
## whispered one may be the answer (foe_ok() refuses it).
static func foe_at(field: EnemyField, at: Vector2) -> Person:
	return pick(field, at)


## Whether `foe` is a fair target for `who`'s attack order: another living person out in the open within ATTACK_R.
static func foe_ok(who: Person, foe: Variant) -> bool:
	if not is_instance_valid(who) or not is_instance_valid(foe) or not foe is Person or foe == who:
		return false
	var f := foe as Person
	return f.is_alive() and not f.inside and f.visible and f.ground_pos.distance_to(who.ground_pos) <= ATTACK_R


## The standing building a click at `at` would pick: the nearest within BUILDING_PICK_R, burnable or not (building_ok() decides). Ground
## you can walk on (a gate, a bridge, a field) is not a building here.
static func building_at(env: EnvironmentField, at: Vector2) -> Structure:
	var best: Structure = null
	var best_d := BUILDING_PICK_R
	for s in env.near(at, BUILDING_PICK_R):
		if not is_instance_valid(s) or s.destroyed or s.walkable:
			continue
		var d := s.distance_to(at)
		if d <= best_d:
			best_d = d
			best = s
	return best


## Whether `s` is a fair target for `who`'s burn order: a standing thing that burns (FireManager.burns()) within BURN_R of them.
static func building_ok(who: Person, s: Variant) -> bool:
	if not is_instance_valid(who) or not is_instance_valid(s) or not s is Structure:
		return false
	var b := s as Structure
	return not b.destroyed and FireManager.burns(b) and b.distance_to(who.ground_pos) <= BURN_R


## Where someone coming from `from` stands to set `s` alight: on free ground at the building's edge nearest them (half a unit out), else
## the nearest free ground to its middle, else where they are.
static func stand_at(grid: WalkGrid, s: Structure, from: Vector2) -> Vector2:
	var edge := from.clamp(s.footprint.position, s.footprint.end)
	var out := from - edge
	var to := edge + (out.normalized() * 0.5 if out.length() > 0.01 else Vector2.ZERO)
	if grid == null:
		return to
	var free := grid.nearest_walkable(to, 6)
	if free == Vector2.INF:
		free = grid.nearest_walkable(s.center(), 6)
	return free if free != Vector2.INF else from


func _build() -> void:
	duration = MAX_SHOW
	busy = 0.3
	var given: Variant = extra.get("target")
	_target = given if is_instance_valid(given) and given is Person else pick(ctx.field, origin)
	_to = extra.get("to", origin)
	_order = String(extra.get("order", "")) if extra.has("order") else ""
	if _order == "attack" or _order == "burn":
		_build_order()
		return
	if _target == null or not _target.whisper(_to, LINGER):
		duration = 0.1
		return
	ctx.play(&"q_whisper", _to)
	# A solid ring in a faint halo, no telegraph's scan or crosshair: a mark, not a threat.
	_ring = _mark(RING_R, COL_RING, 0.25)
	_halo = _mark(HALO_R, COL_HALO, 0.0)


## The attack and burn orders: the whisper takes (it keeps the flight they owe and the shake-off), and the ring marks the foe or the
## spot at the building. Nothing happens, as for a whisper that does not take, when it cannot.
func _build_order() -> void:
	var ok := false
	if _target != null and is_instance_valid(_target):
		if _order == "attack":
			_foe = extra.get("foe") if foe_ok(_target, extra.get("foe")) else null
			if _foe != null:
				_to = _foe.ground_pos
				ok = _target.whisper_fight(_foe, ATTACK_SECS, Person.SOLDIER_BLOW if _target.soldier else CIVIL_BLOW)
		elif ctx.crowd != null and ctx.crowd.fires != null and building_ok(_target, extra.get("building")):
			_building = extra.get("building")
			_to = stand_at(_target.grid, _building, _target.ground_pos)
			ok = _target.whisper(_to, BURN_SECS + BURN_AFTER)
	if not ok:
		duration = 0.1
		return
	ctx.play(&"q_whisper", _to)
	_ring = _mark(RING_R, COL_RING, 0.25)
	_halo = _mark(HALO_R, COL_HALO, 0.0)


func _mark(r: float, col: Color, fill: float) -> QuadFx:
	var q := FxParts.rings(self, _to, r, col, 1, 12.0)
	q.set_param("scan", 0.0)
	q.set_param("crosshair", 0.0)
	q.set_param("pulse", 0.0)
	q.set_param("fill", fill)
	q.set_param("alpha", 0.0)
	return q


## Still whispered to this spot: alive, of the whispered mind, and not since sent somewhere else. An attack order holds while they
## are set on the foe.
func _holds() -> bool:
	if _order == "attack":
		return is_instance_valid(_target) and _target.is_alive() and _target.mind == Person.Mind.FIGHT and _target.fight_target == _foe
	return is_instance_valid(_target) and _target.is_alive() and _target.mind == Person.Mind.WHISPERED \
		and _target.anchor == _to


func _fx_process(_delta: float) -> void:
	if _order == "burn":
		_burn_step()
	elif _order == "attack" and is_instance_valid(_ring) and is_instance_valid(_foe):
		_ring.position = _foe.ground_pos  # the ring follows the foe
		_halo.position = _foe.ground_pos
	if not _holds():
		duration = minf(duration, t + 0.4)  # fade out with the whisper
	var fade := clampf(minf(t / 0.3, (duration - t) / 0.4), 0.0, 1.0)
	var beat := sin(t * PULSE_RATE)
	if is_instance_valid(_ring):
		_ring.set_param("alpha", fade * (1.0 - PULSE_DEPTH + PULSE_DEPTH * beat))
	if is_instance_valid(_halo):
		_halo.set_param("alpha", fade * (1.0 - PULSE_DEPTH - PULSE_DEPTH * beat))


## Burn: note when they get there (the whisper's linger counts only from then), and BURN_SECS later light the building -- if they
## are still under the whisper, and it still stands and burns (FireManager.ignite() checks that).
func _burn_step() -> void:
	if _lit or not _holds():
		return
	if _arrived < 0.0:
		if _target.goal() == Vector2.INF:
			_arrived = t
		return
	if t - _arrived < BURN_SECS:
		return
	_lit = true
	if ctx.crowd != null and ctx.crowd.fires != null:
		ctx.crowd.fires.ignite(_building, EmberFx.START_LEVEL)
