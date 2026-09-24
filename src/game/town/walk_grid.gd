class_name WalkGrid
extends RefCounted
## Where the people of Aldermere may walk: an A* grid over the map at half-unit cells. A standing building
## blocks, its rubble does not, the river blocks except where the bridge still stands, and a fallen bridge
## closes the water under it. The grid is patched in place when a building falls, never rebuilt.

const CELL := 0.5
## People are about this wide, so a footprint is grown by it before being stamped solid.
const BODY := 0.15
## How far nearest_walkable() and path() will look for a free cell beside a blocked goal.
const SNAP_CELLS := 8

var grid := AStarGrid2D.new()

var _env: EnvironmentField
var _bridge: Structure


func setup(env: EnvironmentField, town: Town) -> WalkGrid:
	_env = env
	_bridge = town.bridge
	var m := TownLayout.MAP
	grid.region = Rect2i(Vector2i(floori(m.position.x / CELL), floori(m.position.y / CELL)),
		Vector2i(roundi(m.size.x / CELL), roundi(m.size.y / CELL)))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL, CELL) * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	stamp(TownLayout.RIVER, true)
	# Two passes, because a building people walk over has to win against whatever else claimed its cells: the
	# gates sit inside the wall segments' grown footprints, and the bridge sits in the river.
	for s in env.structures():
		_apply(s)
	for s in env.structures():
		_open(s)
	env.structure_destroyed.connect(_on_destroyed)
	return self


func world_to_id(g: Vector2) -> Vector2i:
	return Vector2i(floori(g.x / CELL), floori(g.y / CELL))


func id_to_world(id: Vector2i) -> Vector2:
	return Vector2(id) * CELL + grid.offset


func walkable(g: Vector2) -> bool:
	var id := world_to_id(g)
	return grid.is_in_boundsv(id) and not grid.is_point_solid(id)


## True when a straight walk from `from` to `to` crosses no solid cell (sampled every half cell).
func clear_line(from: Vector2, to: Vector2) -> bool:
	var span := to - from
	var steps := maxi(int(span.length() / (CELL * 0.5)), 1)
	for i in range(1, steps + 1):
		if not walkable(from + span * (float(i) / float(steps))):
			return false
	return true


## `g` itself when it is free, otherwise the centre of the nearest free cell (searched in rings), or
## Vector2.INF when everything within max_cells is solid.
func nearest_walkable(g: Vector2, max_cells := SNAP_CELLS) -> Vector2:
	var id := world_to_id(g)
	if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
		return g
	var fallback := Vector2.INF
	for r in range(1, max_cells + 1):
		var best := Vector2.INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := id + Vector2i(dx, dy)
				if not grid.is_in_boundsv(c) or grid.is_point_solid(c):
					continue
				var w := id_to_world(c)
				if fallback == Vector2.INF or w.distance_squared_to(g) < fallback.distance_squared_to(g):
					fallback = w
				if not clear_line(g, w):
					continue
				if best == Vector2.INF or w.distance_squared_to(g) < best.distance_squared_to(g):
					best = w
		if best != Vector2.INF:
			return best
	return fallback


## Waypoints from `from` to `to` in ground units (empty when there is no route). A goal inside a building
## routes to the nearest free cell beside it, so "walk home" works even though home is solid.
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := nearest_walkable(from)
	var goal := nearest_walkable(to)
	if start == Vector2.INF or goal == Vector2.INF:
		return PackedVector2Array()
	return grid.get_point_path(world_to_id(start), world_to_id(goal))


## The closest exit there is still a route to, or Vector2.INF when the town is sealed.
func nearest_exit(from: Vector2) -> Vector2:
	var exits: Array[Vector2] = []
	for e: Vector2 in TownLayout.EXITS:
		exits.append(e)
	exits.sort_custom(func(a: Vector2, b: Vector2): return a.distance_squared_to(from) < b.distance_squared_to(from))
	for e in exits:
		if not path(from, e).is_empty():
			return e
	return Vector2.INF


## Mark every cell whose centre lies in `rect` solid or free.
func stamp(rect: Rect2, solid: bool) -> void:
	var c0 := world_to_id(rect.position)
	var c1 := world_to_id(rect.end)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var id := Vector2i(x, y)
			if grid.is_in_boundsv(id) and rect.has_point(id_to_world(id)):
				grid.set_point_solid(id, solid)


## A standing building that blocks: its footprint, grown by a body's width, is solid.
func _apply(s: Structure) -> void:
	if not is_instance_valid(s) or s.destroyed or s.walkable:
		return
	stamp(s.footprint.grow(BODY), true)


## A standing building people walk over — a gate, the bridge, a field: its own footprint is open again,
## whatever a neighbour's margin or the river did to those cells.
func _open(s: Structure) -> void:
	if not is_instance_valid(s) or s.destroyed or not s.walkable:
		return
	stamp(s.footprint, false)


## A building fell: its ground opens up (rubble is walkable), except the bridge, whose fall closes the river.
func _on_destroyed(s: Structure, _kind: StringName) -> void:
	if s == _bridge:
		stamp(s.footprint, true)
		return
	stamp(s.footprint.grow(BODY), false)
	# Freeing a footprint can free cells a standing neighbour or the river still needs, so put those back...
	var area := s.footprint.grow(BODY + CELL)
	if area.intersects(TownLayout.RIVER):
		stamp(area.intersection(TownLayout.RIVER), true)
	for other in _env.structures():
		if other != s and is_instance_valid(other) and not other.destroyed and not other.walkable \
				and other.footprint.grow(BODY).intersects(area):
			_apply(other)
	# ...and then open the ways through again, so a gate beside a fallen wall stays passable.
	for other in _env.structures():
		if other != s and is_instance_valid(other) and not other.destroyed and other.walkable \
				and other.footprint.intersects(area):
			_open(other)
