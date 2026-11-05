extends RefCounted
## Anathema: the district's buildings are cursed -- nobody will be inside one, its fire is left, the keeper will not
## climb a cursed tower -- or hallowed -- everyone must be inside, and stays there whatever happens.


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
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func run(t) -> void:
	var b := PowerBook.get_power("anathema")
	var modes: Array = b.get("modes", [])
	t.check(int(b.dp) == 4 and PowerBook.authority_of("anathema") == "dominion" and PowerBook.is_quiet("anathema")
		and modes.size() == 2 and String(modes[0].key) == "cursed" and String(modes[1].key) == "hallowed"
		and PowerBook.icon("anathema") != null and PowerBook.hud_icon("anathema") != null and PowerBook.clip("anathema") != null
		and Targeting.AREAS.has("anathema") and Rules.POWER_KINDS.has("anathema") and PowerBook.family("anathema") != "",
		"Anathema is Dominion's 4 DP, quiet, cursed or hallowed, with icons, clip, area, kinds and a family")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	# A shelter to stand the tests on: the first the town has.
	var house: Structure = crowd.shelters.shelters.keys()[0]
	var at := house.center()
	var far_house: Structure = null
	for s: Structure in crowd.shelters.shelters.keys():
		if s.center().distance_to(at) > AnathemaFx.RADIUS + 4.0:
			far_house = s
			break
	t.check(AnathemaFx.marked_at(env, at).has(house) and (far_house == null or not AnathemaFx.marked_at(env, at).has(far_house)),
		"it marks the buildings standing within reach of the click (%d)" % AnathemaFx.marked_at(env, at).size())

	# --- CURSED
	var dweller: Person = crowd.citizens[0]
	crowd.shelters._enter(dweller, house)
	(crowd.shelters.shelters[house].inside as Array).append(dweller)
	dweller.mind = Person.Mind.SHELTER
	dweller.shelter = house
	dweller.shelter_door = crowd.shelters._door(house, at + Vector2.DOWN)
	var curse: AnathemaFx = FxTimeline.cast(load("res://src/fx/dominion/anathema.gd"), ctx, at, {"mode": "cursed"})
	t.check(crowd.structure_mark(house) == &"" and curse.buildings.is_empty(), "Anathema: nothing is marked until it is laid")
	curse._process(AnathemaFx.T_CAST + 0.05)
	t.check(curse.mark == AnathemaFx.CURSED and curse.buildings.has(house) and crowd.structure_mark(house) == AnathemaFx.CURSED
		and (far_house == null or crowd.structure_mark(far_house) == &""), "then every building in reach is cursed, and none beyond")
	t.check(not crowd.shelters._usable(house), "a cursed shelter takes nobody in")
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.2)
	t.check(not dweller.inside and crowd.shelters.occupants(house) == 0, "and whoever was inside comes out")
	var bystander: Person = crowd.citizens[1]
	bystander.mind = Person.Mind.CALM
	bystander.ground_pos = grid.nearest_walkable(at + Vector2(0.0, house.footprint.size.y * 0.5 + 0.6))
	var stood := bystander.ground_pos
	curse._process(AnathemaFx.SHUN_EVERY + 0.05)
	t.check(bystander.mind == Person.Mind.COMPELLED and bystander.goal().distance_to(at) > stood.distance_to(at), "one idling by a cursed wall walks away from it")
	bystander.release_compulsion()
	var tower: Structure = crowd.bell.tower
	if tower != null and is_instance_valid(tower):
		crowd.mark_structure(tower, AnathemaFx.CURSED, 10.0)
		crowd.bell.state = BellNetwork.State.IDLE
		crowd.bell.call_keeper()
		t.check(crowd.bell.state == BellNetwork.State.WAITING, "the keeper will not climb a cursed Bell Tower (%s)" % BellNetwork.State.keys()[crowd.bell.state])
		crowd.bell.state = BellNetwork.State.IDLE
	crowd.fires.ignite(house, 0.3)
	t.check(crowd.fires.is_burning(house) and crowd.fires.nearest_fightable(at, 30.0) != house, "a fire on a cursed building is nobody's to fight")
	crowd.fires.clear()
	crowd._clock += AnathemaFx.SPAN + 1.0
	curse._process(AnathemaFx.SPAN + 1.0)
	curse.free()
	t.check(crowd.structure_mark(house) == &"" and crowd.shelters._usable(house), "the span over, the curse lifts")

	# --- HALLOWED
	var faithful: Array[Person] = []
	for k in 5:
		var p: Person = crowd.citizens[2 + k]
		p.mind = Person.Mind.CALM
		p.ground_pos = grid.nearest_walkable(at + Vector2(2.0 + 0.4 * float(k), 3.0))
		faithful.append(p)
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = grid.nearest_walkable(at + Vector2(-2.0, 3.0))
	var soldier_mind := soldier.mind
	var holy: AnathemaFx = FxTimeline.cast(load("res://src/fx/dominion/anathema.gd"), ctx, at, {"mode": "hallowed"})
	holy._process(AnathemaFx.T_CAST + 0.05)
	var going := 0
	for p in faithful:
		if p.mind == Person.Mind.SHELTER and p.shelter != null and crowd.structure_mark(p.shelter) == AnathemaFx.HALLOWED:
			going += 1
	t.check(holy.mark == AnathemaFx.HALLOWED and crowd.structure_mark(house) == AnathemaFx.HALLOWED and going == 5 and soldier.mind == soldier_mind,
		"Hallowed: every citizen in the district makes for a hallowed house; the guard is not called (%d)" % going)
	# They arrive and go in, however many; the house is struck and set alight, and they stay.
	var took: Structure = faithful[0].shelter
	for p in faithful:
		p.ground_pos = p.shelter_door
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.2)
	var in_now := 0
	for p in faithful:
		if p.inside:
			in_now += 1
	t.check(in_now == 5, "they go in (%d)" % in_now)
	took.hp = took.max_hp * 0.3
	crowd.fires.ignite(took, 0.4)
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.2)
	in_now = 0
	for p in faithful:
		if p.inside:
			in_now += 1
	t.check(in_now == 5, "and stay in a house struck and burning: a tomb (%d)" % in_now)
	crowd._clock += AnathemaFx.SPAN + 1.0
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.2)
	t.check(crowd.structure_mark(took) == &"" and crowd.shelters.occupants(took) == 0,
		"the mark lifted, those in the burning house run from it as anyone would (%d still in)" % crowd.shelters.occupants(took))
	holy._process(AnathemaFx.SPAN + 1.0)
	holy.free()
	crowd.fires.clear()
	_done(made)
