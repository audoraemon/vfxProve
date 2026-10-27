extends RefCounted
## v0.11 M2 The Tax Collector (spec §1 as the controller's Task 2 ruling reshapes it, AssassinateDirector): three collectors --
## the tax collector and his two deputies, residents made nobles -- count in the counting-house (the workshop hall) with
## their guards at its door. Each sets out on his own round of debtors' houses (3, 2 and 3 of them), 20 s indoors at each, then makes for the
## Citadel's gate, which loses the night: the collector at 0:35, each deputy at his own time or CHAIN_WAIT after the one
## before him dies, whichever is sooner (smoked out sooner still by a power cast at the door while none is out). A loud power
## near one, a guard felled or a fright sends him to hide 30 s; a house he is in set alight or brought down flushes him out
## (review focus 4) -- a collector out or hiding and, since v0.11.1, one still waiting too: everyone inside the burning or fallen
## counting-house runs for the Citadel, one banner, none sent from it again. All three
## dead wins; one escaping the town counts as safe; a seen kill makes the guards cry murder and calls the bellkeeper. Reserved
## people and places are never taken (review focus 1); freed bodies and the town's rally are borne (review focus 2, 3); with no
## hideout the targets still are three different people (fix round).

const DT := 0.05


## A bare AssassinateDirector with no hideout (v0.11 M2 fix round): three targets with no stops, the Citadel's gate their safe
## place. They wait out of doors, still eligible, so only AssassinateDirector._appointed() keeps them apart.
class NoHideout:
	extends AssassinateDirector

	func _plan() -> void:
		safe_at = TaxCollectorDirector.CITADEL_GATE
		for i in 3:
			var stops: Array[Structure] = []
			_add_quarry("TARGET", 45.0 + 60.0 * float(i), stops, 1)


static func run(t) -> void:
	_setup(t)
	_rounds(t)
	_chain(t)
	_won(t)
	_smoked(t)
	_alarm(t)
	_flushed(t)
	_flush_awkward(t)
	_ember_cast(t)
	_flush_apart(t)
	_running(t)
	_lost(t)
	_kill(t)
	_freed(t)
	_rallied(t)
	_reserved(t)
	_plain(t)
	_mission(t)
	_lantern(t)
	_out_stops(t)
	_out_not_safe(t)
	_out_killed_after(t)
	_mob(t)
	_mob_guarded(t)
	_mob_far(t)
	_mob_centre(t)
	_mob_unvisited(t)


static func _world(loadout := PackedStringArray(), reserve := false, plain := false, keep_gap := false) -> Dictionary:
	var def := MissionBook.tax_collector()
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(loadout if not loadout.is_empty() else def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var director: AssassinateDirector = NoHideout.new() if plain else def.make_director() as AssassinateDirector
	var held := {}
	if reserve:
		held = _hold_back(director, crowd, town)
	director.setup(rules, crowd, town, null)
	if director is TaxCollectorDirector and not keep_gap:
		director.flush_gap = 0.0  # the mechanics tests read a flush at once; _flush_apart() keeps the knob (v0.11.1 Task 8)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners, "held": held}


## Sets aside, before the director is set up (as Descent does): the resident who would be the tax collector, the soldier
## nearest the counting-house, and the collector's first debtor's house. Returns them.
static func _hold_back(d: AssassinateDirector, crowd: Crowd, town: Town) -> Dictionary:
	var shop: Structure = null
	for s: Structure in town._built:
		if s.art_tag == TaxCollectorDirector.COUNTING_TAG:
			shop = s
	var door := shop.center() + Vector2(0.0, shop.footprint.size.y * 0.5 + 0.5)
	var resident: Person = null
	for p in crowd.citizens:
		if not p.inside and p.profile.role == CitizenProfile.Role.RESIDENT \
				and (resident == null or p.ground_pos.distance_to(door) < resident.ground_pos.distance_to(door)):
			resident = p
	var soldier: Person = null
	for p in crowd.soldiers:
		if not p.inside and p.corps == Person.Corps.NONE \
				and (soldier == null or p.ground_pos.distance_to(door) < soldier.ground_pos.distance_to(door)):
			soldier = p
	var house: Structure = null
	for s: Structure in town._built:
		if RuinWish.fits(s, "house") and s != shop and (house == null
				or s.center().distance_to(TaxCollectorDirector.ROUNDS[0][0]) < house.center().distance_to(TaxCollectorDirector.ROUNDS[0][0])):
			house = s
	d.reserved.assign([resident, soldier])
	d.reserved_places.assign([house])
	return {"resident": resident, "soldier": soldier, "house": house}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## The labelled tags' labels, in order.
static func _labels(d: MissionDirector) -> Array:
	var out := []
	for m in d.tags():
		if m.label != "":
			out.append(m.label)
	return out


## Everyone but `who` within 3 units of them moved well away, so a death there has no witness.
static func _clear_round(crowd: Crowd, who: Person) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != who and p.ground_pos.distance_to(who.ground_pos) <= 3.0:
				p.ground_pos = who.ground_pos + Vector2(12.0, 0.0)


## Quarry `i` set out and killed where nobody sees it, then the crowd and the rules stepped once.
static func _kill_unseen(s: Dictionary, i: int) -> void:
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[i]
	if q.state == AssassinateDirector.State.WAITING:
		d._set_out(q)
	elif q.target.inside:
		# Indoors at a debtor's: brought out to his door first (out of the field, nothing can touch him).
		d._come_out(q)
		q.state = AssassinateDirector.State.WALKING
	_clear_round(s.crowd, q.target)
	(s.crowd as Crowd)._field.kill(q.target, &"doom")
	_run(s, DT)


static func _setup(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	t.check(d.quarries.size() == 3, "three collectors: the tax collector and his two deputies")
	var all_ok := true
	var guards_ok := true
	var seen_guards: Array = []
	for q in d.quarries:
		all_ok = all_ok and q.target != null and q.target.profile.role == CitizenProfile.Role.NOBLE and q.target.inside \
			and q.state == AssassinateDirector.State.WAITING
		guards_ok = guards_ok and q.guards.size() == TaxCollectorDirector.GUARDS[q.index]
		for g in q.guards:
			guards_ok = guards_ok and g.soldier and g.corps == Person.Corps.NONE and not seen_guards.has(g) \
				and g.anchor.distance_to(d.hide_door) <= AssassinateDirector.DOOR_GUARD_R + 0.6
			seen_guards.append(g)
	t.check(all_ok and d.quarries[0].target != d.quarries[1].target and d.quarries[1].target != d.quarries[2].target,
		"each a different resident made a noble, counting indoors")
	t.check(d.hideout != null and d.hideout.art_tag == TaxCollectorDirector.COUNTING_TAG, "the counting-house is the workshop hall")
	t.check(guards_ok, "their guards (2, 1, 1), all different, posted by its door")
	var houses: Array = []
	var stops_ok := true
	for q in d.quarries:
		stops_ok = stops_ok and q.stops.size() == (TaxCollectorDirector.ROUNDS[q.index] as Array).size() \
			and q.stop_doors.size() == q.stops.size()
		for h in q.stops:
			stops_ok = stops_ok and RuinWish.fits(h, "house") and h != d.hideout and not houses.has(h)
			houses.append(h)
	t.check(stops_ok and d.quarries[0].stops.size() == 3 and d.quarries[1].stops.size() == 2 and d.quarries[2].stops.size() == 3,
		"each collector's round of debtors (3, 2, 3), all different houses")
	var paths_ok := true
	for q in d.quarries:
		for door in q.stop_doors:
			paths_ok = paths_ok and not (s.crowd as Crowd)._grid.path(d.hide_door, door).is_empty()
	t.check(paths_ok, "every debtor's door has a way to it from the counting-house's (a walled-in yard is passed over)")
	t.check(d.safe_at.distance_to(TaxCollectorDirector.CITADEL_GATE) <= 1.5, "their safe place is the Citadel's gate")
	var up := d.timeline.upcoming(3)
	t.check(up.size() == 3 and String(up[0].id) == "out_0" and is_equal_approx(float(up[0].at), TaxCollectorDirector.SET_OUT_AT[0])
		and String(up[1].id) == "out_1" and is_equal_approx(float(up[1].at), TaxCollectorDirector.SET_OUT_AT[1])
		and String(up[2].id) == "out_2", "the strip: the collector out at 0:35, his deputies at their times")
	t.check(_labels(d) == ["TAX COLLECTOR - INSIDE", "COUNTING-HOUSE", "DEBTOR"] and d.hint_phase() == "inside",
		"tagged indoors, with the counting-house and his first debtor (%s); the hint: he is indoors" % [_labels(d)])
	var stops := d.tour()
	t.check(stops.size() == 3
		and String(stops[0][1]) == "The counting-house. The tax collector sets out at 0:35, his deputies by 1:35 and 2:35."
		and String(stops[1][1]) == "His first debtor. He goes in to collect, then walks on."
		and String(stops[2][1]) == "The Citadel. A collector whose rounds are done takes the taxes in.",
		"the tour: the counting-house, his first debtor, the Citadel (%s)" % [stops])
	t.check((s.banners as Array).has("THE TAX COLLECTORS MAKE THEIR ROUNDS"), "its opening banner")
	_done(s)


static func _rounds(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var rules: Rules = s.rules
	var q := d.quarries[0]
	_run(s, TaxCollectorDirector.SET_OUT_AT[0] + DT * 2.0)
	t.check(q.state == AssassinateDirector.State.WALKING and not q.target.inside and q.target.mind == Person.Mind.DUTY
		and q.target.goal().distance_to(q.stop_doors[0]) < 0.5 and (s.banners as Array).has("THE TAX COLLECTOR SETS OUT")
		and d.quarries[1].state == AssassinateDirector.State.WAITING, "0:35: he sets out for his first debtor; his deputies wait")
	t.check(_labels(d).has("TAX COLLECTOR") and _labels(d).has("NEXT COLLECTOR") and d.hint_phase() == ""
		and rules.objectives[0].hud_text(rules) == "Stop the collectors: 0 / 3",
		"in the street he is tagged, the next collector is pointed out, the hint is the mission's, the HUD counts (%s; %s)"
		% [_labels(d), rules.objectives[0].hud_text(rules)])
	for i in 3:
		_arrive(q.target, q.stop_doors[i])
		_run(s, AssassinateDirector.TICK + DT)
		t.check(q.state == AssassinateDirector.State.VISITING and q.target.inside and q.leg == i,
			"debtor %d: he goes in to collect" % (i + 1))
		_run(s, TaxCollectorDirector.VISIT_SECONDS + DT)
		t.check(q.state == AssassinateDirector.State.WALKING and q.leg == i + 1 and not q.target.inside, "and walks on")
	t.check(d.current() == q and d.hint_phase() == "safe" and _labels(d).has("CITADEL") and q.target.goal().distance_to(d.safe_at) < 0.5
		and rules.objectives[0].hud_text(rules) == "Stop the collectors: 0 / 3, rounds done",
		"the collector's rounds done, he makes for the Citadel")
	# Alarmed, he hides while the first deputy's own time comes.
	d._alarm(q)
	_arrive(q.target, d.hide_door)
	_run(s, AssassinateDirector.TICK + DT)
	_run(s, TaxCollectorDirector.SET_OUT_AT[1] - d._clock + DT * 2.0)
	t.check(q.state == AssassinateDirector.State.HIDING and d.quarries[1].state != AssassinateDirector.State.WAITING
		and (s.banners as Array).has("A DEPUTY SETS OUT"), "1:35 with the collector still alive: the first deputy sets out on his own time")
	_run(s, TaxCollectorDirector.HIDE_SECONDS)
	t.check(q.state == AssassinateDirector.State.WALKING and q.target.goal().distance_to(d.safe_at) < 0.5,
		"out of hiding, the collector makes for the Citadel again")
	_arrive(q.target, d.safe_at)
	_run(s, AssassinateDirector.TICK + DT)
	t.check(d.any_safe() and rules.finished and not rules.won and rules.over_reason == "taxes"
		and (s.banners as Array).has("THE TAXES ARE IN"), "at the Citadel's gate: the taxes are in, and the night is lost")
	t.check(String(d.report().target) == "escaped" and q.state == AssassinateDirector.State.SAFE,
		"the results say one got away")
	_done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var wait := TaxCollectorDirector.CHAIN_WAIT
	t.check(is_equal_approx(d.out_at(1), TaxCollectorDirector.SET_OUT_AT[1]) and is_equal_approx(d.out_at(2), TaxCollectorDirector.SET_OUT_AT[2]),
		"with no one dead, each deputy keeps his own time")
	_run(s, TaxCollectorDirector.SET_OUT_AT[0] + 5.0)
	_kill_unseen(s, 0)
	var died := d.quarries[0].died_at
	t.check(d.quarries[0].dead and is_equal_approx(d.out_at(1), minf(TaxCollectorDirector.SET_OUT_AT[1], died + wait))
		and died + wait < TaxCollectorDirector.SET_OUT_AT[1], "the collector dead: the first deputy is due sooner (%.1f)" % d.out_at(1))
	t.check(d.hint_phase() == "next" and _labels(d).has("DEPUTY - INSIDE") and d.current() == d.quarries[1],
		"between collectors: the hint says the next comes, and he is tagged indoors (%s)" % [_labels(d)])
	_run(s, wait - 1.0)
	t.check(d.quarries[1].state == AssassinateDirector.State.WAITING, "but not before the chain's wait is up")
	_run(s, 1.5)
	t.check(d.quarries[1].state == AssassinateDirector.State.WALKING and (s.banners as Array).has("A DEPUTY SETS OUT")
		and d._clock < TaxCollectorDirector.SET_OUT_AT[1], "%d s after: he sets out, before his own time" % roundi(wait))
	t.check(d.quarries[2].state == AssassinateDirector.State.WAITING and is_equal_approx(d.out_at(2), TaxCollectorDirector.SET_OUT_AT[2]),
		"the last deputy keeps his time while the one before him lives")
	_kill_unseen(s, 1)
	var died2 := d._clock
	_run(s, wait + 0.5)
	t.check(d.quarries[2].state == AssassinateDirector.State.WALKING and d._clock < TaxCollectorDirector.SET_OUT_AT[2]
		and d._clock - died2 <= wait + 1.0, "and the last deputy follows the same way")
	var up := d.timeline.upcoming(3)
	t.check(up.is_empty(), "the strip lists no set-out already come (%s)" % [up])
	_done(s)


static func _won(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var rules: Rules = s.rules
	_kill_unseen(s, 0)
	t.check(not rules.finished and rules.objectives[0].hud_text(rules) == "Stop the collectors: 1 / 3" and d.killed() == 1,
		"one dead is not the night (%s)" % rules.objectives[0].hud_text(rules))
	_kill_unseen(s, 1)
	t.check(not rules.finished and d.killed() == 2, "nor two")
	_kill_unseen(s, 2)
	_run(s, 0.5)
	t.check(d.all_fallen() and rules.finished and rules.won and rules.over_reason == "collector"
		and rules.objectives[0].hud_text(rules) == "Stop the collectors", "all three dead: the night is won")
	var r := d.report()
	t.check(String(r.target) == "unseen" and int(r.killed) == 3 and int(r.seen) == 0 and d.tags().is_empty() and d.hint_phase() == "",
		"the results say all three died unseen (%s); nothing is tagged" % [r])
	_done(s)


static func _smoked(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	_run(s, 10.0)
	d._on_cast(0, "whisper", d.hide_door + Vector2(TaxCollectorDirector.ALARM_REACH - 0.5, 0.0))
	t.check(d.quarries[0].state == AssassinateDirector.State.WALKING and not d.quarries[0].target.inside
		and d.quarries[1].state == AssassinateDirector.State.WAITING,
		"a power cast by the counting-house's door smokes the collector out early, and only him")
	d._on_cast(0, "whisper", d.hide_door)
	t.check(d.quarries[1].state == AssassinateDirector.State.WAITING, "with one out, a cast at the door smokes no deputy out")
	_run(s, TaxCollectorDirector.SET_OUT_AT[0])
	var sets := 0
	for b: String in s.banners:
		sets += 1 if b == "THE TAX COLLECTOR SETS OUT" else 0
	t.check(sets == 1, "and 0:35 does not send him out a second time")
	_kill_unseen(s, 0)
	d._on_cast(0, "whisper", d.hide_door)
	t.check(d.quarries[1].state == AssassinateDirector.State.WALKING and d.quarries[2].state == AssassinateDirector.State.WAITING,
		"with him dead and none out, a cast at the door smokes the next deputy out")
	_done(s)


static func _alarm(t) -> void:
	var s := _world(PackedStringArray(["smite", "doom", "discord"]))
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	d._set_out(q)
	_run(s, DT)
	d._on_cast(1, "doom", q.target.ground_pos + Vector2(1.5, 0.0))
	t.check(q.state == AssassinateDirector.State.WALKING and q.alarms == 0, "a quiet power near him does not alarm him")
	var crowd: Crowd = s.crowd
	crowd.on_cast(q.target.ground_pos + Vector2(TaxCollectorDirector.ALARM_REACH + 2.0, 0.0), Vector2.ZERO, 0.0, "smite")
	_run(s, PowerBook.IMPACT.smite + 0.1)
	t.check(q.alarms == 0, "nor a loud one beyond its reach")
	crowd.on_cast(q.target.ground_pos + Vector2(1.5, 0.0), Vector2.ZERO, 0.0, "smite")
	_run(s, DT)
	t.check(q.alarms == 0, "v0.11.2: a loud one near him does not alarm him at the cast")
	_run(s, PowerBook.IMPACT.smite + 0.1)
	t.check(q.state == AssassinateDirector.State.FLEEING and q.alarms == 1 and (s.banners as Array).has("THE TAX COLLECTOR HIDES")
		and q.target.goal().distance_to(d.hide_door) < 0.5 and d.hint_phase() == "hiding"
		and (s.rules as Rules).objectives[0].hud_text(s.rules) == "Stop the collectors: 0 / 3, he hides",
		"a loud one near him: he makes for the counting-house")
	_arrive(q.target, d.hide_door)
	_run(s, AssassinateDirector.TICK + DT)
	t.check(q.state == AssassinateDirector.State.HIDING and q.target.inside, "and hides there")
	_run(s, TaxCollectorDirector.HIDE_SECONDS + DT)
	t.check(q.state == AssassinateDirector.State.WALKING and q.leg == 0 and q.target.goal().distance_to(q.stop_doors[0]) < 0.5,
		"30 s later he takes his rounds up again")
	_done(s)

	var g := _world()
	var dg: TaxCollectorDirector = g.d
	var qg := dg.quarries[0]
	dg._set_out(qg)
	(g.crowd as Crowd)._field.kill(qg.guards[0], &"fire")
	_run(g, AssassinateDirector.TICK + DT)
	t.check(qg.state == AssassinateDirector.State.FLEEING and qg.alarms == 1, "a guard felled alarms him")
	_done(g)

	var b := _world()
	var db: TaxCollectorDirector = b.d
	var qb := db.quarries[0]
	db._set_out(qb)
	(b.crowd as Crowd)._field.kill(qb.guards[0], &"doom")
	(b.crowd as Crowd)._field.kill(qb.target, &"doom")
	_run(b, AssassinateDirector.TICK + DT)
	var hid := false
	for x: String in b.banners:
		hid = hid or x == "THE TAX COLLECTOR HIDES"
	t.check(qb.dead and qb.alarms == 0 and not hid, "a guard falling with him in one cast raises no alarm")
	_done(b)

	var f := _world()
	var df: TaxCollectorDirector = f.d
	var qf := df.quarries[0]
	df._set_out(qf)
	qf.target.mind = Person.Mind.PANIC
	_run(f, AssassinateDirector.TICK + DT)
	t.check(qf.state == AssassinateDirector.State.FLEEING, "so does a fright")
	_done(f)


## The banners raised so far (v0.11.1).
static func _banners(s: Dictionary) -> Array:
	return s.banners


## Every collector but those in `except` is out of the counting-house, alive, frightened and bound for the Citadel (v0.11.1).
static func _all_run(d: TaxCollectorDirector, except := []) -> bool:
	var ok := true
	for q in d.quarries:
		if except.has(q):
			continue
		ok = ok and not q.target.inside and q.state == AssassinateDirector.State.FLEEING and q.target.is_alive() \
			and q.target.goal().distance_to(d.safe_at) < 0.5 and q.flushed
	return ok


static func _flushed(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	_banners(s).clear()
	(s.crowd as Crowd).fires.ignite(d.hideout, 0.6)
	_run(s, AssassinateDirector.TICK * 2.0 + DT)
	t.check(_all_run(d), "the counting-house alight: every collector, waiting ones too, runs for the Citadel")
	t.check(_banners(s) == [TaxCollectorDirector.FLUSH_BANNER], "one banner, no 'hides' (%s)" % [_banners(s)])
	t.check(d._next_waiting() == null and d.timeline.upcoming(3).is_empty(), "none is left waiting, and the strip's set-out rows are gone")
	_run(s, TaxCollectorDirector.SET_OUT_AT[2] + 1.0)
	var never := true
	for q in d.quarries:
		never = never and q.state != AssassinateDirector.State.WAITING and not q.target.inside
	t.check(never and not d.timeline.fired_ids().has("out_0") and not (_labels(d)).has("NEXT COLLECTOR"),
		"none is ever sent from it again: no set-out fires, no NEXT COLLECTOR tag")
	_done(s)

	# The same with the counting-house brought down instead of burning.
	var f := _world()
	var df: TaxCollectorDirector = f.d
	_banners(f).clear()
	df.hideout.destroy(df.hideout.center(), &"fire")
	_run(f, AssassinateDirector.TICK * 2.0 + DT)
	t.check(_all_run(df) and _banners(f) == [TaxCollectorDirector.FLUSH_BANNER], "the counting-house fallen: the same, one banner")
	_done(f)

	var h := _world()
	var dh: TaxCollectorDirector = h.d
	var qh := dh.quarries[0]
	dh._set_out(qh)
	dh._alarm(qh)
	_arrive(qh.target, dh.hide_door)
	_run(h, AssassinateDirector.TICK + DT)
	var hid := qh.state == AssassinateDirector.State.HIDING and qh.target.inside
	(h.crowd as Crowd).fires.ignite(dh.hideout, 0.6)
	_run(h, DT * 2.0)
	t.check(hid and not qh.target.inside and qh.state != AssassinateDirector.State.HIDING and qh.target.is_alive()
		and dh.quarries[1].state != AssassinateDirector.State.WAITING and not dh.quarries[1].target.inside,
		"hiding there, the collector is flushed out alive (review focus 4); his deputies burst out with him")
	_run(h, AssassinateDirector.TICK + DT)
	t.check(qh.state == AssassinateDirector.State.FLEEING and qh.target.goal().distance_to(dh.safe_at) < 0.5,
		"frightened, with no counting-house to hide in, he runs for the Citadel")
	# The final review's probe: shown as running for the Citadel, not as hiding, wherever he is on the way.
	_arrive(qh.target, dh.safe_at + Vector2(3.0, 0.0))
	_run(h, AssassinateDirector.TICK + DT)
	t.check(_running_shown(dh, h.rules), "and he is shown so: the hint, the HUD and the Citadel tag, not a debtor's (%s; %s; %s)"
		% [dh.hint_phase(), (h.rules as Rules).objectives[0].hud_text(h.rules), _labels(dh)])
	_arrive(qh.target, dh.safe_at)
	_run(h, AssassinateDirector.TICK + DT)
	t.check(dh.any_safe() and (h.rules as Rules).finished and not (h.rules as Rules).won and (h.rules as Rules).over_reason == "taxes",
		"and getting in loses the night")
	_done(h)

	var v := _world()
	var dv: TaxCollectorDirector = v.d
	var qv := dv.quarries[0]
	dv._set_out(qv)
	_arrive(qv.target, qv.stop_doors[0])
	_run(v, AssassinateDirector.TICK + DT)
	qv.stops[0].destroy(qv.stops[0].center(), &"fire")
	_run(v, DT * 2.0)
	t.check(not qv.target.inside and qv.leg == 1 and qv.target.is_alive(),
		"a debtor's house brought down flushes him out alive, and that debtor is done")
	_done(v)


## The counting-house burns at an awkward moment (v0.11.1, review focus 4): one banner, each collector resolves once, none is left
## waiting, and the strip's rows are gone.
static func _flush_awkward(t) -> void:
	# While the collector visits a debtor: he keeps his round, only the two inside run.
	var v := _world()
	var dv: TaxCollectorDirector = v.d
	var q0 := dv.quarries[0]
	dv._set_out(q0)
	_arrive(q0.target, q0.stop_doors[0])
	_run(v, AssassinateDirector.TICK + DT)
	var visiting := q0.state == AssassinateDirector.State.VISITING and q0.target.inside
	_banners(v).clear()
	(v.crowd as Crowd).fires.ignite(dv.hideout, 0.6)
	_run(v, AssassinateDirector.TICK * 2.0 + DT)
	t.check(visiting and q0.state == AssassinateDirector.State.VISITING and q0.target.inside and not q0.flushed
		and _all_run(dv, [q0]) and _banners(v) == [TaxCollectorDirector.FLUSH_BANNER] and dv._next_waiting() == null,
		"burning while the collector visits a debtor: he keeps his visit, the two inside run, one banner")
	_done(v)

	# While the collector flees to hide: the counting-house is no hiding place now, he runs for the Citadel.
	var r := _world()
	var dr: TaxCollectorDirector = r.d
	var qr := dr.quarries[0]
	dr._set_out(qr)
	dr._alarm(qr)
	_banners(r).clear()
	(r.crowd as Crowd).fires.ignite(dr.hideout, 0.6)
	_run(r, AssassinateDirector.TICK * 2.0 + DT)
	t.check(qr.state == AssassinateDirector.State.FLEEING and qr.target.goal().distance_to(dr.safe_at) < 0.5
		and _all_run(dr, [qr]) and _banners(r) == [TaxCollectorDirector.FLUSH_BANNER],
		"burning while he flees to hide: he runs for the Citadel too, the two inside burst out, one banner")
	_done(r)

	# After one is safe: the night is lost and stays lost; the others still run.
	var a := _world()
	var da: TaxCollectorDirector = a.d
	da._set_out(da.quarries[0])
	da._reach_safe(da.quarries[0])
	_banners(a).clear()
	(a.crowd as Crowd).fires.ignite(da.hideout, 0.6)
	_run(a, AssassinateDirector.TICK * 2.0 + DT)
	t.check(da.any_safe() and (a.rules as Rules).finished and not (a.rules as Rules).won
		and _all_run(da, [da.quarries[0]]) and _banners(a).count(TaxCollectorDirector.FLUSH_BANNER) == 1,
		"burning after one is safe: the night stays lost, the two inside run, one banner")
	_done(a)

	# Burning again, and then a fall after burning: still one banner, each resolved once.
	var b := _world()
	var db: TaxCollectorDirector = b.d
	_banners(b).clear()
	(b.crowd as Crowd).fires.ignite(db.hideout, 0.6)
	_run(b, AssassinateDirector.TICK * 2.0 + DT)
	var alarms := 0
	for q in db.quarries:
		alarms += q.alarms
	(b.crowd as Crowd).fires.ignite(db.hideout, 0.6)
	db.hideout.destroy(db.hideout.center(), &"fire")
	_run(b, AssassinateDirector.TICK * 4.0 + DT)
	var again := 0
	for q in db.quarries:
		again += q.alarms
	t.check(_banners(b) == [TaxCollectorDirector.FLUSH_BANNER] and again == alarms and alarms == 3 and _all_run(db),
		"burning again, then falling: still one banner, each collector flushed and alarmed once (%s, %d/%d)" % [_banners(b), again, alarms])
	_done(b)

	# The fire put out does not call a flushed collector back to the counting-house.
	var o := _world()
	var do: TaxCollectorDirector = o.d
	var qo := do.quarries[0]
	qo.flushed = true
	qo.state = AssassinateDirector.State.FLEEING
	t.check(do._hideout_stands() and do._hide_goal(qo).distance_to(do.safe_at) < 0.1 and do._hide_goal().distance_to(do.hide_door) < 0.1
		and do.fleeing_to_safe(qo), "a flushed collector's goal stays the Citadel with the house standing again")
	_done(o)

	# A flushed collector whose fright is ignored (a Reassure on him) still runs for the Citadel, not on to his debtor.
	var f := _world()
	var df: TaxCollectorDirector = f.d
	for q in df.quarries:
		q.target.fearless_left = 99.0
	(f.crowd as Crowd).fires.ignite(df.hideout, 0.6)
	_run(f, AssassinateDirector.TICK * 3.0 + DT)
	t.check(_all_run(df), "a flushed collector whose panic is ignored still runs for the Citadel")
	_done(f)

	# FLUSH_GAP: the next waiting collector bursts that long after the one before.
	var g := _world()
	var dg: TaxCollectorDirector = g.d
	dg.flush_gap = 1.5
	_banners(g).clear()
	(g.crowd as Crowd).fires.ignite(dg.hideout, 0.6)
	_run(g, 1.0)
	var first := not dg.quarries[0].target.inside and dg.quarries[1].target.inside and dg.quarries[2].target.inside
	_run(g, 1.0)
	var second := not dg.quarries[1].target.inside and dg.quarries[2].target.inside
	_run(g, 1.5)
	t.check(first and second and not dg.quarries[2].target.inside and _banners(g).count(TaxCollectorDirector.FLUSH_BANNER) == 1,
		"with FLUSH_GAP 1.5 they burst one at a time, 1.5 s apart, under one banner")
	_done(g)

## v0.11.1 (R8, final review I4, the user's note 6): an Ember cast through the real cast path at the counting-house's door with all three
## waiting never smokes a collector out ahead of its own fire: the spark lands (EmberFx.T_LAND), the house burns, and all three run, one banner.
## Also M1 (a collector whose burst is pending is not sent on his round) and M2 (the spent counting-house, fire out, is no hiding place).
static func _ember_cast(t) -> void:
	var s := _world(PackedStringArray(["ember", "doom", "discord"]))
	var d: TaxCollectorDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	_banners(s).clear()
	t.check(EmberFx.target(s.env, d.hide_door) == d.hideout, "(set-up) an Ember at the door would light the counting-house")
	rules.cast(0, d.hide_door)
	_run(s, 0.3)
	var waiting := true
	for q in d.quarries:
		waiting = waiting and q.state == AssassinateDirector.State.WAITING and q.target.inside
	t.check(waiting and not _banners(s).has("THE TAX COLLECTOR SETS OUT"), "the Ember cast, nobody is smoked out ahead of its fire")
	_run(s, EmberFx.T_LAND - 0.3)
	crowd.fires.ignite(d.hideout, EmberFx.START_LEVEL)  # what EmberFx._land() does (the test's caster casts no Fx)
	_run(s, AssassinateDirector.TICK * 2.0 + DT)
	t.check(_all_run(d) and _banners(s) == [TaxCollectorDirector.FLUSH_BANNER],
		"the spark lands: all three burst out for the Citadel, one banner and no 'sets out' or 'hides' (%s)" % [_banners(s)])
	crowd.fires._put_out(d.hideout, true)
	t.check(not d._hideout_stands(), "M2: the counting-house is spent -- put out and standing, it is no hiding place again")
	_done(s)

	var m := _world()
	var dm: TaxCollectorDirector = m.d
	dm.quarries[0].burst_in = 1.0
	dm._set_out(dm.quarries[0])
	t.check(dm.quarries[0].state == AssassinateDirector.State.WAITING, "M1: a collector whose burst is pending is not sent on his round")
	_done(m)

	# M7: a visit's tag counts its seconds down.
	var v := _world()
	var dv: TaxCollectorDirector = v.d
	var qv := dv.quarries[0]
	dv._set_out(qv)
	_arrive(qv.target, qv.stop_doors[0])
	_run(v, AssassinateDirector.TICK + DT)
	var shown := false
	for tag in dv.tags():
		shown = shown or (qv.state == AssassinateDirector.State.VISITING and String(tag.label) == "TAX COLLECTOR - INSIDE " + UiTheme.clock(qv.indoors_left))
	t.check(shown, "M7: indoors on a visit, his tag counts the visit down (%s)" % [_labels(dv)])
	_done(v)

	# Any other power at the door still smokes the next collector out (v0.11 M3).
	var o := _world(PackedStringArray(["ember", "doom", "discord"]))
	var dd: TaxCollectorDirector = o.d
	(o.rules as Rules).cast(2, dd.hide_door)
	t.check(dd.quarries[0].state == AssassinateDirector.State.WALKING, "a Discord at the door still smokes the first collector out")
	_done(o)



## Spec 7.2 row 2, proven before loadout B's policy (v0.11.1 Task 8, pre-flight I3): the counting-house alight at the start, with its own
## FLUSH_GAP, never lets one bolt take all three. Measured in behaviour_check (Ember at 0.1 s, then Smite on the cluster): at gap 0 the three
## stood within 0.66 of each other and one bolt (KILL_R 0.6) took two of them, and the policy that centres it well takes three, so the gap is the
## first knob (0 -> 1.5 -> 3.0). Here: the bursts are spaced by it, and a runner (PANIC_SPEED) is a bolt's width clear of the next before
## the next is out.
static func _flush_apart(t) -> void:
	var s := _world(PackedStringArray(), false, false, true)
	var d: TaxCollectorDirector = s.d
	(s.crowd as Crowd).fires.ignite(d.hideout, 0.6)
	_run(s, DT * 2.0)
	var offsets := PackedFloat32Array()
	for q in d.quarries:
		offsets.append(q.burst_in if q.burst_in >= 0.0 else 0.0)
	t.check(is_equal_approx(d.flush_gap, TaxCollectorDirector.FLUSH_GAP) and TaxCollectorDirector.FLUSH_GAP >= 1.5
		and offsets[1] > offsets[0] + TaxCollectorDirector.FLUSH_GAP - 0.3 and offsets[2] > offsets[1] + TaxCollectorDirector.FLUSH_GAP - 0.3,
		"the three burst from the counting-house %.1f s apart (%s)" % [TaxCollectorDirector.FLUSH_GAP, offsets])
	t.check(TaxCollectorDirector.FLUSH_GAP * Person.PANIC_SPEED > 2.0 * SmiteFx.KILL_R * 1.5,
		"in that gap a runner is clear of the next out by more than a bolt's width (%.1f vs %.1f)" % [
		TaxCollectorDirector.FLUSH_GAP * Person.PANIC_SPEED, 2.0 * SmiteFx.KILL_R])
	_done(s)


## The collector out runs for the Citadel and is shown so (final review): the hint's phase, the HUD's words, and the Citadel's tag --
## red, pointed at from the edge, once -- with no debtor's.
static func _running_shown(d: TaxCollectorDirector, rules: Rules) -> bool:
	var labels := _labels(d)
	var edged := false
	for m in d.tags():
		edged = edged or (m.label == "CITADEL" and m.edge and m.color == AssassinateDirector.MARK_WATCHED)
	return d.hint_phase() == "running" and rules.objectives[0].hud_text(rules) == "Stop the collectors: 0 / 3, he runs for the Citadel" \
		and labels.count("CITADEL") == 1 and not labels.has("DEBTOR") and edged


## No hiding place (final review): the counting-house burning or down while a collector is out on his round, any later alarm sends
## him running for the Citadel -- and the hint, the HUD and the tags say so, not that he hides. With it standing he still hides.
static func _running(t) -> void:
	var a := _world(PackedStringArray(["smite", "doom", "discord"]))
	var da: TaxCollectorDirector = a.d
	var qa := da.quarries[0]
	da._set_out(qa)
	(a.crowd as Crowd).on_cast(qa.target.ground_pos + Vector2(1.5, 0.0), Vector2.ZERO, 0.0, "smite")
	_run(a, PowerBook.IMPACT.smite + 0.1)  # v0.11.2: at the impact
	t.check(qa.state == AssassinateDirector.State.FLEEING and not da.fleeing_to_safe(qa) and da.hint_phase() == "hiding"
		and (a.rules as Rules).objectives[0].hud_text(a.rules) == "Stop the collectors: 0 / 3, he hides"
		and _labels(da).has("COUNTING-HOUSE") and not _labels(da).has("CITADEL"),
		"alarmed with the counting-house standing, he hides: the hint, the HUD and the tags say that (%s)" % [_labels(da)])
	_done(a)

	for gone in [false, true]:
		var how := "down" if gone else "alight"
		var s := _world()
		var d: TaxCollectorDirector = s.d
		var q := d.quarries[0]
		d._set_out(q)
		if gone:
			d.hideout.destroy(d.hideout.center(), &"fire")
		else:
			(s.crowd as Crowd).fires.ignite(d.hideout, 0.6)
		_run(s, AssassinateDirector.TICK + DT)
		if not gone:
			# (A house brought down frightens whoever stands by it, so he is alarmed at once: the next check is for fire.)
			t.check(q.state == AssassinateDirector.State.WALKING and not d.fleeing_to_safe(q) and d.hint_phase() == ""
				and _labels(d).has("DEBTOR"),
				"out on his round with the counting-house %s: he keeps to it, the two inside run (%s)" % [how, _labels(d)])
		d._alarm(q)
		t.check(q.state == AssassinateDirector.State.FLEEING and d.fleeing_to_safe(q) and q.target.goal().distance_to(d.safe_at) < 0.5
			and _running_shown(d, s.rules),
			"alarmed with the counting-house %s: he runs for the Citadel, and is shown so (%s; %s; %s)"
			% [how, d.hint_phase(), (s.rules as Rules).objectives[0].hud_text(s.rules), _labels(d)])
		# Two running: still one Citadel tag.
		var q1 := d.quarries[1]
		d._set_out(q1)
		d._alarm(q1)
		t.check(d.fleeing_to_safe(q1) and _labels(d).count("CITADEL") == 1, "two running for it share the one Citadel tag")
		_arrive(q.target, d.safe_at)
		_run(s, AssassinateDirector.TICK + DT)
		t.check(d.any_safe() and (s.rules as Rules).finished and not (s.rules as Rules).won and (s.rules as Rules).over_reason == "taxes",
			"and he gets in: the night is lost")
		_done(s)


static func _lost(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var crowd: Crowd = s.crowd
	var rules: Rules = s.rules
	var q := d.quarries[0]
	d._set_out(q)
	var who := q.target
	crowd._field.remove(who)
	crowd.escape(who)
	who.free()  # Crowd.escape() only queues the free: a headless test frees the body itself
	_run(s, DT)
	t.check(q.state == AssassinateDirector.State.SAFE and not q.dead and d.any_safe() and rules.finished and not rules.won
		and rules.over_reason == "taxes" and String(d.report().target) == "escaped" and d.tags().is_empty(),
		"a collector gone out of the town (his body freed at once) counts as escaped: the night is lost")
	_done(s)


static func _kill(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var crowd: Crowd = s.crowd
	var q := d.quarries[0]
	d._set_out(q)
	_clear_round(crowd, q.target)
	crowd._field.kill(q.target, &"doom")
	_run(s, 0.5)
	t.check(q.dead and q.judged and q.unseen and crowd.bell.state == BellNetwork.State.IDLE and not (s.rules as Rules).finished,
		"the collector killed with nobody to see: unseen, no cry, and the night goes on")
	_done(s)

	var w := _world()
	var dw: TaxCollectorDirector = w.d
	var cw: Crowd = w.crowd
	var qw := dw.quarries[0]
	dw._set_out(qw)
	_clear_round(cw, qw.target)
	var near: Person = null
	for p in cw.citizens:
		if near == null and is_instance_valid(p) and p != qw.target and p.is_alive() and not p.inside:
			near = p
	_arrive(near, qw.target.ground_pos + Vector2(1.5, 0.0))
	t.check(dw.witnesses(qw).has(near), "the one standing near is marked as a witness")
	cw._field.kill(qw.target, &"doom")
	_run(w, 0.5)
	t.check(qw.dead and not qw.unseen and (w.banners as Array).has("THE GUARDS CRY MURDER")
		and cw.bell.state != BellNetwork.State.IDLE and int(dw.report().seen) == 1,
		"killed where someone sees: he is dead all the same, but the guards cry murder and the bellkeeper is called")
	_done(w)


static func _freed(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var crowd: Crowd = s.crowd
	var q := d.quarries[0]
	d._set_out(q)
	var g: Person = q.guards[0]
	crowd._field.remove(g)
	crowd.soldiers.erase(g)
	g.free()
	_run(s, AssassinateDirector.TICK * 2.0)
	var blue := 0
	for m in d.tags():
		blue += 1 if m.color == AssassinateDirector.MARK_GUARD else 0
	t.check(q.state == AssassinateDirector.State.WALKING and blue <= 1, "a guard's body freed: he walks on, the freed guard untagged")
	var who := q.target
	crowd._field.kill(who, &"fire")
	crowd._field.remove(who)
	crowd.citizens.erase(who)
	who.free()
	d.step(DT)
	var labels := _labels(d)
	t.check(not labels.has("TAX COLLECTOR") and d.hint_phase() == "next" and d.witnesses(q).is_empty()
		and q.dead and String(d.report().target) == "alive",
		"his body freed after the fade: untagged, the hint on the next collector, and the results still count him dead (%s)"
		% [labels])
	for i in [1, 2]:
		_kill_unseen(s, i)
	var gone: Array = []
	for qq in d.quarries:
		gone.append(qq.target)
	for p: Variant in gone:
		if is_instance_valid(p):
			crowd._field.remove(p as Person)
			crowd.citizens.erase(p)
			(p as Person).free()
	d.step(DT)
	var obj := AssassinateObjective.new("Stop the collectors", "collector", "taxes")
	t.check(d.tags().is_empty() and d.hint_phase() == "" and obj.check(s.rules) == Objective.Status.DONE
		and obj.hud_text(s.rules) == "Stop the collectors" and int(d.report().killed) == 3,
		"every body freed: no tag, no phase, and the objective is done (review focus 2)")
	_done(s)


static func _rallied(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	d._set_out(q)
	var away := TownLayout.CITADEL_ORIGIN
	for g in q.guards:
		g.send_to_post(away, true)
	_run(s, AssassinateDirector.TICK * 3.0)
	var left := true
	for g in q.guards:
		left = left and g.mind == Person.Mind.RALLY and g.anchor == away
	t.check(left and q.state == AssassinateDirector.State.WALKING,
		"the town's rally takes his guards: they are left to it, and he walks on (review focus 3)")
	_done(s)


static func _reserved(t) -> void:
	var s := _world(PackedStringArray(), true)
	var d: TaxCollectorDirector = s.d
	var held: Dictionary = s.held
	var ok := true
	for q in d.quarries:
		ok = ok and q.target != held.resident and not q.guards.has(held.soldier) and not q.stops.has(held.house)
	t.check(ok and d.quarries[0].stops.size() == 3,
		"a reserved resident is never a collector, a reserved soldier never a guard, a reserved house never a debtor's")
	_done(s)


static func _plain(t) -> void:
	var s := _world(PackedStringArray(), false, true)
	var d: AssassinateDirector = s.d
	var who: Array = []
	var ok := d.quarries.size() == 3 and d.hideout == null
	for q in d.quarries:
		ok = ok and q.target != null and not q.target.inside and not who.has(q.target)
		who.append(q.target)
	var labels := _labels(d)
	t.check(ok and not labels.is_empty() and labels[0] == "TARGET",
		"with no hideout the targets wait out of doors, still eligible, yet each is a different person, tagged on him (%s)"
		% [labels])
	_done(s)


static func _mission(t) -> void:
	var m := MissionBook.tax_collector()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.id == "tax_collector" and m.tier == 1 and m.director == TaxCollectorDirector and is_equal_approx(m.clock, 300.0)
		and m.profile == "unaware" and m.slots == 3 and m.dp_capacity == 6 and reasons == ["collector", "dawn"]
		and m.bonuses().is_empty() and m.lantern == LanternWatch.KIND_WATCH,
		"The Tax Collector: Tier 1's numbers, its director; kill them, dawn -- no bell objective, a watch night's Lantern (%s)" % [reasons])
	t.check(MissionBook.get_mission("tax_collector").id == "tax_collector" and MissionBook.tier_missions().size() >= 1
		and not MissionBook.all().any(func(x: MissionDef) -> bool: return x.id == "tax_collector"),
		"found by id among the board's own missions, never in all()")
	t.check(ResultsScreen.title_for(true, "collector") == "THE COLLECTORS ARE DEAD"
		and ResultsScreen.title_for(false, "taxes") == "THE TAXES ARE IN", "its results' titles")
	t.check(MissionHints.line("tax_collector") != "" and MissionHints.line("tax_collector", "hiding") != MissionHints.line("tax_collector")
		and MissionHints.line("tax_collector", "next") != MissionHints.line("tax_collector"), "its how-to-win lines")
	var waits_ok := TaxCollectorDirector.SET_OUT_AT[0] <= 60.0 and TaxCollectorDirector.CHAIN_WAIT >= 30.0 \
		and TaxCollectorDirector.CHAIN_WAIT <= 50.0 and TaxCollectorDirector.HIDE_SECONDS <= 60.0 \
		and TaxCollectorDirector.VISIT_SECONDS <= 60.0
	for i in range(1, TaxCollectorDirector.SET_OUT_AT.size()):
		waits_ok = waits_ok and TaxCollectorDirector.SET_OUT_AT[i] > TaxCollectorDirector.SET_OUT_AT[i - 1]
	t.check(waits_ok, "no wait over 60 s: the first set-out, the chain (30-50 s), a visit, a hiding")


## A world whose Rules carry the night's Lantern (v0.11.2, a watch night), as Mission builds it.
static func _lantern_world() -> Dictionary:
	var s := _world()
	var lw := LanternWatch.new().setup(s.rules, s.crowd, s.town, null, (s.rules as Rules).mission.lantern)
	(s.rules as Rules).lantern = lw
	s["lw"] = lw
	return s


## The bell tolls as it does in play: a keeper on the rope, the climb done.
static func _ring(s: Dictionary) -> void:
	var bell: BellNetwork = (s.crowd as Crowd).bell
	bell.state = BellNetwork.State.CLIMBING
	bell._ring()


## v0.11.2 (Task 16, D15-D21): The Tax Collector is a watch night. The toll no longer loses -- it turns the Lantern (no Herald here) -- and the
## night's schedule (set-outs, the chain) runs on mission time while its reflexes (a visit's, a hiding's seconds) stay real.
static func _lantern(t) -> void:
	var s := _lantern_world()
	var d: TaxCollectorDirector = s.d
	var lw: LanternWatch = s.lw
	var rules: Rules = s.rules
	var kinds := []
	for o in rules.objectives:
		kinds.append(o.reason)
	t.check(lw.kind == LanternWatch.KIND_WATCH and kinds == ["collector", "dawn"], "a watch night: the collectors and dawn, no HeraldObjective, no bell (%s)" % [kinds])
	_ring(s)
	_run(s, 1.0)
	t.check(lw.tolled and lw.stage == LanternWatch.Stage.STIRRING and is_equal_approx(rules.clock_rate, 1.5) and not rules.finished
		and not lw.herald_running() and lw.heralds.is_empty(), "the toll turns the Lantern (x1.5) and loses nothing; no Herald runs on a watch night")
	t.check((s.banners as Array).has(LanternWatch.TOLL_BANNER) and not (s.banners as Array).has("THE BELL TOLLS - THE TOWN IS WARNED"),
		"the Lantern's banner")
	# Reflex: a visit's seconds are real; its tag counts them in mission seconds (D20, D21).
	var q := d.quarries[0]
	d._set_out(q)
	q.target.inside = true
	q.state = AssassinateDirector.State.VISITING
	q.inside_of = q.stops[0]
	q.indoors_left = 20.0
	var words := String(d._target_tag(q).label)
	t.check(words == "TAX COLLECTOR - INSIDE 0:30", "at x1.5 a visit's 20 s reads 0:30 on its tag (%s)" % words)
	var before := q.indoors_left
	_run(s, 2.0)
	t.check(is_equal_approx(before - q.indoors_left, 2.0), "but the visit itself runs in real seconds (%.2f left)" % q.indoors_left)
	_done(s)

	# The schedule on mission time: the clock forced to x2 from the start, the collector sets out at half his time (0:35 -> 17.5 s).
	var f := _world()
	var df: TaxCollectorDirector = f.d
	(f.rules as Rules).clock_rate = 2.0
	var first := df.quarries[0]
	_run(f, TaxCollectorDirector.SET_OUT_AT[0] * 0.5 - 1.0)
	t.check(first.state == AssassinateDirector.State.WAITING, "at x2 he is still indoors a second before half his time")
	_run(f, 2.0)
	t.check(first.state != AssassinateDirector.State.WAITING, "and has set out just after it (the first scheduled event at half its real time)")
	t.check(is_equal_approx(df._clock, df.timeline.elapsed() * df.timeline.stretch_factor()), "the director's clock and the strip's agree (%.2f / %.2f)"
		% [df._clock, df.timeline.elapsed()])
	_done(f)

	# The chain on mission time: a death brings the next out CHAIN_WAIT mission seconds later (22.5 real at x2).
	var c := _world()
	var dc: TaxCollectorDirector = c.d
	(c.rules as Rules).clock_rate = 2.0
	_kill_unseen(c, 0)
	var next := dc.quarries[1]
	_run(c, TaxCollectorDirector.CHAIN_WAIT * 0.5 - 2.0)
	var early := next.state == AssassinateDirector.State.WAITING
	_run(c, 4.0)
	t.check(early and next.state != AssassinateDirector.State.WAITING and dc.quarries[0].died_at <= 0.2,
		"the chain: the next collector comes CHAIN_WAIT mission seconds after the death, 22.5 s at x2")
	_done(c)

	# Reserved from the Bearer: collectors, deputies and their guards are the director's own.
	var b := _world()
	var db: TaxCollectorDirector = b.d
	var mine := true
	for qq in db.quarries:
		mine = mine and db.busy(qq.target)
		for g in qq.guards:
			mine = mine and db.busy(g)
	var stranger: Person = null
	for p in (b.crowd as Crowd).citizens:
		if not db.busy(p):
			stranger = p
			break
	t.check(mine and stranger != null, "busy(): every collector and guard is the director's own, a passer-by is not")
	_done(b)


# --- God T1R Task 3: out of the walls (spec 5.1) and the debtors' mob (spec 5.2) ---

## Aldermere past the Main Gate's wall: out of the walls, on walkable ground (the south road).
const OUTSIDE := Vector2(2.7, 17.5)


## Quarry `i` set out and set down outside the walls, then the world stepped once: he is stopped out (OUT).
static func _send_out(s: Dictionary, i: int) -> void:
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[i]
	if q.state == AssassinateDirector.State.WAITING:
		d._set_out(q)
	_arrive(q.target, OUTSIDE)
	_run(s, DT * 2.0)


static func _out_stops(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var rules: Rules = s.rules
	var q := d.quarries[0]
	t.check(d.walls_stop, "the Tax Collector stops a collector out of the walls")
	_send_out(s, 0)
	t.check(q.state == AssassinateDirector.State.OUT and not q.dead and d.stopped() == 1 and d.killed() == 0 and d.out_count() == 1,
		"set down outside the walls, the collector is OUT: stopped, not dead")
	t.check((s.banners as Array).has(TaxCollectorDirector.OUT_BANNER), "with its banner")
	t.check(d.is_leaving(q.target) and q.target.mind == Person.Mind.DUTY, "and he is sent off the map")
	t.check(not d.any_safe() and not rules.finished and rules.objectives[0].hud_text(rules) == "Stop the collectors: 1 / 3",
		"he is not safe, the night goes on, and the HUD counts him stopped")
	t.check(is_equal_approx(d.out_at(1), q.died_at + TaxCollectorDirector.CHAIN_WAIT) and d.out_at(1) < TaxCollectorDirector.SET_OUT_AT[1],
		"the first deputy's chain runs from the stop: %.1f s" % d.out_at(1))
	t.check(not _labels(d).has("TAX COLLECTOR") and d.hint_phase() == "next" and int(d.report().out) == 1,
		"no tag for him, the hint says the next comes, the report counts him out (%s)" % [_labels(d)])
	var way := Walls.way_off(q.target.ground_pos)
	_arrive(q.target, way + Vector2(0.5, 0.0))
	_run(s, DT * 2.0)
	t.check(not d.is_leaving(q.target) and not q.target in (s.crowd as Crowd).citizens and q.state == AssassinateDirector.State.OUT,
		"within reach of his way off he is taken off the map, and he is still stopped")
	_kill_unseen(s, 1)
	t.check(not rules.finished and d.stopped() == 2, "a death and a stop make two")
	_send_out(s, 2)
	_run(s, 0.5)
	t.check(d.all_fallen() and rules.finished and rules.won and rules.over_reason == "collector"
		and rules.objectives[0].hud_text(rules) == "Stop the collectors", "all three dead or out: the night is won (reason collector)")
	var r := d.report()
	t.check(String(r.target) == "unseen" and int(r.killed) == 1 and int(r.out) == 2, "the results: one dead, two out (%s)" % [r])
	_done(s)


static func _out_not_safe(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	var q := d.quarries[0]
	_send_out(s, 0)
	var who := q.target
	crowd._field.remove(who)
	crowd.escape(who)
	who.free()  # the map's edge took the body, as in _lost()
	_run(s, AssassinateDirector.TICK + DT)
	t.check(q.state == AssassinateDirector.State.OUT and not d.any_safe() and not rules.finished and d.stopped() == 1,
		"an OUT collector whose body is gone at the map's edge is not SAFE: the night is not lost")
	_done(s)


static func _out_killed_after(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	var crowd: Crowd = s.crowd
	var q := d.quarries[0]
	_send_out(s, 0)
	var died := q.died_at
	_clear_round(crowd, q.target)
	crowd._field.kill(q.target, &"doom")
	_run(s, 1.0)
	t.check(q.state == AssassinateDirector.State.OUT and not q.dead and is_equal_approx(q.died_at, died) and not q.judged
		and q.fell_at == Vector2.INF and crowd.bell.state == BellNetwork.State.IDLE and d.stopped() == 1 and q.killed_by == "",
		"an OUT collector struck on his way off: still OUT, the chain unchanged, no judgement, the bell IDLE")
	_done(s)


## The world for the mob tests: a Decree loadout whose caster hands back one NoLeaveFx (sealed, nobody bound yet), and collector 0 having
## gone in at his first debtor's and come out, at that door.
static func _mob_world() -> Dictionary:
	var s := _world(PackedStringArray(["noleave", "belllies", "whisper"]))
	var d: TaxCollectorDirector = s.d
	var rules: Rules = s.rules
	var fx := NoLeaveFx.new()
	s["fx"] = fx
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return fx
	var q := d.quarries[0]
	d._set_out(q)
	_arrive(q.target, q.stop_doors[0])
	_run(s, AssassinateDirector.TICK + DT)
	_run(s, TaxCollectorDirector.VISIT_SECONDS + DT)
	s["door"] = q.stop_doors[0]
	return s


## A look of `seconds` with the collector pinned `off` from his debtor's door and his guards pinned at `guards_at` (the law holds them
## still where the test puts them; the real guards are drawn off by CALL THE GUARD).
static func _mob_run(s: Dictionary, off: Vector2, guards_at: Vector2, seconds: float) -> void:
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	for i in roundi(seconds / DT):
		if q.dead:
			break
		_arrive(q.target, (s.door as Vector2) + off)
		for g: Variant in q.guards:
			if MissionDirector._alive(g):
				_arrive(g as Person, guards_at)
		_run(s, DT)


## The law cast and sealed, binding the collector: centred on the door by default, or on `at` (D17: the mob reads the law's centre).
static func _seal_on(s: Dictionary, at := Vector2.INF) -> void:
	var d: TaxCollectorDirector = s.d
	var fx: NoLeaveFx = s.fx
	var centre: Vector2 = s.door if at == Vector2.INF else at
	(s.rules as Rules).cast(0, centre)
	fx.origin = centre
	fx.sealed = true
	fx.bound[d.quarries[0].target] = 0.0


static func _mob(t) -> void:
	var s := _mob_world()
	var d: TaxCollectorDirector = s.d
	var crowd: Crowd = s.crowd
	var q := d.quarries[0]
	var far := (s.door as Vector2) + Vector2(14.0, 0.0)
	t.check(q.state == AssassinateDirector.State.WALKING and not q.target.inside and not d.mob_ready(q),
		"he came out of his first debtor's, with no law on him: the mob is not ready")
	_seal_on(s)
	_mob_run(s, Vector2.ZERO, far, 0.5)
	t.check(d.mob_ready(q) and not q.dead and (_labels(d).has("TAX COLLECTOR - MOB 0:03") or _labels(d).has("TAX COLLECTOR - MOB 0:02")),
		"bound at a visited door with his guards away: ready, and his tag counts the mob down (%s)" % [_labels(d)])
	_mob_run(s, Vector2.ZERO, far, TaxCollectorDirector.MOB_AFTER - 1.0)
	t.check(not q.dead, "not before MOB_AFTER")
	_mob_run(s, Vector2.ZERO, far, 1.5)
	t.check(q.dead and q.state == AssassinateDirector.State.DEAD and q.judged and q.unseen and q.killed_by == "noleave"
		and q.fell_at == Vector2.INF and crowd.bell.state == BellNetwork.State.IDLE and d.stopped() == 1
		and (s.banners as Array).has(TaxCollectorDirector.MOB_BANNER) and not (s.banners as Array).has("THE GUARDS CRY MURDER"),
		"MOB_AFTER later he is dead, judged unseen (bell IDLE), credited to Leaving Is Prohibited, with the banner")
	t.check(is_equal_approx(d.out_at(1), minf(TaxCollectorDirector.SET_OUT_AT[1], q.died_at + TaxCollectorDirector.CHAIN_WAIT)),
		"and the chain runs from his death")
	(s.fx as NoLeaveFx).free()
	_done(s)


static func _mob_guarded(t) -> void:
	var s := _mob_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	var door: Vector2 = s.door
	_seal_on(s)
	_mob_run(s, Vector2.ZERO, door + Vector2(1.0, 0.0), TaxCollectorDirector.MOB_AFTER + 2.0)
	t.check(not q.dead and not d.mob_ready(q) and _labels(d).has("TAX COLLECTOR - GUARDED"),
		"with a guard of his within MOB_GUARD_R he lives, and his tag says GUARDED (%s)" % [_labels(d)])
	_mob_run(s, Vector2.ZERO, door + Vector2(12.0, 0.0), 1.0)
	t.check(not q.dead and d.mob_ready(q), "the guards drawn off: the mob is ready again, its seconds start over")
	_mob_run(s, Vector2.ZERO, door + Vector2(12.0, 0.0), TaxCollectorDirector.MOB_AFTER)
	t.check(q.dead and q.killed_by == "noleave", "and MOB_AFTER later he is dead")
	(s.fx as NoLeaveFx).free()
	_done(s)


static func _mob_far(t) -> void:
	var s := _mob_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	var door: Vector2 = s.door
	var away := door + Vector2(14.0, 0.0)
	# D17 boundary: the law's centre 3.5 from the door (MOB_DOOR_R is 3.0): the collector stands at the door, bound, and lives.
	_seal_on(s, door + Vector2(TaxCollectorDirector.MOB_DOOR_R + 0.5, 0.0))
	_mob_run(s, Vector2.ZERO, away, TaxCollectorDirector.MOB_AFTER + 2.0)
	t.check(not q.dead and not d.mob_ready(q), "the law's centre 3.5 from his debtor's door: the debtors do not come, he lives")
	(s.fx as NoLeaveFx).sealed = false
	_mob_run(s, Vector2.ZERO, away, TaxCollectorDirector.MOB_AFTER + 2.0)
	t.check(not q.dead and not d.mob_ready(q), "a law that is not sealed binds nobody: he lives")
	(s.fx as NoLeaveFx).free()
	_done(s)


## D17: the law is read at its centre. Centred on the door with the collector held out on the circle's edge (3.2 from the door, past MOB_DOOR_R),
## the mob starts all the same; with the centre 3.0 from the door, it starts too (the number is inclusive).
static func _mob_centre(t) -> void:
	var s := _mob_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	var door: Vector2 = s.door
	_seal_on(s)
	_mob_run(s, Vector2(TaxCollectorDirector.MOB_DOOR_R + 0.2, 0.0), door + Vector2(14.0, 0.0), 0.5)
	t.check(d.mob_ready(q) and not q.dead, "the law centred on the door, the collector held 3.2 from it: the mob is ready")
	_mob_run(s, Vector2(TaxCollectorDirector.MOB_DOOR_R + 0.2, 0.0), door + Vector2(14.0, 0.0), TaxCollectorDirector.MOB_AFTER + 0.5)
	t.check(q.dead and q.killed_by == "noleave" and q.unseen, "and MOB_AFTER later he is dead, unseen")
	(s.fx as NoLeaveFx).free()
	_done(s)
	var e := _mob_world()
	var de: TaxCollectorDirector = e.d
	var qe := de.quarries[0]
	var edge: Vector2 = e.door
	_seal_on(e, edge + Vector2(TaxCollectorDirector.MOB_DOOR_R, 0.0))
	_mob_run(e, Vector2.ZERO, edge + Vector2(14.0, 0.0), 0.5)
	t.check(de.mob_ready(qe), "the law's centre exactly MOB_DOOR_R from the door: the mob is ready")
	(e.fx as NoLeaveFx).free()
	_done(e)


## The door must be one he went in at tonight: bound at the door of the stop he has NOT reached yet (the law centred on it), he lives.
static func _mob_unvisited(t) -> void:
	var s := _mob_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	var next: Vector2 = q.stop_doors[1]
	t.check(next.distance_to(s.door) > TaxCollectorDirector.MOB_DOOR_R * 2.0, "(set-up) his second debtor's door is far from his first")
	_seal_on(s, next)
	for i in roundi((TaxCollectorDirector.MOB_AFTER + 2.0) / DT):
		_arrive(q.target, next)
		for g: Variant in q.guards:
			if MissionDirector._alive(g):
				_arrive(g as Person, next + Vector2(14.0, 0.0))
		_run(s, DT)
	t.check(not q.dead and not d.mob_ready(q), "bound at the door of a stop he has not reached: the debtors do not come, he lives")
	(s.fx as NoLeaveFx).free()
	_done(s)
