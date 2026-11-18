extends RefCounted
## eminent level 5 twist (Death and Decree ability levels, Task 18): Further Claim. For 5.0 s after the first strip is torn down
## a click (Rules.recast -> follow_up) tears a second strip from the first strip's end toward the click, min(6.0, distance) long,
## the first's width and work; one follow-up only, a click under 1.0 from the end refused. A follow-up starts no cooldown and
## sends no cast_made. The second strip ends with its cast (end_now and a freed node), and one cast never ends another's.

const E := preload("res://tests/test_decree_eminent.gd")
const PATH := "res://src/fx/decree/eminent_domain.gd"
## The first strip at level 5 runs from E.FROM along +x, 12 long: its end.
const END := Vector2(29.0, 9.0)
## Ground cleared for the second strips (x 26..32, y 4..20), beside E.CLEAR.
const CLEAR2 := Rect2(26.0, 4.0, 6.0, 16.0)


static func _world() -> Array:
	var made: Array = E._setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	for s in env.structures().duplicate():
		if s.footprint.intersects(E.CLEAR) or s.footprint.intersects(CLEAR2):
			env.remove(s)
	for d in env.decor().duplicate():
		if E.CLEAR.has_point(d.at) or CLEAR2.has_point(d.at):
			env.remove_decor(d)
	return made


static func _house(made: Array, y: float) -> Structure:
	return (made[1] as EnvironmentField).add_structure(Rect2(28.7, y, 0.6, 0.6), 30.0, Structure.Kind.HOUSE, &"house")


static func _cast(made: Array, level: int) -> EminentFx:
	return FxTimeline.cast(load(PATH), made[5], E.FROM, {"level": level, "dir": E.DIR}) as EminentFx


static func _run(fx: FxTimeline, seconds: float) -> void:
	E._run(fx, seconds)


static func run(t) -> void:
	_level4_and_control(t)
	_short_click(t)
	_long_click(t)
	_refusals(t)
	_window(t)
	_rules_route(t)
	await _teardown(t)
	_overlap(t)


static func _end(fx: EminentFx) -> void:
	if is_instance_valid(fx._second):
		fx._second.end_now()
		fx._second.free()
	fx.end_now()
	fx.free()


static func _level4_and_control(t) -> void:
	var made := _world()
	var f4 := _cast(made, 4)
	_run(f4, 1.0)
	var click := f4.to + Vector2(0.0, 4.0)
	t.check(not f4.can_follow_up() and not f4.follow_up(click, {}) and f4._second == null,
		"eminent level 4: no follow-up, no second strip")
	f4.end_now()
	f4.free()
	# Control: the same click at level 5 tears a second strip.
	var f5 := _cast(made, 5)
	t.check(not f5.can_follow_up(), "eminent level 5: no follow-up before the first strip is torn down")
	_run(f5, 1.0)
	t.check(f5.to.is_equal_approx(END) and f5.can_follow_up() and f5.follow_up(click, {}) and f5._second != null,
		"eminent level 5: the same click tears a second strip (control)")
	_end(f5)
	E._done(made)


static func _short_click(t) -> void:
	var made := _world()
	var env: EnvironmentField = made[1]
	var inside := _house(made, 11.0)  # y 11.0..11.6: in a 4-long strip from y 9
	var beyond := _house(made, 14.0)  # past its end
	var fx := _cast(made, 5)
	_run(fx, 1.0)
	t.check(fx.follow_up(END + Vector2(0.0, 4.0), {}), "a click 4 away at 90 degrees is taken")
	var s2: EminentFx = fx._second
	t.check(is_equal_approx(s2.lv_length, 4.0) and s2.origin.is_equal_approx(END) and s2.dir.is_equal_approx(Vector2(0.0, 1.0))
		and is_equal_approx(s2.lv_half_w, fx.lv_half_w) and is_equal_approx(s2.lv_half_w, 1.2) and s2.to.is_equal_approx(END + Vector2(0.0, 4.0)),
		"it tears a 4-long strip from the first strip's end toward the click, the first's width (%s, %s)" % [s2.lv_length, s2.dir])
	_run(s2, 0.7)
	t.check(not E._taken(env, inside), "the second strip is still claimed, nothing falls yet")
	_run(s2, 0.3)
	t.check(E._taken(env, inside) and not E._taken(env, beyond) and not beyond.destroyed and s2.claimed == 1,
		"then it tears down the house in it and leaves the one past its end (%d claimed)" % s2.claimed)
	_run(s2, 3.0)
	t.check(s2.heaps.size() > 0 and not fx.finished and fx.duration >= fx.t, "its rubble lies on its sides and the cast lives until it is done")
	_end(fx)
	E._done(made)


static func _long_click(t) -> void:
	var made := _world()
	var env: EnvironmentField = made[1]
	var inside := _house(made, 14.0)  # y 14.0..14.6: inside 6 long (9..15)
	var beyond := _house(made, 16.2)  # past 6, inside 10
	var fx := _cast(made, 5)
	_run(fx, 1.0)
	t.check(fx.follow_up(END + Vector2(0.0, 10.0), {}) and is_equal_approx(fx._second.lv_length, 6.0),
		"a click 10 away tears a 6-long strip")
	_run(fx._second, 1.4)
	t.check(E._taken(env, inside) and not E._taken(env, beyond), "it reaches 6 along, no farther")
	_end(fx)
	E._done(made)


static func _refusals(t) -> void:
	var made := _world()
	var fx := _cast(made, 5)
	_run(fx, 1.0)
	t.check(not fx.follow_up(END + Vector2(0.5, 0.0), {}) and fx._second == null and fx.can_follow_up(),
		"a click 0.5 away is refused and the follow-up stays")
	t.check(not fx.follow_up(END + Vector2(0.0, 0.99), {}) and fx.follow_up(END + Vector2(0.0, 1.0), {}),
		"under 1.0 is refused, 1.0 is taken (control)")
	t.check(is_equal_approx(fx._second.lv_length, 1.0), "a click 1.0 away tears a 1-long strip")
	var first: EminentFx = fx._second
	t.check(not fx.can_follow_up() and not fx.follow_up(END + Vector2(0.0, 4.0), {}) and fx._second == first,
		"a second follow-up is refused")
	_end(fx)
	E._done(made)


static func _window(t) -> void:
	var made := _world()
	var click := END + Vector2(0.0, 4.0)
	var early := _cast(made, 5)
	_run(early, 5.75)
	t.check(early.follow_up_area() == {"shape": "circle", "r": EminentFx.FOLLOW_MIN}, "while a follow-up can be taken the preview is a small ring, not a lane")
	t.check(early.can_follow_up() and early.follow_up(click, {}), "at 5.75 s (within 5.0 s of the tear) a click is taken (control)")
	_end(early)
	var late := _cast(made, 5)
	_run(late, 5.85)
	t.check(not late.can_follow_up() and not late.follow_up(click, {}) and late._second == null,
		"after 5.0 s from the tear a click is refused")
	t.check(late.follow_up_area().is_empty(), "and the preview is the power's own again")
	_end(late)
	E._done(made)


## The click through a real Rules: recast_made, no cast_made, no new cooldown.
static func _rules_route(t) -> void:
	var made := _world()
	var ctx: FxContext = made[5]
	var rules := Rules.new().setup(PackedStringArray(["eminent", "smite"]), ctx, made[1], made[3], made[0], made[6])
	rules.levels = {"eminent": 5}
	var casts: Array = []
	var recasts: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _at: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): recasts.append([slot, key, p]))
	var fx := rules.cast(0, E.FROM, {"dir": E.DIR}) as EminentFx
	var left := rules.cooldown_left(0)
	var click := END + Vector2(0.0, 4.0)
	t.check(fx != null and left > 0.0 and casts.size() == 1 and not rules.recast(0, click), "Rules.cast starts the cast; before the tear recast is false")
	_run(fx, 1.4)
	t.check(rules.can_recast(0) and rules.recast(0, click) and fx._second != null and is_equal_approx(fx._second.lv_length, 4.0),
		"then recast(slot, at) tears the second strip")
	t.check(recasts == [[0, "eminent", click]] and casts.size() == 1 and rules.cooldown_left(0) <= left and rules.cooldown_left(0) > left - 0.5,
		"it sends recast_made, no second cast_made, and starts no cooldown")
	t.check(not rules.can_recast(0) and not rules.recast(0, click) and recasts.size() == 1, "after it recast is false and sends nothing")
	_end(fx)
	rules.free()
	E._done(made)


static func _teardown(t) -> void:
	# The overhead node joins the tree so a freed cast's _exit_tree fires.
	var made := _world()
	var ctx: FxContext = made[5]
	(t.root as Node).add_child(ctx.overhead)
	await t.process_frame
	var env: EnvironmentField = made[1]
	var click := END + Vector2(0.0, 4.0)
	# Control: left alone, the second strip tears its house.
	var h1 := _house(made, 11.0)
	var f1 := _cast(made, 5)
	_run(f1, 1.0)
	f1.follow_up(click, {})
	_run(f1._second, 1.0)
	t.check(E._taken(env, h1) and not f1._second.finished, "teardown control: a second strip left alone tears its house")
	_end(f1)
	# end_now() ends it before its tear: nothing falls.
	var h2 := _house(made, 11.0)
	var f2 := _cast(made, 5)
	_run(f2, 1.0)
	f2.follow_up(click, {})
	var s2: EminentFx = f2._second
	_run(s2, 0.3)
	f2.end_now()
	_run(s2, 1.5)
	t.check(s2.finished and f2.finished and not E._taken(env, h2) and not h2.destroyed, "end_now ends the second strip before its tear: nothing falls")
	f2.free()
	await t.process_frame
	t.check(not is_instance_valid(s2), "and its node is freed")
	# A freed cast ends it too.
	var h3 := _house(made, 11.0)
	var f3 := _cast(made, 5)
	_run(f3, 1.0)
	f3.follow_up(click, {})
	var s3: EminentFx = f3._second
	_run(s3, 0.3)
	f3.free()
	_run(s3, 1.5)
	t.check(s3.finished and not E._taken(env, h3) and not h3.destroyed, "a freed cast ends the second strip: nothing falls")
	s3.free()
	(t.root as Node).remove_child(ctx.overhead)
	E._done(made)


static func _overlap(t) -> void:
	var made := _world()
	var env: EnvironmentField = made[1]
	var h := _house(made, 11.0)
	var f1 := _cast(made, 5)
	var f2 := _cast(made, 5)
	_run(f1, 1.0)
	_run(f2, 1.0)
	f1.follow_up(END + Vector2(0.0, 4.0), {})
	f2.follow_up(END + Vector2(0.0, 4.0), {})
	var s1: EminentFx = f1._second
	var s2: EminentFx = f2._second
	f1.end_now()
	t.check(s1.finished and not s2.finished and not f2.finished,
		"two casts: ending one ends only its own second strip")
	_run(s2, 1.4)
	t.check(E._taken(env, h), "the other's second strip still tears")
	s1.free()
	f1.free()
	_end(f2)
	E._done(made)
