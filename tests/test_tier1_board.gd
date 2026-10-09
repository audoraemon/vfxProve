extends RefCounted
## v0.11 M2 Tier 1 complete on the board: The Warning and the four new missions, each built at Tier 1's numbers (5:00, 3 / 6,
## Unaware, unaware_town, no bonuses, no stretch); no timed wait over 60 s; a board night's wishes reserved before each
## director gathers its people -- no wish's person or building becomes the mission's (review focus 1); The Tax Collector's night
## never hears the tax collector wish; and five cards a tab, whose best lines wrap to fit.

const DT := 0.05
## The four new Tier 1 missions.
const NEW := ["tax_collector", "spoiled_harvest", "lost_lamb", "first_prayers"]


static func run(t) -> void:
	_board(t)
	_waits(t)
	_reserved(t)
	_tags(t)
	_best(t)


## A board world for `id`: before the director's setup, `reserve`'s people ("c<i>" a citizen, "s<i>" a soldier, by index) and
## places (indices into Town._built) are reserved, and with `night` a real Descent hears its wishes and reserves them too.
static func _world(id: String, reserve := {}, night := false) -> Dictionary:
	var def := TierBook.board(id)
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
	var made := def.make_director()
	for key: String in reserve.get("people", []):
		var list: Array[Person] = crowd.citizens if key.begins_with("c") else crowd.soldiers
		made.reserved.append(list[int(key.substr(1))])
	for i: int in reserve.get("places", []):
		made.reserved_places.append(town._built[i])
	var descent: Descent = null
	if night:
		descent = Descent.new().setup(def, Descent.seed_for(0, id))
		descent.reserve(rules, made)
	var director := made.setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director,
		"descent": descent}


static func _done(s: Dictionary) -> void:
	if s.descent != null:
		(s.descent as Descent).release()
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


## The director's own people and buildings: {"people": Array of Person, "places": Array of Structure}.
## - The Tax Collector's three collectors and their guards, and the debtors' houses (the counting-house is the workshop hall,
##   chosen by its art tag, which no wish takes).
## - Spoiled Harvest's watchmen from the start and its carters (gathered as a granary's grain arrives, so the world is run past
##   the first), and the granaries.
## - The Lost Lamb's acolyte, the gate's watch, the patrols and, from HUNT_AT, the searchers.
## - First Prayers' poor and Faithful.
static func _actors(s: Dictionary) -> Dictionary:
	var d: MissionDirector = s.d
	var people: Array = []
	var places: Array = []
	if d is AssassinateDirector:
		var a := d as AssassinateDirector
		for q in a.quarries:
			people.append(q.target)
			people.append_array(q.guards)
			places.append_array(q.stops)
	elif d is HarvestDirector:
		var h := d as HarvestDirector
		_run(s, float(HarvestDirector.GRAIN_AT[0]) + DT * 2.0)
		places.append_array(h.targets)
		for posts: Array in h.watches.values():
			for w: HarvestDirector.Watch in posts:
				if w.man != null:
					people.append(w.man)
		for crew: Array in h.carters.values():
			people.append_array(crew)
	elif d is EscortDirector:
		var e := d as EscortDirector
		_run(s, e.hunt_at + DT * 2.0 if e.hunt_at > 0.0 else DT)
		people.append(e.charge)
		people.append_array(e.watch)
		for squad: Array in e.patrols:
			people.append_array(squad)
		people.append_array(e.hunters)
	elif d is MirasHouseDirector:
		var m := d as MirasHouseDirector
		people.append_array(m.grieving)
		people.append_array(m.faithful)
	return {"people": people.filter(func(p: Variant) -> bool: return p != null and is_instance_valid(p)),
		"places": places.filter(func(x: Variant) -> bool: return x != null and is_instance_valid(x))}


## The same actors as indices, to reserve them in a second world of the same town; `lost` counts any found in neither roster.
static func _keys(s: Dictionary, actors: Dictionary) -> Dictionary:
	var crowd: Crowd = s.crowd
	var town: Town = s.town
	var people := []
	var lost := 0
	for p: Variant in actors.people:
		var i := crowd.citizens.find(p)
		var j := crowd.soldiers.find(p)
		if i >= 0:
			people.append("c%d" % i)
		elif j >= 0:
			people.append("s%d" % j)
		else:
			lost += 1
	var places := []
	for x: Variant in actors.places:
		var k := town._built.find(x)
		if k >= 0:
			places.append(k)
		else:
			lost += 1
	return {"people": people, "places": places, "lost": lost}


static func _board(t) -> void:
	for id: String in NEW:
		var m := TierBook.board(id)
		t.check(m != null and m.id == id and m.tier == 1 and is_equal_approx(m.clock, 300.0) and m.slots == 3 and m.dp_capacity == 6
			and m.tier_floor == 1 and m.mission_tags.has(TierBook.UNAWARE_TAG) and m.bonuses().is_empty()
			and m.response_profile(ResponseProfile.DEFAULT).title == "Unaware" and is_equal_approx(m.stretch, 1.0),
			"%s on the board: Tier 1, 5:00, 3 / 6, Unaware, unaware_town, no bonuses, no stretch" % id)
	t.check(TierBook.board("tax_collector").mission_tags.has("hunts_tax_collector"),
		"The Tax Collector keeps the tax collector wish away")
	t.check(Array(TierBook.missions(1)) == ["warning"] + NEW and TierBook.need(1) == 3 and DescendState.lock_text(2) == "Clear 3 Whisper missions",
		"Whisper: The Warning and the four new; three of them open Omen")
	t.check(TierBook.type_of("tax_collector") == "Kill" and TierBook.type_of("spoiled_harvest") == "Destroy"
		and TierBook.type_of("lost_lamb") == "Protect" and TierBook.type_of("first_prayers") == "Cult", "each card's type")


static func _waits(t) -> void:
	var waits := {
		"the first collector sets out": TaxCollectorDirector.SET_OUT_AT[0],
		"the second collector, at the latest": TaxCollectorDirector.SET_OUT_AT[1] - TaxCollectorDirector.SET_OUT_AT[0],
		"the third collector, at the latest": TaxCollectorDirector.SET_OUT_AT[2] - TaxCollectorDirector.SET_OUT_AT[1],
		"the next collector after a death": TaxCollectorDirector.CHAIN_WAIT,
		"a debtor's visit": TaxCollectorDirector.VISIT_SECONDS,
		"his hiding": TaxCollectorDirector.HIDE_SECONDS,
		"the first grain": HarvestDirector.GRAIN_AT[0],
		"the second grain, at the latest": HarvestDirector.GRAIN_AT[1] - HarvestDirector.GRAIN_AT[0],
		"the third grain, at the latest": HarvestDirector.GRAIN_AT[2] - HarvestDirector.GRAIN_AT[1],
		"the next grain after a spoiling": HarvestDirector.CHAIN_AFTER,
		"a watchman's return": HarvestDirector.RETURN_AFTER,
		"a watchman's relief": HarvestDirector.RELIEF_AFTER,
		"the first watch change": EscortDirector.WATCH_CHANGE,
		"the next watch change": EscortDirector.WATCH_CYCLE - EscortDirector.WATCH_GAP,
		"a prayer": FirstPrayersDirector.PRAY_SECONDS,
		"the market at the door": FirstPrayersDirector.MARKET_SECONDS,
		"the priests at the door": FirstPrayersDirector.PRIESTS_SECONDS,
	}
	var long := []
	for k: String in waits:
		if float(waits[k]) > 60.0:
			long.append(k)
	t.check(long.is_empty(), "no timed wait in Tier 1's new missions runs over 60 s (over: %s)" % [long])


static func _reserved(t) -> void:
	for id: String in NEW:
		var a := _world(id)
		var first := _keys(a, _actors(a))
		_done(a)
		var b := _world(id, first)
		var second := _keys(b, _actors(b))
		var people_clash := []
		for k: String in second.people:
			if first.people.has(k):
				people_clash.append(k)
		var place_clash := []
		for i: int in second.places:
			if first.places.has(i):
				place_clash.append(i)
		t.check(not (first.people as Array).is_empty() and int(first.lost) == 0 and int(second.lost) == 0 and people_clash.is_empty()
			and place_clash.is_empty(),
			"%s: the people and buildings it would take, once reserved, are never taken (review focus 1) (%s / %s)" % [id,
			people_clash, place_clash])
		_done(b)
		var n := _world(id, {}, true)
		var actors := _actors(n)
		var clash := false
		for w in (n.descent as Descent).wishes:
			for p in w.people():
				clash = clash or (actors.people as Array).has(p)
			for x in w.places():
				clash = clash or (actors.places as Array).has(x)
		t.check(not clash, "%s: a board night's wishes, heard first, share no one and nothing with it" % id)
		_done(n)


## Mission tags end to end (v0.11 M2): the board night's own seeded draw, as Descent.hear() makes it, never offers the tax
## collector wish on The Tax Collector's night, and does on a night that keeps no such tag -- so the test is not vacuous.
static func _tags(t) -> void:
	var tax := _world("tax_collector")
	var other := _world("first_prayers")
	var heard := {}
	var control := {}
	for night in 60:
		for pair: Array in [["tax_collector", tax, heard], ["first_prayers", other, control]]:
			var d := Descent.new().setup(TierBook.board(pair[0]), Descent.seed_for(night, pair[0]))
			d.hear(pair[1].crowd, pair[1].town)
			for w in d.wishes:
				(pair[2] as Dictionary)[w.def.id] = true
			d.release()
	t.check(not heard.has("tax_collector") and not heard.is_empty() and control.has("tax_collector"),
		"sixty seeded draws on The Tax Collector's night never hear the tax collector wish; First Prayers' do (%s / %s)" % [
		heard.keys(), control.keys()])
	_done(tax)
	_done(other)


static func _best(t) -> void:
	var save := SaveFile.new()
	save.descend.cleared.append("tax_collector")
	save.descend.fastest["tax_collector"] = 239.0
	save.descend.most_wishes["tax_collector"] = 2
	var board := MissionBoard.new().setup(save, "tax_collector")
	var room := MissionBoard.card_rect(0, 5).size.x - MissionBoard.PAD * 2.0
	var lines := board.best_lines("tax_collector", room)
	var fits := not lines.is_empty() and lines[0].begins_with("Cleared")
	for line in lines:
		fits = fits and UiTheme.width(line, UiTheme.SIZE_SMALL) <= room
	t.check(fits and board.missions().size() == 5 and board.tier == 1,
		"the Whisper tab's five cards: a card's best line wraps to fit its %d px (%s)" % [int(room), lines])
	var long := {}
	for id in board.missions():
		var brief := board.brief_lines(id, room)
		if brief.size() > MissionBoard.BRIEF_LINES:
			long[id] = brief.size()
	t.check(long.is_empty(), "each of the five cards' briefs wraps to %d lines or fewer, clear of its best line (over: %s)" % [
		MissionBoard.BRIEF_LINES, long])
	board.free()
