class_name NoLeaveFx
extends FxTimeline
## Leaving Is Prohibited (Decree, Tier I): a law laid on a patch of ground. T_SEAL after the cast, and for HOLD_TIME,
## nobody within RADIUS of the click can leave it -- any role, and whoever walks in afterwards as well. They are not
## held still and their minds are their own: they walk, flee, fight as they would, and at the edge they simply cannot
## go on (set back onto it each frame; they hesitate and turn, Person.hesitate()). One inside a building is left
## alone until it comes out. One carried more than CARRIED beyond the edge by something greater (a Mirrorfold, a
## blast) is free of it. The bound wear the bars. Quiet, but for the book entry's "alarm".

const RADIUS := 3.0
const HOLD_TIME := 15.0
const T_SEAL := 0.6
const CARRIED := 1.5
const JOIN_EVERY := 0.2
const TURN_EVERY := 1.2
const PILLARS := 16
## How tall the wall's posts stand, in screen pixels.
const TALL := 16.0

## The bound: Person -> seconds until it may be turned back again.
var bound := {}
## Whether the law holds now, and how many times someone has been turned back at the edge.
var sealed := false
var turned_back := 0

var _join_in := 0.0
var _wall: Wall


func _build() -> void:
	duration = T_SEAL + HOLD_TIME + 0.8
	busy = T_SEAL
	at(T_SEAL, _seal)
	at(T_SEAL + HOLD_TIME, _lift)
	ctx.play(&"hs_charge", origin, -10.0)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, origin, 60.0, 70.0, T_SEAL, 1.2)
		var mark := FxParts.rings(self, origin, RADIUS, DecreeParts.GILT, 2, 24.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_SEAL, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_SEAL + 0.1


func _seal() -> void:
	sealed = true
	_join()
	ctx.play(&"jg_rise", origin, -10.0)
	if not DominionParts.staged(self):
		return
	_wall = Wall.new()
	_wall.fx = self
	_wall.position = origin
	_wall.z_index = 3
	track(_wall, ctx.ground)
	var posts := Posts.new()
	posts.fx = self
	posts.z_index = 4
	track(posts, ctx.overhead_back)
	DecreeParts.seal(self, origin, DecreeParts.BARS, 2.6, 64.0)
	DominionParts.pulse(self, origin, RADIUS, DecreeParts.GILT, 0.5, 1.0)
	# The wall closes in from outside.
	var close := FxParts.shockwave(self, origin, RADIUS * 1.6, DecreeParts.GILT_RAMP)
	close.set_param("thickness", 0.05)
	close.tween_param("progress", 1.0, 0.62, 0.35, 0.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	close.tween_param("fade", 1.0, 0.0, 0.12, 0.25)
	close.life = 0.4


func _lift() -> void:
	sealed = false
	for p: Person in bound:
		if is_instance_valid(p):
			p.clear_badge()
	bound.clear()
	if DominionParts.staged(self):
		DecreeParts.wave(self, origin, RADIUS * 1.3, 0.5, 0.05)


## Whoever stands inside now is bound.
func _join() -> void:
	var left := maxf(T_SEAL + HOLD_TIME - t, 0.1)
	for p in DominionParts.near(ctx.field, origin, RADIUS):
		if not bound.has(p):
			bound[p] = 0.0
			p.set_badge(DecreeParts.BARS, DecreeParts.GILT, left)


func _fx_process(delta: float) -> void:
	if not sealed:
		return
	_join_in -= delta
	if _join_in <= 0.0:
		_join_in = JOIN_EVERY
		_join()
	for p: Person in bound.keys():
		if not is_instance_valid(p) or not p.is_alive():
			bound.erase(p)
			continue
		if p.inside:
			continue
		bound[p] = maxf(float(bound[p]) - delta, 0.0)
		var d := p.ground_pos - origin
		var far := d.length()
		if far > RADIUS + CARRIED:
			bound.erase(p)
			p.clear_badge()
		elif far > RADIUS:
			p.ground_pos = origin + d / far * RADIUS
			if float(bound[p]) <= 0.0:
				bound[p] = TURN_EVERY
				turned_back += 1
				p.hesitate(0.6)
				if _wall != null and is_instance_valid(_wall):
					_wall.strikes.append([d.angle(), 0.0])


## How much of the wall shows: up as the law lands, down as it lifts.
func shown() -> float:
	return clampf(minf((t - T_SEAL) / 0.3, (T_SEAL + HOLD_TIME + 0.6 - t) / 0.6), 0.0, 1.0)


## The boundary on the ground: a slow-turning broken ring in gilt with a dark band inside it, and a bright arc where
## someone has just been turned back ([angle, age]).
class Wall extends Node2D:
	const STRIKE_LIFE := 0.5
	var fx: NoLeaveFx
	var strikes: Array = []

	func _process(delta: float) -> void:
		for s in strikes:
			s[1] += delta
		strikes = strikes.filter(func(s): return s[1] < STRIKE_LIFE)
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		# A black band the gilt can be read against on any ground, and a faint wash of gilt inside it.
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 72, Color(DecreeParts.INK, 0.7 * a), 0.3)
		draw_arc(Vector2.ZERO, RADIUS - 0.35, 0.0, TAU, 72, Color(DecreeParts.GILT, 0.12 * a), 0.4)
		var turn := fx.t * 0.25
		var dash := TAU / 24.0
		for i in 24:
			draw_arc(Vector2.ZERO, RADIUS, turn + dash * float(i), turn + dash * (float(i) + 0.68), 6, Color(DecreeParts.GILT, 0.95 * a), 0.12)
		for s in strikes:
			var k := 1.0 - float(s[1]) / STRIKE_LIFE
			var span := 0.25 + 0.3 * (1.0 - k)
			draw_arc(Vector2.ZERO, RADIUS, float(s[0]) - span, float(s[0]) + span, 10, Color(1.0, 0.97, 0.82, k * a), 0.3)
			draw_arc(Vector2.ZERO, RADIUS + 0.06, float(s[0]) - span, float(s[0]) + span, 10, Color(DecreeParts.GILT, k * a), 0.1)


## The posts of the wall: thin lights standing round the ring, flaring where someone is turned back.
class Posts extends Node2D:
	var fx: NoLeaveFx

	func _process(_delta: float) -> void:
		if fx.t > T_SEAL + HOLD_TIME + 0.7:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var turn := fx.t * 0.25
		var tops := PackedVector2Array()
		for i in PILLARS:
			var ang := turn + TAU * float(i) / float(PILLARS)
			var foot := Iso.ground_to_screen(fx.origin + Vector2.from_angle(ang) * RADIUS).round()
			var flick := 0.8 + 0.2 * sin(fx.t * 5.0 + float(i) * 1.7)
			var tall := roundf(TALL + 2.0 * sin(fx.t * 2.0 + float(i)))
			tops.append(foot + Vector2(0, -tall))
			draw_rect(Rect2(foot + Vector2(-2, -tall - 1), Vector2(4, tall + 2)), Color(DecreeParts.INK, 0.55 * a))
			draw_rect(Rect2(foot + Vector2(-1, -tall), Vector2(2, tall)), Color(DecreeParts.GILT, 0.85 * a * flick))
			draw_rect(Rect2(foot + Vector2(-2, -tall - 2), Vector2(4, 3)), Color(1.0, 0.96, 0.8, a * flick))
		# The rail from post to post: the wall's top edge.
		tops.append(tops[0])
		draw_polyline(tops, Color(DecreeParts.GILT, 0.45 * a), 1.0)
		if fx._wall == null or not is_instance_valid(fx._wall):
			return
		for s in fx._wall.strikes:
			var k := 1.0 - float(s[1]) / Wall.STRIKE_LIFE
			var foot := Iso.ground_to_screen(fx.origin + Vector2.from_angle(float(s[0])) * RADIUS).round()
			draw_rect(Rect2(foot + Vector2(-1, -22), Vector2(2, 22)), Color(1.0, 0.95, 0.75, 0.8 * k * a))
			draw_rect(Rect2(foot + Vector2(-4, -12), Vector2(8, 1)), Color(DecreeParts.GILT, k * a))
