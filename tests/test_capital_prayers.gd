extends RefCounted
## v0.12 M2 First Prayers in the Capital (spec 2.5, Task 13): the Capital's overrides file for the mission (the shrine on free ground on
## the Great Market's south promenade, the poor of the west market's back lanes, the camera), valid against the director's town vars; the town hosts the
## mission; the key walks keep to Aldermere's within the band (D26: the poor's walk and the Bearer's asserted, the Faithful's report run
## printed only, D28); every spot lands on ground, the shrine stands on free ground with the poor and the Faithful's door spots inside
## the old town and apart (spread); the intro's camera keeps the shrine, the Temple and the first of the poor clear of the HUD stack;
## the tour names the Capital's quarter and Aldermere's tour is word for word what it was.

const Kit := preload("res://tests/test_tier2_groundwork.gd")
const FILE := "res://src/game/town/cities/capital_missions/first_prayers.gd"
const ID := "first_prayers"
## D26: a key walk in the Capital is 0.75-1.35x of Aldermere's.
const BAND_LOW := 0.75
const BAND_HIGH := 1.35
## The Aldermere tour line this task must leave as it was.
const ALDERMERE_POOR_LINE := "The poor of the south-west quarter. Three must pray at the well."


static func run(t) -> void:
	City.use(&"aldermere")
	_hostable(t)
	if not _overrides_valid(t):
		City.use(&"aldermere")
		return
	var home := _aldermere()
	City.use(&"capital")
	var def := MissionBook.get_mission(ID + "@capital")
	var s := Kit.world(def)
	var away := _walks(s.d)
	_walk_parity(t, home, away)
	_spots_land(t, s)
	_camera_clear(t, s, def)
	_tour_true(t, s, home)
	Kit.done(s)
	City.use(&"aldermere")
	t.check(City.current().id() == &"aldermere", "the Capital prayers test leaves Aldermere the active city")


## The Capital hosts First Prayers, and lists it as a town night.
static func _hostable(t) -> void:
	var capital := City.by_id(&"capital")
	t.check(MissionBook.hostable(ID, capital), "the Capital hosts First Prayers")
	t.check(MissionBook.town_missions(&"capital").has(ID + "@capital"), "the Capital lists first_prayers@capital")
	t.check(MissionBook.get_mission(ID + "@capital").city == &"capital", "first_prayers@capital is played in the Capital")


## The overrides file loads, applies to a fresh def and director with nothing refused, and every value has the type of the var it sets.
static func _overrides_valid(t) -> bool:
	t.check(ResourceLoader.exists(FILE), "the Capital has a First Prayers overrides file")
	if not ResourceLoader.exists(FILE):
		return false
	var ov: Dictionary = load(FILE).overrides()
	var def := MissionBook.first_prayers()
	t.check(Overrides.apply(def, ov.get("def", {})).is_empty(), "the def overrides apply with nothing refused")
	var d := def.make_director() as FirstPrayersDirector
	var names := Overrides.town_vars(d)
	var fresh := FirstPrayersDirector.new()
	var bad := Overrides.apply(d, ov.get("director", {}), names)
	t.check(bad.is_empty(), "the director overrides apply with nothing refused (%s)" % [bad])
	var typed := true
	for key: Variant in ov.get("director", {}):
		typed = typed and typeof(ov.director[key]) == typeof(fresh.get(String(key))) and d.get(String(key)) == ov.director[key]
	t.check(typed, "every director override has its var's type and reads back")
	t.check(def.camera_at == (ov.def as Dictionary).get("camera_at", Vector2.INF) and def.intro_from == def.camera_at + Vector2(0.0, 6.0),
		"the intro rests on the camera spot and starts 6 south of it (camera_at and intro_from together)")
	t.check(d.shrine_at != FirstPrayersDirector.SHRINE_AT and d.poor_spot != FirstPrayersDirector.POOR_SPOT,
		"the shrine and the poor's spot are the Capital's own")
	return true


## Aldermere's walks and tour line, measured in its own town (built, measured, let go).
static func _aldermere() -> Dictionary:
	City.use(&"aldermere")
	var s := Kit.world(MissionBook.first_prayers())
	var out := _walks(s.d)
	out["poor_line"] = _poor_line(s.d)
	Kit.done(s)
	return out


## The path length of one walk on the town's own grid (the people's WalkGrid.path()).
static func _way(d: FirstPrayersDirector, from: Vector2, to: Vector2) -> float:
	var prev := from
	var total := 0.0
	for p in d.crowd._grid.path(from, to):
		total += prev.distance_to(p)
		prev = p
	return total


## The key walks (D26/D28): the poor's (poor spot -> the shrine's door, straight: a Mind Whisper hop covers 9.5 of straight ground, so
## the poor's reach decides the night; its path is printed -- Aldermere's own 19.5 is a 1.8x detour round one house, not a distance the
## poor ever walk), the Faithful's report run (the door -> the Temple's door, printed only), the Bearer's (the Temple's door -> the bell
## tower's foot).
static func _walks(d: FirstPrayersDirector) -> Dictionary:
	var grid: WalkGrid = d.crowd._grid
	var from := grid.nearest_walkable(d.poor_spot)
	var foot: Vector2 = d.crowd.bell.foot if d.crowd.bell != null else Vector2.INF
	return {"poor": from.distance_to(d.door), "poor_path": _way(d, from, d.door), "report": _way(d, d.door, d.temple_door),
		"bearer": _way(d, d.lantern_door(), foot) if foot != Vector2.INF else INF}


static func _walk_parity(t, home: Dictionary, away: Dictionary) -> void:
	for k: String in ["poor", "poor_path", "report", "bearer"]:
		print("TEST prayers walk %s: Aldermere %.1f, Capital %.1f (%.2fx)" % [k, home[k], away[k], away[k] / maxf(float(home[k]), 0.01)])
	for k: String in ["poor", "bearer"]:
		var r: float = away[k] / maxf(float(home[k]), 0.01)
		t.check(r >= BAND_LOW and r <= BAND_HIGH, "the %s's walk is %.2fx of Aldermere's (%.1f vs %.1f): in %.2f-%.2f" % [
			k, r, away[k], home[k], BAND_LOW, BAND_HIGH])


## Every spot lands: the shrine and the poor's spot snap within 0.6; the shrine stands on free ground, with every one of the poor inside the old
## town and a way to its door; the Faithful's door spots (the market's line and the priests') land apart (spread, more than 1.6).
static func _spots_land(t, s: Dictionary) -> void:
	var d: FirstPrayersDirector = s.d
	var grid: WalkGrid = d.crowd._grid
	for spot: Vector2 in [d.shrine_at, d.poor_spot]:
		t.check(grid.nearest_walkable(spot).distance_to(spot) <= 0.6, "the spot %s snaps to ground within 0.6" % [spot])
	var shrine := d.house as Structure
	var crowded := PackedStringArray()
	for st: Structure in (s.env as EnvironmentField).structures():
		if st != shrine and is_instance_valid(st) and not st.destroyed and st.footprint.grow(0.3).intersects(shrine.footprint):
			crowded.append(str(st.footprint))
	t.check(crowded.is_empty(), "the shrine stands on free ground (touching %s)" % [crowded])
	t.check(grid.walkable(d.door) and d.door.distance_to(shrine.center()) < 2.5, "the shrine's door is open ground by it (%s)" % [d.door])
	var inner := CapitalCity.INNER
	var far := 0
	var lost := 0
	for g in d.grieving:
		far += 0 if inner.has_point(g.ground_pos) else 1
		lost += 0 if not grid.path(g.ground_pos, d.door).is_empty() else 1
	t.check(d.grieving.size() == FirstPrayersDirector.POOR and far == 0 and lost == 0,
		"the %d poor all stand in the old town with a way to the door (%d outside, %d cut off)" % [d.grieving.size(), far, lost])
	var nearest := INF
	var farthest := 0.0
	for g in d.grieving:
		nearest = minf(nearest, g.ground_pos.distance_to(d.door))
		farthest = maxf(farthest, g.ground_pos.distance_to(d.door))
	print("TEST prayers: the poor stand %.1f-%.1f from the door (Aldermere's 10.0-11.8)" % [nearest, farthest])
	# One Mind Whisper hop covers 9.5: a poor lot far beyond it needs two (and the second cannot be cast while the first holds), a lot
	# right at the door makes the night quick; the Capital's poor stand about where Aldermere's do.
	t.check(nearest >= 8.5 and farthest <= 14.0, "the poor stand 8.5-14.0 from the door (%.1f-%.1f)" % [nearest, farthest])
	for pair: Array in [["line", MirasHouseDirector.LINE_SPOTS], ["priests", FirstPrayersDirector.PRIEST_SPOTS]]:
		var landed: Array[Vector2] = []
		var snug := true
		for off: Vector2 in pair[1]:
			var at := d._walkable(d.door + off)
			landed.append(at)
			snug = snug and at.distance_to(d.door + off) <= 1.0
		var apart := INF
		for i in landed.size():
			for j in range(i + 1, landed.size()):
				apart = minf(apart, landed[i].distance_to(landed[j]))
		t.check(snug and apart > 1.6, "the %s spots at the door land within 1.0 of their offsets and %.2f apart (> 1.6)" % [pair[0], apart])


## At the intro's last camera, the first targets' tags (the shrine, the first of the poor, the Temple) lie outside the padded HUD stack.
static func _camera_clear(t, s: Dictionary, def: MissionDef) -> void:
	var d: FirstPrayersDirector = s.d
	var cam := def.camera()
	var zone := Rect2(Kit.STACK.position, Kit.STACK.size + Vector2(Hud.STACK_PAD, Hud.STACK_PAD))
	var first: Person = null
	for g in d.grieving:
		first = g
		break
	t.check(Kit.clear_of_stack(d.door, cam, zone), "the shrine's tag is clear of the padded stack at the camera %s" % [cam])
	t.check(first != null and Kit.clear_of_stack(first.ground_pos, cam, zone), "the first of the poor is clear of the padded stack")
	t.check(Kit.clear_of_stack(d.temple_door, cam, zone), "the Temple's door is clear of the padded stack")


## The tour names the Capital's quarter for the poor and not Aldermere's; Aldermere's own line is unchanged.
static func _tour_true(t, s: Dictionary, home: Dictionary) -> void:
	var d: FirstPrayersDirector = s.d
	var line := _poor_line(d)
	t.check(line.contains(d.poor_quarter) and not line.contains("south-west"), "the Capital tour names the poor's quarter (%s)" % [line])
	t.check(home.poor_line == ALDERMERE_POOR_LINE, "Aldermere's tour line is as it was (%s)" % [home.poor_line])
	var lines := d.tour()
	t.check(lines.size() == 3 and (lines[0][0] as Vector2) == d.door and (lines[2][0] as Vector2) == d.temple_door,
		"the tour shows the shrine, the poor and the Temple")


static func _poor_line(d: FirstPrayersDirector) -> String:
	for l: Array in d.tour():
		if String(l[1]).begins_with("The poor"):
			return String(l[1])
	return ""
