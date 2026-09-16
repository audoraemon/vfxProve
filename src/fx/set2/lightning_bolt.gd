class_name LightningBolt
extends Node2D
## Jagged lightning bolt between two screen points with forked branches.
## Layers: wide dim glow strokes, bright colored strokes, white core. Re-jitters rapidly while alive.

var from := Vector2.ZERO
var to := Vector2.ZERO
var life := 0.2
var thickness := 1.0
var branches := 2
var glow := Color("5aa8ff")
var rng := RandomNumberGenerator.new()
var _age := 0.0
var _next_jitter := 0.0
var _main := PackedVector2Array()
var _forks: Array[PackedVector2Array] = []


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	_next_jitter -= delta
	if _next_jitter <= 0.0:
		_next_jitter = 0.045
		_rebuild()
	queue_redraw()


func _rebuild() -> void:
	_main = _jag(from, to, maxi(int(from.distance_to(to) / 9.0), 4), from.distance_to(to) * 0.09)
	_forks.clear()
	for i in branches:
		var k := rng.randi_range(1, _main.size() - 2)
		var start := _main[k]
		var dir := (to - from).normalized().rotated(rng.randf_range(-0.9, 0.9))
		var fork_len := from.distance_to(to) * rng.randf_range(0.15, 0.35)
		_forks.append(_jag(start, start + dir * fork_len, 4, fork_len * 0.15))


func _jag(a: Vector2, b: Vector2, segs: int, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array([a.round()])
	var perp := (b - a).orthogonal().normalized()
	for i in range(1, segs):
		var t := float(i) / segs
		pts.append((a.lerp(b, t) + perp * rng.randf_range(-amp, amp)).round())
	pts.append(b.round())
	return pts


func _draw() -> void:
	if _main.size() < 2:
		return
	var fade := 1.0 - smoothstep(0.6, 1.0, _age / life)
	var flick := 0.75 + 0.25 * float(rng.randi() % 2)
	var outer := Color(glow.darkened(0.2), 0.45 * fade * flick)
	var mid := Color(glow.lightened(0.2), fade * flick)
	var core := Color(1, 1, 1, fade)
	var t := int(round(thickness))
	for pts in [_main] + _forks:
		var main: bool = pts == _main
		var w: int = t if main else maxi(t - 1, 0)
		for o in range(-w - 1, w + 2):
			_stroke(pts, Vector2(o, 0), outer)
		for o in range(-w, w + 1):
			_stroke(pts, Vector2(o, 0), mid)
		_stroke(pts, Vector2.ZERO, core if main else mid)


func _stroke(pts: PackedVector2Array, off: Vector2, col: Color) -> void:
	for i in pts.size() - 1:
		draw_line(pts[i] + off, pts[i + 1] + off, col, -1.0)
