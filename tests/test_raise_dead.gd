extends RefCounted
## Raise the Dead (Death, Tier I): a click on a body (a remain within Remains.PICK_R). ZOMBIE: the body gets up for 30 s
## wearing its own people sprite, hunts the nearest within 10, and whoever it kills gets up too, 3 raised in all; a soldier cuts
## one down in 3 blows; a plague body's zombie infects. SPIRIT (needs a soul): the soul rises for 20 s, frightens everyone
## within 4 and drifts after the nearest group. It never possesses anyone: Raise has no follow-up (R3).

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
	_no_follow_up(t, made)
	_zombie_catches(t, made)
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
		and RaiseTheDeadFx.SPIRIT_LIFE == 20.0 and RaiseTheDeadFx.FRIGHT_R == 4.0, "the numbers of the brief")


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


## "citizens within 4 of the spirit flee", and it drifts after the nearest group.
static func _spirit(t, made: Array) -> void:
	_clear_all(made)
	var crowd: Crowd = made[0]
	var at := _empty(made)
	_body(made, 14, at)
	var fx := _cast(made, at, "spirit")
	t.check(crowd.remains.pick(at) == null, "the spirit's body is used up")
	var near: Person = crowd.citizens[15]
	var far: Person = crowd.citizens[16]
	near.ground_pos = at + Vector2(3.5, 0.0)
	far.ground_pos = at + Vector2(0.0, 6.0)
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	var sp := fx.spirit
	t.check(sp != null and sp.breed == Animal.Breed.SPIRIT and fx.visitors.living().size() == 1, "the soul rises as a spirit")
	_run(fx, 1.2)
	t.check(near.mind == Person.Mind.PANIC or near.mind == Person.Mind.FLEE,
		"citizens within 4 of the spirit flee (%s)" % Person.Mind.keys()[near.mind])
	t.check(far.mind == Person.Mind.CALM, "one at 6 stays calm (%s)" % Person.Mind.keys()[far.mind])
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


## "spirit mode never possesses: raise has no follow-up"
static func _no_follow_up(t, made: Array) -> void:
	_clear_all(made)
	var rules := Rules.new().setup(PackedStringArray(["raise"]), null, made[1], made[3], made[0], made[6])
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		return FxTimeline.cast(s, made[5], g, e)
	var at := _empty(made)
	_body(made, 20, at)
	var fx := rules.cast(0, at, {"mode": "spirit"}) as RaiseTheDeadFx
	t.check(fx != null, "(set-up) the spirit is cast through Rules")
	if fx != null:
		_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
		t.check(not fx.has_method("follow_up") and not fx.has_method("follow_up_wheel") and not fx.has_method("can_follow_up")
			and not rules.can_recast(0), "spirit mode never possesses: raise has no follow-up")
		fx.end_now()
	rules.free()


## "a zombie closes on a walking citizen": the walker leaves at a walk, 3.0 off; within 8 s it is bitten.
static func _zombie_catches(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	_clear_all(made)
	var at := _empty(made)
	_body(made, 30, at)
	var fx := _cast(made, at, "zombie")
	_run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	var walker: Person = crowd.citizens[31]
	walker.ground_pos = at + Vector2(3.0, 0.0)
	var away := grid.nearest_walkable(at + Vector2(9.0, 0.0))
	walker.walk_to(away)
	var bitten := false
	for i in roundi(8.0 / DT):
		walker.frame(DT)
		fx._process(DT)
		if walker.is_down() or not walker.is_alive():
			bitten = true
			break
	t.check(bitten, "a zombie closes on a walking citizen (down=%s, %.1f off)" % [walker.is_down(),
		walker.ground_pos.distance_to(fx.visitors.living()[0].ground_pos) if not fx.visitors.living().is_empty() else -1.0])
	fx.end_now()


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
	_run(sp, RaiseTheDeadFx.SPIRIT_LIFE - RaiseTheDeadFx.T_RISE - 0.1 + 1.0)
	t.check(sp.visitors.living().is_empty() and sp.finished, "everything recalled by 20 s (spirit)")


## Freed without _finish (Battlefield.clear_effects() on a restart queue_frees it): the risen are gone, nothing errors, and its end after that changes nothing.
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


const T_RISE_PLUS := RaiseTheDeadFx.T_RISE + 0.1


static func _all_gone(nodes: Array) -> bool:
	for a in nodes:
		if is_instance_valid(a) and not a.is_queued_for_deletion():
			return false
	return true
