extends RefCounted
## v0.11 M2 The Tax Collector (spec §1 as the controller's Task 2 ruling reshapes it, AssassinateDirector): three collectors --
## the tax collector and his two deputies, residents made nobles -- count in the counting-house (the workshop hall) with
## their guards at its door. Each sets out on his own round of debtors' houses (3, 2 and 3 of them), 15 s indoors at each, then makes for the
## Citadel's gate, which loses the night: the collector at 0:45, each deputy at his own time or CHAIN_WAIT after the one
## before him dies, whichever is sooner (smoked out sooner still by a power cast at the door while none is out). A loud power
## near one, a guard felled or a fright sends him to hide 30 s; a house he is in set alight or brought down flushes him out
## (review focus 4) -- a collector out or hiding, never one still waiting, who sets out at his own time (fix round). All three
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
	_running(t)
	_lost(t)
	_kill(t)
	_freed(t)
	_rallied(t)
	_reserved(t)
	_plain(t)
	_mission(t)


static func _world(loadout := PackedStringArray(), reserve := false, plain := false) -> Dictionary:
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
		and String(up[2].id) == "out_2", "the strip: the collector out at 0:45, his deputies at their times")
	t.check(_labels(d) == ["TAX COLLECTOR - INSIDE", "COUNTING-HOUSE", "DEBTOR"] and d.hint_phase() == "inside",
		"tagged indoors, with the counting-house and his first debtor (%s); the hint: he is indoors" % [_labels(d)])
	var stops := d.tour()
	t.check(stops.size() == 3
		and String(stops[0][1]) == "The counting-house. The tax collector sets out at 0:45, his deputies by 1:45 and 2:45."
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
		and d.quarries[1].state == AssassinateDirector.State.WAITING, "0:45: he sets out for his first debtor; his deputies wait")
	t.check(_labels(d).has("TAX COLLECTOR") and _labels(d).has("NEXT COLLECTOR") and d.hint_phase() == ""
		and rules.objectives[0].hud_text(rules) == "Kill the collectors: 0 / 3",
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
		and rules.objectives[0].hud_text(rules) == "Kill the collectors: 0 / 3, rounds done",
		"the collector's rounds done, he makes for the Citadel")
	# Alarmed, he hides while the first deputy's own time comes.
	d._alarm(q)
	_arrive(q.target, d.hide_door)
	_run(s, AssassinateDirector.TICK + DT)
	_run(s, TaxCollectorDirector.SET_OUT_AT[1] - d._clock + DT * 2.0)
	t.check(q.state == AssassinateDirector.State.HIDING and d.quarries[1].state != AssassinateDirector.State.WAITING
		and (s.banners as Array).has("A DEPUTY SETS OUT"), "1:45 with the collector still alive: the first deputy sets out on his own time")
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
	t.check(not rules.finished and rules.objectives[0].hud_text(rules) == "Kill the collectors: 1 / 3" and d.killed() == 1,
		"one dead is not the night (%s)" % rules.objectives[0].hud_text(rules))
	_kill_unseen(s, 1)
	t.check(not rules.finished and d.killed() == 2, "nor two")
	_kill_unseen(s, 2)
	_run(s, 0.5)
	t.check(d.all_fallen() and rules.finished and rules.won and rules.over_reason == "collector"
		and rules.objectives[0].hud_text(rules) == "Kill the collectors", "all three dead: the night is won")
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
	t.check(sets == 1, "and 0:45 does not send him out a second time")
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
	d._on_cast(0, "smite", q.target.ground_pos + Vector2(TaxCollectorDirector.ALARM_REACH + 1.0, 0.0))
	t.check(q.alarms == 0, "nor a loud one beyond its reach")
	d._on_cast(0, "smite", q.target.ground_pos + Vector2(1.5, 0.0))
	t.check(q.state == AssassinateDirector.State.FLEEING and q.alarms == 1 and (s.banners as Array).has("THE TAX COLLECTOR HIDES")
		and q.target.goal().distance_to(d.hide_door) < 0.5 and d.hint_phase() == "hiding"
		and (s.rules as Rules).objectives[0].hud_text(s.rules) == "Kill the collectors: 0 / 3, he hides",
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


static func _flushed(t) -> void:
	var s := _world()
	var d: TaxCollectorDirector = s.d
	(s.crowd as Crowd).fires.ignite(d.hideout, 0.6)
	_run(s, 2.0)
	var waiting := true
	for q in d.quarries:
		waiting = waiting and q.target.inside and q.state == AssassinateDirector.State.WAITING and q.target.is_alive()
	t.check(waiting, "the counting-house alight flushes out none still waiting: one fire never sets the whole night out")
	_run(s, TaxCollectorDirector.SET_OUT_AT[0] - d._clock + DT * 2.0)
	var q0 := d.quarries[0]
	t.check(q0.state != AssassinateDirector.State.WAITING and not q0.target.inside and q0.target.is_alive()
		and d.quarries[1].state == AssassinateDirector.State.WAITING and d.quarries[1].target.inside,
		"the collector sets out at his own time all the same, and his deputies wait on")
	_done(s)

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
		and dh.quarries[1].state == AssassinateDirector.State.WAITING and dh.quarries[1].target.inside,
		"hiding there, the collector is flushed out alive (review focus 4); his deputies stay in")
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


## The collector out runs for the Citadel and is shown so (final review): the hint's phase, the HUD's words, and the Citadel's tag --
## red, pointed at from the edge, once -- with no debtor's.
static func _running_shown(d: TaxCollectorDirector, rules: Rules) -> bool:
	var labels := _labels(d)
	var edged := false
	for m in d.tags():
		edged = edged or (m.label == "CITADEL" and m.edge and m.color == AssassinateDirector.MARK_WATCHED)
	return d.hint_phase() == "running" and rules.objectives[0].hud_text(rules) == "Kill the collectors: 0 / 3, he runs for the Citadel" \
		and labels.count("CITADEL") == 1 and not labels.has("DEBTOR") and edged


## No hiding place (final review): the counting-house burning or down while a collector is out on his round, any later alarm sends
## him running for the Citadel -- and the hint, the HUD and the tags say so, not that he hides. With it standing he still hides.
static func _running(t) -> void:
	var a := _world(PackedStringArray(["smite", "doom", "discord"]))
	var da: TaxCollectorDirector = a.d
	var qa := da.quarries[0]
	da._set_out(qa)
	da._on_cast(0, "smite", qa.target.ground_pos + Vector2(1.5, 0.0))
	t.check(qa.state == AssassinateDirector.State.FLEEING and not da.fleeing_to_safe(qa) and da.hint_phase() == "hiding"
		and (a.rules as Rules).objectives[0].hud_text(a.rules) == "Kill the collectors: 0 / 3, he hides"
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
				and not _labels(d).has("CITADEL") and _labels(d).has("DEBTOR"),
				"out on his round with the counting-house %s: not yet running from anything (%s)" % [how, _labels(d)])
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
	var obj := AssassinateObjective.new("Kill the collectors", "collector", "taxes")
	t.check(d.tags().is_empty() and d.hint_phase() == "" and obj.check(s.rules) == Objective.Status.DONE
		and obj.hud_text(s.rules) == "Kill the collectors" and int(d.report().killed) == 3,
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
		and m.profile == "unaware" and m.slots == 3 and m.dp_capacity == 6 and reasons == ["collector", "bell", "dawn"]
		and m.bonuses().is_empty(), "The Tax Collector: Tier 1's numbers, its director; kill them, the bell, dawn (%s)" % [reasons])
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
