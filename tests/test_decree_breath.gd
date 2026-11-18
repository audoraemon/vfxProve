extends RefCounted
## Breathing Is Prohibited (Decree, Tier I; spec 5.2): the air goes out of a circle of 2.5 for 8 s. Whoever stands inside,
## or walks in, chokes: clutches his throat and runs for the nearest edge. Three seconds inside kills (kill kind choke);
## leaving saves him, and stepping back in starts the three seconds again. Soldiers choke too; hounds and other Visitors
## flee it and never die of it. Inside Leaving Is Prohibited's cell nobody can run: the two together are a sure kill.

const PATH := "res://src/fx/decree/breathing_is_prohibited.gd"
const DT := 0.1


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


## `seconds` of the effects' frames, DT at a time (the people stand where they are unless `walkers` are given, whose
## own frames run too).
static func _run(fxs: Array, seconds: float, walkers: Array = []) -> void:
	var steps := int(roundf(seconds / DT))
	for i in steps:
		for fx: FxTimeline in fxs:
			fx._process(DT)
		for p: Person in walkers:
			if p.is_alive():
				p.frame(DT)


static func run(t) -> void:
	var b := PowerBook.get_power("breath")
	var area: Dictionary = Targeting.AREAS.get("breath", {})
	t.check(String(b.get("name", "")) == "Breathing Is Prohibited" and int(b.get("dp", 0)) == 2 and float(b.get("cooldown", 0.0)) == 25.0
		and String(b.get("aim", "")) == "click" and not PowerBook.is_quiet("breath") and PowerBook.authority_of("breath") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "circle"
		and is_equal_approx(float(area.get("r", 0.0)), 2.5) and Rules.POWER_KINDS.get("breath", []) == [&"choke"]
		and PowerBook.family("breath") == "decree" and PowerBook.REACH.has("breath"),
		"Breathing Is Prohibited: Decree, 2 Might, 25 s, a click, loud, a circle of 2.5, kills by choking (%s)" % [b])

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b2: Person = crowd.citizens[1]
	var guard: Person = crowd.soldiers[0]
	var killed := crowd.killed_citizens + crowd.killed_soldiers
	t.check(is_equal_approx(PowerBook.impact("breath"), BreathFx.T_LAND), "its danger lands when the air goes (%.2f)" % PowerBook.impact("breath"))

	# --- Three seconds inside kills; a soldier chokes like anyone; a hound flees it.
	a.ground_pos = at + Vector2(1.0, 0.0)
	guard.ground_pos = at + Vector2(-1.0, 0.5)
	var visitors := Visitors.new().setup(field, crowd, grid, made[4])
	var hound := visitors.summon(grid.nearest_walkable(at + Vector2(0.0, 1.2)), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	var air: BreathFx = FxTimeline.cast(load(PATH), ctx, at)
	t.check(air.law == null and air.choking.is_empty() and not crowd.in_law(a, LawZone.NO_BREATH), "nothing chokes until the law lands")
	air._process(BreathFx.T_LAND)
	t.check(air.law != null and crowd.laws.has(air.law) and crowd.in_law(a, LawZone.NO_BREATH) and air.choking.has(a)
		and air.choking.has(guard) and not air.choking.has(hound), "then the air goes out: whoever stands inside chokes, a soldier too")
	var far := hound.ground_pos.distance_to(at)
	for k in 29:
		air._process(DT)
		visitors.step(DT)
		far = maxf(far, hound.ground_pos.distance_to(at))
	var goal := a.goal()
	t.check(a.is_alive() and guard.is_alive() and air.choking.has(a) and is_equal_approx(float(air.choking[a]), 2.9)
		and goal != Vector2.INF and goal.distance_to(at) > BreathFx.RADIUS,
		"at 2.9 s he still lives, choking, and makes for the edge (%s, goal %.2f out)" % [a.mind, goal.distance_to(at)])
	t.check(far > BreathFx.RADIUS and hound.is_alive(), "a hound runs out of it (%.2f)" % far)
	air._process(DT)
	visitors.step(DT)
	t.check(not a.is_alive() and a._kind == &"choke" and not guard.is_alive() and guard._kind == &"choke"
		and crowd.killed_citizens + crowd.killed_soldiers == killed + 2 and not air.choking.has(a),
		"at 3.0 s he dies of it (kind %s), the soldier too" % a._kind)
	_run([air], 1.0)
	for k in 10:
		visitors.step(DT)
	t.check(hound.is_alive(), "and the hound never dies of it")
	visitors.clear()
	air.end_now()

	# --- Leaving saves him; stepping back in starts the three seconds again.
	b2.ground_pos = at + Vector2(0.0, 1.0)
	air = FxTimeline.cast(load(PATH), ctx, at)
	air._process(BreathFx.T_LAND)
	_run([air], 2.0)
	t.check(air.choking.has(b2) and b2.is_alive(), "one who walks in chokes too")
	b2.ground_pos = at + Vector2(0.0, BreathFx.RADIUS + 1.0)
	_run([air], 1.5)
	t.check(not air.choking.has(b2) and b2.is_alive(), "one who steps out at 2.0 s lives")
	b2.ground_pos = at + Vector2(0.0, 1.0)
	air._process(0.0)
	t.check(air.choking.has(b2) and is_zero_approx(float(air.choking[b2])), "stepping back in starts his clock at 0")
	_run([air], 2.9)
	t.check(b2.is_alive(), "so he lives 2.9 s after he came back (not 1.0)")
	_run([air], 0.1)
	t.check(not b2.is_alive() and b2._kind == &"choke", "and dies 3.0 s after it")

	# --- After 8 s the air comes back: nobody new chokes.
	var c: Person = crowd.citizens[2]
	_run([air], BreathFx.HOLD_TIME)
	c.ground_pos = at + Vector2(0.5, 0.5)
	_run([air], 3.5)
	t.check(not crowd.in_law(c, LawZone.NO_BREATH) and air.choking.is_empty() and c.is_alive() and not crowd.laws.has(air.law),
		"after 8 s the air comes back, and nobody new chokes")
	air.free()

	# --- Indoors, and one who dies of something else.
	var d: Person = crowd.citizens[3]
	var e: Person = crowd.citizens[4]
	d.ground_pos = at + Vector2(0.5, 0.0)
	d.inside = true
	e.ground_pos = at + Vector2(-0.5, 0.0)
	var air2: BreathFx = FxTimeline.cast(load(PATH), ctx, at)
	air2._process(BreathFx.T_LAND)
	t.check(not air2.choking.has(d) and air2.choking.has(e), "one indoors is left alone")
	field.kill(e, &"stone", at)
	_run([air2], 3.5)
	t.check(d.is_alive() and not air2.choking.has(e) and e._kind == &"stone", "one who dies of something else is dropped")
	d.inside = false
	air2.end_now()
	t.check(not crowd.laws.has(air2.law) and not crowd.in_law(d, LawZone.NO_BREATH) and air2.choking.is_empty(),
		"ended early, it lifts the law")

	# --- Free to run, he runs out and lives.
	var f: Person = crowd.citizens[5]
	f.ground_pos = at + Vector2(1.5, 0.0)
	var air3: BreathFx = FxTimeline.cast(load(PATH), ctx, at)
	air3._process(BreathFx.T_LAND)
	var was_choking := air3.choking.has(f)
	_run([air3], 4.0, [f])
	t.check(was_choking and f.is_alive() and f.ground_pos.distance_to(at) > BreathFx.RADIUS,
		"free to run, he runs out of it and lives (%.2f out)" % f.ground_pos.distance_to(at))
	air3.end_now()

	# --- The combo (spec 5.2): inside Leaving Is Prohibited's cell nobody can run, so everyone in both dies.
	var g: Person = crowd.citizens[6]
	var h: Person = crowd.citizens[7]
	var k2: Person = crowd.citizens[8]
	g.ground_pos = at + Vector2(0.5, 0.0)
	h.ground_pos = at + Vector2(-1.0, 1.0)
	k2.ground_pos = at + Vector2(2.8, 0.0)
	var cell: NoLeaveFx = FxTimeline.cast(load("res://src/fx/decree/leaving_is_prohibited.gd"), ctx, at)
	cell._process(NoLeaveFx.T_SEAL)
	var air4: BreathFx = FxTimeline.cast(load(PATH), ctx, at)
	_run([cell, air4], BreathFx.T_LAND + 1.5, [g, h])
	t.check(g.is_alive() and h.is_alive() and g.is_screaming() and h.is_screaming() and air4.choking.has(g) and air4.choking.has(h)
		and not air4.choking.has(k2), "inside both, they clutch their throats where they stand: there is nowhere to run")
	_run([cell, air4], 1.4, [g, h])
	t.check(g.is_alive() and h.is_alive(), "they live to 2.9 s")
	_run([cell, air4], 0.2, [g, h])
	t.check(not g.is_alive() and not h.is_alive() and g._kind == &"choke" and h._kind == &"choke" and k2.is_alive(),
		"and all inside both die at 3.0 s; one in the cell but outside the breath lives")
	cell.free()
	air4.free()

	# --- (final review) Rooted in the cell, he runs the moment the cell lifts mid-choke: leaving still saves him.
	var m: Person = crowd.citizens[9]
	m.ground_pos = at + Vector2(1.5, 0.0)
	var cell2: NoLeaveFx = FxTimeline.cast(load("res://src/fx/decree/leaving_is_prohibited.gd"), ctx, at)
	cell2._process(NoLeaveFx.T_SEAL)
	var air5: BreathFx = FxTimeline.cast(load(PATH), ctx, at)
	_run([cell2, air5], BreathFx.T_LAND + 0.3, [m])
	var rooted := air5.choking.has(m) and m.is_screaming() and m.ground_pos.distance_to(at) < BreathFx.RADIUS
	cell2._lift()
	_run([air5], 3.0, [m])
	t.check(rooted and m.is_alive() and m.ground_pos.distance_to(at) > BreathFx.RADIUS and not air5.choking.has(m),
		"rooted in the cell, he runs once it lifts mid-choke and lives (%.2f out)" % m.ground_pos.distance_to(at))
	cell2.free()
	air5.free()
	_done(made)
