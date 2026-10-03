class_name MindWhisperFx
extends FxTimeline
## Mind Whisper (v0.08, Dominion): one person -- the citizen pressed on -- drops what they are doing, walks to where the
## player released, lingers LINGER seconds and resumes (Person.whisper()). Quiet: no threat, no alarm. A soft gold
## ring marks the spot while they are on their way and lingering; the glyph over them is the person's own.

## How near the press must be to a citizen.
const PICK_R := 0.6
## How far from them the spot may be.
const REACH := 10.0
## How long they linger at the spot.
const LINGER := 8.0
## The ring at the spot: its soft gold and its radius (ground units).
const COL_RING := Color(0.95, 0.82, 0.4, 0.6)
const RING_R := 0.5
## The ring is drawn for as long as this, at most: a walk of REACH along the town's paths at a stroll, then LINGER.
const MAX_SHOW := 40.0

var _target: Person
var _to := Vector2.INF
var _ring: QuadFx


## The citizen a press at `at` whispers to: the nearest living one out in the open within PICK_R, or null.
static func pick(field: EnemyField, at: Vector2) -> Person:
	var best: Person = null
	for e in field.in_radius(at, PICK_R):
		var p := e as Person
		if p == null or p.soldier or p.inside or not p.is_alive():
			continue
		if best == null or p.ground_pos.distance_squared_to(at) < best.ground_pos.distance_squared_to(at):
			best = p
	return best


## Where a release at `to` sends someone standing at `from`: at most REACH away, on walkable ground.
static func clamp_to(grid: WalkGrid, from: Vector2, to: Vector2) -> Vector2:
	var g := from + (to - from).limit_length(REACH)
	if grid == null or grid.walkable(g):
		return g
	var free := grid.nearest_walkable(g, 6)
	return free if free != Vector2.INF else from


func _build() -> void:
	duration = MAX_SHOW
	busy = 0.3
	var given: Variant = extra.get("target")
	_target = given if is_instance_valid(given) and given is Person else pick(ctx.field, origin)
	_to = extra.get("to", origin)
	if _target == null or not _target.whisper(_to, LINGER):
		duration = 0.1
		return
	ctx.play(&"grav_shimmer", _to, -14.0)
	# One solid ring, no telegraph's scan or crosshair: a mark, not a threat.
	_ring = FxParts.rings(self, _to, RING_R, COL_RING, 1, 12.0)
	_ring.set_param("scan", 0.0)
	_ring.set_param("crosshair", 0.0)
	_ring.set_param("pulse", 0.0)
	_ring.set_param("fill", 0.15)
	_ring.set_param("alpha", 0.0)


## Still whispered to this spot: alive, of the whispered mind, and not since sent somewhere else.
func _holds() -> bool:
	return is_instance_valid(_target) and _target.is_alive() and _target.mind == Person.Mind.WHISPERED \
		and _target.anchor == _to


func _fx_process(_delta: float) -> void:
	if not _holds():
		duration = minf(duration, t + 0.4)  # fade out with the whisper
	if is_instance_valid(_ring):
		var fade := clampf(minf(t / 0.3, (duration - t) / 0.4), 0.0, 1.0)
		_ring.set_param("alpha", fade * (0.75 + 0.25 * sin(t * 3.0)))
