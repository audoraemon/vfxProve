extends RefCounted
## Soldier jobs, decision 4: a fallen building (a house, the temple, a barracks, a farm barn) stays a blocked ruin and
## people standing in its falling footprint step out; walls, towers, gates, stalls, props and the Capital's open
## structures keep today's fall rule (rubble you can walk over).


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


static func _with_role(env: EnvironmentField, role: StringName, tag := &"", kind := -1) -> Structure:
	for s in env.structures():
		if s.role == role and (tag == &"" or s.art_tag == tag) and (kind < 0 or s.kind == kind):
			return s
	return null


static func run(t) -> void:
	_kinds(t)
	_temple_stays(t)
	_others_open(t)
	_neighbour_fall(t)
	_pushed(t)
	_far_stays(t)
	_margin_queue(t)
	_capital(t)
	City.use(&"aldermere")


static func _kinds(t) -> void:
	City.use(&"aldermere")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var yes := {"house": _with_role(env, &"house"), "temple": _with_role(env, &"temple"),
		"barracks": _with_role(env, &"barracks"), "farm barn": _with_role(env, &"farm", &"", Structure.Kind.HOUSE)}
	for k: String in yes:
		t.check(yes[k] != null and (yes[k] as Structure).leaves_ruin(), "%s leaves a ruin" % k)
	var wall: Structure = _with_role(env, &"wall")
	var no := {"tower": _with_role(env, &"tower"), "wall run": wall, "gate": _with_role(env, &"gate"),
		"Bell Tower": _with_role(env, &"tower", &"bell_tower"), "market stall": _with_role(env, &"market"),
		"tree": _with_role(env, &"decor", &"oak"), "bridge": town.bridge}
	for k: String in no:
		t.check(no[k] != null and not (no[k] as Structure).leaves_ruin(), "%s leaves no ruin" % k)
	var citadel := false
	var any_citadel := false
	for s in env.structures():
		if s.role == &"citadel":
			any_citadel = true
			citadel = citadel or s.leaves_ruin()
	t.check(any_citadel and not citadel, "no Citadel part leaves a ruin")
	for s in env.structures():
		if s.kind == Structure.Kind.FOUNTAIN:
			t.check(not s.leaves_ruin(), "a fountain leaves no ruin")
			break
	var block := env.add_structure(Rect2(2, 2, 1, 1), 10.0, Structure.Kind.BLOCK)
	var shrine := env.add_structure(Rect2(4, 2, 1, 1), 10.0, Structure.Kind.SHRINE)
	t.check(not block.leaves_ruin() and not shrine.leaves_ruin(), "a BLOCK and a SHRINE leave no ruin")
	town.free()


static func _temple_stays(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var c: Vector2 = TownLayout.TEMPLE.get_center()
	var temple := _with_role(env, &"temple")
	temple.destroy(Vector2.ZERO, &"stone")
	t.check(not grid.walkable(c), "a fallen temple is not walkable")
	t.check(env.blocked(c), "a fallen temple still blocks (EnvironmentField.blocked)")
	temple.restore()
	t.check(not grid.walkable(c) and env.blocked(c), "a restored temple still blocks")
	town.free()


static func _others_open(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	for what: Array in [[&"market", &""], [&"tower", &""], [&"gate", &""]]:
		var s := _with_role(env, what[0], what[1])
		if what[0] == &"gate":
			s = town.gates[0]
		var c := s.center()
		s.destroy(Vector2.ZERO, &"stone")
		t.check(grid.walkable(c), "a fallen %s opens its ground" % what[0])
	town.free()


static func _neighbour_fall(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var house := _with_role(env, &"house")
	var sr := WalkGrid.solid_rect(house.footprint)
	# A block hard against the house: its margin reaches into the house's.
	var block := env.add_structure(Rect2(sr.end.x + 0.1, sr.position.y, 0.6, sr.size.y), 10.0, Structure.Kind.BLOCK)
	t.check(WalkGrid.solid_rect(block.footprint).grow(WalkGrid.CELL).intersects(sr), "the block is a neighbour")
	var snap := {}
	var c0 := grid.world_to_id(sr.position)
	var c1 := grid.world_to_id(sr.end)
	for y in range(c0.y, c1.y + 1):
		for x in range(c0.x, c1.x + 1):
			var id := Vector2i(x, y)
			if sr.has_point(grid.id_to_world(id)):
				snap[id] = grid.walkable(grid.id_to_world(id))
	house.destroy(Vector2.ZERO, &"stone")
	block.destroy(Vector2.ZERO, &"stone")
	var same := not snap.is_empty()
	for id: Vector2i in snap:
		same = same and grid.walkable(grid.id_to_world(id)) == snap[id]
	t.check(same, "a neighbour falling does not reopen a ruin's cells")
	# A removed ruin opens.
	var gone := house.center()
	env.remove(house)
	t.check(grid.walkable(gone), "a removed ruin opens its ground")
	town.free()


static func _pushed(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var house := _with_role(env, &"house")
	var sr := WalkGrid.solid_rect(house.footprint)
	# Inside the body margin, outside the footprint.
	var spot := Vector2(house.footprint.end.x + WalkGrid.BODY * 0.5, house.footprint.get_center().y)
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	for p in [a, b]:
		p.ground_pos = spot
	b.ground_pos = house.center()
	b.inside = true
	var kept := b.ground_pos
	t.check(sr.has_point(spot), "the spot is in the margin")
	house.destroy(Vector2.ZERO, &"stone")
	t.check(grid.walkable(a.ground_pos), "a citizen in the falling margin is pushed onto open ground")
	t.check(b.ground_pos == kept, "someone inside keeps their place")
	(made[2] as Node).free()
	(made[5] as Node).free()


## Final review I1: a fall moves only those standing on its own closed ground, out over its edge; someone on a closed cell
## anywhere else in town (another house's margin) stays where he is.
static func _far_stays(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var house := _with_role(env, &"house")
	var sr := WalkGrid.solid_rect(house.footprint)
	var other: Structure = null
	for s in env.structures():
		if s.role == &"house" and s != house and s.center().distance_to(house.center()) > 10.0:
			other = s
			break
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	a.inside = false
	b.inside = false
	a.ground_pos = house.center()
	b.ground_pos = other.center()
	var kept := b.ground_pos
	t.check(not grid.walkable(kept), "the far citizen stands on a closed cell")
	house.destroy(Vector2.ZERO, &"stone")
	t.check(b.ground_pos == kept, "a citizen on closed ground far from the fall is not moved (%s -> %s)" % [kept, b.ground_pos])
	t.check(grid.walkable(a.ground_pos) and sr.grow(WalkGrid.CELL * 1.5).has_point(a.ground_pos),
			"one in the footprint steps out over its edge (%s, footprint %s)" % [a.ground_pos, sr])
	(made[2] as Node).free()
	(made[5] as Node).free()


## Final review I1: one in the fall's margin cell (his cell closes, he stands outside the footprint) keeps his gate-queue place;
## one inside the footprint gives it up.
static func _margin_queue(t) -> void:
	City.use(&"aldermere")
	var made := _crowd()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var house: Structure = null
	var spot := Vector2.INF
	for s in env.structures():
		if s.role != &"house" or not s.leaves_ruin():
			continue
		var sr := WalkGrid.solid_rect(s.footprint)
		var c := sr.get_center()
		for g: Vector2 in [Vector2(sr.end.x + 0.01, c.y), Vector2(sr.position.x - 0.01, c.y),
				Vector2(c.x, sr.end.y + 0.01), Vector2(c.x, sr.position.y - 0.01)]:
			if not sr.has_point(g) and sr.has_point(grid.id_to_world(grid.world_to_id(g))):
				spot = g
				break
		if spot != Vector2.INF:
			house = s
			break
	t.check(house != null, "a house with a margin cell whose centre is in its solid rect")
	if house == null:
		(made[2] as Node).free()
		(made[5] as Node).free()
		return
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	a.inside = false
	b.inside = false
	a.ground_pos = spot
	b.ground_pos = house.center()
	a.queue_spot = spot + Vector2(1.0, 0.0)
	b.queue_spot = spot + Vector2(1.0, 0.0)
	house.destroy(Vector2.ZERO, &"stone")
	t.check(a.ground_pos != spot and grid.walkable(a.ground_pos), "the margin citizen steps onto open ground")
	t.check(a.queue_spot != Vector2.INF, "and keeps his place in the gate queue")
	t.check(b.queue_spot == Vector2.INF, "one inside the footprint gives it up")
	(made[2] as Node).free()
	(made[5] as Node).free()


static func _capital(t) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var seen := {}
	var wrong := []
	for s in env.structures():
		if s.role != CapitalPlots.ROLE:
			continue
		var info := BuildingTypes.info(s.art_tag)
		var want: bool = info.kind in [Structure.Kind.HOUSE, Structure.Kind.TEMPLE, Structure.Kind.BARRACKS] \
			and not info.walkable and not s.art_tag in Structure.NOT_BUILDINGS
		seen[s.art_tag] = want
		if s.leaves_ruin() != want:
			wrong.append(s.art_tag)
	t.check(wrong.is_empty(), "every plotted set leaves a ruin exactly when it is a building %s" % [wrong])
	for tag in Structure.NOT_BUILDINGS:
		if seen.has(tag):
			t.check(not seen[tag], "%s is not a building" % tag)
	var tenement := _with_role(env, CapitalPlots.ROLE, &"gpt_tenement")
	var wagon := _with_role(env, CapitalPlots.ROLE, &"gpt_wagon")
	if tenement != null:
		var c := tenement.center()
		tenement.destroy(Vector2.ZERO, &"stone")
		t.check(not grid.walkable(c), "a fallen tenement stays closed")
	if wagon != null:
		var c := wagon.center()
		wagon.destroy(Vector2.ZERO, &"stone")
		t.check(grid.walkable(c), "a fallen wagon opens")
	var steps := _with_role(env, CapitalPlots.ROLE, &"gpt_alleysteps")
	t.check(steps == null or not steps.leaves_ruin(), "the alley steps leave no ruin")
	var chapel := _with_role(env, CapitalPlots.ROLE, &"gpt_chapel")
	var yard := _with_role(env, CapitalPlots.ROLE, &"gpt_graveyard")
	t.check(chapel == null or chapel.leaves_ruin(), "a chapel leaves a ruin")
	t.check(yard == null or not yard.leaves_ruin(), "a graveyard leaves none")
	town.free()
	City.use(&"aldermere")
