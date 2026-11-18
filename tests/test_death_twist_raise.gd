extends RefCounted
## Raise the Dead level 5, Body and Soul (Death and Decree ability levels, Task 3): one cast gives both halves for the ring's own
## bodies, once for each. ZOMBIE: a ring zombie's end (cut down, or ZOMBIE_LIFE) raises its soul as a spirit of this cast if its remain
## had a soul; a soulless body and a chain riser give none. SPIRIT: a ring spirit's fade raises its body as a zombie, never a second
## spirit. Two level-5 casts keep separate counts. Levels 1-4 do none of it; a cast freed early leaves no visitor behind.

const RD := preload("res://tests/test_raise_dead.gd")


static func run(t) -> void:
	var made := RD._setup()
	_zombie_souls(t, made)
	_soulless_and_cut(t, made)
	_riser(t, made)
	_spirit_bodies(t, made)
	_spirit_zombie_cut(t, made)
	_two_casts(t, made)
	_level_4(t, made)
	_teardown(t, made)
	RD._done(made)


## `n` bodies laid close together at `at`; the remains, oldest first.
static func _bodies(made: Array, at: Vector2, first: int, n: int) -> Array[Remains.Remain]:
	var out: Array[Remains.Remain] = []
	for k in n:
		out.append(RD._body(made, first + k, at + Vector2(0.4 * float(k), 0.0)))
	return out


static func _cast(made: Array, at: Vector2, mode: String, level: int) -> RaiseTheDeadFx:
	return FxTimeline.cast(RaiseTheDeadFx, made[5], at, {"mode": mode, "level": level}) as RaiseTheDeadFx


static func _cut(fx: RaiseTheDeadFx, a: Animal) -> void:
	while a.is_alive():
		a.hurt(1.0)
	fx.visitors._fell(a)


static func _count(fx: RaiseTheDeadFx, breed: int) -> int:
	var n := 0
	for a in fx.visitors.living():
		if a.breed == breed:
			n += 1
	return n


## ZOMBIE, level 5, 3 bodies with souls: when their time ends each gives a spirit (3), the zombies are gone.
static func _zombie_souls(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, at, 0, 3)
	var fx := _cast(made, at, "zombie", 5)
	t.check(is_equal_approx(fx.duration, 38.0 + 24.0 + RaiseTheDeadFx.FADE), "level 5 lasts both halves (%.1f)" % fx.duration)
	RD._run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	t.check(_count(fx, Animal.Breed.ZOMBIE) == 3 and fx.spirits.is_empty(), "three zombies stand, no spirit yet")
	RD._run(fx, fx.lv_zombie_life - fx.t - 0.1)
	t.check(fx.spirits.is_empty() and _count(fx, Animal.Breed.ZOMBIE) == 3, "just before ZOMBIE_LIFE nothing has risen")
	RD._run(fx, 0.3)
	t.check(_count(fx, Animal.Breed.ZOMBIE) == 0 and fx.spirits.size() == 3 and _count(fx, Animal.Breed.SPIRIT) == 3,
		"at ZOMBIE_LIFE the zombies fall and 3 spirits rise (%d)" % fx.spirits.size())
	var ok := true
	for sp in fx.spirits:
		ok = ok and is_instance_valid(sp)
	t.check(ok, "the spirits stand")
	RD._run(fx, fx.lv_spirit_life + 0.2)
	t.check(fx.spirits.is_empty() and fx.visitors.living().is_empty(), "the spirits thin away at SPIRIT_LIFE")
	fx.end_now()


## A soulless body gives none; a zombie cut down early gives its soul at once.
static func _soulless_and_cut(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	var rs := _bodies(made, at, 3, 3)
	rs[2].born -= Remains.SOUL + 1.0  # the third has lost its soul
	var fx := _cast(made, at, "zombie", 5)
	RD._run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	var ups := fx.visitors.living()
	t.check(ups.size() == 3, "three bodies rose (soul gone from one)")
	var first: Animal = ups[0]
	for a in ups:  # the ring is oldest first: pick the zombie of a body that kept its soul
		if a.ground_pos.distance_to(rs[0].pos) < 0.2:
			first = a
	_cut(fx, first)
	t.check(fx.spirits.size() == 1 and is_instance_valid(fx.spirits[0]), "a zombie cut down early lets its soul rise at once")
	RD._run(fx, fx.lv_zombie_life - fx.t + 0.3)
	# one cut early (its spirit has thinned away by now), one soul at the end, one soulless: exactly one spirit up
	t.check(fx.spirits.size() == 1 and _count(fx, Animal.Breed.ZOMBIE) == 0, "the soulless body gave none (%d up)" % fx.spirits.size())
	fx.end_now()
	# Only soulless bodies: no spirit at all.
	RD._clear_all(made)
	var at2 := RD._empty(made)
	var rs2 := _bodies(made, at2, 6, 2)
	for r in rs2:
		r.born -= Remains.SOUL + 1.0
	var fx2 := _cast(made, at2, "zombie", 5)
	RD._run(fx2, fx2.lv_zombie_life + 0.5)
	t.check(fx2.spirits.is_empty() and fx2.visitors.living().is_empty(), "bodies with no soul give no spirit")
	fx2.end_now()


## A chain riser (a zombie's own kill that got up) gives no spirit; a ring body's zombie does.
static func _riser(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	RD._body(made, 8, at)
	var fx := _cast(made, at, "zombie", 5)
	RD._run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	var z: Animal = fx.visitors.living()[0]
	var v: Person = crowd.citizens[9]
	v.ground_pos = at + Vector2(2.0, 0.0)
	field.kill(v, &"frenzy")
	fx.visitors.bitten.emit(z, v, false)
	t.check(fx.raised == 2 and fx.visitors.living().size() == 2, "its kill got up as a riser")
	var riser: Animal = null
	for a in fx.visitors.living():
		if a != z:
			riser = a
	_cut(fx, riser)
	t.check(fx.spirits.is_empty(), "a chain riser cut down gives no spirit")
	var riser2: Person = crowd.citizens[10]
	riser2.ground_pos = at + Vector2(0.0, 2.0)
	field.kill(riser2, &"frenzy")
	fx.visitors.bitten.emit(z, riser2, false)
	RD._run(fx, fx.lv_zombie_life - fx.t + 0.3)
	t.check(fx.spirits.size() == 1, "at the end only the ring's own zombie gave a spirit (%d)" % fx.spirits.size())
	fx.end_now()


## SPIRIT, level 5: each ring spirit's fade raises its own body once; no second spirit.
static func _spirit_bodies(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	var rs := _bodies(made, at, 11, 2)
	var fx := _cast(made, at, "spirit", 5)
	RD._run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	t.check(fx.spirits.size() == 2 and _count(fx, Animal.Breed.ZOMBIE) == 0, "two spirits, no zombie yet")
	RD._run(fx, fx.lv_spirit_life - fx.t - 0.1)
	t.check(_count(fx, Animal.Breed.ZOMBIE) == 0, "just before SPIRIT_LIFE no body has risen")
	RD._run(fx, 0.3)
	var zs := fx.visitors.living()
	var near_body := 0
	for a in zs:
		for r in rs:
			if a.ground_pos.distance_to(r.pos) < 0.6:
				near_body += 1
				break
	t.check(zs.size() == 2 and _count(fx, Animal.Breed.ZOMBIE) == 2 and _count(fx, Animal.Breed.SPIRIT) == 0 and fx.spirits.is_empty(),
		"at SPIRIT_LIFE each spirit fades and its body rises as a zombie, no spirit left (%d)" % zs.size())
	t.check(near_body == 2 and fx.raised == 2, "the zombies stand where the bodies lay (%d near, %d raised)" % [near_body, fx.raised])
	RD._run(fx, fx.lv_zombie_life + 0.3)
	t.check(fx.visitors.living().is_empty() and fx.spirits.is_empty(), "the zombies fall at ZOMBIE_LIFE and bring back no spirit")
	fx.end_now()


## A zombie born of a spirit, cut down, raises no spirit; its kill shares the cast's CHAIN.
static func _spirit_zombie_cut(t, made: Array) -> void:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	_bodies(made, at, 13, 1)
	var fx := _cast(made, at, "spirit", 5)
	RD._run(fx, fx.lv_spirit_life + 0.3)
	var z: Animal = fx.visitors.living()[0]
	var v: Person = crowd.citizens[14]
	v.ground_pos = at + Vector2(2.0, 0.0)
	field.kill(v, &"frenzy")
	fx.visitors.bitten.emit(z, v, false)
	t.check(fx.raised == 2 and fx.visitors.living().size() == 2, "its kill gets up through the cast's chain")
	for a in fx.visitors.living():
		_cut(fx, a)
	t.check(fx.spirits.is_empty() and fx.visitors.living().is_empty() and _count(fx, Animal.Breed.SPIRIT) == 0,
		"a zombie of the second half, cut down, brings back no spirit")
	fx.end_now()


## Two level-5 casts on separate rings keep separate counts; one ending leaves the other whole.
static func _two_casts(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, at, 15, 2)
	var at2 := RD._empty(made, at)
	t.check(at2 != Vector2.INF and at2.distance_to(at) > 8.0, "a second ring far from the first")
	_bodies(made, at2, 17, 1)
	var a := _cast(made, at, "zombie", 5)
	var b := _cast(made, at2, "zombie", 5)
	RD._run(a, RaiseTheDeadFx.T_RISE + 0.1)
	RD._run(b, RaiseTheDeadFx.T_RISE + 0.1)
	t.check(_count(a, Animal.Breed.ZOMBIE) == 2 and _count(b, Animal.Breed.ZOMBIE) == 1, "two zombies for A, one for B")
	for step in roundi((a.lv_zombie_life + 0.3) / RD.DT):
		if not a.finished:
			a._process(RD.DT)
		if not b.finished:
			b._process(RD.DT)
	t.check(a.spirits.size() == 2 and b.spirits.size() == 1, "separate counts: A %d spirits, B %d" % [a.spirits.size(), b.spirits.size()])
	a.end_now()
	t.check(a.visitors.living().is_empty() and b.spirits.size() == 1 and is_instance_valid(b.spirits[0]) and b.visitors.living().size() == 1,
		"one cast ending leaves the other's spirit up")
	b.end_now()
	# And two SPIRIT casts.
	RD._clear_all(made)
	var s1 := RD._empty(made)
	_bodies(made, s1, 18, 2)
	var s2 := RD._empty(made, s1)
	_bodies(made, s2, 20, 1)
	var c := _cast(made, s1, "spirit", 5)
	var d := _cast(made, s2, "spirit", 5)
	for step in roundi((c.lv_spirit_life + 0.5) / RD.DT):
		if not c.finished:
			c._process(RD.DT)
		if not d.finished:
			d._process(RD.DT)
	t.check(c.raised == 2 and d.raised == 1 and _count(c, Animal.Breed.ZOMBIE) == 2 and _count(d, Animal.Breed.ZOMBIE) == 1,
		"two SPIRIT casts: C raised %d, D raised %d" % [c.raised, d.raised])
	c.end_now()
	d.end_now()


## Level 4 does neither half, runs the same time as before and draws the same random numbers as level 5.
static func _level_4(t, made: Array) -> void:
	RD._clear_all(made)
	var ctx: FxContext = made[5]
	var at := RD._empty(made)
	_bodies(made, at, 21, 2)
	ctx.rng.seed = 7
	var fx := _cast(made, at, "zombie", 4)
	var state4 := ctx.rng.state
	t.check(is_equal_approx(fx.duration, fx.lv_zombie_life + RaiseTheDeadFx.FADE) and is_equal_approx(fx.lv_zombie_life, 36.0),
		"level 4 keeps its own time (%.1f)" % fx.duration)
	RD._run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	_cut(fx, fx.visitors.living()[0])
	t.check(fx.spirits.is_empty(), "level 4: a zombie cut down gives no spirit")
	RD._run(fx, fx.lv_zombie_life + 0.3)
	t.check(fx.spirits.is_empty() and fx.visitors.living().is_empty(), "level 4: no spirit at the end either")
	fx.end_now()
	RD._clear_all(made)
	var at2 := RD._empty(made)
	_bodies(made, at2, 23, 2)
	var fs := _cast(made, at2, "spirit", 4)
	RD._run(fs, fs.lv_spirit_life + 0.5)
	t.check(fs.visitors.living().is_empty() and fs.raised == 0, "level 4: a spirit's fade raises no body")
	fs.end_now()
	RD._clear_all(made)
	var at3 := RD._empty(made)
	_bodies(made, at3, 25, 2)
	ctx.rng.seed = 7
	var f5 := _cast(made, at3, "zombie", 5)
	t.check(ctx.rng.state == state4, "level 5 draws the same random numbers as level 4 at the cast")
	f5.end_now()


## Freed early: the visitors and the spirits are gone and nothing is left to rise.
static func _teardown(t, made: Array) -> void:
	RD._clear_all(made)
	var at := RD._empty(made)
	_bodies(made, at, 27, 2)
	var fx := _cast(made, at, "zombie", 5)
	RD._run(fx, RaiseTheDeadFx.T_RISE + 0.1)
	_cut(fx, fx.visitors.living()[0])
	var sp: Animal = fx.spirits[0]
	var z: Animal = fx.visitors.living()[0]
	fx.end_now()
	t.check(fx.visitors.living().is_empty() and not is_instance_valid(sp) and not is_instance_valid(z), "end_now leaves no visitor or spirit")
	for i in 3:
		fx._process(RD.DT)
	t.check(fx.visitors.living().is_empty(), "nothing rises after the end")
	# Freed without _finish.
	RD._clear_all(made)
	var at2 := RD._empty(made)
	_bodies(made, at2, 29, 2)
	var fy := _cast(made, at2, "zombie", 5)
	RD._run(fy, RaiseTheDeadFx.T_RISE + 0.1)
	_cut(fy, fy.visitors.living()[0])
	var pack := fy.visitors
	fy._exit_tree()
	t.check(pack.living().is_empty() and fy.spirits.is_empty(), "_exit_tree leaves no visitor or spirit")
	# SPIRIT freed early: no zombie rises from the fading.
	RD._clear_all(made)
	var at3 := RD._empty(made)
	_bodies(made, at3, 31, 2)
	var fz := _cast(made, at3, "spirit", 5)
	RD._run(fz, RaiseTheDeadFx.T_RISE + 0.1)
	var pack3 := fz.visitors
	var sp3: Animal = fz.spirits[0]
	fz.end_now()
	t.check(pack3.living().is_empty() and not is_instance_valid(sp3), "a SPIRIT cast ended early leaves no spirit and raises no body")
