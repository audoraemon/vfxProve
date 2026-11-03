extends RefCounted
## Dragonfire ground fire, Task 1 (groundwork): GroundFire patches kept by the FireManager. They burn down in 40 s, burn
## whoever stays in them (1.5 s kills, a dash scorches), are a danger the town fears and routes round, may catch a touching
## building, never draw the building fires' random stream, and are inert when none is laid.

const G := Vector2(2.75, 11.25)  # the Main Gate's plaza: open ground, no building within a few units
const FAR := Vector2(-60.0, -60.0)  # off the map: no one, no building


static func _make(seed_value := 5) -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, seed_value)
	crowd.spawn()
	return [crowd, env, field, world]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[3] as Node).free()


## Everyone well away from the stage, so only the people a test places are near.
static func _clear_away(crowd: Crowd) -> void:
	for p in crowd.citizens:
		p.mind = Person.Mind.CALM
		p._goal = Vector2.INF
		p.ground_pos = FAR + Vector2(20.0, 20.0)


static func _hold(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF


static func run(t) -> void:
	_burns_down(t)
	_danger(t)
	_harm_kills(t)
	_dash_scorches(t)
	_once_in_overlap(t)
	_inside_safe(t)
	_catching(t)
	_own_stream(t)
	_inert_when_empty(t)
	_clear(t)
	_clear_effects(t)


static func _fire_danger_at(crowd: Crowd, at: Vector2) -> bool:
	for th in crowd.threats.nearby(at, 0.0):
		if th.kind == &"fire":
			return true
	return false


static func _burns_down(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	var p := fm.lay(FAR)
	for i in 159:
		fm._burn_patches(0.25)
	t.check(not p.out and fm.patches.size() == 1 and is_equal_approx(p.strength, 0.00625),
		"ground fire: still burning after 39.75 s (strength %.5f)" % p.strength)
	fm._burn_patches(0.25)
	t.check(p.out and not p.beaten and fm.patches_burned_out == 1 and fm.patches.is_empty() and fm.patches_laid == 1,
		"ground fire: out at 40 s, burned out and gone from the list")
	var q := GroundFire.new()
	q.burn_down(1.0, 3)
	t.check(is_equal_approx(q.strength, 0.82), "ground fire: three beaters take 0.18 a second (%.3f)" % q.strength)
	var r := GroundFire.new()
	r.burn_down(100.0, 1)
	t.check(r.out and r.beaten and r.strength == 0.0, "ground fire: put out with a beater beating is beaten")
	_done(made)


static func _danger(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	_clear_away(crowd)
	var p := fm.lay(G)
	var th := crowd.threats.get_threat(p.threat_id)
	t.check(crowd.threats.is_active(p.threat_id) and (th.at as Vector2).is_equal_approx(G)
		and is_equal_approx(float(th.radius), 1.0) and th.kind == &"fire", "ground fire: its danger is registered at once")
	var near: Person = crowd.citizens[0]
	var far: Person = crowd.citizens[1]
	_hold(near, G + Vector2(2.0, 0.0))
	_hold(far, G + Vector2(4.0, 0.0))
	crowd._watch_threats()
	t.check(near.mind != Person.Mind.CALM, "ground fire: a calm citizen 2.0 away takes fright")
	t.check(far.mind == Person.Mind.CALM, "ground fire: one 4.0 away stays calm")
	var id := p.threat_id
	var epoch := crowd.threats.epoch
	fm._burn_patches(100.0)
	t.check(p.out and not crowd.threats.is_active(id) and crowd.threats.epoch > epoch, "ground fire: its danger ends the moment it is out")
	# Out right after a renewal: the danger before the renewal has up to 0.5 s left, and ends too.
	var q := fm.lay(G + Vector2(6.0, 0.0))
	for i in 12:
		fm._burn_patches(0.25)
	t.check(q.prev_threat_id != -1 and crowd.threats.is_active(q.prev_threat_id), "ground fire: a renewal leaves the old danger to expire")
	fm._burn_patches(100.0)
	t.check(q.out and not _fire_danger_at(crowd, q.at), "ground fire: out just after a renewal, no fire danger is left there")
	_done(made)


static func _harm_kills(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[2]
	_clear_away(crowd)
	var patch := GroundFire.new(G, GroundFire.RADIUS, 1)
	var heat := {}
	var c: Person = crowd.citizens[0]
	for i in 14:
		_hold(c, G)
		GroundFire.scorch(field, [patch], heat, GroundFire.HARM_TICK)
	t.check(c.is_alive(), "ground fire: alive after 1.4 s inside")
	_hold(c, G)
	var deaths := GroundFire.scorch(field, [patch], heat, GroundFire.HARM_TICK)
	t.check(not c.is_alive() and deaths == 1 and c._kind == &"fire" and not heat.has(c),
		"ground fire: dead (fire) at the 15th tick, 1.5 s")
	_done(made)


static func _dash_scorches(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[2]
	_clear_away(crowd)
	var patch := GroundFire.new(G, GroundFire.RADIUS, 1)
	var heat := {}
	var c: Person = crowd.citizens[0]
	for i in 9:
		_hold(c, G)
		GroundFire.scorch(field, [patch], heat, GroundFire.HARM_TICK)
	_hold(c, G + Vector2(2.0, 0.0))
	GroundFire.scorch(field, [patch], heat, GroundFire.HARM_TICK)
	t.check(c.is_alive() and c.scorched_left > 0.0 and c.mind == Person.Mind.PANIC and c._startle_left == 0.0,
		"ground fire: a dash leaves a person alive, scorched and fleeing, with no startle")
	for i in 17:
		_hold(c, G + Vector2(2.0, 0.0))
		GroundFire.scorch(field, [patch], heat, GroundFire.HARM_TICK)
	t.check(not heat.has(c), "ground fire: the heat leaves once out (18 ticks)")
	for i in 9:
		_hold(c, G)
		GroundFire.scorch(field, [patch], heat, GroundFire.HARM_TICK)
	t.check(c.is_alive(), "ground fire: cooled, a second dash is survived too")
	# A second dash right after a first starts warm and kills.
	var d: Person = crowd.citizens[1]
	var heat2 := {}
	for i in 9:
		_hold(d, G)
		GroundFire.scorch(field, [patch], heat2, GroundFire.HARM_TICK)
	_hold(d, G + Vector2(2.0, 0.0))
	GroundFire.scorch(field, [patch], heat2, GroundFire.HARM_TICK)
	for i in 9:
		_hold(d, G)
		GroundFire.scorch(field, [patch], heat2, GroundFire.HARM_TICK)
	t.check(not d.is_alive(), "ground fire: a second dash soon after a first kills")
	_done(made)


static func _once_in_overlap(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[2]
	_clear_away(crowd)
	var a := GroundFire.new(G, GroundFire.RADIUS, 1)
	var b := GroundFire.new(G + Vector2(0.3, 0.0), GroundFire.RADIUS, 2)
	var heat := {}
	var c: Person = crowd.citizens[0]
	for i in 14:
		_hold(c, G + Vector2(0.15, 0.0))
		GroundFire.scorch(field, [a, b], heat, GroundFire.HARM_TICK)
	t.check(c.is_alive() and is_equal_approx(float(heat[c].heat), 1.4), "ground fire: in two patches a person heats once a tick")
	_done(made)


static func _inside_safe(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[2]
	_clear_away(crowd)
	var patch := GroundFire.new(G, GroundFire.RADIUS, 1)
	var heat := {}
	var c: Person = crowd.citizens[0]
	c.inside = true
	for i in 30:
		_hold(c, G)
		GroundFire.scorch(field, [patch], heat, GroundFire.HARM_TICK)
	t.check(c.is_alive() and heat.is_empty() and c.scorched_left == 0.0, "ground fire: a person inside a building is never heated")
	c.inside = false
	_done(made)


static func _catching(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var fm := crowd.fires
	# A house with no other structure near its east side, and a stone wall with no burnable near it.
	var house: Structure = null
	var wall: Structure = null
	var reach := GroundFire.RADIUS + GroundFire.TOUCH
	for s in env.structures():
		if house == null and s.kind == Structure.Kind.HOUSE and s.role == &"house" and not s.destroyed:
			var only := true
			for d in [0.9, 1.3]:
				var g := Vector2(s.footprint.end.x + d, s.center().y)
				for n in env.near(g, reach):
					if n != s and FireManager.burns(n) and n.distance_to(g) <= reach:
						only = false
			if only:
				house = s
		if wall == null and s.kind == Structure.Kind.CASTLE_WALL:
			var clean := true
			for n in env.near(s.center(), reach):
				if n != s and FireManager.burns(n) and n.distance_to(s.center()) <= reach:
					clean = false
			if clean:
				wall = s
	t.check(house != null and wall != null, "ground fire: the test town has a lone house and a clean wall")
	if house == null or wall == null:
		_done(made)
		return
	var east := Vector2(house.footprint.end.x, house.center().y)
	var near := GroundFire.new(east + Vector2(0.9, 0.0), GroundFire.RADIUS, 1)
	var far := GroundFire.new(east + Vector2(1.3, 0.0), GroundFire.RADIUS, 2)
	t.check(FireManager.patch_catch(env, near, fm.fires) == house, "ground fire: a house 0.9 from the centre is caught (within 1.0)")
	t.check(FireManager.patch_catch(env, far, fm.fires) == null, "ground fire: a house 1.3 away is not")
	var on_wall := GroundFire.new(wall.center(), GroundFire.RADIUS, 3)
	t.check(FireManager.patch_catch(env, on_wall, fm.fires) == null, "ground fire: a stone wall is not caught")
	fm.ignite(house, 0.5)
	t.check(FireManager.patch_catch(env, near, fm.fires) == null, "ground fire: a building already burning is not caught again")
	t.check(FireManager.spread_chance(1.0, false, 0.25) == 0.02 and is_equal_approx(FireManager.spread_chance(1.0, true, 0.25), 0.06)
		and is_equal_approx(FireManager.spread_chance(0.5, false, 0.25), 0.01), "ground fire: spread chance is strength x 0.08 x dt, windy x3")
	# And it really does set the house alight when the roll hits: beside the house, many steps.
	fm.fires.clear()
	var lit := fm.lay(near.at)
	for i in 2000:
		fm._burn_patches(0.25)
		if fm.is_burning(house):
			break
		lit.strength = 1.0
	t.check(fm.is_burning(house), "ground fire: a patch beside a house sets it alight in time")
	_done(made)


static func _own_stream(t) -> void:
	var a := _make()
	var b := _make()
	var ca: Crowd = a[0]
	var cb: Crowd = b[0]
	ca.fires.lay(FAR)
	for i in 120:
		ca.fires.step(0.25)
		cb.fires.step(0.25)
	t.check(ca.fires.fires.is_empty() and ca.fires._rng.state == cb.fires._rng.state,
		"ground fire: a patch never draws the building fires' random stream")
	t.check(ca.fires._patch_rng.state != cb.fires._patch_rng.state, "ground fire: its own stream is what it draws")
	_done(a)
	_done(b)


## A patch that touches no one changes nothing around it. That an EMPTY manager equals the old code is proven by the
## references (digest, crowd_check), not here.
static func _inert_when_empty(t) -> void:
	var a := _make()
	var b := _make()
	var ca: Crowd = a[0]
	var cb: Crowd = b[0]
	# Both towns blind to the far corner: a patch laid there registers no danger and touches no one.
	ca.veil(FAR, 5.0, 1000.0)
	cb.veil(FAR, 5.0, 1000.0)
	cb.fires.lay(FAR)
	for i in 1200:
		ca.advance(1.0 / 60.0)
		cb.advance(1.0 / 60.0)
	var same := ca.fires._rng.state == cb.fires._rng.state and ca.fires.fires.size() == cb.fires.fires.size() \
		and ca.threats.epoch == cb.threats.epoch and ca.citizens.size() == cb.citizens.size()
	for i in ca.citizens.size():
		if ca.citizens[i].ground_pos != cb.citizens[i].ground_pos:
			same = false
	t.check(same, "ground fire: a laid patch that touches no one changes nothing in the town")
	_done(a)
	_done(b)


static func _clear(t) -> void:
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	_clear_away(crowd)
	var p := fm.lay(G)
	var q := fm.lay(G + Vector2(5.0, 0.0))
	var c: Person = crowd.citizens[0]
	_hold(c, G)
	fm.step(GroundFire.HARM_TICK + 0.01)
	t.check(not fm._heat.is_empty(), "ground fire: the manager's step heats who stands in it")
	fm.clear()
	t.check(p.out and q.out and fm.patches.is_empty() and fm._heat.is_empty(), "ground fire: clear() puts every patch out")
	var epoch := crowd.threats.epoch
	var active := crowd.threats.active_count()
	crowd.threats.end(9999)
	crowd.threats.end(-1)
	t.check(crowd.threats.epoch == epoch and crowd.threats.active_count() == active, "ground fire: ending an unknown threat does nothing")
	fm.clear_patches()
	t.check(fm.patches.is_empty(), "ground fire: clear_patches() on none is safe")
	_done(made)


## Battlefield.clear_effects() puts every patch out and ends its danger (Dragonfire's ground fire is not left unseen).
static func _clear_effects(t) -> void:
	const FxStage := preload("res://tests/fx_stage.gd")
	var made := _make()
	var crowd: Crowd = made[0]
	var fm := crowd.fires
	var bf := FxStage.make(3)
	bf.ctx.crowd = crowd
	var p := fm.lay(G)
	for i in 12:
		fm._burn_patches(0.25)
	t.check(_fire_danger_at(crowd, G), "ground fire: a patch is a fire danger before the stage is cleared")
	bf.clear_effects()
	t.check(p.out and fm.patches.is_empty() and fm._heat.is_empty() and not _fire_danger_at(crowd, G),
		"ground fire: Battlefield.clear_effects() clears the patches and their danger")
	bf.ctx.crowd = null
	FxStage.drop(bf)
	_done(made)
