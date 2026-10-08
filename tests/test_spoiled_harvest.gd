extends RefCounted
## v0.11 M2 Spoiled Harvest (spec §2, HarvestDirector on RazeDirector, as the controller's Task 3 fix-round ruling reshapes it:
## work, not waiting): three granaries -- dwellings far from the Citadel -- open to the god from the start, each with a
## watchman at its door. While he is alive, out of doors, calm and at his post he beats out any fire on his granary after 3 s,
## and what it had burned is forgotten; frightened, held, dead or away he does not (he returns 20 s after a fright, a relief
## comes 30 s after one fell). The carts set out from the Citadel's gate for each granary at 0:30, 1:30 and 2:30 to take its
## loads one at a time; the last load taken empties it and loses the night. A granary burned 10 s in all (the controller's
## Task 3 ruling: a 50-hp house falls in about 13 s, so 15 s would never be reached), or brought down, is spoiled; all three
## spoiled wins. Freed carters and watchmen are borne (review focus 2); reserved people and houses are never taken (review focus
## 1). The Raze base keeps an optional seal, tested here on a bare subclass.

const DT := 0.05


## A bare RazeDirector with its one target sealed (v0.11 M2 fix round 1): the base's optional seal, which HarvestDirector no
## longer uses.
class Walled:
	extends RazeDirector

	func _begin() -> void:
		var h := _house_near(Vector2(-9.0, 12.0))
		targets.append(h)
		seal(h)
		spoil_seconds = 10.0


static func run(t) -> void:
	_setup(t)
	_smother(t)
	_unguarded(t)
	_return(t)
	_relief(t)
	_carts(t)
	_staggered(t)
	_emptied(t)
	_spoiled(t)
	_win(t)
	_freed(t)
	_resume(t)
	_walled(t)
	_reserved(t)
	_mission(t)


static func _world(reserve := false, walled := false) -> Dictionary:
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
	var director: RazeDirector = Walled.new() if walled else def.make_director() as RazeDirector
	var held := {}
	if reserve:
		held = _hold_back(director as HarvestDirector, crowd, town)
	director.setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"banners": banners, "held": held}


## Sets aside, before the director is set up (as Descent does): the dwelling nearest the first granary's spot, and the lay
## citizen nearest each granary's spot and the three nearest the Citadel's gate. Returns them.
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
	var held: Array[Person] = []
	for spot: Vector2 in HarvestDirector.STORE_SPOTS + [HarvestDirector.CITADEL_GATE]:
		lay.sort_custom(func(a: Person, b: Person) -> bool: return a.ground_pos.distance_squared_to(spot) < b.ground_pos.distance_squared_to(spot))
		for p in lay.slice(0, 3 if spot == HarvestDirector.CITADEL_GATE else 1):
			if not held.has(p):
				held.append(p)
		lay.assign(lay.filter(func(p: Person) -> bool: return not held.has(p)))
	d.reserved.assign(held)
	d.reserved_places.assign([house])
	return {"house": house, "lay": held}


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


## Runs `seconds`, holding `p` in `mind` (people are never thought here, but a fright decays by itself).
static func _hold(s: Dictionary, p: Person, mind: Person.Mind, seconds: float) -> void:
	for i in roundi(seconds / DT):
		p.mind = mind
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


## `p` killed, as a power does (he stays a corpse in the crowd).
static func _kill(s: Dictionary, p: Person) -> void:
	(s.crowd as Crowd)._field.kill(p, &"doom")


## `p` killed and his body freed after its death fade (review focus 2).
static func _free(s: Dictionary, p: Person) -> void:
	var crowd: Crowd = s.crowd
	crowd._field.kill(p, &"fire")
	crowd._field.remove(p)
	crowd.citizens.erase(p)
	p.free()


static func _setup(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var ok := d.targets.size() == 3
	var men := []
	for i in d.targets.size():
		var g := d.targets[i]
		var man := d.watchman(g)
		ok = ok and RuinWish.fits(g, "house") and d.targets.find(g) == i and not d.is_sealed(g) and int(d.loads[g]) == HarvestDirector.LOADS
		ok = ok and g.center().distance_to(HarvestDirector.CITADEL_GATE) > 15.0
		ok = ok and man != null and d.guarding(g) and not men.has(man) and man.profile.faith == CitizenProfile.Faith.NONE \
			and not man.profile.role in Wish.NOT_LAY and g.distance_to(man.ground_pos) <= HarvestDirector.GUARD_REACH
		men.append(man)
	t.check(ok, "three granaries: different dwellings far from the Citadel, none sealed, six loads each, a lay watchman on guard at each")
	var at := []
	for e in d.timeline.upcoming(3):
		at.append(float(e.at))
	t.check(at == HarvestDirector.CART_AT, "their carts set out at 0:30, 1:30 and 2:30 (%s)" % [at])
	t.check(_labels(d) == ["GRANARY - CARTS IN 0:30", "GRANARY - CARTS IN 1:30", "GRANARY - CARTS IN 2:30", "WATCHMAN", "WATCHMAN",
		"WATCHMAN"] and d.hint_phase() == "", "tagged with the time to their carts, and a watchman at each (%s)" % [_labels(d)])
	var stops := d.tour()
	t.check(stops.size() == 4 and String(stops[0][1]) == "The south-west granary. Its watchman puts out fires. Its carts set out at 0:30."
		and String(stops[3][1]) == "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled.",
		"the tour: the three granaries, then the Citadel")
	t.check((s.banners as Array).has("SPOIL THE HARVEST"), "its opening banner")
	_done(s)


static func _smother(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	crowd.fires.ignite(g, 0.6)
	_run(s, HarvestDirector.SMOTHER_AFTER - 1.0)
	t.check(crowd.fires.is_burning(g) and d.burned(g) > 1.0 and d.hint_phase() == "watchman"
		and _labels(d)[0].begins_with("GRANARY - BURNING"), "a calm watchman at his post lets it burn at first (%.1f s)" % d.burned(g))
	_run(s, 1.5)
	t.check(not crowd.fires.is_burning(g) and is_zero_approx(d.burned(g)) and not d.razed(g) and not g.destroyed,
		"then beats it out, and what it had burned is forgotten")
	crowd.fires.ignite(g, 0.6)
	_run(s, HarvestDirector.SMOTHER_AFTER + 0.5)
	t.check(not crowd.fires.is_burning(g) and is_zero_approx(d.burned(g)), "and does so again")
	_done(s)


static func _unguarded(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var minds := [Person.Mind.PANIC, Person.Mind.CONFUSED, Person.Mind.WHISPERED]
	for i in 3:
		crowd.fires.ignite(d.targets[i], 0.5)
	for k in roundi((HarvestDirector.SMOTHER_AFTER + 1.0) / DT):
		for i in 3:
			d.watchman(d.targets[i]).mind = minds[i]
		crowd.advance(DT)
		(s.rules as Rules).advance(DT)
	var ok := true
	for i in 3:
		ok = ok and crowd.fires.is_burning(d.targets[i]) and d.burned(d.targets[i]) > HarvestDirector.SMOTHER_AFTER and not d.guarding(d.targets[i])
	t.check(ok and d.hint_phase() == "burning", "frightened, confused or whispered, a watchman leaves the fire to burn")
	_done(s)

	s = _world()
	d = s.d
	crowd = s.crowd
	var a := d.targets[0]
	var b := d.targets[1]
	var c := d.targets[2]
	_kill(s, d.watchman(a))
	var held := d.watchman(b)
	_arrive(held, d.watches[b].post + Vector2(8.0, 0.0))
	var inside := d.watchman(c)
	inside.inside = true
	for g in [a, b, c]:
		crowd.fires.ignite(g, 0.5)
	_hold(s, held, Person.Mind.CALM, HarvestDirector.SMOTHER_AFTER + 1.0)
	ok = true
	for g in [a, b, c]:
		ok = ok and crowd.fires.is_burning(g) and not d.guarding(g)
	t.check(ok, "dead, away from his post, or indoors, he does not either")
	inside.inside = false
	_done(s)

	s = _world()
	d = s.d
	var man := d.watchman(d.targets[0])
	crowd = s.crowd
	crowd.fires.ignite(d.targets[0], 0.5)
	_hold(s, man, Person.Mind.COMPELLED, HarvestDirector.SMOTHER_AFTER + 1.0)
	t.check(crowd.fires.is_burning(d.targets[0]) and not d.guarding(d.targets[0]), "nor compelled")
	_done(s)


static func _return(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	var man := d.watchman(g)
	var post: Vector2 = d.watches[g].post
	_arrive(man, post + Vector2(8.0, 0.0))
	_hold(s, man, Person.Mind.CALM, HarvestDirector.RETURN_AFTER - 3.0)
	var early := man.mind == Person.Mind.CALM and not man.has_goal()
	_run(s, 3.0 + HarvestDirector.TICK * 2.0)
	t.check(early and man.mind == Person.Mind.DUTY and man.goal().distance_to(post) < 0.5,
		"a watchman away from his post, calm again, is sent back to it 20 s after he left")
	_arrive(man, post)
	_run(s, HarvestDirector.TICK + DT)
	t.check(d.guarding(g) and d.watchman(g) == man, "and is on guard again")
	_done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	var old := d.watchman(g)
	var post: Vector2 = d.watches[g].post
	_free(s, old)
	_run(s, HarvestDirector.RELIEF_AFTER - 2.0)
	var none := d.watchman(g) == null
	_run(s, 2.0 + HarvestDirector.TICK * 2.0)
	var fresh := d.watchman(g)
	t.check(none and fresh != null and fresh != old and fresh.mind == Person.Mind.DUTY and fresh.goal().distance_to(post) < 0.5
		and (s.banners as Array).has("A NEW WATCHMAN TAKES THE POST"),
		"a watchman felled (his body freed), another is sent to his post 30 s after")
	_arrive(fresh, post)
	_run(s, HarvestDirector.TICK + DT)
	t.check(d.guarding(g), "and keeps it")
	_done(s)


static func _carts(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, float(HarvestDirector.CART_AT[0]) + DT * 2.0)
	var crew: Array = d.carters[g]
	var ok := d.carting.size() == 1 and d.carting[0] == g and crew.size() == HarvestDirector.CARTERS
	for c: Person in crew:
		ok = ok and c.mind == Person.Mind.DUTY and c.goal().distance_to(d.doors[g]) < 0.5 and c != d.watchman(g)
	t.check(ok and (s.banners as Array).has("THE SOUTH-WEST GRANARY'S CARTS SET OUT") and d.carters[d.targets[1]].is_empty(),
		"0:30: the south-west granary's carts set out for it, and only its")
	t.check(_labels(d)[0] == "GRANARY - %d LEFT" % HarvestDirector.LOADS and _labels(d)[1] == "GRANARY - CARTS IN 1:00", "tagged with its loads (%s)" % [_labels(d)])
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


static func _staggered(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	_run(s, float(HarvestDirector.CART_AT[1]) + DT * 2.0)
	t.check(d.carting.size() == 2 and d.carting[1] == d.targets[1] and d.carters[d.targets[2]].is_empty(),
		"1:30: the south-east granary's carts follow the first's")
	_run(s, float(HarvestDirector.CART_AT[2]) - float(HarvestDirector.CART_AT[1]))
	t.check(d.carting.size() == 3 and d.carting[2] == d.targets[2] and (s.banners as Array).has("THE NORTH-EAST GRANARY'S CARTS SET OUT"),
		"2:30: the north-east granary's")
	_done(s)


static func _emptied(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var rules: Rules = s.rules
	var g := d.targets[0]
	_run(s, float(HarvestDirector.CART_AT[0]) + DT * 2.0)
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
	_run(s, float(HarvestDirector.CART_AT[0]) + DT * 2.0)
	var man := d.watchman(g)
	_kill(s, man)
	crowd.fires.ignite(g, 0.5)
	_run(s, 5.0)
	t.check(d.burned(g) > 4.0 and not d.razed(g) and d.hint_phase() == "burning" and _labels(d)[0].begins_with("GRANARY - BURNING"),
		"the watchman gone and the granary alight, it burns toward its spoiling (%.1f s)" % d.burned(g))
	if crowd.fires.is_burning(g):
		crowd.fires._put_out(g, true)
	_run(s, 1.0)
	t.check(d.burned(g) > 4.0 and not d.razed(g), "put out by the fire crews, the time it burned is kept")
	crowd.fires.ignite(g, 0.5)
	_run(s, HarvestDirector.SPOIL_SECONDS)
	var crew: Array = d.carters[g]
	t.check(d.razed(g) and (s.banners as Array).has("A GRANARY IS SPOILED") and crew.is_empty(),
		"10 s in all: spoiled, and its carters go home")
	var h := d.targets[1]
	h.destroy(h.center(), &"fire")
	_run(s, DT * 2.0)
	t.check(d.razed(h) and d.razed_count() == 2, "a granary brought down is spoiled too, its watchman there or not")
	_done(s)


static func _win(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var rules: Rules = s.rules
	for g in d.targets:
		g.destroy(g.center(), &"fire")
	_run(s, DT * 2.0)
	t.check(d.all_razed() and rules.finished and rules.won and rules.over_reason == "spoiled"
		and rules.objectives[0].hud_text(rules) == "Granaries spoiled 3 / 3", "all three spoiled: the harvest is spoiled")
	t.check(int(d.report().spoiled) == 3 and not bool(d.report().emptied), "the results count them")
	_done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, float(HarvestDirector.CART_AT[0]) + DT * 2.0)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	_run(s, HarvestDirector.TICK + DT)
	_free(s, c0)
	_free(s, d.watchman(d.targets[1]))
	_run(s, HarvestDirector.TICK * 3.0)
	d.tags()
	t.check(int(d.loads[g]) == HarvestDirector.LOADS - 1 and d.hint_phase() == "" and d.watchman(d.targets[1]) == null
		and not d.guarding(d.targets[1]),
		"a carter killed with his load and freed, a watchman freed: the load is lost, the night plays on (review focus 2)")
	_done(s)


static func _resume(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, float(HarvestDirector.CART_AT[0]) + DT * 2.0)
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


## The Raze base's optional seal (a bare subclass): a sealed target only shakes and its fire is smothered; unsealed it is an
## ordinary building; fallen anyway it is razed all the same (the soft-lock guard).
static func _walled(t) -> void:
	var s := _world(false, true)
	var d: RazeDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	var hp := g.hp
	g.damage(500.0, g.center(), &"fire")
	crowd.fires.ignite(g, 0.6)
	_run(s, 1.0)
	t.check(d.is_sealed(g) and not g.destroyed and is_equal_approx(g.hp, hp) and not crowd.fires.is_burning(g) and not d.razed(g)
		and is_zero_approx(d.burned(g)), "a sealed target only shakes, and its fire is smothered (review focus 4)")
	d.unseal(g)
	g.damage(10.0, g.center(), &"fire")
	t.check(not d.is_sealed(g) and g.hp < hp, "unsealed, it takes blows")
	d.seal(g)
	g.destroy(g.center(), &"stone")
	_run(s, DT * 2.0)
	t.check(d.razed(g) and d.all_razed(), "a sealed target somehow brought down is razed all the same")
	_done(s)


static func _reserved(t) -> void:
	var s := _world(true)
	var d: HarvestDirector = s.d
	var held: Dictionary = s.held
	_run(s, float(HarvestDirector.CART_AT[0]) + DT * 2.0)
	var crew: Array = d.carters[d.targets[0]]
	var ok := d.targets.size() == 3 and not d.targets.has(held.house) and crew.size() == HarvestDirector.CARTERS
	for c in crew:
		ok = ok and not (held.lay as Array).has(c)
	for g in d.targets:
		ok = ok and d.watchman(g) != null and not (held.lay as Array).has(d.watchman(g))
	t.check(ok, "a reserved house is never a granary, a reserved citizen never a watchman or a carter")
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
	var waits := [float(HarvestDirector.CART_AT[0])]
	for i in range(1, HarvestDirector.CART_AT.size()):
		waits.append(float(HarvestDirector.CART_AT[i]) - float(HarvestDirector.CART_AT[i - 1]))
	waits.append_array([HarvestDirector.RETURN_AFTER, HarvestDirector.RELIEF_AFTER, HarvestDirector.SMOTHER_AFTER])
	t.check(waits.all(func(w: float) -> bool: return w <= 60.0), "no timed wait is over 60 s (%s)" % [waits])
