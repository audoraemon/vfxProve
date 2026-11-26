class_name ChamberLayout
extends RefCounted
## God's Chamber: the room as data. One 840 x 360 room (x from -100 to 740) seen through a 640 x 360 frame; the four stations
## sit on layers that shift against the mouse by different amounts (parallax). Everything the screen draws, hit-tests or binds
## to a key comes from this table, so art can be swapped without touching the screen.

const ROOM := Rect2(-100.0, 0.0, 840.0, 360.0)
const FRAME := Rect2(0.0, 0.0, 640.0, 360.0)
const BAR_H := 22.0
const PARALLAX_MAX := 6.0
const LAYERS := {"wall": 0.25, "stations": 0.5, "table": 0.75, "desk": 1.0}
## The painting's lit part (room units): beyond its sides the wall fades to black. A zoom that would show more of those sides than the
## window showed at rest covers them in the station's colour (GodChamber.veil_edges()).
const LIT := Rect2(-20.0, 0.0, 665.0, 360.0)
const ORDER: Array[String] = ["descend", "tree", "faith", "awaken"]

## Front layer first: the order a click is tested in.
const _HIT_LAYERS: Array[String] = ["table", "stations", "wall"]

const STATIONS := {
	"descend": {
		"name": "World Table", "rect": Rect2(207.0, 232.0, 218.0, 88.0), "focus": Vector2(316.0, 262.0),
		"layer": "wall", "keys": [KEY_ENTER, KEY_KP_ENTER, KEY_1], "action": "descend",
	},
	"tree": {
		"name": "Ability Tree", "rect": Rect2(0.0, 125.0, 68.0, 182.0), "focus": Vector2(34.0, 215.0),
		"layer": "wall", "keys": [KEY_T, KEY_2], "action": "tree",
	},
	"faith": {
		"name": "Faith Altar", "rect": Rect2(548.0, 192.0, 82.0, 110.0), "focus": Vector2(590.0, 245.0),
		"layer": "wall", "keys": [KEY_F, KEY_3], "action": "faith",
	},
	"awaken": {
		"name": "Rite Door", "rect": Rect2(122.0, 82.0, 112.0, 148.0), "focus": Vector2(178.0, 156.0), "art": Rect2(116.0, 62.0, 132.0, 226.0),
		"layer": "wall", "keys": [KEY_A, KEY_4], "action": "awaken",
	},
}

## Pieces that are drawn but cannot be clicked. The stations are painted in the wall's own picture (one scene, one camera),
## so they ride the wall's layer; a station's optional "art" rect is where its picture is drawn when that is larger than
## the rect that is clicked (the Rite Door's step and the light it throws).
const SCENERY: Array = [
	{"name": "wall", "rect": Rect2(-100.0, 0.0, 840.0, 360.0), "layer": "wall"},
	{"name": "desk", "rect": Rect2(-100.0, 283.0, 840.0, 77.0), "layer": "desk"},
]


## How far a layer moves for a mouse position given as -1..1 from the screen centre: the opposite way, whole units.
static func shift(layer: String, mouse01: Vector2) -> Vector2:
	var m := Vector2(clampf(mouse01.x, -1.0, 1.0), clampf(mouse01.y, -1.0, 1.0))
	return (-m * PARALLAX_MAX * float(LAYERS[layer])).round()


## A station's rect moved by its layer's shift.
static func rect_of(key: String, mouse01 := Vector2.ZERO) -> Rect2:
	var s: Dictionary = STATIONS[key]
	var r: Rect2 = s["rect"]
	r.position += shift(s["layer"], mouse01)
	return r


## The station under a design-frame point, front layer first; "" for none or for a point inside the top bar.
static func at(point: Vector2, mouse01 := Vector2.ZERO, bar_top := 0.0) -> String:
	if point.y < bar_top + BAR_H:
		return ""
	for layer in _HIT_LAYERS:
		for k in ORDER:
			if STATIONS[k]["layer"] == layer and rect_of(k, mouse01).has_point(point):
				return k
	return ""


## The station a key belongs to, or "".
static func key_for(code: Key) -> String:
	for k in ORDER:
		if (STATIONS[k]["keys"] as Array).has(code):
			return k
	return ""
