class_name City
extends RefCounted
## The city being built or played. Missions set it before building (Mission, town_debug); defaults to Aldermere.

static var active: CityDef = null
## The ids of the cities that exist (by_id()).
const IDS := [&"aldermere", &"capital"]
## Cities a test registered (register()): ids() lists them and by_id() builds them. Empty outside a test.
static var _extra := {}


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


## Every city id: IDS, then the ones a test registered.
static func ids() -> Array:
	var out: Array = IDS.duplicate()
	for id: StringName in _extra:
		out.append(id)
	return out


## Whether `id` names a city (IDS or registered).
static func has(id: StringName) -> bool:
	return id in IDS or _extra.has(id)


## A test's fixture town (v0.12): `def` answers by_id(`id`) until unregister(). Never used by the game.
static func register(id: StringName, def: CityDef) -> void:
	_extra[id] = def


static func unregister(id: StringName) -> void:
	_extra.erase(id)
	if active != null and active.id() == id:
		active = null


## A fresh city for `id`. An unknown id is an error; Aldermere stands in so the game still runs.
static func by_id(id: StringName) -> CityDef:
	if _extra.has(id):
		return _extra[id]
	match id:
		&"aldermere":
			return AldermereCity.new()
		&"capital":
			return CapitalCity.new()
		_:
			push_error("City.by_id: unknown city '%s'; using Aldermere" % id)
			return AldermereCity.new()
