extends RefCounted
## v0.11 M2 Spoiled Harvest (spec §2, HarvestDirector on RazeDirector, as the controller's Task 3 fix-round rulings reshape it:
## work, not waiting; the grain arrives one granary at a time): three granaries -- dwellings far from the Citadel -- each empty
## until its grain arrives (the first at 1:00, each next at 2:00 and 3:00 or 45 s after the one before is spoiled, whichever is
## sooner); fire on an empty granary does nothing. Each has two watchmen at its door from the start: while one is alive, out of
## doors, calm and at his post he holds his post while his granary burns and beats the fire out after 3 s, and what it had
## burned is forgotten; frightened, held, dead or away he does not (he returns 20 s after a fright, a relief comes 30 s after one
## fell). Both must go. The grain's carter sets out the moment it is in, to take its six loads one at a time; the last load
## taken empties the granary and loses the night. A granary burned 10 s in all (the controller's Task 3 ruling: a 50-hp house
## falls in about 13 s, so 15 s would never be reached), or brought down, is spoiled; all three spoiled wins. Freed carters and
## watchmen are borne (review focus 2); reserved people and houses are never taken (review focus 1). The Raze base keeps an
## optional seal, tested here on a bare subclass.

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
	_empty(t)
	_grain(t)
	_chain(t)
	_both(t)
	_smother(t)
	_unguarded(t)
	_return(t)
	_relief(t)
	_carts(t)
	_staggered(t)
	_emptied(t)
	_spoiled(t)
	_home(t)
	_win(t)
	_freed(t)
	_resume(t)
	_walled(t)
	_unsealed(t)
	_reserved(t)
	_mission(t)
	_carter_early(t)
	_out(t)
	_left_the_map(t)
	_plague(t)
	_plague_guarded(t)
	_blight(t)
	_blight_guarded(t)
	_blight_empty(t)
	_blight_cast(t)
	_seized(t)
	_seized_by_law(t)
	_replaced(t)
	_road_closed(t)
	_roads_stay_in(t)


static func _world(reserve := false, walled := false, loadout := PackedStringArray()) -> Dictionary:
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
	var rules := Rules.new().setup(def.default_loadout if loadout.is_empty() else loadout, null, env, field, crowd, town, def)
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
## citizens nearest each granary's spot (two) and the three nearest the Citadel's gate. Returns them.
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
		for p in lay.slice(0, 3 if spot == HarvestDirector.CITADEL_GATE else HarvestDirector.WATCHMEN):
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


## Every watchman of granary `g` killed.
static func _kill_all(s: Dictionary, g: Structure) -> void:
	for p in (s.d as HarvestDirector).watchmen(g):
		_kill(s, p)


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
		var pair := d.watchmen(g)
		ok = ok and RuinWish.fits(g, "house") and d.targets.find(g) == i and not d.is_sealed(g) and int(d.loads[g]) == HarvestDirector.LOADS
		ok = ok and g.center().distance_to(HarvestDirector.CITADEL_GATE) > 15.0 and not d.has_grain(g)
		ok = ok and pair.size() == HarvestDirector.WATCHMEN and d.guards(g).size() == HarvestDirector.WATCHMEN and d.guarding(g)
		ok = ok and pair[0].ground_pos.distance_to(pair[1].ground_pos) > 2.0 * SilentDoom.RADIUS
		for man in pair:
			ok = ok and not men.has(man) and man.profile.faith == CitizenProfile.Faith.NONE and not man.profile.role in Wish.NOT_LAY \
				and g.distance_to(man.ground_pos) <= HarvestDirector.GUARD_REACH
			men.append(man)
	t.check(ok and men.size() == 6, "three granaries: different dwellings far from the Citadel, none sealed, empty, two lay watchmen on guard at each, out of one Doom's reach of each other")
	var at := []
	for e in d.timeline.upcoming(3):
		at.append(float(e.at))
	t.check(at == HarvestDirector.GRAIN_AT and d.carting.is_empty(), "their grain arrives by 1:00, 2:00 and 3:00 (%s)" % [at])
	t.check(_labels(d) == ["GRANARY - EMPTY, GRAIN IN 1:00", "GRANARY - EMPTY, GRAIN IN 2:00", "GRANARY - EMPTY, GRAIN IN 3:00",
		"WATCHMAN", "WATCHMAN", "WATCHMAN", "WATCHMAN", "WATCHMAN", "WATCHMAN"] and d.hint_phase() == "empty",
		"tagged empty with the time to their grain, and a watchman at each post (%s)" % [_labels(d)])
	var stops := d.tour()
	t.check(stops.size() == 4 and String(stops[0][1]) == "The south-west granary. Its watchmen put out fires. Its grain arrives by 1:00."
		and String(stops[3][1]) == "The Citadel. Carts carry the grain here. An emptied granary cannot be spoiled.",
		"the tour: the three granaries, then the Citadel")
	t.check((s.banners as Array).has("SPOIL THE HARVEST"), "its opening banner")
	_done(s)


static func _empty(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	_kill_all(s, g)
	crowd.fires.ignite(g, 0.6)
	_run(s, 4.0)
	t.check(not crowd.fires.is_burning(g) and is_zero_approx(d.burned(g)) and not d.razed(g) and not g.destroyed and d.hint_phase() == "empty",
		"fire on an empty granary is put out at once and counts for nothing")
	g.destroy(g.center(), &"stone")
	_run(s, 1.0)
	t.check(not d.razed(g), "nor does its fall, while it is empty")
	d._deliver(g)
	_run(s, DT * 2.0)
	t.check(d.razed(g), "the grain arrives in a ruin: spoiled")
	_done(s)


static func _grain(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, float(HarvestDirector.GRAIN_AT[0]) + DT * 2.0)
	var crew: Array = d.carters[g]
	var ok := d.has_grain(g) and d.carting.size() == 1 and d.carting[0] == g and crew.size() == HarvestDirector.CARTERS \
		and not d.has_grain(d.targets[1])
	for c: Person in crew:
		ok = ok and c.mind == Person.Mind.DUTY and c.goal().distance_to(d.doors[g]) < 0.5 and not d.watchmen(g).has(c)
	t.check(ok and (s.banners as Array).has("GRAIN ARRIVES AT THE SOUTH-WEST GRANARY") and d.hint_phase() == "",
		"1:00: the south-west granary's grain arrives, and its carter sets out for it; the others stay empty")
	t.check(_labels(d)[0] == "GRANARY - %d LEFT" % HarvestDirector.LOADS and _labels(d)[1] == "GRANARY - EMPTY, GRAIN IN 1:00",
		"tagged with its loads, the next with the time to its grain (%s)" % [_labels(d)])
	_done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	_kill_all(s, g)
	(s.crowd as Crowd).fires.ignite(g, 0.6)
	var ran := HarvestDirector.SPOIL_SECONDS + 3.0
	_run(s, ran)
	var early: float = d.spoiled_at[0]
	var due := d.grain_due(1)
	t.check(d.razed(g) and early > 0.0 and early < 20.0 and is_equal_approx(due, early + HarvestDirector.CHAIN_AFTER)
		and due < float(HarvestDirector.GRAIN_AT[1]) and is_equal_approx(d.grain_due(2), float(HarvestDirector.GRAIN_AT[2])),
		"granary 1 spoiled early: granary 2's grain is due CHAIN_AFTER later, sooner than its own time; granary 3's is not brought forward")
	_run(s, due - ran - 2.0)
	var before := d.has_grain(d.targets[1])
	_run(s, 3.0)
	t.check(not before and d.has_grain(d.targets[1]) and (s.banners as Array).has("GRAIN ARRIVES AT THE SOUTH-EAST GRANARY")
		and d.carting.size() == 2 and not d.has_grain(d.targets[2]), "and it arrives within the chain delay, with its carter")
	d.spoiled_at[0] = 85.0
	t.check(is_equal_approx(d.grain_due(1), float(HarvestDirector.GRAIN_AT[1])),
		"a granary spoiled late never delays the next one's own time")
	_done(s)


static func _both(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	d._deliver(g)
	var pair := d.watchmen(g)
	_kill(s, pair[0])
	crowd.fires.ignite(g, 0.5)
	_run(s, HarvestDirector.SMOTHER_AFTER + 1.0)
	t.check(not crowd.fires.is_burning(g) and is_zero_approx(d.burned(g)) and d.guards(g).size() == 1,
		"with one watchman left on guard, the fire is beaten out all the same")
	_kill(s, pair[1])
	crowd.fires.ignite(g, 0.5)
	_run(s, HarvestDirector.SMOTHER_AFTER + 1.0)
	t.check(crowd.fires.is_burning(g) and d.burned(g) > HarvestDirector.SMOTHER_AFTER and d.hint_phase() == "burning" and not d.guarding(g),
		"both gone, it burns")
	_done(s)


static func _smother(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	d._deliver(g)
	crowd.fires.ignite(g, 0.6)
	_run(s, HarvestDirector.SMOTHER_AFTER - 1.0)
	t.check(crowd.fires.is_burning(g) and d.burned(g) > 1.0 and d.hint_phase() == "watchman"
		and _labels(d)[0].begins_with("GRANARY - BURNING"), "calm watchmen at their posts let it burn at first (%.1f s)" % d.burned(g))
	_run(s, 1.5)
	t.check(not crowd.fires.is_burning(g) and is_zero_approx(d.burned(g)) and not d.razed(g) and not g.destroyed,
		"then beat it out, and what it had burned is forgotten")
	crowd.fires.ignite(g, 0.6)
	_run(s, HarvestDirector.SMOTHER_AFTER + 0.5)
	t.check(not crowd.fires.is_burning(g) and is_zero_approx(d.burned(g)), "and do so again")
	_done(s)


static func _unguarded(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var minds := [Person.Mind.PANIC, Person.Mind.CONFUSED, Person.Mind.WHISPERED]
	for i in 3:
		d._deliver(d.targets[i])
		crowd.fires.ignite(d.targets[i], 0.5)
	for k in roundi((HarvestDirector.SMOTHER_AFTER + 1.0) / DT):
		for i in 3:
			for p in d.watchmen(d.targets[i]):
				p.mind = minds[i]
		crowd.advance(DT)
		(s.rules as Rules).advance(DT)
	var ok := true
	for i in 3:
		ok = ok and crowd.fires.is_burning(d.targets[i]) and d.burned(d.targets[i]) > HarvestDirector.SMOTHER_AFTER and not d.guarding(d.targets[i])
	t.check(ok and d.hint_phase() == "burning", "frightened, confused or whispered, watchmen leave the fire to burn")
	_done(s)

	s = _world()
	d = s.d
	crowd = s.crowd
	var a := d.targets[0]
	var b := d.targets[1]
	var c := d.targets[2]
	for g in [a, b, c]:
		d._deliver(g)
	_kill_all(s, a)
	var held := d.watchmen(b)
	for p in held:
		_arrive(p, d.watches[b][0].post + Vector2(8.0, 0.0))
	var indoors := d.watchmen(c)
	for p in indoors:
		p.inside = true
	for g in [a, b, c]:
		crowd.fires.ignite(g, 0.5)
	for k in roundi((HarvestDirector.SMOTHER_AFTER + 1.0) / DT):
		for p in held:
			p.mind = Person.Mind.CALM
		crowd.advance(DT)
		(s.rules as Rules).advance(DT)
	ok = true
	for g in [a, b, c]:
		ok = ok and crowd.fires.is_burning(g) and not d.guarding(g)
	t.check(ok, "dead, away from their posts, or indoors, they do not either")
	for p in indoors:
		p.inside = false
	_done(s)

	s = _world()
	d = s.d
	crowd = s.crowd
	d._deliver(d.targets[0])
	crowd.fires.ignite(d.targets[0], 0.5)
	for k in roundi((HarvestDirector.SMOTHER_AFTER + 1.0) / DT):
		for p in d.watchmen(d.targets[0]):
			p.mind = Person.Mind.COMPELLED
		crowd.advance(DT)
		(s.rules as Rules).advance(DT)
	t.check(crowd.fires.is_burning(d.targets[0]) and not d.guarding(d.targets[0]), "nor compelled")
	_done(s)


static func _return(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	var man := d.watchmen(g)[0]
	var other := d.watchmen(g)[1]
	var post: Vector2 = d.watches[g][0].post
	_arrive(man, post + Vector2(8.0, 0.0))
	_hold(s, man, Person.Mind.CALM, HarvestDirector.RETURN_AFTER - 3.0)
	var early := man.mind == Person.Mind.CALM and not man.has_goal()
	_run(s, 3.0 + HarvestDirector.TICK * 2.0)
	t.check(early and man.mind == Person.Mind.DUTY and man.goal().distance_to(post) < 0.5 and other.mind != Person.Mind.DUTY,
		"a watchman away from his post, calm again, is sent back to it 20 s after he left (his fellow is not)")
	_arrive(man, post)
	_run(s, HarvestDirector.TICK + DT)
	t.check(d.guards(g).size() == 2 and d.guards(g).has(man), "and is on guard again")
	_done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	var pair := d.watchmen(g)
	var old := pair[0]
	var post: Vector2 = d.watches[g][0].post
	_free(s, old)
	_run(s, HarvestDirector.RELIEF_AFTER - 2.0)
	var none := d.watchmen(g).size() == 1
	_run(s, 2.0 + HarvestDirector.TICK * 2.0)
	var now := d.watchmen(g)
	var fresh: Person = null
	for p in now:
		if p != pair[1]:
			fresh = p
	t.check(none and now.size() == 2 and fresh != null and fresh != old and fresh.mind == Person.Mind.DUTY
		and fresh.goal().distance_to(post) < 0.5 and (s.banners as Array).has("A NEW WATCHMAN TAKES THE POST"),
		"a watchman felled (his body freed), another is sent to his post 30 s after")
	_arrive(fresh, post)
	_run(s, HarvestDirector.TICK + DT)
	t.check(d.guards(g).size() == 2, "and keeps it")
	_done(s)


static func _carts(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	var crew: Array = d.carters[g]
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
	_run(s, float(HarvestDirector.GRAIN_AT[1]) + DT * 2.0)
	t.check(d.carting.size() == 2 and d.carting[1] == d.targets[1] and d.carters[d.targets[2]].is_empty(),
		"2:00: the south-east granary's grain follows the first's, its carter with it")
	_run(s, float(HarvestDirector.GRAIN_AT[2]) - float(HarvestDirector.GRAIN_AT[1]))
	t.check(d.carting.size() == 3 and d.carting[2] == d.targets[2] and (s.banners as Array).has("GRAIN ARRIVES AT THE NORTH-EAST GRANARY"),
		"3:00: the north-east granary's")
	_done(s)


static func _emptied(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var rules: Rules = s.rules
	var g := d.targets[0]
	d._deliver(g)
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
	d._deliver(g)
	_kill_all(s, g)
	crowd.fires.ignite(g, 0.5)
	_run(s, 5.0)
	t.check(d.burned(g) > 4.0 and not d.razed(g) and d.hint_phase() == "burning" and _labels(d)[0].begins_with("GRANARY - BURNING"),
		"the watchmen gone and the granary alight, it burns toward its spoiling (%.1f s)" % d.burned(g))
	if crowd.fires.is_burning(g):
		crowd.fires._put_out(g, true)
	_run(s, 1.0)
	t.check(d.burned(g) > 4.0 and not d.razed(g), "put out by the fire crews, the time it burned is kept")
	crowd.fires.ignite(g, 0.5)
	_run(s, HarvestDirector.SPOIL_SECONDS)
	var crew: Array = d.carters[g]
	t.check(d.razed(g) and (s.banners as Array).has("A GRANARY IS SPOILED") and crew.is_empty() and d.spoiled_at[0] > 0.0,
		"10 s in all: spoiled, its carters go home, the chain starts")
	var h := d.targets[1]
	d._deliver(h)
	h.destroy(h.center(), &"fire")
	_run(s, DT * 2.0)
	t.check(d.razed(h) and d.razed_count() == 2, "a granary with its grain in, brought down, is spoiled too, its watchmen there or not")
	t.check(d.spoiled_by.get(g) == "fire" and d.spoiled_by.get(h) == "fall", "recorded: the one burned by fire, the one brought down by its fall")
	_done(s)


## A spoiled granary's watchmen go home (final review): one on duty at his post, and one calm at it -- the first watchmen are set
## down with a stay of 1000 s, so he would stand there all night, as one does who stood through the granary's fall before its grain
## came (fearless, or beyond its fright) -- even holding his post against the fire. One frightened is left to the town, and another
## granary's watchmen are not touched.
static func _home(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	var h := d.targets[1]
	var k := d.targets[2]
	var men := d.watchmen(g)
	var calm: Person = men[0]
	var duty: Person = men[1]
	var kept := d.watchmen(h)
	var scared := d.watchmen(k)
	var stood := calm.mind == Person.Mind.CALM and calm.stay_left > 100.0
	# The two granaries come down before their grain does: nothing is judged yet.
	g.destroy(g.center(), &"fire")
	k.destroy(k.center(), &"fire")
	_run(s, DT * 3.0)
	var waiting := not d.razed(g) and not d.razed(k)
	# The watchmen as the grain's coming finds them: (the collapse's fright has passed them by or run its course).
	calm.mind = Person.Mind.CALM
	calm.fearless_left = HarvestDirector.HOLD_POST
	duty.go_duty(duty.anchor)
	scared[0].mind = Person.Mind.PANIC
	scared[1].mind = Person.Mind.CALM
	d._deliver(g)
	d._deliver(k)
	_run(s, DT * 3.0)
	t.check(stood and waiting and d.razed(g) and d.razed(k), "the watchmen stand calm with a stay of 1000 s; the grain comes to the ruins: spoiled")
	t.check(calm.mind == Person.Mind.REGROUP and calm.anchor.is_equal_approx(calm.profile.home) and is_zero_approx(calm.fearless_left),
		"the one calm at his post goes home, the hold against the fire ended with it")
	t.check(duty.mind == Person.Mind.REGROUP and duty.anchor.is_equal_approx(duty.profile.home), "so does the one on duty")
	t.check(scared[0].mind == Person.Mind.PANIC and scared[1].mind == Person.Mind.REGROUP,
		"one frightened is left to the town; his fellow at the other spoiled granary goes home")
	t.check(kept[0].mind == Person.Mind.CALM and kept[1].mind == Person.Mind.CALM and d.guarding(h),
		"the watchmen of a granary still to spoil keep their posts")
	_done(s)


static func _win(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var rules: Rules = s.rules
	for g in d.targets:
		g.destroy(g.center(), &"fire")
	_run(s, DT * 2.0)
	var held := d.razed_count() == 0 and not rules.finished
	for g in d.targets:
		d._deliver(g)
	_run(s, DT * 2.0)
	t.check(held and d.all_razed() and rules.finished and rules.won and rules.over_reason == "spoiled"
		and rules.objectives[0].hud_text(rules) == "Granaries spoiled 3 / 3", "all three spoiled: the harvest is spoiled")
	t.check(int(d.report().spoiled) == 3 and not bool(d.report().emptied), "the results count them")
	_done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	_run(s, HarvestDirector.TICK + DT)
	_free(s, c0)
	for p in d.watchmen(d.targets[1]):
		_free(s, p)
	_run(s, HarvestDirector.TICK * 3.0)
	d.tags()
	t.check(int(d.loads[g]) == HarvestDirector.LOADS - 1 and d.hint_phase() == "" and d.watchmen(d.targets[1]).is_empty()
		and not d.guarding(d.targets[1]),
		"a carter killed with his load and freed, two watchmen freed: the load is lost, the night plays on (review focus 2)")
	_done(s)


static func _resume(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
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


## The night over (final review): a sealed target's damage filter, bound to the director, is cleared by teardown(), so the building
## takes blows again; a sealed target freed by then is skipped.
static func _unsealed(t) -> void:
	var s := _world(false, true)
	var d: RazeDirector = s.d
	var g := d.targets[0]
	var sealed := d.is_sealed(g) and g.damage_filter.is_valid()
	d.teardown()
	var hp := g.hp
	g.damage(10.0, g.center(), &"fire")
	t.check(sealed and not d.is_sealed(g) and not g.damage_filter.is_valid() and g.hp < hp,
		"a sealed target is unsealed when the night is torn down: no filter bound to the old director, and blows land")
	d.seal(g)
	d.teardown()
	d.teardown()
	t.check(not g.damage_filter.is_valid(), "torn down twice (the rules do so too): still clear")
	_done(s)


static func _reserved(t) -> void:
	var s := _world(true)
	var d: HarvestDirector = s.d
	var held: Dictionary = s.held
	d._deliver(d.targets[0])
	var crew: Array = d.carters[d.targets[0]]
	var ok := d.targets.size() == 3 and not d.targets.has(held.house) and crew.size() == HarvestDirector.CARTERS
	for c in crew:
		ok = ok and not (held.lay as Array).has(c)
	for g in d.targets:
		ok = ok and d.watchmen(g).size() == HarvestDirector.WATCHMEN
		for p in d.watchmen(g):
			ok = ok and not (held.lay as Array).has(p)
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
	var waits := [float(HarvestDirector.GRAIN_AT[0])]
	for i in range(1, HarvestDirector.GRAIN_AT.size()):
		waits.append(float(HarvestDirector.GRAIN_AT[i]) - float(HarvestDirector.GRAIN_AT[i - 1]))
	waits.append_array([HarvestDirector.CHAIN_AFTER, HarvestDirector.RETURN_AFTER, HarvestDirector.RELIEF_AFTER, HarvestDirector.SMOTHER_AFTER])
	t.check(waits.all(func(w: float) -> bool: return w <= 60.0) and HarvestDirector.CHAIN_AFTER <= 45.0 and HarvestDirector.CHAIN_AFTER >= 30.0,
		"no timed wait is over 60 s, and the chain is 30-45 s (%s)" % [waits])


# --- God T1R (Tier 1 routes, Task 4, spec 6) ---

## Where a carter stands to be out of Aldermere's walls (past the ring's east wall by more than Walls.MARGIN).
const OUTSIDE := Vector2(18.5, 0.0)


## The director's tags whose label begins with `prefix`.
static func _tags_like(d: MissionDirector, prefix: String) -> Array[MapTag]:
	var out: Array[MapTag] = []
	for m in d.tags():
		if m.label.begins_with(prefix):
			out.append(m)
	return out


## H0: the first carter sets out CARTER_LEAD before the grain, from the Citadel's gate, and waits at the door; he takes no load before the grain.
static func _carter_early(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	var due := d.grain_due(0)
	t.check(is_equal_approx(d.carter_out_at(0), due - HarvestDirector.CARTER_LEAD) and is_equal_approx(HarvestDirector.CARTER_LEAD, 30.0)
		and is_equal_approx(d.carter_out_at(1), d.grain_due(1) - HarvestDirector.CARTER_LEAD), "a carter sets out grain_due - 30 s")
	_run(s, d.carter_out_at(0) - 1.0)
	t.check(d.carters[g].is_empty() and _tags_like(d, "CARTER").is_empty(), "before that second there is no carter")
	_run(s, 1.0 + HarvestDirector.TICK * 2.0)
	var crew: Array = d.carters[g]
	var c0: Person = crew[0] if not crew.is_empty() else null
	t.check(crew.size() == HarvestDirector.CARTERS and c0 != null and c0.mind == Person.Mind.DUTY and c0.goal().distance_to(d.doors[g]) < 0.5
		and not d.has_grain(g), "at that second the first carter sets out for the door, with no grain yet")
	t.check(d.carters[d.targets[1]].is_empty(), "the second granary's carter is not out")
	var tags := _tags_like(d, "CARTER - GRAIN IN ")
	t.check(tags.size() == 1 and tags[0].edge and tags[0].label.begins_with("CARTER - GRAIN IN 0:"),
		"he is tagged CARTER - GRAIN IN 0:xx, edge-arrowed (%s)" % [_labels(d)])
	_arrive(c0, d.doors[g])
	_run(s, HarvestDirector.TICK * 4.0)
	t.check(int(d.loads[g]) == HarvestDirector.LOADS and c0.mind == Person.Mind.DUTY, "at the door he waits: no load before the grain")
	_run(s, float(HarvestDirector.GRAIN_AT[0]) - d._clock + HarvestDirector.TICK * 2.0)
	var carter_tags := _tags_like(d, "CARTER - ")
	t.check(d.has_grain(g) and int(d.loads[g]) == HarvestDirector.LOADS - 1 and carter_tags.size() >= 1
		and carter_tags[0].label == "CARTER - %d LEFT" % (HarvestDirector.LOADS - 1) and carter_tags[0].edge,
		"the grain comes and he takes his first load at once, tagged CARTER - n LEFT, edge-arrowed (%s)" % [_labels(d)])
	_done(s)


## H1: a carter set down outside the walls, before his grain: the granary is spoiled at once, the chain starts, he is sent off the map.
static func _out(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, d.carter_out_at(0) + HarvestDirector.TICK * 2.0)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	_run(s, HarvestDirector.TICK * 2.0)
	t.check(not d.razed(g), "a carter at his door is in the walls")
	var before := d._clock
	_arrive(c0, OUTSIDE)
	_run(s, HarvestDirector.TICK * 2.0)
	t.check(Walls.outside(OUTSIDE) and d.razed(g) and d.spoiled_by.get(g) == "out" and d.spoiled_at[0] >= before and d.spoiled_at[0] < before + 1.5
		and d.is_leaving(c0) and (s.banners as Array).has("THE CARTER LEAVES TOWN - THE GRAIN ROTS"),
		"out of the walls, before his grain: the granary is spoiled (out), the chain starts from now, and he is leaving")
	t.check(is_equal_approx(d.grain_due(1), minf(float(HarvestDirector.GRAIN_AT[1]), d.spoiled_at[0] + HarvestDirector.CHAIN_AFTER)),
		"the next grain is due the chain's 45 s after")
	_done(s)
	# After his grain, with a load, too.
	s = _world()
	d = s.d
	g = d.targets[0]
	d._deliver(g)
	c0 = d.carters[g][0]
	_arrive(c0, OUTSIDE)
	_run(s, HarvestDirector.TICK * 2.0)
	t.check(d.razed(g) and d.spoiled_by.get(g) == "out", "and after it")
	_done(s)


## D15: a carter taken off the map by any way is gone for the night: his granary is spoiled.
static func _left_the_map(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	var c0: Person = d.carters[g][0]
	d.left_the_map.emit(c0)
	t.check(d.razed(g) and d.spoiled_by.get(g) == "out" and not d.razed(d.targets[1]), "a carter who left the map: his granary is spoiled, no other")
	_done(s)


## H2: no watchman on guard, the carter sick: the granary is spoiled by the plague.
static func _plague(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, d.carter_out_at(0) + HarvestDirector.TICK * 2.0)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	_kill_all(s, g)
	_run(s, HarvestDirector.TICK * 2.0)
	t.check(not d.razed(g) and not d.guarding(g), "the watchmen are gone, the carter is well: nothing is spoiled")
	c0.infect(PlagueManager.PLAGUE_LIFE)
	_run(s, HarvestDirector.TICK * 3.0)
	t.check(d.razed(g) and d.spoiled_by.get(g) == "plague" and (s.banners as Array).has("THE PLAGUE SPOILS THE GRAIN"),
		"sick, with no watchman on guard: the plague spoils the grain")
	_done(s)


## H2 with a watch: the watch turns the sick cart away (banner once); the watchmen cleared while he is still sick: spoiled.
static func _plague_guarded(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_run(s, d.carter_out_at(0) + HarvestDirector.TICK * 2.0)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	c0.infect(PlagueManager.PLAGUE_LIFE)
	_run(s, 1.5)
	var turned := (s.banners as Array).count("THE WATCH TURNS THE SICK CART AWAY")
	t.check(d.guarding(g) and not d.razed(g) and turned == 1 and not (s.banners as Array).has("THE PLAGUE SPOILS THE GRAIN"),
		"a watchman on guard: the watch turns the sick cart away, nothing spoiled (%d banner)" % turned)
	_run(s, 1.0)
	t.check((s.banners as Array).count("THE WATCH TURNS THE SICK CART AWAY") == 1, "the banner shows once for a carter")
	_kill_all(s, g)
	_run(s, HarvestDirector.TICK * 3.0)
	t.check(d.razed(g) and d.spoiled_by.get(g) == "plague",
		"the watchmen then cleared while he is still sick: spoiled (preflight 15)")
	_done(s)


## H3: grain in, no watchman on guard: Blight's mark is the granary, it takes, and it rots.
static func _blight(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	d._deliver(g)
	_kill_all(s, g)
	var aim: Vector2 = g.center() + Vector2(0.5, 0.0)
	t.check(d.blight_target(aim) == g.center() and d.blight_takes(aim) and d.blight_target(g.center() + Vector2(8.0, 8.0)) == Vector2.INF,
		"Blight's mark is a granary near the aim; a far aim has none")
	var alarm := crowd.alarm
	var took := d.blighted(aim)
	t.check(took and d.razed(g) and d.spoiled_by.get(g) == "blight" and d.blight_words(aim) == "BLIGHT - THE GRAIN ROTS" and crowd.alarm > alarm,
		"Blight rots it: spoiled (blight), the words, the town's alarm")
	t.check(d.blight_target(aim) == Vector2.INF, "and a spoiled granary is no mark")
	_done(s)


## H3 with a watch: Blight does not take, says so, rings no alarm.
static func _blight_guarded(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var crowd: Crowd = s.crowd
	var g := d.targets[0]
	d._deliver(g)
	var aim: Vector2 = g.center()
	var alarm := crowd.alarm
	t.check(d.guarding(g) and d.blight_target(aim) != Vector2.INF and not d.blight_takes(aim), "a watchman on guard: it is a mark, but not taken")
	t.check(not d.blighted(aim) and d.blight_words(aim) == "THEIR WATCH KEEPS IT" and not d.razed(g) and is_equal_approx(crowd.alarm, alarm),
		"THEIR WATCH KEEPS IT: not spoiled, no alarm")
	_done(s)


## H3 before the grain: nothing to rot.
static func _blight_empty(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	_kill_all(s, g)
	var aim: Vector2 = g.center()
	t.check(not d.blight_takes(aim) and not d.blighted(aim) and d.blight_words(aim) == "NO GRAIN TO ROT YET" and not d.razed(g),
		"before its grain: NO GRAIN TO ROT YET, not spoiled")
	_done(s)


## Blight, cast through BlightFx: the director is asked first and its words are the banner.
static func _blight_cast(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	_kill_all(s, g)
	var ctx := _fx_context(s)
	var fx: BlightFx = FxTimeline.cast(load("res://src/fx/quiet/blight.gd"), ctx, g.center())
	fx._process(BlightFx.T_ROT + 0.05)
	t.check(d.razed(g) and d.spoiled_by.get(g) == "blight" and (s.banners as Array).has("BLIGHT - THE GRAIN ROTS") and not g.blighted,
		"cast through the power: the granary is spoiled, the words are the banner, no structure is ruined")
	fx.free()
	ctx.overhead.free()
	ctx.ground.free()
	_done(s)


## An effect context over the world `s` (as tests/test_decree.gd builds one).
static func _fx_context(s: Dictionary) -> FxContext:
	var ctx := FxContext.new()
	ctx.env = s.env
	ctx.field = s.field
	ctx.crowd = s.crowd
	ctx.rules = s.rules
	ctx.rng = RandomNumberGenerator.new()
	ctx.rng.seed = 3
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	return ctx


## H4: The Bell Lies, CALL THE GUARD, cast at the carter: the first called soldier arrives, the cart is seized -- up to SEIZE_R (3.0, Leaving Is
## Prohibited's radius) from the place; 3.2 from it, not.
static func _seized(t) -> void:
	for gap in [0.0, 2.9, 3.2]:
		var s := _world(false, false, PackedStringArray(["belllies", "noleave"]))
		var d: HarvestDirector = s.d
		var crowd: Crowd = s.crowd
		var rules: Rules = s.rules
		var g := d.targets[0]
		var ctx := _fx_context(s)
		rules.caster = func(script: GDScript, at: Vector2, extra: Dictionary) -> FxTimeline:
			return FxTimeline.cast(script, ctx, at, extra)
		_run(s, d.carter_out_at(0) + HarvestDirector.TICK * 2.0)
		var c0: Person = d.carters[g][0]
		_arrive(c0, d.doors[g])
		var place: Vector2 = crowd._grid.nearest_walkable(d.doors[g] + Vector2(gap, 0.0))
		var near: Vector2 = crowd._grid.nearest_walkable(place + Vector2(5.0, 0.0))
		for sol in crowd.soldiers:
			sol.ground_pos = near
		var fx := rules.cast(0, place, {"mode": "guard"}) as BellLiesFx
		fx._process(BellLiesFx.T_CAST + 0.05)
		t.check(fx != null and fx.mode == "guard" and fx.called > 0 and rules.last_fx() == fx and not d.razed(g),
			"(gap %.1f) the guard are called, none has come" % gap)
		_run(s, HarvestDirector.TICK * 4.0)
		t.check(not d.razed(g) and d._guard_at != Vector2.INF, "(gap %.1f) none has come yet: nothing is seized" % gap)
		var first: Person = null
		for sol in crowd.soldiers:
			if sol.mind == Person.Mind.COMPELLED and sol.compel_glyph == DecreeParts.BELL:
				first = sol
				break
		_arrive(first, first.anchor)  # (people are not walked in this world: the first called soldier stands at his ring spot)
		_run(s, HarvestDirector.TICK * 3.0)
		if gap < 3.0:
			t.check(d.razed(g) and d.spoiled_by.get(g) == "seized" and (s.banners as Array).has("THE GUARD SEIZE THE CART")
				and not d.razed(d.targets[1]) and d._guard_at == Vector2.INF, "(gap %.1f) the first called soldier arrives: the cart is seized, his granary spoiled" % gap)
			t.check(not (s.banners as Array).has(HarvestDirector.NO_CART_BANNER), "(gap %.1f) and no word of an empty call" % gap)
		else:
			t.check(not d.razed(g) and c0.ground_pos.distance_to(place) > HarvestDirector.SEIZE_R and d._guard_at == Vector2.INF,
				"the carter 3.2 from the place is not seized (%.2f)" % c0.ground_pos.distance_to(place))
			# (final review M7) The call is spent with no cart in reach: never a silent one.
			t.check((s.banners as Array).count(HarvestDirector.NO_CART_BANNER) == 1 and not (s.banners as Array).has("THE GUARD SEIZE THE CART"),
				"the guard come and find no cart: the spent call is announced, once (%s)" % [s.banners])
		fx.free()
		ctx.overhead.free()
		ctx.ground.free()
		_done(s)


## H4 with the law and the bell clicked apart (D23): the carter held on the law's circle is in reach when the law's centre is within SEIZE_R of the bell,
## whatever his distance from the bell; with the law's centre 3.5 from the bell he is not seized.
static func _seized_by_law(t) -> void:
	for offset in [1.5, 3.5]:
		var s := _world(false, false, PackedStringArray(["belllies", "noleave"]))
		var d: HarvestDirector = s.d
		var crowd: Crowd = s.crowd
		var rules: Rules = s.rules
		var g := d.targets[0]
		var ctx := _fx_context(s)
		rules.caster = func(script: GDScript, at: Vector2, extra: Dictionary) -> FxTimeline:
			return FxTimeline.cast(script, ctx, at, extra)
		_run(s, d.carter_out_at(0) + HarvestDirector.TICK * 2.0)
		var c0: Person = d.carters[g][0]
		var bell: Vector2 = d.doors[g]
		var law := bell + Vector2(offset, 0.0)
		# He stands on the law's far edge from the bell (offset 1.5), or well inside it but 5.5 from the bell (offset 3.5).
		_arrive(c0, law + Vector2(3.0 if offset < 3.0 else 2.0, 0.0))
		var held := rules.cast(1, law) as NoLeaveFx
		held._process(NoLeaveFx.T_SEAL + 0.05)
		t.check(held != null and held.sealed and held.bound.has(c0), "(law %.1f from the bell) the carter is bound by the law" % offset)
		var near: Vector2 = crowd._grid.nearest_walkable(bell + Vector2(-5.0, 0.0))
		for sol in crowd.soldiers:
			sol.ground_pos = near
		var call := rules.cast(0, bell, {"mode": "guard"}) as BellLiesFx
		t.check(call != null and rules.last_fx() == call, "(law %.1f) the guard are called" % offset)
		call._process(BellLiesFx.T_CAST + 0.05)
		var first: Person = null
		for sol in crowd.soldiers:
			if sol.mind == Person.Mind.COMPELLED and sol.compel_glyph == DecreeParts.BELL:
				first = sol
				break
		_arrive(first, first.anchor)
		_run(s, HarvestDirector.TICK * 3.0)
		t.check(c0.ground_pos.distance_to(bell) > HarvestDirector.SEIZE_R + HarvestDirector.SEIZE_SLACK, "(law %.1f) he stands out of the bell's own reach" % offset)
		if offset < 3.0:
			t.check(d.razed(g) and d.spoiled_by.get(g) == "seized", "the soldier arrives: the held carter is seized by the law's centre")
		else:
			t.check(not d.razed(g), "a law whose centre is 3.5 from the bell: he is not seized")
		call.free()
		held.free()
		ctx.overhead.free()
		ctx.ground.free()
		_done(s)


## H5: a carter killed is replaced RELIEF_AFTER later from the Citadel's gate, the loads as they were; killing one never spoils.
static func _replaced(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.doors[g])
	_run(s, HarvestDirector.TICK * 2.0)
	var loads := int(d.loads[g])
	_free(s, c0)
	_run(s, HarvestDirector.RELIEF_AFTER - 2.0)
	t.check(not d._carter_alive(g) and not d.razed(g) and int(d.loads[g]) == loads, "killing a carter does not spoil his granary")
	_run(s, 2.0 + HarvestDirector.TICK * 3.0)
	var crew: Array = d.carters[g]
	var fresh: Person = crew[0] if not crew.is_empty() else null
	t.check(fresh != null and fresh != c0 and WarningDirector._alive(fresh) and fresh.mind == Person.Mind.DUTY
		and fresh.goal().distance_to(d.doors[g]) < 0.5 and (s.banners as Array).has("A NEW CARTER SETS OUT")
		and int(d.loads[g]) == loads and not d.razed(g), "RELIEF_AFTER later a new carter sets out for the door; the loads are as they were")
	_done(s)


## A carter whose road was closed (a Thornwall: his walk found no way and was dropped) and stands with no walk is sent on again once it opens.
static func _road_closed(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var g := d.targets[0]
	d._deliver(g)
	var c0: Person = d.carters[g][0]
	_arrive(c0, d.citadel_door + Vector2(2.0, 0.0))
	c0.mind = Person.Mind.DUTY
	c0.anchor = d.doors[g]
	t.check(c0.goal() == Vector2.INF, "the carter stands with no walk, away from his door")
	_run(s, HarvestDirector.TICK + DT)
	t.check(c0.goal().distance_to(d.doors[g]) < 0.5, "and the next look sends him on to the door")
	# Still blocked (his walk is dropped again after each look): he is sent again at every look and nothing else changes.
	var loads := int(d.loads[g])
	var banners := (s.banners as Array).size()
	var sent := 0
	for k in 4:
		c0._goal = Vector2.INF
		c0._path = PackedVector2Array()
		_run(s, HarvestDirector.TICK + DT)
		if c0.goal().distance_to(d.doors[g]) < 0.5:
			sent += 1
	t.check(sent == 4 and c0.mind == Person.Mind.DUTY and int(d.loads[g]) == loads and not d.razed(g) and d.emptied == null
		and (s.banners as Array).size() == banners and d.carters[g][0] == c0 and not d.is_leaving(c0),
		"a carter who stays blocked is sent again at every look, with no other effect (%d of 4)" % sent)
	_done(s)


## The carters' roads stay inside the walls in Aldermere (an 'out' carter is never one who merely walked his road).
static func _roads_stay_in(t) -> void:
	var s := _world()
	var d: HarvestDirector = s.d
	var grid: WalkGrid = (s.crowd as Crowd)._grid
	var in_walls := true
	for g in d.targets:
		for pair in [[d.citadel_door, d.doors[g]], [d.doors[g], d.citadel_door]]:
			var path := grid.path(pair[0], pair[1])
			in_walls = in_walls and not path.is_empty()
			for pt in path:
				in_walls = in_walls and not Walls.outside(pt)
	t.check(in_walls, "every carter's road, Citadel gate to door and back, stays inside the walls")
	_done(s)
