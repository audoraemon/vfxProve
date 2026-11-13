extends RefCounted
## Erasing Distance (Decree, Tier III; spec 5.5): a dragged line whose distance is erased. A gilt seam runs down it, the
## fold pulls whoever stands within CRUSH_W to its middle and crushes them (kill kind crushed), every building it crosses
## falls and those within CRACK_W crack; the spring back throws whoever stands within THROW_W outward and down; law
## rubble lies in kinked heaps along it, closing the walk grid. All by distance: no rolls.

const PATH := "res://src/fx/decree/erasing_distance.gd"
const DT := 0.05
## Open ground west of the town (nothing stands within 5 of it): the line runs from FROM along +y, LEN long.
const FROM := Vector2(-24.0, -3.0)
const DIR := Vector2(0.0, 1.0)
const LEN := 6.0


static func _setup() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.PREPARED)
	crowd.spawn()
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## `seconds` of the effect's frames, DT at a time.
static func _run(fx: FxTimeline, seconds: float) -> void:
	for i in int(roundf(seconds / DT)):
		fx._process(DT)


static func run(t) -> void:
	var b := PowerBook.get_power("erase")
	var area: Dictionary = Targeting.AREAS.get("erase", {})
	t.check(String(b.get("name", "")) == "Erasing Distance" and int(b.get("dp", 0)) == 4 and float(b.get("cooldown", 0.0)) == 60.0
		and String(b.get("aim", "")) == "drag" and not PowerBook.is_quiet("erase") and PowerBook.authority_of("erase") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "lane"
		and is_equal_approx(float(area.get("length", 0.0)), 10.0) and is_equal_approx(float(area.get("half", 0.0)), 1.0)
		and bool(area.get("stretch", false)) and Rules.POWER_KINDS.get("erase", []) == [&"crushed"]
		and PowerBook.family("erase") == "decree" and PowerBook.REACH.has("erase"),
		"Erasing Distance: Decree, 4 Might, 60 s, a drag up to 10, loud, a lane 1 each side, kills by crushing (%s)" % [b])
	var ef = load(PATH) if ResourceLoader.exists(PATH) else null
	if ef == null:
		t.check(false, "the effect script loads")
		return
	t.check(is_equal_approx(PowerBook.impact("erase"), float(ef.T_SEAM) + float(ef.T_FOLD)),
		"its danger lands when the fold closes (%.2f)" % PowerBook.impact("erase"))

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var mid := FROM + DIR * LEN * 0.5
	var clear := true
	for s in env.near(mid, 4.0):
		clear = clear and (s.destroyed or s.walkable)
	t.check(clear, "the test's ground is open")

	# --- The drag's length: clamped to MIN_LEN..MAX_LEN; no end given, DEFAULT_LEN.
	var long = FxTimeline.cast(ef, ctx, FROM, {"dir": DIR, "to": FROM + DIR * 14.0})
	var short = FxTimeline.cast(ef, ctx, FROM, {"dir": DIR, "to": FROM + DIR * 0.2})
	var none = FxTimeline.cast(ef, ctx, FROM, {})
	t.check(is_equal_approx(long.length, 10.0) and is_equal_approx(short.length, float(ef.MIN_LEN))
		and is_equal_approx(none.length, float(ef.DEFAULT_LEN)) and none.dir.is_equal_approx(Vector2.RIGHT),
		"a drag of 14 erases 10, one of 0.2 its least, a cast with no drag its default (%.2f, %.2f, %.2f)" % [long.length, short.length, none.length])
	long.free()
	short.free()
	none.free()

	# --- The ground the line runs through: a house it crosses, one 1.5 off it, one 2.6 off it.
	var crossed := env.add_structure(Rect2(-24.4, 1.2, 0.8, 0.8), 30.0, Structure.Kind.HOUSE, &"house")
	var near_house := env.add_structure(Rect2(-22.5, -2.0, 0.8, 0.8), 30.0, Structure.Kind.HOUSE, &"house")
	var far_house := env.add_structure(Rect2(-21.4, 0.5, 0.6, 0.6), 30.0, Structure.Kind.HOUSE, &"house")
	var a: Person = crowd.citizens[0]
	var guard: Person = crowd.soldiers[0]
	var d: Person = crowd.citizens[1]
	var p15: Person = crowd.citizens[2]
	var p24: Person = crowd.citizens[3]
	var p35: Person = crowd.citizens[4]
	a.ground_pos = FROM + Vector2(0.8, 0.5)  # 0.8 off the line
	guard.ground_pos = FROM + Vector2(-0.5, 5.0)  # 0.5 off it
	d.ground_pos = FROM + Vector2(-0.2, 2.0)
	d.inside = true
	p15.ground_pos = FROM + Vector2(-1.5, 2.0)  # 1.5 off: not crushed, thrown
	p24.ground_pos = FROM + Vector2(2.4, 2.0)  # 2.4 off: thrown
	p35.ground_pos = FROM + Vector2(3.5, 3.0)  # 3.5 off: left standing
	var killed := crowd.killed_citizens + crowd.killed_soldiers
	var a_from := a.ground_pos.distance_to(mid)
	var fx = FxTimeline.cast(ef, ctx, FROM, {"dir": DIR, "to": FROM + DIR * LEN})
	t.check(is_equal_approx(fx.length, LEN) and fx.middle().is_equal_approx(mid), "the line runs from the press to the release (%.2f)" % fx.length)

	# --- Stage 1: the seam runs; nobody is taken yet.
	_run(fx, float(ef.T_SEAM) - DT)
	t.check(a.is_alive() and a.ground_pos.is_equal_approx(FROM + Vector2(0.8, 0.5)) and fx.caught.is_empty() and not crossed.destroyed,
		"while the seam runs, nothing is taken")

	# --- Stage 2: the fold pulls whoever stands within CRUSH_W toward the middle.
	_run(fx, DT + float(ef.T_FOLD) * 0.5)
	t.check(a.is_alive() and guard.is_alive() and fx.caught.has(a) and fx.caught.has(guard) and not fx.caught.has(d)
		and not fx.caught.has(p15) and a.ground_pos.distance_to(mid) < a_from - 0.5,
		"half way through the fold the two within 1 are pulled toward the middle (%.2f of %.2f), the one indoors and the one at 1.5 are not"
		% [a.ground_pos.distance_to(mid), a_from])
	_run(fx, float(ef.T_FOLD) * 0.5)
	fx._process(0.01)  # past the close, whatever the frames' rounding
	t.check(not a.is_alive() and a._kind == &"crushed" and not guard.is_alive() and guard._kind == &"crushed"
		and a.ground_pos.distance_to(mid) < 0.3 and guard.ground_pos.distance_to(mid) < 0.3
		and crowd.killed_citizens + crowd.killed_soldiers == killed + 2 and fx.crushed == 2,
		"when the fold closes they are crushed at its middle (kind %s, %.2f from it)" % [a._kind, a.ground_pos.distance_to(mid)])
	t.check(d.is_alive() and p15.is_alive() and p24.is_alive() and p35.is_alive(), "the one indoors and those beyond 1 live")
	t.check(crossed.destroyed and not near_house.destroyed and near_house.hp < near_house.max_hp * Structure.CRACK_AT
		and not far_house.destroyed and is_equal_approx(far_house.hp, far_house.max_hp),
		"the house the line crosses falls; the one 1.5 off cracks (%.0f of %.0f); the one 2.6 off is untouched" % [near_house.hp, near_house.max_hp])
	t.check(not p15.is_down() and not p24.is_down(), "nobody is thrown until the spring back")

	# --- Stage 3: the spring back throws whoever stands within THROW_W outward and down; rubble is left on the line.
	_run(fx, float(ef.T_SNAP) + DT)
	t.check(p15.is_down() and p24.is_down() and not p35.is_down() and p15._velocity.x < 0.0 and p24._velocity.x > 0.0
		and fx.thrown == 2, "the spring back throws those within 3 outward and knocks them down; the one at 3.5 stands (%d thrown)" % fx.thrown)
	var heaps: Array = fx.heaps
	var on_line := heaps.size() >= 5
	var closed := true
	var offsets := {}
	for h: Structure in heaps:
		var rel := h.center() - FROM
		on_line = (on_line and h.role == LawRubble.ROLE and env.structures().has(h) and absf(rel.x) <= float(ef.KINK) + 0.01
			and rel.y >= 0.0 and rel.y <= LEN)
		closed = closed and not grid.walkable(h.center())
		offsets[snappedf(rel.x, 0.01)] = true
	t.check(on_line and offsets.size() >= 3, "law rubble lies in kinked heaps along the line (%d heaps, %d offsets)" % [heaps.size(), offsets.size()])
	var crossings := 0
	for k in range(1, 12):
		crossings += 0 if grid.walkable(FROM + DIR * float(k) * 0.5) else 1
	t.check(closed and crossings == 11, "and closes the walk cells along it (%d of 11 closed)" % crossings)
	t.check(d.is_alive(), "the one indoors is still alive")
	_run(fx, fx.duration)
	t.check(fx.finished and env.structures().has(heaps[0]), "the effect ends; the rubble stays until it is cleared")

	# --- The same cast on the same ground does the same thing: nothing is rolled.
	var b2: Person = crowd.citizens[5]
	b2.ground_pos = FROM + Vector2(7.0, 0.5)
	var again = FxTimeline.cast(ef, ctx, FROM + Vector2(6.2, 0.0), {"dir": DIR, "to": FROM + Vector2(6.2, LEN)})
	_run(again, float(ef.T_SEAM) + float(ef.T_FOLD) + DT)
	t.check(not b2.is_alive() and b2._kind == &"crushed", "a second line crushes the one 0.8 off it the same way")
	again.free()
	_done(made)
