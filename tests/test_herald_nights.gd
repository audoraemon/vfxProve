extends RefCounted
## v0.11.2 Task 15: the Herald nights adopt the Lantern -- The Warning (campaign), The Omen (The Long Night's Act I), the board's Warning
## (Starfall) and The Bell-Ringers. The toll does not lose any of them (HeraldObjective in place of the old bell-silent objective, the kind "herald" on the
## mission or the act); a Herald who gets in does, a Herald killed unseen leaves the night to be won; Starfall's stars and The Bell-Ringers' posts
## keep their schedule in MISSION seconds while a stare, a post's lamp-lighting and every walk stay real (D20). Task 15 also owns the review-11
## items (C8): The Bell Lies' unring after a toll leaves the Herald running, the toll and the Herald banners both reach the HUD, the first Herald
## is sent in the normal form, a frightened Herald is not slowed, the town-keeper's relay skips a wisher.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const H := preload("res://tests/test_herald.gd")
const DT := 0.05


static func run(t) -> void:
	_adopted(t)
	_warning_toll(t)
	_omen_toll(t)
	_stars_schedule(t)
	_ringers_schedule(t)
	_banners(t)
	_unring(t)
	_first_herald_normal(t)
	_frightened_herald_not_slowed(t)
	_relay_skips_reserved(t)
	_relay_skips_errand(t)
	_bearer_waits_for_herald(t)


## A world for `def` (a mission or an act) with the Lantern its `lantern` names, as Mission builds it: the real objectives, dawn and all.
static func _night(def: MissionDef) -> Dictionary:
	var s := Kit.world(def)
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, def.lantern)
	(s.rules as Rules).lantern = lw
	s["lw"] = lw
	return s


static func _reasons(def: MissionDef) -> Array:
	var out := []
	for o in def.objectives():
		out.append(o.reason)
	return out


## The four nights are Herald nights: the kind, the objectives in order (the main one, HeraldObjective, dawn), no loss by the bell;
## The Long Night's own acts II and III have no Lantern (R31).
static func _adopted(t) -> void:
	var warning := MissionBook.warning()
	var omen := MissionBook.long_night().act("omen")
	var board := TierBook.board("warning")
	var ringers := MissionBook.bell_ringers()
	for pair: Array in [["The Warning", warning, ["warning", "lantern", "dawn"]], ["The Omen", omen, ["warning", "lantern", "dawn"]],
			["the board's Warning", board, ["warning", "lantern", "dawn"]], ["The Bell-Ringers", ringers, ["ringers", "lantern", "dawn"]]]:
		var def: MissionDef = pair[1]
		t.check(def.lantern == LanternWatch.KIND_HERALD, "%s is a Herald night" % pair[0])
		t.check(_reasons(def) == pair[2] and not _reasons(def).has("bell") and def.objectives()[1] is HeraldObjective,
			"%s: the main objective, then HeraldObjective, then dawn; none loses to the bell (%s)" % [pair[0], _reasons(def)])
	t.check(TierBook.board("bell_ringers").lantern == LanternWatch.KIND_HERALD and _reasons(TierBook.board("bell_ringers"))[1] == "lantern",
		"and the board's Bell-Ringers is the same night")
	var night := MissionBook.long_night()
	t.check(night.lantern == "" and night.act("festival").lantern == "" and night.act("procession").lantern == ""
		and night.act("judgement").lantern == "", "The Long Night's later acts meet a rung bell as today, no Lantern (R31)")
	t.check(board.director == StarfallDirector and ringers.director == BellRingersDirector, "the directors are the same ones")


## The Warning with its real objectives: the keeper rings and the night is not lost; the Herald who gets in loses it, reason lantern; killed
## unseen, the night is won, reason warning.
static func _warning_toll(t) -> void:
	var s := _night(MissionBook.warning())
	var r: Rules = s.rules
	var lw: LanternWatch = s.lw
	t.check(H._deliver(s), "(the warning is delivered to the keeper)")
	H._ring(s)
	H._run(s, 0.3)
	t.check(not r.finished and lw.tolled and lw.stage == LanternWatch.Stage.STIRRING and is_equal_approx(r.clock_rate, 1.5)
		and (s.d as WarningDirector).herald_open() and (s.banners as Array).has(LanternWatch.TOLL_BANNER),
		"the toll does not lose The Warning: the Lantern stirs (x1.5) and the keeper is the Herald")
	var took := H._until(s, 45.0, func() -> bool: return r.finished)
	t.check(r.finished and not r.won and r.over_reason == "lantern" and lw.heard and (s.banners as Array).has(LanternWatch.HEARD_BANNER),
		"a Herald who gets in loses it: THE LANTERN HEARS, reason lantern (%.1f s, %s)" % [took, r.over_reason])
	t.check(took >= LanternWatch.HERALD_DESCEND + 8.0 and took <= LanternWatch.HERALD_DESCEND + 28.0,
		"and he has room to be stopped: the descent and a slowed walk (%.1f s)" % took)
	Kit.done(s)

	var u := _night(MissionBook.warning())
	t.check(H._deliver(u), "(delivered again)")
	H._ring(u)
	H._run(u, 0.3)
	var keeper: Person = (u.crowd as Crowd).bell.keeper
	H._clear_round(u, keeper, [])
	(u.crowd as Crowd)._field.kill(keeper, &"doom")
	H._run(u, 0.4)
	t.check((u.rules as Rules).finished and (u.rules as Rules).won and (u.rules as Rules).over_reason == "warning"
		and not (u.lw as LanternWatch).heard, "the Herald killed unseen: the warning dies and the night is won")
	Kit.done(u)


## The Omen is the same night as an act of The Long Night.
static func _omen_toll(t) -> void:
	var s := _night(MissionBook.long_night().act("omen"))
	var r: Rules = s.rules
	t.check(H._deliver(s), "(The Omen: the warning is delivered)")
	H._ring(s)
	H._run(s, 0.3)
	t.check(not r.finished and (s.lw as LanternWatch).tolled and (s.d as WarningDirector).herald_open(),
		"the toll does not lose The Omen either: its keeper is the Herald")
	H._until(s, 45.0, func() -> bool: return r.finished)
	t.check(r.finished and not r.won and r.over_reason == "lantern", "a Herald who gets in loses the act (%s)" % r.over_reason)
	Kit.done(s)


## Starfall's stars keep their time in mission seconds: at x2.0 from the start the first star is set up at half its real time, the next one
## within STOP_WAIT mission seconds of the stop; the stare after a star falls (a reflex) is real.
static func _stars_schedule(t) -> void:
	var s := Kit.world(TierBook.board("warning"))
	var r: Rules = s.rules
	var d: StarfallDirector = s.d
	r.clock_rate = 2.0
	Kit.run_for(s, 3.8)
	t.check(d.stars[0].rules == null and absf(d._clock - 7.6) < 0.2, "x2: at 3.8 s the first star is not yet set up (mission clock %.1f)" % d._clock)
	Kit.run_for(s, 0.4)
	t.check(d.stars[0].rules != null, "x2: its watchman is appointed at 4.2 s, half of the 8 s a normal night waits")
	Kit.run_for(s, 1.6)
	t.check(not d.stars[0].omen_fallen, "the star itself falls OMEN_AT (2 s) after, in real time -- a reflex, not the schedule")
	Kit.run_for(s, 0.6)
	t.check(d.stars[0].omen_fallen, "and it has fallen at 2.2 s after")
	# A stop brings the next star no later than STOP_WAIT mission seconds on: 15 real seconds at x2.
	var stopped_at := d._clock
	d.stars[0].warning_dead = true
	d.stars[0].phase = WarningDirector.Phase.OVER
	Kit.run_for(s, DT * 2.0)
	t.check(is_equal_approx(d.fall_at(1), minf(float(StarfallDirector.STARS[1][0]), d._stopped_at[0] + StarfallDirector.STOP_WAIT))
		and d._stopped_at[0] >= stopped_at and d._stopped_at[0] < stopped_at + 0.5,
		"the stop is noted in mission seconds, and the next star falls STOP_WAIT of them later (%.1f)" % d.fall_at(1))
	Kit.run_for(s, 12.0)
	t.check(d.stars[1].rules == null, "x2: 12 s after the stop the second star is still to come")
	Kit.run_for(s, 3.4)
	t.check(d.stars[1].rules != null, "x2: and 15.4 s after (30 - 2 mission seconds, 14 real) its watchman is up")
	Kit.done(s)

	# At the normal rate nothing changed: 8 s to the first star, one for one.
	var n := Kit.world(TierBook.board("warning"))
	Kit.run_for(n, 7.8)
	t.check((n.d as StarfallDirector).stars[0].rules == null, "x1: not yet at 7.8 s")
	Kit.run_for(n, 0.4)
	t.check((n.d as StarfallDirector).stars[0].rules != null, "x1: set up at 8 s, as in v0.11.1")
	Kit.done(n)


## The Bell-Ringers' posts: the first ringer is sent at 40 mission seconds (20 real at x2), the chain's wait is in mission seconds, and the
## ringer's lamp-lighting (OUT_PAUSE) is real.
static func _ringers_schedule(t) -> void:
	var s := Kit.world(MissionBook.bell_ringers())
	var r: Rules = s.rules
	var d: BellRingersDirector = s.d
	r.clock_rate = 2.0
	Kit.run_for(s, 19.0)
	t.check(d.ringers[0].waiting, "x2: the north-east ringer is still inside at 19 s")
	Kit.run_for(s, 1.5)
	t.check(not d.ringers[0].waiting, "x2: he is sent at 20 s -- 40 mission seconds, half the real time")
	Kit.run_for(s, RingerDirector.OUT_PAUSE - 1.0)
	t.check(d.ringers[0].phase == WarningDirector.Phase.STARE, "he stands OUT_PAUSE real seconds to light his lamp, whatever the rate")
	Kit.run_for(s, 1.6)
	t.check(d.ringers[0].phase == WarningDirector.Phase.RUN, "and runs after it (a reflex: real)")
	var stopped_at := d._clock
	d.ringers[0].warning_dead = true
	d.ringers[0].phase = WarningDirector.Phase.OVER
	Kit.run_for(s, DT * 2.0)
	t.check(d._stopped_at[0] >= stopped_at and is_equal_approx(d.out_at(1), minf(110.0, d._stopped_at[0] + BellRingersDirector.CHAIN_WAIT)),
		"the stop is noted in mission seconds; the chain waits CHAIN_WAIT of them (%.1f)" % d.out_at(1))
	t.check(absf(d._clock - r.mission_time()) < 0.3, "the director's clock is the mission time (%.1f vs %.1f)" % [d._clock, r.mission_time()])
	Kit.done(s)


## The toll and the Herald each have a banner, and both reach the HUD's queue (review-11, C8).
static func _banners(t) -> void:
	var s := _night(MissionBook.warning())
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	t.check(H._deliver(s), "(delivered)")
	H._ring(s)
	H._run(s, 0.3)
	var queued := hud.banners()
	t.check(queued.has(LanternWatch.TOLL_BANNER) and queued.has(LanternWatch.HERALD_BANNER)
		and queued.find(LanternWatch.TOLL_BANNER) < queued.find(LanternWatch.HERALD_BANNER),
		"the HUD queues the toll's banner and then the Herald's (%s)" % [queued])
	t.check((s.banners as Array).count(LanternWatch.TOLL_BANNER) == 1 and (s.banners as Array).count(LanternWatch.HERALD_BANNER) == 1,
		"one of each")
	hud.free()
	Kit.done(s)


## The Bell Lies unrings the bell after the toll: the Lantern stays latched (no second toll), and the keeper who is the Herald is not pulled back
## to the rope -- he runs on and, unstopped, gets in.
static func _unring(t) -> void:
	var s := _night(MissionBook.warning())
	var r: Rules = s.rules
	var lw: LanternWatch = s.lw
	var d: WarningDirector = s.d
	var crowd: Crowd = s.crowd
	var bell := crowd.bell
	t.check(H._deliver(s), "(delivered)")
	var keeper := bell.keeper
	H._ring(s)
	H._run(s, 0.3)
	var tolled_at := lw.tolled_at
	crowd.unring_bell()
	bell._retry_in = 0.0  # the keeper would try again at once, if he were free
	t.check(bell.state == BellNetwork.State.WAITING, "(the bell is unrung: the keeper is to try again)")
	var pulled := 0
	var steps := 0
	while not r.finished and steps < 700:
		H._run(s, DT)
		steps += 1
		if bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
			pulled += 1
	t.check(pulled == 0, "the keeper-Herald is never sent back to the rope (%d frames of CALLED or CLIMBING)" % pulled)
	t.check(lw.tolled and is_equal_approx(lw.tolled_at, tolled_at) and (s.banners as Array).count(LanternWatch.TOLL_BANNER) == 1
		and lw.stage == LanternWatch.Stage.STIRRING, "the Lantern stays latched: one toll, one banner, still Stirring")
	t.check(r.finished and r.over_reason == "lantern" and lw.heard, "the Herald ran on and got in: the night is lost to the Lantern (%s)" % r.over_reason)
	Kit.done(s)

	# Killed unseen after the unring, the night is still won.
	var u := _night(MissionBook.warning())
	t.check(H._deliver(u), "(delivered)")
	var k2: Person = (u.crowd as Crowd).bell.keeper
	H._ring(u)
	H._run(u, 0.3)
	(u.crowd as Crowd).unring_bell()
	((u.crowd as Crowd).bell as BellNetwork)._retry_in = 0.0
	H._run(u, 6.0)
	H._clear_round(u, k2, [])
	(u.crowd as Crowd)._field.kill(k2, &"doom")
	H._run(u, 0.4)
	t.check((u.rules as Rules).finished and (u.rules as Rules).won and (u.rules as Rules).over_reason == "warning",
		"stopped unseen after an unring, the warning is dead and the night won")
	Kit.done(u)


## review-11 Minor 1: the first Herald, sent after his descent, is sent in the normal form -- a fright he came down the tower in is respected.
static func _first_herald_normal(t) -> void:
	var s := H._world("ringers")
	var lw: LanternWatch = s.lw
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	H._ring(s)
	H._run(s, 0.1)
	t.check(lw.heralds.size() == 1 and lw.heralds[0].descend_left() > 4.0, "(the keeper-Herald comes down the tower)")
	keeper.panic(keeper.ground_pos + Vector2(1.0, 0.0), 3.0)
	t.check(keeper.mind == Person.Mind.PANIC, "(and is frightened on the way down)")
	H._until(s, 8.0, func() -> bool: return lw.heralds[0].descend_left() <= 0.0)
	H._run(s, 0.1)
	t.check(keeper.mind == Person.Mind.PANIC, "the descent over, he is not forced back onto the road: his fright runs its course (%s)" % Person.Mind.keys()[keeper.mind])
	Kit.done(s)


## review-11 Minor 2: a Herald who is frightened is not slowed -- he flees at his own pace; the Herald's pace is written when he is sent again.
static func _frightened_herald_not_slowed(t) -> void:
	var s := H._tolled(0.1)
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	H._run(s, LanternWatch.HERALD_DESCEND + 1.0)
	t.check(keeper.mind == Person.Mind.DUTY and is_equal_approx(float(keeper.statuses.get(&"slow", 1.0)), LanternWatch.HERALD_SLOW),
		"(walking, the Herald keeps HERALD_SLOW of his pace)")
	keeper.panic(keeper.ground_pos + Vector2(1.0, 0.0), 3.0)
	H._run(s, 0.6)
	t.check(keeper.mind == Person.Mind.PANIC and not keeper.statuses.has(&"slow"),
		"frightened, he runs at his own pace (no slow while he panics)")
	var rep := H._world("ringers")
	var k2: Person = (rep.crowd as Crowd).bell.keeper
	H._ring(rep)
	H._run(rep, LanternWatch.HERALD_DESCEND + 1.0)
	k2.panic(k2.ground_pos + Vector2(1.0, 0.0), 3.0)
	H._run(rep, 0.6)
	t.check(k2.mind == Person.Mind.PANIC and not k2.statuses.has(&"slow"), "the same for the town keeper's report")
	Kit.done(rep)
	Kit.done(s)


## review-11 Minor 3: the town keeper's relay never picks a wisher or a wish's target.
static func _relay_skips_reserved(t) -> void:
	var s := H._world("ringers")
	var lw: LanternWatch = s.lw
	var d: BellRingersDirector = s.d
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	H._ring(s)
	H._run(s, 6.0)
	var witness: Person = null
	for p in (s.crowd as Crowd).citizens:
		if is_instance_valid(p) and p != keeper and p.is_alive():
			witness = p
			break
	Kit.arrive(witness, keeper.ground_pos + Vector2(1.0, 0.0))
	witness.inside = false
	d.reserved.append(witness)
	H._clear_round(s, keeper, [witness])
	(s.crowd as Crowd)._field.kill(keeper, &"fire")
	H._run(s, 0.4)
	t.check(lw.heralds[0].dead and lw.heralds[0].relays == 0, "a reserved witness does not carry the keeper-Herald on: the report ends")
	Kit.done(s)


## Ruling C15: no relay hands its errand to someone on the Lantern's errand. A Herald killed in sight of only the Bearer's file is stopped
## (the report ends, the warning dies) and the Bearer keeps walking; with a plain witness by, the plain one carries on.
static func _relay_skips_errand(t) -> void:
	for variant: String in ["ringers", "warning"]:
		for plain in [false, true]:
			var s: Dictionary
			var victim: Person
			if variant == "ringers":
				s = H._world("ringers")
				victim = (s.crowd as Crowd).bell.keeper
				H._ring(s)
				H._run(s, LanternWatch.HERALD_DESCEND + 1.0)
			else:
				s = H._tolled(0.1)
				victim = (s.crowd as Crowd).bell.keeper
				H._run(s, LanternWatch.HERALD_DESCEND + 1.0)
			var lw: LanternWatch = s.lw
			var crowd: Crowd = s.crowd
			Kit.arrive(victim, crowd.bell.foot.lerp(H._door(s), 0.5))  # (well off the tower's foot, so the Bearer's walk is no vigil)
			var b := LanternBearer.new().setup(s.rules, crowd, H._door(s), crowd.bell.foot, [])
			lw.bearer = b
			var file: Array = b.walkers()
			var keep: Array = file.duplicate()
			var other: Person = null
			if plain:
				for p in crowd.citizens:
					if is_instance_valid(p) and p != victim and p.is_alive() and not file.has(p) and p.mind != Person.Mind.DUTY:
						other = p
						break
				keep.append(other)
			H._clear_round(s, victim, keep)
			for i in file.size():
				Kit.arrive(file[i], victim.ground_pos + Vector2(0.4 + 0.3 * float(i), 0.3))
			if other != null:
				Kit.arrive(other, victim.ground_pos + Vector2(-1.5, 0.0))
				other.inside = false
			var label := "%s, %s" % [variant, "a plain witness by" if plain else "only the Bearer's file by"]
			t.check(b.state == LanternBearer.State.WALKING and file.size() == 3 and (s.d as MissionDirector).on_lantern_errand(file[1]),
				"(%s: the file is out and on the Lantern's errand)" % label)
			if variant == "warning":
				var seen: Array = (s.d as WarningDirector).witnesses()
				t.check((seen.has(other) or not plain) and not seen.has(file[0]) and not seen.has(file[1]) and not seen.has(file[2]),
					"(%s: the red diamonds leave the Bearer's file out)" % label)
			(s.crowd as Crowd)._field.kill(victim, &"fire")
			H._run(s, 0.4)
			var stopped: bool
			if variant == "ringers":
				stopped = lw.heralds[0].dead and lw.heralds[0].relays == 0
				if plain:
					stopped = lw.heralds[0].is_open() and lw.heralds[0].carrier == other
			else:
				var d: WarningDirector = s.d
				stopped = d.warning_dead
				if plain:
					stopped = not d.warning_dead and d.messenger == other
			t.check(stopped, "%s: %s" % [label, "the plain witness carries it on" if plain else "the Herald is stopped, the Bearer is not taken"])
			t.check(b.state == LanternBearer.State.WALKING and not file.has(other), "(%s: the Bearer keeps walking)" % label)
			Kit.done(s)


## Ruling C16: on a Herald night the Bearer does not set out while any Herald runs; he sets out LanternBearer.AFTER mission seconds after the
## last one is gone. The strip and the hint say he waits.
static func _bearer_waits_for_herald(t) -> void:
	var s := H._world("ringers")
	var lw: LanternWatch = s.lw
	var r: Rules = s.rules
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	H._ring(s)
	H._run(s, LanternWatch.HERALD_DESCEND + 2.0)
	var rows := lw.strip_rows()
	var labels := []
	for row: Dictionary in rows:
		labels.append(String(row["label"]))
	t.check(lw.heralds.size() == 1 and lw.herald_running() and r.mission_time() - lw.tolled_at > LanternBearer.AFTER * 0.5,
		"(the Herald runs, the toll well past)")
	H._run(s, 12.0)
	t.check(lw.herald_running() and lw.bearer == null and lw.hint_phase() == "herald",
		"the Herald still runs well after AFTER mission seconds: the Bearer has not set out (%.1f s since the toll)" % [r.mission_time() - lw.tolled_at])
	labels.clear()
	for row: Dictionary in lw.strip_rows():
		labels.append(String(row["label"]))
	t.check(labels.has("The Bearer waits for the Herald") and labels.has(LanternWatch.STRIP_HERALD) and not labels.has("The Lantern-Bearer sets out"),
		"the strip says the Bearer waits for the Herald, with no countdown of his own (%s)" % [labels])
	var waits: Dictionary = {}
	for row: Dictionary in lw.strip_rows():
		if String(row["label"]) == "The Bearer waits for the Herald":
			waits = row
	t.check(String(waits.get("clock", "")) == LanternWatch.NO_CLOCK, "(a countdown-free row)")
	# The Herald is stopped unseen: the Bearer sets out AFTER mission seconds later, not before.
	H._clear_round(s, keeper, [])
	(s.crowd as Crowd)._field.kill(keeper, &"doom")
	H._run(s, 0.4)
	t.check(lw.heralds[0].dead and not lw.herald_running(), "(the Herald is stopped)")
	var stopped_at := r.mission_time()
	H._until(s, 3.0, func() -> bool: return lw.bearer != null)
	t.check(lw.bearer == null, "he does not set out the moment the Herald falls")
	var took := H._until(s, 30.0, func() -> bool: return lw.bearer != null)
	var after := r.mission_time() - stopped_at
	t.check(lw.bearer != null and after >= LanternBearer.AFTER - 0.5 and after <= LanternBearer.AFTER + 1.5,
		"he sets out AFTER (%.0f) mission seconds from the moment no Herald runs (%.1f s, %.1f real)" % [LanternBearer.AFTER, after, took])
	Kit.done(s)

