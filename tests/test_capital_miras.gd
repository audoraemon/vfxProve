extends RefCounted
## Plan "The Capital at every tier", Task 2: Mira's House in the Capital (spec 6.1.1). Her house is a patrician house in the noble quarter;
## the town's overrides (src/game/town/cities/capital_missions/miras_house.gd) are valid and hold after setup; the mission is hostable;
## the report run (her door to the Temple door) is in Aldermere's band; the spot lands; the intro camera keeps the door clear of the padded
## HUD stack; the tour tells the truth about the Capital; the policy reads the director and no Aldermere const.

const ID := "miras_house"
const Cap := preload("res://tests/capital_kit.gd")
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The noble quarter's ground (spec 6.1.1): the patrician houses.
const NOBLE := Rect2(-24.0, -21.0, 15.0, 12.0)


static func run(t) -> void:
	City.use(&"aldermere")
	Cap.overrides_valid(t, ID)
	Cap.hostable(t, ID)
	_seeded(t)
	_policy_reads_vars(t)
	var cap := Cap.town(&"capital")
	var ald := Cap.town(&"aldermere")
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	Cap.spots_land(t, cap, {"mira_spot": ov.director.mira_spot})
	_starts(t, cap, ald)
	Cap.drop(cap)
	Cap.drop(ald)
	Cap.release()
	_camera_clear(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the Capital Mira test leaves Aldermere active")


## A fresh director holds every town var at its const.
static func _seeded(t) -> void:
	var d := MirasHouseDirector.new()
	t.check(d.mira_spot == MirasHouseDirector.MIRA_SPOT, "a fresh director's mira_spot is MIRA_SPOT (Aldermere's)")
	t.check(Overrides.town_vars(d) == ["mira_spot"], "Mira's House's town vars are mira_spot (%s)" % [Overrides.town_vars(d)])
	t.check(is_equal_approx(d.read_seconds, MirasHouseDirector.READ_SECONDS), "read_seconds is untouched (copy-free)")
	t.check(MissionBook.miras_house().camera_at == MirasHouseDirector.MIRA_SPOT, "Aldermere's camera is still MIRA_SPOT")


## The director's house search and door read the var, not the const.
static func _policy_reads_vars(t) -> void:
	var src := FileAccess.get_file_as_string("res://src/game/mission/miras_house_director.gd")
	var body := src.substr(src.find("func _begin()"))
	body = body.substr(0, body.find("func _opening_banner"))
	var find := src.substr(src.find("func _find_house()"))
	find = find.substr(0, find.find("func _door_of"))
	t.check(not "MIRA_SPOT" in body and not "MIRA_SPOT" in find and "mira_spot" in body and "mira_spot" in find,
		"_begin and _find_house read mira_spot, not MIRA_SPOT")
	var bc := FileAccess.get_file_as_string("res://tools/dev/behaviour_check.gd")
	var policy := bc.substr(bc.find("func _faith_night("))
	policy = policy.substr(0, policy.find("\nfunc ", 10))
	t.check(not "MIRA_SPOT" in policy and not "TownLayout." in policy, "the miras policy (_faith_night) reads no Mira const or TownLayout coordinate")


static func _starts(t, cap: Dictionary, ald: Dictionary) -> void:
	var ov: Dictionary = City.by_id(&"capital").mission_overrides(ID)
	var spot: Vector2 = ov.director.mira_spot
	var d := Cap.starts(t, ID) as MirasHouseDirector
	t.check(d != null and d.mira_spot == spot, "the director reads back the Capital's Mira spot after setup (%s)" % [d.mira_spot if d != null else null])
	var def := MissionBook.get_mission("%s@capital" % ID)
	t.check(def.camera_at == spot and def.intro_from == spot + Vector2(0.0, 6.0), "camera_at and intro_from are overridden together (C9)")
	var h := d.house
	t.check(h != null and d._dwelling(h), "Mira's house is a dwelling")
	t.check(h != null and NOBLE.has_point(h.center()), "Mira's house stands in the noble quarter (%s)" % [h.center() if h != null else null])
	t.check(h != null and h.center().distance_to(spot) <= 2.0, "it is the dwelling nearest the spot (%.2f)" % (h.center().distance_to(spot) if h != null else -1.0))
	t.check(d.door != Vector2.INF and d.temple_door != Vector2.INF, "her door and the Temple's door are found")
	t.check(d.grieving.size() == MirasHouseDirector.GRIEVING, "twelve grieving are chosen (%d)" % d.grieving.size())
	# The report run: her door to the Temple door, Capital against Aldermere.
	City.use(&"aldermere")
	var a := Kit.world(MissionBook.miras_house())
	var ad: MirasHouseDirector = a.d
	# The spec's key walk (A about 14.6) is the door-to-door run as the Faithful's report crosses it: measured straight (Aldermere's grid walk is
	# 37 because her house there is fenced into its lane; the Capital's door is on open ground). Both are printed; the band is on the straight run.
	Cap.parity(t, "Mira's door -> Temple door (straight)", d.door.distance_to(d.temple_door), ad.door.distance_to(ad.temple_door))
	print("CAPITAL MIRA grid walks: capital %.1f, aldermere %.1f" % [Cap.walk(cap.grid, d.door, d.temple_door), Cap.walk(ald.grid, ad.door, ad.temple_door)])
	t.check(Cap.walk(cap.grid, d.door, d.temple_door) <= d.door.distance_to(d.temple_door) * 1.35, "the Capital's door has an open way to the Temple's (no hidden detour)")
	print("CAPITAL MIRA door %s temple_door %s; aldermere door %s temple_door %s" % [d.door, d.temple_door, ad.door, ad.temple_door])
	Kit.done(a)
	City.use(&"capital")
	_words_true(t, d)
	var rest := Cap.snap(cap.grid, spot)
	t.check(cap.grid.path(rest, d.temple_door).size() > 1, "a path joins her door and the Temple's")


## No line of the Capital's tour or banner names the west quarter.
static func _words_true(t, d: MirasHouseDirector) -> void:
	var said := PackedStringArray([d._opening_banner(), d._house_label()])
	for stop: Array in d.tour():
		said.append(String(stop[1]))
	var wrong := false
	for line in said:
		wrong = wrong or "west quarter" in line.to_lower()
	t.check(not wrong, "no tour line says 'west quarter' (%s)" % [said])
	t.check(d.tour().size() == 3, "the tour is her door, the Temple, the Inquisitor")


static func _camera_clear(t) -> void:
	City.use(&"capital")
	var def := MissionBook.get_mission("%s@capital" % ID)
	var cap := Cap.town(&"capital")
	var d := Cap.starts(t, ID) as MirasHouseDirector
	Cap.camera_clear(t, def, [d.door, d.temple_door])
	t.check(def.intro_from == def.camera() + Vector2(0.0, 6.0), "the intro starts 6 south of where it rests")
	Cap.release()
	Cap.drop(cap)
	City.use(&"aldermere")
