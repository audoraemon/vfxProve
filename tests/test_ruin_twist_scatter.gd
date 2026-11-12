extends RefCounted
## Scatter Strike level 5, Seeking Bursts (Ruin ability levels, Task 5): as each burst draws the air in, its point moves to the nearest person in the
## open within 1.5 of it. The random draws are unchanged.

const SCATTER := preload("res://src/fx/ruin/scatter_strike.gd")
const SEED := 5
const AT := Vector2(2.0, 3.0)


static func run(t) -> void:
	_seeks(t)
	_level_four(t)
	_inside(t)
	_same_draws(t)
	_nearest_and_ties(t)


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


static func _cast(ctx: FxContext, level: int) -> ScatterStrikeFx:
	return FxTimeline.cast(SCATTER, ctx, AT, {"level": level})


## The points a level-4 cast draws on SEED (the same draws any level's cast makes, as far as it goes).
static func _level_four_points() -> Array[Vector2]:
	var ctx := _ctx(SEED)
	var fx := _cast(ctx, 4)
	var pts := fx.points.duplicate()
	fx.free()
	_drop(ctx)
	return pts


## Run the cast past `blast` (index) and a little beyond: its compress and its blast have both fired.
static func _past(fx: ScatterStrikeFx, blast: int) -> void:
	fx._process(ScatterStrikeFx.T_FIRST + ScatterStrikeFx.BLAST_GAP * float(blast) + 0.05)


static func _seeks(t) -> void:
	var base := _level_four_points()
	var ctx := _ctx(SEED)
	var near_3 := _man(ctx, base[3] + Vector2(1.0, 0.0))
	var near_5 := _man(ctx, base[5] + Vector2(2.0, 0.0))
	var fx := _cast(ctx, 5)
	var same := true
	for i in base.size():
		same = same and fx.points[i] == base[i]
	t.check(same and fx.points.size() == 16, "level 5: the 15 points drawn at the cast are level 4's (the 16th is one more draw)")
	_past(fx, 3)
	t.check(fx.points[3] == Vector2(near_3.ground_pos) and not near_3.is_alive(), "level 5: burst 3 moved onto the person 1.0 from it and killed him (%s)" % fx.points[3])
	t.check(fx.points[5] == base[5] and near_5.is_alive(), "burst 5 has not gone yet and the one 2.0 away is out of reach")
	_past(fx, 5)
	t.check(fx.points[5] == base[5] and near_5.is_alive(), "level 5: burst 5's point is unchanged with the nearest person 2.0 away")
	fx._process(10.0)
	fx.free()
	_drop(ctx)


static func _level_four(t) -> void:
	var base := _level_four_points()
	var ctx := _ctx(SEED)
	_man(ctx, base[3] + Vector2(1.0, 0.0))
	var fx := _cast(ctx, 4)
	fx._process(10.0)
	var same := true
	for i in base.size():
		same = same and fx.points[i] == base[i]
	t.check(same, "level 4: no point moves")
	t.check(fx.points[3] == base[3] and fx.blasts == 15, "level 4: burst 3 still falls where it was drawn")
	fx.free()
	_drop(ctx)


static func _inside(t) -> void:
	var base := _level_four_points()
	var ctx := _ctx(SEED)
	var indoors := _man(ctx, base[7] + Vector2(0.5, 0.0), true)
	var fx := _cast(ctx, 5)
	_past(fx, 7)
	t.check(fx.points[7] == base[7] and indoors.is_alive(), "level 5: a person inside is never sought (and the blast spares him)")
	fx._process(10.0)
	fx.free()
	_drop(ctx)


## The twist adds no random draw: a level-5 cast draws two numbers per point (16 points) at the cast and nothing after, however the bursts seek.
static func _same_draws(t) -> void:
	var ctx := _ctx(SEED)
	_man(ctx, AT + Vector2(1.0, 1.0))
	var fx := _cast(ctx, 5)
	var after_cast := ctx.rng.state
	fx._process(10.0)
	t.check(ctx.rng.state == after_cast, "level 5: the bursts themselves draw nothing (seeking is not random)")
	fx.free()
	_drop(ctx)
	var plain := RandomNumberGenerator.new()
	plain.seed = SEED
	for i in 32:
		plain.randf()
	t.check(plain.state == after_cast, "and the cast drew exactly the 16 x 2 numbers level 4's draws are the start of")


static func _nearest_and_ties(t) -> void:
	var ctx := _ctx(SEED)
	var fx := _cast(ctx, 5)
	var p := Vector2(-10.0, -10.0)
	t.check(fx.seek(p) == p, "seek() with nobody near returns the point")
	_man(ctx, p + Vector2(1.2, 0.0))
	_man(ctx, p + Vector2(0.0, 0.8))
	_man(ctx, p + Vector2(0.0, -0.8))
	t.check(fx.seek(p) == p + Vector2(0.0, 0.8), "seek() takes the nearest, and a tie goes to the field's order")
	var dead := _man(ctx, p + Vector2(0.1, 0.0))
	ctx.field.kill(dead, &"test")
	t.check(fx.seek(p) == p + Vector2(0.0, 0.8), "and never a dead one")
	fx.free()
	_drop(ctx)
