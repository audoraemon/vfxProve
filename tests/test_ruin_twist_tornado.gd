extends RefCounted
## Tornado level 5, Twin Funnels (Ruin ability levels, Task 4): when it dissipates it leaves two small funnels that run apart for 4 s,
## each pulling only within 1.8 of itself, catching at its core, flinging as the parent does.

const FxStage := preload("res://tests/fx_stage.gd")
const TORNADO := preload("res://src/fx/set2/tornado_tempest.gd")
const STEP := 0.05


static func run(t) -> void:
	_pull_near(t)
	_twins(t)
	_level_four(t)


## A DummyEnemy on `field` at `at`.
static func _dummy(field: EnemyField, at: Vector2) -> DummyEnemy:
	var e := DummyEnemy.new()
	e.ground_pos = at
	field.add(e)
	return e


static func _pull_near(t) -> void:
	var field := EnemyField.new()
	field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	var far := _dummy(field, Vector2(20.0, 0.0))
	var near := _dummy(field, Vector2(1.5, 0.0))
	var out := _dummy(field, Vector2(2.5, 0.0))
	far.pull_step(Vector2(10.0, 0.0), 3.0, 0.0, 0.1)  # in another funnel's grip
	var far_at := far.ground_pos
	field.pull_near(Vector2.ZERO, 1.8, 3.0, 0.0, 0.1)
	t.check(far.ground_pos == far_at and far.state == DummyEnemy.State.PULLED, "pull_near leaves an enemy PULLED elsewhere where it is")
	t.check(near.state == DummyEnemy.State.PULLED and near.ground_pos.x < 1.5, "pull_near draws one 1.5 away toward the centre (%s)" % near.ground_pos)
	t.check(out.state != DummyEnemy.State.PULLED and out.ground_pos == Vector2(2.5, 0.0), "and leaves one 2.5 away alone")
	# pull() still steps every PULLED enemy wherever it is (level 1 is untouched).
	field.pull(Vector2.ZERO, 1.8, 3.0, 0.0, 0.1)
	t.check(far.ground_pos != far_at, "pull() is unchanged: it still steps an enemy PULLED anywhere")
	field.clear()
	field.free()


## Step the effect to `time` in STEP strides.
static func _run_to(fx: FxTimeline, time: float) -> void:
	while fx.t < time - 0.0001:
		fx._process(minf(STEP, time - fx.t))


static func _twins(t) -> void:
	var bf := FxStage.make(11)
	var killed: Array = []
	bf.ctx.field.enemy_killed.connect(func(e: DummyEnemy, kind: StringName) -> void: killed.append([e, kind]))
	var fx = FxTimeline.cast(TORNADO, bf.ctx, Vector2.ZERO, {"level": 5})
	t.check(is_equal_approx(fx.duration, fx.lv_t_end + maxf(2.8, TORNADO.TWIN_LIFE + 0.6)) and fx.twins.is_empty(),
		"level 5: the cast lasts TWIN_LIFE + 0.6 past the death, no twin yet (duration %.2f)" % fx.duration)
	_run_to(fx, fx.lv_t_end - 0.1)
	t.check(fx.twins.is_empty(), "alive, no twin")
	_run_to(fx, fx.lv_t_end + 0.1)
	t.check(fx.twins.size() == 2, "dead: two twins (%d)" % fx.twins.size())
	var a = fx.twins[0]
	var b = fx.twins[1]
	var gap0: float = a.center.distance_to(b.center)
	# Dummies on the line the parent died heading along, 1.5 and 2.5 from where the twins stand now.
	var dir: Vector2 = Vector2.from_angle(fx._heading)
	var mid: Vector2 = (a.center + b.center) * 0.5
	var pulled := _dummy(bf.ctx.field, mid + dir * 1.5)
	var idle := _dummy(bf.ctx.field, mid - dir * 2.5)
	var idle_at := idle.ground_pos
	_run_to(fx, fx.t + 1.0)
	var gap1: float = a.center.distance_to(b.center)
	t.check(gap1 > gap0 + 2.0, "the twins run apart (%.2f -> %.2f in 1 s)" % [gap0, gap1])
	t.check(pulled.state == DummyEnemy.State.PULLED or not pulled.is_alive(), "one 1.5 from a twin is pulled in")
	t.check(idle.state != DummyEnemy.State.PULLED and idle.ground_pos == idle_at, "one 2.5 away is not")
	_run_to(fx, fx.t + 0.5)
	gap1 = a.center.distance_to(b.center)
	t.check(gap1 > 2.0, "and the twins are more than 2 apart after 1.5 s (%.2f)" % gap1)
	# A dummy dropped on a twin's core is caught and flung (wind) within CAPTURE_TIME + 0.2.
	var prey := _dummy(bf.ctx.field, a.center)
	var t0: float = fx.t
	while prey.is_alive() and fx.t < t0 + TORNADO.CAPTURE_TIME + 0.2:
		fx._process(STEP)
	var kind := &""
	for k in killed:
		if k[0] == prey:
			kind = k[1]
	t.check(not prey.is_alive() and kind == &"wind", "a dummy at a twin's core dies of wind within CAPTURE_TIME + 0.2 (%.2f s, %s)" % [fx.t - t0, kind])
	# The end: no twin left, nobody PULLED.
	_run_to(fx, fx.lv_t_end + 4.2)
	var stuck := 0
	for e in bf.ctx.field.alive():
		if e.state == DummyEnemy.State.PULLED:
			stuck += 1
	t.check(fx.twins.is_empty() and stuck == 0, "at lv_t_end + 4.2 no twin is left and no enemy is PULLED (%d twins, %d pulled)" % [fx.twins.size(), stuck])
	fx._process(10.0)
	FxStage.drop(bf)


static func _level_four(t) -> void:
	var bf := FxStage.make(11)
	var fx = FxTimeline.cast(TORNADO, bf.ctx, Vector2.ZERO, {"level": 4})
	t.check(is_equal_approx(fx.duration, fx.lv_t_end + 2.8), "level 4: duration is lv_t_end + 2.8")
	_run_to(fx, fx.lv_t_end + 0.5)
	t.check(fx.twins.is_empty() and fx.t > fx.lv_t_end, "level 4: no twins after it dies")
	fx._process(10.0)
	FxStage.drop(bf)
	# The twist draws nothing from the cast's rng: splitting, and the twins' whole life, leave its state alone.
	bf = FxStage.make(11)
	fx = FxTimeline.cast(TORNADO, bf.ctx, Vector2.ZERO, {"level": 5})
	var state: int = bf.ctx.rng.state
	fx._split()
	t.check(fx.twins.size() == 2 and bf.ctx.rng.state == state, "splitting draws no random number from the cast's rng")
	for i in 100:
		fx._twins_step(STEP)
	t.check(fx.twins.is_empty() and bf.ctx.rng.state == state, "nor does the twins' life (they are gone after 4 s)")
	fx._process(10.0)
	FxStage.drop(bf)
