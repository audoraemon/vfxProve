class_name CityDef
extends RefCounted
## One city's layout: what the town builder, floor, decor, walk grid and crowd read (via City.active).
## Rects are ground cells; every method is deterministic and returns fresh arrays (callers may mutate them).

func id() -> StringName: return &""
func map() -> Rect2: return Rect2()
func town() -> Rect2: return Rect2()                       # the walled core (Aldermere: TownLayout.TOWN)
func rivers() -> Array[Rect2]: return []
func roads() -> Array: return []                           # polylines as in TownLayout.ROADS
func exits() -> Array[Vector2]: return []
func districts() -> Array: return []                       # as TownLayout.DISTRICTS
func structures() -> Array[Dictionary]: return []          # as TownLayout.structures()
func houses() -> Array[Rect2]: return []
func blockers() -> Array[Rect2]: return []
func anchors() -> Dictionary: return {}                    # as TownLayout.anchors()
func street_props() -> Array[Dictionary]: return []
func gardens() -> Array[Rect2]: return []
func queue_fans(margin := 0.3) -> Array[PackedVector2Array]: return []
func fields() -> Array[Rect2]: return []
func stalls() -> Array[Rect2]: return []
func fountains() -> Array[Rect2]: return []
func wells() -> Array[Rect2]: return []
func citadel_origin() -> Vector2: return Vector2.INF       # INF = this city has no Aldermere-style Citadel node
func landmark(name: StringName) -> Rect2: return Rect2()   # empty Rect2 = unknown
func floor_areas() -> Dictionary: return {}                # name -> Array[Rect2], see Task 3
