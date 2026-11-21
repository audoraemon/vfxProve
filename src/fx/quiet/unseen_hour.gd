class_name UnseenHourFx
extends FxTimeline
## Unseen Hour (Veil, Tier III): a patch of the town nobody can see into. T_FALL after the cast, and for VEIL_TIME,
## nothing within RADIUS of the click is seen (Crowd.veil()): a power cast there raises no alarm and nobody looks up
## at it, a death or a collapse there brings no one and is not counted against the god, no danger there is marked,
## no fire there is fought. The people inside go on as they were -- walking, trading, standing guard -- and whatever
## is done to them is done. The veil does not hold the eye out of it: a danger from outside still frightens those
## inside. Quiet when cast; nothing of it is seen but by the god, as a shimmer and a ring of dusk on the ground, and (review
## round, ruling VRC1) a thin dark blanket thrown from the click that hangs over the whole circle for as long as the veil lasts.

const RADIUS := 5.0
const VEIL_TIME := 20.0
const T_FALL := 0.7
const VEIL := Color("b98cff")
const DUSK := Color("3b1470")
const DUSK_LIFE := [Color("f4ecff"), Color("b98cff"), Color("7a3cf0"), Color(0.12, 0.03, 0.2, 0.5)]

## Whether the veil is down now.
var veiled := false
## The god's blanket over the veiled ground (screen space, overhead_back); null until staged.
var blanket: Blanket
## This cast's size: RADIUS and VEIL_TIME in the light, VeilRules.SIZES' dark numbers when cast in the dark.
var radius := RADIUS
var veil_time := VEIL_TIME


func _build() -> void:
	radius = VeilParts.size(self, "unseen", "RADIUS")
	veil_time = VeilParts.size(self, "unseen", "VEIL_TIME")
	duration = T_FALL + veil_time + 1.0
	busy = T_FALL
	at(T_FALL, _fall)
	ctx.play(&"q_unseen", origin)
	# The blanket is thrown from the click now and lands as the veil falls; its shadow and hem lie on the ground under it. Drawing
	# only: built on whatever layers the context has (none in a bare one), staged or not.
	var layer: Node2D = ctx.overhead_back if ctx.overhead_back != null else ctx.overhead
	if layer != null:
		blanket = Blanket.new()
		blanket.fx = self
		blanket.position = Iso.ground_to_screen(origin).round()
		blanket.z_index = 4
		track(blanket, layer)
	if ctx.ground != null:
		var hem := Hem.new()
		hem.fx = self
		hem.position = origin
		hem.z_index = 3
		track(hem, ctx.ground)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, radius, VEIL, 2, 36.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_FALL, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = T_FALL + 0.1
	# Dusk gathers from above into the middle.
	var down := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(origin) + Vector2(0, -40), PixelParticles.Shape.PUFF, DUSK_LIFE)
	down.drag = 1.0
	down.gravity = 40.0
	down.burst(24, {"radius": 30.0, "speed": Vector2(6, 20), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 10),
		"alt_speed": Vector2(-20, 0), "life": Vector2(0.5, 0.8), "size": Vector2(2, 3), "size_end_mul": 0.4})


func _fall() -> void:
	veiled = true
	if ctx.crowd != null:
		ctx.crowd.veil(origin, radius, veil_time)
		VeilParts.land(self, origin, radius)
	if not DominionParts.staged(self):
		return
	# The veil settles: a ring of dusk out to the edge, then the shimmer that is all the god sees of it.
	var w := FxParts.shockwave(self, origin, radius, FxParts.VOID)
	w.set_param("thickness", 0.08)
	w.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	w.tween_param("fade", 1.0, 0.0, 0.25, 0.3)
	w.life = 0.6
	var lens := FxParts.refract_ring(self, origin, radius, Color(0.8, 0.7, 1.0))
	lens.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	lens.life = 0.62
	var haze := FxParts.heat_haze(self, Iso.ground_to_screen(origin), Iso.radius_to_screen(radius).x * 0.9, 0.9)
	haze.life = veil_time + 0.5
	DominionParts.icon(self, origin, DominionParts.SHUT_EYE, VEIL, 2.5, 50.0)


func _rise() -> void:
	veiled = false


## How much of the veil shows: in as it falls, out as the hour ends.
func shown() -> float:
	return clampf(minf((t - T_FALL) / 0.4, (T_FALL + veil_time + 0.8 - t) / 0.8), 0.0, 1.0)


## How far the blanket has spread (0 at the click .. 1 at the veil's edge): thrown out over Blanket.THROW, a little past the edge
## before it settles back onto the circle; it billows a little wider as it lifts at the end.
func spread() -> float:
	var u := clampf(t / Blanket.THROW, 0.0, 1.0)
	var k := u * (2.0 - u) + 0.1 * sin(PI * u) * u
	return maxf(k, 0.04) * (1.0 + 0.12 * lifting())


## How far the blanket has lifted away at the end (0 while it hangs .. 1 gone), over the last second of the cast.
func lifting() -> float:
	return clampf(t - T_FALL - veil_time, 0.0, 1.0)


## The veil's hem on the ground (ground units, ctx.ground): the blanket's soft shadow, a dusk band at the edge with slow pale
## threads crossing it, and faint motes rising.
class Hem extends Node2D:
	var fx: UnseenHourFx

	func _process(_delta: float) -> void:
		# Its cast freed outright (outside the tree, no _exit_tree): it goes too.
		if not is_instance_valid(fx) or fx.t > fx.duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		# The blanket's shadow: a soft dark disc that follows its spread and thins as it lifts.
		var sh := clampf(fx.t / 0.3, 0.0, 1.0) * (1.0 - fx.lifting())
		if sh > 0.0:
			var sr := fx.radius * minf(fx.spread(), 1.08)
			for k in 3:
				draw_circle(Vector2.ZERO, sr * (1.0 - 0.06 * float(k)), Color(VeilParts.BLACK, Blanket.SHADOW * sh))
		var a := fx.shown()
		if a <= 0.0:
			return
		draw_arc(Vector2.ZERO, fx.radius, 0.0, TAU, 80, Color(DUSK, 0.5 * a), 0.25)
		draw_arc(Vector2.ZERO, fx.radius - 0.3, 0.0, TAU, 80, Color(DUSK, 0.18 * a), 0.4)
		var turn := fx.t * 0.12
		for i in 9:
			var a0 := turn + TAU * float(i) / 9.0
			draw_arc(Vector2.ZERO, fx.radius, a0, a0 + 0.25, 6, Color(VEIL, 0.55 * a), 0.06)
		# Motes drifting up the hem, each on its own slow loop.
		for i in 14:
			var k := fmod(fx.t * 0.35 + float(i) * 0.137, 1.0)
			var ang := TAU * float(i) / 14.0 + fx.t * 0.05
			var p := Vector2.from_angle(ang) * (fx.radius - 0.1 + 0.2 * sin(fx.t * 2.0 + float(i)))
			draw_rect(Rect2(p - Vector2(0, k * 0.9) - Vector2(0.03, 0.03), Vector2(0.06, 0.06)), Color(VEIL, (1.0 - k) * 0.7 * a))


## The blanket (spec 5, ruling VRC1): a wide, thin, dark sheet hanging over the veiled circle in screen space, raised above the
## ground ring so it reads as hanging over the town, not lying on it. Thrown from the click it spreads to the veil's edge, settles
## with a slow ripple, hangs with a soft sagging scalloped edge and a faint weave of threads, and lifts away at the end. Thin enough
## that people and roofs under it stay readable. A mesh of rings and spokes drawn as one triangle array each frame.
class Blanket extends Node2D:
	## How long the throw takes from the click to the edge (it lands a little after the veil falls).
	const THROW := T_FALL + 0.6
	## How high the sheet hangs at its middle, and how far its edge droops from there, in screen pixels.
	const LIFT := 30.0
	const DROOP := 16.0
	## How high the throw arcs on its way out.
	const ARC := 34.0
	## The edge's scallops (where it sags between the points it hangs from) and its soft fringe below the hem.
	const SCALLOPS := 9
	const FRINGE := 14.0
	const RINGS := 7
	const SPOKES := 48
	## The sheet's opacity at its middle and at its edge; its shadow's, three discs deep.
	const A_MID := 0.3
	const A_EDGE := 0.5
	const SHADOW := 0.07
	## Ground units between the weave's threads.
	const WEAVE := 0.8
	var fx: UnseenHourFx
	var _idx := PackedInt32Array()
	var _pts := PackedVector2Array()
	var _cols := PackedColorArray()
	var _unit := PackedVector2Array()

	func _ready() -> void:
		for i in SPOKES:
			_unit.append(Vector2.from_angle(TAU * float(i) / float(SPOKES)))
		# Vertex 0 the middle; then RINGS rings of SPOKES (ring k at (k + 1) / RINGS); then the fringe ring below the edge.
		var n := 1 + (RINGS + 1) * SPOKES
		_pts.resize(n)
		_cols.resize(n)
		for i in SPOKES:
			var j := (i + 1) % SPOKES
			_idx.append_array([0, 1 + i, 1 + j])
		for k in RINGS:
			var a := 1 + k * SPOKES
			var b := a + SPOKES
			for i in SPOKES:
				var j := (i + 1) % SPOKES
				_idx.append_array([a + i, b + i, b + j, a + i, b + j, a + j])

	func _process(_delta: float) -> void:
		# Its cast freed outright (outside the tree, no _exit_tree): it goes too.
		if not is_instance_valid(fx) or fx.t > fx.duration:
			queue_free()
			return
		queue_redraw()

	## The sheet's height above the ground (screen pixels) at `rho` (0 middle .. 1 edge) and angle `ang`, now.
	func height(rho: float, ang: float) -> float:
		var c := fx.t
		var u := clampf(c / THROW, 0.0, 1.0)
		var lift := LIFT * u + ARC * sin(PI * u) + 70.0 * pow(fx.lifting(), 2.0)
		# The edge sags most between the points it hangs from, less as it lifts away.
		var scallop := 0.6 + 0.4 * (0.5 - 0.5 * cos(float(SCALLOPS) * ang))
		var z := lift - DROOP * pow(rho, 3.0) * scallop * (1.0 - 0.7 * fx.lifting())
		# The landing's ripple runs out from the middle and dies away; then only a slow breath stirs it.
		if c > THROW:
			var s := c - THROW
			z += 7.0 * exp(-s * 0.8) * sin(rho * 9.0 - s * 5.0) * rho
		z += 2.0 * sin(c * 1.1 + rho * 4.0 + ang * 2.0) * rho
		return z

	func _draw() -> void:
		var a := clampf(fx.t / 0.25, 0.0, 1.0) * (1.0 - fx.lifting())
		if a <= 0.0:
			return
		var h := Iso.radius_to_screen(fx.radius) * fx.spread()
		_pts[0] = Vector2(0.0, -height(0.0, 0.0))
		_cols[0] = Color(VeilParts.BLACK, A_MID * a)
		var edge := PackedVector2Array()
		for k in RINGS:
			var rho := float(k + 1) / float(RINGS)
			var al := lerpf(A_MID, A_EDGE, rho * rho) * a
			for i in SPOKES:
				var ang := TAU * float(i) / float(SPOKES)
				var z := height(rho, ang)
				var p := _unit[i] * h * rho + Vector2(0.0, -z)
				_pts[1 + k * SPOKES + i] = p
				# Folds: where the sheet rises toward the edge it catches a little dusk light, where it falls it is darker.
				var fold := clampf(0.5 + (z - height(rho - 1.0 / float(RINGS), ang)) * 0.12, 0.0, 1.0)
				_cols[1 + k * SPOKES + i] = Color(VeilParts.BLACK.lerp(VeilParts.DUSK, 0.15 + 0.7 * fold), al)
				if k == RINGS - 1:
					edge.append(p)
		# The fringe: a soft band hanging below the hem, deepest between the scallops, fading to nothing.
		var f := 1 + RINGS * SPOKES
		for i in SPOKES:
			var ang := TAU * float(i) / float(SPOKES)
			var drop := FRINGE * (0.5 + 0.5 * (0.5 - 0.5 * cos(float(SCALLOPS) * ang)))
			_pts[f + i] = edge[i] + Vector2(0.0, drop)
			_cols[f + i] = Color(VeilParts.BLACK, 0.0)
			# (the fringe's top edge is the hem ring itself, at A_EDGE)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _idx, _pts, _cols)
		# The weave: faint threads along the ground's two axes (diagonals on screen), each following the sheet's folds.
		var step := sqrt(2.0) * WEAVE / fx.radius
		var lines := int(sqrt(2.0) / step)
		var thread := Color(VeilParts.SILVER.lerp(VeilParts.VEIL, 0.5), 0.17 * a)
		for dirn in 2:
			for k in range(-lines, lines + 1):
				var off := float(k) * step
				# Along the thread, within 0.94 of the middle (unit disc).
				var half := sqrt(maxf(0.94 * 0.94 - off * off * 0.5, 0.0) * 2.0)
				if half <= 0.05:
					continue
				var pl := PackedVector2Array()
				for s in 9:
					var along := lerpf(-half, half, float(s) / 8.0) * 0.5
					var q := Vector2(along + off * 0.5, along - off * 0.5) if dirn == 0 else Vector2(along + off * 0.5, off * 0.5 - along)
					pl.append(Vector2(q.x * h.x, q.y * h.y) + Vector2(0.0, -height(q.length(), q.angle())))
				draw_polyline(pl, thread, 1.0)
		# The hem: a dark seam with a cold pale thread along it.
		edge.append(edge[0])
		draw_polyline(edge, Color(VeilParts.BLACK, 0.6 * a), 4.0)
		draw_polyline(edge, Color(VeilParts.VEIL, 0.45 * a), 1.0)
