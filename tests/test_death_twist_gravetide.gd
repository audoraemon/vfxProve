extends RefCounted
## Grave Tide, level 5 twist -- Scattered Bones (Death and Decree ability levels, Task 11; DL11, R44): when the giant falls (cut
## down, or its GIANT_LIFE over) up to 18 skeleton warriors rise where it fell, as many as LIVING_CAP leaves room for (20 in the
## pack -> 18; 50 -> 10; 60 -> 0), each for 20.0 s. Their kills raise nothing. Level 4 raises none.

const RD := preload("res://tests/test_raise_dead.gd")
const GT := preload("res://tests/test_gravetide.gd")


static func _cast(made: Array, at: Vector2, level: int) -> GraveTideFx:
	return FxTimeline.cast(GraveTideFx, made[5], at, {"level": level}) as GraveTideFx


static func run(t) -> void:
	var made := RD._setup()
	_fall_count(t, made)
	_leave(t, made)
	_life_end(t, made)
	_no_rise(t, made)
	_level_four(t, made)
	_teardown(t, made)
	_two_casts(t, made)
	RD._done(made)


## A tide to just past its last grave's burst and the giant's landing (the horde taken off as it rises), then `fill` ghouls added to the pack; soldiers indoors.
static func _stand(made: Array, level: int, fill: int) -> Array:
	RD._clear_all(made)
	var was := GT._soldiers_in(made)
	var fx := _cast(made, RD._empty(made), level)
	GT._run_bare(fx, GraveTideFx.T_RISE + 0.08 * float(GraveTideFx.GRAVES_MOST) + 0.3)  # every grave burst, the giant landed
	for i in fill:
		DeathParts.ghoul(fx.visitors, fx.giant.ground_pos + Vector2(6.0 + 0.1 * float(i), 0.0))
	return [fx, was]


## The giant cut down as a guard's last blow does it.
static func _cut(fx: GraveTideFx) -> void:
	var g := fx.giant
	var where := g.ground_pos
	g.hurt(float(fx.lv_giant_blows))
	fx.visitors._rules.erase(g)
	fx.visitors.cut_down.emit(g, where)
	if is_instance_valid(g):
		g.free()


static func _skeletons(fx: GraveTideFx) -> Array:
	return GT._of(fx, Animal.Breed.SKELETON)


static func _fall_count(t, made: Array) -> void:
	for pair in [[20, 18], [50, 10], [60, 0]]:
		var s := _stand(made, 5, pair[0])
		var fx: GraveTideFx = s[0]
		var before := fx.undead_up()
		t.check(fx._twist and fx.giant != null and before == pair[0] and _skeletons(fx).is_empty(),
			"level 5: %d in the pack and the giant up, no skeleton yet (%d)" % [pair[0], before])
		_cut(fx)
		var n := _skeletons(fx).size()
		t.check(n == pair[1] and fx.undead_up() == pair[0] + pair[1] and fx.undead_up() <= GraveTideFx.LIVING_CAP,
			"the giant cut down with %d in the pack: %d skeletons (%d), the pack %d of %d" % [pair[0], pair[1], n, fx.undead_up(), GraveTideFx.LIVING_CAP])
		fx.end_now()
		GT._soldiers_back(s[1])


## They stand 20.0 s from the fall and the tide stands with them; then they are gone and the tide is over.
static func _leave(t, made: Array) -> void:
	var s := _stand(made, 5, 0)
	var fx: GraveTideFx = s[0]
	_cut(fx)
	var fell := fx.t
	t.check(_skeletons(fx).size() == 18, "(eighteen up at the fall)")
	RD._run(fx, 19.8)
	var up := _skeletons(fx).size()
	t.check(up > 0 and not fx.finished, "19.8 s on they still stand (%d) and the tide with them" % up)
	RD._run(fx, fell + GraveTideFx.SCATTER_LIFE + 0.1 - fx.t)
	t.check(_skeletons(fx).is_empty() and fx.visitors.living().is_empty(), "at 20.0 s they are gone")
	RD._run(fx, GraveTideFx.LIFE + GraveTideFx.FADE + 0.2 - fx.t)  # the horde's own LIFE still bounds the tide
	t.check(fx.finished, "and the tide ends")
	GT._soldiers_back(s[1])


## The giant's own life over (no one cut it down): the skeletons rise then, the horde and giant are ash.
static func _life_end(t, made: Array) -> void:
	var s := _stand(made, 5, 3)
	var fx: GraveTideFx = s[0]
	var end := fx.landed_at + fx.lv_giant_life
	GT._run_bare(fx, end - 0.3 - fx.t)
	var held := GT._horde(fx).size()
	GT._run_bare(fx, 0.1)
	t.check(fx.giant != null and _skeletons(fx).is_empty() and held == 0, "level 5: the giant stands to the end of its life")
	var g := fx.giant
	RD._run(fx, 0.35)
	var n := _skeletons(fx).size()
	t.check(fx.giant == null and n == 18 and not fx.finished and (g == null or not is_instance_valid(g) or g.is_queued_for_deletion()),
		"its life over the giant is gone and %d skeletons stand" % n)
	RD._run(fx, GraveTideFx.SCATTER_LIFE + GraveTideFx.FADE + 0.4)
	t.check(_skeletons(fx).is_empty() and fx.finished, "they leave 20.0 s on and the tide ends")
	GT._soldiers_back(s[1])


## A skeleton's kill raises nothing (a zombie of the tide's own would show in the pack).
static func _no_rise(t, made: Array) -> void:
	var s := _stand(made, 5, 0)
	var fx: GraveTideFx = s[0]
	_cut(fx)
	var raised := fx.raised
	var a: Animal = _skeletons(fx)[0]
	var victim := GT._put(made, 0, a.ground_pos)
	victim.inside = false
	var rem: Remains = (made[0] as Crowd).remains
	GT._soldiers_back(s[1])
	RD._run(fx, 3.0, [victim])
	t.check(not victim.is_alive() and fx.raised == raised and GT._of(fx, Animal.Breed.ZOMBIE).is_empty(),
		"a skeleton's kill raises none (raised %d -> %d, alive %s)" % [raised, fx.raised, victim.is_alive()])
	fx.end_now()


static func _level_four(t, made: Array) -> void:
	var s := _stand(made, 4, 20)
	var fx: GraveTideFx = s[0]
	_cut(fx)
	t.check(not fx._twist and _skeletons(fx).is_empty() and fx.undead_up() == 20, "level 4: the giant falls and no skeleton rises")
	RD._run(fx, GraveTideFx.FADE + 1.0)
	fx.end_now()
	GT._soldiers_back(s[1])
	# (level 1 the same)
	var s1 := _stand(made, 1, 0)
	var f1: GraveTideFx = s1[0]
	_cut(f1)
	t.check(_skeletons(f1).is_empty(), "level 1: none")
	f1.end_now()
	GT._soldiers_back(s1[1])


## end_now() and a freed tree both undo the skeletons; each with a level-5 positive control that they were out.
static func _teardown(t, made: Array) -> void:
	var s := _stand(made, 5, 0)
	var fx: GraveTideFx = s[0]
	_cut(fx)
	var up := _skeletons(fx)
	var nodes := up.duplicate()
	var pack := fx.visitors
	t.check(up.size() == 18, "teardown control: eighteen skeletons out")
	fx.end_now()
	var gone := true
	for a in nodes:
		gone = gone and (not is_instance_valid(a) or a.is_queued_for_deletion())
	t.check(fx.finished and gone and pack.living().is_empty() and fx._scattered.is_empty(), "end_now(): the skeletons are freed and the pack empty")
	GT._soldiers_back(s[1])
	var s2 := _stand(made, 5, 0)
	var f2: GraveTideFx = s2[0]
	_cut(f2)
	var up2 := _skeletons(f2)
	t.check(up2.size() == 18, "exit control: eighteen out")
	f2._exit_tree()
	var gone2 := true
	for a in up2:
		gone2 = gone2 and (not is_instance_valid(a) or a.is_queued_for_deletion())
	t.check(gone2 and f2.visitors.living().is_empty(), "_exit_tree(): the skeletons are queued for freeing")
	f2.end_now()
	GT._soldiers_back(s2[1])


## Two level-5 casts: one's fall leaves the other's pack alone.
static func _two_casts(t, made: Array) -> void:
	var s := _stand(made, 5, 0)
	var a: GraveTideFx = s[0]
	var b := _cast(made, RD._empty(made, a.origin), 5)
	GT._run_bare(b, GraveTideFx.T_RISE + GraveTideFx.ASSEMBLE + 0.05)
	_cut(a)
	t.check(_skeletons(a).size() == 18 and _skeletons(b).is_empty() and b._scattered.is_empty() and b.giant != null,
		"two casts: the first's fall gives the second nothing")
	a.end_now()
	t.check(b.giant != null and not b.finished, "and ending the first leaves the second's giant standing")
	b.end_now()
	GT._soldiers_back(s[1])
