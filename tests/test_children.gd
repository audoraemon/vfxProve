extends RefCounted
## The town's children (Discord idea "child population", Children): with Children.enabled off there are none and the town
## is as it was; on, Children.SHARE of the grown citizens are children in families that have grown-ups, at home, with no
## work; the routine never sends one to work; they die and count like anyone; a frightened child runs to a grown-up of
## its own family; they leave with their household; no director casts one; the capital has them too; and their own
## rng moves nobody spawned before them.

const STEP := 1.0 / 30.0


static func run(t) -> void:
	var was := Children.enabled
	_off(t)
	Children.enabled = true
	_spawned(t)
	_adults_unmoved(t)
	_routine(t)
	_killed(t)
	_panic(t)
	_household(t)
	_directors(t)
	_look(t)
	_capital(t)
	Children.enabled = was
	City.use(&"aldermere")


static func _build(city := &"aldermere") -> Dictionary:
	City.use(city)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(b: Dictionary) -> void:
	(b.crowd as Crowd).clear()
	(b.crowd as Node).free()
	(b.world as Node).free()
	(b.town as Node).free()


static func _kids(crowd: Crowd) -> Array[Person]:
	return crowd.children()


static func _off(t) -> void:
	Children.enabled = false
	var b := _build()
	var crowd: Crowd = b.crowd
	t.check(crowd.spawned_children == 0 and _kids(crowd).is_empty() and crowd.citizens.size() == Crowd.CITIZENS
		and crowd.spawned_citizens == Crowd.CITIZENS, "with Children.enabled off the town has no children and its %d citizens" % Crowd.CITIZENS)
	_done(b)


static func _spawned(t) -> void:
	var b := _build()
	var crowd: Crowd = b.crowd
	var grid: WalkGrid = b.grid
	var kids := _kids(crowd)
	var want := Children.count_for(Crowd.CITIZENS)
	t.check(want == 40 and kids.size() == want and crowd.spawned_children == want,
		"Aldermere has 18%% of its grown citizens as children (%d of %d)" % [kids.size(), want])
	t.check(crowd.citizens.size() == Crowd.CITIZENS + want and crowd.spawned_citizens == crowd.citizens.size(),
		"the children are citizens, counted in spawned_citizens (%d)" % crowd.spawned_citizens)
	var bad_role := 0
	var no_adult := 0
	var far := 0
	var no_play := 0
	var wired := 0
	var families := {}
	for k in kids:
		var pr := k.profile
		if pr.role != CitizenProfile.Role.CHILD or pr.works() or not k.is_child() or k.kind() != &"child":
			bad_role += 1
		var adult := false
		for p in crowd.citizens:
			adult = adult or (not p.is_child() and p.profile.family == pr.family and p.profile.home == pr.home)
		no_adult += 0 if adult and not k.kin.is_empty() else 1
		far += 1 if k.ground_pos.distance_to(pr.home) > 1.5 or not grid.walkable(k.ground_pos) else 0
		no_play += 1 if pr.leisure.is_empty() else 0
		wired += 1 if k.evac == crowd.evac and k.shelters == crowd.shelters and k.evac != null else 0
		families[pr.family] = true
	t.check(bad_role == 0, "every child is Role.CHILD, of kind \"child\", with no work (%d not)" % bad_role)
	t.check(no_adult == 0, "every child is in a family with a grown-up at its home (%d not)" % no_adult)
	t.check(far == 0 and no_play == 0, "each starts by its home on walkable ground with places to play (%d far, %d without)" % [far, no_play])
	t.check(wired == kids.size(), "each is wired to the evacuation and the shelters like a grown-up (%d of %d)" % [wired, kids.size()])
	t.check(families.size() > kids.size() / 2, "the children spread over many families (%d)" % families.size())
	_done(b)


## Their own rng: the grown-ups and the soldiers spawn where and as they would without them.
static func _adults_unmoved(t) -> void:
	Children.enabled = false
	var b0 := _build()
	var before: Array = []
	for p in (b0.crowd as Crowd).citizens + (b0.crowd as Crowd).soldiers:
		before.append([p.ground_pos, p.rng.seed, p.profile.role if p.profile != null else -1])
	_done(b0)
	Children.enabled = true
	var b1 := _build()
	var crowd: Crowd = b1.crowd
	var same := true
	var adults := crowd.citizens.slice(0, Crowd.CITIZENS) + crowd.soldiers
	same = same and adults.size() == before.size()
	for i in mini(adults.size(), before.size()):
		var p: Person = adults[i]
		same = same and p.ground_pos == before[i][0] and p.rng.seed == before[i][1] \
			and (p.profile.role if p.profile != null else -1) == before[i][2]
	t.check(same, "with children on, every grown-up and soldier spawns where (and with the seed) it did without them")
	_done(b1)


static func _routine(t) -> void:
	var b := _build()
	var crowd: Crowd = b.crowd
	var kid: Person = _kids(crowd)[0]
	var to_work := 0
	var played := 0
	var last := -1
	for i in 300:
		var place := crowd.routine.pick(kid.profile, last)
		to_work += 1 if place == RoutineManager.Place.WORK else 0
		played += 1 if place == RoutineManager.Place.LEISURE else 0
		last = place
	t.check(to_work == 0 and played > 60, "the routine never sends a child to work, and it plays (%d work, %d play)" % [to_work, played])
	var look: Town.Look = TownLook.active
	TownLook.active = Town.Look.NIGHT
	var home := 0
	last = -1
	for i in 300:
		var place := crowd.routine.pick(kid.profile, last)
		home += 1 if place == RoutineManager.Place.HOME else 0
		last = place
	TownLook.active = look
	t.check(home >= 130, "at night a child keeps mostly to home (%d of 300 home)" % home)
	_done(b)


static func _killed(t) -> void:
	var b := _build()
	var crowd: Crowd = b.crowd
	var field: EnemyField = b.field
	var kid: Person = _kids(crowd)[0]
	var dead := crowd.killed_citizens
	field.kill(kid, &"nova")
	t.check(not kid.is_alive() and crowd.killed_citizens == dead + 1, "a child dies like anyone and counts in killed_citizens")
	_done(b)


static func _panic(t) -> void:
	var b := _build()
	var crowd: Crowd = b.crowd
	var grid: WalkGrid = b.grid
	var kid: Person
	for k in _kids(crowd):
		if not k.kin.is_empty():
			kid = k
			break
	var adult: Person = kid.kin[0]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	adult.ground_pos = grid.nearest_walkable(at + Vector2(2.5, 0.0))
	kid.ground_pos = grid.nearest_walkable(at + Vector2(0.0, 0.3))
	for q in kid.kin:
		if q != adult:
			q.ground_pos = Vector2(-30, -30)  # out of reach: the one near is the one it runs to
	kid.shelters = null  # no taking cover: the test is of whom it runs to
	kid.panic(at + Vector2(-1.0, 0.0), 1.0)
	t.check(kid.mind == Person.Mind.PANIC and kid._guardian == adult, "a frightened child picks the grown-up of its family nearby")
	for i in 150:
		kid.tick(STEP)
	t.check(kid.mind == Person.Mind.PANIC and kid.ground_pos.distance_to(adult.ground_pos) <= Children.FOLLOW_GAP + 0.5,
		"and runs to them and stays close (%.2f away)" % kid.ground_pos.distance_to(adult.ground_pos))
	# None of its family near: it runs from the danger as a grown-up would.
	kid._recover(0.1)
	kid.mind = Person.Mind.CALM
	for q in kid.kin:
		q.ground_pos = Vector2(-30, -30)
	kid.panic(kid.ground_pos + Vector2(-0.5, 0.0), 1.0)
	t.check(kid.mind == Person.Mind.PANIC and kid._guardian == null and kid.has_goal(),
		"with no grown-up of its own near, a child runs from the danger on its own")
	t.check(is_equal_approx(kid._base_speed(), Person.PANIC_SPEED * kid.pace), "a child panics at a grown-up's speed")
	kid.mind = Person.Mind.CALM
	t.check(is_equal_approx(kid._base_speed(), Person.WALK_SPEED * kid.pace * Children.WALK_PACE)
		and is_equal_approx(adult._base_speed() if adult.mind == Person.Mind.CALM else Person.WALK_SPEED * adult.pace,
			Person.WALK_SPEED * adult.pace), "a child walks a little brisker than a grown-up (x%.1f)" % Children.WALK_PACE)
	_done(b)


## The household regroups and leaves together, its children with it.
static func _household(t) -> void:
	var b := _build()
	var crowd: Crowd = b.crowd
	crowd._regroup()
	var kid: Person
	for k in _kids(crowd):
		if k.mind == Person.Mind.REGROUP:
			kid = k
			break
	t.check(kid != null, "at City Emergency a regrouping household's children go home with it")
	if kid == null:
		_done(b)
		return
	var elders := 0
	for q in kid.kin:
		elders += 1 if q.mind == Person.Mind.REGROUP else 0
	t.check(elders > 0, "together with the grown-ups of its family (%d)" % elders)
	crowd._evacuate()
	t.check(crowd._households.has(kid.profile.family), "the evacuation waits for the household, child and all")
	crowd._clock += Crowd.HOUSEHOLD_WAIT + 1.0
	crowd._tend_households()
	var gone := kid.mind == Person.Mind.FLEE
	for q in kid.kin:
		if q.mind == Person.Mind.REGROUP:
			gone = false
	t.check(gone, "and the household leaves together, its child with it")
	_done(b)


static func _directors(t) -> void:
	t.check(CitizenProfile.Role.CHILD in Wish.NOT_LAY and CitizenProfile.Role.CHILD in FestivalDirector.SKIP_ROLES,
		"a child is never a wisher, a wish's target or a festival goer")
	var b := _build()
	var crowd: Crowd = b.crowd
	var lay := Wish.lay(crowd, [])
	var kids_in := 0
	for p in lay:
		kids_in += 1 if p.is_child() else 0
	t.check(not lay.is_empty() and kids_in == 0, "the lay pool the wishes and directors cast from has no children (%d)" % kids_in)
	# The relay of a seen death (The Warning): a child standing nearest the body carries nothing on.
	var kid: Person = _kids(crowd)[0]
	var at := kid.ground_pos
	for p in crowd.citizens + crowd.soldiers:
		if p != kid and p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + 0.5:
			p.ground_pos = Vector2(-30, -30)
	var w := TempleReport.new(crowd.soldiers[0], at, 1.0, 5.0)  # descending: not sent yet
	w.skip = func(_p: Person) -> bool: return false
	t.check(w._witness(crowd, at + Vector2(0.2, 0.0)) == null and crowd.nearest_witness(at + Vector2(0.2, 0.0)) == kid,
		"a child sees a death, but is never the one to carry the report")
	_done(b)


static func _look(t) -> void:
	var R := CitizenProfile.Role
	t.check(PeopleArt.CITIZEN.size() == R.size() and PeopleArt.wanted(false, R.CHILD, 0, 0.2) == "child_a"
		and PeopleArt.wanted(false, R.CHILD, 0, 0.4) == "child_b" and PeopleArt.wanted(false, R.CHILD, 0, 0.9) == "child_d", "the children wear child_a to child_d")
	var d := PeopleArt.design_for(false, R.CHILD, 0, 0.2)
	t.check(not PeopleArt.ready() or PeopleArt.has(d), "without child art a child wears a design the atlas has (%s)" % d)
	t.check(RoutineManager.WEIGHTS.has(R.CHILD) and (RoutineManager.WEIGHTS[R.CHILD] as Array)[RoutineManager.Place.WORK] == 0.0,
		"the routine has a child's day, with no work in it")


static func _capital(t) -> void:
	var b := _build(&"capital")
	var crowd: Crowd = b.crowd
	var kids := _kids(crowd)
	var adults := crowd.citizens.size() - kids.size()
	var orphans := 0
	for k in kids:
		orphans += 1 if k.kin.is_empty() or k.profile.home == Vector2.INF else 0
	t.check(adults == City.current().citizens() and kids.size() == Children.count_for(adults) and kids.size() > 50
		and orphans == 0, "the capital has its children too (%d for %d grown citizens), each in a family" % [kids.size(), adults])
	_done(b)
	City.use(&"aldermere")
