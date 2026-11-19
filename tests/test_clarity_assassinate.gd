extends RefCounted
## Mission clarity, the assassinate group (spec 5.2, plan Task 3): The Informer, The Tax Collector, The Bishop and Expel the Inquisitor.
## Every verb a step or a hint of these four names has a case below that lands it through the game's own paths (ClarityKit.apply(): a kill
## through the field, a scare through Crowd.on_cast, a lead through Person.whisper, a seal through a sealed NoLeaveFx the director reads
## from Rules.last_fx()...) and checks the director's own progress moves, or that it does not and the why-not banner says why; the why-not
## rows (each text, and nothing for the same cast out of reach); the read-only proof; the colours each text names are tags drawn.
## Pre-flight rulings applied: B1 (no "scare" on a soldier: the captain and the wardens are citizens), B2 (the kit's paths), I1 (the
## Informer's why-nots: only scare, lead, lure and confuse before word; Kill and Banish say nothing), I2 (Tax Collector "ready"), I6
## (a key with several verbs is judged by all of them), I12 (Seal as he comes out), M11 (hints measured filled with 999).

const ClarityKit := preload("res://tests/clarity_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
const DT := 0.05
const State := AssassinateDirector.State

## Rows a case proved, "id/phase/verb": cases() must all appear (a row with no proof fails).
static var _proved := PackedStringArray()

## The cases: every verb a step or a hint of the four missions names, per phase (spec 5.2's "counts" column).
const ROWS := [
	["informer", "", "confuse"], ["informer", "", "lead"], ["informer", "waiting", "scare"], ["informer", "found", "kill"],
	["informer", "running", "kill"], ["informer", "hiding", "burn"],
	["tax_collector", "", "kill"], ["tax_collector", "", "banish"], ["tax_collector", "ready", "kill"],
	["tax_collector", "inside", "seal"], ["tax_collector", "hiding", "burn"], ["tax_collector", "running", "kill"],
	["tax_collector", "safe", "kill"],
	["bishop", "", "burn"], ["bishop", "", "kill"], ["bishop", "waiting", "kill"], ["bishop", "waiting", "hold"],
	["bishop", "guarded", "kill"], ["bishop", "guarded", "hold"], ["bishop", "open", "burn"], ["bishop", "square", "kill"],
	["bishop", "running", "kill"],
	["expel_inquisitor", "", "kill"], ["expel_inquisitor", "", "banish"], ["expel_inquisitor", "captain", "kill"],
	["expel_inquisitor", "captain", "scare"], ["expel_inquisitor", "near", "kill"], ["expel_inquisitor", "near", "banish"],
]
const IDS := ["informer", "tax_collector", "bishop", "expel_inquisitor"]


static func cases() -> Array:
	var out: Array = []
	for r: Array in ROWS:
		out.append({"id": r[0], "phase": r[1], "verb": r[2]})
	return out


static func run(t) -> void:
	_proved = PackedStringArray()
	_informer(t)
	_tax(t)
	_bishop(t)
	_expel(t)
	_coverage(t)
	_lines(t)


## A case proved: `ok` and the row is recorded.
static func _prove(t, ok: bool, id: String, phase: String, verb: String, msg: String) -> void:
	_proved.append("%s/%s/%s" % [id, phase, verb])
	t.check(ok, "%s/%s/%s: %s" % [id, phase if phase != "" else "(own)", verb, msg])


## Every row of cases() has its proof, every proof is a row, and the steps and hints name no verb without one.
static func _coverage(t) -> void:
	var rows := PackedStringArray()
	for r: Array in ROWS:
		rows.append("%s/%s/%s" % [r[0], r[1], r[2]])
	var unproved := PackedStringArray()
	for r in rows:
		if not _proved.has(r):
			unproved.append(r)
	t.check(unproved.is_empty(), "every case row has its proof (missing %s)" % ", ".join(unproved))
	ClarityKit.check_coverage(t, PackedStringArray(IDS), cases())


## M11: every hint of the group fits the plate filled with its longest countdown, and a step with no counter names no seconds.
static func _lines(t) -> void:
	var long := PackedStringArray()
	for key: String in MissionHints.LINES:
		var id := key.get_slice(".", 0)
		if not IDS.has(id):
			continue
		var text := MissionHints.filled(String(MissionHints.LINES[key]), 999.0)
		if UiTheme.wrap(text, Hud.HINT_W, UiTheme.TEXT_S).size() > Hud.HINT_LINES:
			long.append(key)
	t.check(long.is_empty(), "every hint of the group fits the plate filled with 999 (too long: %s)" % ", ".join(long))


## A cast of `key` far from `g` (out of its reach and margin): the same banner test for "nothing for a cast far from every target".
static func _far(key: String, g: Vector2) -> Vector2:
	return g + Vector2(Crowd._cast_radius(key) + MissionDirector.WHY_MARGIN + 2.0, 0.0)


# ---------------------------------------------------------------- The Informer

static func _informer_world() -> Dictionary:
	return ClarityKit.world(MissionBook.informer())


## Everyone out of doors who would see `c`'s contact, but those of `keep`, moved well away (test_informer's _clear).
static func _clear(d: InformerDirector, c: InformerDirector.Contact, keep: Array = []) -> void:
	var man := c.man as Person
	for p in d.onlookers(c):
		if keep.has(p):
			continue
		var off := p.ground_pos - man.ground_pos
		Kit.arrive(p, man.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * 6.0)


## Company member `k` of `c` set 1.0 east of the contact and the rest of his company well away: a cast on him alone, the cast's own point
## beyond the contact's reach.
static func _aside(c: InformerDirector.Contact, k: int) -> Person:
	var man := c.man as Person
	for i in c.company.size():
		var p := c.company[i] as Person
		Kit.arrive(p, man.ground_pos + (Vector2(1.0, 0.0) if i == k else Vector2(12.0 + i, 0.0)))
	return c.company[k] as Person


static func _informer(t) -> void:
	_inf_waiting(t)
	_inf_word(t)
	_inf_found(t)


## Before word: nothing counts, and the banner says so for a scare, a lead, a lure or a confuse on the contact or his company.
static func _inf_waiting(t) -> void:
	var s := _informer_world()
	var d: InformerDirector = s.d
	var c := d.contacts[0]
	var man := c.man as Person
	t.check(d.hint_phase() == "waiting" and absf(d.hint_seconds() - float(InformerDirector.VISIT_AT[0])) < 1.0
		and MissionSteps.line(s.rules).begins_with("Word reaches him (grey) in 0:4"),
		"waiting: the phase, the seconds to his visit and the step's count (%s, %.1f)" % [MissionSteps.line(s.rules), d.hint_seconds()])
	t.check(ClarityKit.phases_of("informer").has("waiting") and not MissionHints.line("informer", "waiting").is_empty(), "waiting has its line")
	ClarityKit.colours_ok(t, d, MissionHints.line("informer", "waiting") + " " + MissionSteps.steps("informer")[1]["t"], "informer waiting")
	ClarityKit.assert_read_only(t, s, "informer waiting")
	# The user's case: a Discord on the contact (his company confused with him) before word turns nothing, and the banner says so.
	for k in c.company.size():
		ClarityKit.apply(s, "confuse", c.company[k])
	var key := ClarityKit.apply(s, "confuse", man)
	var at: Vector2 = s.at
	t.check(d.why_not(key, at) == InformerDirector.WHY_EARLY, "a Discord on the contact before word: TOO EARLY (%s)" % d.why_not(key, at))
	t.check(d.why_not(key, _far(key, man.ground_pos)) == "", "the same cast far from him and his company says nothing")
	Kit.run_for(s, d.visit_in(0) - 1.0)
	t.check(d.turned_count() == 0 and not c.turned, "and a second before word he is still not turned")
	ClarityKit.done(s)
	# Lead on the contact, a lure and a fright on a companion.
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	man = c.man as Person
	key = ClarityKit.apply(s, "lead", man)
	t.check(d.why_not(key, s.at) == InformerDirector.WHY_EARLY and d.turned_count() == 0, "a whisper on the contact before word: TOO EARLY, nobody turned")
	key = ClarityKit.apply(s, "lure", c.company[0])
	t.check(d.why_not(key, s.at) == InformerDirector.WHY_EARLY, "a lure near his company before word: TOO EARLY")
	t.check(not bool(s.took), "and the lure never takes on a companion on duty (so the hint does not offer it)")
	ClarityKit.done(s)
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	var friend := _aside(c, 0)
	var spot := c.spots[0]
	key = ClarityKit.apply(s, "scare", friend)
	var scared := bool(s.took) and friend.mind != Person.Mind.DUTY
	t.check(d.why_not(key, s.at) == InformerDirector.WHY_EARLY, "a scare on his company before word: TOO EARLY (%s)" % d.why_not(key, s.at))
	t.check(d.why_not(key, _far(key, friend.ground_pos)) == "", "the same cast far from every one of them says nothing")
	(s.crowd as Crowd).threats.clear()  # (the fright is over)
	friend._recover(2.0)  # (his own state machine: he is on his feet)
	Kit.run_for(s, AssassinateDirector.TICK * 2.0 + DT)
	_prove(t, scared and d.turned_count() == 0 and friend.mind == Person.Mind.DUTY and friend.anchor.distance_to(spot) < 0.01,
		"informer", "waiting", "scare", "a companion scared off is sent back to his spot once on his feet, and nothing is turned (%s)" % Person.Mind.keys()[friend.mind])
	ClarityKit.done(s)
	# A kill or a lift on his company: no banner (pre-flight I1), and the director's own kill banner is not doubled.
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	key = ClarityKit.apply(s, "kill", c.company[1])
	t.check(d.why_not(key, s.at) == "", "a kill on his company says nothing")
	key = ClarityKit.apply(s, "banish", c.company[0])
	t.check(d.why_not(key, s.at) == "", "a Skylift on his company says nothing")
	ClarityKit.done(s)
	# The user's own case: a Skylift on the contact before word turns nothing and says so.
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	key = ClarityKit.apply(s, "banish", c.man)
	t.check(d.turned_count() == 0 and d.why_not(key, s.at) == InformerDirector.WHY_EARLY,
		"a Skylift on the contact before word: TOO EARLY - NO WORD YET (%s)" % d.why_not(key, s.at))
	ClarityKit.assert_read_only(t, s, "informer waiting, contact lifted")
	ClarityKit.done(s)


## After word: a Discord with his company confused, or a whisper with none by, turns him; anything else says why not.
static func _inf_word(t) -> void:
	var s := _informer_world()
	var d: InformerDirector = s.d
	var c := d.contacts[0]
	var man := c.man as Person
	d._visit(0)
	t.check(d.hint_phase() == "" and d.hint_seconds() == 0.0, "after word the phase is the mission's, with no seconds")
	ClarityKit.colours_ok(t, d, MissionHints.line("informer") + " " + MissionSteps.steps("informer")[0]["t"], "informer own")
	ClarityKit.assert_read_only(t, s, "informer after word")
	for k in c.company.size():
		ClarityKit.apply(s, "confuse", c.company[k])
	var key := ClarityKit.apply(s, "confuse", man)
	_prove(t, d.turned_count() == 1, "informer", "", "confuse", "one Discord on the contact, his company confused with him, turns him at once")
	t.check(d.why_not(key, s.at) == "", "and it says nothing")
	ClarityKit.done(s)
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	man = c.man as Person
	d._visit(0)
	_clear(d, c)
	key = ClarityKit.apply(s, "lead", man)
	_prove(t, d.turned_count() == 1, "informer", "", "lead", "a whisper on him with none of his company near turns him")
	t.check(d.why_not(key, s.at) == "", "Review Focus 5: the whisper that turned him says nothing, judged after the director's own handler")
	ClarityKit.done(s)
	# A whisper that was seen: the director's own banner, and no second one from the hook.
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	d._visit(0)
	key = ClarityKit.apply(s, "lead", c.man)
	t.check(d.turned_count() == 0 and (s.banners as Array).has(InformerDirector.SEEN_BANNER) and d.why_not(key, s.at) == "",
		"a whisper seen by an onlooker: SEEN - HE SAYS NOTHING from the director, nothing more from the hook")
	ClarityKit.done(s)
	# A Hold, a lift, a lure or a fright on the contact turns nothing.
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	man = c.man as Person
	d._visit(0)
	_clear(d, c)
	key = ClarityKit.apply(s, "hold", man)
	t.check(d.turned_count() == 0 and d.why_not(key, s.at) == InformerDirector.WHY_ONLY, "a Hold on the contact turns nothing: ONLY CONFUSE OR LEAD (%s)" % d.why_not(key, s.at))
	t.check(d.why_not(key, _far(key, man.ground_pos)) == "", "and the same cast far from him says nothing")
	key = ClarityKit.apply(s, "banish", man)
	t.check(d.turned_count() == 0 and d.why_not(key, s.at) == InformerDirector.WHY_ONLY, "a Skylift on the contact: the same")
	t.check(d.why_not("doom", man.ground_pos) == "" and d.why_not("whisper", man.ground_pos) == "" and d.why_not("discord", man.ground_pos) == "",
		"a kill, a whisper or a Discord on him is judged by the director itself")
	ClarityKit.done(s)
	# A companion frightened off walks back to his door: the banner, and the walk.
	s = _informer_world()
	d = s.d
	c = d.contacts[0]
	d._visit(0)
	var friend := _aside(c, 0)
	var spot := c.spots[0]
	key = ClarityKit.apply(s, "scare", friend)
	t.check(d.why_not(key, s.at) == InformerDirector.WHY_BACK, "a fright on his company after word: THEY WALK BACK TO HIS DOOR (%s)" % d.why_not(key, s.at))
	Kit.arrive(friend, (c.man as Person).ground_pos + Vector2(6.0, 0.0))
	t.check(d.why_not("skylift", friend.ground_pos) == "" and d.why_not("oath", friend.ground_pos) == "",
		"a Skylift or a Hold on a runner of his company, out of the contact's reach, says nothing")
	Kit.arrive(friend, (c.man as Person).ground_pos + Vector2(1.0, 0.0))
	t.check(d.why_not(key, _far(key, friend.ground_pos)) == "", "and the same cast far from every one of them says nothing")
	(s.crowd as Crowd).threats.clear()
	friend._recover(2.0)
	Kit.run_for(s, AssassinateDirector.TICK * 2.0 + DT)
	t.check(friend.mind == Person.Mind.DUTY and friend.anchor.distance_to(spot) < 0.01 and d.turned_count() == 0, "and he is sent back to his spot, nothing turned")
	ClarityKit.done(s)


## Found: kill him before the Temple; hiding: burn the house.
static func _inf_found(t) -> void:
	var s := _informer_world()
	var d: InformerDirector = s.d
	for i in d.contacts.size():
		d._visit(i)
		_clear(d, d.contacts[i])
		ClarityKit.apply(s, "lead", d.contacts[i].man)
	var q := d.quarries[0]
	t.check(d.found and d.hint_phase() == "found" and MissionSteps.line(s.rules).begins_with("Kill the informer (gold)"), "found: the phase and the step (%s)" % MissionSteps.line(s.rules))
	ClarityKit.colours_ok(t, d, MissionHints.line("informer", "found") + " " + MissionSteps.steps("informer")[2]["t"], "informer found")
	ClarityKit.assert_read_only(t, s, "informer found")
	# Hiding: alarmed, he runs for the house and is in it; the fire drives him out.
	d._alarm(q)
	Kit.arrive(q.target, d.hide_door)
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	t.check(d.hint_phase() == "hiding" and q.target.inside and MissionSteps.line(s.rules).begins_with("Burn his hiding place (gold)"),
		"hiding: the phase and the step (%s, %s)" % [d.hint_phase(), MissionSteps.line(s.rules)])
	ClarityKit.colours_ok(t, d, MissionHints.line("informer", "hiding") + " " + MissionSteps.steps("informer")[3]["t"], "informer hiding")
	ClarityKit.assert_read_only(t, s, "informer hiding")
	ClarityKit.apply(s, "burn", d.hideout)
	Kit.run_for(s, 3.0)
	_prove(t, not q.target.inside and q.state != State.HIDING, "informer", "hiding", "burn", "the house alight, he is out of doors within 3 s (%s)" % State.keys()[q.state])
	ClarityKit.done(s)
	# Found and running (no hiding place left): kill him.
	s = _informer_world()
	d = s.d
	for i in d.contacts.size():
		d._visit(i)
		_clear(d, d.contacts[i])
		ClarityKit.apply(s, "lead", d.contacts[i].man)
	q = d.quarries[0]
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead, "informer", "found", "kill", "a Doom on the found informer kills him")
	ClarityKit.done(s)
	s = _informer_world()
	d = s.d
	for i in d.contacts.size():
		d._visit(i)
		_clear(d, d.contacts[i])
		ClarityKit.apply(s, "lead", d.contacts[i].man)
	q = d.quarries[0]
	d._hideout_spent = true
	d._alarm(q)
	t.check(d.hint_phase() == "running", "running: no hiding place left")
	ClarityKit.colours_ok(t, d, MissionHints.line("informer", "running"), "informer running")
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead, "informer", "running", "kill", "a Doom on him as he runs kills him")
	ClarityKit.done(s)


## Everyone but `who` within 3 units moved well away, so a death there has no witness.
static func _clear_round(crowd: Crowd, who: Person) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != who and p.ground_pos.distance_to(who.ground_pos) <= 3.0:
				p.ground_pos = who.ground_pos + Vector2(12.0, 0.0)


# ---------------------------------------------------------------- The Tax Collector

static func _tax_world() -> Dictionary:
	return ClarityKit.world(MissionBook.tax_collector())


## `q` is out and walking in the street at the counting-house's door, with a witness a little beyond a Silent Doom's reach (so his tag shows red).
static func _tax_out(s: Dictionary, q: AssassinateDirector.Quarry, witness := true) -> void:
	var d: TaxCollectorDirector = s.d
	d._set_out(q)
	Kit.arrive(q.target, d.hide_door)
	if witness:
		var crowd: Crowd = s.crowd
		for p in crowd.citizens:
			if is_instance_valid(p) and p != q.target and not q.guards.has(p) and not d.busy(p) and not p.inside:
				Kit.arrive(p, q.target.ground_pos + Vector2(SilentDoom.RADIUS + 0.4, 0.0))
				break
	Kit.run_for(s, DT)


## The collector `q` in his first debtor's house for his visit (the first stop's door reached).
static func _tax_visit(s: Dictionary, q: AssassinateDirector.Quarry) -> void:
	var d: TaxCollectorDirector = s.d
	d._set_out(q)
	Kit.arrive(q.target, q.stop_doors[0])
	Kit.run_for(s, AssassinateDirector.TICK + DT)


static func _tax(t) -> void:
	_tax_ready_next(t)
	_tax_smoke(t)
	_tax_street(t)
	_tax_inside(t)
	_tax_hiding(t)


## The wait before the first set-out ("ready"), and the wait for the next collector after one falls ("next").
static func _tax_ready_next(t) -> void:
	var s := _tax_world()
	var d: TaxCollectorDirector = s.d
	t.check(d.hint_phase() == "ready" and absf(d.hint_seconds() - float(TaxCollectorDirector.SET_OUT_AT[0])) < 1.0
		and MissionSteps.line(s.rules).begins_with("Ambush the first collector 0:3"),
		"ready: the phase, 35 s to his set-out, the step (%s, %.1f)" % [MissionSteps.line(s.rules), d.hint_seconds()])
	ClarityKit.colours_ok(t, d, MissionHints.line("tax_collector", "ready") + " " + MissionSteps.steps("tax_collector")[2]["t"], "tax ready")
	ClarityKit.assert_read_only(t, s, "tax ready")
	Kit.run_for(s, float(TaxCollectorDirector.SET_OUT_AT[0]) + 1.0)
	var q := d.quarries[0]
	t.check(q.state != State.WAITING and d.hint_phase() != "ready", "his time comes and he sets out: the phase moves on")
	Kit.arrive(q.target, q.stop_doors[0])  # (away from the counting-house's door: a cast there smokes the next one out)
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, d.stopped() == 1, "tax_collector", "ready", "kill", "the collector who set out falls to a Doom")
	t.check(d.hint_phase() == "next" and d.hint_seconds() > 0.0 and d.hint_seconds() <= TaxCollectorDirector.CHAIN_WAIT + 1.0
		and MissionSteps.line(s.rules).begins_with("Ambush the next collector 0:"),
		"next: the phase, the seconds to the next set-out, the step (%s, %.1f)" % [MissionSteps.line(s.rules), d.hint_seconds()])
	ClarityKit.colours_ok(t, d, MissionHints.line("tax_collector", "next") + " " + MissionSteps.steps("tax_collector")[5]["t"], "tax next")
	ClarityKit.assert_read_only(t, s, "tax next")
	ClarityKit.done(s)


## A cast at the counting-house's door while none is out smokes the next collector out: the director's own handler runs first, so the
## hook, asked after it, has nothing to say (and it never says "indoors" to the cast that brought him out).
static func _tax_smoke(t) -> void:
	var s := _tax_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	(s.rules as Rules).cast_made.emit(0, "oath", d.hide_door)
	t.check(q.state != State.WAITING and d.why_not("oath", d.hide_door) == "", "a cast at the door smokes him out, and the hook says nothing after it")
	ClarityKit.done(s)
	s = _tax_world()
	d = s.d
	var far_at := d.hide_door + Vector2(0.0, d.alarm_reach + 1.5)
	t.check(d.quarries[0].state == State.WAITING and d.why_not("doom", d.hideout.center()) in ["", TaxCollectorDirector.WHY_INDOORS],
		"a cast at the house itself: smoked out, or HE IS INDOORS (%s)" % d.why_not("doom", d.hideout.center()))
	t.check(far_at.distance_to(d.hide_door) > d.alarm_reach, "(set-up)")
	ClarityKit.done(s)


## "" (on his round, in the street): kill, or banish. Then running and safe.
static func _tax_street(t) -> void:
	var s := _tax_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	_tax_out(s, q)
	t.check(d.hint_phase() == "" and MissionSteps.line(s.rules).begins_with("Kill the collector (gold) 0/3"),
		"on his round: the phase and the step (%s)" % MissionSteps.line(s.rules))
	t.check(not d.witnesses(q).is_empty(), "(set-up) a witness stands near him: the red diamond is drawn")
	ClarityKit.colours_ok(t, d, MissionHints.line("tax_collector") + " " + MissionSteps.steps("tax_collector")[0]["t"], "tax own")
	ClarityKit.assert_read_only(t, s, "tax street")
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead and d.stopped() == 1, "tax_collector", "", "kill", "a Doom on the collector in the street kills him (stopped 1)")
	ClarityKit.done(s)
	s = _tax_world()
	d = s.d
	q = d.quarries[0]
	_tax_out(s, q, false)
	ClarityKit.apply(s, "banish", q.target)
	Kit.run_for(s, 1.0)
	_prove(t, q.state == State.OUT and d.stopped() == 1, "tax_collector", "", "banish",
		"set down outside the walls he is stopped for the night (%s)" % State.keys()[q.state])
	ClarityKit.done(s)
	# Running and safe: no hiding place, then his rounds done: kill him.
	s = _tax_world()
	d = s.d
	q = d.quarries[0]
	_tax_out(s, q)
	d._hideout_spent = true
	d._alarm(q)
	t.check(d.hint_phase() == "running", "running: no hiding place, he flees for the Citadel")
	ClarityKit.colours_ok(t, d, MissionHints.line("tax_collector", "running") + " " + MissionSteps.steps("tax_collector")[4]["t"], "tax running")
	ClarityKit.assert_read_only(t, s, "tax running")
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead, "tax_collector", "running", "kill", "a Doom on him as he runs for the Citadel kills him")
	ClarityKit.done(s)
	s = _tax_world()
	d = s.d
	q = d.quarries[0]
	_tax_out(s, q)
	q.leg = q.stops.size()
	t.check(d.hint_phase() == "safe", "safe: his rounds done, he takes the taxes in")
	ClarityKit.colours_ok(t, d, MissionHints.line("tax_collector", "safe"), "tax safe")
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead, "tax_collector", "safe", "kill", "a Doom on him on the way to the Citadel kills him")
	ClarityKit.done(s)


## "inside": in a debtor's house, be at the door and seal it as he comes out with his guards away.
static func _tax_inside(t) -> void:
	var s := _tax_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	_tax_visit(s, q)
	var door: Vector2 = q.stop_doors[0]
	t.check(q.state == State.VISITING and q.target.inside and d.hint_phase() == "inside" and d.hint_seconds() > 17.0
		and d.hint_seconds() <= TaxCollectorDirector.VISIT_SECONDS * (s.rules as Rules).clock_rate,
		"inside: the phase and his visit's seconds (%s, %.1f)" % [d.hint_phase(), d.hint_seconds()])
	t.check(MissionSteps.line(s.rules).begins_with("Ambush him at the door (gold) 0:"), "the step counts the visit (%s)" % MissionSteps.line(s.rules))
	ClarityKit.colours_ok(t, d, MissionHints.line("tax_collector", "inside") + " " + MissionSteps.steps("tax_collector")[1]["t"], "tax inside")
	ClarityKit.assert_read_only(t, s, "tax inside")
	# The banners: a Kill or a Hold on a collector indoors, a Seal laid too soon, off his door, and with his guard by.
	t.check(d.why_not("doom", door) == TaxCollectorDirector.WHY_INDOORS and d.why_not("oath", door) == TaxCollectorDirector.WHY_INDOORS,
		"a Kill or a Hold at the door of the house he is in: HE IS INDOORS (%s)" % d.why_not("doom", door))
	t.check(d.why_not("doom", _far("doom", door)) == "" and d.why_not("oath", _far("oath", door)) == "", "and the same casts far from the door say nothing")
	t.check(d.why_not("noleave", door) == TaxCollectorDirector.WHY_SOON, "a Seal on his door more than HOLD_TIME before he comes out: TOO SOON (%s)" % d.why_not("noleave", door))
	t.check(d.why_not("noleave", door + Vector2(TaxCollectorDirector.MOB_DOOR_R + 0.4, 0.0)) == TaxCollectorDirector.WHY_DOOR,
		"a Seal off the door he went in at: SEAL A DOOR HE WENT IN AT (%s)" % d.why_not("noleave", door + Vector2(TaxCollectorDirector.MOB_DOOR_R + 0.4, 0.0)))
	t.check(d.why_not("noleave", _far("noleave", door)) == "", "a Seal far from every collector says nothing")
	# The Seal as he comes out, guards drawn off: the debtors mob him.
	while q.indoors_left > NoLeaveFx.HOLD_TIME - 1.0:
		Kit.run_for(s, 0.5)
	for g: Variant in q.guards:
		Kit.arrive(g as Person, door + Vector2(1.0, 0.0))
	s["door"] = door
	var key := ClarityKit.apply(s, "seal", q.target)
	t.check(d.why_not(key, s.at) == TaxCollectorDirector.WHY_GUARD,
		"a Seal as he comes out with a guard of his at the door: HIS GUARD (BLUE) STOPS THE MOB (%s)" % d.why_not(key, s.at))
	for g: Variant in q.guards:
		Kit.arrive(g as Person, door + Vector2(14.0, 0.0))
	t.check(d.why_not(key, s.at) == "", "the guards drawn off: it says nothing (%s)" % d.why_not(key, s.at))
	var tries := 0
	while not q.dead and tries < 600:
		if not q.target.inside:
			Kit.arrive(q.target, door)
		for g: Variant in q.guards:
			if MissionDirector._alive(g):
				Kit.arrive(g as Person, door + Vector2(14.0, 0.0))
		Kit.run_for(s, DT)
		tries += 1
	_prove(t, q.dead and q.killed_by == "noleave" and d.stopped() == 1, "tax_collector", "inside", "seal",
		"sealed as he comes out, his guards away, the debtors mob him (dead %s by %s after %.0f s)" % [q.dead, q.killed_by, tries * DT])
	(s.fx as NoLeaveFx).free()
	ClarityKit.done(s)
	# A house alight or down: he comes out by himself, so a Kill is judged by nothing.
	s = _tax_world()
	d = s.d
	q = d.quarries[0]
	_tax_visit(s, q)
	ClarityKit.apply(s, "burn", q.inside_of)
	t.check(d.why_not("doom", q.stop_doors[0]) == "", "his house alight: he comes out; nothing to say to a Kill")
	ClarityKit.done(s)


## "hiding": alarmed, he hides in the counting-house: burn it.
static func _tax_hiding(t) -> void:
	var s := _tax_world()
	var d: TaxCollectorDirector = s.d
	var q := d.quarries[0]
	_tax_out(s, q)
	d._alarm(q)
	Kit.arrive(q.target, d.hide_door)
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	t.check(d.hint_phase() == "hiding" and q.target.inside and MissionSteps.line(s.rules).begins_with("Burn the counting-house (orange)"),
		"hiding: the phase and the step (%s, %s)" % [d.hint_phase(), MissionSteps.line(s.rules)])
	ClarityKit.colours_ok(t, d, MissionHints.line("tax_collector", "hiding") + " " + MissionSteps.steps("tax_collector")[3]["t"], "tax hiding")
	ClarityKit.assert_read_only(t, s, "tax hiding")
	ClarityKit.apply(s, "burn", d.hideout)
	Kit.run_for(s, 3.0)
	_prove(t, q.flushed and not q.target.inside, "tax_collector", "hiding", "burn",
		"the counting-house alight flushes him for the Citadel (flushed %s)" % q.flushed)
	ClarityKit.done(s)


# ---------------------------------------------------------------- The Bishop

static func _bishop_world() -> Dictionary:
	return ClarityKit.world(MissionBook.bishop())


## Every Knight of refuge `i` out of doors killed and freed (test_bishop's _clear).
static func _knights_gone(s: Dictionary, d: BishopDirector, i: int) -> void:
	for p: BishopDirector.Post in d.posts:
		if not p.done and p.refuge == i and MissionDirector._alive(p.man) and not (p.man as Person).inside:
			Kit.free_body(s, p.man)


## The bishop in refuge `i` now: his time brought on, and each refuge before it cleared and left (test_bishop's _to_refuge).
static func _bishop_to(s: Dictionary, d: BishopDirector, i: int) -> void:
	d._set_out(d.quarries[0])
	for k in i:
		_knights_gone(s, d, k)
		d._drive_out(k)
		d._reach_refuge(k + 1)


## A point beyond the reach of a cast of `key` from the refuge `s` (its footprint, not its middle).
static func _far_of(key: String, st: Structure) -> Vector2:
	return st.center() + Vector2(st.footprint.size.x * 0.5 + Crowd._cast_radius(key) + MissionDirector.WHY_MARGIN + 3.0, 0.0)


static func _bishop(t) -> void:
	_bishop_waiting(t)
	_bishop_guarded(t)
	_bishop_open(t)
	_bishop_square(t)


## "waiting": he is in the Citadel, his next refuge's Knights stand guard: kill or hold them shortly before he comes.
static func _bishop_waiting(t) -> void:
	var s := _bishop_world()
	var d: BishopDirector = s.d
	t.check(d.hint_phase() == "waiting" and absf(d.hint_seconds() - BishopDirector.ARRIVE_AT) < 1.0 and d.next_refuge() == 0
		and MissionSteps.line(s.rules).begins_with("Kill or hold its Knights (red) 0:4"),
		"waiting: the phase, the seconds to his arrival and the step (%s, %.1f)" % [MissionSteps.line(s.rules), d.hint_seconds()])
	ClarityKit.colours_ok(t, d, MissionHints.line("bishop", "waiting") + " " + MissionSteps.steps("bishop")[1]["t"], "bishop waiting")
	ClarityKit.assert_read_only(t, s, "bishop waiting")
	var before := d.guards_at(0).size()
	var knight := d.guards_at(0)[0]
	ClarityKit.apply(s, "kill", knight)
	_prove(t, before == 2 and d.guards_at(0).size() == 1, "bishop", "waiting", "kill", "a Doom on one of the next refuge's Knights: guards_at(0) 2 -> %d" % d.guards_at(0).size())
	ClarityKit.done(s)
	s = _bishop_world()
	d = s.d
	knight = d.guards_at(0)[0]
	ClarityKit.apply(s, "hold", knight)
	_prove(t, bool(s.took) and d.guards_at(0).size() == 1, "bishop", "waiting", "hold", "an Oath on one of them: guards_at(0) 2 -> %d (took %s)" % [d.guards_at(0).size(), s.took])
	ClarityKit.done(s)


## "guarded": he is in a refuge and a Knight holds its door: kill or hold them; a fire or a blow there is beaten out and turned aside.
static func _bishop_guarded(t) -> void:
	var s := _bishop_world()
	var d: BishopDirector = s.d
	_bishop_to(s, d, 0)
	var refuge := d.refuges[0]
	t.check(d.hint_phase() == "guarded" and MissionSteps.line(s.rules).begins_with("Kill or hold its Knights (red)"),
		"guarded: the phase and the step (%s, %s)" % [d.hint_phase(), MissionSteps.line(s.rules)])
	ClarityKit.colours_ok(t, d, MissionHints.line("bishop", "guarded") + " " + MissionSteps.steps("bishop")[2]["t"] + " " + MissionHints.line("bishop"), "bishop guarded")
	ClarityKit.assert_read_only(t, s, "bishop guarded")
	# The banners: a fire or a blow on the refuge a Knight holds; nothing for a cast that kills the Knight, for the next refuge, or far away.
	t.check(d.why_not("ember", refuge.center()) == BishopDirector.WHY_KNIGHTS and d.why_not("smite", refuge.center()) == BishopDirector.WHY_KNIGHTS,
		"a fire or a blow on the refuge while a Knight holds it: HIS KNIGHTS (RED) BEAT IT OUT (%s)" % d.why_not("ember", refuge.center()))
	t.check(d.why_not("ember", _far_of("ember", refuge)) == "" and d.why_not("smite", _far_of("smite", refuge)) == "", "the same casts far from it say nothing")
	t.check(d.why_not("ember", d.refuges[1].center()) == "", "a fire on the refuge he is not yet in: nothing (it is stone tonight)")
	t.check(d.why_not("smite", d.guards_at(0)[0].ground_pos) == "" and d.why_not("doom", d.guards_at(0)[0].ground_pos) == "" and d.why_not("oath", refuge.center()) == "",
		"a blow that kills the Knight, a Kill or a Hold: nothing")
	ClarityKit.apply(s, "burn", refuge)
	Kit.run_for(s, BishopDirector.SMOTHER_AFTER + 1.0)
	t.check(not (s.crowd as Crowd).fires.is_burning(refuge) and d.hint_phase() == "guarded", "(and the Knights do beat the fire out)")
	var before := d.guards_at(0).size()
	ClarityKit.apply(s, "kill", d.guards_at(0)[0])
	_prove(t, before >= 2 and d.guards_at(0).size() == before - 1, "bishop", "guarded", "kill", "a Doom on one of his Knights: guards_at %d -> %d" % [before, d.guards_at(0).size()])
	ClarityKit.done(s)
	s = _bishop_world()
	d = s.d
	_bishop_to(s, d, 0)
	var before_h := d.guards_at(0).size()
	ClarityKit.apply(s, "hold", d.guards_at(0)[0])
	_prove(t, bool(s.took) and d.guards_at(0).size() == before_h - 1, "bishop", "guarded", "hold", "an Oath on one of his Knights: he leaves the guard (guards_at %d -> %d)" % [before_h, d.guards_at(0).size()])
	ClarityKit.done(s)


## "open": no Knight stands: burn the refuge now.
static func _bishop_open(t) -> void:
	var s := _bishop_world()
	var d: BishopDirector = s.d
	_bishop_to(s, d, 0)
	_knights_gone(s, d, 0)
	t.check(d.hint_phase() == "open" and MissionSteps.line(s.rules).begins_with("Burn the refuge (gold) now"), "open: the phase and the step (%s, %s)" % [d.hint_phase(), MissionSteps.line(s.rules)])
	ClarityKit.colours_ok(t, d, MissionHints.line("bishop", "open") + " " + MissionSteps.steps("bishop")[3]["t"], "bishop open")
	ClarityKit.assert_read_only(t, s, "bishop open")
	t.check(d.why_not("ember", d.refuges[0].center()) == "", "no Knight stands: a fire on the refuge says nothing")
	ClarityKit.apply(s, "burn", d.refuges[0])
	Kit.run_for(s, 0.5)
	_prove(t, d.hint_phase() == "burning", "bishop", "open", "burn", "the refuge alight with no Knight to beat it out: the phase is burning (%s)" % d.hint_phase())
	_prove(t, d.hint_phase() == "burning", "bishop", "", "burn", "an unguarded refuge set alight burns")
	ClarityKit.colours_ok(t, d, MissionHints.line("bishop", "burning") + " " + MissionSteps.steps("bishop")[4]["t"], "bishop burning")
	ClarityKit.assert_read_only(t, s, "bishop burning")
	ClarityKit.done(s)


## "square": driven from the Temple he walks for the Citadel: kill him; alarmed he runs: kill him.
static func _bishop_square(t) -> void:
	var s := _bishop_world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	_bishop_to(s, d, 2)
	_knights_gone(s, d, 2)
	ClarityKit.apply(s, "burn", d.refuges[2])
	Kit.run_for(s, BishopDirector.DRIVE_OUT_TEMPLE + 0.6)
	t.check(d.in_square and d.hint_phase() == "square" and MissionSteps.line(s.rules).begins_with("Kill the bishop (gold)"), "square: the phase and the step (%s, %s)" % [d.hint_phase(), MissionSteps.line(s.rules)])
	ClarityKit.colours_ok(t, d, MissionHints.line("bishop", "square") + " " + MissionSteps.steps("bishop")[5]["t"], "bishop square")
	ClarityKit.assert_read_only(t, s, "bishop square")
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead, "bishop", "square", "kill", "a Doom on the bishop in the square kills him")
	_prove(t, q.dead, "bishop", "", "kill", "the bishop killed in the square wins")
	ClarityKit.done(s)
	s = _bishop_world()
	d = s.d
	q = d.quarries[0]
	_bishop_to(s, d, 2)
	_knights_gone(s, d, 2)
	ClarityKit.apply(s, "burn", d.refuges[2])
	Kit.run_for(s, BishopDirector.DRIVE_OUT_TEMPLE + 0.6)
	(s.crowd as Crowd).on_cast(q.target.ground_pos, Vector2.ZERO, 0.0, "smite")
	Kit.run_for(s, PowerBook.IMPACT.smite + 0.1)
	t.check(d.hint_phase() == "running", "running: a loud power by him sends him running (%s)" % d.hint_phase())
	ClarityKit.colours_ok(t, d, MissionHints.line("bishop", "running"), "bishop running")
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead, "bishop", "running", "kill", "a Doom on him as he runs kills him")
	ClarityKit.done(s)


# ---------------------------------------------------------------- Expel the Inquisitor

static func _expel_world() -> Dictionary:
	return ClarityKit.world(MissionBook.expel_inquisitor())


## `q` sent out on his round now and set down in the street at his first leg's door (test_expel_inquisitor's _out).
static func _ei_out(d: ExpelInquisitorDirector, q: AssassinateDirector.Quarry) -> void:
	d._set_out(q)
	Kit.arrive(q.target, d.hide_door if d._is_captain(q) else q.stop_doors[0])


static func _expel(t) -> void:
	_expel_wardens(t)
	_expel_captain(t)
	_expel_near(t)


## "": a lantern-warden in the street: kill or banish him; a fright only sends him to hide.
static func _expel_wardens(t) -> void:
	var s := _expel_world()
	var d: ExpelInquisitorDirector = s.d
	var q := d.quarries[0]
	_ei_out(d, q)
	Kit.run_for(s, DT)
	t.check(d.hint_phase() == "" and MissionSteps.line(s.rules).begins_with("Kill or banish a warden (gold)"), "own phase: the step (%s)" % MissionSteps.line(s.rules))
	ClarityKit.colours_ok(t, d, MissionHints.line("expel_inquisitor") + " " + MissionSteps.steps("expel_inquisitor")[0]["t"], "expel own")
	ClarityKit.assert_read_only(t, s, "expel warden")
	var kill_r := float(PowerBook.level_stat("smite", 1, "KILL_R", 0.6))
	t.check(d.why_not("smite", q.target.ground_pos + Vector2(kill_r + 0.5, 0.0)) == ExpelInquisitorDirector.EI_WHY_WARDEN,
		"a fright on a warden before it lands: A WARDEN ONLY HIDES - KILL HIM (%s)" % d.why_not("smite", q.target.ground_pos + Vector2(kill_r + 0.5, 0.0)))
	t.check(d.why_not("smite", q.target.ground_pos) == "" and d.why_not("doom", q.target.ground_pos) == "" and d.why_not("skylift", q.target.ground_pos) == "",
		"a blow that kills him, a Kill or a Skylift: nothing")
	t.check(d.why_not("smite", _far("smite", q.target.ground_pos)) == "", "and the same cast far from him says nothing")
	ClarityKit.apply(s, "scare", q.target)
	t.check((q.state == State.FLEEING or q.state == State.HIDING) and d.stopped() == 0 and d.frights() == 0, "(and a fright does only send him to hide: %s, stopped %d)" % [State.keys()[q.state], d.stopped()])
	ClarityKit.done(s)
	s = _expel_world()
	d = s.d
	q = d.quarries[0]
	_ei_out(d, q)
	_clear_round(s.crowd, q.target)
	ClarityKit.apply(s, "kill", q.target)
	Kit.run_for(s, 0.5)
	_prove(t, q.dead and d.stopped() == 1, "expel_inquisitor", "", "kill", "a Doom on a warden stops him (stopped %d)" % d.stopped())
	ClarityKit.done(s)
	s = _expel_world()
	d = s.d
	q = d.quarries[0]
	_ei_out(d, q)
	ClarityKit.apply(s, "banish", q.target)
	Kit.run_for(s, 1.0)
	_prove(t, q.state == State.OUT and d.stopped() == 1, "expel_inquisitor", "", "banish", "a Skylift sets him down outside the walls: stopped (%s)" % State.keys()[q.state])
	ClarityKit.done(s)


## "captain": kill him, or scare him three times, each at least 8 s apart while he walks.
static func _expel_captain(t) -> void:
	var s := _expel_world()
	var d: ExpelInquisitorDirector = s.d
	var cap := d.captain()
	_ei_out(d, cap)
	Kit.arrive(cap.target, d._walkable(d.hide_door.lerp(cap.stop_doors[0], 0.5)))  # (a street's length from the Temple, where he would hide)
	Kit.run_for(s, DT)
	t.check(d.hint_phase() == "captain" and MissionSteps.line(s.rules).begins_with("Kill or scare the captain (gold)"), "captain: the phase and the step (%s, %s)" % [d.hint_phase(), MissionSteps.line(s.rules)])
	ClarityKit.colours_ok(t, d, MissionHints.line("expel_inquisitor", "captain") + " " + MissionSteps.steps("expel_inquisitor")[1]["t"], "expel captain")
	ClarityKit.assert_read_only(t, s, "expel captain")
	_clear_round(s.crowd, cap.target)
	ClarityKit.apply(s, "kill", cap.target)
	Kit.run_for(s, 0.5)
	_prove(t, cap.dead and d.stopped() == 1, "expel_inquisitor", "captain", "kill", "a Doom on the captain stops him")
	ClarityKit.done(s)
	# Three frights, each once he walks again.
	s = _expel_world()
	d = s.d
	cap = d.captain()
	_ei_out(d, cap)
	Kit.arrive(cap.target, d._walkable(d.hide_door.lerp(cap.stop_doors[0], 0.5)))
	Kit.run_for(s, DT)
	var kill_r := float(PowerBook.level_stat("smite", 1, "KILL_R", 0.6))
	var banners := PackedStringArray()
	for k in 3:
		var at := cap.target.ground_pos + Vector2(kill_r + 0.5, 0.0)
		banners.append(d.why_not("smite", at))
		ClarityKit.apply(s, "scare", cap.target)
		if k == 0:
			t.check(d.why_not("smite", s.at) == ExpelInquisitorDirector.EI_WHY_SHAKEN and d.frights() == 1,
				"a second fright within 8 s of the first: STILL SHAKEN - SCARE HIM AGAIN SOON (%s, frights %d)" % [d.why_not("smite", s.at), d.frights()])
			t.check(d.why_not("smite", _far("smite", cap.target.ground_pos)) == "", "and the same cast far from him says nothing")
		if k < 2:
			Kit.arrive(cap.target, d.hide_door)
			var waited := 0.0
			while cap.state != State.WALKING and waited < 40.0:
				Kit.run_for(s, 1.0)
				waited += 1.0
			t.check(cap.state == State.WALKING and waited >= ExpelInquisitorDirector.EI_FRIGHT_GAP - 1.0, "(set-up) fright %d: he hid and walks again after %.0f s" % [k + 1, waited])
	t.check(banners == PackedStringArray(["", "", ""]), "each of the three frights, asked before it lands, is counted (%s)" % [banners])
	_prove(t, d.frights() == 3 and d.fled() and cap.state == State.OUT and d.stopped() == 1, "expel_inquisitor", "captain", "scare",
		"scared three times, each once he walks again: stopped (%d frights, %s)" % [d.frights(), State.keys()[cap.state]])
	ClarityKit.done(s)


## "near": the captain's last walk: kill or banish him now.
static func _expel_near(t) -> void:
	var s := _expel_world()
	var d: ExpelInquisitorDirector = s.d
	var cap := d.captain()
	d._set_out(cap)
	cap.leg = cap.stops.size()
	cap.state = State.WALKING
	Kit.arrive(cap.target, d._walkable(ExpelInquisitorDirector.EI_FINAL_WAYPOINT))
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	Kit.arrive(cap.target, d.safe_at + Vector2(3.0, 0.0))
	cap.target.go_duty(d.safe_at)
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	t.check(d.hint_phase() == "near" and MissionSteps.line(s.rules).begins_with("Kill the captain (gold) now"), "near: the phase and the step (%s, %s)" % [d.hint_phase(), MissionSteps.line(s.rules)])
	ClarityKit.colours_ok(t, d, MissionHints.line("expel_inquisitor", "near") + " " + MissionSteps.steps("expel_inquisitor")[2]["t"], "expel near")
	ClarityKit.assert_read_only(t, s, "expel near")
	_clear_round(s.crowd, cap.target)
	ClarityKit.apply(s, "kill", cap.target)
	Kit.run_for(s, 0.5)
	_prove(t, cap.dead and d.stopped() == 1, "expel_inquisitor", "near", "kill", "a Doom on the captain near the Citadel stops him")
	ClarityKit.done(s)
	s = _expel_world()
	d = s.d
	cap = d.captain()
	d._set_out(cap)
	cap.leg = cap.stops.size()
	cap.state = State.WALKING
	Kit.arrive(cap.target, d._walkable(ExpelInquisitorDirector.EI_FINAL_WAYPOINT))
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	Kit.arrive(cap.target, d.safe_at + Vector2(3.0, 0.0))
	cap.target.go_duty(d.safe_at)
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	ClarityKit.apply(s, "banish", cap.target)
	Kit.run_for(s, 1.0)
	_prove(t, cap.state == State.OUT and d.stopped() == 1, "expel_inquisitor", "near", "banish", "a Skylift sets him down outside the walls: stopped (%s)" % State.keys()[cap.state])
	ClarityKit.done(s)
