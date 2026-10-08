extends RefCounted
## v0.11 M2 The Lost Lamb (spec §3, LostLambDirector on EscortDirector): the runaway acolyte -- the cleric nearest the north-
## east fountain -- holds where the god leaves him. Two patrols walk their beats, the watch holds the west gate, and from 2:30
## two searchers walk to him: any of them within 2.5 seizes him on sight (none held by the god or turned) and marches him
## to the Temple, which loses the night; the seizer felled, turned or freed frees him. The watch changes 30 s after he first
## nears the gate, away 25 s, every 45 s (review focus 5). At the way out he escapes, freed at once (review focus 2). The
## town's rally is borne (review focus 3): a soldier the rally or the marshals have taken -- his mind not his post's nor the
## errand's, or of a corps -- sees nothing and seizes no one, the searchers among them (the controller's Task 4 ruling).

const DT := 0.05


static func run(t) -> void:
	_setup(t)
	_seize(t)
	_blind(t)
	_taken(t)
	_watch(t)
	_escape(t)
	_hunt(t)
	_searchers(t)
	_freed(t)
	_rallied(t)
	_orders(t)
	_rallied_hunt(t)
	_carried(t)
	_hidden(t)
	_dead(t)
	_lured(t)
	_mission(t)


static func _world() -> Dictionary:
	var def := MissionBook.lost_lamb()
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
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var director := def.make_director().setup(rules, crowd, town, null) as LostLambDirector
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners}


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


static func _labels(d: MissionDirector) -> Array:
	var out := []
	for m in d.tags():
		if m.label != "":
			out.append(m.label)
	return out


## Every soldier set to watch for him -- the watch, the patrols, the searchers -- sent far off, so none sees him by chance.
static func _clear_watchers(d: EscortDirector) -> void:
	var all: Array = d.watch.duplicate()
	for squad: Array in d.patrols:
		all.append_array(squad)
	all.append_array(d.hunters)
	for p: Variant in all:
		if MissionDirector._alive(p):
			(p as Person).ground_pos = Vector2(-14.0, -14.0)


static func _setup(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	t.check(d.charge != null and d.charge.profile.role == CitizenProfile.Role.CLERGY
		and d.charge.ground_pos.distance_to(LostLambDirector.START) <= 1.5 and d.charge.mind == Person.Mind.DUTY,
		"the acolyte: a cleric, holding by the north-east fountain")
	var all: Array = d.watch.duplicate()
	for squad: Array in d.patrols:
		all.append_array(squad)
	var distinct := true
	for i in all.size():
		distinct = distinct and all.find(all[i]) == i and (all[i] as Person).soldier
	t.check(d.charge.pace <= Person.PACE_RANGE.y * LostLambDirector.CHARGE_PACE + 0.001 and LostLambDirector.CHARGE_PACE < 1.0,
		"he walks at his slow pace: a citizen's own, times CHARGE_PACE")
	t.check(d.watch.size() == 2 and d.patrols.size() == 2 and (d.patrols[0] as Array).size() == 2 and distinct,
		"two watchmen at the gate and two patrols of two, all different soldiers")
	for w in d.watch:
		_arrive(w, w.anchor)  # (headless tests never walk: the watch set down at its posts)
	t.check(_labels(d) == ["ACOLYTE", "WEST GATE - WATCHED", "PATROL", "PATROL"] and d.hint_phase() == "",
		"tagged: the acolyte, the watched gate, each patrol (%s)" % [_labels(d)])
	var up := d.timeline.upcoming(1)
	t.check(not up.is_empty() and String(up[0].id) == "hunt" and is_equal_approx(float(up[0].at), LostLambDirector.HUNT_AT),
		"the searchers set out at 2:30")
	var stops := d.tour()
	t.check(stops.size() == 3 and String(stops[0][1]) == "The runaway acolyte hides by the north-east fountain."
		and String(stops[2][1]) == "The Temple. At 2:30 it sends searchers after him.", "the tour: him, the gate, the Temple")
	_done(s)


static func _seize(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var p: Person = d.patrols[0][0]
	_arrive(p, d.charge.ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(d.held and d.seizer == p and p.mind == Person.Mind.DUTY and p.goal().distance_to(d.return_to) < 0.5
		and d.seizures == 1 and (s.banners as Array).has("THE LAMB IS CAUGHT"), "a patrol soldier in sight seizes him for the Temple")
	t.check(_labels(d).has("ACOLYTE - CAUGHT") and _labels(d).has("TAKING HIM BACK") and _labels(d).has("TEMPLE")
		and d.hint_phase() == "caught", "tagged caught, his seizer and the Temple; the hint: free him")
	p.mind = Person.Mind.CONFUSED
	_run(s, EscortDirector.TICK + DT)
	t.check(not d.held and (s.banners as Array).has("THE LAMB IS FREE") and d.charge.mind == Person.Mind.DUTY,
		"his seizer confused: he is free, and holds where he stands")
	var q: Person = d.patrols[1][0]
	_arrive(q, d.charge.ground_pos + Vector2(0.0, 1.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(d.held and d.seizer == q, "seized again by another")
	(s.crowd as Crowd)._field.kill(q, &"fire")
	_run(s, EscortDirector.TICK + DT)
	t.check(not d.held and d.seizures == 2, "his seizer felled: free again")
	_done(s)


static func _blind(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var p: Person = d.patrols[0][0]
	p.mind = Person.Mind.CONFUSED
	_arrive(p, d.charge.ground_pos + Vector2(1.0, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(not d.held, "a soldier held by Discord does not see him")
	_done(s)


static func _taken(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var rules: Rules = s.rules
	_clear_watchers(d)
	var p: Person = d.patrols[0][0]
	_arrive(p, d.charge.ground_pos + Vector2(1.0, 0.0))
	_run(s, EscortDirector.TICK + DT)
	_arrive(p, d.return_to)
	_arrive(d.charge, d.return_to + Vector2(0.5, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(d.taken and rules.finished and not rules.won and rules.over_reason == "taken"
		and (s.banners as Array).has("THE LAMB IS TAKEN BACK"), "marched to the Temple's door: the night is lost")
	_done(s)


static func _watch(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	for w in d.watch:
		_arrive(w, w.anchor)  # the watch back at its posts, out of his sight (4.5 units off)
	_arrive(d.charge, d.gate_at + Vector2(0.0, -4.5))
	d._hold_at = d.charge.ground_pos
	_run(s, EscortDirector.TICK + DT)
	t.check(d.change_in > EscortDirector.WATCH_CHANGE - 1.0 and not d.watch_away and not d.held and d.hint_phase() == "gate",
		"near the gate: the watch will change in 30 s (the wait starts when he arrives)")
	_run(s, EscortDirector.WATCH_CHANGE)
	t.check(d.watch_away and (s.banners as Array).has("THE WATCH CHANGES") and d.hint_phase() == "clear"
		and _labels(d).has("WEST GATE - CLEAR"), "30 s on: the watch changes, the gate is clear")
	_run(s, EscortDirector.WATCH_GAP + DT)
	t.check(not d.watch_away and d.change_in > EscortDirector.WATCH_CYCLE - EscortDirector.WATCH_GAP - 1.0,
		"25 s later the watch is back, the next change 20 s off")
	_run(s, EscortDirector.WATCH_CYCLE - EscortDirector.WATCH_GAP)
	t.check(d.watch_away, "and changes again 45 s after the first change: no wait over a minute (review focus 5)")
	t.check(EscortDirector.WATCH_CHANGE + EscortDirector.WATCH_GAP <= 60.0 and EscortDirector.WATCH_CYCLE <= 60.0
		and EscortDirector.WATCH_CHANGE <= 60.0, "the numbers keep it so: the change and the gap, and the cycle, are a minute or less")
	_done(s)


static func _escape(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var rules: Rules = s.rules
	_clear_watchers(d)
	_arrive(d.charge, d.exit_at)
	_run(s, EscortDirector.TICK + DT)
	t.check(d.escaped and rules.finished and rules.won and rules.over_reason == "out" and (s.banners as Array).has("THE LAMB IS OUT"),
		"at the way out he escapes: won")
	t.check((s.banners as Array).count("THE LAMB IS OUT") == 1, "and the crowd's word of it does not say it twice")
	d.charge.free()  # (Crowd.escape() frees the body at once; a test frees it by hand)
	d.step(EscortDirector.TICK + DT)
	t.check(d.tags().is_empty() and d.hint_phase() == "" and bool(d.report().out) and not d.charge_lost() and d.tour().size() == 2,
		"escaped, his body freed: no tag, no phase, nothing touched, the tour skips him (review focus 2)")
	_done(s)


static func _hunt(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	_run(s, LostLambDirector.HUNT_AT + DT * 2.0)
	var ok := d.hunters.size() == LostLambDirector.HUNTERS
	for h in d.hunters:
		ok = ok and h.mind == Person.Mind.DUTY and h.goal().distance_to(d.charge.ground_pos) < 1.5
	t.check(ok and (s.banners as Array).has("THE TEMPLE SENDS SEARCHERS") and _labels(d).count("SEARCHER") == 2,
		"2:30: two searchers walk to him, tagged")
	_done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var crowd: Crowd = s.crowd
	_clear_watchers(d)
	var p: Person = d.patrols[0][0]
	_arrive(p, d.charge.ground_pos + Vector2(1.0, 0.0))
	_run(s, EscortDirector.TICK + DT)
	crowd._field.kill(p, &"fire")
	crowd._field.remove(p)
	crowd.soldiers.erase(p)
	p.free()
	_run(s, EscortDirector.TICK + DT)
	var tags := d.tags()
	t.check(not d.held and d.hint_phase() == "" and tags.size() == 2 + 2 + 3 and not _labels(d).has("TAKING HIM BACK"),
		"his seizer's body freed: he is free, and the body draws no tag (%d tags) (review focus 2)" % [tags.size()])
	_done(s)


static func _rallied(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var away := TownLayout.CITADEL_ORIGIN
	var all: Array = d.watch.duplicate()
	for squad: Array in d.patrols:
		all.append_array(squad)
	for p: Variant in all:
		(p as Person).send_to_post(away, true)
	_run(s, EscortDirector.TICK * 3.0)
	var left := true
	for p: Variant in all:
		left = left and (p as Person).mind == Person.Mind.RALLY and (p as Person).anchor == away
	t.check(left, "the town's rally takes the watch and the patrols: they are left to it (review focus 3)")
	_run(s, LostLambDirector.HUNT_AT)
	for h in d.hunters:
		(h as Person).send_to_post(away, true)
	_run(s, EscortDirector.TICK * 3.0)
	left = not d.hunters.is_empty()
	for h in d.hunters:
		left = left and h.mind == Person.Mind.RALLY and h.anchor == away
	t.check(left, "and the searchers: the rally takes them off the errand, and they are left to it (review focus 3)")
	_done(s)


## A soldier the town has taken -- the rally, a marshal's post, a fight -- is not the director's to use: seeing nothing, he seizes
## no one, even beside him (the controller's Task 4 ruling, Decision 20).
static func _orders(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var p: Person = d.patrols[0][0]
	var q: Person = d.patrols[1][0]
	var w: Person = d.watch[0]
	p.send_to_post(TownLayout.CITADEL_ORIGIN, true)
	_arrive(p, d.charge.ground_pos + Vector2(1.0, 0.0))
	q.corps = Person.Corps.MARSHAL
	_arrive(q, d.charge.ground_pos + Vector2(0.0, 1.0))
	w.mind = Person.Mind.FIGHT
	_arrive(w, d.charge.ground_pos + Vector2(-1.0, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(not d.held and p.mind == Person.Mind.RALLY and q.mind == Person.Mind.POST and w.mind == Person.Mind.FIGHT,
		"beside him, a rallied soldier, a marshal and a fighting one do not seize him, and are left as the town has them")
	q.corps = Person.Corps.NONE
	q.mind = Person.Mind.POST
	_run(s, EscortDirector.TICK + DT)
	t.check(d.held and d.seizer == q, "the same marshal released to his post, he does")
	_done(s)


## The searchers (spec §3, review focus 1): the free soldiers nearest the Temple's door, the reserved left out; they walk to
## wherever he is (he moved, they follow), and one in sight seizes him.
static func _searchers(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var crowd: Crowd = s.crowd
	_clear_watchers(d)
	var held: Array = []
	for p in crowd.soldiers:
		if not d._watchers().has(p) and p.corps == Person.Corps.NONE:
			held.append(p)
	held.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(d.return_to) < b.ground_pos.distance_squared_to(d.return_to))
	var nearest: Person = held[0]
	d.reserved.append(nearest)
	_run(s, LostLambDirector.HUNT_AT + DT * 2.0)
	t.check(d.hunters.size() == LostLambDirector.HUNTERS and not d.hunters.has(nearest) and held.has(d.hunters[0]),
		"2:30: the searchers are free soldiers, not already watching for him, and never a reserved one")
	_arrive(d.charge, d.charge.ground_pos + Vector2(5.0, 0.0))
	d._hold_at = d.charge.ground_pos
	_run(s, EscortDirector.TICK + DT)
	var moved := true
	for h in d.hunters:
		moved = moved and h.goal().distance_to(d.charge.ground_pos) < 1.5
	t.check(moved, "he is moved: the searchers walk to where he is now")
	var h: Person = d.hunters[0]
	_arrive(h, d.charge.ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(d.held and d.seizer == h and (s.banners as Array).has("THE LAMB IS CAUGHT") and _labels(d).count("SEARCHER") == 1
		and _labels(d).has("TAKING HIM BACK"),
		"a searcher in sight seizes him")
	_done(s)


## The searchers come only from soldiers at their posts (the controller's Task 4 fix ruling): after the town's rally the free
## soldiers stand on its ring, and none of them is sent after him; one back on his post is.
static func _rallied_hunt(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var crowd: Crowd = s.crowd
	_clear_watchers(d)
	crowd.rally()
	_run(s, LostLambDirector.HUNT_AT + DT * 2.0)
	t.check(crowd.ring_count() > 0 and d.hunters.is_empty() and (s.banners as Array).has("THE TEMPLE SENDS SEARCHERS"),
		"after the rally nobody on its ring is sent: no searchers")
	_done(s)
	s = _world()
	d = s.d
	crowd = s.crowd
	_clear_watchers(d)
	crowd.rally()
	var back: Person = null
	for p in crowd.soldiers:
		if not d._watchers().has(p) and p.corps == Person.Corps.NONE and p.mind == Person.Mind.RALLY:
			back = p
			break
	back.send_to_post(back.ground_pos)
	_run(s, LostLambDirector.HUNT_AT + DT * 2.0)
	t.check(d.hunters.size() == 1 and d.hunters[0] == back and back.mind == Person.Mind.DUTY,
		"one soldier back on his post is the only searcher")
	_done(s)


## The crowd's own exit logic carries him off (a gate he fled to, a boat): that is his escape, the win, not his death (the
## controller's Task 4 fix ruling; the Procession's Prince is judged the same way).
static func _carried(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	_clear_watchers(d)
	var lamb: Person = d.charge
	lamb.mind = Person.Mind.FLEE
	lamb.ground_pos = d.exit_at + Vector2(0.0, 6.0)
	lamb._goal = lamb.ground_pos
	crowd.advance(DT)
	t.check(d.escaped and (s.banners as Array).has("THE LAMB IS OUT") and crowd.escaped_count == 1,
		"fleeing to an exit, the crowd carries him off: he is out")
	lamb.free()  # (the crowd frees the body a frame later)
	_run(s, EscortDirector.TICK + DT)
	t.check(rules.finished and rules.won and rules.over_reason == "out" and not d.charge_lost() and d.tags().is_empty()
		and bool(d.report().out), "and the night is won, not lost with him dead")
	_done(s)
	s = _world()
	d = s.d
	crowd = s.crowd
	_clear_watchers(d)
	var p: Person = d.patrols[0][0]
	_arrive(p, d.charge.ground_pos + Vector2(1.0, 0.0))
	_run(s, EscortDirector.TICK + DT)
	var seizer := p
	d.charge.mind = Person.Mind.FLEE
	d.charge._goal = d.charge.ground_pos
	crowd.advance(DT)
	t.check(d.held == false and d.escaped and seizer.mind == Person.Mind.POST and d.seizer == null,
		"carried off in a seizer's hands, he is out and his seizer is let go")
	_done(s)


## A fright sends him indoors to shelter (mind SHELTER, hidden): nobody sees him there, and nobody seizes what he cannot see.
static func _hidden(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var p: Person = d.patrols[0][0]
	d.charge.inside = true
	_arrive(p, d.charge.ground_pos + Vector2(1.0, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(not d.held, "indoors, sheltering, he is not seized by the soldier beside the door")
	d.charge.inside = false
	_run(s, EscortDirector.TICK + DT)
	t.check(d.held and d.seizer == p, "out again, he is seen")
	_done(s)


## He dies: the night is lost ("lamb"), and his freed body is borne.
static func _dead(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var rules: Rules = s.rules
	_clear_watchers(d)
	(s.crowd as Crowd)._field.kill(d.charge, &"fire")
	_run(s, EscortDirector.TICK + DT)
	t.check(d.charge_lost() and rules.finished and not rules.won and rules.over_reason == "lamb" and d.tags().is_empty()
		and d.hint_phase() == "", "he dies: the night is lost, and nothing is tagged")
	var body: Person = d.charge
	body.free()
	d.step(EscortDirector.TICK + DT)
	t.check(d.charge_lost() and d.tags().is_empty() and d.hint_phase() == "" and d.tour().size() == 2,
		"his body freed: still lost, nothing touches it")
	_done(s)


static func _lured(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	d.charge.mind = Person.Mind.OBSERVE
	_run(s, EscortDirector.TICK + DT)
	t.check(d.charge.mind == Person.Mind.OBSERVE, "lured by a light, he is let follow it")
	d.charge.mind = Person.Mind.CALM
	_arrive(d.charge, d.charge.ground_pos + Vector2(2.0, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(d.charge.mind == Person.Mind.DUTY and d.charge.anchor.distance_to(d.charge.ground_pos) < 0.5,
		"back on his feet, he holds where he was left")
	_done(s)


static func _mission(t) -> void:
	var m := MissionBook.lost_lamb()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.id == "lost_lamb" and m.tier == 1 and m.director == LostLambDirector and is_equal_approx(m.clock, 300.0)
		and m.profile == "unaware" and reasons == ["out", "dawn"] and m.bonuses().is_empty(),
		"The Lost Lamb: Tier 1's numbers, its director; lead him out, dawn (%s)" % [reasons])
	t.check(MissionBook.get_mission("lost_lamb").id == "lost_lamb", "found by id")
	t.check(ResultsScreen.title_for(true, "out") == "THE LAMB IS FREE" and ResultsScreen.title_for(false, "taken") == "THE LAMB IS TAKEN BACK"
		and ResultsScreen.title_for(false, "lamb") == "THE ACOLYTE IS DEAD", "its results' titles")
	var none := EscortObjective.new("Lead the acolyte out", "out", "taken", "lamb")
	t.check(none.reason == "out" and none.label == "Lead the acolyte out", "its objective's words")
