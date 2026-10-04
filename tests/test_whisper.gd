extends RefCounted
## v0.08 Mind Whisper's mind: a whispered person drops whatever it was doing, walks (not runs) to the spot, lingers
## there, then resumes -- flight again if it was fleeing, else its day, where a duty's manager takes it back. Soldiers,
## anyone inside and the dead do not hear it.


static func _crowd(tier := ResponseProfile.Tier.ORGANIZED) -> Array:
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
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


static func _arrive(p: Person) -> void:
	p.ground_pos = p.goal()
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _think(p: Person, seconds: float) -> void:
	var step := 0.1
	var t := 0.0
	while t < seconds:
		p._think(step)
		t += step


static func run(t) -> void:
	var made := _crowd()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var p: Person = crowd.citizens[0]
	var to := grid.nearest_walkable(p.ground_pos + Vector2(3.0, 0.0))
	t.check(p.whisper(to, 8.0) and p.mind == Person.Mind.WHISPERED, "a calm citizen hears the whisper")
	t.check(p.goal().distance_to(to) < 0.01 and p.walk_speed <= Person.WALK_SPEED * p.pace + 0.001,
		"and walks to the spot (%.2f)" % p.walk_speed)
	t.check(p.intent() == Person.Intent.WHISPERED, "its intent reads WHISPERED")
	_think(p, 3.0)
	t.check(p.mind == Person.Mind.WHISPERED, "the linger does not start on the way")
	_arrive(p)
	_think(p, 7.0)
	t.check(p.mind == Person.Mind.WHISPERED, "it lingers there")
	_think(p, 1.5)
	t.check(p.mind == Person.Mind.RECOVER, "after 8 s it goes back to its day (%s)" % Person.Mind.keys()[p.mind])

	# Flight is picked up again.
	var f: Person = crowd.citizens[1]
	f.flee()
	f.whisper(grid.nearest_walkable(f.ground_pos + Vector2(0.0, 2.0)), 8.0)
	_arrive(f)
	_think(f, 8.5)
	t.check(f.mind == Person.Mind.FLEE, "a whispered evacuee flees again after")

	# A duty: the bell's keeper drops the climb and the bell waits for it.
	var keeper: Person = crowd.bell.keeper
	crowd.bell.call_keeper()
	t.check(keeper.mind == Person.Mind.DUTY, "the keeper is called")
	keeper.whisper(grid.nearest_walkable(keeper.ground_pos + Vector2(-3.0, 0.0)), 8.0)
	crowd.bell.step(0.1)
	t.check(crowd.bell.state == BellNetwork.State.WAITING, "the bell waits for its whispered keeper")
	for i in 30:
		crowd.bell.step(0.5)
	t.check(keeper.mind == Person.Mind.WHISPERED, "and does not take it back mid-whisper")

	# Immune: soldiers, the dead, anyone inside.
	t.check(not crowd.soldiers[0].whisper(Vector2.ZERO, 8.0), "soldiers do not hear it")
	var inside: Person = crowd.citizens[2]
	inside.inside = true
	t.check(not inside.whisper(Vector2.ZERO, 8.0), "nor does anyone inside")
	inside.inside = false
	var dead: Person = crowd.citizens[3]
	(made[3] as EnemyField).kill(dead, &"doom", dead.ground_pos)
	t.check(not dead.whisper(Vector2.ZERO, 8.0), "nor the dead")

	# The evacuation leaves a whispered person to its whisper, then it flees.
	var w: Person = crowd.citizens[4]
	w.whisper(grid.nearest_walkable(w.ground_pos + Vector2(2.0, 0.0)), 8.0)
	crowd._evacuate()
	t.check(w.mind == Person.Mind.WHISPERED, "the evacuation call does not break a whisper")
	_arrive(w)
	_think(w, 8.5)
	t.check(w.mind == Person.Mind.FLEE, "and it joins the flight after")
	_power(t, made)
	_shake_off(t, made)
	_done(made)


## The shake-off (v0.08.1): someone a whisper has just let go does not hear another for SHAKE_OFF seconds, counted from
## when it wore off and counted down whatever its thinking does; one still under a whisper can be sent on; nobody never
## whispered is touched. Rules refuses a whisper on them with "shaken", and spends no cooldown.
static func _shake_off(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[4]
	var shaken_any := false
	for q: Person in crowd.citizens.slice(20) + crowd.soldiers:
		shaken_any = shaken_any or q.shaken()
	t.check(not shaken_any, "nobody never whispered is shaken")
	var p: Person = crowd.citizens[20]
	var first := grid.nearest_walkable(p.ground_pos + Vector2(2.0, 0.0))
	p.whisper(first, 8.0)
	var second := grid.nearest_walkable(p.ground_pos + Vector2(-2.0, 0.0))
	t.check(p.whisper(second, 8.0) and p.goal().distance_to(second) < 0.01 and not p.shaken(),
		"one still under a whisper hears a new one, and is sent on (the shake-off starts when it wears off)")
	_arrive(p)
	_think(p, 8.5)
	t.check(p.mind != Person.Mind.WHISPERED and p.shaken(), "when the whisper wears off it shakes it off (%s)"
		% Person.Mind.keys()[p.mind])
	t.check(not p.whisper(first, 8.0) and p.mind != Person.Mind.WHISPERED, "and another whisper does not take")
	# Frozen, it does not think at all; the shake-off runs on in tick() all the same.
	p.freeze(60.0)
	for i in 199:
		p.tick(0.1)
	t.check(p.shaken(), "still shaken at 19.9 s, frozen the whole time")
	p.tick(0.2)
	t.check(not p.shaken() and p.whisper(first, 8.0), "and past %d s it hears a whisper again" % roundi(Person.SHAKE_OFF))
	p._frozen = 0.0

	# A whispered evacuee sent on keeps the flight it owes.
	var f: Person = crowd.citizens[21]
	f.flee()
	f.whisper(grid.nearest_walkable(f.ground_pos + Vector2(0.0, 2.0)), 8.0)
	f.whisper(grid.nearest_walkable(f.ground_pos + Vector2(2.0, 0.0)), 8.0)
	_arrive(f)
	_think(f, 8.5)
	t.check(f.mind == Person.Mind.FLEE, "a whispered evacuee whispered again still flees after")

	# The cast: refused with "shaken", no cooldown, nothing cast; never-whispered people are not refused.
	var rules := Rules.new().setup(PackedStringArray(["whisper"]), null, made[1], field, crowd, made[5])
	var casts: Array = []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	var s: Person = crowd.citizens[22]
	s._shaken_left = Person.SHAKE_OFF
	t.check(rules.cast(0, s.ground_pos, {"to": s.ground_pos, "target": s}) == null and refused == [[0, "shaken"]]
		and rules.cooldown_left(0) == 0.0 and casts.is_empty(),
		"a whisper on someone shaken is refused with \"shaken\", and spends no cooldown (%s)" % [refused])
	s._shaken_left = 0.0
	var n: Person = crowd.citizens[23]
	rules.cast(0, n.ground_pos, {"to": n.ground_pos, "target": n})
	t.check(casts.size() == 1 and rules.cooldown_left(0) == 8.0, "one never whispered is whispered as before")
	rules.teardown()
	rules.free()


## The power (v0.08 M3 Task 16): who a press picks, how far a release may send them, the cast's refusal, the effect.
static func _power(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[4]
	var c: Person = crowd.citizens[10]
	# A walkable spot a unit or more from anyone.
	var empty := Vector2.INF
	for i in 200:
		var at := grid.nearest_walkable(Vector2(-20.0 + float(i % 20) * 2.0, -20.0 + float(i / 20) * 4.0))
		if at != Vector2.INF and field.in_radius(at, 1.0).is_empty():
			empty = at
			break
	t.check(empty != Vector2.INF and MindWhisperFx.pick(field, empty) == null, "a press a unit from anyone picks nobody")
	var c_was := c.ground_pos
	c.ground_pos = empty + Vector2(0.4, 0.0)
	t.check(MindWhisperFx.pick(field, empty) == c, "a press within 0.6 of a citizen picks it")
	c.ground_pos = c_was
	var s: Person = crowd.soldiers[1]
	var s_was := s.ground_pos
	s.ground_pos = empty
	var hidden: Person = crowd.citizens[11]
	var h_was := hidden.ground_pos
	hidden.ground_pos = empty + Vector2(0.2, 0.0)
	hidden.inside = true
	t.check(MindWhisperFx.pick(field, empty) == null, "nor a soldier, nor anyone inside")
	hidden.inside = false
	t.check(MindWhisperFx.pick(field, empty) == hidden, "but someone out in the open, yes")
	s.ground_pos = s_was
	hidden.ground_pos = h_was
	var far := MindWhisperFx.clamp_to(grid, c.ground_pos, c.ground_pos + Vector2(20.0, 0.0))
	t.check(far.distance_to(c.ground_pos) <= MindWhisperFx.REACH + 0.5 and grid.walkable(far),
		"a 20-unit drag sends no further than REACH, on walkable ground (%.2f)" % far.distance_to(c.ground_pos))

	# The cast: refused with "nobody" and no cooldown where nobody stands; on a citizen, the 8 s cooldown and the walk.
	var rules := Rules.new().setup(PackedStringArray(["whisper", "heaven"]), null, made[1], field, crowd, made[5])
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		var who: Person = extra.get("target", MindWhisperFx.pick(field, ground))
		if who != null:
			who.whisper(extra.get("to", ground), MindWhisperFx.LINGER)
		return null
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, reason: String): refused.append([slot, reason]))
	var made_casts: Array = []
	rules.cast_made.connect(func(slot: int, key: String, _at: Vector2): made_casts.append([slot, key]))
	t.check(rules.cast(0, empty, {}) == null and refused == [[0, "nobody"]] and rules.cooldown_left(0) == 0.0
		and made_casts.is_empty(), "a whisper at nobody is refused, starts no cooldown and casts nothing (%s)" % [refused])
	rules.refuse(1, "nobody")
	t.check(refused.size() == 2 and refused[1] == [1, "nobody"], "and Targeting can refuse one itself")
	var to := MindWhisperFx.clamp_to(grid, c.ground_pos, c.ground_pos + Vector2(4.0, 1.0))
	rules.cast(0, c.ground_pos, {"to": to, "target": c})
	t.check(rules.cooldown_left(0) == 8.0 and made_casts == [[0, "whisper"]], "a whisper on a citizen starts its 8 s cooldown")
	t.check(c.mind == Person.Mind.WHISPERED and c.goal().distance_to(to) < 0.01, "and the citizen walks to the spot")
	rules.teardown()
	rules.free()

	# The effect itself: it whispers, marks the spot while the whisper lasts, and goes with it.
	var ctx := FxContext.new()
	ctx.env = made[1]
	ctx.field = field
	ctx.rng = RandomNumberGenerator.new()
	ctx.ground = Node2D.new()
	ctx.overhead = Node2D.new()
	var d: Person = crowd.citizens[12]
	var spot := MindWhisperFx.clamp_to(grid, d.ground_pos, d.ground_pos + Vector2(0.0, 3.0))
	var fx := FxTimeline.cast(MindWhisperFx, ctx, d.ground_pos, {"to": spot, "target": d})
	fx._process(1.0)
	t.check(d.mind == Person.Mind.WHISPERED and not fx.finished and ctx.ground.get_child_count() == 2,
		"the effect whispers and rings the spot, a ring in its halo (%d marks)" % ctx.ground.get_child_count())
	_arrive(d)
	_think(d, MindWhisperFx.LINGER + 0.5)
	fx._process(0.1)
	fx._process(0.5)
	t.check(d.mind != Person.Mind.WHISPERED and fx.finished, "and fades once the whisper wears off")
	var none := FxTimeline.cast(MindWhisperFx, ctx, empty, {})
	none._process(0.2)
	t.check(none.finished, "an effect with nobody to whisper to ends at once")
	ctx.ground.free()
	ctx.overhead.free()
