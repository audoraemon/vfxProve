extends RefCounted
## Mission clarity, the escort group (Task 7; spec 5.3, pre-flight B1, B2, I4, I5, I6, I10, minor 4/5): The Lost Lamb, The Prisoner, Exodus,
## Hide the Faithful and Face Halcyon. Every verb a step or a hint of these five names has a case that lands the verb on the very target the
## copy names, through the game's own entry points (ClarityKit.apply(): Crowd.on_cast, Rules.cast, the person calls; the real power's own pick
## where it has one), and shows the mission's own rule counted it (the soldier or watchman no longer sees the charge, the captor lets him go,
## the stocks fall, the escort is no longer able). The why-nots each have a cast that lands and does not count, and one that counts and says
## nothing. Read-only checks, coverage, colours and the plate's fit close it.

const ClarityKit := preload("res://tests/clarity_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")

const DT := 0.05
const IDS := ["lost_lamb", "prisoner", "exodus", "hide_faithful", "face_halcyon"]
const LOOK := EscortDirector.TICK + DT

## The cases the coverage check reads: {"id", "phase", "verb"}.
static var _cases: Array = []


static func run(t) -> void:
	_cases = []
	_lamb(t)
	_lamb_why(t)
	_prisoner(t)
	_prisoner_why(t)
	_exodus(t)
	_hide(t)
	_face(t)
	_face_why(t)
	_seconds(t)
	_read_only(t)
	_colours(t)
	_texts(t)
	ClarityKit.check_coverage(t, PackedStringArray(IDS), _cases)


## A case: `ok` proves the verb counts in `phase` of `id`; it joins the cases the coverage check reads either way.
static func _case(t, id: String, phase: String, verb: String, ok: bool, label: String) -> void:
	t.check(ok, "%s/%s/%s: %s" % [id, phase, verb, label])
	_cases.append({"id": id, "phase": phase, "verb": verb})


# --- worlds -------------------------------------------------------------------------------------------------------------------------

static func _world(def: MissionDef) -> Dictionary:
	return ClarityKit.world(def)


## Everyone who watches for the charges moved well away: nobody sees them by chance.
static func _far(d: EscortDirector) -> void:
	var all: Array = d._watchers()
	all.append_array(d.hunters)
	if d is ExodusDirector:
		for h: ExodusDirector.Household in (d as ExodusDirector).households:
			all.append_array(h.searchers)
	if d is PrisonerDirector:
		all.append_array((d as PrisonerDirector).searchers)
	for v: Variant in all:
		if MissionDirector._alive(v) and not (v as Person).inside:
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))


## `who` stands `gap` from charge `c`, in the open.
static func _beside(who: Person, c: EscortDirector.Charge, gap := 1.0) -> void:
	Kit.arrive(who, (c.man as Person).ground_pos + Vector2(gap, 0.0))
	who.inside = false


## `verb` lands on `who`, a watcher standing beside charge `c` (every other watcher far): before it `who` sees the charge, after it he no
## longer does (EscortDirector._seen_by(): the rule that seizes). `s` is the world, whose d is the escort director.
static func _unsee(t, id: String, phase: String, verb: String, s: Dictionary, who: Person, c: EscortDirector.Charge, extra := "") -> void:
	var d: EscortDirector = s.d
	var before := d._seen_by(c) == who
	ClarityKit.apply(s, verb, who)
	var after := d._seen_by(c) != who
	_case(t, id, phase, verb, before and after and bool(s.get("took", true)), "%s lands on the watcher beside him: seen before %s, after %s%s" % [verb, before, not after, extra])
	ClarityKit.done(s)


## A seizer marches charge `c` (the one `by`); `verb` lands on him and the next look lets the charge go.
static func _release(t, id: String, phase: String, verb: String, s: Dictionary, by: Person, c: EscortDirector.Charge) -> void:
	var d: EscortDirector = s.d
	d._seize(c, by)
	var held: bool = c.held and c.seizer == by
	ClarityKit.apply(s, verb, by)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	_case(t, id, phase, verb, held and not c.held, "%s lands on his captor: held %s, then free %s" % [verb, held, not c.held])
	ClarityKit.done(s)


## A Lead lands on charge `c` and he is set walking: a whispered man with a goal where he was sent.
static func _walks(t, id: String, phase: String, s: Dictionary, c: EscortDirector.Charge, real_pick := true) -> void:
	var p := c.man as Person
	var to := p.ground_pos + Vector2(2.0, 0.0)
	s["to"] = to
	var picked := (MindWhisperFx.pick(s.field, p.ground_pos) == p) if real_pick else true
	ClarityKit.apply(s, "lead", p)
	_case(t, id, phase, "lead", picked and bool(s.took) and p.mind == Person.Mind.WHISPERED and p.goal().distance_to(to) < 0.6,
		"Mind Whisper takes him (picked %s) and he walks where sent (%s)" % [picked, p.goal()])
	ClarityKit.done(s)


# --- The Lost Lamb --------------------------------------------------------------------------------------------------------------------

static func _lamb_world() -> Dictionary:
	var s := _world(MissionBook.lost_lamb())
	var d: LostLambDirector = s.d
	Kit.run_for(s, 0.3)
	_far(d)
	return s


static func _lamb(t) -> void:
	var id := "lost_lamb"
	# "": Lead (a whisper), Lure (a Wisp's light within its draw) and Scare (a loud cast within BOLT_REACH makes him bolt) all count.
	var s := _lamb_world()
	var d: LostLambDirector = s.d
	t.check(d.hint_phase() == "" and not d.led and not d.bolting, "the Lamb starts in the empty phase, neither led nor bolting")
	var lamb := d.charge
	var to := lamb.ground_pos + Vector2(2.0, 0.0)
	s["to"] = to
	var picked: bool = MindWhisperFx.pick(s.field, lamb.ground_pos) == lamb
	ClarityKit.apply(s, "lead", lamb)
	Kit.run_for(s, LOOK)
	_case(t, id, "", "lead", picked and d.led and not d.bolting, "a whisper leads him (picked %s, led %s)" % [picked, d.led])
	ClarityKit.done(s)

	s = _lamb_world()
	d = s.d
	lamb = d.charge
	var light := lamb.ground_pos + Vector2(1.5, 0.0)
	s["light"] = light
	var drawn: Array[Person] = WillOWisp.drawn(s.field, light)
	ClarityKit.apply(s, "lure", lamb, "wisp")
	Kit.run_for(s, LOOK)
	_case(t, id, "", "lure", drawn.has(lamb) and bool(s.took) and d.led, "a Wisp's light draws him (drawn %s, took %s, led %s)" % [drawn.has(lamb), s.took, d.led])
	ClarityKit.done(s)

	s = _lamb_world()
	d = s.d
	var dist_before := d.bolt_left()
	ClarityKit.apply(s, "scare", d.charge)
	Kit.run_for(s, LOOK)
	_case(t, id, "", "scare", dist_before > 50.0 and d.bolting and not d.led, "a loud cast within BOLT_REACH sets him running (bolt in %.0f s, bolting %s)" % [dist_before, d.bolting])
	ClarityKit.done(s)

	# running: the patrols and the watch ahead of him -- Hold (a soldier held by the god sees nothing) and Kill.
	for verb in ["hold", "kill"]:
		s = _lamb_world()
		d = s.d
		d._start_bolt(false)
		t.check(d.hint_phase() == "running", "bolting, the Lamb's phase is running")
		var soldier: Person = d.patrols[0][0]
		_beside(soldier, d._first())
		_unsee(t, id, "running", verb, s, soldier, d._first())

	# led: Lead and Lure move him on.
	s = _lamb_world()
	d = s.d
	d._lead()
	t.check(d.hint_phase() == "led", "led, the Lamb's phase is led")
	_walks(t, id, "led", s, d._first())
	s = _lamb_world()
	d = s.d
	d._lead()
	lamb = d.charge
	light = lamb.ground_pos + Vector2(1.5, 0.0)
	s["light"] = light
	drawn = WillOWisp.drawn(s.field, light)
	ClarityKit.apply(s, "lure", lamb, "wisp")
	_case(t, id, "led", "lure", drawn.has(lamb) and bool(s.took) and lamb.mind == Person.Mind.OBSERVE and lamb.has_goal(), "a light draws him on (took %s)" % [s.took])
	ClarityKit.done(s)

	# caught: Hold or Kill the captor frees him (a captor off duty lets go).
	for verb in ["hold", "kill"]:
		s = _lamb_world()
		d = s.d
		var by: Person = d.patrols[0][0]
		_beside(by, d._first(), 0.5)
		_release(t, id, "caught", verb, s, by, d._first())

	# gate: the watch at the gate held -- the gate reads clear, and the change counts down.
	s = _lamb_world()
	d = s.d
	var gate_near := d.gate_at + Vector2(4.0, 0.0)
	Kit.arrive(d.charge, d._walkable(gate_near))
	Kit.run_for(s, LOOK)
	var posted: Array = []
	for v: Variant in d.watch:
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, d.watch_posts[posted.size() % d.watch_posts.size()])
			posted.append(v)
	var watched := d.hint_phase() == "gate" and d._gate_watched()
	var secs := d.hint_seconds()
	for v: Variant in posted:
		ClarityKit.apply(s, "hold", v)
	var cleared := not d._gate_watched() and d.hint_phase() == "clear"
	_case(t, id, "gate", "hold", watched and cleared and secs > 20.0 and secs <= EscortDirector.WATCH_CHANGE,
		"the watch held, the gate reads clear (gate %s, clear %s); the change counts %.1f s" % [watched, cleared, secs])
	ClarityKit.done(s)

	# clear: Lead him through.
	s = _lamb_world()
	d = s.d
	_walks(t, id, "clear", s, d._first())


static func _lamb_why(t) -> void:
	# caught: a lead or a lure on him does not free him -- the captor must go; a captor off duty, nothing to say.
	var s := _lamb_world()
	var d: LostLambDirector = s.d
	var by: Person = d.patrols[0][0]
	_beside(by, d._first(), 0.5)
	d._seize(d._first(), by)
	var at := d.charge.ground_pos
	var text := "HE IS HELD - FREE HIM FIRST"
	t.check(d.why_not("whisper", at) == text and d.why_not("wisp", at) == text and d.why_not("deathmark", at) == text,
		"a Lead or a Lure on the held acolyte says he is held")
	ClarityKit.apply(s, "lead", d.charge)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(d.held, "and it is true: the whisper left him held (%s)" % [d.held])
	t.check(d.why_not("smite", at + Vector2(9.0, 0.0)) == "" and d.why_not("doom", at) == "" and d.why_not("oath", at) == "",
		"a cast far from him, a kill or a hold of the captor say nothing")
	ClarityKit.apply(s, "hold", by)
	t.check(d.why_not("whisper", at) == "", "his captor held: a lead counts at the next look, nothing to say")
	ClarityKit.done(s)

	# A Wisp's light beyond WISP_HAND does not draw him; within it, it does.
	s = _lamb_world()
	d = s.d
	var lamb := d.charge
	var far := lamb.ground_pos + Vector2(LostLambDirector.WISP_HAND + 0.8, 0.0)
	var near := lamb.ground_pos + Vector2(LostLambDirector.WISP_HAND - 1.0, 0.0)
	t.check(d.why_not("wisp", far) == "TOO FAR - HE ANSWERS A NEAR LIGHT" and d.why_not("wisp", near) == "" and d.why_not("wisp", lamb.ground_pos) == "",
		"a Wisp beyond WISP_HAND of him says it is too far; within it, nothing")
	t.check(d.why_not("deathmark", far) == "" and d.why_not("windfall", far) == "" and d.why_not("smite", far) == "", "no banner for another lure or a blow")
	t.check(d.why_not("wisp", lamb.ground_pos + Vector2(40.0, 0.0)) == "", "a Wisp far from everything says nothing")
	ClarityKit.assert_read_only(t, s, "lost_lamb")
	ClarityKit._cast(s, "wisp", far, null)
	Kit.run_for(s, 1.0)
	var led_far := d.led
	ClarityKit.done(s)
	s = _lamb_world()
	d = s.d
	lamb = d.charge
	near = lamb.ground_pos + Vector2(LostLambDirector.WISP_HAND - 1.0, 0.0)
	ClarityKit._cast(s, "wisp", d._walkable(near), null)
	Kit.run_for(s, 1.0)
	t.check(not led_far and d.led, "and it is true: the far light leaves him unled (%s), the near one leads him (%s)" % [led_far, d.led])
	ClarityKit.done(s)


# --- The Prisoner ---------------------------------------------------------------------------------------------------------------------

static func _prisoner_world() -> Dictionary:
	var s := _world(MissionBook.prisoner())
	Kit.run_for(s, 0.3)
	return s


## The stocks brought down, then two looks: she is free.
static func _free_her(s: Dictionary) -> void:
	var d: PrisonerDirector = s.d
	d.stocks.destroy(d.stocks.center(), &"smite")
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)


## A free prisoner, every other watcher dead or far (`far`), her gaolers dead.
static func _free_world() -> Dictionary:
	var s := _prisoner_world()
	var d: PrisonerDirector = s.d
	for g: Variant in d.gaolers:
		if MissionDirector._alive(g):
			Kit.free_body(s, g)
	_free_her(s)
	_far(d)
	return s


static func _prisoner(t) -> void:
	var id := "prisoner"
	# "": free, she is led or drawn on.
	var s := _free_world()
	var d: PrisonerDirector = s.d
	t.check(not d.bound and d.hint_phase() == "" and d.charge.answers_lure, "freed, she moves by the god's hand: phase empty, answering a lure")
	_walks(t, id, "", s, d._first())
	s = _free_world()
	d = s.d
	var her := d.charge
	var light := her.ground_pos + Vector2(1.5, 0.0)
	s["light"] = light
	var drawn: Array[Person] = WillOWisp.drawn(s.field, light)
	ClarityKit.apply(s, "lure", her, "wisp")
	_case(t, id, "", "lure", drawn.has(her) and bool(s.took) and her.mind == Person.Mind.OBSERVE and her.has_goal(), "a light draws her (took %s)" % [s.took])
	ClarityKit.done(s)

	# bound: Kill, Lead or Confuse both gaolers and she is freed and not seized when the stocks fall; Burn or Strike the stocks and she is free.
	for verb in ["kill", "lead", "confuse"]:
		s = _prisoner_world()
		d = s.d
		var seen_by_gaoler := 0
		for g: Variant in d.gaolers:
			var gp := g as Person
			var real := true
			if verb == "lead":
				real = MindWhisperFx.pick(s.field, gp.ground_pos) == gp
			elif verb == "confuse":
				real = DiscordFx.taken(s.field, gp.ground_pos).has(gp)
			ClarityKit.apply(s, verb, gp)
			seen_by_gaoler += 0 if real else 1
		_far_but_gaolers(d)
		_free_her(s)
		var ok := not d.bound and not d.held and d.seizures == 0 and seen_by_gaoler == 0
		_case(t, id, "bound", verb, ok, "both gaolers %s, the stocks fall: she is free and unseized (seizures %d, held %s, real pick misses %d)" % [verb, d.seizures, d.held, seen_by_gaoler])
		ClarityKit.done(s)
	s = _prisoner_world()
	d = s.d
	_far_but_gaolers(d)
	_free_her(s)
	t.check(d.held and d.seizures == 1, "control: with both gaolers standing, the fall of the stocks sees her seized at once (%d)" % d.seizures)
	ClarityKit.done(s)

	s = _prisoner_world()
	d = s.d
	ClarityKit.apply(s, "strike", d.stocks)
	var fell := d.stocks.destroyed
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	_case(t, id, "bound", "strike", fell and not d.bound, "a blow on the stocks brings them down and frees her (down %s, bound %s)" % [fell, d.bound])
	ClarityKit.done(s)

	s = _prisoner_world()
	d = s.d
	ClarityKit.apply(s, "burn", d.stocks)
	var burning: bool = (s.crowd as Crowd).fires.fires.has(d.stocks)
	var waited := 0.0
	while d.bound and waited < 60.0 and not d.bound_lost:
		Kit.run_for(s, 5.0)
		waited += 5.0
	_case(t, id, "bound", "burn", burning and not d.bound and not d.bound_lost, "fire on the stocks burns them down and frees her (alight %s, freed after %.0f s)" % [burning, waited])
	ClarityKit.done(s)

	# caught: a watchman seizes her; Lead, Scare or Kill him and she is let go.
	for verb in ["lead", "scare", "kill"]:
		s = _free_world()
		d = s.d
		var by: Person = d.watch[0]
		_beside(by, d._first(), 0.5)
		_release(t, id, "caught", verb, s, by, d._first())

	# hounds: the hunters sent out of the Citadel -- Lead, Scare or Kill the one who sees her.
	for verb in ["lead", "scare", "kill"]:
		s = _free_world()
		d = s.d
		var hound: Person = d.searchers[0]
		hound.inside = false
		d.hunters.append(hound)
		_beside(hound, d._first())
		_unsee(t, id, "hounds", verb, s, hound, d._first())

	# gate: the postern's watch -- Lead (or Kill) the one at the postern.
	for verb in ["lead", "kill"]:
		s = _free_world()
		d = s.d
		var watcher: Person = d.watch[0]
		_beside(watcher, d._first())
		_unsee(t, id, "gate", verb, s, watcher, d._first())

	# clear: Lead her through.
	s = _free_world()
	_walks(t, id, "clear", s, (s.d as PrisonerDirector)._first())


## The gaolers stay; everyone else who watches is far.
static func _far_but_gaolers(d: PrisonerDirector) -> void:
	var keep := d.gaolers.duplicate()
	var all: Array = d._watchers()
	all.append_array(d.searchers)
	for v: Variant in all:
		if MissionDirector._alive(v) and not keep.has(v) and not (v as Person).inside:
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(60.0, 60.0))


static func _prisoner_why(t) -> void:
	var s := _prisoner_world()
	var d: PrisonerDirector = s.d
	var her := d.charge
	var gaoler: Person = d.gaolers[0]
	t.check(d.hint_phase() == "bound", "bound, her phase is bound")
	# Lead or Lure on her while she is bound.
	t.check(d.why_not("wisp", her.ground_pos) == "BOUND - SHE CANNOT HEAR YOU" and d.why_not("whisper", her.ground_pos) == "BOUND - SHE CANNOT HEAR YOU",
		"a lead or a lure on the bound prisoner says she cannot hear")
	ClarityKit.apply(s, "lead", her)
	t.check(not bool(s.took) and her.mind != Person.Mind.WHISPERED, "and it is true: a whisper does not take her (took %s)" % s.took)
	ClarityKit.apply(s, "lure", her, "wisp")
	t.check(not bool(s.took) and her.mind != Person.Mind.OBSERVE, "and a light does not draw her (took %s)" % s.took)
	# Scare on a gaoler while she is bound.
	var text := "PAST FEAR WHILE SHE IS BOUND"
	var loud := ""
	for k in PowerBook.keys():
		if MissionVerbs.verbs_of(k) == PackedStringArray(["scare"]):
			loud = k
			break
	t.check(loud != "" and d.why_not(loud, gaoler.ground_pos) == text, "a pure fright near a gaoler says he is past fear (%s)" % loud)
	t.check(d.why_not("doom", gaoler.ground_pos) == "" and d.why_not("discord", gaoler.ground_pos) == "" and d.why_not("ember", d.stocks.center()) == "",
		"a kill, a confusion or a fire on the stocks say nothing")
	t.check(d.why_not(loud, gaoler.ground_pos + Vector2(40.0, 0.0)) == "" and d.why_not(loud, Vector2(40.0, 40.0)) == "", "a cast far from every gaoler says nothing")
	ClarityKit.assert_read_only(t, s, "prisoner (bound)")
	# True: a fright near a gaoler leaves him standing at his post, not moved.
	ClarityKit.apply(s, "scare", gaoler)
	t.check(gaoler.mind == Person.Mind.DUTY or gaoler.mind == Person.Mind.CALM, "and it is true: a loud cast beside him leaves him at his post (mind %s)" % gaoler.mind)
	ClarityKit.done(s)
	# Free: the banners are gone.
	s = _free_world()
	d = s.d
	t.check(d.why_not("wisp", d.charge.ground_pos) == "" and d.why_not("whisper", d.charge.ground_pos) == "", "free, a lead or a lure on her says nothing")
	ClarityKit.assert_read_only(t, s, "prisoner (free)")
	ClarityKit.done(s)


# --- Exodus ---------------------------------------------------------------------------------------------------------------------------

static func _exodus_world() -> Dictionary:
	var s := _world(MissionBook.exodus())
	var d: ExodusDirector = s.d
	d._come_out(0)
	Kit.run_for(s, 0.5)
	_far(d)
	return s


static func _exodus(t) -> void:
	var id := "exodus"
	# "": Lead the lamp and the household follows.
	var s := _exodus_world()
	var d: ExodusDirector = s.d
	var h: ExodusDirector.Household = d.households[0]
	var lamp := d.lamp(0)
	var lamp_at := (lamp.man as Person).ground_pos
	var follower: EscortDirector.Charge = null
	for c: EscortDirector.Charge in h.members:
		if c != lamp:
			follower = c
			break
	var way := (d.gates[0] as ExodusDirector.Gate).mouth
	var to_at := way
	for pt: Vector2 in d.road(0):
		if pt.distance_to(lamp_at) >= 3.0:
			to_at = pt
			break
	s["to"] = to_at
	var picked: bool = MindWhisperFx.pick(s.field, lamp_at) == lamp.man
	ClarityKit.apply(s, "lead", lamp.man)
	var lp := lamp.man as Person
	var sent := lp.mind == Person.Mind.WHISPERED and lp.goal().distance_to(to_at) < 0.6
	# He walks it (a step at a time, as test_exodus does): the household falls in behind him in file.
	for k in 6:
		Kit.arrive(lp, lamp_at.move_toward(to_at, 0.6 * float(k + 1)))
		Kit.run_for(s, ExodusDirector.TICK + DT)
	var spot := d._file_spot(follower)
	_case(t, id, "", "lead", picked and bool(s.took) and sent and spot != Vector2.INF and d.followers(0).size() >= 1,
		"the lamp is sent where whispered (%s) and the household falls in behind him (spot %s, in file %d)" % [sent, spot, d.followers(0).size()])
	ClarityKit.done(s)
	for verb in ["scare", "kill"]:
		s = _exodus_world()
		d = s.d
		var guard: Person = d.watch[0]
		_beside(guard, d.lamp(0))
		_unsee(t, id, "", verb, s, guard, d.lamp(0))

	# caught / hounds / gate / waiting: the watchers, by their verbs.
	for verb in ["lead", "scare", "kill"]:
		s = _exodus_world()
		d = s.d
		var by: Person = d.patrols[0][0]
		_beside(by, d.lamp(0), 0.5)
		_release(t, id, "caught", verb, s, by, d.lamp(0))
	for verb in ["lead", "scare", "kill"]:
		s = _exodus_world()
		d = s.d
		d._send(0)
		var hound: Person = (d.households[0] as ExodusDirector.Household).searchers[0]
		hound.inside = false
		_beside(hound, d.lamp(0))
		t.check(d._watchers().has(hound), "a household's searchers are watchers once it is sent (hounds)")
		_unsee(t, id, "hounds", verb, s, hound, d.lamp(0))
	for verb in ["scare", "kill"]:
		s = _exodus_world()
		d = s.d
		var guard: Person = d.watch[0]
		_beside(guard, d.lamp(0))
		_unsee(t, id, "gate", verb, s, guard, d.lamp(0))
		s = _exodus_world()
		d = s.d
		var next_guard: Person = d.watch[1]
		_beside(next_guard, d.lamp(0))
		_unsee(t, id, "waiting", verb, s, next_guard, d.lamp(0))
	# gate and shut: Lead the household on.
	s = _exodus_world()
	_walks(t, id, "gate", s, (s.d as ExodusDirector).lamp(0))
	s = _exodus_world()
	_walks(t, id, "shut", s, (s.d as ExodusDirector).lamp(0))

	# Two households out: a hold, a scare or a lead on one's watcher says nothing for either (Review focus 3).
	s = _exodus_world()
	d = s.d
	d._come_out(1)
	Kit.run_for(s, 0.5)
	t.check(d.households.size() == 3 and (d.households[0] as ExodusDirector.Household).out and (d.households[1] as ExodusDirector.Household).out,
		"two households are out")
	var asked := 0
	var said := PackedStringArray()
	var points: Array[Vector2] = [Vector2.ZERO]
	for m in d.tags():
		points.append(m.at)
	for verb: String in ClarityKit.DEFAULT_KEY:
		for g in points:
			asked += 1
			var w := d.why_not(String(ClarityKit.DEFAULT_KEY[verb]), g)
			if w != "":
				said.append(w)
	t.check(asked > 0 and said.is_empty(), "Exodus says nothing for any verb at any tag with two households out (asked %d, said %s)" % [asked, said])
	ClarityKit.assert_read_only(t, s, "exodus (two households out)")
	ClarityKit.done(s)


# --- Hide the Faithful ----------------------------------------------------------------------------------------------------------------

static func _hide_world() -> Dictionary:
	var s := _world(HuntBook.def(MissionBook.HIDE_FAITHFUL))
	var d: HideFaithfulDirector = s.d
	d._come_out(0)
	Kit.run_for(s, 0.5)
	_far(d)
	return s


static func _hide(t) -> void:
	var id := "hide_faithful"
	for verb in ["hold", "kill"]:
		var s := _hide_world()
		var d: HideFaithfulDirector = s.d
		var guard: Person = d.watch[0]
		_beside(guard, d.lamp(0))
		_unsee(t, id, "", verb, s, guard, d.lamp(0))
	# trail: the Inquisition's searchers are lay inquisitors: Scare or Kill.
	for verb in ["scare", "kill"]:
		var s := _hide_world()
		var d: HideFaithfulDirector = s.d
		var inq := d.inquisitors[0] as Person
		inq.inside = false
		_beside(inq, d.lamp(0))
		t.check(d._watchers().has(inq) or d._is_searcher(inq), "an inquisitor is a watcher")
		_unsee(t, id, "trail", verb, s, inq, d.lamp(0))
	# seized: the seizer -- a soldier of the watch -- Held or Killed lets him go.
	for verb in ["hold", "kill"]:
		var s := _hide_world()
		var d: HideFaithfulDirector = s.d
		var by: Person = d.watch[0]
		_beside(by, d.lamp(0), 0.5)
		_release(t, id, "seized", verb, s, by, d.lamp(0))
	# A believer set walking by a whisper is not ignored: no banner (the walk resumes after it); nothing here says anything.
	var s2 := _hide_world()
	var d2: HideFaithfulDirector = s2.d
	var believer := d2.lamp(0).man as Person
	t.check(d2.why_not("whisper", believer.ground_pos) == "" and d2.why_not("wisp", believer.ground_pos) == "",
		"Hide the Faithful says nothing for a lead on a believer: the code does not ignore it")
	ClarityKit.apply(s2, "lead", believer)
	t.check(bool(s2.took) and believer.mind == Person.Mind.WHISPERED, "and it is true: a whisper takes a believer (he walks where sent)")
	ClarityKit.assert_read_only(t, s2, "hide_faithful")
	ClarityKit.done(s2)


# --- Face Halcyon ---------------------------------------------------------------------------------------------------------------------

static func _face_world() -> Dictionary:
	var s := _world(HuntBook.def(MissionBook.FACE_HALCYON))
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + LOOK)
	return s


static func _face(t) -> void:
	var id := "face_halcyon"
	# Hold two of the three escorts and the believer is freed.
	var s := _face_world()
	var d: FaceHalcyonDirector = s.d
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	t.check(d.able_escort(0) == 3 and pr.escorts.size() == FaceHalcyonDirector.FH_ESCORT, "three escorts stand able round him")
	var picked: bool = true
	for k in 2:
		var e := pr.escorts[k] as Person
		picked = picked and OathboundFx.bound_at(s.field, e.ground_pos).has(e)
		ClarityKit.apply(s, "hold", e)
	Kit.run_for(s, FaceHalcyonDirector.FH_GRACE + 1.0)
	var freed_by_hold := d.out_count() == 1 and pr.phase == FaceHalcyonDirector.Procession.Phase.FREED
	for ph in ["", "pyre", "gaze"]:
		_case(t, id, ph, "hold", picked and freed_by_hold, "two escorts held (the real pick %s), the believer is freed (%s)" % [picked, d.out_count()])
	ClarityKit.done(s)
	# One held is not enough, and the HUD hears why.
	s = _face_world()
	d = s.d
	pr = d.procs[0]
	var held_one := pr.escorts[0] as Person
	ClarityKit.apply(s, "hold", held_one)
	Kit.run_for(s, FaceHalcyonDirector.FH_GRACE + 1.0)
	t.check(d.able_escort(0) == 2 and d.out_count() == 0 and pr.phase != FaceHalcyonDirector.Procession.Phase.FREED,
		"one escort held leaves him guarded by two (able %d)" % d.able_escort(0))
	ClarityKit.done(s)


static func _face_why(t) -> void:
	var s := _face_world()
	var d: FaceHalcyonDirector = s.d
	var pr: FaceHalcyonDirector.Procession = d.procs[0]
	var first := pr.escorts[0] as Person
	var second := pr.escorts[1] as Person
	var believer := d.procs[0].charge.man as Person
	var text := "STILL GUARDED - HOLD MORE ESCORTS"
	t.check(d.why_not("oath", first.ground_pos) == "", "before any hold lands the cast has nothing to say (the first escort is still able)")
	ClarityKit.apply(s, "hold", first)
	t.check(d.able_escort(0) == 2 and d.why_not("oath", first.ground_pos) == text, "one held, two still able: STILL GUARDED")
	ClarityKit.apply(s, "hold", second)
	t.check(d.able_escort(0) == 1 and d.why_not("oath", second.ground_pos) == "", "the second held leaves one able: the cast counts, nothing to say")
	ClarityKit.done(s)
	s = _face_world()
	d = s.d
	pr = d.procs[0]
	first = pr.escorts[0] as Person
	believer = pr.charge.man as Person
	t.check(d.why_not("whisper", believer.ground_pos) == "BOUND - HE CANNOT HEAR YOU" and d.why_not("wisp", believer.ground_pos) == "BOUND - HE CANNOT HEAR YOU",
		"a lead or a lure on the bound believer says he cannot hear")
	ClarityKit.apply(s, "lead", believer)
	t.check(not bool(s.took) and believer.mind != Person.Mind.WHISPERED, "and it is true: a whisper does not take him (took %s)" % s.took)
	t.check(d.why_not("doom", first.ground_pos) == "" and d.why_not("smite", first.ground_pos) == "" and d.why_not("oath", first.ground_pos + Vector2(40.0, 0.0)) == "",
		"a kill, a bolt that kills an escort, and a hold far from everyone say nothing")
	ClarityKit.assert_read_only(t, s, "face_halcyon")
	ClarityKit.done(s)


# --- the countdowns ------------------------------------------------------------------------------------------------------------------

static func _seconds(t) -> void:
	var s := _lamb_world()
	var d: LostLambDirector = s.d
	t.check(is_equal_approx(d.hint_seconds(), d.bolt_left()) and d.hint_seconds() > 50.0, "the Lamb's countdown is the existing bolt_left() (%.1f)" % d.hint_seconds())
	d._lead()
	t.check(d.hint_seconds() == 0.0, "once he is led there is nothing to count")
	t.check(d.watch_change_in() == 0.0, "and no watch change is scheduled before he nears the gate")
	d.change_in = 12.0
	t.check(is_equal_approx(d.watch_change_in(), 12.0), "the watch's change reads its clock")
	d.watch_away = true
	d.away_left = 10.0
	t.check(is_equal_approx(d.watch_change_in(), 10.0 + EscortDirector.WATCH_CYCLE - EscortDirector.WATCH_GAP), "and while it is away, the walk back and the next change")
	ClarityKit.done(s)

	s = _face_world()
	var f: FaceHalcyonDirector = s.d
	t.check(f.hint_seconds() == 0.0, "no pyre, no count")
	var pr: FaceHalcyonDirector.Procession = f.procs[0]
	pr.phase = FaceHalcyonDirector.Procession.Phase.BURNING
	pr.burn_end = f._clock + 9.0
	t.check(f.hint_phase() == "pyre" and absf(f.hint_seconds() - 9.0) < 0.01, "at the pyre it counts the burning believer's seconds left (%.1f)" % f.hint_seconds())
	ClarityKit.done(s)

	s = _prisoner_world()
	var p: PrisonerDirector = s.d
	t.check(p.hint_seconds() == 0.0, "the Prisoner counts nothing while bound")
	ClarityKit.done(s)


# --- read-only -----------------------------------------------------------------------------------------------------------------------

static func _read_only(t) -> void:
	var s := _lamb_world()
	ClarityKit.assert_read_only(t, s, "lost_lamb (start)")
	(s.d as LostLambDirector)._start_bolt(false)
	ClarityKit.assert_read_only(t, s, "lost_lamb (bolting)")
	ClarityKit.done(s)
	s = _hide_world()
	ClarityKit.assert_read_only(t, s, "hide_faithful (out)")
	ClarityKit.done(s)


# --- colours, plate and openers -----------------------------------------------------------------------------------------------------

## Every phase's step and hint of `id` names only colours `d` draws now.
static func _colours_of(t, id: String, d: MissionDirector, phases: Array, label: String) -> void:
	for ph: String in phases:
		for text in ClarityKit.texts(id, ph):
			ClarityKit.colours_ok(t, d, text, "%s/%s" % [label, ph])


static func _colours(t) -> void:
	var s := _lamb_world()
	_colours_of(t, "lost_lamb", s.d, ["", "running", "led", "caught", "gate", "clear"], "lost_lamb")
	ClarityKit.done(s)
	s = _prisoner_world()
	_colours_of(t, "prisoner", s.d, ["bound"], "prisoner")
	ClarityKit.done(s)
	s = _free_world()
	_colours_of(t, "prisoner", s.d, ["", "caught", "hounds", "gate", "clear"], "prisoner (free)")
	ClarityKit.done(s)
	s = _exodus_world()
	_colours_of(t, "exodus", s.d, ["", "caught", "hounds", "gate", "shut", "waiting"], "exodus")
	ClarityKit.done(s)
	s = _hide_world()
	_colours_of(t, "hide_faithful", s.d, ["", "trail", "seized"], "hide_faithful")
	ClarityKit.done(s)
	s = _face_world()
	_colours_of(t, "face_halcyon", s.d, ["", "pyre", "gaze"], "face_halcyon")
	ClarityKit.done(s)


## Every step opens with a vocabulary verb (and fits MAX_LABEL: coverage); every hint fits the plate with its seconds at their longest.
static func _texts(t) -> void:
	var words := PackedStringArray()
	for v in MissionVerbs.verbs():
		words.append(MissionVerbs.word(v))
	var bad := PackedStringArray()
	var long := PackedStringArray()
	for id in IDS:
		for step: Dictionary in MissionSteps.steps(id):
			if not words.has(String(step["t"]).get_slice(" ", 0)):
				bad.append("%s: %s" % [id, step["t"]])
		for key: String in MissionHints.LINES:
			if key == id or key.begins_with(id + "."):
				var line := MissionHints.filled(String(MissionHints.LINES[key]), 999.0)
				if Hud.hint_lines(line).size() > Hud.HINT_LINES:
					long.append(key)
	t.check(bad.is_empty(), "every escort step opens with a verb of the vocabulary (%s)" % ["; ".join(bad)])
	t.check(long.is_empty(), "every escort hint fits the plate with its seconds at 999 (%s)" % ["; ".join(long)])
