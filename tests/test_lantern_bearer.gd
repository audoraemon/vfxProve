extends RefCounted
## v0.11.2 Task 10: the Lantern-Bearer and his escorts (spec 4.5). A Kit world (tests/test_lantern.gd's bell-ringers town with a stub director
## and a Lantern attached by hand); the walkers are real people on the town's walk grid, so the walk, the file and the relay are the game's own.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const LW := preload("res://tests/test_lantern.gd")
const DT := 0.05
## Seconds after the set-out that escorts coming in from where they stood take to fall into file.
const SETTLE := 4.0


static func run(t) -> void:
	_sets_out(t)
	_spread(t)
	_walk_time(t)
	_kill(t)
	_relay(t)
	_doom_takes_all(t)
	_vigil_kill(t)
	_burn_and_kill_same_cast(t)
	_tags(t)
	_freed(t)
	_fright_and_release(t)
	_waiting(t)
	_gaze_faithful(t)
	_report_leaves_him(t)


## The crowd, the Rules (and so the Lantern) and a standalone Bearer, `seconds` of the night.
static func _go(s: Dictionary, seconds: float, b: LanternBearer = null) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).step_people(DT)
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)
		if b != null:
			b.step(DT)


## The bell tolls and the night runs until the Bearer has set out (or `limit` seconds).
static func _set_out(s: Dictionary, limit := 12.0) -> LanternBearer:
	LW._ring(s)
	var lw: LanternWatch = s.lw
	var left := limit
	while lw.bearer == null and left > 0.0:
		_go(s, DT)
		left -= DT
	return lw.bearer


## Everyone but `keep` within `reach` of `at` goes well away; `keep` stand where they are.
static func _clear(s: Dictionary, at: Vector2, reach: float, keep: Array) -> void:
	LW._clear_round(s, at, reach, keep)


## A standalone Bearer for a controlled walk: the nearest clergy citizen stands at the door, two lay citizens in file behind him (the tail's
## places), everyone else far away, so who is appointed is known. Returns {"b": LanternBearer, "s": world}.
static func _walkers(s: Dictionary) -> LanternBearer:
	var crowd: Crowd = s.crowd
	var d: MissionDirector = s.d
	var door := d.lantern_door()
	var foot := crowd.bell.foot
	var cleric: Person = null
	var lay: Array[Person] = []
	for p in crowd.citizens:
		if p == crowd.bell.keeper or p.profile == null or p.inside:
			continue
		if p.profile.role == CitizenProfile.Role.CLERGY:
			if cleric == null:
				cleric = p
		elif lay.size() < 2 and not p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			lay.append(p)
	_clear(s, door, 16.0, [cleric, lay[0], lay[1]])
	Kit.arrive(cleric, door)
	for i in 2:
		Kit.arrive(lay[i], door + Vector2(0.4 * float(i + 1), 0.0))
	var b := LanternBearer.new().setup(s.rules, crowd, door, foot, [])
	# The escorts stand in the file's places already (they would otherwise come in from where they were): a snapped tail can be nearer than
	# the file keeps, and the spread rule is for the file, not for the first seconds of two people arriving.
	for i in b.escorts.size():
		var place: Vector2 = b._places[i]
		if place != Vector2.INF:
			Kit.arrive(b.escorts[i], place)
	return b


static func _min_pair(b: LanternBearer) -> float:
	var ps := b.walkers()
	var best := INF
	for i in ps.size():
		for j in range(i + 1, ps.size()):
			best = minf(best, ps[i].ground_pos.distance_to(ps[j].ground_pos))
	return best


## Review: BEARER_AFTER mission seconds after the toll (not before), the banner once, three people on DUTY, the carrier clergy if any.
static func _sets_out(t) -> void:
	var s := LW._world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_go(s, 3.0)
	LW._ring(s)
	_go(s, DT * 2.0)
	var toll := lw.tolled_at
	t.check(lw.tolled and lw.bearer == null, "the toll: no Bearer yet")
	while r.mission_time() < toll + LanternBearer.AFTER - 0.3:
		_go(s, DT)
	t.check(lw.bearer == null and (s.banners as Array).count(LanternBearer.SET_OUT) == 0, "0.3 mission seconds before AFTER: nobody has set out")
	while lw.bearer == null and r.mission_time() < toll + LanternBearer.AFTER + 1.0:
		_go(s, DT)
	var b := lw.bearer
	t.check(b != null and b.state == LanternBearer.State.WALKING and (s.banners as Array).count(LanternBearer.SET_OUT) == 1,
		"at toll + AFTER the Bearer sets out, the banner once")
	if b == null:
		Kit.done(s)
		return
	t.check(r.mission_time() - toll >= LanternBearer.AFTER - 0.01 and r.mission_time() - toll < LanternBearer.AFTER + 0.1,
		"(at mission second %.2f after the toll)" % (r.mission_time() - toll))
	var on_duty := 0
	for p in b.walkers():
		if p.mind == Person.Mind.DUTY:
			on_duty += 1
	t.check(b.walkers().size() == 1 + LanternBearer.ESCORTS and on_duty == 3, "three people on DUTY: the Bearer and two escorts (%d / %d)" % [b.walkers().size(), on_duty])
	t.check(b.carrier.profile.role == CitizenProfile.Role.CLERGY, "the Bearer is of the clergy")
	for e: Variant in b.escorts:
		t.check((e as Person).profile.role != CitizenProfile.Role.CLERGY, "an escort is a lay citizen")
	t.check(is_equal_approx(float(b.carrier.statuses.get(&"slow", 1.0)), LanternBearer.SLOW), "the Bearer is slowed")
	t.check(LanternBearer.AFTER == 10.0 and LanternBearer.SLOW == 0.3 and LanternBearer.ESCORTS == 2 and LanternBearer.ESCORT_GAP == 2.2
		and LanternBearer.ESCORT_SEE == 3.0 and LanternBearer.ESCORT_RELAY and LanternBearer.RETARGET == 0.5, "the spec's numbers")
	t.check(lw.hint_phase() == "bearer", "while he walks the hint is the Bearer's")
	Kit.done(s)


## Review (pre-flight): every pair of the three more than two Silent Doom radii apart, sampled every 0.5 s from 2 s after the set-out.
static func _spread(t) -> void:
	var s := LW._world()
	var b := _walkers(s)
	t.check(b.state == LanternBearer.State.WALKING and b.walkers().size() == 3, "(three walkers appointed)")
	var worst := INF
	var samples := 0
	var secs := 0.0
	while b.state == LanternBearer.State.WALKING and secs < 40.0:
		_go(s, 0.5, b)
		secs += 0.5
		if secs >= 2.0:
			worst = minf(worst, _min_pair(b))
			samples += 1
	t.check(samples > 20 and worst > 2.0 * SilentDoom.RADIUS, "the file stays spread over %d samples: closest pair %.2f > %.2f" % [samples, worst, 2.0 * SilentDoom.RADIUS])
	Kit.done(s)
	# As the night appoints them (escorts coming in from where they stood): in file within a few seconds of the set-out, apart from then on.
	var n := LW._world()
	var nb := _set_out(n)
	var worst_n := INF
	var samples_n := 0
	var secs_n := 0.0
	while nb.state == LanternBearer.State.WALKING and secs_n < 40.0:
		_go(n, 0.5)
		secs_n += 0.5
		if secs_n >= SETTLE:
			worst_n = minf(worst_n, _min_pair(nb))
			samples_n += 1
	t.check(samples_n > 20 and worst_n > 2.0 * SilentDoom.RADIUS, "appointed from where they stood, the file is apart from %.1f s on: closest pair %.2f" % [SETTLE, worst_n])
	Kit.done(n)


## From where he stands to the tower's foot he takes 15-30 s; seconds_left() falls about one a second; the vigil at the foot.
static func _walk_time(t) -> void:
	var s := LW._world()
	var b := _walkers(s)
	var start_left := b.seconds_left()
	t.check(start_left > 15.0 and start_left < 30.0, "the countdown at the start reads %.1f s" % start_left)
	_go(s, 3.0, b)
	var l3 := b.seconds_left()
	_go(s, 5.0, b)
	var l8 := b.seconds_left()
	t.check(absf((l3 - l8) / 5.0 - 1.0) < 0.3, "seconds_left() falls ~1 a second (%.2f per second)" % ((l3 - l8) / 5.0))
	var secs := 8.0
	while b.state == LanternBearer.State.WALKING and secs < 45.0:
		_go(s, DT, b)
		secs += DT
	t.check(secs > 15.0 and secs < 30.0 and b.state == LanternBearer.State.VIGIL, "he reaches the tower's foot in %.1f s and keeps the vigil" % secs)
	t.check((s.banners as Array).count(LanternBearer.VIGIL) == 1 and b.seconds_left() == 0.0, "the vigil banner once")
	_go(s, 4.0, b)
	var ring_ok := true
	for e: Variant in b.escorts:
		ring_ok = ring_ok and (e as Person).ground_pos.distance_to(b.carrier.ground_pos) > 1.6
	t.check(ring_ok and b.state == LanternBearer.State.VIGIL and b.carrier.ground_pos.distance_to(b.foot) <= 2.0,
		"at the tower the escorts stand round him, apart, and he stays")
	Kit.done(s)


## An unseen kill: the Bearer dead, the Lantern Blind, dawn back to x1.0.
static func _kill(t) -> void:
	var s := LW._world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var b := _set_out(s)
	_go(s, 4.0)
	lw.burn()
	_go(s, DT)
	t.check(lw.stage == LanternWatch.Stage.BURNING and is_equal_approx(r.clock_rate, 2.0), "(the Lantern burns, x2.0)")
	var victim := b.carrier
	var escorts: Array = b.escorts.duplicate()
	_clear(s, victim.ground_pos, 5.0, [victim])
	(s.crowd as Crowd)._field.kill(victim, &"fire")
	_go(s, DT * 3.0)
	t.check(b.dead() and lw.stage == LanternWatch.Stage.BLIND and is_equal_approx(r.clock_rate, 1.0), "an unseen kill: dead, the Lantern Blind, the clock back to x1.0")
	t.check((s.banners as Array).count(LanternWatch.BLIND_BANNER) == 1 and b.relays == 0, "the blind banner once, no relay")
	var slowed := false
	for e: Variant in escorts:
		slowed = slowed or ((e as Person).statuses.has(&"slow"))
	t.check(not slowed and lw.tags().is_empty() and lw.hint_phase() == "", "the escorts let go (no slow), no tags, the mission's own hint again")
	Kit.done(s)


## An escort within ESCORT_SEE of the fall takes the flame up: RELAY banner, relays 1; the second the same; a third kill finds none.
static func _relay(t) -> void:
	var s := LW._world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var b := _set_out(s)
	_go(s, 4.0)
	var crowd: Crowd = s.crowd
	var first := b.carrier
	var near1: Person = b.escorts[0]
	t.check(near1.ground_pos.distance_to(first.ground_pos) <= LanternBearer.ESCORT_SEE,
		"(an escort follows within sight: %.2f)" % near1.ground_pos.distance_to(first.ground_pos))
	crowd._field.kill(first, &"fire")
	_go(s, DT * 3.0)
	t.check(not b.dead() and b.carrier == near1 and b.relays == 1 and (s.banners as Array).count(LanternBearer.RELAY) == 1
		and lw.stage != LanternWatch.Stage.BLIND, "a kill with an escort in sight: he takes the flame up (RELAY once), the Lantern is not blind")
	t.check(not b.escorts.has(near1) and b.escorts.size() == 1, "(the new Bearer is no longer an escort)")
	_go(s, 2.0)
	t.check(b.carrier.mind == Person.Mind.DUTY or b.carrier.mind in LanternBearer.RESUMABLE or b.carrier.mind == Person.Mind.PANIC,
		"(and walks on)")
	var second := b.carrier
	var near2: Person = b.escorts[0]
	t.check(near2.ground_pos.distance_to(second.ground_pos) <= LanternBearer.ESCORT_SEE + 1.0, "(the other escort is close behind)")
	Kit.arrive(near2, second.ground_pos + Vector2(1.5, 0.0))
	crowd._field.kill(second, &"fire")
	_go(s, DT * 3.0)
	t.check(not b.dead() and b.carrier == near2 and b.relays == 2 and (s.banners as Array).count(LanternBearer.RELAY) == 2,
		"a second relay: the other escort carries on (relays 2)")
	var third := b.carrier
	_clear(s, third.ground_pos, 5.0, [third])
	crowd._field.kill(third, &"fire")
	_go(s, DT * 3.0)
	t.check(b.dead() and lw.stage == LanternWatch.Stage.BLIND and is_equal_approx(r.clock_rate, 1.0) and b.relays == 2,
		"a third kill with no escort left: dead, the Lantern Blind")
	Kit.done(s)
	# An escort out of sight (beyond ESCORT_SEE) does not take it.
	var f := LW._world()
	var fl: LanternWatch = f.lw
	var fb := _set_out(f)
	_go(f, 4.0)
	var victim := fb.carrier
	for e: Variant in fb.escorts:
		Kit.arrive(e as Person, victim.ground_pos + Vector2(LanternBearer.ESCORT_SEE + 0.8, 0.0))
	_clear(f, victim.ground_pos, 5.0, [victim] + fb.escorts)
	for e: Variant in fb.escorts:
		Kit.arrive(e as Person, victim.ground_pos + Vector2(LanternBearer.ESCORT_SEE + 0.8, 0.0))
	(f.crowd as Crowd)._field.kill(victim, &"fire")
	_go(f, DT * 3.0)
	t.check(fb.dead() and fl.stage == LanternWatch.Stage.BLIND, "escorts farther than ESCORT_SEE do not see him fall: dead")
	Kit.done(f)
	# A held escort (whispered) sees nothing.
	var h := LW._world()
	var hb := _set_out(h)
	_go(h, 4.0)
	var hv := hb.carrier
	_clear(h, hv.ground_pos, 5.0, [hv] + hb.escorts)
	for e: Variant in hb.escorts:
		(e as Person).mind = Person.Mind.WHISPERED
	(h.crowd as Crowd)._field.kill(hv, &"fire")
	_go(h, DT * 3.0)
	t.check(hb.dead(), "an escort held by the god (whispered) does not take the flame")
	Kit.done(h)


## Silent Doom judged after a cast's other victims: a Doom that takes the Bearer and both escorts leaves nobody to see.
static func _doom_takes_all(t) -> void:
	var s := LW._world()
	var lw: LanternWatch = s.lw
	var b := _set_out(s)
	_go(s, 3.0)
	var crowd: Crowd = s.crowd
	var three := b.walkers()
	_clear(s, b.carrier.ground_pos, 6.0, three)
	for p in three:
		crowd._field.kill(p, &"doom")
	_go(s, DT * 4.0)
	t.check(b.dead() and lw.stage == LanternWatch.Stage.BLIND and b.relays == 0,
		"a Doom that takes all three (judged after the cast's other victims): nobody to see, the Lantern Blind")
	Kit.done(s)


## D23: at the tower he can still be killed; there is no relay at the vigil.
static func _vigil_kill(t) -> void:
	var s := LW._world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var b := _set_out(s)
	_go(s, 2.0)
	Kit.arrive(b.carrier, b.foot + Vector2(0.3, 0.0))
	_go(s, 6.0)
	t.check(b.state == LanternBearer.State.VIGIL and lw.hint_phase() == "" and lw.stage != LanternWatch.Stage.BLIND, "(he keeps the vigil; the speed-up stays: %s)" % lw.stage)
	t.check(is_equal_approx(r.clock_rate, 1.5), "the clock is still hastened at the tower")
	var victim := b.carrier
	var near: Person = b.escorts[0]
	Kit.arrive(near, victim.ground_pos + Vector2(1.0, 0.0))
	(s.crowd as Crowd)._field.kill(victim, &"fire")
	_go(s, DT * 3.0)
	t.check(b.dead() and b.relays == 0 and lw.stage == LanternWatch.Stage.BLIND and is_equal_approx(r.clock_rate, 1.0),
		"killed at the tower: no relay (even with an escort beside him), the Lantern Blind")
	Kit.done(s)


## Review focus 5: a Heaven Splitter in the beam that kills the Bearer and burns the Lantern in the same cast: the kill wins, in either order.
static func _burn_and_kill_same_cast(t) -> void:
	for order in ["cast_first", "kill_first"]:
		var s := LW._world()
		var lw: LanternWatch = s.lw
		var r: Rules = s.rules
		var b := _set_out(s)
		_go(s, 1.0)
		var victim := b.carrier
		var at := lw.light.aim(0)
		Kit.arrive(victim, at)
		_clear(s, at, 5.0, [victim])
		t.check(lw.light.touches(at) and lw.stage == LanternWatch.Stage.STIRRING, "(%s: the Bearer stands in the beam, Stirring)" % order)
		if order == "cast_first":
			r.cast_made.emit(0, "heaven", at)
			(s.crowd as Crowd)._field.kill(victim, &"fire")
		else:
			(s.crowd as Crowd)._field.kill(victim, &"fire")
			r.cast_made.emit(0, "heaven", at)
		_go(s, DT * 4.0)
		t.check(lw.stage == LanternWatch.Stage.BLIND and is_equal_approx(r.clock_rate, 1.0) and b.dead(),
			"%s: the kill wins over the burn: Blind, x1.0" % order)
		Kit.done(s)


## The tags (spec 5.2): colours, labels, the arrows, the countdown in mission seconds; the strip's rows; the vigil's tag.
static func _tags(t) -> void:
	var s := LW._world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	LW._ring(s)
	_go(s, 1.0)
	var rows := lw.strip_rows()
	t.check(rows.size() == 1 and rows[0]["label"] == "The Lantern-Bearer sets out" and float(rows[0]["in"]) > 5.0 and float(rows[0]["in"]) < LanternBearer.AFTER,
		"before he sets out the strip says so, in mission seconds (%s)" % [rows])
	t.check(lw.tags().is_empty() and lw.hint_phase() == "stirring", "(no tags yet; the Stirring hint)")
	var b := _set_out(s)
	_go(s, 2.0)
	var by := {}
	for m in lw.tags():
		by[m.label] = m
	var carrier_label := "LANTERN-BEARER - AT THE TOWER IN %s" % UiTheme.clock(b.seconds_left() * r.clock_rate)
	t.check(by.has(carrier_label), "the Bearer's tag counts down in mission seconds: %s (have %s)" % [carrier_label, by.keys()])
	if by.has(carrier_label):
		var m: MapTag = by[carrier_label]
		t.check(m.color == Color("d8b23a") and m.edge and m.at.is_equal_approx(b.carrier.ground_pos), "gold, edge-arrowed, on the Bearer")
	var esc := 0
	for m in lw.tags():
		if m.label == "ESCORT":
			esc += 1
			t.check(m.color == Color("c8342a") and m.edge, "an escort: red, edge-arrowed")
	t.check(esc == 2, "two escorts tagged")
	t.check(by.has("BELL TOWER") and (by["BELL TOWER"] as MapTag).color == Color("ff9a3a") and (by["BELL TOWER"] as MapTag).lift == MapTag.PLACE_LIFT,
		"the bell tower: an orange place tag while he walks")
	rows = lw.strip_rows()
	t.check(rows.size() == 1 and rows[0]["label"] == "The Bearer reaches the bell tower"
		and absf(float(rows[0]["in"]) - b.seconds_left() * r.clock_rate) < 0.01, "the strip: the Bearer reaches the bell tower, in mission seconds")
	lw.burn()
	_go(s, DT)
	var burning := "LANTERN-BEARER - AT THE TOWER IN %s" % UiTheme.clock(b.seconds_left() * 2.0)
	var found := false
	for m in lw.tags():
		found = found or m.label == burning
	t.check(found, "at x2.0 the countdown is the walk times 2.0")
	# The vigil.
	Kit.arrive(b.carrier, b.foot + Vector2(0.3, 0.0))
	_go(s, 1.0)
	var vigil := {}
	for m in lw.tags():
		vigil[m.label] = m
	t.check(vigil.has("LANTERN-BEARER - KEEPS THE VIGIL") and not vigil.has("BELL TOWER") and lw.strip_rows().is_empty(),
		"at the tower: KEEPS THE VIGIL, no tower tag, no strip row")
	Kit.done(s)


## An escort freed (a body gone) and the Bearer freed with no death to judge: no error; the file closes up.
static func _freed(t) -> void:
	var s := LW._world()
	var crowd: Crowd = s.crowd
	var b := _walkers(s)
	_go(s, 3.0, b)
	var gone: Person = b.escorts[0]
	var rest: Person = b.escorts[1]
	crowd._field.kill(gone, &"fire")
	b.on_killed(gone)
	crowd._field.remove(gone)
	crowd.citizens.erase(gone)
	gone.free()
	_go(s, 4.0, b)
	t.check(b.state == LanternBearer.State.WALKING and b.walkers().size() == 2 and b.escorts.size() == 1 and b.escorts[0] == rest,
		"an escort freed: the file closes up on the other")
	var gap := rest.ground_pos.distance_to(b.carrier.ground_pos)
	t.check(gap < 4.5 and gap > 1.6, "(he keeps his distance behind the Bearer: %.2f)" % gap)
	# The Bearer freed without a kill: judged as a fall where he was last seen; the escort in sight carries on.
	var last := b.carrier
	crowd._field.remove(last)
	crowd.citizens.erase(last)
	last.free()
	_go(s, DT * 4.0, b)
	t.check(b.carrier == rest and b.relays == 1, "the Bearer freed with no death: the escort in sight takes the flame up")
	Kit.done(s)


## A fright runs at its own pace (the slow is the walk's alone); the walk resumes, slowed, once back on his feet; teardown lets go.
static func _fright_and_release(t) -> void:
	var s := LW._world()
	var lw: LanternWatch = s.lw
	var b := _set_out(s)
	_go(s, 2.0)
	var c := b.carrier
	t.check(c.statuses.has(&"slow"), "(slowed on the walk)")
	c.panic(c.ground_pos + Vector2(2.0, 2.0), 3.0)
	_go(s, DT * 2.0)
	t.check(c.mind == Person.Mind.PANIC and not c.statuses.has(&"slow"), "frightened, he runs at his own pace: no slow while in a panic")
	var secs := 0.0
	while c.mind != Person.Mind.DUTY and secs < 40.0:
		_go(s, 0.5)
		secs += 0.5
	t.check(c.mind == Person.Mind.DUTY and is_equal_approx(float(c.statuses.get(&"slow", 1.0)), LanternBearer.SLOW),
		"back on his feet he takes the walk up again, slowed (%.1f s)" % secs)
	var walkers := b.walkers()
	lw.teardown()
	var clean := true
	for p in walkers:
		clean = clean and not p.statuses.has(&"slow")
	t.check(clean and b.dead(), "teardown (the act ends) undoes the slowing")
	Kit.done(s)


## With nobody free he waits and tries again.
static func _waiting(t) -> void:
	var s := LW._world()
	var crowd: Crowd = s.crowd
	var all: Array = []
	for p in crowd.citizens:
		all.append(p)
	for p: Person in all:
		p.inside = true
	var b := LanternBearer.new().setup(s.rules, crowd, (s.d as MissionDirector).lantern_door(), crowd.bell.foot, [])
	t.check(b.state == LanternBearer.State.WAITING and b.phase() == "" and b.tags().is_empty() and b.walkers().is_empty(),
		"nobody out of doors: he waits (no tags, no walkers)")
	for p: Person in all:
		p.inside = false
	_go(s, 1.0, b)
	t.check(b.state == LanternBearer.State.WALKING and b.walkers().size() == 3, "once people are out he is appointed")
	# The reserved are never chosen.
	var res: Array = [crowd.citizens[0], crowd.citizens[1], crowd.citizens[2]]
	var b2 := LanternBearer.new().setup(s.rules, crowd, (s.d as MissionDirector).lantern_door(), crowd.bell.foot, res)
	var none := true
	for p in b2.walkers():
		none = none and not res.has(p)
	t.check(none and b2.walkers().size() == 3, "people the night has set aside are not appointed")
	# ... nor anyone a director has busy.
	var busy := crowd.citizens[10]
	var b3 := LanternBearer.new().setup(s.rules, crowd, busy.ground_pos, crowd.bell.foot, [], func(p: Person) -> bool: return p == busy)
	t.check(not b3.walkers().has(busy), "nor one the skip rule names")
	b.release()
	b2.release()
	b3.release()
	Kit.done(s)


## A gaze night's escorts are Faithful (pre-flight GAP); elsewhere they are plain lay citizens.
static func _gaze_faithful(t) -> void:
	var g := LW._world("gaze")
	var gb := _set_out(g)
	var d: MissionDirector = g.d
	var all := true
	for e: Variant in gb.escorts:
		all = all and d.faithful.has(e)
	t.check(gb.escorts.size() == 2 and all and not d.faithful.has(gb.carrier), "a gaze night: both escorts are made Faithful (the Bearer is not)")
	Kit.done(g)
	var w := LW._world("watch")
	var wb := _set_out(w)
	var d2: MissionDirector = w.d
	var none := true
	for e: Variant in wb.escorts:
		none = none and not d2.faithful.has(e)
	t.check(wb.escorts.size() == 2 and none, "a watch night: plain lay citizens")
	Kit.done(w)


## A Faithful escort who sees a death is not pulled off the errand by a report, and the director can name its own busy people.
static func _report_leaves_him(t) -> void:
	var s := LW._world("gaze")
	var b := _set_out(s)
	var d: MissionDirector = s.d
	var e: Person = b.escorts[0]
	d.reports.clear()
	d._report(e, d.lantern_door())
	t.check(d.reports.is_empty(), "a director's report does not take an escort off the errand")
	d._report(b.carrier, d.lantern_door())
	t.check(d.reports.is_empty(), "nor the Bearer")
	var other: Person = null
	for p in (s.crowd as Crowd).citizens:
		if not b.walkers().has(p) and not p.inside:
			other = p
			break
	d._report(other, d.lantern_door())
	t.check(d.reports.size() == 1, "(anyone else still can be sent)")
	t.check(not d.busy(e), "MissionDirector.busy() is false by default")
	Kit.done(s)
