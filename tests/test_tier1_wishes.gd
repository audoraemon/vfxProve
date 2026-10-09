extends RefCounted
## v0.11 M2 the two new wishes (mission spec §5): "Stop the bailiff" -- a timed Rescue: once engaged, the bailiff walks from his
## post to the wisher's home; killed, turned, or still short of the door at 50 s grants it, his reaching it fails it -- and "Let
## my neighbours believe" (Faith) -- three of the wisher's neighbours whispered to the wisher each believe. Both may be heard in
## an Unaware town; the tax collector wish is never heard on The Tax Collector's night.

const DT := 0.05


static func run(t) -> void:
	_pool(t)
	_bailiff(t)
	_bailiff_ends(t)
	_neighbours(t)
	_routes(t)
	_walks(t)
	_freed(t)


static func _world() -> Dictionary:
	var def := MissionBook.warning()
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
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
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


static func _labels(w: Wish) -> Array:
	var out := []
	for tag in w.tags():
		out.append(tag.label)
	return out


static func _pool(t) -> void:
	var b := _def("bailiff")
	var n := _def("neighbours")
	t.check(b != null and b.text == "Stop the bailiff" and b.kind == "rescue" and b.reward == 15 and b.clashes.is_empty()
		and n != null and n.text == "Let my neighbours believe" and n.kind == "faith" and n.reward == 10 and n.clashes.is_empty(),
		"the two new wishes: their words, kinds and rewards, and no clash with a sleeping town")
	t.check(Array(_def("tax_collector").clashes) == ["hunts_tax_collector"], "the tax collector wish stays off The Tax Collector's night")
	var s := _world()
	var heard := {}
	for k in range(1, 41):
		var r := RandomNumberGenerator.new()
		r.seed = k
		for w in WishBook.draw(WishBook.pool(), 3, PackedStringArray([TierBook.UNAWARE_TAG, "hunts_tax_collector"]), s.crowd, s.town, r):
			heard[w.def.id] = true
			w.release()
	t.check(heard.has("bailiff") and heard.has("neighbours") and not heard.has("tax_collector") and not heard.has("child"),
		"on The Tax Collector's night, both new wishes can be heard; the tax collector and the child never (%s)" % [heard.keys()])
	_done(s)


static func _bailiff(t) -> void:
	var s := _world()
	var w := _wish(s, "bailiff") as BailiffWish
	t.check(w != null and w.bailiff.soldier and w.bailiff.corps == Person.Corps.NONE
		and w.bailiff.ground_pos.distance_to(w.home) >= BailiffWish.MIN_WALK - 0.01, "a free soldier at least 10 units from the wisher's home")
	t.check(w.timed() and w.waiting() and w.check(s.rules) == Objective.Status.PENDING and _labels(w) == ["BAILIFF", "HOME", Wish.WISHER_LABEL],
		"it waits, unengaged; the bailiff, the home and the wisher tagged (%s)" % [_labels(w)])
	w.on_cast("doom", w.home + Vector2(BailiffWish.ENGAGE_REACH + 1.0, 0.0))
	t.check(not w.engaged, "a cast too far off does not engage it")
	w.on_cast("doom", w.home + Vector2(BailiffWish.ENGAGE_REACH - 0.2, 0.0))
	t.check(w.engaged and w.bailiff.mind == Person.Mind.DUTY and w.bailiff.goal().distance_to(w.home) < 1.0 and not w.engage(),
		"a cast by the home engages it: the bailiff sets out for it; once only")
	t.check(w.hud_text(s.rules) == "Stop the bailiff (+0) 0:50", "its clock shows (%s)" % w.hud_text(s.rules))
	w.bailiff.mind = Person.Mind.FIGHT
	t.check(w.check(s.rules) == Objective.Status.DONE and w.bailiff.mind != Person.Mind.DUTY, "turned (to fight): granted")
	w.release()
	_done(s)


static func _bailiff_ends(t) -> void:
	var a := _world()
	var wa := _wish(a, "bailiff") as BailiffWish
	wa.engage()
	_arrive(wa.bailiff, wa.home)
	t.check(wa.check(a.rules) == Objective.Status.FAILED, "the bailiff at the door: failed")
	wa.release()
	_done(a)

	var b := _world()
	var wb := _wish(b, "bailiff") as BailiffWish
	wb.engage()
	wb.step(b.rules, BailiffWish.SECONDS + 1.0)
	t.check(wb.check(b.rules) == Objective.Status.DONE, "50 s gone and he never reached the door: granted")
	wb.release()
	_done(b)

	var c := _world()
	var wc := _wish(c, "bailiff") as BailiffWish
	wc.engage()
	(c.crowd as Crowd)._field.kill(wc.bailiff, &"fire")
	t.check(wc.check(c.rules) == Objective.Status.DONE, "engaged and killed: granted")
	wc.release()
	_done(c)

	var d := _world()
	var wd := _wish(d, "bailiff") as BailiffWish
	(d.crowd as Crowd)._field.kill(wd.bailiff, &"fire")
	t.check(wd.check(d.rules) == Objective.Status.FAILED, "killed before engagement by no power of the god's: failed")
	wd.release()
	_done(d)

	var e := _world()
	var we := _wish(e, "bailiff") as BailiffWish
	we.engage()
	we.bailiff.send_to_post(TownLayout.CITADEL_ORIGIN, true)
	we.step(e.rules, BailiffWish.RETARGET + DT)
	t.check(we.check(e.rules) == Objective.Status.PENDING and we.bailiff.mind == Person.Mind.DUTY,
		"the town's rally takes him off: he is sent back on his errand, still pending")
	we.release()
	_done(e)


static func _neighbours(t) -> void:
	var s := _world()
	var w := _wish(s, "neighbours") as NeighboursWish
	var ok := w != null and w.neighbours.size() == NeighboursWish.COUNT
	if ok:
		for p: Person in w.neighbours:
			ok = ok and p != w.wisher and p.profile.home.distance_to(w.wisher.profile.home) <= NeighboursWish.REACH \
				and (w.wisher.profile.family < 0 or p.profile.family != w.wisher.profile.family)
	t.check(ok, "three neighbours within 8 of the wisher's home, none of the household")
	t.check(_labels(w).count(NeighboursWish.LABEL) == 3 and w.hud_text(s.rules) == "Let my neighbours believe (+0) 0 / 3",
		"each marked; the HUD counts them")
	var first: Person = w.neighbours[0]
	first.mind = Person.Mind.WHISPERED
	_arrive(first, w.wisher.ground_pos + Vector2(NeighboursWish.NEAR + 1.0, 0.0))
	w.step(s.rules, DT)
	t.check(w.believing.is_empty(), "whispered but not brought to the wisher: not yet")
	_arrive(first, w.wisher.ground_pos + Vector2(NeighboursWish.NEAR - 0.5, 0.0))
	w.step(s.rules, DT)
	t.check(w.believing.size() == 1 and first.profile.faith == CitizenProfile.Faith.BELIEVER, "whispered to the wisher: believes")
	for i in range(1, 3):
		var p: Person = w.neighbours[i]
		p.mind = Person.Mind.WHISPERED
		_arrive(p, w.wisher.ground_pos)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "all three: granted")
	_done(s)

	var f := _world()
	var wf := _wish(f, "neighbours") as NeighboursWish
	(f.crowd as Crowd)._field.kill(wf.neighbours[0], &"fire")
	t.check(wf.check(f.rules) == Objective.Status.FAILED, "a neighbour dead before believing: failed")
	_done(f)


## The town's grid has courtyards shut in by the buildings round them (about a quarter of the doors): a bailiff with no route to
## the door would never set out and the wish would be granted for nothing, and a neighbour with no route to the wisher could
## never be led to them. Neither is chosen, on any seed.
static func _routes(t) -> void:
	var s := _world()
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	var drawn := 0
	var routed := 0
	for n in range(1, 17):
		var w := _wish(s, "bailiff", n) as BailiffWish
		if w != null:
			drawn += 1
			routed += int(not grid.path(w.home, w.bailiff.ground_pos).is_empty())
			w.release()
	t.check(drawn == 16 and routed == drawn, "a bailiff can walk to the door, on every seed (%d routed of %d)" % [routed, drawn])
	drawn = 0
	routed = 0
	for n in range(1, 17):
		var w := _wish(s, "neighbours", n) as NeighboursWish
		if w != null:
			drawn += 1
			var all := true
			for p: Person in w.neighbours:
				all = all and not grid.path(p.ground_pos, w.wisher.ground_pos).is_empty()
			routed += int(all)
	t.check(drawn == 16 and routed == drawn, "every neighbour can be led to the wisher, on every seed (%d routed of %d)" % [routed, drawn])
	_done(s)


## The clock starts on engagement, and an engaged bailiff really walks: stepped as the game steps him, he reaches the door well
## inside SECONDS and fails the wish; a wish nobody engages neither runs out nor ends.
static func _walks(t) -> void:
	for n in [5, 6, 10]:
		var s := _world()
		var w := _wish(s, "bailiff", n) as BailiffWish
		var from := w.bailiff.ground_pos
		w.step(s.rules, BailiffWish.SECONDS + 10.0)
		t.check(w.waiting() and is_equal_approx(w.seconds_left, BailiffWish.SECONDS) and w.check(s.rules) == Objective.Status.PENDING,
			"unengaged, the clock does not run (seed %d)" % n)
		w.engage()
		var clock := 0.0
		while clock < BailiffWish.SECONDS and w.check(s.rules) == Objective.Status.PENDING:
			(s.crowd as Crowd).advance(DT)
			w.bailiff.tick(DT)
			w.step(s.rules, DT)
			clock += DT
		t.check(w.check(s.rules) == Objective.Status.FAILED and clock < BailiffWish.SECONDS - 10.0
			and w.bailiff.ground_pos.distance_to(from) > BailiffWish.MIN_WALK * 0.5,
			"engaged, he walks to the door and the wish fails at %.1f s (seed %d)" % [clock, n])
		w.release()
		_done(s)


## A body is freed after its death fade, and an escaped one at once: both wishes hold their people through it.
static func _freed(t) -> void:
	var a := _world()
	var wa := _wish(a, "bailiff") as BailiffWish
	var gone := wa.bailiff
	wa.release()
	gone.free()  # (a dead soldier's body is freed after its fade, and stays in the roster until it is pruned)
	var again := _wish(a, "bailiff") as BailiffWish
	t.check(again != null and again.bailiff != gone and MissionDirector._alive(again.bailiff), "a freed soldier is never chosen as the bailiff")
	again.release()
	_done(a)

	var b := _world()
	var wb := _wish(b, "bailiff") as BailiffWish
	wb.engage()
	wb.bailiff.free()
	wb.step(b.rules, DT)
	t.check(wb.people().size() == 1 and _labels(wb) == ["HOME", Wish.WISHER_LABEL] and wb.hud_text(b.rules) != ""
		and wb.check(b.rules) == Objective.Status.DONE, "the engaged bailiff's body freed: nothing touched, granted")
	wb.release()
	_done(b)

	var c := _world()
	var wc := _wish(c, "neighbours") as NeighboursWish
	var first: Person = wc.neighbours[0]
	first.mind = Person.Mind.WHISPERED
	_arrive(first, wc.wisher.ground_pos)
	wc.step(c.rules, DT)
	(c.crowd as Crowd)._field.remove(first)
	(c.crowd as Crowd).escape(first)
	first.free()  # (Crowd.escape() only queues the free: a headless test frees the body itself)
	wc.step(c.rules, DT)
	var seen := 0
	for tag in wc.tags():
		seen += int(tag.label == NeighboursWish.LABEL)
	t.check(wc.believing.size() == 1 and wc.people().size() == 3 and seen == 2 and wc.check(c.rules) == Objective.Status.PENDING,
		"a neighbour who believed, then escaped: his body freed, nothing touched, the wish still open")
	for i in range(1, 3):
		var p: Person = wc.neighbours[i]
		p.mind = Person.Mind.WHISPERED
		_arrive(p, wc.wisher.ground_pos)
	wc.step(c.rules, DT)
	t.check(wc.check(c.rules) == Objective.Status.DONE, "the other two believe: granted, with the first's body gone")
	_done(c)

	var d := _world()
	var wd := _wish(d, "neighbours") as NeighboursWish
	var second: Person = wd.neighbours[1]
	(d.crowd as Crowd)._field.remove(second)
	(d.crowd as Crowd).escape(second)
	second.free()
	t.check(wd.check(d.rules) == Objective.Status.FAILED, "a neighbour gone before he believed, his body freed: failed")
	_done(d)
