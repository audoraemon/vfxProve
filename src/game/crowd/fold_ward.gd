class_name FoldWard
extends RefCounted
## A square of ground folded so its edges meet, like a world that wraps round (The Folded Ward). It is axis-aligned on
## the ground grid, `half` to each side of its centre. Its rule is one of two:
##   OUT  no way out: whoever stands inside and walks across an edge going out comes back in at the opposite edge, on
##        the same line (across x = +half at y, in at x = -half + EDGE_IN at that y; across a corner, both ways at once),
##        still walking the same way to the same goal. Walking in is free.
##   IN   no way in: whoever stands outside and walks across an edge going in comes out past the opposite edge, on the
##        same line, EDGE_IN outside it, still walking the same way. Leaving is free.
## Where the spot it lands on is not open ground (an open walk-grid cell, clear of every building's margin), it lands on
## the nearest open cell within SEEK on the side it must land on (inside for OUT, outside for IN), the nearest first and
## the first found of two as near; with none, it is stopped at the edge: put back where it stood a moment before.
## A walk is a step of at most JUMP between two looks; a longer one is a power setting someone down somewhere else, not a
## walk across the edge, and the fold lets it be. Under IN, one put out that means to be inside -- its goal, or with
## none its anchor (a citizen's street, a soldier's post), or a hound's prey -- is turned away for good (turn_away()):
## it walks on outward along the heading it came out with, then mills outside, until it is let in (let_in()). It moves the living out in the open only: citizens, soldiers, the
## town's dogs and cats, visitors from the other side (and any other unit of the field); a throw is carried across as
## well. The dead are not moved; one inside a building is not looked at. No number is drawn from any rng: the same
## walks fold the same way. The owner calls step() every frame while the rule holds.

enum Mode { OUT, IN }

## How far inside (OUT) or outside (IN) the opposite edge one comes back.
const EDGE_IN := 0.3
## How far from the landing spot an open cell is looked for when the spot itself is not open ground.
const SEEK := 1.0
## The longest step between two looks that is still a walk.
const JUMP := 1.0
## The margin a body keeps from a building (a person's step margin): ground nearer a footprint is not open.
const MARGIN := DummyEnemy.STEP_MARGIN

var centre := Vector2.ZERO
var half := 3.0
var mode := Mode.OUT
var grid: WalkGrid
var env: EnvironmentField

## What the last step() did: [body, where it stepped to, where it was set down, where it stepped from] for each one
## carried across, and the bodies stopped at the edge.
var wrapped: Array = []
var stopped: Array = []
## The bodies turned away (turn_away()) and not let in yet.
var turned: Array = []

## Where each body near the square stood at the last look, by instance id; swapped with _now each step.
var _was := {}
var _now := {}


func _init(at: Vector2, half_side: float, rule: Mode, walk_grid: WalkGrid, field_env: EnvironmentField) -> void:
	centre = at
	half = half_side
	mode = rule
	grid = walk_grid
	env = field_env


## The square, in ground units.
func rect() -> Rect2:
	return Rect2(centre - Vector2(half, half), Vector2(half, half) * 2.0)


## Whether `g` is inside the square (its edges count as inside).
func inside(g: Vector2) -> bool:
	return absf(g.x - centre.x) <= half and absf(g.y - centre.y) <= half


## Whether a walk from `from` to `to` crosses the edge the way the rule forbids.
func crosses(from: Vector2, to: Vector2) -> bool:
	if from.distance_squared_to(to) > JUMP * JUMP:
		return false
	if mode == Mode.OUT:
		return inside(from) and not inside(to)
	return not inside(from) and inside(to)


## Where a walk from `from` to `to` that crosses() comes out: the same line, at the opposite edge -- EDGE_IN inside it
## (OUT), EDGE_IN outside it (IN) -- on each axis it crossed; along the other axis, where it stands.
func folded(from: Vector2, to: Vector2) -> Vector2:
	var out := to
	if mode == Mode.OUT:
		for k in 2:
			if to[k] > centre[k] + half:
				out[k] = centre[k] - half + EDGE_IN
			elif to[k] < centre[k] - half:
				out[k] = centre[k] + half - EDGE_IN
	else:
		for k in 2:
			if from[k] < centre[k] - half:
				out[k] = centre[k] + half + EDGE_IN
			elif from[k] > centre[k] + half:
				out[k] = centre[k] - half - EDGE_IN
	return out


## Whether `g` is ground a body may be set down on: an open walk-grid cell, clear of every building's margin.
func open_ground(g: Vector2) -> bool:
	if grid != null and not grid.walkable(g):
		return false
	return env == null or not env.blocked(g, MARGIN)


## Where a walk from `from` to `to` that crosses() lands: folded() when it is open ground; else the nearest open cell
## centre within SEEK of it on the side it must land on; Vector2.INF when there is none (it is stopped at the edge).
func landing(from: Vector2, to: Vector2) -> Vector2:
	var spot := folded(from, to)
	if open_ground(spot):
		return spot
	var want_inside := mode == Mode.OUT
	if grid == null:
		return Vector2.INF
	var id := grid.world_to_id(spot)
	var reach := ceili(SEEK / WalkGrid.CELL)
	var best := Vector2.INF
	var best_d := INF
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var c := grid.id_to_world(id + Vector2i(dx, dy))
			var d := c.distance_squared_to(spot)
			if d > SEEK * SEEK or d >= best_d or inside(c) != want_inside or not open_ground(c):
				continue
			best = c
			best_d = d
	return best


## One look: every body near the square that has walked across its edge the forbidden way since the last look is carried
## across (or stopped at the edge). `field` holds the people (and any other unit), `crowd` (may be null) the town's
## animals and the visitors. Fills `wrapped` and `stopped`.
func step(field: EnemyField, crowd: Crowd) -> void:
	wrapped.clear()
	stopped.clear()
	var near := rect().grow(JUMP)
	if field != null:
		for e in field.in_rect(near):
			var p := e as Person
			if p != null and p.inside:
				continue
			_look(e)
	if crowd != null:
		if crowd.animals != null and is_instance_valid(crowd.animals):
			for a: Animal in crowd.animals.animals:
				if is_instance_valid(a) and a.is_alive() and near.has_point(a.ground_pos):
					_look(a)
		for pack: Visitors in crowd.visitors:
			for a in pack.living():
				if near.has_point(a.ground_pos):
					_look(a)
	var last := _was
	_was = _now
	_now = last
	_now.clear()


## IN: each body the last step() put out that means to be inside the square is held off it for `seconds` (its
## hold_off()): it walks on along the heading it came out with for `walk_away` seconds, then mills outside. A passer-by
## bound beyond the square is not turned away. Returns how many were turned away now.
func turn_away(seconds: float, walk_away: float) -> int:
	if mode != Mode.IN:
		return 0
	var n := 0
	for w: Array in wrapped:
		var body: Object = w[0]
		if not inside(body.bound_for()):
			continue
		if body.hold_off(rect(), seconds, (w[1] as Vector2) - (w[3] as Vector2), walk_away):
			n += 1
			if not turned.has(body):
				turned.append(body)
	return n


## Everyone turned away is let in again (the rule lifts): each takes up its own goal.
func let_in() -> void:
	for body in turned:
		if is_instance_valid(body):
			body.end_hold_off()
	turned.clear()


## Nobody is watched any more (the rule lifts): the next look starts afresh.
func forget() -> void:
	_was.clear()
	_now.clear()


func _look(body: Object) -> void:
	var id := body.get_instance_id()
	var at: Vector2 = body.ground_pos
	var from: Vector2 = _was.get(id, Vector2.INF)
	if from != Vector2.INF and crosses(from, at):
		var land := landing(from, at)
		if land == Vector2.INF:
			if body.wrap_to(from, false):
				stopped.append(body)
		elif body.wrap_to(land):
			wrapped.append([body, at, land, from])
	_now[id] = body.ground_pos
