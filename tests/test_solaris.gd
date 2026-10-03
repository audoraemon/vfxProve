extends RefCounted
## Light of Solaris: nothing is harmed while it gathers; once the pillar lands everyone and everything under it is gone,
## and so is whoever walks in while it stands; when it lifts it leaves a pit that outlasts the effect and takes whoever
## steps into it. The ground stays walkable: nobody knows to go round.

const PATH := "res://src/fx/solaris/light_of_solaris.gd"


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
	ctx.overhead = Node2D.new()
	ctx.overhead_back = Node2D.new()
	ctx.world = world
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.overhead_back.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func run(t) -> void:
	var p := PowerBook.get_power("solaris")
	t.check(PowerBook.authority_of("solaris") == "ruin" and not PowerBook.is_quiet("solaris") and PowerBook.icon("solaris") != null
		and PowerBook.hud_icon("solaris") != null and PowerBook.clip("solaris") != null and PowerBook.REACH.has("solaris"),
		"%s is a Ruin power the town sees, with its icons and clip" % p.name)
	t.check(Rules.POWER_KINDS["solaris"] == [&"solaris", &"pit"], "its casts are credited with the beam's dead and the pit's")

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := Vector2(2.75, 11.25)  # the Main Gate's plaza
	var r: float = LightOfSolaris.RADIUS
	var victim: Person = crowd.citizens[0]
	victim.ground_pos = at + Vector2(0.5, 0.0)
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = at - Vector2(0.8, 0.3)
	var far: Person = crowd.citizens[1]
	far.ground_pos = at + Vector2(r + 0.5, 0.0)
	var house := env.add_structure(Rect2(at + Vector2(-1.0, 0.6), Vector2(0.8, 0.8)), 20.0, Structure.Kind.HOUSE, &"house")
	var keep := env.add_structure(Rect2(at + Vector2(0.4, -1.4), Vector2(0.8, 0.8)), 30.0, Structure.Kind.KEEP, &"citadel")

	var fx: LightOfSolaris = FxTimeline.cast(load(PATH), ctx, at)
	t.check(fx.busy < 0.0 and is_equal_approx(fx.duration, LightOfSolaris.T_END + LightOfSolaris.AFTER),
		"it locks the other slots for its whole run")
	fx._process(LightOfSolaris.T_CHARGE - 0.1)
	t.check(victim.is_alive() and guard.is_alive() and not house.destroyed and fx.pit == null,
		"nothing is harmed while the light gathers")
	fx._process(0.15)
	t.check(not victim.is_alive() and not guard.is_alive() and house.destroyed,
		"the pillar lands: citizen, soldier and house under it are gone")
	t.check(far.is_alive(), "someone just outside it lives")
	t.check(fx.pit != null and not fx.pit.armed, "the ground opens under the pillar; the pit waits while it stands")
	var late: Person = crowd.citizens[2]
	late.ground_pos = at
	fx._process(LightOfSolaris.SCOUR_EVERY * 1.5)
	t.check(not late.is_alive() and late._kind == &"solaris", "whoever walks in while it stands is burned away")

	fx._process(LightOfSolaris.T_END - fx.t + 0.05)
	var pit := fx.pit
	t.check(pit.armed and not house.visible and not keep.visible,
		"when it lifts, the rubble over it is gone -- the Citadel's too -- and the pit is open")
	var later_house := env.add_structure(Rect2(at + Vector2(1.0, 0.2), Vector2(0.6, 0.6)), 20.0, Structure.Kind.HOUSE, &"house")
	later_house.destroy(later_house.center(), &"stone")
	t.check(not later_house.visible, "and so is the rubble of anything that comes down over it later")
	t.check(is_equal_approx(pit.radius, r) and pit.center == at, "the pit is the pillar's own circle")
	var walker: Person = crowd.citizens[3]
	walker.ground_pos = at + Vector2(0.3, 0.2)
	var toe: Person = crowd.citizens[4]
	toe.ground_pos = at + Vector2(r * 0.97, 0.0)
	pit.advance(SolarisPit.CHECK_EVERY)
	t.check(not walker.is_alive() and walker._kind == &"pit", "whoever walks into the pit falls")
	t.check(toe.is_alive(), "a toe on the lip is not in")

	fx._process(LightOfSolaris.AFTER + 0.1)
	t.check(fx.finished and is_instance_valid(pit) and pit.get_parent() == ctx.world and pit.is_in_group(SolarisPit.GROUP), "the pit outlasts the effect, in the world layer")
	var later: Person = crowd.soldiers[1]
	later.ground_pos = at
	pit.advance(60.0)
	t.check(not later.is_alive() and pit.fallen == 2, "and takes whoever walks in a minute later (%d fallen)" % pit.fallen)
	t.check(grid.walkable(at), "the ground stays walkable: nobody knows to go round")
	fx.free()
	_done(made)  # the pit goes with the world layer
