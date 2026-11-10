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
## To the player the square's edge shows as a crease of light, like folded paper, its four corners folded in, faint fold
## lines across it; cold violet with chevrons along the edge pointing in (NO WAY OUT), or pale gold with chevrons
## pointing out (NO WAY IN). Each fold of someone across it shows as a small ripple drawn in where they left and a
## matching one opening where they come out, with a soft tick. It all fades as the span ends.

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
## How far each corner is folded in along its edges, and the chevrons per edge and their size (ground units).
const CORNER := 0.45
const CHEVRONS := 5
const CHEVRON := 0.3
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
## [ground point, age, coming out] for each ripple running.
var _ripples: Array = []
var _glow: QuadFx


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
	_glow = FxParts.ground_light(self, origin, HALF * 1.5, colour(), 0.0)


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


## A fold of someone from `from` to `to`: a ripple drawn in where they left, a matching one opening where they come out.
func _ripple(from: Vector2, to: Vector2) -> void:
	if not DominionParts.staged(self):
		return
	if _ripples.size() + 2 > RIPPLES:
		_ripples = _ripples.slice(2)
	_ripples.append([from, 0.0, false])
	_ripples.append([to, 0.0, true])


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


## How far the square has unfolded to its full size (0..1): it opens out from the click as it folds.
func opened() -> float:
	var k := clampf(t / T_FOLD, 0.0, 1.0)
	return 1.0 - (1.0 - k) * (1.0 - k)


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


## The square drawn flat on the ground, in ground units: a faint sheet with fold lines across it, a crease of light
## round its edge with a glint running along it, each corner folded in as a flap, chevrons along every edge pointing in
## (NO WAY OUT) or out (NO WAY IN), and the ripples of the folds.
class Crease extends Node2D:
	var fx: FoldedWardFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var col := fx.colour()
		var hot := fx.hot()
		var c := fx.origin
		var h := HALF * lerpf(0.25, 1.0, fx.opened())
		var k := CORNER * h / HALF
		var corners: Array[Vector2] = [c + Vector2(-h, -h), c + Vector2(h, -h), c + Vector2(h, h), c + Vector2(-h, h)]
		# The edge, each corner cut where its flap folds in.
		var edge := PackedVector2Array()
		for i in 4:
			var p := corners[i]
			edge.append(p + (corners[(i + 3) % 4] - p).normalized() * k)
			edge.append(p + (corners[(i + 1) % 4] - p).normalized() * k)
		draw_colored_polygon(edge, Color(col, 0.12 * a))
		# Fold lines across the sheet: its middles and its diagonals.
		var faint := Color(hot, 0.22 * a)
		draw_line(c + Vector2(-h, 0.0), c + Vector2(h, 0.0), faint, 0.05)
		draw_line(c + Vector2(0.0, -h), c + Vector2(0.0, h), faint, 0.05)
		draw_line(corners[0], corners[2], Color(hot, 0.14 * a), 0.04)
		draw_line(corners[1], corners[3], Color(hot, 0.14 * a), 0.04)
		var ring := PackedVector2Array(edge)
		ring.append(edge[0])
		draw_polyline(ring, Color(col, 0.3 * a), 0.3)
		draw_polyline(ring, Color(col, 0.9 * a), 0.12)
		draw_polyline(ring, Color(hot, 0.95 * a), 0.05)
		# Each corner folded in: a pale flap over the sheet, its crease brighter.
		for i in 4:
			var p := corners[i]
			var u := edge[i * 2]
			var v := edge[i * 2 + 1]
			var flap := PackedVector2Array([u, v, u + v - p])
			draw_colored_polygon(flap, Color(hot, 0.3 * a))
			draw_line(u, v, Color(hot, 0.95 * a), 0.07)
		# A glint running round the crease.
		var run := fmod(fx.t * 0.35, 1.0) * 4.0
		var side := int(run)
		var from := corners[side]
		var to := corners[(side + 1) % 4]
		var at := from.lerp(to, run - float(side))
		var along := (to - from).normalized()
		draw_line(at - along * 0.5, at + along * 0.5, Color(1, 1, 1, 0.85 * a), 0.1)
		# Chevrons along every edge, a little inside it, pointing in (NO WAY OUT) or out (NO WAY IN), breathing.
		var inward := fx.mode == OUT
		for i in 4:
			var p := corners[i]
			var q := corners[(i + 1) % 4]
			var tdir := (q - p).normalized()
			var mid := (p + q) * 0.5
			var normal := (mid - c).normalized()
			var point := -normal if inward else normal
			for j in CHEVRONS:
				var u := (float(j) + 0.5) / float(CHEVRONS)
				var base := p.lerp(q, 0.12 + 0.76 * u) - normal * 0.35
				var beat := 0.5 + 0.5 * sin(fx.t * 3.0 - float(j) * 0.9 + float(i))
				base += point * 0.06 * beat
				var s := CHEVRON * (0.9 + 0.1 * beat)
				var tip := base + point * s * 0.6
				var cc := Color(hot, (0.45 + 0.4 * beat) * a)
				draw_line(base - tdir * s * 0.6, tip, cc, 0.07)
				draw_line(base + tdir * s * 0.6, tip, cc, 0.07)
		# The folds: drawn in where they left, opening where they come out.
		for r: Array in fx._ripples:
			var g: Vector2 = r[0]
			var age: float = clampf(float(r[1]) / RIPPLE_LIFE, 0.0, 1.0)
			var out: bool = r[2]
			var ra := 0.12 + 0.5 * (age if out else 1.0 - age)
			var al := (1.0 - age) * a
			draw_arc(g, ra, 0.0, TAU, 24, Color(col, 0.8 * al), 0.08)
			draw_arc(g, ra * 0.55, 0.0, TAU, 20, Color(hot, 0.9 * al), 0.05)
			if out:
				draw_circle(g, 0.1 * (1.0 - age), Color(hot, 0.7 * al))
