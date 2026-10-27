extends RefCounted
## v0.12 M2 Task 11: Spoiled Harvest in the Capital (spec 2.3). The town's overrides file
## (src/game/town/cities/capital_missions/spoiled_harvest.gd) is valid and takes (types, read-back); the Capital hosts the mission;
## the carter's walks from the Keep's gate to the three granaries are Aldermere's in length (walk parity, D26); the granary spots land
## on three distinct dwellings and their watchmen's posts stand more than two Silent Doom radii apart; the intro's camera keeps the
## first granary clear of the HUD stack; the tour names the town's granaries and grain times.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
## Walk parity (R19, D26): the Capital's total trip and every trip within this band of Aldermere's.
const BAND_LO := 0.75
const BAND_HI := 1.35


static func run(t) -> void:
	City.use(&"aldermere")
	_overrides_valid(t)
	_hostable(t)
	City.use(&"capital")
	var cap := Kit.world(MissionBook.in_city(MissionBook.spoiled_harvest(), &"capital"))
	(cap.field as EnemyField).bounds = City.current().map()
	City.use(&"aldermere")
	var ald := Kit.world(MissionBook.spoiled_harvest())
	_walk_parity(t, cap, ald)
	_spots_land(t, cap)
	_camera_clear(t, cap)
	_tour_true(t, cap)
	_routes_stay_in(t, cap)
	_still_aldermere(t, ald)
	Kit.done(cap)
	Kit.done(ald)
	City.use(&"aldermere")
	t.check(City.current().id() == &"aldermere", "the Capital harvest test leaves Aldermere the active city")


## The path length (ground units) along the walk grid, -1 when there is no route.
static func plen(grid: WalkGrid, a: Vector2, b: Vector2) -> float:
	var p := grid.path(a, b)
	if p.is_empty():
		return -1.0
	var sum := 0.0
	for i in range(p.size() - 1):
		sum += p[i].distance_to(p[i + 1])
	return sum


## Each granary's walk from the Citadel's gate to its door (the carter's trip), in the director's order.
static func trips(s: Dictionary) -> Array[float]:
	var d: HarvestDirector = s.d
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	var out: Array[float] = []
	for st: Structure in d.targets:
		out.append(plen(grid, d.citadel_door, d.doors[st]))
	return out


static func _overrides_valid(t) -> void:
	var town := City.by_id(&"capital")
	var ov := town.mission_overrides("spoiled_harvest")
	t.check(ov.keys().size() == 2 and ov.has("def") and ov.has("director"), "the Capital has Spoiled Harvest overrides, def and director")
	var def := MissionBook.spoiled_harvest()
	var bad := Overrides.apply(def, ov["def"])
	t.check(bad.is_empty(), "the def overrides apply with no key refused (%s)" % [bad])
	var d := HarvestDirector.new()
	var bad_d := Overrides.apply(d, (ov["director"] as Dictionary).duplicate(true), Overrides.town_vars(d))
	t.check(bad_d.is_empty(), "the director overrides apply with no key refused (%s)" % [bad_d])
	var seeded := HarvestDirector.new()
	var ok := true
	for key: String in ov["director"]:
		ok = ok and typeof(d.get(key)) == typeof(seeded.get(key)) and d.get(key) == ov["director"][key]
	t.check(ok, "every director value has its seeded var's type and reads back")
	t.check(d.store_spots.size() == 3 and d.store_names.size() == 3, "three granary spots and three names")
	t.check(def.camera_at != Vector2.INF and def.intro_from.is_equal_approx(def.camera_at + Vector2(0.0, 6.0)),
		"camera_at and intro_from are both overridden, the intro 6 south of the camera")
	var placed := MissionBook.in_city(MissionBook.spoiled_harvest(), &"capital")
	t.check(placed.city == &"capital" and placed.camera() == def.camera_at, "put in the Capital, the mission takes the town's camera")
	t.check(MissionBook.spoiled_harvest().camera() != placed.camera(), "Aldermere's Spoiled Harvest keeps its own camera")


static func _hostable(t) -> void:
	t.check(MissionBook.hostable("spoiled_harvest", City.by_id(&"capital")), "the Capital hosts Spoiled Harvest")
	t.check(MissionBook.town_missions(&"capital").has("spoiled_harvest@capital"), "the Capital's DEV list has spoiled_harvest@capital")
	t.check(MissionBook.is_dev("spoiled_harvest@capital"), "a town night is a dev night")
	t.check(Array(MissionNeeds.of("spoiled_harvest")).has("citadel_gate"), "Spoiled Harvest needs the Citadel's gate")


## D26: the carter's trips, printed for both towns. The old town's dwellings are 14-29 from the Keep's gate along the streets,
## Aldermere's granaries 26-41; so the Capital's three trips together are 0.75-1.35 of Aldermere's, and each is between 0.75 of
## Aldermere's shortest and 1.35 of its longest (the longest, 40.6, has no dwelling in the old town: the pairing is by the whole set,
## not by rank).
static func _walk_parity(t, cap: Dictionary, ald: Dictionary) -> void:
	var c := trips(cap)
	var a := trips(ald)
	print("Capital harvest parity: capital trips %s (total %.1f), Aldermere trips %s (total %.1f)" % [c, _sum(c), a, _sum(a)])
	var lo := INF
	var hi := 0.0
	for x in a:
		lo = minf(lo, x)
		hi = maxf(hi, x)
	var each := c.size() == 3 and a.size() == 3
	for x in c:
		each = each and x > 0.0 and x >= lo * BAND_LO and x <= hi * BAND_HI
	t.check(each, "each granary trip is within %.2f-%.2f of Aldermere's shortest-longest (%s vs %s)" % [BAND_LO, BAND_HI, c, a])
	var cs := c.duplicate()
	var as_ := a.duplicate()
	cs.sort()
	as_.sort()
	var paired := cs.size() == 3 and as_.size() == 3
	var rank := []
	for i in mini(cs.size(), as_.size()):
		rank.append(snappedf(cs[i] / as_[i], 0.01))
		paired = paired and cs[i] / as_[i] >= RANK_FLOOR
	print("Capital harvest parity: rank-paired ratios %s" % [rank])
	t.check(paired, "the trips, shortest to longest against Aldermere's, are each at least %.2f of its pair (%s)" % [RANK_FLOOR, rank])
	var ratio := _sum(c) / _sum(a)
	t.check(ratio >= BAND_LO and ratio <= BAND_HI, "the three trips together are %.2fx Aldermere's (band %.2f-%.2f)" % [ratio, BAND_LO, BAND_HI])


## The least a Capital trip may be of Aldermere's trip of the same rank (the total is held to BAND_LO-BAND_HI).
const RANK_FLOOR := 0.70


static func _sum(xs: Array[float]) -> float:
	var s := 0.0
	for x in xs:
		s += x
	return s


## Every spot snaps within 0.6 of itself; the spots take three distinct dwellings the board's wishes accept; the six watchmen's posts
## are on walkable ground and more than 1.6 (two Silent Doom radii) from one another.
static func _spots_land(t, cap: Dictionary) -> void:
	var d: HarvestDirector = cap.d
	var grid: WalkGrid = (cap.crowd as Crowd)._grid
	var near := true
	for spot: Vector2 in d.store_spots:
		near = near and grid.nearest_walkable(spot).distance_to(spot) <= 0.6
	t.check(near, "every granary spot snaps to walkable ground within 0.6 of itself")
	var homes := {}
	var fit := d.targets.size() == 3
	for st: Structure in d.targets:
		homes[st] = true
		fit = fit and RuinWish.fits(st, "house")
	t.check(fit and homes.size() == 3, "the three granaries are three distinct dwellings (%d)" % d.targets.size())
	var on_spot := d.targets.size() == 3
	for i in mini(d.targets.size(), d.store_spots.size()):
		on_spot = on_spot and (d.targets[i] as Structure).center().distance_to(d.store_spots[i]) < 1.5
	t.check(on_spot, "each granary is the dwelling at its own spot (names and camera stay on the intended houses)")
	var posts: Array[Vector2] = []
	for st: Structure in d.targets:
		for w: HarvestDirector.Watch in d.watches[st]:
			posts.append(w.post)
	var apart := INF
	var walk := true
	for i in posts.size():
		walk = walk and grid.nearest_walkable(posts[i]).distance_to(posts[i]) < 0.01
		for j in range(i + 1, posts.size()):
			apart = minf(apart, posts[i].distance_to(posts[j]))
	t.check(posts.size() == 6 and walk and apart > 1.6, "six watchmen's posts on walkable ground, nearest pair %.2f apart (> 1.6)" % apart)
	var manned := true
	for st: Structure in d.targets:
		for w: HarvestDirector.Watch in d.watches[st]:
			manned = manned and w.man != null
	t.check(manned, "every post has a watchman")
	t.check(d.citadel_door.distance_to(City.by_id(&"capital").place(&"citadel_gate")) < 0.6,
		"the carters set out from the Capital's Keep gate (%s)" % [d.citadel_door])


## The intro's camera rests on the first granary, which (with its watchmen) is clear of the HUD stack grown by Hud.STACK_PAD.
static func _camera_clear(t, cap: Dictionary) -> void:
	var d: HarvestDirector = cap.d
	var m := MissionBook.in_city(MissionBook.spoiled_harvest(), &"capital")
	var cam := m.camera()
	var zone := Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))
	var first: Structure = d.targets[0]
	var clear := Kit.clear_of_stack(first.center(), cam, zone) and Kit.clear_of_stack(d.doors[first], cam, zone)
	for w: HarvestDirector.Watch in d.watches[first]:
		clear = clear and Kit.clear_of_stack(w.post, cam, zone)
	t.check(clear, "the first granary, its door and its watchmen's posts show clear of the padded stack at the intro camera")
	var others := ""
	for i in range(1, d.targets.size()):
		others += " %s:%s" % [d.store_names[i], Kit.shown_at(d.targets[i].center(), cam)]
	print("Capital harvest camera %s: Citadel gate shown at %s, other granaries shown at%s" % [cam, Kit.shown_at(d.citadel_door, cam), others])
	t.check(m.intro_from.is_equal_approx(cam + Vector2(0.0, 6.0)), "the intro starts 6 south of the camera")


## The tour names the Capital's granaries and the times their grain arrives, not Aldermere's.
static func _tour_true(t, cap: Dictionary) -> void:
	var d: HarvestDirector = cap.d
	var lines := d.tour()
	var ok := lines.size() == 4
	for i in d.targets.size():
		var text: String = lines[i][1]
		ok = ok and text.contains("The %s granary" % d.store_names[i]) and text.contains(UiTheme.clock(float(d.grain_at[i])))
		ok = ok and (lines[i][0] as Vector2) == d.doors[d.targets[i]]
	t.check(ok, "the tour shows each Capital granary at its door with its own name and grain time")
	var aldermere_names := false
	for line in lines:
		for n in HarvestDirector.STORE_NAMES:
			aldermere_names = aldermere_names or (line[1] as String).contains("The %s granary" % n)
	t.check(not aldermere_names, "the tour names none of Aldermere's granaries")


## God T1R (Tier 1 routes, Task 4): the Capital's carters set out CARTER_LEAD before each grain, and none of their roads, Keep gate to door and
## back, leaves the old town's walls (a carter who merely walks his road is never "out of the walls", river gates included), nor does a
## granary's door or a watchman's post.
static func _routes_stay_in(t, cap: Dictionary) -> void:
	var d: HarvestDirector = cap.d
	var capital := City.by_id(&"capital")
	var grid: WalkGrid = (cap.crowd as Crowd)._grid
	var early := true
	for i in d.targets.size():
		early = early and is_equal_approx(d.carter_out_at(i), maxf(d.grain_due(i) - HarvestDirector.CARTER_LEAD, 0.0))
	t.check(early, "the Capital's carters set out CARTER_LEAD before each grain")
	var inside := not Walls.outside(d.citadel_door, capital)
	for st: Structure in d.targets:
		inside = inside and not Walls.outside(d.doors[st], capital)
		for w: HarvestDirector.Watch in d.watches[st]:
			inside = inside and not Walls.outside(w.post, capital)
		for pair in [[d.citadel_door, d.doors[st]], [d.doors[st], d.citadel_door]]:
			var path := grid.path(pair[0], pair[1])
			inside = inside and not path.is_empty()
			for pt in path:
				inside = inside and not Walls.outside(pt, capital)
	t.check(inside, "in the Capital the Keep gate, the doors, the posts and every carter's road lie inside the old town's walls")


## Aldermere's own Spoiled Harvest is as ever: its seeded spots, names and door.
static func _still_aldermere(t, ald: Dictionary) -> void:
	var d: HarvestDirector = ald.d
	t.check(d.store_spots == HarvestDirector.STORE_SPOTS and d.store_names == HarvestDirector.STORE_NAMES
		and d.citadel_door.is_equal_approx(Vector2(-10.5, -7.6)), "Aldermere's Spoiled Harvest keeps its granaries and gate")
