extends RefCounted
## The capital's people (Task 11): about 420 citizens dealt by district from the city's spawn_roles(), the new roles
## wearing existing designs, every role's places reachable, and a calm minute in which the bread queue, the wash
## houses, the harbour and the chapels are each visited. Aldermere keeps its own 220 and its shares.

const R := CitizenProfile.Role
const GROUND := preload("res://tests/test_capital_ground.gd")
## The calm run: how long, its step, how near a place a citizen that has arrived must stand.
const CALM_SECONDS := 60.0
const STEP := 1.0 / 30.0
const AT_PLACE := 0.8


static func run(t) -> void:
	_counts(t)
	_designs(t)
	var built := _build()
	_spawn(t, built)
	_reachable(t, built)
	_calm(t, built)
	(built.world as Node).free()
	(built.town as Node).free()
	City.use(&"aldermere")


## The city sets how many people spawn: Aldermere its 220 and 100, the capital the sum of its spawn_roles().
static func _counts(t) -> void:
	var a := City.by_id(&"aldermere")
	t.check(a.citizens() == Crowd.CITIZENS and a.soldiers() == Crowd.SOLDIERS and a.spawn_roles().is_empty(),
		"Aldermere spawns its own 220 citizens and 100 soldiers by its shares")
	var c := City.by_id(&"capital") as CapitalCity
	var roles := c.spawn_roles()
	var total := 0
	var districts_ok := true
	var jobs_ok := true
	for d: StringName in roles:
		districts_ok = districts_ok and c.landmark(d).has_area()
		for job: StringName in roles[d]:
			jobs_ok = jobs_ok and CitizenProfile.JOBS.has(job)
			total += int(roles[d][job])
	t.check(total >= 400 and total <= 440 and c.citizens() == total, "the capital deals about 420 citizens (%d)" % total)
	t.check(districts_ok and roles.size() >= 12, "its citizens are dealt by district of the plan (%d districts)" % roles.size())
	t.check(jobs_ok, "every role the capital deals is a known job")
	var want := [&"baker", &"washer", &"dockworker", &"monk", &"noble", &"beggar"]
	var dealt := {}
	for d: StringName in roles:
		for job: StringName in roles[d]:
			dealt[job] = true
	var all_dealt := true
	for job: StringName in want:
		all_dealt = all_dealt and dealt.has(job)
	t.check(all_dealt, "the capital deals bakers, washers, dockworkers, monks, nobles and beggars (%s)" % [dealt.keys()])
	var anchors := c.anchors()
	var kinds_ok := true
	var missing: Array = []
	for k: String in ["home", "work", "queue", "wash", "pray", "market", "harbour", "gate", "field"]:
		if (anchors.get(k, []) as Array).is_empty():
			kinds_ok = false
			missing.append(k)
	t.check(kinds_ok, "the capital has every routine point (missing %s)" % [missing])
	var fanned := 0
	for g: Vector2 in anchors.home:
		fanned += 1 if c._in_fan(Rect2(g - Vector2(0.05, 0.05), Vector2(0.1, 0.1))) else 0
	t.check(fanned == 0, "no capital home point stands in a gate's queue fan (%d)" % fanned)


## The new roles wear existing designs: baker a merchant's, washer and beggar a commoner's, dockworker a labourer's,
## monk a priest's; the noble keeps its own.
static func _designs(t) -> void:
	t.check(PeopleArt.CITIZEN.size() == R.size(), "PeopleArt.CITIZEN has an entry for every role")
	var want := {R.BAKER: "merchant", R.WASHER: "resident", R.DOCKWORKER: "laborer", R.MONK: "clergy",
		R.BEGGAR: "resident"}
	var ok := true
	for role: int in want:
		for look in [0.1, 0.9]:
			var d := PeopleArt.design_for(false, role, 0, look)
			ok = ok and PeopleArt.has(d) and d.begins_with(want[role])
	t.check(ok, "the new roles wear the merchant's, commoner's, labourer's and priest's designs")
	for role: int in [R.BAKER, R.WASHER, R.DOCKWORKER, R.MONK, R.BEGGAR]:
		t.check(RoutineManager.WEIGHTS.has(role), "role %s has routine weights" % R.keys()[role])
	t.check(CitizenProfile.JOBS[&"noble"][0] == R.NOBLE and CitizenProfile.JOBS[&"baker"][0] == R.BAKER,
		"jobs name the role they are drawn as")


static func _build() -> Dictionary:
	City.use(&"capital")
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
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


## A capital crowd spawns 400-440 citizens, each with its job, a walkable home, work where its job has one, and its
## district's roles in the city's numbers.
static func _spawn(t, b: Dictionary) -> void:
	var crowd: Crowd = b.crowd
	var grid: WalkGrid = b.grid
	var n := crowd.citizens.size()
	t.check(n >= 400 and n <= 440 and n == City.current().citizens(), "a capital crowd spawns about 420 citizens (%d)" % n)
	var jobs := {}
	var bad: Array = []
	for p: Person in crowd.citizens:
		var pr: CitizenProfile = p.profile
		jobs[pr.job] = int(jobs.get(pr.job, 0)) + 1
		var job: Array = CitizenProfile.JOBS.get(pr.job, [])
		# The bellkeeper and the engineers are appointed from the dealt residents and craftsfolk after the deal.
		var appointed := pr.role == R.BELLKEEPER or pr.role == R.ENGINEER
		if job.is_empty() or (pr.role != job[0] and not appointed) or not grid.walkable(pr.home) \
				or pr.leisure.is_empty():
			bad.append("%s home %s" % [pr.job, pr.home])
		elif not appointed and pr.works() != (not (job[1] as Array).is_empty()):
			bad.append("%s works %s" % [pr.job, pr.works()])
	var ok := bad.is_empty()
	var want := {}
	var roles := City.current().spawn_roles()
	for d: StringName in roles:
		for job: StringName in roles[d]:
			want[job] = int(want.get(job, 0)) + int(roles[d][job])
	t.check(ok, "every capital citizen has its job's role, a walkable home, work if its job has one, and leisure (%s)"
		% [bad.slice(0, 6)])
	t.check(jobs == want, "the crowd's jobs are the city's numbers (%s)" % [jobs])
	var homes_in := 0
	var dealt := 0
	for p: Person in crowd.citizens:
		if p.profile.district != &"":
			dealt += 1
			if City.current().landmark(p.profile.district).grow(1.5).has_point(p.profile.home):
				homes_in += 1
	t.check(dealt == n and homes_in >= n * 0.75, "most citizens live in the district they were dealt to (%d of %d)" % [homes_in, n])


## Every role's places (its work, its routine visits, its home) are reachable from the south road's exit.
static func _reachable(t, b: Dictionary) -> void:
	var crowd: Crowd = b.crowd
	var grid: WalkGrid = b.grid
	var seen: Dictionary = GROUND._flood(grid, grid.nearest_walkable(City.current().exits()[0]))
	var cut := {}
	for p: Person in crowd.citizens:
		var pr: CitizenProfile = p.profile
		var pts: Array[Vector2] = [pr.home]
		if pr.works():
			pts.append(pr.work)
		pts.append_array(Array(pr.leisure))
		for g: Vector2 in pts:
			var w := grid.nearest_walkable(g)
			if w == Vector2.INF or not seen.has(grid.world_to_id(w)):
				cut[pr.job] = int(cut.get(pr.job, 0)) + 1
	t.check(cut.is_empty(), "every role's home, work and routine places are reachable (cut off by job: %s)" % [cut])
	var anchors := City.current().anchors()
	var bad: Array = []
	for k: String in ["queue", "wash", "pray", "market", "harbour", "gate", "work"]:
		for g: Vector2 in anchors[k]:
			var w := grid.nearest_walkable(g)
			if w == Vector2.INF or not seen.has(grid.world_to_id(w)):
				bad.append("%s %s" % [k, g])
	t.check(bad.is_empty(), "every routine point is reachable (%s)" % [bad])


## A calm minute at a fixed step: citizens arrive at the bakery's queue, the wash houses, the harbour and the chapels.
static func _calm(t, b: Dictionary) -> void:
	var crowd: Crowd = b.crowd
	var anchors := crowd._snapped_anchors()
	var places := {"queue": anchors.queue, "wash": anchors.wash, "harbour": anchors.harbour, "pray": anchors.pray}
	var arrived := {}
	var going := {}
	var steps := roundi(CALM_SECONDS / STEP)
	for s in steps:
		crowd.step_people(STEP)
		crowd.advance(STEP)
		if s % 15 != 0:
			continue
		for p: Person in crowd.citizens:
			if not is_instance_valid(p):
				continue
			if p.has_goal():
				going[p] = true
				continue
			if not going.has(p):
				continue
			going.erase(p)
			for k: String in places:
				for g: Vector2 in places[k]:
					if p.ground_pos.distance_to(g) <= AT_PLACE and p.anchor.distance_to(g) <= AT_PLACE:
						arrived[k] = int(arrived.get(k, 0)) + 1
						break
	var calm := true
	for p: Person in crowd.citizens:
		calm = calm and is_instance_valid(p) and p.mind != Person.Mind.FLEE
	print("capital calm minute: arrivals %s" % [arrived])
	for k: String in places:
		t.check(int(arrived.get(k, 0)) >= 1, "in a calm minute someone arrives at the %s (%d)" % [k, int(arrived.get(k, 0))])
	t.check(calm, "the capital stays calm")
