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
	_walking_back(t)
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
	_wisp_leads(t)
	_mission(t)
	_bolts_at_one(t)
	_bolts_on_smite(t)
	_bolts_on_fire(t)
	_bolts_on_death(t)
	_bolts_on_blight(t)
	_led_never_bolts(t)
	_bolt_fear(t)
	_bolt_seized_freed(t)
	_fold_to_exit_seen(t)
	_fold_to_exit_clear(t)
	_tag_countdown(t)
	_bolt_is_a_minute(t)
	_bolt_teardown(t)
	_led_hint(t)
	_passage_dead_end(t)


static func _world(stretch := 1.0) -> Dictionary:
	var def := MissionBook.lost_lamb()
	def.stretch = stretch
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
	t.check(_labels(d) == ["ACOLYTE - BOLTS IN 1:00", "WEST GATE - WATCHED", "PATROL", "PATROL"] and d.hint_phase() == "",
		"tagged: the acolyte (and when he bolts), the watched gate, each patrol (%s)" % [_labels(d)])
	var gate_edged := false
	for tag in d.tags():
		gate_edged = gate_edged or (tag.label.begins_with("WEST GATE") and tag.edge)
	t.check(gate_edged, "the way out is pointed at from the screen's edge, the gate being far from the acolyte (v0.11 M2, Task 8 fix)")
	var up := d.timeline.upcoming(2)
	t.check(up.size() == 2 and String(up[0].id) == "bolt" and is_equal_approx(float(up[0].at), LostLambDirector.BOLT_AT)
		and String(up[1].id) == "hunt" and is_equal_approx(float(up[1].at), LostLambDirector.HUNT_AT),
		"he bolts at 1:00 and the searchers set out at 2:30")
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
	t.check(d.taken and rules.finished and not rules.won and rules.over_reason == "lamb_taken"
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


## The gate reads watched while the watch walks back (final review): the change over, the watchmen still at the guardhouse -- beyond
## the gate's reach -- are on their way to their posts and will see him, so the tag and the hint say watched; one drawn off
## elsewhere (a lure), or frightened, is not counted, and with none left it reads clear. Only the display: seizing is _seen_by()'s
## alone, and the scripted player's own choice (_watch_standing()) is not changed.
static func _walking_back(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	_arrive(d.charge, d.gate_at + Vector2(0.0, -4.5))
	d._hold_at = d.charge.ground_pos
	d.watch_away = true
	d._step_watch_posts()  # off to the guardhouse for the change
	for w in d.watch:
		_arrive(w, w.anchor)
	var away := d.hint_phase() == "clear" and _labels(d).has("WEST GATE - CLEAR")
	d.watch_away = false
	d._step_watch_posts()  # the change over: back to their posts
	var far := not d.watch.is_empty()
	var headed := true
	for w in d.watch:
		far = far and w.ground_pos.distance_to(d.gate_at) > EscortDirector.SIGHT + 1.0
		headed = headed and w.goal() != Vector2.INF
	t.check(away and far and headed and not d._watch_standing() and d.hint_phase() == "gate"
		and _labels(d).has("WEST GATE - WATCHED") and not _labels(d).has("WEST GATE - CLEAR"),
		"the watch walking back from the guardhouse, still far from the gate: it reads watched, not clear (%s; %s)" % [d.hint_phase(), _labels(d)])
	for w in d.watch:
		w.mind = Person.Mind.OBSERVE
		w.set_goal(d.guardhouse + Vector2(0.0, -3.0))
	t.check(d.hint_phase() == "clear" and _labels(d).has("WEST GATE - CLEAR"),
		"drawn off by a lure, the watch does not hold the gate: clear")
	for w in d.watch:
		w.mind = Person.Mind.PANIC
	t.check(d.hint_phase() == "clear" and _labels(d).has("WEST GATE - CLEAR"), "frightened off, none would see him: clear")
	_done(s)


static func _escape(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var rules: Rules = s.rules
	_clear_watchers(d)
	_arrive(d.charge, d.exit_at)
	_run(s, EscortDirector.TICK + DT)
	t.check(d.escaped and rules.finished and rules.won and rules.over_reason == "lamb_out" and (s.banners as Array).has("THE LAMB IS OUT"),
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
	t.check(rules.finished and rules.won and rules.over_reason == "lamb_out" and not d.charge_lost() and d.tags().is_empty()
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


## Spec 7.2 row 4, proven before loadout B's policy (v0.11.1 Task 8): the Wisp leads him -- which the audit took for granted: he holds on duty,
## which no light draws. Now he answers one from as far as it draws anyone (WISP_HAND) though his hold stops it within CHARGE_LURE_R:
## he walks to the near side of its ring at his own slow pace (the lure lasts until he is there and has stared WISP_STARE), and holds where
## it leaves him. A light too far, or not a Wisp's, moves him not at all; one within CHARGE_LURE_R is the Wisp's own to draw.
static func _wisp_leads(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var lamb := d.charge
	t.check(lamb.answers_lure, "the acolyte answers a lure from his duty")
	var from := lamb.ground_pos
	var light := d._walkable(from + Vector2(0.0, 5.0))
	d._on_light(0, "ember", light)
	t.check(lamb.mind == Person.Mind.DUTY, "a spark is no Wisp: he holds")
	d._on_light(0, "wisp", d._walkable(from + Vector2(0.0, 8.5)))
	t.check(lamb.mind == Person.Mind.DUTY, "a Wisp beyond WISP_HAND draws him not")
	d._on_light(0, "wisp", d._walkable(from + Vector2(0.0, 1.5)))
	t.check(lamb.mind == Person.Mind.DUTY, "one within CHARGE_LURE_R is the Wisp's own to draw, not the director's")
	d._on_light(0, "wisp", light)
	var gap := lamb.ground_pos.distance_to(light)
	t.check(lamb.mind == Person.Mind.OBSERVE and lamb.has_goal() and lamb._observe_left > WillOWisp.WISP_TIME - 0.5,
		"a Wisp five off draws him, and he is given the time his slow walk to it takes (%.1f s)" % lamb._observe_left)
	# He walks it, staying drawn; where it leaves him is where he holds.
	for i in roundi((lamb._observe_left - 1.0) / 0.25):
		lamb.tick(0.25)
		d.step(0.25)
	t.check(lamb.ground_pos.distance_to(light) < gap - 1.0 and lamb.mind == Person.Mind.OBSERVE,
		"he comes toward the light (%.1f from it, was %.1f)" % [lamb.ground_pos.distance_to(light), gap])
	_arrive(lamb, light + Vector2(0.0, -0.8))
	d.step(EscortDirector.TICK + DT)
	t.check(lamb.anchor.distance_to(lamb.ground_pos) < 0.5 and d._hold_at.distance_to(lamb.ground_pos) < 0.5,
		"his hold goes with him: where the light leaves him is where he stays, not where he stood before")
	_done(s)


static func _mission(t) -> void:
	var m := MissionBook.lost_lamb()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.id == "lost_lamb" and m.tier == 1 and m.director == LostLambDirector and is_equal_approx(m.clock, 300.0)
		and m.profile == "unaware" and reasons == ["lamb_out", "dawn"] and m.bonuses().is_empty(),
		"The Lost Lamb: Tier 1's numbers, its director; lead him out, dawn (%s)" % [reasons])
	t.check(MissionBook.get_mission("lost_lamb").id == "lost_lamb", "found by id")
	t.check(ResultsScreen.title_for(true, "lamb_out") == "THE LAMB IS FREE" and ResultsScreen.title_for(false, "lamb_taken") == "THE LAMB IS TAKEN BACK"
		and ResultsScreen.title_for(false, "lamb") == "THE ACOLYTE IS DEAD", "its results' titles")
	t.check(ResultsScreen.title_for(true, "out") != "THE LAMB IS FREE" and ResultsScreen.title_for(false, "taken") != "THE LAMB IS TAKEN BACK"
		and ResultsScreen.title_for(false, "dead") != "THE ACOLYTE IS DEAD",
		"the Escort type's own default reasons (out, taken, dead) are not the lamb's titles, for a later Escort mission (final review)")
	var none := EscortObjective.new("Lead the acolyte out", "lamb_out", "lamb_taken", "lamb")
	t.check(none.reason == "lamb_out" and none.label == "Lead the acolyte out", "its objective's words")


# --- God T1R (Task 5): he bolts, and the outer watchman ---

## Nothing done: at BOLT_AT he sets out for the way out on his own -- on duty for it, the banner, the tag RUNNING, the strip's event spent.
static func _bolts_at_one(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	_run(s, LostLambDirector.BOLT_AT - 1.0)
	t.check(not d.bolting and not d.led and d.bolt_left() > 0.5 and d.bolt_left() < 1.6 and d.charge.anchor.distance_to(d.charge.ground_pos) < 0.5,
		"before 1:00 he holds where he hides, a second off his bolt (%.1f)" % d.bolt_left())
	_clear_watchers(d)
	_run(s, 1.5)
	t.check(d.bolting and not d.led and d.charge.mind == Person.Mind.DUTY and d.charge.anchor.distance_to(d.exit_at) < 0.5
		and d.bolt_left() == 0.0, "at 1:00 he bolts: on duty for the way out")
	t.check((s.banners as Array).count("HE BOLTS FOR THE WEST GATE") == 1, "the banner says so, once (%s)" % [s.banners])
	t.check(_labels(d).has("ACOLYTE - RUNNING") and d.hint_phase() == "running", "tagged RUNNING, and the hint's phase is running (%s)" % [_labels(d)])
	var listed := false
	for e in d.timeline.upcoming(4):
		listed = listed or String(e.id) == "bolt"
	t.check(not listed, "the strip no longer lists the bolt")
	_done(s)


## A loud power's danger landing within BOLT_REACH sends him; one beyond it does not.
static func _bolts_on_smite(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	_run(s, 20.0)
	var near: Array[Vector2] = [d.charge.ground_pos + Vector2(4.0, 0.0)]
	(s.crowd as Crowd).danger_landed.emit("smite", near)
	t.check(d.bolting and not d.led and (s.banners as Array).has("HE BOLTS FOR THE WEST GATE") and d.charge.mind == Person.Mind.DUTY
		and d.charge.anchor.distance_to(d.exit_at) < 0.5, "a Smite's danger 4 from him at 0:20: he bolts, and is on his way at once")
	_done(s)
	s = _world()
	d = s.d
	_clear_watchers(d)
	_run(s, 20.0)
	var far: Array[Vector2] = [d.charge.ground_pos + Vector2(7.0, 0.0)]
	(s.crowd as Crowd).danger_landed.emit("smite", far)
	_run(s, EscortDirector.TICK * 2.0)
	t.check(not d.bolting and d.bolt_left() > 39.0, "7 from him: he does not")
	_done(s)


## A building set alight within reach starts his run; one past it does not.
static func _bolts_on_fire(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var crowd: Crowd = s.crowd
	var near: Structure = null
	var far: Structure = null
	for st in (s.env as EnvironmentField).structures():
		if not FireManager.burns(st):
			continue
		var gap := st.distance_to(d.charge.ground_pos)
		if gap <= LostLambDirector.BOLT_REACH - 0.5 and near == null:
			near = st
		elif gap > LostLambDirector.BOLT_REACH + 1.0 and far == null:
			far = st
	t.check(near != null and far != null, "the town has a burnable building within 5.5 of the fountain and one past 7")
	if near == null or far == null:
		_done(s)
		return
	crowd.fires.ignite(far, 1.0)
	_run(s, EscortDirector.TICK * 3.0)
	t.check(not d.bolting, "a house afire 7 off: he does not bolt")
	crowd.fires.ignite(near, 1.0)
	_run(s, EscortDirector.TICK * 3.0)
	t.check(d.bolting and (s.banners as Array).has("HE BOLTS FOR THE WEST GATE"), "a house afire within 6: he bolts at the next look")
	_done(s)


## A death within reach starts his run (of anyone, however he died); one beyond it does not.
static func _bolts_on_death(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var crowd: Crowd = s.crowd
	var others: Array[Person] = []
	for p in crowd.citizens:
		if p != d.charge and others.size() < 2:
			others.append(p)
	_arrive(others[0], d.charge.ground_pos + Vector2(9.0, 0.0))
	crowd._field.kill(others[0], &"fire")
	t.check(not d.bolting, "a citizen dying 9 off: he does not bolt")
	_arrive(others[1], d.charge.ground_pos + Vector2(4.0, 0.0))
	crowd._field.kill(others[1], &"fire")
	t.check(d.bolting and d.charge.mind == Person.Mind.DUTY, "a citizen dying 4 off: he bolts")
	_done(s)


## His fountain blighted starts his run; another fountain does not.
static func _bolts_on_blight(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var env: EnvironmentField = s.env
	t.check(d.fountain != null and d.fountain.kind == Structure.Kind.FOUNTAIN, "his hiding place is a fountain")
	var other: Structure = null
	for st in env.structures():
		if st.kind == Structure.Kind.FOUNTAIN and st != d.fountain and not st.blighted:
			other = st
			break
	if other != null:
		env.blight(other)
		t.check(not d.bolting, "another fountain rotted: he does not bolt")
	env.blight(d.fountain)
	t.check(d.bolting and (s.banners as Array).has("HE BOLTS FOR THE WEST GATE"), "his fountain blighted: he bolts")
	_done(s)


## Whispered at 0:05: led, so at BOLT_AT he does not bolt, and a startle later does not start him either.
static func _led_never_bolts(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	_run(s, 5.0)
	var to := d.charge.ground_pos + Vector2(0.0, 2.0)
	t.check(d.charge.whisper(to, MindWhisperFx.LINGER), "whispered at 0:05")
	_run(s, EscortDirector.TICK * 2.0)
	t.check(d.led and not d.bolting and d.bolt_left() == 0.0 and _labels(d).has("ACOLYTE"),
		"led: no bolt coming, and the tag says only ACOLYTE (%s)" % [_labels(d)])
	_clear_watchers(d)
	_run(s, LostLambDirector.BOLT_AT)
	t.check(not d.bolting and not (s.banners as Array).has("HE BOLTS FOR THE WEST GATE"), "past 1:00 he has not bolted")
	var near: Array[Vector2] = [d.charge.ground_pos + Vector2(3.0, 0.0)]
	(s.crowd as Crowd).danger_landed.emit("smite", near)
	t.check(not d.bolting, "and a startle after he was led does not start him")
	_done(s)
	# A Wisp's own light within CHARGE_LURE_R leads him too; a Death Mark's body drawing him does not.
	s = _world()
	d = s.d
	_clear_watchers(d)
	d._on_light(0, "wisp", d.charge.ground_pos + Vector2(0.0, 2.0))
	d.charge.lure(d.charge.ground_pos + Vector2(0.0, 2.5), 8.0, d.charge.ground_pos + Vector2(0.0, 2.0))
	d.step(DT)
	t.check(d.led, "a Wisp's light beside him draws him: led")
	_done(s)
	s = _world()
	d = s.d
	_clear_watchers(d)
	d.charge.lure(d.charge.ground_pos + Vector2(0.0, 2.5), 8.0, d.charge.ground_pos + Vector2(0.0, 2.0))
	d.step(DT)
	t.check(not d.led, "a body's lure (no Wisp cast) does not lead him")
	_done(s)


## Bolting, a fright on him does not stop him: not indoors, not off his run.
static func _bolt_fear(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	d._start_bolt(true)
	d.charge.panic(d.charge.ground_pos + Vector2(1.0, 0.0), 2.0)
	t.check(d.charge.mind == Person.Mind.DUTY and not d.charge.inside, "a fright on a running acolyte takes at once: he is still on duty, not sheltering")
	_run(s, EscortDirector.TICK * 2.0)
	t.check(d.charge.mind == Person.Mind.DUTY and not d.charge.inside and d.charge.anchor.distance_to(d.exit_at) < 0.5,
		"and a look later: still on duty for the way out")
	_done(s)
	# Not bolting, the same fright moves him off his duty, as before.
	s = _world()
	d = s.d
	_clear_watchers(d)
	d.charge.panic(d.charge.ground_pos + Vector2(1.0, 0.0), 2.0)
	t.check(d.charge.mind != Person.Mind.DUTY or d.charge.inside, "a fright on him before he bolts still moves him off his duty")
	_done(s)
	# A frightened acolyte: the bolt takes him from his fright at once.
	s = _world()
	d = s.d
	_clear_watchers(d)
	d.charge.panic(d.charge.ground_pos + Vector2(1.0, 0.0), 2.0)
	t.check(not d.charge.inside, "a fright in the open does not shelter him in this world (so the next case always asserts)")
	d._start_bolt(true)
	t.check(d.charge.mind == Person.Mind.DUTY and d.charge.anchor.distance_to(d.exit_at) < 0.5,
		"panicking when the bolt starts, he is sent on at once")
	_done(s)


## Bolting, seized, the seizer killed: he runs again at once.
static func _bolt_seized_freed(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	d._start_bolt(true)
	var p: Person = d.patrols[0][0]
	_arrive(p, d.charge.ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	_run(s, EscortDirector.TICK + DT)
	t.check(d.held and d.seizer == p and d.bolting and _labels(d).has("ACOLYTE - CAUGHT"), "bolting, he is seized as ever (caught, still bolting)")
	(s.crowd as Crowd)._field.kill(p, &"fire")
	_run(s, EscortDirector.TICK + DT)
	t.check(not d.held and d.bolting and d.charge.mind == Person.Mind.DUTY and d.charge.anchor.distance_to(d.exit_at) < 0.5
		and _labels(d).has("ACOLYTE - RUNNING"), "the seizer felled: bolting again at once, for the way out")
	_done(s)


## Set down on the exit with the outer watchman on his post: seized, not out (preflight 2: sight before the way out).
static func _fold_to_exit_seen(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	var outer: Person = d.watch[1]
	t.check(d.watch_posts[1].distance_to(d.exit_at) < 1.0 and d.watch_posts[1].y > d.gate_at.y, "the outer post stands just outside the gate, by the way out")
	_arrive(outer, d._walkable(d.watch_posts[1]))
	outer.mind = Person.Mind.POST
	_arrive(d.charge, d.exit_at + Vector2(0.0, -1.0))
	d._hold_at = d.charge.ground_pos
	_run(s, EscortDirector.TICK + DT)
	t.check(d.held and d.seizer == outer and not d.escaped and not (s.rules as Rules).won,
		"folded onto the way out with the outer watchman on post: seized, not out")
	_done(s)


## The watch away or drawn off: the same fold is out.
static func _fold_to_exit_clear(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	_arrive(d.charge, d.exit_at + Vector2(0.0, -1.0))
	d._hold_at = d.charge.ground_pos
	_run(s, EscortDirector.TICK + DT)
	t.check(d.escaped and not d.held and (s.rules as Rules).won, "the watch away: the same fold is out")
	_done(s)
	s = _world()
	d = s.d
	_clear_watchers(d)
	var outer: Person = d.watch[1]
	_arrive(outer, d._walkable(d.watch_posts[1]))
	outer.mind = Person.Mind.CONFUSED  # drawn off by Discord: he sees nothing
	_arrive(d.charge, d.exit_at + Vector2(0.0, -1.0))
	d._hold_at = d.charge.ground_pos
	_run(s, EscortDirector.TICK + DT)
	t.check(d.escaped and not d.held, "the outer watchman confused: out")
	_done(s)


## At 0:18 his tag counts down to the bolt.
static func _tag_countdown(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	_run(s, 18.2)
	t.check(_labels(d).has("ACOLYTE - BOLTS IN 0:42"), "at 0:18 his tag reads BOLTS IN 0:42 (%s)" % [_labels(d)])
	var edged := false
	for tag in d.tags():
		edged = edged or (tag.label.begins_with("ACOLYTE") and tag.edge)
	t.check(edged, "and it is pointed at from the screen's edge")
	_done(s)


## The bolt is never a wait over a minute, on the board's stretched clock too: the event falls at a mission minute of the night.
static func _bolt_is_a_minute(t) -> void:
	var s := _world(1.5)
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	t.check(is_equal_approx(d.bolt_left(), LostLambDirector.BOLT_AT) and LostLambDirector.BOLT_AT <= 60.0,
		"on a clock stretched 1.5 times he still shows a minute to his bolt (%.1f)" % d.bolt_left())
	_run(s, LostLambDirector.BOLT_AT - 1.0)
	t.check(not d.bolting, "and has not bolted at 0:59")
	_clear_watchers(d)
	_run(s, 2.0)
	t.check(d.bolting, "and bolts at the minute, not at 1:30")
	_done(s)


## Torn down, the director lets go of the signals it listened to for the bolt (a startle after the night is nothing to it).
static func _bolt_teardown(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var crowd: Crowd = s.crowd
	t.check(crowd.danger_landed.is_connected(d._on_danger) and crowd._field.enemy_killed.is_connected(d._on_killed)
		and crowd._env.structure_blighted.is_connected(d._on_blighted), "the director listens for a danger, a death and a blight")
	d.teardown()
	t.check(not crowd.danger_landed.is_connected(d._on_danger) and not crowd._field.enemy_killed.is_connected(d._on_killed)
		and not crowd._env.structure_blighted.is_connected(d._on_blighted), "and lets go of them at teardown")
	_done(s)


## Once the god has led him he never runs, so the hint stops saying he does: a `led` phase (and `running` only while he runs).
static func _led_hint(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	_clear_watchers(d)
	t.check(d.hint_phase() == "", "before anything: the mission's own line")
	d.charge.whisper(d.charge.ground_pos + Vector2(0.0, 2.0), MindWhisperFx.LINGER)
	_run(s, EscortDirector.TICK * 2.0)
	t.check(d.led and d.hint_phase() == "led", "led: the hint's phase is led (%s)" % d.hint_phase())
	_done(s)


## D25: Passage's Lamb policy flings a patrol into Aldermere's north-west pocket (the user ruled it fair), which has no way back to the streets. Pinned here, so an
## art round that opens the pocket shows up as this test and not as a Passage gate that loses for no clear reason.
static func _passage_dead_end(t) -> void:
	var s := _world()
	var d: LostLambDirector = s.d
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	var policy := preload("res://tools/dev/routes/god_t1/lamb.gd")
	var spot: Vector2 = policy._far_corner(d)
	t.check(City.current().id() == &"aldermere" and spot.distance_to(d._walkable(policy.FLING_TO)) < 0.01,
		"the policy sets the patrol down at its FLING_TO in Aldermere (%s)" % [spot])
	t.check(grid.path(spot, d.gate_at).is_empty() and grid.path(spot, LostLambDirector.GATE_MOUTH).is_empty(),
		"the Passage Lamb policy depends on a dead end (D25): a soldier set down at %s has no path to the gate mouth; if the pocket was opened, the Passage "
		% [spot] + "gate loses because patrol 1 walks back, not because of the policy")
	_done(s)
