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
##   &"farm"           farm buildings with tilled ground round them (barns, the mills);
##   &"paved"          cobbled ground beyond town(), treated as inside the walls (the capital's second wall ring);
##   &"crossings"      the bridges over the river, where its banks get no pebbles.
func floor_areas() -> Dictionary: return {}

## The countryside the floor and decor dress the city with (none by default):
func trails() -> Array: return []                          # meadow trails, polylines of Vector2 (fenced, clearable)
func road_trails() -> Array[Dictionary]: return []         # dirt roads beyond the walls: {points: polyline, width}
func outcrops() -> Array: return []                        # rocky outcrops: [centre, radius]
## Each gate plaza's paved rosette, by gate plaza index (drawn only where that plaza holds it): {at, radius, along_y
## (its cart ruts run north-south), across (the line the ruts run along: x when along_y, else y)}.
func rosettes() -> Array[Dictionary]: return []
func boats() -> Array[Vector2]: return []                  # rowing boats on the water
func scarecrows() -> Array[Vector2]: return []             # on the fields' tilled edges
func signposts() -> Array[Vector2]: return []              # by the roads beyond the walls
func carts() -> Array[Vector2]: return []                  # by the farms


## Ground the forest ring leaves open (TownFloor and TownDecor): by default each road reaching beyond town(), 0.8
## either side of it across its length (1.5 from its centre line at Aldermere's 1.4-wide roads).
func forest_gaps() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var t := town()
	for r: Rect2 in roads():
		if t.encloses(r):
			continue
		out.append(r.grow_individual(0.0, FOREST_GAP, 0.0, FOREST_GAP) if r.size.x > r.size.y
			else r.grow_individual(FOREST_GAP, 0.0, FOREST_GAP, 0.0))
	return out


## How far past a road's sides the forest stays back (forest_gaps()).
const FOREST_GAP := 0.8
