class_name TownFloor
extends Node2D
## Aldermere's ground, drawn once in ground units under the iso ground plane: meadow, with forest floor beyond the
## west, north and east walls; packed earth inside the walls; cobbled streets that turn into dirt roads outside;
## flagstones for the market and the Citadel court; the sandy barracks yard; farm soil; and the river. The river's
## glints are a small child node that redraws on its own, so this big drawing never has to.

## Drawn area: past the map so zoomed-out views rarely show the void.
const FILL := Rect2(-20, -20, 44, 44)
const GRASS := [Color("587a30"), Color("6a8e3a"), Color("4a6a2a")]
const FOREST := [Color("3e5a26"), Color("46632a"), Color("365020")]
const EARTH := [Color("8a7658"), Color("826e52"), Color("7a684c")]
const TRACK := [Color("7e6a50"), Color("76624a")]
const COBBLE := [Color("8a8274"), Color("958c7d"), Color("7f786c"), Color("777064")]
const FLAG := [Color("a09884"), Color("aaa18d"), Color("968e7b")]
const MORTAR := Color("4e4840")
const SAND := [Color("b09a6c"), Color("a88f62")]
const SOIL := [Color("6e5a3c"), Color("64523a")]
const WATER := Color("3a6a8a")
const WATER_DEEP := Color("2f5a78")
const BANK := Color("5a4a34")
## Tilled soil band the farm fields sit in.
const FARM_BAND := Rect2(-12, 13.4, 28, 2.4)


## Light glints drifting down the river, redrawn a few times a second for a stepped pixel flow.
class RiverGlints extends Node2D:
	const STEP := 0.12
	var _time := 0.0
	var _next := 0.0

	func _process(delta: float) -> void:
		_time += delta
		if _time >= _next:
			_next = _time + STEP
			queue_redraw()

	func _draw() -> void:
		var r := TownLayout.RIVER
		for i in 70:
			var h := (i * 7919 + 13) % 997
			var y := r.position.y + 0.15 + float(h % 61) / 61.0 * (r.size.y - 0.3)
			var x := r.position.x + fposmod(float(h) * 0.53 + _time * (0.5 + float(h % 5) * 0.1), r.size.x)
			draw_rect(Rect2(x, y, 0.3 + float(h % 3) * 0.1, 0.04), Color(0.78, 0.9, 1.0, 0.55))


func _ready() -> void:
	var glints := RiverGlints.new()
	glints.name = "RiverGlints"
	add_child(glints)


func _draw() -> void:
	_meadow()
	_fill(TownLayout.TOWN, EARTH, 0.5)
	_fill(FARM_BAND, SOIL, 0.5)
	_fill(TownLayout.BARRACKS_YARD, SAND, 0.25)
	for road: Rect2 in TownLayout.ROADS:
		_fill(road, TRACK, 0.25)
		_paving(road.intersection(TownLayout.TOWN), COBBLE, 0.25)
	_paving(TownLayout.MARKET_SQUARE, FLAG, 0.4)
	_paving(TownLayout.CITADEL_COURT, FLAG, 0.4)
	_river()


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 997


## Grass (or darker forest floor) cell by cell with small tufts, so the ground never reads as one flat colour.
func _meadow() -> void:
	for y in range(int(FILL.position.y), int(FILL.end.y)):
		for x in range(int(FILL.position.x), int(FILL.end.x)):
			var pal: Array = FOREST if _forest(Vector2(x + 0.5, y + 0.5)) else GRASS
			draw_rect(Rect2(x, y, 1, 1), pal[_hash(x, y) % 3])
			for k in 4:
				var hk := _hash(x * 13 + k, y * 29 - k)
				var p := Vector2(x + float(hk % 89) / 89.0, y + float(floori(hk / 89.0) % 83) / 83.0)
				draw_rect(Rect2(p, Vector2(0.06, 0.12)), (pal[(hk + 1) % 3] as Color).lightened(0.12))


## Forest floor beyond the walls on the west, north and east, north of the river and off the east road.
func _forest(g: Vector2) -> bool:
	if g.y > TownLayout.RIVER.position.y or (absf(g.y) < 0.8 and g.x > TownLayout.TOWN.end.x):
		return false
	var town := TownLayout.TOWN.grow(0.6)
	return g.x < town.position.x or g.y < town.position.y or g.x > town.end.x


## Tile a rect with cell-sized squares in hashed palette colours.
func _fill(r: Rect2, pal: Array, cell: float) -> void:
	var nx := int(ceilf(r.size.x / cell))
	var ny := int(ceilf(r.size.y / cell))
	var ox := int(r.position.x * 8.0)
	var oy := int(r.position.y * 8.0)
	for j in ny:
		for i in nx:
			var sq := Rect2(r.position + Vector2(i, j) * cell, Vector2(cell, cell)).intersection(r)
			draw_rect(sq, pal[_hash(i + ox, j + oy) % pal.size()])


## Stones in staggered rows with mortar gaps; every fourth stone catches the light on its top edge.
func _paving(r: Rect2, pal: Array, stone: float) -> void:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	draw_rect(r, MORTAR)
	var nx := int(ceilf(r.size.x / stone)) + 1
	var ny := int(ceilf(r.size.y / stone))
	var ox := int(r.position.x * 8.0)
	var oy := int(r.position.y * 8.0)
	for j in ny:
		var shift := stone * 0.5 if j % 2 == 1 else 0.0
		for i in nx:
			var sq := Rect2(r.position + Vector2(i * stone - shift, j * stone), Vector2(stone, stone)).intersection(r).grow(-0.02)
			if sq.size.x <= 0.0 or sq.size.y <= 0.0:
				continue
			var h := _hash(i * 3 + ox, j * 5 + oy)
			var c: Color = pal[h % pal.size()]
			draw_rect(sq, c)
			if h % 4 == 0:
				draw_rect(Rect2(sq.position, Vector2(sq.size.x, 0.04)), c.lightened(0.15))


## Water across the whole drawn width (the gameplay river is the map-wide TownLayout.RIVER), deeper in the middle,
## with earthen banks.
func _river() -> void:
	var r := TownLayout.RIVER
	var x0 := FILL.position.x
	var w := FILL.size.x
	draw_rect(Rect2(x0, r.position.y, w, r.size.y), WATER)
	draw_rect(Rect2(x0, r.position.y + r.size.y * 0.3, w, r.size.y * 0.4), WATER_DEEP)
	draw_rect(Rect2(x0, r.position.y - 0.08, w, 0.08), BANK)
	draw_rect(Rect2(x0, r.end.y, w, 0.08), BANK)
