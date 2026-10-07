extends RefCounted
## Board tags: the board missions adopt v0.10 M6's objective layer. The Warning (and The Long Night's Act I), the
## Festival, the Procession, Judgement and Last Judgement each tag what matters on the map, change their how-to-win line
## with the play, and (but Last Judgement) tour their key places. Tags, phases and tours only read: no random number is
## drawn.

const Warn := preload("res://tests/test_warning.gd")
const Fest := preload("res://tests/test_festival.gd")
const Proc := preload("res://tests/test_procession.gd")
const Judge := preload("res://tests/test_judgement.gd")


static func run(t) -> void:
	_warning(t)
	_festival(t)
	_procession(t)
	_last_judgement(t)
	_judgement(t)


static func _tag(d: MissionDirector, label: String) -> MapTag:
	for m in d.tags():
		if m.label == label:
			return m
	return null


## Unlabelled diamonds in `color`.
static func _plain(d: MissionDirector, color: Color) -> int:
	var n := 0
	for m in d.tags():
		if m.label == "" and m.color == color:
			n += 1
	return n


## Calls everything the HUD and the tour read, and says whether the crowd drew a random number meanwhile.
static func _reads_only(d: MissionDirector, crowd: Crowd) -> bool:
	var before := crowd._rng.state
	d.tags()
	d.hint_phase()
	d.tour()
	return crowd._rng.state == before


static func _warning(t) -> void:
	var s: Dictionary = Warn._setup()
	var d: WarningDirector = s.d
	var crowd: Crowd = s.crowd
	var keeper := crowd.bell.keeper
	var first := d.tags()[0]
	t.check(first.label == "WATCHMAN" and first.at == d.watchman.ground_pos and first.edge and first.color == WarningDirector.MARK_MESSENGER,
		"before the star the watchman is tagged first, gold, pointed at")
	var k := _tag(d, "BELLKEEPER")
	t.check(k != null and k.at == keeper.ground_pos and not k.edge, "the bellkeeper is tagged, not pointed at yet")
	var tower := _tag(d, "BELL TOWER")
	t.check(tower != null and tower.at == crowd.bell.tower.center() and tower.rise == crowd.bell.tower.height and not tower.edge,
		"the bell tower is tagged at its top")
	t.check(_plain(d, WarningDirector.MARK_WATCHED) == 0 and d.hint_phase() == "", "no witnesses marked before the run; the mission's line")
	var stops := d.tour()
	t.check(stops.size() == 2 and stops[0][0] == d.watchman.ground_pos and stops[1][0] == keeper.ground_pos,
		"the tour: the watchman, then the bellkeeper")
	t.check(_reads_only(d, crowd), "the Warning's tags, phase and tour draw no random number")

	Warn._run(s, 6.2)
	var w := d.watchman
	t.check(d.phase == WarningDirector.Phase.RUN and d.tags()[0].label == "MESSENGER" and _tag(d, "BELLKEEPER").edge,
		"running, he is the MESSENGER, and the bellkeeper is pointed at")
	var near := crowd.citizens.filter(func(p: Person) -> bool: return p != w and p != keeper and p.is_alive() and not p.inside)[0] as Person
	near.ground_pos = w.ground_pos + Vector2(0.5, 0.0)
	var seeing := d.witnesses()
	t.check(seeing.has(near) and _plain(d, WarningDirector.MARK_WATCHED) == seeing.size()
		and (crowd.nearest_witness(w.ground_pos, w) != null) == not seeing.is_empty(),
		"a red diamond on each witness, by the doom's own rule (%d)" % seeing.size())
	d.relays = 1
	t.check(d.hint_phase() == "relay", "a witness carries it on: the relay's line")
	d.phase = WarningDirector.Phase.DELIVERED
	t.check(d.hint_phase() == "bell", "the bell called: the bell's line")
	d.warning_dead = true
	t.check(d.tags().is_empty(), "the warning dead, nothing is tagged")
	Warn._done(s)


static func _festival(t) -> void:
	var night := NightState.new()
	var s: Dictionary = Fest._setup(night)
	var d: FestivalDirector = Fest._start(s, night)
	var crowd: Crowd = s.crowd
	var mayor := d.mayor
	var first := d.tags()[0]
	t.check(mayor != null and first.label == "MAYOR" and first.at == mayor.ground_pos and not first.edge,
		"the Mayor is tagged first, not pointed at before his address")
	var feast := _tag(d, "THE FEAST")
	t.check(feast != null and feast.at == TownLayout.FOUNTAIN.get_center() and feast.edge, "the feast is tagged at the fountain, pointed at")
	var out := 0
	for p in d.goers:
		if p.is_alive() and not p.inside:
			out += 1
	var pips := 0
	for m in d.tags():
		if m.size == MapTag.PIP_SIZE and m.color == FestivalDirector.MARK_GOER:
			pips += 1
	t.check(out > 0 and pips == out, "a gold pip on each goer still to break (%d of %d)" % [pips, out])
	var stops := d.tour()
	t.check(stops.size() == 2 and stops[0][0] == TownLayout.FOUNTAIN.get_center() and stops[1][0] == mayor.ground_pos,
		"the tour: the fountain, then the Mayor")
	t.check(_reads_only(d, crowd) and d.hint_phase() == "", "its tags draw no random number; at first the act's own line")
	d.timeline.step(FestivalDirector.BONFIRE_AT + 1.0)
	t.check(d.hint_phase() == "packed", "the bonfire lit: the packed crowd's line")
	d.timeline.step(FestivalDirector.ADDRESS_AT - FestivalDirector.BONFIRE_AT)
	t.check(d.hint_phase() == "address" and _tag(d, "MAYOR").edge, "the Mayor speaks: his line, and he is pointed at")
	for p in d.goers:
		d._broke[p] = true
	t.check(d.broken() and _tag(d, "THE FEAST") == null and _tag(d, "MAYOR") != null and d.tags().size() == 1,
		"the festival broken: neither the feast nor its goers are tagged")
	Fest._done(s)


static func _procession(t) -> void:
	var s: Dictionary = Proc._setup()
	var d: ProcessionDirector = s.d
	var crowd: Crowd = s.crowd
	var prince := d.prince
	var first := d.tags()[0]
	t.check(prince != null and first.label == "PRINCE" and first.at == prince.ground_pos and first.edge,
		"the Prince is tagged first, pointed at")
	var ship := _tag(d, "THE SHIP")
	var steps := _tag(d, "CATHEDRAL STEPS")
	t.check(ship != null and ship.at == d.route[d.route.size() - 1] and steps != null
		and steps.at == d.route[ProcessionDirector.STEPS_LEG], "the ship and the cathedral steps are tagged")
	var seeing := d.witnesses()
	var escorts_far := 0
	for e in d.escorts:
		if e.is_alive() and not e.inside and not seeing.has(e):
			escorts_far += 1
	t.check(not seeing.is_empty() and _plain(d, ProcessionDirector.MARK_WATCHED) == seeing.size()
		and _plain(d, ProcessionDirector.MARK_ESCORT) == escorts_far,
		"his attendants are red witnesses, his escort blue (%d, %d)" % [seeing.size(), escorts_far])
	t.check(d.tour().size() == 3 and d.tour()[0][0] == prince.ground_pos, "the tour: the Prince, the steps, the dock")
	t.check(_reads_only(d, crowd) and d.hint_phase() == "", "its tags draw no random number; at first the act's own line")
	d.leg = ProcessionDirector.STEPS_LEG
	prince.ground_pos = d.route[ProcessionDirector.STEPS_LEG]
	d.timeline.step(ProcessionDirector.BLESSING_AT + 1.0)
	t.check(d.hint_phase() == "blessing", "at the steps in the blessing: its line")
	d.leg = ProcessionDirector.DOCK_LEG
	t.check(d.hint_phase() == "dock" and _tag(d, "CATHEDRAL STEPS") == null, "on the dock's leg: its line, and the steps untagged")
	d.boarded = true
	t.check(d.tags().is_empty() and d.hint_phase() == "", "gone, nothing is tagged")
	Proc._done(s)


static func _last_judgement(t) -> void:
	var night := NightState.new()
	var s: Dictionary = Judge._setup(night)
	var crowd: Crowd = s.crowd
	var town: Town = s.town
	var d := LastJudgementDirector.new().setup(s.rules, crowd, town, null) as LastJudgementDirector
	(s.rules as Rules).director = d
	t.check(MissionBook.last_judgement().director == LastJudgementDirector and JudgementDirector.new() is LastJudgementDirector,
		"Last Judgement has this director, and Judgement is one")
	var first := d.tags()[0]
	t.check(first.label == "CITADEL" and first.at == town.citadel.keep.center() and first.rise == town.citadel.keep.height and first.edge,
		"the Citadel is tagged first, at its keep's top, pointed at")
	var gates := 0
	for m in d.tags():
		if m.label == "GATE" and not m.edge:
			gates += 1
	t.check(gates == town.gates.size() and gates == 3, "each gate is tagged (%d)" % gates)
	t.check(_tag(d, "BANISHING RITE") == null and _tag(d, "BOATS") == null and d.hint_phase() == "" and d.tour().is_empty(),
		"no rite, no boats; the mission's line; no tour (the sweep plays)")
	t.check(_reads_only(d, crowd), "its tags draw no random number")
	# The tags draw on their own layer behind the HUD: the Citadel always tagged, the HUD itself stays a still picture.
	var hud := Hud.new().setup(s.rules, crowd, town, null)
	hud.advance(0.016)
	hud.advance(0.016)
	t.check(Hud.tags_shown(s.rules) and hud._tag_layer != null and hud._tag_layer.get_parent() == hud
		and hud._tag_layer.show_behind_parent and hud._drawn != "",
		"the tags have a layer behind the HUD, and the HUD keeps its still picture (%s)" % hud._drawn.left(20))
	hud.free()
	crowd.rite.begin()
	var rite := _tag(d, "BANISHING RITE")
	t.check(crowd.rite.state == BanishingRite.State.GATHERING and rite != null and rite.edge and d.hint_phase() == "rite",
		"the clergy gathering: the rite is pointed at, and its line")
	crowd.ferry.begin()
	t.check(crowd.ferry.open() and _tag(d, "BOATS") != null and _tag(d, "BOATS").edge, "the boats loading: pointed at")
	crowd.rite.state = BanishingRite.State.DONE
	town.citadel._fallen = true
	t.check(_tag(d, "CITADEL") == null and d.hint_phase() == "fallen", "the Citadel down: untagged, and the next line")
	Judge._done(s)


static func _judgement(t) -> void:
	var night := NightState.new()
	var s: Dictionary = Judge._setup(night)
	var d := Judge._start(s, night)
	var town: Town = s.town
	var stops := d.tour()
	t.check(d is LastJudgementDirector and d.tags()[0].label == "CITADEL" and stops.size() == 2
		and stops[0][0] == town.citadel.keep.center() and stops[1][0] == town.gates[0].center(),
		"Act III tags as Last Judgement does, and tours the Citadel and the Main Gate")
	Judge._done(s)
