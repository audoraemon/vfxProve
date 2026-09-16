class_name PixelParticles
extends Node2D
## Lightweight pixel particle system. Particles move on the (iso-squashed) ground plane
## plus an altitude axis, so debris arcs up and lands where it should.

enum Shape { SQUARE, PUFF, STREAK }
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
				var r := maxf(1.0, roundf(sz))
				draw_circle(at, r, col)
				if r >= 3.0:
					var hi := col.lightened(0.15)
					draw_circle(at + Vector2(-r * 0.3, -r * 0.35).round(), roundf(r * 0.55), hi)
			Shape.STREAK:
				var tail := at - (p.vel + Vector2(0, -p.valt)) * streak_len * clampf(sz, 0.5, 4.0)
				draw_line(tail.round(), at, col, -1.0)
				draw_rect(Rect2(at, Vector2.ONE), col.lightened(0.3))
