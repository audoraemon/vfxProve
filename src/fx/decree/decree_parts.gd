class_name DecreeParts
extends RefCounted
## Shared pieces of the Decree powers (Leaving Is Prohibited, The Bell Lies, Magnify, Abolition): the Authority's
## black and gilt, its signs, the proclamation that opens a cast, and the Seal -- a sign on a black plate hung over a
## place, which a decree can strike through. Nothing here knows any one power.

const GILT := Color("ffcf5a")
const INK := Color("120a1c")
const STRUCK := Color("ff3a30")
const GILT_LIFE := [Color("fff6d0"), Color("ffcf5a"), Color("b07a1c"), Color(0.35, 0.2, 0.05, 0.5)]
const INK_LIFE := [Color("4a3668"), Color("2a1a40"), Color("120a1c"), Color(0.03, 0.01, 0.05, 0.55)]
const GILT_RAMP := [Color(0.5, 0.32, 0.08, 0.4), Color("b07a1c"), Color("ffcf5a"), Color("ffe9a0"), Color("fff6d0")]

## Signs, 5x5, a row per int, the high bit leftmost.
const BARS: Array[int] = [0b11111, 0b10101, 0b10101, 0b10101, 0b11111]
const BELL: Array[int] = [0b00100, 0b01110, 0b01110, 0b11111, 0b00100]
const BELL_DOWN: Array[int] = [0b00100, 0b11111, 0b01110, 0b01110, 0b00100]
const LENS: Array[int] = [0b01100, 0b10010, 0b10010, 0b01110, 0b00001]
const CROWN: Array[int] = [0b10101, 0b10101, 0b11111, 0b11111, 0b00000]
const HOURGLASS: Array[int] = [0b11111, 0b01110, 0b00100, 0b01110, 0b11111]
const SHIELD: Array[int] = [0b11111, 0b11111, 0b11111, 0b01110, 0b00100]


## The proclamation over `at`: the sigil drawn in gilt `up` pixels above the ground over `gather` seconds and held
## `hold`, while ink is drawn in off the ground beneath it.
static func proclaim(fx: FxTimeline, at: Vector2, radius_px: float, up: float, gather: float, hold: float) -> void:
	DominionParts.sky_sigil(fx, at, radius_px, up, GILT, gather, hold)
	var ink := FxParts.particles(fx, fx.ctx.overhead, Iso.ground_to_screen(at), PixelParticles.Shape.PUFF, INK_LIFE)
	ink.drag = 0.8
	ink.gravity = -30.0
	ink.burst(int(radius_px * 0.3), {"radius": radius_px * 0.7, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.INWARD,
		"alt": Vector2(0, 6), "alt_speed": Vector2(8, 40), "life": Vector2(gather * 0.7, gather * 1.3), "size": Vector2(2, 4),
		"size_end_mul": 0.4})


## Ink and gilt thrown off a place.
static func scatter(fx: FxTimeline, at: Vector2, count := 14, up := 8.0) -> void:
	var sp := Iso.ground_to_screen(at) + Vector2(0, -up)
	var gilt := FxParts.particles(fx, fx.ctx.overhead, sp, PixelParticles.Shape.SQUARE, GILT_LIFE)
	gilt.gravity = 60.0
	gilt.drag = 1.4
	gilt.burst(count, {"radius": 4.0, "speed": Vector2(20, 90), "alt": Vector2(0, 6), "alt_speed": Vector2(20, 80),
		"life": Vector2(0.4, 0.9), "size": Vector2(1, 2)})
	var ink := FxParts.particles(fx, fx.ctx.overhead, sp, PixelParticles.Shape.PUFF, INK_LIFE)
	ink.gravity = -14.0
	ink.drag = 1.6
	ink.burst(count / 2, {"radius": 6.0, "speed": Vector2(10, 40), "alt": Vector2(0, 8), "alt_speed": Vector2(6, 30),
		"life": Vector2(0.6, 1.2), "size": Vector2(2, 4), "size_end_mul": 0.5})


## A gilt ring thrown out over the ground to `radius`.
static func wave(fx: FxTimeline, at: Vector2, radius: float, seconds := 0.6, thickness := 0.07) -> QuadFx:
	var w := FxParts.shockwave(fx, at, radius, GILT_RAMP)
	w.set_param("thickness", thickness)
	w.tween_param("progress", 0.05, 1.0, seconds, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	w.tween_param("fade", 1.0, 0.0, seconds * 0.4, seconds * 0.65)
	w.life = seconds + 0.1
	return w


## A Seal for `fx` over `over` (a ground point): `glyph` at `px` screen pixels a cell, `up` above the ground, for `life`.
static func seal(fx: FxTimeline, over: Vector2, glyph: Array[int], life: float, up := 60.0, px := 3) -> Seal:
	var s := Seal.new()
	s.glyph = glyph
	s.over = over
	s.life = life
	s.up = up
	s.px = px
	s.z_index = 8
	fx.track(s, fx.ctx.overhead)
	return s


## A sign on a black plate with a gilt border, hung over a place. strike() draws a red stroke through it (the thing it
## stands for is void); shrink_to() makes it small after `shrink_at` seconds, to stay out of the way while it lasts.
class Seal extends Node2D:
	var glyph: Array[int] = []
	var over := Vector2.ZERO
	var up := 60.0
	var life := 3.0
	var px := 3
	var shrink_at := INF
	var shrink_px := 2
	var _age := 0.0
	var _struck_at := INF

	func strike() -> void:
		_struck_at = _age

	func _process(delta: float) -> void:
		_age += delta
		if _age >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(minf(_age / 0.35, (life - _age) / 0.7), 0.0, 1.0)
		var size := float(shrink_px if _age >= shrink_at else px)
		# It comes down into place, then hangs.
		var drop := (1.0 - clampf(_age / 0.35, 0.0, 1.0)) * -10.0
		var at := (Iso.ground_to_screen(over) + Vector2(0, -up + drop + sin(_age * 1.8) * 1.5)).round()
		var half := Vector2(3.5, 3.5) * size
		draw_rect(Rect2(at - half - Vector2.ONE, half * 2.0 + Vector2(2, 2)), Color(DecreeParts.GILT, 0.9 * a))
		draw_rect(Rect2(at - half, half * 2.0), Color(DecreeParts.INK, 0.92 * a))
		for r in 5:
			for c in 5:
				if glyph[r] & (1 << (4 - c)):
					draw_rect(Rect2(at + Vector2(c - 2.5, r - 2.5) * size, Vector2(size, size)), Color(DecreeParts.GILT, a))
		if _age >= _struck_at:
			# The stroke, corner to corner, drawn in a tenth of a second.
			var k := clampf((_age - _struck_at) / 0.1, 0.0, 1.0)
			var from := at + Vector2(-half.x - 2.0, half.y + 2.0)
			var to := at + Vector2(half.x + 2.0, -half.y - 2.0)
			draw_line(from, from.lerp(to, k), Color(DecreeParts.INK, a), maxf(size, 2.0) + 2.0)
			draw_line(from, from.lerp(to, k), Color(DecreeParts.STRUCK, a), maxf(size, 2.0))
