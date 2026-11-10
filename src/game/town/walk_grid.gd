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
const STEPS4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)]

var grid := AStarGrid2D.new()
## Rises whenever a cell turns solid or free (stamp()): distance fields built on the grid rebuild on it.
var version := 0

var _env: EnvironmentField
## The town's crossings (Town.bridges).
var _bridges: Array[Structure] = []
## The city's blockers(), grown to the cells they close. Computed once: it lays out every house, garden and tree,
## far too slow to redo each time a building falls (a Cinderfall felling a dozen trees at once hitched ~100 ms).
var _blockers: Array[Rect2] = []
## The street piles' cells, a layer over the ground (Vector2i -> whether the ground under the pile is closed): a pile cell is
## solid until the guards dig it out; whatever stamps it meanwhile (a neighbour freed, a thorn wall, a restore) changes the
## ground under it, which is what the cell becomes when the pile goes.
var _piles := {}
## Called (no arguments) after anything closes cells while the town stands: a bridge falls, a structure is added, restored
## or barred. PileManager re-checks its gap rule on it. One callable, set by the crowd's PileManager.
var on_closed := Callable()
## A pile's gap cells (Vector2i -> pace factor): open, but crossed at a crawl.
var _slow := {}

## The pace a person keeps crossing a pile's gap.
const SLOW_CROSSING := 0.3


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


## The open cell to step out to from `g`, standing on a closed cell in `r` (a falling footprint, a pile cell): the nearest open
## cell reached from `g` by going only through closed cells inside `r` grown by a cell -- so out over the footprint's own edge,
## on the street's side, never through a fence, a garden or a wall beyond it. Searched in rings of 4-way steps (A* only
## cuts a corner where nothing is in its way), nearest first, ties by (y, x). `g` itself when it is open; Vector2.INF when no
## open cell borders the footprint (searched at least SNAP_CELLS steps, and across the whole of `r`).
func step_out_of(g: Vector2, r: Rect2) -> Vector2:
	var id := world_to_id(g)
	if grid.is_in_boundsv(id) and not grid.is_point_solid(id):
		return g
	var inside := r.grow(CELL)
	var seen := {id: true}
	var ring: Array[Vector2i] = [id]
	var steps := maxi(SNAP_CELLS, ceili(maxf(r.size.x, r.size.y) / CELL) + 2)
	for step in steps:
		var next: Array[Vector2i] = []
		var best := Vector2i.MAX
		var best_d := INF
		for c in ring:
			for d4 in STEPS4:
				var n := c + d4
				if seen.has(n) or not grid.is_in_boundsv(n):
					continue
				seen[n] = true
				var w := id_to_world(n)
				if not grid.is_point_solid(n):
					var d := w.distance_squared_to(g)
					if d < best_d or (d == best_d and (n.y < best.y or (n.y == best.y and n.x < best.x))):
						best = n
						best_d = d
				elif inside.has_point(w):
					next.append(n)
		if best != Vector2i.MAX:
			return id_to_world(best)
		if next.is_empty():
			break
		ring = next
	return Vector2.INF


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
				if _piles.has(id):
					_piles[id] = solid  # under a pile: the ground changes, the pile still closes the cell
				else:
					grid.set_point_solid(id, solid)


## A standing building that blocks: its footprint, grown by a body's width, is solid.
func _apply(s: Structure) -> void:
	if not is_instance_valid(s) or (s.destroyed and not s.leaves_ruin()) or s.walkable:
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
## BuildingTypes.OVER_WATER, the ferry landing) is open on its dry part only: the river under it stays closed. One
## walked through a passage (a capital set: BuildingTypes.PASSAGE, the Keep's gate, the alley steps) is open there
## only: its cheeks either side are solid, as they stand (not grown by a body, which would close the passage too).
func _open(s: Structure) -> void:
	if not is_instance_valid(s) or s.destroyed or not s.walkable:
		return
	stamp(s.footprint, false)
	if s.role == CapitalPlots.ROLE:
		for r: Rect2 in BuildingTypes.cheeks(s.art_tag, s.footprint):
			stamp(r, true)
	if s.role == CapitalPlots.ROLE and BuildingTypes.over_water(s.art_tag):
		for r: Rect2 in City.current().rivers():
			if r.intersects(s.footprint):
				stamp(r.intersection(s.footprint), true)


## A street pile closes (on) or opens (off) these cells. Off gives the cell back the ground under the pile: one something
## else closed while the pile lay there (a thorn wall, a restored stall) stays closed.
func set_pile(ids: Array[Vector2i], on: bool) -> void:
	for id in ids:
		if not grid.is_in_boundsv(id):
			if on:
				_piles[id] = true
			else:
				_piles.erase(id)
			continue
		if on:
			if not _piles.has(id):
				_piles[id] = grid.is_point_solid(id)
			grid.set_point_solid(id, true)
		elif _piles.has(id):
			grid.set_point_solid(id, bool(_piles[id]))
			_piles.erase(id)
	version += 1


func is_pile(id: Vector2i) -> bool:
	return _piles.has(id)


## Whether the ground at `id` is open, a pile on it left aside.
func ground_open(id: Vector2i) -> bool:
	if not grid.is_in_boundsv(id):
		return false
	if _piles.has(id):
		return not bool(_piles[id])
	return not grid.is_point_solid(id)


## Make `id` a slow crossing (factor < 1: the route costs 1/factor there, people walk at that share of their pace);
## factor 1.0 puts it back to an ordinary cell.
func set_slow(id: Vector2i, factor: float) -> void:
	if not grid.is_in_boundsv(id):
		return
	if factor < 1.0:
		_slow[id] = factor
		grid.set_point_weight_scale(id, 1.0 / factor)
	else:
		_slow.erase(id)
		grid.set_point_weight_scale(id, 1.0)


## The share of his pace a person keeps standing at `g` (1.0 at once when no cell is slow).
func pace_at(g: Vector2) -> float:
	if _slow.is_empty():
		return 1.0
	return float(_slow.get(world_to_id(g), 1.0))


## Whether there is a route from `from` to `to`.
func reaches(from: Vector2, to: Vector2) -> bool:
	return not path(from, to).is_empty()


## Stamp a standing building again: one people walk over opens its way, anything else closes its ground. For a
## fallen building rebuilt (v0.05) and a postern barred (Town.bar_postern()).
func refresh(s: Structure) -> void:
	if s.walkable:
		_open(s)
	else:
		_apply(s)
	_closed()


## Cells closed after the town was laid out: tell the piles (their gap rule is re-checked once per such event).
func _closed() -> void:
	if on_closed.is_valid():
		on_closed.call()


## A structure taken away (a thorn wall withering, v0.06): its ground opens, a ruin's too.
func _reopen(s: Structure) -> void:
	if s in _bridges:
		_on_destroyed(s, &"")
		return
	_free_ground(s)


## A structure fell: a bridge closes the river; a building (leaves_ruin()) stays a blocked ruin; anything else opens
## its ground (rubble is walkable).
func _on_destroyed(s: Structure, _kind: StringName) -> void:
	if s in _bridges:
		for r: Rect2 in City.current().fallen_bridge(s.footprint):
			stamp(r, true)
		_closed()
		return
	if s.leaves_ruin():
		return
	_free_ground(s)


func _free_ground(s: Structure) -> void:
	stamp(solid_rect(s.footprint), false)
	# Freeing a footprint can free cells a standing neighbour or the river still needs, so put those back...
	var area := solid_rect(s.footprint).grow(CELL)
	for r: Rect2 in City.current().rivers():
		if area.intersects(r):
			stamp(area.intersection(r), true)
	for other in _env.structures():
		if other != s and is_instance_valid(other) and (not other.destroyed or other.leaves_ruin()) \
				and not other.walkable \
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
