extends RefCounted
## Tier I of Ruin and Death. Smite: one bolt takes whoever stands there and deals one building a blow, not its fall.
## Ember: one spark lights the nearest thing that burns. Death Mark: one grows frail and slow, dies when the mark comes
## due, lies where it fell, and draws the people about to look.


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
	var problems := []
	for key: String in ["smite", "ember", "deathmark"]:
		var b := PowerBook.get_power(key)
		if int(b.dp) != 1 or PowerBook.icon(key) == null or PowerBook.hud_icon(key) == null or PowerBook.clip(key) == null \
				or not ResourceLoader.exists(String(b.path)) or not Targeting.AREAS.has(key) or not Rules.POWER_KINDS.has(key):
			problems.append(key)
	t.check(problems.is_empty() and PowerBook.authority_of("smite") == "ruin" and PowerBook.authority_of("ember") == "ruin"
		and PowerBook.authority_of("deathmark") == "death" and PowerBook.authority_of("pestilence") == "death"
		and not PowerBook.is_quiet("smite") and PowerBook.is_quiet("ember") and PowerBook.is_quiet("deathmark"),
		"Smite and Ember are Ruin's 1 DP, Death Mark Death's, each with its effect, icons, clip, area and kills (%s)" % [problems])

	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	var guard: Person = crowd.soldiers[0]

	# --- Smite
	a.ground_pos = at + Vector2(0.3, 0.0)
	guard.ground_pos = at - Vector2(0.3, 0.0)
	b.ground_pos = at + Vector2(SmiteFx.KILL_R + 0.4, 0.0)
	var shed := env.add_structure(Rect2(at + Vector2(-0.3, 0.3), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	var hp := shed.hp
	var smite: SmiteFx = FxTimeline.cast(load("res://src/fx/ruin/smite.gd"), ctx, at)
	t.check(a.is_alive() and smite.busy < 0.0, "Smite: nothing falls until the bolt lands")
	smite._process(SmiteFx.T_STRIKE + 0.05)
	t.check(not a.is_alive() and not guard.is_alive() and a._kind == &"lightning" and smite.struck == 2 and b.is_alive(),
		"the bolt takes whoever stands there, a soldier too, and nobody a step away")
	t.check(not shed.destroyed and is_equal_approx(hp - shed.hp, SmiteFx.DAMAGE), "and deals a building one blow, not its fall (%.0f of %.0f)" % [hp - shed.hp, hp])
	t.check(crowd.fires.is_burning(shed), "lightning may set it alight")
	smite._process(3.0)
	smite.free()
	crowd.fires.clear()

	# --- Ember
	var barn := env.add_structure(Rect2(at + Vector2(4.0, 0.0), Vector2(0.8, 0.8)), 18.0, Structure.Kind.HOUSE, &"house")
	t.check(EmberFx.target(env, barn.center()) == barn and EmberFx.target(env, Vector2(200.0, 200.0)) == null,
		"Ember looks for the nearest thing that burns within its reach")
	var ember: EmberFx = FxTimeline.cast(load("res://src/fx/ruin/ember.gd"), ctx, barn.center())
	t.check(ember.fuel == barn and not crowd.fires.is_burning(barn), "the spark is falling; nothing burns yet")
	var alarm := crowd.alarm
	ember._process(EmberFx.T_LAND + 0.05)
	t.check(ember.lit and crowd.fires.is_burning(barn) and is_equal_approx(crowd.fires.intensity(barn), EmberFx.START_LEVEL) and not barn.destroyed,
		"it lands and the building is alight, whole")
	t.check(crowd.alarm == alarm, "one spark raises no alarm of its own")
	ember._process(3.0)
	ember.free()
	crowd.fires.clear()

	# --- Death Mark
	var marked: Person = crowd.citizens[2]
	var near: Array[Person] = []
	marked.ground_pos = at + Vector2(0.0, 6.0)
	marked.mind = Person.Mind.CALM
	for k in 4:
		var q: Person = crowd.citizens[10 + k]
		q.ground_pos = grid.nearest_walkable(marked.ground_pos + Vector2(1.5 + 0.4 * float(k), 0.5))
		q.mind = Person.Mind.CALM
		near.append(q)
	var pace := marked._mind_speed()
	var dead := crowd.killed_citizens
	var mark: DeathMarkFx = FxTimeline.cast(load("res://src/fx/death/death_mark.gd"), ctx, marked.ground_pos)
	t.check(mark.marked == marked and marked.is_alive() and marked.statuses.has(&"frail") and marked.badge_left > 0.0
		and is_equal_approx(marked._mind_speed(), pace * DeathMarkFx.SLOW), "Death Mark: the one at the click grows frail and slow, and lives")
	t.check(crowd.threats.active_count() == 0, "nobody sees it laid")
	mark._process(DeathMarkFx.MARK_TIME - 0.2)
	t.check(marked.is_alive(), "it lives out its ten seconds")
	mark._process(0.3)
	t.check(not marked.is_alive() and marked._kind == &"deathmark" and crowd.killed_citizens == dead + 1 and mark.body_at != Vector2.INF,
		"then the mark comes due: a death the town counts")
	marked.tick(DummyEnemy.DEATH_FADE + 1.0)
	t.check(is_instance_valid(marked) and marked.modulate.a > 0.9, "the body lies where it fell, not fading yet")
	mark._process(0.6)
	var looking := 0
	for q in near:
		if q.mind == Person.Mind.OBSERVE and q.goal().distance_to(mark.body_at) <= DeathMarkFx.RING.y + 0.1:
			looking += 1
	t.check(looking == 4 and mark.gawked == 4, "and the people about walk over to look (%d)" % looking)
	mark.free()

	# The frail fall to any blow; one inside when the mark comes due is spared.
	var frail: Person = crowd.citizens[3]
	frail.ground_pos = at + Vector2(0.0, -6.0)
	mark = FxTimeline.cast(load("res://src/fx/death/death_mark.gd"), ctx, frail.ground_pos)
	frail.hurt(0.05, null)
	t.check(not frail.is_alive(), "the frail fall to any blow before the mark comes due")
	mark._process(DeathMarkFx.MARK_TIME + 0.1)
	mark.free()
	var hidden: Person = crowd.citizens[4]
	hidden.ground_pos = at + Vector2(6.0, -6.0)
	mark = FxTimeline.cast(load("res://src/fx/death/death_mark.gd"), ctx, hidden.ground_pos)
	hidden.inside = true
	mark._process(DeathMarkFx.MARK_TIME + 0.1)
	t.check(hidden.is_alive() and not hidden.statuses.has(&"frail") and mark.body_at == Vector2.INF, "one behind a door when it comes due is spared")
	hidden.inside = false
	mark._process(1.0)
	mark.free()
	_done(made)
