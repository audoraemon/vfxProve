extends RefCounted
## Blight's level-5 twist, Watchful Rot (Veil ability levels, A2): a level-5 building cast gives its foothold a RotWatch; the watch (soldiers
## and the mission's faithful) who step into its dusk are eyed, and the first of them while it is not resting falls ill, no cue; it rests
## 15 s; the spared are eyed only; it ends with the foothold. Level 4 and a person cast have no watch.

const BL := preload("res://tests/test_veil_blight.gd")
const BLIGHT := preload("res://src/fx/quiet/blight.gd")

const R := 3.4


## Records the cues asked of a context or a crowd.
class Rec extends Node:
	var played: Array[StringName] = []

	func play(cue: StringName, _at: Vector2, _db := 0.0) -> Node:
		played.append(cue)
		return null


static func run(t) -> void:
	var made := BL._setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var rec := Rec.new()
	ctx.sfx = rec
	crowd.sfx = rec
	_main(t, made, rec)
	_quarry(t, made)
	_cap(t, made)
	_building_gone(t, made)
	_person_cast(t, made)
	_level_four(t, made)
	_teardown(t, made)
	_bare(t)
	ctx.sfx = null
	crowd.sfx = null
	rec.free()
	BL._done(made)
	assert(env != null)


## Everyone parked far off, no eye, no dusk, no foothold left.
static func _fresh(made: Array) -> void:
	var crowd: Crowd = made[0]
	for s in crowd.footholds.duplicate():
		BlightFx.heal(crowd, made[1], s)
	BL._scatter(crowd)
	crowd.dusk.clear()
	crowd.dusk.enabled = true
	crowd.mission_keeps.clear()
	crowd.mission_watch.clear()
	var old := PaleEye.of(crowd)
	if old != null:
		old.free()
	crowd.pale_eye = null
	var ctx: FxContext = made[5]
	for c in ctx.overhead.get_children():
		c.free()


static func _put(p: Person, at: Vector2) -> Person:
	p.ground_pos = at
	p.inside = false
	p.night_indoors = false
	p.home_sick = false
	p.visible = true
	p.statuses.clear()
	return p


static func _soldier(crowd: Crowd, i: int, at: Vector2) -> Person:
	return _put(crowd.soldiers[i], at)


static func _citizen(crowd: Crowd, i: int, at: Vector2) -> Person:
	var p := _put(crowd.citizens[i], at)
	p.profile.faith = CitizenProfile.Faith.NONE
	return p


## A level-5 cast on `h` (a plain house), run past T_ROT. Returns [the cast, its watch].
static func _plant(made: Array, h: Structure, level := 5) -> Array:
	var ctx: FxContext = made[5]
	var fx := FxTimeline.cast(BLIGHT, ctx, h.center(), {"level": level})
	fx._process(BlightFx.T_ROT + 0.05)
	return [fx, _watch_of(h)]


static func _watch_of(h: Structure) -> BlightFx.RotWatch:
	var held: Dictionary = h.get_meta(BlightFx.FOOTHOLD, {})
	var w := instance_from_id(int(held.get("watch", 0))) as BlightFx.RotWatch
	return w if w != null and is_instance_valid(w) and not w.is_queued_for_deletion() else null


static func _run(w: BlightFx.RotWatch, seconds: float) -> void:
	for i in roundi(seconds / 0.25):
		w._process(0.25)


static func _eyed(crowd: Crowd, p: Person) -> bool:
	var e := PaleEye.of(crowd)
	return e != null and e.is_eyed(p)


static func _main(t, made: Array, rec: Rec) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	_fresh(made)
	var h: Structure = BL._houses(env)[0]
	var c := h.center()
	var s := _soldier(crowd, 0, c + Vector2(4.0, 0.0))
	var s2 := _soldier(crowd, 1, c + Vector2(0.0, 4.5))
	var s3 := _soldier(crowd, 2, c + Vector2(-4.5, 0.0))
	var inside := _soldier(crowd, 3, c + Vector2(1.0, 1.0))
	var walker := _citizen(crowd, 0, c + Vector2(0.0, -4.0))
	var faithful := _citizen(crowd, 1, c + Vector2(-4.0, 4.0))
	crowd.mission_watch.append(func(p: Person) -> bool: return p == faithful)
	var alarm := crowd.alarm
	var threats := crowd.threats.active_count()
	var made_fx := _plant(made, h)
	var fx: FxTimeline = made_fx[0]
	var w: BlightFx.RotWatch = made_fx[1]
	t.check(w != null and w.get_parent() == made[5].overhead and w.radius == R and w.is_in_group(SolarisPit.GROUP)
		and int(h.get_meta(BlightFx.FOOTHOLD).get("watch", 0)) == w.get_instance_id(), "a level-5 building cast gives the foothold a RotWatch (r %s)" % [w.radius if w != null else -1.0])
	if w == null:
		fx.end_now()
		return
	_run(w, 0.5)
	rec.played.clear()
	t.check(not _eyed(crowd, inside) and not inside.home_sick, "a soldier inside the dusk at the plant did not step in: nothing")
	s.ground_pos = c + Vector2(3.0, 0.0)
	_run(w, 0.25)
	t.check(_eyed(crowd, s) and s.home_sick and is_equal_approx(w.rest_left, 15.0), "a soldier stepping in is eyed and falls ill; the rot rests 15 s")
	t.check(PaleEye.of(crowd).record.back()["key"] == "blight", "the record's key is blight")
	_run(w, 5.0)
	s2.ground_pos = c + Vector2(0.0, 3.0)
	_run(w, 0.25)
	t.check(_eyed(crowd, s2) and not s2.home_sick, "5 s later another steps in: eyed only")
	_run(w, 5.0)
	var citizen_eyes := PaleEye.of(crowd).record.size()
	walker.ground_pos = c + Vector2(0.0, -2.0)
	_run(w, 0.25)
	t.check(not _eyed(crowd, walker) and not walker.home_sick and PaleEye.of(crowd).record.size() == citizen_eyes, "a citizen stepping in: nothing")
	_run(w, 6.0)  # 16.5 s since the first fell ill
	t.check(w.rest_left == 0.0, "the rest is over after 15 s")
	s3.ground_pos = c + Vector2(-3.0, 0.0)
	_run(w, 0.25)
	t.check(_eyed(crowd, s3) and s3.home_sick, "at 16 s a third soldier falls ill")
	_run(w, 16.0)
	faithful.ground_pos = c + Vector2(-2.0, 2.0)
	_run(w, 0.25)
	t.check(_eyed(crowd, faithful) and faithful.home_sick, "a faithful (the mission's watch) falls ill too")
	var no_cue := true
	for cue in rec.played:
		no_cue = no_cue and cue == PaleEye.CUE
	t.check(no_cue and not rec.played.is_empty(), "no cue but v_pale_eye for the rot's sick (%s)" % [rec.played])
	t.check(crowd.alarm == alarm and crowd.threats.active_count() == threats, "alarm and threats unchanged")
	fx.end_now()
	t.check(_watch_of(h) == w, "the watch outlives its cast")
	# The spared are eyed only and start no rest.
	_run(w, 16.0)
	var believer := _citizen(crowd, 2, c + Vector2(4.0, 4.0))
	believer.profile.faith = CitizenProfile.Faith.BELIEVER
	var after := _soldier(crowd, 4, c + Vector2(-4.0, -4.0))
	_run(w, 0.25)
	believer.ground_pos = c + Vector2(2.0, 2.0)
	crowd.mission_watch.append(func(p: Person) -> bool: return p == believer)
	_run(w, 0.25)
	t.check(_eyed(crowd, believer) and not believer.home_sick and w.rest_left == 0.0, "a spared one is eyed only and starts no rest")
	after.ground_pos = c + Vector2(-2.0, -2.0)
	_run(w, 0.25)
	t.check(after.home_sick, "so the next to step in may fall ill at once")
	believer.profile.faith = CitizenProfile.Faith.NONE
	BlightFx.heal(crowd, env, h)
	t.check(_watch_of(h) == null and w.is_queued_for_deletion(), "healed: the watch is freed")
	var late := _soldier(crowd, 5, c + Vector2(5.0, 0.0))
	_run(w, 0.25)
	late.ground_pos = c + Vector2(2.0, 0.0)
	_run(w, 0.5)
	t.check(not late.home_sick and not _eyed(crowd, late), "a soldier stepping in after the heal: nothing")
	crowd.mission_watch.clear()


static func _quarry(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	_fresh(made)
	var h: Structure = BL._houses(env)[0]
	var c := h.center()
	var q := _soldier(crowd, 0, c + Vector2(4.0, 0.0))
	var dir := BL.TestDirector.new()
	dir.mine = q
	ctx.rules.director = dir
	var m := _plant(made, h)
	var w: BlightFx.RotWatch = m[1]
	_run(w, 0.25)
	q.ground_pos = c + Vector2(2.0, 0.0)
	_run(w, 0.25)
	t.check(not q.home_sick and is_equal_approx(q.ill_left(), BlightFx.ILL_TIME) and _eyed(crowd, q), "a quarry: make_ill(20), not sent home")
	ctx.rules.director = null
	(m[0] as FxTimeline).end_now()
	BlightFx.heal(crowd, env, h)


static func _cap(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	_fresh(made)
	var houses := BL._far_houses(env, 4, 8.0)
	if houses.size() < 4:
		t.check(false, "four far houses exist (%d)" % houses.size())
		return
	var first_watch: BlightFx.RotWatch
	for i in 4:
		var m := _plant(made, houses[i])
		(m[0] as FxTimeline).end_now()
		if i == 0:
			first_watch = m[1]
	t.check(first_watch != null and first_watch.is_queued_for_deletion() and _watch_of(houses[0]) == null and _watch_of(houses[3]) != null,
		"a fourth blight heals the first: its watch is gone, the new one stands")
	var c := houses[0].center()
	var s := _soldier(crowd, 0, c + Vector2(6.0, 0.0))
	first_watch._process(0.25)
	s.ground_pos = c + Vector2(1.5, 0.0)
	first_watch._process(0.5)
	t.check(not s.home_sick and not _eyed(crowd, s), "a soldier stepping into the healed building's dusk: nothing")
	for h in houses:
		BlightFx.heal(crowd, env, h)


static func _building_gone(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	_fresh(made)
	var houses := BL._far_houses(env, 2, 8.0)
	var m := _plant(made, houses[0])
	var w: BlightFx.RotWatch = m[1]
	(m[0] as FxTimeline).end_now()
	houses[0].destroyed = true
	w._process(0.3)
	t.check(w.stopped and w.is_queued_for_deletion(), "its building destroyed: the watch frees itself")
	houses[0].destroyed = false
	BlightFx.heal(crowd, env, houses[0])
	var m3 := _plant(made, houses[1])
	var w3: BlightFx.RotWatch = m3[1]
	(m3[0] as FxTimeline).end_now()
	houses[1].taken = true
	w3._process(0.3)
	t.check(w3.stopped and w3.is_queued_for_deletion(), "its building taken: the watch frees itself")
	houses[0].taken = false
	houses[1].taken = false
	BlightFx.heal(crowd, env, houses[1])
	# Freed: a stand-in building outside the town's list (a freed structure would break the list itself).
	var lone := Structure.new()
	lone.set_meta(BlightFx.FOOTHOLD, {})
	var w2 := BlightFx.RotWatch.new()
	w2.crowd = crowd
	w2.building = lone
	lone.free()
	w2._process(0.3)
	t.check(w2.stopped and w2.is_queued_for_deletion(), "its building freed: the watch frees itself")
	w2.free()
	# Its field freed (a town torn down): it stops before it asks the field anything.
	var m4 := _plant(made, houses[0])
	var w4: BlightFx.RotWatch = m4[1]
	(m4[0] as FxTimeline).end_now()
	var gone_field := EnemyField.new()
	w4.field = gone_field
	gone_field.free()
	w4._process(0.3)
	t.check(w4.stopped and w4.is_queued_for_deletion(), "its field freed: the watch frees itself")
	BlightFx.heal(crowd, env, houses[0])
	# Its building no longer a foothold of the crowd (the list lost it, the meta stayed): it stops.
	var m5 := _plant(made, houses[1])
	var w5: BlightFx.RotWatch = m5[1]
	(m5[0] as FxTimeline).end_now()
	crowd.footholds.erase(houses[1])
	w5._process(0.3)
	t.check(w5.stopped and w5.is_queued_for_deletion(), "its building off the crowd's footholds: the watch frees itself")
	BlightFx.heal(crowd, env, houses[1])


static func _person_cast(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	_fresh(made)
	var open := BL._open_spot(env, grid)
	var p := _citizen(crowd, 0, open)
	var fx := FxTimeline.cast(BLIGHT, ctx, open, {"level": 5})
	fx._process(BlightFx.T_ROT + 0.05)
	var any := false
	for c in ctx.overhead.get_children():
		any = any or c is BlightFx.RotWatch
	t.check(p.home_sick and not any and crowd.footholds.is_empty(), "a level-5 person cast: ill as today, no watch")
	fx.end_now()


static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	_fresh(made)
	var h: Structure = BL._houses(env)[0]
	var c := h.center()
	var s := _soldier(crowd, 0, c + Vector2(4.0, 0.0))
	var m := _plant(made, h, 4)
	_run_all(made)
	s.ground_pos = c + Vector2(2.0, 0.0)
	_run_all(made)
	t.check(m[1] == null and not s.home_sick and PaleEye.of(crowd) == null, "level 4: no watch, no eye, nobody ill")
	(m[0] as FxTimeline).end_now()
	BlightFx.heal(crowd, env, h)


static func _run_all(made: Array) -> void:
	for c in (made[5] as FxContext).overhead.get_children():
		if c is BlightFx.RotWatch:
			c._process(0.5)


static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	_fresh(made)
	var h: Structure = BL._houses(env)[0]
	var c := h.center()
	var s := _soldier(crowd, 0, c + Vector2(4.0, 0.0))
	var m := _plant(made, h)
	var w: BlightFx.RotWatch = m[1]
	_run(w, 0.25)
	s.ground_pos = c + Vector2(2.0, 0.0)
	_run(w, 0.25)
	(m[0] as FxTimeline).end_now()
	BlightFx.heal(crowd, env, h)
	var eye := PaleEye.of(crowd)
	var wid := w.get_instance_id()
	t.check(eye.held_by(m[0].get_instance_id()) == 0 and eye.held_by(wid) == 1, "teardown: the cast holds no eye; the watch's timed one runs out on its own")
	eye.step(PaleEye.TIME + 0.1)
	t.check(eye.held_by(wid) == 0 and s.is_alive(), "and then none is held, nobody taken")
	# The cast ended or freed before T_ROT leaves nothing.
	_fresh(made)
	var early := FxTimeline.cast(BLIGHT, made[5], c, {"level": 5})
	early._process(0.3)
	early.free()
	t.check(crowd.footholds.is_empty() and _watch_of(h) == null, "freed before T_ROT: no foothold, no watch")
	# A watch whose crowd is gone frees itself.
	var m2 := _plant(made, h)
	var w2: BlightFx.RotWatch = m2[1]
	(m2[0] as FxTimeline).end_now()
	w2.crowd = null
	w2._process(0.3)
	t.check(w2.stopped, "a watch with no crowd stops")
	BlightFx.heal(crowd, env, h)


static func _bare(t) -> void:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var field := EnemyField.new()
	field.env = env
	var bare := FxContext.new()
	bare.env = env
	bare.field = field
	bare.rng = RandomNumberGenerator.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	var h: Structure = BL._houses(env)[0]
	var fx := FxTimeline.cast(BLIGHT, bare, h.center(), {"level": 5})
	fx._process(BlightFx.T_ROT + 0.1)
	fx.end_now()
	var any := false
	for c in bare.overhead.get_children():
		any = any or c is BlightFx.RotWatch
	t.check(fx.finished and not any, "bare (no crowd): builds, finishes, no watch")
	bare.overhead.free()
	bare.ground.free()
