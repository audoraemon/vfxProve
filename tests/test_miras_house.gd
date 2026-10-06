extends RefCounted
## v0.10 Mira's House (MirasHouseDirector): GRIEVING (12) grieving near her door, Halcyon's Faithful about the town; a
## grieving citizen whispered or lured to the door goes in, reads for READ_SECONDS (8 s) and comes out a Believer; a
## Faithful who sees someone go in turns them away and reports, one who sees a Believer come out reports; a report
## delivered, a seen death or the bell fills the Gaze; BelieversObjective.NEED (4) Believers out at dawn win.

const DT := 0.05


static func _setup() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	var def := MissionBook.miras_house()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as MirasHouseDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var lines := []
	rules.subtitle.connect(func(text: String) -> void: lines.append(text))
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners, "lines": lines}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## Every Faithful moved well away from `at` (nobody of the Faith can see there).
static func _blind(d: MirasHouseDirector, at: Vector2) -> void:
	for f in d.faithful:
		if is_instance_valid(f) and f.ground_pos.distance_to(at) <= MirasHouseDirector.SIGHT + 1.0:
			f.ground_pos = at + Vector2(MirasHouseDirector.SIGHT + 8.0, 0.0)


## Grieving `g` whispered to the door and standing there.
static func _bring(d: MirasHouseDirector, g: Person) -> void:
	g.whisper(d.door, 8.0)
	_arrive(g, d.door)


## The first of the director's tags labelled `label`, or null.
static func _tag(d: MissionDirector, label: String) -> MapTag:
	for m in d.tags():
		if m.label == label:
			return m
	return null


static func run(t) -> void:
	_cast(t)
	_reading(t)
	_seen(t)
	_gaze(t)
	_ending(t)
	_events(t)
	_focus(t)
	_lines(t)
	_tags(t)
	_freed(t)
	_loose_ends(t)


static func _cast(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	t.check(d.house != null and d.house.kind == Structure.Kind.HOUSE and d.door != Vector2.INF
		and d.door.distance_to(d.house.center()) < 3.0, "Mira's house is a west-quarter house with a door")
	t.check(d.grieving.size() == MirasHouseDirector.GRIEVING and d.gaze != null and d.gaze.value == 0.0,
		"the grieving chosen, and the Gaze at 0")
	var faithful_ok := d.faithful.size() >= MirasHouseDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL and not d.grieving.has(f)
	t.check(faithful_ok, "the Faithful chosen, none of them grieving (%d)" % d.faithful.size())
	t.check(d.venn != null and d.faithful.has(d.venn), "the Inquisitor is one of the Faithful")
	var grieving_tags := 0
	for m in d.tags():
		grieving_tags += 1 if m.color == MirasHouseDirector.MARK_GRIEVING else 0
	t.check(grieving_tags == MirasHouseDirector.GRIEVING, "the HUD marks the grieving")
	t.check(d.timeline != null, "the night keeps a timeline for its windows")
	_done(s)


static func _reading(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var g := d.grieving[0]
	_blind(d, d.door)
	_bring(d, g)
	_run(s, DT * 2.0)
	t.check(g.inside and not g.visible and d.inside().has(g), "a whispered grieving citizen at the door goes in")
	_run(s, MirasHouseDirector.READ_SECONDS - 1.0)
	t.check(g.inside and d.believers.is_empty(), "still reading a second short of READ_SECONDS")
	_blind(d, d.door)
	_run(s, 1.5)
	t.check(not g.inside and g.visible and d.believers.has(g) and g.profile.faith == CitizenProfile.Faith.BELIEVER
		and d.journal == g and d.believers_outside() == 1, "after READ_SECONDS they come out a Believer, carrying the journal")
	t.check(d.reports.is_empty(), "nobody of the Faith saw")
	var marked_believer := false
	for m in d.tags():
		marked_believer = marked_believer or (m.at == g.ground_pos and m.color == MirasHouseDirector.MARK_BELIEVER)
	t.check(marked_believer, "the Believer wears the ember mark")

	# Any face of the house will do for a whisper (the drawn door may be on +x), and a Will-o'-Wisp at the door brings its
	# lured in from the ring it stands them on.
	var side := d.grieving[2]
	_blind(d, d.door)
	var east := Vector2(d.house.footprint.end.x + 0.3, d.house.footprint.get_center().y)
	side.whisper(east, 8.0)
	_arrive(side, east)
	_run(s, DT * 2.0)
	t.check(side.inside, "a whisper to the house's other face brings them in too")
	var lured := d.grieving[3]
	_blind(d, d.door)
	lured.lure(d.door, 6.0)
	_arrive(lured, d.door + Vector2(1.4, 0.0))
	_run(s, DT * 2.0)
	t.check(lured.inside, "a grieving citizen lured to the door goes in from the wisp's ring")
	var looker := d.grieving[4]
	_blind(d, d.door)
	looker.observe(d.door + Vector2(12.0, 0.0), 5.0)
	_arrive(looker, d.door)
	_run(s, DT * 2.0)
	t.check(not looker.inside, "one stopping at the door to look at something far off stays out")

	# Review focus 5: a grieving citizen walking past on their own day does not go in.
	var h := d.grieving[1]
	_blind(d, d.door)
	_arrive(h, d.door)
	h.mind = Person.Mind.CALM
	_run(s, DT * 2.0)
	t.check(not h.inside and d.reports.is_empty(), "a grieving citizen passing the door on their own day stays out")
	_done(s)


static func _seen(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var g := d.grieving[0]
	_blind(d, d.door)
	var f := d.faithful[0]
	f.ground_pos = d.door + Vector2(2.0, 0.0)
	_bring(d, g)
	_run(s, DT * 2.0)
	t.check(not g.inside and d.reports.size() == 1 and d.reports[0].carrier == f,
		"a Faithful who sees someone go in turns them away and runs to report")
	_run(s, 1.0)
	t.check(not g.inside and d.reports.size() == 1, "the turned-away reader does not slip in while still at the door")

	# A Faithful held by Discord sees nothing.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var g2 := d2.grieving[0]
	_blind(d2, d2.door)
	var f2 := d2.faithful[0]
	f2.ground_pos = d2.door + Vector2(2.0, 0.0)
	f2.confuse(10.0)
	_bring(d2, g2)
	_run(s2, DT * 2.0)
	t.check(g2.inside and d2.reports.is_empty(), "a Faithful confused by Discord sees nothing")
	# Seen coming out.
	_run(s2, MirasHouseDirector.READ_SECONDS - 0.5)
	var f3 := d2.faithful[1]
	f3.ground_pos = d2.door + Vector2(-2.0, 0.0)
	_run(s2, 1.0)
	t.check(d2.believers.has(g2) and d2.reports.size() == 1, "a Believer seen coming out is reported, but believes")
	_done(s)
	_done(s2)


static func _gaze(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	var f := d.faithful[0]
	f.ground_pos = d.door + Vector2(2.0, 0.0)
	_bring(d, d.grieving[0])
	_run(s, DT * 2.0)
	t.check(d.reports.size() == 1, "a report is on its way")
	_arrive(d.reports[0].carrier, d.temple_door)
	_run(s, DT * 3.0)
	t.check(d.gaze.is_full() and rules.finished and not rules.won and rules.over_reason == "gaze",
		"a report reaching the Temple fills the Gaze, and the night is lost (%s)" % rules.over_reason)
	_done(s)

	# A seen death adds 10.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var victim := d2.faithful[3]
	var near := d2.faithful[4]
	near.ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s2.crowd as Crowd)._field.kill(victim, &"doom")
	_run(s2, DT * 3.0)
	t.near(d2.gaze.value, GazeMeter.SEEN_DEATH, 0.001, "a seen death adds 10 to the Gaze")
	_done(s2)

	# Review focus 4: the bell, rung by the town's own alarm, fills it.
	var s3 := _setup()
	var d3: MirasHouseDirector = s3.d
	var crowd3: Crowd = s3.crowd
	if crowd3.bell != null:
		crowd3.bell.state = BellNetwork.State.RUNG
	_run(s3, DT * 2.0)
	t.check(crowd3.bell == null or ((s3.rules as Rules).finished and (s3.rules as Rules).over_reason == "gaze"),
		"the bell filling the Gaze loses the night")
	_done(s3)


static func _ending(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var rules: Rules = s.rules
	for i in BelieversObjective.NEED:
		var g := d.grieving[i]
		g.profile.faith = CitizenProfile.Faith.BELIEVER
		d.believers.append(g)
	d.journal = d.grieving[0]
	rules.time_left = DT
	_run(s, DT * 2.0)
	t.check(rules.finished and rules.won and rules.over_reason == "believers", "enough Believers out at dawn win the night")
	var res := rules.result()
	t.check(int(res.get("believers", -1)) == BelieversObjective.NEED, "the results count them")
	var earned := []
	for b: Dictionary in res.bonuses:
		earned.append(bool(b.earned))
	t.check(earned == [true, true], "no death and the journal out: both bonuses (%s)" % [earned])
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	for i in BelieversObjective.NEED - 1:
		d2.believers.append(d2.grieving[i])
	(s2.rules as Rules).time_left = DT
	_run(s2, DT * 2.0)
	t.check((s2.rules as Rules).finished and not (s2.rules as Rules).won and (s2.rules as Rules).over_reason == "few",
		"one short at dawn loses it")
	_done(s2)


static func _events(t) -> void:
	# 0:40 -- the Inquisitor searches; at Mira's door with someone inside, she reports at once.
	var s := _setup()
	var d: MirasHouseDirector = s.d
	t.check(d.timeline.upcoming(4).size() >= 3, "the night's windows are on the strip")
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(d.venn_searching and d.venn.mind == Person.Mind.DUTY, "at 0:40 the Inquisitor starts her search")
	_blind(d, d.door)
	_bring(d, d.grieving[0])
	_run(s, DT * 2.0)
	t.check(d.grieving[0].inside, "someone is inside")
	d._venn_i = d._venn_houses.size() - 1
	_arrive(d.venn, d.door)
	d.venn.go_duty(d.door)
	_arrive(d.venn, d.door)
	_run(s, DT * 2.0)
	t.check(d.reports.size() == 1 and d.reports[0].carrier == d.venn and not d.venn_searching,
		"at Mira's door with someone inside, the Inquisitor reports")
	_done(s)

	# 1:15 -- a Believer cries out; whispered back in, no report.
	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	var b := d2.grieving[0]
	b.profile.faith = CitizenProfile.Faith.BELIEVER
	d2.believers.append(b)
	_run(s2, MirasHouseDirector.SHOUT_AT + DT)
	t.check(d2.shouter == b and b.mind == Person.Mind.DUTY and _tag(d2, "CRYING OUT") != null and _tag(d2, "CRYING OUT").at == b.ground_pos,
		"at 1:15 the newest Believer runs out crying, and the HUD marks them")
	_blind(d2, d2.door)
	_bring(d2, b)
	_run(s2, DT * 2.0)
	t.check(b.inside and d2.shouter == null, "whispered back into the house, the cry is over")
	_run(s2, 5.0)
	t.check(d2.reports.is_empty(), "and nobody reports the cry (still reading inside)")
	_done(s2)

	# ... and left crying with a Faithful in earshot: a report.
	var s3 := _setup()
	var d3: MirasHouseDirector = s3.d
	var b3 := d3.grieving[0]
	d3.believers.append(b3)
	_run(s3, MirasHouseDirector.SHOUT_AT + DT)
	_run(s3, MirasHouseDirector.SHOUT_SECONDS - DT * 4.0)
	var f3 := d3.faithful[2]
	f3.ground_pos = b3.ground_pos + Vector2(3.0, 0.0)
	f3.mind = Person.Mind.CALM
	_run(s3, DT * 8.0)
	t.check(d3.shouter == null and d3.reports.size() == 1, "a cry left 15 s with a Faithful in earshot is reported")
	_done(s3)

	# 1:45 -- the Vigil passes; liners stand by the door for 30 s.
	var s4 := _setup()
	var d4: MirasHouseDirector = s4.d
	_run(s4, MirasHouseDirector.VIGIL_AT + DT)
	t.check(d4.vigil != null and d4.vigil.active and d4.liners.size() > 0, "at 1:45 the Vigil sets out and Faithful line the street")
	var lined := true
	for f in d4.liners:
		lined = lined and f.mind == Person.Mind.DUTY and f.anchor.distance_to(d4.door) <= MirasHouseDirector.SIGHT
	t.check(lined, "each liner stands within sight of the door")
	_run(s4, MirasHouseDirector.VIGIL_SECONDS)
	t.check(d4.liners.is_empty(), "after 30 s the liners go back to their day")
	_done(s4)

	# 2:00 -- the house burns: everyone inside runs out, unconverted; nobody goes in; at dawn the roof falls.
	var s5 := _setup()
	var d5: MirasHouseDirector = s5.d
	_run(s5, MirasHouseDirector.FIRE_AT - 3.0)
	_blind(d5, d5.door)
	var g5 := d5.grieving[0]
	_bring(d5, g5)
	_run(s5, DT * 2.0)
	t.check(g5.inside, "a reader goes in at 1:57")
	_run(s5, 3.0)
	t.check(d5.burning and not g5.inside and not d5.believers.has(g5), "at 2:00 the fire drives them out, unread")
	_blind(d5, d5.door)
	_bring(d5, d5.grieving[1])
	_run(s5, DT * 2.0)
	t.check(not d5.grieving[1].inside, "nobody goes into a burning house")
	(s5.rules as Rules).time_left = DT
	_run(s5, DT * 2.0)
	t.check(d5.roof_fallen and d5.house.destroyed, "at dawn the roof falls")
	_done(s5)


## Review focus 1 and 2: the people an event needs are gone; the house falls early with people inside.
static func _focus(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	(s.crowd as Crowd)._field.kill(d.venn, &"doom")
	_run(s, MirasHouseDirector.SHOUT_AT + DT)
	t.check(not d.venn_searching and d.shouter == null and d.reports.is_empty(),
		"a dead Inquisitor never searches, and with no Believer out nobody cries")
	_run(s, MirasHouseDirector.VIGIL_AT - MirasHouseDirector.SHOUT_AT)
	var none_dead := true
	for f in d.liners:
		none_dead = none_dead and f.is_alive()
	t.check(none_dead, "no dead Faithful lines the street")
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	_blind(d2, d2.door)
	_bring(d2, d2.grieving[0])
	_run(s2, DT * 2.0)
	d2.house.destroy(d2.house.center(), &"lightning")
	_run(s2, DT * 2.0)
	t.check(not d2.grieving[0].inside and d2.grieving[0].visible and d2.inside().is_empty(),
		"a house destroyed early lets everyone inside out at the door")
	_blind(d2, d2.door)
	_bring(d2, d2.grieving[1])
	_run(s2, DT * 2.0)
	t.check(not d2.grieving[1].inside, "and nobody goes into its ruins")
	(s2.rules as Rules).time_left = DT
	_run(s2, DT * 2.0)
	t.check(d2.roof_fallen, "dawn passes over the ruins quietly")
	_done(s2)


## Cael's lines (v0.10 M5, spec §5.2): as the Inquisitor sets out, and as the house burns. Review focus 2: a dead
## Inquisitor never searches, and he does not name her.
static func _lines(t) -> void:
	var s := _setup()
	var lines: Array = s.lines
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(lines == [CampaignText.cael_line(MissionBook.MIRAS_HOUSE, "venn")],
		"as the Inquisitor sets out, Cael names her (%s)" % [lines])
	_run(s, MirasHouseDirector.FIRE_AT - MirasHouseDirector.VENN_AT)
	t.check(lines.size() == 2 and lines[1] == CampaignText.cael_line(MissionBook.MIRAS_HOUSE, "fire"),
		"as the house burns, he speaks again (%s)" % [lines])
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	(s2.crowd as Crowd)._field.kill(d2.venn, &"doom")
	_run(s2, MirasHouseDirector.VENN_AT + DT)
	t.check((s2.lines as Array).is_empty(), "with the Inquisitor dead, nothing is said of her (%s)" % [s2.lines])
	_done(s2)


## v0.10 M6 (spec §4.1): the map's tags -- the house first, named, outlined and pointed at from the edge; its door clear
## or watched, a red diamond on each watcher; the Inquisitor, pointed at while she searches; a runner and the Temple
## while a report runs; the crying Believer, pointed at; no door once the house burns, no house once it falls; nobody
## dead is tagged (review focus 2); the hint's phases, as the HUD shows them.
static func _tags(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	# v0.10 M6 final review: at its start no event meets the hint plate, so it stays under the objective rows.
	var start := Hud.new().setup(s.rules, s.crowd, s.town, null)
	t.check(start.hint_top() == 2.0 + 5.0 + Hud.ROW_H * float(start.objective_rows().size()) + 4.0
		and not start.hint_rect().intersects(start.events_rect(Hud.SCREEN_W)),
		"at its start the hint stays under the rows, clear of the events (%s)" % start.hint_top())
	start.free()
	var house: MapTag = d.tags()[0]
	t.check(house.label == "MIRA'S HOUSE" and house.at == d.house.center() and house.rise == d.house.height
		and house.edge and house.outline == d.house.footprint and house.color == MirasHouseDirector.MARK_HOUSE,
		"the house comes first: named, outlined, pointed at from the edge")
	_blind(d, d.door)
	var door := _tag(d, "DOOR - CLEAR")
	t.check(door != null and door.at == d.door and not door.edge and door.color == MirasHouseDirector.MARK_CLEAR,
		"no Faithful in sight: the door is clear")
	var f: Person = null
	for p in d.faithful:
		if p != d.venn and p.is_alive():
			f = p
			break
	_arrive(f, d.door + Vector2(1.0, 0.0))
	var red := false
	for m in d.tags():
		red = red or (m.at == f.ground_pos and m.color == MirasHouseDirector.MARK_WATCHED and m.label == "")
	t.check(_tag(d, "DOOR - WATCHED") != null and _tag(d, "DOOR - CLEAR") == null and red,
		"a Faithful by it: the door is watched, and the watcher marked red")
	var venn := _tag(d, "INQUISITOR")
	t.check(venn != null and venn.at == d.venn.ground_pos and venn.color == MirasHouseDirector.MARK_VENN and not venn.edge,
		"the Inquisitor is named; no arrow before her search")
	d._report(f, d.temple_door)
	var runner := _tag(d, "TO THE TEMPLE")
	var temple := _tag(d, "TEMPLE")
	t.check(runner != null and runner.at == f.ground_pos and runner.edge and temple != null and temple.at == d.temple_door
		and temple.edge, "a report on its way: the runner and the Temple, both pointed at from the edge")
	# The Temple is listed after the Inquisitor (spec §4.1's order).
	var order := PackedStringArray()
	for m in d.tags():
		if m.label in ["INQUISITOR", "TEMPLE"]:
			order.append(m.label)
	t.check(order == PackedStringArray(["INQUISITOR", "TEMPLE"]), "the Temple is listed after the Inquisitor (%s)" % order)
	d.reports.clear()
	t.check(_tag(d, "TO THE TEMPLE") == null and _tag(d, "TEMPLE") == null, "no report running: neither")
	var g := d.grieving[0]
	d.believers.append(g)
	d.shouter = g
	var cry := _tag(d, "CRYING OUT")
	t.check(cry != null and cry.at == g.ground_pos and cry.edge and d.marker() == Vector2.INF,
		"the crying Believer is tagged and pointed at (the director keeps no marker of its own)")
	(s.crowd as Crowd)._field.kill(g, &"fire")
	t.check(_tag(d, "CRYING OUT") == null, "dead, they are not tagged (review focus 2)")
	t.check(d.hint_phase() == "", "fewer than four believe: the mission's own line")
	for i in range(1, 1 + BelieversObjective.NEED):
		d.believers.append(d.grieving[i])
	t.check(d.hint_phase() == "four", "four Believers out: the hint says keep them")
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	t.check(hud.hint_text() == MissionHints.line(MissionBook.MIRAS_HOUSE, "four") and hud.hint_top() > Hud.ROW_H,
		"the HUD shows the phase's line, under the objective rows")
	hud.free()
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(d.venn_searching and _tag(d, "INQUISITOR") != null and _tag(d, "INQUISITOR").edge,
		"searching, the Inquisitor is pointed at from the edge")
	(s.crowd as Crowd)._field.kill(d.venn, &"fire")
	t.check(_tag(d, "INQUISITOR") == null, "struck down, she is not tagged (review focus 2)")
	d._burn()
	t.check(_tag(d, "DOOR - CLEAR") == null and _tag(d, "DOOR - WATCHED") == null and d.hint_phase() == "burning",
		"the house burning: no door, and the hint says so")
	d.house.destroy(d.house.center(), &"fire")
	t.check(_tag(d, "MIRA'S HOUSE") == null, "the house gone, its tag goes")
	_done(s)


## v0.10 M6 (review focus 2): a Faithful who has fallen is no watcher; once their body is freed (as it is when the death
## fade ends) they are still none, and neither they nor a freed Inquisitor stops the rest being seen or the tags being
## made -- the HUD asks for them every frame. A headless test frees no body by itself, so this one frees them by hand.
static func _freed(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	_blind(d, d.door)
	var by: Array[Person] = []
	for p in d.faithful:
		if p != d.venn and by.size() < 2:
			by.append(p)
	for p in by:
		_arrive(p, d.door + Vector2(1.0, 0.0))
	t.check(d.watchers(d.door, MirasHouseDirector.SIGHT, d.venn).size() == 2, "two Faithful by the door: two watchers")
	(s.crowd as Crowd)._field.kill(by[0], &"fire")
	var alone := d.watchers(d.door, MirasHouseDirector.SIGHT, d.venn)
	t.check(alone.size() == 1 and alone[0] == by[1], "one has fallen: the other watches alone")
	by[0].free()
	var still := d.watchers(d.door, MirasHouseDirector.SIGHT)
	t.check(d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) == by[1] and still.size() == 1 and still[0] == by[1],
		"a freed body ahead of them in the list: the other is still seen, and nothing is raised")
	d.venn.free()
	t.check(_tag(d, "DOOR - WATCHED") != null and _tag(d, "INQUISITOR") == null,
		"the Inquisitor's body freed too: the tags are still made, the door watched, and no one is named")
	# A runner struck down, and a grieving body freed: their tags go.
	var runner: Person = by[1]
	d._report(runner, d.temple_door)
	(s.crowd as Crowd)._field.kill(runner, &"fire")
	t.check(_tag(d, "TO THE TEMPLE") == null and _tag(d, "TEMPLE") == null, "a runner struck down: no runner, no Temple")
	var grieving_before := 0
	for m in d.tags():
		grieving_before += 1 if m.color == MirasHouseDirector.MARK_GRIEVING else 0
	d.grieving[0].free()
	var grieving_after := 0
	for m in d.tags():
		grieving_after += 1 if m.color == MirasHouseDirector.MARK_GRIEVING else 0
	t.check(grieving_after == grieving_before - 1, "a grieving body freed: one fewer grieving tag")
	_done(s)


## v0.10 M5: the Inquisitor already running to the Temple at 0:40 is not turned to her search, and Cael does not name her
## (review focus 2); with no Faithful free, the Vigil does not pass.
static func _loose_ends(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	# Far from the Temple, so the report is still on its way at 0:40 (nobody walks in a headless test).
	_arrive(d.venn, d.door + Vector2(2.0, 0.0))
	d._report(d.venn, d.temple_door)
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(not d.venn_searching and d.reports.size() == 1 and d.reports[0].carrier == d.venn
		and d.venn.anchor.distance_to(d.temple_door) < 0.5 and not d.timeline.fired_ids().has("venn")
		and (s.lines as Array).is_empty(), "an Inquisitor carrying a report runs on to the Temple, unsearching, unnamed")
	_done(s)

	var s2 := _setup()
	var d2: MirasHouseDirector = s2.d
	for f in d2.faithful:
		if f != d2.venn:  # the Inquisitor never walks the Vigil; she stays out for her own search
			f.inside = true
	_run(s2, MirasHouseDirector.VIGIL_AT + DT)
	t.check(d2.vigil == null and not (s2.banners as Array).has("THE VIGIL PASSES"),
		"with no Faithful free, the Vigil does not pass and no banner says it does")
	_done(s2)
