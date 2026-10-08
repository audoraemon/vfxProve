extends RefCounted
## The capital's plots (Task 7): every building on its plot. No two structures overlap; all stand in the map and off
## the water (bar the bridges); every ChatGPT set is placed (bar the props) on its blockout footprint and height and
## draws its own art; about 140-180 houses fill the blocks; the landmarks stay in view; every landmark name shared code
## asks for resolves; and the people can reach every building from the market.

## How far in front (screen-down: south and east) of a landmark nothing taller may stand.
const FRONT := 3.0
## The landmarks that must be seen, and the tag or set of each.
const SEEN := [[&"citadel", &""], [&"temple", &"cathedral"], [&"town_hall", &"gpt_townhall"],
	[&"market_hall", &"gpt_markethall"]]
## Landmark names the capital has no equivalent for; their callers check has_area().
const NO_EQUIVALENT := [&"river_west", &"watermill"]
## How far a piece of the new town's river wall (a wall, a gatehouse, a wall tower) may reach into the water.
const RING_WET := 0.5


static func run(t) -> void:
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_row(t)
	_sets_table(t)
	var all := _everything(c)
	_overlaps(t, all)
	_in_map(t, c, all)
	_off_roads(t, c)
	_every_set(t, c)
	_houses(t, c)
	_art(t, c)
	_districts(t, c)
	_market(t, c)
	_seen(t, c, all)
	_landmarks(t, c)
	_reach(t)
	City.use(&"aldermere")


## Every structure the town builds for the capital: its structures(), the Citadel's parts, the fountains and the wells.
static func _everything(c: CapitalCity) -> Array[Dictionary]:
	var out: Array[Dictionary] = c.structures()
	for r: Rect2 in Citadel.TOWERS + Citadel.WALLS + [Citadel.KEEP]:
		out.append({"rect": Rect2(r.position + c.citadel_origin(), r.size), "height": 118.0 if r == Citadel.KEEP else 84.0,
			"kind": Structure.Kind.KEEP, "role": &"citadel", "tag": &""})
	for r: Rect2 in c.fountains():
		out.append({"rect": r, "height": 24.0, "kind": Structure.Kind.FOUNTAIN, "role": &"decor", "tag": &""})
	for r: Rect2 in c.wells():
		out.append({"rect": r, "height": 12.0, "kind": Structure.Kind.FOUNTAIN, "role": &"decor", "tag": &"well"})
	return out


## The block generator: deterministic, inside its block, gap apart, and as full as it can be.
static func _row(t) -> void:
	var block := Rect2(2.0, 3.0, 10.0, 5.0)
	var a := CapitalPlots.row(block, Vector2(1.3, 0.95), 0.6, 7)
	t.check(a == CapitalPlots.row(block, Vector2(1.3, 0.95), 0.6, 7), "row() is deterministic")
	t.check(a.size() == 5 * 3, "row() fills the block: 5 columns, 3 rows (got %d)" % a.size())
	var ok := true
	for i in a.size():
		ok = ok and block.encloses(a[i]) and a[i].size == Vector2(1.3, 0.95)
		for j in range(i + 1, a.size()):
			ok = ok and not a[i].grow(0.3 - 0.001).intersects(a[j].grow(0.3 - 0.001))
	t.check(ok, "row()'s plots lie in the block, the gap apart")
	t.check(a != CapitalPlots.row(block, Vector2(1.3, 0.95), 0.6, 8), "another seed slides the rows")
	t.check(CapitalPlots.row(Rect2(0, 0, 1.0, 1.0), Vector2(1.3, 0.95), 0.6, 1).is_empty(), "a block too small takes none")


## SETS holds each gpt_* set of the sprite manifest at the footprint and height its blockout gave it.
static func _sets_table(t) -> void:
	var man := SpriteArt.manifest()
	var gpt: Array = []
	for k: String in man:
		if k.begins_with("gpt_"):
			gpt.append(k)
	t.check(gpt.size() == 73 and CapitalPlots.SETS.size() == 73,
		"73 ChatGPT sets (manifest %d, table %d)" % [gpt.size(), CapitalPlots.SETS.size()])
	for k: String in gpt:
		var row: Array = CapitalPlots.SETS.get(StringName(k), [])
		var fp: Array = man[k].footprint
		t.check(row.size() == 2 and (row[0] as Vector2).is_equal_approx(Vector2(fp[0], fp[1]))
			and is_equal_approx(row[1], float(man[k].height)), "%s keeps its blockout footprint and height" % k)
	t.check(CapitalPlots.PROPS == [&"gpt_wagon", &"gpt_handcart"], "the props are the wagon and the hand cart")


static func _overlaps(t, all: Array[Dictionary]) -> void:
	var n := 0
	var first := ""
	for i in all.size():
		var a: Rect2 = all[i].rect
		for j in range(i + 1, all.size()):
			var o := a.intersection(all[j].rect)
			if o.size.x > 0.001 and o.size.y > 0.001:
				n += 1
				if first == "":
					first = "%s %s / %s %s" % [all[i].tag, a, all[j].tag, all[j].rect]
	t.check(n == 0, "no two capital structures overlap (%d; %s)" % [n, first])


static func _in_map(t, c: CapitalCity, all: Array[Dictionary]) -> void:
	var out := 0
	var wet := 0
	var first := ""
	var deep := 0.0
	var deep_corner := 0.0
	var deepest := ""
	for d: Dictionary in all:
		var r: Rect2 = d.rect
		if not c.map().encloses(r):
			out += 1
		if d.kind == Structure.Kind.BRIDGE:
			continue
		# The new town's river wall stands on the river's edge (Task 6's ring): its walls, gatehouses and towers may
		# reach a little way into the water, a corner tower by its own reach past the wall line (TownLayout.WALL_T),
		# the rest by at most RING_WET. No plot may.
		var ring: bool = d.kind in [Structure.Kind.CASTLE_WALL, Structure.Kind.GATE] 			or (d.kind == Structure.Kind.KEEP and d.role == &"tower" and d.tag != &"bell_tower")
		for w: Rect2 in c.rivers():
			if not w.intersects(r):
				continue
			var cut := w.intersection(r)
			var depth := minf(cut.size.x, cut.size.y)
			if not ring:
				wet += 1
				first = "%s %s" % [d.tag, r]
			elif is_equal_approx(r.size.x, TownLayout.CORNER_TOWER) and is_equal_approx(r.size.y, TownLayout.CORNER_TOWER):
				deep_corner = maxf(deep_corner, depth)
			elif depth > deep:
				deep = depth
				deepest = "%s %s" % [Structure.Kind.keys()[d.kind], r]
	t.check(out == 0, "every capital structure lies inside the map (%d out)" % out)
	t.check(wet == 0, "only bridges (and the river wall) stand on the water (%d; %s)" % [wet, first])
	t.check(deep <= RING_WET + 0.001, "the river wall's pieces reach at most %.1f into the water (%.2f, %s)"
		% [RING_WET, deep, deepest])
	t.check(deep_corner <= TownLayout.WALL_T + 0.001, "its corner towers at most their reach past the wall (%.2f)" % deep_corner)


## No building stands on a street: only the walls' gatehouses and the bridges meet the roads (Task 6 checks the walls).
static func _off_roads(t, c: CapitalCity) -> void:
	var n := 0
	var first := ""
	var things: Array[Dictionary] = []
	for d: Dictionary in c.structures():
		if not d.kind in [Structure.Kind.CASTLE_WALL, Structure.Kind.GATE, Structure.Kind.BRIDGE] \
				and not (d.kind == Structure.Kind.KEEP and d.role == &"tower"):
			things.append(d)
	for r: Rect2 in c.fountains() + c.wells():
		things.append({"rect": r, "tag": &"fountain"})
	for d: Dictionary in things:
		for road: Rect2 in c.roads():
			if road.intersects(d.rect):
				n += 1
				first = "%s %s" % [d.tag, d.rect]
	t.check(n == 0, "no building, stall, fountain or well stands on a street (%d; %s)" % [n, first])


## Every ChatGPT set but the props stands on at least one plot (the footbridge as the bridge's spans).
static func _every_set(t, c: CapitalCity) -> void:
	var placed := {}
	for d: Dictionary in c.structures():
		if String(d.tag).begins_with("gpt_"):
			placed[d.tag] = true
	var missing: Array = []
	for k: StringName in CapitalPlots.SETS:
		if not k in CapitalPlots.PROPS and not placed.has(k):
			missing.append(k)
	t.check(missing.is_empty(), "every ChatGPT set but the props is placed (missing %s)" % [missing])
	for k: StringName in CapitalPlots.PROPS:
		t.check(not placed.has(k), "the prop %s is not a structure" % k)
	t.check(placed.size() == 71, "71 sets placed (%d)" % placed.size())


static func _houses(t, c: CapitalCity) -> void:
	var houses := c.houses()
	t.check(houses.size() >= 140 and houses.size() <= 180, "about 140-180 houses (%d)" % houses.size())
	var built := 0
	for d: Dictionary in c.structures():
		if d.kind == Structure.Kind.HOUSE and d.role == &"house" and d.tag in [&"", &"townhouse"]:
			built += 1
	t.check(built == houses.size(), "every house is built, a cottage or a townhouse (%d of %d)" % [built, houses.size()])
	var walled := true
	for h: Rect2 in houses:
		walled = walled and (CapitalCity.INNER.grow(-1.2).encloses(h) or CapitalCity.OUTER.grow(-1.2).encloses(h))
	t.check(walled, "every house stands inside a wall ring, clear of the wall")
	t.check(c.houses() == houses, "houses() is deterministic")


## Each ChatGPT plot stands unturned on its set's footprint at its height, as role gpt tagged with its set; the art
## lookup draws that set. The existing sets keep their Aldermere roles and tags.
static func _art(t, c: CapitalCity) -> void:
	var exact := true
	var drawn := true
	var bad := ""
	for d: Dictionary in c.structures():
		if d.role != CapitalPlots.ROLE:
			continue
		var row: Array = CapitalPlots.SETS[d.tag]
		if not ((d.rect as Rect2).size.is_equal_approx(row[0]) and is_equal_approx(d.height, row[1])
				and d.kind == BuildingTypes.info(d.tag).kind):
			exact = false
			bad = String(d.tag)
		var s := Structure.new().setup(d.rect, d.height, d.kind, 1, d.role, d.tag)
		if SpriteArt.name_for(s) != String(d.tag) or not SpriteArt.set_for(s).get("mirror", true) == false:
			drawn = false
			bad = String(d.tag)
		s.free()
	t.check(exact, "every ChatGPT plot has its set's footprint, height and kind (%s)" % bad)
	t.check(drawn, "every ChatGPT plot draws its own set, unmirrored (%s)" % bad)
	var want := {&"cathedral": "cathedral", &"tavern": "tavern", &"smithy": "smithy", &"workshop": "workshop",
		&"carpenter": "carpenter", &"bell_tower": "bell_tower", &"windmill": "windmill"}
	var seen := {}
	for d: Dictionary in c.structures():
		if want.has(d.tag):
			var s := Structure.new().setup(d.rect, d.height, d.kind, 1, d.role, d.tag)
			if SpriteArt.name_for(s) == want[d.tag]:
				seen[d.tag] = true
			s.free()
		elif d.kind == Structure.Kind.BARRACKS and d.role == &"barracks":
			seen[&"barracks"] = true
		elif d.kind == Structure.Kind.MARKET_STALL and d.role == &"market":
			seen[&"stall"] = true
	t.check(seen.size() == want.size() + 2, "the town sets are reused: cathedral, tavern, smithy, workshop, carpenter, "
		+ "bell tower, windmill, barracks, stalls (%s)" % [seen.keys()])
	var aldermere := false
	for d: Dictionary in AldermereCity.new().structures():
		aldermere = aldermere or d.role == CapitalPlots.ROLE
	t.check(not aldermere, "Aldermere has no ChatGPT plots")


## Where the plan puts them (spec §1): a sample of each district's buildings.
static func _districts(t, c: CapitalCity) -> void:
	var want := {
		&"gpt_armoury": &"royal_keep", &"gpt_treasury": &"royal_keep", &"gpt_manor": &"noble_quarter",
		&"gpt_library": &"noble_quarter", &"gpt_school": &"noble_quarter", &"gpt_townhall": &"cathedral_square",
		&"gpt_courthouse": &"cathedral_square", &"gpt_jail": &"cathedral_square", &"gpt_monument": &"cathedral_square",
		&"gpt_guildhall": &"guild_quarter", &"gpt_weavers": &"guild_quarter", &"gpt_markethall": &"great_market",
		&"gpt_weighhouse": &"great_market", &"gpt_crierstage": &"great_market", &"gpt_hospital": &"old_town_houses",
		&"gpt_bathhouse": &"old_town_houses", &"gpt_cistern": &"old_town_houses", &"gpt_crane": &"harbour_district",
		&"gpt_fishmarket": &"harbour_district", &"gpt_ferry": &"harbour_district", &"gpt_bakery": &"crafts_quarter",
		&"gpt_brewery": &"crafts_quarter", &"gpt_lumberyard": &"crafts_quarter", &"gpt_chapel": &"new_town",
		&"gpt_rowhouses": &"new_town", &"gpt_tannery": &"tanners_dyers", &"gpt_dyers": &"tanners_dyers",
		&"gpt_glassworks": &"tanners_dyers", &"gpt_tenement": &"poor_quarter", &"gpt_latrine": &"poor_quarter",
		&"gpt_inn": &"road_quarter", &"gpt_stables": &"road_quarter", &"gpt_monastery": &"monastery_hill",
		&"gpt_graveyard": &"monastery_hill", &"gpt_charcoal": &"northern_woods", &"gpt_vineyard": &"south_east_fields",
		&"gpt_beehives": &"south_east_fields", &"gpt_dovecote": &"south_east_fields", &"gpt_granary": &"south_east_fields",
		&"gpt_farmhouse": &"west_farms", &"gpt_hut": &"suburbs", &"gpt_gallows": &"suburbs",
		&"gpt_grandstand": &"tournament_field", &"gpt_tiltbarrier": &"tournament_field",
	}
	var at := {}
	for d: Dictionary in c.structures():
		if want.has(d.tag) and c.landmark(want[d.tag]).encloses(d.rect):
			at[d.tag] = true
	var wrong: Array = []
	for k: StringName in want:
		if not at.has(k):
			wrong.append(k)
	t.check(wrong.is_empty(), "each sampled building stands in its plan district (wrong: %s)" % [wrong])
	t.check(c.landmark(&"temple") != Rect2() and c.landmark(&"cathedral_square").encloses(c.landmark(&"temple")),
		"the cathedral stands in the cathedral square")
	t.check(c.landmark(&"royal_keep").encloses(c.landmark(&"barracks")), "the barracks stand in the Royal Keep")


## The Great Market: its square is clear of every street (the west bridge avenue no longer crosses it), and its stalls
## stand on its squares, clear of the fountain.
static func _market(t, c: CapitalCity) -> void:
	var sq := c.landmark(&"market_square")
	var clear := sq.has_area()
	for road: Rect2 in c.roads():
		clear = clear and not road.intersects(sq)
	t.check(clear, "the market square is clear of every street")
	t.check(c.landmark(&"great_market").encloses(sq), "the market square lies in the Great Market")
	var stalls := c.stalls()
	t.check(stalls.size() >= 24, "the market has its stalls (%d)" % stalls.size())
	var plazas: Array = c.floor_areas()[&"plazas"]
	var on := true
	for st: Rect2 in stalls:
		var any := false
		for p: Rect2 in plazas:
			any = any or p.encloses(st)
		on = on and any
		for f: Rect2 in c.fountains():
			on = on and not f.grow(0.6).intersects(st)
	t.check(on, "every stall stands on a market square, clear of the fountains")
	var built := 0
	for d: Dictionary in c.structures():
		built += 1 if d.kind == Structure.Kind.MARKET_STALL and d.role == &"market" else 0
	t.check(built == stalls.size(), "every stall is built (%d)" % built)
	var torches := c.torches()
	t.check(torches[0].distance_to(sq.position) < 0.6 and torches[3].distance_to(sq.end) < 0.6,
		"the market's torches stand at its square's corners")


## Nothing taller stands directly in front (south or east: screen-down) of the keep, the cathedral, the town hall or
## the market hall, within FRONT cells.
static func _seen(t, c: CapitalCity, all: Array[Dictionary]) -> void:
	for row: Array in SEEN:
		var mark: Rect2
		var h := 0.0
		if row[0] == &"citadel":
			mark = Rect2(Citadel.KEEP.position + c.citadel_origin(), Citadel.KEEP.size)
			h = 118.0
		else:
			for d: Dictionary in all:
				if d.tag == row[1]:
					mark = d.rect
					h = d.height
		t.check(mark.has_area(), "the landmark %s stands" % row[0])
		var south := Rect2(mark.position.x, mark.end.y, mark.size.x + FRONT, FRONT)
		var east := Rect2(mark.end.x, mark.position.y, FRONT, mark.size.y + FRONT)
		var hidden: Array = []
		for d: Dictionary in all:
			var r: Rect2 = d.rect
			if r == mark or d.height <= h:
				continue
			if r.intersects(south) or r.intersects(east):
				hidden.append(d.tag)
		t.check(hidden.is_empty(), "nothing taller stands in front of the %s (%s)" % [row[0], hidden])


## Every landmark name shared code asks for (each `landmark(&"...")` in src/) is a real rect in the capital, but the
## few it has no equivalent of, whose callers check has_area(); and the capital's answers are its own buildings.
static func _landmarks(t, c: CapitalCity) -> void:
	var names := {}
	var re := RegEx.create_from_string("landmark\\(&\"([a-z_]+)\"\\)")
	for path: String in _scripts("res://src"):
		if path.contains("/cities/"):
			continue
		for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(path)):
			names[StringName(m.get_string(1))] = path
	t.check(names.size() >= 15, "the shared code's landmark names are found (%d)" % names.size())
	for n: StringName in names:
		if n in NO_EQUIVALENT:
			t.check(not c.landmark(n).has_area(), "the capital has no %s" % n)
			continue
		t.check(c.landmark(n).has_area(), "the capital answers landmark %s (asked by %s)" % [n, names[n]])
	var tags := {&"temple": &"cathedral", &"smithy": &"smithy", &"workshop": &"workshop", &"carpenter": &"carpenter",
		&"bell_tower": &"bell_tower", &"windmill": &"windmill"}
	for n: StringName in tags:
		var found := false
		for d: Dictionary in c.structures():
			found = found or (d.tag == tags[n] and d.rect == c.landmark(n))
		t.check(found, "landmark %s is the capital's own %s" % [n, tags[n]])
	var barracks := false
	for d: Dictionary in c.structures():
		barracks = barracks or (d.kind == Structure.Kind.BARRACKS and d.role == &"barracks" and d.rect == c.landmark(&"barracks"))
	t.check(barracks, "landmark barracks is the capital's barracks")
	# The callers of the names it has no equivalent of check has_area() before they use them.
	for n: StringName in NO_EQUIVALENT:
		if not names.has(n):
			continue
		for path: String in _scripts("res://src"):
			var src := FileAccess.get_file_as_string(path)
			if path.contains("/cities/") or not src.contains("landmark(&\"%s\")" % n):
				continue
			t.check(src.contains("has_area()"), "%s guards landmark %s with has_area()" % [path, n])
	# Asked again and again, it is worked out once (the gatehouses are not rebuilt per call).
	var t0 := Time.get_ticks_usec()
	for i in 2000:
		c.landmark(&"barbican")
	t.check(Time.get_ticks_usec() - t0 < 100000, "landmark() is cached (2000 calls in %d us)" % (Time.get_ticks_usec() - t0))


static func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(d)))
	return out


## Built through the real town and walk grid: from the market people reach the front of every building and every house,
## and both map exits.
static func _reach(t) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var start := grid.nearest_walkable(City.current().landmark(&"market_square").get_center())
	var seen := {}
	var todo: Array[Vector2i] = [grid.world_to_id(start)]
	seen[todo[0]] = true
	while not todo.is_empty():
		var id: Vector2i = todo.pop_back()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := id + step
			if not seen.has(n) and grid.grid.is_in_boundsv(n) and not grid.grid.is_point_solid(n):
				seen[n] = true
				todo.append(n)
	var cut: Array = []
	for s: Structure in env.structures():
		if s.walkable or s.kind in [Structure.Kind.CASTLE_WALL, Structure.Kind.TREE, Structure.Kind.TORCH] \
				or s.role in [&"tower", &"citadel"]:
			continue
		var f := s.footprint
		var front := grid.nearest_walkable(Vector2(f.get_center().x, f.end.y + 0.35))
		var side := grid.nearest_walkable(Vector2(f.end.x + 0.35, f.get_center().y))
		var ok := (front != Vector2.INF and seen.has(grid.world_to_id(front))) \
			or (side != Vector2.INF and seen.has(grid.world_to_id(side)))
		if not ok:
			cut.append("%s %s" % [s.art_tag if s.art_tag != &"" else s.role, f])
	t.check(cut.is_empty(), "every building can be reached from the market (%d cut off: %s)" % [cut.size(), cut.slice(0, 6)])
	for e: Vector2 in City.current().exits():
		var g := grid.nearest_walkable(e)
		t.check(g != Vector2.INF and seen.has(grid.world_to_id(g)), "the exit %s can be reached from the market" % e)
	town.free()
	City.use(&"aldermere")
