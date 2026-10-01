extends RefCounted
## v0.05 Banishing Rite: at City Emergency the clergy of a Prepared town gather on the cathedral's steps and chant;
## finished, the rite costs the god PENALTY seconds. Scattering the clergy or damaging the cathedral breaks it (they
## regather after a cooldown); a fallen cathedral or too few clergy ends it.


static func _crowd(tier := ResponseProfile.Tier.PREPARED) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(tier)
	crowd.spawn()
	return [crowd, env, world, field, grid]


## Everyone called walks straight to their place.
static func _arrive(rite: BanishingRite) -> void:
	for e in rite.circle:
		var p: Person = e[0]
		p.ground_pos = e[1]
		p._goal = Vector2.INF
		p._path = PackedVector2Array()


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


static func run(t) -> void:
	# An Organized town holds no rite.
	var made := _crowd(ResponseProfile.Tier.ORGANIZED)
	t.check((made[0] as Crowd).rite.state == BanishingRite.State.ENDED, "an Organized town holds no rite")
	_done(made)

	made = _crowd()
	var crowd: Crowd = made[0]
	var rite := crowd.rite
	t.check(rite.state == BanishingRite.State.IDLE and rite.cathedral != null and rite.cathedral.role == &"temple"
		and rite.places.size() == BanishingRite.CALL and rite.living_clergy() >= BanishingRite.CALL,
		"a Prepared town's rite waits at the cathedral (%d places, %d clergy)" % [rite.places.size(), rite.living_clergy()])
	t.check(not (made[4] as WalkGrid).path(TownLayout.MARKET_SQUARE.get_center(), rite.centre).is_empty(),
		"its steps can be reached from the market")

	# City Emergency calls the clergy; once NEED stand in the ring, they chant.
	var events: Array = []
	rite.gathering.connect(func() -> void: events.append("gathering"))
	rite.started.connect(func() -> void: events.append("started"))
	rite.completed.connect(func() -> void: events.append("completed"))
	rite.broken.connect(func(why: String) -> void: events.append("broken: " + why))
	rite.ended.connect(func(why: String) -> void: events.append("ended: " + why))
	crowd._on_stage(AlarmManager.Stage.CITY_EMERGENCY, "test")
	var on_duty := true
	for e in rite.circle:
		on_duty = on_duty and (e[0] as Person).mind == Person.Mind.DUTY \
			and (e[0] as Person).profile.role == CitizenProfile.Role.CLERGY
	t.check(rite.state == BanishingRite.State.GATHERING and rite.circle.size() == BanishingRite.CALL and on_duty,
		"City Emergency calls %d clergy to the steps" % rite.circle.size())
	rite.step(0.1)
	t.check(rite.state == BanishingRite.State.GATHERING, "and they must get there first")
	_arrive(rite)
	rite.step(0.1)
	t.check(rite.state == BanishingRite.State.CHANTING and events == ["gathering", "started"], "at the steps they chant (%s)" % [events])

	# The evacuation leaves them at it.
	crowd._evacuate()
	var still := true
	for e in rite.circle:
		still = still and (e[0] as Person).mind == Person.Mind.DUTY
	t.check(still, "the evacuation does not pull them from the rite")

	rite.step(rite.duration * 0.5)
	t.check(rite.state == BanishingRite.State.CHANTING and is_equal_approx(rite.fraction(), 0.5),
		"the rite takes %d s" % roundi(rite.duration))
	var called: Array = []
	for e in rite.circle:
		called.append(e[0])
	rite.step(rite.duration)
	var released := true
	for p: Person in called:
		released = released and p.mind == Person.Mind.FLEE
	t.check(rite.state == BanishingRite.State.DONE and events.back() == "completed" and released,
		"it completes, and the clergy go on to the gates")
	rite.step(BanishingRite.COOLDOWN + 1.0)
	t.check(rite.state == BanishingRite.State.DONE, "and is done once")

	# Rules: the penalty comes off the manifestation's clock, never below zero.
	var rules := Rules.new()
	rules.time_left = 100.0
	rules.lose_time(BanishingRite.PENALTY)
	var after := rules.time_left
	rules.lose_time(500.0)
	t.check(is_equal_approx(after, 100.0 - BanishingRite.PENALTY) and rules.time_left == 0.0,
		"the god loses %d s of manifestation" % roundi(BanishingRite.PENALTY))
	rules.free()
	_done(made)

	# Scattered: frighten the ring down to one, and the rite breaks; after the cooldown the clergy regather.
	made = _crowd()
	crowd = made[0]
	rite = crowd.rite
	events = []
	rite.broken.connect(func(why: String) -> void: events.append("broken: " + why))
	rite.begin()
	_arrive(rite)
	rite.step(0.1)
	rite.step(10.0)
	var scared := 0
	for e in rite.circle:
		if scared < rite.circle.size() - 1:
			var p: Person = e[0]
			p.shelters = null
			p.panic(p.ground_pos + Vector2(0.5, 0.0), 1.0, &"heaven")
			scared += 1
	rite.step(0.1)
	t.check(rite.state == BanishingRite.State.COOLDOWN and rite.progress == 0.0 and events.size() == 1,
		"frightening the clergy away breaks the rite (%s)" % [events])
	rite.step(BanishingRite.COOLDOWN + 0.1)
	t.check(rite.state == BanishingRite.State.GATHERING and rite.circle.size() >= BanishingRite.NEED,
		"and after %d s they regather (%d called)" % [roundi(BanishingRite.COOLDOWN), rite.circle.size()])

	# A cathedral under half its health breaks it too.
	_arrive(rite)
	rite.step(0.1)
	var chanting := rite.state == BanishingRite.State.CHANTING
	rite.cathedral.hp = rite.cathedral.max_hp * (BanishingRite.MIN_HP - 0.1)
	rite.step(0.1)
	t.check(chanting and rite.state == BanishingRite.State.COOLDOWN, "a badly damaged cathedral breaks the rite")
	rite.step(BanishingRite.COOLDOWN + 0.1)
	_arrive(rite)
	rite.step(0.1)
	t.check(rite.state == BanishingRite.State.GATHERING, "and it cannot start again until the cathedral is mended")

	# Destroyed: over for good.
	events = []
	rite.ended.connect(func(why: String) -> void: events.append(why))
	rite.cathedral.destroy(rite.cathedral.center(), &"nova")
	rite.step(0.1)
	t.check(rite.state == BanishingRite.State.ENDED and events.size() == 1 and rite.circle.is_empty(),
		"a fallen cathedral ends the rite for good (%s)" % [events])
	_done(made)

	# Too few clergy left alive: over too.
	made = _crowd()
	crowd = made[0]
	rite = crowd.rite
	rite.begin()
	var field: EnemyField = made[3]
	for p in crowd.citizens:
		if p.is_alive() and p.profile.role == CitizenProfile.Role.CLERGY and rite.living_clergy() >= BanishingRite.NEED:
			field.kill(p, &"test")
	rite.step(0.1)
	t.check(rite.state == BanishingRite.State.ENDED, "killing the clergy ends it (%d left)" % rite.living_clergy())
	_done(made)
