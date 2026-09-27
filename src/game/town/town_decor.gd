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
## Outside the walls: the share of the tree grid's spots that get a tree in the forest ring and in the meadow, the
## forest's share of pines (the reference's woods are mostly round-crowned), and the bush grid's share.
const FOREST_TREES := 0.85
const MEADOW_TREES := 0.2
const FOREST_PINES := 0.35
const BUSHES := 0.45
## A generous screen box around any decor piece (relative to its ground point): tall enough for a tree.
const SCREEN_BOX := Rect2(-26, -66, 52, 68)
## Inside the walls, low decor is painted into the floor (_bake_low()): these kinds, each with the screen box it
## draws in (relative to its ground point; a garden's runs to its far corner as well).
const LOW_BOX := {
	Decor.Kind.FLOWERS: Rect2(-7, -5, 14, 9), Decor.Kind.BUSH: Rect2(-10, -15, 20, 16),
	Decor.Kind.ROCK: Rect2(-14, -14, 28, 18), Decor.Kind.GARDEN: Rect2(-4, -14, 8, 16),
}
## The box other pieces draw in (relative to the ground point), for deciding what may lie under them; GOODS_BOX
## for any kind not listed.
const DRAW_BOX := {
	Decor.Kind.BARREL: Rect2(-6, -11, 12, 12), Decor.Kind.CRATES: Rect2(-10, -17, 20, 19),
	Decor.Kind.TABLE: Rect2(-16, -14, 32, 18), Decor.Kind.LOGS: Rect2(-12, -16, 24, 18),
	Decor.Kind.BENCH: Rect2(-4, -6, 8, 8), Decor.Kind.LAMP: Rect2(-5, -Structure.LAMP_H - 3, 17, Structure.LAMP_H + 4),
}
const GOODS_BOX := Rect2(-24, -36, 56, 40)
## Goods inside the walls standing within PILE_REACH of each other merge into one PILE node of up to PILE_MAX
## (_merge_piles()): one draw call where each took one. Only kinds drawn at their own size can share a node.
const PILE_KINDS := [Decor.Kind.BARREL, Decor.Kind.CRATES, Decor.Kind.TABLE, Decor.Kind.BENCH, Decor.Kind.LOGS]
const PILE_REACH := 0.6
const PILE_MAX := 6
## Screen cell for the box index the two passes above use.
const BOX_CELL := 64.0
## A height (px) above any part of the Citadel, for the index.
const CITADEL_TALL := 140.0
## Px a building's screen outline is grown by, for eaves and overhangs (_silhouette()).
const SILHOUETTE_GROW := 4.0
## A tree's screen shape (_tree_shape()): where its crown starts above the ground, how far it spreads either side,
## and how far it rises past the tree's height.
const TREE_CROWN_LOW := 10.0
const TREE_CROWN_HALF := 26.0
const TREE_CROWN_UP := 16.0


static func spots() -> Array[Dictionary]:
	# The layout's buildings, worked out once: every pass below needs them, and each working-out lays out the town.
	var built := TownLayout.structures()
	var solid := _solid_rects(built)
	var out: Array[Dictionary] = []
	_yards(out)
	_houses(out, solid)
	_market(out)
	_countryside(out)
	_outside(out, solid)
	# Last, so every other piece keeps its seed.
	_carpenter(out)
	_street(out)
	var boxes := _screen_boxes(built)
	for d in out:
		d.bake = _bakeable(d, boxes)
	_bake_low(out, built)
	return _merge_piles(out, built)


## Footprints that block walking: every standing non-walkable building, the Citadel's parts and the fountain.
static func _solid_rects(built: Array[Dictionary]) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d in built:
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


## What stands on each street prop's blocker (TownLayout.street_props()).
static func _street(out: Array[Dictionary]) -> void:
	for p in TownLayout.street_props():
		var r: Rect2 = p.rect
		var ay: bool = p.along_y
		# Offsets inside the blocker, given along the street and across it.
		var o := func(along: float, across: float) -> Vector2:
			return r.position + (Vector2(across, along) if ay else Vector2(along, across))
		match p.kind:
			TownLayout.Prop.CART:
				_add(out, Decor.Kind.CART, r.position + Vector2(0.45, 0.33))
			TownLayout.Prop.BENCH:
				_add(out, Decor.Kind.BENCH, o.call(0.0, 0.12), Vector2(0.0, 0.7) if ay else Vector2(0.7, 0.0))
			TownLayout.Prop.CRATES:
				_add(out, Decor.Kind.CRATES, o.call(0.3, 0.32))
				_add(out, Decor.Kind.BARREL, o.call(0.45, 0.25))
			TownLayout.Prop.BARRELS:
				_add(out, Decor.Kind.BARREL, o.call(0.12, 0.18))
				_add(out, Decor.Kind.BARREL, o.call(0.36, 0.2))
			TownLayout.Prop.LAMP:
				_add(out, Decor.Kind.LAMP, r.get_center())


## The carpenter's log pile and a barrel of pegs, on the yard beside his shed.
static func _carpenter(out: Array[Dictionary]) -> void:
	var c: Rect2 = TownLayout.CARPENTER_YARD
	_add(out, Decor.Kind.LOGS, c.position + Vector2(0.4, 0.5))
	_add(out, Decor.Kind.BARREL, c.position + Vector2(0.78, 0.22))


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
	# The piles: the wide one a cart; the rest in turn a table of goods, or crates stacked beside a barrel or two.
	for i in TownLayout.MARKET_PILES.size():
		var r: Rect2 = TownLayout.MARKET_PILES[i]
		if r.size.x > 0.8:
			_add(out, Decor.Kind.CART, r.get_center() + Vector2(0.0, 0.1))
			continue
		if i % 2 == 1:
			_add(out, Decor.Kind.TABLE, r.get_center() + Vector2(0.05, 0.1))
			continue
		_add(out, Decor.Kind.CRATES, r.position + Vector2(0.3, 0.3))
		_add(out, Decor.Kind.BARREL, r.position + Vector2(0.12, 0.35))
		if _h(i, 90) < 0.5:
			_add(out, Decor.Kind.BARREL, r.end - Vector2(0.05, 0.02))


# --- Outside the walls ------------------------------------------------------------------

static func _outside(out: Array[Dictionary], solid: Array[Rect2]) -> void:
	var area := TownLayout.MAP.grow(-0.5)
	# Trees on a jittered grid: thick in the forest, scattered in the meadow.
	_scatter(out, solid, area, 1.05, 10, func(g: Vector2, roll: float, i: int) -> int:
		var forest := _forest(g)
		if roll > (FOREST_TREES if forest else MEADOW_TREES) or TownFloor.on_outcrop(g):
			return -1
		var pine := _h(i, 11) < (FOREST_PINES if forest else 0.25)
		return Decor.Kind.PINE if pine else Decor.Kind.OAK)
	_scatter(out, solid, area, 2.0, 20, func(g: Vector2, roll: float, _i: int) -> int:
		return Decor.Kind.ROCK if roll < (0.55 if _forest(g) else 0.32) else -1)
	_scatter(out, solid, area, 1.6, 30, func(g: Vector2, roll: float, _i: int) -> int:
		return Decor.Kind.BUSH if roll < BUSHES and not TownFloor.on_outcrop(g) else -1)
	_scatter(out, solid, area, 1.3, 40, func(g: Vector2, roll: float, _i: int) -> int:
		return Decor.Kind.FLOWERS if roll < 0.3 and not _forest(g) and not TownFloor.on_outcrop(g) else -1)
	# Boulders heaped on the rocky outcrops.
	var boulder := 0
	for o: Array in TownFloor.OUTCROPS:
		var c: Vector2 = o[0]
		var rad: float = o[1]
		for j in int(rad * 4.0):
			boulder += 1
			var a := _h(boulder, 80) * TAU
			var g := c + Vector2(cos(a), sin(a)) * sqrt(_h(boulder, 81)) * rad * 0.7
			if _outside_ok(g, solid, 0.2) and _far_from_others(out, g, 0.35):
				_add(out, Decor.Kind.ROCK, g)
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
	return out > 2.2 and out < TownFloor.FOREST_OUT


# --- Baking ------------------------------------------------------------------

## Every building's screen box (raised by its height and a roof), for the bake test.
static func _screen_boxes(built: Array[Dictionary]) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for d in built:
		out.append(Person._screen_box(d.rect, d.height))
	return out


## Where a piece is drawn in the world's y-sort (its node's screen y), and the box it draws in.
static func _sort_y(g: Vector2) -> float:
	return Iso.ground_to_screen(g).y


static func _box(d: Dictionary) -> Rect2:
	var p := Iso.ground_to_screen(d.at)
	if LOW_BOX.has(d.kind):
		var b: Rect2 = LOW_BOX[d.kind]
		var box := Rect2(p + b.position, b.size)
		if d.kind == Decor.Kind.GARDEN:
			var sc := ArtTuning.scale("garden")
			for c: Vector2 in [Vector2((d.size as Vector2).x, 0.0), d.size, Vector2(0.0, (d.size as Vector2).y)]:
				var q := p + (Iso.ground_to_screen(d.at + c) - p) * sc
				box = box.merge(Rect2(q + b.position, b.size))
		return box
	if d.kind in [Decor.Kind.OAK, Decor.Kind.PINE]:
		return Rect2(p + SCREEN_BOX.position, SCREEN_BOX.size)
	if d.kind == Decor.Kind.PILE:
		var box := Rect2()
		for part: Dictionary in d.parts:
			box = _box(part) if box.size == Vector2.ZERO else box.merge(_box(part))
		return box
	if DRAW_BOX.has(d.kind):
		var b: Rect2 = DRAW_BOX[d.kind]
		var box := Rect2(p + b.position, b.size)
		if d.kind == Decor.Kind.BENCH:
			# A bench runs from its point along its size.
			var q := Iso.ground_to_screen(d.at + (d.size as Vector2))
			box = box.merge(Rect2(q + b.position, b.size))
		return box
	return Rect2(p + GOODS_BOX.position, GOODS_BOX.size)


## Everything drawn live in the town, as [box, sort y, id, outline or null]: the buildings (sorted by their front
## corner), the Citadel and the fountains, and the decor not baked (without the low kinds, with `skip_low`).
## Indexed by BOX_CELL screen cells.
static func _live_index(out: Array[Dictionary], built: Array[Dictionary], skip_low := false) -> Dictionary:
	var index := {}
	var n := 0
	for s in built:
		var r: Rect2 = s.rect
		var shape: Variant = null
		if s.kind == Structure.Kind.TREE:
			shape = _tree_shape(Iso.ground_to_screen(r.get_center()), s.height)
		elif s.kind != Structure.Kind.MARKET_STALL:
			shape = _silhouette(r, s.height)
		_index_box(index, [Person._screen_box(r, s.height), _sort_y(r.end), n, shape])
		n += 1
	# Built beside the layout's buildings: the fountains, and the Citadel's parts (as tall as its keep, to be safe).
	var others: Array[Rect2] = []
	for f: Rect2 in TownLayout.FOUNTAINS:
		others.append(f)
	for r: Rect2 in Citadel.TOWERS + Citadel.WALLS + [Citadel.KEEP]:
		others.append(Rect2(r.position + TownLayout.CITADEL_ORIGIN, r.size))
	for r in others:
		_index_box(index, [Person._screen_box(r, CITADEL_TALL), _sort_y(r.end), n, null])
		n += 1
	for i in out.size():
		var d := out[i]
		if not d.bake and not (skip_low and LOW_BOX.has(d.kind)):
			var shape: Variant = null
			if d.kind in [Decor.Kind.OAK, Decor.Kind.PINE]:
				var tall: float = (d.size as Vector2).x if (d.size as Vector2).x > 0.0 else 64.0
				shape = _tree_shape(Iso.ground_to_screen(d.at), tall)
			_index_box(index, [_box(d), _sort_y(d.at), -1 - i, shape])
	return index


## A tree on screen, from its ground point: a narrow trunk up to TREE_CROWN_LOW px, then a crown TREE_CROWN_HALF
## either side up to its height and a margin.
static func _tree_shape(p: Vector2, tall: float) -> PackedVector2Array:
	var top := -tall - TREE_CROWN_UP
	var low := -TREE_CROWN_LOW
	var w := TREE_CROWN_HALF
	return PackedVector2Array([p + Vector2(-4, 3), p + Vector2(4, 3), p + Vector2(4, low), p + Vector2(w, low),
		p + Vector2(w, top), p + Vector2(-w, top), p + Vector2(-w, low), p + Vector2(-4, low)])


## A building's outline on screen: its footprint's near corners on the ground and all four raised by its height and
## a roof's rise, grown by SILHOUETTE_GROW for eaves. Its bounding box's empty corners cover nothing.
static func _silhouette(r: Rect2, h: float) -> PackedVector2Array:
	var up := Vector2(0.0, -(h + Person.ROOF_MARGIN))
	var back := Iso.ground_to_screen(r.position)
	var right := Iso.ground_to_screen(Vector2(r.end.x, r.position.y))
	var front := Iso.ground_to_screen(r.end)
	var left := Iso.ground_to_screen(Vector2(r.position.x, r.end.y))
	var g := SILHOUETTE_GROW
	return PackedVector2Array([left + Vector2(-g, 0.0), front + Vector2(0.0, g), right + Vector2(g, 0.0),
		right + up + Vector2(g, 0.0), back + up + Vector2(0.0, -g), left + up + Vector2(-g, 0.0)])


static func _index_box(index: Dictionary, e: Array) -> void:
	var b: Rect2 = e[0]
	for y in range(floori(b.position.y / BOX_CELL), floori(b.end.y / BOX_CELL) + 1):
		for x in range(floori(b.position.x / BOX_CELL), floori(b.end.x / BOX_CELL) + 1):
			var key := Vector2i(x, y)
			if not index.has(key):
				index[key] = []
			(index[key] as Array).append(e)


## Whether anything live that sorts before `sort_y` (drawn earlier, so under it) overlaps `box`, ignoring `skip` ids.
## A piece painted into the floor is under everything, so such a neighbour would wrongly cover it.
static func _covered(index: Dictionary, box: Rect2, sort_y: float, skip: Array = []) -> bool:
	for y in range(floori(box.position.y / BOX_CELL), floori(box.end.y / BOX_CELL) + 1):
		for x in range(floori(box.position.x / BOX_CELL), floori(box.end.x / BOX_CELL) + 1):
			for e: Array in index.get(Vector2i(x, y), []):
				if e[1] < sort_y and not skip.has(e[2]) and _overlaps(e, box):
					return true
	return false


static func _overlaps(e: Array, box: Rect2) -> bool:
	if not (e[0] as Rect2).intersects(box):
		return false
	if e[3] == null:
		return true
	var poly := PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end,
		Vector2(box.position.x, box.end.y)])
	return not Geometry2D.intersect_polygons(poly, e[3]).is_empty()


## Low decor inside the walls -- flowers, bushes, garden beds, rocks -- painted into the floor instead of standing
## as a live node each. A piece qualifies unless something live and taller sorting before it overlaps it: a building,
## a tree, a lamp or goods behind it would then cover it. Low pieces never keep each other live: at ground level
## their order moves a pixel or two. A baked piece keeps its live colour, the decor's evening light rather than the
## floor's deeper gold; unlike a live piece, a blast neither chars it nor knocks it flat.
static func _bake_low(out: Array[Dictionary], built: Array[Dictionary]) -> void:
	var low: Array[int] = []
	for i in out.size():
		if LOW_BOX.has(out[i].kind) and TownLayout.TOWN.grow(1.0).has_point(out[i].at):
			low.append(i)
	# Everything else that is live goes in the index first; then each low piece, back to front, joins it if it has
	# to stay live.
	for i in low:
		out[i].bake = true
	var index := _live_index(out, built, true)
	low.sort_custom(func(a: int, b: int) -> bool: return _sort_y(out[a].at) < _sort_y(out[b].at))
	var lit := Color(Town.EVENING.r / Town.GROUND_EVENING.r, Town.EVENING.g / Town.GROUND_EVENING.g,
		Town.EVENING.b / Town.GROUND_EVENING.b)
	for i in low:
		var d := out[i]
		var box := _box(d)
		d.bake = not _covered(index, box, _sort_y(d.at))
		if d.bake:
			d.tint = lit


## Goods inside the walls standing together merged into PILE entries: a cluster grows from its first piece (back to
## front) with pieces within PILE_REACH of any piece already in it, up to PILE_MAX, and only while nothing live
## sorts between its pieces and overlaps them (it would be drawn wrongly over or under the whole pile). The pile
## stands at, and sorts by, its front piece.
static func _merge_piles(out: Array[Dictionary], built: Array[Dictionary]) -> Array[Dictionary]:
	var goods: Array[int] = []
	for i in out.size():
		var d := out[i]
		if not d.bake and d.kind in PILE_KINDS and TownLayout.TOWN.has_point(d.at) \
				and ArtTuning.scale(String(Decor.Kind.keys()[d.kind]).to_lower()) == 1.0:
			goods.append(i)
	goods.sort_custom(func(a: int, b: int) -> bool: return _sort_y(out[a].at) < _sort_y(out[b].at))
	var index := _live_index(out, built)
	var taken := {}
	var piles: Array[Dictionary] = []
	for gi in goods.size():
		var first: int = goods[gi]
		if taken.has(first):
			continue
		var members: Array[int] = [first]
		for gj in range(gi + 1, goods.size()):
			if members.size() >= PILE_MAX:
				break
			var j: int = goods[gj]
			if taken.has(j):
				continue
			var near := false
			for m in members:
				near = near or (out[j].at as Vector2).distance_to(out[m].at) <= PILE_REACH
			if not near:
				continue
			if _pile_ok(out, members + [j], index):
				members.append(j)
		if members.size() < 2:
			continue
		var parts: Array = []
		for m in members:
			taken[m] = true
			var d := out[m]
			parts.append({"kind": d.kind, "at": d.at, "size": d.size, "seed": d.seed})
		# Members were taken back to front, so the last is the front piece the pile sorts by.
		var front := out[members[members.size() - 1]]
		piles.append({"kind": Decor.Kind.PILE, "at": front.at, "size": Vector2.ZERO, "seed": front.seed, "bake": false,
			"parts": parts})
	var result: Array[Dictionary] = []
	for i in out.size():
		if not taken.has(i):
			result.append(out[i])
	result.append_array(piles)
	return result


## Whether these goods can share a node: nothing else live that sorts between the back piece and the front one
## overlaps them.
static func _pile_ok(out: Array[Dictionary], members: Array, index: Dictionary) -> bool:
	var y0 := INF
	var y1 := -INF
	var box := Rect2()
	var skip: Array = []
	for m: int in members:
		var y := _sort_y(out[m].at)
		y0 = minf(y0, y)
		y1 = maxf(y1, y)
		box = _box(out[m]) if skip.is_empty() else box.merge(_box(out[m]))
		skip.append(-1 - m)
	return not _between(index, box, y0, y1, skip)


## Whether anything live sorting between y0 (inclusive) and y1 overlaps `box`, ignoring `skip` ids.
static func _between(index: Dictionary, box: Rect2, y0: float, y1: float, skip: Array) -> bool:
	for y in range(floori(box.position.y / BOX_CELL), floori(box.end.y / BOX_CELL) + 1):
		for x in range(floori(box.position.x / BOX_CELL), floori(box.end.x / BOX_CELL) + 1):
			for e: Array in index.get(Vector2i(x, y), []):
				var sy: float = e[1]
				if sy >= y0 and sy < y1 and not skip.has(e[2]) and _overlaps(e, box):
					return true
	return false


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
