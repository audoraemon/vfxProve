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
## The fountain's water: [highlight, body], emissive so it glows a little.
const WATER_GLOW := [Color("bfe8fa"), Color("58a8dc")]
const CANOPY_BACK := 25.0
const CANOPY_FRONT := 20.0
## Bridge corner posts: how far in from the corners and how tall above the deck.
const POST_IN := 0.08
const POST_UP := 11.0
const ROPE := Color(0.24, 0.16, 0.1, 0.9)
## Fence posts: spacing along an edge (ground units) and height (px).
const FENCE_STEP := 0.4
const FENCE_H := 12.0
## Wheat stands this far above the soil (px).
const WHEAT_H := 6.0


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
			tree(s._gp(s.center(), 0.0), s.max_height * 1.8, s.art.species, s.rng.seed)
			ArtKit.flush(s)
		Structure.Kind.FOUNTAIN:
			_fountain(s)


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
	var c1 := r.end - Vector2(0.06, 0.26)
	_box(s, c0, c1, 0.0, COUNTER_H, ArtKit.WOOD[1], ArtKit.WOOD[0], ArtKit.WOOD[0].lightened(0.1))
	for i in 9:
		var g := Vector2(lerpf(c0.x + 0.08, c1.x - 0.08, ArtKit.hash01(s.rng.seed, 80 + i)),
			lerpf(c0.y + 0.08, c1.y - 0.08, ArtKit.hash01(s.rng.seed, 90 + i)))
		var col: Color = ArtKit.PRODUCE[ArtKit.pick(s.rng.seed, 100 + i, ArtKit.PRODUCE.size())]
		var p := s._gp(g, COUNTER_H)
		ArtKit.blob(p + Vector2(0, -1), Vector2(2, 1.5), col, ArtKit.LIT_TOP, 6)
		ArtKit.poly(PackedVector2Array([p + Vector2(-1, -2), p + Vector2(0, -2), p + Vector2(0, -1), p + Vector2(-1, -1)]),
			col.lightened(0.35), ArtKit.LIT_TOP)
	# A basket of produce and a small crate in front of the counter, as in the reference.
	var bk := s._gp(Vector2(r.position.x + 0.24, r.end.y - 0.12), 0.0)
	ArtKit.blob(bk + Vector2(0, -2), Vector2(4, 2.5), ArtKit.WOOD[1], ArtKit.LIT_LEFT, 8)
	ArtKit.blob(bk + Vector2(0, -3.5), Vector2(3.5, 1.6), ArtKit.WOOD[0], ArtKit.LIT_TOP, 8)
	for i in 4:
		var col: Color = ArtKit.PRODUCE[ArtKit.pick(s.rng.seed, 120 + i, ArtKit.PRODUCE.size())]
		ArtKit.blob(bk + Vector2(-2 + i * 1.4, -4.5 - float(i % 2)), Vector2(1.3, 1.0), col, ArtKit.LIT_TOP, 5)
	var cr := Vector2(r.end.x - 0.34, r.end.y - 0.22)
	_box(s, cr, cr + Vector2(0.2, 0.18), 0.0, 5.0, ArtKit.WOOD[1], ArtKit.WOOD[0], ArtKit.WOOD[0].lightened(0.1))
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
	# Stone blocks line the bridge heads on both banks, as in the reference: the far end's first.
	_head_stones(s, true)
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
		_post(s, c, h, h + POST_UP, 2.0)
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
	_head_stones(s, false)
	ArtKit.flush(s)


## A few rough stone blocks beside each bridge head, on the land outside the deck's sides (`far`: the far head).
static func _head_stones(s: Structure, far: bool) -> void:
	var r := s.footprint
	var along_y := r.size.y >= r.size.x
	for side in [-1.0, 1.0]:
		for k in 2:
			var t := 0.04 + k * 0.1 if far else 0.86 - k * 0.1
			var g: Vector2
			if along_y:
				var x := r.position.x - 0.26 if side < 0.0 else r.end.x + 0.04
				g = Vector2(x, lerpf(r.position.y, r.end.y, t))
			else:
				var y := r.position.y - 0.26 if side < 0.0 else r.end.y + 0.04
				g = Vector2(lerpf(r.position.x, r.end.x, t), y)
			var hgt := 4.0 + float(ArtKit.pick(s.rng.seed, 180 + k + int(side + 1.0) * 3 + (0 if far else 10), 3))
			_box(s, g, g + Vector2(0.22, 0.2), 0.0, hgt, ArtKit.STONE[1], ArtKit.STONE[0], ArtKit.STONE_TOP)


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
	_box(s, r.position, r.end, h, top, ArtKit.WHEAT[2], ArtKit.WHEAT[1], ArtKit.WHEAT[1])
	# Ears in loose rows: each a light tuft with a dark shadow under it, some leaning, some paler.
	var step := 0.12
	var nx := int(r.size.x / step)
	var ny := int(r.size.y / step)
	for j in ny:
		for i in nx:
			var n := j * 97 + i
			var jit := Vector2(ArtKit.hash01(s.rng.seed, 200 + n) - 0.5, ArtKit.hash01(s.rng.seed, 900 + n) - 0.5)
			var g := r.position + Vector2((i + 0.5) * step, (j + 0.5) * step) + jit * step * 0.5
			var p := s._gp(g, top)
			var lean := roundf((ArtKit.hash01(s.rng.seed, 1600 + n) - 0.5) * 2.0)
			ArtKit.poly(PackedVector2Array([p + Vector2(-2, 1), p + Vector2(2, 1), p + Vector2(2, 2), p + Vector2(-2, 2)]),
				ArtKit.WHEAT[2], ArtKit.LIT_TOP)
			var tone: Color = ArtKit.WHEAT[0] if ArtKit.hash01(s.rng.seed, 2300 + n) < 0.7 else ArtKit.WHEAT[0].lightened(0.2)
			ArtKit.blob(p + Vector2(lean * 0.5, -1), Vector2(2.2, 1.8), tone, ArtKit.LIT_TOP, 6)
			ArtKit.poly(PackedVector2Array([p + Vector2(lean, -4), p + Vector2(lean + 1, -4), p + Vector2(1, -1),
				p + Vector2(0, -1)]), ArtKit.WHEAT[1], ArtKit.LIT_TOP)
	# Stalks down the two visible sides, poking above the top edge as a ragged fringe.
	for face in [ArtKit.LEFT, ArtKit.RIGHT]:
		var a := s._gp(Vector2(r.position.x, r.end.y) if face == ArtKit.LEFT else Vector2(r.end.x, r.position.y), 0.0)
		var b := s._gp(r.end, 0.0)
		var cols := int(absf(b.x - a.x) / 2.0)
		for i in cols:
			var p := a.lerp(b, (i + 0.5) / cols)
			var poke := 1.0 + float(ArtKit.pick(s.rng.seed, 300 + i + face * 50, 4))
			ArtKit.line(p + Vector2(0, -h - 1.0), p + Vector2(0, -top - poke),
				ArtKit.ink(0.25) if i % 2 == 0 else ArtKit.ink(0.25, true))


static func _cabbages(s: Structure, r: Rect2, h: float) -> void:
	var rows := int(r.size.y / 0.24)
	for j in rows:
		var y := r.position.y + (j + 0.5) * r.size.y / rows
		ArtKit.line(s._gp(Vector2(r.position.x, y + 0.1), h), s._gp(Vector2(r.end.x, y + 0.1), h), ArtKit.ink(0.3))
		var n := int(r.size.x / 0.22)
		for i in n:
			var g := Vector2(r.position.x + (i + 0.5) * r.size.x / n, y)
			var p := s._gp(g, h)
			ArtKit.blob(p + Vector2(0.5, 0), Vector2(4, 2.6), ArtKit.LEAF[2].darkened(0.2), ArtKit.LIT_TOP, 7)
			ArtKit.blob(p + Vector2(0, -2), Vector2(3.6, 2.6), ArtKit.LEAF[1], ArtKit.LIT_TOP, 7)
			ArtKit.blob(p + Vector2(-1, -3), Vector2(2, 1.3), ArtKit.LEAF[0], ArtKit.LIT_TOP, 6)
			if ArtKit.hash01(s.rng.seed, 400 + j * 37 + i) < 0.45:
				ArtKit.poly(PackedVector2Array([p + Vector2(1, -4), p + Vector2(3, -4), p + Vector2(3, -3), p + Vector2(1, -3)]),
					ArtKit.PRODUCE[3], ArtKit.LIT_TOP)


## Posts every FENCE_STEP from `a` to `b` with two rails between them.
static func _fence(s: Structure, a: Vector2, b: Vector2) -> void:
	var n := maxi(int(a.distance_to(b) / FENCE_STEP), 1)
	var prev := Vector2.INF
	for i in n + 1:
		var g := a.lerp(b, float(i) / n)
		if prev != Vector2.INF:
			for hh in [FENCE_H * 0.35, FENCE_H * 0.72]:
				var p0 := s._gp(prev, hh)
				var p1 := s._gp(g, hh)
				ArtKit.poly(PackedVector2Array([p0, p1, p1 + Vector2(0, 2), p0 + Vector2(0, 2)]), ArtKit.WOOD[1],
					ArtKit.LIT_LEFT)
				ArtKit.line(p0 + Vector2(0, 2), p1 + Vector2(0, 2), ArtKit.ink(0.4))
		_post(s, g, 0.0, FENCE_H, 2.0)
		prev = g


# --- Fountain ------------------------------------------------------------------

## The market fountain: an eight-sided stone basin of water, a pillar and an upper bowl spilling over.
static func _fountain(s: Structure) -> void:
	ArtKit.begin()
	var c := s.center()
	# Drawn a little inside the footprint (which people keep clear of): the reference's fountain is this size.
	var r := s.footprint.grow(-0.2)
	# A square blocky stone base, as in the reference, the round basin sitting on it.
	var base := 3.0
	_box(s, r.position + Vector2(0.02, 0.02), r.end - Vector2(0.02, 0.02), 0.0, base, ArtKit.STONE[1], ArtKit.STONE[0],
		ArtKit.STONE_TOP)
	for k in range(1, 4):
		var u := k / 4.0
		ArtKit.line(s._gp(Vector2(lerpf(r.position.x, r.end.x, u), r.end.y), 0.0),
			s._gp(Vector2(lerpf(r.position.x, r.end.x, u), r.end.y), base), ArtKit.ink(0.35))
		ArtKit.line(s._gp(Vector2(r.end.x, lerpf(r.position.y, r.end.y, u)), 0.0),
			s._gp(Vector2(r.end.x, lerpf(r.position.y, r.end.y, u)), base), ArtKit.ink(0.35))
	var rad := r.size.x * 0.44
	var rim := base + 7.0
	var ring: Array[Vector2] = []
	for k in 8:
		var ang := TAU * (k + 0.5) / 8.0
		ring.append(c + Vector2(cos(ang), sin(ang)) * rad)
	var inner: Array[Vector2] = []
	for g in ring:
		inner.append(c + (g - c) * 0.8)
	for k in 8:
		ArtKit.poly(PackedVector2Array([s._gp(ring[k], rim), s._gp(ring[(k + 1) % 8], rim), s._gp(inner[(k + 1) % 8], rim),
			s._gp(inner[k], rim)]), ArtKit.STONE_TOP, ArtKit.LIT_TOP)
	# Water glows a little, as the reference's does.
	var water := PackedVector2Array()
	for g in inner:
		water.append(s._gp(g, rim - 1.0))
	for k in range(1, 7):
		ArtKit.poly(PackedVector2Array([water[0], water[k], water[k + 1]]), WATER_GLOW[1], ArtKit.EMIT)
	var wc := s._gp(c, rim - 1.0)
	ArtKit.blob(wc + Vector2(-7, 2), Vector2(4, 1.5), WATER_GLOW[0], ArtKit.EMIT, 6)
	ArtKit.blob(wc + Vector2(8, 3), Vector2(3, 1), WATER_GLOW[0], ArtKit.EMIT, 6)
	# Two tiers: a pillar to a wide bowl, a short pillar to a small bowl with a spout, water spilling from both.
	var t1 := 14.0
	var t2 := 7.0
	ArtKit.poly(PackedVector2Array([wc + Vector2(-2, 0), wc + Vector2(2, 0), wc + Vector2(2, -t1), wc + Vector2(-2, -t1)]),
		ArtKit.STONE[0], ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([wc + Vector2(-2, 0), wc + Vector2(0, 0), wc + Vector2(0, -t1), wc + Vector2(-2, -t1)]),
		ArtKit.STONE[1], ArtKit.LIT_LEFT)
	for x in [-8.0, 8.0]:
		ArtKit.line(wc + Vector2(x, -t1), wc + Vector2(x * 1.15, -1), Color(0.78, 0.92, 1.0, 0.85))
	ArtKit.blob(wc + Vector2(0, -t1), Vector2(9, 3.5), ArtKit.STONE[1], ArtKit.LIT_LEFT)
	ArtKit.blob(wc + Vector2(0, -t1 - 1), Vector2(7.5, 2.6), WATER_GLOW[1], ArtKit.EMIT)
	var w2 := wc + Vector2(0, -t1 - 1)
	ArtKit.poly(PackedVector2Array([w2 + Vector2(-1, 0), w2 + Vector2(1, 0), w2 + Vector2(1, -t2), w2 + Vector2(-1, -t2)]),
		ArtKit.STONE[0], ArtKit.LIT_RIGHT)
	for x in [-4.0, 4.0]:
		ArtKit.line(w2 + Vector2(x, -t2), w2 + Vector2(x * 1.3, -1), Color(0.78, 0.92, 1.0, 0.85))
	ArtKit.blob(w2 + Vector2(0, -t2), Vector2(4.5, 1.8), ArtKit.STONE[1], ArtKit.LIT_LEFT)
	ArtKit.blob(w2 + Vector2(0, -t2 - 0.5), Vector2(3.5, 1.2), WATER_GLOW[1], ArtKit.EMIT)
	ArtKit.poly(PackedVector2Array([w2 + Vector2(-1, -t2), w2 + Vector2(1, -t2), w2 + Vector2(1, -t2 - 5), w2 + Vector2(-1, -t2 - 5)]),
		WATER_GLOW[0], ArtKit.EMIT)
	# The basin's front walls (the sides facing the camera), each block its own shade.
	for k in 8:
		var a := ring[k]
		var b := ring[(k + 1) % 8]
		var n := ((a + b) * 0.5 - c).normalized()
		if n.x + n.y <= 0.05:
			continue
		var shade := ArtKit.STONE[0] if n.x >= n.y else ArtKit.STONE[1]
		var code := ArtKit.LIT_RIGHT if n.x >= n.y else ArtKit.LIT_LEFT
		ArtKit.poly(PackedVector2Array([s._gp(a, base), s._gp(b, base), s._gp(b, rim), s._gp(a, rim)]),
			shade.darkened(ArtKit.hash01(s.rng.seed, 150 + k) * 0.1), code)
		ArtKit.line(s._gp(a, rim), s._gp(b, rim), ArtKit.ink(0.2, true))
		ArtKit.line(s._gp(a, base), s._gp(a, rim), ArtKit.ink(0.35))
	ArtKit.flush(s)

# --- Tree ------------------------------------------------------------------

## A tree standing on `base` (canvas px), `tall` px to its crown: species 0 an oak, 1 a pine. Collects only.
static func tree(base: Vector2, tall: float, species: int, seed_value: int) -> void:
	var trunk_h := roundf(tall * (0.24 if species == 0 else 0.14))
	# A trunk with a little root flare at its foot.
	ArtKit.poly(PackedVector2Array([base + Vector2(-2, 0), base + Vector2(3, 0), base + Vector2(2, -trunk_h),
		base + Vector2(-1, -trunk_h)]), ArtKit.BARK, ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([base + Vector2(-2, 0), base + Vector2(0, 0), base + Vector2(0, -trunk_h),
		base + Vector2(-1, -trunk_h)]), ArtKit.BARK.darkened(0.3), ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([base + Vector2(-4, 1), base + Vector2(5, 1), base + Vector2(2, -2), base + Vector2(-1, -2)]),
		ArtKit.BARK.darkened(0.15), ArtKit.LIT_LEFT)
	if species == 0:
		_oak(base + Vector2(0, -trunk_h), tall - trunk_h, seed_value)
	else:
		_pine(base + Vector2(0, -trunk_h * 0.5), tall - trunk_h * 0.5, seed_value)


static func _oak(foot: Vector2, crown: float, seed_value: int) -> void:
	var rx := roundf(crown * 0.5)
	var c := foot + Vector2(0, -crown * 0.5)
	leafy(c, Vector2(rx, crown * 0.46), seed_value, 30, ArtKit.OAK)


## A leafy mass as the reference draws its oaks and bushes: a dark outline of big clumps, then many small leaf
## clusters, each with a darker rim and a light top, lit from the upper left and shaded to the lower right, back
## to front. `pal` is [light, mid, dark, outline]. Collects only.
static func leafy(c: Vector2, r: Vector2, seed_value: int, clusters: int, pal: Array) -> void:
	var o := ArtKit.LIT_TOP
	var big := [Vector3(-0.45, 0.2, 0.6), Vector3(0.45, 0.22, 0.58), Vector3(0.0, -0.38, 0.64),
		Vector3(-0.2, 0.42, 0.55), Vector3(0.28, -0.08, 0.6), Vector3(-0.35, -0.18, 0.5)]
	for i in big.size():
		var k: Vector3 = big[i]
		var p := c + Vector2(k.x * r.x, k.y * r.y)
		ArtKit.blob(p, Vector2(k.z * r.x + 1.0, k.z * r.y + 1.0), pal[3], o)
	for i in big.size():
		var k: Vector3 = big[i]
		ArtKit.blob(c + Vector2(k.x * r.x, k.y * r.y + 1.0), Vector2(k.z * r.x, k.z * r.y), pal[2], o)
	# Leaf clusters, spread over the crown and drawn from the back (top) to the front (bottom).
	var spots: Array[Vector3] = []
	for i in clusters:
		var ang := ArtKit.hash01(seed_value, 600 + i) * TAU
		var dist := sqrt(ArtKit.hash01(seed_value, 700 + i)) * 0.82
		var size := lerpf(0.16, 0.26, ArtKit.hash01(seed_value, 800 + i)) * r.x
		spots.append(Vector3(cos(ang) * dist * r.x, sin(ang) * dist * r.y, maxf(size, 1.6)))
	spots.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
	var light := Vector2(-0.6, -0.8)
	for p in spots:
		var at := c + Vector2(p.x, p.y)
		var lit := Vector2(p.x / r.x, p.y / r.y).dot(light)
		var tone: Color = pal[0] if lit > 0.35 else (pal[1] if lit > -0.25 else pal[2])
		ArtKit.blob(at + Vector2(0.5, 0.8), Vector2(p.z + 0.6, p.z * 0.85 + 0.6), pal[2].darkened(0.25), o, 7)
		ArtKit.blob(at, Vector2(p.z, p.z * 0.85), tone, o, 7)
		ArtKit.blob(at + Vector2(-p.z * 0.35, -p.z * 0.35), Vector2(p.z * 0.45, p.z * 0.35), tone.lightened(0.18), o, 5)


## A pine as the reference draws it: a dark cone built up from rows of drooping branch clumps, lit on the right
## and shaded on the left, the rows flaring every few steps so the outline is ragged.
static func _pine(foot: Vector2, crown: float, seed_value: int) -> void:
	var o := ArtKit.LIT_TOP
	var top := foot + Vector2(0, -crown)
	var base_half := crown * 0.34
	ArtKit.poly(PackedVector2Array([top + Vector2(0, -1), foot + Vector2(base_half + 1, 1), foot + Vector2(-base_half - 1, 1)]),
		ArtKit.PINE[3], o)
	var rows := maxi(int(crown / 3.5), 4)
	for j in rows:
		var t := (j + 0.6) / rows
		var y := lerpf(top.y, foot.y - 1.0, t)
		var flare := 0.8 + 0.2 * float(j % 3) / 2.0
		var half := base_half * t * flare
		var n := maxi(int(half * 2.0 / 3.5), 1)
		for k in n + 1:
			var x := lerpf(-half, half, float(k) / n) if n > 0 else 0.0
			var side := x / maxf(half, 1.0)
			var tone: Color = ArtKit.PINE[0] if side > 0.3 else (ArtKit.PINE[1] if side > -0.35 else ArtKit.PINE[2])
			var r := 2.0 + ArtKit.hash01(seed_value, 900 + j * 31 + k) * 1.2
			var c := Vector2(foot.x + x, y)
			ArtKit.blob(c + Vector2(0.4, 0.9), Vector2(r + 0.5, r * 0.6 + 0.5), ArtKit.PINE[3], o, 6)
			ArtKit.blob(c, Vector2(r, r * 0.6), tone, o, 6)
			if side > 0.3:
				ArtKit.blob(c + Vector2(-0.6, -0.6), Vector2(r * 0.4, r * 0.25), tone.lightened(0.2), o, 5)


# --- Shared ------------------------------------------------------------------

## A post standing at ground point `g` from height h0 to h1, `half` px either side of it.
static func _post(s: Structure, g: Vector2, h0: float, h1: float, half := 1.0) -> void:
	var p := s._gp(g, h0)
	var q := s._gp(g, h1)
	ArtKit.poly(PackedVector2Array([p + Vector2(-half, 0), p + Vector2(half, 0), q + Vector2(half, 0), q + Vector2(-half, 0)]),
		ArtKit.WOOD[2], ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([q + Vector2(-half, -1), q + Vector2(half, -1), q + Vector2(half, 0), q + Vector2(-half, 0)]),
		ArtKit.WOOD[1], ArtKit.LIT_TOP)
	ArtKit.poly(PackedVector2Array([p + Vector2(-half, 0), p, q, q + Vector2(-half, 0)]), ArtKit.WOOD[2].darkened(0.25),
		ArtKit.LIT_LEFT)


## A box over the ground rect g0..g1 from h0 to h1: left side, right side, top.
static func _box(s: Structure, g0: Vector2, g1: Vector2, h0: float, h1: float, left: Color, right: Color, top: Color) -> void:
	var gl := Vector2(g0.x, g1.y)
	var gr := Vector2(g1.x, g0.y)
	ArtKit.poly(PackedVector2Array([s._gp(gl, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gl, h1)]), left, ArtKit.LIT_LEFT)
	ArtKit.poly(PackedVector2Array([s._gp(gr, h0), s._gp(g1, h0), s._gp(g1, h1), s._gp(gr, h1)]), right, ArtKit.LIT_RIGHT)
	ArtKit.poly(PackedVector2Array([s._gp(g0, h1), s._gp(gr, h1), s._gp(g1, h1), s._gp(gl, h1)]), top, ArtKit.LIT_TOP)
