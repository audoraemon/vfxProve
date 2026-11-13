extends RefCounted
## Mind Whisper's orders and wheel serve any follow-up (Death task 4, for Raise the Dead's possession): a live effect whose
## follow_up_wheel() is true is recast through the whisper's press, drag and release and its WALK / ATTACK / BURN wheel, on a person within
## follow_up_reach() of follow_up_from() (the spirit, not the caster); the release hands follow_up() exactly the extra the wheel builds
## for Mind Whisper's own cast. MindWhisperFx.order() runs that extra on anyone for any length. Mind Whisper itself is unchanged
## (test_whisper, test_whisper_wheel, test_dominion_twist_whisper, test_dominion_levels).


## A stand-in for a live effect that takes its follow-up through the wheel (no Death power exists yet).
class WheelStub extends FxTimeline:
	var open := true
	var wheel := true
	var take := true
	var from := Vector2.ZERO
	var reach := 4.0
	var got: Array = []

	func can_follow_up() -> bool:
		return open

	func follow_up_wheel() -> bool:
		return wheel

	func follow_up_reach() -> float:
		return reach

	func follow_up_from() -> Vector2:
		return from

	func follow_up(at_pos: Vector2, extra_data: Dictionary) -> bool:
		if not open or not take:
			return false
		got.append([at_pos, extra_data])
		return true


## A follow-up with a subject of its own (review R15: Walking Corpse's walker): the wheel opens round it, its third slice is ENTER.
class SubjectStub extends WheelStub:
	var subject: Animal

	func follow_up_subject() -> Node2D:
		return subject if is_instance_valid(subject) else null

	func follow_up_orders() -> Array:
		return ["walk", "attack", "enter"]


static func run(t) -> void:
	var made := _crowd()
	_wheel(t, made)
	_orders(t, made)
	_rules(t, made)
	_order_fx(t, made)
	_subject(t, made)
	await _subject_draws(t, made)
	await _closed_redraws(t, made)
	_done(made)


static func _crowd() -> Array:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.for_tier(ResponseProfile.Tier.ORGANIZED)
	crowd.spawn()
	return [crowd, env, world, field, grid, town]


static func _done(made: Array) -> void:
	(made[0] as Crowd).clear()
	(made[2] as Node).free()


## Walkable ground with nobody within 7 units (searched over the whole town: the sections before have moved people about).
static func _empty(made: Array) -> Vector2:
	var grid: WalkGrid = made[4]
	var field: EnemyField = made[3]
	for i in 1600:
		var at := grid.nearest_walkable(Vector2(-40.0 + float(i % 40) * 2.0, -40.0 + float(i / 40) * 2.0))
		if at != Vector2.INF and field.in_radius(at, 7.0).is_empty():
			return at
	return Vector2.INF


## A standing house that burns.
static func _house(env: EnvironmentField) -> Structure:
	for s in env.structures():
		if not s.destroyed and not s.walkable and FireManager.burns(s) and s.kind == Structure.Kind.HOUSE:
			return s
	return null


## Rules with a live WheelStub in slot 0 ("doom", a plain click power) past its busy lock, Mind Whisper in slot 1.
static func _setup(made: Array, given: WheelStub = null) -> Array:
	var rules := Rules.new().setup(PackedStringArray(["doom", "whisper"]), null, made[1], made[3], made[0], made[5])
	var stub := given if given != null else WheelStub.new()
	stub.duration = 30.0
	stub.busy = 1.0
	var casts: Array = []
	rules.caster = func(_s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		casts.append([g, e])
		return stub if casts.size() == 1 else null
	rules.cast(0, Vector2.ZERO)
	stub.t = 2.0
	var aim := Targeting.new().setup(rules, made[0])
	return [rules, stub, aim, casts]


static func _free(set: Array) -> void:
	(set[2] as Node).free()
	(set[0] as Node).free()
	(set[1] as Node).free()


## "a live effect with follow_up_wheel gets the whisper wheel on recast"
static func _wheel(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var set := _setup(made)
	var rules: Rules = set[0]
	var stub: WheelStub = set[1]
	var aim: Targeting = set[2]
	var refused: Array = []
	rules.cast_refused.connect(func(s: int, why: String) -> void: refused.append([s, why]))
	var base := _empty(made)
	t.check(base != Vector2.INF, "a spot with nobody within 7 units")
	var who: Person = crowd.citizens[40]
	var far: Person = crowd.citizens[42]
	who.ground_pos = base
	far.ground_pos = base + Vector2(-6.0, 0.0)
	stub.from = base + Vector2(1.0, 0.0)  # the spirit: who stands 1 from it, far 7
	aim.pick(0)
	t.check(rules.can_recast(0) and rules.cooldown_left(0) > 0.0, "the stub is live and takes a follow-up, the slot on its cooldown")
	t.check(aim._aim_kind() == "whisper", "a live effect with follow_up_wheel gets the whisper wheel on recast (%s)" % aim._aim_kind())
	t.near(aim._whisper_reach(), 4.0, 0.0001, "the reach is the effect's follow_up_reach(), not Mind Whisper's REACH")
	stub.reach = 2.5
	t.near(aim._whisper_reach(), 2.5, 0.0001, "and follows it")
	stub.reach = 4.0
	stub.wheel = false
	t.check(aim._aim_kind() == "click", "with follow_up_wheel false the follow-up is a plain click, as before")
	stub.wheel = true

	aim.press(base + Vector2(0.2, 0.0))
	t.check(aim.wheel_open() and aim.armed and aim.aiming and aim._whisper_target == who and refused.is_empty(),
		"a press on a person within reach of the spirit opens the wheel on them (%s)" % [refused])
	aim.release(base + Vector2(0.1, 0.0))
	t.check(aim.wheel_open() and not aim.armed and stub.got.is_empty(), "the middle keeps it open")
	aim.cancel()

	# A press on someone past the reach from the spirit, or on nobody, is refused "missed": never "cooldown", never "nobody".
	refused.clear()
	aim.press(far.ground_pos)
	t.check(not aim.wheel_open() and not aim.armed and refused == [[0, "missed"]],
		"a person beyond follow_up_reach() of follow_up_from() is refused \"missed\" (%s)" % [refused])
	refused.clear()
	aim.press(base + Vector2(0.0, 3.0))
	t.check(not aim.wheel_open() and not aim.armed and refused == [[0, "missed"]], "and so is a press on nobody (%s)" % [refused])
	refused.clear()
	who._shaken_left = Person.SHAKE_OFF
	aim.press(who.ground_pos)
	t.check(not aim.wheel_open() and refused == [[0, "missed"]], "and one on someone still shaking a whisper off (%s)" % [refused])
	who._shaken_left = 0.0

	# The effect ends with the wheel up: it goes with it, quietly, and the slot aims as its own kind again.
	refused.clear()
	aim.press(who.ground_pos)
	aim.release(who.ground_pos + Vector2(0.1, 0.0))
	t.check(aim.wheel_open(), "the wheel is up again")
	stub.open = false
	aim.hover(who.ground_pos + Vector2(0.5, 0.5))
	t.check(not aim.wheel_open() and aim.picking_order() == "" and refused.is_empty() and aim._aim_kind() == "click",
		"when the effect stops taking follow-ups the wheel closes without a refusal (%s)" % [refused])
	stub.open = true

	# Mind Whisper in slot 1 keeps its own reach and its own refusals.
	aim.pick(1)
	t.check(aim._aim_kind() == "whisper" and is_equal_approx(aim._whisper_reach(), MindWhisperFx.REACH), "Mind Whisper keeps its REACH")
	refused.clear()
	aim.press(base + Vector2(0.0, 3.0))
	t.check(refused == [[1, "nobody"]], "and its \"nobody\" (%s)" % [refused])
	_free(set)


## "release on a slice passes walk/attack/burn extra to follow_up"
static func _orders(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var set := _setup(made)
	var rules: Rules = set[0]
	var stub: WheelStub = set[1]
	var aim: Targeting = set[2]
	var casts: Array = set[3]
	var refused: Array = []
	var called: Array = []
	rules.cast_refused.connect(func(s: int, why: String) -> void: refused.append([s, why]))
	rules.recast_made.connect(func(s: int, _k: String, at: Vector2) -> void: called.append([s, at]))
	var base := _empty(made)
	t.check(base != Vector2.INF, "_orders: a spot with nobody within 7 units")
	var who: Person = crowd.citizens[40]
	var foe: Person = crowd.citizens[41]
	who.ground_pos = base
	foe.ground_pos = base + Vector2(3.0, 0.0)
	stub.from = base
	var left := rules.cooldown_left(0)
	aim.pick(0)

	# Past the edge: the walk, clamped to the effect's reach.
	var spot := base + Vector2(0.0, 7.0)
	aim.press(base)
	aim.release(spot)
	var want := {"to": MindWhisperFx.clamp_to(grid, who.ground_pos, spot, 4.0), "target": who}
	t.check(stub.got.size() == 1 and stub.got[0][0] == who.ground_pos and stub.got[0][1] == want,
		"a release past the edge hands follow_up the walk {to, target}, clamped to follow_up_reach() (%s)" % [stub.got])
	t.check(called == [[0, who.ground_pos]] and casts.size() == 1 and is_equal_approx(rules.cooldown_left(0), left),
		"through recast: recast_made, no new cast, the cooldown untouched")
	t.check(aim.slot == 0 and not aim.wheel_open() and aim.picking_order() == "", "the slot stays focused for the next, the wheel gone")

	# ATTACK.
	stub.got.clear()
	aim.press(base)
	aim.release(base + Targeting.wheel_dir("attack") * 0.8)
	t.check(aim.picking_order() == "attack" and stub.got.is_empty(), "the ATTACK slice picks the order")
	aim.press(foe.ground_pos)
	aim.release(foe.ground_pos)
	t.check(stub.got.size() == 1 and stub.got[0][1] == {"target": who, "order": "attack", "foe": foe},
		"a click on the foe hands follow_up {target, order attack, foe} (%s)" % [stub.got])

	# WALK by its slice, then a spot.
	stub.got.clear()
	aim.press(base)
	aim.release(base + Targeting.wheel_dir("walk") * 0.8)
	var to := base + Vector2(0.0, 3.0)
	refused.clear()
	aim.press(to)
	aim.release(to)
	t.check(refused.is_empty() and stub.got.size() == 1
		and stub.got[0][1] == {"to": MindWhisperFx.clamp_to(grid, who.ground_pos, to, 4.0), "target": who},
		"the WALK slice and a click hand follow_up the walk, not refused on the slot's cooldown (%s %s)" % [refused, stub.got])

	# BURN.
	var house := _house(env)
	t.check(house != null, "the town has a house that burns")
	who.ground_pos = grid.nearest_walkable(house.center() + Vector2(3.0, 0.0), 6)
	stub.from = who.ground_pos
	stub.got.clear()
	aim.press(who.ground_pos)
	aim.release(who.ground_pos + Targeting.wheel_dir("burn") * 0.8)
	t.check(aim.picking_order() == "burn", "the BURN slice picks the burn")
	aim.press(house.center())
	aim.release(house.center())
	t.check(stub.got.size() == 1 and stub.got[0][1] == {"target": who, "order": "burn", "building": house},
		"a click on the house hands follow_up {target, order burn, building} (%s)" % [stub.got])

	# A follow-up that will not take it is refused "missed".
	stub.take = false
	refused.clear()
	aim.press(who.ground_pos)
	aim.release(who.ground_pos + Vector2(0.0, 5.0))
	t.check(refused == [[0, "missed"]] and aim.slot == 0, "a follow_up that refuses the order is \"missed\" (%s)" % [refused])
	stub.take = true
	_free(set)


## Rules reads a wheel follow-up as it reads Mind Whisper's cast: someone who cannot hear, or an unfair foe or building, never reaches
## follow_up().
static func _rules(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var set := _setup(made)
	var rules: Rules = set[0]
	var stub: WheelStub = set[1]
	var base := _empty(made)
	t.check(base != Vector2.INF, "_rules: a spot with nobody within 7 units")
	var who: Person = crowd.citizens[43]
	var foe: Person = crowd.citizens[44]
	var far: Person = crowd.citizens[45]
	who.ground_pos = base
	foe.ground_pos = base + Vector2(2.0, 0.0)
	far.ground_pos = base + Vector2(8.0, 0.0)
	t.check(not rules.recast(0, base, {"target": who, "order": "attack", "foe": far}) and stub.got.is_empty(),
		"a wheel follow-up with a foe out of ATTACK_R is false, follow_up untouched")
	t.check(not rules.recast(0, base, {"target": who, "order": "burn"}) and stub.got.is_empty(), "and a burn with no building")
	who.inside = true
	t.check(not rules.recast(0, base, {"target": who, "to": base}) and stub.got.is_empty(), "and one on someone indoors")
	who.inside = false
	who._shaken_left = Person.SHAKE_OFF
	t.check(not rules.recast(0, base, {"target": who, "to": base}) and stub.got.is_empty(), "and one on someone shaken")
	who._shaken_left = 0.0
	t.check(rules.recast(0, base, {"target": who, "order": "attack", "foe": foe}) and stub.got.size() == 1, "a fair attack goes through")
	stub.wheel = false
	t.check(rules.recast(0, base, {"target": who, "order": "attack", "foe": far}) and stub.got.size() == 2,
		"a follow-up without the wheel is handed its extra as before, unread")
	_free(set)


## A follow-up with a subject (R15): the wheel opens round the subject, never round a picked person; its orders carry no "target".
static func _subject(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[4]
	var stub := SubjectStub.new()
	var set := _setup(made, stub)
	var rules: Rules = set[0]
	var aim: Targeting = set[2]
	var refused: Array = []
	rules.cast_refused.connect(func(s: int, why: String) -> void: refused.append([s, why]))
	var base := _empty(made)
	t.check(base != Vector2.INF, "_subject: a spot with nobody within 7 units")
	var dog := Animal.new()
	dog.ground_pos = base
	stub.subject = dog
	stub.from = base
	var other: Person = crowd.citizens[46]
	other.ground_pos = base + Vector2(2.0, 0.0)  # someone Mind Whisper's pick would take: the subject's wheel never does
	aim.pick(0)
	t.check(aim._aim_kind() == "whisper", "(a subject's follow-up aims as the wheel)")

	aim.press(base + Vector2(0.8, 0.4))
	t.check(aim.wheel_open() and aim.armed and aim._subject == dog and aim._whisper_target == null and refused.is_empty(),
		"a press within 1.2 of the subject opens the wheel on it (%s)" % [refused])
	aim.release(base + Vector2(0.1, 0.0))
	t.check(aim.wheel_open() and not aim.armed and stub.got.is_empty(), "(the middle keeps it open)")
	aim.cancel()

	refused.clear()
	aim.press(other.ground_pos)
	t.check(not aim.wheel_open() and not aim.armed and refused == [[0, "missed"]],
		"a press 2.0 from the subject is refused missed, even on a person (%s)" % [refused])

	# Past the edge: the walk, clamped to the effect's reach, with no "target".
	refused.clear()
	var spot := base + Vector2(0.0, 7.0)
	aim.press(base)
	aim.release(spot)
	var want := {"order": "walk", "to": MindWhisperFx.clamp_to(grid, base, spot, 4.0)}
	t.check(stub.got.size() == 1 and stub.got[0][0] == base and stub.got[0][1] == want and not (stub.got[0][1] as Dictionary).has("target"),
		"release past the edge walks the subject (%s %s)" % [stub.got, refused])

	# ATTACK, then a click on a citizen; a click on nobody is refused "foe" and the pick goes on.
	aim.press(base)
	aim.release(base + Targeting.wheel_dir("attack") * 0.8)
	t.check(aim.picking_order() == "attack", "the ATTACK slice picks the attack")
	refused.clear()
	aim.press(base + Vector2(0.0, -3.0))
	aim.release(base + Vector2(0.0, -3.0))
	t.check(refused == [[0, "foe"]] and aim.picking_order() == "attack", "ATTACK on nobody is refused foe, the pick goes on (%s)" % [refused])
	aim.press(other.ground_pos)
	aim.release(other.ground_pos)
	var last: Dictionary = stub.got.back()[1]
	t.check(stub.got.size() == 2 and String(last.get("order", "")) == "attack" and last.get("foe") == other and not last.has("target"),
		"ATTACK then a click on a citizen gives the foe (%s)" % [stub.got])

	# The third slice is the effect's own word: ENTER, with the click's spot.
	aim.press(base)
	aim.release(base + Targeting.wheel_dir("burn") * 0.8)
	t.check(aim.picking_order() == "enter", "the third slice is ENTER (%s)" % aim.picking_order())
	var click := base + Vector2(1.5, 2.5)
	aim.press(click)
	aim.release(click)
	t.check(stub.got.size() == 3 and stub.got.back()[1] == {"order": "enter", "to": click},
		"the third slice is ENTER and gives the click spot (%s)" % [stub.got])

	# The subject is taken away with the wheel up: it closes quietly, nothing is sent.
	aim.press(base)
	aim.release(base + Vector2(0.1, 0.0))
	t.check(aim.wheel_open(), "(the wheel is up again)")
	var before := refused.size()
	dog.free()
	aim.hover(base + Vector2(0.5, 0.5))
	t.check(not aim.wheel_open() and aim.picking_order() == "" and refused.size() == before and stub.got.size() == 3,
		"the subject freed: the wheel closes quietly (%s)" % [refused])
	aim.release(base + Vector2(0.5, 0.5))
	t.check(refused.size() == before and stub.got.size() == 3, "(and a release after it sends nothing)")
	_free(set)


## The subject's wheel and its pick step draw, in the tree, over frames: its words (ENTER third) and the order's line.
static func _subject_draws(t, made: Array) -> void:
	var stub := SubjectStub.new()
	var set := _setup(made, stub)
	var aim: Targeting = set[2]
	var base := _empty(made)
	var dog := Animal.new()
	dog.ground_pos = base
	stub.subject = dog
	stub.from = base
	aim.pick(0)
	t.root.add_child(aim)
	var draws := [0]
	aim.draw.connect(func() -> void: draws[0] += 1)
	aim.hover(base + Vector2(2.0, 0.0))
	await t.process_frame
	aim.press(base)
	aim.hover(base + Targeting.wheel_dir("burn") * 0.8)
	await t.process_frame
	aim.release(base + Targeting.wheel_dir("burn") * 0.8)
	aim.hover(base + Vector2(1.0, 2.0))
	await t.process_frame
	t.check(aim.picking_order() == "enter" and draws[0] >= 3, "the subject's wheel and its ENTER pick draw (%d draws)" % draws[0])
	aim.cancel()
	t.root.remove_child(aim)
	dog.free()
	_free(set)


static func _fx_ctx(made: Array) -> FxContext:
	var ctx := FxContext.new()
	ctx.env = made[1]
	ctx.field = made[3]
	ctx.rng = RandomNumberGenerator.new()
	ctx.ground = Node2D.new()
	ctx.overhead = Node2D.new()
	ctx.crowd = made[0]
	return ctx


## MindWhisperFx.order(ctx, who, extra, seconds): the wheel's extra run on anyone, for any length.
static func _order_fx(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[4]
	var ctx := _fx_ctx(made)
	var base := _empty(made)
	t.check(base != Vector2.INF, "_order_fx: a spot with nobody within 7 units")
	var who: Person = crowd.citizens[50]
	var foe: Person = crowd.citizens[51]
	var far: Person = crowd.citizens[52]
	who.ground_pos = base
	foe.ground_pos = base + Vector2(0.4, 0.0)
	far.ground_pos = base + Vector2(8.0, 0.0)
	var to := grid.nearest_walkable(base + Vector2(0.0, 3.0))
	t.check(MindWhisperFx.order(ctx, who, {"to": to, "target": who}, 5.0), "a walk order takes")
	t.check(who.mind == Person.Mind.WHISPERED and who.anchor == to and is_equal_approx(who.whispered_left(), 5.0),
		"and whispers them to the spot for its seconds (%.2f)" % who.whispered_left())
	who._wake()
	who._shaken_left = 0.0
	t.check(not MindWhisperFx.order(ctx, who, {"target": who, "order": "attack", "foe": far}, 5.0) and who.mind != Person.Mind.FIGHT,
		"an attack on a foe out of reach does not take")
	t.check(MindWhisperFx.order(ctx, who, {"target": who, "order": "attack", "foe": foe}, 5.0)
		and who.mind == Person.Mind.FIGHT and who.fight_target == foe, "an attack on a fair foe sets them on him")
	who._wake()
	who._shaken_left = 0.0
	var house := _house(env)
	who.ground_pos = grid.nearest_walkable(house.center() + Vector2(3.0, 0.0), 6)
	var stand := MindWhisperFx.stand_at(grid, house, who.ground_pos)
	t.check(MindWhisperFx.order(ctx, who, {"target": who, "order": "burn", "building": house}, 5.0)
		and who.mind == Person.Mind.WHISPERED and who.anchor == stand and is_equal_approx(who.whispered_left(), 5.0),
		"a burn walks them to the house's edge for its seconds")
	who._wake()
	who._shaken_left = 0.0
	ctx.crowd = null
	t.check(not MindWhisperFx.order(ctx, who, {"target": who, "order": "burn", "building": house}, 5.0), "and with no town fires it does not take")
	ctx.ground.free()
	ctx.overhead.free()


## The effect stops taking follow-ups with the wheel up and the cursor still: the hover that closes the wheel redraws, so the wheel
## is not left drawn where it was (a still cursor's hover otherwise returns before its redraw). The edge's colour does not change
## here (as when the slot is ready again by the time the possession ends), so the per-frame edge check asks for no redraw: the
## redraw counted is the hover's own.
static func _closed_redraws(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var set := _setup(made)
	var rules: Rules = set[0]
	var stub: WheelStub = set[1]
	var aim: Targeting = set[2]
	var base := _empty(made)
	var who: Person = crowd.citizens[44]
	who.ground_pos = base
	stub.from = base + Vector2(1.0, 0.0)
	aim.pick(0)
	aim.press(who.ground_pos)
	aim.release(who.ground_pos + Vector2(0.1, 0.0))
	t.check(aim.wheel_open(), "(the wheel is up)")
	var still := who.ground_pos + Vector2(0.5, 0.5)
	aim.hover(still)
	t.root.add_child(aim)
	await t.process_frame
	await t.process_frame
	var draws := [0]
	aim.draw.connect(func() -> void: draws[0] += 1)
	stub.open = false
	aim._edge_ready = rules.refusal(0) == "" or rules.can_recast(0)
	aim.hover(still)
	await t.process_frame
	await t.process_frame
	t.check(not aim.wheel_open() and draws[0] > 0, "the hover that closes the wheel with the cursor still redraws it away (%d draws)" % draws[0])
	t.root.remove_child(aim)
	_free(set)
