extends RefCounted
## The Closing Cage (Decree, Tier V; spec 5.9): a ring of brass bars carved with law rises round a district of 12, and over
## 30 s slides in toward the middle until it is 1.5 across. Nobody can pass the bars (one NO LEAVING law whose radius
## shrinks): people and visitors at the bars are pushed inward ahead of them; one whose inward step is blocked by a
## building the bars have not yet felled is cut down there (kill kind crushed). A building cracks as the bars touch it
## and falls when they pass its middle, crushing whoever shelters in it. At the end everyone still inside dies; whoever
## stood outside 12 at the cast is untouched, and whoever walked in during the close is caged too. All by distance.

const PATH := "res://src/fx/decree/the_closing_cage.gd"
const DT := 0.1
## Ground east of the market, cleared for the test: the cage closes on C.
const C := Vector2(17.0, -4.0)
const CLEAR_R := 14.0


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## The effect's frames, DT at a time, until its clock reads `until`.
static func _run_to(fx: FxTimeline, until: float) -> void:
	while fx.t < until - 0.001 and not fx.finished:
		fx._process(DT)


static func run(t) -> void:
	var b := PowerBook.get_power("cage")
	var area: Dictionary = Targeting.AREAS.get("cage", {})
	t.check(String(b.get("name", "")) == "The Closing Cage" and int(b.get("dp", 0)) == 6 and float(b.get("cooldown", 0.0)) == 999.0
		and String(b.get("aim", "")) == "click" and not PowerBook.is_quiet("cage") and PowerBook.authority_of("cage") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "circle"
		and is_equal_approx(float(area.get("r", 0.0)), 12.0) and Rules.POWER_KINDS.get("cage", null) == [&"crushed"]
		and PowerBook.family("cage") == "decree" and PowerBook.REACH.has("cage") and String(b.get("shape", "")).contains("once a descent"),
		"The Closing Cage: Decree, 6 Might, once a descent, a click, loud, a circle of 12, kills by crushing (%s)" % [b])
	var cf = load(PATH) if ResourceLoader.exists(PATH) else null
	if cf == null:
		t.check(false, "the effect script loads")
		return
	t.check(is_equal_approx(PowerBook.impact("cage"), float(cf.T_LAND)), "its danger lands as the bars stand (%.2f)" % PowerBook.impact("cage"))
	t.check(is_equal_approx(cf.RADIUS, 12.0) and is_equal_approx(cf.END_R, 0.75) and is_equal_approx(cf.CLOSE_TIME, 30.0),
		"12 across to 1.5 across over 30 s")
	t.check(is_equal_approx(cf.radius_at(cf.T_LAND), 12.0) and absf(cf.radius_at(cf.T_LAND + 15.0) - 6.4) < 0.05
		and is_equal_approx(cf.radius_at(cf.T_LAND + 30.0), 0.75) and is_equal_approx(cf.radius_at(cf.T_LAND + 99.0), 0.75),
		"the bars close at an even pace: 6.4 at 15 s (%.3f)" % cf.radius_at(cf.T_LAND + 15.0))
	_closing(t, cf)
	_perf(t, cf)


static func _closing(t, cf) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var clear := Rect2(C - Vector2(CLEAR_R, CLEAR_R), Vector2(CLEAR_R, CLEAR_R) * 2.0)
	for s in env.structures().duplicate():
		if s.footprint.intersects(clear):
			env.remove(s, true, true)
	# A house 5 from the middle, a wall 6 north of it, a house straddling the ring's start, and one wholly outside.
	var house := env.add_structure(Rect2(C + Vector2(4.5, -0.5), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	var wall := env.add_structure(Rect2(C + Vector2(-1.5, -6.3), Vector2(3.0, 0.3)), 20.0, Structure.Kind.WALL)
	var rim := env.add_structure(Rect2(C + Vector2(-12.6, -0.5), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	var outside := env.add_structure(Rect2(C + Vector2(2.5, 12.6), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
	var a: Person = crowd.citizens[0]  # 10 west of the middle, nothing between him and it
	var pinned: Person = crowd.soldiers[0]  # 9 north, the wall between him and the middle
	var sheltered: Person = crowd.citizens[1]  # in the house
	var mid: Person = crowd.citizens[2]  # by the middle
	var walker: Person = crowd.citizens[3]  # outside at the cast, walks in during the close
	var far: Person = crowd.citizens[4]  # outside 12 all along
	a.ground_pos = C + Vector2(-10.0, 0.0)
	pinned.ground_pos = C + Vector2(0.0, -9.0)
	mid.ground_pos = C + Vector2(0.3, 0.2)
	walker.ground_pos = C + Vector2(0.0, 13.5)
	far.ground_pos = C + Vector2(0.0, -13.0)
	sheltered.ground_pos = house.center()
	crowd.shelters.shelters[house] = {"inside": [], "coming": [], "clear": 0.0}
	crowd.shelters._enter(sheltered, house)
	(crowd.shelters.shelters[house].inside as Array).append(sheltered)
	var visitors := Visitors.new().setup(field, crowd, grid, made[4])
	var hound := visitors.summon(C + Vector2(9.0, 0.0), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	var far_at := far.ground_pos

	var fx = FxTimeline.cast(cf, ctx, C)
	t.check(fx.law == null and is_equal_approx(fx.radius, 12.0), "nothing holds until the bars stand")
	_run_to(fx, cf.T_LAND + 0.05)
	t.check(fx.law != null and crowd.laws.has(fx.law) and fx.law.holds(LawZone.NO_LEAVING) and fx.law.members.has(a)
		and fx.law.members.has(pinned) and fx.law.members.has(mid) and fx.law.members.has(hound) and not fx.law.members.has(far)
		and not fx.law.members.has(walker), "then the bars stand: whoever is inside 12 is caged, a hound too; nobody outside")
	t.check(rim._cracks.size() > 0 and not rim.destroyed and house._cracks.is_empty() and outside._cracks.is_empty(),
		"the house the ring stands across cracks at once; the rest do not")

	# --- Whoever walks in during the close is caged too.
	_run_to(fx, 5.0)
	walker.ground_pos = C + Vector2(0.0, 9.0)
	_run_to(fx, 5.0 + DT)
	t.check(fx.law.members.has(walker), "one who walks in during the close is caged too")

	# --- Halfway: the ring is about 6.4, and the one who stood at 10 is inside it, alive.
	_run_to(fx, cf.T_LAND + 15.0)
	t.check(absf(fx.radius - 6.4) < 0.05 and a.is_alive() and a.ground_pos.distance_to(C) <= 6.4 + 0.001
		and absf(a.ground_pos.distance_to(C) - fx.radius) < 0.01,
		"at 15 s the ring is %.3f and the one who stood at 10 is pushed in ahead of it (%.3f), alive" % [fx.radius, a.ground_pos.distance_to(C)])
	t.check(pinned.is_alive() and absf(pinned.ground_pos.distance_to(C) - fx.radius) < 0.01 and walker.is_alive()
		and walker.ground_pos.distance_to(C) <= fx.radius + 0.001,
		"the one north of the wall is pushed up to it, still alive (%.3f)" % pinned.ground_pos.distance_to(C))

	# --- Pinned against the wall: cut down when the ring reaches him; the wall falls only when the ring passes its middle.
	var killed := crowd.killed_citizens + crowd.killed_soldiers
	_run_to(fx, cf.T_LAND + 15.3)
	t.check(not pinned.is_alive() and pinned._kind == &"crushed" and not wall.destroyed and wall._cracks.size() > 0
		and crowd.killed_soldiers + crowd.killed_citizens == killed + 1 and fx.cut == 1,
		"pinned against the wall it has not passed, he is cut down when the ring reaches him (kind %s, ring %.3f)" % [pinned._kind, fx.radius])
	_run_to(fx, cf.T_LAND + 15.8)
	t.check(wall.destroyed, "the wall falls when the ring passes its middle (ring %.3f)" % fx.radius)

	# --- The house: cracked as the ring touches it, a hound pressed against it cut down, felled at its middle.
	_run_to(fx, cf.T_LAND + 17.4)
	t.check(house._cracks.size() > 0 and not house.destroyed and sheltered.is_alive() and sheltered.inside,
		"the ring touches the house: it cracks, and still stands (ring %.3f)" % fx.radius)
	t.check(not hound.is_alive() and fx.cut == 2, "a hound pushed against it is cut down too")
	_run_to(fx, cf.T_LAND + 18.8)
	t.check(house.destroyed and not sheltered.is_alive() and sheltered._kind == &"crushed",
		"the house falls as the ring passes its middle, and the one sheltering in it dies with it (ring %.3f)" % fx.radius)

	# --- The end: everyone still inside dies; outside, nothing is touched.
	_run_to(fx, cf.T_LAND + cf.CLOSE_TIME - DT)
	t.check(a.is_alive() and mid.is_alive() and walker.is_alive() and a.ground_pos.distance_to(C) <= fx.radius + 0.001,
		"just before the end those inside still live, pressed together (ring %.3f)" % fx.radius)
	_run_to(fx, cf.T_LAND + cf.CLOSE_TIME + DT)
	t.check(not a.is_alive() and not mid.is_alive() and not walker.is_alive() and a._kind == &"crushed" and mid._kind == &"crushed"
		and walker._kind == &"crushed" and is_equal_approx(fx.radius, cf.END_R) and not crowd.laws.has(fx.law),
		"at the end, 1.5 across, everyone still inside dies, and the law lifts")
	var alive_in := 0
	for e in field.in_radius(C, cf.RADIUS):
		alive_in += 1
	t.check(alive_in == 0, "nobody inside is alive (%d)" % alive_in)
	t.check(far.is_alive() and far.ground_pos.is_equal_approx(far_at) and not outside.destroyed and outside._cracks.is_empty()
		and is_equal_approx(outside.hp, outside.max_hp) and rim._cracks.size() > 0 and not rim.destroyed,
		"whoever stood outside 12 is untouched, and so is the house outside it; the one across the ring is only cracked")
	_run_to(fx, fx.duration + DT)
	t.check(fx.finished, "the effect ends")
	visitors.clear()
	_done(made)


## With 220 people inside it, in the town as it stands, its own frame stays under 2 ms.
static func _perf(t, cf) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var people: Array = crowd.citizens + crowd.soldiers
	var inside: Array[Person] = []
	var k := 0
	var n := 0
	while inside.size() < 220 and k < 2000:
		var ang := TAU * fposmod(float(k) * 0.618034, 1.0)
		var r := 11.5 * sqrt(fposmod(float(k) * 0.381966 + 0.05, 1.0))
		k += 1
		var g := grid.nearest_walkable(at + Vector2.from_angle(ang) * r)
		if g == Vector2.INF or g.distance_to(at) > 11.8:
			continue
		var p: Person = people[n]
		n += 1
		p.ground_pos = g
		inside.append(p)
	for j in range(n, people.size()):
		(people[j] as Person).ground_pos = Vector2(-27.0 + float(j % 20) * 0.3, -27.0 + float(j / 20) * 0.3)
	var untouched: Array[Structure] = []
	for s in env.structures():
		var c := at.clamp(s.footprint.position, s.footprint.end)
		if c.distance_to(at) > cf.RADIUS + 0.05 and not s.destroyed and s._cracks.is_empty():
			untouched.append(s)
	# Timed frame by frame over the close. A frame where someone dies or a building falls also runs the town's own
	# reaction to it (Crowd: the alarm, a collapse's fright, the investigation), which any killing power sets off; the
	# effect's own work is the frames where neither happens.
	var fx = FxTimeline.cast(cf, ctx, at)
	var times := PackedInt32Array()
	var own := PackedInt32Array()
	for j in roundi((cf.T_LAND + cf.CLOSE_TIME + 1.0) * 60.0):
		var before: float = fx.t
		var cut0: int = fx.cut
		var fell0: int = fx.felled
		var t0 := Time.get_ticks_usec()
		fx._process(1.0 / 60.0)
		var spent := Time.get_ticks_usec() - t0
		if before > cf.T_LAND + 0.05 and fx.t < cf.T_LAND + cf.CLOSE_TIME - 0.05:
			times.append(spent)
			if fx.cut == cut0 and fx.felled == fell0:
				own.append(spent)
	t.check(inside.size() == 220 and times.size() > 1700 and own.size() > 1000,
		"220 people inside the ring (%d), timed over the close (%d frames, %d its own work only)" % [inside.size(), times.size(), own.size()])
	if times.is_empty() or own.is_empty():
		_done(made)
		return
	var all := times.duplicate()
	all.sort()
	own.sort()
	var total := 0
	for v in times:
		total += v
	var mean := float(total) / float(times.size())
	var top := own[own.size() - 1]
	# 99.5th percentile: a frame or two the machine takes from the test is not the effect's.
	var own_hi := own[mini(int(own.size() * 0.995), own.size() - 1)]
	print("cage perf: own frames median %d us, p99.5 %d us, max %d us; all frames mean %.0f us, p95 %d us, max %d us; %d cut, %d felled"
		% [own[own.size() / 2], own_hi, top, mean, all[int(all.size() * 0.95)], all[all.size() - 1], fx.cut, fx.felled])
	t.check(own_hi < 2000 and mean < 2000.0 and all[int(all.size() * 0.95)] < 2000,
		"with 220 inside, its own frame stays under 2 ms (p99.5 %d us, max %d us), and every frame averages under it (%.0f us)" % [own_hi, top, mean])
	var alive := 0
	for p in inside:
		if p.is_alive():
			alive += 1
	t.check(alive == 0 and fx.felled > 0, "at the end none of the 220 lives (%d), cut down or crushed (%d cut); %d buildings felled" % [alive, fx.cut, fx.felled])
	var hit := 0
	for s in untouched:
		if not is_instance_valid(s) or s.destroyed or not s._cracks.is_empty():
			hit += 1
	t.check(hit == 0, "no building wholly outside the ring is touched (%d of %d)" % [hit, untouched.size()])
	_done(made)
