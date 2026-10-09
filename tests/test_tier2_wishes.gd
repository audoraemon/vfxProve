extends RefCounted
## v0.11 M3 Omen's two wishes (mission spec §5): the pool grows to twelve, the two new ones heard from Omen up (WishDef.min_tier,
## WishBook.pool_for()), so a Tier 1 night shuffles exactly M2's ten and its seeded draws are unchanged (controller ruling 3); the
## informer wish keeps off The Informer's night. Scare off the bully: granted by a fright, never the town's flight; failed by his
## death, his leaving, or a blow ("unharmed" is unhurt). Free the pressed man: engaged by a click or a cast, two soldiers march the son to the barracks' door; both
## killed or turned within 45 s grants it; the door, the clock or the son's death fails it; engagement judged first.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_pool(t)
	_draws(t)
	_bully(t)
	_bully_unharmed(t)
	_pressed(t)
	_pressed_lead(t)
	_pressed_ends(t)
	_pressed_orders(t)
	_pressed_freed(t)
	_nobody(t)


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
	var shelter := _wish(s, "bully", 9) as FrightWish
	shelter.target.mind = Person.Mind.SHELTER
	t.check(shelter.check(s.rules) == Objective.Status.DONE, "running for shelter is a fright too: granted")
	shelter.release()
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


## "Unharmed" is unhurt (v0.11 M3, review fix): a bully struck at all -- a blow that panics him as it lands, or one that does not -- fails
## the wish, judged before his mind; one frightened in a whole skin is granted.
static func _bully_unharmed(t) -> void:
	var s := _world()
	var w := _wish(s, "bully") as FrightWish
	w.target.hurt(0.25, null)
	t.check(w.target.health < Person.HEALTH_CITIZEN and w.target.is_alive() and w.check(s.rules) == Objective.Status.FAILED,
		"a bully hurt and alive fails it: 'unharmed' is unhurt")
	w.release()
	var x := _wish(s, "bully", 5) as FrightWish
	x.target.hurt(0.5, x.wisher)
	t.check(x.target.is_alive() and x.target.mind in FestivalDirector.BROKE_MINDS and x.check(s.rules) == Objective.Status.FAILED,
		"and one the blow frightened -- panicked as it landed -- fails it rather than grants it")
	x.release()
	var y := _wish(s, "bully", 7) as FrightWish
	y.target.panic(y.target.ground_pos + Vector2(1.0, 0.0), 1.0)
	t.check(y.target.health == Person.HEALTH_CITIZEN and y.check(s.rules) == Objective.Status.DONE, "frightened in a whole skin: granted")
	y.release()
	Kit.done(s)


## The man who reached the son is the one he follows, not the first of the two (v0.11 M3, review fix).
static func _pressed_lead(t) -> void:
	var s := _world()
	var w := _wish(s, "pressed") as PressedWish
	w.engage()
	Kit.arrive(w.soldier, w.child.ground_pos + Vector2(8.0, 0.0))
	Kit.arrive(w.mate, w.child.ground_pos)
	w.step(s.rules, RescueWish.RETARGET + DT)
	t.check(w.dragging and w.child.mind == Person.Mind.DUTY and w.child.goal().distance_to(w.mate.ground_pos) < 1.5,
		"the second man reached him: the son follows the second man, not the first")
	Kit.arrive(w.mate, w.child.ground_pos + Vector2(8.0, 0.0))
	Kit.arrive(w.soldier, w.child.ground_pos + Vector2(0.0, 6.0))
	w.step(s.rules, RescueWish.RETARGET + DT)
	t.check(w.child.goal().distance_to(w.mate.ground_pos) < 1.5, "and goes on following him, whoever stands nearer")
	(s.crowd as Crowd)._field.kill(w.mate, &"doom")
	w.step(s.rules, RescueWish.RETARGET + DT)
	t.check(w.child.goal().distance_to(w.soldier.ground_pos) < 1.5, "he falls: the son follows the one who is left")
	w.release()
	Kit.done(s)


## A choose() that fails takes nobody (v0.11 M3, review fix): `taken` stays as it was, no one is set, no signal stays connected; and
## release() lets the kill signal go.
static func _nobody(t) -> void:
	var a := _world()
	var crowd: Crowd = a.crowd
	var lay := Wish.lay(crowd, [])
	for p in lay.slice(1):
		p.profile.faith = CitizenProfile.Faith.FAITHFUL
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var taken := []
	var bully := _def("bully").instance() as FrightWish
	t.check(Wish.lay(crowd, []).size() == 1 and not bully.choose(crowd, a.town, r, taken) and taken.is_empty()
		and bully.wisher == null and bully.target == null, "one lay person: no bully, and nobody taken")
	Kit.done(a)
	var b := _world()
	crowd = b.crowd
	var free: Array[Person] = []
	for p in crowd.soldiers:
		if MissionDirector._alive(p) and not p.inside and p.corps == Person.Corps.NONE:
			free.append(p)
	for p in free.slice(1):
		p.corps = Person.Corps.ESCORT
	taken = []
	var one := _def("pressed").instance() as PressedWish
	t.check(free.size() >= 2 and not one.choose(crowd, b.town, _seeded(3), taken) and taken.is_empty() and one.wisher == null
		and one.child == null and one.soldier == null and one.mate == null and not crowd._field.enemy_killed.is_connected(one._on_killed),
		"one free soldier, not two: no wish, nobody taken, no signal left connected")
	free[0].corps = Person.Corps.ESCORT
	var none := _def("pressed").instance() as PressedWish
	t.check(not none.choose(crowd, b.town, _seeded(3), taken) and taken.is_empty() and none.soldier == null,
		"no free soldier: no wish, nobody taken")
	for p in crowd.soldiers:
		p.corps = Person.Corps.NONE
	for p in Wish.lay(crowd, []):
		p.ground_pos = PressedWish.barracks_door(crowd)
	var near := _def("pressed").instance() as PressedWish
	t.check(not near.choose(crowd, b.town, _seeded(3), taken) and taken.is_empty() and near.child == null,
		"every lay person at the barracks' door: no son far enough, no wish, nobody taken")
	var w := _wish(b, "pressed") as PressedWish
	t.check(w == null, "and the same town still has no son when asked afresh")
	Kit.done(b)
	var c := _world()
	var ok := _wish(c, "pressed") as PressedWish
	var field: EnemyField = c.field
	t.check(ok != null and field.enemy_killed.is_connected(ok._on_killed), "a wish with its people listens for the men's fall")
	ok.release()
	t.check(not field.enemy_killed.is_connected(ok._on_killed), "release() lets the signal go")
	Kit.done(c)


static func _seeded(n: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = n
	return r
