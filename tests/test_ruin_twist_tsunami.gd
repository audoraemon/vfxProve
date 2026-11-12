extends RefCounted
## Tsunami level 5 twist, Backwash (Ruin ability levels, R12 and R12a): 0.2 s after the crash the water draws back over 2.4 s from
## 5.0 beyond the lane's end (the splash ring the crash only knocked) to its start, and 1.5 wider each side than the lane; whoever is
## alive, in the open and in that reach behind the receding edge is carried with it and set down at the start, knocked clear. It kills
## no one and hits no building. Level 1-4 leave whoever is there where they stand.

const FxStage := preload("res://tests/fx_stage.gd")
const TsunamiFx := preload("res://src/fx/set2/tsunami_breaker.gd")
const PATH := "res://src/fx/set2/tsunami_breaker.gd"
const AT := Vector2(-12.0, 0.0)


static func _stage(seed_value: int) -> Battlefield:
	return FxStage.make(seed_value)


static func _drop(bf: Battlefield) -> void:
	bf.ctx.field.clear()
	bf.ctx.env.clear()
	FxStage.drop(bf)


static func _dummy(bf: Battlefield, along: float, side: float) -> DummyEnemy:
	var e := DummyEnemy.new()
	e.ground_pos = AT + Vector2(along, side)
	bf.ctx.field.add(e)
	return e


## Step the cast to time `to` in 0.05 s ticks.
static func _run_to(fx: FxTimeline, to: float) -> void:
	while fx.t < to - 0.0001 and not fx.finished:
		fx._process(minf(0.05, to - fx.t))


static func run(t) -> void:
	_level_five(t)
	_level_four(t)
	_reach(t, 5)
	_reach(t, 4)


## Everything the check needs, in one run: two people in the lane (5.0 and 2.0 along), one outside it, a house in the lane.
static func _scene(level: int) -> Array:
	var bf := _stage(3)
	var fx: FxTimeline = FxTimeline.cast(load(PATH), bf.ctx, AT, {"level": level, "dir": Vector2(1, 0)})
	_run_to(fx, TsunamiFx.T_CRASH + 0.05)  # the wave has crashed; the lane is empty of the living
	var far := _dummy(bf, 5.0, 0.5)
	var near := _dummy(bf, 2.0, -1.0)
	var outsider := _dummy(bf, 4.0, fx.lv_width * 0.5 + TsunamiFx.BACKWASH_SIDE + 1.0)
	var house := bf.ctx.env.add_structure(Rect2(AT + Vector2(3.5, 2.0), Vector2(0.8, 0.8)), 20.0, Structure.Kind.HOUSE, &"house")
	return [bf, fx, far, near, outsider, house]


static func _level_five(t) -> void:
	var sc := _scene(5)
	var bf: Battlefield = sc[0]
	var fx: TsunamiFx = sc[1]
	var far: DummyEnemy = sc[2]
	var near: DummyEnemy = sc[3]
	var outsider: DummyEnemy = sc[4]
	var house: Structure = sc[5]
	var outsider_at := outsider.ground_pos
	var hp := house.hp
	t.check(is_equal_approx(fx.lv_length, 8.5) and fx.duration == 9.5, "level 5: the wave runs 8.5 and the cast still lasts 9.5 s")
	_run_to(fx, TsunamiFx.T_CRASH + 1.8)
	t.check(fx._backwashing and far.state == DummyEnemy.State.PULLED and (far.ground_pos - AT).x < 5.2 and near.state != DummyEnemy.State.PULLED,
		"mid-backwash the receding edge has caught the far person and is drawing them back (%.2f along), not yet the near one" % (far.ground_pos - AT).x)
	_run_to(fx, TsunamiFx.T_CRASH + 2.3)
	t.check(near.state == DummyEnemy.State.PULLED and absf((near.ground_pos - AT).x - (fx._back_front - 0.25)) < 0.5,
		"and then the near one, riding just inside the edge (%.2f along, edge %.2f)" % [(near.ground_pos - AT).x, fx._back_front])
	t.check(outsider.ground_pos == outsider_at and outsider.state != DummyEnemy.State.PULLED, "the one outside the lane is not touched")
	_run_to(fx, TsunamiFx.T_CRASH + 2.7)
	t.check(far.is_alive() and near.is_alive(), "at the crash + 2.7 s both lane people are alive: the backwash does not kill")
	t.check(absf((far.ground_pos - AT).x) <= 0.5 and absf((near.ground_pos - AT).x) <= 0.5,
		"and both stand within 0.5 of the lane's start line (%.2f, %.2f)" % [(far.ground_pos - AT).x, (near.ground_pos - AT).x])
	t.check(far.state == DummyEnemy.State.KNOCKBACK and near.state == DummyEnemy.State.KNOCKBACK and not fx._backwashing,
		"they are knocked back off the start, and the backwash is over")
	t.check(absf((far.ground_pos - AT).y - 0.5) < 0.3 and absf((near.ground_pos - AT).y + 1.0) < 0.3, "each is put down on their own side of the lane")
	t.check(outsider.ground_pos == outsider_at and outsider.is_alive(), "the outsider has not moved")
	t.check(house.hp == hp and not house.destroyed, "no building took damage during the backwash (hp %.0f)" % house.hp)
	_drop(bf)


static func _level_four(t) -> void:
	var sc := _scene(4)
	var bf: Battlefield = sc[0]
	var fx: TsunamiFx = sc[1]
	var far: DummyEnemy = sc[2]
	var near: DummyEnemy = sc[3]
	var outsider: DummyEnemy = sc[4]
	var far_at := far.ground_pos
	var near_at := near.ground_pos
	var outsider_at := outsider.ground_pos
	_run_to(fx, TsunamiFx.T_CRASH + 2.7)
	t.check(not fx._backwashing and fx._dragged.is_empty() and far.ground_pos == far_at and near.ground_pos == near_at
		and outsider.ground_pos == outsider_at and far.state == DummyEnemy.State.WANDER and near.state == DummyEnemy.State.WANDER,
		"level 4: nobody moves")
	_drop(bf)


## The twist where it matters (R12a): the crash kills its own lane, so the drag reaches those the wave only knocked. People stand in
## place before the cast runs: one 4.0 beyond the crash point (in the splash ring) and one 1.0 outside the lane's side, along the lane.
## At level 5 both live through the crash and end within 0.5 of the start line; at level 4 neither is dragged.
static func _reach(t, level: int) -> void:
	var bf := _stage(3)
	var fx: FxTimeline = FxTimeline.cast(load(PATH), bf.ctx, AT, {"level": level, "dir": Vector2(1, 0)})
	var ring := _dummy(bf, fx.lv_length + 4.0, 0.5)
	var flank := _dummy(bf, 3.0, fx.lv_width * 0.5 + 1.0)
	var flank_at := flank.ground_pos
	_run_to(fx, TsunamiFx.T_CRASH + 0.15)
	t.check(ring.is_alive() and flank.is_alive(), "level %d: both survive the crash (the ring is knocked, the flank is outside the sweep)" % level)
	if level == 5:
		_run_to(fx, TsunamiFx.T_CRASH + 2.7)
		t.check(ring.is_alive() and flank.is_alive() and not fx._backwashing, "level 5: the backwash has come and gone and killed no one")
		t.check(absf((ring.ground_pos - AT).x) <= 0.5 and absf((flank.ground_pos - AT).x) <= 0.5,
			"and both stand within 0.5 of the start line (%.2f, %.2f)" % [(ring.ground_pos - AT).x, (flank.ground_pos - AT).x])
		t.check(ring.state == DummyEnemy.State.KNOCKBACK and flank.state == DummyEnemy.State.KNOCKBACK, "knocked back off the start")
		t.check(fx._front <= fx.lv_length + 0.0001, "the flood and its light never overshoot the lane (front %.2f)" % fx._front)
	else:
		_run_to(fx, TsunamiFx.T_CRASH + 2.7)
		t.check(fx._dragged.is_empty() and flank.ground_pos == flank_at and (ring.ground_pos - AT).x > fx.lv_length,
			"level 4: nobody is dragged (flank %.2f along, ring %.2f)" % [(flank.ground_pos - AT).x, (ring.ground_pos - AT).x])
	_drop(bf)
