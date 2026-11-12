extends RefCounted
## Raise the Dead (Death, Tier I): a click on a body (a remain within Remains.PICK_R). ZOMBIE: the body gets up for 30 s
## wearing its own people sprite, hunts the nearest within 10, and whoever it kills gets up too, 3 raised in all; a soldier cuts
## one down in 3 blows; a plague body's zombie infects. SPIRIT (needs a soul): the soul rises for 20 s, frightens everyone
## within 3 and drifts after the nearest group; a press within 4 of it possesses that person for 5 s with Mind Whisper's
## own orders (walk, attack, burn), 3 hosts in all. A host who cannot hear is refused "missed" and spends nothing.

const DT := 0.05


## A person whose mind the god cannot reach (as test_soldier_minds' double).
class Strong:
	extends Person

	func resists_mind() -> bool:
		return true


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
	crowd.remains.enabled = true
	var ctx := FxContext.new()
	ctx.env = env
	ctx.field = field
	ctx.crowd = crowd
	ctx.world = world
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return [crowd, env, grid, field, world, ctx, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	var ctx: FxContext = made[5]
	ctx.overhead.free()
	ctx.ground.free()
	(made[4] as Node).free()


static func _run(fx: FxTimeline, seconds: float, people: Array = []) -> void:
	for i in roundi(seconds / DT):
		for p in people:
			if is_instance_valid(p):
				(p as Person).frame(DT)
		if not fx.finished:
			fx._process(DT)


## Everyone far off in a corner, out of every reach, calm.
static func _clear_town(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		if not person.is_alive():
			continue
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		person.mind = Person.Mind.CALM
		i += 1


## The nth citizen, set down at `at` and killed as `kind`: the remain it leaves.
static func _body(made: Array, n: int, at: Vector2, kind := &"mob") -> Remains.Remain:
	var p: Person = (made[0] as Crowd).citizens[n]
	p.ground_pos = at
	(made[3] as EnemyField).kill(p, kind)
	return (made[0] as Crowd).remains.pick(at)


## Walkable ground with nobody within 12 units (past a zombie's hunt).
static func _empty(made: Array, skip := Vector2.INF) -> Vector2:
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	for i in 1600:
		var at := grid.nearest_walkable(Vector2(-20.0 + float(i % 40) * 1.0, -20.0 + float(i / 40) * 1.0))
		if at == Vector2.INF or (skip != Vector2.INF and at.distance_to(skip) < 16.0):
			continue
		if field.in_radius(at, 12.0).is_empty() and grid.walkable(at + Vector2(3.0, 0.0)) and grid.walkable(at + Vector2(0.0, 3.0)):
			return at
	return Vector2.INF


## A standing house that burns, with walkable ground 2 units off its east face.
static func _house(env: EnvironmentField, grid: WalkGrid) -> Structure:
	for s in env.structures():
		if s.destroyed or s.walkable or not FireManager.burns(s) or s.kind != Structure.Kind.HOUSE:
			continue
		var side := Vector2(s.footprint.end.x + 2.0, s.center().y)
		# (and the spot at its edge Mind Whisper sends a burner to is near enough to strike the match from)
		if grid.walkable(side) and s.distance_to(MindWhisperFx.stand_at(grid, s, side)) <= MindWhisperFx.BURN_NEAR * 0.8:
			return s
	return null


static func _clear_all(made: Array) -> void:
	_clear_town(made[0])
	var rem: Remains = (made[0] as Crowd).remains
	for r in rem.all():
		rem.take(r)


static func run(t) -> void:
	var made := _setup()
	_book(t)
	_zombie(t, made)
	_refused(t, made)
	_chain(t, made)
	_plague(t, made)
	_soldier(t, made)
	_soul(t, made)
	_spirit(t, made)
	_possess_walk(t, made)
	_possess_attack(t, made)
	_possess_burn(t, made)
	_hosts(t, made)
	_refused_hosts(t, made)
	_recalled(t, made)
	_exit(t, made)
	_done(made)


## The row, its tables, its icon.
static func _book(t) -> void:
	var b := PowerBook.get_power("raise")
	t.check(not b.is_empty() and int(b.dp) == 1 and float(b.cooldown) == 25.0 and String(b.aim) == "click"
		and String(b.get("needs", "")) == "body" and PowerBook.authority_of("raise") == "death" and not PowerBook.is_quiet("raise")
		and b.path == "res://src/fx/death/raise_the_dead.gd",
		"Raise the Dead: Death's 1 DP, 25 s, a click on a body, loud (%s)" % [b])
	var modes: Array = b.get("modes", [])
	t.check(modes.size() == 2 and String(modes[0].key) == "zombie" and String(modes[0].name) == "ZOMBIE"
		and String(modes[1].key) == "spirit" and String(modes[1].name) == "SPIRIT" and String(modes[1].get("needs", "")) == "soul"
		and Rules.needs_of("raise", "zombie") == "body" and Rules.needs_of("raise", "spirit") == "soul",
		"Q/E: ZOMBIE needs a body, SPIRIT a soul")
	var area: Dictionary = Targeting.AREAS.get("raise", {})
	t.check(PowerBook.REACH.has("raise") and is_equal_approx(PowerBook.impact("raise"), RaiseTheDeadFx.T_RISE)
		and PowerBook.family("raise") == "death" and Rules.POWER_KINDS.get("raise", []) == [&"frenzy"]
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), Remains.PICK_R)
		and is_equal_approx(float(area.get("roam", 0.0)), RaiseTheDeadFx.SEEK) and Targeting.AREA_STATS.has("raise"),
		"its reach, impact (the dead stand), family, kills (frenzy) and area (the body's pick, the hunt's roam)")
	t.check(PowerBook.icon("raise") != null and PowerBook.hud_icon("raise") != null, "it has its icons")
	t.check(RaiseTheDeadFx.ZOMBIE_LIFE == 30.0 and RaiseTheDeadFx.CHAIN == 3 and RaiseTheDeadFx.SEEK == 10.0
		and RaiseTheDeadFx.SPIRIT_LIFE == 20.0 and RaiseTheDeadFx.FRIGHT_R == 3.0 and RaiseTheDeadFx.POSSESS_R == 4.0
		and RaiseTheDeadFx.POSSESS == 5.0 and RaiseTheDeadFx.HOSTS == 3, "the numbers of the brief")


static func _cast(made: Array, at: Vector2, mode: String) -> RaiseTheDeadFx:
	return FxTimeline.cast(RaiseTheDeadFx, made[5], at, {"mode": mode}) as RaiseTheDeadFx


## "zombie mode raises the clicked remain and uses it up"
static func _zombie(t, made: Array) -> void:
	_clear_all(made)
	var crowd: Crowd = made[0]
	var at := _empty(made)
	t.check(at != Vector2.INF, "a spot with nobody near")
	var corpse: Person = crowd.citizens[0]
	var r := _body(made, 0, at)
	var design := r.design
	var fx := _cast(made, at + Vector2(0.4, 0.0), "zombie")
	t.check(crowd.remains.pick(at) == null, "zombie mode raises the clicked remain and uses it up")
	t.check(is_instance_valid(corpse) and not corpse.visible, "the corpse node is hidden when it rises: no body left lying behind")
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	var up := fx.visitors.living()
	t.check(up.size() == 1 and up[0].breed == Animal.Breed.ZOMBIE and up[0].worn == design
		and up[0].ground_pos.distance_to(at) < 0.05 and fx.raised == 1,
		"at T_RISE it stands where it lay, wearing its own design (%d up)" % up.size())
	fx.end_now()


## "no remain: refused no_dead, cooldown untouched" (carried from Task 2: the first row with "needs")
static func _refused(t, made: Array) -> void:
	_clear_all(made)
	var rules := Rules.new().setup(PackedStringArray(["raise"]), null, made[1], made[3], made[0], made[6])
	var casts := []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append(fx)
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var at := _empty(made)
	var got := rules.cast(0, at, {"mode": "zombie"})
	t.check(got == null and refused == [[0, "no_dead"]] and rules.cooldown_left(0) == 0.0 and casts.is_empty(),
		"no remain: refused no_dead, cooldown untouched (%s, %.1f)" % [refused, rules.cooldown_left(0)])
	refused.clear()
	got = rules.cast(0, at, {"mode": "spirit"})
	t.check(got == null and refused == [[0, "no_dead"]] and rules.cooldown_left(0) == 0.0, "and the same for the spirit (%s)" % [refused])
	refused.clear()
	_body(made, 1, at)
	got = rules.cast(0, at + Vector2(0.3, 0.3), {"mode": "zombie"})
	t.check(got != null and refused.is_empty() and is_equal_approx(rules.cooldown_left(0), 25.0),
		"a body there: it casts and the 25 s cooldown starts")
	if got != null:
		got.end_now()
	rules.free()


## "zombie kills chain to 3 raised in all, not 4"
static func _chain(t, made: Array) -> void:
	_clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := _empty(made)
	_body(made, 2, at)
	var fx := _cast(made, at, "zombie")
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	var z: Animal = fx.visitors.living()[0]
	# A real bite first: a citizen beside it is knocked down, then killed, and gets up.
	var first: Person = crowd.citizens[3]
	first.ground_pos = at + Vector2(0.3, 0.0)
	_run(fx, 2.0)  # it looks again within RETARGET, bites, and bites again BITE_EVERY on
	t.check(not first.is_alive() and fx.raised == 2 and fx.visitors.living().size() == 2,
		"a zombie's kill gets up as another zombie (%s, %d raised)" % [first.is_alive(), fx.raised])
	# Then three more of its kills: one more rises, then no more.
	var spots := [at + Vector2(2.0, 0.0), at + Vector2(0.0, 2.0), at + Vector2(-2.0, 0.0)]
	for k in 3:
		var v: Person = crowd.citizens[4 + k]
		v.ground_pos = spots[k]
		field.kill(v, &"frenzy")
		fx.visitors.bitten.emit(z, v, false)
	t.check(fx.raised == 3 and fx.visitors.living().size() == 3, "zombie kills chain to 3 raised in all, not 4 (%d)" % fx.raised)
	t.check(crowd.remains.pick(spots[2]) != null, "the fourth body stays where it fell")
	fx.end_now()


## "a zombie from a plague body infects with its bite"
static func _plague(t, made: Array) -> void:
	_clear_all(made)
	var crowd: Crowd = made[0]
	var at := _empty(made)
	_body(made, 8, at, &"plague")
	var fx := _cast(made, at, "zombie")
	var prey: Person = crowd.citizens[9]
	prey.ground_pos = at + Vector2(0.3, 0.0)
	_run(fx, RaiseTheDeadFx.T_RISE + 0.2)
	t.check(prey.is_alive() and prey.is_down() and prey.sick_left > 0.0,
		"a zombie from a plague body infects with its bite (down %s, sick %.1f)" % [prey.is_down(), prey.sick_left])
	fx.end_now()
	_clear_all(made)
	var at2 := _empty(made)
	_body(made, 10, at2, &"mob")
	var fx2 := _cast(made, at2, "zombie")
	var other: Person = crowd.citizens[11]
	other.ground_pos = at2 + Vector2(0.3, 0.0)
	_run(fx2, RaiseTheDeadFx.T_RISE + 0.2)
	t.check(other.is_down() and other.sick_left <= 0.0, "a body that died of no plague bites clean")
	fx2.end_now()


## A soldier cuts one down in 3 blows.
static func _soldier(t, made: Array) -> void:
	_clear_all(made)
	var crowd: Crowd = made[0]
	var at := _empty(made)
	_body(made, 12, at)
	var fx := _cast(made, at, "zombie")
	_run(fx, RaiseTheDeadFx.T_RISE + 0.05)
	var s: Person = crowd.soldiers[0]
	s.ground_pos = at + Vector2(0.3, 0.0)
	_run(fx, Visitors.GUARD_SWING * 2.0 + 0.1)
	t.check(fx.visitors.living().size() == 1, "two blows do not put it down")
	_run(fx, Visitors.GUARD_SWING)
	t.check(fx.visitors.living().is_empty() and fx.visitors.slain == 1 and s.is_alive(),
		"a soldier cuts one down in 3 blows (%d slain)" % fx.visitors.slain)
	fx.end_now()


## "spirit mode needs a soul: a 16 s old remain is refused soul_gone"
static func _soul(t, made: Array) -> void:
	_clear_all(made)
	var crowd: Crowd = made[0]
	var rules := Rules.new().setup(PackedStringArray(["raise"]), null, made[1], made[3], made[0], made[6])
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline: return FxTimeline.cast(s, made[5], g, e)
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var at := _empty(made)
	_body(made, 13, at)
	crowd.remains.step(16.0)
	var got := rules.cast(0, at, {"mode": "spirit"})
	t.check(got == null and refused == [[0, "soul_gone"]] and rules.cooldown_left(0) == 0.0,
		"spirit mode needs a soul: a 16 s old remain is refused soul_gone (%s)" % [refused])
	refused.clear()
	got = rules.cast(0, at, {"mode": "zombie"})
	t.check(got != null and refused.is_empty(), "the body itself still rises as a zombie")
	if got != null:
		got.end_now()
	rules.free()


## "citizens within 3 of the spirit flee", and it drifts after the nearest group.
static func _spirit(t, made: Array) -> void:
	_clear_all(made)
	var crowd: Crowd = made[0]
	var at := _empty(made)
	_body(made, 14, at)
	var fx := _cast(made, at, "spirit")
	t.check(crowd.remains.pick(at) == null, "the spirit's body is used up")
	var near: Person = crowd.citizens[15]
	var far: Person = crowd.citizens[16]
	near.ground_pos = at + Vector2(2.0, 0.0)
	far.ground_pos = at + Vector2(0.0, 6.0)
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	var sp := fx.spirit
	t.check(sp != null and sp.breed == Animal.Breed.SPIRIT and fx.visitors.living().size() == 1, "the soul rises as a spirit")
	_run(fx, 1.2)
	t.check(near.mind == Person.Mind.PANIC or near.mind == Person.Mind.FLEE,
		"citizens within 3 of the spirit flee (%s)" % Person.Mind.keys()[near.mind])
	t.check(far.mind == Person.Mind.CALM, "one at 6 does not (%s)" % Person.Mind.keys()[far.mind])
	# A group of three beside each other 6 off, the one frightened sent far away: it drifts to them.
	_clear_town(crowd)
	var group := at + Vector2(6.0, 0.0)
	for k in 3:
		(crowd.citizens[17 + k] as Person).ground_pos = group + Vector2(0.0, float(k) * 0.4)
	var before := sp.ground_pos.distance_to(group)
	_run(fx, 2.0)
	t.check(sp.ground_pos.distance_to(group) < before - 1.0, "it drifts after the nearest group (%.1f -> %.1f)" % [before, sp.ground_pos.distance_to(group)])
	fx.end_now()


## A spirit up, with the town cleared and the spirit at `at` (pinned there by a test).
static func _spirit_at(made: Array, n: int) -> Array:
	_clear_all(made)
	var at := _empty(made)
	_body(made, n, at)
	var fx := _cast(made, at, "spirit")
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	return [fx, at]


## "possession: walk order moves the host for 5 s then frees them"
static func _possess_walk(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var got := _spirit_at(made, 20)
	var fx: RaiseTheDeadFx = got[0]
	var at: Vector2 = got[1]
	var host: Person = crowd.citizens[21]
	host.ground_pos = at + Vector2(3.5, 0.0)  # beyond its fright (3), within its reach (4)
	fx.drift = false
	t.check(fx.can_follow_up() and fx.follow_up_wheel() and is_equal_approx(fx.follow_up_reach(), RaiseTheDeadFx.POSSESS_R)
		and fx.follow_up_from() == fx.spirit.ground_pos, "a live spirit takes a follow-up through the whisper's wheel, reach 4 from itself")
	var to := grid.nearest_walkable(host.ground_pos + Vector2(0.0, 3.0))
	t.check(fx.follow_up(host.ground_pos, {"target": host, "to": to}), "a press on someone within 4 possesses them")
	t.check(host.mind == Person.Mind.WHISPERED and host.anchor == to and not fx.spirit.visible and fx.hosts_left == 2
		and fx.host == host and not fx.can_follow_up(),
		"they walk where they were sent; the spirit is inside them, one host spent, none other meanwhile")
	var from := host.ground_pos
	_run(fx, 2.5, [host])
	t.check(host.mind == Person.Mind.WHISPERED and host.ground_pos.distance_to(from) > 0.5, "they walk (%.2f)" % host.ground_pos.distance_to(from))
	_run(fx, RaiseTheDeadFx.POSSESS - 2.5 + 0.2, [host])
	t.check(host.mind != Person.Mind.WHISPERED and not host.shaken() and fx.host == null and fx.spirit.visible
		and fx.can_follow_up(),
		"possession: walk order moves the host for 5 s then frees them (%s); the spirit comes out" % Person.Mind.keys()[host.mind])
	t.check(fx.spirit.ground_pos.distance_to(host.ground_pos) < 0.6, "it comes out of them where they stand")
	fx.end_now()


## "possession: attack order sets the host on the foe"
static func _possess_attack(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var got := _spirit_at(made, 22)
	var fx: RaiseTheDeadFx = got[0]
	var at: Vector2 = got[1]
	fx.drift = false
	var host: Person = crowd.citizens[23]
	var foe: Person = crowd.citizens[24]
	host.ground_pos = at + Vector2(3.5, 0.0)
	foe.ground_pos = host.ground_pos + Vector2(0.0, 0.4)
	t.check(fx.follow_up(host.ground_pos, {"target": host, "order": "attack", "foe": foe}), "an attack order takes")
	t.check(host.mind == Person.Mind.FIGHT and host.fight_target == foe and fx.host == host,
		"possession: attack order sets the host on the foe")
	_run(fx, RaiseTheDeadFx.POSSESS + 0.3)
	t.check(host.mind != Person.Mind.FIGHT and fx.host == null and fx.spirit.visible, "after 5 s they come to and the spirit comes out")
	fx.end_now()


## A burn order: the host walks to the building's edge and lights it BURN_SECS after getting there.
static func _possess_burn(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	_clear_all(made)
	var house := _house(env, grid)
	t.check(house != null, "a house that burns")
	if house == null:
		return
	var side := Vector2(house.footprint.end.x + 2.0, house.center().y)
	_body(made, 25, side + Vector2(1.0, 0.0))
	var fx := _cast(made, side + Vector2(1.0, 0.0), "spirit")
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	fx.drift = false
	var host: Person = crowd.citizens[26]
	host.ground_pos = MindWhisperFx.stand_at(grid, house, side)  # (the walk itself is the walk order's test)
	t.check(fx.follow_up(host.ground_pos, {"target": host, "order": "burn", "building": house}), "a burn order takes")
	var lit_at := -1.0
	var start := fx.t
	for i in roundi(8.0 / DT):
		host.frame(DT)
		fx._process(DT)
		if crowd.fires.is_burning(house):
			lit_at = fx.t - start
			break
	t.check(lit_at >= MindWhisperFx.BURN_SECS - 0.01 and lit_at < MindWhisperFx.BURN_SECS + 0.5,
		"the possessed host lights the building BURN_SECS after getting to its edge (%.2f s)" % lit_at)
	_run(fx, 0.2, [host])
	t.check(fx.host == null and fx.spirit.visible, "and the spirit comes out of them")
	crowd.fires.douse(house)
	fx.end_now()


## "3 hosts then can_follow_up is false"
static func _hosts(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var got := _spirit_at(made, 27)
	var fx: RaiseTheDeadFx = got[0]
	var at: Vector2 = got[1]
	fx.drift = false
	for k in 3:
		var host: Person = crowd.citizens[28 + k]
		t.check(fx.can_follow_up(), "before host %d it takes a follow-up" % (k + 1))
		host.ground_pos = fx.spirit.ground_pos + Vector2(3.5, 0.0)
		(crowd.citizens[31 + k] as Person).ground_pos = host.ground_pos + Vector2(0.0, 0.4)
		t.check(fx.follow_up(host.ground_pos, {"target": host, "order": "attack", "foe": crowd.citizens[31 + k]}),
			"host %d is possessed" % (k + 1))
		_run(fx, RaiseTheDeadFx.POSSESS + 0.2)
		host.stop_fighting()
		host.ground_pos = at + Vector2(-20.0, -20.0)
	t.check(fx.hosts_left == 0 and not fx.can_follow_up() and fx.spirit.visible and not fx.finished,
		"3 hosts then can_follow_up is false (%d left); the spirit drifts on" % fx.hosts_left)
	fx.end_now()


## "a resisting or indoor host is refused (missed) and the spirit keeps its hosts" (review focus 1), through Rules.recast too.
static func _refused_hosts(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var grid: WalkGrid = made[2]
	_clear_all(made)
	var rules := Rules.new().setup(PackedStringArray(["raise"]), null, made[1], made[3], made[0], made[6])
	var live := []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var f := FxTimeline.cast(s, made[5], g, e)
		live.append(f)
		return f
	var at := _empty(made)
	_body(made, 35, at)
	var fx := rules.cast(0, at, {"mode": "spirit"}) as RaiseTheDeadFx
	t.check(fx != null, "the spirit is cast through Rules")
	if fx == null:
		rules.free()
		return
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	fx.drift = false
	var cd := rules.cooldown_left(0)
	t.check(rules.can_recast(0), "a live spirit: the slot takes a follow-up")
	var spot := fx.spirit.ground_pos + Vector2(3.5, 0.0)
	var to := grid.nearest_walkable(spot + Vector2(0.0, 2.0))

	# Indoors.
	var indoor: Person = crowd.citizens[36]
	indoor.ground_pos = spot
	indoor.inside = true
	t.check(not fx.follow_up(spot, {"target": indoor, "to": to}) and fx.hosts_left == RaiseTheDeadFx.HOSTS and fx.host == null,
		"an indoor host is refused and the spirit keeps its hosts")
	# A bystander under the press: whisper_refusal falls back to them and passes, but the press named the one indoors.
	var bystander: Person = crowd.citizens[37]
	bystander.ground_pos = spot + Vector2(0.1, 0.0)
	t.check(rules.whisper_refusal(spot, {"target": indoor, "to": to}) == "", "(set-up) the bystander lets whisper_refusal pass")
	t.check(not rules.recast(0, spot, {"target": indoor, "to": to}) and fx.hosts_left == RaiseTheDeadFx.HOSTS
		and bystander.mind != Person.Mind.WHISPERED and fx.host == null,
		"a bystander under the press: the indoor host is still refused (missed), nobody possessed")
	indoor.inside = false
	indoor.ground_pos = at + Vector2(-20.0, -20.0)

	# A mind that resists.
	var strong := Strong.new()
	strong.setup_person(true, spot, grid)
	field.add(strong)
	(made[4] as Node).add_child(strong)
	t.check(not rules.recast(0, spot, {"target": strong, "to": to}) and fx.hosts_left == RaiseTheDeadFx.HOSTS
		and bystander.mind != Person.Mind.WHISPERED and strong.mind != Person.Mind.WHISPERED,
		"a resisting host is refused (missed) and the spirit keeps its hosts")
	strong.ground_pos = at + Vector2(-22.0, -20.0)

	# Shaken.
	bystander._shaken_left = Person.SHAKE_OFF
	t.check(not fx.follow_up(bystander.ground_pos, {"target": bystander, "to": to}) and fx.hosts_left == RaiseTheDeadFx.HOSTS,
		"a shaken host is refused too")
	bystander._shaken_left = 0.0

	# Out of reach of the spirit: the spirit drifted since the press was aimed.
	bystander.ground_pos = fx.spirit.ground_pos + Vector2(4.6, 0.0)
	t.check(not fx.follow_up(bystander.ground_pos, {"target": bystander, "to": to}) and fx.hosts_left == RaiseTheDeadFx.HOSTS,
		"one more than 4 from the spirit is refused, measured at the follow-up")
	t.check(not fx.finished and fx.spirit.visible and is_equal_approx(rules.cooldown_left(0), cd),
		"the refusals spend nothing: the spirit lives on, the cooldown is as it was")
	# And a fair one still takes.
	bystander.ground_pos = spot
	t.check(rules.recast(0, spot, {"target": bystander, "to": to}) and fx.hosts_left == RaiseTheDeadFx.HOSTS - 1,
		"a fair host still takes after the refusals")
	fx.end_now()
	rules.free()


## "everything recalled by 30 s / 20 s"
static func _recalled(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	_clear_all(made)
	var at := _empty(made)
	_body(made, 40, at)
	var fx := _cast(made, at, "zombie")
	_run(fx, RaiseTheDeadFx.ZOMBIE_LIFE - 0.5)
	t.check(fx.visitors.living().size() == 1, "the zombie stands until its 30 s")
	_run(fx, 1.5)
	t.check(fx.visitors.living().is_empty() and fx.finished, "everything recalled by 30 s (zombie)")
	_clear_all(made)
	var at2 := _empty(made)
	_body(made, 41, at2)
	var sp := _cast(made, at2, "spirit")
	_run(sp, RaiseTheDeadFx.T_RISE + 0.1)
	sp.drift = false
	var host: Person = crowd.citizens[42]
	host.ground_pos = sp.spirit.ground_pos + Vector2(3.5, 0.0)
	_run(sp, RaiseTheDeadFx.SPIRIT_LIFE - RaiseTheDeadFx.T_RISE - 0.1 - 3.0)
	t.check(sp.follow_up(host.ground_pos, {"target": host, "to": host.ground_pos + Vector2(0.0, 1.0)}), "a host taken 3 s before the end")
	_run(sp, 4.0, [host])
	t.check(sp.visitors.living().is_empty() and sp.finished and host.mind != Person.Mind.WHISPERED,
		"everything recalled by 20 s (spirit), and its host let go (%s)" % Person.Mind.keys()[host.mind])


## Freed without _finish (Battlefield.clear_effects() on a restart queue_frees it): the risen are gone, a live possession is
## ended (the host let go of the order, the eyes gone), nothing errors, and its end after that changes nothing.
static func _exit(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	_clear_all(made)
	var at := _empty(made)
	_body(made, 50, at)
	var fx := _cast(made, at, "zombie")
	_run(fx, T_RISE_PLUS)
	var pack := fx.visitors
	var up := pack.living()
	t.check(up.size() == 1, "(a zombie up)")
	fx._exit_tree()
	t.check(_all_gone(up) and pack.living().is_empty() and not crowd.visitors.has(pack),
		"freed without its end, the zombies are gone and the pack leaves the town")
	fx.end_now()
	t.check(fx.finished, "and its end after that changes nothing")
	# A spirit riding a host.
	var got := _spirit_at(made, 51)
	var sp: RaiseTheDeadFx = got[0]
	var at2: Vector2 = got[1]
	sp.drift = false
	var host: Person = crowd.citizens[52]
	host.ground_pos = at2 + Vector2(3.5, 0.0)
	var to := (made[2] as WalkGrid).nearest_walkable(host.ground_pos + Vector2(0.0, 3.0))
	t.check(sp.follow_up(host.ground_pos, {"target": host, "to": to}) and sp.host == host, "(possessed)")
	var spirits := sp.visitors.living()
	var eyes := sp._eyes
	sp._exit_tree()
	t.check(sp.host == null and host.mind != Person.Mind.WHISPERED and (eyes == null or not is_instance_valid(eyes) or eyes.is_queued_for_deletion()),
		"freed mid-possession, the host is let go of the order (%s) and the eyes go" % Person.Mind.keys()[host.mind])
	t.check(_all_gone(spirits) and sp.visitors.living().is_empty(), "and the spirit is gone")
	sp.end_now()
	t.check(sp.finished and host.mind != Person.Mind.WHISPERED, "and its end after that changes nothing")
	# A host freed mid-possession (they left the town), then the effect torn down: no error.
	var got3 := _spirit_at(made, 53)
	var sp3: RaiseTheDeadFx = got3[0]
	sp3.drift = false
	var host3: Person = crowd.citizens[54]
	host3.ground_pos = (got3[1] as Vector2) + Vector2(3.5, 0.0)
	t.check(sp3.follow_up(host3.ground_pos, {"target": host3, "to": host3.ground_pos + Vector2(0.0, 1.0)}), "(possessed again)")
	crowd.citizens.erase(host3)
	(made[3] as EnemyField).remove(host3)
	host3.free()
	sp3._exit_tree()
	t.check(sp3.visitors.living().is_empty(), "a host freed before the teardown: the spirit still goes, without an error")
	sp3.end_now()
	t.check(sp3.finished, "and it ends cleanly")


const T_RISE_PLUS := RaiseTheDeadFx.T_RISE + 0.1


static func _all_gone(nodes: Array) -> bool:
	for a in nodes:
		if is_instance_valid(a) and not a.is_queued_for_deletion():
			return false
	return true
