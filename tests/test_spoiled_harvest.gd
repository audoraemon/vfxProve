extends RefCounted
## v0.11 M2 Spoiled Harvest (spec §2, HarvestDirector on RazeDirector): three granaries -- dwellings far from the Citadel --
## sealed until 1:00, 2:00 and 3:00 (tuned from 0:45, 1:45 and 2:45): a sealed one only shakes and its fire is smothered
## (review focus 4). Opened, its two carters walk from the Citadel's gate to take its five loads there one at a time; the last
## load taken empties it and loses the night. A granary burned 10 s in all (the controller's ruling: a 50-hp house falls in
## about 13 s, so 15 s would never be reached), or brought down, is spoiled; all three spoiled wins. Freed carters are borne
## (review focus 2); reserved people and houses are never taken (review focus 1).

const DT := 0.05


static func run(t) -> void:
	_setup(t)
	_sealed(t)
	_carts(t)
	_emptied(t)
	_spoiled(t)
	_win(t)
	_freed(t)
	_resume(t)
	_fell(t)
	_reserved(t)
	_mission(t)


static func _world(reserve := false) -> Dictionary:
	var def := MissionBook.spoiled_harvest()
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	var director := def.make_director() as HarvestDirector
	var held := {}
	if reserve:
		held = _hold_back(director, crowd, town)
	director.setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners, "held": held}


## Sets aside, before the director is set up (as Descent does): the dwelling nearest the first granary's spot, and the three lay
## citizens nearest the Citadel's gate. Returns them.
static func _hold_back(d: HarvestDirector, crowd: Crowd, town: Town) -> Dictionary:
	var house: Structure = null
	for s: Structure in town._built:
		if RuinWish.fits(s, "house") and (house == null or s.center().distance_to(HarvestDirector.STORE_SPOTS[0])
				< house.center().distance_to(HarvestDirector.STORE_SPOTS[0])):
			house = s
	var lay: Array[Person] = []
	for p in crowd.citizens:
		if not p.inside and p.profile.faith == CitizenProfile.Faith.NONE and not p.profile.role in Wish.NOT_LAY:
			lay.append(p)
	lay.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(HarvestDirector.CITADEL_GATE) < b.ground_pos.distance_squared_to(HarvestDirector.CITADEL_GATE))
	lay = lay.slice(0, 3)
	d.reserved.assign(lay)
	d.reserved_places.assign([house])
	return {"house": house, "lay": lay}


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


static func _labels(d: MissionDirector) -> Array:
	var out := []
	for m in d.tags():
		if m.label != "":
			out.append(m.label)
	return out


static func _setup(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var ok := d.targets.size() == 3
	for i in d.targets.size():
		var g := d.targets[i]
		ok = ok and RuinWish.fits(g, "house") and d.targets.find(g) == i and d.is_sealed(g) and int(d.loads[g]) == HarvestDirector.LOADS
		ok = ok and g.center().distance_to(HarvestDirector.CITADEL_GATE) > 15.0
	t.check(ok, "three granaries: different dwellings far from the Citadel, sealed, five loads each")
	var at := []
	for e in d.timeline.upcoming(3):
		at.append(float(e.at))
	t.check(at == HarvestDirector.OPEN_AT, "they open at 1:00, 2:00 and 3:00 (%s)" % [at])
	t.check(_labels(d) == ["GRANARY - OPENS IN 1:00", "GRANARY - OPENS IN 2:00", "GRANARY - OPENS IN 3:00"]
		and d.hint_phase() == "sealed", "tagged sealed, with the time to each opening (%s)" % [_labels(d)])
	var stops := d.tour()
	t.check(stops.size() == 4 and String(stops[0][1]) == "The south-west granary. Its doors open at 1:00."
		and String(stops[3][1]) == "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled.",
		"the tour: the three granaries, then the Citadel")
	t.check((s.banners as Array).has("SPOIL THE HARVEST"), "its opening banner")
	_done(s)


static func _sealed(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	var hp := g.hp
	g.damage(500.0, g.center(), &"fire")
	crowd.fires.ignite(g, 0.6)
	_run(s, 1.0)
	t.check(not g.destroyed and is_equal_approx(g.hp, hp) and not crowd.fires.is_burning(g) and not d.razed(g)
		and is_zero_approx(d.burned(g)), "a sealed granary only shakes, and its fire is smothered (review focus 4)")
	_done(s)


static func _carts(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, float(HarvestDirector.OPEN_AT[0]) + DT * 2.0)
	var crew: Array = d.carters[g]
	var ok := not d.is_sealed(g) and d.opened.size() == 1 and d.opened[0] == g and crew.size() == HarvestDirector.CARTERS
	for c: Person in crew:
		ok = ok and c.mind == Person.Mind.DUTY and c.goal().distance_to(d.doors[g]) < 0.5
	t.check(ok and (s.banners as Array).has("THE SOUTH-WEST GRANARY OPENS") and d.hint_phase() == "",
		"1:00: the south-west granary opens, its two carters set out for it")
	t.check(_labels(d)[0] == "GRANARY - 5 LEFT", "it is tagged with its loads (%s)" % _labels(d)[0])
	var c0: Person = crew[0]
	_arrive(c0, d.doors[g])
	_run(s, HarvestDirector.TICK + DT)
	t.check(int(d.loads[g]) == HarvestDirector.LOADS - 1 and c0.goal().distance_to(d.citadel_door) < 0.5,
		"a carter at its door takes a load and makes for the Citadel")
	_arrive(c0, d.citadel_door)
	_run(s, HarvestDirector.TICK + DT)
	t.check(int(d.loads[g]) == HarvestDirector.LOADS - 1 and c0.goal().distance_to(d.doors[g]) < 0.5,
		"delivered, he goes back for the next")
	c0.mind = Person.Mind.CONFUSED
	_run(s, HarvestDirector.TICK + DT)
	t.check(c0.mind == Person.Mind.CONFUSED, "held by the god, a carter is left be")
	_done(s)


static func _emptied(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var rules: Rules = s.rules
	var g := d.targets[0]
	_run(s, float(HarvestDirector.OPEN_AT[0]) + DT * 2.0)
	d.loads[g] = 1
	_arrive(d.carters[g][0], d.doors[g])
	_run(s, HarvestDirector.TICK + DT)
	t.check(d.emptied == g and rules.finished and not rules.won and rules.over_reason == "emptied"
		and (s.banners as Array).has("A GRANARY IS EMPTIED"), "the last load taken empties it: the night is lost")
	_done(s)


static func _spoiled(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	_run(s, float(HarvestDirector.OPEN_AT[0]) + DT * 2.0)
	crowd.fires.ignite(g, 0.5)
	_run(s, 5.0)
	t.check(d.burned(g) > 4.0 and not d.razed(g) and d.hint_phase() == "burning" and _labels(d)[0].begins_with("GRANARY - BURNING"),
		"open and alight, it burns toward its spoiling (%.1f s)" % d.burned(g))
	if crowd.fires.is_burning(g):
		crowd.fires._put_out(g, true)
	_run(s, 1.0)
	t.check(d.burned(g) > 4.0 and not d.razed(g), "put out, the time it burned is kept")
	crowd.fires.ignite(g, 0.5)
	_run(s, HarvestDirector.SPOIL_SECONDS)
	var crew: Array = d.carters[g]
	t.check(d.razed(g) and (s.banners as Array).has("A GRANARY IS SPOILED") and crew.is_empty(),
		"10 s in all: spoiled, and its carters go home")
	var h := d.targets[1]
	d.unseal(h)
	h.destroy(h.center(), &"fire")
	_run(s, DT * 2.0)
	t.check(d.razed(h) and d.razed_count() == 2, "an open granary brought down is spoiled too")
	_done(s)


static func _win(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var rules: Rules = s.rules
	for g in d.targets:
		d.unseal(g)
		g.destroy(g.center(), &"fire")
	_run(s, DT * 2.0)
	t.check(d.all_razed() and rules.finished and rules.won and rules.over_reason == "spoiled"
		and rules.objectives[0].hud_text(rules) == "Granaries spoiled 3 / 3", "all three spoiled: the harvest is spoiled")
	t.check(int(d.report().spoiled) == 3 and not bool(d.report().emptied), "the results count them")
	_done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	_run(s, float(HarvestDirector.OPEN_AT[0]) + DT * 2.0)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	_run(s, HarvestDirector.TICK + DT)
	crowd._field.kill(c0, &"fire")
	crowd._field.remove(c0)
	crowd.citizens.erase(c0)
	c0.free()
	_run(s, HarvestDirector.TICK * 3.0)
	d.tags()
	t.check(int(d.loads[g]) == HarvestDirector.LOADS - 1 and d.hint_phase() == "",
		"a carter killed with his load and freed: the load is lost, the night plays on (review focus 2)")
	_done(s)


static func _resume(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, float(HarvestDirector.OPEN_AT[0]) + DT * 2.0)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	c0.mind = Person.Mind.PANIC
	_run(s, HarvestDirector.TICK + DT)
	var left := int(d.loads[g])
	c0.mind = Person.Mind.CALM
	_run(s, HarvestDirector.TICK + DT)
	t.check(left == HarvestDirector.LOADS and int(d.loads[g]) == HarvestDirector.LOADS - 1 and c0.mind == Person.Mind.DUTY,
		"a frightened carter takes nothing; calm again, he takes his errand up where he stands")
	_done(s)


static func _fell(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	g.destroy(g.center(), &"stone")
	_run(s, float(HarvestDirector.OPEN_AT[0]) + DT * 2.0)
	t.check(d.razed(g) and d.is_sealed(g) and d.opened.is_empty() and d.hint_phase() == "sealed",
		"a sealed granary somehow brought down is spoiled all the same, and never opens")
	_done(s)


static func _reserved(t) -> void:
	var s := _world(true)
	var d: HarvestDirector = s.d
	var held: Dictionary = s.held
	_run(s, float(HarvestDirector.OPEN_AT[0]) + DT * 2.0)
	var crew: Array = d.carters[d.targets[0]]
	var ok := d.targets.size() == 3 and not d.targets.has(held.house) and crew.size() == HarvestDirector.CARTERS
	for c in crew:
		ok = ok and not (held.lay as Array).has(c)
	t.check(ok, "a reserved house is never a granary, a reserved citizen never a carter")
	_done(s)


static func _mission(t) -> void:
	var m := MissionBook.spoiled_harvest()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.id == "spoiled_harvest" and m.tier == 1 and m.director == HarvestDirector and is_equal_approx(m.clock, 300.0)
		and m.profile == "unaware" and reasons == ["spoiled", "dawn"] and m.bonuses().is_empty(),
		"Spoiled Harvest: Tier 1's numbers, its director; spoil them, dawn (%s)" % [reasons])
	t.check(MissionBook.get_mission("spoiled_harvest").id == "spoiled_harvest", "found by id")
	t.check(ResultsScreen.title_for(true, "spoiled") == "THE HARVEST IS SPOILED"
		and ResultsScreen.title_for(false, "emptied") == "A GRANARY IS EMPTIED", "its results' titles")
