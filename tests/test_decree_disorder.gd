extends RefCounted
## Disorder (Decree, Tier III; spec 5.6): for 15 s, in a circle of 5, every choice goes wrong. Nobody is pushed or
## controlled: each one decides, and decides wrongly, at the town's own choice points, which all ask the one law
## (LawZone kind disorder): the frightened run toward the danger (Person._flee_local), a guard goes for the farthest one
## in his sight (Person's fight pick; the Escort type's watchers), no shelter takes anyone in (ShelterManager.try_shelter)
## and the way out is the farthest gate (EvacuationManager.choose). No roll in any of it.

const PATH := "res://src/fx/decree/disorder.gd"
const Kit := preload("res://tests/test_tier2_groundwork.gd")


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


static func run(t) -> void:
	var b := PowerBook.get_power("disorder")
	var area: Dictionary = Targeting.AREAS.get("disorder", {})
	t.check(String(b.get("name", "")) == "Disorder" and int(b.get("dp", 0)) == 3 and float(b.get("cooldown", 0.0)) == 45.0
		and String(b.get("aim", "")) == "click" and not PowerBook.is_quiet("disorder") and PowerBook.authority_of("disorder") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "circle"
		and is_equal_approx(float(area.get("r", 0.0)), 5.0) and Rules.POWER_KINDS.get("disorder", null) == []
		and PowerBook.family("disorder") == "decree" and PowerBook.REACH.has("disorder") and LawZone.DISORDER == &"disorder",
		"Disorder: Decree, 3 Might, 45 s, a click, loud, a circle of 5, kills nobody itself (%s)" % [b])
	var df = load(PATH) if ResourceLoader.exists(PATH) else null
	if df == null:
		t.check(false, "the effect script loads")
		return
	t.check(is_equal_approx(PowerBook.impact("disorder"), float(df.T_LAND) + float(df.T_TOLL)),
		"its danger lands as the crooked bell tolls, after the law (%.2f)" % PowerBook.impact("disorder"))

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	t.check(crowd.citizens[0].crowd == crowd and crowd.soldiers[0].crowd == crowd, "every person knows his crowd (the laws it holds)")

	# --- The law: laid T_LAND after the cast, a circle of 5 for 15 s, then lifted.
	var a: Person = crowd.citizens[0]
	a.ground_pos = at + Vector2(2.0, 0.0)
	var fx = FxTimeline.cast(df, ctx, at)
	t.check(fx.law == null and not crowd.in_law(a, LawZone.DISORDER), "nothing goes wrong until the law lands")
	fx._process(float(df.T_LAND))
	var law: LawZone = fx.law
	t.check(law != null and crowd.laws.has(law) and law.holds(LawZone.DISORDER) and is_equal_approx(law.radius, 5.0)
		and crowd.in_law(a, LawZone.DISORDER), "then the law holds in a circle of 5 round the click")
	var out: Person = crowd.citizens[4]
	out.ground_pos = at + Vector2(0.0, 5.3)
	t.check(not crowd.in_law(out, LawZone.DISORDER), "and not past its edge")

	# --- The frightened run toward the danger inside; away from it outside. The same picks with any rng seed.
	var flee_in := []
	var flee_out := []
	var fight_in := []
	var fight_given := []
	var fight_out := []
	var gate_in := []
	for k in 2:
		var sd := 11 + 977 * k
		var p := _flee(crowd, grid, at, Vector2(2.0, 0.5), Vector2(-1.0, 0.0), sd)
		flee_in.append(p)
		var q := _flee(crowd, grid, at, Vector2(0.0, 8.0), Vector2(1.0, 0.0), sd)
		flee_out.append(q)
		var f := _fight(crowd, at, Vector2(-1.0, -1.0), sd, false)
		fight_in.append(f)
		fight_given.append(_fight(crowd, at, Vector2(-1.0, -1.0), sd, true))
		fight_out.append(_fight(crowd, at, Vector2(-1.0, 9.0), sd, false))
		var ep: Person = crowd.citizens[5]
		ep.rng.seed = sd
		ep.ground_pos = grid.nearest_walkable(at + Vector2(1.0, 1.0))
		gate_in.append(crowd.evac.choose(ep))
	var p0: Array = flee_in[0]
	t.check(p0[3] and p0[1] < p0[0], "inside, a frightened citizen runs toward the danger: his goal %.2f from it, he %.2f" % [p0[1], p0[0]])
	var q0: Array = flee_out[0]
	t.check(not q0[3] and q0[1] > q0[0], "outside, he runs away from it: his goal %.2f from it, he %.2f" % [q0[1], q0[0]])
	t.check(p0[2] == (flee_in[1] as Array)[2], "inside, the same goal with another rng seed (%s, %s)" % [p0[2], (flee_in[1] as Array)[2]])

	# --- A soldier in the circle goes for the farthest of two in his sight (even one set on the nearer); outside, the nearest.
	var f0: Array = fight_in[0]
	t.check(f0[0] == f0[2] and f0[3], "in the circle a soldier goes for the farther of two")
	var g0: Array = fight_given[0]
	t.check(g0[0] == g0[2], "set on the nearer, he swaps him for the farther")
	var o0: Array = fight_out[0]
	t.check(not o0[3] and o0[0] == o0[1], "outside it he goes for the nearer")
	t.check((fight_in[1] as Array)[0] == (fight_in[1] as Array)[2] and (fight_out[1] as Array)[0] == (fight_out[1] as Array)[1],
		"and the same with another rng seed")

	# --- The way out: the farthest gate inside the circle; outside, the town's own best.
	var e: Person = crowd.citizens[5]
	e.ground_pos = grid.nearest_walkable(at + Vector2(1.0, 1.0))
	var ev := crowd.evac
	var far_i := -1
	var far_d := -1
	var best_i := -1
	var best_s := INF
	for k in ev.exits.size():
		var s := ev.score(e, k)
		if s >= INF:
			continue
		var d := ev._dist(k, e.ground_pos)
		if d > far_d:
			far_d = d
			far_i = k
		if s < best_s:
			best_s = s
			best_i = k
	t.check(crowd.in_law(e, LawZone.DISORDER) and far_i >= 0 and far_i != best_i and ev.choose(e) == ev.exits[far_i]
		and gate_in[0] == ev.exits[far_i] and gate_in[1] == gate_in[0],
		"inside, the way out is the farthest gate (%d, not the best %d), whatever the seed" % [far_i, best_i])

	# --- After 15 s the law lifts: every choice goes right again.
	for k in 160:
		fx._process(0.1)
	t.check(not crowd.laws.has(law) and not law.alive() and not crowd.in_law(e, LawZone.DISORDER) and ev.choose(e) == ev.exits[best_i],
		"after 15 s the law lifts, and the way out is the best one again")
	fx.free()

	# --- No shelter takes anyone in inside the circle; the same person at the same door, the law lifted, gets in.
	var sh := _shelter_near(crowd, at)
	var c: Person = crowd.citizens[6]
	c.shelters = crowd.shelters
	c.mind = Person.Mind.CALM
	c.ground_pos = crowd._spot_near(sh.center() + Vector2(0.0, sh.footprint.size.y * 0.5 + 1.2), 0.3)
	var probe := RandomNumberGenerator.new()
	for s in range(1, 60):
		probe.seed = s
		if probe.randf() < ShelterManager.CHANCE_SEVERE:
			c.rng.seed = s
			break
	var shelter_law := LawZone.circle(c.ground_pos, 5.0, [LawZone.DISORDER], 15.0)
	crowd.add_law(shelter_law)
	var from := c.ground_pos + Vector2(4.0, 0.0)
	var refused := not crowd.shelters.try_shelter(c, from, 1.0, &"tornado")
	crowd.remove_law(shelter_law)
	t.check(refused and c.mind == Person.Mind.CALM, "inside, a shelter's door leads back out: try_shelter fails")
	t.check(crowd.shelters.try_shelter(c, from, 1.0, &"tornado") and c.mind == Person.Mind.SHELTER,
		"outside, the same man at the same door with the same seed gets in")
	c.mind = Person.Mind.CALM

	var fx2 = FxTimeline.cast(df, ctx, at)
	fx2._process(float(df.T_LAND))
	var law2: LawZone = fx2.law
	fx2.end_now()
	t.check(law2 != null and not crowd.laws.has(law2) and not law2.alive(), "ended early, it lifts the law")
	fx2.free()
	_done(made)

	_watchers(t)


## A citizen at `at + off` frightened by a danger at `off + toward` (radius 1), his rng seeded `seed`: [his distance from
## the danger, his goal's, the goal, whether he stood in the law].
static func _flee(crowd: Crowd, grid: WalkGrid, at: Vector2, off: Vector2, toward: Vector2, sd: int) -> Array:
	var p: Person = crowd.citizens[1]
	p.shelters = null
	p.mind = Person.Mind.CALM
	p._panic_left = 0.0
	p.rng.seed = sd
	p.ground_pos = grid.nearest_walkable(at + off)
	var threat := p.ground_pos + toward
	var inside := crowd.in_law(p, LawZone.DISORDER)
	p.panic(threat, 1.0, &"")
	var goal := p.goal()
	var out := [p.ground_pos.distance_to(threat), goal.distance_to(threat), goal, inside]
	p.mind = Person.Mind.CALM
	p._goal = Vector2.INF
	return out


## A soldier at `at + off` and two fighting citizens 1 and 2.5 east of him: [his target, the nearer, the farther, whether
## he stood in the law]. `given`: he is set on the nearer first.
static func _fight(crowd: Crowd, at: Vector2, off: Vector2, sd: int, given: bool) -> Array:
	var g: Person = crowd.soldiers[0]
	var near: Person = crowd.citizens[2]
	var far: Person = crowd.citizens[3]
	g.rng.seed = sd
	g.ground_pos = at + off
	near.ground_pos = g.ground_pos + Vector2(1.0, 0.0)
	far.ground_pos = g.ground_pos + Vector2(2.5, 0.0)
	near.fight(null, 20.0, 0.1)
	far.fight(null, 20.0, 0.1)
	g.fight(near if given else null, 20.0, Person.SOLDIER_BLOW, Person.FightRule.HOSTILES)
	g._fight_step(0.0)
	var out := [g.fight_target, near, far, crowd.in_law(g, LawZone.DISORDER)]
	for p: Person in [g, near, far]:
		p.stop_fighting()
		p.mind = Person.Mind.CALM
		p._goal = Vector2.INF
	return out


## The shelter nearest `at`.
static func _shelter_near(crowd: Crowd, at: Vector2) -> Structure:
	var best: Structure = null
	for s: Structure in crowd.shelters.shelters.keys():
		if best == null or s.center().distance_to(at) < best.center().distance_to(at):
			best = s
	return best


## The Escort type's watchers (Exodus's, the Hunt's): a watcher standing in the law passes over the nearer believer in his
## sight and seizes the farther; out of it, he seizes the one he sees.
static func _watchers(t) -> void:
	var s := Kit.world(MissionBook.exodus())
	var d: ExodusDirector = s.d
	var crowd: Crowd = s.crowd
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(40.0, 40.0))
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var near: EscortDirector.Charge = h.members[0]
	var far: EscortDirector.Charge = h.members[1]
	for m: EscortDirector.Charge in h.members:
		if m != near and m != far:
			Kit.arrive(m.man as Person, (m.man as Person).ground_pos + Vector2(20.0, 20.0))
	var w := d.watch[0]
	Kit.arrive(w, (near.man as Person).ground_pos + Vector2(1.0, 0.0))
	Kit.arrive(far.man as Person, w.ground_pos + Vector2(EscortDirector.SIGHT - 0.4, 0.0))
	var plain := d._seen_by(near) == w and d._seen_by(far) == w
	var law := LawZone.circle(w.ground_pos, 5.0, [LawZone.DISORDER], 15.0)
	crowd.add_law(law)
	var wrong := d._seen_by(near) == null and d._seen_by(far) == w
	crowd.remove_law(law)
	t.check(plain and wrong, "a watcher in the law passes over the nearer believer and seizes the farther (out of it: either)")
	Kit.done(s)
