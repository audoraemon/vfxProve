class_name PileManager
extends RefCounted
## Street piles (soldier jobs): when a building falls (Structure.leaves_ruin()) its rubble spills onto the street beside
## it as a pile of one to three cells that closes the way until the guards dig it out. This file chooses the cells,
## places and clears the piles and draws them; the digging itself is stepped here later (step()).

const MAX_CELLS := 3
## A pile's gap cell when no gap has been left in it (the gap check, a later task).
const NO_GAP := Vector2i(-2147483648, -2147483648)
const STONE := [Color("6a6a70"), Color("55555c"), Color("46464c")]
const SIDES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]


class Pile:
	var cells: Array[Vector2i] = []
	var gap := PileManager.NO_GAP
	var site: Structure
	## Dug out so far, 0..1.
	var work := 0.0
	var diggers: Array = []
	## digger -> his assigned dig spot (a Vector2), in the order he took it.
	var spots := {}
	## [PackedVector2Array in screen points, Color]; the first `ceili(size * (1 - work))` are drawn.
	var pieces: Array = []


class PileLayer extends Node2D:
	var mgr: PileManager
	## How many times a redraw was asked for (the tests count it: a pile is drawn when it changes, never every frame).
	var redraws := 0

	func redraw() -> void:
		redraws += 1
		queue_redraw()

	func _draw() -> void:
		if mgr == null:
			return
		for p: Pile in mgr.piles:
			for i in PileManager.visible_pieces(p):
				var piece: Array = p.pieces[i]
				draw_colored_polygon(piece[0], piece[1])


var piles: Array[Pile] = []
var layer: PileLayer
var _crowd: Crowd
var _env: EnvironmentField
var _grid: WalkGrid
var _rng := RandomNumberGenerator.new()
## Pile -> how many pieces were last drawn.
var _shown := {}


func setup(crowd: Crowd, env: EnvironmentField, grid: WalkGrid) -> PileManager:
	_crowd = crowd
	_env = env
	_grid = grid
	_rng.seed = crowd._seed + 53
	return self


## The draw layer, made once, under the people like the ground drawer.
func attach(parent: Node2D) -> void:
	if layer != null and is_instance_valid(layer):
		return
	layer = PileLayer.new()
	layer.name = "PileLayer"
	layer.z_index = -3
	layer.mgr = self
	parent.add_child(layer)


static func visible_pieces(p: Pile) -> int:
	return ceili(p.pieces.size() * (1.0 - p.work))


static func _cell_rect(id: Vector2i) -> Rect2:
	return Rect2(Vector2(id) * WalkGrid.CELL, Vector2(WalkGrid.CELL, WalkGrid.CELL))


func _open_cell(id: Vector2i) -> bool:
	return _grid.grid.is_in_boundsv(id) and not _grid.grid.is_point_solid(id)


## Up to three cells in a straight line out from the side of `s` with the most open street along it.
func cells_for(s: Structure) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var longest := maxf(s.footprint.size.x, s.footprint.size.y)
	var n := 3 if longest >= 2.0 else (2 if longest >= 1.0 else 1)
	var sr := WalkGrid.solid_rect(s.footprint)
	var c := WalkGrid.CELL
	# The cells whose centres lie in the solid rect.
	var ix0 := ceili((sr.position.x - c * 0.5) / c)
	var ix1 := floori((sr.end.x - c * 0.5) / c)
	var iy0 := ceili((sr.position.y - c * 0.5) / c)
	var iy1 := floori((sr.end.y - c * 0.5) / c)
	var mid := _grid.world_to_id(sr.get_center())
	# A footprint too thin to hold a cell centre: start from the midpoint cell.
	if ix0 > ix1:
		ix0 = mid.x
		ix1 = mid.x
	if iy0 > iy1:
		iy0 = mid.y
		iy1 = mid.y
	var best := -1
	var best_side := 0
	for side in 4:
		var d := SIDES[side]
		var score := 0
		for depth in range(1, 4):
			if d.y != 0:
				var y := (iy1 if d.y > 0 else iy0) + d.y * depth
				for x in range(ix0, ix1 + 1):
					if _open_cell(Vector2i(x, y)):
						score += 1
			else:
				var x := (ix1 if d.x > 0 else ix0) + d.x * depth
				for y in range(iy0, iy1 + 1):
					if _open_cell(Vector2i(x, y)):
						score += 1
		if score > best:
			best = score
			best_side = side
	var dir := SIDES[best_side]
	var start: Vector2i
	if dir.y != 0:
		start = Vector2i(mid.x, (iy1 if dir.y > 0 else iy0) + dir.y)
	else:
		start = Vector2i((ix1 if dir.x > 0 else ix0) + dir.x, mid.y)
	var walk := _walkable_footprints()
	var rivers := City.current().rivers()
	var exits := _exit_cells()
	for k in n:
		var id := start + dir * k
		if not _open_cell(id) or _in_any(id, walk) or _in_any(id, rivers) or exits.has(id):
			break
		out.append(id)
	return out


func _walkable_footprints() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for s in _env.structures():
		if is_instance_valid(s) and s.walkable:
			out.append(s.footprint)
	return out


func _in_any(id: Vector2i, rects: Array[Rect2]) -> bool:
	var g := _grid.id_to_world(id)
	for r in rects:
		if r.has_point(g):
			return true
	return false


func _exit_cells() -> Dictionary:
	var out := {}
	var city := City.current()
	for g: Vector2 in city.exits():
		out[_grid.world_to_id(g)] = true
	for g: Vector2 in city.gate_exits():
		out[_grid.world_to_id(g)] = true
	return out


## A pile on `cells` (those still open), dropped by `site` or plain stone. Null when no cell is left.
func place(cells: Array[Vector2i], site: Structure = null) -> Pile:
	var p := Pile.new()
	for id in cells:
		if _open_cell(id):
			p.cells.append(id)
	if p.cells.is_empty():
		return null
	p.site = site
	_grid.set_pile(p.cells, true)
	for id in p.cells:
		_crowd.clear_ground(_cell_rect(id))
	var area := _cell_rect(p.cells[0])
	for id in p.cells:
		area = area.merge(_cell_rect(id))
	var pal: Array = STONE
	if site != null and is_instance_valid(site):
		pal = site._palette()
	p.pieces = Structure.rubble_polys(area.grow(0.1), Vector2.ZERO, pal, clampi(p.cells.size() * 5, 5, 15), _rng)
	piles.append(p)
	_shown[p] = p.pieces.size()
	_redraw()
	return p


func on_fall(s: Structure) -> void:
	if s.leaves_ruin():
		place(cells_for(s), s)


func clear_pile(p: Pile) -> void:
	_grid.set_pile(p.cells, false)
	piles.erase(p)
	_shown.erase(p)
	_redraw()


func step(_delta: float) -> void:
	var changed := false
	for p in piles:
		var v := visible_pieces(p)
		if _shown.get(p, -1) != v:
			_shown[p] = v
			changed = true
	if changed:
		_redraw()


## Every pile cell opens again, the list empties (a restart).
func clear() -> void:
	for p in piles:
		_grid.set_pile(p.cells, false)
	piles.clear()
	_shown.clear()
	_redraw()


## The draw layer goes with the crowd's other drawers.
func free_layer() -> void:
	if layer != null and is_instance_valid(layer):
		layer.queue_free()
	layer = null


func _redraw() -> void:
	if layer != null and is_instance_valid(layer):
		layer.redraw()
