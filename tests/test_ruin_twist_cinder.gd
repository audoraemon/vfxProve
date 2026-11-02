extends RefCounted
## Cinderfall level 5 twist, the Lava Pool (Ruin ability levels): the crater the volcano leaves stays molten for LAVA_TIME seconds, kills what
## stands in it and sets the burnables beside it alight. Level 4 shows nothing of it.

const FxStage := preload("res://tests/fx_stage.gd")
const CinderFx := preload("res://src/fx/set2/cinderfall_barrage.gd")

const AT := Vector2(12.0, 12.0)


static func run(t) -> void:
	_level_five(t)
	_level_four(t)


## Cast at `level` on a fresh stage; the volcano is already sunk by T_SINK and the barrage over, so nothing but the pool can kill at the centre.
static func _cast(level: int) -> Array:
	var bf := FxStage.make(11)
	var fx = FxTimeline.cast(load("res://src/fx/set2/cinderfall_barrage.gd"), bf.ctx, AT, {"level": level})
	return [bf, fx]


## Step the effect to the effect clock `to`, 0.1 s a frame.
static func _step(fx, to: float) -> void:
	while fx.t < to - 0.0001 and not fx.finished:
		fx._process(minf(0.1, to - fx.t))


static func _level_five(t) -> void:
	var made: Array = _cast(5)
	var bf: Battlefield = made[0]
	var fx = made[1]
	t.check(is_equal_approx(fx.busy, 12.0) and is_equal_approx(fx.duration, CinderFx.T_SINK + CinderFx.LAVA_TIME + 1.0),
		"Cinder level 5: the slots unlock at 12 s (busy %.1f), the cast lasts to cover the pool (%.1f)" % [fx.busy, fx.duration])
	# The barrage falls by 7.5 s: put the houses and the dummy in after it, so no stone touches them.
	_step(fx, CinderFx.T_SINK - 0.15)
	var near_house := bf.ctx.env.add_structure(Rect2(AT + Vector2(2.9, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var far_house := bf.ctx.env.add_structure(Rect2(AT + Vector2(-0.3, 3.5), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	t.check(not fx.pool_open, "the pool is shut until the volcano sinks")
	_step(fx, CinderFx.T_SINK + 0.1)
	t.check(fx.pool_open and absf(fx.pool_until - (fx.t - 0.1 + CinderFx.LAVA_TIME)) < 0.15, "the pool opens at the sink and burns %.0f s" % CinderFx.LAVA_TIME)
	# The sunk volcano's own kill zone is a tween's work, which a stepped effect does not run: end it here.
	fx._volcano.sink = 1.0
	t.check(near_house.hp < near_house.max_hp, "a house 2.9 away is set alight when it opens (no town: a blow of fire)")
	t.check(is_equal_approx(far_house.hp, far_house.max_hp), "one 3.5 away is not")
	var kinds := {}
	bf.ctx.field.enemy_killed.connect(func(e, kind): kinds[e] = kind)
	_step(fx, CinderFx.T_SINK + 5.0)
	var inside := DummyEnemy.new()
	inside.ground_pos = AT + Vector2(1.0, 0.0)
	bf.ctx.field.add(inside)
	var outside := DummyEnemy.new()
	outside.ground_pos = AT + Vector2(1.7, 0.0)
	bf.ctx.field.add(outside)
	_step(fx, CinderFx.T_SINK + 5.3)
	t.check(not inside.is_alive() and kinds.get(inside, &"") == &"cinder", "a dummy walked to 1.0 from the centre at 5 s dies of cinder")
	t.check(outside.is_alive(), "one at 1.7, outside the pool, lives")
	t.check(near_house.hp < near_house.max_hp - 1.5, "the house is set alight again every 3 s (hp %.1f)" % near_house.hp)
	_step(fx, CinderFx.T_SINK + 15.5)
	var late := DummyEnemy.new()
	late.ground_pos = AT
	bf.ctx.field.add(late)
	_step(fx, fx.t + 0.3)
	t.check(not fx.pool_open and late.is_alive() and not fx.finished, "at 15.5 s the pool is out: a dummy at the centre lives")
	_step(fx, fx.duration + 0.2)
	t.check(fx.finished, "and the cast ends after its last second")
	FxStage.drop(bf)


static func _level_four(t) -> void:
	var made: Array = _cast(4)
	var bf: Battlefield = made[0]
	var fx = made[1]
	t.check(is_equal_approx(fx.duration, 12.0) and fx.busy < 0.0, "Cinder level 4: 12 s, the slots locked for all of it, as before the twist")
	_step(fx, CinderFx.T_SINK - 0.15)
	var house := bf.ctx.env.add_structure(Rect2(AT + Vector2(2.9, -0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	_step(fx, CinderFx.T_SINK + 0.1)
	fx._volcano.sink = 1.0
	var inside := DummyEnemy.new()
	inside.ground_pos = AT + Vector2(1.0, 0.0)
	bf.ctx.field.add(inside)
	_step(fx, CinderFx.T_SINK + 5.0)
	t.check(not fx.pool_open and inside.is_alive() and is_equal_approx(house.hp, house.max_hp),
		"level 4: no pool, the dummy at 1.0 after the sink lives, the house stands untouched")
	FxStage.drop(bf)
