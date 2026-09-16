class_name PixelParticles
extends Node2D
## Lightweight pixel particle system. Particles move on the (iso-squashed) ground plane
## plus an altitude axis, so debris arcs up and lands where it should.

enum Shape { SQUARE, PUFF, STREAK, CHUNK }
enum Dir { ANGLE, OUTWARD, INWARD }

class Particle:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var alt := 0.0
	var valt := 0.0
	var life := 1.0
	var age := 0.0
	var size := 1.0
	var size_end := 1.0
	var tint := 0.0

var shape := Shape.SQUARE
## Colors sampled in steps over lifetime (no smooth blend: pixel-art look).
var ramp := PackedColorArray([Color.WHITE])
## Pulls altitude down (px/s^2). Negative makes particles rise faster over time.
var gravity := 0.0
## Fraction of velocity lost per second.
var drag := 0.0
var iso_squash := 0.5
var bounce := false
var emitting := false
## Particles per second while emitting.
var rate := 0.0
## Spawn spec used by continuous emission. See burst().
var spec := {}
var auto_free := true
## STREAK tail length in seconds of velocity.
var streak_len := 0.04
var rng := RandomNumberGenerator.new()
## Draw a dark pixel shadow on the ground under airborne particles.
var shadows := false
## PUFF: warm light from below early in life (fire-lit smoke). Alpha 0 disables.
var underglow := Color(0, 0, 0, 0)
## Fraction of lifetime the underglow lasts.
var underglow_life := 0.4

var _particles: Array[Particle] = []
var _accum := 0.0
var _spawned_any := false


## Spec keys (all optional):
##   radius: float px spawn disc; speed: Vector2(min,max) px/s; angle: Vector2(min,max) rad;
##   dir: Dir; alt: Vector2; alt_speed: Vector2; life: Vector2; size: Vector2;
##   size_end_mul: float; offset: Vector2 px added to spawn point; velocity: Vector2 px/s override.
func burst(count: int, s: Dictionary) -> void:
	for i in count:
		_spawn(s)


func _rand(s: Dictionary, key: String, default: Vector2) -> float:
	var r: Vector2 = s.get(key, default)
	return rng.randf_range(r.x, r.y)


func _spawn(s: Dictionary) -> void:
	var p := Particle.new()
	var radius: float = s.get("radius", 0.0)
	var off := Vector2.RIGHT.rotated(rng.randf() * TAU) * radius * sqrt(rng.randf())
	p.pos = Vector2(off.x, off.y * iso_squash) + s.get("offset", Vector2.ZERO)
	var speed := _rand(s, "speed", Vector2.ZERO)
	var dir: Vector2
	match s.get("dir", Dir.ANGLE):
		Dir.OUTWARD:
			dir = off.normalized() if off.length() > 0.01 else Vector2.RIGHT.rotated(rng.randf() * TAU)
		Dir.INWARD:
			dir = -off.normalized() if off.length() > 0.01 else Vector2.ZERO
		_:
			dir = Vector2.RIGHT.rotated(_rand(s, "angle", Vector2(0, TAU)))
	p.vel = Vector2(dir.x, dir.y * iso_squash) * speed
	if s.has("velocity"):
		p.vel = s.velocity
	p.alt = _rand(s, "alt", Vector2.ZERO)
	p.valt = _rand(s, "alt_speed", Vector2.ZERO)
	p.life = maxf(_rand(s, "life", Vector2(0.5, 1.0)), 0.01)
	p.size = _rand(s, "size", Vector2(1, 1))
	p.size_end = p.size * float(s.get("size_end_mul", 1.0))
	p.tint = rng.randf()
	_particles.append(p)
	_spawned_any = true


func _process(delta: float) -> void:
	if emitting and rate > 0.0:
		_accum += rate * delta
		while _accum >= 1.0:
			_accum -= 1.0
			_spawn(spec)
	var i := 0
	while i < _particles.size():
		var p := _particles[i]
		p.age += delta
		if p.age >= p.life:
			_particles.remove_at(i)
			continue
		p.vel *= maxf(1.0 - drag * delta, 0.0)
		p.pos += p.vel * delta
		p.valt -= gravity * delta
		p.alt += p.valt * delta
		if gravity > 0.0 and p.alt < 0.0:
			p.alt = 0.0
			if bounce and absf(p.valt) > 25.0:
				p.valt = -p.valt * 0.35
				p.vel *= 0.6
			else:
				p.valt = 0.0
				p.vel *= 0.85
		i += 1
	queue_redraw()
	if auto_free and _spawned_any and not emitting and _particles.is_empty():
		queue_free()


func _draw() -> void:
	var steps := ramp.size()
	if shadows:
		for p in _particles:
			if p.alt > 1.5:
				var sw := maxf(1.0, roundf(p.size * 0.8))
				draw_rect(Rect2(p.pos.round() - Vector2(floor(sw * 0.5), 0), Vector2(sw, 1)), Color(0, 0, 0, 0.35))
	for p in _particles:
		var k := p.age / p.life
		var col := ramp[mini(int(k * steps), steps - 1)]
		var sz := lerpf(p.size, p.size_end, k)
		var at := (p.pos + Vector2(0, -p.alt)).round()
		match shape:
			Shape.SQUARE:
				var s := maxf(1.0, roundf(sz))
				draw_rect(Rect2(at - Vector2(floor(s * 0.5), floor(s * 0.5)), Vector2(s, s)), col)
			Shape.PUFF:
				_draw_puff(at, sz, col, k)
			Shape.STREAK:
				var tail := at - (p.vel + Vector2(0, -p.valt)) * streak_len * clampf(sz, 0.5, 4.0)
				draw_line(tail.round(), at, col, -1.0)
				draw_rect(Rect2(at, Vector2.ONE), col.lightened(0.3))
			Shape.CHUNK:
				_draw_chunk(p, at, sz, col)


## Three-tone smoke ball: shadowed lower-right, body, lit upper-left, optional fire underglow.
func _draw_puff(at: Vector2, sz: float, col: Color, k: float) -> void:
	var r := maxf(1.0, roundf(sz))
	if r < 3.0:
		draw_circle(at, r, col)
		return
	var shade := Color(col.darkened(0.14), col.a)
	draw_circle(at + Vector2(roundf(r * 0.2), roundf(r * 0.2)), r, shade)
	draw_circle(at, roundf(r * 0.9), col)
	draw_circle(at + Vector2(-roundf(r * 0.3), -roundf(r * 0.35)), roundf(r * 0.5), Color(col.lightened(0.07), col.a))
	if underglow.a > 0.0 and k < underglow_life:
		var g := 1.0 - k / underglow_life
		var glow := Color(col.lerp(underglow, 0.75 * g), col.a)
		draw_circle(at + Vector2(0, roundf(r * 0.45)), roundf(r * 0.55), glow)


## Angular rock fragment with a lit top edge, tumbling over its lifetime.
func _draw_chunk(p: Particle, at: Vector2, sz: float, col: Color) -> void:
	if sz < 2.0:
		draw_rect(Rect2(at, Vector2.ONE * maxf(1.0, roundf(sz))), col)
		return
	# Tumble while airborne; points stay unrounded so triangulation never sees duplicates.
	var spin := (p.tint - 0.5) * 12.0 * (1.0 if p.alt > 0.5 else 0.0)
	var base_angle := p.tint * TAU + p.age * spin
	var pts := PackedVector2Array()
	var lit := PackedVector2Array()
	var n := 5
	for i in n:
		var a := base_angle + TAU * i / n
		var jitter := fposmod(sin(float(i) * 12.9898 + p.tint * 78.233) * 43758.5453, 1.0)
		var rr := sz * (0.6 + 0.45 * jitter)
		var v := Vector2(cos(a), sin(a)) * rr
		pts.append(at + v)
		lit.append(at + v * 0.55 + Vector2(-0.6, -0.8) * sz * 0.3)
	draw_colored_polygon(pts, Color(col.darkened(0.3), col.a))
	draw_colored_polygon(lit, Color(col.lightened(0.2), col.a))
