extends RefCounted
## Dragonfire ground fire, Task 4: the breath lays a strip of burning-ground patches along the swept arc (8 at level 1, 9/9/10,
## and two strips of 11 at level 5), from the arc and the golden ratio alone -- no rng -- and they outlive the cast.

const FxStage := preload("res://tests/fx_stage.gd")
const DragonFx := preload("res://src/fx/set2/dragonfire_parade.gd")
const PATH := "res://src/fx/set2/dragonfire_parade.gd"


static func run(t) -> void:
	_level_one(t)
	_levels(t)
	_no_rng(t)
	_town(t)
	_outlives(t)


static func _drop(bf: Battlefield) -> void:
	bf.ctx.field.clear()
	FxStage.drop(bf)


## Cast at `level` on a fresh stage seeded `seed_value`, and step it to the end of its breath(s) plus a little (not to its end).
static func _cast(level: int, seed_value := 5, to := -1.0) -> Array:
	var bf := FxStage.make(seed_value)
	var fx: DragonFx = FxTimeline.cast(load(PATH), bf.ctx, Vector2.ZERO, {"level": level})
	_step(fx, to if to > 0.0 else fx.lv_t_sink - 0.3)
	return [bf, fx]


static func _step(fx, to: float) -> void:
	while fx.t < to - 0.0001 and not fx.finished:
		fx._process(1.0 / 60.0)


static func _sprites(bf: Battlefield) -> int:
	var n := 0
	for c in bf.ctx.world.get_children():
		if c is GroundFireSprite:
			n += 1
	return n


static func _level_one(t) -> void:
	var made := _cast(1)
	var bf: Battlefield = made[0]
	var fx: DragonFx = made[1]
	t.check(fx.strips.size() == 1 and fx.strips[0].size() == 8 and fx.patches_laid == 8,
		"dragon_ground: level 1 lays one strip of 8 patches (%d strips, %d)" % [fx.strips.size(), fx.patches_laid])
	var ok := true
	var spaced := true
	var prev := -1.0
	for p: GroundFire in fx.strips[0]:
		var rel := p.at - fx.origin
		var a := angle_difference(fx._start_angle, rel.angle())
		ok = ok and rel.length() >= DragonFx.PATCH_NEAR - 0.01 and rel.length() <= DragonFx.PATCH_FAR + 0.01 \
			and a >= -0.05 and a <= fx.lv_sweep_arc + 0.05
		if prev >= 0.0 and absf(rel.length() - prev) < 1.0:
			spaced = false
		prev = rel.length()
	t.check(ok, "every patch lies %.1f..%.1f out and within the arc" % [DragonFx.PATCH_NEAR, DragonFx.PATCH_FAR])
	t.check(spaced, "no two consecutive patches lie within 1.0 of each other's distance")
	t.check(_sprites(bf) == 8, "eight GroundFireSprites stand in the world (%d)" % _sprites(bf))
	_drop(bf)


static func _levels(t) -> void:
	var want := {2: 9, 3: 9, 4: 10}
	for lv: int in want:
		var made := _cast(lv)
		var fx: DragonFx = made[1]
		t.check(fx.strips.size() == 1 and fx.strips[0].size() == want[lv],
			"level %d lays %d patches (%d)" % [lv, want[lv], fx.strips[0].size() if fx.strips.size() > 0 else -1])
		_drop(made[0])
	var made := _cast(5)
	var bf: Battlefield = made[0]
	var fx: DragonFx = made[1]
	t.check(fx.strips.size() == 2 and fx.strips[0].size() == 11 and fx.strips[1].size() == 11,
		"level 5 lays two strips of 11 (%d strips)" % fx.strips.size())
	var differ := false
	if fx.strips.size() == 2:
		for i in mini(fx.strips[0].size(), fx.strips[1].size()):
			var d0: float = (fx.strips[0][i].at - fx.origin).length()
			var d1: float = (fx.strips[1][i].at - fx.origin).length()
			if absf(d0 - d1) > 0.5:
				differ = true
	t.check(differ, "the second strip's distances differ from the first's (the phase)")
	_drop(bf)


static func _no_rng(t) -> void:
	var a := _cast(1, 5)
	var b := _cast(1, 99)
	var same: bool = a[1].strips[0].size() == b[1].strips[0].size()
	if same:
		for i in a[1].strips[0].size():
			same = same and (a[1].strips[0][i].at - b[1].strips[0][i].at).length() < 0.001
	t.check(same, "two casts with different rng seeds lay patches at the same points")
	_drop(a[0])
	_drop(b[0])


static func _town(t) -> void:
	var bf := FxStage.make(5)
	var crowd := Crowd.new()
	crowd.fires = FireManager.new().setup(crowd, bf.ctx.env, 4)
	bf.ctx.crowd = crowd
	var fx: DragonFx = FxTimeline.cast(load(PATH), bf.ctx, Vector2.ZERO, {"level": 1})
	_step(fx, fx.lv_t_sink - 0.3)
	var in_pool := crowd.fires.patches.size() == 8 and crowd.fires.patches_laid == 8
	var owned := true
	var danger := true
	for i in fx.strips[0].size():
		var p: GroundFire = fx.strips[0][i]
		in_pool = in_pool and crowd.fires.patches.has(p)
		owned = owned and p.owned
		danger = danger and p.threat_id >= 0
	t.check(in_pool and owned, "town: the patches are the fire manager's, owned (%d, laid %d)" % [crowd.fires.patches.size(), crowd.fires.patches_laid])
	t.check(danger, "and every patch's danger is registered")
	crowd.fires.clear()
	bf.ctx.crowd = null
	crowd.free()
	FxStage.drop(bf)


static func _outlives(t) -> void:
	var made := _cast(1)
	var bf: Battlefield = made[0]
	var fx: DragonFx = made[1]
	_step(fx, fx.duration + 0.5)
	t.check(fx.finished or fx.is_queued_for_deletion(), "the cast is over")
	var first: GroundFire = fx.strips[0][0]
	t.check(_sprites(bf) == 8 and not first.out, "the sprites remain after the cast and their patches still burn (%d)" % _sprites(bf))
	var held := DummyEnemy.new()
	held.ground_pos = first.at
	bf.ctx.field.add(held)
	var time := 0.0
	var sprite: GroundFireSprite = null
	for c in bf.ctx.world.get_children():
		if c is GroundFireSprite and c.patch == first:
			sprite = c
	while held.is_alive() and time < 3.0 and sprite != null:
		sprite.advance(0.1)
		time += 0.1
	t.check(not held.is_alive() and time <= 1.6, "a dummy in the first patch dies within 1.6 s (%.1f)" % time)
	_drop(bf)
