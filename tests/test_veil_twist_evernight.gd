extends RefCounted
## Evernight's level-5 twist, "The Light Gives Way" (Veil ability levels, VS 7 / VL14): every torch's light shrinks evenly from TORCH_R at
## the fall to END_R when the dawn begins, and every reader of "is he in the light" (a claim, a take's re-check, put_out(), a dusk laid over
## a torch, the light field) reads the radius at that moment; the huddle's slots stay level 1's; each bearer is eyed from the fall to the
## dawn. Level 4 does none of it.

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
	_radius(t, made)
	_claims(t, made)
	_huddle(t, made)
	_laid(t, made)
	_put_out_late(t, made)
	_eyes(t, made)
	_night_mission(t, made)
	_lights(t, made)
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


## torch_r(): 2.5 at the fall, 1.85 half way (WAVE + 34 of 68 s), 1.2 at t_dawn; level 4: 2.5 throughout.
static func _radius(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	for lv in [5, 4]:
		var at := _begin(made)
		EV._put(crowd, at + Vector2(0.0, -6.0), true)
		var fx := _cast(made, at, L5 if lv == 5 else L4)
		t.check(is_equal_approx(fx.night_time, 68.0) == (lv == 5) and fx._twist == (lv == 5), "level %d: night %.0f s, twist %s" % [lv, fx.night_time, fx._twist])
		EV._until(fx, E.WAVE + DT)
		var at_fall := fx.torch_r()
		EV._until(fx, E.WAVE + 34.0)
		var mid := fx.torch_r()
		EV._until(fx, fx.t_dawn - DT)
		var late := fx.torch_r()
		if lv == 5:
			t.check(absf(at_fall - 2.5) < 0.01 and absf(mid - 1.85) < 0.01 and absf(late - 1.2) < 0.02,
				"level 5: torch_r() 2.5 at the fall, 1.85 at WAVE + 34, 1.2 at the dawn (%.3f, %.3f, %.3f)" % [at_fall, mid, late])
		else:
			t.check(at_fall == 2.5 and mid == 2.5 and late == 2.5 and PaleEye.of(crowd) == null, "level 4: 2.5 throughout, no eye")
		fx.end_now()


## A citizen 2.0 from a torch is not claimable at the fall and is claimed on the first take's beat after the light has shrunk below 2.0.
static func _claims(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	for lv in [5, 4]:
		var at := _begin(made)
		var x := at + Vector2(0.0, -6.0)
		EV._put(crowd, x, true)
		var c := EV._put(crowd, x + Vector2(2.0, 0.0))
		var fx := _cast(made, at, L5 if lv == 5 else L4)
		EV._until(fx, E.WAVE + DT)
		var id := c.get_instance_id()
		t.check(not fx.claimed.has(id), "level %d: 2.0 from the torch is not claimable at the fall" % lv)
		EV._until(fx, E.WAVE + 28.0 + DT)
		if lv == 5:
			t.check(fx.claimed.has(id) or fx.taken.has(id), "level 5: by WAVE + 28 (the first claim beat after the light fell below 2.0) he is claimed")
			EV._until(fx, E.WAVE + 31.0)
			t.check(fx.taken.has(id), "level 5: and taken at the next take")
		else:
			EV._until(fx, E.WAVE + 40.0)
			t.check(not fx.claimed.has(id) and not fx.taken.has(id) and c.is_alive(), "level 4: never claimed in the light")
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


## A 0.5 patch laid 2.3 from a torch at WAVE + 60: it puts the torch out at level 4 (2.3 <= 0.5 + 2.5), not at level 5 (0.5 + about 1.35).
static func _laid(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	for lv in [4, 5]:
		var at := _begin(made)
		var x := at + Vector2(0.0, -6.0)
		EV._put(crowd, x, true)
		var fx := _cast(made, at, L5 if lv == 5 else L4)
		EV._until(fx, E.WAVE + 60.0)
		crowd.lay_dusk(x + Vector2(2.3, 0.0), 0.5, 5.0)
		t.check(fx.torches[0].out == (lv == 4), "level %d: a 0.5 patch 2.3 off at WAVE + 60 %s the torch (%.2f)" % [lv, "puts out" if lv == 4 else "leaves", fx.torch_r()])
		fx.end_now()


## put_out() late takes only those within torch_r(): one at 1.8 is out of the light by then and lives.
static func _put_out_late(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var x := at + Vector2(0.0, -6.0)
	var s := EV._put(crowd, x, true)
	var inner := EV._put(crowd, x + Vector2(0.8, 0.0))
	var outer := EV._put(crowd, x + Vector2(1.8, 0.0))
	for p in [inner, outer]:
		p.sleep(400.0, true)  # held where they stand: the take's claims pass them by
	var fx := _cast(made, at)
	EV._until(fx, E.WAVE + 37.0)  # the light is 1.79 now; the claim beat that would take him at 1.8 is at WAVE + 38
	fx.put_out(0)
	t.check(not inner.is_alive() and outer.is_alive() and not s.is_alive(), "level 5: put_out() late takes those within torch_r() and the bearer, not one at 1.8 (%s %s %s r %.2f)" % [inner.is_alive(), outer.is_alive(), s.is_alive(), fx.torch_r()])
	fx.end_now()


## Five bearers eyed from the fall (open-ended), none at the dawn; the record names the power.
static func _eyes(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	var spots := [Vector2(-24.0, -20.0), Vector2(-8.0, -20.0), Vector2(8.0, -20.0), Vector2(24.0, -20.0), Vector2(-24.0, 4.0), Vector2(-8.0, 4.0), Vector2(8.0, 4.0)]
	for sp in spots:
		EV._put(crowd, sp, true)
	var fx := _cast(made, at)
	var id := fx.get_instance_id()
	EV._until(fx, E.WAVE - DT)
	t.check(PaleEye.of(crowd) == null, "no eye before the fall")
	EV._until(fx, E.WAVE + DT)
	var eye := PaleEye.of(crowd)
	t.check(fx.torches.size() == 5 and eye != null and eye.held_by(id) == 5, "level 5: five torches, five bearers eyed (%d torches, eye %s, lv_torches %d)" % [fx.torches.size(), eye, fx.lv_torches])
	var all_eyed := true
	for tc in fx.torches:
		all_eyed = all_eyed and eye.is_eyed(instance_from_id(int(tc.bearer)) as Person)
	t.check(all_eyed and eye.record.size() == 5 and eye.record[0]["key"] == "evernight", "each torch's bearer, the record names Evernight")
	EV._until(fx, fx.t_dawn - DT)
	t.check(eye.held_by(id) == 5, "the eyes are still open just before the dawn")
	EV._until(fx, fx.t_dawn + DT)
	t.check(eye.held_by(id) == 0, "none at the dawn")
	fx.end_now()


## A NIGHT mission's night is 102 s at level 5: the light shrinks over all of it.
static func _night_mission(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _begin(made)
	crowd.night_mission = true
	crowd.sight_scale = NightRules.NIGHT_SIGHT
	EV._put(crowd, at + Vector2(0.0, -6.0), true)
	var fx := _cast(made, at, {"level": 5, "dark": true})
	t.check(is_equal_approx(fx.night_time, 102.0), "NIGHT: 102 s at level 5 (%.1f)" % fx.night_time)
	EV._until(fx, E.WAVE + 51.0)
	t.check(absf(fx.torch_r() - 1.85) < 0.01, "NIGHT: half way through 102 s the light is 1.85 (%.3f)" % fx.torch_r())
	EV._until(fx, fx.t_dawn - DT)
	t.check(absf(fx.torch_r() - 1.2) < 0.02, "NIGHT: 1.2 at the dawn")
	fx.end_now()
	crowd.night_mission = false


## The light field's static light follows the shrinking radius (re-added every LIGHT_STEP).
static func _lights(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	var at := _begin(made)
	EV._put(crowd, at + Vector2(0.0, -6.0), true)
	var fx := _cast(made, at)
	EV._until(fx, E.WAVE + DT)
	var l0 := EV._light(ctx.lights, int(fx.torches[0].light))
	t.check(not l0.is_empty() and is_equal_approx(float(l0.radius), 2.5), "the torch's light starts at 2.5")
	EV._until(fx, E.WAVE + 34.0)
	var l1 := EV._light(ctx.lights, int(fx.torches[0].light))
	t.check(not l1.is_empty() and float(l1.radius) < 2.0 and float(l1.radius) - fx.torch_r() < E.LIGHT_STEP + 0.001 and EV._light(ctx.lights, int(l0.id)).is_empty(),
		"half way the light field's torch is smaller (%.2f) and the old one is gone" % float(l1.radius))
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


## end_now() mid-night and a freed cast: no light-field static of the cast left, no eye open.
static func _teardown(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var ctx: FxContext = made[5]
	for mode in ["end_now", "free"]:
		var at := _begin(made)
		EV._put(crowd, at + Vector2(0.0, -6.0), true)
		EV._put(crowd, at + Vector2(12.0, 6.0), true)
		var fx := _cast(made, at)
		var id := fx.get_instance_id()
		EV._until(fx, E.WAVE + 30.0)
		var ids: Array[int] = []
		for tc in fx.torches:
			ids.append(int(tc.light))
		t.check(PaleEye.of(crowd).held_by(id) == 2 and not ids.has(0), "%s: mid-night two bearers eyed, two lights" % mode)
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
