extends RefCounted
## Veil Task 10: The Swallowing Dark (spec 5.9). A black circle grows from the click at GROW a second -- 0 to 10 in the light, from the
## dusk patch it was cast in to 14 in the dark -- unseen: no danger, no alarm, nobody runs, and one who walks out in time lives. At full
## size everything inside is gone without a sound (people &"void", animals, decor, buildings wholly inside with their shelterers; the
## spared stand), PER_FRAME removals a frame at most, all within 1 s; nothing is remembered; the emptied ground is dusk for 20 s. An
## effect ended before full size takes nothing. Through Rules the other slots unlock once the circle has opened (C16).

const DT := 1.0 / 60.0


## A director that needs one building standing.
class TestDirector extends MissionDirector:
	var keep: Structure

	func needs_standing(s: Structure) -> bool:
		return s != null and s == keep


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
	crowd.dusk.enabled = true
	crowd.remains.enabled = true
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.rules = Rules.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	var crowd: Crowd = made[0]
	for s in crowd.footholds.duplicate():
		BlightFx.heal(crowd, made[1], s)
	crowd.clear()
	var ctx: FxContext = made[5]
	ctx.rules.free()
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _cast(ctx: FxContext, at: Vector2, dark := false) -> TheSwallowingDarkFx:
	return FxTimeline.cast(TheSwallowingDarkFx, ctx, at, {"dark": dark}) as TheSwallowingDarkFx


## Steps the effect `seconds` in frames of DT.
static func _go(fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		if not is_instance_valid(fx) or fx.finished:
			return
		fx._process(DT)


## Plain houses, by instance id.
static func _houses(env: EnvironmentField) -> Array[Structure]:
	var out: Array[Structure] = []
	for s in env.structures():
		if is_instance_valid(s) and s.kind == Structure.Kind.HOUSE and not s.walkable:
			out.append(s)
	out.sort_custom(func(a: Structure, b: Structure) -> bool: return a.get_instance_id() < b.get_instance_id())
	return out


## The living people within `r` of `at`, out in the open.
static func _out_within(crowd: Crowd, at: Vector2, r: float) -> Array[Person]:
	var out: Array[Person] = []
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= r:
			out.append(p)
	return out


static func run(t) -> void:
	_wholly(t)
	var made := _setup()
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	t.check(env.decor().size() > 0 and _houses(env).size() > 10, "a town with decor and houses")
	_sizes(t, made)
	_unlocks(t, made)
	var shelter := _shelter_site(made)
	t.check(shelter != null, "a shelter that is not spared exists")
	# The teardown site: the house farthest from the shelter, so the big dark cast leaves it be.
	var far: Structure = null
	if shelter != null:
		for h in _houses(env):
			if far == null or h.center().distance_to(shelter.center()) > far.center().distance_to(shelter.center()):
				far = h
		_teardown(t, made, far)
		_full(t, made, shelter, grid)
		_control(t, made, far)
	_done(made)
	_no_crowd(t)


static func _wholly(t) -> void:
	var s := Structure.new()
	s.footprint = Rect2(Vector2(1.0, 1.0), Vector2(2.0, 1.0))
	var far := Vector2(3.0, 2.0).length()
	t.check(TheSwallowingDarkFx.wholly_inside(s, Vector2.ZERO, far + 0.001), "all four corners within r: wholly inside")
	t.check(not TheSwallowingDarkFx.wholly_inside(s, Vector2.ZERO, far - 0.01), "one corner outside: not wholly inside")
	t.check(not TheSwallowingDarkFx.wholly_inside(null, Vector2.ZERO, 99.0), "no structure: not inside")
	s.free()


## Light: 0 at the cast, 5.0 after 10 s, full (10.0) at 20 s. Dark in a dusk patch of 3: starts at 3.0, full at 14.0 after 22 s.
static func _sizes(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := Vector2(-200.0, -200.0)  # far off the map: nothing to take
	var fx := _cast(ctx, at)
	t.check(fx.radius() == 0.0 and is_equal_approx(fx.full_r, 10.0) and is_equal_approx(fx.t_full, 20.0) and fx.busy > 0.0,
		"light: radius 0 at the cast, full 10 at 20 s (%.2f, %.2f, %.2f)" % [fx.radius(), fx.full_r, fx.t_full])
	_go(fx, 10.0)
	t.check(absf(fx.radius() - 5.0) < 0.02 and not fx.swallowed, "light: 5.0 after 10 s (%.3f)" % fx.radius())
	_go(fx, 10.0)
	t.check(is_equal_approx(fx.radius(), 10.0) and fx.swallowed, "light: full 10 at 20 s (%.3f)" % fx.radius())
	fx.end_now()
	crowd.dusk.clear()
	crowd.lay_dusk(at, 3.0, 60.0)
	fx = _cast(ctx, at, true)
	t.check(is_equal_approx(fx.radius(), 3.0) and is_equal_approx(fx.full_r, 14.0) and is_equal_approx(fx.t_full, 22.0),
		"dark in a dusk patch of 3: starts at 3.0, full 14.0 after 22 s (%.2f, %.2f, %.2f)" % [fx.radius(), fx.full_r, fx.t_full])
	_go(fx, 21.9)
	t.check(not fx.swallowed and fx.radius() < 14.0, "dark: not full at 21.9 s")
	_go(fx, 0.2)
	t.check(fx.swallowed and is_equal_approx(fx.radius(), 14.0), "dark: full at 22 s")
	fx.end_now()
	crowd.dusk.clear()


## C16: through Rules the other slots are locked only until the circle has opened (busy = T_OPEN); after it Silent Doom casts while the
## circle still grows.
static func _unlocks(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["swallow", "doom"]), null, made[1], made[3], crowd, made[6])
	var casts: Array = []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append(fx)
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var at := Vector2(-200.0, -200.0)
	var fx := rules.cast(0, at) as TheSwallowingDarkFx
	t.check(fx != null and refused.is_empty(), "The Swallowing Dark goes out through Rules")
	if fx == null:
		rules.free()
		return
	var early := rules.cast(1, at + Vector2(-30.0, 0.0))
	t.check(early == null and refused == [[1, "busy"]] and rules.busy_left() > 0.0, "while it opens the other slots are locked (%s)" % [refused])
	refused.clear()
	_go(fx, TheSwallowingDarkFx.T_OPEN + DT)
	var later := rules.cast(1, at + Vector2(-30.0, 0.0))
	t.check(later != null and refused.is_empty() and not fx.finished and not fx.swallowed and fx.radius() < fx.full_r,
		"once it has opened Silent Doom casts while the circle still grows (%s)" % [refused])
	if later != null and is_instance_valid(later):
		later.end_now()
	fx.end_now()
	rules.free()
	crowd.dusk.clear()


static func _marks(ctx: FxContext) -> int:
	var n := 0
	for c in ctx.ground.get_children():
		if c is TheSwallowingDarkFx.BareEarth:
			n += 1
	return n


## A shelter building that is not spared and has a house wholly inside 14 of it, another not wholly inside, and decor near.
static func _shelter_site(made: Array) -> Structure:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var best: Structure = null
	for s in crowd.shelters.shelters:
		if s.role == &"temple" or MissionKeeps.spared(s, crowd, null):
			continue
		var whole := 0
		var edge := 0
		for h in _houses(env):
			if h == s:
				continue
			if TheSwallowingDarkFx.wholly_inside(h, s.center(), 14.0):
				whole += 1
			elif h.distance_to(s.center()) < 14.0 and h.center().distance_to(s.center()) <= 14.0:
				edge += 1
		if whole >= 3 and edge >= 1 and (best == null or s.get_instance_id() < best.get_instance_id()):
			best = s
	return best


## The dark cast at a shelter: growth unseen, then everything inside goes.
static func _full(t, made: Array, s0: Structure, grid: WalkGrid) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var at := s0.center()
	const R := 14.0
	# The houses: wholly inside (one a foothold, one the director keeps) and one with a corner outside.
	var whole: Array[Structure] = []
	var edge: Structure = null
	for h in _houses(env):
		if h == s0:
			continue
		if TheSwallowingDarkFx.wholly_inside(h, at, R):
			whole.append(h)
		elif edge == null and h.distance_to(at) < R and h.center().distance_to(at) <= R:
			edge = h
	var gone_h := whole[0]
	var foothold := whole[1]
	var kept := whole[2]
	var d := TestDirector.new()
	d.keep = kept
	ctx.rules.director = d
	BlightFx.plant(crowd, env, foothold, 3.0)
	t.check(crowd.footholds.has(foothold), "a blighted foothold stands inside")
	# Animals (the pack is off in tests): three inside, one outside.
	if crowd.animals == null:
		crowd.animals = AnimalPack.new().setup(crowd, grid, made[4], 5)
		(made[4] as Node).add_child(crowd.animals)
		crowd.animals.spawn(4)
	var pets := crowd.animals.living()
	t.check(pets.size() == 4, "four animals")
	for i in pets.size():
		pets[i].ground_pos = at + (Vector2(1.0 + float(i), 1.0) if i < 3 else Vector2(R + 4.0, 0.0))
	var pet_out: Animal = pets[3]
	t.check(not grid.walkable(gone_h.center()), "the walk grid is closed at the house's centre before")
	# People: one sheltering in s0, one inside who stays, one who walks out in time.
	var sh: Person = crowd.citizens[0]
	crowd.shelters._enter(sh, s0)
	(crowd.shelters.shelters[s0].inside as Array).append(sh)
	var a: Person = crowd.citizens[1]
	a.ground_pos = at + Vector2(4.0, 0.0)
	a.inside = false
	var b: Person = crowd.citizens[2]
	b.ground_pos = at + Vector2(5.0, 1.0)
	b.inside = false
	# The kept house made a shelter (C20): one shelters in it at full size, one walks in from the open after full size. Both live while
	# it stands; the one sheltering in s0 (taken) is the control.
	crowd.shelters.shelters[kept] = {"inside": [], "coming": [], "clear": 0.0}
	var k: Person = crowd.citizens[6]
	crowd.shelters._enter(k, kept)
	(crowd.shelters.shelters[kept].inside as Array).append(k)
	var late: Person = crowd.citizens[7]
	late.ground_pos = at + Vector2(0.3, 0.2)
	late.inside = false
	# Remains: one lying inside, one outside (written to the ledger as a body would be; their people then go far off).
	var lay_remain := func(p: Person, g: Vector2) -> Remains.Remain:
		p.ground_pos = g
		crowd.remains._on_killed(p, &"deathmark")
		p.ground_pos = Vector2(-27.0, -27.0)
		p.inside = false
		return crowd.remains.near(g, 0.01)[0]
	var r_in: Remains.Remain = lay_remain.call(crowd.citizens[4], at + Vector2(6.0, -1.0))
	var r_out: Remains.Remain = lay_remain.call(crowd.citizens[5], at + Vector2(R + 5.0, 0.0))
	crowd.dusk.clear()
	crowd.lay_dusk(at, 3.0, 120.0)
	var kinds := {}
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void: kinds[e] = kind
	field.enemy_killed.connect(on_kill)
	var added: Array = []
	var on_add := func(x: Structure) -> void: added.append(x)
	env.structure_added.connect(on_add)
	var alarm := crowd.alarm
	var threats := crowd.threats._next
	var events: int = crowd.alarms._events.size()
	var remains := crowd.remains.all().size()
	var structures := env.structures().size()
	var fx := _cast(ctx, at, true)
	t.check(is_equal_approx(fx.t_full, 22.0), "dark at the shelter: full after 22 s")
	# Growing: unseen. A keeps his place (pinned) and must never take fright.
	var fled := false
	var heard := false
	var walked := false
	var inside: Array[Person] = []
	var decor_in: Array[Decor] = []
	var animals_in := 0
	while not fx.swallowed and not fx.finished:
		if fx.t >= fx.t_full - 2.0 * DT and inside.is_empty():
			inside = _out_within(crowd, at, R)
			for dd in env.decor():
				if dd.at.distance_to(at) <= R:
					decor_in.append(dd)
			animals_in = crowd.animals.in_radius(at, R).size() if crowd.animals != null else 0
		a.tick(DT)
		a.ground_pos = at + Vector2(4.0, 0.0)
		fled = fled or a.mind == Person.Mind.FLEE or a.mind == Person.Mind.SHELTER
		heard = heard or crowd.alarm != alarm or crowd.threats._next != threats
		if fx.t >= 15.0 and not walked:
			b.ground_pos = at + Vector2(R + 3.0, 0.0)
			walked = true
		fx._process(DT)
	t.check(not heard, "while it grows: no threat registered, alarm unchanged")
	t.check(not fled and a.is_alive(), "a person inside does not flee")
	t.check(inside.has(a) and not inside.has(b) and inside.size() > 1, "at full size %d people stand inside" % inside.size())
	# After full size, before his turn (he stands near the middle: the fold takes the outermost first), one walks into the standing shelter.
	t.check(late.is_alive() and not late.inside, "the late one is still out in the open at full size")
	crowd.shelters._enter(late, kept)
	(crowd.shelters.shelters[kept].inside as Array).append(late)
	inside.erase(late)
	# The removals: never more than PER_FRAME a frame, all done within 1 s.
	var most := fx.removed
	var frames := 0
	var last := fx.removed
	var most_built := structures - env.structures().size()
	var built := env.structures().size()
	var gone_all := most_built
	while fx.left() > 0 and frames < 120:
		fx._process(DT)
		frames += 1
		most = maxi(most, fx.removed - last)
		last = fx.removed
		most_built = maxi(most_built, built - env.structures().size())
		gone_all += built - env.structures().size()
		built = env.structures().size()
	t.check(gone_all > TheSwallowingDarkFx.BUILDINGS_PER_FRAME and most_built <= TheSwallowingDarkFx.BUILDINGS_PER_FRAME,
		"at most BUILDINGS_PER_FRAME buildings a frame (%d of %d)" % [most_built, gone_all])
	t.check(fx.removed > TheSwallowingDarkFx.PER_FRAME, "more than one frame's worth to take (%d)" % fx.removed)
	t.check(most <= TheSwallowingDarkFx.PER_FRAME, "never more than PER_FRAME in one frame (%d)" % most)
	t.check(fx.left() == 0 and float(frames) * DT <= 1.0, "all taken within 1 s of full size (%d frames)" % frames)
	# Everyone inside, silently.
	var all_void := true
	for p in inside:
		all_void = all_void and not p.is_alive() and kinds.get(p, &"") == &"void" and not p.visible
	t.check(all_void, "every person within r is taken (&\"void\", hidden)")
	t.check(b.is_alive(), "the one who walked out lives")
	t.check(not sh.is_alive() and kinds.get(sh, &"") == &"void" and not crowd.shelters.shelters.has(s0),
		"the one sheltering in the taken building is taken with it")
	t.check(animals_in == 3 and crowd.animals.in_radius(at, R).is_empty() and crowd.animals.living() == [pet_out],
		"every animal inside is gone, the one outside stays (%d were inside)" % animals_in)
	var decor_left := 0
	for dd in decor_in:
		if is_instance_valid(dd) and env.decor().has(dd):
			decor_left += 1
	t.check(not decor_in.is_empty() and decor_left == 0, "every decor piece inside is gone (%d of %d left)" % [decor_left, decor_in.size()])
	# The buildings.
	t.check(not env.structures().has(gone_h) and gone_h.taken and grid.walkable(gone_h.center()),
		"a house wholly inside is gone: out of the field, taken, the walk grid open at its centre")
	t.check(added.is_empty() and not grid.is_pile(grid.world_to_id(gone_h.center())), "no rubble laid")
	t.check(not env.structures().has(s0) and s0.taken, "the shelter is gone")
	t.check(edge != null and env.structures().has(edge) and not edge.taken, "a house with a corner outside stands")
	t.check(env.structures().has(kept) and not kept.taken, "a building MissionKeeps.spared() names stands, though wholly inside")
	t.check(not crowd.footholds.has(foothold) and not foothold.blighted, "the foothold it took is healed: no foothold points at it")
	t.check(env.structures().size() < structures, "buildings were removed")
	# Nothing remembered.
	t.check(crowd.alarm == alarm and crowd.threats._next == threats and crowd.alarms._events.size() == events,
		"nothing remembered: alarm unchanged, no threat, no incident")
	t.check(crowd.remains.all().size() == remains - 1, "no remains left by the void's own kills")
	t.check(not crowd.remains.all().has(r_in) and crowd.remains.all().has(r_out), "a remain lying inside is taken; one outside stays")
	t.check(k.is_alive() and k.inside and env.structures().has(kept),
		"one sheltering in a building that stands is out of reach (VA6)")
	t.check(late.is_alive() and late.inside, "one who went into a standing building after full size is not taken")
	# The emptied ground: dusk for 20 s.
	var rim := at + Vector2(R - 0.1, 0.0)
	t.check(crowd.dusk.covers(rim), "the emptied ground is dusk")
	crowd.dusk.step(19.8)
	t.check(crowd.dusk.covers(rim), "still dusk at 19.8 s")
	crowd.dusk.step(0.4)
	t.check(not crowd.dusk.covers(rim), "gone after 20 s")
	_go(fx, 2.0)
	t.check(fx.finished, "the effect ends")
	field.enemy_killed.disconnect(on_kill)
	env.structure_added.disconnect(on_add)
	ctx.rules.director = null
	crowd.dusk.clear()


static func _teardown(t, made: Array, h: Structure) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var c: Person = crowd.citizens[3]
	c.ground_pos = h.center() + Vector2(0.0, 2.0)
	c.inside = false
	var decor := env.decor().size()
	var marks0 := _marks(ctx)
	for how in ["end_now", "free"]:
		crowd.dusk.clear()
		var fx := _cast(ctx, h.center())
		_go(fx, 10.0)
		if how == "end_now":
			fx.end_now()
		else:
			fx.free()
		t.check(c.is_alive() and env.structures().has(h) and not h.taken and env.decor().size() == decor
			and crowd.dusk.count() == 0, "%s before full size: nothing taken, no dusk" % how)
		# The growing disc is the effect's own; the bare earth is laid only at full size.
		t.check(_marks(ctx) == marks0, "%s before full size: no bare earth laid" % how)


## The control on the same path: the same cast left to run takes them.
static func _control(t, made: Array, h: Structure) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var c: Person = crowd.citizens[3]
	c.ground_pos = h.center() + Vector2(0.0, 2.0)
	c.inside = false
	crowd.dusk.clear()
	var marks0 := _marks(ctx)
	var fx := _cast(ctx, h.center())
	_go(fx, 22.0)
	t.check(not c.is_alive() and not env.structures().has(h) and h.taken and crowd.dusk.count() == 1 and _marks(ctx) == marks0 + 1,
		"(control) left to run: the person and the house are taken, dusk and bare earth laid")
	t.check(fx.finished, "(control) it ends")


## No crowd, no rules (the VFX Sandbox): it grows at the light size, takes the town's buildings and decor and finishes.
static func _no_crowd(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var ctx := FxContext.new()
	ctx.env = env
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var h: Structure = _houses(env)[0]
	var fx := FxTimeline.cast(TheSwallowingDarkFx, ctx, h.center()) as TheSwallowingDarkFx
	t.check(fx.radius() == 0.0 and is_equal_approx(fx.full_r, 10.0), "no crowd: the light size")
	_go(fx, 23.0)
	t.check(fx.finished and not env.structures().has(h), "no crowd: it takes the house and finishes")
	ctx.overhead.free()
	ctx.ground.free()
