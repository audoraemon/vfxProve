extends RefCounted
## God T1R Task 1 (spec 2.1): the walls a mission is played in (Walls.outside(), Walls.way_off()), a Mirrorfold's way out beyond them, the
## leaver bookkeeping on MissionDirector (send_off(), _step_leaving(), is_leaving()), and the seconds the bell still lies (Crowd.lie_left()).

const DT := 0.05


static func run(t) -> void:
	_aldermere(t)
	_capital(t)
	_fold_outside(t)
	_send_off(t)
	_lie_left(t)


## A crowd on the real town, a Rules for the board Warning's definition (its caster hands nothing back) and a bare MissionDirector.
static func _world() -> Dictionary:
	var def := TierBook.board("warning")
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
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var d := MissionDirector.new().setup(rules, crowd, town, null)
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": d}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _aldermere(t) -> void:
	t.check(not Walls.outside(Vector2(0, 0)), "the market is inside the walls")
	t.check(not Walls.outside(Vector2(2.7, 15.9)), "the Main Gate's passage is inside")
	t.check(Walls.outside(Vector2(2.7, 16.6)), "past the wall by more than the margin is out")
	t.check(not Walls.outside(Vector2(-16.4, 0)) and Walls.outside(Vector2(-16.6, 0)), "the west wall's margin is the same")
	t.near(Walls.MARGIN, 0.5, 0.0001, "Walls.MARGIN is 0.5")
	t.check(Walls.way_off(Vector2(2.7, 17.0)) == TownLayout.EXITS[0], "from the Main Gate the nearest way off is the south road")
	t.check(Walls.way_off(Vector2(2.7, 17.0)) == Vector2(2.7, 29.6), "the south road is at (2.7, 29.6)")
	t.check(Walls.way_off(Vector2(17.0, 9.0)) == TownLayout.EXITS[1], "from the east it is the east road")
	t.check(Walls.outside(Vector2(0, 0), CapitalCity.new()) == false and Walls.outside(Vector2(0, 8), CapitalCity.new()),
		"outside() takes the town to judge by")


static func _capital(t) -> void:
	City.use(&"capital")
	t.check(Walls.outside(Vector2(-24.6, -13.0)), "the Capital: out by the west gate")
	t.check(not Walls.outside(Vector2(-23.0, -13.0)), "the Capital: inside the west gate")
	t.check(Walls.outside(Vector2(4.0, 4.6)), "the Capital: onto a bridge is out")
	# From the bridge the ferry landing is nearer, but its straight walk runs back through the old town: the south road it is.
	t.check(Walls.way_off(Vector2(4.0, 4.6)) == Vector2(7, 39.6), "the Capital: from a bridge, a way off that does not cross the old town")
	t.check(Walls.way_off(Vector2(-24.6, -13.0)) == Vector2(-39.6, -13), "the Capital: from the west gate, the west road")
	t.check(Walls.way_off(Vector2(19.0, -9.0)) == CapitalCity.FERRY_LANDING, "the Capital: from the harbour gate, the ferry landing")
	City.use(&"aldermere")


## A Mirrorfold's way out beyond the wall needs no change (spec 2.1): the walker is set down on walkable ground there, and the next
## look finds him out of the walls.
static func _fold_outside(t) -> void:
	var s := _world()
	var p: Person = (s.crowd as Crowd).citizens[0]
	t.check(p.fold(Vector2(2.7, 18.0)), "a fold to ground outside the wall takes")
	t.check(Walls.outside(p.ground_pos), "he stands outside the walls after it")
	_done(s)


static func _send_off(t) -> void:
	var s := _world()
	var d: MissionDirector = s.d
	var crowd: Crowd = s.crowd
	var p: Person = crowd.citizens[0]
	p.go_duty(p.ground_pos)  # on duty where he stands: send_off() stands him down first
	p.ground_pos = Vector2(2.7, 17.0)
	var escaped := crowd.escaped_count
	d.send_off(p)
	var way := Walls.way_off(Vector2(2.7, 17.0))
	t.check(p.mind == Person.Mind.DUTY and p.anchor == way, "sent off, he is on duty at his way off")
	t.check(d.is_leaving(p) and d.leaving.size() == 1, "and he is leaving")
	d.send_off(p)
	t.check(d.leaving.size() == 1, "a second send_off of the same person adds nothing")
	p.ground_pos = way + Vector2(0.5, 0.0)
	d._step_leaving()
	t.check(not p in crowd.citizens, "within reach of his way off he is taken out of the crowd")
	t.check(crowd.escaped_count == escaped, "and not counted as an escaped citizen")
	t.check(d.leaving.is_empty() and not d.is_leaving(p), "and he is no longer leaving")
	# A soldier is taken off the soldiers' roll, and one knocked off his walk (a fright) is sent on again.
	var sol: Person = crowd.soldiers[0]
	sol.ground_pos = Vector2(2.7, 17.5)
	d.send_off(sol)
	t.check(sol.mind == Person.Mind.DUTY and sol.anchor == way and d.is_leaving(sol), "a soldier is sent off the same way")
	sol.mind = Person.Mind.CALM
	d._step_leaving()
	t.check(sol.mind == Person.Mind.DUTY and sol.anchor == way and d.is_leaving(sol), "one back on his feet after a fright is sent again")
	sol.ground_pos = way
	d._step_leaving()
	t.check(not sol in crowd.soldiers, "the soldier is taken off the soldiers' roll")
	# The dead and the freed are let go without a call on a freed body.
	var q: Person = crowd.citizens[1]
	q.ground_pos = Vector2(2.7, 17.5)
	d.send_off(q)
	var r: Person = crowd.citizens[2]
	r.ground_pos = Vector2(2.7, 17.5)
	d.send_off(r)
	crowd.citizens.erase(q)
	q.free()
	d._step_leaving()
	t.check(d.leaving.size() == 1 and d.is_leaving(r), "a leaver freed meanwhile is dropped")
	t.check(not d.is_leaving(q), "and is_leaving() answers for a freed body")
	_done(s)


static func _lie_left(t) -> void:
	var s := _world()
	var crowd: Crowd = s.crowd
	t.near(crowd.lie_left(), 0.0, 0.0001, "the bell does not lie to begin with: nothing left")
	crowd.bell_lies(45.0)
	t.near(crowd.lie_left(), 45.0, 0.001, "a lie of 45 s has 45 s left")
	for i in roundi(5.0 / DT):
		crowd.advance(DT)
	t.near(crowd.lie_left(), 40.0, 0.2, "five seconds on, 40 left")
	for i in roundi(41.0 / DT):
		crowd.advance(DT)
	t.near(crowd.lie_left(), 0.0, 0.0001, "once it has run out, 0")
	t.check(not crowd.is_bell_lying(), "and the bell no longer lies")
	_done(s)
