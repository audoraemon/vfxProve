extends RefCounted
## Mission clarity, the convert group (Task 4; spec 5.6): First Prayers, Mira's House, The Sermon, The Vigil Flame, The Relic Run, Broken
## Lanterns and The First Taste. For every (mission, phase, verb) a step or hint of these names, one case lands the verb on its target through
## the kit's real path and asserts the director's own progress; one case per why-not banner (and "" far away and when the cast counts);
## every director passes ClarityKit.assert_read_only(); the coverage and colour checks close the file.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const ClarityKit := preload("res://tests/clarity_kit.gd")
const DT := 0.05
## Where a lamplighter is chained from to be about 1.8 from the shrine-road post (First Taste).
const BY_POST := Vector2(-8.0, 19.4)
const IDS := ["first_prayers", "miras_house", "sermon", "vigil_flame", "relic_run", "broken_lanterns", "first_taste"]

## The (id, phase, verb) rows a step or hint names (ClarityKit.check_coverage reads them; each is proved below by a case that records it).
const ROWS := [
	["first_prayers", "", "lead"], ["first_prayers", "", "lure"],
	["first_prayers", "watched", "burn"], ["first_prayers", "watched", "calm"], ["first_prayers", "watched", "lead"],
	["first_prayers", "watched", "confuse"], ["first_prayers", "watched", "kill"],
	["miras_house", "", "lead"], ["miras_house", "", "lure"],
	["sermon", "", "lead"], ["sermon", "rapt", "lead"], ["sermon", "rapt", "confuse"], ["sermon", "rapt", "scare"], ["sermon", "rapt", "kill"],
	["sermon", "coming", "lead"], ["sermon", "watched", "lead"], ["sermon", "watched", "confuse"], ["sermon", "watched", "kill"],
	["sermon", "report", "kill"], ["sermon", "bell", "kill"],
	["vigil_flame", "", "lead"], ["vigil_flame", "", "confuse"], ["vigil_flame", "wren", "lead"], ["vigil_flame", "wren", "lure"],
	["vigil_flame", "homeward", "lead"], ["vigil_flame", "carry", "lead"],
	["relic_run", "", "lead"], ["relic_run", "moving", "lead"], ["relic_run", "moving", "confuse"], ["relic_run", "moving", "kill"],
	["relic_run", "watched", "lead"], ["relic_run", "watched", "confuse"], ["relic_run", "watched", "kill"], ["relic_run", "watched", "lure"],
	["relic_run", "aboard", "lead"], ["relic_run", "aboard", "confuse"], ["relic_run", "aboard", "kill"],
	["relic_run", "carry", "lead"], ["relic_run", "last_halt", "lead"], ["relic_run", "report", "kill"], ["relic_run", "bell", "kill"],
	["broken_lanterns", "", "strike"], ["broken_lanterns", "", "lead"], ["broken_lanterns", "knights", "lead"],
	["broken_lanterns", "knights", "kill"], ["broken_lanterns", "knights", "strike"],
	["first_taste", "drag", "hold"], ["first_taste", "drag", "kill"], ["first_taste", "march", "kill"], ["first_taste", "march", "scare"],
	["first_taste", "cleanse", "kill"], ["first_taste", "cleanse", "scare"],
]

static var _proved := {}


## The cases the coverage check reads.
static func cases() -> Array:
	var out := []
	for r: Array in ROWS:
		out.append({"id": r[0], "phase": r[1], "verb": r[2]})
	return out


static func run(t) -> void:
	_proved = {}
	_first_prayers(t)
	_miras(t)
	_sermon(t)
	_vigil(t)
	_relic(t)
	_lanterns(t)
	_taste(t)
	var missing := PackedStringArray()
	for r: Array in ROWS:
		if not _proved.has("%s/%s/%s" % [r[0], r[1], r[2]]):
			missing.append("%s/%s/%s" % [r[0], r[1], r[2]])
	t.check(missing.is_empty(), "every case row was proved (unproved: %s)" % ", ".join(missing))
	ClarityKit.check_coverage(t, PackedStringArray(IDS), cases())
	_colours(t)
	_fit(t)


## Records and asserts one case row.
static func _prove(t, ok: bool, id: String, phase: String, verb: String, msg: String) -> void:
	t.check(ok, "%s/%s/%s: %s" % [id, phase, verb, msg])
	if ok:
		_proved["%s/%s/%s" % [id, phase, verb]] = true


## The world of `def`, stepping the crowd, every person in `who` (headless, a crowd's people are not stepped by their own _process) and the rules.
static func _run(s: Dictionary, seconds: float, who := []) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		for p: Variant in who:
			if is_instance_valid(p):
				(p as Person).tick(DT)
		(s.rules as Rules).advance(DT)


## `key`'s cast at `at`, moved far enough that it reaches nothing (the spec's "the same cast far away").
static func _far(key: String, at: Vector2) -> Vector2:
	return at + Vector2(Crowd._cast_radius(key) + MissionDirector.WHY_MARGIN + 30.0, 0.0)


## Every Faithful who would see `d`'s door moved well away (sentries and wardens included: they are Faithful).
static func _unwatch(d: MirasHouseDirector) -> void:
	for f in d.watchers(d.door, MirasHouseDirector.SIGHT):
		Kit.arrive(f, d.door + Vector2(MirasHouseDirector.SIGHT + 8.0, 0.0))


## One Faithful stands by the door and sees it; the others are away. Returns him.
static func _watch(d: MirasHouseDirector) -> Person:
	_unwatch(d)
	var f: Person = null
	for p in d.faithful:
		if MissionDirector._alive(p) and not p.inside:
			f = p
			break
	Kit.arrive(f, d.door + Vector2(1.5, 0.0))
	f.mind = Person.Mind.CALM
	return f


## A house within `reach` of `at` (nearest first), or the nearest beyond `beyond` when `reach` is 0.
static func _house_near(town: Town, at: Vector2, within: float, beyond := 0.0) -> Structure:
	var best: Structure = null
	for st: Structure in town._built:
		if st.kind != Structure.Kind.HOUSE or st.role != &"house" or st.destroyed:
			continue
		var d := st.center().distance_to(at)
		if (within > 0.0 and d > within) or d < beyond:
			continue
		if best == null or d < best.center().distance_to(at):
			best = st
	return best


# --- First Prayers and Mira's House ---------------------------------------------------------------------------------

## Lead and Lure bring one of the poor in at an unwatched door; the same cast read by the why-nots.
static func _brought(t, id: String, def: MissionDef, turned: String, only: String) -> void:
	var s := ClarityKit.world(def)
	var d: MirasHouseDirector = s.d
	_unwatch(d)
	var g: Person = d.grieving[0]
	Kit.arrive(g, d.door)
	s["to"] = d.door
	ClarityKit.apply(s, "lead", g)
	var quiet := d.why_not("whisper", s.at)
	_run(s, 0.5)
	_prove(t, bool(s.took) and quiet == "" and d.inside().has(g), id, "", "lead", "led to an unwatched door he goes in (%s)" % d.inside())
	ClarityKit.done(s)

	s = ClarityKit.world(def)
	d = s.d
	_unwatch(d)
	g = d.grieving[0]
	Kit.arrive(g, d.door + Vector2(1.0, 0.0))
	s["light"] = d.door
	ClarityKit.apply(s, "lure", g)
	var took := bool(s.took)
	var said := d.why_not("wisp", s.at)
	if g.goal() != Vector2.INF:
		Kit.arrive(g, g.goal())
	_run(s, 0.5)
	_prove(t, took and said == "" and d.inside().has(g), id, "", "lure", "a light by the door draws one of the poor in (took %s, said '%s')" % [took, said])
	ClarityKit.done(s)

	# Why-not: a watched door turns him away.
	s = ClarityKit.world(def)
	d = s.d
	var f := _watch(d)
	g = d.grieving[0]
	Kit.arrive(g, d.door)
	s["to"] = d.door
	ClarityKit.apply(s, "lead", g)
	var key := "whisper"
	t.check(d.why_not(key, s.at) == turned and d.why_not(key, _far(key, s.at)) == "" and turned.length() <= 36,
		"%s: a lead to a watched door says %s (got '%s'; whispered %s at %s, goal %s door %s took %s)" % [id, turned, d.why_not(key, s.at), d._whispered_at(s.at), s.at, g.goal(), d.door, s.took])
	_run(s, 0.5)
	t.check(not d.inside().has(g) and d._turned.has(g), "%s: and the banner is true: he is turned away" % id)
	ClarityKit.done(s)
	s = ClarityKit.world(def)
	d = s.d
	f = _watch(d)
	g = d.grieving[0]
	Kit.arrive(g, d.door + Vector2(1.0, 0.0))
	s["light"] = d.door
	ClarityKit.apply(s, "lure", g)
	t.check(d.why_not("wisp", s.at) == turned and d.why_not("wisp", _far("wisp", s.at)) == "",
		"%s: a light by a watched door says %s (got '%s')" % [id, turned, d.why_not("wisp", s.at)])
	ClarityKit.done(s)

	# Why-not: someone who is not of the poor.
	s = ClarityKit.world(def)
	d = s.d
	_unwatch(d)
	var other: Person = null
	for p in (s.crowd as Crowd).citizens:
		if not d.grieving.has(p) and not d.faithful.has(p) and MissionDirector._alive(p):
			other = p
			break
	Kit.arrive(other, d.door)
	s["to"] = d.door
	ClarityKit.apply(s, "lead", other)
	t.check(d.why_not(key, s.at) == only and d.why_not(key, _far(key, s.at)) == "" and only.length() <= 36,
		"%s: a lead of someone else to the door says %s (got '%s')" % [id, only, d.why_not(key, s.at)])
	_run(s, 0.5)
	t.check(not d.inside().has(other), "%s: and the banner is true: he does not go in" % id)
	ClarityKit.assert_read_only(t, s, id)
	ClarityKit.done(s)

	# Why-not: held, he still sees (a compel on a Faithful at the door); Discord blinds him.
	s = ClarityKit.world(def)
	d = s.d
	f = _watch(d)
	ClarityKit.apply(s, "hold", f)
	t.check(d.why_not("oath", s.at) == MirasHouseDirector.WHY_HELD and d.why_not("oath", _far("oath", s.at)) == ""
		and d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) == f, "%s: a hold on the watcher says he still sees, and he does" % id)
	ClarityKit.done(s)
	s = ClarityKit.world(def)
	d = s.d
	f = _watch(d)
	ClarityKit.apply(s, "confuse", f)
	t.check(d.why_not("discord", s.at) == "" and d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) == null,
		"%s: Discord on him counts: no banner, and he sees nothing" % id)
	ClarityKit.done(s)


static func _miras(t) -> void:
	_brought(t, "miras_house", MissionBook.miras_house(), "WATCHED - SHE WILL BE TURNED AWAY", "ONLY THE GRIEVING (GOLD) GO IN")


static func _first_prayers(t) -> void:
	_brought(t, "first_prayers", MissionBook.first_prayers(), "WATCHED - HE WILL BE TURNED AWAY", "ONLY THE POOR (GOLD) PRAY HERE")
	var s := ClarityKit.world(MissionBook.first_prayers())
	var d: FirstPrayersDirector = s.d
	var f := _watch(d)
	t.check(d.hint_phase() == "watched", "first_prayers: a Faithful at the door: the watched phase")
	# Burn: a house within FIRE_PULL pulls him off; one beyond says it is too far.
	var near := _house_near(s.town, d.door, FirstPrayersDirector.FIRE_PULL)
	t.check(near != null, "first_prayers: a house stands within FIRE_PULL of the door")
	if near != null:
		ClarityKit.apply(s, "burn", near)
		var quiet := d.why_not("ember", near.center())
		_run(s, 0.2)
		if f.anchor != Vector2.INF:
			Kit.arrive(f, f.anchor)
		_prove(t, quiet == "" and d._pulled.has(f) and d.hint_phase() == "", "first_prayers", "watched", "burn",
			"a house by the door burns: he is pulled off and the door is not watched (phase '%s')" % d.hint_phase())
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.first_prayers())
	d = s.d
	f = _watch(d)
	var far := _house_near(s.town, d.door, 0.0, FirstPrayersDirector.FIRE_PULL + 3.0)
	t.check(far != null, "first_prayers: a house stands beyond FIRE_PULL")
	if far != null:
		var no_near := true
		for st: Structure in s.town._built:
			if not st.destroyed and st != d.house and st.center().distance_to(far.center()) <= Crowd._cast_radius("ember") + MissionDirector.WHY_MARGIN \
					and st.center().distance_to(d.door) <= FirstPrayersDirector.FIRE_PULL:
				no_near = false
		var text := d.why_not("ember", far.center())
		t.check(not no_near or text == FirstPrayersDirector.WHY_FAR, "first_prayers: a Burn beyond FIRE_PULL says %s (got '%s')" % [FirstPrayersDirector.WHY_FAR, text])
		t.check(d.why_not("ember", Vector2(900.0, 900.0)) == "", "first_prayers: and a Burn far from every building says nothing")
		ClarityKit.apply(s, "burn", far)
		_run(s, 0.3)
		t.check(not d._pulled.has(f) and d.hint_phase() == "watched", "first_prayers: and the banner is true: the Faithful are not pulled")
	ClarityKit.assert_read_only(t, s, "first_prayers")
	ClarityKit.done(s)
	# Calm, lead, confuse, kill.
	for verb: String in ["calm", "lead", "confuse", "kill"]:
		s = ClarityKit.world(MissionBook.first_prayers())
		d = s.d
		f = _watch(d)
		var target: Variant = d.door if verb == "calm" else f
		ClarityKit.apply(s, verb, target)
		_run(s, 0.2)
		_prove(t, d.hint_phase() == "", "first_prayers", "watched", verb, "the door is not watched after it (phase '%s')" % d.hint_phase())
		ClarityKit.done(s)
	# The hint counts down the next walker.
	s = ClarityKit.world(MissionBook.first_prayers())
	d = s.d
	t.check(absf(d.hint_seconds() - float(FirstPrayersDirector.POOR_OUT_AT[0])) < 1.0, "first_prayers: the hint counts to the first walker (%.1f)" % d.hint_seconds())
	_run(s, 10.0)
	t.check(absf(d.hint_seconds() - (float(FirstPrayersDirector.POOR_OUT_AT[0]) - 10.0)) < 1.0, "first_prayers: ten seconds on, ten fewer (%.1f)" % d.hint_seconds())
	ClarityKit.done(s)


# --- The Sermon ---------------------------------------------------------------------------------------------------------

static func _sermon(t) -> void:
	var s := ClarityKit.world(MissionBook.sermon())
	var d: SermonDirector = s.d
	_unwatch(d)
	var l := d.listeners[0] as SermonDirector.Listener
	var p := l.man as Person
	Kit.arrive(p, d.door)
	p._shaken_left = 0.0
	s["to"] = d.door
	ClarityKit.apply(s, "lead", p)
	_run(s, 0.5)
	_prove(t, bool(s.took) and d.inside().has(p), "sermon", "", "lead", "a listener led to the unwatched god's house goes in")
	ClarityKit.done(s)

	# The preacher: confuse, scare, lead take his voice; kill does it, and it is seen by his acolytes unless they are blind.
	for verb: String in ["confuse", "scare", "lead"]:
		s = ClarityKit.world(MissionBook.sermon())
		d = s.d
		var was := d.preaching() and d.hint_phase() == "rapt"
		ClarityKit.apply(s, verb, d.preacher)
		_run(s, 0.3)
		_prove(t, was and not d.preaching(), "sermon", "rapt", verb, "he preaches no more (phase before was rapt: %s)" % was)
		ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.sermon())
	d = s.d
	for a: Variant in d.acolytes:
		(a as Person).confuse(60.0)
	ClarityKit.apply(s, "kill", d.preacher)
	_run(s, 0.6)
	var unseen := not d.preaching() and d.reports.is_empty()
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.sermon())
	d = s.d
	ClarityKit.apply(s, "kill", d.preacher)
	_run(s, 0.6)
	_prove(t, unseen and not d.reports.is_empty(), "sermon", "rapt", "kill", "unseen by his held acolytes it ends the sermon quietly; seen, a report runs (%d)" % d.reports.size())
	ClarityKit.done(s)

	# Coming: a latecomer on his way, out of the preacher's voice, is led.
	s = ClarityKit.world(MissionBook.sermon())
	d = s.d
	d._call_wave(1)
	var late: Person = null
	for l2: SermonDirector.Listener in d.listeners:
		if l2.wave == 1:
			late = l2.man as Person
			break
	Kit.arrive(late, d.door + Vector2(0.0, 3.0))
	late._shaken_left = 0.0
	late.fearless_left = 0.0
	late.go_duty(late.ground_pos)
	var before := d.hint_phase()
	s["to"] = d.door
	ClarityKit.apply(s, "lead", late)
	_prove(t, before == "coming" and bool(s.took) and late.mind == Person.Mind.WHISPERED, "sermon", "coming", "lead",
		"a walked-in listener outside his voice (phase %s) takes the whisper" % before)
	ClarityKit.done(s)

	# Watched: a sentry is led, confused or killed off the door; held he still sees (why-not).
	for verb: String in ["lead", "confuse", "kill"]:
		s = ClarityKit.world(MissionBook.sermon())
		d = s.d
		var st := d.sentries[0] as SermonDirector.Sentry
		var man := st.man as Person
		var on := d.sentries_on_guard().size()
		ClarityKit.apply(s, verb, man)
		_run(s, 0.2)
		_prove(t, on == 2 and not d.sentries_on_guard().has(man) and d.sentries_on_guard().size() == 1, "sermon", "watched", verb,
			"the sentry is off the door (%d on guard of %d)" % [d.sentries_on_guard().size(), on])
		ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.sermon())
	d = s.d
	var guard := (d.sentries[0] as SermonDirector.Sentry).man as Person
	ClarityKit.apply(s, "hold", guard)
	t.check(d.why_not("oath", s.at) == MirasHouseDirector.WHY_HELD and d.why_not("oath", _far("oath", s.at)) == "" and d.sentries_on_guard().has(guard),
		"sermon: a hold on a sentry says he still sees, and he still guards the door (got '%s')" % d.why_not("oath", s.at))
	ClarityKit.assert_read_only(t, s, "sermon")
	ClarityKit.done(s)

	# Report: the runner killed unseen ends the report.
	s = ClarityKit.world(MissionBook.sermon())
	d = s.d
	var seer: Person = d.acolytes[0]
	for f in d.faithful:
		if f != seer:
			Kit.arrive(f, d.temple_door + Vector2(40.0, 0.0))
	Kit.arrive(seer, d.pulpit + Vector2(0.0, 12.0))
	d._report(seer, d.temple_door)
	var report: TempleReport = d.reports[0]
	var phase := d.hint_phase()
	ClarityKit.apply(s, "kill", seer)
	_run(s, 0.6)
	_prove(t, phase == "report" and not report.is_open(), "sermon", "report", "kill", "the runner killed unseen ends the report (phase %s)" % phase)
	ClarityKit.done(s)

	# Bell: the called keeper killed.
	s = ClarityKit.world(MissionBook.sermon())
	d = s.d
	s.crowd.bell.call_keeper()
	var keeper := d.bellkeeper()
	phase = d.hint_phase()
	if keeper != null:
		ClarityKit.apply(s, "kill", keeper)
		_run(s, 0.6)
	_prove(t, keeper != null and phase == "bell" and not keeper.is_alive(), "sermon", "bell", "kill", "the called keeper killed (phase %s)" % phase)
	ClarityKit.done(s)


# --- The Vigil Flame ----------------------------------------------------------------------------------------------------

## Wren has come and stands by the lantern; every Faithful but the Vigil's three is away.
static func _vigil_ready(d: VigilFlameDirector) -> void:
	d._wren_comes()
	Kit.arrive(d.wren, d._lantern + Vector2(0.5, 0.0))
	d.wren.go_duty(d.wren.ground_pos)
	var walkers := d.vigil.walkers()
	for f in d.faithful:
		if not walkers.has(f):
			Kit.arrive(f, d._lantern + Vector2(60.0, 60.0))
	for i in d.vigil.acolytes.size():
		Kit.arrive(d.vigil.acolytes[i], d._lantern + (VigilRoute.ACOLYTE_OFFSETS[i % 2] as Vector2))


static func _swap_with(s: Dictionary, d: VigilFlameDirector, verb: String, light := false) -> void:
	s["to"] = d._lantern
	if light:
		s["light"] = d._lantern
	ClarityKit.apply(s, verb, d.wren)
	_run(s, VigilFlameDirector.SWAP_SECONDS + 2.0)


static func _vigil(t) -> void:
	# "": the acolytes led or confused off, Wren swaps unseen; left as they are, they see it.
	var s := ClarityKit.world(MissionBook.vigil_flame())
	var d: VigilFlameDirector = s.d
	t.check(absf(d.hint_seconds() - VigilFlameDirector.WREN_AT) < 1.0 and d.hint_phase() == "", "vigil_flame: the first step counts down to Wren (%.1f)" % d.hint_seconds())
	_vigil_ready(d)
	t.check(d.hint_seconds() == 0.0, "vigil_flame: and stops once he has come")
	_swap_with(s, d, "lead")
	var seen_when_left := d.swapped and d.swap_seen
	ClarityKit.done(s)
	for verb: String in ["lead", "confuse"]:
		s = ClarityKit.world(MissionBook.vigil_flame())
		d = s.d
		_vigil_ready(d)
		for a in d.vigil.acolytes:
			ClarityKit.apply(s, verb, a)
		_swap_with(s, d, "lead")
		_prove(t, seen_when_left and d.swapped and not d.swap_seen and d.reports.is_empty(), "vigil_flame", "", verb,
			"the acolytes %sed off: the swap is unseen; left alone it is seen (%s)" % [verb, seen_when_left])
		ClarityKit.done(s)
	# Wren: led to the flame, he swaps it; so does a light.
	s = ClarityKit.world(MissionBook.vigil_flame())
	d = s.d
	_vigil_ready(d)
	for a in d.vigil.acolytes:
		Kit.arrive(a, d._lantern + Vector2(30.0, 30.0))
	var phase := d.hint_phase()
	_swap_with(s, d, "lead")
	_prove(t, phase == "wren" and d.swapped and not d.swap_seen, "vigil_flame", "wren", "lead", "Wren led to the flame swaps it (phase %s)" % phase)
	# carry: led to the shrine he brings it home.
	phase = d.hint_phase()
	s["to"] = d.shrine
	ClarityKit.apply(s, "lead", d.wren)
	Kit.arrive(d.wren, d.shrine + Vector2(0.4, 0.0))
	_run(s, 0.5)
	_prove(t, phase == "carry" and d.home, "vigil_flame", "carry", "lead", "Wren led to Mira's shrine brings the flame home (phase %s)" % phase)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.vigil_flame())
	d = s.d
	_vigil_ready(d)
	for a in d.vigil.acolytes:
		Kit.arrive(a, d._lantern + Vector2(30.0, 30.0))
	_swap_with(s, d, "lure", true)
	_prove(t, d.swapped, "vigil_flame", "wren", "lure", "a light at the flame draws Wren to swap it")
	ClarityKit.done(s)
	# homeward: the Vigil turns for home; led to the flame he still swaps it first.
	s = ClarityKit.world(MissionBook.vigil_flame())
	d = s.d
	Kit.arrive(d.vigil.bearer, d.temple_door + Vector2(0.0, 9.0))
	Kit.run_for(s, 0.1)
	_vigil_ready(d)
	for a in d.vigil.acolytes:
		Kit.arrive(a, d._lantern + Vector2(30.0, 30.0))
	d._route_home()
	phase = d.hint_phase()
	_swap_with(s, d, "lead")
	_prove(t, phase == "homeward" and d.swapped and not d.kept, "vigil_flame", "homeward", "lead", "the Vigil going home (phase %s): Wren leads the swap (swapped %s kept %s)" % [phase, d.swapped, d.kept])
	ClarityKit.done(s)
	# Why-nots.
	s = ClarityKit.world(MissionBook.vigil_flame())
	d = s.d
	_vigil_ready(d)
	s["to"] = d._lantern
	ClarityKit.apply(s, "lead", d.wren)
	var key := "whisper"
	t.check(d.why_not(key, s.at) == VigilFlameDirector.WHY_SEEN and d.why_not(key, _far(key, s.at)) == "",
		"vigil_flame: a lead of Wren with an acolyte by says %s (got '%s')" % [VigilFlameDirector.WHY_SEEN, d.why_not(key, s.at)])
	ClarityKit.assert_read_only(t, s, "vigil_flame")
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.vigil_flame())
	d = s.d
	_vigil_ready(d)
	for a in d.vigil.acolytes:
		(a as Person).confuse(60.0)
	s["to"] = d._lantern
	ClarityKit.apply(s, "lead", d.wren)
	t.check(d.why_not(key, s.at) == "", "vigil_flame: with the acolytes confused the lead counts: no banner (got '%s')" % d.why_not(key, s.at))
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.vigil_flame())
	d = s.d
	_vigil_ready(d)
	var boy: Person = null
	for p in (s.crowd as Crowd).citizens:
		if p != d.wren and not d.faithful.has(p) and MissionDirector._alive(p):
			boy = p
			break
	Kit.arrive(boy, d._lantern + Vector2(0.5, 0.0))
	s["to"] = d._lantern
	ClarityKit.apply(s, "lead", boy)
	t.check(d.why_not(key, s.at) == VigilFlameDirector.WHY_ONLY_WREN and d.why_not(key, _far(key, s.at)) == "",
		"vigil_flame: a lead of anyone else to the flame says %s (got '%s')" % [VigilFlameDirector.WHY_ONLY_WREN, d.why_not(key, s.at)])
	_run(s, VigilFlameDirector.SWAP_SECONDS + 2.0)
	t.check(not d.swapped, "vigil_flame: and the banner is true: no one else takes it")
	ClarityKit.done(s)


# --- The Relic Run ------------------------------------------------------------------------------------------------------

## The cart at its `k`th checkpoint, its people set down at it (headless people never walk).
static func _halt(s: Dictionary, d: RelicRunDirector, k: int) -> void:
	if not d.set_out:
		d._set_out_cart()
	d.vigil.leg = int(RelicRunDirector.HALT_LEGS[k]) - d._leg_base
	var at := d.checkpoints[k]
	Kit.arrive(d.vigil.bearer, at)
	for i in d.vigil.acolytes.size():
		Kit.arrive(d.vigil.acolytes[i], at + (VigilRoute.ACOLYTE_OFFSETS[i % 2] as Vector2))
	Kit.run_for(s, 0.1)


static func _relic(t) -> void:
	# Pip led to the cart at a halt, the watch away: he boards (the first and the last halt).
	for row: Array in [["", 0], ["last_halt", 1]]:
		var s := ClarityKit.world(MissionBook.relic_run())
		var d: RelicRunDirector = s.d
		if int(row[1]) == 1:
			d.halts_done[0] = true
		_halt(s, d, int(row[1]))
		for w in d.watchers_now():
			w.confuse(60.0)
		Kit.arrive(d.wren, d.cart_at() + Vector2(0.5, 0.0))
		s["to"] = d.cart_at()
		ClarityKit.apply(s, "lead", d.wren)
		_run(s, RelicRunDirector.BOARD + 1.0)
		_prove(t, d.halt >= 0 and d.aboard, "relic_run", String(row[0]), "lead", "Pip led to the halted unwatched cart slips aboard")
		ClarityKit.done(s)
	# The watch: each verb takes a watcher out of the count (the same rule holds in moving, watched and aboard).
	for phase: String in ["moving", "watched", "aboard"]:
		for verb: String in ["lead", "confuse", "kill"]:
			var s := ClarityKit.world(MissionBook.relic_run())
			var d: RelicRunDirector = s.d
			_halt(s, d, 0)
			var all := d.watchers_now()
			var w: Person = all[0] if not all.is_empty() else null
			var before := d.watched()
			if w != null:
				ClarityKit.apply(s, verb, w)
			_prove(t, w != null and before and not d.watchers_now().has(w), "relic_run", phase, verb,
				"a watcher is out of the count (%d watched before)" % all.size())
			ClarityKit.done(s)
	# A lure: before Pip follows the god's light the watch answers none (banner); after, it walks off to it.
	var s := ClarityKit.world(MissionBook.relic_run())
	var d: RelicRunDirector = s.d
	_halt(s, d, 0)
	var w: Person = d.watchers_now()[0]
	s["light"] = w.ground_pos + Vector2(2.5, 0.0)
	ClarityKit.apply(s, "lure", w)
	var refused := not bool(s.took)
	t.check(refused and d.why_not("wisp", s.at) == RelicRunDirector.WHY_NO_LURE and d.why_not("wisp", _far("wisp", s.at)) == "",
		"relic_run: a lure of the watch before Pip follows says %s and is refused (got '%s')" % [RelicRunDirector.WHY_NO_LURE, d.why_not("wisp", s.at)])
	ClarityKit.assert_read_only(t, s, "relic_run")
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.relic_run())
	d = s.d
	_halt(s, d, 0)
	d.pip_led = true
	d._watch_answers()
	w = d.watchers_now()[0]
	s["light"] = w.ground_pos + (w.ground_pos - d.cart_at()).normalized() * 2.5
	ClarityKit.apply(s, "lure", w)
	_prove(t, bool(s.took) and w.lured() and w.goal().distance_to(d.cart_at()) > RelicRunDirector.WATCH and d.why_not("wisp", s.at) == "",
		"relic_run", "watched", "lure", "once Pip follows, a light draws a watcher away from the cart (no banner)")
	ClarityKit.done(s)
	# Carry: Pip led to your believers' house brings the relic home.
	s = ClarityKit.world(MissionBook.relic_run())
	d = s.d
	_halt(s, d, 1)
	d.swapped = true
	d.aboard = false
	Kit.arrive(d.wren, d.shrine + Vector2(0.4, 0.0))
	s["to"] = d.shrine
	ClarityKit.apply(s, "lead", d.wren)
	_run(s, 0.5)
	_prove(t, d.home, "relic_run", "carry", "lead", "Pip led to the believers' house brings the relic home")
	ClarityKit.done(s)
	# Report and bell: kill unseen.
	s = ClarityKit.world(MissionBook.relic_run())
	d = s.d
	var seer: Person = d.escorts[0]
	for f in d.faithful:
		if f != seer:
			Kit.arrive(f, d.temple_door + Vector2(40.0, 0.0))
	Kit.arrive(seer, d.temple_door + Vector2(0.0, 25.0))
	d._report(seer, d.temple_door)
	var report: TempleReport = d.reports[0]
	var phase := d.hint_phase()
	ClarityKit.apply(s, "kill", seer)
	_run(s, 0.6)
	_prove(t, phase == "report" and not report.is_open(), "relic_run", "report", "kill", "the runner killed unseen ends the report (phase %s)" % phase)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.relic_run())
	d = s.d
	s.crowd.bell.call_keeper()
	var keeper := d.bellkeeper()
	phase = d.hint_phase()
	if keeper != null:
		ClarityKit.apply(s, "kill", keeper)
		_run(s, 0.6)
	_prove(t, keeper != null and phase == "bell" and not keeper.is_alive(), "relic_run", "bell", "kill", "the called keeper killed (phase %s)" % phase)
	ClarityKit.done(s)
	# Citadel (Q6): nothing saves the relic once the last halt has passed -- a cart stood by its dead hands lets Pip board no more.
	s = ClarityKit.world(MissionBook.relic_run())
	d = s.d
	d.halts_done[0] = true
	d.halts_done[1] = true
	d._set_out_cart()
	Kit.run_for(s, 0.1)
	phase = d.hint_phase()
	for v: Variant in [d.carter] + d.escorts:
		ClarityKit.apply(s, "kill", v)
	Kit.arrive(d.wren, d.cart_at() + Vector2(0.5, 0.0))
	_run(s, RelicRunDirector.RELIEF_AFTER + RelicRunDirector.BOARD + 4.0)
	t.check(phase == "citadel" and not d.aboard and not d.swapped and d.halt < 0,
		"relic_run: past the last halt (phase %s) Pip cannot board, even at a cart stood by its dead hands: the step says the relic is lost" % phase)
	ClarityKit.done(s)


# --- Broken Lanterns ----------------------------------------------------------------------------------------------------

## A broken lantern draining at the bearer's feet's end: the bearer walks to it, the Vigil stepped by hand.
static func _bearer_run(verb: String) -> Dictionary:
	var s := ClarityKit.world(MissionBook.broken_lanterns())
	var d: BrokenLanternsDirector = s.d
	var sh: Structure = d.shrines[0]
	sh.destroy(sh.center(), &"smite")
	var b: Person = d.vigil.bearer
	var who: Array = [b] + d.vigil.acolytes
	var start := d._walkable(d.relight_point(sh) + Vector2(5.0, 0.0))
	Kit.arrive(b, start)
	for i in d.vigil.acolytes.size():
		Kit.arrive(d.vigil.acolytes[i], start + (VigilRoute.ACOLYTE_OFFSETS[i % 2] as Vector2))
	_run(s, 0.6, who)
	if verb != "":
		s["to"] = start + Vector2(6.0, 0.0)
		ClarityKit.apply(s, verb, b)
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 2.0, who)
	var out := {"relit": d.relit, "drained": d.is_drained(sh)}
	ClarityKit.done(s)
	return out


static func _lanterns(t) -> void:
	# "": a strike breaks an unguarded lantern, and it drains; led away for the whole drain, the bearer does not relight it.
	var s := ClarityKit.world(MissionBook.broken_lanterns())
	var d: BrokenLanternsDirector = s.d
	var sh: Structure = d.shrines[0]
	ClarityKit.apply(s, "strike", sh)
	_run(s, 0.2)
	_prove(t, sh.destroyed and d.draining(sh), "broken_lanterns", "", "strike", "an unguarded lantern struck down breaks and drains")
	ClarityKit.done(s)
	var left := _bearer_run("")
	var led := _bearer_run("lead")
	_prove(t, int(left.relit) == 1 and int(led.relit) == 0 and bool(led.drained), "broken_lanterns", "", "lead",
		"left alone the bearer relights it; led away he does not and it drains (%s / %s)" % [left, led])
	# Knights.
	s = ClarityKit.world(MissionBook.broken_lanterns())
	d = s.d
	d._knights_come()
	var k: Person = d.knights[0]
	sh = d.guarding[k]
	Kit.arrive(k, d._guard_place(sh, k))
	t.check(d.guarded(sh) and d.hint_phase() == "knights", "broken_lanterns: a Knight by the lantern: guarded, the knights phase")
	# Strike on a guarded lantern only shakes it, and says why; the same cast far away says nothing.
	ClarityKit.apply(s, "strike", sh)
	t.check(not sh.destroyed and d.why_not("smite", sh.center()) == BrokenLanternsDirector.WHY_SHIELDED and d.why_not("smite", _far("smite", sh.center())) == "",
		"broken_lanterns: a blow on a guarded lantern says %s and only shakes it (got '%s')" % [BrokenLanternsDirector.WHY_SHIELDED, d.why_not("smite", sh.center())])
	ClarityKit.assert_read_only(t, s, "broken_lanterns")
	# Confuse or a compel on the Knight: he stays by it (banner); the same cast far away says nothing.
	ClarityKit.apply(s, "hold", k)
	_run(s, 1.0, [k])
	t.check(d.guarded(sh) and d.why_not("oath", k.ground_pos) == BrokenLanternsDirector.WHY_STANDS and d.why_not("oath", _far("oath", k.ground_pos)) == "",
		"broken_lanterns: a hold on a Knight says %s and he still guards it (got '%s')" % [BrokenLanternsDirector.WHY_STANDS, d.why_not("oath", k.ground_pos)])
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.broken_lanterns())
	d = s.d
	d._knights_come()
	k = d.knights[0]
	sh = d.guarding[k]
	Kit.arrive(k, d._guard_place(sh, k))
	ClarityKit.apply(s, "confuse", k)
	var told := d.why_not("discord", k.ground_pos)
	_run(s, 6.0, [k])
	t.check(told == BrokenLanternsDirector.WHY_STANDS and d.guarded(sh) and not bool(s.get("refused")),
		"broken_lanterns: a confused Knight stands by the lantern (said '%s', still guarding %s, at %.1f)" % [told, d.guarded(sh), k.ground_pos.distance_to(sh.center())])
	ClarityKit.done(s)
	# A lure takes no soldier at his post: the hint does not promise it.
	s = ClarityKit.world(MissionBook.broken_lanterns())
	d = s.d
	d._knights_come()
	k = d.knights[0]
	sh = d.guarding[k]
	Kit.arrive(k, d._guard_place(sh, k))
	s["light"] = k.ground_pos + Vector2(2.5, 0.0)
	ClarityKit.apply(s, "lure", k)
	t.check(not bool(s.took), "broken_lanterns: a light does not draw a Knight off his post")
	ClarityKit.done(s)
	# The same two casts for real (ruling R2): a Knight refuses the light, so the HUD says he stands by it; a blow on his lantern says it is shielded.
	s = ClarityKit.world(MissionBook.broken_lanterns())
	d = s.d
	d._knights_come()
	k = d.knights[0]
	sh = d.guarding[k]
	Kit.arrive(k, d._guard_place(sh, k))
	var hud := ClarityKit.attach_hud(s)
	ClarityKit.cast_real(s, "wisp", k.ground_pos + Vector2(2.5, 0.0))
	t.check(hud.banners() == PackedStringArray([BrokenLanternsDirector.WHY_STANDS]) and not k.lured() and d.guarded(sh),
		"broken_lanterns: the real Wisp by a Knight: he is not drawn, and the HUD says %s (%s)" % [BrokenLanternsDirector.WHY_STANDS, hud.banners()])
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.broken_lanterns())
	d = s.d
	d._knights_come()
	k = d.knights[0]
	sh = d.guarding[k]
	Kit.arrive(k, d._guard_place(sh, k))
	hud = ClarityKit.attach_hud(s)
	var fx := ClarityKit.cast_real(s, "smite", sh.center())
	t.check(hud.banners() == PackedStringArray([BrokenLanternsDirector.WHY_SHIELDED]), "broken_lanterns: the real Smite on a guarded lantern: the HUD says %s (%s)" % [BrokenLanternsDirector.WHY_SHIELDED, hud.banners()])
	for i in 20:
		fx._process(0.1)
	t.check(not sh.destroyed, "broken_lanterns: and the real blow only shakes it")
	ClarityKit.done(s)
	for verb: String in ["kill", "lead"]:
		s = ClarityKit.world(MissionBook.broken_lanterns())
		d = s.d
		d._knights_come()
		k = d.knights[0]
		sh = d.guarding[k]
		Kit.arrive(k, d._guard_place(sh, k))
		var guard_before := d.guarded(sh)
		s["to"] = k.ground_pos + Vector2(6.0, 0.0)
		s["light"] = k.ground_pos + Vector2(2.5, 0.0)
		ClarityKit.apply(s, verb, k)
		_run(s, 14.0, [k])
		_prove(t, guard_before and d.guard_of(sh) == null, "broken_lanterns", "knights", verb, "the Knight is off the lantern after it (took %s)" % s.took)
		if verb == "kill":
			ClarityKit.apply(s, "strike", sh)
			_run(s, 0.2)
			_prove(t, sh.destroyed, "broken_lanterns", "knights", "strike", "with the Knight gone, the strike breaks the lantern")
		ClarityKit.done(s)


# --- The First Taste ----------------------------------------------------------------------------------------------------

## The crowd, everyone the director keeps at an errand, and the rules.
static func _step(s: Dictionary) -> void:
	(s.crowd as Crowd).advance(DT)
	var d: FirstTasteDirector = s.d
	var seen := {}
	for p: Variant in d._held_people():
		if is_instance_valid(p) and not seen.has(p):
			seen[p] = true
			(p as Person).tick(DT)
	(s.rules as Rules).advance(DT)


static func _taste_run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		_step(s)


## A captive chained by the post and gripped; returns the gripper, or null.
static func _gripped(s: Dictionary) -> Person:
	var d: FirstTasteDirector = s.d
	var v: Person = d.marked[0]
	Kit.arrive(v, d._walkable(BY_POST))
	v.go_duty(v.ground_pos)
	d.chain(v)
	for i in roundi(6.0 / DT):
		_step(s)
		if d.grip_by != null:
			break
	return d.grip_by


static func _kneel_all(m: FirstTasteDirector.March, d: FirstTasteDirector) -> void:
	m.walking = true
	m.muster_left = 0.0
	for p in m.people:
		m.spots[p] = d._kneel_spot(m, m.people.find(p))
		m.paused[p] = false
		Kit.arrive(p, m.spots[p])
		p.go_duty(p.ground_pos)


static func _taste(t) -> void:
	for verb: String in ["hold", "kill"]:
		var s := ClarityKit.world(MissionBook.first_taste())
		var d: FirstTasteDirector = s.d
		var by := _gripped(s)
		var phase := d.hint_phase()
		var grip := d.grip
		if by != null:
			ClarityKit.apply(s, verb, by)
			_taste_run(s, 0.6)
		_prove(t, by != null and phase == "drag" and grip > 0.0 and d.grip_by != by and d.grip < grip, "first_taste", "drag", verb,
			"the gripper %s: his grip is off (phase %s, grip %.2f -> %.2f)" % [verb, phase, grip, d.grip])
		ClarityKit.done(s)
	# March: of two marchers one killed or frightened ends it; a hold only loses time (banner).
	for verb: String in ["kill", "scare"]:
		var s := ClarityKit.world(MissionBook.first_taste())
		var d: FirstTasteDirector = s.d
		d.offer(d.marked[0])
		var m: FirstTasteDirector.March = d.marches[0]
		_taste_run(s, FirstTasteDirector.MARCH_AFTER + 1.0)
		var phase := d.hint_phase()
		ClarityKit.apply(s, verb, m.people[1])
		_taste_run(s, 0.8)
		_prove(t, phase == "march" and m.done, "first_taste", "march", verb, "one of two %s: the march is broken (phase %s)" % [verb, phase])
		ClarityKit.done(s)
	var s := ClarityKit.world(MissionBook.first_taste())
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	var m: FirstTasteDirector.March = d.marches[0]
	_taste_run(s, FirstTasteDirector.MARCH_AFTER + 1.0)
	var held: Person = m.people[1]
	ClarityKit.apply(s, "hold", held)
	_taste_run(s, 0.4)
	t.check(d.why_not("oath", s.at) == FirstTasteDirector.WHY_HELD and d.why_not("oath", _far("oath", s.at)) == "" and not m.done and m.people.has(held),
		"first_taste: a hold on a marcher says %s and the march goes on (got '%s')" % [FirstTasteDirector.WHY_HELD, d.why_not("oath", s.at)])
	t.check(d.why_not("smite", s.at) == "" and d.why_not("doom", s.at) == "", "first_taste: a kill or a fright on him says nothing")
	ClarityKit.assert_read_only(t, s, "first_taste")
	ClarityKit.done(s)
	# Cleanse: one of two kneelers killed or frightened stops the ring.
	for verb: String in ["kill", "scare"]:
		s = ClarityKit.world(MissionBook.first_taste())
		d = s.d
		d.offer(d.marked[0])
		m = d.marches[0]
		_kneel_all(m, d)
		_taste_run(s, 1.0)
		var running := d.cleansing() and d.hint_phase() == "cleanse"
		ClarityKit.apply(s, verb, m.people[0])
		_taste_run(s, 0.8)
		_prove(t, running and not d.cleansing() and d.cleanse == 0.0, "first_taste", "cleanse", verb,
			"the ring runs, then a kneeler %s: it stops (phase before: cleanse %s)" % [verb, running])
		ClarityKit.done(s)


# --- Colours and fit ------------------------------------------------------------------------------------------------------

## The colour a tag's colour is read as: the nearest of LegendPanel's five within 70 (Wren's and the flame's own are a shade off the legend's).
static func _name_of(c: Color) -> String:
	var best := ""
	var best_d := 70.0
	for n: String in ClarityKit.COLOURS:
		var k: Color = ClarityKit.COLOURS[n]
		var dist := Vector3(c.r - k.r, c.g - k.g, c.b - k.b).length() * 255.0
		if dist < best_d:
			best_d = dist
			best = n
	return best


## Each "(gold)" ... in `text` is the colour of a tag `d` draws now.
static func _colours_ok(t, d: MissionDirector, text: String, label: String) -> void:
	var drawn := PackedStringArray()
	for m in d.tags():
		var n := _name_of(m.color)
		if n != "" and not drawn.has(n):
			drawn.append(n)
	var re := RegEx.create_from_string("\\((gold|orange|red|blue|grey)\\)")
	var bad := PackedStringArray()
	for hit in re.search_all(text):
		if not drawn.has(hit.get_string(1)):
			bad.append(hit.get_string(1))
	t.check(bad.is_empty(), "%s: every colour named is a tag drawn (%s; drawn %s)" % [label, ", ".join(bad), ", ".join(drawn)])


## The texts of `id` at `phase` (its step and its hint), each colour word checked against the tags of the world `s` stands in.
static func _check_texts(t, id: String, phase: String, s: Dictionary) -> void:
	for text in ClarityKit.texts(id, phase):
		_colours_ok(t, s.d, text, "%s/%s" % [id, phase])


static func _colours(t) -> void:
	var s := ClarityKit.world(MissionBook.first_prayers())
	var d: FirstPrayersDirector = s.d
	_check_texts(t, "first_prayers", "", s)
	_watch(d)
	_check_texts(t, "first_prayers", "watched", s)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.miras_house())
	var md: MirasHouseDirector = s.d
	_watch(md)
	_check_texts(t, "miras_house", "", s)
	md.believers.append(md.grieving[0])
	_check_texts(t, "miras_house", "burning", s)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.sermon())
	var sd: SermonDirector = s.d
	for ph in ["", "rapt", "watched", "coming"]:
		_check_texts(t, "sermon", ph, s)
	var seer: Person = sd.acolytes[0]
	sd._report(seer, sd.temple_door)
	_check_texts(t, "sermon", "report", s)
	s.crowd.bell.call_keeper()
	_check_texts(t, "sermon", "bell", s)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.vigil_flame())
	var vd: VigilFlameDirector = s.d
	_check_texts(t, "vigil_flame", "", s)
	_vigil_ready(vd)
	for ph in ["wren", "carry"]:
		_check_texts(t, "vigil_flame", ph, s)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.relic_run())
	var rd: RelicRunDirector = s.d
	_check_texts(t, "relic_run", "", s)
	_halt(s, rd, 0)
	for ph in ["moving", "watched", "aboard", "carry", "last_halt", "citadel"]:
		_check_texts(t, "relic_run", ph, s)
	rd.halts_done[1] = true
	_check_texts(t, "relic_run", "citadel", s)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.broken_lanterns())
	var bd: BrokenLanternsDirector = s.d
	_check_texts(t, "broken_lanterns", "", s)
	bd._knights_come()
	_check_texts(t, "broken_lanterns", "knights", s)
	ClarityKit.done(s)
	s = ClarityKit.world(MissionBook.first_taste())
	var fd: FirstTasteDirector = s.d
	_check_texts(t, "first_taste", "chain", s)
	fd.offer(fd.marked[0])
	_check_texts(t, "first_taste", "march", s)
	_check_texts(t, "first_taste", "drag", s)
	_check_texts(t, "first_taste", "cleanse", s)
	ClarityKit.done(s)


## Every new line, its {n} filled with a three-digit number, still fits the plate (pre-flight minor 11).
static func _fit(t) -> void:
	var long := PackedStringArray()
	for id: String in IDS:
		for phase in ClarityKit.phases_of(id):
			var text := MissionHints.filled(MissionHints.line(id, phase), 999.0)
			if text != "" and UiTheme.wrap(text, Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
				long.append("%s/%s" % [id, phase])
	t.check(long.is_empty(), "every hint of the group fits the plate with its seconds filled (too long: %s)" % ", ".join(long))
