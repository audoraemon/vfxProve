extends RefCounted
## Decree's law on a place (LawZone, spec §4.2; plan Task 2): a circle or a strip where a law holds for a time, listed on
## the crowd so every choice asks in_law(). NO LEAVING is held by the zone itself: whoever stands inside (a person or a
## visitor) cannot walk out -- set back onto the edge, hesitating now and then -- until carried CARRIED past it; walking in
## is free. Indoors and chained people are left alone. Two zones hold side by side; a zone dies with its time or its
## effect. Law rubble (spec §4.3) closes the street and the engineers clear it.


## An effect that lays a law for as long as it lives (as a Decree power does).
class LawFx extends FxTimeline:
	var zone: LawZone

	func _build() -> void:
		duration = 30.0
		zone = LawZone.circle(origin, 3.0, [&"no_breath"], 20.0)
		ctx.crowd.add_law(zone, self)


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
	# Everyone out of the way, in a corner.
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	if is_instance_valid(ctx.overhead):
		ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	var folk: Array[Person] = []
	for p in crowd.citizens:
		if p.profile != null and p.profile.role == CitizenProfile.Role.RESIDENT:
			folk.append(p)
	var a: Person = folk[0]
	var b: Person = folk[1]
	var c: Person = folk[2]
	var d: Person = folk[3]
	const DT := 0.016

	# --- NO LEAVING: whoever stands inside cannot walk out.
	var z := LawZone.circle(at, 3.0, [&"no_leaving"], 10.0)
	t.check(z.contains(at + Vector2(2.9, 0.0)) and not z.contains(at + Vector2(3.1, 0.0)) and z.alive() and z.radius == 3.0
		and z.kinds == [&"no_leaving"], "a circle of 3 holds what stands within 3 of its centre")
	a.ground_pos = at + Vector2(1.0, 0.0)
	crowd.add_law(z)
	crowd.step_laws(DT)
	t.check(crowd.laws.has(z) and z.members.has(a) and crowd.in_law(a, &"no_leaving") and not crowd.in_law(a, &"no_breath"),
		"laid on the crowd, it holds whoever stands inside, and answers only its own kind")
	a.ground_pos = at + Vector2(4.0, 0.0)
	crowd.step_laws(DT)
	t.check(is_equal_approx(a.ground_pos.distance_to(at), 3.0) and a._idle > 0.0 and z.turned_back == 1,
		"one who walks to r + 1 is set back onto the edge, and hesitates (%.2f)" % a.ground_pos.distance_to(at))
	a._idle = 0.0
	a.ground_pos = at + Vector2(4.0, 0.0)
	crowd.step_laws(DT)
	t.check(is_equal_approx(a.ground_pos.distance_to(at), 3.0) and is_zero_approx(a._idle) and z.turned_back == 1,
		"pushing on at once he is held again, but hesitates only every %.1f s" % LawZone.TURN_EVERY)
	a.ground_pos = at + Vector2(0.5, 0.5)
	crowd.step_laws(DT)
	t.check(a.ground_pos.is_equal_approx(at + Vector2(0.5, 0.5)), "inside it he walks where he likes")

	# Walking in is free; whoever walks in is held too.
	b.ground_pos = at + Vector2(0.0, 4.0)
	crowd.step_laws(DT)
	t.check(b.ground_pos.is_equal_approx(at + Vector2(0.0, 4.0)) and not z.members.has(b), "one outside is left alone")
	b.ground_pos = at + Vector2(0.0, 2.5)
	crowd.step_laws(DT)
	t.check(b.ground_pos.is_equal_approx(at + Vector2(0.0, 2.5)) and z.members.has(b), "one walking in is not pushed back")
	b.ground_pos = at + Vector2(0.0, 3.5)
	crowd.step_laws(DT)
	t.check(is_equal_approx(b.ground_pos.distance_to(at), 3.0), "and once in, he cannot leave either")

	# Carried far past the edge by something greater, he is free.
	b.ground_pos = at + Vector2(0.0, 3.0 + LawZone.CARRIED + 0.5)
	crowd.step_laws(DT)
	t.check(not z.members.has(b) and b.ground_pos.is_equal_approx(at + Vector2(0.0, 5.0)),
		"carried more than %.1f past the edge, he is let go" % LawZone.CARRIED)

	# A hound inside is held as a person is.
	var visitors := Visitors.new().setup(field, crowd, grid, made[4])
	var hound := visitors.summon(at + Vector2(0.5, -0.5), Animal.Breed.HELLHOUND, 3, 1.0, 8.0, 0.5, 1.0)
	crowd.step_laws(DT)
	hound.ground_pos = at + Vector2(0.0, -4.0)
	crowd.step_laws(DT)
	t.check(z.members.has(hound) and is_equal_approx(hound.ground_pos.distance_to(at), 3.0),
		"a hound inside cannot leave either (%.2f)" % hound.ground_pos.distance_to(at))

	# Indoors and chained people are left alone.
	c.ground_pos = at + Vector2(-1.0, 0.0)
	crowd.step_laws(DT)
	c.inside = true
	c.ground_pos = at + Vector2(-4.0, 0.0)
	crowd.step_laws(DT)
	t.check(c.ground_pos.is_equal_approx(at + Vector2(-4.0, 0.0)), "one indoors is left alone")
	c.inside = false
	c.ground_pos = at + Vector2(-1.0, 0.0)
	crowd.step_laws(DT)
	c.chained = true
	c.ground_pos = at + Vector2(-4.0, 0.0)
	crowd.step_laws(DT)
	t.check(c.ground_pos.is_equal_approx(at + Vector2(-4.0, 0.0)), "a chained captive walks out: the chain is stronger than the law")
	c.chained = false

	# The dead and the freed are dropped.
	d.ground_pos = at + Vector2(0.0, 1.0)
	crowd.step_laws(DT)
	var held := z.members.size()
	field.kill(d, &"test")
	crowd.step_laws(DT)
	t.check(z.members.size() == held - 1 and not z.members.has(d), "one who dies in it is dropped")
	var e: Person = folk[4]
	e.ground_pos = at + Vector2(0.0, 1.5)
	crowd.step_laws(DT)
	held = z.members.size()
	crowd.citizens.erase(e)
	e.free()
	crowd.step_laws(DT)
	t.check(z.members.size() == held - 1 and not crowd.in_law(e, &"no_leaving"), "one freed in it is dropped, and asking about him is safe")

	# Two laws on the same ground: both hold, and lifting one leaves the other.
	var z2 := LawZone.circle(at + Vector2(1.0, 0.0), 3.0, [&"no_leaving"], 10.0)
	a.ground_pos = at + Vector2(0.5, 0.0)
	crowd.add_law(z2)
	crowd.step_laws(DT)
	a.ground_pos = at + Vector2(-2.5, 0.0)
	crowd.step_laws(DT)
	t.check(z.members.has(a) and z2.members.has(a) and a.ground_pos.is_equal_approx(at + Vector2(-2.0, 0.0)),
		"inside two laws, the second holds him where the first would let him go (%s)" % (a.ground_pos - at))
	a.ground_pos = at + Vector2(3.5, 0.0)
	crowd.step_laws(DT)
	t.check(a.ground_pos.is_equal_approx(at + Vector2(3.0, 0.0)), "and the first where the second would (%s)" % (a.ground_pos - at))
	crowd.remove_law(z)
	t.check(not crowd.laws.has(z) and not z.alive() and crowd.laws.has(z2) and crowd.in_law(a, &"no_leaving"),
		"lifting one leaves the other")
	a.ground_pos = at + Vector2(4.5, 0.0)
	crowd.step_laws(DT)
	t.check(a.ground_pos.is_equal_approx(at + Vector2(4.0, 0.0)), "which still holds him (%s)" % (a.ground_pos - at))
	crowd.remove_law(z2)
	a.ground_pos = at + Vector2(6.0, 0.0)
	crowd.step_laws(DT)
	t.check(crowd.laws.is_empty() and a.ground_pos.is_equal_approx(at + Vector2(6.0, 0.0)) and not crowd.in_law(a, &"no_leaving"),
		"with both lifted he walks away")
	visitors.clear()

	# --- Other kinds are only asked; each holds for its seconds.
	var breath := LawZone.circle(at, 2.5, [&"no_breath", &"disorder"], 2.0)
	crowd.add_law(breath)
	a.ground_pos = at + Vector2(1.0, 1.0)
	b.ground_pos = at + Vector2(0.0, 2.6)
	t.check(crowd.in_law(a, &"no_breath") and crowd.in_law(a, &"disorder") and not crowd.in_law(b, &"no_breath")
		and not crowd.in_law(a, &"no_leaving") and not crowd.in_law(null, &"no_breath"),
		"in_law answers each kind the zone holds, for those inside it")
	a.ground_pos = at + Vector2(1.1, 1.0)
	crowd.step_laws(1.0)
	t.check(crowd.in_law(a, &"no_breath") and a.ground_pos.is_equal_approx(at + Vector2(1.1, 1.0)),
		"a law that is not NO LEAVING moves nobody")
	crowd.step_laws(1.1)
	t.check(not crowd.in_law(a, &"no_breath") and not breath.alive() and not crowd.laws.has(breath),
		"after its seconds it holds no more")

	# A strip: from a to b, half_width to each side.
	var lane := LawZone.lane(at, at + Vector2(6.0, 0.0), 1.0, [&"no_running"], 5.0)
	t.check(lane.contains(at + Vector2(3.0, 0.9)) and not lane.contains(at + Vector2(3.0, 1.1))
		and not lane.contains(at + Vector2(6.2, 0.0)) and not lane.contains(at + Vector2(-0.2, 0.0)) and lane.contains(at + Vector2(6.0, -1.0)),
		"a lane holds a strip from end to end, half_width to each side")
	var slant := LawZone.lane(at, at + Vector2(4.0, 4.0), 0.5, [&"no_leaving"], 5.0)
	t.check(slant.contains(at + Vector2(2.0, 2.0) + Vector2(-0.3, 0.3)) and not slant.contains(at + Vector2(2.0, 2.0) + Vector2(-0.4, 0.4)),
		"a slanted lane too")
	crowd.add_law(slant)
	a.ground_pos = at + Vector2(2.0, 2.0)
	crowd.step_laws(DT)
	a.ground_pos = at + Vector2(2.0, 2.0) + Vector2(-0.6, 0.6)
	crowd.step_laws(DT)
	t.check(a.ground_pos.is_equal_approx(at + Vector2(2.0, 2.0) + Vector2(-0.5, 0.5).normalized() * 0.5),
		"NO LEAVING on a lane sets one back onto its side (%s)" % (a.ground_pos - at))
	crowd.remove_law(slant)

	# --- A law laid by an effect ends with it.
	var fx: LawFx = FxTimeline.cast(LawFx, made[5], at)
	a.ground_pos = at
	t.check(crowd.in_law(a, &"no_breath"), "an effect lays its law")
	fx.free()
	t.check(not crowd.in_law(a, &"no_breath"), "freed, its law holds no more")
	crowd.step_laws(DT)
	t.check(crowd.laws.is_empty(), "and the crowd drops it")
	# Leaving the tree (ended, or the scene torn down) it is lifted at once, before it is freed. (The test's tree does not
	# run, so its leaving is told by the signal the engine sends.)
	fx = FxTimeline.cast(LawFx, made[5], at)
	var zone := fx.zone
	fx.tree_exiting.emit()
	t.check(not crowd.laws.has(zone) and not zone.alive() and is_instance_valid(fx) and not crowd.in_law(a, &"no_breath"),
		"an effect leaving the tree lifts its law at once (remove_law on exit)")
	fx.free()

	# --- Law rubble closes the street; the engineers clear it, and it is no incident.
	var spot := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center() + Vector2(2.0, 2.0))
	var rect := Rect2(spot - Vector2(0.5, 0.5), Vector2(1.0, 1.0))
	var alarm := crowd.alarm
	var rubble := LawRubble.lay(env, rect, 6.0)
	t.check(rubble != null and rubble.role == &"decree" and env.structures().has(rubble) and not grid.walkable(spot),
		"law rubble stands where it is laid and closes its ground")
	t.check(&"decree" in EngineerManager.CLEARABLE and not Visitors._wreckable(rubble), "the engineers clear it, and no demon claws it")
	crowd._on_stage(AlarmManager.Stage.CITY_EMERGENCY, "test")
	alarm = crowd.alarm
	var eng := crowd.engineers
	eng.step(0.1)
	var clearing: Dictionary = {}
	for team in eng.teams:
		if team.job.get("type", -1) == EngineerManager.Job.CLEAR and team.job.get("target") == rubble:
			clearing = team
	t.check(not clearing.is_empty(), "an engineer team goes to clear it")
	if not clearing.is_empty():
		for i in clearing.members.size():
			var m: Person = clearing.members[i]
			m.ground_pos = clearing.spots[i]
			m._goal = Vector2.INF
			m._path = PackedVector2Array()
		eng.step(EngineerManager.CLEAR_TIME + 0.1)
	t.check((not is_instance_valid(rubble) or not env.structures().has(rubble)) and grid.walkable(spot), "cleared in %d s, the street opens again" % roundi(EngineerManager.CLEAR_TIME))
	var rubble2 := LawRubble.lay(env, rect, 6.0)
	alarm = crowd.alarm
	rubble2.destroy(rubble2.center(), &"fire")
	t.check(crowd.alarm == alarm, "law rubble blasted away raises nothing")
	_done(made)
