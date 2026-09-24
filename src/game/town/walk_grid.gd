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
	for s in env.structures():
		_apply(s)
	# The bridge's footprint overlaps the river band, and _apply() above skips every walkable structure
	# (right for gates and fields, which touch nothing pre-stamped) -- so while the bridge stands, open the
	# water under it explicitly, the same way _on_destroyed() re-opens it after a neighbour floods it back.
	if is_instance_valid(_bridge) and not _bridge.destroyed:
		stamp(_bridge.footprint, false)
	env.structure_destroyed.connect(_on_destroyed)
	return self


func world_to_id(g: Vector2) -> Vector2i:
	return Vector2i(floori(g.x / CELL), floori(g.y / CELL))


func id_to_world(id: Vector2i) -> Vector2:
	return Vector2(id) * CELL + grid.offset


func walkable(g: Vector2) -> bool:
	var id := world_to_id(g)
	return grid.is_in_boundsv(id) and not grid.is_point_solid(id)


## `g` itself when it is free, otherwise the centre of the nearest free cell (searched in rings), or
## Vector2.INF when everything within max_cells is solid.
func nearest_walkable(g: Vector2, max_cells := SNAP_CELLS) -> Vector2:
	var id := world_to_id(g)
	if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
		return g
	for r in range(1, max_cells + 1):
		var best := Vector2i.ZERO
		var found := false
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := id + Vector2i(dx, dy)
				if not grid.is_in_boundsv(c) or grid.is_point_solid(c):
					continue
				if not found or id_to_world(c).distance_squared_to(g) < id_to_world(best).distance_squared_to(g):
					best = c
					found = true
		if found:
			return id_to_world(best)
	return Vector2.INF


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


func _apply(s: Structure) -> void:
	if not is_instance_valid(s):
		return
	if s.destroyed or s.walkable:
		return
	stamp(s.footprint.grow(BODY), true)


## A building fell: its ground opens up (rubble is walkable), except the bridge, whose fall closes the river.
func _on_destroyed(s: Structure) -> void:
	if s == _bridge:
		stamp(s.footprint, true)
		return
	stamp(s.footprint.grow(BODY), false)
	# Freeing a footprint can free cells a standing neighbour or the river needs, so put those back.
	var area := s.footprint.grow(BODY + CELL)
	if area.intersects(TownLayout.RIVER):
		var water := area.intersection(TownLayout.RIVER)
		stamp(water, true)
		if is_instance_valid(_bridge) and not _bridge.destroyed:
			stamp(_bridge.footprint.intersection(water), false)
	for other in _env.structures():
		if other != s and is_instance_valid(other) and not other.destroyed and not other.walkable \
				and other.footprint.grow(BODY).intersects(area):
			_apply(other)
