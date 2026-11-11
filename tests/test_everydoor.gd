extends RefCounted
## Every Door: for SPAN every door in town obeys the cast's mode. SHUT -- nobody goes into or comes out of any building
## (the barracks too), nobody climbs the bell tower, nobody leaves the town (gates, roads, boat); the queue waits. OPEN --
## everyone indoors is thrown into the street in front of its door, knocked down, and no building takes anyone in; the
## ways out work. When the span ends, everything goes on.


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
	# Everyone out of the way in a corner, calm, so only the people a check sets up matter.
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _cast(ctx: FxContext, mode: String) -> EveryDoorFx:
	return FxTimeline.cast(load("res://src/fx/control/every_door.gd"), ctx, Vector2(1.0, 1.0), {"mode": mode})


## `p` taken inside shelter `s`, come in by the door on the street side below it.
static func _put_inside(crowd: Crowd, p: Person, s: Structure) -> void:
	p.mind = Person.Mind.SHELTER
	p.shelter = s
	p.shelter_door = crowd.shelters._door(s, s.center() + Vector2(0.0, 5.0))
	crowd.shelters._enter(p, s)
	(crowd.shelters.shelters[s].inside as Array).append(p)


## `p` on its way to shelter `s`, standing at its door now.
static func _at_door(crowd: Crowd, p: Person, s: Structure) -> void:
	p.mind = Person.Mind.CALM
	p.seek_shelter(s, crowd.shelters._door(s, s.center() + Vector2(0.0, 5.0)))
	(crowd.shelters.shelters[s].coming as Array).append(p)
	p.ground_pos = p.shelter_door
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _step_shelters(crowd: Crowd) -> void:
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.25)


## `p` fleeing, standing at the front of `gate`'s crowd.
static func _at_gate(crowd: Crowd, p: Person, gate: Structure) -> void:
	var spots := crowd.queue_spots(gate)
	p.mind = Person.Mind.FLEE
	p.passing_gate = null
	p.queue_spot = Vector2.INF
	p.queue_since = -1.0
	p.ground_pos = spots[0]
	p._goal = gate.center() + Crowd.outward_of(gate) * 4.0
	p._path = PackedVector2Array()


static func _gate_tick(crowd: Crowd) -> void:
	crowd._gate_next.clear()
	crowd._gates()


## `p` fleeing, standing at a way out on foot (not the dock).
static func _at_exit(crowd: Crowd, p: Person) -> bool:
	for e in crowd.evac.exits:
		if not crowd.evac.is_boat_exit(e):
			p.mind = Person.Mind.FLEE
			p.ground_pos = e
			p._goal = e
			p._path = PackedVector2Array()
			return true
	return false


## The bellkeeper at the tower's foot, on duty, called to the rope.
static func _keeper_at_foot(bell: BellNetwork) -> void:
	bell.keeper.go_ring(bell.foot)
	bell.keeper.ground_pos = bell.foot
	bell.keeper._goal = Vector2.INF
	bell.keeper._path = PackedVector2Array()
	bell.state = BellNetwork.State.CALLED


static func run(t) -> void:
	var b := PowerBook.get_power("everydoor")
	var modes: Array = b.get("modes", [])
	t.check(int(b.dp) == 5 and float(b.cooldown) >= 999.0 and PowerBook.authority_of("everydoor") == "passage"
		and PowerBook.is_quiet("everydoor") and modes.size() == 2 and String(modes[0].key) == "shut" and String(modes[1].key) == "open"
		and PowerBook.icon("everydoor") != null and PowerBook.hud_icon("everydoor") != null and PowerBook.clip("everydoor") != null
		and Targeting.AREAS.has("everydoor") and Rules.POWER_KINDS.has("everydoor") and PowerBook.family("everydoor") != "",
		"Every Door is Passage's 5 DP, once a descent, quiet, SHUT or OPEN, with icons, clip, area, kinds and a family")
	_shut(t)
	_open(t)


static func _shut(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var houses: Array = crowd.shelters.shelters.keys()
	var house: Structure = houses[0]
	var other: Structure = houses[1]
	var barracks: Structure = null
	for s: Structure in houses:
		if s.kind == Structure.Kind.BARRACKS:
			barracks = s
			break

	crowd.set_doors(&"shut", 1.0)
	crowd._clock += 1.1
	t.check(crowd.doors() == &"", "the doors' rule runs out by itself on the town's clock")

	var dweller: Person = crowd.citizens[0]
	_put_inside(crowd, dweller, house)
	var guard: Person = crowd.soldiers[0]
	if barracks != null:
		_put_inside(crowd, guard, barracks)
	var comer: Person = crowd.citizens[1]
	_at_door(crowd, comer, other)
	var gate: Structure = null
	for g in crowd._town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			gate = g
			break
	var waiting: Person = crowd.citizens[2]
	var leaving: Person = crowd.citizens[3]
	var alarm := crowd.threats.active_count()
	var dead := crowd.killed_citizens + crowd.killed_soldiers

	var fx := _cast(ctx, "shut")
	t.check(crowd.doors() == &"" and not fx.holding, "SHUT: nothing changes until the door in the sky has opened")
	fx._process(EveryDoorFx.T_FLASH + 0.05)
	t.check(fx.mode == EveryDoorFx.SHUT and crowd.doors_shut() and fx.holding, "then every door in town is shut")
	t.check(crowd.threats.active_count() == alarm and crowd.killed_citizens + crowd.killed_soldiers == dead,
		"the cast is no danger: nobody is frightened or hurt by it")

	# Nobody gets in.
	_step_shelters(crowd)
	t.check(not comer.inside and comer.mind != Person.Mind.SHELTER, "one at a shelter's door finds it shut and turns away")
	var late: Person = crowd.citizens[4]
	late.ground_pos = grid.nearest_walkable(other.center() + Vector2(0.0, 3.0))
	late.mind = Person.Mind.CALM
	t.check(not crowd.shelters.try_shelter(late, late.ground_pos + Vector2(4.0, 0.0), 1.0, &"nova")
		and not crowd.shelters.send_in(late, other) and not late.inside, "no shelter takes anyone in, frightened or sent")

	# Nobody inside comes out, whatever happens to the building or the town.
	house.hp = house.max_hp * 0.3
	crowd.fires.ignite(house, 0.4)
	crowd.alarms.stage = AlarmManager.Stage.EVACUATION
	_step_shelters(crowd)
	t.check(dweller.inside and crowd.shelters.occupants(house) == 1,
		"nobody inside comes out: not from a house struck and burning, not when the town evacuates")
	if barracks != null:
		t.check(guard.inside and crowd.shelters.occupants(barracks) >= 1, "the garrison stays in its barracks")
	crowd.alarms.stage = AlarmManager.Stage.NORMAL

	# Nobody leaves the town.
	if gate != null:
		_at_gate(crowd, waiting, gate)
		_gate_tick(crowd)
		_gate_tick(crowd)
		t.check(waiting.passing_gate == null and waiting.queue_spot != Vector2.INF,
			"the gate lets nobody through: the one at its head waits at it")
	var escaped := crowd.escaped_count
	var at_exit := _at_exit(crowd, leaving)
	if at_exit:
		crowd._escapes()
		t.check(crowd.escaped_count == escaped and crowd.citizens.has(leaving), "one standing at the way out does not leave the town")
	var ferry := crowd.ferry
	var sailor: Person = crowd.citizens[5]
	var boat := ferry != null and ferry.dock != null and ferry.board_at != Vector2.INF
	if boat:
		ferry.state = RiverFerry.State.LOADING
		sailor.mind = Person.Mind.FLEE
		sailor.ground_pos = ferry.board_at
		sailor._goal = ferry.board_at
		sailor._path = PackedVector2Array()
		ferry.step(0.1)
		t.check(not ferry.aboard.has(sailor) and not sailor.inside, "nobody steps aboard the boat")

	# Nobody climbs the bell tower; a bell already rung rings on.
	var bell := crowd.bell
	var tower := bell != null and bell.state != BellNetwork.State.SILENCED and is_instance_valid(bell.tower) \
		and is_instance_valid(bell.keeper)
	if tower:
		_keeper_at_foot(bell)
		bell.step(0.1)
		t.check(bell.state == BellNetwork.State.CALLED, "the keeper at the tower's foot cannot go up (%s)" % BellNetwork.State.keys()[bell.state])
		bell.state = BellNetwork.State.CLIMBING
		bell.progress = 1.0
		bell.step(0.5)
		t.check(bell.state == BellNetwork.State.CLIMBING and is_equal_approx(bell.progress, 1.0), "a climb under way stands where it is")
		bell.state = BellNetwork.State.RUNG
		bell.step(0.5)
		t.check(bell.state == BellNetwork.State.RUNG, "a bell already rung rings on")
		_keeper_at_foot(bell)

	# The span ends: everything goes on.
	fx._process(EveryDoorFx.SPAN)
	t.check(crowd.doors() == &"" and not fx.holding, "the span over, the doors are the town's again")
	_step_shelters(crowd)
	t.check(not dweller.inside and crowd.shelters.occupants(house) == 0, "and those in the struck, burning house run from it as anyone would")
	t.check(crowd.shelters.send_in(late, other), "a shelter takes people in again")
	if gate != null:
		_gate_tick(crowd)
		t.check(waiting.passing_gate == gate, "the gate lets its crowd through again")
	if at_exit:
		crowd._escapes()
		t.check(crowd.escaped_count == escaped + 1, "the one at the way out gets away")
	if boat:
		ferry.step(0.1)
		t.check(ferry.aboard.has(sailor), "the boat takes on passengers again")
	if tower:
		bell.step(0.1)
		t.check(bell.state == BellNetwork.State.CLIMBING, "the keeper climbs the tower again")
	crowd.fires.clear()
	fx.free()
	_done(made)


static func _open(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var houses: Array = crowd.shelters.shelters.keys()
	var a: Structure = houses[0]
	var b: Structure = houses[1]
	var indoors: Array[Person] = [crowd.citizens[0], crowd.citizens[1], crowd.citizens[2]]
	_put_inside(crowd, indoors[0], a)
	_put_inside(crowd, indoors[1], b)
	_put_inside(crowd, indoors[2], b)
	var doors: Array[Vector2] = []
	for p in indoors:
		doors.append(p.shelter_door)
	var comer: Person = crowd.citizens[3]
	_at_door(crowd, comer, a)
	var bell := crowd.bell
	var tower := bell != null and bell.state != BellNetwork.State.SILENCED and is_instance_valid(bell.tower) \
		and is_instance_valid(bell.keeper)
	if tower:
		_keeper_at_foot(bell)
		bell.state = BellNetwork.State.CLIMBING
		bell.progress = 2.0

	var fx := _cast(ctx, "open")
	fx._process(EveryDoorFx.T_FLASH + 0.05)
	t.check(fx.mode == EveryDoorFx.OPEN and crowd.doors_open() and not crowd.doors_shut(), "OPEN: every door in town stands open")
	var out := 0
	var by_door := 0
	var down := 0
	for i in indoors.size():
		var p := indoors[i]
		if not p.inside and p.visible and fx.thrown.has(p) and field.alive().has(p):
			out += 1
		if p.ground_pos.distance_to(doors[i]) <= EveryDoorFx.THROW + 0.6 and grid.walkable(p.ground_pos) \
				and p.ground_pos.distance_to(houses[0 if i == 0 else 1].center()) > doors[i].distance_to(houses[0 if i == 0 else 1].center()):
			by_door += 1
		if p.is_down():
			down += 1
	t.check(out == 3 and crowd.shelters.total_inside() == 0, "everyone inside every building is thrown out into the street (%d)" % out)
	t.check(by_door == 3, "each lands in front of the door it came in by, about THROW out from it (%d)" % by_door)
	t.check(down == 3, "and is knocked down (%d)" % down)

	# No building takes anyone in.
	_step_shelters(crowd)
	t.check(not comer.inside and comer.mind != Person.Mind.SHELTER, "one at a shelter's door is not taken in")
	var late: Person = crowd.citizens[4]
	late.ground_pos = grid.nearest_walkable(a.center() + Vector2(0.0, 3.0))
	late.mind = Person.Mind.CALM
	t.check(not crowd.shelters.try_shelter(late, late.ground_pos + Vector2(4.0, 0.0), 1.0, &"nova")
		and not crowd.shelters.send_in(late, a), "no shelter takes anyone in, frightened or sent")
	if tower:
		t.check(fx.thrown.has(bell.keeper) and bell.keeper.is_down(), "the bell's climber is thrown down at the tower's foot")
		bell.step(0.1)
		t.check(bell.state == BellNetwork.State.CALLED and is_zero_approx(bell.progress), "and his climb is lost")
		bell.keeper._goal = Vector2.INF
		bell.step(0.1)
		t.check(bell.state == BellNetwork.State.CALLED, "the tower takes nobody up while the doors stand open")

	# The ways out of town are untouched.
	var gate: Structure = null
	for g in crowd._town.gates:
		if is_instance_valid(g) and not g.destroyed and g.walkable:
			gate = g
			break
	if gate != null:
		var runner: Person = crowd.citizens[5]
		_at_gate(crowd, runner, gate)
		_gate_tick(crowd)
		t.check(runner.passing_gate == gate, "a gate still lets its crowd through")
	var leaving: Person = crowd.citizens[6]
	if _at_exit(crowd, leaving):
		var escaped := crowd.escaped_count
		crowd._escapes()
		t.check(crowd.escaped_count == escaped + 1, "and one at the way out gets away")

	# The span ends: the buildings take people in again.
	fx._process(EveryDoorFx.SPAN)
	t.check(crowd.doors() == &"", "the span over, the doors are the town's again")
	t.check(crowd.shelters.send_in(late, a), "a shelter takes people in again")
	late.ground_pos = late.shelter_door
	late._goal = Vector2.INF
	late._path = PackedVector2Array()
	_step_shelters(crowd)
	t.check(late.inside, "and they go in")
	if tower:
		_keeper_at_foot(bell)
		bell.step(0.1)
		t.check(bell.state == BellNetwork.State.CLIMBING, "the keeper climbs the tower again")
	fx.free()
	_done(made)
