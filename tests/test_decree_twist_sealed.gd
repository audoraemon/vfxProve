extends RefCounted
## The Sealed Verdict, level 5 twist -- The Ledger Remembers (Death and Decree ability levels, Task 21; DL14): everyone whose ground
## position lay inside the district at any step of the countdown (one frame counts) is listed; at the bell each listed one still alive
## dies by verdict wherever he is, indoors too; the faithful die as the base verdict kills them; one freed before the bell is skipped.
## The listing is quiet: no alarm, fright or on_cast. Levels 1-4 take only those inside at the bell.

const SV := preload("res://tests/test_decree_sealed.gd")
const C := SV.C
const DT := SV.DT


static func _cast(ctx: FxContext, level: int) -> SealedFx:
	return FxTimeline.cast(SealedFx, ctx, C, {"level": level}) as SealedFx


static func run(t) -> void:
	_walkers(t)
	_quiet(t)
	_sheltered(t)
	_teardown(t)
	_two_casts(t)


## Who walks through, lives away, sits indoors, is faithful or is freed; level 5 against level 4.
static func _scene(level: int, t) -> Dictionary:
	var made := SV._setup()
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var ctx: FxContext = made[5]
	SV._away(crowd)
	var r := {"made": made}
	var walker: Person = crowd.citizens[0]  # walks through at 5 s, 20 away at the bell
	var never: Person = crowd.citizens[1]  # never enters
	var indoor: Person = crowd.citizens[2]  # inside at 5 s, then goes indoors outside the circle
	var faithful: Person = crowd.citizens[3]  # inside at 8 s, leaves
	var freed: Person = crowd.citizens[4]  # inside at 5 s, then freed (gone) before the bell
	var blink: Person = crowd.citizens[5]  # inside for one frame only
	never.ground_pos = C + Vector2(0.0, 14.0)
	walker.ground_pos = C + Vector2(-20.0, 0.0)
	indoor.ground_pos = C + Vector2(-20.0, 3.0)
	faithful.ground_pos = C + Vector2(-20.0, 6.0)
	freed.ground_pos = C + Vector2(-20.0, 9.0)
	blink.ground_pos = C + Vector2(-20.0, 12.0)
	var fx := _cast(ctx, level)
	SV._run_to(fx, 4.95)
	walker.ground_pos = C + Vector2(2.0, 0.0)
	indoor.ground_pos = C + Vector2(0.0, 3.0)
	freed.ground_pos = C + Vector2(3.0, 3.0)
	SV._run_to(fx, 5.55)
	walker.ground_pos = C + Vector2(20.0, 0.0)
	SV._run_to(fx, 7.95)
	faithful.ground_pos = C + Vector2(-1.0, 1.0)
	SV._run_to(fx, 8.55)
	faithful.ground_pos = C + Vector2(0.0, -20.0)
	blink.ground_pos = C + Vector2(1.0, 1.0)
	fx._process(DT)
	blink.ground_pos = C + Vector2(-20.0, 12.0)
	# the indoor one goes in, out in the road beyond the circle
	indoor.ground_pos = C + Vector2(-20.0, 3.0)
	SV._indoors(field, indoor, C + Vector2(-20.0, 3.0), false)
	r.merge({"fx": fx, "walker": walker, "never": never, "indoor": indoor, "faithful": faithful, "freed": freed, "blink": blink, "ctx": ctx})
	return r


static func _walkers(t) -> void:
	for level in [5, 4]:
		var s := _scene(level, t)
		var made: Array = s.made
		var crowd: Crowd = made[0]
		var fx: SealedFx = s.fx
		var walker: Person = s.walker
		var never: Person = s.never
		var indoor: Person = s.indoor
		var faithful: Person = s.faithful
		var freed: Person = s.freed
		var blink: Person = s.blink
		# the "faithful" is a plain person here: the twist never asks, the base verdict kills every faithful as anyone
		var deaths: Array = []
		(made[3] as EnemyField).enemy_killed.connect(func(e: DummyEnemy, kind: StringName) -> void: deaths.append([e, kind]))
		freed.free()  # freed before the bell: nothing to kill, nothing to trip on
		SV._run_to(fx, 25.0)
		SV._run_to(fx, fx.lv_countdown - DT)
		t.check(fx.t < fx.lv_countdown and deaths.is_empty(), "level %d: nobody dies before the bell" % level)
		fx._process(DT * 1.5)
		var kinds_ok := true
		for d in deaths:
			kinds_ok = kinds_ok and d[1] == &"verdict"
		if level == 5:
			t.check(fx._twist and not walker.is_alive() and not faithful.is_alive() and not blink.is_alive() and not indoor.is_alive(),
				"level 5: one who walked through at 5 s (20 away at the bell), one indoors on the list, a faithful and a one-frame visitor die")
			t.check(never.is_alive() and kinds_ok and deaths.size() == 4 and fx.dead == 4,
				"one who never entered lives; every death is a verdict and the freed one is skipped (%d deaths)" % deaths.size())
		else:
			t.check(not fx._twist and walker.is_alive() and faithful.is_alive() and blink.is_alive() and indoor.is_alive() and never.is_alive()
				and deaths.is_empty(),
				"level %d: only those inside at the bell die; those who walked out live" % level)
		fx.end_now()
		fx.free()
		SV._done(made)


## The listing adds no alarm, danger or fright before the bell, at level 5 as at level 1.
static func _quiet(t) -> void:
	var s := _scene(5, t)
	var made: Array = s.made
	var crowd: Crowd = made[0]
	var fx: SealedFx = s.fx
	var alarm := crowd.alarm
	var minds := {}
	for p in crowd.citizens + crowd.soldiers:
		minds[p] = p.mind
	SV._run_to(fx, fx.lv_countdown - DT)
	var changed := 0
	for p in minds:
		if is_instance_valid(p) and p.mind != minds[p]:
			changed += 1
	t.check(fx._listed.size() >= 4 and is_equal_approx(crowd.alarm, alarm) and changed == 0 and crowd.threats.nearby(C, 30.0).is_empty(),
		"level 5 listing is quiet: no alarm, no change of mind, no threat (%d listed)" % fx._listed.size())
	fx.end_now()
	fx.free()
	SV._done(made)


static func _teardown(t) -> void:
	var s := _scene(5, t)
	var made: Array = s.made
	var fx: SealedFx = s.fx
	var walker: Person = s.walker
	fx.end_now()
	t.check(fx.finished and fx._listed.is_empty(), "end_now clears the list")
	for i in 400:
		fx._process(DT)
	t.check(walker.is_alive() and not fx.struck, "cut short, the verdict is never carried out")
	fx.free()
	t.check(not is_instance_valid(fx), "and the node is freed")
	SV._done(made)
	# positive control: the same scene left alone kills the walker
	var u := _scene(5, t)
	SV._run_to(u.fx, 31.0)
	t.check((u.walker as Person).is_alive() == false, "control: left alone, the level 5 walker dies")
	var f2: SealedFx = u.fx
	f2.free()
	SV._done(u.made)


## Two overlapping level-5 casts keep their own lists.
static func _two_casts(t) -> void:
	var made := SV._setup()
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	SV._away(crowd)
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	a.ground_pos = C + Vector2(1.0, 0.0)
	var f1 := _cast(ctx, 5)
	SV._run_to(f1, 2.0)
	a.ground_pos = C + Vector2(-20.0, 0.0)
	b.ground_pos = C + Vector2(1.0, 1.0)
	var f2 := _cast(ctx, 5)
	SV._run_to(f2, 2.0)
	b.ground_pos = C + Vector2(20.0, 20.0)
	t.check(f1._listed.has(a.get_instance_id()) and not f2._listed.has(a.get_instance_id()) and f2._listed.has(b.get_instance_id()),
		"each cast lists only what it saw")
	f1.end_now()
	t.check(f2._listed.has(b.get_instance_id()), "ending one leaves the other's list")
	f2.end_now()
	f1.free()
	f2.free()
	SV._done(made)


## Sheltering in a district house from 5 s to 20 s, then out of the circle before the bell: listed, dies. A house outside lists nobody.
static func _sheltered(t) -> void:
	for level in [5, 4]:
		var made := SV._setup()
		var crowd: Crowd = made[0]
		var env: EnvironmentField = made[1]
		var ctx: FxContext = made[5]
		SV._away(crowd)
		var inn: Person = crowd.citizens[0]
		var outer: Person = crowd.citizens[1]
		var h_in := env.add_structure(Rect2(C + Vector2(4.5, 2.5), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
		var h_out := env.add_structure(Rect2(C + Vector2(24.5, 2.5), Vector2(1.0, 1.0)), 30.0, Structure.Kind.HOUSE, &"house")
		for h in [h_in, h_out]:
			crowd.shelters.shelters[h] = {"inside": [], "coming": [], "clear": 0.0}
		var fx := _cast(ctx, level)
		SV._run_to(fx, 5.0)
		inn.ground_pos = h_in.center()
		crowd.shelters._enter(inn, h_in)
		(crowd.shelters.shelters[h_in].inside as Array).append(inn)
		outer.ground_pos = h_out.center()
		crowd.shelters._enter(outer, h_out)
		(crowd.shelters.shelters[h_out].inside as Array).append(outer)
		SV._run_to(fx, 5.5)
		if level == 5:
			t.check(fx._listed.has(inn.get_instance_id()) and not fx._listed.has(outer.get_instance_id()),
				"level 5: one indoors in a district house is listed; one in a house outside is not")
		# out of the house and the circle before the bell (a release, wherever it lands)
		SV._run_to(fx, 20.0)
		(crowd.shelters.shelters[h_in].inside as Array).erase(inn)
		inn.inside = false
		inn.visible = true
		inn.ground_pos = C + Vector2(-25.0, 0.0)
		# a listed one sheltering in a house OUTSIDE the district when the bell strikes
		if level == 5:
			t.check((crowd.shelters.shelters[h_out].inside as Array).has(outer), "setup: the outer one sits in the outside house")
			fx._listed[outer.get_instance_id()] = true  # (a person once in the district, now sheltering outside it)
		SV._run_to(fx, fx.lv_countdown - DT)
		fx._process(DT * 1.5)
		if level == 5:
			t.check(not outer.is_alive() and crowd.shelters.occupants(h_out) == 0 and crowd.shelters.occupants(h_in) == 0,
				"level 5: a listed one in a house outside is let out before he dies: no dead occupant stays inside")
			t.check(not inn.is_alive(), "level 5: the one once indoors dies at the bell wherever he is")
		else:
			t.check(inn.is_alive() and outer.is_alive(), "level 4: the one who left lives")
		fx.end_now()
		fx.free()
		SV._done(made)
