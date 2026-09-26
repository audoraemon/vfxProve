class_name DecorArt
extends RefCounted
## The town's small things, after concepts/TOWN REF/Town Visual Upgrade.png: barrels, crates, benches, fences,
## gardens, bushes, rocks, trees, lamps, bunting, a scarecrow, a signpost, reeds and flowers.
## paint() only collects (ArtKit): a live Decor flushes onto itself, the floor bake onto its detail layer.
## Points are screen px relative to `origin` (the screen point the drawing canvas treats as zero).
## Colours are final (no lighting codes matter): a live decor's layer is dimmed with the ambient light, and baked
## decor dims with the ground.

const STRAW := Color("d8b860")
const CLOTH := Color("8a4a3a")


static func paint(kind: int, at: Vector2, size: Vector2, seed_value: int, origin: Vector2, down := false) -> void:
	var o := Iso.ground_to_screen(at) - origin
	if down:
		if kind == Decor.Kind.OAK or kind == Decor.Kind.PINE:
			ArtKit.poly(PackedVector2Array([o + Vector2(-2, 0), o + Vector2(2, 0), o + Vector2(2, -3), o + Vector2(-2, -3)]),
				ArtKit.BARK, 0.0)
		return
	match kind:
		Decor.Kind.BARREL:
			_barrel(o)
		Decor.Kind.CRATES:
			_crate(at, Vector2(0.28, 0.28), 0.0, origin)
			if ArtKit.hash01(seed_value, 1) < 0.5:
				_crate(at - Vector2(0.04, 0.04), Vector2(0.2, 0.2), 6.0, origin)
		Decor.Kind.BENCH:
			_bench(at, size, origin)
		Decor.Kind.FENCE:
			_fence(at, at + size, origin, 14.0)
		Decor.Kind.GARDEN:
			_garden(at, size, seed_value, origin)
		Decor.Kind.BUSH:
			_bush(o, seed_value, 1.2)
		Decor.Kind.ROCK:
			_rock(o, seed_value)
		Decor.Kind.OAK, Decor.Kind.PINE:
			# A tree in town carries its height (px) in size.x; out in the country it picks one.
			var tall := size.x if size.x > 0.0 else 46.0 + ArtKit.hash01(seed_value, 3) * 18.0
			PropArt.tree(o, tall, 0 if kind == Decor.Kind.OAK else 1, seed_value)
		Decor.Kind.LAMP:
			_lamp(o)
		Decor.Kind.BUNTING:
			_bunting(at, at + size, origin)
		Decor.Kind.SCARECROW:
			_scarecrow(o)
		Decor.Kind.SIGNPOST:
			_signpost(o)
		Decor.Kind.REEDS:
			_reeds(o, seed_value)
		Decor.Kind.FLOWERS:
			_flowers(o, seed_value)
		Decor.Kind.TABLE:
			_table(at, origin, seed_value)


## Where a lamp's lantern glows (relative to its ground point, screen px).
static func lamp_light() -> Vector2:
	return Vector2(3, -13)


static func _gp(g: Vector2, h: float, origin: Vector2) -> Vector2:
	return Iso.ground_to_screen(g) - origin + Vector2(0, -h)


static func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	ArtKit.poly(PackedVector2Array([a, b, c, d]), col, 0.0)


static func _rect(p: Vector2, w: float, h: float, col: Color) -> void:
	_quad(p, p + Vector2(w, 0), p + Vector2(w, h), p + Vector2(0, h), col)


static func _barrel(o: Vector2) -> void:
	_rect(o + Vector2(-5, -10), 10, 10, ArtKit.WOOD[1])
	_rect(o + Vector2(-5, -10), 3, 10, ArtKit.WOOD[2])
	_rect(o + Vector2(3, -10), 2, 10, ArtKit.WOOD[0])
	for x in [-2.0, 1.0]:
		ArtKit.line(o + Vector2(x, -9), o + Vector2(x, 0), ArtKit.ink(0.25))
	ArtKit.blob(o + Vector2(0, -10), Vector2(5, 2.2), ArtKit.WOOD[0], 0.0, 10)
	ArtKit.blob(o + Vector2(0, -10), Vector2(3.5, 1.4), ArtKit.WOOD[2], 0.0, 8)
	for y in [-2.0, -8.0]:
		_rect(o + Vector2(-5, y), 10, 1, Color(0.24, 0.2, 0.18))
	ArtKit.line(o + Vector2(-5, 0), o + Vector2(5, 0), ArtKit.ink(0.6))


static func _crate(at: Vector2, side: Vector2, lift: float, origin: Vector2) -> void:
	var g0 := at - side
	var g1 := at
	var gl := Vector2(g0.x, g1.y)
	var gr := Vector2(g1.x, g0.y)
	var h0 := lift
	var h1 := lift + side.x * 20.0
	_quad(_gp(gl, h0, origin), _gp(g1, h0, origin), _gp(g1, h1, origin), _gp(gl, h1, origin), ArtKit.WOOD[1])
	_quad(_gp(gr, h0, origin), _gp(g1, h0, origin), _gp(g1, h1, origin), _gp(gr, h1, origin), ArtKit.WOOD[0])
	_quad(_gp(g0, h1, origin), _gp(gr, h1, origin), _gp(g1, h1, origin), _gp(gl, h1, origin), ArtKit.WOOD[0].lightened(0.12))
	ArtKit.line(_gp(gl, h0, origin), _gp(g1, h1, origin), ArtKit.ink(0.35))
	ArtKit.line(_gp(gr, h0, origin), _gp(g1, h1, origin), ArtKit.ink(0.35))
	ArtKit.line(_gp(g1, h0, origin), _gp(g1, h1, origin), ArtKit.ink(0.5))


static func _bench(at: Vector2, size: Vector2, origin: Vector2) -> void:
	var a := at
	var b := at + size
	for g in [a, b]:
		var p := _gp(g, 0.0, origin)
		_rect(p + Vector2(-1, -3), 1, 3, ArtKit.WOOD[2])
	var side := Vector2(-size.y, size.x).normalized() * 0.07
	_quad(_gp(a - side, 3.0, origin), _gp(b - side, 3.0, origin), _gp(b + side, 3.0, origin), _gp(a + side, 3.0, origin),
		ArtKit.WOOD[0])
	_quad(_gp(a + side, 3.0, origin), _gp(b + side, 3.0, origin), _gp(b + side, 2.0, origin), _gp(a + side, 2.0, origin),
		ArtKit.WOOD[2])


## Chunky posts every 0.4 units with two thick rails between them, as in the reference.
static func _fence(a: Vector2, b: Vector2, origin: Vector2, tall: float) -> void:
	var n := maxi(roundi(a.distance_to(b) / 0.4), 1)
	var prev := Vector2.INF
	for i in n + 1:
		var g := a.lerp(b, float(i) / n)
		if prev != Vector2.INF:
			for hh in [tall * 0.35, tall * 0.72]:
				var p0 := _gp(prev, hh, origin)
				var p1 := _gp(g, hh, origin)
				_quad(p0, p1, p1 + Vector2(0, 2), p0 + Vector2(0, 2), ArtKit.WOOD[1])
				ArtKit.line(p0 + Vector2(0, 2), p1 + Vector2(0, 2), ArtKit.ink(0.4))
		var p := _gp(g, 0.0, origin)
		_rect(p + Vector2(-2, -tall), 4, tall, ArtKit.WOOD[2])
		_rect(p + Vector2(0, -tall), 2, tall, ArtKit.WOOD[1])
		_rect(p + Vector2(-2, -tall - 1), 4, 1, ArtKit.WOOD[0])
		prev = g


static func _garden(at: Vector2, size: Vector2, seed_value: int, origin: Vector2) -> void:
	var g0 := at
	var g1 := at + size
	_quad(_gp(g0, 0.0, origin), _gp(Vector2(g1.x, g0.y), 0.0, origin), _gp(g1, 0.0, origin),
		_gp(Vector2(g0.x, g1.y), 0.0, origin), ArtKit.SOIL[0])
	_fence(g0, Vector2(g1.x, g0.y), origin, 9.0)
	_fence(g0, Vector2(g0.x, g1.y), origin, 9.0)
	var step := 0.18
	var cols := maxi(int(size.x / step), 1)
	var rows := maxi(int(size.y / step), 1)
	for k in cols * rows:
		var g := g0 + Vector2((k % cols + 0.5) * size.x / cols, (floori(float(k) / cols) + 0.5) * size.y / rows)
		var p := _gp(g, 0.0, origin)
		ArtKit.blob(p + Vector2(0, -1), Vector2(3.4, 2.2), ArtKit.LEAF[2].darkened(0.2), 0.0, 7)
		ArtKit.blob(p + Vector2(0, -2), Vector2(3, 2), ArtKit.LEAF[1], 0.0, 7)
		ArtKit.blob(p + Vector2(-1, -3), Vector2(1.6, 1.1), ArtKit.LEAF[0], 0.0, 6)
		if ArtKit.hash01(seed_value, 10 + k) < 0.5:
			var col: Color = TownFloor.FLOWERS[ArtKit.pick(seed_value, 40 + k, TownFloor.FLOWERS.size())]
			_rect(p + Vector2(0, -4), 2, 2, col)
	_fence(Vector2(g0.x, g1.y), g1, origin, 9.0)
	_fence(Vector2(g1.x, g0.y), g1, origin, 9.0)


static func _bush(o: Vector2, seed_value: int, scale: float) -> void:
	var r := Vector2(7.0, 5.5) * scale
	PropArt.leafy(o + Vector2(0, -r.y), r, seed_value, 12, ArtKit.OAK)


## A cluster of two to four blocky boulders, as in the reference: each a rough block with a pale top, a mid left
## face and a dark right face, a crack or two, and moss on some tops. Back boulders first.
static func _rock(o: Vector2, seed_value: int) -> void:
	var n := 2 + ArtKit.pick(seed_value, 50, 2)
	var blocks: Array[Vector3] = []
	for i in n:
		var a := lerpf(5.0, 7.0, ArtKit.hash01(seed_value, 52 + i))
		var side := -1.0 if i % 2 == 1 else 1.0
		var at := Vector2(side * lerpf(5.0, 7.0, ArtKit.hash01(seed_value, 60 + i)), (ArtKit.hash01(seed_value, 70 + i) - 0.5) * 6.0)
		if i == 0:
			at = Vector2.ZERO
			a = 8.0
		blocks.append(Vector3(at.x, at.y, a))
	blocks.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.y < q.y)
	for i in blocks.size():
		var b := blocks[i]
		var c := o + Vector2(roundf(b.x), roundf(b.y))
		var a := b.z
		var hgt := roundf(a * lerpf(1.1, 1.5, ArtKit.hash01(seed_value, 80 + i)))
		var j := func(k: int) -> Vector2:
			return Vector2(roundf((ArtKit.hash01(seed_value, 90 + i * 10 + k) - 0.5) * 2.0),
				roundf((ArtKit.hash01(seed_value, 95 + i * 10 + k) - 0.5) * 2.0))
		var top := c + Vector2(0, -hgt)
		var tl: Vector2 = top + Vector2(-a, 0) + j.call(0)
		var tb: Vector2 = top + Vector2(0, -a * 0.5) + j.call(1)
		var tr: Vector2 = top + Vector2(a, 0) + j.call(2)
		var tf: Vector2 = top + Vector2(0, a * 0.5) + j.call(3)
		var bl := Vector2(tl.x, c.y)
		var bf := Vector2(tf.x, c.y + a * 0.5)
		var br := Vector2(tr.x, c.y)
		var ink := Color("2e2c2a")
		# Ink outline: the top diamond and the body, grown a pixel.
		ArtKit.poly(PackedVector2Array([tl + Vector2(-1, 0), tb + Vector2(0, -1), tr + Vector2(1, 0), tf + Vector2(0, 1)]), ink, 0.0)
		ArtKit.poly(PackedVector2Array([tl + Vector2(-1, 0), tr + Vector2(1, 0), br + Vector2(1, 1), bl + Vector2(-1, 1)]),
			ink, 0.0)
		ArtKit.poly(PackedVector2Array([bl + Vector2(-1, 1), br + Vector2(1, 1), bf + Vector2(0, 1)]), ink, 0.0)
		ArtKit.poly(PackedVector2Array([tl, tf, bf, bl]), TownFloor.PEBBLE[1], 0.0)
		ArtKit.poly(PackedVector2Array([tf, tr, br, bf]), TownFloor.PEBBLE[2], 0.0)
		ArtKit.poly(PackedVector2Array([tl, tb, tr, tf]), TownFloor.PEBBLE[0], 0.0)
		ArtKit.line(tl, tf, Color(1, 1, 1, 0.25))
		ArtKit.line(tf, tr, Color(1, 1, 1, 0.15))
		ArtKit.line(tf.lerp(bf, 0.2) + Vector2(1, 0), tf.lerp(bf, 0.7) + Vector2(2, 0), ArtKit.ink(0.4))
		ArtKit.line(tl.lerp(bl, 0.4) + Vector2(2, 0), tl.lerp(bl, 0.4) + Vector2(4, 1), ArtKit.ink(0.3))
		if ArtKit.hash01(seed_value, 99 + i) < 0.6:
			ArtKit.blob(tb.lerp(tf, 0.5) + Vector2(-1, 0), Vector2(a * 0.45, a * 0.2), Color("6a7e32"), 0.0, 6)
			ArtKit.blob(tb.lerp(tf, 0.4) + Vector2(-2, 0), Vector2(a * 0.2, a * 0.1), Color("8ea042"), 0.0, 5)


static func _lamp(o: Vector2) -> void:
	var tall := Structure.LAMP_H
	_rect(o + Vector2(-2, -tall), 3, tall, ArtKit.TIMBER_DARK)
	_rect(o + Vector2(0, -tall), 1, tall, ArtKit.TIMBER)
	_rect(o + Vector2(-4, -2), 7, 2, ArtKit.TIMBER_DARK)
	_rect(o + Vector2(-2, -tall - 2), 12, 2, ArtKit.TIMBER_DARK)
	var l := o + Vector2(5, -tall + 1)
	_rect(l, 6, 8, ArtKit.IRON.darkened(0.3))
	_rect(l + Vector2(1, 1), 4, 6, ArtKit.GLOW_RIM)
	_rect(l + Vector2(2, 2), 2, 4, ArtKit.GLOW)


static func _bunting(a: Vector2, b: Vector2, origin: Vector2) -> void:
	var pa := _gp(a, 18.0, origin)
	var pb := _gp(b, 18.0, origin)
	var n := maxi(int(pa.distance_to(pb) / 5.0), 2)
	var prev := pa
	for i in range(1, n + 1):
		var k := float(i) / n
		var sag := sin(k * PI) * 5.0
		var p := pa.lerp(pb, k) + Vector2(0, sag)
		ArtKit.line(prev, p, PropArt.ROPE)
		var mid := prev.lerp(p, 0.5)
		var col: Color = ArtKit.BANNER[0] if i % 2 == 0 else ArtKit.BANNER[2]
		ArtKit.poly(PackedVector2Array([prev + Vector2(1, 0), p + Vector2(-1, 0), mid + Vector2(0, 4)]), col, 0.0)
		prev = p


## A scarecrow the reference's size: a cross post, a patched shirt with straw hands, trousers, a straw head and a
## wide-brimmed hat.
static func _scarecrow(o: Vector2) -> void:
	_rect(o + Vector2(-1, -30), 2, 30, ArtKit.WOOD[2])
	_rect(o + Vector2(-13, -22), 26, 2, ArtKit.WOOD[2])
	_rect(o + Vector2(-5, -23), 10, 11, CLOTH)
	_rect(o + Vector2(-5, -23), 3, 11, CLOTH.darkened(0.25))
	_rect(o + Vector2(1, -19), 3, 3, Color("c09050"))
	_rect(o + Vector2(-9, -23), 4, 3, CLOTH)
	_rect(o + Vector2(5, -23), 4, 3, CLOTH.darkened(0.1))
	_rect(o + Vector2(-13, -23), 4, 3, STRAW)
	_rect(o + Vector2(9, -23), 4, 3, STRAW)
	_rect(o + Vector2(-4, -12), 3, 7, Color("4a5a78"))
	_rect(o + Vector2(1, -12), 3, 7, Color("3e4c68"))
	_rect(o + Vector2(-4, -6), 2, 2, STRAW)
	_rect(o + Vector2(2, -6), 2, 2, STRAW)
	ArtKit.blob(o + Vector2(0, -27), Vector2(3.5, 3.5), STRAW, 0.0, 8)
	_rect(o + Vector2(-1, -28), 1, 1, Color("2a1c14"))
	_rect(o + Vector2(1, -28), 1, 1, Color("2a1c14"))
	ArtKit.blob(o + Vector2(0, -30), Vector2(7, 2), ArtKit.WOOD[1], 0.0, 10)
	ArtKit.poly(PackedVector2Array([o + Vector2(-4, -30), o + Vector2(4, -30), o + Vector2(3, -35), o + Vector2(-3, -35)]),
		ArtKit.WOOD[1].darkened(0.1), 0.0)


## A signpost the reference's size: a stout post with two arrow boards pointing different ways.
static func _signpost(o: Vector2) -> void:
	_rect(o + Vector2(-2, -28), 4, 28, ArtKit.WOOD[2])
	_rect(o + Vector2(0, -28), 2, 28, ArtKit.WOOD[1])
	_rect(o + Vector2(-4, -2), 8, 2, ArtKit.WOOD[2])
	for board in [[-26.0, 1.0], [-18.0, -1.0]]:
		var y: float = board[0]
		var d: float = board[1]
		var x0 := -2.0 if d > 0.0 else -12.0
		_rect(o + Vector2(x0, y), 14, 6, ArtKit.WOOD[1])
		_rect(o + Vector2(x0, y), 14, 1, ArtKit.WOOD[0])
		var tip := o + Vector2(x0 + (14.0 if d > 0.0 else 0.0), y)
		ArtKit.poly(PackedVector2Array([tip, tip + Vector2(3.0 * d, 3), tip + Vector2(0, 6)]), ArtKit.WOOD[1], 0.0)
		ArtKit.line(o + Vector2(x0 + 2, y + 3), o + Vector2(x0 + 10, y + 3), ArtKit.ink(0.45))


static func _reeds(o: Vector2, seed_value: int) -> void:
	for i in 12:
		var x := (ArtKit.hash01(seed_value, 60 + i) - 0.5) * 14.0
		var tall := 12.0 + ArtKit.hash01(seed_value, 70 + i) * 14.0
		var lean := roundf((ArtKit.hash01(seed_value, 75 + i) - 0.5) * 4.0)
		var col: Color = ArtKit.LEAF[i % 3]
		var b := o + Vector2(roundf(x), 0)
		ArtKit.poly(PackedVector2Array([b + Vector2(-1, 0), b + Vector2(1, 0), b + Vector2(lean + 0.5, -tall),
			b + Vector2(lean - 0.5, -tall)]), col, 0.0)
		if i % 3 == 0:
			_rect(b + Vector2(lean - 1, -tall - 3), 2, 5, Color("5a3a22"))


## A tavern table with a bench either side and a mug or two on it; `at` is the table's centre.
static func _table(at: Vector2, origin: Vector2, seed_value: int) -> void:
	var half := Vector2(0.22, 0.1)
	for bench_y: float in [-0.2, 0.2]:
		if bench_y > 0.0:
			_table_top(at, half, origin, seed_value)
		var c := at + Vector2(0, bench_y)
		var g0 := c - Vector2(0.2, 0.04)
		var g1 := c + Vector2(0.2, 0.04)
		_quad(_gp(g0, 4.0, origin), _gp(Vector2(g1.x, g0.y), 4.0, origin), _gp(g1, 4.0, origin), _gp(Vector2(g0.x, g1.y), 4.0, origin),
			ArtKit.WOOD[0])
		_quad(_gp(Vector2(g0.x, g1.y), 4.0, origin), _gp(g1, 4.0, origin), _gp(g1, 2.5, origin), _gp(Vector2(g0.x, g1.y), 2.5, origin),
			ArtKit.WOOD[2])
		for x in [g0.x + 0.03, g1.x - 0.03]:
			var p := _gp(Vector2(x, g1.y), 0.0, origin)
			_rect(p + Vector2(0, -3), 1, 3, ArtKit.WOOD[2])


static func _table_top(at: Vector2, half: Vector2, origin: Vector2, seed_value: int) -> void:
	var g0 := at - half
	var g1 := at + half
	for x in [g0.x + 0.04, g1.x - 0.04]:
		var p := _gp(Vector2(x, g1.y - 0.02), 0.0, origin)
		_rect(p + Vector2(-1, -7), 2, 7, ArtKit.WOOD[2])
	_quad(_gp(g0, 7.0, origin), _gp(Vector2(g1.x, g0.y), 7.0, origin), _gp(g1, 7.0, origin), _gp(Vector2(g0.x, g1.y), 7.0, origin),
		ArtKit.WOOD[0].lightened(0.08))
	_quad(_gp(Vector2(g0.x, g1.y), 7.0, origin), _gp(g1, 7.0, origin), _gp(g1, 5.5, origin), _gp(Vector2(g0.x, g1.y), 5.5, origin),
		ArtKit.WOOD[2])
	for i in 1 + ArtKit.pick(seed_value, 130, 2):
		var m := _gp(at + Vector2(-0.1 + i * 0.16, 0.0), 7.0, origin)
		_rect(m + Vector2(-1, -3), 2, 3, Color("c8a060"))
		_rect(m + Vector2(-1, -3), 2, 1, Color("f0e6c8"))


static func _flowers(o: Vector2, seed_value: int) -> void:
	for i in 6:
		var p := o + Vector2(roundf((ArtKit.hash01(seed_value, 80 + i) - 0.5) * 10.0), roundf((ArtKit.hash01(seed_value, 90 + i) - 0.5) * 5.0))
		_rect(p + Vector2(0, -2), 1, 2, ArtKit.LEAF[2])
		var col: Color = TownFloor.FLOWERS[ArtKit.pick(seed_value, 100 + i, TownFloor.FLOWERS.size())]
		_rect(p + Vector2(0, -3), 2, 1, col)
