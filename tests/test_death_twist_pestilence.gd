extends RefCounted
## Pestilence level 5, Foul Dead (Death and Decree ability levels, Task 4): the dead of this cast's plague line leave a foul spot for
## 15 s that infects up to 3 healthy people out of doors within 1.2 (they are foul in turn). A sick person from a level-4 cast leaves
## none; two level-5 casts both foul; a cast freed early leaves its line foul (the plague outlives the node) and nothing of itself.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05
## Where the first cast lands; everyone else is laid out far off, in a 0.9-spaced grid (as test_plague does).
const AT := Vector2(0.8, 2.0)


static func run(t) -> void:
	_foul_spot(t)
	_level_4(t)
	_two_casts(t)
	_spot_ends(t)
	_teardown(t)


## A crowd with everyone put away in a grid; [made, crowd, plague].
static func _scene() -> Array:
	var made := RD._setup()
	var crowd: Crowd = made[0]
	var i := 0
	for p in crowd.citizens + crowd.soldiers:
		p.ground_pos = Vector2(-27.0 + float(i % 20) * 0.9, -27.0 + float(i / 20) * 0.9)
		i += 1
	return [made, crowd, crowd.plague]


## Three people at 120 degrees round `at`, 1.1 out (1.9 apart: out of each other's spread reach).
static func _three(crowd: Crowd, at: Vector2, first: int) -> Array[Person]:
	var out: Array[Person] = []
	for k in 3:
		var p: Person = crowd.citizens[first + k]
		p.ground_pos = at + Vector2.from_angle(TAU * float(k) / 3.0) * 1.1
		out.append(p)
	return out


static func _cast(made: Array, at: Vector2, level: int) -> PestilenceFx:
	return FxTimeline.cast(PestilenceFx, made[5], at, {"level": level}) as PestilenceFx


static func _run(fx: FxTimeline, plague: PlagueManager, seconds: float) -> void:
	for i in roundi(seconds / DT):
		if fx != null and is_instance_valid(fx) and not fx.finished:
			fx._process(DT)
		plague.step(DT)


## Level 5: the cast's victims die of the plague, each leaves a spot; a healthy walker within 1.2 is infected, the 4th is not.
static func _foul_spot(t) -> void:
	var s := _scene()
	var made: Array = s[0]
	var crowd: Crowd = s[1]
	var plague: PlagueManager = s[2]
	var vs := _three(crowd, AT, 0)
	var fx := _cast(made, AT, 5)
	_run(fx, plague, 0.6)
	var id := fx.get_instance_id()
	var tagged := true
	for p in vs:
		tagged = tagged and p.sick_left > 0.0 and p.plague_src == id
	t.check(tagged, "level 5: the three caught carry the cast's id as plague_src")
	t.check(plague.foul.has(id), "level 5: the cast's line is foul")
	t.check(plague.foul_spots.is_empty(), "no spot while they live")
	var at0: Vector2 = vs[0].ground_pos
	_run(fx, plague, PlagueManager.PLAGUE_LIFE + 0.3)
	var dead := 0
	for p in vs:
		if not p.is_alive():
			dead += 1
	t.check(dead == 3 and plague.deaths == 3, "all three died of the plague (%d)" % dead)
	t.check(plague.foul_spots.size() == 3, "each death left a foul spot (%d)" % plague.foul_spots.size())
	# Four healthy walkers beside the first spot, on the side away from the other two; the 4th is the farthest.
	var dir := (at0 - AT).normalized()
	var walkers: Array[Person] = []
	var offs := [0.1, 0.2, 0.3, 1.0]
	for k in 4:
		var w: Person = crowd.citizens[10 + k]
		w.ground_pos = at0 + dir * float(offs[k])
		walkers.append(w)
	_run(null, plague, 0.3)
	var caught := 0
	for w in walkers:
		if w.sick_left > 0.0:
			caught += 1
	t.check(walkers[0].sick_left > 0.0 and walkers[1].sick_left > 0.0 and walkers[2].sick_left > 0.0,
		"the three nearest walkers are infected by the spot")
	t.check(walkers[3].sick_left <= 0.0 and caught == 3, "the 4th walker is not (%d caught)" % caught)
	var same := true
	for k in 3:
		same = same and walkers[k].plague_src == id
	t.check(same, "the spot's victims carry the same source, so they are foul in turn")
	var before := plague.foul_spots.size()
	_run(null, plague, PlagueManager.PLAGUE_LIFE + 0.3)
	t.check(not walkers[0].is_alive() and plague.foul_spots.size() > 0 and plague.deaths >= 6,
		"a spot's victim dies and leaves a spot in turn (%d spots, was %d)" % [plague.foul_spots.size(), before])
	if is_instance_valid(fx):
		fx.end_now()
	RD._done(made)


## Level 4: the same line, the same deaths, no id and no spot. The level-5 run above is its positive control.
static func _level_4(t) -> void:
	var s := _scene()
	var made: Array = s[0]
	var crowd: Crowd = s[1]
	var plague: PlagueManager = s[2]
	var vs := _three(crowd, AT, 0)
	var fx := _cast(made, AT, 4)
	_run(fx, plague, 0.6)
	var sick := true
	for p in vs:
		sick = sick and p.sick_left > 0.0 and p.plague_src == 0
	t.check(sick and plague.foul.is_empty(), "level 4: the three are sick with no source and nothing is foul")
	_run(fx, plague, PlagueManager.PLAGUE_LIFE + 0.3)
	t.check(plague.deaths == 3 and plague.foul_spots.is_empty(), "level 4: they die of the plague and leave no spot")
	fx.end_now()
	RD._done(made)
	# A sick person of another line (no source) beside a level-5 cast's victim: only the 5's own line is foul.
	var s5 := _scene()
	var made5: Array = s5[0]
	var crowd5: Crowd = s5[1]
	var plague5: PlagueManager = s5[2]
	var p4: Person = crowd5.citizens[0]
	p4.ground_pos = AT
	p4.infect(PlagueManager.PLAGUE_LIFE)
	var v5: Person = crowd5.citizens[1]
	v5.ground_pos = AT + Vector2(6.0, 0.0)
	var f5 := _cast(made5, v5.ground_pos, 5)
	_run(f5, plague5, 0.6)
	_run(f5, plague5, PlagueManager.PLAGUE_LIFE + 0.3)
	t.check(not p4.is_alive() and not v5.is_alive() and plague5.foul_spots.size() == 1
		and plague5.foul_spots[0]["src"] == f5.get_instance_id(),
		"a sick person of another line dies without a spot; the level-5 one leaves one")
	f5.end_now()
	RD._done(made5)


## Two level-5 casts: both lines are foul, each death leaves a spot with its own source.
static func _two_casts(t) -> void:
	var s := _scene()
	var made: Array = s[0]
	var crowd: Crowd = s[1]
	var plague: PlagueManager = s[2]
	var a: Person = crowd.citizens[0]
	var b: Person = crowd.citizens[1]
	a.ground_pos = AT
	b.ground_pos = AT + Vector2(8.0, 0.0)
	var fa := _cast(made, a.ground_pos, 5)
	var fb := _cast(made, b.ground_pos, 5)
	for i in roundi(0.6 / DT):
		fa._process(DT)
		fb._process(DT)
		plague.step(DT)
	t.check(fa.get_instance_id() != fb.get_instance_id() and plague.foul.has(fa.get_instance_id())
		and plague.foul.has(fb.get_instance_id()), "two level-5 casts: both lines are foul")
	_run(null, plague, PlagueManager.PLAGUE_LIFE + 0.3)
	var srcs := {}
	for sp in plague.foul_spots:
		srcs[int(sp["src"])] = true
	t.check(plague.foul_spots.size() == 2 and srcs.has(fa.get_instance_id()) and srcs.has(fb.get_instance_id()),
		"each cast's death left a spot of its own source (%d)" % plague.foul_spots.size())
	fa.end_now()
	t.check(plague.foul.has(fb.get_instance_id()), "one cast ending leaves the other's line foul")
	fb.end_now()
	RD._done(made)


## Spots end after FOUL_LIFE (15 s), not before; nothing is infected after.
static func _spot_ends(t) -> void:
	var s := _scene()
	var made: Array = s[0]
	var crowd: Crowd = s[1]
	var plague: PlagueManager = s[2]
	var v: Person = crowd.citizens[0]
	v.ground_pos = AT
	var fx := _cast(made, AT, 5)
	_run(fx, plague, 0.6 + PlagueManager.PLAGUE_LIFE + 0.3)
	t.check(plague.foul_spots.size() == 1, "one spot after the death")
	_run(null, plague, 13.5)
	t.check(plague.foul_spots.size() == 1, "the spot still lies at 14 s")
	_run(null, plague, 1.6)
	t.check(plague.foul_spots.is_empty(), "the spot has ended after 15 s")
	var w: Person = crowd.citizens[5]
	w.ground_pos = AT
	_run(null, plague, 0.5)
	t.check(w.sick_left <= 0.0, "a walker on the old spot is not infected")
	fx.end_now()
	RD._done(made)


## A level-5 cast freed early (end_now, then freed; or _exit_tree before it infected) leaves no node and no particles, yet its
## victims' line still fouls: the plague outlives the cast. A cast left standing is the positive control (_foul_spot).
static func _teardown(t) -> void:
	var s := _scene()
	var made: Array = s[0]
	var crowd: Crowd = s[1]
	var plague: PlagueManager = s[2]
	var ctx: FxContext = made[5]
	var v: Person = crowd.citizens[0]
	v.ground_pos = AT
	var fx := _cast(made, AT, 5)
	var id := fx.get_instance_id()
	_run(fx, plague, 0.6)
	t.check(v.plague_src == id and plague.foul.has(id) and ctx.overhead.get_child_count() >= 1,
		"the cast infected its victim and stands")
	fx.end_now()
	fx.free()
	t.check(not is_instance_valid(fx) and ctx.overhead.get_child_count() == 0, "end_now then freed: no node left")
	_run(null, plague, PlagueManager.PLAGUE_LIFE + 0.3)
	t.check(not v.is_alive() and plague.foul_spots.size() == 1 and plague.foul_spots[0]["src"] == id,
		"the plague outlives the cast: its victim still dies and leaves a spot")
	RD._done(made)
	# A cast freed before the infection (0.4 s): nothing was infected and nothing is foul.
	var s2 := _scene()
	var made2: Array = s2[0]
	var crowd2: Crowd = s2[1]
	var plague2: PlagueManager = s2[2]
	var v2: Person = crowd2.citizens[0]
	v2.ground_pos = AT
	var fy := _cast(made2, AT, 5)
	fy._process(DT)
	fy._exit_tree()
	fy.end_now()
	fy.free()
	_run(null, plague2, 1.0)
	t.check(v2.sick_left <= 0.0 and plague2.foul.is_empty(), "freed before it infected: nobody sick, nothing foul")
	RD._done(made2)
