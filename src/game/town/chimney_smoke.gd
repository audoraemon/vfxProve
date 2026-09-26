class_name ChimneySmoke
extends Node2D
## Smoke curling up from every standing cottage's chimney, all drawn by this one node in stepped 8 Hz frames:
## a few pale puffs per chimney rise, drift and fade on a loop, each chimney out of step with the rest. A house
## that falls stops smoking. It dims with the ambient light like everything else.

const STEP := 0.125
## Seconds a puff takes to rise and vanish, how high it goes (px) and how far it drifts.
const CYCLE := 2.8
const RISE := 18.0
const DRIFT := 5.0
const PUFFS := 4

var lights: LightField
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
	return is_instance_valid(h) and not h.destroyed and h._collapse < 0.0 and HouseArt.chimney_top(h) != Vector2.INF


func _process(delta: float) -> void:
	_time += delta
	if _time >= _next:
		_next = _time + STEP
		queue_redraw()


func _draw() -> void:
	var amb := maxf(lights.ambient, 0.3) if lights else 1.0
	for i in _houses.size():
		var h := _houses[i]
		if not _smokes(h):
			continue
		var tip := h.position + HouseArt.chimney_top(h) - position
		var phase := float(i * 37 % 100) / 100.0 * CYCLE
		for k in PUFFS:
			var t := fposmod(_time + phase + k * CYCLE / PUFFS, CYCLE) / CYCLE
			var size := roundf(lerpf(2.0, 5.0, t))
			var p := (tip + Vector2(sin(t * 5.0 + i) * 1.5 + t * DRIFT, -t * RISE)).round()
			var grey := lerpf(0.85, 0.7, t) * amb
			draw_rect(Rect2(p - Vector2(size, size) * 0.5, Vector2(size, size)), Color(grey, grey, grey, 0.45 * (1.0 - t)))
