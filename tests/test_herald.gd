extends RefCounted
## v0.11.2 Task 11: the Herald (spec 4.6). On a Herald night the toll does not lose: the warning's errand becomes the Temple's door, its carrier --
## the keeper who rang, or the witness who took it on -- walks there slowed, and a Herald who gets in has the Lantern hear. Killed unseen, the
## warning dies and the night is won; the town's own keeper ringing with no warning delivered is a Herald of his own (a TempleReport); a silenced bell
## sends the warning to the Temple with no toll at all. Worlds are Kit worlds (tests/test_tier2_groundwork.gd) with a Lantern of kind herald attached.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05
const HERALD_ROW := "The Herald reaches the Temple"


## The strip's Herald rows (the Bearer's row shares the strip).
static func _herald_rows(lw: LanternWatch) -> Array:
	return lw.strip_rows().filter(func(r: Dictionary) -> bool: return String(r["label"]) == HERALD_ROW)


static func run(t) -> void:
	_report(t)
	_toll_runs(t)
	_heard(t)
	_unseen(t)
	_herald_relay(t)
	_later_star(t)
	_silenced(t)
	_silenced_after_toll(t)
	_keeper_alone(t)
	_win_needs_no_herald(t)
	_heard_same_frame(t)
	_ringer(t)
	_off_nights(t)
	_teardown(t)


## A Kit world for `variant` -- "warning" (the campaign's), "stars" (the board's Starfall) or "ringers" (The Bell-Ringers) -- whose objectives are
## the night's main one and HeraldObjective (no dawn, so nothing else ends it), with a Lantern of `kind` on its Rules.
static func _world(variant: String, kind := "herald") -> Dictionary:
	var def: MissionDef
	match variant:
		"stars":
			def = TierBook.board("warning")
		"ringers":
			def = MissionBook.bell_ringers()
		_:
			def = MissionBook.warning()
	def.make_objectives = func() -> Array[Objective]:
		var main: Objective = WarningObjective.new()
		if variant == "stars":
			main = StarsObjective.new()
		elif variant == "ringers":
			main = StarsObjective.new("Stop the ringers", "ringers", "Ringers stopped")
		var out: Array[Objective] = [main, HeraldObjective.new()]
		return out
	var s := Kit.world(def)
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, kind)
	(s.rules as Rules).lantern = lw
	s["lw"] = lw
	return s


## The bell tolls as it does in play: the one on the rope, the climb done.
static func _ring(s: Dictionary) -> void:
	var bell: BellNetwork = (s.crowd as Crowd).bell
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()


static func _count(s: Dictionary, line: String) -> int:
	return (s.banners as Array).count(line)


## Everyone but `keep` within sight of `c` is sent well off, so nobody but `keep` sees him fall.
static func _clear_round(s: Dictionary, c: Person, keep: Array) -> void:
	for group: Array[Person] in [(s.crowd as Crowd).citizens, (s.crowd as Crowd).soldiers]:
		for p in group:
			if is_instance_valid(p) and p != c and not keep.has(p) and p.is_alive() \
					and p.ground_pos.distance_to(c.ground_pos) <= Crowd.DOOM_WITNESS + 0.5:
				var off := p.ground_pos - c.ground_pos
				Kit.arrive(p, c.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * 6.0)


## The Warning's watchman runs, tells the keeper at the tower's foot, and the keeper has the rope (DELIVERED): true when he does.
static func _deliver(s: Dictionary) -> bool:
	var d: WarningDirector = s.d
	var bell: BellNetwork = (s.crowd as Crowd).bell
	_run(s, WarningDirector.OMEN_AT + WarningDirector.STARE + 0.3)
	Kit.arrive(bell.keeper, bell.foot)
	Kit.arrive(d.messenger, bell.foot + Vector2(0.3, 0.0))
	_run(s, 1.0)
	return d.phase == WarningDirector.Phase.DELIVERED and d.messenger == bell.keeper


## The Warning world, delivered and tolled, `after` seconds on.
static func _tolled(after := 0.1) -> Dictionary:
	var s := _world("warning")
	var ok := _deliver(s)
	_ring(s)
	_run(s, after)
	s["delivered"] = ok
	return s


static func _door(s: Dictionary) -> Vector2:
	return MissionDirector.lantern_door_in(s.crowd)


## The people on an errand for the night -- every warning's carrier, and the Lantern's own Heralds. A test world is not ticked by the engine (a
## crowd's people are stepped by its ticker, which a headless test has not), so these walk only because _run() ticks them.
static func _walkers(s: Dictionary) -> Array:
	var out := []
	var ws := []
	var d: Variant = s.d
	if d is StarfallDirector:
		ws = (d as StarfallDirector).stars
	elif d is BellRingersDirector:
		ws = (d as BellRingersDirector).ringers
	elif d is WarningDirector:
		ws = [d]
	for w: WarningDirector in ws:
		if w.rules != null and is_instance_valid(w.messenger) and w.messenger.is_alive():
			out.append(w.messenger)
	for h in (s.lw as LanternWatch).heralds:
		if is_instance_valid(h.carrier) and h.carrier.is_alive():
			out.append(h.carrier)
	return out


## `seconds` of the night: the crowd, the walkers (above), then the rules and so the director and the Lantern.
static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		for p: Person in _walkers(s):
			p.tick(DT)
		(s.rules as Rules).advance(DT)


## Runs until `cond` holds or `limit` seconds pass; the seconds it took.
static func _until(s: Dictionary, limit: float, cond: Callable) -> float:
	var n := 0.0
	while n < limit and not cond.call():
		_run(s, DT)
		n += DT
	return n


## TempleReport's two new knobs: slow and descend.
static func _report(t) -> void:
	var s := _world("stars")
	var crowd: Crowd = s.crowd
	var door := _door(s)
	var a: Person = crowd.citizens[0]
	var plain := TempleReport.new(a, door)
	t.check(a.mind == Person.Mind.DUTY and not a.statuses.has(&"slow") and plain.slow == 1.0 and plain.descend == 0.0,
		"a plain report sends its carrier at once, at full pace (the other missions' way)")
	crowd.off_duty(a)
	var b: Person = crowd.citizens[1]
	var rep := TempleReport.new(b, door, LanternWatch.HERALD_SLOW, 3.0)
	t.check(b.mind != Person.Mind.DUTY and rep.slow == 0.4 and rep.descend == 3.0 and is_equal_approx(rep.descend_left(), 3.0),
		"with descend the carrier is not sent in _init: still held")
	var at := b.ground_pos
	for i in 40:
		rep.step(DT, crowd)
		crowd.advance(DT)
	t.check(b.mind != Person.Mind.DUTY and b.ground_pos.distance_to(at) < 0.05 and rep.descend_left() > 0.9,
		"2 s into a 3 s descent he has not stirred (%.2f moved)" % b.ground_pos.distance_to(at))
	for i in 25:
		rep.step(DT, crowd)
	t.check(b.mind == Person.Mind.DUTY and is_equal_approx(float(b.statuses.get(&"slow", 1.0)), 0.4)
		and b.walk_speed <= Person.PANIC_SPEED * b.pace * 0.4 + 0.001 and rep.descend_left() == 0.0,
		"after it he is on duty at 0.4 of his pace")
	rep.carrier.ground_pos = door
	rep.step(DT, crowd)
	t.check(rep.delivered and not b.statuses.has(&"slow"), "delivered: his pace is given back")
	Kit.done(s)


static func _toll_runs(t) -> void:
	var s := _tolled(0.1)
	var d: WarningDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	t.check(s.delivered, "(the watchman told the keeper: the warning is delivered)")
	t.check(lw.tolled and not r.finished and d.heralding() and d.messenger == keeper and d.phase == WarningDirector.Phase.DELIVERED,
		"the keeper rings: no loss, and the keeper is the messenger -- the Herald")
	t.check(lw.heralds.is_empty() and lw.herald_running() and d.herald_open() and lw.hint_phase() == "herald",
		"the warning claims him (no second Herald); a Herald runs, and the hint is the Herald's")
	t.check(d._goal().is_equal_approx(_door(s)) and d._descend > 4.5 and d._descend <= LanternWatch.HERALD_DESCEND,
		"his goal is the Temple's door, after HERALD_DESCEND (%.2f s left)" % d._descend)
	var label := ""
	for tag in d.tags():
		if tag.label.begins_with("HERALD"):
			label = tag.label
	t.check(label.begins_with("HERALD - COMES DOWN IN ") and Kit.edged(d, label), "while he comes down: HERALD - COMES DOWN IN m:ss, pointed at (%s)" % label)
	t.check(not Kit.labels(d).has("BELL TOWER") and not Kit.labels(d).has("BELLKEEPER"), "the tower and the keeper are no longer the errand")
	var lt := lw.tags()
	var temple := false
	for tag in lt:
		temple = temple or (tag.label == "TEMPLE" and tag.edge and tag.at.is_equal_approx(_door(s)))
	# The Bearer's row (Task 10) shares the strip: only the Herald's rows are counted here.
	var hrows := _herald_rows(lw)
	t.check(temple and hrows.size() == 1 and float(hrows[0]["in"]) > 7.0,
		"the Temple's door is tagged, and the strip has the row (%s)" % [lw.strip_rows()])
	var p0 := keeper.ground_pos
	_run(s, 4.0)
	t.check(keeper.ground_pos.distance_to(p0) < 0.15, "he stands on the tower for the descent (%.2f moved)" % keeper.ground_pos.distance_to(p0))
	_run(s, 1.2)
	label = ""
	for tag in d.tags():
		if tag.label.begins_with("HERALD"):
			label = tag.label
	t.check(d._descend == 0.0 and keeper.mind == Person.Mind.DUTY and keeper.goal().distance_to(_door(s)) < 0.6
		and is_equal_approx(float(keeper.statuses.get(&"slow", 1.0)), LanternWatch.HERALD_SLOW)
		and label.begins_with("HERALD - AT THE TEMPLE IN "), "then he walks to the door, slowed (%s)" % label)
	t.check(_count(s, LanternWatch.HERALD_BANNER) == 1 and _count(s, LanternWatch.TOLL_BANNER) == 1, "the banners once each")
	Kit.done(s)


static func _heard(t) -> void:
	var s := _tolled(0.0)
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var took := _until(s, 90.0, func() -> bool: return r.finished)
	t.check(r.finished and not r.won and r.over_reason == "lantern" and lw.heard and _count(s, LanternWatch.HEARD_BANNER) == 1,
		"let him walk: the Lantern hears, the night is lost, reason lantern (%s)" % r.over_reason)
	t.check(took >= LanternWatch.HERALD_DESCEND + 11.0 and took <= LanternWatch.HERALD_DESCEND + 27.0,
		"the trip is the descent plus 13-25 s of walking (%.1f s)" % took)
	Kit.done(s)


static func _unseen(t) -> void:
	var s := _tolled(0.0)
	var d: WarningDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_run(s, 6.0)
	var keeper: Person = d.messenger
	_clear_round(s, keeper, [])
	(s.crowd as Crowd)._field.kill(keeper, &"doom")
	_run(s, 0.4)
	t.check(d.warning_dead and not lw.herald_running() and r.finished and r.won and r.over_reason == "warning" and not lw.heard,
		"killed unseen on the way: the warning is dead, the objective counts it, the night is won (%s)" % r.over_reason)
	Kit.done(s)


static func _herald_relay(t) -> void:
	var s := _tolled(0.0)
	var d: WarningDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_run(s, 6.0)
	var keeper: Person = d.messenger
	var witness: Person = null
	for p in (s.crowd as Crowd).citizens:
		if is_instance_valid(p) and p != keeper and p.is_alive():
			witness = p
			break
	Kit.arrive(witness, keeper.ground_pos + Vector2(1.0, 0.0))
	witness.inside = false
	_clear_round(s, keeper, [witness])
	(s.crowd as Crowd)._field.kill(keeper, &"fire")
	_run(s, 0.4)
	t.check(not d.warning_dead and d.relays == 1 and d.messenger == witness and not r.finished and _count(s, "THE WARNING PASSES ON") == 1,
		"killed seen: the witness carries it on (relays 1), the night goes on")
	t.check(witness.mind == Person.Mind.DUTY and witness.goal().distance_to(_door(s)) < 0.6
		and is_equal_approx(float(witness.statuses.get(&"slow", 1.0)), LanternWatch.HERALD_SLOW) and d._descend == 0.0 and lw.herald_running(),
		"to the Temple (not the keeper or the bell), slowed, with no descent: he is the Herald now")
	var label := ""
	for tag in d.tags():
		if tag.label.begins_with("HERALD"):
			label = tag.label
	t.check(label.begins_with("HERALD - AT THE TEMPLE IN "), "and tagged as the Herald (%s)" % label)
	_until(s, 90.0, func() -> bool: return r.finished)
	t.check(r.finished and not r.won and r.over_reason == "lantern", "left alone, the relayed Herald gets in too (%s)" % r.over_reason)
	Kit.done(s)


## Review focus 6: a star that falls after the toll sends its watchman straight to the Temple.
static func _later_star(t) -> void:
	var s := _world("stars")
	var d: StarfallDirector = s.d
	var lw: LanternWatch = s.lw
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	_ring(s)
	_run(s, 0.1)
	t.check(lw.tolled and lw.heralds.size() == 1 and lw.heralds[0].carrier == keeper and lw.heralds[0].slow == LanternWatch.HERALD_SLOW,
		"the town's keeper rang with no warning delivered: a Herald of his own, a TempleReport")
	d._clock = 7.95
	_run(s, WarningDirector.OMEN_AT + WarningDirector.STARE + 2.5)
	var w := d.stars[0]
	t.check(w.rules != null and w.phase == WarningDirector.Phase.RUN and w.heralding() and w.messenger.mind == Person.Mind.DUTY
		and w.messenger.goal().distance_to(_door(s)) < 0.6 and w.messenger.goal().distance_to(keeper.ground_pos) > 3.0
		and is_equal_approx(float(w.messenger.statuses.get(&"slow", 1.0)), LanternWatch.HERALD_SLOW),
		"the postern's watchman, after the toll, runs for the Temple (not the keeper), slowed")
	t.check(d.herald_open() and d.claims_herald(w.messenger) and not d.claims_herald(keeper) and d.stars[1].rules == null,
		"his director claims him; the keeper's report is the Lantern's own")
	var heralds := 0
	for tag in d.tags():
		heralds += 1 if tag.label.begins_with("HERALD") else 0
	for tag in lw.tags():
		heralds += 1 if tag.label.begins_with("HERALD") else 0
	t.check(heralds == 2 and _herald_rows(lw).size() == 1, "two Heralds at once, both tagged, one strip row (soonest)")
	Kit.done(s)


## The tower cracked before the warning is told: the called bell is silenced, there is no toll, and the warning runs for the Temple.
static func _silenced(t) -> void:
	var s := _world("warning")
	var d: WarningDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var bell: BellNetwork = (s.crowd as Crowd).bell
	t.check(not d.heralding() and not lw.bell_silenced, "(before: the warning runs for the keeper)")
	(s.env as EnvironmentField).blight(bell.tower)
	t.check(not d.heralding(), "a cracked tower that was never called silences nothing yet")
	var ok := _deliver(s)
	_run(s, 0.4)
	t.check(ok or bell.state == BellNetwork.State.SILENCED, "(the keeper was told, and the called bell fell silent)")
	t.check(bell.state == BellNetwork.State.SILENCED and lw.bell_silenced and not lw.tolled and lw.stage == LanternWatch.Stage.ASLEEP
		and is_equal_approx(r.clock_rate, 1.0) and d.heralding() and d.herald_open(),
		"the bell is silent: no toll, the Lantern Asleep at x1.0, the warning a Herald")
	t.check(_count(s, LanternWatch.SILENT_BANNER) == 1 and _count(s, LanternWatch.TOLL_BANNER) == 0 and _count(s, LanternWatch.HERALD_BANNER) == 0,
		"THE BELL IS SILENT - THE WARNING RUNS FOR THE TEMPLE, once; no toll banner")
	var keeper: Person = d.messenger
	t.check(d._descend == 0.0 and d._goal().is_equal_approx(_door(s)) and keeper.mind == Person.Mind.DUTY and keeper.goal().distance_to(_door(s)) < 0.6,
		"the messenger (the keeper who held it) runs for the door at once: nothing to descend")
	_until(s, 90.0, func() -> bool: return r.finished)
	t.check(r.finished and not r.won and r.over_reason == "lantern" and lw.stage == LanternWatch.Stage.ASLEEP,
		"and in he gets: lost, reason lantern, with the Lantern still Asleep (%s)" % r.over_reason)
	Kit.done(s)
	# A town with no bell at all is SILENCED from the start without the signal: it heralds nothing.
	var n := _world("warning")
	((n.crowd as Crowd).bell as BellNetwork).state = BellNetwork.State.SILENCED
	t.check(not (n.d as WarningDirector).heralding() and not (n.lw as LanternWatch).bell_silenced,
		"a bell silenced by setup (no signal) is not a silenced bell: the warning does not herald")
	Kit.done(n)


## C7: a silencing after the toll latches nothing, and starts nothing new.
static func _silenced_after_toll(t) -> void:
	var s := _tolled(0.1)
	var d: WarningDirector = s.d
	var lw: LanternWatch = s.lw
	var bell: BellNetwork = (s.crowd as Crowd).bell
	var descend := d._descend
	bell._silence("the tower has fallen")
	_run(s, 0.1)
	t.check(lw.tolled and not lw.bell_silenced and lw.stage == LanternWatch.Stage.STIRRING and d.heralding() and d._descend < descend
		and _count(s, LanternWatch.SILENT_BANNER) == 0, "silenced once it has tolled: bell_silenced stays false, the Herald goes on as he was")
	Kit.done(s)


## The town's own keeper rings with no ringer on the rope: a Herald of his own, whom the win needs stopped too.
static func _keeper_alone(t) -> void:
	var s := _world("ringers")
	var d: BellRingersDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	_ring(s)
	_run(s, 0.1)
	t.check(lw.heralds.size() == 1 and lw.heralds[0].carrier == keeper and lw.heralds[0].is_open() and lw.herald_running()
		and _count(s, LanternWatch.HERALD_BANNER) == 1 and not d.herald_open(),
		"no ringer on the rope: the keeper who rang is a TempleReport Herald (the banner once)")
	var label := ""
	for tag in lw.tags():
		if tag.label.begins_with("HERALD"):
			label = tag.label
	t.check(label.begins_with("HERALD - COMES DOWN IN ") and lw.heralds[0].descend_left() > 4.5, "he comes down the tower first (%s)" % label)
	for q in d.ringers:
		q.warning_dead = true
		q.phase = WarningDirector.Phase.OVER
	_run(s, 0.2)
	t.check(d.stopped() == 3 and not r.finished, "every ringer stopped: the night is NOT won while the keeper-Herald runs")
	_run(s, 6.0)
	t.check(keeper.mind == Person.Mind.DUTY and is_equal_approx(float(keeper.statuses.get(&"slow", 1.0)), LanternWatch.HERALD_SLOW)
		and keeper.goal().distance_to(_door(s)) < 0.6, "after the descent he walks, slowed, to the door")
	_clear_round(s, keeper, [])
	(s.crowd as Crowd)._field.kill(keeper, &"doom")
	_run(s, 0.4)
	t.check(lw.heralds[0].dead and not lw.herald_running() and r.finished and r.won, "stopped unseen: the report is over and the night is won")
	Kit.done(s)
	# Seen, a witness carries him on (the report's relay), and a Herald gone from the town ends his report.
	var q := _world("ringers")
	var ql: LanternWatch = q.lw
	var kq: Person = (q.crowd as Crowd).bell.keeper
	_ring(q)
	_run(q, 6.0)
	var witness: Person = null
	for p in (q.crowd as Crowd).citizens:
		if is_instance_valid(p) and p != kq and p.is_alive():
			witness = p
			break
	Kit.arrive(witness, kq.ground_pos + Vector2(1.0, 0.0))
	witness.inside = false
	_clear_round(q, kq, [witness])
	(q.crowd as Crowd)._field.kill(kq, &"fire")
	_run(q, 0.4)
	t.check(ql.heralds[0].is_open() and ql.heralds[0].relays == 1 and ql.heralds[0].carrier == witness
		and is_equal_approx(float(witness.statuses.get(&"slow", 1.0)), LanternWatch.HERALD_SLOW),
		"seen: the witness takes the report on, slowed too")
	Kit.free_body(q, witness)
	_run(q, 0.2)
	t.check(not ql.heralds[0].is_open() and not ql.herald_running(), "a Herald whose body is gone from the town ends his report (no unwinnable night)")
	Kit.done(q)


static func _win_needs_no_herald(t) -> void:
	var s := _world("stars")
	var d: StarfallDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	_ring(s)
	for w in d.stars:
		w.warning_dead = true
		w.phase = WarningDirector.Phase.OVER
	_run(s, 0.3)
	t.check(d.stopped() == 3 and lw.herald_running() and not r.finished, "all three warnings dead and one report Herald open: not won")
	_run(s, 6.0)
	_clear_round(s, keeper, [])
	(s.crowd as Crowd)._field.kill(keeper, &"doom")
	_run(s, 0.4)
	t.check(r.finished and r.won and r.over_reason == "warning", "he is stopped: won")
	Kit.done(s)


## C7: `heard` is set in the frame the Herald is delivered, before the objectives are checked: no frame reads the night as won in between.
static func _heard_same_frame(t) -> void:
	var s := _world("stars")
	var d: StarfallDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	_ring(s)
	for w in d.stars:
		w.warning_dead = true
		w.phase = WarningDirector.Phase.OVER
	for i in roundi(6.0 / DT):
		r.advance(DT)  # the descent counts down; nobody moves
	Kit.arrive(keeper, _door(s) + Vector2(0.0, 0.5))
	var held := true
	var seen_heard := false
	for i in 12:
		r.advance(DT)
		held = held and (lw.herald_running() or lw.heard) and not (r.finished and r.won)
		seen_heard = seen_heard or lw.heard
	t.check(held and seen_heard and r.finished and not r.won and r.over_reason == "lantern",
		"the Herald gets in with every warning already dead: at no frame is the night won, and it is lost for the Lantern")
	Kit.done(s)


## The Bell-Ringers: a ringer on the rope is his warning's Herald.
static func _ringer(t) -> void:
	var s := _world("ringers")
	var d: BellRingersDirector = s.d
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var bell: BellNetwork = (s.crowd as Crowd).bell
	var a := d.ringers[0]
	d._send(0)
	_run(s, RingerDirector.OUT_PAUSE + DT * 4.0)
	Kit.arrive(a.messenger, bell.foot)
	a.messenger.mind = Person.Mind.DUTY
	a.phase = WarningDirector.Phase.RUN
	a._run()
	Kit.arrive(a.messenger, bell.foot)
	bell.step(DT)
	t.check(bell.keeper == a.messenger and bell.state == BellNetwork.State.CLIMBING and not a.heralding(), "(the ringer is on the rope, climbing)")
	bell.progress = bell.climb
	bell.step(DT)
	_run(s, 0.1)
	t.check(lw.tolled and a.heralding() and a.herald_open() and lw.heralds.is_empty() and d.herald_open() and d.claims_herald(a.messenger)
		and a._goal().is_equal_approx(_door(s)) and a._descend > 4.5 and not r.finished,
		"the ringer rang: no loss -- he is the Herald, his goal the Temple's door, after the descent")
	var label := ""
	for tag in d.tags():
		if tag.label.begins_with("HERALD"):
			label = tag.label
	t.check(label.begins_with("HERALD - COMES DOWN IN ") and not d.ringers[1].herald_open() and d.hint_phase() == "herald",
		"RINGER - CLIMBING is now HERALD - COMES DOWN IN; a post still waiting is no Herald (%s)" % label)
	_run(s, 6.0)
	t.check(a.messenger.mind == Person.Mind.DUTY and a.messenger.goal().distance_to(_door(s)) < 0.6
		and is_equal_approx(float(a.messenger.statuses.get(&"slow", 1.0)), LanternWatch.HERALD_SLOW), "then he walks to the Temple, slowed")
	# A post sent after the toll sends its ringer straight for the Temple.
	d._send(1)
	var b := d.ringers[1]
	_run(s, RingerDirector.OUT_PAUSE + WarningDirector.RETARGET + DT * 4.0)
	t.check(b.phase == WarningDirector.Phase.RUN and b.messenger.goal().distance_to(_door(s)) < 0.6 and not b.messenger.goal().is_equal_approx(bell.foot),
		"a ringer sent after the toll runs for the Temple, never for the rope")
	Kit.done(s)


## A watch or gaze night, or none: the toll is the Lantern's alone; no warning heralds.
static func _off_nights(t) -> void:
	for kind in ["watch", "gaze"]:
		var s := _world("warning", kind)
		var d: WarningDirector = s.d
		var lw: LanternWatch = s.lw
		_deliver(s)
		_ring(s)
		_run(s, 0.2)
		t.check(lw.tolled and not d.heralding() and not d.herald_open() and d._descend == 0.0 and lw.heralds.is_empty() and not lw.herald_running()
			and _count(s, LanternWatch.HERALD_BANNER) == 0, "a %s night: the toll makes no Herald" % kind)
		Kit.done(s)
	var n := Kit.world(MissionBook.warning())
	t.check(not (n.d as WarningDirector).heralding() and not (n.d as MissionDirector).herald_open() and (n.d as MissionDirector).herald_eta() == INF,
		"no Lantern: nothing heralds")
	Kit.done(n)


## The act ends: a Herald is given back his pace.
static func _teardown(t) -> void:
	var s := _tolled(0.0)
	var d: WarningDirector = s.d
	_run(s, 6.0)
	var keeper: Person = d.messenger
	t.check(keeper.statuses.has(&"slow"), "(the Herald is slowed)")
	(s.rules as Rules).teardown()
	t.check(not keeper.statuses.has(&"slow") and (s.crowd as Crowd).bell.hold_on_death == false, "teardown gives the director's Herald his pace back")
	Kit.done(s)
	var q := _world("ringers")
	var kq: Person = (q.crowd as Crowd).bell.keeper
	_ring(q)
	_run(q, 6.0)
	t.check(kq.statuses.has(&"slow"), "(the report's Herald is slowed)")
	(q.rules as Rules).teardown()
	t.check(not kq.statuses.has(&"slow"), "and so does the Lantern's, with its report")
	Kit.done(q)
