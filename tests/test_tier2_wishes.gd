extends RefCounted
## v0.11 M3 Omen's two wishes (mission spec §5): the pool grows to twelve, the two new ones heard from Omen up (WishDef.min_tier,
## WishBook.pool_for()), so a Tier 1 night shuffles exactly M2's ten and its seeded draws are unchanged (controller ruling 3); the
## informer wish keeps off The Informer's night. Scare off the bully: granted by a fright, never the town's flight; failed by his
## death or his leaving. Free the pressed man: engaged by a click or a cast, two soldiers march the son to the barracks' door; both
## killed or turned within 45 s grants it; the door, the clock or the son's death fails it; engagement judged first.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_pool(t)
	_draws(t)
	_bully(t)
	_pressed(t)
	_pressed_ends(t)
	_pressed_orders(t)
	_pressed_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.bell_ringers(), MissionDirector.new())


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


static func _ids(list: Array) -> Array:
	var out := []
	for x in list:
		out.append(x.id if x is WishDef else (x as Wish).def.id)
	return out


static func _labels(w: Wish) -> Array:
	var out := []
	for m in w.tags():
		out.append(m.label)
	return out


## `p` leaves the town: his body freed at once, with no death (v0.11 M3 tests).
static func _vanish(s: Dictionary, p: Person) -> void:
	var crowd: Crowd = s.crowd
	crowd._field.remove(p)
	crowd.citizens.erase(p)
	p.free()


static func _pool(t) -> void:
	var all := _ids(WishBook.pool())
	t.check(all.size() == 12 and all.slice(10) == ["bully", "pressed"], "the pool: M2's ten, then Omen's two (%s)" % [all])
	var bully := _def("bully")
	var pressed := _def("pressed")
	t.check(bully.text == "Scare off the bully, unharmed" and bully.kind == "fright" and bully.reward == 10 and bully.min_tier == 2
		and Array(bully.clashes) == ["unaware_town"] and pressed.text == "Free the pressed man" and pressed.kind == "rescue"
		and pressed.reward == 15 and pressed.min_tier == 2 and Array(pressed.clashes) == ["unaware_town"],
		"their words, kinds and rewards; heard from Omen up, never in a sleeping town")
	t.check(Array(_def("informer").clashes) == ["hunts_informer"] and _def("sign").min_tier == 1,
		"the informer wish keeps off The Informer's night; the older wishes are heard from Whisper")
	t.check(_ids(WishBook.pool_for(1)) == all.slice(0, 10) and _ids(WishBook.pool_for(2)) == all,
		"a Tier 1 night draws from M2's ten, in M2's order; Omen's from all twelve")


static func _draws(t) -> void:
	var s := Kit.world(TierBook.board("warning"), MissionDirector.new())
	var ten: Array[WishDef] = []
	ten.assign(WishBook.pool().slice(0, 10))
	var same := true
	for n in 20:
		var a := Descent.new().setup(TierBook.board("warning"), Descent.seed_for(n, "warning"))
		a.hear(s.crowd, s.town)
		var r := RandomNumberGenerator.new()
		r.seed = Descent.seed_for(n, "warning")
		var b := WishBook.draw(ten, TierBook.wishes(1), TierBook.board("warning").mission_tags, s.crowd, s.town, r)
		same = same and _ids(a.wishes) == _ids(b)
		for w in a.wishes:
			w.release()
		for w in b:
			w.release()
	t.check(same, "twenty Tier 1 nights hear exactly what M2's ten gave them (controller ruling 3)")
	Kit.done(s)
	var o := _world()
	var heard := {}
	for n in 40:
		var d := Descent.new().setup(TierBook.board("miras_house"), Descent.seed_for(n, "miras_house"))
		d.hear(o.crowd, o.town)
		for w in d.wishes:
			heard[w.def.id] = true
			w.release()
	t.check(heard.has("bully") and heard.has("pressed"), "Omen's nights can hear both new wishes (%s)" % [heard.keys()])
	Kit.done(o)


static func _bully(t) -> void:
	var s := _world()
	var w := _wish(s, "bully") as FrightWish
	t.check(w != null and w.target != w.wisher and not w.target.soldier and w.people().has(w.target)
		and w.check(s.rules) == Objective.Status.PENDING and _labels(w) == [FrightWish.LABEL, Wish.WISHER_LABEL],
		"a lay bully, tagged BULLY; open (%s)" % [_labels(w)])
	var tags := w.tags()
	t.check(tags[0].edge and tags[0].color == Wish.COLOR, "the bully's tag is soft blue and pointed at from the edge: he walks the town")
	w.target.flee()
	t.check(w.check(s.rules) == Objective.Status.PENDING, "the town's own flight is not a fright")
	w.target.mind = Person.Mind.CALM
	w.target.panic(w.target.ground_pos + Vector2(1.0, 0.0), 1.0)
	t.check(w.check(s.rules) == Objective.Status.DONE, "frightened -- panicking, or running for shelter -- he is scared off: granted")
	w.release()
	var x := _wish(s, "bully", 5) as FrightWish
	(s.crowd as Crowd)._field.kill(x.target, &"doom")
	t.check(x.check(s.rules) == Objective.Status.FAILED, "dead first: failed")
	x.release()
	var y := _wish(s, "bully", 7) as FrightWish
	_vanish(s, y.target)
	t.check(y.check(s.rules) == Objective.Status.FAILED, "gone from the town (his body freed): failed, and no error")
	y.release()
	Kit.done(s)


static func _pressed(t) -> void:
	var s := _world()
	var w := _wish(s, "pressed") as PressedWish
	var door := PressedWish.barracks_door(s.crowd)
	t.check(w != null and w.child.profile.family == w.wisher.profile.family and w.child != w.wisher
		and w.child.ground_pos.distance_to(door) >= PressedWish.MIN_FROM - 0.01
		and BailiffWish.route_length((s.crowd as Crowd)._grid, w.child.ground_pos, door) <= PressedWish.MAX_ROUTE
		and w.soldier.soldier and w.mate.soldier and w.soldier != w.mate and w.people().size() == 4,
		"a son of the wisher's household at least 15 from the barracks' door with at most 40 of street, and two free soldiers")
	t.check(w.timed() and w.waiting() and w.check(s.rules) == Objective.Status.PENDING
		and _labels(w) == ["PRESSED MAN", "PRESS-GANG", "PRESS-GANG", Wish.WISHER_LABEL], "it waits, unengaged; its tags (%s)" % [_labels(w)])
	var waiting_tags := w.tags()
	t.check(waiting_tags[0].edge and not waiting_tags[1].edge and not waiting_tags[2].edge and waiting_tags[0].color == Wish.COLOR
		and waiting_tags[1].color == Wish.COLOR, "waiting, the son is pointed at from the edge; the men stand at their posts")
	w.on_cast("doom", Vector2(100.0, 100.0))
	t.check(not w.engaged, "a cast far off does not engage it")
	w.on_cast("doom", w.mate.ground_pos)
	t.check(w.engaged and w.soldier.mind == Person.Mind.DUTY and w.mate.mind == Person.Mind.DUTY
		and w.soldier.goal().distance_to(w.child.ground_pos) < 1.5 and w.hud_text(s.rules).ends_with(UiTheme.clock(RescueWish.SECONDS)),
		"a cast by a press-ganger engages it: both walk to the son, and the clock shows")
	var moving_tags := w.tags()
	t.check(moving_tags[0].edge and moving_tags[1].edge and moving_tags[2].edge, "engaged, the son and both men are pointed at from the edge")
	Kit.arrive(w.soldier, w.child.ground_pos)
	w.step(s.rules, RescueWish.RETARGET + DT)
	t.check(w.dragging and w.soldier.goal().distance_to(door) < 1.5 and w.mate.goal().distance_to(door) < 1.5
		and w.child.mind == Person.Mind.DUTY, "one has him: they march him to the barracks' door")
	(s.crowd as Crowd)._field.kill(w.soldier, &"doom")
	w.mate.mind = Person.Mind.CONFUSED
	t.check(w.check(s.rules) == Objective.Status.DONE, "one killed, the other turned (RescueWish.TURNED): granted")
	w.release()
	Kit.done(s)


static func _pressed_ends(t) -> void:
	var a := _world()
	var w := _wish(a, "pressed") as PressedWish
	w.engage()
	w.dragging = true
	Kit.arrive(w.child, PressedWish.barracks_door(a.crowd))
	t.check(w.check(a.rules) == Objective.Status.FAILED, "the son at the barracks' door: failed")
	w.release()
	var x := _wish(a, "pressed", 5) as PressedWish
	x.engage()
	x.step(a.rules, RescueWish.SECONDS + DT)
	t.check(x.check(a.rules) == Objective.Status.FAILED, "45 s gone: failed")
	x.release()
	Kit.done(a)
	var b := _world()
	var god := _wish(b, "pressed") as PressedWish
	(b.rules as Rules).cast(0, Vector2(100.0, 100.0))
	(b.field as EnemyField).kill(god.soldier, &"doom")
	t.check(god.check(b.rules) == Objective.Status.PENDING and god.engaged and god.mate.mind == Person.Mind.DUTY,
		"a man felled by the god's own cast before it was engaged engages it: the other sets out")
	god.release()
	var other := _wish(b, "pressed", 5) as PressedWish
	(b.field as EnemyField).kill(other.mate, &"fire")
	t.check(other.check(b.rules) == Objective.Status.FAILED, "felled by another hand before it was engaged: failed")
	other.release()
	Kit.done(b)


## A town order undone, a man turned left be, and the last turned (v0.11 M3).
static func _pressed_orders(t) -> void:
	var s := _world()
	var w := _wish(s, "pressed") as PressedWish
	w.engage()
	w.soldier.mind = Person.Mind.RALLY
	w.mate.mind = Person.Mind.PANIC
	w.step(s.rules, RescueWish.RETARGET + DT)
	t.check(w.soldier.mind == Person.Mind.DUTY and w.mate.mind == Person.Mind.PANIC and w.check(s.rules) == Objective.Status.PENDING,
		"a town order taking a man off the errand sends him back on it; a man the god has turned is left be, and one still marches")
	w.soldier.mind = Person.Mind.WHISPERED
	t.check(w.check(s.rules) == Objective.Status.DONE, "the last turned too: granted")
	w.release()
	var x := _wish(s, "pressed", 5) as PressedWish
	x.engage()
	x.mate.mind = Person.Mind.CALM
	t.check(x.check(s.rules) == Objective.Status.PENDING, "a man who never set out and is calm again is not turned")
	x.release()
	Kit.done(s)


## Bodies freed -- a man or the son leaving the town -- are guarded (v0.11 M3, the freed-body rules).
static func _pressed_freed(t) -> void:
	var s := _world()
	var a := _wish(s, "pressed") as PressedWish
	_vanish(s, a.mate)
	t.check(a.people().size() == 3 and a.check(s.rules) == Objective.Status.FAILED,
		"a press-ganger gone from the town before it was engaged, with no god's cast on him: failed, and no error")
	a.release()
	var b := _wish(s, "pressed", 5) as PressedWish
	b.engage()
	_vanish(s, b.mate)
	b.step(s.rules, RescueWish.RETARGET + DT)
	t.check(b.check(s.rules) == Objective.Status.PENDING and b.people().size() == 3
		and _labels(b) == ["PRESSED MAN", "PRESS-GANG", Wish.WISHER_LABEL], "engaged, one man gone: the other marches on (%s)" % [_labels(b)])
	_vanish(s, b.soldier)
	t.check(b.check(s.rules) == Objective.Status.DONE, "and both gone: granted")
	b.release()
	var c := _wish(s, "pressed", 7) as PressedWish
	c.engage()
	_vanish(s, c.child)
	c.step(s.rules, RescueWish.RETARGET + DT)
	t.check(c.check(s.rules) == Objective.Status.FAILED and c.people().size() == 3, "the son gone: failed, and no error")
	c.release()
	Kit.done(s)
