extends RefCounted
## v0.12 Task 1: the merge of feat/capital-city. Clergy tests count the Capital's monks, the barracks' door is the city's, the
## sandbox is a dev mission of the Capital, and Aldermere's head count is still PEOPLE.

static func run(t) -> void:
	_clergy(t)
	_pressed_door(t)
	_sandbox(t)
	_aldermere_people(t)
	_river_rules(t)
	City.use(&"aldermere")
	t.check(City.current() is AldermereCity, "the merge test leaves Aldermere the active city")


## A monk is clergy; no "is this person clergy" test compares the role to CLERGY by == or != in mission/descend/the rite.
## (A role table such as SKIP_ROLES or NOT_LAY, and an exact role pick -- _citizen_near(at, Role.CLERGY) -- stay.)
static func _clergy(t) -> void:
	t.check(CitizenProfile.is_clergy(CitizenProfile.Role.MONK) and CitizenProfile.is_clergy(CitizenProfile.Role.CLERGY),
		"monks and clergy are clergy")
	t.check(not CitizenProfile.is_clergy(CitizenProfile.Role.MAYOR), "a mayor is not")
	var files: Array[String] = ["res://src/game/crowd/banishing_rite.gd"]
	_scripts_under("res://src/game/mission", files)
	_scripts_under("res://src/game/descend", files)
	var re := RegEx.create_from_string("role\\s*(==|!=)\\s*CitizenProfile\\.Role\\.CLERGY")
	var found := PackedStringArray()
	for p: String in files:
		for line: String in FileAccess.get_file_as_string(p).split("\n"):
			if re.search(line.get_slice("#", 0)) != null:
				found.append(p.get_file())
	t.check(found.is_empty(), "no clergy test by == or != Role.CLERGY (found in %s)" % ", ".join(found))


## The barracks' door is the middle of the city's barracks' front: in Aldermere, the value v0.11.2 gave on TownLayout.BARRACKS.
static func _pressed_door(t) -> void:
	City.use(&"aldermere")
	var crowd := Crowd.new()
	var door := PressedWish.barracks_door(crowd)
	crowd.free()
	var r := TownLayout.BARRACKS
	t.check(door == Vector2(r.get_center().x, r.end.y + 0.5), "Aldermere's barracks door is the old expression (%s)" % door)


## The capital's sandbox is a dev mission whose city is the Capital; no board mission is dev.
static func _sandbox(t) -> void:
	var m := MissionBook.get_mission(MissionBook.CAPITAL_SANDBOX)
	t.check(m.id == MissionBook.CAPITAL_SANDBOX and m.city == &"capital", "the sandbox is the Capital's")
	t.check(MissionBook.is_dev("capital_sandbox"), "the sandbox is dev-only")
	t.check(not MissionBook.is_dev(MissionBook.TAX_COLLECTOR) and not MissionBook.is_dev(MissionBook.WARNING), "board missions are not dev")
	t.check(MissionBook.get_mission(MissionBook.TAX_COLLECTOR).city == &"aldermere", "a board mission is Aldermere's by default")


## Aldermere's head count is the v0.11 constant: 220 citizens and 100 soldiers.
static func _aldermere_people(t) -> void:
	City.use(&"aldermere")
	var c := City.current()
	t.check(c.citizens() + c.soldiers() == Mission.PEOPLE and Mission.PEOPLE == 320, "Aldermere keeps 220 + 100 people")


## The capital's walkers' river rules (no step into the water, wade ashore from a fallen span) are the Capital's: Aldermere's
## v0.11 nights ran without them and their checksums ride on it (D5, R8).
static func _river_rules(t) -> void:
	t.check(not City.by_id(&"aldermere").river_rules(), "Aldermere's walkers have no river rules")
	t.check(City.by_id(&"capital").river_rules(), "the Capital's walkers have them")


static func _scripts_under(dir: String, out: Array[String]) -> void:
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in DirAccess.get_directories_at(dir):
		_scripts_under(dir.path_join(sub), out)
