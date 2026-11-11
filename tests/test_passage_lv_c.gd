extends RefCounted
## Passage ability levels, Tier 3: Door to the Deep and Mirrorfold Passage. Level 1 is the constants; each level reads
## its numbers from the PowerBook row; level 5 brings the twist. Door to the Deep's Standing Water: when the door has
## shut its water lies STAND seconds more -- nobody drawn in or taken, whoever is in it at half pace and for SOAKED_FOR
## after, fires in it kept out. Mirrorfold's Mirror Twins: whoever goes through leaves a glass twin at the way in that
## walks on toward where they meant to go, a decoy the town's hunters go for; struck, it shatters and its shards cut
## whoever stands by it; it counts for nobody.

const DEEP := "res://src/fx/control/door_to_the_deep.gd"
const MIRROR := "res://src/fx/control/mirrorfold_passage.gd"
const GlassTwins := preload("res://src/fx/control/glass_twins.gd")
const DeepT := preload("res://tests/test_deep.gd")
const HoundT := preload("res://tests/test_houndgate.gd")
const STEP := 0.05


static func _run(fx: FxTimeline, seconds: float) -> void:
	for k in roundi(seconds / STEP):
		fx._process(STEP)


static func _park(crowd: Crowd) -> void:
	var i := 0
	for person in crowd.citizens + crowd.soldiers:
		person.ground_pos = Vector2(-27.0 + float(i % 20) * 0.3, -27.0 + float(i / 20) * 0.3)
		i += 1


static func run(t) -> void:
	_deep(t)
	_mirror(t)


# --- Door to the Deep -------------------------------------------------------------------------------------------------

static func _deep(t) -> void:
	var made := HoundT._setup()
	var crowd: Crowd = made[0]
	var env: EnvironmentField = made[1]
	var grid: WalkGrid = made[2]
	var ctx: FxContext = made[5]
	_park(crowd)
	var site := DeepT._site(env, grid, grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center()))
	t.check(site != Vector2.INF, "deep lv: open ground for a whirlpool")
	var T_OPEN := DoorToTheDeepFx.T_OPEN
	var DRAIN := DoorToTheDeepFx.DRAIN

	# Level 1 is today's door: the constants, no standing water.
	var plain: DoorToTheDeepFx = FxTimeline.cast(load(DEEP), ctx, site)
	var one: DoorToTheDeepFx = FxTimeline.cast(load(DEEP), ctx, site, {"level": 1})
	for fx: DoorToTheDeepFx in [plain, one]:
		t.check(fx.lv_radius == DoorToTheDeepFx.RADIUS and fx.lv_span == DoorToTheDeepFx.SPAN
			and fx.lv_pull_core == DoorToTheDeepFx.PULL_CORE and not fx.standing
			and is_equal_approx(fx.duration, T_OPEN + DoorToTheDeepFx.SPAN + DRAIN + 0.3)
			and fx.reach(T_OPEN + DoorToTheDeepFx.SPAN + DRAIN + 0.01) == 0.0
			and is_equal_approx(fx.reach(T_OPEN + DoorToTheDeepFx.SPAN), DoorToTheDeepFx.RADIUS),
			"deep lv1: RADIUS 4, SPAN 25, PULL_CORE 0.75, its old length, and the water drains as it always did")
	t.check(is_equal_approx(DoorToTheDeepFx.pull_speed(1.0), DoorToTheDeepFx.pull_speed(1.0, DoorToTheDeepFx.RADIUS, DoorToTheDeepFx.PULL_CORE)),
		"deep lv1: the pull at the constants is the old pull")
	plain.free()
	one.free()

	# Level 4: the table's numbers, still no standing water.
	var four: DoorToTheDeepFx = FxTimeline.cast(load(DEEP), ctx, site, {"level": 4})
	t.check(is_equal_approx(four.lv_radius, 4.75) and is_equal_approx(four.lv_span, 30.0) and is_equal_approx(four.lv_pull_core, 0.9)
		and not four.standing and is_equal_approx(four.duration, T_OPEN + 30.0 + DRAIN + 0.3)
		and is_equal_approx(four.reach(T_OPEN + 30.0), 4.75),
		"deep lv4: RADIUS 4.75, SPAN 30, PULL_CORE 0.9, no standing water")
	four._process(T_OPEN + 30.0 + DRAIN + 0.1)
	var dry_walker: Person = crowd.citizens[0]
	DeepT._stand(dry_walker, site + Vector2(1.5, 0.0))
	var dry_pace := dry_walker.walk_speed
	four._process(0.6)
	t.check(four.reach(four.t) == 0.0 and dry_walker.pace_holds.is_empty() and is_equal_approx(dry_walker.walk_speed, dry_pace)
		and dry_walker.ground_pos == site + Vector2(1.5, 0.0), "deep lv4: once the door has shut the ground is dry: one walking in keeps his pace")
	four.free()
	dry_walker.ground_pos = Vector2(-27.0, -27.0)

	# Level 5: the numbers, and Standing Water.
	var five: DoorToTheDeepFx = FxTimeline.cast(load(DEEP), ctx, site, {"level": 5})
	var STAND := DoorToTheDeepFx.STAND
	var SOAKED_FOR := DoorToTheDeepFx.SOAKED_FOR
	t.check(is_equal_approx(five.lv_radius, 5.0) and is_equal_approx(five.lv_span, 31.0) and is_equal_approx(five.lv_pull_core, 0.95)
		and five.standing and is_equal_approx(five.shut_at(), T_OPEN + 31.0 + DRAIN)
		and is_equal_approx(five.duration, T_OPEN + 31.0 + DRAIN + STAND + SOAKED_FOR + 0.3),
		"deep lv5: RADIUS 5, SPAN 31, PULL_CORE 0.95, and the water stands STAND s after the door shuts")
	t.check(is_equal_approx(five.reach(five.shut_at() + 10.0), 5.0) and five.force(five.shut_at() + 10.0) == 0.0
		and five.stands(five.shut_at() + 10.0) and five.reach(five.stand_end() + 0.01) == 0.0
		and five.reach(five.stand_end() - DoorToTheDeepFx.STAND_FADE * 0.5) < 5.0,
		"deep lv5: after the shut the circle is still flooded, the torrent gone; it soaks away at the end")
	t.check(is_equal_approx(five.force(T_OPEN + 31.0 + DRAIN * 0.5), 0.5),
		"deep lv5: the torrent dies with the door over the drain, though the water stays")
	five._process(five.shut_at() + 1.0)
	t.check(five.reach(five.t) == 5.0 and five.opening() == 0.0, "deep lv5: a second after the shut the door is closed and the circle full of water")
	var wader: Person = crowd.citizens[1]
	var on_door: Person = crowd.citizens[2]
	DeepT._stand(wader, site + Vector2(3.0, 0.0))
	DeepT._stand(on_door, site + Vector2(0.3, 0.0))
	var pace := wader.walk_speed
	var on_door_pace := on_door.walk_speed
	var drowned := five.drowned
	var shed := env.add_structure(Rect2(site + Vector2(1.6, -2.4), Vector2(0.6, 0.6)), 18.0, Structure.Kind.HOUSE, &"house")
	crowd.fires.ignite(shed, 0.6)
	var shed_hp := shed.hp
	_run(five, 1.0)
	t.check(wader.is_alive() and wader.ground_pos == site + Vector2(3.0, 0.0) and on_door.is_alive()
		and on_door.ground_pos == site + Vector2(0.3, 0.0) and five.drowned == drowned,
		"deep lv5: in the standing water nobody is drawn in or taken, not even one standing on the shut door")
	t.check(is_equal_approx(wader.pace_hold(), DoorToTheDeepFx.STAND_SLOW)
		and DeepT._about(wader.walk_speed, 0.5 * pace, 0.05),
		"deep lv5: one who walks into it is soaked and walks at half pace (%.2f of %.2f)" % [wader.walk_speed, pace])
	_run(five, 5.0)
	t.check(not crowd.fires.is_burning(shed) and five.doused >= 1, "deep lv5: a fire in the standing water goes out")
	t.check(is_equal_approx(shed.hp, shed_hp), "deep lv5: the standing water soaks no wall")
	# He walks out: soaked SOAKED_FOR more.
	wader.ground_pos = site + Vector2(6.5, 0.0)
	_run(five, SOAKED_FOR - 0.5)
	t.check(not wader.pace_holds.is_empty() and DeepT._about(wader.walk_speed, 0.5 * pace, 0.05),
		"deep lv5: out of the water he is still soaked and slow %.1f s later" % (SOAKED_FOR - 0.5))
	_run(five, 1.1)
	t.check(wader.pace_holds.is_empty() and is_equal_approx(wader.walk_speed, pace),
		"deep lv5: SOAKED_FOR after leaving it he has his pace back")
	crowd.fires.ignite(shed, 0.6)
	_run(five, 2.0)
	t.check(not crowd.fires.is_burning(shed), "deep lv5: a fire lit in it later is put out too")
	# The water soaks away; the one still standing in it is soaked SOAKED_FOR more, then dry.
	_run(five, five.stand_end() + 0.1 - five.t)
	t.check(five.reach(five.t) == 0.0 and not on_door.pace_holds.is_empty() and on_door.is_alive(),
		"deep lv5: at STAND the water is gone; the one who stood in it is soaked still")
	_run(five, SOAKED_FOR + 0.5)
	t.check(five.finished and on_door.pace_holds.is_empty() and is_equal_approx(on_door.walk_speed, on_door_pace),
		"deep lv5: SOAKED_FOR after that he is dry and the door is done")
	five.free()

	# Cut short in the standing water: nobody left slowed.
	var cut: DoorToTheDeepFx = FxTimeline.cast(load(DEEP), ctx, site, {"level": 5})
	cut._process(cut.shut_at() + 1.0)
	DeepT._stand(wader, site + Vector2(2.0, 0.0))
	cut._process(0.6)
	var was_slow := not wader.pace_holds.is_empty()
	cut.end_now()
	t.check(was_slow and wader.pace_holds.is_empty() and is_equal_approx(wader.walk_speed, pace),
		"deep lv5: cut short, the standing water leaves nobody slowed")
	cut.free()
	HoundT._done(made)


# --- Mirrorfold Passage -----------------------------------------------------------------------------------------------

static func _cast_mirror(ctx: FxContext, a: Vector2, dir: Vector2, len: float, b: Vector2, level: int) -> MirrorfoldFx:
	var extra := {"dir": dir, "length": len, "to": b}
	if level > 0:
		extra["level"] = level
	return FxTimeline.cast(load(MIRROR), ctx, a, extra)


static func _twins_in(field: EnemyField) -> int:
	var n := 0
	for e in field.alive():
		if GlassTwins.is_twin(e):
			n += 1
	return n


## `p` walks onto the way in at `on`, fleeing to the nearest way out of the town; one step of the passage.
static func _cross(fx: MirrorfoldFx, grid: WalkGrid, p: Person, on: Vector2) -> void:
	p.ground_pos = on + Vector2(0.0, 3.0)
	p.flee()
	p.set_goal(grid.nearest_exit(on))
	p.ground_pos = on
	fx._process(STEP)


static func _mirror(t) -> void:
	var made := HoundT._setup()
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	var field: EnemyField = made[3]
	var world: Node2D = made[4]
	var ctx: FxContext = made[5]
	_park(crowd)
	var a := Vector2(2.75, 11.25)  # the Main Gate's plaza
	var dir := Vector2(1, 0)
	var side: Vector2 = MirrorfoldFx.side_of(dir)
	var b := grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center()) - dir * 2.0
	var citizens := crowd.citizens.size()
	var soldiers := crowd.soldiers.size()
	var killed_c := crowd.killed_citizens
	var killed_s := crowd.killed_soldiers

	# Level 1: the constants, no twins.
	var plain := _cast_mirror(ctx, a, dir, 10.0, b, 0)
	var one := _cast_mirror(ctx, a, dir, 10.0, b, 1)
	for fx: MirrorfoldFx in [plain, one]:
		t.check(fx.length == MirrorfoldFx.MAX_LEN and fx.duration == MirrorfoldFx.MIRROR_TIME and fx.twins == null,
			"mirror lv1: a drag of 10 lays a lane of MAX_LEN 6; it stands MIRROR_TIME 30 s; no twins")
	one.end_now()
	one.free()
	var w1: Person = crowd.citizens[0]
	var field_n := field.alive().size()
	_cross(plain, grid, w1, a + dir * 2.0)
	t.check(plain.folded == 1 and field.alive().size() == field_n and _twins_in(field) == 0,
		"mirror lv1: one goes through and nothing is left behind")
	plain._process(MirrorfoldFx.MIRROR_TIME)
	t.check(plain.finished, "mirror lv1: gone at MIRROR_TIME")
	plain.free()
	_park(crowd)

	# Level 4: the table's numbers, no twins.
	var four := _cast_mirror(ctx, a, dir, 10.0, b, 4)
	t.check(is_equal_approx(four.length, 7.5) and is_equal_approx(four.duration, 38.0) and four.twins == null,
		"mirror lv4: MAX_LEN 7.5, MIRROR_TIME 38, no twins")
	_cross(four, grid, w1, a + dir * 2.0)
	t.check(four.folded == 1 and _twins_in(field) == 0, "mirror lv4: one goes through and leaves no twin")
	four.end_now()
	four.free()
	_park(crowd)

	# Level 5: the numbers, and Mirror Twins.
	var five := _cast_mirror(ctx, a, dir, 10.0, b, 5)
	t.check(is_equal_approx(five.length, 8.0) and is_equal_approx(five.lv_mirror_time, 40.0)
		and is_equal_approx(five.duration, 40.0 + GlassTwins.TWIN_TIME) and five.twins != null,
		"mirror lv5: MAX_LEN 8, MIRROR_TIME 40, and twins (the passage runs on TWIN_TIME for them)")
	var walker: Person = crowd.citizens[1]
	var from := a + dir * 2.0 + side * 0.2
	_cross(five, grid, walker, from)
	var aim := walker.goal()
	var twins: Array = five.twins.living()
	t.check(five.folded == 1 and twins.size() == 1 and walker.ground_pos.distance_to(b + dir * 2.0 + side * 0.2) < 0.75,
		"mirror lv5: one goes through to the way out, and one twin is left")
	var twin: Person = twins[0] if twins.size() > 0 else null
	t.check(twin != null and twin.ground_pos.is_equal_approx(from) and field.alive().has(twin) and not crowd.citizens.has(twin)
		and not crowd.soldiers.has(twin) and crowd.citizens.size() == citizens and GlassTwins.is_twin(twin),
		"mirror lv5: the twin stands at the way in where he stepped on: in the field, not in the crowd")
	t.check(twin != null and twin.is_alive() and not twin.inside and twin.visible,
		"mirror lv5: to the town it is a living person out in the open")
	var start_d := twin.ground_pos.distance_to(aim) if twin != null else 0.0
	_run(five, 1.0)
	t.check(twin != null and is_instance_valid(twin) and twin.ground_pos.distance_to(from) > 0.3
		and twin.ground_pos.distance_to(aim) < start_d - 0.3 and five.folded == 1,
		"mirror lv5: it walks on toward where he meant to go, and the passage does not carry it (%.2f nearer)"
			% (start_d - twin.ground_pos.distance_to(aim) if twin != null else 0.0))

	# A hound bites it: it shatters, and its shards cut those beside it.
	var visitors := Visitors.new().setup(field, crowd, grid, world)
	var by: Person = crowd.citizens[2]
	var guard: Person = crowd.soldiers[0]
	DeepT._stand(by, twin.ground_pos + Vector2(-0.5, 0.0))
	guard.ground_pos = twin.ground_pos + Vector2(0.0, 0.5)
	var far: Person = crowd.citizens[3]
	DeepT._stand(far, twin.ground_pos + Vector2(-1.5, 0.0))
	var hound := visitors.summon(twin.ground_pos + Vector2(0.3, 0.0), Animal.Breed.HELLHOUND, 4, 1.0, 8.0, 0.5, 1.0, false)
	t.check(visitors._nearest(hound.ground_pos, 8.0, null) == twin, "mirror lv5: the hound's nearest prey is the twin")
	var by_hp := by.health
	var guard_hp := guard.health
	visitors.step(STEP)
	t.check(twin.broken and not field.alive().has(twin) and five.twins.shattered == 1 and five.twins.living().is_empty(),
		"mirror lv5: bitten, the twin shatters and is gone from the field")
	t.check(by.is_alive() and by.health < by_hp and guard.is_alive() and guard.health < guard_hp and five.twins.cut == 2,
		"mirror lv5: its shards cut the citizen and the soldier within %.1f (%.2f, %.2f)" % [GlassTwins.SHARD_R, by.health, guard.health])
	t.check(far.is_alive() and is_equal_approx(far.health, Person.HEALTH_CITIZEN), "mirror lv5: one further off is not cut")
	t.check(visitors.kills == 0 and crowd.killed_citizens == killed_c and crowd.killed_soldiers == killed_s,
		"mirror lv5: the twin's breaking counts for nobody: no hound kill, no death in the town")
	visitors.clear()
	five._process(STEP)
	t.check(not is_instance_valid(twin) or not twin.is_alive(), "mirror lv5: the broken twin is taken away")
	for p: Person in [by, guard, far]:
		p.ground_pos = Vector2(-27.0, -27.0)

	# A maddened frenzy goes for a twin as for anyone.
	var w2: Person = crowd.citizens[4]
	_cross(five, grid, w2, a + dir * 5.0)
	var twin2: Person = five.twins.living()[0] if five.twins.living().size() > 0 else null
	var mad: Person = crowd.citizens[5]
	DeepT._stand(mad, twin2.ground_pos + Vector2(0.0, 0.3))
	mad.fight(null, 15.0, 0.5, Person.FightRule.ANYONE, Person.FIGHT_SIGHT, &"madness")
	for k in 10:
		if twin2.broken:
			break
		mad._fight_step(STEP)
	t.check(twin2 != null and twin2.broken and mad.is_alive() and crowd.killed_citizens == killed_c,
		"mirror lv5: a frenzy strikes the twin, which shatters; no death is counted")
	mad.stop_fighting()
	mad.ground_pos = Vector2(-27.0, -27.0)
	five._process(STEP)

	# Twins vanish after TWIN_TIME.
	var w3: Person = crowd.citizens[6]
	_cross(five, grid, w3, a + dir * 3.0 - side * 0.2)
	t.check(five.twins.living().size() == 1, "mirror lv5: another crossing, another twin")
	_run(five, GlassTwins.TWIN_TIME - 0.5)
	t.check(five.twins.living().size() == 1, "mirror lv5: it walks on for its time")
	_run(five, 0.6)
	t.check(five.twins.living().is_empty() and _twins_in(field) == 0, "mirror lv5: after TWIN_TIME the twin is gone from the town")
	five.end_now()
	five.free()
	_park(crowd)

	# At most MAX_TWINS at once.
	var many := _cast_mirror(ctx, a, dir, 8.0, b, 5)
	for k in GlassTwins.MAX_TWINS + 2:
		var p: Person = crowd.citizens[10 + k]
		_cross(many, grid, p, a + dir * (0.4 + 0.3 * float(k)) + side * (0.1 if k % 2 == 0 else -0.1))
	t.check(many.folded > GlassTwins.MAX_TWINS and many.twins.living().size() == GlassTwins.MAX_TWINS
		and many.twins.made == GlassTwins.MAX_TWINS and _twins_in(field) == GlassTwins.MAX_TWINS,
		"mirror lv5: %d go through, %d twins stand (MAX_TWINS)" % [many.folded, many.twins.living().size()])
	# The passage ends at its time; the twins walk on, then all is gone.
	_run(many, 40.0 + 0.1 - many.t)
	t.check(not field.portals.has(many) and not many.finished and field.through(a + dir * 1.0) == a + dir * 1.0,
		"mirror lv5: at MIRROR_TIME the passage is no portal any more, though it runs on for its twins")
	_run(many, many.duration - many.t + 0.1)
	t.check(many.finished and _twins_in(field) == 0 and field.portals.is_empty(), "mirror lv5: at the end nothing of it is left")
	many.free()
	# Cut short with twins standing: all taken.
	var cut := _cast_mirror(ctx, a, dir, 8.0, b, 5)
	_park(crowd)
	_cross(cut, grid, crowd.citizens[7], a + dir * 1.0)
	t.check(_twins_in(field) == 1, "mirror lv5: a twin stands")
	cut.end_now()
	t.check(_twins_in(field) == 0 and cut.finished, "mirror lv5: cut short, its twins are gone with it")
	cut.free()
	t.check(crowd.citizens.size() == citizens and crowd.soldiers.size() == soldiers and crowd.killed_citizens == killed_c
		and crowd.killed_soldiers == killed_s, "mirror lv5: the crowd's numbers never moved for the twins")
	HoundT._done(made)
