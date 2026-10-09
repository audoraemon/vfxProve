class_name WalkGrid
extends RefCounted
## Where the people of Aldermere may walk: an A* grid over the map at half-unit cells. A standing building
## blocks, its rubble does not, the river blocks except where a bridge still stands, and a fallen bridge
## closes the water under it (CityDef.fallen_bridge(): Aldermere's whole footprint, the capital's water only). The grid is patched in place when a building falls, never rebuilt.

const CELL := 0.5
const BenchProf := preload("res://src/core/bench_prof.gd")

## People are about this wide, so a footprint is grown by it before being stamped solid.
const BODY := 0.15
## How far nearest_walkable() and path() will look for a free cell beside a blocked goal.
const SNAP_CELLS := 8

var grid := AStarGrid2D.new()
## Rises whenever a cell turns solid or free (stamp()): distance fields built on the grid rebuild on it.
var version := 0

var _env: EnvironmentField
## The town's crossings (Town.bridges).
var _bridges: Array[Structure] = []
## The city's blockers(), grown to the cells they close. Computed once: it lays out every house, garden and tree,
## far too slow to redo each time a building falls (a Cinderfall felling a dozen trees at once hitched ~100 ms).
var _blockers: Array[Rect2] = []


func setup(env: EnvironmentField, town: Town) -> WalkGrid:
	_env = env
	_bridges = town.bridges.duplicate()
	var city := City.current()
	var m := city.map()
	grid.region = Rect2i(Vector2i(floori(m.position.x / CELL), floori(m.position.y / CELL)),
		Vector2i(roundi(m.size.x / CELL), roundi(m.size.y / CELL)))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(CELL, CELL) * 0.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for r: Rect2 in city.rivers():
		stamp(r, true)
	# A garden or a yard closes every cell it touches, so nobody is drawn walking through its fence or props.
	for g in city.blockers():
		_blockers.append(g.grow(CELL * 0.5))
	for g in _blockers:
		stamp(g, true)
	# Two passes, because a building people walk over has to win against whatever else claimed its cells: the
	# gates sit inside the wall segments' grown footprints, and the bridge sits in the river.
	for s in env.structures():
		_apply(s)
	for s in env.structures():
		_open(s)
	env.structure_destroyed.connect(_on_destroyed)
	env.structure_restored.connect(refresh)
	env.structure_added.connect(refresh)
	env.structure_removed.connect(_reopen)
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
	if BenchProf.on:
		var t0 := BenchProf.begin()
		var out := grid.get_point_path(world_to_id(start), world_to_id(goal))
		BenchProf.add(&"paths", t0)
		BenchProf.count(&"path_calls")
		return out
	return grid.get_point_path(world_to_id(start), world_to_id(goal))


## The closest exit there is still a route to, or Vector2.INF when the town is sealed.
func nearest_exit(from: Vector2) -> Vector2:
	var exits: Array[Vector2] = []
	for e: Vector2 in City.current().exits():
		exits.append(e)
	exits.sort_custom(func(a: Vector2, b: Vector2): return a.distance_squared_to(from) < b.distance_squared_to(from))
	for e in exits:
		if not path(from, e).is_empty():
			return e
	return Vector2.INF


## Mark every cell whose centre lies in `rect` solid or free.
func stamp(rect: Rect2, solid: bool) -> void:
	version += 1
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
	stamp(solid_rect(s.footprint), true)


## The ground a footprint closes: grown by a body's width, and at least a cell across each way, so that something
## thinner (a fence, a notice board, a sliver of wall: none at Aldermere) still closes the cells it stands in, as it
## blocks the people walking into it.
static func solid_rect(footprint: Rect2) -> Rect2:
	var r := footprint.grow(BODY)
	if r.size.x < CELL:
		r = r.grow_individual((CELL - r.size.x) * 0.5, 0.0, (CELL - r.size.x) * 0.5, 0.0)
	if r.size.y < CELL:
		r = r.grow_individual(0.0, (CELL - r.size.y) * 0.5, 0.0, (CELL - r.size.y) * 0.5)
	return r


## A standing building people walk over — a gate, the bridge, a field: its own footprint is open again,
## whatever a neighbour's margin or the river did to those cells. One standing over the water (a capital set:
## BuildingTypes.OVER_WATER, the ferry landing) is open on its dry part only: the river under it stays closed.
func _open(s: Structure) -> void:
	if not is_instance_valid(s) or s.destroyed or not s.walkable:
		return
	stamp(s.footprint, false)
	if s.role == CapitalPlots.ROLE and BuildingTypes.over_water(s.art_tag):
		for r: Rect2 in City.current().rivers():
			if r.intersects(s.footprint):
				stamp(r.intersection(s.footprint), true)


## Stamp a standing building again: one people walk over opens its way, anything else closes its ground. For a
## fallen building rebuilt (v0.05) and a postern barred (Town.bar_postern()).
func refresh(s: Structure) -> void:
	if s.walkable:
		_open(s)
	else:
		_apply(s)


## A structure taken away (a thorn wall withering, v0.06): its ground opens as a fallen building's does.
func _reopen(s: Structure) -> void:
	_on_destroyed(s, &"")


## A building fell: its ground opens up (rubble is walkable), except a bridge, whose fall closes the river.
func _on_destroyed(s: Structure, _kind: StringName) -> void:
	if s in _bridges:
		for r: Rect2 in City.current().fallen_bridge(s.footprint):
			stamp(r, true)
		return
	stamp(solid_rect(s.footprint), false)
	# Freeing a footprint can free cells a standing neighbour or the river still needs, so put those back...
	var area := solid_rect(s.footprint).grow(CELL)
	for r: Rect2 in City.current().rivers():
		if area.intersects(r):
			stamp(area.intersection(r), true)
	for other in _env.structures():
		if other != s and is_instance_valid(other) and not other.destroyed and not other.walkable \
				and solid_rect(other.footprint).intersects(area):
			_apply(other)
	for g in _blockers:
		if g.intersects(area):
			stamp(g, true)
	# ...and then open the ways through again, so a gate beside a fallen wall stays passable.
	for other in _env.structures():
		if other != s and is_instance_valid(other) and not other.destroyed and other.walkable \
				and other.footprint.intersects(area):
			_open(other)
