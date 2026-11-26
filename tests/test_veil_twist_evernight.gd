extends RefCounted
## Evernight's level-5 twist, "The False Light" (Veil ability levels, second round): the torches' light is a false cold blue (FALSE_COLOR in
## the light field), its radius stays TORCH_R all night and nobody in it is touched; in the last FLARE_EYE seconds before the dawn every
## huddler and bearer is eyed; at the dawn each burning torch flares black and takes its huddle (no body, ids in `flared`) before the
## dawn's own takes. A cast cut short never flares. Level 4 does none of it.

const RD := preload("res://tests/test_raise_dead.gd")
const EV := preload("res://tests/test_veil_evernight.gd")
const E := preload("res://src/fx/veil/evernight.gd")
const DT := 0.05
const L5 := {"level": 5}
const L4 := {"level": 4}


static func run(t) -> void:
	var made := RD._setup()
	var ctx: FxContext = made[5]
	ctx.lights = LightField.new()
	(made[0] as Crowd).remains.enabled = true
	_radius(t, made)
	_colour(t, made)
	_huddle(t, made)
	_safe_all_night(t, made)
	_eyed_last_seconds(t, made)
	_flare_takes_huddle(t, made)
	_flare_spares(t, made)
	_two_evernights(t, made)
	_no_flare_on_teardown(t, made)
	_level4_unchanged(t, made)
	_rf4_haste(t, made)
	_teardown(t, made)
	_bare(t)
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


static func _cast(made: Array, at: Vector2, extra := L5) -> EvernightFx:
	return FxTimeline.cast(EvernightFx, made[5], at, extra) as EvernightFx


## Whether any body was laid within 3 of `g`.
static func _body_near(crowd: Crowd, g: Vector2) -> bool:
	return not crowd.remains.near(g, 3.0).is_empty()


## A torch (a soldier) with `n` citizens round it, 1.0 away: {x, s, huddle}.
static func _torch_with_huddle(made: Array, at: Vector2, n := 3) -> Dictionary:
	var crowd: Crowd = made[0]
	var x := at + Vector2(0.0, -6.0)
	var s := EV._put(crowd, x, true)
	var h: Array[Person] = []
	for i in n:
		h.append(EV._put(crowd, x + Vector2.from_angle(float(i) * 2.1) * 1.0))
	return {"x": x, "s": s, "huddle": h}


## torch_r() is TORCH_R at the fall, mid-night and just before the dawn, at level 5 too.
static func _radius(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	EV._put(crowd, at + Vector2(0.0, -6.0), true)
	var fx := _cast(made, at)
	t.check(is_equal_approx(fx.night_time, 68.0) and fx._twist, "level 5: night 68 s, twist")
	EV._until(fx, E.WAVE + DT)
	var a := fx.torch_r()
	EV._until(fx, E.WAVE + 34.0)
	var b := fx.torch_r()
	EV._until(fx, fx.t_dawn - DT)
	var c := fx.torch_r()
	t.check(a == E.TORCH_R and b == E.TORCH_R and c == E.TORCH_R, "level 5: torch_r() is TORCH_R at the fall, mid-night and before the dawn (%.2f %.2f %.2f)" % [a, b, c])
	fx.end_now()


## Level 5's torches light with FALSE_COLOR (the light field's static light); level 4's with TORCH_COLOR.
static func _colour(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	for lv in [5, 4]:
		var at := _begin(made)
		EV._put(crowd, at + Vector2(0.0, -6.0), true)
		var fx := _cast(made, at, L5 if lv == 5 else L4)
		EV._until(fx, E.WAVE + DT)
		var l := EV._light(ctx.lights, int(fx.torches[0].light))
		var want: Color = E.FALSE_COLOR if lv == 5 else E.TORCH_COLOR
		t.check(not l.is_empty() and (l.color as Color).is_equal_approx(want) and is_equal_approx(float(l.radius), E.TORCH_R) and fx.torch_color() == want,
			"level %d: the torch's light is %s at TORCH_R" % [lv, "FALSE_COLOR" if lv == 5 else "TORCH_COLOR"])
		fx.end_now()


## The huddle's slots stay level 1's: within TORCH_R - 0.3 of the torch, at level 5 too.
static func _huddle(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var at := _begin(made)
	var x := grid.nearest_walkable(at + Vector2(0.0, -2.0))
	EV._put(crowd, x, true)
	var near := EV._put(crowd, grid.nearest_walkable(x + Vector2(8.0, 0.0)))
	crowd.mission_keeps.append(func(p: Person) -> bool: return p == near)
	var fx := _cast(made, at)
	EV._until(fx, E.WAVE + DT)
	t.check(fx.torches.size() == 1 and near._goal != Vector2.INF and near._goal.distance_to(x) <= E.TORCH_R - 0.3 + 0.001,
		"level 5: the huddle slot is within TORCH_R - 0.3 of the torch (%.2f; %d torches, near at %.1f)" % [near._goal.distance_to(x), fx.torches.size(), near.ground_pos.distance_to(x)])
	fx.end_now()
	crowd.mission_keeps.clear()


## A huddler in a torch's light is never claimed or taken before the dawn.
static func _safe_all_night(t, made: Array) -> void:
	var at := _begin(made)
	var d := _torch_with_huddle(made, at)
	var fx := _cast(made, at)
	EV._until(fx, fx.t_dawn - DT)
	var alive := (d.s as Person).is_alive()
	for p: Person in d.huddle:
		alive = alive and p.is_alive() and not fx.claimed.has(p.get_instance_id())
	t.check(alive and fx.taken.is_empty() and fx.flared.is_empty(), "level 5: huddlers and bearer live all night, nothing taken before the dawn (%d taken)" % fx.taken.size())
	fx.end_now()


## Nobody eyed at FLARE_EYE + 1 s before the dawn; every huddler and bearer eyed at FLARE_EYE - 0.5 s before it; all released after.
static func _eyed_last_seconds(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var d := _torch_with_huddle(made, at)
	var fx := _cast(made, at)
	var id := fx.get_instance_id()
	EV._until(fx, fx.t_dawn - E.FLARE_EYE - 1.0)
	var eye := PaleEye.of(crowd)
	t.check(eye == null or eye.held_by(id) == 0, "level 5: nobody eyed at FLARE_EYE + 1 s before the dawn")
	EV._until(fx, fx.t_dawn - E.FLARE_EYE + 0.5)
	eye = PaleEye.of(crowd)
	var all := eye != null and eye.is_eyed(d.s)
	for p: Person in d.huddle:
		all = all and eye != null and eye.is_eyed(p)
	t.check(all and eye.held_by(id) == 4, "level 5: every huddler and the bearer eyed at FLARE_EYE - 0.5 s (%d held)" % (eye.held_by(id) if eye != null else -1))
	EV._until(fx, fx.t_dawn + DT)
	t.check(eye.held_by(id) == 0, "level 5: the eyes are released at the dawn")
	fx.end_now()


## At the dawn every huddler and the bearer of each burning torch is taken (no body), their ids in `flared`; the torch is out.
static func _flare_takes_huddle(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var d := _torch_with_huddle(made, at)
	var fx := _cast(made, at)
	EV._until(fx, fx.t_dawn - DT)
	t.check((d.s as Person).is_alive(), "level 5: all alive just before the dawn")
	EV._until(fx, fx.t_dawn + DT)
	var all_gone := not (d.s as Person).is_alive()
	var ids: Array[int] = [(d.s as Person).get_instance_id()]
	for p: Person in d.huddle:
		all_gone = all_gone and not p.is_alive()
		ids.append(p.get_instance_id())
	var flagged := true
	for id in ids:
		flagged = flagged and fx.flared.has(id) and fx.taken.has(id)
	t.check(all_gone and flagged and fx.torches[0].out and not _body_near(crowd, d.x),
		"level 5: the flare takes the huddle and the bearer (no body, in flared), the torch is out (%d flared)" % fx.flared.size())
	fx.end_now()


## A spared huddler and one indoors are alive after the dawn.
static func _flare_spares(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var d := _torch_with_huddle(made, at, 3)
	var spared: Person = d.huddle[0]
	crowd.mission_keeps.append(func(p: Person) -> bool: return p == spared)
	var indoors: Person = d.huddle[1]
	var gone: Person = d.huddle[2]
	var fx := _cast(made, at)
	EV._until(fx, fx.t_dawn - 1.0)
	indoors.inside = true
	EV._until(fx, fx.t_dawn + DT)
	t.check(spared.is_alive() and indoors.is_alive() and not gone.is_alive() and not fx.flared.has(spared.get_instance_id()),
		"level 5: a spared huddler and one indoors live; the other is taken")
	fx.end_now()
	crowd.mission_keeps.clear()
	indoors.inside = false


## Two level-5 Evernights with torches 1.0 apart: a huddler in both lights is taken once, no error.
static func _two_evernights(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var x := at + Vector2(0.0, -6.0)
	var s1 := EV._put(crowd, x, true)
	var s2 := EV._put(crowd, x + Vector2(1.0, 0.0), true)
	var both := EV._put(crowd, x + Vector2(0.5, 0.5))
	var a := _cast(made, at)
	var b := _cast(made, at)
	EV._until(a, a.t_dawn + DT)
	EV._until(b, b.t_dawn + DT)
	var n := 0
	for f: EvernightFx in [a, b]:
		n += f.flared.count(both.get_instance_id())
	t.check(not both.is_alive() and n == 1 and not s1.is_alive() and not s2.is_alive(), "two Evernights: a huddler in both lights is taken once (%d times)" % n)
	a.end_now()
	b.end_now()


## end_now() before the dawn: nobody taken, no eye left open.
static func _no_flare_on_teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var d := _torch_with_huddle(made, at)
	var fx := _cast(made, at)
	var id := fx.get_instance_id()
	EV._until(fx, fx.t_dawn - 2.0)
	t.check(PaleEye.of(crowd).held_by(id) == 4, "level 5: eyed in the last seconds")
	fx.end_now()
	var alive := (d.s as Person).is_alive()
	for p: Person in d.huddle:
		alive = alive and p.is_alive()
	t.check(alive and fx.taken.is_empty() and fx.flared.is_empty() and PaleEye.of(crowd).held_by(id) == 0, "end_now() before the dawn: no flare, nobody taken, no eye open")


## Level 4: the dawn takes only what it took before (a sleeper in dusk); the huddle lives and no eye opens.
static func _level4_unchanged(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var d := _torch_with_huddle(made, at)
	var dreamer := EV._put(crowd, d.x + Vector2(1.5, 0.0))
	crowd.lay_dusk(dreamer.ground_pos, 0.6, 200.0)
	dreamer.sleep(200.0, true)
	var fx := _cast(made, at, L4)
	EV._until(fx, fx.t_dawn - 1.0)
	t.check(PaleEye.of(crowd) == null, "level 4: no eye in the last seconds")
	EV._until(fx, fx.t_dawn + DT)
	var live := (d.s as Person).is_alive()
	for p: Person in d.huddle:
		live = live and p.is_alive()
	t.check(live and not dreamer.is_alive() and fx.flared.is_empty() and fx.taken.size() == 1, "level 4: the dawn takes only the sleeper in the dusk, the huddle lives (%d taken)" % fx.taken.size())
	fx.end_now()


## HASTE with level-5 cooldowns: a level-5 Slumber slot under a level-5 Evernight is ready after 16 s; Evernight's own slot is not hastened.
static func _rf4_haste(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _begin(made)
	var x := at + Vector2(0.0, -8.0)
	EV._put(crowd, x, true)
	var rules := Rules.new().setup(PackedStringArray(["evernight", "slumber"]), null, made[1], made[3], crowd, made[6])
	rules.levels = {"evernight": 5, "slumber": 5}
	ctx.rules = rules
	rules.caster = func(sc: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		return FxTimeline.cast(sc, ctx, g, e)
	var fx := rules.cast(0, at) as EvernightFx
	t.check(fx != null and fx._twist, "a level-5 Evernight goes out through Rules")
	if fx != null:
		EV._until(fx, E.WAVE + DT)
		rules.advance(DT)
		var sl := rules.cast(1, x)
		t.check(sl != null, "and a level-5 Slumber after the wave")
		var cd := rules.cooldown_left(1)
		var ev := rules.cooldown_left(0)
		for i in 16:
			rules.advance(1.0)
		t.check(is_equal_approx(cd, 32.0) and rules.cooldown_left(1) <= 0.001, "Slumber (32 s) is ready after 16 s of game time (%.2f -> %.2f)" % [cd, rules.cooldown_left(1)])
		t.check(is_equal_approx(ev - rules.cooldown_left(0), 16.0), "Evernight's own slot is not hastened (%.2f)" % (ev - rules.cooldown_left(0)))
		if sl != null and is_instance_valid(sl):
			sl.end_now()
		fx.end_now()
	ctx.rules = null
	rules.free()


## end_now() and a freed cast in the last seconds: no light-field static of the cast left, no eye open, nobody flared.
static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	for mode in ["end_now", "free"]:
		var at := _begin(made)
		EV._put(crowd, at + Vector2(0.0, -6.0), true)
		EV._put(crowd, at + Vector2(12.0, 6.0), true)
		var fx := _cast(made, at)
		var id := fx.get_instance_id()
		EV._until(fx, fx.t_dawn - 2.0)
		var ids: Array[int] = []
		for tc in fx.torches:
			ids.append(int(tc.light))
		t.check(PaleEye.of(crowd).held_by(id) == 2 and not ids.has(0), "%s: in the last seconds two bearers eyed, two lights" % mode)
		if mode == "end_now":
			fx.end_now()
		else:
			fx.free()
		var left := 0
		for i in ids:
			if not EV._light(ctx.lights, i).is_empty():
				left += 1
		t.check(left == 0 and PaleEye.of(crowd).held_by(id) == 0, "%s: no light of the cast left, no eye open" % mode)


## No crowd, no field, no lights: builds and finishes.
static func _bare(t) -> void:
	var bare := FxContext.new()
	bare.overhead = Node2D.new()
	var fx := FxTimeline.cast(EvernightFx, bare, Vector2.ZERO, L5) as EvernightFx
	for i in roundi((fx.duration + 1.0) / 0.1):
		if fx.finished:
			break
		fx._process(0.1)
	t.check(fx.finished or fx.t >= fx.duration, "bare: builds and finishes without error")
	if is_instance_valid(fx):
		fx.end_now()
	bare.overhead.free()
