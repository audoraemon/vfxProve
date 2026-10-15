extends RefCounted
## v0.11 M5 The Sermon (mission spec §3, SermonDirector, MirasHouseDirector reused): a preacher at the south-west well holds his crowd
## rapt -- deaf to a whisper, past fear, on duty -- while he preaches; silenced (held, or dead) he frees them. Twelve listeners in four
## waves of three, the waiting ones held at their sources until their wave walks in on the chain. A listener whispered to the god's
## house goes in unseen, reads, and comes out a Believer who stands by the door; seen by a sentry he is turned away and reported, the
## relay passing over the fleeing. Sentries return and are relieved. Eight Believers win; too few left to turn, the Gaze or the sermon's
## end lose. The god's house only shakes. The evacuation passes them by (review focus 2); freed bodies are borne (review focus 4).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_house(t)
	_rapt(t)
	_silenced(t)
	_turned(t)
	_believe(t)
	_flock(t)
	_waves(t)
	_sentries(t)
	_relief(t)
	_evacuate(t)
	_tagged(t)
	_bell(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.sermon())


## Wave `w`'s listeners in `d`, untyped (v0.11 M5 tests).
static func _wave(d: SermonDirector, w: int) -> Array:
	var out := []
	for l: SermonDirector.Listener in d.listeners:
		if l.wave == w:
			out.append(l)
	return out


## Wave `w`'s listeners set down at their places on the ring (v0.11 M5 tests: headless people never walk).
static func _seat(d: SermonDirector, w: int) -> void:
	for l: SermonDirector.Listener in _wave(d, w):
		if MissionDirector._alive(l.man) and not (l.man as Person).inside:
			Kit.arrive(l.man as Person, l.spot)


## The preacher held by Discord (it never lifts headless) and his crowd's hold let go by hand, as it lapses (v0.11 M5 tests).
static func _silence(d: SermonDirector) -> void:
	(d.preacher as Person).confuse(60.0)
	for l: SermonDirector.Listener in d.listeners:
		if MissionDirector._alive(l.man):
			(l.man as Person)._shaken_left = 0.0


## Every Faithful who would see the god's door confused (v0.11 M5 tests, First Prayers' _blind(), the controller's ruling): the
## eight lay Faithful and the clergy are spread by rule and never move headless, so a test of an unwatched door must not depend on
## where they happen to stand.
static func _blind(d: SermonDirector) -> void:
	for f in d.watchers(d.door, MirasHouseDirector.SIGHT):
		f.confuse(60.0)


## The two sentries killed and freed, and anyone else who would see the door confused (v0.11 M5 tests).
static func _unwatch(s: Dictionary, d: SermonDirector) -> void:
	for st: SermonDirector.Sentry in d.sentries:
		if MissionDirector._alive(st.man):
			Kit.free_body(s, st.man)
	_blind(d)


static func _setup(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	t.check(d.house != null and RuinWish.fits(d.house, "house") and d.door.distance_to(d.pulpit) > SermonDirector.VOICE
		and d.house.damage_filter.is_valid() and d.house.center().distance_to(SermonDirector.HOUSE_SPOT) < 5.0,
		"the god's house: a dwelling by the west wall, beyond VOICE of the pulpit, its door reached by the street")
	var seen := {}
	var ok := d.listeners.size() == SermonDirector.WAVES * SermonDirector.WAVE
	for l: SermonDirector.Listener in d.listeners:
		var p := l.man as Person
		ok = ok and p != null and not seen.has(p) and p.mind == Person.Mind.DUTY and not d.faithful.has(p) \
			and p.anchor == (l.spot if l.wave == 0 else l.source)
		seen[p] = true
	t.check(ok and _wave(d, 3).size() == 3, "twelve listeners in four waves of three: the first walks in, the rest wait on duty at their sources")
	var pr := d.preacher as Person
	var near := true
	for a: Variant in d.acolytes:
		var gap := (a as Person).ground_pos.distance_to(pr.ground_pos)
		near = near and (a as Person).profile.role == CitizenProfile.Role.CLERGY and gap > SilentDoom.RADIUS and gap <= DiscordFx.DISCORD_R + 0.05
	t.check(pr.profile.role == CitizenProfile.Role.CLERGY and pr.mind == Person.Mind.DUTY and pr.ground_pos.distance_to(d.pulpit) < 0.1
		and d.preaching() and d.acolytes.size() == 2 and near and d.faithful.has(pr),
		"the preacher, a cleric, preaches at the well; his two acolytes beside him, within one Discord, beyond one Doom")
	var posted := d.sentries.size() == SermonDirector.SENTRIES
	for st: SermonDirector.Sentry in d.sentries:
		var p := st.man as Person
		posted = posted and p.profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p) and p.mind == Person.Mind.DUTY \
			and p.ground_pos.distance_to(st.post) < 0.1 and p.ground_pos.distance_to(d.door) <= MirasHouseDirector.SIGHT
	posted = posted and (d.sentries[0].man as Person).ground_pos.distance_to((d.sentries[1].man as Person).ground_pos) > Crowd.DOOM_WITNESS
	t.check(posted, "two sentries, Faithful watchmen, each seeing the door, beyond one witness of each other")
	var lay := 0
	for f in d.faithful:
		lay += 1 if f.profile.role != CitizenProfile.Role.CLERGY and f.profile.role != CitizenProfile.Role.WATCHMAN else 0
	t.check(lay == SermonDirector.FAITHFUL_LAY, "every cleric and eight lay of the rest are Faithful (%d lay)" % lay)
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["wave_1", "wave_2", "wave_3", "ends"], "the strip: three waves, then the sermon's end (%s)" % [ids])
	var cam := SermonDirector.CAMERA_AT
	var clear := Kit.clear_of_stack(d.pulpit, cam, Kit.STACK) and Kit.clear_of_stack(d.door, cam, Kit.STACK) \
		and Kit.clear_of_stack(d.temple_door, cam, Kit.STACK)
	for w in range(1, SermonDirector.WAVES):
		clear = clear and Kit.clear_of_stack(d._wave_source(w), cam, Kit.STACK)
	t.check(clear, "the camera keeps the pulpit, the god's house, the Temple and the waves' sources (or their arrows) clear of the real HUD stack")
	var m := MissionBook.sermon()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and reasons == ["gaze", "sermon", "sermon_over"] and d.need == SermonDirector.NEED
		and is_equal_approx(d.read_seconds, SermonDirector.READ) and Array(m.default_loadout) == ["whisper", "discord", "doom", "wisp"]
		and MissionBook.get_mission("sermon").id == "sermon", "the mission: Tier 4's numbers; the Gaze, the crowd, the sermon's end (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := (d.preacher as Person).mind == Person.Mind.DUTY
	for l: SermonDirector.Listener in d.listeners:
		held = held and (l.man as Person).mind == Person.Mind.DUTY
	for st: SermonDirector.Sentry in d.sentries:
		held = held and (st.man as Person).mind == Person.Mind.DUTY
	for a: Variant in d.acolytes:
		held = held and (a as Person).mind == Person.Mind.DUTY
	t.check(held, "the regroup and the evacuation pass the preacher, his acolytes, his crowd and the sentries by (review focus 2)")
	Kit.done(s)


static func _house(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var hp := d.house.hp
	d.house.damage(60.0, d.house.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(d.house, 0.5)
	Kit.run_for(s, 0.1)
	t.check(is_equal_approx(d.house.hp, hp) and not d.house.destroyed and not (s.crowd as Crowd).fires.is_burning(d.house),
		"the god's house only shakes tonight, and its fire is put out (review focus 6)")
	var house := d.house
	d.teardown()
	t.check(not house.damage_filter.is_valid(), "teardown lets it go: it takes blows again")
	Kit.done(s)


static func _rapt(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.6)
	var all := true
	for l: SermonDirector.Listener in _wave(d, 0):
		var p := l.man as Person
		all = all and d.rapt(p) and p.shaken() and p.fearless_left > 0.0 and p.mind == Person.Mind.DUTY \
			and not p.whisper(d.door, MindWhisperFx.LINGER)
	var w: SermonDirector.Listener = _wave(d, 1)[0]
	var wp := w.man as Person
	t.check(all, "within VOICE of the preaching preacher his crowd is rapt: deaf, fearless, on duty")
	t.check(not d.rapt(wp) and wp.shaken() and wp.mind == Person.Mind.DUTY and wp.anchor == w.source,
		"a waiting wave is held deaf at its source too: nothing is done with it before it walks in (plan decision 183)")
	d._on_refused(0, "shaken")
	t.check((s.banners as Array).has("THEY HEAR ONLY HIM"), "a whisper refused while they are rapt: THEY HEAR ONLY HIM")
	Kit.done(s)


static func _silenced(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.6)
	var p := (_wave(d, 0)[0] as SermonDirector.Listener).man as Person
	var pr := d.preacher as Person
	pr.confuse(5.0)
	p._shaken_left = 0.0
	Kit.run_for(s, 0.6)
	t.check(not d.preaching() and not d.rapt(p) and not p.shaken(), "a confused preacher is silent: his crowd's hold lapses")
	pr._come_to()
	Kit.run_for(s, 1.2)
	t.check(d.preaching() and d.rapt(p) and p.shaken() and (s.banners as Array).has("THE PREACHER TAKES UP HIS SERMON"),
		"back on his feet he preaches again, and holds them again")
	Kit.free_body(s, pr)
	Kit.run_for(s, 0.1)
	t.check(not d.preaching() and (s.banners as Array).has("THE PREACHER IS SILENT") and d.reports_started >= 1,
		"killed, he is silent for good; his acolytes saw it and run to the Temple")
	Kit.done(s)


static func _turned(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.1)
	_silence(d)
	var l: SermonDirector.Listener = _wave(d, 0)[0]
	var p := l.man as Person
	t.check(p.whisper(d.door, MindWhisperFx.LINGER), "(set-up) with the preacher silent he hears a whisper")
	Kit.arrive(p, d.door)
	Kit.run_for(s, 0.1)
	t.check(not p.inside and d._turned.has(p) and d.reports_started == 1 and (s.banners as Array).has("A FAITHFUL RUNS TO THE TEMPLE")
		and d.reports[0].skip.is_valid() and d.hint_phase() == "report",
		"a sentry sees him at the door: turned away, and a Faithful runs to the Temple, its relay passing over the fleeing")
	p._wake()
	Kit.run_for(s, 0.6)
	t.check(p.mind == Person.Mind.DUTY and p.anchor == l.spot, "turned away and back on his feet, he walks back to the pulpit")
	Kit.done(s)


static func _believe(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.1)
	_silence(d)
	_unwatch(s, d)
	var l: SermonDirector.Listener = _wave(d, 0)[0]
	var p := l.man as Person
	p.whisper(d.door, MindWhisperFx.LINGER)
	Kit.arrive(p, d.door)
	Kit.run_for(s, 0.1)
	t.check(p.inside, "unseen, he goes in to read")
	t.check(d._counted(l) and not d.spent(0), "(the chain) he counts as turned once inside, but the rest of his wave is still to turn")
	Kit.run_for(s, SermonDirector.READ + 0.2)
	t.check(d.believers.has(p) and not p.inside and p.mind == Person.Mind.DUTY and p.anchor == d._believer_spot(p)
		and (s.banners as Array).has("1 BELIEVE") and ((s.rules as Rules).objectives[1] as Objective).hud_text(s.rules) == "Turn the crowd 1 / 8",
		"READ later he comes out a Believer and stands on duty by the door; the HUD counts him")
	Kit.done(s)


static func _flock(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[1]
	var gone := 0
	for l: SermonDirector.Listener in d.listeners:
		if gone < 4 and l.wave > 0:
			Kit.free_body(s, l.man)
			gone += 1
	Kit.run_for(s, 0.1)
	t.check(d.lost_reason() == "" and main.check(s.rules) == Objective.Status.PENDING, "eight left to turn: the night goes on")
	Kit.free_body(s, (_wave(d, 3)[2] as SermonDirector.Listener).man)
	Kit.run_for(s, 0.1)
	t.check(d.lost_reason() == "flock" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "flock",
		"too few left to turn: lost at once, with its own reason")
	Kit.done(s)


## The chain (the controller's idle ruling): a wave is spent once each of its listeners believes, is dead, is gone or is inside
## reading -- the last one whispered in starts the next wave's CHAIN, not his walk out READ later.
static func _waves(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.1)
	_silence(d)
	_unwatch(s, d)
	var first: Array = _wave(d, 0)
	for k in 2:
		Kit.free_body(s, (first[k] as SermonDirector.Listener).man)
	var last := (first[2] as SermonDirector.Listener).man as Person
	last.whisper(d.door, MindWhisperFx.LINGER)
	Kit.arrive(last, d.door)
	Kit.run_for(s, 0.1)
	var shown := d.timeline.seconds_to("wave_1")
	t.check(last.inside and d.spent(0) and d.spent_at[0] >= 0.0 and shown <= SermonDirector.CHAIN + 0.1 and not d.called[1],
		"the first wave spent as its last goes in to read: the second chained, CHAIN on (%.1f)" % shown)
	Kit.run_for(s, SermonDirector.CHAIN + DT)
	var walking := true
	for l: SermonDirector.Listener in _wave(d, 1):
		walking = walking and (l.man as Person).anchor == l.spot and (l.man as Person).mind == Person.Mind.DUTY
	t.check(d.called[1] and walking and (s.banners as Array).has("MORE COME TO HEAR HIM"), "CHAIN later the second wave walks in, on duty")
	Kit.done(s)


static func _sentries(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var st: SermonDirector.Sentry = d.sentries[0]
	var dead: Variant = st.man
	Kit.free_body(s, dead)
	Kit.run_for(s, SermonDirector.RELIEF_AFTER + 1.0)
	var p: Variant = st.man
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p)
		and (p as Person).anchor == st.post and st.relief and d.reliefs == 1 and (s.banners as Array).has("A NEW SENTRY WATCHES THE GOD'S HOUSE"),
		"RELIEF_AFTER after a sentry falls, the nearest lay citizen with a way there is made a Faithful watchman and walks to his post")
	var other: SermonDirector.Sentry = d.sentries[1]
	var op := other.man as Person
	Kit.arrive(op, d.door + Vector2(0.0, 8.0))
	op.mind = Person.Mind.CALM
	Kit.run_for(s, SermonDirector.RETURN_AFTER + 1.0)
	t.check(op.mind == Person.Mind.DUTY and op.anchor == other.post, "one off his post and calm walks back RETURN_AFTER after he left")
	Kit.done(s)


## The reliefs copy The Crown's Bread's (the controller's ruling): one chosen once the town is running is stopped from the flight
## first, and with no one who can reach the post the search backs off, tried again RELIEF_AFTER later.
static func _relief(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	Kit.evacuate(s)
	var st: SermonDirector.Sentry = d.sentries[0]
	Kit.free_body(s, st.man)
	Kit.run_for(s, SermonDirector.RELIEF_AFTER + 1.0)
	var p: Variant = st.man
	t.check(st.relief and MissionDirector._alive(p) and (p as Person).mind == Person.Mind.DUTY and (p as Person).anchor == st.post,
		"a relief chosen while the town runs is stopped from the flight and walks to the post")
	Kit.done(s)
	s = _world()
	d = s.d
	for c in (s.crowd as Crowd).citizens:
		if c.profile != null and c.profile.faith == CitizenProfile.Faith.NONE:
			c.profile.faith = CitizenProfile.Faith.GRIEVING  # (set-up) no lay citizen left to send
	st = d.sentries[0]
	Kit.free_body(s, st.man)
	Kit.run_for(s, SermonDirector.RELIEF_AFTER + 1.0)
	t.check(d.reliefs == 0 and not MissionDirector._alive(st.man) and st.fallen < 2.0,
		"with no one to send the search backs off, tried again RELIEF_AFTER later (%.1f)" % st.fallen)
	Kit.done(s)


static func _evacuate(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.1)
	_silence(d)
	Kit.free_body(s, d.sentries[0].man)
	var b: SermonDirector.Sentry = d.sentries[1]
	var bp := b.man as Person
	Kit.arrive(bp, d.door + Vector2(0.0, 8.0))
	bp.mind = Person.Mind.RECOVER
	_blind(d)
	var first := (_wave(d, 0)[0] as SermonDirector.Listener).man as Person
	first.whisper(d.door, MindWhisperFx.LINGER)
	Kit.arrive(first, d.door)
	Kit.run_for(s, SermonDirector.READ + 0.3)
	var walker := (_wave(d, 0)[1] as SermonDirector.Listener).man as Person
	walker.whisper(d.door, MindWhisperFx.LINGER)
	var waiter := (_wave(d, 3)[0] as SermonDirector.Listener).man as Person
	waiter.confuse(60.0)
	t.check(d.believers.has(first), "(set-up) one Believer stands by the door")
	Kit.evacuate(s)
	t.check(bp.mind == Person.Mind.FLEE and walker._whisper_fled and waiter._reassured_fled,
		"(set-up) the evacuation sends the recovering sentry running, owes the whispered listener a flight, and a held waiting one a later one")
	Kit.run_for(s, 0.6)
	t.check(bp.mind == Person.Mind.DUTY and bp.anchor == b.post and not walker._whisper_fled and walker.mind == Person.Mind.WHISPERED
		and not waiter._reassured_fled and first.mind == Person.Mind.DUTY and not first.inside,
		"at the first look after it: the sentry kept from the flight and sent straight back; the whispered and the held owe none; the Believer stays")
	Kit.arrive(walker, d.door)
	Kit.run_for(s, 0.1)
	t.check(walker.inside, "the whispered listener reaches the door and goes in")
	waiter._come_to()
	Kit.run_for(s, 1.2)
	var waiting := true
	for l: SermonDirector.Listener in _wave(d, 3):
		waiting = waiting and (l.man as Person).mind == Person.Mind.DUTY and (l.man as Person).anchor == l.source
	t.check(bp.mind == Person.Mind.DUTY and waiting and first.mind == Person.Mind.DUTY and d.believers_outside() >= 1 and d.lost_reason() == "",
		"the waiting waves and the Believer stay; no listener is lost to the flight (review focus 2)")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.6)
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 3) == ["GOD'S HOUSE", "DOOR - WATCHED", "PREACHER"] and String(labels[3]).begins_with("NEXT WAVE ")
		and labels.has("SENTRY") and Kit.edged(d, "GOD'S HOUSE") and d.tags()[0].outline == d.house.footprint and d.hint_phase() == "rapt",
		"the god's house outlined and pointed at, its door watched, the preacher, the next wave's time; he preaches (%s)" % [labels])
	_silence(d)
	Kit.run_for(s, 0.1)
	t.check(Kit.labels(d).has("PREACHER - SILENT") and d.hint_phase() == "watched", "silent, grey; the sentries watch the door")
	_unwatch(s, d)
	Kit.run_for(s, SermonDirector.SEEN_SHOW + 0.1)
	t.check(Kit.labels(d)[1] == "DOOR - CLEAR" and d.hint_phase() == "",
		"no sentry: the door is clear, the mission's own line (once the bell's warning for their seen deaths has passed)")
	var stray: Person = null
	for f in d.faithful:
		if MissionDirector._alive(f) and not f.inside and not f.mind in MissionDirector.BLIND and not d._busy().has(f):
			stray = f
			break
	Kit.arrive(stray, d.door + Vector2(0.5, 0.0))
	var marked := false
	for m in d.tags():
		marked = marked or (m.at == stray.ground_pos and m.color == MirasHouseDirector.MARK_WATCHED and m.label == "")
	t.check(Kit.labels(d)[1] == "DOOR - WATCHED" and marked, "any other Faithful by the door watches it too, and is marked red (Mira's watchers)")
	stray.confuse(60.0)
	d._report(d.acolytes[0] as Person, d.temple_door)
	t.check(Kit.labels(d).has("TO THE TEMPLE") and Kit.labels(d).has("TEMPLE") and d.hint_phase() == "report", "a report runs: its runner and the Temple")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("The preacher at the south-west well.")
		and String(tour[1][1]).begins_with("The god's house."), "the tour: the preacher, the god's house, the Temple")
	t.check(ResultsScreen.ACT_TITLES.get("sermon") == "THE CROWD BELIEVES" and ResultsScreen.ACT_TITLES.get("sermon_over") == "THE SERMON ENDS"
		and ResultsScreen.ACT_TITLES.get("flock") == "THE FLOCK IS SCATTERED", "its results under its own keys")
	Kit.done(s)


## The bell's warning (the controller's ruling): a seen death raises the Gaze and the warning shows before the bell is called; once
## it is called, its own line, and the bellkeeper tagged red with an edge arrow.
static func _bell(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var crowd: Crowd = s.crowd
	_seat(d, 0)
	Kit.run_for(s, 0.6)
	t.check(d.hint_phase() == "rapt", "(set-up) he preaches")
	d.gaze.seen_death()
	Kit.run_for(s, 0.1)
	t.check(d.hint_phase() == "seen" and crowd.bell.state == BellNetwork.State.IDLE, "a seen death raises the Gaze: the bell's warning, before it is called")
	Kit.run_for(s, SermonDirector.SEEN_SHOW + 0.5)
	t.check(d.hint_phase() == "rapt", "SEEN_SHOW later the night's own phase again")
	var keeper := crowd.bell.keeper
	crowd.bell.state = BellNetwork.State.CALLED
	t.check(d.hint_phase() == "bell" and (keeper == null or (Kit.labels(d).has("BELLKEEPER") and Kit.edged(d, "BELLKEEPER"))),
		"the bell called: its line, and the bellkeeper tagged with an edge arrow")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var out: Array = [d.preacher] + d.acolytes
	for st: SermonDirector.Sentry in d.sentries:
		out.append(st.man)
	for l: SermonDirector.Listener in _wave(d, 0):
		out.append(l.man)
	for v: Variant in out:
		Kit.free_body(s, v)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(not d.preaching() and d.lost_reason() == "" and int(d.report().believers) == 0 and d.sentries_on_guard().is_empty(),
		"the preacher, his acolytes, the sentries and a wave freed: the tags, hint and report bear it (review focus 4)")
	Kit.done(s)
