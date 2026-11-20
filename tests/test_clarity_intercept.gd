extends RefCounted
## Mission clarity, the intercept group (spec 5.1; plan Task 5): The Warning and its acts (The Omen, The Long Night), the board's Starfall,
## The Bell-Ringers, Silence the Witness, The Festival and Market Panic, The Procession. Every verb a step or hint of these names is proved in
## a Kit world by casting it through the game's own entry points (ClarityKit.apply(); pre-flight B1, B2: never Person.panic(), never a scare
## on a soldier); every why-not banner is proved true by what the cast then does, and "" for the same cast far away; every director's
## why_not() is read-only; the new `{n}` readouts count what they say.
##
## cases() is the list of what was proved, as {"id", "phase", "verb"} rows: a proof adds a row for each mission and phase whose text it
## covers (a phase whose line is the mission's, or the same words, is proved once). The Herald phase's text is the Lantern's own on the
## plate (MissionSteps.HERALD, the how-to-win line), so its fallback rows ride on the proof of the phase it falls back to.

const ClarityKit := preload("res://tests/clarity_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")

const IDS := ["warning", "omen", "long_night", "bell_ringers", "silence_witness", "festival", "feast_festival", "market_panic", "procession",
	"feast_procession"]
## A point far from every target in every Kit world.
const FAR := Vector2(-60.0, 60.0)

static var _rows: Array = []


## What was proved: {"id", "phase", "verb"} rows (the coverage check reads them).
static func cases() -> Array:
	return _rows


static func run(t) -> void:
	_rows = []
	_warning(t)
	_starfall(t)
	_two_targets(t)
	_bell_ringers(t)
	_bell_mates(t)
	_bell_rope(t)
	_bell_keeper(t)
	_silence(t)
	_festival(t)
	_market_wardens(t)
	_market_crowd(t)
	_market_why(t)
	_procession(t)
	_real_powers(t)
	ClarityKit.check_coverage(t, PackedStringArray(IDS), _rows)


## `ok` checked, and when it holds the rows for each of `ids` in each of `phases` for `verb`.
static func _proved(t, ok: bool, msg: String, ids: Array, phases: Array, verb: String) -> void:
	t.check(ok, msg)
	if not ok:
		return
	for id in ids:
		for ph in phases:
			_rows.append({"id": id, "phase": ph, "verb": verb})


## Everyone out of doors but `keep` is moved clear of `at` by more than the witness distance, so a death there is unseen by all but them.
static func _isolate(s: Dictionary, at: Vector2, keep: Array) -> void:
	var crowd: Crowd = s.crowd
	var n := 0
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + 4.0:
				n += 1
				Kit.arrive(p, at + Vector2(Crowd.DOOM_WITNESS + 8.0, 0.0).rotated(float(n)))


static func _run(s: Dictionary, seconds: float) -> void:
	Kit.run_for(s, seconds)


## Each colour a step or hint of `ids` names in the phase the world is in is a tag the director draws now.
static func _colours(t, s: Dictionary, ids: Array) -> void:
	var d: MissionDirector = s.d
	for id in ids:
		for text in ClarityKit.texts(id, d.hint_phase()):
			ClarityKit.colours_ok(t, d, text, "%s/%s" % [id, d.hint_phase()])


## The why-not proof: `key` cast at `at` says `text`, and the same cast far from every target says nothing.
static func _says(t, d: MissionDirector, key: String, at: Vector2, text: String, label: String) -> void:
	t.check(d.why_not(key, at) == text, "%s: %s says '%s' (got '%s')" % [label, key, text, d.why_not(key, at)])
	t.check(d.why_not(key, FAR) == "", "%s: %s far away says nothing" % [label, key])


## Casts `verb` at `target` through ClarityKit.apply() and checks the banner the HUD would ask for (the Kit's scare runs the world past its
## impact, which can move the target indoors, so the question is asked as the cast is made: before the impact lands).
static func _says_verb(t, s: Dictionary, verb: String, target: Variant, text: String, label: String) -> String:
	var d: MissionDirector = s.d
	var key := String(ClarityKit.DEFAULT_KEY[verb])
	if verb == "scare":
		var kill_r := float(PowerBook.level_stat("smite", 1, "KILL_R", 0.6))
		_says(t, d, key, ClarityKit.point_of(target) + Vector2(kill_r + 0.5, 0.0), text, label)
	key = ClarityKit.apply(s, verb, target)
	if verb != "scare":
		_says(t, d, key, s.at, text, label)
	return key


# ---------------------------------------------------------------------------------------------------------------------
# The Warning, The Omen, The Long Night (the lone WarningDirector)

## A world for the campaign's Warning with its messenger running (the stare is over).
static func _warning_world() -> Dictionary:
	var s := ClarityKit.world(MissionBook.warning())
	_run(s, WarningDirector.OMEN_AT + WarningDirector.STARE + 0.3)
	return s


static func _warning(t) -> void:
	var all_phases: Array = ClarityKit.phases_of("long_night")
	# "" and herald: kill the messenger with no one near.
	var s := _warning_world()
	var d: WarningDirector = s.d
	var m := d.messenger
	_colours(t, s, ["warning", "omen"])
	ClarityKit.assert_read_only(t, s, "warning")
	_isolate(s, m.ground_pos, [m])
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	_proved(t, d.warning_dead and d.stopped_how == "kill", "warning: killed unseen, the messenger stops the warning", ["warning", "omen"],
		["", "herald"], "kill")
	_proved(t, d.warning_dead, "long_night: the same kill, in each act's phase", ["long_night"], all_phases, "kill")
	ClarityKit.done(s)
	# relay: a witness saw it; killing him unseen stops it.
	s = _warning_world()
	d = s.d
	m = d.messenger
	var witness: Person = null
	for p in (s.crowd as Crowd).citizens:
		if p != m and p != d.watchman and not p.inside and not p.is_child() and p != (s.crowd as Crowd).bell.keeper:
			witness = p
			break
	_isolate(s, m.ground_pos, [m, witness])
	Kit.arrive(witness, m.ground_pos + Vector2(1.0, 0.0))
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	t.check(d.relays == 1 and d.messenger == witness and d.hint_phase() == "relay", "warning: a seen kill passes the warning to the witness (relay)")
	_colours(t, s, ["warning", "omen"])
	_isolate(s, witness.ground_pos, [witness])
	ClarityKit.apply(s, "kill", witness)
	_run(s, 0.3)
	_proved(t, d.warning_dead and d.stopped_how == "kill", "warning: the witness killed unseen stops it", ["warning", "omen"], ["relay"], "kill")
	ClarityKit.done(s)
	# bell: delivered, the keeper climbs; killed unseen, it stops.
	s = _warning_world()
	d = s.d
	var keeper: Person = (s.crowd as Crowd).bell.keeper
	d.messenger.ground_pos = keeper.ground_pos + Vector2(0.3, 0.0)
	_run(s, 0.7)
	t.check(d.hint_phase() == "bell" and d.messenger == keeper, "warning: told, the keeper carries it (bell)")
	_colours(t, s, ["warning", "omen"])
	_isolate(s, keeper.ground_pos, [keeper])
	ClarityKit.apply(s, "kill", keeper)
	_run(s, 0.3)
	_proved(t, d.warning_dead and d.stopped_how == "kill", "warning: the ringer killed unseen stops it", ["warning", "omen"], ["bell"], "kill")
	ClarityKit.done(s)


# ---------------------------------------------------------------------------------------------------------------------
# The board's Starfall

## A world for the board's Warning with star `i` set up and, when `stared` is false, its stare over.
static func _star_world(i := 0, stared := false) -> Dictionary:
	var s := ClarityKit.world(TierBook.board("warning"))
	_star_up(s, i, stared)
	return s


static func _star_up(s: Dictionary, i: int, stared: bool) -> WarningDirector:
	var d: StarfallDirector = s.d
	d._clock = float(d.star_falls[i][0]) - WarningDirector.OMEN_AT - 0.05
	_run(s, 0.1)
	_run(s, WarningDirector.OMEN_AT + (0.5 if stared else WarningDirector.STARE + 0.2))
	return d.stars[i]


static func _starfall(t) -> void:
	# stars (the stare) and running: kill unseen, banish, calm.
	for stare in [true, false]:
		var phase := "stars" if stare else "running"
		var s := _star_world(0, stare)
		var d: StarfallDirector = s.d
		var w := d.stars[0]
		t.check(d.hint_phase() == phase, "starfall: the %s phase (%s)" % [phase, d.hint_phase()])
		_colours(t, s, ["warning"])
		if stare:
			ClarityKit.assert_read_only(t, s, "starfall")
		var m := w.messenger
		_isolate(s, m.ground_pos, [m])
		ClarityKit.apply(s, "kill", m)
		_run(s, 0.3)
		_proved(t, w.warning_dead and w.stopped_how == "kill", "starfall %s: killed unseen, the warning stops" % phase, ["warning"], [phase], "kill")
		ClarityKit.done(s)
		s = _star_world(0, stare)
		d = s.d
		w = d.stars[0]
		m = w.messenger
		ClarityKit.apply(s, "banish", m)
		_run(s, 0.2)
		_proved(t, w.warning_dead and w.stopped_how == "out", "starfall %s: set down outside the walls, it stops" % phase, ["warning"], [phase],
			"banish")
		ClarityKit.done(s)
		s = _star_world(0, stare)
		d = s.d
		w = d.stars[0]
		m = w.messenger
		ClarityKit.apply(s, "calm", m)
		var keeper: Person = (s.crowd as Crowd).bell.keeper
		m.ground_pos = keeper.ground_pos + Vector2(0.3, 0.0)
		_run(s, 5.0 if stare else 0.7)
		_proved(t, w.warning_dead and w.stopped_how == "lie", "starfall %s: told while the bell lies, he is sent home" % phase, ["warning"], [phase],
			"calm")
		ClarityKit.done(s)
	# The why-not: a fright, Discord, a whisper or a lure on the carrier only stops him; it is true. (The Main Gate's: the Postern's watchman
	# holds the postern's key, and a fright takes him out through it.)
	for verb in ["scare", "confuse", "lead", "lure"]:
		var s3 := _star_world(1, false)
		var w3 := (s3.d as StarfallDirector).stars[1]
		var m3 := w3.messenger
		_isolate(s3, m3.ground_pos, [m3])
		_says_verb(t, s3, verb, m3, WarningDirector.STOPS_BANNER, "starfall " + verb)
		_run(s3, 0.5)
		t.check(not w3.warning_dead and w3.messenger == m3, "starfall: the %s stops him, but he keeps the warning" % verb)
		ClarityKit.done(s3)
	var s4 := _star_world(0, false)
	var m4 := (s4.d as StarfallDirector).stars[0].messenger
	t.check((s4.d as StarfallDirector).stars[0].key_door() != Vector2.INF, "starfall: the postern's watchman holds its key")
	t.check(s4.d.why_not("smite", m4.ground_pos + Vector2(1.1, 0.0)) == "", "starfall: a fright on the postern's watchman may take him out: nothing")
	ClarityKit.done(s4)
	var s2 := _star_world(1, false)
	var d2: StarfallDirector = s2.d
	var m2 := d2.stars[1].messenger
	_isolate(s2, m2.ground_pos, [m2])
	# What counts says nothing: a kill in reach, a calm, a banish where the walls stop it.
	var at2 := m2.ground_pos
	t.check(d2.why_not("doom", at2) == "" and d2.why_not("belllies", at2) == "" and d2.why_not("skylift", at2) == "",
		"starfall: a kill, a calm and a banish on the carrier say nothing")
	t.check(d2.why_not("smite", at2) == "", "starfall: a Smite on him kills him: nothing")
	t.check(d2.why_not("smite", at2 + Vector2(Crowd._cast_radius("smite") + MissionDirector.WHY_MARGIN + 2.0, 0.0)) == "",
		"starfall: a Smite far away says nothing")
	ClarityKit.done(s2)


## Review focus 3: two warnings out at once; a cast that stops one says nothing though it frightens the other.
static func _two_targets(t) -> void:
	var s := _star_world(0, false)
	var d: StarfallDirector = s.d
	_star_up(s, 1, false)
	var m0 := d.stars[0].messenger
	var m1 := d.stars[1].messenger
	t.check(d.running() == d.stars[1] and not d.stars[0].warning_dead and not d.stars[1].warning_dead, "two warnings are out")
	_isolate(s, m0.ground_pos, [m0, m1])
	Kit.arrive(m1, m0.ground_pos + Vector2(1.1, 0.0))
	var at := m0.ground_pos
	ClarityKit.apply(s, "kill", m0, "smite")
	t.check(d.why_not("smite", at) == "", "two warnings: a Smite that kills one's carrier says nothing though it frightens the other's")
	ClarityKit.done(s)
	s = _star_world(0, false)
	d = s.d
	_star_up(s, 1, false)
	m0 = d.stars[0].messenger
	m1 = d.stars[1].messenger
	_isolate(s, m1.ground_pos, [m0, m1])
	Kit.arrive(m0, m1.ground_pos + Vector2(20.0, 0.0))
	ClarityKit.apply(s, "scare", m1)
	var text: String = d.why_not("smite", s.at)
	t.check(text == WarningDirector.STOPS_BANNER, "two warnings: a fright that reaches only one's carrier says why (%s)" % text)
	ClarityKit.done(s)


# ---------------------------------------------------------------------------------------------------------------------
# The Bell-Ringers

## A world for The Bell-Ringers with the north-east post's ringer set out and the pause over: his mates at his heels.
static func _ringers_world() -> Dictionary:
	var s := ClarityKit.world(MissionBook.bell_ringers())
	(s.d as BellRingersDirector)._send(0)
	_run(s, RingerDirector.OUT_PAUSE + 0.4)
	return s


static func _bell_ringers(t) -> void:
	# "": a ringer alone, killed unseen.
	var s := _ringers_world()
	var d: BellRingersDirector = s.d
	var r := d.ringers[0]
	var m := r.messenger
	t.check(r.mates.size() == RingerDirector.MATES and d.hint_phase() == "mates", "ringers: the ringer runs with his mates (mates, %s)" % d.hint_phase())
	_colours(t, s, ["bell_ringers"])
	ClarityKit.assert_read_only(t, s, "bell_ringers")
	_isolate(s, m.ground_pos, [m])
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	_proved(t, r.warning_dead and r.stopped_how == "kill", "ringers: a ringer killed with no one near stops his warning", ["bell_ringers"], ["", "herald"],
		"kill")
	ClarityKit.done(s)
	# mates: kill them first, then him.
	s = _ringers_world()
	d = s.d
	r = d.ringers[0]
	m = r.messenger
	for mate: Variant in r.mates:
		ClarityKit.apply(s, "kill", mate as Person)
	_isolate(s, m.ground_pos, [m])
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	_proved(t, r.warning_dead, "ringers: his mates killed first, he dies unseen", ["bell_ringers"], ["mates"], "kill")
	ClarityKit.done(s)
	# relay: a witness (an ordinary citizen) carries on; killed unseen, it stops.
	s = _ringers_world()
	d = s.d
	r = d.ringers[0]
	m = r.messenger
	var witness: Person = null
	for p in (s.crowd as Crowd).citizens:
		if p != m and not r.crew().has(p) and not p.inside and p.profile != null and not p.is_child() \
				and not d.claimed_besides(0).has(p):
			witness = p
			break
	_isolate(s, m.ground_pos, [m, witness])
	for mate: Variant in r.mates:
		Kit.arrive(mate as Person, m.ground_pos + Vector2(20.0, 0.0))
	Kit.arrive(witness, m.ground_pos + Vector2(1.0, 0.0))
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	t.check(r.relays == 1 and r.messenger == witness and d.hint_phase() == "relay", "ringers: a seen kill passes the warning on (relay, %s)" % d.hint_phase())
	_colours(t, s, ["bell_ringers"])
	_isolate(s, witness.ground_pos, [witness])
	ClarityKit.apply(s, "kill", witness)
	_run(s, 0.3)
	_proved(t, r.warning_dead, "ringers: the witness killed unseen stops it", ["bell_ringers"], ["relay"], "kill")
	ClarityKit.done(s)


## mates: Lead and Lure take them off the road -- they stand past the witness distance, and a kill then is unseen; a Discord does not (he
## still sees: the why-not). (People do not walk in a Kit world: a led or lured mate is set down where his goal is.)
static func _bell_mates(t) -> void:
	for verb in ["lead", "lure"]:
		var s := _ringers_world()
		var d: BellRingersDirector = s.d
		var r := d.ringers[0]
		var m := r.messenger
		var took := true
		var goals_ok := true
		for mate: Variant in r.mates:
			var p := mate as Person
			var away := (p.ground_pos - m.ground_pos).normalized()
			if verb == "lead":
				s["to"] = p.ground_pos + away * 6.0
			else:
				s["light"] = p.ground_pos + away * 1.5
			ClarityKit.apply(s, verb, p)
			took = took and s.took
			var goal := p.goal()
			goals_ok = goals_ok and goal != Vector2.INF and goal.distance_to(m.ground_pos) > Crowd.DOOM_WITNESS + 0.3
			Kit.arrive(p, goal)
		var keep: Array = [m]
		keep.append_array(r.mates)
		_isolate(s, m.ground_pos, keep)
		ClarityKit.apply(s, "kill", m)
		_run(s, 0.3)
		_proved(t, took and goals_ok and r.warning_dead, "ringers: his mates %s off (took %s, goals past sight %s), he dies unseen" % [verb, took, goals_ok],
			["bell_ringers"], ["mates"], verb)
		ClarityKit.done(s)
	# The why-not: a confused mate still sees; the ringer's death is carried on.
	var s := _ringers_world()
	var d: BellRingersDirector = s.d
	var r := d.ringers[0]
	var m := r.messenger
	var mate0: Person = r.mates[0]
	_isolate(s, m.ground_pos, [m, mate0])
	Kit.arrive(r.mates[1], m.ground_pos + Vector2(20.0, 0.0))
	ClarityKit.apply(s, "confuse", mate0)
	t.check(mate0.mind == Person.Mind.CONFUSED, "ringers: Discord confuses the mate")
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	t.check(r.relays == 1 and r.messenger == mate0, "ringers: the confused mate still saw him fall and runs on")
	ClarityKit.done(s)
	# The banner itself, on a mate alone.
	s = _ringers_world()
	d = s.d
	r = d.ringers[0]
	m = r.messenger
	var far_mate: Person = r.mates[0]
	Kit.arrive(far_mate, m.ground_pos + Vector2(2.6, 0.0))
	var at := far_mate.ground_pos + Vector2(0.4, 0.0)
	t.check(d.why_not("discord", at) == RingerDirector.MATE_SEES_BANNER, "ringers: Discord on a mate says he still sees (%s)" % d.why_not("discord", at))
	t.check(d.why_not("whisper", far_mate.ground_pos) == "" and d.why_not("doom", far_mate.ground_pos) == "",
		"ringers: a whisper or a kill on a mate says nothing")
	t.check(d.why_not("discord", FAR) == "", "ringers: Discord far away says nothing")
	t.check(d.why_not("discord", m.ground_pos) == WarningDirector.STOPS_BANNER, "ringers: Discord on the ringer himself says he keeps the warning")
	ClarityKit.done(s)
	# A Lead, a Lure or a fright on a mate standing at MATE_GAP also reaches the ringer 1.2 away: it counts (it holds the mate), so no banner.
	for verb in ["lead", "lure", "scare"]:
		s = _ringers_world()
		d = s.d
		r = d.ringers[0]
		m = r.messenger
		var mate: Person = r.mates[0]
		Kit.arrive(mate, m.ground_pos + Vector2(RingerDirector.MATE_GAP, 0.0))
		t.check(r.mates_with().has(mate) and mate.ground_pos.distance_to(m.ground_pos) < 1.5, "ringers: (set-up) a mate at MATE_GAP with him")
		var said := ClarityKit.apply_asked(s, verb, mate)
		t.check(said == "", "ringers: a %s on a mate at MATE_GAP says nothing (said '%s')" % [verb, said])
		ClarityKit.done(s)
	# A real whisper on the ringer himself picks him: the banner; on a mate beside him it picks the mate: none.
	s = _ringers_world()
	d = s.d
	r = d.ringers[0]
	m = r.messenger
	ClarityKit.apply(s, "lead", m)
	t.check(d.why_not("whisper", s.at) == WarningDirector.STOPS_BANNER, "ringers: a whisper on the ringer himself: he keeps the warning (%s)" % d.why_not("whisper", s.at))
	ClarityKit.done(s)
	s = _ringers_world()
	d = s.d
	r = d.ringers[0]
	m = r.messenger
	Kit.arrive(r.mates[0], m.ground_pos + Vector2(RingerDirector.MATE_GAP, 0.0))
	ClarityKit.apply(s, "lead", r.mates[0])
	t.check(d.why_not("whisper", s.at) == "", "ringers: a whisper on the mate beside him says nothing (%s)" % d.why_not("whisper", s.at))
	t.check(d.why_not("doom", m.ground_pos) == "" and d.why_not("smite", m.ground_pos) == "", "ringers: a kill on the ringer says nothing")
	ClarityKit.done(s)


## The carrier at the foot takes the rope and climbs (test_bell_ringers' own way: he is set down there, a bell step starts the climb).
static func _climb(r: RingerDirector, bell: BellNetwork) -> void:
	Kit.arrive(r.messenger, bell.foot)
	r.messenger.mind = Person.Mind.DUTY
	r.phase = WarningDirector.Phase.RUN
	r._run()
	Kit.arrive(r.messenger, bell.foot)
	bell.step(Kit.DT)


## climbing: Lead, scare and kill take him off the rope.
static func _bell_rope(t) -> void:
	for verb in ["kill", "lead", "scare"]:
		var s := ClarityKit.world(MissionBook.bell_ringers())
		var d: BellRingersDirector = s.d
		d._send(0)
		_run(s, RingerDirector.OUT_PAUSE + 0.4)
		var r := d.ringers[0]
		var m := r.messenger
		var bell: BellNetwork = (s.crowd as Crowd).bell
		_climb(r, bell)
		_run(s, 1.0)
		var on_rope := bell.state == BellNetwork.State.CLIMBING and bell.keeper == m and bell.progress > 0.0
		t.check(on_rope and r.hint_phase() == "climbing", "ringers: the ringer climbs (%s, %s, %s)" % [BellNetwork.State.keys()[bell.state], r.hint_phase(), bell.progress])
		if verb == "kill":
			_colours(t, s, ["bell_ringers"])
			_isolate(s, m.ground_pos, [m])
			ClarityKit.apply(s, "kill", m)
			_run(s, 0.3)
			_proved(t, r.warning_dead, "ringers: killed on the rope unseen, it stops", ["bell_ringers"], ["climbing"], "kill")
		else:
			var before := bell.progress
			var said := ClarityKit.apply_asked(s, verb, m)  # (asked as the cast is made: the cast that pulls him off the rope never banners)
			t.check(said == "", "ringers: a %s on the climbing ringer says nothing, it counts (said '%s')" % [verb, said])
			_run(s, 0.3)
			_proved(t, before > 0.0 and bell.state != BellNetwork.State.CLIMBING and bell.progress == 0.0,
				"ringers: a %s pulls him off the rope, the climb starts over (progress %s -> %s)" % [verb, before, bell.progress], ["bell_ringers"],
				["climbing"], verb)
		ClarityKit.done(s)


## bell: the town's own keeper is called; kill or hold him and the bell does not toll.
static func _bell_keeper(t) -> void:
	var results := {}
	for verb in ["none", "kill", "hold"]:
		var s := ClarityKit.world(MissionBook.bell_ringers())
		var d: BellRingersDirector = s.d
		var bell: BellNetwork = (s.crowd as Crowd).bell
		bell.call_keeper()
		_run(s, 0.5)
		t.check(d.called() and d.hint_phase() == "bell", "ringers: the town calls its keeper (bell, %s)" % d.hint_phase())
		if verb == "none":
			_colours(t, s, ["bell_ringers"])
			ClarityKit.assert_read_only(t, s, "bell_ringers (the keeper)")
		var keeper := bell.keeper
		Kit.arrive(keeper, bell.foot)  # (nobody walks in a Kit world: he is at the rope)
		_run(s, 0.3)
		if verb != "none":
			ClarityKit.apply(s, verb, keeper)
		_run(s, 35.0)
		results[verb] = bell.state
		if verb == "kill":
			_proved(t, bell.state != BellNetwork.State.RUNG, "ringers: the keeper killed, the bell does not toll", ["bell_ringers"], ["bell"], "kill")
		elif verb == "hold":
			_proved(t, bell.state != BellNetwork.State.RUNG, "ringers: the keeper held, the bell does not toll", ["bell_ringers"], ["bell"], "hold")
		ClarityKit.done(s)
	t.check(results["none"] == BellNetwork.State.RUNG, "ringers: left alone, the called keeper tolls the bell (%s)" % [BellNetwork.State.keys()[results["none"]]])


# ---------------------------------------------------------------------------------------------------------------------
# Silence the Witness

## A world for Silence the Witness with the west witness set out and standing at his door with his mates.
static func _witness_world() -> Dictionary:
	var s := ClarityKit.world(MissionBook.silence_witness())
	(s.d as SilenceWitnessDirector)._send(0)
	_run(s, SilenceWitnessDirector.SW_OUT_PAUSE + 0.3)
	return s


static func _silence(t) -> void:
	var s := _witness_world()
	var d: SilenceWitnessDirector = s.d
	var r := d.ringers[0] as WitnessDirector
	var m := r.messenger
	t.check(r.mates.size() == SilenceWitnessDirector.SW_MATES and r.hint_phase() == "", "silence: a witness and two mates walk (%s)" % r.hint_phase())
	_colours(t, s, ["silence_witness"])
	ClarityKit.assert_read_only(t, s, "silence_witness")
	# The banner for a fright on the carrier (the base's rule), and none for a mate: held mates are what count.
	t.check(d.why_not("discord", m.ground_pos) == WarningDirector.STOPS_BANNER, "silence: Discord on the witness says he keeps the warning")
	ClarityKit.done(s)
	# "": killed with his mates out of sight.
	s = _witness_world()
	d = s.d
	r = d.ringers[0] as WitnessDirector
	m = r.messenger
	_isolate(s, m.ground_pos, [m])
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	_proved(t, r.warning_dead, "silence: killed with no one near, the word dies", ["silence_witness"], ["", "near", "relay"], "kill")
	ClarityKit.done(s)
	# "": the control -- with his mates near and free, a mate carries it on; held first, it dies with him.
	s = _witness_world()
	d = s.d
	r = d.ringers[0] as WitnessDirector
	m = r.messenger
	var keep: Array = [m]
	keep.append_array(r.mates)
	_isolate(s, m.ground_pos, keep)
	for mate: Variant in r.mates:
		Kit.arrive(mate as Person, m.ground_pos + Vector2(1.0, 0.0))
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	var carried := r.relays == 1 and not r.warning_dead and d.hint_phase() == "relay"
	t.check(carried, "silence: a free mate saw him fall and runs on (relay, %s)" % d.hint_phase())
	if carried:
		_colours(t, s, ["silence_witness"])
		_isolate(s, r.messenger.ground_pos, [r.messenger])
		ClarityKit.apply(s, "kill", r.messenger)
		_run(s, 0.3)
		_proved(t, r.warning_dead, "silence: the mate killed too, the word dies", ["silence_witness"], ["relay"], "kill")
	ClarityKit.done(s)
	s = _witness_world()
	d = s.d
	r = d.ringers[0] as WitnessDirector
	m = r.messenger
	var keep2: Array = [m]
	keep2.append_array(r.mates)
	_isolate(s, m.ground_pos, keep2)
	var held := true
	for mate: Variant in r.mates:
		Kit.arrive(mate as Person, m.ground_pos + Vector2(1.0, 0.0))
		ClarityKit.apply(s, "hold", mate as Person)
		held = held and s.took
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	_proved(t, held and r.warning_dead, "silence: his mates held first, the word dies with him (held %s)" % held, ["silence_witness"], [""], "hold")
	ClarityKit.done(s)
	# near: the witness is at the Temple's door; kill or banish him.
	for verb in ["kill", "banish"]:
		s = _witness_world()
		d = s.d
		r = d.ringers[0] as WitnessDirector
		m = r.messenger
		var door := d.lantern_door()
		var spot: Vector2 = (s.crowd as Crowd)._grid.nearest_walkable(door + Vector2(0.0, 6.0))
		Kit.arrive(m, spot)
		_run(s, 0.6)
		t.check(r.hint_phase() == "near", "silence: the witness nears the Temple (%s, eta %s)" % [r.hint_phase(), r.eta()])
		_colours(t, s, ["silence_witness"])
		if verb == "kill":
			_isolate(s, m.ground_pos, [m])
		ClarityKit.apply(s, verb, m)
		_run(s, 0.4)
		_proved(t, r.warning_dead, "silence: near the Temple, %s stops him" % verb, ["silence_witness"], ["near"], verb)
		ClarityKit.done(s)


# ---------------------------------------------------------------------------------------------------------------------
# The Festival

static func _festival_def() -> MissionDef:
	var def := MissionBook.long_night().act("festival")
	def.night = NightState.new()
	return def


## A goer out of doors, still to break, standing clear of the others: where a cast of one's own is told apart from the crowd's.
static func _lone_goer(s: Dictionary, goers: Array, at: Vector2) -> Person:
	var best: Person = null
	for v: Variant in goers:
		var p := v as Person
		if is_instance_valid(p) and p.is_alive() and not p.inside:
			best = p
			break
	_isolate(s, at, [best])
	Kit.arrive(best, at)
	return best


static func _festival(t) -> void:
	var fountain := Places.at(&"fountain")
	for verb in ["scare", "kill"]:
		var s := ClarityKit.world(_festival_def())
		var d: FestivalDirector = s.d
		var p := _lone_goer(s, d.goers, fountain + Vector2(3.0, 0.0))
		t.check(d.hint_phase() == "" and d.hint_seconds() > 100.0, "festival: the square is open, the close in %s s" % d.hint_seconds())
		if verb == "scare":
			_colours(t, s, ["festival", "feast_festival"])
			ClarityKit.assert_read_only(t, s, "festival")
		var before := d.count()
		ClarityKit.apply(s, verb, p)
		_run(s, 0.3)
		_proved(t, d.count() == before + 1, "festival: a %s on a goer breaks him (%d -> %d)" % [verb, before, d.count()], ["festival", "feast_festival"],
			["", "packed"] if verb == "scare" else ["", "address"], verb)
		ClarityKit.done(s)
	# packed: the bonfire gathers them; one scare breaks the ones in reach (the hint's "one cast breaks many").
	var s2 := ClarityKit.world(_festival_def())
	var d2: FestivalDirector = s2.d
	d2.timeline.step(FestivalDirector.BONFIRE_AT + 1.0)
	t.check(d2.hint_phase() == "packed", "festival: the bonfire is lit (%s)" % d2.hint_phase())
	_colours(t, s2, ["festival", "feast_festival"])
	var crowd_at := fountain + Vector2(3.0, 0.0)
	var pack: Array = []
	for v: Variant in d2.goers:
		if pack.size() < 4 and is_instance_valid(v) and (v as Person).is_alive() and not (v as Person).inside:
			pack.append(v)
	_isolate(s2, crowd_at, pack)
	for i in pack.size():
		Kit.arrive(pack[i], crowd_at + Vector2(float(i) * 0.25, 0.0))
	var before2 := d2.count()
	ClarityKit.apply(s2, "scare", pack[0])
	_run(s2, 0.3)
	t.check(d2.count() >= before2 + 2, "festival: one scare in the packed crowd breaks several (%d -> %d)" % [before2, d2.count()])
	ClarityKit.done(s2)
	# address: the Mayor is killed; the crowd round the fountain panics.
	s2 = ClarityKit.world(_festival_def())
	d2 = s2.d
	t.check(WarningDirector._alive(d2.mayor), "festival: a Mayor is appointed")
	d2.timeline.step(FestivalDirector.ADDRESS_AT + 1.0)
	t.check(d2.hint_phase() == "address", "festival: the Mayor speaks (%s)" % d2.hint_phase())
	_colours(t, s2, ["festival", "feast_festival"])
	var near: Array = []
	for v: Variant in d2.goers:
		if near.size() < 5 and is_instance_valid(v) and (v as Person).is_alive() and not (v as Person).inside:
			near.append(v)
	for i in near.size():
		Kit.arrive(near[i], fountain + Vector2(1.5 + float(i) * 0.3, -1.0))
	var before3 := d2.count()
	ClarityKit.apply(s2, "kill", d2.mayor)
	_run(s2, 0.3)
	_proved(t, d2.count() >= before3 + near.size(), "festival: the Mayor's death panics the crowd round the fountain (%d -> %d)" % [before3, d2.count()],
		["festival", "feast_festival"], ["address"], "kill")
	ClarityKit.done(s2)
	# why-not: Lead, Lure and Confuse move a goer and break none.
	var s := ClarityKit.world(_festival_def())
	var d: FestivalDirector = s.d
	var p := _lone_goer(s, d.goers, fountain + Vector2(3.0, 0.0))
	for verb in ["lead", "lure", "confuse"]:
		var before := d.count()
		var key := ClarityKit.apply(s, verb, p)
		var at: Vector2 = s.at
		t.check(d.why_not(key, at) == FestivalDirector.GOERS_BANNER and d.why_not(key, FAR) == "",
			"festival: %s on a goer says only fear or death breaks them (%s)" % [verb, d.why_not(key, at)])
		_run(s, 0.3)
		t.check(d.count() == before, "festival: the %s broke no one" % verb)
	t.check(d.why_not("smite", p.ground_pos) == "" and d.why_not("doom", p.ground_pos) == "",
		"festival: a kill or a fright on a goer says nothing")
	ClarityKit.done(s)
	# the countdown: the seconds to the close, rounded up by the hint.
	s = ClarityKit.world(_festival_def())
	d = s.d
	d.timeline.step(30.0)
	t.check(is_equal_approx(d.hint_seconds(), FestivalDirector.CLOSE_AT - 30.0) and d.step_seconds() == d.hint_seconds(),
		"festival: the countdown reads the close (%s)" % d.hint_seconds())
	d.timeline.step(200.0)
	t.check(d.hint_seconds() == 0.0, "festival: nothing counts once the square is closed")
	ClarityKit.done(s)
	t.check(MissionHints.filled(MissionHints.line("festival"), 119.2).contains("in 120 s."), "festival: the hint fills the seconds")


# ---------------------------------------------------------------------------------------------------------------------
# Market Panic

## A world for Market Panic, a moment on (the wardens are fearless once the first look has passed); with `wardens_down`, every warden set
## down far from his post, off guard (a kill would frighten the first crowd and break it).
static func _market_world(wardens_down: bool) -> Dictionary:
	var s := ClarityKit.world(MissionBook.market_panic())
	_run(s, 0.6)
	if wardens_down:
		var d: MarketPanicDirector = s.d
		for w in d.wards:
			if w.man != null and WarningDirector._alive(w.man):
				Kit.arrive(w.man as Person, w.post + Vector2(30.0, 0.0))
		_run(s, 0.1)
	return s


## Wardens: Kill, Lead, Confuse take one off his post; a Scare does nothing to him.
static func _market_wardens(t) -> void:
	for verb in ["kill", "lead", "confuse"]:
		var s := _market_world(false)
		var d: MarketPanicDirector = s.d
		t.check(d.on_guard().size() == MarketPanicDirector.WARDENS and d.hint_phase() == "", "market: three wardens stand (%s)" % d.hint_phase())
		if verb == "kill":
			_colours(t, s, ["market_panic"])
			ClarityKit.assert_read_only(t, s, "market_panic")
		var w := d.on_guard()[0]
		ClarityKit.apply(s, verb, w)
		_run(s, 0.3)
		_proved(t, d.on_guard().size() == MarketPanicDirector.WARDENS - 1, "market: a %s takes a warden off guard (%d)" % [verb, d.on_guard().size()],
			["market_panic"], ["", "steadied"], verb)
		_run(s, 0.1)
		if verb == "kill":
			# Two stand: steadied.
			t.check(d.hint_phase() == "steadied", "market: some but not all wardens stand (%s)" % d.hint_phase())
			_colours(t, s, ["market_panic"])
		ClarityKit.done(s)
	# A scare does nothing to a warden on guard (fearless): he stays.
	var s2 := _market_world(false)
	var d2: MarketPanicDirector = s2.d
	var w2 := d2.on_guard()[0]
	ClarityKit.apply(s2, "scare", w2)
	_run(s2, 0.3)
	t.check(d2.on_guard().size() == MarketPanicDirector.WARDENS and w2.mind != Person.Mind.PANIC, "market: a fright does nothing to a warden on guard")
	ClarityKit.done(s2)


## Goers: with the wardens down, a scare breaks them; open and coming.
static func _market_crowd(t) -> void:
	var s := _market_world(true)
	var d: MarketPanicDirector = s.d
	t.check(d.on_guard().is_empty() and d.hint_phase() == "open", "market: no warden stands (%s)" % d.hint_phase())
	_colours(t, s, ["market_panic"])
	var p := d.unbroken()[0]
	_isolate(s, p.ground_pos, [p])
	var before := d.count()
	ClarityKit.apply(s, "scare", p)
	_run(s, 0.3)
	_proved(t, d.count() == before + 1, "market: a scare breaks a goer no warden steadies (%d -> %d)" % [before, d.count()], ["market_panic"],
		["", "steadied", "open"], "scare")
	ClarityKit.done(s)
	# coming: a later crowd walks in; scare one on the way.
	s = _market_world(true)
	d = s.d
	d._send_wave(1)
	_run(s, 1.0)
	t.check(d.hint_phase() == "coming", "market: the next crowd walks in (%s)" % d.hint_phase())
	_colours(t, s, ["market_panic"])
	var q: Person = null
	for v: Variant in d.waves[1]:
		if WarningDirector._alive(v) and not (v as Person).inside and not d._broke.has(v):
			q = v as Person
			break
	_isolate(s, q.ground_pos, [q])
	var before2 := d.count()
	ClarityKit.apply(s, "scare", q)
	_run(s, 0.3)
	_proved(t, d.count() == before2 + 1, "market: a scare breaks one on the way (%d -> %d)" % [before2, d.count()], ["market_panic"], ["coming"], "scare")
	ClarityKit.done(s)


## The three banners.
static func _market_why(t) -> void:
	# The warden stands fast: a fright on a warden on guard.
	var s := _market_world(false)
	var d: MarketPanicDirector = s.d
	var w := d.on_guard()[0]
	for other in d.on_guard():
		if other != w:
			Kit.arrive(other, other.ground_pos + Vector2(30.0, 0.0))
	_isolate(s, w.ground_pos, [w])  # no goer by the cast: a bolt that lands on a goer breaks him, and that counts
	_says_verb(t, s, "scare", w, MarketPanicDirector.STANDS_BANNER, "market (scare on a warden)")
	_run(s, 0.3)
	t.check(d.on_guard().has(w) and w.mind != Person.Mind.PANIC, "market: the fright left the warden on guard")
	t.check(d.why_not("doom", w.ground_pos) == "" and d.why_not("whisper", w.ground_pos) == "" and d.why_not("discord", w.ground_pos) == "",
		"market: a kill, a whisper or Discord on a warden says nothing")
	ClarityKit.done(s)
	# A lure on a lone warden at his post: the light is near, he stares at it and stays; a far light draws him off.
	s = _market_world(false)
	d = s.d
	var keep := d.on_guard()[0]
	for other in d.on_guard():
		if other != keep:
			Kit.arrive(other, other.ground_pos + Vector2(30.0, 0.0))
	_run(s, 0.1)
	s["light"] = keep.ground_pos + Vector2(1.5, 0.0)
	var lure_key := ClarityKit.apply(s, "lure", keep)
	t.check(s.took and d.on_guard().has(keep) and d.why_not(lure_key, s.at) == MarketPanicDirector.STANDS_BANNER,
		"market: a lure to a light beside his post draws him no further, and says so (took %s)" % s.took)
	ClarityKit.done(s)
	s = _market_world(false)
	d = s.d
	keep = d.on_guard()[0]
	for other in d.on_guard():
		if other != keep:
			Kit.arrive(other, other.ground_pos + Vector2(30.0, 0.0))
	_run(s, 0.1)
	var far_light := keep.ground_pos + Vector2(HarvestDirector.GUARD_REACH + 1.5, 0.0)
	t.check(d.why_not("wisp", far_light) == "", "market: a lure to a light past his reach could draw him off: nothing")
	ClarityKit.done(s)
	# A warden steadies them: a fright landing only on goers a warden steadies.
	s = _market_world(false)
	d = s.d
	var w2 := d.on_guard()[0]
	var goer := d.unbroken()[0]
	_isolate(s, w2.ground_pos, [w2, goer])
	for other in d.on_guard():
		if other != w2:
			Kit.arrive(other, w2.ground_pos + Vector2(30.0, 0.0))
	Kit.arrive(goer, w2.ground_pos + Vector2(4.5, 0.0))
	_run(s, 0.6)
	t.check(d.steadied(goer) and not d.broken(), "market: the goer stands steadied by the warden")
	var before := d.count()
	_says_verb(t, s, "scare", goer, MarketPanicDirector.STEADIES_BANNER, "market (scare on a steadied goer)")
	t.check(d.count() == before, "market: the fright broke none of the steadied")
	ClarityKit.done(s)
	# Only fear or death breaks them: Lead, Lure and Confuse on a goer.
	s = _market_world(true)
	d = s.d
	var p := d.unbroken()[0]
	_isolate(s, p.ground_pos, [p])
	for verb in ["lead", "lure", "confuse"]:
		var k := ClarityKit.apply(s, verb, p)
		t.check(d.why_not(k, s.at) == FestivalDirector.GOERS_BANNER, "market: %s on a goer says only fear or death breaks them" % verb)
	t.check(d.why_not("smite", p.ground_pos) == "", "market: a scare on a goer no warden steadies says nothing")
	ClarityKit.done(s)


# ---------------------------------------------------------------------------------------------------------------------
# The Procession

static func _procession_world() -> Dictionary:
	var def := MissionBook.long_night().act("procession")
	def.night = NightState.new()
	return ClarityKit.world(def)


static func _procession(t) -> void:
	var ids := ["procession", "feast_procession"]
	# "": walking to the steps; kill him with no one near.
	var s := _procession_world()
	var d: ProcessionDirector = s.d
	var prince := d.prince
	t.check(d.hint_phase() == "" and not prince.inside, "procession: the Prince walks (%s)" % d.hint_phase())
	_colours(t, s, ids)
	ClarityKit.assert_read_only(t, s, "procession")
	_isolate(s, prince.ground_pos, [prince])
	ClarityKit.apply(s, "kill", prince)
	_run(s, 0.3)
	_proved(t, d.fallen() and d.unseen, "procession: killed with no one near, the town is leaderless", ids, [""], "kill")
	ClarityKit.done(s)
	# blessing: he holds at the steps for the blessing; the hint counts it down.
	s = _procession_world()
	d = s.d
	prince = d.prince
	d.leg = ProcessionDirector.STEPS_LEG
	Kit.arrive(prince, d.route[ProcessionDirector.STEPS_LEG])
	d.timeline.step(ProcessionDirector.BLESSING_AT + 5.0)
	t.check(d.hint_phase() == "blessing" and is_equal_approx(d.hint_seconds(), ProcessionDirector.BLESSING_SECONDS - 5.0),
		"procession: the blessing, %s s left (%s)" % [d.hint_seconds(), d.hint_phase()])
	t.check(d.step_seconds() == d.hint_seconds(), "procession: the task line counts the same seconds")
	_colours(t, s, ids)
	_isolate(s, prince.ground_pos, [prince])
	ClarityKit.apply(s, "kill", prince)
	_run(s, 0.3)
	_proved(t, d.fallen(), "procession: killed at the steps", ids, ["blessing"], "kill")
	ClarityKit.done(s)
	# dock: the ship docks at SHIP_AT; the hint counts down to it.
	s = _procession_world()
	d = s.d
	prince = d.prince
	d.leg = ProcessionDirector.DOCK_LEG
	Kit.arrive(prince, d.route[ProcessionDirector.DOCK_LEG])
	d.timeline.step(ProcessionDirector.SHIP_AT - 30.0)
	t.check(d.hint_phase() == "dock" and is_equal_approx(d.hint_seconds(), 30.0), "procession: the dock, %s s to the ship (%s)" % [d.hint_seconds(), d.hint_phase()])
	_colours(t, s, ids)
	_isolate(s, prince.ground_pos, [prince])
	ClarityKit.apply(s, "kill", prince)
	_run(s, 0.3)
	_proved(t, d.fallen(), "procession: killed at the dock", ids, ["dock"], "kill")
	ClarityKit.done(s)
	# why-not: a fright, Discord, a whisper or a lure only halts him.
	for verb in ["scare", "confuse", "lead", "lure"]:
		s = _procession_world()
		d = s.d
		prince = d.prince
		_isolate(s, prince.ground_pos, [prince])
		var key := ClarityKit.apply(s, verb, prince)
		_says(t, d, key, s.at, ProcessionDirector.HALTS_BANNER, "procession " + verb)
		_run(s, 1.0)
		t.check(d.under_way() and not d.fallen(), "procession: the %s only halts him" % verb)
		ClarityKit.done(s)
	s = _procession_world()
	d = s.d
	prince = d.prince
	t.check(d.why_not("doom", prince.ground_pos) == "" and d.why_not("smite", prince.ground_pos) == "" and d.why_not("skylift", prince.ground_pos) == "",
		"procession: a kill or a set-down outside on the Prince says nothing")
	ClarityKit.done(s)


# ---------------------------------------------------------------------------------------------------------------------
# The real powers (review R2): the verbs the copy promises through Lure, Confuse and Hold, cast as the game casts them -- Rules.cast() with the
# power's own effect -- on this group's targets, not through the person calls the Kit uses.

## An effect context for the world `s` (the layers an effect hangs its pieces on), made once.
static func _ctx(s: Dictionary) -> FxContext:
	if s.has("_fx_ctx"):
		return s["_fx_ctx"]
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.rules = s.rules
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.ground = Node2D.new()
	ctx.world = Node2D.new()
	ctx.overhead_back = Node2D.new()
	ctx.overhead = Node2D.new()
	ctx.distort = Node2D.new()
	s["_fx_ctx"] = ctx
	return ctx


## `key` cast at `at` through Rules.cast() with its own effect, then run for `seconds` (the effect and the world together).
static func _real_cast(s: Dictionary, key: String, at: Vector2, seconds := 1.0, extra := {}) -> FxTimeline:
	var rules: Rules = s.rules
	var ctx := _ctx(s)
	var slot := rules.loadout.find(key)
	if slot < 0:
		var l := rules.loadout
		l.append(key)
		rules.loadout = l
		var c := rules._cooldowns
		c.append(0.0)
		rules._cooldowns = c
		slot = l.size() - 1
	rules._cooldowns[slot] = 0.0
	rules._playing = null
	rules.caster = func(script: GDScript, g: Vector2, ex: Dictionary) -> FxTimeline: return FxTimeline.cast(script, ctx, g, ex)
	var fx := rules.cast(slot, at, extra)
	for i in roundi(seconds / 0.1):
		if is_instance_valid(fx) and not fx.finished:
			fx._process(0.1)
		_run(s, 0.1)
	return fx


static func _done(s: Dictionary) -> void:
	if s.has("_fx_ctx"):
		var ctx: FxContext = s["_fx_ctx"]
		for layer in [ctx.ground, ctx.world, ctx.overhead_back, ctx.overhead, ctx.distort]:
			if is_instance_valid(layer):
				(layer as Node).free()
	ClarityKit.done(s)


static func _real_powers(t) -> void:
	# Lure: a Will-o'-Wisp's light beside a mate draws him; at the light, beyond sight of the ringer, a kill is unseen.
	var s := _ringers_world()
	var d: BellRingersDirector = s.d
	var r := d.ringers[0]
	var m := r.messenger
	var p: Person = r.mates[0]
	var away := (p.ground_pos - m.ground_pos).normalized()
	var light := p.ground_pos + away * 1.5
	var fx := _real_cast(s, "wisp", light, 0.5)
	var drawn := p.lured() and p.goal() != Vector2.INF and p.goal().distance_to(m.ground_pos) > Crowd.DOOM_WITNESS
	t.check(fx != null and drawn, "real Wisp: its light beside a mate draws him past sight of the ringer (lured %s, goal %s)" % [p.lured(), p.goal()])
	var keep: Array = [m, p]
	_isolate(s, m.ground_pos, keep)
	Kit.arrive(r.mates[1], m.ground_pos + Vector2(20.0, 0.0))
	Kit.arrive(p, p.goal())
	ClarityKit.apply(s, "kill", m)
	_run(s, 0.3)
	t.check(r.warning_dead, "real Wisp: the ringer then dies unseen")
	_done(s)
	# Confuse: Discord on a warden takes him off guard.
	s = _market_world(false)
	var md: MarketPanicDirector = s.d
	var w := md.on_guard()[0]
	var n := md.on_guard().size()
	fx = _real_cast(s, "discord", w.ground_pos, 0.5)
	t.check(fx != null and w.mind == Person.Mind.CONFUSED and md.on_guard().size() == n - 1, "real Discord: a confused warden leaves guard (%d -> %d)" % [n, md.on_guard().size()])
	_done(s)
	# Hold: an Oath on the called bellkeeper stops his climb; on a witness's mates, they no longer see.
	s = ClarityKit.world(MissionBook.bell_ringers())
	d = s.d
	var bell: BellNetwork = (s.crowd as Crowd).bell
	bell.call_keeper()
	var keeper := bell.keeper
	Kit.arrive(keeper, bell.foot)
	_run(s, 0.5)
	t.check(bell.state == BellNetwork.State.CLIMBING, "the called keeper climbs")
	fx = _real_cast(s, "oath", keeper.ground_pos, 0.5)
	t.check(fx != null and keeper.mind == Person.Mind.COMPELLED and bell.state != BellNetwork.State.CLIMBING and bell.progress == 0.0,
		"real Oath: a held keeper is off the rope (%s)" % [BellNetwork.State.keys()[bell.state]])
	_done(s)
	s = _witness_world()
	var sd: SilenceWitnessDirector = s.d
	var wr := sd.ringers[0] as WitnessDirector
	var wm := wr.messenger
	var held := true
	for mate: Variant in wr.mates:
		Kit.arrive(mate as Person, wm.ground_pos + Vector2(1.0, 0.0))
	var keep2: Array = [wm]
	keep2.append_array(wr.mates)
	_isolate(s, wm.ground_pos, keep2)
	for mate: Variant in wr.mates:
		var mp := mate as Person
		_real_cast(s, "oath", mp.ground_pos, 0.2)
		held = held and mp.mind == Person.Mind.COMPELLED
	ClarityKit.apply(s, "kill", wm)
	_run(s, 0.3)
	t.check(held and wr.warning_dead, "real Oath: the witness's mates held (%s), the word dies with him" % held)
	_done(s)
