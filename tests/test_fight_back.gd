extends RefCounted
## Fights with the dead look like fights (Death second review, R30-R32): a soldier's blow on an undead shows his swing; every
## blow flinches the undead (a flash and a draw-only recoil); a citizen an undead holds in reach is cornered (Crowd.cornered(),
## Visitors.corners()) and fights back with weaker blows that never reset its bite; bare hands do nothing to a spirit.

const DT := 0.05
## The pin's own source id (hold_pace()).
const PIN := 4242


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
	var visitors := Visitors.new().setup(field, crowd, grid, world)
	return [crowd, env, grid, field, world, visitors]


static func _done(made: Array) -> void:
	(made[5] as Visitors).clear()
	(made[0] as Crowd).clear()
	(made[4] as Node).free()


## Everyone far off in a corner, out of every reach.
static func _clear_town(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		i += 1


static func _step(v: Visitors, seconds: float) -> void:
	for i in roundi(seconds / DT):
		v.step(DT)


## A fresh pack in place of the old one.
static func _fresh(made: Array) -> Visitors:
	(made[5] as Visitors).clear()
	var v := Visitors.new().setup(made[3], made[0], made[2], made[4])
	made[5] = v
	_clear_town(made[0])
	return v


static func _zombie(v: Visitors, at: Vector2, bite := false) -> Animal:
	var r := Remains.Remain.new()
	r.pos = at
	r.design = PeopleArt.design_for(false, 0, 0, 0.1)
	r.kind = &"frenzy"
	var z := DeathParts.zombie(v, r, false)
	if not bite:
		v.give(z, {"no_bite": true})
	return z


## A citizen pinned where he stands (no step of his own), at `at`.
static func _pinned(p: Person, at: Vector2) -> Person:
	p.ground_pos = at
	p.hold_pace(PIN, 0.0)
	return p


static func _facing_to(p: Person, g: Vector2) -> int:
	return 1 if g.x - g.y > p.ground_pos.x - p.ground_pos.y else -1


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var v: Visitors = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	_clear_town(crowd)

	# --- A soldier's blow shows his swing, and the struck zombie flinches.
	var sol: Person = crowd.soldiers[0]
	sol.ground_pos = at + Vector2(0.4, 0.0)
	var z := _zombie(v, at)
	var was_at := z.ground_pos
	var took := 0.0
	for i in 30:
		was_at = z.ground_pos
		v.step(DT)
		took += DT
		if z.health < 3.0:
			break
	t.check(is_equal_approx(z.health, 2.0) and took <= Visitors.GUARD_SWING + 0.05 + 0.001 and sol._swing_left > 0.0
		and sol._facing == _facing_to(sol, z.ground_pos),
		"a soldier's blow on a zombie shows his swing (health %.2f at %.2f s, swing %.2f)" % [z.health, took, sol._swing_left])
	var off := z.recoil_offset()
	var away := Iso.ground_to_screen(z.ground_pos) - Iso.ground_to_screen(sol.ground_pos)
	t.check(z._flash > 0.0 and off.length() >= 2.0 and off.length() <= 3.0 and off.dot(away) > 0.0
		and z.ground_pos == was_at,
		"each blow flinches the undead: a flash and a 2-3 px recoil, and nothing moves (%s, %.2f px)" % [off, off.length()])
	_step(v, 0.2)
	t.check(z.recoil_offset() == Vector2.ZERO, "the recoil eases back to nothing within 0.2 s (%s)" % z.recoil_offset())
	# The wraith's tick returns early (its own sheet): its recoil eases back all the same.
	var w := Animal.new()
	w.breed = Animal.Breed.WRAITH
	w.ground_pos = at
	w.struck_from(at + Vector2(-0.4, 0.0))
	var w_off := w.recoil_offset().length()
	for i in 4:
		w.tick_visual(DT)
	t.check(w_off > 2.0 and w.recoil_offset() == Vector2.ZERO, "a wraith's recoil eases back too (%s)" % w.recoil_offset())
	w.free()
	v = _fresh(made)

	# --- A cornered citizen fights back.
	var c: Person = _pinned(crowd.citizens[0], at)
	var cz := _zombie(v, at + Vector2(0.4, 0.0))
	_step(v, 0.3)
	t.check(not crowd.cornered(c), "not cornered before CORNER_HOLD")
	_step(v, 0.25)
	t.check(crowd.cornered(c) and v.corners(c), "a citizen a zombie holds in reach is cornered by 0.55 s")
	_step(v, Visitors.CORNER_HOLD + Visitors.CITIZEN_SWING + 0.05 - 0.55)
	# His counter-blow as it stood in his reach (R30a), then his first cornered blow a swing after CORNER_HOLD.
	t.check(is_equal_approx(cz.health, 3.0 - 2.0 * Visitors.CITIZEN_BLOW) and c._swing_left > 0.0
		and c._facing == _facing_to(c, cz.ground_pos),
		"a citizen a zombie holds in reach is cornered and fights back (health %.2f, swing %.2f)" % [cz.health, c._swing_left])
	# Weaker, and never resets the bite: over 5 s from the start, at most ceil(5 / 1.2) blows of 0.5.
	var rule: Visitors.Rule = v._rules[cz]
	var never_up := true
	var steps := roundi((5.0 - 1.75) / DT)
	for i in steps:
		var hp := cz.health
		var before := rule.bite_in
		v.step(DT)
		if cz.health < hp and rule.bite_in > before:
			never_up = false
	var most := ceilf(5.0 / Visitors.CITIZEN_SWING) * Visitors.CITIZEN_BLOW
	t.check(never_up and 3.0 - cz.health <= most + 0.001 and cz.health < 2.0,
		"a citizen's blow is weaker and never resets the bite (took %.2f, most %.2f)" % [3.0 - cz.health, most])
	c.free_pace(PIN)
	v = _fresh(made)

	# --- One who outruns it is never cornered (it bites, if it can reach him).
	var runner: Person = crowd.citizens[1]
	runner.ground_pos = at + Vector2(0.9, 0.0)
	var rz := _zombie(v, at, true)
	runner.panic(rz.ground_pos, 1.0, &"", false)
	var ever := false
	for i in roundi(3.0 / DT):
		var dir := (runner.ground_pos - rz.ground_pos).normalized()
		runner.ground_pos += dir * runner.walk_speed * DT
		v.step(DT)
		if crowd.cornered(runner):
			ever = true
	t.check(not ever and runner.walk_speed > 0.75, "one who outruns it is never cornered (pace %.2f)" % runner.walk_speed)
	v = _fresh(made)

	# --- Bare hands do nothing to a pale ghost.
	var g: Person = _pinned(crowd.citizens[2], at)
	var pg := DeathParts.pale_ghost(v, at + Vector2(0.3, 0.0), at, 5.0)
	v.give(pg, {"touch_kill": &"", "no_bite": true})
	_step(v, Visitors.CORNER_HOLD + Visitors.CITIZEN_SWING + 0.3)
	t.check(v.corners(g) and g._swing_left > 0.0 and is_equal_approx(pg.health, float(DeathParts.SPIRIT_BLOWS)),
		"bare hands do not hurt a pale ghost (cornered %s, swing %.2f, health %.1f)" % [v.corners(g), g._swing_left, pg.health])
	g.free_pace(PIN)
	v = _fresh(made)

	# --- A ghoul halts at its leap's reach; it can be struck back there, and falls to four bare-hand blows.
	var gc: Person = _pinned(crowd.citizens[3], at)
	var gh := DeathParts.ghoul(v, at + Vector2(0.7, 0.0))
	v.give(gh, {"no_bite": true})
	var cuts := [0]
	v.cut_down.connect(func(_a: Animal, _at: Vector2) -> void: cuts[0] += 1)
	_step(v, Visitors.CORNER_HOLD + 4.0 * Visitors.CITIZEN_SWING + 0.3)
	t.check(not is_instance_valid(gh) or not gh.is_alive(), "a ghoul falls to four bare-hand blows")
	t.check(v.slain == 1 and cuts[0] == 1 and v.living().is_empty(),
		"a citizen's cut-down counts as slain and is told (slain %d, told %d)" % [v.slain, cuts[0]])
	gc.free_pace(PIN)
	v = _fresh(made)

	# --- Down or freed: no blow.
	var d: Person = _pinned(crowd.citizens[4], at)
	var dz := _zombie(v, at + Vector2(0.4, 0.0))
	_step(v, 0.6)
	t.check(crowd.cornered(d), "the one to be knocked down is cornered first")
	var d_hp := dz.health  # his counter-blow only (R30a)
	d.knock_down()
	_step(v, 3.0)
	t.check(d.is_down() and not crowd.cornered(d) and is_equal_approx(dz.health, d_hp)
		and is_equal_approx(d_hp, 3.0 - Visitors.CITIZEN_BLOW),
		"down or freed: no blow while he is down (health %.2f, at the knock %.2f)" % [dz.health, d_hp])
	v = _fresh(made)
	var f: Person = _pinned(crowd.citizens[5], at)
	var fz := _zombie(v, at + Vector2(0.4, 0.0))
	_step(v, 1.5)  # cornered, the first blow near
	t.check(crowd.cornered(f), "the one whose zombie is freed is cornered first")
	fz.free()
	_step(v, 1.5)
	t.check(not crowd.cornered(f) and v.slain == 0 and v._rules.is_empty(),
		"down or freed: the zombie freed between steps, the next steps run and land nothing")
	f.free_pace(PIN)
	v = _fresh(made)

	# --- The counter-blow (R30a): a BITING zombie comes up to a pinned citizen; he strikes the moment it comes within his
	# reach, before its first bite knocks him down.
	var k: Person = _pinned(crowd.citizens[6], at)
	var kz := _zombie(v, at + Vector2(2.0, 0.0), true)
	var hit_at := -1
	var down_at := -1
	for i in roundi(4.0 / DT):
		v.step(DT)
		if hit_at < 0 and kz.health < float(DeathParts.ZOMBIE_BLOWS):
			hit_at = i
		if down_at < 0 and k.is_down():
			down_at = i
			break
	t.check(down_at >= 0 and hit_at >= 0 and hit_at <= down_at
		and is_equal_approx(kz.health, float(DeathParts.ZOMBIE_BLOWS) - Visitors.CITIZEN_BLOW) and k._swing_left > 0.0,
		"a biting zombie that reaches him takes his counter-blow before he is knocked down (hit step %d, down step %d, health %.2f)"
			% [hit_at, down_at, kz.health])
	var kr: Visitors.Rule = v._rules[kz]
	t.check(kr.bite_in > 0.0, "the counter-blow does not begin the zombie's bite again: it bit (bite in %.2f)" % kr.bite_in)
	k.free_pace(PIN)
	v = _fresh(made)

	# Summoned already within his reach: the counter lands in the same step, before the bite.
	var k2: Person = _pinned(crowd.citizens[7], at)
	var kz2 := _zombie(v, at + Vector2(0.4, 0.0), true)
	v.step(DT)
	t.check(k2.is_down() and is_equal_approx(kz2.health, float(DeathParts.ZOMBIE_BLOWS) - Visitors.CITIZEN_BLOW),
		"a biting zombie already in his reach takes his counter-blow in the very step it knocks him down (health %.2f)"
			% kz2.health)
	_step(v, 2.0)
	t.check(is_equal_approx(kz2.health, float(DeathParts.ZOMBIE_BLOWS) - Visitors.CITIZEN_BLOW),
		"knocked down, he strikes no more (health %.2f)" % kz2.health)
	k2.free_pace(PIN)
	v = _fresh(made)

	# --- A biting skeleton: its first strike kills, yet he lands his one blow before he dies.
	var sk: Person = _pinned(crowd.citizens[8], at)
	var skel := DeathParts.skeleton(v, at + Vector2(2.0, 0.0))
	var sk_died := -1
	var sk_hit := -1
	for i in roundi(5.0 / DT):
		v.step(DT)
		if sk_hit < 0 and skel.health < float(DeathParts.SKELETON_BLOWS):
			sk_hit = i
		if not sk.is_alive():
			sk_died = i
			break
	t.check(sk_died >= 0 and sk_hit >= 0 and sk_hit <= sk_died
		and is_equal_approx(skel.health, float(DeathParts.SKELETON_BLOWS) - Visitors.CITIZEN_BLOW),
		"a biting skeleton's victim lands one blow before he dies (hit step %d, died step %d, health %.2f)"
			% [sk_hit, sk_died, skel.health])
	sk.free_pace(PIN)
	v = _fresh(made)

	# --- A giant's long reach shadowing a skeleton does not waste his blow: he strikes the nearest SOLID one in reach.
	var sh: Person = _pinned(crowd.citizens[9], at)
	var sh_sk := DeathParts.skeleton(v, at + Vector2(0.5, 0.0))
	v.give(sh_sk, {"no_bite": true})
	var giant := v.summon(at + Vector2(0.0, 0.3), Animal.Breed.BONE_GIANT, 12, 1.0, 10.0, 0.9, 1.4, false)
	v.give(giant, {"prey": "soldiers", "no_bite": true})
	_step(v, Visitors.CORNER_HOLD + Visitors.CITIZEN_SWING + 0.1)
	t.check(is_equal_approx(sh_sk.health, float(DeathParts.SKELETON_BLOWS) - 2.0 * Visitors.CITIZEN_BLOW)
		and is_equal_approx(giant.health, 12.0),
		"a nearer giant does not take the blow meant for the skeleton (skeleton %.2f, giant %.2f)" % [sh_sk.health, giant.health])
	sh.free_pace(PIN)

	_done(made)
