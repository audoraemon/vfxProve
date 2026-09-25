class_name TownLayout
extends RefCounted
## Aldermere, the town of the one-mission game, as pure data in ground units: origin at the town centre, plan
## north = -y (on screen the Citadel sits upper right, the Main Gate lower left). Town builds it; the Citadel's
## nine parts live in citadel.gd. Numbers follow the spec's town table.

const MAP := Rect2(-12, -12, 28, 28)
## Inside the town walls.
const TOWN := Rect2(-9, -9, 18, 18)
const RIVER := Rect2(-12, 11.4, 28, 1.6)
## North-south street from the Citadel gate out through the Main Gate and over the bridge; east-west street from
## the west wall out through the Side Gate along the forest road.
const ROADS := [Rect2(-0.4, -3.5, 0.8, 19.5), Rect2(-8.4, -0.4, 24.4, 0.8)]
const MARKET_SQUARE := Rect2(-2.9, -2.4, 5.8, 5.0)
const BARRACKS_YARD := Rect2(3.9, 0.7, 4.2, 2.4)
## The Citadel's ground (its nine parts stay inside) and its paved court.
const CITADEL_AREA := Rect2(-2.7, -8.2, 5.4, 4.6)
const CITADEL_COURT := Rect2(-2.9, -8.4, 5.8, 5.0)
## Centre of the keep.
const CITADEL_ORIGIN := Vector2(0, -5.9)
## Reaching one of these means a citizen escaped: the south road and the east forest road at the map edge.
const EXITS := [Vector2(0, 15.6), Vector2(15.6, 0)]

const WALLS := [
	Rect2(-7.95, -9.0, 15.9, 0.6), Rect2(-9.0, -7.95, 0.6, 15.9),
	Rect2(-7.95, 8.4, 6.55, 0.6), Rect2(1.4, 8.4, 6.55, 0.6),
	Rect2(8.4, -7.95, 0.6, 2.35), Rect2(8.4, -4.3, 0.6, 3.0), Rect2(8.4, 1.3, 0.6, 2.7), Rect2(8.4, 5.3, 0.6, 2.65),
]
const CORNER_TOWERS := [
	Rect2(-9.45, -9.45, 1.5, 1.5), Rect2(7.95, -9.45, 1.5, 1.5), Rect2(-9.45, 7.95, 1.5, 1.5), Rect2(7.95, 7.95, 1.5, 1.5),
]
const SIDE_TOWERS := [Rect2(8.05, -5.6, 1.3, 1.3), Rect2(8.05, 4.0, 1.3, 1.3)]
const MAIN_GATE := Rect2(-1.4, 8.2, 2.8, 1.0)
const SIDE_GATE := Rect2(8.2, -1.3, 1.0, 2.6)
const TEMPLE := Rect2(3.5, -7.6, 2.7, 3.1)
const BARRACKS := Rect2(3.9, -2.5, 4.2, 1.9)
const BRIDGE := Rect2(-1.0, 11.0, 2.0, 2.4)
const STALLS := [
	Rect2(-2.5, -2.0, 0.9, 0.7), Rect2(-1.4, -2.0, 0.9, 0.7), Rect2(0.6, -2.0, 0.9, 0.7), Rect2(1.7, -2.0, 0.9, 0.7),
	Rect2(-2.5, 1.4, 0.9, 0.7), Rect2(0.6, 1.4, 0.9, 0.7), Rect2(1.7, 1.4, 0.9, 0.7),
]
const FIELDS := [
	Rect2(-10.5, 13.7, 2.6, 1.8), Rect2(-7.7, 13.7, 2.6, 1.8), Rect2(-4.9, 13.7, 2.6, 1.8),
	Rect2(2.5, 13.7, 2.8, 1.8), Rect2(5.5, 13.7, 2.8, 1.8), Rect2(8.5, 13.7, 2.8, 1.8), Rect2(11.5, 13.7, 2.8, 1.8),
]
const BARNS := [Rect2(-11.9, 13.7, 1.2, 1.4), Rect2(14.5, 13.7, 1.2, 1.4)]
## Torch posts: the market corners, both sides of the Main Gate and the Citadel gate, outside the Side Gate.
const TORCHES := [
	Vector2(-2.9, -2.45), Vector2(2.8, -2.45), Vector2(-2.9, 2.35), Vector2(2.8, 2.35),
	Vector2(-1.8, 8.0), Vector2(1.6, 8.0), Vector2(-0.9, -3.3), Vector2(0.7, -3.3),
	Vector2(9.6, -1.8), Vector2(9.6, 1.6),
]
## Residential blocks filled with rows of houses (see houses()): north-west, south-west, south-middle, south-east.
const DISTRICTS := [Rect2(-8.1, -7.8, 4.9, 6.9), Rect2(-8.1, 0.9, 4.9, 6.9), Rect2(-2.6, 3.6, 2.0, 4.3), Rect2(0.7, 3.6, 7.1, 4.3)]
const HOUSE_WIDE := Vector2(1.3, 0.95)
const HOUSE_DEEP := Vector2(0.95, 1.25)
const HOUSE_GAP := Vector2(0.45, 0.5)
const TREE_SIZE := Vector2(0.7, 0.7)


## A wall run is built in short pieces instead of one long slab. A building sorts against the rest of the town
## by the screen point of its south-east corner, which is the corner nearest the camera -- fine for a house,
## wrong for a fifteen-unit wall, because that one corner put the whole north run in front of the north-west
## district, the market and all nine parts of the Citadel. A piece this long still sorts correctly against
## anything standing half a unit behind it, and a blast now takes a hole out of a wall instead of the side.
const WALL_PIECE := 1.2


## One wall run cut into pieces along its length. A run shorter than a piece comes back whole.
static func wall_pieces(r: Rect2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var along_x := r.size.x >= r.size.y
	var run: float = r.size.x if along_x else r.size.y
	var count := maxi(1, ceili(run / WALL_PIECE))
	var step := run / float(count)
	for i in count:
		var at := step * float(i)
		var pos: Vector2 = r.position + (Vector2(at, 0.0) if along_x else Vector2(0.0, at))
		var size: Vector2 = Vector2(step, r.size.y) if along_x else Vector2(r.size.x, step)
		out.append(Rect2(pos, size))
	return out


## Every building except the Citadel, as {rect, height, kind, role}.
static func structures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Rect2 in WALLS:
		for piece in wall_pieces(r):
			_add(out, piece, 34.0, Structure.Kind.CASTLE_WALL, &"wall")
	for r: Rect2 in CORNER_TOWERS:
		_add(out, r, 70.0, Structure.Kind.KEEP, &"tower")
	for r: Rect2 in SIDE_TOWERS:
		_add(out, r, 60.0, Structure.Kind.KEEP, &"tower")
	_add(out, MAIN_GATE, 40.0, Structure.Kind.GATE, &"gate")
	_add(out, SIDE_GATE, 40.0, Structure.Kind.GATE, &"gate")
	_add(out, TEMPLE, 56.0, Structure.Kind.TEMPLE, &"temple")
	_add(out, BARRACKS, 36.0, Structure.Kind.BARRACKS, &"barracks")
	for r: Rect2 in STALLS:
		_add(out, r, 10.0, Structure.Kind.MARKET_STALL, &"market")
	var house_rects := houses()
	for i in house_rects.size():
		_add(out, house_rects[i], 20.0 + float(i * 7 % 5) * 1.5, Structure.Kind.HOUSE, &"house")
	_add(out, BRIDGE, 6.0, Structure.Kind.BRIDGE, &"bridge")
	for r: Rect2 in FIELDS:
		_add(out, r, 3.0, Structure.Kind.FARM_FIELD, &"farm")
	for r: Rect2 in BARNS:
		_add(out, r, 20.0, Structure.Kind.HOUSE, &"farm")
	var tree_spots := trees()
	for i in tree_spots.size():
		_add(out, Rect2(tree_spots[i], TREE_SIZE), 26.0 + float(i % 3) * 3.0, Structure.Kind.TREE, &"decor")
	for p: Vector2 in TORCHES:
		_add(out, Rect2(p, Vector2(0.2, 0.2)), 16.0, Structure.Kind.TORCH, &"decor")
	return out


## House footprints: rows filling each district, alternating wide (1.3 x 0.95) and deep (0.95 x 1.25) houses,
## deep rows nudged sideways so the streets are not a perfect grid. 12 + 12 + 3 + 13 = 40 houses.
static func houses() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d: Rect2 in DISTRICTS:
		var y := d.position.y
		var row := 0
		while true:
			var size: Vector2 = HOUSE_WIDE if row % 2 == 0 else HOUSE_DEEP
			if y + size.y > d.end.y + 0.001:
				break
			var x := d.position.x + (0.2 if row % 2 == 1 else 0.0)
			while x + size.x <= d.end.x + 0.001:
				out.append(Rect2(Vector2(x, y), size))
				x += size.x + HOUSE_GAP.x
			y += size.y + HOUSE_GAP.y
			row += 1
	return out


## Tree spots (top-left corners): a row along the north edge, a column along the west edge and two columns on
## the east edge that leave the forest road clear, each nudged a little so the forest does not look planted.
static func trees() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for i in 14:
		spots.append(Vector2(-11.4 + 2.0 * i, -10.6))
	for i in 9:
		spots.append(Vector2(-10.6, -8.5 + 2.2 * i))
	for x: float in [10.6, 13.0]:
		for i in 9:
			var y := -8.5 + 2.2 * i
			if absf(y) < 1.4:
				continue
			spots.append(Vector2(x, y))
	for i in spots.size():
		spots[i] += Vector2(_jitter(i * 2), _jitter(i * 2 + 1))
	return spots


static func _jitter(n: int) -> float:
	return (float((n * 37 + 11) % 7) / 6.0 - 0.5) * 0.6


static func _add(out: Array[Dictionary], rect: Rect2, height: float, kind: Structure.Kind, role: StringName) -> void:
	out.append({"rect": rect, "height": height, "kind": kind, "role": role})
