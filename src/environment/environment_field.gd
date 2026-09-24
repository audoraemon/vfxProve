class_name EnvironmentField
extends Node
## Registry of destructible structures with ground-space damage queries, like EnemyField for props.

## A structure was destroyed (any cause); the game's rules count these.
signal structure_destroyed(s: Structure)

## Spatial index cell (ground units) for blocked(); query margins up to MAX_MARGIN use it.
const CELL := 2.0
const MAX_MARGIN := 0.5

var lights: LightField
## Y-sorted world layer structures are added to (null in headless tests).
var world_parent: Node
var fx_parent: Node
var fx_back: Node
var rng := RandomNumberGenerator.new()

var _structures: Array[Structure] = []
## Vector2i cell -> structures whose footprint, grown by MAX_MARGIN, touches that cell.
var _grid := {}


func add_structure(rect: Rect2, height: float, kind: Structure.Kind, role := &"") -> Structure:
	var s := Structure.new().setup(rect, height, kind, rng.randi())
	s.role = role
	s.lights = lights
	s.fx_parent = fx_parent
	s.fx_back = fx_back
	s.broken.connect(_on_structure_broken)
	if kind == Structure.Kind.TORCH and lights != null:
		s.light_id = lights.add_static(rect.get_center(), 2.4, Structure.TORCH_LIGHT, 0.55, 1.0)
	_structures.append(s)
	_index(s)
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


## Castle courtyard: keeps on the corners, crenellated walls along the back edges, timber houses,
## barricades and torches, leaving the middle open for the horde.
func build_castle() -> void:
	var K := Structure.Kind.KEEP
	var W := Structure.Kind.CASTLE_WALL
	var H := Structure.Kind.HOUSE
	var T := Structure.Kind.TORCH
	var C := Structure.Kind.CRATES
	var layout := [
		[Rect2(-6.6, -6.6, 1.8, 1.8), 96.0, K], [Rect2(4.8, -6.6, 1.8, 1.8), 88.0, K],
		[Rect2(-6.6, 4.9, 1.6, 1.6), 80.0, K],
		[Rect2(-4.6, -6.5, 9.2, 0.7), 34.0, W], [Rect2(-6.5, -4.6, 0.7, 9.3), 34.0, W],
		[Rect2(-3.0, -4.9, 1.8, 1.2), 24.0, H], [Rect2(1.0, -5.0, 1.4, 1.4), 22.0, H],
		[Rect2(-5.2, 1.4, 1.2, 1.8), 24.0, H], [Rect2(4.8, 2.0, 1.4, 1.6), 22.0, H],
		[Rect2(2.2, 4.8, 1.8, 1.2), 22.0, H],
		[Rect2(-2.6, 2.6, 1.4, 0.4), 12.0, C], [Rect2(2.4, -1.8, 0.5, 1.2), 12.0, C],
		[Rect2(-3.4, -2.2, 0.5, 0.5), 10.0, C],
		[Rect2(-4.2, -5.6, 0.2, 0.2), 16.0, T], [Rect2(3.6, -5.6, 0.2, 0.2), 16.0, T],
		[Rect2(-5.6, -1.2, 0.2, 0.2), 16.0, T], [Rect2(-5.6, 3.4, 0.2, 0.2), 16.0, T],
		[Rect2(0.2, 3.2, 0.2, 0.2), 16.0, T], [Rect2(4.2, -0.6, 0.2, 0.2), 16.0, T],
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
	_grid.clear()


## Take one structure out of the field and free it (the town's teardown). The spatial index is rebuilt, so
## this is for the handful of times a map is torn down, not for destruction — destroyed buildings stay.
func remove(s: Structure) -> void:
	_structures.erase(s)
	if is_instance_valid(s):
		if s.light_id != 0 and lights != null:
			lights.remove(s.light_id)
			s.light_id = 0
		if s.is_inside_tree():
			s.queue_free()
		else:
			s.free()
	_reindex()


func _reindex() -> void:
	_grid.clear()
	for s in _structures:
		if is_instance_valid(s):
			_index(s)


func structures() -> Array[Structure]:
	return _structures


## True when a standing structure units cannot walk through occupies the ground point (rubble, gates, the bridge
## and fields are walkable). Only the structures indexed in g's cell are checked.
func blocked(g: Vector2, margin := 0.15) -> bool:
	var candidates: Array = _structures if margin > MAX_MARGIN else _grid.get(_cell(g), [])
	for s in candidates:
		if is_instance_valid(s) and not s.destroyed and not s.walkable and s.contains(g, margin):
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


func _on_structure_broken(s: Structure) -> void:
	structure_destroyed.emit(s)


func _cell(g: Vector2) -> Vector2i:
	return Vector2i(floori(g.x / CELL), floori(g.y / CELL))


func _index(s: Structure) -> void:
	var r := s.footprint.grow(MAX_MARGIN)
	var c0 := _cell(r.position)
	var c1 := _cell(r.end)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var key := Vector2i(x, y)
			if not _grid.has(key):
				_grid[key] = []
			_grid[key].append(s)
