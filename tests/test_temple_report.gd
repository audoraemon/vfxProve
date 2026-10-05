extends RefCounted
## v0.10 a report to the Temple (TempleReport): a Faithful who saw the god at work runs to the Temple's door; there the
## report is delivered. A death nobody sees ends it; a seen one passes it to the witness, who runs on. Fright and the
## god's holds interrupt the run until the carrier is back on its feet. Two reports run apart (review focus 3).

const DT := 0.05


static func _crowd() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var door := grid.nearest_walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "door": door}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, reports: Array, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		for r: TempleReport in reports:
			r.step(DT, s.crowd)


## Everyone but `keep` within `reach` of `at` moved well away.
static func _clear_round(crowd: Crowd, at: Vector2, reach: float, keep: Array) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + (p.ground_pos - at).normalized() * (reach + 6.0) if p.ground_pos != at \
					else at + Vector2(reach + 6.0, 0.0)


static func run(t) -> void:
	t.check(CitizenProfile.new().faith == CitizenProfile.Faith.NONE, "nobody is of any faith by default")
	var s := _crowd()
	var crowd: Crowd = s.crowd
	var door: Vector2 = s.door
	var a: Person = crowd.citizens[3]
	var r := TempleReport.new(a, door)
	t.check(a.mind == Person.Mind.DUTY and r.is_open() and r.carrier == a, "the Faithful runs to the Temple")
	a.ground_pos = door + Vector2(0.4, 0.0)
	_run(s, [r], DT * 2.0)
	t.check(r.delivered and not r.is_open() and a.mind != Person.Mind.DUTY, "at the door the report is delivered")

	# An unseen death ends a report.
	var b: Person = crowd.citizens[7]
	var rb := TempleReport.new(b, door)
	_clear_round(crowd, b.ground_pos, Crowd.DOOM_WITNESS + 1.0, [b])
	crowd._field.kill(b, &"doom")
	rb.on_killed(b)
	_run(s, [rb], DT * 2.0)
	t.check(rb.dead and not rb.delivered and not rb.is_open(), "a death nobody sees ends the report")

	# A seen death passes it on.
	var c: Person = crowd.citizens[11]
	var w: Person = crowd.citizens[12]
	var rc := TempleReport.new(c, door)
	_clear_round(crowd, c.ground_pos, Crowd.DOOM_WITNESS + 1.0, [c])
	w.ground_pos = c.ground_pos + Vector2(1.0, 0.0)
	crowd._field.kill(c, &"doom")
	rc.on_killed(c)
	_run(s, [rc], DT * 2.0)
	t.check(rc.carrier == w and rc.relays == 1 and rc.is_open() and w.mind == Person.Mind.DUTY,
		"a seen death passes the report to the witness, who runs on")

	# A whisper holds the carrier; once it wears off they run on.
	var d: Person = crowd.citizens[15]
	var rd := TempleReport.new(d, door)
	d.whisper(d.ground_pos, 1.0)
	d._goal = Vector2.INF  # already standing on the spot: the linger starts at once
	d._path = PackedVector2Array()
	_run(s, [rd], 0.5)
	t.check(d.mind == Person.Mind.WHISPERED and rd.is_open(), "a whisper holds the carrier")
	# People only think when the tree steps them (Crowd.step_people()); the test steps this one's mind by hand.
	for i in 30:
		d._think(0.1)
	_run(s, [rd], TempleReport.RETARGET * 2.0)
	t.check(d.mind == Person.Mind.DUTY or rd.delivered, "once it wears off they run on (%s)" % Person.Mind.keys()[d.mind])

	# Review focus 3: two reports apart; one carrier killed in front of the other carrier.
	var e1: Person = crowd.citizens[20]
	var e2: Person = crowd.citizens[21]
	var r1 := TempleReport.new(e1, door)
	var r2 := TempleReport.new(e2, door)
	_clear_round(crowd, e1.ground_pos, Crowd.DOOM_WITNESS + 1.0, [e1])
	e2.ground_pos = e1.ground_pos + Vector2(1.0, 0.0)
	crowd._field.kill(e1, &"doom")
	r1.on_killed(e1)
	r2.on_killed(e1)
	_run(s, [r1, r2], DT * 2.0)
	t.check(r1.carrier == e2 and r2.carrier == e2 and r2.relays == 0, "the witness carries both, the second never relayed")
	e2.ground_pos = door + Vector2(0.3, 0.0)
	_run(s, [r1, r2], DT * 2.0)
	t.check(r1.delivered and r2.delivered, "and both arrive with them")
	_done(s)
