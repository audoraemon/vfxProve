class_name AldermereCity
extends CityDef
## Aldermere through the shared city format: every method hands back TownLayout's own data (its constants, or its
## static functions' results) unchanged, in the same order, as fresh copies.

const LANDMARKS := {
	&"market_square": TownLayout.MARKET_SQUARE, &"temple": TownLayout.TEMPLE,
	&"citadel_court": TownLayout.CITADEL_COURT, &"bell_tower": TownLayout.BELL_TOWER, &"dock": TownLayout.DOCK,
	&"dock_wait": TownLayout.DOCK_WAIT, &"main_gate": TownLayout.MAIN_GATE, &"barracks": TownLayout.BARRACKS,
	&"barracks_yard": TownLayout.BARRACKS_YARD, &"workshop": TownLayout.WORKSHOP, &"smithy": TownLayout.SMITHY,
	&"carpenter": TownLayout.CARPENTER, &"windmill": TownLayout.WINDMILL, &"watermill": TownLayout.WATERMILL,
	&"bridge": TownLayout.BRIDGE, &"fountain_plaza": TownLayout.FOUNTAIN_PLAZA,
	&"carpenter_yard": TownLayout.CARPENTER_YARD, &"tavern_patio": TownLayout.TAVERN_PATIO,
	&"smithy_yard": TownLayout.SMITHY_YARD, &"river": TownLayout.RIVER, &"river_west": TownLayout.RIVER_WEST,
}


func id() -> StringName:
	return &"aldermere"


func map() -> Rect2:
	return TownLayout.MAP


func town() -> Rect2:
	return TownLayout.TOWN


func rivers() -> Array[Rect2]:
	return _rects(TownLayout.RIVERS)


func roads() -> Array:
	return TownLayout.ROADS.duplicate(true)


func exits() -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.assign(TownLayout.EXITS)
	return out


func districts() -> Array:
	return TownLayout.DISTRICTS.duplicate(true)


func structures() -> Array[Dictionary]:
	return TownLayout.structures().duplicate(true)


func houses() -> Array[Rect2]:
	return TownLayout.houses().duplicate()


func blockers() -> Array[Rect2]:
	return TownLayout.blockers().duplicate()


func anchors() -> Dictionary:
	return TownLayout.anchors().duplicate(true)


func street_props() -> Array[Dictionary]:
	return TownLayout.street_props().duplicate(true)


func gardens() -> Array[Rect2]:
	return TownLayout.gardens().duplicate()


func queue_fans(margin := 0.3) -> Array[PackedVector2Array]:
	return TownLayout.queue_fans(margin).duplicate()


func fields() -> Array[Rect2]:
	return _rects(TownLayout.FIELDS)


func stalls() -> Array[Rect2]:
	return _rects(TownLayout.STALLS)


func fountains() -> Array[Rect2]:
	return _rects(TownLayout.FOUNTAINS)


func wells() -> Array[Rect2]:
	return _rects(TownLayout.WELLS)


func taverns() -> Array[Rect2]:
	return _rects(TownLayout.TAVERNS)


func pastures() -> Array[Rect2]:
	return _rects(TownLayout.PASTURES)


func market_piles() -> Array[Rect2]:
	return _rects(TownLayout.MARKET_PILES)


func torches() -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.assign(TownLayout.TORCHES)
	return out


func ship_at() -> Vector2:
	return TownLayout.SHIP_AT


## Exactly the rects TownFloor painted from TownLayout before the city format, in the same order.
func floor_areas() -> Dictionary:
	var building_yards: Array[Rect2] = [TownLayout.TEMPLE.grow(0.35), TownLayout.SMITHY.grow(0.3),
		TownLayout.WORKSHOP.grow(0.3), TownLayout.CARPENTER.grow(0.3), TownLayout.CARPENTER_YARD.grow(0.2)]
	for t: Rect2 in TownLayout.TAVERNS:
		building_yards.append(t.grow(0.3))
	var farm := _rects(TownLayout.BARNS)
	farm.append_array([TownLayout.WINDMILL, TownLayout.WATERMILL])
	var plazas: Array[Rect2] = [TownLayout.MARKET_SQUARE, TownLayout.CITADEL_COURT, TownLayout.FOUNTAIN_PLAZA]
	var yards: Array[Rect2] = [TownLayout.BARRACKS_YARD]
	return {
		&"plazas": plazas, &"yards": yards, &"gate_plazas": _rects(TownLayout.GATE_PLAZAS),
		&"building_yards": building_yards, &"farm": farm,
	}


func citadel_origin() -> Vector2:
	return TownLayout.CITADEL_ORIGIN


func landmark(name: StringName) -> Rect2:
	return LANDMARKS.get(name, Rect2())


## A fresh typed copy of one of TownLayout's (untyped, read-only) Rect2 constants.
static func _rects(src: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.assign(src)
	return out
