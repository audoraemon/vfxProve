extends RefCounted
## Death's undead kit (Death authority, spec 5.1 and 6): zombies wearing the dead person's own sprite, the pale spirit,
## the wraith and the bone giant breed, and the Visitors traits they go by (knock_first, infect, spare_guise, prey,
## fright_r, slow_pass). Every Death power that raises or calls the dead spawns through DeathParts.

const DT := 0.05


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


static func _remain(at: Vector2, design: String, sick := false) -> Remains.Remain:
	var r := Remains.Remain.new()
	r.pos = at
	r.design = design
	r.sick = sick
	r.kind = &"frenzy"
	return r


static func run(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var v: Visitors = made[5]
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())
	_clear_town(crowd)

	t.check(Animal.Breed.GHOST == 12 and Animal.Breed.ZOMBIE == 13 and Animal.Breed.SPIRIT == 14 and Animal.Breed.BONE_GIANT == 15
		and Animal.UNDEAD == [Animal.Breed.ZOMBIE, Animal.Breed.SPIRIT, Animal.Breed.BONE_GIANT, Animal.Breed.WRAITH]
		and not (Animal.Breed.ZOMBIE in Animal.DOGS) and not (Animal.Breed.SPIRIT in Animal.CATS)
		and Animal.sheet(Animal.Breed.BONE_GIANT).get("cell", 0) == 96
		and Animal.sheet(Animal.Breed.SPIRIT).is_empty() and Animal.sheet(Animal.Breed.ZOMBIE).is_empty(),
		"the three breeds are appended (indices kept), the giant has its 96 px sheet, the zombie and spirit have none")

	# --- Zombie wears the dead person's design.
	var design := PeopleArt.design_for(false, 0, 0, 0.1)
	var r := _remain(at, design)
	var z := DeathParts.zombie(v, r, false)
	t.check(z.breed == Animal.Breed.ZOMBIE and z.ground_pos == at and z.worn == design and v.living().has(z)
		and is_equal_approx(z.health, float(DeathParts.ZOMBIE_BLOWS)),
		"zombie wears the dead person's design, rises at the remain, takes ZOMBIE_BLOWS blows")
	var blind := DeathParts.zombie(v, r, false, Color(1, 1, 1, 0))
	t.check(z.eyes == DeathParts.GRAVE_GREEN and blind.eyes.a == 0.0,
		"a zombie's eyes are grave green unless the caller gives none")
	z.target = null
	t.check(is_equal_approx(z.speed(), 0.6), "zombie walks at a walk (0.6 u/s) with no prey (%.3f)" % z.speed())
	z.target = crowd.citizens[0]
	t.check(is_equal_approx(z.speed(), 0.75), "zombie chases at 1.25 x walk (0.75 u/s) (%.3f)" % z.speed())
	z.target = null
	v = _fresh(made)

	# --- knock_first: first bite knocks down, second within 3 s kills, after 3 s it knocks again.
	var prey: Person = crowd.citizens[0]
	prey.ground_pos = at + Vector2(0.3, 0.0)
	var a := v.summon(at, Animal.Breed.ZOMBIE, 3, 1.0, 10.0, 0.5, 1.0, true)
	v.give(a, {"knock_first": true})
	_step(v, 0.1)
	t.check(prey.is_alive() and prey.is_down() and a.target == prey, "knock_first: the first bite knocks down, does not kill")
	_step(v, 1.2)
	t.check(not prey.is_alive() and v.kills == 1, "knock_first: a second bite within 3 s kills")
	var prey2: Person = crowd.citizens[1]
	var rr: Visitors.Rule = v._rules[a]
	rr.bite_in = 0.0
	prey2.ground_pos = a.ground_pos + Vector2(0.3, 0.0)
	_step(v, 0.6)  # it looks again for someone within RETARGET
	t.check(prey2.is_alive() and prey2.is_down(), "the next victim is knocked first")
	a.ground_pos = Vector2(27.0, 27.0)  # it is called off, out of everyone's reach
	_step(v, 3.5)
	t.check(prey2.is_alive(), "knock_first: left alone, they live")
	a.ground_pos = prey2.ground_pos + Vector2(0.3, 0.0)
	rr.bite_in = 0.0
	rr.retarget_in = 0.0
	_step(v, 0.1)
	t.check(prey2.is_alive() and prey2.is_down(), "after 3 s the same person is knocked again, not killed")
	v = _fresh(made)

	# --- infect.
	var sick_prey: Person = crowd.citizens[2]
	sick_prey.ground_pos = at + Vector2(0.3, 0.0)
	var b := v.summon(at, Animal.Breed.ZOMBIE, 3, 1.0, 10.0, 0.5, 1.0, true)
	v.give(b, {"knock_first": true, "infect": true})
	_step(v, 0.1)
	t.check(sick_prey.sick_left > 0.0, "infect trait: a bitten citizen is sick")
	v = _fresh(made)

	# --- spare_guise.
	var guised: Person = crowd.citizens[3]
	var other: Person = crowd.citizens[4]
	guised.ground_pos = at + Vector2(0.5, 0.0)
	other.ground_pos = at + Vector2(3.0, 0.0)
	guised.statuses[&"guise"] = 25.0
	var c := v.summon(at, Animal.Breed.ZOMBIE, 3, 1.0, 10.0, 0.5, 1.0, true)
	v.give(c, {"spare_guise": true})
	_step(v, 0.6)
	t.check(c.target == other, "spare_guise: a guised person is never chosen, though nearer")
	guised.statuses.erase(&"guise")
	v = _fresh(made)

	# --- prey soldiers.
	var cit: Person = crowd.citizens[5]
	var sol: Person = crowd.soldiers[0]
	cit.ground_pos = at + Vector2(0.5, 0.0)
	sol.ground_pos = at + Vector2(4.0, 0.0)
	var w := DeathParts.wraith(v, at)
	_step(v, 0.6)
	t.check(w.target == sol and cit.is_alive(), "prey soldiers: a citizen nearer is ignored")
	t.check(w.breed == Animal.Breed.WRAITH, "a wraith is the wraith breed")
	v = _fresh(made)

	# --- Spirit: cannot be cut down; frights within 3.
	var s := DeathParts.spirit(v, at)
	var guard: Person = crowd.soldiers[1]
	guard.ground_pos = s.ground_pos + Vector2(0.2, 0.0)
	var bystander: Person = crowd.citizens[6]
	bystander.ground_pos = at + Vector2(2.0, 0.0)
	var calm_far: Person = crowd.citizens[7]
	calm_far.ground_pos = at + Vector2(14.0, 0.0)
	var rs: Visitors.Rule = v._rules[s]
	_step(v, 5.0)
	t.check(s.is_alive() and v.slain == 0 and rs.phase and is_equal_approx(rs.fright_r, DeathParts.SPIRIT_FRIGHT_R),
		"spirit cannot be cut down (a guard beside it strikes for 5 s)")
	t.check(bystander.mind != Person.Mind.CALM and calm_far.mind == Person.Mind.CALM,
		"spirit frights within 3: the near one is not calm, the far one is")
	var quiet := DeathParts.spirit(v, at, false)
	t.check((v._rules[quiet] as Visitors.Rule).fright_r == 0.0, "a quiet spirit (fright false) frights no one")
	v = _fresh(made)

	# --- Wraith slows who it passes (a citizen; a soldier it reaches it kills) to 0.5 for 4 s.
	var slowed: Person = crowd.citizens[17]
	slowed.ground_pos = at + Vector2(0.3, 0.0)
	var wr := DeathParts.wraith(v, at)
	wr.target = null
	var base := slowed.pace_hold()
	_step(v, 0.2)
	t.check(is_equal_approx(base, 1.0) and slowed.pace_hold() <= 0.5 + 0.001,
		"wraith slows who it passes to 0.5 (%.2f)" % slowed.pace_hold())
	wr.ground_pos = Vector2(27.0, 27.0)
	slowed.ground_pos = Vector2(-27.0, -27.0)
	_step(v, 3.5)
	var still := slowed.pace_hold() <= 0.5 + 0.001
	_step(v, 1.0)
	t.check(still and is_equal_approx(slowed.pace_hold(), 1.0), "and the hold lifts 4 s after the pass")
	v = _fresh(made)

	# --- on_kill_rise.
	var rem: Remains = crowd.remains
	rem.enabled = true
	var dead: Person = crowd.citizens[8]
	dead.ground_pos = at
	field.kill(dead, &"frenzy")
	var left := DeathParts.on_kill_rise(v, rem, dead, 3)
	t.check(left == 2 and v.living().size() == 1 and (v.living()[0] as Animal).breed == Animal.Breed.ZOMBIE and rem.all().is_empty(),
		"on_kill_rise raises a whole body (the chain: left 3 -> %d) and uses the remain up" % left)
	var stoned: Person = crowd.citizens[9]
	stoned.ground_pos = at + Vector2(5.0, 5.0)
	field.kill(stoned, &"stone")
	var left2 := DeathParts.on_kill_rise(v, rem, stoned, left)
	t.check(left2 == left and v.living().size() == 1, "and not a stone death: left unchanged, nothing raised")
	var dead2: Person = crowd.citizens[10]
	dead2.ground_pos = at + Vector2(-5.0, -5.0)
	field.kill(dead2, &"frenzy")
	var spent := DeathParts.on_kill_rise(v, rem, dead2, 0)
	t.check(spent == 0 and v.living().size() == 1, "with none left to raise, nothing rises")
	rem.enabled = false

	# --- Task 2: the wraith breed, touch kills, bounded ghosts, the grave kind.
	t.check(Animal.Breed.WRAITH == 16 and Animal.UNDEAD.has(Animal.Breed.WRAITH), "WRAITH is appended (16), undead")
	var pk := AnimalPack.new().setup(crowd, grid, made[4], 13)
	pk.spawn(80)
	var nowr := true
	for an in pk.animals:
		nowr = nowr and an.breed != Animal.Breed.WRAITH
	t.check(nowr, "WRAITH is never in the town pack")
	pk.clear()
	pk.free()
	v = _fresh(made)
	rem.enabled = true
	var lone: Person = crowd.soldiers[5]
	lone.ground_pos = at + Vector2(0.3, 0.0)
	var got := []
	var grab := func(e: DummyEnemy, kind: StringName) -> void: got.append([e, kind])
	field.enemy_killed.connect(grab)
	DeathParts.wraith(v, at)
	_step(v, 1.0)
	field.enemy_killed.disconnect(grab)
	t.check(got.size() == 1 and got[0][0] == lone and got[0][1] == &"pit"
		and rem.near(lone.ground_pos, 0.5).is_empty() and v.living().is_empty(),
		"a wraith kills the soldier it reaches as pit, leaves no body, and is spent (%s)" % [got])
	v = _fresh(made)
	var nearc: Person = crowd.citizens[11]
	var fars: Person = crowd.soldiers[6]
	nearc.ground_pos = at + Vector2(1.0, 0.0)
	fars.ground_pos = at + Vector2(4.0, 0.0)
	DeathParts.wraith(v, at)
	_step(v, 3.0)
	t.check(nearc.is_alive() and not fars.is_alive(), "a wraith passes a nearer citizen for a soldier")
	v = _fresh(made)
	var pv: Person = crowd.citizens[12]
	pv.ground_pos = at + Vector2(0.3, 0.0)
	DeathParts.pale_ghost(v, at, at, 6.0)
	_step(v, 1.0)
	t.check(not pv.is_alive() and rem.pick(pv.ground_pos) != null, "a pale ghost's touch kills as pale and leaves a remain")
	v = _fresh(made)
	var outer: Person = crowd.citizens[13]
	var inner: Person = crowd.citizens[14]
	outer.ground_pos = at + Vector2(3.5, 0.0)
	inner.ground_pos = at + Vector2(1.0, 0.0)
	DeathParts.pale_ghost(v, at + Vector2(3.0, 0.0), at, 3.0)
	_step(v, 4.0)
	t.check(outer.is_alive() and not inner.is_alive(), "a pale ghost never picks anyone outside its bounds, even nearer")
	v = _fresh(made)
	var gp: Person = crowd.citizens[15]
	gp.ground_pos = at + Vector2(-8.0, 0.0)
	var alarm0 := crowd.alarm
	field.kill(gp, &"grave", gp.ground_pos)
	t.check(is_equal_approx(crowd.alarm, alarm0) and rem.pick(gp.ground_pos) != null
		and DeathVoices.QUIET_KINDS.has(&"grave") and Rules.POWER_KINDS["walker"] == [&"grave"],
		"the grave kind: a body, quiet, no alarm")
	v = _fresh(made)
	var calm: Person = crowd.citizens[16]
	calm.ground_pos = at + Vector2(0.3, 0.0)
	DeathParts.haunt(v, at)
	_step(v, 3.0)
	t.check(calm.is_alive() and calm.mind == Person.Mind.CALM, "haunt: a wraith that hunts nobody, bites nobody, frightens nobody")
	v = _fresh(made)
	rem.enabled = false

	# --- The town's pack never spawns the undead.
	var pack := AnimalPack.new().setup(crowd, grid, made[4], 11)
	pack.spawn(60)
	var clean := pack.animals.size() == 60
	for an in pack.animals:
		clean = clean and not (an.breed in Animal.UNDEAD)
	t.check(clean, "the town's pack never spawns ZOMBIE, SPIRIT, BONE_GIANT")
	pack.clear()
	pack.free()
	_done(made)
