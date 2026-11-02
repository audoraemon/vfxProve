extends RefCounted
## Dragon level 5 twist, Second Breath (Ruin ability levels, R11): 2.0 s after the first breath ends the dragon breathes again over the
## same arc, back from right to left; the cast stays busy through it and the dragon sinks 0.4 s after the second. Level 1-4 breathe once.

const FxStage := preload("res://tests/fx_stage.gd")
const DragonFx := preload("res://src/fx/set2/dragonfire_parade.gd")
const PATH := "res://src/fx/set2/dragonfire_parade.gd"


## The suites run before the root is in the tree, so the real Impact has no viewport to ask (focus_of) and no post pass to drive: a
## cast that runs past its rise (T_RISE) gets this one, which takes every call and does nothing.
class StubImpact extends Impact:
	func focus_of(_p: Vector2) -> Vector2:
		return Vector2(0.5, 0.5)

	func hitstop(_s: float, _scale := 0.04) -> void:
		pass

	func impact_frame(_s := 0.05, _f := Vector2(0.5, 0.5), _a := Color.WHITE, _b := Color.BLACK) -> void:
		pass

	func aberration(_px: float, _s: float) -> void:
		pass

	func dim(_amount: float, _speed := 1.5) -> void:
		pass


static func _stage(seed_value: int) -> Battlefield:
	var bf := FxStage.make(seed_value)
	bf.ctx.impact = StubImpact.new()
	return bf


static func _drop(bf: Battlefield) -> void:
	var stub := bf.ctx.impact
	bf.ctx.field.clear()
	FxStage.drop(bf)
	stub.free()


## A dummy standing `dist` out from `origin` at `arc_share` (0 = the arc's start, 1 = its far end) of the dragon's arc.
static func _dummy(bf: Battlefield, fx, arc_share: float, dist := 6.0) -> DummyEnemy:
	var e := DummyEnemy.new()
	e.ground_pos = fx.origin + Vector2.RIGHT.rotated(fx._start_angle + fx.lv_sweep_arc * arc_share) * dist
	bf.ctx.field.add(e)
	return e


static func run(t) -> void:
	_level_five(t)
	_level_four(t)


static func _level_five(t) -> void:
	var bf := _stage(5)
	var fx: DragonFx = FxTimeline.cast(load(PATH), bf.ctx, Vector2.ZERO, {"level": 5})
	t.check(is_equal_approx(fx.lv_breath_time, 3.2) and is_equal_approx(fx.lv_t_sink, DragonFx.T_BREATH + 2.0 * 3.2 + DragonFx.SECOND_GAP + 0.4),
		"level 5: a 3.2 s breath twice, 2.0 s apart; the dragon sinks at %.1f" % fx.lv_t_sink)
	t.check(is_equal_approx(fx.duration, 11.5 + (2.0 * 3.2 + 2.0 - 2.4)) and is_equal_approx(fx.duration, 17.5) and fx.busy < 0.0,
		"the cast runs %.1f s and keeps the slots locked the whole time" % fx.duration)
	var early := _dummy(bf, fx, 0.5)
	var late: DummyEnemy = null
	var late_at := DragonFx.T_BREATH + fx.lv_breath_time + 0.5
	var died_in_first := false
	var late_died_at := -1.0
	while fx.t < fx.duration and not fx.finished:
		if late == null and fx.t >= late_at:
			late = _dummy(bf, fx, 0.3)
		fx._process(0.05)
		if not early.is_alive() and late_died_at < 0.0 and fx.breaths == 1:
			died_in_first = true
		if late != null and not late.is_alive() and late_died_at < 0.0:
			late_died_at = fx.t
	t.check(died_in_first and fx.breaths == 2, "level 5: a dummy in the cone dies in the first breath; there are two breaths (%d)" % fx.breaths)
	var second_start := DragonFx.T_BREATH + fx.lv_breath_time + DragonFx.SECOND_GAP
	t.check(late_died_at >= second_start and late_died_at <= second_start + fx.lv_breath_time + 0.1,
		"a dummy placed after the first breath dies during the second (at %.2f, second breath %.2f..%.2f)" % [late_died_at, second_start, second_start + fx.lv_breath_time])
	# It sweeps back: a dummy near the arc's start dies before one near its far end.
	_drop(bf)

	bf = _stage(5)
	fx = FxTimeline.cast(load(PATH), bf.ctx, Vector2.ZERO, {"level": 5})
	var start_side: DummyEnemy = null
	var far_side: DummyEnemy = null
	var start_t := -1.0
	var far_t := -1.0
	var spawned := false
	while fx.t < fx.duration and not fx.finished:
		if not spawned and fx.t >= DragonFx.T_BREATH + fx.lv_breath_time + 0.5:
			spawned = true
			start_side = _dummy(bf, fx, 0.1)
			far_side = _dummy(bf, fx, 0.9)
		fx._process(0.05)
		if spawned and not start_side.is_alive() and start_t < 0.0:
			start_t = fx.t
		if spawned and not far_side.is_alive() and far_t < 0.0:
			far_t = fx.t
	t.check(start_t > 0.0 and far_t > start_t, "the second breath sweeps back: the arc's start burns (%.2f) before its far end (%.2f)" % [start_t, far_t])
	_drop(bf)


static func _level_four(t) -> void:
	var bf := _stage(5)
	var fx: DragonFx = FxTimeline.cast(load(PATH), bf.ctx, Vector2.ZERO, {"level": 4})
	t.check(is_equal_approx(fx.lv_breath_time, 3.0) and is_equal_approx(fx.duration, 11.5 + (3.0 - 2.4)),
		"level 4: a 3.0 s breath, the cast %.2f s" % fx.duration)
	var early := _dummy(bf, fx, 0.5)
	var late: DummyEnemy = null
	while fx.t < fx.duration and not fx.finished:
		if late == null and fx.t >= DragonFx.T_BREATH + fx.lv_breath_time + 0.5:
			late = _dummy(bf, fx, 0.3)
		fx._process(0.05)
	t.check(not early.is_alive() and fx.breaths == 1, "level 4: one breath burns the cone (%d)" % fx.breaths)
	t.check(late != null and late.is_alive() and not fx._back, "level 4: the late dummy lives, nothing breathes back")
	_drop(bf)
