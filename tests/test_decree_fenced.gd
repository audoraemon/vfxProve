extends RefCounted
## Fenced Rule (Decree, Tier IV; spec 5.8): a fence of iron posts rises round a district of 7 for 30 s, and two of five
## rules hold inside it, for everyone (your faithful too): NO RUNNING (everyone walks), NO ARMS (no guard strikes or
## seizes), NO DOORS (nobody goes into or out of a building), NO SIGHT (nobody sees farther than 2) and NO LEAVING (as
## Leaving Is Prohibited, at the fence). The ten pairs are ten modes (Q/E). One law (LawZone) of the two kinds; the
## town's own choice points ask it (Crowd.in_law(), Crowd.sight()).

const PATH := "res://src/fx/decree/fenced_rule.gd"
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const RULES := ["run", "arms", "doors", "sight", "leave"]
const WORDS := {"run": "NO RUNNING", "arms": "NO ARMS", "doors": "NO DOORS", "sight": "NO SIGHT", "leave": "NO LEAVING"}


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
	var b := PowerBook.get_power("fenced")
	var area: Dictionary = Targeting.AREAS.get("fenced", {})
	t.check(String(b.get("name", "")) == "Fenced Rule" and int(b.get("dp", 0)) == 5 and float(b.get("cooldown", 0.0)) == 80.0
		and String(b.get("aim", "")) == "click" and not PowerBook.is_quiet("fenced") and PowerBook.authority_of("fenced") == "decree"
		and ResourceLoader.exists(String(b.get("path", ""))) and String(area.get("shape", "")) == "circle"
		and is_equal_approx(float(area.get("r", 0.0)), 7.0) and Rules.POWER_KINDS.get("fenced", null) == []
		and PowerBook.family("fenced") == "decree" and PowerBook.REACH.has("fenced"),
		"Fenced Rule: Decree, 5 Might, 80 s, a click, loud, a circle of 7, kills nobody itself (%s)" % [b])
	t.check(LawZone.NO_RUNNING == &"no_running" and LawZone.NO_ARMS == &"no_arms" and LawZone.NO_DOORS == &"no_doors"
		and LawZone.NO_SIGHT == &"no_sight" and is_equal_approx(LawZone.SIGHT_CAP, 2.0), "the four new kinds of law, and NO SIGHT's 2")

	# --- Ten modes, each a distinct pair of the five rules, named for its two rules.
	var modes: Array = b.get("modes", [])
	var pairs := {}
	var named := true
	for m: Dictionary in modes:
		var parts := String(m.key).split("_")
		if parts.size() != 2 or not RULES.has(parts[0]) or not RULES.has(parts[1]) or parts[0] == parts[1] \
				or RULES.find(parts[0]) > RULES.find(parts[1]):
			named = false
			continue
		pairs[String(m.key)] = true
		named = named and String(m.name) == "%s + %s" % [WORDS[parts[0]], WORDS[parts[1]]]
	t.check(modes.size() == 10 and pairs.size() == 10 and named, "ten modes, each a distinct pair of the five rules (%s)" % [modes])
	t.check(String(modes[0].key) == "run_arms" and String(modes[9].key) == "sight_leave", "in order: run_arms first, sight_leave last")

	var df = load(PATH) if ResourceLoader.exists(PATH) else null
	if df == null:
		t.check(false, "the effect script loads")
		return
	t.check(is_equal_approx(PowerBook.impact("fenced"), float(df.T_LAND)), "its danger lands as the posts are driven in (%.2f)" % PowerBook.impact("fenced"))
	var mapped := true
	for m: Dictionary in modes:
		var parts := String(m.key).split("_")
		var kinds: Array[StringName] = df.kinds_of(String(m.key))
		mapped = mapped and kinds.size() == 2 and kinds[0] == df.KINDS[parts[0]] and kinds[1] == df.KINDS[parts[1]]
	t.check(mapped and df.KINDS["leave"] == LawZone.NO_LEAVING and df.KINDS["run"] == LawZone.NO_RUNNING,
		"each mode lays its own two kinds of law")

	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.shelters = null
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- NO RUNNING + NO ARMS: laid T_LAND after the cast, a circle of 7.
	var runner: Person = crowd.citizens[0]
	runner.ground_pos = grid.nearest_walkable(at + Vector2(2.0, 1.0))
	var fx = FxTimeline.cast(df, ctx, at, {"mode": "run_arms"})
	t.check(fx.law == null and not crowd.in_law(runner, LawZone.NO_RUNNING), "no rule holds until the posts are in")
	fx._process(float(df.T_LAND))
	var law: LawZone = fx.law
	t.check(law != null and crowd.laws.has(law) and law.kinds == [LawZone.NO_RUNNING, LawZone.NO_ARMS] and is_equal_approx(law.radius, 7.0)
		and is_equal_approx(law.left, 30.0), "then NO RUNNING and NO ARMS hold in a circle of 7 for 30 s")

	# A soldier inside does not strike a fighting citizen next to him; one outside does.
	var struck_in := _strike(crowd, at + Vector2(-1.0, -1.0))
	var struck_out := _strike(crowd, at + Vector2(0.0, 9.0))
	t.check(not struck_in and struck_out, "NO ARMS: a soldier inside does not strike the citizen next to him (outside: he does)")

	# A runner inside moves at a walk; one outside runs.
	runner.panic(runner.ground_pos + Vector2(1.0, 0.0), 1.0, &"", false)
	var free_runner: Person = crowd.citizens[1]
	free_runner.ground_pos = grid.nearest_walkable(at + Vector2(0.0, 9.5))
	free_runner.panic(free_runner.ground_pos + Vector2(1.0, 0.0), 1.0, &"", false)
	t.check(runner.walk_speed > Person.WALK_SPEED * runner.pace + 0.01, "a frightened man runs (%.2f)" % runner.walk_speed)
	fx._process(0.1)
	t.check(runner.mind == Person.Mind.PANIC and runner.walk_speed <= Person.WALK_SPEED * runner.pace + 0.001 and runner.pace_hold() < 1.0,
		"NO RUNNING: frightened inside, he only walks (%.2f)" % runner.walk_speed)
	t.check(free_runner.walk_speed > Person.WALK_SPEED * free_runner.pace + 0.01, "outside the fence one runs (%.2f)" % free_runner.walk_speed)
	var walker: Person = crowd.citizens[2]
	walker.ground_pos = grid.nearest_walkable(at + Vector2(-2.0, 1.0))
	walker.mind = Person.Mind.CALM
	walker.walk_speed = walker._mind_speed()
	var calm_speed := walker.walk_speed
	fx._process(0.1)
	t.check(is_equal_approx(walker.walk_speed, calm_speed), "one already walking walks on at his own pace")
	runner.ground_pos = grid.nearest_walkable(at + Vector2(0.0, 10.0))
	fx._process(0.1)
	t.check(runner.pace_holds.is_empty() and runner.walk_speed > Person.WALK_SPEED * runner.pace + 0.01, "out of the fence he runs again")
	runner.ground_pos = grid.nearest_walkable(at + Vector2(2.0, 1.0))
	fx._process(0.1)
	t.check(not runner.pace_holds.is_empty(), "back in, he walks again")

	# --- After 30 s every rule lifts and every pace hold is let go.
	for k in 310:
		fx._process(0.1)
	t.check(not crowd.laws.has(law) and not law.alive() and not crowd.in_law(runner, LawZone.NO_RUNNING)
		and runner.pace_holds.is_empty() and walker.pace_holds.is_empty() and law.paced.is_empty(),
		"after 30 s both rules lift and every pace hold is let go")
	t.check(_strike(crowd, at + Vector2(-1.0, -1.0)), "and a soldier there strikes again")
	fx.free()

	# --- Ended early: it lifts the law and lets go of the paces.
	runner.mind = Person.Mind.CALM
	runner.panic(runner.ground_pos + Vector2(1.0, 0.0), 1.0, &"", false)
	var fx2 = FxTimeline.cast(df, ctx, at, {"mode": "doors_leave"})
	fx2._process(float(df.T_LAND) + 0.1)
	var law2: LawZone = fx2.law
	t.check(law2 != null and law2.kinds == [LawZone.NO_DOORS, LawZone.NO_LEAVING] and runner.pace_holds.is_empty(),
		"NO DOORS + NO LEAVING lays those two, and holds nobody's pace")
	fx2.end_now()
	t.check(not crowd.laws.has(law2) and not law2.alive(), "ended early, it lifts the law")
	fx2.free()
	var fx3 = FxTimeline.cast(df, ctx, at, {"mode": "run_sight"})
	fx3._process(float(df.T_LAND) + 0.1)
	var held := not runner.pace_holds.is_empty()
	fx3.end_now()
	t.check(held and runner.pace_holds.is_empty(), "ended early, its pace holds are let go")
	fx3.free()
	runner.mind = Person.Mind.CALM

	# --- NO SIGHT: a guard 3 off does not see a wanted man inside; a guard's fight pick at 2.8 finds no one.
	var guard: Person = crowd.soldiers[0]
	var wanted: Person = crowd.citizens[3]
	wanted.ground_pos = at
	guard.ground_pos = at + Vector2(3.0, 0.0)
	guard.mind = Person.Mind.POST
	LawMark.set_law(wanted, LawMark.CRIMINAL, 10.0, 991)
	var blind := LawZone.circle(at, 7.0, [LawZone.NO_SIGHT, LawZone.NO_LEAVING], 30.0)
	crowd.add_law(blind)
	wanted.law._hunt(wanted)
	var unseen := guard.mind != Person.Mind.FIGHT
	t.check(is_equal_approx(crowd.sight(guard, wanted.ground_pos, 3.0), 2.0) and unseen,
		"NO SIGHT: a guard 3 off does not see the man the law calls criminal")
	var fighter: Person = crowd.citizens[4]
	fighter.ground_pos = at + Vector2(0.0, 2.8)
	fighter.fight(null, 20.0, 0.1)
	var g2: Person = crowd.soldiers[1]
	g2.ground_pos = at
	g2.fight(null, 20.0, Person.SOLDIER_BLOW, Person.FightRule.HOSTILES)
	g2._fight_step(0.0)
	var picked_in := g2.fight_target
	# --- NO LEAVING: one at the fence walking out is set back on it.
	var leaver: Person = crowd.citizens[5]
	leaver.ground_pos = at + Vector2(6.9, 0.0)
	crowd.step_laws(0.0)
	leaver.ground_pos = at + Vector2(7.4, 0.0)
	crowd.step_laws(0.1)
	t.check(leaver.ground_pos.distance_to(at) <= 7.0 + 0.01, "NO LEAVING: one at the fence cannot walk out (%.2f)" % leaver.ground_pos.distance_to(at))
	crowd.remove_law(blind)
	wanted.law._hunt(wanted)
	t.check(guard.mind == Person.Mind.FIGHT and guard.fight_target == wanted, "out of the law, the guard 3 off goes for him")
	g2._retarget_in = 0.0
	g2._fight_step(0.0)
	t.check(picked_in == null and g2.fight_target == fighter, "a guard's fight pick sees no one 2.8 off under NO SIGHT, and does without it")
	LawMark.lift(wanted, 991)
	for p: Person in [guard, g2, fighter]:
		p.stop_fighting()
		p.mind = Person.Mind.CALM
		p._goal = Vector2.INF

	# --- NO DOORS: nobody goes into a building, and nobody inside comes out while it holds.
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
	var doors := LawZone.circle(sh.center(), 7.0, [LawZone.NO_DOORS, LawZone.NO_ARMS], 30.0)
	crowd.add_law(doors)
	var from := c.ground_pos + Vector2(4.0, 0.0)
	var refused := not crowd.shelters.try_shelter(c, from, 1.0, &"tornado")
	var e: Dictionary = crowd.shelters.shelters[sh]
	var in_man: Person = crowd.citizens[7]
	in_man.mind = Person.Mind.SHELTER
	in_man.shelter = sh
	in_man.shelter_door = c.ground_pos
	(e.inside as Array).append(in_man)
	crowd.shelters._enter(in_man, sh)
	e.clear = ShelterManager.CLEAR_SECONDS + 1.0
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.5)
	var stayed := in_man.inside
	var sent := crowd.shelters.send_in(c, sh)
	crowd.remove_law(doors)
	t.check(refused and c.mind == Person.Mind.CALM and not sent, "NO DOORS: no building takes anyone in")
	t.check(stayed, "NO DOORS: one inside a building does not come out while it holds")
	e.clear = ShelterManager.CLEAR_SECONDS + 1.0
	crowd.shelters._step_in = 0.0
	crowd.shelters.step(0.5)
	t.check(not in_man.inside, "the law lifted, he comes out")
	t.check(crowd.shelters.try_shelter(c, from, 1.0, &"tornado") and c.mind == Person.Mind.SHELTER,
		"and the same man at the same door with the same seed gets in")
	_done(made)

	_watchers(t)


## A soldier at `g_at` and a fighting citizen 0.3 east of him, set on him; one swing: whether the citizen was struck.
static func _strike(crowd: Crowd, g_at: Vector2) -> bool:
	var g: Person = crowd.soldiers[2]
	var c: Person = crowd.citizens[8]
	g.ground_pos = g_at
	c.ground_pos = g_at + Vector2(0.3, 0.0)
	c.health = 100.0
	c.fight(null, 20.0, 0.1)
	g.fight(c, 20.0, Person.SOLDIER_BLOW, Person.FightRule.HOSTILES)
	var before := c.health
	g._fight_step(0.0)
	var struck := c.health < before
	for p: Person in [g, c]:
		p.stop_fighting()
		p.mind = Person.Mind.CALM
		p._goal = Vector2.INF
		p.health = 100.0
	return struck


## The shelter nearest `at`.
static func _shelter_near(crowd: Crowd, at: Vector2) -> Structure:
	var best: Structure = null
	for s: Structure in crowd.shelters.shelters.keys():
		if best == null or s.center().distance_to(at) < best.center().distance_to(at):
			best = s
	return best


## The Escort type's watchers (Exodus's, the Hunt's): under NO ARMS a watcher next to a believer does not seize him; under NO
## SIGHT one 2.3 off does not see him (one 1.5 off does); a Faithful 3 off does not see a fall inside; and a believer -- the
## god's own -- is bound too: frightened inside NO RUNNING, he walks.
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
	for m: EscortDirector.Charge in h.members:
		if m != near:
			Kit.arrive(m.man as Person, (m.man as Person).ground_pos + Vector2(20.0, 20.0))
	var w := d.watch[0]
	var man := near.man as Person
	Kit.arrive(w, man.ground_pos + Vector2(1.0, 0.0))
	var plain := d._seen_by(near) == w
	var arms := LawZone.circle(w.ground_pos, 7.0, [LawZone.NO_ARMS, LawZone.NO_SIGHT], 30.0)
	crowd.add_law(arms)
	var disarmed := d._seen_by(near) == null
	crowd.remove_law(arms)
	t.check(plain and disarmed, "NO ARMS: a watcher next to a believer does not seize him (without it: he does)")
	Kit.arrive(w, man.ground_pos + Vector2(2.3, 0.0))
	var far_plain := d._seen_by(near) == w
	var blind := LawZone.circle(man.ground_pos, 7.0, [LawZone.NO_SIGHT, LawZone.NO_DOORS], 30.0)
	crowd.add_law(blind)
	var far_blind := d._seen_by(near) == null
	Kit.arrive(w, man.ground_pos + Vector2(1.5, 0.0))
	var near_blind := d._seen_by(near) == w
	# A Faithful 3 off a fall inside does not see it; out of the law he does.
	var f: Person = null
	for p in crowd.citizens:
		if p != man and p.is_alive() and not p.inside and not d.faithful.has(p):
			f = p
			break
	var fall_at := man.ground_pos + Vector2(0.0, 0.5)
	Kit.arrive(f, fall_at + Vector2(3.0, 0.0))
	f.mind = Person.Mind.CALM
	var sees_blind := d._sees(f, fall_at, 4.0, null)
	crowd.remove_law(blind)
	var sees_plain := d._sees(f, fall_at, 4.0, null)
	t.check(far_plain and far_blind and near_blind, "NO SIGHT: a watcher 2.3 off does not see the believer; 1.5 off he does")
	t.check(sees_plain and not sees_blind, "NO SIGHT: one 3 off does not see a fall inside (without it: he does)")
	# The god's own are bound too: a believer frightened inside NO RUNNING walks.
	man.shelters = null
	man.mind = Person.Mind.CALM
	man.fearless_left = 0.0
	man._shaken_left = 0.0
	man.panic(man.ground_pos + Vector2(1.0, 0.0), 1.0, &"", false)
	var ran := man.walk_speed > Person.WALK_SPEED * man.pace + 0.01
	var walk := LawZone.circle(man.ground_pos, 7.0, [LawZone.NO_RUNNING, LawZone.NO_LEAVING], 30.0)
	crowd.add_law(walk)
	crowd.step_laws(0.1)
	var walked := man.walk_speed <= Person.WALK_SPEED * man.pace + 0.001
	crowd.remove_law(walk)
	t.check(ran and walked and man.pace_holds.is_empty(), "a believer is bound too: frightened inside NO RUNNING he walks, and runs once it lifts")
	Kit.done(s)
