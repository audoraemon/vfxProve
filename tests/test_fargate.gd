extends RefCounted
## The Far Gate (Passage, Tier V): a door of stars opens where the click lands and stands SPAN. The MAX_PEOPLE nearest
## within RADIUS -- not fighting, not inside -- walk to it by the streets at their own pace (soldiers at SOLDIER_PACE of
## theirs) and whoever reaches it is gone for the night: counted dead (kind gone), no body, no cry. Dogs and cats go
## too, and the loose goods slide to it and vanish. At the shut the rest stop, dazed, and go on with their business.
## Nothing in it is luck: two casts on the same town end the same way.

const FX := "res://src/fx/control/the_far_gate.gd"
const DT := 0.05


static func _setup() -> Dictionary:
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
	# The town's dogs and cats, by hand (the runner spawns none): the pack steps them, the door turns them.
	var pack := AnimalPack.new().setup(crowd, grid, world, 5)
	crowd.animals = pack
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.world = world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	# Everyone out of the way in a far corner, to be placed one by one.
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos
		i += 1
	var door := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	return {"crowd": crowd, "env": env, "grid": grid, "field": field, "world": world, "ctx": ctx, "pack": pack,
		"door": door, "frame": 0}


static func _done(s: Dictionary) -> void:
	Person.frame_no = -1
	(s.pack as AnimalPack).clear()
	(s.crowd as Crowd).clear()
	var ctx: FxContext = s.ctx
	ctx.overhead.free()
	ctx.ground.free()
	(s.world as Node).free()


## Stand `p` at `at` in `mind`, with nothing to walk to and an even pace.
static func _stand(p: Person, at: Vector2, mind := Person.Mind.CALM) -> void:
	p.ground_pos = at
	p.mind = mind
	p.pace = 1.0
	p.inside = false
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p.statuses.erase(&"slow")
	p.walk_speed = p._mind_speed()


## The door's clock alone (nobody moves): up to and past the opening.
static func _run_fx(fx: FxTimeline, seconds: float) -> void:
	for k in roundi(seconds / DT):
		fx._process(DT)


## The whole town `seconds` on: the door, the people, the crowd and the animals, a frame at a time.
static func _run(s: Dictionary, fx: FxTimeline, seconds: float) -> void:
	var crowd: Crowd = s.crowd
	for k in roundi(seconds / DT):
		s.frame += 1
		Person.frame_no = s.frame
		if not fx.finished:
			fx._process(DT)
		crowd.step_people(DT)
		crowd.advance(DT)
		(s.pack as AnimalPack).step(DT)


## How far the streets make a walk from `a` to `b`.
static func _walk(grid: WalkGrid, a: Vector2, b: Vector2) -> float:
	var way := grid.path(a, b)
	var d := 0.0
	var last := a
	for q in way:
		d += last.distance_to(q)
		last = q
	return d + last.distance_to(b)


## A walkable spot whose walk to `door` by the streets is between `lo` and `hi`.
static func _spot(grid: WalkGrid, door: Vector2, lo: float, hi: float) -> Vector2:
	for r in [0.5 * (lo + hi), lo, hi, lo * 0.9]:
		for k in 16:
			var q := grid.nearest_walkable(door + Vector2.from_angle(TAU * float(k) / 16.0) * float(r), 3)
			if q == Vector2.INF:
				continue
			var w := _walk(grid, q, door)
			if w >= lo and w <= hi:
				return q
	return Vector2.INF


static func _animal(s: Dictionary, breed: Animal.Breed, at: Vector2) -> Animal:
	var a := Animal.new()
	a.breed = breed
	a.ground_pos = at
	a.home = at
	a.goal = at
	a.wait = 999.0
	a.sync_position()
	(s.world as Node2D).add_child(a)
	(s.pack as AnimalPack).animals.append(a)
	return a


static func _decor(s: Dictionary, kind: Decor.Kind, at: Vector2) -> Decor:
	var d := Decor.new().setup(kind, at, Vector2(0.3, 0.3), 11)
	(s.env as EnvironmentField).add_decor(d)
	return d


## One whole cast on a town laid out the same way every time; what it did, for the checks (and for two runs to compare).
static func _scenario(t, checks: bool) -> String:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var grid: WalkGrid = s.grid
	var env: EnvironmentField = s.env
	var pack: AnimalPack = s.pack
	var door: Vector2 = s.door
	var near := grid.nearest_walkable(door + Vector2(1.6, 1.0))
	var far := _spot(grid, door, 6.0, 7.5)
	var soldier_near := grid.nearest_walkable(door + Vector2(-1.2, 0.8))
	var aside := grid.nearest_walkable(door + Vector2(0.0, 2.6))
	var beyond := grid.nearest_walkable(door + Vector2(_beyond(), 0.0), 6)
	var c_near: Person = crowd.citizens[0]
	var c_far: Person = crowd.citizens[1]
	var c_fight: Person = crowd.citizens[2]
	var c_inside: Person = crowd.citizens[3]
	var c_out: Person = crowd.citizens[4]
	var s_far: Person = crowd.soldiers[0]
	var s_near: Person = crowd.soldiers[1]
	_stand(c_near, near)
	_stand(c_far, far)
	_stand(s_far, far + Vector2(0.05, 0.0), Person.Mind.POST)
	_stand(s_near, soldier_near, Person.Mind.POST)
	_stand(c_fight, aside, Person.Mind.FIGHT)
	c_fight._fight_left = 60.0
	c_fight._fight_rule = Person.FightRule.OF_KIND
	c_fight.fight_kind = &"nobody here"  # in a fight, with nobody to strike
	_stand(c_inside, aside + Vector2(0.1, 0.0))
	c_inside.inside = true
	_stand(c_out, beyond)
	var dog := _animal(s, Animal.Breed.HOUND, grid.nearest_walkable(door + Vector2(2.4, -1.0)))
	var cat := _animal(s, Animal.Breed.TABBY, grid.nearest_walkable(door + Vector2(-_beyond(), 0.0), 6))
	var barrel := _decor(s, Decor.Kind.BARREL, door + Vector2(2.5, 2.0))
	var far_barrel := _decor(s, Decor.Kind.BARREL, door + Vector2(0.0, _beyond()))
	var bush := _decor(s, Decor.Kind.BUSH, door + Vector2(-2.0, 2.0))
	var dead_c := crowd.killed_citizens
	var dead_s := crowd.killed_soldiers
	var voiced := crowd.deaths.voiced
	var alarm := crowd.alarm

	var fx: TheFarGateFx = FxTimeline.cast(load(FX), s.ctx, door)
	if checks:
		t.check(far != Vector2.INF and beyond.distance_to(door) > TheFarGateFx.RADIUS
				and _walk(grid, near, door) < 3.0 and _walk(grid, soldier_near, door) < 4.0,
			"the town is laid out: a citizen and a soldier near the door, a citizen and a soldier %.1f away by the streets, one beyond RADIUS" % _walk(grid, far, door))
		t.check(fx.door == door and is_equal_approx(fx.busy, TheFarGateFx.T_OPEN)
				and is_equal_approx(fx.shut_at(), TheFarGateFx.T_OPEN + TheFarGateFx.SPAN) and not fx.opened,
			"the door stands where the click lands; it takes T_OPEN to open and stands open SPAN after")
	_run_fx(fx, TheFarGateFx.T_OPEN - DT)
	if checks:
		t.check(not fx.opened and c_near.mind == Person.Mind.CALM and fx.drawn.is_empty(), "nobody is drawn before the door is open")
	_run_fx(fx, DT * 2.0)
	var expected: Array[Person] = [c_near, c_far, s_far, s_near]
	if checks:
		var who_ok := fx.drawn.size() == expected.size()
		for p in expected:
			who_ok = who_ok and p in fx.drawn
		t.check(fx.opened and who_ok, "when it opens, the near citizen and soldier and the far ones are drawn (%d drawn)" % fx.drawn.size())
		t.check(not c_fight in fx.drawn and c_fight.mind == Person.Mind.FIGHT, "one fighting is not drawn")
		t.check(not c_inside in fx.drawn and c_inside.mind != Person.Mind.COMPELLED, "one inside a building is not drawn")
		t.check(not c_out in fx.drawn and c_out.mind == Person.Mind.CALM, "one beyond RADIUS is not touched")
		var calm := true
		for p in expected:
			calm = calm and p.mind == Person.Mind.COMPELLED and p.held_by_will(Person.WILL_ABSOLUTE)
		t.check(calm, "the drawn go calm, held by a will no danger breaks (not frightened)")
		var routed := true
		for p in [c_near, c_far, s_far]:
			routed = routed and p.has_goal() and p.goal() == door and p._path.size() > 0
		t.check(routed, "each walks to the door by a route through the streets")
		t.check(is_equal_approx(s_far.walk_speed, c_far.walk_speed * TheFarGateFx.SOLDIER_PACE)
				and is_equal_approx(float(s_far.statuses.get(&"slow", 1.0)), TheFarGateFx.SOLDIER_PACE),
			"a soldier resists: he walks at SOLDIER_PACE of a citizen's pace (%.2f vs %.2f)" % [s_far.walk_speed, c_far.walk_speed])
		t.check(dog in fx.animals and dog.state == Animal.State.GATHER and not cat in fx.animals and cat.state != Animal.State.GATHER,
			"a dog within RADIUS turns to the door; a cat beyond it does not")
		t.check(barrel in fx.goods and not far_barrel in fx.goods and not bush in fx.goods,
			"the loose goods within RADIUS are drawn (a barrel); a barrel beyond RADIUS and a bush are not")

	var barrel_gap := barrel.at.distance_to(door)
	var on_ground := true
	for k in 6:
		_run(s, fx, 0.5)
		for p in fx.drawn:
			on_ground = on_ground and not env.blocked(p.ground_pos, 0.0)
	if checks:
		t.check(on_ground, "on the way, nobody drawn walks through a building")
		t.check(not is_instance_valid(barrel) or barrel.at.distance_to(door) < barrel_gap - 1.0,
			"the barrel slides over the ground toward the door")
		t.check(not c_near.is_alive() and c_near._kind == &"gone" and c_near in fx.gone_people,
			"the citizen near the door reaches it and is gone through it (kind gone)")
	_run(s, fx, fx.shut_at() - fx.t + DT)
	if checks:
		t.check(fx.shut and not c_far.is_alive() and c_far._kind == &"gone",
			"a citizen %.1f away by the streets makes it before the door shuts" % _walk(grid, far, door))
		t.check(not s_near.is_alive() and s_near._kind == &"gone", "the soldier near the door makes it at his slow pace")
		t.check(s_far.is_alive() and s_far in fx.released and s_far.mind != Person.Mind.COMPELLED,
			"the soldier who stood beside that citizen does not make it at half pace: the door shuts on him and lets him go")
		t.check(not s_far.statuses.has(&"slow") and is_equal_approx(s_far.walk_speed, s_far._mind_speed()),
			"let go, he has his own pace back")
		t.check(crowd.killed_citizens - dead_c == 2 and crowd.killed_soldiers - dead_s == 1,
			"those gone through are counted among the dead: 2 citizens, 1 soldier (%d, %d)" % [crowd.killed_citizens - dead_c, crowd.killed_soldiers - dead_s])
		t.check(crowd.deaths.voiced == voiced and is_equal_approx(crowd.alarm, alarm),
			"the town hears no cry and raises no alarm for them (voiced %d -> %d, alarm %.2f -> %.2f)" % [voiced, crowd.deaths.voiced, alarm, crowd.alarm])
		t.check(c_near.modulate.a <= 0.01 and c_near._char >= 1.0,
			"no body is left: the one gone first has faded to nothing")
		t.check(c_out.is_alive() and c_inside.is_alive() and c_fight.is_alive(), "the fighter, the one inside and the one beyond RADIUS are all still here")
		t.check(not is_instance_valid(dog) and fx.gone_animals == 1 and pack.animals.size() == 1 and pack.animals[0] == cat,
			"the dog went through the door; the cat beyond RADIUS is still in town")
		t.check(not is_instance_valid(barrel) and fx.gone_goods >= 1 and env.decor().has(far_barrel) and env.decor().has(bush),
			"the barrel vanished into the door; the far barrel and the bush are still there")
	var dazed_at := s_far.ground_pos
	var dazed := s_far.wait > 0.0
	_run(s, fx, TheFarGateFx.DAZE * 0.8)
	if checks:
		t.check(dazed and s_far.ground_pos.distance_to(dazed_at) < 0.01,
			"he stops where the shut found him, dazed DAZE")
		t.check(s_far.mind == Person.Mind.POST, "and then goes back to his own business (his post)")
	var out := "%d|%d|%d|%d|%s|%s" % [fx.gone_people.size(), fx.gone_animals, fx.gone_goods, fx.released.size(),
		str(s_far.ground_pos.snapped(Vector2(0.001, 0.001))), str(c_out.ground_pos.snapped(Vector2(0.001, 0.001)))]
	_run(s, fx, 2.0)
	if checks:
		t.check(fx.finished, "the door has folded away")
	_done(s)
	return out


## Beyond the door's reach.
static func _beyond() -> float:
	return TheFarGateFx.RADIUS + 1.5


## Fifty calm citizens round the door at fifty distances: the forty nearest are drawn, no further one.
static func _forty(t) -> void:
	var s := _setup()
	var crowd: Crowd = s.crowd
	var grid: WalkGrid = s.grid
	var door: Vector2 = s.door
	var placed: Array[Person] = []
	for k in 50:
		if k >= crowd.citizens.size():
			break
		var p: Person = crowd.citizens[k]
		var q := grid.nearest_walkable(door + Vector2.from_angle(float(k) * 2.4) * (0.4 + float(k) * 0.18), 4)
		if q == Vector2.INF or q.distance_to(door) > TheFarGateFx.RADIUS:
			continue
		_stand(p, q)
		placed.append(p)
	var fx: TheFarGateFx = FxTimeline.cast(load(FX), s.ctx, door)
	_run_fx(fx, TheFarGateFx.T_OPEN + DT)
	var nearest_left := INF
	var farthest_drawn := 0.0
	for p in placed:
		var d := p.ground_pos.distance_to(door)
		if p in fx.drawn or p in fx.gone_people:  # one already within DOOR_R is gone the moment it opens
			farthest_drawn = maxf(farthest_drawn, d)
		else:
			nearest_left = minf(nearest_left, d)
	t.check(placed.size() > TheFarGateFx.MAX_PEOPLE and fx.drawn.size() + fx.gone_people.size() == TheFarGateFx.MAX_PEOPLE
			and farthest_drawn <= nearest_left,
		"with %d in reach, only the MAX_PEOPLE nearest are drawn (%d; farthest drawn %.2f, nearest left %.2f)" % [placed.size(), fx.drawn.size() + fx.gone_people.size(), farthest_drawn, nearest_left])
	fx.end_now()
	var held := 0
	for p in placed:
		if p.is_alive() and p.mind == Person.Mind.COMPELLED:
			held += 1
	t.check(held == 0, "a door cut short lets everyone go (%d still drawn)" % held)
	_done(s)


static func run(t) -> void:
	var b := PowerBook.get_power("fargate")
	var area: Dictionary = Targeting.AREAS.get("fargate", {})
	t.check(int(b.dp) == 6 and PowerBook.is_quiet("fargate") and String(b.aim) == "click"
			and is_equal_approx(float(b.cooldown), 999.0) and PowerBook.authority_of("fargate") == "passage"
			and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), TheFarGateFx.RADIUS)
			and Rules.POWER_KINDS.get("fargate", []) == [&"gone"] and PowerBook.family("fargate") != ""
			and PowerBook.icon("fargate") != null and PowerBook.hud_icon("fargate") != null and PowerBook.clip("fargate") != null,
		"The Far Gate is Passage's 6 DP, quiet, a click on a circle of RADIUS, once a descent, its dead kind gone, with icons, clip and a family")
	var first := _scenario(t, true)
	var second := _scenario(t, false)
	t.check(first == second, "no luck: two casts on the same town end the same way (%s / %s)" % [first, second])
	_forty(t)
