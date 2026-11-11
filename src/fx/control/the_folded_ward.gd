class_name FoldedWardFx
extends FxTimeline
## The Folded Ward (Passage, Tier IV): the god folds a square of the town so its edges meet, like a world that wraps
## round. The click lays the square, axis-aligned on the ground grid (a diamond to the eye), HALF to each side of the
## click. It folds over T_FOLD and then holds for SPAN, under the cast's mode (Q/E; extra.mode, NO WAY OUT when none):
##   NO WAY OUT  whoever is inside and walks out across an edge comes back in at the opposite edge, on the same line
##               (out across x = +HALF at y, in at x = -HALF + EDGE_IN at that y; out across a corner, in at the opposite
##               corner), still walking the same way, still going where they were going. They can never leave: they
##               walk out and come back in, again and again. Walking in from outside is free, so the trap fills up.
##   NO WAY IN   whoever is outside and walks in across an edge comes out past the opposite edge, on the same line,
##               EDGE_IN outside it, still walking the same way. Nobody gets in: whoever was only passing through is
##               across in an instant, and whoever meant to be inside (its goal, its street, its post, a hound's prey)
##               is turned away for good -- it walks on outward the way it came out for TURN_AWAY, then mills about
##               outside until the ward is gone, and then goes on to where it meant to be. Leaving is free.
## Where they would come out is not open ground, they come out on the nearest open cell within FoldWard.SEEK on that
## edge's side (inside for NO WAY OUT, outside for NO WAY IN); with none, they are simply stopped at the edge. It takes
## everyone walking there: citizens, soldiers, the town's dogs and cats, visitors from the other side; someone thrown
## across the edge is carried across too. The dead are not moved, and nobody inside a building is touched. Nothing is
## left to luck: the same walk always folds the same way (FoldWard). The god touches nobody and harms nobody: no danger
## and no fright come of the cast; quiet, but for the book entry's "alarm". Use NO WAY OUT under a strike to keep the
## crowd in it, NO WAY IN to keep the guard off a place, or people from a shelter or a gate inside it.
## To the player the square stands as a wall of folded light on all four edges, a person and a half tall (WALL_H):
## translucent, pleated top to bottom like folded paper or silk that shimmers slowly, bright along its top and its foot
## and faint between so the people behind it still show, a faint crease of light on the ground where it stands. Cold
## violet with chevrons across the wall pointing in (NO WAY OUT), or pale gold with chevrons pointing out (NO WAY IN). It
## rises out of the ground as the square folds and sinks back into it as the span ends. Each fold of someone across it
## shows on the wall itself: a ring drawn in where they went into it and a matching one opening on the far wall where
## they come out, with a soft tick. The wall stands in the town's own depth order: its two back edges behind the
## people inside, its two front edges before them (each edge is WALL_SEG-long pieces, each sorted on its own).

const HALF := 3.0
const SPAN := 25.0
const T_FOLD := 0.8
const EDGE_IN := FoldWard.EDGE_IN
## NO WAY IN: how long one turned away walks on outward before it mills.
const TURN_AWAY := 1.5
const OUT := &"out"
const IN := &"in"
## Seconds the crease takes to fade once the span is over.
const FADE := 1.0
## The soft tick of a fold is heard at most once every TICK_EVERY (a crowd at the edge folds many at once).
const TICK_EVERY := 0.25
## Ripples drawn at most (the rule takes everyone; the eye needs only these), and how long one runs.
const RIPPLES := 32
const RIPPLE_LIFE := 0.6
## How far each corner of the crease on the ground is folded in along its edges, and the chevrons per edge of the wall
## and their size (ground units).
const CORNER := 0.45
const CHEVRONS := 5
const CHEVRON := 0.3
## The wall: its height (px; people are drawn some 18 px tall), the length of each piece it stands in (ground units:
## each piece sorts on its own, so the people inside draw before the front edges and after the back ones), and how far
## the ridge of each piece's fold stands out of the edge line (ground units).
const WALL_H := 30.0
const WALL_SEG := 0.5
const PLEAT := 0.09
## Its sheen: the alpha at its bright foot and top, and of the faint sheet between.
const WALL_EDGE_A := 0.7
const WALL_MID_A := 0.1
## Cold violet for NO WAY OUT, pale gold for NO WAY IN: the crease, its bright core, and the dim of the paper.
const VIOLET := Color("a77cff")
const VIOLET_HOT := Color("e8dcff")
const GOLD := Color("f5d27a")
const GOLD_HOT := Color("fff7dc")
const VIOLET_LIFE := [Color("f4eeff"), Color("cdb6ff"), Color("8f62f0"), Color(0.35, 0.2, 0.6, 0.5)]
const GOLD_LIFE := [Color("fffdf0"), Color("ffe9a8"), Color("e8b84a"), Color(0.6, 0.42, 0.12, 0.5)]

var mode := OUT
## Whether the fold holds now, and how many it has carried across, and stopped at the edge.
var holding := false
var folds := 0
var stops := 0
## NO WAY IN: how many times someone was turned away.
var turned := 0
var ward: FoldWard

var _tick_in := 0.0
## [point on the wall's foot, age, coming out, wall piece index] for each ripple running.
var _ripples: Array = []
var _glow: QuadFx
## The wall's pieces, edge by edge round the square (WallPiece).
var _wall: Array[WallPiece] = []


func _build() -> void:
	mode = IN if String(extra.get("mode", "out")) == "in" else OUT
	duration = T_FOLD + SPAN + FADE
	busy = T_FOLD
	ward = FoldWard.new(origin, HALF, FoldWard.Mode.IN if mode == IN else FoldWard.Mode.OUT, _grid(), ctx.env)
	at(T_FOLD, _fold)
	at(T_FOLD + SPAN, _unfold)
	ctx.play(&"q_foldward", origin, 0.0)
	if not DominionParts.staged(self):
		return
	var crease := Crease.new()
	crease.fx = self
	crease.z_index = 4
	track(crease, ctx.ground)
	_build_wall()
	_glow = FxParts.ground_light(self, origin, HALF * 1.5, colour(), 0.0)


## The wall, in pieces WALL_SEG long round the square, each in the world layer at the middle of its foot so the town
## sorts round it piece by piece. The chevrons go to the pieces they stand on.
func _build_wall() -> void:
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	var corners := _corners()
	var per := maxi(roundi(HALF * 2.0 / WALL_SEG), 1)
	for e in 4:
		var p := corners[e]
		var q := corners[(e + 1) % 4]
		var normal := ((p + q) * 0.5 - origin).normalized()
		for k in per:
			var piece := WallPiece.new()
			piece.fx = self
			piece.index = _wall.size()
			piece.setup(p.lerp(q, float(k) / per), p.lerp(q, float(k + 1) / per), normal,
				HALF * 2.0 * (float(e) + float(k) / per), k == 0)
			track(piece, parent)
			_wall.append(piece)
		for j in CHEVRONS:
			var u := 0.12 + 0.76 * (float(j) + 0.5) / float(CHEVRONS)
			_wall[e * per + mini(int(u * per), per - 1)].chevrons.append(p.lerp(q, u))


## The wall piece whose foot holds the point of the edge nearest ground point `g`, and that point: [point, index].
func _on_wall(g: Vector2) -> Array:
	var d := g - origin
	var e: int
	var along: float
	if absf(d.x) >= absf(d.y):
		e = 1 if d.x > 0.0 else 3
		along = d.y + HALF if e == 1 else HALF - d.y
	else:
		e = 2 if d.y > 0.0 else 0
		along = d.x + HALF if e == 0 else HALF - d.x
	along = clampf(along, 0.0, HALF * 2.0)
	var corners := _corners()
	var point := corners[e].lerp(corners[(e + 1) % 4], along / (HALF * 2.0))
	var per := maxi(roundi(HALF * 2.0 / WALL_SEG), 1)
	return [point, e * per + clampi(int(along / (HALF * 2.0) * per), 0, per - 1)]


## The fold takes: from now until the span is over, whoever walks across the edge the forbidden way is folded across.
func _fold() -> void:
	holding = true
	if not DominionParts.staged(self):
		return
	DominionParts.pulse(self, origin, HALF * 1.7, colour(), 0.8, 1.0)
	for c in _corners():
		DominionParts.motes(self, c, life(), 6)


## The span is over: the square is the town's again.
func _unfold() -> void:
	holding = false
	ward.let_in()
	ward.forget()


func _finish() -> void:
	_unfold()
	super()


func _fx_process(delta: float) -> void:
	_tick_in -= delta
	if holding:
		ward.step(ctx.field, ctx.crowd)
		folds += ward.wrapped.size()
		turned += ward.turn_away(T_FOLD + SPAN - t, TURN_AWAY)
		stops += ward.stopped.size()
		for w: Array in ward.wrapped:
			_ripple(w[1], w[2])
		if not ward.wrapped.is_empty() and _tick_in <= 0.0:
			_tick_in = TICK_EVERY
			ctx.play(&"q_mirror_hit", ward.wrapped[ward.wrapped.size() - 1][2], -4.0)
	for i in range(_ripples.size() - 1, -1, -1):
		_ripples[i][1] += delta
		if _ripples[i][1] >= RIPPLE_LIFE:
			_ripples.remove_at(i)
	if is_instance_valid(_glow):
		_glow.set_param("intensity", 0.32 * shown() * (0.85 + 0.15 * sin(t * 2.2)))
	# The wall shimmers, so its pieces redraw each frame, those on screen only (Person.view, empty in a bare test).
	var view := Person.view.grow(WALL_H * 2.0)
	for piece in _wall:
		if Person.view.size == Vector2.ZERO or view.has_point(piece.position):
			piece.queue_redraw()


## A fold of someone from `from` to `to`: a ring drawn in on the wall where they went into it, a matching one opening on
## the far wall where they come out.
func _ripple(from: Vector2, to: Vector2) -> void:
	if not DominionParts.staged(self) or _wall.is_empty():
		return
	if _ripples.size() + 2 > RIPPLES:
		_ripples = _ripples.slice(2)
	var went := _on_wall(from)
	var came := _on_wall(to)
	_ripples.append([went[0], 0.0, false, went[1]])
	_ripples.append([came[0], 0.0, true, came[1]])


## The square's colour: violet for NO WAY OUT, gold for NO WAY IN; its bright core; and its motes.
func colour() -> Color:
	return VIOLET if mode == OUT else GOLD


func hot() -> Color:
	return VIOLET_HOT if mode == OUT else GOLD_HOT


func life() -> Array:
	return VIOLET_LIFE if mode == OUT else GOLD_LIFE


## How much of the square shows: in as it folds, out over FADE once the span is over.
func shown() -> float:
	return clampf(minf(t / T_FOLD, (duration - t) / FADE), 0.0, 1.0)


## How far the wall has risen out of the ground (0..1): up as the square folds, back down over FADE at the end.
func risen() -> float:
	var up := clampf(t / T_FOLD, 0.0, 1.0)
	var down := clampf((duration - t) / FADE, 0.0, 1.0)
	return minf(1.0 - (1.0 - up) * (1.0 - up), 1.0 - (1.0 - down) * (1.0 - down))


func _corners() -> Array[Vector2]:
	return [origin + Vector2(-HALF, -HALF), origin + Vector2(HALF, -HALF), origin + Vector2(HALF, HALF),
		origin + Vector2(-HALF, HALF)]


## The town's walk grid: the crowd's, or anyone's in the field.
func _grid() -> WalkGrid:
	if ctx.crowd != null and ctx.crowd._grid != null:
		return ctx.crowd._grid
	for e in ctx.field.alive():
		var p := e as Person
		if p != null and p.grid != null:
			return p.grid
	return null


## The crease on the ground where the wall stands, in ground units: a faint footing line of light round the square, a
## faint sheet within it and each corner folded in as a pale flap. Drawn once; it fades by its alpha alone.
class Crease extends Node2D:
	var fx: FoldedWardFx

	func _process(_delta: float) -> void:
		modulate.a = fx.shown()

	func _draw() -> void:
		var col := fx.colour()
		var hot := fx.hot()
		var c := fx.origin
		var corners: Array[Vector2] = [c + Vector2(-HALF, -HALF), c + Vector2(HALF, -HALF), c + Vector2(HALF, HALF),
			c + Vector2(-HALF, HALF)]
		var ring := PackedVector2Array(corners)
		ring.append(corners[0])
		draw_colored_polygon(PackedVector2Array(corners), Color(col, 0.05))
		for i in 4:
			var p := corners[i]
			var u := p + (corners[(i + 3) % 4] - p).normalized() * CORNER
			var v := p + (corners[(i + 1) % 4] - p).normalized() * CORNER
			draw_colored_polygon(PackedVector2Array([p, u, v]), Color(hot, 0.12))
			draw_line(u, v, Color(hot, 0.35), 0.04)
		draw_polyline(ring, Color(col, 0.18), 0.24)
		draw_polyline(ring, Color(col, 0.5), 0.08)
		draw_polyline(ring, Color(hot, 0.55), 0.035)


## One piece of the wall, WALL_SEG of the edge long, standing on the ground in the world layer at the middle of its
## foot (so it sorts with the town by that point). Folded once along its length: its middle stands out of the edge line
## by PLEAT as a ridge between two faces, one lit and one in shade, so the edge reads as pleated paper. Bright at its
## foot and top, faint between; the sheen breathes in a slow wave round the square and a glint runs along it. It holds
## the chevrons standing across it at half height (in for NO WAY OUT, out for NO WAY IN) and draws the ripples of the
## folds that went into it or came out of it.
class WallPiece extends Node2D:
	## Px of wall height per ground unit of a ripple's radius, so a ripple is a round ring on the wall.
	const RIPPLE_UP := 24.0
	const RING := 20
	var fx: FoldedWardFx
	var index := 0
	var chevrons: Array[Vector2] = []
	var _normal := Vector2.ZERO
	var _along := Vector2.ZERO
	## Its middle's place round the square (ground units from the first corner), for the wave and the glint.
	var _s := 0.0
	## Whether its first foot is a corner of the square (a fold where two edges meet).
	var _corner := false
	## Its two feet and its ridge, in px from its position.
	var _fa := Vector2.ZERO
	var _fm := Vector2.ZERO
	var _fb := Vector2.ZERO
	var _quad := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	var _cols := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	var _ring := PackedVector2Array()

	func setup(a: Vector2, b: Vector2, normal: Vector2, s0: float, corner: bool) -> void:
		_normal = normal
		_along = (b - a).normalized()
		_s = s0 + a.distance_to(b) * 0.5
		_corner = corner
		position = Iso.ground_to_screen((a + b) * 0.5).round()
		_fa = _local(a)
		_fb = _local(b)
		_fm = _local((a + b) * 0.5 + normal * PLEAT)
		_ring.resize(RING + 1)

	func _local(g: Vector2) -> Vector2:
		return Iso.ground_to_screen(g) - position

	func _draw() -> void:
		var a := fx.shown()
		var h := WALL_H * fx.risen()
		if a <= 0.0 or h < 1.0:
			return
		var col := fx.colour()
		var hot := fx.hot()
		var now := fx.t
		var round_len := HALF * 8.0
		var gd := absf(_s - fmod(now * 0.35, 1.0) * round_len)
		var glint := clampf(1.0 - minf(gd, round_len - gd) / 1.2, 0.0, 1.0)
		var wave := 0.5 + 0.5 * sin(now * 1.2 - _s * 1.1)
		# Its deeper colour for the glow round its edges and its shaded faces, and a dark rim under its top that holds
		# it off bright paving.
		var deep: Color = fx.life()[2]
		_face(_fa, _fm, 1.0, h, a, col, hot, glint, wave)
		_face(_fm, _fb, 0.55, h, a, deep, hot, glint, wave)
		var up := Vector2(0.0, -h)
		# The folds: a valley at its first foot, the ridge brighter, a bright fold where two edges meet.
		draw_line(_fa, _fa + up, Color(col, 0.3 * a), 1.0)
		draw_line(_fm, _fm + up, Color(hot, minf((0.3 + 0.3 * wave + 0.4 * glint) * a, 1.0)), 1.0)
		if _corner:
			draw_line(_fa, _fa + up, Color(col, 0.35 * a), 4.0)
			draw_line(_fa, _fa + up + Vector2(0.0, -2.0), Color(hot, 0.9 * a), 2.0)
		# Its foot and its top: the bright edges, a glow of its colour round a core of light.
		var halo := Color(deep, 0.5 * a)
		draw_line(_fa, _fm, halo, 3.0)
		draw_line(_fm, _fb, halo, 3.0)
		var foot := Color(hot, minf(0.7 * a, 1.0))
		draw_line(_fa, _fm, foot, 1.0)
		draw_line(_fm, _fb, foot, 1.0)
		draw_line(_fa + up, _fm + up, halo, 4.0)
		draw_line(_fm + up, _fb + up, halo, 4.0)
		var rim := Color(deep.darkened(0.6), 0.45 * a)
		draw_line(_fa + up + Vector2(0.0, 2.0), _fm + up + Vector2(0.0, 2.0), rim, 1.0)
		draw_line(_fm + up + Vector2(0.0, 2.0), _fb + up + Vector2(0.0, 2.0), rim, 1.0)
		var top := Color(hot, minf((0.8 + 0.15 * wave + 0.4 * glint) * a, 1.0))
		draw_line(_fa + up, _fm + up, top, 2.0)
		draw_line(_fm + up, _fb + up, top, 2.0)
		# The chevrons standing across it at half height, pointing in or out, breathing.
		var point := -_normal if fx.mode == OUT else _normal
		var lift := Vector2(0.0, -h * 0.5)
		for g in chevrons:
			var beat := 0.5 + 0.5 * sin(now * 3.0 - _s * 0.9)
			var s := CHEVRON * 1.8 * (0.9 + 0.1 * beat)
			var base := g - point * s * 0.35 + point * 0.08 * beat
			var tip := _local(base + point * s * 0.7) + lift
			var l0 := _local(base - _along * s * 0.6) + lift
			var l1 := _local(base + _along * s * 0.6) + lift
			draw_line(l0, tip, Color(deep, 0.6 * a), 4.0)
			draw_line(l1, tip, Color(deep, 0.6 * a), 4.0)
			var cc := Color(hot, minf((0.6 + 0.4 * beat) * a, 1.0))
			draw_line(l0, tip, cc, 2.0)
			draw_line(l1, tip, cc, 2.0)
		# The folds of people through it: drawn in where they went in, opening where they come out.
		for r: Array in fx._ripples:
			if int(r[3]) != index:
				continue
			var age: float = clampf(float(r[1]) / RIPPLE_LIFE, 0.0, 1.0)
			var out: bool = r[2]
			var ra := 0.12 + 0.42 * (age if out else 1.0 - age)
			var al := (1.0 - age) * a
			var c := _local(r[0]) + Vector2(0.0, -h * 0.45)
			_ring_at(c, ra)
			draw_polyline(_ring, Color(deep, 0.9 * al), 3.0)
			draw_polyline(_ring, Color(hot, 0.95 * al), 1.0)
			_ring_at(c, ra * 0.55)
			draw_polyline(_ring, Color(hot, 0.8 * al), 1.0)
			if out:
				draw_circle(c, 3.0 * (1.0 - age), Color(hot, 0.85 * al))

	## One face of the fold, foot `p` to foot `q`: bright at its foot and top, faint between, `lit` by how it faces.
	func _face(p: Vector2, q: Vector2, lit: float, h: float, a: float, col: Color, hot: Color, glint: float,
			wave: float) -> void:
		var k := lit * (0.75 + 0.25 * wave) + 0.5 * glint
		var tint := col if lit >= 1.0 else col.darkened(0.15)
		var foot := Color(tint, minf(WALL_EDGE_A * a * k, 1.0))
		var mid := Color(tint, WALL_MID_A * a * (0.7 + 0.6 * wave * lit + glint))
		var top := Color(tint.lerp(hot, 0.35), minf(WALL_EDGE_A * a * k, 1.0))
		_band(p, q, 0.0, h * 0.28, foot, mid)
		_band(p, q, h * 0.28, h * 0.62, mid, mid)
		_band(p, q, h * 0.62, h, mid, top)

	func _band(p: Vector2, q: Vector2, y0: float, y1: float, c0: Color, c1: Color) -> void:
		_quad[0] = p + Vector2(0.0, -y0)
		_quad[1] = q + Vector2(0.0, -y0)
		_quad[2] = q + Vector2(0.0, -y1)
		_quad[3] = p + Vector2(0.0, -y1)
		_cols[0] = c0
		_cols[1] = c0
		_cols[2] = c1
		_cols[3] = c1
		draw_polygon(_quad, _cols)

	## A ring of radius `r` (ground units) round `c` in the wall's own plane.
	func _ring_at(c: Vector2, r: float) -> void:
		for i in RING + 1:
			var th := TAU * float(i) / float(RING)
			_ring[i] = c + Iso.ground_to_screen(_along * r * cos(th)) + Vector2(0.0, -r * RIPPLE_UP * sin(th))
