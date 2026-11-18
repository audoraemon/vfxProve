extends RefCounted
## Grave Tide (Death, Tier V; the second review's city-wide grave burst, R41-R45): a click, once a descent, always castable.
## The graves of the whole city (grave_spots(): every district's centre and quarter points, snapped to open ground, GRAVE_GAP
## apart, GRAVES_MOST at most, spread) burst one by one from T_RISE, each raising a skeleton warrior and a ghoul; the town's
## bodies rise on top as zombies, in the room the graves leave under LIVING_CAP. Nobody marches to the click: each hunts from
## where it rose and claws at buildings, never one the night needs standing (MissionKeeps.spared()). A giant of bones always
## comes: its BONES bones fly up out of the grave nearest the click over ASSEMBLE; it lands with a slam and slams every
## SLAM_EVERY (soldiers within SLAM_R die, the rest are knocked back and frightened, every building within it not spared
## takes SLAM_WRECK), walks the graves one leg at a time, and a soldier near cuts its leg for the hunt. Death's undead within
## GIANT_AURA of it move AURA_SPEED times as fast. It stands GIANT_LIFE, the horde LIFE. The frame-rate check: the whole horde,
## thirty bodies, the giant and its slams cost under PERF_MS a frame.

const RD := preload("res://tests/test_raise_dead.gd")
const FxStage := preload("res://tests/fx_stage.gd")
const DT := 0.05
## The perf check's frames and its ceiling (ms a frame, averaged).
const PERF_FRAMES := 200
const PERF_MS := 8.0


## A walk grid whose open ground is everywhere but `built` (no open cell within GRAVE_SNAP of a point there): the stub town
## for grave_spots().
class StubGrid extends WalkGrid:
	var built: Array[Rect2] = []

	func nearest_walkable(g: Vector2, max_cells := SNAP_CELLS, streets := false) -> Vector2:
		for b in built:
			if b.has_point(g):
				return Vector2.INF
		return g


## A night whose director needs one building standing (R45's needs_standing()).
class HoldDirector extends MissionDirector:
	var held: Structure

	func needs_standing(s: Structure) -> bool:
		return s == held


## A night that wants one building down (a Raze target: R45's wants_down()) and needs another standing.
class WantDirector extends MissionDirector:
	var want: Structure
	var held: Structure

	func wants_down(s: Structure) -> bool:
		return s == want

	func needs_standing(s: Structure) -> bool:
		return s == held


static func _cast(made: Array, at: Vector2) -> GraveTideFx:
	return FxTimeline.cast(GraveTideFx, made[5], at) as GraveTideFx


static func run(t) -> void:
	var made := RD._setup()
	_book(t, made)
	_graves(t, made)
	_stub_graves(t)
	_always(t, made)
	_kinds(t, made)
	_bodies_cap(t, made)
	_assemble(t, made)
	_landing(t, made)
	_slam_every(t, made)
	_no_slam_fallen(t, made)
	_soldier(t, made)
	_soldier_leg(t, made)
	_aura(t, made)
	_aura_others(t, made)
	_aura_walker(t, made)
	_freed_clear(t, made)
	_cut_short(t, made)
	_exit(t, made)
	await _staged(t, made)
	_tour(t, made)
	_slam_house(t, made)
	_spared(t, made)
	_wanted_down(t, made)
	_life(t, made)
	RD._done(made)
	_perf(t)
	_perf_bones(t)


## The citizens still alive and out in the open, in the crowd's order.
static func _alive(made: Array) -> Array:
	return (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive() and not q.inside)


## One body at each of `spots`, in that order, each a moment after the last (so the oldest is the first): the remains.
static func _bodies(made: Array, spots: Array) -> Array:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var alive := _alive(made)
	var out := []
	for i in spots.size():
		var p: Person = alive[alive.size() - 1 - i]  # from the back: the front of the list stays for the tests' living
		p.ground_pos = spots[i]
		field.kill(p, &"mob")
		crowd.remains.step(0.01)
		out.append(crowd.remains.pick(spots[i]))
	return out


## `n` walkable spots on a ring of `r` round `at` (the first at angle 0).
static func _ring(made: Array, at: Vector2, n: int, r: float) -> Array:
	var grid: WalkGrid = made[2]
	var out := []
	for i in n:
		var p := at + Vector2.from_angle(TAU * float(i) / float(n)) * r
		out.append(p if grid.walkable(p) else grid.nearest_walkable(p, 4))
	return out


## The town's graves, as a cast now would find them.
static func _graves_of(made: Array) -> Array[Vector2]:
	return GraveTideFx.grave_spots(made[2], City.current().districts())


## The horde: the tide's living undead but the giant.
static func _horde(fx: GraveTideFx) -> Array:
	return fx.visitors.living().filter(func(a: Animal) -> bool: return a != fx.giant)


static func _of(fx: GraveTideFx, breed: Animal.Breed) -> Array:
	return fx.visitors.living().filter(func(a: Animal) -> bool: return a.breed == breed)


## Runs the tide with its horde taken off the town every step, as it rises (the giant alone: the checks of the giant's own
## doings, with no skeleton or ghoul to get there first); `people` are stepped too.
static func _run_bare(fx: GraveTideFx, seconds: float, people: Array = []) -> void:
	for i in roundi(seconds / DT):
		for p in people:
			if is_instance_valid(p):
				(p as Person).frame(DT)
		if fx.finished:
			continue
		fx._process(DT)
		if fx.visitors != null:
			for a in _horde(fx):
				fx.visitors.take(a)


## The pace a tide undead was summoned at, by its kind.
static func _own_pace(a: Animal) -> float:
	var walk := DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	match a.breed:
		Animal.Breed.SKELETON:
			return DeathParts.SKELETON_PACE * walk
		Animal.Breed.GHOUL:
			return DeathParts.GHOUL_PACE * walk
		Animal.Breed.BONE_GIANT:
			return GraveTideFx.GIANT_PACE / (Animal.DOG_SPEED * Animal.RUN)
	return DeathParts.ZOMBIE_PACE * walk


## Every soldier indoors (none for the giant to go after, none for a guard to strike it); the old `inside` of each.
static func _soldiers_in(made: Array) -> Dictionary:
	var was := {}
	for s in (made[0] as Crowd).soldiers:
		if is_instance_valid(s):
			was[s] = s.inside
			s.inside = true
	return was


static func _soldiers_back(was: Dictionary) -> void:
	for s in was:
		if is_instance_valid(s):
			s.inside = was[s]


static func _put(made: Array, n: int, at: Vector2) -> Person:
	var p: Person = _alive(made)[n]
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	return p


## The row, its tables, its icons, clip and cues, the brief's numbers; the aim.
static func _book(t, made: Array) -> void:
	var b := PowerBook.get_power("gravetide")
	t.check(not b.is_empty() and int(b.dp) == 6 and float(b.cooldown) == 999.0 and String(b.aim) == "click"
		and not b.has("needs") and PowerBook.authority_of("gravetide") == "death"
		and not PowerBook.is_quiet("gravetide") and String(b.get("path", "")) == "res://src/fx/death/grave_tide.gd",
		"Grave Tide: Death's 6 DP, once a descent, a click, needs no body (R44), loud (%s)" % [b.get("needs", "-")])
	var area: Dictionary = Targeting.AREAS.get("gravetide", {})
	t.check(PowerBook.REACH.has("gravetide") and is_equal_approx(PowerBook.impact("gravetide"), GraveTideFx.T_RISE)
		and PowerBook.family("gravetide") == "death" and Rules.POWER_KINDS.get("gravetide", []) == [&"frenzy"]
		and area.get("shape", "") == "graves" and is_equal_approx(float(area.get("r", 0.0)), GraveTideFx.GIANT_AURA)
		and Targeting.AREA_STATS.get("gravetide", {}) == {"r": "GIANT_AURA"},
		"its reach, impact (the dead stand), family, kills (frenzy) and area (the graves, the giant's aura round its own)")
	t.check(PowerBook.icon("gravetide") != null and PowerBook.hud_icon("gravetide") != null and PowerBook.clip("gravetide") != null,
		"it has its icons and its clip")
	t.check(GraveTideFx.MOST == 30 and GraveTideFx.LIFE == 40.0 and GraveTideFx.GIANT_BLOWS == 12 and GraveTideFx.GIANT_AURA == 6.0
		and GraveTideFx.AURA_SPEED == 1.2, "the numbers of the brief")
	t.check(GraveTideFx.GRAVES_MOST == 24 and GraveTideFx.GRAVE_GAP == 2.5 and GraveTideFx.BURST_STEP == 0.08
		and GraveTideFx.LIVING_CAP == 60 and GraveTideFx.GIANT_LEG == 25.0 and GraveTideFx.SLAM_WRECK == 60.0,
		"the second review's numbers: the graves, the cap, the giant's leg, the slam's wreck (R41, R43, R44)")
	t.check(GraveTideFx.ZOMBIE_WRECK == 3.0 and GraveTideFx.ZOMBIE_WRECK_EVERY == 1.5 and GraveTideFx.SKELETON_WRECK == 6.0
		and GraveTideFx.SKELETON_WRECK_EVERY == 1.5 and GraveTideFx.GHOUL_WRECK == 3.0 and GraveTideFx.GHOUL_WRECK_EVERY == 1.0,
		"the claws of each kind (R42)")
	t.check(GraveTideFx.GIANT_LIFE == 60.0 and GraveTideFx.ASSEMBLE == 1.2 and GraveTideFx.BONES == 18 and GraveTideFx.SLAM_EVERY == 3.0
		and GraveTideFx.SLAM_R == 3.5 and GraveTideFx.SLAM_KNOCK == 5.5, "the slam's numbers (ruling R12; every 3 s within 3.5 by the R46 bar ruling)")
	var script := load("res://src/fx/death/grave_tide.gd") as GDScript
	var consts := script.get_script_constant_map()
	var methods := script.get_script_method_list().map(func(m: Dictionary) -> String: return String(m.name))
	t.check(not consts.has("CLUSTER_R") and not consts.has("CLUSTER_MIN") and not consts.has("MARCH_FOR")
		and not methods.has("cluster") and not methods.has("_nearest_soldier"),
		"the cluster, the march to the click and the soldier-anywhere search are gone (R43)")
	t.check(Sfx.CATALOG.has(&"gravetide_rise") and Sfx.CATALOG.has(&"giant_step"), "its cues (bone grinding) are catalogued")
	t.check(Remains.wants(["smite", "gravetide"]), "a loadout with Grave Tide keeps the town's bodies (Remains.wants)")
	t.check(Animal.sheet(Animal.Breed.BONE_GIANT).size() > 0 or not ResourceLoader.exists(Animal.SHEETS[Animal.Breed.BONE_GIANT]),
		"the bone giant wears its painted sheet")
	# The aim: every grave marked, the one nearest the cursor ringed.
	var rules := Rules.new().setup(PackedStringArray(["gravetide"]), null, made[1], made[3], made[0], made[6])
	var aim := Targeting.new().setup(rules, made[0])
	aim.pick(0)
	var spots := aim.grave_spots()
	t.check(String(aim.area().get("shape", "")) == "graves" and spots.size() > 0 and spots == _graves_of(made)
		and aim.grave_spots() == spots,
		"the aim marks the town's graves, as a cast would find them (%d)" % spots.size())
	aim.free()
	rules.free()


## R41 over Aldermere's districts: every grave on open ground, GRAVES_MOST at most, GRAVE_GAP apart, the same each time. Every
## district reaches the graves (the F11 check, exact by construction): every candidate of every district snaps to open ground
## and lies within GRAVE_GAP of a grave kept -- which, as no candidate snaps more than GRAVE_SNAP cells, puts a grave within
## GRAVE_SNAP * CELL * sqrt(2) + GRAVE_GAP of every district.
static func _graves(t, made: Array) -> void:
	var grid: WalkGrid = made[2]
	var districts := City.current().districts()
	var spots := GraveTideFx.grave_spots(grid, districts)
	var open := true
	for p in spots:
		open = open and grid.walkable(p) and grid.on_streets(p)
	var apart := true
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			apart = apart and spots[i].distance_to(spots[j]) >= GraveTideFx.GRAVE_GAP
	t.check(spots.size() > 0 and spots.size() <= GraveTideFx.GRAVES_MOST and open and apart
		and spots == GraveTideFx.grave_spots(grid, districts),
		"graves across every district: %d, all on open ground with a way to the streets, %.1f apart at least, the same each time" % [spots.size(), GraveTideFx.GRAVE_GAP])
	var reached := true
	var worst := 0.0
	for d: Rect2 in districts:
		var mine := 0
		for c in [d.get_center(), d.position + d.size * 0.25, d.position + d.size * 0.75]:
			var p := grid.nearest_walkable(c, GraveTideFx.GRAVE_SNAP, true)
			if p == Vector2.INF:
				continue
			mine += 1
			var near := INF
			for s in spots:
				near = minf(near, s.distance_to(p))
			reached = reached and near < GraveTideFx.GRAVE_GAP
		var off := INF
		for s in spots:
			off = minf(off, s.distance_to(s.clamp(d.position, d.end)))
		worst = maxf(worst, off)
		reached = reached and mine > 0
	var bound := float(GraveTideFx.GRAVE_SNAP) * WalkGrid.CELL * sqrt(2.0) + GraveTideFx.GRAVE_GAP
	t.check(reached and worst <= bound,
		"every district's candidates lie within %.1f of a grave (the farthest district %.2f off its graves, bound %.2f)" % [GraveTideFx.GRAVE_GAP, worst, bound])


## Review Focus 5: a district built over (no open ground within GRAVE_SNAP cells) gives no grave; past GRAVES_MOST the graves
## kept are floor(i * n / GRAVES_MOST), spread over the whole town.
static func _stub_graves(t) -> void:
	var grid := StubGrid.new()
	var ds := [Rect2(0, 0, 4, 4), Rect2(10, 0, 4, 4), Rect2(20, 0, 4, 4)]
	grid.built.append(Rect2(10, 0, 4, 4))
	var spots := GraveTideFx.grave_spots(grid, ds)
	var none := true
	for p in spots:
		none = none and not Rect2(10, 0, 4, 4).grow(0.01).has_point(p)
	t.check(spots == [Vector2(2, 2), Vector2(22, 2)] and none,
		"a district built over is skipped: no grave from it (%s)" % [spots])
	var many := []
	for i in 40:
		many.append(Rect2(float(i) * 10.0, 0.0, 4.0, 4.0))
	var open := StubGrid.new()
	var kept := GraveTideFx.grave_spots(open, many)
	var spread := kept.size() == GraveTideFx.GRAVES_MOST
	if spread:
		for i in GraveTideFx.GRAVES_MOST:
			spread = spread and kept[i] == (many[i * 40 / GraveTideFx.GRAVES_MOST] as Rect2).get_center()
	t.check(spread and kept[0] == Vector2(2, 2) and kept[-1] == Vector2(382, 2),
		"40 districts keep 24 graves, taken floor(i * n / 24): spread to the last (%d, %s .. %s)" % [kept.size(), kept[0], kept[-1]])


## R44: always castable -- no remains anywhere, no refusal, the cooldown spent; the graves burst and the giant stands at the
## grave nearest the click (a tie to the lower index) at T_RISE + ASSEMBLE. A second cast is refused "cooldown".
static func _always(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var rules := Rules.new().setup(PackedStringArray(["gravetide"]), null, made[1], made[3], made[0], made[6])
	var casts := []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append(fx)
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var at := RD._empty(made)
	t.check((made[0] as Crowd).remains.all().is_empty() and rules.body_refusal("gravetide", "", at) == "",
		"(no body anywhere in town, and nothing to refuse)")
	var got := rules.cast(0, at) as GraveTideFx
	t.check(got != null and refused.is_empty() and rules.cooldown_left(0) > TierBook.clock(5),
		"no remains: it casts, and waits out the longest night (%s, %.0f s)" % [refused, rules.cooldown_left(0)])
	if got == null:
		rules.free()
		_soldiers_back(was)
		return
	var graves := _graves_of(made)
	var near := -1
	for i in graves.size():
		if near < 0 or graves[i].distance_to(at) < graves[near].distance_to(at):
			near = i
	t.check(got.graves == graves and got.graves.size() > 0 and got.giant_grave == near,
		"the graves burst (%d), the giant's is the one nearest the click (%d)" % [got.graves.size(), got.giant_grave])
	_run_bare(got, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	var g := got.giant
	t.check(g != null and g.breed == Animal.Breed.BONE_GIANT and g.ground_pos.distance_to(graves[near]) < 0.01
		and is_equal_approx(g.health, float(GraveTideFx.GIANT_BLOWS)) and got.landed_at >= GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.001,
		"the giant always comes: it stands at its grave at T_RISE + ASSEMBLE (%.2f off), %d blows"
		% [g.ground_pos.distance_to(graves[near]) if g != null else -1.0, int(g.health) if g != null else 0])
	var rule: Visitors.Rule = got.visitors._rules.get(g) if g != null else null
	t.check(rule != null and rule.wreck == GraveTideFx.GIANT_WRECK and not rule.wreck_idle and rule.bite >= Person.HEALTH_SOLDIER
		and not rule.flinch and rule.soldiers_only and rule.spare.is_valid(),
		"it claws at walls in its way (never idle), its blow fells a soldier, it does not flinch, hunts soldiers, spares (F10)")
	got.end_now()
	rules.cast(0, at)
	t.check(casts.size() == 1 and refused == [[0, "cooldown"]], "a second cast is refused (%s)" % [refused])
	rules.free()
	_soldiers_back(was)


## R41-R42: each grave raises a skeleton warrior and a ghoul, one either side of it, in burst order; after the last burst there
## are as many of each as there are graves. Each hunts from where it rose (no march) and claws at buildings, sparing.
static func _kinds(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	var n := fx.graves.size()
	RD._run(fx, GraveTideFx.T_RISE + 0.03)
	var first := fx.visitors.living()
	var by_first := first.size() == 2
	for a in first:
		by_first = by_first and (a as Animal).ground_pos.distance_to(fx.graves[0]) <= GraveTideFx.CLIMB_OUT + 0.2  # (a step on since)
	t.check(fx.burst == 1 and by_first and _of(fx, Animal.Breed.SKELETON).size() == 1 and _of(fx, Animal.Breed.GHOUL).size() == 1,
		"at T_RISE the first grave bursts: a skeleton warrior and a ghoul climb out beside it (%d burst, %d up: %s)"
		% [fx.burst, first.size(), first.map(func(a: Animal) -> float: return a.ground_pos.distance_to(fx.graves[0]))])
	RD._run(fx, GraveTideFx.T_RISE + float(n - 1) * GraveTideFx.BURST_STEP + 0.05 - fx.t)
	var sk := _of(fx, Animal.Breed.SKELETON)
	var gh := _of(fx, Animal.Breed.GHOUL)
	t.check(fx.burst == n and sk.size() == n and gh.size() == n and fx.raised == 2 * n and 2 * n <= GraveTideFx.LIVING_CAP,
		"each grave raises a skeleton warrior and a ghoul: %d graves, %d skeletons, %d ghouls" % [n, sk.size(), gh.size()])
	var armed := not sk.is_empty() and not gh.is_empty()
	for a in sk:
		var r: Visitors.Rule = fx.visitors._rules[a]
		armed = armed and r.wreck == GraveTideFx.SKELETON_WRECK and r.wreck_every == GraveTideFx.SKELETON_WRECK_EVERY
		armed = armed and r.wreck_idle and r.spare.is_valid() and r.prefer_soldiers and r.march == Vector2.INF
	for a in gh:
		var r: Visitors.Rule = fx.visitors._rules[a]
		armed = armed and r.wreck == GraveTideFx.GHOUL_WRECK and r.wreck_every == GraveTideFx.GHOUL_WRECK_EVERY
		armed = armed and r.wreck_idle and r.spare.is_valid() and r.knock_first and r.march == Vector2.INF
	t.check(armed, "skeletons claw 6 every 1.5 s, ghouls 3 every 1.0 s, both go at buildings with nobody near, spare, and nobody marches")
	fx.end_now()
	_soldiers_back(was)


## R44: the town's bodies rise on top as zombies, the oldest first, in the room the graves leave: 30 bodies give
## mini(30, LIVING_CAP - 2 * graves) zombies, the youngest still lying there; the living undead never pass LIVING_CAP. A grave
## whose two would pass the cap raises none.
static func _bodies_cap(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var spots := []
	for i in 30:
		spots.append((made[2] as WalkGrid).nearest_walkable(at + Vector2(-4.0 + float(i % 8) * 1.0, -2.0 + float(i / 8) * 1.0), 4))
	var rems := _bodies(made, spots)
	var fx := _cast(made, at)
	var n := fx.graves.size()
	var want := mini(30, GraveTideFx.LIVING_CAP - 2 * n)
	var worst := 0
	for i in roundi((GraveTideFx.T_RISE + float(n) * GraveTideFx.BURST_STEP + 1.0) / DT):
		fx._process(DT)
		worst = maxi(worst, fx.undead_up())
	var left := crowd.remains.all()
	var youngest := rems.slice(want)
	var same := left.size() == 30 - want
	for r in youngest:
		same = same and left.has(r)
	var zs := _of(fx, Animal.Breed.ZOMBIE)
	var clawing := not zs.is_empty()
	for a in zs:
		var r: Visitors.Rule = fx.visitors._rules[a]
		clawing = clawing and r.wreck == GraveTideFx.ZOMBIE_WRECK and r.wreck_every == GraveTideFx.ZOMBIE_WRECK_EVERY
		clawing = clawing and r.spare.is_valid() and r.march == Vector2.INF
	t.check(zs.size() == want and same and worst <= GraveTideFx.LIVING_CAP and fx.raised == 2 * n + want,
		"the town's bodies rise on top: 30 bodies, %d zombies (mini(30, 60 - 2 * %d)), the youngest %d still lie there; at most %d up"
		% [zs.size(), n, left.size(), worst])
	t.check(clawing, "the zombies claw 3 every 1.5 s, spare, and do not march")
	fx.end_now()
	# A grave whose two would pass the cap raises none: the pack filled to one short of it before the graves burst.
	RD._clear_all(made)
	fx = _cast(made, at)
	for i in GraveTideFx.LIVING_CAP - 1:
		fx._up_skeleton(at)
	RD._run(fx, GraveTideFx.T_RISE + float(n) * GraveTideFx.BURST_STEP + 0.1)
	t.check(fx.burst == n and fx.undead_up() == GraveTideFx.LIVING_CAP - 1 and _of(fx, Animal.Breed.GHOUL).is_empty(),
		"with %d up, every grave bursts and raises none (%d up)" % [GraveTideFx.LIVING_CAP - 1, fx.undead_up()])
	fx.end_now()
	_soldiers_back(was)


## Ruling R12: "bones fly in one by one, then the giant stands" -- halfway through ASSEMBLE no giant yet and some, not all,
## of the BONES in; at T_RISE + ASSEMBLE the giant stands with every bone in. Counted on the effect clock, staged or not.
static func _assemble(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE * 0.5)
	t.check(fx.giant == null and fx.bones_in > 0 and fx.bones_in < GraveTideFx.BONES and fx.landed_at < 0.0,
		"bones fly in one by one: halfway through, no giant and %d of %d bones in" % [fx.bones_in, GraveTideFx.BONES])
	_run_bare(fx, GraveTideFx.ASSEMBLE * 0.5 + 0.05)
	t.check(fx.giant != null and fx.bones_in == GraveTideFx.BONES and fx.landed_at >= GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.001,
		"then the giant stands, every bone in (%d), landed at %.2f" % [fx.bones_in, fx.landed_at])
	fx.end_now()
	_soldiers_back(was)


## "the landing slams": the landing is the first slam. A soldier 2 off dies (frenzy: a body lies there); a citizen 2 off
## lives, is frightened and is thrown back.
static func _landing(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var fx := _cast(made, RD._empty(made))
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.1)
	var spot := fx.giant_at
	var soldier: Person = null
	for s in crowd.soldiers:
		if is_instance_valid(s) and s.is_alive():
			soldier = s
			break
	var citizen := _put(made, 0, spot + Vector2(0.0, -2.0))
	t.check(soldier != null and fx.giant == null and fx.slams == 0, "(a soldier to stand by the giant's grave; nothing has landed yet)")
	if soldier == null:
		fx.end_now()
		return
	soldier.inside = false
	soldier.ground_pos = spot + Vector2(0.0, 2.0)
	soldier.health = Person.HEALTH_SOLDIER
	soldier.mind = Person.Mind.CALM
	var from := citizen.ground_pos.distance_to(spot)
	var dead_at := soldier.ground_pos
	var kinds := []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e == soldier:
			kinds.append(kind)
	field.enemy_killed.connect(on_kill)
	_run_bare(fx, 0.15)
	field.enemy_killed.disconnect(on_kill)
	t.check(fx.giant != null and fx.slams == 1, "the landing is the first slam (%d)" % fx.slams)
	crowd.remains.step(0.01)
	t.check(not soldier.is_alive() and kinds == [&"frenzy"] and crowd.remains.pick(dead_at) != null,
		"a soldier 2 off dies (%s), and his body lies there" % [kinds])
	var knocked := citizen.state == DummyEnemy.State.KNOCKBACK
	_run_bare(fx, 0.5, [citizen])
	var away := citizen.ground_pos.distance_to(spot) - from
	t.check(citizen.is_alive() and knocked and (citizen.mind == Person.Mind.PANIC or citizen.mind == Person.Mind.FLEE) and away >= 0.3,
		"a citizen 2 off lives, knocked back (%s) and frightened (mind %d), thrown %.2f farther off" % [knocked, citizen.mind, away])
	fx.end_now()


## "a slam every SLAM_EVERY s": the landing's, then one at landed_at + SLAM_EVERY and + 2 SLAM_EVERY.
static func _slam_every(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	var first := fx.slams
	_run_bare(fx, fx.landed_at + GraveTideFx.SLAM_EVERY - 0.1 - fx.t)
	var before := fx.slams
	_run_bare(fx, fx.landed_at + 2.0 * GraveTideFx.SLAM_EVERY + 0.05 - fx.t)
	t.check(first == 1 and before == 1 and fx.slams == 3,
		"a slam every %.0f s: %d at the landing, %d just before the next, %d at landed_at + %.0f" % [GraveTideFx.SLAM_EVERY, first, before, fx.slams, 2.0 * GraveTideFx.SLAM_EVERY])
	fx.end_now()
	_soldiers_back(was)


## Review Focus 4: "no slam once the giant falls" -- cut down, it slams no more.
static func _no_slam_fallen(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	var g := fx.giant
	t.check(g != null, "(the giant stands)")
	if g == null:
		fx.end_now()
		_soldiers_back(was)
		return
	# Cut down as a guard's last blow does it: its health gone, the pack forgets it, cut_down heard.
	var where := g.ground_pos
	g.hurt(float(GraveTideFx.GIANT_BLOWS))
	fx.visitors._rules.erase(g)
	fx.visitors.cut_down.emit(g, where)
	var n := fx.slams
	_run_bare(fx, GraveTideFx.SLAM_EVERY * 2.0 + 0.5)
	t.check(fx.giant == null and n == 1 and fx.slams == n, "no slam once the giant falls (%d -> %d)" % [n, fx.slams])
	fx.end_now()
	if is_instance_valid(g):
		g.free()
	_soldiers_back(was)


## The giant's blow kills a soldier outright (a zombie's only wounds one).
static func _soldier(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var fx := _cast(made, RD._empty(made))
	var bites := []
	fx.visitors.bitten.connect(func(a: Animal, v: Person, _first: bool) -> void:
		bites.append([a.breed, is_instance_valid(v) and v.is_alive()]))
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	var soldier: Person = null
	for s in crowd.soldiers:
		if is_instance_valid(s) and s.is_alive() and s.corps != Person.Corps.KNIGHT:
			soldier = s
			break
	t.check(fx.giant != null and soldier != null, "(the giant stands, and a soldier is left to stand by it)")
	if fx.giant == null or soldier == null:
		fx.end_now()
		return
	soldier.inside = false
	soldier.ground_pos = fx.giant.ground_pos + Vector2(0.0, 0.5)
	soldier.health = Person.HEALTH_SOLDIER
	soldier.mind = Person.Mind.CALM
	_run_bare(fx, Visitors.RETARGET + 0.3)
	t.check(not bites.is_empty() and bites[0][0] == Animal.Breed.BONE_GIANT and not bites[0][1] and not soldier.is_alive(),
		"the giant's blow kills a soldier outright (%s)" % [bites])
	fx.end_now()


## F10: on a leg of its tour (a march turns only on prey within Visitors.MARCH_SEEK), a soldier out in the open within
## GIANT_SEEK ends the leg -- the hunt takes him, the grave not counted visited; with him gone the tour goes on.
static func _soldier_leg(t, made: Array) -> void:
	RD._clear_all(made)
	var grid: WalkGrid = made[2]
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + GraveTideFx.GIANT_LOOK + 0.1)
	var g := fx.giant
	var on_leg := g != null and fx.visitors.marching(g)
	var leg := fx._leg
	var soldier: Person = null
	for s in was:
		if is_instance_valid(s) and s.is_alive() and s.corps != Person.Corps.KNIGHT:
			soldier = s
			break
	var spot := Vector2.INF
	if g != null:
		for i in 16:
			var p := grid.nearest_walkable(g.ground_pos + Vector2.from_angle(TAU * float(i) / 16.0) * 5.0, 4)
			var d := p.distance_to(g.ground_pos) if p != Vector2.INF else INF
			if d > Visitors.MARCH_SEEK + 1.0 and d < GraveTideFx.GIANT_SEEK - 2.0:
				spot = p
				break
	t.check(on_leg and leg >= 0 and soldier != null and spot != Vector2.INF, "(the giant is on a leg of its tour, a soldier to put by it: %s, leg %d, %s, %s)" % [on_leg, leg, soldier != null, spot])
	if not on_leg or soldier == null or spot == Vector2.INF:
		fx.end_now()
		_soldiers_back(was)
		return
	soldier.inside = false
	soldier.ground_pos = spot
	soldier.health = Person.HEALTH_SOLDIER
	soldier.mind = Person.Mind.CALM
	_run_bare(fx, GraveTideFx.GIANT_LOOK + 0.1)
	t.check(not fx.visitors.marching(g) and g.target == soldier and not fx.visited.has(leg),
		"a soldier %.1f off (past the march's %.1f, within %.0f) ends the leg, and the hunt takes him; that grave not visited"
		% [spot.distance_to(g.ground_pos), Visitors.MARCH_SEEK, GraveTideFx.GIANT_SEEK])
	soldier.inside = true
	_run_bare(fx, 2.0 * GraveTideFx.GIANT_LOOK + 0.6)
	t.check(fx.visitors.marching(g) and fx._leg >= 0, "with him gone, the tour goes on (to grave %d)" % fx._leg)
	fx.end_now()
	_soldiers_back(was)


## "aura speeds undead near the giant": AURA_SPEED times their pace within GIANT_AURA, their own pace back outside it. The
## town's bodies lie by the giant's grave.
static func _aura(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var at := RD._empty(made)
	var graves := _graves_of(made)
	var g := graves[GraveTideFx.nearest_grave(graves, at)]
	_bodies(made, _ring(made, g, 5, 1.5))
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.2)
	var zs := _of(fx, Animal.Breed.ZOMBIE)
	var base := DeathParts.ZOMBIE_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var fast := zs.size() == 5
	for a in zs:
		fast = fast and is_equal_approx((a as Animal).speed_mul, base * GraveTideFx.AURA_SPEED)
	var g_base := fx.giant.speed_mul if fx.giant != null else 0.0
	t.check(fast and fx.giant != null and is_equal_approx(g_base, GraveTideFx.GIANT_PACE / (Animal.DOG_SPEED * Animal.RUN)),
		"aura speeds undead near the giant: x%.1f within %.0f (the giant itself at its own pace)" % [GraveTideFx.AURA_SPEED, GraveTideFx.GIANT_AURA])
	if not fast or fx.giant == null:
		fx.end_now()
		_soldiers_back(was)
		return
	var out: Animal = zs[0]
	out.ground_pos = fx.giant.ground_pos + Vector2(GraveTideFx.GIANT_AURA + 3.0, 0.0)
	RD._run(fx, 0.3)
	t.check(is_equal_approx(out.speed_mul, base) and is_equal_approx((zs[1] as Animal).speed_mul, base * GraveTideFx.AURA_SPEED),
		"one that leaves the aura has its own pace back; the rest keep the speed (%.3f, %.3f)" % [out.speed_mul, (zs[1] as Animal).speed_mul])
	out.ground_pos = fx.giant.ground_pos + Vector2(1.0, 0.0)
	RD._run(fx, 0.3)
	t.check(is_equal_approx(out.speed_mul, base * GraveTideFx.AURA_SPEED), "and it is sped again as it comes back")
	fx.end_now()
	_soldiers_back(was)


## Review IMPORTANT 1 (spec 5.8, "Death's undead within 6 of the giant move 20% faster"): another power's zombie -- Raise the
## Dead's -- standing by the giant is quickened too, and has its pace back as it leaves or as the giant goes (carried off by
## another power: its node freed with no cut_down); a hellhound of another pack beside it never is.
static func _aura_others(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var was := _soldiers_in(made)
	var at := RD._empty(made)
	var graves := _graves_of(made)
	var g := graves[GraveTideFx.nearest_grave(graves, at)]
	var beside := grid.nearest_walkable(g + Vector2(0.0, 3.0), 4)
	_bodies(made, [beside])
	var raise := FxTimeline.cast(RaiseTheDeadFx, made[5], beside, {"mode": "zombie"}) as RaiseTheDeadFx
	var fx := _cast(made, at)
	var hounds := Visitors.new().setup(made[3], crowd, made[2], made[4])
	var hound := hounds.summon(g + Vector2(-2.0, 0.0), Animal.Breed.HELLHOUND, 4, 1.0, 0.0, 0.5, 1.0, false)
	var both := func(seconds: float) -> void:
		for i in roundi(seconds / DT):
			if not fx.finished:
				fx._process(DT)
			if not raise.finished:
				raise._process(DT)
	both.call(GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.2)
	var z: Animal = raise.visitors.living()[0] if raise.visitors.living().size() == 1 else null
	t.check(z != null and fx.giant != null and z.ground_pos.distance_to(fx.giant.ground_pos) <= GraveTideFx.GIANT_AURA,
		"(a Raise the Dead zombie stands by the giant)")
	if z == null or fx.giant == null:
		fx.end_now()
		raise.end_now()
		hounds.clear()
		_soldiers_back(was)
		return
	var own := DeathParts.ZOMBIE_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	t.check(is_equal_approx(z.speed_mul, own * GraveTideFx.AURA_SPEED) and is_equal_approx(hound.speed_mul, 1.0),
		"another power's zombie by the giant is quickened x%.1f (%.3f); a hellhound beside it is not (%.2f)" % [GraveTideFx.AURA_SPEED, z.speed_mul, hound.speed_mul])
	z.ground_pos = fx.giant.ground_pos + Vector2(GraveTideFx.GIANT_AURA + 3.0, 0.0)
	both.call(0.3)
	t.check(is_equal_approx(z.speed_mul, own), "it has its own pace back as it leaves the aura (%.3f)" % z.speed_mul)
	z.ground_pos = fx.giant.ground_pos + Vector2(1.0, 0.0)
	both.call(0.3)
	var again := is_equal_approx(z.speed_mul, own * GraveTideFx.AURA_SPEED)
	fx.visitors.take(fx.giant)  # another power carries the giant off: freed, no cut_down
	both.call(0.3)
	var mine := true
	for a in _horde(fx):
		mine = mine and is_equal_approx((a as Animal).speed_mul, _own_pace(a))
	t.check(again and is_equal_approx(z.speed_mul, own) and mine and fx.giant == null,
		"quickened again as it comes back; the giant gone, every one has its own pace back (%.3f; the tide's own: %s)" % [z.speed_mul, mine])
	fx.end_now()
	raise.end_now()
	hounds.clear()
	_soldiers_back(was)


## Final review 2 (R27): the aura scales a walker's pace by its ratio, as Walking Corpse's attack pace does (R18), so the two
## compose in either order: an attack started in the aura, the aura left, the attack ended -- its summoned pace back; an attack
## started outside, the aura entered, the attack ended, the aura left -- its summoned pace back too.
static func _aura_walker(t, made: Array) -> void:
	RD._clear_all(made)
	var grid: WalkGrid = made[2]
	var at := RD._empty(made)
	var graves := _graves_of(made)
	var g := graves[GraveTideFx.nearest_grave(graves, at)]
	var fx := _cast(made, at)
	var beside := grid.nearest_walkable(g + Vector2(0.0, 2.5))
	_bodies(made, [beside])  # after the tide's pick: the walker's body, not the tide's
	var wc := FxTimeline.cast(WalkingCorpseFx, made[5], beside, {"to": beside}) as WalkingCorpseFx
	var both := func(seconds: float) -> void:
		for i in roundi(seconds / DT):
			if not fx.finished:
				fx._process(DT)
				for a in _horde(fx):
					fx.visitors.take(a)  # the tide's own horde gone: nobody but the walker goes for the foe
			if not wc.finished:
				wc._process(DT)
	both.call(GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.2)
	var w := wc.walker
	t.check(w != null and fx.giant != null and w.ground_pos.distance_to(fx.giant.ground_pos) <= GraveTideFx.GIANT_AURA
		and is_equal_approx(w.speed_mul, wc._pace * GraveTideFx.AURA_SPEED), "(the walker stands in the giant's aura, quickened)")
	if w == null or fx.giant == null:
		fx.end_now()
		wc.end_now()
		return
	var foe: Person = _alive(made)[0]
	# In the aura: attack, leave, end the attack.
	foe.ground_pos = grid.nearest_walkable(w.ground_pos + (w.ground_pos - fx.giant.ground_pos).normalized() * 4.0)
	foe.statuses.erase(&"guise")
	t.check(wc.follow_up(foe.ground_pos, {"order": "attack", "foe": foe}), "(an attack is taken in the aura)")
	w.ground_pos = fx.giant.ground_pos + Vector2(GraveTideFx.GIANT_AURA + 4.0, 0.0)
	both.call(0.3)
	foe.statuses[&"guise"] = 5.0  # guised: the chase ends with no kill
	both.call(0.1)
	t.check(wc.order == "wait" and is_equal_approx(w.speed_mul, wc._pace),
		"attack in the aura, leave it, end the attack: its summoned pace back (%.4f, want %.4f)" % [w.speed_mul, wc._pace])
	# Outside: attack, come into the aura, end the attack, leave.
	foe.statuses.erase(&"guise")
	foe.ground_pos = grid.nearest_walkable(w.ground_pos + Vector2(3.0, 0.0))
	t.check(wc.follow_up(foe.ground_pos, {"order": "attack", "foe": foe}), "(an attack is taken outside the aura)")
	w.ground_pos = fx.giant.ground_pos + Vector2(1.0, 0.0)
	both.call(0.3)
	var quick := is_equal_approx(w.speed_mul, wc._pace * WalkingCorpseFx.ATTACK_PACE * GraveTideFx.AURA_SPEED)
	foe.statuses[&"guise"] = 5.0
	both.call(0.1)
	w.ground_pos = fx.giant.ground_pos + Vector2(GraveTideFx.GIANT_AURA + 4.0, 0.0)
	both.call(0.3)
	t.check(quick and wc.order == "wait" and is_equal_approx(w.speed_mul, wc._pace),
		"attack outside, enter the aura, end the attack, leave: its summoned pace back (%.4f, want %.4f)" % [w.speed_mul, wc._pace])
	foe.statuses.erase(&"guise")
	fx.end_now()
	wc.end_now()


## Review minor (a): a visitor whose node another power freed is still in its pack; clear() frees the rest without an error.
static func _freed_clear(t, made: Array) -> void:
	var v := Visitors.new().setup(made[3], made[0], made[2], made[4])
	var at := RD._empty(made)
	var gone := v.summon(at, Animal.Breed.ZOMBIE, 3, 1.0, 0.0, 0.5, 1.0, true)
	var kept := v.summon(at + Vector2(1.0, 0.0), Animal.Breed.ZOMBIE, 3, 1.0, 0.0, 0.5, 1.0, true)
	gone.free()
	v.clear()
	t.check(v._rules.is_empty() and not is_instance_valid(kept) and not (made[0] as Crowd).visitors.has(v),
		"a freed visitor's pack clears without an error, the rest freed")


## "cut short mid-burst: no more graves, no giant" -- ended a moment after the first graves burst, no grave bursts after,
## the giant never comes, and the pack is gone.
static func _cut_short(t, made: Array) -> void:
	RD._clear_all(made)
	var fx := _cast(made, RD._empty(made))
	RD._run(fx, GraveTideFx.T_RISE + 0.3)
	var b := fx.burst
	var up := fx.undead_up()
	fx._finish()
	for i in roundi(3.0 / DT):
		fx._process(DT)
	t.check(b > 0 and b < fx.graves.size() and up == 2 * b and fx.burst == b and fx.giant == null and fx.slams == 0
		and fx.visitors.living().is_empty() and fx.finished,
		"cut short mid-burst (%d of %d graves): no more graves, no giant, nobody left" % [b, fx.graves.size()])


## Freed without its end (a mission torn down): the pack is cleared, nothing errors.
static func _exit(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.3)
	var pack := fx.visitors
	var up := pack.living()
	t.check(up.size() > 2 and fx.giant != null, "the horde and the giant up (%d)" % up.size())
	fx._exit_tree()
	var gone := true
	for a in up:
		gone = gone and (not is_instance_valid(a) or a.is_queued_for_deletion())
	t.check(gone and pack.living().is_empty() and not (made[0] as Crowd).visitors.has(pack) and fx.giant == null,
		"freed without its end, the pack is cleared and leaves the town")
	fx.end_now()
	t.check(fx.finished, "and its end after that changes nothing")
	_soldiers_back(was)


## One cast for the staged check: a soldier 2 off the giant's grave as it lands, run to past the second slam (the horde taken
## off as it rises). Counts the bones in mid-assembly, the slams, whether the soldier died, the graves burst, and (staged) the
## flying bones, slam marks and grave pits drawn. Each `await` lets the tree draw a frame with the effect itself held still, so
## staged and headless run the same clock.
static func _slam_run(t, made: Array, staged: bool) -> Dictionary:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var ctx: FxContext = made[5]
	var fx := _cast(made, RD._empty(made))
	var out := {"bones": 0, "slams": 0, "dead": false, "burst": 0, "drawn_bones": 0, "marks": 0, "pits": 0}
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE * 0.5)
	out.bones = fx.bones_in
	if staged:
		fx.set_process(false)
		await t.process_frame
		fx.set_process(true)
		for n in fx.stand_layer().get_children():
			out.drawn_bones += 1 if n is GraveTideFx.Bones else 0
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.1 - fx.t)
	var soldier: Person = was.keys()[0] if not was.is_empty() else null
	if soldier != null:
		soldier.inside = false
		soldier.ground_pos = fx.giant_at + Vector2(2.0, 0.0)
		soldier.health = Person.HEALTH_SOLDIER
	_run_bare(fx, GraveTideFx.SLAM_EVERY + 0.3)
	out.slams = fx.slams
	out.dead = soldier != null and not soldier.is_alive()
	out.burst = fx.burst
	if staged:
		fx.set_process(false)
		await t.process_frame
		fx.set_process(true)
		for n in ctx.ground.get_children():
			out.marks += 1 if n is GraveTideFx.SlamMark else 0
			out.pits += 1 if n is GraveTideFx.GravePit else 0
	fx.end_now()
	_soldiers_back(was)
	return out


## Staged (the effect in the tree with an Impact, as in the game): the bones are drawn flying in, each slam leaves its mark
## (ring and cracks) and each burst grave its pit on the ground layer, and none of it changes the logic -- staged or headless,
## the same bones, slams, graves and dead.
static func _staged(t, made: Array) -> void:
	var plain: Dictionary = await _slam_run(t, made, false)
	var ctx: FxContext = made[5]
	var keep := [ctx.overhead, ctx.ground, ctx.overhead_back]
	var stage := Node2D.new()
	t.root.add_child(stage)
	await t.process_frame  # (the tree is only live after the first frame)
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.overhead_back = Node2D.new()
	for n in [ctx.ground, ctx.overhead_back, ctx.overhead]:
		stage.add_child(n)
	var stub := FxStage.StageImpact.new()
	ctx.impact = stub
	var lit: Dictionary = await _slam_run(t, made, true)
	ctx.impact = null
	stub.free()
	ctx.overhead = keep[0]
	ctx.ground = keep[1]
	ctx.overhead_back = keep[2]
	t.root.remove_child(stage)
	stage.free()
	t.check(int(lit.drawn_bones) == 1 and int(lit.marks) == 2 and int(lit.pits) == int(lit.burst) and int(lit.burst) > 0,
		"staged: the bones are drawn flying in, each slam leaves its mark (%d), each burst grave its pit (%d of %d)"
		% [lit.marks, lit.pits, lit.burst])
	t.check(lit.bones == plain.bones and lit.slams == plain.slams and lit.dead == plain.dead and lit.burst == plain.burst
		and int(plain.slams) == 2 and plain.dead,
		"staged or not, the same bones (%d/%d), slams (%d/%d), graves (%d/%d) and dead (%s/%s)"
		% [lit.bones, plain.bones, lit.slams, plain.slams, lit.burst, plain.burst, lit.dead, plain.dead])


## R43: "the giant walks the graves" -- by the streets to the nearest grave it has not visited, then the next: 30 s after its
## landing it has visited two graves at least (its own the first, the nearest to it the second) and stands 4 or more off its
## own.
static func _tour(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	var own := fx.giant_at
	var rest: Array[Vector2] = []
	var index: Array[int] = []
	for i in fx.graves.size():
		if i != fx.giant_grave:
			rest.append(fx.graves[i])
			index.append(i)
	var second := index[GraveTideFx.nearest_grave(rest, own)] if not rest.is_empty() else -1
	_run_bare(fx, 30.0)
	var g := fx.giant
	t.check(g != null and fx.visited.size() >= 2 and fx.visited[0] == fx.giant_grave and fx.visited[1] == second
		and g.ground_pos.distance_to(own) >= 4.0,
		"the giant walks the graves: %d visited (%s, the nearest second: %d), %.1f off its own"
		% [fx.visited.size(), fx.visited, second, g.ground_pos.distance_to(own) if g != null else -1.0])
	fx.end_now()
	_soldiers_back(was)


## R43: "a slam knocks a house down" -- a house (50 hp) 2.0 or less from the giant's grave falls to the landing's slam.
static func _slam_house(t, made: Array) -> void:
	RD._clear_all(made)
	var env: EnvironmentField = made[1]
	var was := _soldiers_in(made)
	var graves := _graves_of(made)
	var house: Structure = null
	var at := Vector2.INF
	for s in env.structures():
		if not Visitors._wreckable(s) or s.kind != Structure.Kind.HOUSE or s.role != &"house" or s.hp != 50.0:
			continue
		for g in graves:
			if s.distance_to(g) <= 2.0 and not MissionKeeps.spared(s, made[0], null):
				house = s
				at = g
				break
		if house != null:
			break
	t.check(house != null, "(a house of 50 hp within 2 of a grave)")
	if house == null:
		_soldiers_back(was)
		return
	var fx := _cast(made, at)
	_run_bare(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.05)
	var standing := not house.destroyed and house.hp == 50.0 and fx.slams == 0
	_run_bare(fx, 0.1)
	t.check(standing and fx.slams == 1 and house.destroyed and fx.slam_wrecks >= 1,
		"a slam knocks a house down: %.1f from the landing, standing before it, down after (%d struck)" % [house.distance_to(at), fx.slam_wrecks])
	fx.end_now()
	_soldiers_back(was)


## The open ground beside building `s`.
static func _beside(grid: WalkGrid, s: Structure) -> Vector2:
	return grid.nearest_walkable(Vector2(s.footprint.end.x + 0.3, s.center().y), 6)


## R45: "a building the night needs is never damaged" -- the temple and a house the night's director holds, with skeletons
## beside them and slams on them, keep every hp for 20 s; a plain house beside them is clawed.
static func _spared(t, made: Array) -> void:
	RD._clear_all(made)
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var was := _soldiers_in(made)
	var temple: Structure = null
	for s in env.structures():
		if s.role == &"temple" and not s.destroyed:
			temple = s
			break
	var houses: Array[Structure] = []
	if temple != null:
		for s in env.near(temple.center(), 10.0):
			if Visitors._wreckable(s) and s.kind == Structure.Kind.HOUSE and s.role == &"house" and _beside(grid, s) != Vector2.INF:
				houses.append(s)
		houses.sort_custom(func(a: Structure, b: Structure) -> bool: return a.distance_to(temple.center()) < b.distance_to(temple.center()))
	t.check(temple != null and houses.size() >= 2 and _beside(grid, temple) != Vector2.INF, "(the temple, and two houses near it)")
	if temple == null or houses.size() < 2:
		_soldiers_back(was)
		return
	var held := houses[0]
	var plain := houses[1]
	var director := HoldDirector.new()
	director.held = held
	var rules := Rules.new()
	rules.director = director
	ctx.rules = rules
	var fx := _cast(made, RD._empty(made))
	RD._run(fx, GraveTideFx.T_RISE + 0.1)
	var hp := [temple.hp, held.hp, plain.hp]
	for s in [temple, held, plain]:
		for i in 2:
			fx._up_skeleton(_beside(grid, s))
	fx._slam(_beside(grid, temple))
	fx._slam(_beside(grid, held))
	RD._run(fx, 20.0)
	t.check(temple.hp == hp[0] and not temple.destroyed and held.hp == hp[1] and not held.destroyed,
		"a building the night needs is never damaged: the temple (%.0f -> %.0f) and the held house (%.0f -> %.0f), skeletons beside them and slammed"
		% [hp[0], temple.hp, hp[1], held.hp])
	t.check(plain.destroyed or plain.hp < hp[2], "a plain house beside them is clawed (%.0f -> %.0f)" % [hp[2], plain.hp])
	fx.end_now()
	ctx.rules = null
	rules.free()
	_soldiers_back(was)


## R45 at the tide's level: a building the night wants down is the god's to spoil even where it would be spared (the temple,
## a Raze target here) -- clawed and slammed -- while a house it needs standing beside it keeps every hp.
static func _wanted_down(t, made: Array) -> void:
	RD._clear_all(made)
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var was := _soldiers_in(made)
	var temple: Structure = null
	for s in env.structures():
		if s.role == &"temple" and not s.destroyed:
			temple = s
			break
	var held: Structure = null
	if temple != null:
		var best := INF
		for s in env.near(temple.center(), 10.0):
			if Visitors._wreckable(s) and s.kind == Structure.Kind.HOUSE and s.role == &"house" and _beside(grid, s) != Vector2.INF 					and s.distance_to(temple.center()) < best:
				best = s.distance_to(temple.center())
				held = s
	t.check(temple != null and held != null and _beside(grid, temple) != Vector2.INF
		and MissionKeeps.spared(temple, made[0], null), "(the temple, spared on a plain night, and a house near it)")
	if temple == null or held == null:
		_soldiers_back(was)
		return
	var director := WantDirector.new()
	director.want = temple
	director.held = held
	var rules := Rules.new()
	rules.director = director
	ctx.rules = rules
	var fx := _cast(made, RD._empty(made))
	RD._run(fx, GraveTideFx.T_RISE + 0.1)
	var hp := [temple.hp, held.hp]
	for s in [temple, held]:
		for i in 2:
			fx._up_skeleton(_beside(grid, s))
	fx._slam(_beside(grid, temple))
	var slammed: bool = temple.destroyed or temple.hp < float(hp[0])
	fx._slam(_beside(grid, held))
	RD._run(fx, 20.0)
	t.check(slammed and (temple.destroyed or temple.hp < hp[0]),
		"a building the night wants down is slammed and clawed even where it would be spared: the temple (%.0f -> %.0f)"
		% [hp[0], temple.hp])
	t.check(held.hp == hp[1] and not held.destroyed,
		"one it needs standing beside it is not (%.0f -> %.0f)" % [hp[1], held.hp])
	fx.end_now()
	ctx.rules = null
	rules.free()
	_soldiers_back(was)


## "the giant outlives the horde": at LIFE the horde falls to ash and the giant stands on; GIANT_LIFE after its landing it is
## gone too, and the tide is over.
static func _life(t, made: Array) -> void:
	RD._clear_all(made)
	var was := _soldiers_in(made)
	var fx := _cast(made, RD._empty(made))
	RD._run(fx, GraveTideFx.LIFE - 0.2)
	var up := fx.undead_up()
	t.check(up > 0 and fx.giant != null, "up to LIFE the horde stands (%d) with the giant" % up)
	RD._run(fx, GraveTideFx.LIFE + 1.0 - fx.t)
	var g := fx.giant
	t.check(fx.undead_up() == 0 and g != null and is_instance_valid(g) and g.is_alive() and fx.visitors.living() == [g]
		and not fx.finished,
		"the giant outlives the horde: at LIFE the horde falls to ash (%d left), the giant stands" % fx.undead_up())
	RD._run(fx, fx.landed_at + GraveTideFx.GIANT_LIFE - 0.3 - fx.t)
	t.check(fx.giant != null and not fx.finished, "it stands to the end of its GIANT_LIFE")
	RD._run(fx, fx.landed_at + GraveTideFx.GIANT_LIFE + GraveTideFx.FADE + 0.2 - fx.t)
	t.check(fx.giant == null and fx.visitors.living().is_empty() and fx.finished,
		"GIANT_LIFE after its landing it is gone, and the tide is over")
	_soldiers_back(was)


## The whole tide in the full town (220 people where the day put them), cast at the market with thirty bodies lying round it:
## every grave's two, the zombies up to the cap and the giant, from just before the landing to past landed_at + 2 SLAM_EVERY
## (the landing's slam and two more), at 60 frames a second: _fx_process + visitors.step under PERF_MS a frame.
static func _perf(t) -> void:
	var made := RD._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var spots := []
	for i in 30:
		spots.append(grid.nearest_walkable(at + Vector2.from_angle(TAU * float(i) / 30.0) * (1.5 + float(i % 3) * 1.5), 4))
	_bodies(made, spots)
	var fx := _cast(made, at)
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE - 0.1)
	var frame := 1.0 / 60.0
	var frames := ceili((0.1 + 2.0 * GraveTideFx.SLAM_EVERY + 0.2) / frame)
	var worst := 0.0
	var slam_worst := 0.0
	var peak := 0
	var t0 := Time.get_ticks_usec()
	for i in frames:
		var before := fx.slams
		var f0 := Time.get_ticks_usec()
		fx._process(frame)
		var f_ms := float(Time.get_ticks_usec() - f0) / 1000.0
		worst = maxf(worst, f_ms)
		if fx.slams > before:
			slam_worst = maxf(slam_worst, f_ms)
		peak = maxi(peak, fx.undead_up())
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(frames)
	var full := 2 * fx.graves.size() + mini(30, GraveTideFx.LIVING_CAP - 2 * fx.graves.size())
	print("TIDE perf: %.3f ms a frame over %d frames, worst %.3f ms, worst slam frame %.3f ms (%d slams, %d graves, peak %d undead, %d up at the end, %d alive in town)"
		% [ms, frames, worst, slam_worst, fx.slams, fx.graves.size(), peak, fx.undead_up(),
		(crowd.citizens + crowd.soldiers).filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive()).size()])
	t.check(fx.giant != null and fx.raised == full and fx.slams >= 3 and frames >= PERF_FRAMES and ms < PERF_MS,
		"the whole tide (%d of %d risen, %d at its peak) + the giant + %d slams: _fx_process + visitors.step under %.0f ms a frame averaged over %d frames (%.3f ms)"
		% [fx.raised, full, peak, fx.slams, PERF_MS, frames, ms])
	fx.end_now()
	RD._done(made)


## Level 5, Scattered Bones, the bones out: the tide at its cap (the graves' 2 each and the town's bodies, none lying here, so
## the bones take the room the graves' dead leave, up to 18), the giant cut down just after its landing, then PERF_FRAMES frames of the
## whole pack (_fx_process + visitors.step) under PERF_MS a frame averaged.
static func _perf_bones(t) -> void:
	var made := RD._setup()
	var grid: WalkGrid = made[2]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var fx := FxTimeline.cast(GraveTideFx, made[5], at, {"level": 5}) as GraveTideFx
	RD._run(fx, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.1)
	var g := fx.giant
	var where := g.ground_pos
	g.hurt(float(fx.lv_giant_blows))
	fx.visitors._rules.erase(g)
	fx.visitors.cut_down.emit(g, where)
	g.free()
	var bones := fx._scattered.size()
	var room := GraveTideFx.LIVING_CAP - (fx.undead_up() - bones)
	var frame := 1.0 / 60.0
	var t0 := Time.get_ticks_usec()
	var peak := 0
	for i in PERF_FRAMES:
		fx._process(frame)
		peak = maxi(peak, fx.undead_up())
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(PERF_FRAMES)
	print("TIDE perf (level 5, bones out): %.3f ms a frame over %d frames (%d bones, peak %d undead)" % [ms, PERF_FRAMES, bones, peak])
	t.check(bones == mini(GraveTideFx.SCATTER_MOST, room) and bones > 0 and peak <= GraveTideFx.LIVING_CAP and ms < PERF_MS,
		"level 5 with the %d bones out (peak %d of %d): the pack under %.0f ms a frame averaged over %d frames (%.3f ms)"
		% [bones, peak, GraveTideFx.LIVING_CAP, PERF_MS, PERF_FRAMES, ms])
	fx.end_now()
	RD._done(made)
