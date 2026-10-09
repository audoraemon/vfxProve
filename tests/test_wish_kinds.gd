extends RefCounted
## v0.11 M1 the rest of the pool (spec §5.3): "Save my child" -- waits until engaged (a cast near the child or the soldier;
## the tag's click is the HUD's), then the soldier drags the child toward the Citadel's gate; stopped or turned within 45 s
## grants it, the child dead, the gate reached or the time out fails it (review focus 2); the soldier felled before it is
## engaged by the god's own cast engages and grants it, by any other hand fails it (controller ruling); "Lead my brother
## out" -- whispered to a gate, he escapes; "Show yourself to my family" -- three whispered. The pool is the spec's eight.

const DT := 0.05


static func run(t) -> void:
	_pool(t)
	_rescue(t)
	_rally(t)
	_early(t)
	_mercy(t)
	_family(t)
	_people(t)


static func _world(loadout := PackedStringArray()) -> Dictionary:
	var def := TierBook.board("vigil_flame")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(loadout if not loadout.is_empty() else def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules}


static func _done(s: Dictionary) -> void:
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


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var r := RandomNumberGenerator.new()
	r.seed = seed_n
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, r, []) else null


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


static func _pool(t) -> void:
	var ids := []
	for d in WishBook.pool():
		ids.append(d.id)
	t.check(ids == ["moneylender", "watchtower", "tax_collector", "informer", "child", "brother", "sign", "family", "bailiff",
		"neighbours", "bully", "pressed"], "the pool: M1's eight in the spec's order, then M2's two, then M3's two (%s)" % [ids])
	var child := _def("child")
	t.check(child.text == "Save my child" and child.kind == "rescue" and child.reward == 15 and Array(child.clashes) == ["unaware_town"]
		and _def("brother").text == "Lead my brother out" and _def("brother").reward == 10
		and _def("family").text == "Show yourself to my family" and _def("family").reward == 10, "their words and rewards")
	var s := _world()
	var drawn := false
	for n in range(1, 21):
		var r := RandomNumberGenerator.new()
		r.seed = n
		var got := WishBook.draw(WishBook.pool(), 8, PackedStringArray(["unaware_town"]), s.crowd, s.town, r)
		for w in got:
			drawn = drawn or w.def.id == "child"
			w.release()
	t.check(not drawn, "Save my child is never heard in an unaware town")
	_done(s)


static func _rescue(t) -> void:
	var s := _world()
	var w := _wish(s, "child") as RescueWish
	t.check(w != null and w.child.profile.family == w.wisher.profile.family and w.child != w.wisher
		and w.soldier.soldier and w.soldier.corps == Person.Corps.NONE, "the child of the wisher's household, and a soldier")
	t.check(w.timed() and w.waiting() and not w.engaged and w.check(s.rules) == Objective.Status.PENDING, "it waits, unengaged")
	var labels := []
	for tag in w.tags():
		labels.append(tag.label)
	t.check(labels == ["THE CHILD", "SOLDIER", Wish.WISHER_LABEL], "the child, the soldier and the wisher tagged (%s)" % [labels])
	w.on_cast("doom", w.child.ground_pos + Vector2(RescueWish.ENGAGE_REACH + 1.0, 0.0))
	t.check(not w.engaged, "a cast too far from them does not engage it")
	w.on_cast("doom", w.child.ground_pos + Vector2(RescueWish.ENGAGE_REACH - 0.2, 0.0))
	t.check(w.engaged and not w.waiting() and w.soldier.mind == Person.Mind.DUTY and not w.engage(),
		"one near the child engages it: the soldier sets out; once only")
	t.check(w.hud_text(s.rules) == "Save my child (+0) 0:45", "its clock shows (%s)" % w.hud_text(s.rules))
	_arrive(w.soldier, w.child.ground_pos)
	w.step(s.rules, RescueWish.RETARGET)
	t.check(w.dragging and w.child.mind == Person.Mind.DUTY and w.soldier.goal().distance_to(RescueWish.GATE) < 1.5,
		"he takes the child toward the Citadel's gate")
	w.soldier.mind = Person.Mind.CONFUSED
	t.check(w.check(s.rules) == Objective.Status.DONE and w.child.mind != Person.Mind.DUTY, "turned: granted, the child let go")
	_done(s)

	var late := _world()
	var l := _wish(late, "child") as RescueWish
	l.engage()
	l.step(late.rules, RescueWish.SECONDS + 1.0)
	t.check(l.check(late.rules) == Objective.Status.FAILED and l.soldier.mind != Person.Mind.DUTY, "45 s gone: failed, the soldier let go")
	_done(late)

	var gate := _world()
	var g := _wish(gate, "child") as RescueWish
	g.engage()
	g.dragging = true
	_arrive(g.soldier, g._gate)
	t.check(g.check(gate.rules) == Objective.Status.FAILED, "the gate reached: failed")
	_done(gate)

	var lost := _world()
	var c := _wish(lost, "child") as RescueWish
	(lost.field as EnemyField).kill(c.child, &"doom")
	t.check(c.check(lost.rules) == Objective.Status.FAILED and c.tags().is_empty(), "the child dead, unengaged: failed (review focus 2)")
	_done(lost)

	var stopped := _world()
	var k := _wish(stopped, "child") as RescueWish
	k.engage()
	(stopped.field as EnemyField).kill(k.soldier, &"doom")
	t.check(k.check(stopped.rules) == Objective.Status.DONE, "the soldier dead: granted")
	_done(stopped)


## Final review, item 1: the town's rally (City Emergency, the first Citadel hit, Judgement's start) sends every corps-less
## soldier to the ring, an engaged rescuer included. That is the town's order, not the god's: the wish stays pending and he
## is sent back on his errand. Only the god's own effects turn him.
static func _rally(t) -> void:
	var s := _world()
	var w := _wish(s, "child") as RescueWish
	w.engage()
	w.step(s.rules, DT)
	t.check(w.soldier.mind == Person.Mind.DUTY, "(set-up) the engaged soldier is on his errand")
	(s.crowd as Crowd).rally()
	t.check(w.soldier.mind == Person.Mind.RALLY, "(set-up) the rally sent him to the ring")
	t.check(w.check(s.rules) == Objective.Status.PENDING, "the town's rally does not grant the rescue")
	w.step(s.rules, RescueWish.RETARGET)
	t.check(w.soldier.mind == Person.Mind.DUTY and w.soldier.goal().distance_to(w.child.ground_pos) < 1.5
		and w.check(s.rules) == Objective.Status.PENDING, "he is back on his errand toward the child, the wish still pending")
	_arrive(w.soldier, w.child.ground_pos)
	w.step(s.rules, RescueWish.RETARGET)
	w.soldier.send_to_post(Vector2.ZERO)
	t.check(w.check(s.rules) == Objective.Status.PENDING, "a POST order is no turning either")
	w.step(s.rules, RescueWish.RETARGET)
	t.check(w.dragging and w.soldier.mind == Person.Mind.DUTY and w.soldier.goal().distance_to(RescueWish.GATE) < 1.5,
		"back on his errand with the child, he drags them to the gate")
	_done(s)

	for m: int in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.WHISPERED, Person.Mind.COMPELLED]:
		var o := _world()
		var x := _wish(o, "child") as RescueWish
		x.engage()
		x.step(o.rules, DT)
		x.soldier.mind = m as Person.Mind
		t.check(x.check(o.rules) == Objective.Status.DONE, "the god's own effect (mind %d) turns him: granted" % m)
		_done(o)


## The controller's ruling: engagement is judged first. The soldier felled before the wish is engaged engages it and grants
## it if the god's own cast felled him; any other hand fails it.
static func _early(t) -> void:
	var god := _world(PackedStringArray(["whisper", "doom", "discord"]))
	var a := _wish(god, "child") as RescueWish
	var slot: int = (god.rules as Rules).loadout.find("doom")
	t.check(slot >= 0 and (god.rules as Rules).cast(slot, a.soldier.ground_pos + Vector2(8.0, 0.0)) == null,
		"(set-up) a Silent Doom goes out, far from the soldier")
	(god.field as EnemyField).kill(a.soldier, &"doom")
	t.check(a.waiting() and a.check(god.rules) == Objective.Status.DONE and a.engaged and not a.waiting(),
		"the soldier felled by the god's own cast before it is engaged: it engages, and is granted")
	_done(god)

	var other := _world()
	var b := _wish(other, "child") as RescueWish
	(other.field as EnemyField).kill(b.soldier, &"fire")
	t.check(b.check(other.rules) == Objective.Status.FAILED and not b.engaged,
		"the soldier felled by any other hand before it is engaged: failed, no reward")
	_done(other)

	var gone := _world()
	var c := _wish(gone, "child") as RescueWish
	c.soldier.die(&"fire", Vector2.INF)
	t.check(c.check(gone.rules) == Objective.Status.FAILED, "the soldier dead some other way, unannounced, before it is engaged: failed")
	_done(gone)

	var click := _world()
	var d := _wish(click, "child") as RescueWish
	t.check(d.engage() and d.engaged and not d.engage(), "a click on its tag (engage()) engages it, once")
	_done(click)


static func _mercy(t) -> void:
	var s := _world()
	var w := _wish(s, "brother") as MercyWish
	var exit: Vector2 = MercyWish.exits()[0]
	_arrive(w.target, exit)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.PENDING, "at a gate unwhispered: nothing")
	var escaped := (s.crowd as Crowd).escaped_count
	w.target.whisper(exit, 8.0)
	_arrive(w.target, exit)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE and (s.crowd as Crowd).escaped_count == escaped + 1
		and not (s.crowd as Crowd).citizens.has(w.target), "whispered to a gate: he escapes, granted")
	var dead := _wish(s, "brother", 8) as MercyWish
	(s.field as EnemyField).kill(dead.target, &"doom")
	t.check(dead.check(s.rules) == Objective.Status.FAILED, "dead first: failed")
	_done(s)


static func _family(t) -> void:
	var s := _world()
	var w := _wish(s, "family") as FamilyWish
	var near := true
	for p: Person in w.family:
		near = near and p != w.wisher and p.profile.home.distance_to(w.wisher.profile.home) <= FamilyWish.REACH
	t.check(w.family.size() == FamilyWish.COUNT and near, "three living near the wisher's home")
	var first: Person = w.family[0]
	first.whisper(first.ground_pos + Vector2(1.0, 0.0), 8.0)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.PENDING and w.hud_text(s.rules) == "Show yourself to my family (+0) 1 / 3",
		"one shown (%s)" % w.hud_text(s.rules))
	for p: Person in w.family:
		p.whisper(p.ground_pos + Vector2(1.0, 0.0), 8.0)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "all three shown: granted")
	var other := _wish(s, "family", 11) as FamilyWish
	(s.field as EnemyField).kill(other.family[1], &"doom")
	t.check(other.check(s.rules) == Objective.Status.FAILED, "one dead before being shown: failed")
	_done(s)


## Each sets its people aside for the Descent to reserve (Task 6), and a choose that fails takes nobody.
static func _people(t) -> void:
	var s := _world()
	var r := _wish(s, "child") as RescueWish
	t.check(r.people().size() == 3 and r.people().has(r.child) and r.people().has(r.soldier), "Save my child sets aside the wisher, child and soldier")
	var m := _wish(s, "brother") as MercyWish
	t.check(m.people().size() == 2 and m.people().has(m.target), "Lead my brother out sets aside the wisher and him")
	var f := _wish(s, "family") as FamilyWish
	t.check(f.people().size() == 1 + FamilyWish.COUNT, "Show yourself to my family sets aside the wisher and the three")
	var taken := []
	var bare := _def("brother").instance() as MercyWish
	var crowd: Crowd = s.crowd
	var only: Array[Person] = Wish.lay(crowd, taken)
	taken.append_array(only.slice(1))
	t.check(not bare.choose(crowd, s.town, RandomNumberGenerator.new(), taken) and taken.size() == only.size() - 1,
		"a brother with no second citizen to name takes nobody")
	_done(s)
