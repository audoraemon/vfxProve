extends RefCounted
## Divine Congregation: the citizens in the circle walk, at a walk, to spots of their own round the place, keep their
## compulsion through an evacuation but not through a danger on top of them, resist by what they are (soldiers always),
## go back to their day when it is over, and are let go at once when the place falls. The town sees nothing but a
## little unease.

const PATH := "res://src/fx/dominion/divine_congregation.gd"


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
	var p := PowerBook.get_power("congregation")
	t.check(PowerBook.authority_of("congregation") == "dominion" and PowerBook.is_quiet("congregation") and String(p.aim) == "two clicks"
		and float(p.alarm) == CongregationFx.ALARM_GENERATED and PowerBook.icon("congregation") != null
		and PowerBook.hud_icon("congregation") != null and PowerBook.clip("congregation") != null,
		"%s is a quiet Dominion power of two clicks, with its icons and clip" % p.name)

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	# Everyone far off, then a district's worth placed in the circle.
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var market := TownLayout.MARKET_SQUARE.get_center()
	var at := grid.nearest_walkable(market + Vector2(3.0, 2.0))  # the circle's middle, off the place
	var inside: Array[Person] = []
	for k in 12:
		var c: Person = crowd.citizens[k]
		c.ground_pos = grid.nearest_walkable(at + Vector2(cos(float(k)) * 2.0, sin(float(k)) * 2.0))
		c.mind = Person.Mind.CALM
		inside.append(c)
	var outside: Person = crowd.citizens[12]
	outside.ground_pos = grid.nearest_walkable(at + Vector2(CongregationFx.RADIUS + 1.0, 0.0))
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = at
	var alarm := crowd.alarm

	# The place: open ground at the market gives spots in rings; a house gives spots round its walls.
	var ground_place := CongregationFx.place_for(env, market)
	var spots := CongregationFx.spots_for(grid, ground_place, 12)
	var apart := true
	for a in spots.size():
		for b in range(a + 1, spots.size()):
			apart = apart and spots[a].distance_to(spots[b]) >= CongregationFx.GATHER_SPACING * 0.95
	t.check(spots.size() == 12 and apart, "twelve spots round the place, each its own (%d)" % spots.size())
	var house: Structure = null
	for s in env.structures():
		if s.role == &"house" and not s.destroyed:
			house = s
			break
	var house_place := CongregationFx.place_for(env, house.center())
	var house_spots := CongregationFx.spots_for(grid, house_place, 8)
	var round_it: bool = house_place.structure == house and house_spots.size() == 8
	for g in house_spots:
		round_it = round_it and not house.contains(g) and house.distance_to(g) < 1.5
	t.check(round_it, "a click on a house gathers round its walls")

	var fx: CongregationFx = FxTimeline.cast(load(PATH), ctx, market, {"to": at})
	t.check(fx.busy == 1.0 and fx.duration == CongregationFx.DURATION, "the cast locks the slots for 1 s, not its whole run")
	var all_in := true
	for c in inside:
		all_in = all_in and c.mind == Person.Mind.COMPELLED and c.intent() == Person.Intent.GATHER and c.has_goal()
	t.check(all_in and fx.gathered.size() == 12, "everyone in the circle is drawn to the place (%d)" % fx.gathered.size())
	t.check(outside.mind == Person.Mind.CALM, "someone outside it is not")
	t.check(guard.mind == Person.Mind.POST and fx.resisted >= 1, "a soldier resists")
	t.check(not inside[0].is_running() and is_equal_approx(inside[0].walk_speed, Person.WALK_SPEED * inside[0].pace),
		"they walk, as if of their own mind")
	var own_spots := {}
	for c in inside:
		own_spots[c.goal()] = true
	t.check(own_spots.size() == 12, "each to a spot of its own (%d)" % own_spots.size())
	t.check(crowd.threats.active_count() == 0, "the town sees no danger")
	crowd.on_cast(market, Vector2.ZERO, 0.0, "congregation")
	t.check(is_equal_approx(crowd.alarm - alarm, CongregationFx.ALARM_GENERATED), "and is only a little unsettled (+%.1f)" % (crowd.alarm - alarm))

	# Arrived, they stand; an evacuation does not call them away; a danger on top of them does.
	var first := inside[0]
	first.ground_pos = first.goal()
	first._goal = Vector2.INF
	first._path = PackedVector2Array()
	first._pick_target()
	t.check(first.mind == Person.Mind.COMPELLED and first._target.is_equal_approx(first.ground_pos), "arrived, they stand")
	first.flee()
	first.regroup(Vector2.ZERO)
	t.check(first.mind == Person.Mind.COMPELLED, "an evacuation or a regrouping does not call them away")
	first.panic(first.ground_pos, 0.5)
	t.check(first.mind != Person.Mind.COMPELLED, "a danger on top of them does")

	# When it is over, each takes up its day again.
	var second := inside[1]
	fx._process(CongregationFx.DURATION - 0.3)
	t.check(second.mind == Person.Mind.COMPELLED, "they stay until it is over")
	second._think(CongregationFx.DURATION)
	t.check(second.mind == Person.Mind.RECOVER and second.compel_will == 0.0, "then look about and take up their day")
	fx._process(1.0)
	t.check(fx.finished, "and the effect is done")
	fx.free()

	# The place falls: everyone let go at once.
	var third := inside[2]
	third.mind = Person.Mind.CALM
	var fx2: CongregationFx = FxTimeline.cast(load(PATH), ctx, house.center(), {"to": third.ground_pos})
	t.check(fx2.place == house and third.mind == Person.Mind.COMPELLED, "gathered to a house")
	house.destroy(house.center(), &"stone")
	fx2._process(CongregationFx.CHECK_EVERY + 0.05)
	t.check(third.mind != Person.Mind.COMPELLED and fx2.gathered.is_empty(), "when it falls, everyone is let go at once")
	fx2._process(2.0)
	fx2.free()
	_done(made)
