class_name DisorderFx
extends FxTimeline
## Disorder (Decree, Tier III; spec 5.6): for HOLD_TIME, in a circle of RADIUS round the click, every choice goes wrong.
## Nobody is pushed or controlled: each one decides, and decides wrongly. The effect only lays the law (a LawZone of kind
## DISORDER on the crowd, T_LAND after the cast, stepped on the effect's own clock) and shows where it holds; the town's
## own choice points ask it (Crowd.in_law()) and choose wrongly for whoever stands in it:
## - the frightened run toward the danger, not away (Person._flee_local);
## - a guard goes for the farthest one in his sight, not the nearest (Person's fight pick; the Escort type's watchers);
## - a shelter's door leads back out: no building takes him in (ShelterManager.try_shelter);
## - the way out is the farthest gate (EvacuationManager.choose), and no second thought turns him back (_recheck).
## None of it is a roll: the wrong choice is the worst by distance. Loud: a crooked bell tolls T_TOLL after the law
## lands, and that is when its danger lands (PowerBook.IMPACT), so the frightened it reaches already choose wrongly.
## The law shows over the ground for its 15 s: a crooked gilt ring that will not sit level, and letters of law askew.

const RADIUS := 5.0
const HOLD_TIME := 15.0
## The proclamation, then the law lands; the bell tolls after it.
const T_LAND := 0.6
const T_TOLL := 0.25
## The ring fades this long once the law lifts (look only).
const FADE := 0.6
## A crooked bell: the Decree's bell sign, knocked askew.
const CROOKED_BELL: Array[int] = [0b00010, 0b00111, 0b01110, 0b11110, 0b01000]

## The law on the place (LawZone, DISORDER): laid at T_LAND, lifted at the end. null before.
var law: LawZone

var _ring: Askew


func _build() -> void:
	duration = T_LAND + HOLD_TIME + FADE
	busy = T_LAND + T_TOLL
	at(T_LAND, _land)
	at(T_LAND + T_TOLL, _toll)
	at(T_LAND + HOLD_TIME, _lift)
	ctx.play(&"di_bell", origin)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, origin, 60.0, 70.0, T_LAND, 0.9)
		var mark := FxParts.rings(self, origin, RADIUS, DecreeParts.GILT, 2, 24.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_LAND, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_LAND + 0.1


## The law lands: from now on every choice made inside goes wrong.
func _land() -> void:
	law = LawZone.circle(origin, RADIUS, [LawZone.DISORDER], HOLD_TIME)
	law.stepped_by_holder = true
	if ctx.crowd != null:
		ctx.crowd.add_law(law, self)
	else:
		law.hold_by(self)
	if not DominionParts.staged(self):
		return
	_ring = Askew.new()
	_ring.fx = self
	_ring.position = Iso.ground_to_screen(origin).round()
	_ring.z_index = 4
	track(_ring, ctx.overhead_back)


## The crooked bell tolls: a gilt ring thrown out off-true, and the bell's sign hung askew over the middle.
func _toll() -> void:
	if not DominionParts.staged(self):
		return
	DecreeParts.wave(self, origin + Vector2(0.35, -0.2), RADIUS * 1.1, 0.7, 0.06)
	var plate := DecreeParts.seal(self, origin, CROOKED_BELL, HOLD_TIME - T_TOLL, 74.0, 4)
	plate.shrink_at = 1.6
	plate.shrink_px = 2


## The law lifts: every choice goes right again.
func _lift() -> void:
	if law != null:
		if ctx.crowd != null:
			ctx.crowd.remove_law(law)
		else:
			law.lift()
	if DominionParts.staged(self):
		DecreeParts.wave(self, origin, RADIUS * 1.15, 0.5, 0.05)


## Cut short (an act of the night ends): the law is lifted with it.
func end_now() -> void:
	if not finished and law != null and law.alive():
		_lift()
	super()


func _fx_process(delta: float) -> void:
	if law == null or not law.alive():
		return
	# The law's clock starts when it lands, so it holds to the last frame before the lift.
	var dt := minf(delta, t - T_LAND)
	if ctx.crowd != null:
		ctx.crowd.step_law(law, dt)
	else:
		law.step(dt, [], [])


## How much of the ring shows: up as the law lands, whole while it holds, gone as it lifts.
func shown() -> float:
	if t < T_LAND:
		return 0.0
	if t < T_LAND + HOLD_TIME:
		return clampf((t - T_LAND) / 0.3, 0.0, 1.0)
	return clampf(1.0 - (t - T_LAND - HOLD_TIME) / FADE, 0.0, 1.0)


## Where the law holds, drawn in screen space round its middle: a faint ink wash, a gilt ring that will not sit true
## (its rim dented by order, tilted and rocking slowly, set a little off its middle), a second ring off-true inside it
## turning the other way, and letters of law round the rim, each knocked askew and some upside down, rocking as the
## ring does. Its shapes are laid out once; each frame only draws them.
class Askew extends Node2D:
	const WASH := Color(0.07, 0.04, 0.11, 0.22)
	const LETTERS := 14
	## A letter of law: three columns, four rows, a row per int, the high bit leftmost.
	const GLYPHS := [[0b111, 0b010, 0b010, 0b111], [0b101, 0b111, 0b101, 0b101], [0b110, 0b101, 0b110, 0b100],
		[0b111, 0b100, 0b110, 0b111], [0b101, 0b101, 0b010, 0b010]]
	## How far the rim is set off its middle, in screen pixels; how far it tilts and rocks, in radians.
	const OFF := Vector2(5.0, -3.0)
	const TILT := 0.09
	const ROCK := 0.05
	var fx: DisorderFx
	var _disc := PackedVector2Array()
	## The dented rim and the inner ring, in screen pixels round (0, 0).
	var _rim := PackedVector2Array()
	var _inner := PackedVector2Array()
	## Each letter's place round the rim (0..1) and its own lean, laid out by order.
	var _lean := PackedFloat32Array()

	## The ground circle's half width and half height on screen.
	static func half_axes() -> Vector2:
		return Vector2(RADIUS * 32.0 * sqrt(2.0), RADIUS * 16.0 * sqrt(2.0))

	func _init() -> void:
		var h := half_axes()
		for i in 40:
			var ang := TAU * float(i) / 40.0
			_disc.append(Vector2.from_angle(ang))
			# Dented by order: two slow lobes and a third, so the rim is nowhere quite round.
			var dent := 1.0 + 0.045 * sin(ang * 2.0 + 0.7) + 0.03 * sin(ang * 3.0 + 2.1)
			_rim.append(Vector2(cos(ang), sin(ang)) * h * dent)
			_inner.append(Vector2(cos(ang), sin(ang)) * h * 0.72 * (1.0 + 0.05 * sin(ang * 2.0 + 2.4)))
		_rim.append(_rim[0])
		_inner.append(_inner[0])
		for i in LETTERS:
			var lean := 0.55 * sin(float(i) * 2.399963)
			if i % 3 == 1:
				lean += PI  # upside down
			_lean.append(lean)

	func _process(_delta: float) -> void:
		if fx.t > fx.duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var h := half_axes()
		var now := fx.t
		var rock := TILT + ROCK * sin(now * 0.9)
		# The wash, set true: where the law holds.
		draw_set_transform(Vector2.ZERO, 0.0, h)
		draw_colored_polygon(_disc, Color(WASH, WASH.a * a))
		# The inner ring, off-true the other way, turning against the rim.
		draw_set_transform(-OFF * 0.5, -rock * 1.4 + now * 0.03, Vector2.ONE)
		draw_polyline(_inner, Color(DecreeParts.INK, 0.5 * a), 4.0)
		draw_polyline(_inner, Color(DecreeParts.GILT, 0.6 * a), 2.0)
		# The rim: ink under gilt, so it reads on any ground, set off its middle and tilted.
		draw_set_transform(OFF, rock, Vector2.ONE)
		draw_polyline(_rim, Color(DecreeParts.INK, 0.65 * a), 6.0)
		draw_polyline(_rim, Color(DecreeParts.GILT, 0.95 * a), 3.0)
		# Letters of law round the rim, each askew, rocking: gilt on an ink shadow, so they read on sand.
		for i in LETTERS:
			var ang := TAU * (float(i) + 0.5 * sin(float(i) * 1.3)) / float(LETTERS) - now * 0.05
			var p := OFF + Vector2(h.x * 0.86 * cos(ang), h.y * 0.86 * sin(ang)).rotated(rock)
			draw_set_transform(p.round(), _lean[i] + 0.25 * sin(now * 1.1 + float(i)), Vector2(3.0, 3.0))
			var glyph: Array = GLYPHS[i % GLYPHS.size()]
			for r in 4:
				for c in 3:
					if int(glyph[r]) & (1 << (2 - c)):
						draw_rect(Rect2(Vector2(c - 1.2, r - 1.7), Vector2.ONE), Color(DecreeParts.INK, 0.7 * a))
			for r in 4:
				for c in 3:
					if int(glyph[r]) & (1 << (2 - c)):
						draw_rect(Rect2(Vector2(c - 1.5, r - 2.0), Vector2.ONE), Color(DecreeParts.GILT, 0.95 * a))
		draw_set_transform(Vector2.ZERO)
