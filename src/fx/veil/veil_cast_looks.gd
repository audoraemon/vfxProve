class_name VeilCastLooks
extends RefCounted
## The cast looks of the Veil review (Task B, spec 4 and 5): what Slumber, Cloak of Night, Dreamless and Shadow Play draw while
## they are cast, and the mark a person Blight made ill carries home. Drawing only: nothing here touches the crowd's state or the
## shared random stream (particles get a seed of their own, made from the cast point and a constant), and every number a look
## needs from the rules (a reach, a time) is handed in by the effect. Each piece frees itself when its time is up; a piece an
## effect made with FxTimeline.track() also goes with the effect. The two that outlive their cast (ShadeFade, BlightMark) join
## SolarisPit.GROUP and free themselves.

## The rot of Blight's mark: a deep green, low in red, so that after the town's day grade (which lifts and warms it) it is still green,
## apart from gold and the Veil's violet on the badge's dark plate (VRB8: day (108,197,65), dusk (93,179,62) measured).
const ROT := Color("3c9646")
## Silver of the threads and the dust.
const SILVER := Color("cfd3e6")
## A pale violet-silver for the glyph over Slumber.
const PALE := Color("e8dcff")


## A seed for a look's own scatter: from where it was cast and a constant, never from the town's stream.
static func seed_of(at: Vector2, salt: int) -> int:
	return int(hash(Vector3i(roundi(at.x * 64.0), roundi(at.y * 64.0), salt)))


## Pixel particles with their own seed, tracked by `fx` (FxParts.particles() draws its seed from ctx.rng, which a look must not).
static func particles(fx: FxTimeline, parent: Node, screen_pos: Vector2, shape: PixelParticles.Shape, ramp: Array,
		seed_value: int) -> PixelParticles:
	var p := PixelParticles.new()
	p.rng.seed = seed_value
	p.shape = shape
	p.ramp = PackedColorArray(ramp)
	p.position = screen_pos
	fx.track(p, parent)
	return p


## How tall `p` stands on screen, in pixels (the shimmer's own reading).
static func head_of(p: Person) -> float:
	if p == null or not is_instance_valid(p):
		return 20.0
	var design: String = p._design()
	if PeopleArt.has(design):
		return (PeopleArt.info(design)[2] as Vector2).y
	return 20.0


## A wave across the ground from the cast point out to `r` (ground units; drawn on ctx.ground, so the iso basis makes it an
## ellipse of the true reach). MIST: a soft front of puffs rolling out over a faint fill (Slumber, Dreamless). RIPPLE: three dark
## bands with a thin rim crossing the ground one after another (Shadow Play).
class Wave extends Node2D:
	enum Kind { MIST, RIPPLE }
	var kind := Kind.MIST
	var r := 1.5
	var rim := Color(VeilParts.VEIL, 0.4)
	var fill := Color(VeilParts.DUSK, 0.16)
	## A thin line at the front (alpha 0: none).
	var edge := Color(0, 0, 0, 0)
	var grow := 0.6
	var hold := 0.4
	var fade := 0.6
	var clock := 0.0

	func life() -> float:
		return grow + hold + fade

	func _process(delta: float) -> void:
		clock += delta
		if clock >= life():
			queue_free()
			return
		queue_redraw()

	func _alpha() -> float:
		if clock <= grow + hold:
			return clampf(clock / 0.08, 0.0, 1.0)
		return clampf(1.0 - (clock - grow - hold) / fade, 0.0, 1.0)

	static func _out(k: float) -> float:
		k = clampf(k, 0.0, 1.0)
		return 1.0 - (1.0 - k) * (1.0 - k)

	func _draw() -> void:
		var a := _alpha()
		if a <= 0.0:
			return
		if kind == Kind.RIPPLE:
			for j in 3:
				var kj := (clock - float(j) * 0.2) / grow
				if kj <= 0.0:
					continue
				var f := r * _out(kj)
				var aj := a * (1.0 - 0.22 * float(j)) * (1.0 - 0.45 * clampf(kj - 1.0, 0.0, 1.0))
				draw_arc(Vector2.ZERO, maxf(f - 0.14, 0.01), 0.0, TAU, 72, Color(fill, fill.a * aj), 0.3)
				draw_arc(Vector2.ZERO, f, 0.0, TAU, 72, Color(rim, rim.a * aj), 0.07)
			return
		var front := r * _out(clock / grow)
		if front <= 0.0:
			return
		draw_circle(Vector2.ZERO, front, Color(fill, fill.a * a))
		var n := clampi(int(r * 18.0), 22, 72)
		var big := clampf(r / 1.5, 1.0, 1.8)
		for i in n:
			var fi := float(i)
			var ang := TAU * fi / float(n) + 0.25 * sin(fi * 1.7)
			var wob := 0.05 * r * sin(clock * 4.0 + fi * 2.1)
			var rad := (0.17 + 0.06 * sin(fi * 3.1 + clock * 2.0)) * big
			var dir := Vector2.from_angle(ang)
			draw_circle(dir * maxf(front * 0.72 + wob, 0.0), rad * 0.8, Color(rim, rim.a * a * 0.45))
			draw_circle(dir * maxf(front + wob, 0.0), rad, Color(rim, rim.a * a))
		if edge.a > 0.0:
			draw_arc(Vector2.ZERO, front, 0.0, TAU, 72, Color(edge, edge.a * a), 0.05)


## Slumber's closed eye: over the middle of the reach an eye opens, blinks shut at the landing, and fades (screen space).
class EyeGlyph extends Node2D:
	## '#' a pale lid, 'p' the violet pupil; each lit pixel gets a dark outline, so the lids read against dusk as well as lit stone.
	const OPEN := ["....#####....", "..##.....##..", ".#...ppp...#.", "#...ppppp...#", ".#...ppp...#.", "..##.....##..",
		"....#####...."]
	const HALF := [".............", ".............", ".###########.", "#...ppppp...#", ".#...ppp...#.", "..##.....##..",
		"....#####...."]
	const SHUT := [".............", ".............", ".............", "#...........#", ".##.......##.", "...#######...",
		"...#..#..#..."]
	## When it shuts (the landing).
	var shut_at := 0.6
	var life := 1.6
	var px := 2.0
	var clock := 0.0

	func _process(delta: float) -> void:
		clock += delta
		if clock >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(clock / 0.15, 0.0, 1.0) * clampf((life - clock) / 0.45, 0.0, 1.0)
		var rows: Array = OPEN
		if clock >= shut_at:
			rows = SHUT
		elif clock >= shut_at - 0.1:
			rows = HALF
		var w := String(rows[0]).length()
		var lift := -minf(maxf(clock - shut_at, 0.0), 1.0) * 5.0
		for pass_i in 2:
			for y in rows.size():
				var row := String(rows[y])
				for x in w:
					if row[x] == ".":
						continue
					var at := Vector2((float(x) - float(w) * 0.5) * px, (float(y) - 3.5) * px + lift).round()
					if pass_i == 0:
						draw_rect(Rect2(at - Vector2.ONE, Vector2.ONE * (px + 2.0)), Color(VeilParts.BLACK, 0.85 * a))
					else:
						draw_rect(Rect2(at, Vector2.ONE * px), Color(VeilCastLooks.PALE if row[x] == "#" else VeilParts.VEIL, a))


## Slumber's heavy silver dust sinking onto each sleeper: a few specks falling from above the head to the shoulders (screen
## space; one node for every sleeper of the cast).
class DustFall extends Node2D:
	var spots: Array[Vector2] = []
	var life := 1.2
	var clock := 0.0

	func _process(delta: float) -> void:
		clock += delta
		if clock >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		for i in spots.size():
			var base: Vector2 = spots[i]
			for j in 12:
				var s := fposmod(float(i * 7 + j * 13) * 0.618034, 1.0)
				var k := (clock - s * 0.35) / 0.6
				if k < 0.0 or k > 1.3:
					continue
				var kk := clampf(k, 0.0, 1.0)
				var y := lerpf(-40.0, -8.0, kk * kk)
				var x := (s * 2.0 - 1.0) * 8.0 + sin(clock * 5.0 + float(j)) * 0.8
				var a := 1.0 if k <= 1.0 else (1.3 - k) / 0.3
				var sz := 2.0 if j % 2 == 0 else 1.0
				var at := (base + Vector2(x, y)).round()
				draw_rect(Rect2(at + Vector2(0, sz), Vector2(sz, 1)), Color(VeilParts.BLACK, 0.4 * a))
				draw_rect(Rect2(at, Vector2(sz, sz)), Color(VeilCastLooks.SILVER, 0.95 * a))


## Cloak of Night's cast: a dark cloth unfurls over the click, a strand flies from it to each person it hides, and wraps him
## round from feet to head (screen space; one node for the cast, following each person by instance id).
class CloakCast extends Node2D:
	## The cloth's top, over the click.
	var cloth_at := Vector2.ZERO
	var ids: Array[int] = []
	## When the strands arrive (the cast's T_LAND).
	var land := 0.5
	var clock := 0.0
	const UNFURL := 0.32
	const FLY_FROM := 0.18
	const WRAP := 0.6

	func life() -> float:
		return land + WRAP + 0.15

	func _process(delta: float) -> void:
		clock += delta
		if clock >= life():
			queue_free()
			return
		queue_redraw()

	func _who(id: int) -> Person:
		return instance_from_id(id) as Person

	func _draw() -> void:
		_draw_cloth()
		for id in ids:
			var p := _who(id)
			if p == null or not p.is_alive() or p.inside:
				continue
			var feet := Iso.ground_to_screen(p.ground_pos)
			var head := VeilCastLooks.head_of(p)
			_draw_strand(feet + Vector2(0, -head * 0.6))
			_draw_wrap(feet, head)

	func _draw_cloth() -> void:
		var e := clampf(clock / UNFURL, 0.0, 1.0)
		e = 1.0 - (1.0 - e) * (1.0 - e)
		var shrink := clampf((clock - land) / 0.35, 0.0, 1.0)
		var s := e * (1.0 - shrink)
		if s <= 0.02:
			return
		var w := 26.0 * s
		var h := 18.0 * s
		var pts := PackedVector2Array()
		pts.append(cloth_at + Vector2(-w * 0.5, 0))
		pts.append(cloth_at + Vector2(w * 0.5, 0))
		var n := 6
		for i in range(n, -1, -1):
			var u := float(i) / float(n)
			var x := lerpf(-w * 0.5, w * 0.5, u) + sin(clock * 6.0 + u * 5.0) * 1.5 * s
			var y := h + sin(clock * 9.0 + u * 9.0) * 2.0 * s
			pts.append(cloth_at + Vector2(x, y))
		draw_colored_polygon(pts, Color(VeilParts.BLACK, 0.85))
		var line := pts.duplicate()
		line.append(pts[0])
		draw_polyline(line, Color(VeilParts.VEIL, 0.75), 1.0)
		# Its fold catching the light.
		draw_line(cloth_at + Vector2(-w * 0.2, 1), cloth_at + Vector2(-w * 0.1, h * 0.8), Color(VeilParts.DUSK, 0.9), 1.0)

	static func _bez(a: Vector2, c: Vector2, b: Vector2, u: float) -> Vector2:
		return a.lerp(c, u).lerp(c.lerp(b, u), u)

	func _draw_strand(to: Vector2) -> void:
		var head_k := clampf((clock - FLY_FROM) / (land - FLY_FROM), 0.0, 1.0)
		var tail_k := clampf((clock - land) / 0.25, 0.0, 1.0)
		if head_k <= 0.0 or tail_k >= 1.0:
			return
		var from := cloth_at + Vector2(0, 8)
		var ctrl := (from + to) * 0.5 + Vector2(0, -26)
		var pts := PackedVector2Array()
		var n := 14
		for i in n + 1:
			var u := lerpf(tail_k, head_k, float(i) / float(n))
			pts.append(_bez(from, ctrl, to, u))
		draw_polyline(pts, Color(VeilParts.BLACK, 0.85), 3.0)
		draw_polyline(pts, Color(VeilParts.VEIL, 0.8), 1.0)
		if head_k < 1.0:
			draw_rect(Rect2(pts[pts.size() - 1].round() - Vector2.ONE, Vector2(3, 3)), Color(VeilCastLooks.PALE, 0.9))

	func _draw_wrap(feet: Vector2, head: float) -> void:
		var k := (clock - land) / WRAP
		if k <= 0.0 or k >= 1.25:
			return
		var reveal := clampf(k, 0.0, 1.0)
		var a := clampf((1.25 - k) / 0.4, 0.0, 1.0)
		var n := 36
		var prev := Vector2.INF
		for i in n + 1:
			var u := float(i) / float(n)
			if u > reveal:
				break
			var ang := u * TAU * 2.5 + clock * 5.0
			var at := feet + Vector2(cos(ang) * 6.5, -u * (head + 2.0) + sin(ang) * 2.2)
			if prev != Vector2.INF:
				var front := sin(ang) > 0.0
				draw_line(prev, at, Color(VeilParts.BLACK, 0.8 * a), 3.0 if front else 2.0)
				if front:
					draw_line(prev, at, Color(VeilParts.VEIL, 0.85 * a), 1.0)
			prev = at


## Dreamless's thread: over each sitter a thin silver thread rises and thins as his rest runs out (read from the effect), and
## snaps when he is found or freed (screen space; one node for the cast).
class Threads extends Node2D:
	var fx_id := 0
	## [person id, screen base, since (clock), snapped at (clock; -1: not), height at the snap]
	var entries: Array = []
	var clock := 0.0
	const SNAP := 0.9

	func add(p: Person) -> void:
		entries.append([p.get_instance_id(), Iso.ground_to_screen(p.ground_pos) + Vector2(0, -9), clock, -1.0, 0.0])

	func _fx() -> DreamlessFx:
		return instance_from_id(fx_id) as DreamlessFx

	## Whether he still rests under this cast.
	static func resting(fx: DreamlessFx, p: Person) -> bool:
		return fx != null and p != null and p.is_alive() and fx.rests(p)

	## The share of the rest still to run (1 at the sit, 0 at the find).
	func _left(fx: DreamlessFx) -> float:
		return clampf(fx.rest_left() / DreamlessFx.REST, 0.0, 1.0) if fx != null else 0.0

	func _height(fx: DreamlessFx, since: float) -> float:
		var grow := clampf((clock - since) / 0.5, 0.0, 1.0)
		return lerpf(16.0, 28.0, _left(fx)) * grow

	## How many threads are still up (tests).
	func up() -> int:
		var n := 0
		for e: Array in entries:
			if float(e[3]) < 0.0:
				n += 1
		return n

	func _process(delta: float) -> void:
		clock += delta
		var fx := _fx()
		var live := false
		for e: Array in entries:
			if float(e[3]) >= 0.0:
				live = live or clock - float(e[3]) < SNAP
				continue
			var p := instance_from_id(int(e[0])) as Person
			if resting(fx, p):
				e[1] = Iso.ground_to_screen(p.ground_pos) + Vector2(0, -9)
				live = true
			else:
				e[4] = _height(fx, float(e[2]))
				e[3] = clock
				live = true
		if not live and (fx == null or not entries.is_empty()):
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var fx := _fx()
		var left := _left(fx)
		for e: Array in entries:
			var base: Vector2 = e[1]
			if float(e[3]) < 0.0:
				_thread(base, _height(fx, float(e[2])), left, 0.0, 1.0)
			else:
				var ks := (clock - float(e[3])) / SNAP
				if ks >= 1.0:
					continue
				var h: float = e[4]
				var a := 1.0 - ks * ks
				# The snap: a spark where it breaks; the top drifts off upward, the stub falls back.
				_thread(base + Vector2(0, -h * 0.5 - ks * 16.0), h * 0.5, 1.0, h * 0.5, a)
				_thread(base + Vector2(0, ks * 2.0), h * 0.5 * (1.0 - ks), 1.0, 0.0, a)
				if ks < 0.6:
					# The break: a flash of pale silver, two sparks flung off sideways.
					var at := base + Vector2(0, -h * 0.5)
					var ka := 1.0 - ks / 0.6
					draw_rect(Rect2((at - Vector2(2, 2)).round(), Vector2(5, 5)), Color(VeilParts.BLACK, 0.5 * ka))
					draw_rect(Rect2((at - Vector2(1, 1)).round(), Vector2(3, 3)), Color(VeilCastLooks.PALE, ka))
					for sgn: float in [-1.0, 1.0]:
						draw_rect(Rect2((at + Vector2(sgn * (2.0 + ks * 14.0), -ks * 6.0)).round(), Vector2(2, 2)), Color(VeilCastLooks.SILVER, ka))

	## One thread of height `h` up from `base`: a wavering line of single pixels, frayed (gaps) as `left` runs low.
	func _thread(base: Vector2, h: float, left: float, phase: float, a: float) -> void:
		var steps := int(h)
		for y in steps:
			var fy := float(y) + phase
			var fray := fposmod(sin(fy * 12.9898) * 43758.5453, 1.0)
			if fray > left + 0.7:
				continue
			var sway := sin(fy * 0.35 + clock * 1.6) * 1.6 * (float(y) / maxf(h, 1.0))
			var al := (0.8 + 0.2 * left) * a * (1.0 - 0.3 * float(y) / maxf(h, 1.0))
			var at := (base + Vector2(sway, -float(y))).round()
			# A dark line either side, so the silver reads on bright cobbles as well as in the dark.
			draw_rect(Rect2(at + Vector2(-1, 0), Vector2(3, 1)), Color(VeilParts.BLACK, 0.7 * al))
			draw_rect(Rect2(at, Vector2.ONE), Color(VeilCastLooks.SILVER, al))
		if h > 4.0:
			# A bead of silver climbing it.
			var b := fposmod(clock * 0.5, 1.0)
			var at := base + Vector2(sin((b * h) * 0.35 + clock * 1.6) * 1.6 * b, -b * h)
			draw_rect(Rect2(at.round() - Vector2(0, 1), Vector2(2, 2)), Color(VeilCastLooks.PALE, a * (1.0 - b) * (0.5 + 0.5 * left)))


## Shadow Play's peel: each shadow lies stretched on the ground from its owner's feet and stands up into him (his own
## silhouette, Person.silhouette_src()), then the black body and silver edge go on (screen space; one node for the cast).
class Peel extends Node2D:
	var ids: Array[int] = []
	var clock := 0.0
	const RISE := 0.7
	const MELT := 0.2

	func _process(delta: float) -> void:
		clock += delta
		if clock >= RISE + MELT:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(clock / RISE, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		var a := 0.92 * clampf(1.0 - (clock - RISE) / MELT, 0.0, 1.0)
		var ky := lerpf(-0.6, 1.0, k)
		var skew := lerpf(0.9, 0.0, k)
		for id in ids:
			var p := instance_from_id(id) as Person
			if p == null or not p.is_alive() or p.inside:
				continue
			var sil := ShadowPlayFx.sil_of(p)
			if sil.size == Vector2.ZERO:
				continue
			var feet := Iso.ground_to_screen(p.ground_pos)
			draw_set_transform_matrix(Transform2D(Vector2(1, 0), Vector2(skew, ky), feet))
			for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				draw_texture_rect_region(PeopleArt.atlas(), Rect2(p.drawn_dst.position + d, p.drawn_dst.size), sil,
					Color(VeilParts.VEIL, 0.55 * a))
			draw_texture_rect_region(PeopleArt.atlas(), p.drawn_dst, sil, Color(VeilParts.BLACK, a))
		draw_set_transform_matrix(Transform2D.IDENTITY)


## Shadow Play in the dark: a soldier's shadow fading where it stands, made an event -- it stretches up thin and pale-edged, a ring
## of silver goes out at its feet, dark motes rise. Outlives the cast (it ends on the same frame): SolarisPit.GROUP, frees itself.
class ShadeFade extends Node2D:
	var sil := Rect2()
	var dst := Rect2()
	var clock := 0.0
	const LIFE := 1.4

	func take(p: Person, seed_value: int) -> void:
		sil = ShadowPlayFx.sil_of(p)
		dst = p.drawn_dst
		position = Iso.ground_to_screen(p.ground_pos)
		add_to_group(SolarisPit.GROUP)
		var m := PixelParticles.new()
		m.rng.seed = seed_value
		m.shape = PixelParticles.Shape.PUFF
		m.ramp = PackedColorArray([Color("3b1470"), Color("1c0c34"), Color("07050c"), Color(0.03, 0.02, 0.05, 0.4)])
		m.gravity = -30.0
		m.drag = 1.2
		m.burst(9, {"radius": 6.0, "speed": Vector2(2, 10), "alt": Vector2(4, 24), "alt_speed": Vector2(16, 40),
			"life": Vector2(0.7, 1.2), "size": Vector2(2, 3), "size_end_mul": 1.3})
		m.show_behind_parent = true  # the motes behind the thinning silhouette, not over it
		add_child(m)

	func _process(delta: float) -> void:
		clock += delta
		if clock >= LIFE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(clock / LIFE, 0.0, 1.0)
		# The ring at the feet.
		var rk := clampf(clock / 0.7, 0.0, 1.0)
		if rk < 1.0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
			draw_arc(Vector2.ZERO, lerpf(4.0, 22.0, rk), 0.0, TAU, 28, Color(VeilCastLooks.SILVER, 0.8 * (1.0 - rk)), 1.5)
			draw_set_transform(Vector2.ZERO)
		if sil.size == Vector2.ZERO or dst.size == Vector2.ZERO:
			return
		var sx := lerpf(1.0, 0.25, k * k)
		var sy := lerpf(1.0, 2.1, k)
		var a := 1.0 - k
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx, sy))
		for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_texture_rect_region(PeopleArt.atlas(), Rect2(dst.position + d, dst.size), sil, Color(VeilCastLooks.SILVER, 0.9 * a))
		draw_texture_rect_region(PeopleArt.atlas(), dst, sil, Color(VeilParts.BLACK, a))
		draw_set_transform(Vector2.ZERO)


## Blight's mark on a person it made ill: a small sickness glyph over the head in the rot colour -- the game's own badge
## (Person.set_badge()), kept up while he walks home sick (until he is indoors) or, a quarry, while he is ill -- and a faint drift of
## rot motes where he passes. A badge another power set is left alone (then only the motes show), and one that replaces ours ends
## our claim. Two casts on one man share the glyph: only the last mark standing lets it go (VRB9). A citizen sent home keeps it until
## indoors; a quarry keeps it while ill_left() runs, hidden while he is inside and back when he comes out (VRB10). SolarisPit.GROUP;
## frees itself, clearing our badge, when he is home, well, dead or gone.
class BlightMark extends Node2D:
	const SICK: Array[int] = [0b00100, 0b01110, 0b11101, 0b11111, 0b01110]
	## The badge's seconds, renewed every frame while he is ill (a badge runs down on its own: one never outlives the mark by more).
	const HOLD := 0.5
	const TRAIL := 6
	const EVERY := 0.3
	var who_id := 0
	## Whether this mark keeps the SICK glyph over him (shared with any other Blight mark on him).
	var owns := false
	## How many live marks keep each person's glyph: person id -> count (drawing only; never read by the town).
	static var _holders := {}
	var clock := 0.0
	var _trail: Array[Vector2] = []
	var _next := 0.0

	func _who() -> Person:
		return instance_from_id(who_id) as Person

	## Starts on `p` (just made ill): the badge goes on unless another power's is up.
	func start(p: Person) -> void:
		who_id = p.get_instance_id()
		add_to_group(SolarisPit.GROUP)
		# Ours to keep when nothing is up, or when another Blight mark's SICK glyph is (then it is shared).
		owns = p.badge_left <= 0.0 or p.badge_glyph == SICK
		if owns:
			_holders[who_id] = int(_holders.get(who_id, 0)) + 1
			if shown(p):
				p.set_badge(SICK, VeilCastLooks.ROT, HOLD)

	## Whether `p` is still ill: a citizen sent home until he is indoors; a quarry while his illness runs (indoors or not).
	static func ill(p: Person) -> bool:
		if p == null or not is_instance_valid(p) or not p.is_alive():
			return false
		if p.home_sick:
			return not p.inside
		return p.ill_left() > 0.0

	## Whether his mark shows now (he is out of doors).
	static func shown(p: Person) -> bool:
		return ill(p) and not p.inside

	func _process(delta: float) -> void:
		var p := _who()
		if not ill(p):
			_drop()
			queue_free()
			return
		clock += delta
		var out := shown(p)
		if owns:
			if p.badge_left > 0.0 and p.badge_glyph != SICK:
				_release()  # another power's badge came over ours: it stays
			elif out:
				p.set_badge(SICK, VeilCastLooks.ROT, HOLD)
			elif p.badge_glyph == SICK:
				p.clear_badge()  # a quarry gone indoors: hidden until he comes out
		visible = out
		if not out:
			return
		if clock >= _next:
			_next = clock + EVERY
			_trail.push_front(Iso.ground_to_screen(p.ground_pos))
			if _trail.size() > TRAIL:
				_trail.pop_back()
		queue_redraw()

	## Gives up this mark's share of the glyph (the count goes down; nothing else).
	func _release() -> void:
		if not owns:
			return
		owns = false
		var n := int(_holders.get(who_id, 1)) - 1
		if n <= 0:
			_holders.erase(who_id)
		else:
			_holders[who_id] = n

	## Lets the glyph go: cleared only when this was the last Blight mark keeping it, and only when it is still SICK.
	func _drop() -> void:
		var was := owns
		_release()
		if not was or _holders.has(who_id):
			return
		var p := _who()
		if p != null and is_instance_valid(p) and p.badge_glyph == SICK:
			p.clear_badge()

	func _exit_tree() -> void:
		_drop()

	## Freed off the tree (no _exit_tree): its share is still given up.
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			_drop()

	func _draw() -> void:
		# Rot motes rising and fading where he walked (the oldest faintest).
		var ph := fposmod(clock / EVERY, 1.0)
		for i in _trail.size():
			var age := (float(i) + ph) / float(TRAIL)
			var at: Vector2 = _trail[i]
			for j in 3:
				var x := (float(j) - 1.0) * 4.0 + sin(clock * 2.0 + float(i * 3 + j)) * 1.5
				var y := -4.0 - age * 16.0 - float(j % 2) * 5.0
				var sz := 2.0 if (i + j) % 2 == 0 else 1.0
				draw_rect(Rect2((at + Vector2(x, y)).round(), Vector2.ONE * sz), Color(VeilCastLooks.ROT, 0.7 * (1.0 - age)))
