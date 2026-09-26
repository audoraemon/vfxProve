class_name PropArt
extends RefCounted
## The smaller things in town, after concepts/TOWN REF/Town Visual Upgrade.png.
## - Market stall: a striped awning with a scalloped edge on four posts, over a counter heaped with produce.
## - Bridge: a plank deck with side beams, a torch on each corner post, and sagging rope rails between them.
## - Farm field: golden wheat or rows of cabbages, fenced with posts and rails.
## - Tree: a lumpy oak or a tiered pine. tree() is shared with decor, so it only collects: callers flush.
## Colours are unlit: the structure's shader lights them (see ArtKit).

## Stall cloths [stripe, stripe]: red and cream, blue and cream, cream and tan.
const CLOTH := [[Color("c8342a"), Color("ece2c8")], [Color("2f5fb8"), Color("ece2c8")], [Color("ece2c8"), Color("c0a070")]]
const COUNTER_H := 7.0
const CANOPY_BACK := 25.0
const CANOPY_FRONT := 20.0
## Bridge corner posts: how far in from the corners and how tall above the deck.
const POST_IN := 0.08
const POST_UP := 11.0
const ROPE := Color(0.24, 0.16, 0.1, 0.9)
## Fence posts: spacing along an edge (ground units) and height (px).
const FENCE_STEP := 0.45
const FENCE_H := 6.0
## Wheat stands this far above the soil (px).
const WHEAT_H := 5.0


static func plan(s: Structure) -> Dictionary:
	var sd := s.rng.seed
	match s.kind:
		Structure.Kind.MARKET_STALL:
			return {"cloth": sd % CLOTH.size()}
		Structure.Kind.FARM_FIELD:
			return {"crop": ArtKit.pick(sd, 31, 2)}
		Structure.Kind.TREE:
			return {"species": ArtKit.pick(sd, 30, 2)}
	return {}


static func draw(s: Structure) -> void:
	match s.kind:
		Structure.Kind.MARKET_STALL:
			_stall(s)
		Structure.Kind.BRIDGE:
			_bridge(s)
		Structure.Kind.FARM_FIELD:
			_field(s)
		Structure.Kind.TREE:
			ArtKit.begin()
			tree(s._gp(s.center(), 0.0), s.max_height, s.art.species, s.rng.seed)
			ArtKit.flush(s)


## Flame spots for the structure's flame node (structure-local px): the bridge's four torches.
static func flame_tips(s: Structure) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if s.kind == Structure.Kind.BRIDGE:
		for c in _bridge_posts(s):
			out.append(s._gp(c, s.height + POST_UP) + Vector2(0, -1))
	return out


# --- Market stall ------------------------------------------------------------------

static func _stall(s: Structure) -> void:
	ArtKit.begin()
	var r := s.footprint
	var cloth: Array = CLOTH[int(s.art.cloth)]
	var back_posts := [r.position, Vector2(r.end.x, r.position.y)]
	var front_posts := [Vector2(r.position.x, r.end.y), r.end]
	for c: Vector2 in back_posts:
		_post(s, c, 0.0, CANOPY_BACK)
	# Counter: a wooden box with a plank line, and produce heaped on top.
	var c0 := r.position + Vector2(0.06, 0.06)
	var c1 := r.end - Vector2(0.06, 0.06)
	_box(s, c0, c1, 0.0, COUNTER_H, ArtKit.WOOD[1], ArtKit.WOOD[0], ArtKit.WOOD[0].lightened(0.1))
	for i in 9:
		var g := Vector2(lerpf(c0.x + 0.08, c1.x - 0.08, ArtKit.hash01(s.rng.seed, 80 + i)),
			lerpf(c0.y + 0.08, c1.y - 0.08, ArtKit.hash01(s.rng.seed, 90 + i)))
		var col: Color = ArtKit.PRODUCE[ArtKit.pick(s.rng.seed, 100 + i, ArtKit.PRODUCE.size())]
		var p := s._gp(g, COUNTER_H)
		ArtKit.blob(p + Vector2(0, -1), Vector2(2, 1.5), col, ArtKit.LIT_TOP, 6)
		ArtKit.poly(PackedVector2Array([p + Vector2(-1, -2), p + Vector2(0, -2), p + Vector2(0, -1), p + Vector2(-1, -1)]),
			col.lightened(0.35), ArtKit.LIT_TOP)
	for c: Vector2 in front_posts:
		_post(s, c, 0.0, CANOPY_FRONT)
	# Awning: stripes across, sloping down to the front, scallops along the front edge and the open side.
	var x0 := r.position.x - 0.06
	var x1 := r.end.x + 0.06
	var yb := r.position.y - 0.04
	var yf := r.end.y + 0.04
	var stripes := 5
	for i in stripes:
		var xa := lerpf(x0, x1, float(i) / stripes)
		var xb := lerpf(x0, x1, float(i + 1) / stripes)
		var col: Color = cloth[i % 2]
		ArtKit.poly(PackedVector2Array([s._gp(Vector2(xa, yb), CANOPY_BACK), s._gp(Vector2(xb, yb), CANOPY_BACK),
			s._gp(Vector2(xb, yf), CANOPY_FRONT), s._gp(Vector2(xa, yf), CANOPY_FRONT)]), col, ArtKit.LIT_TOP)
		ArtKit.poly(PackedVector2Array([s._gp(Vector2(xa, yf), CANOPY_FRONT), s._gp(Vector2(xb, yf), CANOPY_FRONT),
			s._gp(Vector2((xa + xb) * 0.5, yf), CANOPY_FRONT - 3.0)]), col.darkened(0.12), ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(Vector2(x1, yb), CANOPY_BACK), s._gp(Vector2(x1, yf), CANOPY_FRONT),
		s._gp(Vector2(x1, yf), CANOPY_FRONT - 2.0), s._gp(Vector2(x1, yb), CANOPY_BACK - 2.0)]),
		(cloth[0] as Color).darkened(0.15), ArtKit.LIT_RIGHT)
	ArtKit.line(s._gp(Vector2(x0, yf), CANOPY_FRONT), s._gp(Vector2(x1, yf), CANOPY_FRONT), ArtKit.ink(0.35))
	ArtKit.line(s._gp(Vector2(x0, yb), CANOPY_BACK), s._gp(Vector2(x1, yb), CANOPY_BACK), ArtKit.ink(0.45))
	ArtKit.line(s._gp(Vector2(x0, yb), CANOPY_BACK), s._gp(Vector2(x0, yf), CANOPY_FRONT), ArtKit.ink(0.45))
	ArtKit.line(s._gp(Vector2(x1, yb), CANOPY_BACK - 2.0), s._gp(Vector2(x1, yf), CANOPY_FRONT - 2.0), ArtKit.ink(0.45))
	ArtKit.flush(s)


# --- Bridge ------------------------------------------------------------------

static func _bridge(s: Structure) -> void:
	ArtKit.begin()
	var r := s.footprint
	var h := s.height
	var along_y := r.size.y >= r.size.x
	# Sides: the long beam on the right, the plank ends on the left.
	ArtKit.face_quad(s, ArtKit.RIGHT, 0.0, 1.0, 0.0, h, ArtKit.WOOD[2])
	ArtKit.face_quad(s, ArtKit.LEFT, 0.0, 1.0, 0.0, h, ArtKit.WOOD[1])
	ArtKit.face_line(s, ArtKit.RIGHT, 0.0, h * 0.5, 1.0, h * 0.5, ArtKit.ink(0.35))
	# Deck planks across the span, each its own shade, with gaps.
	var span := r.size.y if along_y else r.size.x
	var n := int(span / 0.2)
	for i in n:
		var k0 := float(i) / n
		var k1 := float(i + 1) / n
		var t := (ArtKit.hash01(s.rng.seed, 110 + i) - 0.5) * 0.18
		var col := ArtKit.WOOD[0].lightened(t) if t > 0.0 else ArtKit.WOOD[0].darkened(-t)
		var q: PackedVector2Array
		if along_y:
			var y0 := lerpf(r.position.y, r.end.y, k0)
			var y1 := lerpf(r.position.y, r.end.y, k1)
			q = PackedVector2Array([s._gp(Vector2(r.position.x, y0), h), s._gp(Vector2(r.end.x, y0), h),
				s._gp(Vector2(r.end.x, y1), h), s._gp(Vector2(r.position.x, y1), h)])
		else:
			var x0 := lerpf(r.position.x, r.end.x, k0)
			var x1 := lerpf(r.position.x, r.end.x, k1)
			q = PackedVector2Array([s._gp(Vector2(x0, r.position.y), h), s._gp(Vector2(x1, r.position.y), h),
				s._gp(Vector2(x1, r.end.y), h), s._gp(Vector2(x0, r.end.y), h)])
		ArtKit.poly(q, col, ArtKit.LIT_TOP)
		ArtKit.line(q[0], q[1], ArtKit.ink(0.4))
	# Side beams along the deck's long edges.
	var beam := 0.12
	var sides := [[r.position, Vector2(r.position.x + beam, r.end.y)], [Vector2(r.end.x - beam, r.position.y), r.end]] \
		if along_y else [[r.position, Vector2(r.end.x, r.position.y + beam)], [Vector2(r.position.x, r.end.y - beam), r.end]]
	for sd in sides:
		var a: Vector2 = sd[0]
		var b: Vector2 = sd[1]
		ArtKit.poly(PackedVector2Array([s._gp(a, h + 1.0), s._gp(Vector2(b.x, a.y), h + 1.0), s._gp(b, h + 1.0),
			s._gp(Vector2(a.x, b.y), h + 1.0)]), ArtKit.WOOD[2], ArtKit.LIT_TOP)
	# Corner posts with torch cups, then the ropes sagging between each side's pair.
	var posts := _bridge_posts(s)
	for c: Vector2 in posts:
		_post(s, c, h, h + POST_UP)
		var tip := s._gp(c, h + POST_UP)
		ArtKit.poly(PackedVector2Array([tip + Vector2(-2, 0), tip + Vector2(2, 0), tip + Vector2(1, 2), tip + Vector2(-1, 2)]),
			ArtKit.IRON, ArtKit.LIT_RIGHT)
	for pair in [[posts[0], posts[1]], [posts[2], posts[3]]]:
		var a := s._gp(pair[0], h + POST_UP - 3.0)
		var b := s._gp(pair[1], h + POST_UP - 3.0)
		var mid := a.lerp(b, 0.5) + Vector2(0, 3)
		ArtKit.line(a, a.lerp(mid, 0.5) + Vector2(0, 1), ROPE)
		ArtKit.line(a.lerp(mid, 0.5) + Vector2(0, 1), mid, ROPE)
		ArtKit.line(mid, mid.lerp(b, 0.5) + Vector2(0, 1), ROPE)
		ArtKit.line(mid.lerp(b, 0.5) + Vector2(0, 1), b, ROPE)
	ArtKit.flush(s)


## The bridge's corner posts: far side pair first (drawn first), then the near side's.
static func _bridge_posts(s: Structure) -> Array[Vector2]:
	var r := s.footprint.grow(-POST_IN)
	if s.footprint.size.y >= s.footprint.size.x:
		return [r.position, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), r.end]
	return [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]


# --- Farm field ------------------------------------------------------------------

static func _field(s: Structure) -> void:
	ArtKit.begin()
	var r := s.footprint
	var h := s.height
	_fence(s, r.position, Vector2(r.end.x, r.position.y))
	_fence(s, r.position, Vector2(r.position.x, r.end.y))
	ArtKit.flush(s)
	_box(s, r.position, r.end, 0.0, h, ArtKit.SOIL[1], ArtKit.SOIL[0], ArtKit.SOIL[0])
	var inner := r.grow(-0.14)
	if int(s.art.crop) == 0:
		_wheat(s, inner, h)
	else:
		_cabbages(s, inner, h)
	ArtKit.flush(s)
	_fence(s, Vector2(r.position.x, r.end.y), r.end)
	_fence(s, Vector2(r.end.x, r.position.y), r.end)
	ArtKit.flush(s)


static func _wheat(s: Structure, r: Rect2, h: float) -> void:
	var top := h + WHEAT_H
	_box(s, r.position, r.end, h, top, ArtKit.WHEAT[2], ArtKit.WHEAT[1], ArtKit.WHEAT[0])
	# Ears on top: short strokes in a loose grid, dark and light.
	var step := 0.11
	var nx := int(r.size.x / step)
	var ny := int(r.size.y / step)
	for j in ny:
		for i in nx:
			var jit := Vector2(ArtKit.hash01(s.rng.seed, 200 + i * 31 + j) - 0.5, ArtKit.hash01(s.rng.seed, 900 + i * 17 + j) - 0.5)
			var g := r.position + Vector2((i + 0.5) * step, (j + 0.5) * step) + jit * step * 0.6
			var p := s._gp(g, top)
			ArtKit.line(p, p + Vector2(0, -2), ArtKit.ink(0.22) if (i + j) % 2 == 0 else ArtKit.ink(0.25, true))
	# Stalks down the two visible sides, poking above the top edge.
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var a := s._gp(Vector2(r.position.x, r.end.y) if face == ArtKit.LEFT else Vector2(r.end.x, r.position.y), 0.0)
		var b := s._gp(r.end, 0.0)
		var cols := int(absf(b.x - a.x) / 2.0)
		for i in cols:
			var p := a.lerp(b, (i + 0.5) / cols)
			var poke := 1.0 + float(ArtKit.pick(s.rng.seed, 300 + i + face * 50, 3))
			ArtKit.line(p + Vector2(0, -h - 1.0), p + Vector2(0, -top - poke),
				ArtKit.ink(0.2) if i % 2 == 0 else ArtKit.ink(0.2, true))


static func _cabbages(s: Structure, r: Rect2, h: float) -> void:
	var rows := int(r.size.y / 0.3)
	for j in rows:
		var y := r.position.y + (j + 0.5) * r.size.y / rows
		ArtKit.line(s._gp(Vector2(r.position.x, y + 0.1), h), s._gp(Vector2(r.end.x, y + 0.1), h), ArtKit.ink(0.3))
		var n := int(r.size.x / 0.26)
		for i in n:
			var g := Vector2(r.position.x + (i + 0.5) * r.size.x / n, y)
			var p := s._gp(g, h)
			ArtKit.blob(p + Vector2(0.5, 0), Vector2(3, 1.8), ArtKit.LEAF[2], ArtKit.LIT_TOP, 6)
			ArtKit.blob(p + Vector2(0, -1), Vector2(2.6, 1.8), ArtKit.LEAF[1], ArtKit.LIT_TOP, 6)
			ArtKit.blob(p + Vector2(-1, -2), Vector2(1.4, 0.9), ArtKit.LEAF[0], ArtKit.LIT_TOP, 6)
			if ArtKit.hash01(s.rng.seed, 400 + j * 37 + i) < 0.3:
				ArtKit.poly(PackedVector2Array([p + Vector2(1, -3), p + Vector2(2, -3), p + Vector2(2, -2), p + Vector2(1, -2)]),
					ArtKit.PRODUCE[3], ArtKit.LIT_TOP)


## Posts every FENCE_STEP from `a` to `b` with two rails between them.
static func _fence(s: Structure, a: Vector2, b: Vector2) -> void:
	var n := maxi(int(a.distance_to(b) / FENCE_STEP), 1)
	var prev := Vector2.INF
	for i in n + 1:
		var g := a.lerp(b, float(i) / n)
		_post(s, g, 0.0, FENCE_H)
		if prev != Vector2.INF:
			for hh in [2.5, 5.0]:
				ArtKit.line(s._gp(prev, hh), s._gp(g, hh), ROPE)
		prev = g


# --- Tree ------------------------------------------------------------------

## A tree standing on `base` (canvas px), `tall` px to its crown: species 0 an oak, 1 a pine. Collects only.
static func tree(base: Vector2, tall: float, species: int, seed_value: int) -> void:
	var trunk_h := roundf(tall * (0.22 if species == 0 else 0.16))
	ArtKit.poly(PackedVector2Array([base + Vector2(-1, 0), base + Vector2(2, 0), base + Vector2(2, -trunk_h),
		base + Vector2(-1, -trunk_h)]), ArtKit.BARK, ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([base + Vector2(-1, 0), base + Vector2(0, 0), base + Vector2(0, -trunk_h),
		base + Vector2(-1, -trunk_h)]), ArtKit.BARK.darkened(0.3), ArtKit.LIT_LEFT)
	if species == 0:
		_oak(base + Vector2(0, -trunk_h), tall - trunk_h, seed_value)
	else:
		_pine(base + Vector2(0, -trunk_h * 0.5), tall - trunk_h * 0.5, seed_value)


static func _oak(foot: Vector2, crown: float, seed_value: int) -> void:
	var rad := roundf(crown * 0.56)
	var c := foot + Vector2(0, -crown * 0.48)
	var clumps := [Vector3(-0.45, 0.2, 0.62), Vector3(0.45, 0.22, 0.6), Vector3(0.0, -0.38, 0.66),
		Vector3(-0.2, 0.42, 0.55), Vector3(0.28, -0.08, 0.6), Vector3(-0.35, -0.18, 0.5)]
	var pts: Array[Vector3] = []
	for i in clumps.size():
		var k: Vector3 = clumps[i]
		var j := Vector2(ArtKit.hash01(seed_value, 500 + i) - 0.5, ArtKit.hash01(seed_value, 520 + i) - 0.5) * 0.25
		pts.append(Vector3((k.x + j.x) * rad, (k.y + j.y) * rad, k.z * rad))
	var o := ArtKit.LIT_TOP
	for p in pts:
		ArtKit.blob(c + Vector2(p.x, p.y), Vector2(p.z + 1.0, p.z * 0.9 + 1.0), ArtKit.OAK[3], o)
	for p in pts:
		ArtKit.blob(c + Vector2(p.x, p.y + 1.0), Vector2(p.z, p.z * 0.9), ArtKit.OAK[2], o)
	for p in pts:
		ArtKit.blob(c + Vector2(p.x - 0.5, p.y - 0.5), Vector2(p.z * 0.8, p.z * 0.7), ArtKit.OAK[1], o)
	for i in 3:
		var p := pts[[2, 5, 4][i]]
		ArtKit.blob(c + Vector2(p.x - p.z * 0.3, p.y - p.z * 0.35), Vector2(p.z * 0.4, p.z * 0.3), ArtKit.OAK[0], o, 6)


static func _pine(foot: Vector2, crown: float, seed_value: int) -> void:
	var tiers := 4
	var w := crown * 0.36
	var tier_h := crown * 0.36
	var step := (crown - tier_h) / (tiers - 1)
	var o := ArtKit.LIT_TOP
	var lean := (ArtKit.hash01(seed_value, 540) - 0.5) * 2.0
	for i in tiers:
		var y := foot.y - i * step
		var half := roundf(w * (1.0 - 0.2 * i))
		var apex := Vector2(foot.x + lean * i * 0.3, y - tier_h)
		var l := Vector2(foot.x - half, y)
		var r := Vector2(foot.x + half, y)
		var m := Vector2(foot.x, y + 1.0)
		ArtKit.poly(PackedVector2Array([apex + Vector2(0, -1), r + Vector2(1, 1), l + Vector2(-1, 1)]), ArtKit.PINE[3], o)
		ArtKit.poly(PackedVector2Array([apex, m, l]), ArtKit.PINE[2], o)
		ArtKit.poly(PackedVector2Array([apex, r, m]), ArtKit.PINE[1], o)
		ArtKit.poly(PackedVector2Array([apex, apex.lerp(r, 0.55), apex.lerp(m, 0.4)]), ArtKit.PINE[0], o)


# --- Shared ------------------------------------------------------------------

## A 2 px post standing at ground point `g` from height h0 to h1.
static func _post(s: Structure, g: Vector2, h0: float, h1: float) -> void:
	var p := s._gp(g, h0)
	var q := s._gp(g, h1)
	ArtKit.poly(PackedVector2Array([p + Vector2(-1, 0), p + Vector2(1, 0), q + Vector2(1, 0), q + Vector2(-1, 0)]),
		ArtKit.WOOD[2], ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([p + Vector2(-1, 0), p, q, q + Vector2(-1, 0)]), ArtKit.WOOD[2].darkened(0.25),
		ArtKit.LIT_LEFT)


## A box over the ground rect g0..g1 from h0 to h1: left side, right side, top.
static func _box(s: Structure, g0: Vector2, g1: Vector2, h0: float, h1: float, left: Color, right: Color, top: Color) -> void:
	var gl := Vector2(g0.x, g1.y)
	var gr := Vector2(g1.x, g0.y)
	ArtKit.poly(PackedVector2Array([s._gp(gl, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gl, h1)]), left, ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(gr, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gr, h1)]), right, ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([s._gp(g0, h1), s._gp(gr, h1), s._gp(g1, h1), s._gp(gl, h1)]), top, ArtKit.LIT_TOP)
