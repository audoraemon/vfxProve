extends RefCounted
## Heaven's Door (Passage, Tier V): a great door falls from the sky where the press lands, facing the drag. At T_FALL it
## lands: everyone within CRUSH_R is crushed (kind stone), everyone within SHOCK_R thrown away and down, and every
## building and good within SHOCK_R takes LAND_DAMAGE (stone: no fire). Its leaves open over T_OPEN; then for SPAN
## everything in the half circle of PULL_R before it is drawn to the doorway, PULL_NEAR a second at the door falling
## evenly to PULL_FAR at PULL_R. Whoever comes within DOOR_R of the doorway is gone (kind gone, no body); the town's dogs,
## the hellhounds, the loose goods and the small structures go in too; the bigger buildings in front are torn down by
## the wind (no fire). Behind it nothing is drawn. Nothing in it is luck: two casts on the same town end the same way.

const FX := "res://src/fx/control/heavens_door.gd"
const DT := 0.05


# --- Worlds -------------------------------------------------------------------

## The town, with its crowd and its pack, everyone moved out of the way into a far corner to be placed one by one.
static func _town() -> Dictionary:
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
	var pack := AnimalPack.new().setup(crowd, grid, world, 5)
	crowd.animals = pack
	var ctx := _ctx(env, field, crowd, world)
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos
		i += 1
	var door := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	return {"crowd": crowd, "env": env, "grid": grid, "field": field, "world": world, "ctx": ctx, "pack": pack,
		"door": door, "frame": 0}


## Open ground and no town: an empty field of plain units, for the pull's own rules.
static func _bare() -> Dictionary:
	var env := EnvironmentField.new()
	var field := EnemyField.new()
	field.env = env
	field.bounds = Rect2(-40, -40, 80, 80)
	var world := Node2D.new()
	return {"env": env, "field": field, "world": world, "ctx": _ctx(env, field, null, world), "units": []}


static func _ctx(env: EnvironmentField, field: EnemyField, crowd: Crowd, world: Node2D) -> FxContext:
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.world = world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return ctx


static func _unit(s: Dictionary, at: Vector2) -> DummyEnemy:
	var e := DummyEnemy.new()
	e.ground_pos = at
	e._target = at
	(s.field as EnemyField).add(e)
	(s.units as Array).append(e)
	return e


static func _done(s: Dictionary) -> void:
	Person.frame_no = -1
	if s.has("pack"):
		(s.pack as AnimalPack).clear()
	if s.has("crowd"):
		(s.crowd as Crowd).clear()
	for e in s.get("units", []):
		if is_instance_valid(e):
			e.free()
	var ctx: FxContext = s.ctx
	ctx.overhead.free()
	ctx.ground.free()
	(s.world as Node).free()


## Stand `p` at `at` in `mind`, with nothing to walk to and an even pace.
static func _stand(p: Person, at: Vector2, mind := Person.Mind.CALM) -> void:
	p.ground_pos = at
	p.mind = mind
	p.pace = 1.0
	p.inside = false
	p._goal = Vector2.INF
	p._path = PackedVector2Array()
	p._target = at
	p.statuses.erase(&"slow")
	p.walk_speed = p._mind_speed()
	p._sync_position()


## The door's clock alone (nobody walks; only the door moves anyone).
static func _run_fx(fx: FxTimeline, seconds: float) -> void:
	for k in roundi(seconds / DT):
		fx._process(DT)


## The whole town `seconds` on: the door, the people, the crowd and the animals, a frame at a time.
static func _run(s: Dictionary, fx: FxTimeline, seconds: float) -> void:
	var crowd: Crowd = s.crowd
	for k in roundi(seconds / DT):
		s.frame += 1
		Person.frame_no = s.frame
		if not fx.finished:
			fx._process(DT)
		crowd.step_people(DT)
		crowd.advance(DT)
		(s.pack as AnimalPack).step(DT)


## A walkable spot about `d` from `door`, in front of a door facing `dir`, as near the facing as the town allows.
static func _spot(grid: WalkGrid, door: Vector2, dir: Vector2, d: float) -> Vector2:
	for a in [0.0, 0.2, -0.2, 0.4, -0.4, 0.6, -0.6, 0.8, -0.8, 1.0, -1.0, 1.2, -1.2]:
		var q := grid.nearest_walkable(door + dir.rotated(a) * d, 3)
		if q != Vector2.INF and absf(q.distance_to(door) - d) < 0.5 and HeavensDoorFx.before(q, door, dir):
			return q
	return Vector2.INF


## A walkable spot `d` from `door` in front of it from which the streets lead straight out past PULL_R: its way to a
## spot PULL_R + 3 out never turns back toward the door and is not much longer than the straight line. INF if none.
static func _open_run(grid: WalkGrid, door: Vector2, dir: Vector2, d: float) -> Vector2:
	var best := Vector2.INF
	var best_len := INF
	for k in 31:
		var way := dir.rotated((float(k) / 30.0 - 0.5) * PI * 0.9)
		var q := grid.nearest_walkable(door + way * d, 2)
		var to := grid.nearest_walkable(door + way * (HeavensDoorFx.PULL_R + 3.0), 3)
		if q == Vector2.INF or to == Vector2.INF or not HeavensDoorFx.before(q, door, dir):
			continue
		var path := grid.path(q, to)
		if path.is_empty():
			continue
		var length := 0.0
		var last := q
		var outward := true
		for w in path:
			length += last.distance_to(w)
			last = w
			outward = outward and w.distance_to(door) >= q.distance_to(door) - 0.3
		if outward and length < best_len and length < 1.4 * q.distance_to(to):
			best_len = length
			best = q
	return best


static func _animal(s: Dictionary, breed: Animal.Breed, at: Vector2) -> Animal:
	var a := Animal.new()
	a.breed = breed
	a.ground_pos = at
	a.home = at
	a.goal = at
	a.wait = 999.0
	a.sync_position()
	(s.world as Node2D).add_child(a)
	(s.pack as AnimalPack).animals.append(a)
	return a


static func _decor(s: Dictionary, kind: Decor.Kind, at: Vector2) -> Decor:
	var d := Decor.new().setup(kind, at, Vector2(0.3, 0.3), 11)
	(s.env as EnvironmentField).add_decor(d)
	return d


## A house standing `lo`..`hi` from the door (its nearest wall), its middle well in front of a door facing `dir` (or,
## with `behind`, well behind it).
static func _house(env: EnvironmentField, door: Vector2, dir: Vector2, lo: float, hi: float, behind := false) -> Structure:
	var best: Structure = null
	for s in env.near(door, hi + 3.0):
		if s.destroyed or s.kind != Structure.Kind.HOUSE:
			continue
		var d := s.distance_to(door)
		var rel := s.center() - door
		var along := rel.dot(dir) * (-1.0 if behind else 1.0)
		if d >= lo and d <= hi and along >= 0.6 * rel.length():
			if best == null or d < best.distance_to(door):
				best = s
	return best


# --- The book -------------------------------------------------------------------

static func _book(t) -> void:
	var b := PowerBook.get_power("heavendoor")
	var area: Dictionary = Targeting.AREAS.get("heavendoor", {})
	t.check(b.name == "Heaven's Door" and int(b.dp) == 6 and is_equal_approx(float(b.cooldown), 999.0) and String(b.aim) == "drag"
			and not PowerBook.is_quiet("heavendoor") and PowerBook.authority_of("heavendoor") == "passage"
			and PowerBook.family("heavendoor") == "passage",
		"Heaven's Door is Passage's 6 DP, loud, aimed by a drag, once a descent, of the passage family")
	t.check(is_equal_approx(PowerBook.impact("heavendoor"), HeavensDoorFx.T_FALL) and PowerBook.REACH.has("heavendoor")
			and Rules.POWER_KINDS.get("heavendoor", []) == [&"stone", &"gone"],
		"its first kill is the landing at T_FALL; the town sees it (REACH); its dead are crushed (stone) or gone")
	t.check(PowerBook.icon("heavendoor") != null and PowerBook.hud_icon("heavendoor") != null, "it has its icons")
	t.check(String(area.get("shape", "")) == "cone" and is_equal_approx(float(area.get("r", 0.0)), HeavensDoorFx.PULL_R)
			and is_equal_approx(float(area.get("arc", 0.0)), HeavensDoorFx.HALF_ANGLE * 2.0) and bool(area.get("aimed", false))
			and is_equal_approx(float(area.get("inner", 0.0)), HeavensDoorFx.CRUSH_R)
			and is_equal_approx(float(area.get("outer", 0.0)), HeavensDoorFx.SHOCK_R),
		"the aim shows the half circle of PULL_R before it, with CRUSH_R and SHOCK_R ringed where it lands")
	t.check(is_equal_approx(Targeting.cone_start(area, Vector2(0, 1)), 0.0)
			and is_equal_approx(Targeting.cone_start(area, Vector2(1, 0)), -PI * 0.5)
			and is_equal_approx(Targeting.cone_start(Targeting.AREAS["dragon"], Vector2(0, 1)), Targeting.cone_start(Targeting.AREAS["dragon"], Vector2(1, 0))),
		"its half circle turns with the drag (the dragon's cone does not)")
	t.check(HeavensDoorFx.facing_of({}) == Vector2(1, 0) and HeavensDoorFx.facing_of({"dir": Vector2(0, 3)}) == Vector2(0, 1),
		"a click with no drag faces it down-right on screen; a drag faces it the drag's way")


# --- The pull's own rules (EnemyField) ----------------------------------------------

static func _pull_rules(t) -> void:
	var c := Vector2.ZERO
	var f := Vector2(1, 0)
	t.check(EnemyField.cone_has(Vector2(5, 0), c, f, 16.0, PI * 0.5) and EnemyField.cone_has(Vector2(0, 5), c, f, 16.0, PI * 0.5)
			and not EnemyField.cone_has(Vector2(-0.5, 5), c, f, 16.0, PI * 0.5) and not EnemyField.cone_has(Vector2(16.5, 0), c, f, 16.0, PI * 0.5),
		"the half circle: in front and along the door's line are in it; behind it and beyond its radius are not")
	t.check(is_equal_approx(HeavensDoorFx.pull_speed(0.0), HeavensDoorFx.PULL_NEAR) and is_equal_approx(HeavensDoorFx.pull_speed(HeavensDoorFx.PULL_R), HeavensDoorFx.PULL_FAR)
			and is_equal_approx(HeavensDoorFx.pull_speed(HeavensDoorFx.PULL_R * 0.5), (HeavensDoorFx.PULL_NEAR + HeavensDoorFx.PULL_FAR) * 0.5),
		"the pull is PULL_NEAR at the door, PULL_FAR at PULL_R, evenly between")
	t.check(HeavensDoorFx.pull_speed(HeavensDoorFx.DOOR_R * 2.0) > Person.PANIC_SPEED * Person.PACE_RANGE.y
			and HeavensDoorFx.pull_speed(HeavensDoorFx.PULL_R * 0.75) < Person.PANIC_SPEED * Person.PACE_RANGE.x,
		"near the door the pull outruns the fastest panic; in the outer quarter even the slowest panic outruns it")
	var s := _bare()
	var field: EnemyField = s.field
	var near := _unit(s, Vector2(3, 0))
	var far := _unit(s, Vector2(12, 0))
	var back := _unit(s, Vector2(-5, 0))
	var out := _unit(s, Vector2(17, 0))
	var skipped := _unit(s, Vector2(0, 6))
	var moved := field.pull_cone(c, f, 16.0, PI * 0.5, 3.0, 0.6, 0.5, func(e: DummyEnemy) -> bool: return e == skipped)
	t.near(3.0 - near.ground_pos.x, HeavensDoorFx.pull_speed(3.0) * 0.5, 0.0001, "half a second of it carries one 3 from the door its pull's half (%.3f)" % (3.0 - near.ground_pos.x))
	t.near(12.0 - far.ground_pos.x, HeavensDoorFx.pull_speed(12.0) * 0.5, 0.0001, "and one 12 away less (%.3f)" % (12.0 - far.ground_pos.x))
	t.check(back.ground_pos == Vector2(-5, 0) and out.ground_pos == Vector2(17, 0) and skipped.ground_pos == Vector2(0, 6)
			and moved.size() == 2 and near in moved and far in moved,
		"behind the door, beyond PULL_R and one left out: not moved")
	# A wall across the way: held against it, never through it.
	var env: EnvironmentField = s.env
	env.add_structure(Rect2(1.5, -3.0, 1.0, 6.0), 20.0, Structure.Kind.WALL)
	var walled := _unit(s, Vector2(5, 0.5))
	for k in 60:
		field.pull_cone(c, f, 16.0, PI * 0.5, 3.0, 0.6, 1.0 / 30.0)
	t.check(walled.ground_pos.x > 2.5 and walled.ground_pos.x < 3.0 and not env.blocked(walled.ground_pos),
		"a wall in the way holds them against it: they are not carried through it (%s)" % walled.ground_pos)
	_done(s)


# --- One cast on the town -------------------------------------------------------------

## The whole cast, laid out the same way every time; what it did (for two runs to compare).
static func _scenario(t, checks: bool) -> String:
	var s := _town()
	var crowd: Crowd = s.crowd
	var grid: WalkGrid = s.grid
	var env: EnvironmentField = s.env
	var field: EnemyField = s.field
	var pack: AnimalPack = s.pack
	var door: Vector2 = s.door
	var dir := HeavensDoorFx.DEFAULT_DIR
	var kinds := {}
	field.enemy_killed.connect(func(e: DummyEnemy, kind: StringName) -> void: kinds[e] = kind)
	var c_crush: Person = crowd.citizens[0]
	var c_crush_back: Person = crowd.citizens[1]
	var c_shock: Person = crowd.citizens[2]
	var c_far: Person = crowd.citizens[3]
	var c_behind: Person = crowd.citizens[4]
	var c_inside: Person = crowd.citizens[5]
	var s_near: Person = crowd.soldiers[0]
	_stand(c_crush, grid.nearest_walkable(door + dir * 1.8, 3))
	_stand(c_crush_back, grid.nearest_walkable(door - dir * 2.2, 3))
	_stand(c_shock, _spot(grid, door, dir, 5.0))
	_stand(c_far, _open_run(grid, door, dir, 13.0))
	_stand(c_behind, grid.nearest_walkable(door - dir * 9.0, 4))
	_stand(c_inside, door + dir * 2.0)
	c_inside.inside = true
	_stand(s_near, _spot(grid, door, dir, 6.0), Person.Mind.POST)
	var visitors := Visitors.new().setup(field, crowd, grid, s.world)
	var hound := visitors.summon(_spot(grid, door, dir.rotated(-0.5), 8.0), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	var barrel_at := _spot(grid, door, dir.rotated(0.3), 9.0)
	var barrel := _decor(s, Decor.Kind.BARREL, barrel_at)
	var back_barrel := _decor(s, Decor.Kind.BARREL, grid.nearest_walkable(door - dir * 10.0, 4))
	# A market stall out beyond the blow of the landing, in front.
	var stall_at := _spot(grid, door, dir.rotated(-0.25), 10.0)
	var stall := env.add_structure(Rect2(stall_at - Vector2(0.3, 0.3), Vector2(0.6, 0.6)), 10.0, Structure.Kind.MARKET_STALL, &"market")
	var house := _house(env, door, dir, 8.0, 13.0)
	var house_back := _house(env, door, dir, 8.0, 13.0, true)
	var hp := {}
	for st in env.structures():
		hp[st] = st.hp
	var in_shock := []
	var past_shock := []
	for st in env.near(door, HeavensDoorFx.SHOCK_R + 4.0):
		if st.destroyed:
			continue
		if st.distance_to(door) <= HeavensDoorFx.SHOCK_R:
			in_shock.append(st)
		elif st.distance_to(door) > HeavensDoorFx.SHOCK_R + 0.05:
			past_shock.append(st)
	var shocked_goods := []
	for d in env.decor():
		if is_instance_valid(d) and d.at.distance_to(door) <= HeavensDoorFx.SHOCK_R - 0.2:
			shocked_goods.append(d)
	if checks:
		t.check(c_shock.ground_pos != Vector2.INF and c_far.ground_pos != Vector2.INF and s_near.ground_pos != Vector2.INF
				and barrel_at != Vector2.INF and stall_at != Vector2.INF and house != null and house_back != null
				and not in_shock.is_empty() and not past_shock.is_empty(),
			"the town is laid out: people near and far in front, one behind, a stall and a barrel in front, a house in front and one behind")

	var fx: HeavensDoorFx = FxTimeline.cast(load(FX), s.ctx, door)
	if checks:
		t.check(fx.door == door and fx.facing == dir and is_equal_approx(fx.busy, HeavensDoorFx.T_FALL)
				and is_equal_approx(fx.open_at(), HeavensDoorFx.T_FALL + HeavensDoorFx.T_OPEN)
				and is_equal_approx(fx.shut_at(), fx.open_at() + HeavensDoorFx.SPAN),
			"it lands where the press lands, facing down-right with no drag; it opens T_OPEN after the fall and draws SPAN")
	var at_shock := c_shock.ground_pos
	_run_fx(fx, HeavensDoorFx.T_FALL - DT)
	if checks:
		t.check(not fx.landed and c_crush.is_alive() and c_shock.ground_pos == at_shock and c_shock.state == DummyEnemy.State.WANDER
				and house.hp == float(hp[house]) and env.decor().has(barrel),
			"nothing happens before it lands: nobody hurt, nothing moved, nothing broken")
	_run_fx(fx, DT * 2.0)
	if checks:
		t.check(fx.landed and not c_crush.is_alive() and not c_crush_back.is_alive() and kinds.get(c_crush) == &"stone"
				and kinds.get(c_crush_back) == &"stone",
			"it lands: everyone within CRUSH_R, in front or behind, is crushed (kind stone)")
		t.check(c_inside.is_alive(), "one inside a building is not crushed by the door (the building is struck)")
		var away: Vector2 = c_shock._velocity
		t.check(c_shock.is_alive() and c_shock.state == DummyEnemy.State.KNOCKBACK and away.dot(c_shock.ground_pos - door) > 0.0
				and c_shock.is_down() and s_near.state == DummyEnemy.State.KNOCKBACK,
			"everyone within SHOCK_R is thrown away from it and down, soldiers too")
		t.check(c_far.state == DummyEnemy.State.WANDER and c_behind.state == DummyEnemy.State.WANDER, "nobody beyond SHOCK_R is thrown")
		var struck := true
		var burning := false
		for st in in_shock:
			struck = struck and (st.destroyed or is_equal_approx(st.hp, float(hp[st]) - HeavensDoorFx.LAND_DAMAGE))
			if st.destroyed:
				struck = struck and st.destroy_kind == &"stone"
			burning = burning or crowd.fires.is_burning(st)
		var untouched := true
		for st in past_shock:
			untouched = untouched and is_equal_approx(st.hp, float(hp[st]))
		t.check(struck and not burning, "every building within SHOCK_R takes LAND_DAMAGE (stone): those it brings down fall to stone, and nothing burns")
		t.check(untouched, "the buildings beyond SHOCK_R are not struck by the landing")
		var down := true
		for d in shocked_goods:
			down = down and (not is_instance_valid(d) or d.down)
		t.check(down, "the goods within SHOCK_R are knocked over")
	# The leaves open: nothing is drawn until they are wide.
	var hp_house := house.hp
	_run_fx(fx, HeavensDoorFx.T_OPEN * 0.5)
	var half_open := fx.leaves(fx.t)
	var far_at := c_far.ground_pos
	_run_fx(fx, fx.open_at() - fx.t - DT)
	if checks:
		t.check(half_open > 0.2 and half_open < 0.8 and fx.leaves(fx.t) < 1.0 and not fx.pulling
				and c_far.ground_pos == far_at and house.hp == hp_house and env.decor().has(barrel) and barrel.at == barrel_at,
			"its leaves swing open over T_OPEN (%.2f halfway), and nothing is drawn before they are wide" % half_open)
	_run_fx(fx, DT * 2.0)
	if checks:
		t.check(fx.pulling and is_equal_approx(fx.leaves(fx.t), 1.0) and c_far.ground_pos.distance_to(door) < far_at.distance_to(door),
			"wide open, it draws: one far out in front is carried toward the door")
		t.check(c_far.mind == Person.Mind.PANIC or c_far.mind == Person.Mind.SHELTER, "the drawn are terrified and run")
		t.check(c_behind.ground_pos.distance_to(door) >= 8.0 and c_behind.mind != Person.Mind.PANIC, "behind the door nobody is drawn or frightened by it")
	# The span, the whole town alive round it. A dog trots up into the cleared market once the nearest houses are down
	# (a falling house kills the animals beside it: AnimalPack).
	var behind_at := c_behind.ground_pos
	var behind_min := INF
	var dog: Animal = null
	var far_out := false
	for k in roundi(HeavensDoorFx.SPAN / 0.5):
		_run(s, fx, 0.5)
		behind_min = minf(behind_min, c_behind.ground_pos.distance_to(door))
		far_out = far_out or not HeavensDoorFx.before(c_far.ground_pos, door, dir)
		if k == 3:
			dog = _animal(s, Animal.Breed.HOUND, _spot(grid, door, dir.rotated(0.5), 5.0))
	if checks:
		t.check(not c_shock.is_alive() and kinds.get(c_shock) == &"gone" and c_shock in fx.taken_people,
			"one near the door cannot outrun the pull: it reaches the doorway and is gone (kind gone)")
		t.check(c_shock.gone_light == HeavensDoorFx.GONE_LIGHT and (c_shock.modulate.a <= 0.01 or c_shock._char >= 0.99),
			"no body: the figure pales into white-gold light at the threshold")
		t.check(not s_near.is_alive() and kinds.get(s_near) == &"gone", "a soldier near the door is drawn in and gone too")
		t.check(c_far.is_alive() and far_out, "one far out who runs gets away: out of the half circle, and alive (%s)" % c_far.ground_pos)
		t.check(c_behind.is_alive() and behind_min > 3.0, "the safe side: one behind the door is never drawn to it (nearest %.1f)" % behind_min)
		t.check(not is_instance_valid(dog) and pack.animals.size() == 0, "a dog in front is drawn in and gone")
		t.check(not is_instance_valid(hound) and visitors.living().is_empty() and fx.taken_animals == 2, "a hellhound in front is drawn in and gone")
		t.check(not is_instance_valid(barrel) and fx.taken_goods >= 1 and env.decor().has(back_barrel),
			"a barrel in front slides in and is gone; one behind stays")
		t.check(not is_instance_valid(stall) and fx.torn >= 1 and fx.torn_gone >= 1,
			"a market stall in front is torn loose whole and drawn in")
		t.check(house.destroyed and house.destroy_kind == &"wind" and not crowd.fires.is_burning(house) and fx.felled >= 1,
			"a house in front is torn down by the wind over the span, and does not burn")
		t.check(not house_back.destroyed and is_equal_approx(house_back.hp, float(hp[house_back])),
			"a house behind the door takes no wind")
	# Shut: nothing is drawn any more.
	_run(s, fx, fx.shut_at() - fx.t + DT)
	var late: Person = crowd.citizens[6]
	_stand(late, _spot(grid, door, dir, 10.0))
	var late_at := late.ground_pos
	_run_fx(fx, 0.5)
	if checks:
		t.check(fx.shut and not fx.pulling and late.ground_pos == late_at, "once it shuts nothing is drawn")
	_run_fx(fx, fx.duration - fx.t + DT)
	if checks:
		t.check(fx.finished, "it rises back into the sky and is gone")
	var out := "%d|%d|%d|%d|%d|%d|%d|%s|%s" % [fx.crushed, fx.knocked, fx.taken_people.size(), fx.taken_animals, fx.taken_goods,
		fx.torn_gone, fx.felled, str(c_far.ground_pos.snapped(Vector2(0.001, 0.001))), str(behind_at.snapped(Vector2(0.001, 0.001)))]
	visitors.clear()
	_done(s)
	return out


## The drag turns it: with a drag down the ground's y, the one ahead along y is drawn and the one behind is not; turned
## the other way, the other way about.
static func _facing(t) -> void:
	for way: float in [1.0, -1.0]:
		var s := _bare()
		var ahead := _unit(s, Vector2(0, 8) * way)
		var behind := _unit(s, Vector2(0, -8) * way)
		var fx: HeavensDoorFx = FxTimeline.cast(load(FX), s.ctx, Vector2.ZERO, {"dir": Vector2(0, 2) * way})
		_run_fx(fx, fx.open_at() + 1.0)
		t.check(fx.facing == Vector2(0, 1) * way and ahead.ground_pos.length() < 8.0 - 0.5 and behind.ground_pos == Vector2(0, -8) * way,
			"facing %s: the one before it is drawn in, the one behind is not (%s, %s)" % [fx.facing, ahead.ground_pos, behind.ground_pos])
		fx.end_now()
		_done(s)


## Beyond PULL_R in front nothing is drawn.
static func _reach(t) -> void:
	var s := _bare()
	var out := _unit(s, Vector2(HeavensDoorFx.PULL_R + 0.5, 0))
	var edge := _unit(s, Vector2(HeavensDoorFx.PULL_R - 0.5, 0))
	var fx: HeavensDoorFx = FxTimeline.cast(load(FX), s.ctx, Vector2.ZERO)
	_run_fx(fx, fx.open_at() + 1.0)
	t.check(out.ground_pos.x == HeavensDoorFx.PULL_R + 0.5 and edge.ground_pos.x < HeavensDoorFx.PULL_R - 0.5,
		"one just beyond PULL_R in front is not drawn; one just within it is")
	fx.end_now()
	_done(s)


static func run(t) -> void:
	_book(t)
	_pull_rules(t)
	_facing(t)
	_reach(t)
	var first := _scenario(t, true)
	var second := _scenario(t, false)
	t.check(first == second, "no luck: two casts on the same town end the same way (%s / %s)" % [first, second])
