extends RefCounted
## The loss warning on every night (loss-warning-all): each director's threats() names the countdowns that end its night -- a target walking for
## the safe place, a deadline the strip counts, a march, a rite, a meter -- empty while the night is safe, at an honest time once it runs. The
## worlds are the directors' own tests'. test_threat_alert holds the first wave (Heralds, the witness, the captain, the standards, the pyres).

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const BI := preload("res://tests/test_bishop.gd")
const IN := preload("res://tests/test_informer.gd")
const DT := 0.05


static func run(t) -> void:
	_collector(t)
	_bishop(t)
	_informer_names(t)
	_informer_runs(t)


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
