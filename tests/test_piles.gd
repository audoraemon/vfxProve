extends RefCounted
## Soldier jobs, decision 5: a fallen building drops a street pile on the walkable ground beside it (1..3 cells) that
## blocks the way until the guards dig it out.


const Corps := preload("res://tests/test_corps.gd")
const GJ := preload("res://tests/test_guard_jobs.gd")
const CapPeople := preload("res://tests/test_capital_people.gd")


static func _crowd() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _free(made: Array) -> void:
	(made[2] as Node).free()
	(made[5] as Node).free()


## The first house with a street beside it.
static func _house_with_street(crowd: Crowd, env: EnvironmentField) -> Structure:
	for s in env.structures():
		if s.role == &"house" and s.leaves_ruin() and not crowd.piles.cells_for(s).is_empty():
			return s
	return null


static func run(t) -> void:
	_rubble_same(t)
	_pile_drops(t)
	_no_pile(t)
	_cells_valid_everywhere(t)
	_pile_pushes(t)
	_pile_survives_neighbour(t)
	_clear_resets(t)
	_drawn(t)
	_gap_rule(t)
	_detour_no_gap(t)
	_mission_point(t)
	_slow_pace(t)
	_once_per_fall(t)
	_one_route_read(t)
	_island_first_point(t)
	_all_slow_fallback(t)
	_overlap_clear(t)
	_guards_dig(t)
	_one_digger(t)
	_too_early(t)
	_fire_first(t)
	_stranded_digger(t)
	_held_digger(t)
	_taken_digger(t)
	_squads_after_rally(t)
	_trapped_first(t)
	_capital_pile(t)
	City.use(&"aldermere")


## Pins the rng order of the building rubble: Structure.rubble_polys() must give exactly what _build_rubble() always did.
static func _rubble_same(t) -> void:
	City.use(&"aldermere")
	var s := Structure.new().setup(Rect2(0, 0, 2.0, 1.5), 3.0, Structure.Kind.HOUSE, 12345)
	s.destroy(Vector2.ZERO, &"stone")
	var r: Array = s._rubble
	t.check(r.size() == 26, "the rubble pile count is as ever (%d)" % r.size())
	var p0: Vector2 = r[0][0][0]
	t.near(p0.x, -36.72108, 0.001, "the first rubble point x")
	t.near(p0.y, -32.82147, 0.001, "the first rubble point y")
	t.check((r[0][1] as Color).to_html() == "7a6a58ff", "the first rubble colour")
	s.free()


static func _pile_drops(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var house := _house_with_street(crowd, env)
	t.check(house != null, "a house has a street beside it")
	var cells := crowd.piles.cells_for(house)
	var open := true
	for id in cells:
		open = open and grid.walkable(grid.id_to_world(id))
	t.check(open, "the pile cells are open before the fall")
	house.destroy(Vector2.ZERO, &"stone")
	t.check(crowd.piles.piles.size() == 1, "a fallen house drops one pile")
	var p: PileManager.Pile = crowd.piles.piles[0]
	t.check(p.cells.size() >= 1 and p.cells.size() <= 3, "a pile is 1..3 cells (%d)" % p.cells.size())
	t.check(p.cells == cells, "the pile sits on the cells chosen")
	var shut := true
	for id in p.cells:
		if id != p.gap:
			shut = shut and not grid.walkable(grid.id_to_world(id)) and grid.is_pile(id)
	t.check(shut, "every pile cell is closed")
	var reach := WalkGrid.solid_rect(house.footprint).grow(WalkGrid.CELL)
	t.check(reach.has_point(grid.id_to_world(p.cells[0])), "the first cell touches the house")
	var line := true
	if p.cells.size() > 1:
		var unit: Vector2i = p.cells[1] - p.cells[0]
		line = absi(unit.x) + absi(unit.y) == 1
		for i in range(1, p.cells.size()):
			line = line and p.cells[i] - p.cells[0] == unit * i
	t.check(line, "the cells form a straight line outward")
	_free(made)


static func _no_pile(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var done := {}
	for s in env.structures():
		for role in [&"tower", &"market", &"decor"]:
			if s.role == role and not done.has(role):
				done[role] = true
				s.destroy(Vector2.ZERO, &"stone")
	t.check(done.size() == 3, "a tower, a stall and a tree fell")
	t.check(crowd.piles.piles.is_empty(), "a tower, a stall, a tree drop no pile")
	_free(made)


static func _cells_valid_everywhere(t) -> void:
	for city in [&"aldermere", &"capital"]:
		City.use(city)
		var made := _crowd()
		var crowd: Crowd = made[0]
		var env: EnvironmentField = made[1]
		var grid: WalkGrid = made[4]
		var walk: Array[Rect2] = []
		for s in env.structures():
			if s.walkable:
				walk.append(s.footprint)
		var rivers := City.current().rivers()
		var total := 0
		var got := 0
		var bad := []
		for s in env.structures():
			if not s.leaves_ruin():
				continue
			total += 1
			var cells := crowd.piles.cells_for(s)
			if not cells.is_empty():
				got += 1
			if cells.size() > 3:
				bad.append("%s size" % s.art_tag)
			for id in cells:
				var g := grid.id_to_world(id)
				var ok := grid.walkable(g)
				for r in walk:
					ok = ok and not r.has_point(g)
				for r in rivers:
					ok = ok and not r.has_point(g)
				if not ok:
					bad.append("%s %s" % [s.art_tag, id])
		t.check(bad.is_empty(), "%s: every pile cell is open street %s" % [city, bad])
		var share := float(got) / maxf(total, 1)
		print("pile cells: %s %d of %d buildings get a pile (%.0f%%)" % [city, got, total, share * 100.0])
		# 80% is the brief's tunable: Aldermere packs 25 of its 81 houses between gardens and fences (no open street on
		# the chosen side), so the floor is 70% there; the Capital clears 90%.
		var min_share := 0.7 if city == &"aldermere" else 0.9
		t.check(total > 0 and share >= min_share, "%s: at least %.0f%% of buildings get a pile (%.2f)" % [city, min_share * 100.0, share])
		_free(made)
	City.use(&"aldermere")


static func _pile_pushes(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var house := _house_with_street(crowd, env)
	var cells := crowd.piles.cells_for(house)
	var a: Person = crowd.citizens[0]
	a.inside = false
	a.ground_pos = grid.id_to_world(cells[0])
	house.destroy(Vector2.ZERO, &"stone")
	t.check(not grid.walkable(grid.id_to_world(cells[0])), "the pile closed the cell")
	t.check(grid.walkable(a.ground_pos), "a citizen on the pile cell ends on open ground")
	_free(made)


static func _pile_survives_neighbour(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var house := _house_with_street(crowd, env)
	house.destroy(Vector2.ZERO, &"stone")
	var p: PileManager.Pile = crowd.piles.piles[0]
	grid._free_ground(house)
	var shut := true
	for id in p.cells:
		shut = shut and not grid.walkable(grid.id_to_world(id))
	t.check(shut, "freeing the ground around a pile keeps it closed")
	# A block standing on the pile falls: its freed footprint does not open the pile.
	var c := grid.id_to_world(p.cells[0])
	var block := env.add_structure(Rect2(c - Vector2(0.2, 0.2), Vector2(0.4, 0.4)), 1.0, Structure.Kind.BLOCK)
	block.destroy(Vector2.ZERO, &"stone")
	t.check(not grid.walkable(c) and grid.is_pile(p.cells[0]), "a block falling on a pile does not open it")
	_free(made)


static func _clear_resets(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var house := _house_with_street(crowd, env)
	var cells := crowd.piles.cells_for(house)
	house.destroy(Vector2.ZERO, &"stone")
	var p: PileManager.Pile = crowd.piles.piles[0]
	crowd.piles.clear_pile(p)
	var open := true
	for id in cells:
		open = open and grid.walkable(grid.id_to_world(id)) and not grid.is_pile(id)
	t.check(open and crowd.piles.piles.is_empty(), "clear_pile() opens its cells")
	var second := crowd.piles.place(cells)
	t.check(second != null and not grid.walkable(grid.id_to_world(cells[0])), "a stone pile closes its cells")
	t.check(crowd.piles.place([] as Array[Vector2i]) == null, "no cells, no pile")
	crowd.piles.clear()
	open = true
	for id in cells:
		open = open and grid.walkable(grid.id_to_world(id)) and not grid.is_pile(id)
	t.check(open and crowd.piles.piles.is_empty(), "clear() opens every pile cell and empties the list")
	_free(made)


static func _drawn(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var house := _house_with_street(crowd, env)
	var layer: PileManager.PileLayer = crowd.piles.layer
	t.check(layer != null and layer.z_index == -3, "the pile layer is under the people")
	house.destroy(Vector2.ZERO, &"stone")
	var p: PileManager.Pile = crowd.piles.piles[0]
	t.check(p.pieces.size() >= 5, "a pile has at least five pieces (%d)" % p.pieces.size())
	var before := layer.redraws
	for i in 60:
		crowd.advance(1.0 / 60.0)
	t.check(layer.redraws == before, "a quiet pile is not redrawn (%d new)" % (layer.redraws - before))
	_free(made)


const BRIDGE: Array[Vector2i] = [Vector2i(3, 44), Vector2i(4, 44), Vector2i(5, 44), Vector2i(6, 44)]


static func _bridge_walkable(grid: WalkGrid) -> int:
	var n := 0
	for id in BRIDGE:
		if grid.walkable(grid.id_to_world(id)):
			n += 1
	return n


## The bridge's four cells carry the only way from the temple to the first exit: a pile on them leaves one slow crossing.
static func _gap_rule(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var from: Vector2 = TownLayout.TEMPLE.get_center() + Vector2(0, 3)
	var to: Vector2 = TownLayout.EXITS[0]
	t.check(_bridge_walkable(grid) == 4, "the four bridge cells are walkable")
	t.check(grid.reaches(from, to), "the temple reaches the exit before the pile")
	var p := crowd.piles.place(BRIDGE.duplicate())
	t.check(p != null and _bridge_walkable(grid) == 1, "a pile on the bridge leaves exactly one cell walkable (%d)" % _bridge_walkable(grid))
	var gap: Vector2i = p.gap
	t.check(gap != PileManager.NO_GAP and BRIDGE.has(gap) and grid.walkable(grid.id_to_world(gap)), "the pile names its gap")
	t.near(grid.pace_at(grid.id_to_world(gap)), WalkGrid.SLOW_CROSSING, 0.0001, "the gap is a slow crossing")
	t.near(grid.grid.get_point_weight_scale(gap), 1.0 / WalkGrid.SLOW_CROSSING, 0.0001, "the route weighs the gap by its slowness")
	t.check(grid.reaches(from, to), "the temple still reaches the exit through the gap")
	# A second pile on the gap itself is left open as a crossing too.
	var q := crowd.piles.place([gap] as Array[Vector2i])
	t.check(q != null and q.gap == gap and grid.walkable(grid.id_to_world(gap)), "a second pile on the gap is itself left open")
	t.check(grid.reaches(from, to), "two piles still leave the route")
	crowd.piles.clear_pile(q)
	crowd.piles.clear_pile(p)
	t.check(_bridge_walkable(grid) == 4, "clearing the pile opens every cell")
	t.near(grid.pace_at(grid.id_to_world(gap)), 1.0, 0.0001, "the crossing is ordinary again")
	_free(made)


static func _detour_no_gap(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var id := grid.world_to_id(TownLayout.MARKET_SQUARE.get_center())
	var before := crowd.piles.gap_checks
	var p := crowd.piles.place([id] as Array[Vector2i])
	t.check(p != null and p.gap == PileManager.NO_GAP, "a pile in an open square leaves no gap")
	t.check(crowd.piles.gap_checks == before, "a way round needs no key-point check")
	_free(made)


static func _mission_point(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var pt: Vector2 = grid.id_to_world(grid.world_to_id(TownLayout.MARKET_SQUARE.get_center()))
	var base := crowd.route_points()
	crowd.mission_points.append(func() -> Array[Vector2]: return [pt] as Array[Vector2])
	var got := crowd.route_points()
	t.check(got.size() == base.size() + 1 and got.has(pt), "a mission's point joins the route points")
	crowd.clear_mission_hooks()
	t.check(crowd.route_points().size() == base.size(), "clear_mission_hooks() removes it")
	_free(made)


static func _slow_pace(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var p := crowd.piles.place(BRIDGE.duplicate())
	var s: Person = crowd.soldiers[0]
	s.ground_pos = grid.id_to_world(p.gap)
	var slow := s._mind_speed()
	s.ground_pos = grid.id_to_world(p.gap) + Vector2(0, 5)
	var fast := s._mind_speed()
	t.check(fast > 0.0 and absf(slow - fast * WalkGrid.SLOW_CROSSING) < 0.0001, "a soldier on the gap walks at 0.3 of his pace (%f of %f)" % [slow, fast])
	_free(made)


static func _once_per_fall(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var before := crowd.piles.gap_checks
	crowd.piles.place(BRIDGE.duplicate())
	var after := crowd.piles.gap_checks
	t.check(after == before + 1, "the pile on the bridge cost one key-point check (%d)" % (after - before))
	for i in 120:
		crowd.advance(1.0 / 60.0)
	t.check(crowd.piles.gap_checks == after, "no further checks while time passes")
	_free(made)


## The route points are read once per pile placed, not once per candidate gap cell.
static func _one_route_read(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var calls := [0]
	crowd.mission_points.append(func() -> Array[Vector2]:
		calls[0] += 1
		return [] as Array[Vector2])
	var p := crowd.piles.place(BRIDGE.duplicate())
	t.check(p != null and p.gap != PileManager.NO_GAP, "the bridge pile found its gap")
	t.check(calls[0] == 1, "the route points were read once for the whole placement (%d)" % calls[0])
	crowd.clear_mission_hooks()
	_free(made)


## The first route point sits in a closed-off island: the seal is still found between the points that share the rest of town.
static func _island_first_point(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var first := grid.world_to_id(crowd.route_points()[0])
	for d in PileManager.SIDES:
		if grid.grid.is_in_boundsv(first + d):
			grid.grid.set_point_solid(first + d, true)
	var far := grid.id_to_world(Vector2i(4, 54))
	crowd.mission_points.append(func() -> Array[Vector2]: return [far] as Array[Vector2])
	var from: Vector2 = TownLayout.TEMPLE.get_center() + Vector2(0, 3)
	t.check(not grid.reaches(grid.id_to_world(first), from), "the first route point is an island")
	t.check(grid.reaches(far, from), "the point south of the bridge reaches the temple")
	var p := crowd.piles.place(BRIDGE.duplicate())
	t.check(p != null and p.gap != PileManager.NO_GAP, "the seal is found although the first point is an island")
	t.check(grid.reaches(far, from), "the bridge is still crossable")
	crowd.clear_mission_hooks()
	_free(made)


## Two rows of the bridge: no single cell opens the way, so every cell is a slow crossing and the pile is still drawn.
static func _all_slow_fallback(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var cells: Array[Vector2i] = []
	for id in BRIDGE:
		cells.append(id)
		cells.append(id + Vector2i(0, 1))
	var from: Vector2 = TownLayout.TEMPLE.get_center() + Vector2(0, 3)
	var p := crowd.piles.place(cells)
	t.check(p != null and p.cells.size() == 8, "a two-row pile on the bridge")
	var open := 0
	var slow := 0
	for id in p.cells:
		if grid.walkable(grid.id_to_world(id)):
			open += 1
		if is_equal_approx(grid.pace_at(grid.id_to_world(id)), WalkGrid.SLOW_CROSSING):
			slow += 1
	t.check(open == 8 and slow == 8, "no single gap works: all cells open slow (%d open, %d slow)" % [open, slow])
	t.check(p.gap != PileManager.NO_GAP and p.cells.has(p.gap), "the pile names a gap")
	t.check(not p.pieces.is_empty() and PileManager.visible_pieces(p) == p.pieces.size(), "the pile is still drawn")
	t.check(grid.reaches(from, TownLayout.EXITS[0]), "the route is open")
	crowd.piles.clear()
	t.check(grid._slow.is_empty(), "clear() leaves no slow cell")
	_free(made)


## Clearing a pile does not reopen a cell another pile still holds closed.
static func _overlap_clear(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var open: Array[Vector2i] = []
	var c0 := grid.world_to_id(TownLayout.MARKET_SQUARE.get_center())
	for r in range(0, 8):
		for dx in range(-r, r + 1):
			var id := c0 + Vector2i(dx, r)
			if grid.walkable(grid.id_to_world(id)) and open.size() < 6:
				open.append(id)
	t.check(open.size() == 6, "six open cells in the square")
	var a := crowd.piles.place([open[0], open[1]] as Array[Vector2i])
	var b := crowd.piles.place([open[5]] as Array[Vector2i])
	t.check(a != null and b != null, "two piles")
	# b also holds a's second cell (as when it was placed on a's gap).
	b.cells.append(open[1])
	crowd.piles.clear_pile(a)
	t.check(not grid.walkable(grid.id_to_world(open[1])) and grid.is_pile(open[1]), "a cell another pile holds stays closed")
	t.check(grid.walkable(grid.id_to_world(open[0])), "and the rest of the cleared pile opens")
	crowd.piles.clear()
	t.check(grid.walkable(grid.id_to_world(open[1])), "clear() opens it")
	_free(made)


# --- clearing: guards dig, idle rescue squads after the rally -------------------------------------------------------

## The house nearest the barracks yard that has a street beside it, with a stone pile on its cells.
static func _yard_pile(crowd: Crowd, env: EnvironmentField) -> PileManager.Pile:
	var c: Vector2 = City.current().landmark(&"barracks_yard").get_center()
	var best: Structure = null
	for s in env.structures():
		if s.kind == Structure.Kind.HOUSE and s.role == &"house" and not s.destroyed and not crowd.piles.cells_for(s).is_empty():
			if best == null or s.center().distance_to(c) < best.center().distance_to(c):
				best = s
	return crowd.piles.place(crowd.piles.cells_for(best))


## Everybody walking arrives at his goal.
static func _arrive(people: Array) -> void:
	for p: Person in people:
		if is_instance_valid(p) and p.has_goal():
			p.ground_pos = p.goal()
			p._goal = Vector2.INF
			p._path = PackedVector2Array()


static func _run(crowd: Crowd, seconds: float) -> void:
	for i in int(seconds * 60.0):
		crowd.piles.step(1.0 / 60.0)


static func _open_pile(grid: WalkGrid, pile: PileManager.Pile) -> bool:
	for id in pile.cells:
		if not grid.walkable(grid.id_to_world(id)):
			return false
	return true


static func _guards_dig(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	crowd.alarms.stage = crowd.profile.fire_from
	var pile := _yard_pile(crowd, made[1])
	var n := crowd.guard_jobs.free_near(crowd.piles.centre(pile), PileManager.REACH).size()
	t.check(n >= 4, "guards stand near the pile (%d)" % n)
	crowd.piles.step(1.0)
	t.check(pile.diggers.size() == mini(PileManager.DIGGERS, ceili(n * 0.5)), "half the guards near it dig, at most two (%d of %d)" % [pile.diggers.size(), n])
	var diggers: Array = pile.diggers.duplicate()
	var jobs_ok := true
	for d: Person in diggers:
		jobs_ok = jobs_ok and d.corps == Person.Corps.NONE and crowd.guard_jobs.job_of(d) == pile and d.anchor.is_equal_approx(pile.spots[d])
	t.check(jobs_ok, "each is an ordinary guard on the pile's job, sent to his spot")
	_arrive(diggers)
	_run(crowd, 1.0)
	var shown := true
	var posed := true
	for d: Person in diggers:
		shown = shown and d.dig_shown > 0.0
		if d._own_art(15):
			posed = posed and d._sprite_pose()[0] == &"dig"
	t.check(shown and posed, "at their spots they dig")
	t.check(crowd.piles.piles.size() == 1, "the pile still stands")
	_run(crowd, PileManager.SECONDS)
	t.check(crowd.piles.piles.is_empty() and _open_pile(grid, pile), "twenty seconds, two diggers: the pile is gone and its cells walk")
	var home := true
	for d: Person in diggers:
		home = home and d.mind == Person.Mind.POST and d.anchor.is_equal_approx(d.post) and not crowd.guard_jobs.on_job(d)
	t.check(home, "the diggers go back to their posts")
	Corps._done(made)


static func _one_digger(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	crowd.alarms.stage = crowd.profile.fire_from
	var pile := _yard_pile(crowd, made[1])
	crowd.piles.step(1.0)
	var keep: Person = pile.diggers[0]
	for i in range(pile.diggers.size() - 1, 0, -1):
		var d: Person = pile.diggers[i]
		crowd.guard_jobs.release(d)
		crowd.piles.release(d)
	crowd.alarms.stage = AlarmManager.Stage.NORMAL
	_arrive([keep])
	_run(crowd, 21.0)
	t.check(crowd.piles.piles.size() == 1, "one digger: still blocked at 21 s")
	_run(crowd, 20.0)
	t.check(crowd.piles.piles.is_empty() and _open_pile(grid, pile), "one digger: clear by 41 s")
	Corps._done(made)


static func _too_early(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = AlarmManager.Stage.NORMAL
	var pile := _yard_pile(crowd, made[1])
	_run(crowd, 3.0)
	t.check(pile.diggers.is_empty(), "below the profile's fire stage nobody digs")
	crowd.alarms.stage = crowd.profile.fire_from
	_run(crowd, 1.5)
	t.check(not pile.diggers.is_empty(), "at it they do")
	Corps._done(made)


static func _fire_first(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = crowd.profile.fire_from
	var pile := _yard_pile(crowd, made[1])
	var house := GJ._yard_fire(crowd, made[1])
	var n0 := crowd.guard_jobs.free_near(house.center(), FireManager.RECRUIT_REACH).size()
	crowd.fires._recruit()
	crowd.piles.step(1.0)
	t.check(crowd.fires.guards_on(house) == ceili(n0 * 0.5), "the fire takes its half first (%d of %d)" % [crowd.fires.guards_on(house), n0])
	var both := false
	for d: Person in pile.diggers:
		both = both or d.mind == Person.Mind.ASSIST or crowd.guard_jobs.job_of(d) != pile
	t.check(not both, "no guard is both on the fire and on the pile")
	Corps._done(made)


static func _stranded_digger(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = crowd.profile.fire_from
	var pile := _yard_pile(crowd, made[1])
	crowd.piles.step(1.0)
	var d: Person = pile.diggers[0]
	_arrive([d])
	pile.spots.erase(d)
	crowd.guard_jobs.prune()
	t.check(not crowd.guard_jobs.on_job(d) and d.anchor.is_equal_approx(d.post), "a digger whose record drops walks back to his post")
	Corps._done(made)


static func _held_digger(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = crowd.profile.fire_from
	var pile := _yard_pile(crowd, made[1])
	crowd.piles.step(1.0)
	_arrive(pile.diggers)
	var h: Person = pile.diggers[0]
	h.confuse(5.0)
	pile.work = 1.0
	crowd.piles.step(0.02)
	t.check(crowd.piles.piles.is_empty(), "the pile is cleared")
	for i in 40 * 60:
		h.tick(1.0 / 60.0)
		if i % 60 == 0:
			crowd.guard_jobs.prune()
	t.check(h.mind == Person.Mind.POST and h.anchor.is_equal_approx(h.post) and not crowd.guard_jobs.on_job(h),
			"a digger the god held comes back to his post (mind %d, anchor %s, post %s, job %s, held %s)" % [h.mind, h.anchor, h.post, crowd.guard_jobs.on_job(h), h.held_by_god()])
	Corps._done(made)


static func _taken_digger(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = crowd.profile.fire_from
	var pile := _yard_pile(crowd, made[1])
	crowd.piles.step(1.0)
	var d: Person = pile.diggers[0]
	var was := pile.diggers.size()
	d.go_duty(d.ground_pos + Vector2(3.0, 0.0))
	_run(crowd, 1.2)
	t.check(not pile.diggers.has(d) and not crowd.guard_jobs.on_job(d), "a digger taken for a duty leaves the pile")
	t.check(pile.diggers.size() == was, "and another guard is taken in his place (%d of %d)" % [pile.diggers.size(), was])
	Corps._done(made)


static func _squads_after_rally(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	crowd.alarms.stage = crowd.profile.fire_from
	crowd.rally()
	var pile := _yard_pile(crowd, made[1])
	crowd.piles.step(1.0)
	t.check(pile.diggers.is_empty(), "no guard digs once the rally has closed the jobs")
	crowd.rescue.step(0.6)
	var squad: Dictionary = {}
	for sq in crowd.rescue.squads:
		var all := not crowd.rescue._living(sq).is_empty()
		for m in crowd.rescue._living(sq):
			all = all and pile.diggers.has(m)
		if all:
			squad = sq
	t.check(not squad.is_empty(), "an idle rescue squad takes the pile")
	_arrive(pile.diggers)
	for i in 21 * 60:
		crowd.rescue.step(1.0 / 60.0)
		crowd.piles.step(1.0 / 60.0)
	t.check(crowd.piles.piles.is_empty() and _open_pile(grid, pile), "the squad clears it")
	var home := true
	for m in crowd.rescue._living(squad):
		home = home and m.anchor.is_equal_approx(m.post)
	t.check(home, "and goes back to its post")
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	var again := _yard_pile(crowd, made[1])
	crowd.rescue.step(0.6)
	t.check(again != null and not again.diggers.is_empty(), "during the evacuation a new pile still gets a squad")
	Corps._done(made)


static func _trapped_first(t) -> void:
	City.use(&"aldermere")
	var made := Corps._crowd()
	var crowd: Crowd = made[0]
	crowd.alarms.stage = crowd.profile.fire_from
	crowd.rally()
	var pile := _yard_pile(crowd, made[1])
	crowd.rescue.step(0.6)
	var squad: Dictionary = crowd.rescue.squads[0]
	var crew: Array = crowd.rescue._living(squad)
	t.check(pile.diggers.has(crew[0]), "the squad is on the pile")
	crowd.rescue.squads = [squad]
	var house: Structure = null
	for s in made[1].structures():
		if s.kind == Structure.Kind.HOUSE and s.role == &"house" and not s.destroyed:
			house = s
			break
	crowd.rescue.trap([crowd.citizens[0]], house)
	crowd.rescue.step(0.6)
	var on_pile := false
	for m in crew:
		on_pile = on_pile or pile.diggers.has(m) or crowd.piles.digging(m)
	t.check(squad.site == house and not on_pile, "a trapped person comes before a pile")
	Corps._done(made)


static func _capital_pile(t) -> void:
	var b: Dictionary = CapPeople._build()
	var crowd: Crowd = b.crowd
	crowd.alarms.stage = crowd.profile.fire_from
	var pile := _yard_pile(crowd, b.env)
	t.check(pile != null, "a pile by the Capital's yard")
	if pile != null:
		crowd.piles.step(1.0)
		t.check(pile.diggers.size() == 2, "two Capital guards dig (%d)" % pile.diggers.size())
		var none := true
		for d: Person in pile.diggers:
			none = none and d.corps == Person.Corps.NONE
		t.check(none, "ordinary guards")
		_arrive(pile.diggers)
		_run(crowd, PileManager.SECONDS + 1.0)
		t.check(crowd.piles.piles.is_empty(), "and they clear it")
	crowd.clear()
	(b.world as Node).free()
	(b.town as Node).free()
	City.use(&"aldermere")
