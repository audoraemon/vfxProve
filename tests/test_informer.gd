extends RefCounted
## v0.11 M3 The Informer (mission spec §3, InformerDirector, AssassinateDirector reused): four contacts kept at their houses' (quiet)
## doors, each with his company; the informer indoors in his lodging, untagged and untouchable; word reaches each contact at his
## visit (the next at its time, or CHAIN_WAIT after the one before is turned); a whisper on a contact with word, unseen -- held minds
## see nothing; a confused contact can be whispered -- turns him and names the next; the last names the hiding place and the
## informer runs for the Temple, hiding when alarmed (AssassinateDirector's rules, no guards). A contact dead (or gone from the town)
## before he is turned loses the night, and every contact's tag, the hint and the tour warn of it from the start (the controller's
## Task 4 rulings: all tagged, the one to work on bright and the others pale); the names reach the Temple FOUND_LIMIT after the last
## visit, before dawn, or when he gets in. Freed bodies are borne (review focus 4); the tags, hints, tour, titles, camera, numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_word(t)
	_turn(t)
	_seen(t)
	_found(t)
	_cold(t)
	_names(t)
	_warn(t)
	_tagged(t)
	_unwatched(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.informer())


## Moves everyone within sight of `c`'s contact well away, but those of `keep` (v0.11 M3 tests).
static func _clear(d: InformerDirector, c: InformerDirector.Contact, keep: Array = []) -> void:
	var man := c.man as Person
	for p in d.onlookers(c):
		if keep.has(p):
			continue
		var off := p.ground_pos - man.ground_pos
		Kit.arrive(p, man.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * 6.0)


## A Mind Whisper on `c`'s contact as the game casts it (v0.11 M3 tests): he hears it, then the cast is made where he stands.
static func _whisper(s: Dictionary, c: InformerDirector.Contact) -> void:
	var man := c.man as Person
	man.whisper(man.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
	(s.rules as Rules).cast_made.emit(0, "whisper", man.ground_pos)


## Word reaches every contact in turn, and each is turned unseen (v0.11 M3 tests).
static func _turn_all(s: Dictionary, d: InformerDirector) -> void:
	for i in d.contacts.size():
		d._visit(i)
		_clear(d, d.contacts[i])
		_whisper(s, d.contacts[i])


## The contacts' tags, in the order drawn (v0.11 M3 tests, the controller's Task 4 ruling): each one labelled "... DO NOT KILL".
static func _contact_tags(d: InformerDirector) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for m in d.tags():
		if m.label.ends_with("DO NOT KILL"):
			out.append(m)
	return out


static func _setup(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var crowd: Crowd = s.crowd
	var q := d.quarries[0]
	var seen := {}
	var houses := []
	var ok := d.contacts.size() == InformerDirector.CONTACT_SPOTS.size() and d.lodging != null \
		and d.hideout == d.contacts[d.contacts.size() - 1].house and q.guards.is_empty()
	for c in d.contacts:
		var man := c.man as Person
		houses.append(c.house)
		ok = ok and man.ground_pos.distance_to(c.door) < 0.1 and man.mind == Person.Mind.DUTY and c.company.size() == InformerDirector.COMPANY
		ok = ok and not seen.has(man) and man.profile.faith == CitizenProfile.Faith.NONE
		seen[man] = true
		for v: Variant in c.company:
			var p := v as Person
			ok = ok and p.ground_pos.distance_to(man.ground_pos) <= Crowd.DOOM_WITNESS and p.mind == Person.Mind.DUTY and not seen.has(p)
			seen[p] = true
	t.check(ok and seen.size() == 4 * (1 + InformerDirector.COMPANY) and not seen.has(q.target) and not houses.has(d.lodging),
		"four contacts at their doors with COMPANY each, all on duty there: %d lay citizens, five houses" % seen.size())
	t.check(q.target.inside and q.target.ground_pos == d.lodging.center() and q.state == AssassinateDirector.State.WAITING
		and not Kit.labels(d).has("INFORMER") and not Kit.labels(d).has("INFORMER - INSIDE"),
		"the informer waits indoors in his lodging, untouchable and untagged")
	crowd._regroup()
	crowd._evacuate()
	t.check((d.contacts[0].man as Person).mind == Person.Mind.DUTY and (d.contacts[0].company[0] as Person).mind == Person.Mind.DUTY
		and q.target.mind == Person.Mind.DUTY,
		"the town's regroup and evacuation pass the contacts, their company and the hidden informer by (review focus 6)")
	var ids := []
	for e in d.timeline.upcoming(5):
		ids.append(e.id)
	t.check(ids == ["visit_0", "visit_1", "visit_2", "visit_3", "names"] and Kit.labels(d)[0] == "NO WORD YET - DO NOT KILL"
		and float(InformerDirector.VISIT_AT[3]) + InformerDirector.FOUND_LIMIT < MissionBook.informer().clock,
		"the strip: four visits and the names' deadline, before dawn; the chandler's tag first (%s)" % [ids])
	var clear := Kit.clear_of_stack(d.safe_at, InformerDirector.CAMERA_AT)
	for c in d.contacts:
		clear = clear and Kit.clear_of_stack(c.door, InformerDirector.CAMERA_AT)
	t.check(clear, "the camera keeps the Temple and every contact (or his arrow) clear of the left HUD stack")
	var m := MissionBook.informer()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 2 and is_equal_approx(m.clock, 330.0) and m.dp_capacity == 8 and reasons == ["informer", "bell", "dawn"]
		and Array(m.default_loadout) == ["whisper", "discord", "doom"] and MissionBook.get_mission("informer").id == "informer",
		"the mission: Tier 2's numbers; the informer, the bell, dawn (%s)" % [reasons])
	Kit.done(s)


static func _word(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var c := d.contacts[0]
	_clear(d, c)
	_whisper(s, c)
	t.check(not c.turned and d.hint_phase() == "waiting", "before his visit a contact knows nothing: a whisper turns no one")
	Kit.run_for(s, float(InformerDirector.VISIT_AT[0]) + DT)
	t.check(c.word and (s.banners as Array).has("WORD REACHES THE CHANDLER") and d.hint_phase() == ""
		and Kit.labels(d)[0] == "CONTACT - DO NOT KILL" and Kit.edged(d, "CONTACT - DO NOT KILL"),
		"word reaches the chandler at his time: orange, pointed at")
	Kit.done(s)


static func _turn(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var c := d.contacts[0]
	d._visit(0)
	_clear(d, c)
	_whisper(s, c)
	var shown := d.timeline.seconds_to("visit_1")
	t.check(c.turned and d.contacts[1].known and (s.banners as Array).has("THE CHANDLER NAMES THE WEAVER")
		and shown <= InformerDirector.CHAIN_WAIT + 0.1 and d.hud_line() == "Find the informer: contacts turned 1 / %d" % d.contacts.size()
		and Kit.labels(d)[0] == "NO WORD YET - DO NOT KILL",
		"whispered unseen after his visit, the chandler names the weaver; the strip shows his visit within CHAIN_WAIT (%.1f s)" % shown)
	Kit.run_for(s, InformerDirector.CHAIN_WAIT + DT * 2.0)
	t.check(d.contacts[1].word and (s.banners as Array).has("WORD REACHES HIS SECOND CONTACT"), "CHAIN_WAIT after, word reaches the weaver")
	Kit.done(s)


static func _seen(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var c := d.contacts[0]
	d._visit(0)
	_clear(d, c, c.company)
	_whisper(s, c)
	t.check(not c.turned and not d.onlookers(c).is_empty() and (s.banners as Array).has(InformerDirector.SEEN_BANNER),
		"his company sees the whisper: he says nothing")
	for v: Variant in c.company:
		(v as Person).confuse(10.0)
	_whisper(s, c)
	t.check(c.turned, "held by Discord, his company sees nothing: the whisper turns him")
	Kit.done(s)
	var b := _world()
	var e: InformerDirector = b.d
	var k := e.contacts[0]
	e._visit(0)
	_clear(e, k)
	(k.man as Person).confuse(10.0)
	_whisper(b, k)
	t.check(k.turned, "a contact held by Discord himself can still be whispered, and turned (Decision 24)")
	Kit.done(b)
	# A whisper cast beside him -- on a companion at his elbow -- while an older whisper of his still holds him is not his own
	# (headless people never think, so the older whisper's linger is wound down by hand).
	var g := _world()
	var f: InformerDirector = g.d
	var o := f.contacts[0]
	f._visit(0)
	_clear(f, o)
	var held := o.man as Person
	held.whisper(held.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
	held._whisper_left = 3.0
	(g.rules as Rules).cast_made.emit(0, "whisper", held.ground_pos + Vector2(0.3, 0.0))
	t.check(not o.turned and not (g.banners as Array).has(InformerDirector.SEEN_BANNER),
		"a whisper beside him while an older one still holds him neither turns him nor reads as seen (pre-flight cosmetic 12)")
	Kit.done(g)


static func _found(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var rules: Rules = s.rules
	var q := d.quarries[0]
	_turn_all(s, d)
	t.check(d.found and q.state == AssassinateDirector.State.WALKING and not q.target.inside
		and q.target.ground_pos.distance_to(d.hide_door) < 0.1 and q.target.goal().distance_to(d.safe_at) < 0.6
		and (s.banners as Array).has("THE CARPENTER NAMES HIS HIDING PLACE") and (s.banners as Array).has("THE INFORMER IS FOUND"),
		"the carpenter names the hiding place: the informer bursts out of his house and runs for the Temple")
	var labels := Kit.labels(d)
	t.check(labels[0] == "INFORMER" and Kit.edged(d, "INFORMER") and labels.has("TEMPLE") and Kit.edged(d, "TEMPLE")
		and d.hint_phase() == "found" and rules.objectives[0].hud_text(rules) == "Kill the informer",
		"INFORMER and TEMPLE pointed at; the hint and the HUD on the kill (%s)" % [labels])
	d._alarm(q)
	t.check(q.state == AssassinateDirector.State.FLEEING and d.hint_phase() == "hiding"
		and rules.objectives[0].hud_text(rules) == "Kill the informer, he hides", "alarmed, he flees back to hide")
	(s.crowd as Crowd).fires.ignite(d.hideout, 0.6)
	t.check(d.fleeing_to_safe(q) and d.hint_phase() == "running"
		and rules.objectives[0].hud_text(rules) == "Kill the informer, he runs for the Temple", "his hiding place alight: he runs for the Temple")
	(s.crowd as Crowd)._field.kill(q.target, &"doom")
	Kit.run_for(s, DT * 2.0)
	t.check(rules.objectives[0].check(rules) == Objective.Status.DONE and ResultsScreen.title_for(true, "informer") == "THE INFORMER IS DEAD",
		"any death of his wins")
	Kit.done(s)


static func _cold(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	(s.crowd as Crowd)._field.kill(d.contacts[0].man as Person, &"doom")
	t.check(d.cold and d.lost_reason() == "cold" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "cold"
		and (s.banners as Array).has("THE TRAIL GOES COLD") and ResultsScreen.title_for(false, "cold") == "THE TRAIL GOES COLD"
		and d.tags().is_empty(), "a contact killed before he is turned takes the trail with him: lost (Decision 26)")
	Kit.done(s)
	# The ruling: the carpenter, not yet named, is tagged from the start, so his death loses the night too -- warned.
	var b := _world()
	var e: InformerDirector = b.d
	var carpenter := e.contacts[e.contacts.size() - 1].man as Person
	var warned := false
	for m in _contact_tags(e):
		warned = warned or m.at.distance_to(carpenter.ground_pos) < 0.01
	(b.crowd as Crowd)._field.kill(carpenter, &"doom")
	t.check(warned and e.cold and (b.rules as Rules).objectives[0].check(b.rules) == Objective.Status.FAILED,
		"the carpenter, tagged DO NOT KILL from the start though not yet named: his death loses the night too (the ruling)")
	Kit.done(b)
	# Gone from the town without a death (Crowd.escape(): his body freed at once), a contact takes the trail with him all the same:
	# the night is lost at once, not held until the names reach the Temple.
	var g := _world()
	var f: InformerDirector = g.d
	var crowd: Crowd = g.crowd
	var weaver := f.contacts[1].man as Person
	crowd._field.remove(weaver)
	crowd.escape(weaver)
	weaver.free()  # Crowd.escape() only queues the free: a headless test frees the body itself
	Kit.run_for(g, AssassinateDirector.TICK + DT)
	t.check(f.cold and (g.rules as Rules).objectives[0].check(g.rules) == Objective.Status.FAILED
		and (g.banners as Array).has("THE TRAIL GOES COLD") and f.tags().is_empty(),
		"a contact gone out of the town before he is turned: the trail goes cold at once")
	Kit.done(g)


static func _names(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	for i in d.contacts.size():
		d._visit(i)
	var shown := d.timeline.seconds_to("names")
	Kit.run_for(s, InformerDirector.FOUND_LIMIT - 1.0)
	var before := main.check(s.rules) == Objective.Status.PENDING
	Kit.run_for(s, 1.0 + DT * 2.0)
	t.check(absf(shown - InformerDirector.FOUND_LIMIT) < 0.1 and before and main.check(s.rules) == Objective.Status.FAILED
		and main.reason == "names" and (s.banners as Array).has("THE NAMES REACH THE TEMPLE")
		and ResultsScreen.title_for(false, "names") == "THE NAMES REACH THE TEMPLE",
		"not found FOUND_LIMIT after the last visit, the names reach the Temple (the strip counted it down from the visit)")
	Kit.done(s)
	var b := _world()
	var e: InformerDirector = b.d
	_turn_all(b, e)
	Kit.arrive(e.quarries[0].target, e.safe_at)
	Kit.run_for(b, AssassinateDirector.TICK + DT)
	var main_b: Objective = (b.rules as Rules).objectives[0]
	t.check(main_b.check(b.rules) == Objective.Status.FAILED and main_b.reason == "names", "found, he gets in at the Temple's door: the names are in")
	Kit.done(b)


static func _warn(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var stops := d.tour()
	t.check(MissionHints.line("informer").contains("Do not kill") and MissionHints.line("informer", "waiting").contains("Do not kill")
		and String(stops[0][1]).contains("do not kill him") and String(Kit.labels(d)[0]).contains("DO NOT KILL"),
		"the hint (from the first second), the tour and the contact's tag say plainly: turn him, do not kill him (ruling on Decision 26)")
	d._visit(0)
	t.check(Kit.labels(d)[0] == "CONTACT - DO NOT KILL", "and so does his tag once word has reached him")
	t.check(stops.size() == 2 and String(stops[0][1]) == "The chandler, first of the informer's four contacts. Word reaches him at %s. Turn him with a whisper: do not kill him." % UiTheme.clock(float(InformerDirector.VISIT_AT[0]))
		and String(stops[1][1]) == "The Temple. The informer takes your believers' names here.", "the tour (%s)" % [stops])
	var missing := []
	for phase: String in ["", "waiting", "found", "hiding", "running"]:
		var line := MissionHints.line("informer", phase)
		if line == "" or (phase != "" and line == MissionHints.line("informer")):
			missing.append(phase)
	t.check(missing.is_empty(), "a hint line for every phase (missing: %s)" % [missing])
	Kit.done(s)


## The controller's Task 4 rulings: all four contacts are tagged from the start -- the one to work on bright and pointed at from the
## edge (grey NO WORD YET before his visit, orange CONTACT once word has reached him), the others pale NO WORD YET, not pointed at;
## a turned contact loses his tag, and the next is the bright one.
static func _tagged(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var tags := _contact_tags(d)
	var on := tags.size() == 4 and tags[0].label == "NO WORD YET - DO NOT KILL" and tags[0].edge \
		and tags[0].color == InformerDirector.MARK_WAITING
	for i in tags.size():
		on = on and tags[i].at.distance_to((d.contacts[i].man as Person).ground_pos) < 0.01
		if i > 0:
			on = on and tags[i].label == "NO WORD YET - DO NOT KILL" and not tags[i].edge and tags[i].color == InformerDirector.MARK_PALE
	t.check(on, "from the start all four contacts are tagged DO NOT KILL: the chandler grey and pointed at, the other three pale")
	t.check(InformerDirector.MARK_PALE.a < InformerDirector.MARK_WAITING.a, "pale is fainter than the chandler's grey")
	d._visit(0)
	tags = _contact_tags(d)
	t.check(tags.size() == 4 and tags[0].label == "CONTACT - DO NOT KILL" and tags[0].color == AssassinateDirector.MARK_PLACE
		and tags[0].edge and tags[1].color == InformerDirector.MARK_PALE and tags[3].color == InformerDirector.MARK_PALE,
		"word at the chandler: his tag orange CONTACT; the others still pale NO WORD YET")
	_clear(d, d.contacts[0])
	_whisper(s, d.contacts[0])
	tags = _contact_tags(d)
	t.check(d.contacts[0].turned and tags.size() == 3
		and tags[0].at.distance_to((d.contacts[1].man as Person).ground_pos) < 0.01 and tags[0].edge
		and tags[0].color == InformerDirector.MARK_WAITING and tags[1].color == InformerDirector.MARK_PALE
		and tags[2].color == InformerDirector.MARK_PALE,
		"the chandler turned loses his tag; the weaver is the bright one, the potter and the carpenter still pale")
	Kit.done(s)


## The controller's Task 4 fix ruling (quiet doors): no contact's door is one a soldier's post watches -- a soldier hears no whisper
## and feels no Discord, so standing guard there he would see every whisper on the contact all night. A soldier posted by the
## chandler's door before the night begins sends the chandler to another house.
static func _unwatched(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var door := d.contacts[0].door
	var house := d.contacts[0].house
	var clear := true
	for c in d.contacts:
		clear = clear and not d._watched(c.door)
	Kit.done(s)
	var post := func(_e: MissionDirector, r: Rules) -> void:
		var g: Person = r._crowd.soldiers[0]
		g.post = door + Vector2(1.0, 0.0)
		g.anchor = g.post
		g.ground_pos = g.post
	var b := Kit.world(MissionBook.informer(), null, post)
	var e: InformerDirector = b.d
	t.check(clear and e.contacts[0].house != house and not e._watched(e.contacts[0].door)
		and e.contacts[0].door.distance_to(door) > InformerDirector.SPEAK_SEEN,
		"no contact's door is watched by a soldier's post; one posted by the chandler's door sends him to another house")
	Kit.done(b)


static func _freed(t) -> void:
	var s := _world()
	var d: InformerDirector = s.d
	var c := d.contacts[0]
	d._visit(0)
	Kit.free_body(s, c.company[0] as Person)
	Kit.run_for(s, AssassinateDirector.TICK * 2.0)
	t.check(not d.cold and Kit.labels(d)[0] == "CONTACT - DO NOT KILL" and d.hint_phase() == "",
		"a companion's body freed: no trail lost; the tags, the onlookers and the hint never touch it")
	_turn_all(s, d)
	var q := d.quarries[0]
	(s.crowd as Crowd)._field.kill(q.target, &"doom")
	Kit.run_for(s, DT * 2.0)
	Kit.free_body(s, q.target)
	Kit.run_for(s, DT * 2.0)
	t.check((s.rules as Rules).objectives[0].check(s.rules) == Objective.Status.DONE and d.tags().is_empty() and d.hint_phase() == ""
		and int(d.report().killed) == 1, "the informer's body freed after his death: still dead, untagged, the night won")
	Kit.done(s)
