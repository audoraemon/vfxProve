class_name Places
extends RefCounted
## The places a mission reads, by name, from the active town (v0.12). CityDef answers landmark() and place(); a misspelt
## name there is an empty Rect2(), whose centre is the map's middle -- a silent bug. Missions read through here instead, and
## an unknown name is an error. A town's needs (MissionNeeds) are asked with has().

## The needs that are lists on the city: present when the list is not empty (`name:n`: at least n long).
const LIST_NEEDS := [&"gate_towers", &"barns", &"taverns", &"wells", &"fountains", &"districts"]


## The active city's landmark `name`; an error and Rect2() when it has none.
static func rect(name: StringName) -> Rect2:
	var r := City.current().landmark(name)
	if not r.has_area():
		push_error("Places.rect: city '%s' has no landmark '%s'" % [City.current().id(), name])
		return Rect2()
	return r


## The active city's place `name`; an error and Vector2.INF when it has none.
static func point(name: StringName) -> Vector2:
	var p := City.current().place(name)
	if p == Vector2.INF:
		push_error("Places.point: city '%s' has no place '%s'" % [City.current().id(), name])
	return p


## A landmark's centre, else a place's point; an error and Vector2.INF for neither.
static func at(name: StringName) -> Vector2:
	var r := City.current().landmark(name)
	if r.has_area():
		return r.get_center()
	var p := City.current().place(name)
	if p == Vector2.INF:
		push_error("Places.at: city '%s' has no landmark or place '%s'" % [City.current().id(), name])
	return p


## Whether `city` has what a need names: `citadel` (an Aldermere-style Citadel node), a list (`taverns`, `barns:4`), or any
## other name: a landmark with area or a known place.
static func has(city: CityDef, need: StringName) -> bool:
	var text := String(need)
	var base := StringName(text.get_slice(":", 0))
	var count := int(text.get_slice(":", 1)) if ":" in text else 1
	if ":" in text and not base in LIST_NEEDS:
		push_error("Places.has: '%s' has a count, but only the list needs (%s) are counted" % [need, LIST_NEEDS])
	if base == &"citadel":
		return city.citadel_origin() != Vector2.INF
	if base in LIST_NEEDS:
		return _list(city, base).size() >= maxi(count, 1)
	return city.landmark(base).has_area() or city.place(base) != Vector2.INF


## Whether `city` has every place mission `id` needs (MissionNeeds); an id with no row is an error and false. Whether it is
## also offered there is MissionBook.hostable().
static func can_host(id: String, city: CityDef) -> bool:
	if not MissionNeeds.TABLE.has(id):
		push_error("Places.can_host: no needs listed for '%s'; it cannot be hosted" % id)
		return false
	for need: String in MissionNeeds.of(id):
		if not has(city, StringName(need)):
			return false
	return true


static func _list(city: CityDef, name: StringName) -> Array:
	match name:
		&"gate_towers":
			return city.gate_towers()
		&"barns":
			return city.barns()
		&"taverns":
			return city.taverns()
		&"wells":
			return city.wells()
		&"fountains":
			return city.fountains()
		&"districts":
			return city.districts()
	return []
