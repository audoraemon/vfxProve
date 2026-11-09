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
## The most closed cells opened in a row to join a pocket of open ground to the streets (_join_pockets()).
const LINK_CELLS := 4
## How finely a link's steps are checked for a body's room (_room_between()).
const LINK_SAMPLE := 0.05

var grid := AStarGrid2D.new()
## Rises whenever a cell turns solid or free (stamp()): distance fields built on the grid rebuild on it.
var version := 0

var _env: EnvironmentField
## The town's crossings (Town.bridges).
var _bridges: Array[Structure] = []
## The city's blockers(), grown to the cells they close. Computed once: it lays out every house, garden and tree,
## far too slow to redo each time a building falls (a Cinderfall felling a dozen trees at once hitched ~100 ms).
var _blockers: Array[Rect2] = []
## The city's blockers() grown by a body only: what a body standing at a link's cell must keep out of.
var _fences: Array[Rect2] = []
## The solid cheeks of the passages (BuildingTypes.cheeks()): never opened for a link.
var _cheeks: Array[Rect2] = []
## The cells a piece of the town's decor stands in (TownDecor.spots(), baked into the floor or not): never opened for a
## link, so decor only stands where nobody walks (decor_clear()).
var _props := {}
## Cells opened by _join_pockets(): put back open whenever a fall re-stamps the ground round them.
var _links: Array[Vector2i] = []
## What _join_pockets() did, one [cells, centre, links opened (-1: none, left as it is)] per pocket (for the stall probe).
var pockets: Array = []
## The cells of the pockets _join_pockets() found no way out of: open ground with no route to the streets, as the grid
## was set up. on_streets() is false there, so the crowd places nobody in one.
var _off := {}


## `join_pockets` false leaves pockets of open ground the streets cannot reach as they are (tests of the rules for
## ground with no route; the game always joins them, _join_pockets()).
func setup(env: EnvironmentField, town: Town, join_pockets := true) -> WalkGrid:
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
		_fences.append(g.grow(BODY))
	for g in _blockers:
		stamp(g, true)
	# Two passes, because a building people walk over has to win against whatever else claimed its cells: the
	# gates sit inside the wall segments' grown footprints, and the bridge sits in the river.
	for s in env.structures():
		_apply(s)
	for s in env.structures():
		_open(s)
	if join_pockets:
		_join_pockets()
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


## Open ground with a route to the streets as the grid was set up: walkable, and not in a pocket _join_pockets() could
## not join.
func on_streets(g: Vector2) -> bool:
	return walkable(g) and not _off.has(world_to_id(g))


## `g` itself when it is free, otherwise the centre of the nearest free cell (searched in rings), or
## Vector2.INF when everything within max_cells is solid. `streets` counts a pocket's cells as solid (on_streets()).
func nearest_walkable(g: Vector2, max_cells := SNAP_CELLS, streets := false) -> Vector2:
	var id := world_to_id(g)
	if grid.is_in_boundsv(id) and not grid.is_point_solid(id) and not (streets and _off.has(id)):
		return g
	var fallback := Vector2.INF
	for r in range(1, max_cells + 1):
		var best := Vector2.INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := id + Vector2i(dx, dy)
				if not grid.is_in_boundsv(c) or grid.is_point_solid(c) or (streets and _off.has(c)):
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
			_cheeks.append(r)
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
		_reopen_links(solid_rect(s.footprint))


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
	_reopen_links(area)
	# ...and then open the ways through again, so a gate beside a fallen wall stays passable.
	for other in _env.structures():
		if other != s and is_instance_valid(other) and not other.destroyed and other.walkable \
				and other.footprint.intersects(area):
			_open(other)


## Open ground the streets cannot reach (a corner behind a garden, the yard behind the citadel): every pocket of open
## cells off the largest region, the streets, is joined to them through the fewest closed cells (at most LINK_CELLS) a
## body has room in -- shut only by a garden's half-cell grow or a thin thing's one-cell minimum, never a footprint's
## margin, a fence, the river, a passage's cheek or a piece of decor. A pocket with no such way out is left as it is,
## its cells remembered (on_streets() false there), so the crowd places nobody in it. Run once, at setup; pockets joined
## to each other first are joined as one.
func _join_pockets() -> void:
	var labels := PackedInt32Array()
	var regions := _label(labels)
	if regions.size() < 2:
		return
	for d: Dictionary in TownDecor.spots():
		var ext := Rect2(d.at, d.size).abs()
		var c0 := world_to_id(ext.position - Vector2.ONE * CELL)
		var c1 := world_to_id(ext.end + Vector2.ONE * CELL)
		for y in range(c0.y, c1.y + 1):
			for x in range(c0.x, c1.x + 1):
				if not decor_clear(Vector2i(x, y), d.at, d.size):
					_props[Vector2i(x, y)] = true
	var main := 0
	for k in regions.size():
		if regions[k].size() > regions[main].size():
			main = k
	var joined := {main: true}
	var left: Array[int] = []
	for k in regions.size():
		if k != main:
			left.append(k)
	left.sort_custom(func(a: int, b: int) -> bool: return regions[a].size() > regions[b].size())
	var grew := true
	while grew:
		grew = false
		for k in left.duplicate():
			var link := _link(regions[k], labels, joined)
			if link.is_empty():
				continue
			for id: Vector2i in link:
				grid.set_point_solid(id, false)
				_links.append(id)
				labels[(id.y - grid.region.position.y) * grid.region.size.x + (id.x - grid.region.position.x)] = main
			pockets.append([regions[k].size(), _centre(regions[k]), link.size()])
			joined[k] = true
			left.erase(k)
			grew = true
	for k in left:
		pockets.append([regions[k].size(), _centre(regions[k]), -1])
		for id: Vector2i in regions[k]:
			_off[id] = true
	version += 1


func _centre(cells: Array) -> Vector2:
	var sum := Vector2.ZERO
	for id: Vector2i in cells:
		sum += id_to_world(id)
	return sum / float(cells.size())


## Whether a cell may be walked beside a piece of decor at `at` (TownDecor.spots()): never the cell a point-sized piece
## stands in, and never one whose centre is within a body of a piece's ground (`size` from `at`: a bench's run). A
## bench's end just inside a cell leaves it free while a body at its centre keeps clear of the bench.
func decor_clear(id: Vector2i, at: Vector2, size: Vector2) -> bool:
	if size == Vector2.ZERO and world_to_id(at) == id:
		return false
	var ext := Rect2(at, size).abs()
	var c := id_to_world(id)
	return c.clamp(ext.position, ext.end).distance_to(c) > BODY


## Every 4-connected region of open cells (a route joins two cells only through such steps: a diagonal step needs both
## its sides open), largest first.
func regions() -> Array:
	var out := _label(PackedInt32Array())
	out.sort_custom(func(a: Array, b: Array) -> bool: return a.size() > b.size())
	return out


## The regions of open cells, each an Array[Vector2i], in scan order; `labels` (one per cell of the region, row by row)
## is filled with each cell's region index, -1 where solid.
func _label(labels: PackedInt32Array) -> Array:
	var reg := grid.region
	var w := reg.size.x
	labels.resize(reg.size.x * reg.size.y)
	labels.fill(-1)
	var out: Array = []
	for y in range(reg.position.y, reg.end.y):
		for x in range(reg.position.x, reg.end.x):
			var i := (y - reg.position.y) * w + (x - reg.position.x)
			if labels[i] >= 0 or grid.is_point_solid(Vector2i(x, y)):
				continue
			var comp: Array[Vector2i] = []
			var q: Array[Vector2i] = [Vector2i(x, y)]
			labels[i] = out.size()
			while not q.is_empty():
				var c: Vector2i = q.pop_back()
				comp.append(c)
				for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					var n := c + d
					if not grid.is_in_boundsv(n) or grid.is_point_solid(n):
						continue
					var j := (n.y - reg.position.y) * w + (n.x - reg.position.x)
					if labels[j] < 0:
						labels[j] = out.size()
						q.append(n)
			out.append(comp)
	return out


## The fewest closed cells (at most LINK_CELLS, a body having room all the way) leading from `comp` to a region in
## `joined`, by a breadth-first walk over the cells a link may open; empty when there is none.
func _link(comp: Array, labels: PackedInt32Array, joined: Dictionary) -> Array[Vector2i]:
	var reg := grid.region
	var from := {}
	var frontier: Array[Vector2i] = []
	for id: Vector2i in comp:
		from[id] = id
		frontier.append(id)
	for depth in LINK_CELLS + 1:
		var next: Array[Vector2i] = []
		for c in frontier:
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				var n := c + d
				if from.has(n) or not grid.is_in_boundsv(n):
					continue
				if not grid.is_point_solid(n):
					var lab := labels[(n.y - reg.position.y) * reg.size.x + (n.x - reg.position.x)]
					if joined.has(lab) and depth > 0 and _room_between(id_to_world(c), id_to_world(n)):
						var out: Array[Vector2i] = []
						var k := c
						while from[k] != k:
							out.append(k)
							k = from[k]
						return out
					continue
				if depth < LINK_CELLS and not _props.has(n) and _room_at(id_to_world(n)) and _room_between(id_to_world(c), id_to_world(n)):
					from[n] = c
					next.append(n)
		frontier = next
	return [] as Array[Vector2i]


## Whether a body may stand at `g`: clear of every standing footprint's margin, every fence, the river and the cheeks.
func _room_at(g: Vector2) -> bool:
	if _env.blocked(g, BODY):
		return false
	for r: Rect2 in _fences:
		if r.has_point(g):
			return false
	for r: Rect2 in City.current().rivers():
		if r.has_point(g):
			return false
	for r: Rect2 in _cheeks:
		if r.has_point(g):
			return false
	return true


## Whether a body walking straight from `a` to `b` keeps room all the way (the ends excepted: either may be open
## ground already).
func _room_between(a: Vector2, b: Vector2) -> bool:
	var n := maxi(ceili(a.distance_to(b) / LINK_SAMPLE), 1)
	for k in range(1, n):
		if not _room_at(a.lerp(b, float(k) / float(n))):
			return false
	return true


## The links inside `area` opened again, where a body still has room (a wall added since closes one for good).
func _reopen_links(area: Rect2) -> void:
	for id in _links:
		var g := id_to_world(id)
		if area.has_point(g) and grid.is_point_solid(id) and not _env.blocked(g, BODY):
			grid.set_point_solid(id, false)
			version += 1
