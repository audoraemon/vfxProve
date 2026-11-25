extends RefCounted
## The Swallowing Dark's level-5 twist, "Nothing Leaves" (Veil ability levels, VS 7 / VL13): whoever has stood inside the growing circle
## and then walks out of it is eyed (open-ended) and marked; at the fold every marked man still alive is taken wherever he is (sheltering
## too), except a spared one outside the circle. Level 4 does none of it; the cast's end, early or freed, lifts every eye and mark.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 1.0 / 60.0
const L5 := {"level": 5}
const L4 := {"level": 4}


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_walker(t, made)
	_never_inside(t, made)
	_shelter(t, made)
	_spared(t, made)
	_died(t, made)
	_teardown(t, made)
	_level_four(t, made)
	_bare(t, made)
	ctx.lights.free()
	ctx.lights = null
	RD._done(made)


static func _begin(made: Array) -> Vector2:
	var crowd: Crowd = made[0]
	var old := PaleEye.of(crowd)
	if old != null:
		old.free()
	crowd.pale_eye = null
	return EV._fresh(made)


static func _cast(made: Array, at: Vector2, extra := L5) -> TheSwallowingDarkFx:
	return FxTimeline.cast(TheSwallowingDarkFx, made[5], at, extra) as TheSwallowingDarkFx


static func _go(fx: FxTimeline, seconds: float) -> void:
	for i in roundi(seconds / DT):
		if not is_instance_valid(fx) or fx.finished:
			return
		fx._process(DT)


static func _eyed(made: Array, p: Person) -> bool:
	var eye := PaleEye.of(made[0])
	return eye != null and eye.is_eyed(p)


## One man inside at 3 s who walks out to 12: eyed, marked, taken at the fold though at 12 (a thread each); the record names the power.
static func _walker(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var w := EV._put(crowd, at + Vector2(0.3, 0.0))
	var fx := _cast(made, at)
	t.check(fx._twist and is_equal_approx(fx.full_r, 10.8) and is_equal_approx(fx.lv_grow, 0.7), "level 5, light: twist on, 10.8 at 0.7/s (%.2f, %.2f)" % [fx.full_r, fx.lv_grow])
	_go(fx, 3.0)
	t.check(fx._stood.has(w) and not fx._marked.has(w) and not _eyed(made, w), "inside at 3 s: stood, not marked, not eyed")
	Kit.arrive(w, at + Vector2(12.0, 0.0))
	_go(fx, 0.5)
	t.check(fx._marked.has(w) and _eyed(made, w), "walked out to 12: marked and eyed")
	var eye := PaleEye.of(crowd)
	t.check(eye != null and eye.held_by(fx.get_instance_id()) == 1 and eye.record.size() == 1 and eye.record[0]["key"] == "swallow",
		"the eye is open-ended and the record names the power")
	_go(fx, 5.0)
	t.check(_eyed(made, w) and w.is_alive() and not fx.swallowed, "still eyed (open-ended) and alive before the fold")
	_go(fx, fx.t_full - fx.t + DT)
	t.check(fx.swallowed and not _eyed(made, w) and eye.held_by(fx.get_instance_id()) == 0, "at the fold the eyes are released")
	_go(fx, 2.0)
	t.check(not w.is_alive() and w.ground_pos.distance_to(at) > fx.full_r, "at the fold he is taken though at 12 from the click")
	fx.end_now()


## One who never stood inside is left alone (no mark, no eye, alive after the fold).
static func _never_inside(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var walker := EV._put(crowd, at + Vector2(0.3, 0.0))
	var other := EV._put(crowd, at + Vector2(12.0, 1.0))
	var fx := _cast(made, at)
	_go(fx, 3.0)
	Kit.arrive(walker, at + Vector2(12.5, -1.0))
	_go(fx, fx.t_full + 2.0 - fx.t)
	t.check(not walker.is_alive(), "control: the one who stood inside is taken")
	t.check(other.is_alive() and not _eyed(made, other), "one who never stood inside: untouched, never eyed")
	fx.end_now()


## A marked man who went into a shelter is taken and the shelter's list is clean.
static func _shelter(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var s: Structure = null
	for h in crowd.shelters.shelters:
		if not TheSwallowingDarkFx.wholly_inside(h, at, 14.0) and h.distance_to(at) > 13.0 and (s == null or h.get_instance_id() < s.get_instance_id()):
			s = h
	t.check(s != null, "a shelter far from the click exists")
	if s == null:
		return
	var w := EV._put(crowd, at + Vector2(0.3, 0.0))
	var fx := _cast(made, at)
	_go(fx, 3.0)
	Kit.arrive(w, at + Vector2(12.0, 0.0))
	_go(fx, 0.5)
	t.check(fx._marked.has(w), "marked outside")
	crowd.shelters._enter(w, s)
	(crowd.shelters.shelters[s].inside as Array).append(w)
	_go(fx, fx.t_full + 2.0 - fx.t)
	t.check(not w.is_alive() and not (crowd.shelters.shelters[s].inside as Array).has(w), "sheltering at the fold: taken, the shelter's list clean")
	fx.end_now()


## A marked believer outside the circle lives and stays eyed until the fold's release; a spared one inside is taken as today.
static func _spared(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var b := EV._put(crowd, at + Vector2(0.3, 0.0))
	b.profile.faith = CitizenProfile.Faith.BELIEVER
	var fx := _cast(made, at)
	_go(fx, 3.0)
	Kit.arrive(b, at + Vector2(12.0, 0.0))
	_go(fx, 0.5)
	t.check(fx._marked.has(b) and _eyed(made, b), "a believer who walks out is marked and eyed")
	_go(fx, fx.t_full + 2.0 - fx.t)
	t.check(b.is_alive(), "marked believer outside: alive")
	b.profile.faith = CitizenProfile.Faith.NONE
	fx.end_now()


## A marked man who died meanwhile: no error, nothing taken twice.
static func _died(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var w := EV._put(crowd, at + Vector2(0.3, 0.0))
	var fx := _cast(made, at)
	_go(fx, 3.0)
	Kit.arrive(w, at + Vector2(12.0, 0.0))
	_go(fx, 0.5)
	crowd.take(w, &"void")
	_go(fx, fx.t_full + 2.0 - fx.t)
	t.check(fx.swallowed and not w.is_alive() and not _eyed(made, w), "a marked man who died meanwhile: no error, no eye")
	fx.end_now()


## end_now() before the fold and free() off the tree: marked alive, threads and marks gone, eyes closed, nobody taken.
static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	for mode in ["end_now", "free"]:
		var at := _begin(made)
		var w := EV._put(crowd, at + Vector2(0.3, 0.0))
		var fx := _cast(made, at)
		var id := fx.get_instance_id()
		_go(fx, 3.0)
		Kit.arrive(w, at + Vector2(12.0, 0.0))
		_go(fx, 0.5)
		t.check(fx._marked.has(w) and PaleEye.of(crowd).held_by(id) == 1, "%s: marked and eyed first" % mode)
		if mode == "end_now":
			fx.end_now()
			t.check(fx._marked.is_empty(), "end_now: the marks are gone")
		else:
			fx.free()
		t.check(w.is_alive() and PaleEye.of(crowd).held_by(id) == 0 and not _eyed(made, w), "%s: alive, no eye open" % mode)
		Kit.arrive(w, at + Vector2(-30.0, 0.0))


## Level 4: the walker out lives, and no eye is ever built.
static func _level_four(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var w := EV._put(crowd, at + Vector2(0.3, 0.0))
	var fx := _cast(made, at, L4)
	t.check(not fx._twist, "level 4: no twist")
	_go(fx, 3.0)
	Kit.arrive(w, at + Vector2(12.0, 0.0))
	_go(fx, fx.t_full + 2.0 - fx.t)
	t.check(w.is_alive() and PaleEye.of(crowd) == null and fx._marked.is_empty(), "level 4: the walker out lives, no eye")
	fx.end_now()


## No crowd, no field: builds and finishes.
static func _bare(t, made: Array) -> void:
	var bare := FxContext.new()
	bare.overhead = Node2D.new()
	bare.env = (made[5] as FxContext).env
	var fx := FxTimeline.cast(TheSwallowingDarkFx, bare, Vector2(-200.0, -200.0), L5) as TheSwallowingDarkFx
	_go(fx, fx.t_full + 3.0)
	t.check(fx.swallowed and fx._marked.is_empty(), "bare: builds and finishes without error")
	fx.end_now()
	bare.overhead.free()
