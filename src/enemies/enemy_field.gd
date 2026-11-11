class_name EnemyField
extends Node
## Registry of enemies with ground-space queries. Effects touch enemies only through this.

signal enemy_killed(enemy: DummyEnemy, kind: StringName)
## A blow landed on a person (Person.hurt()), for its sound; nothing in the simulation listens.
signal enemy_struck(enemy: DummyEnemy, by: DummyEnemy)

var bounds := Rect2(-6.5, -6.5, 13, 13)
var env: EnvironmentField
var lights: LightField
var look := DummyEnemy.Look.TROOPER

var _enemies: Array[DummyEnemy] = []
## The passages open in the world (Mirrorfold Passage): any Object with `carries(p: Vector2) -> bool` and
## `across(p: Vector2) -> Vector2`. What is dropped or poured onto one arrives on its other side (through()).
var portals: Array = []


## Where `p` ends up after the open passages: the first portal that carries it takes it across; else `p`.
func through(p: Vector2) -> Vector2:
	for portal in portals:
		if is_instance_valid(portal) and portal.carries(p):
			return portal.across(p)
	return p


func spawn(count: int, parent: Node, rng: RandomNumberGenerator) -> void:
	for i in count:
		var e := DummyEnemy.new()
		e.look = look
		e.rng.seed = rng.randi()
		e.ground_pos = Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y))
		for attempt in 20:
			if env == null or not env.blocked(e.ground_pos, 0.3):
				break
			e.ground_pos = Vector2(
				rng.randf_range(bounds.position.x, bounds.end.x),
				rng.randf_range(bounds.position.y, bounds.end.y))
		add(e)
		parent.add_child(e)


func add(e: DummyEnemy) -> void:
	e.bounds = bounds
	e.lights = lights
	if env != null:
		e.blocked = env.blocked
		e.block_env = env
	_enemies.append(e)


## Take one unit out of the field: it left the map (a citizen escaped) rather than died.
func remove(e: DummyEnemy) -> void:
	_enemies.erase(e)


func clear() -> void:
	for e in _enemies:
		if not is_instance_valid(e):
			continue
		if e.is_inside_tree():
			e.queue_free()
		else:
			e.free()
	_enemies.clear()


## Drop units that are gone or dead, so a four-minute mission does not keep scanning corpses.
func purge() -> void:
	var keep: Array[DummyEnemy] = []
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			keep.append(e)
	_enemies = keep


func alive() -> Array[DummyEnemy]:
	var out: Array[DummyEnemy] = []
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			out.append(e)
	return out


func in_radius(center: Vector2, r: float) -> Array[DummyEnemy]:
	var out: Array[DummyEnemy] = []
	for e in alive():
		if e.ground_pos.distance_squared_to(center) <= r * r:
			out.append(e)
	return out


## The living standing in `r` (edges included), without building the list of everyone alive first: cheap enough to
## ask every frame about a small patch of a big town (The Folded Ward).
func in_rect(r: Rect2) -> Array[DummyEnemy]:
	var out: Array[DummyEnemy] = []
	var lo := r.position
	var hi := r.end
	for e in _enemies:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var g := e.ground_pos
		if g.x >= lo.x and g.x <= hi.x and g.y >= lo.y and g.y <= hi.y:
			out.append(e)
	return out


func in_lane(origin: Vector2, dir: Vector2, half_width: float, along_min: float, along_max: float) -> Array[DummyEnemy]:
	var out: Array[DummyEnemy] = []
	var side := dir.orthogonal()
	for e in alive():
		var rel := e.ground_pos - origin
		var along := rel.dot(dir)
		if along >= along_min and along <= along_max and absf(rel.dot(side)) <= half_width:
			out.append(e)
	return out


## source: ground position the damage came from, so the death reaction can move away from it.
func kill(e: DummyEnemy, kind: StringName, source := Vector2.INF) -> bool:
	if not is_instance_valid(e) or not e.is_alive():
		return false
	e.die(kind, source)
	enemy_killed.emit(e, kind)
	return true


## Freeze living enemies within radius that are not frozen yet; returns how many were frozen.
## Already frozen enemies keep their timer. `on_thaw(enemy)` fires when each one's ice runs out.
func freeze_radius(center: Vector2, r: float, seconds: float, on_thaw := Callable()) -> int:
	var count := 0
	for e in in_radius(center, r):
		if e.is_frozen():
			continue
		count += 1
		e.freeze(seconds, on_thaw)
	return count


func frozen_in_radius(center: Vector2, r: float) -> Array[DummyEnemy]:
	var out: Array[DummyEnemy] = []
	for e in in_radius(center, r):
		if e.is_frozen():
			out.append(e)
	return out


func knock_from(center: Vector2, r_min: float, r_max: float, force: float) -> void:
	for e in alive():
		var rel := e.ground_pos - center
		var d := rel.length()
		if d < r_min or d > r_max:
			continue
		var dir := rel / d if d > 0.001 else Vector2.RIGHT.rotated(e.rng.randf() * TAU)
		e.knock(dir * force * (1.0 - 0.5 * d / r_max))


func pull(center: Vector2, radius: float, strength: float, swirl: float, delta: float) -> void:
	for e in alive():
		if e.state == DummyEnemy.State.PULLED or e.ground_pos.distance_squared_to(center) <= radius * radius:
			e.pull_step(center, strength, swirl, delta)


## Whether ground point `g` lies in the cone at `center` facing `dir` (a unit vector): within `radius` of it and within
## `half_angle` (radians) either side of `dir`. At PI / 2 the cone is the half disc in front of `center` (Heaven's Door),
## the line through `center` across `dir` included; `center` itself is in it.
static func cone_has(g: Vector2, center: Vector2, dir: Vector2, radius: float, half_angle: float) -> bool:
	var rel := g - center
	var d := rel.length()
	if d > radius:
		return false
	if d < 0.000001:
		return true
	return rel.dot(dir) / d >= cos(half_angle) - 0.000001


## How fast a pull toward a centre moves something `d` from it: `near` a second at the centre, falling evenly to `far`
## at `radius` (and `far` beyond it).
static func cone_speed(d: float, radius: float, near: float, far: float) -> float:
	return lerpf(near, far, clampf(d / radius, 0.0, 1.0))


## Where something at `g` ends a step of `step` ground units straight toward `to` (never past it): the whole step when it
## ends on open ground (on the map, not in a wall or a building -- env.blocked()); else the step along each ground axis
## alone (sliding along the wall), the longer first; else nowhere new (`g`: held against the wall).
func carry_toward(g: Vector2, to: Vector2, step: float) -> Vector2:
	var rel := to - g
	var d := rel.length()
	if d < 0.000001 or step <= 0.0:
		return g
	var move := rel * (minf(step, d) / d)
	var tries: Array[Vector2] = [g + move]
	if absf(move.x) >= absf(move.y):
		tries.append_array([g + Vector2(move.x, 0.0), g + Vector2(0.0, move.y)])
	else:
		tries.append_array([g + Vector2(0.0, move.y), g + Vector2(move.x, 0.0)])
	for q in tries:
		if q != g and bounds.has_point(q) and (env == null or not env.blocked(q)):
			return q
	return g


## The living in the cone at `center` facing `dir` (cone_has()).
func in_cone(center: Vector2, dir: Vector2, radius: float, half_angle: float) -> Array[DummyEnemy]:
	var out: Array[DummyEnemy] = []
	for e in in_radius(center, radius):
		if cone_has(e.ground_pos, center, dir, radius, half_angle):
			out.append(e)
	return out


## A pull toward `center` over its cone (in_cone()), `delta` seconds of it: everyone there is moved straight toward it at
## cone_speed() -- `near` a second at the centre falling evenly to `far` at `radius` -- by carry_toward() (sliding
## along walls, never through them). It is a carry, not a hold: they keep their minds and their own walking. Those for
## whom `skip(e) -> bool` is true are left. Returns everyone it reached (moved or held against a wall).
func pull_cone(center: Vector2, dir: Vector2, radius: float, half_angle: float, near: float, far: float, delta: float,
		skip := Callable()) -> Array[DummyEnemy]:
	var out: Array[DummyEnemy] = []
	for e in in_cone(center, dir, radius, half_angle):
		if skip.is_valid() and skip.call(e):
			continue
		var d := e.ground_pos.distance_to(center)
		e.ground_pos = carry_toward(e.ground_pos, center, cone_speed(d, radius, near, far) * delta)
		e._sync_position()
		out.append(e)
	return out


func release_all() -> void:
	for e in alive():
		e.release()
