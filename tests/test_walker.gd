extends RefCounted
## Walking Corpse (Death, Tier III, quiet; spec 5.4): click a body, then where it should go. The body gets up -- a ZOMBIE-breed
## Visitor in the dead person's own look, no grey, no eyes, so it passes for living -- and walks there by the streets at a
## person's walk pace. Nobody panics, no alarm, no soldier cuts it down. In the open it stands and waits for orders (review R7):
## through the follow-up wheel it walks on (within ORDER_REACH), goes into a building, or kills someone quietly (&"grave", a body,
## no alarm), KILLS_MOST times at most. A Death sigil hangs over it all its life. At WALK_LIFE it lies down where it stands: its
## remain moved there and its clock restarted. Walked into a shelter or to a house door it is hidden: off the
## street drawing and out of the other powers' reach (Raise the Dead cannot pick it), though Walking Corpse can walk it back
## out. A plague body walked into a shelter infects up to INFECT_MOST of those sheltering there, nearest first.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func _cast(ctx: FxContext, at: Vector2, to: Vector2) -> WalkingCorpseFx:
	return FxTimeline.cast(WalkingCorpseFx, ctx, at, {"to": to}) as WalkingCorpseFx


static func run(t) -> void:
	_book(t)
	var made := RD._setup()
	_refused(t, made)
	_others_place(t, made)
	_walks(t, made)
	_orders(t, made)
	_attack(t, made)
	_foe_indoors(t, made)
	_walk_life(t, made)
	_quiet(t, made)
	_shelter_plague(t, made)
	_hidden(t, made)
	_carried_off(t, made)
	_exit(t, made)
	RD._done(made)


## The row: Tier III's 3 Might, 30 s, two clicks (the body, then where it goes), a body at the first, quiet, Death's.
static func _book(t) -> void:
	var p := PowerBook.get_power("walker")
	t.check(not p.is_empty() and int(p.dp) == 3 and float(p.cooldown) == 30.0 and String(p.aim) == "two clicks"
		and String(p.get("needs", "")) == "body" and PowerBook.is_quiet("walker") and PowerBook.authority_of("walker") == "death"
		and not p.has("alarm") and String(p.path) == "res://src/fx/death/walking_corpse.gd",
		"Walking Corpse: Death, 3 DP, 30 s, two clicks on a body, quiet, no alarm (%s)" % [p])
	t.check(bool(p.get("reaches_hidden", false)), "it alone reaches a hidden body (to walk it back out)")
	t.check(not PowerBook.REACH.has("walker") and not PowerBook.IMPACT.has("walker"), "no reach, no impact: nothing for the town to see")
	t.check(WalkingCorpseFx.WALK_LIFE == 40.0 and WalkingCorpseFx.INFECT_MOST == 3, "40 s to walk, 3 infected at most")
	var area: Dictionary = Targeting.AREAS.get("walker", {})
	t.check(String(area.get("shape", "")) == "circle" and is_equal_approx(float(area.get("r", 0.0)), Remains.PICK_R),
		"its area is the body's pick (%s)" % [area])
	t.check(Sfx.CATALOG.has(&"q_walker") and PowerBook.icon("walker") != null and PowerBook.hud_icon("walker") != null
		and PowerBook.clip("walker") != null, "its own cue q_walker, its icons and its clip")
	t.check(Rules.POWER_KINDS.get("walker", null) == [&"grave"] and PowerBook.FAMILY.get("walker", "") == "death", "it kills only as the quiet grave kind; Death's family")
	t.check(WalkingCorpseFx.ORDER_REACH == 12.0 and WalkingCorpseFx.ATTACK_R == 6.0 and WalkingCorpseFx.ATTACK_SECS == 10.0
		and WalkingCorpseFx.KILL_R == 0.4 and WalkingCorpseFx.KILLS_MOST == 2 and WalkingCorpseFx.ATTACK_PACE == 1.6
		and WalkingCorpseFx.SIGIL_UP == 26.0, "its orders' numbers (R7): reach 12, attack 6 / 10 s / 0.4, 2 kills, 1.6 x pace, sigil 26 px up")


## Steps `fx` (and `people`) DT at a time until `done` is true or `most` seconds pass: the seconds it took.
static func _until(fx: FxTimeline, done: Callable, most: float, people: Array = []) -> float:
	var took := 0.0
	while not done.call() and took < most:
		RD._run(fx, DT, people)
		took += DT
	return took


## A body at `at`, sent to its own spot: it gets up and stands there, waiting for orders.
static func _standing(made: Array, n: int, at: Vector2) -> WalkingCorpseFx:
	RD._body(made, n, at)
	var fx := _cast(made[5], at, at)
	RD._run(fx, WalkingCorpseFx.T_RISE + 0.3)
	return fx


## Walkable ground `d` units from `at` along the first of eight ways, the line there open or not.
static func _far(made: Array, at: Vector2, d: float) -> Vector2:
	var grid: WalkGrid = made[2]
	for k in 8:
		var to := at + Vector2.RIGHT.rotated(TAU * float(k) / 8.0) * d
		if grid.walkable(to):
			return to
	return Vector2.INF


## Walkable ground `d` units from `at` along the first of eight ways that is open all along, nobody within 4 of it.
static func _spot(made: Array, at: Vector2, d: float) -> Vector2:
	var grid: WalkGrid = made[2]
	for k in 8:
		var dir := Vector2.RIGHT.rotated(TAU * float(k) / 8.0)
		var to := at + dir * d
		if grid.walkable(to) and grid.clear_line(at, to):
			return to
	return Vector2.INF


## "no remain: refused no_dead", the cooldown untouched; a body there casts and the 30 s cooldown starts.
static func _refused(t, made: Array) -> void:
	RD._clear_all(made)
	var rules := Rules.new().setup(PackedStringArray(["walker"]), null, made[1], made[3], made[0], made[6])
	var casts := []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append(fx)
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var at := RD._empty(made)
	var got := rules.cast(0, at, {"to": at + Vector2(3.0, 0.0)})
	t.check(got == null and refused == [[0, "no_dead"]] and rules.cooldown_left(0) == 0.0 and casts.is_empty(),
		"no remain: refused no_dead (%s, cooldown %.1f)" % [refused, rules.cooldown_left(0)])
	refused.clear()
	RD._body(made, 1, at)
	got = rules.cast(0, at + Vector2(0.3, 0.3), {"to": at + Vector2(3.0, 0.0)})
	t.check(got != null and refused.is_empty() and is_equal_approx(rules.cooldown_left(0), 30.0),
		"a body there: it casts and the 30 s cooldown starts")
	if got != null:
		got.end_now()
	# Aimed: the first click finds no body and is refused there and then; on a body it is placed, and the second click casts.
	RD._clear_all(made)
	var aim := Targeting.new().setup(rules, made[0])
	refused.clear()
	casts.clear()
	rules._cooldowns[0] = 0.0
	aim.pick(0)
	aim.press(at)
	aim.release(at)
	t.check(not aim.placed and refused == [[0, "no_dead"]], "aimed: a first click on no body is refused at once (%s)" % [refused])
	RD._body(made, 5, at)
	refused.clear()
	aim.press(at)  # the slot stays picked (a second pick would let go of it)
	aim.release(at)
	t.check(aim.placed and refused.is_empty() and casts.is_empty(), "a first click on a body places it")
	aim.press(at + Vector2(3.0, 0.0))
	aim.release(at + Vector2(3.0, 0.0))
	t.check(casts.size() == 1 and (casts[0] as WalkingCorpseFx).origin == at
		and (casts[0] as WalkingCorpseFx).extra.get("to", Vector2.INF) == at + Vector2(3.0, 0.0),
		"and the second click casts it from the body to there")
	for fx in casts:
		if is_instance_valid(fx):
			fx.end_now()
	aim.free()
	rules.free()


## The first-click body refusal is only for a power that needs a body: Gravecall's and Skylift's first clicks (two clicks, no
## "needs") are still placed with no remain in town.
static func _others_place(t, made: Array) -> void:
	RD._clear_all(made)
	var rules := Rules.new().setup(PackedStringArray(["gravecall", "skylift", "walker"]), null, made[1], made[3], made[0], made[6])
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var aim := Targeting.new().setup(rules, made[0])
	var at := RD._empty(made)
	var placed := []
	for slot in 2:
		aim.pick(slot)
		aim.press(at)
		aim.release(at)
		placed.append(aim.placed and aim.first == at)
		aim.unfocus()
	t.check(placed == [true, true] and refused.is_empty() and (made[0] as Crowd).remains.enabled,
		"Gravecall and Skylift still place their first click with no body in town (%s, %s)" % [placed, refused])
	aim.free()
	rules.free()


## "arriving in the open it stands and waits, not lying down": walked to the second click, it stands there for its next order.
static func _walks(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var rem: Remains = crowd.remains
	var ctx: FxContext = made[5]
	var at := RD._empty(made)
	var corpse: Person = crowd.citizens[2]
	var r := RD._body(made, 2, at, &"deathmark")
	var design := r.design
	rem.step(20.0)  # it has lain a while
	var to := _spot(made, at, 5.0)
	t.check(r != null and to != Vector2.INF, "a body, and open ground 5 off")
	var fx := _cast(made[5], at + Vector2(0.3, 0.0), to)
	t.check(rem.pick(at) == null and rem.all().is_empty(), "the body is taken off the ground while it walks")
	t.check(is_instance_valid(corpse) and not corpse.visible and rem._shown_count() == 0,
		"its corpse is not drawn at the old spot while it walks away (Death Mark's 20 s hold too)")
	t.check(fx.order == "walk", "the second click in the open is its first order: a walk (%s)" % fx.order)
	RD._run(fx, 0.1)
	var up: Array = fx.visitors.living() if fx.visitors != null else []
	var w: Animal = up[0] if up.size() == 1 else null
	t.check(w != null and w.breed == Animal.Breed.ZOMBIE and w.worn == design and w.worn_tint == Color.WHITE and w.eyes.a == 0.0,
		"it gets up in its own look, no grey, no eyes: it passes for living")
	RD._run(fx, WalkingCorpseFx.T_RISE)  # it has got up
	var start := w.ground_pos if w != null else at
	RD._run(fx, 2.0)
	var walked := w.ground_pos.distance_to(start) if is_instance_valid(w) else 0.0
	var pace := DummyEnemy.WALK_SPEED * 2.0
	t.check(walked > pace * 0.85 and walked < pace * 1.15,
		"it walks at a person's pace (%.2f in 2 s, a walk is %.2f)" % [walked, pace])
	var sig := fx.sigil
	t.check(is_instance_valid(sig) and sig.get_parent() == ctx.overhead
		and sig.position.distance_to(Iso.ground_to_screen(w.ground_pos) + Vector2(0.0, -WalkingCorpseFx.SIGIL_UP)) < 0.01,
		"it carries a sigil all its life: Death's skull 26 px over it")
	var waited := _until(fx, func() -> bool: return fx.order != "walk" or fx.laid, 30.0)
	t.check(not fx.laid and fx.order == "wait" and fx.can_follow_up() and rem.pick(to, false, true) == null
		and is_instance_valid(w) and w.ground_pos.distance_to(to) <= 0.3,
		"arriving in the open it stands and waits, not lying down (%.1f s, laid %s, order %s)" % [waited, fx.laid, fx.order])
	var stood := w.ground_pos
	RD._run(fx, 3.0)
	t.check(not fx.laid and fx.order == "wait" and w.ground_pos == stood and rem.all().is_empty() and is_instance_valid(fx.sigil),
		"and it stays standing there, the body still up, the sigil over it")
	fx.end_now()
	t.check(fx.laid and rem.pick(stood) == r and fx.sigil == null, "cut short, it lies down where it stood and its sigil goes")


## Orders through the wheel's hooks (R7, R15): its hooks; "a walk order sends it on"; "a walk past 12 is refused"; and Rules hands a
## walk with no "target" key straight to it.
static func _orders(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := RD._empty(made)
	var fx := _standing(made, 6, at)
	var w := fx.walker
	t.check(fx.order == "wait" and fx.can_follow_up() and fx.follow_up_wheel() and fx.follow_up_subject() == w
		and fx.follow_up_from() == w.ground_pos and fx.follow_up_reach() == WalkingCorpseFx.ORDER_REACH
		and fx.follow_up_orders() == ["walk", "attack", "enter"],
		"its hooks: the wheel on the walker itself, reach 12 from it, WALK / ATTACK / ENTER")
	var p := _spot(made, w.ground_pos, 4.0)
	t.check(fx.follow_up(p, {"order": "walk", "to": p}) and fx.order == "walk", "a walk order is taken")
	var took := _until(fx, func() -> bool: return fx.order != "walk" or fx.laid, 15.0)
	t.check(fx.order == "wait" and not fx.laid and fx.walker.ground_pos.distance_to(p) <= WalkingCorpseFx.ARRIVE,
		"a walk order sends it on (%.1f s, %.2f off)" % [took, fx.walker.ground_pos.distance_to(p)])
	var far := _far(made, fx.walker.ground_pos, 15.0)
	t.check(far != Vector2.INF and not fx.follow_up(far, {"order": "walk", "to": far}) and fx.order == "wait",
		"a walk past 12 is refused")
	t.check(not fx.follow_up(p, {"order": "burn", "to": p}) and not fx.follow_up(p, {"to": p}) and not fx.follow_up(p, {})
		and fx.order == "wait", "an order it does not know is refused")
	var open := WalkingCorpseFx.indoors_at(ctx.env, crowd, p) == null
	t.check(not open or not fx.follow_up(p, {"order": "enter", "to": p}), "ENTER with no building there is refused")
	fx.end_now()
	# Rules hands a subject's walk on as it is: no "target" key, the effect judges it.
	var at2 := _spot(made, at, 6.0)
	RD._body(made, 7, at2)
	var rules := Rules.new().setup(PackedStringArray(["walker"]), null, made[1], made[3], made[0], made[6])
	rules.caster = func(sc: GDScript, g: Vector2, e: Dictionary) -> FxTimeline: return FxTimeline.cast(sc, made[5], g, e)
	var got := rules.cast(0, at2, {"to": at2}) as WalkingCorpseFx
	t.check(got != null, "(Rules casts it on the body)")
	if got != null:
		RD._run(got, WalkingCorpseFx.T_RISE + 0.3)
		var q := _spot(made, got.walker.ground_pos, 3.0)
		var extra := {"order": "walk", "to": q}
		t.check(rules.can_recast(0) and rules.recast(0, q, extra) and not extra.has("target") and got.order == "walk"
			and got.dest.distance_to(q) < 0.01, "Rules: a walk order on the walker goes through, no target key")
		var far2 := _far(made, got.walker.ground_pos, 15.0)
		t.check(not rules.recast(0, far2, {"order": "walk", "to": far2}), "Rules: one past 12 is refused by the effect")
		got.end_now()
	rules.free()


## "an attack order kills quietly and leaves a body"; "two kills, then attack is refused".
static func _attack(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var rem: Remains = crowd.remains
	var at := RD._empty(made)
	var fx := _standing(made, 8, at)
	var w := fx.walker
	var foe: Person = crowd.citizens[70]
	var foe_pos := _spot(made, w.ground_pos, 4.0)
	foe.ground_pos = foe_pos
	var by: Person = crowd.citizens[71]
	by.ground_pos = foe_pos + (foe_pos - w.ground_pos).normalized() * 2.0
	by.mind = Person.Mind.CALM
	var deaths: Array = []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void: deaths.append([e, kind])
	field.enemy_killed.connect(on_kill)
	var alarm := crowd.alarm
	# Unfair foes first: out of ATTACK_R, or guised, or nobody.
	var far: Person = crowd.citizens[72]
	far.ground_pos = _far(made, w.ground_pos, 7.0)
	t.check(not fx.follow_up(far.ground_pos, {"order": "attack", "foe": far}) and fx.order == "wait", "an attack on one 7 off is refused")
	foe.statuses[&"guise"] = 5.0
	t.check(not fx.follow_up(foe_pos, {"order": "attack", "foe": foe}) and fx.order == "wait", "and on one guised")
	foe.statuses.erase(&"guise")
	t.check(not fx.follow_up(foe_pos, {"order": "attack"}) and not fx.follow_up(foe_pos, {"order": "attack", "foe": w}),
		"and with no person to attack")
	t.check(fx.follow_up(foe_pos, {"order": "attack", "foe": foe}) and fx.order == "attack", "an attack on one 4 off is taken")
	var took := _until(fx, func() -> bool: return fx.order != "attack", 11.0, [by])
	t.check(not foe.is_alive() and deaths == [[foe, &"grave"]] and fx.kills == 1 and fx.order == "wait" and took < 10.0,
		"an attack order kills quietly as the grave kind (%.1f s, %s)" % [took, deaths])
	t.check(rem.pick(foe_pos) != null, "and leaves a body")
	t.check(crowd.alarm == alarm and by.is_alive() and by.mind == Person.Mind.CALM,
		"no alarm, and a citizen 2.0 from the kill stays calm (alarm %.2f -> %.2f, %s)" % [alarm, crowd.alarm, Person.Mind.keys()[by.mind]])
	t.check(not fx.laid and fx.can_follow_up(), "and it stands, waiting for its next order")
	# A second kill, then no more.
	var foe2: Person = crowd.citizens[73]
	foe2.ground_pos = _spot(made, fx.walker.ground_pos, 3.0)
	t.check(fx.follow_up(foe2.ground_pos, {"order": "attack", "foe": foe2}), "a second attack is taken")
	_until(fx, func() -> bool: return fx.order != "attack", 11.0)
	var foe3: Person = crowd.citizens[74]
	foe3.ground_pos = _spot(made, fx.walker.ground_pos, 3.0)
	t.check(not foe2.is_alive() and fx.kills == WalkingCorpseFx.KILLS_MOST
		and not fx.follow_up(foe3.ground_pos, {"order": "attack", "foe": foe3}) and fx.order == "wait" and foe3.is_alive(),
		"two kills, then attack is refused (%d kills)" % fx.kills)
	t.check(fx.follow_up(foe3.ground_pos, {"order": "walk", "to": foe3.ground_pos}), "(it still walks where it is told)")
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## "the foe goes indoors first: no kill, it waits"; and a chase that runs ATTACK_SECS gives up.
static func _foe_indoors(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var fx := _standing(made, 9, at)
	var foe: Person = crowd.citizens[75]
	foe.ground_pos = _spot(made, fx.walker.ground_pos, 5.0)
	t.check(fx.follow_up(foe.ground_pos, {"order": "attack", "foe": foe}), "(the attack is taken)")
	RD._run(fx, 0.5)
	foe.inside = true
	RD._run(fx, 0.2)
	t.check(fx.order == "wait" and fx.kills == 0 and foe.is_alive(), "the foe goes indoors first: no kill, it waits (%s)" % fx.order)
	foe.inside = false
	# Out of reach all along (always 3 ahead of it): at ATTACK_SECS it gives up.
	t.check(fx.follow_up(foe.ground_pos, {"order": "attack", "foe": foe}), "(a new attack)")
	var ahead := (foe.ground_pos - fx.walker.ground_pos).normalized() * 3.0
	var took := _until(fx, func() -> bool:
		if is_instance_valid(fx.walker):
			foe.ground_pos = fx.walker.ground_pos + ahead
		return fx.order != "attack", 12.0)
	t.check(fx.order == "wait" and fx.kills == 0 and foe.is_alive() and absf(took - WalkingCorpseFx.ATTACK_SECS) < 0.2,
		"a chase that runs 10 s gives up: no kill, it waits (%.1f s)" % took)
	fx.end_now()


## At WALK_LIFE it lies down wherever it has got to.
static func _walk_life(t, made: Array) -> void:
	RD._clear_all(made)
	var rem: Remains = (made[0] as Crowd).remains
	var at := RD._empty(made)
	var r := RD._body(made, 3, at)
	var far := Vector2(-at.x, -at.y)
	var grid: WalkGrid = made[2]
	far = grid.nearest_walkable(far)
	t.check(far != Vector2.INF and far.distance_to(at) > WalkingCorpseFx.WALK_LIFE * DummyEnemy.WALK_SPEED + 4.0,
		"somewhere farther than a 40 s walk (%.1f off)" % [far.distance_to(at) if far != Vector2.INF else 0.0])
	var fx := _cast(made[5], at, far)
	RD._run(fx, WalkingCorpseFx.WALK_LIFE - 0.5)
	t.check(not fx.laid, "still walking just short of WALK_LIFE")
	var sig := fx.sigil
	t.check(is_instance_valid(sig), "it carries a sigil all its life (still there at 39.5 s)")
	var last := fx.walker.ground_pos
	while not fx.laid and fx.t < WalkingCorpseFx.WALK_LIFE + 1.0:
		if is_instance_valid(fx.walker):
			last = fx.walker.ground_pos
		RD._run(fx, DT)
	t.check(fx.laid and r.pos.distance_to(at) > 5.0 and r.pos.distance_to(far) > 1.0 and rem.pick(r.pos) == r and not r.hidden
		and r.pos.distance_to(last) < 0.01 and fx.t >= WalkingCorpseFx.WALK_LIFE,
		"time out: lies down where it stands at 40 s (%s, last %s)" % [r.pos, last])
	t.check(rem.age(r) < 1.0 and rem.has_soul(r) and rem._drawn(r) and rem._shown_count() == 1,
		"its clock restarted, and it is drawn lying there at once, and only there (age %.2f)" % rem.age(r))
	t.check(fx.sigil == null and (not is_instance_valid(sig) or sig.is_queued_for_deletion()), "and its sigil goes as it lies down")
	t.check(fx.visitors == null or fx.visitors.living().is_empty(), "the walker is gone: only the body lies there")
	fx.end_now()


## "nobody flees and alarm is unchanged": the people it passes stay calm, the crowd holds no danger, and a soldier beside it does not
## cut it down.
static func _quiet(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	RD._body(made, 4, at)
	var to := _spot(made, at, 5.0)
	var near: Array = []
	for i in 6:
		var p: Person = crowd.citizens[20 + i]
		p.ground_pos = at.lerp(to, float(i) / 5.0) + Vector2(0.0, 0.4)
		near.append(p)
	var soldier: Person = crowd.soldiers[0]
	soldier.ground_pos = at + Vector2(0.2, 0.2)
	soldier.mind = Person.Mind.CALM
	near.append(soldier)
	var alarm := crowd.alarm
	var held := crowd.held_count()
	crowd.on_cast(at, Vector2.ZERO, 0.0, "walker")
	var fx := _cast(made[5], at, to)
	RD._run(fx, 3.0, near)
	var calm := near.all(func(p: Person) -> bool: return p.mind == Person.Mind.CALM)
	t.check(crowd.alarm == alarm and crowd.held_count() == held and calm,
		"nobody flees and alarm is unchanged (alarm %.2f -> %.2f, held %d, minds %s)" % [alarm, crowd.alarm, crowd.held_count(),
			near.map(func(p: Person) -> String: return Person.Mind.keys()[p.mind])])
	t.check(fx.walker != null and is_instance_valid(fx.walker) and fx.walker.is_alive() and fx.walker.health == 1.0,
		"no soldier strikes it: it walks like anyone else")
	var src := FileAccess.get_file_as_string("res://src/fx/death/walking_corpse.gd")
	t.check(src != "" and not src.contains("add_alarm") and not src.contains("fright(") and not src.contains("panic(")
		and not src.contains("threats.register"), "the effect's code never alarms, frightens or panics anyone")
	fx.end_now()


## Everyone out of the way, and every remain taken up, the hidden ones too.
static func _clear_every(made: Array) -> void:
	RD._clear_all(made)
	var rem: Remains = (made[0] as Crowd).remains
	for r in rem._list.duplicate():
		rem.take(r)


## A shelter with walkable ground before its door, and its door.
static func _shelter(made: Array) -> Structure:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var keys: Array = crowd.shelters.shelters.keys()
	keys.sort_custom(func(a: Structure, b: Structure) -> bool: return a.get_instance_id() < b.get_instance_id())
	for s: Structure in keys:
		if s.destroyed or not crowd.shelters._usable(s):
			continue
		var door := WalkingCorpseFx.door_of(s, grid)
		if door != Vector2.INF and _spot(made, door, 3.0) != Vector2.INF:
			return s
	return null


## "a plague body walked into a shelter infects up to 3 inside", nearest first (all inside stand at its middle: by instance id).
static func _shelter_plague(t, made: Array) -> void:
	_clear_every(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var s := _shelter(made)
	t.check(s != null, "a shelter to walk into")
	if s == null:
		return
	var inside: Array[Person] = []
	for i in 5:
		var p: Person = crowd.citizens[40 + i]
		if p.inside:
			crowd.shelters.release(p)
		p.sick_left = 0.0
		crowd.shelters._enter(p, s)
		(crowd.shelters.shelters[s].inside as Array).append(p)
		inside.append(p)
	var door := WalkingCorpseFx.door_of(s, grid)
	var from := _spot(made, door, 3.0)
	var dead: Person = crowd.citizens[50]
	dead.ground_pos = from
	dead.infect(PlagueManager.PLAGUE_LIFE)
	(made[3] as EnemyField).kill(dead, &"plague")
	var r := crowd.remains.pick(from)
	t.check(r != null and r.sick, "a plague body before its door")
	var fx := _cast(made[5], from, from)
	RD._run(fx, WalkingCorpseFx.T_RISE + 0.3)
	t.check(fx.order == "wait" and fx.follow_up(s.center(), {"order": "enter", "to": s.center()}) and fx.order == "enter",
		"enter a shelter: the order is taken (%s)" % fx.order)
	RD._run(fx, 20.0)
	t.check(fx.laid and r.hidden and fx.shelter == s and fx.sigil == null,
		"enter a shelter: hidden, plague in, the walk over (laid %s, hidden %s)" % [fx.laid, r.hidden if r != null else false])
	var sick := inside.filter(func(p: Person) -> bool: return p.sick_left > 0.0)
	var by_id := inside.duplicate()
	by_id.sort_custom(func(a: Person, b: Person) -> bool: return a.get_instance_id() < b.get_instance_id())
	t.check(sick.size() == WalkingCorpseFx.INFECT_MOST and fx.infected.size() == 3 and fx.infected == by_id.slice(0, 3),
		"a plague body walked into a shelter infects up to 3 inside, nearest first (%d sick)" % sick.size())
	fx.end_now()
	# A clean body walked in infects nobody.
	for p in inside:
		p.sick_left = 0.0
	var clean: Person = crowd.citizens[51]
	clean.ground_pos = from
	(made[3] as EnemyField).kill(clean, &"mob")
	var fx2 := _cast(made[5], from, s.center())
	RD._run(fx2, 20.0)
	t.check(fx2.laid and inside.all(func(p: Person) -> bool: return p.sick_left <= 0.0), "a body that died of no plague brings none in")
	fx2.end_now()
	for p in inside:
		crowd.shelters.release(p)


## "a hidden remain is not picked by Raise": walked to a house door it is off the street; Raise is refused there, Walking Corpse
## still reaches it and walks it back out.
static func _hidden(t, made: Array) -> void:
	_clear_every(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var rem: Remains = crowd.remains
	var s := _shelter(made)
	if s == null:
		return
	var door := WalkingCorpseFx.door_of(s, grid)
	var from := _spot(made, door, 3.0)
	RD._body(made, 52, from)
	var fx := _cast(made[5], from, s.center())
	RD._run(fx, 20.0)
	var r: Remains.Remain = fx.remain
	t.check(fx.laid and r != null and r.hidden and rem.pick(r.pos) == null and rem.all().is_empty() and not rem._drawn(r),
		"walked indoors it is hidden: off the street and the drawing")
	fx.end_now()
	var rules := Rules.new().setup(PackedStringArray(["raise", "walker"]), null, made[1], made[3], made[0], made[6])
	rules.caster = func(sc: GDScript, g: Vector2, e: Dictionary) -> FxTimeline: return FxTimeline.cast(sc, made[5], g, e)
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var got := rules.cast(0, r.pos, {"mode": "zombie"})
	t.check(got == null and refused == [[0, "no_dead"]], "a hidden remain is not picked by Raise (%s)" % [refused])
	t.check(rem.pick(r.pos, false, true) == r, "the ledger still has it, for Walking Corpse alone")
	refused.clear()
	got = rules.cast(1, r.pos, {"to": from})
	t.check(got != null and refused.is_empty(), "Walking Corpse can walk it back out (%s)" % [refused])
	if got != null:
		RD._run(got, 20.0)
		var w := (got as WalkingCorpseFx).walker
		t.check((got as WalkingCorpseFx).order == "wait" and is_instance_valid(w) and w.ground_pos.distance_to(from) < 0.3,
			"walked back out, it stands on the street")
		got.end_now()
		t.check((got as WalkingCorpseFx).laid and not r.hidden and rem.pick(from) == r, "and lying down there it is out again, seen")
	rules.free()


## "carried off by another power: the wheel's subject is gone": the walker freed (Heaven's Door takes a pack's walkers), the effect
## stops taking orders and its sigil goes.
static func _carried_off(t, made: Array) -> void:
	_clear_every(made)
	var at := RD._empty(made)
	var fx := _standing(made, 61, at)
	t.check(fx.can_follow_up() and fx.follow_up_subject() == fx.walker, "(standing, its own subject)")
	var sig := fx.sigil
	fx.walker.free()
	t.check(fx.follow_up_subject() == null and not fx.can_follow_up() and not fx.follow_up(at, {"order": "walk", "to": at})
		and fx.follow_up_from() == fx.origin, "freed between frames: no subject, no order, and its reach is read from where it rose")
	RD._run(fx, DT)
	t.check(not fx.can_follow_up() and fx.follow_up_subject() == null and fx.sigil == null
		and (not is_instance_valid(sig) or sig.is_queued_for_deletion()),
		"carried off by another power: the wheel's subject is gone, and its sigil with it")
	fx.end_now()


## Freed without _finish (Battlefield.clear_effects() on a restart queue_frees it): the walker is gone, and the body is put
## back down where it had got to (the ledger still there), so it is never lost; no error, and its end after that changes nothing.
static func _exit(t, made: Array) -> void:
	_clear_every(made)
	var crowd: Crowd = made[0]
	var rem: Remains = crowd.remains
	var at := RD._empty(made)
	var r := RD._body(made, 60, at)
	var to := _spot(made, at, 5.0)
	var fx := _cast(made[5], at, to)
	RD._run(fx, WalkingCorpseFx.T_RISE + 2.0)
	var pack := fx.visitors
	var up := pack.living()
	t.check(up.size() == 1 and rem.all().is_empty() and not fx.laid, "(walking, the body off the ledger)")
	var was := up[0].ground_pos if up.size() == 1 else at
	fx._exit_tree()
	t.check(RD._all_gone(up) and pack.living().is_empty() and not crowd.visitors.has(pack),
		"freed without its end, the walker is gone and the pack leaves the town")
	t.check(fx.laid and rem.pick(was) == r and r.pos.distance_to(was) < 0.01 and not r.hidden,
		"and the body lies back down where it had got to (%s)" % [r.pos])
	t.check(fx.sigil == null, "and its sigil is let go")
	fx.end_now()
	t.check(fx.finished and rem.all().size() == 1, "and its end after that changes nothing (one body, %d)" % rem.all().size())
	rem.take(r)
