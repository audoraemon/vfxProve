extends RefCounted
## Door to the Deep: a door opens in the ground and black water floods a circle of the town for a while -- everyone in
## it wades at a third of their pace, every fire in it goes out, every building in it takes slow water damage -- and
## then it drains, and nobody is the worse for it but the buildings.


## A Mirrorfold stub: whatever is poured anywhere comes out six units down the map.
class Shift extends RefCounted:
	func carries(_p: Vector2) -> bool:
		return true

	func across(p: Vector2) -> Vector2:
		return p + Vector2(0, 6)


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


static func _about(value: float, expected: float, share: float) -> bool:
	return absf(value - expected) <= absf(expected) * share


static func run(t) -> void:
	var b := PowerBook.get_power("deep")
	var area: Dictionary = Targeting.AREAS.get("deep", {})
	t.check(int(b.dp) == 2 and not PowerBook.is_quiet("deep") and String(b.aim) == "click" and PowerBook.authority_of("deep") == "passage"
		and PowerBook.icon("deep") != null and PowerBook.hud_icon("deep") != null and PowerBook.clip("deep") != null
		and String(area.get("shape", "")) == "circle" and is_equal_approx(float(area.get("r", 0.0)), DoorToTheDeepFx.RADIUS)
		and Rules.POWER_KINDS.has("deep") and (Rules.POWER_KINDS["deep"] as Array).is_empty()
		and is_equal_approx(PowerBook.impact("deep"), DoorToTheDeepFx.T_OPEN) and PowerBook.family("deep") != "",
		"Door to the Deep is Passage's 2 DP, loud, a click on a circle of RADIUS, kills nobody, its impact the door's opening, with icons, clip and a family")

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
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- The water's reach in time
	var fx: DoorToTheDeepFx = FxTimeline.cast(load("res://src/fx/control/door_to_the_deep.gd"), ctx, at)
	var T_OPEN := DoorToTheDeepFx.T_OPEN
	var SPREAD := DoorToTheDeepFx.SPREAD
	var SPAN := DoorToTheDeepFx.SPAN
	var DRAIN := DoorToTheDeepFx.DRAIN
	var TICK := DoorToTheDeepFx.TICK
	t.check(fx.mouth == at and is_equal_approx(fx.busy, T_OPEN) and fx.reach(T_OPEN - 0.1) == 0.0
		and is_equal_approx(fx.reach(T_OPEN + SPREAD), DoorToTheDeepFx.RADIUS) and is_equal_approx(fx.reach(T_OPEN + SPAN), DoorToTheDeepFx.RADIUS)
		and fx.reach(T_OPEN + SPAN + DRAIN + 0.01) == 0.0 and fx.reach(T_OPEN + SPAN + DRAIN * 0.5) < DoorToTheDeepFx.RADIUS,
		"the door is the click; no water before it opens, a circle of RADIUS once it has spread and for the span, none after the drain")

	# --- People in the water
	var wader: Person = crowd.citizens[0]
	wader.mind = Person.Mind.CALM
	wader.ground_pos = at + Vector2(2.0, 0.0)
	wader.walk_speed = wader._mind_speed()
	var normal := wader.walk_speed
	var dry: Person = crowd.citizens[1]
	dry.mind = Person.Mind.CALM
	dry.ground_pos = at + Vector2(DoorToTheDeepFx.RADIUS + 0.5, 0.0)
	dry.walk_speed = dry._mind_speed()
	var dry_normal := dry.walk_speed
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = at + Vector2(0.0, 1.5)
	guard.walk_speed = guard._mind_speed()
	var guard_normal := guard.walk_speed
	# --- Buildings in the water: a burning shed within reach, a burning one well beyond it, and a dry one by the door.
	var shed := env.add_structure(Rect2(at + Vector2(0.6, -1.6), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var far_shed := env.add_structure(Rect2(at + Vector2(6.0, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var soaked := env.add_structure(Rect2(at + Vector2(-1.0, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	crowd.fires.ignite(shed, 0.6)
	crowd.fires.ignite(far_shed, 0.6)
	var hp := soaked.hp
	var alive := crowd.alive_citizens()
	var soldiers := crowd.alive_soldiers()

	fx._process(T_OPEN - 0.1)
	t.check(is_equal_approx(wader.walk_speed, normal) and not wader.statuses.has(&"slow") and crowd.fires.is_burning(shed)
		and is_equal_approx(soaked.hp, hp), "before the door opens nobody wades, no fire is touched, no wall is wet")
	fx._process(0.1 + SPREAD + TICK)
	t.check(wader.statuses.has(&"slow") and _about(wader.walk_speed, DoorToTheDeepFx.SLOW * normal, 0.1),
		"once the water has spread, a citizen two steps from the door walks at a third of his pace (%.2f of %.2f)" % [wader.walk_speed, normal])
	t.check(_about(guard.walk_speed, DoorToTheDeepFx.SLOW * guard_normal, 0.1), "a soldier in it wades as slowly")
	t.check(is_equal_approx(dry.walk_speed, dry_normal) and not dry.statuses.has(&"slow"), "one standing half a step beyond the water keeps his pace")
	wader.ground_pos = at + Vector2(DoorToTheDeepFx.RADIUS + 1.0, 0.0)
	fx._process(TICK)
	t.check(is_equal_approx(wader.walk_speed, normal) and not wader.statuses.has(&"slow"), "whoever steps out of the water has his pace back at once")

	# --- Fires and walls, five seconds into the flood
	fx._process(5.0 - SPREAD - 2.0 * TICK)
	var ticks := 5.0 / TICK
	t.check(not crowd.fires.is_burning(shed) and fx.doused == 1, "a burning shed within reach is out after five seconds of water")
	t.check(crowd.fires.is_burning(far_shed), "one burning six units off still burns")
	t.check(_about(hp - soaked.hp, DoorToTheDeepFx.SOAK * ticks, 0.2) and not soaked.destroyed,
		"a shed by the door has taken SOAK a tick of water damage (%.1f for %.0f ticks)" % [hp - soaked.hp, ticks])
	t.check(not crowd.fires.is_burning(soaked), "water sets nothing alight")
	var water_threat := false
	for z in crowd.threats.nearby(at, 0.5):
		water_threat = water_threat or z.kind == &"water"
	t.check(water_threat, "the flooded circle is a mild threat: people go round it")

	# --- The drain
	fx._process(SPAN + DRAIN - 5.0 + 0.1)
	t.check(fx.reach(fx.t) == 0.0 and is_equal_approx(guard.walk_speed, guard_normal) and not guard.statuses.has(&"slow"),
		"when it drains the soldier who stood in it the whole while has his pace back and no slow on him")
	t.check(crowd.alive_citizens() == alive and crowd.alive_soldiers() == soldiers, "nobody drowns")
	fx.free()
	crowd.fires.clear()

	# --- Through a Mirrorfold
	field.portals.append(Shift.new())
	var carried: DoorToTheDeepFx = FxTimeline.cast(load("res://src/fx/control/door_to_the_deep.gd"), ctx, at)
	t.check(carried.mouth == at + Vector2(0, 6), "poured onto a Mirrorfold's way in, the door opens at its way out")
	field.portals.clear()
	carried.free()
	_done(made)
