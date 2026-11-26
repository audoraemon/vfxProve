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
const SH := preload("res://tests/test_spoiled_harvest.gd")
const HO := preload("res://tests/test_heart_of_faith.gd")
const HH := preload("res://tests/test_heretic_hunt.gd")
const FT := preload("res://tests/test_first_taste.gd")
const PN := preload("res://tests/test_procession.gd")
const VF := preload("res://tests/test_vigil_flame.gd")
const RR := preload("res://tests/test_relic_run.gd")
const BL := preload("res://tests/test_broken_lanterns.gd")
const HF := preload("res://tests/test_hide_faithful.gd")
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
	_granary(t)
	_blessed(t)
	_kindled(t)
	_cellar(t)
	_cleanse(t)
	_ship(t)
	_escape(t)
	_flame_home(t)
	_vigil_prayer(t)
	_relic(t)
	_lantern_prayer(t)
	_two_held(t)


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


## Spoiled Harvest: a carter walking for a granary's last load is `emptied_<i>` at his walk to its door; more loads left, or confused, none.
static func _granary(t) -> void:
	var s := SH._world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	var c: Person = d.carters[g][0]
	Kit.arrive(c, d.doors[g] + Vector2(3.0, 0.0))
	c.go_duty(d.doors[g])
	t.check(_find(d.threats(), &"emptied_0").is_empty(), "five loads left: no threat")
	d.loads[g] = 1
	var th := _find(d.threats(), &"emptied_0")
	t.check(_at(th, d.last_load_eta(g, c)) and float(th.eta) < 6.0 / maxf(c.walk_speed, 0.05) and String(th.title) == "A GRANARY IS EMPTIED",
		"the last load: his walk to the door (%s)" % [th])
	c.confuse(3.0)
	t.check(_find(d.threats(), &"emptied_0").is_empty(), "confused, he is off his errand: no threat")
	SH._done(s)


## The Heart of Faith: the flame's blessing at BLESSED_AT (`blessed`, the strip's time) while it burns; out, none.
static func _blessed(t) -> void:
	var s := HO._world()
	var d: HeartOfFaithDirector = s.d
	var th := _find(d.threats(), &"blessed")
	t.check(_at(th, d.timeline.seconds_to("blessed")) and String(th.title) == "THE GREAT FLAME IS BLESSED", "the flame burns: blessed at its time (%s)" % [th])
	d.timeline.step(HeartOfFaithDirector.BLESSED_AT - 10.0)
	t.check(absf(float(_find(d.threats(), &"blessed").get("eta", INF)) - 10.0) < 0.2, "ten seconds before: ten seconds")
	HO._put_out(d)
	t.check(_find(d.threats(), &"blessed").is_empty(), "the flame out: no blessing")
	Kit.done(s)


## The Heart of Faith: Odran's rekindling on the steps (`kindled`, the rite's seconds left); broken by a whisper, gone.
static func _kindled(t) -> void:
	var s := HO._world()
	var d: HeartOfFaithDirector = s.d
	HO._put_out(d)
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	d._odran_comes()
	var o := d.odran as Person
	t.check(_find(d.threats(), &"kindled").is_empty(), "Odran out, not at the steps: no threat")
	Kit.arrive(o, d.steps_at)
	d._road_at = d._road.size() - 1
	o.go_duty(d.steps_at)
	Kit.run_for(s, 1.0)
	var th := _find(d.threats(), &"kindled")
	t.check(d.rite_on and _at(th, d.rite_left * (s.rules as Rules).clock_rate) and float(th.eta) < HeartOfFaithDirector.RITE,
		"at the steps he rekindles: the rite's seconds left (%s)" % [th])
	o.whisper(o.ground_pos + Vector2(4.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, DT)
	t.check(_find(d.threats(), &"kindled").is_empty(), "the rite broken: no threat")
	Kit.done(s)


## The Heretic Hunt: the captain on his search, `found` at the rest of his route and stops; at its last leg his walk to the cellar.
static func _cellar(t) -> void:
	var s := HH._world()
	var d: HereticHuntDirector = s.d
	t.check(_find(d.threats(), &"found").is_empty(), "the captain in the Temple: no threat")
	for i in 3:
		HH._break(s, d, i)
	d._call_head()
	var head := d.head as Person
	Kit.run_for(s, DT)
	var far := _find(d.threats(), &"found")
	t.check(far.is_empty() or float(far.eta) > HereticHuntDirector.CAPTAIN_STOP * float(d.head_route.size() - 1),
		"out on his search: the cellar is at least his stops away (%s)" % [far])
	for k in d.head_route.size() - 1:
		Kit.arrive(head, d.head_route[k])
		Kit.run_for(s, HereticHuntDirector.CAPTAIN_STOP + 0.3)
	var th := _find(d.threats(), &"found")
	t.check(d._route_at == d.head_route.size() - 1 and _at(th, d.find_eta()) and String(th.title) == "THE CAPTAIN FINDS THE CELLAR"
		and float(th.eta) <= MissionDirector.walk_left(head, d.cellar_door) + 0.01, "on his last leg: his walk to the cellar (%s)" % [th])
	head.confuse(3.0)
	t.check(_find(d.threats(), &"found").is_empty(), "confused, he leaves his search a while: no threat")
	Kit.done(s)


## The First Taste: two clergy kneeling run the ring, `cleanse` at its seconds left (real seconds); a march still mustering is far off.
static func _cleanse(t) -> void:
	var s := FT._world()
	var d: FirstTasteDirector = s.d
	d.offer(d.marked[0])
	t.check(d.cleanse_eta() > 15.0, "a march mustering: the cleanse is far off (%.1f)" % d.cleanse_eta())
	var m: FirstTasteDirector.March = d.marches[0]
	FT._kneel_all(m, d)
	t.check(is_equal_approx(d.cleanse_eta(), FirstTasteDirector.CLEANSE_SECONDS), "all kneeling, the ring not yet run: the whole ring (%.2f)" % d.cleanse_eta())
	FT._run(s, 1.0)
	var th := _find(d.threats(), &"cleanse")
	t.check(d.cleansing() and _at(th, FirstTasteDirector.CLEANSE_SECONDS - d.cleanse) and float(th.eta) < FirstTasteDirector.CLEANSE_SECONDS,
		"the ring runs: its seconds left (%s)" % [th])
	FT._done(s)


## The Procession: the Prince waiting at the dock is `ship` at the ship's docking and his last leg; walking to the steps, far off.
static func _ship(t) -> void:
	var s := PN._setup()
	var d: ProcessionDirector = s.d
	var p := d.prince
	PN._to(s, 30.0)
	t.check(d.ship_eta() > 60.0, "at 30 s, on his way to the steps: the ship is far off (%.1f)" % d.ship_eta())
	PN._arrive(p)
	PN._to(s, 82.0)
	PN._arrive(p)
	PN._to(s, 100.0)
	PN._arrive(p)
	PN._to(s, 110.0)
	var walk := (d.road_len(d.route[3], d.route[4]) - ProcessionDirector.ARRIVE) / p.walk_speed
	var th := _find(d.threats(), &"ship")
	t.check(d.leg == 3 and _at(th, d.ship_eta()) and absf(float(th.eta) - (d.timeline.seconds_to("ship") + walk)) < 0.2,
		"at the dock at 110 s: the ship's docking and his last leg (%s, walk %.2f)" % [th, walk])
	p.panic(p.ground_pos + Vector2(1.0, 0.0), 2.0)
	t.check(_find(d.threats(), &"ship").is_empty(), "frightened, he is halted: no threat")
	PN._done(s)


## Last Judgement: one escape short of the limit, a citizen running for a way out is `escape` at his run there.
static func _escape(t) -> void:
	var s := Kit.world(MissionBook.last_judgement())
	var d: LastJudgementDirector = s.d
	var rules: Rules = s.rules
	var crowd: Crowd = s.crowd
	t.check(d.escapes_left() > 1 and _find(d.threats(), &"escape").is_empty(), "nobody fleeing: no threat")
	crowd.escaped_count = rules._escaped0 + Rules.ESCAPE_LIMIT - 1
	var p: Person = null
	for c in crowd.citizens:
		if is_instance_valid(c) and c.is_alive() and not c.inside:
			p = c
			break
	p.mind = Person.Mind.FLEE
	p.walk_speed = p._mind_speed()
	p._goal = p.ground_pos + Vector2(4.0, 0.0)
	p._path = PackedVector2Array()
	var th := _find(d.threats(), &"escape")
	t.check(d.escapes_left() == 1 and _at(th, (4.0 - Person.GOAL_REACH) / p.walk_speed) and String(th.title) == "THE PEOPLE ESCAPE",
		"one short of the limit: his run to the way out (%s)" % [th])
	rules._escaped0 -= 1
	t.check(_find(d.threats(), &"escape").is_empty(), "two short, one running: no threat")
	Kit.done(s)


## The Vigil Flame: nothing before the route turns home; then the bearer's walk to the Temple's door, `flame_home`; swapped, none.
static func _flame_home(t) -> void:
	var s := VF._setup()
	var d: VigilFlameDirector = s.d
	t.check(_find(d.threats(), &"flame_home").is_empty(), "the Vigil on its round: no threat")
	VF._arrive(d.vigil.bearer, d.vigil.route[d.vigil.route.size() / 2])  # out on its round, far from the Temple (headless people never walk)
	d.timeline.step(VigilFlameDirector.ROUTE_AT)
	VF._run(s, VigilRoute.TICK + DT)
	var th := _find(d.threats(), &"flame_home")
	t.check(d.going_home() and _at(th, d.home_eta()) and String(th.title) == "THE FLAME GOES HOME"
		and absf(float(th.eta) - (MissionDirector.walk_left(d.vigil.bearer, d.temple_door) - VigilFlameDirector.HOME_REACH / d.vigil.bearer.walk_speed)
			* (s.rules as Rules).clock_rate) < 0.01,
		"the route turned home: the bearer's walk to the Temple (%s)" % [th])
	d.swapped = true
	t.check(_find(d.threats(), &"flame_home").is_empty(), "the flame swapped: he carries nothing that loses")
	VF._done(s)


## The Vigil Flame: a prayer under way fills the Gaze only when what it can add is enough; `prayer` then, at the time it does.
static func _vigil_prayer(t) -> void:
	var s := VF._setup()
	var d: VigilFlameDirector = s.d
	var f: Person = null
	for v: Variant in d.faithful:
		if MissionDirector._alive(v) and not (v as Person).inside:
			f = v
			break
	f.go_duty(f.ground_pos)
	d.praying[f] = [VigilFlameDirector.PRAY_SECONDS, f.ground_pos]
	d.gaze.value = 90.0
	t.check(_find(d.threats(), &"prayer").is_empty(), "one prayer at Gaze 90: it cannot fill it, no threat")
	d.gaze.value = 99.0
	var th := _find(d.threats(), &"prayer")
	var want := 1.0 / (GazeMeter.PRAYER_PER_SECOND * VigilFlameDirector.PRAYER_SCALE) * (s.rules as Rules).clock_rate
	t.check(_at(th, want), "Gaze 99: the prayer fills it in %.2f s (%s)" % [want, th])
	VF._done(s)


## The Relic Run: past its last checkpoint the cart walks for the Citadel's gate, `flame_home` (THE RELIC REACHES THE CITADEL); a checkpoint
## still to come, none.
static func _relic(t) -> void:
	var s := RR._world()
	var d: RelicRunDirector = s.d
	RR._out_on_road(s, d)
	t.check(_find(d.threats(), &"flame_home").is_empty(), "on the road, its checkpoints ahead: no threat")
	d.halts_done[0] = true
	d.halts_done[1] = true
	var th := _find(d.threats(), &"flame_home")
	t.check(_at(th, d.home_eta()) and String(th.title) == "THE RELIC REACHES THE CITADEL"
		and float(th.eta) > MissionDirector.walk_left(d.vigil.bearer, d.vigil.goal()) * (s.rules as Rules).clock_rate,
		"no checkpoint left: its walk on to the Citadel's gate (%s)" % [th])
	Kit.done(s)


## Broken Lanterns: the Faithful at prayer fill the Gaze at a steady rate, `prayer` at (FULL - Gaze) / rate.
static func _lantern_prayer(t) -> void:
	var s := BL._setup()
	var d: BrokenLanternsDirector = s.d
	BL._away(d)
	t.check(_find(d.threats(), &"prayer").is_empty(), "nobody at prayer: no threat")
	BL._break(d.shrines[0])
	for k: Variant in d.praying.keys():
		BL._arrive(k as Person, d.praying[k][1])
	d.gaze.value = 99.0
	var rate := minf(float(d.praying_count()), GazeMeter.PRAYER_CAP) * BrokenLanternsDirector.PRAYER_SCALE * d._toll_scale()
	var th := _find(d.threats(), &"prayer")
	t.check(d.praying_count() > 0 and _at(th, 1.0 / rate * (s.rules as Rules).clock_rate), "at prayer, Gaze 99: they fill it (%s)" % [th])
	BL._done(s)


## Hide the faithful: one seized with none lost is no threat; two marched at once, the second delivery loses -- the later of the two.
static func _two_held(t) -> void:
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
	t.check(lead.held and d.lost() == 0 and d.threats().is_empty(), "(set-up) one seized, none lost: no threat")
	var other: EscortDirector.Charge = null
	for c in d.charges:
		if c != lead and MissionDirector._alive(c.man):
			other = c
			break
	other.held = true
	other.seizer = d.patrols[1][0]
	d._seized_at[other] = d._clock - 5.0
	d._refresh_march()
	var th := NightThreat.soonest(d.threats())
	var later := maxf(d._temple_in(lead), d._temple_in(other))
	t.check(not th.is_empty() and absf(float(th.eta) - later) < 0.001, "two marched with none lost: the later delivery is the loss (%s, %.2f)" % [th, later])
	other.held = false
	other.seizer = null
	Kit.done(s)
