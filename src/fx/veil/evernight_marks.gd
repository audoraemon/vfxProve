class_name EvernightMarks
extends RefCounted
## Evernight's marks on the people it claims and the ground it takes them from (Veil review 2, spec 5; looks only: nothing here decides
## who is claimed or taken, or when -- EvernightFx does, and tells these pieces).
## - Claim: one small follower per claimed person (at most a take's group, 10, a cast): a pool of shadow spreading under his feet and the
##   dark climbing him from the ground up, its rim reaching his head as his take comes, so the god reads how long each has left. It
##   follows him as he walks; let go, it falls away quickly and leaves nothing. It never writes to the person.
## - Stains: every shadow the night leaves where it took someone, ONE drawn piece on the ground layer for the whole night (a night can
##   leave more than 200): a fallen figure's shadow lying flat in the iso plane, redrawn only while one fades in or the dawn fades them.
## Scatter (each stain's turn, each claim's flicker) comes from instance ids and fixed hashes, never the shared random stream.

## The claims' absolute z: over the night's shade and air (EvernightSky.Z_SHADE / Z_AIR), so the multiply never swallows them, and
## under the aim (Targeting, absolute 5), so the ring and its previews stay readable over them (VRF1).
const Z_CLAIM := 4
## The dark climbs this high (pixels: Person.SPRITE_BOX's height and a little over; figure() is its outline).
const BODY_H := 20.0
## The pool under the claimed: from this radius to this (ground units) as the take comes.
const POOL_FROM := 0.18
const POOL_TO := 0.46
## A claim shows over this long, and falls away over this long when let go.
const FADE_IN := 0.35
const FALL := 0.4
## A stain fades in over this long when its person is taken.
const STAIN_IN := 0.45
## A stain's fill and its rim (a faint violet edge, so the shadow still reads under the night's multiply).
const STAIN := Color(0.03, 0.02, 0.06, 0.86)
const STAIN_RIM := Color(0.73, 0.55, 1.0, 0.30)


## The dark eating one claimed person until his take (`wait` seconds), following him; `let_go()` makes it fall away.
class Claim extends Node2D:
	var who_id := 0
	var wait := 2.0
	var age := 0.0
	## Seconds since it was let go (-1: still eating).
	var gone := -1.0
	var clock := 0.0
	var phase := 0.0

	func _init(who: Person, wait_s: float) -> void:
		who_id = who.get_instance_id()
		wait = maxf(wait_s, 0.1)
		phase = float(who_id % 97) * 0.37
		z_as_relative = false
		z_index = EvernightMarks.Z_CLAIM
		position = Iso.ground_to_screen(who.ground_pos)

	## How far the dark has climbed, 0..1 (1 = at his head: his take).
	func progress() -> float:
		var k := clampf(age / wait, 0.0, 1.0)
		return k * (1.0 - gone / EvernightMarks.FALL) if gone >= 0.0 else k

	## Let go (he reached the light, went in, was spared, died, or the night ended): the dark falls away and leaves nothing.
	func let_go() -> void:
		if gone < 0.0:
			gone = 0.0

	func _process(delta: float) -> void:
		age += delta
		clock += delta
		var p := instance_from_id(who_id) as Person
		if gone >= 0.0:
			gone += delta
			if gone >= EvernightMarks.FALL:
				queue_free()
				return
		elif p == null or not p.is_alive() or p.inside:
			let_go()
		if p != null and p.is_alive():
			position = Iso.ground_to_screen(p.ground_pos)
		queue_redraw()

	func _draw() -> void:
		var a := clampf(age / EvernightMarks.FADE_IN, 0.0, 1.0)
		if gone >= 0.0:
			a *= 1.0 - clampf(gone / EvernightMarks.FALL, 0.0, 1.0)
		if a <= 0.0:
			return
		var k := progress()
		# The pool, spreading under his feet.
		var semi := Iso.radius_to_screen(lerpf(EvernightMarks.POOL_FROM, EvernightMarks.POOL_TO, sqrt(k)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, semi.y / semi.x))
		draw_circle(Vector2.ZERO, semi.x * 1.12, Color(VeilParts.VEIL, 0.10 * a))
		draw_circle(Vector2.ZERO, semi.x, Color(VeilParts.DUSK.darkened(0.55), 0.72 * a))
		draw_circle(Vector2.ZERO, semi.x * 0.68, Color(VeilParts.BLACK, 0.88 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# The dark climbing him: his own outline filled from the feet to the line it has reached, that line licking upward.
		var top := -EvernightMarks.BODY_H * k
		if top > -1.0:
			return
		var edge := PackedVector2Array()
		var n := 8
		for i in n + 1:
			var f := float(i) / float(n)
			var lick := 2.2 * absf(sin(clock * 5.0 + phase + float(i) * 1.9)) * sin(PI * f)
			edge.append(Vector2(lerpf(-9.0, 9.0, f), top - lick))
		var cut := PackedVector2Array([Vector2(9.0, 3.0), Vector2(-9.0, 3.0)])
		cut.append_array(edge)
		var dark := Color(VeilParts.BLACK, lerpf(0.7, 0.94, k) * a)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(EvernightMarks.figure(), cut):
			draw_colored_polygon(part, dark)
		# Its rim, so the line it has climbed to reads at any zoom.
		for line: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(edge, EvernightMarks.figure()):
			draw_polyline(line, Color(VeilParts.VEIL, 0.85 * a), 1.0)
		# Tendrils reaching above the rim, and motes of dark rising off him.
		for i in 3:
			var x0 := lerpf(-3.0, 3.0, float(i) / 2.0)
			var reach := 2.0 + 3.0 * absf(sin(clock * 3.1 + phase * 1.3 + float(i) * 2.3))
			var sway := 1.5 * sin(clock * 2.3 + float(i))
			draw_line(Vector2(x0, top), Vector2(x0 + sway, top - reach), Color(VeilParts.DUSK.lightened(0.15), 0.85 * a), 1.0)
		for i in 3:
			var rise := fposmod(clock * 9.0 + float(i) * 4.0 + phase, 12.0)
			var mx := 4.0 * sin(phase + float(i) * 2.1)
			draw_rect(Rect2(Vector2(mx, top - rise) - Vector2(0.5, 0.5), Vector2(1.0, 1.0)), Color(VeilParts.BLACK, 0.8 * a * (1.0 - rise / 12.0)))
		# At the end only his pale eyes are left in the dark.
		if k > 0.8:
			var e := Color(VeilParts.SILVER, a * (k - 0.8) / 0.2)
			draw_rect(Rect2(-2.0, -16.0, 1.0, 1.0), e)
			draw_rect(Rect2(1.0, -16.0, 1.0, 1.0), e)


## A standing figure's outline (pixels, feet at the origin), a little over Person.SPRITE_BOX, that the dark fills as it climbs.
static func figure() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-4.0, 1.0), Vector2(-4.2, -8.0), Vector2(-6.0, -12.5), Vector2(-2.4, -14.2), Vector2(-3.2, -16.5),
		Vector2(-2.2, -20.0), Vector2(2.2, -20.0), Vector2(3.2, -16.5), Vector2(2.4, -14.2), Vector2(6.0, -12.5), Vector2(4.2, -8.0),
		Vector2(4.0, 1.0)])


## Every shadow the night left, one node on the ground layer (ground units: the layer carries Iso.BASIS, so each lies flat in the iso
## plane). One triangle list for all of them, rebuilt only when one is added, while one fades in, or while `fade` changes.
class Stains extends Node2D:
	## Each: [where (ground), turn (radians), mirrored, the clock when added].
	var marks: Array = []
	var fade := 1.0
	var clock := 0.0
	var fx_id := 0
	var _dirty := true
	## The figure's convex parts (ground units, head toward +x, 0.8 long), built once.
	static var _parts: Array = []

	func _init() -> void:
		z_index = 2  # under the night wash's torch rings (3)

	## His shadow where he was taken (`id`: his instance id, which turns and mirrors it: no luck).
	func add(at_g: Vector2, id: int) -> void:
		var h := fposmod(sin(float(id % 100003) * 12.9898) * 43758.5453, 1.0)
		marks.append([at_g, h * TAU, (id / 7) % 2 == 1, clock])
		_dirty = true

	func set_fade(f: float) -> void:
		if not is_equal_approx(f, fade):
			fade = f
			_dirty = true

	func _process(delta: float) -> void:
		if fx_id != 0 and instance_from_id(fx_id) == null:
			queue_free()
			return
		clock += delta
		if not marks.is_empty() and clock - float(marks[-1][3]) < EvernightMarks.STAIN_IN + delta:
			_dirty = true
		if _dirty:
			_dirty = false
			queue_redraw()

	static func parts() -> Array:
		if not _parts.is_empty():
			return _parts
		var head := PackedVector2Array()
		for i in 10:
			head.append(Vector2(0.30, 0.0) + Vector2.from_angle(TAU * float(i) / 10.0) * 0.09)
		_parts = [head, PackedVector2Array([Vector2(0.22, -0.11), Vector2(0.22, 0.11), Vector2(-0.06, 0.085), Vector2(-0.06, -0.085)])]
		for limb in [[Vector2(0.18, -0.09), Vector2(0.04, -0.31), 0.045], [Vector2(0.19, 0.09), Vector2(0.34, 0.25), 0.045],
				[Vector2(-0.03, -0.05), Vector2(-0.42, -0.13), 0.055], [Vector2(-0.03, 0.05), Vector2(-0.40, 0.14), 0.055]]:
			var a: Vector2 = limb[0]
			var b: Vector2 = limb[1]
			var side := (b - a).orthogonal().normalized() * float(limb[2])
			_parts.append(PackedVector2Array([a + side, b + side * 0.7, b - side * 0.7, a - side]))
		return _parts

	func _draw() -> void:
		if marks.is_empty() or fade <= 0.0:
			return
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var idx := PackedInt32Array()
		var shape := parts()
		for layer in 2:
			for m: Array in marks:
				var grow := clampf((clock - float(m[3])) / EvernightMarks.STAIN_IN, 0.0, 1.0)
				var a := grow * fade
				if a <= 0.0:
					continue
				var col := Color(EvernightMarks.STAIN_RIM, EvernightMarks.STAIN_RIM.a * a) if layer == 0 \
					else Color(EvernightMarks.STAIN, EvernightMarks.STAIN.a * a)
				var xf := Transform2D(float(m[1]), m[0])
				if bool(m[2]):
					xf = xf * Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2.ZERO)
				for part: PackedVector2Array in shape:
					var c := Vector2.ZERO
					for v in part:
						c += v
					c /= float(part.size())
					var base := pts.size()
					for v in part:
						# The rim: the part a little larger, under the fill.
						pts.append(xf * (c + (v - c) * 1.35 + (v - c).normalized() * 0.025 if layer == 0 else v))
						cols.append(col)
					for i in range(1, part.size() - 1):
						idx.append_array([base, base + i, base + i + 1])
		if not idx.is_empty():
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)
