extends RefCounted
## v0.11.2 Task 7: LanternWatch, the core of The Lantern Turns (spec 4.1-4.4, 4.7, 4.9, 4.10) -- the mechanism with every seam, which no night
## adopts yet. A Kit world (tests/test_tier2_groundwork.gd) with a stub director and a Lantern attached by hand.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05


## A director that has stopped every warning it has (StarsObjective's tally), for the win-versus-Herald checks.
class AllStopped:
	extends MissionDirector

	func stars_stopped() -> int:
		return 3

	func stars_total() -> int:
		return 3


static func run(t) -> void:
	_asleep(t)
	_toll(t)
	_beams(t)
	_burn(t)
	_quiet_in_beam(t)
	_blind(t)
	_latches(t)
	_gaze(t)
	_result(t)
	_heard_beats_win(t)
	_no_lantern(t)
	_seams(t)


## A bell-ringers town (Organized: it has a bellkeeper) with a stub director and a Lantern of `kind` on its Rules. The mission's only objective
## is HeraldObjective, so nothing ends the night by itself.
static func _world(kind := "watch") -> Dictionary:
	var def := MissionBook.bell_ringers()
	def.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [HeraldObjective.new()]
		return out
	var s := Kit.world(def, MissionDirector.new())
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, kind)
	(s.rules as Rules).lantern = lw
	s["lw"] = lw
	return s


## The bell tolls as it does in play: a keeper on the rope, the climb done.
static func _ring(s: Dictionary) -> void:
	var bell: BellNetwork = (s.crowd as Crowd).bell
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()


## `seconds` of the night for the Rules alone (the Lantern, the clock, the beam): the crowd does not move.
static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.rules as Rules).advance(DT)


static func _count(s: Dictionary, line: String) -> int:
	return (s.banners as Array).count(line)


## Everyone but `keep` within `reach` of `at` is sent well away, so nobody but `keep` can witness there.
static func _clear_round(s: Dictionary, at: Vector2, reach: float, keep: Array) -> void:
	var crowd: Crowd = s.crowd
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				Kit.arrive(p, at + Vector2(reach + 8.0, reach + 8.0))


## A citizen stands at `at`, to fall there.
static func _victim(s: Dictionary, at: Vector2) -> Person:
	var p: Person = (s.crowd as Crowd).citizens[0]
	Kit.arrive(p, at)
	p.inside = false
	return p


static func _asleep(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_run(s, 1.0)
	t.check(lw.stage == LanternWatch.Stage.ASLEEP and not lw.tolled and is_equal_approx(lw.rate(), 1.0)
		and is_equal_approx(r.clock_rate, 1.0) and lw.badge() == "" and not lw.light.on and lw.hint_phase() == ""
		and lw.tags().is_empty() and lw.strip_rows().is_empty() and not lw.herald_running() and not lw.blocks_win(),
		"before the toll: Asleep, rate 1.0, no beam, no badge, no hint, no tags, no strip rows")
	t.check(lw.RATES == [1.0, 1.5, 2.0, 1.0] and lw.GAZE_TOLL == 40.0 and lw.BEAM_HOLD == 6.0 and lw.BURN_HINT == 8.0
		and lw.HERALD_DESCEND == 5.0 and lw.HERALD_SLOW == 0.4, "the numbers: rates 1 / 1.5 / 2 / 1, GAZE_TOLL 40, BEAM_HOLD 6, BURN_HINT 8, the Herald's 5 s and 0.4")
	var before := r.time_left
	r.cast_made.emit(0, "smite", Vector2(0.0, 8.0))
	t.check(not lw.light.on and lw.light.noise == Vector2.INF, "a loud cast before the toll lights nothing and is not heard")
	t.check(is_equal_approx(before, r.time_left), "(the clock was not touched by the cast)")
	Kit.done(s)


static func _toll(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_run(s, 3.0)
	_ring(s)
	_run(s, 0.1)
	t.check(lw.tolled and lw.stage == LanternWatch.Stage.STIRRING and is_equal_approx(r.clock_rate, 1.5),
		"the toll: Stirring, the clock at x1.5")
	t.check(_count(s, LanternWatch.TOLL_BANNER) == 1 and lw.light.beams() == 1 and not r.finished,
		"one banner, one beam, and the night is not lost")
	t.check(lw.tolled_at >= 2.9 and lw.tolled_at < 3.3, "it tolled at mission second ~3 (%.2f)" % lw.tolled_at)
	t.check(lw.badge() == "x1.5" and lw.hint_phase() == "stirring" and lw.light.hunt and is_equal_approx(lw.light.hold, LanternWatch.BEAM_HOLD),
		"badge x1.5, the Stirring hint, a hunting beam that holds BEAM_HOLD")
	var t0 := r.time_left
	var m0 := r.mission_time()
	_run(s, 1.0)
	t.check(is_equal_approx(t0 - r.time_left, 1.5) and is_equal_approx(r.mission_time() - m0, 1.5),
		"a second of the night is 1.5 mission seconds")
	t.check(is_equal_approx(lw.light.spire.distance_to(TownLayout.TEMPLE.get_center()), 0.0), "the beam stands on the Temple's spire")
	var d: MissionDirector = s.d
	t.check(d.lantern_door().is_equal_approx(d._walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6)))
		and lw.door().is_equal_approx(d.lantern_door()) and MissionDirector.lantern_door_in(s.crowd).is_equal_approx(d.lantern_door()),
		"lantern_door() is the walkable point 0.6 south of the Temple (the name leaves the directors' own temple_door alone)")
	Kit.done(s)


## One beam at Stirring however old the light, two at Burning (R25, the pre-flight's beam_cap).
static func _beams(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	_ring(s)
	_run(s, Searchlight.SECOND_AFTER + 10.0)
	t.check(lw.stage == LanternWatch.Stage.STIRRING and lw.light.beams() == 1, "40 s after the toll, still Stirring: still one beam")
	lw.burn()
	t.check(lw.light.beams() == 2 and lw.light.aim(1).is_finite(), "Burning lights the second at once, on its path")
	_run(s, 1.0)
	t.check(lw.light.beams() == 2 and lw.light.touches(lw.light.aim(1)), "and keeps two")
	Kit.done(s)
	# A beam hears: hunting at once, held BEAM_HOLD, then back to its sweep.
	var h := _world()
	var hl: LanternWatch = h.lw
	_ring(h)
	_run(h, 1.0)
	var far := hl.light.aim(0) + Vector2(3.0, 9.0)
	(h.rules as Rules).cast_made.emit(0, "heaven", far)
	_run(h, 0.1)
	t.check(hl.light.searching and hl.light.search_beam == 0, "a loud cast is heard: the beam goes to it at once (hunt)")
	_run(h, 3.0)
	t.check(hl.light.aim(0).distance_to(far) < 0.1, "and holds there")
	_run(h, LanternWatch.BEAM_HOLD)
	t.check(not hl.light.searching, "and goes back to its sweep after BEAM_HOLD seconds")
	Kit.done(h)


static func _burn(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_ring(s)
	_run(s, 0.5)
	var hit := lw.light.aim(0)
	t.check(lw.light.touches(hit) and lw.stage == LanternWatch.Stage.STIRRING, "(the beam is where the cast will fall)")
	r.cast_made.emit(0, "smite", hit)
	_run(s, 0.1)
	t.check(lw.stage == LanternWatch.Stage.BURNING and is_equal_approx(r.clock_rate, 2.0) and lw.light.beams() == 2 and lw.badge() == "x2.0",
		"a loud power cast into the beam: Burning, x2.0, two beams")
	t.check(_count(s, LanternWatch.BURN_BANNER) == 1 and lw.hint_phase() == "burning", "the banner once, the Burning hint")
	r.cast_made.emit(0, "smite", lw.light.aim(1))
	_run(s, 0.1)
	t.check(_count(s, LanternWatch.BURN_BANNER) == 1 and lw.stage == LanternWatch.Stage.BURNING, "a second cast in a beam changes nothing")
	_run(s, LanternWatch.BURN_HINT + 0.5)
	t.check(lw.stage == LanternWatch.Stage.BURNING and lw.hint_phase() == "stirring",
		"it never falls back to Stirring; after BURN_HINT the hint is the Stirring one again (no Bearer yet)")
	Kit.done(s)
	# A loud cast outside the beam heard, not burning.
	var o := _world()
	var ol: LanternWatch = o.lw
	_ring(o)
	_run(o, 0.5)
	(o.rules as Rules).cast_made.emit(0, "smite", ol.light.aim(0) + Vector2(POOL_PLUS, 0.0))
	_run(o, 0.1)
	t.check(ol.stage == LanternWatch.Stage.STIRRING and ol.light.noise != Vector2.INF, "a loud cast outside the beam is heard but does not burn it")
	Kit.done(o)
	# A death someone sees inside the beam burns it; one nobody sees does not.
	var seen := _world()
	var sl: LanternWatch = seen.lw
	_ring(seen)
	_run(seen, 0.5)
	var at := sl.light.aim(0)
	var victim := _victim(seen, at)
	var witness: Person = (seen.crowd as Crowd).citizens[1]
	Kit.arrive(witness, at + Vector2(1.0, 0.0))
	witness.inside = false
	_clear_round(seen, at, 3.0, [victim, witness])
	(seen.crowd as Crowd)._field.kill(victim, &"fire")
	_run(seen, DT * 2.0)
	t.check(sl.stage == LanternWatch.Stage.BURNING, "a death in the beam that someone saw: Burning")
	Kit.done(seen)
	var unseen := _world()
	var ul: LanternWatch = unseen.lw
	_ring(unseen)
	_run(unseen, 0.5)
	var at2 := ul.light.aim(0)
	var v2 := _victim(unseen, at2)
	_clear_round(unseen, at2, 3.0, [v2])
	(unseen.crowd as Crowd)._field.kill(v2, &"fire")
	_run(unseen, DT * 2.0)
	t.check(ul.stage == LanternWatch.Stage.STIRRING and ul.light.noise.distance_to(at2) < 0.01,
		"a death in the beam that nobody saw: heard, but still Stirring")
	Kit.done(unseen)
	# A death someone saw OUTSIDE the beam does not burn it either.
	var out := _world()
	var xl: LanternWatch = out.lw
	_ring(out)
	_run(out, 0.5)
	var at3 := xl.light.aim(0) + Vector2(POOL_PLUS + 4.0, 0.0)
	var v3 := _victim(out, at3)
	var w3: Person = (out.crowd as Crowd).citizens[1]
	Kit.arrive(w3, at3 + Vector2(1.0, 0.0))
	w3.inside = false
	_clear_round(out, at3, 3.0, [v3, w3])
	(out.crowd as Crowd)._field.kill(v3, &"fire")
	_run(out, DT * 2.0)
	t.check(xl.stage == LanternWatch.Stage.STIRRING, "a seen death outside the beam: Stirring")
	Kit.done(out)


const POOL_PLUS := Searchlight.POOL_R + 0.5


## A quiet power cast in the beam does nothing (D19), and is not even heard.
static func _quiet_in_beam(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	_ring(s)
	_run(s, 0.5)
	(s.rules as Rules).cast_made.emit(0, "doom", lw.light.aim(0))
	(s.rules as Rules).cast_made.emit(0, "whisper", lw.light.aim(0))
	_run(s, 0.2)
	t.check(lw.stage == LanternWatch.Stage.STIRRING and lw.light.noise == Vector2.INF and _count(s, LanternWatch.BURN_BANNER) == 0,
		"Silent Doom and Mind Whisper cast in the beam: still Stirring, nothing heard")
	Kit.done(s)


static func _blind(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_ring(s)
	_run(s, 0.5)
	lw.burn()
	_run(s, 0.1)
	lw.blind()
	_run(s, 0.1)
	t.check(lw.stage == LanternWatch.Stage.BLIND and is_equal_approx(r.clock_rate, 1.0) and not lw.light.on and lw.light.beams() == 0
		and lw.badge() == "" and lw.hint_phase() == "", "blind: the clock back to x1.0, the beams out, no badge, no hint")
	t.check(_count(s, LanternWatch.BLIND_BANNER) == 1, "BLIND_BANNER once")
	lw.burn()
	r.cast_made.emit(0, "smite", Vector2(0.0, 8.0))
	_ring(s)
	_run(s, 0.1)
	t.check(lw.stage == LanternWatch.Stage.BLIND and is_equal_approx(r.clock_rate, 1.0), "Blind is final: neither a burn, a cast nor a toll turns it again")
	lw.blind()
	t.check(_count(s, LanternWatch.BLIND_BANNER) == 1, "(and goes blind only once)")
	Kit.done(s)
	# Blind before any toll (the Bearer cannot be, but a forced Lantern can): the toll then turns nothing.
	var b := _world()
	var bl: LanternWatch = b.lw
	bl.blind()
	_ring(b)
	t.check(bl.stage == LanternWatch.Stage.BLIND and not bl.tolled and _count(b, LanternWatch.TOLL_BANNER) == 0, "a blind Lantern is not woken by a toll")
	Kit.done(b)


## Review focus 5: the toll is latched. A bell unrung by The Bell Lies and rung again turns nothing a second time.
static func _latches(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_ring(s)
	_run(s, 0.2)
	lw.burn()
	var at := lw.tolled_at
	(s.crowd as Crowd).unring_bell()
	t.check((s.crowd as Crowd).bell.state == BellNetwork.State.WAITING, "(the bell is unrung)")
	_run(s, 2.0)
	_ring(s)
	_run(s, 0.1)
	t.check(_count(s, LanternWatch.TOLL_BANNER) == 1 and lw.stage == LanternWatch.Stage.BURNING and lw.tolled_at == at
		and is_equal_approx(r.clock_rate, 2.0), "a second toll after an unring: no second banner, the stage and the time unchanged")
	Kit.done(s)


## A gaze night: the toll adds GAZE_TOLL (40) to the director's Gaze, once, and fills nothing.
static func _gaze(t) -> void:
	var s := _world("gaze")
	var d: MissionDirector = s.d
	d.gaze = GazeMeter.new()
	_ring(s)
	_run(s, 0.1)
	t.check(is_equal_approx(d.gaze.value, LanternWatch.GAZE_TOLL) and not d.gaze.is_full(), "a gaze night's toll: the Gaze at 40, not 100")
	(s.crowd as Crowd).unring_bell()
	_ring(s)
	t.check(is_equal_approx(d.gaze.value, 40.0), "and a second toll adds nothing")
	Kit.done(s)
	var w := _world("watch")
	var wd: MissionDirector = w.d
	wd.gaze = GazeMeter.new()
	_ring(w)
	t.check(is_equal_approx(wd.gaze.value, 0.0), "a watch night's toll leaves a Gaze alone")
	Kit.done(w)
	var h := _world("herald")
	var hd: MissionDirector = h.d
	hd.gaze = GazeMeter.new()
	_ring(h)
	t.check(is_equal_approx(hd.gaze.value, 0.0), "and so does a herald night's")
	Kit.done(h)


static func _result(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	t.check(r.result()["tolled"] == false, "the result says it has not tolled before the toll")
	_ring(s)
	_run(s, 0.1)
	t.check(r.result()["tolled"] == true, "and that it tolled after")
	var ho := HeraldObjective.new()
	t.check(ho.label == "Stop the Herald" and ho.reason == "lantern" and ho.check(r) == Objective.Status.PENDING and ho.hud_text(r) == "",
		"HeraldObjective: 'Stop the Herald', reason lantern, pending, nothing on the HUD while none runs")
	lw.heralds.append(TempleReport.new((s.crowd as Crowd).citizens[0], lw.door()))
	t.check(lw.herald_running() and ho.hud_text(r) == "Stop the Herald" and lw.hint_phase() == "herald",
		"a Herald running: the HUD says so, and the hint is the Herald's before any other")
	lw.heard = true
	t.check(ho.check(r) == Objective.Status.FAILED, "once the Lantern has heard: FAILED")
	Kit.done(s)
	# Without a Lantern the objective never fails, and the result says it did not toll.
	var n := Kit.world(MissionBook.bell_ringers(), MissionDirector.new())
	t.check(HeraldObjective.new().check(n.rules) == Objective.Status.PENDING and n.rules.result()["tolled"] == false,
		"no Lantern: HeraldObjective is pending and the result says not tolled")
	Kit.done(n)


## Pre-flight BLOCKING: a Herald who reaches the Temple must not let the night read as won. Objectives decide in list order and the main one
## (Warning, Stars) comes first, so it must not be DONE while a Herald runs or has been heard.
static func _heard_beats_win(t) -> void:
	for variant in ["warning", "stars"]:
		for k in 3:
			var def := MissionBook.warning()
			def.make_objectives = func() -> Array[Objective]:
				var main: Objective = WarningObjective.new() if variant == "warning" else StarsObjective.new()
				var out: Array[Objective] = [main, HeraldObjective.new()]
				return out
			var d: MissionDirector = def.make_director() if variant == "warning" else AllStopped.new()
			var s := Kit.world(def, d)
			var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, "herald")
			(s.rules as Rules).lantern = lw
			if variant == "warning":
				(d as WarningDirector).warning_dead = true
			var label := "%s, case %d" % [variant, k]
			if k == 0:
				_run(s, DT * 2.0)
				t.check((s.rules as Rules).finished and (s.rules as Rules).won, "all warnings dead and no Herald: won (%s)" % label)
			elif k == 1:
				var report := TempleReport.new((s.crowd as Crowd).citizens[0], lw.door())
				lw.heralds.append(report)
				_run(s, DT * 2.0)
				t.check(not (s.rules as Rules).finished, "all warnings dead but a Herald runs: not won yet (%s)" % label)
				report.dead = true
				_run(s, DT * 2.0)
				t.check((s.rules as Rules).finished and (s.rules as Rules).won, "he is stopped: won (%s)" % label)
			else:
				lw.heard = true
				_run(s, DT * 2.0)
				var rl: Rules = s.rules
				t.check(rl.finished and not rl.won and rl.over_reason == "lantern",
					"all warnings dead but the Herald got in: LOST, reason lantern, never a win (%s)" % label)
			Kit.done(s)


## A Rules with no Lantern is what it was: the toll is the town's alarm, the rate is whatever was set.
static func _no_lantern(t) -> void:
	var s := Kit.world(MissionBook.bell_ringers(), MissionDirector.new())
	var r: Rules = s.rules
	t.check(r.lantern == null and MissionBook.bell_ringers().lantern == "" and MissionBook.warning().lantern == ""
		and MissionBook.long_night().lantern == "" and TierBook.board("festival").lantern == "", "no mission names a Lantern yet (MissionDef.lantern is \"\")")
	_ring(s)
	_run(s, 1.0)
	t.check(is_equal_approx(r.clock_rate, 1.0) and not (s.banners as Array).has(LanternWatch.TOLL_BANNER),
		"no Lantern: the toll leaves the rate at 1.0 and shows no Lantern banner")
	r.clock_rate = 2.0
	_run(s, 0.1)
	t.check(is_equal_approx(r.clock_rate, 2.0), "and a forced rate stays forced (only a Lantern sets it every frame)")
	Kit.done(s)


## The seams Tasks 10 and 11 fill do nothing here, and teardown lets go of every signal.
static func _seams(t) -> void:
	var s := _world()
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	_ring(s)
	_run(s, 0.2)
	t.check(lw.bearer == null and lw.heralds.is_empty() and lw.tags().is_empty() and lw.strip_rows().is_empty() and not lw.heard,
		"the Bearer and the Heralds are not there yet: no tags, no rows")
	var bell: BellNetwork = (s.crowd as Crowd).bell
	r.teardown()
	t.check(r.lantern == null and not bell.rung.is_connected(lw.on_toll) and not r.cast_made.is_connected(lw._on_cast)
		and not (s.crowd as Crowd)._field.enemy_killed.is_connected(lw._on_killed) and not lw.light.on,
		"Rules.teardown() lets the Lantern go: its signals disconnected, its beam out")
	lw.on_toll()
	t.check(lw.stage == LanternWatch.Stage.STIRRING and _count(s, LanternWatch.TOLL_BANNER) == 1, "(a released Lantern does nothing more)")
	Kit.done(s)
