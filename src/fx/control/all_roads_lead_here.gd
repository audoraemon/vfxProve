class_name AllRoadsLeadHereFx
extends FxTimeline
## All Roads Lead Here (Passage, Tier IV): the click lays a district of RADIUS about it, and for SPAN seconds every road
## in that district ends at the click. The MAX_PEOPLE living people nearest the click within RADIUS at the cast --
## citizens and soldiers alike, nearest first, the nearer of two at the same distance the earlier spawned -- are caught.
## They keep their own minds: they still mean to go home, to their errand, to the gate, to their post, away from a danger.
## But every route any of them plans leads to the click (Person.bend_roads()). They arrive, find they are not where they
## meant to be, plan again, and the new route brings them back. Nobody is compelled: no mark over the head, no mind
## changed; the roads lie. A danger still frightens them, and when they run from it they run here. The calm, milling
## about their street, mill about the click instead, within GATHER_R of it. Those waiting at a gate are let out of its
## crowd: their way out leads here. One inside a building is left alone until it comes out; if it is one of the caught,
## its roads are bent the moment it plans one. When the span ends everything runs true again and each plans its own
## way anew; one who dies is let go at once. Quiet: no danger and no fright from the cast itself (its alarm is the
## book's). Use it to gather a district under a great strike, to draw the responders into a trap, to mix the guard
## with the townsfolk. To the player the district's streets show thin gold lines that grow over T_BEND and all bend in
## to the click, a soft gold glow lies on the ground there, and a faint gold thread trails from each caught person
## toward it while it lasts; all of it fades at the end.

const RADIUS := 10.0
const MAX_PEOPLE := 80
const SPAN := 25.0
const T_BEND := 0.8
const GATHER_R := 1.5

## The roads drawn: one from each of ROADS points round the district's edge, along the streets to the click.
const ROADS := 18
## A bright pulse runs every PULSE_GAP along each road toward the click, at PULSE_SPEED.
const PULSE_GAP := 1.6
const PULSE_SPEED := 2.4
## Seconds it takes to fade away at the end.
const FADE := 1.0
## A caught person's thread: this long toward the click (screen px), at most.
const THREAD_PX := 46.0
const GOLD := Color("f2c14e")
const PALE := Color("fff1c4")
const DEEP := Color("8a5a14")

## Everyone caught at the cast who is still caught (the dead are let go).
var caught: Array[Person] = []
## Where every road leads: the click, on open ground.
var spot := Vector2.ZERO
var _ended := false
var _glow: QuadFx


## Who a cast at `at` catches: the living within RADIUS, nearest first (the earlier spawned first at the same distance),
## MAX_PEOPLE at most. Those inside a building count: their roads bend when they come out.
static func caught_by(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, RADIUS):
		var p := e as Person
		if p != null:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		if da != db:
			return da < db
		return a.stagger_key() < b.stagger_key())
	return out.slice(0, MAX_PEOPLE)


func _build() -> void:
	duration = SPAN + 0.1
	busy = T_BEND
	var grid := _grid()
	spot = origin
	if grid != null and not grid.walkable(spot):
		var w := grid.nearest_walkable(spot, 8)
		if w != Vector2.INF:
			spot = w
	for p in caught_by(ctx.field, origin):
		if p.bend_roads(spot, SPAN, GATHER_R):
			caught.append(p)
	at(SPAN, _release)
	ctx.play(&"q_allroads", origin, 0.0)
	if not DominionParts.staged(self):
		return
	DominionParts.pulse(self, spot, GATHER_R * 2.4, GOLD, 0.6, T_BEND + 0.4)
	_glow = FxParts.ground_light(self, spot, GATHER_R * 1.8, GOLD, 0.0)
	var roads := Roads.new()
	roads.fx = self
	roads.lines = _roads(grid)
	roads.z_index = 3
	track(roads, ctx.ground)
	var threads := Threads.new()
	threads.fx = self
	threads.z_index = 4
	track(threads, ctx.overhead)


## The span is over (or the effect cut short): every caught person's roads run true again.
func _release() -> void:
	if _ended:
		return
	_ended = true
	for p in caught:
		if is_instance_valid(p):
			p.unbend_roads()
	caught.clear()


func _finish() -> void:
	_release()
	super()


func _fx_process(_delta: float) -> void:
	# One who dies is let go at once.
	for i in range(caught.size() - 1, -1, -1):
		var p := caught[i]
		if not is_instance_valid(p) or not p.is_alive():
			if is_instance_valid(p):
				p.unbend_roads()
			caught.remove_at(i)
	if is_instance_valid(_glow):
		_glow.set_param("intensity", 0.45 * fade() * (0.85 + 0.15 * sin(t * 2.6)))


## How much of the drawing shows: the roads grow in over T_BEND, everything fades over the last FADE.
func fade() -> float:
	return curve([[0.0, 0.0], [T_BEND * 0.5, 1.0], [SPAN - FADE, 1.0], [SPAN, 0.0]])


## How far the roads have grown in from the district's edge (0..1).
func grown() -> float:
	return clampf(t / T_BEND, 0.0, 1.0)


## The town's walk grid, by way of anyone in it.
func _grid() -> WalkGrid:
	for e in ctx.field.alive():
		var p := e as Person
		if p != null and p.grid != null:
			return p.grid
	return null


## The roads drawn: from ROADS points round the district's edge along the walk grid to the spot, each smoothed, running
## from the edge in.
func _roads(grid: WalkGrid) -> Array:
	var out: Array = []
	if grid == null:
		return out
	for k in ROADS:
		var a := TAU * (float(k) + 0.5) / float(ROADS)
		var from := grid.nearest_walkable(spot + Vector2(cos(a), sin(a)) * RADIUS * 0.92, 8)
		if from == Vector2.INF:
			continue
		var way := grid.path(from, spot)
		if way.size() < 3:
			continue
		way.insert(0, from)
		way.append(spot)
		out.append(_smooth(way))
	return out


## Corners of the grid's steps rounded off (two passes of neighbour averaging, the ends kept).
static func _smooth(way: PackedVector2Array) -> PackedVector2Array:
	var w := way
	for _pass in 2:
		var s := PackedVector2Array(w)
		for i in range(1, w.size() - 1):
			s[i] = (w[i - 1] + w[i] * 2.0 + w[i + 1]) * 0.25
		w = s
	return w


## The bent streets, drawn flat on the ground in ground units: a faint gold line along each road, grown from the edge
## inward, with brighter pulses running along it to the spot, and small rings closing in on the spot.
class Roads extends Node2D:
	var fx: AllRoadsLeadHereFx
	## PackedVector2Array per road, from the district's edge to the spot.
	var lines: Array = []
	var _lengths: Array[float] = []

	func _ready() -> void:
		for way: PackedVector2Array in lines:
			var n := 0.0
			for i in range(1, way.size()):
				n += way[i - 1].distance_to(way[i])
			_lengths.append(n)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a := fx.fade()
		if a <= 0.0:
			return
		var g := fx.grown()
		for k in lines.size():
			var way: PackedVector2Array = lines[k]
			var total: float = _lengths[k]
			# Grown from the edge: the part from the edge to `g` of the way along.
			var shown := _part(way, 0.0, total * g)
			if shown.size() >= 2:
				draw_polyline(shown, Color(DEEP, 0.5 * a), 0.16)
				draw_polyline(shown, Color(GOLD, 0.8 * a), 0.06)
			if g < 1.0:
				continue
			# Pulses running in along the road to the spot.
			var d := fmod(fx.t * PULSE_SPEED + float(k) * 0.37, PULSE_GAP)
			while d < total:
				var seg := _part(way, d, minf(d + 0.45, total))
				if seg.size() >= 2:
					draw_polyline(seg, Color(PALE, 0.95 * a), 0.09)
				d += PULSE_GAP
		# Rings closing in on the spot, one after another.
		for i in 3:
			var k := fmod(fx.t * 0.5 + float(i) / 3.0, 1.0)
			var r := GATHER_R * (1.0 - k)
			if r > 0.05:
				draw_arc(fx.spot, r, 0.0, TAU, 40, Color(GOLD, 0.5 * a * k), 0.05)
		draw_circle(fx.spot, 0.12, Color(PALE, 0.9 * a))

	## The stretch of `way` from `from` to `to` along it.
	static func _part(way: PackedVector2Array, from: float, to: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		if to <= from:
			return out
		var run := 0.0
		for i in range(1, way.size()):
			var p := way[i - 1]
			var q := way[i]
			var seg := p.distance_to(q)
			var s := run
			var e := run + seg
			run = e
			if e < from or seg <= 0.0:
				continue
			if s > to:
				break
			var a := p.lerp(q, clampf((from - s) / seg, 0.0, 1.0))
			var b := p.lerp(q, clampf((to - s) / seg, 0.0, 1.0))
			if out.is_empty():
				out.append(a)
			out.append(b)
		return out


## A faint gold thread from each caught person toward the spot, in screen space, fading off along its length.
class Threads extends Node2D:
	var fx: AllRoadsLeadHereFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a := fx.fade()
		if a <= 0.0:
			return
		var to := Iso.ground_to_screen(fx.spot)
		for p in fx.caught:
			if not is_instance_valid(p) or p.inside or not p.is_alive():
				continue
			var from := Iso.ground_to_screen(p.ground_pos) + Vector2(0, -3)
			var span := to - from
			var n := span.length()
			if n < 6.0:
				continue
			var dir := span / n
			var reach := minf(n, THREAD_PX)
			var steps := 4
			for s in steps:
				var u0 := float(s) / float(steps)
				var u1 := float(s + 1) / float(steps)
				draw_line(from + dir * reach * u0, from + dir * reach * u1, Color(GOLD, 0.5 * a * (1.0 - u0)), 1.0)
