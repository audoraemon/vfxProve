class_name EnvironmentField
extends Node
## Registry of destructible structures with ground-space damage queries, like EnemyField for props.

var lights: LightField
## Y-sorted world layer structures are added to (null in headless tests).
var world_parent: Node
var fx_parent: Node
var fx_back: Node
var rng := RandomNumberGenerator.new()

var _structures: Array[Structure] = []


func add_structure(rect: Rect2, height: float, kind: Structure.Kind) -> Structure:
	var s := Structure.new().setup(rect, height, kind, rng.randi())
	s.lights = lights
	s.fx_parent = fx_parent
	s.fx_back = fx_back
	_structures.append(s)
	if world_parent != null:
		world_parent.add_child(s)
	return s


## A small ruined city block around the 14x14 sandbox, leaving the middle open for enemies.
func build_city() -> void:
	var T := Structure.Kind.TOWER
	var B := Structure.Kind.BLOCK
	var W := Structure.Kind.WALL
	var C := Structure.Kind.CRATES
	var layout := [
		[Rect2(-6.4, -6.4, 1.6, 1.6), 92.0, T], [Rect2(4.6, -6.3, 1.8, 1.4), 84.0, T],
		[Rect2(-6.3, 4.4, 1.5, 1.9), 78.0, T], [Rect2(4.9, 4.9, 1.4, 1.4), 30.0, B],
		[Rect2(-3.6, -6.0, 2.2, 1.2), 46.0, B], [Rect2(0.8, -6.1, 2.0, 1.2), 40.0, B],
		[Rect2(-6.2, -2.2, 1.2, 2.4), 44.0, B], [Rect2(5.3, -1.6, 1.2, 2.2), 50.0, B],
		[Rect2(-2.2, 5.0, 2.4, 1.2), 42.0, B], [Rect2(2.4, 5.2, 1.8, 1.2), 36.0, B],
		[Rect2(-3.4, -3.0, 1.8, 0.35), 14.0, W], [Rect2(2.0, 1.6, 0.35, 1.8), 14.0, W],
		[Rect2(1.8, -3.2, 1.6, 0.35), 14.0, W], [Rect2(-3.2, 1.8, 0.35, 1.6), 14.0, W],
		[Rect2(0.6, -1.8, 0.6, 0.6), 12.0, C], [Rect2(-1.9, 0.9, 0.7, 0.5), 10.0, C],
		[Rect2(3.4, 0.4, 0.6, 0.6), 12.0, C], [Rect2(-4.4, -0.6, 0.6, 0.6), 11.0, C],
	]
	for item in layout:
		add_structure(item[0], item[1], item[2])


func clear() -> void:
	for s in _structures:
		if not is_instance_valid(s):
			continue
		if s.is_inside_tree():
			s.queue_free()
		else:
			s.free()
	_structures.clear()


func structures() -> Array[Structure]:
	return _structures


## True when a standing structure occupies the ground point (rubble is walkable).
func blocked(g: Vector2, margin := 0.15) -> bool:
	for s in _structures:
		if is_instance_valid(s) and not s.destroyed and s.contains(g, margin):
			return true
	return false


func damage_radius(center: Vector2, radius: float, amount: float, kind: StringName) -> void:
	for s in _structures:
		if is_instance_valid(s) and not s.destroyed and s.distance_to(center) <= radius:
			s.damage(amount, center, kind)


## Anything the lane band [along_min, along_max] x [-half_width, half_width] overlaps is cut down.
func damage_lane(origin: Vector2, dir: Vector2, half_width: float, along_min: float, along_max: float, kind: StringName) -> void:
	var side := dir.orthogonal()
	for s in _structures:
		if not is_instance_valid(s) or s.destroyed:
			continue
		var half := s.footprint.size * 0.5
		var rel := s.center() - origin
		var along := rel.dot(dir)
		var across := rel.dot(side)
		var ext_along := absf(half.x * dir.x) + absf(half.y * dir.y)
		var ext_side := absf(half.x * side.x) + absf(half.y * side.y)
		if along + ext_along >= along_min and along - ext_along <= along_max and absf(across) <= half_width + ext_side:
			s.damage(99999.0, s.center() - dir, kind)


func shake_radius(center: Vector2, radius: float, amount: float) -> void:
	for s in _structures:
		if is_instance_valid(s) and not s.destroyed and s.distance_to(center) <= radius:
			s.shake(amount)
