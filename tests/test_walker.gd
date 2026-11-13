extends RefCounted
## Walking Corpse (Death, Tier III, quiet; spec 5.4): click a body, then where it should go. The body gets up -- a ZOMBIE-breed
## Visitor in the dead person's own look, no grey, no eyes, so it passes for living -- and walks there by the streets at a
## person's walk pace. Nobody panics, no alarm, no soldier cuts it down. When it gets there (or at WALK_LIFE) it lies down
## again: its remain moved there and its clock restarted. Walked into a shelter or to a house door it is hidden: off the
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
	_walk_life(t, made)
	_quiet(t, made)
	_shelter_plague(t, made)
	_hidden(t, made)
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


## "walks to the second click and lies down there, clock restarted"
static func _walks(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var rem: Remains = crowd.remains
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
	var waited := 0.0
	while not fx.laid and waited < WalkingCorpseFx.WALK_LIFE:
		RD._run(fx, 0.5)
		waited += 0.5
	t.check(fx.laid and waited < WalkingCorpseFx.WALK_LIFE - 20.0, "it gets there and lies down (%.1f s)" % [waited + 2.7])
	var there := rem.pick(to)
	t.check(there == r and r.pos.distance_to(to) < 0.3 and not r.hidden and rem.age(r) < 1.0 and rem.has_soul(r),
		"walks to the second click and lies down there, clock restarted (%s, at %s, age %.2f)" % [there == r, r.pos, rem.age(r)])
	t.check(rem._drawn(r) and rem._shown_count() == 1 and not corpse.visible,
		"and it is drawn lying there at once, and only there")
	t.check(fx.visitors == null or fx.visitors.living().is_empty(), "the walker is gone: only the body lies there")
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
	RD._run(fx, 1.0)
	t.check(fx.laid and r.pos.distance_to(at) > 5.0 and r.pos.distance_to(far) > 1.0 and rem.pick(r.pos) == r and not r.hidden,
		"at WALK_LIFE it lies down where it got to (%s)" % [r.pos])
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
	var fx := _cast(made[5], from, s.center())
	RD._run(fx, 20.0)
	t.check(fx.laid and r.hidden and fx.shelter == s, "it walks in and lies down hidden (laid %s, hidden %s)" % [fx.laid, r.hidden if r != null else false])
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
		t.check((got as WalkingCorpseFx).laid and not r.hidden and rem.pick(from) == r, "out on the street again, seen")
		got.end_now()
	rules.free()


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
	fx.end_now()
	t.check(fx.finished and rem.all().size() == 1, "and its end after that changes nothing (one body, %d)" % rem.all().size())
	rem.take(r)
