class_name UnseenHourFx
extends FxTimeline
## Unseen Hour (Veil, Tier III): a patch of the town nobody can see into. T_FALL after the cast, and for VEIL_TIME,
## nothing within RADIUS of the click is seen (Crowd.veil()): a power cast there raises no alarm and nobody looks up
## at it, a death or a collapse there brings no one and is not counted against the god, no danger there is marked,
## no fire there is fought. The people inside go on as they were -- walking, trading, standing guard -- and whatever
## is done to them is done. The veil does not hold the eye out of it: a danger from outside still frightens those
## inside. Quiet when cast; nothing of it is seen but by the god, as a shimmer and a ring of dusk on the ground.

const RADIUS := 5.0
const VEIL_TIME := 20.0
const T_FALL := 0.7
const VEIL := Color("b98cff")
const DUSK := Color("3b1470")
const DUSK_LIFE := [Color("f4ecff"), Color("b98cff"), Color("7a3cf0"), Color(0.12, 0.03, 0.2, 0.5)]

## Whether the veil is down now.
var veiled := false


func _build() -> void:
	duration = T_FALL + VEIL_TIME + 1.0
	busy = T_FALL
	at(T_FALL, _fall)
	ctx.play(&"q_unseen", origin)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, RADIUS, VEIL, 2, 36.0)
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
		ctx.crowd.veil(origin, RADIUS, VEIL_TIME)
	if not DominionParts.staged(self):
		return
	# The veil settles: a ring of dusk out to the edge, then the shimmer that is all the god sees of it.
	var w := FxParts.shockwave(self, origin, RADIUS, FxParts.VOID)
	w.set_param("thickness", 0.08)
	w.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	w.tween_param("fade", 1.0, 0.0, 0.25, 0.3)
	w.life = 0.6
	var lens := FxParts.refract_ring(self, origin, RADIUS, Color(0.8, 0.7, 1.0))
	lens.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	lens.life = 0.62
	var haze := FxParts.heat_haze(self, Iso.ground_to_screen(origin), Iso.radius_to_screen(RADIUS).x * 0.9, 0.9)
	haze.life = VEIL_TIME + 0.5
	var hem := Hem.new()
	hem.fx = self
	hem.position = origin
	hem.z_index = 3
	track(hem, ctx.ground)
	DominionParts.icon(self, origin, DominionParts.SHUT_EYE, VEIL, 2.5, 50.0)


func _rise() -> void:
	veiled = false


## How much of the veil shows: in as it falls, out as the hour ends.
func shown() -> float:
	return clampf(minf((t - T_FALL) / 0.4, (T_FALL + VEIL_TIME + 0.8 - t) / 0.8), 0.0, 1.0)


## The veil's hem on the ground: a dusk band at the edge with slow pale threads crossing it, and faint motes rising.
class Hem extends Node2D:
	var fx: UnseenHourFx

	func _process(_delta: float) -> void:
		if fx.t > T_FALL + VEIL_TIME + 0.9:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 80, Color(DUSK, 0.5 * a), 0.25)
		draw_arc(Vector2.ZERO, RADIUS - 0.3, 0.0, TAU, 80, Color(DUSK, 0.18 * a), 0.4)
		var turn := fx.t * 0.12
		for i in 9:
			var a0 := turn + TAU * float(i) / 9.0
			draw_arc(Vector2.ZERO, RADIUS, a0, a0 + 0.25, 6, Color(VEIL, 0.55 * a), 0.06)
		# Motes drifting up the hem, each on its own slow loop.
		for i in 14:
			var k := fmod(fx.t * 0.35 + float(i) * 0.137, 1.0)
			var ang := TAU * float(i) / 14.0 + fx.t * 0.05
			var p := Vector2.from_angle(ang) * (RADIUS - 0.1 + 0.2 * sin(fx.t * 2.0 + float(i)))
			draw_rect(Rect2(p - Vector2(0, k * 0.9) - Vector2(0.03, 0.03), Vector2(0.06, 0.06)), Color(VEIL, (1.0 - k) * 0.7 * a))
