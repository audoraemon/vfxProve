class_name WorldLayout
extends RefCounted
## The World Map as data (World Map + Conquer Progress, Task 5): six spots on a 640 x 360 page -- two towns (Aldermere, the Capital) and four
## sealed ones the god cannot reach yet -- and the road between the towns. Everything WorldMap draws and hit-tests comes from here.

## The land, inside the sea; the spots all sit on it.
const LAND := Rect2(40.0, 34.0, 560.0, 290.0)
## A spot's hit radius: its rect is a square of twice this about its place.
const HIT_R := 16.0

## `source` "town": the name is read from Conquest.town_name(); "sealed": the spot is beyond the god's reach.
const SPOTS: Array = [
	{"id": "aldermere", "name": "", "place": Vector2(250.0, 220.0), "source": "town"},
	{"id": "capital", "name": "", "place": Vector2(420.0, 140.0), "source": "town"},
	{"id": "thornwick", "name": "Thornwick", "place": Vector2(110.0, 110.0), "source": "sealed"},
	{"id": "saltmere", "name": "Saltmere", "place": Vector2(540.0, 260.0), "source": "sealed"},
	{"id": "greyhollow", "name": "Greyhollow", "place": Vector2(130.0, 290.0), "source": "sealed"},
	{"id": "vael", "name": "Vael Crossing", "place": Vector2(555.0, 85.0), "source": "sealed"},
]
const ROADS := [["aldermere", "capital"]]


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for s: Dictionary in SPOTS:
		out.append(String(s.id))
	return out


## The spot's row, or {} for an unknown id.
static func spot(id: String) -> Dictionary:
	for s: Dictionary in SPOTS:
		if s.id == id:
			return s
	return {}


static func name_of(id: String) -> String:
	var s := spot(id)
	if s.is_empty():
		return ""
	return Conquest.town_name(id) if s.source == "town" else String(s.name)


static func is_town(id: String) -> bool:
	return str(spot(id).get("source", "")) == "town"


static func spot_rect(id: String) -> Rect2:
	var p: Vector2 = spot(id).get("place", Vector2.ZERO)
	return Rect2(p - Vector2(HIT_R, HIT_R), Vector2(HIT_R, HIT_R) * 2.0)


## The spot nearest `point`, within HIT_R of its place; "" for none.
static func at(point: Vector2) -> String:
	var best := ""
	var best_d := HIT_R + 0.001
	for s: Dictionary in SPOTS:
		var d := point.distance_to(s.place as Vector2)
		if d < best_d:
			best_d = d
			best = String(s.id)
	return best
