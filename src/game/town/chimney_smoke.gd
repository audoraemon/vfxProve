class_name ChimneySmoke
extends Node2D
## Smoke curling up from every standing cottage's chimney, all drawn by this one node in stepped 8 Hz frames:
## a few pale puffs per chimney rise, drift and fade on a loop, each chimney out of step with the rest. A house
## that falls stops smoking. It dims with the ambient light like everything else.

const BenchProf := preload("res://src/core/bench_prof.gd")
const STEP := 0.125
## Seconds a puff takes to rise and vanish, how high it goes (px) and how far it drifts.
const CYCLE := 2.8
const RISE := 18.0
const DRIFT := 5.0
const PUFFS := 4

var lights: LightField
## The town's DAY and NIGHT looks (set by Town.build): taller, fuller plumes with thin wisps between the puffs (TALL_*).
## Off (CURRENT): the plume is drawn exactly as before.
var tall := false
const TALL_CYCLE := 4.2
const TALL_RISE := 34.0
const TALL_DRIFT := 11.0
const TALL_PUFFS := 7
var _houses: Array[Structure] = []
var _time := 0.0
var _next := 0.0


func setup(houses: Array[Structure]) -> ChimneySmoke:
	_houses = houses.duplicate()
	return self


## Standing houses that have a chimney.
func wisp_count() -> int:
	var n := 0
	for h in _houses:
		if _smokes(h):
			n += 1
	return n


func _smokes(h: Structure) -> bool:
	return is_instance_valid(h) and not h.destroyed and h._collapse < 0.0 and tip_of(h) != Vector2.INF


## Where a house's smoke leaves its chimney (px from its front corner; INF for none): its sprite's chimney when it is
## drawn from a sprite (whose own smoke, if drawn in, means none here), else the procedural art's.
static func tip_of(h: Structure) -> Vector2:
	if h.sprite.is_empty():
		# Drawn procedurally, only a house has a chimney (a ChatGPT armoury or monastery without its sprite has none).
		return HouseArt.chimney_top(h) if h.kind == Structure.Kind.HOUSE else Vector2.INF
	var c: Vector2 = h.sprite.chimney
	if c == Vector2.INF:
		return c
	var at: Vector2 = h.sprite.anchor
	return Vector2((c.x - at.x) * (-1.0 if h.sprite.mirror else 1.0), c.y - at.y)


func _process(delta: float) -> void:
	_time += delta
	if _time >= _next:
		_next = _time + STEP
		queue_redraw()


func _draw() -> void:
	var t0 := BenchProf.begin()
	_draw_all()
	BenchProf.add(&"smoke_draw", t0)


func _draw_all() -> void:
	if tall:
		_draw_tall()
		return
	var amb := maxf(lights.ambient, 0.3) if lights else 1.0
	for i in _houses.size():
		var h := _houses[i]
		if not _smokes(h):
			continue
		var tip := h.position + tip_of(h) - position
		var phase := float(i * 37 % 100) / 100.0 * CYCLE
		for k in PUFFS:
			var t := fposmod(_time + phase + k * CYCLE / PUFFS, CYCLE) / CYCLE
			var size := roundf(lerpf(2.0, 5.0, t))
			var p := (tip + Vector2(sin(t * 5.0 + i) * 1.5 + t * DRIFT, -t * RISE)).round()
			var grey := lerpf(0.85, 0.7, t) * amb
			draw_rect(Rect2(p - Vector2(size, size) * 0.5, Vector2(size, size)), Color(grey, grey, grey, 0.45 * (1.0 - t)))


## The looks' plume: more puffs rising higher and drifting further on a slower loop, each trailing a thin wisp (a 1 px
## line of fading pixels back toward the one below it).
func _draw_tall() -> void:
	var amb := maxf(lights.ambient, 0.3) if lights else 1.0
	for i in _houses.size():
		var h := _houses[i]
		if not _smokes(h):
			continue
		var tip := h.position + tip_of(h) - position
		var phase := float(i * 37 % 100) / 100.0 * TALL_CYCLE
		for k in TALL_PUFFS:
			var t := fposmod(_time + phase + k * TALL_CYCLE / TALL_PUFFS, TALL_CYCLE) / TALL_CYCLE
			var size := roundf(lerpf(2.0, 6.0, t))
			var p := (tip + Vector2(sin(t * 4.0 + i) * 2.0 + t * t * TALL_DRIFT, -t * TALL_RISE)).round()
			var grey := lerpf(0.97, 0.8, t) * amb
			var a := 0.72 * (1.0 - t * t)
			draw_rect(Rect2(p - Vector2(size, size) * 0.5, Vector2(size, size)), Color(grey, grey, grey, a))
			# The wisp: a thin trail of single pixels down toward where this puff came from.
			var t0 := maxf(t - 0.06, 0.0)
			var q := (tip + Vector2(sin(t0 * 4.0 + i) * 2.0 + t0 * t0 * TALL_DRIFT, -t0 * TALL_RISE)).round()
			var steps := int(maxf(absf(q.y - p.y), 1.0))
			for j in range(1, steps, 2):
				var w := p.lerp(q, float(j) / steps).round()
				draw_rect(Rect2(w, Vector2.ONE), Color(grey, grey, grey, a * 0.6))
