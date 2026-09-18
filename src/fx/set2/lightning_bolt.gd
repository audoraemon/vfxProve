class_name LightningBolt
extends Node2D
## Jagged lightning bolt between two screen points with forked branches.
## Layers: wide dim glow strokes, bright colored strokes, white core (wider on thick bolts). The shape comes from
## midpoint displacement (a big wander with finer jags on top) and re-rolls every `jitter_every` seconds.

var from := Vector2.ZERO
var to := Vector2.ZERO
var life := 0.2
var thickness := 1.0
var branches := 2
var glow := Color("5aa8ff")
## Seconds between re-rolls of the bolt's shape.
var jitter_every := 0.045
## Fork length range as a fraction of the bolt, and how far forks may swing off the bolt's direction (radians).
var fork_reach := Vector2(0.15, 0.35)
var fork_angle := 0.9
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
	# Fade and flicker through modulate so the strokes only redraw when the shape re-rolls.
	var fade := 1.0 - smoothstep(0.6, 1.0, _age / life)
	modulate.a = fade * (0.75 + 0.25 * float(rng.randi() % 2))
	_next_jitter -= delta
	if _next_jitter <= 0.0:
		_next_jitter = jitter_every
		_rebuild()
		queue_redraw()


func _rebuild() -> void:
	var dist := from.distance_to(to)
	_main = _jag(from, to, maxi(int(dist / 9.0), 4), dist * 0.1)
	_forks.clear()
	for i in branches:
		var k := rng.randi_range(1, _main.size() - 2)
		var start := _main[k]
		var dir := (to - from).normalized().rotated(rng.randf_range(-fork_angle, fork_angle))
		var fork_len := dist * rng.randf_range(fork_reach.x, fork_reach.y)
		_forks.append(_jag(start, start + dir * fork_len, maxi(int(fork_len / 8.0), 3), fork_len * 0.14))


## Midpoint displacement between a and b: each level splits every segment and pushes the new point sideways,
## halving the push each time, until there are at least `segs` segments.
func _jag(a: Vector2, b: Vector2, segs: int, amp: float) -> PackedVector2Array:
	var perp := (b - a).orthogonal().normalized()
	var pts: Array[Vector2] = [a, b]
	var push := amp
	while pts.size() - 1 < segs:
		var next: Array[Vector2] = [pts[0]]
		for i in pts.size() - 1:
			next.append((pts[i] + pts[i + 1]) * 0.5 + perp * rng.randf_range(-push, push))
			next.append(pts[i + 1])
		pts = next
		push *= 0.5
	var out := PackedVector2Array()
	for p in pts:
		out.append(p.round())
	return out


func _draw() -> void:
	if _main.size() < 2:
		return
	var outer := Color(glow.darkened(0.2), 0.45)
	var mid := Color(glow.lightened(0.2), 1.0)
	var core := Color(1, 1, 1, 1)
	var t := int(round(thickness))
	var all: Array[PackedVector2Array] = [_main]
	all.append_array(_forks)
	for n in all.size():
		var pts := all[n]
		var w: int = t if n == 0 else maxi(t - 1, 0)
		_stroke(pts, 2 * w + 3, outer)
		_stroke(pts, 2 * w + 1, mid)
		# White core: a single pixel on thin strokes, wider down thick ones.
		_stroke(pts, 2 * maxi(w - 1, 0) + 1, core if n == 0 or w >= 2 else mid)


## One polyline stroke `width` pixels wide (a crisp hairline at 1).
func _stroke(pts: PackedVector2Array, width: int, col: Color) -> void:
	draw_polyline(pts, col, -1.0 if width <= 1 else float(width))
