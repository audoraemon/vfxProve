extends RefCounted
## The loss warning (Discord idea "More Effect on Losing situation"): ThreatAlert's one big hit, then the reminder, and each director's threats()
## -- empty while the night is safe, and the director's own countdown once its night-ending thing runs. Worlds are the directors' own tests'.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const H := preload("res://tests/test_herald.gd")
const SW := preload("res://tests/test_silence_witness.gd")
const EI := preload("res://tests/test_expel_inquisitor.gd")
const BH := preload("res://tests/test_break_hunt.gd")
const FH := preload("res://tests/test_face_halcyon.gd")
const HF := preload("res://tests/test_hide_faithful.gd")
const DT := 0.05


static func run(t) -> void:
	_states(t)
	_hidden(t)
	_flicker(t)
	_kick(t)
	_card_text(t)
	_herald(t)
	_starfall(t)
	_witness(t)
	_captain(t)
	_standard(t)
	_pyre(t)
	_seized(t)
	_eye(t)
	_bell_gaze(t)
	_report(t)
	_deadline(t)


static func _threat(id: StringName, eta: float) -> Array:
	return [NightThreat.make(id, "THE HERALD REACHES THE TEMPLE", "STOP HIM", eta)]


## The state machine: idle with nothing or a far threat; the card and one alarm at WARN_AT; the edge after CARD_SECONDS, no second alarm; idle once
## gone; a new id is a new hit; the night over hides it for good.
static func _states(t) -> void:
	var a := ThreatAlert.new()
	a.tick(DT, [])
	t.check(a.state == ThreatAlert.State.IDLE and not a.visible and a.stings == 0, "no threat: idle, nothing shown")
	a.tick(DT, _threat(&"a", 20.0))
	t.check(a.state == ThreatAlert.State.IDLE and not a.visible and a.stings == 0, "a threat 20 s out: still idle")
	var asked := UiSound.asked.size()
	a.tick(DT, _threat(&"a", 14.0))
	t.check(a.card_shown() and a.stings == 1 and UiSound.asked.size() > 0 and UiSound.asked[-1] == ThreatAlert.CUE,
		"14 s out: the card slams in with the alarm (%s, %d stings)" % [a.state, a.stings])
	t.check(asked >= 0 and String(a.current.title) == "THE HERALD REACHES THE TEMPLE", "and shows the threat")
	var n := ceili(ThreatAlert.CARD_SECONDS / DT) + 1
	for i in n:
		a.tick(DT, _threat(&"a", 14.0 - DT * (i + 1)))
	t.check(a.edge_shown() and a.stings == 1, "after %.1f s the card goes and the edge pulse stays, with no second alarm" % ThreatAlert.CARD_SECONDS)
	a.tick(DT, _threat(&"a", ThreatAlert.WARN_AT + 1.0))
	t.check(a.edge_shown(), "a warned threat jittering just past WARN_AT stays warned (hysteresis)")
	a.tick(DT, [])
	t.check(a.state == ThreatAlert.State.IDLE and not a.visible, "the threat gone: idle")
	for i in ceili(ThreatAlert.FORGET / DT) + 1:
		a.tick(DT, [])
	a.tick(DT, _threat(&"b", 10.0))
	t.check(a.card_shown() and a.stings == 2, "a new threat: its own hit")
	a.tick(DT, _threat(&"c", 4.0) + _threat(&"b", 9.9))
	t.check(a.card_shown() and a.stings == 3 and a.current.id == &"c", "a sooner new one while the card is up: a hit of its own")
	var rules := Rules.new()
	a.setup(rules)
	rules.over.emit(false, "lantern")
	a.tick(DT, _threat(&"d", 3.0))
	t.check(not a.visible and a.state == ThreatAlert.State.IDLE and a.stings == 3, "the night over: hidden, and nothing more is warned")
	rules.free()
	a.free()


## Hidden (the interface off), a threat is still followed, silently: when shown again it is the reminder, no late hit.
static func _hidden(t) -> void:
	var a := ThreatAlert.new()
	a.tick(DT, _threat(&"a", 12.0), false)
	t.check(not a.visible and a.state == ThreatAlert.State.CARD and a.stings == 0, "hidden: followed, but no card shown and no alarm")
	for i in ceili(ThreatAlert.CARD_SECONDS / DT) + 1:
		a.tick(DT, _threat(&"a", 12.0), false)
	a.tick(DT, _threat(&"a", 9.0), true)
	t.check(a.edge_shown() and a.stings == 0, "shown again: only the edge, the hit is not played late")
	a.free()


## The same threat comes back after another was soonest a moment: no second hit; after it was gone longer than FORGET, it hits again.
static func _flicker(t) -> void:
	var a := ThreatAlert.new()
	a.tick(DT, _threat(&"a", 12.0))
	a.tick(DT, _threat(&"a", 12.0) + _threat(&"b", 8.0))
	a.tick(DT, _threat(&"a", 11.9))
	t.check(a.state == ThreatAlert.State.EDGE and a.current.id == &"a" and a.stings == 2, "a, then b sooner (its own hit), then a again: a is the reminder")
	for i in ceili(ThreatAlert.FORGET / DT) + 2:
		a.tick(DT, _threat(&"a", 30.0))
	a.tick(DT, _threat(&"a", 12.0))
	t.check(a.card_shown() and a.stings == 3, "a went away (beyond CLEAR_AT) and came back: a new hit")
	a.free()


## The kick moves the world's picture, never the camera, and puts it back where it was.
static func _kick(t) -> void:
	var a := ThreatAlert.new()
	var pic := Control.new()
	pic.position = Vector2(0.0, 0.0)
	a.setup(null, pic)
	a.tick(DT, _threat(&"a", 10.0))
	a._step_kick(DT)
	t.check(pic.position.y > 0.0, "the hit kicks the picture down (%.1f)" % pic.position.y)
	for i in ceili(ThreatAlert.KICK_SECONDS / DT) + 1:
		a._step_kick(DT)
	t.check(pic.position == Vector2.ZERO, "and it springs back to rest (%s)" % pic.position)
	a.tick(DT, _threat(&"b", 9.0))
	a._step_kick(DT)
	a.finish()
	t.check(pic.position == Vector2.ZERO and not a.visible, "the night over mid-kick: the picture is put back")
	pic.free()
	a.free()


static func _card_text(t) -> void:
	t.check(ThreatAlert.act_line(NightThreat.make(&"x", "T", "STOP HIM", 11.2)) == "STOP HIM - 12 SECONDS"
		and ThreatAlert.act_line(NightThreat.make(&"x", "T", "STOP HIM", 0.4)) == "STOP HIM - 1 SECOND", "the card's countdown line")
	var s := NightThreat.suffixed([NightThreat.make(&"herald", "T", "A", 3.0)], "2")
	t.check(s[0].id == &"herald_2" and NightThreat.soonest([NightThreat.make(&"a", "", "", 5.0), NightThreat.make(&"b", "", "", 2.0)]).id == &"b"
		and NightThreat.soonest([]).is_empty(), "the helpers: suffixed ids, the soonest")
	t.check(MissionDirector.new().threat().is_empty(), "a director warns of nothing by default")


static func _find(list: Array, id: StringName) -> Dictionary:
	for th: Dictionary in list:
		if th.id == id:
			return th
	return {}


## The Warning on a Herald night: nothing before the toll; the Herald's threat, as herald_eta(), once he runs.
static func _herald(t) -> void:
	var s := H._world("warning")
	var d: WarningDirector = s.d
	var rules: Rules = s.rules
	t.check(d.threats().is_empty() and rules.threat().is_empty(), "the Warning at its start: no threat")
	t.check(H._deliver(s), "(set-up) the warning is delivered")
	t.check(d.threats().is_empty(), "the bell called, not yet tolled: the toll is no loss on a Herald night, no threat")
	H._ring(s)
	H._run(s, 0.1)
	var th := d.threat()
	t.check(th.get("id", &"") == &"herald" and absf(float(th.get("eta", -1.0)) - d.herald_eta()) < 0.001 and d.herald_eta() < INF,
		"the Herald runs: his threat, at herald_eta() (%s, %.2f)" % [th, d.herald_eta()])
	t.check(rules.threat().get("id", &"") == &"herald", "Rules.threat() names him")
	d.warning_dead = true
	t.check(d.threats().is_empty(), "the warning stopped: gone")
	Kit.done(s)


## Starfall: each star's Herald numbered by its star; the keeper's own Herald is the Lantern's.
static func _starfall(t) -> void:
	var s := H._world("stars")
	var d: StarfallDirector = s.d
	var lw: LanternWatch = s.lw
	t.check(d.threats().is_empty() and lw.threats().is_empty(), "Starfall at its start: no threat")
	H._ring(s)
	H._run(s, 0.1)
	var own := lw.threats()
	t.check(own.size() == 1 and String(own[0].id).begins_with("herald_keeper_") and float(own[0].eta) < INF and d.threats().is_empty(),
		"the keeper rang with no warning: the Lantern's own Herald is a threat (%s)" % [own])
	d._clock = 7.95
	H._run(s, WarningDirector.OMEN_AT + WarningDirector.STARE + 2.5)
	var th := _find(d.threats(), &"herald_0")
	t.check(not th.is_empty() and absf(float(th.eta) - d.stars[0].herald_eta()) < 0.001, "the postern's Herald is herald_0, at its herald_eta() (%s)" % [th])
	var soon := (s.rules as Rules).threat()
	t.check(not soon.is_empty() and float(soon.eta) <= minf(float(th.eta), float(lw.threats()[0].eta)) + 0.001, "Rules.threat() is the sooner of the two")
	Kit.done(s)


## Silence the witness: nothing while the houses wait; a walking witness's word, as his eta().
static func _witness(t) -> void:
	var s := SW._world()
	var d: SilenceWitnessDirector = s.d
	t.check(d.threats().is_empty(), "every house waiting: no threat")
	var r := SW._out(s, 0)
	var th := d.threat()
	t.check(th.get("id", &"") == &"word_0" and absf(float(th.get("eta", -1.0)) - r.eta()) < 0.001 and r.eta() < INF
		and is_equal_approx(r.eta(), d.word_eta()), "the west witness walks: word_0, at his eta() (%s)" % [th])
	Kit.done(s)


## Expel the inquisitor: nothing on his round; his last walk to the Citadel, as captain_eta().
static func _captain(t) -> void:
	var s := EI._world()
	var d := EI._ei(s)
	var cap := d.captain()
	EI._out(d, cap)
	var last := cap.stops.size() - 1
	for i in last:
		EI._walk_to(s, cap, cap.stop_doors[i])
		Kit.run_for(s, ExpelInquisitorDirector.EI_VISIT + AssassinateDirector.TICK + DT)
	t.check(d.threats().is_empty() and d.captain_eta() == INF, "the captain on his round: no threat")
	EI._walk_to(s, cap, cap.stop_doors[last])
	var th := d.threat()
	t.check(th.get("id", &"") == &"captain" and absf(float(th.get("eta", -1.0)) - d.captain_eta()) < 0.001 and d.captain_eta() < INF,
		"his last visit begins: the captain's threat, at captain_eta() (%s)" % [th])
	Kit.done(s)


## Break the hunt: a standard marching while no house is taken is no threat (the first house is no loss); once one is, the next is.
static func _standard(t) -> void:
	var s := BH._world()
	var d := BH._bh(s)
	d._raise(0)
	d._raise(1)
	Kit.run_for(s, 1.0)
	t.check(d.eta(1) < INF and d.threats().is_empty(), "two standards marching, no house taken: no threat (eta %.1f)" % d.eta(1))
	d._plant(0, d._dest[0])
	var th := _find(d.threats(), &"standard_1")
	t.check(d.taken() == 1 and not th.is_empty() and absf(float(th.eta) - d.eta(1)) < 0.001, "one house taken: the second standard is a threat, at eta(1) (%s)" % [th])
	t.check(_find(d.threats(), &"standard_0").is_empty(), "the planted one is not")
	Kit.done(s)


## Face Halcyon: a believer on the stake with none burned is no threat; with one burned, he is, as burn_left().
static func _pyre(t) -> void:
	var s := FH._world()
	var d: FaceHalcyonDirector = s.d
	d._come_out(0)
	Kit.run_for(s, FaceHalcyonDirector.FH_FORM + FH.LOOK)
	FH._stand(d, 0, d.pyre_at + Vector2(0.0, 1.0))
	FH._look(s)
	t.check(d.procs[0].phase == FaceHalcyonDirector.Procession.Phase.BURNING and d.threats().is_empty(), "(set-up) bound, none burned yet: no threat")
	d.charges[1].taken = true
	var th := d.threat()
	t.check(d.burned() == 1 and th.get("id", &"") == &"pyre_0" and absf(float(th.get("eta", -1.0)) - d.burn_left(0)) < 0.001,
		"one burned: the believer on the stake is a threat, at burn_left(0) (%s)" % [th])
	Kit.done(s)


## Hide the faithful: a seized believer marched with none lost is no threat; with one lost, he is, as the strip's _temple_in().
static func _seized(t) -> void:
	var s := HF._world()
	var d: HideFaithfulDirector = s.d
	HF._clear_watch(d)
	d._come_out(0)
	Kit.run_for(s, EscortDirector.TICK + DT)
	var lead := d.lamp(0)
	var by := d.patrols[0][0] as Person
	Kit.arrive(by, (lead.man as Person).ground_pos + Vector2(1.0, 0.0))
	by.send_to_post(by.ground_pos)
	Kit.run_for(s, 2.0 * EscortDirector.TICK + DT)
	t.check(lead.held and d.threats().is_empty(), "(set-up) seized, none lost: no threat")
	var other := d.charges[d.charges.size() - 1]
	other.taken = true
	var th := d.threat()
	t.check(d.lost() == 1 and th.get("id", &"") == StringName("seized_%d" % d.charges.find(lead)) and absf(float(th.get("eta", -1.0)) - d._temple_in(lead)) < 0.001,
		"one lost: the seized believer is a threat, at the strip's time (%s)" % [th])
	Kit.done(s)


## The Lantern's Eye: nothing until the three stand; the Eye's countdown, as eye_left(); gone when a mirror shatters.
static func _eye(t) -> void:
	var s := Kit.world(MissionBook.lantern_eye())
	var d: LanternEyeDirector = s.d
	t.check(d.threats().is_empty(), "no mirror up: no threat")
	for i in 3:
		d._raise(i)
	Kit.run_for(s, DT)
	var th := d.threat()
	t.check(String(th.get("id", "")).begins_with("eye_") and absf(float(th.get("eta", -1.0)) - d.eye_left()) < 0.001, "all three standing: the Eye's threat (%s)" % [th])
	d._shatter(2)
	Kit.run_for(s, DT)
	t.check(d.threats().is_empty(), "a mirror shattered: gone")
	Kit.done(s)


## Mira's House: the bell's climb is a threat only when its toll would fill the Gaze (the Lantern's GAZE_TOLL; with no Lantern, the whole Gaze).
static func _bell_gaze(t) -> void:
	var s := Kit.world(MissionBook.miras_house())
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	var lw := LanternWatch.new().setup(rules, s.crowd, s.town, null, LanternWatch.KIND_GAZE)
	rules.lantern = lw
	var bell: BellNetwork = (s.crowd as Crowd).bell
	t.check(bell != null and MissionDirector._alive(bell.keeper) and d.threats().is_empty(), "(set-up) the bell idle: no threat")
	bell.state = BellNetwork.State.CLIMBING
	bell.progress = 2.0
	d.gaze.value = 50.0
	t.check(_find(d.threats(), &"bell").is_empty(), "the keeper climbs, Gaze 50: the toll's 40 would not fill it, no threat")
	d.gaze.value = 60.0
	var th := _find(d.threats(), &"bell")
	t.check(not th.is_empty() and absf(float(th.eta) - (bell.climb - bell.progress) * rules.clock_rate) < 0.001,
		"Gaze 60: the toll would fill it -- the bell's threat, at the climb left (%s)" % [th])
	lw.tolled = true
	t.check(_find(d.threats(), &"bell").is_empty(), "a second toll adds nothing: no threat")
	lw.tolled = false
	rules.lantern = null
	d.gaze.value = 0.0
	t.check(not _find(d.threats(), &"bell").is_empty(), "no Lantern: the toll fills the Gaze outright, a threat at any Gaze")
	rules.lantern = lw  # Rules.teardown() lets it go
	Kit.done(s)


## A Faithful's report running for the Temple on a night whose full Gaze loses it.
static func _report(t) -> void:
	var s := Kit.world(MissionBook.miras_house())
	var d: MirasHouseDirector = s.d
	var p: Person = (s.crowd as Crowd).citizens[0]
	d._report(p, d.lantern_door())
	var th := d.threat()
	t.check(String(th.get("id", "")).begins_with("report_") and float(th.get("eta", INF)) < INF and String(th.title) == "A FAITHFUL REACHES THE TEMPLE",
		"a Faithful runs to the Temple: a threat (%s)" % [th])
	d.gaze.value = GazeMeter.FULL
	t.check(d.threats().is_empty(), "the Gaze already full: nothing left to warn")
	Kit.done(s)


## A deadline on the main objective (Market Panic's market closing): its event's time, while the main objective is not done.
static func _deadline(t) -> void:
	var s := Kit.world(MissionBook.market_panic())
	var rules: Rules = s.rules
	var d: MissionDirector = s.d
	var th := _find(rules.threats(), &"deadline_close")
	t.check(d.timeline != null and not th.is_empty() and absf(float(th.eta) - d.timeline.seconds_to("close")) < 0.001 and String(th.title) == "MARKET CLOSES"
		and String(th.act).ends_with(" FIRST"), "the market's closing is a threat at its time (%s)" % [th])
	rules.main_done = true
	t.check(_find(rules.threats(), &"deadline_close").is_empty(), "the main objective done: the deadline no longer ends the night")
	rules.main_done = false
	rules.finished = true
	t.check(rules.threats().is_empty() and rules.threat().is_empty(), "the act over: nothing")
	Kit.done(s)
