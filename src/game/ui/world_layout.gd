class_name WorldLayout
extends RefCounted
## The World Map as data (World Map + Conquer Progress, Task 5): six spots on a 640 x 360 page -- two towns (Aldermere, the Capital) and four
## sealed ones the god cannot reach yet -- measured on the painted map. Everything WorldMap draws and hit-tests comes from here.

## The map's vellum inside its carved frame (the painting assets/chamber/map.png, concepts/world_map/); the spots all sit on it.
const LAND := Rect2(12.0, 29.0, 616.0, 316.0)
## A spot's hit radius: its rect is a square of twice this about its place.
const HIT_R := 22.0
## Half the width and height of a town's picture, for its ring, its light and its fog.
const SPAN := Vector2(34.0, 24.0)

## Measured on the painting (1671 x 941 drawn on the 640 x 360 page). `place`: the town's middle. `ribbon`: the flat of its blank name ribbon
## (the code writes the name there). `span`: half its width and height on the page (SPAN when not given). `smoke`: a chimney, or none. `source` "town": the name is read from Conquest.town_name(); "sealed": the
## spot is beyond the god's reach.
const SPOTS: Array = [
	{"id": "aldermere", "name": "", "place": Vector2(234.0, 216.0), "ribbon": Rect2(213.0, 167.0, 51.0, 12.5), "smoke": Vector2(226.0, 188.0), "source": "town"},
	{"id": "capital", "name": "", "place": Vector2(425.0, 160.0), "span": Vector2(90.0, 50.0), "ribbon": Rect2(357.0, 100.5, 57.0, 14.0), "source": "town"},
	{"id": "thornwick", "name": "Thornwick", "place": Vector2(113.0, 127.0), "ribbon": Rect2(86.0, 79.0, 51.0, 12.5), "source": "sealed"},
	{"id": "saltmere", "name": "Saltmere", "place": Vector2(513.0, 283.0), "ribbon": Rect2(484.0, 238.5, 53.0, 13.5), "source": "sealed"},
	{"id": "greyhollow", "name": "Greyhollow", "place": Vector2(116.0, 285.0), "ribbon": Rect2(89.0, 238.5, 54.0, 13.5), "smoke": Vector2(155.0, 264.0), "source": "sealed"},
	{"id": "vael", "name": "Vael Crossing", "place": Vector2(440.0, 77.0), "ribbon": Rect2(412.0, 36.5, 52.0, 12.5), "smoke": Vector2(484.0, 54.0), "source": "sealed"},
]
## The painted road between the towns (kept for the tests and the arrows; the painting draws it).
const ROADS := [["aldermere", "capital"]]
## Ways not yet known: a dotted path from an open town toward a sealed one, bent through `via`.
const ROUTES := [
	{"from": "aldermere", "to": "thornwick", "via": Vector2(150.0, 190.0)},
	{"from": "aldermere", "to": "greyhollow", "via": Vector2(185.0, 262.0)},
	{"from": "capital", "to": "vael", "via": Vector2(405.0, 118.0)},
	{"from": "aldermere", "to": "saltmere", "via": Vector2(390.0, 246.0)},
]
## The title's place in the painted cartouche, the candles in the frame's corner, and the calm vellum the plate lies on.
const TITLE_AT := Vector2(320.0, 22.0)
const CANDLES_AT := Vector2(30.0, 40.0)


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


## The flat of the spot's name ribbon on the painting.
static func ribbon(id: String) -> Rect2:
	return spot(id).get("ribbon", Rect2())


## Half the width and height of the spot's picture on the page.
static func span(id: String) -> Vector2:
	return spot(id).get("span", SPAN)
