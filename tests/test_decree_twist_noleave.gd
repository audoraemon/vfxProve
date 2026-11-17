extends RefCounted
## noleave level 5 twist (Death and Decree ability levels, Task 12): Held for Trial. When the cell ends, whoever it holds
## and who still stands inside is named criminal for 15 s (LawMark), the god's faithful excepted; the guards hunt them.

const Kit := preload("res://tests/test_decree.gd")
const PATH := "res://src/fx/decree/leaving_is_prohibited.gd"


static func _cast(ctx: FxContext, at: Vector2, level: int) -> NoLeaveFx:
	var fx: NoLeaveFx = FxTimeline.cast(load(PATH), ctx, at, {"level": level})
	fx._process(NoLeaveFx.T_SEAL + 0.05)
	return fx


static func _end(fx: NoLeaveFx) -> void:
	fx._process(fx.lv_hold_time - 0.1)
	fx._lift()


static func run(t) -> void:
	var made: Array = Kit._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var c: Person = crowd.citizens[2]
	var guard: Person = crowd.soldiers[0]
	var rules := Rules.new()
	rules.director = MissionDirector.new()
	ctx.rules = rules

	# Level 4: the twist is off; nobody is named.
	for p: Person in [a, b, c]:
		p.ground_pos = at + Vector2(0.5, 0.0)
	var low := _cast(ctx, at, 4)
	_end(low)
	t.check(low.named.is_empty() and LawMark.kind_of(a) == &"", "noleave level 4: nobody is named at the end")
	low.free()

	# Level 5: 3 inside, 1 faithful -> 2 named criminal for 15.0, the faithful not.
	for p: Person in [a, b, c]:
		p.ground_pos = at + Vector2(0.5, 0.0)
	rules.director.faithful.append(c)
	var fx := _cast(ctx, at, 5)
	_end(fx)
	var span := 0.0
	if a.law != null and a.law.laws.has(fx.get_instance_id()):
		span = float(a.law.laws[fx.get_instance_id()][1])
	t.check(fx.named.size() == 2 and LawMark.kind_of(a) == LawMark.CRIMINAL and LawMark.kind_of(b) == LawMark.CRIMINAL
		and is_equal_approx(span, 15.0) and LawMark.kind_of(c) == &"",
		"noleave level 5: 2 named criminal for 15 s, the faithful not (%d named, %s)" % [fx.named.size(), span])
	# A guard hunts a named one.
	guard.ground_pos = a.ground_pos + Vector2(2.0, 0.0)
	guard.mind = Person.Mind.POST
	a.law._hunt(a)
	t.check(guard.mind == Person.Mind.FIGHT or not a.law.hunters.is_empty(), "a guard hunts one named for trial")
	LawMark.lift(a, fx.get_instance_id())
	LawMark.lift(b, fx.get_instance_id())
	fx.free()

	# One who left before the end is not named.
	rules.director.faithful.clear()
	guard.mind = Person.Mind.CALM
	for p: Person in [a, b]:
		p.ground_pos = at + Vector2(0.5, 0.0)
	var f2 := _cast(ctx, at, 5)
	f2._process(5.0)
	b.ground_pos = at + Vector2(NoLeaveFx.RADIUS + NoLeaveFx.CARRIED + 6.0, 0.0)
	_end(f2)
	t.check(LawMark.kind_of(b) == &"" and not f2.named.has(b) and f2.named.has(a), "noleave level 5: one who left before the end is not named")
	LawMark.lift(a, f2.get_instance_id())
	f2.free()

	# No director: all inside are named.
	ctx.rules = null
	for p: Person in [a, b, c]:
		p.ground_pos = at + Vector2(0.5, 0.0)
	var f3 := _cast(ctx, at, 5)
	_end(f3)
	t.check(f3.named.has(a) and f3.named.has(b) and f3.named.has(c), "noleave level 5: no director, all inside are named (%d)" % f3.named.size())
	f3.free()
	rules.free()
	Kit._done(made)
