extends RefCounted
## Anathema, level 5: Spreading Mark (SPREAD_AT s after the marks are laid, the mark leaps to buildings within
## SPREAD_R of a marked one's footprint -- once).


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


## Five new buildings in an empty corner: A (house) at the district's edge; B 2.5 off A's footprint on the far side,
## C 3.5 above A, D 2.5 past B (3 from B only), a Citadel keep 2.0 below A. Returns the dictionary of them and the click.
static func _block(made: Array, radius: float) -> Dictionary:
	var env: EnvironmentField = made[1]
	var ax := 4.0
	var ay := 24.0
	var a := env.add_structure(Rect2(ax, ay, 2.0, 2.0), 12.0, Structure.Kind.HOUSE, &"house")
	var b := env.add_structure(Rect2(ax + 2.0 + 2.5, ay, 2.0, 2.0), 12.0, Structure.Kind.HOUSE, &"house")
	var c := env.add_structure(Rect2(ax, ay - 3.5 - 2.0, 2.0, 2.0), 12.0, Structure.Kind.HOUSE, &"house")
	var d := env.add_structure(Rect2(ax + 2.0 + 2.5 + 2.0 + 2.5, ay, 2.0, 2.0), 12.0, Structure.Kind.HOUSE, &"house")
	var cit := env.add_structure(Rect2(ax, ay + 2.0 + 2.0, 2.0, 2.0), 12.0, Structure.Kind.KEEP, &"citadel")
	return {"a": a, "b": b, "c": c, "d": d, "cit": cit, "click": a.center() - Vector2(radius - 0.5, 0.0)}


static func run(t) -> void:
	t.check(not AnathemaFx.MARKED.has(&"citadel"), "the Citadel's role is not one a mark lands on")
	for mode in ["cursed", "hallowed", "level4"]:
		var made := _setup()
		var crowd: Crowd = made[0]
		var ctx: FxContext = made[5]
		var i := 0
		for person in crowd.citizens + crowd.soldiers:
			person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
			person.mind = Person.Mind.CALM
			i += 1
		var level := 4 if mode == "level4" else 5
		var radius := float(PowerBook.stat({"level": level}, "anathema", "RADIUS", AnathemaFx.RADIUS))
		var s := _block(made, radius)
		var a: Structure = s.a
		var b: Structure = s.b
		var c: Structure = s.c
		var d: Structure = s.d
		var cit: Structure = s.cit
		var citizen: Person = crowd.citizens[0]
		citizen.ground_pos = b.center() + Vector2(0.0, 2.0)
		var indoors: Person = crowd.citizens[1]
		indoors.ground_pos = b.center() + Vector2(0.5, 2.0)
		indoors.inside = true
		var fx: AnathemaFx = FxTimeline.cast(load("res://src/fx/dominion/anathema.gd"), ctx, s.click,
			{"mode": "hallowed" if mode == "hallowed" else "cursed", "level": level})
		fx._process(AnathemaFx.T_CAST + 0.05)
		var kind := AnathemaFx.HALLOWED if mode == "hallowed" else AnathemaFx.CURSED
		t.check(crowd.structure_mark(a) == kind and crowd.structure_mark(b) == &"" and crowd.structure_mark(c) == &"" and fx.buildings.has(a)
			and not fx.buildings.has(b) and not fx.buildings.has(c), "%s: the first marks are today's (A marked; B, C beyond the district)" % mode)
		fx._process(AnathemaFx.T_CAST + AnathemaFx.SPREAD_AT - 1.1)
		t.check(crowd.structure_mark(b) == &"" and fx.spread.is_empty(), "%s: just before the spread B is unmarked" % mode)
		var moved_before := fx.moved
		crowd._clock += AnathemaFx.SPREAD_AT
		fx._process(0.2)
		if mode == "level4":
			t.check(crowd.structure_mark(b) == &"" and fx.spread.is_empty() and not fx.buildings.has(b), "level 4: nothing spreads (%d buildings, %d spread)" % [fx.buildings.size(), fx.spread.size()])
		else:
			t.check(crowd.structure_mark(b) == kind and fx.spread.has(b) and fx.buildings.has(b), "%s: the mark leaps to B (2.5 from A) (spread %d, buildings %d, B %s)" % [mode, fx.spread.size(), fx.buildings.size(), crowd.structure_mark(b)])
			t.check(crowd.structure_mark(c) == &"" and crowd.structure_mark(d) == &"" and crowd.structure_mark(cit) == &"",
				"%s: not to C (3.5 off), not on to D (the spread ones do not spread), not to the Citadel" % mode)
			var span := fx.lv_span
			crowd._clock = span - 0.5
			t.check(crowd.structure_mark(b) == kind and crowd.structure_mark(a) == kind, "%s: B holds until the span the first marks do" % mode)
			crowd._clock = span + 0.5
			t.check(crowd.structure_mark(b) == &"" and crowd.structure_mark(a) == &"", "%s: and lifts with them" % mode)
		if mode == "hallowed":
			t.check(citizen.compel_glyph == DominionParts.HALO and citizen.mind == Person.Mind.COMPELLED and citizen.goal().distance_to(b.center()) < 4.0,
				"hallowed: a citizen 1.0 from B is sent to it at the spread")
			t.check(indoors.mind != Person.Mind.COMPELLED and fx.moved - moved_before == 1, "hallowed: one already inside near B is not sent again (%d moved)" % (fx.moved - moved_before))
		fx.free()
		_done(made)
