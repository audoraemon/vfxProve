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
			_fence(at, at + size, origin, 6.0)
		Decor.Kind.GARDEN:
			_garden(at, size, seed_value, origin)
		Decor.Kind.BUSH:
			_bush(o, seed_value, 1.0)
		Decor.Kind.ROCK:
			_rock(o, seed_value)
		Decor.Kind.OAK, Decor.Kind.PINE:
			PropArt.tree(o, 30.0 + ArtKit.hash01(seed_value, 3) * 16.0, 0 if kind == Decor.Kind.OAK else 1, seed_value)
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
	_rect(o + Vector2(-3, -6), 6, 6, ArtKit.WOOD[1])
	_rect(o + Vector2(-3, -6), 2, 6, ArtKit.WOOD[2])
	_rect(o + Vector2(2, -6), 1, 6, ArtKit.WOOD[0])
	ArtKit.blob(o + Vector2(0, -6), Vector2(3, 1.3), ArtKit.WOOD[0], 0.0, 8)
	ArtKit.blob(o + Vector2(0, -6), Vector2(1.8, 0.7), ArtKit.WOOD[2], 0.0, 6)
	for y in [-2.0, -5.0]:
		ArtKit.line(o + Vector2(-3, y), o + Vector2(3, y), Color(0.2, 0.15, 0.12, 0.9))
	ArtKit.line(o + Vector2(-3, 0), o + Vector2(3, 0), ArtKit.ink(0.6))


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


static func _fence(a: Vector2, b: Vector2, origin: Vector2, tall: float) -> void:
	var n := maxi(int(a.distance_to(b) / 0.45), 1)
	var prev := Vector2.INF
	for i in n + 1:
		var g := a.lerp(b, float(i) / n)
		var p := _gp(g, 0.0, origin)
		_rect(p + Vector2(-1, -tall), 2, tall, ArtKit.WOOD[2])
		_rect(p + Vector2(0, -tall), 1, tall, ArtKit.WOOD[1])
		if prev != Vector2.INF:
			for hh in [tall * 0.4, tall * 0.8]:
				ArtKit.line(_gp(prev, hh, origin), _gp(g, hh, origin), PropArt.ROPE)
		prev = g


static func _garden(at: Vector2, size: Vector2, seed_value: int, origin: Vector2) -> void:
	var g0 := at
	var g1 := at + size
	_quad(_gp(g0, 0.0, origin), _gp(Vector2(g1.x, g0.y), 0.0, origin), _gp(g1, 0.0, origin),
		_gp(Vector2(g0.x, g1.y), 0.0, origin), ArtKit.SOIL[0])
	_fence(g0, Vector2(g1.x, g0.y), origin, 4.0)
	_fence(g0, Vector2(g0.x, g1.y), origin, 4.0)
	var n := int(size.x / 0.14) * int(size.y / 0.14)
	var cols := maxi(int(size.x / 0.14), 1)
	for k in n:
		var g := g0 + Vector2((k % cols + 0.5) * 0.14, (floori(float(k) / cols) + 0.5) * 0.14)
		if not Rect2(g0, size).has_point(g):
			continue
		var p := _gp(g, 0.0, origin)
		ArtKit.blob(p + Vector2(0, -1), Vector2(2, 1.3), ArtKit.LEAF[1], 0.0, 6)
		ArtKit.blob(p + Vector2(-0.5, -2), Vector2(1.1, 0.7), ArtKit.LEAF[0], 0.0, 6)
		if ArtKit.hash01(seed_value, 10 + k) < 0.45:
			var col: Color = TownFloor.FLOWERS[ArtKit.pick(seed_value, 40 + k, TownFloor.FLOWERS.size())]
			_rect(p + Vector2(0, -3), 1, 1, col)
	_fence(Vector2(g0.x, g1.y), g1, origin, 4.0)
	_fence(Vector2(g1.x, g0.y), g1, origin, 4.0)


static func _bush(o: Vector2, seed_value: int, scale: float) -> void:
	var pts: Array[Vector3] = []
	for i in 3:
		pts.append(Vector3((ArtKit.hash01(seed_value, 20 + i) - 0.5) * 6.0 * scale, -3.0 - ArtKit.hash01(seed_value, 30 + i) * 3.0,
			(3.0 + ArtKit.hash01(seed_value, 40 + i) * 2.0) * scale))
	for p in pts:
		ArtKit.blob(o + Vector2(p.x, p.y), Vector2(p.z + 1.0, p.z * 0.8 + 1.0), ArtKit.OAK[3], 0.0)
	for p in pts:
		ArtKit.blob(o + Vector2(p.x, p.y + 0.5), Vector2(p.z, p.z * 0.8), ArtKit.OAK[2], 0.0)
	for p in pts:
		ArtKit.blob(o + Vector2(p.x - 0.5, p.y - 0.5), Vector2(p.z * 0.75, p.z * 0.6), ArtKit.OAK[1], 0.0)
	ArtKit.blob(o + Vector2(pts[0].x - 1.0, pts[0].y - 1.5), Vector2(1.5, 1.0), ArtKit.OAK[0], 0.0, 6)


static func _rock(o: Vector2, seed_value: int) -> void:
	var r := 4.0 + ArtKit.hash01(seed_value, 50) * 5.0
	var outline := Color("3c3a38")
	ArtKit.blob(o + Vector2(0, -r * 0.6), Vector2(r + 1.0, r * 0.75 + 1.0), outline, 0.0, 7)
	ArtKit.blob(o + Vector2(0, -r * 0.6), Vector2(r, r * 0.75), TownFloor.PEBBLE[1], 0.0, 7)
	ArtKit.blob(o + Vector2(-r * 0.25, -r * 0.8), Vector2(r * 0.6, r * 0.45), TownFloor.PEBBLE[0], 0.0, 6)
	if ArtKit.hash01(seed_value, 51) < 0.5:
		var o2 := o + Vector2(r * 0.9, 0)
		ArtKit.blob(o2 + Vector2(0, -r * 0.35), Vector2(r * 0.55 + 1.0, r * 0.4 + 1.0), outline, 0.0, 6)
		ArtKit.blob(o2 + Vector2(0, -r * 0.35), Vector2(r * 0.55, r * 0.4), TownFloor.PEBBLE[2], 0.0, 6)
	ArtKit.blob(o + Vector2(r * 0.3, -r * 0.1), Vector2(r * 0.5, r * 0.2), Color(0.35, 0.45, 0.2, 0.8), 0.0, 5)


static func _lamp(o: Vector2) -> void:
	_rect(o + Vector2(-1, -14), 2, 14, ArtKit.TIMBER_DARK)
	_rect(o + Vector2(-1, -14), 5, 1, ArtKit.TIMBER_DARK)
	var l := o + Vector2(2, -13)
	_rect(l, 3, 4, ArtKit.IRON)
	_rect(l + Vector2(0.5, 0.5), 2, 3, ArtKit.GLOW)
	_rect(o + Vector2(-2, -1), 4, 1, ArtKit.TIMBER_DARK)


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


static func _scarecrow(o: Vector2) -> void:
	_rect(o + Vector2(0, -15), 1, 15, ArtKit.WOOD[2])
	_rect(o + Vector2(-4, -11), 9, 1, ArtKit.WOOD[2])
	_rect(o + Vector2(-2, -11), 5, 5, CLOTH)
	_rect(o + Vector2(-4, -11), 2, 2, STRAW)
	_rect(o + Vector2(3, -11), 2, 2, STRAW)
	ArtKit.blob(o + Vector2(0.5, -14), Vector2(2, 2), STRAW, 0.0, 6)
	ArtKit.poly(PackedVector2Array([o + Vector2(-3, -16), o + Vector2(4, -16), o + Vector2(0.5, -20)]), ArtKit.WOOD[2], 0.0)


static func _signpost(o: Vector2) -> void:
	_rect(o + Vector2(-1, -12), 2, 12, ArtKit.WOOD[2])
	_rect(o + Vector2(-5, -11), 9, 4, ArtKit.WOOD[1])
	_rect(o + Vector2(-5, -11), 9, 1, ArtKit.WOOD[0])
	ArtKit.line(o + Vector2(-4, -9), o + Vector2(2, -9), ArtKit.ink(0.5))


static func _reeds(o: Vector2, seed_value: int) -> void:
	for i in 10:
		var x := (ArtKit.hash01(seed_value, 60 + i) - 0.5) * 12.0
		var tall := 6.0 + ArtKit.hash01(seed_value, 70 + i) * 8.0
		var col: Color = ArtKit.LEAF[i % 3]
		_rect(o + Vector2(roundf(x), -tall), 1, tall, col)
		if i % 3 == 0:
			_rect(o + Vector2(roundf(x), -tall - 2.0), 1, 3, Color("5a3a22"))


static func _flowers(o: Vector2, seed_value: int) -> void:
	for i in 6:
		var p := o + Vector2(roundf((ArtKit.hash01(seed_value, 80 + i) - 0.5) * 10.0), roundf((ArtKit.hash01(seed_value, 90 + i) - 0.5) * 5.0))
		_rect(p + Vector2(0, -2), 1, 2, ArtKit.LEAF[2])
		var col: Color = TownFloor.FLOWERS[ArtKit.pick(seed_value, 100 + i, TownFloor.FLOWERS.size())]
		_rect(p + Vector2(0, -3), 2, 1, col)
