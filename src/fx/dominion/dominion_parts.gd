class_name DominionParts
extends RefCounted
## What the Dominion powers share: who is near a point, the sigil in the sky and on the ground, a floating glyph over a
## place or a person, and the thin threads of light that jump between people or to a place and fade.

const SH_SIGIL := preload("res://shaders/divine_sigil.gdshader")
const GOLD := Color("ffe9a8")
const CRIMSON := Color("ff4040")
const GOLD_LIFE := [Color("fffdf0"), Color("ffe9a8"), Color("e8c070"), Color(0.8, 0.6, 0.3, 0.5)]
const SKY_SQUASH := 0.42
## Five-by-five glyphs (Person.GLYPH_*'s form): linked rings, speech waves, a split emblem, a blade, an eye, a
## hammer, a cross, a roof, an arrow, a shut eye, a flame.
const RINGS: Array[int] = [0b01110, 0b10001, 0b01110, 0b10001, 0b01110]
const WAVES: Array[int] = [0b10101, 0b01010, 0b00000, 0b10101, 0b01010]
const SPLIT: Array[int] = [0b11011, 0b10011, 0b11011, 0b11001, 0b11011]
const BLADE: Array[int] = [0b00100, 0b00100, 0b00100, 0b01110, 0b00100]
const EYE: Array[int] = [0b00000, 0b01110, 0b10101, 0b01110, 0b00000]
const HAMMER: Array[int] = [0b01110, 0b01110, 0b00100, 0b00100, 0b00100]
const CROSS: Array[int] = [0b00100, 0b01110, 0b00100, 0b00100, 0b00100]
const ROOF: Array[int] = [0b00100, 0b01010, 0b10001, 0b10001, 0b11111]
const ARROW: Array[int] = [0b00100, 0b00010, 0b11111, 0b00010, 0b00100]
const SHUT_EYE: Array[int] = [0b00000, 0b00000, 0b11111, 0b01110, 0b00000]
const FLAME: Array[int] = [0b00100, 0b01100, 0b01110, 0b11111, 0b01110]


## Whether there is a stage to play on (a headless test hands an effect only the field and the ground).
static func staged(fx: FxTimeline) -> bool:
	return fx.ctx.impact != null and fx.is_inside_tree()


## The living out in the open within `r` of `at`, nearest first, `most` at most.
static func near(field: EnemyField, at: Vector2, r: float, most := 9999) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, r):
		var p := e as Person
		if p != null and not p.inside:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out.slice(0, most)


## Where someone goes home to: a citizen's home, a soldier's post, else where it keeps to.
static func home_of(p: Person) -> Vector2:
	if p.soldier and p.post != Vector2.INF:
		return p.post
	if p.profile != null and p.profile.home != Vector2.INF:
		return p.profile.home
	return p.anchor


## The Dominion sigil hanging over `at`, `radius_px` wide, `up` pixels above the ground: drawn out over `gather`
## seconds, held `hold`, then gone.
static func sky_sigil(fx: FxTimeline, at: Vector2, radius_px: float, up: float, color: Color, gather: float, hold: float) -> QuadFx:
	var q := FxParts.quad(fx, SH_SIGIL, Vector2(radius_px * 2.0, radius_px * 2.0 * SKY_SQUASH), fx.ctx.overhead)
	q.position = Iso.ground_to_screen(at) + Vector2(0, -up)
	q.z_index = 6
	q.set_param("color", color)
	q.set_param("px", 1.0 / (radius_px * 0.62))
	q.tween_param("reveal", 0.0, 1.0, gather, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	q.tween_param("alpha", 1.0, 0.0, 1.2, gather + hold, Tween.TRANS_QUAD, Tween.EASE_IN)
	q.life = gather + hold + 1.25
	return q


## The same sigil on the ground round `at`, `radius` ground units.
static func ground_sigil(fx: FxTimeline, at: Vector2, radius: float, color: Color, gather: float, hold: float) -> QuadFx:
	var q := FxParts.quad(fx, SH_SIGIL, Vector2.ONE * radius * 2.0, fx.ctx.ground)
	q.position = at
	q.z_index = 3
	q.set_param("color", color)
	q.set_param("px", FxParts.px_for_radius(radius))
	q.tween_param("reveal", 0.0, 1.0, gather, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	q.tween_param("alpha", 1.0, 0.0, 1.5, gather + hold, Tween.TRANS_QUAD, Tween.EASE_IN)
	q.life = gather + hold + 1.55
	return q


## A soft pulse of light on the ground at `at`.
static func pulse(fx: FxTimeline, at: Vector2, radius: float, color: Color, strength := 0.7, seconds := 1.2) -> void:
	var l := FxParts.ground_light(fx, at, radius, color, strength)
	l.tween_param("intensity", strength, 0.0, seconds, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	l.life = seconds + 0.05


## A few motes off someone (or a place) in `ramp`.
static func motes(fx: FxTimeline, at: Vector2, ramp: Array, count := 8) -> void:
	var m := FxParts.particles(fx, fx.ctx.overhead, Iso.ground_to_screen(at) + Vector2(0, -8), PixelParticles.Shape.SQUARE, ramp)
	m.gravity = -24.0
	m.drag = 1.0
	m.burst(count, {"radius": 5.0, "speed": Vector2(4, 16), "alt": Vector2(0, 8), "alt_speed": Vector2(10, 34),
		"life": Vector2(0.5, 0.9), "size": Vector2(1, 1)})


## Threads of light that fade: between two people, or from a person to a point. add() one; it draws itself
## for LIFE seconds, following whoever it is tied to.
class Links extends Node2D:
	const LIFE := 0.8
	## [from (Person or Vector2 ground), to (Person or Vector2 screen), colour, born]
	var links: Array = []
	var _clock := 0.0

	func add(from: Variant, to: Variant, color: Color) -> void:
		links.append([from, to, color, _clock])

	func _process(delta: float) -> void:
		_clock += delta
		if not links.is_empty():
			links = links.filter(func(l: Array) -> bool: return _clock - float(l[3]) < LIFE)
			queue_redraw()

	static func _point(v: Variant) -> Vector2:
		if v is Vector2:
			return v
		if is_instance_valid(v):
			return Iso.ground_to_screen((v as Person).ground_pos) + Vector2(0, -14)
		return Vector2.INF

	func _draw() -> void:
		for l: Array in links:
			var a := _point(l[0])
			var b := _point(l[1])
			if a == Vector2.INF or b == Vector2.INF:
				continue
			var k := 1.0 - (_clock - float(l[3])) / LIFE
			# An arc, not a straight line: it jumps.
			var mid := (a + b) * 0.5 + Vector2(0, -12.0 - a.distance_to(b) * 0.12)
			draw_polyline(PackedVector2Array([a, a.lerp(mid, 0.5) + Vector2(0, -3), mid, b.lerp(mid, 0.5) + Vector2(0, -3), b]),
				Color(l[2], 0.7 * k), 1.0)


## A glyph floating over a place (ground point) or a person, twice the size of the ones people wear: a target's brand,
## a destination's anchor. Bobs; fades in and out with `life`.
class Icon extends Node2D:
	var glyph: Array[int] = []
	var color := Color.WHITE
	var over: Variant = Vector2.ZERO
	var up := 34.0
	var life := 5.0
	var px := 2
	var _age := 0.0

	func _process(delta: float) -> void:
		_age += delta
		if _age >= life or (over is Object and not is_instance_valid(over)):
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var at: Vector2 = Iso.ground_to_screen(over) if over is Vector2 else Iso.ground_to_screen((over as Person).ground_pos)
		at += Vector2(0, -up + sin(_age * 2.4) * 2.0)
		var a := clampf(minf(_age / 0.3, (life - _age) / 0.6), 0.0, 1.0)
		var size := float(px)
		draw_rect(Rect2(at + Vector2(-3.5, -3.5) * size, Vector2(7, 7) * size), Color(0.12, 0.06, 0.03, 0.85 * a))
		for r in 5:
			for c in 5:
				if glyph[r] & (1 << (4 - c)):
					draw_rect(Rect2(at + Vector2(c - 2.5, r - 2.5) * size, Vector2(size, size)), Color(color, a))
		draw_arc(at, 6.0 * size, 0.0, TAU, 20, Color(color, 0.6 * a), 1.0)


## A Links layer for `fx`.
static func links(fx: FxTimeline) -> Links:
	var l := Links.new()
	l.z_index = 5
	fx.track(l, fx.ctx.overhead)
	return l


## An Icon for `fx`.
static func icon(fx: FxTimeline, over: Variant, glyph: Array[int], color: Color, life: float, up := 34.0) -> Icon:
	var i := Icon.new()
	i.glyph = glyph
	i.color = color
	i.over = over
	i.life = life
	i.up = up
	i.z_index = 8
	fx.track(i, fx.ctx.overhead)
	return i
