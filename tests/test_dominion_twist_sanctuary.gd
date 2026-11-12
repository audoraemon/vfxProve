extends RefCounted
## Sacred Sanctuary, level 5: Pressed into Service (an intruder the wall drives out takes a place on the wall).


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
	return [crowd, env, grid, field, world, ctx]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


## A raised wall of six at level `level`; returns {fx, site, intruder, made}. The intruder (a citizen, or the first
## soldier when `soldier`) has walked in and been set on; the caller moves it out.
static func _raised(kind: String, level: int, soldier: bool) -> Dictionary:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		i += 1
	var from := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var site := from + Vector2(0.0, 9.0)
	for k in 6:
		var p: Person = crowd.citizens[k]
		p.ground_pos = grid.nearest_walkable(from + Vector2(0.6 * float(k) - 1.0, 0.5))
	var fx: SacredSanctuaryFx = FxTimeline.cast(load("res://src/fx/dominion/sacred_sanctuary.gd"), ctx, from, {"mode": kind, "to": site, "level": level})
	fx._process(SacredSanctuaryFx.T_CAST + 0.05)
	for g in fx.guards:
		g.ground_pos = g.goal()
	var intruder: Person = crowd.soldiers[0] if soldier else crowd.citizens[9]
	intruder.ground_pos = site + Vector2(0.0, 0.5)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	return {"fx": fx, "site": site, "intruder": intruder, "made": made}


static func _set_on(fx: SacredSanctuaryFx, p: Person) -> int:
	var n := 0
	for g in fx.guards:
		if g.mind == Person.Mind.FIGHT and g.fight_target == p:
			n += 1
	return n


static func run(t) -> void:
	# wall_spot
	var c := Vector2(3.0, -2.0)
	var cs := SacredSanctuaryFx.wall_spot("circle", c, c + Vector2(0.0, 7.0))
	t.check(cs.is_equal_approx(c + Vector2(0.0, SacredSanctuaryFx.CIRCLE_R)) and SacredSanctuaryFx.wall_spot("circle", c, c + Vector2(-9.0, 0.0)).is_equal_approx(c + Vector2(-SacredSanctuaryFx.CIRCLE_R, 0.0))
		and is_equal_approx(SacredSanctuaryFx.wall_spot("circle", c, c).distance_to(c), SacredSanctuaryFx.CIRCLE_R),
		"wall_spot (circle): the edge on the line from the centre; the centre itself falls to a fixed side")
	var rs := SacredSanctuaryFx.wall_spot("rect", c, c + Vector2(7.0, 1.0))
	var rs2 := SacredSanctuaryFx.wall_spot("rect", c, c + Vector2(1.0, -6.0))
	var rs3 := SacredSanctuaryFx.wall_spot("rect", c, c + Vector2(9.0, 9.0))
	var rs4 := SacredSanctuaryFx.wall_spot("rect", c, c + Vector2(3.0, 0.5))
	t.check(rs.is_equal_approx(c + Vector2(4.0, 1.0)) and rs2.is_equal_approx(c + Vector2(1.0, -2.5)) and rs3.is_equal_approx(c + Vector2(4.0, 2.5))
		and rs4.is_equal_approx(c + Vector2(4.0, 0.5)),
		"wall_spot (rect): the nearest point on the border, from outside (side and corner) and from inside")

	# circle, level 5, a citizen
	var r := _raised("circle", 5, false)
	var fx: SacredSanctuaryFx = r.fx
	var site: Vector2 = r.site
	var x: Person = r.intruder
	t.check(fx.guards.size() == 6 and _set_on(fx, x) == SacredSanctuaryFx.GUARDS_PER_INTRUDER and not fx.guards.has(x), "level 5: an intruder inside is set on as ever (guards %d, on it %d)" % [fx.guards.size(), _set_on(fx, x)])
	x.ground_pos = site + Vector2(SacredSanctuaryFx.CIRCLE_R + 1.5, 0.0)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	var spot := SacredSanctuaryFx.wall_spot("circle", site, x.ground_pos)
	t.check(fx.guards.has(x) and fx.places.size() == fx.guards.size() and fx.pressed == 1 and x.mind == Person.Mind.COMPELLED
		and x.goal().distance_to(spot) <= 0.5 and x.compel_glyph == SacredSanctuaryFx.SHIELD,
		"Pressed into Service: driven out, it joins the wall at the nearest spot (guards %d, pressed %d, mind %d, d %.2f)" % [fx.guards.size(), fx.pressed, x.mind, x.goal().distance_to(spot)])
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	t.check(fx.pressed == 1 and fx.guards.size() == 7, "and is taken once")
	fx.free()
	_done(r.made)

	# a soldier intruder too
	r = _raised("circle", 5, true)
	fx = r.fx
	x = r.intruder
	x.ground_pos = r.site + Vector2(-(SacredSanctuaryFx.CIRCLE_R + 1.5), 0.0)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	t.check(fx.guards.has(x) and x.soldier and fx.pressed == 1 and x.mind == Person.Mind.COMPELLED, "a soldier is pressed in too")
	fx.free()
	_done(r.made)

	# the wall is full
	r = _raised("circle", 5, false)
	fx = r.fx
	x = r.intruder
	fx.lv_max_guards = fx.guards.size()
	x.ground_pos = r.site + Vector2(SacredSanctuaryFx.CIRCLE_R + 1.5, 0.0)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	t.check(not fx.guards.has(x) and fx.pressed == 0 and fx.places.size() == fx.guards.size(), "with the wall at its cap, nobody more is taken")
	fx.free()
	_done(r.made)

	# rectangle
	r = _raised("rect", 5, false)
	fx = r.fx
	x = r.intruder
	x.ground_pos = r.site + Vector2(SacredSanctuaryFx.RECT.x * 0.5 + 1.5, 0.5)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	var on_border: Vector2 = SacredSanctuaryFx.wall_spot("rect", r.site, x.ground_pos)
	t.check(fx.guards.has(x) and is_equal_approx(on_border.x - r.site.x, SacredSanctuaryFx.RECT.x * 0.5) and x.goal().distance_to(on_border) <= 0.5,
		"the rectangle's post is on its border")
	fx.free()
	_done(r.made)

	# level 4
	r = _raised("circle", 4, false)
	fx = r.fx
	x = r.intruder
	x.ground_pos = r.site + Vector2(SacredSanctuaryFx.CIRCLE_R + 1.5, 0.0)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	t.check(not fx.guards.has(x) and fx.pressed == 0 and x.mind != Person.Mind.COMPELLED, "level 4: the intruder driven out is not a guard")
	fx.free()
	_done(r.made)
