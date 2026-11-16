extends RefCounted
## Death's undead kit (Death authority, spec 5.1 and 6): zombies wearing the dead person's own sprite, the pale spirit,
## the wraith and the bone giant breed, the pale ghost, skeleton warrior and ghoul, the withering, and the Visitors traits they
## go by (knock_first, infect, spare_guise, prey, fright_r, slow_pass, sector, wither, touches_most, prefer, spare). Every
## Death power that raises or calls the dead spawns through DeathParts.

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
		and Animal.UNDEAD == [Animal.Breed.ZOMBIE, Animal.Breed.SPIRIT, Animal.Breed.BONE_GIANT, Animal.Breed.WRAITH,
			Animal.Breed.PALE_GHOST, Animal.Breed.SKELETON, Animal.Breed.GHOUL]
		and not (Animal.Breed.ZOMBIE in Animal.DOGS) and not (Animal.Breed.SPIRIT in Animal.CATS)
		and Animal.sheet(Animal.Breed.BONE_GIANT).get("cell", 0) == 96
		and Animal.sheet(Animal.Breed.SPIRIT).is_empty() and Animal.sheet(Animal.Breed.ZOMBIE).is_empty(),
		"the breeds are appended (indices kept), the giant has its 96 px sheet, the zombie and spirit have none")

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

	# --- prey soldiers (the trait; the giant goes by it).
	var cit: Person = crowd.citizens[5]
	var sol: Person = crowd.soldiers[0]
	cit.ground_pos = at + Vector2(0.5, 0.0)
	sol.ground_pos = at + Vector2(4.0, 0.0)
	var ps := v.summon(at, Animal.Breed.WRAITH, DeathParts.SPIRIT_BLOWS, 1.0, 12.0, 0.5, 1.0, false)
	v.give(ps, {"phase": true, "prey": "soldiers", "no_bite": true})
	_step(v, 0.6)
	t.check(ps.target == sol and cit.is_alive(), "prey soldiers: a citizen nearer is ignored")
	v = _fresh(made)
	var w := DeathParts.wraith(v, at, Vector4.ZERO, at)
	t.check(w.breed == Animal.Breed.WRAITH, "a wraith is the wraith breed")
	# Final review 1: its painted sheet is what play draws. The draw path looks up sheet(breed) for every breed first; the
	# wraith's own sheet is cached apart, so that look never leaves it empty (the 2x spirit stand-in drawn instead).
	Animal.sheet(w.breed)
	var wsh := Animal._wraith_sheet()
	t.check(not wsh.is_empty() and wsh.get("tex") != null and (wsh.get("frames", []) as Array).size() == 3,
		"the wraith's painted sheet is there after the draw path's sheet() look (%s)" % [wsh.keys()])
	# And its strike row plays once and ends: the bite clock runs for a wraith too.
	w.bit()
	w.tick_visual(0.5)
	var striking := w._bite_t < 1.0
	w.tick_visual(0.6)
	t.check(striking and w._bite_t >= 1.0, "a wraith's strike pose plays and ends (bite clock %.2f)" % w._bite_t)
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

	# --- Wraith slows who it passes to 0.5 for 4 s (a guised one: it passes through, and never withers them).
	var slowed: Person = crowd.citizens[17]
	slowed.ground_pos = at + Vector2(0.3, 0.0)
	slowed.statuses[&"guise"] = 25.0
	var wr := DeathParts.wraith(v, at, Vector4.ZERO, at)
	wr.target = null
	var base := slowed.pace_hold()
	_step(v, 0.2)
	t.check(is_equal_approx(base, 1.0) and slowed.pace_hold() <= 0.5 + 0.001 and not slowed.withered(),
		"wraith slows who it passes to 0.5 (%.2f)" % slowed.pace_hold())
	wr.ground_pos = Vector2(27.0, 27.0)
	slowed.ground_pos = Vector2(-27.0, -27.0)
	_step(v, 3.5)
	var still := slowed.pace_hold() <= 0.5 + 0.001
	_step(v, 1.0)
	t.check(still and is_equal_approx(slowed.pace_hold(), 1.0), "and the hold lifts 4 s after the pass")
	slowed.statuses.erase(&"guise")
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
	var wl := DeathParts.wraith(v, at, Vector4.ZERO, at)
	_step(v, 1.0)
	field.enemy_killed.disconnect(grab)
	t.check(got.is_empty() and lone.is_alive() and lone.withered() and v.living().has(wl),
		"a wraith withers the soldier it reaches (no kill at its touch) and is not spent by one touch (%s)" % [got])
	crowd.withering.clear()
	v = _fresh(made)
	# The touch kill is a trait still (no Death power gives it to a wraith now): it kills as its kind and, spent_on_kill, is freed.
	var lone2: Person = crowd.soldiers[8]
	lone2.ground_pos = at + Vector2(0.3, 0.0)
	got.clear()
	field.enemy_killed.connect(grab)
	_touch_killer(v, at)
	_step(v, 1.0)
	field.enemy_killed.disconnect(grab)
	t.check(got.size() == 1 and got[0][0] == lone2 and got[0][1] == &"pit"
		and rem.near(lone2.ground_pos, 0.5).is_empty() and v.living().is_empty(),
		"touch_kill: it kills the soldier it reaches as pit, leaves no body, and is spent (%s)" % [got])
	v = _fresh(made)
	var gone_s: Person = crowd.soldiers[7]
	gone_s.ground_pos = at + Vector2(0.3, 0.0)
	var wlive := _touch_killer(v, at)
	wlive.target = gone_s
	field.kill(gone_s, &"frenzy", gone_s.ground_pos)
	_step(v, 1.0)
	t.check(wlive.is_alive() and v.living().has(wlive), "touch_kill: one whose target fell already is not spent")
	v = _fresh(made)
	# R37: a wraith goes for the nearest, citizen or soldier.
	var nearc: Person = crowd.citizens[11]
	var fars: Person = crowd.soldiers[6]
	nearc.ground_pos = at + Vector2(1.0, 0.0)
	fars.ground_pos = at + Vector2(4.0, 0.0)
	var order := []
	v.bitten.connect(func(_a: Animal, victim: Person, _first: bool) -> void: order.append(victim))
	DeathParts.wraith(v, at, Vector4.ZERO, at)
	_step(v, 3.0)
	t.check(not order.is_empty() and order[0] == nearc and nearc.withered(),
		"a wraith goes for the nearer citizen first, not the soldier (R37) (%d touched)" % order.size())
	crowd.withering.clear()
	v = _fresh(made)
	var pv: Person = crowd.citizens[12]
	pv.ground_pos = at + Vector2(0.3, 0.0)
	var pg := DeathParts.pale_ghost(v, at, at, 6.0)
	_step(v, 1.0)
	t.check(not pv.is_alive() and rem.pick(pv.ground_pos) != null and pg.breed == Animal.Breed.PALE_GHOST,
		"a pale ghost (its own breed) touches dead as pale and leaves a remain")
	v = _fresh(made)
	var outer: Person = crowd.citizens[13]
	var inner: Person = crowd.citizens[14]
	outer.ground_pos = at + Vector2(3.5, 0.0)
	inner.ground_pos = at + Vector2(1.0, 0.0)
	DeathParts.pale_ghost(v, at + Vector2(3.0, 0.0), at, 3.0)
	_step(v, 4.0)
	t.check(outer.is_alive() and not inner.is_alive(), "a pale ghost never picks anyone outside its bounds, even nearer")
	v = _fresh(made)
	# A mark (Hound Gate's Quarry) set on one outside the bounds does not draw a bounded ghost out after them.
	var marked_out: Person = crowd.citizens[19]
	var marked_in: Person = crowd.citizens[20]
	marked_out.ground_pos = at + Vector2(-4.0, 0.0)
	marked_in.ground_pos = at + Vector2(1.0, 0.0)
	DeathParts.pale_ghost(v, at + Vector2(2.0, 0.0), at, 3.0)
	v.mark(marked_out)
	_step(v, 6.0)
	t.check(marked_out.is_alive() and not marked_in.is_alive(),
		"a pale ghost ignores a mark outside its bounds and hunts the nearest inside")
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
	_second_review(t)


## A wraith with the touch kill (the trait, kept): prey soldiers, kills as pit, spent on its kill.
static func _touch_killer(v: Visitors, at: Vector2) -> Animal:
	var a := v.summon(at, Animal.Breed.WRAITH, DeathParts.SPIRIT_BLOWS, DeathParts.WRAITH_SPEED, DeathParts.WRAITH_SEEK,
		DeathParts.WRAITH_TOUCH, 1.0, false)
	v.give(a, {"phase": true, "prey": "soldiers", "touch_kill": &"pit", "spent_on_kill": true})
	return a


## Steps the crowd (its withering with it) for `seconds`.
static func _advance(crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / DT):
		crowd.advance(DT)


## Death's second review (R36-R42): the new breeds, the withering and the traits Gate Below, Pale Reign and Grave Tide go by.
## A town of its own: the crowd is stepped here (its withering with it), and the first town's plague (the infect check) would
## spread through it.
static func _second_review(t) -> void:
	var made := _setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var v := _fresh(made)
	var rem: Remains = crowd.remains
	var at := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())

	# --- The breeds.
	var pk := AnimalPack.new().setup(crowd, grid, made[4], 17)
	pk.spawn(80)
	var none := true
	for an in pk.animals:
		none = none and not (an.breed in [Animal.Breed.PALE_GHOST, Animal.Breed.SKELETON, Animal.Breed.GHOUL])
	pk.clear()
	pk.free()
	t.check(Animal.Breed.PALE_GHOST == 17 and Animal.Breed.SKELETON == 18 and Animal.Breed.GHOUL == 19
		and Animal.UNDEAD.has(Animal.Breed.PALE_GHOST) and Animal.UNDEAD.has(Animal.Breed.SKELETON)
		and Animal.UNDEAD.has(Animal.Breed.GHOUL)
		and Animal.SOLID_UNDEAD == [Animal.Breed.ZOMBIE, Animal.Breed.SKELETON, Animal.Breed.GHOUL] and none,
		"three breeds appended, undead, never in the town pack")

	# --- The withering: grey, slowed, panicked, dead at 6 s as wither, a body.
	rem.enabled = true
	var c: Person = crowd.citizens[21]
	c.ground_pos = at
	var got := []
	var grab := func(e: DummyEnemy, kind: StringName) -> void: got.append([e, kind])
	field.enemy_killed.connect(grab)
	var laid := crowd.wither(c, Withering.WITHER, c.ground_pos + Vector2(1, 0))
	t.check(laid and c.withered() and c.pace_hold() <= Withering.WITHER_PACE
		and c.walk_speed <= Withering.WITHER_PACE * c._base_speed() + 0.001
		and (c.mind in [Person.Mind.PANIC, Person.Mind.FLEE] or c.startled()),
		"withering: grey, held to WITHER_PACE of the pace his mind gives (%.2f of %.2f), panicked (mind %d)"
		% [c.walk_speed, c._base_speed(), c.mind])
	_advance(crowd, 5.9)
	var alive_at := c.is_alive()
	var alarm0 := crowd.alarm
	_advance(crowd, 0.2)
	var pos := c.ground_pos
	t.check(alive_at and not c.is_alive() and got.size() == 1 and got[0][1] == &"wither" and rem.pick(pos) != null
		and crowd.alarm > alarm0,
		"withering: alive at 5.9 s, dead at 6.1 s as wither, a body, the alarm raised (%s, alarm %.2f -> %.2f)"
		% [got, alarm0, crowd.alarm])
	t.check(not c.withered() and crowd.withering.count() == 0, "and it is done with him")

	# --- It lapses indoors, on another death, or freed (Review Focus 1).
	got.clear()
	var home: Person = crowd.citizens[22]
	var slain: Person = crowd.citizens[23]
	var carried: Person = crowd.citizens[24]
	home.ground_pos = at + Vector2(2.0, 0.0)
	slain.ground_pos = at + Vector2(-2.0, 0.0)
	carried.ground_pos = at + Vector2(0.0, 2.0)
	for q in [home, slain, carried]:
		crowd.wither(q, Withering.WITHER, at)
	_advance(crowd, 2.0)
	field.kill(slain, &"frenzy", slain.ground_pos)
	field.remove(carried)
	crowd.citizens.erase(carried)
	carried.free()
	_advance(crowd, 1.0)
	home.inside = true
	_advance(crowd, 3.1)
	t.check(home.is_alive() and not home.withered() and is_equal_approx(home.pace_hold(), 1.0)
		and got.size() == 1 and got[0][0] == slain and got[0][1] == &"frenzy" and not slain.withered()
		and crowd.withering.count() == 0,
		"withering lapses indoors, on another death, or freed (%s)" % [got])
	home.inside = false

	# --- A second withering on the withering runs nothing new.
	got.clear()
	var twice: Person = crowd.citizens[25]
	twice.ground_pos = at + Vector2(-3.0, 1.0)
	crowd.wither(twice, Withering.WITHER, at)
	_advance(crowd, 3.0)
	var again := crowd.wither(twice, Withering.WITHER, at)
	_advance(crowd, 2.9)
	var lives := twice.is_alive()
	_advance(crowd, 0.2)
	t.check(not again and lives and not twice.is_alive() and got.size() == 1 and got[0][1] == &"wither",
		"a second withering on the withering runs nothing new: he dies at the first's 6 s")
	field.enemy_killed.disconnect(grab)
	v = _fresh(made)

	# --- A wraith withers whoever it reaches, three, then sinks.
	var line: Array[Person] = []
	for k in 4:
		var q: Person = crowd.citizens[26 + k]
		q.ground_pos = at + Vector2(1.5 * float(k + 1), 0.0)
		line.append(q)
	DeathParts.wraith(v, at, Vector4.ZERO, at)
	_step(v, 15.0)
	var hit := 0
	for k in 3:
		var q := line[k]
		if q.withered() or (not q.is_alive() and q._kind == &"wither"):
			hit += 1
	t.check(hit == 3 and line[3].is_alive() and not line[3].withered() and v.living().is_empty(),
		"a wraith withers whoever it reaches, three, then sinks (%d withered, %d up)" % [hit, v.living().size()])
	crowd.withering.clear()
	v = _fresh(made)

	# --- No crowd to lay the withering: a wraith's touch lays nothing, and nothing is told as a touch (bitten).
	var bare := Visitors.new().setup(field, null, grid, made[4])
	var told := []
	bare.bitten.connect(func(_a: Animal, who: Person, _first: bool) -> void: told.append(who))
	var lone_c: Person = crowd.citizens[29]
	lone_c.ground_pos = at + Vector2(0.3, 0.0)
	DeathParts.wraith(bare, at, Vector4.ZERO, at)
	_step(bare, 2.0)
	t.check(told.is_empty() and not lone_c.withered(), "no withering laid, no touch told (%d told)" % told.size())
	bare.clear()
	_clear_town(crowd)

	# --- A sector keeps a wraith to its own.
	var out_one: Person = crowd.citizens[30]
	var in_one: Person = crowd.citizens[31]
	out_one.ground_pos = at + Vector2(0.0, -2.0)
	in_one.ground_pos = at + Vector2(3.0, 0.5)
	var from := at + Vector2(0.0, -1.0)
	var sw := DeathParts.wraith(v, from, Vector4(at.x, at.y, 0.0, PI / 2.0), from)
	_step(v, 1.0)
	t.check(sw.target == in_one and not out_one.withered(),
		"a sector keeps a wraith to its own: the nearer one outside it is passed over")
	crowd.withering.clear()
	v = _fresh(made)

	# --- prefer soldiers: a skeleton passes a nearer citizen.
	var pc: Person = crowd.citizens[32]
	var psol: Person = crowd.soldiers[9]
	pc.ground_pos = at + Vector2(1.0, 0.0)
	psol.ground_pos = at + Vector2(4.0, 0.0)
	var sk := DeathParts.skeleton(v, at)
	_step(v, 0.2)
	var took_soldier := sk.target == psol
	v = _fresh(made)
	pc.ground_pos = at + Vector2(1.0, 0.0)
	var sk2 := DeathParts.skeleton(v, at)
	_step(v, 0.2)
	t.check(took_soldier and sk2.target == pc,
		"prefer soldiers: a skeleton passes a nearer citizen for a soldier; with no soldier in seek, the citizen")
	v = _fresh(made)

	# --- spare: a spared building is never clawed.
	var kept: Structure = null
	var other: Structure = null
	var side := Vector2.INF
	for s in env.structures():
		if not Visitors._wreckable(s) or s.kind != Structure.Kind.HOUSE:
			continue
		var p := Vector2(s.footprint.end.x + 0.3, s.center().y)
		if not grid.walkable(p):
			continue
		var best := INF
		var near: Structure = null
		for o in env.near(p, 8.0):
			if o != s and Visitors._wreckable(o) and o.distance_to(p) < best:
				best = o.distance_to(p)
				near = o
		if near != null:
			kept = s
			other = near
			side = p
			break
	t.check(kept != null, "two houses for the spare check")
	if kept != null:
		var kept_hp := kept.hp
		var other_hp := other.hp
		var wk := v.summon(side, Animal.Breed.GHOUL, 4, 1.0, 8.0, 0.6, 1.0, true)
		v.give(wk, {"wreck": 3.0, "wreck_every": 1.0, "wreck_reach": 0.5,
			"spare": func(s: Structure) -> bool: return s == kept})
		_step(v, 10.0)
		t.check(kept.hp == kept_hp and other.hp < other_hp,
			"spare: a spared building is never clawed (%.0f -> %.0f), the other is (%.0f -> %.0f)"
			% [kept_hp, kept.hp, other_hp, other.hp])
		kept.hp = kept_hp
		other.hp = other_hp
		v = _fresh(made)
		# Asked live (the parked review item): a building spared after it was chosen -- the one beside a wrecker, or the one
		# an idle wrecker is walking to -- is dropped at once, with no fresh look between.
		var held := [false]
		var by := v.summon(side, Animal.Breed.GHOUL, 4, 1.0, 8.0, 0.6, 1.0, true)
		v.give(by, {"wreck": 3.0, "wreck_every": 1.0, "wreck_reach": 0.5,
			"spare": func(s: Structure) -> bool: return held[0] and s == kept})
		var on_kept := [0]
		v.wrecked.connect(func(_a: Animal, s: Structure) -> void:
			if s == kept:
				on_kept[0] += 1)
		var rb: Visitors.Rule = v._rules[by]
		for i in 40:
			v.step(DT)
			if on_kept[0] > 0:
				break
		var struck_once: bool = on_kept[0] == 1 and rb.beside == kept
		held[0] = true
		rb.look_in = 99.0  # no fresh look: only the live re-check can drop it
		var hp_then := kept.hp
		_step(v, 1.5)
		t.check(struck_once and kept.hp == hp_then and rb.beside != kept,
			"spare asked live: the building beside it, spared after it was chosen, takes no more blows (%d before, %.0f -> %.0f)"
			% [on_kept[0], hp_then, kept.hp])
		kept.hp = kept_hp
		other.hp = other_hp
		v = _fresh(made)
		var going_to := [null]
		var walker := v.summon(at, Animal.Breed.GHOUL, 4, 1.0, 8.0, 0.6, 1.0, true)
		v.give(walker, {"wreck": 3.0, "wreck_every": 1.0, "wreck_reach": 0.5,
			"spare": func(s: Structure) -> bool: return s == going_to[0]})
		var rw: Visitors.Rule = v._rules[walker]
		for i in 10:
			v.step(DT)
			if rw.house != null:
				break
		var then := rw.house
		going_to[0] = then  # spared now, with the wrecker on its way to it
		v.step(DT)
		t.check(then != null and rw.house != then,
			"spare asked live: an idle wrecker drops the house it was walking to once that house is spared")
	v = _fresh(made)

	# --- An idle wrecker with nothing to wreck looks for a building at most once every WRECK_LOOK, not every step.
	var bored := v.summon(at, Animal.Breed.GHOUL, 4, 1.0, 8.0, 0.6, 1.0, true)
	v.give(bored, {"wreck": 3.0, "wreck_every": 1.0, "wreck_reach": 0.5,
		"spare": func(_s: Structure) -> bool: return true})
	var looks0 := v.house_looks
	_step(v, 1.0)
	var most_looks := ceili(1.0 / Visitors.WRECK_LOOK) + 1
	t.check(v.house_looks - looks0 >= 1 and v.house_looks - looks0 <= most_looks and v._rules[bored].house == null,
		"an idle wrecker with nothing to wreck looks for a building at most once every WRECK_LOOK (%d looks in 1 s, most %d)"
			% [v.house_looks - looks0, most_looks])
	v = _fresh(made)

	# --- Skeleton and ghoul stats.
	var s1 := DeathParts.skeleton(v, at)
	var g1 := DeathParts.ghoul(v, at)
	var rs: Visitors.Rule = v._rules[s1]
	var rg: Visitors.Rule = v._rules[g1]
	s1.target = null
	g1.target = null
	t.check(s1.breed == Animal.Breed.SKELETON and is_equal_approx(s1.health, 4.0) and not rs.flinch
		and is_equal_approx(rs.bite, 1.0) and rs.prefer_soldiers and rs.spare_guise
		and g1.breed == Animal.Breed.GHOUL and is_equal_approx(g1.health, 2.0) and rg.knock_first and rg.flinch
		and rg.spare_guise and is_equal_approx(s1.speed(), 0.78) and is_equal_approx(g1.speed(), 1.2),
		"skeleton and ghoul stats (speeds %.3f / %.3f)" % [s1.speed(), g1.speed()])
	v = _fresh(made)

	# --- The wither kind.
	t.check(Remains.BODY_KINDS.has(&"wither") and not DeathVoices.QUIET_KINDS.has(&"wither")
		and Rules.POWER_KINDS["gatebelow"] == [&"pit", &"wither"],
		"the wither kind: a body, a cry, Gate Below's")
	rem.enabled = false
	_done(made)
