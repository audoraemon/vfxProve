extends RefCounted
## Eminent Domain (Decree, Tier IV; spec 5.7): a road dragged through the town. Every structure, wall, stall, tree and
## piece of decor the 10 x 2 strip overlaps is claimed and torn down; whoever stands in it (or shelters in a house it
## claims) is thrown clear to the nearer side, knocked down, at half their health -- nobody dies of it. It leaves a clear
## street, its cells open, with law rubble piled along both long sides, never on the water. All by distance: no rolls.

const PATH := "res://src/fx/decree/eminent_domain.gd"
const DT := 0.05
## Meadow east of the town wall, cleared for the test: the strip runs from FROM along +x, 10 long, 2 wide (y 8..10).
const FROM := Vector2(17.0, 9.0)
const DIR := Vector2(1.0, 0.0)
const CLEAR := Rect2(16.3, 4.5, 13.2, 9.0)


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


static func _decor(env: EnvironmentField, kind: Decor.Kind, at: Vector2, size := Vector2.ZERO) -> Decor:
	var d := Decor.new().setup(kind, at, size, 7)
	env.add_decor(d)
	return d


## Whether decor `d` is still in the town (a piece taken away is freed).
static func _has(env: EnvironmentField, d: Variant) -> bool:
	return is_instance_valid(d) and env.decor().has(d)


static func run(t) -> void:
	var b := PowerBook.get_power("eminent")
	var area: Dictionary = Targeting.AREAS.get("eminent", {})
	t.check(String(b.get("name", "")) == "Eminent Domain" and int(b.get("dp", 0)) == 4 and float(b.get("cooldown", 0.0)) == 80.0
		and String(b.get("aim", "")) == "drag" and not PowerBook.is_quiet("eminent") and PowerBook.authority_of("eminent") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "lane"
		and is_equal_approx(float(area.get("length", 0.0)), 10.0) and is_equal_approx(float(area.get("half", 0.0)), 1.0)
		and not bool(area.get("stretch", false)) and Rules.POWER_KINDS.get("eminent", [null]) == []
		and PowerBook.family("eminent") == "decree" and PowerBook.REACH.has("eminent"),
		"Eminent Domain: Decree, 4 Might, 80 s, a drag 10 long, loud, a lane 1 each side, kills nobody (%s)" % [b])
	var ef = load(PATH) if ResourceLoader.exists(PATH) else null
	if ef == null:
		t.check(false, "the effect script loads")
		return
	t.check(is_equal_approx(float(ef.LENGTH), 10.0) and is_equal_approx(float(ef.HALF_W), 1.0)
		and is_equal_approx(PowerBook.impact("eminent"), float(ef.T_TEAR)),
		"10 long, 1 each side; its danger lands when the strip is torn down (%.2f)" % PowerBook.impact("eminent"))

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
	# The meadow, cleared: nothing of the town's stands in the test's ground.
	for s in env.structures().duplicate():
		if s.footprint.intersects(CLEAR):
			env.remove(s)
	for d in env.decor().duplicate():
		if CLEAR.has_point(d.at):
			env.remove_decor(d)

	# --- What stands in the strip (y 8..10, x 17..27), and what stands just beside it.
	var house_in := env.add_structure(Rect2(19.0, 8.5, 1.0, 1.0), 30.0, Structure.Kind.HOUSE, &"house")
	var house_edge := env.add_structure(Rect2(22.0, 9.8, 0.8, 0.8), 30.0, Structure.Kind.HOUSE, &"house")
	var stall := env.add_structure(Rect2(25.0, 7.6, 0.6, 0.6), 12.0, Structure.Kind.MARKET_STALL, &"stall")
	var tree := env.add_structure(Rect2(26.0, 8.8, 0.4, 0.4), 40.0, Structure.Kind.TREE)
	var wall := env.add_structure(Rect2(20.5, 7.0, 0.3, 4.0), 20.0, Structure.Kind.WALL)
	var gate := env.add_structure(Rect2(23.0, 8.6, 0.4, 0.8), 20.0, Structure.Kind.GATE)
	var house_out := env.add_structure(Rect2(24.0, 10.5, 0.8, 0.8), 30.0, Structure.Kind.HOUSE, &"house")  # 0.5 off
	var claimed: Array[Structure] = [house_in, house_edge, stall, tree, wall, gate]
	var barrel_in := _decor(env, Decor.Kind.BARREL, Vector2(18.0, 9.5))
	var oak := _decor(env, Decor.Kind.OAK, Vector2(21.5, 8.2), Vector2(50.0, 0.0))
	var fence := _decor(env, Decor.Kind.FENCE, Vector2(24.6, 11.5), Vector2(0.0, -2.0))  # runs into the strip
	var barrel_out := _decor(env, Decor.Kind.BARREL, Vector2(26.0, 10.5))  # 0.5 off
	# A yard's fence the town's blockers close (as a garden's): the strip opens it.
	var yard := Rect2(23.2, 9.0, 0.8, 0.9)
	grid._blockers.append(yard)
	grid.stamp(yard, true)
	# The people: two in the open either side of the line, one on it, one sheltering in the house it claims, one in the
	# band beside it where the rubble will lie, one well off.
	var a: Person = crowd.citizens[0]
	var guard: Person = crowd.soldiers[0]
	var c: Person = crowd.citizens[1]
	var sheltered: Person = crowd.citizens[2]
	var beside: Person = crowd.citizens[3]
	var far: Person = crowd.citizens[4]
	a.ground_pos = Vector2(18.5, 9.4)
	guard.ground_pos = Vector2(20.0, 8.7)
	c.ground_pos = Vector2(24.0, 9.0)
	sheltered.ground_pos = house_in.center()
	crowd.shelters.shelters[house_in] = {"inside": [], "coming": [], "clear": 0.0}
	crowd.shelters._enter(sheltered, house_in)
	(crowd.shelters.shelters[house_in].inside as Array).append(sheltered)
	beside.ground_pos = Vector2(26.5, 10.6)
	far.ground_pos = Vector2(25.0, 12.8)
	var a_health := a.health
	var g_health := guard.health
	var killed := crowd.killed_citizens + crowd.killed_soldiers

	var fx = FxTimeline.cast(ef, ctx, FROM, {"dir": DIR, "to": FROM + DIR * 3.0})
	t.check(fx.dir.is_equal_approx(DIR) and fx.to.is_equal_approx(FROM + DIR * 10.0),
		"the strip runs 10 along the drag, however short the drag (%s)" % [fx.to])

	# --- The claim: the strip is ruled out; nothing falls yet.
	_run(fx, float(ef.T_TEAR) - DT)
	var standing := true
	for s in claimed:
		standing = standing and not s.destroyed
	t.check(standing and not a.is_down() and a.ground_pos.is_equal_approx(Vector2(18.5, 9.4)) and _has(env, barrel_in)
		and sheltered.inside, "while the strip is claimed, nothing is torn down and nobody is moved")

	# --- The tear, and the throw.
	_run(fx, DT + float(ef.T_THROW) + DT)
	var fallen := true
	for s in claimed:
		fallen = fallen and is_instance_valid(s) and s.destroyed
	t.check(fallen and fx.claimed == claimed.size() and not house_out.destroyed and is_equal_approx(house_out.hp, house_out.max_hp),
		"every house, wall, stall, tree and gate the strip overlaps is torn down (%d); the house 0.5 off is untouched" % fx.claimed)
	var left_in := 0
	for d in env.decor():
		if is_instance_valid(d) and fx.in_strip(d.at, 0.15):
			left_in += 1
	t.check(not _has(env, barrel_in) and not _has(env, oak) and not _has(env, fence) and _has(env, barrel_out)
		and left_in == 0 and fx.removed == 3,
		"every piece of decor in it is gone, the fence that ran into it too; the barrel 0.5 off stays (%d removed)" % fx.removed)
	var hl := float(ef.HALF_W)
	t.check(a.is_alive() and a.ground_pos.y > 9.0 + hl and is_equal_approx(a.ground_pos.x, 18.5)
		and is_equal_approx(a.ground_pos.y - 9.0, fx.land) and a.is_down() and is_equal_approx(a.health, a_health * 0.5),
		"the one 0.4 off the line is thrown clear to his own side (%.2f off), knocked down, at half his health (%.2f)"
		% [a.ground_pos.y - 9.0, a.health])
	t.check(guard.is_alive() and guard.ground_pos.y < 9.0 - hl and guard.is_down() and is_equal_approx(guard.health, g_health * 0.5),
		"the soldier on the other side is thrown to that side, down, at half health (%s, %.2f)" % [guard.ground_pos, guard.health])
	t.check(c.is_alive() and absf(c.ground_pos.y - 9.0) > hl and c.is_down() and is_equal_approx(c.health, 0.5),
		"the one on the line is thrown clear too (%s)" % [c.ground_pos])
	t.check(sheltered.is_alive() and not sheltered.inside and sheltered.visible and absf(sheltered.ground_pos.y - 9.0) > hl
		and sheltered.is_down() and is_equal_approx(sheltered.health, 0.5) and crowd.shelters.occupants(house_in) == 0,
		"the one sheltering in the house it claims is thrown out of it and clear, not buried (%s)" % [sheltered.ground_pos])
	t.check(far.is_alive() and not far.is_down() and is_equal_approx(far.health, 1.0) and beside.is_alive() and not beside.is_down()
		and is_equal_approx(beside.health, 1.0) and crowd.killed_citizens + crowd.killed_soldiers == killed and fx.thrown == 4,
		"those outside it are not hurt, and nobody dies of it (%d thrown)" % fx.thrown)

	# --- What it leaves: a clear street, open to walk, rubble along both sides.
	var shut := 0
	for x in 20:
		for y in 4:
			if not grid.walkable(Vector2(17.25 + 0.5 * float(x), 8.25 + 0.5 * float(y))):
				shut += 1
	t.check(shut == 0, "every cell of the strip is open to walk, the yard it crossed too (%d closed)" % shut)
	var heaps: Array = fx.heaps
	var north := 0
	var south := 0
	var ok := true
	var strip := Rect2(17.0, 8.0, 10.0, 2.0)
	for h: Structure in heaps:
		ok = (ok and h.role == LawRubble.ROLE and env.structures().has(h) and not h.footprint.intersects(strip)
			and h.footprint.position.x >= 16.9 and h.footprint.end.x <= 27.1 and not grid.walkable(h.center())
			and not h.footprint.intersects(house_out.footprint) and not h.footprint.has_point(beside.ground_pos))
		var off := h.center().y - 9.0
		ok = ok and absf(off) > hl and absf(off) < hl + 1.6
		if off > 0.0:
			south += 1
		else:
			north += 1
	t.check(ok and north >= 6 and south >= 5,
		"law rubble lies along both long sides, outside the street, never in a standing house or on a person (%d, %d)" % [north, south])
	t.check(beside.ground_pos.distance_to(Vector2(26.5, 10.6)) > 0.1 and absf(beside.ground_pos.y - 9.0) > 1.6,
		"one standing where a heap is laid is pushed out from under it (%s)" % [beside.ground_pos])
	_run(fx, fx.duration)
	t.check(fx.finished and env.structures().has(heaps[0]), "the effect ends; the rubble stays until it is cleared")
	# A house beside it falling later closes the yard's ground again -- but not the street's.
	house_out.damage(99999.0, house_out.center(), &"stone")
	shut = 0
	for x in 3:
		for y in 4:
			if not grid.walkable(Vector2(23.25 + 0.5 * float(x), 8.25 + 0.5 * float(y))):
				shut += 1
	t.check(house_out.destroyed and shut == 0, "the street stays open when a fall beside it stamps the town's ground again (%d)" % shut)

	# --- By the river: no heap on the water, nobody thrown into it.
	var wet: Person = crowd.citizens[5]
	var from2 := Vector2(-25.2, 3.0)
	wet.ground_pos = from2 + Vector2(-0.7, 3.0)
	var again = FxTimeline.cast(ef, ctx, from2, {"dir": Vector2(0.0, 1.0)})
	_run(again, float(again.duration) + DT)
	var dry := true
	var east := 0
	for h: Structure in again.heaps:
		for r: Rect2 in City.current().rivers():
			dry = dry and not h.footprint.intersects(r)
		if h.center().x > from2.x:
			east += 1
	t.check(dry and east >= 5, "by the river the rubble lies on the dry side only (%d heaps, %d east)" % [again.heaps.size(), east])
	t.check(wet.is_alive() and grid.walkable(wet.ground_pos) and absf(wet.ground_pos.x - from2.x) > hl and wet.is_down(),
		"one whose nearer side is the river is thrown clear onto dry ground (%s)" % [wet.ground_pos])
	_done(made)
