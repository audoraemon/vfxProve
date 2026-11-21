extends RefCounted
## Dread of the Dark (Veil, Tier 4; spec 5.7): T_FALL after the click and for 25 s, the dark ground within 6 (12 in the dark) of the
## click is dreaded. Who stands in it freezes, silent, no witness; a soldier there neither fights nor seizes. Nobody outside steps in:
## he waits at its edge and walks on when it ends. Lit ground in reach is not dreaded. A shadow is not afraid of it. Asleep beats
## frozen. No dark ground in reach: the cast is refused ("no_dark") and spends no cooldown. Two Dreads never undo each other, and
## a Dread cut short or freed lets everyone go. Quiet; its dusk is laid at the click when it lifts (VC1).

const RD := preload("res://tests/test_raise_dead.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05


static func _cast(ctx: FxContext, at: Vector2, extra := {}) -> DreadOfTheDarkFx:
	return FxTimeline.cast(DreadOfTheDarkFx, ctx, at, extra) as DreadOfTheDarkFx


## A calm town, the ledger on and empty, no dread, no night: open walkable ground at the market with nobody within 14.
static func _fresh(made: Array) -> Vector2:
	RD._clear_all(made)
	var crowd: Crowd = made[0]
	crowd.dusk.clear()
	crowd.dusk.enabled = true
	crowd.night_mission = false
	crowd.dreads.clear()
	crowd._veils.clear()
	var grid: WalkGrid = made[2]
	return grid.nearest_walkable(TownLayout.MARKET_SQUARE.get_center())


## The nth citizen, set down at `at`, calm and standing.
static func _put(crowd: Crowd, n: int, at: Vector2) -> Person:
	var p: Person = crowd.citizens[n]
	Kit.arrive(p, at)
	p.mind = Person.Mind.CALM
	p.walk_speed = 1.0
	if p.is_asleep():
		p.wake()
	return p


## Steps the cast and `people` (their walk: Person.tick) for `seconds`; returns the least distance any of `people` came to `watch`.
static func _go(fx: FxTimeline, seconds: float, people: Array = [], watch := Vector2.INF) -> float:
	var least := INF
	for i in roundi(seconds / DT):
		for p in people:
			if is_instance_valid(p):
				(p as Person).tick(DT)
				if watch != Vector2.INF:
					least = minf(least, (p as Person).ground_pos.distance_to(watch))
		if fx != null and is_instance_valid(fx) and not fx.finished:
			fx._process(DT)
	return least


static func run(t) -> void:
	_book(t)
	var made := RD._setup()
	_held(t, made)
	_edge(t, made)
	_lit(t, made)
	_reach(t, made)
	_refused(t, made)
	_night(t, made)
	_shadow(t, made)
	_sleep(t, made)
	_evernight_and_two(t, made)
	_teardown(t, made)
	_quiet(t, made)
	_look(t, made)
	_wall_halves(t, made)
	RD._done(made)
	_seizer(t)
	_no_crowd(t)


static func _book(t) -> void:
	var p := PowerBook.get_power("dread")
	t.check(not p.is_empty() and String(p.get("authority", "")) == "veil" and String(p.aim) == "click" and float(p.cooldown) == 70.0,
		"the row: Veil, a click, 70 s (%s)" % [p])
	t.check(DreadOfTheDarkFx.HOLD == 25.0 and DreadOfTheDarkFx.T_FALL == 0.8, "holds 25 s, falls at 0.8 s")
	t.check(VeilRules.size("dread", "REACH", false) == 6.0 and VeilRules.size("dread", "REACH", true) == 12.0, "reach 6 in the light, 12 in the dark")


## Dusk at D, 4 from the click: who stands in D is dreaded for 25 s -- he does not move, is no witness; a soldier there takes no fight.
static func _held(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var p := _put(crowd, 10, d)
	var s: Person = crowd.soldiers[1]
	Kit.arrive(s, d + Vector2(0.4, 0.3))
	s.send_to_post(s.ground_pos)
	var foe := _put(crowd, 11, d + Vector2(1.5, 1.0))
	t.check(crowd.nearest_witness(d) == p, "control: the one standing in D is its witness")
	s.fight(foe, 10.0, 0.5)
	t.check(s.mind == Person.Mind.FIGHT, "control: the soldier would fight")
	s.stop_fighting()
	s.send_to_post(s.ground_pos)
	var fx := _cast(made[5], at)
	_go(fx, 0.5)
	t.check(not p.is_dreaded() and crowd.dreads.is_empty(), "before T_FALL nothing is dreaded yet")
	_go(fx, DreadOfTheDarkFx.T_FALL - 0.5 + DT)
	t.check(p.is_dreaded() and s.is_dreaded() and crowd.dreaded(d), "at the fall the one in D and the soldier there are dreaded")
	t.check(not foe.is_dreaded(), "the foe outside the dusk is not")
	t.check(crowd.nearest_witness(d) != p and crowd.nearest_witness(d) != s, "the dreaded are no witness")
	s.fight(foe, 10.0, 0.5)
	t.check(s.mind != Person.Mind.FIGHT, "the dreaded soldier takes no fight")
	var goal := (made[2] as WalkGrid).nearest_walkable(at + Vector2(4.0, 4.0))
	p.set_goal(goal)
	var from := p.ground_pos
	_go(fx, 24.0, [p])
	t.check(p.ground_pos.distance_to(from) < 0.001 and p.is_dreaded(), "24 s on he has not moved and is still dreaded (%.3f)" % p.ground_pos.distance_to(from))
	_go(fx, 1.0, [p])
	t.check(not p.is_dreaded() and not s.is_dreaded() and not crowd.dreaded(d) and crowd.dreads.is_empty() and not p.has_meta(&"dread_owners"),
		"at 25 s the dread lifts: everyone free, the crowd's dread gone")
	_go(fx, 1.0, [p])
	t.check(fx.finished, "and the effect ends")
	t.check(p.ground_pos.distance_to(from) > 0.2, "freed, he walks on (%.2f)" % p.ground_pos.distance_to(from))


## Who walks toward D from outside stops at its edge and never enters while it lasts; when it ends he walks on.
static func _edge(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var w := _put(crowd, 12, d + Vector2(0.0, 3.5))
	var goal := d + Vector2(0.0, -3.5)
	var grid: WalkGrid = made[2]
	t.check(grid.walkable(w.ground_pos) and grid.walkable(goal) and grid.walkable(d), "(the ground through D is open)")
	var fx := _cast(made[5], at)
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	w.set_goal(goal)
	var least := _go(fx, 8.0, [w], d)
	t.check(least >= 1.5 - 0.01 and not w.is_dreaded(), "he never steps into D (closest %.2f)" % least)
	t.check(w.ground_pos.distance_to(d) < 2.2, "he waits at its edge (%.2f from D)" % w.ground_pos.distance_to(d))
	fx.end_now()
	least = _go(null, 8.0, [w], d)
	t.check(least < 1.0, "the dread ended: he walks on through (closest %.2f)" % least)


## Lit ground inside the reach is not dreaded: one there walks freely.
static func _lit(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	crowd.lay_dusk(at + Vector2(4.0, 0.0), 1.5, 120.0)
	var l := _put(crowd, 13, at + Vector2(-4.0, 0.0))
	var fx := _cast(made[5], at)
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(not l.is_dreaded() and not crowd.dreaded(l.ground_pos), "lit ground within 6 is not dreaded")
	l.set_goal((made[2] as WalkGrid).nearest_walkable(at + Vector2(-4.0, 3.0)))
	var from := l.ground_pos
	_go(fx, 2.0, [l])
	t.check(l.ground_pos.distance_to(from) > 0.5, "he walks freely (%.2f)" % l.ground_pos.distance_to(from))
	fx.end_now()


## Light reach 6: dusk at 7 is untouched; dark reach 12: it is dreaded.
static func _reach(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	crowd.lay_dusk(at + Vector2(4.0, 0.0), 1.5, 120.0)
	crowd.lay_dusk(at + Vector2(0.0, 7.0), 0.5, 120.0)
	var e := _put(crowd, 14, at + Vector2(0.0, 7.0))
	var light := _cast(made[5], at)
	_go(light, DreadOfTheDarkFx.T_FALL + DT)
	t.check(light.reach == 6.0 and not e.is_dreaded(), "light: the dusk at 7 is untouched")
	light.end_now()
	var dark := _cast(made[5], at, {"dark": true})
	_go(dark, DreadOfTheDarkFx.T_FALL + DT)
	t.check(dark.reach == 12.0 and e.is_dreaded(), "dark: reach 12, the one at 7 is dreaded")
	dark.end_now()
	t.check(not e.is_dreaded(), "(ended)")


## No dark ground within reach: refused "no_dark", no cooldown spent; with dark in reach it goes and the 70 s start.
static func _refused(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	t.check(DreadOfTheDarkFx.refusal(crowd, at, false) == "no_dark", "nothing dark: no_dark")
	t.check(DreadOfTheDarkFx.refusal(null, at, false) == "", "no crowd: nothing to judge, it goes")
	t.check(DreadOfTheDarkFx.refusal(crowd, at, true) == "", "a cast stamped dark stands on dark ground")
	var far := crowd.lay_dusk(at + Vector2(7.0, 0.0), 0.5, 120.0)
	t.check(DreadOfTheDarkFx.refusal(crowd, at, false) == "no_dark", "dusk wholly past 6: still no_dark")
	crowd.dusk.end(far)
	crowd.lay_dusk(at + Vector2(6.8, 0.0), 1.0, 120.0)
	t.check(DreadOfTheDarkFx.refusal(crowd, at, false) == "", "dusk reaching into the 6: allowed")
	crowd.dusk.clear()
	crowd.veil(at + Vector2(0.0, 6.5), 1.0, 30.0)
	t.check(DreadOfTheDarkFx.refusal(crowd, at, false) == "", "Unseen Hour's veil reaching in: allowed")
	crowd._veils.clear()
	crowd.night_mission = true
	t.check(DreadOfTheDarkFx.refusal(crowd, at, false) == "", "a NIGHT mission: allowed")
	crowd.night_mission = false
	crowd.dusk.everywhere = true
	t.check(DreadOfTheDarkFx.refusal(crowd, at, false) == "", "Evernight: allowed")
	crowd.dusk.everywhere = false
	var rules := Rules.new().setup(PackedStringArray(["dread"]), null, made[1], made[3], crowd, made[6])
	var casts: Array = []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append(fx)
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var got := rules.cast(0, at)
	t.check(got == null and refused == [[0, "no_dark"]] and rules.cooldown_left(0) == 0.0 and casts.is_empty(),
		"Rules refuses it: no_dark, no cooldown spent (%s, %.1f)" % [refused, rules.cooldown_left(0)])
	refused.clear()
	crowd.lay_dusk(at + Vector2(4.0, 0.0), 1.5, 120.0)
	got = rules.cast(0, at)
	t.check(got != null and refused.is_empty() and is_equal_approx(rules.cooldown_left(0), 70.0),
		"control: dusk in reach, it goes and the 70 s cooldown starts (%s)" % [refused])
	if got != null:
		got.end_now()
	rules.free()
	_unlocks(t, made, at)


## C16: through Rules, Dread locks the other slots only until it falls (busy = T_FALL); then another power casts while it runs.
static func _unlocks(t, made: Array, at: Vector2) -> void:
	var crowd: Crowd = made[0]
	crowd.lay_dusk(at + Vector2(4.0, 0.0), 1.5, 120.0)
	var rules := Rules.new().setup(PackedStringArray(["dread", "doom"]), null, made[1], made[3], crowd, made[6])
	var casts: Array = []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		casts.append(fx)
		return fx
	var refused: Array = []
	rules.cast_refused.connect(func(slot: int, why: String) -> void: refused.append([slot, why]))
	var dread := rules.cast(0, at) as DreadOfTheDarkFx
	t.check(dread != null and refused.is_empty(), "Dread goes out over the laid dusk (%s)" % [refused])
	if dread == null:
		rules.free()
		return
	var far := at + Vector2(-8.0, 0.0)
	_go(dread, 0.4)
	var early := rules.cast(1, far)
	t.check(rules.busy_left() > 0.0 and early == null and refused == [[1, "busy"]] and casts.size() == 1,
		"before T_FALL the other slots are locked (busy %.2f, %s)" % [rules.busy_left(), refused])
	refused.clear()
	_go(dread, DreadOfTheDarkFx.T_FALL - 0.4 + DT)
	var later := rules.cast(1, far)
	t.check(later != null and refused.is_empty() and not dread.finished and not crowd.dreads.is_empty(),
		"after T_FALL Silent Doom casts while Dread still holds (%s)" % [refused])
	if later != null and is_instance_valid(later):
		later.end_now()
	dread.end_now()
	rules.free()


## A NIGHT mission: everyone within 12 of the click is dreaded; one at 13 is not.
static func _night(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	crowd.night_mission = true
	var ps: Array[Person] = []
	var spots := [Vector2(1.0, 0.0), Vector2(-5.0, 2.0), Vector2(0.0, -8.0), Vector2(8.0, 8.0)]
	for i in spots.size():
		ps.append(_put(crowd, 20 + i, at + spots[i]))
	var out := _put(crowd, 30, at + Vector2(13.0, 0.0))
	var fx := _cast(made[5], at, {"dark": crowd.in_dark(at)})
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(fx.reach == 12.0 and ps.all(func(p: Person) -> bool: return p.is_dreaded()), "NIGHT: all four within 12 are dreaded")
	t.check(not out.is_dreaded(), "one at 13 is not")
	fx.end_now()
	crowd.night_mission = false
	t.check(not ps.any(func(p: Person) -> bool: return p.is_dreaded()), "(ended)")


## A shadow walks through dreaded ground and is not frozen.
static func _shadow(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var inside := _put(crowd, 15, d)
	inside.statuses[&"shadow"] = 60.0
	var walker := _put(crowd, 16, d + Vector2(0.0, 3.5))
	walker.statuses[&"shadow"] = 60.0
	var fx := _cast(made[5], at)
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(crowd.dreaded(d) and not inside.is_dreaded() and not walker.is_dreaded(), "a shadow in the dread is not frozen")
	walker.set_goal(d + Vector2(0.0, -3.5))
	var least := _go(fx, 8.0, [walker], d)
	t.check(least < 1.0 and not walker.is_dreaded(), "a shadow walks through dreaded ground (closest %.2f)" % least)
	fx.end_now()
	inside.statuses.erase(&"shadow")
	walker.statuses.erase(&"shadow")


## Asleep beats frozen: the frozen put to sleep sleep, and wake free if the dread has ended (held still if not); a sleeper is not
## frozen while he sleeps, and is once he wakes inside.
static func _sleep(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var p := _put(crowd, 17, d)
	var q := _put(crowd, 18, d + Vector2(0.5, 0.0))
	var sleeper := _put(crowd, 19, d + Vector2(-0.5, 0.0))
	sleeper.sleep(20.0, true)
	var fx := _cast(made[5], at)
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(p.is_dreaded() and q.is_dreaded(), "two frozen")
	t.check(sleeper.is_asleep() and not sleeper.is_dreaded(), "a sleeper is not frozen")
	p.sleep(20.0, true)
	q.sleep(20.0, true)
	_go(fx, 1.0)
	t.check(p.is_asleep() and p.mind == Person.Mind.ASLEEP and p.is_dreaded(), "frozen, then put to sleep: he sleeps")
	q.wake()
	var goal := (made[2] as WalkGrid).nearest_walkable(at + Vector2(4.0, 4.0))
	q.set_goal(goal)
	var qfrom := q.ground_pos
	_go(fx, 1.0, [q])
	t.check(q.is_dreaded() and q.ground_pos.distance_to(qfrom) < 0.001, "woken while the dread lasts: still frozen")
	sleeper.wake()
	_go(fx, DT)
	t.check(sleeper.is_dreaded(), "the sleeper woken inside the dread is frozen now")
	fx.end_now()
	t.check(not p.is_dreaded() and not q.is_dreaded() and not sleeper.is_dreaded(), "the dread ended")
	p.wake()
	p.set_goal(goal)
	var from := p.ground_pos
	_go(null, 3.0, [p])
	t.check(not p.is_asleep() and p.ground_pos.distance_to(from) > 0.2, "he wakes free and walks (%.2f)" % p.ground_pos.distance_to(from))


## Evernight starting during a Dread does not end it (and the whole circle is dark then); two Dreads: ending the first leaves the
## second's people held.
static func _evernight_and_two(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var p := _put(crowd, 24, d)
	var l := _put(crowd, 25, at + Vector2(-4.0, 0.0))
	var fx := _cast(made[5], at)
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(p.is_dreaded() and not l.is_dreaded(), "control: D frozen, lit ground free")
	crowd.dusk.everywhere = true
	_go(fx, 1.0)
	t.check(not fx.finished and not crowd.dreads.is_empty() and p.is_dreaded(), "Evernight falls: the Dread goes on")
	t.check(l.is_dreaded(), "and the whole circle is dark now: the lit one freezes too")
	crowd.dusk.everywhere = false
	_go(fx, DT)
	t.check(p.is_dreaded() and not l.is_dreaded(), "its dark gone, he is free again")
	fx.end_now()
	var a := _cast(made[5], at)
	var b := _cast(made[5], at)
	_go(a, DreadOfTheDarkFx.T_FALL + DT)
	_go(b, DreadOfTheDarkFx.T_FALL + DT)
	t.check(p.is_dreaded() and (p.get_meta(&"dread_owners", {}) as Dictionary).size() == 2, "two Dreads hold him")
	a.end_now()
	t.check(p.is_dreaded() and crowd.dreaded(d), "the first ended: the second still holds him")
	_go(b, 1.0, [p])
	t.check(p.is_dreaded(), "and goes on holding him")
	b.end_now()
	t.check(not p.is_dreaded() and not crowd.dreaded(d), "the second ended: free")


## end_now() and a freed node both free every person and end the dread; a second Dread elsewhere keeps its own (control).
static func _teardown(t, made: Array) -> void:
	for mode in ["end_now", "free"]:
		var crowd: Crowd = made[0]
		var at := _fresh(made)
		var d := at + Vector2(4.0, 0.0)
		var far := at + Vector2(0.0, -30.0)
		crowd.lay_dusk(d, 1.5, 120.0)
		crowd.lay_dusk(far, 1.5, 120.0)
		var ps: Array[Person] = [_put(crowd, 26, d), _put(crowd, 27, d + Vector2(0.5, 0.3))]
		var q := _put(crowd, 28, far)
		var a := _cast(made[5], at)
		var b := _cast(made[5], far + Vector2(3.0, 0.0))
		_go(a, DreadOfTheDarkFx.T_FALL + DT)
		_go(b, DreadOfTheDarkFx.T_FALL + DT)
		t.check(ps.all(func(p: Person) -> bool: return p.is_dreaded()) and q.is_dreaded() and crowd.dreads.size() == 2,
			"%s: control: both Dreads hold their people" % mode)
		if mode == "end_now":
			a.end_now()
		else:
			a.free()
		t.check(not ps.any(func(p: Person) -> bool: return p.is_dreaded() or p.has_meta(&"dread_owners")) and not crowd.dreaded(d),
			"%s: every person the first held is free, its dread ended" % mode)
		t.check(q.is_dreaded() and crowd.dreaded(far) and crowd.dreads.size() == 1, "%s: the second's are still held" % mode)
		b.end_now()
		t.check(not q.is_dreaded() and crowd.dreads.is_empty(), "%s: the second lets go of its own (positive control)" % mode)


## Quiet: nobody screams, the alarm and the held count are unchanged, the frozen stay calm; the code never alarms, frightens or rolls.
## Its dusk is laid at the click when it lifts.
static func _quiet(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var ps: Array[Person] = [_put(crowd, 31, d), _put(crowd, 32, d + Vector2(0.4, 0.0)), _put(crowd, 33, at + Vector2(-3.0, 0.0))]
	var alarm := crowd.alarm
	var voiced := crowd.voices_played
	var dangers := crowd.threats.active_count()
	var epoch := crowd.threats.epoch
	var fx := _cast(made[5], at)
	_go(fx, DreadOfTheDarkFx.T_FALL + 2.0, ps)
	var calm := ps.all(func(p: Person) -> bool: return p.mind == Person.Mind.CALM)
	t.check(crowd.alarm == alarm and crowd.voices_played == voiced and calm, "nobody screams, no alarm, everyone calm")
	t.check(crowd.threats.active_count() == dangers and crowd.threats.epoch == epoch, "no danger registered")
	t.check(not crowd.dusk.covers(at), "no dusk at the click while it holds (VC1)")
	_go(fx, DreadOfTheDarkFx.HOLD)
	t.check(crowd.dusk.covers(at) and crowd.dusk.r_at(at) == VeilRules.DUSK_R, "lifted: dusk laid at the click (r %.1f)" % crowd.dusk.r_at(at))
	var src := FileAccess.get_file_as_string("res://src/fx/veil/dread_of_the_dark.gd")
	t.check(src != "" and not src.contains("add_alarm") and not src.contains("fright(") and not src.contains("panic(") and not src.contains("on_cast")
		and not src.contains("randf") and not src.contains("randi") and not src.contains("ctx.rng") and not src.contains("register("),
		"the code never alarms, frightens, panics, registers a danger or rolls")
	fx.end_now()


## The god's look: the dark ground in reach thickens (runs of cells) with eyes at its edge, a mark under each frozen; it goes with the cast.
static func _look(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	var p := _put(crowd, 34, d)
	var fx := _cast(made[5], at)
	t.check(fx.shade != null and is_instance_valid(fx.shade) and fx.shade.get_parent() == (made[5] as FxContext).overhead, "a shade in the god's overhead layer")
	t.check(not fx.shade.runs.is_empty() and fx.shade.front() < fx.shade._d_max, "the dark is read at the click and its front starts short of it (VRC2)")
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	var shade := fx.shade
	var walled := shade.pillars.size() > 0 and shade.pillars.size() <= DreadOfTheDarkFx.DreadShade.PILLARS
	for g: Vector2 in shade.pillars:
		walled = walled and g.distance_to(d) <= 1.5 + 0.8
	t.check(walled, "a wall of pillars stands at the border of the dreaded ground, not round the reach (%d)" % shade.pillars.size())
	_go(fx, DreadOfTheDarkFx.DreadShade.SPREAD)
	t.check(shade.front() >= shade._d_max, "the front has crossed all the dreaded ground")
	t.check(not shade.runs.is_empty() and shade.eyes.size() > 0 and shade.eyes.size() <= DreadOfTheDarkFx.DreadShade.EYES, "the dark thickens; eyes at its edge (%d)" % shade.eyes.size())
	var inside := true
	for r: Array in shade.runs:
		inside = inside and (r[0] as Vector2).distance_to(d) <= 1.5 + 0.8 and (r[1] as Vector2).distance_to(d) <= 1.5 + 0.8
	t.check(inside, "only the dark ground is thickened, not the lit")
	t.check(shade.strength == 1.0 and shade.held.has(p.get_instance_id()), "full while it holds; the frozen are marked")
	fx.end_now()
	t.check(not is_instance_valid(shade) or shade.is_queued_for_deletion(), "the shade goes with the cast")



## Fix round 1 (VRC3): with overhead_back the wall's far half stands on a back node there, and it goes with end_now() and with a cast
## freed outright; a held person at the patch's side edge is covered by no pillar taller than the near share.
static func _wall_halves(t, made: Array) -> void:
	var crowd: Crowd = made[0]
	var base: FxContext = made[5]
	var ctx := FxContext.new()
	ctx.env = base.env
	ctx.field = base.field
	ctx.crowd = crowd
	ctx.world = base.world
	ctx.rng = base.rng
	ctx.overhead = base.overhead
	ctx.ground = base.ground
	ctx.overhead_back = Node2D.new()
	var at := _fresh(made)
	var d := at + Vector2(4.0, 0.0)
	crowd.lay_dusk(d, 1.5, 120.0)
	# The patch's right-hand side on screen: ground (1, -1) is screen right.
	var p := _put(crowd, 34, d + Vector2(1.0, -1.0).normalized() * 1.1)
	var fx := _cast(ctx, at)
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	var shade := fx.shade
	var back := shade.back
	t.check(back != null and is_instance_valid(back) and back.get_parent() == ctx.overhead_back and shade.get_parent() == ctx.overhead,
		"the wall's far half on a node on overhead_back, the shade (near half) on overhead")
	var rect := DreadOfTheDarkFx.DreadShade.person_rect(p.ground_pos)
	var cut := 0
	var bad := 0
	for i in shade.pillars.size():
		if shade.pillar_rect(i, shade.share(i)).intersects(rect):
			cut += 1
			if shade.share(i) > DreadOfTheDarkFx.DreadShade.NEAR + 0.001:
				bad += 1
	t.check(p.is_dreaded() and shade.held.has(p.get_instance_id()) and cut > 0 and bad == 0,
		"a held man at the side edge: the %d pillars that reach his rect are all cut to the near share (%d too tall)" % [cut, bad])
	fx.end_now()
	t.check(not is_instance_valid(back) or back.is_queued_for_deletion(), "the back half goes with end_now()")
	var other := _cast(ctx, at)
	var back2: Node2D = other.shade.back if other.shade != null else null
	var shade2 := other.shade
	other.free()
	if is_instance_valid(shade2):
		shade2._process(DT)
	if is_instance_valid(back2) and not back2.is_queued_for_deletion():
		back2._process(DT)
	t.check(back2 != null and (not is_instance_valid(back2) or back2.is_queued_for_deletion()), "and with a cast freed outright")
	for c in ctx.overhead_back.get_children():
		c.free()
	ctx.overhead_back.free()


## The watch's seizing: a patrol soldier standing in dreaded ground does not see a believer beside him; the control does.
static func _seizer(t) -> void:
	var s := Kit.world(HuntBook.def(MissionBook.HIDE_FAITHFUL))
	var d: HideFaithfulDirector = s.d
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var crowd: Crowd = s.crowd
	crowd.dusk.enabled = true
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = crowd
	ctx.world = s.world
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	var lead := d.lamp(0)
	var lp := lead.man as Person
	var soldier := d.patrols[0][0] as Person
	Kit.arrive(soldier, lp.ground_pos + Vector2(1.0, 0.0))
	soldier.send_to_post(soldier.ground_pos)
	t.check(d._seen_by(lead) != null, "control: the patrol sees the believer")
	crowd.lay_dusk(soldier.ground_pos, 0.4, 60.0)
	var fx := _cast(ctx, soldier.ground_pos, {"dark": true})
	_go(fx, DreadOfTheDarkFx.T_FALL + DT)
	t.check(soldier.is_dreaded() and not lp.is_dreaded(), "the soldier in the dusk is dreaded, the believer beside it not")
	t.check(d._seen_by(lead) == null, "a dreaded soldier seizes no one")
	fx.end_now()
	t.check(d._seen_by(lead) != null, "the dread ended: he sees him again")
	ctx.overhead.free()
	ctx.ground.free()
	Kit.done(s)


## No crowd, no rules (the VFX Sandbox): the cast builds and finishes at the light size.
static func _no_crowd(t) -> void:
	var ctx := FxContext.new()
	ctx.rng = RandomNumberGenerator.new()
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.world = Node2D.new()
	var fx := _cast(ctx, Vector2.ZERO)
	t.check(fx != null and fx.reach == 6.0 and fx.duration == 1.0, "no crowd: builds at the light size")
	for i in 40:
		if not fx.finished:
			fx._process(DT)
	t.check(fx.finished, "and finishes without an error")
	ctx.overhead.free()
	ctx.ground.free()
	ctx.world.free()
