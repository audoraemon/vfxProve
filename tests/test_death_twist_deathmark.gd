extends RefCounted
## Death Mark level 5, The Wake (Death and Decree ability levels, Task 2): the first gawker to stand at the body sees it get up as a
## Raise the Dead zombie (level-1 numbers, the body used up, CHAIN 3 for this cast alone). Levels 1-4 raise nothing; the rising is
## quiet; a body another power took first raises nothing and breaks nothing.

const DT := 0.05
const SCRIPT := "res://src/fx/death/death_mark.gd"


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
	ctx.world = world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, grid, ctx, world, field]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[2]
	ctx.overhead.free()
	ctx.ground.free()
	(made[3] as Node).free()


## Everyone far off in a corner, calm.
static func _clear_town(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		if not person.is_alive():
			continue
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		i += 1


static func _spot(made: Array) -> Vector2:
	return (made[1] as WalkGrid).nearest_walkable(TownLayout.MARKET_SQUARE.get_center())


## A cast at `level` on the nth citizen, with `looks` people about it; the mark runs to its death and the first look (0.5 s later).
## Returns [fx, marked, lookers].
static func _cast(made: Array, level: int, n: int, spot: Vector2, looks := 2) -> Array:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[2]
	var marked: Person = crowd.citizens[n]
	marked.ground_pos = spot
	marked.mind = Person.Mind.CALM
	var lookers: Array[Person] = []
	for k in looks:
		var q: Person = crowd.citizens[20 + k]
		q.ground_pos = (made[1] as WalkGrid).nearest_walkable(spot + Vector2(2.0 + 0.4 * float(k), 0.5))
		q.mind = Person.Mind.CALM
		lookers.append(q)
	var fx: DeathMarkFx = FxTimeline.cast(load(SCRIPT), ctx, spot, {"level": level})
	fx._process(fx.lv_mark_time + 0.05)
	fx._process(0.6)  # the first look: the people about are drawn over
	return [fx, marked, lookers]


## `who` stands `near_by` from the body; one step of the effect.
static func _arrive(fx: DeathMarkFx, who: Person, near_by := 0.5) -> void:
	who.ground_pos = fx.body_at + Vector2(near_by, 0.0)
	fx._process(DT)


static func run(t) -> void:
	_raises(t)
	_before_five(t)
	_chain(t)
	_hunts(t)
	_gone(t)
	_quiet(t)
	_sick(t)
	_unlured(t)
	_overlap(t)


static func _raises(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	_clear_town(crowd)
	var c := _cast(made, 5, 2, _spot(made))
	var fx: DeathMarkFx = c[0]
	var marked: Person = c[1]
	var lookers: Array[Person] = c[2]
	t.check(fx._twist and fx.lv_mark_time == 8.0 and not marked.is_alive() and fx.body_at != Vector2.INF, "the Wake: a level 5 mark is cast and comes due")
	t.check(fx.visitors == null and crowd.remains.pick(fx.body_at) != null, "no gawker stands at the body yet: nothing has risen")
	t.check(fx.gawked == 2 and lookers.size() == 2, "the crowd is drawn as before (%d)" % fx.gawked)
	lookers[0].ground_pos = fx.body_at + Vector2(1.8, 0.0)
	fx._process(DT)
	t.check(fx.visitors == null, "a gawker 1.8 away is not at the body")
	var before_dur := fx.duration
	_arrive(fx, lookers[1], 0.9)
	t.check(fx.visitors != null and fx.visitors.living().size() == 1 and fx.raised == 1, "the first gawker within 1.0 sees it get up: one zombie")
	var z: Animal = fx.visitors.living()[0]
	t.check(z.ground_pos.distance_to(fx.body_at) < 0.3 and z.breed == Animal.Breed.ZOMBIE, "it stands at the body, a zombie")
	t.check(crowd.remains.pick(fx.body_at) == null, "the remain is taken")
	t.check(fx.duration >= fx.t + RaiseTheDeadFx.ZOMBIE_LIFE and fx.duration > before_dur, "the effect lasts the zombie's 30 s")
	fx.end_now()
	t.check(fx.visitors.living().is_empty() and crowd.visitors.is_empty(), "the zombie goes with the effect")
	fx.free()
	_done(made)


static func _before_five(t) -> void:
	for lv in [1, 4]:
		var made := _setup()
		var crowd: Crowd = made[0]
		crowd.remains.enabled = true
		_clear_town(crowd)
		var c := _cast(made, lv, 2, _spot(made))
		var fx: DeathMarkFx = c[0]
		var lookers: Array[Person] = c[2]
		_arrive(fx, lookers[0], 0.5)
		fx._process(1.0)
		t.check(fx.visitors == null and not fx._twist and crowd.remains.pick(fx.body_at) != null and crowd.visitors.is_empty(),
			"level %d: a gawker at the body raises nothing" % lv)
		fx.free()
		_done(made)
	# The twist adds no draw: a level 4 and a level 5 cast leave the same rng state up to the rising.
	var states: Array[int] = []
	for lv in [4, 5]:
		var made := _setup()
		_clear_town(made[0])
		var c := _cast(made, lv, 2, _spot(made))
		states.append((made[2] as FxContext).rng.state)
		(c[0] as Node).free()
		_done(made)
	t.check(states[0] == states[1], "the twist draws no random number")


static func _chain(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[4]
	crowd.remains.enabled = true
	_clear_town(crowd)
	var c := _cast(made, 5, 2, _spot(made))
	var fx: DeathMarkFx = c[0]
	_arrive(fx, (c[2] as Array)[0], 0.5)
	var z: Animal = fx.visitors.living()[0]
	# Four kills by its bite, each where it stands: only 2 more rise (CHAIN 3 in all).
	for k in 4:
		var v: Person = crowd.citizens[40 + k]
		v.ground_pos = z.ground_pos + Vector2(0.4, 0.0)
		field.kill(v, &"frenzy")
		fx._on_bite(z, v, false)
	t.check(fx.raised == 3 and fx.visitors.living().size() == 3, "its kills raise at most 2 more (%d, %d standing)" % [fx.raised, fx.visitors.living().size()])
	fx.end_now()
	fx.free()
	_done(made)


## Two level-5 casts overlap: the first to end leaves the ledger on for the second; after both it is off.
static func _overlap(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	_clear_town(crowd)
	var spot := _spot(made)
	var a := _cast(made, 5, 2, spot)
	var fa: DeathMarkFx = a[0]
	t.check(crowd.remains.enabled, "overlap: the first cast lights the ledger")
	# The second is cast at once (its person is not dead yet) a little way off.
	var second: Person = crowd.citizens[3]
	var spot2 := (made[1] as WalkGrid).nearest_walkable(spot + Vector2(8.0, 0.0))
	second.ground_pos = spot2
	second.mind = Person.Mind.CALM
	var gaw: Person = crowd.citizens[30]
	gaw.ground_pos = (made[1] as WalkGrid).nearest_walkable(spot2 + Vector2(2.0, 0.5))
	gaw.mind = Person.Mind.CALM
	var fb: DeathMarkFx = FxTimeline.cast(load(SCRIPT), made[2], spot2, {"level": 5})
	t.check(fb.marked == second and second.is_alive(), "overlap: the second is cast while the first's body already lies")
	fa.end_now()
	t.check(crowd.remains.enabled, "overlap: the first ends and the ledger stays on")
	fb._process(fb.lv_mark_time + 0.05)
	fb._process(0.6)
	t.check(crowd.remains.pick(fb.body_at) != null, "overlap: the second's body is still written down")
	_arrive(fb, gaw, 0.4)
	t.check(fb.visitors != null and fb.raised == 1, "overlap: and its Wake still comes")
	fb.end_now()
	t.check(not crowd.remains.enabled, "overlap: after both end the ledger is off")
	fa.free()
	fb.free()
	_done(made)


## The zombie hunts: a citizen near it is bitten (a first bite knocks down).
static func _hunts(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	_clear_town(crowd)
	var c := _cast(made, 5, 2, _spot(made))
	var fx: DeathMarkFx = c[0]
	var lookers: Array[Person] = c[2]
	_arrive(fx, lookers[0], 0.5)
	var prey: Person = crowd.citizens[50]
	prey.ground_pos = (made[1] as WalkGrid).nearest_walkable(fx.body_at + Vector2(3.0, 0.0))
	prey.mind = Person.Mind.CALM
	var dead := false
	for i in 400:
		if is_instance_valid(prey):
			prey.frame(DT)
		fx._process(DT)
		if prey.is_down() or not prey.is_alive() or lookers.any(func(q: Person) -> bool: return q.is_down() or not q.is_alive()):
			dead = true
			break
	t.check(dead and fx.visitors.living().size() >= 1, "the zombie hunts the nearest living (the gawkers it rose among) and bites (%s)" % [dead])
	fx.end_now()
	fx.free()
	_done(made)


static func _gone(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	_clear_town(crowd)
	var c := _cast(made, 5, 2, _spot(made))
	var fx: DeathMarkFx = c[0]
	crowd.remains.take(crowd.remains.pick(fx.body_at))  # another power got there first
	_arrive(fx, (c[2] as Array)[0], 0.5)
	fx._process(1.0)
	t.check(fx.visitors == null and fx.raised == 0 and crowd.visitors.is_empty(), "a body taken by another power first: no zombie, no error")
	fx.free()
	_done(made)


static func _quiet(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	_clear_town(crowd)
	var c := _cast(made, 5, 2, _spot(made))
	var fx: DeathMarkFx = c[0]
	var alarm := crowd.alarm
	var threats := crowd.threats.active_count()
	_arrive(fx, (c[2] as Array)[0], 0.5)
	t.check(fx.visitors != null and is_equal_approx(crowd.alarm, alarm) and crowd.threats.active_count() == threats,
		"the rising is quiet: no alarm and no threat of its own")
	fx.end_now()
	fx.free()
	_done(made)
	# A level 5 cast with the ledger off turns it on: the body is written down to rise.
	var made2 := _setup()
	_clear_town(made2[0])
	var c2 := _cast(made2, 5, 2, _spot(made2))
	var fx2: DeathMarkFx = c2[0]
	_arrive(fx2, (c2[2] as Array)[0], 0.5)
	t.check(fx2.visitors != null, "with the ledger off at the cast, the twist turns it on and the body still rises")
	t.check(made2[0].remains.enabled, "the cast that turned the ledger on keeps it on while it runs")
	fx2.end_now()
	t.check(not made2[0].remains.enabled, "and puts it back off at its end")
	fx2.free()
	_done(made2)
	# Freed without end_now: the ledger goes back too. A ledger already on stays on.
	var made3 := _setup()
	_clear_town(made3[0])
	var c3 := _cast(made3, 5, 2, _spot(made3))
	t.check(made3[0].remains.enabled, "a level 5 cast lights the ledger")
	(c3[0] as DeathMarkFx)._exit_tree()  # what a free inside a live tree runs (the test's layers are not in one)
	(c3[0] as Node).free()
	t.check(not made3[0].remains.enabled, "torn down without end_now (_exit_tree): the ledger is off again")
	_done(made3)
	var made4 := _setup()
	made4[0].remains.enabled = true
	_clear_town(made4[0])
	var c4 := _cast(made4, 5, 2, _spot(made4))
	(c4[0] as DeathMarkFx).end_now()
	t.check(made4[0].remains.enabled, "a ledger that was already on stays on")
	(c4[0] as Node).free()
	_done(made4)


## DL3: a sick body's zombie carries the plague.
static func _sick(t) -> void:
	for sick in [true, false]:
		var made := _setup()
		var crowd: Crowd = made[0]
		crowd.remains.enabled = true
		_clear_town(crowd)
		var spot := _spot(made)
		var marked: Person = crowd.citizens[2]
		marked.infect(60.0) if sick else null
		var c := _cast(made, 5, 2, spot)
		var fx: DeathMarkFx = c[0]
		_arrive(fx, (c[2] as Array)[0], 0.5)
		var z: Animal = fx.visitors.living()[0]
		var r: Visitors.Rule = fx.visitors._rules[z]
		t.check(r.infect == sick, "a %s marked person's wake zombie %s the plague" % ["sick" if sick else "healthy", "carries" if sick else "does not carry"])
		fx.end_now()
		fx.free()
		_done(made)


## Someone never lured, standing at the body, does not wake it.
static func _unlured(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	crowd.remains.enabled = true
	_clear_town(crowd)
	var c := _cast(made, 5, 2, _spot(made), 0)
	var fx: DeathMarkFx = c[0]
	var stranger: Person = crowd.citizens[60]
	stranger.mind = Person.Mind.CALM
	_arrive(fx, stranger, 0.4)
	fx._process(1.0)
	t.check(fx.visitors == null and crowd.remains.pick(fx.body_at) != null, "someone never lured, standing at the body, does not wake it")
	fx.end_now()
	fx.free()
	_done(made)
	# Positive control: the same setup with a lured gawker does wake.
	var made2 := _setup()
	var crowd2: Crowd = made2[0]
	crowd2.remains.enabled = true
	_clear_town(crowd2)
	var c2 := _cast(made2, 5, 2, _spot(made2), 1)
	var fx2: DeathMarkFx = c2[0]
	_arrive(fx2, (c2[2] as Array)[0], 0.4)
	t.check(fx2.visitors != null, "control: the same cast with a lured gawker at the body does wake it")
	fx2.end_now()
	fx2.free()
	_done(made2)
