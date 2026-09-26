class_name TownLayout
extends RefCounted
## Aldermere as pure data in ground units, laid out after concepts/TOWN REF/Town Visual and Scale Upgrade.png (the
## town scale upgrade): origin at the town centre, plan north = -y (on screen the north corner is the top, the Main
## Gate is on the lower-left wall and the Side Gate on the lower-right one). Town builds it; the Citadel's nine
## parts live in citadel.gd.
##
## Landmarks sit where the reference has them (read through a homography anchored on its corner towers); the
## Citadel, which the reference does not have, takes the north corner. The reference's walls are not a clean
## square; ours are.

const MAP := Rect2(-30, -30, 60, 60)
## Inside the town walls.
const TOWN := Rect2(-16, -16, 32, 32)
## The river across the south, and its branch up the west side to a waterfall at the map's edge.
const RIVER := Rect2(-30, 20.0, 60, 4.4)
const RIVER_WEST := Rect2(-30, -2.0, 3.6, 22.0)
const RIVERS := [RIVER, RIVER_WEST]
## Wall band thickness, inside TOWN's edge.
const WALL_T := 0.7
## Streets: the main north-south street from the cathedral through the market to the Main Gate; the main east-west
## street from the west wall to the Side Gate; a street along the cathedral's front; two long north-south streets;
## the lane from the Citadel's gate; and outside, the south road over the bridge and the east road.
const ROADS := [
	Rect2(2.0, -4.6, 1.4, 19.9), Rect2(-15.3, 8.3, 30.6, 1.4), Rect2(-15.3, -5.6, 30.6, 1.0),
	Rect2(-6.5, -15.3, 1.0, 30.6), Rect2(9.0, -15.3, 1.0, 30.6), Rect2(-11.0, -8.0, 1.0, 2.4),
	Rect2(2.0, 16.2, 1.4, 13.8), Rect2(16.2, 8.3, 13.8, 1.4),
]
const MARKET_SQUARE := Rect2(-3.5, -3.5, 8.5, 11.5)
## The small plaza round the second fountain, in the north-east.
const FOUNTAIN_PLAZA := Rect2(9.8, -11.6, 3.2, 3.2)
const BARRACKS_YARD := Rect2(10.3, 6.0, 4.5, 2.1)
## The Citadel's ground (its nine parts stay inside) and its paved court, in the north corner.
const CITADEL_ORIGIN := Vector2(-10.5, -10.5)
const CITADEL_AREA := Rect2(-13.25, -12.85, 5.5, 4.7)
const CITADEL_COURT := Rect2(-13.4, -13.0, 5.8, 5.0)
## Reaching one of these means a citizen escaped: the south road and the east road at the map's edge.
const EXITS := [Vector2(2.7, 29.6), Vector2(29.6, 9.0)]

const CORNER_TOWER := 2.0
const WALL_TOWER := 1.6
## Wall towers along each run, at these offsets from its middle (gates keep their own towers).
const TOWER_AT := [-8.0, 0.0, 8.0]
## The gatehouses: a gate between two towers, the Main Gate on the south wall and the Side Gate on the east wall.
const MAIN_GATE := Rect2(1.7, 15.1, 2.0, 1.1)
const SIDE_GATE := Rect2(15.1, 8.0, 1.1, 2.0)
const GATE_TOWERS := [
	Rect2(0.1, 14.9, 1.6, 1.6), Rect2(3.7, 14.9, 1.6, 1.6),
	Rect2(14.9, 6.4, 1.6, 1.6), Rect2(14.9, 10.0, 1.6, 1.6),
]
## Ground in front of each gate kept clear of everything, where the fleeing crowd queues (up to the gatehouse's
## torches).
const GATE_PLAZAS := [Rect2(-0.6, 10.9, 6.6, 3.3), Rect2(10.6, 9.8, 3.6, 3.8)]

## The cathedral, facing the market across the street along its front.
const TEMPLE := Rect2(-1.3, -11.8, 4.2, 6.2)
const BARRACKS := Rect2(10.3, 3.9, 4.4, 1.9)
## The workshop hall and the forge, in the east quarter beside the barracks.
const WORKSHOP := Rect2(10.2, -1.3, 2.6, 1.5)
const SMITHY := Rect2(13.0, -1.6, 1.5, 1.25)
## The taverns: north (by the Citadel's lane), west of the market, and east of the market.
const TAVERNS := [Rect2(-9.6, -7.6, 2.4, 1.5), Rect2(-5.3, -0.6, 1.6, 2.4), Rect2(5.6, 2.4, 2.8, 1.8)]
const TAVERN := Rect2(5.6, 2.4, 2.8, 1.8)
## Working ground the reference fills with props: tables on the east tavern's patio, barrels and crates in the
## blacksmith's yard. People walk round them (see blockers()).
const TAVERN_PATIO := Rect2(5.8, 4.2, 2.4, 0.42)
const SMITHY_YARD := Rect2(13.1, -0.2, 1.3, 0.55)
const YARDS := [TAVERN_PATIO, SMITHY_YARD]
const BRIDGE := Rect2(1.7, 18.4, 2.0, 7.6)
## The market fountain and the north-east plaza's (built after the Citadel so every other building keeps its seed).
const FOUNTAIN := Rect2(0.2, 5.1, 1.2, 1.2)
const FOUNTAINS := [Rect2(0.2, 5.1, 1.2, 1.2), Rect2(10.8, -10.6, 1.2, 1.2)]
## Market stalls in rows west of the main street, a row east of it, and a ring round the fountain.
const STALLS := [
	Rect2(-3.1, -2.8, 0.9, 0.7), Rect2(-1.9, -2.8, 0.9, 0.7), Rect2(-0.7, -2.8, 0.9, 0.7),
	Rect2(-3.1, -0.6, 0.9, 0.7), Rect2(-1.9, -0.6, 0.9, 0.7), Rect2(-0.7, -0.6, 0.9, 0.7),
	Rect2(-3.1, 1.6, 0.9, 0.7), Rect2(-1.9, 1.6, 0.9, 0.7), Rect2(-0.7, 1.6, 0.9, 0.7),
	Rect2(-3.1, 3.8, 0.9, 0.7), Rect2(-1.9, 3.8, 0.9, 0.7), Rect2(-0.7, 3.8, 0.9, 0.7),
	Rect2(3.7, -2.8, 0.9, 0.7), Rect2(3.7, -0.6, 0.9, 0.7), Rect2(3.7, 1.6, 0.9, 0.7), Rect2(3.7, 3.8, 0.9, 0.7),
	Rect2(3.7, 6.0, 0.9, 0.7), Rect2(-3.1, 6.2, 0.9, 0.7), Rect2(-1.9, 6.2, 0.9, 0.7), Rect2(-0.7, 7.1, 0.9, 0.7),
]
## Farm fields outside the walls: north, south of the river, and east.
const FIELDS := [
	Rect2(-24, -28, 5, 3.5), Rect2(-18, -28, 5, 3.5), Rect2(0, -28, 5, 3.5), Rect2(6, -28, 5, 3.5), Rect2(12, -27, 5, 3.5),
	Rect2(-24, 25.9, 5, 3.4), Rect2(-17, 25.9, 5, 3.4), Rect2(6, 25.9, 5, 3.4), Rect2(13, 25.9, 5, 3.4), Rect2(19, 13, 5, 3.5),
]
## The mills: a windmill among the north farms, a watermill on the south bank west of the bridge.
const WINDMILL := Rect2(-11.9, -24.9, 0.9, 0.9)
const WATERMILL := Rect2(-6.9, 25.0, 2.4, 1.9)
## Fenced pastures with sheep and cows: north, and east of the Side Gate's road.
const PASTURES := [Rect2(-9.8, -26.8, 5.8, 5.0), Rect2(18.5, 1.5, 7.0, 5.5)]
## The dock: a pier out from the south bank west of the bridge, where the ship is moored.
const DOCK := Rect2(-2.4, 23.2, 2.8, 1.2)
## Farmhouses by the fields.
const BARNS := [Rect2(-12.5, -28.4, 1.3, 1.5), Rect2(18.0, -26.5, 1.3, 1.5), Rect2(-10.0, 26.2, 1.3, 1.5),
	Rect2(19.5, 17.2, 1.3, 1.5)]
## Torch posts: the market's corners, inside the Main Gate, outside the Side Gate, at the Citadel's gate and the
## cathedral's steps.
const TORCHES := [
	Vector2(-3.8, -3.8), Vector2(5.1, -3.8), Vector2(-3.8, 8.0), Vector2(5.1, 8.0),
	Vector2(1.3, 14.4), Vector2(3.9, 14.4), Vector2(16.8, 7.5), Vector2(16.8, 10.3),
	Vector2(-11.5, -7.6), Vector2(-9.9, -7.9), Vector2(-0.9, -4.3), Vector2(3.6, -4.3),
]
## Street lamps along the streets' edges.
const LAMPS := [
	Vector2(-12.5, 8.0), Vector2(-8.2, 9.8), Vector2(-4.5, 8.0), Vector2(6.8, 9.8), Vector2(13.5, 13.9),
	Vector2(-12.5, -4.4), Vector2(-8.2, -5.8), Vector2(6.8, -4.4), Vector2(12.2, -5.8),
	Vector2(-0.9, 11.2), Vector2(6.3, 11.2), Vector2(-5.3, -11.0), Vector2(-5.3, 3.5), Vector2(10.2, -2.5), Vector2(10.2, 12.5),
]
## Residential blocks between the streets, each filled with a loose grid of cottages (see houses()).
const DISTRICTS := [
	Rect2(-15.2, -15.2, 8.6, 9.5), Rect2(-5.4, -15.2, 4.0, 9.5), Rect2(3.0, -15.2, 5.9, 9.5), Rect2(10.1, -15.2, 5.1, 9.5),
	Rect2(-15.2, -4.5, 8.6, 12.7), Rect2(5.1, -4.5, 3.8, 12.7), Rect2(-15.2, 9.8, 8.6, 5.4), Rect2(-5.4, 9.8, 7.3, 5.4),
	Rect2(3.5, 9.8, 5.4, 5.4), Rect2(10.1, 9.8, 5.1, 5.4),
]
## Grid spacing of the cottages: the reference's cottages stand about 2 units apart.
const HOUSE_CELL := Vector2(1.75, 1.8)
## A cottage's footprint, turned either way.
const HOUSE_WIDE := Vector2(0.95, 0.75)
const HOUSE_DEEP := Vector2(0.75, 0.95)
## Open ground kept between a cottage and any street, and between a cottage and the walls.
const STREET_CLEAR := 0.95
const WALL_CLEAR := 1.0
## A garden plot's sides (ground units), and the open ground kept between it and any street.
const GARDEN_LONG := 1.0
const GARDEN_SHORT := 0.45
## Gap between a garden and its cottage.
const GARDEN_GAP := 0.18
const GARDEN_STREET_CLEAR := 0.7
## The share of cottages that try for a garden.
const GARDEN_CHANCE := 0.85
const TREE_SIZE := Vector2(0.7, 0.7)
## Trees in town, between the cottages, and the share of candidate spots that get one.
const TOWN_TREE := Vector2(0.45, 0.45)
const TOWN_TREE_CHANCE := 0.8


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


## The four corner towers, centred 0.3 inside each corner so they stand mostly out of it.
static func corner_towers() -> Array[Rect2]:
	var h := CORNER_TOWER * 0.5
	var out: Array[Rect2] = []
	for c: Vector2 in [TOWN.position, Vector2(TOWN.end.x, TOWN.position.y), TOWN.end, Vector2(TOWN.position.x, TOWN.end.y)]:
		var centre := c + (TOWN.get_center() - c).sign() * 0.3
		out.append(Rect2(centre - Vector2(h, h), Vector2(CORNER_TOWER, CORNER_TOWER)))
	return out


## Towers along the runs, at TOWER_AT from each run's middle, moved along the wall off any street that ends there,
## and left out where a gatehouse stands.
static func wall_towers() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var h := WALL_TOWER * 0.5
	var mid := WALL_T * 0.5
	for off: float in TOWER_AT:
		for side in 4:
			for nudge: float in [0.0, -1.4, 1.4]:
				var o := off + nudge
				var c: Vector2 = [Vector2(o, TOWN.position.y + mid), Vector2(TOWN.position.x + mid, o),
					Vector2(o, TOWN.end.y - mid), Vector2(TOWN.end.x - mid, o)][side]
				var r := Rect2(c - Vector2(h, h), Vector2(WALL_TOWER, WALL_TOWER))
				var on_road := false
				for road: Rect2 in ROADS:
					on_road = on_road or road.grow(0.3).intersects(r)
				if on_road:
					continue
				var clear := true
				for g: Rect2 in GATE_TOWERS + [MAIN_GATE, SIDE_GATE]:
					clear = clear and not g.grow(0.6).intersects(r)
				if clear:
					out.append(r)
				break
	return out


## The wall runs between the towers and gatehouses: each side's band, less whatever stands on it.
static func walls() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var blocking: Array[Rect2] = corner_towers() + wall_towers()
	for g: Rect2 in GATE_TOWERS + [MAIN_GATE, SIDE_GATE]:
		blocking.append(g)
	var bands := [
		Rect2(TOWN.position.x, TOWN.position.y, TOWN.size.x, WALL_T), Rect2(TOWN.position.x, TOWN.end.y - WALL_T, TOWN.size.x, WALL_T),
		Rect2(TOWN.position.x, TOWN.position.y, WALL_T, TOWN.size.y), Rect2(TOWN.end.x - WALL_T, TOWN.position.y, WALL_T, TOWN.size.y),
	]
	for band: Rect2 in bands:
		var along_x := band.size.x >= band.size.y
		var cuts: Array = []
		for b: Rect2 in blocking:
			if b.intersects(band):
				cuts.append([b.position.x, b.end.x] if along_x else [b.position.y, b.end.y])
		cuts.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
		var at: float = band.position.x if along_x else band.position.y
		var end: float = band.end.x if along_x else band.end.y
		for c: Array in cuts:
			if c[0] - at > 0.05:
				out.append(Rect2(at, band.position.y, c[0] - at, band.size.y) if along_x \
					else Rect2(band.position.x, at, band.size.x, c[0] - at))
			at = maxf(at, c[1])
		if end - at > 0.05:
			out.append(Rect2(at, band.position.y, end - at, band.size.y) if along_x \
				else Rect2(band.position.x, at, band.size.x, end - at))
	return out


## Every building except the Citadel and the fountains, as {rect, height, kind, role, tag}.
static func structures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Rect2 in walls():
		for piece in wall_pieces(r):
			_add(out, piece, 34.0, Structure.Kind.CASTLE_WALL, &"wall")
	for r: Rect2 in corner_towers():
		_add(out, r, 50.0, Structure.Kind.KEEP, &"tower")
	for r: Rect2 in wall_towers():
		_add(out, r, 46.0, Structure.Kind.KEEP, &"tower")
	for r: Rect2 in GATE_TOWERS:
		_add(out, r, 52.0, Structure.Kind.KEEP, &"tower")
	_add(out, MAIN_GATE, 34.0, Structure.Kind.GATE, &"gate")
	_add(out, SIDE_GATE, 34.0, Structure.Kind.GATE, &"gate")
	_add(out, TEMPLE, 56.0, Structure.Kind.TEMPLE, &"temple", &"cathedral")
	_add(out, BARRACKS, 36.0, Structure.Kind.BARRACKS, &"barracks")
	for r: Rect2 in STALLS:
		_add(out, r, 10.0, Structure.Kind.MARKET_STALL, &"market")
	var house_rects := houses()
	for i in house_rects.size():
		_add(out, house_rects[i], 15.0 + float(i * 7 % 5), Structure.Kind.HOUSE, &"house")
	for r: Rect2 in TAVERNS:
		_add(out, r, 30.0, Structure.Kind.HOUSE, &"house", &"tavern")
	_add(out, SMITHY, 20.0, Structure.Kind.HOUSE, &"house", &"smithy")
	_add(out, WORKSHOP, 22.0, Structure.Kind.HOUSE, &"house", &"workshop")
	_add(out, BRIDGE, 6.0, Structure.Kind.BRIDGE, &"bridge", &"stone")
	for r: Rect2 in FIELDS:
		_add(out, r, 3.0, Structure.Kind.FARM_FIELD, &"farm")
	for r: Rect2 in BARNS:
		_add(out, r, 20.0, Structure.Kind.HOUSE, &"farm")
	_add(out, WINDMILL, 60.0, Structure.Kind.HOUSE, &"farm", &"windmill")
	_add(out, WATERMILL, 34.0, Structure.Kind.HOUSE, &"farm", &"watermill")
	var tree_spots := trees()
	for i in tree_spots.size():
		_add(out, Rect2(tree_spots[i], TREE_SIZE), 26.0 + float(i % 3) * 3.0, Structure.Kind.TREE, &"decor")
	for p: Vector2 in TORCHES:
		_add(out, Rect2(p, Vector2(0.2, 0.2)), 16.0, Structure.Kind.TORCH, &"decor")
	for p: Vector2 in LAMPS:
		_add(out, Rect2(p, Vector2(0.2, 0.2)), 18.0, Structure.Kind.TORCH, &"decor", &"lamp")
	var town_trees := town_trees()
	for i in town_trees.size():
		_add(out, Rect2(town_trees[i], TOWN_TREE), 25.0 + float(i % 3) * 2.0, Structure.Kind.TREE, &"decor", &"oak")
	return out


## Everything a cottage must keep clear of: the landmarks, yards, gate plazas and the Citadel's ground.
static func _landmarks() -> Array[Rect2]:
	var out: Array[Rect2] = [TEMPLE, BARRACKS, BARRACKS_YARD, WORKSHOP, SMITHY, MARKET_SQUARE, FOUNTAIN_PLAZA,
		CITADEL_COURT]
	for r: Rect2 in TAVERNS + YARDS + GATE_PLAZAS:
		out.append(r)
	return out


## Cottage footprints: a loose grid in every district at the reference's density, each turned and nudged by a
## hash so the blocks are not a chessboard, kept STREET_CLEAR from every street and WALL_CLEAR inside the walls,
## and left out wherever a landmark, a yard or a gate plaza stands.
static func houses() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var inner := TOWN.grow(-WALL_T - WALL_CLEAR)
	var keep_clear := _landmarks()
	var n := 0
	for d: Rect2 in DISTRICTS:
		var cols := maxi(int(d.size.x / HOUSE_CELL.x), 1)
		var rows := maxi(int(d.size.y / HOUSE_CELL.y), 1)
		var cell := Vector2(d.size.x / cols, d.size.y / rows)
		for j in rows:
			for i in cols:
				n += 1
				var c := d.position + cell * Vector2(i + 0.5, j + 0.5)
				var size: Vector2 = HOUSE_WIDE if _unit(n * 3) < 0.55 else HOUSE_DEEP
				var room := (cell - size) * 0.5 - Vector2(0.25, 0.25)
				c += Vector2((_unit(n * 3 + 1) - 0.5) * 2.0 * maxf(room.x, 0.0) * 0.6,
					(_unit(n * 3 + 2) - 0.5) * 2.0 * maxf(room.y, 0.0) * 0.6)
				var h := _off_streets(Rect2(c - size * 0.5, size))
				if not inner.encloses(h):
					continue
				var clear := true
				for k in keep_clear:
					clear = clear and not h.grow(0.35).intersects(k)
				for road: Rect2 in ROADS:
					clear = clear and not h.grow(0.5).intersects(road)
				if clear:
					out.append(h)
	return out


## A cottage nudged back from every street so at least STREET_CLEAR of open ground runs beside each road: with
## less, one grid cell of passage is left and a crowd fleeing to a gate jams in it.
static func _off_streets(h: Rect2) -> Rect2:
	for road: Rect2 in ROADS:
		if not h.grow(STREET_CLEAR).intersects(road):
			continue
		if road.size.y > road.size.x:
			if h.get_center().x < road.get_center().x:
				h.position.x = minf(h.position.x, road.position.x - STREET_CLEAR - h.size.x)
			else:
				h.position.x = maxf(h.position.x, road.end.x + STREET_CLEAR)
		else:
			if h.get_center().y < road.get_center().y:
				h.position.y = minf(h.position.y, road.position.y - STREET_CLEAR - h.size.y)
			else:
				h.position.y = maxf(h.position.y, road.end.y + STREET_CLEAR)
	return h


## Fenced vegetable gardens beside the cottages, as in the reference: a plot along one of a cottage's sides (those
## facing the camera first), on the block's lawn, kept clear of the streets, the other buildings, the town's trees
## and each other. They are solid to people (WalkGrid stamps them), so decor drawn on them never has anyone
## walking through its fence.
static func gardens() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var others: Array[Rect2] = houses()
	others.append_array(_landmarks())
	others.append(SMITHY)
	var trees: Array[Rect2] = []
	for p in town_trees():
		trees.append(Rect2(p, TOWN_TREE))
	var blocks: Array[Rect2] = []
	for d: Rect2 in DISTRICTS:
		blocks.append(d.grow(-0.05))
	var hs := houses()
	for i in hs.size():
		if _unit(i * 11 + 3) > GARDEN_CHANCE:
			continue
		var h := hs[i]
		var long_x := minf(h.size.x + 0.2, GARDEN_LONG)
		var long_y := minf(h.size.y + 0.2, GARDEN_LONG)
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
	keep_clear.append_array(_landmarks())
	keep_clear.append(SMITHY)
	for r: Rect2 in corner_towers() + wall_towers() + walls():
		keep_clear.append(r)
	for r: Rect2 in GATE_TOWERS + [MAIN_GATE, SIDE_GATE]:
		keep_clear.append(r)
	var n := 0
	for d: Rect2 in DISTRICTS:
		var cols := maxi(int(d.size.x / HOUSE_CELL.x), 1)
		var rows := maxi(int(d.size.y / HOUSE_CELL.y), 1)
		var cell := Vector2(d.size.x / cols, d.size.y / rows)
		# Candidates at every grid corner and half-way along each cell's sides: the reference's blocks are thick
		# with trees between the cottages.
		for j in rows * 2 + 1:
			for i in cols * 2 + 1:
				if i % 2 == 1 and j % 2 == 1:
					continue
				n += 1
				if _unit(n * 5 + 7) > TOWN_TREE_CHANCE:
					continue
				var p := d.position + cell * Vector2(i, j) * 0.5 - TOWN_TREE * 0.5
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
				for o: Vector2 in out:
					if Rect2(o, TOWN_TREE).grow(0.15).intersects(t):
						clear = false
				if clear:
					out.append(p)
	return out


## A stable number in [0, 1) for layout variety.
static func _unit(n: int) -> float:
	return float(absi((n * 2654435761) ^ (n * 40503 + 12345)) % 1009) / 1009.0


## Tree spots (top-left corners) standing just outside the walls, every 2.4 units round the town, leaving the
## roads, the river and the gatehouses clear and nudged a little so the forest edge does not look planted.
static func trees() -> Array[Vector2]:
	var spots: Array[Vector2] = []
	var ring := TOWN.grow(2.2)
	var n := int(ring.size.x / 2.4)
	for i in n + 1:
		var t := float(i) / n
		for p: Vector2 in [Vector2(lerpf(ring.position.x, ring.end.x, t), ring.position.y),
				Vector2(ring.position.x, lerpf(ring.position.y, ring.end.y, t)),
				Vector2(ring.end.x, lerpf(ring.position.y, ring.end.y, t))]:
			spots.append(p)
	var out: Array[Vector2] = []
	for i in spots.size():
		var p := spots[i] + Vector2(_jitter(i * 2), _jitter(i * 2 + 1))
		var t := Rect2(p, TREE_SIZE)
		var clear := true
		for road: Rect2 in ROADS:
			clear = clear and not road.grow(0.8).intersects(t)
		for r: Rect2 in RIVERS:
			clear = clear and not r.grow(0.3).intersects(t)
		for f: Rect2 in FIELDS + BARNS + PASTURES + [WINDMILL, WATERMILL]:
			clear = clear and not f.grow(0.3).intersects(t)
		for o in out:
			clear = clear and o.distance_to(p) > 1.0
		if clear:
			out.append(p)
	return out


static func _jitter(n: int) -> float:
	return (float((n * 37 + 11) % 7) / 6.0 - 0.5) * 0.6


static func _add(out: Array[Dictionary], rect: Rect2, height: float, kind: Structure.Kind, role: StringName,
		tag := &"") -> void:
	out.append({"rect": rect, "height": height, "kind": kind, "role": role, "tag": tag})
