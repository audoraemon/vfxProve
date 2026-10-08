class_name City
extends RefCounted
## The city being built or played. Missions set it before building (Mission, town_debug); defaults to Aldermere.

static var active: CityDef = null


static func current() -> CityDef:
	if active == null:
		active = AldermereCity.new()
	return active


## Makes `id` the active city. The active city is kept when it already is `id` (CityDefs hold no state, and the
## floor and decor caches are kept per city object); another id makes a fresh one.
static func use(id: StringName) -> void:
	if active != null and active.id() == id:
		return
	active = by_id(id)


## A fresh city for `id`. An unknown id is an error; Aldermere stands in so the game still runs.
static func by_id(id: StringName) -> CityDef:
	match id:
		&"aldermere":
			return AldermereCity.new()
		&"capital":
			return load("res://src/game/town/cities/capital_city.gd").new()
		_:
			push_error("City.by_id: unknown city '%s'; using Aldermere" % id)
			return AldermereCity.new()
