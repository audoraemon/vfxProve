extends RefCounted
## Smite level 5, Gathered Storm (Smite and Ember adjustments, Task 1): a drag from the press grows the bolt -- kill radius KILL_R * s,
## every building within HIT_R * s hit -- with s = 1 + drag / GROW_PER, GROW_MAX at most. A click (or a twitch) is the plain bolt.

const SMITE := preload("res://src/fx/ruin/smite.gd")


static func run(t) -> void:
	_grow_for(t)
	_click_is_plain(t)
	_drag_grows(t)
	_cap(t)
	_below_five(t)
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


## A small house whose nearest edge is `d` east of the origin, too stout for one blow to fell (so the blow shows in its hp).
static func _house(ctx: FxContext, d: float) -> Structure:
	return _stout(ctx.env.add_structure(Rect2(Vector2(d, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house"))


## The same, `d` west of the origin.
static func _west_house(ctx: FxContext, d: float) -> Structure:
	return _stout(ctx.env.add_structure(Rect2(Vector2(-d - 0.6, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house"))


static func _stout(s: Structure) -> Structure:
	s.max_hp = 500.0
	s.hp = 500.0
	return s


## Cast at the origin with `extra`, run past the strike.
static func _cast(ctx: FxContext, extra: Dictionary) -> SmiteFx:
	var fx: SmiteFx = FxTimeline.cast(SMITE, ctx, Vector2.ZERO, extra)
	fx._process(SmiteFx.T_STRIKE + 0.01)
	return fx


static func _end(fx: SmiteFx) -> void:
	fx._process(3.0)
	fx.free()


static func _kill_r(level: int) -> float:
	return float(PowerBook.level_stat("smite", level, "KILL_R", SmiteFx.KILL_R))


static func _grow_for(t) -> void:
	t.check(SmiteFx.GROW_PER == 1.5 and SmiteFx.GROW_MAX == 2.5, "GROW_PER 1.5, GROW_MAX 2.5")
	t.check(SmiteFx.grow_for(0.0) == 1.0 and is_equal_approx(SmiteFx.grow_for(1.5), 2.0) and SmiteFx.grow_for(9.0) == 2.5,
		"grow_for: no drag 1.0, a drag of 1.5 doubles, a long one stops at 2.5 (%.2f, %.2f, %.2f)"
		% [SmiteFx.grow_for(0.0), SmiteFx.grow_for(1.5), SmiteFx.grow_for(9.0)])
	t.check(SmiteFx.grow_for(-1.0) == 1.0, "grow_for never shrinks the bolt")
	t.check(SmiteFx.grow_of({"level": 5}, Vector2.ZERO) == 1.0 and SmiteFx.grow_of({"level": 4, "to": Vector2(1.5, 0.0)}, Vector2.ZERO) == 1.0
		and is_equal_approx(SmiteFx.grow_of({"level": 5, "to": Vector2(1.5, 0.0)}, Vector2.ZERO), 2.0)
		and SmiteFx.grow_of({"level": 5, "to": Vector2(Targeting.DRAG_MIN - 0.1, 0.0)}, Vector2.ZERO) == 1.0,
		"grow_of: level 5 with no drag, below level 5, and a twitch under the dead zone are 1.0; a level 5 drag of 1.5 is 2.0")


## A level 5 cast with no drag is the level 4 bolt with the level 5 numbers, and lays no fork.
static func _click_is_plain(t) -> void:
	var r := _kill_r(5)
	for extra: Dictionary in [{"level": 5}, {"level": 5, "to": Vector2(0.2, 0.0), "dir": Targeting.DEFAULT_DIR}]:
		var ctx := _ctx(1)
		var a := _man(ctx, Vector2(0.0, -(r - 0.02)))
		var b := _man(ctx, Vector2(0.0, r + 0.05))
		var c := _man(ctx, Vector2(0.0, 2.0))
		var near := _house(ctx, SmiteFx.HIT_R - 0.05)
		var far := _west_house(ctx, SmiteFx.HIT_R + 0.05)
		var fx := _cast(ctx, extra)
		fx._process(0.5)
		t.check(fx.grow == 1.0 and not a.is_alive() and b.is_alive() and c.is_alive() and fx.struck == 1,
			"level 5 %s: only the one inside KILL_R(5) %.2f dies, nobody else is struck afterwards (struck %d)" % [extra, r, fx.struck])
		t.check(is_equal_approx(near.hp, near.max_hp - fx.lv_damage) and far.hp == far.max_hp,
			"level 5 %s: the house within HIT_R takes DAMAGE, the one past it none" % [extra])
		t.check(not ("forked_at" in fx) and not (load("res://src/fx/ruin/smite.gd") as GDScript).get_script_constant_map().has("FORK_R"),
			"the fork is gone")
		_end(fx)
		_drop(ctx)


## A level 5 drag of 1.5: s = 2.0.
static func _drag_grows(t) -> void:
	var r := _kill_r(5)
	var ctx := _ctx(1)
	var inside := _man(ctx, Vector2(0.0, -1.9 * r))
	var outside := _man(ctx, Vector2(0.0, 2.1 * r))
	var indoors := _man(ctx, Vector2(0.0, 1.0 * r), true)
	var near := _house(ctx, SmiteFx.HIT_R * 2.0 - 0.05)
	var far := _west_house(ctx, SmiteFx.HIT_R * 2.0 + 0.05)
	var fx := _cast(ctx, {"level": 5, "to": Vector2(0.0, -1.5), "dir": Vector2(0.0, -1.0)})
	t.check(is_equal_approx(fx.grow, 2.0), "a level 5 drag of 1.5 grows the bolt 2x (%.2f)" % fx.grow)
	t.check(not inside.is_alive() and outside.is_alive() and indoors.is_alive() and fx.struck == 1,
		"it kills at 1.9 x KILL_R(5) and spares 2.1 x, and indoors is safe (struck %d)" % fx.struck)
	t.check(is_equal_approx(near.hp, near.max_hp - fx.lv_damage) and far.hp == far.max_hp,
		"a house within HIT_R x 2 takes DAMAGE (hp %.1f), one past it none (hp %.1f)" % [near.hp, far.hp])
	_end(fx)
	_drop(ctx)


## A drag of 10: the radius stops at GROW_MAX.
static func _cap(t) -> void:
	var r := _kill_r(5)
	var ctx := _ctx(1)
	var inside := _man(ctx, Vector2(2.45 * r, 0.0))
	var outside := _man(ctx, Vector2(-2.55 * r, 0.0))
	var fx := _cast(ctx, {"level": 5, "to": Vector2(10.0, 0.0), "dir": Vector2(1.0, 0.0)})
	t.check(fx.grow == SmiteFx.GROW_MAX and not inside.is_alive() and outside.is_alive(),
		"a drag of 10 is capped at 2.5x: 2.45 x KILL_R(5) dies, 2.55 x lives (grow %.2f)" % fx.grow)
	_end(fx)
	_drop(ctx)


## Below level 5 a drag (a bot's "to") grows nothing.
static func _below_five(t) -> void:
	var ctx := _ctx(1)
	var r := _kill_r(4)
	var a := _man(ctx, Vector2(r - 0.02, 0.0))
	var b := _man(ctx, Vector2(1.5 * r, 0.0))
	var fx := _cast(ctx, {"level": 4, "to": Vector2(0.0, 3.0)})
	t.check(fx.grow == 1.0 and not a.is_alive() and b.is_alive() and fx.struck == 1, "level 4 with a \"to\": the plain level 4 bolt")
	_end(fx)
	_drop(ctx)


## The twist adds no random draw to a headless cast: the rng ends where a level-4 cast leaves it.
static func _same_draws(t) -> void:
	var states: Array[int] = []
	for extra: Dictionary in [{"level": 4}, {"level": 5, "to": Vector2(2.0, 0.0)}]:
		var ctx := _ctx(7)
		_man(ctx, Vector2(0.3, 0.0))
		_man(ctx, Vector2(0.0, 2.0))
		var fx := _cast(ctx, extra)
		fx._process(0.5)
		states.append(ctx.rng.state)
		_end(fx)
		_drop(ctx)
	t.check(states[0] == states[1], "a grown level 5 bolt draws the same random numbers as level 4 (%d vs %d)" % [states[0], states[1]])
