extends RefCounted
## Ember on a person, and its level 5 Fire Trail (Smite and Ember adjustments, 2026-11-19). A living person out in the
## open and not guised within PERSON_R of the click takes the spark (the nearest; a tie to the lower instance id) and
## burns (Burning); else it falls on a building as before. Quiet when cast. Level 5, Fire Trail: on a building a ring of
## burning ground (FireManager.lay) round the house as it catches; on a person a patch behind him every TRAIL_STEP he
## runs, TRAIL_MOST at most, the first where he caught fire. Levels 1-4 lay no patch.

const EMBER := preload("res://src/fx/ruin/ember.gd")
const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func run(t) -> void:
	_consts(t)
	_ring_spots(t)
	_house_ring(t)
	_ring_dry(t)
	_ring_most(t)
	_durations(t)
	var made := RD._setup()
	_person_burns(t, made)
	_person_too_far(t, made)
	_nearer_burns(t, made)
	_guised(t, made)
	_quiet(t, made)
	_man_trail(t, made)
	_man_low_levels(t, made)
	RD._done(made)


static func _ctx(seed_value: int, with_town := true) -> FxContext:
	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = Rect2(-30.0, -30.0, 60.0, 60.0)
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = seed_value
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	if with_town:
		var crowd := Crowd.new()
		crowd.fires = FireManager.new().setup(crowd, env, seed_value)
		ctx.crowd = crowd
	return ctx


static func _drop(ctx: FxContext) -> void:
	if ctx.crowd != null:
		ctx.crowd.fires.clear()
		ctx.crowd.free()
	ctx.field.clear()
	ctx.field.free()
	ctx.env.clear()
	ctx.env.free()
	ctx.overhead.free()
	ctx.ground.free()


## A house of 0.6 x 0.6 whose centre is `centre`.
static func _house(ctx: FxContext, centre: Vector2, kind := Structure.Kind.HOUSE) -> Structure:
	return ctx.env.add_structure(Rect2(centre - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), 18.0, kind, &"house")


static func _cast(ctx: FxContext, at: Vector2, level: int) -> EmberFx:
	return FxTimeline.cast(EMBER, ctx, at, {"level": level})


static func _end(fx: EmberFx) -> void:
	if is_instance_valid(fx):
		fx._process(5.0)
		fx.free()


static func _consts(t) -> void:
	t.check(EmberFx.PERSON_R == 0.6 and EmberFx.TRAIL_STEP == 1.0 and EmberFx.TRAIL_MOST == 8, "the brief's numbers")
	var src := FileAccess.get_file_as_string("res://src/fx/ruin/ember.gd")
	t.check(not src.contains("LEAP_R") and not src.contains("LEAP_DELAY") and not src.contains("leap_target"),
		"the Leaping Spark is gone")
	var row: Dictionary = PowerBook.get_power("ember")
	t.check(String(row.blurb) == "One spark sets a building or a person alight."
		and String(row.shape).contains("building") and String(row.shape).contains("person")
		and String(row.levels[4].twist_text) == "Fire Trail: burning ground round the house, or behind the man",
		"the blurb, the shape and the level 5 twist text (%s / %s)" % [row.blurb, row.shape])


## ring_spots(): the points about 0.6 outside the footprint, spaced `step` round it.
static func _ring_spots(t) -> void:
	var ctx := _ctx(1)
	var a := ctx.env.add_structure(Rect2(Vector2(10.0, 10.0), Vector2(2.0, 1.0)), 18.0, Structure.Kind.HOUSE, &"house")
	var spots := EmberFx.ring_spots(a, 1.0)
	var perim := 2.0 * (2.0 + 1.2 + 1.0 + 1.2)
	var ok := absf(float(spots.size()) - perim) <= 1.0
	for g in spots:
		var d := a.distance_to(g)
		ok = ok and d >= 0.6 - 0.001 and d <= 1.2
	var gap_ok := true
	for k in spots.size():
		var g2 := spots[(k + 1) % spots.size()]
		gap_ok = gap_ok and spots[k].distance_to(g2) <= 1.0 + 0.3 and spots[k].distance_to(g2) >= 0.5
	t.check(ok and gap_ok, "a 2 x 1 house: %d spots (perimeter %.1f), each 0.6-1.2 off it, about 1.0 apart" % [spots.size(), perim])
	t.check(EmberFx.ring_spots(a, 1.0) == spots, "pure: the same spots twice")
	_drop(ctx)


## Level 5 on a house: as it catches, a ring of burning ground round it, about perimeter / TRAIL_STEP patches, each 0.6-1.2
## off the footprint. Levels 1-4 lay none.
static func _house_ring(t) -> void:
	var ctx := _ctx(1)
	var a := _house(ctx, Vector2(10.0, 10.0))
	var fx := _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND - 0.05)
	var none_before := ctx.crowd.fires.patches.is_empty()
	fx._process(0.1)
	var patches := ctx.crowd.fires.patches
	var perim := 4.0 * (0.6 + 1.2)
	var ok := absf(float(patches.size()) - perim / EmberFx.TRAIL_STEP) <= 1.0
	for p in patches:
		var d := a.distance_to(p.at)
		ok = ok and d >= 0.6 - 0.001 and d <= 1.2
	t.check(none_before and fx.lit and ctx.crowd.fires.is_burning(a) and ok,
		"level 5 on a house: it catches and %d patches ring it (perimeter %.1f), each 0.6-1.2 off it" % [patches.size(), perim])
	_end(fx)
	_drop(ctx)
	for level in [1, 2, 3, 4]:
		ctx = _ctx(1)
		a = _house(ctx, Vector2(10.0, 10.0))
		fx = _cast(ctx, a.center(), level)
		fx._process(EmberFx.T_LAND + 1.0)
		t.check(fx.lit and ctx.crowd.fires.patches.is_empty(), "level %d on a house: lit, no patch" % level)
		_end(fx)
		_drop(ctx)
	# A spot inside another building is left out.
	ctx = _ctx(1)
	a = _house(ctx, Vector2(10.0, 10.0))
	var b := ctx.env.add_structure(Rect2(Vector2(9.0, 10.8), Vector2(2.0, 1.0)), 18.0, Structure.Kind.BLOCK, &"wall")
	fx = _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND + 0.05)
	var inside := 0
	for p in ctx.crowd.fires.patches:
		if b.contains(p.at, 0.0):
			inside += 1
	t.check(not ctx.crowd.fires.patches.is_empty() and inside == 0, "no patch is laid inside a building (%d)" % inside)
	_end(fx)
	_drop(ctx)


## A house by the river: no patch on the water (City.rivers(), as the Dragonfire Parade skips them), nor on a cell nobody
## can walk.
static func _ring_dry(t) -> void:
	var river: Rect2 = TownLayout.RIVER
	var ctx := _ctx(1)
	var a := _house(ctx, Vector2(0.0, river.position.y - 0.5))
	var all := EmberFx.ring_spots(a, 1.0)
	var wet := 0
	for g in all:
		if river.has_point(g):
			wet += 1
	var dry := EmberFx.ring_spots(a, 1.0, ctx.env, null, [river])
	var dry_ok := not dry.is_empty() and dry.size() == all.size() - wet
	for g in dry:
		dry_ok = dry_ok and not river.has_point(g)
	t.check(wet > 0 and dry_ok, "(pure) %d of %d spots lie in the river and are left out" % [wet, all.size()])
	var fx := _cast(ctx, a.center(), 5)
	fx._process(EmberFx.T_LAND + 0.05)
	var in_river := 0
	for p in ctx.crowd.fires.patches:
		for r: Rect2 in City.current().rivers():
			if r.has_point(p.at):
				in_river += 1
	t.check(fx.lit and not ctx.crowd.fires.patches.is_empty() and in_river == 0,
		"level 5 on a house by the river: %d patches, none on the water" % ctx.crowd.fires.patches.size())
	_end(fx)
	_drop(ctx)
	# The walk grid: in the town, every ring spot is on a walkable cell.
	var made := RD._setup()
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var bad := 0
	var n := 0
	for s: Structure in env.structures():
		if s.destroyed or not FireManager.burns(s):
			continue
		for g in EmberFx.ring_spots(s, 1.0, env, grid, City.current().rivers()):
			n += 1
			if not grid.walkable(g) or env.blocked(g, 0.0):
				bad += 1
	t.check(n > 0 and bad == 0, "every ring spot round the town's burnables is walkable and dry (%d spots, %d bad)" % [n, bad])
	RD._done(made)


## A large building's ring is thinned evenly to RING_MOST (16) patches.
static func _ring_most(t) -> void:
	var ctx := _ctx(1)
	var big := ctx.env.add_structure(Rect2(Vector2(5.0, 5.0), Vector2(6.0, 5.0)), 40.0, Structure.Kind.TEMPLE, &"temple")
	var spots := EmberFx.ring_spots(big, 1.0)
	var fx := _cast(ctx, big.center(), 5)
	fx._process(EmberFx.T_LAND + 0.05)
	var n := ctx.crowd.fires.patches.size()
	var lo := INF
	var hi := 0.0
	for k in spots.size():
		var d := spots[k].distance_to(spots[(k + 1) % spots.size()])
		lo = minf(lo, d)
		hi = maxf(hi, d)
	t.check(EmberFx.RING_MOST == 16 and spots.size() == 16 and fx.lit and n == 16 and hi <= lo * 2.0 + 0.01,
		"a 6 x 5 temple (perimeter 26.8): %d spots, %d patches, gaps %.2f-%.2f" % [spots.size(), n, lo, hi])
	_end(fx)
	_drop(ctx)


static func _durations(t) -> void:
	var ctx := _ctx(1)
	var five := _cast(ctx, Vector2.ZERO, 5)
	var one: EmberFx = FxTimeline.cast(EMBER, ctx, Vector2.ZERO)
	t.check(is_equal_approx(five.duration, EmberFx.T_LAND + 1.6) and is_equal_approx(one.duration, EmberFx.T_LAND + 1.6)
		and is_equal_approx(five.busy, EmberFx.T_LAND), "duration T_LAND + 1.6 at every level, busy T_LAND")
	five.free()
	one.free()
	_drop(ctx)


# --- On a person (a whole town) ---------------------------------------------------------------------------------------

static func _town_cast(made: Array, at: Vector2, level := 1) -> EmberFx:
	return FxTimeline.cast(EMBER, made[5], at, {"level": level}) as EmberFx


## The nth citizen still alive, calm, out in the open, unguised, at `at`.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var alive := (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var p: Person = alive[n]
	p.ground_pos = at
	p.inside = false
	p.mind = Person.Mind.CALM
	p.statuses.erase(&"guise")
	return p


static func _reset(made: Array) -> void:
	var crowd: Crowd = made[0]
	crowd.burning.clear()
	crowd.fires.clear()
	RD._clear_all(made)


## A person 0.4 from the click takes the spark and burns; the house in Ember's reach is not lit by the cast itself.
static func _person_burns(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var house := RD._house(made[1], made[2])
	var click := Vector2(house.footprint.end.x + 0.9, house.center().y)
	var p := _put(made, 3, click + Vector2(0.4, 0.0))
	var fx := _town_cast(made, click)
	t.check(fx.victim == p and fx.fuel == null, "a person 0.4 from the click is picked, not the building in reach")
	fx._process(EmberFx.T_LAND + 0.05)
	t.check(fx.lit and p.burning() and crowd.burning.count() == 1 and crowd.fires.fires.is_empty()
		and EmberFx.target(made[1], click) != null,
		"he burns, and the cast itself lights nothing, with a building in Ember's reach")
	_end(fx)


## A person 0.8 from the click and a house in reach: the house takes the spark.
static func _person_too_far(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var house := RD._house(made[1], made[2])
	var click := Vector2(house.footprint.end.x + 0.5, house.center().y)
	var p := _put(made, 4, click + Vector2(0.8, 0.0))
	var fx := _town_cast(made, click)
	fx._process(EmberFx.T_LAND + 0.05)
	t.check(fx.victim == null and fx.fuel != null and fx.fuel == EmberFx.target(made[1], click) and fx.lit
		and crowd.fires.is_burning(fx.fuel) and not p.burning() and crowd.burning.count() == 0,
		"a person 0.8 away: the nearest thing that burns in reach is lit, he is not (victim %s, fuel %s, lit %s)"
		% [fx.victim, fx.fuel, fx.lit])
	_end(fx)


## Two within 0.6: the nearer burns (Review Focus 3); a tie goes to the lower instance id.
static func _nearer_burns(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var near := _put(made, 5, at + Vector2(0.3, 0.0))
	var far := _put(made, 6, at + Vector2(0.0, 0.5))
	var fx := _town_cast(made, at)
	fx._process(EmberFx.T_LAND + 0.05)
	t.check(fx.victim == near and near.burning() and not far.burning(), "two within 0.6: the nearer burns")
	_end(fx)
	_reset(made)
	var a := _put(made, 7, at + Vector2(0.4, 0.0))
	var b := _put(made, 8, at + Vector2(-0.4, 0.0))
	var low := a if a.get_instance_id() < b.get_instance_id() else b
	t.check(EmberFx.pick_person(made[3], at) == low, "a tie goes to the lower instance id")
	a.inside = true
	b.inside = true
	t.check(EmberFx.pick_person(made[3], at) == null, "nobody out in the open: null")
	a.inside = false
	b.inside = false


## A guised person is passed over; with nothing else near, the spark gutters.
static func _guised(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var g := _put(made, 9, at + Vector2(0.2, 0.0))
	g.statuses[&"guise"] = 30.0
	var other := _put(made, 10, at + Vector2(0.0, 0.5))
	var fx := _town_cast(made, at)
	fx._process(EmberFx.T_LAND + 0.05)
	t.check(fx.victim == other and other.burning() and not g.burning(), "a guised person is skipped: the next one burns")
	_end(fx)
	_reset(made)
	g = _put(made, 9, at + Vector2(0.2, 0.0))
	g.statuses[&"guise"] = 30.0
	fx = _town_cast(made, at)
	fx._process(EmberFx.T_LAND + 0.05)
	t.check(fx.victim == null and not fx.lit and not g.burning() and crowd.burning.count() == 0,
		"only a guised one near: nothing burns")
	g.statuses.erase(&"guise")
	_end(fx)


## Quiet when cast: no alarm, and the bystander stays calm until the burning man is seen.
static func _quiet(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p := _put(made, 11, at + Vector2(0.2, 0.0))
	var by := _put(made, 12, at + Vector2(2.5, 0.0))
	var alarm0 := crowd.alarm
	var fx := _town_cast(made, at)
	fx._process(EmberFx.T_LAND + 0.05)
	t.check(PowerBook.is_quiet("ember") and p.burning() and is_equal_approx(crowd.alarm, alarm0) and by.mind == Person.Mind.CALM,
		"the cast is quiet: no alarm, the bystander calm (mind %d)" % by.mind)
	_end(fx)


## Level 5 on a man: as he runs, a patch behind him each TRAIL_STEP, TRAIL_MOST at most, the first where he caught fire, all
## on walkable ground and none inside a building (Review Focus 4).
static func _man_trail(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var at := RD._empty(made)
	var p := _put(made, 13, at)
	var laid0 := crowd.fires.patches_laid
	var fx := _town_cast(made, at, 5)
	var spots: Array[Vector2] = []
	var caught := Vector2.INF
	for i in roundi((EmberFx.T_LAND + Burning.BURN_FOR + 0.5) / DT):
		if is_instance_valid(p) and p.is_alive():
			p.frame(DT)
		if is_instance_valid(fx) and not fx.finished:
			fx._process(DT)
		if caught == Vector2.INF and p.burning():
			caught = p.ground_pos
		crowd.advance(DT)
	for g in crowd.fires.patches:
		spots.append(g.at)
	var laid := crowd.fires.patches_laid - laid0
	var ok := laid >= 1 and laid <= EmberFx.TRAIL_MOST and spots.size() == laid
	if ok:
		ok = spots[0].distance_to(caught) < 0.2
		for k in range(1, spots.size()):
			ok = ok and spots[k].distance_to(spots[k - 1]) >= EmberFx.TRAIL_STEP - 0.001
	for g in spots:
		ok = ok and grid.walkable(g) and not env.blocked(g, 0.0)
	t.check(ok and not p.is_alive(),
		"level 5 on a man: %d patches behind him, the first where he caught fire, each 1.0 on, on walkable ground (%s)" % [laid, spots])
	_end(fx)
	# TRAIL_MOST holds: walked far, he leaves 8 at most.
	_reset(made)
	at = RD._empty(made)
	var q := _put(made, 14, at)
	fx = _town_cast(made, at, 5)
	fx._process(EmberFx.T_LAND + 0.05)
	laid0 = crowd.fires.patches_laid
	for i in 60:
		q.ground_pos = grid.nearest_walkable(at + Vector2(0.25 * float(i + 1), 0.0).rotated(float(i) * 0.02))
		crowd.advance(DT)
	var most := crowd.fires.patches_laid - laid0
	t.check(q.burning() or not q.is_alive(), "(set-up) he burned on")
	t.check(most == EmberFx.TRAIL_MOST, "never more than TRAIL_MOST (%d laid over 15 units)" % most)
	_end(fx)
	_reset(made)


## Levels 1-4 on a man lay no patch.
static func _man_low_levels(t, made: Array) -> void:
	for level in [1, 2, 3, 4]:
		_reset(made)
		var crowd: Crowd = made[0]
		var grid: WalkGrid = made[2]
		var at := RD._empty(made)
		var p := _put(made, 15, at)
		var laid0 := crowd.fires.patches_laid
		var fx := _town_cast(made, at, level)
		fx._process(EmberFx.T_LAND + 0.05)
		for i in 40:
			p.ground_pos = grid.nearest_walkable(at + Vector2(0.25 * float(i + 1), 0.0))
			crowd.advance(DT)
		t.check(p.burning() and crowd.fires.patches_laid == laid0, "level %d on a man: he burns, no patch" % level)
		_end(fx)
	_reset(made)
