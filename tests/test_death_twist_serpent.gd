extends RefCounted
## The Pale Serpent, level 5 twist -- Shed ShedSkin (Death and Decree ability levels, Task 10; DL10): as it departs it leaves its
## skin along the whole path (the drag and the loop) for 30 s, a band 0.5 either side of points laid STEP apart. A person who
## steps onto it out in the open is sickened once (SICK_PACE for lv_sick, under the cast's own id, and the plague when it is in
## town); a person 0.6 off it is untouched; the band is gone at 30.0 s. One node, one disc per point, drawn once.

const RD := preload("res://tests/test_raise_dead.gd")
const SP := preload("res://tests/test_serpent.gd")
const FxStage := preload("res://tests/fx_stage.gd")
const DT := 0.05


static func _cast(made: Array, at: Vector2, level: int) -> PaleSerpentFx:
	return FxTimeline.cast(PaleSerpentFx, made[5], at, {"level": level, "dir": Vector2.RIGHT, "to": at + Vector2(16.0, 0.0)}) as PaleSerpentFx


## Run the cast's clock to `time` (the effect's own seconds).
static func _to(fx: PaleSerpentFx, time: float) -> void:
	RD._run(fx, time - fx.t)


## A point of the loop, well out of the serpent's sight (the far side of the loop from the press).
static func _far(fx: PaleSerpentFx) -> Vector2:
	return fx.path_at(fx._len + PI * PaleSerpentFx.CIRCLE_R)


static func run(t) -> void:
	var made := RD._setup()
	_band(t, made)
	_once(t, made)
	_gone(t, made)
	_plague(t, made)
	_level_four(t, made)
	_teardown(t, made)
	_overlap(t, made)
	await _staged(t, made)
	RD._done(made)


## A person put on the band 5 s after the departure is slowed for lv_sick; one 0.6 off it, indoors, or guised is not.
static func _band(t, made: Array) -> void:
	SP._reset(made)
	var at := RD._empty(made)
	var a := SP._put(made, 0, Vector2(-27.0, -27.0))
	var off := SP._put(made, 1, Vector2(-26.0, -27.0))
	var indoor := SP._put(made, 2, Vector2(-25.0, -27.0))
	var guised := SP._put(made, 3, Vector2(-24.0, -27.0))
	var fx := _cast(made, at, 5)
	var g := _far(fx) 
	_to(fx, PaleSerpentFx.glide_end() + 5.0)
	t.check(is_equal_approx(fx.lv_sick, 24.0) and a.pace_hold() == 1.0, "level 5: nobody was near it (lv_sick %.1f)" % fx.lv_sick)
	a.ground_pos = g
	off.ground_pos = g + Vector2(0.0, 0.6)
	indoor.ground_pos = g + Vector2(0.25, 0.0)
	indoor.inside = true
	guised.ground_pos = g + Vector2(-0.25, 0.0)
	guised.statuses[&"guise"] = 120.0
	RD._run(fx, 0.3)
	t.check(is_equal_approx(a.pace_hold(), PaleSerpentFx.SICK_PACE) and fx._skin_once.size() == 1,
		"a person on the skin 5 s after the departure walks at 0.6 (%.2f)" % a.pace_hold())
	t.check(off.pace_hold() == 1.0, "a person 0.6 off it is untouched (%.2f)" % off.pace_hold())
	t.check(indoor.pace_hold() == 1.0 and guised.pace_hold() == 1.0, "nor one indoors or guised")
	t.check(a.sick_left == 0.0, "no plague in town: no plague caught")
	fx.end_now()
	t.check(a.pace_hold() == 1.0, "(let go at the end)")


## Standing on the band the whole while: sickened once, let go lv_sick (24 s) later, not sickened again by the same band.
static func _once(t, made: Array) -> void:
	SP._reset(made)
	var at := RD._empty(made)
	var a := SP._put(made, 0, Vector2(-27.0, -27.0))
	var fx := _cast(made, at, 5)
	_to(fx, PaleSerpentFx.glide_end() + 5.0)
	a.ground_pos = _far(fx)
	RD._run(fx, 0.3)
	var from := fx.t
	t.check(a.pace_hold() < 1.0, "(sickened)")
	_to(fx, from + 12.0)
	a.ground_pos = Vector2(-27.0, -27.0)
	RD._run(fx, 0.3)
	a.ground_pos = _far(fx)  # steps on it again
	RD._run(fx, 0.3)
	t.check(fx._skin_once.size() == 1 and is_equal_approx(a.pace_hold(), PaleSerpentFx.SICK_PACE), "stepping on it again adds nothing (%d sickened)" % fx._skin_once.size())
	_to(fx, from + 24.4)
	t.check(fx.t < PaleSerpentFx.glide_end() + 30.0 and a.pace_hold() == 1.0 and fx._skin_once.size() == 1,
		"let go lv_sick after the first step, and not sickened again though still on the band (%.2f, %d)" % [a.pace_hold(), fx._skin_once.size()])
	fx.end_now()


## Gone at 30.0 s: one who steps on at 29.5 s is sickened, one at 30.1 s is not; the cast ends after the last hold.
static func _gone(t, made: Array) -> void:
	SP._reset(made)
	var at := RD._empty(made)
	var early := SP._put(made, 0, Vector2(-27.0, -27.0))
	var late := SP._put(made, 1, Vector2(-26.0, -27.0))
	var fx := _cast(made, at, 5)
	var born := PaleSerpentFx.glide_end()
	_to(fx, born + 29.5)
	early.ground_pos = _far(fx)
	RD._run(fx, 0.3)
	t.check(early.pace_hold() < 1.0 and not fx.finished, "at 29.5 s the band still sickens")
	_to(fx, born + 30.1)
	late.ground_pos = _far(fx)
	RD._run(fx, 0.3)
	t.check(late.pace_hold() == 1.0 and fx._skin_once.size() == 1, "at 30.1 s the band is gone (%.2f)" % late.pace_hold())
	_to(fx, born + 29.5 + fx.lv_sick + 0.5)
	t.check(early.pace_hold() == 1.0 and fx.finished, "the last sick is let go and the cast is over (%.2f)" % early.pace_hold())


## With the plague in town the band's victim catches it too.
static func _plague(t, made: Array) -> void:
	SP._reset(made)
	var at := RD._empty(made)
	var a := SP._put(made, 0, Vector2(-27.0, -27.0))
	var ill := SP._put(made, 1, Vector2(-20.0, -27.0))
	ill.sick_left = 30.0
	var fx := _cast(made, at, 5)
	_to(fx, PaleSerpentFx.glide_end() + 5.0)
	a.ground_pos = _far(fx)
	RD._run(fx, 0.3)
	t.check(is_equal_approx(a.sick_left, PlagueManager.PLAGUE_LIFE) and a.pace_hold() < 1.0, "with the plague in town the band sickens and plagues (%.1f)" % a.sick_left)
	ill.sick_left = 0.0
	a.sick_left = 0.0
	fx.end_now()


## Level 4: no skin -- the same person on the same point is not slowed and the cast is over by its old end.
static func _level_four(t, made: Array) -> void:
	SP._reset(made)
	var at := RD._empty(made)
	var a := SP._put(made, 0, Vector2(-27.0, -27.0))
	var fx := _cast(made, at, 4)
	var g := _far(fx)
	_to(fx, PaleSerpentFx.glide_end() + 0.5)
	a.ground_pos = g
	RD._run(fx, 0.3)
	t.check(a.pace_hold() == 1.0 and fx._skin_pts.is_empty() and fx._skin_once.is_empty(), "level 4: no skin is shed (%.2f)" % a.pace_hold())
	t.check(not fx.finished, "(level 4: the sight's slow still runs)")
	_to(fx, PaleSerpentFx.T_RISE + fx.lv_sick + 0.2)
	t.check(fx.finished, "level 4: the cast ends at its old end (%.2f s)" % fx.t)


## Freed early (end_now, then a freed node), a sick person walks free and the band takes no more.
static func _teardown(t, made: Array) -> void:
	for mode in 2:
		SP._reset(made)
		var at := RD._empty(made)
		var a := SP._put(made, 0, Vector2(-27.0, -27.0))
		var b := SP._put(made, 1, Vector2(-26.0, -27.0))
		var fx := _cast(made, at, 5)
		_to(fx, PaleSerpentFx.glide_end() + 3.0)
		a.ground_pos = _far(fx)
		RD._run(fx, 0.3)
		var held := a.pace_hold() < 1.0
		var name := "end_now" if mode == 0 else "freed"
		if mode == 0:
			fx.end_now()
		else:
			fx._exit_tree()
			fx.free()
		t.check(held and a.pace_hold() == 1.0 and a.pace_holds.is_empty(), "%s: the sick person walks free (%.2f)" % [name, a.pace_hold()])
		if mode == 0:
			b.ground_pos = _far(fx)
			RD._run(fx, 0.3)
			t.check(b.pace_hold() == 1.0 and fx._skin_held.is_empty(), "%s: the band sickens no one after" % name)


## Two casts at once: one ending early leaves the other's hold on the same person.
static func _overlap(t, made: Array) -> void:
	SP._reset(made)
	var at := RD._empty(made)
	var a := SP._put(made, 0, Vector2(-27.0, -27.0))
	var one := _cast(made, at, 5)
	var two := _cast(made, at, 5)
	_to(one, PaleSerpentFx.glide_end() + 3.0)
	_to(two, PaleSerpentFx.glide_end() + 3.0)
	a.ground_pos = _far(one)
	RD._run(one, 0.3)
	RD._run(two, 0.3)
	t.check(a.pace_holds.size() == 2 and a.pace_hold() < 1.0, "two casts' bands: two holds on the one person (%d)" % a.pace_holds.size())
	one.end_now()
	t.check(a.pace_holds.size() == 1 and is_equal_approx(a.pace_hold(), PaleSerpentFx.SICK_PACE), "one ended: the other's hold stays (%.2f)" % a.pace_hold())
	two.end_now()
	t.check(a.pace_hold() == 1.0, "both ended: free")


## Staged: one skin node of one disc per point, faded over the last 3 s, gone at 30 s, and none left cut short or freed.
static func _staged(t, made: Array) -> void:
	var ctx: FxContext = made[5]
	var keep := [ctx.overhead, ctx.ground, ctx.overhead_back]
	var stage := Node2D.new()
	t.root.add_child(stage)
	await t.process_frame
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.overhead_back = Node2D.new()
	for n in [ctx.ground, ctx.overhead_back, ctx.overhead]:
		stage.add_child(n)
	var stub := FxStage.StageImpact.new()
	ctx.impact = stub
	var out := {"nodes": 0, "pts": 0, "want": 0, "faded": false, "full": false, "gone": false, "four": 0}
	var left := {}
	for how in 4:
		SP._reset(made)
		var at := RD._empty(made)
		var fx := _cast(made, at, 4 if how == 3 else 5)
		_to(fx, PaleSerpentFx.glide_end() + 1.0)
		var nodes := _skins(ctx)
		if how == 3:
			out.four = nodes.size()
			fx.end_now()
			continue
		if how == 0:
			out.nodes = nodes.size()
			if not nodes.is_empty():
				out.pts = (nodes[0] as PaleSerpentFx.ShedSkin).pts.size()
				out.want = ceili((fx._len + TAU * PaleSerpentFx.CIRCLE_R) / PaleSerpentFx.STEP) + 1
				out.full = is_equal_approx((nodes[0] as PaleSerpentFx.ShedSkin).modulate.a, 1.0)
			_to(fx, PaleSerpentFx.glide_end() + 28.5)
			nodes = _skins(ctx)
			out.faded = not nodes.is_empty() and (nodes[0] as PaleSerpentFx.ShedSkin).modulate.a < 0.6
			_to(fx, PaleSerpentFx.glide_end() + 30.2)
			out.gone = fx._skin_node == null
			fx.end_now()
		elif how == 1:
			fx.end_now()
		else:
			fx._exit_tree()
			fx.free()
		await t.process_frame
		left[how] = _skins(ctx).size()
	await t.process_frame
	ctx.impact = null
	stub.free()
	ctx.overhead = keep[0]
	ctx.ground = keep[1]
	ctx.overhead_back = keep[2]
	t.root.remove_child(stage)
	stage.free()
	t.check(int(out.nodes) == 1 and int(out.pts) == int(out.want) and bool(out.full),
		"staged: the skin is one node, one disc per point (%d nodes, %d of %d points)" % [out.nodes, out.pts, out.want])
	t.check(bool(out.faded) and bool(out.gone), "staged: it fades over its last 3 s and is gone at 30 s")
	t.check(int(out.four) == 0, "staged level 4: no skin node")
	t.check(int(left[0]) == 0 and int(left[1]) == 0 and int(left[2]) == 0,
		"staged: no skin node left after the natural end, end_now or a freed cast (%s)" % [left])


static func _skins(ctx: FxContext) -> Array:
	return ctx.ground.get_children().filter(func(n: Node) -> bool: return n is PaleSerpentFx.ShedSkin and not n.is_queued_for_deletion())
