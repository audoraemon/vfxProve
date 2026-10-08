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
func taverns() -> Array[Rect2]: return []
func pastures() -> Array[Rect2]: return []
func market_piles() -> Array[Rect2]: return []             # market clutter (Aldermere: TownLayout.MARKET_PILES)
func torches() -> Array[Vector2]: return []                # torch posts; the first four are the market's corners
func ship_at() -> Vector2: return Vector2.INF              # where the moored ship lies (INF = no ship)
func citadel_origin() -> Vector2: return Vector2.INF       # INF = this city has no Aldermere-style Citadel node
func landmark(name: StringName) -> Rect2: return Rect2()   # empty Rect2 = unknown
## Ground the floor paints, name -> Array[Rect2] (a missing key is no such ground):
##   &"plazas"         flagstone squares, open ground (Aldermere: market, citadel court, fountain plaza);
##   &"yards"          sanded working yards, open ground (the barracks yard);
##   &"gate_plazas"    cobbled queue ground inside each gate, one cart-rut salt and rosette per index;
##   &"building_yards" packed-earth yards round the landmark buildings, already grown to their painted size;
##   &"farm"           farm buildings with tilled ground round them (barns, the mills).
func floor_areas() -> Dictionary: return {}
