extends RefCounted
## Ember level 5, Leaping Spark (Ruin ability levels, Task 3): 1.0 s after it lands, a second spark leaps to the nearest other thing that burns
## within 3.0 of the first one's centre, if the first caught.

const EMBER := preload("res://src/fx/ruin/ember.gd")


static func run(t) -> void:
	_leaps(t)
	_level_four(t)
	_nothing_to_leap_to(t)
	_already_burning(t)
	_no_town(t)
	_durations(t)


static func _ctx(seed_value: int, with_town := true) -> FxContext:
	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = seed_value
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	if with_town:
		var crowd := Crowd.new()
		crowd.fires = FireManager.new().setup(crowd, env, seed_value)
		ctx.crowd = crowd
	return ctx


static func _drop(ctx: FxContext) -> void:
	if ctx.crowd != null:
		ctx.crowd.fires.clear()
		ctx.crowd.free()
	ctx.field.clear()
	ctx.field.free()
	ctx.env.clear()
	ctx.env.free()
	ctx.overhead.free()
	ctx.ground.free()


## A house of 0.6 x 0.6 whose centre is `centre`.
static func _house(ctx: FxContext, centre: Vector2, kind := Structure.Kind.HOUSE) -> Structure:
	return ctx.env.add_structure(Rect2(centre - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), 18.0, kind, &"house")


static func _cast(ctx: FxContext, at: Vector2, level: int) -> EmberFx:
	return FxTimeline.cast(EMBER, ctx, at, {"level": level})


static func _end(fx: EmberFx) -> void:
	fx._process(5.0)
	fx.free()


static func _leaps(t) -> void:
	var ctx := _ctx(1)
	var a := _house(ctx, Vector2(10.0, 10.0))
	var b := _house(ctx, Vector2(12.5, 10.0))
	var c := _house(ctx, Vector2(10.0, 13.5))
	var fx := _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND + 0.05)
	t.check(fx.lit and ctx.crowd.fires.is_burning(a) and not ctx.crowd.fires.is_burning(b), "level 5: the first spark lights A and B waits")
	fx._process(EmberFx.LEAP_DELAY * 0.5)
	t.check(not ctx.crowd.fires.is_burning(b), "...half a second later B is still dark")
	fx._process(EmberFx.T_LAND + 1.1 - fx.t)
	t.check(ctx.crowd.fires.is_burning(a) and ctx.crowd.fires.is_burning(b) and not ctx.crowd.fires.is_burning(c) and fx.leapt == b,
		"level 5: after T_LAND + 1.1 A and B are lit, C (3.5 from A) is not")
	t.check(is_equal_approx(ctx.crowd.fires.intensity(b), EmberFx.START_LEVEL + 0.2), "the second spark starts B at the level's START_LEVEL (0.65 at level 5)")
	t.check(PowerBook.is_quiet("ember"), "Ember is still a quiet power")
	_end(fx)
	_drop(ctx)


static func _level_four(t) -> void:
	var ctx := _ctx(1)
	var a := _house(ctx, Vector2(10.0, 10.0))
	var b := _house(ctx, Vector2(12.5, 10.0))
	var fx := _cast(ctx, a.center(), 4)
	fx._process(EmberFx.T_LAND + 1.3)
	t.check(ctx.crowd.fires.is_burning(a) and not ctx.crowd.fires.is_burning(b) and fx.leapt == null, "level 4: only A is lit, nothing leaps")
	_end(fx)
	_drop(ctx)


static func _nothing_to_leap_to(t) -> void:
	# A cannot burn: nothing catches, so nothing leaps (B stands in reach and stays dark).
	var ctx := _ctx(1)
	var stone := _house(ctx, Vector2(10.0, 10.0), Structure.Kind.BLOCK)
	var b := _house(ctx, Vector2(12.0, 10.0))
	var fx := _cast(ctx, Vector2(10.0, 10.0), 5)
	fx._process(EmberFx.T_LAND + 1.3)
	t.check(not fx.lit and fx.fuel == null and fx.leapt == null and not ctx.crowd.fires.is_burning(stone) and not ctx.crowd.fires.is_burning(b),
		"level 5, the click on bare stone: it does not catch, so there is no leap")
	_end(fx)
	_drop(ctx)
	# Nothing else in reach (3.2 away: beyond LEAP_R).
	ctx = _ctx(1)
	var a := _house(ctx, Vector2(10.0, 10.0))
	var far := _house(ctx, Vector2(13.4, 10.0))
	fx = _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND + 1.3)
	t.check(ctx.crowd.fires.is_burning(a) and fx.leapt == null and not ctx.crowd.fires.is_burning(far), "level 5, the next house beyond 3.0 of A: no leap")
	_end(fx)
	_drop(ctx)
	# Only A: a lone house.
	ctx = _ctx(1)
	a = _house(ctx, Vector2(10.0, 10.0))
	fx = _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND + 1.3)
	t.check(ctx.crowd.fires.is_burning(a) and fx.leapt == null, "level 5, a lone house: no leap, no error")
	_end(fx)
	_drop(ctx)


static func _already_burning(t) -> void:
	# B already burns: the spark takes the next nearest within 3.0.
	var ctx := _ctx(1)
	var a := _house(ctx, Vector2(10.0, 10.0))
	var b := _house(ctx, Vector2(12.0, 10.0))
	var d := _house(ctx, Vector2(10.0, 12.8))
	ctx.crowd.fires.ignite(b, 0.3)
	var fx := _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND + 1.3)
	t.check(fx.leapt == d and ctx.crowd.fires.is_burning(d) and is_equal_approx(ctx.crowd.fires.intensity(b), 0.3),
		"B already burning: the leap takes the next nearest (D at 2.8), and B's fire is left alone")
	_end(fx)
	_drop(ctx)
	# B already burns and nothing else is near: no leap.
	ctx = _ctx(1)
	a = _house(ctx, Vector2(10.0, 10.0))
	b = _house(ctx, Vector2(12.0, 10.0))
	ctx.crowd.fires.ignite(b, 0.3)
	fx = _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND + 1.3)
	t.check(fx.leapt == null and is_equal_approx(ctx.crowd.fires.intensity(b), 0.3), "B already burning and nothing else near: no leap")
	_end(fx)
	_drop(ctx)


## With no town keeping fires the blow itself is fire's, as the first spark's is.
static func _no_town(t) -> void:
	var ctx := _ctx(1, false)
	var a := _house(ctx, Vector2(10.0, 10.0))
	var b := _house(ctx, Vector2(12.5, 10.0))
	var fx := _cast(ctx, a.center(), 5)
	var hp_a := a.hp
	var hp_b := b.hp
	fx._process(EmberFx.T_LAND + 1.3)
	t.check(fx.leapt == b and a.hp < hp_a and b.hp < hp_b, "no town: the second spark strikes B as the first struck A")
	_end(fx)
	_drop(ctx)


static func _durations(t) -> void:
	var ctx := _ctx(1)
	var five := _cast(ctx, Vector2.ZERO, 5)
	var four := _cast(ctx, Vector2.ZERO, 4)
	var one: EmberFx = FxTimeline.cast(EMBER, ctx, Vector2.ZERO)
	t.check(is_equal_approx(five.duration, EmberFx.T_LAND + EmberFx.LEAP_DELAY + 1.6) and is_equal_approx(four.duration, EmberFx.T_LAND + 1.6)
		and is_equal_approx(one.duration, EmberFx.T_LAND + 1.6), "duration stretches by LEAP_DELAY at level 5 only")
	t.check(is_equal_approx(five.busy, EmberFx.T_LAND) and is_equal_approx(four.busy, EmberFx.T_LAND), "busy stays T_LAND")
	five.free()
	four.free()
	one.free()
	_drop(ctx)
