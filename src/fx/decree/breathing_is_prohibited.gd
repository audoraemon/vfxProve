class_name BreathFx
extends FxTimeline
## Breathing Is Prohibited (Decree, Tier I; spec 5.2): the air goes out of a circle of RADIUS round the click for
## HOLD_TIME, T_LAND after the cast. It shimmers grey-gold and sound dies inside it. Whoever stands inside, or walks in,
## chokes: clutches his throat (Person.scream()) and runs for the nearest edge (Person.panic() from the middle: the run
## goes straight out). CHOKE seconds inside kills (damage kind choke, a quiet collapse); leaving saves him, and stepping
## back in starts the CHOKE seconds again. Any role chokes, soldiers and inquisitors too. One standing where nobody can
## leave (a NO LEAVING law: Leaving Is Prohibited's cell) has nowhere to run: he clutches his throat where he stands, so
## the two together are a sure kill. One indoors, or a rite's chained captive, is left alone. Hounds and other Visitors
## flee it (Visitors asks the law) and never die of it. The law itself is a LawZone (NO BREATH) laid on the crowd, which
## the town's choices can ask (Crowd.in_law()); this effect steps it on its own clock and keeps its own books: `choking`,
## each one's seconds inside. Who dies follows how long each has stood inside, never a roll. Loud.

const RADIUS := 2.5
const HOLD_TIME := 8.0
const CHOKE := 3.0
## The proclamation, then the air goes out.
const T_LAND := 0.5
## How long one who starts to choke clutches his throat before he runs.
const CLUTCH := 0.35
## The air comes back over this long once the law lifts (look only).
const FADE := 0.6
## Leeway on the CHOKE seconds, for clocks summed frame by frame.
const EPS := 0.0001

## Whoever chokes now: Person -> seconds inside since he last came in.
var choking := {}
## The law on the place (LawZone, NO BREATH): laid when the air goes, lifted at the end. null before.
var law: LawZone

## Those choking where they stand (nowhere to run), so each is told once.
var _rooted := {}
var _hush: Hush


func _build() -> void:
	duration = T_LAND + HOLD_TIME + FADE
	busy = T_LAND
	at(T_LAND, _land)
	at(T_LAND + HOLD_TIME, _lift)
	ctx.play(&"br_hush", origin)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, origin, 50.0, 64.0, T_LAND, 0.9)
		var mark := FxParts.rings(self, origin, RADIUS, DecreeParts.GILT, 2, 24.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_LAND, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_LAND + 0.1


## The air goes out.
func _land() -> void:
	law = LawZone.circle(origin, RADIUS, [LawZone.NO_BREATH], HOLD_TIME)
	law.stepped_by_holder = true
	if ctx.crowd != null:
		ctx.crowd.add_law(law, self)
	else:
		law.hold_by(self)
	_choke(0.0)
	if not DominionParts.staged(self):
		return
	_hush = Hush.new()
	_hush.fx = self
	_hush.position = Iso.ground_to_screen(origin).round()
	_hush.z_index = 4
	track(_hush, ctx.overhead_back)
	# The air drawn out of it: a grey-gold ring thrown out to the edge, and a dull light that goes.
	var out := FxParts.shockwave(self, origin, RADIUS * 1.15, DecreeParts.GILT_RAMP)
	out.set_param("thickness", 0.12)
	out.tween_param("progress", 0.05, 1.0, 0.45, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	out.tween_param("fade", 1.0, 0.0, 0.2, 0.3)
	out.life = 0.55
	DominionParts.pulse(self, origin, RADIUS, Hush.HAZE_LIGHT, 0.5, 0.8)


## The air comes back: the law is lifted, and whoever was choking breathes again.
func _lift() -> void:
	if law != null:
		if ctx.crowd != null:
			ctx.crowd.remove_law(law)
		else:
			law.lift()
	choking.clear()
	_rooted.clear()
	if DominionParts.staged(self):
		DecreeParts.wave(self, origin, RADIUS * 1.2, 0.5, 0.05)


## Cut short (an act of the night ends): the law is lifted with it.
func end_now() -> void:
	if not finished and law != null and law.alive():
		_lift()
	super()


func _fx_process(delta: float) -> void:
	if law == null or not law.alive():
		return
	# The law's clock starts when the air goes, so it holds to the last frame before the lift.
	var dt := minf(delta, t - T_LAND)
	if ctx.crowd != null:
		ctx.crowd.step_law(law, dt)
	else:
		law.step(dt, [], [])
	_choke(dt)


## One frame of the choking: whoever stands inside now chokes (a newcomer from 0, the rest `delta` more), whoever is
## not inside any more breathes again and is forgotten, and whoever has stood inside CHOKE seconds dies.
func _choke(delta: float) -> void:
	for e in ctx.field.in_rect(law.bounds()):
		var p := e as Person
		if p == null or p.inside or p.chained or not law.contains(p.ground_pos):
			continue
		if choking.has(p):
			choking[p] = float(choking[p]) + delta
		else:
			choking[p] = 0.0
			_rooted.erase(p)
			_gasp(p)
		if not _rooted.has(p) and _held(p):
			# Nowhere to run: he clutches his throat where he stands until it is over.
			_rooted[p] = true
			p.scream(CHOKE - float(choking[p]) + 0.2)
	for p: Variant in choking.keys():
		if not is_instance_valid(p) or not p.is_alive() or p.inside or p.chained or not law.contains(p.ground_pos):
			choking.erase(p)
			_rooted.erase(p)
			continue
		if float(choking[p]) >= CHOKE - EPS:
			choking.erase(p)
			_rooted.erase(p)
			ctx.field.kill(p, &"choke", p.ground_pos)


## The first breath that will not come: he clutches his throat, then runs straight out for the nearest edge.
func _gasp(p: Person) -> void:
	if _held(p):
		return
	p.panic(origin, RADIUS, &"choke", false)
	p.scream(CLUTCH)


## Whether `p` stands where nobody can leave.
func _held(p: Person) -> bool:
	return ctx.crowd != null and ctx.crowd.in_law(p, LawZone.NO_LEAVING)


## How much of the haze shows: up as the air goes, whole while the law holds, gone as the air comes back.
func shown() -> float:
	if t < T_LAND:
		return 0.0
	if t < T_LAND + HOLD_TIME:
		return clampf((t - T_LAND) / 0.3, 0.0, 1.0)
	return clampf(1.0 - (t - T_LAND - HOLD_TIME) / FADE, 0.0, 1.0)


## The airless circle, drawn in screen space round its middle: a grey-gold haze on the ground with a still, thin
## gilt rim and letters of law round it, motes of the last air rising and thinning, and a slow shimmer that moves out
## over it. Over each one choking, a gilt arc that empties as his breath runs out. Its shapes are laid out once; each
## frame only draws them.
class Hush extends Node2D:
	const HAZE := Color(0.5, 0.48, 0.42, 0.34)
	const HAZE_LIGHT := Color(0.86, 0.8, 0.62)
	const MOTES := 26
	const LETTERS := 12
	## A letter of law: three columns, four rows, a row per int, the high bit leftmost.
	const GLYPHS := [[0b111, 0b010, 0b010, 0b111], [0b101, 0b111, 0b101, 0b101], [0b110, 0b101, 0b110, 0b100],
		[0b111, 0b100, 0b110, 0b111]]
	## How high over a person's feet his breath is shown.
	const HEAD := 26.0
	var fx: BreathFx
	var _disc := PackedVector2Array()
	## A unit ring (scaled when drawn as a hairline), and the rim in screen pixels (drawn unscaled, so its widths hold).
	var _rim := PackedVector2Array()
	var _rim_px := PackedVector2Array()

	## The ground circle's half width and half height on screen.
	static func half_axes() -> Vector2:
		return Vector2(RADIUS * 32.0 * sqrt(2.0), RADIUS * 16.0 * sqrt(2.0))

	func _init() -> void:
		for i in 32:
			_disc.append(Vector2.from_angle(TAU * float(i) / 32.0))
		_rim = _disc.duplicate()
		_rim.append(_disc[0])
		var h := half_axes()
		for v in _rim:
			_rim_px.append(v * h)

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
		# The haze, and a little darker at its heart, where the air is thinnest.
		draw_set_transform(Vector2.ZERO, 0.0, h)
		draw_colored_polygon(_disc, Color(HAZE, HAZE.a * a))
		draw_set_transform(Vector2.ZERO, 0.0, h * 0.55)
		draw_colored_polygon(_disc, Color(0.22, 0.2, 0.18, 0.16 * a))
		# The shimmer: two faint rings moving out over it, over and over.
		for k in 2:
			var s := fposmod(now * 0.45 + float(k) * 0.5, 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, h * lerpf(0.15, 1.0, s))
			draw_polyline(_rim, Color(HAZE_LIGHT, 0.55 * a * (1.0 - s)), -1.0)
		# The rim, ink under gilt, so it reads on any ground.
		draw_set_transform(Vector2.ZERO)
		draw_polyline(_rim_px, Color(DecreeParts.INK, 0.6 * a), 4.0)
		draw_polyline(_rim_px, Color(DecreeParts.GILT, 0.95 * a), 2.0)
		# Letters of law round the rim, turning slowly.
		for i in LETTERS:
			var ang := TAU * float(i) / float(LETTERS) + now * 0.08
			var p := Vector2(h.x * 0.86 * cos(ang), h.y * 0.86 * sin(ang)).round()
			var glyph: Array = GLYPHS[i % GLYPHS.size()]
			for r in 4:
				for c in 3:
					if int(glyph[r]) & (1 << (2 - c)):
						draw_rect(Rect2(p + Vector2(c - 1, r - 2), Vector2.ONE), Color(DecreeParts.GILT, 0.95 * a))
		# The last of the air: motes laid out by order (a golden-angle spread), rising and thinning.
		for i in MOTES:
			var ang := TAU * fposmod(float(i) * 0.618034, 1.0)
			var r := sqrt(fposmod(float(i) * 0.381966 + 0.11, 1.0))
			var rise := fposmod(now * 0.35 + float(i) * 0.137, 1.0)
			var p := Vector2(h.x * r * cos(ang), h.y * r * sin(ang) - rise * 22.0).round()
			draw_rect(Rect2(p, Vector2(2.0, 2.0)), Color(HAZE_LIGHT, 0.7 * a * (1.0 - rise)))
		# Over each one choking: his breath, an arc that empties as it runs out.
		for body: Variant in fx.choking:
			if not is_instance_valid(body):
				continue
			var p := body as Person
			var left := clampf(1.0 - float(fx.choking[body]) / CHOKE, 0.0, 1.0)
			var at := (Iso.ground_to_screen(p.ground_pos) - position + Vector2(0.0, -HEAD)).round()
			draw_arc(at, 3.5, -PI * 0.5, -PI * 0.5 + TAU * left, 12, Color(DecreeParts.INK, 0.7 * a), 3.0)
			draw_arc(at, 3.5, -PI * 0.5, -PI * 0.5 + TAU * left, 12, Color(HAZE_LIGHT, 0.95 * a), 1.0)
