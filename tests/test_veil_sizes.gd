extends RefCounted
## Veil Task 3: Silent Doom and Unseen Hour take two sizes (VeilRules.SIZES): small on lit ground, full in the dark (extra["dark"]).
## Each lays the dusk its landing leaves, when it lands. With no crowd both still build and finish.


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
	crowd.dusk.enabled = true
	var ctx := _ctx(env, field, crowd)
	return [crowd, env, grid, field, world, ctx]


static func _ctx(env: EnvironmentField, field: EnemyField, crowd: Crowd) -> FxContext:
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return ctx


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _scatter(crowd: Crowd) -> void:
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p.inside = false
		i += 1


## Two people 0.7 and 1.2 from `at`; casts a doom and runs it past its strike. Returns [near alive, far alive, dusk count at the
## strike, dusk count just before it, the fx].
static func _doom(made: Array, at: Vector2, extra: Dictionary) -> Array:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	_scatter(crowd)
	crowd.dusk.clear()
	var near: Person = crowd.citizens[0]
	var far: Person = crowd.citizens[1]
	near.ground_pos = at + Vector2(0.7, 0.0)
	far.ground_pos = at + Vector2(0.0, 1.2)
	var fx: FxTimeline = FxTimeline.cast(load("res://src/fx/quiet/silent_doom.gd"), ctx, at, extra)
	fx._process(SilentDoom.T_STRIKE - 0.05)
	var before := crowd.dusk.count()
	fx._process(0.1)
	return [near.is_alive(), far.is_alive(), crowd.dusk.count(), before, fx]


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- Silent Doom
	_scatter(crowd)
	var np: Person = crowd.citizens[0]
	np.ground_pos = at + Vector2(0.7, 0.0)
	t.check(SilentDoom.victims_at(made[3], at).has(np) and SilentDoom.victims_at(made[3], at, 1.0).has(np)
		and not SilentDoom.victims_at(made[3], at, 0.5).has(np), "victims_at(field, at, r) takes a radius; the default is RADIUS")
	var lit := _doom(made, at, {})
	t.check(not lit[0] and lit[1], "doom in the light: the person at 0.7 falls, the one at 1.2 does not")
	t.check(lit[3] == 0 and lit[2] == 1 and crowd.dusk.covers(at + Vector2(VeilRules.DUSK_R - 0.1, 0.0))
		and not crowd.dusk.covers(at + Vector2(VeilRules.DUSK_R + 0.3, 0.0)),
		"it lays a dusk of DUSK_R at the click when it strikes, not before (%d before, %d after)" % [lit[3], lit[2]])
	var dark := _doom(made, at, {"dark": true})
	t.check(not dark[0] and not dark[1], "doom cast in the dark: both fall")
	t.check(dark[3] == 0 and dark[2] == 1, "the dark one lays its dusk at the strike too")

	# --- Unseen Hour
	_scatter(crowd)
	crowd.dusk.clear()
	var hour: UnseenHourFx = FxTimeline.cast(load("res://src/fx/quiet/unseen_hour.gd"), ctx, at)
	t.check(crowd.dusk.count() == 0, "unseen lays no dusk before it falls")
	hour._process(UnseenHourFx.T_FALL + 0.05)
	t.check(crowd.is_veiled(at + Vector2(4.9, 0.0)) and not crowd.is_veiled(at + Vector2(5.1, 0.0)),
		"unseen in the light veils out to 5.0 and not past it")
	t.check(crowd.dusk.count() == 1 and crowd.dusk.r_at(at) >= 5.0 - 0.01,
		"unseen lays a dusk of its own radius (%d patches, r %.2f)" % [crowd.dusk.count(), crowd.dusk.r_at(at)])
	crowd.advance(20.1)
	t.check(not crowd.is_veiled(at), "the light veil is gone after 20.8 s")
	hour.end_now()
	t.check(hour.finished, "end_now() finishes the hour")
	crowd.dusk.clear()

	var dk: UnseenHourFx = FxTimeline.cast(load("res://src/fx/quiet/unseen_hour.gd"), ctx, at, {"dark": true})
	dk._process(UnseenHourFx.T_FALL + 0.05)
	t.check(crowd.is_veiled(at + Vector2(6.9, 0.0)) and not crowd.is_veiled(at + Vector2(7.1, 0.0)),
		"unseen cast in the dark veils out to 7.0 and not past it")
	t.check(crowd.dusk.r_at(at) >= 7.0 - 0.01, "its dusk is the dark radius (r %.2f)" % crowd.dusk.r_at(at))
	crowd.advance(28.3)
	t.check(crowd.is_veiled(at), "the dark veil is still up at 29 s")
	crowd.advance(2.0)
	t.check(not crowd.is_veiled(at), "and gone by 31 s (30 s long)")

	# Another hour: ending the node early leaves nothing the node held (the veil is the crowd's, by its clock).
	var live: FxTimeline = FxTimeline.cast(load("res://src/fx/quiet/silent_doom.gd"), ctx, at)
	live.end_now()
	t.check(live.finished, "positive control: end_now() finishes a doom")
	_done(made)

	# --- no crowd, no rules (the VFX Sandbox): both build and finish
	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	var bare := _ctx(env, field, null)
	var d: FxTimeline = FxTimeline.cast(load("res://src/fx/quiet/silent_doom.gd"), bare, Vector2.ZERO, {"dark": true})
	d._process(SilentDoom.T_STRIKE + 0.1)
	d.end_now()
	var u: FxTimeline = FxTimeline.cast(load("res://src/fx/quiet/unseen_hour.gd"), bare, Vector2.ZERO)
	u._process(UnseenHourFx.T_FALL + 0.1)
	u.end_now()
	t.check(d.finished and u.finished, "with no crowd both build and finish without an error")
	bare.overhead.free()
	bare.ground.free()
