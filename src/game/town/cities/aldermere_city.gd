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


func citadel_origin() -> Vector2:
	return TownLayout.CITADEL_ORIGIN


func landmark(name: StringName) -> Rect2:
	return LANDMARKS.get(name, Rect2())


## A fresh typed copy of one of TownLayout's (untyped, read-only) Rect2 constants.
static func _rects(src: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.assign(src)
	return out
