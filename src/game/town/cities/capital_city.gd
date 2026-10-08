class_name CapitalCity
extends CityDef
## The capital: a river-port city about twice Aldermere's size (docs/superpowers/specs/2026-10-09-capital-city-design.md
## §1 and the district plan beside it). This is its geography: the map, the Great River and the harbour basin, the
## three bridges, the two wall rings with their gatehouses, the avenues and lanes, the districts, the exits and the
## dock. Its buildings come later (Task 7): houses(), stalls() and the rest stay empty until then.
##
## Coordinates are ground cells, plan north = -y. The old town's wall ring (INNER) holds the Keep, the noble, civic and
## guild quarters, the Great Market and the old town houses; the river runs between it and the new town's ring
## (OUTER), crossed by two stone bridges and a footbridge, each landing at a gatehouse in both rings.

const MAP := Rect2(-40, -40, 80, 80)
## The Great River, a band across the whole map, and the harbour basin it widens into east of the old town.
const RIVER := Rect2(-40, 6, 80, 6)
const HARBOUR := Rect2(22, -2, 18, 20)
## The two wall rings: the old town's and the new town's.
const INNER := Rect2(-24, -30, 42, 34)
const OUTER := Rect2(-30, 12, 52, 22)
## Wall towers along each run, at these offsets from its middle (ring_wall_towers() leaves out those that would reach
## a corner).
const TOWER_AT := [-16.0, -8.0, 0.0, 8.0, 16.0]
## Where each ring's gatehouses stand (TownLayout.ring_gatehouse()): the old town's west gate, its three river gates at
## the bridges and its harbour gate; the new town's three river gates and the south barbican.
const INNER_GATES := [Vector2(-24, -13), Vector2(-14, 4), Vector2(4, 4), Vector2(14, 4), Vector2(18, -9)]
const OUTER_GATES := [Vector2(-14, 12), Vector2(4, 12), Vector2(14, 12), Vector2(7, 34)]
## The bridges, gate to gate across the river: the two stone bridges (bridge_stone's own 2.0 x 7.6 footprint) and the
## footbridge, laid as FOOTBRIDGE_SPANS lengths of the gpt_footbridge set (a set about two cells long) end to end.
const BRIDGES := [Rect2(-15, 4.2, 2.0, 7.6), Rect2(3, 4.2, 2.0, 7.6)]
const FOOTBRIDGE := Rect2(13.5, 4.2, 1.0, 7.6)
const FOOTBRIDGE_SPANS := 4
const BRIDGE_H := 6.0
## The harbour's ferry pier, out from the basin's north quay (a structure people walk onto, as Aldermere's dock), the
## quay where people wait for the ferry, and the ferry's landing: reaching it is an escape by water.
const DOCK := Rect2(29.5, -2.4, 3.0, 1.0)
const DOCK_H := 3.0
const DOCK_WAIT := Rect2(28.7, -5.6, 4.6, 3.0)
const FERRY_LANDING := Vector2(31.0, -2.9)
## The Citadel (Town builds one per city, citadel.gd) stands on the Royal Keep's hill, its paved court round it as
## at Aldermere (the same offsets from its origin).
const CITADEL_ORIGIN := Vector2(0, -25.5)
const CITADEL_COURT := Rect2(-2.9, -28.0, 5.8, 5.0)
## The Great Market's open square (the stalls come in Task 7), west of the old town houses and clear of the avenues.
const MARKET_SQUARE := Rect2(-21, -7, 15, 6)
## Avenues (2 cells wide) and lanes (1 cell), as axis-aligned polylines: roads() turns each segment into a street rect.
const AVENUE_W := 2.0
const LANE_W := 1.0
const AVENUES := [
	# The south road: from the map's south edge through the barbican, over the east stone bridge, up to the Keep.
	[Vector2(7, 40), Vector2(7, 27), Vector2(4, 27), Vector2(4, -21)],
	# The west road: from the map's west edge through the west gate to the cathedral square.
	[Vector2(-40, -13), Vector2(4, -13)],
	# The cross avenue between the upper quarters and the market and old town, out through the harbour gate.
	[Vector2(-22, -9), Vector2(34, -9)],
	# The west bridge avenue: from the cross avenue through the market, over the west stone bridge, into the new town.
	[Vector2(-14, -9), Vector2(-14, 22)],
	# The new town's avenue, between its upper and lower quarters.
	[Vector2(-28, 22), Vector2(20, 22)],
]
const LANES := [
	# Over the footbridge, from the cross avenue to the new town avenue.
	[Vector2(14, -9), Vector2(14, 22)],
	# From the cross avenue down to the harbour's ferry quay.
	[Vector2(31, -9), Vector2(31, -3)],
	# Between the cathedral square and the guild quarter; between the market and the old town houses.
	[Vector2(8, -20), Vector2(8, -9)],
	[Vector2(-2, -9), Vector2(-2, 2)],
	# The new town's quarter lanes, and the lane between the poor quarter and the road quarter.
	[Vector2(-8, 13.5), Vector2(-8, 21)],
	[Vector2(10, 13.5), Vector2(10, 21)],
	[Vector2(-4, 23), Vector2(-4, 32.5)],
]
## Every area of the district plan (spec §1): name, rect, kind. &"old_town" lies in the old town's wall ring,
## &"new_town" in the new town's, &"outside" beyond both.
const DISTRICT_TABLE := [
	[&"royal_keep", Rect2(-8, -30, 16, 9), &"old_town"],
	[&"noble_quarter", Rect2(-24, -21, 15, 12), &"old_town"],
	[&"cathedral_square", Rect2(-9, -21, 17, 12), &"old_town"],
	[&"guild_quarter", Rect2(8, -21, 10, 12), &"old_town"],
	[&"great_market", Rect2(-24, -9, 22, 13), &"old_town"],
	[&"old_town_houses", Rect2(-2, -9, 20, 13), &"old_town"],
	[&"harbour_district", Rect2(18, -22, 22, 20), &"outside"],
	[&"crafts_quarter", Rect2(-30, 12, 22, 10), &"new_town"],
	[&"new_town", Rect2(-8, 12, 18, 10), &"new_town"],
	[&"tanners_dyers", Rect2(10, 12, 12, 10), &"new_town"],
	[&"poor_quarter", Rect2(-30, 22, 26, 12), &"new_town"],
	[&"road_quarter", Rect2(-4, 22, 26, 12), &"new_town"],
	[&"monastery_hill", Rect2(-40, -40, 16, 28), &"outside"],
	[&"northern_woods", Rect2(14, -40, 26, 18), &"outside"],
	[&"west_farms", Rect2(-40, 12, 10, 28), &"outside"],
	[&"south_east_fields", Rect2(22, 18, 18, 22), &"outside"],
	[&"suburbs", Rect2(-30, 34, 36, 6), &"outside"],
	[&"tournament_field", Rect2(6, 34, 16, 6), &"outside"],
]
## A house block narrower than this either way is left as street.
const BLOCK_MIN := 1.0
## How deep the cobbled queue ground inside each gatehouse is, and its gap from the gate towers.
const GATE_PLAZA := Vector2(3.6, 2.6)
const GATE_PLAZA_GAP := 0.6


func id() -> StringName:
	return &"capital"


func map() -> Rect2:
	return MAP


## The old town's wall ring: the walled core the crowd's patrols and the floor's cobbles keep to.
func town() -> Rect2:
	return INNER


func rivers() -> Array[Rect2]:
	return [RIVER, HARBOUR]


## Every avenue's and lane's segments as street rects, each segment grown by half its width at both ends so the
## corners join, and cut to the map.
func roads() -> Array:
	var out: Array = []
	for line: Array in AVENUES:
		_segments(out, line, AVENUE_W)
	for line: Array in LANES:
		_segments(out, line, LANE_W)
	return out


## The road polylines themselves: {points, width}, avenues first.
func road_lines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line: Array in AVENUES:
		out.append({"points": line.duplicate(), "width": AVENUE_W})
	for line: Array in LANES:
		out.append({"points": line.duplicate(), "width": LANE_W})
	return out


## Where an escape ends: the south road and the west road at the map's edge, and the harbour's ferry landing.
func exits() -> Array[Vector2]:
	return [Vector2(7, 39.6), Vector2(-39.6, -13), FERRY_LANDING]


## The house blocks, as Aldermere's districts are: each walled district of the plan (district_table(), spec §1) less
## its streets, in DISTRICT_TABLE order; slivers under BLOCK_MIN across are left as street. The floor paints them as
## worn ground between the cobbled streets, and the alarms count a local emergency per block.
func districts() -> Array:
	var streets := roads()
	var out: Array = []
	for row: Array in DISTRICT_TABLE:
		if row[2] == &"outside":
			continue
		var pieces: Array[Rect2] = [row[1]]
		for road: Rect2 in streets:
			var next: Array[Rect2] = []
			for r: Rect2 in pieces:
				next.append_array(_minus(r, road))
			pieces = next
		for r: Rect2 in pieces:
			if r.size.x >= BLOCK_MIN and r.size.y >= BLOCK_MIN:
				out.append(r)
	return out


## Every area of the district plan: {name, rect, kind}.
func district_table() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Array in DISTRICT_TABLE:
		out.append({"name": row[0], "rect": row[1], "kind": row[2]})
	return out


## The walls, towers and gatehouses of both rings (old town first), then the bridges and the dock.
func structures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var streets := roads()
	for ring: Array in _rings():
		var g := _gatehouses(ring[0], ring[1])
		out.append_array(TownLayout.ring_structures(ring[0], streets, g.towers, g.gates, TOWER_AT))
	for r: Rect2 in BRIDGES:
		out.append({"rect": r, "height": BRIDGE_H, "kind": Structure.Kind.BRIDGE, "role": &"bridge", "tag": &"stone"})
	var span := FOOTBRIDGE.size.y / FOOTBRIDGE_SPANS
	for k in FOOTBRIDGE_SPANS:
		out.append({"rect": Rect2(FOOTBRIDGE.position.x, FOOTBRIDGE.position.y + span * k, FOOTBRIDGE.size.x, span),
			"height": BRIDGE_H, "kind": Structure.Kind.BRIDGE, "role": &"bridge", "tag": &"gpt_footbridge"})
	out.append({"rect": DOCK, "height": DOCK_H, "kind": Structure.Kind.BRIDGE, "role": &"dock", "tag": &"dock"})
	return out


## The keys every city's anchors have, empty until the capital's buildings land (Task 7), but for the open squares:
## the market square's and each gate plaza's four quarter points, as Aldermere's "plaza" anchors.
func anchors() -> Dictionary:
	var out := {"home": [], "stall": [], "craft": [], "tavern": [], "cathedral": [], "plaza": [], "water": [],
		"field": [], "mill": [], "dock": [], "barn": [], "bell": []}
	var squares: Array[Rect2] = [MARKET_SQUARE]
	squares.append_array(gate_plazas())
	for pl: Rect2 in squares:
		for k in 4:
			out.plaza.append(pl.position + pl.size * Vector2(0.25 + 0.5 * (k % 2), 0.25 + 0.5 * (k / 2)))
	out.dock.append(Vector2(DOCK.get_center().x, DOCK.position.y - 0.4))
	return out


## Torch posts: the market square's four corners first (TownDecor strings bunting between them), then two inside
## every gatehouse, as at Aldermere's gates.
func torches() -> Array[Vector2]:
	var m := MARKET_SQUARE
	var out: Array[Vector2] = [m.position - Vector2(0.3, 0.3), Vector2(m.end.x + 0.1, m.position.y - 0.3),
		Vector2(m.position.x - 0.3, m.end.y + 0.1), m.end + Vector2(0.1, 0.1)]
	for ring: Array in _rings():
		for at: Vector2 in ring[1]:
			var inward := _inward(ring[0], at)
			var mid := _wall_mid(ring[0], at)
			if inward.y != 0.0:
				out.append(Vector2(mid.x - 1.4, mid.y + inward.y * 1.25))
				out.append(Vector2(mid.x + 1.2, mid.y + inward.y * 1.25))
			else:
				out.append(Vector2(mid.x + inward.x * 1.25, mid.y - 1.4))
				out.append(Vector2(mid.x + inward.x * 1.25, mid.y + 1.2))
	return out


## The cobbled queue ground inside each gatehouse, in gate order (old town's gates, then the new town's).
func gate_plazas() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var off := WALL_TOWER_HALF + GATE_PLAZA_GAP
	for ring: Array in _rings():
		for at: Vector2 in ring[1]:
			var inward := _inward(ring[0], at)
			var mid := _wall_mid(ring[0], at)
			if inward.y != 0.0:
				var y0 := mid.y + off if inward.y > 0.0 else mid.y - off - GATE_PLAZA.y
				out.append(Rect2(mid.x - GATE_PLAZA.x * 0.5, y0, GATE_PLAZA.x, GATE_PLAZA.y))
			else:
				var x0 := mid.x + off if inward.x > 0.0 else mid.x - off - GATE_PLAZA.y
				out.append(Rect2(x0, mid.y - GATE_PLAZA.x * 0.5, GATE_PLAZA.y, GATE_PLAZA.x))
	return out


func citadel_origin() -> Vector2:
	return CITADEL_ORIGIN


func landmark(name: StringName) -> Rect2:
	var gates := {}
	for ring: Array in _rings():
		var g := _gatehouses(ring[0], ring[1])
		gates[ring[0]] = g.gates
	match name:
		&"river":
			return RIVER
		&"harbour":
			return HARBOUR
		&"bridge":
			return BRIDGES[1]
		&"footbridge":
			return FOOTBRIDGE
		&"dock":
			return DOCK
		&"dock_wait":
			return DOCK_WAIT
		&"market_square":
			return MARKET_SQUARE
		&"citadel_court":
			return CITADEL_COURT
		&"old_town_wall":
			return INNER
		&"new_town_wall":
			return OUTER
		&"west_gate":
			return gates[INNER][0]
		&"harbour_gate":
			return gates[INNER][4]
		&"barbican", &"main_gate":
			return gates[OUTER][3]
	for row: Array in DISTRICT_TABLE:
		if row[0] == name:
			return row[1]
	return Rect2()


func floor_areas() -> Dictionary:
	var none: Array[Rect2] = []
	var plazas: Array[Rect2] = [MARKET_SQUARE, CITADEL_COURT]
	return {
		&"plazas": plazas, &"yards": none.duplicate(), &"gate_plazas": gate_plazas(),
		&"building_yards": none.duplicate(), &"farm": none.duplicate(),
		&"paved": [OUTER.grow(-TownLayout.WALL_T)] as Array[Rect2],
	}


# --- Helpers ---------------------------------------------------------------------------------------------

const WALL_TOWER_HALF := TownLayout.WALL_TOWER * 0.5


## Each ring with its gate points: [rect, gate points].
func _rings() -> Array:
	return [[INNER, INNER_GATES], [OUTER, OUTER_GATES]]


## The ring's gatehouses at `points`: {gates, towers}, both Array[Rect2], the towers in gate order.
func _gatehouses(ring: Rect2, points: Array) -> Dictionary:
	var gates: Array[Rect2] = []
	var towers: Array[Rect2] = []
	for at: Vector2 in points:
		var g := TownLayout.ring_gatehouse(ring, at)
		gates.append(g.gate)
		towers.append_array(g.towers)
	return {"gates": gates, "towers": towers}


## The middle of the ring's wall band at the gate point `at` (on the side nearest it).
func _wall_mid(ring: Rect2, at: Vector2) -> Vector2:
	var g: Rect2 = TownLayout.ring_gatehouse(ring, at).gate
	return g.get_center()


## The unit step from the gate at `at` into the ring.
func _inward(ring: Rect2, at: Vector2) -> Vector2:
	var g: Rect2 = TownLayout.ring_gatehouse(ring, at).gate
	if g.size.x > g.size.y:
		return Vector2(0.0, 1.0 if g.get_center().y < ring.get_center().y else -1.0)
	return Vector2(1.0 if g.get_center().x < ring.get_center().x else -1.0, 0.0)


## `r` less `cut`: up to four rects (the strips above and below the cut across r's width, then those left and right of
## it); `r` itself when they do not meet.
static func _minus(r: Rect2, cut: Rect2) -> Array[Rect2]:
	if not r.intersects(cut):
		return [r]
	var out: Array[Rect2] = []
	var c := r.intersection(cut)
	if c.position.y > r.position.y:
		out.append(Rect2(r.position.x, r.position.y, r.size.x, c.position.y - r.position.y))
	if c.end.y < r.end.y:
		out.append(Rect2(r.position.x, c.end.y, r.size.x, r.end.y - c.end.y))
	if c.position.x > r.position.x:
		out.append(Rect2(r.position.x, c.position.y, c.position.x - r.position.x, c.size.y))
	if c.end.x < r.end.x:
		out.append(Rect2(c.end.x, c.position.y, r.end.x - c.end.x, c.size.y))
	return out


## Appends the polyline's segments as street rects `width` wide.
func _segments(out: Array, line: Array, width: float) -> void:
	for k in line.size() - 1:
		var a: Vector2 = line[k]
		var b: Vector2 = line[k + 1]
		var r := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs()).grow(width * 0.5)
		out.append(r.intersection(MAP))
