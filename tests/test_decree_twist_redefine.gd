extends RefCounted
## redefine level 5 twist (Death and Decree ability levels, Task 14): Precedent. Once names are laid, a click (Rules.recast ->
## follow_up) names the living unnamed person nearest it who stands within 2.0 of a named one, with that name for the named
## one's time left; at most 3 copies, none from a click 2.5 away from every named one. A follow-up starts no cooldown and sends
## no cast_made. Copies are this cast's marks: lifted with the rest at SPAN, on end_now() and on free; never another cast's.

const PATH := "res://src/fx/decree/redefine.gd"
const Kit := preload("res://tests/test_decree.gd")
const DT := 0.1


static func _scatter(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1


## A town, its walkable centre, the one to be named `a` (at the centre) and four others `c[0..3]`, placed later (_place) 1.6-1.9
## from it, out of the naming reach of 1.5: [made, ctx, at, a, c].
static func _world() -> Array:
	var made: Array = Kit._setup()
	var crowd: Crowd = made[0]
	_scatter(crowd)
	var at: Vector2 = (made[2] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	a.ground_pos = at
	var c: Array = []
	for i in 4:
		c.append(crowd.citizens[1 + i])
	return [made, made[5], at, a, c]


static func _place(at: Vector2, c: Array) -> void:
	var dirs := [Vector2(1.6, 0.0), Vector2(0.0, 1.7), Vector2(-1.8, 0.0), Vector2(0.0, -1.9)]
	for i in 4:
		(c[i] as Person).ground_pos = at + dirs[i]


static func _cast(ctx: FxContext, at: Vector2, level: int, mode := "criminal") -> RedefineFx:
	return FxTimeline.cast(load(PATH), ctx, at, {"level": level, "mode": mode})


static func _step(fx: RedefineFx, people: Array, seconds: float) -> void:
	for i in int(roundf(seconds / DT)):
		if is_instance_valid(fx):
			fx._process(DT)
		for p: Person in people:
			LawMark.step(p, DT)


static func run(t) -> void:
	_level4_and_control(t)
	_copies(t)
	_reach(t)
	_ends_with_source(t)
	_source_dies(t)
	_rules_route(t)
	await _teardown(t)
	_overlap(t)


static func _level4_and_control(t) -> void:
	var w := _world()
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var a: Person = w[3]
	var c: Array = w[4]
	var f4 := _cast(ctx, at, 4)
	_place(at, c)
	t.check(f4.named == [a] and not f4.can_follow_up() and not f4.follow_up(at, {}) and LawMark.kind_of(c[0]) == &"",
		"redefine level 4: no follow-up, nobody is copied")
	f4.end_now()
	f4.free()
	# Control: the same click at level 5 copies the name.
	var f5 := _cast(ctx, at, 5)
	_place(at, c)
	t.check(f5.can_follow_up() and f5.follow_up(at, {}) and f5.copied == [c[0]] and LawMark.kind_of(c[0]) == &"criminal",
		"redefine level 5: the same click names the nearest unnamed one within 2.0 of a named one (control)")
	f5.end_now()
	f5.free()
	Kit._done(w[0])


static func _copies(t) -> void:
	var w := _world()
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var a: Person = w[3]
	var c: Array = w[4]
	var fx := _cast(ctx, at, 5, "nobody")
	_place(at, c)
	t.check(fx.follow_up(at, {}) and fx.follow_up(at, {}) and fx.can_follow_up() and fx.follow_up(at, {}),
		"redefine level 5: three copies are taken")
	t.check(fx.copied == [c[0], c[1], c[2]] and LawMark.kind_of(c[1]) == &"nobody" and not fx.can_follow_up()
		and not fx.follow_up(at, {}) and fx.copied.size() == 3 and LawMark.kind_of(c[3]) == &"",
		"a fourth is refused and the fourth one carries no name (nearest first)")
	t.check(fx.named == [a], "the named one is untouched")
	fx.end_now()
	fx.free()
	Kit._done(w[0])


static func _reach(t) -> void:
	var w := _world()
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var c: Array = w[4]
	var fx := _cast(ctx, at, 5)
	_place(at, c)
	t.check(not fx.follow_up(at + Vector2(2.5, 0.0), {}) and fx.copied.is_empty() and LawMark.kind_of(c[0]) == &"",
		"a click 2.5 from every named one is refused (a candidate stands 0.9 from the click)")
	t.check(fx.follow_up(at + Vector2(1.9, 0.0), {}) and fx.copied == [c[0]],
		"control: a click 1.9 from the named one is taken")
	# Someone out of reach of every named one is never named, however near the click.
	(c[3] as Person).ground_pos = at + Vector2(0.0, -2.3)
	t.check(fx.follow_up(at + Vector2(0.0, -1.6), {}) and not fx.copied.has(c[3]),
		"one 2.3 from the named one is not copied (another within reach is)")
	fx.end_now()
	fx.free()
	Kit._done(w[0])


static func _ends_with_source(t) -> void:
	var w := _world()
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var a: Person = w[3]
	var c: Array = w[4]
	var fx := _cast(ctx, at, 5)
	_place(at, c)
	var span := fx.lv_span
	var people := [a, c[0]]
	_step(fx, people, 10.0)
	t.check(fx.follow_up(at, {}), "redefine level 5: a copy is taken at 10 s")
	var src_left := float(a.law.laws[fx.get_instance_id()][1])
	var copy_left := float((c[0] as Person).law.laws[fx.get_instance_id()][1])
	t.check(is_equal_approx(src_left, copy_left) and absf(copy_left - (span - 10.0)) < 0.2,
		"the copy has the source name's time left (%.2f / %.2f)" % [copy_left, src_left])
	_step(fx, people, src_left - 0.3)
	t.check(LawMark.wanted(c[0]) and LawMark.wanted(a) and not fx.lifted, "both still CRIMINAL just before the end")
	_step(fx, people, 0.5)
	t.check(not LawMark.wanted(c[0]) and not LawMark.wanted(a) and fx.lifted, "the copy ends with its source")
	t.check(not fx.can_follow_up() and not fx.follow_up(at, {}), "no follow-up once the names are lifted")
	fx.free()
	Kit._done(w[0])


static func _source_dies(t) -> void:
	var w := _world()
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var a: Person = w[3]
	var c: Array = w[4]
	var fx := _cast(ctx, at, 5)
	_place(at, c)
	_step(fx, [a], 3.0)
	t.check(fx.follow_up(at, {}), "a copy is taken")
	a.die(&"test")
	_step(fx, [c[0]], 2.0)
	t.check(not a.is_alive() and LawMark.wanted(c[0]) and fx.copied == [c[0]],
		"the named one dies mid-span: the copy stays valid")
	t.check(not fx.follow_up(at, {}), "a dead named one is no source for another copy")
	fx.end_now()
	t.check(LawMark.kind_of(c[0]) == &"", "and it is lifted when the cast ends")
	fx.free()
	Kit._done(w[0])


## The click through a real Rules: recast_made, no cast_made, no new cooldown.
static func _rules_route(t) -> void:
	var w := _world()
	var made: Array = w[0]
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var c: Array = w[4]
	var rules := Rules.new().setup(PackedStringArray(["redefine", "smite"]), ctx, made[1], made[3], made[0], made[6])
	rules.levels = {"redefine": 5}
	var casts: Array = []
	var recasts: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _at: Vector2): casts.append([slot, key]))
	rules.recast_made.connect(func(slot: int, key: String, p: Vector2): recasts.append([slot, key, p]))
	var fx := rules.cast(0, at, {"mode": "criminal"}) as RedefineFx
	_place(at, c)
	var left := rules.cooldown_left(0)
	t.check(fx != null and left > 0.0 and casts.size() == 1 and not rules.recast(0, at),
		"Rules.cast starts the cast; while it writes, recast is false")
	fx._process(RedefineFx.WRITE + 0.05)
	t.check(rules.can_recast(0) and rules.recast(0, at) and fx.copied == [c[0]], "then recast(slot, at) copies the name")
	t.check(recasts == [[0, "redefine", at]] and casts.size() == 1 and is_equal_approx(rules.cooldown_left(0), left),
		"it sends recast_made, no second cast_made, and starts no cooldown")
	rules.recast(0, at)
	rules.recast(0, at)
	t.check(not rules.can_recast(0) and not rules.recast(0, at) and recasts.size() == 3 and casts.size() == 1,
		"after 3 copies recast is false and sends nothing")
	fx.end_now()
	fx.free()
	rules.free()
	Kit._done(made)


static func _teardown(t) -> void:
	# The overhead node joins the tree so a freed cast's _exit_tree fires.
	# end_now() and a freed node both lift the copies; another owner's law stays.
	var w := _world()
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var c: Array = w[4]
	(t.root as Node).add_child(ctx.overhead)
	await t.process_frame
	var f1 := _cast(ctx, at, 5)
	_place(at, c)
	f1.follow_up(at, {})
	LawMark.set_law(c[0], LawMark.NOBODY, 20.0, 99)
	LawMark.set_law(c[0], LawMark.CRIMINAL, 20.0, f1.get_instance_id())
	t.check(LawMark.kind_of(c[0]) == &"criminal", "teardown control: the copy is CRIMINAL before the cast ends")
	f1.end_now()
	t.check(LawMark.kind_of(c[0]) == &"nobody" and (c[0] as Person).law.laws.has(99),
		"end_now lifts the copy; another owner's law stays")
	f1.free()
	LawMark.lift(c[0], 99)
	var f2 := _cast(ctx, at, 5)
	f2.follow_up(at, {})
	t.check(LawMark.wanted(c[0]), "teardown control: a second cast's copy holds")
	f2.free()
	t.check(not is_instance_valid(f2) and LawMark.kind_of(c[0]) == &"", "a freed cast lifts its copy too")
	(t.root as Node).remove_child(ctx.overhead)
	Kit._done(w[0])


static func _overlap(t) -> void:
	var w := _world()
	var ctx: FxContext = w[1]
	var at: Vector2 = w[2]
	var a: Person = w[3]
	var c: Array = w[4]
	var f1 := _cast(ctx, at, 5)
	_place(at, c)
	t.check(f1.follow_up(at, {}), "overlap: the first cast copies")
	# A second cast names `a` too, and copies another.
	var f2 := _cast(ctx, at, 5, "officer")
	t.check(f2.named.has(a) and f2.follow_up(at + Vector2(0.0, 1.7), {}) and f2.copied.size() == 1 and f2.copied[0] != f1.copied[0],
		"overlap: the second cast copies a different one")
	var second: Person = f2.copied[0]
	var first: Person = f1.copied[0]
	f1.end_now()
	t.check(LawMark.kind_of(first) == &"" and LawMark.kind_of(second) == &"officer" and LawMark.kind_of(a) == &"officer",
		"ending the first lifts only its own marks")
	f2.end_now()
	t.check(LawMark.kind_of(second) == &"" and LawMark.kind_of(a) == &"", "and the second its own")
	f1.free()
	f2.free()
	Kit._done(w[0])
