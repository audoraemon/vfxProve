extends RefCounted
## The loss warning on every night (loss-warning-all): each director's threats() names the countdowns that end its night -- a target walking for
## the safe place, a deadline the strip counts, a march, a rite, a meter -- empty while the night is safe, at an honest time once it runs. The
## worlds are the directors' own tests'. test_threat_alert holds the first wave (Heralds, the witness, the captain, the standards, the pyres).

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const BI := preload("res://tests/test_bishop.gd")
const IN := preload("res://tests/test_informer.gd")
const LL := preload("res://tests/test_lost_lamb.gd")
const PR := preload("res://tests/test_prisoner.gd")
const EX := preload("res://tests/test_exodus.gd")
const DT := 0.05


static func run(t) -> void:
	_collector(t)
	_bishop(t)
	_informer_names(t)
	_informer_runs(t)
	_decisive(t)
	_lamb(t)
	_prisoner(t)
	_exodus_march(t)
	_exodus_gates(t)


static func _find(list: Array, id: StringName) -> Dictionary:
	for th: Dictionary in list:
		if th.id == id:
			return th
	return {}


## `th` is a threat at `eta` (within `eps`), with a title and an order.
static func _at(th: Dictionary, eta: float, eps := 0.01) -> bool:
	return not th.is_empty() and eta < INF and absf(float(th.eta) - eta) < eps and String(th.title) != "" and String(th.act) != ""


## The Tax Collector: nothing on his round; past his last stop he walks for the Citadel, `safe_0` at his walk there.
static func _collector(t) -> void:
	var s := Kit.world(MissionBook.tax_collector())
	var d: TaxCollectorDirector = s.d
	var q: AssassinateDirector.Quarry = d.quarries[0]
	d._set_out(q)
	Kit.run_for(s, DT)
	t.check(q.state == AssassinateDirector.State.WALKING and q.leg < q.stops.size() and _find(d.threats(), &"safe_0").is_empty(),
		"the collector on his round: no threat")
	q.leg = q.stops.size()
	q.target.go_duty(d.safe_at)
	var th := _find(d.threats(), &"safe_0")
	var want := MissionDirector.walk_left(q.target, d.safe_at) * (s.rules as Rules).clock_rate
	t.check(_at(th, want) and String(th.title) == "THE TAX COLLECTOR REACHES THE CITADEL", "his round done: he walks for the Citadel (%s, %.2f)" % [th, want])
	q.target.confuse(3.0)
	t.check(_find(d.threats(), &"safe_0").is_empty(), "confused by the god, he does not walk on: no threat")
	Kit.done(s)


## The Bishop: drawn into the square he walks for the Citadel's gate at half his pace, `safe_0`; none while he keeps to his refuges.
static func _bishop(t) -> void:
	var s := BI._world()
	var d: BishopDirector = s.d
	var q: AssassinateDirector.Quarry = d.quarries[0]
	BI._to_refuge(s, d, 2)
	t.check(_find(d.threats(), &"safe_0").is_empty(), "in the Temple, his last refuge: no threat")
	d._drive_out(2)
	Kit.run_for(s, AssassinateDirector.TICK + DT)
	var th := _find(d.threats(), &"safe_0")
	t.check(d.in_square and _at(th, MissionDirector.walk_left(q.target, d.safe_at) * (s.rules as Rules).clock_rate)
		and String(th.title) == "THE BISHOP REACHES THE CITADEL", "in the square: he walks for the Citadel (%s)" % [th])
	Kit.done(s)


## The Informer: no names' threat before the last visit; after it, `names` at the strip's time (FOUND_LIMIT); gone once he is found.
static func _informer_names(t) -> void:
	var s := IN._world()
	var d: InformerDirector = s.d
	t.check(_find(d.threats(), &"names").get("eta", INF) > 60.0, "at the start the names are far off")
	for i in d.contacts.size():
		d._visit(i)
	var th := _find(d.threats(), &"names")
	t.check(_at(th, d.timeline.seconds_to("names")) and absf(float(th.eta) - InformerDirector.FOUND_LIMIT) < 0.1,
		"the last contact has the word: the names, FOUND_LIMIT out (%s)" % [th])
	Kit.run_for(s, InformerDirector.FOUND_LIMIT - 10.0)
	th = (s.rules as Rules).threat()
	t.check(th.get("id", &"") == &"names" and absf(float(th.eta) - 10.0) < 0.2, "ten seconds left: the names are the soonest (%s)" % [th])
	Kit.done(s)


## The Informer found: he runs for the Temple's door, `safe_0`; hiding, no threat; his hiding place alight, he runs again.
static func _informer_runs(t) -> void:
	var s := IN._world()
	var d: InformerDirector = s.d
	var q: AssassinateDirector.Quarry = d.quarries[0]
	IN._turn_all(s, d)
	var th := _find(d.threats(), &"safe_0")
	t.check(d.found and _at(th, MissionDirector.walk_left(q.target, d.safe_at) * (s.rules as Rules).clock_rate)
		and String(th.title) == "THE INFORMER REACHES THE TEMPLE" and _find(d.threats(), &"names").is_empty(),
		"found, he runs for the Temple: his threat; the names' gone (%s)" % [th])
	d._alarm(q)
	t.check(_find(d.threats(), &"safe_0").is_empty(), "alarmed, he runs back to hide: no threat")
	(s.crowd as Crowd).fires.ignite(d.hideout, 0.6)
	t.check(d.fleeing_to_safe(q) and not _find(d.threats(), &"safe_0").is_empty(), "his hiding place alight: he runs for the Temple again")
	Kit.done(s)


## NightThreat.decisive(): with k more to lose, the k-th soonest on; nothing with fewer than k, or k < 1.
static func _decisive(t) -> void:
	var list := [NightThreat.make(&"a", "A", "X", 9.0), NightThreat.make(&"b", "B", "X", 3.0), NightThreat.make(&"c", "C", "X", 6.0)]
	var two := NightThreat.decisive(list, 2)
	t.check(two.size() == 2 and NightThreat.soonest(two).id == &"c", "two to lose: the second soonest is the moment (%s)" % [two])
	t.check(NightThreat.decisive(list, 1).size() == 3 and NightThreat.decisive(list, 4).is_empty() and NightThreat.decisive(list, 0).is_empty(),
		"one to lose: all of them; more than there are, or none: nothing")


## The Lost Lamb: seized, the acolyte marched back to the Temple is `seized_0` at the later of his seizer's walk and his own; free, none.
static func _lamb(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb())
	var d: LostLambDirector = s.d
	LL._clear_watchers(d)
	t.check(d.threats().is_empty(), "the acolyte free: no threat")
	var p: Person = d.patrols[0][0]
	Kit.arrive(p, d.charge.ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	var th := _find(d.threats(), &"seized_0")
	t.check(d.held and _at(th, d.march_eta(d.charges[0])) and String(th.title) == "THE ACOLYTE IS TAKEN BACK"
		and float(th.eta) >= MissionDirector.walk_left(p, d.return_to) - 1.0, "seized: he is marched back to the Temple (%s)" % [th])
	p.mind = Person.Mind.CONFUSED
	t.check(d.threats().is_empty(), "his seizer confused: no march, no threat")
	Kit.done(s)


## The Prisoner: bound, the gaolers taking her inside at FREE_BY (`inside`, the strip's time); the stocks down, gone; seized, her march back.
static func _prisoner(t) -> void:
	var s := PR._world()
	var d: PrisonerDirector = s.d
	var th := _find(d.threats(), &"inside")
	t.check(_at(th, d.timeline.seconds_to("inside")) and String(th.title) == "THE GAOLERS TAKE HER INSIDE", "bound in the stocks: taken inside at FREE_BY (%s)" % [th])
	d.timeline.step(PrisonerDirector.FREE_BY - 10.0)
	t.check(absf(float(_find(d.threats(), &"inside").get("eta", INF)) - 10.0) < 0.2, "ten seconds before FREE_BY: ten seconds")
	PR._break(s, d)
	t.check(_find(d.threats(), &"inside").is_empty(), "the stocks down: she is not taken inside")
	th = _find(d.threats(), &"seized_0")
	t.check(d.held and _at(th, d.march_eta(d.charges[0])) and String(th.title) == "THE PRISONER IS TAKEN BACK" and String(th.act) == "FREE HER",
		"seized the moment she is free: her march back to the Citadel (%s)" % [th])
	Kit.done(s)


## Exodus: a seized believer with two to spare is no threat (the third delivered loses); with none to spare he is.
static func _exodus_march(t) -> void:
	var s := EX._world()
	var d: ExodusDirector = s.d
	EX._clear_watch(d)
	d._come_out(0)
	var c: EscortDirector.Charge = (d.households[0] as ExodusDirector.Household).members[0]
	Kit.arrive(d.watch[0], (c.man as Person).ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	var i := d.charges.find(c)
	t.check(c.held and d.takings_to_lose() == 3 and _find(d.threats(), StringName("seized_%d" % i)).is_empty(),
		"seized with two to spare: no threat")
	var gone := 0
	for o in d.charges:
		if gone < 2 and o != c and MissionDirector._alive(o.man) and not o.held:
			Kit.free_body(s, o.man)
			gone += 1
	var th := _find(d.threats(), StringName("seized_%d" % i))
	t.check(d.takings_to_lose() == 1 and _at(th, d.march_eta(c)) and String(th.title) == "A SEIZED BELIEVER REACHES THE TEMPLE",
		"none to spare: his march is the loss (%s)" % [th])
	Kit.done(s)


## Exodus: the last gate's shutting while too few are out (`gates_shut`, the strip's time); enough out, none.
static func _exodus_gates(t) -> void:
	var s := EX._world()
	var d: ExodusDirector = s.d
	var th := _find(d.threats(), &"gates_shut")
	t.check(_at(th, d.timeline.seconds_to("shut_2")) and float(th.eta) > 200.0, "the last gate shuts at its time (%s)" % [th])
	d.timeline.step(float(ExodusDirector.SHUT_AT[2]) - 12.0)
	th = (s.rules as Rules).threat()
	t.check(th.get("id", &"") == &"gates_shut" and absf(float(th.eta) - 12.0) < 0.3, "twelve seconds before: the soonest (%s)" % [th])
	for k in d.tune_need:
		d.charges[k].escaped = true
	t.check(_find(d.threats(), &"gates_shut").is_empty(), "enough out: the gates shutting loses nothing")
	Kit.done(s)
