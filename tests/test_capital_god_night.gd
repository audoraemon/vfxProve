extends RefCounted
## World Map + Conquer Progress, Task 6: nights in the Capital. The draw and the def are town-aware (only what the Capital hosts is
## drawn; Aldermere's draw is today's, bit for bit), a night there has a Descent (wishes) and banks into the Capital's believers, and
## Game's World Map handler assigns the town only once a night was drawn.

const BASE := "user://test_capital_god_night_"
const SAVE := "user://test_capital_god_night_save.cfg"
const SETTINGS := "user://test_capital_god_night_settings.cfg"


static func run(t) -> void:
	GodTree.dev_fill = true
	_draw_hostable(t)
	_draw_none(t)
	_hunt_aldermere_only(t)
	_def_in_capital(t)
	_has_descent(t)
	_capital_bank(t)
	_hunt_pays_conquer_bonus(t)
	_capital_wishes(t)
	await _world_action(t)
	City.use(&"aldermere")
	GodTree.dev_fill = false


static func _slot(tier := 1, seed_value := 3) -> GodSlot:
	var s := GodSlot.make(1, "ruin", seed_value)
	s.tier = tier
	return s


## The draw as it was before the Capital had nights: the oracle for Aldermere.
static func _old_draw(slot: GodSlot) -> String:
	var hunt := GodNight.hunt_for(slot)
	if not hunt.is_empty():
		return String(hunt.id)
	var pool := PackedStringArray()
	for id in TierBook.missions(slot.tier):
		if id != slot.last_mission and id != slot.before_hunt:
			pool.append(id)
	if pool.is_empty():
		pool = TierBook.missions(slot.tier)
	var rng := RandomNumberGenerator.new()
	rng.seed = GodNight.night_seed(slot)
	return pool[rng.randi_range(0, pool.size() - 1)]


static func _hosted(tier: int) -> PackedStringArray:
	var out := PackedStringArray()
	for id in TierBook.missions(tier):
		if MissionBook.hostable(id, City.by_id(&"capital")):
			out.append(id)
	return out


static func _draw_hostable(t) -> void:
	var bad := 0
	var same := true
	var drew := 0
	for tier in range(1, 6):
		for night in range(0, 21):
			var s := _slot(tier, 5 + night)
			s.night = night
			s.last_mission = TierBook.missions(tier)[night % TierBook.missions(tier).size()]
			var id := GodNight.draw(s, "capital")
			if id != "":
				drew += 1
				if not MissionBook.hostable(id, City.by_id(&"capital")):
					bad += 1
			same = same and GodNight.draw(s, "aldermere") == _old_draw(s) and GodNight.draw(s) == _old_draw(s)
	t.check(bad == 0, "the Capital draws only what it hosts (%d unhostable draws)" % bad)
	t.check(drew > 0, "the Capital draws some night (%d)" % drew)
	t.check(same, "Aldermere's draw is today's for tiers 1-5 and nights 0..20")
	t.check(GodNight.can_host("aldermere", "bishop") and GodNight.can_host("aldermere", "warning"), "Aldermere hosts every tier mission")
	t.check(GodNight.can_host("capital", "warning") == MissionBook.hostable("warning", City.by_id(&"capital")), "can_host asks the book for another town")


static func _draw_none(t) -> void:
	var tier := 0
	for k in range(1, 6):
		if _hosted(k).is_empty():
			tier = k
			break
	t.check(tier > 0, "some tier is hosted by no mission in the Capital (tier %d)" % tier)
	if tier > 0:
		var s := _slot(tier)
		t.check(GodNight.draw(s, "capital") == "", "a tier the Capital hosts nothing of draws no night")
		t.check(GodNight.draw(s, "aldermere") == _old_draw(s), "and Aldermere still draws its own")


static func _hunt_aldermere_only(t) -> void:
	var s := _slot()
	s.notice = 100
	t.check(GodNight.is_hunt(GodNight.draw(s, "aldermere")), "a full Notice: Aldermere draws the Hunt")
	t.check(GodNight.draw(s, "capital") == "", "a full Notice: the Capital draws no night (the Hunt is not hosted there)")
	t.check(GodNight.draw(s) == GodNight.draw(s, "aldermere"), "the default town is Aldermere")


static func _def_in_capital(t) -> void:
	var s := _slot(1, 9)
	var id := String(_hosted(1)[0])
	var cap := GodNight.def_for(s, id, "capital")
	var ald := GodNight.def_for(s, id, "aldermere")
	var plain := GodNight.def_for(s, id)
	t.check(cap != null and cap.city == &"capital", "def_for in the Capital is the Capital's (%s)" % [cap.city if cap != null else "null"])
	t.check(ald.city == &"aldermere" and plain.city == &"aldermere", "def_for in Aldermere is today's")
	t.check(cap.slots == s.slots() and cap.dp_capacity == s.max_might() and cap.pool == ald.pool and cap.clock == ald.clock,
		"slots, Might, pool and clock are the god's in either town (%d, %d)" % [cap.slots, cap.dp_capacity])
	var rite := GodNight.def_for(s, RiteBook.FIRST_TASTE, "capital")
	t.check(rite != null and rite.city == GodNight.def_for(s, RiteBook.FIRST_TASTE).city, "a rite ignores the town")


static func _has_descent(t) -> void:
	var cap := MissionBook.in_city(TierBook.board(String(_hosted(1)[0]), null), &"capital")
	var ald := TierBook.board("tax_collector", null)
	t.check(not Mission.has_descent(cap, true), "the Capital's board night in the DEV tab has no Descent")
	t.check(Mission.has_descent(cap, true, true), "a god's night in the Capital has one")
	t.check(not Mission.has_descent(cap, false, true), "off the board it has none")
	t.check(Mission.has_descent(ald, true) and Mission.has_descent(ald, true, true) and not Mission.has_descent(ald, false), "Aldermere's is unchanged")
	t.check(not Mission.has_descent(MissionBook.first_taste(), true, true), "a rite has none in any town")
	t.check(not Mission.has_descent(MissionBook.capital_sandbox(), true, true), "the sandbox has none")
	t.check(City.by_id(&"capital").wishes() and City.by_id(&"aldermere").wishes(), "Aldermere and the Capital hear wishes")


static func _capital_bank(t) -> void:
	var s := _slot()
	s.opened.append("capital")
	s.believers["aldermere"] = 20
	var id := String(_hosted(1)[0])
	var out := {"won": true, "descend": {"tier": 1, "main": true, "kept": 1, "earned": 30, "main_time": 150.0},
		"conquest": {"town": "capital", "carried_alive": 40, "named": 2, "fill": 6, "lost": 0}}
	var res := GodNight.bank(s, id, PackedStringArray(["smite"]), out)
	t.check(int(s.believers.get("capital", 0)) == 48 and int(res.conquest.count) == 48 and res.conquest.town == "capital", "the night banks into the Capital (%s)" % [s.believers])
	t.check(int(s.believers.aldermere) == 20, "Aldermere's count is untouched (%s)" % [s.believers])
	t.check(s.night == 1 and s.last_mission == id and int(res.divine_power) > 0 and s.faith > 0, "the night counts, pays DP and Faith (%d, %s)" % [s.night, s.last_mission])
	t.check(not MissionBook.is_dev(id), "its id is not a dev id")


## The conquered-town Faith bonus is paid on a won Hunt and a lost one, not on a rite or a forfeit.
static func _hunt_pays_conquer_bonus(t) -> void:
	var won := _slot()
	won.believers["aldermere"] = Conquest.population("aldermere")
	won.notice = 100
	var before := won.faith
	var out := {"won": true, "descend": {"tier": 1, "main": true, "kept": 0, "earned": 0, "main_time": 100.0}}
	var res := GodNight.bank(won, String(GodNight.hunt_for(won).id), PackedStringArray(["smite"]), out)
	t.check(int(res.conquer_faith) == Conquest.CONQUER_FAITH, "a won Hunt reports the conquered bonus (%s)" % [res.get("conquer_faith")])
	t.check(won.faith == before + GodNight.HUNT_FAITH * won.tier + Conquest.CONQUER_FAITH, "a won Hunt pays its Faith and the bonus (%d)" % won.faith)
	var lost := _slot()
	lost.believers["aldermere"] = Conquest.population("aldermere")
	lost.notice = 100
	var res2 := GodNight.bank(lost, String(GodNight.hunt_for(lost).id), PackedStringArray(["smite"]),
		{"won": false, "descend": {"tier": 1, "main": false, "kept": 0, "earned": 0}})
	t.check(int(res2.conquer_faith) == Conquest.CONQUER_FAITH and lost.faith == Conquest.CONQUER_FAITH, "a lost Hunt pays the bonus too (%d)" % lost.faith)
	var none := _slot()
	none.notice = 100
	GodNight.bank(none, String(GodNight.hunt_for(none).id), PackedStringArray(["smite"]), out)
	t.check(none.faith == GodNight.HUNT_FAITH * none.tier, "no conquered town: a Hunt pays no bonus (%d)" % none.faith)
	var rite := _slot()
	rite.believers["aldermere"] = Conquest.population("aldermere")
	var rres := GodNight.bank(rite, RiteBook.FIRST_TASTE, PackedStringArray(["smite"]), {"won": true})
	t.check(rite.faith == 0 and int(rres.faith) == 0, "a rite pays no bonus (%d)" % rite.faith)
	var forfeit := _slot()
	forfeit.believers["aldermere"] = Conquest.population("aldermere")
	forfeit.in_night = "warning"
	GodNight.forfeit(forfeit)
	t.check(forfeit.faith == 0, "a forfeit pays no bonus (%d)" % forfeit.faith)


## A Capital world's wishes: their people are living citizens of the crowd, their places structures of that town.
static func _capital_wishes(t) -> void:
	City.use(&"capital")
	var heard := 0
	var bad := 0
	for tier in range(1, 6):
		var id := String(_hosted(1)[0])
		var def := MissionBook.in_city(TierBook.board(id, null, tier), &"capital")
		var s := _world(def)
		var descent := Descent.new().setup(def, 1)
		var crowd := s.crowd as Crowd
		var town := s.town as Town
		for wish_seed in range(1, 6):
			descent.wish_seed = wish_seed
			descent.hear(crowd, town)
			for w in descent.wishes:
				heard += 1
				for p in w.people():
					if not (is_instance_valid(p) and MissionDirector._alive(p) and (crowd.citizens.has(p) or crowd.soldiers.has(p))):
						bad += 1
				for st in w.places():
					if not is_instance_valid(st) or not town._built.has(st):
						bad += 1
			descent.release()
		_done(s)
	City.use(&"aldermere")
	t.check(heard > 0, "the Capital's nights hear wishes (%d)" % heard)
	t.check(bad == 0, "every heard wish's people live in the crowd and its places stand in the town (%d bad)" % bad)


static func _world(def: MissionDef) -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = City.current().map()
	var node := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, node, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	return {"env": env, "town": town, "field": field, "world": node, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## Game._on_world_action: the town and the night are assigned only once a night was drawn.
static func _world_action(t) -> void:
	City.use(&"aldermere")
	var game: Game = load("res://scenes/game.tscn").instantiate()
	game.save_path = SAVE
	game.settings_path = SETTINGS
	game.god_base = BASE
	game.god_slot = 1
	t.root.add_child(game)
	await t.process_frame
	var god := _slot(1, 11)
	god.opened.append("capital")
	game.god = god
	var map := WorldMap.new()
	t.root.add_child(map)
	map.setup(god)
	# A refused Descend (a tier the Capital hosts none of) leaves everything alone.
	var none_tier := 0
	for k in range(2, 6):
		if _hosted(k).is_empty():
			none_tier = k
			break
	if none_tier > 0:
		god.tier = none_tier
		game.mission_id = "keep"
		game.night_town = "aldermere"
		god.last_town = "aldermere"
		map.selected = "capital"
		game._on_world_action("descend", map)
		t.check(god.last_town == "aldermere" and game.night_town == "aldermere" and game.mission_id == "keep",
			"a refused Descend leaves last_town, night_town and mission_id alone (%s, %s, %s)" % [god.last_town, game.night_town, game.mission_id])
		god.tier = 1
	# The Capital.
	map.selected = "capital"
	game._on_world_action("descend", map)
	t.check(god.last_town == "capital" and game.night_town == "capital" and game.mission_id == GodNight.draw(god, "capital") and game.mission_id != "",
		"Descend in the Capital sets the town and its night (%s, %s, %s)" % [god.last_town, game.night_town, game.mission_id])
	t.check(game.screen == Game.Screen.PREPARE, "and opens Prepare")
	# Aldermere.
	map.selected = "aldermere"
	game._on_world_action("descend", map)
	t.check(god.last_town == "aldermere" and game.night_town == "aldermere" and game.mission_id == GodNight.draw(god, "aldermere"),
		"Descend in Aldermere sets its town and night (%s, %s, %s)" % [god.last_town, game.night_town, game.mission_id])
	# A refusal with a due Hunt in the Capital.
	god.notice = 100
	map.selected = "capital"
	var keep_id := game.mission_id
	game._on_world_action("descend", map)
	t.check(god.last_town == "aldermere" and game.night_town == "aldermere" and game.mission_id == keep_id,
		"a Hunt due: the Capital is refused and nothing moves (%s, %s, %s)" % [god.last_town, game.night_town, game.mission_id])
	map.free()
	game.free()
	for f in [SAVE, SETTINGS, BASE + "1.cfg"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
