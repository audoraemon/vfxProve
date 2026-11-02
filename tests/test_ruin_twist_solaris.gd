extends RefCounted
## Solaris level 5 twist, Wandering Sun (Ruin ability levels, R10): the pillar drifts toward a knot of people within 4.0 of it, looking
## again every half second, at 0.8 u/s and never past it; the pit follows and is left where the pillar stops. Level 1-4 stands still.

const PATH := "res://src/fx/solaris/light_of_solaris.gd"
const AT := Vector2(2.75, 11.25)  # the Main Gate's plaza


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
	# Everyone else is moved well away, so only the people a test places are near the cast.
	var away := AT + Vector2(40.0, 40.0)
	for e in field.alive():
		e.ground_pos = away
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.overhead_back.free()
	ctx.ground.free()
	(made[4] as Node).free()


## Five in a knot along the east line (2.8 .. 3.2 from `at`): each has four neighbours within 1.0; the one at 2.8 is nearest.
static func _knot_at(crowd: Crowd, at: Vector2, dist: float) -> Array[Person]:
	var out: Array[Person] = []
	for i in 5:
		var p: Person = crowd.citizens[i]
		p.ground_pos = at + Vector2(dist - 0.2 + 0.1 * i, 0.0)
		out.append(p)
	return out


## Step the cast from `fx.t` to `to` in 0.1 s ticks.
static func _run_to(fx: LightOfSolaris, to: float) -> void:
	while fx.t < to - 0.0001:
		fx._process(minf(0.1, to - fx.t))


static func run(t) -> void:
	_drift(t)
	_reach(t)
	_level_four(t)
	_far_knot(t)
	_staged_follow(t)


## A knot 3.0 east and a loner 2.0 west: the pillar (shrunk to 1.0 so nobody dies while it is measured) drifts 0.8 u/s east.
static func _drift(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var knot := _knot_at(crowd, AT, 3.0)
	var loner: Person = crowd.citizens[5]
	loner.ground_pos = AT - Vector2(2.0, 0.0)
	var fx: LightOfSolaris = FxTimeline.cast(load(PATH), ctx, AT, {"level": 5})
	fx.lv_radius = 1.0
	t.check(fx.beam_at == AT, "level 5: the pillar starts on the cast point")
	_run_to(fx, LightOfSolaris.T_CHARGE)
	t.check(fx.pit != null and fx.beam_at == AT, "it lands where it was cast")
	_run_to(fx, LightOfSolaris.T_CHARGE + 2.0)
	t.check(absf(fx.beam_at.x - (AT.x + 1.6)) <= 0.05 and absf(fx.beam_at.y - AT.y) <= 0.01,
		"after 2 s of beam the pillar has drifted 1.6 east toward the knot (%s)" % str(fx.beam_at - AT))
	t.check(fx.pit.center == fx.beam_at, "the pit goes with it")
	t.check(loner.is_alive() and knot[0].is_alive(), "the loner and the knot are still alive: the 1.0 pillar has not reached them")
	_run_to(fx, fx.lv_t_end + 0.1)
	t.check(fx.beam_at.x <= AT.x + 2.8 + 0.001, "never past the knot's nearest person (%.2f east)" % (fx.beam_at.x - AT.x))
	var stop := fx.beam_at
	_run_to(fx, fx.lv_t_end + 1.0)
	t.check(fx.beam_at == stop and fx.pit.center == stop, "when the beam lifts it stops, and the pit is left where it stopped")
	fx.free()
	_done(made)


## The real level-5 pillar (radius 3.0): a knot 3.8 east is out of reach at first, and burned once the pillar has drifted up to it.
static func _reach(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var knot := _knot_at(crowd, AT, 3.8)
	var fx: LightOfSolaris = FxTimeline.cast(load(PATH), ctx, AT, {"level": 5})
	t.check(is_equal_approx(fx.lv_radius, 3.0), "level 5's pillar is 3.0 wide")
	_run_to(fx, LightOfSolaris.T_CHARGE + 0.3)
	t.check(knot[0].is_alive() and knot[4].is_alive(), "the knot is out of reach when the beam lands")
	_run_to(fx, LightOfSolaris.T_CHARGE + 2.0)
	var dead := 0
	for p in knot:
		if not p.is_alive():
			dead += 1
	t.check(dead == 5 and knot[0]._kind == &"solaris", "once the pillar has drifted up to them, the whole knot is burned away (%d)" % dead)
	fx.free()
	_done(made)


## Level 4 (and the same cast with no twist) never moves.
static func _level_four(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var knot := _knot_at(crowd, AT, 3.8)
	var fx: LightOfSolaris = FxTimeline.cast(load(PATH), ctx, AT, {"level": 4})
	var still := true
	while fx.t < fx.lv_t_end + 0.5:
		fx._process(0.1)
		still = still and fx.beam_at == AT
	t.check(still and fx.pit.center == AT, "level 4: the pillar and its pit stay on the cast point throughout")
	t.check(knot[0].is_alive(), "level 4: a knot out of the 2.8 pillar's reach lives")
	fx.free()
	_done(made)


## A knot 5.0 away is out of the pillar's reach (4.0): it is ignored and stands.
static func _far_knot(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var knot := _knot_at(crowd, AT, 5.0)
	var fx: LightOfSolaris = FxTimeline.cast(load(PATH), ctx, AT, {"level": 5})
	_run_to(fx, fx.lv_t_end + 0.5)
	t.check(fx.beam_at == AT, "a knot 5.0 away is ignored: the pillar stands")
	var alive := 0
	for p in knot:
		if p.is_alive():
			alive += 1
	t.check(alive == 5, "and the knot stands")
	fx.free()
	_done(made)


## The pillar's pieces follow it: `_follow()` puts the column, glows, lights and emitters where the pillar stands. (A headless cast
## has no stage, so the pieces are bare ones handed in; the staged show itself is checked by the eye and the smoke run.)
static func _staged_follow(t) -> void:
	var made := _setup()
	var ctx: FxContext = made[5]
	var fx: LightOfSolaris = FxTimeline.cast(load(PATH), ctx, AT, {"level": 5})
	fx._column = QuadFx.new()
	fx._halo = QuadFx.new()
	fx._glow = QuadFx.new()
	fx._light = QuadFx.new()
	fx._rays = QuadFx.new()
	fx._updraft = PixelParticles.new()
	fx._sparks = PixelParticles.new()
	fx.beam_at = AT + Vector2(1.5, -0.5)
	fx._follow()
	var sp := Iso.ground_to_screen(fx.beam_at)
	t.check(fx._column.position.is_equal_approx(sp) and fx._glow.position.is_equal_approx(sp)
		and fx._halo.position.is_equal_approx(sp + Vector2(0, -LightOfSolaris.COLUMN_H * 0.3))
		and fx._sparks.position.is_equal_approx(sp) and fx._updraft.position.is_equal_approx(sp),
		"its column, glows and sparks follow in screen space")
	t.check(fx._light.position.is_equal_approx(fx.beam_at) and fx._rays.position.is_equal_approx(fx.beam_at),
		"its ground light and rays follow on the ground")
	for n in [fx._column, fx._halo, fx._glow, fx._light, fx._rays, fx._updraft, fx._sparks]:
		n.free()
	fx.free()
	_done(made)
