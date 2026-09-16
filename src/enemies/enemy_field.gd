class_name EnemyField
extends Node
## Registry of enemies with ground-space queries. Effects touch enemies only through this.

signal enemy_killed(enemy: DummyEnemy, kind: StringName)

var bounds := Rect2(-6.5, -6.5, 13, 13)
var env: EnvironmentField
var lights: LightField
var look := DummyEnemy.Look.TROOPER

var _enemies: Array[DummyEnemy] = []


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
	_enemies.append(e)


func clear() -> void:
	for e in _enemies:
		if not is_instance_valid(e):
			continue
		if e.is_inside_tree():
			e.queue_free()
		else:
			e.free()
	_enemies.clear()


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


func release_all() -> void:
	for e in alive():
		e.release()
