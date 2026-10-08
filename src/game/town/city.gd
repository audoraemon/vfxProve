class_name City
extends RefCounted
## The city being built or played. Missions set it before building (Mission, town_debug); defaults to Aldermere.

static var active: CityDef = null


static func current() -> CityDef:
	if active == null:
		active = AldermereCity.new()
	return active


static func use(id: StringName) -> void:
	active = by_id(id)


static func by_id(id: StringName) -> CityDef:
	match id:
		&"capital":
			return load("res://src/game/town/cities/capital_city.gd").new()
		_:
			return AldermereCity.new()
