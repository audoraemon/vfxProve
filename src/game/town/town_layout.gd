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
## The market fountain at the crossroads (built after the Citadel so every other building keeps its seed).
const FOUNTAIN := Rect2(-0.6, -0.6, 1.2, 1.2)
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
## Residential blocks (north-west, south-west, south-middle, south-east), each a loose grid of cottages with room
## between them for trees and gardens (see houses()): [rect, columns, rows]. The southern blocks stop short of the
## south wall, leaving a lane inside it.
const DISTRICTS := [
	[Rect2(-8.1, -7.8, 4.9, 6.9), 3, 4], [Rect2(-8.1, 0.9, 4.9, 6.5), 3, 4],
	[Rect2(-2.6, 3.6, 2.0, 2.9), 1, 2], [Rect2(0.7, 3.6, 7.1, 3.8), 4, 3],
]
## A cottage's footprint, turned either way.
const HOUSE_WIDE := Vector2(0.95, 0.75)
const HOUSE_DEEP := Vector2(0.75, 0.95)
## Open ground kept between a cottage and either street.
const STREET_CLEAR := 0.95
## A garden plot's sides (ground units), and the open ground kept between it and either street.
const GARDEN_LONG := 1.0
const GARDEN_SHORT := 0.45
## Gap between a garden and its cottage.
const GARDEN_GAP := 0.18
const GARDEN_STREET_CLEAR := 0.7
## The tavern faces the market across the west street; the blacksmith works against the west wall at the street's
## end. Both are homes too (role &"house"), drawn by their own art (tag).
const TAVERN := Rect2(-5.4, -2.35, 2.1, 1.4)
const SMITHY := Rect2(-8.1, 0.95, 1.5, 1.25)
## Working ground the reference fills with props: tables on the tavern's patio, barrels and crates in the
## blacksmith's yard and in a store at the barracks' west end. People walk round them (see blockers()).
const TAVERN_PATIO := Rect2(-5.25, -0.95, 1.8, 0.42)
const SMITHY_YARD := Rect2(-6.55, 1.05, 0.45, 1.05)
const BARRACKS_STORE := Rect2(3.4, -2.3, 0.45, 1.3)
const YARDS := [TAVERN_PATIO, SMITHY_YARD, BARRACKS_STORE]
const TREE_SIZE := Vector2(0.7, 0.7)
## Trees in town, between the cottages.
const TOWN_TREE := Vector2(0.45, 0.45)
## Street lamps: along both streets at their edges, and round the market.
const LAMPS := [
	Vector2(-7.2, 0.55), Vector2(-5.6, -0.75), Vector2(-3.4, 0.55), Vector2(3.4, -0.75), Vector2(0.55, 3.4), Vector2(-0.75, -3.1),
]


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
		_add(out, r, 50.0, Structure.Kind.KEEP, &"tower")
	for r: Rect2 in SIDE_TOWERS:
		_add(out, r, 46.0, Structure.Kind.KEEP, &"tower")
	_add(out, MAIN_GATE, 34.0, Structure.Kind.GATE, &"gate")
	_add(out, SIDE_GATE, 34.0, Structure.Kind.GATE, &"gate")
	_add(out, TEMPLE, 56.0, Structure.Kind.TEMPLE, &"temple")
	_add(out, BARRACKS, 36.0, Structure.Kind.BARRACKS, &"barracks")
	for r: Rect2 in STALLS:
		_add(out, r, 10.0, Structure.Kind.MARKET_STALL, &"market")
	var house_rects := houses()
	for i in house_rects.size():
		_add(out, house_rects[i], 15.0 + float(i * 7 % 5), Structure.Kind.HOUSE, &"house")
	_add(out, TAVERN, 30.0, Structure.Kind.HOUSE, &"house", &"tavern")
	_add(out, SMITHY, 20.0, Structure.Kind.HOUSE, &"house", &"smithy")
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
	for p: Vector2 in LAMPS:
		_add(out, Rect2(p, Vector2(0.2, 0.2)), 18.0, Structure.Kind.TORCH, &"decor", &"lamp")
	var town_trees := town_trees()
	for i in town_trees.size():
		_add(out, Rect2(town_trees[i], TOWN_TREE), 22.0 + float(i % 3) * 2.0, Structure.Kind.TREE, &"decor")
	return out


## Cottage footprints: one per cell of each district's grid, turned and nudged by a hash so the streets are not a
## chessboard, leaving out the cells the tavern and the blacksmith stand in. 10 + 11 + 2 + 12 = 35 cottages; the
## ground in front of the Main Gate stays open for the crowd that queues there.
static func houses() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var n := 0
	for d: Array in DISTRICTS:
		var r: Rect2 = d[0]
		var cols: int = d[1]
		var rows: int = d[2]
		var cell := Vector2(r.size.x / cols, r.size.y / rows)
		for j in rows:
			for i in cols:
				n += 1
				var c := r.position + cell * Vector2(i + 0.5, j + 0.5)
				var size: Vector2 = HOUSE_WIDE if _unit(n * 3) < 0.55 else HOUSE_DEEP
				var room := (cell - size) * 0.5 - Vector2(0.2, 0.2)
				c += Vector2((_unit(n * 3 + 1) - 0.5) * 2.0 * maxf(room.x, 0.0) * 0.6,
					(_unit(n * 3 + 2) - 0.5) * 2.0 * maxf(room.y, 0.0) * 0.6)
				var h := _off_streets(Rect2(c - size * 0.5, size))
				if h.grow(0.3).intersects(TAVERN) or h.grow(0.3).intersects(SMITHY):
					continue
				var in_yard := false
				for y: Rect2 in YARDS:
					in_yard = in_yard or h.grow(0.3).intersects(y)
				if in_yard:
					continue
				out.append(h)
	return out


## A cottage nudged back from both streets so at least STREET_CLEAR of open ground runs beside each road: with
## less, one grid cell of passage is left and a crowd fleeing to a gate jams in it.
static func _off_streets(h: Rect2) -> Rect2:
	var ns: Rect2 = ROADS[0]
	var ew: Rect2 = ROADS[1]
	if h.grow(STREET_CLEAR).intersects(ns):
		if h.get_center().x < ns.get_center().x:
			h.position.x = minf(h.position.x, ns.position.x - STREET_CLEAR - h.size.x)
		else:
			h.position.x = maxf(h.position.x, ns.end.x + STREET_CLEAR)
	if h.grow(STREET_CLEAR).intersects(ew):
		if h.get_center().y < ew.get_center().y:
			h.position.y = minf(h.position.y, ew.position.y - STREET_CLEAR - h.size.y)
		else:
			h.position.y = maxf(h.position.y, ew.end.y + STREET_CLEAR)
	return h


## Fenced vegetable gardens beside the cottages, as in the reference: a plot along a cottage's south or east side,
## on the block's lawn, kept clear of the streets, the other buildings, the town's trees and each other. They are
## solid to people (WalkGrid stamps them), so decor drawn on them never has anyone walking through its fence.
static func gardens() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var others: Array[Rect2] = houses()
	others.append_array([TAVERN, SMITHY, TEMPLE, BARRACKS])
	for y: Rect2 in YARDS:
		others.append(y)
	var trees: Array[Rect2] = []
	for p in town_trees():
		trees.append(Rect2(p, TOWN_TREE))
	var blocks: Array[Rect2] = []
	for d: Array in DISTRICTS:
		blocks.append((d[0] as Rect2).grow(-0.05))
	var hs := houses()
	for i in hs.size():
		if _unit(i * 11 + 3) > 0.55:
			continue
		var h := hs[i]
		var long_x := minf(h.size.x + 0.2, GARDEN_LONG)
		var long_y := minf(h.size.y + 0.2, GARDEN_LONG)
		# Try the sides facing the camera first (south, east, in a hashed order), where a roof cannot hide the plot.
		var sides := [
			Rect2(Vector2(h.position.x - 0.05, h.end.y + GARDEN_GAP), Vector2(long_x, GARDEN_SHORT)),
			Rect2(Vector2(h.end.x + GARDEN_GAP, h.position.y - 0.05), Vector2(GARDEN_SHORT, long_y)),
			Rect2(Vector2(h.position.x - 0.05, h.position.y - GARDEN_GAP - GARDEN_SHORT), Vector2(long_x, GARDEN_SHORT)),
			Rect2(Vector2(h.position.x - GARDEN_GAP - GARDEN_SHORT, h.position.y - 0.05), Vector2(GARDEN_SHORT, long_y)),
		]
		var order := [0, 1, 3, 2] if _unit(i * 11 + 4) < 0.5 else [1, 0, 3, 2]
		for k in 4:
			var plot: Rect2 = sides[order[k]]
			var ok := false
			for bl in blocks:
				ok = ok or bl.encloses(plot)
			for road: Rect2 in ROADS:
				ok = ok and not road.grow(GARDEN_STREET_CLEAR).intersects(plot)
			for o in others:
				ok = ok and not o.grow(0.1).intersects(plot)
			for t in trees:
				ok = ok and not t.intersects(plot)
			for g in out:
				ok = ok and not g.grow(0.45).intersects(plot)
			if ok:
				out.append(plot)
				break
	return out


## Ground people walk round besides the buildings: the gardens and the working yards.
static func blockers() -> Array[Rect2]:
	var out := gardens()
	for y: Rect2 in YARDS:
		out.append(y)
	return out


## Tree spots between the cottages: grid corners inside each district, kept clear of every building and street.
static func town_trees() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var keep_clear: Array[Rect2] = houses()
	keep_clear.append_array([TAVERN, SMITHY, TEMPLE, BARRACKS, BARRACKS_YARD, MARKET_SQUARE, CITADEL_COURT, MAIN_GATE, SIDE_GATE])
	for y: Rect2 in YARDS:
		keep_clear.append(y)
	keep_clear.append_array(CORNER_TOWERS)
	keep_clear.append_array(SIDE_TOWERS)
	keep_clear.append_array(WALLS)
	var n := 0
	for d: Array in DISTRICTS:
		var r: Rect2 = d[0]
		var cols: int = d[1]
		var rows: int = d[2]
		var cell := Vector2(r.size.x / cols, r.size.y / rows)
		for j in rows + 1:
			for i in cols + 1:
				n += 1
				if _unit(n * 5 + 7) > 0.62:
					continue
				var p := r.position + cell * Vector2(i, j) - TOWN_TREE * 0.5
				p += Vector2(_unit(n * 5 + 8) - 0.5, _unit(n * 5 + 9) - 0.5) * 0.3
				var t := Rect2(p, TOWN_TREE)
				if not TOWN.grow(-0.75).encloses(t):
					continue
				var clear := true
				for k in keep_clear:
					if k.grow(0.2).intersects(t):
						clear = false
						break
				for road: Rect2 in ROADS:
					if road.grow(0.25).intersects(t):
						clear = false
				if clear:
					out.append(p)
	return out


## A stable number in [0, 1) for layout variety.
static func _unit(n: int) -> float:
	return float(absi((n * 2654435761) ^ (n * 40503 + 12345)) % 1009) / 1009.0


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


static func _add(out: Array[Dictionary], rect: Rect2, height: float, kind: Structure.Kind, role: StringName,
		tag := &"") -> void:
	out.append({"rect": rect, "height": height, "kind": kind, "role": role, "tag": tag})
