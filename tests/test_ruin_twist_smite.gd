extends RefCounted
## Smite level 5, Forked Bolt (Ruin ability levels, Task 2): 0.12 s after the strike a full bolt leaps to the nearest person within 2.5 of the click.

const SMITE := preload("res://src/fx/ruin/smite.gd")


static func run(t) -> void:
	_forks(t)
	_level_four(t)
	_nobody_near(t)
	_nobody_at_the_click(t)
	_inside_and_ties(t)
	_same_draws(t)


static func _ctx(seed_value: int) -> FxContext:
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
	return ctx


static func _drop(ctx: FxContext) -> void:
	ctx.field.clear()
	ctx.field.free()
	ctx.env.clear()
	ctx.env.free()
	ctx.overhead.free()
	ctx.ground.free()


static func _man(ctx: FxContext, at: Vector2, inside := false) -> Person:
	var p := Person.new()
	p.ground_pos = at
	p.inside = inside
	ctx.field.add(p)
	return p


## Cast at the origin at `level`, run past the strike and the fork.
static func _cast(ctx: FxContext, level: int) -> SmiteFx:
	var fx: SmiteFx = FxTimeline.cast(SMITE, ctx, Vector2.ZERO, {"level": level})
	fx._process(SmiteFx.T_STRIKE + 0.01)
	return fx


static func _end(fx: SmiteFx) -> void:
	fx._process(3.0)
	fx.free()


static func _forks(t) -> void:
	var ctx := _ctx(1)
	var a := _man(ctx, Vector2(0.3, 0.0))
	var b := _man(ctx, Vector2(0.0, 2.0))
	var c := _man(ctx, Vector2(-3.0, 0.0))
	var fx := _cast(ctx, 5)
	t.check(not a.is_alive() and b.is_alive() and fx.struck == 1 and fx.forked_at == Vector2.INF,
		"level 5: the first bolt takes the one at 0.3 and the fork is still in the air (struck %d)" % fx.struck)
	fx._process(SmiteFx.FORK_DELAY + 0.01)
	t.check(not a.is_alive() and not b.is_alive() and c.is_alive() and fx.struck == 2,
		"level 5: both nearer die, the one at 3.0 lives (struck %d)" % fx.struck)
	t.check(fx.forked_at == Vector2(0.0, 2.0), "level 5: forked_at is the second one's spot (%s)" % fx.forked_at)
	_end(fx)
	_drop(ctx)


static func _level_four(t) -> void:
	var ctx := _ctx(1)
	var a := _man(ctx, Vector2(0.3, 0.0))
	var b := _man(ctx, Vector2(0.0, 2.0))
	var fx := _cast(ctx, 4)
	fx._process(SmiteFx.FORK_DELAY + 0.5)
	t.check(not a.is_alive() and b.is_alive() and fx.struck == 1 and fx.forked_at == Vector2.INF,
		"level 4: only the first dies, forked_at stays INF")
	_end(fx)
	_drop(ctx)


static func _nobody_near(t) -> void:
	var ctx := _ctx(1)
	var a := _man(ctx, Vector2(0.3, 0.0))
	var far := _man(ctx, Vector2(0.0, 2.6))
	var fx := _cast(ctx, 5)
	fx._process(SmiteFx.FORK_DELAY + 0.5)
	t.check(not a.is_alive() and far.is_alive() and fx.forked_at == Vector2.INF, "level 5 with the only other person at 2.6: no fork")
	_end(fx)
	_drop(ctx)
	ctx = _ctx(1)
	fx = _cast(ctx, 5)
	fx._process(SmiteFx.FORK_DELAY + 0.5)
	t.check(fx.forked_at == Vector2.INF and fx.struck == 0, "level 5 with nobody anywhere: no fork, no error")
	_end(fx)
	_drop(ctx)


static func _nobody_at_the_click(t) -> void:
	var ctx := _ctx(1)
	var b := _man(ctx, Vector2(2.0, 0.0))
	var fx := _cast(ctx, 5)
	t.check(b.is_alive() and fx.struck == 0, "nobody at the click: the first bolt strikes nobody")
	fx._process(SmiteFx.FORK_DELAY + 0.01)
	t.check(not b.is_alive() and fx.forked_at == Vector2(2.0, 0.0) and fx.struck == 1, "...and it still forks to the one at 2.0")
	_end(fx)
	_drop(ctx)


static func _inside_and_ties(t) -> void:
	# A person indoors is never the fork's target, even the nearest.
	var ctx := _ctx(1)
	var indoors := _man(ctx, Vector2(1.0, 0.0), true)
	var open := _man(ctx, Vector2(0.0, 2.2))
	var fx := _cast(ctx, 5)
	fx._process(SmiteFx.FORK_DELAY + 0.01)
	t.check(indoors.is_alive() and not open.is_alive() and fx.forked_at == Vector2(0.0, 2.2), "an indoor person is skipped; the one in the open at 2.2 is struck")
	_end(fx)
	_drop(ctx)
	# Equal distance: the field's order decides (the one added first).
	ctx = _ctx(1)
	var first := _man(ctx, Vector2(1.5, 0.0))
	var second := _man(ctx, Vector2(-1.5, 0.0))
	fx = _cast(ctx, 5)
	fx._process(SmiteFx.FORK_DELAY + 0.01)
	t.check(not first.is_alive() and second.is_alive() and fx.forked_at == Vector2(1.5, 0.0), "a tie goes to the field's order")
	_end(fx)
	_drop(ctx)


## The twist adds no random draw to a headless cast: the rng ends where a level-4 cast leaves it.
static func _same_draws(t) -> void:
	var states: Array[int] = []
	for level in [4, 5]:
		var ctx := _ctx(7)
		_man(ctx, Vector2(0.3, 0.0))
		_man(ctx, Vector2(0.0, 2.0))
		var fx := _cast(ctx, level)
		fx._process(SmiteFx.FORK_DELAY + 0.5)
		states.append(ctx.rng.state)
		_end(fx)
		_drop(ctx)
	t.check(states[0] == states[1], "level 5 draws the same random numbers as level 4 (%d vs %d)" % [states[0], states[1]])
