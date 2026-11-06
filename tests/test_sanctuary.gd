extends RefCounted
## Sacred Sanctuary: the people at the first click are hypnotized into a wall round the place at the second, in the
## shape chosen; who stood inside is under it, and whoever comes in afterwards is set on.


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


static func run(t) -> void:
	var b := PowerBook.get_power("sanctuary")
	var modes: Array = b.get("modes", [])
	t.check(int(b.dp) == 4 and PowerBook.authority_of("sanctuary") == "dominion" and PowerBook.is_quiet("sanctuary") and String(b.aim) == "two clicks"
		and modes.size() == 2 and String(modes[0].key) == "circle" and String(modes[1].key) == "rect" and bool(b.get("alt_steps_mode", false))
		and PowerBook.icon("sanctuary") != null and PowerBook.hud_icon("sanctuary") != null and PowerBook.clip("sanctuary") != null
		and String(Targeting.AREAS["sanctuary"].shape) == "sanctuary" and Rules.POWER_KINDS["sanctuary"].has(&"frenzy") and PowerBook.family("sanctuary") != "",
		"Sacred Sanctuary is Dominion's 4 DP, quiet, two clicks, its shape a mode the right button steps, with icons, clip, area, kinds and a family")

	# The shapes.
	var c := Vector2(3.0, -2.0)
	var ring := SacredSanctuaryFx.spots("circle", c, 12)
	var on_ring := true
	for p in ring:
		on_ring = on_ring and is_equal_approx(p.distance_to(c), SacredSanctuaryFx.CIRCLE_R)
	var box := SacredSanctuaryFx.spots("rect", c, 13)
	var on_box := true
	for p in box:
		var d := p - c
		on_box = on_box and is_equal_approx(maxf(absf(d.x) / (SacredSanctuaryFx.RECT.x * 0.5), absf(d.y) / (SacredSanctuaryFx.RECT.y * 0.5)), 1.0)
	t.check(ring.size() == 12 and on_ring and box.size() == 13 and on_box, "its places lie along the edge of the circle, or of the rectangle")
	t.check(SacredSanctuaryFx.inside("circle", c, c + Vector2(3.9, 0.0)) and not SacredSanctuaryFx.inside("circle", c, c + Vector2(4.1, 0.0))
		and SacredSanctuaryFx.inside("rect", c, c + Vector2(3.9, 2.4)) and not SacredSanctuaryFx.inside("rect", c, c + Vector2(3.9, 2.6))
		and not SacredSanctuaryFx.inside("rect", c, c + Vector2(4.1, 0.0)), "and inside is inside the shape")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var from := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var site := from + Vector2(0.0, 9.0)
	var picked: Array[Person] = []
	for k in 6:
		var p: Person = crowd.citizens[k]
		p.ground_pos = grid.nearest_walkable(from + Vector2(0.6 * float(k) - 1.5, 0.5))
		p.mind = Person.Mind.CALM
		picked.append(p)
	var guard: Person = crowd.soldiers[0]
	guard.ground_pos = grid.nearest_walkable(from + Vector2(0.0, -1.0))
	var apart: Person = crowd.citizens[7]
	apart.ground_pos = from + Vector2(SacredSanctuaryFx.PICK_R + 3.0, 0.0)
	apart.mind = Person.Mind.CALM
	var dweller: Person = crowd.citizens[8]
	dweller.ground_pos = site + Vector2(0.5, 0.0)
	dweller.mind = Person.Mind.CALM
	t.check(SacredSanctuaryFx.picked_at(field, from).size() == 7 and not SacredSanctuaryFx.picked_at(field, from).has(apart),
		"the first click takes everyone within reach of it, a soldier too (%d)" % SacredSanctuaryFx.picked_at(field, from).size())
	var fx: SacredSanctuaryFx = FxTimeline.cast(load("res://src/fx/dominion/sacred_sanctuary.gd"), ctx, from, {"mode": "circle", "to": site})
	t.check(fx.guards.size() == 7 and not fx.raised and picked[0].mind == Person.Mind.CALM, "Sacred Sanctuary: the hypnotized are picked; nothing moves until the wall is raised")
	fx._process(SacredSanctuaryFx.T_CAST + 0.05)
	var walking := 0
	for g in fx.guards:
		if g.mind == Person.Mind.COMPELLED and g.held_by_will(Person.WILL_FIRM) and absf(g.goal().distance_to(site) - SacredSanctuaryFx.CIRCLE_R) <= 0.8:
			walking += 1
	t.check(fx.raised and walking == 7 and fx.places.size() == 7 and apart.mind == Person.Mind.CALM,
		"then each is sent, firmly, to a place of its own on the circle's edge; one who was not picked is left alone (%d)" % walking)
	t.check(fx.sheltered.has(dweller) and not fx.sheltered.has(apart), "who stood inside when it was raised is under it")
	# The wall stands: everyone at their place.
	for g in fx.guards:
		g.ground_pos = g.goal()
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	t.check(fx.repelled == 0 and dweller.mind == Person.Mind.CALM, "the one inside is left in peace")
	# A stranger walks in.
	var stranger: Person = crowd.citizens[9]
	stranger.mind = Person.Mind.CALM
	stranger.ground_pos = site + Vector2(0.0, 1.0)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	var set_on := 0
	for g in fx.guards:
		if g.mind == Person.Mind.FIGHT and g.fight_target == stranger:
			set_on += 1
	t.check(fx.repelled == 1 and set_on == SacredSanctuaryFx.GUARDS_PER_INTRUDER, "whoever comes in afterwards is set on by the nearest guards (%d)" % set_on)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	t.check(fx.repelled == 1, "and no more are pulled off the wall for the same intruder")
	# One who was inside leaves, and comes back a stranger.
	dweller.ground_pos = site + Vector2(SacredSanctuaryFx.CIRCLE_R + 2.0, 0.0)
	fx._process(SacredSanctuaryFx.RETHINK + 0.05)
	t.check(not fx.sheltered.has(dweller), "one who leaves is no longer under it")
	fx._process(SacredSanctuaryFx.SPAN + 1.0)
	fx.free()
	for p in picked + [guard]:
		p.stop_fighting()
		p.release_compulsion()

	# The rectangle.
	for k in 6:
		picked[k].ground_pos = grid.nearest_walkable(from + Vector2(0.6 * float(k) - 1.5, 0.5))
		picked[k].mind = Person.Mind.CALM
	guard.ground_pos = grid.nearest_walkable(from + Vector2(0.0, -1.0))
	var box_fx: SacredSanctuaryFx = FxTimeline.cast(load("res://src/fx/dominion/sacred_sanctuary.gd"), ctx, from, {"mode": "rect", "to": site})
	box_fx._process(SacredSanctuaryFx.T_CAST + 0.05)
	var edge := 0
	for p in box_fx.places:
		var d := p - site
		if is_equal_approx(maxf(absf(d.x) / (SacredSanctuaryFx.RECT.x * 0.5), absf(d.y) / (SacredSanctuaryFx.RECT.y * 0.5)), 1.0):
			edge += 1
	t.check(box_fx.shape == "rect" and edge == box_fx.places.size() and edge == 7, "the rectangle's wall stands along its four sides (%d)" % edge)
	box_fx._process(SacredSanctuaryFx.SPAN + 1.0)
	box_fx.free()
	_done(made)
