extends RefCounted
## World Map + Conquer Progress Task 2: BelieverRoll marks a town's carried believers with a generator of its own, counts the deaths once
## each, keeps the escaped as alive, and a count of 0 draws nothing from any stream.


static func run(t) -> void:
	_marks_n(t)
	_skips_reserved(t)
	_same_seed(t)
	_zero_draws_nothing(t)
	_marking_leaves_streams(t)
	_too_many(t)
	_deaths_once(t)
	_escaped_alive(t)
	_report_keys(t)


## Aldermere with its crowd (seed 5), a Tier 1 def's director and a Descent attached, so wishes reserve their people.
static func _world(crowd_seed := 5) -> Dictionary:
	var def := TierBook.board("tax_collector")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, crowd_seed)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var made := def.make_director()
	var director: MissionDirector = made.setup(rules, crowd, town, null) if made != null else null
	rules.director = director
	var descent := Descent.new().setup(def, 7)
	descent.attach(rules, director)
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director, "descent": descent}


static func _reserved(s: Dictionary) -> Array:
	var out: Array = (s.d as MissionDirector).reserved.duplicate() if s.d != null else []
	for w in (s.descent as Descent).wishes:
		out.append_array(w.people())
	return out


static func _roll(s: Dictionary, roll_seed := 11) -> BelieverRoll:
	return BelieverRoll.new().setup(s.crowd, "aldermere", roll_seed)


static func _done(s: Dictionary, roll: BelieverRoll) -> void:
	roll.release()
	(s.descent as Descent).release()
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


static func _count_believers(crowd: Crowd) -> int:
	var n := 0
	for p in crowd.citizens:
		if p.profile != null and p.profile.faith == CitizenProfile.Faith.BELIEVER:
			n += 1
	return n


static func _indices(crowd: Crowd, roll: BelieverRoll) -> Array:
	var out := []
	for i in crowd.citizens.size():
		if roll.is_carried(crowd.citizens[i]):
			out.append(i)
	return out


static func _marks_n(t) -> void:
	var s := _world()
	var roll := _roll(s)
	var before := _count_believers(s.crowd)
	var n := roll.mark_carried(12, _reserved(s))
	var carried := 0
	for p in (s.crowd as Crowd).citizens:
		if roll.is_carried(p):
			carried += 1
			t.check(p.profile.faith == CitizenProfile.Faith.BELIEVER, "a carried person is a believer")
	t.check(n == 12 and roll.marked.size() == 12 and carried == 12 and roll.unplaced == 0 and roll.asked == 12,
		"count 12 marks 12 (%d, %d, %d, unplaced %d)" % [n, roll.marked.size(), carried, roll.unplaced])
	t.check(_count_believers(s.crowd) == before + 12, "and no other citizen changed faith")
	_done(s, roll)


static func _skips_reserved(t) -> void:
	var was := Children.enabled
	Children.enabled = true
	var s := _world()
	var roll := _roll(s)
	var reserved := _reserved(s)
	roll.mark_carried(60, reserved)
	var bad := 0
	var children := 0
	for p in roll.marked:
		if reserved.has(p) or p.soldier or p.profile.role == CitizenProfile.Role.CHILD:
			bad += 1
	for p in (s.crowd as Crowd).citizens:
		if p.profile != null and p.profile.role == CitizenProfile.Role.CHILD:
			children += 1
	t.check(roll.marked.size() > 0 and bad == 0, "no marked person is reserved, a soldier or a child (%d bad of %d, %d children in town)" % [bad, roll.marked.size(), children])
	_done(s, roll)
	Children.enabled = was


static func _same_seed(t) -> void:
	var a := _world(5)
	var ra := _roll(a, 11)
	ra.mark_carried(15, _reserved(a))
	var b := _world(5)
	var rb := _roll(b, 11)
	rb.mark_carried(15, _reserved(b))
	var c := _world(5)
	var rc := _roll(c, 12)
	rc.mark_carried(15, _reserved(c))
	var ia := _indices(a.crowd, ra)
	t.check(ia.size() == 15 and ia == _indices(b.crowd, rb), "the same crowd seed and roll seed mark the same citizens")
	t.check(ia != _indices(c.crowd, rc), "another roll seed marks others")
	_done(a, ra)
	_done(b, rb)
	_done(c, rc)


static func _snapshot(crowd: Crowd) -> Array:
	var out := [crowd._rng.state]
	for p in crowd.citizens:
		out.append([p.rng.state, p.profile.faith if p.profile != null else -1])
	return out


static func _zero_draws_nothing(t) -> void:
	var s := _world()
	var roll := _roll(s)
	var before := _snapshot(s.crowd)
	var n := roll.mark_carried(0, _reserved(s))
	t.check(n == 0 and roll.marked.is_empty() and roll.unplaced == 0, "count 0 marks nobody")
	t.check(_snapshot(s.crowd) == before, "and every stream and faith is as it was")
	_done(s, roll)


static func _marking_leaves_streams(t) -> void:
	var s := _world()
	var roll := _roll(s)
	var before := _snapshot(s.crowd)
	roll.mark_carried(30, _reserved(s))
	var after := _snapshot(s.crowd)
	var same: bool = after[0] == before[0]
	for i in range(1, before.size()):
		same = same and after[i][0] == before[i][0]
	t.check(same, "marking 30 leaves the crowd's stream and every person's stream alone")
	_done(s, roll)


static func _too_many(t) -> void:
	var s := _world()
	var roll := _roll(s)
	var pool := 0
	var reserved := _reserved(s)
	for p in (s.crowd as Crowd).citizens:
		if BelieverRoll.eligible(p, reserved):
			pool += 1
	var n := roll.mark_carried(10000, reserved)
	t.check(n == pool and roll.marked.size() == pool and pool > 0, "10000 marks every eligible citizen (%d of %d)" % [n, pool])
	t.check(roll.unplaced == 10000 - pool and roll.carried_alive() == 10000, "the rest are unplaced, and all 10000 still count (%d)" % roll.carried_alive())
	_done(s, roll)


static func _deaths_once(t) -> void:
	var s := _world()
	var roll := _roll(s)
	roll.mark_carried(10, _reserved(s))
	var field: EnemyField = s.field
	var a: Person = roll.marked[0]
	var b: Person = roll.marked[1]
	field.kill(a, &"test")
	field.kill(b, &"test")
	t.check(roll.lost == 2, "two marked deaths cost 2 (%d)" % roll.lost)
	field.enemy_killed.emit(a, &"test")
	t.check(roll.lost == 2, "the same death twice still costs once")
	t.check(roll.carried_alive() == 8, "carried_alive is 8 (%d)" % roll.carried_alive())
	var other: Person = null
	for p in (s.crowd as Crowd).citizens:
		if p.is_alive() and not p.soldier and not roll.is_carried(p) and p.profile.faith == CitizenProfile.Faith.NONE:
			other = p
			break
	field.kill(other, &"test")
	t.check(roll.lost == 2, "a non-believer's death costs nothing (%d)" % roll.lost)
	_done(s, roll)


static func _escaped_alive(t) -> void:
	var s := _world()
	var roll := _roll(s)
	roll.mark_carried(10, _reserved(s))
	var before := roll.carried_alive()
	(s.crowd as Crowd).escape(roll.marked[0])
	t.check(before == 10 and roll.carried_alive() == 10 and roll.lost == 0, "an escaped believer is still counted, alive (%d)" % roll.carried_alive())
	_done(s, roll)


static func _report_keys(t) -> void:
	var s := _world()
	var roll := _roll(s)
	roll.mark_carried(5, _reserved(s))
	var r := roll.report(true, false, [])
	var keys := r.keys()
	keys.sort()
	t.check(keys == ["carried", "carried_alive", "fill", "lost", "marked", "named", "town"], "the report's keys (%s)" % [keys])
	t.check(r.town == "aldermere" and r.carried == 5 and r.marked == 5 and r.carried_alive == 5 and r.named == 0 and r.fill == 0 and r.lost == 0,
		"and values (%s)" % [r])
	_done(s, roll)
