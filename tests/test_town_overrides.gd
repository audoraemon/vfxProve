extends RefCounted
## v0.12 Task 4: a town's overrides on a mission (Overrides, CityDef.mission_overrides, MissionBook.in_city), composite ids
## (`tax_collector@capital`), hostable, --city, and no Descent off Aldermere. A fixture town (tests/fixtures/fixture_city.gd) carries
## overrides for the Tax Collector; the real Capital has none until M2's tasks add theirs.
##
## Mission.start() cannot run in a suite (no scene tree): the decisions it takes are the statics Mission.city_for() and
## Mission.has_descent(); the round trip is FLOW's (Task 7) and behaviour_check's.

const CAPITAL_TAX := "res://src/game/town/cities/capital_missions/tax_collector.gd"


static func run(t) -> void:
	City.use(&"aldermere")
	City.register(FixtureCity.ID, FixtureCity.new())
	City.register(MisnamedCity.ID, MisnamedCity.new())
	_ids(t)
	_apply(t)
	_unknown_key(t)
	_typed(t)
	_order(t)
	_aldermere_none(t)
	_hostable(t)
	_refused(t)
	_director_keys(t)
	_def_for(t)
	_no_descent(t)
	_city_for(t)
	_cli_city(t)
	_registry(t)
	City.unregister(FixtureCity.ID)
	City.unregister(MisnamedCity.ID)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity and not City.has(FixtureCity.ID), "the overrides test leaves Aldermere active and the fixture gone")


static func _ids(t) -> void:
	t.check(MissionBook.city_id("tax_collector", &"capital") == "tax_collector@capital", "composite id")
	t.check(MissionBook.split_city("tax_collector@capital") == ["tax_collector", &"capital"], "split: base and city")
	t.check(MissionBook.split_city("warning")[1] == &"" and MissionBook.split_city("warning")[0] == "warning", "split: a plain id has no city")
	t.check(MissionBook.is_dev("tax_collector@capital") and not MissionBook.is_dev("tax_collector"), "a town night is a dev night")
	var m := MissionBook.get_mission("tax_collector@capital")
	t.check(m.id == "tax_collector" and m.city == &"capital", "get_mission(composite) is the mission in that town")
	t.check(MissionBook.get_mission("tax_collector").city == &"aldermere", "a plain id stays in its home city")


static func _apply(t) -> void:
	var m := MissionBook.in_city(MissionBook.tax_collector(), FixtureCity.ID)
	t.check(m.city == FixtureCity.ID and m.camera_at == Vector2(1.0, 2.0), "def overrides applied")
	var d := m.make_director() as TaxCollectorDirector
	t.check(is_equal_approx(d.hide_seconds, 31.0), "director overrides on the made director, before setup")
	var plain := MissionBook.tax_collector().make_director() as TaxCollectorDirector
	t.check(not is_equal_approx(plain.hide_seconds, 31.0), "a mission not put in the town keeps its own number")


static func _unknown_key(t) -> void:
	var bad := Overrides.apply(MissionDef.new(), {"no_such": 1, "camera_at": "x"})
	t.check(bad == PackedStringArray(["no_such", "camera_at"]), "an unknown key and a wrong type are reported (got %s)" % [bad])
	var def := MissionDef.new()
	var before := def.camera_at
	Overrides.apply(def, {"camera_at": "x"})
	t.check(def.camera_at == before, "a wrong-typed value is not set")
	t.check(Overrides.apply(MissionDef.new(), {"clock": 100}) == PackedStringArray(["clock"]), "an int for a float is reported (write 100.0)")
	t.check(Overrides.apply(MissionDef.new(), {"clock": 100.0, "camera_at": Vector2(3.0, 4.0)}).is_empty(), "good values are accepted")


static func _typed(t) -> void:
	# A typed-array property takes an untyped literal (a plain set() would leave it unchanged, silently).
	var d := EscortDirector.new()
	var bad := Overrides.apply(d, {"watch_posts": [Vector2(1.0, 2.0), Vector2(3.0, 4.0)]})
	t.check(bad.is_empty() and d.watch_posts.size() == 2 and d.watch_posts[1] == Vector2(3.0, 4.0), "a typed array takes an untyped literal (got %s)" % [bad])
	var e := EscortDirector.new()
	var worse := Overrides.apply(e, {"watch_posts": [Vector2i(1, 2)]})
	t.check(worse == PackedStringArray(["watch_posts"]) and e.watch_posts.is_empty(), "elements of the wrong type are reported, the field unchanged (got %s)" % [worse])
	var f := EscortDirector.new()
	f.watch_posts.assign([Vector2(9.0, 9.0)])
	t.check(Overrides.apply(f, {"watch_posts": [1, 2]}).size() == 1 and f.watch_posts == [Vector2(9.0, 9.0)], "a bad literal leaves a set field as it was")


static func _order(t) -> void:
	# The board's tune runs first, then the town's director overrides: the town is the most specific.
	var m := MissionBook.tax_collector()
	m.tune = func(d: MissionDirector) -> void:
		(d as TaxCollectorDirector).hide_seconds = 10.0
	m = MissionBook.in_city(m, FixtureCity.ID)
	t.check(is_equal_approx((m.make_director() as TaxCollectorDirector).hide_seconds, 31.0), "the town's override follows the board's tune")
	var board := MissionBook.tax_collector()
	board.tune = func(d: MissionDirector) -> void:
		(d as TaxCollectorDirector).chain_wait = 12.0
	board = MissionBook.in_city(board, FixtureCity.ID)
	var d2 := board.make_director() as TaxCollectorDirector
	t.check(is_equal_approx(d2.chain_wait, 12.0) and is_equal_approx(d2.hide_seconds, 31.0), "both the board's tune and the town's overrides apply")


static func _aldermere_none(t) -> void:
	var al := City.by_id(&"aldermere")
	var ok := true
	for id in TierBook.all():
		ok = ok and al.mission_overrides(id).is_empty()
	t.check(ok, "Aldermere never overrides a mission")
	t.check(City.by_id(&"capital").mission_overrides("not_a_mission").is_empty(), "no file, no overrides")
	t.check(al.missions_dir() == "res://src/game/town/cities/aldermere_missions" and City.by_id(&"capital").missions_dir().ends_with("capital_missions"),
		"missions_dir() is the city's folder")


static func _hostable(t) -> void:
	var al := City.by_id(&"aldermere")
	var capital := City.by_id(&"capital")
	var fixture := City.by_id(FixtureCity.ID)
	t.check(MissionBook.hostable("tax_collector", al), "Aldermere hosts the Tax Collector")
	# The Capital offers a mission once its overrides file exists (M2 adds them one by one).
	t.check(MissionBook.hostable("tax_collector", capital) == ResourceLoader.exists(CAPITAL_TAX), "the Capital hosts the Tax Collector only with its overrides")
	t.check(MissionBook.hostable("tax_collector", fixture), "the fixture town (overrides and the Capital's places) hosts it")
	t.check(not MissionBook.hostable("spoiled_harvest", fixture), "no overrides, no hosting")
	t.check(MissionBook.hostable("capital_sandbox", capital), "the Capital hosts its own sandbox")
	t.check(MissionBook.town_missions(&"aldermere").is_empty(), "Aldermere lists no town missions")
	t.check(MissionBook.town_missions(FixtureCity.ID) == PackedStringArray(["tax_collector@fixture"]), "the fixture town lists its one (got %s)" % [MissionBook.town_missions(FixtureCity.ID)])


static func _def_for(t) -> void:
	var w := Mission.def_for("warning@capital", true, null)
	t.check(w.director == StarfallDirector and w.city == &"capital", "the board's Warning in the Capital is Starfall, in the Capital")
	t.check(w.id == "warning" and w.tier_floor >= 0, "the board's version, id kept")
	var plain := Mission.def_for("warning", true, null)
	t.check(plain.city == &"aldermere", "a plain id is played at home")
	var camp := Mission.def_for("tax_collector@" + String(FixtureCity.ID), false, null)
	t.check(camp.camera_at == Vector2(1.0, 2.0), "def_for(composite) applies the town's overrides")


static func _no_descent(t) -> void:
	var board := Mission.def_for("tax_collector", true, null)
	t.check(Mission.has_descent(board, true), "a board night in Aldermere has a Descent")
	t.check(not Mission.has_descent(board, false), "an off-board night has none")
	var away := Mission.def_for("tax_collector@capital", true, null)
	t.check(not Mission.has_descent(away, true), "a board night in another town has no Descent")
	t.check(not Mission.has_descent(MissionBook.capital_sandbox(), true), "the sandbox has none")


static func _city_for(t) -> void:
	var tax := MissionBook.tax_collector()
	t.check(Mission.city_for(tax, &"", PackedStringArray(), true) == &"aldermere", "no city asked for: the def's own")
	t.check(Mission.city_for(tax, &"capital", PackedStringArray(), true) == &"capital", "a scripted run's city var wins")
	t.check(Mission.city_for(tax, &"", PackedStringArray(["--city=capital"]), true) == &"capital", "--city= on a self-started mission")
	t.check(Mission.city_for(tax, &"", PackedStringArray(["--city=capital"]), false) == &"aldermere", "--city= ignored when Game starts it")
	t.check(Mission.city_for(MissionBook.capital_sandbox(), &"", PackedStringArray(), true) == &"capital", "the sandbox is already in the Capital")
	# Start() asks this of its own inputs only, so a Restart after a Capital night cannot keep a stale city.
	City.use(&"capital")
	t.check(Mission.city_for(tax, &"", PackedStringArray(), true) == &"aldermere", "with the Capital active, an Aldermere mission is still Aldermere's")
	City.use(&"aldermere")


static func _cli_city(t) -> void:
	t.check(Mission.wanted_city(PackedStringArray(["--city=capital"]), true) == &"capital", "wanted_city: --city= when autostart")
	t.check(Mission.wanted_city(PackedStringArray(["--city=capital"]), false) == &"", "wanted_city: nothing when Game starts the mission")
	t.check(Mission.wanted_city(PackedStringArray(), true) == &"", "wanted_city: nothing without the flag")


static func _registry(t) -> void:
	t.check(City.has(&"capital") and City.has(FixtureCity.ID) and not City.has(&"atlantis"), "City.has() knows IDS and registered towns")
	t.check(City.ids() == [&"aldermere", &"capital", FixtureCity.ID, MisnamedCity.ID], "City.ids() lists IDS then the registered towns")
	t.check(City.IDS == [&"aldermere", &"capital"], "City.IDS itself is unchanged")
	t.check(City.by_id(FixtureCity.ID).id() == FixtureCity.ID, "by_id() builds a registered town")


## C6: a night in a town that cannot host the mission is refused (Mission.start), not run on Aldermere's coordinates. A misnamed
## overrides file is the same as none.
static func _refused(t) -> void:
	var misnamed := City.by_id(MisnamedCity.ID)
	t.check(not MissionBook.hostable("tax_collector", misnamed), "a misnamed overrides file hosts nothing")
	var tax := MissionBook.tax_collector()
	t.check(Mission.hosting_error(tax, MisnamedCity.ID) != "", "the Tax Collector is refused in the town with the misnamed file")
	t.check(Mission.hosting_error(tax, &"aldermere") == "", "a mission at home is never refused")
	t.check(Mission.hosting_error(tax, FixtureCity.ID) == "", "a town with the mission's overrides hosts it")
	t.check(Mission.hosting_error(MissionBook.get_mission("tax_collector@" + String(FixtureCity.ID)), FixtureCity.ID) == "",
		"the composite id's def is judged by its base id: hosted")
	t.check(Mission.hosting_error(MissionBook.get_mission("tax_collector@" + String(MisnamedCity.ID)), MisnamedCity.ID) != "",
		"the composite id's def is judged by its base id: refused")
	t.check(Mission.hosting_error(MissionBook.spoiled_harvest(), FixtureCity.ID) != "", "no overrides, no night")
	t.check(Mission.hosting_error(tax, &"atlantis") != "", "an unknown town is refused")
	t.check(Mission.hosting_error(MissionBook.capital_sandbox(), &"capital") == "", "the sandbox is the Capital's own")


## C7: a town's director overrides take only the names the director lists in TOWN_VARS.
class LabelCity extends CapitalCity:
	func id() -> StringName: return &"labelled"
	func mission_overrides(_id: String) -> Dictionary:
		return {"director": {"hide_seconds": 31.0, "hideout_label": "SOMEWHERE"}}


static func _director_keys(t) -> void:
	var d := TaxCollectorDirector.new()
	var allowed := Overrides.town_vars(d)
	t.check("hide_seconds" in allowed and "set_out_at" in allowed and not "hideout_label" in allowed, "the Tax Collector lists its town vars (%s)" % [allowed])
	var bad := Overrides.apply(d, {"hide_seconds": 40.0, "hideout_label": "X"}, allowed)
	t.check(bad == PackedStringArray(["hideout_label"]) and is_equal_approx(d.hide_seconds, 40.0) and d.hideout_label != "X",
		"a key outside TOWN_VARS is refused, the rest applied (got %s)" % [bad])
	t.check(Overrides.apply(MissionDef.new(), {"clock": 100.0}).is_empty(), "no list given: any property (the def section)")
	t.check(Overrides.town_vars(MissionDirector.new()).is_empty(), "a director with no TOWN_VARS takes no override")
	var m := MissionBook.in_city(MissionBook.tax_collector(), &"labelled", LabelCity.new())
	var made := m.make_director() as TaxCollectorDirector
	t.check(is_equal_approx(made.hide_seconds, 31.0) and made.hideout_label != "SOMEWHERE",
		"through in_city(): the listed key is set, the label refused")
