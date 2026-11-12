extends RefCounted
## Passage ability levels, All Roads Lead Here and The Folded Ward: each reads its numbers at the cast's level (level 1
## is today's exactly), and each has its level-5 twist. The Last Mile: in the last LAST_MILE seconds of the span The Far
## Gate's door of stars stands at the spot and takes the caught the roads have gathered within GATHER_R of it (kind gone);
## those still on their way stand dazed when it shuts. Pocket Square: when the span ends the square folds shut and a
## click within POCKET_WAIT sets it down elsewhere, everyone in it at the same offset, dazed; no click, it opens where it
## was. Deterministic: nothing here draws on luck.

const R = preload("res://tests/test_allroads.gd")
const F = preload("res://tests/test_foldward.gd")
const AR := "res://src/fx/control/all_roads_lead_here.gd"
const FW := "res://src/fx/control/the_folded_ward.gd"
const DT := 0.05


static func run(t) -> void:
	_roads_levels(t)
	_last_mile(t)
	_ward_levels(t)
	_pocket(t)
	_pocket_no_click(t)


# --- All Roads Lead Here ---------------------------------------------------------------------------------------------

static func _roads_cast(ctx: FxContext, at: Vector2, level: int) -> AllRoadsLeadHereFx:
	return FxTimeline.cast(load(AR), ctx, at, {"level": level}) as AllRoadsLeadHereFx


## The effect, its door (when it stands) and `who`, `seconds` in DT ticks.
static func _roads_step(fx: AllRoadsLeadHereFx, who: Array[Person], crowd: Crowd, seconds: float) -> void:
	for k in roundi(seconds / DT):
		for p in who:
			if is_instance_valid(p) and p.is_alive() and not p.inside:
				p.tick(DT)
		crowd.advance(DT)
		if not fx.finished:
			fx._process(DT)
		if fx.gate != null and is_instance_valid(fx.gate) and not fx.gate.finished:
			fx.gate._process(DT)


static func _roads_levels(t) -> void:
	var made: Array = R._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	R._park(crowd)
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var near: Person = crowd.citizens[0]
	R._calm(near, at + Vector2(2.0, 0.0))
	var edge: Person = crowd.citizens[1]
	R._calm(edge, at + Vector2(11.0, 0.0))

	var one := _roads_cast(ctx, at, 1)
	t.check(one.lv_radius == AllRoadsLeadHereFx.RADIUS and one.lv_max_people == AllRoadsLeadHereFx.MAX_PEOPLE
		and one.lv_span == AllRoadsLeadHereFx.SPAN and not one.last_mile and is_equal_approx(one.duration, AllRoadsLeadHereFx.SPAN + 0.1)
		and one.caught.has(near) and not one.caught.has(edge),
		"All Roads at level 1 is today's: a district of 10, 80 people, 25 s; one 11 away is not caught")
	one.end_now()
	near.unbend_roads()
	R._calm(near, at + Vector2(2.0, 0.0))
	var five := _roads_cast(ctx, at, 5)
	t.check(is_equal_approx(five.lv_radius, 12.0) and five.lv_max_people == 110 and is_equal_approx(five.lv_span, 33.0)
		and five.last_mile and is_equal_approx(five.duration, 33.1) and five.caught.has(near) and five.caught.has(edge)
		and is_equal_approx(float(PowerBook.cooldown("allroads", 5)), 78.0),
		"All Roads at level 5: a district of 12 (one 11 away is caught), 110 people, 33 s, a 78 s cooldown, The Last Mile")
	five.end_now()
	R._done(made)


## The Last Mile: one the roads have gathered at the end is taken in the last 3 s; one still far on its way is not, and
## stands dazed when it shuts; at level 4 nobody is taken.
static func _last_mile(t) -> void:
	for level in [5, 4]:
		var made: Array = R._setup()
		var crowd: Crowd = made[0]
		var grid: WalkGrid = made[2]
		var ctx: FxContext = made[5]
		R._park(crowd)
		var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
		var gathered: Person = crowd.citizens[0]
		R._calm(gathered, grid.nearest_walkable(at + Vector2(0.8, 0.0)))
		var far: Person = crowd.citizens[1]
		R._calm(far, grid.nearest_walkable(at + Vector2(7.0, 0.0)))
		var dead_c := crowd.killed_citizens
		var fx := _roads_cast(ctx, at, level)
		var walkers: Array[Person] = [gathered]
		t.check(fx.caught.has(gathered) and fx.caught.has(far), "level %d: both are caught by the roads" % level)
		# Up to just before the last 3 s: no door, nobody taken.
		_roads_step(fx, walkers, crowd, fx.lv_span - AllRoadsLeadHereFx.LAST_MILE - 0.2)
		t.check(fx.gate == null and gathered.is_alive() and far.is_alive()
			and gathered.ground_pos.distance_to(fx.spot) <= AllRoadsLeadHereFx.GATHER_R + 0.05,
			"level %d: before the last 3 s there is no door, and the gathered one mills within GATHER_R of the end" % level)
		_roads_step(fx, walkers, crowd, 0.4)
		if level == 5:
			t.check(fx.gate != null and fx.gate.door == fx.spot and not fx.gate.shut,
				"The Last Mile: in the last 3 s The Far Gate's door stands at the end of every road")
		else:
			t.check(fx.gate == null, "level 4: no door opens")
		_roads_step(fx, walkers, crowd, AllRoadsLeadHereFx.LAST_MILE)
		if level == 5:
			t.check(not gathered.is_alive() and gathered._kind == &"gone" and fx.taken.has(gathered)
				and crowd.killed_citizens - dead_c == 1,
				"The Last Mile: the one gathered at the end walks in and is gone for the night (kind gone, counted dead)")
			t.check(far.is_alive() and not far.roads_bent() and far.wait > 0.0 and far.mind != Person.Mind.COMPELLED
				and fx.gate.shut and not fx.taken.has(far),
				"The Last Mile: the one still far on its way arrives too late: alive, roads true again, standing dazed when it shuts")
		else:
			t.check(gathered.is_alive() and far.is_alive() and fx.taken.is_empty() and crowd.killed_citizens == dead_c
				and not gathered.roads_bent(),
				"level 4: nobody is taken; the roads simply run true again")
		R._done(made)


# --- The Folded Ward -------------------------------------------------------------------------------------------------

static func _ward_cast(s: Dictionary, level: int, at := F.C) -> FoldedWardFx:
	return FxTimeline.cast(load(FW), s.ctx, at, {"mode": "out", "level": level}) as FoldedWardFx


static func _ward_levels(t) -> void:
	var s: Dictionary = F._setup()
	var one := _ward_cast(s, 1)
	t.check(one.lv_half == FoldedWardFx.HALF and one.lv_span == FoldedWardFx.SPAN and one.ward.half == FoldedWardFx.HALF
		and not one.pocket and is_equal_approx(one.duration, FoldedWardFx.T_FOLD + FoldedWardFx.SPAN + FoldedWardFx.FADE),
		"The Folded Ward at level 1 is today's: a square of half 3, 25 s")
	one.end_now()
	var four := _ward_cast(s, 4)
	t.check(is_equal_approx(four.lv_half, 3.75) and is_equal_approx(four.lv_span, 31.0) and not four.pocket
		and is_equal_approx(four.ward.half, 3.75), "level 4: half 3.75, 31 s, no Pocket Square")
	while not four.finished:
		four._process(DT)
		if four.t > FoldedWardFx.T_FOLD + four.lv_span + 0.1 and four.t < FoldedWardFx.T_FOLD + four.lv_span + 0.2:
			t.check(not four.can_follow_up() and not four.follow_up(F.C + Vector2(0.0, 9.0), {}),
				"level 4: when the span ends there is no follow-up; a click is refused")
	var five := _ward_cast(s, 5)
	var area := five.follow_up_area()
	t.check(is_equal_approx(five.lv_half, 4.0) and is_equal_approx(five.lv_span, 33.0) and five.pocket
		and is_equal_approx(five.ward.half, 4.0) and String(area.get("shape", "")) == "square"
		and is_equal_approx(float(area.get("half", 0.0)), 4.0) and not five.can_follow_up()
		and is_equal_approx(float(PowerBook.cooldown("foldward", 5)), 78.0),
		"level 5: half 4 (the crowd-side fold too), 33 s, a 78 s cooldown, Pocket Square with a square preview of its size; no follow-up while it holds")
	five.end_now()
	F._done(s)


## Those placed for Pocket Square: [citizen, soldier, citizen at the level-5 corner, outsider, dog, hound pack, hound].
static func _pocket_cast(s: Dictionary) -> Array:
	var crowd: Crowd = s.crowd
	var c := F.C
	var a: Person = crowd.citizens[0]
	F._stand(a, c + Vector2(1.0, 1.0))
	var guard: Person = crowd.soldiers[0]
	F._stand(guard, c + Vector2(-2.0, 0.5))
	var corner: Person = crowd.citizens[1]
	F._stand(corner, c + Vector2(3.5, -3.5))
	var outsider: Person = crowd.citizens[2]
	F._stand(outsider, c + Vector2(6.0, 0.0))
	var dog := Animal.new()
	dog.breed = Animal.Breed.HOUND
	dog.ground_pos = c + Vector2(0.5, -1.5)
	dog.home = dog.ground_pos
	dog.goal = dog.ground_pos
	dog.sync_position()
	(s.world as Node2D).add_child(dog)
	(s.pack as AnimalPack).animals.append(dog)
	var visitors := Visitors.new().setup(s.field, crowd, s.grid, s.world)
	var hound := visitors.summon(c + Vector2(-3.0, 3.0), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	var fx := _ward_cast(s, 5)
	# The span runs out (nobody stepped: they stand where they were put).
	while fx.t < FoldedWardFx.T_FOLD + fx.lv_span:
		fx._process(DT)
	return [fx, a, guard, corner, outsider, dog, visitors, hound]


## Steps the ward, the people placed, and the hound's pack, `seconds`.
static func _pocket_step(fx: FoldedWardFx, people: Array, visitors: Visitors, seconds: float) -> void:
	for k in roundi(seconds / DT):
		for p: Person in people:
			if p.is_alive() and not p.inside:
				p.tick(DT)
		visitors.step(DT)
		if not fx.finished:
			fx._process(DT)


static func _pocket(t) -> void:
	var s: Dictionary = F._setup()
	var made := _pocket_cast(s)
	var fx: FoldedWardFx = made[0]
	var people: Array = [made[1], made[2], made[3]]
	var inside: Array = [made[1], made[2], made[3], made[5], made[7]]
	var visitors: Visitors = made[6]
	var was := {}
	for body: Object in inside + [made[4]]:
		was[body] = body.ground_pos
	t.check(fx.pocket_shut and fx.can_follow_up() and not fx.holding,
		"Pocket Square: when the span ends the square folds shut and waits for the click")
	_pocket_step(fx, people, visitors, 1.0)
	var still := true
	for body: Object in inside:
		still = still and (body.ground_pos as Vector2) == (was[body] as Vector2)
	t.check(still and fx.can_follow_up(), "folded in the square, everyone in it stays where it stood while it waits")
	# Somewhere open ground for every one of them at the same offsets.
	var to := Vector2.INF
	for cand: Vector2 in [F.C + Vector2(0.0, 10.0), F.C + Vector2(0.0, -10.0), F.C + Vector2(-10.0, 0.0), F.C + Vector2(10.0, 0.0),
			F.C + Vector2(10.0, 10.0), F.C + Vector2(-10.0, -10.0)]:
		var ok := true
		for body: Object in inside:
			ok = ok and fx.ward.open_ground(cand + (was[body] as Vector2) - F.C)
		if ok:
			to = cand
			break
	t.check(to != Vector2.INF, "an open square of the same size is found for the test (%s)" % to)
	if to == Vector2.INF:
		to = F.C + Vector2(0.0, 10.0)
	t.check(fx.follow_up(to, {}), "a click within 4 s sets the square down there")
	var moved := true
	for body: Object in inside:
		moved = moved and (body.ground_pos as Vector2).distance_to(to + (was[body] as Vector2) - F.C) < 0.001
	var a: Person = made[1]
	var guard: Person = made[2]
	t.check(moved and fx.pocket_moved == inside.size() and fx.pocket_at == to,
		"everyone inside -- citizens, a soldier, one at the level-5 corner, a dog, a hellhound -- is unfolded at the same offset in the new square (%d)" % fx.pocket_moved)
	t.check((made[4] as Person).ground_pos == was[made[4]], "one outside the square is not carried")
	t.check(is_equal_approx(a.wait, FoldedWardFx.DAZE) and is_equal_approx(guard.wait, FoldedWardFx.DAZE)
		and not fx.can_follow_up() and not fx.follow_up(F.C, {}),
		"those set down stand dazed 1 s; the square, set down, takes no second click")
	var hound: Animal = made[7]
	_pocket_step(fx, [], visitors, 0.5)
	t.check(hound.ground_pos.distance_to(to + (was[hound] as Vector2) - F.C) < 0.001, "the hellhound stands dazed where it was set down")
	visitors.clear()
	F._done(s)


static func _pocket_no_click(t) -> void:
	var s: Dictionary = F._setup()
	var made := _pocket_cast(s)
	var fx: FoldedWardFx = made[0]
	var inside: Array = [made[1], made[2], made[3], made[5], made[7]]
	var visitors: Visitors = made[6]
	var was := {}
	for body: Object in inside:
		was[body] = body.ground_pos
	_pocket_step(fx, [made[1], made[2], made[3]], visitors, FoldedWardFx.POCKET_WAIT + 0.1)
	var stayed := true
	var drift := ""
	for body: Object in inside:
		var off := (body.ground_pos as Vector2) - (was[body] as Vector2)
		stayed = stayed and off.length() < 0.001
		drift += "%s " % off
	t.check(stayed and fx.pocket_moved == 0 and fx.pocket_at == F.C and not fx.pocket_shut
		and not fx.can_follow_up() and not fx.follow_up(F.C + Vector2(0.0, 10.0), {}),
		"no click within 4 s: it opens where it was, nobody moves, and a late click is refused (%s| %d %s %s)"
		% [drift, fx.pocket_moved, fx.pocket_at, fx.pocket_shut])
	visitors.clear()
	F._done(s)
