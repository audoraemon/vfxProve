class_name TownDecor
extends RefCounted
## Where Aldermere's decor goes, as pure data: {kind, at, size, seed, bake}. Deterministic.
## - Inside the walls it only stands where people already cannot walk: on walk-grid cells a building blocks,
##   hugging houses, the Temple and the barracks.
## - Outside it keeps at least ROAD_CLEAR from the roads and both exits, and out of the river, the fields and the
##   trails.
## - `bake` marks pieces that neither a building nor a person can ever overlap on screen (the open meadow and
##   forest). The floor paints those into its texture; the rest become live Decor nodes that sort with everyone.

## Cell size and body margin the walk grid blocks buildings by (WalkGrid.CELL, WalkGrid.BODY).
const CELL := 0.5
const BODY := 0.15
const ROAD_CLEAR := 1.0
## How far from a road (and exit) a piece has to be before it can be baked into the floor.
const BAKE_CLEAR := 1.4
const SEED := 5171
## A generous screen box around any decor piece (relative to its ground point): tall enough for a tree.
const SCREEN_BOX := Rect2(-26, -66, 52, 68)


static func spots() -> Array[Dictionary]:
	var solid := _solid_rects()
	var out: Array[Dictionary] = []
	_yards(out)
	_houses(out, solid)
	_market(out)
	_countryside(out)
	_outside(out, solid)
	var boxes := _screen_boxes()
	for d in out:
		d.bake = _bakeable(d, boxes)
	return out


## Footprints that block walking: every standing non-walkable building, the Citadel's parts and the fountain.
static func _solid_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d in TownLayout.structures():
		if not d.kind in Structure.WALKABLE:
			out.append(d.rect)
	for r: Rect2 in Citadel.TOWERS + Citadel.WALLS + [Citadel.KEEP]:
		out.append(Rect2(r.position + TownLayout.CITADEL_ORIGIN, r.size))
	for f: Rect2 in TownLayout.FOUNTAINS:
		out.append(f)
	# Gardens and yards close every cell they touch (WalkGrid): grown so that, with blocked()'s own BODY, they reach
	# half a cell.
	for g in TownLayout.blockers():
		out.append(g.grow(CELL * 0.5 - BODY))
	return out


## The walk grid's rule: a cell is solid when its centre lies in a footprint grown by a body's width.
static func blocked(g: Vector2, solid: Array[Rect2]) -> bool:
	var c := (Vector2(floorf(g.x / CELL), floorf(g.y / CELL)) + Vector2(0.5, 0.5)) * CELL
	for r in solid:
		if r.grow(BODY).has_point(c):
			return true
	return false


static func _inside_any(g: Vector2, solid: Array[Rect2], margin := 0.02) -> bool:
	for r in solid:
		if r.grow(margin).has_point(g):
			return true
	return false


static func _h(i: int, salt: int) -> float:
	return ArtKit.hash01(SEED + i * 131, salt)


static func _add(out: Array[Dictionary], kind: Decor.Kind, at: Vector2, size := Vector2.ZERO) -> void:
	out.append({"kind": kind, "at": at, "size": size, "seed": SEED + out.size() * 7919, "bake": false})


static func _far_from_others(out: Array[Dictionary], g: Vector2, d: float) -> bool:
	for o in out:
		if (o.at as Vector2).distance_to(g) < d:
			return false
	return true


# --- Inside the walls ------------------------------------------------------------------

## The working yards: tables and benches on the tavern's patio, barrels and crates in the blacksmith's yard.
static func _yards(out: Array[Dictionary]) -> void:
	var p: Rect2 = TownLayout.TAVERN_PATIO
	_add(out, Decor.Kind.TABLE, p.position + Vector2(0.45, 0.22))
	_add(out, Decor.Kind.TABLE, p.position + Vector2(1.3, 0.22))
	_add(out, Decor.Kind.BARREL, p.position + Vector2(1.72, 0.12))
	var y: Rect2 = TownLayout.SMITHY_YARD
	_add(out, Decor.Kind.BARREL, y.position + Vector2(0.2, 0.22))
	_add(out, Decor.Kind.CRATES, y.position + Vector2(0.72, 0.4))
	_add(out, Decor.Kind.BARREL, y.position + Vector2(1.12, 0.22))


## Trees behind the houses; barrels, crates, flowers, bushes and lamps against the houses, the Temple, the barracks,
## the tavern and the blacksmith; and small gardens.
static func _houses(out: Array[Dictionary], solid: Array[Rect2]) -> void:
	var hosts: Array[Rect2] = TownLayout.houses()
	hosts.append_array([TownLayout.TEMPLE, TownLayout.BARRACKS, TownLayout.SMITHY, TownLayout.WORKSHOP])
	# Crates, barrels and baskets pile up round the market stalls too.
	for st: Rect2 in TownLayout.STALLS:
		hosts.append(st)
	for t: Rect2 in TownLayout.TAVERNS:
		hosts.append(t)
	for i in hosts.size():
		var r := hosts[i]
		var placed := 0
		# A tree behind the house (its north or west side), its crown showing over the roof as in the reference.
		var back := Vector2(r.get_center().x, r.position.y - 0.12) if _h(i, 3) < 0.5 \
			else Vector2(r.position.x - 0.12, r.get_center().y)
		if _h(i, 4) < 0.85 and blocked(back, solid) and not _inside_any(back, solid) and _far_from_others(out, back, 0.5):
			_add(out, Decor.Kind.OAK if _h(i, 5) < 0.75 else Decor.Kind.PINE, back, Vector2(24.0 + _h(i, 6) * 8.0, 0.0))
		var sides := [
			[Vector2(r.position.x, r.end.y + 0.1), Vector2(r.end.x, r.end.y + 0.1)],
			[Vector2(r.end.x + 0.1, r.position.y), Vector2(r.end.x + 0.1, r.end.y)],
			[Vector2(r.position.x, r.position.y - 0.1), Vector2(r.end.x, r.position.y - 0.1)],
			[Vector2(r.position.x - 0.1, r.position.y), Vector2(r.position.x - 0.1, r.end.y)],
		]
		for sd in sides.size():
			for t in [0.2, 0.8]:
				if placed >= 3:
					break
				var g: Vector2 = (sides[sd][0] as Vector2).lerp(sides[sd][1], t)
				if not blocked(g, solid) or _inside_any(g, solid) or not _far_from_others(out, g, 0.35):
					continue
				var roll := _h(i * 8 + sd * 2 + int(t * 2.0), 1)
				var kind := Decor.Kind.BARREL
				if roll < 0.38:
					kind = Decor.Kind.BARREL
				elif roll < 0.62:
					kind = Decor.Kind.CRATES
				elif roll < 0.78:
					kind = Decor.Kind.FLOWERS
				elif roll < 0.92:
					kind = Decor.Kind.BUSH
				else:
					kind = Decor.Kind.LAMP
				_add(out, kind, g)
				placed += 1
	for g in TownLayout.gardens():
		_add(out, Decor.Kind.GARDEN, g.position, g.size)


## Bunting strung between the market's torch posts, across its north and south edges.
static func _market(out: Array[Dictionary]) -> void:
	var t: Array = TownLayout.TORCHES
	var pairs := [[t[0], t[1]], [t[2], t[3]]]
	for pr in pairs:
		# Tied to the facing sides of the two posts: the cells the posts block, but not inside them.
		var a: Vector2 = pr[0] + Vector2(0.25, 0.1)
		var b: Vector2 = pr[1] + Vector2(-0.05, 0.1)
		_add(out, Decor.Kind.BUNTING, a, b - a)


# --- Outside the walls ------------------------------------------------------------------

static func _outside(out: Array[Dictionary], solid: Array[Rect2]) -> void:
	var area := TownLayout.MAP.grow(-0.5)
	# Trees on a jittered grid: thick in the forest, scattered in the meadow.
	_scatter(out, solid, area, 1.05, 10, func(g: Vector2, roll: float, i: int) -> int:
		var forest := _forest(g)
		if roll > (0.45 if forest else 0.12):
			return -1
		var pine := _h(i, 11) < (0.6 if forest else 0.25)
		return Decor.Kind.PINE if pine else Decor.Kind.OAK)
	_scatter(out, solid, area, 2.0, 20, func(_g: Vector2, roll: float, _i: int) -> int:
		return Decor.Kind.ROCK if roll < 0.32 else -1)
	_scatter(out, solid, area, 1.6, 30, func(_g: Vector2, roll: float, _i: int) -> int:
		return Decor.Kind.BUSH if roll < 0.28 else -1)
	_scatter(out, solid, area, 1.3, 40, func(g: Vector2, roll: float, _i: int) -> int:
		return Decor.Kind.FLOWERS if roll < 0.3 and not _forest(g) else -1)
	# Reeds along both banks of the south river and the west branch's east bank, clear of the road and the bridge.
	var river := TownLayout.RIVER
	var west := TownLayout.RIVER_WEST
	var i := 0
	for bank_y in [river.position.y - 0.28, river.end.y + 0.3]:
		var x := area.position.x
		while x < area.end.x:
			var g := Vector2(x + _h(i, 50) * 0.3, bank_y + (_h(i, 51) - 0.5) * 0.12)
			if _h(i, 52) < 0.9 and _outside_ok(g, solid, 0.25):
				_add(out, Decor.Kind.REEDS, g)
			x += 0.32
			i += 1
	var y := west.position.y
	while y < river.position.y:
		var g := Vector2(west.end.x + 0.3 + (_h(i, 51) - 0.5) * 0.12, y + _h(i, 50) * 0.3)
		if _h(i, 52) < 0.9 and _outside_ok(g, solid, 0.25):
			_add(out, Decor.Kind.REEDS, g)
		y += 0.32
		i += 1
	# Short fence runs beside the trails.
	for tr: Array in TownFloor.TRAILS:
		for k in tr.size() - 1:
			var a: Vector2 = tr[k]
			var b: Vector2 = tr[k + 1]
			var along := (b - a).normalized()
			var side := Vector2(-along.y, along.x) * (0.62 if _h(k + i, 60) < 0.5 else -0.62)
			var start := a.lerp(b, 0.3) + side
			var run := along * 1.3
			i += 1
			if _h(k * 7 + i, 61) < 0.55 and _outside_ok(start, solid, 0.2) and _outside_ok(start + run, solid, 0.2) \
					and _outside_ok(start + run * 0.5, solid, 0.2):
				_add(out, Decor.Kind.FENCE, start, run)
	for g in [Vector2(-16.0, -24.0), Vector2(2.5, -24.0), Vector2(8.5, 28.9), Vector2(-14.5, 28.9)]:
		if _outside_ok(g, solid, 0.0, false):
			_add(out, Decor.Kind.SCARECROW, g)
	for g in [Vector2(21.0, 10.9), Vector2(4.6, 27.0)]:
		if _outside_ok(g, solid, 0.0):
			_add(out, Decor.Kind.SIGNPOST, g)


## The Scale reference's countryside: the dock with the ship moored at it and rowing boats on the rivers, fenced
## pastures with sheep and cows, and carts by the farms.
static func _countryside(out: Array[Dictionary]) -> void:
	var d: Rect2 = TownLayout.DOCK
	_add(out, Decor.Kind.DOCK, d.position, d.size)
	_add(out, Decor.Kind.SHIP, Vector2(-4.3, 22.3))
	for g in [Vector2(-11.0, 21.4), Vector2(7.8, 22.6), Vector2(-20.5, 22.0), Vector2(-28.2, 9.0), Vector2(14.0, 21.2)]:
		_add(out, Decor.Kind.BOAT, g)
	var n := 0
	for p: Rect2 in TownLayout.PASTURES:
		# Fences on all four sides, with a gap for a gate on the side facing the camera.
		var gl := Vector2(p.position.x, p.end.y)
		var gr := Vector2(p.end.x, p.position.y)
		_add(out, Decor.Kind.FENCE, p.position, gr - p.position)
		_add(out, Decor.Kind.FENCE, p.position, gl - p.position)
		_add(out, Decor.Kind.FENCE, gr, p.end - gr)
		var gate := gl.lerp(p.end, 0.45)
		_add(out, Decor.Kind.FENCE, gl, gate - gl)
		_add(out, Decor.Kind.FENCE, gate + (p.end - gl).normalized() * 1.0, p.end - gate - (p.end - gl).normalized() * 1.0)
		# One animal to each cell of a 3 x 3 grid, jittered inside its cell, so no two stand on each other.
		var cell := (p.size - Vector2(1.2, 1.2)) / 3.0
		for i in 9:
			n += 1
			var at := p.position + Vector2(0.6, 0.6) + cell * Vector2(float(i % 3) + 0.2 + _h(n, 70) * 0.6,
				floorf(i / 3.0) + 0.2 + _h(n, 71) * 0.6)
			var cow := n % 3 == 0 and p.position.x > 0.0
			_add(out, Decor.Kind.COW if cow else Decor.Kind.SHEEP, at)
	for g in [Vector2(-1.0, 27.6), Vector2(22.0, 12.6), Vector2(-15.5, -21.5)]:
		_add(out, Decor.Kind.CART, g)


## Points on a jittered grid over `area`; `pick` turns (point, roll, index) into a kind, or -1 to skip.
static func _scatter(out: Array[Dictionary], solid: Array[Rect2], area: Rect2, step: float, salt: int,
		pick: Callable) -> void:
	var nx := int(area.size.x / step)
	var ny := int(area.size.y / step)
	for j in ny:
		for i in nx:
			var n := j * 1000 + i
			var g := area.position + Vector2((i + 0.2 + _h(n, salt) * 0.6) * step, (j + 0.2 + _h(n, salt + 1) * 0.6) * step)
			var kind: int = pick.call(g, _h(n, salt + 2), n)
			if kind < 0 or not _outside_ok(g, solid, 0.45):
				continue
			if not _far_from_others(out, g, 0.55):
				continue
			_add(out, kind, g)


## Outside the walls, off the roads, the exits, the rivers and the fields' tilled ground, clear of trails (by
## `trail_gap`) and of every building. `farm` false lets a piece stand on a field's tilled edge (the scarecrows).
static func _outside_ok(g: Vector2, solid: Array[Rect2], trail_gap: float, farm := true) -> bool:
	if TownLayout.TOWN.grow(0.9).has_point(g):
		return false
	for r: Rect2 in TownLayout.RIVERS:
		if r.grow(0.12).has_point(g):
			return false
	for f: Rect2 in TownLayout.FIELDS:
		if f.grow(0.5 if farm else 0.1).has_point(g):
			return false
	for road: Rect2 in TownLayout.ROADS:
		if road.grow(ROAD_CLEAR).has_point(g):
			return false
	for ex: Vector2 in TownLayout.EXITS:
		if g.distance_to(ex) < ROAD_CLEAR:
			return false
	if TownLayout.BRIDGE.grow(0.4).has_point(g):
		return false
	for p: Rect2 in TownLayout.PASTURES + [TownLayout.DOCK.grow(0.6)]:
		if p.grow(0.3).has_point(g):
			return false
	if _inside_any(g, solid, 0.45):
		return false
	for tr: Array in TownFloor.TRAILS:
		if trail_gap > 0.0 and TownFloor._near_polyline(g, tr, trail_gap):
			return false
	return true


## The floor's forest ring round the walls, repeated without its noisy edge (a tree thinning out at the forest's
## rim is fine).
static func _forest(g: Vector2) -> bool:
	if g.y > TownLayout.RIVER.position.y:
		return false
	var t := TownLayout.TOWN
	if (g.x > t.end.x and absf(g.y - 9.0) < 1.5) or (g.y > t.end.y and absf(g.x - 2.7) < 1.5):
		return false
	var out := maxf(maxf(t.position.x - g.x, g.x - t.end.x), maxf(t.position.y - g.y, g.y - t.end.y))
	return out > 2.2 and out < 7.0


# --- Baking ------------------------------------------------------------------

## Every building's screen box (raised by its height and a roof), for the bake test.
static func _screen_boxes() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d in TownLayout.structures():
		out.append(Person._screen_box(d.rect, d.height))
	return out


## Bakeable: outside the walls, well clear of the roads and exits, and overlapping no building on screen.
static func _bakeable(d: Dictionary, boxes: Array[Rect2]) -> bool:
	var g: Vector2 = d.at
	if TownLayout.TOWN.grow(1.0).has_point(g) or d.kind in [Decor.Kind.BUNTING, Decor.Kind.LAMP]:
		return false
	for road: Rect2 in TownLayout.ROADS:
		if road.grow(BAKE_CLEAR).has_point(g):
			return false
	for ex: Vector2 in TownLayout.EXITS:
		if g.distance_to(ex) < BAKE_CLEAR:
			return false
	var mine := Rect2(Iso.ground_to_screen(g) + SCREEN_BOX.position, SCREEN_BOX.size)
	if d.kind == Decor.Kind.FENCE:
		mine = mine.merge(Rect2(Iso.ground_to_screen(g + (d.size as Vector2)) + SCREEN_BOX.position, SCREEN_BOX.size))
	for b in boxes:
		if b.intersects(mine):
			return false
	return true
