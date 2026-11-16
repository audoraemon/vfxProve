extends RefCounted
## The Gate Below (Death, Tier IV): a click tears the ground open into a rift that fills its ring of 6 (its lip about 4.2,
## cracks and bone out to 6) for 12 s. Every 0.5 s grasping hands take the nearest person within 6 who is out in the open,
## not guised and not caught yet, hold them (pace 0) and drag them to the lip over 1.5 s (one already inside it goes under
## where he stands), where they go under (killed as pit: no body is left). When the pit closes every soul it took climbs
## back out as a wraith that flies out into its own sector of the circle and withers whoever it reaches there (three at
## most, citizen or soldier), and they die of it 6 s later as wither, leaving a body. The pit is a rift drawn on the ground
## with 36 hands reaching up all over its ring, not a stretched sheet. Loud: the town panics.

const RD := preload("res://tests/test_raise_dead.gd")
const DT := 0.05


static func _cast(made: Array, at: Vector2) -> TheGateBelowFx:
	return FxTimeline.cast(TheGateBelowFx, made[5], at) as TheGateBelowFx


static func run(t) -> void:
	var made := RD._setup()
	_book(t)
	_rift(t)
	_grabs(t, made)
	_held_and_freed(t, made)
	_pit(t, made)
	_inside_lip(t, made)
	_wraiths(t, made)
	_none(t, made)
	_scatter(t, made)
	_wraith_withers(t, made)
	_loud(t, made)
	_freed_mid_drag(t, made)
	_killed_mid_drag(t, made)
	_decoy(t, made)
	_exit(t, made)
	RD._done(made)


## Everyone back out in the open and unguised, then off in the corner (RD._clear_all).
static func _reset(made: Array) -> void:
	var crowd: Crowd = made[0]
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p):
			p.inside = false
			p.statuses.erase(&"guise")
	RD._clear_all(made)


## The nth citizen still alive (the pit kills some in every test), calm, at `at`.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var alive := (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var p: Person = alive[n]
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	return p


## The row, its tables, its icons, the brief's numbers.
static func _book(t) -> void:
	var b := PowerBook.get_power("gatebelow")
	t.check(not b.is_empty() and int(b.dp) == 5 and float(b.cooldown) == 90.0 and String(b.aim) == "click"
		and PowerBook.authority_of("gatebelow") == "death" and not PowerBook.is_quiet("gatebelow")
		and String(b.get("path", "")) == "res://src/fx/death/the_gate_below.gd",
		"The Gate Below: Death's 5 DP, 90 s, a click, loud (%s)" % [b])
	var area: Dictionary = Targeting.AREAS.get("gatebelow", {})
	t.check(PowerBook.REACH.has("gatebelow") and is_equal_approx(PowerBook.impact("gatebelow"), TheGateBelowFx.T_OPEN + TheGateBelowFx.DRAG)
		and PowerBook.family("gatebelow") == "death" and Rules.POWER_KINDS.get("gatebelow", []) == [&"pit", &"wither"]
		and area.get("shape", "") == "circle" and is_equal_approx(float(area.get("r", 0.0)), TheGateBelowFx.REACH)
		and Targeting.AREA_STATS.get("gatebelow", {}) == {"r": "REACH"},
		"its reach, impact (the first soul under), family, kills (pit, wither) and area (the arms' reach)")
	t.check(PowerBook.icon("gatebelow") != null and PowerBook.hud_icon("gatebelow") != null, "it has its icons")
	t.check(TheGateBelowFx.PIT_R == TheGateBelowFx.REACH and TheGateBelowFx.REACH == 6.0 and TheGateBelowFx.EDGE == 4.2
		and TheGateBelowFx.SPAN == 12.0 and TheGateBelowFx.GRAB_EVERY == 0.5 and TheGateBelowFx.DRAG == 1.5
		and TheGateBelowFx.WRAITH_LIFE == 20.0 and TheGateBelowFx.ARMS == 36 and TheGateBelowFx.ARM_SCALE == 1.0,
		"the numbers of the brief (R33, R34)")
	t.check(Remains.wants(["smite", "gatebelow"]), "a loadout with The Gate Below keeps the town's bodies: the withered rise (Remains.wants)")
	t.check(Sfx.CATALOG.has(&"gatebelow_open") and Sfx.CATALOG.has(&"gatebelow_close"), "its two cues are catalogued")


## R8, R33, R34: the pit is a rift drawn on the ground, not a stretched sheet, and it fills its ring: 28 jagged points
## about the lip (4.2, give or take 20%), cracks out toward the reach, and 36 hands standing all over the ring, the rift too.
static func _rift(t) -> void:
	var c := Vector2(3.0, -2.0)
	var pts := TheGateBelowFx.rift_points(c)
	var ok := pts.size() == 28
	var most := 0.0
	for p in pts:
		var d := p.distance_to(c)
		most = maxf(most, d)
		ok = ok and d >= TheGateBelowFx.EDGE * 0.8 - 0.0001 and d <= TheGateBelowFx.EDGE * 1.2 + 0.0001
	var cracks := TheGateBelowFx.crack_lines()
	var crack_ok := cracks.size() == 16
	for line in cracks:
		var end := line[line.size() - 1].length()
		crack_ok = crack_ok and end >= TheGateBelowFx.REACH * 0.7 - 0.0001 and end <= TheGateBelowFx.REACH + 0.01
	t.check(ok and most <= TheGateBelowFx.REACH and crack_ok,
		"the rift spans the reach: 28 points between 3.36 and 5.04 (widest %.2f), %d cracks out toward 6" % [most, cracks.size()])
	var spots := TheGateBelowFx.arm_spots(c)
	var lo := INF
	var hi := 0.0
	var outer := 0
	for s in spots:
		var d := s.distance_to(c)
		lo = minf(lo, d)
		hi = maxf(hi, d)
		if d > TheGateBelowFx.REACH * 0.75:
			outer += 1
	t.check(spots.size() == 36 and lo <= TheGateBelowFx.ARM_IN + 0.05 and hi <= TheGateBelowFx.REACH + 0.01 and outer >= 8,
		"36 hands over the whole ring (%d, %.2f..%.2f, %d past 4.5)" % [spots.size(), lo, hi, outer])
	var hand := "res://assets/pixellab/fx/grave_hand/grave_hand"
	var sheet = JSON.parse_string(FileAccess.get_file_as_string(hand + ".json"))
	var sheet_ok: bool = (sheet is Dictionary and Vector2(sheet.cell[0], sheet.cell[1]) == TheGateBelowFx.ARM_CELL
		and Vector2(sheet.foot[0], sheet.foot[1]) == TheGateBelowFx.ARM_FOOT and int(sheet.frames) == TheGateBelowFx.ARM_FRAMES)
	t.check(ResourceLoader.exists(hand + ".png") and TheGateBelowFx.ARM_SHEET == hand + ".png" and sheet_ok
		and not ResourceLoader.exists("res://assets/pixellab/fx/grave_arms.png")
		and not FileAccess.file_exists("res://assets/pixellab/fx/grave_arms.json"),
		"the hand sheet, no pole arms (%s)" % [sheet])
	var src := FileAccess.get_file_as_string("res://src/fx/death/the_gate_below.gd")
	t.check(not ResourceLoader.exists("res://assets/pixellab/fx/gate_below.png") and not src.is_empty()
		and not src.contains("gate_below.png"), "no stretched pit sprite")

## "grabs the nearest each 0.5 s, never a guised one": the nearest fair one first, the next 0.5 s later; a guised one, one
## indoors and one past REACH are never taken; a tie goes to the lower instance id.
static func _grabs(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	t.check(at != Vector2.INF, "a spot with nobody near")
	var guised := _put(made, 0, at + Vector2(1.0, 0.0))
	guised.statuses[&"guise"] = 30.0
	var indoor := _put(made, 1, at + Vector2(0.0, 1.2))
	indoor.inside = true
	var first := _put(made, 2, at + Vector2(0.0, 2.5))
	var second := _put(made, 3, at + Vector2(-3.5, 0.0))
	var far := _put(made, 4, at + Vector2(0.0, 6.8))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN - 0.1)
	t.check(fx.grabbed.is_empty(), "nobody is taken before the pit is open")
	RD._run(fx, 0.15)
	t.check(fx.grabbed == [first], "the nearest fair one is taken first, not the guised one nearer (%s)" % [_names(fx.grabbed)])
	RD._run(fx, TheGateBelowFx.GRAB_EVERY - 0.1)
	t.check(fx.grabbed.size() == 1, "nobody else before the next 0.5 s")
	RD._run(fx, 0.1)
	t.check(fx.grabbed == [first, second], "the next nearest 0.5 s later (%s)" % [_names(fx.grabbed)])
	RD._run(fx, 4.0)
	t.check(fx.grabbed == [first, second] and guised.is_alive() and indoor.is_alive() and far.is_alive(),
		"never a guised one, nor one indoors, nor one past 6 (%s)" % [_names(fx.grabbed)])
	fx.end_now()
	guised.statuses.erase(&"guise")
	indoor.inside = false
	# A tie: two at the same distance, the lower instance id first.
	_reset(made)
	var a := _put(made, 5, at + Vector2(3.0, 0.0))
	var b := _put(made, 6, at + Vector2(-3.0, 0.0))
	var low := a if a.get_instance_id() < b.get_instance_id() else b
	var fx2 := _cast(made, at)
	RD._run(fx2, TheGateBelowFx.T_OPEN + 0.05)
	t.check(fx2.grabbed == [low], "a tie goes to the lower instance id")
	fx2.end_now()


static func _names(ps: Array) -> Array:
	return ps.map(func(p: Person) -> String: return String(p.name) if is_instance_valid(p) else "<freed>")


## A caught one is held (pace 0) while dragged; the effect cut short lets them go with their pace back.
static func _held_and_freed(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var p := _put(made, 2, at + Vector2(5.5, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + 0.6)
	var d := p.ground_pos.distance_to(at)
	t.check(p.is_alive() and p.pace_hold() == 0.0 and d < 5.5 - 0.1 and d > TheGateBelowFx.EDGE,
		"a caught one is held (pace %.2f) and dragged toward the edge (%.2f from the middle)" % [p.pace_hold(), d])
	fx.end_now()
	t.check(p.is_alive() and p.pace_hold() == 1.0, "cut short, they are let go with their pace back (%.2f)" % p.pace_hold())
	# One the night puts indoors mid-drag is let go too, and never goes under.
	_reset(made)
	var q := _put(made, 2, at + Vector2(0.0, 5.0))
	var fx2 := _cast(made, at)
	RD._run(fx2, TheGateBelowFx.T_OPEN + 0.3)
	q.inside = true
	RD._run(fx2, TheGateBelowFx.DRAG)
	t.check(q.is_alive() and q.pace_hold() == 1.0 and fx2.souls == 0, "one put indoors mid-drag is let go (pace %.2f)" % q.pace_hold())
	q.inside = false
	fx2.end_now()


## "a grabbed person dies as pit, no remain": dragged to the edge over DRAG, then under: a pit death, no body.
static func _pit(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var p := _put(made, 2, at + Vector2(0.0, 5.5))
	var kinds := []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e == p:
			kinds.append(kind)
	field.enemy_killed.connect(on_kill)
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + TheGateBelowFx.DRAG - 0.1)
	t.check(p.is_alive(), "still alive while the arms drag them")
	RD._run(fx, 0.15)
	t.check(not p.is_alive() and kinds == [&"pit"], "a grabbed person dies as pit (%s)" % [kinds])
	t.check(absf(p.ground_pos.distance_to(at) - TheGateBelowFx.EDGE) < 0.05,
		"at the pit's edge (%.2f from the middle, the edge %.2f)" % [p.ground_pos.distance_to(at), TheGateBelowFx.EDGE])
	t.check(crowd.remains.enabled and crowd.remains.all().is_empty() and crowd.remains.pick(p.ground_pos) == null,
		"no remain: no body is left")
	t.check(fx.souls == 1 and is_equal_approx(fx.first_soul_at, PowerBook.impact("gatebelow")),
		"one soul taken, at the power's impact (%.2f)" % fx.first_soul_at)
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## R33: "one inside the lip goes under where he stands": a citizen 2.0 from the middle is grabbed, held where he stands,
## and goes under there after DRAG as the pit.
static func _inside_lip(t, made: Array) -> void:
	_reset(made)
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var stood := at + Vector2(2.0, 0.0)
	var p := _put(made, 2, stood)
	var kinds := []
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e == p:
			kinds.append(kind)
	field.enemy_killed.connect(on_kill)
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + TheGateBelowFx.DRAG + 0.1)
	t.check(fx.grabbed == [p] and not p.is_alive() and kinds == [&"pit"] and p.ground_pos.distance_to(stood) <= 0.1,
		"one inside the lip goes under where he stands (%s, %.2f from where he stood)" % [kinds, p.ground_pos.distance_to(stood)])
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## "at 12 s one wraith per soul taken": none before the close; at it one per soul, each owning its share of the circle,
## withering anyone (three at most); they last WRAITH_LIFE and are gone with the effect.
static func _wraiths(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	_put(made, 2, at + Vector2(2.0, 0.0))
	_put(made, 3, at + Vector2(0.0, 3.0))
	_put(made, 4, at + Vector2(-4.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.SPAN - 0.1)
	t.check(fx.souls == 3 and fx.visitors.living().is_empty(), "three souls taken, nobody back yet (%d souls)" % fx.souls)
	RD._run(fx, 0.15)
	var up := fx.visitors.living()
	var ok := up.size() == 3
	for a in up:
		var r: Visitors.Rule = fx.visitors._rules[a]
		ok = (ok and a.breed == Animal.Breed.WRAITH and not r.soldiers_only and r.slow < 1.0 and r.phase
			and r.wither == Withering.WITHER and r.touches_most == DeathParts.WRAITH_TOUCHES
			and is_equal_approx(r.sector.w, TAU / 3.0) and a.ground_pos.distance_to(at) < TheGateBelowFx.EDGE)
	t.check(ok, "at 12 s one wraith per soul taken, out of the pit, each to its third (%d up)" % up.size())
	# Everyone else indoors (_reset brings them out): with nobody to wither, none is spent before its time.
	for p in (made[0] as Crowd).citizens + (made[0] as Crowd).soldiers:
		if is_instance_valid(p):
			p.inside = true
	RD._run(fx, TheGateBelowFx.WRAITH_LIFE - 0.6)
	t.check(fx.visitors.living().size() == 3 and not fx.finished, "they last their 20 s")
	RD._run(fx, 0.6 + TheGateBelowFx.FADE + 0.4)
	t.check(fx.finished and fx.visitors.living().is_empty(), "then they are gone, and the effect with them")


## Nobody near: no soul, no wraith, and the effect ends with the close.
static func _none(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.SPAN + TheGateBelowFx.CLOSE + 0.3)
	t.check(fx.souls == 0 and fx.visitors.living().is_empty() and fx.finished, "nobody taken: no wraith, and it ends with the close")


## R35: the sectors, by rule: wraith k of n owns [0.4 + TAU (k - 0.5) / n, + TAU / n) about the pit; one alone owns the
## circle. "wraiths scatter, one to a sector": four souls taken, then the close: four wraiths, a quarter each, and 2 s after
## the close they have flown apart, at least an eighth of the circle between any two bearings from the pit.
static func _scatter(t, made: Array) -> void:
	var c := Vector2(1.0, 2.0)
	var s0 := TheGateBelowFx.sector_of(0, 4, c)
	var s3 := TheGateBelowFx.sector_of(3, 4, c)
	var one := TheGateBelowFx.sector_of(0, 1, c)
	t.check(Vector2(s0.x, s0.y) == c and is_equal_approx(s0.z, 0.4 - TAU / 8.0) and is_equal_approx(s0.w, TAU / 4.0)
		and is_equal_approx(s3.z, 0.4 + TAU * 2.5 / 4.0) and is_equal_approx(one.w, TAU),
		"the sectors by rule: a quarter each from 0.4, one alone the whole circle (%s, %s, %s)" % [s0, s3, one])
	_reset(made)
	var at := RD._empty(made)
	_put(made, 2, at + Vector2(1.5, 0.0))
	_put(made, 3, at + Vector2(0.0, 2.0))
	_put(made, 4, at + Vector2(-2.5, 0.0))
	_put(made, 5, at + Vector2(0.0, -3.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.SPAN + 0.05)
	var up := fx.visitors.living()
	var ok := fx.souls == 4 and up.size() == 4
	for a in up:
		var r: Visitors.Rule = fx.visitors._rules[a]
		ok = ok and is_equal_approx(r.sector.w, TAU / 4.0) and Vector2(r.sector.x, r.sector.y) == at
	RD._run(fx, 2.0)
	var bearings: Array[float] = []
	var own := 0  # how many stand within their own sector (fposmod(bearing - from, TAU) < width)
	for a in up:
		if is_instance_valid(a):
			var bearing := (a.ground_pos - at).angle()
			bearings.append(bearing)
			var rr: Visitors.Rule = fx.visitors._rules.get(a)
			if rr != null and fposmod(bearing - rr.sector.z, TAU) < rr.sector.w:
				own += 1
	var apart := INF
	for i in bearings.size():
		for j in range(i + 1, bearings.size()):
			apart = minf(apart, absf(angle_difference(bearings[i], bearings[j])))
	t.check(ok and bearings.size() == 4 and apart >= TAU / 8.0 and own == 4,
		"wraiths scatter, one to a sector, each within its own (%d souls, %d up, %d in their own, the nearest two %.2f apart)"
			% [fx.souls, bearings.size(), own, apart])
	fx.end_now()


## Runs `fx` and the crowd's withering (the town steps it) for `seconds`.
static func _run_withering(fx: FxTimeline, crowd: Crowd, seconds: float) -> void:
	for i in roundi(seconds / DT):
		if not fx.finished:
			fx._process(DT)
		crowd.withering.step(DT)


## R36, R37 (in place of R9's touch kill): "a wraith withers a citizen or a soldier, and they die as wither": two souls
## taken, then the close; a citizen and a soldier out past the reach in sector 0 are both withered within 8 s, each dies as
## wither 6 s after the touch, and the pit counts the curses.
static func _wraith_withers(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var s0 := TheGateBelowFx.sector_of(0, 2, at)
	var dir := Vector2.from_angle(s0.z + s0.w * 0.5)
	_put(made, 2, at - dir * 1.5)
	_put(made, 3, at - dir * 2.5 + dir.orthogonal())
	var c := _put(made, 4, at + dir * (TheGateBelowFx.REACH + 1.0))
	var alive := crowd.soldiers.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var s: Person = alive[0]
	s.ground_pos = at + dir * (TheGateBelowFx.REACH + 2.5)
	s.mind = Person.Mind.CALM
	var touched := {}
	var died := {}
	var fx := _cast(made, at)
	fx.visitors.bitten.connect(func(_a: Animal, who: Person, _first: bool) -> void:
		touched[who] = fx.t)
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void:
		if e == c or e == s:
			died[e] = [kind, fx.t]
	field.enemy_killed.connect(on_kill)
	_run_withering(fx, crowd, TheGateBelowFx.SPAN + 0.05)
	t.check(fx.souls == 2 and fx.visitors.living().size() == 2 and c.is_alive() and s.is_alive(),
		"(two souls, two wraiths up, the two out past the reach alive: %d, %d)" % [fx.souls, fx.visitors.living().size()])
	_run_withering(fx, crowd, 8.0)
	var by := TheGateBelowFx.SPAN + 8.0
	t.check(touched.has(c) and touched.has(s) and float(touched[c]) <= by and float(touched[s]) <= by,
		"both are withered within 8 s of the close (%s)" % [touched.values()])
	_run_withering(fx, crowd, Withering.WITHER + 0.5)
	var ok := touched.has(c) and touched.has(s) and died.has(c) and died.has(s)
	if ok:
		for who in [c, s]:
			ok = ok and died[who][0] == &"wither" and absf(float(died[who][1]) - float(touched[who]) - Withering.WITHER) <= 0.1
	t.check(ok and fx.withered >= 2,
		"a wraith withers a citizen or a soldier, and they die as wither 6 s after the touch (%s, %d withered)"
			% [died.values(), fx.withered])
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## "loud: the town panics": the cast is held as a danger until its impact; people past the arms' reach flee the open pit;
## the first soul taken raises the alarm.
static func _loud(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var held := crowd.held_count()
	crowd.on_cast(at, Vector2.ZERO, 0.0, "gatebelow")
	t.check(crowd.held_count() == held + 1, "the cast is a danger the town sees (held for its impact)")
	crowd.drop_held()
	_put(made, 2, at + Vector2(3.0, 0.0))
	var watcher := _put(made, 3, at + Vector2(0.0, TheGateBelowFx.REACH + 1.5))
	var alarm := crowd.alarm
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + TheGateBelowFx.DRAG + 0.2)
	t.check(watcher.is_alive() and watcher.mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER]
		and crowd.threats.unsafe(watcher.ground_pos),
		"loud: the town panics (one 7.5 off, past the arms: %s, in the pit's danger)" % Person.Mind.keys()[watcher.mind])
	t.check(crowd.alarm > alarm, "the first soul taken raises the alarm (%.2f -> %.2f)" % [alarm, crowd.alarm])
	fx.end_now()


## A caught one freed mid-drag (they left the town: Crowd.escape, or another power took them "gone"): the dead reference is
## dropped without an error, every other caught one still goes under on time, and the effect ends cleanly.
static func _freed_mid_drag(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var a := _put(made, 2, at + Vector2(2.0, 0.0))
	var gone := _put(made, 3, at + Vector2(0.0, 3.0))
	var c := _put(made, 4, at + Vector2(-4.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + TheGateBelowFx.GRAB_EVERY * 2.0 + 0.05)
	t.check(fx.grabbed.size() == 3 and fx._drags.size() == 3, "(three caught, all still dragged: %d, %d)" % [fx.grabbed.size(), fx._drags.size()])
	crowd.citizens.erase(gone)
	field.remove(gone)
	gone.free()
	RD._run(fx, TheGateBelowFx.DRAG + 0.1)
	t.check(not a.is_alive() and not c.is_alive() and fx.souls == 2 and fx._drags.is_empty(),
		"one freed mid-drag is dropped; the others still go under (%d souls, %d drags left)" % [fx.souls, fx._drags.size()])
	t.check(c.pace_hold() == 1.0, "and nobody is left held")
	fx.end_now()
	t.check(fx.finished and fx._drags.is_empty() and fx.visitors.living().is_empty(), "and the effect ends cleanly")


## A caught one killed by something else mid-drag is let go: their pace back, no soul for the pit, the arm lets go.
static func _killed_mid_drag(t, made: Array) -> void:
	_reset(made)
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var p := _put(made, 2, at + Vector2(4.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + 0.3)
	t.check(fx._drags.size() == 1 and p.pace_hold() == 0.0, "(caught and dragged)")
	var arm = fx._drags[0].arm
	field.kill(p, &"mob")
	RD._run(fx, 0.1)
	t.check(fx._drags.is_empty() and p.pace_hold() == 1.0 and fx.souls == 0,
		"one killed by something else mid-drag is let go (pace %.2f, %d souls)" % [p.pace_hold(), fx.souls])
	t.check(arm == null or not is_instance_valid(arm) or arm.pull_at >= 0.0, "and the arm lets go")
	RD._run(fx, TheGateBelowFx.DRAG)
	t.check(fx.souls == 0, "the pit never counts them")
	fx.end_now()


## A decoy (Mirrorfold's glass twin) is no one: the arms pass over it, as Pale Reign's do.
static func _decoy(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var twin := _put(made, 2, at + Vector2(1.0, 0.0))
	twin.set_meta(&"decoy", true)
	var real := _put(made, 3, at + Vector2(0.0, 3.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + TheGateBelowFx.GRAB_EVERY * 2.0 + 0.05)
	t.check(fx.grabbed == [real] and twin.is_alive() and twin.pace_hold() == 1.0,
		"a decoy nearer the pit is never taken (%s)" % [_names(fx.grabbed)])
	fx.end_now()
	twin.remove_meta(&"decoy")


## Freed without _finish (Battlefield.clear_effects() on a restart): every pace hold is let go and the wraiths are gone, with
## no error; its end after that changes nothing.
static func _exit(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p := _put(made, 2, at + Vector2(4.0, 0.0))
	var fx := _cast(made, at)
	RD._run(fx, TheGateBelowFx.T_OPEN + 0.3)
	t.check(p.pace_hold() == 0.0, "(one held mid-drag)")
	fx._exit_tree()
	t.check(p.pace_hold() == 1.0 and fx._drags.is_empty(), "freed mid-drag, the one held is let go (pace %.2f)" % p.pace_hold())
	fx.end_now()
	t.check(p.pace_hold() == 1.0 and fx.finished, "and its end after that changes nothing")
	# With the wraiths up.
	_reset(made)
	_put(made, 2, at + Vector2(2.0, 0.0))
	var fx2 := _cast(made, at)
	RD._run(fx2, TheGateBelowFx.SPAN + 0.1)
	var pack := fx2.visitors
	var up := pack.living()
	t.check(up.size() == 1, "(a wraith up: %d)" % up.size())
	fx2._exit_tree()
	var gone := true
	for a in up:
		gone = gone and (not is_instance_valid(a) or a.is_queued_for_deletion())
	t.check(gone and pack.living().is_empty() and not crowd.visitors.has(pack),
		"freed without its end, the wraiths are gone and the pack leaves the town")
	fx2.end_now()
	t.check(fx2.finished, "and it ends cleanly")
