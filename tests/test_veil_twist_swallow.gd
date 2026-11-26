extends RefCounted
## The Swallowing Dark's level-5 twist, "The Moon's Face" (Veil twists, round 2): at the fold the circle is left pitted with craters
## (MoonCraters, about a third of it); who stays in one is hurt a quarter of his health a second -- quietly, no panic, no body, nobody
## woken -- and taken at nought; who only walks through lives. The spared are eyed, never hurt; the indoors passed over. The craters
## stay for the mission (Battlefield.clear_effects() frees them). Level 4 lays none.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const SW := preload("res://tests/test_veil_swallow.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 1.0 / 60.0
const L5 := {"level": 5}
const L4 := {"level": 4}
const DARK5 := {"level": 5, "dark": true}


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	_t_place_seeded(t)
	_t_place_count_and_cover(t)
	_t_place_keep_out(t)
	_t_laid_clear_of_kept(t)
	_t_laid_at_fold_level5_only(t, made)
	_t_hurt_over_time(t, made)
	_t_walk_through_survives(t, made)
	_t_silent(t, made)
	_t_spared_never_hurt(t, made)
	_t_indoors_passed_over(t, made)
	_t_stay_for_mission(t, made)
	_t_teardown(t, made)
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


static func _craters(made: Array) -> Array:
	var out: Array = []
	for c in (made[5] as FxContext).ground.get_children():
		if c is MoonCraters and not c.is_queued_for_deletion():
			out.append(c)
	return out


static func _clear(made: Array) -> void:
	for c in _craters(made):
		(c as Node).free()


## Casts at level 5 and runs it to the fold (the queue drained); [the cast, the craters laid].
static func _fold(made: Array, at: Vector2, extra := L5) -> Array:
	var fx := _cast(made, at, extra)
	_go(fx, fx.t_full + 1.5)
	return [fx, _craters(made)]


## A man put out of doors at `at`, at his full health (the pool's people are reused between the checks).
static func _man(crowd: Crowd, at: Vector2, soldier := false) -> Person:
	var p := EV._put(crowd, at, soldier)
	p.health = Person.HEALTH_SOLDIER if soldier else Person.HEALTH_CITIZEN
	return p


static func _eyed(made: Array, p: Person) -> bool:
	var eye := PaleEye.of(made[0])
	return eye != null and eye.is_eyed(p)


static func _step(mc: MoonCraters, seconds: float) -> void:
	for i in roundi(seconds / DT):
		mc.step(DT)


static func _area(list: Array) -> float:
	var a := 0.0
	for c in list:
		a += PI * (c[1] as float) * (c[1] as float)
	return a


static func _t_place_seeded(t) -> void:
	var a := MoonCraters.place(Vector2(3.0, 4.0), 10.8, 9, 77, [])
	var b := MoonCraters.place(Vector2(3.0, 4.0), 10.8, 9, 77, [])
	var c := MoonCraters.place(Vector2(30.0, -4.0), 10.8, 9, hash(Vector2(30.0, -4.0)), [])
	t.check(a.size() == 9 and a == b, "place(): the same inputs give the same craters")
	t.check(a != c, "place(): another origin and seed give others")


static func _t_place_count_and_cover(t) -> void:
	for dark in [false, true]:
		var full_r := 16.0 if dark else 10.8
		var count: int = MoonCraters.COUNT[1 if dark else 0]
		var at := Vector2(5.0, -9.0)
		var list := MoonCraters.place(at, full_r, count, hash(at.round()), [])
		var clean := true
		for i in list.size():
			var ci: Array = list[i]
			if (ci[0] as Vector2).distance_to(at) + float(ci[1]) > full_r + 0.001 or float(ci[1]) < MoonCraters.R_MIN - 0.001 or float(ci[1]) > MoonCraters.R_MAX + 0.001:
				clean = false
			for j in range(i + 1, list.size()):
				var cj: Array = list[j]
				if (ci[0] as Vector2).distance_to(cj[0]) < float(ci[1]) + float(cj[1]) - 0.001:
					clean = false
		var share := _area(list) / (PI * full_r * full_r)
		t.check(list.size() == count and clean, "%s: %d craters, none overlapping, all inside the circle (%d)" % ["dark" if dark else "light", count, list.size()])
		t.check(share > 0.22 and share < 0.40, "%s: the craters cover about a third (%.2f)" % ["dark" if dark else "light", share])


static func _t_place_keep_out(t) -> void:
	var at := Vector2.ZERO
	var rect := Rect2(Vector2(4.0, -2.0), Vector2(3.0, 3.0))
	var keep: Array = [Vector2(0.0, 0.0), rect]
	var list := MoonCraters.place(at, 10.8, 9, 5, keep)
	var clear := true
	for c in list:
		var centre: Vector2 = c[0]
		var r: float = c[1]
		if centre.distance_to(Vector2.ZERO) < r:
			clear = false
		var near := Vector2(clampf(centre.x, rect.position.x, rect.end.x), clampf(centre.y, rect.position.y, rect.end.y))
		if near.distance_to(centre) < r:
			clear = false
	t.check(list.size() >= 6 and clear, "keep-outs (a point, a rect): no crater covers them (%d placed)" % list.size())


## A crater laid over a gate or a building the mission needs (one it wants down, one it needs standing) is never placed: each footprint is
## in the cast's keep-out list and no crater touches it.
static func _t_laid_clear_of_kept(t) -> void:
	var made := SW._setup()
	var env: EnvironmentField = made[1]
	var ctx: FxContext = made[5]
	var town: Town = made[6]
	var houses := SW._houses(env)
	var d := SW.TestDirector.new()
	var spots: Array = []
	if houses.size() >= 2:
		var near: Structure = null
		for o in houses:
			if o != houses[0] and o.center().distance_to(houses[0].center()) < 8.0:
				near = o
				break
		d.want = houses[0]
		d.keep = near
		spots.append([houses[0].center(), [houses[0], near]])
	if not town.gates.is_empty():
		spots.append([town.gates[0].center(), [town.gates[0]]])
	t.check(spots.size() >= 1, "a house and a gate to lay craters around")
	ctx.rules.director = d
	for spot in spots:
		var fx := FxTimeline.cast(TheSwallowingDarkFx, ctx, spot[0], L5) as TheSwallowingDarkFx
		_go(fx, fx.t_full + 0.5)
		var list := _craters(made)
		var keep_out := fx._crater_keep_out()
		var ok := not list.is_empty()
		var seen := 0
		for s in spot[1]:
			if s == null:
				continue
			var rect: Rect2 = (s as Structure).footprint
			seen += 1 if keep_out.has(rect.grow(0.5)) else 0
			for c in (list[0] as MoonCraters).circles:
				var centre: Vector2 = c[0]
				var nearest := Vector2(clampf(centre.x, rect.position.x, rect.end.x), clampf(centre.y, rect.position.y, rect.end.y))
				if nearest.distance_to(centre) < float(c[1]):
					ok = false
		t.check(ok and seen > 0, "craters laid clear of the kept footprints (%d in the keep-out list)" % seen)
		fx.end_now()
		_clear(made)
	SW._done(made)


static func _t_laid_at_fold_level5_only(t, made: Array) -> void:
	var at := _begin(made)
	var fx := _cast(made, at)
	_go(fx, fx.t_full - 1.0)
	t.check(_craters(made).is_empty(), "level 5: no craters before the fold")
	_go(fx, 2.0)
	var list := _craters(made)
	t.check(list.size() == 1 and (list[0] as MoonCraters).circles.size() == 9, "level 5, light: one MoonCraters of 9 laid at the fold (%d)" % list.size())
	fx.end_now()
	_clear(made)
	var at4 := _begin(made)
	var fx4 := _cast(made, at4, L4)
	_go(fx4, fx4.t_full + 1.5)
	t.check(_craters(made).is_empty(), "level 4: none")
	fx4.end_now()
	var at_d := _begin(made)
	var r := _fold(made, at_d, DARK5)
	t.check((r[1] as Array).size() == 1 and ((r[1] as Array)[0] as MoonCraters).circles.size() == 20, "level 5, dark: 20 craters")
	(r[0] as FxTimeline).end_now()
	_clear(made)


## A citizen (health 1.0) in a crater: alive at 3 s, taken (no body) by 4.5 s, eyed meanwhile; a soldier (2.0) alive at 7 s, taken by 8.5 s.
static func _t_hurt_over_time(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var r := _fold(made, at)
	var mc: MoonCraters = (r[1] as Array)[0]
	var centre: Vector2 = mc.circles[0][0]
	var c := _man(crowd, centre)
	var s := _man(crowd, centre + Vector2(0.2, 0.0), true)
	Kit.arrive(c, centre)
	Kit.arrive(s, centre)
	var bodies := crowd.remains.near(centre, 3.0).size() if crowd.remains != null else 0
	_step(mc, 3.0)
	t.check(c.is_alive() and _eyed(made, c), "a citizen in a crater: alive and eyed at 3 s (health %.2f)" % c.health)
	_step(mc, 1.5)
	t.check(not c.is_alive() and not _eyed(made, c), "taken by 4.5 s")
	t.check((crowd.remains.near(centre, 3.0).size() if crowd.remains != null else 0) == bodies, "the take leaves no body")
	_step(mc, 2.5)
	t.check(s.is_alive(), "a soldier (2.0) alive at 7 s (health %.2f)" % s.health)
	_step(mc, 1.5)
	t.check(not s.is_alive(), "a soldier taken by 8.5 s")
	(r[0] as FxTimeline).end_now()
	_clear(made)


static func _t_walk_through_survives(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var r := _fold(made, at)
	var mc: MoonCraters = (r[1] as Array)[0]
	var centre: Vector2 = mc.circles[0][0]
	var c := _man(crowd, centre)
	Kit.arrive(c, centre)
	_step(mc, 1.0)
	Kit.arrive(c, at + Vector2(0.0, 40.0))
	_step(mc, 1.5)
	t.check(c.is_alive() and absf(c.health - 0.75) < 0.07, "walked through: alive, health about 0.75 (%.2f)" % c.health)
	t.check(not _eyed(made, c), "no longer eyed once out")
	(r[0] as FxTimeline).end_now()
	_clear(made)


static func _t_silent(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var r := _fold(made, at)
	var mc: MoonCraters = (r[1] as Array)[0]
	var centre: Vector2 = mc.circles[0][0]
	var c := _man(crowd, centre)
	var z := _man(crowd, centre + Vector2(0.3, 0.0))
	Kit.arrive(c, centre)
	Kit.arrive(z, centre + Vector2(0.3, 0.0))
	z.sleep(200.0, true)
	var struck := [0]
	(made[5] as FxContext).field.enemy_struck.connect(func(_a = null, _b = null, _c = null) -> void: struck[0] += 1)
	var mind: int = c.mind
	_step(mc, 2.0)
	t.check(c.health < 1.0 and c.mind == mind and struck[0] == 0, "hurt quietly: health down, mind unchanged, no enemy_struck (%.2f)" % c.health)
	t.check(z.health < 1.0 and z.is_asleep(), "a sleeper is hurt and stays asleep")
	(r[0] as FxTimeline).end_now()
	_clear(made)
	z.wake()


static func _t_spared_never_hurt(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var r := _fold(made, at)
	var mc: MoonCraters = (r[1] as Array)[0]
	var centre: Vector2 = mc.circles[0][0]
	var b := _man(crowd, centre)
	Kit.arrive(b, centre)
	b.profile.faith = CitizenProfile.Faith.BELIEVER
	_step(mc, 6.0)
	t.check(b.is_alive() and is_equal_approx(b.health, 1.0) and _eyed(made, b), "a believer in a crater: eyed, never hurt")
	b.profile.faith = CitizenProfile.Faith.NONE
	(r[0] as FxTimeline).end_now()
	_clear(made)


static func _t_indoors_passed_over(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var r := _fold(made, at)
	var mc: MoonCraters = (r[1] as Array)[0]
	var centre: Vector2 = mc.circles[0][0]
	var c := _man(crowd, centre)
	Kit.arrive(c, centre)
	c.inside = true
	_step(mc, 6.0)
	t.check(c.is_alive() and is_equal_approx(c.health, 1.0) and not _eyed(made, c), "indoors in a crater's circle: passed over")
	(r[0] as FxTimeline).end_now()
	_clear(made)


static func _t_stay_for_mission(t, made: Array) -> void:
	var at := _begin(made)
	var r := _fold(made, at)
	var mc: MoonCraters = (r[1] as Array)[0]
	_step(mc, 120.0)
	t.check(is_instance_valid(mc) and mc.is_in_group(SolarisPit.GROUP), "the craters still stand 120 s on, in the group clear_effects() frees")
	(r[0] as FxTimeline).end_now()
	t.check(is_instance_valid(mc) and not mc.is_queued_for_deletion(), "the cast's end leaves them for the mission")
	_clear(made)


static func _t_teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var r := _fold(made, at)
	var mc: MoonCraters = (r[1] as Array)[0]
	var id := mc.get_instance_id()
	var centre: Vector2 = mc.circles[0][0]
	var c := _man(crowd, centre)
	Kit.arrive(c, centre)
	_step(mc, 1.0)
	t.check(_eyed(made, c), "eyed in the crater")
	mc.free()
	t.check(c.is_alive() and PaleEye.of(crowd).held_by(id) == 0 and not _eyed(made, c), "craters freed: no eye stays open, nobody taken")
	(r[0] as FxTimeline).end_now()
	Kit.arrive(c, at + Vector2(0.0, 40.0))


## No crowd, no field: builds and finishes, craters and all.
static func _bare(t, made: Array) -> void:
	var bare := FxContext.new()
	bare.overhead = Node2D.new()
	bare.ground = Node2D.new()
	bare.env = (made[5] as FxContext).env
	var fx := FxTimeline.cast(TheSwallowingDarkFx, bare, Vector2(-200.0, -200.0), L5) as TheSwallowingDarkFx
	_go(fx, fx.t_full + 3.0)
	var n := 0
	for c in bare.ground.get_children():
		if c is MoonCraters:
			(c as MoonCraters).step(0.5)
			n += 1
	t.check(fx.swallowed and n == 1, "bare: builds, lays craters and finishes without error")
	fx.end_now()
	bare.overhead.free()
	bare.ground.free()
